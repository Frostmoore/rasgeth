// The page's side of the timeline editor (G41.5b), with no view in it (tested alone): the
// person's gestures go through the protocol's pure edits (video-timeline.ts) and become the same
// actions the agents send (`diffTimeline`), with ids of the page's own (two authors on the same
// revision would otherwise both make `c<n>`); others' revisions met with the person's own still in
// flight; the keys of Resolve (and montatore) as a table; the ruler's ticks, the snapping of a
// block, J/K/L; a change in the person's words. The server owns the file: the page never writes it.
import {
  clipEnd,
  type DocSummary,
  diffTimeline,
  fps,
  type RgVideo,
  secondsToFrames,
  snap,
  snapPoints,
  timecode,
  VIDEO_ENGINE,
  VIDEO_ENGINE_VERSION,
  type VideoAction,
  type VideoEdit,
  type VideoIdGen,
  type VideoMediaInfo,
  type VideoMediaRef,
  type VideoRate,
  videoActionsConflict,
} from "@redgiant/protocol";
import { type Key, t } from "../i18n.js";

export const videoDocOp = (op: VideoAction) => ({
  family: "video" as const,
  engine: VIDEO_ENGINE as typeof VIDEO_ENGINE,
  engineVersion: VIDEO_ENGINE_VERSION,
  op,
});

/** The actions of a host's message (others' revisions). */
export const videoActionsOf = (ops: readonly { family: string; op?: unknown }[]): VideoAction[] =>
  ops.flatMap((o) => (o.family === "video" ? [o.op as VideoAction] : []));

/** The ids a list of actions sets (clips, tracks, markers…): what an agent's change highlights. */
export function touchedIds(list: readonly VideoAction[]): Set<string> {
  const out = new Set<string>();
  for (const a of list)
    for (const p of a.t === "batch" ? a.ops : [a])
      if (p.t !== "doc" && p.t !== "meta" && p.value) out.add(p.id);
  return out;
}

// ---- ids of the page's own ------------------------------------------------------------------

/** A short tag of this page, for its ids (letters and digits only). */
export const pageTag = (): string => `p${Math.random().toString(36).slice(2, 7)}`;

/**
 * The page's ids: `c_<tag>1`, `g_<tag>2`… never `c<n>` (the agents' and the server's, from
 * `videoIdGen`), never one the timeline has. The counter goes on across edits (an id taken back
 * by an undo is not given again).
 */
export class PageIds {
  private n = 0;
  constructor(readonly tag: string = pageTag()) {}
  for(doc: RgVideo): VideoIdGen {
    const taken = new Set<string>();
    for (const c of doc.clips) {
      taken.add(c.id);
      if (c.link) taken.add(c.link);
    }
    for (const x of doc.transitions) taken.add(x.id);
    for (const m of doc.markers) taken.add(m.id);
    for (const s of doc.captions.segments) taken.add(s.id);
    return (prefix) => {
      let id: string;
      do id = `${prefix}_${this.tag}${++this.n}`;
      while (taken.has(id));
      taken.add(id);
      return id;
    };
  }
}

/** A gesture's action: the difference the edit made, tagged with it (undefined: nothing changed). */
export const editAction = (before: RgVideo, after: RgVideo, what: VideoEdit) =>
  before === after ? undefined : diffTimeline(before, after, what);

// ---- others' revisions and the person's own --------------------------------------------------

export interface VideoOutgoing {
  clientId: string;
  baseRevision: number;
  actions: VideoAction[];
}

let sent = 0;
const newId = () => `v${Date.now().toString(36)}${(sent++).toString(36)}`;

/**
 * The person's gestures on their way to the host, one message at a time (each gesture its own
 * action); others' revisions apply on the page unless they meet the person's own still in flight
 * (then the page loads the timeline again).
 */
export class VideoCollab {
  revision = 0;
  private inflight: { id: string; actions: VideoAction[] } | undefined;
  private buffer: VideoAction[] = [];

