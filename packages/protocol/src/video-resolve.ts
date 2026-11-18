// A timeline for DaVinci Resolve (G41.6b): Final Cut Pro 7 XML (xmeml 4), as montatore writes it.
// Montatore (the person's own project, confirmed by them in Resolve: «perfetta» with its v1.4.3)
// builds an OpenTimelineIO timeline (engine/montatore_engine/fcpxml.py `build`), has
// otio-fcp-adapter 1.0.0 write it (OpenTimelineIO 0.18.1; minidom's pretty print) and then
// completes it with what Resolve expects (`finish_xml`, as Premiere writes it). This file is that
// whole chain ported to TypeScript for the subset montatore produces, so the text is the same
// byte for byte (protocol/test/video-resolve.test.ts compares it with XML montatore's engine
// wrote from the same timelines, fixtures in test/fixtures/resolve/). Resolve's traps, kept:
//  - T17: paths as Premiere writes them, `file://localhost/E%3a/Video/x.mp4` (`file:///E:/…`
//    is correct, but Resolve on Windows does not find it);
//  - T18: the camera's start timecode is the start of the file's material, with the camera's own
//    string and DF/NDF (Resolve looks clips up by timecode: «File not found» otherwise);
//  - T19: every clip says which track of its file it uses (`sourcetrack`), every file its
//    picture size and its sound's channels and rate (only the first clip of A1 had sound);
//  - T14: no clip is lost as a duplicate (the adapter writes identical clips once: montatore
//    makes them differ by track and start; here every clip is written whole).
// Off clips and tracks stay, marked `<enabled>FALSE</enabled>`. Fades, volumes, Ken Burns,
// titles, transitions, subtitles and markers are not exported (they are redone in Resolve):
// `resolveJob` counts them so the answer can say it.
//
// One difference from montatore, on purpose: a sound-only file (music, a voice-over) is
// described without a picture (`video: false`); montatore never had one and would give it the
// timeline's size.
import type { RgVideo } from "./doc-video.js";
import { isMediaRef } from "./video-timeline.js";

/** The rates OpenTimelineIO writes SMPTE timecode at (any other: montatore's engine fails). */
export const RESOLVE_RATES: readonly (readonly [number, number])[] = [
  [24000, 1001],
  [24, 1],
  [25, 1],
  [30000, 1001],
  [30, 1],
  [48000, 1001],
  [48, 1],
  [50, 1],
  [60000, 1001],
  [60, 1],
];
const VALID_RATES = new Set(RESOLVE_RATES.map(([n, d]) => n / d));

/** A camera's start timecode as montatore accepts it (`MediaFile::startTimecode`). */
export const CAMERA_TIMECODE = /^\d{1,2}:\d{2}:\d{2}[:;.]\d{2}$/;

/** A file of the timeline, as montatore's engine gets it (frames null: a picture). */
export interface ResolveMedia {
  url: string;
  name: string;
  frames: number | null;
  timecode: string | null;
  width: number;
  height: number;
  audio: { channels: number; sample_rate: number } | null;
  /** false: a sound-only file (no picture described). Absent: montatore's behaviour. */
  video?: boolean;
}
export interface ResolveJobClip {
  media: string | number;
  start: number;
  in: number;
  dur: number;
  enabled: boolean;
}
export interface ResolveJobTrack {
  id: string;
  type: "video" | "audio";
  enabled: boolean;
  clips: ResolveJobClip[];
}
/** Montatore's `fcpxml` input (times in frames at fps_num/fps_den). */
export interface ResolveJob {
  name?: string;
  fps_num: number;
  fps_den: number;
  width: number;
  height: number;
  media: Record<string, ResolveMedia>;
  tracks: ResolveJobTrack[];
}

/** The timeline's rate has no SMPTE timecode (montatore's engine fails there too). */
export class ResolveRateError extends Error {}

