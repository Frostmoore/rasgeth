// A timeline as OpenTimelineIO (G41.6b): `.otio` out and in. OTIO is documented JSON
// (Timeline → Stack → Track → Clip/Gap/Transition, RationalTime, ExternalReference,
// GeneratorReference, Marker); `.rgvideo` already has its names and units (G41.2), so the
// subset we use translates directly.
//
// Out (`toOtio`): the same OTIO timeline montatore's engine builds for Resolve (`build` in
// engine/montatore_engine/fcpxml.py: one Track per track, Gaps for the empty parts, clips with
// the camera's timecode as the start of their file, a picture an hour long), plus what OTIO has
// a place for (titles as GeneratorReference, transitions, markers) and, in
// `metadata.redgiant`, everything else of the timeline, so reading it back gives the same
// timeline. `otioText` writes it as OpenTimelineIO 0.18 does (keys in its order, metadata keys
// sorted, times as doubles, four spaces): Python's `otio.adapters.read_from_file` + write gives
// back the same bytes (test/fixtures/resolve/*.ours.otio).
//
// In (`fromOtio`): the subset we know (video and audio tracks, clips of files, gaps, colours and
// our titles, dissolves and other transitions, markers), at any rate (rescaled to the
// timeline's); the rest is left out with a warning.
import {
  RGVIDEO_FORMAT_VERSION,
  type RgVideo,
  VIDEO_MARKER_COLORS,
  VIDEO_TRANSITIONS,
  VideoAssembled,
  VideoCaptions,
  type VideoClip,
  VideoClip as VideoClipSchema,
  type VideoRate,
  type VideoTrack,
  VideoTrack as VideoTrackSchema,
} from "./doc-video.js";
import {
  type ResolveMedia,
  resolveFileUrl,
  resolveStartFrame,
  STILL_SECONDS,
} from "./video-resolve.js";
import { cleanTimeline, isMediaRef, newRgVideo } from "./video-timeline.js";

type Json = null | boolean | number | string | Json[] | { [k: string]: Json };
type Obj = { [k: string]: Json };

const rt = (value: number, rate: number): Obj => ({
  OTIO_SCHEMA: "RationalTime.1",
  rate,
  value,
});
const range = (start: number, duration: number, rate: number): Obj => ({
  OTIO_SCHEMA: "TimeRange.1",
  duration: rt(duration, rate),
  start_time: rt(start, rate),
});
const roundTime = (seconds: number, rate: number) => Math.round(seconds * rate);

/** OTIO's own transition type for a dissolve; ours are kept by name in the metadata. */
const OTIO_DISSOLVE = "SMPTE_Dissolve";
/** Our titles' generator (OTIO has no text generator of its own). */
export const OTIO_TEXT_GENERATOR = "RedGiantText";
export const OTIO_COLOR_GENERATOR = "SolidColor";

/** A JSON copy without the undefined values (metadata must be plain JSON). */
const plain = (x: unknown): Json => JSON.parse(JSON.stringify(x ?? null)) as Json;

/**
 * The OTIO timeline of a timeline. `media` is what the XML for Resolve gets too (`resolveJob`:
 * where Resolve finds each file, its length, its camera timecode), by the file's path in the
 * project; a file it lacks is written without a known length.
 */
