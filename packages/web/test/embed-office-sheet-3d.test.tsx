// @vitest-environment jsdom
// G42.8: the sheet, document and 3D editors inside RGCompanion. Each opens bare in the embed (no
// head of the page, its title sent to the app); what they export reaches the app's «Save as…»;
// a document's «Open in the browser» is RedGiant's page with the file in its Canvas; the full
// document editor comes down with a real bar (amounts, speed, time left: measured with a fake
// clock), «Annulla» stops it (the server's job cancelled, the pages shown) and «Riprova» starts
// again; inside the app the reason it cannot run speaks of the app, not of Chrome.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

/** What the stand-in server does, per test. */
const server = {
  calls: [] as { name: string; args: unknown[] }[],
  ready: false,
  job: {
    state: "running" as "running" | "done" | "failed" | "cancelled",
    done: 0,
    rate: null as number | null,
    secondsLeft: null as number | null,
  },
  versions: [] as { name: string; path: string; type: string; size: number; modifiedAt: string }[],
};
const ZETA = 53_243_567;

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
              server.calls.push({ name: String(name), args });
              if (name === "canvasLink") {
                const target = args[0] as { path?: string };
                return { url: `/preview/T/${target.path ?? ""}`, folder: false };
              }
              if (name === "canvasVersion") return { version: 1 };
              if (name === "editorCopy") return { copy: null };
              if (name === "fileReport") return null;
              if (name === "editorSettings") return { settings: {} };
              if (name === "setup") return { config: { completed: true } };
              if (name === "officeState") return { ready: server.ready };
              if (name === "officePrepare") return { ready: false, job: "zeta-1" };
              if (name === "job")
                return {
                  id: "zeta-1",
                  state: server.job.state,
                  steps: [
                    {
                      state: server.job.state === "running" ? "running" : "done",
                      progress: {
                        done: server.job.done,
                        total: ZETA,
                        rate: server.job.rate,
                        secondsLeft: server.job.secondsLeft,
                      },
                    },
                  ],
                };
              if (name === "cancelJob") {
                server.job.state = "cancelled";
                return {};
              }
              if (name === "officeExport" || name === "sheetExport")
                return new Blob([new Uint8Array([80, 75, 3, 4])]);
              if (name === "list") return server.versions;
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

/** The page's one LibreOffice frame, as frame.js answers; its copy into the browser held here. */
const frame = {
  starts: 0,
  /** Sends a progress of the copy into the browser, as frame.js does. */
  progress: (_done: number, _total: number) => {},
  /** Lets the start finish. */
  finish: () => {},
};
vi.mock("../src/viewers/office-shared.js", async (orig) => {
  const real = await orig<typeof import("../src/viewers/office-shared.js")>();
  let n = 0;
  let shared: InstanceType<typeof real.SharedOffice> | undefined;
  const env = {
    frame(id: string) {
      const el = document.createElement("iframe");
      el.dataset.id = id;
      return el;
    },
    channel() {
      const ch = {
        onmessage: null as ((e: { data: unknown }) => void) | null,
        close() {},
        postMessage(m: unknown) {
          const q = m as { t: string; req?: number };
          const answer = (a: Record<string, unknown>) =>
            queueMicrotask(() => ch.onmessage?.({ data: { ...a, req: q.req, from: "frame" } }));
          if (q.t === "check") answer({ t: "check", secure: true, isolated: true, webgl: true });
          else if (q.t === "start") {
            frame.starts += 1;
            frame.progress = (done, total) =>
              ch.onmessage?.({ data: { t: "progress", done, total, from: "frame" } });
            frame.finish = () => answer({ t: "ready" });
          } else if (q.t === "open") answer({ t: "opened" });
          else if (q.t === "export") answer({ t: "exported", bytes: new ArrayBuffer(1) });
        },
      };
      return ch;
    },
    move: () => false,
    park: () => document.body,
    id: () => `f${++n}`,
  };
  return {
    ...real,
    sharedOffice: () => {
      shared ??= new real.SharedOffice(env);
      return shared;
    },
  };
});

