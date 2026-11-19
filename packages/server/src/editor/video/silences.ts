// Silences and long pauses to propose as cuts (G41.4), a port of montatore's silences.py. Two
// sources, crossed: the gaps between the transcript's words decide *where* to cut; ffmpeg's
// `silencedetect` (where the sound really is below a level) decides the *kind*: a gap mostly
// quiet is a "silence", a gap with no words but some sound (breath, "uhm", laughter) a
// "long_pause". Each cut keeps a margin (`padding`) next to the words, so the attack and tail of
// a syllable are not eaten; the start and the end of the file are cut flush.

import type { SilenceCut, TimeSpan, TranscriptWord } from "@redgiant/protocol";

/** Below this length, after the margin, a cut is not worth it. */
export const MIN_CUT = 0.3;
/** The share of a gap `silencedetect` must cover to call it a "silence". */
export const SILENCE_SHARE = 0.5;

/** `silencedetect` on the first audio stream; half the shortest gap, as montatore. */
export function silenceArgs(file: string, noiseDb: number, minSec: number): string[] {
  return [
    "-hide_banner",
    "-nostdin",
    "-i",
    file,
    "-map",
    "0:a:0",
    "-af",
    `silencedetect=noise=${noiseDb}dB:d=${(minSec / 2).toFixed(3)}`,
    "-f",
    "null",
    "-",
  ];
}

/** The quiet stretches in what `silencedetect` wrote; one still open runs to `duration`. */
export function parseSilenceDetect(stderr: string, duration: number): TimeSpan[] {
  const out: TimeSpan[] = [];
  let start: number | undefined;
  for (const line of stderr.split(/\r?\n/)) {
    const s = /silence_start: (-?[\d.]+)/.exec(line);
    const e = /silence_end: (-?[\d.]+)/.exec(line);
    if (s) start = Math.max(0, Number(s[1]));
    else if (e && start !== undefined) {
      out.push([round3(start), round3(Math.min(Number(e[1]), duration || Number(e[1])))]);
      start = undefined;
    }
  }
  if (start !== undefined && duration > start) out.push([round3(start), round3(duration)]);
  return out;
}

const round3 = (n: number) => Math.round(n * 1000) / 1000;

function overlap(a: TimeSpan, spans: readonly TimeSpan[]): number {
  let sum = 0;
  for (const [s, e] of spans) sum += Math.max(0, Math.min(a[1], e) - Math.max(a[0], s));
  return sum;
}

/**
 * The cuts proposed from the words' times and the quiet stretches (montatore's `compute_cuts`):
 * gaps shorter than `minSec` stay; the head and tail are cut flush with the file, the gaps in
 * the middle keep `padding` on both sides; a cut shorter than `MIN_CUT` after that is dropped.
 */
export function silenceCuts(
  words: readonly Pick<TranscriptWord, "start" | "end">[],
  silent: readonly TimeSpan[],
  duration: number,
  minSec: number,
  padding: number,
): SilenceCut[] {
  const first = words[0];
  const last = words.at(-1);
  if (!first || !last) return [];
  const gaps: [number, number, SilenceCut["where"]][] = [[0, first.start, "head"]];
  for (let i = 1; i < words.length; i++)
    gaps.push([words[i - 1]?.end ?? 0, words[i]?.start ?? 0, "mid"]);
  gaps.push([last.end, duration, "tail"]);
  const cuts: SilenceCut[] = [];
  for (const [start, end, where] of gaps) {
    // A small tolerance: 0.8 written as 1.0 − 0.2 is 0.7999…
    if (end - start < minSec - 1e-9) continue;
    const cutStart = where === "head" ? start : start + padding;
    const cutEnd = where === "tail" ? end : end - padding;
    if (cutEnd - cutStart < MIN_CUT - 1e-9) continue;
    const share = overlap([start, end], silent) / (end - start);
    cuts.push({
      start: round3(cutStart),
      end: round3(cutEnd),
      kind: share >= SILENCE_SHARE ? "silence" : "long_pause",
      where,
    });
  }
  return cuts;
}

/** The stretches with sound: the complement of the quiet ones inside [0, duration]. */
export function soundSpans(silent: readonly TimeSpan[], duration: number): TimeSpan[] {
  const out: TimeSpan[] = [];
  let at = 0;
  for (const [s, e] of [...silent].sort((a, b) => a[0] - b[0])) {
    if (s > at) out.push([round3(at), round3(Math.min(s, duration))]);
    at = Math.max(at, e);
  }
  if (duration > at) out.push([round3(at), round3(duration)]);
  return out.filter(([s, e]) => e > s);
}