export function toOtio(
  doc: RgVideo,
  o: { name: string; media: Readonly<Record<string, ResolveMedia>> },
): Obj {
  const rate = doc.format.rate.num / doc.format.rate.den;
  const { tracks: _t, clips: _c, transitions: _x, markers: _m, ...rest } = doc;
  const children: Json[] = [];
  for (const t of doc.tracks) {
    const items: Json[] = [];
    const clips = doc.clips.filter((c) => c.track === t.id).sort((a, b) => a.start - b.start);
    let cursor = 0;
    let prev: VideoClip | undefined;
    for (const c of clips) {
      if (c.start > cursor)
        items.push({
          OTIO_SCHEMA: "Gap.1",
          metadata: {},
          name: "",
          source_range: range(0, c.start - cursor, rate),
          effects: [],
          markers: [],
          enabled: true,
          color: null,
        });
      const tr =
        prev && prev.start + prev.sourceRange.duration === c.start
          ? doc.transitions.find((x) => x.track === t.id && x.from === prev?.id && x.to === c.id)
          : undefined;
      if (tr)
        items.push({
          OTIO_SCHEMA: "Transition.1",
          metadata: { redgiant: plain({ transition: tr }) },
          name: "",
          in_offset: rt(tr.inOffset, rate),
          out_offset: rt(tr.outOffset, rate),
          transition_type: tr.kind === "dissolve" ? OTIO_DISSOLVE : "Custom_Transition",
        });
      items.push(clipOf(c, rate, o.media));
      cursor = c.start + c.sourceRange.duration;
      prev = c;
    }
    children.push({
      OTIO_SCHEMA: "Track.1",
      metadata: { redgiant: plain({ track: t }) },
      name: t.name || t.id,
      source_range: null,
      effects: [],
      markers: [],
      enabled: !(t.hidden ?? t.muted ?? false),
      color: null,
      children: items,
      kind: t.kind,
    });
  }
  return {
    OTIO_SCHEMA: "Timeline.1",
    metadata: { redgiant: plain(rest) },
    name: o.name,
    global_start_time: rt(0, rate),
    tracks: {
      OTIO_SCHEMA: "Stack.1",
      metadata: {},
      name: "tracks",
      source_range: null,
      effects: [],
      markers: doc.markers.map((m) => ({
        OTIO_SCHEMA: "Marker.2",
        metadata: { redgiant: { id: m.id } },
        name: m.note,
        color: m.color,
        marked_range: range(m.frame, m.duration ?? 0, rate),
        comment: "",
      })),
      enabled: true,
      color: null,
      children,
    },
  };
}

function clipOf(c: VideoClip, rate: number, media: Readonly<Record<string, ResolveMedia>>): Obj {
  let ref: Obj;
  let source: Obj;
  let name = c.name;
  if (isMediaRef(c.ref)) {
    const m = media[c.ref.media];
    const still = m ? m.frames === null : !!c.ref.still;
    const tc0 = still || !m ? 0 : resolveStartFrame(m.timecode, rate);
    const frames = m ? m.frames : (c.ref.frames ?? null);
    const available = still
      ? range(0, roundTime(STILL_SECONDS, rate), rate)
      : frames !== null
        ? range(tc0, roundTime(frames / rate, rate), rate)
        : null;
    ref = {
      OTIO_SCHEMA: "ExternalReference.1",
      metadata: {},
      name: "",
      available_range: available,
      available_image_bounds: null,
      target_url: resolveFileUrl(m ? m.url : c.ref.media),
    };
    source = range(
      tc0 + roundTime(still ? 0 : c.sourceRange.start / rate, rate),
      roundTime(c.sourceRange.duration / rate, rate),
      rate,
    );
    name ??= m?.name ?? c.ref.media.slice(c.ref.media.lastIndexOf("/") + 1);
  } else {
    const text = c.ref.generator === "text";
    ref = {
      OTIO_SCHEMA: "GeneratorReference.1",
      metadata: {},
      name: "",
      available_range: null,
      available_image_bounds: null,
      generator_kind: text ? OTIO_TEXT_GENERATOR : OTIO_COLOR_GENERATOR,
      parameters: plain(
        c.ref.generator === "text"
          ? { text: c.ref.text, style: c.ref.style, position: c.ref.position }
          : { color: c.ref.color },
      ),
    };
    source = range(c.sourceRange.start, c.sourceRange.duration, rate);
    name ??= c.ref.generator === "text" ? c.ref.text.slice(0, 60) : c.ref.color;
  }
  return {
    OTIO_SCHEMA: "Clip.2",
    metadata: { redgiant: plain({ clip: c }) },
    name,
    source_range: source,
    effects: [],
    markers: [],
    enabled: c.enabled,
    color: null,
    media_references: { DEFAULT_MEDIA: ref },
    active_media_reference_key: "DEFAULT_MEDIA",
  };
}

// -------------------------------------------------------------------------------------------
// The text, as OpenTimelineIO writes it

const DOUBLE = "\u0000D";
/** OTIO's dictionaries (std::map: sorted keys, all the way down). */
const SORTED = new Set(["metadata", "parameters"]);

const sortedDeep = (v: Json): Json => {
  if (Array.isArray(v)) return v.map(sortedDeep);
  if (v && typeof v === "object") {
    const out: Obj = {};
    for (const k of Object.keys(v).sort()) out[k] = sortedDeep(v[k] as Json);
    return out;
  }
  return v;
};

/** A double as RapidJSON writes it (an integer keeps its `.0`). */
const double = (n: number) => (Number.isInteger(n) ? `${n}.0` : String(n));

