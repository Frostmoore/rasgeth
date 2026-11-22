// @vitest-environment jsdom
// 3.11 phase 2: a device live on the right. A pointer's path becomes a tap, a press held or a
// swipe; the screen watches its device, shows its frames, sends gestures only while the person has
// control, and the phone's buttons are drawn ones (no emoji, no native controls); words in it/en.
import { cleanup, fireEvent, render } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const sent: unknown[] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getLive: () => ({ send: (m: unknown) => sent.push(m) }),
}));
const { DeviceScreen, gesture } = await import("../src/components/DeviceScreen.js");
const { deviceScreens, applyMessage } = await import("../src/state.js");

beforeEach(() => {
  sent.length = 0;
  lang.value = "en";
  deviceScreens.value = {};
});
afterEach(cleanup);

describe("a device's screen", () => {
  it.each([
    [{ x: 0.5, y: 0.5 }, { x: 0.505, y: 0.5 }, 120, { kind: "tap", x: 0.5, y: 0.5 }],
    [{ x: 0.5, y: 0.5 }, { x: 0.5, y: 0.5 }, 900, { kind: "long", x: 0.5, y: 0.5, ms: 900 }],
    [
      { x: 0.5, y: 0.8 },
      { x: 0.5, y: 0.3 },
      250,
      { kind: "swipe", x: 0.5, y: 0.8, x2: 0.5, y2: 0.3, ms: 250 },
    ],
    [
      { x: 0.1, y: 0.1 },
      { x: 0.9, y: 0.1 },
      10,
      { kind: "swipe", x: 0.1, y: 0.1, x2: 0.9, y2: 0.1, ms: 50 },
    ],
  ])("%o to %o in %i ms", (from, to, ms, want) => {
    expect(gesture(from, to, ms)).toEqual(want);
  });

  it("watches, shows frames, and sends gestures only once the person has control", async () => {
    const v = render(<DeviceScreen device="avd:Pixel_8" title="Pixel_8" />);
    expect(sent[0]).toEqual({ type: "device.watch", id: "avd:Pixel_8" });
    applyMessage({ type: "device.state", id: "avd:Pixel_8", state: "on", control: "agents" });
    applyMessage({
      type: "device.frame",
      id: "avd:Pixel_8",
      data: "AAAA",
      width: 576,
      height: 1280,
    });
    v.rerender(<DeviceScreen device="avd:Pixel_8" title="Pixel_8" />);
    expect(v.container.querySelector("img")?.getAttribute("src")).toBe(
      "data:image/jpeg;base64,AAAA",
    );
    expect(v.getByText(/you see what they do/)).toBeTruthy();
    const keys = v.container.querySelectorAll(".device-keys button");
    expect(keys).toHaveLength(4);
    expect([...keys].every((b) => (b as HTMLButtonElement).disabled)).toBe(true);
    fireEvent.click(v.getByText("Take control"));
    expect(sent.at(-1)).toEqual({ type: "device.control", id: "avd:Pixel_8", take: true });
    applyMessage({ type: "device.state", id: "avd:Pixel_8", state: "on", control: "person" });
    v.rerender(<DeviceScreen device="avd:Pixel_8" title="Pixel_8" />);
    fireEvent.click(v.getByLabelText("Home"));
    expect(sent.at(-1)).toEqual({
      type: "device.input",
      id: "avd:Pixel_8",
      event: { kind: "button", button: "home" },
    });
    fireEvent.keyDown(v.getByRole("img"), { key: "a" });
    expect(sent.at(-1)).toMatchObject({ event: { kind: "text", text: "a" } });
    fireEvent.keyDown(v.getByRole("img"), { key: "Enter" });
    expect(sent.at(-1)).toMatchObject({ event: { kind: "key", key: "Enter" } });
    expect(v.container.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
    cleanup();
    await vi.waitFor(() =>
      expect(sent).toContainEqual({ type: "device.unwatch", id: "avd:Pixel_8" }),
    );
  });

  it("says why it cannot be shown, in Italian too", () => {
    lang.value = "it";
    applyMessage({
      type: "device.state",
      id: "avd:X",
      state: "off",
      control: "agents",
      error: "At most 2 emulators run at once",
    });
    const v = render(<DeviceScreen device="avd:X" title="X" />);
    expect(v.getByText(/Non si può mostrare: At most 2/)).toBeTruthy();
    expect(v.getByText(/spento/)).toBeTruthy();
  });
});
