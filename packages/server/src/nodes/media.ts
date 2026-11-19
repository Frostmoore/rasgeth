// What a node does to render video for another machine (G41.7, the `media` operation): checked by
// `nodeMedia` («use» is enough, with or without a container: R1), then everything happens in one
// folder of this machine kept for the asker, `<data>/work/<asker>/video/`:
//   - `ensure`: this machine's own ffmpeg and ffprobe (the one it has, a WinGet one on Windows
//     included, or the pinned build of G41.1 downloaded with its checksums), the download's
//     progress sent as pieces of the answer, stopped with the asker's «Cancel»;
//   - `state`/`put`/`get`/`hash`: files in 4 MB pieces (`pieces.ts`, shared with `storage`), a
//     copy checked against the SHA-256 the asker sent before it appears, resumed after a
//     reconnect from what arrived;
//   - `render`: the timeline (a document, never a command or a filter graph) compiled here by this
//     machine's own compiler with its fonts and its encoder (NVENC when it really works), its files
//     probed here, ffmpeg run with `execFile` and every input limited to files of this folder
//     (`-protocol_whitelist file`, no URL); the progress as pieces; «Cancel» stops ffmpeg and
//     leaves nothing half-written;
//   - `clean`: the finished videos the asker took back (or the whole folder).
// No key of either machine is involved; the log of nodes writes what was asked.

import { mkdir, readFile, realpath, rm, stat } from "node:fs/promises";
import { isAbsolute, join, relative, resolve, sep } from "node:path";
import { nodeMedia } from "@redgiant/hierarchy";
import { isMediaRef, PRODUCT_NAME, readRgVideo, VIDEO_RENDER_QUALITIES } from "@redgiant/protocol";
import {
  compileVideo,
  EmptyTimeline,
  type RenderProbe,
  VIDEO_COMPILER_VERSION,
} from "../editor/video/compile.js";
import type { MediaMachineLike } from "../editor/video/machine.js";
import { type MediaRunner, runMedia } from "../editor/video/media-run.js";
import { probeFile, renderProbeOf } from "../editor/video/probe.js";
import {
  type FfmpegRun,
  ffmpegRunner,
  RENDER_FONTS_DIR,
  renderVideo,
} from "../editor/video/render.js";
import { fileHash, pieceState, putPiece, readPiece } from "./pieces.js";
import type { NodeCaller } from "./service.js";
import { NodeError } from "./service.js";

/** A file of the asker's video folder: copied media (by hash) or a finished video. */
export const MEDIA_NAME = /^(media|out)\/[A-Za-z0-9][A-Za-z0-9_-]{0,79}(\.[A-Za-z0-9]{1,8})?$/;

export interface NodeMediaOptions {
  dataDir: string;
  machine: MediaMachineLike;
  run?: MediaRunner;
  fontsDir?: string;
  /** Whether this machine's sandbox is a real container (it changes nothing for media: R1). */
  container: boolean;
  /** The person lends this machine's sandboxes (and so its renders) now. */
  lends: (ownerId: string) => boolean;
  /** How often progress pieces go at most (ms). */
  everyMs?: number;
}

const safe = (fp: string) =>
  fp
    .replace(/^SHA256:/, "")
    .replace(/[^A-Za-z0-9]/g, "")
    .slice(0, 24);

/** Whether `p` is `root` or inside it. */
const inside = (root: string, p: string) => p === root || p.startsWith(root + sep);

/**
 * ffmpeg's arguments with every input limited to files inside `roots`: `-protocol_whitelist file`
 * before each `-i`, and an input that is a URL or a path outside is refused (relative ones are
 * read from `cwd`). Pure: tested on its own.
 */
export function confineInputs(
  args: readonly string[],
  cwd: string,
  roots: readonly string[],
): string[] {
  const out: string[] = [];
  for (let i = 0; i < args.length; i++) {
    const a = args[i] as string;
    if (a === "-i") {
      const input = args[i + 1];
      if (input === undefined) throw new NodeError("invalid", "An input without a file");
      if (/^[a-z][a-z0-9+.-]*:/i.test(input) && !/^[a-z]:[\\/]/i.test(input))
        throw new NodeError("refused", `Not a file: ${input.slice(0, 80)}`);
      const abs = isAbsolute(input) ? resolve(input) : resolve(cwd, input);
      if (!roots.some((r) => inside(resolve(r), abs)))
        throw new NodeError("refused", "A file outside the folder kept for you");
      out.push("-protocol_whitelist", "file", "-i", input);
      i++;
      continue;
    }
    out.push(a);
  }
  return out;
}