/**
 * OTIO JSON as OpenTimelineIO 0.18 writes it: the keys in its order (as built here or read),
 * metadata and parameters with sorted keys, RationalTime's rate and value as doubles, four
 * spaces, no final newline.
 */
export function otioText(obj: Json): string {
  const text = JSON.stringify(
    obj,
    function (this: unknown, key: string, value: Json) {
      if (SORTED.has(key) && value && typeof value === "object" && !Array.isArray(value))
        return sortedDeep(value);
      // A map of references: its keys sorted, the references themselves in their own order.
      if (key === "media_references" && value && typeof value === "object" && !Array.isArray(value))
        return Object.fromEntries(
          Object.keys(value)
            .sort()
            .map((k) => [k, value[k] as Json]),
        );
      if (
        value &&
        typeof value === "object" &&
        !Array.isArray(value) &&
        value.OTIO_SCHEMA === "RationalTime.1"
      )
        return {
          OTIO_SCHEMA: "RationalTime.1",
          rate: `${DOUBLE}${value.rate}`,
          value: `${DOUBLE}${value.value}`,
        };
      return value;
    },
    4,
  );
  return text.replace(/"\\u0000D([^"]*)"/g, (_, n: string) => double(Number(n)));
}

// -------------------------------------------------------------------------------------------
// In

/** What to make of an `.otio`'s files: the path in the project, or undefined (left out). */
export interface FromOtioOptions {
  media(url: string): string | undefined;
}

const isObj = (v: unknown): v is Obj => !!v && typeof v === "object" && !Array.isArray(v);
const num = (v: unknown): number | undefined =>
  typeof v === "number" && Number.isFinite(v) ? v : undefined;
const schemaOf = (v: unknown): string =>
  isObj(v) && typeof v.OTIO_SCHEMA === "string" ? v.OTIO_SCHEMA : "";
const schemaName = (v: unknown) => schemaOf(v).replace(/\.\d+$/, "");

/** A RationalTime's seconds (undefined when it is not one). */
const seconds = (v: unknown): number | undefined => {
  if (!isObj(v)) return undefined;
  const value = num(v.value);
  const rate = num(v.rate);
  return value !== undefined && rate !== undefined && rate > 0 ? value / rate : undefined;
};
const rangeOf = (v: unknown): { start: number; duration: number } | undefined => {
  if (!isObj(v)) return undefined;
  const start = seconds(v.start_time);
  const duration = seconds(v.duration);
  return start !== undefined && duration !== undefined ? { start, duration } : undefined;
};

/** A rate as our fraction (29.97… = 30000/1001). */
export function otioRate(rate: number): VideoRate {
  for (const den of [1, 1001]) {
    const n = Math.round(rate * den);
    if (n > 0 && Math.abs(n / den - rate) < 1e-6) return { num: n, den };
  }
  const n = Math.round(rate * 1000);
  return { num: Math.max(1, n), den: 1000 };
}

const redgiant = (v: Obj): Obj | undefined => {
  const md = v.metadata;
  return isObj(md) && isObj(md.redgiant) ? md.redgiant : undefined;
};

/**
 * A timeline from an `.otio` file's text: the subset we know, at the rate of its first time (or
 * the one of our own metadata), the rest left out with a warning (in English, for the agent).
 * Throws when it is not an OTIO timeline.
 */
