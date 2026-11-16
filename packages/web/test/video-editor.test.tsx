// @vitest-environment jsdom
// G41.5b: the timeline editor's page side. The pure parts (the page's own ids, Resolve's keys as a
// table, J/K/L, the ruler, snapping a block, edges, gaps, a file's reference, the panel's words),
// the queue meeting others' revisions on the server's own family, and the editor in the canvas
// with a small host built on that family: moving (also to another track), trimming (Alt: one side,
// a J/L-cut), the blade, deleting with and without closing, a chosen gap closed, linking, snapping,
// copy and paste, markers, a locked track, the marquee, a file dropped from the project's tree,
// the source viewer with In/Out and F10, undo, an agent's change highlighted, the shortcuts' list.
import {
  checkVideoAction,
  type DocChange,
  type DocOp,
  type DocSummary,
  newRgVideo,
  PERSON,
  type RgVideo,
  type VideoAction,
  type VideoClip,
  type VideoMediaInfo,
  videoIdGen,
} from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { videoFamily } from "../../server/src/editor/video-family.js";
import { lang } from "../src/i18n.js";
import type { DocPeer } from "../src/state.js";
import {
  edgeAt,
  editAction,
  gapAt,
  mediaRefOf,
  PageIds,
  rulerTicks,
  shuttleRate,
  snapBlock,
  touchedIds,
  VIDEO_KEYS,
  VideoCollab,
  type VideoOutgoing,
  videoChangeText,
  videoKey,
} from "../src/viewers/video-ops.js";

// jsdom has no PointerEvent: a mouse event with a pointer's id is enough here.
if (!("PointerEvent" in window)) {
  class PointerEventLike extends MouseEvent {
    pointerId: number;
    constructor(type: string, init: PointerEventInit = {}) {
      super(type, init);
      this.pointerId = init.pointerId ?? 1;
    }
  }
  Object.assign(window, { PointerEvent: PointerEventLike });
}
// Nor DragEvent: a mouse event that carries the drag's data.
if (!("DragEvent" in window)) {
  class DragEventLike extends MouseEvent {
    dataTransfer: DataTransfer | null;
    constructor(type: string, init: DragEventInit = {}) {
      super(type, init);
      this.dataTransfer = init.dataTransfer ?? null;
    }
  }
  Object.assign(window, { DragEvent: DragEventLike });
}

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
  const d = newRgVideo({ width: 1280, height: 720, rate: R, aspect: "16:9" });
  d.tracks = [
    { id: "V1", kind: "Video", name: "V1", locked: false },
    { id: "V2", kind: "Video", name: "V2", locked: false },
    { id: "A1", kind: "Audio", name: "Voce", locked: false },
    { id: "A2", kind: "Audio", name: "Musica", locked: false },
  ];
  d.clips = [
    clip("a", "V1", 0, 100, "v/a.mp4", { link: "g1" }),
    clip("b", "V1", 150, 100, "v/b.mp4", { link: "g2", sourceRange: { start: 50, duration: 100 } }),
    clip("va", "A1", 0, 100, "v/a.mp4", { link: "g1" }),
    clip("vb", "A1", 150, 100, "v/b.mp4", {
      link: "g2",
      sourceRange: { start: 50, duration: 100 },
    }),
    clip("m", "A2", 0, 300, "v/music.m4a"),
  ];
  return d;
}

const op = (a: VideoAction): DocOp => ({
  family: "video",
  engine: "rgvideo",
  engineVersion: "1",
  op: a,
});

beforeEach(() => {
  lang.value = "it";
});
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

// ---- the pure parts -------------------------------------------------------------------------

describe("the page's ids", () => {
  it("never the agents' c<n>, never one the timeline has; another page another tag", () => {
    const d = timeline();
    d.clips.push(clip("c_px1", "V2", 0, 10, "v/a.mp4"));
    const ids = new PageIds("px");
    const gen = ids.for(d);
    const made = [gen("c"), gen("c"), gen("g")];
    expect(made).toEqual(["c_px2", "c_px3", "g_px4"]);
    for (const id of made) expect(id).not.toMatch(/^[a-z]+\d+$/);
    // The server's own generator ignores them: an agent's next clip is still c1.
    const withPage = structuredClone(d);
    withPage.clips.push(clip(made[0] as string, "V2", 20, 10, "v/a.mp4"));
    expect(videoIdGen(withPage)("c")).toBe("c1");
    expect(new PageIds().tag).not.toBe(new PageIds().tag);
    // The counter goes on across edits.
    expect(ids.for(d)("c")).toBe("c_px5");
  });
});

