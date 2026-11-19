// G41.5d's pure parts in the protocol: A1, where a picture sits in the frame (the crop that keeps
// the frame's shape, moved and kept inside the picture, and the page's geometry of the render's
// crop, fill and fit); A2, the timeline's switch for −14 LUFS, kept through the file and undone
// exactly; A5, the named versions' names, folder and copies.
import { describe, expect, it } from "vitest";
import {
  applyVideoAction,
  cropOf,
  diffTimeline,
  framePicture,
  fromVersion,
  invertVideoAction,
  moveCrop,
  needsReframe,
  newRgVideo,
  type RgVideo,
  readRgVideo,
  reframeCrop,
  rgvideoVersionPath,
  rgvideoVersionsDir,
  setNormalize,
  type VideoRect,
  versionFileOf,
  versionStamp,
  videoVersionOf,
  wholeCrop,
  writeRgVideo,
} from "../src/index.js";

const HD = { w: 1920, h: 1080 };
const VERT = { w: 1080, h: 1920 };
const SQ = { w: 1080, h: 1080 };

describe("A1: the crop", () => {
  it.each([
    [
      "a wide shot in 9:16 keeps its height and a third of its width",
      HD,
      VERT,
      0.5,
      0.5,
      { x: 0.3418, y: 0, w: 0.3164, h: 1 },
    ],
    ["moved to the left edge", HD, VERT, 0, 0.5, { x: 0, y: 0, w: 0.3164, h: 1 }],
    [
      "moved past the right edge stops there",
      HD,
      VERT,
      1,
      0.5,
      { x: 0.6836, y: 0, w: 0.3164, h: 1 },
    ],
    ["a wide shot in 1:1", HD, SQ, 0.5, 0.5, { x: 0.2188, y: 0, w: 0.5625, h: 1 }],
    [
      "a vertical shot in 16:9 keeps its width",
      VERT,
      HD,
      0.5,
      0.5,
      { x: 0, y: 0.3418, w: 1, h: 0.3164 },
    ],
    ["a vertical shot in 16:9, from the top", VERT, HD, 0.5, 0, { x: 0, y: 0, w: 1, h: 0.3164 }],
    ["the same shape: the whole picture", HD, HD, 0.5, 0.5, { x: 0, y: 0, w: 1, h: 1 }],
  ] as const)("%s", (_w, src, out, cx, cy, want) => {
    expect(reframeCrop(src, out, cx, cy)).toEqual(want);
  });

  it.each([
    ["right a tenth", 0.1, 0, { x: 0.4418, y: 0, w: 0.3164, h: 1 }],
    ["left beyond the edge stops at 0", -0.9, 0, { x: 0, y: 0, w: 0.3164, h: 1 }],
    ["right beyond the edge stops at 1 - w", 0.9, 0, { x: 0.6836, y: 0, w: 0.3164, h: 1 }],
    [
      "down when it is as tall as the picture: nothing",
      0,
      0.2,
      { x: 0.3418, y: 0, w: 0.3164, h: 1 },
    ],
  ] as const)("moved %s", (_w, dx, dy, want) => {
    expect(moveCrop({ x: 0.3418, y: 0, w: 0.3164, h: 1 }, dx, dy)).toEqual(want);
  });

  it.each([
    ["wide in vertical", HD, VERT, true],
    ["wide in square", HD, SQ, true],
    ["the same shape", HD, { w: 1280, h: 720 }, false],
    ["almost the same (1%)", { w: 1920, h: 1088 }, HD, false],
    ["unknown size", { w: 0, h: 0 }, HD, false],
  ] as const)("needsReframe: %s", (_w, src, out, want) => {
    expect(needsReframe(src, out)).toBe(want);
  });

  it("the render's crop never passes the right and bottom edges; the whole picture is no crop", () => {
    expect(cropOf({ x: 0.8, y: 0.5, w: 0.5, h: 0.7 })).toEqual({ x: 0.8, y: 0.5, w: 0.2, h: 0.5 });
    expect(wholeCrop(undefined)).toBe(true);
    expect(wholeCrop({ x: 0, y: 0, w: 1, h: 1 })).toBe(true);
    expect(wholeCrop({ x: 0, y: 0, w: 0.5, h: 1 })).toBe(false);
  });
});

