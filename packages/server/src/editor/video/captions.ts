// Subtitles from the words (G41.4): lines of at most 42 characters, at most two to a subtitle,
// each on screen long enough to read; SRT and WebVTT written from the timeline's captions. The
// words of a timeline are the words of the sound it plays: they follow the *audio* clips, so with
// a J-cut or an L-cut (the sound starting before or ending after its picture) the subtitles stay
// with the voice.

import {
  framesToSeconds,
  type RgVideo,
  type Transcript,
  type TranscriptWord,
  type VideoCaptionWord,
} from "@redgiant/protocol";

export interface CaptionOptions {
  /** Characters in one line (the usual broadcast limit is 42). */
  maxChars?: number;
  /** Lines in one subtitle. */
  maxLines?: number;
  /** The shortest time on screen, in seconds (stretched into the gap after it). */
  minSec?: number;
  /** The longest one. */
  maxSec?: number;
  /** A pause this long between words starts a new subtitle. */
  gapSec?: number;
}

const DEFAULTS: Required<CaptionOptions> = {
  maxChars: 42,
  maxLines: 2,
  minSec: 1,
  maxSec: 7,
  gapSec: 0.8,
};

/** A subtitle in seconds, with the words it shows. */
export interface CaptionLine {
  start: number;
  end: number;
  /** Its lines joined by "\n". */
  text: string;
  words: TranscriptWord[];
}

/** Splits words into one line, or two (`maxLines` ≥ 2) as even as possible; null if they do not fit. */
export function breakLines(
  words: readonly string[],
  maxChars: number,
  maxLines: number,
): string[] | null {
  const all = words.join(" ");
  if (all.length <= maxChars) return [all];
  if (maxLines < 2) return null;
  // Two lines: the split point that keeps both under the limit with the most even lengths.
  let best: string[] | null = null;
  let score = Number.POSITIVE_INFINITY;
  for (let i = 1; i < words.length; i++) {
    const a = words.slice(0, i).join(" ");
    const b = words.slice(i).join(" ");
    if (a.length > maxChars) break;
    if (b.length > maxChars) continue;
    // Prefer a break after a comma or a full stop, then the most even.
    const punct = /[,;:.!?]$/.test(a) ? -8 : 0;
    const s = Math.abs(a.length - b.length) + punct;
    if (s < score) {
      score = s;
      best = [a, b];
    }
  }
  return best;
}

