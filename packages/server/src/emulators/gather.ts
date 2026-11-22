// Reading a machine for `detectEmulators` (3.11, phase 1). Read-only on purpose: files are read,
// adb is asked through its own socket only when its server already runs (looking never starts it),
// programs run without a shell (`execFile`) and only to ask (`emulator -accel-check`,
// `xcodebuild -version`, `xcrun simctl list`). Nothing is installed, started or changed.
import { execFile } from "node:child_process";
import { constants, existsSync } from "node:fs";
import { access, readdir, readFile, realpath, stat } from "node:fs/promises";
import { connect } from "node:net";
import { homedir } from "node:os";
import { delimiter } from "node:path";
import type { EmuAccel, EmuArch, EmuOs, IosReport } from "@redgiant/protocol";
import {
  avdHome,
  avdImage,
  type EmuEnv,
  type EmulatorFacts,
  joinFor,
  linuxAccel,
  parseAccelCheck,
  parseAdbDevices,
  parseAvdConfig,
  parseProperties,
  parseSimctl,
  parseStudioSdkPath,
  parseXcodeVersion,
  pickSdk,
  type SdkProbe,
  sdkCandidates,
  studioDirsNewestFirst,
  studioSettingsRoot,
} from "./detect.js";

export const osOf = (p: NodeJS.Platform = process.platform): EmuOs =>
  p === "win32" ? "windows" : p === "darwin" ? "macos" : "linux";
export const archOf = (a: string = process.arch): EmuArch => (a === "arm64" ? "arm64" : "x64");

const isDir = async (p: string) => (await stat(p).catch(() => null))?.isDirectory() ?? false;
const isFile = async (p: string) => (await stat(p).catch(() => null))?.isFile() ?? false;
const list = async (p: string) => readdir(p).catch(() => [] as string[]);
const text = async (p: string) => readFile(p, "utf8").catch(() => undefined);

function run(file: string, args: string[], timeoutMs: number) {
  return new Promise<{ out: string; code: number | null }>((resolve) => {
    execFile(
      file,
      args,
      { timeout: timeoutMs, windowsHide: true, maxBuffer: 8 << 20 },
      (err, stdout, stderr) => {
        const code = err ? (typeof err.code === "number" ? err.code : null) : 0;
        resolve({ out: `${stdout ?? ""}${stderr ?? ""}`, code });
      },
    );
  });
}

/** RedGiant runs in a container (Docker, Podman, LXC): emulators come from nodes there. */
export async function inContainer(): Promise<boolean> {
  if (process.platform !== "linux") return false;
  if (existsSync("/.dockerenv") || existsSync("/run/.containerenv")) return true;
  if (process.env.container) return true;
  const cg = await text("/proc/1/cgroup");
  if (cg && /docker|lxc|kubepods|containerd/.test(cg)) return true;
  const env = await readFile("/proc/1/environ").catch(() => undefined);
  return env ? /container=/.test(Buffer.from(env).toString("latin1")) : false;
}

/** Programs with this name on the PATH, resolved to their real place (WinGet's links included). */
async function onPath(os: EmuOs, name: string): Promise<string[]> {
  const exts = os === "windows" ? [".exe", ".bat", ".cmd"] : [""];
  const out: string[] = [];
  for (const dir of (process.env.PATH ?? "").split(delimiter).filter(Boolean))
    for (const e of exts) {
      const p = joinFor(os, dir, name + e);
      if (await isFile(p)) out.push(await realpath(p).catch(() => p));
    }
  return out;
}

async function probe(
  os: EmuOs,
  c: { path: string; source: SdkProbe["source"] },
): Promise<SdkProbe> {
  const has = async (d: string) => isDir(joinFor(os, c.path, d));
  const [pt, emu, cl, si] = await Promise.all([
    has("platform-tools"),
    has("emulator"),
    has("cmdline-tools"),
    has("system-images"),
  ]);
  return { ...c, isSdk: pt || emu || cl || si, emulator: emu };
}

