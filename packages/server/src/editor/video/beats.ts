// The music's beats (3.10, video part 2): «Taglia a ritmo» and the snapping need where the beats
// fall. Simple and local, no model: the sound as 11 025 Hz mono samples (ffmpeg), its energy
// every 256 samples, the rises of that energy as onsets; the tempo is the lag (60-180 BPM) at
// which the onsets repeat best, a little preferring tempos near 120; the phase is where a grid
// at that tempo meets the most onset; each beat of the grid then moves to the strongest onset
// near it (music is played, not quantized). Pure in `beatsOf`; `detectBeats` runs ffmpeg.
import { readFile, rm } from "node:fs/promises";
import { join } from "node:path";
import { type RgVideo, sourceUsed, type VideoClip } from "@redgiant/protocol";
import type { MediaRunner } from "./media-run.js";

export const BEATS_RATE = 11_025;
const HOP = 256;
const WIN = 1024;
const MIN_BPM = 60;
const MAX_BPM = 180;

export interface Beats {
  /** Beats a minute, one decimal. */
  bpm: number;
  /** Each beat, in seconds from the start of the sound given. */
  beats: number[];
}

/** The beats of mono samples (−1..1) at `rate`; none for a sound too short or flat. */
export function beatsOf(samples: Float32Array, rate = BEATS_RATE): Beats {
  const frames = Math.floor((samples.length - WIN) / HOP);
  if (frames < 16) return { bpm: 0, beats: [] };
  // The energy's rises, in a log scale (loud and soft music alike).
  const onset = new Float32Array(frames);
  let prev = 0;
  for (let i = 0; i < frames; i++) {
    let e = 0;
    const at = i * HOP;
    for (let k = 0; k < WIN; k++) {
      const v = samples[at + k] ?? 0;
      e += v * v;
    }
    const le = Math.log(1e-9 + e / WIN);
    onset[i] = i === 0 ? 0 : Math.max(0, le - prev);
    prev = le;
  }
  // Less than the average around it is no onset.
  const flat = new Float32Array(frames);
  const half = 16;
  for (let i = 0; i < frames; i++) {
    let sum = 0;
    let n = 0;
    for (let k = Math.max(0, i - half); k < Math.min(frames, i + half); k++) {
      sum += onset[k] ?? 0;
      n++;
    }
    flat[i] = Math.max(0, (onset[i] ?? 0) - sum / n);
  }
  const fps = rate / HOP;
  const lo = Math.max(2, Math.floor((60 * fps) / MAX_BPM));
  const hi = Math.min(frames - 1, Math.ceil((60 * fps) / MIN_BPM));
  if (hi <= lo) return { bpm: 0, beats: [] };
  // The tempo: the lag the onsets repeat at, weighted towards 120 BPM.
  const score = (lag: number) => {
    let s = 0;
    for (let i = lag; i < frames; i++) s += (flat[i] ?? 0) * (flat[i - lag] ?? 0);
    const bpm = (60 * fps) / lag;
    const w = Math.exp(-0.5 * (Math.log2(bpm / 120) / 0.9) ** 2);
    return (s / (frames - lag)) * w;
  };
  let best = lo;
  let bestScore = -1;
  const scores: number[] = [];
  for (let lag = lo; lag <= hi; lag++) {
    const s = score(lag);
    scores[lag] = s;
    if (s > bestScore) {
      bestScore = s;
      best = lag;
    }
  }
  if (bestScore <= 0) return { bpm: 0, beats: [] };
  // Half the lag repeating almost as well is the real beat (the slower one skips every other).
  const halfLag = Math.round(best / 2);
  if (halfLag >= lo && (scores[halfLag] ?? score(halfLag)) >= 0.5 * bestScore) {
    best = halfLag;
    bestScore = scores[halfLag] ?? score(halfLag);
  }
  // Between two lags: the peak of a parabola through the three around the best.
  const a = scores[best - 1] ?? bestScore;
  const c = scores[best + 1] ?? bestScore;
  const den = a - 2 * bestScore + c;
  const lag = den < 0 ? best + (0.5 * (a - c)) / den : best;
  // The phase: where a grid at that lag meets the most onset.
  let phase = 0;
  let phaseScore = -1;
  for (let p = 0; p < best; p++) {
    let s = 0;
    for (let t = p; t < frames; t += lag) s += flat[Math.round(t)] ?? 0;
    if (s > phaseScore) {
      phaseScore = s;
      phase = p;
    }
  }
  // Beat by beat: the next is expected a lag after the last one found, and moves to the strongest
  // onset within an eighth of a beat (music is played, not quantized; no drift builds up).
  const reach = Math.max(1, Math.round(lag / 8));
  const beats: number[] = [];
  for (let t = phase; t < frames; ) {
    const at = Math.round(t);
    let peak = at;
    for (let k = Math.max(0, at - reach); k <= Math.min(frames - 1, at + reach); k++)
      if ((flat[k] ?? 0) > (flat[peak] ?? 0)) peak = k;
    // A window's energy rises as the hit enters its end: the hit is about a window later.
    const sec = (peak * HOP + WIN - HOP / 2) / rate;
    if (!beats.length || sec - (beats[beats.length - 1] as number) > 0.15)
      beats.push(Math.round(sec * 1000) / 1000);
    // From the onset found when there was one, else from the grid.
    t = ((flat[peak] ?? 0) > 0 ? peak : t) + lag;
  }
  // The tempo told by the beats themselves (a straight line through them), finer than the lag.
  let period = lag / fps;
  if (beats.length >= 4) {
    const n = beats.length;
    const mx = (n - 1) / 2;
    const my = beats.reduce((x, y) => x + y, 0) / n;
    let sxy = 0;
    let sxx = 0;
    for (let i = 0; i < n; i++) {
      sxy += (i - mx) * ((beats[i] as number) - my);
      sxx += (i - mx) ** 2;
    }
    if (sxx > 0 && sxy > 0) period = sxy / sxx;
  }
  return { bpm: Math.round((60 / period) * 10) / 10, beats };
}

