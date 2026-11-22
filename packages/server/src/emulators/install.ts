// The guided install of the Android SDK pieces (3.11, phase 5), run as a job with a real bar. It
// never starts by itself: `plan` (the person pressed «Install what is missing») reads Google's
// lists for the sizes and the licence texts and keeps the plan under an id; only `start` with that
// id, and `licenceAccepted: true` when the plan has licences, runs it (the person's recorded yes).
// Agents have no tool for this. Programs run without a shell, arguments one by one: sdkmanager and
// avdmanager through Java (`java -classpath … SdkManagerCli`, the same on every system, so no .bat
// on Windows). Everything is written inside the SDK folder (and the AVD in the emulator's own
// place); the licence prompts are answered only for the licences the person accepted.
import { spawn } from "node:child_process";
import { createHash, randomUUID } from "node:crypto";
import { createReadStream, createWriteStream, type WriteStream } from "node:fs";
import { chmod, mkdir, readdir, rename, rm, stat } from "node:fs/promises";
import { homedir } from "node:os";
import { delimiter, isAbsolute, relative, resolve } from "node:path";
import { Readable, Transform } from "node:stream";
import { pipeline } from "node:stream/promises";
import type {
  EmuArch,
  EmuInstallPlan,
  EmuInstallPlanBody,
  EmulatorReport,
  EmuOs,
  Job,
} from "@redgiant/protocol";
import { Unzip, UnzipInflate } from "fflate";
import type { JobHandle, Jobs } from "../jobs.js";
import { type EmuEnv, joinFor } from "./detect.js";
import {
  AVD_DEVICE,
  cmdlineArchive,
  cmdlineHome,
  mergeCatalogs,
  type PinnedArchive,
  type PlannedInstall,
  parseRepository,
  planInstall,
  REPOSITORY_LISTS,
  type RepoCatalog,
  type TargetState,
} from "./install-plan.js";

/** A program the installer runs: its output as it comes, its input, its end. */
export interface Program {
  onOutput(cb: (text: string) => void): void;
  write(text: string): void;
  /** The exit code (null when it was killed). */
  exit: Promise<number | null>;
  kill(): void;
}
export type Launch = (
  file: string,
  args: string[],
  o: { env: NodeJS.ProcessEnv; cwd?: string },
) => Program;

/** Node's spawn, without a shell: every argument goes to the program as it is. */
export const launchProgram: Launch = (file, args, o) => {
  const child = spawn(file, args, {
    env: o.env,
    ...(o.cwd && { cwd: o.cwd }),
    shell: false,
    windowsHide: true,
    stdio: ["pipe", "pipe", "pipe"],
  });
  const listeners: ((t: string) => void)[] = [];
  const emit = (b: Buffer) => {
    const t = b.toString("utf8");
    for (const l of listeners) l(t);
  };
  child.stdout?.on("data", emit);
  child.stderr?.on("data", emit);
  child.stdin?.on("error", () => {});
  return {
    onOutput: (cb) => listeners.push(cb),
    write: (t) => {
      child.stdin?.write(t);
    },
    exit: new Promise((done) => {
      child.on("error", () => done(-1));
      child.on("close", (code) => done(code));
    }),
    kill: () => {
      child.kill();
    },
  };
};

/** An error with a code the page explains (`eiErr_<code>`). */
export class InstallError extends Error {
  constructor(
    readonly code:
      | "no-plan"
      | "licence"
      | "blocked"
      | "busy"
      | "checksum"
      | "download"
      | "program"
      | "outside",
    message: string,
  ) {
    super(message);
  }
}

// ---- Java ----

/** `java -version`'s first line: `version "17.0.13"` → 17, `"1.8.0_392"` → 8, `openjdk 21` → 21. */
export function parseJavaVersion(text: string): number | undefined {
  const q = /version\s+"(\d+)(?:\.(\d+))?/.exec(text);
  if (q?.[1]) return q[1] === "1" && q[2] ? Number(q[2]) : Number(q[1]);
  const plain = /^(?:openjdk|java)\s+(\d+)/im.exec(text);
  return plain?.[1] ? Number(plain[1]) : undefined;
}

/**
 * Where a Java may be, in order: JAVA_HOME, the PATH, then the one Android Studio carries (its
 * `jbr`), in the standard places of each system.
 */
