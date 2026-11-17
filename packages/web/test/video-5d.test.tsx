// @vitest-environment jsdom
// G41.5d in the page: A1, the picture placed as the render places it (a crop moved, filled or
// fitted, on black or on a blurred copy: the pure geometry as a table and the player's elements),
// the inspector's crop on the miniature, what shows around a fitted clip and the timeline's shape;
// A2, the switch for −14 LUFS; A4, «Chiedi all'agente qui» (what is chosen, with its times and ids,
// as a table, and the message handed to the conversation); A5, the named versions saved, listed
// and brought back as one edit after the present one is saved too.
import {
  type DocOp,
  newRgVideo,
  PERSON,
  type RgVideo,
  type VideoAction,
  type VideoClip,
} from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { videoFamily } from "../../server/src/editor/video-family.js";
import {
  backdropOf,
  type MediaLike,
  pictureFrame,
  TimelinePlayer,
} from "../src/components/viewers/video/player.js";
import { lang } from "../src/i18n.js";
import type { DocPeer } from "../src/state.js";
import { askHereContext, askHereMessage } from "../src/viewers/video-ops.js";

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

beforeEach(() => {
  lang.value = "it";
});
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

// ---- the pure parts -------------------------------------------------------------------------

describe("A1: the page's picture as the render's", () => {
  const HD = { w: 1920, h: 1080 };
  const VERT = { w: 1080, h: 1920 };
  it.each([
    ["no crop: left as it is (cover or contain)", { fit: "fill" as const }, HD, "", null],
    [
      "no size known: left as it is",
      { fit: "fill" as const, crop: { x: 0, y: 0, w: 0.3164, h: 1 } },
      undefined,
      "",
      null,
    ],
    [
      "a crop at the left edge, filled",
      { fit: "fill" as const, crop: { x: 0, y: 0, w: 0.3164, h: 1 } },
      HD,
      "",
      {
        transform: "translate(0.00000%, -0.00100%) scale(3.16056, 1.00002)",
        clipPath: "inset(0.000% 68.360% 0.000% 0.000%)",
      },
    ],
    [
      "a crop fitted, with a wipe of the stage moved into the file's measures",
      { fit: "fit" as const, crop: { x: 0.25, y: 0, w: 0.5, h: 1 } },
      VERT,
      "inset(0 50.00% 0 0)",
      {
        transform: "translate(0.00000%, 0.00000%) scale(1.00000, 1.00000)",
        clipPath: "inset(0.000% 50.000% 0.000% 25.000%)",
      },
    ],
  ] as const)("%s", (_w, c, src, wipe, want) => {
    expect(pictureFrame(c, src, VERT, wipe)).toEqual(want);
  });

  it.each([
    ["filled", { fit: "fill", background: "blur" }, "none"],
    ["fitted, nothing around", { fit: "fit" }, "none"],
    ["fitted on black", { fit: "fit", background: "black" }, "black"],
    ["fitted on a blurred copy", { fit: "fit", background: "blur" }, "blur"],
  ] as const)("around the picture: %s", (_w, c, want) => {
    expect(backdropOf(c)).toBe(want);
  });
});

