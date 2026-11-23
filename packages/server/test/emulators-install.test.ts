// 3.11 phase 5: the guided install of the Android SDK pieces, only with the person's yes. The
// planner is a table (any system and processor, any starting point); the runner runs with fake
// downloads and fake programs (no network, no real SDK): it refuses to start without the plan's id
// and without the licences accepted, answers only the accepted licences, reports bytes with speed
// and time left, cancels, and writes only inside the SDK folder and the AVD's place.
import { createHash } from "node:crypto";
import { mkdir, mkdtemp, readdir, rm, stat, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, sep } from "node:path";
import type { EmuInstallPlan, EmulatorReport, Job } from "@redgiant/protocol";
import { zipSync } from "fflate";
import { afterEach, describe, expect, it } from "vitest";
import type { EmuEnv } from "../src/emulators/detect.js";
import {
  downloadPercent,
  EmulatorInstaller,
  findCmdline,
  InstallError,
  inside,
  javaCandidates,
  type Launch,
  licenceAnswer,
  type Program,
  parseJavaVersion,
  unzipInto,
} from "../src/emulators/install.js";
import {
  CMDLINE_TOOLS,
  cmdlineArchive,
  DEFAULT_AVD_NAME,
  freeAvdName,
  type PlanFacts,
  parseRepository,
  planInstall,
  REPOSITORY_LISTS,
  type RepoCatalog,
} from "../src/emulators/install-plan.js";
import { EmulatorMachine, memorySettings } from "../src/emulators/machine.js";
import { Jobs } from "../src/jobs.js";
import { startServer } from "./helpers.js";

const report = (over: Partial<EmulatorReport> = {}, android = {}): EmulatorReport => {
  const base: EmulatorReport = {
    os: "windows",
    arch: "x64",
    container: false,
    android: {
      looked: [],
      avds: [],
      attached: [],
      accel: { ok: false, reason: "unknown" },
    },
    missing: ["sdk"],
    ready: false,
    maxRunning: 2,
    at: "2026-11-22T10:00:00.000Z",
  };
  return { ...base, ...over, android: { ...base.android, ...over.android, ...android } };
};
const sdk = (o: Partial<NonNullable<EmulatorReport["android"]["sdk"]>> = {}) => ({
  root: "D:\\Android\\Sdk",
  source: "studio" as const,
  emulator: "37.3.10",
  platformTools: "37.0.3",
  cmdlineTools: true,
  images: ["android-35/google_apis/x86_64"],
  ...o,
});

const catalog: RepoCatalog = {
  packages: {
    "platform-tools": { version: "37.0.3", size: 8_188_601, licence: "android-sdk-license" },
    emulator: { version: "37.3.10", size: 456_613_348, licence: "android-sdk-license" },
    "system-images;android-35;google_apis;x86_64": {
      version: "9",
      size: 1_738_815_903,
      licence: "android-sdk-license",
    },
    "system-images;android-35;google_apis;arm64-v8a": {
      version: "9",
      size: 1_778_933_980,
      licence: "android-sdk-arm-dbt-license",
    },
  },
  licences: {
    "android-sdk-license": "Terms and Conditions…",
    "android-sdk-arm-dbt-license": "ARM terms…",
  },
};
const java = { path: "C:\\Java\\bin\\java.exe", major: 17 };
const winEnv: EmuEnv = { LOCALAPPDATA: "C:\\Users\\Ada\\AppData\\Local" };

type Row = {
  name: string;
  r: EmulatorReport;
  f?: Partial<PlanFacts>;
  steps: string[];
  blocked?: string;
  target?: string;
  standard?: boolean;
  notes?: string[];
  licences?: string[];
  pkgs?: string[];
};

