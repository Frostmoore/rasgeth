// 3.11 phase 1: finding emulators, as tables. Every case is a kind of machine any person may have
// (Windows, macOS, Linux, x64 and arm64; SDK in the standard place, from the environment, from
// Android Studio's settings, around adb on the PATH, or in a folder they chose; no SDK at all;
// RedGiant in a container; emulators already running; phones over USB and Wi-Fi), never one house.
import type { EmulatorReport } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import {
  avdHome,
  detectEmulators,
  type EmulatorFacts,
  linuxAccel,
  parseAccelCheck,
  parseAdbDevices,
  parseAvdConfig,
  parseSimctl,
  parseStudioSdkPath,
  parseXcodeVersion,
  pickSdk,
  type SdkProbe,
  sdkCandidates,
  sdkRootOfTool,
  standardSdk,
  studioDirsNewestFirst,
  studioSettingsRoot,
} from "../src/emulators/detect.js";
import { EmulatorMachine, memorySettings } from "../src/emulators/machine.js";
import { nodeHandlers } from "../src/nodes/serve.js";
import { startServer } from "./helpers.js";

const WIN_ENV = {
  LOCALAPPDATA: "C:\\Users\\ana\\AppData\\Local",
  APPDATA: "C:\\Users\\ana\\AppData\\Roaming",
};

