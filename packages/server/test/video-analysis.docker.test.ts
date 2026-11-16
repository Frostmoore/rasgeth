// G41.4 with the real programs: ffmpeg and ffprobe (9.0.x, from REDGIANT_FFMPEG / REDGIANT_FFPROBE
// or the PATH) on clips made here with `testsrc2` and `sine`, and whisper.cpp's whisper-cli when
// REDGIANT_WHISPER_CLI and REDGIANT_WHISPER_MODEL say where (no model is downloaded here). Run with
// REDGIANT_DOCKER_TESTS=1 pnpm test:docker.
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdtemp, readdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { MediaAnalysis } from "@redgiant/protocol";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { mediaFingerprint, VideoAnalysis } from "../src/editor/video/analysis.js";
import { Jobs } from "../src/jobs.js";

const on = process.env.REDGIANT_DOCKER_TESTS === "1";
const ffmpeg = process.env.REDGIANT_FFMPEG || "ffmpeg";
const ffprobe = process.env.REDGIANT_FFPROBE || "ffprobe";
const whisper = process.env.REDGIANT_WHISPER_CLI;
const model = process.env.REDGIANT_WHISPER_MODEL;

const make = (args: string[]) =>
  execFileSync(ffmpeg, ["-hide_banner", "-loglevel", "error", "-y", ...args], { stdio: "pipe" });
const probeJson = (file: string, args: string[]) =>
  JSON.parse(
    execFileSync(ffprobe, ["-v", "error", "-print_format", "json", ...args, file], {
      encoding: "utf8",
    }),
  ) as Record<string, unknown>;

describe.skipIf(!on)("video analysis with the real ffmpeg", () => {
  let dir: string;
  let clip: string;
  let long: string;
  const jobs = new Jobs();
  let service: VideoAnalysis;

  beforeAll(async () => {
    dir = await mkdtemp(join(tmpdir(), "rg-video-real-"));
    clip = join(dir, "clip.mp4");
    // 12 s, 1920x1080 at 29.97: a tone from 2 to 5 s and from 8 to 10 s, quiet elsewhere.
    make([
      "-f",
      "lavfi",
      "-i",
      "testsrc2=s=1920x1080:r=30000/1001:d=12",
      "-f",
      "lavfi",
      "-i",
      "aevalsrc='if(between(t,2,5)+between(t,8,10),0.5*sin(2*PI*440*t),0)':s=48000:d=12",
      "-c:v",
      "libx264",
      "-preset",
      "ultrafast",
      "-c:a",
      "aac",
      "-shortest",
      clip,
    ]);
    long = join(dir, "long.mp4");
    make([
      "-f",
      "lavfi",
      "-i",
      "testsrc2=s=1920x1080:r=30:d=60",
      "-c:v",
      "libx264",
      "-preset",
      "ultrafast",
      long,
    ]);
    service = new VideoAnalysis({
      dataDir: join(dir, "data"),
      jobs,
      tools: async () => ({ ffmpeg, ffprobe }),
      transcriber: async () =>
        whisper && model ? { kind: "cli", program: whisper, model } : undefined,
      language: () => "it",
    });
  }, 120_000);

  afterAll(async () => {
    await rm(dir, { recursive: true, force: true });
  });

  it("probe, silences and speech from the sound", async () => {
    const a: MediaAnalysis = await service.analysis("u", clip, "clip.mp4");
    expect(a.probe).toMatchObject({
      kind: "video",
      width: 1920,
      height: 1080,
      rate: { num: 30000, den: 1001 },
      audio: true,
    });
    expect(a.probe.duration).toBeCloseTo(12, 0);
    expect(a.silent.length).toBe(3);
    expect(a.silent[0]?.[1]).toBeCloseTo(2, 1);
    expect(a.silent[1]?.[0]).toBeCloseTo(5, 1);
    expect(a.silent[1]?.[1]).toBeCloseTo(8, 1);
    if (!whisper) expect(a.speech).toMatchObject({ source: "sound", role: "A" });
  }, 120_000);

  it("proxy in the 960 box with a keyframe every 10, strip and waveform", async () => {
    const proxy = await service.derived("u", clip, "clip.mp4", "proxy");
    const s = (probeJson(proxy.path, ["-show_streams"]).streams as Record<string, unknown>[]) ?? [];
    expect(s.find((x) => x.codec_type === "video")).toMatchObject({
      codec_name: "h264",
      width: 960,
      height: 540,
      pix_fmt: "yuv420p",
    });
    expect(s.find((x) => x.codec_type === "audio")).toMatchObject({
      codec_name: "aac",
      channels: 2,
    });
    const frames = probeJson(proxy.path, [
      "-select_streams",
      "v:0",
      "-show_entries",
      "frame=key_frame",
    ]).frames as { key_frame: number }[];
    const keys = frames.map((f, i) => (f.key_frame ? i : -1)).filter((i) => i >= 0);
    expect(keys.slice(0, 4)).toEqual([0, 10, 20, 30]);
    const strip = await service.derived("u", clip, "clip.mp4", "filmstrip");
    const st = (probeJson(strip.path, ["-show_streams"]).streams as Record<string, unknown>[])[0];
    expect(st).toMatchObject({ width: 160 * 12, height: 90 });
    const wave = await service.derived("u", clip, "clip.mp4", "waveform");
    const wv = (probeJson(wave.path, ["-show_streams"]).streams as Record<string, unknown>[])[0];
    expect(wv).toMatchObject({ width: 480, height: 64, codec_name: "png" });
  }, 180_000);

  it("«Cancel» on a long proxy kills ffmpeg and leaves no file", async () => {
    const job = await service.derive("u", long, "long.mp4", "proxy");
    for (let i = 0; i < 400; i++) {
      const j = jobs.get("u", job.id);
      if (j?.steps.find((x) => x.id === "video_derive")?.progress) break;
      await new Promise((r) => setTimeout(r, 50));
    }
    expect(jobs.cancel("u", job.id)).toBe(true);
    expect((await jobs.settled(job.id))?.state).toBe("cancelled");
    const fp = await mediaFingerprint(long);
    const left = existsSync(service.dirOf(fp)) ? await readdir(service.dirOf(fp)) : [];
    expect(left.filter((f) => f.startsWith("proxy"))).toEqual([]);
  }, 180_000);
});
