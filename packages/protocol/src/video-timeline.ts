// The timeline's edits (G41.2), without a page: pure functions on an `RgVideo`, used by the server
// (the agents' canvas_edit) and by the page (the person's tools) alike. Ported from montatore's
// `resources/js/editor/model.js` (its 14 tests are the first rows of video-timeline.test.ts),
// with OTIO's names: a clip plays `sourceRange` {start, duration} of its reference from its
// absolute `start` in the timeline. Every edit takes a document and gives a new one (the one it
// got never changes; nothing to do: the same object back); `diffTimeline` (video-patch.ts) turns
// the difference into the family's actions, each with its exact inverse. Behaviour follows
// DaVinci Resolve as montatore does: where clips land they overwrite, locked tracks are never
// touched, linked clips (audio and video of one file) move, trim and delete together.
import {
  RGVIDEO_FORMAT_VERSION,
  RgVideo,
  VIDEO_ASPECTS,
  VIDEO_MARKER_COLORS,
  VIDEO_TEXT_POSITIONS,
  VIDEO_TEXT_STYLES,
  VIDEO_TRANSITIONS,
  type VideoAspect,
  type VideoCaption,
  type VideoCaptionSettings,
  type VideoCaptionWord,
  type VideoClip,
  type VideoColorRef,
  type VideoDuck,
  type VideoFormat,
  type VideoKenBurns,
  type VideoMarker,
  type VideoMarkerColor,
  type VideoMediaRef,
  type VideoRate,
  type VideoRect,
  type VideoRef,
  type VideoTextRef,
  type VideoTrack,
  type VideoTrackKind,
  type VideoTransition,
  type VideoTransitionKind,
} from "./doc-video.js";

/** Makes a new id with this prefix (c clip, g link, m marker, t transition, s caption). */
export type VideoIdGen = (prefix: string) => string;
export interface VideoEditOpts {
  /** The page passes its own (ids with a prefix of its own: no clash with an agent's). */
  ids?: VideoIdGen;
}

const clone = <T>(x: T): T => structuredClone(x);

export const clipEnd = (c: VideoClip): number => c.start + c.sourceRange.duration;
export const clipLength = (c: VideoClip): number => c.sourceRange.duration;
export const isMediaRef = (r: VideoRef): r is VideoMediaRef => "media" in r;
export const isTextRef = (r: VideoRef): r is VideoTextRef =>
  "generator" in r && r.generator === "text";
/** A picture, a text or a colour: no length of its own, never a base under the others. */
export const isStillClip = (c: VideoClip): boolean => !isMediaRef(c.ref) || !!c.ref.still;

// -------------------------------------------------------------------------------------------
// A new timeline, its format

/** The usual sizes of each shape (the short side 1080). */
export function formatFor(
  aspect: VideoAspect,
  short = 1080,
  rate: VideoRate = { num: 30, den: 1 },
): VideoFormat {
  const s = even(short);
  const long = even(Math.round((s * 16) / 9));
  if (aspect === "9:16") return { width: s, height: long, rate, aspect };
  if (aspect === "1:1") return { width: s, height: s, rate, aspect };
  return { width: long, height: s, rate, aspect: aspect === "free" ? "free" : "16:9" };
}
const even = (n: number) => Math.max(16, Math.round(n / 2) * 2);

/** An empty timeline: V1 and A1, 1920×1080 at 30 fps unless said. */
export function newRgVideo(format?: Partial<VideoFormat>, name?: string): RgVideo {
  const f = { ...formatFor("16:9"), ...format };
  return {
    formatVersion: RGVIDEO_FORMAT_VERSION,
    ...(name !== undefined && { name }),
    format: f,
    tracks: [
      { id: "V1", kind: "Video", name: "V1", locked: false, hidden: false },
      { id: "A1", kind: "Audio", name: "A1", locked: false, muted: false },
    ],
    clips: [],
    transitions: [],
    markers: [],
    captions: { language: "", burnIn: false, style: "boxed", position: "bottom", segments: [] },
  };
}

// -------------------------------------------------------------------------------------------
// Time: frames, seconds, timecode

export const fps = (r: VideoRate): number => r.num / r.den;
export const framesToSeconds = (f: number, r: VideoRate): number => (f * r.den) / r.num;
export const secondsToFrames = (s: number, r: VideoRate): number => Math.round((s * r.num) / r.den);

/** HH:MM:SS:FF on the rate's whole base (non-drop-frame, as montatore and Resolve show it). */
export function timecode(frame: number, rate: VideoRate): string {
  const base = Math.max(1, Math.round(fps(rate)));
  const neg = frame < 0;
  const f = Math.abs(Math.round(frame));
  const ff = f % base;
  const s = Math.floor(f / base);
  const p = (n: number) => String(n).padStart(2, "0");
  return `${neg ? "-" : ""}${p(Math.floor(s / 3600))}:${p(Math.floor(s / 60) % 60)}:${p(s % 60)}:${p(ff)}`;
}

/**
 * A time as frames: a number is frames; a string is "120f" (frames), "4.5s" or "4,5" (seconds),
 * or a timecode "HH:MM:SS:FF" (also "MM:SS:FF", "SS:FF"); a leading "-" for a backward change.
 * Undefined when it cannot be read.
 */
export function parseTime(v: unknown, rate: VideoRate): number | undefined {
  if (typeof v === "number") return Number.isFinite(v) ? Math.round(v) : undefined;
  if (typeof v !== "string") return undefined;
  let t = v.trim().replace(",", ".");
  let sign = 1;
  if (t.startsWith("-")) {
    sign = -1;
    t = t.slice(1).trim();
  } else if (t.startsWith("+")) t = t.slice(1).trim();
  let m = /^(\d+)\s*f$/i.exec(t);
  if (m) return sign * Number(m[1]);
  m = /^(\d+(?:\.\d+)?)\s*s?$/i.exec(t);
  if (m) return sign * secondsToFrames(Number(m[1]), rate);
  if (!/^\d+([:;]\d+){1,3}$/.test(t)) return undefined;
  const parts = t.split(/[:;]/).map(Number);
  while (parts.length < 4) parts.unshift(0);
  const [h = 0, mi = 0, s = 0, f = 0] = parts;
  const base = Math.max(1, Math.round(fps(rate)));
  if (mi > 59 || s > 59 || f >= base) return undefined;
  return sign * (((h * 60 + mi) * 60 + s) * base + f);
}

// -------------------------------------------------------------------------------------------
// Reading the timeline

export const trackOf = (doc: RgVideo, id: string | undefined): VideoTrack | undefined =>
  doc.tracks.find((t) => t.id === id);
export const clipOf = (doc: RgVideo, id: string): VideoClip | undefined =>
  doc.clips.find((c) => c.id === id);
export const isLocked = (doc: RgVideo, trackId: string | undefined): boolean =>
  !!trackOf(doc, trackId)?.locked;

export function trackClips(doc: RgVideo, trackId: string): VideoClip[] {
  return doc.clips.filter((c) => c.track === trackId).sort((a, b) => a.start - b.start);
}

/** The timeline's length: the end of its last clip. */
export function timelineDuration(doc: RgVideo): number {
  return doc.clips.reduce((m, c) => Math.max(m, clipEnd(c)), 0);
}

/** The clips linked (same `link`) to these, these included. */
export function withLinked(doc: RgVideo, ids: readonly string[]): string[] {
  const set = new Set(ids);
  const links = new Set(
    doc.clips.filter((c) => set.has(c.id) && c.link).map((c) => c.link as string),
  );
  for (const c of doc.clips) if (c.link && links.has(c.link)) set.add(c.id);
  return [...set];
}

export function clipAt(doc: RgVideo, trackId: string, frame: number): VideoClip | undefined {
  return doc.clips.find((c) => c.track === trackId && frame >= c.start && frame < clipEnd(c));
}

const trackNumber = (id: string) => Number(id.slice(1));

/** The tracks of one kind in order (V1, V2…; A1, A2…). */
export function lanes(doc: RgVideo, kind: VideoTrackKind): string[] {
  return doc.tracks
    .filter((t) => t.kind === kind)
    .map((t) => t.id)
    .sort((a, b) => trackNumber(a) - trackNumber(b));
}

/** The clips in `after` that `before` did not have (a placement's, a paste's). */
export function addedClips(before: RgVideo, after: RgVideo): string[] {
  const had = new Set(before.clips.map((c) => c.id));
  return after.clips.filter((c) => !had.has(c.id)).map((c) => c.id);
}

/** Ids not used yet: the highest number after each prefix, plus one. */
export function videoIdGen(doc: RgVideo): VideoIdGen {
  const max = new Map<string, number>();
  const see = (id: string | undefined) => {
    const m = id ? /^([a-z]+)(\d+)$/.exec(id) : null;
    if (m?.[1]) max.set(m[1], Math.max(max.get(m[1]) ?? 0, Number(m[2])));
  };
  for (const c of doc.clips) {
    see(c.id);
    see(c.link);
  }
  for (const t of doc.transitions) see(t.id);
  for (const m of doc.markers) see(m.id);
  for (const s of doc.captions.segments) see(s.id);
  return (p) => {
    const n = (max.get(p) ?? 0) + 1;
    max.set(p, n);
    return `${p}${n}`;
  };
}

/** How far a clip's edges may go into its file (a picture or a text: without limit). */
function room(c: VideoClip): { left: number; right: number } {
  if (isStillClip(c)) return { left: Number.POSITIVE_INFINITY, right: Number.POSITIVE_INFINITY };
  const frames = (c.ref as VideoMediaRef).frames;
  return {
    left: c.sourceRange.start,
    right:
      frames === undefined
        ? Number.POSITIVE_INFINITY
        : frames - (c.sourceRange.start + c.sourceRange.duration),
  };
}

