// The render compiler (G41.3): a `.rgvideo` timeline made into ffmpeg runs, as montatore's
// render.py does it (its trap T13: one graph with many 4K inputs runs out of memory).
//
// 1. The picture is cut into segments at every edge of a clip and of a transition's window: in
//    a segment each video track shows at most one clip (or the two clips of one transition), so
//    a segment opens only its own files. Tracks are stacked from V1 up over black; a picture,
//    a text or a colour is never the base (S53 in montatore: after zoompan the fps filter drops
//    the last frame), a video that covers the frame without fading is. Every segment is
//    encoded on its own, to the exact frame (`-frames:v`, and every stream held on its last
//    frame and cut to the segment's length).
// 2. The sound is mixed in a pass of its own (no video to decode): every audio clip in its
//    place (`adelay` in samples), volume and fades, `amix normalize=0` per track and for all,
//    music ducked under the voice (`sidechaincompress`), `loudnorm` to −14 LUFS when on (A2):
//    two passes (measured, then corrected linearly), since one pass misses short videos.
// 3. Segments and sound are joined without re-encoding (`concat`, `+faststart`), with the
//    subtitles as a text track when they are not burnt in, and SRT and WebVTT beside.
//
// Effects. Fades and Ken Burns are computed on the clip's own time (`setpts` shifted by the
// frames already played), so a clip split over several segments goes on without a jump.
// Transitions are not `xfade`: xfade's progress always starts at 0 within its graph, and a
// transition's window can be split by an edge on another track; they are overlays whose
// progress is the frame inside the window (dissolve: the next clip's alpha; wipes: a moving
// mask; slides: a moving position). `dip_to_black` needs no extra frames: the first clip fades
// to black before the cut, the second from black after it. The others need frames past the
// cut: the transition is centred on it, `inOffset` frames before (into the first clip) and
// `outOffset` after (into the second), the clips keep their length, and inside the window the
// first clip goes on after its out point and the second starts before its in point, taking
// the file's own frames (handles) when the file has them (`ref.frames` from ffprobe), and
// holding the edge frame where it has not (a warning says which).
// J-cuts and L-cuts need nothing: audio clips are trimmed on their own tracks. Video clips
// never play sound; their linked audio clips do.
//
// Everything here is pure: the document, the probes and the target in; the filter graphs as
// text, the arguments, the files the graphs read and a hash per segment out. `render.ts` runs
// it with `execFile` and `-/filter_complex <file>` (ffmpeg 9 has no -filter_complex_script).
import { createHash } from "node:crypto";
import {
  cleanTimeline,
  clipEnd,
  clipLength,
  type H264Encoder,
  isMediaRef,
  lanes,
  type RgVideo,
  trackOf,
  type VideoClip,
  type VideoProbe,
  type VideoRate,
  type VideoRect,
  type VideoTransition,
} from "@redgiant/protocol";
import { captionsToSrt, captionsToVtt } from "./captions.js";
import { captionsAss, subtitleLanguage, textWidth } from "./render-subtitles.js";

export { textWidth };

/** Changes when the graphs change: cached segments of another version are not reused. */
export const VIDEO_COMPILER_VERSION = "1";
/** Seconds read past what a segment needs, so an input never runs short. */
const MARGIN = 0.25;
/** A picture with Ken Burns is prepared at twice the output's size (smooth movement). */
const PRESCALE = 2;
export const AUDIO_RATE = 48_000;
/** The shortest fade at each audio clip's edges, against clicks (10 ms). */
const AUDIO_EDGE = 480;
/** A2: the loudness of the finished video (YouTube, Instagram, TikTok all aim near it). */
export const LOUDNESS_TARGET = -14;
const LOUDNORM = `loudnorm=I=${LOUDNESS_TARGET}:TP=-1.5:LRA=11`;
const AAC_ARGS = ["-c:a", "aac", "-b:a", "256k", "-ar", String(AUDIO_RATE), "-ac", "2"];

/** ffprobe's answer for a file (`probe.ts`), with what identifies its content for the cache. */
export interface RenderProbe extends VideoProbe {
  /** Size and modification time, or a hash: a segment's hash changes when its files do. */
  fingerprint?: string;
}

export type RenderQuality = "draft" | "good" | "best";
export type RenderCaptions = "burn" | "track" | "none";

export interface RenderTarget {
  encoder: H264Encoder;
  /** The output's height; never more than the timeline's (never enlarged). */
  height?: number;
  /** draft: the exact preview (G41.5a); good: the default; best: slower, smaller. */
  quality?: RenderQuality;
  /** A2: the sound brought to −14 LUFS (on unless false). */
  loudnorm?: boolean;
  /** Burnt into the picture, as the MP4's text track, or neither (SRT/VTT are always beside). */
  captions?: RenderCaptions;
  /** The folder of the server's fonts (`packages/server/fonts`: Inter for texts and subtitles). */
  fontsDir: string;
  /**
   * Only a stretch of the timeline, in frames [from, to) (G41.5a, the exact preview): segments cut
   * at its ends, the sound of the whole timeline (cached by its hash) started at `from`.
   */
  span?: { from: number; to: number };
}

/** One ffmpeg input: its options and the project file it reads. */
export interface RenderInput {
  before: string[];
  media: string;
}

/** One ffmpeg run of the plan: a segment of the picture, or the sound. */
export interface RenderStep {
  /** The file it writes (`seg-<hash>.mp4`, `audio-<hash>.m4a`): the same work, the same name. */
  name: string;
  hash: string;
  /** The first frame in the timeline and how many (the sound: all of it). */
  start: number;
  frames: number;
  inputs: RenderInput[];
  /** The filter graph, written to `<name>.graph` and read with `-/filter_complex`. */
  script: string;
  /** Files the graph reads, by name (texts for drawtext, ASS for libass). */
  files: Record<string, string>;
  /** What comes after the graph: maps and encoder options (the output name is added). */
  output: string[];
}