const rows: Row[] = [
  {
    name: "Windows, no SDK at all: everything into %LOCALAPPDATA%\\Android\\Sdk",
    r: report(),
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    target: "C:\\Users\\Ada\\AppData\\Local\\Android\\Sdk",
    standard: true,
    licences: ["android-sdk-license"],
    pkgs: [
      "platform-tools",
      "emulator",
      "system-images;android-35;google_apis;x86_64",
      "system-images;android-35;google_apis;x86_64",
    ],
  },
  {
    name: "Windows, no SDK, the person's folder",
    r: report(),
    f: { target: "E:\\sdk", targetState: "absent" },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    target: "E:\\sdk",
    standard: false,
  },
  {
    name: "a folder full of other things is refused",
    r: report(),
    f: { target: "C:\\Users\\Ada", targetState: "other" },
    steps: [],
    blocked: "folder-not-empty",
  },
  {
    name: "a relative folder is refused",
    r: report(),
    f: { target: "sdk" },
    steps: [],
    blocked: "folder-relative",
  },
  {
    name: "macOS arm64, no SDK: ~/Library/Android/sdk, the arm64 image and its licence; Xcode explained",
    r: report({ os: "macos", arch: "arm64", missing: ["sdk", "xcode"] }),
    f: { home: "/Users/ada", env: {} },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    target: "/Users/ada/Library/Android/sdk",
    notes: ["xcode"],
    licences: ["android-sdk-license", "android-sdk-arm-dbt-license"],
  },
  {
    name: "macOS with Xcode but no bridge: only explained",
    r: report({ os: "macos", arch: "x64", missing: ["sdk", "ios-bridge"] }),
    f: { home: "/Users/ada", env: {} },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    notes: ["ios-bridge"],
  },
  {
    name: "Linux x64 with KVM, no SDK: ~/Android/Sdk",
    r: report({ os: "linux", android: { accel: { ok: true, kind: "kvm" } } as never }),
    f: { home: "/home/ada", env: {} },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    target: "/home/ada/Android/Sdk",
  },
  {
    name: "Linux without KVM: too slow, a node instead",
    r: report(
      { os: "linux", missing: ["sdk", "accel"] },
      { accel: { ok: false, reason: "no-kvm" } },
    ),
    f: { home: "/home/ada", env: {} },
    steps: [],
    blocked: "no-accel",
    notes: ["node"],
  },
  {
    name: "Linux with /dev/kvm denied: the kvm group explained",
    r: report(
      { os: "linux", missing: ["sdk", "accel"] },
      { accel: { ok: false, kind: "kvm", reason: "kvm-denied" } },
    ),
    f: { home: "/home/ada", env: {} },
    steps: [],
    blocked: "no-accel",
    notes: ["kvm-group", "node"],
  },
  {
    name: "Rasgeth in a container: nothing here, a node",
    r: report({ os: "linux", container: true, missing: ["sdk", "accel"] }),
    f: { home: "/home/node", env: {} },
    steps: [],
    blocked: "container",
    notes: ["node"],
  },
  {
    name: "Linux arm64: Google has no emulator",
    r: report({ os: "linux", arch: "arm64" }),
    f: { home: "/home/ada", env: {} },
    steps: [],
    blocked: "unsupported",
    notes: ["node"],
  },
  {
    name: "Windows on ARM: no emulator either",
    r: report({ arch: "arm64" }),
    steps: [],
    blocked: "unsupported",
  },
  {
    name: "adb only (WinGet): a new SDK in the standard place, platform-tools too",
    r: report(
      { missing: ["emulator", "cmdline-tools", "system-image", "avd"] },
      {
        sdk: sdk({
          root: "C:\\Users\\Ada\\AppData\\Local\\Microsoft\\WinGet\\Packages\\Google.PlatformTools",
          source: "path",
          emulator: undefined,
          cmdlineTools: false,
          images: [],
        }),
      },
    ),
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    target: "C:\\Users\\Ada\\AppData\\Local\\Android\\Sdk",
    standard: true,
  },
  {
    name: "SDK without the emulator: emulator, image and AVD into the same SDK",
    r: report(
      { missing: ["emulator", "system-image", "avd"] },
      { sdk: sdk({ emulator: undefined, images: [] }) },
    ),
    f: { cmdline: { usable: true, latestTaken: true } },
    steps: ["licences", "emulator", "system-image", "avd"],
    target: "D:\\Android\\Sdk",
    standard: false,
  },
  {
    name: "image missing for this processor (only an arm64 one on x64)",
    r: report(
      { missing: ["system-image", "avd"] },
      { sdk: sdk({ images: ["android-35/google_apis/arm64-v8a"] }) },
    ),
    f: { cmdline: { usable: true, latestTaken: true } },
    steps: ["licences", "system-image", "avd"],
    pkgs: [
      "system-images;android-35;google_apis;x86_64",
      "system-images;android-35;google_apis;x86_64",
    ],
  },
  {
    name: "an image but no AVD: only the AVD, on the newest image there",
    r: report(
      { missing: ["avd"] },
      {
        sdk: sdk({
          images: ["android-34/google_apis/x86_64", "android-35/google_apis_playstore/x86_64"],
        }),
      },
    ),
    f: { cmdline: { usable: true, latestTaken: true } },
    steps: ["avd"],
    pkgs: ["system-images;android-35;google_apis_playstore;x86_64"],
    licences: [],
  },
  {
    name: "old emulator (Rig's case): the update proposed alone",
    r: report(
      { missing: ["emulator-old"], ready: true },
      {
        sdk: sdk({ root: "D:\\androidvd", emulator: "35.2.10" }),
        avds: [{ name: "Medium_Phone" }],
      },
    ),
    f: { only: "emulator-update", cmdline: { usable: true, latestTaken: true } },
    steps: ["licences", "emulator-update"],
    target: "D:\\androidvd",
  },
  {
    name: "old emulator while one runs: close it first",
    r: report(
      { missing: ["emulator-old"], ready: true },
      {
        sdk: sdk({ emulator: "35.2.10" }),
        avds: [{ name: "Medium_Phone" }],
        attached: [{ serial: "emulator-5554", kind: "emulator", state: "device" }],
      },
    ),
    f: { only: "emulator-update", cmdline: { usable: true, latestTaken: true } },
    steps: [],
    blocked: "emulators-running",
  },
  {
    name: "everything missing but an emulator runs: the rest now, the update later",
    r: report(
      { missing: ["system-image", "avd", "emulator-old"] },
      {
        sdk: sdk({ emulator: "35.2.10", images: [] }),
        attached: [{ serial: "emulator-5554", kind: "emulator", state: "device" }],
      },
    ),
    f: { cmdline: { usable: true, latestTaken: true } },
    steps: ["licences", "system-image", "avd"],
  },
  {
    name: "old cmdline-tools without the Java sdkmanager: ours beside them",
    r: report(
      { missing: ["emulator-old"], ready: true },
      { sdk: sdk({ emulator: "35.2.10" }), avds: [{ name: "Medium_Phone" }] },
    ),
    f: { only: "emulator-update", cmdline: { usable: false, latestTaken: true } },
    steps: ["cmdline-tools", "licences", "emulator-update"],
  },
  {
    name: "nothing missing",
    r: report({ missing: [], ready: true }, { sdk: sdk(), avds: [{ name: "P" }] }),
    f: { cmdline: { usable: true, latestTaken: true } },
    steps: [],
    blocked: "nothing",
  },
  {
    name: "no Java: the steps are shown, nothing starts",
    r: report(),
    f: { java: undefined },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    blocked: "no-java",
  },
  {
    name: "Java 11: too old",
    r: report(),
    f: { java: { path: "java", major: 11 } },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    blocked: "java-old",
  },
  {
    name: "Google's list not readable: the licences cannot be shown, nothing starts",
    r: report(),
    f: { catalog: undefined },
    steps: ["cmdline-tools", "licences", "platform-tools", "emulator", "system-image", "avd"],
    blocked: "offline",
  },
];

