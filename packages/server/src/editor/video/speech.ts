// Speech or coverage (G41.4): how much of a file is someone speaking, to propose it as an "A"
// clip (it carries the story) or a "B" one (it covers). montatore measured it with Silero VAD;
// here the transcript's words already say where speech is (whisper.cpp's own DTW times), and
// without a transcription service the sound's level from `silencedetect` stands in. montatore's
// thresholds: A when speech is at least 25% of the file and 3 seconds in all; a picture is always
// B; a choice made by hand is never overwritten.

import type { MediaProbe, SpeechInfo, TimeSpan, TranscriptWord } from "@redgiant/protocol";

/** montatore's `speech_ratio_min` and `speech_seconds_min`. */
export const SPEECH_RATIO_MIN = 0.25;
export const SPEECH_SECONDS_MIN = 3;
/** Words closer than this are one stretch of speech. */
export const SPEECH_JOIN_SEC = 0.5;
/** Shorter stretches are not speech (Silero's `min_speech_duration_ms` in montatore: 300). */
export const SPEECH_MIN_SEC = 0.3;

const round3 = (n: number) => Math.round(n * 1000) / 1000;

/** The stretches where words are said, joined across short gaps. */
export function speechSpans(
  words: readonly Pick<TranscriptWord, "start" | "end">[],
  join = SPEECH_JOIN_SEC,
  min = SPEECH_MIN_SEC,
): TimeSpan[] {
  const spans: TimeSpan[] = [];
  for (const w of [...words].sort((a, b) => a.start - b.start)) {
    const last = spans.at(-1);
    if (last && w.start - last[1] <= join) last[1] = Math.max(last[1], w.end);
    else spans.push([w.start, w.end]);
  }
  return spans.filter(([s, e]) => e - s >= min - 1e-9).map(([s, e]) => [round3(s), round3(e)]);
}

/** "A" or "B" for a file, from its speech (montatore's `RoleAssigner.proposeFor`). */
export function speechRole(kind: MediaProbe["kind"], ratio: number, seconds: number): "A" | "B" {
  if (kind !== "video") return "B";
  return ratio >= SPEECH_RATIO_MIN && seconds >= SPEECH_SECONDS_MIN ? "A" : "B";
}

/**
 * Speech or coverage of one file: from its words when there is a transcript, otherwise from the
 * stretches with sound (`sound`, louder than the silence level); a file without sound has none.
 */
export function speechRatio(
  probe: Pick<MediaProbe, "kind" | "duration" | "audio">,
  from:
    | { words: readonly Pick<TranscriptWord, "start" | "end">[] }
    | { sound: readonly TimeSpan[] },
): SpeechInfo {
  const duration = probe.duration ?? 0;
  if (!probe.audio || duration <= 0)
    return { ratio: 0, seconds: 0, segments: [], role: "B", source: "none" };
  const segments =
    "words" in from
      ? speechSpans(from.words)
      : from.sound
          .filter(([s, e]) => e - s >= SPEECH_MIN_SEC - 1e-9)
          .map(([s, e]) => [s, e] as TimeSpan);
  const seconds = round3(segments.reduce((n, [s, e]) => n + Math.max(0, e - s), 0));
  const ratio = Math.min(1, Math.round((seconds / duration) * 10_000) / 10_000);
  return {
    ratio,
    seconds,
    segments,
    role: speechRole(probe.kind, ratio, seconds),
    source: "words" in from ? "words" : "sound",
  };
}