/** ffmpeg's arguments for `seconds` of sound from `start` as 11 025 Hz mono 16-bit samples. */
export function beatsPcmArgs(file: string, start: number, seconds: number, out: string): string[] {
  return [
    "-hide_banner",
    "-nostdin",
    "-y",
    "-ss",
    start.toFixed(3),
    "-t",
    seconds.toFixed(3),
    "-i",
    file,
    "-vn",
    "-ac",
    "1",
    "-ar",
    String(BEATS_RATE),
    "-f",
    "s16le",
    out,
  ];
}

/** The beats of a part of a file: its sound decoded by ffmpeg into `work`, read, removed. */
export async function detectBeats(
  run: MediaRunner,
  ffmpeg: string,
  file: string,
  start: number,
  seconds: number,
  work: string,
  signal?: AbortSignal,
): Promise<Beats> {
  const pcm = join(work, `beats-${process.pid}-${Date.now().toString(36)}.pcm`);
  try {
    await run(ffmpeg, beatsPcmArgs(file, start, seconds, pcm), signal ? { signal } : {});
    const raw = await readFile(pcm);
    const n = Math.floor(raw.length / 2);
    const samples = new Float32Array(n);
    for (let i = 0; i < n; i++) samples[i] = raw.readInt16LE(i * 2) / 32768;
    return beatsOf(samples);
  } finally {
    await rm(pcm, { force: true });
  }
}

/** The audio clip whose music gives the beats: the one named, else the longest on a ducked track, else the longest. */
export function musicClip(doc: RgVideo, id?: string): VideoClip | undefined {
  const audio = doc.clips.filter((c) => c.track.startsWith("A") && "media" in c.ref && c.enabled);
  if (id) return doc.clips.find((c) => c.id === id && "media" in c.ref);
  const ducked = new Set(doc.tracks.filter((t) => t.duck).map((t) => t.id));
  const longest = (list: VideoClip[]) =>
    list.sort((a, b) => b.sourceRange.duration - a.sourceRange.duration)[0];
  return longest(audio.filter((c) => ducked.has(c.track))) ?? longest(audio);
}

/**
 * The beats of an audio clip in timeline frames: the part of its file it plays (at its speed)
 * decoded and read, each beat placed where the clip plays it.
 */
export async function clipBeats(
  doc: RgVideo,
  clip: VideoClip,
  abs: string,
  run: MediaRunner,
  ffmpeg: string,
  work: string,
  signal?: AbortSignal,
): Promise<{ bpm: number; frames: number[] }> {
  const fps = doc.format.rate.num / doc.format.rate.den;
  const speed = clip.speed ?? 1;
  const r = await detectBeats(
    run,
    ffmpeg,
    abs,
    clip.sourceRange.start / fps,
    sourceUsed(clip) / fps,
    work,
    signal,
  );
  const end = clip.start + clip.sourceRange.duration;
  const frames = r.beats
    .map((sec) => clip.start + Math.round((sec * fps) / speed))
    .filter((f) => f >= clip.start && f < end);
  return { bpm: Math.round(r.bpm * speed * 10) / 10, frames };
}
