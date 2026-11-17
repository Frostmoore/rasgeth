// G41.7: a render on a node the person chose, with two real servers in this process (PGlite,
// FakeProvider, their own keychains) and a fake ffmpeg on the node. The `media` operation needs
// «use» alone (R1, no container here); its files stay in the asker's folder; pieces resume after a
// reconnect and a wrong SHA-256 is refused; the render's progress comes in pieces; «Cancel» stops
// the copy and the render on the node; a node that goes away is a clear error with no file left;
// the person's choice is asked at the first render and remembered (R2), and an agent cannot
// change it.
import { existsSync } from "node:fs";
import { mkdir, mkdtemp, readdir, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { isAbsolute, join } from "node:path";
import {
  type FfmpegInfo,
  type Job,
  type NodesState,
  newRgVideo,
  type PairCode,
  type PendingPair,
  type RenderMachine,
  type RgVideo,
  type VideoClip,
  type VideoRenderResult,
  writeRgVideo,
} from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { fixedMachine } from "../src/editor/video/machine.js";
import type { MediaRunner, RunOptions } from "../src/editor/video/media-run.js";
import { confineInputs } from "../src/nodes/media.js";
import { PIECE, pieceState, putPiece } from "../src/nodes/pieces.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
const open: { close: () => Promise<unknown> }[] = [];
afterEach(async () => {
  for (const s of open.splice(0).reverse()) await s.close().catch(() => {});
}, 60_000);

async function until<T>(
  f: () => Promise<T | undefined | false> | T | undefined | false,
  ms = 10_000,
): Promise<T> {
  const end = Date.now() + ms;
  for (;;) {
    const v = await f();
    if (v) return v as T;
    if (Date.now() > end) throw new Error("timed out waiting");
    await new Promise((r) => setTimeout(r, 20));
  }
}

const FX = join(import.meta.dirname, "fixtures", "video");
const LOUDNORM =
  '{ "input_i" : "-20.0", "input_tp" : "-2.0", "input_lra" : "3.0", "input_thresh" : "-30.0", "target_offset" : "0.1" }';

/** The node's ffmpeg: ffprobe answers from a fixture, ffmpeg writes its output with progress. */
function fakeMedia(o: { hang?: (args: string[]) => boolean } = {}) {
  const calls: { program: string; args: string[] }[] = [];
  const state = { aborted: 0, hanging: false };
  const run: MediaRunner = async (program, args, opts: RunOptions = {}) => {
    calls.push({ program, args });
    if (program === "ffprobe")
      return { stdout: await readFile(join(FX, "probe-clip30.json"), "utf8"), stderr: "" };
    if (args.includes("null")) return { stdout: "", stderr: LOUDNORM };
    const out = args.at(-1) as string;
    const abs = isAbsolute(out) ? out : join(opts.cwd ?? ".", out);
    if (o.hang?.(args)) {
      await writeFile(abs, "half");
      state.hanging = true;
      await new Promise<void>((_, no) => {
        const stop = () => {
          state.aborted++;
          const e = new Error("cancelled");
          e.name = "AbortError";
          no(e);
        };
        if (opts.signal?.aborted) stop();
        else opts.signal?.addEventListener("abort", stop);
      });
    }
    for (const us of [250_000, 500_000, 1_000_000]) {
      opts.onStdoutLine?.(`out_time_us=${us}`);
      await new Promise((r) => setTimeout(r, 120));
    }
    await writeFile(abs, `made by ${program} ${args.includes("h264_nvenc") ? "nvenc" : "x264"}`);
    return { stdout: "", stderr: "" };
  };
  return { run, calls, state };
}

const info = (version: string): FfmpegInfo => ({
  version,
  major: 9,
  source: "path",
  ffprobe: true,
  missing: [],
  encoders: ["h264_nvenc", "libx264"],
});
const RTX = { vendor: "nvidia" as const, name: "NVIDIA GeForce RTX 4080 SUPER", vramGb: 16 };

async function severino() {
  const s = await startServer(
    [{ text: "OK" }],
    {},
    {
      nodes: { hostName: "severino", reconnectMs: [60], waitMs: 3000, pollMs: 0 },
      videoMedia: {
        tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
        run: fakeMedia().run,
        machine: fixedMachine(
          { ffmpeg: "ffmpeg", ffprobe: "ffprobe" },
          { download: true, nvenc: false, encoder: "libx264", ffmpeg: info("n9.0.2") },
        ),
      },
    },
  );
  open.push(s);
  return s;
}

/** Rig: Windows-like (no container), an RTX with NVENC, ffmpeg downloaded at the first render. */
async function rig(o: { hang?: (args: string[]) => boolean; have?: boolean } = {}) {
  const fake = fakeMedia(o.hang ? { hang: o.hang } : {});
  const downloads: number[] = [];
  const machine = fixedMachine(
    o.have ? { ffmpeg: "ffmpeg", ffprobe: "ffprobe" } : undefined,
    { download: true, nvenc: true, encoder: "h264_nvenc", ffmpeg: info("9.0.1-full_build") },
    [RTX],
    async (p) => {
      for (const n of [0, 50_000_000, 100_000_000]) {
        p.progress(n, 100_000_000);
        downloads.push(n);
        await new Promise((r) => setTimeout(r, 300));
      }
      p.unpacking?.();
      return { ffmpeg: "ffmpeg", ffprobe: "ffprobe" };
    },
  );
  const s = await startServer(
    [{ text: "OK" }],
    {},
    {
      nodes: { hostName: "DESKTOP-8CCPHGB", reconnectMs: [60], waitMs: 3000, pollMs: 0 },
      videoMedia: { run: fake.run, machine },
    },
  );
  open.push(s);
  return { s, fake, downloads };
}

const state = async (s: Server) => (await s.api<NodesState>("GET", "/api/nodes")).body;

async function pairUp(principal: Server, node: Server, rights: ("use" | "admin")[], name: string) {
  const code = (await principal.api<PairCode>("POST", "/api/nodes/code")).body;
  await node.api<PendingPair>("POST", "/api/nodes/pair", {
    address: principal.url,
    code: code.code,
  });
  const p = await state(principal);
  const n = await state(node);
  await principal.api("POST", "/api/nodes/confirm", {
    fingerprint: (p.pending[0] as PendingPair).fingerprint,
    name,
  });
  await node.api("POST", "/api/nodes/confirm", {
    fingerprint: (n.pending[0] as PendingPair).fingerprint,
    rights,
  });
  const fp = n.self.fingerprint as string;
  await until(() => principal.core.nodes.isOnline(fp));
  await principal.core.nodes.poll("me", fp);
  return fp;
}

const R = { num: 25, den: 1 };
const clip = (id: string, track: string, start: number, dur: number) =>
  ({
    id,
    track,
    start,
    sourceRange: { start: 0, duration: dur },
    ref: { media: "riprese/clip.mp4", frames: 750, audio: true },
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

/** A project with a timeline and its clip (`size` bytes, so a copy takes several pieces). */
async function project(s: Server, size = 6 * 1024 * 1024) {
  const p = await s.api<{ id: string }>("POST", "/api/projects", { name: "Video" });
  const scope = `project:${p.body.id}`;
  const root = await s.core.scopeFolder("me", scope);
  await mkdir(join(root, "riprese"), { recursive: true });
  const bytes = Buffer.alloc(size);
  for (let i = 0; i < size; i += 4096) bytes[i] = (i / 4096) % 251;
  await writeFile(join(root, "riprese", "clip.mp4"), bytes);
  await writeFile(join(root, "film.rgvideo"), writeRgVideo(film()));
  return { scope, root };
}

const render = (s: Server, scope: string, where?: string) =>
  s.api<{ job?: Job; ask?: boolean; machines?: RenderMachine[]; error?: string }>(
    "POST",
    "/api/editor/video/render",
    { scope, path: "film.rgvideo", height: 720, ...(where && { where }) },
  );

/** The job's steps as it runs, sampled until it ends. */
async function follow(s: Server, id: string, onSample?: (j: Job) => void) {
  for (;;) {
    const j = s.core.jobs.get("me", id) as Job;
    onSample?.(j);
    if (j.state !== "running") return j;
    await new Promise((r) => setTimeout(r, 15));
  }
}

const nodeVideoDir = (n: Server) => join(n.dir, "nodes", "work");

describe("pure parts (G41.7)", () => {
  it.each<[string, string[], string[] | string]>([
    [
      "an input inside: only files",
      ["-y", "-i", "/w/media/a.mp4", "-c", "copy", "out.mp4"],
      ["-y", "-protocol_whitelist", "file", "-i", "/w/media/a.mp4", "-c", "copy", "out.mp4"],
    ],
    [
      "a relative input is read from the work folder",
      ["-f", "concat", "-safe", "0", "-i", "list.txt"],
      ["-f", "concat", "-safe", "0", "-protocol_whitelist", "file", "-i", "list.txt"],
    ],
    ["a URL", ["-i", "http://evil/x.mp4"], "Not a file"],
    ["another protocol", ["-i", "concat:/w/a|/etc/passwd"], "Not a file"],
    ["a file outside", ["-i", "/etc/passwd"], "outside"],
    ["out by dots", ["-i", "../../../etc/passwd"], "outside"],
  ])("confineInputs: %s", (_name, args, want) => {
    const go = () => confineInputs(args, "/w/work/render-1", ["/w"]);
    if (typeof want === "string") expect(go).toThrow(want);
    else expect(go()).toEqual(want);
  });

  it("pieces: in order, a piece asked again is not written twice, a wrong hash is thrown away", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-pieces-"));
    try {
      const file = join(dir, "media", "a.bin");
      const a = Buffer.alloc(10, 1).toString("base64");
      expect(await putPiece(file, { offset: 0, data: a })).toEqual({ size: 10 });
      // The same piece again (a reconnect asked it again): nothing more written.
      expect(await putPiece(file, { offset: 10, data: a })).toEqual({ size: 20 });
      expect(await putPiece(file, { offset: 10, data: a })).toEqual({ size: 20 });
      expect(await pieceState(file)).toEqual({ size: 0, partial: 20 });
      await expect(putPiece(file, { offset: 40, data: a })).rejects.toThrow(/out of order/);
      await expect(
        putPiece(file, { offset: 20, data: a, last: true, sha256: "0".repeat(64) }),
      ).rejects.toThrow(/did not match its SHA-256/);
      expect(existsSync(file)).toBe(false);
      expect(existsSync(`${file}.part`)).toBe(false);
    } finally {
      await rm(dir, { recursive: true, force: true });
    }
  });
});

describe("rendering on a node (G41.7)", () => {
  it("«use» alone is enough, without a container (R1); none is refused; files stay in the asker's folder", async () => {
    const s = await severino();
    const { s: r } = await rig({ have: true });
    const n = await pairUp(s, r, ["use"], "Rig");
    const ask = (body: Record<string, unknown>) =>
      s.core.nodes.request("me", n, "media", body, { timeoutMs: 5000 });
    // No container on Rig (the test servers run commands on the machine): media still works.
    const [known] = await s.core.nodes.known("me");
    expect(known?.view?.capabilities?.sandbox.container).toBe(false);
    expect(known?.view?.capabilities?.media).toMatchObject({ nvenc: true, encoder: "h264_nvenc" });
    expect(known?.view?.capabilities?.gpus?.[0]?.name).toBe(RTX.name);
    expect(await ask({ action: "state", name: "media/abc.mp4" })).toEqual({ size: 0, partial: 0 });
    for (const name of [
      "../x.mp4",
      "media/../../secret",
      "/etc/passwd",
      "media/a/b.mp4",
      "C:\\Windows\\x",
      "work/x.mp4",
    ]) {
      const e = await ask({ action: "put", name, offset: 0, data: "" }).catch((x) => x);
      expect(e.code, name).toBe("invalid");
    }
    await ask({ action: "put", name: "media/abc.mp4", offset: 0, data: "aGk=", last: true });
    const kept = await readdir(nodeVideoDir(r), { recursive: true });
    expect(kept.some((f) => f.endsWith(join("video", "media", "abc.mp4")))).toBe(true);
    // The person on Rig takes «use» away: refused there, whatever severino asks.
    const mine = (await state(r)).grants[0];
    await r.api("POST", "/api/nodes/grants/revoke", { target: n, id: mine?.id });
    const denied = await ask({ action: "state", name: "media/abc.mp4" }).catch((x) => x);
    expect(denied.code).toBe("forbidden");
  }, 60_000);

  it("asked at the first render, then remembered: ffmpeg made ready there, files copied in checked pieces, NVENC, the MP4 back", async () => {
    const s = await severino();
    const { s: r, fake, downloads } = await rig();
    const n = await pairUp(s, r, ["use"], "Rig");
    const { scope, root } = await project(s);
    // Nothing chosen yet: the page is asked which machine (R2).
    const first = await render(s, scope);
    expect(first.status).toBe(409);
    expect(
      first.body.machines?.map((m) => [m.id === "here" ? "here" : m.name, m.ok, m.nvenc]),
    ).toEqual([
      ["here", true, false],
      ["Rig", true, true],
    ]);
    expect(first.body.machines?.[1]?.gpu).toBe(RTX.name);
    const go = await render(s, scope, n);
    expect(go.status).toBe(200);
    const steps: Record<string, number[]> = {};
    const end = await follow(s, (go.body.job as Job).id, (j) => {
      for (const st of j.steps)
        if (st.state === "running" && st.progress) (steps[st.id] ??= []).push(st.progress.done);
    });
    expect(end.state, JSON.stringify(end.error)).toBe("done");
    expect(end.steps.map((x) => [x.id, x.state])).toEqual([
      ["video_wait", "skipped"],
      ["video_probe", "done"],
      ["node_ffmpeg", "done"],
      ["node_copy", "done"],
      ["video_render", "done"],
      ["node_fetch", "done"],
      ["node_check", "done"],
      ["video_save", "done"],
    ]);
    expect(end.vars?.node).toBe("Rig");
    const res = end.result as VideoRenderResult;
    expect(res).toMatchObject({ path: "renders/film-v1.mp4", node: "Rig", encoder: "h264_nvenc" });
    expect(await readFile(join(root, "renders", "film-v1.mp4"), "utf8")).toBe(
      "made by ffmpeg x264",
    );
    // ffmpeg downloaded on Rig with its bar in bytes; the copy in pieces with a growing bar.
    expect(downloads).toEqual([0, 50_000_000, 100_000_000]);
    expect(steps.node_ffmpeg?.some((d) => d > 0)).toBe(true);
    const copy = steps.node_copy ?? [];
    expect(copy.length).toBeGreaterThan(1);
    for (let k = 1; k < copy.length; k++) expect(copy[k]).toBeGreaterThanOrEqual(copy[k - 1] ?? 0);
    expect(steps.video_render?.some((d) => d > 0 && d <= 100)).toBe(true);
    // The node compiled the timeline itself, with NVENC, every input only a file of the folder.
    const encodes = fake.calls.filter(
      (c) =>
        c.program === "ffmpeg" && c.args.includes("-/filter_complex") && c.args.includes("-c:v"),
    );
    expect(encodes.length).toBeGreaterThan(0);
    for (const c of encodes) {
      expect(c.args).toContain("h264_nvenc");
      const inputs = c.args.flatMap((a, i) => (a === "-i" ? [c.args[i - 1]] : []));
      expect(inputs.every((x) => x === "file")).toBe(true);
    }
    // The finished video went from the node; the copied media stay for the next render.
    const left = await readdir(nodeVideoDir(r), { recursive: true });
    expect(left.filter((f) => /[\\/]out[\\/].+\.mp4/.test(f))).toEqual([]);
    expect(left.filter((f) => /[\\/]media[\\/][0-9a-f]{64}\.mp4$/.test(f))).toHaveLength(1);
    // Remembered: the next render goes to Rig without asking, and copies nothing again.
    const chosen = await s.api<{ chosen?: string }>(
      "GET",
      `/api/editor/video/machines?scope=${encodeURIComponent(scope)}`,
    );
    expect(chosen.body.chosen).toBe(n);
    const again = await render(s, scope);
    expect(again.status).toBe(200);
    const end2 = await follow(s, (again.body.job as Job).id);
    expect(end2.state).toBe("done");
    expect((end2.result as VideoRenderResult).path).toBe("renders/film-v2.mp4");
    const puts = (await s.core.store.list({ types: ["node.action"] })).filter(
      (e) =>
        e.type === "node.action" &&
        e.payload.side === "asked" &&
        e.payload.what.startsWith("video copy"),
    );
    // Pieces of the first copy only (6 MB = two pieces): the second render sent none.
    expect(puts).toHaveLength(Math.ceil((6 * 1024 * 1024) / PIECE));
    // Changed by the person in Settings > Nodes: back here.
    expect((await s.api("PUT", "/api/nodes/placements", { scope, render: "here" })).status).toBe(
      200,
    );
    const here = await render(s, scope);
    const end3 = await follow(s, (here.body.job as Job).id);
    expect(end3.state).toBe("done");
    expect(end3.steps.map((x) => x.id)).not.toContain("node_copy");
    expect((end3.result as VideoRenderResult).node).toBeUndefined();
  }, 90_000);

  it("a copy cut by a reconnect resumes and arrives whole; «Cancel» during the render stops ffmpeg on the node and leaves nothing", async () => {
    const s = await severino();
    const { s: r, fake } = await rig({
      have: true,
      hang: (args) => args.some((a) => a.endsWith(".part.mp4")),
    });
    const n = await pairUp(s, r, ["use"], "Rig");
    const { scope, root } = await project(s, 14 * 1024 * 1024);
    const go = await render(s, scope, n);
    const id = (go.body.job as Job).id;
    // The link drops while the pieces travel: the same piece is asked again, the copy goes on.
    await until(
      () => s.core.jobs.get("me", id)?.steps.find((x) => x.id === "node_copy")?.progress?.done,
    );
    s.core.nodes.dropLink(n);
    await until(() => fake.state.hanging, 20_000);
    const copied = await readdir(nodeVideoDir(r), { recursive: true });
    expect(copied.filter((f) => /[\\/]media[\\/][0-9a-f]{64}\.mp4$/.test(f))).toHaveLength(1);
    // «Cancel» in the render: ffmpeg stopped on the node, nothing kept on either side.
    s.core.jobs.cancel("me", id);
    expect((await follow(s, id)).state).toBe("cancelled");
    await until(() => fake.state.aborted > 0);
    expect(
      existsSync(join(root, "renders"))
        ? (await readdir(join(root, "renders"))).filter((f) => f.includes(".mp4"))
        : [],
    ).toEqual([]);
    await until(async () => {
      const left = await readdir(nodeVideoDir(r), { recursive: true });
      return !left.some((f) => /[\\/]out[\\/]/.test(f) && f.endsWith(".mp4"));
    });
  }, 90_000);

  it("«Cancel» during the copy stops it; a node that goes away mid-render is a clear error, no file left", async () => {
    const s = await severino();
    const { s: r, fake } = await rig({
      have: true,
      hang: (args) => args.some((a) => a.endsWith(".part.mp4")),
    });
    const n = await pairUp(s, r, ["use"], "Rig");
    const { scope, root } = await project(s, 40 * 1024 * 1024);
    const go = await render(s, scope, n);
    const id = (go.body.job as Job).id;
    await until(
      () => s.core.jobs.get("me", id)?.steps.find((x) => x.id === "node_copy")?.progress?.done,
    );
    s.core.jobs.cancel("me", id);
    const stopped = await follow(s, id);
    expect(stopped.state).toBe("cancelled");
    expect(stopped.steps.find((x) => x.id === "video_render")?.state).not.toBe("done");
    // Not whole on the node: no file under its hash, at most a part to resume from.
    const left = await readdir(nodeVideoDir(r), { recursive: true });
    expect(left.filter((f) => /[0-9a-f]{64}\.mp4$/.test(f))).toEqual([]);
    // Again: it resumes, then Rig goes away while it renders.
    const two = await render(s, scope);
    const id2 = (two.body.job as Job).id;
    await until(() => fake.state.hanging, 30_000);
    await r.close();
    open.splice(open.indexOf(r), 1);
    const lost = await follow(s, id2);
    expect(lost.state).toBe("failed");
    expect(lost.error?.code).toBe("video_node_offline");
    expect(lost.error?.message).toMatch(/^Rig: /);
    const renders = existsSync(join(root, "renders")) ? await readdir(join(root, "renders")) : [];
    expect(renders).toEqual([]);
  }, 90_000);

  it("an agent follows the person's choice: asked at the first render, never another machine by itself", async () => {
    const seen: string[] = [];
    let i = 0;
    const steps = [
      { name: "video", input: { action: "render", path: "film.rgvideo", where: "Rig" } },
      { name: "video", input: { action: "render", path: "film.rgvideo", where: "here" } },
      { name: "video", input: { action: "render", path: "film.rgvideo" } },
    ];
    const s = await startServer(
      ((req: { messages: { parts: { type: string; content?: string }[] }[] }) => {
        const r = req.messages.at(-1)?.parts.find((p) => p.type === "tool_result");
        if (r?.content) seen.push(r.content);
        const next = steps[i++];
        return next ? { toolCalls: [next] } : { text: "Done." };
      }) as never,
      { contextWindow: 65_536 },
      {
        nodes: { hostName: "severino", reconnectMs: [60], waitMs: 3000, pollMs: 0 },
        editor: { saveDelayMs: 0, watchMs: 0 },
        videoMedia: {
          tools: async () => ({ ffmpeg: "ffmpeg", ffprobe: "ffprobe" }),
          run: fakeMedia().run,
          machine: fixedMachine(
            { ffmpeg: "ffmpeg", ffprobe: "ffprobe" },
            { download: true, nvenc: false, encoder: "libx264", ffmpeg: info("n9.0.2") },
          ),
        },
      },
    );
    open.push(s);
    const { s: r } = await rig({ have: true });
    const n = await pairUp(s, r, ["use"], "Rig");
    const { scope } = await project(s, 64 * 1024);
    const id = scope.slice("project:".length);
    const god = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const a = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "orchestrator",
      parentId: god.body.id,
      projectId: id,
      name: "Regista",
    });
    expect(a.status, JSON.stringify(a.body)).toBe(201);
    const sessionId = (
      await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: a.body.id })
    ).body.sessionId;
    const asked: string[][] = [];
    const answering = (async () => {
      let q = s.core.questions.list("me")[0];
      while (!q) {
        await new Promise((x) => setTimeout(x, 10));
        q = s.core.questions.list("me")[0];
      }
      asked.push(q.questions[0]?.options.map((o) => o.label) ?? []);
      expect(q.questions[0]?.question).toMatch(/Where should the videos of this project be made/);
      const rigLabel = q.questions[0]?.options.find((o) => o.label.startsWith("Rig"))?.label;
      s.core.questions.answer("me", q.requestId, [[rigLabel as string]], "web");
    })();
    await (await s.core.send("me", sessionId, "Fai il video")).done;
    await answering;
    // The agent's pick came first among the options; the person chose Rig.
    expect(asked[0]).toEqual(["Rig (NVIDIA GeForce RTX 4080 SUPER, NVENC)", "This machine"]);
    expect(seen[0]).toMatch(/^Rendered renders\/film-v1\.mp4 on Rig with NVENC/);
    expect(await s.core.nodes.renderPlacement("me", scope)).toBe(n);
    // Another machine than the person's: refused, nothing rendered.
    expect(seen[1]).toMatch(/^The person chose to make this project's videos on Rig/);
    // Without "where": the person's choice.
    expect(seen[2]).toMatch(/^Rendered renders\/film-v2\.mp4 on Rig/);
    expect(s.core.questions.list("me")).toEqual([]);
  }, 90_000);
});
