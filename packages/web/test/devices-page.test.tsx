// @vitest-environment jsdom
// G40.1: Settings › Devices. The page lists the devices with their platform, last use and where
// from, never a token; renaming goes through our text window, revoking only after our own
// confirmation (never the browser's dialogs, no native checkboxes); every text in both languages.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const pixel = {
  id: "dev_1",
  name: "Pixel 8",
  platform: "android",
  createdAt: "2026-11-15T09:00:00Z",
  lastUsedAt: "2026-11-15T10:00:00Z",
  lastAddress: "192.168.1.20",
  current: false,
};
const mac = {
  id: "dev_2",
  name: "Mac di casa",
  platform: "macos",
  createdAt: "2026-11-15T09:00:00Z",
  lastUsedAt: null,
  lastAddress: null,
};
let list: unknown[] = [];
let testAnswer: unknown = { ok: true };
const webpush = {
  kind: "webpush",
  registeredAt: "2026-11-15T09:00:00Z",
  target: "ntfy.sh",
  lastSentAt: null,
  lastError: null,
};
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "devices") return Promise.resolve(list);
        if (name === "renameDevice") return Promise.resolve({ ...pixel, name: args[1] });
        if (name === "testDevicePush") return Promise.resolve(testAnswer);
        return Promise.resolve({ ok: true });
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { Devices } = await import("../src/components/Devices.js");
const { Dialogs } = await import("../src/components/dialogs.js");
const { t } = await import("../src/i18n.js");

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  list = [pixel, mac];
  testAnswer = { ok: true };
});
afterEach(() => cleanup());

const page = () =>
  render(
    <>
      <Devices />
      <Dialogs />
    </>,
  );

describe("Settings › Devices (G40.1)", () => {
  it("lists the devices: platform, last use and where from, never a token", async () => {
    const r = page();
    await waitFor(() => r.getByText("Pixel 8"));
    const text = r.container.textContent ?? "";
    expect(text).toContain("I tuoi dispositivi");
    expect(text).toContain("Android");
    expect(text).toContain("da 192.168.1.20");
    expect(text).toContain("macOS · mai usato");
    expect(text).not.toMatch(/rgd_|token/i);
    expect(
      r.container.querySelectorAll('input[type="checkbox"], input[type="radio"]'),
    ).toHaveLength(0);
  });

  it("names the device asking", async () => {
    list = [{ ...pixel, current: true }];
    const r = page();
    await waitFor(() => r.getByText("questo dispositivo"));
  });

  it("says what to do when there is none", async () => {
    list = [];
    const r = page();
    await waitFor(() => r.getByText(t("dvNone")));
  });

  it("renames in our window", async () => {
    const r = page();
    await waitFor(() => r.getByText("Pixel 8"));
    fireEvent.click(r.getAllByText("Rinomina")[0] as HTMLElement);
    await waitFor(() => r.getByText("Un nome nuovo per «Pixel 8»"));
    const input = document.querySelector(".ui-modal input") as HTMLInputElement;
    fireEvent.input(input, { target: { value: "Telefono" } });
    fireEvent.click(r.getAllByText("Rinomina").at(-1) as HTMLElement);
    await waitFor(() =>
      expect(calls.find(([n]) => n === "renameDevice")?.[1]).toEqual(["dev_1", "Telefono"]),
    );
  });

  it("revokes only after our confirmation", async () => {
    const confirm = vi.spyOn(window, "confirm");
    const r = page();
    await waitFor(() => r.getByText("Pixel 8"));
    fireEvent.click(r.getAllByText("Revoca")[0] as HTMLElement);
    await waitFor(() => r.getByText("Revocare «Pixel 8»?"));
    expect(r.container.textContent).toContain(t("dvRevokeText"));
    expect(calls.some(([n]) => n === "revokeDevice")).toBe(false);
    fireEvent.click(r.getAllByText("Revoca").at(-1) as HTMLElement);
    await waitFor(() => expect(calls.find(([n]) => n === "revokeDevice")?.[1]).toEqual(["dev_1"]));
    await waitFor(() => r.getByText("«Pixel 8» revocato."));
    expect(confirm).not.toHaveBeenCalled();
  });

  it("says where each device's notifications go, and sends a test (G40.4)", async () => {
    list = [
      { ...pixel, push: webpush },
      { ...mac, push: null },
      {
        ...mac,
        id: "dev_3",
        name: "iPhone",
        platform: "ios",
        push: { ...webpush, kind: "apns", target: "APNs", blocked: "relay_off" },
      },
    ];
    const r = page();
    await waitFor(() => r.getByText("Notifiche tramite ntfy.sh"));
    const text = r.container.textContent ?? "";
    expect(text).toContain(t("dvPushNone"));
    expect(text).toContain(t("dvPushRelayOff"));
    // Only a device whose notifications can go is offered a test.
    expect(r.getAllByText("Manda una prova")).toHaveLength(1);
    fireEvent.click(r.getByText("Manda una prova"));
    await waitFor(() => r.getByText("Prova mandata a «Pixel 8»: tra poco dovrebbe comparire lì."));
    expect(calls.find(([n]) => n === "testDevicePush")?.[1]).toEqual(["dev_1"]);

    testAnswer = { ok: false, error: "HTTP 500", gone: false };
    fireEvent.click(r.getByText("Manda una prova"));
    await waitFor(() => r.getByText("La prova non è arrivata a «Pixel 8»: HTTP 500."));
  });

  it("shows the last failure of a device's notifications", async () => {
    list = [{ ...pixel, push: { ...webpush, lastError: "timed out" } }];
    const r = page();
    await waitFor(() =>
      r.getByText("Notifiche tramite ntfy.sh · l'ultima non è arrivata (timed out)"),
    );
  });

  it("every text is there in both languages", () => {
    for (const l of ["it", "en"] as const) {
      lang.value = l;
      for (const k of [
        "dvSection",
        "dvQ",
        "dvLead",
        "dvNone",
        "dvRevokeQ",
        "dvRevokeText",
        "dvKeysNote",
        "dvPlatform_android",
        "dvPlatform_ios",
        "dvPlatform_windows",
        "dvPlatform_macos",
        "dvPlatform_linux",
        "dvPlatform_other",
        "dvPushNone",
        "dvPushOn",
        "dvPushLast",
        "dvPushFailed",
        "dvPushRelayOff",
        "dvPushLocked",
        "dvPushTest",
        "dvPushTestOk",
        "dvPushTestFailed",
        "dvPushTestGone",
      ])
        expect(t(k as never)).not.toBe(k);
    }
    lang.value = "en";
    expect(t("dvRevokeQ", { name: "Mac" })).toBe("Revoke «Mac»?");
  });
});
