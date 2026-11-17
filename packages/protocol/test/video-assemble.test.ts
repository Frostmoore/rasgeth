// The automatic assembly (G41.6) as tables: roles, order, silences cut, coverage on V2 under the
// rules, music ducked on A3, voice-overs covered on V1, the length asked, the same draft twice.
import { describe, expect, it } from "vitest";
import {
  type AssembleFile,
  assembleOrder,
  assembleRole,
  autoAssemble,
  brollRules,
  clipEnd,
  cutsFromSilence,
  keptSpans,
  type MediaProbe,
  timelineInserts,
  timelineProblems,
  validateInserts,
} from "../src/index.js";

const probe = (
  kind: MediaProbe["kind"],
  duration: number | null,
  o: Partial<MediaProbe> = {},
): MediaProbe => ({
  kind,
  duration,
  width: kind === "audio" ? 0 : 1920,
  height: kind === "audio" ? 0 : 1080,
  rotation: 0,
  rate: kind === "video" ? { num: 30, den: 1 } : null,
  codec: kind === "audio" ? null : "h264",
  audio: kind !== "image",
  audioCodec: kind === "image" ? null : "aac",
  sampleRate: kind === "image" ? null : 48000,
  channels: kind === "image" ? null : 2,
  timecode: null,
  createdAt: null,
  size: 1000,
  ...o,
});
/** A word every half second from `from` to `to`. */
const talk = (from: number, to: number) =>
  Array.from({ length: Math.floor((to - from) / 0.5) }, (_, i) => ({
    text: `w${i}`,
    start: from + i * 0.5,
    end: from + i * 0.5 + 0.4,
  }));
const speaker = (path: string, duration: number, o: Partial<AssembleFile> = {}): AssembleFile => ({
  path,
  probe: probe("video", duration),
  words: talk(0, duration),
  speech: { ratio: 0.8, seconds: duration * 0.8, role: "A" },
  cuts: [],
  ...o,
});
const cover = (path: string, duration = 10): AssembleFile => ({
  path,
  probe: probe("video", duration),
  speech: { ratio: 0, seconds: 0, role: "B" },
});
const photo = (path: string): AssembleFile => ({ path, probe: probe("image", null) });
const music = (path: string, duration = 20): AssembleFile => ({
  path,
  probe: probe("audio", duration),
  speech: { ratio: 0, seconds: 0, role: "B" },
});
const AT = "2026-11-17T10:00:00.000Z";

describe("roles and order", () => {
  it.each<[string, AssembleFile, string]>([
    ["a speaker", speaker("a.mp4", 30), "A"],
    ["coverage", cover("b.mp4"), "B"],
    ["a picture", photo("p.jpg"), "B"],
    ["music", music("m.mp3"), "music"],
    [
      "a voice-over",
      { ...music("v.wav"), speech: { ratio: 0.7, seconds: 20, role: "B" } },
      "voice",
    ],
    ["chosen by hand", { ...cover("b.mp4"), role: "A" }, "A"],
    [
      "loud music without a transcription",
      { ...music("m.mp3"), speech: { ratio: 1, seconds: 20, role: "B", source: "sound" } },
      "music",
    ],
  ])("%s is %s", (_, f, role) => {
    expect(assembleRole(f)).toBe(role);
  });
  it("names in their natural order, dates when every file has one", () => {
    const files = [speaker("clip10.mp4", 5), speaker("clip2.mp4", 5), speaker("Clip1.mp4", 5)];
    expect(assembleOrder(files).map((f) => f.path)).toEqual([
      "Clip1.mp4",
      "clip2.mp4",
      "clip10.mp4",
    ]);
    const dated = files.map((f, i) => ({
      ...f,
      probe: { ...f.probe, createdAt: `2026-01-0${3 - i}T10:00:00Z` },
    }));
    expect(assembleOrder(dated).map((f) => f.path)).toEqual([
      "Clip1.mp4",
      "clip2.mp4",
      "clip10.mp4",
    ]);
    const partly = [
      { ...dated[0], probe: { ...(files[0] as AssembleFile).probe, createdAt: null } },
      ...dated.slice(1),
    ] as AssembleFile[];
    expect(assembleOrder(partly).map((f) => f.path)).toEqual([
      "Clip1.mp4",
      "clip2.mp4",
      "clip10.mp4",
    ]);
  });
  it.each<[string, number, { start: number; end: number }[], [number, number][]]>([
    ["no cuts", 10, [], [[0, 10]]],
    [
      "head and tail",
      10,
      [
        { start: 0, end: 1 },
        { start: 9, end: 10 },
      ],
      [[1, 9]],
    ],
    [
      "overlapping cuts merged",
      10,
      [
        { start: 2, end: 4 },
        { start: 3, end: 5 },
      ],
      [
        [0, 2],
        [5, 10],
      ],
    ],
    ["everything cut", 10, [{ start: 0, end: 10 }], []],
  ])("keptSpans: %s", (_, d, cuts, want) => {
    expect(keptSpans(d, cuts)).toEqual(want);
  });
});

