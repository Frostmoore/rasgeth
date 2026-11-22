// Finding emulators (3.11, phase 1): pure functions, tested as tables. `gather.ts` reads the
// machine (files, adb's socket when its server already runs, `emulator -accel-check`) and these
// decide where an Android SDK is, which AVDs and devices there are and what is missing. Nothing
// here knows a particular machine: the SDK is looked for where any person may have it (the folder
// chosen in Settings, ANDROID_HOME, ANDROID_SDK_ROOT, Android Studio's settings, the place Studio
// installs to, adb or the emulator on the PATH), on Windows, macOS and Linux, x64 and arm64.
import {
  type AttachedDevice,
  type AvdReport,
  type EmuAccel,
  type EmuArch,
  type EmulatorReport,
  type EmuMissing,
  type EmuOs,
  type IosReport,
  RECOMMENDED_EMULATOR,
  type SdkSource,
  versionBelow,
} from "@redgiant/protocol";

/** The environment variables that matter here (absent ones are undefined or empty). */
export interface EmuEnv {
  ANDROID_HOME?: string | undefined;
  ANDROID_SDK_ROOT?: string | undefined;
  ANDROID_USER_HOME?: string | undefined;
  ANDROID_EMULATOR_HOME?: string | undefined;
  ANDROID_AVD_HOME?: string | undefined;
  LOCALAPPDATA?: string | undefined;
  APPDATA?: string | undefined;
  XDG_CONFIG_HOME?: string | undefined;
}

/** Paths are joined with the machine's own separator, never the server's (nodes report theirs). */
export function joinFor(os: EmuOs, ...parts: string[]): string {
  const sep = os === "windows" ? "\\" : "/";
  return parts
    .filter((p) => p !== "")
    .map((p, i) => (i === 0 ? p.replace(/[\\/]+$/, "") : p.replace(/^[\\/]+|[\\/]+$/g, "")))
    .join(sep);
}

const set = (v: string | undefined | null): v is string => typeof v === "string" && v.trim() !== "";

/** Comparison key of a path: Windows and macOS file systems ignore case. */
const keyOf = (os: EmuOs, p: string) => {
  const n = p.replace(/[\\/]+$/, "").replace(/\\/g, "/");
  return os === "linux" ? n : n.toLowerCase();
};

/** Where Android Studio puts the SDK when the person accepts its default. */
export function standardSdk(os: EmuOs, home: string, env: EmuEnv): string | undefined {
  if (os === "windows")
    return set(env.LOCALAPPDATA)
      ? joinFor(os, env.LOCALAPPDATA, "Android", "Sdk")
      : set(home)
        ? joinFor(os, home, "AppData", "Local", "Android", "Sdk")
        : undefined;
  if (!set(home)) return undefined;
  return os === "macos"
    ? joinFor(os, home, "Library", "Android", "sdk")
    : joinFor(os, home, "Android", "Sdk");
}

/** The folders that hold Android Studio's settings (`AndroidStudio<version>/options/other.xml`). */
export function studioSettingsRoot(os: EmuOs, home: string, env: EmuEnv): string | undefined {
  if (os === "windows")
    return set(env.APPDATA)
      ? joinFor(os, env.APPDATA, "Google")
      : set(home)
        ? joinFor(os, home, "AppData", "Roaming", "Google")
        : undefined;
  if (!set(home) && !set(env.XDG_CONFIG_HOME)) return undefined;
  if (os === "macos") return joinFor(os, home, "Library", "Application Support", "Google");
  return joinFor(
    os,
    set(env.XDG_CONFIG_HOME) ? env.XDG_CONFIG_HOME : joinFor(os, home, ".config"),
    "Google",
  );
}

/** Studio's settings folders, newest version first (`AndroidStudio2025.1` before `…2024.2`). */
export function studioDirsNewestFirst(names: readonly string[]): string[] {
  const ver = (n: string) => n.replace(/^AndroidStudio(Preview)?/i, "");
  return names
    .filter((n) => /^AndroidStudio/i.test(n))
    .sort((a, b) => (versionBelow(ver(a), ver(b)) ? 1 : versionBelow(ver(b), ver(a)) ? -1 : 0));
}

/** Where AVDs live (the emulator's own rules: ANDROID_AVD_HOME, then the user home's `avd`). */
export function avdHome(os: EmuOs, home: string, env: EmuEnv): string {
  if (set(env.ANDROID_AVD_HOME)) return env.ANDROID_AVD_HOME;
  if (set(env.ANDROID_USER_HOME)) return joinFor(os, env.ANDROID_USER_HOME, "avd");
  if (set(env.ANDROID_EMULATOR_HOME)) return joinFor(os, env.ANDROID_EMULATOR_HOME, "avd");
  return joinFor(os, home, ".android", "avd");
}