// -------------------------------------------------------------------------------------------
// Keeping the document in order after every edit

const trackRank = (doc: RgVideo) => {
  const rank = new Map<string, number>();
  for (const t of doc.tracks) rank.set(t.id, (t.kind === "Video" ? 0 : 1000) + trackNumber(t.id));
  return (id: string) => rank.get(id) ?? 9999;
};
const byStr = (a: string, b: string) => (a < b ? -1 : a > b ? 1 : 0);

/**
 * The one order of every list, whatever the edits that made it (so an edit and its inverse give
 * back the same bytes): tracks video then audio by number, clips by track and start, transitions
 * by track and cut, markers by frame, captions by start; ties by id.
 */
export function canonicalTimeline(doc: RgVideo): RgVideo {
  const rank = trackRank(doc);
  doc.tracks.sort((a, b) => rank(a.id) - rank(b.id) || byStr(a.id, b.id));
  doc.clips.sort((a, b) => rank(a.track) - rank(b.track) || a.start - b.start || byStr(a.id, b.id));
  const startOf = new Map(doc.clips.map((c) => [c.id, c.start]));
  doc.transitions.sort(
    (a, b) =>
      rank(a.track) - rank(b.track) ||
      (startOf.get(a.to) ?? 0) - (startOf.get(b.to) ?? 0) ||
      byStr(a.id, b.id),
  );
  doc.markers.sort((a, b) => a.frame - b.frame || byStr(a.id, b.id));
  doc.captions.segments.sort((a, b) => a.start - b.start || byStr(a.id, b.id));
  return doc;
}

/**
 * After an edit: fades at most half a clip, transitions only between two clips still adjacent on
 * their track (offsets within them, one per cut), then the canonical order.
 */
function settle(doc: RgVideo): RgVideo {
  for (const c of doc.clips) {
    const half = Math.floor(c.sourceRange.duration / 2);
    c.fadeIn = Math.max(0, Math.min(c.fadeIn, half));
    c.fadeOut = Math.max(0, Math.min(c.fadeOut, half));
  }
  doc.transitions = validTransitions(doc, doc.transitions);
  return canonicalTimeline(doc);
}

function validTransitions(doc: RgVideo, list: readonly VideoTransition[]): VideoTransition[] {
  const byId = new Map(doc.clips.map((c) => [c.id, c]));
  const outs = new Set<string>();
  const ins = new Set<string>();
  const out: VideoTransition[] = [];
  for (const t of list) {
    const a = byId.get(t.from);
    const b = byId.get(t.to);
    if (!a || !b || a.track !== t.track || b.track !== t.track || clipEnd(a) !== b.start) continue;
    if (outs.has(a.id) || ins.has(b.id)) continue;
    const inOffset = Math.min(t.inOffset, clipLength(a));
    const outOffset = Math.min(t.outOffset, clipLength(b));
    if (inOffset + outOffset < 1) continue;
    outs.add(a.id);
    ins.add(b.id);
    out.push({ ...t, inOffset, outOffset });
  }
  return out;
}

/** The clip `from` was split: its outgoing transition now leaves from the right part. */
function retarget(doc: RgVideo, from: string, to: string) {
  for (const t of doc.transitions) if (t.from === from) t.from = to;
}

/** A clip's length set, its source range kept in step. */
const withLength = (c: VideoClip, duration: number): VideoClip => ({
  ...c,
  sourceRange: { start: c.sourceRange.start, duration },
});

/**
 * Frees [from, to) on a track: clips inside go, those across it are shortened or split in two
 * (Resolve's «overwrite»). The right part of a split clip gets a new id and no link.
 */
function carve(
  doc: RgVideo,
  trackId: string,
  from: number,
  to: number,
  ids: VideoIdGen,
  keep: ReadonlySet<string> = new Set(),
) {
  if (to <= from) return;
  const out: VideoClip[] = [];
  for (const c of doc.clips) {
    if (c.track !== trackId || keep.has(c.id) || clipEnd(c) <= from || c.start >= to) {
      out.push(c);
      continue;
    }
    const split = c.start < from;
    if (split) out.push({ ...withLength(c, from - c.start), fadeOut: 0 });
    if (clipEnd(c) > to) {
      const cut = to - c.start;
      const right: VideoClip = {
        ...c,
        id: ids("c"),
        start: to,
        sourceRange: {
          start: c.sourceRange.start + (isStillClip(c) ? 0 : cut),
          duration: clipEnd(c) - to,
        },
        fadeIn: 0,
      };
      if (split) delete right.link;
      retarget(doc, c.id, right.id);
      out.push(right);
    }
  }
  doc.clips = out;
}

// -------------------------------------------------------------------------------------------
// Moving

/**
 * Moves the clips `ids` by `delta` frames and `laneDelta` tracks (among tracks of the same kind).
 * Linked clips follow when `linked`; only the grabbed clip's kind changes track (dragging a video
 * leaves its linked audio on its audio track, as in Resolve). Where they land they overwrite.
 * Locked tracks are not touched; never before frame 0.
 */
