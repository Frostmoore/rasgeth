// The render of a timeline on a node the person chose (G41.7), from the asking side, as the steps
// of the job `video_render`: the files' SHA-256 here («video_probe»), ffmpeg made ready there
// («node_ffmpeg», the node's own download with its bar), the files copied in checked pieces
// («node_copy»: bytes, speed and time left; a file already there with the same hash is skipped, a
// copy cut by a reconnect resumes), the render there («video_render», its progress), the video
// brought back («node_fetch») and checked against the hash the node computed («node_check»), then
// saved in the project as a render here would be («video_save»). «Cancel» stops the step running on
// the node too (`Nodes.request` sends `cancel`). A node that goes away is a clear error and leaves
// no half-copied file here; what it wrote there is cleaned at the end, whatever happened.
// No key goes to the node: only the timeline and its media files.

import { createHash, randomUUID } from "node:crypto";
import { open, rename, rm, stat, writeFile } from "node:fs/promises";
import { extname } from "node:path";
import {
  type H264Encoder,
  isMediaRef,
  type NodeMedia,
  type RgVideo,
  type VideoRenderQuality,
} from "@redgiant/protocol";
import { JobFailure, type JobHandle } from "../../jobs.js";
import { fileHash, PIECE } from "../../nodes/pieces.js";
import { timelineLuts, VIDEO_COMPILER_VERSION } from "./compile.js";

/** The steps of a render on a node. */
export const REMOTE_RENDER_STEPS = [
  "video_wait",
  "video_probe",
  "node_ffmpeg",
  "node_copy",
  "video_render",
  "node_fetch",
  "node_check",
  "video_save",
];

/** One `media` request to the node (the server's `Nodes.request`), with its pieces. */
export type NodeMediaCall = (
  body: Record<string, unknown>,
  o: {
    signal: AbortSignal;
    onChunk?: (b: unknown) => void;
    timeoutMs?: number;
    /** How long to wait for a node that is offline (default: the nodes' own wait). */
    waitMs?: number;
    what?: string;
  },
) => Promise<unknown>;

export interface RemoteRenderAsk {
  node: { fingerprint: string; name: string };
  /** The timeline as it is rendered (its shape already set). */
  doc: RgVideo;
  /** The output's height in pixels (from the short side asked). */
  height?: number;
  quality: VideoRenderQuality;
  /** A media of the timeline's path here (undefined: missing, skipped as a render here does). */
  mediaPath: (media: string) => Promise<string | undefined>;
  /** Where the finished video goes here (`renders/<name>-v<n>.mp4`), chosen at the end. */
  out: () => Promise<string>;
}

export interface RemoteRenderDone {
  path: string;
  sidecars: string[];
  seconds: number;
  width: number;
  height: number;
  frames: number;
  reused: number;
  warnings: string[];
  encoder: H264Encoder;
}

/** Hashes already computed here, by path, size and date: a second render does not read again. */
const hashes = new Map<string, { key: string; sha256: string }>();

async function hashOf(abs: string): Promise<{ sha256: string; size: number }> {
  const st = await stat(abs);
  const key = `${st.size}:${st.mtimeMs}`;
  const hit = hashes.get(abs);
  if (hit?.key === key) return { sha256: hit.sha256, size: st.size };
  const h = await fileHash(abs);
  hashes.set(abs, { key, sha256: h.sha256 });
  if (hashes.size > 2000) hashes.delete(hashes.keys().next().value as string);
  return h;
}

/** A node's error as the job's: its code tells the page which words to use. */
function failure(e: unknown, node: string): Error {
  if (e instanceof JobFailure) return e;
  const err = e as { code?: string; message?: string; name?: string };
  if (err?.name === "AbortError") return e as Error;
  const code =
    err?.code === "offline" || err?.code === "lost"
      ? "video_node_offline"
      : err?.code === "forbidden" || err?.code === "refused"
        ? "video_node_refused"
        : "video_node";
  return new JobFailure(code, `${node}: ${err?.message ?? String(e)}`);
}

