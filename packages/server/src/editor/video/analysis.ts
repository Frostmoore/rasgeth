// The analysis of a video project's files (G41.4): ffprobe's facts, the words with their times,
// the quiet stretches and the cuts they suggest, speech or coverage, and the files derived for
// the page (proxy, strip of frames, waveform). Everything is a cache of the file, kept by a
// fingerprint of its bytes in `<data>/cache/video/<fingerprint>/` (a renamed or copied file finds
// its cache again; an edited one gets a new one), never in the `.rgvideo` document. Long work
// runs as a job with its steps and bar, and «Cancel» kills the program and leaves no half file.
// The same file asked twice while it runs shares one job; whisper.cpp runs one file at a time.

import { createHash, randomUUID } from "node:crypto";
import { existsSync } from "node:fs";
import { mkdir, open, readFile, rename, rm, stat, writeFile } from "node:fs/promises";
import { cpus } from "node:os";
import { join } from "node:path";
import {
  type Job,
  type MediaAnalysis,
  type MediaDerived,
  type MediaProbe,
  type SilenceSettings,
  SilenceSettings as SilenceSettingsSchema,
  type TimeSpan,
  Transcript,
} from "@redgiant/protocol";
import { JobFailure, type JobHandle, type Jobs } from "../../jobs.js";
import type { TranscriptionConfig } from "../../voice.js";
import {
  filmstripArgs,
  filmstripTiles,
  pcmArgs,
  proxyArgs,
  waveformArgs,
  waveformWidth,
} from "./derived.js";
import { type MediaRunner, progressSeconds, runMedia } from "./media-run.js";
import { parseProbe, probeArgs } from "./probe.js";
import { parseSilenceDetect, silenceArgs, silenceCuts, soundSpans } from "./silences.js";
import { speechRatio } from "./speech.js";
import {
  CHUNK_SEC,
  chunkPoints,
  fromWhisperCliJson,
  joinTranscripts,
  pcmToWav,
  shiftTranscript,
  transcribeWords,
  whisperCliArgs,
  whisperProgress,
} from "./transcript.js";

/** Who turns the sound into words: whisper.cpp's program here, or a service. */
export type VideoTranscriber =
  | { kind: "cli"; program: string; model: string }
  | { kind: "service"; config: TranscriptionConfig };

export interface VideoTools {
  ffmpeg: string;
  ffprobe: string;
}

export interface VideoAnalysisOptions {
  dataDir: string;
  jobs: Jobs;
  /** ffmpeg and ffprobe, downloaded inside the job when missing (its `tool_*` steps). */
  tools: (owner: string, into: JobHandle) => Promise<VideoTools>;
  /** The transcription the person chose (Settings › Voice); undefined: none. */
  transcriber: () => Promise<VideoTranscriber | undefined>;
  /** The language spoken, when known (the agents' language). */
  language?: () => string | undefined;
  run?: MediaRunner;
  fetch?: typeof fetch;
  threads?: number;
}

export interface AnalyzeOptions {
  settings?: Partial<SilenceSettings>;
  language?: string;
  /** false: no transcript (speech from the sound's level only). */
  transcribe?: boolean;
  /** Recompute what is cached. */
  force?: boolean;
}

/** Bytes read at each end of a file for its fingerprint. */
const EDGE = 1024 * 1024;

const TOOL_STEPS = ["tool_download", "tool_unpack"];
export const ANALYSIS_STEPS = [
  ...TOOL_STEPS,
  "video_probe",
  "video_sound",
  "video_silences",
  "video_transcribe",
];
export const DERIVE_STEPS = [...TOOL_STEPS, "video_probe", "video_derive"];

/** A fingerprint of a file's bytes: its size and its first and last megabyte. */
export async function mediaFingerprint(file: string): Promise<string> {
  const f = await open(file, "r");
  try {
    const { size } = await f.stat();
    const h = createHash("sha256").update(`${size}\n`);
    const head = Buffer.alloc(Math.min(EDGE, size));
    await f.read(head, 0, head.length, 0);
    h.update(head);
    if (size > EDGE) {
      const tail = Buffer.alloc(Math.min(EDGE, size - EDGE));
      await f.read(tail, 0, tail.length, size - tail.length);
      h.update(tail);
    }
    return h.digest("hex").slice(0, 32);
  } finally {
    await f.close();
  }
}

async function writeAtomic(file: string, data: string | Uint8Array): Promise<void> {
  const part = `${file}.${randomUUID().slice(0, 8)}.part`;
  await writeFile(part, data);
  await rename(part, file);
}

async function readJson<T>(file: string): Promise<T | undefined> {
  try {
    return JSON.parse(await readFile(file, "utf8")) as T;
  } catch {
    return undefined;
  }
}