export interface RenderPlan {
  width: number;
  height: number;
  rate: VideoRate;
  /** The first frame rendered (0, or a span's start); `frames` are counted from it. */
  start: number;
  frames: number;
  seconds: number;
  segments: RenderStep[];
  /** The sound's mix; with `loudness` a FLAC mix measured and corrected to −14 LUFS (A2). */
  audio: RenderStep;
  loudness: boolean;
  captions: { mode: RenderCaptions; srt?: string; vtt?: string; language: string };
  warnings: string[];
}

export class EmptyTimeline extends Error {
  constructor() {
    super("Nothing to render: no clip is on, on a track that shows or sounds.");
  }
}

// -------------------------------------------------------------------------------------------
// Small helpers

const even = (n: number) => Math.max(2, Math.round(n / 2) * 2);
const num = (x: number, d = 6) => {
  const s = x.toFixed(d);
  return s === `-${(0).toFixed(d)}` ? (0).toFixed(d) : s;
};
/** Frames to seconds, as text. */
const secOf = (f: number, r: VideoRate) => num((f * r.den) / r.num);
/** Frames to audio samples. */
const samplesOf = (f: number, r: VideoRate) => Math.round((f * r.den * AUDIO_RATE) / r.num);
const sha = (s: string) => createHash("sha256").update(s).digest("hex");

/**
 * A value inside a filter graph read from a file: quoted for the option parser, then escaped
 * for the graph parser (so a Windows path's colon and an apostrophe survive). Backslashes of a
 * path become slashes, which ffmpeg reads everywhere.
 */