/** The SDK around a program found on the PATH (`<sdk>/platform-tools/adb`, `<sdk>/emulator/emulator`). */
export function sdkRootOfTool(os: EmuOs, tool: string): string | undefined {
  const parts = tool.split(/[\\/]/);
  const dir = parts.at(-2)?.toLowerCase();
  if (dir !== "platform-tools" && dir !== "emulator") return undefined;
  const root = parts.slice(0, -2);
  if (!root.length || (root.length === 1 && root[0] === "")) return undefined;
  return root.join(os === "windows" ? "\\" : "/");
}

/**
 * Every place an SDK may be, in order, without repeats: the person's folder first (their choice
 * wins), then the environment, Android Studio's own setting, Studio's default place, and the SDK
 * around adb or the emulator on the PATH.
 */
export function sdkCandidates(o: {
  os: EmuOs;
  home: string;
  env: EmuEnv;
  custom?: string | null | undefined;
  /** `android.sdk.path` from Studio's settings, newest Studio first. */
  studio?: readonly string[];
  /** adb or emulator programs found on the PATH. */
  pathTools?: readonly string[];
}): { path: string; source: SdkSource }[] {
  const out: { path: string; source: SdkSource }[] = [];
  const seen = new Set<string>();
  const add = (path: string | undefined | null, source: SdkSource) => {
    if (!set(path)) return;
    const p = path.trim();
    const k = keyOf(o.os, p);
    if (seen.has(k)) return;
    seen.add(k);
    out.push({ path: p, source });
  };
  add(o.custom, "custom");
  add(o.env.ANDROID_HOME, "ANDROID_HOME");
  add(o.env.ANDROID_SDK_ROOT, "ANDROID_SDK_ROOT");
  for (const s of o.studio ?? []) add(s, "studio");
  add(standardSdk(o.os, o.home, o.env), "standard");
  for (const t of o.pathTools ?? []) add(sdkRootOfTool(o.os, t), "path");
  return out;
}

/** What a candidate folder holds (read by `gather`). */
export interface SdkProbe {
  path: string;
  source: SdkSource;
  /** It has platform-tools, emulator, cmdline-tools or system-images: an SDK at all. */
  isSdk: boolean;
  emulator: boolean;
}

/**
 * The SDK to use: the person's folder when it is an SDK (their choice wins), otherwise the first
 * with an emulator (an SDK made only of adb, as WinGet's, is not enough to start one), otherwise
 * the first SDK at all.
 */
export function pickSdk(probes: readonly SdkProbe[]): SdkProbe | undefined {
  const custom = probes.find((p) => p.source === "custom" && p.isSdk);
  return custom ?? probes.find((p) => p.isSdk && p.emulator) ?? probes.find((p) => p.isSdk);
}

/** `key=value` lines (`source.properties`, an AVD's `config.ini`). */
export function parseProperties(text: string): Record<string, string> {
  const out: Record<string, string> = {};
  for (const line of text.split(/\r?\n/)) {
    const m = /^\s*([^#=\s][^=]*?)\s*=\s*(.*?)\s*$/.exec(line);
    if (m?.[1] !== undefined && m[2] !== undefined) out[m[1]] = m[2];
  }
  return out;
}

/**
 * The SDK folder Android Studio remembers, from its `options/other.xml`: newer Studios keep a JSON
 * map (`"android.sdk.path": "D:\\sdk"`), older ones a `<property name="android.sdk.path" …/>`.
 */
export function parseStudioSdkPath(xml: string): string | undefined {
  const json = /"android\.sdk\.path"\s*:\s*"((?:[^"\\]|\\.)*)"/.exec(xml);
  if (json?.[1] !== undefined) {
    try {
      const v = JSON.parse(`"${json[1]}"`) as string;
      return set(v) ? v : undefined;
    } catch {
      return undefined;
    }
  }
  const prop = /<property\s+name="android\.sdk\.path"\s+value="([^"]*)"/.exec(xml);
  const v = prop?.[1]?.replace(/&amp;/g, "&").replace(/&quot;/g, '"');
  return set(v) ? v : undefined;
}

/** A system image's id from its folder or `image.sysdir.1` (`android-35/google_apis/x86_64`). */
export function imageId(sysdir: string): string | undefined {
  const parts = sysdir.split(/[\\/]/).filter(Boolean);
  const i = parts.findIndex((p) => p.toLowerCase() === "system-images");
  const rest = i >= 0 ? parts.slice(i + 1) : parts;
  return rest.length >= 3 ? rest.slice(0, 3).join("/") : undefined;
}

