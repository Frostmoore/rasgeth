// @vitest-environment jsdom
// 3.12.4: Settings > Messages: the contacts, the requests with a ready reply (send, edit, refuse),
// and the guides that connect WhatsApp Business and a Telegram bot, each step checked.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
let remoteOk = false;
let tokenOk = true;
// biome-ignore lint/suspicious/noExplicitAny: a stand-in for the whole API
const fakeApi: any = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        switch (name) {
          case "secretaryAccounts":
            return Promise.resolve({ accounts: [] });
          case "secretaryContacts":
            return Promise.resolve({
              contacts: [
                {
                  id: "c1",
                  accountId: "a1",
                  channel: "whatsapp",
                  handle: "393331112222",
                  name: "Luca",
                  notes: "",
                  paused: false,
                  stopped: false,
                  unread: 2,
                  lastAt: null,
                  lastText: "Can you fix my car?",
                  windowOpen: true,
                  pending: 1,
                },
              ],
              pending: [
                {
                  id: "p1",
                  contactId: "c1",
                  contactName: "Luca",
                  channel: "whatsapp",
                  reason: "commitment",
                  summary: "Wants a table for 4 on Friday",
                  draft: "Friday at 8 is fine.",
                  status: "open",
                  createdAt: "x",
                },
              ],
            });
          case "secretaryCheck": {
            const b = args[0] as { step: string };
            if (b.step === "remote")
              return Promise.resolve(
                remoteOk
                  ? { ok: true, code: "ok", detail: "https://rg.example.test" }
                  : { ok: false, code: "no_remote" },
              );
            return Promise.resolve(
              tokenOk
                ? { ok: true, code: "ok", number: "+39 333 1234567", verifiedName: "Salone" }
                : { ok: false, code: "bad_token" },
            );
          }
          default:
            return Promise.resolve({});
        }
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => {
  const real = await orig<typeof import("../src/state.js")>();
  real.agents.value = [
    { id: "g", kind: "god", name: "Zeus" } as never,
    { id: "s1", kind: "demigod", name: "Secretary" } as never,
  ];
  return {
    ...real,
    getApi: () => fakeApi,
    getLive: () => ({ send: () => {} }),
    refresh: () => Promise.resolve(),
  };
});

const { Secretary } = await import("../src/components/Secretary.js");

beforeEach(() => {
  calls.length = 0;
  remoteOk = false;
  tokenOk = true;
  lang.value = "en";
});
afterEach(cleanup);

describe("Settings > Messages", () => {
  it("shows the requests with a ready reply: send as it is, edited, or refuse", async () => {
    const ui = render(<Secretary />);
    await waitFor(() => expect(ui.getByText("Wants a table for 4 on Friday")).toBeTruthy());
    expect(ui.getByText("Luca", { selector: ".sc-contact-text b" })).toBeTruthy();
    const box = ui.container.querySelector("textarea") as HTMLTextAreaElement;
    expect(box.value).toBe("Friday at 8 is fine.");
    fireEvent.click(ui.getByText("Send"));
    await waitFor(() => expect(calls.some(([n]) => n === "secretaryApprove")).toBe(true));
    expect(calls.find(([n]) => n === "secretaryApprove")?.[1]).toEqual(["p1", undefined]);
    fireEvent.input(box, { target: { value: "Friday at 9." } });
    fireEvent.click(ui.getByText("Send my version"));
    await waitFor(() =>
      expect(calls.filter(([n]) => n === "secretaryApprove").at(-1)?.[1]).toEqual([
        "p1",
        "Friday at 9.",
      ]),
    );
    fireEvent.click(ui.getByText("Refuse"));
    await waitFor(() => expect(calls.some(([n]) => n === "secretaryRefuse")).toBe(true));
  });

  it("the WhatsApp guide stops at remote access and says where to set it", async () => {
    const ui = render(<Secretary />);
    fireEvent.click(await ui.findByText("Connect WhatsApp Business"));
    await waitFor(() => expect(document.body.textContent).toContain("Remote access is not set up"));
    expect(document.body.textContent).toContain("Open Remote access");
    expect(calls.some(([n]) => n === "secretaryStartWhatsApp")).toBe(false);
  });

  it("the WhatsApp guide moves on when the checks pass, and a wrong token stays on its step", async () => {
    remoteOk = true;
    const ui = render(<Secretary />);
    fireEvent.click(await ui.findByText("Connect WhatsApp Business"));
    await waitFor(() => expect(document.body.textContent).toContain("Reachable from outside"));
    await waitFor(() => expect(document.body.textContent).toContain("Open Meta for Developers"), {
      timeout: 3000,
    });
    fireEvent.click(document.body.querySelector(".sc-step.cur .wz-btn.primary") as HTMLElement);
    const id = document.body.querySelector(".sc-step.cur input") as HTMLInputElement;
    fireEvent.input(id, { target: { value: "1055555555" } });
    fireEvent.click(document.body.querySelector(".sc-step.cur .wz-btn.primary") as HTMLElement);
    tokenOk = false;
    const token = document.body.querySelector(".sc-step.cur input") as HTMLInputElement;
    fireEvent.input(token, { target: { value: "x".repeat(30) } });
    fireEvent.click(document.body.querySelector(".sc-step.cur .wz-btn.primary") as HTMLElement);
    await waitFor(() =>
      expect(document.body.textContent).toContain("The token is wrong or expired"),
    );
    tokenOk = true;
    fireEvent.click(document.body.querySelector(".sc-step.cur .wz-btn.primary") as HTMLElement);
    await waitFor(() => expect(document.body.textContent).toContain("The app's secret"));
    expect(document.body.textContent).toContain("32 letters and digits");
  });

  it("speaks Italian too, and the guide has no emoji or native controls", async () => {
    lang.value = "it";
    const ui = render(<Secretary />);
    expect(await ui.findByText("Collega WhatsApp Business")).toBeTruthy();
    expect(ui.getByText("Collega un bot Telegram")).toBeTruthy();
    expect(ui.container.querySelectorAll('input[type="checkbox"],input[type="radio"]').length).toBe(
      0,
    );
  });
});
