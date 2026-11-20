// 3.10, video part 2: a Resolve (FCP7 XML) timeline read into a .rgvideo. Our own export read back
// (tracks, clips, speeds, boxes with keys, volumes with keys, clips off), an XML written as Resolve
// writes it (a file named once then by id, start -1 after a transition, a dissolve, a marker, a
// title), what is left out said, and what is not XML refused.
import { describe, expect, it } from "vitest";
import {
  fcp7Xml,
  fromFcp7Xml,
  newRgVideo,
  parseXml,
  type RgVideo,
  resolveJob,
  type VideoClip,
} from "../src/index.js";

const R = { num: 25, den: 1 };
const clip = (
  id: string,
  track: string,
  start: number,
  dur: number,
  media: string,
  more: Partial<VideoClip> = {},
  src = 0,
): VideoClip => ({
  id,
  track,
  start,
  sourceRange: { start: src, duration: dur },
  ref: { media, frames: 1000 },
  enabled: true,
  volume: 0,
  fadeIn: 0,
  fadeOut: 0,
  fit: "fill",
  ...more,
});

function film(): RgVideo {
  const d = newRgVideo({ width: 1920, height: 1080, rate: R, aspect: "16:9" }, "Gita");
  d.tracks = [
    { id: "V1", kind: "Video", name: "V1", locked: false },
    { id: "V2", kind: "Video", name: "V2", locked: false },
    { id: "A1", kind: "Audio", name: "A1", locked: false },
  ];
  d.clips = [
    clip("a", "V1", 0, 100, "riprese/a.mp4", { speed: 2 }, 50),
    clip("b", "V1", 100, 50, "riprese/b.mp4", { enabled: false }),
    clip("p", "V2", 20, 60, "riprese/b.mp4", {
      boxKeys: [
        { at: 0, x: 0.75, y: 0.25, scale: 0.3 },
        { at: 59, x: 0.25, y: 0.75, scale: 0.5 },
      ],
    }),
    clip("s", "A1", 0, 150, "musica/m.m4a", {
      volumeKeys: [
        { at: 0, db: -20 },
        { at: 100, db: 0 },
      ],
    }),
  ];
  return d;
}

const facts = (kind: "video" | "audio") => ({
  kind,
  duration: 40,
  width: 1920,
  height: 1080,
  audio: true,
  channels: 2,
  sampleRate: 48000,
  timecode: null,
});

