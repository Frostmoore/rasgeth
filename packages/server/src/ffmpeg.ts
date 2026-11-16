// ffmpeg and ffprobe (G41.1). First for voice notes (2026-11-05: M4A/AAC and what the WASM
// decoders do not read), then for the video editor's renders and probes (3.9). One already on this
// computer is used when it is good enough (version 7 or later with the filters the editor needs,
// and its ffprobe); otherwise RedGiant's own pinned build is downloaded once into the data folder,
// with its bar and «Cancel», like Git and whisper.cpp:
//   - Linux x64/arm64 and Windows x64/arm64: BtbN FFmpeg-Builds, the 9.0 GPL static build of one
//     month-end autobuild (those stay published; the daily ones go after a few weeks);
//   - macOS arm64/x64: ffmpeg.martin-riedl.de, the 9.0.2 release (ffmpeg and ffprobe, one zip each).
// Every package is checked against the SHA-256 written here before anything is unpacked. GPL
// programs run only as separate executables. REDGIANT_FFMPEG_RELEASES points to a mirror (same
// paths under `<mirror>/btbn/` and `<mirror>/martin-riedl/`, same checksums) or to a fake in tests.
//
// `downloadFfmpeg` needs no job: a node (G41.7, `media ensure`) calls it with its own progress and
// signal. `ensureFfmpeg` is the server's way in, as a job (`download_ffmpeg`).

import { execFile, spawnSync } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import { createWriteStream, existsSync, realpathSync, statSync } from "node:fs";
import { chmod, mkdir, rename, rm } from "node:fs/promises";
import { delimiter, dirname, join } from "node:path";
import { Readable, Transform } from "node:stream";
import { pipeline } from "node:stream/promises";
import {
  FFMPEG_ENCODERS_WANTED,
  FFMPEG_FILTERS_WANTED,
  type FfmpegFeatures,
  type FfmpegInfo,
  ffmpegFeatures,
  ffmpegUsable,
  ffmpegVersion,
} from "@redgiant/protocol";
import { agentEnv } from "@redgiant/tools";
import type { Runner } from "./convert-programs.js";
import type { JobHandle, Jobs } from "./jobs.js";

/** The ffmpeg RedGiant downloads (the folder under `<data>/tools/ffmpeg/`). */
export const FFMPEG_VERSION = "9.0.2";
/** BtbN's month-end autobuild with ffmpeg 9.0.2 (checked 2026-11-16). */
export const BTBN_TAG = "autobuild-2026-10-31-12-59";
const BTBN_NAME = "ffmpeg-n9.0.2-39-g7adfbe40dc";
const BTBN = "https://github.com/BtbN/FFmpeg-Builds/releases/download";
const RIEDL = "https://ffmpeg.martin-riedl.de/download";

export type FfmpegProgram = "ffmpeg" | "ffprobe";

/** One file to download: where, its checksum and size, and which programs are inside. */
export interface FfmpegPackage {
  /** Its path at the source (a mirror keeps it under `<mirror>/<source>/`). */
  path: string;
  url: string;
  sha256: string;
  size: number;
  kind: "tarxz" | "zip";
  /** The archive members to take, per program. */
  members: Partial<Record<FfmpegProgram, string>>;
}

export interface FfmpegBuild {
  version: string;
  source: "btbn" | "martin-riedl";
  packages: FfmpegPackage[];
}

/** BtbN's packages (`checksums.sha256` of BTBN_TAG; sizes from GitHub). */
const BTBN_BUILDS: Record<string, { target: string; sha256: string; size: number }> = {
  "linux x64": {
    target: "linux64",
    sha256: "73e29a56974ae5a651133a04584c7483b21afe941e17dc91d79814a758b608d3",
    size: 153175100,
  },
  "linux arm64": {
    target: "linuxarm64",
    sha256: "6cad88ae5bcec356cfc5d7979a036cc4007128201928a0cf243df3db483276cc",
    size: 128664064,
  },
  "win32 x64": {
    target: "win64",
    sha256: "693f3e224bc184b40524a62ca47526cfebaf2504414021b92fe75f677ad868b9",
    size: 195110184,
  },
  "win32 arm64": {
    target: "winarm64",
    sha256: "8b3c394762f26716ccef03ac1b7ac76430759080e1255aa9bc01d74db590bcb5",
    size: 136603040,
  },
};

/** martin-riedl's 9.0.2 release for macOS (each zip's `.sha256`; sizes from the server). */
const RIEDL_BUILDS: Record<
  string,
  { dir: string } & Record<FfmpegProgram, { sha256: string; size: number }>
