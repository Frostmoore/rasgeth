// The render for real (G41.3): synthetic clips (testsrc, sine) on three video tracks and two
// audio tracks with every effect, rendered by ffmpeg 9 in segments; exact frame counts (as
// montatore's tests), the streams checked with ffprobe, the loudness at −14 LUFS, a vertical
// render with a blurred background, the cache reused, and a fonts folder whose path has a colon
// and an apostrophe. Run with REDGIANT_DOCKER_TESTS=1 pnpm test:docker and REDGIANT_FFMPEG set
// to an ffmpeg ≥ 9 (ffprobe beside it, or REDGIANT_FFPROBE); REDGIANT_RENDER_ENCODER=h264_nvenc
// on a machine with an NVIDIA GPU.
import { execFileSync, spawnSync } from "node:child_process";
import { cpSync, existsSync, mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  type H264Encoder,
  kenBurnsPreset,
  newRgVideo,
  type RgVideo,
  type VideoClip,
  type VideoRef,
} from "@redgiant/protocol";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { compileVideo, type RenderTarget } from "../src/editor/video/compile.js";
import { type MediaProbe, probeMedia } from "../src/editor/video/render-probe.js";
import { ffmpegRunner, renderVideo } from "../src/editor/video/render.js";

const ffmpeg = process.env.REDGIANT_FFMPEG ?? "";
const ffprobe =
  process.env.REDGIANT_FFPROBE ??
  join(dirname(ffmpeg), process.platform === "win32" ? "ffprobe.exe" : "ffprobe");
const on = process.env.REDGIANT_DOCKER_TESTS === "1" && !!ffmpeg && existsSync(ffmpeg);
const encoder = (process.env.REDGIANT_RENDER_ENCODER ?? "libx264") as H264Encoder;
const FONTS = fileURLToPath(new URL("../fonts/", import.meta.url));
const R = { num: 25, den: 1 };

function clip(
  id: string,
  track: string,
  start: number,
  dur: number,
  ref: VideoRef,
  more: Partial<VideoClip> = {},
  src = 0,
): VideoClip {
  return {
    id,
    track,
    start,
    sourceRange: { start: src, duration: dur },
    ref,
    enabled: true,
    volume: 0,
    fadeIn: 0,
    fadeOut: 0,
    fit: "fill",
    ...more,
  };
}

/** 10 s at 25 fps: three video tracks, voice and music, every effect. */
function timeline(vertical = false): RgVideo {
  const d = newRgVideo(
    vertical
      ? { width: 360, height: 640, rate: R, aspect: "9:16" }
      : { width: 640, height: 360, rate: R, aspect: "16:9" },
  );
  d.tracks = [
    { id: "V1", kind: "Video", name: "V1", locked: false },
    { id: "V2", kind: "Video", name: "V2", locked: false },
    { id: "V3", kind: "Video", name: "V3", locked: false },
    { id: "A1", kind: "Audio", name: "Voce", locked: false },
    {
      id: "A2",
      kind: "Audio",
      name: "Musica",
      locked: false,
      duck: { under: ["A1"], amountDb: -12, attackMs: 200, releaseMs: 600 },
    },
  ];
  const land = { media: "land.mp4" };
  const port = { media: "port.mp4" };
  d.clips = [
    clip("c1", "V1", 0, 60, land, vertical ? { fit: "fit", background: "blur" } : {}, 10),
    clip("c2", "V1", 60, 50, port, {}, 20),
    clip(
      "c3",
      "V1",
      110,
      50,
      { media: "photo.jpg", still: true },
      { kenBurns: kenBurnsPreset("in", "right") },
    ),
    clip("c4", "V1", 160, 40, land, vertical ? { crop: { x: 0.34, y: 0, w: 0.32, h: 1 } } : {}, 70),
    clip("c5", "V1", 200, 50, port, { fit: "fit", background: "blur" }),
    clip("b1", "V2", 30, 40, port, { fit: "fit", fadeIn: 5, fadeOut: 5 }, 40),
    clip(
      "t1",
      "V3",
      5,
      45,
      { generator: "text", text: "Titolo di prova", style: "title", position: "center" },
      { fadeIn: 5, fadeOut: 5 },
    ),
    clip("t2", "V3", 165, 30, {
      generator: "text",
      text: "Mario Rossi, montatore",
      style: "lower_third",
      position: "lower_third",
    }),
    // J-cut into c2: its sound starts 10 frames before its picture
    clip("a1", "A1", 0, 50, land, {}, 10),
    clip("a2", "A1", 50, 60, port, { volume: -3 }, 10),
    clip("m1", "A2", 0, 250, { media: "music.m4a" }, { volume: -6, fadeOut: 25 }),
  ];
  d.transitions = [
    { id: "x1", track: "V1", from: "c1", to: "c2", kind: "dissolve", inOffset: 10, outOffset: 10 },
    { id: "x2", track: "V1", from: "c2", to: "c3", kind: "wipe_left", inOffset: 10, outOffset: 10 },
    { id: "x3", track: "V1", from: "c3", to: "c4", kind: "slide_up", inOffset: 8, outOffset: 8 },
    {
      id: "x4",
      track: "V1",
      from: "c4",
      to: "c5",
      kind: "dip_to_black",
      inOffset: 10,
      outOffset: 10,
    },
  ];
  d.captions = {
    language: "it",
    burnIn: true,
    style: "boxed",
    position: "bottom",
    segments: [
      { id: "s1", start: 5, end: 55, text: "Primo sottotitolo" },
      { id: "s2", start: 120, end: 190, text: "Il secondo attraversa più segmenti" },
    ],
  };
  return d;
}