describe("Resolve's keys", () => {
  const rows: [Parameters<typeof videoKey>[0], string | undefined][] = [
    [{ key: " " }, "play"],
    [{ key: "j" }, "reverse"],
    [{ key: "K" }, "stop"],
    [{ key: "l" }, "forward"],
    [{ key: "ArrowLeft" }, "prevFrame"],
    [{ key: "ArrowRight", shiftKey: true }, "nextSecond"],
    [{ key: "ArrowUp" }, "prevEdit"],
    [{ key: "ArrowDown" }, "nextEdit"],
    [{ key: "Home" }, "home"],
    [{ key: "End" }, "end"],
    [{ key: "b", ctrlKey: true }, "blade"],
    [{ key: "b", metaKey: true }, "blade"],
    [{ key: "b" }, "toolBlade"],
    [{ key: "a" }, "toolSelect"],
    [{ key: "t" }, "toolTrim"],
    [{ key: "Backspace" }, "lift"],
    [{ key: "Delete" }, "ripple"],
    [{ key: "z", ctrlKey: true }, "undo"],
    [{ key: "Z", ctrlKey: true, shiftKey: true }, "redo"],
    [{ key: "y", ctrlKey: true }, "redo"],
    [{ key: "c", ctrlKey: true }, "copy"],
    [{ key: "v", ctrlKey: true }, "paste"],
    [{ key: "a", ctrlKey: true }, "selectAll"],
    [{ key: "l", ctrlKey: true, altKey: true }, "link"],
    [{ key: "L", ctrlKey: true, shiftKey: true }, "linkedSel"],
    [{ key: "m" }, "marker"],
    [{ key: "d" }, "enable"],
    [{ key: "n" }, "snap"],
    [{ key: "i" }, "markIn"],
    [{ key: "o" }, "markOut"],
    [{ key: "+" }, "zoomIn"],
    [{ key: "-" }, "zoomOut"],
    [{ key: "Z", shiftKey: true }, "fit"],
    [{ key: "F9" }, "insert"],
    [{ key: "F10" }, "overwrite"],
    [{ key: "F12", shiftKey: true }, "append"],
    [{ key: "F12" }, undefined],
    [{ key: "s", ctrlKey: true }, "save"],
    [{ key: "Escape" }, "escape"],
    [{ key: "?" }, "help"],
    [{ key: "," }, "nudgeLeft"],
    [{ key: "." }, "nudgeRight"],
    [{ key: "{" }, "trimStart"],
    [{ key: "]", shiftKey: true }, "trimEnd"],
    [{ key: "V", shiftKey: true }, "selectAtPlayhead"],
    [{ key: "x" }, undefined],
    [{ key: "j", altKey: true }, undefined],
  ];
  it.each(rows)("%j → %s", (e, cmd) => expect(videoKey(e)).toBe(cmd));

  it("every key of the list has its words in both languages", async () => {
    const { dictionaries } = await import("../src/i18n.js");
    for (const k of VIDEO_KEYS) {
      expect(dictionaries.it[k.what]).toBeTruthy();
      expect(dictionaries.en[k.what]).toBeTruthy();
    }
  });

  it("J/K/L: again doubles up to 8×, the other way starts over", () => {
    let r = 0;
    let playing = false;
    const seen: number[] = [];
    for (let i = 0; i < 5; i++) {
      r = shuttleRate(playing, r, "forward");
      playing = true;
      seen.push(r);
    }
    expect(seen).toEqual([1, 2, 4, 8, 8]);
    expect(shuttleRate(true, 4, "reverse")).toBe(-1);
    expect(shuttleRate(true, -2, "reverse")).toBe(-4);
  });
});