export function moveClips(
  doc0: RgVideo,
  ids: readonly string[],
  delta: number,
  laneDelta = 0,
  o: VideoEditOpts & { linked?: boolean } = {},
): RgVideo {
  const doc = clone(doc0);
  const gen = o.ids ?? videoIdGen(doc0);
  const moving = new Set(o.linked === false ? ids : withLinked(doc, ids));
  const clips = doc.clips.filter((c) => moving.has(c.id) && !isLocked(doc, c.track));
  if (!clips.length) return doc0;
  const d = Math.max(Math.round(delta), -Math.min(...clips.map((c) => c.start)));
  const grabbed = trackOf(doc, doc.clips.find((c) => c.id === ids[0])?.track)?.kind;
  for (const c of clips) {
    const kind = trackOf(doc, c.track)?.kind ?? "Video";
    const ls = lanes(doc, kind);
    const dl = kind === grabbed ? laneDelta : 0;
    const target = ls[Math.max(0, Math.min(ls.length - 1, ls.indexOf(c.track) + dl))] ?? c.track;
    if (isLocked(doc, target)) return doc0;
    c.track = target;
    c.start += d;
  }
  if (!d && clips.every((c) => doc0.clips.find((x) => x.id === c.id)?.track === c.track))
    return doc0;
  for (const c of clips) carve(doc, c.track, c.start, clipEnd(c), gen, moving);
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Trimming

/** Moves by `delta` everything starting at `from` or later, on the unlocked tracks. */
function shiftAfter(
  doc: RgVideo,
  from: number,
  delta: number,
  except: ReadonlySet<string> = new Set(),
  only?: ReadonlySet<string>,
) {
  for (const c of doc.clips)
    if (
      !except.has(c.id) &&
      c.start >= from &&
      !isLocked(doc, c.track) &&
      (!only || only.has(c.track))
    )
      c.start += delta;
}

// -------------------------------------------------------------------------------------------
// Markers and subtitles follow the ripples (G41.5c)

/**
 * Markers and subtitles belong to the timeline, not to a track: they follow a ripple that moves
 * the main tracks (every unlocked track, or a set that holds V1 or A1, where the picture and the
 * voice are), never one on a side track alone (music closing up under a still voice).
 */
const timedFollow = (only?: ReadonlySet<string>) => !only || only.has("V1") || only.has("A1");

/**
 * A subtitle's words with their frames: its own (G41.4, from the transcription) or, for a line
 * typed by hand, spread over its time by their length (as G41.4's interpolated words).
 */
export function captionWords(c: Pick<VideoCaption, "start" | "end" | "text" | "words">) {
  if (c.words?.length) return c.words.map((w) => ({ ...w }));
  const parts = c.text.split(/\s+/).filter(Boolean);
  const total = parts.reduce((n, p) => n + p.length + 1, 0);
  const out: VideoCaptionWord[] = [];
  let at = 0;
  for (const p of parts) {
    const s = c.start + Math.round(((c.end - c.start) * at) / total);
    at += p.length + 1;
    const e = c.start + Math.round(((c.end - c.start) * at) / total);
    out.push({ start: s, end: Math.max(e, s + 1), text: p });
  }
  return out;
}

/** Everything timed from `from` on moves by `delta` (a space opened, F9). */
function shiftTimed(doc: RgVideo, from: number, delta: number) {
  for (const m of doc.markers) if (m.frame >= from) m.frame = Math.max(0, m.frame + delta);
  for (const c of doc.captions.segments) {
    if (c.start < from) continue;
    c.start = Math.max(0, c.start + delta);
    c.end = Math.max(c.start + 1, c.end + delta);
    if (c.words)
      c.words = c.words.map((w) => ({ ...w, start: w.start + delta, end: w.end + delta }));
  }
}

/**
 * Frames [s, e) left the timeline: markers inside go to `s`, those after move back; a subtitle
 * inside goes, one across an edge loses the part (and the words) that went, the rest moves back;
 * its text becomes the words left (its own, or spread by length for a line typed by hand).
 */
function cutTimed(doc: RgVideo, s: number, e: number) {
  const len = e - s;
  if (len <= 0) return;
  const at = (f: number) => (f >= e ? f - len : Math.min(f, s));
  const seen = new Set<number>();
  doc.markers = doc.markers.filter((m) => {
    m.frame = at(m.frame);
    if (seen.has(m.frame)) return false; // two markers on one frame: the first stays
    seen.add(m.frame);
    return true;
  });
  const out: VideoCaption[] = [];
  for (const c of doc.captions.segments) {
    if (c.end <= s) {
      out.push(c);
      continue;
    }
    if (c.start >= s && c.end <= e) continue;
    const start = at(c.start);
    const end = at(c.end);
    if (end - start < 1) continue;
    const n: VideoCaption = { ...c, start, end };
    // A line typed by hand has no words of its own: spread by length, as the transcript shows it.
    const all = c.words ?? captionWords(c);
    const words = all
      .filter((w) => (w.start + w.end) / 2 < s || (w.start + w.end) / 2 >= e)
      .map((w) => ({ ...w, start: at(w.start), end: Math.max(at(w.start) + 1, at(w.end)) }));
    if (all.length && !words.length) continue;
    if (words.length !== all.length) n.text = words.map((w) => w.text).join(" ");
    if (c.words) n.words = words;
    out.push(n);
  }
  doc.captions.segments = out;
}

/**
 * Trims the `edge` ("in" = start, "out" = end) of clip `id` by `delta` frames (positive = to the
 * right). Without `ripple` the clip neither crosses its neighbours nor leaves its file; with
 * `ripple` (the T tool) what follows moves to close or open the space, on every unlocked track.
 * Linked clips are trimmed together when `linked`. At least one frame stays.
 */
export function trimClip(
  doc0: RgVideo,
  id: string,
  edge: "in" | "out",
  delta: number,
  o: { ripple?: boolean; linked?: boolean } = {},
): RgVideo {
  const doc = clone(doc0);
  const main = doc.clips.find((c) => c.id === id);
  if (!main || isLocked(doc, main.track)) return doc0;
  const ripple = !!o.ripple;
  const ids = o.linked === false ? [id] : withLinked(doc, [id]);
  const group = doc.clips.filter((c) => ids.includes(c.id) && !isLocked(doc, c.track));
  let lo = Number.NEGATIVE_INFINITY;
  let hi = Number.POSITIVE_INFINITY;
  for (const c of group) {
    const r = room(c);
    const sorted = trackClips(doc, c.track);
    const i = sorted.findIndex((x) => x.id === c.id);
    const prev = sorted[i - 1];
    const next = sorted[i + 1];
    if (edge === "in") {
      lo = Math.max(lo, -r.left);
      hi = Math.min(hi, clipLength(c) - 1);
      if (!ripple) lo = Math.max(lo, (prev ? clipEnd(prev) : 0) - c.start);
    } else {
      hi = Math.min(hi, r.right);
      lo = Math.max(lo, 1 - clipLength(c));
      if (!ripple && next) hi = Math.min(hi, next.start - clipEnd(c));
    }
  }
  const d = Math.max(lo, Math.min(hi, Math.round(delta)));
  if (!d || !Number.isFinite(d)) return doc0;
  const oldEnd = clipEnd(main);
  for (const c of group) {
    if (edge === "in") {
      if (!ripple) c.start += d; // with ripple the clip stays and the rest slides
      c.sourceRange = {
        start: c.sourceRange.start + (isStillClip(c) ? 0 : d),
        duration: c.sourceRange.duration - d,
      };
    } else c.sourceRange = { start: c.sourceRange.start, duration: c.sourceRange.duration + d };
  }
  if (ripple) {
    const shift = edge === "in" ? -d : d;
    const moved = new Set(group.map((c) => c.id));
    // Closing: when a clip of another track crosses the frames freed, only the trimmed clips'
    // tracks close up (as a ripple delete does), or what follows would run over it.
    let only: Set<string> | undefined;
    if (shift < 0) {
      const own = new Set(group.map((c) => c.track));
      const [s0, e0] = [oldEnd + shift, oldEnd];
      if (doc.clips.some((c) => !own.has(c.track) && c.start < e0 && clipEnd(c) > s0)) only = own;
    }
    shiftAfter(doc, oldEnd, shift, moved, only);
    if (timedFollow(only)) {
      if (shift < 0) cutTimed(doc, oldEnd + shift, oldEnd);
      else shiftTimed(doc, oldEnd, shift);
    }
  }
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// The blade

/**
 * Cuts at `frame` the clips across it: only `ids` (with their linked clips) when given, every
 * unlocked track otherwise (Ctrl+B without a selection). The right halves of two linked clips
 * stay linked to each other; a transition leaving the clip now leaves from its right half.
 */
export function bladeAt(
  doc0: RgVideo,
  frame: number,
  ids?: readonly string[] | null,
  o: VideoEditOpts = {},
): RgVideo {
  const doc = clone(doc0);
  const gen = o.ids ?? videoIdGen(doc0);
  const pick = ids?.length ? new Set(withLinked(doc, ids)) : null;
  const newLinks = new Map<string, string>();
  const added: VideoClip[] = [];
  for (const c of doc.clips) {
    if (pick && !pick.has(c.id)) continue;
    if (isLocked(doc, c.track) || frame <= c.start || frame >= clipEnd(c)) continue;
    const cut = frame - c.start;
    const right: VideoClip = {
      ...c,
      id: gen("c"),
      start: frame,
      sourceRange: {
        start: c.sourceRange.start + (isStillClip(c) ? 0 : cut),
        duration: clipLength(c) - cut,
      },
      fadeIn: 0,
    };
    if (c.link) {
      let l = newLinks.get(c.link);
      if (!l) {
        l = gen("g");
        newLinks.set(c.link, l);
      }
      right.link = l;
    }
    retarget(doc, c.id, right.id);
    c.sourceRange = { start: c.sourceRange.start, duration: cut };
    c.fadeOut = 0;
    added.push(right);
  }
  if (!added.length) return doc0;
  doc.clips.push(...added);
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Deleting

/** Backspace: the clips go, the gap stays. */
export function liftClips(
  doc0: RgVideo,
  ids: readonly string[],
  o: { linked?: boolean } = {},
): RgVideo {
  const del = new Set(o.linked === false ? ids : withLinked(doc0, ids));
  const gone = doc0.clips.filter((c) => del.has(c.id) && !isLocked(doc0, c.track));
  if (!gone.length) return doc0;
  const doc = clone(doc0);
  const out = new Set(gone.map((c) => c.id));
  doc.clips = doc.clips.filter((c) => !out.has(c.id));
  return settle(doc);
}

export function mergeSpans(spans: readonly [number, number][]): [number, number][] {
  const out: [number, number][] = [];
  for (const [s, e] of [...spans].sort((a, b) => a[0] - b[0])) {
    const last = out[out.length - 1];
    if (last && s <= last[1]) last[1] = Math.max(last[1], e);
    else out.push([s, e]);
  }
  return out;
}

function closeSpan(doc: RgVideo, s: number, e: number, ownTracks: ReadonlySet<string>) {
  const len = e - s;
  const crosses = (c: VideoClip) => c.start < e && clipEnd(c) > s;
  const others = doc.tracks.filter(
    (t) =>
      !t.locked && !ownTracks.has(t.id) && doc.clips.some((c) => c.track === t.id && crosses(c)),
  );
  const tracks = new Set(
    others.length ? [...ownTracks] : doc.tracks.filter((t) => !t.locked).map((t) => t.id),
  );
  for (const c of doc.clips) if (tracks.has(c.track) && c.start >= e) c.start -= len;
  if (timedFollow(others.length ? tracks : undefined)) cutTimed(doc, s, e);
}

/**
 * Delete: the clips go and the gap closes (ripple delete). On every unlocked track when nothing
 * else crosses the gap; otherwise only on the tracks of the clips taken out.
 */
export function rippleDeleteClips(
  doc0: RgVideo,
  ids: readonly string[],
  o: { linked?: boolean } = {},
): RgVideo {
  const list = o.linked === false ? ids : withLinked(doc0, ids);
  const del = new Set(list.filter((id) => !isLocked(doc0, clipOf(doc0, id)?.track)));
  const removed = doc0.clips.filter((c) => del.has(c.id));
  if (!removed.length) return doc0;
  const doc = clone(doc0);
  doc.clips = doc.clips.filter((c) => !del.has(c.id));
  // From the rightmost, so the shifts do not disturb each other.
  const spans = mergeSpans(removed.map((c) => [c.start, clipEnd(c)])).reverse();
  const own = new Set(removed.map((c) => c.track));
  for (const [s, e] of spans) closeSpan(doc, s, e, own);
  return settle(doc);
}

/**
 * Takes frames [s, e) out of the whole timeline and closes them up (the speech cut from its
 * text, G41.5c): every unlocked track is cut at both edges, what lies between goes, what follows
 * moves back; markers and subtitles follow. Locked tracks stay as they are.
 */
export function cutTimeRange(doc0: RgVideo, s: number, e: number, o: VideoEditOpts = {}): RgVideo {
  const a = Math.max(0, Math.round(s));
  const b = Math.round(e);
  if (b <= a) return doc0;
  let doc = bladeAt(doc0, a, null, o.ids ? { ids: o.ids } : {});
  doc = bladeAt(doc, b, null, o.ids ? { ids: o.ids } : {});
  doc = doc === doc0 ? clone(doc0) : doc;
  const len = b - a;
  const open = (c: VideoClip) => !isLocked(doc, c.track);
  const before = doc.clips.length;
  doc.clips = doc.clips.filter((c) => !(open(c) && c.start >= a && clipEnd(c) <= b));
  let moved = false;
  for (const c of doc.clips)
    if (open(c) && c.start >= b) {
      c.start -= len;
      moved = true;
    }
  const timed = JSON.stringify([doc.markers, doc.captions.segments]);
  cutTimed(doc, a, b);
  const timedChanged = timed !== JSON.stringify([doc.markers, doc.captions.segments]);
  if (doc.clips.length === before && !moved && !timedChanged) return doc0;
  return settle(doc);
}

/** Closes the gap containing `frame` on a track (a click on the gap, then Delete). */
export function closeGap(doc0: RgVideo, trackId: string, frame: number): RgVideo {
  if (isLocked(doc0, trackId)) return doc0;
  let s = 0;
  for (const c of trackClips(doc0, trackId)) {
    if (frame < c.start) {
      if (frame < s) return doc0;
      const doc = clone(doc0);
      closeSpan(doc, s, c.start, new Set([trackId]));
      return settle(doc);
    }
    s = clipEnd(c);
  }
  return doc0;
}

// -------------------------------------------------------------------------------------------
// Editing from the media pool and the source viewer

/** Ken Burns as montatore's presets: zoom in or out, panning towards a side. */
export function kenBurnsPreset(
  zoom: "in" | "out",
  pan: "left" | "right" | "up" | "down",
): VideoKenBurns {
  const full: VideoRect = { x: 0, y: 0, w: 1, h: 1 };
  const k = 0.8;
  const side = (1 - k) / 2;
  const at: Record<typeof pan, VideoRect> = {
    left: { x: 0, y: side, w: k, h: k },
    right: { x: 1 - k, y: side, w: k, h: k },
    up: { x: side, y: 0, w: k, h: k },
    down: { x: side, y: 1 - k, w: k, h: k },
  };
  const near = { ...at[pan] };
  for (const key of ["x", "y", "w", "h"] as const) near[key] = Math.round(near[key] * 1000) / 1000;
  return zoom === "in" ? { from: full, to: near } : { from: near, to: full };
}

export interface PlaceOpts extends VideoEditOpts {
  /** "overwrite" (F10) or "insert" (F9: opens the space by moving everything after it). */
  mode?: "overwrite" | "insert";
  /** The destination tracks; the audio only for a file with sound. */
  targets?: { video?: string | null; audio?: string | null };
  audioEnabled?: boolean;
  /** Video fades, in frames. */
  fade?: number;
  kenBurns?: VideoKenBurns | null;
  name?: string;
}

/**
 * Puts [srcIn, srcOut) of `ref` at `frame`: video on `targets.video`, audio (a media file with
 * sound) on `targets.audio`, linked. A picture gets Ken Burns (zoom in, to the right) unless said.
 */
export function placeClip(
  doc0: RgVideo,
  ref: VideoRef,
  srcIn: number,
  srcOut: number,
  frame: number,
  o: PlaceOpts = {},
): RgVideo {
  let doc = clone(doc0);
  const gen = o.ids ?? videoIdGen(doc0);
  const media = isMediaRef(ref);
  const still = !media || !!ref.still;
  const at = Math.max(0, Math.round(frame));
  const dur = Math.max(1, Math.round(srcOut) - Math.round(srcIn));
  const targets = o.targets ?? { video: "V1", audio: "A1" };
  const vt = targets.video ? trackOf(doc, targets.video) : undefined;
  const at_ = targets.audio ? trackOf(doc, targets.audio) : undefined;
  const withVideo = !!vt && vt.kind === "Video" && !vt.locked;
  const withAudio =
    !!at_ && at_.kind === "Audio" && !at_.locked && media && !still && ref.audio !== false;
  if (!withVideo && !withAudio) return doc0;
  if (o.mode === "insert") {
    doc = bladeAt(doc, at, null, { ids: gen });
    if (doc === doc0) doc = clone(doc0);
    shiftAfter(doc, at, dur);
    shiftTimed(doc, at, dur);
  }
  const link = withVideo && withAudio ? gen("g") : undefined;
  const src = { start: still ? 0 : Math.max(0, Math.round(srcIn)), duration: dur };
  const base = {
    start: at,
    sourceRange: src,
    ref: clone(ref),
    ...(o.name && { name: o.name }),
    ...(link && { link }),
    volume: 0,
    fit: "fill" as const,
  };
  if (withVideo && vt) {
    if (o.mode !== "insert") carve(doc, vt.id, at, at + dur, gen);
    const fade = Math.max(0, Math.round(o.fade ?? 0));
    const kb =
      o.kenBurns === undefined
        ? media && still
          ? kenBurnsPreset("in", "right")
          : undefined
        : o.kenBurns;
    doc.clips.push({
      id: gen("c"),
      track: vt.id,
      ...base,
      enabled: true,
      fadeIn: fade,
      fadeOut: fade,
      ...(kb && { kenBurns: kb }),
    });
  }
  if (withAudio && at_) {
    if (o.mode !== "insert") carve(doc, at_.id, at, at + dur, gen);
    doc.clips.push({
      id: gen("c"),
      track: at_.id,
      ...base,
      enabled: o.audioEnabled !== false,
      fadeIn: 0,
      fadeOut: 0,
    });
  }
  return settle(doc);
}

/** Appends after the last clip of the destination tracks (Shift+F12). */
export function appendClip(
  doc0: RgVideo,
  ref: VideoRef,
  srcIn: number,
  srcOut: number,
  o: PlaceOpts = {},
): RgVideo {
  const targets = o.targets ?? { video: "V1", audio: "A1" };
  const at = Math.max(
    0,
    ...[targets.video, targets.audio]
      .filter((t): t is string => !!t)
      .map((t) => trackClips(doc0, t).reduce((m, c) => Math.max(m, clipEnd(c)), 0)),
  );
  return placeClip(doc0, ref, srcIn, srcOut, at, { ...o, mode: "overwrite", targets });
}

// -------------------------------------------------------------------------------------------
// Copy and paste

/** Copy: the clips with their positions relative to the first. */
export function copyClips(
  doc: RgVideo,
  ids: readonly string[],
  o: { linked?: boolean } = {},
): VideoClip[] {
  const set = new Set(o.linked === false ? ids : withLinked(doc, ids));
  const clips = doc.clips.filter((c) => set.has(c.id)).map((c) => clone(c));
  if (!clips.length) return [];
  const base = Math.min(...clips.map((c) => c.start));
  return clips.map((c) => ({ ...c, start: c.start - base }));
}

/** Paste at `frame`, on the same tracks, overwriting; links among the copies kept, new. */
export function pasteClips(
  doc0: RgVideo,
  copied: readonly VideoClip[],
  frame: number,
  o: VideoEditOpts = {},
): RgVideo {
  if (!copied.length) return doc0;
  const doc = clone(doc0);
  const gen = o.ids ?? videoIdGen(doc0);
  const links = new Map<string, string>();
  const added: VideoClip[] = [];
  for (const c of copied) {
    if (!trackOf(doc, c.track) || isLocked(doc, c.track)) continue;
    const n: VideoClip = { ...clone(c), id: gen("c"), start: c.start + Math.max(0, frame) };
    delete n.link;
    if (c.link) {
      let l = links.get(c.link);
      if (!l) {
        l = gen("g");
        links.set(c.link, l);
      }
      n.link = l;
    }
    added.push(n);
  }
  if (!added.length) return doc0;
  for (const c of added) carve(doc, c.track, c.start, clipEnd(c), gen);
  doc.clips.push(...added);
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Links and properties

export function unlinkClips(doc0: RgVideo, ids: readonly string[]): RgVideo {
  const set = new Set(withLinked(doc0, ids));
  if (!doc0.clips.some((c) => set.has(c.id) && c.link)) return doc0;
  const doc = clone(doc0);
  for (const c of doc.clips) if (set.has(c.id)) delete c.link;
  return settle(doc);
}

/** Links the clips given (a video and its audio, or as they come: one group). */
export function linkClips(doc0: RgVideo, ids: readonly string[], o: VideoEditOpts = {}): RgVideo {
  const set = new Set(ids);
  if (doc0.clips.filter((c) => set.has(c.id)).length < 2) return doc0;
  const doc = clone(doc0);
  const g = (o.ids ?? videoIdGen(doc0))("g");
  for (const c of doc.clips) if (set.has(c.id)) c.link = g;
  return settle(doc);
}

/** What `setClipProps` may change (null takes an optional one away). */
export interface VideoClipProps {
  enabled?: boolean;
  volume?: number;
  fadeIn?: number;
  fadeOut?: number;
  kenBurns?: VideoKenBurns | null;
  fit?: "fill" | "fit";
  background?: "black" | "blur" | null;
  crop?: VideoRect | null;
  speed?: number | null;
  name?: string | null;
  metadata?: Record<string, unknown> | null;
}

const OPTIONAL_PROPS = ["kenBurns", "background", "crop", "speed", "name", "metadata"] as const;

export function setClipProps(
  doc0: RgVideo,
  ids: readonly string[],
  props: VideoClipProps,
): RgVideo {
  const doc = clone(doc0);
  const set = new Set(ids);
  let changed = false;
  for (const c of doc.clips) {
    if (!set.has(c.id) || isLocked(doc, c.track)) continue;
    changed = true;
    const m = c as unknown as Record<string, unknown>;
    for (const [k, v] of Object.entries(props)) {
      if (v === undefined) continue;
      if (v === null) {
        if ((OPTIONAL_PROPS as readonly string[]).includes(k)) delete m[k];
        continue;
      }
      m[k] = clone(v);
    }
    c.volume = Math.max(-60, Math.min(12, Math.round(c.volume * 10) / 10));
    c.fadeIn = Math.round(c.fadeIn);
    c.fadeOut = Math.round(c.fadeOut);
  }
  if (!changed) return doc0;
  return settle(doc);
}

/** A text's or a colour's content (the clip keeps its place and length). */
export function setGenerator(
  doc0: RgVideo,
  id: string,
  patch: Partial<Omit<VideoTextRef, "generator">> & Partial<Omit<VideoColorRef, "generator">>,
): RgVideo {
  const c = clipOf(doc0, id);
  if (!c || isMediaRef(c.ref) || isLocked(doc0, c.track)) return doc0;
  const doc = clone(doc0);
  const n = clipOf(doc, id) as VideoClip;
  if (isTextRef(n.ref)) {
    const r: VideoTextRef = { ...n.ref };
    if (patch.text?.length) r.text = patch.text;
    if (patch.style !== undefined) r.style = patch.style;
    if (patch.position !== undefined) r.position = patch.position;
    n.ref = r;
  } else if (patch.color !== undefined) n.ref = { generator: "color", color: patch.color };
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Tracks

export function addTrack(doc0: RgVideo, kind: VideoTrackKind, name?: string): RgVideo {
  const prefix = kind === "Video" ? "V" : "A";
  const n = Math.max(0, ...lanes(doc0, kind).map(trackNumber)) + 1;
  if (n > 99) return doc0;
  const doc = clone(doc0);
  const id = `${prefix}${n}`;
  const t: VideoTrack = { id, kind, name: name?.trim().slice(0, 60) || id, locked: false };
  if (kind === "Video") t.hidden = false;
  else t.muted = false;
  doc.tracks.push(t);
  return settle(doc);
}

/** Takes away an empty track (V1 and A1 always stay); ducking under it is forgotten. */
export function removeTrack(doc0: RgVideo, id: string): RgVideo {
  if (id === "V1" || id === "A1" || !trackOf(doc0, id) || doc0.clips.some((c) => c.track === id))
    return doc0;
  const doc = clone(doc0);
  doc.tracks = doc.tracks.filter((t) => t.id !== id);
  for (const t of doc.tracks)
    if (t.duck) {
      const under = t.duck.under.filter((u) => u !== id);
      if (under.length) t.duck = { ...t.duck, under };
      else delete t.duck;
    }
  return settle(doc);
}

export interface VideoTrackProps {
  name?: string;
  locked?: boolean;
  hidden?: boolean;
  muted?: boolean;
  duck?: VideoDuck | null;
}

export function setTrack(doc0: RgVideo, id: string, props: VideoTrackProps): RgVideo {
  if (!trackOf(doc0, id)) return doc0;
  const doc = clone(doc0);
  const t = trackOf(doc, id) as VideoTrack;
  if (props.name !== undefined) t.name = props.name.trim().slice(0, 60) || t.id;
  if (props.locked !== undefined) t.locked = props.locked;
  if (props.hidden !== undefined && t.kind === "Video") t.hidden = props.hidden;
  if (props.muted !== undefined && t.kind === "Audio") t.muted = props.muted;
  if (props.duck === null) delete t.duck;
  else if (props.duck && t.kind === "Audio") t.duck = clone(props.duck);
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Markers

export function addMarker(
  doc0: RgVideo,
  frame: number,
  o: VideoEditOpts & { color?: VideoMarkerColor; note?: string; duration?: number } = {},
): RgVideo {
  const f = Math.max(0, Math.round(frame));
  if (doc0.markers.some((m) => m.frame === f)) return doc0;
  const doc = clone(doc0);
  const m: VideoMarker = {
    id: (o.ids ?? videoIdGen(doc0))("m"),
    frame: f,
    color: o.color ?? "BLUE",
    note: (o.note ?? "").slice(0, 500),
  };
  if (o.duration) m.duration = Math.max(0, Math.round(o.duration));
  doc.markers.push(m);
  return settle(doc);
}

export function removeMarker(doc0: RgVideo, id: string): RgVideo {
  if (!doc0.markers.some((m) => m.id === id)) return doc0;
  const doc = clone(doc0);
  doc.markers = doc.markers.filter((m) => m.id !== id);
  return settle(doc);
}

export function setMarker(
  doc0: RgVideo,
  id: string,
  props: Partial<Omit<VideoMarker, "id">>,
): RgVideo {
  if (!doc0.markers.some((m) => m.id === id)) return doc0;
  const doc = clone(doc0);
  const m = doc.markers.find((x) => x.id === id) as VideoMarker;
  if (props.frame !== undefined) m.frame = Math.max(0, Math.round(props.frame));
  if (props.color !== undefined) m.color = props.color;
  if (props.note !== undefined) m.note = props.note.slice(0, 500);
  if (props.duration !== undefined) m.duration = Math.max(0, Math.round(props.duration));
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Transitions

/** The clip that starts exactly where `from` ends, on its track. */
export function nextClip(doc: RgVideo, from: VideoClip): VideoClip | undefined {
  return doc.clips.find((c) => c.track === from.track && c.start === clipEnd(from));
}

/**
 * A transition at the cut after clip `fromId` (the next clip must start where it ends), `length`
 * frames centred on the cut and kept inside both clips; the one already there is replaced.
 */
export function addTransition(
  doc0: RgVideo,
  fromId: string,
  kind: VideoTransitionKind,
  length: number,
  o: VideoEditOpts = {},
): RgVideo {
  const a = clipOf(doc0, fromId);
  if (!a || isLocked(doc0, a.track)) return doc0;
  const b = nextClip(doc0, a);
  if (!b) return doc0;
  const len = Math.max(1, Math.round(length));
  const inOffset = Math.min(Math.floor(len / 2), clipLength(a));
  const outOffset = Math.min(len - inOffset, clipLength(b));
  const doc = clone(doc0);
  const old = doc.transitions.find((t) => t.from === a.id || t.to === b.id);
  const t: VideoTransition = {
    id: old?.id ?? (o.ids ?? videoIdGen(doc0))("t"),
    track: a.track,
    from: a.id,
    to: b.id,
    kind,
    inOffset,
    outOffset,
  };
  doc.transitions = [
    ...doc.transitions.filter((x) => x.from !== a.id && x.to !== b.id && x.id !== t.id),
    t,
  ];
  return settle(doc);
}

export function removeTransition(doc0: RgVideo, id: string): RgVideo {
  const t = doc0.transitions.find((x) => x.id === id);
  if (!t || isLocked(doc0, t.track)) return doc0;
  const doc = clone(doc0);
  doc.transitions = doc.transitions.filter((x) => x.id !== id);
  return settle(doc);
}

export function setTransition(
  doc0: RgVideo,
  id: string,
  props: { kind?: VideoTransitionKind; inOffset?: number; outOffset?: number },
): RgVideo {
  const t0 = doc0.transitions.find((x) => x.id === id);
  if (!t0 || isLocked(doc0, t0.track)) return doc0;
  const doc = clone(doc0);
  const t = doc.transitions.find((x) => x.id === id) as VideoTransition;
  if (props.kind) t.kind = props.kind;
  if (props.inOffset !== undefined) t.inOffset = Math.max(0, Math.round(props.inOffset));
  if (props.outOffset !== undefined) t.outOffset = Math.max(0, Math.round(props.outOffset));
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Texts and titles: generator clips on a video track

/**
 * A text (or a colour) `length` frames long at `frame`: on `track` (overwriting there), or on the
 * highest unlocked video track free at that time, or on a new video track on top.
 */
export function addGenerator(
  doc0: RgVideo,
  ref: VideoTextRef | VideoColorRef,
  frame: number,
  length: number,
  o: VideoEditOpts & { track?: string; fade?: number } = {},
): RgVideo {
  const at = Math.max(0, Math.round(frame));
  const len = Math.max(1, Math.round(length));
  let doc = doc0;
  let track = o.track;
  if (track) {
    const t = trackOf(doc0, track);
    if (t?.kind !== "Video" || t.locked) return doc0;
  } else {
    const free = lanes(doc0, "Video")
      .reverse()
      .find(
        (id) =>
          !isLocked(doc0, id) &&
          !doc0.clips.some((c) => c.track === id && c.start < at + len && clipEnd(c) > at),
      );
    const top = lanes(doc0, "Video").at(-1);
    if (free && free === top) track = free;
    else {
      doc = addTrack(doc0, "Video");
      if (doc === doc0) return doc0;
      track = lanes(doc, "Video").at(-1) as string;
    }
  }
  return placeClip(doc, ref, 0, len, at, {
    ...(o.ids && { ids: o.ids }),
    targets: { video: track, audio: null },
    fade: o.fade ?? 0,
    kenBurns: null,
  });
}

// -------------------------------------------------------------------------------------------
// Captions

export function setCaptionSettings(doc0: RgVideo, props: Partial<VideoCaptionSettings>): RgVideo {
  const doc = clone(doc0);
  const c = doc.captions;
  if (props.language !== undefined) c.language = props.language.slice(0, 20);
  if (props.burnIn !== undefined) c.burnIn = props.burnIn;
  if (props.style !== undefined) c.style = props.style;
  if (props.position !== undefined) c.position = props.position;
  return JSON.stringify(c) === JSON.stringify(doc0.captions) ? doc0 : settle(doc);
}

const cleanWords = (w: readonly VideoCaptionWord[] | undefined) =>
  w
    ?.filter((x) => x.end >= x.start)
    .slice(0, 500)
    .map((x) => ({
      start: Math.round(x.start),
      end: Math.round(x.end),
      text: x.text.slice(0, 200),
    }));

/** Every subtitle replaced (G41.4 writes them from the transcription). */
export function setCaptionSegments(
  doc0: RgVideo,
  segments: readonly { start: number; end: number; text: string; words?: VideoCaptionWord[] }[],
  o: VideoEditOpts = {},
): RgVideo {
  const doc = clone(doc0);
  doc.captions.segments = [];
  const gen = o.ids ?? videoIdGen(doc);
  for (const s of segments) {
    const start = Math.max(0, Math.round(s.start));
    const end = Math.round(s.end);
    if (end <= start) continue;
    const words = cleanWords(s.words);
    doc.captions.segments.push({
      id: gen("s"),
      start,
      end,
      text: s.text.slice(0, 2000),
      ...(words?.length && { words }),
    });
  }
  return settle(doc);
}

export function addCaption(
  doc0: RgVideo,
  start: number,
  end: number,
  text: string,
  o: VideoEditOpts = {},
): RgVideo {
  const s = Math.max(0, Math.round(start));
  const e = Math.round(end);
  if (e <= s) return doc0;
  const doc = clone(doc0);
  doc.captions.segments.push({
    id: (o.ids ?? videoIdGen(doc0))("s"),
    start: s,
    end: e,
    text: text.slice(0, 2000),
  });
  return settle(doc);
}

export function setCaption(
  doc0: RgVideo,
  id: string,
  props: { start?: number; end?: number; text?: string },
): RgVideo {
  const old = doc0.captions.segments.find((s) => s.id === id);
  if (!old) return doc0;
  const start = Math.max(0, Math.round(props.start ?? old.start));
  const end = Math.round(props.end ?? old.end);
  if (end <= start) return doc0;
  const doc = clone(doc0);
  const s = doc.captions.segments.find((x) => x.id === id) as VideoCaption;
  s.start = start;
  s.end = end;
  if (props.text !== undefined && props.text !== s.text) {
    s.text = props.text.slice(0, 2000);
    delete s.words; // the words were of the old text
  }
  return settle(doc);
}

/** A subtitle moved by `delta` frames with its words (never before frame 0). */
export function moveCaption(doc0: RgVideo, id: string, delta: number): RgVideo {
  const old = doc0.captions.segments.find((x) => x.id === id);
  if (!old) return doc0;
  const d = Math.max(-old.start, Math.round(delta));
  if (!d) return doc0;
  const doc = clone(doc0);
  const s = doc.captions.segments.find((x) => x.id === id) as VideoCaption;
  s.start += d;
  s.end += d;
  if (s.words) s.words = s.words.map((w) => ({ ...w, start: w.start + d, end: w.end + d }));
  return settle(doc);
}

export function removeCaptions(doc0: RgVideo, ids: readonly string[]): RgVideo {
  const set = new Set(ids);
  if (!doc0.captions.segments.some((s) => set.has(s.id))) return doc0;
  const doc = clone(doc0);
  doc.captions.segments = doc.captions.segments.filter((s) => !set.has(s.id));
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// The format

/**
 * Every frame value at another rate (rounded; order and adjacency are kept, since rounding never
 * swaps two values).
 */
export function retimeTimeline(doc0: RgVideo, rate: VideoRate): RgVideo {
  const k = fps(rate) / fps(doc0.format.rate);
  if (k === 1) {
    if (rate.num === doc0.format.rate.num && rate.den === doc0.format.rate.den) return doc0;
    const doc = clone(doc0);
    doc.format.rate = { ...rate };
    return settle(doc);
  }
  const r = (f: number) => Math.round(f * k);
  const doc = clone(doc0);
  doc.format.rate = { ...rate };
  for (const c of doc.clips) {
    const end = r(clipEnd(c));
    c.start = r(c.start);
    c.sourceRange = { start: r(c.sourceRange.start), duration: Math.max(1, end - c.start) };
    c.fadeIn = r(c.fadeIn);
    c.fadeOut = r(c.fadeOut);
    if (isMediaRef(c.ref) && c.ref.frames !== undefined)
      c.ref = { ...c.ref, frames: Math.max(1, r(c.ref.frames)) };
  }
  for (const t of doc.transitions) {
    t.inOffset = r(t.inOffset);
    t.outOffset = r(t.outOffset);
  }
  for (const m of doc.markers) {
    m.frame = r(m.frame);
    if (m.duration !== undefined) m.duration = r(m.duration);
  }
  for (const s of doc.captions.segments) {
    s.start = r(s.start);
    s.end = Math.max(s.start + 1, r(s.end));
    if (s.words) s.words = s.words.map((w) => ({ ...w, start: r(w.start), end: r(w.end) }));
  }
  return settle(doc);
}

/**
 * The format changed: a shape alone takes the usual size for it (the short side kept), a rate
 * retimes every frame value.
 */
export function setFormat(doc0: RgVideo, props: Partial<VideoFormat>): RgVideo {
  let doc = props.rate ? retimeTimeline(doc0, props.rate) : doc0;
  const f = doc.format;
  let next: VideoFormat = { ...f };
  if (
    props.aspect &&
    props.aspect !== "free" &&
    props.width === undefined &&
    props.height === undefined
  )
    next = formatFor(props.aspect, Math.min(f.width, f.height), f.rate);
  else if (props.aspect) next.aspect = props.aspect;
  if (props.width !== undefined) next.width = even(props.width);
  if (props.height !== undefined) next.height = even(props.height);
  if (JSON.stringify(next) === JSON.stringify(f)) return doc;
  if (doc === doc0) doc = clone(doc0);
  doc.format = next;
  return settle(doc);
}

// -------------------------------------------------------------------------------------------
// Navigation and snapping

/** Edit points (starts and ends of clips), in order: for ↑ / ↓. */
export function editPoints(doc: RgVideo): number[] {
  return [...new Set([0, ...doc.clips.flatMap((c) => [c.start, clipEnd(c)])])].sort(
    (a, b) => a - b,
  );
}

export function prevEdit(doc: RgVideo, frame: number): number {
  return [...editPoints(doc)].reverse().find((f) => f < frame) ?? 0;
}

export function nextEdit(doc: RgVideo, frame: number): number {
  return editPoints(doc).find((f) => f > frame) ?? timelineDuration(doc);
}

/** Points to snap to: the other clips' edges, the playhead, the markers. */
export function snapPoints(
  doc: RgVideo,
  exclude: ReadonlySet<string> = new Set(),
  playhead: number | null = null,
): number[] {
  const pts = new Set([0]);
  for (const c of doc.clips)
    if (!exclude.has(c.id)) {
      pts.add(c.start);
      pts.add(clipEnd(c));
    }
  for (const m of doc.markers) pts.add(m.frame);
  if (playhead !== null) pts.add(playhead);
  return [...pts];
}

/** The nearest point within `threshold` frames, or the value itself. */
export function snap(frame: number, points: readonly number[], threshold: number): number {
  let best = frame;
  let dist = threshold + 1;
  for (const p of points) {
    const d = Math.abs(p - frame);
    if (d <= threshold && d < dist) {
      best = p;
      dist = d;
    }
  }
  return best;
}

// -------------------------------------------------------------------------------------------
// Problems: what a valid timeline never has (an edit that adds one is refused)

/** Each problem in words, naming its ids (the host compares before and after). */
export function timelineProblems(doc: RgVideo): string[] {
  const out: string[] = [];
  const kinds = new Map(doc.tracks.map((t) => [t.id, t.kind]));
  const seen = new Set<string>();
  for (const t of doc.tracks) {
    if (seen.has(`track:${t.id}`)) out.push(`track ${t.id} is there twice`);
    seen.add(`track:${t.id}`);
    if ((t.id[0] === "V") !== (t.kind === "Video"))
      out.push(`track ${t.id} is not of kind ${t.kind}`);
    for (const u of t.duck?.under ?? [])
      if (kinds.get(u) !== "Audio") out.push(`track ${t.id} ducks under ${u}, not an audio track`);
  }
  if (kinds.get("V1") !== "Video") out.push("there is no track V1");
  if (kinds.get("A1") !== "Audio") out.push("there is no track A1");
  const ends = new Map<string, VideoClip>();
  const ids = new Set<string>();
  for (const c of [...doc.clips].sort((a, b) => byStr(a.track, b.track) || a.start - b.start)) {
    if (ids.has(c.id)) out.push(`clip ${c.id} is there twice`);
    ids.add(c.id);
    const kind = kinds.get(c.track);
    if (!kind) {
      out.push(`clip ${c.id} is on track ${c.track}, which does not exist`);
      continue;
    }
    if (kind === "Audio") {
      if (!isMediaRef(c.ref))
        out.push(`clip ${c.id} is a ${c.ref.generator} on audio track ${c.track}`);
      else if (c.ref.still) out.push(`clip ${c.id} is a picture on audio track ${c.track}`);
      else if (c.ref.audio === false)
        out.push(`clip ${c.id} has no sound, on audio track ${c.track}`);
    }
    if (
      isMediaRef(c.ref) &&
      !c.ref.still &&
      c.ref.frames !== undefined &&
      clipEnd({ ...c, start: c.sourceRange.start }) > c.ref.frames
    )
      out.push(`clip ${c.id} goes past the end of ${c.ref.media}`);
    const half = Math.floor(clipLength(c) / 2);
    if (c.fadeIn > half || c.fadeOut > half) out.push(`clip ${c.id} fades longer than half of it`);
    const prev = ends.get(c.track);
    if (prev && clipEnd(prev) > c.start)
      out.push(`clips ${prev.id} and ${c.id} overlap on ${c.track}`);
    ends.set(c.track, c);
  }
  const links = new Map<string, number>();
  for (const c of doc.clips) if (c.link) links.set(c.link, (links.get(c.link) ?? 0) + 1);
  const valid = new Set(validTransitions(doc, doc.transitions).map((t) => t.id));
  const tids = new Set<string>();
  for (const t of doc.transitions) {
    if (tids.has(t.id)) out.push(`transition ${t.id} is there twice`);
    tids.add(t.id);
    if (!valid.has(t.id))
      out.push(
        `transition ${t.id} is not between two adjacent clips of ${t.track} (${t.from}, ${t.to})`,
      );
  }
  const mids = new Set<string>();
  for (const m of doc.markers) {
    if (mids.has(m.id)) out.push(`marker ${m.id} is there twice`);
    mids.add(m.id);
  }
  const sids = new Set<string>();
  for (const s of doc.captions.segments) {
    if (sids.has(s.id)) out.push(`subtitle ${s.id} is there twice`);
    sids.add(s.id);
    if (s.end <= s.start) out.push(`subtitle ${s.id} ends before it starts`);
  }
  return out;
}

// -------------------------------------------------------------------------------------------
// Cleaning: what a file holds made into a valid timeline, never an exception (as montatore's
// TimelineSanitizer): wrong values corrected or left out.

/** What is known of a file of the project (ffprobe, G41.6): its length at the timeline's rate. */
export interface VideoProbe {
  /** null: a picture. */
  frames?: number | null;
  audio?: boolean;
}

type Raw = Record<string, unknown>;
const isObj = (v: unknown): v is Raw => !!v && typeof v === "object" && !Array.isArray(v);
const intOf = (v: unknown, min: number, max: number, def: number): number => {
  const n = typeof v === "string" && v.trim() !== "" ? Number(v) : v;
  return typeof n === "number" && Number.isFinite(n)
    ? Math.max(min, Math.min(max, Math.round(n)))
    : def;
};
const numOf = (v: unknown, min: number, max: number, def: number): number =>
  typeof v === "number" && Number.isFinite(v) ? Math.max(min, Math.min(max, v)) : def;
const strOf = (v: unknown, max: number): string =>
  typeof v === "string" || typeof v === "number" ? String(v).trim().slice(0, max) : "";
const idOf = (v: unknown): string => {
  const s = strOf(v, 80);
  return /^[A-Za-z0-9_.:-]+$/.test(s) ? s : "";
};
const oneOf = <T extends string>(v: unknown, list: readonly T[], def: T): T =>
  list.includes(v as T) ? (v as T) : def;
const F = 86_400_000;

function rectOf(v: unknown): VideoRect | undefined {
  if (!isObj(v)) return undefined;
  const w = numOf(v.w, 0.01, 1, 1);
  const h = numOf(v.h, 0.01, 1, 1);
  const room = (n: number) => Math.round((1 - n) * 1e6) / 1e6;
  return { x: numOf(v.x, 0, room(w), 0), y: numOf(v.y, 0, room(h), 0), w, h };
}

function rateOf(v: unknown): VideoRate {
  if (typeof v === "number" && v > 0) {
    // 29.97 and its kin as NTSC fractions.
    for (const n of [24, 30, 48, 60, 120])
      if (Math.abs(v - (n * 1000) / 1001) < 0.01) return { num: n * 1000, den: 1001 };
    return { num: Math.round(v * 1000), den: 1000 };
  }
  if (isObj(v)) return { num: intOf(v.num, 1, 1_000_000, 30), den: intOf(v.den, 1, 1_000_000, 1) };
  return { num: 30, den: 1 };
}

function reduceRate(r: VideoRate): VideoRate {
  const g = (a: number, b: number): number => (b ? g(b, a % b) : a);
  const d = g(r.num, r.den) || 1;
  return { num: r.num / d, den: r.den / d };
}

function formatOf(v: unknown): VideoFormat {
  if (!isObj(v)) return formatFor("16:9");
  return {
    width: intOf(v.width, 16, 16_384, 1920),
    height: intOf(v.height, 16, 16_384, 1080),
    rate: reduceRate(rateOf(v.rate)),
    aspect: oneOf(v.aspect, VIDEO_ASPECTS, "16:9"),
  };
}

function refOf(v: unknown, probes: Record<string, VideoProbe> | undefined): VideoRef | undefined {
  if (!isObj(v)) return undefined;
  if (v.generator === "text") {
    const text = strOf(v.text, 2000);
    if (!text) return undefined;
    return {
      generator: "text",
      text,
      style: oneOf(v.style, VIDEO_TEXT_STYLES, "title"),
      position: oneOf(v.position, VIDEO_TEXT_POSITIONS, "center"),
    };
  }
  if (v.generator === "color")
    return {
      generator: "color",
      color: typeof v.color === "string" && /^#[0-9a-fA-F]{6}$/.test(v.color) ? v.color : "#000000",
    };
  const media = typeof v.media === "string" ? v.media.trim().slice(0, 4000) : "";
  if (!media) return undefined;
  const p = probes?.[media];
  const r: VideoMediaRef = { media };
  const still = p ? p.frames === null : v.still === true;
  const frames = p ? (p.frames ?? undefined) : v.frames;
  if (still) r.still = true;
  else if (frames !== undefined && frames !== null) r.frames = intOf(frames, 1, F, 1);
  const audio = p?.audio ?? (typeof v.audio === "boolean" ? v.audio : undefined);
  if (audio !== undefined && !still) r.audio = audio;
  return r;
}

function tracksOf(raw: unknown): VideoTrack[] {
  const byId = new Map<string, VideoTrack>();
  for (const t of Array.isArray(raw) ? raw : []) {
    if (!isObj(t)) continue;
    const id = typeof t.id === "string" ? t.id : "";
    if (!/^[VA][1-9]\d?$/.test(id) || byId.has(id)) continue;
    byId.set(id, trackFrom(id, t));
  }
  if (!byId.has("V1")) byId.set("V1", trackFrom("V1", {}));
  if (!byId.has("A1")) byId.set("A1", trackFrom("A1", {}));
  const tracks = [...byId.values()];
  const audio = new Set(tracks.filter((t) => t.kind === "Audio").map((t) => t.id));
  for (const t of tracks)
    if (t.duck) {
      const under = t.duck.under.filter((u) => audio.has(u) && u !== t.id);
      if (under.length) t.duck = { ...t.duck, under };
      else delete t.duck;
    }
  return tracks;
}

function trackFrom(id: string, t: Raw): VideoTrack {
  const kind: VideoTrackKind = id[0] === "V" ? "Video" : "Audio";
  const track: VideoTrack = { id, kind, name: strOf(t.name, 60) || id, locked: t.locked === true };
  if (kind === "Video") track.hidden = t.hidden === true;
  else {
    track.muted = t.muted === true;
    const d = t.duck;
    if (isObj(d) && Array.isArray(d.under)) {
      const under = d.under.filter(
        (u): u is string => typeof u === "string" && /^A[1-9]\d?$/.test(u),
      );
      if (under.length)
        track.duck = {
          under: [...new Set(under)].slice(0, 20),
          amountDb: numOf(d.amountDb, -40, 0, -12),
          attackMs: intOf(d.attackMs, 0, 5000, 200),
          releaseMs: intOf(d.releaseMs, 0, 10_000, 600),
        };
    }
  }
  return track;
}

function clipFrom(
  c: unknown,
  kinds: Map<string, VideoTrackKind>,
  probes: Record<string, VideoProbe> | undefined,
): VideoClip | undefined {
  if (!isObj(c)) return undefined;
  const id = idOf(c.id);
  const track = typeof c.track === "string" ? c.track : "";
  const kind = kinds.get(track);
  const ref = refOf(c.ref, probes);
  if (!id || !kind || !ref) return undefined;
  if (kind === "Audio" && (!isMediaRef(ref) || ref.still || ref.audio === false)) return undefined;
  const sr = isObj(c.sourceRange) ? c.sourceRange : {};
  const still = !isMediaRef(ref) || !!ref.still;
  let start = still ? 0 : intOf(sr.start, 0, F, 0);
  let dur = intOf(sr.duration, 0, F, 0);
  if (isMediaRef(ref) && !still && ref.frames !== undefined) {
    start = Math.min(start, ref.frames - 1);
    dur = Math.min(dur, ref.frames - start);
  }
  if (dur < 1) return undefined;
  const half = Math.floor(dur / 2);
  const clip: VideoClip = {
    id,
    track,
    start: intOf(c.start, 0, F, 0),
    sourceRange: { start, duration: dur },
    ref,
    enabled: c.enabled !== false,
    volume: Math.round(numOf(c.volume, -60, 12, 0) * 10) / 10,
    fadeIn: intOf(c.fadeIn, 0, half, 0),
    fadeOut: intOf(c.fadeOut, 0, half, 0),
    fit: c.fit === "fit" ? "fit" : "fill",
  };
  const name = strOf(c.name, 200);
  if (name) clip.name = name;
  const link = idOf(c.link);
  if (link) clip.link = link;
  if (isObj(c.kenBurns)) {
    const from = rectOf(c.kenBurns.from);
    const to = rectOf(c.kenBurns.to);
    if (from && to) clip.kenBurns = { from, to };
  }
  if (c.background === "black" || c.background === "blur") clip.background = c.background;
  const crop = rectOf(c.crop);
  if (crop) clip.crop = crop;
  if (typeof c.speed === "number" && Number.isFinite(c.speed) && c.speed !== 1)
    clip.speed = numOf(c.speed, 0.1, 10, 1);
  if (isObj(c.metadata)) clip.metadata = c.metadata;
  return clip;
}

/**
 * A file's timeline made valid: tracks V1/A1 always there, clips of the right kind for their
 * track and inside their file (pictures without limit), no clip overlapping another on its
 * track (the later one is cut at its head, or left out), links of a single clip dropped,
 * transitions only between adjacent clips, markers and subtitles in order. `probes` (by path)
 * correct what the file says of its media.
 */
export function cleanTimeline(raw: unknown, probes?: Record<string, VideoProbe>): RgVideo {
  const d = isObj(raw) ? raw : {};
  const tracks = tracksOf(d.tracks);
  const kinds = new Map(tracks.map((t) => [t.id, t.kind]));
  const seen = new Set<string>();
  const clips: VideoClip[] = [];
  for (const c of Array.isArray(d.clips) ? d.clips : []) {
    const clip = clipFrom(c, kinds, probes);
    if (!clip || seen.has(clip.id)) continue;
    seen.add(clip.id);
    clips.push(clip);
  }
  // No overlaps on a track: the clip starting later is cut at its head.
  clips.sort((a, b) => byStr(a.track, b.track) || a.start - b.start || byStr(a.id, b.id));
  const kept: VideoClip[] = [];
  const end = new Map<string, number>();
  for (const c of clips) {
    const prevEnd = end.get(c.track) ?? 0;
    if (c.start < prevEnd) {
      const cut = prevEnd - c.start;
      if (clipLength(c) - cut < 1) continue;
      c.start = prevEnd;
      c.sourceRange = {
        start: c.sourceRange.start + (isStillClip(c) ? 0 : cut),
        duration: c.sourceRange.duration - cut,
      };
      const half = Math.floor(c.sourceRange.duration / 2);
      c.fadeIn = Math.min(c.fadeIn, half);
      c.fadeOut = Math.min(c.fadeOut, half);
    }
    end.set(c.track, clipEnd(c));
    kept.push(c);
  }
  const count = new Map<string, number>();
  for (const c of kept) if (c.link) count.set(c.link, (count.get(c.link) ?? 0) + 1);
  for (const c of kept) if (c.link && (count.get(c.link) ?? 0) < 2) delete c.link;

  const transitions: VideoTransition[] = [];
  const tseen = new Set<string>();
  for (const t of Array.isArray(d.transitions) ? d.transitions : []) {
    if (!isObj(t)) continue;
    const id = idOf(t.id);
    const from = idOf(t.from);
    const to = idOf(t.to);
    if (!id || !from || !to || tseen.has(id) || typeof t.track !== "string") continue;
    tseen.add(id);
    transitions.push({
      id,
      track: t.track,
      from,
      to,
      kind: oneOf(t.kind, VIDEO_TRANSITIONS, "dissolve"),
      inOffset: intOf(t.inOffset, 0, F, 0),
      outOffset: intOf(t.outOffset, 0, F, 0),
    });
  }

  const markers: VideoMarker[] = [];
  const mseen = new Set<string>();
  for (const m of Array.isArray(d.markers) ? d.markers : []) {
    if (!isObj(m)) continue;
    const id = idOf(m.id);
    if (!id || mseen.has(id)) continue;
    mseen.add(id);
    const mk: VideoMarker = {
      id,
      frame: intOf(m.frame, 0, F, 0),
      color: oneOf(
        typeof m.color === "string" ? m.color.toUpperCase() : m.color,
        VIDEO_MARKER_COLORS,
        "BLUE",
      ),
      note: strOf(m.note, 500),
    };
    if (m.duration !== undefined) mk.duration = intOf(m.duration, 0, F, 0);
    markers.push(mk);
  }

  const cap = isObj(d.captions) ? d.captions : {};
  const segments: VideoCaption[] = [];
  const sseen = new Set<string>();
  for (const s of Array.isArray(cap.segments) ? cap.segments : []) {
    if (!isObj(s)) continue;
    const id = idOf(s.id);
    const start = intOf(s.start, 0, F, 0);
    const endF = intOf(s.end, 0, F, 0);
    if (!id || sseen.has(id) || endF <= start) continue;
    sseen.add(id);
    const seg: VideoCaption = { id, start, end: endF, text: strOf(s.text, 2000) };
    if (Array.isArray(s.words)) {
      const words = cleanWords(
        s.words.filter(isObj).map((w) => ({
          start: intOf(w.start, 0, F, 0),
          end: intOf(w.end, 0, F, 0),
          text: strOf(w.text, 200),
        })),
      );
      if (words?.length) seg.words = words;
    }
    segments.push(seg);
  }

  const doc: RgVideo = {
    formatVersion: RGVIDEO_FORMAT_VERSION,
    format: formatOf(d.format),
    tracks,
    clips: kept,
    transitions,
    markers,
    captions: {
      language: strOf(cap.language, 20),
      burnIn: cap.burnIn === true,
      style: oneOf(cap.style, ["plain", "boxed", "bold"] as const, "boxed"),
      position: cap.position === "top" ? "top" : "bottom",
      segments,
    },
  };
  const name = strOf(d.name, 200);
  if (name) doc.name = name;
  if (isObj(d.assembled) && typeof d.assembled.at === "string")
    doc.assembled = {
      at: d.assembled.at.slice(0, 40),
      ...(typeof d.assembled.brief === "string" && { brief: d.assembled.brief.slice(0, 4000) }),
    };
  if (isObj(d.version) && strOf(d.version.name, 120) && typeof d.version.at === "string")
    doc.version = {
      name: strOf(d.version.name, 120),
      at: d.version.at.slice(0, 40),
      ...(typeof d.version.of === "string" && { of: d.version.of.slice(0, 4000) }),
      reason: d.version.reason === "before_assemble" ? "before_assemble" : "manual",
    };
  if (isObj(d.metadata)) doc.metadata = d.metadata;
  doc.transitions = validTransitions(doc, doc.transitions);
  // The schema's own key order (an edit and its inverse give back the same bytes).
  return canonicalTimeline(RgVideo.parse(doc));
}

// -------------------------------------------------------------------------------------------
// The file

/** A file of a newer RedGiant: refused, never rewritten in an older shape. */
export class NewerVideoFormat extends Error {}

/**
 * A timeline without `formatVersion` is montatore's own shape (its `TimelineSanitizer`:
 * `tracks[].type`, clips `{media, in, dur, motion}`, lower-case marker colours): read as the
 * first version. `mediaPaths` names its media ids' files.
 */
export function upgradeRgVideo(
  raw: unknown,
  o: { mediaPaths?: Record<string, string>; rate?: VideoRate } = {},
): unknown {
  if (!isObj(raw)) return raw;
  if (raw.formatVersion !== undefined) return raw;
  const tracks = (Array.isArray(raw.tracks) ? raw.tracks : []).filter(isObj).map((t) => ({
    ...t,
    kind: t.type === "audio" ? "Audio" : "Video",
  }));
  const clips = (Array.isArray(raw.clips) ? raw.clips : []).filter(isObj).map((c) => {
    const key = String(c.media ?? "");
    const still = "motion" in c || c.still === true;
    const kb =
      isObj(c.motion) &&
      (c.motion.zoom === "in" || c.motion.zoom === "out") &&
      ["left", "right", "up", "down"].includes(String(c.motion.pan))
        ? kenBurnsPreset(c.motion.zoom, c.motion.pan as "left")
        : undefined;
    return {
      id: c.id,
      track: c.track,
      start: c.start,
      sourceRange: { start: c.in ?? 0, duration: c.dur ?? 0 },
      ref: { media: o.mediaPaths?.[key] ?? key, ...(still && { still: true }) },
      ...(typeof c.link === "string" && c.link && { link: c.link }),
      enabled: c.enabled,
      volume: c.volume,
      fadeIn: c.fadeIn,
      fadeOut: c.fadeOut,
      ...(kb && { kenBurns: kb }),
    };
  });
  return {
    formatVersion: RGVIDEO_FORMAT_VERSION,
    format: { ...formatFor("16:9"), rate: o.rate ?? { num: 30, den: 1 } },
    tracks,
    clips,
    transitions: [],
    markers: raw.markers,
    captions: {},
    ...(typeof raw.generatedAt === "string" && { assembled: { at: raw.generatedAt } }),
  };
}

/** A `.rgvideo` file's text as a timeline (empty: a new one). Throws when it is not one. */
export function readRgVideo(text: string): RgVideo {
  if (!text.trim()) return newRgVideo();
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new Error("it is not JSON (an .rgvideo file is a JSON timeline)");
  }
  if (!isObj(raw)) throw new Error("its JSON is not an object (an .rgvideo timeline)");
  const v = raw.formatVersion;
  if (v !== undefined && (typeof v !== "number" || !Number.isInteger(v) || v < 1))
    throw new Error(`its formatVersion (${JSON.stringify(v)}) is not one RedGiant knows`);
  if (typeof v === "number" && v > RGVIDEO_FORMAT_VERSION)
    throw new NewerVideoFormat(
      `it was written by a newer RedGiant (format ${v}; this one reads up to ${RGVIDEO_FORMAT_VERSION}): update RedGiant to edit it`,
    );
  return cleanTimeline(upgradeRgVideo(raw));
}

/** The file's text: JSON, two spaces, a final newline. */
export const writeRgVideo = (doc: RgVideo): string => `${JSON.stringify(doc, null, 2)}\n`;

/**
 * Where a named version of a timeline is kept (A5): beside it, in `<name>.versions/`, as
 * `<stamp> <name>.rgvideo` (`stamp` sorts by time: 2026-11-16 1530).
 */
export function rgvideoVersionPath(path: string, name: string, stamp: string): string {
  const p = path.replace(/\\/g, "/");
  const slash = p.lastIndexOf("/");
  const dir = slash >= 0 ? p.slice(0, slash + 1) : "";
  const base = p.slice(slash + 1).replace(/\.rgvideo$/i, "");
  const safe = (s: string) =>
    s
      .replace(/[\\/:*?"<>|]/g, " ")
      .replace(/\p{Cc}/gu, " ")
      .replace(/\s+/g, " ")
      .trim()
      .slice(0, 80);
  const n = safe(name) || "version";
  return `${dir}${base}.versions/${safe(stamp)} ${n}.rgvideo`;
}