describe("where an SDK is looked for", () => {
  const cases: {
    name: string;
    input: Parameters<typeof sdkCandidates>[0];
    want: [string, string][];
  }[] = [
    {
      name: "Windows, nothing set: Android Studio's default place",
      input: { os: "windows", home: "C:\\Users\\ana", env: WIN_ENV },
      want: [["C:\\Users\\ana\\AppData\\Local\\Android\\Sdk", "standard"]],
    },
    {
      name: "Windows, the person's folder first; Studio's same folder (other case) not repeated; WinGet's adb",
      input: {
        os: "windows",
        home: "C:\\Users\\ana",
        env: WIN_ENV,
        custom: "D:\\androidvd",
        studio: ["d:\\AndroidVD\\"],
        pathTools: [
          "C:\\Users\\ana\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Google.PlatformTools\\platform-tools\\adb.exe",
        ],
      },
      want: [
        ["D:\\androidvd", "custom"],
        ["C:\\Users\\ana\\AppData\\Local\\Android\\Sdk", "standard"],
        [
          "C:\\Users\\ana\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Google.PlatformTools",
          "path",
        ],
      ],
    },
    {
      name: "Windows, ANDROID_HOME and ANDROID_SDK_ROOT the same: once",
      input: {
        os: "windows",
        home: "C:\\Users\\ana",
        env: { ...WIN_ENV, ANDROID_HOME: "E:\\sdk", ANDROID_SDK_ROOT: "E:\\SDK" },
      },
      want: [
        ["E:\\sdk", "ANDROID_HOME"],
        ["C:\\Users\\ana\\AppData\\Local\\Android\\Sdk", "standard"],
      ],
    },
    {
      name: "macOS: ANDROID_SDK_ROOT, then ~/Library/Android/sdk",
      input: { os: "macos", home: "/Users/ana", env: { ANDROID_SDK_ROOT: "/opt/android" } },
      want: [
        ["/opt/android", "ANDROID_SDK_ROOT"],
        ["/Users/ana/Library/Android/sdk", "standard"],
      ],
    },
    {
      name: "Linux: ~/Android/Sdk; the SDK around an emulator on the PATH; Debian's /usr/bin/adb has none",
      input: {
        os: "linux",
        home: "/home/ana",
        env: {},
        studio: ["/home/ana/Android/Sdk"],
        pathTools: ["/usr/bin/adb", "/usr/lib/android-sdk/emulator/emulator"],
      },
      want: [
        ["/home/ana/Android/Sdk", "studio"],
        ["/usr/lib/android-sdk", "path"],
      ],
    },
    {
      name: "Linux tells case apart",
      input: {
        os: "linux",
        home: "/home/ana",
        env: { ANDROID_HOME: "/opt/Sdk", ANDROID_SDK_ROOT: "/opt/sdk" },
      },
      want: [
        ["/opt/Sdk", "ANDROID_HOME"],
        ["/opt/sdk", "ANDROID_SDK_ROOT"],
        ["/home/ana/Android/Sdk", "standard"],
      ],
    },
    {
      name: "empty values are ignored",
      input: { os: "linux", home: "/home/node", env: { ANDROID_HOME: " " }, custom: "" },
      want: [["/home/node/Android/Sdk", "standard"]],
    },
  ];
  for (const c of cases)
    it(c.name, () => {
      expect(sdkCandidates(c.input).map((x) => [x.path, x.source])).toEqual(c.want);
    });

  it.each([
    ["windows", "C:\\sdk\\platform-tools\\adb.exe", "C:\\sdk"],
    ["windows", "C:\\sdk\\emulator\\emulator.exe", "C:\\sdk"],
    ["linux", "/home/a/Android/Sdk/platform-tools/adb", "/home/a/Android/Sdk"],
    ["linux", "/usr/bin/adb", undefined],
    ["macos", "/opt/homebrew/bin/adb", undefined],
    ["linux", "/platform-tools/adb", undefined],
  ] as const)("%s: the SDK around %s", (os, tool, want) => {
    expect(sdkRootOfTool(os, tool)).toBe(want);
  });

  it.each([
    [
      "windows",
      "C:\\Users\\ana",
      WIN_ENV,
      "C:\\Users\\ana\\AppData\\Local\\Android\\Sdk",
      "C:\\Users\\ana\\AppData\\Roaming\\Google",
    ],
    [
      "windows",
      "C:\\Users\\ana",
      {},
      "C:\\Users\\ana\\AppData\\Local\\Android\\Sdk",
      "C:\\Users\\ana\\AppData\\Roaming\\Google",
    ],
    [
      "macos",
      "/Users/ana",
      {},
      "/Users/ana/Library/Android/sdk",
      "/Users/ana/Library/Application Support/Google",
    ],
    ["linux", "/home/ana", {}, "/home/ana/Android/Sdk", "/home/ana/.config/Google"],
    ["linux", "/home/ana", { XDG_CONFIG_HOME: "/cfg" }, "/home/ana/Android/Sdk", "/cfg/Google"],
  ] as const)("%s home %s: standard SDK and Studio's settings", (os, home, env, sdk, studio) => {
    expect(standardSdk(os, home, env)).toBe(sdk);
    expect(studioSettingsRoot(os, home, env)).toBe(studio);
  });

  it.each([
    [{}, "/home/a/.android/avd"],
    [{ ANDROID_USER_HOME: "/data/android" }, "/data/android/avd"],
    [{ ANDROID_EMULATOR_HOME: "/emu" }, "/emu/avd"],
    [{ ANDROID_AVD_HOME: "/avds", ANDROID_USER_HOME: "/x" }, "/avds"],
  ])("AVDs in %o: %s", (env, want) => {
    expect(avdHome("linux", "/home/a", env)).toBe(want);
  });

  it("Studio's settings, the newest version first", () => {
    expect(
      studioDirsNewestFirst([
        "AndroidStudio2024.2",
        "consentOptions",
        "AndroidStudio2025.1",
        "AndroidStudioPreview2025.2",
      ]),
    ).toEqual(["AndroidStudioPreview2025.2", "AndroidStudio2025.1", "AndroidStudio2024.2"]);
  });
});

describe("which SDK is used", () => {
  const p = (
    path: string,
    source: SdkProbe["source"],
    isSdk: boolean,
    emulator: boolean,
  ): SdkProbe => ({
    path,
    source,
    isSdk,
    emulator,
  });
  it.each([
    [
      "the person's folder wins even without an emulator",
      [p("/c", "custom", true, false), p("/s", "standard", true, true)],
      "/c",
    ],
    [
      "a chosen folder that is no SDK is skipped",
      [p("/c", "custom", false, false), p("/s", "standard", true, true)],
      "/s",
    ],
    [
      "an SDK with the emulator before one with adb only",
      [p("/w", "ANDROID_HOME", true, false), p("/s", "studio", true, true)],
      "/s",
    ],
    [
      "adb only, when nothing else",
      [p("/w", "path", true, false), p("/s", "standard", false, false)],
      "/w",
    ],
    ["nothing", [p("/s", "standard", false, false)], undefined],
  ] as const)("%s", (_name, probes, want) => {
    expect(pickSdk(probes)?.path).toBe(want);
  });
});