describe("A1: the picture's place in the frame (the page's geometry of the render)", () => {
  const third: VideoRect = { x: 0.3418, y: 0, w: 0.3164, h: 1 };
  it.each([
    // fill: the shorter side covers the frame, the rest spills out centred (a crop rounded to
    // four decimals, as the render writes it, is a hair off the frame's shape: filled, as ffmpeg)
    ["fill, the same shape", HD, HD, "fill", undefined, { left: 0, top: 0, width: 1, height: 1 }],
    [
      "fill, wide in vertical: three frames wide, centred",
      HD,
      VERT,
      "fill",
      undefined,
      { left: -1.080247, top: 0, width: 3.160494, height: 1 },
    ],
    [
      "fit, wide in vertical: the whole width, a band in the middle",
      HD,
      VERT,
      "fit",
      undefined,
      { left: 0, top: 0.341797, width: 1, height: 0.316406 },
    ],
    [
      "fill with a crop of the frame's shape: the crop is the frame",
      HD,
      VERT,
      "fill",
      third,
      {
        left: -1.080278,
        top: -0.00001,
        width: 3.160556,
        height: 1.00002,
        clip: { top: 0, right: 0.3418, bottom: 0, left: 0.3418 },
      },
    ],
    [
      "fill, the crop moved to the left edge",
      HD,
      VERT,
      "fill",
      { x: 0, y: 0, w: 0.3164, h: 1 },
      {
        left: 0,
        top: -0.00001,
        width: 3.160556,
        height: 1.00002,
        clip: { top: 0, right: 0.6836, bottom: 0, left: 0 },
      },
    ],
    [
      "fit, a quarter at the top left, in its own shape",
      HD,
      HD,
      "fit",
      { x: 0, y: 0, w: 0.5, h: 0.5 },
      { left: 0, top: 0, width: 2, height: 2, clip: { top: 0, right: 0.5, bottom: 0.5, left: 0 } },
    ],
    [
      "fit, a tall crop of a wide frame: centred, bands at the sides",
      HD,
      HD,
      "fit",
      { x: 0.25, y: 0, w: 0.25, h: 1 },
      {
        left: 0.125,
        top: 0,
        width: 1,
        height: 1,
        clip: { top: 0, right: 0.5, bottom: 0, left: 0.25 },
      },
    ],
  ] as const)("%s", (_w, src, out, fit, crop, want) => {
    expect(framePicture(src, out, fit, crop)).toEqual(want);
  });

  it("the crop's centre is always the frame's centre", () => {
    for (const [crop, fit] of [
      [{ x: 0.1, y: 0.2, w: 0.3, h: 0.4 }, "fill"],
      [{ x: 0.6, y: 0, w: 0.4, h: 0.9 }, "fit"],
    ] as const) {
      const f = framePicture(HD, VERT, fit, crop);
      expect(f.left + (crop.x + crop.w / 2) * f.width).toBeCloseTo(0.5, 5);
      expect(f.top + (crop.y + crop.h / 2) * f.height).toBeCloseTo(0.5, 5);
    }
  });
});

describe("A2: the timeline's switch for the loudness", () => {
  it("on by default; off is kept in the file; on again removes it; undone to the same bytes", () => {
    const d = newRgVideo();
    expect(d.normalize).toBeUndefined();
    expect(setNormalize(d, true)).toBe(d);
    const off = setNormalize(d, false);
    expect(off.normalize).toBe(false);
    expect(readRgVideo(writeRgVideo(off)).normalize).toBe(false);
    expect(setNormalize(off, true).normalize).toBeUndefined();
    const a = diffTimeline(d, off, "format");
    expect(a).toEqual({
      t: "batch",
      what: "format",
      ops: [{ t: "meta", key: "normalize", value: false }],
    });
    if (!a) throw new Error("no action");
    const applied = applyVideoAction(d, a);
    expect(applied.normalize).toBe(false);
    const back = applyVideoAction(applied, invertVideoAction(d, a));
    expect(writeRgVideo(back)).toBe(writeRgVideo(d));
  });

  it("a file with something else in it reads as on", () => {
    const text = writeRgVideo(newRgVideo()).replace(
      '"formatVersion": 1,',
      '"formatVersion": 1, "normalize": "yes",',
    );
    expect(readRgVideo(text).normalize).toBeUndefined();
  });
});

describe("A5: named versions", () => {
  it.each([
    ["video/gita.rgvideo", "video/gita.versions"],
    ["gita.rgvideo", "gita.versions"],
    ["a\\b\\Gita estate.RGVIDEO", "a/b/Gita estate.versions"],
  ])("the versions of %s are in %s", (path, dir) => {
    expect(rgvideoVersionsDir(path)).toBe(dir);
    expect(rgvideoVersionPath(path, "Prima", "2026-11-16 1530").startsWith(`${dir}/`)).toBe(true);
  });

  it("a stamp sorts by time; a version file's name is read back, anything else is not", () => {
    expect(versionStamp(new Date(2026, 10, 6, 9, 5))).toBe("2026-11-06 0905");
    expect(versionStamp(new Date(2026, 10, 16, 15, 30))).toBe("2026-11-16 1530");
    const p = rgvideoVersionPath("video/gita.rgvideo", "Prima bozza: corta?", "2026-11-16 1530");
    expect(p).toBe("video/gita.versions/2026-11-16 1530 Prima bozza corta.rgvideo");
    expect(versionFileOf(p)).toEqual({ stamp: "2026-11-16 1530", name: "Prima bozza corta" });
    expect(versionFileOf("video/gita.versions/note.txt")).toBeUndefined();
    expect(versionFileOf("2026-11-16 1530.rgvideo")).toBeUndefined();
  });

  it("a version's copy says what it is; brought back it is the same timeline without that", () => {
    const d: RgVideo = newRgVideo({ width: 1080, height: 1920, aspect: "9:16" }, "Gita");
    d.normalize = false;
    const v = videoVersionOf(d, {
      name: "  Prima  ",
      at: "2026-11-16T15:30:00.000Z",
      of: "video/gita.rgvideo",
      reason: "before_assemble",
    });
    expect(v.version).toEqual({
      name: "Prima",
      at: "2026-11-16T15:30:00.000Z",
      of: "video/gita.rgvideo",
      reason: "before_assemble",
    });
    expect(d.version).toBeUndefined();
    const text = writeRgVideo(v);
    expect(readRgVideo(text).version?.reason).toBe("before_assemble");
    expect(writeRgVideo(fromVersion(readRgVideo(text)))).toBe(writeRgVideo(d));
  });
});
