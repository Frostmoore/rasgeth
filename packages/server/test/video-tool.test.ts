// G41.6 on the server, with a fake ffmpeg/ffprobe: the render as a job (its bar from `-progress`
// on the fake clock, «Cancel» halfway leaving no file, the next version's name, a second render
// of the same project waiting for the first, the disk checked first), and the `video` tool from
// end to end with a scripted model (FakeProvider): inspect → analyze → assemble → frame →
// render, assembling again over an untouched draft (a version kept, nobody asked) and over one
// the person edited (asked first; their yes replaces it, a version kept).
import { existsSync } from "node:fs";
import { mkdir, mkdtemp, readdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, isAbsolute, join } from "node:path";
import {
  newRgVideo,
  PERSON,
  type RgVideo,
  readRgVideo,
  type VideoClip,
  type VideoRenderResult,
  writeRgVideo,
} from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { VideoAnalysis } from "../src/editor/video/analysis.js";
import type { MediaRunner, RunOptions } from "../src/editor/video/media-run.js";
import { nextRenderName, renderHeight, VideoRenders } from "../src/editor/video/renders.js";
import { secondsOf, wordLines } from "../src/editor/video/tool.js";
import { Jobs } from "../src/jobs.js";
import { startServer } from "./helpers.js";

const FX = join(import.meta.dirname, "fixtures", "video");
const fixture = (name: string) => readFile(join(FX, name), "utf8");
const LOUDNORM =
  '{ "input_i" : "-20.0", "input_tp" : "-2.0", "input_lra" : "3.0", "input_thresh" : "-30.0", "target_offset" : "0.1" }';

/** ffprobe answers by the file's name; ffmpeg writes its last argument, telling its progress. */
function fakeMedia(o: { hang?: (args: string[]) => boolean; tick?: () => void } = {}) {
  const calls: { program: string; args: string[] }[] = [];
  let started: (() => void) | undefined;
  const hanging = new Promise<void>((r) => {
    started = r;
  });
  const run: MediaRunner = async (program, args, opts: RunOptions = {}) => {
    calls.push({ program, args });
    if (program === "ffprobe") {
      const f = basename(args.at(-1) ?? "");
      if (/\.jpe?g$/.test(f)) return { stdout: await fixture("probe-photo.json"), stderr: "" };
      if (/\.mp3$/.test(f)) return { stdout: await fixture("probe-music.json"), stderr: "" };
      const clip = JSON.parse(await fixture("probe-clip30.json"));
      // The coverage has no sound of its own.
      if (/porto|drone/.test(f))
        clip.streams = clip.streams.filter((s: { codec_type: string }) => s.codec_type === "video");
      return { stdout: JSON.stringify(clip), stderr: "" };
    }
    if (args.some((a) => a.startsWith("silencedetect"))) {
      for (const l of (await fixture("silencedetect-clip30.txt")).split("\n"))
        opts.onStderrLine?.(l);
      return { stdout: "", stderr: "" };
    }
    if (args.includes("null")) return { stdout: "", stderr: LOUDNORM };
    const out = args.at(-1) as string;
    const abs = isAbsolute(out) ? out : join(opts.cwd ?? ".", out);
    if (o.hang?.(args)) {
      await writeFile(abs, "half");
      started?.();
      await new Promise<void>((_, no) => {
        const stop = () => {
          const e = new Error("cancelled");
          e.name = "AbortError";
          no(e);
        };
        if (opts.signal?.aborted) stop();
        else opts.signal?.addEventListener("abort", stop);
      });
    }
    for (const us of [250_000, 500_000, 1_000_000]) {
      o.tick?.();
      opts.onStdoutLine?.(`out_time_us=${us}`);
    }
    await writeFile(abs, abs.endsWith(".pcm") ? Buffer.alloc(30 * 32000) : `made by ${program}`);
    return { stdout: "", stderr: "" };
  };
  return { run, calls, hanging };
}

