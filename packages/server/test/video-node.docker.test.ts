// G41.7 for real: two servers in this process, the node «Coder» (no GPU, no container) rendering a
// short timeline with its own ffmpeg (found through REDGIANT_FFMPEG, measured by `MediaMachine`:
// no NVENC there, so libx264), the files copied in checked pieces and the MP4 brought back, then
// read with ffprobe. Run with REDGIANT_DOCKER_TESTS=1 and REDGIANT_FFMPEG set to an ffmpeg ≥ 9
// (ffprobe beside it, or REDGIANT_FFPROBE).
import { execFileSync } from "node:child_process";
import { existsSync } from "node:fs";
import { mkdir, writeFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import {
  type Job,
  type NodesState,
  newRgVideo,
  type PairCode,
  type PendingPair,
  type VideoClip,
  type VideoRenderResult,
  writeRgVideo,
} from "@redgiant/protocol";
import { afterAll, describe, expect, it } from "vitest";
import { MediaMachine } from "../src/editor/video/machine.js";
import { startServer } from "./helpers.js";

const ffmpeg = process.env.REDGIANT_FFMPEG ?? "";
const ffprobe =
  process.env.REDGIANT_FFPROBE ??
  join(dirname(ffmpeg), process.platform === "win32" ? "ffprobe.exe" : "ffprobe");
const on = process.env.REDGIANT_DOCKER_TESTS === "1" && !!ffmpeg && existsSync(ffmpeg);

type Server = Awaited<ReturnType<typeof startServer>>;
const open: Server[] = [];
afterAll(async () => {
  for (const s of open.reverse()) await s.close().catch(() => {});
});

async function until<T>(f: () => Promise<T | false | undefined> | T | false | undefined) {
  const end = Date.now() + 20_000;
  for (;;) {
    const v = await f();
    if (v) return v as T;
    if (Date.now() > end) throw new Error("timed out waiting");
    await new Promise((r) => setTimeout(r, 50));
  }
}

const machine = async (name: string, gpus: () => Promise<never[]>) => {
  const s = await startServer(
    [{ text: "OK" }],
    {},
    {
      nodes: { hostName: name, reconnectMs: [60], waitMs: 5000, pollMs: 0 },
      videoMedia: {
        tools: async () => ({ ffmpeg, ffprobe }),
        machine: new MediaMachine({ dataDir: "/nonexistent", gpus, canDownload: false }),
      },
    },
  );
  open.push(s);
  return s;
};

describe.skipIf(!on)("a render on a node, for real (G41.7)", () => {
  it("Coder renders a short timeline with its ffmpeg; the MP4 comes back whole", async () => {
    const severino = await machine("severino", async () => []);
    const coder = await machine("coder", async () => []);
    const code = (await severino.api<PairCode>("POST", "/api/nodes/code")).body;
    await coder.api("POST", "/api/nodes/pair", { address: severino.url, code: code.code });
    const st = async (s: Server) => (await s.api<NodesState>("GET", "/api/nodes")).body;
    const p = await st(severino);
    const n = await st(coder);
    await severino.api("POST", "/api/nodes/confirm", {
      fingerprint: (p.pending[0] as PendingPair).fingerprint,
      name: "Coder",
    });
    await coder.api("POST", "/api/nodes/confirm", {
      fingerprint: (n.pending[0] as PendingPair).fingerprint,
      rights: ["use"],
    });
    const fp = n.self.fingerprint as string;
    await until(() => severino.core.nodes.isOnline(fp));
    await severino.core.nodes.poll("me", fp);
    const caps = (await severino.core.nodes.known("me"))[0]?.view?.capabilities;
    expect(caps?.media).toMatchObject({ nvenc: false, encoder: "libx264" });
    expect(caps?.media?.ffmpeg?.major).toBeGreaterThanOrEqual(9);

    // A project with a real 3 s clip (picture and sound).
    const proj = await severino.api<{ id: string }>("POST", "/api/projects", { name: "Video" });
    const scope = `project:${proj.body.id}`;
    const root = await severino.core.scopeFolder("me", scope);
    await mkdir(join(root, "riprese"), { recursive: true });
    const src = join(root, "riprese", "clip.mp4");
    execFileSync(ffmpeg, [
      "-hide_banner",
      "-loglevel",
      "error",
      "-f",
      "lavfi",
      "-i",
      "testsrc2=s=640x360:r=25:d=3",
      "-f",
      "lavfi",
      "-i",
      "sine=f=440:d=3",
      "-c:v",
      "libx264",
      "-c:a",
      "aac",
      "-shortest",
      src,
    ]);
    const clip = (id: string, track: string): VideoClip => ({
      id,
      track,
      start: 0,
      sourceRange: { start: 0, duration: 75 },
      ref: { media: "riprese/clip.mp4", frames: 75, audio: true },
      enabled: true,
      volume: 0,
      fadeIn: 0,
      fadeOut: 0,
      fit: "fill",
    });
    const doc = newRgVideo({ width: 640, height: 360, rate: { num: 25, den: 1 }, aspect: "16:9" });
    doc.clips = [clip("v1", "V1"), clip("a1", "A1")];
    await writeFile(join(root, "film.rgvideo"), writeRgVideo(doc));

    const t0 = Date.now();
    const r = await severino.api<{ job: Job }>("POST", "/api/editor/video/render", {
      scope,
      path: "film.rgvideo",
      where: fp,
    });
    expect(r.status).toBe(200);
    let end: Job;
    for (;;) {
      end = severino.core.jobs.get("me", r.body.job.id) as Job;
      if (end.state !== "running") break;
      await new Promise((x) => setTimeout(x, 100));
    }
    expect(end.state, JSON.stringify(end.error)).toBe("done");
    const res = end.result as VideoRenderResult;
    expect(res).toMatchObject({ path: "renders/film-v1.mp4", node: "Coder", encoder: "libx264" });
    const out = execFileSync(ffprobe, [
      "-v",
      "error",
      "-count_frames",
      "-show_entries",
      "stream=codec_name,width,height,nb_read_frames,sample_rate",
      "-of",
      "json",
      join(root, res.path),
    ]).toString();
    const streams = (JSON.parse(out) as { streams: Record<string, unknown>[] }).streams;
    expect(streams.find((s) => s.codec_name === "h264")).toMatchObject({
      width: 640,
      height: 360,
      nb_read_frames: "75",
    });
    expect(streams.find((s) => s.codec_name === "aac")?.sample_rate).toBe("48000");
    console.log(`render on Coder: ${Date.now() - t0} ms`);
  }, 180_000);
});