> = {
  "darwin arm64": {
    dir: "macos/arm64/1789931890_9.0.2",
    ffmpeg: {
      sha256: "c8ed4c4e6978a03c485edbfe4e0a5dc2380f8a30bba5150531b31b094492d924",
      size: 28395699,
    },
    ffprobe: {
      sha256: "fcbe839537485eaee7a7a8bc5cbc0f90d53617e80943e8a5b2e31cb851197ea6",
      size: 28317701,
    },
  },
  "darwin x64": {
    dir: "macos/amd64/1789931006_9.0.2",
    ffmpeg: {
      sha256: "7c6b4125b191cbf773832dc51f424cf2b6bb7da43007d1e066f95909e47cacd4",
      size: 33816391,
    },
    ffprobe: {
      sha256: "2322438ed2f6319a691291b247d09c69dcaa3a982460d1f269a7e1af335cfdfd",
      size: 33719233,
    },
  },
};

const exe = (name: FfmpegProgram, platform: string) =>
  platform === "win32" ? `${name}.exe` : name;

/** The pinned build for a system, if there is one. */
export function ffmpegBuild(
  platform: string = process.platform,
  arch: string = process.arch,
  mirror: string | undefined = process.env.REDGIANT_FFMPEG_RELEASES,
): FfmpegBuild | undefined {
  const at = (source: FfmpegBuild["source"], path: string) =>
    mirror
      ? `${mirror.replace(/\/+$/, "")}/${source}/${path}`
      : `${source === "btbn" ? BTBN : RIEDL}/${path}`;
  const key = `${platform} ${arch}`;
  const b = BTBN_BUILDS[key];
  if (b) {
    const win = platform === "win32";
    const folder = `${BTBN_NAME}-${b.target}-gpl-9.0`;
    const path = `${BTBN_TAG}/${folder}.${win ? "zip" : "tar.xz"}`;
    return {
      version: FFMPEG_VERSION,
      source: "btbn",
      packages: [
        {
          path,
          url: at("btbn", path),
          sha256: b.sha256,
          size: b.size,
          kind: win ? "zip" : "tarxz",
          members: {
            ffmpeg: `${folder}/bin/${exe("ffmpeg", platform)}`,
            ffprobe: `${folder}/bin/${exe("ffprobe", platform)}`,
          },
        },
      ],
    };
  }
  const r = RIEDL_BUILDS[key];
  if (r)
    return {
      version: FFMPEG_VERSION,
      source: "martin-riedl",
      packages: (["ffmpeg", "ffprobe"] as const).map((name) => {
        const path = `${r.dir}/${name}.zip`;
        return {
          path,
          url: at("martin-riedl", path),
          sha256: r[name].sha256,
          size: r[name].size,
          kind: "zip" as const,
          members: { [name]: name },
        };
      }),
    };
  return undefined;
}

/** Where RedGiant's own build lives: `<data>/tools/ffmpeg/<version>/`. */
export const ffmpegDir = (dataDir: string, version = FFMPEG_VERSION) =>
  join(dataDir, "tools", "ffmpeg", version);
export const ffmpegPath = (dataDir: string, platform: string = process.platform) =>
  join(ffmpegDir(dataDir), exe("ffmpeg", platform));
export const ffprobePath = (dataDir: string, platform: string = process.platform) =>
  join(ffmpegDir(dataDir), exe("ffprobe", platform));

/**
 * A program on the PATH (the person's own), as its real file: WinGet puts a link on the PATH that
 * Windows may refuse to start from another program («untrusted mount point», p3.3.1).
 */
function onPath(name: FfmpegProgram, path: string): string | undefined {
  for (const d of path.split(delimiter)) {
    const p = d && join(d, exe(name, process.platform));
    if (p && existsSync(p)) {
      try {
        return realpathSync(p);
      } catch {
        return p;
      }
    }
  }
  return undefined;
}

/** What `ffmpeg -version` and `-filters` say, read once per file (its size and time as the key). */
const asked = new Map<string, { version: string; features: FfmpegFeatures } | null>();
function askSync(ffmpeg: string): { version: string; features: FfmpegFeatures } | undefined {
  let key: string;
  try {
    const s = statSync(ffmpeg);
    key = `${ffmpeg}\0${s.size}\0${s.mtimeMs}`;
  } catch {
    return undefined;
  }
  const had = asked.get(key);
  if (had !== undefined) return had ?? undefined;
  const say = (args: string[]) => {
    const r = spawnSync(ffmpeg, args, {
      encoding: "utf8",
      timeout: 10_000,
      windowsHide: true,
      env: agentEnv(),
      maxBuffer: 4 * 1024 * 1024,
    });
    return r.status === 0 ? `${r.stdout}${r.stderr}` : undefined;
  };
  const version = say(["-hide_banner", "-version"]);
  const filters = version && say(["-hide_banner", "-filters"]);
  const got = version && filters ? { version, features: ffmpegFeatures(filters) } : null;
  asked.set(key, got);
  return got ?? undefined;
}