describe("the install plan (a table)", () => {
  for (const row of rows)
    it(row.name, () => {
      const p = planInstall({
        report: row.r,
        home: "C:\\Users\\Ada",
        env: winEnv,
        java,
        catalog,
        ...row.f,
      });
      expect(p.steps.map((s) => s.id)).toEqual(row.steps);
      expect(p.blocked).toBe(row.blocked);
      if (row.target) expect(p.target).toBe(row.target);
      if (row.standard !== undefined) expect(p.targetStandard).toBe(row.standard);
      if (row.notes) expect(p.notes).toEqual(row.notes);
      if (row.licences) expect(p.licenceIds).toEqual(row.licences);
      if (row.pkgs)
        expect(p.steps.filter((s) => s.package).map((s) => s.package)).toEqual(row.pkgs);
    });

  it("sizes: the pinned tools for this system plus Google's sizes", () => {
    const p = planInstall({ report: report(), home: "C:\\Users\\Ada", env: winEnv, java, catalog });
    expect(p.steps[0]).toMatchObject({ bytes: 155_655_386, version: "22.0" });
    expect(p.bytes).toBe(155_655_386 + 8_188_601 + 456_613_348 + 1_738_815_903);
    expect(p.cmdlineDir).toBe("latest");
    expect(p.steps.at(-1)).toMatchObject({ id: "avd", avd: DEFAULT_AVD_NAME });
  });

  it("the AVD name: the person's, never one already taken", () => {
    expect(freeAvdName("Pixel", ["pixel"])).toBe("Pixel_2");
    expect(freeAvdName("Pixel", ["Pixel", "Pixel_2"])).toBe("Pixel_3");
    const p = planInstall({
      report: report({}, { avds: [{ name: DEFAULT_AVD_NAME }] }),
      home: "C:\\Users\\Ada",
      env: winEnv,
      java,
      catalog,
      avdName: "bad name!",
    });
    expect(p.steps.at(-1)?.avd).toBe(`${DEFAULT_AVD_NAME}_2`);
  });

  it("pinned cmdline-tools 22.0 for every system, from Google's repository", () => {
    expect(CMDLINE_TOOLS.version).toBe("22.0");
    for (const [os, arch] of [
      ["windows", "x64"],
      ["linux", "x64"],
      ["macos", "x64"],
      ["macos", "arm64"],
    ] as const) {
      const a = cmdlineArchive(os, arch);
      expect(a.url).toMatch(/^https:\/\/dl\.google\.com\/android\/repository\/commandlinetools-/);
      expect(a.sha1).toMatch(/^[0-9a-f]{40}$/);
    }
    expect(cmdlineArchive("macos", "arm64").url).toContain("mac_arm64");
  });
});