// The device's access works: what the stand-in API cannot answer after it is not this test's.
vi.mock("../src/state.js", async (orig) => {
  const real = await orig<typeof import("../src/state.js")>();
  return {
    ...real,
    signIn: async (t: string, o: { keep?: boolean }) => {
      await real.signIn(t, o).catch(() => {});
    },
  };
});

const embed = await import("../src/embed.js");
const { EmbedRoot } = await import("../src/components/Embed.js");
const { OfficeEditor, whyText, officeVersions } = await import(
  "../src/components/viewers/OfficeEditor.js"
);
const state = await import("../src/state.js");
const { lang } = await import("../src/i18n.js");

const NONCE = "n0nce-n0nce_n0nce";
const sent: { rg: string; n: string; m: { t: string } & Record<string, unknown> }[] = [];
const of = (t: string) => sent.filter((s) => s.m.t === t).map((s) => s.m);

beforeEach(() => {
  sent.length = 0;
  server.calls.length = 0;
  server.ready = false;
  server.job = { state: "running", done: 0, rate: null, secondsLeft: null };
  server.versions = [];
  localStorage.clear();
  lang.value = "it";
  state.officeLoad.value = undefined;
  Object.defineProperty(window, "isSecureContext", { configurable: true, value: true });
  (window as unknown as Record<string, unknown>).RGEmbed = {
    postMessage: (s: string) => sent.push(JSON.parse(s)),
  };
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
  embed.resetEmbed();
  state.sideViews.value = [];
  delete (window as unknown as Record<string, unknown>).RGEmbed;
});

const open = (scope: string, path: string) => {
  history.replaceState(
    null,
    "",
    `/embed-isolated.html#token=t&embed=canvas&bridge=${NONCE}&scope=${scope}&path=${encodeURIComponent(path)}&theme=light&lang=it`,
  );
  const p = embed.takeEmbed();
  if (!p) throw new Error("no embed");
  return p;
};