/** Whether OpenTimelineIO writes timecode at this rate. */
export const resolveRateOk = (num: number, den: number): boolean => VALID_RATES.has(num / den);

// -------------------------------------------------------------------------------------------
// Paths and timecode

const UNRESERVED = /[A-Za-z0-9_.\-~/]/;

/** Python's `urllib.parse.quote(s, safe="/")`. */
export function pyQuote(s: string): string {
  let out = "";
  for (const ch of s) {
    if (UNRESERVED.test(ch)) {
      out += ch;
      continue;
    }
    for (const b of new TextEncoder().encode(ch))
      out += `%${b.toString(16).toUpperCase().padStart(2, "0")}`;
  }
  return out;
}

/** Python's `urllib.parse.unquote` (bad sequences kept as they are). */
export function pyUnquote(s: string): string {
  return s.replace(/(%[0-9A-Fa-f]{2})+/g, (run) => {
    const bytes = new Uint8Array(run.length / 3);
    for (let i = 0; i < bytes.length; i++)
      bytes[i] = Number.parseInt(run.slice(i * 3 + 1, i * 3 + 3), 16);
    return new TextDecoder("utf-8", { fatal: false }).decode(bytes);
  });
}

/**
 * A path as the URL Premiere writes and Resolve reads (montatore's `to_url`, T17):
 * `file://localhost/E%3a/Video/x.mp4` on Windows, `file://localhost/mnt/…` elsewhere,
 * `file://server/share/…` for `\\server\share\…`; a `file://` URL stays as it is.
 */
export function resolveFileUrl(path: string): string {
  if (path.startsWith("file://")) return path;
  if (/^[A-Za-z]:[\\/]/.test(path)) {
    const rest = path.slice(2).replace(/\\/g, "/").replace(/^\/+/, "");
    return `file://localhost/${path[0]}%3a/${pyQuote(rest)}`;
  }
  if (path.startsWith("\\\\"))
    return `file://${pyQuote(path.replace(/^\\+/, "").replace(/\\/g, "/"))}`;
  return `file://localhost${pyQuote(path)}`;
}

/** C++'s `std::stoi`: leading blanks, a sign, digits; nothing readable is an error. */
const stoi = (s: string): number | undefined => {
  const m = /^\s*([+-]?\d+)/.exec(s);
  return m ? Number.parseInt(m[1] as string, 10) : undefined;
};

/**
 * OpenTimelineIO's `RationalTime.from_timecode` (0.18): the frame a timecode names at `rate`, or
 * undefined where it raises (a rate without timecode, `;` at a rate without drop frame, frames
 * past the rate, unreadable fields). Fields are read two characters at a time, as it does.
 */
export function otioTimecodeFrame(tc: string, rate: number): number | undefined {
  if (!VALID_RATES.has(rate)) return undefined;
  let drop = rate === 30000 / 1001 || rate === 60000 / 1001;
  if (tc.includes(";")) {
    if (!drop) return undefined;
  } else drop = false;
  const f = [0, 3, 6, 9].map((i) => stoi(tc.substr(i, 2)));
  if (f.some((x) => x === undefined)) return undefined;
  const [h, m, s, fr] = f as [number, number, number, number];
  const nominal = Math.ceil(rate);
  if (fr >= nominal) return undefined;
  const dropped = drop ? (rate === 30000 / 1001 ? 2 : 4) : 0;
  const minutes = h * 60 + m;
  return (minutes * 60 + s) * nominal + fr - dropped * (minutes - Math.trunc(minutes / 10));
}

/** Montatore's `start_time`: the file's start as a frame (0 when missing or unreadable). */
export const resolveStartFrame = (tc: string | null | undefined, rate: number): number =>
  (tc ? otioTimecodeFrame(tc, rate) : undefined) ?? 0;

/** `RationalTime.from_seconds(s, rate).round()` (half away from zero). */
const roundTime = (seconds: number, rate: number): number => {
  const v = seconds * rate;
  return v < 0 ? -Math.round(-v) : Math.round(v);
};

