// The video editor's routes (G41.5a): what the page needs to play a timeline on proxies, and the
// exact preview of a stretch made by ffmpeg.
//   POST /api/editor/video/prepare {scope, path, extra?}  every file the timeline uses (and the
//                                                  `extra` ones, about to go in): its probe, signed
//                                                  links (`/preview/…`, served with Range) to the
//                                                  proxy, strip of frames, waveform and the file
//                                                  itself, and the jobs started for what is missing
//   POST /api/editor/video/exact {scope, path, from, to}  the exact preview of frames [from, to):
//                                                  a job `video_preview` (its result's `id`)
//   GET  /api/editor/video/exact/:id               the finished preview's signed link
//   POST /api/editor/video/versions {scope, path}  its named versions (A5), the newest first
//   POST /api/editor/video/versions/save {scope, path, name}  a version of it as it is now
//   POST /api/editor/video/versions/read {scope, path, version}  a version's timeline (to bring
//                                                  it back: the page commits it as one edit)
//   POST /api/editor/video/captions {scope, path}  the subtitles from what the timeline plays
//                                                  (G41.5c, G41.4's transcripts): `captions`
//                                                  once every sound is analysed, else the jobs
//                                                  analysing them; `silent` files without words
// The derived files are a cache of each file (`VideoAnalysis`, by fingerprint), never written
// into the project: an archived project's timeline still plays.

import { readFile, stat } from "node:fs/promises";
import { basename, extname, join } from "node:path";
import {
  isMediaRef,
  type Job,
  readRgVideo,
  rgvideoVersionsDir,
  type VideoMediaInfo,
  type VideoPrepared,
} from "@redgiant/protocol";
import type { Context, Hono } from "hono";
import { z } from "zod";
import { BadRequestError, NotFoundError, type RedGiantCore } from "../core.js";
import { mediaFingerprint, type VideoAnalysis } from "./video/analysis.js";
import { captionsForTimeline } from "./video/captions.js";
import { filmstripTiles, waveformWidth } from "./video/derived.js";
import { RENDER_FONTS_DIR } from "./video/render.js";
import { listVideoVersions, saveVideoVersion } from "./video/versions.js";

const PICTURE = /\.(png|jpe?g|webp|gif|bmp|tiff?|avif|heic|heif)$/i;
const SOUND = /\.(mp3|wav|m4a|aac|flac|ogg|oga|opus|weba|wma|aiff?)$/i;

/** A file's fingerprint, read again only when its size or date change. */
class Fingerprints {
  private readonly known = new Map<string, { key: string; fp: string }>();
  async of(abs: string): Promise<string> {
    const st = await stat(abs);
    const key = `${st.size}:${st.mtimeMs}`;
    const hit = this.known.get(abs);
    if (hit?.key === key) return hit.fp;
    const fp = await mediaFingerprint(abs);
    this.known.set(abs, { key, fp });
    if (this.known.size > 5000) this.known.delete(this.known.keys().next().value as string);
    return fp;
  }
}

