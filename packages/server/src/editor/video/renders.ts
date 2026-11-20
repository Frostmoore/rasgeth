// The render of a timeline on this machine (G41.6): the compiler of G41.3 and `renderVideo` as a
// job `video_render` with its bar (ffmpeg's `-progress`) and «Cancel» (ffmpeg stopped, nothing
// half-written left). One render at a time per project: a second one waits for its turn (step
// `video_wait`). The disk is checked first. The finished MP4 goes into the project as
// `renders/<name>-v<n>.mp4`, the highest version there plus one (montatore's T15), with its
// subtitles beside it. Segments are shared with the exact preview's cache: a render after a
// preview of the same stretch at the same size does not encode it again.

import { mkdir, readdir, statfs } from "node:fs/promises";
import { basename, join, posix } from "node:path";
import {
  type H264Encoder,
  isMediaRef,
  type Job,
  type RgVideo,
  setFormat,
  type VideoRenderAsk,
  type VideoRenderResult,
} from "@redgiant/protocol";
import { JobFailure, type JobHandle, type Jobs } from "../../jobs.js";
import { mediaFingerprint, type VideoAnalysis, type VideoTools } from "./analysis.js";
import { compileVideo, EmptyTimeline, lutFile, type RenderProbe, readLuts } from "./compile.js";
import type { MediaRunner } from "./media-run.js";
import { renderProbeOf } from "./probe.js";
import { type NodeMediaCall, REMOTE_RENDER_STEPS, renderOnNode } from "./remote-render.js";
import { ffmpegRunner, RENDER_FONTS_DIR, renderVideo } from "./render.js";

export const RENDER_STEPS = [
  "tool_download",
  "tool_unpack",
  "video_wait",
  "video_probe",
  "video_render",
  "video_save",
];

/** Bytes a render needs free: the segments and the finished file, with room to spare. */
export function renderSpace(seconds: number, width: number, height: number): number {
  const mbit = 12 * ((width * height) / (1920 * 1080));
  return Math.round(seconds * ((Math.max(1, mbit) * 1e6) / 8) * 2.2 + 200 * 1024 * 1024);
}