export function javaCandidates(
  os: EmuOs,
  env: EmuEnv & { JAVA_HOME?: string | undefined; ProgramFiles?: string | undefined },
  pathDirs: readonly string[],
  home: string,
): string[] {
  const exe = os === "windows" ? "java.exe" : "java";
  const out: string[] = [];
  const add = (p: string | undefined) => {
    if (p && !out.includes(p)) out.push(p);
  };
  if (env.JAVA_HOME?.trim()) add(joinFor(os, env.JAVA_HOME.trim(), "bin", exe));
  for (const d of pathDirs) if (d) add(joinFor(os, d, exe));
  if (os === "windows") {
    const pf = env.ProgramFiles?.trim() || "C:\\Program Files";
    add(joinFor(os, pf, "Android", "Android Studio", "jbr", "bin", exe));
    if (env.LOCALAPPDATA)
      add(joinFor(os, env.LOCALAPPDATA, "Programs", "Android Studio", "jbr", "bin", exe));
  } else if (os === "macos") {
    add("/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java");
    if (home)
      add(
        joinFor(os, home, "Applications", "Android Studio.app/Contents/jbr/Contents/Home/bin/java"),
      );
  } else {
    add("/opt/android-studio/jbr/bin/java");
    add("/usr/local/android-studio/jbr/bin/java");
    if (home) add(joinFor(os, home, "android-studio", "jbr", "bin", "java"));
  }
  return out;
}

const isFile = async (p: string) => (await stat(p).catch(() => null))?.isFile() ?? false;
const isDir = async (p: string) => (await stat(p).catch(() => null))?.isDirectory() ?? false;

/** Runs a program to ask it something (no shell), its whole output. */
async function ask(launch: Launch, file: string, args: string[], env: NodeJS.ProcessEnv) {
  const p = launch(file, args, { env });
  let out = "";
  p.onOutput((t) => {
    out += t;
  });
  const timer = setTimeout(() => p.kill(), 20_000);
  const code = await p.exit;
  clearTimeout(timer);
  return { out, code };
}

/** The first Java there that says its version (17 or newer preferred over an older one). */
export async function findJava(o: {
  os: EmuOs;
  env: NodeJS.ProcessEnv;
  home: string;
  launch: Launch;
  exists?: (p: string) => Promise<boolean>;
}): Promise<{ path: string; major: number } | undefined> {
  const pathVar = Object.entries(o.env).find(([k]) => k.toUpperCase() === "PATH")?.[1] ?? "";
  const dirs = pathVar.split(o.os === "windows" ? ";" : delimiter).filter(Boolean);
  let older: { path: string; major: number } | undefined;
  for (const c of javaCandidates(o.os, o.env as EmuEnv, dirs, o.home)) {
    if (!(await (o.exists ?? isFile)(c))) continue;
    const r = await ask(o.launch, c, ["-version"], o.env);
    const major = parseJavaVersion(r.out);
    if (major === undefined) continue;
    if (major >= 17) return { path: c, major };
    older ??= { path: c, major };
  }
  return older;
}

// ---- sdkmanager's output ----

/**
 * sdkmanager asks «Accept? (y/N):» after showing a licence (`License android-sdk-license:`). The
 * answer is yes only for a licence the person accepted; any other is refused.
 */
export function licenceAnswer(
  text: string,
  accepted: ReadonlySet<string>,
): { id: string | undefined; yes: boolean } | undefined {
  if (!/Accept\?\s*\(y\/N\):?\s*$/i.test(text)) return undefined;
  const ids = [...text.matchAll(/License\s+([A-Za-z0-9._-]+):/g)];
  const id = ids.at(-1)?.[1];
  return { id, yes: id !== undefined && accepted.has(id) };
}

/** `[=====      ] 45% Downloading x86_64-35_r09.zip...` → 45 while downloading. */
export function downloadPercent(text: string): number | undefined {
  let pct: number | undefined;
  for (const m of text.matchAll(/(\d{1,3})%\s+Downloading/g)) pct = Number(m[1]);
  return pct !== undefined && pct <= 100 ? pct : undefined;
}

// ---- Unpacking a checked zip, inside one folder only ----

/** `inner` is inside `outer` (never `outer` itself, never above it). */
export function inside(outer: string, inner: string): boolean {
  const rel = relative(resolve(outer), resolve(inner));
  return rel !== "" && !rel.startsWith("..") && !isAbsolute(rel);
}

