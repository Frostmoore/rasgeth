// The video family's actions (G41.2) applied, inverted, compared and described: pure, the same
// on the server and in the page. An action sets one entity by its id (a clip, a track, a
// transition, a marker, a subtitle) or one setting of the timeline; an edit of the timeline
// (video-timeline.ts) becomes them through `diffTimeline`. Positions are absolute, so an action
// made on an older revision applies as it is after another that touched other entities: two
// actions conflict only on the same id, on an entity the other points at (a clip's track, a
// transition's clips), or on clips of one track that would overlap.
import {
  type RgVideo,
  type VideoAction,
  VideoCaption,
  VideoCaptionSettings,
  type VideoChange,
  VideoClip,
  type VideoEdit,
  VideoFormat,
  VideoMarker,
  type VideoMetaKey,
  type VideoPlainAction,
  VideoTrack,
  VideoTransition,
  VideoAssembled,
  VideoVersionInfo,
} from "./doc-video.js";
import {
  canonicalTimeline,
  clipEnd,
  readRgVideo,
  timecode,
  timelineProblems,
  writeRgVideo,
} from "./video-timeline.js";

type EntityKind = "clip" | "track" | "transition" | "marker" | "caption";
type Entity = { id: string };

const listOf = (doc: RgVideo, k: EntityKind): Entity[] =>
  k === "clip"
    ? doc.clips
    : k === "track"
      ? doc.tracks
      : k === "transition"
        ? doc.transitions
        : k === "marker"
          ? doc.markers
          : doc.captions.segments;

const SCHEMAS = {
  clip: VideoClip,
  track: VideoTrack,
  transition: VideoTransition,
  marker: VideoMarker,
  caption: VideoCaption,
} as const;

/** A key-order-free JSON (an entity made by an edit and the same read from the file compare equal). */
export function stableJson(v: unknown): string {
  if (Array.isArray(v)) return `[${v.map(stableJson).join(",")}]`;
  if (v && typeof v === "object")
    return `{${Object.keys(v)
      .filter((k) => (v as Record<string, unknown>)[k] !== undefined)
      .sort()
      .map((k) => `${JSON.stringify(k)}:${stableJson((v as Record<string, unknown>)[k])}`)
      .join(",")}}`;
  return JSON.stringify(v) ?? "null";
}

const metaOf = (doc: RgVideo, key: VideoMetaKey): unknown => {
  if (key === "captions") {
    const { segments: _s, ...settings } = doc.captions;
    return settings;
  }
  return doc[key] ?? null;
};

function metaValue(key: VideoMetaKey, v: unknown): unknown {
  switch (key) {
    case "name":
      return v === null ? null : String(v).slice(0, 200);
    case "format":
      return VideoFormat.parse(v);
    case "captions":
      return VideoCaptionSettings.parse(v);
    case "assembled":
      return v === null ? null : VideoAssembled.parse(v);
    case "version":
      return v === null ? null : VideoVersionInfo.parse(v);
    case "metadata":
      return v === null ? null : (v as Record<string, unknown>);
  }
}

/** Applies one plain action on a working copy (in place; the order is restored after). */
function applyPlain(doc: RgVideo, a: VideoPlainAction): RgVideo {
  switch (a.t) {
    case "doc":
      return readRgVideo(a.text);
    case "meta": {
      const v = metaValue(a.key, a.value);
      if (a.key === "captions")
        doc.captions = { ...(v as VideoCaptionSettings), segments: doc.captions.segments };
      else if (a.key === "format") doc.format = v as VideoFormat;
      else if (v === null) delete doc[a.key];
      else (doc as Record<string, unknown>)[a.key] = v;
      return doc;
    }
    default: {
      const list = listOf(doc, a.t);
      const i = list.findIndex((e) => e.id === a.id);
      if (a.value === null) {
        if (i >= 0) list.splice(i, 1);
      } else {
        const v = (SCHEMAS[a.t] as { parse(x: unknown): Entity }).parse(a.value);
        if (i >= 0) list[i] = v;
        else list.push(v);
      }
      return doc;
    }
  }
}