  constructor(private readonly send: (o: VideoOutgoing) => void) {}

  reset(revision: number): void {
    this.revision = revision;
    this.inflight = undefined;
    this.buffer = [];
  }

  get pending(): boolean {
    return !!this.inflight || this.buffer.length > 0;
  }

  /** A gesture made on the page: sent at once when nothing is in flight. */
  local(a: VideoAction): void {
    this.buffer.push(a);
    this.flush();
  }

  flush(): void {
    if (this.inflight || !this.buffer.length) return;
    const actions = this.buffer;
    this.buffer = [];
    this.inflight = { id: newId(), actions };
    this.send({ clientId: this.inflight.id, baseRevision: this.revision, actions });
  }

  ack(clientId: string, revision: number): boolean {
    if (!this.inflight || this.inflight.id !== clientId) return false;
    this.revision = revision;
    this.inflight = undefined;
    this.flush();
    return true;
  }

  /** Others' revision: "apply" on the page, or "reload" (not the next one, or it meets mine). */
  remote(revision: number, actions: readonly VideoAction[]): "apply" | "reload" {
    if (revision !== this.revision + 1) return "reload";
    const mine = [...(this.inflight?.actions ?? []), ...this.buffer];
    for (const a of mine) for (const b of actions) if (videoActionsConflict(a, b)) return "reload";
    this.revision = revision;
    return "apply";
  }

  rejected(clientId: string): boolean {
    return this.inflight?.id === clientId;
  }
}

// ---- the keys -------------------------------------------------------------------------------

export type VideoCommand =
  | "undo"
  | "redo"
  | "save"
  | "blade"
  | "copy"
  | "paste"
  | "selectAll"
  | "link"
  | "linkedSel"
  | "play"
  | "reverse"
  | "stop"
  | "forward"
  | "prevFrame"
  | "nextFrame"
  | "prevSecond"
  | "nextSecond"
  | "prevEdit"
  | "nextEdit"
  | "home"
  | "end"
  | "lift"
  | "ripple"
  | "escape"
  | "insert"
  | "overwrite"
  | "append"
  | "toolSelect"
  | "toolBlade"
  | "toolTrim"
  | "snap"
  | "marker"
  | "enable"
  | "markIn"
  | "markOut"
  | "zoomIn"
  | "zoomOut"
  | "fit"
  | "help"
  | "nudgeLeft"
  | "nudgeRight"
  | "trimStart"
  | "trimEnd"
  | "selectAtPlayhead";

export interface KeyLike {
  key: string;
  ctrlKey?: boolean;
  metaKey?: boolean;
  altKey?: boolean;
  shiftKey?: boolean;
}

/**
 * The command of a key, as in Resolve and montatore (Ctrl is Cmd on macOS: either counts). The
 * table is the shortcuts' list too (`VIDEO_KEYS`), shown with «?».
 */