/** One AVD from its `config.ini` (and the `target` of its `<name>.ini`, when known). */
export function parseAvdConfig(name: string, configIni: string, target?: string): AvdReport {
  const c = parseProperties(configIni);
  const img = c["image.sysdir.1"] ? imageId(c["image.sysdir.1"]) : undefined;
  const api = /android-(\d+)/.exec(img ?? target ?? c.target ?? "")?.[1];
  const tag = c["tag.id"] ?? img?.split("/")[1];
  const abi = c["abi.type"] ?? img?.split("/")[2];
  return {
    name,
    ...(c["hw.device.name"] && { device: c["hw.device.name"] }),
    ...(api && { api: Number(api) }),
    ...(abi && { abi }),
    ...(tag && { tag }),
    ...((c["PlayStore.enabled"] === "true" || c["PlayStore.enabled"] === "yes") && {
      playStore: true,
    }),
  };
}

/** The image an AVD needs, from its config (`android-35/google_apis_playstore/x86_64`). */
export function avdImage(configIni: string): string | undefined {
  const c = parseProperties(configIni);
  return c["image.sysdir.1"] ? imageId(c["image.sysdir.1"]) : undefined;
}

/**
 * adb's `host:devices-l` answer: one device per line, `serial state key:value…`. Emulators are
 * `emulator-<port>`; a phone over Wi-Fi is `ip:port` or an mDNS `adb-…._adb-tls-connect._tcp`.
 */
export function parseAdbDevices(text: string): AttachedDevice[] {
  const out: AttachedDevice[] = [];
  for (const line of text.split(/\r?\n/)) {
    const m = /^(\S+)\s+(\S+)(.*)$/.exec(line.trim());
    if (!m?.[1] || !m[2] || m[1] === "List") continue;
    const [, serial, rawState, rest = ""] = m;
    const props = Object.fromEntries(
      [...rest.matchAll(/(\w+):(\S+)/g)].map((x) => [x[1] as string, x[2] as string]),
    );
    const state: AttachedDevice["state"] =
      rawState === "device" || rawState === "unauthorized" || rawState === "offline"
        ? rawState
        : "other";
    const emulator = /^emulator-\d+$/.test(serial);
    const wifi = /:\d+$/.test(serial) || serial.includes("._adb-tls-connect.");
    out.push({
      serial,
      kind: emulator ? "emulator" : "phone",
      state,
      ...(!emulator && { link: wifi ? "wifi" : "usb" }),
      ...(props.model && { model: props.model.replace(/_/g, " ") }),
    });
  }
  return out;
}

/** `emulator -accel-check`: exit 0 and «… is installed and usable» means acceleration works. */
export function parseAccelCheck(os: EmuOs, output: string, exitCode: number | null): EmuAccel {
  const text = output.toLowerCase();
  const kind: EmuAccel["kind"] | undefined = text.includes("whpx")
    ? "whpx"
    : text.includes("aehd") || text.includes("gvm")
      ? "aehd"
      : text.includes("haxm")
        ? "haxm"
        : text.includes("hvf") || text.includes("hypervisor.framework")
          ? "hvf"
          : text.includes("kvm")
            ? "kvm"
            : undefined;
  if (exitCode === 0 && text.includes("usable")) return { ok: true, ...(kind && { kind }) };
  const reason: EmuAccel["reason"] =
    os === "linux" && /\/dev\/kvm.*(not found|does not exist)/.test(text)
      ? "no-kvm"
      : os === "linux" && /permission|access/.test(text)
        ? "kvm-denied"
        : /disabled|not enabled|bios|vt-x|svm|vmx/.test(text)
          ? "disabled"
          : "unknown";
  return { ok: false, ...(kind && { kind }), reason };
}

/** Linux without the emulator to ask: /dev/kvm decides (a container usually has none). */
export function linuxAccel(o: { kvm: "rw" | "denied" | "absent"; container: boolean }): EmuAccel {
  if (o.kvm === "rw") return { ok: true, kind: "kvm" };
  if (o.kvm === "denied") return { ok: false, kind: "kvm", reason: "kvm-denied" };
  return { ok: false, reason: o.container ? "container" : "no-kvm" };
}

/** `xcrun simctl list -j devices`: every simulator with its runtime's readable name. */
export function parseSimctl(json: string): IosReport["simulators"] {
  let data: {
    devices?: Record<
      string,
      { name?: string; udid?: string; state?: string; isAvailable?: boolean }[]
    >;
  };
  try {
    data = JSON.parse(json);
  } catch {
    return [];
  }
  const out: IosReport["simulators"] = [];
  for (const [runtime, list] of Object.entries(data.devices ?? {})) {
    // com.apple.CoreSimulator.SimRuntime.iOS-27-2 → iOS 27.2
    const m = /SimRuntime\.([A-Za-z]+)-(\d+(?:-\d+)*)$/.exec(runtime);
    const name = m ? `${m[1]} ${m[2]?.replace(/-/g, ".")}` : runtime;
    for (const d of list ?? []) {
      if (d.isAvailable === false || !d.name || !d.udid) continue;
      const s = (d.state ?? "").toLowerCase();
      out.push({
        name: d.name,
        udid: d.udid,
        runtime: name,
        state: s === "booted" ? "booted" : s === "shutdown" ? "shutdown" : "other",
      });
    }
  }
  return out;
}

