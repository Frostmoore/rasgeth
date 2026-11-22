// The agents' devices (3.11, phase 3) in the permission policy, as a table: change it first.
// Looking (list, look, wait, logs) changes nothing and works in every mode. Gestures on a device
// are ordinary work. Installing an app on an emulator is an ordinary request (it follows the
// person's choices, classifier included). On a real phone installing or launching an app is the
// person's alone (`device-phone-app`, human only), and installing is truly dangerous too: it always
// asks the person, whatever the rules and modes.
import { describe, expect, it } from "vitest";
import {
  DEFAULT_POLICY,
  DEVICE_INSTALL,
  DEVICE_PHONE_APP,
  type Decision,
  evaluate,
  type PolicySettings,
} from "../src/index.js";

const settings = (over: Partial<PolicySettings> = {}): PolicySettings => ({
  ...DEFAULT_POLICY,
  roots: ["/work/app"],
  home: "/home/ann",
  ...over,
});

type Row = [
  label: string,
  mode: "auto" | "manual" | "plan" | "readonly",
  tool: string,
  input: unknown,
  decision: Decision,
  danger: string[],
  over?: Partial<PolicySettings>,
];

const APK = "/work/app/build/app-debug.apk";
const TABLE: Row[] = [
  ["listing devices", "auto", "device_list", {}, "allow", []],
  ["listing devices in plan mode", "plan", "device_list", {}, "allow", []],
  [
    "looking at an emulator in read-only mode",
    "readonly",
    "device_look",
    { device: "avd:Pixel_8" },
    "allow",
    [],
  ],
  ["waiting for a text", "plan", "device_wait", { device: "avd:Pixel_8", text: "Ok" }, "allow", []],
  ["reading the logs", "readonly", "device_logs", { device: "emulator-5554" }, "allow", []],
  ["a tap on an emulator", "auto", "device_tap", { device: "avd:Pixel_8", ref: 3 }, "allow", []],
  [
    "a tap on a phone",
    "auto",
    "device_tap",
    { device: "R58N12ABCDE", x: 0.5, y: 0.5 },
    "allow",
    [],
  ],
  ["a tap in plan mode", "plan", "device_tap", { device: "avd:Pixel_8", ref: 3 }, "deny", []],
  [
    "typing on an emulator",
    "auto",
    "device_type",
    { device: "avd:Pixel_8", text: "hello" },
    "allow",
    [],
  ],
  [
    "opening an emulator (starts it)",
    "auto",
    "device_open",
    { device: "avd:Pixel_8" },
    "allow",
    [],
  ],
  [
    "installing on an emulator: an ordinary request",
    "auto",
    "device_install",
    { device: "avd:Pixel_8", apk: APK },
    "ask",
    [DEVICE_INSTALL],
  ],
  [
    "installing on a running emulator by its serial",
    "auto",
    "device_install",
    { device: "emulator-5556", apk: APK },
    "ask",
    [DEVICE_INSTALL],
  ],
  [
    "installing on an emulator, a rule allows it",
    "auto",
    "device_install",
    { device: "avd:Pixel_8", apk: APK },
    "allow",
    [DEVICE_INSTALL],
    { rules: [{ tool: "device_install", decision: "allow" }] },
  ],
  [
    "launching an app on an emulator",
    "auto",
    "device_launch",
    { device: "avd:Pixel_8", package: "com.example.app" },
    "allow",
    [],
  ],
  [
    "launching an app on a phone: the person's",
    "auto",
    "device_launch",
    { device: "R58N12ABCDE", package: "com.example.app" },
    "ask",
    [DEVICE_PHONE_APP],
  ],
  [
    "launching on a phone over Wi-Fi",
    "auto",
    "device_launch",
    { device: "192.168.1.40:5555", package: "com.example.app" },
    "ask",
    [DEVICE_PHONE_APP],
  ],
  [
    "installing on a phone: the person's, and truly dangerous",
    "auto",
    "device_install",
    { device: "R58N12ABCDE", apk: APK },
    "ask",
    [DEVICE_PHONE_APP, "critical-system"],
  ],
  [
    "installing on a phone, a rule allows every tool: still asked",
    "auto",
    "device_install",
    { device: "R58N12ABCDE", apk: APK },
    "ask",
    [DEVICE_PHONE_APP, "critical-system"],
    { rules: [{ tool: "*", decision: "allow" }] },
  ],
  [
    "installing in plan mode",
    "plan",
    "device_install",
    { device: "avd:Pixel_8", apk: APK },
    "deny",
    [DEVICE_INSTALL],
  ],
];

describe("devices in the policy (3.11): the table", () => {
  for (const [label, mode, tool, input, decision, danger, over] of TABLE)
    it(`${decision}: ${label}`, () => {
      const e = evaluate(mode, { callId: "c", name: tool, input }, settings(over));
      expect(e.decision).toBe(decision);
      expect(e.danger).toEqual(danger);
    });

  it("a phone's apps are the person's; an emulator's install is an ordinary request", () => {
    expect(DEFAULT_POLICY.humanOnly).toContain(DEVICE_PHONE_APP);
    expect(DEFAULT_POLICY.humanOnly).not.toContain(DEVICE_INSTALL);
  });
});