const XML = `<?xml version="1.0"?>
<sdk:sdk-repository>
  <license id="android-sdk-license" type="text">Terms &amp; Conditions
line two</license>
  <channel id="channel-0">stable</channel>
  <channel id="channel-2">dev</channel>
  <remotePackage path="emulator">
    <revision><major>37</major><minor>4</minor><micro>1</micro></revision>
    <uses-license ref="android-sdk-license"/><channelRef ref="channel-2"/>
    <archives><archive><complete><size>1</size><checksum type="sha1">aa</checksum><url>dev.zip</url></complete><host-os>windows</host-os><host-arch>x64</host-arch></archive></archives>
  </remotePackage>
  <remotePackage path="emulator">
    <revision><major>37</major><minor>3</minor><micro>10</micro></revision>
    <uses-license ref="android-sdk-license"/><channelRef ref="channel-0"/>
    <archives>
      <archive><complete><size>350068887</size><checksum type="sha1">bb</checksum><url>emulator-linux_x64.zip</url></complete><host-os>linux</host-os><host-arch>x64</host-arch></archive>
      <archive><complete><size>456613348</size><checksum type="sha1">cc</checksum><url>emulator-windows_x64.zip</url></complete><host-os>windows</host-os><host-arch>x64</host-arch></archive>
    </archives>
  </remotePackage>
  <remotePackage path="platform-tools">
    <revision><major>37</major><minor>0</minor><micro>3</micro></revision>
    <uses-license ref="android-sdk-license"/><channelRef ref="channel-0"/>
    <archives><archive><complete><size>8188601</size><checksum type="sha1">dd</checksum><url>pt-win.zip</url></complete><host-os>windows</host-os></archive></archives>
  </remotePackage>
</sdk:sdk-repository>`;

describe("Google's lists", () => {
  it("stable channel, this system's archive, the licence's text", () => {
    const c = parseRepository(XML, "windows", "x64");
    expect(c.packages.emulator).toEqual({
      version: "37.3.10",
      size: 456_613_348,
      sha1: "cc",
      url: "emulator-windows_x64.zip",
      licence: "android-sdk-license",
    });
    expect(c.packages["platform-tools"]?.size).toBe(8_188_601);
    expect(c.licences["android-sdk-license"]).toBe("Terms & Conditions\nline two");
    // No archive for Linux arm64 or macOS: not installable there.
    expect(parseRepository(XML, "linux", "arm64").packages.emulator).toBeUndefined();
    expect(parseRepository(XML, "macos", "arm64").packages["platform-tools"]).toBeUndefined();
  });

  it("sdkmanager's output: licence prompts and the download's percent", () => {
    const yes = new Set(["android-sdk-license"]);
    expect(
      licenceAnswer("License android-sdk-license:\n---\ntext\n---\nAccept? (y/N): ", yes),
    ).toEqual({ id: "android-sdk-license", yes: true });
    expect(licenceAnswer("License android-sdk-preview-license:\n…\nAccept? (y/N): ", yes)).toEqual({
      id: "android-sdk-preview-license",
      yes: false,
    });
    expect(licenceAnswer("License android-sdk-license:\n…", yes)).toBeUndefined();
    expect(
      downloadPercent("[====    ] 10% Downloading a.zip...\r[=====  ] 45% Downloading a.zip"),
    ).toBe(45);
    expect(downloadPercent("[=====] 50% Unzipping... a/b")).toBeUndefined();
  });

  it("Java: versions and where it is looked for", () => {
    expect(parseJavaVersion('openjdk version "17.0.13" 2024-10-15')).toBe(17);
    expect(parseJavaVersion('java version "1.8.0_392"')).toBe(8);
    expect(parseJavaVersion("openjdk 21.0.2 2024-01-16")).toBe(21);
    expect(parseJavaVersion("nothing")).toBeUndefined();
    const w = javaCandidates(
      "windows",
      { JAVA_HOME: "C:\\Program Files\\OpenLogic\\jdk-17", LOCALAPPDATA: "C:\\L" },
      ["C:\\bin"],
      "C:\\Users\\Ada",
    );
    expect(w[0]).toBe("C:\\Program Files\\OpenLogic\\jdk-17\\bin\\java.exe");
    expect(w[1]).toBe("C:\\bin\\java.exe");
    expect(w).toContain("C:\\Program Files\\Android\\Android Studio\\jbr\\bin\\java.exe");
    expect(javaCandidates("macos", {}, [], "/Users/a")).toContain(
      "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java",
    );
  });
});

// ---- The runner, with fake downloads and programs ----

const dirs: string[] = [];
afterEach(async () => {
  for (const d of dirs.splice(0)) await rm(d, { recursive: true, force: true });
});

