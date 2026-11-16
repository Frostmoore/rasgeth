// ffmpeg and ffprobe (G41.1): the pinned builds per system, the ffmpeg already on the computer
// used only when good enough, the download with its bar, checksum and «Cancel» (a fake HTTP
// server, never the network), and what a build can do read from its real words (fixtures saved
// from BtbN's 9.0.2 and the ffmpeg-static build RedGiant used before).
import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readFileSync, realpathSync, statSync } from "node:fs";
import { chmod, mkdir, mkdtemp, readdir, readFile, rm, symlink, writeFile } from "node:fs/promises";
import { createServer, type Server } from "node:http";
import { tmpdir } from "node:os";
import { delimiter, dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  FFMPEG_FILTERS_WANTED,
  ffmpegFeatures,
  ffmpegUsable,
  ffmpegVersion,
  pickEncoder,
} from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { Programs, type Runner } from "../src/convert-programs.js";
import {
  BTBN_TAG,
  downloadFfmpeg,
  ensureFfmpeg,
  ensureFfprobe,
  FFMPEG_VERSION,
  type FfmpegBuild,
  ffmpegBuild,
  ffmpegInfo,
  ffmpegPath,
  ffprobePath,
  findFfmpeg,
  findFfprobe,
  locateFfmpeg,
  nvencWorks,
  readFeatures,
} from "../src/ffmpeg.js";
import { Jobs } from "../src/jobs.js";
import { forWhisperCpp, toWav16k } from "../src/local-voice.js";

const fixtures = join(dirname(fileURLToPath(import.meta.url)), "fixtures", "ffmpeg");
const fixture = (name: string) => readFileSync(join(fixtures, name), "utf8");
const F9 = {
  version: fixture("version-9.0.2-btbn.txt"),
  filters: fixture("filters-9.0.2-btbn.txt"),
  encoders: fixture("encoders-9.0.2-btbn.txt"),
};
const F7 = {
  version: fixture("version-7.0.2-static.txt"),
  filters: fixture("filters-7.0.2-static.txt"),
  encoders: fixture("encoders-7.0.2-static.txt"),
};
const posix = process.platform !== "win32";
const sha = (b: Buffer) => createHash("sha256").update(b).digest("hex");
type Features = ReturnType<typeof ffmpegFeatures>;

/**
 * A PATH with no ffmpeg but the archivers the download runs (tar, and the xz it calls; unzip):
 * links to them in a folder of their own.
 */
async function archiversOnly(dir: string): Promise<string> {
  const bin = join(dir, "archivers");
  await mkdir(bin, { recursive: true });
  for (const name of ["tar", "xz", "unzip"])
    for (const d of (saved.PATH ?? "").split(delimiter)) {
      if (d && existsSync(join(d, name))) {
        await symlink(join(d, name), join(bin, name));
        break;
      }
    }
  return bin;
}

const saved = { ...process.env };
afterEach(() => {
  process.env = { ...saved };
});