/** The ffmpeg found, its ffprobe if any, and where they come from. */
export interface FoundFfmpeg {
  ffmpeg: string;
  ffprobe?: string;
  source: FfmpegInfo["source"];
}

/**
 * The ffmpeg to use, without downloading: REDGIANT_FFMPEG (with REDGIANT_FFPROBE or the ffprobe
 * beside it), RedGiant's own download, then a PATH ffmpeg that is good enough (`ffmpegUsable`)
 * with an ffprobe on the PATH too. A PATH ffmpeg that is too old or lacks filters is left alone:
 * RedGiant downloads its own.
 */
export function locateFfmpeg(
  dataDir: string,
  path: string = process.env.PATH ?? process.env.Path ?? "",
): FoundFfmpeg | undefined {
  const beside = (ffmpeg: string) => {
    const p = join(dirname(ffmpeg), exe("ffprobe", process.platform));
    return existsSync(p) ? p : undefined;
  };
  const own = process.env.REDGIANT_FFMPEG;
  if (own && existsSync(own)) {
    const probe = process.env.REDGIANT_FFPROBE;
    const ffprobe = probe && existsSync(probe) ? probe : beside(own);
    return { ffmpeg: own, ...(ffprobe && { ffprobe }), source: "env" };
  }
  const ours = ffmpegPath(dataDir);
  if (existsSync(ours)) {
    const ffprobe = beside(ours);
    return { ffmpeg: ours, ...(ffprobe && { ffprobe }), source: "ours" };
  }
  const there = onPath("ffmpeg", path);
  const probe = there && onPath("ffprobe", path);
  if (there && probe) {
    const said = askSync(there);
    if (said && ffmpegUsable(said.version, said.features).ok)
      return { ffmpeg: there, ffprobe: probe, source: "path" };
  }
  return undefined;
}

/** The ffmpeg to use, without downloading (see `locateFfmpeg`). */
export const findFfmpeg = (dataDir: string, path?: string): string | undefined =>
  locateFfmpeg(dataDir, path)?.ffmpeg;

/** The ffprobe that goes with it, without downloading. */
export const findFfprobe = (dataDir: string, path?: string): string | undefined =>
  locateFfmpeg(dataDir, path)?.ffprobe;

/** A package's checksum did not match: nothing was unpacked. */
export class FfmpegChecksumError extends Error {
  constructor(
    readonly path: string,
    readonly expected: string,
    readonly got: string,
  ) {
    super(
      `The ffmpeg package ${path} did not match its checksum (expected ${expected}, got ${got})`,
    );
  }
}

export interface FfmpegDeps {
  fetch?: typeof fetch;
  run?: Runner;
  platform?: string;
  arch?: string;
  /** Tests: the build to download instead of the pinned one. */
  build?: FfmpegBuild;
}

/** How a download reports itself: a job's handle, or a node's chunks (G41.7). */
export interface FfmpegProgress {
  signal: AbortSignal;
  /** Bytes down out of every package's bytes. */
  progress(done: number, total: number | null): void;
  /** The downloads are checked: unpacking now. */
  unpacking?(): void;
}

const execRun: Runner = (file, args, o) =>
  new Promise((done) => {
    execFile(
      file,
      args,
      {
        ...(o.cwd && { cwd: o.cwd }),
        timeout: o.timeoutMs,
        ...(o.signal && { signal: o.signal }),
        env: { ...agentEnv(), ...o.env },
        maxBuffer: 16 * 1024 * 1024,
        windowsHide: true,
      },
      (err, stdout, stderr) =>
        done({
          stdout: String(stdout),
          stderr: String(stderr || (err ? err.message : "")),
          exitCode: err ? (typeof err.code === "number" ? err.code : 1) : 0,
        }),
    );
  });