async function everyFile(root: string): Promise<string[]> {
  const out: string[] = [];
  const walk = async (d: string) => {
    for (const e of await readdir(d, { withFileTypes: true })) {
      const p = join(d, e.name);
      if (e.isDirectory()) await walk(p);
      else out.push(p);
    }
  };
  await walk(root);
  return out;
}

const toolsZip = () => {
  const zip = zipSync({
    "cmdline-tools/bin/sdkmanager": new TextEncoder().encode("#!/bin/sh\n"),
    "cmdline-tools/lib/sdkmanager-classpath.jar": new Uint8Array([1, 2, 3]),
    "cmdline-tools/lib/avdmanager-classpath.jar": new Uint8Array([4, 5, 6]),
    "cmdline-tools/source.properties": new TextEncoder().encode("Pkg.Revision=22.0\n"),
  });
  return {
    zip,
    archive: {
      url: "https://dl.google.com/android/repository/commandlinetools-test.zip",
      size: zip.length,
      sha1: createHash("sha1").update(zip).digest("hex"),
    },
  };
};

/** A body in chunks; `each` runs before every chunk (a fake clock moves there). */
const chunked = (data: Uint8Array, parts: number, each?: (i: number) => void) => {
  const n = Math.ceil(data.length / parts);
  let i = 0;
  return new ReadableStream<Uint8Array>({
    async pull(c) {
      if (i >= parts) return c.close();
      // A pause between chunks: the job exists and can be read while the download runs.
      await new Promise((r) => setTimeout(r, 2));
      each?.(i);
      c.enqueue(data.subarray(i * n, Math.min(data.length, (i + 1) * n)));
      i++;
    },
  });
};

interface FakeRun {
  file: string;
  args: string[];
  env: NodeJS.ProcessEnv;
  written: string[];
}

/**
 * sdkmanager and avdmanager as they behave: a licence prompt for each package (or the one given),
 * the download's percent, then the package's folder; avdmanager asks about a custom profile.
 */
function fakeTools(o: { root: string; licence?: string; hang?: boolean; runs: FakeRun[] }): Launch {
  return (file, args, opts) => {
    const run: FakeRun = { file, args, env: opts.env, written: [] };
    o.runs.push(run);
    const listeners: ((t: string) => void)[] = [];
    const say = (t: string) => {
      for (const l of listeners) l(t);
    };
    let killed = false;
    // What the runner wrote, waiting to be read (a real program's stdin keeps it the same way).
    const inbox: string[] = [];
    let answer: ((t: string) => void) | undefined;
    let finish: (c: number | null) => void = () => {};
    const exit = new Promise<number | null>((d) => {
      finish = d;
    });
    const next = () =>
      new Promise<string>((r) => {
        const queued = inbox.shift();
        if (queued !== undefined) r(queued);
        else answer = r;
      });
    void (async () => {
      await new Promise((r) => setTimeout(r, 1));
      if (args.includes("-version")) {
        say('openjdk version "17.0.13" 2024-10-15\n');
        return finish(0);
      }
      const sdkRoot = args.find((a) => a.startsWith("--sdk_root="))?.slice(11);
      const install = args[args.indexOf("--install") + 1];
      if (install && sdkRoot) {
        say(`License ${o.licence ?? "android-sdk-license"}:\n-----\nTerms\n-----\nAccept? (y/N): `);
        const a = await next();
        if (a.trim() !== "y") {
          say("Skipping following packages as the license is not accepted:\n");
          return finish(0);
        }
        say("[==      ] 40% Downloading package.zip... \r");
        if (o.slowTemp) {
          await mkdir(join(sdkRoot, ".temp"), { recursive: true });
          await writeFile(join(sdkRoot, ".temp", "part.zip"), new Uint8Array(o.slowTemp));
          await new Promise((r) => setTimeout(r, 1300));
        }
        if (o.hang) return; // until killed
        say("[========] 100% Downloading package.zip... \r[===] 50% Unzipping... x\r");
        await mkdir(join(sdkRoot, ...install.split(";")), { recursive: true });
        await writeFile(
          join(sdkRoot, ...install.split(";"), "source.properties"),
          "Pkg.Revision=1\n",
        );
        return finish(0);
      }
      if (args.includes("create")) {
        say("Do you wish to create a custom hardware profile? [no] ");
        const a = await next();
        if (a.trim() !== "no") return finish(1);
        const name = args[args.indexOf("--name") + 1] as string;
        const home = opts.env.ANDROID_AVD_HOME as string;
        await mkdir(join(home, `${name}.avd`), { recursive: true });
        await writeFile(join(home, `${name}.ini`), "path=x\n");
        return finish(0);
      }
      finish(2);
    })();
    const p: Program = {
      onOutput: (cb) => listeners.push(cb),
      write: (t) => {
        run.written.push(t);
        if (answer) {
          const a = answer;
          answer = undefined;
          a(t);
        } else inbox.push(t);
      },
      exit,
      kill: () => {
        if (!killed) {
          killed = true;
          finish(null);
        }
      },
    };
    return p;
  };
}

