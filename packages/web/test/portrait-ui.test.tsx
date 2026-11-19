// @vitest-environment jsdom
// 3.9.4: Settings › Portrait («Mirror»): the traits grouped, each with how sure it is and where it
// comes from (its conversation opens), «Change», «Remove», «Not true»; the switch, who reads it,
// the text the agents read and «Forget everything» after our own confirm window. Words in it/en.
import type { PortraitView } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { dictionaries, lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const opened: unknown[] = [];
let view: PortraitView;
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "portrait") return Promise.resolve(view);
        return Promise.resolve({ ok: true });
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  openSession: (s: unknown) => opened.push(s),
}));

const { PortraitPage } = await import("../src/components/Portrait.js");
const { asking, Dialogs } = await import("../src/components/dialogs.js");
const { GROUPS } = await import("../src/components/Settings.js");

const trait = (over: Partial<PortraitView["traits"][number]>) => ({
  id: "t1",
  text: "Prefers short answers",
  category: "style" as const,
  confidence: 0.8,
  createdAt: "2026-11-10T10:00:00Z",
  updatedAt: "2026-11-10T10:00:00Z",
  seenAt: "2026-11-12T10:00:00Z",
  by: "auto",
  edited: false,
  confirmations: 2,
  sources: [
    {
      sessionId: "s1",
      agentId: "a1",
      at: "2026-11-12T10:00:00Z",
      sessionTitle: "Release notes",
      agentName: "God",
    },
  ],
  ...over,
});

beforeEach(() => {
  calls.length = 0;
  opened.length = 0;
  lang.value = "it";
  view = {
    on: true,
    agents: { god: true, orchestrators: true, chat: true, others: false },
    traits: [
      trait({}),
      trait({
        id: "t2",
        text: "Works on Rasgeth",
        category: "project",
        confidence: 0.4,
        confirmations: 0,
        sources: [],
      }),
      trait({ id: "t3", text: "Likes tea", category: "preference", edited: true, by: "human" }),
    ],
    text: "## The person's portrait\n\nHow to talk to them:\n- Prefers short answers",
    limit: 1600,
    denied: 1,
  };
});
afterEach(() => {
  cleanup();
  asking.value = [];
});

describe("Settings › Portrait (3.9.4)", () => {
  it("is a section of Settings, next to the shared memory", () => {
    const ids = GROUPS.flatMap((g) => g.sections.map((s) => s.id));
    expect(ids.indexOf("portrait")).toBe(ids.indexOf("memory") + 1);
  });

  it("shows the traits grouped, how sure, and where each comes from", async () => {
    const r = render(<PortraitPage />);
    await waitFor(() => r.getByText("Prefers short answers"));
    const titles = [...r.container.querySelectorAll(".pr-group-title")].map((h) => h.textContent);
    expect(titles).toEqual(["Preferenze", "Come parlarti", "Progetti in corso"]);
    expect(r.getByText("Scritto da te")).toBeTruthy();
    expect(r.getByText("Sicuro")).toBeTruthy();
    expect(r.getByText("Probabile")).toBeTruthy();
    expect(r.getByText(/1 tratto che hai detto non vero/)).toBeTruthy();
    // No native checkboxes or radios: our switches and chips only.
    expect(r.container.querySelector("input[type=checkbox], input[type=radio]")).toBeNull();
    // Where it comes from: the conversation opens.
    const item = r.container.querySelector('[data-trait="t1"]') as HTMLElement;
    fireEvent.click(item.querySelector(".mem-from") as HTMLElement);
    await waitFor(() => r.getByText("«Release notes»"));
    fireEvent.click(r.getByText("«Release notes»"));
    expect(opened).toEqual([{ id: "s1", agentId: "a1", title: "Release notes" }]);
  });

  it("removes, denies, changes, switches and forgets", async () => {
    const r = render(
      <>
        <PortraitPage />
        <Dialogs />
      </>,
    );
    await waitFor(() => r.getByText("Prefers short answers"));
    const item = () => r.container.querySelector('[data-trait="t1"]') as HTMLElement;
    const button = (el: HTMLElement, label: string) =>
      [...el.querySelectorAll("button")].find((b) => b.textContent === label) as HTMLElement;
    fireEvent.click(button(item(), "Non è vero"));
    await waitFor(() => expect(calls.some(([n]) => n === "denyTrait")).toBe(true));
    fireEvent.click(button(item(), "Togli"));
    await waitFor(() => expect(calls.some(([n]) => n === "removeTrait")).toBe(true));
    // Change: words and category, saved together.
    fireEvent.click(button(item(), "Cambia"));
    const area = await waitFor(
      () => document.querySelector(".mem-edit textarea") as HTMLTextAreaElement,
    );
    fireEvent.input(area, { target: { value: "Prefers very short answers" } });
    fireEvent.click(r.getByRole("button", { name: "Da evitare" }));
    fireEvent.click(r.getByRole("button", { name: "Salva" }));
    await waitFor(() =>
      expect(calls.find(([n]) => n === "editTrait")?.[1]).toEqual([
        "t1",
        { text: "Prefers very short answers", category: "avoid" },
      ]),
    );
    // Who reads it: one switch each.
    fireEvent.click(r.getByRole("switch", { name: "Tutti gli altri agenti" }));
    await waitFor(() =>
      expect(calls.find(([n]) => n === "setPortrait")?.[1]).toEqual([
        { agents: { god: true, orchestrators: true, chat: true, others: true } },
      ]),
    );
    // The text the agents read.
    fireEvent.click(r.getByText("Mostra il testo"));
    expect(r.container.querySelector(".pr-text")?.textContent).toContain("Prefers short answers");
    // Forget everything: asked in our window first.
    fireEvent.click(r.getAllByText("Dimentica tutto").at(-1) as HTMLElement);
    await waitFor(() => expect(asking.value).toHaveLength(1));
    expect(calls.some(([n]) => n === "forgetPortrait")).toBe(false);
  });

  it("has every word in both languages", () => {
    const keys = Object.keys(dictionaries.en).filter((k) => /^pr[A-Z]|^err_portrait/.test(k));
    expect(keys.length).toBeGreaterThan(50);
    for (const k of keys)
      expect(dictionaries.it[k as keyof typeof dictionaries.it], k).toBeTruthy();
  });
});