describe("A4: what the question is about", () => {
  const d = timeline();
  it.each([
    [
      "two clips: their span, ids, tracks and files",
      { clips: ["a", "va"], playhead: 0 },
      [
        "[Nel montaggio video/gita.rgvideo, da 00:00:00:00 a 00:00:04:00 (fotogrammi 0-100 a 25 fps)]",
        "- clip a su V1: v/a.mp4, 00:00:00:00-00:00:04:00, dal file 00:00:00:00-00:00:04:00",
        "- clip va su A1: v/a.mp4, 00:00:00:00-00:00:04:00, dal file 00:00:00:00-00:00:04:00",
      ],
    ],
    [
      "a title",
      { clips: ["t"], playhead: 0 },
      [
        "[Nel montaggio video/gita.rgvideo, da 00:00:01:00 a 00:00:03:00 (fotogrammi 25-75 a 25 fps)]",
        "- clip t su V2: titolo «Ciao a tutti», 00:00:01:00-00:00:03:00",
      ],
    ],
    [
      "a transition: its window around the cut",
      { transition: "x1", playhead: 0 },
      [
        "[Nel montaggio video/gita.rgvideo, da 00:00:03:20 a 00:00:04:05 (fotogrammi 95-105 a 25 fps)]",
        "- transizione x1 (dissolve) fra a e b, taglio a 00:00:04:00",
      ],
    ],
    [
      "a subtitle and a marker together",
      { caption: "s1", marker: "m1", playhead: 0 },
      [
        "[Nel montaggio video/gita.rgvideo, da 00:00:00:10 a 00:00:06:01 (fotogrammi 10-151 a 25 fps)]",
        "- sottotitolo s1, 00:00:00:10-00:00:02:10: «Buongiorno a tutti»",
        "- marcatore m1 a 00:00:06:00: più corto",
      ],
    ],
    [
      "a gap",
      { gap: { track: "V2", frame: 10 }, playhead: 0 },
      [
        "[Nel montaggio video/gita.rgvideo, da 00:00:00:00 a 00:00:01:00 (fotogrammi 0-25 a 25 fps)]",
        "- vuoto su V2, 00:00:00:00-00:00:01:00",
      ],
    ],
    [
      "words of the transcript",
      { words: [10, 35] as [number, number], playhead: 0 },
      [
        "[Nel montaggio video/gita.rgvideo, da 00:00:00:10 a 00:00:01:10 (fotogrammi 10-35 a 25 fps)]",
        "- parole: «Buongiorno»",
      ],
    ],
    [
      "nothing chosen: the moment under the playhead",
      { playhead: 42 },
      ["[Nel montaggio video/gita.rgvideo, a 00:00:01:17 (fotogramma 42)]"],
    ],
  ] as const)("%s", (_w, sel, want) => {
    expect(askHereContext(d, "video/gita.rgvideo", sel).text.split("\n")).toEqual(want);
  });

  it("in English too; the message is the question, then what it is about", () => {
    lang.value = "en";
    const c = askHereContext(d, "video/gita.rgvideo", { clips: ["b"], playhead: 0 });
    expect(c).toMatchObject({ from: 100, to: 200, items: 1 });
    expect(c.text).toBe(
      "[In the timeline video/gita.rgvideo, from 00:00:04:00 to 00:00:08:00 (frames 100-200 at 25 fps)]\n- clip b on V1: v/b.mp4, 00:00:04:00-00:00:08:00, from the file 00:00:02:00-00:00:06:00",
    );
    expect(askHereMessage("  Make it shorter ", c.text)).toBe(`Make it shorter\n\n${c.text}`);
  });
});

// ---- the player: crops and backdrops --------------------------------------------------------

function fakeEl(tag: "video" | "audio") {
  const el = document.createElement("div") as unknown as MediaLike &
    HTMLElement & { tag: string; paused: boolean };
  Object.assign(el, {
    tag,
    src: "",
    currentTime: 0,
    paused: true,
    playbackRate: 1,
    volume: 1,
    muted: false,
    preload: "",
    play() {
      el.paused = false;
      return Promise.resolve();
    },
    pause() {
      el.paused = true;
    },
    load() {},
  });
  return el;
}