describe("the pinned builds (G41.1)", () => {
  it("has one for each system, with its URL, checksum and programs", () => {
    const btbn = (target: string, ext: string) =>
      `https://github.com/BtbN/FFmpeg-Builds/releases/download/${BTBN_TAG}/ffmpeg-n9.0.2-39-g7adfbe40dc-${target}-gpl-9.0.${ext}`;
    const riedl = (dir: string, name: string) =>
      `https://ffmpeg.martin-riedl.de/download/macos/${dir}/${name}.zip`;
    const table: [string, string, string | undefined, string[]][] = [
      ["linux", "x64", "btbn", [btbn("linux64", "tar.xz")]],
      ["linux", "arm64", "btbn", [btbn("linuxarm64", "tar.xz")]],
      ["win32", "x64", "btbn", [btbn("win64", "zip")]],
      ["win32", "arm64", "btbn", [btbn("winarm64", "zip")]],
      [
        "darwin",
        "arm64",
        "martin-riedl",
        [riedl("arm64/1789931890_9.0.2", "ffmpeg"), riedl("arm64/1789931890_9.0.2", "ffprobe")],
      ],
      [
        "darwin",
        "x64",
        "martin-riedl",
        [riedl("amd64/1789931006_9.0.2", "ffmpeg"), riedl("amd64/1789931006_9.0.2", "ffprobe")],
      ],
      ["linux", "arm", undefined, []],
      ["linux", "ia32", undefined, []],
      ["win32", "ia32", undefined, []],
      ["freebsd", "x64", undefined, []],
    ];
    const seen = new Set<string>();
    for (const [platform, arch, source, urls] of table) {
      const b = ffmpegBuild(platform, arch, undefined);
      expect([platform, arch, b?.source]).toEqual([platform, arch, source]);
      expect(b?.packages.map((p) => p.url) ?? []).toEqual(urls);
      if (!b) continue;
      expect(b.version).toBe(FFMPEG_VERSION);
      const members = b.packages.flatMap((p) => Object.keys(p.members)).sort();
      expect(members).toEqual(["ffmpeg", "ffprobe"]);
      for (const p of b.packages) {
        expect(p.sha256).toMatch(/^[0-9a-f]{64}$/);
        expect(seen.has(p.sha256)).toBe(false);
        seen.add(p.sha256);
        expect(p.size).toBeGreaterThan(20_000_000);
        expect(p.kind).toBe(platform === "linux" ? "tarxz" : "zip");
        for (const [name, m] of Object.entries(p.members))
          expect(m.split("/").pop()).toBe(platform === "win32" ? `${name}.exe` : name);
      }
    }
    // The checksums written down (BtbN's checksums.sha256, martin-riedl's .sha256).
    expect(ffmpegBuild("linux", "x64", undefined)?.packages[0]?.sha256).toBe(
      "73e29a56974ae5a651133a04584c7483b21afe941e17dc91d79814a758b608d3",
    );
    expect(ffmpegBuild("win32", "x64", undefined)?.packages[0]?.members.ffprobe).toBe(
      "ffmpeg-n9.0.2-39-g7adfbe40dc-win64-gpl-9.0/bin/ffprobe.exe",
    );
    expect(ffmpegBuild("darwin", "arm64", undefined)?.packages.map((p) => p.sha256)).toEqual([
      "c8ed4c4e6978a03c485edbfe4e0a5dc2380f8a30bba5150531b31b094492d924",
      "fcbe839537485eaee7a7a8bc5cbc0f90d53617e80943e8a5b2e31cb851197ea6",
    ]);
  });

  it("takes a mirror with the same paths and checksums", () => {
    const real = ffmpegBuild("darwin", "x64", undefined);
    const mirror = ffmpegBuild("darwin", "x64", "http://mirror.lan/ff/");
    expect(mirror?.packages.map((p) => p.url)).toEqual([
      "http://mirror.lan/ff/martin-riedl/macos/amd64/1789931006_9.0.2/ffmpeg.zip",
      "http://mirror.lan/ff/martin-riedl/macos/amd64/1789931006_9.0.2/ffprobe.zip",
    ]);
    expect(mirror?.packages.map((p) => p.sha256)).toEqual(real?.packages.map((p) => p.sha256));
    expect(ffmpegBuild("linux", "x64", "http://m")?.packages[0]?.url).toBe(
      `http://m/btbn/${BTBN_TAG}/ffmpeg-n9.0.2-39-g7adfbe40dc-linux64-gpl-9.0.tar.xz`,
    );
  });

  it("keeps each version in its own folder", () => {
    expect(ffmpegPath("/d", "win32")).toBe(join("/d", "tools", "ffmpeg", "9.0.2", "ffmpeg.exe"));
    expect(ffprobePath("/d", "win32")).toBe(join("/d", "tools", "ffmpeg", "9.0.2", "ffprobe.exe"));
    expect(ffmpegPath("/d", "linux")).toBe(join("/d", "tools", "ffmpeg", "9.0.2", "ffmpeg"));
    expect(ffprobePath("/d", "darwin")).toBe(join("/d", "tools", "ffmpeg", "9.0.2", "ffprobe"));
  });

  it("downloads only where there is a build (Programs)", () => {
    const jobs = new Jobs();
    const can = (platform: string, arch: string) =>
      new Programs({ jobs, dataDir: "/d", download: { platform, arch } }).canDownload("ffmpeg");
    expect([can("linux", "x64"), can("darwin", "arm64"), can("win32", "arm64")]).toEqual([
      true,
      true,
      true,
    ]);
    expect([can("linux", "arm"), can("freebsd", "x64")]).toEqual([false, false]);
  });
});