export function nodeMediaHandler(o: NodeMediaOptions) {
  const run = o.run ?? runMedia;
  return async (c: NodeCaller, raw: unknown): Promise<unknown> => {
    const may = nodeMedia(c.rights, o.container);
    if (!may.ok) throw new NodeError("refused", "This machine does not let you render here");
    if (!o.lends(c.ownerId))
      throw new NodeError("refused", "This machine does not lend its sandboxes now");
    const b = (raw ?? {}) as Record<string, unknown>;
    const base = join(o.dataDir, "work", safe(c.from), "video");
    await mkdir(join(base, "media"), { recursive: true });
    await mkdir(join(base, "out"), { recursive: true });
    const real = await realpath(base);
    const at = async (name: unknown) => {
      if (typeof name !== "string" || !MEDIA_NAME.test(name))
        throw new NodeError("invalid", "A file here is media/<hash>.<ext> or out/<name>.mp4");
      const file = join(real, ...name.split("/"));
      // A link planted in the folder does not lead out of it.
      const dir = await realpath(join(file, "..")).catch(() => "");
      if (!inside(real, dir)) throw new NodeError("refused", "Outside the folder kept for you");
      return file;
    };
    // Progress pieces, not more often than `everyMs`.
    let last = 0;
    const tell = (body: Record<string, unknown>, force = false) => {
      const now = Date.now();
      if (!force && now - last < (o.everyMs ?? 250)) return;
      last = now;
      c.chunk(body);
    };
    switch (b.action) {
      case "ensure": {
        const ready = await o.machine.ensure({
          signal: c.signal,
          progress: (done, total) => tell({ step: "download", done, total }),
          unpacking: () => tell({ step: "unpack" }, true),
        });
        void ready;
        return { media: await o.machine.media(), gpus: await o.machine.gpus() };
      }
      case "state":
        return pieceState(await at(b.name));
      case "put":
        return putPiece(await at(b.name), b);
      case "get":
        return readPiece(await at(b.name), Number(b.offset) || 0);
      case "hash":
        return fileHash(await at(b.name));
      case "clean": {
        if (b.all === true) {
          await rm(real, { recursive: true, force: true });
          return { ok: true };
        }
        const names = Array.isArray(b.names) ? b.names : [];
        for (const n of names.slice(0, 50)) await rm(await at(n), { force: true });
        return { ok: true };
      }
      case "render":
        return render(c, b, real, at, tell);
      default:
        throw new NodeError("invalid", "Unknown video action");
    }
  };

  async function render(
    c: NodeCaller,
    b: Record<string, unknown>,
    real: string,
    at: (name: unknown) => Promise<string>,
    tell: (body: Record<string, unknown>, force?: boolean) => void,
  ) {
    if (b.compiler !== VIDEO_COMPILER_VERSION)
      throw new NodeError(
        "invalid",
        `This machine renders with another version of the video compiler (${VIDEO_COMPILER_VERSION}, asked ${String(b.compiler)}): update ${PRODUCT_NAME} on both`,
      );
    const tools = o.machine.found();
    if (!tools) throw new NodeError("invalid", "There is no ffmpeg here yet (ask «ensure» first)");
    let doc: ReturnType<typeof readRgVideo>;
    try {
      doc = readRgVideo(JSON.stringify(b.doc ?? null));
    } catch (e) {
      throw new NodeError("invalid", `The timeline cannot be read: ${(e as Error).message}`);
    }
    const files = (b.media ?? {}) as Record<string, unknown>;
    const quality = VIDEO_RENDER_QUALITIES.find((q) => q === b.quality) ?? "good";
    const height = Number(b.height) > 0 ? Math.min(4320, Math.round(Number(b.height))) : undefined;
    if (typeof b.out !== "string" || !b.out.startsWith("out/") || !b.out.endsWith(".mp4"))
      throw new NodeError("invalid", "The video is written as out/<name>.mp4");
    const out = await at(b.out);
    // Every file of the timeline must be here, copied whole (its name is its hash).
    const paths: Record<string, string> = {};
    const probes: Record<string, RenderProbe> = {};
    const rate = doc.format.rate;
    const used = [...new Set(doc.clips.flatMap((x) => (isMediaRef(x.ref) ? [x.ref.media] : [])))];
    for (const m of used) {
      c.signal.throwIfAborted();
      const name = files[m];
      if (name === undefined) continue;
      const abs = await at(name);
      if (!(await stat(abs).catch(() => undefined))?.isFile())
        throw new NodeError("invalid", `${String(name)} was not copied here`);
      const p = await probeFile(tools.ffprobe, abs, { run, signal: c.signal }).catch((e) => {
        throw new NodeError("invalid", `ffprobe cannot read ${m}: ${(e as Error).message}`);
      });
      paths[m] = abs;
      probes[m] = renderProbeOf(p, rate, String(name).replace(/^media\/|\.[^.]+$/g, ""));
    }
    const encoder = await o.machine.encoder();
    let plan: ReturnType<typeof compileVideo>;
    try {
      plan = compileVideo(doc, probes, {
        encoder,
        ...(height && { height }),
        quality,
        fontsDir: o.fontsDir ?? RENDER_FONTS_DIR,
      });
    } catch (e) {
      if (e instanceof EmptyTimeline)
        throw new NodeError("invalid", "The timeline has nothing to play");
      throw e;
    }
    const fonts = resolve(o.fontsDir ?? RENDER_FONTS_DIR);
    const ff = ffmpegRunner(tools.ffmpeg, run);
    const confined: FfmpegRun = (args, x) => ff(confineInputs(args, x.cwd, [real, fonts]), x);
    tell({ step: "render", fraction: 0 }, true);
    const done = await renderVideo(plan, {
      run: confined,
      mediaPath: (m) => paths[m] ?? join(real, "missing"),
      workDir: join(real, "work"),
      cacheDir: join(real, "segments"),
      out,
      signal: c.signal,
      progress: (fraction, step) => tell({ step: "render", fraction, what: step }, fraction === 1),
    });
    const side = async (p: string | undefined) => {
      if (!p) return undefined;
      const text = await readFile(p, "utf8").catch(() => undefined);
      await rm(p, { force: true });
      return text;
    };
    const srt = await side(done.sidecars.find((x) => x.endsWith(".srt")));
    const vtt = await side(done.sidecars.find((x) => x.endsWith(".vtt")));
    const h = await fileHash(out);
    return {
      name: relative(real, out).split(sep).join("/"),
      sha256: h.sha256,
      size: h.size,
      frames: done.frames,
      seconds: done.seconds,
      width: plan.width,
      height: plan.height,
      reused: done.reused,
      warnings: done.warnings,
      encoder,
      ...(srt !== undefined && { srt }),
      ...(vtt !== undefined && { vtt }),
    };
  }
}