describe("reading what the tools say", () => {
  it.each([
    ['{"keyToString": {"android.sdk.path": "D:\\\\androidvd", "x": "y"}}', "D:\\androidvd"],
    [
      '<property name="android.sdk.path" value="/Users/ana/Library/Android/sdk" />',
      "/Users/ana/Library/Android/sdk",
    ],
    ['{"android.sdk.path": ""}', undefined],
    ["<application/>", undefined],
  ])("Android Studio's other.xml %#", (xml, want) => {
    expect(parseStudioSdkPath(xml)).toBe(want);
  });

  it("an AVD's config.ini (Windows paths, Play Store)", () => {
    const ini = [
      "PlayStore.enabled = true",
      "abi.type = x86_64",
      "hw.device.name = medium_phone",
      "image.sysdir.1 = system-images\\android-35\\google_apis_playstore\\x86_64\\",
      "tag.id = google_apis_playstore",
    ].join("\r\n");
    expect(parseAvdConfig("Medium_Phone_API_35", ini)).toEqual({
      name: "Medium_Phone_API_35",
      device: "medium_phone",
      api: 35,
      abi: "x86_64",
      tag: "google_apis_playstore",
      playStore: true,
    });
    expect(parseAvdConfig("Bare", "", "android-34")).toEqual({ name: "Bare", api: 34 });
  });

  it("adb's devices: emulators, phones over USB and Wi-Fi, one waiting for its yes", () => {
    const text = [
      "emulator-5554          device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64 device:emu64xa transport_id:1",
      "R58N12ABCDE            device usb:1-1 product:a52q model:SM_A525F device:a52q transport_id:2",
      "192.168.1.40:5555      device product:panther model:Pixel_7 device:panther transport_id:3",
      "adb-2B1C3D-xyz._adb-tls-connect._tcp device product:oriole model:Pixel_6 transport_id:4",
      "0123456789ABCDEF       unauthorized usb:1-2 transport_id:5",
      "emulator-5556          offline transport_id:6",
    ].join("\n");
    expect(parseAdbDevices(text)).toEqual([
      { serial: "emulator-5554", kind: "emulator", state: "device", model: "sdk gphone64 x86 64" },
      { serial: "R58N12ABCDE", kind: "phone", state: "device", link: "usb", model: "SM A525F" },
      {
        serial: "192.168.1.40:5555",
        kind: "phone",
        state: "device",
        link: "wifi",
        model: "Pixel 7",
      },
      {
        serial: "adb-2B1C3D-xyz._adb-tls-connect._tcp",
        kind: "phone",
        state: "device",
        link: "wifi",
        model: "Pixel 6",
      },
      { serial: "0123456789ABCDEF", kind: "phone", state: "unauthorized", link: "usb" },
      { serial: "emulator-5556", kind: "emulator", state: "offline" },
    ]);
    expect(parseAdbDevices("")).toEqual([]);
  });

  it.each([
    [
      "windows",
      "accel:\n0\nWHPX(10.0.26200) is installed and usable.\naccel\n",
      0,
      { ok: true, kind: "whpx" },
    ],
    [
      "windows",
      "accel:\n0\nAEHD (version 2.2) is installed and usable.\naccel",
      0,
      { ok: true, kind: "aehd" },
    ],
    [
      "windows",
      "accel:\n4\nHAXM is not installed or VT-x is disabled in BIOS\naccel",
      4,
      { ok: false, kind: "haxm", reason: "disabled" },
    ],
    [
      "linux",
      "accel:\n0\nKVM (version 12) is installed and usable.\naccel",
      0,
      { ok: true, kind: "kvm" },
    ],
    [
      "linux",
      "accel:\n7\n/dev/kvm is not found: VT disabled in BIOS or KVM kernel module not loaded\naccel",
      7,
      { ok: false, kind: "kvm", reason: "no-kvm" },
    ],
    [
      "linux",
      "accel:\n8\nThis user doesn't have permissions to use KVM (/dev/kvm).\naccel",
      8,
      { ok: false, kind: "kvm", reason: "kvm-denied" },
    ],
    [
      "macos",
      "accel:\n0\nHypervisor.Framework OS X Version 27.0\naccel\nHVF is installed and usable.",
      0,
      { ok: true, kind: "hvf" },
    ],
    ["windows", "something else", null, { ok: false, reason: "unknown" }],
  ] as const)("%s accel-check %#", (os, out, code, want) => {
    expect(parseAccelCheck(os, out, code)).toEqual(want);
  });

  it.each([
    [
      { kvm: "rw", container: false },
      { ok: true, kind: "kvm" },
    ],
    [
      { kvm: "denied", container: false },
      { ok: false, kind: "kvm", reason: "kvm-denied" },
    ],
    [
      { kvm: "absent", container: false },
      { ok: false, reason: "no-kvm" },
    ],
    [
      { kvm: "absent", container: true },
      { ok: false, reason: "container" },
    ],
  ] as const)("Linux without an emulator to ask: %o", (input, want) => {
    expect(linuxAccel(input)).toEqual(want);
  });

  it("simctl's simulators and Xcode's version", () => {
    const json = JSON.stringify({
      devices: {
        "com.apple.CoreSimulator.SimRuntime.iOS-27-2": [
          { name: "iPhone 18", udid: "A-1", state: "Shutdown", isAvailable: true },
          { name: "iPad Air", udid: "A-2", state: "Booted", isAvailable: true },
          { name: "Old", udid: "A-3", state: "Shutdown", isAvailable: false },
        ],
      },
    });
    expect(parseSimctl(json)).toEqual([
      { name: "iPhone 18", udid: "A-1", runtime: "iOS 27.2", state: "shutdown" },
      { name: "iPad Air", udid: "A-2", runtime: "iOS 27.2", state: "booted" },
    ]);
    expect(parseSimctl("not json")).toEqual([]);
    expect(parseXcodeVersion("Xcode 27.2\nBuild version 27B52")).toBe("27.2");
    expect(
      parseXcodeVersion("xcode-select: error: tool 'xcodebuild' requires Xcode"),
    ).toBeUndefined();
  });
});

