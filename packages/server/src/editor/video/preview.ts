// The exact preview of a stretch of the timeline (G41.5a): the render of G41.3 at 360p with
// `ultrafast` (quality draft), only the segments of the stretch, made by ffmpeg as a job with its
// bar and «Cancel». Segments are kept by their hash in `<data>/cache/video/segments/` (a second
// look after a small edit encodes only what changed) and the finished previews in
// `<data>/cache/video/previews/<owner>/`; both are cleaned after every preview: the segments
// least recently used go first beyond a size, the previews beyond a count. The browser's own
// playback on the proxies (the page's player) stays the everyday preview.

import { createHash } from "node:crypto";
import { mkdir, readdir, rm, stat, utimes } from "node:fs/promises";
import { join } from "node:path";
import { isMediaRef, type Job, type RgVideo, type VideoPreviewResult } from "@redgiant/protocol";
import { JobFailure, type JobHandle, type Jobs } from "../../jobs.js";
import { mediaFingerprint, type VideoAnalysis, type VideoTools } from "./analysis.js";
import { compileVideo, EmptyTimeline, lutFile, type RenderProbe, readLuts } from "./compile.js";
import type { MediaRunner } from "./media-run.js";
import { renderProbeOf } from "./probe.js";
import { ffmpegRunner, RENDER_FONTS_DIR, renderVideo } from "./render.js";

/** The preview's height (never more than the timeline's). */
export const PREVIEW_HEIGHT = 360;
/** The longest stretch one exact preview renders. */
export const PREVIEW_MAX_SECONDS = 60;
/** The segments' cache is cleaned down to this size after every preview. */
export const SEGMENTS_MAX_BYTES = 2 * 1024 ** 3;
/** Finished previews kept per person. */
export const PREVIEWS_KEPT = 12;

export const PREVIEW_STEPS = ["tool_download", "tool_unpack", "video_probe", "video_render"];

export type PreviewResult = VideoPreviewResult;

/**
 * Cleans a cache folder: files least recently used (their modification time, touched when used)
 * are removed until the folder holds at most `maxBytes` and `maxFiles`; names in `keep` and
 * half-written `.part` files stay. Returns the names removed.
 */
export async function pruneCache(
  dir: string,
  o: { maxBytes?: number; maxFiles?: number; keep?: ReadonlySet<string> },
): Promise<string[]> {
  const names = await readdir(dir).catch(() => [] as string[]);
  const files: { name: string; size: number; at: number }[] = [];
  for (const name of names) {
    if (name.includes(".part")) continue;
    const st = await stat(join(dir, name)).catch(() => undefined);
    if (st?.isFile()) files.push({ name, size: st.size, at: st.mtimeMs });
  }
  let bytes = files.reduce((n, f) => n + f.size, 0);
  let count = files.length;
  const removed: string[] = [];
  for (const f of files.sort((a, b) => a.at - b.at || a.name.localeCompare(b.name))) {
    const over = (o.maxBytes !== undefined && bytes > o.maxBytes) || count > (o.maxFiles ?? count);
    if (!over) break;
    if (o.keep?.has(f.name)) continue;
    await rm(join(dir, f.name), { force: true });
    removed.push(f.name);
    bytes -= f.size;
    count--;
  }
  return removed;
}

export interface VideoPreviewsOptions {
  analysis: VideoAnalysis;
  jobs: Jobs;
  tools: (owner: string, into: JobHandle) => Promise<VideoTools>;
  run?: MediaRunner;
  fontsDir?: string;
  maxBytes?: number;
}

export class VideoPreviews {
  /** Running previews by what they make: asked again while it works, the same job. */
  private readonly running = new Map<string, string>();

  constructor(private readonly o: VideoPreviewsOptions) {}

  get segmentsDir(): string {
    return join(this.o.analysis.cacheRoot, "segments");
  }

  private previewsDir(owner: string): string {
    return join(
      this.o.analysis.cacheRoot,
      "previews",
      createHash("sha256").update(owner).digest("hex").slice(0, 16),
    );
  }

  /** Where a finished preview is; undefined for a name that is not one. */
  previewPath(owner: string, id: string): string | undefined {
    return /^[0-9a-f]{24}$/.test(id) ? join(this.previewsDir(owner), `${id}.mp4`) : undefined;
  }

