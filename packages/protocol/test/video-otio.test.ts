// G41.6b: the timeline as OpenTimelineIO. `toOtio` builds the same OTIO timeline montatore's
// engine builds (fixtures/resolve/<name>.otio, written by OpenTimelineIO 0.18.1 from its `build`):
// equal but for the metadata (montatore's own, ours). `otioText` writes OpenTimelineIO's bytes
// (its own files written again are the same; ours read and written by Python's OTIO are the
// same, fixtures/resolve/<name>.ours.otio). `fromOtio(toOtio(doc))` gives the timeline back.
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  cleanTimeline,
  fromOtio,
  newRgVideo,
  otioRate,
  otioText,
  type ResolveJob,
  type RgVideo,
  resolveFileUrl,
  toOtio,
} from "../src/index.js";

const DIR = join(import.meta.dirname, "fixtures", "resolve");
const read = (f: string) => readFileSync(join(DIR, f), "utf8");
const NAMES = readdirSync(DIR)
  .filter((f) => f.endsWith(".otio") && !f.endsWith(".ours.otio"))
  .map((f) => f.replace(/\.otio$/, ""));
const job = (n: string) => JSON.parse(read(`${n}.job.json`)) as ResolveJob;

/** A timeline that is montatore's job: same tracks (named by id), clips and files. */
function docOf(j: ResolveJob): RgVideo {
  const d = newRgVideo({
    width: j.width,
    height: j.height,
    rate: { num: j.fps_num, den: j.fps_den },
  });
  d.name = j.name;
  d.tracks = j.tracks.map((t) =>
    t.type === "video"
      ? { id: t.id, kind: "Video", name: t.id, locked: false, hidden: !t.enabled }
      : { id: t.id, kind: "Audio", name: t.id, locked: false, muted: !t.enabled },
  );
  let n = 0;
  d.clips = j.tracks.flatMap((t) =>
    t.clips.map((c) => ({
      id: `c${++n}`,
      track: t.id,
      start: c.start,
      sourceRange: { start: c.in, duration: c.dur },
      ref: {
        media: String(c.media),
        ...(j.media[String(c.media)]?.frames === null && { still: true }),
      },
      enabled: c.enabled,
      volume: 0,
      fadeIn: 0,
      fadeOut: 0,
      fit: "fill" as const,
    })),
  );
  return d;
}

const stripMeta = (v: unknown): unknown => {
  if (Array.isArray(v)) return v.map(stripMeta);
  if (v && typeof v === "object") {
    const o: Record<string, unknown> = {};
    for (const [k, x] of Object.entries(v)) o[k] = k === "metadata" ? {} : stripMeta(x);
    return o;
  }
  return v;
};

describe("toOtio: montatore's OTIO timeline", () => {
  it("has every reference", () => {
    expect(NAMES.length).toBe(7);
  });
  it.each(NAMES)("%s: OpenTimelineIO's own text written again is the same bytes", (n) => {
    const text = read(`${n}.otio`);
    if (process.env.RG_OTIO_OUT)
      writeFileSync(
        join(process.env.RG_OTIO_OUT, `${n}.rewritten.otio`),
        otioText(JSON.parse(text)),
      );
    expect(otioText(JSON.parse(text))).toBe(text);
  });
  it.each(NAMES)("%s: the same timeline as montatore's build, but for the metadata", (n) => {
    const j = job(n);
    const ours = toOtio(docOf(j), { name: j.name ?? "", media: j.media });
    expect(otioText(stripMeta(ours) as never)).toBe(
      otioText(stripMeta(JSON.parse(read(`${n}.otio`))) as never),
    );
  });
  it.each(NAMES)("%s: Python's OpenTimelineIO reads ours and writes the same bytes", (n) => {
    const j = job(n);
    const text = otioText(toOtio(docOf(j), { name: j.name ?? "", media: j.media }));
    // RG_OTIO_OUT=<folder>: writes ours for make-reference.sh's round trip through Python.
    if (process.env.RG_OTIO_OUT) writeFileSync(join(process.env.RG_OTIO_OUT, `${n}.otio`), text);
    expect(text).toBe(read(`${n}.ours.otio`));
  });
});