/** A still «lasts» what it needs to: an hour of material (montatore's STILL_AVAILABLE). */
export const STILL_SECONDS = 3600;

// -------------------------------------------------------------------------------------------
// A small element tree written as ElementTree writes it

interface El {
  tag: string;
  attrs: [string, string][];
  text?: string;
  kids: El[];
  tail?: string;
}
const el = (tag: string, text?: string, attrs: [string, string][] = []): El => ({
  tag,
  attrs,
  kids: [],
  ...(text !== undefined && text !== "" && { text }),
});
const add = (parent: El, tag: string, text?: string): El => {
  const e = el(tag, text);
  parent.kids.push(e);
  return e;
};
const find = (e: El, tag: string): El | undefined => e.kids.find((k) => k.tag === tag);

/** minidom's `toprettyxml(indent="    ")` read back by ElementTree: the blanks it leaves. */
function pretty(e: El, depth: number): void {
  if (!e.kids.length) return;
  const inner = `\n${"    ".repeat(depth + 1)}`;
  e.text = inner;
  for (const k of e.kids) {
    k.tail = inner;
    pretty(k, depth + 1);
  }
  (e.kids[e.kids.length - 1] as El).tail = `\n${"    ".repeat(depth)}`;
}

const escText = (s: string) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const escAttr = (s: string) => escText(s).replace(/"/g, "&quot;").replace(/\n/g, "&#10;");

function write(e: El, out: string[]): void {
  out.push(`<${e.tag}`);
  for (const [k, v] of e.attrs) out.push(` ${k}="${escAttr(v)}"`);
  if (e.text || e.kids.length) {
    out.push(">");
    if (e.text) out.push(escText(e.text));
    for (const k of e.kids) write(k, out);
    out.push(`</${e.tag}>`);
  } else out.push(" />");
  if (e.tail) out.push(e.tail);
}

/** XML 1.0 cannot carry most control characters: they are dropped (Python would fail). */
const xmlSafe = (s: string) =>
  // biome-ignore lint/suspicious/noControlCharactersInRegex: the characters XML refuses
  s.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, "");

const rateEl = (fps: number): El => {
  const base = Math.ceil(fps);
  const r = el("rate");
  add(r, "timebase", String(base));
  add(r, "ntsc", base === fps ? "FALSE" : "TRUE");
  return r;
};

/** The adapter's `<timecode>` for a start frame (its string is replaced by the camera's). */
const timecodeEl = (frame: number, fps: number): El => {
  const tc = el("timecode");
  tc.kids.push(rateEl(fps));
  add(tc, "string", "00:00:00:00");
  add(tc, "frame", String(Math.round(frame)));
  add(tc, "displayformat", "NDF");
  return tc;
};