export class VideoAnalysis {
  private readonly run: MediaRunner;
  /** Jobs running by what they make (fingerprint + kind): asked again, the same job. */
  private readonly running = new Map<string, string>();
  /** whisper.cpp one file at a time: it takes every core. */
  private whisperQueue: Promise<unknown> = Promise.resolve();

  constructor(private readonly o: VideoAnalysisOptions) {
    this.run = o.run ?? runMedia;
  }

  get cacheRoot(): string {
    return join(this.o.dataDir, "cache", "video");
  }

  dirOf(fingerprint: string): string {
    return join(this.cacheRoot, fingerprint);
  }

  /** ffprobe's facts, from the cache when the file was seen before. */
  async probe(
    file: string,
    tools: VideoTools,
    fingerprint?: string,
    signal?: AbortSignal,
  ): Promise<MediaProbe> {
    const fp = fingerprint ?? (await mediaFingerprint(file));
    const cached = join(this.dirOf(fp), "probe.json");
    const hit = await readJson<MediaProbe>(cached);
    if (hit) return hit;
    const { size } = await stat(file);
    const r = await this.run(tools.ffprobe, probeArgs(file), {
      stdout: true,
      ...(signal && { signal }),
    });
    let json: unknown;
    try {
      json = JSON.parse(r.stdout);
    } catch {
      throw new JobFailure("video_unreadable", "ffprobe answered something unreadable");
    }
    const p = parseProbe(json, size);
    await mkdir(this.dirOf(fp), { recursive: true });
    await writeAtomic(cached, JSON.stringify(p));
    return p;
  }

  /** The analysis already in the cache, without starting anything. */
  async cached(file: string, o: AnalyzeOptions = {}): Promise<MediaAnalysis | undefined> {
    const fp = await mediaFingerprint(file);
    return readJson<MediaAnalysis>(join(this.dirOf(fp), this.analysisName(o)));
  }

  private analysisName(o: AnalyzeOptions): string {
    const s = SilenceSettingsSchema.parse(o.settings ?? {});
    const lang = o.language ?? this.o.language?.() ?? "";
    return `analysis-${s.noiseDb}-${s.minSec}-${s.padding}-${lang || "auto"}-${o.transcribe === false ? "nt" : "t"}.json`;
  }

  /**
   * Starts (or joins) the analysis of one file as a job (`video_analysis`); its result is the
   * `MediaAnalysis`. `name` is the file's path in the project, as the result tells it.
   */
  async analyze(owner: string, file: string, name: string, o: AnalyzeOptions = {}): Promise<Job> {
    const fp = await mediaFingerprint(file);
    const key = `${fp}:${this.analysisName(o)}`;
    const busy = this.running.get(key);
    const same = busy && this.o.jobs.get(owner, busy);
    if (same && same.state === "running") return same;
    const job = this.o.jobs.start(
      owner,
      "video_analysis",
      ANALYSIS_STEPS,
      (h) => this.analyzeIn(owner, h, file, name, fp, o).finally(() => this.running.delete(key)),
      { name },
    );
    this.running.set(key, job.id);
    return job;
  }

  /** `analyze` to its end: the result, or the job's error. */
  async analysis(
    owner: string,
    file: string,
    name: string,
    o: AnalyzeOptions = {},
  ): Promise<MediaAnalysis> {
    const job = await this.analyze(owner, file, name, o);
    return this.result<MediaAnalysis>(job);
  }

  private async result<T>(job: Job): Promise<T> {
    const end = await this.o.jobs.settled(job.id, 20);
    if (end?.state === "done") return end.result as T;
    if (end?.state === "cancelled") throw new JobFailure("cancelled", "The analysis was cancelled");
    throw new JobFailure(
      end?.error?.code ?? "video_failed",
      end?.error?.message ?? "The analysis failed",
    );
  }

