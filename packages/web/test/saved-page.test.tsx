// @vitest-environment jsdom
// G40.14: «Salva» a part of a message (next to «Rispondi a questo») or a whole one, with a note
// and tags; «Salvati» lists them newest first, searches, filters, opens the conversation at the
// passage, edits the note and deletes only after our own confirmation (never the browser's).
import type { Event, SavedItem } from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const item = (id: string, extra: Partial<SavedItem> = {}): SavedItem => ({
  id,
  text: "First A",
  markdown: "First **A**",
  whole: false,
  note: "",
  tags: [],
  source: {
    kind: "session",
    sessionId: "s1",
    seq: 2,
    start: 6,
    end: 13,
    agentId: "god",
    agentName: "God",
    title: "Il piano",
    messageAt: "2026-11-15T10:00:00.000Z",
  },
  createdAt: "2026-11-16T09:00:00.000Z",
  updatedAt: "2026-11-16T09:00:00.000Z",
  ...extra,
});
let items: SavedItem[] = [];
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "savedList") {
          const q = (args[0] ?? {}) as { q?: string; tag?: string };
          const shown = items.filter(
            (i) =>
              (!q.q || `${i.text} ${i.note}`.includes(q.q)) && (!q.tag || i.tags.includes(q.tag)),
          );
          return Promise.resolve({
            items: shown,
            more: false,
            tags: [{ tag: "piano", count: 1 }],
            agents: [
              { id: "god", name: "God", count: 2 },
              { id: "chat", name: "Chat", count: 1 },
            ],
          });
        }
        if (name === "saveItem") return Promise.resolve(item("sav_new"));
        if (name === "updateSaved")
          return Promise.resolve({ ...item("sav_1"), ...(args[1] as object) });
        if (name === "exportSaved") return Promise.resolve(new Blob(["# Salvati"]));
        return Promise.resolve({ ok: true });
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getLive: () => ({ send: () => {} }),
  getApi: () => fakeApi,
}));

const state = await import("../src/state.js");
const { Chat } = await import("../src/components/Chat.js");
const { SavedPage, SaveDialogHost, saveDraft } = await import("../src/components/Saved.js");
const { Dialogs } = await import("../src/components/dialogs.js");
const { fragmentMarkdown } = await import("../src/saved-markdown.js");

let seq = 0;
const ev = (type: string, payload: unknown): Event =>
  ({
    id: `e${++seq}`,
    seq,
    ts: new Date(Date.UTC(2026, 10, 15, 10, 0, seq)).toISOString(),
    ownerId: "me",
    projectId: null,
    agentId: "god",
    sessionId: "s1",
    type,
    payload,
    hash: "",
    prevHash: "",
  }) as unknown as Event;
const said = (text: string) =>
  ev("message.assistant", {
    parts: [{ type: "text", text }],
    metrics: {
      inputTokens: 1,
      outputTokens: 1,
      cachedReadTokens: 0,
      cacheWriteTokens: 0,
      contextUsed: 2,
      contextWindow: 100000,
      startedAt: "2026-11-15T10:00:00.000Z",
      source: "server",
    },
    costUsd: 0,
    provider: "fake",
    model: "m",
    stopReason: "end_turn",
  });

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  items = [];
  seq = 0;
  saveDraft.value = null;
  state.pendingJump.value = null;
  state.sessionRows.value = [];
  state.approvals.value = [];
  state.subPath.value = {};
  state.agents.value = [{ id: "god", name: "God", kind: "god" }] as never;
  Element.prototype.scrollIntoView = vi.fn();
});
afterEach(() => cleanup());

const withDialogs = (node: preact.ComponentChildren) =>
  render(
    <>
      {node}
      <SaveDialogHost />
      <Dialogs />
    </>,
  );