const AUDIO_EXTS = new Set([".wav", ".aac", ".mp3", ".aif", ".aiff", ".m4a"]);
const urlPath = (url: string): string => {
  const m = /^[a-z][a-z0-9+.-]*:\/\/[^/?#]*([^?#]*)/i.exec(url);
  return m ? (m[1] as string) : (url.split(/[?#]/)[0] as string);
};
const baseName = (p: string) => p.slice(p.lastIndexOf("/") + 1);

/**
 * The XML for Resolve of a job, the same text montatore's engine writes for it. Throws
 * `ResolveRateError` at a rate without SMPTE timecode, and on a clip whose media is not in
 * `job.media` (montatore fails there too).
 */
export function fcp7Xml(job: ResolveJob): string {
  const fps = job.fps_num / job.fps_den;
  if (!VALID_RATES.has(fps))
    throw new ResolveRateError(
      `a timeline at ${+fps.toFixed(3)} fps has no SMPTE timecode: Resolve's XML needs 23.976, 24, 25, 29.97, 30, 47.952, 48, 50, 59.94 or 60`,
    );
  const name = xmlSafe(job.name ?? "montatore");
  const media = new Map(Object.entries(job.media));

  // The adapter's tree (OTIO's build, then otio-fcp-adapter's writer).
  const root = el("xmeml", undefined, [["version", "4"]]);
  const project = add(root, "project");
  add(project, "name", name);
  const children = add(project, "children");
  const seq = el("sequence", undefined, [["id", "sequence-1"]]);
  children.kids.push(seq);
  add(seq, "name", name || "tracks");
  const seqDuration = add(seq, "duration");
  seq.kids.push(rateEl(fps));
  const seqMedia = add(seq, "media");
  const video = add(seqMedia, "video");
  const audio = add(seqMedia, "audio");
  add(video, "format");

  const fileIds = new Map<string, number>();
  const placed: { kind: "video" | "audio"; el: El; job: ResolveJobTrack; clips: El[] }[] = [];
  let clipN = 0;
  let longest = 0;
  for (const t of job.tracks) {
    const trackEl = el("track");
    const items: El[] = [];
    let cursor = 0;
    let at = 0;
    for (const c of [...t.clips].sort((a, b) => a.start - b.start)) {
      if (c.start > cursor) at += c.start - cursor;
      const m = media.get(String(c.media));
      if (!m) throw new Error(`the clip at ${c.start} names a file the job does not list`);
      const still = m.frames === null;
      const tc0 = still ? 0 : resolveStartFrame(m.timecode, fps);
      const available = roundTime(still ? STILL_SECONDS : (m.frames as number) / fps, fps);
      const inF = roundTime(still ? 0 : c.in / fps, fps);
      const dur = roundTime(c.dur / fps, fps);
      const url = resolveFileUrl(m.url);

      const item = el("clipitem", undefined, [
        ["frameBlend", "FALSE"],
        ["id", `clipitem-${++clipN}`],
      ]);
      let fileId = fileIds.get(url);
      if (fileId !== undefined) item.kids.push(el("file", undefined, [["id", `file-${fileId}`]]));
      else {
        fileId = fileIds.size + 1;
        fileIds.set(url, fileId);
        const file = el("file", undefined, [["id", `file-${fileId}`]]);
        add(file, "pathurl", url);
        add(file, "name", baseName(urlPath(url)));
        file.kids.push(rateEl(fps));
        add(file, "duration", String(available));
        file.kids.push(timecodeEl(tc0, fps));
        const fm = add(file, "media");
        const ext = /\.[^./]*$/.exec(baseName(urlPath(url)))?.[0]?.toLowerCase() ?? "";
        if (!AUDIO_EXTS.has(ext)) add(fm, "video");
        add(fm, "audio");
        item.kids.push(file);
      }
      add(item, "name", xmlSafe(m.name));
      item.kids.push(rateEl(fps));
      item.kids.push(rateEl(fps));
      add(item, "duration", String(dur));
      add(item, "start", String(at));
      add(item, "end", String(at + dur));
      add(item, "in", String(inF));
      add(item, "out", String(inF + dur));
      trackEl.kids.push(item);
      items.push(item);
      at += dur;
      cursor = c.start + c.dur;
    }
    longest = Math.max(longest, at);
    placed.push({ kind: t.type, el: trackEl, job: t, clips: items });
  }
  seqDuration.text = String(longest);
  for (const p of placed) (p.kind === "video" ? video : audio).kids.push(p.el);
  seq.kids.push(timecodeEl(0, fps));
  pretty(root, 0);

  // montatore's finish_xml: what Resolve expects, as Premiere writes it.
  const byUrl = new Map<string, ResolveMedia>();
  for (const m of media.values()) byUrl.set(resolveFileUrl(m.url), m);
  const files: El[] = [];
  const collect = (e: El) => {
    if (e.tag === "file") files.push(e);
    for (const k of e.kids) collect(k);
  };
  collect(root);
  for (const f of files) {
    const pathurl = find(f, "pathurl")?.text ?? "";
    const item = byUrl.get(pathurl);
    if (!item) continue;
    const nameEl = find(f, "name");
    const shown = xmlSafe(item.name) || pyUnquote(baseName(pathurl));
    if (nameEl && shown) nameEl.text = shown;
    else if (nameEl) delete nameEl.text;
    const tc = find(f, "timecode");
    if (item.timecode && tc) {
      (find(tc, "string") as El).text = item.timecode;
      (find(tc, "displayformat") as El).text = item.timecode.includes(";") ? "DF" : "NDF";
    }
    const fm = find(f, "media") as El;
    fm.kids = [];
    if (item.video !== false) {
      const sc = add(add(fm, "video"), "samplecharacteristics");
      add(sc, "width", String(item.width || job.width));
      add(sc, "height", String(item.height || job.height));
    }
    if (item.audio) {
      const a = add(fm, "audio");
      const sc = add(a, "samplecharacteristics");
      add(sc, "depth", "16");
      add(sc, "samplerate", String(item.audio.sample_rate ?? 48000));
      add(a, "channelcount", String(item.audio.channels ?? 2));
    }
  }
  for (const kind of ["video", "audio"] as const)
    for (const p of placed) {
      if (p.kind !== kind) continue;
      for (const item of p.clips) {
        const st = add(item, "sourcetrack");
        add(st, "mediatype", kind);
        add(st, "trackindex", "1");
      }
      if (!p.job.enabled) add(p.el, "enabled", "FALSE");
      const clips = [...p.job.clips].sort((a, b) => a.start - b.start);
      p.clips.forEach((item, i) => {
        if (clips[i] && !clips[i].enabled) add(item, "enabled", "FALSE");
      });
    }

  const out: string[] = ["<?xml version='1.0' encoding='UTF-8'?>\n"];
  write(root, out);
  return out.join("");
}

// -------------------------------------------------------------------------------------------
// From a timeline

/** What the export needs of a file (ffprobe's, `MediaProbe`); undefined: not found. */
export interface ResolveFileFacts {
  kind: "video" | "image" | "audio";
  duration: number | null;
  width: number;
  height: number;
  audio: boolean;
  channels: number | null;
  sampleRate: number | null;
  timecode: string | null;
}

/** What a timeline has that the XML for Resolve does not carry (redone in Resolve). */
export interface ResolveLeftOut {
  titles: number;
  transitions: number;
  fades: number;
  volumes: number;
  kenBurns: number;
  reframes: number;
  speeds: number;
  ducking: number;
  markers: number;
  captions: number;
  /** Files not found: exported with what the timeline knows of them. */
  missing: string[];
}

export interface ResolveJobOptions {
  /** The sequence's name (montatore: the project's). */
  name: string;
  /** Where Resolve will find a file of the project (`resolveMediaPath`). */
  path(media: string): string;
}

/** The last part of a path, either slash. */
const fileName = (p: string) => p.slice(Math.max(p.lastIndexOf("/"), p.lastIndexOf("\\")) + 1);

/**
 * Where Resolve finds a file (montatore's D21): in the folder the person named, where the
 * originals are on the computer that runs Resolve, by the file's name; without a folder, the
 * file where it is on this machine. Two different files of the timeline with the same name keep
 * their folders below `root` (montatore had one folder of uploads; a project here has folders).
 */
export function resolveMediaPaths(
  files: readonly string[],
  root: string | undefined,
  absolute: (media: string) => string,
): Record<string, string> {
  const out: Record<string, string> = {};
  const r = root?.trim() ?? "";
  if (!r) {
    for (const f of files) out[f] = absolute(f);
    return out;
  }
  const sep = /^[A-Za-z]:\\|\\/.test(r) ? "\\" : "/";
  const names = new Map<string, number>();
  for (const f of files)
    names.set(fileName(f).toLowerCase(), (names.get(fileName(f).toLowerCase()) ?? 0) + 1);
  const base = r.replace(/[\\/]+$/, "");
  for (const f of files) {
    const rel = (names.get(fileName(f).toLowerCase()) ?? 0) > 1 ? f : fileName(f);
    out[f] = `${base}${sep}${rel.replace(/[\\/]+/g, sep)}`;
  }
  return out;
}

/**
 * Montatore's export job of a timeline (ExportBuilder::timelineJob): every track in order, on or
 * off; on each its clips of files (titles and colours have no file: left out), by start; every
 * file used once, with its name, its length in frames (null for a picture), the camera's
 * timecode, its size and its sound. Pure.
 */
export function resolveJob(
  doc: RgVideo,
  facts: Readonly<Record<string, ResolveFileFacts | undefined>>,
  o: ResolveJobOptions,
): { job: ResolveJob; leftOut: ResolveLeftOut } {
  const { num, den } = doc.format.rate;
  const fps = num / den;
  const media: Record<string, ResolveMedia> = {};
  const leftOut: ResolveLeftOut = {
    titles: 0,
    transitions: doc.transitions.length,
    fades: 0,
    volumes: 0,
    kenBurns: 0,
    reframes: 0,
    speeds: 0,
    ducking: doc.tracks.filter((t) => t.duck).length,
    markers: doc.markers.length,
    captions: doc.captions.segments.length,
    missing: [],
  };
  const ends = new Map<string, number>();
  for (const c of doc.clips) {
    if (!isMediaRef(c.ref)) {
      leftOut.titles++;
      continue;
    }
    if (c.fadeIn > 0 || c.fadeOut > 0) leftOut.fades++;
    if (c.volume !== 0) leftOut.volumes++;
    if (c.kenBurns) leftOut.kenBurns++;
    if (c.crop || c.fit !== "fill") leftOut.reframes++;
    if (c.speed !== undefined && c.speed !== 1) leftOut.speeds++;
    const end = c.sourceRange.start + c.sourceRange.duration;
    ends.set(c.ref.media, Math.max(ends.get(c.ref.media) ?? 0, end));
  }
  for (const c of doc.clips) {
    if (!isMediaRef(c.ref) || media[c.ref.media]) continue;
    const path = c.ref.media;
    const f = facts[path];
    if (!f) leftOut.missing.push(path);
    const still = f ? f.kind === "image" : !!c.ref.still;
    const frames = still
      ? null
      : f?.duration != null
        ? Math.max(1, Math.floor(f.duration * fps))
        : (c.ref.frames ?? Math.max(1, ends.get(path) ?? 1));
    const tc = f?.timecode && CAMERA_TIMECODE.test(f.timecode) ? f.timecode : null;
    const sound = f ? f.audio : !still && c.ref.audio !== false;
    media[path] = {
      url: o.path(path),
      name: fileName(path),
      frames,
      timecode: tc,
      width: f?.width ?? 0,
      height: f?.height ?? 0,
      audio: sound ? { channels: f?.channels ?? 2, sample_rate: f?.sampleRate ?? 48000 } : null,
      ...(f?.kind === "audio" && { video: false }),
    };
  }
  const job: ResolveJob = {
    name: o.name,
    fps_num: num,
    fps_den: den,
    width: doc.format.width,
    height: doc.format.height,
    media,
    tracks: doc.tracks.map((t) => ({
      id: t.id,
      type: t.kind === "Audio" ? "audio" : "video",
      enabled: !(t.hidden ?? t.muted ?? false),
      clips: doc.clips
        .filter((c) => c.track === t.id && isMediaRef(c.ref))
        .sort((a, b) => a.start - b.start)
        .map((c) => ({
          media: (c.ref as { media: string }).media,
          start: c.start,
          in: c.sourceRange.start,
          dur: c.sourceRange.duration,
          enabled: c.enabled,
        })),
    })),
  };
  return { job, leftOut };
}