describe("the three editors, bare in the embed", () => {
  it.each([
    ["conti.ods", ".sheet-editor"],
    ["relazione.odt", ".doc-office"],
    ["sedia.glb", ".doc-work"],
  ])("%s", async (path, editor) => {
    const p = open("p1", path);
    const r = render(<EmbedRoot params={p} />);
    await waitFor(() => expect(of("title")).toContainEqual({ t: "title", name: path }), {
      timeout: 5000,
    });
    await waitFor(() => expect(r.container.querySelector(editor)).not.toBeNull(), {
      timeout: 5000,
    });
    // No head of the page: the app's bar is the frame (its buttons sent as data).
    const head = r.container.querySelector(".canvas-head");
    expect(head?.hasAttribute("hidden")).toBe(true);
    await waitFor(() => expect(of("bar").length).toBeGreaterThan(0));
    expect(r.container.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
  });

  it("a document's «Open in the browser» is the page with the file in its Canvas", async () => {
    const p = open("p1", "relazione.docx");
    render(<EmbedRoot params={p} />);
    await waitFor(() => expect(of("bar").at(-1)?.link).toMatch(/^\/#open=canvas/));
    const link = String(of("bar").at(-1)?.link);
    const back = new URLSearchParams(link.slice(2));
    expect(back.get("scope")).toBe("p1");
    expect(back.get("path")).toBe("relazione.docx");
    // The page takes it once signed in, and the address keeps nothing of it.
    history.replaceState(null, "", link);
    expect(state.takeFromLink()).toEqual({
      file: { scope: "p1", path: "relazione.docx" },
    });
    expect(location.hash).toBe("");
  });
});

describe("«Save as…» through the app", () => {
  it("«Esporta come…» of a document sends the bytes to the app", async () => {
    open("p1", "relazione.odt");
    await state.signIn("t", { keep: false });
    const r = render(<OfficeEditor file={{ scope: "p1", path: "relazione.odt" }} />);
    // Our drawn choice (3.10.1), not a native select.
    const menu = r.container.querySelector(
      ".doc-office-export .ui-drop-current",
    ) as HTMLButtonElement;
    expect(menu).not.toBeNull();
    expect(r.container.querySelector("select")).toBeNull();
    // jsdom has no blob URLs to fetch: the URL the page made answers with the export's bytes.
    const urls = vi
      .spyOn(URL, "createObjectURL")
      .mockImplementation(() => "blob:http://localhost/1");
    const fetched = vi
      .spyOn(globalThis, "fetch")
      .mockImplementation(async (u) =>
        String(u) === "blob:http://localhost/1"
          ? new Response(new Uint8Array([80, 75, 3, 4]))
          : new Response(null, { status: 404 }),
      );
    try {
      fireEvent.click(menu);
      const pdf = [...document.querySelectorAll<HTMLButtonElement>(".ui-drop-list button")].find(
        (b) => b.textContent === "PDF",
      ) as HTMLButtonElement;
      fireEvent.click(pdf);
      await waitFor(() => expect(of("saveAs")).toHaveLength(1));
      expect(of("saveAs")[0]).toEqual({ t: "saveAs", name: "relazione.pdf", data: "UEsDBA==" });
    } finally {
      urls.mockRestore();
      fetched.mockRestore();
    }
  });

  it("a kept version of the original is saved through the app as a link of the server", async () => {
    open("p1", "relazione.docx.open/relazione.odt");
    await state.signIn("t", { keep: false });
    server.versions = [
      {
        name: "relazione.2026-11-17T10-00-00-000Z.docx",
        path: "relazione.docx.open/versions/relazione.2026-11-17T10-00-00-000Z.docx",
        type: "file",
        size: 2048,
        modifiedAt: "2026-11-17T10:00:00.000Z",
      },
      {
        name: "relazione.2026-11-18T09-00-00-000Z.docx",
        path: "relazione.docx.open/versions/relazione.2026-11-18T09-00-00-000Z.docx",
        type: "file",
        size: 4096,
        modifiedAt: "2026-11-18T09:00:00.000Z",
      },
      {
        name: "notes.txt",
        path: "relazione.docx.open/versions/notes.txt",
        type: "file",
        size: 1,
        modifiedAt: "",
      },
    ];
    const listed = await officeVersions("p1", "relazione.docx");
    expect(listed.map((v) => v.size)).toEqual([4096, 2048]);
    const r = render(
      <OfficeEditor file={{ scope: "p1", path: "relazione.docx.open/relazione.odt" }} />,
    );
    fireEvent.click(r.getByText("Versioni"));
    await waitFor(() =>
      expect(r.container.querySelectorAll(".doc-office-versions li")).toHaveLength(2),
    );
    fireEvent.click(r.container.querySelector(".doc-office-versions li button") as HTMLElement);
    await waitFor(() => expect(of("saveAs")).toHaveLength(1));
    expect(of("saveAs")[0]).toEqual({
      t: "saveAs",
      name: "relazione.2026-11-18T09-00-00-000Z.docx",
      url: "/preview/T/relazione.docx.open/versions/relazione.2026-11-18T09-00-00-000Z.docx",
    });
  });
});

describe("the full document editor coming down (fake clock)", () => {
  const file = { scope: "p1", path: "relazione.odt" };
  const text = (r: ReturnType<typeof render>) => r.container.textContent ?? "";

  it("the server's download with its bar, then «Annulla» and «Riprova»", async () => {
    open("p1", "relazione.odt");
    await state.signIn("t", { keep: false });
    vi.useFakeTimers();
    const r = render(<OfficeEditor file={file} />);
    await vi.advanceTimersByTimeAsync(10);
    expect(text(r)).toContain("Scarico l'editor completo");
    server.job.done = 10 * 1024 * 1024;
    server.job.rate = 5 * 1024 * 1024;
    server.job.secondsLeft = 8;
    await vi.advanceTimersByTimeAsync(1100);
    const bar = r.container.querySelector(".doc-office-wait .ui-progress") as HTMLElement;
    expect(bar.textContent).toContain("10.0 MB");
    expect(bar.textContent).toContain("5.0 MB/s");
    expect(bar.querySelector('[role="progressbar"]')?.getAttribute("aria-valuenow")).toBe("20");
    fireEvent.click(r.getByText("Annulla"));
    await vi.advanceTimersByTimeAsync(10);
    expect(server.calls.filter((c) => c.name === "cancelJob").map((c) => c.args)).toEqual([
      ["zeta-1"],
    ]);
    // The pages are shown with why, and the start can be tried again.
    expect(r.container.querySelector(".doc-office-fallback")).not.toBeNull();
    expect(text(r)).toContain("hai fermato lo scaricamento");
    // Nothing more is asked of the cancelled job.
    const asked = server.calls.filter((c) => c.name === "job").length;
    await vi.advanceTimersByTimeAsync(5000);
    expect(server.calls.filter((c) => c.name === "job").length).toBe(asked);
    server.ready = true;
    fireEvent.click(r.getByText("Riprova"));
    await vi.advanceTimersByTimeAsync(10);
    expect(r.container.querySelector(".doc-office-fallback")).toBeNull();
    expect(text(r)).toContain("Porto l'editor in questo browser");
  });

  it("the copy into the web view's storage: speed and time left measured, then «Annulla»", async () => {
    open("p1", "relazione.odt");
    await state.signIn("t", { keep: false });
    server.ready = true;
    vi.useFakeTimers();
    const starts = frame.starts;
    const r = render(<OfficeEditor file={file} />);
    await vi.advanceTimersByTimeAsync(10);
    expect(frame.starts).toBe(starts + 1);
    frame.progress(0, ZETA);
    await vi.advanceTimersByTimeAsync(2000);
    frame.progress(20 * 1024 * 1024, ZETA);
    await vi.advanceTimersByTimeAsync(10);
    const load = state.officeLoad.value;
    expect(load?.at).toBe("browser");
    // 20 MB in 2 s: 10 MB/s, the rest (about 30.8 MB) in about 3 s.
    expect(Math.round((load?.progress?.rate ?? 0) / 1024 / 1024)).toBe(10);
    expect(Math.round(load?.progress?.secondsLeft ?? 0)).toBe(3);
    const bar = r.container.querySelector(".doc-office-wait .ui-progress") as HTMLElement;
    expect(bar.textContent).toContain("10.0 MB/s");
    fireEvent.click(r.getByText("Annulla"));
    await vi.advanceTimersByTimeAsync(10);
    expect(r.container.querySelector(".doc-office-fallback")).not.toBeNull();
    // The frame was not the server's job: nothing to cancel there.
    expect(server.calls.some((c) => c.name === "cancelJob")).toBe(false);
    // The copy finishing late changes nothing.
    frame.finish();
    await vi.advanceTimersByTimeAsync(10);
    expect(r.container.querySelector(".doc-office-fallback")).not.toBeNull();
  });
});

describe("the app's theme reaches the editors (G42.8)", () => {
  it("the page's theme signal follows the app, and nothing is saved", async () => {
    const { applyEmbedLook } = await import("../src/components/Embed.js");
    const { theme } = await import("../src/theme.js");
    applyEmbedLook({ theme: "dark" });
    expect(theme.value).toBe("dark");
    expect(document.documentElement.dataset.theme).toBe("dark");
    applyEmbedLook({ theme: "light" });
    expect(theme.value).toBe("light");
    expect(localStorage.getItem("rg.theme")).toBeNull();
  });
});

describe("why the full editor does not run, inside the app", () => {
  it("speaks of the app's web view and of «Apri nel browser», never of using Chrome", () => {
    expect(whyText("browser")).toContain("Chrome, Edge");
    open("p1", "relazione.odt");
    const said = whyText("browser");
    expect(said).toContain("l'app");
    expect(said).toContain("«Apri nel browser»");
    // WebKitGTK: isolated, but no WebGL in LibreOffice's workers (G42.8, the Linux app).
    const webgl = whyText("webgl");
    expect(webgl).toContain("vista web dell'app");
    expect(webgl).toContain("«Apri nel browser»");
    expect(webgl).not.toBe(said);
  });
});