/** Whether a folder the person names is an Android SDK (Settings › Emulators refuses others). */
export async function looksLikeSdk(path: string, os: EmuOs = osOf()): Promise<boolean> {
  return (await probe(os, { path, source: "custom" })).isSdk;
}

async function sdkDetails(os: EmuOs, root: string) {
  const rev = async (d: string) =>
    parseProperties((await text(joinFor(os, root, d, "source.properties"))) ?? "")["Pkg.Revision"];
  const exe = os === "windows" ? ".bat" : "";
  const cmdline =
    (
      await Promise.all(
        (
          await list(joinFor(os, root, "cmdline-tools"))
        ).map((v) => isFile(joinFor(os, root, "cmdline-tools", v, "bin", `sdkmanager${exe}`))),
      )
    ).some(Boolean) || (await isFile(joinFor(os, root, "tools", "bin", `sdkmanager${exe}`)));
  const images: string[] = [];
  for (const api of await list(joinFor(os, root, "system-images")))
    for (const tag of await list(joinFor(os, root, "system-images", api)))
      for (const abi of await list(joinFor(os, root, "system-images", api, tag)))
        if (await isDir(joinFor(os, root, "system-images", api, tag, abi)))
          images.push(`${api}/${tag}/${abi}`);
  const [emulator, platformTools] = await Promise.all([rev("emulator"), rev("platform-tools")]);
  return {
    ...(emulator && { emulator }),
    ...(platformTools && { platformTools }),
    cmdlineTools: cmdline,
    images: images.sort(),
  };
}

async function readAvds(os: EmuOs, home: string, env: EmuEnv) {
  const dir = avdHome(os, home, env);
  const out: EmulatorFacts["avds"] = [];
  for (const f of (await list(dir)).filter((n) => n.toLowerCase().endsWith(".ini")).sort()) {
    const name = f.slice(0, -4);
    const ini = parseProperties((await text(joinFor(os, dir, f))) ?? "");
    const path = ini.path ?? joinFor(os, dir, `${name}.avd`);
    const config = (await text(joinFor(os, path, "config.ini"))) ?? "";
    const image = avdImage(config);
    out.push({ report: parseAvdConfig(name, config, ini.target), ...(image && { image }) });
  }
  return out;
}

/** One request to adb's server on its socket; undefined when no server listens (never started). */
export function adbAsk(
  service: string,
  o: { port?: number; transport?: string; timeoutMs?: number } = {},
): Promise<string | undefined> {
  const port = o.port ?? (Number(process.env.ANDROID_ADB_SERVER_PORT) || 5037);
  const frame = (s: string) => `${Buffer.byteLength(s).toString(16).padStart(4, "0")}${s}`;
  return new Promise((resolve) => {
    const sock = connect({ host: "127.0.0.1", port });
    let buf = Buffer.alloc(0);
    let step: "transport" | "status" | "body" = o.transport ? "transport" : "status";
    const done = (v: string | undefined) => {
      sock.destroy();
      resolve(v);
    };
    sock.setTimeout(o.timeoutMs ?? 2000, () => done(undefined));
    sock.on("error", () => done(undefined));
    sock.on("connect", () =>
      sock.write(frame(o.transport ? `host:transport:${o.transport}` : service)),
    );
    sock.on("data", (d) => {
      buf = Buffer.concat([buf, typeof d === "string" ? Buffer.from(d) : d]);
      if (step !== "body" && buf.length >= 4) {
        if (buf.subarray(0, 4).toString() !== "OKAY") return done(undefined);
        buf = buf.subarray(4);
        if (step === "transport") {
          step = "status";
          sock.write(frame(service));
        } else step = "body";
      }
      // host: services answer with a length; shell: runs until the device closes.
      if (step === "body" && service.startsWith("host:") && buf.length >= 4) {
        const len = Number.parseInt(buf.subarray(0, 4).toString(), 16);
        if (buf.length >= 4 + len) done(buf.subarray(4, 4 + len).toString());
      }
    });
    sock.on("end", () => done(step === "body" ? buf.toString() : undefined));
  });
}