/** The computer running the tests: the install writes real folders, so its paths are this machine's. */
const HOST_OS =
  process.platform === "win32" ? "windows" : process.platform === "darwin" ? "macos" : "linux";

async function setup(
  o: { licence?: string; hang?: boolean; slowTemp?: number; now?: () => number } = {},
) {
  const root = await mkdtemp(join(tmpdir(), "rg-emu-install-"));
  dirs.push(root);
  const home = join(root, "home");
  const outside = join(root, "elsewhere");
  await mkdir(outside, { recursive: true });
  await writeFile(join(outside, "keep.txt"), "untouched");
  // Where Android Studio puts the SDK on this system (detect.ts `standardSdk`).
  const target =
    HOST_OS === "windows"
      ? join(home, "AppData", "Local", "Android", "Sdk")
      : HOST_OS === "macos"
        ? join(home, "Library", "Android", "sdk")
        : join(home, "Android", "Sdk");
  const avdHome = join(home, ".android", "avd");
  const runs: FakeRun[] = [];
  const { zip, archive } = toolsZip();
  const fetched: string[] = [];
  const fetchFn = (async (url: string | URL) => {
    const u = String(url);
    fetched.push(u);
    if (REPOSITORY_LISTS.includes(u as never))
      return new Response(
        u.includes("sys-img")
          ? `<x><license id="android-sdk-license" type="text">Terms</license><remotePackage path="system-images;android-35;google_apis;x86_64"><revision><major>9</major></revision><uses-license ref="android-sdk-license"/><channelRef ref="channel-0"/><archives><archive><complete><size>1738815903</size><url>x.zip</url></complete></archive></archives></remotePackage></x>`
          : XML.replace(/windows/g, HOST_OS),
      );
    if (u === archive.url) return new Response(chunked(zip, 4));
    return new Response("no", { status: 404 });
  }) as typeof fetch;
  const jobs = new Jobs(o.now);
  const machine = new EmulatorMachine({
    settings: memorySettings(),
    os: HOST_OS,
    gather: async (s) => ({
      os: HOST_OS,
      arch: "x64",
      container: false,
      looked: [],
      avds: [],
      accel: { ok: true, kind: "kvm" },
      maxRunning: s.maxRunning,
      at: new Date().toISOString(),
    }),
    isSdk: async () => true,
  });
  const installer = new EmulatorInstaller({
    jobs,
    machine,
    env: () => ({ PATH: "/usr/bin" }),
    places: { ANDROID_AVD_HOME: avdHome },
    home,
    fetch: fetchFn,
    launch: fakeTools({ root, runs, ...o }),
    java: async () => ({ path: "/usr/bin/java", major: 17 }),
    cmdline: archive,
  });
  return { root, home, outside, target, avdHome, runs, fetched, jobs, installer, machine };
}