describe("cutsFromSilence", () => {
  it.each<[string, [number, number][], { start: number; end: number; where: string }[]]>([
    [
      "head, middle and tail",
      [
        [0, 2.015],
        [9.795, 14.199],
        [21.386, 30],
      ],
      [
        { start: 0, end: 1.865, where: "head" },
        { start: 9.945, end: 14.049, where: "mid" },
        { start: 21.536, end: 30, where: "tail" },
      ],
    ],
    ["short pauses stay", [[5, 5.5]], []],
    [
      "a pause just long enough keeps its padding",
      [[5, 5.8]],
      [{ start: 5.15, end: 5.65, where: "mid" }],
    ],
  ])("%s", (_, silent, want) => {
    expect(cutsFromSilence(silent, 30)).toEqual(want);
  });
});

describe("autoAssemble", () => {
  it("speech on V1/A1 in order with its silences cut, linked", () => {
    const { doc, report } = autoAssemble(
      [
        speaker("clip2.mp4", 10, {
          cuts: [
            { start: 0, end: 1 },
            { start: 4, end: 6 },
          ],
        }),
        speaker("clip1.mp4", 8),
      ],
      { at: AT },
    );
    expect(report.order).toEqual(["clip1.mp4", "clip2.mp4"]);
    expect(report.cut).toBe(3);
    expect(report.seconds).toBe(15);
    const v1 = doc.clips.filter((c) => c.track === "V1").sort((a, b) => a.start - b.start);
    expect(v1.map((c) => [c.start, c.sourceRange.start, c.sourceRange.duration])).toEqual([
      [0, 0, 240],
      [240, 30, 90],
      [330, 180, 120],
    ]);
    const a1 = doc.clips.filter((c) => c.track === "A1");
    expect(a1).toHaveLength(3);
    for (const v of v1)
      expect(a1.find((a) => a.link === v.link && a.start === v.start)).toBeTruthy();
    expect(doc.assembled).toEqual({ at: AT });
    expect(timelineProblems(doc)).toEqual([]);
  });

  it("coverage on V2 keeps the rules, its sound linked and off, pictures with Ken Burns taking turns", () => {
    const files = [
      speaker("talk.mp4", 60),
      cover("b1.mp4"),
      cover("b2.mp4"),
      photo("p1.jpg"),
      photo("p2.jpg"),
    ];
    const { doc, report } = autoAssemble(files, { at: AT });
    const v2 = doc.clips.filter((c) => c.track === "V2");
    expect(v2.length).toBe(4);
    expect(report.inserts).toHaveLength(4);
    const rules = brollRules();
    const cat = files.slice(1).map((f) => ({
      id: f.path,
      still: f.probe.kind === "image",
      duration: f.probe.duration,
    }));
    expect(validateInserts(rules, cat, report.words, report.seconds, timelineInserts(doc))).toEqual(
      [],
    );
    for (const c of v2) expect(c.fadeIn).toBe(12);
    const stills = v2.filter((c) => "still" in c.ref && c.ref.still);
    expect(stills.map((c) => JSON.stringify(c.kenBurns))).toHaveLength(2);
    expect(new Set(stills.map((c) => JSON.stringify(c.kenBurns))).size).toBe(2);
    const a2 = doc.clips.filter((c) => c.track === "A2");
    expect(a2.length).toBe(2);
    for (const a of a2) expect(a.enabled).toBe(false);
    expect(timelineProblems(doc)).toEqual([]);
  });

  it("the agent's direction is repaired, never trusted", () => {
    const { report } = autoAssemble([speaker("talk.mp4", 60), cover("b1.mp4"), cover("b2.mp4")], {
      at: AT,
      inserts: [
        { media: "b1.mp4", start: 2, end: 9, reason: "the harbour" },
        { media: "b2.mp4", start: 10.2, end: 14.2 },
        { media: "nope.mp4", start: 30, end: 34 },
      ],
    });
    expect(report.inserts.map((i) => [i.b, i.start, i.end])).toEqual([
      ["b1.mp4", 5, 7],
      ["b2.mp4", 10, 14.4],
    ]);
    expect(report.inserts[0]?.reason).toBe("the harbour");
    expect(report.actions.map((a) => a.code)).toContain("dropped_unknown_b");
  });

  it("music on A3, again and again, ducked under the voice", () => {
    const { doc, report } = autoAssemble([speaker("talk.mp4", 30), music("song.mp3", 12)], {
      at: AT,
    });
    expect(report.music).toBe("song.mp3");
    const a3 = doc.clips.filter((c) => c.track === "A3").sort((a, b) => a.start - b.start);
    expect(a3.map((c) => [c.start, c.sourceRange.duration])).toEqual([
      [0, 360],
      [360, 360],
      [720, 180],
    ]);
    expect(a3[0]?.fadeIn).toBe(30);
    expect(a3.at(-1)?.fadeOut).toBe(60);
    expect(doc.tracks.find((t) => t.id === "A3")?.duck?.under).toEqual(["A1"]);
    expect(
      autoAssemble([speaker("talk.mp4", 30), music("song.mp3")], {
        at: AT,
        music: false,
      }).doc.clips.some((c) => c.track === "A3"),
    ).toBe(false);
  });

  it("a voice-over is covered on V1 by the coverage", () => {
    const voice: AssembleFile = {
      ...music("voice.wav", 20),
      words: talk(0, 20),
      speech: { ratio: 0.9, seconds: 18, role: "B" },
    };
    const { doc, report } = autoAssemble([voice, cover("b1.mp4", 6), photo("p.jpg")], { at: AT });
    expect(report.order).toEqual(["voice.wav"]);
    const v1 = doc.clips.filter((c) => c.track === "V1").sort((a, b) => a.start - b.start);
    expect(v1[0]?.start).toBe(0);
    expect(Math.max(...v1.map(clipEnd))).toBe(600);
    for (let i = 1; i < v1.length; i++) expect(v1[i]?.start).toBe(clipEnd(v1[i - 1] as never));
    expect(doc.clips.filter((c) => c.track === "A1")).toHaveLength(1);
    expect(doc.clips.some((c) => c.track === "V2")).toBe(false);
    expect(timelineProblems(doc)).toEqual([]);
  });

  it("the length asked ends at the last word before it", () => {
    const { doc, report } = autoAssemble([speaker("talk.mp4", 60)], {
      at: AT,
      targetSeconds: 20.2,
    });
    expect(report.seconds).toBeCloseTo(20.05, 2);
    expect(Math.max(...doc.clips.map(clipEnd))).toBe(602);
    expect(report.warnings.join(" ")).toMatch(/length asked/);
  });

  it("a shape asked, files skipped, and the same draft twice", () => {
    const files = [
      speaker("talk.mp4", 40),
      cover("b1.mp4"),
      { ...cover("b2.mp4"), role: "skip" as const },
    ];
    const one = autoAssemble(files, { at: AT, aspect: "9:16", name: "Gita" });
    expect(one.doc.format).toMatchObject({ width: 1080, height: 1920, aspect: "9:16" });
    expect(one.report.skipped).toEqual(["b2.mp4"]);
    expect(one.doc.name).toBe("Gita");
    expect(JSON.stringify(autoAssemble(files, { at: AT, aspect: "9:16", name: "Gita" }))).toBe(
      JSON.stringify(one),
    );
  });

  it("nothing but coverage: one after the other on V1", () => {
    const { doc, report } = autoAssemble([cover("b1.mp4", 6), photo("p.jpg")], { at: AT });
    expect(report.warnings[0]).toMatch(/No file has speech/);
    expect(
      doc.clips.filter((c) => c.track === "V1").map((c) => [c.start, c.sourceRange.duration]),
    ).toEqual([
      [0, 180],
      [180, 120],
    ]);
  });
});