const R = { num: 25, den: 1 };
const clip = (id: string, track: string, start: number, dur: number, media = "clip.mp4") =>
  ({
    id,
    track,
    start,
    sourceRange: { start: 0, duration: dur },
    ref: { media, frames: 750, audio: true },
    enabled: true,
    volume: 0,
    fadeIn: 0,
    fadeOut: 0,
    fit: "fill",
  }) as VideoClip;
function film(): RgVideo {
  const d = newRgVideo({ width: 1280, height: 720, rate: R, aspect: "16:9" });
  d.clips = [clip("v1", "V1", 0, 100), clip("a1", "A1", 0, 100)];
  return d;
}

let dir: string;
beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-video-tool-"));
});
afterEach(async () => {
  await rm(dir, { recursive: true, force: true });
});

describe("pure helpers", () => {
  it.each<[string[], string]>([
    [[], "film-v1.mp4"],
    [["film-v1.mp4", "film-v3.mp4", "other-v9.mp4", "film-v2.srt"], "film-v4.mp4"],
    [["FILM-V2.mp4"], "film-v3.mp4"],
  ])("nextRenderName after %j is %s", (names, want) => {
    expect(nextRenderName("film", names)).toBe(want);
  });
  it.each([
    [1920, 1080, 720, 720],
    [1080, 1920, 720, 1280],
    [1080, 1080, 480, 480],
  ])("a %d×%d timeline at short side %d is %d high", (w, h, short, want) => {
    expect(renderHeight({ format: { width: w, height: h, rate: R, aspect: "free" } }, short)).toBe(
      want,
    );
  });
  it.each<[unknown, number | undefined]>([
    [4, 4],
    ["4s", 4],
    ["2.5", 2.5],
    ["1:02.5", 62.5],
    ["00:00:04:15", 4.5],
    ["later", undefined],
    [-1, undefined],
  ])("secondsOf(%j) at 30 fps", (v, want) => {
    expect(secondsOf(v, 30)).toBe(want);
  });
  it("words as timed lines, a new one at a sentence's end or a pause", () => {
    const w = (text: string, start: number) => ({ text, start, end: start + 0.4 });
    expect(
      wordLines([w("Ciao", 0), w("a", 0.5), w("tutti.", 1), w("Oggi", 1.5), w("porto", 4)]),
    ).toBe("[0.0–1.4] Ciao a tutti.\n[1.5–1.9] Oggi\n[4.0–4.4] porto");
  });
});

