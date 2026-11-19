// @vitest-environment jsdom
// G41.6b in the page: «Esporta» from the editor («Esporta per Resolve», «Esporta OTIO», the folder
// of the originals remembered, the saved file downloaded or opened, what the XML leaves out, the
// rate Resolve refuses explained) and the XML itself read by a real XML parser (jsdom's).
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { fcp7Xml, type ResolveJob, type VideoExportResult } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "../src/api.js";
import { lang } from "../src/i18n.js";

type Handler = (...args: unknown[]) => unknown;
let handlers: Record<string, Handler> = {};
const calls: [string, unknown[]][] = [];
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        const h = handlers[name];
        try {
          return h ? Promise.resolve(h(...args)) : Promise.resolve({});
        } catch (e) {
          return Promise.reject(e);
        }
      };
    },
  },
);
const opened: unknown[] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  openCanvas: (...args: unknown[]) => {
    opened.push(args);
    return "id";
  },
}));
const { ExportPanel, leftOutLines } = await import(
  "../src/components/viewers/video/ExportPanel.js"
);

const FILE = { scope: "project:p1", path: "video/gita.rgvideo" };
const result = (over: Partial<VideoExportResult> = {}): VideoExportResult => ({
  path: "video/gita.xml",
  format: "resolve",
  clips: 3,
  files: 2,
  mediaRoot: "E:\\Video\\Gita",
  example: "E:\\Video\\Gita\\intervista.mp4",
  leftOut: {
    titles: 1,
    transitions: 0,
    fades: 2,
    volumes: 0,
    kenBurns: 1,
    reframes: 0,
    speeds: 0,
    ducking: 0,
    markers: 0,
    captions: 0,
    missing: [],
  },
  ...over,
});

beforeEach(() => {
  lang.value = "it";
  handlers = {};
  calls.length = 0;
  opened.length = 0;
  localStorage.clear();
});
afterEach(() => cleanup());

