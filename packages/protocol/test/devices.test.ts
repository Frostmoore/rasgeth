// Devices and the app's protocol (G40.1): the rules as tables.
import { describe, expect, it } from "vitest";
import {
  APP_PROTOCOL_VERSION,
  AppHello,
  answerVia,
  appVia,
  appViaName,
  type Credential,
  DeviceCreateBody,
  DeviceName,
  mayIssueDevice,
} from "../src/index.js";

describe("who may make a device token", () => {
  const rows: [Credential, boolean][] = [
    ["installation", true],
    ["session", true],
    // A device never makes another: a stolen token would outlive its revocation.
    ["device", false],
  ];
  it.each(rows)("%s → %s", (by, want) => expect(mayIssueDevice(by)).toBe(want));
});

describe("where an answer was given", () => {
  const rows: [string, Parameters<typeof answerVia>[0], string][] = [
    ["the page", {}, "web"],
    ["the editor (G38.6)", { claimed: "editor" }, "editor"],
    ["a device", { device: "Pixel 8" }, "app (Pixel 8)"],
    // A device cannot pass for the editor.
    ["a device claiming the editor", { device: "Mac", claimed: "editor" }, "app (Mac)"],
  ];
  it.each(rows)("%s", (_name, o, want) => expect(answerVia(o)).toBe(want));

  it("reads the device's name back, nothing else", () => {
    expect(appViaName(appVia("Telefono (lavoro)"))).toBe("Telefono (lavoro)");
    expect(appViaName("web")).toBeUndefined();
    expect(appViaName("telegram")).toBeUndefined();
    expect(appViaName(undefined)).toBeUndefined();
    expect(appViaName("app ()")).toBeUndefined();
  });
});

describe("the shapes", () => {
  it("names: trimmed, 1–60 characters, no control characters", () => {
    expect(DeviceName.parse("  Pixel 8  ")).toBe("Pixel 8");
    expect(DeviceName.safeParse("").success).toBe(false);
    expect(DeviceName.safeParse("a".repeat(61)).success).toBe(false);
    expect(DeviceName.safeParse("a\nb").success).toBe(false);
    expect(DeviceCreateBody.safeParse({ name: "x", platform: "android" }).success).toBe(true);
    expect(DeviceCreateBody.safeParse({ name: "x", platform: "palm" }).success).toBe(false);
  });

  it("the hello carries no personal field", () => {
    const hello = AppHello.parse({
      app: "redgiant",
      version: "3.8.0",
      appProtocol: APP_PROTOCOL_VERSION,
      protocolVersion: 2,
      machine: "redgiant",
      firstStartCompleted: true,
      access: { password: true, code: false, token: true },
      signedIn: false,
    });
    expect(Object.keys(hello).sort()).toEqual(
      [
        "access",
        "app",
        "appProtocol",
        "firstStartCompleted",
        "machine",
        "protocolVersion",
        "signedIn",
        "version",
      ].sort(),
    );
    expect(Number.isInteger(APP_PROTOCOL_VERSION)).toBe(true);
  });
});
