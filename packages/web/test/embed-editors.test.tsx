// @vitest-environment jsdom
// G42.7: the editors inside RGCompanion. Text and code, PDF, SVG and layered pictures open bare
// (no head of the page) in their editor's shell; the save state goes to the app's bar (with why it
// failed); a selection in the text becomes «Ask the agent» in the app's bar and goes to the app's
// composer with its lines; the app's keys reach the editor even when the focus is nowhere in the
// page; the picture editor takes a picture pasted from the system's clipboard; an archived
// project's file opens in its viewer, said so in the page and in the app's bar.
import type { DocFile } from "@redgiant/protocol";
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
                return { url: `/preview/T/${target.path ?? ""}`, folder: false };
              }
              if (name === "projects")
                return [
                  { id: "p1", name: "Uno" },
                  { id: "old", name: "Vecchio", archivedAt: "2026-11-01T00:00:00.000Z" },
                ];
              if (name === "canvasVersion") return { version: 1 };
              if (name === "editorCopy") return { copy: null };
              if (name === "fileReport") return null;
              if (name === "editorSettings") return { settings: {} };
              if (name === "imageInfo") return { krita: false };
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

vi.mock("../src/state.js", async (orig) => {
  const real = await orig<typeof import("../src/state.js")>();
  return {
    ...real,
    signIn: async (t: string, o: { keep?: boolean }) => {
      await real.signIn(t, o).catch(() => {});
    },
  };
});

const { EditorView } = await import("@codemirror/view");
const embed = await import("../src/embed.js");
const { EmbedRoot } = await import("../src/components/Embed.js");
const state = await import("../src/state.js");
const { lang } = await import("../src/i18n.js");

const NONCE = "n0nce-n0nce_n0nce";
const sent: { rg: string; n: string; m: { t: string } & Record<string, unknown> }[] = [];
const of = (t: string) => sent.filter((s) => s.m.t === t).map((s) => s.m);
type Bar = {
  actions: { id: string; icon?: string; label: string }[];
  paste?: boolean;
  readOnly?: boolean;
};
const lastBar = () => of("bar").at(-1) as unknown as Bar | undefined;

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

const opened = (file: DocFile, text = "") =>
  state.applyMessage({
    type: "doc.opened",
    file,
    family: "text",
    revision: 1,
    snapshot: { family: "text", text },
    changes: [],
    proposals: [],
    presence: [],
    mode: "now",
    modeOwn: false,
  });

describe("the four editors, bare, in their shell", () => {
  it.each(["main.ts", "report.pdf", "logo.svg", "layers.ora"])("%s", async (path) => {
    const p = open("p1", path);
    const r = render(<EmbedRoot params={p} />);
    await waitFor(() => expect(r.container.querySelector(".doc-shell")).toBeTruthy(), {
      timeout: 5000,
    });
    // The page's head is not there: the frame is the app's.
    expect(r.container.querySelector(".canvas-head:not([hidden])")).toBeNull();
    expect(r.container.querySelector(".canvas.canvas-bare")).toBeTruthy();
    await waitFor(() => expect(lastBar()?.actions.map((a) => a.id)).toContain("keys"), {
      timeout: 5000,
    });
    // Only the picture editor takes a pasted picture; none is read only.
    await waitFor(() => expect(lastBar()?.paste ?? false).toBe(path === "layers.ora"), {
      timeout: 5000,
    });
    expect(lastBar()?.readOnly).toBeUndefined();
    // The editor's own keys are marked for the app's (the PDF's at once; the text's, the
    // drawing's and the picture's once their content is there).
    if (path === "report.pdf") expect(r.container.querySelector("[data-embed-keys]")).toBeTruthy();
  });
});