/** The media of a timeline as the page plays them; starts the jobs for what is missing. */
export async function prepareMedia(
  o: {
    analysis: VideoAnalysis;
    owner: string;
    media: string[];
    abs: (media: string) => Promise<string | undefined>;
    link: (abs: string) => string;
    fingerprint: (abs: string) => Promise<string>;
  },
  start = true,
): Promise<VideoMediaInfo[]> {
  const out: VideoMediaInfo[] = [];
  for (const media of o.media) {
    const abs = await o.abs(media);
    if (!abs || !(await stat(abs).catch(() => undefined))?.isFile()) {
      out.push({ media, missing: true, jobs: [] });
      continue;
    }
    const info: VideoMediaInfo = { media, file: o.link(abs), jobs: [] };
    out.push(info);
    if (PICTURE.test(media)) {
      info.kind = "image";
      continue;
    }
    const fp = await o.fingerprint(abs);
    const probe = await o.analysis.cachedProbe(fp);
    const has = (k: "proxy" | "filmstrip" | "waveform") =>
      stat(o.analysis.derivedPath(fp, k)).then(
        (s) => s.isFile(),
        () => false,
      );
    const derive = async (k: "proxy" | "filmstrip" | "waveform") => {
      if (start) info.jobs.push((await o.analysis.derive(o.owner, abs, basename(abs), k)).id);
    };
    if (!probe) {
      // The first job reads the file too; the rest are asked for once its kind is known.
      await derive(SOUND.test(media) ? "waveform" : "proxy");
      continue;
    }
    info.kind = probe.kind;
    info.probe = probe;
    if (probe.kind === "image") continue;
    const duration = probe.duration ?? 0;
    if (probe.kind === "video") {
      if (await has("proxy")) info.proxy = o.link(o.analysis.derivedPath(fp, "proxy"));
      else await derive("proxy");
      // The strip reads the proxy: asked for once it is there.
      if (await has("filmstrip"))
        info.filmstrip = {
          url: o.link(o.analysis.derivedPath(fp, "filmstrip")),
          tiles: filmstripTiles(duration),
        };
      else if (info.proxy) await derive("filmstrip");
    }
    if (probe.audio) {
      if (await has("waveform"))
        info.waveform = {
          url: o.link(o.analysis.derivedPath(fp, "waveform")),
          width: waveformWidth(duration),
        };
      else await derive("waveform");
    }
  }
  return out;
}

const FileBody = z.object({ scope: z.string().min(1), path: z.string().min(1) });

