// Emulators in the Canvas (3.11): what a machine has for Android emulators, real Android phones and
// (on macOS) iOS simulators, as `detectEmulators` found it there. Read-only: finding never installs,
// starts or changes anything (adb is asked only when its server already runs). The same report is
// shown in Settings › Emulators for this machine and, through `NodeCapabilities.emulators`, for
// every node.
import { z } from "zod";

export type EmuOs = "windows" | "macos" | "linux";
export type EmuArch = "x64" | "arm64";

/** Where an Android SDK was found, in the order it is looked for. */
export type SdkSource =
  | "custom" // the folder the person chose in Settings › Emulators
  | "ANDROID_HOME"
  | "ANDROID_SDK_ROOT"
  | "studio" // Android Studio's own settings (`android.sdk.path`)
  | "standard" // the place Android Studio installs to on this system
  | "path"; // adb or the emulator on the PATH, the SDK around them

export interface AndroidSdkReport {
  root: string;
  source: SdkSource;
  /** The emulator package's version (`emulator/source.properties`), if installed. */
  emulator?: string;
  /** platform-tools' version (adb). */
  platformTools?: string;
  /** `cmdline-tools` with `sdkmanager` and `avdmanager`. */
  cmdlineTools: boolean;
  /** System images there, as `android-35/google_apis_playstore/x86_64`. */
  images: string[];
}

export interface AvdReport {
  name: string;
  /** The hardware profile (`hw.device.name`), e.g. `pixel_6`. */
  device?: string;
  /** Android API level of its image. */
  api?: number;
  abi?: string;
  /** `google_apis_playstore`, `google_apis`, `default`… */
  tag?: string;
  playStore?: boolean;
  /** Its system image is not in the SDK found (it would not start). */
  imageMissing?: boolean;
}

/** A device adb sees: an emulator already running or a real phone (USB or Wi-Fi). */
export interface AttachedDevice {
  serial: string;
  kind: "emulator" | "phone";
  /** adb's state: `device` is usable; `unauthorized` waits for the yes on the phone. */
  state: "device" | "unauthorized" | "offline" | "other";
  /** How a phone is attached. */
  link?: "usb" | "wifi";
  model?: string;
  /** For an emulator: its AVD, when known. */
  avd?: string;
}

/** Hardware acceleration for x86_64/arm64 emulators. */
export interface EmuAccel {
  ok: boolean;
  /** whpx, aehd, haxm (Windows), hvf (macOS), kvm (Linux). */
  kind?: "whpx" | "aehd" | "haxm" | "hvf" | "kvm";
  /** Why not, when known. */
  reason?: "no-kvm" | "kvm-denied" | "container" | "disabled" | "unknown";
}

export interface IosReport {
  /** Xcode's version (`xcodebuild -version`), when installed. */
  xcode?: string;
  simulators: {
    name: string;
    udid: string;
    runtime: string;
    state: "booted" | "shutdown" | "other";
  }[];
  /** The bridge that sends touches (3.11.1), found on the PATH. */
  bridge?: "serve-sim" | "idb";
}

/**
 * What is missing, the most important first. The page has the words for each code; nothing is ever
 * installed without the person's yes (phase 5).
 */
export type EmuMissing =
  | "sdk" // no Android SDK at all: guided install, or choose its folder
  | "emulator" // SDK without the emulator package
  | "platform-tools" // no adb
  | "cmdline-tools" // no sdkmanager/avdmanager (needed to download images and create AVDs)
  | "system-image" // no system image for this processor
  | "avd" // no virtual device yet
  | "accel" // no hardware acceleration: emulators would be too slow
  | "emulator-old" // the emulator is older than RECOMMENDED_EMULATOR (an update is proposed)
  | "xcode" // macOS without Xcode (iOS simulators)
  | "ios-bridge"; // macOS with Xcode but no bridge for touches

export interface EmulatorReport {
  os: EmuOs;
  arch: EmuArch;
  /** RedGiant runs in a container here (Docker, LXC): no emulators, nodes bring them. */
  container: boolean;
  android: {
    sdk?: AndroidSdkReport;
    /** Every place looked at, in order (the page shows them when nothing was found). */
    looked: { path: string; source: SdkSource }[];
    avds: AvdReport[];
    attached: AttachedDevice[];
    /** adb's server was not running, so attached devices are unknown (it is never started to look). */
    adbIdle?: boolean;
    accel: EmuAccel;
  };
  /** macOS only. */
  ios?: IosReport;
  missing: EmuMissing[];
  /** Emulators can run here now (SDK, emulator, an AVD, acceleration). */
  ready: boolean;
  /** The person's limit of emulators running at once on this machine. */
  maxRunning: number;
  at: string;
}

