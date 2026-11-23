// @vitest-environment jsdom
// 3.12.2: iOS simulators in the page. The bridge's install window (what is downloaded, where, its
// licence; blocks in words; nothing starts before the button; the job with its bar), the offer
// only on a Mac that misses the bridge, the report on Linux saying «use a Mac node», a
// simulator's screen without Android's back and recents buttons, and every word in it and en.
import type { EmulatorReport, IosBridgePlan, Job } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { dictionaries, lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const sent: unknown[] = [];
let plan: IosBridgePlan;
let job: Job;
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "iosBridgePlan") return Promise.resolve(plan);
        if (name === "startIosBridgeInstall") return Promise.resolve({ jobId: "J1" });
        if (name === "job") return Promise.resolve(job);
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  getLive: () => ({ send: (m: unknown) => sent.push(m) }),
}));

const { EmulatorInstall, installOffer } = await import("../src/components/EmulatorInstall.js");
const { MachineReport } = await import("../src/components/Emulators.js");
const { iosBlockText } = await import("../src/components/IosBridgeInstall.js");
const { DeviceScreen } = await import("../src/components/DeviceScreen.js");
const { asking } = await import("../src/components/dialogs.js");
const { deviceScreens } = await import("../src/state.js");

const mac = (over: Partial<EmulatorReport> = {}): EmulatorReport => ({
  os: "macos",
  arch: "arm64",
  container: false,
  android: { looked: [], avds: [], attached: [], accel: { ok: true, kind: "hvf" } },
  ios: {
    xcode: "27.2",
    simulators: [{ name: "iPhone 18", udid: "U", runtime: "iOS 27.2", state: "shutdown" }],
    ready: false,
  },
  missing: ["ios-bridge"],
  ready: false,
  maxRunning: 2,
  at: "2026-11-23T10:00:00.000Z",
  ...over,
});

beforeEach(() => {
  calls.length = 0;
  sent.length = 0;
  lang.value = "en";
  plan = {
    planId: "P1",
    folder: "/Users/ada/Library/Application Support/Rasgeth/ios-bridge",
    version: "0.1.49",
    bytes: 40_000_000,
    licence: "Apache-2.0",
  };
  job = {
    id: "J1",
    kind: "ios_bridge_install",
    state: "running",
    steps: [
      { id: "ios-download", state: "running" },
      { id: "ios-install", state: "pending" },
    ],
  } as unknown as Job;
});
afterEach(cleanup);

