// The guided install of the Android SDK pieces (3.11, phase 5): pure functions, tested as a table.
// From a machine's report (and the person's choices) they decide the ordered steps for any person
// (Windows, macOS, Linux; x64 and arm64), the folder everything goes into, the licences to read and
// what cannot be done here (a container, no acceleration, no Java…). Nothing here downloads or
// runs anything: `install.ts` does, and only after the person's yes.
import {
  AVD_NAME_RE,
  type EmuArch,
  type EmuInstallBlock,
  type EmuInstallNote,
  type EmuInstallPlan,
  type EmuInstallStep,
  type EmulatorReport,
  type EmuOs,
} from "@redgiant/protocol";
import { avdHome, type EmuEnv, joinFor, nativeAbis, standardSdk } from "./detect.js";

/** Google's repository of SDK packages (the official one Android Studio uses). */
export const SDK_REPOSITORY = "https://dl.google.com/android/repository/";
/** The lists read when planning: packages, sizes and the licence texts. */
export const REPOSITORY_LISTS = [
  `${SDK_REPOSITORY}repository2-3.xml`,
  `${SDK_REPOSITORY}sys-img/google_apis/sys-img2-3.xml`,
] as const;

export interface PinnedArchive {
  url: string;
  size: number;
  /** Google publishes SHA-1 for its SDK archives. */
  sha1: string;
}

/**
 * The command-line tools, pinned (read from Google's repository2-3.xml on 2026-11-22). 22.0 is the
 * last with the Java sdkmanager and avdmanager: 23.0 turns sdkmanager into a wrapper of the new
 * «android» program, which unpacks itself into the person's home and sends usage data.
 */
export const CMDLINE_TOOLS = {
  version: "22.0",
  licence: "android-sdk-license",
  archives: {
    windows: {
      url: `${SDK_REPOSITORY}commandlinetools-win-15859902_latest.zip`,
      size: 155_655_386,
      sha1: "b9862337a13e2809a5159dc3a08d058091bd59f6",
    },
    linux: {
      url: `${SDK_REPOSITORY}commandlinetools-linux-15859902_latest.zip`,
      size: 181_833_628,
      sha1: "040d3996a65543d22ec4bf73e4c37aa37a8d4af4",
    },
    "macos-x64": {
      url: `${SDK_REPOSITORY}commandlinetools-mac_x86_64-15859902_latest.zip`,
      size: 156_281_494,
      sha1: "1a79e61677b99cb0ce622792713cbea7ff2dc5de",
    },
    "macos-arm64": {
      url: `${SDK_REPOSITORY}commandlinetools-mac_arm64-15859902_latest.zip`,
      size: 156_083_281,
      sha1: "c4e0dbc53f1a4ce04fc2b11d4e2c4675001a95af",
    },
  } satisfies Record<string, PinnedArchive>,
} as const;

export function cmdlineArchive(os: EmuOs, arch: EmuArch): PinnedArchive {
  const a = CMDLINE_TOOLS.archives;
  return os === "windows" ? a.windows : os === "linux" ? a.linux : a[`macos-${arch}`];
}

/** The image installed for a new AVD: Android 15 with Google APIs, for this processor. */
export const IMAGE_API = 35;
export const imagePackage = (arch: EmuArch) =>
  `system-images;android-${IMAGE_API};google_apis;${arch === "arm64" ? "arm64-v8a" : "x86_64"}`;
export const DEFAULT_AVD_NAME = `Rasgeth_Phone_API_${IMAGE_API}`;
/** The hardware profile of a new AVD. */
export const AVD_DEVICE = "pixel_6";
/** Java's major version sdkmanager and avdmanager need. */
export const JAVA_MIN = 17;

/** Licences when Google's list could not say (the ones these packages used on 2026-11-22). */
const KNOWN_LICENCE: Record<string, string> = {
  "cmdline-tools": "android-sdk-license",
  "platform-tools": "android-sdk-license",
  emulator: "android-sdk-license",
};
const imageLicence = (pkg: string) =>
  pkg.endsWith(";arm64-v8a") ? "android-sdk-arm-dbt-license" : "android-sdk-license";

/** Google publishes an emulator for these systems only (Windows on ARM and Linux on ARM: none). */
export function emulatorSupported(os: EmuOs, arch: EmuArch): boolean {
  return os === "macos" || arch === "x64";
}