describe("what a build can do", () => {
  it("reads filters and encoders from the real lists", () => {
    const f9 = ffmpegFeatures(F9.filters, F9.encoders);
    const f7 = ffmpegFeatures(F7.filters, F7.encoders);
    for (const f of FFMPEG_FILTERS_WANTED) {
      expect([f, f9.filters.has(f)]).toEqual([f, true]);
      // The static build used before 3.9 has no drawtext (no freetype).
      expect([f, f7.filters.has(f)]).toEqual([f, f !== "drawtext"]);
    }
    // Many filters, none of the legend's words.
    expect(f9.filters.size).toBeGreaterThan(400);
    expect(f7.filters.size).toBeGreaterThan(400);
    for (const legend of ["=", "Timeline", "Audio", "Filters", "Video"]) {
      expect(f9.filters.has(legend)).toBe(false);
      expect(f9.encoders.has(legend)).toBe(false);
    }
    expect(f9.encoders.has("h264_nvenc")).toBe(true);
    expect(f9.encoders.has("libx264")).toBe(true);
    expect(f9.encoders.has("aac")).toBe(true);
    expect(f7.encoders.has("h264_nvenc")).toBe(false);
    expect(f7.encoders.has("libx264")).toBe(true);
  });

  it("tells the version", () => {
    const table: [string, string, number | null][] = [
      [F9.version, "n9.0.2-39-g7adfbe40dc-20261031", 9],
      [F7.version, "7.0.2-static", 7],
      ["ffmpeg version 7.1.1-1+b1 Copyright (c) 2000-2025", "7.1.1-1+b1", 7],
      ["ffmpeg version 9.0.2 Copyright (c) 2000-2026", "9.0.2", 9],
      ["ffmpeg version 6.1.1-static https://johnvansickle.com", "6.1.1-static", 6],
      ["ffmpeg version N-128910-g38519047ce Copyright", "N-128910-g38519047ce", null],
      ["something else", "", null],
    ];
    for (const [text, version, major] of table)
      expect(ffmpegVersion(text)).toEqual({ version, major });
  });

  it("uses an ffmpeg already here only from 7 on and with the filters", () => {
    const all = ffmpegFeatures(F9.filters);
    const noSubs = ffmpegFeatures(
      F9.filters
        .split("\n")
        .filter((l) => !/ (subtitles|ass) /.test(l))
        .join("\n"),
    );
    const table: [string, Features, boolean, RegExp | undefined][] = [
      [F9.version, all, true, undefined],
      [F7.version, ffmpegFeatures(F7.filters), false, /^no drawtext$/],
      ["ffmpeg version 6.1.1-static", all, false, /older than 7/],
      ["ffmpeg version N-128910-g38519047ce", all, false, /unknown version/],
      [F9.version, noSubs, false, /no subtitles/],
      [F9.version, ffmpegFeatures(""), false, /no xfade, zoompan/],
    ];
    for (const [version, features, ok, why] of table) {
      const got = ffmpegUsable(version, features);
      expect(got.ok).toBe(ok);
      if (why && !got.ok) expect(got.why).toMatch(why);
    }
  });

  it("picks NVENC only when it is there and a frame works, otherwise libx264", () => {
    const f9 = ffmpegFeatures(F9.filters, F9.encoders);
    const f7 = ffmpegFeatures(F7.filters, F7.encoders);
    const nvidia = [{ vendor: "nvidia" }];
    const table: [Features, { vendor: string }[], boolean, string | undefined][] = [
      [f9, nvidia, true, "h264_nvenc"],
      [f9, nvidia, false, "libx264"],
      [f9, [{ vendor: "amd" }], true, "libx264"],
      [f9, [], true, "libx264"],
      [f7, nvidia, true, "libx264"],
      [ffmpegFeatures(F9.filters, ""), nvidia, true, undefined],
    ];
    for (const [features, gpus, works, encoder] of table)
      expect(pickEncoder(features, gpus, works)).toBe(encoder);
  });

  it("asks a build without a shell: features, info, a one-frame NVENC try", async () => {
    const calls: string[][] = [];
    const run: Runner = async (file, args) => {
      calls.push([file, ...args]);
      const out =
        args[1] === "-version"
          ? F9.version
          : args[1] === "-filters"
            ? F9.filters
            : args[1] === "-encoders"
              ? F9.encoders
              : "";
      return { stdout: out, stderr: "", exitCode: args.includes("h264_nvenc") ? 1 : 0 };
    };
    const { features } = await readFeatures("/x/ffmpeg", run);
    expect(features.filters.has("xfade")).toBe(true);
    const info = await ffmpegInfo(
      { ffmpeg: "/x/ffmpeg", ffprobe: "/x/ffprobe", source: "ours" },
      run,
    );
    expect(info).toEqual({
      version: "n9.0.2-39-g7adfbe40dc-20261031",
      major: 9,
      source: "ours",
      ffprobe: true,
      missing: [],
      encoders: ["h264_nvenc", "libx264"],
    });
    expect(await nvencWorks("/x/ffmpeg", run)).toBe(false);
    expect(calls.at(-1)).toEqual([
      "/x/ffmpeg",
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
    ]);
  });
});

