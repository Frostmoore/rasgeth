// @vitest-environment jsdom
// 3.11 phase 1: Settings › Emulators. This machine's report (SDK and where it was found, AVDs,
// running emulators and phones, what is missing in words), the folder the person chooses (refused
// with the server's words), how many emulators at once, and the nodes' reports. Words in it/en,
// no native checkboxes.
import type { EmulatorReport, EmulatorsState, EmuMissing } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { dictionaries, lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
let state: EmulatorsState;
let refuse: string | undefined;
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "setEmulatorSettings" && refuse) return Promise.reject(new Error(refuse));
        if (name === "setEmulatorSettings")
          state = { ...state, settings: { ...state.settings, ...(args[0] as object) } };
        return Promise.resolve(state);
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { Emulators, missingText, statusLine, attachedFacts } = await import(
  "../src/components/Emulators.js"
);

const report = (over: Partial<EmulatorReport> = {}): EmulatorReport => ({
  os: "windows",
  arch: "x64",
  container: false,
  android: {
    sdk: {
      root: "D:\\Android\\Sdk",
      source: "studio",
      emulator: "35.2.10",
      platformTools: "37.0.1",
      cmdlineTools: true,
      images: ["android-35/google_apis_playstore/x86_64"],
    },
    looked: [{ path: "D:\\Android\\Sdk", source: "studio" }],
    avds: [{ name: "Medium_Phone_API_35", api: 35, abi: "x86_64", playStore: true }],
    attached: [
      { serial: "emulator-5554", kind: "emulator", state: "device", avd: "Medium_Phone_API_35" },
      { serial: "R58", kind: "phone", state: "unauthorized", link: "usb" },
    ],
    accel: { ok: true, kind: "whpx" },
  },
  missing: ["emulator-old"],
  ready: true,
  maxRunning: 2,
  at: "2026-11-22T10:00:00.000Z",
  ...over,
});

beforeEach(() => {
  lang.value = "en";
  calls.length = 0;
  refuse = undefined;
  state = {
    here: { id: "here", name: "studio-pc", online: true, report: report() },
    settings: { sdkPath: null, maxRunning: 2 },
    nodes: [
      {
        id: "SHA256:node",
        name: "mac-mini",
        online: true,
        report: report({
          os: "macos",
          arch: "arm64",
          android: {
            looked: [],
            avds: [],
            attached: [],
            adbIdle: true,
            accel: { ok: true, kind: "hvf" },
          },
          ios: {
            xcode: "27.2",
            simulators: [{ name: "iPhone 18", udid: "U", runtime: "iOS 27.2", state: "shutdown" }],
          },
          missing: ["sdk", "ios-bridge"],
          ready: false,
        }),
      },
      { id: "SHA256:old", name: "old-box", online: false },
    ],
  };
});
afterEach(cleanup);

describe("Settings › Emulators", () => {
  it("shows this machine, its devices, what is missing and the nodes", async () => {
    const v = render(<Emulators />);
    await waitFor(() => expect(v.getByText(/Ready: emulators can run here/)).toBeTruthy());
    const text = v.container.textContent ?? "";
    expect(text).toContain("D:\\Android\\Sdk");
    expect(text).toContain("from Android Studio's settings");
    expect(text).toContain("Medium_Phone_API_35");
    expect(text).toContain("Emulator · Medium_Phone_API_35");
    expect(text).toContain("waiting for your yes on the phone");
    expect(text).toContain("The emulator is old");
    expect(text).toContain("mac-mini");
    expect(text).toContain("iPhone 18 (iOS 27.2)");
    expect(text).toContain("A bridge for touches on iOS simulators");
    expect(text).toContain("older than 3.11");
    expect(v.container.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
  });

  it("saves a folder, shows the server's refusal, forgets it, and sets how many at once", async () => {
    const v = render(<Emulators />);
    await waitFor(() => expect(v.getByText("Use this folder")).toBeTruthy());
    const input = v.container.querySelector("input") as HTMLInputElement;
    refuse = "No Android SDK in that folder";
    fireEvent.input(input, { target: { value: "E:\\nothing" } });
    fireEvent.click(v.getByText("Use this folder"));
    await waitFor(() => expect(v.getByText(/No Android SDK in that folder/)).toBeTruthy());
    refuse = undefined;
    fireEvent.input(input, { target: { value: "E:\\sdk" } });
    fireEvent.click(v.getByText("Use this folder"));
    await waitFor(() => expect(v.getByText("Forget it")).toBeTruthy());
    expect(calls.filter((c) => c[0] === "setEmulatorSettings").map((c) => c[1][0])).toEqual([
      { sdkPath: "E:\\nothing" },
      { sdkPath: "E:\\sdk" },
    ]);
    fireEvent.click(v.getByText("Forget it"));
    fireEvent.click(v.getByText("3"));
    await waitFor(() =>
      expect(calls.filter((c) => c[0] === "setEmulatorSettings").map((c) => c[1][0])).toEqual([
        { sdkPath: "E:\\nothing" },
        { sdkPath: "E:\\sdk" },
        { sdkPath: null },
        { maxRunning: 3 },
      ]),
    );
  });

  it("asks again when the person says so", async () => {
    const v = render(<Emulators />);
    await waitFor(() => expect(v.getByText("Look again")).toBeTruthy());
    fireEvent.click(v.getByText("Look again"));
    await waitFor(() =>
      expect(calls.some((c) => c[0] === "emulators" && c[1][0] === true)).toBe(true),
    );
  });

  it("says why a machine is not ready, in Italian too", () => {
    lang.value = "it";
    expect(statusLine(report({ container: true, ready: false }))).toMatch(/container/);
    expect(
      statusLine(
        report({ ready: false, android: { ...report().android, sdk: undefined as never } }),
      ),
    ).toMatch(/Nessun SDK Android/);
    expect(
      attachedFacts({
        serial: "1.2.3.4:5555",
        kind: "phone",
        state: "device",
        link: "wifi",
        model: "Pixel 7",
      }),
    ).toBe("Telefono via Wi-Fi · Pixel 7");
  });

  it("has words for every missing piece in both languages", () => {
    const all: EmuMissing[] = [
      "sdk",
      "emulator",
      "platform-tools",
      "cmdline-tools",
      "system-image",
      "avd",
      "accel",
      "emulator-old",
      "xcode",
      "ios-bridge",
    ];
    for (const l of ["it", "en"] as const) {
      lang.value = l;
      for (const m of all) {
        const w = missingText(m);
        expect(w.length).toBeGreaterThan(10);
        expect(w).not.toMatch(/^emMiss_/);
      }
    }
    const it = Object.keys(dictionaries.it).filter((k) => k.startsWith("em"));
    const en = Object.keys(dictionaries.en).filter((k) => k.startsWith("em"));
    expect(it.sort()).toEqual(en.sort());
  });
});
