// Runs a render plan (G41.3, `compile.ts`): every segment with its own ffmpeg (no shell, the
// graph from a file with `-/filter_complex`), the sound, then the join without re-encoding.
// Segments are named by their hash: with a cache folder an unchanged segment is not encoded
// again (the exact preview of G41.5a, a second render after a small edit). Nothing is left
// half-written: the output is written as `<out>.part.mp4` and renamed, the work folder goes.
// G41.6 wraps it in a job (`video_render`, the bar from `progress`, «Cancel» from `signal`).
import { copyFile, mkdir, mkdtemp, rename, rm, stat, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  concatLine,
  joinArgs,
  loudnormApplyArgs,
  loudnormMeasureArgs,
  parseLoudnorm,
  type RenderPlan,
  type RenderStep,
  stepArgs,
} from "./compile.js";
import { type MediaRunner, progressSeconds, runMedia } from "./media-run.js";

/** The server's fonts (p3.5.8, `packages/server/fonts`): Inter for texts and subtitles. */
export const RENDER_FONTS_DIR = fileURLToPath(new URL("../../../fonts/", import.meta.url));

/**
 * Runs ffmpeg in `cwd`; `onTime` gets the seconds written so far (from `-progress`). Resolves
 * with the end of what it printed (loudnorm's measure is there).
 */
export type FfmpegRun = (
  args: string[],
  o: { cwd: string; signal?: AbortSignal; onTime?: (seconds: number) => void },
) => Promise<string>;

/**
 * ffmpeg through `runMedia` (no shell, «Cancel» kills it), its progress read from
 * `-progress pipe:1`; resolves with the end of stderr (loudnorm's measure).
 */
export function ffmpegRunner(ffmpeg: string, run: MediaRunner = runMedia): FfmpegRun {
  return async (args, o) => {
    const r = await run(ffmpeg, ["-progress", "pipe:1", "-nostats", ...args], {
      cwd: o.cwd,
      ...(o.signal && { signal: o.signal }),
      onStdoutLine: (line) => {
        const t = progressSeconds(line);
        if (t !== undefined) o.onTime?.(t);
      },
    });
    return r.stderr;
  };
}

export interface RenderOptions {
  run: FfmpegRun;
  /** A project file's path on this machine. */
  mediaPath: (media: string) => string;
  /** Where the work folder is made (next to the output is best: same disk). */
  workDir: string;
  /** Encoded segments and sound kept by hash (G41.5a's cache); none: thrown away. */
  cacheDir?: string;
  /** The finished MP4. */
  out: string;
  signal?: AbortSignal;
  /** 0..1 and what is being done ("segment 3/12", "sound", "join"). */
  progress?: (fraction: number, step: string) => void;
}

export interface RenderResult {
  path: string;
  frames: number;
  seconds: number;
  segments: number;
  /** Segments taken from the cache instead of encoded. */
  reused: number;
  /** SRT and WebVTT written beside the video. */
  sidecars: string[];
  warnings: string[];
}

const exists = (p: string) =>
  stat(p).then(
    () => true,
    () => false,
  );

async function moveInto(from: string, to: string): Promise<void> {
  await mkdir(dirname(to), { recursive: true });
  try {
    await rename(from, to);
  } catch {
    await copyFile(from, to);
    await rm(from, { force: true });
  }
}