describe("TimelinePlayer (A1)", () => {
  const MEDIA = {
    "v/a.mp4": { proxy: "/p/a.mp4", kind: "video" as const, width: 1920, height: 1080 },
    "v/b.mp4": { proxy: "/p/b.mp4", kind: "video" as const, width: 1920, height: 1080 },
    "f.jpg": { file: "/p/f.jpg", kind: "image" as const, width: 1920, height: 1080 },
  };
  const setup = (d: RgVideo) => {
    const stage = document.createElement("div");
    const made: ReturnType<typeof fakeEl>[] = [];
    const p = new TimelinePlayer({
      stage,
      audioBox: document.createElement("div"),
      media: (tag) => {
        const el = fakeEl(tag);
        made.push(el);
        return el;
      },
      now: () => 0,
      schedule: () => 1,
      cancel: () => {},
    });
    p.setDoc(d, MEDIA);
    const players = () => made.filter((m) => m.parentElement?.dataset.track === "V1");
    const backdrops = () => made.filter((m) => m.parentElement?.classList.contains("vp-bgs"));
    return { p, stage, players, backdrops };
  };

  it("a moved crop: the file placed by a transform and clipped; fitted on blur, a filled blurred copy under it", () => {
    const d = timeline();
    d.transitions = [];
    d.clips = [
      clip("a", "V1", 0, 100, "v/a.mp4", { crop: { x: 0, y: 0, w: 0.3164, h: 1 } }),
      clip("b", "V1", 100, 100, "v/b.mp4", { fit: "fit", background: "blur" }),
    ];
    const { p, players, backdrops } = setup(d);
    p.seek(10);
    const a = players().find((s) => s.style.opacity !== "0") as HTMLElement & MediaLike;
    expect(a.className).toBe("vp-video framed");
    expect(a.style.transform).toBe("translate(0.00000%, -0.00100%) scale(3.16056, 1.00002)");
    expect(a.style.clipPath).toBe("inset(0.000% 68.360% 0.000% 0.000%)");
    expect(backdrops()).toHaveLength(0);
    // fitted on a blurred copy: the picture whole, and under it its blurred, filled copy
    p.seek(150);
    const b = players().find((s) => s.style.opacity !== "0") as HTMLElement & MediaLike;
    expect(b.className).toBe("vp-video fit");
    const [bg] = backdrops();
    expect(bg?.className).toBe("vp-bg blur");
    expect(bg?.src).toBe("/p/b.mp4");
    expect(bg?.style.opacity).toBe("1");
    expect(bg?.style.filter).toMatch(/^blur\(calc\(var\(--side\) \* 0\.0259\)\)$/);
    expect(Number(bg?.style.zIndex)).toBeLessThan(Number(b.style.zIndex));
    expect(bg?.muted).toBe(true);
    // back on the first clip: the copy goes dark and stops
    p.seek(10);
    expect(backdrops()[0]?.style.opacity).toBe("0");
    expect(backdrops()[0]?.paused).toBe(true);
  });

  it("a picture fitted on black; its crop placed from its size", () => {
    const d = timeline();
    d.transitions = [];
    d.clips = [
      {
        ...clip("f", "V1", 0, 100, "f.jpg", { fit: "fit", background: "black" }),
        ref: { media: "f.jpg", still: true },
      },
      {
        ...clip("g", "V1", 100, 100, "f.jpg", { crop: { x: 0.6836, y: 0, w: 0.3164, h: 1 } }),
        ref: { media: "f.jpg", still: true },
      },
    ];
    const { p, stage } = setup(d);
    p.seek(5);
    const img = stage.querySelector<HTMLImageElement>('[data-track="V1"] > img.vp-picture.fit');
    expect(img?.style.opacity).toBe("1");
    const bg = stage.querySelector<HTMLImageElement>('[data-track="V1"] .vp-bgs img.vp-bg.black');
    expect(bg?.style.opacity).toBe("1");
    expect(bg?.style.filter).toBe("brightness(0)");
    p.seek(150);
    const framed = stage.querySelector<HTMLImageElement>(
      '[data-track="V1"] > img.vp-picture.framed',
    );
    expect(framed?.style.transform).toBe(
      "translate(-216.05560%, -0.00100%) scale(3.16056, 1.00002)",
    );
    expect(stage.querySelector<HTMLImageElement>(".vp-bgs img.vp-bg.black")?.style.opacity).toBe(
      "0",
    );
  });
});

// ---- the editor ---------------------------------------------------------------------------

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
const find = (d: RgVideo, id: string) => d.clips.find((c) => c.id === id) as VideoClip;
const byText = (root: ParentNode, sel: string, text: string) =>
  [...root.querySelectorAll<HTMLElement>(sel)].find(
    (b) => b.textContent?.trim() === text,
  ) as HTMLElement;
const switchOf = (root: ParentNode, label: string) => {
  const l = [...root.querySelectorAll("label.ui-toggle-label")].find(
    (x) => x.textContent === label,
  );
  return document.getElementById(l?.getAttribute("for") ?? "") as HTMLElement;
};
const tool = (root: ParentNode, label: string) =>
  root.querySelector(`.ve-bar button[aria-label^="${label}"]`) as HTMLElement;
const lastWhat = () => {
  const m = sentDoc.filter((x) => x.type === "doc.ops").at(-1) as { ops: DocOp[] } | undefined;
  const a = m?.ops[0]?.op as VideoAction | undefined;
  return a?.t === "batch" ? a.what : a?.t;
};

beforeEach(() => {
  for (const m of ["load", "pause"] as const)
    vi.spyOn(HTMLMediaElement.prototype, m).mockImplementation(() => {});
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(async () => {});
});