describe("the Markdown of a selection", () => {
  it("keeps emphasis, code, links, lists, headings and tables", () => {
    const box = document.createElement("div");
    box.innerHTML =
      '<h2>Plan</h2><p>First <strong>A</strong>, then <a href="https://b.example">B</a> and <code>c()</code>.</p>' +
      '<ul><li>one</li><li>two</li></ul><pre><code class="language-js">x = 1\n</code></pre>' +
      "<table><tr><th>k</th><th>v</th></tr><tr><td>a</td><td>1</td></tr></table>" +
      '<button class="copy-code">Copia</button>';
    expect(fragmentMarkdown(box)).toBe(
      "## Plan\n\nFirst **A**, then [B](https://b.example) and `c()`.\n\n- one\n- two\n\n" +
        "```js\nx = 1\n```\n\n| k | v |\n| --- | --- |\n| a | 1 |",
    );
  });
});

describe("«Salva» in the chat (G40.14)", () => {
  it("offers «Salva» next to «Rispondi a questo» and saves the passage with a note and tags", async () => {
    const a = said("Plan: **first A**, then B.");
    state.sessionView("s1").value = {
      events: [ev("message.user", { text: "plan?" }), a],
      text: "",
      thinking: "",
      state: "idle",
      synced: true,
    };
    const r = withDialogs(<Chat sessionId="s1" agentId="god" />);
    const bubble = r.container.querySelector(".bubble.assistant") as HTMLElement;
    expect(bubble.dataset.seq).toBe(String(a.seq));
    const strong = bubble.querySelector("strong") as HTMLElement;
    const range = document.createRange();
    range.selectNodeContents(strong);
    Range.prototype.getBoundingClientRect = () => new DOMRect(40, 40, 60, 16);
    window.getSelection()?.removeAllRanges();
    window.getSelection()?.addRange(range);
    await act(async () => {
      document.dispatchEvent(new globalThis.Event("selectionchange"));
      await new Promise((res) => setTimeout(res, 250));
    });
    expect(r.getByText("Rispondi a questo")).toBeTruthy();
    const pops = r.container.querySelectorAll(".quote-pops .quote-pop");
    expect([...pops].map((b) => b.textContent)).toEqual(["Rispondi a questo", "Salva"]);
    fireEvent.click(pops[1] as HTMLElement);
    await waitFor(() => r.getByText("Salva questo passaggio"));
    fireEvent.input(document.querySelector(".saved-dialog textarea") as HTMLElement, {
      target: { value: "da ricordare" },
    });
    fireEvent.input(document.querySelector(".saved-tags-edit input") as HTMLElement, {
      target: { value: "piano, #Idee" },
    });
    fireEvent.click(document.querySelector(".ui-modal .wz-btn.primary") as HTMLElement);
    await waitFor(() => r.getByText("È nei tuoi Salvati, con la conversazione da cui viene."));
    expect(calls.find(([n]) => n === "saveItem")?.[1]).toEqual([
      {
        source: { kind: "session", sessionId: "s1", seq: a.seq, start: 6, end: 13 },
        text: "first A",
        markdown: "**first A**",
        note: "da ricordare",
        tags: ["piano", "Idee"],
      },
    ]);
    expect(
      r.container.querySelectorAll('input[type="checkbox"], input[type="radio"]'),
    ).toHaveLength(0);
  });

  it("saves a whole message from its menu", async () => {
    const a = said("All of it.");
    state.sessionView("s1").value = {
      events: [ev("message.user", { text: "x" }), a],
      text: "",
      thinking: "",
      state: "idle",
      synced: true,
    };
    const r = withDialogs(<Chat sessionId="s1" agentId="god" />);
    fireEvent.click(
      r.container.querySelector(
        ".msg-actions:not(.user-actions) .msg-action:last-child",
      ) as HTMLElement,
    );
    await waitFor(() => r.getByText("Salva questo messaggio"));
    expect(document.querySelector(".saved-preview")?.textContent).toBe("All of it.");
    fireEvent.click(document.querySelector(".ui-modal .wz-btn.primary") as HTMLElement);
    await waitFor(() => expect(calls.some(([n]) => n === "saveItem")).toBe(true));
    expect(calls.find(([n]) => n === "saveItem")?.[1]).toEqual([
      { source: { kind: "session", sessionId: "s1", seq: a.seq } },
    ]);
  });
});