describe("geometry", () => {
  it("the ruler: timecodes at least minPx apart, frames when zoomed in", () => {
    const wide = rulerTicks(1, R, 500, 96);
    const major = wide.filter((x) => !x.minor);
    expect(major[0]).toEqual({ frame: 0, label: "00:00:00:00" });
    expect(major[1]?.frame).toBe(125); // 5 s: the first step of at least 96 px at 1 px a frame
    expect(major[1]?.label).toBe("00:00:05:00");
    const close = rulerTicks(20, R, 50, 96).filter((x) => !x.minor);
    expect(close[1]).toEqual({ frame: 5, label: "00:00:00:05" });
    // Small marks between labels when there is room.
    expect(rulerTicks(40, R, 50, 96).some((x) => x.minor)).toBe(true);
  });

  it("snapping a block: the nearer of its edges to a point", () => {
    const d = timeline();
    // "a" (0-100) moved by 45: its end at 145 snaps to "b"'s start at 150.
    expect(snapBlock(d, new Set(["a", "va"]), 45, 0, 10)).toBe(50);
    // Too far: as it is.
    expect(snapBlock(d, new Set(["a", "va"]), 30, 0, 10)).toBe(30);
    // The playhead counts.
    expect(snapBlock(d, new Set(["a", "va"]), 26, 22, 5)).toBe(22);
  });

  it("edges, gaps", () => {
    expect(edgeAt(102, 100, 200)).toBe("in");
    expect(edgeAt(296, 100, 200)).toBe("out");
    expect(edgeAt(200, 100, 200)).toBeUndefined();
    // A narrow clip keeps a body in the middle.
    expect(edgeAt(105, 100, 9)).toBeUndefined();
    const d = timeline();
    expect(gapAt(d, "V1", 120)).toEqual([100, 150]);
    expect(gapAt(d, "V1", 50)).toBeUndefined();
    expect(gapAt(d, "V1", 400)).toBeUndefined();
    expect(gapAt(d, "V2", 10)).toBeUndefined();
  });

  it("a file's reference from what the server read", () => {
    const probe = {
      kind: "video" as const,
      duration: 4,
      width: 1920,
      height: 1080,
      rotation: 0,
      rate: R,
      codec: "h264",
      audio: false,
      audioCodec: null,
      sampleRate: null,
      channels: null,
      timecode: null,
      createdAt: null,
      size: 1,
    };
    const info: VideoMediaInfo = { media: "v/x.mp4", probe, jobs: [] };
    expect(mediaRefOf(info, "v/x.mp4", { num: 30000, den: 1001 })).toEqual({
      media: "v/x.mp4",
      frames: 120,
      audio: false,
    });
    expect(mediaRefOf(undefined, "v/foto.JPG", R)).toEqual({ media: "v/foto.JPG", still: true });
    expect(mediaRefOf({ media: "v/x.mp4", jobs: ["j"] }, "v/x.mp4", R)).toBeUndefined();
  });
});

describe("words", () => {
  const s = (video: DocSummary["video"]): DocSummary => ({ text: "x", kind: "edit", video });
  it("each edit in Italian and English", () => {
    expect(videoChangeText(s({ action: "move", n: 2 }))).toBe("Spostate 2 clip");
    expect(videoChangeText(s({ action: "blade", n: 2, added: 1 }))).toBe(
      "Tagliata una clip in due",
    );
    expect(videoChangeText(s({ action: "ripple_delete", n: 2, removed: 2 }))).toBe(
      "Cancellate 2 clip e chiuso il vuoto",
    );
    expect(videoChangeText(s({ action: "overwrite", n: 2, added: 2 }))).toBe("Messe 2 clip");
    expect(videoChangeText(s({ action: "add_track", n: 1, id: "V3" }))).toBe(
      "Aggiunta la traccia V3",
    );
    lang.value = "en";
    expect(videoChangeText(s({ action: "trim", n: 1 }))).toBe("Trimmed a clip");
    expect(videoChangeText(s({ action: "close_gap", n: 3 }))).toBe("Closed a gap");
  });
});

// ---- the queue on the server's own family ---------------------------------------------------