describe("the install runs only with the person's yes", () => {
  it("plan, refusals without the yes, then the whole install inside the SDK folder", async () => {
    const s = await setup();
    const plan = await s.installer.plan("me", {});
    expect(plan.blocked).toBeUndefined();
    expect(plan.target).toBe(s.target);
    expect(plan.steps.map((x) => x.id)).toEqual([
      "cmdline-tools",
      "licences",
      "platform-tools",
      "emulator",
      "system-image",
      "avd",
    ]);
    expect(plan.licences).toEqual([
      { id: "android-sdk-license", text: "Terms & Conditions\nline two" },
    ]);
    expect(plan.planId).toBeTruthy();
    // Planning downloads only Google's lists, never a package.
    expect(s.fetched.every((u) => REPOSITORY_LISTS.includes(u as never))).toBe(true);
    // No yes, no start.
    expect(() => s.installer.start("me", { planId: plan.planId as string })).toThrow(InstallError);
    expect(() =>
      s.installer.start("me", { planId: plan.planId as string, licenceAccepted: false }),
    ).toThrow(/licences/);
    expect(() => s.installer.start("me", { planId: "made-up", licenceAccepted: true })).toThrow(
      /not known/,
    );
    expect(() =>
      s.installer.start("someone-else", { planId: plan.planId as string, licenceAccepted: true }),
    ).toThrow(/not known/);
    expect(s.runs).toEqual([]);

    const job = s.installer.start("me", { planId: plan.planId as string, licenceAccepted: true });
    const end = (await s.jobs.settled(job.id)) as Job;
    expect(end.error).toBeUndefined();
    expect(end.state).toBe("done");
    expect(end.result).toEqual({ target: s.target, avd: DEFAULT_AVD_NAME });
    // A plan runs once.
    expect(() =>
      s.installer.start("me", { planId: plan.planId as string, licenceAccepted: true }),
    ).toThrow(/not known/);

    // Programs through Java, arguments one by one, the licence answered yes once per package.
    const sdkRuns = s.runs.filter((r) => r.args.includes("--install"));
    expect(sdkRuns.map((r) => r.args.at(-1))).toEqual([
      "platform-tools",
      "emulator",
      "system-images;android-35;google_apis;x86_64",
    ]);
    for (const r of sdkRuns) {
      expect(r.file).toBe("/usr/bin/java");
      expect(r.args).toContain("com.android.sdklib.tool.sdkmanager.SdkManagerCli");
      expect(r.args).toContain(`--sdk_root=${s.target}`);
      expect(r.written).toEqual(["y\n"]);
      expect(String(r.env.ANDROID_USER_HOME).startsWith(s.target)).toBe(true);
    }
    const avd = s.runs.find((r) => r.args.includes("create"));
    expect(avd?.args).toContain("com.android.sdklib.tool.AvdManagerCli");
    expect(avd?.written).toEqual(["no\n"]);

    // Every file is inside the SDK folder or the AVD's place; the rest is untouched.
    const files = await everyFile(s.root);
    expect(
      files
        .filter((f) => !inside(s.target, f) && !inside(s.avdHome, f))
        .map((f) => f.slice(s.root.length).split(sep).join("/")),
    ).toEqual(["/elsewhere/keep.txt"]);
    expect(await findCmdline(HOST_OS, s.target)).toBe(join(s.target, "cmdline-tools", "latest"));
    // Windows has no execute bit: the install makes the tools runnable only elsewhere.
    if (HOST_OS !== "windows")
      expect(
        (await stat(join(s.target, "cmdline-tools", "latest", "bin", "sdkmanager"))).mode & 0o111,
      ).toBeTruthy();
    // The work folder is gone.
    expect(files.some((f) => f.includes(".rasgeth-install"))).toBe(false);
    // This fake machine does not see the new SDK by itself: its folder is remembered.
    expect(s.machine.settings().sdkPath).toBe(s.target);
  });

  it("a licence the person did not accept is refused, and the install stops", async () => {
    const s = await setup({ licence: "android-sdk-preview-license" });
    const plan = await s.installer.plan("me", {});
    const job = s.installer.start("me", { planId: plan.planId as string, licenceAccepted: true });
    const end = (await s.jobs.settled(job.id)) as Job;
    expect(end.state).toBe("failed");
    expect(end.error?.message).toMatch(/did not accept: android-sdk-preview-license/);
    expect(s.runs.find((r) => r.args.includes("--install"))?.written).toEqual(["n\n"]);
  });

  it("cancel: the running program is stopped and the work folder removed", async () => {
    const s = await setup({ hang: true });
    const plan = await s.installer.plan("me", {});
    const job = s.installer.start("me", { planId: plan.planId as string, licenceAccepted: true });
    for (let i = 0; i < 200 && !s.runs.some((r) => r.args.includes("--install")); i++)
      await new Promise((r) => setTimeout(r, 5));
    await new Promise((r) => setTimeout(r, 20));
    expect(s.jobs.cancel("me", job.id)).toBe(true);
    const end = (await s.jobs.settled(job.id)) as Job;
    expect(end.state).toBe("cancelled");
    expect((await everyFile(s.root)).some((f) => f.includes(".rasgeth-install"))).toBe(false);
  });

  it("one install at a time", async () => {
    const s = await setup({ hang: true });
    const a = await s.installer.plan("me", {});
    const b = await s.installer.plan("me", {});
    const job = s.installer.start("me", { planId: a.planId as string, licenceAccepted: true });
    expect(() =>
      s.installer.start("me", { planId: b.planId as string, licenceAccepted: true }),
    ).toThrow(/already running/);
    s.jobs.cancel("me", job.id);
    await s.jobs.settled(job.id);
  });

  it("the bar: bytes of the download with speed and time left", async () => {
    let clock = 1_000_000;
    const s = await setup({ now: () => clock });
    const { zip, archive } = toolsZip();
    const seen: NonNullable<Job["steps"][number]["progress"]>[] = [];
    let jobId = "";
    const installer = new EmulatorInstaller({
      jobs: s.jobs,
      machine: s.machine,
      env: () => ({}),
      places: { ANDROID_AVD_HOME: s.avdHome },
      home: s.home,
      fetch: (async (url: string | URL) => {
        const u = String(url);
        if (REPOSITORY_LISTS.includes(u as never))
          return new Response(XML.replace(/windows/g, HOST_OS));
        return new Response(
          chunked(zip, 8, () => {
            clock += 1000;
            const p = s.jobs.get("me", jobId)?.steps.find((x) => x.progress)?.progress;
            if (p) seen.push(p);
          }),
        );
      }) as typeof fetch,
      launch: fakeTools({ root: s.root, runs: s.runs }),
      java: async () => ({ path: "/usr/bin/java", major: 17 }),
      cmdline: archive,
    });
    const plan = await installer.plan("me", { only: undefined });
    // The image size is unknown in this list: the plan still reads, the step has no bytes.
    jobId = installer.start("me", { planId: plan.planId as string, licenceAccepted: true }).id;
    await s.jobs.settled(jobId);
    const last = seen.at(-1);
    expect(last?.total).toBe(archive.size);
    expect(last?.rate).toBeGreaterThan(0);
    expect(last?.secondsLeft).not.toBeNull();
  });

  it("sdkmanager's bar also reads the bytes of its download in <sdk>/.temp", async () => {
    const s = await setup({ slowTemp: 6_000_000 });
    const plan = await s.installer.plan("me", {});
    const job = s.installer.start("me", { planId: plan.planId as string, licenceAccepted: true });
    const seen: number[] = [];
    // Up to 15 s: a slow machine (macOS on CI) reaches the step later.
    for (let i = 0; i < 1500; i++) {
      const j = s.jobs.get("me", job.id) as Job;
      const p = j.steps.find((x) => x.id === "platform-tools")?.progress;
      if (p) seen.push(p.done);
      if (j.state !== "running") break;
      await new Promise((r) => setTimeout(r, 10));
    }
    // 40% of 8 188 601 bytes from the percent (3.3 MB); 6 MB already in the folder.
    expect(seen).toContain(6_000_000);
    expect((await s.jobs.settled(job.id))?.state).toBe("done");
  }, 30_000);

  it("a member outside the folder stops the unpacking (zip-slip)", async () => {
    const root = await mkdtemp(join(tmpdir(), "rg-zipslip-"));
    dirs.push(root);
    const into = join(root, "in");
    await mkdir(into);
    const file = join(root, "bad.zip");
    await writeFile(
      file,
      zipSync({ "ok.txt": new Uint8Array([1]), "../evil.txt": new Uint8Array([2]) }),
    );
    await expect(unzipInto(file, into, new AbortController().signal)).rejects.toThrow(/outside/);
    expect((await readdir(root)).sort()).toEqual(["bad.zip", "in"]);
  });

  it("no Java: the plan says so and has no id", async () => {
    const s = await setup();
    const installer = new EmulatorInstaller({
      jobs: s.jobs,
      machine: s.machine,
      env: () => ({}),
      home: s.home,
      fetch: (async () => new Response(XML)) as typeof fetch,
      java: async () => undefined,
    });
    const p: EmuInstallPlan = await installer.plan("me", {});
    expect(p.blocked).toBe("no-java");
    expect(p.planId).toBeUndefined();
  });
});

