// The words of a clip with their times (G41.4), from the transcription RedGiant already has for
// voice notes (G20.2, 3.0, 3.7.3), the simplest way that gives word times:
// - whisper.cpp on this computer: its `whisper-cli` on the clip's WAV, with DTW token times
//   (`-dtw large.v3.turbo`, which needs `-nfa`) and the full JSON (`-ojf`); the voice notes'
//   server stays as it is. Tried on Severino (2026-11-16): DTW times within ~0.1 s of the sound,
//   the plain token times were off by seconds after a pause.
// - a service: OpenAI and Groq (`verbose_json` with word timestamps), ElevenLabs Scribe (words by
//   default), whisper-asr-webservice (`word_timestamps`), whisper.cpp's server (`verbose_json`,
//   token times); a model that answers only text (gpt-4o-transcribe, the Mac's whisper binding)
//   gets its words spread over the stretches with sound ("interpolated").
// Tokens are merged into words here: a token starting with a space starts a word, punctuation
// sticks to the word before without moving its times.

import type {
  TimeSpan,
  Transcript,
  TranscriptSegment,
  TranscriptTiming,
  TranscriptWord,
} from "@redgiant/protocol";
import {
  fetchVoiceError,
  httpVoiceError,
  type TranscriptionConfig,
  TranscriptionError,
} from "../../voice.js";

/** whisper.cpp's DTW preset for the model RedGiant downloads (`WHISPER_MODEL`). */
export const WHISPER_DTW = "large.v3.turbo";
/** A word's end when only its start is known (DTW gives one time per token). */
export const DTW_TAIL_SEC = 0.25;
/** The services' upload limit is 25 MB: 10 minutes of 16 kHz mono WAV (19.2 MB) per request. */
export const CHUNK_SEC = 600;

const round3 = (n: number) => Math.round(n * 1000) / 1000;

/** whisper-cli's arguments: DTW token times, the full JSON beside `outBase`, progress. */
export function whisperCliArgs(o: {
  model: string;
  wav: string;
  outBase: string;
  language?: string;
  threads: number;
}): string[] {
  return [
    "-m",
    o.model,
    "-f",
    o.wav,
    "-l",
    o.language || "auto",
    "-t",
    String(o.threads),
    "-dtw",
    WHISPER_DTW,
    // DTW does not work with flash attention.
    "-nfa",
    "-ojf",
    "-of",
    o.outBase,
    "-pp",
    "-np",
  ];
}

/** The percentage in one of whisper.cpp's progress lines. */
export function whisperProgress(line: string): number | undefined {
  const m = /progress\s*=\s*(\d+)%/.exec(line);
  return m ? Number(m[1]) : undefined;
}

interface Token {
  text: string;
  /** Seconds. */
  from: number;
  to: number;
  /** DTW time in seconds, when computed. */
  dtw?: number;
  p?: number;
}

