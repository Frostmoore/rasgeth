// @vitest-environment jsdom
// G42.18: the video timeline inside RGCompanion (an embed). The timeline's keys the app passes on
// (J/K/L, I/O, Ctrl/Cmd+B) reach the editor when nothing in the page has the focus; a file dragged
// from the app's own tree lands on a track; «Chiedi all'agente qui» goes into the app's composer;
// «Salva come…» of a finished file goes through the app's dialog with a signed link; a render is
// handed to the app to follow in its notifications.
import {
  type DocOp,
  newRgVideo,
  type RgVideo,
  type VideoAction,
  type VideoClip,
} from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { videoFamily } from "../../server/src/editor/video-family.js";
import { lang } from "../src/i18n.js";
import type { DocPeer } from "../src/state.js";

const R = { num: 25, den: 1 };
const clip = (
  id: string,
  track: string,
  start: number,
  dur: number,
  media: string,
  more: Partial<VideoClip> = {},
): VideoClip => ({
  id,
  track,
  start,
  sourceRange: { start: 0, duration: dur },
  ref: { media, frames: 400 },
  enabled: true,
  volume: 0,
  fadeIn: 0,
  fadeOut: 0,
  fit: "fill",
  ...more,
});

function timeline(): RgVideo {
  const d = newRgVideo({ width: 1080, height: 1920, rate: R, aspect: "9:16" }, "Gita");
  d.tracks = [
    { id: "V1", kind: "Video", name: "V1", locked: false },
    { id: "V2", kind: "Video", name: "V2", locked: false },
    { id: "A1", kind: "Audio", name: "Voce", locked: false },
  ];
  d.clips = [
    clip("a", "V1", 0, 100, "v/a.mp4", { link: "g1" }),
    clip("b", "V1", 100, 100, "v/b.mp4", { sourceRange: { start: 50, duration: 100 } }),
    clip("va", "A1", 0, 100, "v/a.mp4", { link: "g1" }),
    {
      ...clip("t", "V2", 25, 50, "x"),
      ref: { generator: "text", text: "Ciao a tutti", style: "title", position: "center" },
    },
  ];
  d.transitions = [
    { id: "x1", track: "V1", from: "a", to: "b", kind: "dissolve", inOffset: 5, outOffset: 5 },
  ];
  d.markers = [{ id: "m1", frame: 150, color: "RED", note: "più corto" }];
  d.captions.segments = [{ id: "s1", start: 10, end: 60, text: "Buongiorno a tutti" }];
  return d;
}

class MiniHost {
  doc: RgVideo;
  revision = 0;
  constructor(d: RgVideo) {
    this.doc = d;
  }
  apply(ops: readonly DocOp[]): string | undefined {
    for (const o of ops) {
      const bad = videoFamily.check({ doc: this.doc }, o);
      if (bad) return bad;
      this.doc = videoFamily.apply({ doc: this.doc }, o).doc;
    }
    this.revision++;
    return undefined;
  }
}

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
        return h ? Promise.resolve(h(...args)) : Promise.resolve({});
      };
    },
  },
);
let peer: DocPeer | undefined;
const sentDoc: Record<string, unknown>[] = [];
let onSend: (m: Record<string, unknown>) => void = () => {};
const asked = { confirm: true, text: "Bozza per Marco" as string | null };
vi.mock("../src/components/dialogs.js", async (orig) => ({
  ...(await orig<typeof import("../src/components/dialogs.js")>()),
  askConfirm: vi.fn(async () => asked.confirm),
  askText: vi.fn(async () => asked.text),
}));
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  openDoc: (_file: unknown, p: DocPeer) => {
    peer = p;
    return () => {
      peer = undefined;
    };
  },
  sendDoc: (m: Record<string, unknown>) => {
    sentDoc.push(m);
    onSend(m);
  },
  saveDoc: () => {},
}));
const { VideoEditor } = await import("../src/components/viewers/VideoEditor.js");
const embed = await import("../src/embed.js");
const state = await import("../src/state.js");

const file = { scope: "p1", path: "video/gita.rgvideo" };
const KEY = `${file.scope}:${file.path}`;
const probe = {
  kind: "video" as const,
  duration: 16,
  width: 1920,
  height: 1080,
  rotation: 0,
  rate: R,
  codec: "h264",
  audio: true,
  audioCodec: "aac",
  sampleRate: null,
  channels: null,
  timecode: null,
  createdAt: null,
  size: 1,
};