/** A timeline with all we write: titles, colours, transitions, markers, subtitles, A1's reframe. */
function rich(): RgVideo {
  const d = newRgVideo(
    { width: 1080, height: 1920, aspect: "9:16", rate: { num: 25, den: 1 } },
    "Prova",
  );
  d.tracks = [
    { id: "V1", kind: "Video", name: "A", locked: false, hidden: false },
    { id: "V2", kind: "Video", name: "B", locked: true, hidden: true },
    { id: "A1", kind: "Audio", name: "A", locked: false, muted: false },
    {
      id: "A3",
      kind: "Audio",
      name: "Musica",
      locked: false,
      muted: true,
      duck: { under: ["A1"], amountDb: -12, attackMs: 200, releaseMs: 600 },
    },
  ];
  const base = { enabled: true, volume: 0, fadeIn: 0, fadeOut: 0, fit: "fill" as const };
  d.clips = [
    {
      ...base,
      id: "c1",
      track: "V1",
      start: 0,
      sourceRange: { start: 25, duration: 100 },
      ref: { media: "riprese/a.mp4", frames: 500 },
      link: "g1",
      fadeIn: 5,
    },
    {
      ...base,
      id: "c2",
      track: "V1",
      start: 100,
      sourceRange: { start: 0, duration: 50 },
      ref: { media: "riprese/b.mov", frames: 300 },
      crop: { x: 0.2, y: 0, w: 0.3, h: 1 },
      fit: "fit",
      background: "blur",
    },
    {
      ...base,
      id: "c3",
      track: "V2",
      start: 30,
      sourceRange: { start: 0, duration: 75 },
      ref: { media: "foto.jpg", still: true },
      kenBurns: { from: { x: 0, y: 0, w: 1, h: 1 }, to: { x: 0.25, y: 0.25, w: 0.5, h: 0.5 } },
      enabled: false,
    },
    {
      ...base,
      id: "t1",
      track: "V2",
      start: 200,
      sourceRange: { start: 0, duration: 50 },
      ref: { generator: "text", text: "Fine", style: "lower_third", position: "bottom" },
    },
    {
      ...base,
      id: "k1",
      track: "V1",
      start: 150,
      sourceRange: { start: 0, duration: 25 },
      ref: { generator: "color", color: "#000000" },
    },
    {
      ...base,
      id: "c4",
      track: "A1",
      start: 0,
      sourceRange: { start: 25, duration: 100 },
      ref: { media: "riprese/a.mp4", frames: 500 },
      link: "g1",
      volume: -3.5,
    },
    {
      ...base,
      id: "c5",
      track: "A3",
      start: 0,
      sourceRange: { start: 0, duration: 250 },
      ref: { media: "musica.mp3", frames: 9000, audio: true },
      metadata: { note: "base" },
    },
  ];
  d.transitions = [
    { id: "x1", track: "V1", from: "c1", to: "c2", kind: "dissolve", inOffset: 10, outOffset: 10 },
    { id: "x2", track: "V1", from: "c2", to: "k1", kind: "wipe_left", inOffset: 5, outOffset: 0 },
  ];
  d.markers = [
    { id: "m1", frame: 12, color: "RED", note: "qui" },
    { id: "m2", frame: 40, duration: 10, color: "GREEN", note: "" },
  ];
  d.captions = {
    language: "it",
    burnIn: true,
    style: "bold",
    position: "top",
    segments: [{ id: "s1", start: 0, end: 40, text: "Ciao" }],
  };
  d.normalize = false;
  return cleanTimeline(d);
}