describe("«Esporta»", () => {
  it("exports for Resolve with the folder of the originals, remembered", async () => {
    handlers.videoExport = () => ({ result: result() });
    const r = render(<ExportPanel file={FILE} onClose={() => {}} />);
    const input = r.getByPlaceholderText("E:\\Video\\Matrimonio") as HTMLInputElement;
    expect(r.getByText("Vuota: i file puntano a dove sono su questa macchina.")).toBeTruthy();
    fireEvent.input(input, { target: { value: " E:\\Video\\Gita " } });
    expect(r.getByText("I file puntano a questa cartella, con il loro nome.")).toBeTruthy();
    fireEvent.click(r.getByText("Esporta per Resolve"));
    await waitFor(() => r.getByText("Salvata: video/gita.xml (3 clip)."));
    expect(calls.find((c) => c[0] === "videoExport")?.[1]).toEqual([
      "project:p1",
      "video/gita.rgvideo",
      "resolve",
      "E:\\Video\\Gita",
    ]);
    expect(r.getByText("Primo file: E:\\Video\\Gita\\intervista.mp4")).toBeTruthy();
    expect(r.getByText(/File › Import › Timeline/)).toBeTruthy();
    expect(
      r.getByText(
        "Non nell'XML, da rifare in Resolve: 1 titoli o colori, 2 dissolvenze, 1 movimenti Ken Burns.",
      ),
    ).toBeTruthy();
    expect(localStorage.getItem("rg.video.resolveMediaRoot")).toBe("E:\\Video\\Gita");
    // Opened again: the folder is there.
    cleanup();
    const again = render(<ExportPanel file={FILE} onClose={() => {}} />);
    expect((again.getByPlaceholderText("E:\\Video\\Matrimonio") as HTMLInputElement).value).toBe(
      "E:\\Video\\Gita",
    );
  });

  it("exports OTIO, opens the file, and lets the embedding app save it", async () => {
    handlers.videoExport = () => ({
      result: result({ path: "video/gita.otio", format: "otio", mediaRoot: undefined }),
    });
    const saved: unknown[] = [];
    const r = render(
      <ExportPanel
        file={FILE}
        onClose={() => {}}
        onDownload={(f) => {
          saved.push(f);
          return true;
        }}
      />,
    );
    fireEvent.click(r.getByText("Esporta OTIO"));
    await waitFor(() => r.getByText("Salvata: video/gita.otio (3 clip)."));
    expect(calls.find((c) => c[0] === "videoExport")?.[1]).toEqual([
      "project:p1",
      "video/gita.rgvideo",
      "otio",
      "",
    ]);
    // OTIO carries everything: no list of what is left out.
    expect(r.queryByText(/Non nell'XML/)).toBeNull();
    fireEvent.click(r.getByText("Scarica"));
    expect(saved).toEqual([{ scope: "project:p1", path: "video/gita.otio", name: "gita.otio" }]);
    expect(calls.some((c) => c[0] === "download")).toBe(false);
    fireEvent.click(r.getByText("Apri"));
    expect(opened).toEqual([
      ["gita.otio", { kind: "file", scope: "project:p1", path: "video/gita.otio" }],
    ]);
  });

  it("downloads in the page; says the files not found and a rate Resolve refuses", async () => {
    handlers.videoExport = () => ({
      result: result({ leftOut: { ...result().leftOut, missing: ["riprese/sparito.mov"] } }),
    });
    handlers.download = () => new Blob(["<xmeml/>"]);
    const url = vi.fn(() => "blob:x");
    URL.createObjectURL = url;
    URL.revokeObjectURL = () => {};
    const click = vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(() => {});
    const r = render(<ExportPanel file={FILE} onClose={() => {}} />);
    fireEvent.click(r.getByText("Esporta per Resolve"));
    await waitFor(() =>
      r.getByText("Non trovati qui, esportati con quello che la timeline sa: riprese/sparito.mov."),
    );
    fireEvent.click(r.getByText("Scarica"));
    await waitFor(() => expect(click).toHaveBeenCalled());
    expect(calls.find((c) => c[0] === "download")?.[1]).toEqual(["project:p1", "video/gita.xml"]);
    click.mockRestore();

    handlers.videoExport = () => {
      throw new ApiError(400, "no SMPTE timecode", "video_export_rate");
    };
    fireEvent.click(r.getByText("Esporta per Resolve"));
    await waitFor(() => r.getByText(/L'XML per Resolve vuole una timeline a 23,976/));
  });

  it("speaks English too", () => {
    lang.value = "en";
    const r = render(<ExportPanel file={FILE} onClose={() => {}} />);
    expect(r.getByText("Export for Resolve")).toBeTruthy();
    expect(r.getByText("Export OTIO")).toBeTruthy();
    expect(leftOutLines(result())).toEqual(["1 titles or colours", "2 fades", "1 Ken Burns moves"]);
  });
});

describe("the XML read by a real XML parser", () => {
  const DIR = join(import.meta.dirname, "..", "..", "protocol", "test", "fixtures", "resolve");
  const names = readdirSync(DIR)
    .filter((f) => f.endsWith(".job.json") && f !== "rate12.job.json")
    .map((f) => f.replace(/\.job\.json$/, ""));
  it.each(names)("%s", (n) => {
    const job = JSON.parse(readFileSync(join(DIR, `${n}.job.json`), "utf8")) as ResolveJob;
    const doc = new DOMParser().parseFromString(fcp7Xml(job), "application/xml");
    expect(doc.getElementsByTagName("parsererror")).toHaveLength(0);
    expect(doc.documentElement.tagName).toBe("xmeml");
    const clips = [...doc.querySelectorAll("sequence > media clipitem")];
    expect(clips).toHaveLength(job.tracks.reduce((s, t) => s + t.clips.length, 0));
    // T19: every clip says which track of its file it uses.
    for (const c of clips)
      expect(c.querySelector(":scope > sourcetrack > trackindex")?.textContent).toBe("1");
    // T14: no empty clip left by a duplicate.
    for (const c of clips) expect(c.querySelector(":scope > start")).not.toBeNull();
    // The names as they are on the disk, read back unescaped.
    const names = new Set([...doc.querySelectorAll("file > name")].map((e) => e.textContent));
    for (const m of Object.values(job.media)) expect(names.has(m.name)).toBe(true);
  });
});