const ENDS_SENTENCE = /[.!?…]["»”']?$/;

/** The subtitles for a run of words (seconds), in order. */
export function captionLines(
  words0: readonly TranscriptWord[],
  options: CaptionOptions = {},
): CaptionLine[] {
  const o = { ...DEFAULTS, ...options };
  const words = words0.filter((w) => w.text.trim() !== "").sort((a, b) => a.start - b.start);
  const out: CaptionLine[] = [];
  let cur: TranscriptWord[] = [];
  /** Ends the subtitle; `upTo` keeps the words after it for the next one. */
  const flush = (upTo = cur.length) => {
    const rest = cur.slice(upTo);
    cur = cur.slice(0, upTo);
    const first = cur[0];
    const last = cur.at(-1);
    if (!first || !last) {
      cur = rest;
      return;
    }
    const lines = breakLines(
      cur.map((w) => w.text.trim()),
      o.maxChars,
      o.maxLines,
    ) ?? [cur.map((w) => w.text.trim()).join(" ")];
    out.push({
      start: first.start,
      end: Math.max(last.end, first.start),
      text: lines.join("\n"),
      words: cur,
    });
    cur = rest;
  };
  for (const w of words) {
    const prev = cur.at(-1);
    if (prev) {
      const texts = [...cur, w].map((x) => x.text.trim());
      const fits = breakLines(texts, o.maxChars, o.maxLines) !== null;
      const pause = w.start - prev.end >= o.gapSec;
      const long = w.end - (cur[0]?.start ?? w.start) > o.maxSec;
      const sentence = ENDS_SENTENCE.test(prev.text.trim()) && cur.length >= 2;
      if (!fits && !pause && !long && !sentence) {
        // Full: end at the last comma of its second half if there is one, the rest goes on.
        let at = -1;
        for (let i = cur.length - 1; i >= Math.ceil(cur.length / 2) - 1 && i >= 0; i--)
          if (/[,;:]$/.test(cur[i]?.text.trim() ?? "")) {
            at = i;
            break;
          }
        flush(at >= 0 && at < cur.length - 1 ? at + 1 : cur.length);
      } else if (!fits || pause || long || sentence) flush();
    }
    cur.push(w);
  }
  flush();
  // Long enough to read: stretched up to the next one's start.
  for (let i = 0; i < out.length; i++) {
    const c = out[i] as CaptionLine;
    const next = out[i + 1]?.start ?? Number.POSITIVE_INFINITY;
    if (c.end - c.start < o.minSec) c.end = Math.min(c.start + o.minSec, Math.max(c.end, next));
    c.start = round3(c.start);
    c.end = round3(c.end);
  }
  return out;
}

const round3 = (n: number) => Math.round(n * 1000) / 1000;

/** A word of the timeline: its frames there and the clip it is heard in. */
export interface TimelineWord {
  text: string;
  start: number;
  end: number;
  clip: string;
  p?: number;
}

/**
 * The words the timeline plays, in timeline frames: those of each enabled clip on an audible
 * audio track whose file has a transcript, inside the part of the file it plays. Video clips are
 * silent (their sound is the linked audio clip), so J-cuts and L-cuts carry the words with them.
 */
export function timelineWords(
  doc: Pick<RgVideo, "format" | "tracks" | "clips">,
  transcripts: Record<string, Pick<Transcript, "words">>,
): TimelineWord[] {
  const rate = doc.format.rate;
  const audible = new Set(
    doc.tracks.filter((t) => t.kind === "Audio" && !t.muted).map((t) => t.id),
  );
  const out: TimelineWord[] = [];
  for (const c of doc.clips) {
    if (!c.enabled || !audible.has(c.track) || !("media" in c.ref)) continue;
    const t = transcripts[c.ref.media];
    if (!t) continue;
    const from = c.sourceRange.start;
    const to = from + c.sourceRange.duration;
    for (const w of t.words) {
      const s = (w.start * rate.num) / rate.den;
      const e = (w.end * rate.num) / rate.den;
      const mid = (s + e) / 2;
      // A word belongs to the clip that plays its middle; cut at the clip's edges.
      if (mid < from || mid >= to) continue;
      const start = c.start + Math.round(Math.max(s, from) - from);
      const end = c.start + Math.round(Math.min(e, to) - from);
      out.push({
        text: w.text,
        start,
        end: Math.max(end, start + 1),
        clip: c.id,
        ...(w.p !== undefined && { p: w.p }),
      });
    }
  }
  return out.sort((a, b) => a.start - b.start || a.end - b.end);
}

/**
 * The timeline's subtitles from what it plays: `captionLines` on its words, back in frames,
 * ready for `setCaptionSegments`.
 */
export function captionsForTimeline(
  doc: Pick<RgVideo, "format" | "tracks" | "clips">,
  transcripts: Record<string, Pick<Transcript, "words">>,
  options: CaptionOptions = {},
): { start: number; end: number; text: string; words: VideoCaptionWord[] }[] {
  const rate = doc.format.rate;
  const sec = (f: number) => framesToSeconds(f, rate);
  const words = timelineWords(doc, transcripts).map((w) => ({
    text: w.text,
    start: sec(w.start),
    end: sec(w.end),
  }));
  const frame = (s: number) => Math.round((s * rate.num) / rate.den);
  return captionLines(words, options).map((c) => ({
    start: frame(c.start),
    end: Math.max(frame(c.end), frame(c.start) + 1),
    text: c.text,
    words: c.words.map((w) => ({ start: frame(w.start), end: frame(w.end), text: w.text })),
  }));
}

// SRT and WebVTT live in protocol (G41.5c: the page writes them too).
export { captionsToSrt, captionsToVtt } from "@redgiant/protocol";