/** A fake ffmpeg that answers with saved lists (and a fake ffprobe), in `dir`. */
async function fakeTools(dir: string, f: { version: string; filters: string }, probe = true) {
  await mkdir(dir, { recursive: true });
  await writeFile(join(dir, "version.txt"), f.version);
  await writeFile(join(dir, "filters.txt"), f.filters);
  await writeFile(
    join(dir, "ffmpeg"),
    `#!/bin/sh\nPATH=/bin:/usr/bin\ncase "$2" in -version) cat "${dir}/version.txt";; -filters) cat "${dir}/filters.txt";; esac\n`,
  );
  await chmod(join(dir, "ffmpeg"), 0o755);
  if (probe) {
    await writeFile(join(dir, "ffprobe"), "#!/bin/sh\n");
    await chmod(join(dir, "ffprobe"), 0o755);
  }
}

describe("the ffmpeg already on the computer", () => {
  it("uses REDGIANT_FFMPEG with its ffprobe, then RedGiant's own", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-find-"));
    try {
      const data = join(dir, "data");
      delete process.env.REDGIANT_FFMPEG;
      delete process.env.REDGIANT_FFPROBE;
      expect(findFfmpeg(data, "/nowhere")).toBeUndefined();
      await mkdir(dirname(ffmpegPath(data)), { recursive: true });
      await writeFile(ffmpegPath(data), "");
      await writeFile(ffprobePath(data), "");
      expect(locateFfmpeg(data, "/nowhere")).toEqual({
        ffmpeg: ffmpegPath(data),
        ffprobe: ffprobePath(data),
        source: "ours",
      });
      await mkdir(join(dir, "own"));
      await writeFile(join(dir, "own", "ffmpeg"), "");
      process.env.REDGIANT_FFMPEG = join(dir, "own", "ffmpeg");
      // No ffprobe beside it: none, and ensureFfprobe gives RedGiant's own.
      expect(locateFfmpeg(data, "/nowhere")).toEqual({
        ffmpeg: join(dir, "own", "ffmpeg"),
        source: "env",
      });
      expect(await ensureFfprobe(new Jobs(), "me", data)).toBe(ffprobePath(data));
      await writeFile(join(dir, "probe"), "");
      process.env.REDGIANT_FFPROBE = join(dir, "probe");
      expect(findFfprobe(data, "/nowhere")).toBe(join(dir, "probe"));
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });

  it.skipIf(!posix)(
    "takes a PATH ffmpeg only if it is 7 or later, has the filters and an ffprobe",
    async () => {
      const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-path-"));
      try {
        delete process.env.REDGIANT_FFMPEG;
        const data = join(dir, "data");
        const good = join(dir, "good");
        const old = join(dir, "old");
        const bare = join(dir, "bare");
        const noProbe = join(dir, "noprobe");
        await fakeTools(good, F9);
        await fakeTools(old, { version: "ffmpeg version 6.1.1-static\n", filters: F9.filters });
        await fakeTools(bare, {
          version: F9.version,
          filters: F9.filters
            .split("\n")
            .filter((l) => !l.includes(" drawtext "))
            .join("\n"),
        });
        await fakeTools(noProbe, F9, false);
        // Taken through its links, as its real path (macOS: /private/var).
        expect(locateFfmpeg(data, ["/nowhere", good].join(delimiter))).toEqual({
          ffmpeg: realpathSync(join(good, "ffmpeg")),
          ffprobe: realpathSync(join(good, "ffprobe")),
          source: "path",
        });
        expect(findFfmpeg(data, old)).toBeUndefined();
        expect(findFfmpeg(data, bare)).toBeUndefined();
        expect(findFfmpeg(data, noProbe)).toBeUndefined();
        // The static build RedGiant downloaded before 3.9 (7.0.2) has no drawtext: not used.
        const seven = join(dir, "seven");
        await fakeTools(seven, F7);
        expect(findFfmpeg(data, seven)).toBeUndefined();
        // A 7.x with everything (as a distribution's) is.
        const distro = join(dir, "distro");
        await fakeTools(distro, { version: "ffmpeg version 7.1.1-1+b1\n", filters: F9.filters });
        expect(findFfmpeg(data, distro)).toBe(realpathSync(join(distro, "ffmpeg")));
        // RedGiant's own wins over the PATH's.
        await mkdir(dirname(ffmpegPath(data)), { recursive: true });
        await writeFile(ffmpegPath(data), "");
        expect(findFfmpeg(data, good)).toBe(ffmpegPath(data));
      } finally {
        await rm(dir, { recursive: true, force: true });
      }
    },
  );
});