/** Downloads one package into `file`, counting the bytes and checking its SHA-256. */
async function fetchChecked(
  pkg: FfmpegPackage,
  file: string,
  progress: (done: number) => void,
  signal: AbortSignal,
  fetchFn: typeof fetch,
): Promise<number> {
  const r = await fetchFn(pkg.url, { signal });
  if (!r.ok || !r.body)
    throw new Error(`${new URL(pkg.url).host} answered ${r.status} for ${pkg.path}`);
  const hash = createHash("sha256");
  let done = 0;
  // Counted and hashed in the pipe itself: nothing flows before it is counted.
  const count = new Transform({
    transform(b: Buffer, _enc, next) {
      hash.update(b);
      done += b.length;
      progress(done);
      next(null, b);
    },
  });
  await pipeline(Readable.fromWeb(r.body as never), count, createWriteStream(file), { signal });
  const got = hash.digest("hex");
  if (got !== pkg.sha256.toLowerCase()) throw new FfmpegChecksumError(pkg.path, pkg.sha256, got);
  return done;
}

/** Takes the members of a checked archive into `dir` (tar.xz with tar; zip with bsdtar or unzip). */
async function extract(
  pkg: FfmpegPackage,
  file: string,
  dir: string,
  platform: string,
  run: Runner,
  signal: AbortSignal,
): Promise<void> {
  const members = Object.values(pkg.members);
  const o = { timeoutMs: 20 * 60_000, signal };
  const r =
    pkg.kind === "tarxz"
      ? await run("tar", ["-xJf", file, "-C", dir, ...members], o)
      : platform === "linux"
        ? await run("unzip", ["-o", "-q", file, ...members, "-d", dir], o)
        : // Windows 10 and later and macOS carry bsdtar, which reads zip.
          await run("tar", ["-xf", file, "-C", dir, ...members], o);
  if (r.exitCode !== 0)
    throw new Error(
      `Unpacking ${pkg.path} failed (${r.exitCode}): ${(r.stderr || r.stdout).slice(-400)}`,
    );
}

/**
 * Downloads this computer's pinned ffmpeg and ffprobe into `<data>/tools/ffmpeg/<version>/`.
 * Every package is checked before unpacking; cancelled or failed, nothing half-done stays (the
 * work folder goes). The old single-file download (`tools/ffmpeg/ffmpeg`, before 3.9) is removed.
 */
export async function downloadFfmpeg(
  dataDir: string,
  p: FfmpegProgress,
  d: FfmpegDeps = {},
): Promise<{ ffmpeg: string; ffprobe: string }> {
  const platform = d.platform ?? process.platform;
  const arch = d.arch ?? process.arch;
  const build = d.build ?? ffmpegBuild(platform, arch);
  if (!build) throw new Error(`There is no ready ffmpeg for ${platform} ${arch}`);
  const root = join(dataDir, "tools", "ffmpeg");
  const final = ffmpegDir(dataDir, build.version);
  const work = join(root, `.download-${randomUUID().slice(0, 8)}`);
  await mkdir(work, { recursive: true });
  try {
    const total = build.packages.reduce((n, k) => n + k.size, 0) || null;
    let before = 0;
    const files: string[] = [];
    for (const [i, pkg] of build.packages.entries()) {
      const file = join(work, `package-${i}.${pkg.kind === "tarxz" ? "tar.xz" : "zip"}`);
      before += await fetchChecked(
        pkg,
        file,
        (n) => p.progress(before + n, total),
        p.signal,
        d.fetch ?? fetch,
      );
      files.push(file);
    }
    p.unpacking?.();
    const out = join(work, "bin");
    await mkdir(out);
    for (const [i, pkg] of build.packages.entries()) {
      const into = join(work, `unpacked-${i}`);
      await mkdir(into);
      await extract(pkg, files[i] as string, into, platform, d.run ?? execRun, p.signal);
      for (const [name, member] of Object.entries(pkg.members) as [FfmpegProgram, string][]) {
        const target = join(out, exe(name, platform));
        await rename(join(into, ...member.split("/")), target);
        if (platform !== "win32") await chmod(target, 0o755);
      }
      await rm(files[i] as string, { force: true });
    }
    for (const name of ["ffmpeg", "ffprobe"] as const)
      if (!existsSync(join(out, exe(name, platform))))
        throw new Error(`The ffmpeg build has no ${name}`);
    await rm(final, { recursive: true, force: true });
    await rename(out, final);
  } finally {
    await rm(work, { recursive: true, force: true });
  }
  await rm(join(root, exe("ffmpeg", platform)), { force: true }).catch(() => {});
  return {
    ffmpeg: join(final, exe("ffmpeg", platform)),
    ffprobe: join(final, exe("ffprobe", platform)),
  };
}

/** One download per data folder at a time, however many ask for it. */
const pending = new Map<string, Promise<void>>();