const plainOf = (a: VideoAction): VideoPlainAction[] => (a.t === "batch" ? a.ops : [a]);

/** The timeline after the action (a new object; the one given never changes). */
export function applyVideoAction(doc: RgVideo, a: VideoAction): RgVideo {
  let work = structuredClone(doc);
  for (const p of plainOf(a)) work = applyPlain(work, p);
  return canonicalTimeline(work);
}

/** Why the action cannot apply here (undefined: it can). */
export function checkVideoAction(doc: RgVideo, a: VideoAction): string | undefined {
  let work = structuredClone(doc);
  for (const p of plainOf(a)) {
    if (p.t === "doc") {
      try {
        readRgVideo(p.text);
      } catch (err) {
        return `the timeline cannot be read: ${(err as Error).message}`;
      }
    } else if (p.t === "meta") {
      try {
        metaValue(p.key, p.value);
      } catch {
        return `the value of ${p.key} is not valid`;
      }
    } else {
      if (p.value && p.value.id !== p.id) return `the ${p.t} ${p.id} is given with id ${p.value.id}`;
      if (p.value) {
        const r = (SCHEMAS[p.t] as { safeParse(x: unknown): { success: boolean } }).safeParse(
          p.value,
        );
        if (!r.success) return `the ${p.t} ${p.id} is not valid`;
      } else if (!listOf(work, p.t).some((e) => e.id === p.id))
        return `there is no ${p.t} «${p.id}»`;
    }
    work = applyPlain(work, p);
  }
  const before = new Set(timelineProblems(doc));
  const added = timelineProblems(canonicalTimeline(work)).filter((x) => !before.has(x));
  return added[0];
}

function invertPlain(doc: RgVideo, a: VideoPlainAction): VideoPlainAction {
  switch (a.t) {
    case "doc":
      return { t: "doc", text: writeRgVideo(doc) };
    case "meta":
      return { t: "meta", key: a.key, value: structuredClone(metaOf(doc, a.key)) };
    default: {
      const old = listOf(doc, a.t).find((e) => e.id === a.id);
      return { t: a.t, id: a.id, value: old ? structuredClone(old) : null } as VideoPlainAction;
    }
  }
}

/** The action that undoes `a`, on the timeline after it (`doc` is the one before). */
export function invertVideoAction(doc: RgVideo, a: VideoAction): VideoAction {
  if (a.t !== "batch") return invertPlain(doc, a);
  let work = structuredClone(doc);
  const inv: VideoPlainAction[] = [];
  for (const p of a.ops) {
    inv.push(invertPlain(work, p));
    work = applyPlain(work, p);
  }
  return { t: "batch", ops: inv.reverse(), ...(a.what && { what: a.what }) };
}

/** Several actions as one batch (its edit: theirs when they share one). */
export function composeVideoActions(list: readonly VideoAction[]): VideoAction {
  const whats = new Set(list.map((a) => (a.t === "batch" ? a.what : undefined)));
  const what = whats.size === 1 ? [...whats][0] : "edit";
  return { t: "batch", ops: list.flatMap(plainOf), ...(what && { what }) };
}

interface Touch {
  all: boolean;
  writes: Set<string>;
  refs: Set<string>;
  spans: { track: string; from: number; to: number }[];
}

