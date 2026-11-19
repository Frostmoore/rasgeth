// G41.6b: the timeline for DaVinci Resolve. The XML is compared byte for byte with what
// montatore's own engine wrote (fixtures/resolve/<name>.xml from <name>.job.json: a copy of
// engine/montatore_engine run with OpenTimelineIO 0.18.1 and otio-fcp-adapter 1.0.0, see
// fixtures/resolve/README), then read back by an XML parser; OpenTimelineIO's timecode reading is
// checked against a table OpenTimelineIO itself wrote.
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";
import {
  fcp7Xml,
  newRgVideo,
  otioTimecodeFrame,
  pyQuote,
  pyUnquote,
  type ResolveFileFacts,
  type ResolveJob,
  ResolveRateError,
  type RgVideo,
  resolveFileUrl,
  resolveJob,
  resolveMediaPaths,
  resolveRateOk,
} from "../src/index.js";

const DIR = join(import.meta.dirname, "fixtures", "resolve");
const job = (n: string) =>
  JSON.parse(readFileSync(join(DIR, `${n}.job.json`), "utf8")) as ResolveJob;
const NAMES = readdirSync(DIR)
  .filter((f) => f.endsWith(".xml"))
  .map((f) => f.replace(/\.xml$/, ""));

describe("fcp7Xml: the same text montatore's engine writes", () => {
  it("has every reference", () => {
    expect(NAMES.sort()).toEqual([
      "audio-lunga",
      "edicola",
      "film24",
      "matrimonio",
      "ntsc59",
      "ripetute",
      "vuota",
    ]);
  });
  it.each(NAMES)("%s", (n) => {
    expect(fcp7Xml(job(n))).toBe(readFileSync(join(DIR, `${n}.xml`), "utf8"));
  });
  it("refuses a rate without SMPTE timecode, as montatore's engine fails there", () => {
    expect(() => fcp7Xml(job("rate12"))).toThrow(ResolveRateError);
    expect(resolveRateOk(12, 1)).toBe(false);
    expect(resolveRateOk(30000, 1001)).toBe(true);
    expect(resolveRateOk(2400, 100)).toBe(true);
    expect(resolveRateOk(2997, 100)).toBe(false);
  });
  it("carries what Resolve needs (T17, T18, T19; read by a real XML parser in web/test/video-6b)", () => {
    const xml = fcp7Xml(job("edicola"));
    expect(xml).toContain("<pathurl>file://localhost/E%3a/video/porto.mp4</pathurl>");
    expect(xml.match(/<sourcetrack><mediatype>(video|audio)<\/mediatype>/g)).toHaveLength(7);
    expect(xml).toContain("<string>12:12:33;23</string>\n");
    expect(xml.match(/<enabled>FALSE<\/enabled>/g)).toHaveLength(3);
  });
  it("describes a sound-only file without a picture (on purpose, unlike montatore)", () => {
    const j = job("audio-lunga");
    (j.media.v as { video?: boolean }).video = false;
    const xml = fcp7Xml(j);
    expect(xml).not.toContain("<video><samplecharacteristics>");
    expect(xml).toContain("<media>\n");
    // Everything else is the reference's.
    expect(xml.replace(/\s+/g, "")).toBe(
      readFileSync(join(DIR, "audio-lunga.xml"), "utf8")
        .replace(
          "<video><samplecharacteristics><width>1080</width><height>1920</height></samplecharacteristics></video>",
          "",
        )
        .replace(/\s+/g, ""),
    );
  });
});

describe("OpenTimelineIO's from_timecode", () => {
  const table = JSON.parse(readFileSync(join(DIR, "otio-timecodes.json"), "utf8")) as {
    num: number;
    den: number;
    tc: string;
    frame: number;
  }[];
  it("matches the table OpenTimelineIO 0.18.1 wrote (failures are 0 in montatore)", () => {
    expect(table.length).toBeGreaterThan(150);
    for (const r of table)
      expect([r.num, r.den, r.tc, otioTimecodeFrame(r.tc, r.num / r.den) ?? 0]).toEqual([
        r.num,
        r.den,
        r.tc,
        r.frame,
      ]);
  });
});