describe("over HTTP", () => {
  it("plan, a start without the licences refused, then the job", async () => {
    const s0 = await setup();
    const tools = toolsZip();
    const srv = await startServer(
      [],
      {},
      {
        emulators: s0.machine,
        emuInstall: {
          places: { ANDROID_AVD_HOME: s0.avdHome },
          home: s0.home,
          fetch: (async (url: string | URL) => {
            const u = String(url);
            if (REPOSITORY_LISTS.includes(u as never))
              return new Response(XML.replace(/windows/g, HOST_OS));
            return new Response(tools.zip);
          }) as typeof fetch,
          launch: fakeTools({ root: s0.root, runs: s0.runs }),
          java: async () => ({ path: "/usr/bin/java", major: 17 }),
          cmdline: tools.archive,
        },
      },
    );
    try {
      const bad = await srv.api("POST", "/api/emulators/install/plan", { avdName: "no spaces" });
      expect(bad.status).toBe(400);
      const plan = await srv.api<EmuInstallPlan>("POST", "/api/emulators/install/plan", {});
      expect(plan.status).toBe(200);
      expect(plan.body.planId).toBeTruthy();
      expect(plan.body.licences[0]?.text).toContain("Terms");
      const no = await srv.api<{ code: string }>("POST", "/api/emulators/install/start", {
        planId: plan.body.planId,
      });
      expect(no.status).toBe(400);
      expect(no.body.code).toBe("licence");
      const ok = await srv.api<{ jobId: string }>("POST", "/api/emulators/install/start", {
        planId: plan.body.planId,
        licenceAccepted: true,
      });
      expect(ok.status).toBe(200);
      let job: Job | undefined;
      for (let i = 0; i < 400; i++) {
        job = (await srv.api<Job>("GET", `/api/jobs/${ok.body.jobId}`)).body;
        if (job.state !== "running") break;
        await new Promise((r) => setTimeout(r, 10));
      }
      expect(job?.state).toBe("done");
      expect(job?.kind).toBe("emulator_install");
    } finally {
      await srv.close();
    }
  });
});