/** The next version's name in a folder: `<stem>-v<n>.mp4`, the highest there plus one. */
export function nextRenderName(stem: string, names: readonly string[]): string {
  const safe = stem.replace(/[\\/:*?"<>|]+/g, "_").trim() || "video";
  const re = new RegExp(`^${safe.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}-v(\\d+)\\.mp4$`, "i");
  const top = names.reduce((n, f) => Math.max(n, Number(re.exec(f)?.[1] ?? 0)), 0);
  return `${safe}-v${top + 1}.mp4`;
}

/** The output's height for a short side asked (never more than the timeline's). */
export function renderHeight(doc: Pick<RgVideo, "format">, short?: number): number | undefined {
  if (!short) return undefined;
  const { width, height } = doc.format;
  return Math.round((short * height) / Math.min(width, height) / 2) * 2;
}

export interface VideoRendersOptions {
  analysis: VideoAnalysis;
  jobs: Jobs;
  tools: (owner: string, into: JobHandle) => Promise<VideoTools>;
  run?: MediaRunner;
  fontsDir?: string;
  /** Free bytes where the render is written (tests). */
  free?: (dir: string) => Promise<number>;
  /** The encoder a render here uses (G41.7: NVENC when it really works; default libx264). */
  encoder?: () => Promise<H264Encoder>;
  /** G41.7: `media` requests to a node of this person. */
  node?: (owner: string, fingerprint: string) => NodeMediaCall;
}

export interface RenderRequest extends VideoRenderAsk {
  doc: RgVideo;
  /** The timeline's file name (the job's words). */
  name: string;
  /** One render at a time for the same key (the project). */
  queue: string;
  /** The project's folder on this machine, and the timeline's path in it. */
  root: string;
  path: string;
  mediaPath: (media: string) => Promise<string | undefined>;
  /** G41.7: made on this node instead of here (the person's choice). */
  node?: { fingerprint: string; name: string };
}

export class VideoRenders {
  /** Per project, the end of the last render started: the next one waits for it. */
  private readonly lanes = new Map<string, Promise<void>>();

  constructor(private readonly o: VideoRendersOptions) {}

  /** Whether a render runs or waits for this project. */
  busy(queue: string): boolean {
    return this.lanes.has(queue);
  }

  /** Starts a render: a job `video_render` whose result is a `VideoRenderResult`. */
  start(owner: string, r: RenderRequest): Job {
    const before = this.lanes.get(r.queue);
    let release = () => {};
    const mine = new Promise<void>((ok) => {
      release = ok;
    });
    this.lanes.set(r.queue, mine);
    const node = r.node;
    return this.o.jobs.start(
      owner,
      "video_render",
      node ? REMOTE_RENDER_STEPS : RENDER_STEPS,
      async (h) => {
        try {
          const tools = node ? undefined : await this.o.tools(owner, h);
          if (!node) for (const s of ["tool_download", "tool_unpack"]) h.skip(s);
          if (before) {
            h.step("video_wait");
            // The one before ends (done, failed or cancelled) before this one starts.
            await Promise.race([
              before,
              new Promise((_, no) =>
                h.signal.addEventListener("abort", () => no(h.signal.reason), { once: true }),
              ),
            ]);
            h.signal.throwIfAborted();
          } else h.skip("video_wait");
          if (node) return await this.renderThere(h, owner, node, r);
          return await this.renderIn(h, tools as VideoTools, r);
        } finally {
          release();
          if (this.lanes.get(r.queue) === mine) this.lanes.delete(r.queue);
        }
      },
      { name: r.name, ...(node && { node: node.name }) },
    );
  }

  /** G41.7: the same render on a node; the MP4 comes back into the project. */
  private async renderThere(
    h: JobHandle,
    owner: string,
    node: { fingerprint: string; name: string },
    r: RenderRequest,
  ): Promise<VideoRenderResult> {
    if (!this.o.node) throw new JobFailure("video_node", "Nodes are not available here");
    const doc =
      r.aspect && r.aspect !== r.doc.format.aspect ? setFormat(r.doc, { aspect: r.aspect }) : r.doc;
    const outDir = join(r.root, "renders");
    await mkdir(outDir, { recursive: true });
    const stem = basename(r.path).replace(/\.rgvideo$/i, "");
    const done = await renderOnNode(h, this.o.node(owner, node.fingerprint), {
      node,
      doc,
      ...(r.height && { height: renderHeight(doc, r.height) as number }),
      quality: r.quality ?? "good",
      mediaPath: r.mediaPath,
      out: async () => {
        const out = join(outDir, nextRenderName(stem, await readdir(outDir).catch(() => [])));
        // The disk here holds the video coming back.
        return out;
      },
    });
    const rel = (abs: string) => posix.join("renders", basename(abs));
    return {
      path: rel(done.path),
      sidecars: done.sidecars.map(rel),
      seconds: done.seconds,
      width: done.width,
      height: done.height,
      frames: done.frames,
      reused: done.reused,
      warnings: done.warnings,
      node: node.name,
      encoder: done.encoder,
    };
  }

  private async renderIn(
    h: JobHandle,
    tools: VideoTools,
    r: RenderRequest,
  ): Promise<VideoRenderResult> {
    h.step("video_probe");
    const doc =
      r.aspect && r.aspect !== r.doc.format.aspect ? setFormat(r.doc, { aspect: r.aspect }) : r.doc;
    const rate = doc.format.rate;
    const media = [...new Set(doc.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : [])))];
    const paths: Record<string, string> = {};
    const probes: Record<string, RenderProbe> = {};
    for (const [i, m] of media.entries()) {
      h.signal.throwIfAborted();
      const abs = await r.mediaPath(m);
      if (abs) {
        const fp = await mediaFingerprint(abs).catch(() => undefined);
        if (fp) {
          const p = await this.o.analysis.probe(abs, tools, fp, h.signal);
          paths[m] = abs;
          probes[m] = renderProbeOf(p, rate, fp);
        }
      }
      h.progress(i + 1, media.length);
    }
    const encoder = (await this.o.encoder?.().catch(() => undefined)) ?? "libx264";
    let plan: ReturnType<typeof compileVideo>;
    try {
      plan = compileVideo(doc, probes, {
        encoder,
        ...(r.height && { height: renderHeight(doc, r.height) as number }),
        quality: r.quality ?? "good",
        fontsDir: this.o.fontsDir ?? RENDER_FONTS_DIR,
        luts: await readLuts(doc, r.mediaPath, lutFile),
      });
    } catch (e) {
      if (e instanceof EmptyTimeline)
        throw new JobFailure("video_empty", "The timeline has nothing to play");
      throw e;
    }
    const outDir = join(r.root, "renders");
    await mkdir(outDir, { recursive: true });
    const need = renderSpace(plan.seconds, plan.width, plan.height);
    const free = await (this.o.free ?? diskFree)(outDir);
    if (free < need)
      throw new JobFailure(
        "video_disk",
        `Not enough free space: about ${Math.ceil(need / 1024 ** 2)} MB needed, ${Math.floor(free / 1024 ** 2)} MB free`,
      );
    h.step("video_render");
    const stem = basename(r.path).replace(/\.rgvideo$/i, "");
    const name = nextRenderName(stem, await readdir(outDir).catch(() => []));
    const out = join(outDir, name);
    const segments = join(this.o.analysis.cacheRoot, "segments");
    await mkdir(segments, { recursive: true });
    const done = await renderVideo(plan, {
      run: ffmpegRunner(tools.ffmpeg, this.o.run),
      mediaPath: (m) => paths[m] ?? m,
      workDir: join(this.o.analysis.cacheRoot, "work"),
      cacheDir: segments,
      out,
      signal: h.signal,
      progress: (f) => h.progress(Math.round(f * 1000) / 10, 100),
    });
    h.step("video_save");
    const rel = (abs: string) => posix.join("renders", basename(abs));
    return {
      path: rel(done.path),
      sidecars: done.sidecars.map(rel),
      seconds: done.seconds,
      width: plan.width,
      height: plan.height,
      frames: done.frames,
      reused: done.reused,
      warnings: done.warnings,
      encoder,
    };
  }
}

async function diskFree(dir: string): Promise<number> {
  const s = await statfs(dir).catch(() => undefined);
  return s ? s.bavail * s.bsize : Number.POSITIVE_INFINITY;
}