export function fromOtio(text: string, o: FromOtioOptions): { doc: RgVideo; warnings: string[] } {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new Error("it is not JSON (an .otio file is OpenTimelineIO's JSON)");
  }
  if (schemaName(raw) === "SerializableCollection" && isObj(raw) && Array.isArray(raw.children))
    raw = raw.children.find((c) => schemaName(c) === "Timeline");
  if (schemaName(raw) !== "Timeline" || !isObj(raw))
    throw new Error("it holds no OpenTimelineIO timeline");
  const tl = raw;
  const warnings: string[] = [];
  const warn = (w: string) => {
    if (!warnings.includes(w)) warnings.push(w);
  };
  const ours = redgiant(tl) ?? {};

  const doc = newRgVideo();
  if (typeof tl.name === "string" && tl.name) doc.name = tl.name.slice(0, 200);
  const fmt = isObj(ours.format) ? ours.format : undefined;
  if (fmt && isObj(fmt.rate) && num(fmt.rate.num) && num(fmt.rate.den))
    doc.format = { ...doc.format, ...(fmt as unknown as RgVideo["format"]) };
  else {
    const first = isObj(tl.global_start_time) ? num(tl.global_start_time.rate) : undefined;
    if (first && first > 0) doc.format.rate = otioRate(first);
  }
  const cap = VideoCaptions.safeParse(ours.captions);
  if (cap.success) doc.captions = cap.data;
  if (typeof ours.normalize === "boolean") doc.normalize = ours.normalize;
  const asm = VideoAssembled.safeParse(ours.assembled);
  if (asm.success) doc.assembled = asm.data;
  if (isObj(ours.metadata)) doc.metadata = ours.metadata as RgVideo["metadata"];
  const r = doc.format.rate.num / doc.format.rate.den;
  const frames = (s: number) => Math.round(s * r);

  const stack = isObj(tl.tracks) ? tl.tracks : {};
  const tracks: VideoTrack[] = [];
  const clips: VideoClip[] = [];
  const transitions: RgVideo["transitions"] = [];
  const markers: RgVideo["markers"] = [];
  const used = new Set<string>();
  const next: Record<string, number> = {};
  const newId = (prefix: string, wanted?: unknown) => {
    let id = typeof wanted === "string" && /^[A-Za-z0-9_.:-]{1,80}$/.test(wanted) ? wanted : "";
    while (!id || used.has(id)) {
      next[prefix] = (next[prefix] ?? 0) + 1;
      id = `${prefix}${next[prefix]}`;
    }
    used.add(id);
    return id;
  };
  const counts = { Video: 0, Audio: 0 };
  const trackIds = new Set<string>();

  for (const t of Array.isArray(stack.children) ? stack.children : []) {
    if (schemaName(t) !== "Track" || !isObj(t)) {
      warn(`left out: a ${schemaName(t) || "thing"} inside the tracks (only tracks are read)`);
      continue;
    }
    const kind = t.kind === "Audio" ? "Audio" : t.kind === "Video" ? "Video" : undefined;
    if (!kind) {
      warn(`left out: a track of kind "${String(t.kind)}"`);
      continue;
    }
    const meta = redgiant(t);
    const kept = VideoTrackSchema.safeParse(isObj(meta) ? meta.track : undefined);
    let id = kept.success && kept.data.kind === kind ? kept.data.id : "";
    while (!id || trackIds.has(id)) id = `${kind[0]}${++counts[kind]}`;
    if (trackIds.size >= 198 || !/^[VA][1-9]\d?$/.test(id)) {
      warn("left out: tracks past 99 of a kind");
      continue;
    }
    trackIds.add(id);
    const off = t.enabled === false;
    const track: VideoTrack = kept.success
      ? { ...kept.data, id }
      : {
          id,
          kind,
          name: (typeof t.name === "string" ? t.name : "").slice(0, 60) || id,
          locked: false,
        };
    if (kind === "Video") track.hidden = off;
    else track.muted = off;
    tracks.push(track);

    let cursor = 0;
    let prev: VideoClip | undefined;
    let pending: Obj | undefined;
    for (const it of Array.isArray(t.children) ? t.children : []) {
      const kindOf = schemaName(it);
      if (!isObj(it)) continue;
      if (kindOf === "Gap") {
        cursor += frames(rangeOf(it.source_range)?.duration ?? 0);
        prev = undefined;
        continue;
      }
      if (kindOf === "Transition") {
        pending = it;
        continue;
      }
      if (kindOf !== "Clip") {
        const len = rangeOf(it.source_range)?.duration;
        if (len !== undefined) cursor += frames(len);
        warn(`left out: a ${kindOf || "thing"} inside a track (nested stacks are not read)`);
        prev = undefined;
        pending = undefined;
        continue;
      }
      const refs = isObj(it.media_references) ? it.media_references : {};
      const key =
        typeof it.active_media_reference_key === "string"
          ? it.active_media_reference_key
          : "DEFAULT_MEDIA";
      const ref = isObj(refs[key])
        ? (refs[key] as Obj)
        : isObj(it.media_reference)
          ? it.media_reference
          : {};
      const avail = rangeOf(ref.available_range);
      const src = rangeOf(it.source_range) ?? avail;
      if (!src || src.duration <= 0) {
        warn("left out: a clip without a length");
        continue;
      }
      const start = cursor;
      const duration = Math.max(1, frames(src.duration));
      cursor += duration;
      const meta = redgiant(it);
      const kept = VideoClipSchema.safeParse(isObj(meta) ? meta.clip : undefined);
      let cref: VideoClip["ref"] | undefined;
      const refKind = schemaName(ref);
      if (refKind === "ExternalReference") {
        const url = typeof ref.target_url === "string" ? ref.target_url : "";
        const keptRef = kept.success && isMediaRef(kept.data.ref) ? kept.data.ref : undefined;
        const path = keptRef?.media ?? o.media(url);
        if (!path) warn(`left out: clips of files outside the project (${url.slice(0, 200)})`);
        else cref = keptRef ? { ...keptRef, media: path } : { media: path };
      } else if (refKind === "GeneratorReference") {
        const p = isObj(ref.parameters) ? ref.parameters : {};
        if (
          ref.generator_kind === OTIO_COLOR_GENERATOR &&
          typeof p.color === "string" &&
          /^#[0-9a-fA-F]{6}$/.test(p.color)
        )
          cref = { generator: "color", color: p.color };
        else if (ref.generator_kind === OTIO_TEXT_GENERATOR && typeof p.text === "string" && p.text)
          cref =
            kept.success && !isMediaRef(kept.data.ref)
              ? kept.data.ref
              : {
                  generator: "text",
                  text: p.text.slice(0, 2000),
                  style: "title",
                  position: "center",
                };
        else warn(`left out: generated clips of kind "${String(ref.generator_kind)}"`);
      } else warn(`left out: clips with a ${refKind || "missing"} reference (no file)`);
      if (!cref) {
        prev = undefined;
        pending = undefined;
        continue;
      }
      const sourceStart =
        refKind === "ExternalReference" && !("generator" in cref) && !cref.still
          ? Math.max(0, frames(src.start - (avail?.start ?? 0)))
          : kept.success
            ? kept.data.sourceRange.start
            : 0;
      const base: VideoClip = kept.success
        ? kept.data
        : {
            id: "",
            track: id,
            start: 0,
            sourceRange: { start: 0, duration: 1 },
            ref: cref,
            enabled: true,
            volume: 0,
            fadeIn: 0,
            fadeOut: 0,
            fit: "fill",
          };
      const clip: VideoClip = {
        ...base,
        id: newId("c", kept.success ? kept.data.id : undefined),
        track: id,
        start,
        sourceRange: { start: sourceStart, duration },
        ref: cref,
        enabled: it.enabled !== false,
      };
      if (!kept.success && typeof it.name === "string" && it.name)
        clip.name = it.name.slice(0, 200);
      for (const m of Array.isArray(it.markers) ? it.markers : [])
        if (isObj(m)) markerFrom(m, start - frames(src.start));
      clips.push(clip);
      if (pending && prev && prev.start + prev.sourceRange.duration === start) {
        const tm = redgiant(pending);
        const was = isObj(tm) && isObj(tm.transition) ? tm.transition : {};
        const k = was.kind;
        transitions.push({
          id: newId("t", was.id),
          track: id,
          from: prev.id,
          to: clip.id,
          kind:
            typeof k === "string" && (VIDEO_TRANSITIONS as readonly string[]).includes(k)
              ? (k as RgVideo["transitions"][number]["kind"])
              : "dissolve",
          inOffset: Math.max(0, frames(seconds(pending.in_offset) ?? 0)),
          outOffset: Math.max(0, frames(seconds(pending.out_offset) ?? 0)),
        });
      } else if (pending) warn("left out: a transition that is not between two clips");
      pending = undefined;
      prev = clip;
    }
  }

  function markerFrom(m: Obj, offset: number) {
    const mr = rangeOf(m.marked_range);
    if (!mr) return;
    const meta = redgiant(m);
    const color = typeof m.color === "string" ? m.color.toUpperCase() : "";
    const dur = frames(mr.duration);
    const note = [m.name, m.comment].filter((x) => typeof x === "string" && x).join(" — ");
    markers.push({
      id: newId("m", isObj(meta) ? meta.id : undefined),
      frame: Math.max(0, offset + frames(mr.start)),
      ...(dur > 0 && { duration: dur }),
      color: (VIDEO_MARKER_COLORS as readonly string[]).includes(color)
        ? (color as RgVideo["markers"][number]["color"])
        : "BLUE",
      note: note.slice(0, 500),
    });
  }
  for (const m of Array.isArray(stack.markers) ? stack.markers : []) if (isObj(m)) markerFrom(m, 0);

  if (Array.isArray(stack.effects) && stack.effects.length) warn("left out: effects");
  doc.tracks = tracks;
  doc.clips = clips;
  doc.transitions = transitions;
  doc.markers = markers;
  const clean = cleanTimeline({ ...doc, formatVersion: RGVIDEO_FORMAT_VERSION });
  return { doc: clean, warnings };
}