export async function renderVideo(plan: RenderPlan, options: RenderOptions): Promise<RenderResult> {
  // ffmpeg runs inside the work folder: every path it gets is absolute.
  const o = {
    ...options,
    workDir: resolve(options.workDir),
    out: resolve(options.out),
    ...(options.cacheDir && { cacheDir: resolve(options.cacheDir) }),
  };
  await mkdir(o.workDir, { recursive: true });
  const work = await mkdtemp(join(o.workDir, "render-"));
  const part = `${o.out}.part.mp4`;
  const weight = (s: RenderStep) => s.frames * (1 + 0.5 * s.inputs.length);
  const total =
    plan.segments.reduce((n, s) => n + weight(s), 0) + plan.frames * 0.3 + plan.frames * 0.05;
  let done = 0;
  const tell = (extra: number, step: string) =>
    o.progress?.(Math.min(1, (done + extra) / Math.max(1, total)), step);
  let reused = 0;

  /** One step: from the cache, or encoded in the work folder (and kept in the cache). */
  const runStep = async (
    s: RenderStep,
    label: string,
    w: number,
    seen: Map<string, string>,
    keep = true,
  ) => {
    const already = seen.get(s.hash);
    if (already) return already;
    const kept = o.cacheDir && keep ? join(o.cacheDir, s.name) : undefined;
    if (kept && (await exists(kept))) {
      reused++;
      seen.set(s.hash, kept);
      return kept;
    }
    for (const [name, content] of Object.entries(s.files))
      await writeFile(join(work, name), content);
    const graph = `${s.name}.graph`;
    await writeFile(join(work, graph), s.script);
    const tmp = s.name.replace(/(\.\w+)$/, ".part$1");
    const seconds = (s.frames * plan.rate.den) / plan.rate.num;
    await o.run(stepArgs(s, o.mediaPath, graph, tmp), {
      cwd: work,
      ...(o.signal && { signal: o.signal }),
      onTime: (t) => tell((w * Math.min(t, seconds)) / Math.max(seconds, 1e-6), label),
    });
    const dest = kept ?? join(work, s.name);
    await moveInto(join(work, tmp), dest);
    seen.set(s.hash, dest);
    return dest;
  };

  try {
    const seen = new Map<string, string>();
    const files: string[] = [];
    for (const [i, s] of plan.segments.entries()) {
      o.signal?.throwIfAborted();
      files.push(await runStep(s, `segment ${i + 1}/${plan.segments.length}`, weight(s), seen));
      done += weight(s);
      tell(0, `segment ${i + 1}/${plan.segments.length}`);
    }
    o.signal?.throwIfAborted();
    let audio: string;
    if (!plan.loudness) audio = await runStep(plan.audio, "sound", plan.frames * 0.3, seen);
    else {
      // A2: the mix (lossless, not kept), its loudness measured, then corrected into AAC.
      const name = `audio-${plan.audio.hash}.m4a`;
      const kept = o.cacheDir ? join(o.cacheDir, name) : undefined;
      if (kept && (await exists(kept))) {
        reused++;
        audio = kept;
      } else {
        const mix = await runStep(plan.audio, "sound", plan.frames * 0.2, seen, false);
        tell(plan.frames * 0.2, "loudness");
        const measured = parseLoudnorm(
          await o.run(loudnormMeasureArgs(mix), {
            cwd: work,
            ...(o.signal && { signal: o.signal }),
          }),
        );
        const tmp = "audio.part.m4a";
        await o.run(loudnormApplyArgs(mix, measured, tmp), {
          cwd: work,
          ...(o.signal && { signal: o.signal }),
        });
        audio = kept ?? join(work, name);
        await moveInto(join(work, tmp), audio);
      }
    }
    done += plan.frames * 0.3;
    tell(0, "join");
    await writeFile(join(work, "list.txt"), files.map(concatLine).join(""));
    let srt: string | undefined;
    if (plan.captions.mode === "track" && plan.captions.srt) {
      srt = "captions.srt";
      await writeFile(join(work, srt), plan.captions.srt);
    }
    await mkdir(dirname(o.out), { recursive: true });
    o.signal?.throwIfAborted();
    await o.run(joinArgs(plan, "list.txt", audio, srt, part), {
      cwd: work,
      ...(o.signal && { signal: o.signal }),
    });
    await rename(part, o.out);
    const sidecars: string[] = [];
    const base = o.out.replace(/\.[^./\\]+$/, "");
    if (plan.captions.srt) {
      await writeFile(`${base}.srt`, plan.captions.srt);
      sidecars.push(`${base}.srt`);
    }
    if (plan.captions.vtt) {
      await writeFile(`${base}.vtt`, plan.captions.vtt);
      sidecars.push(`${base}.vtt`);
    }
    o.progress?.(1, "done");
    return {
      path: o.out,
      frames: plan.frames,
      seconds: plan.seconds,
      segments: plan.segments.length,
      reused,
      sidecars,
      warnings: plan.warnings,
    };
  } finally {
    await rm(work, { recursive: true, force: true });
    await rm(part, { force: true });
  }
}
