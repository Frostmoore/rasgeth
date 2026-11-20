// @vitest-environment jsdom
// 3.10, video part 2 in the page: the inspector's speed, still frame, picture in a box with a key
// at the playhead, colour (a dial moved with the keys), a LUT from the project, the volume's keys,
// the music's beats found by the server and «Taglia a ritmo»; the T tool's slip. Each change is
// one edit of the timeline, as an agent's would be.
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
const lastWhat = () => {
  const m = sentDoc.filter((x) => x.type === "doc.ops").at(-1) as { ops: DocOp[] } | undefined;
  const a = m?.ops[0]?.op as VideoAction | undefined;
  return a?.t === "batch" ? a.what : a?.t;
};
const byText = (root: ParentNode, sel: string, text: string) =>
  [...root.querySelectorAll<HTMLElement>(sel)].find(
    (b) => b.textContent?.trim() === text,
  ) as HTMLElement;
const sec = (root: ParentNode, label: string) =>
  root.querySelector(`.ve-insp-sec[aria-label="${label}"]`) as HTMLElement;
const switchIn = (el: HTMLElement) => el.querySelector('[role="switch"]') as HTMLElement;

beforeEach(() => {
  lang.value = "it";
  for (const m of ["load", "pause"] as const)
    vi.spyOn(HTMLMediaElement.prototype, m).mockImplementation(() => {});
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(async () => {});
});
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

describe("3.10, video part 2: the inspector", () => {
  it("speed and still frame on a video clip", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoEdit(KEY, { sel: ["a"], inspOpen: true }));
    const speed = sec(r.container, "Velocità");
    fireEvent.click(byText(speed, "button", "2× più veloce"));
    await waitFor(() => expect(host.doc.clips.find((c) => c.id === "a")?.speed).toBe(2));
    expect(lastWhat()).toBe("props");
    fireEvent.click(switchIn(speed));
    await waitFor(() => expect(host.doc.clips.find((c) => c.id === "a")?.freeze).toBe(true));
  });

  it("picture in picture: on, then a keyframe at the playhead", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoEdit(KEY, { sel: ["a"], inspOpen: true }));
    const box = () => sec(r.container, "Immagine nell'immagine");
    fireEvent.click(switchIn(box()));
    await waitFor(() =>
      expect(host.doc.clips.find((c) => c.id === "a")?.box).toEqual({
        x: 0.75,
        y: 0.25,
        scale: 0.33,
      }),
    );
    await act(async () => state.setVideoView(KEY, { frame: 40, playing: false }));
    fireEvent.click(await waitFor(() => byText(box(), "button", "Chiave al cursore")));
    await waitFor(() =>
      expect(host.doc.clips.find((c) => c.id === "a")?.boxKeys?.map((k) => k.at)).toEqual([0, 40]),
    );
    expect(lastWhat()).toBe("keys");
    expect(box().textContent).toContain("2 chiavi");
  });

  it("colour with the keys of a dial; a LUT of the project; back to as shot", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoEdit(KEY, { sel: ["a"], inspOpen: true }));
    const color = () => sec(r.container, "Colore");
    const sat = [...color().querySelectorAll<HTMLElement>("label.ve-dial")].find((l) =>
      l.textContent?.includes("Saturazione"),
    ) as HTMLElement;
    fireEvent.keyDown(sat, { key: "ArrowLeft", shiftKey: true });
    await waitFor(() =>
      expect(host.doc.clips.find((c) => c.id === "a")?.color?.saturation).toBeCloseTo(-0.5),
    );
    expect(lastWhat()).toBe("color");
    asked.text = "lut/film.cube";
    fireEvent.click(byText(color(), "button", "Aggiungi una LUT…"));
    await waitFor(() =>
      expect(host.doc.clips.find((c) => c.id === "a")?.lut).toBe("lut/film.cube"),
    );
    fireEvent.click(byText(color(), "button", "Come girato"));
    await waitFor(() => expect(host.doc.clips.find((c) => c.id === "a")?.color).toBeUndefined());
  });

  it("the music's beats from the server, then the cuts on them", async () => {
    const { r, host } = await open();
    handlers.videoBeats = (..._args: unknown[]) => ({
      clip: String(_args[2]),
      bpm: 120,
      frames: [12, 24, 37, 50, 98, 150],
    });
    await act(async () => state.setVideoEdit(KEY, { sel: ["va"], inspOpen: true }));
    const beats = () => sec(r.container, "Le battute della musica");
    fireEvent.click(byText(beats(), "button", "Trova le battute"));
    await waitFor(() => expect(host.doc.beats).toEqual([12, 24, 37, 50, 98, 150]));
    expect(host.doc.beatsOf).toBe("va");
    expect(calls.find(([n]) => n === "videoBeats")?.[1]).toEqual([
      "p1",
      "video/gita.rgvideo",
      "va",
    ]);
    expect(r.container.querySelectorAll(".ve-beat")).toHaveLength(6);
    fireEvent.click(byText(beats(), "button", "Taglia a ritmo"));
    // The cut at 100 goes to the beat at 98 (within a quarter of a second).
    await waitFor(() =>
      expect(host.doc.clips.find((c) => c.id === "a")?.sourceRange.duration).toBe(98),
    );
    expect(lastWhat()).toBe("beats");
  });
});

