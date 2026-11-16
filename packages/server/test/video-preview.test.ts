// G41.5a on the server, with a fake ffmpeg/ffprobe: the media the page plays (proxy, strip,
// waveform asked for in order, signed links served with Range), the exact preview of a stretch
// as a job (segments cached by hash, the same stretch again free, a small edit re-encodes only
// what changed) and the cleaning of the caches.
import { mkdir, mkdtemp, readdir, readFile, rm, stat, utimes, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { isAbsolute, join } from "node:path";
import { newRgVideo, type RgVideo, type VideoClip } from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { VideoAnalysis } from "../src/editor/video/analysis.js";
import type { MediaRunner, RunOptions } from "../src/editor/video/media-run.js";
import { pruneCache, VideoPreviews } from "../src/editor/video/preview.js";
import { Jobs } from "../src/jobs.js";
import { startServer } from "./helpers.js";

const FX = join(import.meta.dirname, "fixtures", "video");
const LOUDNORM =
  '{ "input_i" : "-20.0", "input_tp" : "-2.0", "input_lra" : "3.0", "input_thresh" : "-30.0", "target_offset" : "0.1" }';

/** ffprobe answers with a 30 s 1280×720 clip with sound; ffmpeg writes its last argument. */
function fakeMedia() {
  const calls: { program: string; args: string[] }[] = [];
  const run: MediaRunner = async (program, args, o: RunOptions = {}) => {
    calls.push({ program, args });
    if (program === "ffprobe")
      return { stdout: await readFile(join(FX, "probe-clip30.json"), "utf8"), stderr: "" };
    o.onStdoutLine?.("out_time_us=500000");
    if (args.includes("null")) return { stdout: "", stderr: LOUDNORM };
    const out = args.at(-1) as string;
    await writeFile(isAbsolute(out) ? out : join(o.cwd ?? ".", out), `made by ${program}`);
    return { stdout: "", stderr: "" };
  };
  return { run, calls };
}

const R = { num: 25, den: 1 };
const clip = (id: string, track: string, start: number, dur: number, more: Partial<VideoClip>) =>
  ({
    id,
    track,
    start,
    sourceRange: { start: 0, duration: dur },
    ref: { media: "clip.mp4" },
    enabled: true,
    volume: 0,
    fadeIn: 0,
    fadeOut: 0,
    fit: "fill",
    ...more,
  }) as VideoClip;

function timeline(): RgVideo {
  const d = newRgVideo({ width: 1280, height: 720, rate: R, aspect: "16:9" });
  for (const id of ["V2", "V3"]) d.tracks.push({ id, kind: "Video", name: id, locked: false });
  d.clips = [
    clip("v1", "V1", 0, 100, {}),
    clip("v2", "V1", 100, 100, { sourceRange: { start: 200, duration: 100 } }),
    clip("t", "V2", 50, 100, {
      ref: { generator: "text", text: "Ciao", style: "title", position: "center" },
    }),
    clip("a1", "A1", 0, 200, {}),
  ];
  return d;
}

let dir: string;
beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-video-preview-"));
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

describe("pruneCache", () => {
  it("removes the least recently used beyond the size or the count, never what is kept", async () => {
    const at = (n: number) => new Date(Date.parse("2026-11-16T10:00:00Z") + n * 60_000);
    for (const [i, name] of ["a", "b", "c", "d"].entries()) {
      await writeFile(join(dir, name), Buffer.alloc(100));
      await utimes(join(dir, name), at(i), at(i));
    }
    await writeFile(join(dir, "e.part.mp4"), Buffer.alloc(1000));
    // 400 bytes in four files (the half-written one does not count and stays)
    expect(await pruneCache(dir, { maxBytes: 400 })).toEqual([]);
    expect(await pruneCache(dir, { maxBytes: 250, keep: new Set(["a"]) })).toEqual(["b", "c"]);
    expect((await readdir(dir)).sort()).toEqual(["a", "d", "e.part.mp4"]);
    expect(await pruneCache(dir, { maxFiles: 1 })).toEqual(["a"]);
    expect(await pruneCache(join(dir, "nothing"), { maxFiles: 0 })).toEqual([]);
  });
});

describe("VideoPreviews.exact", () => {
  const setup = (maxBytes?: number) => {
    const jobs = new Jobs();
    const fake = fakeMedia();
    const tools = async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" });
    const analysis = new VideoAnalysis({
      dataDir: join(dir, "data"),
      jobs,
      tools,
      transcriber: async () => undefined,
      run: fake.run,
    });
    const previews = new VideoPreviews({
      analysis,
      jobs,
      tools,
      run: fake.run,
      fontsDir: "/fonts",
      ...(maxBytes !== undefined && { maxBytes }),
    });
    return { jobs, fake, analysis, previews };
  };

  it("renders a stretch at 360p; the same stretch again is free; an edit re-encodes its part", async () => {
    const { jobs, fake, previews } = setup();
    const media = join(dir, "clip.mp4");
    await writeFile(media, Buffer.alloc(4096, 3));
    const ask = async (doc: RgVideo, from: number, to: number) => {
      const job = previews.exact("me", {
        doc,
        name: "film.rgvideo",
        from,
        to,
        mediaPath: async (m) => (m === "clip.mp4" ? media : undefined),
      });
      expect(job.kind).toBe("video_preview");
      const end = await jobs.settled(job.id, 20);
      expect(end?.state, JSON.stringify(end?.error)).toBe("done");
      return end?.result as { id: string; start: number; frames: number; height: number };
    };
    const first = await ask(timeline(), 40, 160);
    expect(first).toMatchObject({ start: 40, frames: 120, height: 360 });
    // ffprobe once, then segments cut at 40, 50, 100, 150, 160, the sound in two passes, the join
    const ff = fake.calls.filter((c) => c.program === "ffmpeg");
    expect(fake.calls.filter((c) => c.program === "ffprobe")).toHaveLength(1);
    expect(ff).toHaveLength(4 + 3 + 1);
    const join_ = ff.at(-1)?.args ?? [];
    expect(join_[join_.indexOf("-ss") + 1]).toBe("1.600000");
    expect(join_[join_.indexOf("-t") + 1]).toBe("4.800000");
    const file = previews.previewPath("me", first.id) as string;
    expect((await stat(file)).isFile()).toBe(true);
    expect(previews.previewPath("someone-else", first.id)).not.toBe(file);
    expect(previews.previewPath("me", "../x")).toBeUndefined();
    const segs = await readdir(previews.segmentsDir);
    expect(segs.filter((n) => n.startsWith("seg-"))).toHaveLength(4);
    // the same stretch again: nothing runs
    const before = fake.calls.length;
    expect((await ask(timeline(), 40, 160)).id).toBe(first.id);
    expect(fake.calls.length).toBe(before);
    // the title changed: only the two segments under it, the sound from the cache, the join
    const edited = timeline();
    edited.clips[2] = clip("t", "V2", 50, 100, {
      ref: { generator: "text", text: "Ciao a tutti", style: "title", position: "center" },
    });
    const n = fake.calls.length;
    expect((await ask(edited, 40, 160)).id).not.toBe(first.id);
    expect(fake.calls.slice(n).map((c) => c.args.at(-1))).toEqual([
      expect.stringMatching(/^seg-.*\.part\.mp4$/),
      expect.stringMatching(/^seg-.*\.part\.mp4$/),
      expect.stringMatching(/\.mp4\.part\.mp4$/),
    ]);
  });

  it("at most a minute; the cache cleaned down to its size, the stretch's segments kept", async () => {
    const { jobs, previews } = setup(1);
    const media = join(dir, "clip.mp4");
    await writeFile(media, Buffer.alloc(4096, 3));
    // a title of 80 s (no file limits it), the clip's 30 s under its start
    const doc = timeline();
    doc.clips = [
      clip("v1", "V1", 0, 750, {}),
      clip("t", "V2", 0, 2000, {
        ref: { generator: "text", text: "Lungo", style: "title", position: "center" },
      }),
    ];
    const job = previews.exact("me", {
      doc,
      name: "film.rgvideo",
      from: 0,
      to: 5000,
      mediaPath: async () => media,
    });
    const end = await jobs.settled(job.id, 20);
    expect(end?.result).toMatchObject({ start: 0, frames: 1500 });
    // a segment of another timeline, older: it goes first
    await mkdir(previews.segmentsDir, { recursive: true });
    const old = join(previews.segmentsDir, "seg-old.mp4");
    await writeFile(old, "x");
    await utimes(old, new Date(0), new Date(0));
    const again = previews.exact("me", {
      doc,
      name: "film.rgvideo",
      from: 0,
      to: 100,
      mediaPath: async () => media,
    });
    await jobs.settled(again.id, 20);
    const left = await readdir(previews.segmentsDir);
    expect(left).not.toContain("seg-old.mp4");
    expect(left.some((n) => n.startsWith("seg-"))).toBe(true);
  });

  it("an empty stretch fails in plain words", async () => {
    const { jobs, previews } = setup();
    const job = previews.exact("me", {
      doc: newRgVideo(),
      name: "vuoto.rgvideo",
      from: 0,
      to: 25,
      mediaPath: async () => undefined,
    });
    expect((await jobs.settled(job.id, 20))?.error?.code).toBe("video_empty");
  });
});

describe("video routes", () => {
  it("prepare: proxy first, then strip and waveform; links served with Range; the exact preview", async () => {
    const s = await startServer([]);
    try {
      const fake = fakeMedia();
      const core = s.core as unknown as Record<string, unknown>;
      const analysis = new VideoAnalysis({
        dataDir: join(s.dir, "data"),
        jobs: s.core.jobs,
        tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
        transcriber: async () => undefined,
        run: fake.run,
      });
      core.videoAnalysisCache = analysis;
      core.videoPreviewsCache = new VideoPreviews({
        analysis,
        jobs: s.core.jobs,
        tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
        run: fake.run,
        fontsDir: "/fonts",
      });
      const root = await s.core.scopeFolder("me", "platform");
      await mkdir(join(root, "riprese"), { recursive: true });
      await writeFile(join(root, "riprese", "clip.mp4"), Buffer.alloc(8192, 5));
      await writeFile(join(root, "foto.jpg"), "a picture");
      const doc = timeline();
      doc.clips = doc.clips.map((c) =>
        "media" in c.ref ? { ...c, ref: { media: "riprese/clip.mp4" } } : c,
      );
      doc.clips.push(clip("p", "V3", 0, 50, { ref: { media: "foto.jpg", still: true } }));
      doc.clips.push(clip("x", "V3", 60, 50, { ref: { media: "via.mp4" } }));
      await writeFile(join(root, "film.rgvideo"), JSON.stringify(doc));
      const file = { scope: "platform", path: "film.rgvideo" };
      type Info = {
        media: string;
        kind?: string;
        missing?: true;
        file?: string;
        proxy?: string;
        filmstrip?: { url: string; tiles: number };
        waveform?: { url: string; width: number };
        jobs: string[];
      };
      const prepare = async () => {
        const r = await s.api<{ media: Info[]; fonts: { regular: string } }>(
          "POST",
          "/api/editor/video/prepare",
          file,
        );
        expect(r.status).toBe(200);
        const by = Object.fromEntries(r.body.media.map((m) => [m.media, m]));
        for (const m of r.body.media)
          for (const id of m.jobs) expect((await s.core.jobs.settled(id, 20))?.state).toBe("done");
        return { by, fonts: r.body.fonts };
      };
      const one = await prepare();
      expect(one.by["via.mp4"]).toEqual({ media: "via.mp4", missing: true, jobs: [] });
      expect(one.by["foto.jpg"]).toMatchObject({ kind: "image", jobs: [] });
      const clipInfo = one.by["riprese/clip.mp4"] as Info;
      expect(clipInfo.jobs).toHaveLength(1);
      expect(clipInfo.proxy).toBeUndefined();
      const two = (await prepare()).by["riprese/clip.mp4"] as Info;
      expect(two).toMatchObject({ kind: "video" });
      expect(two.proxy).toMatch(/^\/preview\/.+\/proxy\.mp4$/);
      expect(two.jobs).toHaveLength(2);
      const three = await prepare();
      const ready = three.by["riprese/clip.mp4"] as Info;
      expect(ready.jobs).toEqual([]);
      expect(ready.filmstrip).toMatchObject({ tiles: 30 });
      expect(ready.waveform).toMatchObject({ width: 1200 });
      expect(three.fonts.regular).toMatch(/Inter-Regular\.ttf$/);
      // a signed link plays in a <video>: no sign-in header, ranges answered
      const ranged = await fetch(`${s.url}${ready.proxy}`, { headers: { range: "bytes=0-3" } });
      expect(ranged.status).toBe(206);
      expect(ranged.headers.get("content-range")).toBe("bytes 0-3/14");
      expect(await ranged.text()).toBe("made");
      const photo = await fetch(`${s.url}${three.by["foto.jpg"]?.file}`);
      expect(await photo.text()).toBe("a picture");

      const bad = await s.api("POST", "/api/editor/video/exact", { ...file, from: 50, to: 10 });
      expect(bad.status).toBe(400);
      const r = await s.api<{ job: { id: string } }>("POST", "/api/editor/video/exact", {
        ...file,
        from: 0,
        to: 75,
      });
      const end = await s.core.jobs.settled(r.body.job.id, 20);
      expect(end?.state, JSON.stringify(end?.error)).toBe("done");
      const id = (end?.result as { id: string } | undefined)?.id ?? "";
      const got = await s.api<{ url: string }>("GET", `/api/editor/video/exact/${id}`);
      expect(got.body.url).toMatch(/^\/preview\/.+\.mp4$/);
      const video = await fetch(`${s.url}${got.body.url}`, { headers: { range: "bytes=0-" } });
      expect(video.status).toBe(206);
      expect(
        (await s.api("GET", `/api/editor/video/exact/${id}`, undefined, "other-token-0123456789"))
          .status,
      ).not.toBe(200);
      expect(
        (await s.api("POST", "/api/editor/video/prepare", { ...file, path: "x.txt" })).status,
      ).toBe(400);
    } finally {
      await s.close();
    }
  });
});