export function filterValue(v: string): string {
  const l1 = `'${v.replace(/'/g, "'\\''")}'`;
  return l1.replace(/[\\'[\],;]/g, (m) => `\\${m}`);
}
export const filterPath = (p: string) => filterValue(p.replace(/\\/g, "/"));

/** A file the graph reads, named by its content: the same text, the same name, the same hash. */
function contentFile(files: Record<string, string>, ext: string, content: string): string {
  const name = `x-${sha(content).slice(0, 16)}.${ext}`;
  files[name] = content;
  return name;
}

/** The output's size: the timeline's, or smaller at `height`, even sides. */
export function outputSize(doc: RgVideo, height?: number): { width: number; height: number } {
  const fh = doc.format.height;
  const h = even(Math.min(height && height > 0 ? height : fh, fh));
  return { width: even((doc.format.width * h) / fh), height: h };
}

/** H.264 High, yuv420p, BT.709 TV range, no timecode or camera metadata (as montatore). */
export function encoderArgs(
  encoder: H264Encoder,
  quality: RenderQuality,
  rate: VideoRate,
): string[] {
  const gop = String(Math.max(1, Math.round(rate.num / rate.den)));
  const codec =
    encoder === "h264_nvenc"
      ? [
          "-c:v",
          "h264_nvenc",
          "-preset",
          { draft: "p1", good: "p5", best: "p7" }[quality],
          "-tune",
          "hq",
          "-rc",
          "vbr",
          "-cq",
          { draft: "30", good: "21", best: "18" }[quality],
          "-b:v",
          "0",
        ]
      : [
          "-c:v",
          "libx264",
          "-preset",
          { draft: "ultrafast", good: "fast", best: "slow" }[quality],
          "-crf",
          { draft: "28", good: "20", best: "17" }[quality],
        ];
  return [
    ...codec,
    "-profile:v",
    "high",
    "-pix_fmt",
    "yuv420p",
    "-g",
    gop,
    "-bf",
    "2",
    "-r",
    `${rate.num}/${rate.den}`,
    "-color_range",
    "tv",
    "-colorspace",
    "bt709",
    "-color_primaries",
    "bt709",
    "-color_trc",
    "bt709",
    "-map_metadata",
    "-1",
  ];
}

// -------------------------------------------------------------------------------------------
// Pieces: what each video track shows, and when

interface Dips {
  in: number;
  out: number;
}

type Piece =
  | { kind: "clip"; from: number; to: number; clip: VideoClip }
  | {
      kind: "mix";
      from: number;
      to: number;
      t: VideoTransition;
      a: VideoClip;
      b: VideoClip;
    };

interface Ctx {
  doc: RgVideo;
  rate: VideoRate;
  w: number;
  h: number;
  probes: Record<string, RenderProbe>;
  fontsDir: string;
  dips: Map<string, Dips>;
  warn: (s: string) => void;
}

/** The transitions of a track that join two clips that both play, one right after the other. */
function liveTransitions(doc: RgVideo, track: string, playing: VideoClip[]): VideoTransition[] {
  const byId = new Map(playing.map((c) => [c.id, c]));
  return doc.transitions.filter((t) => {
    const a = byId.get(t.from);
    const b = byId.get(t.to);
    return (
      t.track === track &&
      !!a &&
      !!b &&
      a.track === track &&
      b.track === track &&
      clipEnd(a) === b.start &&
      t.inOffset + t.outOffset > 0
    );
  });
}

/**
 * A video track's pieces: each clip where it shows alone, and each transition's window with its
 * two clips. Two windows that would overlap inside a short clip are shortened (the second's
 * frames before its cut). Dips to black become fades of the two clips (`dips`).
 */
function trackPieces(ctx: Ctx, track: string): Piece[] {
  const playing = ctx.doc.clips
    .filter((c) => c.track === track && c.enabled)
    .sort((a, b) => a.start - b.start);
  const byId = new Map(playing.map((c) => [c.id, c]));
  const head = new Map<string, number>();
  const tail = new Map<string, number>();
  const mixes: { t: VideoTransition; a: VideoClip; b: VideoClip }[] = [];
  for (const t of liveTransitions(ctx.doc, track, playing).sort(
    (x, y) => (byId.get(x.from)?.start ?? 0) - (byId.get(y.from)?.start ?? 0),
  )) {
    const a = byId.get(t.from) as VideoClip;
    const b = byId.get(t.to) as VideoClip;
    if (t.kind === "dip_to_black") {
      const da = ctx.dips.get(a.id) ?? { in: 0, out: 0 };
      const db = ctx.dips.get(b.id) ?? { in: 0, out: 0 };
      ctx.dips.set(a.id, { ...da, out: Math.min(t.inOffset, clipLength(a)) });
      ctx.dips.set(b.id, { ...db, in: Math.min(t.outOffset, clipLength(b)) });
      continue;
    }
    const room = clipLength(a) - (head.get(a.id) ?? 0);
    const before = Math.min(t.inOffset, Math.max(0, room));
    if (before < t.inOffset)
      ctx.warn(
        `transition ${t.id} starts ${t.inOffset - before} frames later: ${a.id} is too short for two transitions`,
      );
    const after = Math.min(t.outOffset, clipLength(b));
    if (before + after === 0) continue;
    tail.set(a.id, before);
    head.set(b.id, after);
    mixes.push({ t: { ...t, inOffset: before, outOffset: after }, a, b });
  }
  const pieces: Piece[] = [];
  for (const c of playing) {
    const from = c.start + (head.get(c.id) ?? 0);
    const to = clipEnd(c) - (tail.get(c.id) ?? 0);
    if (to > from) pieces.push({ kind: "clip", from, to, clip: c });
  }
  for (const m of mixes) {
    const cut = clipEnd(m.a);
    pieces.push({ kind: "mix", from: cut - m.t.inOffset, to: cut + m.t.outOffset, ...m });
  }
  return pieces.sort((x, y) => x.from - y.from);
}

// -------------------------------------------------------------------------------------------
// A segment's graph

class Graph {
  inputs: RenderInput[] = [];
  lines: string[] = [];
  files: Record<string, string> = {};
  private n = 0;
  label(prefix: string): string {
    return `${prefix}${this.n++}`;
  }
  input(before: string[], media: string): number {
    this.inputs.push({ before, media });
    return this.inputs.length - 1;
  }
}

/** Appends filters to a chain that is either open (`[0:v]a,b`) or a bare label (`[x]`). */
const cont = (chain: string, f: string) =>
  chain.endsWith("]") || chain === "" ? `${chain}${f}` : `${chain},${f}`;

function cropFilter(r: VideoRect): string {
  const w = Math.min(r.w, 1 - r.x);
  const h = Math.min(r.h, 1 - r.y);
  return `crop=w=iw*${num(w, 4)}:h=ih*${num(h, 4)}:x=iw*${num(r.x, 4)}:y=ih*${num(r.y, 4)}`;
}

const fillFilter = (w: number, h: number) =>
  `scale=${w}:${h}:force_original_aspect_ratio=increase:flags=lanczos:out_range=tv,crop=${w}:${h},setsar=1`;
const fitFilter = (w: number, h: number) =>
  `scale=${w}:${h}:force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos:out_range=tv,setsar=1`;

/** A file's picture at w×h: filled (cropped at the centre) or fitted on black, nothing, or blur. */
function picture(g: Graph, chain: string, c: VideoClip, w: number, h: number): string {
  let ch = c.crop ? cont(chain, cropFilter(c.crop)) : chain;
  if (c.fit === "fill") return cont(ch, fillFilter(w, h));
  const pad = `pad=${w}:${h}:(ow-iw)/2:(oh-ih)/2`;
  if (c.background === "black") return cont(ch, `${fitFilter(w, h)},${pad}:color=black`);
  if (c.background !== "blur")
    return cont(ch, `format=yuva420p,${fitFilter(w, h)},${pad}:color=black@0`);
  // A1: the picture fitted on a blurred, filled copy of itself (blurred small: cheap).
  const a = g.label("sa");
  const b = g.label("sb");
  const bg = g.label("bg");
  const fg = g.label("fg");
  const out = g.label("pb");
  const qw = even(w / 4);
  const qh = even(h / 4);
  g.lines.push(cont(ch, `split=2[${a}][${b}]`));
  g.lines.push(
    `[${a}]${fillFilter(qw, qh)},boxblur=8:2,scale=${w}:${h}:flags=bicubic,setsar=1[${bg}]`,
  );
  g.lines.push(`[${b}]${fitFilter(w, h)}[${fg}]`);
  g.lines.push(`[${bg}][${fg}]overlay=(W-w)/2:(H-h)/2[${out}]`);
  ch = `[${out}]`;
  return ch;
}

/** Ken Burns: the part of the picture shown moves from one rectangle to the other. */
function kenBurns(
  c: VideoClip,
  w: number,
  h: number,
  frames: number,
  offset: number,
  rate: VideoRate,
): string {
  const kb = c.kenBurns as NonNullable<VideoClip["kenBurns"]>;
  const p = `((on+${offset})/${Math.max(clipLength(c) - 1, 1)})`;
  const lerp = (a: number, b: number) => `(${num(a, 4)}+(${num(b - a, 4)})*${p})`;
  const z = `1/${lerp(kb.from.w, kb.to.w)}`;
  const x = `iw*${lerp(kb.from.x, kb.to.x)}`;
  const y = `ih*${lerp(kb.from.y, kb.to.y)}`;
  return `zoompan=z='${z}':x='${x}':y='${y}':d=${frames}:s=${w}x${h}:fps=${rate.num}/${rate.den}`;
}

/** Fades on the clip's own time: alpha for its fades, colour (to black) for a dip. */
function fades(c: VideoClip, o: number, n: number, ctx: Ctx, opaque: boolean): string {
  const L = clipLength(c);
  const r = ctx.rate;
  const dip = ctx.dips.get(c.id) ?? { in: 0, out: 0 };
  const parts: string[] = [];
  const touchesIn = (len: number) => len > 0 && o < len && o + n > 0;
  const touchesOut = (len: number) => len > 0 && o + n > L - len && o < L;
  if (!opaque && touchesIn(c.fadeIn)) parts.push(`fade=t=in:st=0:d=${secOf(c.fadeIn, r)}:alpha=1`);
  if (!opaque && touchesOut(c.fadeOut))
    parts.push(`fade=t=out:st=${secOf(L - c.fadeOut, r)}:d=${secOf(c.fadeOut, r)}:alpha=1`);
  if (touchesIn(dip.in)) parts.push(`fade=t=in:st=0:d=${secOf(dip.in, r)}`);
  if (touchesOut(dip.out))
    parts.push(`fade=t=out:st=${secOf(L - dip.out, r)}:d=${secOf(dip.out, r)}`);
  if (!parts.length) return "";
  const s = secOf(Math.abs(o), r);
  const [fwd, back] = o >= 0 ? ["+", "-"] : ["-", "+"];
  return `,setpts=PTS${fwd}${s}/TB,${parts.join(",")},setpts=PTS${back}${s}/TB`;
}

/** Does this clip's alpha fade touch the frames [o, o+n)? */
function alphaFades(c: VideoClip, o: number, n: number): boolean {
  const L = clipLength(c);
  return (c.fadeIn > 0 && o < c.fadeIn) || (c.fadeOut > 0 && o + n > L - c.fadeOut);
}

/** Can this piece be the base (no black under it)? A video that covers the frame, unfaded. */
function isBase(p: Piece, segStart: number, n: number): boolean {
  if (p.kind !== "clip") return false;
  const c = p.clip;
  if (!isMediaRef(c.ref) || c.ref.still) return false;
  if (c.fit === "fit" && !c.background) return false;
  return !alphaFades(c, segStart - c.start, n);
}

const TEXT_LOOK = {
  title: { font: "Inter-Bold.ttf", size: 0.085, box: false, shadow: true },
  subtitle: { font: "Inter-Regular.ttf", size: 0.055, box: false, shadow: true },
  lower_third: { font: "Inter-Bold.ttf", size: 0.05, box: true, shadow: false },
  caption: { font: "Inter-Regular.ttf", size: 0.045, box: true, shadow: false },
  plain: { font: "Inter-Regular.ttf", size: 0.05, box: false, shadow: false },
} as const;

/** The title-safe margin: every text stays this far (a share of the side) from each edge. */
export const TITLE_SAFE = 0.05;

/** Words on lines no wider than `room` pixels (a word wider than that stays whole). */
export function wrapToWidth(text: string, room: number, size: number, bold = false): string[] {
  const lines: string[] = [];
  for (const para of text.replace(/\r\n?/g, "\n").split("\n")) {
    let cur = "";
    for (const word of para.split(/\s+/).filter(Boolean)) {
      const next = cur ? `${cur} ${word}` : word;
      if (cur && textWidth(next, size, bold) > room) {
        lines.push(cur);
        cur = word;
      } else cur = next;
    }
    lines.push(cur);
  }
  return lines;
}

export interface FittedText {
  size: number;
  lines: string[];
  /** The box's border around a lower third (0 without a box). */
  border: number;
  x: string;
  y: string;
  align: "C" | "L";
}

/**
 * A text placed inside the title-safe area (5% from each side): its size follows the short
 * side (the same title fits 16:9, 9:16 and 1:1), its words go on new lines when a line is too
 * wide, and when a single word or the lines' height still do not fit the size goes down. A
 * lower third's box is inside the area too: it grows to the left edge of the area and wraps,
 * it is never cut.
 */
export function fitText(
  text: string,
  style: keyof typeof TEXT_LOOK,
  position: "center" | "top" | "bottom" | "lower_third",
  w: number,
  h: number,
): FittedText {
  const look = TEXT_LOOK[style];
  const bold = look.font.includes("Bold");
  const side = Math.min(w, h);
  const border = look.box ? Math.max(2, Math.round(side * 0.015)) : 0;
  const shadow = look.shadow ? Math.max(1, Math.round(side / 360)) : 0;
  const mx = Math.ceil(w * TITLE_SAFE);
  const my = Math.ceil(h * TITLE_SAFE);
  const room = w - 2 * mx - 2 * border - shadow;
  // Lines take 1.25 of the size (line_spacing 0.25); top, bottom and the lower third start
  // lower than the area's edge, so they have less height.
  const top = {
    center: my,
    top: Math.round(h * 0.08),
    bottom: my,
    lower_third: Math.round(h * 0.7),
  }[position];
  const height = position === "lower_third" ? h - my - top : h - 2 * my;
  let size = Math.max(8, Math.round(side * look.size));
  let lines = wrapToWidth(text, room, size, bold);
  const fits = () =>
    Math.max(...lines.map((l) => textWidth(l, size, bold))) <= room &&
    lines.length * size * 1.25 + 2 * border <= Math.max(height, size * 1.25 + 2 * border);
  while (!fits() && size > 8) {
    size = Math.max(8, Math.floor(size * 0.92));
    lines = wrapToWidth(text, room, size, bold);
  }
  const lo = `h-${my}-${border}-text_h`;
  const y = {
    center: "(h-text_h)/2",
    top: `${Math.max(top, my + border)}`,
    bottom: `h-text_h-${Math.round(h * 0.08) + border}`,
    // Moved up when its lines would go past the bottom of the area.
    lower_third: `min(${top}\\,${lo})`,
  }[position];
  return {
    size,
    lines,
    border,
    x: position === "lower_third" ? `${mx + border}` : "(w-text_w)/2",
    y,
    align: position === "lower_third" ? "L" : "C",
  };
}

/** A text clip: drawtext over a transparent frame, the text read from a file (no escaping). */
function textFilter(g: Graph, ctx: Ctx, c: VideoClip): string {
  const ref = c.ref as Extract<VideoClip["ref"], { generator: "text" }>;
  const look = TEXT_LOOK[ref.style];
  const fit = fitText(ref.text, ref.style, ref.position, ctx.w, ctx.h);
  const side = Math.min(ctx.w, ctx.h);
  const textFile = contentFile(g.files, "txt", fit.lines.join("\n"));
  const font = `${ctx.fontsDir.replace(/[\\/]+$/, "")}/${look.font}`;
  const opts = [
    `fontfile=${filterPath(font)}`,
    `textfile=${textFile}`,
    "expansion=none",
    `text_align=${fit.align}`,
    `fontsize=${fit.size}`,
    "fontcolor=white",
    `line_spacing=${Math.round(fit.size * 0.25)}`,
    `x=${fit.x}`,
    `y=${fit.y}`,
  ];
  if (look.shadow) {
    const d = Math.max(1, Math.round(side / 360));
    opts.push("shadowcolor=black@0.6", `shadowx=${d}`, `shadowy=${d}`);
  }
  if (look.box) opts.push("box=1", "boxcolor=black@0.55", `boxborderw=${fit.border}`);
  return `drawtext=${opts.join(":")}`;
}

/**
 * One clip's stream for a segment: `n` frames starting `o` frames into the clip (negative, or
 * past its length, inside a transition's window), w×h, its fades applied. Returns its label.
 */
function clipStream(
  g: Graph,
  ctx: Ctx,
  c: VideoClip,
  o: number,
  n: number,
  opaque: boolean,
  extra = "",
): string {
  const { w, h, rate: r } = ctx;
  const R = `${r.num}/${r.den}`;
  const fmt = opaque ? "yuv420p" : "yuva420p";
  const out = g.label("v");
  const tail = `format=${fmt},trim=end_frame=${n},setpts=PTS-STARTPTS${fades(c, o, n, ctx, opaque)}${extra}[${out}]`;
  const ref = c.ref;
  if (!isMediaRef(ref)) {
    if (ref.generator === "color") {
      g.lines.push(`color=c=0x${ref.color.slice(1)}:s=${w}x${h}:r=${R},${tail}`);
    } else {
      g.lines.push(
        `color=c=black@0:s=${w}x${h}:r=${R},format=yuva420p,${textFilter(g, ctx, c)},${tail}`,
      );
    }
    return out;
  }
  if (ref.still) {
    const k = g.input([], ref.media);
    const P = c.kenBurns ? PRESCALE : 1;
    let ch = picture(g, `[${k}:v]`, c, P * w, P * h);
    ch = c.kenBurns
      ? cont(ch, kenBurns(c, w, h, n, o, r))
      : cont(ch, `loop=loop=-1:size=1,setpts=N*${r.den}/${r.num}/TB`);
    g.lines.push(cont(ch, `tpad=stop=-1:stop_mode=clone,${tail}`));
    return out;
  }
  // A video: the frames it reads from the file, the ones it holds at either edge.
  const known = ref.frames ?? ctx.probes[ref.media]?.frames ?? undefined;
  const end = known ?? c.sourceRange.start + clipLength(c);
  const s = c.sourceRange.start + o;
  const padStart = Math.max(0, Math.min(n, -s));
  let s0 = Math.max(0, s);
  let read = n - padStart;
  if (s0 >= end) s0 = Math.max(0, end - 1);
  if (s0 + read > end) read = Math.max(1, end - s0);
  const held = n - padStart - read;
  if (padStart > 0)
    ctx.warn(`${c.id} holds its first frame for ${padStart} frames: the file has none before it`);
  if (held > 0 && o + n > clipLength(c))
    ctx.warn(
      known === undefined
        ? `${c.id} holds its last frame for ${held} frames: the file's length is not known (ffprobe)`
        : `${c.id} holds its last frame for ${held} frames: the file has none after it`,
    );
  const k = g.input(
    ["-ss", secOf(s0, r), "-t", num((read * r.den) / r.num + MARGIN, 4), "-an"],
    ref.media,
  );
  let ch = `[${k}:v]fps=${R},trim=end_frame=${read},setpts=PTS-STARTPTS`;
  if (padStart > 0) ch += `,tpad=start=${padStart}:start_mode=clone`;
  ch += ",tpad=stop=-1:stop_mode=clone";
  ch = picture(g, ch, c, w, h);
  if (c.kenBurns) ch = cont(ch, kenBurns(c, w, h, 1, o, r));
  g.lines.push(cont(ch, tail));
  return out;
}

/** How far (0..1) a transition has gone at overlay's frame `n` of this segment. */
const progress = (k: number, len: number) => `min(1,(n+${k})/${len})`;

function overlayOf(g: Graph, under: string, over: string, xy = ""): string {
  const out = g.label("o");
  g.lines.push(`[${under}][${over}]overlay=${xy}eof_action=pass:format=auto[${out}]`);
  return out;
}

function mixLayer(g: Graph, ctx: Ctx, cur: string, p: Piece, s: number, n: number): string {
  if (p.kind !== "mix") return cur;
  const { t, a, b } = p;
  const k = s - p.from;
  const len = p.to - p.from;
  const { w, h, rate: r } = ctx;
  const R = `${r.num}/${r.den}`;
  const sa = clipStream(g, ctx, a, s - a.start, n, false);
  if (t.kind === "dissolve") {
    const ks = secOf(k, r);
    const sb = clipStream(
      g,
      ctx,
      b,
      s - b.start,
      n,
      false,
      `,setpts=PTS+${ks}/TB,fade=t=in:st=0:d=${secOf(len, r)}:alpha=1,setpts=PTS-${ks}/TB`,
    );
    return overlayOf(g, overlayOf(g, cur, sa), sb);
  }
  const sb = clipStream(g, ctx, b, s - b.start, n, false);
  const P = progress(k, len);
  const pos: Record<"left" | "right" | "up" | "down", [string, string]> = {
    left: [`W*(1-${P})`, "0"],
    right: [`-W*(1-${P})`, "0"],
    up: ["0", `H*(1-${P})`],
    down: ["0", `-H*(1-${P})`],
  };
  const [kind, dir] = t.kind.split("_") as ["wipe" | "slide", keyof typeof pos];
  const [x, y] = pos[dir];
  const under = overlayOf(g, cur, sa);
  if (kind === "slide") return overlayOf(g, under, sb, `x='${x}':y='${y}':eval=frame:`);
  // A wipe: the next clip shows through a white rectangle sliding over a black mask.
  const m0 = g.label("m");
  const m1 = g.label("m");
  const mk = g.label("mk");
  const bm = g.label("bm");
  g.lines.push(`color=c=black:s=${w}x${h}:r=${R},format=gray,trim=end_frame=${n}[${m0}]`);
  g.lines.push(`color=c=white:s=${w}x${h}:r=${R},format=gray,trim=end_frame=${n}[${m1}]`);
  g.lines.push(
    `[${m0}][${m1}]overlay=x='${x}':y='${y}':eval=frame,format=gray,trim=end_frame=${n},setpts=PTS-STARTPTS[${mk}]`,
  );
  g.lines.push(`[${sb}][${mk}]alphamerge[${bm}]`);
  return overlayOf(g, under, bm);
}

function segmentStep(
  ctx: Ctx,
  start: number,
  n: number,
  layers: Piece[],
  burn: boolean,
  output: string[],
): RenderStep {
  const g = new Graph();
  const { w, h, rate: r } = ctx;
  const R = `${r.num}/${r.den}`;
  const rest = [...layers];
  let cur: string;
  if (rest[0] && isBase(rest[0], start, n)) {
    const p = rest.shift() as Extract<Piece, { kind: "clip" }>;
    cur = clipStream(g, ctx, p.clip, start - p.clip.start, n, true);
  } else {
    cur = g.label("k");
    g.lines.push(`color=c=black:s=${w}x${h}:r=${R},format=yuv420p,trim=end_frame=${n}[${cur}]`);
  }
  for (const p of rest) {
    if (p.kind === "mix") cur = mixLayer(g, ctx, cur, p, start, n);
    else cur = overlayOf(g, cur, clipStream(g, ctx, p.clip, start - p.clip.start, n, false));
  }
  let last = `[${cur}]`;
  if (burn) {
    const ass = captionsAss(
      ctx.doc.captions.segments,
      ctx.doc.captions,
      r,
      { width: w, height: h },
      start,
      start + n,
    );
    if (ass) {
      const file = contentFile(g.files, "ass", ass);
      last += `subtitles=filename=${file}:fontsdir=${filterPath(ctx.fontsDir)},`;
    }
  }
  g.lines.push(`${last}format=yuv420p[vout]`);
  const script = `${g.lines.join(";\n")}\n`;
  const out = ["-map", "[vout]", "-frames:v", String(n), ...output];
  const hash = stepHash(g.inputs, ctx.probes, script, g.files, out);
  return {
    name: `seg-${hash}.mp4`,
    hash,
    start,
    frames: n,
    inputs: g.inputs,
    script,
    files: g.files,
    output: out,
  };
}

function stepHash(
  inputs: RenderInput[],
  probes: Record<string, RenderProbe>,
  script: string,
  files: Record<string, string>,
  output: string[],
): string {
  const ins = inputs.map((i) => ({ ...i, fp: probes[i.media]?.fingerprint ?? null }));
  const sortedFiles = Object.keys(files)
    .sort()
    .map((k) => [k, files[k]]);
  return sha(
    JSON.stringify({ v: VIDEO_COMPILER_VERSION, ins, script, files: sortedFiles, output }),
  ).slice(0, 24);
}

// -------------------------------------------------------------------------------------------
// The sound

function audioStep(ctx: Ctx, total: number, loudnorm: boolean): RenderStep {
  const { doc, rate: r } = ctx;
  const g = new Graph();
  const trackOut = new Map<string, string>();
  const totalSamples = samplesOf(total, r);
  for (const id of lanes(doc, "Audio")) {
    const track = trackOf(doc, id);
    if (!track || track.muted) continue;
    const playing = doc.clips
      .filter(
        (c) =>
          c.track === id && c.enabled && isMediaRef(c.ref) && !c.ref.still && c.ref.audio !== false,
      )
      .sort((a, b) => a.start - b.start);
    if (!playing.length) continue;
    const trans = liveTransitions(doc, id, playing);
    const labels: string[] = [];
    for (const c of playing) {
      const ref = c.ref as Extract<VideoClip["ref"], { media: string }>;
      const known = ref.frames ?? ctx.probes[ref.media]?.frames ?? undefined;
      let st = c.start;
      let src = c.sourceRange.start;
      let len = clipLength(c);
      let fin = c.fadeIn;
      let fout = c.fadeOut;
      const into = trans.find((t) => t.to === c.id);
      const out = trans.find((t) => t.from === c.id);
      if (into?.kind === "dip_to_black") fin = Math.max(fin, into.outOffset);
      else if (into) {
        // A crossfade: this clip starts before its cut, as far as its file allows.
        const pre = Math.min(into.inOffset, src);
        if (pre < into.inOffset)
          ctx.warn(`${c.id}'s sound starts at the cut: the file has nothing before it`);
        st -= pre;
        src -= pre;
        len += pre;
        fin = Math.max(fin, pre + into.outOffset);
      }
      if (out?.kind === "dip_to_black") fout = Math.max(fout, out.inOffset);
      else if (out) {
        const room = known === undefined ? 0 : Math.max(0, known - (src + len));
        const post = Math.min(out.outOffset, room);
        if (post < out.outOffset)
          ctx.warn(`${c.id}'s sound ends at the cut: the file has nothing after it`);
        len += post;
        fout = Math.max(fout, out.inOffset + post);
      }
      const N = samplesOf(len, r);
      const nIn = Math.min(Math.max(AUDIO_EDGE, samplesOf(fin, r)), Math.floor(N / 2));
      const nOut = Math.min(Math.max(AUDIO_EDGE, samplesOf(fout, r)), Math.floor(N / 2));
      const k = g.input(
        ["-ss", secOf(src, r), "-t", num((len * r.den) / r.num + MARGIN, 4), "-vn"],
        ref.media,
      );
      const lbl = g.label("c");
      g.lines.push(
        `[${k}:a]aresample=${AUDIO_RATE},aformat=sample_fmts=fltp:channel_layouts=stereo,atrim=end_sample=${N},asetpts=PTS-STARTPTS,afade=t=in:ns=${nIn},afade=t=out:ss=${N - nOut}:ns=${nOut},volume=${num(c.volume, 1)}dB,adelay=delays=${samplesOf(st, r)}S:all=1[${lbl}]`,
      );
      labels.push(lbl);
    }
    const tl = `t${id}`;
    g.lines.push(
      labels.length === 1
        ? `[${labels[0]}]anull[${tl}]`
        : `${labels.map((l) => `[${l}]`).join("")}amix=inputs=${labels.length}:normalize=0:dropout_transition=0[${tl}]`,
    );
    trackOut.set(id, tl);
  }
  // Ducking: every track used as a voice is split, one copy per music track it lowers.
  const ducks = lanes(doc, "Audio")
    .map((id) => trackOf(doc, id))
    .filter((t) => !!t && trackOut.has(t.id) && !!t.duck)
    .map((t) => ({
      id: t?.id as string,
      duck: t?.duck as NonNullable<NonNullable<typeof t>["duck"]>,
      under: (t?.duck?.under ?? []).filter((u) => u !== t?.id && trackOut.has(u)),
    }))
    .filter((d) => d.under.length);
  const uses = new Map<string, string[]>();
  for (const id of trackOut.keys()) uses.set(id, []);
  for (const d of ducks) for (const u of d.under) uses.get(u)?.push(d.id);
  const finalOf = new Map<string, string>();
  const scOf = new Map<string, string[]>();
  for (const [id, lbl] of trackOut) {
    const users = uses.get(id) ?? [];
    if (!users.length) {
      finalOf.set(id, lbl);
      continue;
    }
    const outs = [`${lbl}m`, ...users.map((u) => `${lbl}s${u}`)];
    g.lines.push(`[${lbl}]asplit=${outs.length}${outs.map((o) => `[${o}]`).join("")}`);
    finalOf.set(id, outs[0] as string);
    users.forEach((u, i) => {
      scOf.set(u, [...(scOf.get(u) ?? []), outs[i + 1] as string]);
    });
  }
  for (const d of ducks) {
    const scs = scOf.get(d.id) ?? [];
    const sc = `sc${d.id}`;
    g.lines.push(
      scs.length === 1
        ? `[${scs[0]}]apad[${sc}]`
        : `${scs.map((l) => `[${l}]`).join("")}amix=inputs=${scs.length}:normalize=0:dropout_transition=0,apad[${sc}]`,
    );
    // A strong compressor keyed by the voice; `mix` sets how far the music goes down.
    const mix = 1 - 10 ** (d.duck.amountDb / 20);
    const attack = Math.min(2000, Math.max(0.01, d.duck.attackMs));
    const release = Math.min(9000, Math.max(0.01, d.duck.releaseMs));
    const music = finalOf.get(d.id) as string;
    const ducked = `d${d.id}`;
    g.lines.push(
      `[${music}][${sc}]sidechaincompress=threshold=0.003:ratio=20:attack=${num(attack, 2)}:release=${num(release, 2)}:makeup=1:mix=${num(mix, 4)},atrim=end_sample=${totalSamples}[${ducked}]`,
    );
    finalOf.set(d.id, ducked);
  }
  const finals = [...finalOf.values()];
  if (!finals.length)
    g.lines.push(`anullsrc=r=${AUDIO_RATE}:cl=stereo,atrim=end_sample=${totalSamples}[aout]`);
  else
    g.lines.push(
      `${finals.map((l) => `[${l}]`).join("")}${finals.length === 1 ? "anull" : `amix=inputs=${finals.length}:normalize=0:dropout_transition=0`},apad,atrim=end_sample=${totalSamples},aformat=sample_fmts=fltp:channel_layouts=stereo[aout]`,
    );
  const script = `${g.lines.join(";\n")}\n`;
  // With loudnorm the mix is lossless (FLAC), measured, then corrected into AAC (`render.ts`).
  const output = ["-map", "[aout]", ...(loudnorm ? ["-c:a", "flac"] : AAC_ARGS)];
  const hash = stepHash(g.inputs, ctx.probes, script, g.files, [...output, `ln=${loudnorm}`]);
  return {
    name: loudnorm ? `mix-${hash}.flac` : `audio-${hash}.m4a`,
    hash,
    start: 0,
    frames: total,
    inputs: g.inputs,
    script,
    files: g.files,
    output,
  };
}

// -------------------------------------------------------------------------------------------
// The plan

/**
 * The render of a timeline: segments, sound and captions. `probes` (by the media's path in
 * the project) give the files' lengths (handles for transitions, `cleanTimeline` for the rest)
 * and their fingerprints (the segments' hashes).
 */
export function compileVideo(
  raw: RgVideo,
  probes: Record<string, RenderProbe>,
  target: RenderTarget,
): RenderPlan {
  const doc = cleanTimeline(raw, probes);
  const warnings = new Set<string>();
  const { width: w, height: h } = outputSize(doc, target.height);
  const rate = doc.format.rate;
  const ctx: Ctx = {
    doc,
    rate,
    w,
    h,
    probes,
    fontsDir: target.fontsDir,
    dips: new Map(),
    warn: (s) => warnings.add(s),
  };
  if (doc.clips.some((c) => c.speed !== undefined && c.speed !== 1))
    warnings.add("speed is not rendered yet (3.10): those clips play at normal speed");

  const videoTracks = lanes(doc, "Video").filter((id) => !trackOf(doc, id)?.hidden);
  const audioTracks = lanes(doc, "Audio").filter((id) => !trackOf(doc, id)?.muted);
  const pieces = videoTracks.map((id) => trackPieces(ctx, id));
  let total = 0;
  for (const c of doc.clips)
    if (c.enabled && (videoTracks.includes(c.track) || audioTracks.includes(c.track)))
      total = Math.max(total, clipEnd(c));
  if (total <= 0) throw new EmptyTimeline();

  const from = target.span ? Math.max(0, Math.min(total - 1, Math.round(target.span.from))) : 0;
  const to = target.span ? Math.max(from + 1, Math.min(total, Math.round(target.span.to))) : total;
  const cuts = new Set<number>([from, to]);
  for (const list of pieces) for (const p of list) cuts.add(p.from).add(p.to);
  const bounds = [...cuts].filter((x) => x >= from && x <= to).sort((a, b) => a - b);

  const quality = target.quality ?? "good";
  const enc = encoderArgs(target.encoder, quality, rate);
  const hasCaptions = doc.captions.segments.some((c) => c.end > c.start && c.text.trim());
  const mode: RenderCaptions = !hasCaptions
    ? "none"
    : (target.captions ?? (doc.captions.burnIn ? "burn" : "track"));
  const segments: RenderStep[] = [];
  for (let i = 0; i + 1 < bounds.length; i++) {
    const a = bounds[i] as number;
    const b = bounds[i + 1] as number;
    const layers: Piece[] = [];
    for (const list of pieces) {
      const p = list.find((x) => x.from <= a && b <= x.to);
      if (p) layers.push(p);
    }
    segments.push(segmentStep(ctx, a, b - a, layers, mode === "burn", enc));
  }
  const loudness = target.loudnorm !== false;
  const audio = audioStep(ctx, total, loudness);
  return {
    width: w,
    height: h,
    rate,
    start: from,
    frames: to - from,
    seconds: ((to - from) * rate.den) / rate.num,
    segments,
    audio,
    loudness,
    captions: {
      mode,
      ...(hasCaptions && {
        srt: captionsToSrt(doc.captions.segments, rate),
        vtt: captionsToVtt(doc.captions.segments, rate),
      }),
      language: subtitleLanguage(doc.captions.language),
    },
    warnings: [...warnings],
  };
}

/** What loudnorm's first pass measured (its JSON). */
export interface LoudnormMeasure {
  input_i: string;
  input_tp: string;
  input_lra: string;
  input_thresh: string;
  target_offset: string;
}

/** A2, first pass: measure the mix (the JSON is at the end of what ffmpeg prints). */
export const loudnormMeasureArgs = (mix: string): string[] => [
  "-hide_banner",
  "-nostdin",
  "-i",
  mix,
  "-af",
  `${LOUDNORM}:print_format=json`,
  "-f",
  "null",
  "-",
];

/** The last JSON block loudnorm printed; undefined when there is none or the mix is silent. */
export function parseLoudnorm(text: string): LoudnormMeasure | undefined {
  const start = text.lastIndexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end < start) return undefined;
  try {
    const j = JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
    const keys = ["input_i", "input_tp", "input_lra", "input_thresh", "target_offset"] as const;
    const out: Record<string, string> = {};
    for (const k of keys) {
      const v = Number(j[k]);
      if (!Number.isFinite(v)) return undefined;
      out[k] = String(j[k]);
    }
    return out as unknown as LoudnormMeasure;
  } catch {
    return undefined;
  }
}

/** A2, second pass: the mix brought to −14 LUFS linearly (or only encoded, when silent). */
export function loudnormApplyArgs(
  mix: string,
  m: LoudnormMeasure | undefined,
  output: string,
): string[] {
  const af = m
    ? [
        "-af",
        `${LOUDNORM}:measured_I=${m.input_i}:measured_TP=${m.input_tp}:measured_LRA=${m.input_lra}:measured_thresh=${m.input_thresh}:offset=${m.target_offset}:linear=true,aresample=${AUDIO_RATE}`,
      ]
    : [];
  return ["-hide_banner", "-nostdin", "-y", "-i", mix, ...af, ...AAC_ARGS, output];
}

/** A step's whole command line: inputs (their files through `mediaPath`), graph, outputs. */
export function stepArgs(
  step: RenderStep,
  mediaPath: (media: string) => string,
  graphFile: string,
  output: string,
): string[] {
  return [
    "-hide_banner",
    "-nostdin",
    "-y",
    ...step.inputs.flatMap((i) => [...i.before, "-i", mediaPath(i.media)]),
    "-/filter_complex",
    graphFile,
    ...step.output,
    output,
  ];
}

/** The join: segments (a concat list) and sound, copied; the subtitles as a text track. */
export function joinArgs(
  plan: RenderPlan,
  list: string,
  audio: string,
  srt: string | undefined,
  output: string,
): string[] {
  const subs = plan.captions.mode === "track" && srt !== undefined;
  return [
    "-hide_banner",
    "-nostdin",
    "-y",
    "-f",
    "concat",
    "-safe",
    "0",
    "-i",
    list,
    // A span: the whole timeline's sound, from the span's first frame.
    ...(plan.start > 0 ? ["-ss", num((plan.start * plan.rate.den) / plan.rate.num)] : []),
    "-i",
    audio,
    ...(subs ? ["-i", srt] : []),
    "-map",
    "0:v",
    "-map",
    "1:a",
    ...(subs
      ? ["-map", "2:s", "-c:s", "mov_text", "-metadata:s:s:0", `language=${plan.captions.language}`]
      : []),
    "-c:v",
    "copy",
    "-c:a",
    "copy",
    "-map_metadata",
    "-1",
    "-write_tmcd",
    "0",
    "-movflags",
    "+faststart",
    "-t",
    num(plan.seconds),
    output,
  ];
}

/** A concat list's line for a file (an apostrophe in the path escaped as concat wants). */
export const concatLine = (path: string) => `file '${path.replace(/'/g, "'\\''")}'\n`;
