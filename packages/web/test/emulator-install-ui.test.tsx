// @vitest-environment jsdom
// 3.11 phase 5: the guided install's window in Settings › Emulators. The buttons appear only when
// something can be installed (never in a container), the window shows the steps, the folder, the
// sizes and the licence text, the Install button waits for the licences accepted (our switch, no
// native checkbox), then the job with its bar (percent, speed, time left) and the report read
// again at the end. Blocks are said in words; it/en both have every word.
import type { EmuInstallPlan, EmulatorReport, Job } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { dictionaries, lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
let plan: EmuInstallPlan;
let job: Job;
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "emulatorInstallPlan") return Promise.resolve(plan);
        if (name === "startEmulatorInstall") return Promise.resolve({ jobId: "J1" });
        if (name === "job") return Promise.resolve(job);
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { EmulatorInstall, installOffer } = await import("../src/components/EmulatorInstall.js");

const report = (over: Partial<EmulatorReport> = {}): EmulatorReport => ({
  os: "windows",
  arch: "x64",
  container: false,
  android: { looked: [], avds: [], attached: [], accel: { ok: false, reason: "unknown" } },
  missing: ["sdk"],
  ready: false,
  maxRunning: 2,
  at: "2026-11-22T10:00:00.000Z",
  ...over,
});

const fullPlan = (): EmuInstallPlan => ({
  planId: "P1",
  target: "C:\\Users\\Ada\\AppData\\Local\\Android\\Sdk",
  targetStandard: true,
  avdHome: "C:\\Users\\Ada\\.android\\avd",
  steps: [
    { id: "cmdline-tools", bytes: 155_655_386, version: "22.0" },
    { id: "licences" },
    { id: "platform-tools", package: "platform-tools", bytes: 8_188_601 },
    { id: "emulator", package: "emulator", bytes: 456_613_348 },
    {
      id: "system-image",
      package: "system-images;android-35;google_apis;x86_64",
      bytes: 1_738_815_903,
    },
    {
      id: "avd",
      package: "system-images;android-35;google_apis;x86_64",
      avd: "Rasgeth_Phone_API_35",
    },
  ],
  licences: [
    {
      id: "android-sdk-license",
      text: "Terms and Conditions\n\nThis is the Android SDK License Agreement",
    },
  ],
  bytes: 2_359_273_238,
  notes: [],
  java: { path: "C:\\Program Files\\OpenLogic\\jdk-17\\bin\\java.exe", major: 17 },
});

beforeEach(() => {
  lang.value = "en";
  calls.length = 0;
  plan = fullPlan();
  job = {
    id: "J1",
    kind: "emulator_install",
    vars: {},
    state: "running",
    steps: [
      {
        id: "cmdline-tools",
        state: "running",
        progress: { done: 77_827_693, total: 155_655_386, rate: 12_500_000, secondsLeft: 6.2 },
      },
      { id: "licences", state: "waiting" },
      { id: "platform-tools", state: "waiting" },
      { id: "emulator", state: "waiting" },
      { id: "system-image", state: "waiting" },
      { id: "avd", state: "waiting" },
    ],
    startedAt: "2026-11-22T10:00:00.000Z",
  };
});
afterEach(cleanup);