/** Unpacks a zip into `dir`; a member that would land outside it stops everything. */
export async function unzipInto(file: string, dir: string, signal: AbortSignal): Promise<void> {
  const unzip = new Unzip();
  unzip.register(UnzipInflate);
  const waits: Promise<void>[] = [];
  const open: WriteStream[] = [];
  let failure: Error | undefined;
  unzip.onfile = (f) => {
    const name = f.name.replace(/\\/g, "/");
    const target = resolve(dir, ...name.split("/").filter(Boolean));
    if (!inside(dir, target) || name.startsWith("/") || /^[A-Za-z]:/.test(name)) {
      failure ??= new InstallError("outside", `The archive has a file outside its folder: ${name}`);
      return;
    }
    if (name.endsWith("/")) {
      waits.push(mkdir(target, { recursive: true }).then(() => {}));
      return;
    }
    const ready = mkdir(resolve(target, ".."), { recursive: true });
    let ws: WriteStream | undefined;
    const queue: Uint8Array[] = [];
    let ended = false;
    const finished = new Promise<void>((done, fail) => {
      void ready.then(() => {
        ws = createWriteStream(target);
        open.push(ws);
        ws.on("error", fail);
        ws.on("finish", () => done());
        for (const q of queue) ws.write(q);
        if (ended) ws.end();
      }, fail);
    });
    waits.push(finished);
    f.ondata = (err, data, final) => {
      if (err) {
        failure ??= err;
        return;
      }
      if (ws) ws.write(data);
      else queue.push(data);
      if (final) {
        ended = true;
        ws?.end();
      }
    };
    f.start();
  };
  for await (const chunk of createReadStream(file, { highWaterMark: 1 << 20 })) {
    if (signal.aborted) throw new Error("cancelled");
    unzip.push(chunk as Uint8Array, false);
    if (failure) break;
    // Let the writes catch up: the archive is never all in memory.
    while (open.reduce((n, w) => n + w.writableLength, 0) > 32 << 20)
      await new Promise((r) => setTimeout(r, 10));
  }
  if (!failure) unzip.push(new Uint8Array(0), true);
  await Promise.allSettled(waits);
  for (const w of open) w.destroy();
  if (failure) throw failure;
  await Promise.all(waits);
}

/** The bytes of every file under a folder (0 when it is not there). */
export async function folderBytes(dir: string): Promise<number> {
  let n = 0;
  for (const e of await readdir(dir, { withFileTypes: true }).catch(() => [])) {
    const p = resolve(dir, e.name);
    if (e.isDirectory()) n += await folderBytes(p);
    else if (e.isFile()) n += (await stat(p).catch(() => null))?.size ?? 0;
  }
  return n;
}

// ---- The download of the cmdline-tools ----

async function fetchChecked(
  a: PinnedArchive,
  file: string,
  progress: (done: number) => void,
  signal: AbortSignal,
  fetchFn: typeof fetch,
): Promise<void> {
  const r = await fetchFn(a.url, { signal });
  if (!r.ok || !r.body)
    throw new InstallError("download", `${new URL(a.url).host} answered ${r.status}`);
  const hash = createHash("sha1");
  let done = 0;
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
  if (got !== a.sha1.toLowerCase())
    throw new InstallError(
      "checksum",
      `The download did not match Google's checksum (expected ${a.sha1}, got ${got})`,
    );
}

/** A cmdline-tools folder with the Java sdkmanager and avdmanager (latest first, then newest). */
export async function findCmdline(os: EmuOs, sdk: string): Promise<string | undefined> {
  const root = joinFor(os, sdk, "cmdline-tools");
  const dirs = await readdir(root).catch(() => [] as string[]);
  const ver = (d: string) => d.split(".").map((x) => Number.parseInt(x, 10) || 0);
  const sorted = dirs.sort((a, b) => {
    if (a === "latest") return -1;
    if (b === "latest") return 1;
    const [va, vb] = [ver(a), ver(b)];
    for (let i = 0; i < Math.max(va.length, vb.length); i++)
      if ((va[i] ?? 0) !== (vb[i] ?? 0)) return (vb[i] ?? 0) - (va[i] ?? 0);
    return 0;
  });
  for (const d of sorted) {
    const lib = joinFor(os, root, d, "lib");
    if (
      (await isFile(joinFor(os, lib, "sdkmanager-classpath.jar"))) &&
      (await isFile(joinFor(os, lib, "avdmanager-classpath.jar")))
    )
      return joinFor(os, root, d);
  }
  return undefined;
}

// ---- The run ----