export function videoKey(e: KeyLike): VideoCommand | undefined {
  const k = e.key;
  const lk = k.length === 1 ? k.toLowerCase() : k;
  const mod = !!(e.ctrlKey || e.metaKey);
  if (mod) {
    if (lk === "z") return e.shiftKey ? "redo" : "undo";
    if (lk === "y") return "redo";
    if (lk === "s") return "save";
    if (lk === "b") return "blade";
    if (lk === "c") return "copy";
    if (lk === "v") return "paste";
    if (lk === "a") return "selectAll";
    if (e.altKey && lk === "l") return "link";
    if (e.shiftKey && lk === "l") return "linkedSel";
    return undefined;
  }
  if (e.altKey) return undefined;
  if (k === " ") return "play";
  if (lk === "j") return "reverse";
  if (lk === "k") return "stop";
  if (lk === "l") return "forward";
  if (k === "ArrowLeft") return e.shiftKey ? "prevSecond" : "prevFrame";
  if (k === "ArrowRight") return e.shiftKey ? "nextSecond" : "nextFrame";
  if (k === "ArrowUp") return "prevEdit";
  if (k === "ArrowDown") return "nextEdit";
  if (k === "Home") return "home";
  if (k === "End") return "end";
  if (k === "Backspace") return "lift";
  if (k === "Delete") return "ripple";
  if (k === "Escape") return "escape";
  if (k === "F9") return "insert";
  if (k === "F10") return "overwrite";
  if (k === "F12" && e.shiftKey) return "append";
  if (k === "+" || k === "=") return "zoomIn";
  if (k === "-" || k === "_") return "zoomOut";
  if (lk === "z" && e.shiftKey) return "fit";
  if (k === "?") return "help";
  if (k === ",") return "nudgeLeft";
  if (k === ".") return "nudgeRight";
  if (k === "{" || (k === "[" && e.shiftKey)) return "trimStart";
  if (k === "}" || (k === "]" && e.shiftKey)) return "trimEnd";
  if (lk === "v" && e.shiftKey) return "selectAtPlayhead";
  if (lk === "a") return "toolSelect";
  if (lk === "b") return "toolBlade";
  if (lk === "t") return "toolTrim";
  if (lk === "n") return "snap";
  if (lk === "m") return "marker";
  if (lk === "d") return "enable";
  if (lk === "i") return "markIn";
  if (lk === "o") return "markOut";
  return undefined;
}

/** The list «?» shows: the keys (as written on a keyboard) and what they do. */
export const VIDEO_KEYS: readonly { keys: string; what: Key }[] = [
  { keys: "Space", what: "veKeyPlay" },
  { keys: "J / K / L", what: "veKeyJkl" },
  { keys: "← →", what: "veKeyFrame" },
  { keys: "Shift+← →", what: "veKeySecond" },
  { keys: "↑ ↓", what: "veKeyEdit" },
  { keys: "Home / End", what: "veKeyHomeEnd" },
  { keys: "A / B / T", what: "veKeyTools" },
  { keys: "Ctrl+B", what: "veKeyBlade" },
  { keys: "Backspace", what: "veKeyLift" },
  { keys: "Delete", what: "veKeyRipple" },
  { keys: ", .", what: "veKeyNudge" },
  { keys: "Shift+[ ]", what: "veKeyTrimTo" },
  { keys: "Ctrl+C / Ctrl+V", what: "veKeyCopy" },
  { keys: "Ctrl+A", what: "veKeySelectAll" },
  { keys: "Shift+V", what: "veKeySelectAt" },
  { keys: "Ctrl+Z / Ctrl+Shift+Z", what: "veKeyUndo" },
  { keys: "Ctrl+Alt+L", what: "veKeyLink" },
  { keys: "Ctrl+Shift+L", what: "veKeyLinkedSel" },
  { keys: "M", what: "veKeyMarker" },
  { keys: "D", what: "veKeyEnable" },
  { keys: "N", what: "veKeySnap" },
  { keys: "+ / − / Shift+Z", what: "veKeyZoom" },
  { keys: "I / O", what: "veKeyInOut" },
  { keys: "F9 / F10 / Shift+F12", what: "veKeyPlace" },
  { keys: "Ctrl+S", what: "veKeySave" },
  { keys: "Esc", what: "veKeyEscape" },
  { keys: "?", what: "veKeyHelp" },
];

/**
 * Keys as the person's keyboard writes them: Italian names (Maiusc, Canc, Fine…) and Cmd for
 * Ctrl on macOS. Pure: the list and the buttons' titles go through it.
 */
