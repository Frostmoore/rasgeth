// What RedGiant learns about a media file of a video project (G41.4): ffprobe's facts, the words
// spoken with their times, the silences proposed as cuts, how much of it is speech (the "A" clips
// that carry the story, or the "B" coverage). All of it is a cache of the file (by a fingerprint
// of its bytes), outside the `.rgvideo` document: only what the person or an agent decides
// (cuts, captions) goes into the timeline. Times are seconds from the start of the file.
import { z } from "zod";

/** A rate as a fraction (29.97 = 30000/1001), as in the timeline. */
const Rate = z.object({ num: z.number().int().positive(), den: z.number().int().positive() });

/** ffprobe's answer, made into what the editor needs. */
export const MediaProbe = z.object({
  /** "image": a picture (no length, never a base under the others); "audio": sound only. */
  kind: z.enum(["video", "image", "audio"]),
  /** Seconds; null for a picture. */
  duration: z.number().nonnegative().nullable(),
  /** As shown (a phone's portrait clip rotated by 90 has its sides swapped). */
  width: z.number().int().nonnegative(),
  height: z.number().int().nonnegative(),
  /** Degrees, 0/90/180/270. */
  rotation: z.number().int(),
  /** The video's frame rate; null for a picture or sound. */
  rate: Rate.nullable(),
  codec: z.string().nullable(),
  audio: z.boolean(),
  audioCodec: z.string().nullable(),
  sampleRate: z.number().int().nullable(),
  channels: z.number().int().nullable(),
  /** The camera's start timecode ("01:02:03:04"), when it wrote one. */
  timecode: z.string().nullable(),
  /** When it was shot (ISO 8601, `creation_time`), when the file says. */
  createdAt: z.string().nullable(),
  /** Bytes. */
  size: z.number().int().nonnegative(),
});
export type MediaProbe = z.infer<typeof MediaProbe>;

/** One word, with its start and end in seconds and how sure the model was (0..1). */
export const TranscriptWord = z.object({
  text: z.string(),
  start: z.number().nonnegative(),
  end: z.number().nonnegative(),
  p: z.number().min(0).max(1).optional(),
});
export type TranscriptWord = z.infer<typeof TranscriptWord>;

/** A sentence as the model gave it: its words are `words[w0..w1]`. */
export const TranscriptSegment = z.object({
  start: z.number().nonnegative(),
  end: z.number().nonnegative(),
  text: z.string(),
  w0: z.number().int().nonnegative(),
  w1: z.number().int().nonnegative(),
});
export type TranscriptSegment = z.infer<typeof TranscriptSegment>;

/**
 * How precise the words' times are: "word" from the engine itself (whisper.cpp's DTW, the
 * cloud's word timestamps), "segment" spread inside the model's sentences, "interpolated" spread
 * over the parts with sound (a service that answers only text).
 */
export const TRANSCRIPT_TIMINGS = ["word", "segment", "interpolated"] as const;
export type TranscriptTiming = (typeof TRANSCRIPT_TIMINGS)[number];

export const Transcript = z.object({
  /** What the model heard ("it", "en"), or the language asked for; "" when not known. */
  language: z.string(),
  /** Who transcribed it: "whisper.cpp", "OpenAI", "ElevenLabs"… */
  engine: z.string(),
  model: z.string().optional(),
  timing: z.enum(TRANSCRIPT_TIMINGS),
  duration: z.number().nonnegative(),
  words: z.array(TranscriptWord),
  segments: z.array(TranscriptSegment),
});
export type Transcript = z.infer<typeof Transcript>;

/** A stretch of seconds [start, end]. */
export const TimeSpan = z.tuple([z.number(), z.number()]);
export type TimeSpan = z.infer<typeof TimeSpan>;

/**
 * A cut proposed between words: "silence" when ffmpeg finds the gap mostly quiet, "long_pause"
 * when nothing is said but something is heard (breath, "uhm", laughter), as in montatore.
 */
export const SilenceCut = z.object({
  start: z.number().nonnegative(),
  end: z.number().nonnegative(),
  kind: z.enum(["silence", "long_pause"]),
  /** Where the gap is: before the first word, between two, after the last. */
  where: z.enum(["head", "mid", "tail"]),
});
export type SilenceCut = z.infer<typeof SilenceCut>;

export const SilenceSettings = z.object({
  /** Shorter gaps are left alone (montatore: 0.8 s). */
  minSec: z.number().min(0.1).max(30).default(0.8),
  /** Kept around the words, so the attack and tail of a syllable stay (montatore: 0.15 s). */
  padding: z.number().min(0).max(2).default(0.15),
  /** Below this the sound counts as quiet (montatore: −35 dB). */
  noiseDb: z.number().min(-90).max(0).default(-35),
});
export type SilenceSettings = z.infer<typeof SilenceSettings>;

/** Speech or coverage: "A" carries the story (speech), "B" covers it. */
export const SpeechInfo = z.object({
  ratio: z.number().min(0).max(1),
  seconds: z.number().nonnegative(),
  segments: z.array(TimeSpan),
  role: z.enum(["A", "B"]),
  /** What the speech was measured from: the words, or (no transcription) the sound's level. */
  source: z.enum(["words", "sound", "none"]),
});
export type SpeechInfo = z.infer<typeof SpeechInfo>;

/** Everything `analyze` learns about one file (the `video analyze` action of G41.6). */
export const MediaAnalysis = z.object({
  path: z.string(),
  /** The cache's key: a fingerprint of the file's bytes. */
  fingerprint: z.string(),
  probe: MediaProbe,
  /** Absent: no sound, or no transcription service. */
  transcript: Transcript.optional(),
  /** Quiet stretches found by ffmpeg's `silencedetect`. */
  silent: z.array(TimeSpan),
  cuts: z.array(SilenceCut),
  speech: SpeechInfo,
  settings: SilenceSettings,
});
export type MediaAnalysis = z.infer<typeof MediaAnalysis>;

/** The derived files for playing and showing a clip in the page (G41.5a uses them). */
export const MEDIA_DERIVED = ["proxy", "filmstrip", "waveform"] as const;
export type MediaDerived = (typeof MEDIA_DERIVED)[number];
