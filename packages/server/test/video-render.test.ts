// The render's runner (G41.3) with a fake ffmpeg: graphs and texts written where ffmpeg reads
// them, segments kept by hash and reused, loudnorm in two passes, the join, SRT/VTT beside,
// nothing left half-written after a failure or a cancel, a bar that only goes forward.
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { isAbsolute, join } from "node:path";
import { newRgVideo, type RgVideo, type VideoClip } from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { compileVideo, type RenderPlan } from "../src/editor/video/compile.js";
import type { MediaRunner } from "../src/editor/video/media-run.js";
import { type FfmpegRun, ffmpegRunner, renderVideo } from "../src/editor/video/render.js";

const R = { num: 25, den: 1 };
const clip = (
  id: string,
  track: string,
  start: number,
  dur: number,
  media: string,
  more: Partial<VideoClip> = {},
): VideoClip => ({
  id,
  track,
  start,
  sourceRange: { start: 0, duration: dur },
  ref: { media },
  enabled: true,
  volume: 0,
  fadeIn: 0,
  fadeOut: 0,
  fit: "fill",
  ...more,
});

function timeline(): RgVideo {
  const d = newRgVideo({ width: 640, height: 360, rate: R, aspect: "16:9" });
  d.tracks.splice(1, 0, { id: "V2", kind: "Video", name: "V2", locked: false });
  d.clips = [
    clip("v1", "V1", 0, 50, "a.mp4"),
    clip("t", "V2", 10, 20, "", {
      ref: { generator: "text", text: "Ciao", style: "title", position: "center" },
    }),
    clip("a1", "A1", 0, 50, "a.mp4"),
  ];
  d.captions = {
    ...d.captions,
    burnIn: true,
    segments: [{ id: "s1", start: 0, end: 25, text: "Sotto" }],
  };
  return d;
}

const PROBES = { "a.mp4": { frames: 500, audio: true, fingerprint: "1" } };
const plan = (d = timeline()): RenderPlan =>
  compileVideo(d, PROBES, { encoder: "libx264", fontsDir: "/fonts", quality: "draft" });

let dir: string;
beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-video-render-"));
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

/** A fake ffmpeg: checks what it is given, writes its output, prints a loudnorm measure. */
function fake(opts: { failAt?: number; onCall?: () => void } = {}) {
  const calls: { args: string[]; cwd: string; graph?: string; files: string[] }[] = [];
  const run: FfmpegRun = async (args, o) => {
    opts.onCall?.();
    const gi = args.indexOf("-/filter_complex");
    const graph = gi >= 0 ? readFileSync(join(o.cwd, args[gi + 1] as string), "utf8") : undefined;
    calls.push({
      args,
      cwd: o.cwd,
      ...(graph !== undefined && { graph }),
      files: readdirSync(o.cwd),
    });
    if (opts.failAt === calls.length) throw new Error("ffmpeg failed (1): boom");
    o.onTime?.(0.5);
    o.onTime?.(1e9);
    if (args.includes("null"))
      return '{ "input_i" : "-20.0", "input_tp" : "-2.0", "input_lra" : "3.0", "input_thresh" : "-30.0", "target_offset" : "0.1" }';
    const out = args.at(-1) as string;
    await writeFile(isAbsolute(out) ? out : join(o.cwd, out), `out of call ${calls.length}`);
    return "";
  };
  return { run, calls };
}