/** `xcodebuild -version` → «27.2». */
export function parseXcodeVersion(text: string): string | undefined {
  return /Xcode\s+(\d+(?:\.\d+)*)/.exec(text)?.[1];
}

/** The ABIs a machine runs fast (an image for another processor would be emulated, too slow). */
export function nativeAbis(arch: EmuArch): string[] {
  return arch === "arm64" ? ["arm64-v8a"] : ["x86_64", "x86"];
}

/** Everything `gather` read, the input of `detectEmulators`. */
export interface EmulatorFacts {
  os: EmuOs;
  arch: EmuArch;
  container: boolean;
  looked: { path: string; source: SdkSource }[];
  /** The first candidate that is really an SDK (has platform-tools, emulator or system-images). */
  sdk?: {
    root: string;
    source: SdkSource;
    emulator?: string;
    platformTools?: string;
    cmdlineTools: boolean;
    images: string[];
  };
  /** AVDs with the image each one needs. */
  avds: { report: AvdReport; image?: string }[];
  /** undefined: adb's server is not running (not started just to look). */
  attached?: AttachedDevice[];
  /** The AVD each running emulator runs (`emu avd name` over its console), by serial. */
  runningAvds?: Record<string, string>;
  accel: EmuAccel;
  ios?: { xcode?: string; simulators: IosReport["simulators"]; bridge?: IosReport["bridge"] };
  maxRunning: number;
  at: string;
}

/** The report: what there is, what is missing (most important first), and whether it is ready. */
export function detectEmulators(f: EmulatorFacts): EmulatorReport {
  const images = f.sdk?.images ?? [];
  const have = new Set(images.map((i) => i.toLowerCase()));
  const avds = f.avds.map(({ report, image }) =>
    image && f.sdk && !have.has(image.toLowerCase()) ? { ...report, imageMissing: true } : report,
  );
  const abis = nativeAbis(f.arch);
  const fast = (abi: string | undefined) => abi !== undefined && abis.includes(abi);
  const usable = avds.filter((a) => !a.imageMissing && (a.abi === undefined || fast(a.abi)));
  const missing: EmuMissing[] = [];
  if (!f.sdk) missing.push("sdk");
  else {
    if (!f.sdk.emulator) missing.push("emulator");
    if (!f.sdk.platformTools) missing.push("platform-tools");
  }
  // Unknown acceleration is only a lack once there is an emulator to ask (Windows without one
  // cannot tell).
  if (!f.accel.ok && (f.accel.reason !== "unknown" || f.sdk?.emulator)) missing.push("accel");
  if (f.sdk) {
    if (!f.sdk.cmdlineTools) missing.push("cmdline-tools");
    if (!images.some((i) => fast(i.split("/")[2]))) missing.push("system-image");
    if (!usable.length) missing.push("avd");
    if (f.sdk.emulator && versionBelow(f.sdk.emulator, RECOMMENDED_EMULATOR))
      missing.push("emulator-old");
  }
  if (f.os === "macos") {
    if (!f.ios?.xcode) missing.push("xcode");
    else if (!f.ios.bridge) missing.push("ios-bridge");
  }
  const attached = f.attached?.map((d): AttachedDevice => {
    const avd = d.kind === "emulator" ? f.runningAvds?.[d.serial] : undefined;
    return avd ? { ...d, avd } : d;
  });
  const sdk = f.sdk && {
    root: f.sdk.root,
    source: f.sdk.source,
    ...(f.sdk.emulator && { emulator: f.sdk.emulator }),
    ...(f.sdk.platformTools && { platformTools: f.sdk.platformTools }),
    cmdlineTools: f.sdk.cmdlineTools,
    images,
  };
  return {
    os: f.os,
    arch: f.arch,
    container: f.container,
    android: {
      ...(sdk && { sdk }),
      looked: f.looked,
      avds,
      attached: attached ?? [],
      ...(attached === undefined && { adbIdle: true }),
      accel: f.accel,
    },
    ...(f.os === "macos" && {
      ios: {
        ...(f.ios?.xcode && { xcode: f.ios.xcode }),
        simulators: f.ios?.simulators ?? [],
        ...(f.ios?.bridge && { bridge: f.ios.bridge }),
      },
    }),
    missing,
    ready: Boolean(f.sdk?.emulator) && usable.length > 0 && f.accel.ok,
    maxRunning: f.maxRunning,
    at: f.at,
  };
}