describe("«Salvati» (G40.14)", () => {
  it("lists, searches, filters, opens at the passage, edits and deletes after our confirmation", async () => {
    const confirm = vi.spyOn(window, "confirm");
    items = [
      item("sav_1", { note: "il primo passo", tags: ["piano"] }),
      item("sav_2", {
        text: "Tutto",
        markdown: null,
        whole: true,
        source: {
          kind: "chat",
          chatId: "c1",
          messageId: 4,
          agentId: null,
          agentName: null,
          title: "Ricette",
          messageAt: null,
        },
      }),
    ];
    const r = withDialogs(<SavedPage />);
    await waitFor(() => r.getByText("il primo passo"));
    expect(r.container.querySelectorAll(".saved-card")).toHaveLength(2);
    expect(r.container.textContent).toContain("Il piano · God");
    expect(r.container.querySelector(".saved-card .md strong")?.textContent).toBe("A");
    expect(r.container.textContent).toContain("Messaggio intero");

    // Search (after a short pause) and a tag.
    fireEvent.input(r.getByPlaceholderText("Cerca nei Salvati"), { target: { value: "primo" } });
    await waitFor(() =>
      expect(
        calls.some(([n, a]) => n === "savedList" && (a[0] as { q?: string }).q === "primo"),
      ).toBe(true),
    );
    await waitFor(() => expect(r.container.querySelectorAll(".saved-card")).toHaveLength(1));
    fireEvent.input(r.getByPlaceholderText("Cerca nei Salvati"), { target: { value: "" } });
    await waitFor(() => expect(r.container.querySelectorAll(".saved-card")).toHaveLength(2));
    fireEvent.click(r.container.querySelector(".saved-filter .pick-tile") as HTMLElement);
    await waitFor(() =>
      expect(
        calls.some(([n, a]) => n === "savedList" && (a[0] as { tag?: string }).tag === "piano"),
      ).toBe(true),
    );
    fireEvent.click(r.container.querySelector(".saved-filter .pick-tile") as HTMLElement);
    await waitFor(() => expect(r.container.querySelectorAll(".saved-card")).toHaveLength(2));

    // Open: the conversation's tab, and the passage to light up once it shows.
    fireEvent.click(r.getAllByText("Apri nella conversazione")[0] as HTMLElement);
    expect(state.tabs.value.some((t) => t.id === "chat:s1")).toBe(true);
    expect(state.pendingJump.value).toEqual({
      sessionId: "s1",
      seq: 2,
      start: 6,
      end: 13,
      text: "First A",
    });

    // Edit the note.
    fireEvent.click(r.getAllByText("Modifica nota ed etichette")[0] as HTMLElement);
    fireEvent.input(r.container.querySelector(".saved-edit textarea") as HTMLElement, {
      target: { value: "cambiata" },
    });
    fireEvent.click(r.getByText("Salva"));
    await waitFor(() => r.getByText("cambiata"));
    expect(calls.find(([n]) => n === "updateSaved")?.[1]).toEqual([
      "sav_1",
      { note: "cambiata", tags: ["piano"] },
    ]);

    // Delete: only after our own window says yes.
    fireEvent.click(r.getAllByText("Elimina")[1] as HTMLElement);
    await waitFor(() => r.getByText("Eliminare questo salvato?"));
    expect(calls.some(([n]) => n === "deleteSaved")).toBe(false);
    fireEvent.click(r.getAllByText("Elimina").at(-1) as HTMLElement);
    await waitFor(() => expect(calls.find(([n]) => n === "deleteSaved")?.[1]).toEqual(["sav_2"]));
    await waitFor(() => expect(r.container.querySelectorAll(".saved-card")).toHaveLength(1));
    expect(confirm).not.toHaveBeenCalled();
  });

  it("says when there is nothing yet", async () => {
    const r = withDialogs(<SavedPage />);
    await waitFor(() => r.getByText("Non hai ancora salvato niente."));
  });
});