  private async analyzeIn(
    owner: string,
    h: JobHandle,
    file: string,
    name: string,
    fp: string,
    o: AnalyzeOptions,
  ): Promise<MediaAnalysis> {
    const settings = SilenceSettingsSchema.parse(o.settings ?? {});
    const language = o.language ?? this.o.language?.() ?? "";
    const dir = this.dirOf(fp);
    const out = join(dir, this.analysisName(o));
    if (!o.force) {
      const hit = await readJson<MediaAnalysis>(out);
      if (hit) {
        for (const s of ANALYSIS_STEPS) h.skip(s);
        return { ...hit, path: name };
      }
    }
    const tools = await this.o.tools(owner, h);
    for (const s of TOOL_STEPS) h.skip(s);
    h.step("video_probe");
    const probe = await this.probe(file, tools, fp, h.signal);
    const duration = probe.duration ?? 0;
    const empty = (): MediaAnalysis => ({
      path: name,
      fingerprint: fp,
      probe,
      silent: [],
      cuts: [],
      speech: speechRatio(probe, { sound: [] }),
      settings,
    });
    if (!probe.audio || duration <= 0) {
      for (const s of ANALYSIS_STEPS) h.skip(s);
      const a = empty();
      await writeAtomic(out, JSON.stringify(a));
      return a;
    }
    await mkdir(dir, { recursive: true });
    const work = join(dir, `work-${randomUUID().slice(0, 8)}`);
    await mkdir(work, { recursive: true });
    try {
      // The sound, once, as 16 kHz mono samples: silencedetect and whisper read it fast.
      h.step("video_sound");
      const pcm = join(work, "sound.pcm");
      await this.ffmpeg(tools, pcmArgs(file, pcm), duration, h);
      h.step("video_silences");
      const silentFile = join(dir, `silent-${settings.noiseDb}-${settings.minSec}.json`);
      let silent = o.force ? undefined : await readJson<TimeSpan[]>(silentFile);
      if (!silent) {
        const lines: string[] = [];
        await this.run(
          tools.ffmpeg,
          [
            "-f",
            "s16le",
            "-ar",
            "16000",
            "-ac",
            "1",
            ...silenceArgs(pcm, settings.noiseDb, settings.minSec),
          ],
          {
            signal: h.signal,
            onStderrLine: (l) => {
              if (l.includes("silence_")) lines.push(l);
              const t = /time=(\d+):(\d+):([\d.]+)/.exec(l);
              if (t)
                h.progress(
                  pct(Number(t[1]) * 3600 + Number(t[2]) * 60 + Number(t[3]), duration),
                  100,
                );
            },
          },
        );
        silent = parseSilenceDetect(lines.join("\n"), duration);
        await writeAtomic(silentFile, JSON.stringify(silent));
      }
      const sound = soundSpans(silent, duration);
      let transcript: Transcript | undefined;
      const transcriber = o.transcribe === false ? undefined : await this.o.transcriber();
      if (transcriber) {
        h.step("video_transcribe");
        const tFile = join(dir, `transcript-${language || "auto"}.json`);
        transcript = o.force ? undefined : await readJson<Transcript>(tFile);
        if (!transcript) {
          transcript = await this.transcribe(
            transcriber,
            pcm,
            work,
            duration,
            silent,
            sound,
            language,
            h,
          );
          Transcript.parse(transcript);
          await writeAtomic(tFile, JSON.stringify(transcript));
        }
      } else h.skip("video_transcribe");
      const words = transcript?.words ?? [];
      const a: MediaAnalysis = {
        ...empty(),
        ...(transcript && { transcript }),
        silent,
        cuts: transcript
          ? silenceCuts(words, silent, duration, settings.minSec, settings.padding)
          : [],
        speech: transcript ? speechRatio(probe, { words }) : speechRatio(probe, { sound }),
      };
      await writeAtomic(out, JSON.stringify(a));
      return a;
    } finally {
      await rm(work, { recursive: true, force: true });
    }
  }

  private async ffmpeg(
    tools: VideoTools,
    args: string[],
    duration: number,
    h: JobHandle,
  ): Promise<void> {
    await this.run(tools.ffmpeg, args, {
      signal: h.signal,
      onStdoutLine: (l) => {
        const s = progressSeconds(l);
        if (s !== undefined) h.progress(pct(s, duration), 100);
      },
    });
  }

  private async transcribe(
    t: VideoTranscriber,
    pcm: string,
    work: string,
    duration: number,
    silent: TimeSpan[],
    sound: TimeSpan[],
    language: string,
    h: JobHandle,
  ): Promise<Transcript> {
    const samples = new Uint8Array(await readFile(pcm));
    if (t.kind === "cli") {
      const wav = join(work, "sound.wav");
      await writeFile(wav, pcmToWav(samples));
      const base = join(work, "words");
      const threads = this.o.threads ?? Math.max(1, Math.min(8, cpus().length - 1));
      const go = () =>
        this.run(
          t.program,
          whisperCliArgs({ model: t.model, wav, outBase: base, language, threads }),
          {
            signal: h.signal,
            onStderrLine: (l) => {
              const p = whisperProgress(l);
              if (p !== undefined) h.progress(p, 100);
            },
          },
        );
      // One whisper.cpp at a time; a cancelled wait does not hold the queue.
      const turn = this.whisperQueue.then(go, go);
      this.whisperQueue = turn.catch(() => undefined);
      await turn;
      const json = await readJson<unknown>(`${base}.json`);
      if (!json) throw new JobFailure("video_transcribe", "whisper.cpp wrote no transcript");
      return {
        ...fromWhisperCliJson(json, duration),
        engine: "whisper.cpp",
        model: "large-v3-turbo",
      };
    }
    // A service: pieces of at most ten minutes, cut in a quiet stretch.
    const points = [0, ...chunkPoints(duration, silent, CHUNK_SEC), duration];
    const parts: Transcript[] = [];
    for (let i = 0; i < points.length - 1; i++) {
      const from = points[i] as number;
      const to = points[i + 1] as number;
      const a = Math.floor(from * 16000) * 2;
      const b = Math.floor(to * 16000) * 2;
      const piece = await transcribeWords(pcmToWav(samples.subarray(a, b)), t.config, {
        duration: to - from,
        sound: sound
          .filter(([s, e]) => e > from && s < to)
          .map(([s, e]) => [Math.max(s, from) - from, Math.min(e, to) - from] as TimeSpan),
        ...(language && { language }),
        ...(this.o.fetch && { fetch: this.o.fetch }),
        signal: h.signal,
      });
      parts.push(shiftTranscript(piece, from));
      h.progress(pct(to, duration), 100);
    }
    return joinTranscripts(parts, duration);
  }