async function open(d = timeline(), onAsk?: (text: string) => { to: string } | undefined) {
  const host = new MiniHost(d);
  sentDoc.length = 0;
  calls.length = 0;
  handlers = {
    videoPrepare: () => ({
      media: ["v/a.mp4", "v/b.mp4"].map((m) => ({
        media: m,
        kind: "video",
        probe,
        file: `/preview/x/${m}`,
        jobs: [],
      })),
      fonts: { regular: "/r.ttf", bold: "/b.ttf" },
    }),
  };
  onSend = (m) => {
    if (m.type !== "doc.ops") return;
    const bad = host.apply(m.ops as DocOp[]);
    if (bad) throw new Error(`refused: ${bad}`);
    peer?.ack({
      type: "doc.ack",
      file,
      clientId: m.clientId as string,
      revision: host.revision,
    } as never);
  };
  state.setVideoEdit(KEY, {
    ppf: 1,
    sel: [],
    tool: "select",
    snapping: true,
    linkedSel: true,
    pool: [],
    sourceOpen: false,
    help: false,
    gap: undefined,
    source: undefined,
    trans: undefined,
    cap: undefined,
    inspOpen: undefined,
    transcript: undefined,
    words: undefined,
    allTracks: undefined,
    editText: undefined,
  });
  state.setVideoView(KEY, { frame: 0, playing: false });
  const r = render(<VideoEditor file={file} {...(onAsk && { onAsk })} />);
  await act(async () => peer?.opened({ family: "video", doc: d }, 0));
  await waitFor(() => r.container.querySelector("[data-clip=a]"));
  return { r, host };
}
const NONCE = "n0nce-n0nce_n0nce";
const toApp: { t: string; [k: string]: unknown }[] = [];
const lastWhat = () => {
  const m = sentDoc.filter((x) => x.type === "doc.ops").at(-1) as { ops: DocOp[] } | undefined;
  const a = m?.ops[0]?.op as VideoAction | undefined;
  return a?.t === "batch" ? a.what : a?.t;
};
const tool = (root: ParentNode, label: string) =>
  root.querySelector(`.ve-bar button[aria-label^="${label}"]`) as HTMLElement;
const byText = (root: ParentNode, sel: string, text: string) =>
  [...root.querySelectorAll<HTMLElement>(sel)].find(
    (b) => b.textContent?.trim() === text,
  ) as HTMLElement;
const clipsOf = (d: RgVideo, media: string) =>
  d.clips.filter((c) => "media" in c.ref && c.ref.media === media);

beforeEach(() => {
  lang.value = "it";
  toApp.length = 0;
  for (const m of ["load", "pause"] as const)
    vi.spyOn(HTMLMediaElement.prototype, m).mockImplementation(() => {});
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(async () => {});
  (window as unknown as Record<string, unknown>).RGEmbed = {
    postMessage: (s: string) => toApp.push(JSON.parse(s).m),
  };
  history.replaceState(
    null,
    "",
    `/embed.html#token=rgd_x&embed=canvas&bridge=${NONCE}&scope=p1&path=video%2Fgita.rgvideo&theme=light&lang=it`,
  );
  embed.takeEmbed();
});
afterEach(() => {
  cleanup();
  embed.resetEmbed();
  vi.restoreAllMocks();
  delete (window as unknown as Record<string, unknown>).RGEmbed;
});