/** A BtbN-like tar.xz with `folder/bin/ffmpeg` and `folder/bin/ffprobe` (scripts). */
async function btbnLike(
  dir: string,
  ffmpeg: string,
): Promise<{ file: Buffer; build: FfmpegBuild }> {
  const folder = "ffmpeg-n9.0.2-test-linux64-gpl-9.0";
  await mkdir(join(dir, "src", folder, "bin"), { recursive: true });
  await mkdir(join(dir, "src", folder, "doc"), { recursive: true });
  await writeFile(join(dir, "src", folder, "bin", "ffmpeg"), ffmpeg);
  await writeFile(join(dir, "src", folder, "bin", "ffprobe"), "#!/bin/sh\necho probe\n");
  await writeFile(join(dir, "src", folder, "bin", "ffplay"), "not taken");
  await writeFile(join(dir, "src", folder, "doc", "readme.txt"), "not taken");
  const out = join(dir, "pkg.tar.xz");
  execFileSync("tar", ["-cJf", out, "-C", join(dir, "src"), folder]);
  const file = await readFile(out);
  return {
    file,
    build: {
      version: FFMPEG_VERSION,
      source: "btbn",
      packages: [
        {
          path: "test/pkg.tar.xz",
          url: "",
          sha256: sha(file),
          size: file.length,
          kind: "tarxz",
          members: { ffmpeg: `${folder}/bin/ffmpeg`, ffprobe: `${folder}/bin/ffprobe` },
        },
      ],
    },
  };
}

/** Serves `body` at /pkg; `hold` keeps the answer open after half of it (for «Cancel»). */
async function serve(body: Buffer, o: { hold?: boolean } = {}) {
  let downloads = 0;
  const server: Server = createServer((req, res) => {
    if (req.url !== "/pkg") return void res.writeHead(404).end();
    downloads++;
    res.writeHead(200, { "content-length": body.length });
    if (!o.hold) return void res.end(body);
    res.write(body.subarray(0, body.length >> 1));
  });
  await new Promise<void>((ok) => server.listen(0, "127.0.0.1", ok));
  const url = `http://127.0.0.1:${(server.address() as { port: number }).port}/pkg`;
  return {
    url,
    downloads: () => downloads,
    close: () => {
      server.closeAllConnections();
      server.close();
    },
  };
}

/** Jobs whose progress calls the test sees, on a fake clock (a second per chunk). */
function watchedJobs() {
  let t = 1_000_000;
  const jobs = new Jobs(() => t);
  const seen: number[] = [];
  const ids: string[] = [];
  const real = jobs.start.bind(jobs);
  jobs.start = (owner, kind, steps, run, vars) => {
    const job = real(
      owner,
      kind,
      steps,
      (h) =>
        run({
          ...h,
          progress: (d, total) => {
            t += 1000;
            seen.push(d);
            h.progress(d, total);
          },
        }),
      vars,
    );
    ids.push(job.id);
    return job;
  };
  return { jobs, seen, ids };
}

const leftovers = async (data: string) =>
  (await readdir(join(data, "tools", "ffmpeg")).catch(() => [] as string[])).filter((n) =>
    n.startsWith(".download-"),
  );

const withUrl = (build: FfmpegBuild, url: string, more: { sha256?: string } = {}) => ({
  ...build,
  packages: build.packages.map((p) => ({ ...p, url, ...more })),
});