export interface RunPlan extends PlannedInstall {
  os: EmuOs;
  arch: EmuArch;
  /** The licences the person accepted (all of the plan's, or none). */
  accepted: string[];
}

export interface RunDeps {
  fetch?: typeof fetch;
  launch?: Launch;
  /** The environment programs get (no secrets: `agentEnv`). */
  env: NodeJS.ProcessEnv;
  /** Tests: another archive instead of the pinned cmdline-tools. */
  cmdline?: PinnedArchive;
}

/** Runs a plan; every step of the job is a step of the plan. */
export async function runInstall(
  plan: RunPlan,
  h: JobHandle,
  d: RunDeps,
): Promise<{ target: string; avd?: string }> {
  const { os, target } = plan;
  const launch = d.launch ?? launchProgram;
  const java = plan.java?.path;
  if (!java) throw new InstallError("blocked", "No Java to run sdkmanager");
  const accepted = new Set(plan.accepted);
  if (plan.licenceIds.some((id) => !accepted.has(id)))
    throw new InstallError("licence", "The licences were not accepted");
  const work = joinFor(os, target, ".rasgeth-install");
  const must = (p: string) => {
    if (!inside(target, p)) throw new InstallError("outside", `${p} is outside ${target}`);
    return p;
  };
  await mkdir(target, { recursive: true });
  await mkdir(must(work), { recursive: true });
  let result: { target: string; avd?: string } = { target };
  try {
    let clt = await findCmdline(os, target);
    for (const s of plan.steps) {
      if (h.signal.aborted) throw new Error("cancelled");
      h.step(s.id);
      if (s.id === "cmdline-tools") {
        const a = d.cmdline ?? cmdlineArchive(os, plan.arch);
        const zip = must(joinFor(os, work, "cmdline-tools.zip"));
        await fetchChecked(a, zip, (n) => h.progress(n, a.size), h.signal, d.fetch ?? fetch);
        const into = must(joinFor(os, work, "unpacked"));
        await mkdir(into, { recursive: true });
        await unzipInto(zip, into, h.signal);
        const dest = must(cmdlineHome(os, target, plan.cmdlineDir ?? "latest"));
        if (await isDir(dest)) throw new InstallError("outside", `${dest} already exists`);
        await mkdir(joinFor(os, target, "cmdline-tools"), { recursive: true });
        await rename(joinFor(os, into, "cmdline-tools"), dest);
        if (os !== "windows")
          for (const f of await readdir(joinFor(os, dest, "bin")).catch(() => [] as string[]))
            await chmod(joinFor(os, dest, "bin", f), 0o755).catch(() => {});
        await rm(zip, { force: true });
        clt = dest;
        continue;
      }
      // The licences were read and accepted in the window: their yes is in `accepted`.
      if (s.id === "licences") continue;
      if (!clt) throw new InstallError("program", "No sdkmanager in this SDK");
      const tool = s.id === "avd" ? "avdmanager" : "sdkmanager";
      const javaArgs = [
        tool === "sdkmanager"
          ? `-Dcom.android.sdklib.toolsdir=${clt}`
          : `-Dcom.android.sdkmanager.toolsdir=${clt}`,
        `-Djava.io.tmpdir=${must(joinFor(os, work, "tmp"))}`,
        `-Djava.util.prefs.userRoot=${must(joinFor(os, work, "prefs"))}`,
        "-classpath",
        joinFor(os, clt, "lib", `${tool}-classpath.jar`),
        tool === "sdkmanager"
          ? "com.android.sdklib.tool.sdkmanager.SdkManagerCli"
          : "com.android.sdklib.tool.AvdManagerCli",
      ];
      await mkdir(joinFor(os, work, "tmp"), { recursive: true });
      const args =
        s.id === "avd"
          ? [
              "create",
              "avd",
              "--name",
              s.avd ?? "Rasgeth_Phone",
              "--package",
              s.package ?? "",
              "--device",
              AVD_DEVICE,
            ]
          : [`--sdk_root=${target}`, "--channel=0", "--install", s.package ?? ""];
      const env: NodeJS.ProcessEnv = {
        ...d.env,
        ANDROID_HOME: target,
        ANDROID_SDK_ROOT: target,
        // sdkmanager's own settings and cache stay in the work folder, not in the person's home.
        ANDROID_USER_HOME: must(joinFor(os, work, "user")),
        ...(plan.avdHome && { ANDROID_AVD_HOME: plan.avdHome }),
      };
      const size = s.bytes ?? null;
      let best = 0;
      let buffer = "";
      let refused: string | undefined;
      const p = launch(java, [...javaArgs, ...args], { env, cwd: work });
      const stop = () => p.kill();
      h.signal.addEventListener("abort", stop, { once: true });
      // sdkmanager prints its percent in bursts when it has no terminal: the bytes of its download
      // in `<sdk>/.temp` are read every second too, and the bar takes the larger.
      const temp = joinFor(os, target, ".temp");
      const watch =
        size && s.id !== "avd"
          ? setInterval(() => {
              void folderBytes(temp).then((n) => {
                if (n > best && !h.signal.aborted) {
                  best = Math.min(n, size);
                  h.progress(best, size);
                }
              });
            }, 1000)
          : undefined;
      p.onOutput((t) => {
        buffer = (buffer + t).slice(-20_000);
        const pct = downloadPercent(t);
        if (pct !== undefined && size) {
          best = Math.max(best, Math.round((pct / 100) * size));
          h.progress(best, size);
        }
        if (s.id === "avd" && /custom hardware profile/i.test(buffer.slice(-300))) {
          p.write("no\n");
          buffer += "\n";
        }
        const answer = licenceAnswer(buffer, accepted);
        if (answer) {
          if (!answer.yes) refused = answer.id ?? "unknown";
          p.write(answer.yes ? "y\n" : "n\n");
          buffer += "\n";
        }
      });
      const code = await p.exit;
      clearInterval(watch);
      h.signal.removeEventListener("abort", stop);
      if (h.signal.aborted) throw new Error("cancelled");
      if (refused)
        throw new InstallError(
          "licence",
          `sdkmanager asked for a licence the person did not accept: ${refused}`,
        );
      if (code !== 0 || /license is not accepted|Failed to install/i.test(buffer))
        throw new InstallError(
          "program",
          `${tool} ${s.id} ended with ${code}: ${buffer.replace(/\r/g, "\n").slice(-600)}`,
        );
      if (size) h.progress(size, size);
      if (s.id === "avd") result = { ...result, ...(s.avd && { avd: s.avd }) };
    }
  } finally {
    await rm(work, { recursive: true, force: true }).catch(() => {});
  }
  return result;
}