  /**
   * Starts the exact preview of frames [from, to) of `doc` (at most `PREVIEW_MAX_SECONDS`):
   * a job `video_preview` whose result is a `PreviewResult`. `mediaPath` gives a project file's
   * path on this machine (undefined: missing, left out as the render does).
   */
  exact(
    owner: string,
    o: {
      doc: RgVideo;
      name: string;
      from: number;
      to: number;
      mediaPath: (media: string) => Promise<string | undefined>;
    },
  ): Job {
    const rate = o.doc.format.rate;
    const most = Math.round((PREVIEW_MAX_SECONDS * rate.num) / rate.den);
    const from = Math.max(0, Math.floor(o.from));
    const to = Math.max(from + 1, Math.min(Math.ceil(o.to), from + most));
    const key = createHash("sha256")
      .update(`${owner}\n${JSON.stringify(o.doc)}\n${from}-${to}`)
      .digest("hex");
    const busy = this.running.get(key);
    const same = busy && this.o.jobs.get(owner, busy);
    if (same && same.state === "running") return same;
    const job = this.o.jobs.start(
      owner,
      "video_preview",
      PREVIEW_STEPS,
      (h) => this.exactIn(owner, h, { ...o, from, to }).finally(() => this.running.delete(key)),
      { name: o.name },
    );
    this.running.set(key, job.id);
    return job;
  }

  private async exactIn(
    owner: string,
    h: JobHandle,
    o: {
      doc: RgVideo;
      from: number;
      to: number;
      mediaPath: (media: string) => Promise<string | undefined>;
    },
  ): Promise<PreviewResult> {
    const tools = await this.o.tools(owner, h);
    for (const s of ["tool_download", "tool_unpack"]) h.skip(s);
    h.step("video_probe");
    const rate = o.doc.format.rate;
    const media = [
      ...new Set(o.doc.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : []))),
    ];
    const paths: Record<string, string> = {};
    const probes: Record<string, RenderProbe> = {};
    for (const [i, m] of media.entries()) {
      h.signal.throwIfAborted();
      const abs = await o.mediaPath(m);
      if (abs) {
        const fp = await mediaFingerprint(abs);
        const p = await this.o.analysis.probe(abs, tools, fp, h.signal);
        paths[m] = abs;
        probes[m] = renderProbeOf(p, rate, fp);
      }
      h.progress(i + 1, media.length);
    }
    h.step("video_render");
    let plan: ReturnType<typeof compileVideo>;
    try {
      plan = compileVideo(o.doc, probes, {
        encoder: "libx264",
        height: PREVIEW_HEIGHT,
        quality: "draft",
        captions: o.doc.captions.burnIn ? "burn" : "none",
        fontsDir: this.o.fontsDir ?? RENDER_FONTS_DIR,
        span: { from: o.from, to: o.to },
        luts: await readLuts(o.doc, o.mediaPath, lutFile),
      });
    } catch (e) {
      if (e instanceof EmptyTimeline)
        throw new JobFailure("video_empty", "The timeline has nothing to play there");
      throw e;
    }
    const id = createHash("sha256")
      .update(
        JSON.stringify([
          plan.start,
          plan.frames,
          plan.width,
          plan.segments.map((s) => s.hash),
          plan.audio.hash,
        ]),
      )
      .digest("hex")
      .slice(0, 24);
    const dir = this.previewsDir(owner);
    const out = join(dir, `${id}.mp4`);
    const done = await stat(out).catch(() => undefined);
    if (!done) {
      await mkdir(this.segmentsDir, { recursive: true });
      await renderVideo(plan, {
        run: ffmpegRunner(tools.ffmpeg, this.o.run),
        mediaPath: (m) => paths[m] ?? m,
        workDir: join(this.o.analysis.cacheRoot, "work"),
        cacheDir: this.segmentsDir,
        out,
        signal: h.signal,
        progress: (f) => h.progress(Math.round(f * 1000) / 10, 100),
      });
      // The SRT/VTT the render writes beside a video are not needed here.
      await rm(out.replace(/\.mp4$/, ".srt"), { force: true });
      await rm(out.replace(/\.mp4$/, ".vtt"), { force: true });
    }
    // Used now: the newest in both caches, then the cleaning.
    const now = new Date();
    const used = new Set([...plan.segments.map((s) => s.name), `audio-${plan.audio.hash}.m4a`]);
    for (const name of [...used, plan.audio.name])
      await utimes(join(this.segmentsDir, name), now, now).catch(() => {});
    await utimes(out, now, now).catch(() => {});
    await pruneCache(this.segmentsDir, {
      maxBytes: this.o.maxBytes ?? SEGMENTS_MAX_BYTES,
      keep: used,
    });
    await pruneCache(dir, { maxFiles: PREVIEWS_KEPT, keep: new Set([`${id}.mp4`]) });
    return {
      id,
      start: plan.start,
      frames: plan.frames,
      seconds: plan.seconds,
      width: plan.width,
      height: plan.height,
      warnings: plan.warnings,
    };
  }
}