export function keyWords(keys: string, o: { it: boolean; mac: boolean }): string {
  let s = keys;
  if (o.mac) s = s.replace(/\bCtrl\b/g, "Cmd").replace(/\bAlt\b/g, "Option");
  if (o.it)
    s = s
      .replace(/\bShift\b/g, "Maiusc")
      .replace(/\bSpace\b/g, "Spazio")
      .replace(/\bDelete\b/g, "Canc")
      .replace(/\bEnd\b/g, "Fine")
      .replace(/\bHome\b/g, "Inizio");
  return s;
}

/** J/K/L: J backwards, L forwards, again doubles up to 8×; K stops (0). */
export function shuttleRate(playing: boolean, rate: number, key: "reverse" | "forward"): number {
  const dir = key === "forward" ? 1 : -1;
  if (playing && Math.sign(rate) === dir) return Math.min(8, Math.abs(rate) * 2) * dir;
  return dir;
}

// ---- geometry -------------------------------------------------------------------------------

/** Pixels per frame: the narrowest and widest zoom. */
export const PPF_MIN = 0.02;
export const PPF_MAX = 40;
export const clampPpf = (p: number) => Math.max(PPF_MIN, Math.min(PPF_MAX, p));

/** The zoom that fits the timeline (at least 10 s) into `width` pixels. */
export function fitPpf(width: number, duration: number, rate: VideoRate): number {
  return clampPpf((Math.max(100, width) - 40) / Math.max(duration, fps(rate) * 10));
}

const TICK_FRAMES = [1, 2, 5, 10];
const TICK_SECONDS = [1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 1800, 3600];

/**
 * The ruler's ticks: a step of frames or of whole seconds with at least `minPx` between labels,
 * every label a timecode; small marks between them when there is room.
 */
export function rulerTicks(
  ppf: number,
  rate: VideoRate,
  total: number,
  minPx = 96,
): { frame: number; label: string; minor?: true }[] {
  const base = Math.max(1, Math.round(fps(rate)));
  const steps = [
    ...TICK_FRAMES.filter((f) => f < base),
    ...TICK_SECONDS.map((s) => secondsToFrames(s, rate)),
  ];
  const step = steps.find((s) => s * ppf >= minPx) ?? secondsToFrames(7200, rate);
  const out: { frame: number; label: string; minor?: true }[] = [];
  const minorN = step * ppf >= minPx * 2 ? 4 : step * ppf >= minPx ? 2 : 1;
  for (let f = 0; f <= total; f += step) {
    out.push({ frame: f, label: timecode(f, rate) });
    for (let i = 1; i < minorN; i++) {
      const m = Math.round(f + (step * i) / minorN);
      if (m <= total) out.push({ frame: m, label: "", minor: true });
    }
  }
  return out;
}

/** Snapping a dragged block: the nearer of its start and end to a point (or none). */
export function snapBlock(
  doc: RgVideo,
  moving: ReadonlySet<string>,
  delta: number,
  playhead: number,
  threshold: number,
): number {
  const clips = doc.clips.filter((c) => moving.has(c.id));
  if (!clips.length) return delta;
  const s = Math.min(...clips.map((c) => c.start)) + delta;
  const e = Math.max(...clips.map(clipEnd)) + delta;
  const pts = snapPoints(doc, moving, playhead);
  const ds = snap(s, pts, threshold) - s;
  const de = snap(e, pts, threshold) - e;
  const pick = ds === 0 ? de : de === 0 ? ds : Math.abs(ds) <= Math.abs(de) ? ds : de;
  return delta + pick;
}

/** Where a press on a clip falls: its left or right edge (trim) within `edgePx`, or its body. */
export function edgeAt(
  x: number,
  left: number,
  width: number,
  edgePx = 7,
): "in" | "out" | undefined {
  const e = Math.min(edgePx, width / 3);
  if (x - left <= e) return "in";
  if (left + width - x <= e) return "out";
  return undefined;
}