describe("the guided install", () => {
  it("offers install and update only where it can do something", () => {
    expect(installOffer(report())).toEqual({ install: true, update: false, ios: false });
    expect(installOffer(report({ missing: ["emulator-old"] }))).toEqual({
      install: false,
      update: true,
      ios: false,
    });
    expect(installOffer(report({ container: true, missing: ["sdk", "accel"] }))).toEqual({
      install: false,
      update: false,
      ios: false,
    });
    expect(installOffer(report({ missing: ["xcode"] }))).toEqual({
      install: false,
      update: false,
      ios: false,
    });
  });

  it("the window: steps, folder, sizes, licence; Install waits for the yes; then the bar", async () => {
    const onDone = vi.fn();
    const v = render(<EmulatorInstall r={report()} onDone={onDone} />);
    fireEvent.click(v.getByText("Install what is missing"));
    await waitFor(() => expect(v.getByText("What it will do")).toBeTruthy());
    const text = v.container.ownerDocument.body.textContent ?? "";
    expect(text).toContain("C:\\Users\\Ada\\AppData\\Local\\Android\\Sdk");
    expect(text).toContain("the standard place on this system");
    expect(text).toContain("Android's command-line tools 22.0");
    expect(text).toContain("The virtual phone Rasgeth_Phone_API_35");
    expect(text).toContain("To download: ");
    expect(text).toContain("This is the Android SDK License Agreement");
    expect(text).toContain("With Java 17:");
    expect(calls[0]).toEqual(["emulatorInstallPlan", [{}]]);
    const body = v.container.ownerDocument.body;
    expect(body.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
    const install = v.getByText("Install").closest("button") as HTMLButtonElement;
    expect(install.disabled).toBe(true);
    fireEvent.click(v.getByRole("switch"));
    await waitFor(() => expect(install.disabled).toBe(false));
    fireEvent.click(install);
    await waitFor(() =>
      expect(calls.find((c) => c[0] === "startEmulatorInstall")?.[1][0]).toEqual({
        planId: "P1",
        licenceAccepted: true,
      }),
    );
    await waitFor(() => expect(body.textContent).toContain("50%"));
    expect(body.textContent).toMatch(/\/s/);
    expect(body.textContent).toContain("less than a minute");
    expect(v.getByText("Stop")).toBeTruthy();
    expect(onDone).not.toHaveBeenCalled();
  });

  it("the end of the job reads the report again and says so", async () => {
    job = { ...job, state: "done", steps: job.steps.map((s) => ({ id: s.id, state: "done" })) };
    const onDone = vi.fn();
    const v = render(<EmulatorInstall r={report()} onDone={onDone} />);
    fireEvent.click(v.getByText("Install what is missing"));
    await waitFor(() => expect(v.getByRole("switch")).toBeTruthy());
    fireEvent.click(v.getByRole("switch"));
    fireEvent.click(v.getByText("Install").closest("button") as HTMLButtonElement);
    await waitFor(() => expect(onDone).toHaveBeenCalledTimes(1));
    expect(v.getByText(/Done. The report of this machine/)).toBeTruthy();
  });

  it("a blocked plan says why in words and offers no Install", async () => {
    plan = {
      ...fullPlan(),
      planId: undefined,
      blocked: "no-accel",
      accelReason: "no-kvm",
      steps: [],
      licences: [],
      bytes: 0,
      notes: ["node"],
    } as EmuInstallPlan;
    const v = render(
      <EmulatorInstall r={report({ os: "linux", missing: ["sdk", "accel"] })} onDone={() => {}} />,
    );
    fireEvent.click(v.getByText("Install what is missing"));
    await waitFor(() => expect(v.getByText(/far too slow/)).toBeTruthy());
    expect(v.getByText(/Settings › Nodes/)).toBeTruthy();
    expect(v.queryByText("Install")).toBeNull();
  });

  it("the emulator update asks for its own plan", async () => {
    plan = {
      ...fullPlan(),
      target: "D:\\androidvd",
      targetStandard: false,
      steps: [
        { id: "licences" },
        { id: "emulator-update", package: "emulator", version: "37.3.10" },
      ],
      bytes: 456_613_348,
    };
    const v = render(
      <EmulatorInstall r={report({ missing: ["emulator-old"] })} onDone={() => {}} />,
    );
    fireEvent.click(v.getByText("Update the emulator"));
    await waitFor(() => expect(v.getByText(/at its latest version 37.3.10/)).toBeTruthy());
    expect(calls[0]).toEqual(["emulatorInstallPlan", [{ only: "emulator-update" }]]);
    expect(v.getByText("Update").closest("button")).toBeTruthy();
  });

  it("every word in both languages", () => {
    const en = Object.keys(dictionaries.en).filter((k) => k.startsWith("ei"));
    const it = Object.keys(dictionaries.it).filter((k) => k.startsWith("ei"));
    expect(en.length).toBeGreaterThan(40);
    expect(it.sort()).toEqual(en.sort());
  });
});
