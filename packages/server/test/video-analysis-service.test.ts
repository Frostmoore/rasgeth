// G41.4: the analysis service with a fake runner (no ffmpeg, no whisper.cpp, no model): jobs with
// their steps and bar, the cache by fingerprint, one job for the same file asked twice,
// «Cancel» halfway leaving no half file, a transcription service over recorded HTTP.
import { existsSync } from "node:fs";
import { copyFile, mkdtemp, readdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { MediaAnalysis } from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import {
  mediaFingerprint,
  VideoAnalysis,
  type VideoTranscriber,
} from "../src/editor/video/analysis.js";
import { MediaRunError, type MediaRunner, type RunOptions } from "../src/editor/video/media-run.js";
import { Jobs } from "../src/jobs.js";

const FX = join(import.meta.dirname, "fixtures", "video");
const fixture = (name: string) => readFile(join(FX, name), "utf8");

interface Call {
  program: string;
  args: string[];
}

/** Plays ffprobe, ffmpeg and whisper-cli: writes what they would write. */
function fakeRunner(o: { hangOn?: (c: Call) => boolean; probe?: string } = {}) {
  const calls: Call[] = [];
  let release: (() => void) | undefined;
  const run: MediaRunner = async (program, args, opts: RunOptions = {}) => {
    const c = { program, args };
    calls.push(c);
    if (o.hangOn?.(c)) {
      // Writes half its output, then waits to be cancelled.
      const out = args.at(-1) ?? "";
      if (out.includes(".part.")) await writeFile(out, "half");
      await new Promise<void>((resolve, reject) => {
        release = resolve;
        opts.signal?.addEventListener("abort", () => {
          const e = new Error("cancelled");
          e.name = "AbortError";
          reject(e);
        });
      });
    }
    if (program === "ffprobe" && o.probe === "broken")
      throw new MediaRunError("ffprobe", 1, "clip.mp4: Invalid data found when processing input");
    if (program === "ffprobe")
      return { stdout: await fixture(o.probe ?? "probe-clip30.json"), stderr: "" };
    if (program === "whisper-cli") {
      for (const p of [10, 55, 100])
        opts.onStderrLine?.(`whisper_print_progress_callback: progress = ${p}%`);
      const base = args[args.indexOf("-of") + 1] ?? "";
      await writeFile(`${base}.json`, await fixture("whisper-cli-clip30.json"));
      return { stdout: "", stderr: "" };
    }
    if (args.some((a) => a.startsWith("silencedetect"))) {
      for (const l of (await fixture("silencedetect-clip30.txt")).split("\n"))
        opts.onStderrLine?.(l);
      return { stdout: "", stderr: "" };
    }
    // ffmpeg writing a file: the sound (16 kHz s16le), a proxy, a strip, a waveform.
    opts.onStdoutLine?.("out_time_us=15000000");
    const out = args.at(-1) ?? "";
    await writeFile(out, out.endsWith(".pcm") ? Buffer.alloc(30 * 32000) : `made by ${program}`);
    opts.onStdoutLine?.("out_time_us=30000000");
    opts.onStdoutLine?.("progress=end");
    return { stdout: "", stderr: "" };
  };
  return { run, calls, release: () => release?.() };
}

let dir: string;
let now = Date.parse("2026-11-16T10:00:00Z");
const clock = () => now;

beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-video-analysis-"));
  now = Date.parse("2026-11-16T10:00:00Z");
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

async function setup(
  o: {
    transcriber?: VideoTranscriber;
    hangOn?: (c: Call) => boolean;
    probe?: string;
    fetch?: typeof fetch;
  } = {},
) {
  const jobs = new Jobs(clock);
  const fake = fakeRunner({
    ...(o.hangOn && { hangOn: o.hangOn }),
    ...(o.probe && { probe: o.probe }),
  });
  const service = new VideoAnalysis({
    dataDir: join(dir, "data"),
    jobs,
    tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
    transcriber: async () => o.transcriber,
    language: () => "it",
    run: fake.run,
    threads: 2,
    ...(o.fetch && { fetch: o.fetch }),
  });
  const file = join(dir, "clip.mp4");
  await writeFile(file, Buffer.alloc(3 * 1024 * 1024, 7));
  return { jobs, fake, service, file };
}

const CLI: VideoTranscriber = { kind: "cli", program: "whisper-cli", model: "ggml.bin" };

describe("VideoAnalysis.analyze", () => {
  it("runs as a job: probe, sound, silences, words; the result is cached by fingerprint", async () => {
    const { jobs, fake, service, file } = await setup({ transcriber: CLI });
    const job = await service.analyze("u1", file, "media/clip.mp4");
    expect(job).toMatchObject({ kind: "video_analysis", vars: { name: "media/clip.mp4" } });
    const end = await jobs.settled(job.id);
    expect(end?.state).toBe("done");
    expect(end?.steps.map((s) => [s.id, s.state])).toEqual([
      ["tool_download", "skipped"],
      ["tool_unpack", "skipped"],
      ["video_probe", "done"],
      ["video_sound", "done"],
      ["video_silences", "done"],
      ["video_transcribe", "done"],
    ]);
    const a = end?.result as MediaAnalysis;
    expect(a.path).toBe("media/clip.mp4");
    expect(a.probe).toMatchObject({ kind: "video", duration: 30, audio: true });
    expect(a.transcript).toMatchObject({ engine: "whisper.cpp", timing: "word", language: "it" });
    expect(a.cuts.map((c) => c.where)).toEqual(["head", "mid", "tail"]);
    expect(a.speech).toMatchObject({ role: "A", source: "words" });
    expect(a.settings).toEqual({ minSec: 0.8, padding: 0.15, noiseDb: -35 });
    // whisper.cpp got the WAV, the language and DTW; the sound was read once.
    const whisper = fake.calls.find((c) => c.program === "whisper-cli");
    expect(whisper?.args).toEqual(
      expect.arrayContaining(["-l", "it", "-dtw", "large.v3.turbo", "-t", "2"]),
    );
    expect(fake.calls.map((c) => c.program)).toEqual([
      "ffprobe",
      "ffmpeg",
      "ffmpeg",
      "whisper-cli",
    ]);
    // Cached: probe, silences, transcript, analysis; the work folder is gone.
    const fp = await mediaFingerprint(file);
    const files = await readdir(service.dirOf(fp));
    expect(files.sort()).toEqual([
      "analysis--35-0.8-0.15-it-t.json",
      "probe.json",
      "silent--35-0.8.json",
      "transcript-it.json",
    ]);
    // Again, and on a copy with another name: nothing runs.
    const copy = join(dir, "renamed.mp4");
    await copyFile(file, copy);
    const again = await service.analysis("u1", copy, "other/renamed.mp4");
    expect(again.path).toBe("other/renamed.mp4");
    expect(again.cuts).toEqual(a.cuts);
    expect(fake.calls).toHaveLength(4);
    expect(await service.cached(copy)).toMatchObject({ fingerprint: fp });
  });

  it("other silence settings reuse the transcript; force recomputes", async () => {
    const { fake, service, file } = await setup({ transcriber: CLI });
    await service.analysis("u1", file, "clip.mp4");
    const wider = await service.analysis("u1", file, "clip.mp4", { settings: { padding: 0.3 } });
    expect(wider.settings.padding).toBe(0.3);
    expect(wider.cuts[1]?.start).toBeCloseTo((wider.transcript?.words[18]?.end ?? 0) + 0.3, 3);
    // Only the sound was read again (the probe, silences and transcript are cached).
    expect(fake.calls.map((c) => c.program)).toEqual([
      "ffprobe",
      "ffmpeg",
      "ffmpeg",
      "whisper-cli",
      "ffmpeg",
    ]);
    await service.analysis("u1", file, "clip.mp4", { force: true });
    expect(fake.calls.filter((c) => c.program === "whisper-cli")).toHaveLength(2);
  });

  it("the same file asked twice while it runs shares one job", async () => {
    const { jobs, fake, service, file } = await setup({
      transcriber: CLI,
      hangOn: (c) => c.program === "whisper-cli",
    });
    const a = await service.analyze("u1", file, "clip.mp4");
    const b = await service.analyze("u1", file, "clip.mp4");
    expect(b.id).toBe(a.id);
    while (!fake.calls.some((c) => c.program === "whisper-cli"))
      await new Promise((r) => setTimeout(r, 5));
    fake.release();
    expect((await jobs.settled(a.id))?.state).toBe("done");
  });

  it("«Cancel» while whisper.cpp runs: the job is cancelled and leaves nothing half done", async () => {
    const { jobs, fake, service, file } = await setup({
      transcriber: CLI,
      hangOn: (c) => c.program === "whisper-cli",
    });
    const job = await service.analyze("u1", file, "clip.mp4");
    while (!fake.calls.some((c) => c.program === "whisper-cli"))
      await new Promise((r) => setTimeout(r, 5));
    now += 3000;
    expect(jobs.cancel("u1", job.id)).toBe(true);
    const end = await jobs.settled(job.id);
    expect(end?.state).toBe("cancelled");
    const fp = await mediaFingerprint(file);
    const files = await readdir(service.dirOf(fp));
    // Probe and silences stay (whole files); no transcript, no analysis, no work folder.
    expect(files.sort()).toEqual(["probe.json", "silent--35-0.8.json"]);
    await expect(service.cached(file)).resolves.toBeUndefined();
  });

  it("without a transcription service: speech from the sound, no cuts", async () => {
    const { jobs, service, file } = await setup();
    const job = await service.analyze("u1", file, "clip.mp4");
    const end = await jobs.settled(job.id);
    const a = end?.result as MediaAnalysis;
    expect(end?.steps.find((s) => s.id === "video_transcribe")?.state).toBe("skipped");
    expect(a.transcript).toBeUndefined();
    expect(a.cuts).toEqual([]);
    expect(a.silent).toHaveLength(3);
    expect(a.speech).toMatchObject({ role: "A", source: "sound" });
  });

  it.each([["a picture", "probe-photo.json", "image"]])(
    "%s: no sound to read, always B",
    async (_, probe, kind) => {
      const { fake, service, file } = await setup({ transcriber: CLI, probe });
      const a = await service.analysis("u1", file, "photo.jpg");
      expect(a.probe.kind).toBe(kind);
      expect(a.speech).toMatchObject({ role: "B", source: "none", ratio: 0 });
      expect(fake.calls.map((c) => c.program)).toEqual(["ffprobe"]);
    },
  );

  it("a transcription service gets the WAV and answers with word times (recorded HTTP)", async () => {
    const seen: { url: string; body: FormData }[] = [];
    const f = (async (url: string | URL, init: RequestInit = {}) => {
      seen.push({ url: String(url), body: init.body as FormData });
      return Response.json({
        language: "italian",
        words: [
          { word: "Buongiorno", start: 2.05, end: 2.6 },
          { word: "a", start: 2.65, end: 2.7 },
          { word: "tutti.", start: 2.75, end: 3.1 },
          { word: "Dopo", start: 14.3, end: 14.6 },
        ],
      });
    }) as typeof fetch;
    const { service, file } = await setup({
      transcriber: {
        kind: "service",
        config: {
          api: "openai",
          url: "https://api.example/v1",
          model: "whisper-1",
          key: "k",
          name: "OpenAI",
        },
      },
      fetch: f,
    });
    const a = await service.analysis("u1", file, "clip.mp4");
    expect(seen).toHaveLength(1);
    const wav = seen[0]?.body.get("file") as File;
    // 30 s of 16 kHz mono 16-bit samples, with a WAV header.
    expect(wav.size).toBe(44 + 30 * 32000);
    expect(seen[0]?.body.get("language")).toBe("it");
    expect(a.transcript).toMatchObject({ engine: "OpenAI", timing: "word", language: "it" });
    expect(a.cuts.map((c) => [c.where, c.kind])).toEqual([
      ["head", "silence"],
      // 3.1 to 14.3 s without words but only 4.4 s of it quiet: something is heard there.
      ["mid", "long_pause"],
      ["tail", "silence"],
    ]);
  });
});

describe("VideoAnalysis errors the page can say", () => {
  it("a file ffprobe cannot read", async () => {
    const { jobs, service, file } = await setup({ probe: "broken" });
    const end = await jobs.settled((await service.analyze("u1", file, "clip.mp4")).id);
    expect(end).toMatchObject({ state: "failed", error: { code: "video_unreadable" } });
    expect(end?.error?.message).toContain("Invalid data");
  });

  it("a service that refuses the key: the voice notes' words, the job's code", async () => {
    const f = (async () => new Response("bad key", { status: 401 })) as unknown as typeof fetch;
    const { jobs, service, file } = await setup({
      transcriber: {
        kind: "service",
        config: { api: "openai", url: "https://x/v1", key: "k", name: "Groq" },
      },
      fetch: f,
    });
    const end = await jobs.settled((await service.analyze("u1", file, "clip.mp4")).id);
    expect(end).toMatchObject({
      state: "failed",
      error: { code: "video_transcribe", message: "Groq refused the key" },
    });
    // What was learnt before stays for the next try.
    const files = await readdir(service.dirOf(await mediaFingerprint(file)));
    expect(files.sort()).toEqual(["probe.json", "silent--35-0.8.json"]);
  });
});

describe("VideoAnalysis.derive", () => {
  it("proxy, strip (from the proxy) and waveform, each once", async () => {
    const { jobs, fake, service, file } = await setup();
    const job = await service.derive("u1", file, "clip.mp4", "proxy");
    expect(job.kind).toBe("video_proxy");
    const end = await jobs.settled(job.id);
    const proxy = end?.result as { path: string };
    expect(proxy.path.endsWith("proxy.mp4")).toBe(true);
    expect(await readFile(proxy.path, "utf8")).toBe("made by ffmpeg");
    const args = fake.calls.at(-1)?.args ?? [];
    expect(args).toEqual(expect.arrayContaining(["-crf", "28", "-g", "10", "-b:a", "96k"]));
    expect(args.at(-1)).toMatch(/proxy\.[0-9a-f]{8}\.part\.mp4$/);
    const strip = await service.derived("u1", file, "clip.mp4", "filmstrip");
    expect(strip.tiles).toBe(30);
    expect(fake.calls.at(-1)?.args).toContain(proxy.path);
    const wave = await service.derived("u1", file, "clip.mp4", "waveform");
    expect(wave.width).toBe(1200);
    const n = fake.calls.length;
    const again = await jobs.settled((await service.derive("u1", file, "clip.mp4", "proxy")).id);
    expect(again?.steps.find((s) => s.id === "video_derive")?.state).toBe("skipped");
    expect(fake.calls).toHaveLength(n);
  });

  it("«Cancel» halfway removes the half-written proxy", async () => {
    const { jobs, fake, service, file } = await setup({ hangOn: (c) => c.args.includes("-crf") });
    const job = await service.derive("u1", file, "clip.mp4", "proxy");
    while (!fake.calls.some((c) => c.args.includes("-crf")))
      await new Promise((r) => setTimeout(r, 5));
    const part = fake.calls.at(-1)?.args.at(-1) ?? "";
    while (!existsSync(part)) await new Promise((r) => setTimeout(r, 5));
    jobs.cancel("u1", job.id);
    expect((await jobs.settled(job.id))?.state).toBe("cancelled");
    expect(existsSync(part)).toBe(false);
    const fp = await mediaFingerprint(file);
    expect(existsSync(service.derivedPath(fp, "proxy"))).toBe(false);
  });

  it("a waveform of a file with no sound is a clear error", async () => {
    const { jobs, service, file } = await setup({ probe: "probe-photo.json" });
    const end = await jobs.settled((await service.derive("u1", file, "p.jpg", "waveform")).id);
    expect(end).toMatchObject({ state: "failed", error: { code: "video_no_sound" } });
  });
});