function touchOf(a: VideoAction): Touch {
  const t: Touch = { all: false, writes: new Set(), refs: new Set(), spans: [] };
  for (const p of plainOf(a)) {
    if (p.t === "doc") t.all = true;
    else if (p.t === "meta") {
      t.writes.add(`meta:${p.key}`);
      if (p.key === "format") t.all = true; // a rate moves every frame value
    } else {
      t.writes.add(`${p.t}:${p.id}`);
      const v = p.value;
      if (!v) continue;
      if (p.t === "clip") {
        const c = v as VideoClip;
        t.refs.add(`track:${c.track}`);
        t.spans.push({ track: c.track, from: c.start, to: clipEnd(c) });
      } else if (p.t === "transition") {
        const x = v as VideoTransition;
        t.refs.add(`track:${x.track}`);
        t.refs.add(`clip:${x.from}`);
        t.refs.add(`clip:${x.to}`);
      } else if (p.t === "track") {
        for (const u of (v as VideoTrack).duck?.under ?? []) t.refs.add(`track:${u}`);
      }
    }
  }
  return t;
}

const meets = (a: Set<string>, b: Set<string>) => [...a].some((x) => b.has(x));

/**
 * Whether `a` and `b`, made on the same timeline, touch the same place: the same entity, one
 * the other points at, or clips of one track that would overlap; the whole file or the format
 * meet everything.
 */
export function videoActionsConflict(a: VideoAction, b: VideoAction): boolean {
  const x = touchOf(a);
  const y = touchOf(b);
  if (x.all || y.all) return true;
  if (meets(x.writes, y.writes) || meets(x.writes, y.refs) || meets(y.writes, x.refs)) return true;
  return x.spans.some((s) =>
    y.spans.some((u) => u.track === s.track && u.from < s.to && s.from < u.to),
  );
}

/** `a` made on the same timeline as `b`, after `b`: as it is (positions are absolute), or none. */
export function mapVideoAction(a: VideoAction, b: VideoAction): VideoAction | undefined {
  return videoActionsConflict(a, b) ? undefined : a;
}

/** The difference between two timelines as actions (undefined: none), tagged with the edit. */
export function diffTimeline(
  before: RgVideo,
  after: RgVideo,
  what?: VideoEdit,
): VideoAction | undefined {
  const ops: VideoPlainAction[] = [];
  for (const key of ["format", "name", "captions", "assembled", "version", "metadata"] as const) {
    const b = metaOf(before, key);
    const a = metaOf(after, key);
    if (stableJson(a) !== stableJson(b))
      ops.push({ t: "meta", key, value: structuredClone(a) });
  }
  for (const k of ["track", "clip", "transition", "marker", "caption"] as const) {
    const was = new Map(listOf(before, k).map((e) => [e.id, e]));
    const now = new Map(listOf(after, k).map((e) => [e.id, e]));
    // Removals first: a track goes only once its clips went (an undo puts them back in order).
    for (const id of was.keys())
      if (!now.has(id)) ops.push({ t: k, id, value: null } as VideoPlainAction);
    for (const [id, e] of now) {
      const old = was.get(id);
      if (!old || stableJson(old) !== stableJson(e))
        ops.push({ t: k, id, value: structuredClone(e) } as VideoPlainAction);
    }
  }
  if (!ops.length) return undefined;
  if (ops.length === 1 && !what) return ops[0] as VideoPlainAction;
  return { t: "batch", ops, ...(what && { what }) };
}

// -------------------------------------------------------------------------------------------
// In words

const plural = (n: number, one: string, many = `${one}s`) => `${n} ${n === 1 ? one : many}`;

/** What a batch of actions does, on the timeline before it: a line in English and the change. */
export function describeVideo(
  doc: RgVideo,
  actions: readonly VideoAction[],
): { text: string; change: VideoChange } {
  const parts: string[] = [];
  let n = 0;
  let added = 0;
  let removed = 0;
  const ids = new Set<string>();
  const whats: VideoEdit[] = [];
  let work = doc;
  for (const a of actions) {
    const plain = plainOf(a);
    const clips = plain.filter((p) => p.t === "clip");
    const had = new Set(work.clips.map((c) => c.id));
    const add = clips.filter((p) => p.value && !had.has(p.id)).length;
    const del = clips.filter((p) => !p.value && had.has(p.id)).length;
    const changed = clips.length - add - del;
    added += add;
    removed += del;
    for (const p of plain) if (p.t !== "doc" && p.t !== "meta") ids.add(p.id);
    n += plain.length;
    const what = a.t === "batch" && a.what ? a.what : guess(plain);
    whats.push(what);
    parts.push(words(what, plain, { add, del, changed, rate: work.format.rate }));
    work = applyVideoAction(work, a);
  }
  const action: VideoEdit = new Set(whats).size === 1 ? (whats[0] as VideoEdit) : "edit";
  const text = parts.join("; ").slice(0, 480);
  return {
    text,
    change: {
      action,
      n: ids.size || n,
      ...(added && { added }),
      ...(removed && { removed }),
      ...(ids.size === 1 && { id: [...ids][0] as string }),
    },
  };
}

