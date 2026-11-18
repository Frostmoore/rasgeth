// G41.6b on the server: the timeline exported beside itself for DaVinci Resolve (FCP7 XML, the
// same text as montatore's) or as OpenTimelineIO, with the files pointing where Resolve finds
// them (the person's folder of originals, D21, or this machine); the page's route; the `video`
// tool from end to end with a scripted model (export both ways, then import the .otio again).
import { existsSync } from "node:fs";
import { mkdir, mkdtemp, readdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import {
  fcp7Xml,
  type MediaProbe,
  newRgVideo,
  type RgVideo,
  readRgVideo,
  resolveJob,
  type VideoClip,
  type VideoExportResult,
  writeRgVideo,
} from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { exportText, exportTimeline, VideoExportRateError } from "../src/editor/video/export.js";
import type { MediaRunner } from "../src/editor/video/media-run.js";
import { startServer } from "./helpers.js";

const FX = join(import.meta.dirname, "fixtures", "video");

const probe = (o: Partial<MediaProbe>): MediaProbe => ({
  kind: "video",
  duration: 30,
  width: 1920,
  height: 1080,
  rotation: 0,
  rate: { num: 25, den: 1 },
  codec: "h264",
  audio: true,
  audioCodec: "aac",
  sampleRate: 48000,
  channels: 2,
  timecode: null,
  createdAt: null,
  size: 1,
  ...o,
});

const clip = (id: string, track: string, start: number, dur: number, media: string, from = 0) =>
  ({
    id,
    track,
    start,
    sourceRange: { start: from, duration: dur },
    ref: { media },
    enabled: true,
    volume: 0,
    fadeIn: 0,
    fadeOut: 0,
    fit: "fill",
  }) as VideoClip;

function film(): RgVideo {
  const d = newRgVideo({ width: 1920, height: 1080, rate: { num: 25, den: 1 } }, "Gita al porto");
  d.tracks.push({ id: "V2", kind: "Video", name: "V2", locked: false, hidden: true });
  d.clips = [
    clip("v1", "V1", 0, 100, "riprese/intervista.mp4", 50),
    { ...clip("v2", "V2", 25, 50, "riprese/porto.mp4"), fadeIn: 10 },
    clip("a1", "A1", 0, 100, "riprese/intervista.mp4", 50),
    {
      ...clip("t1", "V2", 100, 25, ""),
      ref: { generator: "text", text: "Fine", style: "title", position: "center" },
    },
  ];
  return d;
}

let dir: string;
beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-video-export-"));
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

describe("exportTimeline", () => {
  const facts: Record<string, MediaProbe> = {
    "riprese/intervista.mp4": probe({ timecode: "10:00:00:00", duration: 30 }),
    "riprese/porto.mp4": probe({
      width: 3840,
      height: 2160,
      audio: false,
      sampleRate: null,
      channels: null,
    }),
  };
  const request = (doc: RgVideo, format: "resolve" | "otio", mediaRoot?: string) => ({
    doc,
    abs: join(dir, "video", "gita.rgvideo"),
    path: "video/gita.rgvideo",
    root: join(dir, "video"),
    format,
    ...(mediaRoot !== undefined && { mediaRoot }),
    mediaAbs: async (m: string) => (facts[m] ? join(dir, "video", m) : undefined),
    probe: async (abs: string) => facts[abs.slice(join(dir, "video").length + 1)],
  });

  it("writes montatore's XML beside the timeline, the files in the person's folder (D21)", async () => {
    await mkdir(join(dir, "video"), { recursive: true });
    const r = await exportTimeline(request(film(), "resolve", "E:\\Video\\Gita\\"));
    expect(r).toMatchObject({
      path: "video/gita.xml",
      format: "resolve",
      clips: 3,
      files: 2,
      mediaRoot: "E:\\Video\\Gita\\",
      example: "E:\\Video\\Gita\\intervista.mp4",
    });
    expect(r.leftOut).toMatchObject({ titles: 1, fades: 1, missing: [] });
    const xml = await readFile(join(dir, "video", "gita.xml"), "utf8");
    // The same text as the protocol's generator (byte for byte montatore's, video-resolve.test).
    const { job } = resolveJob(film(), facts, {
      name: "Gita al porto",
      path: (m) => `E:\\Video\\Gita\\${basename(m)}`,
    });
    expect(xml).toBe(fcp7Xml(job));
    expect(xml).toContain("<pathurl>file://localhost/E%3a/Video/Gita/intervista.mp4</pathurl>");
    expect(xml).toContain("<string>10:00:00:00</string>");
    expect(xml).toContain("<frame>900000</frame>");
    expect(xml).toContain("<width>3840</width>");
    // Nothing half-written is left.
    expect(await readdir(join(dir, "video"))).toEqual(["gita.xml"]);
    const text = exportText(r);
    expect(text).toContain(
      "Saved video/gita.xml (FCP7 XML for DaVinci Resolve): 3 clip(s) of 2 file(s).",
    );
    expect(text).toContain("Files point to E:\\Video\\Gita\\ by their names");
    expect(text).toContain(
      "Not in the XML (redo them in Resolve, as montatore does): 1 title/colour clip(s), 1 clip(s) with fades.",
    );
  });

  it("without a folder the files point to this machine; a missing file is said", async () => {
    await mkdir(join(dir, "video"), { recursive: true });
    const d = film();
    d.clips.push(clip("v3", "V1", 200, 10, "riprese/sparito.mov"));
    const r = await exportTimeline(request(d, "resolve", "  "));
    expect(r.mediaRoot).toBeUndefined();
    expect(r.example).toBe(join(dir, "video", "riprese", "intervista.mp4"));
    expect(r.leftOut.missing).toEqual(["riprese/sparito.mov"]);
    const xml = await readFile(join(dir, "video", "gita.xml"), "utf8");
    expect(xml).toContain(
      `<pathurl>file://localhost${join(dir, "video", "riprese", "sparito.mov")}</pathurl>`,
    );
    expect(exportText(r)).toContain(
      "Not found here (exported with what the timeline knows): riprese/sparito.mov.",
    );
  });

  it("writes the .otio beside it, read back to the same timeline", async () => {
    await mkdir(join(dir, "video"), { recursive: true });
    const r = await exportTimeline(request(film(), "otio"));
    expect(r.path).toBe("video/gita.otio");
    const otio = JSON.parse(await readFile(join(dir, "video", "gita.otio"), "utf8"));
    expect(otio.OTIO_SCHEMA).toBe("Timeline.1");
    expect(otio.name).toBe("Gita al porto");
    expect(exportText(r)).toContain("OpenTimelineIO");
  });

  it("refuses a rate without timecode for Resolve, and writes nothing", async () => {
    await mkdir(join(dir, "video"), { recursive: true });
    const d = film();
    d.format.rate = { num: 12, den: 1 };
    await expect(exportTimeline(request(d, "resolve"))).rejects.toThrow(VideoExportRateError);
    expect(await readdir(join(dir, "video"))).toEqual([]);
    // OTIO has no such limit.
    await expect(exportTimeline(request(d, "otio"))).resolves.toMatchObject({ format: "otio" });
  });
});

/** ffprobe answers from the fixtures (the interview with the camera's timecode). */
const fakeProbe: MediaRunner = async (program, args) => {
  if (program !== "ffprobe") return { stdout: "", stderr: "" };
  const clip30 = JSON.parse(await readFile(join(FX, "probe-clip30.json"), "utf8"));
  if (/intervista/.test(args.at(-1) ?? "")) clip30.streams[0].tags.timecode = "09:59:58:00";
  return { stdout: JSON.stringify(clip30), stderr: "" };
};

type Req = { messages: { parts: { type: string; content?: string }[] }[] };
const resultOf = (req: Req) => {
  const parts = req.messages.at(-1)?.parts ?? [];
  const r = parts.find((p) => p.type === "tool_result") as { content: string } | undefined;
  return r?.content;
};

describe("the route and the video tool", () => {
  let s: Awaited<ReturnType<typeof startServer>> | undefined;
  afterEach(async () => {
    await s?.close();
    s = undefined;
  });

  it("export both ways from the tool and the page, then import the .otio", {
    timeout: 20_000,
  }, async () => {
    const seen: string[] = [];
    const list = [
      { name: "video", input: { action: "export", path: "video/gita.rgvideo" } },
      {
        name: "video",
        input: {
          action: "export",
          path: "video/gita.rgvideo",
          format: "resolve",
          media_root: "D:/Riprese",
        },
      },
      { name: "video", input: { action: "export", path: "video/gita.rgvideo", format: "otio" } },
      { name: "video", input: { action: "import", file: "video/gita.otio" } },
      {
        name: "video",
        input: { action: "import", file: "video/gita.otio", path: "video/copia.rgvideo" },
      },
    ];
    let i = 0;
    s = await startServer(
      ((req: Req) => {
        const r = resultOf(req);
        if (r !== undefined) seen.push(r);
        const next = list[i++];
        return next ? { toolCalls: [next] } : { text: "Done." };
      }) as never,
      { contextWindow: 65_536 },
      {
        editor: { saveDelayMs: 0, watchMs: 0 },
        videoMedia: {
          tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
          run: fakeProbe,
        },
      },
    );
    const g = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const sessionId = (
      await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g.body.id })
    ).body.sessionId;
    const root = await s.core.scopeFolder("me", "platform");
    await mkdir(join(root, "riprese"), { recursive: true });
    await mkdir(join(root, "video"), { recursive: true });
    for (const f of ["intervista.mp4", "porto.mp4"])
      await writeFile(join(root, "riprese", f), Buffer.alloc(8192, f.length));
    await writeFile(join(root, "video", "gita.rgvideo"), writeRgVideo(film()));

    await (await s.core.send("me", sessionId, "Esporta per Resolve")).done;
    const [noFormat, resolve, otio, imported, copy] = seen;
    expect(noFormat).toMatch(/Nothing done: give "format"/);
    expect(resolve).toContain(
      "Saved video/gita.xml (FCP7 XML for DaVinci Resolve): 3 clip(s) of 2 file(s).",
    );
    expect(resolve).toContain(
      "Files point to D:/Riprese by their names (e.g. D:/Riprese/intervista.mp4)",
    );
    const xml = await readFile(join(root, "video", "gita.xml"), "utf8");
    expect(xml).toContain("<pathurl>file://localhost/D%3a/Riprese/intervista.mp4</pathurl>");
    expect(xml).toContain("<string>09:59:58:00</string>");
    expect(otio).toContain("Saved video/gita.otio (OpenTimelineIO)");
    expect(imported).toMatch(/Nothing done: video\/gita\.rgvideo exists already/);
    expect(copy).toContain(
      "Read gita.otio into video/copia.rgvideo: 3 tracks, 4 clip(s); shown to the person.",
    );
    const back = readRgVideo(await readFile(join(root, "video", "copia.rgvideo"), "utf8"));
    expect(back.clips).toEqual(readRgVideo(writeRgVideo(film())).clips);

    // The page's route: the same file, with the folder the person typed.
    const r = await s.api<{ result: VideoExportResult }>("POST", "/api/editor/video/export", {
      scope: "platform",
      path: "video/gita.rgvideo",
      format: "resolve",
      mediaRoot: "E:\\Video",
    });
    expect(r.status).toBe(200);
    expect(r.body.result).toMatchObject({
      path: "video/gita.xml",
      clips: 3,
      example: "E:\\Video\\intervista.mp4",
    });
    expect(await readFile(join(root, "video", "gita.xml"), "utf8")).toContain(
      "<pathurl>file://localhost/E%3a/Video/intervista.mp4</pathurl>",
    );
    const bad = await s.api<{ error: string }>("POST", "/api/editor/video/export", {
      scope: "platform",
      path: "video/gita.rgvideo",
      format: "fcpx",
    });
    expect(bad.status).toBe(400);
    expect(existsSync(join(root, "video", "gita.otio"))).toBe(true);
  });
});
