// @vitest-environment jsdom
// Echo (3.9.6): the search box over past conversations in the left bar, the same results as the
// agents' search_conversations, and the #conv: links an agent's answer carries.
import { cleanup, fireEvent, render, screen } from "@testing-library/preact";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const { api } = vi.hoisted(() => ({
  api: {} as Record<string, ReturnType<typeof vi.fn>>,
}));
vi.mock("../src/api.js", async (orig) => {
  const real = await orig<typeof import("../src/api.js")>();
  class Api {
    constructor() {
      // biome-ignore lint/correctness/noConstructorReturn: a stand-in for the whole API
      return new Proxy(
        {},
        { get: (_t, name) => (api as Record<string, unknown>)[name as string] ?? (async () => []) },
      );
    }
  }
  class Live {
    send() {}
    close() {}
  }
  return { ...real, Api, Live };
});

const hit = {
  sessionId: "sess_old",
  title: "Rounding of invoices",
  agentId: "coder",
  projectId: "demo",
  at: "2026-11-12T10:00:00.000Z",
  lastAt: "2026-11-12T11:00:00.000Z",
  matches: 3,
  archived: true,
  snippets: [
    {
      role: "person",
      at: "2026-11-12T10:00:00.000Z",
      text: "the invoices are wrong",
      marks: [[4, 12]],
    },
    {
      role: "agent",
      at: "2026-11-12T10:01:00.000Z",
      text: "fixed the invoices rounding",
      marks: [[10, 18]],
    },
  ],
};
const setUp = () => {
  Object.assign(api, {
    sessions: vi.fn(async () => []),
    chats: vi.fn(async () => []),
    setup: vi.fn(async () => ({ config: { completed: true, remote: true } })),
    searchConversations: vi.fn(async (q: string) => (q.includes("nothing") ? [] : [hit])),
  });
};
setUp();

const state = await import("../src/state.js");
const { Sidebar } = await import("../src/components/Sidebar.js");
const { renderAnswer } = await import("../src/markdown.js");
const { activeTab, agents, projects, sessionRows, tabs } = state;
beforeAll(async () => {
  await state.signIn("token").catch(() => {});
});
beforeEach(() => {
  lang.value = "it";
  localStorage.setItem("rg.remoteNotice", "hidden");
  tabs.value = [];
  activeTab.value = null;
  sessionRows.value = [];
  projects.value = [{ id: "demo", name: "Demo" }] as never;
  agents.value = [
    { id: "god", name: "God", kind: "god", status: "active" },
    { id: "coder", name: "Coder", kind: "agent", projectId: "demo", status: "active" },
  ] as never;
  setUp();
});
afterEach(() => cleanup());

describe("Echo in the left bar (3.9.6)", () => {
  it("searches past conversations and shows them in place of the lists, then opens one", async () => {
    render(<Sidebar />);
    const box = screen.getByLabelText("Cerca nelle conversazioni passate");
    expect(screen.getByText("God")).toBeTruthy();
    fireEvent.input(box, { target: { value: "i" } });
    expect(screen.getByText(/Scrivi almeno due lettere/)).toBeTruthy();
    expect(api.searchConversations).not.toHaveBeenCalled();
    fireEvent.input(box, { target: { value: "invoices" } });
    await vi.waitFor(() => expect(screen.getByText("Rounding of invoices")).toBeTruthy());
    expect(api.searchConversations).toHaveBeenCalledWith("invoices");
    // While a search is shown the bar's lists step aside.
    expect(screen.queryByText("Progetti")).toBe(null);
    expect(screen.getByText("Demo · Coder")).toBeTruthy();
    expect(screen.getByText("archiviato")).toBeTruthy();
    expect(screen.getByText("3 messaggi", { exact: false })).toBeTruthy();
    // The words found are marked from offsets (text, never HTML from the server).
    const marks = [...document.querySelectorAll(".echo-snippet mark")].map((m) => m.textContent);
    expect(marks).toEqual(["invoices", "invoices"]);
    expect(screen.getByText("Tu:")).toBeTruthy();
    fireEvent.click(screen.getByText("Rounding of invoices"));
    await vi.waitFor(() => expect(activeTab.value).toBe("chat:sess_old"));
  });

  it("says when nothing is found, and clearing brings the lists back", async () => {
    render(<Sidebar />);
    const box = screen.getByLabelText("Cerca nelle conversazioni passate");
    fireEvent.input(box, { target: { value: "nothing here" } });
    await vi.waitFor(() =>
      expect(screen.getByText("Nessuna conversazione passata ha queste parole.")).toBeTruthy(),
    );
    fireEvent.click(screen.getByTitle("Cancella la ricerca"));
    expect(screen.getByText("God")).toBeTruthy();
    expect(screen.queryByText("Nessuna conversazione passata ha queste parole.")).toBe(null);
  });

  it("opens a #conv: link of an agent's answer in its tab", async () => {
    sessionRows.value = [
      {
        id: "sess_old",
        agentId: "coder",
        projectId: "demo",
        createdAt: "2026-11-12T09:00:00.000Z",
        lastAt: "2026-11-12T11:00:00.000Z",
        title: "Rounding of invoices",
        pinned: false,
        archived: false,
        running: false,
      },
    ] as never;
    const box = document.createElement("div");
    box.innerHTML = renderAnswer("We did it in [Rounding of invoices](#conv:sess_old).");
    document.body.append(box);
    const link = box.querySelector("a");
    expect(link?.getAttribute("href")).toBe("#conv:sess_old");
    link?.click();
    await vi.waitFor(() => expect(activeTab.value).toBe("chat:sess_old"));
    box.remove();
  });
});