describe("VideoRenders", () => {
  const setup = (o: Parameters<typeof fakeMedia>[0] = {}, free?: number) => {
    let now = Date.parse("2026-11-17T10:00:00Z");
    const jobs = new Jobs(() => now);
    /** The render's bar as the page reads it, a second apart on the fake clock. */
    const bars: { done: number; rate: number | null }[] = [];
    const fake = fakeMedia({
      ...o,
      tick: () => {
        now += 1000;
        const j = jobs.list("me").find((x) => x.kind === "video_render" && x.state === "running");
        const p = j?.steps.find((x) => x.id === "video_render")?.progress;
        if (p) bars.push({ done: p.done, rate: p.rate });
      },
    });
    const tools = async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" });
    const analysis = new VideoAnalysis({
      dataDir: join(dir, "data"),
      jobs,
      tools,
      transcriber: async () => undefined,
      run: fake.run,
    });
    const renders = new VideoRenders({
      analysis,
      jobs,
      tools,
      run: fake.run,
      fontsDir: "/fonts",
      ...(free !== undefined && { free: async () => free }),
    });
    return { jobs, fake, renders, bars };
  };
  const ask = async (renders: VideoRenders, doc = film()) => {
    const root = join(dir, "project");
    await mkdir(root, { recursive: true });
    await writeFile(join(root, "clip.mp4"), Buffer.alloc(4096, 1));
    return renders.start("me", {
      doc,
      name: "film.rgvideo",
      queue: "me\nproject:p",
      root,
      path: "film.rgvideo",
      mediaPath: async (m) => join(root, m),
      height: 720,
    });
  };

  it("renders into renders/<name>-v<n>.mp4 with its bar, then the next version", async () => {
    const { jobs, renders, fake, bars } = setup();
    const job = await ask(renders);
    expect(job.kind).toBe("video_render");
    const end = await jobs.settled(job.id, 5);
    expect(end?.state).toBe("done");
    const r = end?.result as VideoRenderResult;
    expect(r).toMatchObject({ path: "renders/film-v1.mp4", width: 1280, height: 720 });
    expect(end?.steps.map((s) => [s.id, s.state])).toEqual([
      ["tool_download", "skipped"],
      ["tool_unpack", "skipped"],
      ["video_wait", "skipped"],
      ["video_probe", "done"],
      ["video_render", "done"],
      ["video_save", "done"],
    ]);
    expect(await readFile(join(dir, "project", "renders", "film-v1.mp4"), "utf8")).toMatch(
      /made by/,
    );
    // ffmpeg's `-progress` lines made the bar move, with a rate (the fake clock: a second a line).
    expect(fake.calls.some((c) => c.args.includes("-progress"))).toBe(true);
    expect(bars.length).toBeGreaterThan(2);
    for (let k = 1; k < bars.length; k++)
      expect(bars[k]?.done).toBeGreaterThanOrEqual(bars[k - 1]?.done ?? 0);
    expect(bars.at(-1)?.done).toBeLessThanOrEqual(100);
    expect(bars.some((b) => b.rate !== null)).toBe(true);
    const again = await jobs.settled((await ask(renders)).id, 5);
    expect((again?.result as VideoRenderResult | undefined)?.path).toBe("renders/film-v2.mp4");
    // Every segment came from the cache the second time.
    expect((again?.result as VideoRenderResult | undefined)?.reused).toBeGreaterThan(0);
  });

  it("«Cancel» halfway stops ffmpeg and leaves no file", async () => {
    const { jobs, renders, fake } = setup({
      hang: (args) => args.some((a) => a.endsWith(".part.mp4")),
    });
    const job = await ask(renders);
    await fake.hanging;
    expect(jobs.get("me", job.id)?.steps.find((s) => s.id === "video_render")?.state).toBe(
      "running",
    );
    jobs.cancel("me", job.id);
    expect((await jobs.settled(job.id, 5))?.state).toBe("cancelled");
    const out = join(dir, "project", "renders");
    expect((await readdir(out)).filter((f) => f.endsWith(".mp4"))).toEqual([]);
    expect(existsSync(join(dir, "data", "cache", "video", "work"))).toBe(true);
    expect(await readdir(join(dir, "data", "cache", "video", "work"))).toEqual([]);
  });

  it("a second render of the same project waits for the first", async () => {
    let first: (() => void) | undefined;
    const gate = new Promise<void>((r) => {
      first = r;
    });
    let waiting = true;
    const { jobs, renders, fake } = setup({
      hang: (args) => waiting && args.some((a) => a.endsWith(".part.mp4")),
    });
    const one = await ask(renders);
    await fake.hanging;
    const two = await ask(renders);
    await new Promise((r) => setTimeout(r, 30));
    expect(jobs.get("me", two.id)?.steps.find((s) => s.id === "video_wait")?.state).toBe("running");
    waiting = false;
    jobs.cancel("me", one.id);
    first?.();
    await gate;
    expect((await jobs.settled(one.id, 5))?.state).toBe("cancelled");
    const end = await jobs.settled(two.id, 5);
    expect(end?.state).toBe("done");
    expect((end?.result as VideoRenderResult | undefined)?.path).toBe("renders/film-v1.mp4");
    expect(renders.busy("me\nproject:p")).toBe(false);
  });

  it("not enough disk: refused before ffmpeg runs", async () => {
    const { jobs, renders, fake } = setup({}, 1024);
    const end = await jobs.settled((await ask(renders)).id, 5);
    expect(end).toMatchObject({ state: "failed", error: { code: "video_disk" } });
    expect(fake.calls.filter((c) => c.program === "ffmpeg")).toEqual([]);
  });
});

// ---- from end to end ----------------------------------------------------------------------