interface Probed {
  streams: {
    codec_type: string;
    codec_name: string;
    profile?: string;
    width?: number;
    height?: number;
    pix_fmt?: string;
    color_range?: string;
    color_space?: string;
    r_frame_rate?: string;
    sample_rate?: string;
    channels?: number;
    nb_read_frames?: string;
  }[];
  format: { duration: string };
}

const probe = (file: string): Probed =>
  JSON.parse(
    execFileSync(ffprobe, [
      "-v",
      "error",
      "-count_frames",
      "-show_entries",
      "format=duration:stream=codec_type,codec_name,profile,width,height,pix_fmt,color_range,color_space,r_frame_rate,sample_rate,channels,nb_read_frames",
      "-of",
      "json",
      file,
    ]).toString(),
  );

/** The integrated loudness ebur128 prints in its summary (on stderr). */
const loudness = (file: string): number => {
  const r = spawnSync(ffmpeg, [
    "-hide_banner",
    "-nostats",
    "-i",
    file,
    "-af",
    "ebur128",
    "-f",
    "null",
    "-",
  ]);
  const summary = r.stderr.toString().split("Summary:").at(-1) ?? "";
  return Number(/I:\s+(-?[\d.]+) LUFS/.exec(summary)?.[1]);
};

describe.skipIf(!on)("video render with ffmpeg", () => {
  let dir: string;
  let media: string;
  let probes: Record<string, MediaProbe>;
  let fonts: string;

  beforeAll(async () => {
    dir = mkdtempSync(join(tmpdir(), "rg-video-docker-"));
    media = join(dir, "media");
    mkdirSync(media);
    const gen = (args: string[]) =>
      execFileSync(ffmpeg, ["-v", "error", "-y", ...args], { cwd: media });
    gen([
      "-f",
      "lavfi",
      "-i",
      "testsrc2=s=640x360:r=25:d=8",
      "-f",
      "lavfi",
      "-i",
      "sine=f=440:r=48000:d=8",
      "-c:v",
      "libx264",
      "-preset",
      "ultrafast",
      "-pix_fmt",
      "yuv420p",
      "-c:a",
      "aac",
      "-shortest",
      "land.mp4",
    ]);
    gen([
      "-f",
      "lavfi",
      "-i",
      "testsrc=s=360x640:r=30:d=6",
      "-f",
      "lavfi",
      "-i",
      "sine=f=660:r=48000:d=6",
      "-c:v",
      "libx264",
      "-preset",
      "ultrafast",
      "-pix_fmt",
      "yuv420p",
      "-c:a",
      "aac",
      "-shortest",
      "port.mp4",
    ]);
    gen(["-f", "lavfi", "-i", "mandelbrot=s=600x900", "-frames:v", "1", "photo.jpg"]);
    gen(["-f", "lavfi", "-i", "sine=f=220:r=48000:d=12", "-c:a", "aac", "music.m4a"]);
    probes = {};
    for (const m of ["land.mp4", "port.mp4", "photo.jpg", "music.m4a"])
      probes[m] = await probeMedia(ffprobe, join(media, m), R);
    // A fonts folder whose path needs escaping in the graph (not possible on Windows).
    fonts = process.platform === "win32" ? FONTS : join(dir, "font: l'Inter");
    if (fonts !== FONTS) cpSync(FONTS, fonts, { recursive: true });
  }, 120_000);
  afterAll(() => rmSync(dir, { recursive: true, force: true }));

  const target = (more: Partial<RenderTarget> = {}): RenderTarget => ({
    encoder,
    quality: "draft",
    fontsDir: fonts,
    ...more,
  });

  it("probes the files at the timeline's rate", () => {
    expect(probes["land.mp4"]).toMatchObject({ frames: 200, audio: true, width: 640, height: 360 });
    expect(probes["port.mp4"]).toMatchObject({ frames: 150, audio: true });
    expect(probes["photo.jpg"]).toMatchObject({ frames: null, audio: false });
    expect(probes["music.m4a"]).toMatchObject({ frames: 300, audio: true });
  });

  it("renders every effect to the exact frame, H.264 High BT.709 and AAC 48 kHz at −14 LUFS", async () => {
    // "good" (the default): High; "draft" (ultrafast, the exact preview) comes out as Main.
    const plan = compileVideo(timeline(), probes, target({ quality: "good" }));
    expect(plan.warnings).toEqual([]);
    const out = join(dir, "renders", "prova-v1.mp4");
    const t0 = Date.now();
    const res = await renderVideo(plan, {
      run: ffmpegRunner(ffmpeg),
      mediaPath: (m) => join(media, m),
      workDir: join(dir, "work"),
      cacheDir: join(dir, "cache"),
      out,
    });
    const seconds = (Date.now() - t0) / 1000;
    expect(res.frames).toBe(250);
    const info = probe(out);
    const v = info.streams.find((s) => s.codec_type === "video");
    const a = info.streams.find((s) => s.codec_type === "audio");
    expect(info.streams).toHaveLength(2);
    expect(v).toMatchObject({
      codec_name: "h264",
      profile: "High",
      width: 640,
      height: 360,
      pix_fmt: "yuv420p",
      color_range: "tv",
      color_space: "bt709",
      r_frame_rate: "25/1",
      nb_read_frames: "250",
    });
    expect(a).toMatchObject({ codec_name: "aac", sample_rate: "48000", channels: 2 });
    expect(Number(info.format.duration)).toBeCloseTo(10, 1);
    expect(Math.abs(loudness(out) + 14)).toBeLessThan(1);
    console.log(`render ${plan.segments.length} segments, ${seconds.toFixed(1)} s with ${encoder}`);

    // again, from the cache: only the join
    const t1 = Date.now();
    const again = await renderVideo(plan, {
      run: ffmpegRunner(ffmpeg),
      mediaPath: (m) => join(media, m),
      workDir: join(dir, "work"),
      cacheDir: join(dir, "cache"),
      out: join(dir, "renders", "prova-v2.mp4"),
    });
    expect(again.reused).toBe(new Set(plan.segments.map((s) => s.hash)).size + 1);
    expect(probe(again.path).streams[0]?.nb_read_frames).toBe("250");
    expect(Date.now() - t1).toBeLessThan(seconds * 1000);
  });

  it("vertical with a blurred background and a moved crop; subtitles as a text track; no loudnorm", async () => {
    const d = timeline(true);
    d.captions.burnIn = false;
    const plan = compileVideo(d, probes, target({ loudnorm: false }));
    const res = await renderVideo(plan, {
      run: ffmpegRunner(ffmpeg),
      mediaPath: (m) => join(media, m),
      workDir: join(dir, "work"),
      out: join(dir, "renders", "verticale.mp4"),
    });
    const info = probe(res.path);
    expect(info.streams.map((s) => s.codec_type)).toEqual(["video", "audio", "subtitle"]);
    expect(info.streams[0]).toMatchObject({ width: 360, height: 640, nb_read_frames: "250" });
    expect(info.streams[2]?.codec_name).toBe("mov_text");
    expect(res.sidecars.map((s) => s.slice(-4))).toEqual([".srt", ".vtt"]);
  });

  it("a smaller height and a timeline at 29.97 still give the exact frames", async () => {
    const d = timeline();
    d.format = { width: 1280, height: 720, rate: { num: 30000, den: 1001 }, aspect: "16:9" };
    const p = { ...probes };
    for (const k of ["land.mp4", "port.mp4", "music.m4a"])
      p[k] = await probeMedia(ffprobe, join(media, k), d.format.rate);
    const plan = compileVideo(d, p, target({ height: 360, captions: "none" }));
    expect([plan.width, plan.height]).toEqual([640, 360]);
    const res = await renderVideo(plan, {
      run: ffmpegRunner(ffmpeg),
      mediaPath: (m) => join(media, m),
      workDir: join(dir, "work"),
      out: join(dir, "renders", "ntsc.mp4"),
    });
    const v = probe(res.path).streams[0];
    expect(v).toMatchObject({
      width: 640,
      height: 360,
      r_frame_rate: "30000/1001",
      nb_read_frames: "250",
    });
  });
});