async function accelOf(
  os: EmuOs,
  emulatorExe: string | undefined,
  container: boolean,
): Promise<EmuAccel> {
  if (os === "linux" && !emulatorExe) {
    const kvm = await access("/dev/kvm", constants.R_OK | constants.W_OK).then(
      () => "rw" as const,
      (e: NodeJS.ErrnoException) =>
        e.code === "ENOENT" ? ("absent" as const) : ("denied" as const),
    );
    return linuxAccel({ kvm, container });
  }
  if (!emulatorExe)
    return os === "macos" ? { ok: true, kind: "hvf" } : { ok: false, reason: "unknown" };
  const r = await run(emulatorExe, ["-accel-check"], 20_000);
  return parseAccelCheck(os, r.out, r.code);
}

async function iosOf(): Promise<EmulatorFacts["ios"]> {
  const x = await run("xcodebuild", ["-version"], 15_000);
  const xcode = x.code === 0 ? parseXcodeVersion(x.out) : undefined;
  if (!xcode) return { simulators: [] };
  const s = await run("xcrun", ["simctl", "list", "-j", "devices"], 20_000);
  const bridge: IosReport["bridge"] | undefined = (await onPath("macos", "serve-sim")).length
    ? "serve-sim"
    : (await onPath("macos", "idb")).length
      ? "idb"
      : undefined;
  return { xcode, simulators: s.code === 0 ? parseSimctl(s.out) : [], ...(bridge && { bridge }) };
}

export interface GatherOptions {
  custom?: string | null;
  maxRunning: number;
  /** Tests and nodes: another adb port. */
  adbPort?: number;
}

/** Everything this machine has, for `detectEmulators`. */
export async function gatherEmulatorFacts(o: GatherOptions): Promise<EmulatorFacts> {
  const os = osOf();
  const arch = archOf();
  const home = homedir();
  const env = process.env as EmuEnv;
  const container = await inContainer();
  const studioRoot = studioSettingsRoot(os, home, env);
  const studio: string[] = [];
  if (studioRoot)
    for (const d of studioDirsNewestFirst(await list(studioRoot))) {
      const xml = await text(joinFor(os, studioRoot, d, "options", "other.xml"));
      const p = xml && parseStudioSdkPath(xml);
      if (p) studio.push(p);
    }
  const pathTools = [...(await onPath(os, "adb")), ...(await onPath(os, "emulator"))];
  const looked = sdkCandidates({ os, home, env, custom: o.custom, studio, pathTools });
  const chosen = pickSdk(await Promise.all(looked.map((c) => probe(os, c))));
  const sdk = chosen && {
    root: chosen.path,
    source: chosen.source,
    ...(await sdkDetails(os, chosen.path)),
  };
  const emulatorExe =
    sdk?.emulator !== undefined
      ? joinFor(os, sdk.root, "emulator", os === "windows" ? "emulator.exe" : "emulator")
      : undefined;
  const raw = await adbAsk("host:devices-l", { ...(o.adbPort && { port: o.adbPort }) });
  const attached = raw === undefined ? undefined : parseAdbDevices(raw);
  const runningAvds: Record<string, string> = {};
  for (const d of attached ?? [])
    if (d.kind === "emulator" && d.state === "device") {
      const name = await adbAsk("shell:getprop ro.boot.qemu.avd_name", {
        transport: d.serial,
        ...(o.adbPort && { port: o.adbPort }),
      });
      if (name?.trim()) runningAvds[d.serial] = name.trim();
    }
  return {
    os,
    arch,
    container,
    looked,
    ...(sdk && { sdk }),
    avds: await readAvds(os, home, env),
    ...(attached && { attached, runningAvds }),
    accel: await accelOf(os, emulatorExe, container),
    ...(os === "macos" && { ios: (await iosOf()) ?? { simulators: [] } }),
    maxRunning: o.maxRunning,
    at: new Date().toISOString(),
  };
}