function fetchOurs(
  jobs: Jobs,
  owner: string,
  dataDir: string,
  o: { into?: JobHandle; deps?: FfmpegDeps },
): Promise<void> {
  const running = pending.get(dataDir);
  if (running) return running;
  const into = async (h: JobHandle) => {
    h.step("tool_download");
    await downloadFfmpeg(
      dataDir,
      {
        signal: h.signal,
        progress: (d, t) => h.progress(d, t),
        unpacking: () => h.step("tool_unpack"),
      },
      o.deps,
    );
  };
  const p = (async () => {
    if (o.into) return into(o.into);
    const job = jobs.start(owner, "download_ffmpeg", ["tool_download", "tool_unpack"], into);
    const end = await jobs.settled(job.id, 500);
    if (end?.state === "cancelled") throw new Error("The ffmpeg download was cancelled");
    if (end?.state !== "done") throw new Error(end?.error?.message ?? "ffmpeg did not download");
  })().finally(() => pending.delete(dataDir));
  pending.set(dataDir, p);
  return p;
}

const hasBuild = (d?: FfmpegDeps) =>
  d?.build !== undefined || ffmpegBuild(d?.platform, d?.arch) !== undefined;

/**
 * ffmpeg for this computer: the one already here, or RedGiant's own downloaded now as a job with
 * its bar (`download_ffmpeg`, or inside `into`). Several callers at once share one download.
 * `undefined` when there is no build for this system.
 */
export async function ensureFfmpeg(
  jobs: Jobs,
  owner: string,
  dataDir: string,
  o: { into?: JobHandle; deps?: FfmpegDeps } = {},
): Promise<string | undefined> {
  const here = findFfmpeg(dataDir);
  if (here) return here;
  if (!hasBuild(o.deps)) return undefined;
  await fetchOurs(jobs, owner, dataDir, o);
  return ffmpegPath(dataDir);
}

/**
 * ffprobe for this computer: the one that goes with the ffmpeg found, or RedGiant's own (an
 * ffmpeg set by the administrator without an ffprobe beside it gets ours).
 */
export async function ensureFfprobe(
  jobs: Jobs,
  owner: string,
  dataDir: string,
  o: { into?: JobHandle; deps?: FfmpegDeps } = {},
): Promise<string | undefined> {
  const here = findFfprobe(dataDir);
  if (here) return here;
  if (existsSync(ffprobePath(dataDir))) return ffprobePath(dataDir);
  if (!hasBuild(o.deps)) return undefined;
  await fetchOurs(jobs, owner, dataDir, o);
  return ffprobePath(dataDir);
}

/** What an ffmpeg can do: its version, filters and encoders (`ffmpeg -hide_banner …`). */
export async function readFeatures(
  ffmpeg: string,
  run: Runner = execRun,
): Promise<{ version: string; features: FfmpegFeatures }> {
  const say = async (arg: string) => {
    const r = await run(ffmpeg, ["-hide_banner", arg], { timeoutMs: 20_000 });
    if (r.exitCode !== 0) throw new Error(`${ffmpeg} ${arg} failed (${r.exitCode})`);
    return `${r.stdout}${r.stderr}`;
  };
  const version = await say("-version");
  const features = ffmpegFeatures(await say("-filters"), await say("-encoders"));
  return { version, features };
}

/** What this computer's ffmpeg is (a node reports it in G41.7). */
export async function ffmpegInfo(found: FoundFfmpeg, run: Runner = execRun): Promise<FfmpegInfo> {
  const { version, features } = await readFeatures(found.ffmpeg, run);
  return {
    ...ffmpegVersion(version),
    source: found.source,
    ffprobe: found.ffprobe !== undefined,
    missing: FFMPEG_FILTERS_WANTED.filter((f) => !features.filters.has(f)),
    encoders: FFMPEG_ENCODERS_WANTED.filter((e) => features.encoders.has(e)),
  };
}

/**
 * Whether NVENC really encodes here: one black frame through `h264_nvenc` (the build may list it
 * on a computer whose driver or GPU cannot run it).
 */
export async function nvencWorks(ffmpeg: string, run: Runner = execRun): Promise<boolean> {
  const r = await run(
    ffmpeg,
    [
      "-hide_banner",
      "-nostdin",
      "-f",
      "lavfi",
      "-i",
      "color=black:s=256x256:d=0.04",
      "-frames:v",
      "1",
      "-c:v",
      "h264_nvenc",
      "-f",
      "null",
      "-",
    ],
    { timeoutMs: 30_000 },
  );
  return r.exitCode === 0;
}