describe("the app's bar and composer", () => {
  it("the save state goes to the app, a failure with its reason", async () => {
    const file = { scope: "p1", path: "notes.md" };
    const r = render(<EmbedRoot params={open(file.scope, file.path)} />);
    await waitFor(() => expect(r.container.querySelector(".doc-shell")).toBeTruthy(), {
      timeout: 5000,
    });
    opened(file, "# Note\n");
    state.applyMessage({ type: "doc.saved", file, revision: 1 });
    await waitFor(() => expect(of("saveState")).toContainEqual({ t: "saveState", state: "saved" }));
    state.applyMessage({ type: "doc.saved", file, revision: 1, error: "disco pieno" });
    await waitFor(() =>
      expect(of("saveState").at(-1)).toEqual({
        t: "saveState",
        state: "error",
        error: "disco pieno",
      }),
    );
  });

  it("a selection in the text: «Ask the agent» in the bar, to the app with its lines", async () => {
    const file = { scope: "p1", path: "src/main.ts" };
    const r = render(<EmbedRoot params={open(file.scope, file.path)} />);
    await waitFor(() => expect(r.container.querySelector(".doc-shell")).toBeTruthy(), {
      timeout: 5000,
    });
    // Said again until the editor is listening (it opens the file once it is mounted).
    await waitFor(
      () => {
        if (!r.container.querySelector(".cm-editor"))
          opened(file, "const a = 1;\nconst b = 2;\nconst c = 3;\n");
        expect(r.container.querySelector(".cm-editor")).toBeTruthy();
      },
      { timeout: 5000 },
    );
    const view = EditorView.findFromDOM(r.container.querySelector(".cm-editor") as HTMLElement);
    if (!view) throw new Error("no editor");
    expect(lastBar()?.actions.map((a) => a.id)).not.toContain("ask");
    view.dispatch({ selection: { anchor: 6, head: 18 } });
    await waitFor(() => expect(lastBar()?.actions[0]).toMatchObject({ id: "ask", icon: "chat" }), {
      timeout: 5000,
    });
    expect(lastBar()?.actions[0]?.label).toBe("Chiedi all'agente");
    expect(embed.handleAppInput({ t: "action", id: "ask" })).toBe(true);
    expect(of("askAgent")).toEqual([
      {
        t: "askAgent",
        text: "a = 1;\nconst",
        ref: { scope: "p1", path: "src/main.ts", line: 1, lineEnd: 2 },
      },
    ]);
    // Nothing selected: the action goes.
    view.dispatch({ selection: { anchor: 3 } });
    await waitFor(() => expect(lastBar()?.actions.map((a) => a.id)).not.toContain("ask"));
  });

  it("the app's Ctrl+Z reaches the text even when the focus is nowhere in the page", async () => {
    const file = { scope: "p1", path: "keys.ts" };
    const r = render(<EmbedRoot params={open(file.scope, file.path)} />);
    await waitFor(() => expect(r.container.querySelector(".doc-shell")).toBeTruthy(), {
      timeout: 5000,
    });
    await waitFor(
      () => {
        if (!r.container.querySelector(".cm-editor")) opened(file, "x\n");
        expect(r.container.querySelector("[data-embed-keys]")).toBeTruthy();
      },
      { timeout: 5000 },
    );
    const keys = r.container.querySelector("[data-embed-keys]") as HTMLElement;
    expect(keys.classList.contains("cm-content")).toBe(true);
    const got: string[] = [];
    keys.addEventListener("keydown", (e) =>
      got.push(`${e.key}${e.shiftKey ? "+shift" : ""}${e.ctrlKey || e.metaKey ? "+mod" : ""}`),
    );
    (document.activeElement as HTMLElement | null)?.blur();
    embed.handleAppInput({ t: "key", key: "undo" });
    embed.handleAppInput({ t: "key", key: "redo" });
    expect(got).toEqual(["z+mod", "z+shift+mod"]);
  });

  it("a picture from the system's clipboard reaches the editor as a file", () => {
    open("p1", "layers.ora");
    const got: File[] = [];
    const take = (e: Event) => got.push(...(e as CustomEvent<{ files: File[] }>).detail.files);
    window.addEventListener("rg-embed-paste", take);
    try {
      expect(
        embed.handleAppInput({
          t: "paste",
          files: [{ name: "pasted.png", type: "image/png", size: 8, data: "iVBORw0KGgo=" }],
        }),
      ).toBe(true);
    } finally {
      window.removeEventListener("rg-embed-paste", take);
    }
    expect(got.map((f) => [f.name, f.type, f.size])).toEqual([["pasted.png", "image/png", 8]]);
  });

  it("an archived project's file: its viewer, said in the page and in the app's bar", async () => {
    const r = render(<EmbedRoot params={open("project:old", "notes.md")} />);
    await waitFor(() => expect(lastBar()?.readOnly).toBe(true), { timeout: 5000 });
    expect(r.container.querySelector(".doc-shell")).toBeNull();
    expect(r.container.querySelector(".canvas-archived-note")?.textContent).toMatch(
      /^Il progetto è archiviato/,
    );
    expect(lastBar()?.paste).toBeUndefined();
    // A file of a project in use is edited as usual.
    cleanup();
    embed.resetEmbed();
    const p = render(<EmbedRoot params={open("project:p1", "notes.md")} />);
    await waitFor(() => expect(p.container.querySelector(".doc-shell")).toBeTruthy(), {
      timeout: 5000,
    });
    expect(p.container.querySelector(".canvas-archived-note")).toBeNull();
  });
});