export async function renderOnNode(
  h: JobHandle,
  call: NodeMediaCall,
  a: RemoteRenderAsk,
): Promise<RemoteRenderDone> {
  const signal = h.signal;
  const node = a.node.name;
  h.info({ node });
  const ask = (
    body: Record<string, unknown>,
    o: Omit<Parameters<NodeMediaCall>[1], "signal"> = {},
  ) =>
    call(body, { signal, ...o }).catch((e) => {
      // A cancel says so itself; anything else is the node's error, said with its name.
      signal.throwIfAborted();
      throw failure(e, node);
    });
  const outName = `out/${randomUUID().replace(/-/g, "").slice(0, 24)}.mp4`;
  let part: string | undefined;
  try {
    // Every file of the timeline by its hash: the name it has on the node.
    h.step("video_probe");
    // The media and (3.10) the LUTs the clips use.
    const used = [
      ...new Set([
        ...a.doc.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : [])),
        ...timelineLuts(a.doc),
      ]),
    ];
    const files: { media: string; abs: string; name: string; sha256: string; size: number }[] = [];
    for (const [i, m] of used.entries()) {
      signal.throwIfAborted();
      const abs = await a.mediaPath(m);
      const st = abs ? await stat(abs).catch(() => undefined) : undefined;
      if (abs && st?.isFile()) {
        const { sha256, size } = await hashOf(abs);
        const ext = extname(abs)
          .toLowerCase()
          .replace(/[^.a-z0-9]/g, "")
          .slice(0, 9);
        files.push({ media: m, abs, name: `media/${sha256}${ext}`, sha256, size });
      }
      h.progress(i + 1, used.length);
    }

    // ffmpeg there: the one it has, or its own download (the bar is the node's bytes).
    h.step("node_ffmpeg");
    const ready = (await ask(
      { action: "ensure" },
      {
        what: "video ensure ffmpeg",
        onChunk: (b) => {
          const p = b as { step?: string; done?: number; total?: number | null };
          if (p.step === "download" && typeof p.done === "number")
            h.progress(p.done, p.total ?? null);
        },
      },
    )) as { media?: NodeMedia };
    if (!ready.media?.ffmpeg)
      throw new JobFailure("video_node_ffmpeg", `${node} has no ffmpeg and could not download one`);

    // The files, in checked pieces; one already there with the same hash is not sent again.
    h.step("node_copy");
    const total = files.reduce((n, f) => n + f.size, 0);
    let sent = 0;
    h.progress(0, total);
    for (const f of files) {
      signal.throwIfAborted();
      const there = (await ask({ action: "state", name: f.name })) as {
        sha256?: string;
        partial?: number;
      };
      if (there.sha256 === f.sha256) {
        sent += f.size;
        h.progress(sent, total);
        continue;
      }
      // Resumed where an earlier copy stopped (whole pieces only).
      let at = there.partial && there.partial < f.size ? there.partial : 0;
      const fh = await open(f.abs, "r");
      try {
        const buf = Buffer.alloc(PIECE);
        sent += at;
        do {
          signal.throwIfAborted();
          const { bytesRead } = await fh.read(buf, 0, PIECE, at);
          const last = at + bytesRead >= f.size;
          await ask(
            {
              action: "put",
              name: f.name,
              offset: at,
              data: buf.subarray(0, bytesRead).toString("base64"),
              last,
              ...(last && { sha256: f.sha256 }),
            },
            { timeoutMs: 180_000, what: `video copy ${f.media}` },
          );
          at += bytesRead;
          sent += bytesRead;
          h.progress(sent, total);
          if (last || bytesRead === 0) break;
        } while (at < f.size);
      } finally {
        await fh.close();
      }
    }

    // The render there: the node compiles the timeline itself and picks its encoder.
    h.step("video_render");
    const done = (await ask(
      {
        action: "render",
        compiler: VIDEO_COMPILER_VERSION,
        doc: a.doc,
        media: Object.fromEntries(files.map((f) => [f.media, f.name])),
        ...(a.height && { height: a.height }),
        quality: a.quality,
        out: outName,
      },
      {
        what: `video render on ${node}`,
        onChunk: (b) => {
          const p = b as { step?: string; fraction?: number };
          if (p.step === "render" && typeof p.fraction === "number")
            h.progress(Math.round(p.fraction * 1000) / 10, 100);
        },
      },
    )) as {
      name: string;
      sha256: string;
      size: number;
      frames: number;
      seconds: number;
      width: number;
      height: number;
      reused: number;
      warnings: string[];
      encoder: H264Encoder;
      srt?: string;
      vtt?: string;
    };

    // Back here as a part, its hash computed as it comes.
    h.step("node_fetch");
    const out = await a.out();
    part = `${out}.part.mp4`;
    const sha = createHash("sha256");
    const fh = await open(part, "w");
    try {
      for (let at = 0; ; ) {
        signal.throwIfAborted();
        const r = (await ask(
          { action: "get", name: done.name, offset: at },
          { timeoutMs: 180_000, what: `video fetch ${done.name}` },
        )) as { data: string; size: number; done: boolean };
        const piece = Buffer.from(r.data, "base64");
        await fh.write(piece, 0, piece.length, at);
        sha.update(piece);
        at += piece.length;
        h.progress(at, r.size);
        if (r.done || piece.length === 0) break;
      }
    } finally {
      await fh.close();
    }

    h.step("node_check");
    const got = sha.digest("hex");
    const size = (await stat(part)).size;
    if (got !== done.sha256 || size !== done.size)
      throw new JobFailure(
        "video_check",
        `The video from ${node} did not match its SHA-256 (expected ${done.sha256}, got ${got}): nothing was kept`,
      );

    h.step("video_save");
    await rename(part, out);
    part = undefined;
    const sidecars: string[] = [];
    const base = out.replace(/\.[^./\\]+$/, "");
    if (done.srt !== undefined) {
      await writeFile(`${base}.srt`, done.srt);
      sidecars.push(`${base}.srt`);
    }
    if (done.vtt !== undefined) {
      await writeFile(`${base}.vtt`, done.vtt);
      sidecars.push(`${base}.vtt`);
    }
    return {
      path: out,
      sidecars,
      seconds: done.seconds,
      width: done.width,
      height: done.height,
      frames: done.frames,
      reused: done.reused,
      warnings: done.warnings,
      encoder: done.encoder,
    };
  } finally {
    if (part) await rm(part, { force: true });
    // What the node wrote for this render goes, whatever happened (the copied media stay: the
    // next render of the same files sends nothing).
    await call(
      { action: "clean", names: [outName] },
      { signal: new AbortController().signal, timeoutMs: 10_000, waitMs: 0 },
    ).catch(() => {});
  }
}