// ---- Google's repository lists ----

export interface RepoPackage {
  version: string;
  size?: number;
  licence?: string;
  url?: string;
  sha1?: string;
}

export interface RepoCatalog {
  /** By sdkmanager's path, stable channel only, the archive for this system. */
  packages: Record<string, RepoPackage>;
  licences: Record<string, string>;
}

const XML_ENTITIES: Record<string, string> = {
  "&lt;": "<",
  "&gt;": ">",
  "&quot;": '"',
  "&apos;": "'",
  "&amp;": "&",
};
const unescapeXml = (s: string) =>
  s.replace(/&(lt|gt|quot|apos|amp);/g, (m) => XML_ENTITIES[m] ?? m);

/**
 * One of Google's `repository2-3.xml` / `sys-img2-3.xml`: every package of the stable channel with
 * the archive for this system (`host-os` windows/macosx/linux, `host-arch` x64/aarch64 when
 * given), and every licence's full text.
 */
export function parseRepository(xml: string, os: EmuOs, arch: EmuArch): RepoCatalog {
  const licences: Record<string, string> = {};
  for (const m of xml.matchAll(/<license\s+id="([^"]+)"[^>]*>([\s\S]*?)<\/license>/g))
    if (m[1] && m[2] !== undefined) licences[m[1]] = unescapeXml(m[2]).trim();
  const stable = /<channel\s+id="([^"]+)"\s*>\s*stable\s*</.exec(xml)?.[1] ?? "channel-0";
  const hostOs = os === "macos" ? "macosx" : os;
  const hostArch = arch === "arm64" ? "aarch64" : "x64";
  const packages: Record<string, RepoPackage> = {};
  for (const m of xml.matchAll(/<remotePackage\s+path="([^"]+)"\s*>([\s\S]*?)<\/remotePackage>/g)) {
    const [, path, body = ""] = m;
    if (!path || packages[path]) continue;
    const channel = /<channelRef\s+ref="([^"]+)"/.exec(body)?.[1];
    if (channel && channel !== stable) continue;
    const rev = /<revision>([\s\S]*?)<\/revision>/.exec(body)?.[1] ?? "";
    const version = ["major", "minor", "micro"]
      .map((k) => new RegExp(`<${k}>(\\d+)</${k}>`).exec(rev)?.[1])
      .filter((x) => x !== undefined)
      .join(".");
    const licence = /<uses-license\s+ref="([^"]+)"/.exec(body)?.[1];
    let archive: RepoPackage | undefined;
    for (const a of body.matchAll(/<archive>([\s\S]*?)<\/archive>/g)) {
      const ab = a[1] ?? "";
      const aos = /<host-os>([^<]+)</.exec(ab)?.[1];
      const aarch = /<host-arch>([^<]+)</.exec(ab)?.[1];
      if ((aos && aos !== hostOs) || (aarch && aarch !== hostArch)) continue;
      const size = Number(/<size>(\d+)</.exec(ab)?.[1]);
      const sha1 = /<checksum\s+type="sha1">([0-9a-f]+)</i.exec(ab)?.[1];
      const url = /<url>([^<]+)</.exec(ab)?.[1];
      archive = {
        version,
        ...(Number.isFinite(size) && size > 0 && { size }),
        ...(sha1 && { sha1 }),
        ...(url && { url }),
      };
      break;
    }
    // A package without an archive for this system cannot be installed here.
    if (archive) packages[path] = { ...archive, ...(licence && { licence }) };
  }
  return { packages, licences };
}

export function mergeCatalogs(...cs: RepoCatalog[]): RepoCatalog {
  const out: RepoCatalog = { packages: {}, licences: {} };
  for (const c of cs) {
    out.packages = { ...c.packages, ...out.packages };
    out.licences = { ...c.licences, ...out.licences };
  }
  return out;
}

// ---- The plan ----

/** What the folder chosen holds (read by the installer before planning). */
export type TargetState = "absent" | "empty" | "sdk" | "other";