// biome-ignore lint/suspicious/noExplicitAny: the app's own Env, kept private in app.ts
export function videoRoutes<E extends { Variables: any }>(
  app: Hono<E>,
  core: RedGiantCore,
  owner: (c: Context<E>) => string,
): void {
  const fingerprints = new Fingerprints();
  const link = (ownerId: string) => (abs: string) =>
    `/preview/${core.previews.sign(ownerId, { kind: "file", path: abs })}/${encodeURIComponent(basename(abs))}`;
  /** The timeline as saved, and its files' paths on this machine. */
  const timeline = async (ownerId: string, scope: string, path: string) => {
    if (extname(path).toLowerCase() !== ".rgvideo") throw new BadRequestError("Not a .rgvideo");
    // The editor's latest edits first (G41.5b: the host writes after a pause).
    await core.editor.writeNow(ownerId, { scope, path });
    const abs = await core.docAbs(ownerId, { scope, path }).catch(() => {
      throw new NotFoundError(`No such file "${path}"`);
    });
    const doc = readRgVideo(await readFile(abs, "utf8"));
    const media = [...new Set(doc.clips.flatMap((c) => (isMediaRef(c.ref) ? [c.ref.media] : [])))];
    const mediaAbs = (m: string) => core.docAbs(ownerId, { scope, path: m }).catch(() => undefined);
    return { doc, media, mediaAbs, name: basename(abs), abs };
  };

  app.post("/api/editor/video/versions", async (c) => {
    const b = FileBody.safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    const t = await timeline(owner(c), b.data.scope, b.data.path);
    return c.json({ versions: await listVideoVersions(t.abs, b.data.path) }, 200);
  });

  app.post("/api/editor/video/versions/save", async (c) => {
    const b = FileBody.extend({ name: z.string().trim().min(1).max(120) }).safeParse(
      await c.req.json().catch(() => ({})),
    );
    if (!b.success) return c.json({ error: b.error.message }, 400);
    const o = owner(c);
    // An archived project's files stay as they are.
    core.assertWritable(o, b.data.scope);
    const t = await timeline(o, b.data.scope, b.data.path);
    const version = await saveVideoVersion({
      abs: t.abs,
      path: b.data.path,
      doc: t.doc,
      name: b.data.name,
      reason: "manual",
    });
    return c.json({ version }, 200);
  });

  app.post("/api/editor/video/versions/read", async (c) => {
    const b = FileBody.extend({ version: z.string().min(1).max(4000) }).safeParse(
      await c.req.json().catch(() => ({})),
    );
    if (!b.success) return c.json({ error: b.error.message }, 400);
    const dir = `${rgvideoVersionsDir(b.data.path.replace(/\\/g, "/"))}/`;
    const v = b.data.version.replace(/\\/g, "/");
    if (!v.startsWith(dir) || v.slice(dir.length).includes("/") || !/\.rgvideo$/i.test(v))
      return c.json({ error: "Not a version of this timeline" }, 400);
    const abs = await core.docAbs(owner(c), { scope: b.data.scope, path: v }).catch(() => {
      throw new NotFoundError(`No such version "${v}"`);
    });
    return c.json({ doc: readRgVideo(await readFile(abs, "utf8")) }, 200);
  });

  app.post("/api/editor/video/prepare", async (c) => {
    const b = FileBody.extend({
      /** Files not in the timeline yet (G41.5b: dragged from the project's files). */
      extra: z.array(z.string().min(1).max(4000)).max(50).optional(),
    }).safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    const o = owner(c);
    const t = await timeline(o, b.data.scope, b.data.path);
    const media = await prepareMedia({
      analysis: core.videoAnalysis,
      owner: o,
      media: [...new Set([...t.media, ...(b.data.extra ?? [])])],
      abs: t.mediaAbs,
      link: link(o),
      fingerprint: (abs) => fingerprints.of(abs),
    });
    // The server's fonts: texts and subtitles in the page look as in the render.
    const fonts = {
      regular: link(o)(join(RENDER_FONTS_DIR, "Inter-Regular.ttf")),
      bold: link(o)(join(RENDER_FONTS_DIR, "Inter-Bold.ttf")),
    };
    return c.json({ media, fonts } satisfies VideoPrepared, 200);
  });

  app.post("/api/editor/video/exact", async (c) => {
    const b = FileBody.extend({
      from: z.number().int().min(0),
      to: z.number().int().min(1),
    }).safeParse(await c.req.json().catch(() => ({})));
    if (!b.success || b.data.to <= b.data.from)
      return c.json({ error: b.success ? "to must be after from" : b.error.message }, 400);
    const o = owner(c);
    const t = await timeline(o, b.data.scope, b.data.path);
    const job: Job = core.videoPreviews.exact(o, {
      doc: t.doc,
      name: t.name,
      from: b.data.from,
      to: b.data.to,
      mediaPath: t.mediaAbs,
    });
    return c.json({ job }, 200);
  });

  app.post("/api/editor/video/captions", async (c) => {
    const b = FileBody.safeParse(await c.req.json().catch(() => ({})));
    if (!b.success) return c.json({ error: b.error.message }, 400);
    const o = owner(c);
    const t = await timeline(o, b.data.scope, b.data.path);
    const audible = new Set(t.doc.tracks.filter((x) => x.kind === "Audio").map((x) => x.id));
    const sounds = [
      ...new Set(
        t.doc.clips.flatMap((x) =>
          audible.has(x.track) && isMediaRef(x.ref) ? [x.ref.media] : [],
        ),
      ),
    ];
    const transcripts: Record<string, { words: { start: number; end: number; text: string }[] }> =
      {};
    const jobs: string[] = [];
    const silent: string[] = [];
    for (const m of sounds) {
      const abs = await t.mediaAbs(m);
      if (!abs || !(await stat(abs).catch(() => undefined))?.isFile()) continue;
      const done = await core.videoAnalysis.cached(abs);
      if (!done) jobs.push((await core.videoAnalysis.analyze(o, abs, m)).id);
      else if (done.transcript?.words.length) transcripts[m] = done.transcript;
      else silent.push(m);
    }
    if (jobs.length) return c.json({ jobs, silent }, 200);
    return c.json({ jobs, silent, captions: captionsForTimeline(t.doc, transcripts) }, 200);
  });

  app.get("/api/editor/video/exact/:id", async (c) => {
    const o = owner(c);
    const file = core.videoPreviews.previewPath(o, c.req.param("id"));
    if (!file || !(await stat(file).catch(() => undefined))?.isFile())
      return c.json({ error: "No such preview" }, 404);
    return c.json({ url: link(o)(file) }, 200);
  });
}