/** The host in a few lines, on the server's video family: check, apply, ack or refuse. */
class MiniHost {
  doc: RgVideo;
  revision = 0;
  history: { before: RgVideo; op: DocOp; author: string }[] = [];
  constructor(d: RgVideo) {
    this.doc = d;
  }
  apply(ops: readonly DocOp[], author = PERSON): string | undefined {
    for (const o of ops) {
      const bad = videoFamily.check({ doc: this.doc }, o);
      if (bad) return bad;
      this.history.push({ before: this.doc, op: o, author });
      this.doc = videoFamily.apply({ doc: this.doc }, o).doc;
    }
    this.revision++;
    return undefined;
  }
}

describe("VideoCollab", () => {
  it("the person moves a clip while an agent trims another: the same timeline at both ends", async () => {
    const { applyVideoAction, moveClips, trimClip } = await import("@redgiant/protocol");
    const host = new MiniHost(timeline());
    const sent: VideoOutgoing[] = [];
    const collab = new VideoCollab((o) => sent.push(o));
    collab.reset(0);
    let page = timeline();
    const ids = new PageIds("pp");
    // The person's move, sent at once.
    const moved = moveClips(page, ["a"], 10, 0, { ids: ids.for(page) });
    collab.local(editAction(page, moved, "move") as VideoAction);
    page = moved;
    expect(sent).toHaveLength(1);
    // The agent's trim reaches the host first.
    const agentDoc = trimClip(host.doc, "b", "out", -20);
    const agentAction = editAction(host.doc, agentDoc, "trim") as VideoAction;
    expect(host.apply([op(agentAction)], "agent")).toBeUndefined();
    expect(collab.remote(1, [agentAction])).toBe("apply");
    page = applyVideoAction(page, agentAction);
    // Then the person's (made on revision 0: positions are absolute, no conflict).
    const mine = sent[0] as VideoOutgoing;
    expect(mine.baseRevision).toBe(0);
    expect(host.apply(mine.actions.map(op))).toBeUndefined();
    expect(collab.ack(mine.clientId, 2)).toBe(true);
    expect(page).toEqual(host.doc);
  });

  it("an agent's change to the clip the person is moving: the page reads the timeline again", async () => {
    const { moveClips } = await import("@redgiant/protocol");
    const collab = new VideoCollab(() => {});
    collab.reset(3);
    const d = timeline();
    collab.local(editAction(d, moveClips(d, ["a"], 5), "move") as VideoAction);
    const theirs = editAction(d, moveClips(d, ["a"], -0), "move");
    expect(theirs).toBeUndefined();
    const agent = {
      t: "clip" as const,
      id: "a",
      value: { ...(d.clips[0] as VideoClip), volume: -3 },
    };
    expect(collab.remote(4, [agent])).toBe("reload");
    // Not the next revision: again.
    const c2 = new VideoCollab(() => {});
    c2.reset(1);
    expect(c2.remote(3, [agent])).toBe("reload");
    expect(touchedIds([agent])).toEqual(new Set(["a"]));
  });
});

// ---- the editor in the canvas ---------------------------------------------------------------

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
const { VideoEditor, HEAD_W, FILE_TYPE } = await import("../src/components/viewers/VideoEditor.js");
const state = await import("../src/state.js");

const file = { scope: "p1", path: "video/film.rgvideo" };
const KEY = `${file.scope}:${file.path}`;

const probe = (duration: number, audio = true) => ({
  kind: "video" as const,
  duration,
  width: 1280,
  height: 720,
  rotation: 0,
  rate: R,
  codec: "h264",
  audio,
  audioCodec: audio ? "aac" : null,
  sampleRate: null,
  channels: null,
  timecode: null,
  createdAt: null,
  size: 1,
});