export interface PlanFacts {
  report: EmulatorReport;
  home: string;
  env: EmuEnv;
  /** The person's folder for the SDK, when they chose one. */
  target?: string | undefined;
  targetState?: TargetState | undefined;
  avdName?: string | undefined;
  only?: "emulator-update" | undefined;
  /** The Java found; undefined when none. */
  java?: { path: string; major: number } | undefined;
  /** Google's lists; undefined when they could not be read. */
  catalog?: RepoCatalog | undefined;
  /**
   * The SDK's cmdline-tools: usable when one of its folders has the Java sdkmanager
   * (`lib/sdkmanager-classpath.jar`); `latestTaken` when `cmdline-tools/latest` exists anyway.
   */
  cmdline?: { usable: boolean; latestTaken: boolean } | undefined;
}

export type PlannedInstall = Omit<EmuInstallPlan, "planId" | "licences"> & {
  /** The licences to show and accept, in order. */
  licenceIds: string[];
  /** For `cmdline-tools`: the folder under `<sdk>/cmdline-tools`. */
  cmdlineDir?: string;
};

const keyOf = (os: EmuOs, p: string) => {
  const n = p
    .trim()
    .replace(/[\\/]+$/, "")
    .replace(/\\/g, "/");
  return os === "linux" ? n : n.toLowerCase();
};

export const isAbsoluteFor = (os: EmuOs, p: string) =>
  os === "windows" ? /^([A-Za-z]:[\\/]|\\\\[^\\/]+[\\/][^\\/]+)/.test(p) : p.startsWith("/");

/** `android-35/google_apis_playstore/x86_64` → `system-images;android-35;google_apis_playstore;x86_64`. */
const imageIdToPackage = (id: string) => `system-images;${id.split("/").join(";")}`;

/** A free AVD name: the person's (or the default), with `_2`, `_3`… when one already has it. */
export function freeAvdName(wanted: string, taken: readonly string[]): string {
  const used = new Set(taken.map((n) => n.toLowerCase()));
  if (!used.has(wanted.toLowerCase())) return wanted;
  for (let i = 2; ; i++) {
    const n = `${wanted.slice(0, 60)}_${i}`;
    if (!used.has(n.toLowerCase())) return n;
  }
}

/**
 * The ordered steps for this machine. A plan that cannot run says why (`blocked`) and what to do
 * instead (`notes`); Xcode and the iOS bridge are only ever explained, never installed.
 */
