// 3.10, video part 2 (G41.20a): the picture's box and the volume over time (simple linear keys),
// the colour, a LUT and a still frame kept in order; Resolve's slip, slide and roll; the music's
// beats in the snapping and «Taglia a ritmo». Every edit undone exactly through its actions, and a
// file's values cleaned within their limits.
import { describe, expect, it } from "vitest";
import {
  applyVideoAction,
  boxAt,
  cleanTimeline,
  cutsToBeats,
  diffTimeline,
  FULL_BOX,
  newRgVideo,
  type RgVideo,
  rollEdit,
  setBeats,
  setClipKey,
  setClipProps,
  slideClip,
  slipClip,
  snapPoints,
  sourceUsed,
  type VideoClip,
  volumeAt,
} from "../src/index.js";

const R = { num: 25, den: 1 };
const clip = (
  id: string,
  track: string,
  start: number,
  dur: number,
  srcStart: number,
  more: Partial<VideoClip> = {},
): VideoClip => ({
  id,
  track,
  start,
  sourceRange: { start: srcStart, duration: dur },
  ref: { media: `v/${id}.mp4`, frames: 500 },
  enabled: true,
  volume: 0,
  fadeIn: 0,
  fadeOut: 0,
  fit: "fill",
  ...more,
});
/** Three clips touching on V1: a 0-100, b 100-200 (source 50), c 200-300 (source 100). */
function three(): RgVideo {
  const d = newRgVideo({ width: 1920, height: 1080, rate: R, aspect: "16:9" }, "Prova");
  d.clips = [
    clip("a", "V1", 0, 100, 0),
    clip("b", "V1", 100, 100, 50),
    clip("c", "V1", 200, 100, 100),
  ];
  return d;
}
const get = (d: RgVideo, id: string) => d.clips.find((c) => c.id === id) as VideoClip;
/** The edit undone through the actions of its difference: the very same timeline. */
function roundTrip(before: RgVideo, after: RgVideo) {
  const fwd = diffTimeline(before, after);
  const back = diffTimeline(after, before);
  expect(fwd).toBeDefined();
  expect(applyVideoAction(before, fwd as never)).toEqual(after);
  expect(applyVideoAction(after, back as never)).toEqual(before);
}