/** The editor opened on a small host: the page's ops checked and applied by the family. */
async function open(d = timeline()) {
  const host = new MiniHost(d);
  sentDoc.length = 0;
  calls.length = 0;
  handlers = {
    videoPrepare: (...args: unknown[]) => ({
      media: [
        ...["v/a.mp4", "v/b.mp4", "v/music.m4a", ...((args[2] as string[] | undefined) ?? [])].map(
          (m) => ({
            media: m,
            kind: m.endsWith(".m4a") ? "audio" : "video",
            probe: { ...probe(16), ...(m.endsWith(".m4a") && { kind: "audio" as const }) },
            file: `/preview/x/${m}`,
            jobs: [],
          }),
        ),
      ],
      fonts: { regular: "/r.ttf", bold: "/b.ttf" },
    }),
  };
  onSend = (m) => {
    if (m.type === "doc.ops") {
      const bad = host.apply(m.ops as DocOp[]);
      if (bad) throw new Error(`refused: ${bad} ${JSON.stringify(m.ops)}`);
      peer?.ack({
        type: "doc.ack",
        file,
        clientId: m.clientId as string,
        revision: host.revision,
      } as never);
    }
    if (m.type === "doc.undo") {
      const last = host.history.pop();
      if (!last) return;
      const inverse = videoFamily.invert({ doc: last.before }, last.op);
      host.doc = last.before;
      host.revision++;
      peer?.changed({
        type: "doc.changed",
        file,
        revision: host.revision,
        ops: [inverse],
        change: change(host.revision, PERSON, { undoOf: [m.revision as number] }),
      } as never);
    }
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
  });
  state.setVideoView(KEY, { frame: 0, playing: false });
  const r = render(<VideoEditor file={file} />);
  await act(async () => peer?.opened({ family: "video", doc: d }, 0));
  await waitFor(() => r.container.querySelector("[data-clip=a]"));
  return { r, host, el: (sel: string) => r.container.querySelector(sel) as HTMLElement };
}
const change = (revision: number, author: string, more: Partial<DocChange> = {}): DocChange => ({
  revision,
  ts: new Date().toISOString(),
  author,
  groupId: `g${revision}`,
  summary: { text: "x", kind: "edit" },
  ...more,
});
const x = (frame: number) => HEAD_W + frame; // ppf 1, the rows at the page's left
const lastOps = () =>
  sentDoc.filter((m) => m.type === "doc.ops").at(-1) as { ops: DocOp[] } | undefined;
const whatOf = (m: { ops: DocOp[] } | undefined) => {
  const a = m?.ops[0]?.op as VideoAction | undefined;
  return a?.t === "batch" ? a.what : a?.t;
};
const find = (d: RgVideo, id: string) => d.clips.find((c) => c.id === id) as VideoClip;

beforeEach(() => {
  for (const m of ["load", "pause"] as const)
    vi.spyOn(HTMLMediaElement.prototype, m).mockImplementation(() => {});
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(async () => {});
  // Clips where their style puts them; rows one under the other (the rows' own box at 0).
  vi.spyOn(Element.prototype, "getBoundingClientRect").mockImplementation(function (this: Element) {
    const el = this as HTMLElement;
    if (el.dataset?.clip) {
      const row = el.closest(".ve-row");
      const rowsEl = el.closest(".ve-rows");
      const i = rowsEl ? Array.from(rowsEl.querySelectorAll(".ve-row")).indexOf(row as Element) : 0;
      const left = HEAD_W + Number.parseFloat(el.style.left);
      const width = Number.parseFloat(el.style.width);
      return {
        left,
        width,
        right: left + width,
        top: i * 50 + 3,
        bottom: i * 50 + 47,
        height: 44,
        x: left,
        y: i * 50,
      } as DOMRect;
    }
    return { left: 0, top: 0, right: 0, bottom: 0, width: 0, height: 0, x: 0, y: 0 } as DOMRect;
  });
});

const press = (el: Element, clientX: number, more: PointerEventInit = {}) =>
  fireEvent.pointerDown(el, { button: 0, clientX, clientY: 10, ...more });
const moveTo = (clientX: number, clientY = 10) =>
  fireEvent.pointerMove(window, { clientX, clientY });
const release = (clientX: number) => fireEvent.pointerUp(window, { clientX });
const key = (el: Element, k: string, more: KeyboardEventInit = {}) =>
  fireEvent.keyDown(el, { key: k, ...more });