describe("the iOS bridge's install", () => {
  it("is offered only on a Mac that misses the bridge", () => {
    expect(installOffer(mac()).ios).toBe(true);
    expect(installOffer(mac({ missing: [] })).ios).toBe(false);
    expect(installOffer({ ...mac(), os: "linux", missing: ["ios-bridge"] }).ios).toBe(false);
  });

  it("shows what is downloaded and starts only with the button", async () => {
    const v = render(<EmulatorInstall r={mac()} onDone={() => {}} />);
    fireEvent.click(v.getByText("Install the iOS bridge"));
    await waitFor(() => expect(v.getByText(/serve-sim 0.1.49/)).toBeTruthy());
    const text = document.body.textContent ?? "";
    expect(text).toContain("Apache-2.0");
    expect(text).toContain("ios-bridge");
    expect(text).toContain("Removing that folder removes it");
    expect(calls.map((c) => c[0])).toEqual(["iosBridgePlan"]);
    fireEvent.click(v.getByText("Download and install"));
    await waitFor(() => expect(calls.map((c) => c[0])).toContain("startIosBridgeInstall"));
    expect(calls.find((c) => c[0] === "startIosBridgeInstall")?.[1]).toEqual([{ planId: "P1" }]);
    expect(document.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
  });

  it("says why it cannot, with no button to start", async () => {
    plan = { folder: "/x", version: "0.1.49", bytes: 0, licence: "Apache-2.0", blocked: "intel" };
    const v = render(<EmulatorInstall r={mac()} onDone={() => {}} />);
    fireEvent.click(v.getByText("Install the iOS bridge"));
    await waitFor(() => expect(v.getByText(/Intel Mac/)).toBeTruthy());
    expect(v.queryByText("Download and install")).toBeNull();
  });

  it("has every word in both languages", () => {
    for (const l of ["it", "en"] as const) {
      lang.value = l;
      for (const b of ["not-mac", "intel", "no-xcode", "no-npm", "offline", "nothing"] as const) {
        expect(iosBlockText(b)).not.toMatch(/^ibBlock_/);
        expect(iosBlockText(b).length).toBeGreaterThan(10);
      }
    }
    const keys = (d: Record<string, string>) =>
      Object.keys(d)
        .filter((k) => /^(ib|emIos|emRunningSim|emMiss_ios|dvRepair|dvTouch)/.test(k))
        .sort();
    expect(keys(dictionaries.it)).toEqual(keys(dictionaries.en));
    expect(keys(dictionaries.en)).toContain("ibLead");
    expect(JSON.stringify(dictionaries.en)).not.toContain("3.12.2");
    expect(JSON.stringify(dictionaries.it)).not.toContain("3.12.2");
  });
});

describe("the report", () => {
  it("shows Xcode, the bridge, the runtimes and who is ready", () => {
    const ready = mac({
      ios: {
        xcode: "27.2",
        simulators: [{ name: "iPhone 18", udid: "U", runtime: "iOS 27.2", state: "shutdown" }],
        bridge: "serve-sim",
        bridgeVersion: "0.1.49",
        bridgeDir: "/ios-bridge",
        ready: true,
      },
      missing: [],
    });
    const v = render(<MachineReport r={ready} />);
    const text = v.container.textContent ?? "";
    expect(text).toContain("serve-sim 0.1.49, in /ios-bridge");
    expect(text).toContain("iPhone 18 (iOS 27.2)");
    expect(text).toContain("open in the Canvas");
  });

  it("on Linux says to use a Mac node", () => {
    const v = render(
      <MachineReport r={{ ...mac(), os: "linux", arch: "x64", missing: [], ios: undefined }} />,
    );
    expect(v.container.textContent).toContain("pair a Mac as a node");
  });
});

describe("Repair touches", () => {
  const answer = async (yes: boolean) => {
    await waitFor(() => expect(asking.value).toHaveLength(1));
    const a = asking.value[0] as { title: string; text?: string; done: (y: boolean) => void };
    a.done(yes);
    asking.value = [];
    return a;
  };

  it("asks first in our Modal, saying what it does, and only a yes repairs", async () => {
    deviceScreens.value = {};
    const v = render(<DeviceScreen device="ios:UDID" title="iPhone 18" />);
    fireEvent.click(v.getByText("Repair touches"));
    const q = await answer(false);
    expect(q.title).toBe("Repair the touches of iPhone 18?");
    expect(q.text).toContain("restarts the simulator's home screen and closes the apps open on it");
    await new Promise((r) => setTimeout(r, 10));
    expect(calls.some((c) => c[0] === "repairDeviceTouches")).toBe(false);
    fireEvent.click(v.getByText("Repair touches"));
    await answer(true);
    await waitFor(() =>
      expect(calls.find((c) => c[0] === "repairDeviceTouches")?.[1]).toEqual(["ios:UDID"]),
    );
  });

  it("is offered with a hint when taps changed nothing, never on Android, in Settings too", async () => {
    deviceScreens.value = {
      "ios:UDID": { state: "on", control: "agents", hint: "touches" },
    };
    const v = render(<DeviceScreen device="ios:UDID" title="iPhone 18" />);
    expect(v.container.textContent).toContain("Several taps in a row changed nothing");
    cleanup();
    const a = render(<DeviceScreen device="avd:Pixel" title="Pixel" />);
    expect(a.container.textContent).not.toContain("Repair touches");
    lang.value = "it";
    cleanup();
    const it = render(<DeviceScreen device="ios:UDID" title="iPhone 18" />);
    expect(it.container.textContent).toContain("Ripara i tocchi");
  });
});

describe("a simulator's screen", () => {
  it("has home and turning, not back and recents", () => {
    const ios = render(<DeviceScreen device="ios:UDID" title="iPhone 18" />);
    expect(ios.container.querySelectorAll(".device-keys button")).toHaveLength(2);
    cleanup();
    const android = render(<DeviceScreen device="avd:Pixel" title="Pixel" />);
    expect(android.container.querySelectorAll(".device-keys button")).toHaveLength(4);
  });
});