describe("keys", () => {
  const c = {
    box: { x: 0.8, y: 0.2, scale: 0.3 },
    boxKeys: [
      { at: 0, x: 0.5, y: 0.5, scale: 1 },
      { at: 50, x: 0.8, y: 0.2, scale: 0.3 },
    ],
    volume: -3,
    volumeKeys: [
      { at: 10, db: 0 },
      { at: 20, db: -20 },
    ],
  };
  it.each([
    [0, { x: 0.5, y: 0.5, scale: 1 }],
    [25, { x: 0.65, y: 0.35, scale: 0.65 }],
    [50, { x: 0.8, y: 0.2, scale: 0.3 }],
    [99, { x: 0.8, y: 0.2, scale: 0.3 }],
  ])("the box at frame %i of the clip", (at, want) => {
    const b = boxAt(c, at);
    expect(b.x).toBeCloseTo(want.x);
    expect(b.y).toBeCloseTo(want.y);
    expect(b.scale).toBeCloseTo(want.scale);
  });
  it.each([
    [0, 0],
    [10, 0],
    [15, -10],
    [20, -20],
    [80, -20],
  ])("the volume at frame %i is %d dB", (at, db) => {
    expect(volumeAt(c, at)).toBeCloseTo(db);
  });
  it("without keys: the box, else the whole frame; the volume", () => {
    expect(boxAt({ box: c.box }, 30)).toEqual(c.box);
    expect(boxAt({}, 30)).toEqual(FULL_BOX);
    expect(volumeAt({ volume: -6 }, 30)).toBe(-6);
  });

  it("a first key later in the clip keeps the present box at its start; removed one by one", () => {
    const d0 = three();
    const d1 = setClipKey(d0, "b", "box", 140, { x: 0.75, y: 0.25, scale: 0.4 });
    expect(get(d1, "b").boxKeys).toEqual([
      { at: 0, ...FULL_BOX },
      { at: 40, x: 0.75, y: 0.25, scale: 0.4 },
    ]);
    roundTrip(d0, d1);
    // A frame outside the clip lands on its last frame; the same frame replaces.
    const d2 = setClipKey(d1, "b", "box", 900, { x: 0.1, y: 0.1, scale: 0.2 });
    expect(get(d2, "b").boxKeys?.map((k) => k.at)).toEqual([0, 40, 99]);
    const d3 = setClipKey(d2, "b", "box", 140, null);
    expect(get(d3, "b").boxKeys?.map((k) => k.at)).toEqual([0, 99]);
    const d4 = setClipKey(setClipKey(d3, "b", "box", 199, null), "b", "box", 100, null);
    expect(get(d4, "b").boxKeys).toBeUndefined();
  });

  it("volume keys start from the clip's volume and stay within −60…12 dB", () => {
    const d0 = setClipProps(three(), ["a"], { volume: -6 });
    const d1 = setClipKey(d0, "a", "volume", 50, 40);
    expect(get(d1, "a").volumeKeys).toEqual([
      { at: 0, db: -6 },
      { at: 50, db: 12 },
    ]);
    roundTrip(d0, d1);
  });

  it("colour, LUT, still frame and speed are kept tidy", () => {
    const d0 = three();
    const d1 = setClipProps(d0, ["a"], {
      color: { exposure: 0.5, contrast: 0.2, saturation: -1, temperature: 0.3 },
      lut: "lut/film.cube",
      freeze: true,
      speed: 2,
    });
    expect(get(d1, "a")).toMatchObject({
      color: { exposure: 0.5, contrast: 0.2, saturation: -1, temperature: 0.3 },
      lut: "lut/film.cube",
      freeze: true,
      speed: 2,
    });
    roundTrip(d0, d1);
    // Nothing changed is nothing kept; speed 1 and freeze off are the default.
    const d2 = setClipProps(d1, ["a"], {
      color: { exposure: 0, contrast: 0, saturation: 0, temperature: 0 },
      speed: 1,
      freeze: false,
      lut: null,
    });
    const a = get(d2, "a");
    expect([a.color, a.speed, a.freeze, a.lut]).toEqual([
      undefined,
      undefined,
      undefined,
      undefined,
    ]);
    expect(sourceUsed(get(d1, "a"))).toBe(1);
    expect(sourceUsed({ ...get(d0, "a"), speed: 2 })).toBe(200);
  });

  it("a speed goes to the linked clips too, and never reads past the file's end", () => {
    const d0 = three();
    // a's sound on A1, linked; c uses its file up to frame 200 of 250.
    d0.clips.push(clip("sa", "A1", 0, 100, 0, { link: "g1" }));
    get(d0, "a").link = "g1";
    get(d0, "c").ref = { media: "v/c.mp4", frames: 250 };
    const d1 = setClipProps(d0, ["a"], { speed: 2 });
    expect([get(d1, "a").speed, get(d1, "sa").speed]).toEqual([2, 2]);
    expect(get(d1, "a").sourceRange.duration).toBe(100);
    roundTrip(d0, d1);
    // 150 frames left in c's file: at 2× they last 75 frames of the timeline.
    const d2 = setClipProps(d0, ["c"], { speed: 2 });
    expect(get(d2, "c").sourceRange.duration).toBe(75);
    expect(sourceUsed(get(d2, "c"))).toBe(150);
    roundTrip(d0, d2);
    // Slower reads less: the length stays.
    expect(get(setClipProps(d0, ["c"], { speed: 0.5 }), "c").sourceRange.duration).toBe(100);
  });
});