describe("G41.5d: the editor", () => {
  it("the timeline's own settings with nothing chosen: its shape and the loudness switch (A2)", async () => {
    const { r, host } = await open();
    const insp = r.container.querySelector(".ve-inspector") as HTMLElement;
    expect(insp.textContent).toContain("Questo montaggio");
    expect(insp.textContent).toContain("1080 x 1920 pixel");
    const loud = switchOf(insp, "Volume uniforme");
    expect(loud.getAttribute("aria-checked")).toBe("true");
    fireEvent.click(loud);
    expect(lastWhat()).toBe("format");
    expect(host.doc.normalize).toBe(false);
    await waitFor(() =>
      expect(switchOf(insp, "Volume uniforme").getAttribute("aria-checked")).toBe("false"),
    );
    fireEvent.click(switchOf(insp, "Volume uniforme"));
    expect(host.doc.normalize).toBeUndefined();
    fireEvent.click(byText(insp, ".wz-seg button", "1:1 quadrato"));
    expect(host.doc.format).toMatchObject({ width: 1080, height: 1080, aspect: "1:1" });
    expect(insp.querySelector("input[type=checkbox], input[type=radio], select")).toBeNull();
  });

  it("a wide clip in 9:16: around a fitted picture, and its crop moved with the arrows (A1)", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoEdit(KEY, { sel: ["a"] }));
    const insp = r.container.querySelector(".ve-inspector") as HTMLElement;
    // filled with no crop: the frame starts at the centre, dashed
    const rect = await waitFor(() => {
      const el = insp.querySelector(".ve-crop-rect") as HTMLElement;
      expect(el).toBeTruthy();
      return el;
    });
    expect(rect.classList.contains("auto")).toBe(true);
    expect(rect.style.left).toBe("34.2%");
    fireEvent.keyDown(rect, { key: "ArrowRight" });
    expect(lastWhat()).toBe("props");
    expect(find(host.doc, "a").crop).toEqual({ x: 0.3518, y: 0, w: 0.3164, h: 1 });
    fireEvent.keyDown(insp.querySelector(".ve-crop-rect") as HTMLElement, {
      key: "ArrowLeft",
      shiftKey: true,
    });
    expect(find(host.doc, "a").crop).toEqual({ x: 0.2518, y: 0, w: 0.3164, h: 1 });
    // the playhead stays where it was
    expect(state.videoViewOf(KEY).frame).toBe(0);
    fireEvent.click(byText(insp, "button", "Togli il ritaglio"));
    expect(find(host.doc, "a").crop).toBeUndefined();
    fireEvent.click(byText(insp, "button", "Al centro"));
    expect(find(host.doc, "a").crop).toEqual({ x: 0.3418, y: 0, w: 0.3164, h: 1 });
    // fitted: nothing, black or blurred around it
    expect(byText(insp, ".wz-seg button", "Sfocato")).toBeUndefined();
    fireEvent.click(byText(insp, ".wz-seg button", "Adatta (tutta l'immagine)"));
    fireEvent.click(byText(insp, ".wz-seg button", "Sfocato"));
    expect(find(host.doc, "a")).toMatchObject({ fit: "fit", background: "blur" });
    fireEvent.click(byText(insp, ".wz-seg button", "Niente"));
    expect(find(host.doc, "a").background).toBeUndefined();
  });

  it("the crop dragged on the miniature: one edit when let go", async () => {
    const { r, host } = await open();
    await act(async () => state.setVideoEdit(KEY, { sel: ["a"] }));
    const insp = r.container.querySelector(".ve-inspector") as HTMLElement;
    const box = insp.querySelector(".ve-crop-thumb") as HTMLElement;
    Object.defineProperty(box, "clientWidth", { value: 200 });
    Object.defineProperty(box, "clientHeight", { value: 112 });
    const before = sentDoc.length;
    fireEvent.pointerDown(insp.querySelector(".ve-crop-rect") as HTMLElement, {
      clientX: 100,
      clientY: 50,
      pointerId: 1,
    });
    fireEvent.pointerMove(box, { clientX: 140, clientY: 50, pointerId: 1 });
    fireEvent.pointerMove(box, { clientX: 300, clientY: 50, pointerId: 1 });
    expect(sentDoc.length).toBe(before);
    fireEvent.pointerUp(box, { clientX: 300, clientY: 50, pointerId: 1 });
    expect(find(host.doc, "a").crop).toEqual({ x: 0.6836, y: 0, w: 0.3164, h: 1 });
  });

  it("«Chiedi all'agente qui»: the chosen clip's times and ids go with the question (A4)", async () => {
    const onAsk = vi.fn((_text: string) => ({ to: "Montatore" }) as { to: string } | undefined);
    const { r } = await open(timeline(), onAsk);
    await act(async () => state.setVideoEdit(KEY, { sel: ["b"] }));
    fireEvent.click(tool(r.container, "Chiedi all'agente qui"));
    const panel = await waitFor(() => {
      const el = r.container.querySelector(".ve-ask") as HTMLElement;
      expect(el).toBeTruthy();
      return el;
    });
    expect(panel.querySelector(".ve-ask-ctx")?.textContent).toContain("clip b su V1: v/b.mp4");
    const send = byText(panel, "button", "Manda");
    expect(send.hasAttribute("disabled")).toBe(true);
    const box = panel.querySelector("textarea") as HTMLTextAreaElement;
    fireEvent.input(box, { target: { value: "Accorcia questa parte" } });
    // the editor's keys stay out of the box (Delete would remove the clip)
    fireEvent.keyDown(box, { key: "Delete" });
    expect(sentDoc.some((m) => m.type === "doc.ops")).toBe(false);
    fireEvent.keyDown(box, { key: "Enter", ctrlKey: true });
    expect(onAsk).toHaveBeenCalledTimes(1);
    const msg = onAsk.mock.calls[0]?.[0] as string;
    expect(
      msg.startsWith("Accorcia questa parte\n\n[Nel montaggio video/gita.rgvideo, da 00:00:04:00"),
    ).toBe(true);
    expect(msg).toContain("- clip b su V1: v/b.mp4");
    await waitFor(() => expect(r.container.querySelector(".ve-ask")).toBeNull());
    expect(r.container.querySelector(".ve-notice")?.textContent).toBe("Mandato a Montatore.");
    // nowhere to send it: said, and the question stays
    onAsk.mockReturnValueOnce(undefined);
    fireEvent.click(tool(r.container, "Chiedi all'agente qui"));
    const box2 = (await waitFor(() =>
      r.container.querySelector(".ve-ask textarea"),
    )) as HTMLTextAreaElement;
    fireEvent.input(box2, { target: { value: "Ancora" } });
    fireEvent.click(byText(r.container.querySelector(".ve-ask") as HTMLElement, "button", "Manda"));
    await waitFor(() =>
      expect(r.container.querySelector(".ve-notice")?.textContent).toBe(
        "Apri prima una conversazione con un agente: la domanda va lì.",
      ),
    );
    expect(r.container.querySelector(".ve-ask")).toBeTruthy();
  });

  it("the versions: listed, one saved with a name, one brought back after the present is kept (A5)", async () => {
    const old = timeline();
    old.clips = old.clips.filter((c) => c.id !== "b");
    old.transitions = [];
    old.version = {
      name: "Corta",
      at: "2026-11-16T15:30:00.000Z",
      of: file.path,
      reason: "manual",
    };
    const list = [
      {
        path: "video/gita.versions/2026-11-16 1600 x.rgvideo",
        name: "x",
        at: "2026-11-16T16:00:00.000Z",
        reason: "before_assemble",
        clips: 4,
      },
      {
        path: "video/gita.versions/2026-11-16 1530 Corta.rgvideo",
        name: "Corta",
        at: "2026-11-16T15:30:00.000Z",
        reason: "manual",
        clips: 3,
      },
    ];
    const { r, host } = await open();
    handlers.videoVersions = () => ({ versions: list });
    handlers.videoVersionSave = (_s: unknown, _p: unknown, name: unknown) => ({
      version: { name },
    });
    handlers.videoVersionRead = () => ({ doc: old });
    fireEvent.click(tool(r.container, "Versioni"));
    const panel = await waitFor(() => {
      const el = r.container.querySelector(".ve-versions") as HTMLElement;
      expect(el.querySelectorAll(".ve-version")).toHaveLength(2);
      return el;
    });
    const names = [...panel.querySelectorAll(".ve-version strong")].map((x) => x.textContent);
    expect(names).toEqual(["Prima del montaggio automatico", "Corta"]);
    expect(panel.textContent).toContain("3 clip");
    // saved with the name asked for
    fireEvent.click(byText(panel, "button", "Salva una versione"));
    await waitFor(() =>
      expect(calls.some(([n, a]) => n === "videoVersionSave" && a[2] === "Bozza per Marco")).toBe(
        true,
      ),
    );
    // brought back: first the present one, then the version's timeline as one edit
    calls.length = 0;
    const restore = [...panel.querySelectorAll<HTMLElement>(".ve-version")][1]?.querySelector(
      "button",
    ) as HTMLElement;
    fireEvent.click(restore);
    await waitFor(() => expect(host.doc.clips.map((c) => c.id)).not.toContain("b"));
    expect(calls.map(([n]) => n).filter((n) => n.startsWith("videoVersion"))).toEqual([
      "videoVersionSave",
      "videoVersionRead",
      "videoVersions",
    ]);
    expect(calls[0]?.[1][2]).toBe("Prima di riprendere «Corta»");
    expect(lastWhat()).toBe("replace");
    expect(host.doc.version).toBeUndefined();
    // said no: nothing changes
    asked.confirm = false;
    calls.length = 0;
    fireEvent.click(restore);
    await new Promise((ok) => setTimeout(ok, 20));
    expect(calls.some(([n]) => n === "videoVersionRead")).toBe(false);
    asked.confirm = true;
    expect(PERSON).toBeTruthy();
  });
});