const PUNCT = /^[\s.,;:!?…"'«»“”()[\]-]*$/;

/** whisper.cpp's tokens (one sentence) merged into words. */
function mergeTokens(tokens: readonly Token[], dtw: boolean): TranscriptWord[] {
  const groups: { text: string; tokens: Token[] }[] = [];
  for (const t of tokens) {
    if (/^\[_[A-Z]+_?\d*\]$/.test(t.text.trim()) || t.text.startsWith("[_")) continue;
    const last = groups.at(-1);
    const startsWord = /^\s/.test(t.text) || !last;
    if (!startsWord && last) {
      last.text += t.text;
      if (!PUNCT.test(t.text)) last.tokens.push(t);
    } else if (PUNCT.test(t.text) && last) {
      last.text += t.text.trim();
    } else groups.push({ text: t.text, tokens: PUNCT.test(t.text) ? [] : [t] });
  }
  const words: TranscriptWord[] = [];
  for (const g of groups) {
    const text = g.text.trim();
    const first = g.tokens[0];
    const last = g.tokens.at(-1);
    if (!text || !first || !last || PUNCT.test(text)) continue;
    const p = g.tokens.reduce((n, t) => n + (t.p ?? 1), 0) / g.tokens.length;
    if (dtw && first.dtw !== undefined && last.dtw !== undefined)
      words.push({ text, start: first.dtw, end: last.dtw + DTW_TAIL_SEC, p: round3(p) });
    else words.push({ text, start: first.from, end: Math.max(last.to, first.from), p: round3(p) });
  }
  // With DTW only starts are sure: a word ends at the latest where the next begins.
  if (dtw)
    for (let i = 0; i < words.length - 1; i++) {
      const w = words[i] as TranscriptWord;
      const next = words[i + 1] as TranscriptWord;
      w.end = Math.max(w.start + 0.02, Math.min(w.end, next.start));
    }
  return words.map((w) => ({ ...w, start: round3(w.start), end: round3(w.end) }));
}

type Raw = Record<string, unknown>;
const obj = (v: unknown): Raw =>
  v && typeof v === "object" && !Array.isArray(v) ? (v as Raw) : {};
const arr = (v: unknown): Raw[] => (Array.isArray(v) ? v.map(obj) : []);
const num = (v: unknown): number | undefined =>
  typeof v === "number" && Number.isFinite(v) ? v : undefined;

/** Sentences with their words, made into a transcript's words and segments. */
function assemble(
  sentences: { text: string; start: number; end: number; words: TranscriptWord[] }[],
) {
  const words: TranscriptWord[] = [];
  const segments: TranscriptSegment[] = [];
  for (const s of sentences) {
    const w0 = words.length;
    for (const w of s.words) if (w.text.trim()) words.push(w);
    const first = words[w0];
    const last = words.at(-1);
    if (words.length > w0 && first && last)
      segments.push({
        start: first.start,
        end: last.end,
        text: s.text.trim(),
        w0,
        w1: words.length - 1,
      });
  }
  return { words, segments };
}

/**
 * whisper-cli's full JSON (`-ojf`): `transcription[]` with `offsets` (ms) and `tokens[]` (`t_dtw`
 * in hundredths of a second, -1 when not computed).
 */
export function fromWhisperCliJson(json: unknown, duration: number): Omit<Transcript, "engine"> {
  const j = obj(json);
  const parts = arr(j.transcription);
  let anyDtw = false;
  const sentences = parts.map((s) => {
    const tokens: Token[] = arr(s.tokens).map((t) => {
      const off = obj(t.offsets);
      const d = num(t.t_dtw);
      if (d !== undefined && d >= 0) anyDtw = true;
      return {
        text: String(t.text ?? ""),
        from: (num(off.from) ?? 0) / 1000,
        to: (num(off.to) ?? 0) / 1000,
        ...(d !== undefined && d >= 0 && { dtw: d / 100 }),
        ...(num(t.p) !== undefined && { p: Math.max(0, Math.min(1, num(t.p) as number)) }),
      };
    });
    const off = obj(s.offsets);
    return {
      text: String(s.text ?? ""),
      from: (num(off.from) ?? 0) / 1000,
      to: (num(off.to) ?? 0) / 1000,
      tokens,
    };
  });
  const merged = sentences.map((s) => ({
    text: s.text,
    start: s.from,
    end: s.to,
    words: mergeTokens(s.tokens, anyDtw),
  }));
  return {
    language: String(obj(j.result).language ?? ""),
    timing: anyDtw ? "word" : "segment",
    duration,
    ...assemble(merged),
  };
}

/** whisper.cpp's server `verbose_json`: segments whose `words` are tokens (t_dtw when on). */
function fromWhisperServer(j: Raw, duration: number): Omit<Transcript, "engine"> {
  let anyDtw = false;
  const merged = arr(j.segments).map((s) => {
    const tokens: Token[] = arr(s.words).map((w) => {
      const d = num(w.t_dtw);
      if (d !== undefined && d >= 0) anyDtw = true;
      return {
        text: String(w.word ?? ""),
        from: num(w.start) ?? 0,
        to: num(w.end) ?? 0,
        ...(d !== undefined && d >= 0 && { dtw: d / 100 }),
        ...(num(w.probability) !== undefined && { p: num(w.probability) as number }),
      };
    });
    return { text: String(s.text ?? ""), start: num(s.start) ?? 0, end: num(s.end) ?? 0, tokens };
  });
  return {
    language: String(j.language ?? ""),
    // Token times without DTW are good to the sentence, not to the word.
    timing: anyDtw ? "word" : "segment",
    duration,
    ...assemble(
      merged.map((s) => ({
        text: s.text,
        start: s.start,
        end: s.end,
        words: mergeTokens(s.tokens, anyDtw),
      })),
    ),
  };
}

/** Words of a text spread over stretches of time, by their length. */
export function interpolateWords(text: string, spans: readonly TimeSpan[]): TranscriptWord[] {
  const tokens = text.split(/\s+/).filter(Boolean);
  const useful = spans.filter(([s, e]) => e > s);
  const total = useful.reduce((n, [s, e]) => n + (e - s), 0);
  if (!tokens.length || total <= 0) return [];
  const weights = tokens.map((t) => t.length + 1);
  const sum = weights.reduce((a, b) => a + b, 0);
  // Position along the stretches (seconds of sound) → time in the file.
  const at = (x: number): number => {
    let left = x;
    for (const [s, e] of useful) {
      if (left <= e - s) return s + left;
      left -= e - s;
    }
    return useful.at(-1)?.[1] ?? 0;
  };
  const out: TranscriptWord[] = [];
  let x = 0;
  tokens.forEach((t, i) => {
    const len = (total * (weights[i] ?? 1)) / sum;
    const a = at(x);
    // A word that would cross into the next stretch ends where its own does.
    let b = at(x + len * 0.9);
    const span = useful.find(([s, e]) => a >= s && a <= e);
    if (span && b > span[1]) b = span[1];
    out.push({ text: t, start: round3(a), end: round3(Math.max(b, a + 0.02)) });
    x += len;
  });
  return out;
}

/** Spread inside each sentence when a service gives sentence times but no word times. */
function segmentWords(
  segments: Raw[],
): { text: string; start: number; end: number; words: TranscriptWord[] }[] {
  return segments.map((s) => {
    const start = num(s.start) ?? 0;
    const end = num(s.end) ?? start;
    const text = String(s.text ?? "");
    return { text, start, end, words: interpolateWords(text, [[start, end]]) };
  });
}

/** Full names some services answer with ("italian") as their two letters. */
const LANGUAGE_NAMES: Record<string, string> = {
  italian: "it",
  english: "en",
  french: "fr",
  german: "de",
  spanish: "es",
  portuguese: "pt",
  dutch: "nl",
  ita: "it",
  eng: "en",
  fra: "fr",
  deu: "de",
  spa: "es",
  por: "pt",
  nld: "nl",
};
const lang = (v: unknown): string => {
  const s = typeof v === "string" ? v.trim().toLowerCase() : "";
  return LANGUAGE_NAMES[s] ?? s;
};

/**
 * A service's answer (any of the shapes above) as a transcript. `sound` are the stretches with
 * sound, for a plain-text answer.
 */
export function fromServiceAnswer(
  body: string,
  duration: number,
  sound: readonly TimeSpan[],
): Omit<Transcript, "engine"> {
  let j: Raw | undefined;
  if (body.trimStart().startsWith("{")) {
    try {
      j = obj(JSON.parse(body));
    } catch {
      j = undefined;
    }
  }
  if (!j) {
    const text = body.replace(/\s+/g, " ").trim();
    const words = interpolateWords(text, sound.length ? sound : [[0, duration]]);
    return {
      language: "",
      timing: "interpolated",
      duration,
      ...assemble([{ text, start: 0, end: duration, words }]),
    };
  }
  const segments = arr(j.segments);
  // whisper.cpp's server: token "words" with `t_dtw` or a `task` key and tokens.
  if (segments.some((s) => arr(s.words).some((w) => "t_dtw" in w)))
    return fromWhisperServer(j, duration);
  const language = lang(j.language ?? j.language_code);
  // OpenAI / Groq: top-level `words` [{word, start, end}].
  // ElevenLabs: top-level `words` [{text, start, end, type: word|spacing|audio_event}].
  const top = arr(j.words).filter((w) => w.type === undefined || w.type === "word");
  if (top.length) {
    const words: TranscriptWord[] = top
      .map((w) => ({
        text: String(w.word ?? w.text ?? "").trim(),
        start: round3(num(w.start) ?? 0),
        end: round3(num(w.end) ?? num(w.start) ?? 0),
        ...(num(w.probability) !== undefined && { p: num(w.probability) as number }),
      }))
      .filter((w) => w.text);
    // Sentences: the service's segments if any, otherwise split at full stops.
    const sentences = segments.length
      ? segments.map((s) => {
          const a = num(s.start) ?? 0;
          const b = num(s.end) ?? a;
          return {
            text: String(s.text ?? ""),
            start: a,
            end: b,
            words: words.filter((w) => w.start >= a - 0.01 && w.start < b + 0.01),
          };
        })
      : splitSentences(words);
    // A word no segment claims (rounding at the edges) must not be lost.
    const claimed = new Set(sentences.flatMap((s) => s.words));
    const loose = words.filter((w) => !claimed.has(w));
    const all = loose.length ? splitSentences(words) : sentences;
    return { language, timing: "word", duration, ...assemble(all) };
  }
  // whisper-asr-webservice: segments with their own `words`.
  if (segments.some((s) => arr(s.words).length)) {
    const sentences = segments.map((s) => ({
      text: String(s.text ?? ""),
      start: num(s.start) ?? 0,
      end: num(s.end) ?? 0,
      words: arr(s.words)
        .map((w) => ({
          text: String(w.word ?? w.text ?? "").trim(),
          start: round3(num(w.start) ?? 0),
          end: round3(num(w.end) ?? 0),
          ...(num(w.probability) !== undefined && { p: num(w.probability) as number }),
        }))
        .filter((w) => w.text),
    }));
    return { language, timing: "word", duration, ...assemble(sentences) };
  }
  if (segments.length)
    return { language, timing: "segment", duration, ...assemble(segmentWords(segments)) };
  const text = String(j.text ?? "")
    .replace(/\s+/g, " ")
    .trim();
  const words = interpolateWords(text, sound.length ? sound : [[0, duration]]);
  return {
    language,
    timing: "interpolated",
    duration,
    ...assemble([{ text, start: 0, end: duration, words }]),
  };
}

function splitSentences(words: TranscriptWord[]) {
  const out: { text: string; start: number; end: number; words: TranscriptWord[] }[] = [];
  let cur: TranscriptWord[] = [];
  const flush = () => {
    if (cur.length)
      out.push({
        text: cur.map((w) => w.text).join(" "),
        start: cur[0]?.start ?? 0,
        end: cur.at(-1)?.end ?? 0,
        words: cur,
      });
    cur = [];
  };
  for (const w of words) {
    cur.push(w);
    if (/[.!?…]$/.test(w.text)) flush();
  }
  flush();
  return out;
}

/** A 16 kHz mono 16-bit WAV around raw samples. */
export function pcmToWav(pcm: Uint8Array): Uint8Array {
  const n = pcm.length - (pcm.length % 2);
  const out = Buffer.alloc(44 + n);
  out.write("RIFF", 0);
  out.writeUInt32LE(36 + n, 4);
  out.write("WAVEfmt ", 8);
  out.writeUInt32LE(16, 16);
  out.writeUInt16LE(1, 20);
  out.writeUInt16LE(1, 22);
  out.writeUInt32LE(16000, 24);
  out.writeUInt32LE(32000, 28);
  out.writeUInt16LE(2, 32);
  out.writeUInt16LE(16, 34);
  out.write("data", 36);
  out.writeUInt32LE(n, 40);
  out.set(pcm.subarray(0, n), 44);
  return out;
}

/**
 * Where to split a long recording for the services: at most `max` seconds a piece, each cut in
 * the middle of the last quiet stretch before the limit (a hard cut when there is none).
 */
export function chunkPoints(
  duration: number,
  silent: readonly TimeSpan[],
  max = CHUNK_SEC,
): number[] {
  const cuts: number[] = [];
  let from = 0;
  while (duration - from > max) {
    const limit = from + max;
    const quiet = silent
      .filter(([s, e]) => e > from + max / 2 && s < limit)
      .map(([s, e]) => (Math.max(s, from) + Math.min(e, limit)) / 2)
      .at(-1);
    const at = round3(quiet ?? limit);
    cuts.push(at);
    from = at;
  }
  return cuts;
}

/** Times of a piece moved to where it is in the whole file. */
export function shiftTranscript<T extends Pick<Transcript, "words" | "segments">>(
  t: T,
  by: number,
  w0 = 0,
): T {
  return {
    ...t,
    words: t.words.map((w) => ({ ...w, start: round3(w.start + by), end: round3(w.end + by) })),
    segments: t.segments.map((s) => ({
      ...s,
      start: round3(s.start + by),
      end: round3(s.end + by),
      w0: s.w0 + w0,
      w1: s.w1 + w0,
    })),
  };
}

/**
 * One piece of a recording (a WAV) to a transcription service, asking for word times where the
 * service has them. Throws `TranscriptionError` as the voice notes do.
 */
export async function transcribeWords(
  wav: Uint8Array,
  cfg: TranscriptionConfig,
  o: {
    duration: number;
    /** Stretches with sound, for a plain-text answer. */
    sound: readonly TimeSpan[];
    language?: string;
    fetch?: typeof fetch;
    timeoutMs?: number;
    signal?: AbortSignal;
  },
): Promise<Transcript> {
  const name = cfg.name ?? (cfg.api === "local" ? "whisper.cpp" : "whisper");
  if (cfg.noKey || (cfg.api === "elevenlabs" && !cfg.key))
    throw new TranscriptionError(`${name} has no key yet`, "voice_no_key", { name }, 400);
  const file = new Blob([new Uint8Array(wav)], { type: "audio/wav" });
  const base = cfg.url.replace(/\/+$/, "");
  const body = new FormData();
  let url: string;
  if (cfg.api === "whisper-asr") {
    const q = new URLSearchParams({
      task: "transcribe",
      output: "json",
      encode: "true",
      word_timestamps: "true",
      vad_filter: "true",
      ...(o.language && { language: o.language }),
    });
    url = `${base}/asr?${q}`;
    body.set("audio_file", file, "clip.wav");
  } else if (cfg.api === "elevenlabs") {
    url = `${base}/speech-to-text`;
    body.set("file", file, "clip.wav");
    body.set("model_id", cfg.model ?? "scribe_v3");
    body.set("timestamps_granularity", "word");
    if (o.language) body.set("language_code", o.language);
  } else {
    url = `${base}/audio/transcriptions`;
    body.set("file", file, "clip.wav");
    body.set("model", cfg.model ?? "whisper-1");
    // The cloud's newer models answer only JSON (no times): `cfg.json` says so.
    body.set("response_format", cfg.json ? "json" : "verbose_json");
    if (!cfg.json) body.append("timestamp_granularities[]", "word");
    if (!cfg.json) body.append("timestamp_granularities[]", "segment");
    if (o.language && !cfg.noLanguage) body.set("language", o.language);
  }
  const headers: Record<string, string> = {};
  if (cfg.key && cfg.api === "elevenlabs") headers["xi-api-key"] = cfg.key;
  else if (cfg.key) headers.authorization = `Bearer ${cfg.key}`;
  const timeout = AbortSignal.timeout(o.timeoutMs ?? 10 * 60_000);
  let r: Response;
  try {
    r = await (o.fetch ?? fetch)(url, {
      method: "POST",
      body,
      headers,
      signal: o.signal ? AbortSignal.any([o.signal, timeout]) : timeout,
    });
  } catch (err) {
    if (o.signal?.aborted) throw err;
    throw fetchVoiceError(err as Error, name);
  }
  if (!r.ok) {
    const detail = (await r.text().catch(() => "")).slice(0, 200);
    throw httpVoiceError(r.status, name, detail);
  }
  const t = fromServiceAnswer(await r.text(), o.duration, o.sound);
  return {
    ...t,
    language: t.language || o.language || "",
    engine: name,
    ...(cfg.model && { model: cfg.model }),
  };
}

/** The pieces' transcripts as one (times already moved to the whole file). */
export function joinTranscripts(parts: readonly Transcript[], duration: number): Transcript {
  const words: TranscriptWord[] = [];
  const segments: TranscriptSegment[] = [];
  const order: TranscriptTiming[] = ["interpolated", "segment", "word"];
  let timing: TranscriptTiming = "word";
  for (const p of parts) {
    const s = shiftTranscript(p, 0, words.length);
    words.push(...s.words);
    segments.push(...s.segments);
    if (order.indexOf(p.timing) < order.indexOf(timing)) timing = p.timing;
  }
  const first = parts[0];
  return {
    language: parts.find((p) => p.language)?.language ?? "",
    engine: first?.engine ?? "",
    ...(first?.model && { model: first.model }),
    timing,
    duration,
    words,
    segments,
  };
}