/** The gap around `frame` on a track: [from, to) between two clips (none after the last one). */
export function gapAt(doc: RgVideo, trackId: string, frame: number): [number, number] | undefined {
  let s = 0;
  for (const c of doc.clips.filter((x) => x.track === trackId).sort((a, b) => a.start - b.start)) {
    if (frame < c.start) return frame >= s && c.start > s ? [s, c.start] : undefined;
    s = Math.max(s, clipEnd(c));
  }
  return undefined;
}

// ---- files ----------------------------------------------------------------------------------

const PICTURE = /\.(png|jpe?g|webp|gif|bmp|tiff?|avif|heic|heif)$/i;
const SOUND = /\.(mp3|wav|m4a|aac|flac|ogg|oga|opus|weba|wma|aiff?)$/i;
const MOVIE = /\.(mp4|m4v|webm|ogv|mov|mkv|avi|wmv|flv|mpg|mpeg|3gp|mts|m2ts)$/i;

/** Whether a project file can go into a timeline (a video, a picture or a sound). */
export const isTimelineMedia = (path: string) =>
  PICTURE.test(path) || SOUND.test(path) || MOVIE.test(path);

/**
 * A file's reference in the timeline from what the server read of it: its length in frames at
 * the timeline's rate, a picture as still, no sound when it has none. Undefined while the file
 * is not read yet (its probe still a job).
 */
export function mediaRefOf(
  info: VideoMediaInfo | undefined,
  media: string,
  rate: VideoRate,
): VideoMediaRef | undefined {
  if (PICTURE.test(media) || info?.kind === "image") return { media, still: true };
  const p = info?.probe;
  if (!p) return undefined;
  if (p.kind === "image") return { media, still: true };
  const ref: VideoMediaRef = { media };
  if (p.duration) ref.frames = Math.max(1, secondsToFrames(p.duration, rate));
  if (!p.audio) ref.audio = false;
  return ref;
}

/** How long a file's source is in frames (a picture: 5 s). */
export const sourceLength = (ref: VideoMediaRef, rate: VideoRate) =>
  ref.frames ?? secondsToFrames(5, rate);

// ---- words ----------------------------------------------------------------------------------

/** A timeline's change in the person's words: «Spostate 2 clip», «Tagliata una clip in due». */
export function videoChangeText(s: DocSummary): string {
  const c = s.video;
  if (!c) return s.text;
  const one = c.n <= 1;
  const n = String(c.n);
  const pick = (a: Key, many: Key, count = c.n) =>
    count <= 1 ? t(a) : t(many, { n: String(count) });
  switch (c.action) {
    case "move":
      return pick("veChMove", "veChMoveN");
    case "trim":
      return pick("veChTrim", "veChTrimN");
    case "ripple_trim":
      return t("veChRippleTrim");
    case "blade":
      return pick("veChBlade", "veChBladeN", c.added ?? 1);
    case "lift":
      return pick("veChLift", "veChLiftN", c.removed ?? 1);
    case "ripple_delete":
      return pick("veChRipple", "veChRippleN", c.removed ?? 1);
    case "close_gap":
      return t("veChCloseGap");
    case "insert":
    case "overwrite":
    case "append":
    case "paste":
      return pick(`veCh_${c.action}` as Key, `veCh_${c.action}N` as Key, c.added ?? 1);
    case "link":
      return t("veChLink");
    case "unlink":
      return t("veChUnlink");
    case "props":
      return one ? t("veChProps") : t("veChPropsN", { n });
    case "add_track":
      return t("veChAddTrack", { id: c.id ?? "" });
    case "remove_track":
      return t("veChRemoveTrack", { id: c.id ?? "" });
    case "track":
      return t("veChTrack", { id: c.id ?? "" });
    case "marker":
      return t("veChMarker");
    case "transition":
      return t("veChTransition");
    case "text":
      return t("veChText");
    case "caption":
      return t("veChCaption");
    case "format":
      return t("veChFormat");
    case "replace":
      return t("docReplaced");
    default:
      return one ? t("veChEdit") : t("veChEditN", { n });
  }
}