describe("paths as Resolve reads them (T17)", () => {
  it.each([
    [
      "E:\\Fotocamera\\2026-10-29\\MVI_0570.MP4",
      "file://localhost/E%3a/Fotocamera/2026-10-29/MVI_0570.MP4",
    ],
    ["E:/video/MVI 1.MP4", "file://localhost/E%3a/video/MVI%201.MP4"],
    ["/mnt/a b/x.mp4", "file://localhost/mnt/a%20b/x.mp4"],
    ["\\\\nas\\video\\x.mp4", "file://nas/video/x.mp4"],
    ["file:///già/così", "file:///già/così"],
    ["/a/è #1 50%?~.mp4", "file://localhost/a/%C3%A8%20%231%2050%25%3F~.mp4"],
  ])("%s", (p, url) => {
    expect(resolveFileUrl(p)).toBe(url);
  });
  it("quotes and unquotes as Python does", () => {
    expect(pyQuote("a b/c!'()*")).toBe("a%20b/c%21%27%28%29%2A");
    expect(pyUnquote("a%20%C3%A8%zz%")).toBe("a è%zz%");
  });
  it("finds the originals in the person's folder by name (D21), with folders only for twins", () => {
    const abs = (m: string) => `/data/p/${m}`;
    expect(resolveMediaPaths(["riprese/a.mp4", "foto.jpg"], undefined, abs)).toEqual({
      "riprese/a.mp4": "/data/p/riprese/a.mp4",
      "foto.jpg": "/data/p/foto.jpg",
    });
    expect(resolveMediaPaths(["riprese/a.mp4", "foto.jpg"], "E:\\Video\\Sposi\\", abs)).toEqual({
      "riprese/a.mp4": "E:\\Video\\Sposi\\a.mp4",
      "foto.jpg": "E:\\Video\\Sposi\\foto.jpg",
    });
    expect(resolveMediaPaths(["a/x.mp4", "b/X.MP4", "c.mp4"], "/Volumes/Disco", abs)).toEqual({
      "a/x.mp4": "/Volumes/Disco/a/x.mp4",
      "b/X.MP4": "/Volumes/Disco/b/X.MP4",
      "c.mp4": "/Volumes/Disco/c.mp4",
    });
  });
});