const AT = "2026-11-22T10:00:00.000Z";
const facts = (f: Partial<EmulatorFacts> & Pick<EmulatorFacts, "os" | "arch">): EmulatorFacts => ({
  container: false,
  looked: [],
  avds: [],
  accel: { ok: true },
  maxRunning: 2,
  at: AT,
  ...f,
});
const sdk = (
  o: Partial<NonNullable<EmulatorFacts["sdk"]>> = {},
): NonNullable<EmulatorFacts["sdk"]> => ({
  root: "/sdk",
  source: "standard",
  emulator: "37.3.10",
  platformTools: "37.0.1",
  cmdlineTools: true,
  images: ["android-35/google_apis/x86_64"],
  ...o,
});
const avd = (name: string, abi = "x86_64", image = `android-35/google_apis/${abi}`) => ({
  report: { name, api: 35, abi },
  image,
});

describe("what is missing", () => {
  const cases: {
    name: string;
    f: EmulatorFacts;
    missing: string[];
    ready: boolean;
    check?: (r: EmulatorReport) => void;
  }[] = [
    {
      name: "Windows with everything, emulator old (an update is proposed, it still runs)",
      f: facts({
        os: "windows",
        arch: "x64",
        sdk: sdk({
          root: "D:\\androidvd",
          source: "custom",
          emulator: "35.2.10",
          images: ["android-35/google_apis_playstore/x86_64"],
        }),
        avds: [avd("Medium_Phone_API_35", "x86_64", "android-35/google_apis_playstore/x86_64")],
        accel: { ok: true, kind: "whpx" },
        attached: [],
      }),
      missing: ["emulator-old"],
      ready: true,
    },
    {
      name: "Windows with no SDK (acceleration cannot be asked yet: not called missing)",
      f: facts({ os: "windows", arch: "x64", accel: { ok: false, reason: "unknown" } }),
      missing: ["sdk"],
      ready: false,
      check: (r) => expect(r.android.adbIdle).toBe(true),
    },
    {
      name: "Windows on arm64: only arm64 images run fast",
      f: facts({
        os: "windows",
        arch: "arm64",
        sdk: sdk({ images: ["android-35/google_apis/arm64-v8a"] }),
        avds: [avd("Arm", "arm64-v8a")],
      }),
      missing: [],
      ready: true,
    },
    {
      name: "macOS arm64 with nothing: SDK and Xcode",
      f: facts({ os: "macos", arch: "arm64", accel: { ok: true, kind: "hvf" } }),
      missing: ["sdk", "xcode"],
      ready: false,
      check: (r) => expect(r.ios).toEqual({ simulators: [] }),
    },
    {
      name: "macOS with an SDK and Xcode but no bridge for iOS touches",
      f: facts({
        os: "macos",
        arch: "arm64",
        sdk: sdk({ images: ["android-36/google_apis/arm64-v8a"] }),
        avds: [avd("Pixel", "arm64-v8a", "android-36/google_apis/arm64-v8a")],
        ios: {
          xcode: "27.2",
          simulators: [{ name: "iPhone 18", udid: "U", runtime: "iOS 27.2", state: "shutdown" }],
        },
      }),
      missing: ["ios-bridge"],
      ready: true,
    },
    {
      name: "Linux server in Docker: no SDK, no KVM (the nodes bring emulators)",
      f: facts({
        os: "linux",
        arch: "x64",
        container: true,
        accel: { ok: false, reason: "container" },
      }),
      missing: ["sdk", "accel"],
      ready: false,
      check: (r) => expect(r.container).toBe(true),
    },
    {
      name: "Linux arm64 with only x86_64 images: none runs fast",
      f: facts({ os: "linux", arch: "arm64", sdk: sdk(), avds: [avd("X86")] }),
      missing: ["system-image", "avd"],
      ready: false,
    },
    {
      name: "Linux desktop without KVM rights",
      f: facts({
        os: "linux",
        arch: "x64",
        sdk: sdk(),
        avds: [avd("P")],
        accel: { ok: false, kind: "kvm", reason: "kvm-denied" },
      }),
      missing: ["accel"],
      ready: false,
    },
    {
      name: "an AVD whose image was deleted",
      f: facts({
        os: "linux",
        arch: "x64",
        sdk: sdk(),
        avds: [avd("Gone", "x86_64", "android-30/default/x86_64")],
      }),
      missing: ["avd"],
      ready: false,
      check: (r) => expect(r.android.avds[0]?.imageMissing).toBe(true),
    },
    {
      name: "adb only (WinGet): phones work, emulators need the rest",
      f: facts({
        os: "windows",
        arch: "x64",
        sdk: {
          root: "C:\\winget\\PlatformTools",
          source: "path",
          platformTools: "37.0.1",
          cmdlineTools: false,
          images: [],
        },
        accel: { ok: false, reason: "unknown" },
        attached: [
          { serial: "R58", kind: "phone", state: "device", link: "usb", model: "SM A525F" },
        ],
      }),
      missing: ["emulator", "cmdline-tools", "system-image", "avd"],
      ready: false,
      check: (r) => expect(r.android.attached).toHaveLength(1),
    },
    {
      name: "an emulator already running (started by the person) shows its AVD",
      f: facts({
        os: "linux",
        arch: "x64",
        sdk: sdk(),
        avds: [avd("Pixel_8")],
        attached: [{ serial: "emulator-5554", kind: "emulator", state: "device" }],
        runningAvds: { "emulator-5554": "Pixel_8" },
      }),
      missing: [],
      ready: true,
      check: (r) => {
        expect(r.android.attached[0]?.avd).toBe("Pixel_8");
        expect(r.android.adbIdle).toBeUndefined();
      },
    },
  ];
  for (const c of cases)
    it(c.name, () => {
      const r = detectEmulators(c.f);
      expect(r.missing).toEqual(c.missing);
      expect(r.ready).toBe(c.ready);
      c.check?.(r);
    });
});