// ---- Plans kept for their yes ----

interface Stored {
  ownerId: string;
  at: number;
  plan: PlannedInstall & { os: EmuOs; arch: EmuArch };
}

const PLAN_TTL_MS = 30 * 60_000;
const CATALOG_TTL_MS = 60 * 60_000;

export interface InstallerOptions {
  jobs: Jobs;
  /** This machine's report and its settings (the SDK folder is remembered once installed). */
  machine: {
    report(fresh?: boolean): Promise<EmulatorReport>;
    settings(): { sdkPath: string | null };
    update(b: { sdkPath?: string | null }): Promise<unknown>;
  };
  env: () => NodeJS.ProcessEnv;
  /** The variables that say where SDKs and AVDs go (LOCALAPPDATA, ANDROID_AVD_HOME…). */
  places?: EmuEnv;
  home?: string;
  fetch?: typeof fetch;
  launch?: Launch;
  /** Tests: where Java is, instead of looking. */
  java?: () => Promise<{ path: string; major: number } | undefined>;
  cmdline?: PinnedArchive;
  now?: () => number;
}

/** What a folder holds, for the plan (an existing folder of other things is refused). */
async function targetState(os: EmuOs, p: string): Promise<TargetState> {
  const names = await readdir(p).catch(() => undefined);
  if (names === undefined) return "absent";
  if (!names.length) return "empty";
  const sdkDirs = ["platform-tools", "emulator", "cmdline-tools", "system-images", "licenses"];
  for (const n of names) if (sdkDirs.includes(n) && (await isDir(joinFor(os, p, n)))) return "sdk";
  return "other";
}

export class EmulatorInstaller {
  private readonly plans = new Map<string, Stored>();
  private catalog: { at: number; value: RepoCatalog; key: string } | undefined;
  private running: string | undefined;

  constructor(private readonly o: InstallerOptions) {}

  private now() {
    return (this.o.now ?? Date.now)();
  }