describe("renderVideo", () => {
  it("segments, sound in two passes, the join; the cache makes the second render free", async () => {
    const p = plan();
    const f = fake();
    const bar: number[] = [];
    const out = join(dir, "renders", "film-v1.mp4");
    const res = await renderVideo(p, {
      run: f.run,
      mediaPath: (m) => `/progetto/${m}`,
      workDir: join(dir, "work"),
      cacheDir: join(dir, "cache"),
      out,
      progress: (x) => bar.push(x),
    });
    // three segments, the mix, the measure, the correction, the join
    expect(f.calls).toHaveLength(p.segments.length + 4);
    expect(p.segments).toHaveLength(3);
    for (const [i, s] of p.segments.entries()) {
      const c = f.calls[i];
      expect(c?.graph).toBe(s.script);
      // the texts and ASS files the graph reads are beside it
      for (const name of Object.keys(s.files)) expect(c?.files).toContain(name);
      expect(c?.args).toContain("/progetto/a.mp4");
    }
    const [mix, measure, correct, joined] = f.calls.slice(-4);
    expect(mix?.args.at(-1)).toMatch(/^mix-.*\.part\.flac$/);
    expect(measure?.args).toContain("null");
    expect(correct?.args.join(" ")).toContain("measured_I=-20.0");
    expect(joined?.args.slice(0, 9)).toEqual([
      "-hide_banner",
      "-nostdin",
      "-y",
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      "list.txt",
    ]);
    expect(joined?.args.at(-1)).toBe(`${out}.part.mp4`);
    expect(res).toMatchObject({ path: out, frames: 50, segments: 3, reused: 0 });
    expect(await readFile(out, "utf8")).toBe(`out of call ${f.calls.length}`);
    expect(res.sidecars).toEqual([
      join(dir, "renders", "film-v1.srt"),
      join(dir, "renders", "film-v1.vtt"),
    ]);
    expect(await readFile(join(dir, "renders", "film-v1.srt"), "utf8")).toContain("Sotto");
    // nothing left behind but the video, its captions and the cache
    expect(readdirSync(join(dir, "renders")).sort()).toEqual([
      "film-v1.mp4",
      "film-v1.srt",
      "film-v1.vtt",
    ]);
    expect(readdirSync(join(dir, "work"))).toEqual([]);
    expect(readdirSync(join(dir, "cache")).sort()).toEqual(
      [...p.segments.map((s) => s.name), `audio-${p.audio.hash}.m4a`].sort(),
    );
    // the bar only goes forward, and ends full
    expect(bar.every((x, i) => i === 0 || x >= (bar[i - 1] as number))).toBe(true);
    expect(bar.at(-1)).toBe(1);

    // again: only the join runs
    const again = fake();
    const res2 = await renderVideo(p, {
      run: again.run,
      mediaPath: (m) => m,
      workDir: join(dir, "work"),
      cacheDir: join(dir, "cache"),
      out: join(dir, "renders", "film-v2.mp4"),
    });
    expect(again.calls).toHaveLength(1);
    expect(res2.reused).toBe(4);
    // an edit on V2 encodes only the segments it touches
    const d = timeline();
    (d.clips[1] as VideoClip).fadeIn = 3;
    const third = fake();
    await renderVideo(plan(d), {
      run: third.run,
      mediaPath: (m) => m,
      workDir: join(dir, "work"),
      cacheDir: join(dir, "cache"),
      out: join(dir, "renders", "film-v3.mp4"),
    });
    expect(third.calls).toHaveLength(2);
  });

  it("the same segment twice in one plan is encoded once; without a cache nothing is kept", async () => {
    const d = newRgVideo({ width: 640, height: 360, rate: R, aspect: "16:9" });
    d.clips = [
      clip("c", "V1", 0, 20, "", { ref: { generator: "color", color: "#ff0000" } }),
      clip("x", "V1", 30, 20, "", { ref: { generator: "color", color: "#ff0000" } }),
    ];
    const p = compileVideo(d, {}, { encoder: "libx264", fontsDir: "/f", loudnorm: false });
    expect(p.segments.map((s) => s.frames)).toEqual([20, 10, 20]);
    expect(p.segments[0]?.hash).toBe(p.segments[2]?.hash);
    const f = fake();
    await renderVideo(p, {
      run: f.run,
      mediaPath: (m) => m,
      workDir: join(dir, "w"),
      out: join(dir, "o.mp4"),
    });
    // two distinct segments, the sound (no loudnorm: one pass), the join
    expect(f.calls).toHaveLength(4);
    const list = f.calls[3]?.files.includes("list.txt");
    expect(list).toBe(true);
    expect(readdirSync(dir).sort()).toEqual(["o.mp4", "w"]);
    expect(readdirSync(join(dir, "w"))).toEqual([]);
  });

  it("a failure halfway leaves no output and no work folder; the cache keeps what was done", async () => {
    const f = fake({ failAt: 2 });
    const out = join(dir, "out.mp4");
    await expect(
      renderVideo(plan(), {
        run: f.run,
        mediaPath: (m) => m,
        workDir: join(dir, "work"),
        cacheDir: join(dir, "cache"),
        out,
      }),
    ).rejects.toThrow("boom");
    expect(existsSync(out)).toBe(false);
    expect(existsSync(`${out}.part.mp4`)).toBe(false);
    expect(readdirSync(join(dir, "work"))).toEqual([]);
    expect(readdirSync(join(dir, "cache"))).toHaveLength(1);
  });

  it("cancelled: it stops before the next run and leaves nothing", async () => {
    const ac = new AbortController();
    const f = fake({ onCall: () => ac.abort() });
    const out = join(dir, "out.mp4");
    await mkdir(join(dir, "work"));
    await expect(
      renderVideo(plan(), {
        run: f.run,
        mediaPath: (m) => m,
        workDir: join(dir, "work"),
        out,
        signal: ac.signal,
      }),
    ).rejects.toThrow();
    expect(f.calls).toHaveLength(1);
    expect(existsSync(out)).toBe(false);
    expect(readdirSync(join(dir, "work"))).toEqual([]);
  });
});

describe("ffmpegRunner", () => {
  it("runs ffmpeg through runMedia: progress lines, cwd, signal, the end of stderr", async () => {
    const seen: { program: string; args: string[]; cwd?: string; signal?: AbortSignal }[] = [];
    const run: MediaRunner = async (program, args, o = {}) => {
      seen.push({
        program,
        args,
        ...(o.cwd && { cwd: o.cwd }),
        ...(o.signal && { signal: o.signal }),
      });
      for (const line of ["frame=1", "out_time_us=500000", "out_time_ms=1500000", "progress=end"])
        o.onStdoutLine?.(line);
      return { stdout: "", stderr: "measure" };
    };
    const signal = new AbortController().signal;
    const times: number[] = [];
    const out = await ffmpegRunner("/bin/ffmpeg", run)(["-i", "a.mp4", "b.mp4"], {
      cwd: "/work",
      signal,
      onTime: (t) => times.push(t),
    });
    expect(out).toBe("measure");
    expect(times).toEqual([0.5, 1.5]);
    expect(seen).toEqual([
      {
        program: "/bin/ffmpeg",
        args: ["-progress", "pipe:1", "-nostats", "-i", "a.mp4", "b.mp4"],
        cwd: "/work",
        signal,
      },
    ]);
  });

  it("a failure is runMedia's error", async () => {
    const run: MediaRunner = async () => {
      throw new Error("ffmpeg exited with 1: boom");
    };
    await expect(ffmpegRunner("ffmpeg", run)([], { cwd: "/w" })).rejects.toThrow("boom");
  });
});