type Req = {
  messages: { role: string; parts: { type: string; content?: string; images?: unknown[] }[] }[];
};
/** The last tool's result, and the pictures that follow it in the same message. */
const resultOf = (req: Req) => {
  const parts = req.messages.at(-1)?.parts ?? [];
  const r = parts.find((p) => p.type === "tool_result") as { content: string } | undefined;
  return r && { content: r.content, images: parts.filter((p) => p.type === "image") };
};
function calls(
  list: { name: string; input: unknown }[],
  seen: { content: string; images?: unknown[] }[],
) {
  let i = 0;
  return (req: Req) => {
    const r = resultOf(req);
    if (r !== undefined) seen.push(r);
    const next = list[i++];
    return next ? { toolCalls: [next] } : { text: "Done." };
  };
}

describe("the video tool from end to end (FakeProvider)", () => {
  let s: Awaited<ReturnType<typeof startServer>> | undefined;
  afterEach(async () => {
    await s?.close();
    s = undefined;
  });

  it("inspect, analyze, assemble, frame, render; assembling again keeps a version", {
    timeout: 20_000,
  }, async () => {
    const seen: { content: string; images?: unknown[] }[] = [];
    const fake = fakeMedia();
    const path = "video/montaggio.rgvideo";
    s = await startServer(
      calls(
        [
          { name: "video", input: { action: "inspect", files: ["video/riprese/"] } },
          { name: "video", input: { action: "analyze", files: ["video/riprese/intervista.mp4"] } },
          {
            name: "video",
            input: {
              action: "assemble",
              path,
              files: ["video/riprese/", "video/musica.mp3"],
              brief: "Un minuto sulla gita al porto",
            },
          },
          {
            name: "video",
            input: { action: "frame", file: "video/riprese/porto.mp4", every: "10s" },
          },
          { name: "video", input: { action: "render", path, quality: "draft", height: 720 } },
          {
            name: "video",
            input: { action: "assemble", path, files: ["video/riprese/"], music: false },
          },
          { name: "video", input: { action: "inspect", files: [path] } },
        ],
        seen,
      ) as never,
      { contextWindow: 65_536 },
      {
        editor: { saveDelayMs: 0, watchMs: 0 },
        videoMedia: {
          tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
          run: fake.run,
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
    await mkdir(join(root, "video", "riprese"), { recursive: true });
    for (const f of ["intervista.mp4", "porto.mp4", "drone.mp4", "cima.jpg"])
      await writeFile(join(root, "video", "riprese", f), Buffer.alloc(8192, f.length));
    await writeFile(join(root, "video", "musica.mp3"), Buffer.alloc(4096, 9));

    await (await s.core.send("me", sessionId, "Monta le riprese della gita")).done;
    const [inspect, analyze, assemble, frame, render, again, check] = seen;
    expect(inspect?.content).toContain(
      "video/riprese/intervista.mp4: video 1280×720 25 fps, 30.0 s, with sound",
    );
    expect(inspect?.content).toContain("video/riprese/cima.jpg: picture");
    expect(analyze?.content).toMatch(/speech 50% \(15\.0 s, from the sound's level/);
    expect(analyze?.content).toContain("A, carries the story");
    expect(analyze?.content).toMatch(/silences proposed as cuts/);
    expect(assemble?.content).toMatch(
      /^Assembled into video\/montaggio\.rgvideo \(a new timeline\)/,
    );
    expect(assemble?.content).toContain("Speech on V1/A1: video/riprese/intervista.mp4");
    expect(assemble?.content).toContain("Music on A3 (ducked under A1): video/musica.mp3");
    expect(frame?.images).toHaveLength(3);
    expect(frame?.content).toMatch(
      /Frames: 0:00\.0 \(picture 1\); 0:10\.0 \(picture 2\); 0:20\.0 \(picture 3\)/,
    );
    expect(render?.content).toMatch(/^Rendered renders\/montaggio-v1\.mp4: 1280×720/);
    expect(existsSync(join(root, "renders", "montaggio-v1.mp4"))).toBe(true);
    // Over the untouched draft: replaced at once, the one before kept as a version.
    expect(again?.content).toMatch(/^Assembled into video\/montaggio\.rgvideo as revision 1/);
    expect(again?.content).toMatch(/kept as the version video\/montaggio\.versions\//);
    expect(check?.content).toMatch(/timeline «montaggio» 1280×720/);
    await s.core.editor.flush();
    const versions = await readdir(join(root, "video", "montaggio.versions"));
    expect(versions).toHaveLength(1);
    const kept = readRgVideo(
      await readFile(join(root, "video", "montaggio.versions", versions[0] as string), "utf8"),
    );
    expect(kept.version).toMatchObject({ reason: "before_assemble", of: path });
    // The first draft, as the version: its brief, the speech on V1, the music on A3.
    expect(kept.assembled?.brief).toBe("Un minuto sulla gita al porto");
    expect(kept.clips.filter((c) => c.track === "V1").length).toBeGreaterThan(0);
    expect(kept.clips.some((c) => c.track === "A3")).toBe(true);
    const now = readRgVideo(await readFile(join(root, path), "utf8"));
    expect(now.clips.some((c) => c.track === "A3")).toBe(false);
    // The canvas showed the timeline and the video.
    const shown = (await s.core.store.list({ sessionId })).filter((e) => e.type === "canvas.show");
    expect(shown.map((e) => (e.payload as { title: string }).title)).toEqual([
      "montaggio.rgvideo",
      "montaggio-v1.mp4",
      "montaggio.rgvideo",
    ]);
  });

  it("over a timeline the person edited it asks first: no keeps it, yes replaces it", {
    timeout: 20_000,
  }, async () => {
    const seen: { content: string }[] = [];
    const fake = fakeMedia();
    const path = "montaggio.rgvideo";
    const assemble = { name: "video", input: { action: "assemble", path, files: ["riprese/"] } };
    s = await startServer(
      calls([assemble, assemble], seen) as never,
      { contextWindow: 65_536 },
      {
        editor: { saveDelayMs: 0, watchMs: 0 },
        videoMedia: {
          tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
          run: fake.run,
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
    await writeFile(join(root, "riprese", "intervista.mp4"), Buffer.alloc(8192, 3));
    await writeFile(join(root, "riprese", "porto.mp4"), Buffer.alloc(8192, 4));
    // The person's own timeline, made by hand.
    const own = film();
    own.name = "Mia";
    own.clips = own.clips.map((c) => ({
      ...c,
      ref: { media: "riprese/intervista.mp4", frames: 750, audio: true },
    }));
    await writeFile(join(root, path), writeRgVideo(own));
    const answers = ["Keep it", "Replace it"];
    const answering = (async () => {
      for (const a of answers) {
        let q = s?.core.questions.list("me")[0];
        while (!q) {
          await new Promise((r) => setTimeout(r, 10));
          q = s?.core.questions.list("me")[0];
        }
        expect(q.questions[0]?.question).toMatch(/Replace the timeline «Mia»/);
        s?.core.questions.answer("me", q.requestId, [[a]], "web");
        await new Promise((r) => setTimeout(r, 30));
      }
    })();
    await (await s.core.send("me", sessionId, "Rifai il montaggio")).done;
    await answering;
    expect(seen[0]?.content).toMatch(/^Nothing replaced: the person kept the timeline/);
    expect(seen[1]?.content).toMatch(/^Assembled into montaggio\.rgvideo as revision 1/);
    await s.core.editor.flush();
    const versions = await readdir(join(root, "montaggio.versions"));
    expect(versions).toHaveLength(1);
    expect(
      readRgVideo(await readFile(join(root, "montaggio.versions", versions[0] as string), "utf8"))
        .name,
    ).toBe("Mia");
    // «Undo» brings the person's timeline back.
    const back = await s.core.editor.undo(
      "me",
      { scope: "platform", path },
      { revision: 1 },
      { id: PERSON },
    );
    expect(back).toMatchObject({ ok: true });
    await s.core.editor.flush();
    expect(readRgVideo(await readFile(join(root, path), "utf8")).name).toBe("Mia");
  });
});