describe.skipIf(!posix)("the download", () => {
  it("comes down once, checked, with its bar; a voice note goes through it", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-dl-"));
    const wav = toWav16k([new Float32Array(1600)], 16000);
    await writeFile(join(dir, "ref.wav"), wav);
    // A stand-in for ffmpeg: writes the reference WAV to its last argument.
    const made = await btbnLike(
      dir,
      `#!/bin/sh\nPATH=/bin:/usr/bin\nfor a; do last="$a"; done\ncp "${dir}/ref.wav" "$last"\n`,
    );
    const http = await serve(made.file);
    const build = withUrl(made.build, http.url);
    delete process.env.REDGIANT_FFMPEG;
    process.env.PATH = await archiversOnly(dir);
    const data = join(dir, "data");
    // The single file of the downloads before 3.9 goes.
    await mkdir(join(data, "tools", "ffmpeg"), { recursive: true });
    await writeFile(join(data, "tools", "ffmpeg", "ffmpeg"), "old");
    const { jobs, seen, ids } = watchedJobs();
    try {
      const [a, b] = await Promise.all([
        ensureFfmpeg(jobs, "me", data, { deps: { build } }),
        ensureFfmpeg(jobs, "me", data, { deps: { build } }),
      ]);
      expect(a).toBe(ffmpegPath(data));
      expect(b).toBe(a);
      expect(http.downloads()).toBe(1);
      expect(ids).toHaveLength(1);
      const job = jobs.get("me", ids[0] as string);
      expect(job?.kind).toBe("download_ffmpeg");
      expect(job?.state).toBe("done");
      expect(job?.steps.map((s) => [s.id, s.state])).toEqual([
        ["tool_download", "done"],
        ["tool_unpack", "done"],
      ]);
      expect(seen.at(-1)).toBe(made.file.length);
      // Only the two programs, executable, nothing else of the archive.
      expect((await readdir(dirname(ffmpegPath(data)))).sort()).toEqual(["ffmpeg", "ffprobe"]);
      expect(statSync(ffprobePath(data)).mode & 0o111).not.toBe(0);
      expect(existsSync(join(data, "tools", "ffmpeg", "ffmpeg"))).toBe(false);
      expect(await leftovers(data)).toEqual([]);
      // Already here: nothing more comes down, ffprobe too.
      expect(await ensureFfmpeg(jobs, "me", data, { deps: { build } })).toBe(a);
      expect(await ensureFfprobe(jobs, "me", data, { deps: { build } })).toBe(ffprobePath(data));
      expect(http.downloads()).toBe(1);

      const m4a = Buffer.concat([Buffer.from([0, 0, 0, 0x20]), Buffer.from("ftypM4A ")]);
      const got = await forWhisperCpp(m4a, "audio/mp4", {
        ffmpeg: () => ensureFfmpeg(jobs, "me", data),
      });
      expect(got.type).toBe("audio/wav");
      expect(Buffer.from(got.audio).equals(Buffer.from(wav))).toBe(true);
    } finally {
      http.close();
      await rm(dir, { recursive: true, force: true });
    }
  });

  it("refuses a package whose checksum does not match, and keeps nothing", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-sum-"));
    const made = await btbnLike(dir, "#!/bin/sh\n");
    const http = await serve(made.file);
    const wrong = withUrl(made.build, http.url, { sha256: "0".repeat(64) });
    delete process.env.REDGIANT_FFMPEG;
    process.env.PATH = await archiversOnly(dir);
    const data = join(dir, "data");
    const { jobs, ids } = watchedJobs();
    try {
      await expect(ensureFfmpeg(jobs, "me", data, { deps: { build: wrong } })).rejects.toThrow(
        /did not match its checksum/,
      );
      expect(jobs.get("me", ids[0] as string)?.state).toBe("failed");
      expect(existsSync(dirname(ffmpegPath(data)))).toBe(false);
      expect(await leftovers(data)).toEqual([]);
    } finally {
      http.close();
      await rm(dir, { recursive: true, force: true });
    }
  });

  it("stops at «Cancel» halfway and removes what came down", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-cancel-"));
    const made = await btbnLike(dir, "#!/bin/sh\n");
    const http = await serve(made.file, { hold: true });
    const held = withUrl(made.build, http.url);
    delete process.env.REDGIANT_FFMPEG;
    process.env.PATH = await archiversOnly(dir);
    const data = join(dir, "data");
    const { jobs, seen, ids } = watchedJobs();
    try {
      const caught = ensureFfmpeg(jobs, "me", data, { deps: { build: held } }).catch(
        (e: Error) => e,
      );
      // Half of it came down: the bar shows it against the whole size.
      for (let i = 0; i < 300 && !seen.length; i++) await new Promise((r) => setTimeout(r, 10));
      expect(seen.length).toBeGreaterThan(0);
      const id = ids[0] as string;
      expect(jobs.get("me", id)?.steps[0]?.progress?.total).toBe(made.file.length);
      expect(jobs.cancel("me", id)).toBe(true);
      expect(String(await caught)).toMatch(/cancelled/);
      expect(jobs.get("me", id)?.state).toBe("cancelled");
      expect(existsSync(dirname(ffmpegPath(data)))).toBe(false);
      expect(await leftovers(data)).toEqual([]);
    } finally {
      http.close();
      await rm(dir, { recursive: true, force: true });
    }
  });

  it("puts macOS's two zips together, one bar over both (martin-riedl)", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-mac-"));
    const zips = { ffmpeg: Buffer.from("zip of ffmpeg"), ffprobe: Buffer.from("zip of ffprobe!") };
    const server = createServer((req, res) => {
      const name = req.url?.slice(1) as keyof typeof zips;
      if (!(name in zips)) return void res.writeHead(404).end();
      res.writeHead(200, { "content-length": zips[name].length });
      res.end(zips[name]);
    });
    await new Promise<void>((ok) => server.listen(0, "127.0.0.1", ok));
    const base = `http://127.0.0.1:${(server.address() as { port: number }).port}`;
    const build: FfmpegBuild = {
      version: FFMPEG_VERSION,
      source: "martin-riedl",
      packages: (["ffmpeg", "ffprobe"] as const).map((name) => ({
        path: `macos/arm64/x/${name}.zip`,
        url: `${base}/${name}`,
        sha256: sha(zips[name]),
        size: zips[name].length,
        kind: "zip" as const,
        members: { [name]: name },
      })),
    };
    // bsdtar on macOS: here a fake that "unpacks" the member it was asked for.
    const calls: string[][] = [];
    const run: Runner = async (file, args) => {
      calls.push([file, ...args]);
      const at = args.indexOf("-C");
      const member = args.at(-1) as string;
      await writeFile(join(args[at + 1] as string, member), `#!/bin/sh\necho ${member}\n`);
      return { stdout: "", stderr: "", exitCode: 0 };
    };
    const data = join(dir, "data");
    const bar: [number, number | null][] = [];
    try {
      const got = await downloadFfmpeg(
        data,
        { signal: new AbortController().signal, progress: (d, t) => bar.push([d, t]) },
        { build, run, platform: "darwin", arch: "arm64" },
      );
      const total = zips.ffmpeg.length + zips.ffprobe.length;
      expect(bar.at(-1)).toEqual([total, total]);
      expect(bar.every(([, t]) => t === total)).toBe(true);
      expect(calls.map((c) => [c[0], c[1], c.at(-1)])).toEqual([
        ["tar", "-xf", "ffmpeg"],
        ["tar", "-xf", "ffprobe"],
      ]);
      expect(await readFile(got.ffprobe, "utf8")).toContain("echo ffprobe");
      expect(got.ffmpeg).toBe(ffmpegPath(data, "darwin"));
    } finally {
      server.close();
      await rm(dir, { recursive: true, force: true });
    }
  });

  it("says why when ffmpeg cannot come down", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-ffmpeg-fail-"));
    const server = createServer((_req, res) => res.writeHead(503).end());
    await new Promise<void>((ok) => server.listen(0, "127.0.0.1", ok));
    process.env.REDGIANT_FFMPEG_RELEASES = `http://127.0.0.1:${(server.address() as { port: number }).port}/x`;
    delete process.env.REDGIANT_FFMPEG;
    process.env.PATH = await archiversOnly(dir);
    try {
      const m4a = Buffer.concat([Buffer.from([0, 0, 0, 0x20]), Buffer.from("ftypM4A ")]);
      await expect(
        forWhisperCpp(m4a, "audio/mp4", {
          ffmpeg: () => ensureFfmpeg(new Jobs(), "me", join(dir, "data")),
        }),
      ).rejects.toThrow(/ffmpeg could not be downloaded \(.*answered 503/);
    } finally {
      server.close();
      await rm(dir, { recursive: true, force: true });
    }
  });
});