describe("FCP7 XML in", () => {
  it("reads back our own export: tracks, clips, speed, box keys, volume keys, clips off", () => {
    const { job } = resolveJob(
      film(),
      {
        "riprese/a.mp4": facts("video"),
        "riprese/b.mp4": facts("video"),
        "musica/m.m4a": facts("audio"),
      },
      { name: "Gita", path: (m) => `/progetto/${m}` },
    );
    const xml = fcp7Xml(job);
    expect(xml).toContain("<effectid>timeremap</effectid>");
    expect(xml).toContain("<effectid>basic</effectid>");
    expect(xml).toContain("<effectid>audiolevels</effectid>");
    const { doc, warnings } = fromFcp7Xml(xml, {
      media: (url) => decodeURI(url).replace(/^file:\/\/localhost\/progetto\//, ""),
    });
    expect(warnings).toEqual([]);
    expect(doc.name).toBe("Gita");
    expect(doc.format).toMatchObject({ width: 1920, height: 1080, rate: R });
    const by = (m: string, t: string) =>
      doc.clips.find((c) => "media" in c.ref && c.ref.media === m && c.track === t) as VideoClip;
    expect(by("riprese/a.mp4", "V1")).toMatchObject({
      start: 0,
      sourceRange: { start: 50, duration: 100 },
      speed: 2,
    });
    expect(by("riprese/b.mp4", "V1")).toMatchObject({ start: 100, enabled: false });
    const p = by("riprese/b.mp4", "V2");
    expect(p.boxKeys?.map((k) => [k.at, k.x, k.y, k.scale])).toEqual([
      [0, 0.75, 0.25, 0.3],
      [59, 0.25, 0.75, 0.5],
    ]);
    const s = by("musica/m.m4a", "A1");
    expect(s.volumeKeys?.map((k) => [k.at, Math.round(k.db)])).toEqual([
      [0, -20],
      [100, 0],
    ]);
  });

  it("an XML as Resolve writes it: a file by its id, a dissolve, a marker; the rest said", () => {
    const xml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xmeml>
<xmeml version="5">
  <sequence id="s1">
    <name>Matrimonio &amp; festa</name>
    <rate><timebase>30</timebase><ntsc>TRUE</ntsc></rate>
    <media>
      <video>
        <format><samplecharacteristics><width>3840</width><height>2160</height></samplecharacteristics></format>
        <track>
          <clipitem id="c1"><name>A001</name><start>0</start><end>60</end><in>120</in><out>180</out>
            <file id="f1"><name>A001.mov</name><pathurl>file://localhost/E%3a/Sposi/A001.mov</pathurl><duration>900</duration><media><video/><audio/></media></file>
          </clipitem>
          <transitionitem><start>50</start><end>70</end><effect><name>Cross Dissolve</name></effect></transitionitem>
          <clipitem id="c2"><name>A001</name><start>-1</start><end>120</end><in>300</in><out>360</out><file id="f1"/></clipitem>
          <generatoritem id="g1"><name>Titolo</name><start>120</start><end>150</end></generatoritem>
          <clipitem id="c3"><name>X</name><start>150</start><end>200</end><in>0</in><out>50</out>
            <file id="f2"><name>X.mov</name><pathurl>file://localhost/C%3a/Altrove/X.mov</pathurl></file>
            <filter><effect><name>Gaussian Blur</name><effectid>gaussianblur</effectid></effect></filter>
          </clipitem>
        </track>
        <track><enabled>FALSE</enabled></track>
      </video>
      <audio><track><clipitem id="a1"><name>A001</name><start>0</start><end>60</end><in>120</in><out>180</out><file id="f1"/></clipitem></track></audio>
    </media>
    <marker><name>Bacio</name><comment>più lungo</comment><in>90</in><out>-1</out></marker>
  </sequence>
</xmeml>`;
    const { doc, warnings } = fromFcp7Xml(xml, {
      media: (url) => (url.includes("/Sposi/") ? `girato/${url.split("/").pop()}` : undefined),
    });
    expect(doc.name).toBe("Matrimonio & festa");
    expect(doc.format).toMatchObject({
      width: 3840,
      height: 2160,
      rate: { num: 30000, den: 1001 },
    });
    const v1 = doc.clips.filter((c) => c.track === "V1");
    expect(v1.map((c) => [c.start, c.sourceRange.start, c.sourceRange.duration])).toEqual([
      [0, 120, 60],
      [60, 300, 60],
    ]);
    expect(doc.transitions).toHaveLength(1);
    expect(doc.transitions[0]).toMatchObject({ kind: "dissolve", inOffset: 10, outOffset: 10 });
    expect(doc.tracks.find((t) => t.id === "V2")?.hidden).toBe(true);
    expect(doc.clips.filter((c) => c.track === "A1")).toHaveLength(1);
    expect(doc.markers).toEqual([
      { id: "m1", frame: 90, color: "BLUE", note: "Bacio — più lungo" },
    ]);
    expect(warnings).toEqual(["X.mov: not a file of the project, left out"]);
  });

  it("refuses what is not an FCP7 XML", () => {
    expect(() => fromFcp7Xml("<fcpxml/>", { media: () => undefined })).toThrow("not an FCP7 XML");
    expect(() => parseXml("<a><b></a>")).toThrow("</a> closes <b>");
    expect(() => fromFcp7Xml("<xmeml/>", { media: () => undefined })).toThrow("no sequence");
  });
});