describe("resolveJob: montatore's job from a timeline", () => {
  const facts: Record<string, ResolveFileFacts> = {
    "riprese/a 1.mp4": {
      kind: "video",
      duration: 20.03,
      width: 3840,
      height: 2160,
      audio: true,
      channels: 2,
      sampleRate: 48000,
      timecode: "12:12:33;23",
    },
    "porto.mp4": {
      kind: "video",
      duration: 12.0121,
      width: 1920,
      height: 1080,
      audio: true,
      channels: null,
      sampleRate: null,
      timecode: "garbage",
    },
    "foto.jpg": {
      kind: "image",
      duration: null,
      width: 1200,
      height: 800,
      audio: false,
      channels: null,
      sampleRate: null,
      timecode: null,
    },
    "musica.mp3": {
      kind: "audio",
      duration: 30,
      width: 0,
      height: 0,
      audio: true,
      channels: 2,
      sampleRate: 44100,
      timecode: null,
    },
  };
  const doc = (): RgVideo => {
    const d = newRgVideo();
    d.format.rate = { num: 30000, den: 1001 };
    d.format.width = 3840;
    d.format.height = 2160;
    d.tracks = [
      { id: "V1", kind: "Video", name: "A", locked: false },
      { id: "V2", kind: "Video", name: "B", locked: false, hidden: true },
      { id: "A1", kind: "Audio", name: "A", locked: false },
      {
        id: "A2",
        kind: "Audio",
        name: "Musica",
        locked: false,
        muted: false,
        duck: { under: ["A1"], amountDb: -12, attackMs: 200, releaseMs: 600 },
      },
    ];
    const clip = (
      id: string,
      track: string,
      start: number,
      media: string,
      s: number,
      d: number,
      extra = {},
    ) => ({
      id,
      track,
      start,
      sourceRange: { start: s, duration: d },
      ref: { media },
      enabled: true,
      volume: 0,
      fadeIn: 0,
      fadeOut: 0,
      fit: "fill" as const,
      ...extra,
    });
    d.clips = [
      clip("c1", "V1", 0, "riprese/a 1.mp4", 0, 240, { link: "g1" }),
      clip("c2", "V1", 250, "riprese/a 1.mp4", 300, 100, { fadeIn: 10 }),
      {
        ...clip("t1", "V1", 350, "x", 0, 50),
        ref: {
          generator: "text" as const,
          text: "Fine",
          style: "title" as const,
          position: "center" as const,
        },
      },
      clip("c3", "V2", 60, "porto.mp4", 90, 120, {
        kenBurns: { from: { x: 0, y: 0, w: 1, h: 1 }, to: { x: 0.1, y: 0.1, w: 0.8, h: 0.8 } },
      }),
      clip("c4", "V2", 300, "foto.jpg", 0, 90, { enabled: false }),
      clip("c5", "A1", 0, "riprese/a 1.mp4", 0, 240, { link: "g1", volume: -3 }),
      clip("c6", "A2", 0, "musica.mp3", 0, 400),
      clip("c7", "V1", 500, "sparito.mov", 10, 20),
    ];
    d.markers = [{ id: "m1", frame: 10, color: "RED", note: "qui" }];
    return d;
  };

  it("keeps every track, on or off, and the clips of files by start", () => {
    const { job: j, leftOut } = resolveJob(doc(), facts, {
      name: "Edicola",
      path: (m) => `E:\\Video\\${m.split("/").pop()}`,
    });
    expect(j.tracks.map((t) => [t.id, t.type, t.enabled, t.clips.length])).toEqual([
      ["V1", "video", true, 3],
      ["V2", "video", false, 2],
      ["A1", "audio", true, 1],
      ["A2", "audio", true, 1],
    ]);
    expect(j.tracks[1]?.clips[1]).toEqual({
      media: "foto.jpg",
      start: 300,
      in: 0,
      dur: 90,
      enabled: false,
    });
    expect(j.media["riprese/a 1.mp4"]).toEqual({
      url: "E:\\Video\\a 1.mp4",
      name: "a 1.mp4",
      frames: 600,
      timecode: "12:12:33;23",
      width: 3840,
      height: 2160,
      audio: { channels: 2, sample_rate: 48000 },
    });
    expect(j.media["porto.mp4"]).toMatchObject({
      timecode: null,
      frames: 360,
      audio: { channels: 2, sample_rate: 48000 },
    });
    expect(j.media["foto.jpg"]).toMatchObject({ frames: null, audio: null });
    expect(j.media["musica.mp3"]).toMatchObject({
      video: false,
      audio: { channels: 2, sample_rate: 44100 },
    });
    expect(j.media["sparito.mov"]).toMatchObject({
      frames: 30,
      timecode: null,
      width: 0,
      audio: { channels: 2 },
    });
    expect(leftOut).toEqual({
      titles: 1,
      transitions: 0,
      fades: 1,
      volumes: 1,
      kenBurns: 1,
      reframes: 0,
      speeds: 0,
      ducking: 1,
      markers: 1,
      captions: 0,
      missing: ["sparito.mov"],
    });
    const xml = fcp7Xml(j);
    expect(xml).toContain("<pathurl>file://localhost/E%3a/Video/a%201.mp4</pathurl>");
    expect(xml).toContain("<string>12:12:33;23</string>");
    expect(xml.match(/<clipitem /g)).toHaveLength(7);
  });

  it("gives montatore's own job for montatore's test timeline", () => {
    const d = doc();
    d.tracks = d.tracks.map((t) => ({
      ...t,
      hidden: undefined,
      muted: t.id === "A2" ? true : undefined,
    }));
    d.clips = d.clips.filter((c) => ["c1", "c2", "c3", "c4", "c5"].includes(c.id));
    d.clips.push({
      ...(d.clips[4] as RgVideo["clips"][number]),
      id: "c8",
      start: 250,
      sourceRange: { start: 300, duration: 100 },
    });
    d.clips.push({
      ...(d.clips[2] as RgVideo["clips"][number]),
      id: "c9",
      track: "A2",
      enabled: false,
    });
    for (const c of d.clips)
      c.ref = { media: (c.ref as { media: string }).media.replace("riprese/a 1.mp4", "a 1.mp4") };
    const f = { ...facts, "a 1.mp4": facts["riprese/a 1.mp4"] as ResolveFileFacts };
    const urls: Record<string, string> = {
      "a 1.mp4": "/mnt/media/a 1.mp4",
      "porto.mp4": "E:\\video\\porto.mp4",
      "foto.jpg": "/mnt/media/foto.jpg",
    };
    const { job: j } = resolveJob(d, f, { name: "Edicola", path: (m) => urls[m] as string });
    // montatore's ids are its database's; the text is the same.
    expect(fcp7Xml(j)).toBe(readFileSync(join(DIR, "edicola.xml"), "utf8"));
  });
});
