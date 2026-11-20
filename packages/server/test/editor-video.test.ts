// The video family (G41.2): `.rgvideo` timelines read and written (old and new files), the
// agent's plain operations as actions on them (each undone exactly), the structure an agent
// reads, conflicts between the person and an agent on the same clip, an edit moved over another
// that touched other clips, proposals, a change from outside, and from end to end with a scripted
// model (FakeProvider): help, structure, canvas_edit with dry_run and expect_revision, and the
// whole turn undone.
import { mkdir, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { EventStore, migrate } from "@redgiant/events";
import {
  addTrack,
  applyVideoAction,
  DEFAULT_EDITOR_SETTINGS,
  type DocFile,
  type DocOp,
  invertVideoAction,
  newRgVideo,
  PERSON,
  placeClip,
  type RgVideo,
  readRgVideo,
  type ServerMessage,
  trackClips,
  type VideoAction,
  type VideoMediaRef,
  writeRgVideo,
} from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { EditorHost } from "../src/editor/host.js";
import { videoFromAgent } from "../src/editor/video/agent.js";
import { videoStructure } from "../src/editor/video/structure.js";
import { videoFamily } from "../src/editor/video-family.js";
import { startServer, wsClient } from "./helpers.js";
import { memoryDb } from "./pglite.js";

const A: VideoMediaRef = { media: "riprese/a.mp4", frames: 1000, audio: true };

/** A timeline at 25 fps: an interview on V1/A1 in two linked pieces, a B on V2. */
function timeline(): RgVideo {
  let d = addTrack(newRgVideo({ rate: { num: 25, den: 1 } }, "Gita"), "Video");
  d = placeClip(d, A, 0, 100, 0);
  d = placeClip(d, A, 300, 450, 100);
  d = placeClip(d, { media: "riprese/b.mp4", frames: 300, audio: true }, 10, 60, 40, {
    targets: { video: "V2", audio: null },
  });
  // As the host keeps it (read from its file).
  return readRgVideo(writeRgVideo(d));
}
const enc = (d: RgVideo) => new TextEncoder().encode(writeRgVideo(d));

function agent(doc: RgVideo, ops: unknown[]): VideoAction[] {
  const r = videoFromAgent(doc, ops);
  if ("error" in r) throw new Error(`${r.index}: ${r.error}`);
  return r.actions;
}
/** Applies one after the other, and checks the inverses (through JSON) give back the same bytes. */
function roundTrip(doc: RgVideo, list: VideoAction[]): RgVideo {
  let d = doc;
  const back: VideoAction[] = [];
  for (const a of list) {
    expect(videoFamily.check({ doc: d }, wrap(a))).toBeUndefined();
    back.unshift(JSON.parse(JSON.stringify(invertVideoAction(d, a))));
    d = applyVideoAction(d, a);
  }
  expect(writeRgVideo(back.reduce(applyVideoAction, d))).toBe(writeRgVideo(doc));
  return d;
}
const wrap = (op: VideoAction): DocOp => ({
  family: "video",
  engine: "rgvideo",
  engineVersion: "1",
  op,
});

describe("the .rgvideo file", () => {
  it("reads and writes a timeline, a new one from an empty file", () => {
    expect(videoFamily.accepts("video/gita.rgvideo")).toBe(true);
    expect(videoFamily.accepts("video/gita.mp4")).toBe(false);
    const d = timeline();
    const { model } = videoFamily.load(enc(d));
    expect(new TextDecoder().decode(videoFamily.save(model))).toBe(writeRgVideo(d));
    expect(videoFamily.load(new Uint8Array()).model.doc).toEqual(newRgVideo());
    expect(videoFamily.snapshot(model)).toEqual({ family: "video", doc: d });
  });

  it("refuses what it cannot keep: not UTF-8, not JSON, a newer format", () => {
    expect(() => videoFamily.load(new Uint8Array([0xff, 0xfe, 0x00]))).toThrow(/not UTF-8/);
    expect(() => videoFamily.load(new TextEncoder().encode("ciao"))).toThrow(/not JSON/);
    expect(() => videoFamily.load(new TextEncoder().encode('{"formatVersion":9}'))).toThrow(
      /newer Rasgeth \(format 9/,
    );
  });

  it("an old file (montatore's shape) opens as the current version", () => {
    const old = {
      tracks: [
        { id: "V1", type: "video" },
        { id: "A1", type: "audio" },
      ],
      clips: [{ id: "c1", track: "V1", media: "a.mp4", start: 5, in: 0, dur: 50 }],
      markers: [],
    };
    const { model } = videoFamily.load(new TextEncoder().encode(JSON.stringify(old)));
    expect(model.doc.formatVersion).toBe(1);
    expect(model.doc.clips[0]).toMatchObject({
      id: "c1",
      start: 5,
      sourceRange: { start: 0, duration: 50 },
      ref: { media: "a.mp4" },
    });
  });
});

describe("the agent's operations", () => {
  it("places, appends, moves, trims, cuts, links, sets, all undone exactly", () => {
    const d0 = timeline();
    const list = agent(d0, [
      {
        op: "place",
        media: "riprese/c.mp4",
        in: "1s",
        out: "3s",
        at: "00:00:20:00",
        file_length: "10s",
      },
      { op: "move", clips: ["c5"], by: "1s" },
      { op: "append", media: "foto/cima.jpg", length: "4s", video: "V2", audio: null },
      { op: "trim", clip: "c1", edge: "out", by: "-10f", ripple: true },
      { op: "blade", at: "00:00:05:00", clips: ["c3"] },
      {
        op: "set",
        clips: ["c5"],
        volume: -6,
        fade_in: "10f",
        ken_burns: "out_left",
        fit: "fit",
        background: "blur",
      },
      { op: "unlink", clips: ["c1"] },
      { op: "duplicate", clips: ["c5"], at: "40s" },
    ]);
    expect(list.map((a) => (a.t === "batch" ? a.what : a.t))).toEqual([
      "overwrite",
      "move",
      "append",
      "ripple_trim",
      "blade",
      "props",
      "unlink",
      "paste",
    ]);
    const d = roundTrip(d0, list);
    const at = (t: string) => trackClips(d, t).map((c) => [c.id, c.start, c.sourceRange.duration]);
    // The ripple moved what followed the interview's first piece by 10 frames, on its tracks only:
    // the B on V2 crosses the frames freed.
    expect(at("V1")).toEqual([
      ["c1", 0, 90],
      ["c3", 90, 35],
      ["c9", 125, 115],
      ["c6", 490, 50],
    ]);
    expect(at("V2")).toEqual([
      ["c5", 65, 50],
      ["c8", 115, 100],
      ["c11", 1000, 50],
    ]);
    expect(d.clips.find((c) => c.id === "c6")?.ref).toEqual({
      media: "riprese/c.mp4",
      frames: 250,
    });
    expect(d.clips.find((c) => c.id === "c8")?.ref).toEqual({
      media: "foto/cima.jpg",
      still: true,
    });
    expect(d.clips.find((c) => c.id === "c5")).toMatchObject({
      volume: -6,
      fadeIn: 10,
      fit: "fit",
      background: "blur",
    });
    expect(d.clips.find((c) => c.id === "c1")?.link).toBeUndefined();
    expect(d.clips.find((c) => c.id === "c9")?.link).toBe(
      d.clips.find((c) => c.id === "c10")?.link,
    );
  });

  it("transitions, texts, tracks with ducking, markers, subtitles, the format", () => {
    const d0 = timeline();
    const list = agent(d0, [
      { op: "add_transition", from: "c1", kind: "dip_to_black", length: 10 },
      { op: "add_text", text: "La gita", at: 0, length: "3s", style: "title", fade: 5 },
      { op: "add_track", kind: "audio", name: "Musica" },
      { op: "set_track", track: "A2", duck: { under: ["A1"], amount_db: -14 } },
      { op: "add_marker", at: "2s", color: "red", note: "qui la musica" },
      { op: "captions", language: "it", burn_in: true },
      { op: "add_caption", start: 0, end: "2s", text: "Eccoci" },
      { op: "format", aspect: "9:16", name: "Gita verticale" },
    ]);
    const d = roundTrip(d0, list);
    expect(d.transitions).toEqual([
      {
        id: "t1",
        track: "V1",
        from: "c1",
        to: "c3",
        kind: "dip_to_black",
        inOffset: 5,
        outOffset: 5,
      },
    ]);
    expect(trackClips(d, "V3")[0]).toMatchObject({
      ref: { generator: "text", text: "La gita" },
      sourceRange: { duration: 75 },
      fadeIn: 5,
    });
    expect(d.tracks.find((t) => t.id === "A2")).toMatchObject({
      name: "Musica",
      duck: { under: ["A1"], amountDb: -14 },
    });
    expect(d.markers[0]).toMatchObject({ frame: 50, color: "RED" });
    expect(d.captions).toMatchObject({
      language: "it",
      burnIn: true,
      segments: [{ end: 50, text: "Eccoci" }],
    });
    expect(d.format).toMatchObject({ width: 1080, height: 1920, aspect: "9:16" });
    expect(d.name).toBe("Gita verticale");
  });

  it.each<[unknown, RegExp]>([
    [{ op: "move", clips: ["nope"], by: 5 }, /there is no clip «nope»/],
    [{ op: "fly" }, /no operation "fly"/],
    [{ op: "move", clips: ["c1"], by: "domani" }, /not a time I can read/],
    [{ op: "place", media: "../fuori.mp4", out: 10, at: 0 }, /a path inside the project/],
    [{ op: "place", media: "a.mp4", at: 0 }, /give "out"/],
    [{ op: "add_transition", from: "c3", length: 10 }, /changes nothing \(the next clip/],
    [{ op: "trim", clip: "c1", edge: "out", by: 50 }, /changes nothing \(a neighbour/],
    [{ op: "set", clips: ["c1"], volume: 40 }, /from -60 to \+12/],
    [{ op: "set", clips: ["c1"], crop: { x: 0.5, y: 0, w: 0.8, h: 1 } }, /inside the picture/],
    [{ op: "move", clips: ["c1"], track: "A1" }, /only to a video track/],
    [{ op: "remove_track", track: "V1" }, /V1 and A1 stay/],
  ])("refuses %j", (op, why) => {
    const r = videoFromAgent(timeline(), [op]);
    expect(r).toMatchObject({ index: 0 });
    expect((r as { error: string }).error).toMatch(why);
  });

  it("a locked track is said", () => {
    const d = agent(timeline(), [{ op: "set_track", track: "V2", locked: true }]).reduce(
      applyVideoAction,
      timeline(),
    );
    const r = videoFromAgent(d, [{ op: "move", clips: ["c5"], by: 10 }]);
    expect((r as { error: string }).error).toBe("it changes nothing (track V2 is locked)");
  });
});

describe("the agent's operations, video part 2 (3.10)", () => {
  it("speed, still, box, colour and LUT in «set»; keys; undone exactly", () => {
    const d0 = timeline();
    const [c1, c2] = d0.clips.filter((c) => c.track === "V1").map((c) => c.id) as [string, string];
    const d = roundTrip(
      d0,
      agent(d0, [
        {
          op: "set",
          clips: [c1],
          speed: 2,
          color: { exposure: 0.4, saturation: -0.2 },
          lut: "lut/a.cube",
        },
        { op: "set", clips: [c2], freeze: true, box: { x: 0.7, y: 0.3, scale: 0.4 } },
        { op: "key", clip: c2, at: "6s", box: { x: 0.2, y: 0.8, scale: 0.6 } },
        { op: "key", clip: c1, at: "2s", volume: -12 },
      ]),
    );
    const one = d.clips.find((c) => c.id === c1);
    const two = d.clips.find((c) => c.id === c2);
    expect(one).toMatchObject({
      speed: 2,
      color: { exposure: 0.4, contrast: 0, saturation: -0.2, temperature: 0 },
      lut: "lut/a.cube",
    });
    expect(two).toMatchObject({ freeze: true, box: { x: 0.7, y: 0.3, scale: 0.4 } });
    expect(two?.boxKeys).toEqual([
      { at: 0, x: 0.7, y: 0.3, scale: 0.4 },
      { at: 50, x: 0.2, y: 0.8, scale: 0.6 },
    ]);
    expect(
      d.clips
        .filter((c) => c.link === one?.link)
        .every((c) => !c.volumeKeys || c.volumeKeys.length === 2),
    ).toBe(true);
  });

  it("slip, roll and beats; cuts to beats; what cannot be done says why", () => {
    const d0 = timeline();
    const [c1, c2] = d0.clips.filter((c) => c.track === "V1").map((c) => c.id) as [string, string];
    // Nothing after the last piece: roll needs a clip that touches.
    const bad = videoFromAgent(d0, [{ op: "roll", clip: c2, by: "4f" }]);
    expect(bad).toMatchObject({
      error: expect.stringContaining("a clip must touch it after"),
      index: 0,
    });
    const d1 = roundTrip(d0, agent(d0, [{ op: "slip", clip: c2, by: "10f" }]));
    expect(d1.clips.find((c) => c.id === c2)?.sourceRange.start).toBe(310);
    const d2 = roundTrip(
      d1,
      agent(d1, [
        { op: "beats", beats: ["1s", "3.92s", 300], of: c1 },
        { op: "cuts_to_beats", track: "V1", within: "4f" },
      ]),
    );
    expect(d2.beats).toEqual([25, 98, 300]);
    expect(d2.clips.find((c) => c.id === c1)?.sourceRange.duration).toBe(98);
    expect(videoFromAgent(d0, [{ op: "cuts_to_beats" }])).toMatchObject({
      error: expect.stringContaining("no beats yet"),
    });
    expect(videoFromAgent(d0, [{ op: "set", clips: [c1], lut: "../x.cube" }])).toMatchObject({
      error: expect.stringContaining("inside the project"),
    });
    expect(videoFromAgent(d0, [{ op: "set", clips: [c1], color: { contrast: 3 } }])).toMatchObject({
      error: expect.stringContaining("from -1 to 1"),
    });
  });
});

describe("the structure an agent reads", () => {
  it("lists tracks from the top, clips with timecodes, gaps, links and the rest", () => {
    const d = agent(timeline(), [
      { op: "add_transition", from: "c1", length: 10 },
      { op: "add_marker", at: 30, note: "inizio" },
      { op: "add_caption", start: 0, end: 25, text: "Ciao" },
    ]).reduce(applyVideoAction, timeline());
    const s = videoStructure(d);
    expect(s).toContain(
      "Video timeline «Gita» (.rgvideo): 1920×1080 (16:9) at 25 fps, 00:00:10:00 long (250 frames).",
    );
    expect(s).toContain("- V2: 1 clip\n- V1: 2 clips\n- A1: 2 clips");
    expect(s).toContain(
      "V2:\n  gap 00:00:00:00–00:00:01:15 (40f)\n  c5 00:00:01:15–00:00:03:15 (50f) riprese/b.mp4 from 00:00:00:10, file 300f",
    );
    expect(s).toContain(
      "  c1 00:00:00:00–00:00:04:00 (100f) riprese/a.mp4 from 00:00:00:00, file 1000f, linked g1 (c2)",
    );
    expect(s).toContain(
      "- t1 dissolve on V1 at 00:00:04:00 (c1 → c3), 5f before the cut + 5f after",
    );
    expect(s).toContain("- m1 00:00:01:05 BLUE «inizio»");
    expect(s).toContain("- s1 00:00:00:00–00:00:01:00 «Ciao»");
    expect(videoStructure(d, { fromLine: 2, toLine: 3 })).toMatch(
      /^Tracks .*\n- V2: 1 clip\n\(lines 2-3 of \d+/,
    );
  });
});

// ---- in the host ----------------------------------------------------------------------------

let dir: string;
let store: EventStore;
let hosts: EditorHost[] = [];
const ADA = { id: "ada", name: "Ada", sessionId: "s-ada" };

function host() {
  const h = new EditorHost({
    store,
    dataDir: join(dir, "data"),
    resolve: async (_o, f) => join(dir, "ws", f.path),
    settings: () => DEFAULT_EDITOR_SETTINGS,
    families: [videoFamily],
    saveDelayMs: 60_000,
    watchMs: 0,
  });
  hosts.push(h);
  return h;
}
const opsOf = (doc: RgVideo, list: unknown[]): DocOp[] => {
  const r = videoFamily.fromAgent({ doc }, list);
  if ("error" in r) throw new Error(r.error);
  return r.ops;
};

describe("a timeline in the editor's host", () => {
  beforeEach(async () => {
    dir = await mkdtemp(join(tmpdir(), "rg-video-"));
    await mkdir(join(dir, "ws"), { recursive: true });
    const { db } = await memoryDb();
    await migrate(db);
    store = new EventStore(db);
  });
  afterEach(async () => {
    for (const h of hosts) await h.close();
    hosts = [];
    await rm(dir, { recursive: true, force: true });
  });

  it("the person and an agent: refused on the same clip, moved over another's, undone, saved, rebuilt", async () => {
    const file: DocFile = { scope: "platform", path: "gita.rgvideo" };
    const text = writeRgVideo(timeline());
    await writeFile(join(dir, "ws", file.path), text);
    const h = host();
    const doc0 = ((await h.read("me", file)).model as { doc: RgVideo }).doc;
    // The person moves the B (as the page sends it: the edit's actions, with its own ids).
    const r1 = await h.apply("me", file, {
      author: { id: PERSON },
      baseRevision: 0,
      ops: opsOf(doc0, [{ op: "move", clips: ["c5"], by: 100 }]),
      groupId: "g1",
    });
    expect(r1).toMatchObject({
      ok: true,
      revision: 1,
      summary: {
        video: { action: "move", n: 1, id: "c5" },
        text: "moved 1 clip on V2 at 00:00:05:15",
      },
    });
    // Ada, on revision 0, on the same clip: refused.
    const r2 = await h.apply("me", file, {
      author: ADA,
      baseRevision: 0,
      ops: opsOf(doc0, [{ op: "set", clips: ["c5"], volume: -3 }]),
      groupId: "turn:1",
    });
    expect(r2).toMatchObject({ ok: false, code: "conflict" });
    // Ada, on revision 0, where the B lands now: refused too (two clips on the same frames).
    const r3 = await h.apply("me", file, {
      author: ADA,
      baseRevision: 0,
      ops: opsOf(doc0, [{ op: "add_text", text: "Su", at: "6s", length: "1s", track: "V2" }]),
      groupId: "turn:1",
    });
    expect(r3).toMatchObject({ ok: false, code: "conflict" });
    // Ada on the interview, elsewhere: moved over the person's.
    const r4 = await h.apply("me", file, {
      author: ADA,
      baseRevision: 0,
      ops: opsOf(doc0, [{ op: "trim", clip: "c3", edge: "out", by: -50 }]),
      groupId: "turn:1",
    });
    expect(r4).toMatchObject({
      ok: true,
      revision: 2,
      rebased: true,
      summary: { video: { action: "trim" } },
    });
    const now = ((await h.read("me", file)).model as { doc: RgVideo }).doc;
    expect(now.clips.find((c) => c.id === "c5")?.start).toBe(140);
    expect(now.clips.find((c) => c.id === "c3")?.sourceRange.duration).toBe(100);
    // «Annulla questa modifica» on the person's, not the last.
    const u = await h.undo("me", file, { revision: 1 }, { id: PERSON });
    expect(u).toMatchObject({ ok: true, revision: 3 });
    await h.flush();
    const disk = readRgVideo(await readFile(join(dir, "ws", file.path), "utf8"));
    expect(disk.clips.find((c) => c.id === "c5")?.start).toBe(40);
    expect(disk.clips.find((c) => c.id === "c3")?.sourceRange.duration).toBe(100);
    // Ada's whole turn back: the very same bytes.
    await h.undo("me", file, { groupId: "turn:1" }, { id: PERSON });
    await h.flush();
    expect(await readFile(join(dir, "ws", file.path), "utf8")).toBe(text);
    const again = await host().read("me", file);
    expect(again.revision).toBe(4);
  });

  it("a proposal waits for the person, then applies as the agent's", async () => {
    const file: DocFile = { scope: "platform", path: "p.rgvideo" };
    await writeFile(join(dir, "ws", file.path), writeRgVideo(timeline()));
    const h = host();
    const doc0 = ((await h.read("me", file)).model as { doc: RgVideo }).doc;
    const p = await h.propose("me", file, {
      author: ADA,
      baseRevision: 0,
      ops: opsOf(doc0, [{ op: "ripple_delete", clips: ["c1"] }]),
      groupId: "turn:9",
    });
    expect(p.summary).toMatchObject({
      kind: "delete",
      video: { action: "ripple_delete", removed: 2 },
    });
    const out = await h.decide("me", file, p.proposalId, true);
    expect(out).toMatchObject({ ok: true, revision: 1 });
    const now = ((await h.read("me", file)).model as { doc: RgVideo }).doc;
    expect(trackClips(now, "V1").map((c) => [c.id, c.start])).toEqual([["c3", 0]]);
  });

  it("a change from outside is kept as its difference and can be undone", async () => {
    const file: DocFile = { scope: "platform", path: "o.rgvideo" };
    const one = writeRgVideo(timeline());
    await writeFile(join(dir, "ws", file.path), one);
    const h = host();
    await h.read("me", file);
    const changed = timeline();
    changed.name = "Cambiato fuori";
    await writeFile(join(dir, "ws", file.path), writeRgVideo(changed));
    const read = await h.read("me", file);
    expect(read.revision).toBe(1);
    const last = (await h.open("me", file)).history.at(-1) as { summary: { video?: unknown } };
    expect(last.summary.video).toMatchObject({ action: "replace" });
    const u = await h.undo("me", file, { revision: 1 }, { id: PERSON });
    expect(u).toMatchObject({ ok: true });
    await h.flush();
    expect(await readFile(join(dir, "ws", file.path), "utf8")).toBe(one);
  });
});

// ---- from end to end ----------------------------------------------------------------------

type Req = { messages: { role: string; parts: { type: string; content?: string }[] }[] };
const resultOf = (req: Req) =>
  (
    req.messages.at(-1)?.parts.find((p) => p.type === "tool_result") as
      | { content: string }
      | undefined
  )?.content;
function calls(list: { name: string; input: unknown }[], seen: string[]) {
  let i = 0;
  return (req: Req) => {
    const r = resultOf(req);
    if (r !== undefined) seen.push(r);
    const next = list[i++];
    return next ? { toolCalls: [next] } : { text: "Done." };
  };
}

describe("a timeline from end to end (FakeProvider)", () => {
  let s: Awaited<ReturnType<typeof startServer>> | undefined;
  afterEach(async () => {
    await s?.close();
    s = undefined;
  });

  it("help, structure, a dry run, an edit the page sees, a refusal, the turn undone", async () => {
    const seen: string[] = [];
    const file = { scope: "platform", path: "video/gita.rgvideo" };
    const place = {
      op: "place",
      media: "riprese/c.mp4",
      in: 0,
      out: "2s",
      at: "12s",
    };
    s = await startServer(
      calls(
        [
          { name: "canvas_edit", input: { path: file.path, help: true } },
          { name: "canvas_look", input: { path: file.path, view: "structure" } },
          {
            name: "canvas_edit",
            input: { path: file.path, ops: [place], dry_run: true, expect_revision: 0 },
          },
          {
            name: "canvas_edit",
            input: {
              path: file.path,
              expect_revision: 0,
              ops: [place, { op: "add_text", text: "Fine", at: "12s", length: "2s" }],
            },
          },
          {
            name: "canvas_edit",
            input: { path: file.path, ops: [{ op: "lift", clips: ["nope"] }] },
          },
        ],
        seen,
      ) as never,
      { contextWindow: 65_536 },
      { editor: { saveDelayMs: 0, watchMs: 0 } },
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
    await mkdir(dirname(join(root, file.path)), { recursive: true });
    const text = writeRgVideo(timeline());
    await writeFile(join(root, file.path), text);
    const page = await wsClient(s.url);
    await page.waitFor("welcome");
    page.send({ type: "doc.open", file });
    const opened = await page.waitFor("doc.opened");
    expect(opened).toMatchObject({
      family: "video",
      revision: 0,
      snapshot: { family: "video", doc: { name: "Gita" } },
    });
    await (await s.core.send("me", sessionId, "Aggiungi la clip finale con un titolo")).done;
    expect(seen[0]).toMatch(/^Video timelines \(\.rgvideo/);
    expect(seen[0]).toContain('"op":"place"');
    expect(seen[1]).toContain("revision 0");
    expect(seen[1]).toContain("Video timeline «Gita» (.rgvideo)");
    expect(seen[2]).toMatch(
      /^Dry run on revision 0 \(nothing changed\): it would have placed 2 clips on V1 at 00:00:12:00/,
    );
    expect(seen[3]).toMatch(
      /^Applied as revision 1: placed 2 clips on V1 at 00:00:12:00; added a text on V2 at 00:00:12:00/,
    );
    expect(seen[4]).toMatch(/Nothing applied: operation 1: there is no clip «nope»/);
    const changed = page.messages.filter(
      (m): m is Extract<ServerMessage, { type: "doc.changed" }> => m.type === "doc.changed",
    );
    expect(changed).toHaveLength(1);
    expect(changed[0]?.change.summary.video).toMatchObject({ action: "edit", added: 3 });
    await s.core.editor.flush();
    const disk = readRgVideo(await readFile(join(root, file.path), "utf8"));
    expect(trackClips(disk, "V1").at(-1)).toMatchObject({
      start: 300,
      ref: { media: "riprese/c.mp4" },
    });
    expect(trackClips(disk, "V2").at(-1)).toMatchObject({
      start: 300,
      ref: { generator: "text", text: "Fine" },
    });
    // «Annulla tutto il turno»: the file as it was.
    const u = await s.core.editor.undo(
      "me",
      file,
      { groupId: changed[0]?.change.groupId as string },
      { id: PERSON },
    );
    expect(u).toMatchObject({ ok: true, revision: 2 });
    await s.core.editor.flush();
    expect(await readFile(join(root, file.path), "utf8")).toBe(text);
    page.close();
  });
});