describe("G42.18: the timeline in the app", () => {
  it("the app's keys reach the editor with the focus nowhere: Ctrl+B cuts at the cursor", async () => {
    const { host } = await open();
    await act(async () => state.setVideoView(KEY, { frame: 50, playing: false }));
    (document.activeElement as HTMLElement | null)?.blur();
    await act(async () => {
      embed.handleAppInput({ t: "key", key: "blade" });
    });
    await waitFor(() => expect(lastWhat()).toBe("blade"));
    expect(host.doc.clips.filter((c) => c.track === "V1")).toHaveLength(3);
  });

  it("J, K, L from the app play backwards, stop and play forwards; the keys carry no modifier", async () => {
    await open();
    const seen: KeyboardEvent[] = [];
    const ve = document.querySelector("[data-embed-keys]") as HTMLElement;
    expect(ve.classList.contains("ve")).toBe(true);
    ve.addEventListener("keydown", (e) => seen.push(e));
    for (const key of ["shuttleBack", "pause", "shuttleForward", "markIn", "markOut"] as const)
      await act(async () => {
        embed.handleAppInput({ t: "key", key });
      });
    expect(seen.map((e) => [e.key, e.ctrlKey || e.metaKey])).toEqual([
      ["j", false],
      ["k", false],
      ["l", false],
      ["i", false],
      ["o", false],
    ]);
    await waitFor(() => expect(state.videoViewOf(KEY).playing).toBe(true));
  });

  it("a file dragged from the app's tree lands on a track; one of another project is said", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoView(KEY, { frame: 200, playing: false }));
    const before = clipsOf(host.doc, "v/b.mp4").length;
    await act(async () => {
      embed.handleAppInput({ t: "drop", scope: "p1", path: "v/b.mp4", x: 300, y: 400 });
    });
    await waitFor(() => expect(clipsOf(host.doc, "v/b.mp4").length).toBeGreaterThan(before));
    const placed = clipsOf(host.doc, "v/b.mp4").find((c) => c.start === 200);
    expect(placed?.track).toBe("V1");
    await act(async () => {
      embed.handleAppInput({ t: "drop", scope: "p2", path: "v/b.mp4", x: 300, y: 400 });
    });
    await waitFor(() =>
      expect(r.container.querySelector(".ve-notice")?.textContent).toBe(
        "Quel file non è in questo progetto.",
      ),
    );
  });

  it("«Chiedi all'agente qui» goes into the app's composer with the timeline's place", async () => {
    const { r } = await open();
    await act(async () => state.setVideoEdit(KEY, { sel: ["b"] }));
    fireEvent.click(tool(r.container, "Chiedi all'agente qui"));
    const box = (await waitFor(() =>
      r.container.querySelector(".ve-ask textarea"),
    )) as HTMLTextAreaElement;
    fireEvent.input(box, { target: { value: "Accorcia questa parte" } });
    fireEvent.click(byText(r.container.querySelector(".ve-ask") as HTMLElement, "button", "Manda"));
    await waitFor(() => expect(r.container.querySelector(".ve-ask")).toBeNull());
    const ask = toApp.find((m) => m.t === "askAgent") as unknown as { text: string; ref: unknown };
    expect(ask.ref).toEqual({ scope: "p1", path: "video/gita.rgvideo" });
    expect(ask.text.startsWith("Accorcia questa parte\n\n[Nel montaggio video/gita.rgvideo")).toBe(
      true,
    );
    expect(r.container.querySelector(".ve-notice")?.textContent).toBe(
      "La domanda è nel riquadro della conversazione: mandala da lì.",
    );
  });
});

describe("G42.18: the bridge's ways for a video", () => {
  it("«Salva come…» of a project's file: its signed link, to the app's dialog", async () => {
    const link = vi.fn(async () => ({ url: "/api/canvas/raw/abc/finale.mp4?sig=1" }));
    const ok = await embed.saveFileThroughApp(link, {
      scope: "p1",
      path: "video/finale.mp4",
      name: "finale.mp4",
    });
    expect(ok).toBe(true);
    expect(link).toHaveBeenCalledWith({ kind: "file", scope: "p1", path: "video/finale.mp4" });
    expect(toApp.at(-1)).toEqual({
      t: "saveAs",
      name: "finale.mp4",
      url: "/api/canvas/raw/abc/finale.mp4?sig=1",
    });
    // no link: false, nothing sent
    const n = toApp.length;
    expect(
      await embed.saveFileThroughApp(
        async () => {
          throw new Error("404");
        },
        { scope: "p1", path: "x.xml", name: "x.xml" },
      ),
    ).toBe(false);
    expect(toApp).toHaveLength(n);
  });

  it("a render handed to the app; outside an app nothing goes anywhere", () => {
    expect(embed.followJobInApp("6f1c2d3e-0a1b", "Video di gita.rgvideo")).toBe(true);
    expect(toApp.at(-1)).toEqual({ t: "job", id: "6f1c2d3e-0a1b", title: "Video di gita.rgvideo" });
    embed.resetEmbed();
    expect(embed.followJobInApp("a", "b")).toBe(false);
    expect(embed.askAppAbout({ scope: "p1" }, "x")).toBe(false);
  });
});