  /** Where a derived file is (or will be) for a fingerprint. */
  derivedPath(fingerprint: string, kind: MediaDerived): string {
    const ext = kind === "proxy" ? "mp4" : kind === "filmstrip" ? "jpg" : "png";
    return join(this.dirOf(fingerprint), `${kind}.${ext}`);
  }

  /**
   * Starts (or joins) making a derived file as a job (`video_<kind>`); its result is
   * `{ path, tiles? , width? }`. Already made: the job ends at once with it.
   */
  async derive(
    owner: string,
    file: string,
    name: string,
    kind: MediaDerived,
    force = false,
  ): Promise<Job> {
    const fp = await mediaFingerprint(file);
    const key = `${fp}:${kind}`;
    const busy = this.running.get(key);
    const same = busy && this.o.jobs.get(owner, busy);
    if (same && same.state === "running") return same;
    const job = this.o.jobs.start(
      owner,
      `video_${kind}`,
      DERIVE_STEPS,
      (h) => this.deriveIn(owner, h, file, fp, kind, force).finally(() => this.running.delete(key)),
      { name },
    );
    this.running.set(key, job.id);
    return job;
  }

  /** `derive` to its end. */
  async derived(
    owner: string,
    file: string,
    name: string,
    kind: MediaDerived,
  ): Promise<{ path: string; tiles?: number; width?: number }> {
    return this.result(await this.derive(owner, file, name, kind));
  }

  private async deriveIn(
    owner: string,
    h: JobHandle,
    file: string,
    fp: string,
    kind: MediaDerived,
    force: boolean,
  ): Promise<{ path: string; tiles?: number; width?: number }> {
    const dst = this.derivedPath(fp, kind);
    const tools = await this.o.tools(owner, h);
    for (const s of TOOL_STEPS) h.skip(s);
    h.step("video_probe");
    const probe = await this.probe(file, tools, fp, h.signal);
    const duration = probe.duration ?? 0;
    const info = {
      path: dst,
      ...(kind === "filmstrip" && { tiles: filmstripTiles(duration) }),
      ...(kind === "waveform" && { width: waveformWidth(duration) }),
    };
    if (!force && existsSync(dst)) {
      h.skip("video_derive");
      return info;
    }
    if (kind === "waveform" && !probe.audio)
      throw new JobFailure("video_no_sound", "This file has no sound to draw");
    if (kind !== "waveform" && probe.kind === "audio")
      throw new JobFailure("video_no_picture", "This file has no picture");
    h.step("video_derive");
    await mkdir(this.dirOf(fp), { recursive: true });
    // The extension stays last: ffmpeg and the cache both read it.
    const part = dst.replace(/(\.\w+)$/, `.${randomUUID().slice(0, 8)}.part$1`);
    try {
      // The strip reads the proxy when there is one: light, and every tenth frame a keyframe.
      const proxy = this.derivedPath(fp, "proxy");
      const args =
        kind === "proxy"
          ? proxyArgs(file, part, probe.audio)
          : kind === "filmstrip"
            ? filmstripArgs(existsSync(proxy) ? proxy : file, part, Math.max(duration, 0.1))
            : waveformArgs(file, part, duration);
      await this.ffmpeg(tools, args, duration, h);
      await rename(part, dst);
    } catch (e) {
      // Cancelled or failed: no half-written file stays.
      await rm(part, { force: true });
      throw e;
    }
    return info;
  }
}

function pct(done: number, total: number): number {
  if (!(total > 0)) return 0;
  return Math.max(0, Math.min(100, Math.round((done / total) * 1000) / 10));
}