describe("VideoEditor", () => {
  it("draws the tracks from the top (V2, V1, A1, A2) with their clips, the files of this edit", async () => {
    const { r } = await open();
    const heads = [...r.container.querySelectorAll(".ve-target")].map((b) => b.textContent);
    expect(heads).toEqual(["V2", "V1", "A1", "A2"]);
    expect(r.container.querySelector("[data-clip=a]")?.getAttribute("aria-label")).toBe(
      "a.mp4, traccia V1, a 00:00:00:00, lunga 00:00:04:00",
    );
    const pool = [...r.container.querySelectorAll(".ve-pool-item")].map((b) => b.textContent);
    expect(pool).toEqual(["a.mp4", "b.mp4", "music.m4a"]);
    expect(calls.some(([n]) => n === "videoPrepare")).toBe(true);
  });

  it("moves a clip with its linked sound; to another track only the picture changes track", async () => {
    const { el, host } = await open();
    press(el("[data-clip=a]"), x(50));
    moveTo(x(70));
    release(x(70));
    expect(whatOf(lastOps())).toBe("move");
    expect(find(host.doc, "a").start).toBe(20);
    expect(find(host.doc, "va").start).toBe(20);
    // Onto V2: the lane under the pointer.
    const v2 = el("[data-lane=V2]");
    document.elementFromPoint = () => v2;
    press(el("[data-clip=a]"), x(70));
    moveTo(x(70), 5);
    moveTo(x(71), 5);
    release(x(71));
    expect(find(host.doc, "a").track).toBe("V2");
    expect(find(host.doc, "va").track).toBe("A1");
    (document as { elementFromPoint?: unknown }).elementFromPoint = undefined;
  });

  it("trims an edge, the linked sound too; with Alt only the picture (an L-cut)", async () => {
    const { el, host } = await open();
    // The out edge of "b" (150-250), 3 px inside it.
    press(el("[data-clip=b]"), x(247));
    moveTo(x(227));
    release(x(227));
    expect(whatOf(lastOps())).toBe("trim");
    expect(find(host.doc, "b").sourceRange.duration).toBe(80);
    expect(find(host.doc, "vb").sourceRange.duration).toBe(80);
    press(el("[data-clip=b]"), x(227), { altKey: true });
    moveTo(x(207), 10);
    release(x(207));
    expect(find(host.doc, "b").sourceRange.duration).toBe(60);
    expect(find(host.doc, "vb").sourceRange.duration).toBe(80);
  });

  it("ripple trim (T): what follows moves to close the space", async () => {
    const { el, host, r } = await open();
    key(r.container.querySelector(".ve") as Element, "t");
    press(el("[data-clip=a]"), x(97));
    moveTo(x(77));
    release(x(77));
    expect(whatOf(lastOps())).toBe("ripple_trim");
    expect(find(host.doc, "a").sourceRange.duration).toBe(80);
    expect(find(host.doc, "b").start).toBe(130);
  });

  it("the blade (B) cuts where clicked, with ids of the page's own; Ctrl+B at the cursor", async () => {
    const { el, host, r } = await open();
    const root = r.container.querySelector(".ve") as Element;
    key(root, "b");
    press(el("[data-clip=a]"), x(40));
    release(x(40));
    expect(whatOf(lastOps())).toBe("blade");
    const right = host.doc.clips.filter((c) => c.track === "V1" && c.start === 40);
    expect(right).toHaveLength(1);
    expect(right[0]?.id).toMatch(/^c_p[a-z0-9]+\d+$/);
    expect(host.doc.clips.filter((c) => c.track === "A1" && c.start === 40)).toHaveLength(1);
    // Ctrl+B at the cursor, nothing chosen: every unlocked track.
    key(root, "a");
    await act(async () => {
      state.setVideoView(KEY, { frame: 200 });
    });
    key(root, "b", { ctrlKey: true });
    expect(
      host.doc.clips
        .filter((c) => c.start === 200)
        .map((c) => c.track)
        .sort(),
    ).toEqual(["A1", "A2", "V1"]);
  });

  it("Backspace leaves the gap, Delete closes it; a chosen gap closes with Delete", async () => {
    const { el, host, r } = await open();
    const root = r.container.querySelector(".ve") as Element;
    press(el("[data-clip=a]"), x(50));
    release(x(50));
    key(root, "Backspace");
    expect(whatOf(lastOps())).toBe("lift");
    expect(host.doc.clips.map((c) => c.id).sort()).toEqual(["b", "m", "vb"]);
    // The gap before "b" on V1 (0-150), chosen with a click, closed with Delete.
    press(el("[data-lane=V1]"), x(60));
    release(x(60));
    expect(r.container.querySelector(".ve-gap")).toBeTruthy();
    key(root, "Delete");
    expect(whatOf(lastOps())).toBe("close_gap");
    expect(find(host.doc, "b").start).toBe(0);
    // Delete on a clip: it goes and what follows closes up.
    press(el("[data-clip=b]"), x(50));
    release(x(50));
    key(root, "Delete");
    expect(whatOf(lastOps())).toBe("ripple_delete");
    expect(host.doc.clips.map((c) => c.id)).toEqual(["m"]);
  });

  it("unlink and link (Ctrl+Alt+L), snapping (N), copy and paste at the cursor", async () => {
    const { el, host, r } = await open();
    const root = r.container.querySelector(".ve") as Element;
    press(el("[data-clip=a]"), x(50));
    release(x(50));
    key(root, "l", { ctrlKey: true, altKey: true });
    expect(whatOf(lastOps())).toBe("unlink");
    expect(find(host.doc, "a").link).toBeUndefined();
    expect(r.container.querySelector(".ve-notice")?.textContent).toMatch(/scollegate/);
    key(root, "n");
    expect(state.videoEditOf(KEY).snapping).toBe(false);
    expect(r.container.querySelector(".ve-notice")?.textContent).toBe("Aggancio disattivo");
    // Copy "a" and its sound (chosen, not linked now), paste at 260.
    key(root, "c", { ctrlKey: true });
    await act(async () => {
      state.setVideoView(KEY, { frame: 260 });
    });
    key(root, "v", { ctrlKey: true });
    expect(whatOf(lastOps())).toBe("paste");
    const pasted = host.doc.clips.filter((c) => c.start === 260);
    expect(pasted.map((c) => c.track).sort()).toEqual(["A1", "V1"]);
    expect(pasted[0]?.id).toMatch(/^c_p/);
  });

  it("a marker at the cursor (M); a locked track does not move", async () => {
    const { el, host, r } = await open();
    const root = r.container.querySelector(".ve") as Element;
    await act(async () => {
      state.setVideoView(KEY, { frame: 30 });
    });
    key(root, "m");
    expect(host.doc.markers.map((m) => m.frame)).toEqual([30]);
    expect(host.doc.markers[0]?.id).toMatch(/^m_p/);
    await waitFor(() => expect(r.container.querySelector(".ve-marker")).toBeTruthy());
    // Lock V1 from its header.
    const lock = r.container
      .querySelectorAll<HTMLElement>(".ve-row")[2]
      ?.querySelector("[aria-label='Blocca la traccia']") as HTMLElement;
    fireEvent.click(lock);
    expect(host.doc.tracks.find((t) => t.id === "V1")?.locked).toBe(true);
    const before = host.revision;
    press(el("[data-clip=a]"), x(50));
    moveTo(x(90));
    release(x(90));
    expect(host.revision).toBe(before);
    expect(r.container.querySelector(".ve-notice")?.textContent).toBe("La traccia V1 è bloccata.");
  });

  it("the marquee chooses the clips it touches", async () => {
    const { el, r } = await open();
    // From an empty place of V2 (row 1) down to A1 (row 3), across frames 120-160.
    press(el("[data-lane=V2]"), x(120), { clientY: 60 });
    moveTo(x(160), 160);
    release(x(160));
    expect(state.videoEditOf(KEY).sel.sort()).toEqual(["b", "vb"]);
    expect(r.container.querySelectorAll(".ve-clip.sel")).toHaveLength(2);
  });

  it("a file dropped from the project's tree: read first, then placed with its sound", async () => {
    const { el, host } = await open();
    const data = new Map<string, string>([
      [FILE_TYPE, JSON.stringify({ scope: "p1", path: "v/new.mp4" })],
    ]);
    const dataTransfer = {
      types: [FILE_TYPE],
      getData: (k: string) => data.get(k) ?? "",
      dropEffect: "none",
    };
    fireEvent.dragOver(el("[data-lane=V2]"), { clientX: x(300), dataTransfer });
    fireEvent.drop(el("[data-lane=V2]"), { clientX: x(300), dataTransfer });
    await waitFor(() => expect(host.doc.clips.some((c) => isNew(c))).toBe(true));
    const added = host.doc.clips.filter(isNew);
    expect(added.map((c) => [c.track, c.start, c.sourceRange.duration]).sort()).toEqual([
      ["A2", 300, 400],
      ["V2", 300, 400],
    ]);
    expect(whatOf(lastOps())).toBe("overwrite");
    expect(
      calls.some(([n, a]) => n === "videoPrepare" && (a[2] as string[])?.includes("v/new.mp4")),
    ).toBe(true);
  });

  it("the source viewer: In and Out with I/O, then F10 at the cursor on the destinations", async () => {
    const { r, host } = await open();
    const root = r.container.querySelector(".ve") as Element;
    fireEvent.click([...r.container.querySelectorAll(".ve-pool-item")][1] as Element);
    await waitFor(() => expect(r.container.querySelector(".ve-source")).toBeTruthy());
    await act(async () => {
      state.setVideoEdit(KEY, {
        source: {
          ...(state.videoEditOf(KEY).source as {
            media: string;
            in: number;
            out: number;
            at: number;
          }),
          at: 25,
        },
      });
    });
    key(root, "i");
    await act(async () => {
      state.setVideoEdit(KEY, {
        source: {
          ...(state.videoEditOf(KEY).source as {
            media: string;
            in: number;
            out: number;
            at: number;
          }),
          at: 75,
        },
      });
    });
    key(root, "o");
    expect(state.videoEditOf(KEY).source).toMatchObject({ media: "v/b.mp4", in: 25, out: 75 });
    await act(async () => {
      state.setVideoView(KEY, { frame: 300 });
    });
    key(root, "F10");
    expect(whatOf(lastOps())).toBe("overwrite");
    const placed = host.doc.clips.filter((c) => c.start === 300);
    expect(
      placed.map((c) => [c.track, c.sourceRange.start, c.sourceRange.duration]).sort(),
    ).toEqual([
      ["A1", 25, 50],
      ["V1", 25, 50],
    ]);
    // The cursor goes to the end of what was placed, as in Resolve.
    expect(state.videoViewOf(KEY).frame).toBe(350);
  });

  it("Ctrl+Z takes back the person's last gesture through the host", async () => {
    const { el, host, r } = await open();
    const root = r.container.querySelector(".ve") as Element;
    press(el("[data-clip=a]"), x(50));
    moveTo(x(75));
    release(x(75));
    expect(find(host.doc, "a").start).toBe(25);
    key(root, "z", { ctrlKey: true });
    const undo = sentDoc.find((m) => m.type === "doc.undo");
    expect(undo).toMatchObject({ revision: 1 });
    expect(find(host.doc, "a").start).toBe(0);
    await waitFor(() =>
      expect((r.container.querySelector("[data-clip=a]") as HTMLElement).style.left).toBe("0px"),
    );
  });

  it("an agent's change shows on its clips with who made it", async () => {
    const { r, host } = await open();
    const { setClipProps } = await import("@redgiant/protocol");
    const next = setClipProps(host.doc, ["b"], { volume: -6 });
    const a = editAction(host.doc, next, "props") as VideoAction;
    expect(checkVideoAction(host.doc, a)).toBeUndefined();
    host.apply([op(a)], "agent-1");
    await act(async () =>
      peer?.changed({
        type: "doc.changed",
        file,
        revision: host.revision,
        ops: [op(a)],
        change: change(host.revision, "agent-1", { authorName: "Regista" }),
      } as never),
    );
    const b = r.container.querySelector("[data-clip=b]") as HTMLElement;
    expect(b.classList.contains("agent")).toBe(true);
    expect(b.querySelector(".ve-clip-who")?.textContent).toBe("Regista");
  });

  it("«?» lists the shortcuts in our window; Escape closes it", async () => {
    const { r } = await open();
    const root = r.container.querySelector(".ve") as Element;
    key(root, "?");
    await waitFor(() => expect(document.querySelector(".ve-keys")).toBeTruthy());
    expect(document.body.textContent).toContain("Taglia al cursore");
    key(root, "Escape");
    expect(state.videoEditOf(KEY).help).toBe(false);
  });
});

const isNew = (c: VideoClip) => "media" in c.ref && c.ref.media === "v/new.mp4";