function guess(plain: readonly VideoPlainAction[]): VideoEdit {
  const kinds = new Set(plain.map((p) => (p.t === "meta" ? `meta:${p.key}` : p.t)));
  if (kinds.has("doc")) return "replace";
  if (kinds.size !== 1) return "edit";
  const [k] = kinds;
  if (k === "meta:format") return "format";
  if (k === "track") return "track";
  if (k === "marker") return "marker";
  if (k === "transition") return "transition";
  if (k === "caption" || k === "meta:captions") return "caption";
  if (k === "clip") return "props";
  return "edit";
}

function words(
  what: VideoEdit,
  plain: readonly VideoPlainAction[],
  c: { add: number; del: number; changed: number; rate: RgVideo["format"]["rate"] },
): string {
  const clips = plain.filter((p) => p.t === "clip");
  const one = clips.length === 1 ? ` ${clips[0]?.id}` : "";
  const touched = plural(Math.max(1, c.changed + c.add), "clip");
  const first = clips.find((p) => p.value)?.value as VideoClip | undefined;
  const where = first ? ` on ${first.track} at ${timecode(first.start, c.rate)}` : "";
  const trackId = plain.find((p) => p.t === "track")?.id ?? "";
  switch (what) {
    case "move":
      return `moved ${plural(c.changed, "clip")}${where}`;
    case "trim":
      return `trimmed ${plural(c.changed, "clip")}${one && c.changed === 1 ? ` (${clips[0]?.id})` : ""}`;
    case "ripple_trim":
      return `trimmed a clip and moved what follows (${plural(c.changed, "clip")} changed)`;
    case "blade":
      return `cut ${plural(c.add, "clip")} in two${where.replace(/ on \S+/, "")}`;
    case "lift":
      return `removed ${plural(c.del, "clip")}, leaving the gap`;
    case "ripple_delete":
      return `removed ${plural(c.del, "clip")} and closed the gap`;
    case "close_gap":
      return `closed a gap (${plural(c.changed, "clip")} moved)`;
    case "insert":
      return `inserted ${plural(c.add, "clip")}${where}`;
    case "overwrite":
      return `placed ${plural(c.add, "clip")}${where}`;
    case "append":
      return `appended ${plural(c.add, "clip")}${where}`;
    case "paste":
      return `pasted ${plural(c.add, "clip")}${where}`;
    case "link":
      return `linked ${touched}`;
    case "unlink":
      return `unlinked ${touched}`;
    case "props":
      return `changed ${touched}`;
    case "add_track":
      return `added track ${trackId}`;
    case "remove_track":
      return `removed track ${trackId}`;
    case "track":
      return `changed track ${trackId}`;
    case "marker":
      return `changed ${plural(plain.filter((p) => p.t === "marker").length, "marker")}`;
    case "transition":
      return `changed ${plural(plain.filter((p) => p.t === "transition").length, "transition")}`;
    case "text":
      return c.add ? `added a text${where}` : "changed a text";
    case "caption":
      return `changed ${plural(Math.max(1, plain.filter((p) => p.t === "caption").length), "subtitle")}`;
    case "format":
      return "changed the timeline's format";
    case "replace":
      return "replaced the timeline";
    default:
      return `edited ${plural(plain.length, "item")}`;
  }
}