const media = {
  "riprese/a.mp4": {
    url: "E:\\Video\\a.mp4",
    name: "a.mp4",
    frames: 500,
    timecode: "10:00:00:00",
    width: 1920,
    height: 1080,
    audio: { channels: 2, sample_rate: 48000 },
  },
  "riprese/b.mov": {
    url: "E:\\Video\\b.mov",
    name: "b.mov",
    frames: 300,
    timecode: null,
    width: 1920,
    height: 1080,
    audio: null,
  },
  "foto.jpg": {
    url: "E:\\Video\\foto.jpg",
    name: "foto.jpg",
    frames: null,
    timecode: null,
    width: 800,
    height: 600,
    audio: null,
  },
  "musica.mp3": {
    url: "E:\\Video\\musica.mp3",
    name: "musica.mp3",
    frames: 9000,
    timecode: null,
    width: 0,
    height: 0,
    audio: { channels: 2, sample_rate: 44100 },
    video: false,
  },
};
const back = (url: string) =>
  Object.entries(media).find(([, m]) => resolveFileUrl(m.url) === url)?.[0];

describe("fromOtio", () => {
  it("gives the same timeline back, with all OTIO has no place for", () => {
    const d = rich();
    const text = otioText(toOtio(d, { name: "Prova", media }));
    if (process.env.RG_OTIO_OUT) writeFileSync(join(process.env.RG_OTIO_OUT, "ricca.otio"), text);
    expect(text).toBe(read("ricca.ours.otio"));
    const { doc, warnings } = fromOtio(text, { media: back });
    expect(warnings).toEqual([]);
    expect(doc).toEqual(d);
  });

  it("puts the transitions and titles where OTIO has them", () => {
    const o = JSON.parse(otioText(toOtio(rich(), { name: "Prova", media }))) as {
      tracks: {
        children: {
          name: string;
          enabled: boolean;
          children: {
            OTIO_SCHEMA: string;
            transition_type?: string;
            media_references?: {
              DEFAULT_MEDIA: {
                generator_kind?: string;
                available_range: unknown;
                target_url?: string;
              };
            };
            source_range?: { start_time: { value: number } };
          }[];
        }[];
        markers: { name: string; color: string }[];
      };
    };
    const [v1, v2, a1, a3] = o.tracks.children;
    expect(v1?.children.map((c) => c.transition_type ?? c.OTIO_SCHEMA)).toEqual([
      "Clip.2",
      "SMPTE_Dissolve",
      "Clip.2",
      "Custom_Transition",
      "Clip.2",
    ]);
    // The camera's timecode is the start of the file's material (T18): 10:00:00:00 at 25 + 25.
    expect(v1?.children[0]?.source_range?.start_time.value).toBe(900_025);
    expect(v1?.children[4]?.media_references?.DEFAULT_MEDIA.generator_kind).toBe("SolidColor");
    expect(v2?.children.map((c) => c.OTIO_SCHEMA)).toEqual(["Gap.1", "Clip.2", "Gap.1", "Clip.2"]);
    expect(v2?.children[3]?.media_references?.DEFAULT_MEDIA.generator_kind).toBe("RedGiantText");
    expect([v1?.enabled, v2?.enabled, a1?.enabled, a3?.enabled]).toEqual([
      true,
      false,
      true,
      false,
    ]);
    expect(a3?.name).toBe("Musica");
    expect(o.tracks.markers.map((m) => [m.name, m.color])).toEqual([
      ["qui", "RED"],
      ["", "GREEN"],
    ]);
  });

  it("reads an OTIO written elsewhere (no metadata of ours), at another rate", () => {
    const j = job("edicola");
    const foreign = stripMeta(toOtio(docOf(j), { name: "Edicola", media: j.media })) as Record<
      string,
      unknown
    >;
    const urls: Record<string, string> = {
      "file://localhost/mnt/media/a%201.mp4": "riprese/a 1.mp4",
      "file://localhost/E%3a/video/porto.mp4": "porto.mp4",
    };
    const { doc, warnings } = fromOtio(JSON.stringify(foreign), { media: (u) => urls[u] });
    expect(doc.format.rate).toEqual({ num: 30000, den: 1001 });
    expect(doc.tracks.map((t) => [t.id, t.name, t.hidden ?? t.muted])).toEqual([
      ["V1", "V1", false],
      ["V2", "V2", false],
      ["A1", "A1", false],
      ["A2", "A2", true],
    ]);
    // In points from the file's own start (the camera's timecode taken off).
    expect(
      doc.clips.map((c) => [c.track, c.start, c.sourceRange.start, c.sourceRange.duration]),
    ).toEqual([
      ["V1", 0, 0, 240],
      ["V1", 250, 300, 100],
      ["V2", 60, 90, 120],
      ["A1", 0, 0, 240],
      ["A1", 250, 300, 100],
      ["A2", 60, 90, 120],
    ]);
    expect(warnings).toEqual([
      "left out: clips of files outside the project (file://localhost/mnt/media/foto.jpg)",
    ]);
    expect(otioRate(24)).toEqual({ num: 24, den: 1 });
    expect(otioRate(23.976023976023978)).toEqual({ num: 24000, den: 1001 });
    expect(otioRate(12.5)).toEqual({ num: 12500, den: 1000 });
  });

  it("rescales times written at another rate, and leaves out what it does not know", () => {
    const rt = (value: number, rate = 50) => ({ OTIO_SCHEMA: "RationalTime.1", rate, value });
    const tr = (s: number, d: number, rate = 50) => ({
      OTIO_SCHEMA: "TimeRange.1",
      start_time: rt(s, rate),
      duration: rt(d, rate),
    });
    const tl = {
      OTIO_SCHEMA: "Timeline.1",
      name: "Fuori",
      global_start_time: rt(0, 25),
      tracks: {
        OTIO_SCHEMA: "Stack.1",
        markers: [
          {
            OTIO_SCHEMA: "Marker.2",
            name: "uno",
            comment: "nota",
            color: "ORANGE",
            marked_range: tr(100, 0),
          },
        ],
        children: [
          {
            OTIO_SCHEMA: "Track.1",
            kind: "Video",
            name: "Camera",
            children: [
              { OTIO_SCHEMA: "Gap.1", source_range: tr(0, 50) },
              {
                OTIO_SCHEMA: "Clip.1",
                name: "x",
                source_range: tr(10, 100),
                media_reference: { OTIO_SCHEMA: "ExternalReference.1", target_url: "x.mp4" },
              },
              { OTIO_SCHEMA: "Transition.1", in_offset: rt(10), out_offset: rt(10) },
              {
                OTIO_SCHEMA: "Clip.2",
                name: "s",
                source_range: tr(0, 50),
                media_references: { DEFAULT_MEDIA: { OTIO_SCHEMA: "MissingReference.1" } },
                active_media_reference_key: "DEFAULT_MEDIA",
              },
              { OTIO_SCHEMA: "Stack.1", source_range: tr(0, 20), children: [] },
            ],
          },
          { OTIO_SCHEMA: "Track.1", kind: "Data", children: [] },
        ],
      },
    };
    const { doc, warnings } = fromOtio(JSON.stringify(tl), {
      media: (u) => (u === "x.mp4" ? "x.mp4" : undefined),
    });
    expect(doc.format.rate).toEqual({ num: 25, den: 1 });
    expect(
      doc.clips.map((c) => [c.track, c.start, c.sourceRange.start, c.sourceRange.duration, c.name]),
    ).toEqual([["V1", 25, 5, 50, "x"]]);
    expect(doc.markers).toEqual([{ id: "m1", frame: 50, color: "ORANGE", note: "uno — nota" }]);
    expect(doc.tracks.map((t) => t.id)).toEqual(["V1", "A1"]);
    expect(warnings).toEqual([
      "left out: clips with a MissingReference reference (no file)",
      "left out: a Stack inside a track (nested stacks are not read)",
      'left out: a track of kind "Data"',
    ]);
    expect(() => fromOtio("{}", { media: () => undefined })).toThrow(/no OpenTimelineIO timeline/);
    expect(() => fromOtio("nope", { media: () => undefined })).toThrow(/not JSON/);
  });
});