  private async readCatalog(os: EmuOs, arch: EmuArch): Promise<RepoCatalog | undefined> {
    const key = `${os}/${arch}`;
    if (this.catalog?.key === key && this.now() - this.catalog.at < CATALOG_TTL_MS)
      return this.catalog.value;
    try {
      const lists = await Promise.all(
        REPOSITORY_LISTS.map(async (url) => {
          const r = await (this.o.fetch ?? fetch)(url, { signal: AbortSignal.timeout(30_000) });
          if (!r.ok) throw new Error(`${url} answered ${r.status}`);
          return parseRepository(await r.text(), os, arch);
        }),
      );
      const value = mergeCatalogs(...lists);
      this.catalog = { at: this.now(), value, key };
      return value;
    } catch {
      return undefined;
    }
  }

  /** The plan for this machine, kept under an id when it can start (the window shows it). */
  async plan(ownerId: string, body: EmuInstallPlanBody): Promise<EmuInstallPlan> {
    const report = await this.o.machine.report(true);
    const env = this.o.env();
    const home = this.o.home ?? homedir();
    const { os, arch } = report;
    const launch = this.o.launch ?? launchProgram;
    const [java, catalog] = await Promise.all([
      this.o.java ? this.o.java() : findJava({ os, env, home, launch }),
      this.readCatalog(os, arch),
    ]);
    const first = planInstall({
      report,
      home,
      env: this.o.places ?? (process.env as EmuEnv),
      target: body.target,
      avdName: body.avdName,
      only: body.only,
      java,
      catalog,
    });
    const state = first.target ? await targetState(os, first.target) : "absent";
    const clt = first.target ? await findCmdline(os, first.target) : undefined;
    const latestTaken = first.target
      ? await isDir(joinFor(os, first.target, "cmdline-tools", "latest"))
      : false;
    const plan = planInstall({
      report,
      home,
      env: this.o.places ?? (process.env as EmuEnv),
      target: body.target,
      targetState: state,
      avdName: body.avdName,
      only: body.only,
      java,
      catalog,
      cmdline: { usable: clt !== undefined, latestTaken },
    });
    const { licenceIds, cmdlineDir: _dir, ...view } = plan;
    const licences = licenceIds.map((id) => ({ id, text: catalog?.licences[id] ?? "" }));
    this.sweep();
    if (plan.blocked) return { ...view, licences };
    const planId = randomUUID();
    this.plans.set(planId, { ownerId, at: this.now(), plan: { ...plan, os, arch } });
    return { ...view, licences, planId };
  }

  /**
   * The person's yes: the plan they saw, with their acceptance of its licences. A plan runs once;
   * one install at a time.
   */
  start(ownerId: string, b: { planId: string; licenceAccepted?: boolean | undefined }): Job {
    this.sweep();
    const s = this.plans.get(b.planId);
    if (!s || s.ownerId !== ownerId)
      throw new InstallError("no-plan", "This plan is not known any more: look again");
    if (s.plan.licenceIds.length && b.licenceAccepted !== true)
      throw new InstallError("licence", "The licences must be read and accepted first");
    if (this.running && this.o.jobs.get(ownerId, this.running)?.state === "running")
      throw new InstallError("busy", "An install is already running");
    this.plans.delete(b.planId);
    const plan: RunPlan = { ...s.plan, accepted: b.licenceAccepted ? s.plan.licenceIds : [] };
    const job = this.o.jobs.start(
      ownerId,
      "emulator_install",
      plan.steps.map((x) => x.id),
      async (h) => {
        const out = await runInstall(plan, h, {
          env: this.o.env(),
          ...(this.o.fetch && { fetch: this.o.fetch }),
          ...(this.o.launch && { launch: this.o.launch }),
          ...(this.o.cmdline && { cmdline: this.o.cmdline }),
        });
        // A folder Rasgeth would not find by itself is remembered as the person's SDK folder.
        const fresh = await this.o.machine.report(true).catch(() => undefined);
        const sameRoot = (a?: string) =>
          a !== undefined &&
          resolve(a)
            .toLowerCase()
            .replace(/[\\/]+$/, "") ===
            resolve(out.target)
              .toLowerCase()
              .replace(/[\\/]+$/, "");
        if (fresh && !sameRoot(fresh.android.sdk?.root))
          await this.o.machine.update({ sdkPath: out.target }).catch(() => {});
        return out;
      },
      { target: plan.target },
    );
    this.running = job.id;
    return job;
  }

  private sweep() {
    const limit = this.now() - PLAN_TTL_MS;
    for (const [id, s] of this.plans) if (s.at < limit) this.plans.delete(id);
  }
}