describe("slip, slide, roll", () => {
  it("slip: same place and length, other frames of the file; never past its ends", () => {
    const d0 = three();
    const d1 = slipClip(d0, "b", 20);
    expect(get(d1, "b")).toMatchObject({ start: 100, sourceRange: { start: 70, duration: 100 } });
    roundTrip(d0, d1);
    expect(get(slipClip(d0, "b", -999), "b").sourceRange.start).toBe(0);
    // 500 frames in the file, 100 played: the start goes to 400 at most.
    expect(get(slipClip(d0, "b", 9999), "b").sourceRange.start).toBe(400);
  });

  it("slide: the clip moves between its neighbours, which give and take the frames", () => {
    const d0 = three();
    const d1 = slideClip(d0, "b", 30);
    expect(get(d1, "a").sourceRange).toEqual({ start: 0, duration: 130 });
    expect(get(d1, "b")).toMatchObject({ start: 130, sourceRange: { start: 50, duration: 100 } });
    expect(get(d1, "c")).toMatchObject({ start: 230, sourceRange: { start: 130, duration: 70 } });
    roundTrip(d0, d1);
    // Left: the one before keeps one frame, the one after cannot start before its file.
    const left = slideClip(d0, "b", -500);
    expect(get(left, "a").sourceRange.duration).toBe(1);
    expect(get(slideClip(d0, "b", 500), "c").sourceRange.duration).toBe(1);
    // Without both neighbours touching: nothing.
    expect(slideClip(d0, "a", 10)).toBe(d0);
  });

  it("roll: the cut moves, one clip longer as the other gets shorter", () => {
    const d0 = three();
    const d1 = rollEdit(d0, "a", -40);
    expect(get(d1, "a").sourceRange).toEqual({ start: 0, duration: 60 });
    expect(get(d1, "b")).toMatchObject({ start: 60, sourceRange: { start: 10, duration: 140 } });
    roundTrip(d0, d1);
    // The clip after cannot start before its file (it begins at 50).
    expect(get(rollEdit(d0, "a", -90), "b").start).toBe(50);
    expect(rollEdit(d0, "c", 10)).toBe(d0);
  });
});

describe("beats", () => {
  it("are in the snapping, and «Taglia a ritmo» rolls each cut to the nearest within reach", () => {
    const d0 = setBeats(three(), [96, 210, 260, 96], "mu");
    expect(d0.beats).toEqual([96, 210, 260]);
    expect(snapPoints(d0)).toEqual(expect.arrayContaining([96, 210, 260]));
    const d1 = cutsToBeats(d0, "V1", 8);
    expect(get(d1, "a").sourceRange.duration).toBe(96);
    // 200 → 210 is 10 frames away: beyond 8, the cut stays.
    expect(get(d1, "c").start).toBe(200);
    roundTrip(d0, d1);
    expect(get(cutsToBeats(d0, "V1", 12), "c").start).toBe(210);
    expect(setBeats(d0, null).beats).toBeUndefined();
  });
});

describe("a file's values", () => {
  it("are read within their limits; keys sorted inside the clip", () => {
    const raw = {
      ...three(),
      beats: [30, -4, "x", 30, 12],
      beatsOf: "mu",
      clips: [
        {
          ...clip("a", "V1", 0, 100, 0),
          box: { x: 2, y: 0.5, scale: 9 },
          boxKeys: [
            { at: 400, x: 0.1, y: 0.1, scale: 0.5 },
            { at: 5, x: 0.2, y: 0.2, scale: 0.5 },
            { at: 6, x: "no" },
          ],
          volumeKeys: [{ at: 3, db: 99 }],
          color: { exposure: 9, saturation: -4 },
          lut: "../../etc/passwd",
          freeze: "yes",
        },
      ],
    };
    const d = cleanTimeline(raw);
    const a = get(d, "a");
    expect(a.box).toEqual({ x: 1, y: 0.5, scale: 4 });
    expect(a.boxKeys).toEqual([
      { at: 5, x: 0.2, y: 0.2, scale: 0.5 },
      { at: 99, x: 0.1, y: 0.1, scale: 0.5 },
    ]);
    expect(a.volumeKeys).toEqual([{ at: 3, db: 12 }]);
    expect(a.color).toEqual({ exposure: 3, contrast: 0, saturation: -1, temperature: 0 });
    expect(a.lut).toBeUndefined();
    expect(a.freeze).toBeUndefined();
    expect(d.beats).toEqual([12, 30]);
    expect(d.beatsOf).toBe("mu");
  });
});