describe("3.10, video part 2: the page's player", () => {
  it("a box as a transform of the frame; the colour as CSS filters", async () => {
    const { boxCss, colorCss } = await import("../src/components/viewers/video/player.js");
    const base = timeline().clips[0] as VideoClip;
    expect(boxCss({ ...base, box: { x: 0.75, y: 0.25, scale: 0.3 } }, 0)).toBe(
      "translate(60%, 10%) scale(0.3)",
    );
    expect(
      boxCss(
        {
          ...base,
          boxKeys: [
            { at: 0, x: 0.5, y: 0.5, scale: 1 },
            { at: 10, x: 1, y: 0.5, scale: 0.5 },
          ],
        },
        5,
      ),
    ).toBe("translate(37.5%, 12.5%) scale(0.75)");
    expect(boxCss(base, 0)).toBe("");
    expect(
      colorCss({
        ...base,
        color: { exposure: 1, contrast: 0.2, saturation: -1, temperature: 0.5 },
      }),
    ).toBe("brightness(2) contrast(1.2) saturate(0) sepia(0.175)");
    expect(
      colorCss({ ...base, color: { exposure: 0, contrast: 0, saturation: 0, temperature: -1 } }),
    ).toBe("hue-rotate(18deg)");
  });

  it("a speed reads further into the file, a still stays on its frame; the volume's keys", async () => {
    const { videoLayers, audioLayers } = await import("../src/components/viewers/video/player.js");
    const d = timeline();
    const a = d.clips.find((c) => c.id === "a") as VideoClip;
    a.speed = 2;
    expect(videoLayers(d, "V1", 25, {})[0]?.time).toBeCloseTo(2);
    a.freeze = true;
    expect(videoLayers(d, "V1", 25, {})[0]?.time).toBeCloseTo(0);
    const va = d.clips.find((c) => c.id === "va") as VideoClip;
    va.volumeKeys = [
      { at: 0, db: 0 },
      { at: 50, db: -20 },
    ];
    expect(audioLayers(d, "A1", 50)[0]?.gain).toBeCloseTo(0.1);
  });
});

describe("3.10, video part 2: the T tool", () => {
  beforeEach(() => {
    // Clips where their style puts them (one pixel per frame).
    vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(function (
      this: Element,
    ) {
      const el = this as HTMLElement;
      const left = el.dataset?.clip ? Number.parseFloat(el.style.left) : 0;
      const width = el.dataset?.clip ? Number.parseFloat(el.style.width) : 0;
      return {
        left,
        width,
        right: left + width,
        top: 0,
        bottom: 44,
        height: 44,
        x: left,
        y: 0,
      } as DOMRect;
    });
  });
  const drag = (el: Element, from: number, to: number, more: PointerEventInit = {}) => {
    fireEvent.pointerDown(el, { button: 0, clientX: from, clientY: 10, ...more });
    fireEvent.pointerMove(window, { clientX: to, clientY: 10 });
    fireEvent.pointerUp(window, { clientX: to });
  };

  it("the middle of a clip slips its frames; Shift on a cut rolls it", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoEdit(KEY, { tool: "trim" }));
    const b = () => host.doc.clips.find((c) => c.id === "b") as VideoClip;
    const left = Number.parseFloat(
      (r.container.querySelector("[data-clip=b]") as HTMLElement).style.left,
    );
    // Dragging left shows later frames of the file, as in Resolve; same place and length.
    await act(async () =>
      drag(r.container.querySelector("[data-clip=b]") as Element, left + 50, left + 40),
    );
    await waitFor(() => expect(b().sourceRange.start).toBe(60));
    expect([b().start, b().sourceRange.duration]).toEqual([100, 100]);
    expect(lastWhat()).toBe("slip");
    // Shift on b's start: the cut between a and b moves, a longer and b shorter.
    await act(async () =>
      drag(r.container.querySelector("[data-clip=b]") as Element, left + 1, left + 9, {
        shiftKey: true,
      }),
    );
    await waitFor(() => expect(b().start).toBe(108));
    expect(host.doc.clips.find((c) => c.id === "a")?.sourceRange.duration).toBe(108);
    expect([b().sourceRange.start, b().sourceRange.duration]).toEqual([68, 92]);
    expect(lastWhat()).toBe("roll");
  });
});