export function planInstall(f: PlanFacts): PlannedInstall {
  const r = f.report;
  const { os, arch } = r;
  const notes: EmuInstallNote[] = [];
  if (os === "macos") {
    if (r.missing.includes("xcode")) notes.push("xcode");
    else if (r.missing.includes("ios-bridge")) notes.push("ios-bridge");
  }
  const sdk = r.android.sdk;
  // An SDK made only of adb from WinGet or a package manager (found around adb on the PATH) is not
  // a place to install into: the new SDK goes to the standard place.
  const sdkUsable =
    sdk &&
    (sdk.source !== "path" || sdk.emulator !== undefined || sdk.cmdlineTools || sdk.images.length);
  const target =
    (f.target?.trim() || (sdkUsable ? sdk.root : standardSdk(os, f.home, f.env))) ?? "";
  const existing = sdk && target && keyOf(os, target) === keyOf(os, sdk.root) ? sdk : undefined;
  const base = {
    target,
    targetStandard: !f.target?.trim() && !sdkUsable,
    avdHome: avdHome(os, f.home, f.env),
    notes,
    ...(f.java && { java: f.java }),
  };
  const stop = (blocked: EmuInstallBlock, extra: Partial<PlannedInstall> = {}): PlannedInstall => ({
    ...base,
    steps: [],
    bytes: 0,
    licenceIds: [],
    blocked,
    ...extra,
  });

  if (r.container) return stop("container", { notes: [...notes, "node"] });
  if (!emulatorSupported(os, arch)) return stop("unsupported", { notes: [...notes, "node"] });
  const accel = r.android.accel;
  const slow =
    r.missing.includes("accel") &&
    (accel.reason === "no-kvm" ||
      accel.reason === "kvm-denied" ||
      accel.reason === "container" ||
      accel.reason === "disabled");
  if (slow && f.only !== "emulator-update")
    return stop("no-accel", {
      ...(accel.reason && { accelReason: accel.reason }),
      notes: [
        ...notes,
        ...(accel.reason === "kvm-denied" ? (["kvm-group"] as const) : []),
        ...(accel.reason === "disabled" ? (["bios"] as const) : []),
        "node",
      ],
    });
  if (!target || !isAbsoluteFor(os, target)) return stop("folder-relative");
  if (!existing && f.targetState === "other") return stop("folder-not-empty");

  const pkgSteps: EmuInstallStep[] = [];
  const abis = nativeAbis(arch);
  const nativeImages = (existing?.images ?? []).filter((i) => abis.includes(i.split("/")[2] ?? ""));
  const running = r.android.attached.some((d) => d.kind === "emulator");
  const avdName = freeAvdName(
    f.avdName && AVD_NAME_RE.test(f.avdName) ? f.avdName : DEFAULT_AVD_NAME,
    r.android.avds.map((a) => a.name),
  );
  const pkg = (id: EmuInstallStep["id"], name: string): EmuInstallStep => {
    const c = f.catalog?.packages[name];
    return {
      id,
      package: name,
      ...(c?.size && { bytes: c.size }),
      ...(c?.version && { version: c.version }),
    };
  };
  if (f.only === "emulator-update") {
    if (existing?.emulator && r.missing.includes("emulator-old"))
      pkgSteps.push(pkg("emulator-update", "emulator"));
  } else {
    if (!existing?.platformTools) pkgSteps.push(pkg("platform-tools", "platform-tools"));
    if (!existing?.emulator) pkgSteps.push(pkg("emulator", "emulator"));
    // The emulator cannot be replaced while one runs: the rest goes on, the update waits.
    else if (r.missing.includes("emulator-old") && !running)
      pkgSteps.push(pkg("emulator-update", "emulator"));
    let image = nativeImages.length
      ? imageIdToPackage(
          // The newest API first.
          [...nativeImages].sort(
            (a, b) =>
              Number(/android-(\d+)/.exec(b)?.[1] ?? 0) - Number(/android-(\d+)/.exec(a)?.[1] ?? 0),
          )[0] as string,
        )
      : undefined;
    if (!image) {
      image = imagePackage(arch);
      pkgSteps.push(pkg("system-image", image));
    }
    if (!existing || r.missing.includes("avd"))
      pkgSteps.push({ id: "avd", package: image, avd: avdName });
  }
  const needCmdline = !existing || !existing.cmdlineTools || f.cmdline?.usable === false;
  if (!pkgSteps.length && !(needCmdline && r.missing.includes("cmdline-tools")))
    return stop("nothing");
  if (running && pkgSteps.some((s) => s.id === "emulator-update")) return stop("emulators-running");

  const steps: EmuInstallStep[] = [];
  let cmdlineDir: string | undefined;
  if (needCmdline) {
    const a = cmdlineArchive(os, arch);
    cmdlineDir = f.cmdline?.latestTaken ? CMDLINE_TOOLS.version : "latest";
    steps.push({ id: "cmdline-tools", bytes: a.size, version: CMDLINE_TOOLS.version });
  }
  const downloads = pkgSteps.filter((s) => s.id !== "avd");
  const licenceIds: string[] = [];
  const addLicence = (id: string | undefined) => {
    if (id && !licenceIds.includes(id)) licenceIds.push(id);
  };
  if (needCmdline) addLicence(CMDLINE_TOOLS.licence);
  for (const s of downloads)
    addLicence(
      f.catalog?.packages[s.package ?? ""]?.licence ??
        (s.id === "system-image"
          ? imageLicence(s.package ?? "")
          : (KNOWN_LICENCE[s.package ?? ""] ?? "android-sdk-license")),
    );
  if (licenceIds.length) steps.push({ id: "licences" });
  steps.push(...pkgSteps);
  const planned: PlannedInstall = {
    ...base,
    steps,
    bytes: steps.reduce((n, s) => n + (s.bytes ?? 0), 0),
    licenceIds,
    ...(cmdlineDir && { cmdlineDir }),
  };
  // Every step after the download of the tools runs sdkmanager or avdmanager, which need Java.
  if (!f.java) return { ...planned, blocked: "no-java" };
  if (f.java.major < JAVA_MIN) return { ...planned, blocked: "java-old" };
  // Without Google's lists the licences cannot be shown: nothing starts.
  if (!f.catalog || licenceIds.some((id) => !f.catalog?.licences[id]))
    return { ...planned, blocked: "offline" };
  return planned;
}

/** Where the cmdline-tools of a plan live once installed (sdkmanager runs from there). */
export const cmdlineHome = (os: EmuOs, target: string, dir: string) =>
  joinFor(os, target, "cmdline-tools", dir);