/** Emulators older than this are proposed an update (HAXM went in 36.2, AEHD ends in 2026). */
export const RECOMMENDED_EMULATOR = "36.2.0";
/** By default, at most this many emulators at once per machine (decision of 2026-11-22). */
export const DEFAULT_MAX_EMULATORS = 2;

/** This machine's settings for emulators (Settings › Emulators). */
export const EmulatorSettings = z.object({
  /** A folder with an Android SDK the person chose (absolute path), or none. */
  sdkPath: z.string().trim().min(1).max(400).nullable().default(null),
  maxRunning: z.number().int().min(1).max(8).default(DEFAULT_MAX_EMULATORS),
});
export type EmulatorSettings = z.infer<typeof EmulatorSettings>;

export const EmulatorSettingsBody = z.object({
  sdkPath: z.string().trim().max(400).nullable().optional(),
  maxRunning: z.number().int().min(1).max(8).optional(),
});

/** One machine as Settings › Emulators shows it. */
export interface EmulatorMachineView {
  /** `here` or the node's fingerprint. */
  id: string;
  name: string;
  online: boolean;
  /** Absent: a node older than 3.11, or offline before it ever reported. */
  report?: EmulatorReport;
}

export interface EmulatorsState {
  here: EmulatorMachineView;
  settings: EmulatorSettings;
  nodes: EmulatorMachineView[];
}

/** `a` < `b` for dotted versions (`35.2.10` < `36.2.0`); a missing part counts as 0. */
export function versionBelow(a: string, b: string): boolean {
  const pa = a.split(/[.\s-]/).map((x) => Number.parseInt(x, 10) || 0);
  const pb = b.split(/[.\s-]/).map((x) => Number.parseInt(x, 10) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d) return d < 0;
  }
  return false;
}

// ---- Phase 2: a device live in the Canvas, for the person and the agents ----

/** Keys the person's keyboard and the agents send to a device (Android key codes on the server). */
export const DEVICE_KEYS = [
  "Enter",
  "Backspace",
  "Delete",
  "Tab",
  "Escape",
  "Space",
  "ArrowUp",
  "ArrowDown",
  "ArrowLeft",
  "ArrowRight",
] as const;
export type DeviceKey = (typeof DEVICE_KEYS)[number];

/** The phone's own buttons. */
export const DEVICE_BUTTONS = [
  "back",
  "home",
  "recents",
  "power",
  "volume_up",
  "volume_down",
] as const;
export type DeviceButton = (typeof DEVICE_BUTTONS)[number];

const frac = z.number().min(0).max(1);
/** One gesture on a device's screen; x and y are fractions of the screen (0 to 1). */
export const DeviceInput = z.discriminatedUnion("kind", [
  z.object({ kind: z.literal("tap"), x: frac, y: frac }),
  z.object({
    kind: z.literal("long"),
    x: frac,
    y: frac,
    ms: z.number().int().min(300).max(5000).optional(),
  }),
  z.object({
    kind: z.literal("swipe"),
    x: frac,
    y: frac,
    x2: frac,
    y2: frac,
    ms: z.number().int().min(50).max(5000).optional(),
  }),
  z.object({ kind: z.literal("text"), text: z.string().min(1).max(2000) }),
  z.object({ kind: z.literal("key"), key: z.enum(DEVICE_KEYS) }),
  z.object({ kind: z.literal("button"), button: z.enum(DEVICE_BUTTONS) }),
  z.object({ kind: z.literal("rotate") }),
]);
export type DeviceInput = z.infer<typeof DeviceInput>;

export type DeviceState = "off" | "starting" | "on" | "unauthorized" | "offline";

/** A device one can open: an AVD (on or off), a running emulator, a phone over USB or Wi-Fi. */
export interface EmuDeviceView {
  /** `avd:<name>` for an AVD that is off, else adb's serial. */
  id: string;
  name: string;
  kind: "emulator" | "phone";
  state: DeviceState;
  avd?: string;
  serial?: string;
  model?: string;
  link?: "usb" | "wifi";
  /** Rasgeth started it (only those are switched off when idle). */
  ours?: boolean;
  /** Who drives it now. */
  control: "agents" | "person";
}

/** An emulator is an id `avd:<name>` or a serial `emulator-<port>`; anything else is a real phone. */
export const isEmulatorId = (id: string): boolean => /^(avd:|emulator-\d+$)/.test(id);
