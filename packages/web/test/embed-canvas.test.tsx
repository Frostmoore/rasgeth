// @vitest-environment jsdom
// G42.6: the Canvas inside RGCompanion. Every viewer kind opens bare (no head of the page) and its
// head's buttons go to the app as data (`bar`), done here when the app says (`action`); the embed is
// one tab of the app's Canvas: another tab is the app's to open (`open`), an open copy stays in its
// tab, nothing is saved for the page's own reopening; an agent that looks reads the app's tabs with
// this tab's place (`tabs`), and an agent's move reaches only the tab it is for.
import { cleanup, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("../src/api.js", async (orig) => {
  const real = await orig<typeof import("../src/api.js")>();
  class Api {
    constructor() {
      // biome-ignore lint/correctness/noConstructorReturn: a stand-in for the whole API
      return new Proxy(
        {},
        {
          get:
            (_t, name) =>
            async (...args: unknown[]) => {
              if (name === "canvasLink") {
                const target = args[0] as { path?: string };
                return {
                  url: `/preview/T/${target.path ?? ""}`,
                  folder: target.path === "site",
                  artifact: target.path === "artefatti/conti.html",
                };
              }
              if (name === "canvasVersion") return { version: 1 };
              if (name === "editorCopy") return { copy: null };
              if (name === "artifactState") return { pendingRun: false };
              if (name === "fileReport") return null;
              return [];
            },
        },
      );
    }
  }
  class Live {
    send() {}
    close() {}
  }
  return { ...real, Api, Live };
});

const embed = await import("../src/embed.js");
const { EmbedRoot, embedTab } = await import("../src/components/Embed.js");
const state = await import("../src/state.js");
const live = await import("../src/viewers/live.js");
const { lang } = await import("../src/i18n.js");

const NONCE = "n0nce-n0nce_n0nce";
const sent: { rg: string; n: string; m: { t: string } & Record<string, unknown> }[] = [];
const of = (t: string) => sent.filter((s) => s.m.t === t).map((s) => s.m);

beforeEach(() => {
  sent.length = 0;
  localStorage.clear();
  lang.value = "it";
  (window as unknown as Record<string, unknown>).RGEmbed = {
    postMessage: (s: string) => sent.push(JSON.parse(s)),
  };
});
afterEach(() => {
  cleanup();
  embed.resetEmbed();
  state.sideViews.value = [];
  delete (window as unknown as Record<string, unknown>).RGEmbed;
});

const open = (scope: string, path: string) => {
  history.replaceState(
    null,
    "",
    `/embed.html#token=t&embed=canvas&bridge=${NONCE}&scope=${scope}&path=${encodeURIComponent(path)}&theme=dark&lang=it`,
  );
  const p = embed.takeEmbed();
  if (!p) throw new Error("no embed");
  return p;
};

describe("every viewer kind, bare, with its bar sent to the app", () => {
  // One file for each ViewerKind of viewers/kind.ts.
  const files = [
    "clip.mp4",
    "voice.mp3",
    "photo.png",
    "report.pdf",
    "README.md",
    "main.ts",
    "notes.txt",
    "data.csv",
    "budget.xlsx",
    "letter.docx",
    "deck.pptx",
    "chair.glb",
    "bundle.zip",
    "font.ttf",
    "config.json",
    "site",
    "layers.ora",
    "blob.bin",
  ];
  it.each(files)("%s", async (path) => {
    const p = open("p1", path);
    const r = render(<EmbedRoot params={p} />);
    await waitFor(() => expect(of("title")).toContainEqual({ t: "title", name: path }));
    type Bar = { actions: { id: string }[]; link?: string; download?: boolean };
    const last = () => of("bar").at(-1) as Bar | undefined;
    await waitFor(() => expect(last()?.link).toMatch(new RegExp(`^/preview/T/${path}\\?v=\\d+-0$`)));
    // The page's head is not there: the frame is the app's.
    expect(r.container.querySelector(".canvas-head:not([hidden])")).toBeNull();
    expect(r.container.querySelector(".canvas.canvas-bare")).toBeTruthy();
    expect(last()?.actions.map((a) => a.id)).toContain("keys");
    expect(last()?.download).toBe(path !== "site");
    // The embed's one tab is the page's Canvas's only one.
    expect(state.sideViews.value.map((v) => v.id)).toEqual([
      state.canvasViewId({ kind: "file", scope: "p1", path }),
    ]);
  });

  it("an artifact's «App» and «Source» are the bar's, and the app's action switches them", async () => {
    const p = open("p1", "artefatti/conti.html");
    render(<EmbedRoot params={p} />);
    await waitFor(() =>
      expect((of("bar").at(-1) as { actions: { id: string }[] }).actions.map((a) => a.id)).toEqual([
        "art.app",
        "art.source",
        "art.project",
        "keys",
      ]),
    );
    const on = () =>
      (of("bar").at(-1) as { actions: { id: string; on?: boolean }[] }).actions
        .filter((a) => a.on)
        .map((a) => a.id);
    expect(on()).toEqual(["art.app"]);
    expect(embed.handleAppInput({ t: "action", id: "art.source" })).toBe(true);
    await waitFor(() => expect(on()).toEqual(["art.source"]));
    expect(embed.handleAppInput({ t: "action", id: "nothing.here" })).toBe(false);
  });
});

describe("one tab of the app's Canvas", () => {
  it("another tab is the app's to open; nothing is saved for the page's reopening", () => {
    open("p1", "a.pdf");
    const own = { kind: "file" as const, scope: "p1", path: "a.pdf" };
    const id = embedTab("a.pdf", own);
    const other = { kind: "file" as const, scope: "p1", path: "b.odt" };
    expect(state.openCanvas("b.odt", other)).toBe(state.canvasViewId(other));
    expect(of("open")).toEqual([{ t: "open", title: "b.odt", target: other }]);
    expect(state.sideViews.value.map((v) => v.id)).toEqual([id]);
    // The own tab, given another file (an open copy): in place, under its name.
    state.retargetCanvas(id, { kind: "file", scope: "p1", path: "a.pdf.open/a.odg" });
    expect(state.sideViews.value).toHaveLength(1);
    expect(of("open")).toHaveLength(1);
    expect(localStorage.getItem("rg.canvas")).toBeNull();
  });

  it("an agent that looks reads the app's tabs, this tab's place, in view when the app says", () => {
    open("p1", "a.pdf");
    const own = { kind: "file" as const, scope: "p1", path: "a.pdf" };
    const port = { kind: "port" as const, agentId: "a1", port: 5173 };
    const id = embedTab("a.pdf", own);
    live.setTabKind(id, "pdf");
    live.report(id, { page: 2, pages: 5 });
    // Before the app says: this tab only.
    expect(state.canvasSnapshot()).toEqual({
      visible: true,
      tabs: [{ title: "a.pdf", target: own, active: true, kind: "pdf", place: { page: 2, pages: 5 } }],
    });
    embed.handleAppInput({
      t: "tabs",
      visible: true,
      tabs: [
        { title: "Il sito", target: port, active: false },
        { title: "a.pdf", target: own, active: true },
      ],
    });
    expect(state.canvasSnapshot()).toEqual({
      visible: true,
      tabs: [
        { title: "Il sito", target: port, active: false },
        { title: "a.pdf", target: own, active: true, kind: "pdf", place: { page: 2, pages: 5 } },
      ],
    });
    // Behind the chat, or another tab in front: not in view.
    embed.handleAppInput({ t: "tabs", visible: false, tabs: [] });
    expect(state.canvasSnapshot()).toEqual({ visible: false, tabs: [] });
    live.forgetTab(id);
  });

  it("an agent's move reaches the tab it is for; a show is the app's", () => {
    open("p1", "a.pdf");
    const own = { kind: "file" as const, scope: "p1", path: "a.pdf" };
    const id = embedTab("a.pdf", own);
    const ev = (seq: number, type: string, target: unknown) =>
      ({
        type: "canvas.open",
        sessionId: "s9",
        event: { seq, ts: "", sessionId: "s9", type, payload: { title: "x", target, do: { page: 3 } } },
      }) as unknown as Parameters<typeof state.applyMessage>[0];
    state.applyMessage(ev(1, "canvas.act", own));
    expect(live.orders.value.get(id)?.do).toEqual({ page: 3 });
    state.applyMessage(ev(2, "canvas.act", { kind: "file", scope: "p1", path: "b.pdf" }));
    state.applyMessage(ev(3, "canvas.show", { kind: "file", scope: "p1", path: "c.pdf" }));
    expect(state.sideViews.value.map((v) => v.id)).toEqual([id]);
    expect(of("open")).toEqual([]);
    live.forgetTab(id);
  });

  it("the bar is sent once per change, its actions run by id", () => {
    open("p1", "a.pdf");
    const runs: string[] = [];
    const bar = (label: string) => ({
      actions: [{ id: "keys", label, icon: "keyboard" as const, run: () => runs.push(label) }],
      link: "/preview/T/a.pdf?v=1-0",
      download: true,
    });
    embed.setEmbedBar(bar("Scorciatoie"));
    embed.setEmbedBar(bar("Scorciatoie"));
    expect(of("bar")).toHaveLength(1);
    embed.setEmbedBar(bar("Tasti"));
    expect(of("bar")).toHaveLength(2);
    expect(embed.runEmbedAction("keys")).toBe(true);
    expect(runs).toEqual(["Tasti"]);
  });
});