describe("this machine's emulators", () => {
  const gather = async (o: { custom: string | null; maxRunning: number }) =>
    facts({
      os: "windows",
      arch: "x64",
      looked: o.custom ? [{ path: o.custom, source: "custom" }] : [],
      ...(o.custom && { sdk: sdk({ root: o.custom, source: "custom" }) }),
      maxRunning: o.maxRunning,
    });

  it("a chosen folder must be a full path with an SDK; null forgets it; the report follows", async () => {
    let looks = 0;
    const m = new EmulatorMachine({
      settings: memorySettings(),
      os: "windows",
      gather: async (o) => {
        looks++;
        return gather(o);
      },
      isSdk: async (p) => p === "D:\\androidvd",
    });
    expect((await m.report()).android.sdk).toBeUndefined();
    await m.report();
    expect(looks).toBe(1);
    await expect(m.update({ sdkPath: "androidvd" })).rejects.toThrow(/full path/);
    await expect(m.update({ sdkPath: "D:\\empty" })).rejects.toThrow(/No Android SDK/);
    await m.update({ sdkPath: "D:\\androidvd", maxRunning: 3 });
    const r = await m.report();
    expect(r.android.sdk).toMatchObject({ root: "D:\\androidvd", source: "custom" });
    expect(r.maxRunning).toBe(3);
    await m.update({ sdkPath: null });
    expect(m.settings()).toEqual({ sdkPath: null, maxRunning: 3 });
    expect((await m.report(true)).android.sdk).toBeUndefined();
  });

  it("a node reports its emulators in its capabilities", async () => {
    const report = detectEmulators(facts({ os: "macos", arch: "arm64" }));
    const h = nodeHandlers({
      dataDir: "/tmp/rg-emu-node-test",
      sandbox: async () => {
        throw new Error("unused");
      },
      providers: { list: () => [] } as never,
      sandboxKind: "host",
      emulators: async () => report,
    });
    expect((await h.capabilities("me")).emulators).toEqual(report);
    const failing = nodeHandlers({
      dataDir: "/tmp/rg-emu-node-test",
      sandbox: async () => {
        throw new Error("unused");
      },
      providers: { list: () => [] } as never,
      sandboxKind: "host",
      emulators: async () => {
        throw new Error("broken");
      },
    });
    expect((await failing.capabilities("me")).emulators).toBeUndefined();
  });

  it("Settings › Emulators over HTTP: the report, and a folder refused in words", async () => {
    const s = await startServer(
      [],
      {},
      {
        emulators: new EmulatorMachine({
          settings: memorySettings(),
          os: "linux",
          gather,
          isSdk: async (p) => p === "/opt/android",
        }),
      },
    );
    try {
      const first = await s.api<{
        here: { id: string; report: EmulatorReport };
        settings: unknown;
        nodes: unknown[];
      }>("GET", "/api/emulators");
      expect(first.status).toBe(200);
      expect(first.body.here.id).toBe("here");
      expect(first.body.here.report.missing).toContain("sdk");
      expect(first.body.settings).toEqual({ sdkPath: null, maxRunning: 2 });
      const bad = await s.api<{ error: string }>("PUT", "/api/emulators/settings", {
        sdkPath: "/nothing",
      });
      expect(bad.status).toBe(400);
      expect(bad.body.error).toMatch(/No Android SDK/);
      const good = await s.api<{ here: { report: EmulatorReport } }>(
        "PUT",
        "/api/emulators/settings",
        {
          sdkPath: "/opt/android",
        },
      );
      expect(good.status).toBe(200);
      expect(good.body.here.report.android.sdk?.root).toBe("/opt/android");
      expect((await s.api("PUT", "/api/emulators/settings", { maxRunning: 99 })).status).toBe(400);
    } finally {
      await s.close();
    }
  });
});
