// The timeline's pure edits (G41.2): montatore's 14 tests of `model.js` as the first rows, then
// every edit undone exactly through its actions, the cleaning of what a file holds, times,
// transitions, conflicts, formats and the file itself.
import { describe, expect, it } from "vitest";
import {
  addCaption,
  addedClips,
  addGenerator,
  addMarker,
  addTrack,
  addTransition,
  appendClip,
  applyVideoAction,
  bladeAt,
  captionsToSrt,
  captionsToVtt,
  captionWords,
  checkVideoAction,
  cleanTimeline,
  closeGap,
  composeVideoActions,
  copyClips,
  cutTimeRange,
  describeVideo,
  diffTimeline,
  editPoints,
  fitText,
  invertVideoAction,
  kenBurnsPreset,
  liftClips,
  linkClips,
  mapVideoAction,
  moveCaption,
  moveClips,
  NewerVideoFormat,
  newRgVideo,
  nextEdit,
  parseTime,
  pasteClips,
  placeClip,
  prevEdit,
  type RgVideo,
  readRgVideo,
  removeTrack,
  retimeTimeline,
  rgvideoVersionPath,
  rippleDeleteClips,
  setCaptionSegments,
  setClipProps,
  setFormat,
  setGenerator,
  setMarker,
  setTrack,
  setTransition,
  snap,
  snapPoints,
  stableJson,
  TITLE_SAFE,
  textWidth,
  timecode,
  timelineDuration,
  timelineProblems,
  trackClips,
  trimClip,
  unlinkClips,
  type VideoAction,
  type VideoClip,
  type VideoEdit,
  type VideoMediaRef,
  videoActionsConflict,
  writeRgVideo,
} from "../src/index.js";

// Files: A 1000 frames with sound, B 300 with sound, a picture, a silent B of 200.
const A: VideoMediaRef = { media: "a.mp4", frames: 1000, audio: true };
const B: VideoMediaRef = { media: "b.mp4", frames: 300, audio: true };
const FOTO: VideoMediaRef = { media: "foto.jpg", still: true };
const MUTA: VideoMediaRef = { media: "muta.mp4", frames: 200, audio: false };

const clip = (
  id: string,
  track: string,
  ref: VideoMediaRef,
  start: number,
  inF: number,
  dur: number,
  link?: string,
  fades = 0,
): VideoClip => ({
  id,
  track,
  start,
  sourceRange: { start: inF, duration: dur },
  ref,
  ...(link && { link }),
  enabled: true,
  volume: 0,
  fadeIn: fades,
  fadeOut: fades,
  fit: "fill",
});

/** V1/A1: A in two linked pieces (0–100 and 100–250); V2: a B at 40–90 (montatore's doc()). */
function doc(): RgVideo {
  const d = newRgVideo();
  return cleanTimeline({
    ...d,
    tracks: [
      { id: "V1", kind: "Video", name: "V1" },
      { id: "V2", kind: "Video", name: "V2" },
      { id: "A1", kind: "Audio", name: "A1" },
      { id: "A2", kind: "Audio", name: "A2" },
    ],
    clips: [
      clip("v1", "V1", A, 0, 0, 100, "g1"),
      clip("a1", "A1", A, 0, 0, 100, "g1"),
      clip("v2", "V1", A, 100, 300, 150, "g2"),
      clip("a2", "A1", A, 100, 300, 150, "g2"),
      clip("b", "V2", B, 40, 10, 50, undefined, 6),
    ],
  });
}

const get = (d: RgVideo, id: string) => d.clips.find((c) => c.id === id);
const on = (d: RgVideo, t: string) =>
  trackClips(d, t).map((c) => [c.start, c.sourceRange.start, c.sourceRange.duration]);
/** The clips a placement or a paste added (not the right parts of the clips it split). */
const added = (before: RgVideo, after: RgVideo) => {
  const split = (c: VideoClip) =>
    before.clips.some(
      (o) =>
        o.track === c.track &&
        stableJson(o.ref) === stableJson(c.ref) &&
        o.sourceRange.start - o.start === c.sourceRange.start - c.start,
    );
  return addedClips(before, after)
    .map((id) => get(after, id) as VideoClip)
    .filter((c) => !split(c));
};

describe("montatore's 14 cases", () => {
  it("1. the edits never change the document they get", () => {
    const d = doc();
    const before = JSON.stringify(d);
    moveClips(d, ["b"], 10);
    trimClip(d, "v1", "out", -10);
    bladeAt(d, 50);
    rippleDeleteClips(d, ["v1"]);
    placeClip(d, B, 0, 50, 0);
    addTrack(d, "Video");
    addMarker(d, 5);
    expect(JSON.stringify(d)).toBe(before);
  });

  it.each<[string, (d: RgVideo) => unknown, unknown]>([
    // 2. moving a linked clip moves its audio too, and overwrites where it lands
    [
      "move linked: V1",
      (d) => on(moveClips(d, ["v1"], 200), "V1"),
      [
        [100, 300, 100],
        [200, 0, 100],
      ],
    ],
    [
      "move linked: A1",
      (d) => on(moveClips(d, ["v1"], 200), "A1"),
      [
        [100, 300, 100],
        [200, 0, 100],
      ],
    ],
    [
      "move unlinked",
      (d) => on(moveClips(d, ["v1"], 300, 0, { linked: false }), "A1")[0],
      [0, 0, 100],
    ],
    ["never before zero", (d) => get(moveClips(d, ["b"], -500), "b")?.start, 0],
    // 3. to another track: only the grabbed kind changes track
    ["video up a track", (d) => get(moveClips(d, ["v1"], 0, 1), "v1")?.track, "V2"],
    ["its audio stays", (d) => get(moveClips(d, ["v1"], 0, 1), "a1")?.track, "A1"],
    ["overwrites the B there", (d) => get(moveClips(d, ["v1"], 0, 1), "b"), undefined],
    ["audio down a track", (d) => get(moveClips(d, ["a1"], 0, 1), "a1")?.track, "A2"],
    ["its video stays", (d) => get(moveClips(d, ["a1"], 0, 1), "v1")?.track, "V1"],
    // 5. trim without ripple: never over the neighbours nor out of the file
    [
      "out edge blocked by the next",
      (d) => get(trimClip(d, "v1", "out", 50), "v1")?.sourceRange.duration,
      100,
    ],
    [
      "shorter leaves a gap, audio too",
      (d) => {
        const x = trimClip(d, "v1", "out", -30);
        return [
          get(x, "v1")?.sourceRange.duration,
          get(x, "a1")?.sourceRange.duration,
          get(x, "v2")?.start,
        ];
      },
      [70, 70, 100],
    ],
    [
      "in edge back to the previous end",
      (d) => on(trimClip(trimClip(d, "v1", "out", -30), "v2", "in", -50), "V1")[1],
      [70, 270, 180],
    ],
    ["in edge not before the file", (d) => on(trimClip(d, "b", "in", -40), "V2"), [[30, 0, 60]]],
    [
      "out edge not past the file",
      (d) => get(trimClip(d, "b", "out", 9999), "b")?.sourceRange.duration,
      290,
    ],
    ["at least one frame", (d) => get(trimClip(d, "b", "out", -999), "b")?.sourceRange.duration, 1],
    // 6. ripple trim (T): what follows moves
    [
      "ripple out: V1",
      (d) => on(trimClip(d, "v1", "out", -30, { ripple: true }), "V1"),
      [
        [0, 0, 70],
        [70, 300, 150],
      ],
    ],
    [
      "ripple out: A1",
      (d) => on(trimClip(d, "v1", "out", -30, { ripple: true }), "A1"),
      [
        [0, 0, 70],
        [70, 300, 150],
      ],
    ],
    [
      "ripple out with a clip across the gap on another track: only its own tracks close",
      (d) => {
        const x = placeClip(d, MUTA, 0, 30, 100, { targets: { video: "V2" } });
        const y = trimClip(x, "v1", "out", -30, { ripple: true });
        return [on(y, "V1"), on(y, "V2")];
      },
      [
        [
          [0, 0, 70],
          [70, 300, 150],
        ],
        [
          [40, 10, 50],
          [100, 0, 30],
        ],
      ],
    ],
    [
      "ripple in: the clip stays",
      (d) => on(trimClip(d, "v2", "in", 20, { ripple: true }), "V1")[1],
      [100, 320, 130],
    ],
    [
      "ripple in: the B before stays",
      (d) => get(trimClip(d, "v2", "in", 20, { ripple: true }), "b")?.start,
      40,
    ],
    [
      "a picture has no limit",
      (d) => {
        const x = placeClip(d, FOTO, 0, 50, 500, { targets: { video: "V2" } });
        const id = addedClips(d, x)[0] as string;
        return get(trimClip(x, id, "out", 400), id)?.sourceRange.duration;
      },
      450,
    ],
    // 7. blade
    [
      "blade: V1",
      (d) => on(bladeAt(d, 60), "V1"),
      [
        [0, 0, 60],
        [60, 60, 40],
        [100, 300, 150],
      ],
    ],
    [
      "blade: V2",
      (d) => on(bladeAt(d, 60), "V2"),
      [
        [40, 10, 20],
        [60, 30, 30],
      ],
    ],
    [
      "blade: right halves linked to each other",
      (d) => {
        const x = bladeAt(d, 60);
        const v = trackClips(x, "V1")[1];
        const a = trackClips(x, "A1")[1];
        return [v?.link === a?.link, v?.link !== "g1"];
      },
      [true, true],
    ],
    [
      "blade only the chosen",
      (d) => [
        trackClips(bladeAt(d, 60, ["b"]), "V1").length,
        trackClips(bladeAt(d, 60, ["b"]), "V2").length,
      ],
      [2, 2],
    ],
    ["blade on an edge cuts nothing", (d) => bladeAt(d, 100, ["v1"]).clips.length, 5],
    // 8. Backspace leaves the gap, Delete closes it
    ["lift: V1", (d) => on(liftClips(d, ["v1"]), "V1"), [[100, 300, 150]]],
    ["lift: A1", (d) => on(liftClips(d, ["v1"]), "A1"), [[100, 300, 150]]],
    ["ripple delete: V1", (d) => on(rippleDeleteClips(d, ["v1"]), "V1"), [[0, 300, 150]]],
    ["ripple delete: A1", (d) => on(rippleDeleteClips(d, ["v1"]), "A1"), [[0, 300, 150]]],
    [
      "ripple delete: the B over it stays",
      (d) => on(rippleDeleteClips(d, ["v1"]), "V2"),
      [[40, 10, 50]],
    ],
    [
      "ripple delete over every track",
      (d) =>
        on(
          rippleDeleteClips(placeClip(d, MUTA, 0, 30, 300, { targets: { video: "V2" } }), ["v2"]),
          "V2",
        ).at(-1),
      [150, 0, 30],
    ],
    // 9. closing a clicked gap
    ["close gap", (d) => on(closeGap(liftClips(d, ["v1"]), "V1", 50), "V1"), [[0, 300, 150]]],
    [
      "inside a clip: nothing",
      (d) => {
        const x = liftClips(d, ["v1"]);
        return closeGap(x, "V1", 150) === x;
      },
      true,
    ],
    // 10. overwrite, insert, append from the media pool
    [
      "overwrite: V1",
      (d) => on(placeClip(d, B, 100, 130, 50), "V1"),
      [
        [0, 0, 50],
        [50, 100, 30],
        [80, 80, 20],
        [100, 300, 150],
      ],
    ],
    [
      "overwrite: linked",
      (d) => {
        const [v, a] = added(d, placeClip(d, B, 100, 130, 50));
        return !!v?.link && v.link === a?.link;
      },
      true,
    ],
    [
      "insert: V1",
      (d) => on(placeClip(d, B, 100, 130, 50, { mode: "insert" }), "V1"),
      [
        [0, 0, 50],
        [50, 100, 30],
        [80, 50, 50],
        [130, 300, 150],
      ],
    ],
    [
      "insert: V2 cut and moved",
      (d) => on(placeClip(d, B, 100, 130, 50, { mode: "insert" }), "V2"),
      [
        [40, 10, 10],
        [80, 20, 40],
      ],
    ],
    [
      "a silent B puts nothing on the audio",
      (d) =>
        added(d, placeClip(d, MUTA, 0, 20, 500, { targets: { video: "V2", audio: "A2" } })).length,
      1,
    ],
    [
      "a picture gets Ken Burns",
      (d) =>
        added(d, placeClip(d, FOTO, 0, 75, 500, { targets: { video: "V2", audio: "A2" } }))[0]
          ?.kenBurns,
      kenBurnsPreset("in", "right"),
    ],
    ["append after the last clip", (d) => on(appendClip(d, B, 0, 40), "V1").at(-1), [250, 0, 40]],
    // 11. copy and paste
    ["copy takes the linked", (d) => copyClips(d, ["v1"]).length, 2],
    ["paste", (d) => on(pasteClips(d, copyClips(d, ["v1"]), 300), "V1").at(-1), [300, 0, 100]],
    [
      "paste links the copies anew",
      (d) => {
        const [v, a] = added(d, pasteClips(d, copyClips(d, ["v1"]), 300));
        return [v?.link === a?.link, v?.link !== "g1"];
      },
      [true, true],
    ],
    // 12. link, unlink, properties
    [
      "unlink both",
      (d) => [get(unlinkClips(d, ["v1"]), "v1")?.link, get(unlinkClips(d, ["v1"]), "a1")?.link],
      [undefined, undefined],
    ],
    [
      "link again",
      (d) => {
        const x = linkClips(unlinkClips(d, ["v1"]), ["v1", "a1"]);
        return !!get(x, "v1")?.link && get(x, "v1")?.link === get(x, "a1")?.link;
      },
      true,
    ],
    [
      "properties, fades at most half",
      (d) => {
        const c = get(setClipProps(d, ["a1"], { volume: -6, fadeIn: 999, enabled: false }), "a1");
        return [c?.volume, c?.fadeIn, c?.enabled];
      },
      [-6, 50, false],
    ],
    // 13. tracks and markers
    [
      "add a track",
      (d) => addTrack(d, "Video").tracks.map((t) => t.id),
      ["V1", "V2", "V3", "A1", "A2"],
    ],
    [
      "not a full track",
      (d) => {
        const x = addTrack(d, "Video");
        return removeTrack(x, "V2") === x;
      },
      true,
    ],
    [
      "an empty track goes",
      (d) => removeTrack(addTrack(d, "Video"), "V3").tracks.map((t) => t.id),
      ["V1", "V2", "A1", "A2"],
    ],
    [
      "V1 always stays",
      (d) => {
        const x = addTrack(d, "Video");
        return removeTrack(x, "V1") === x;
      },
      true,
    ],
    [
      "markers in order",
      (d) =>
        addMarker(addMarker(d, 120, { color: "RED", note: "qui" }), 30).markers.map((m) => m.frame),
      [30, 120],
    ],
    [
      "one marker per frame",
      (d) => {
        const x = addMarker(d, 30);
        return addMarker(x, 30) === x;
      },
      true,
    ],
    [
      "a marker moved",
      (d) => {
        const x = addMarker(addMarker(d, 120), 30);
        return setMarker(x, x.markers[1]?.id as string, { frame: 10 }).markers.map((m) => m.frame);
      },
      [10, 30],
    ],
    // 14. edit points and snapping
    ["edit points", (d) => editPoints(d), [0, 40, 90, 100, 250]],
    ["next edit", (d) => nextEdit(d, 40), 90],
    ["previous edit", (d) => prevEdit(d, 95), 90],
    ["next edit at the end", (d) => nextEdit(d, 250), 250],
    ["snap to an edge", (d) => snap(97, snapPoints(d, new Set(["b"]), 123), 5), 100],
    ["snap to the playhead", (d) => snap(120, snapPoints(d, new Set(["b"]), 123), 5), 123],
    ["nothing near", (d) => snap(160, snapPoints(d, new Set(["b"]), 123), 5), 160],
    ["duration", (d) => timelineDuration(d), 250],
  ])("%s", (_name, f, want) => {
    expect(f(doc())).toEqual(want);
  });

  it("4. a locked track is never touched", () => {
    const locked = setTrack(doc(), "V2", { locked: true });
    expect(moveClips(locked, ["b"], 10)).toBe(locked);
    expect(moveClips(locked, ["v1"], 0, 1)).toBe(locked);
    expect(on(bladeAt(locked, 60), "V2")).toEqual([[40, 10, 50]]);
    expect(trimClip(locked, "b", "out", -5)).toBe(locked);
    expect(liftClips(locked, ["b"])).toBe(locked);
    expect(setClipProps(locked, ["b"], { volume: -3 })).toBe(locked);
  });
});

// ---- every edit through its actions, undone exactly -----------------------------------------

/** doc() with markers at 10, 50, 120 and three subtitles with words. */
function withTimed(d: RgVideo): RgVideo {
  let x = addMarker(d, 10);
  x = addMarker(x, 50);
  x = addMarker(x, 120);
  return setCaptionSegments(x, [
    {
      start: 0,
      end: 40,
      text: "uno due tre",
      words: [
        { start: 0, end: 10, text: "uno" },
        { start: 15, end: 25, text: "due" },
        { start: 30, end: 40, text: "tre" },
      ],
    },
    { start: 45, end: 55, text: "quattro" },
    { start: 130, end: 160, text: "cinque" },
  ]);
}

const EDITS: [VideoEdit, (d: RgVideo) => RgVideo][] = [
  ["move", (d) => moveClips(d, ["v1"], 200)],
  ["move", (d) => moveClips(d, ["v1"], 0, 1)],
  ["trim", (d) => trimClip(d, "b", "in", -5)],
  ["ripple_trim", (d) => trimClip(d, "v1", "out", -30, { ripple: true })],
  ["blade", (d) => bladeAt(d, 60)],
  ["lift", (d) => liftClips(d, ["v2"])],
  ["ripple_delete", (d) => rippleDeleteClips(d, ["v1"])],
  ["close_gap", (d) => closeGap(liftClips(d, ["v1"]), "V1", 10)],
  ["insert", (d) => placeClip(d, B, 100, 130, 50, { mode: "insert" })],
  ["overwrite", (d) => placeClip(d, B, 100, 130, 50)],
  ["append", (d) => appendClip(d, FOTO, 0, 90, { targets: { video: "V2" } })],
  ["paste", (d) => pasteClips(d, copyClips(d, ["v1"]), 300)],
  ["unlink", (d) => unlinkClips(d, ["v1"])],
  [
    "props",
    (d) =>
      setClipProps(d, ["b"], {
        kenBurns: kenBurnsPreset("out", "up"),
        fit: "fit",
        background: "blur",
        crop: { x: 0.3, y: 0, w: 0.4, h: 1 },
      }),
  ],
  ["add_track", (d) => addTrack(d, "Audio", "Musica")],
  ["remove_track", (d) => removeTrack(d, "A2")],
  [
    "track",
    (d) =>
      setTrack(d, "A2", { duck: { under: ["A1"], amountDb: -15, attackMs: 100, releaseMs: 400 } }),
  ],
  ["marker", (d) => addMarker(d, 12, { color: "GREEN", note: "inizio" })],
  ["transition", (d) => addTransition(d, "v1", "dissolve", 20)],
  [
    "text",
    (d) =>
      addGenerator(
        d,
        { generator: "text", text: "Titolo", style: "title", position: "center" },
        0,
        90,
      ),
  ],
  [
    "caption",
    (d) =>
      setCaptionSegments(d, [
        { start: 0, end: 30, text: "Ciao", words: [{ start: 0, end: 10, text: "Ciao" }] },
      ]),
  ],
  ["ripple_delete", (d) => cutTimeRange(withTimed(d), 20, 60)],
  ["caption", (d) => moveCaption(withTimed(d), "s1", 12)],
  ["format", (d) => setFormat(d, { aspect: "9:16" })],
  ["format", (d) => retimeTimeline(d, { num: 60, den: 1 })],
];

describe("every edit as actions, with its exact inverse", () => {
  it.each(EDITS.map(([w, f], i) => [`${i + 1}. ${w}`, w, f] as const))("%s", (_n, what, f) => {
    const before = doc();
    const after = f(before);
    expect(after).not.toBe(before);
    const action = diffTimeline(before, after, what) as VideoAction;
    expect(action).toBeDefined();
    expect(checkVideoAction(before, action)).toBeUndefined();
    const applied = applyVideoAction(before, action);
    expect(stableJson(applied)).toBe(stableJson(after));
    // Through the log (JSON) and back: the very same bytes.
    const inv = JSON.parse(JSON.stringify(invertVideoAction(before, action))) as VideoAction;
    expect(writeRgVideo(applyVideoAction(applied, inv))).toBe(writeRgVideo(before));
    // The file read again is the same timeline.
    expect(writeRgVideo(readRgVideo(writeRgVideo(applied)))).toBe(writeRgVideo(applied));
    expect(timelineProblems(applied)).toEqual([]);
    expect(describeVideo(before, [action]).change.action).toBe(what);
  });

  it("nothing to do: the same document, no action", () => {
    const d = doc();
    expect(moveClips(d, ["nope"], 10)).toBe(d);
    expect(diffTimeline(d, d)).toBeUndefined();
    expect(trimClip(d, "v1", "out", 50)).toBe(d);
  });

  it("describes in words, with timecodes", () => {
    const d = doc();
    const a = diffTimeline(d, placeClip(d, B, 0, 30, 300), "overwrite") as VideoAction;
    expect(describeVideo(d, [a]).text).toBe("placed 2 clips on V1 at 00:00:10:00");
    const m = diffTimeline(d, moveClips(d, ["b"], 30), "move") as VideoAction;
    expect(describeVideo(d, [a, m])).toMatchObject({
      text: "placed 2 clips on V1 at 00:00:10:00; moved 1 clip on V2 at 00:00:02:10",
      change: { action: "edit", added: 2 },
    });
    expect(describeVideo(d, [composeVideoActions([a, m])]).change.action).toBe("edit");
  });

  it("refuses an action that would make clips overlap, or names the wrong id", () => {
    const d = doc();
    const b = get(d, "b") as VideoClip;
    expect(checkVideoAction(d, { t: "clip", id: "x", value: { ...b, id: "x", start: 60 } })).toBe(
      "clips b and x overlap on V2",
    );
    expect(checkVideoAction(d, { t: "clip", id: "x", value: { ...b, id: "y" } })).toMatch(
      /given with id y/,
    );
    expect(checkVideoAction(d, { t: "clip", id: "nope", value: null })).toBe(
      "there is no clip «nope»",
    );
    expect(
      checkVideoAction(d, {
        t: "clip",
        id: "z",
        value: { ...b, id: "z", track: "A2", start: 500 },
      }),
    ).toBeUndefined();
    expect(
      checkVideoAction(d, {
        t: "clip",
        id: "z",
        value: { ...b, id: "z", track: "A2", start: 500, ref: FOTO },
      }),
    ).toBe("clip z is a picture on audio track A2");
    expect(checkVideoAction(d, { t: "meta", key: "format", value: { width: 1 } })).toMatch(
      /format is not valid/,
    );
  });
});

// ---- conflicts ----------------------------------------------------------------------------

describe("conflicts between two edits on the same revision", () => {
  const d = doc();
  const act = (f: (x: RgVideo) => RgVideo, what?: VideoEdit) =>
    diffTimeline(d, f(d), what) as VideoAction;
  /** Another author's ids (the page's own prefix): new clips never share an id. */
  const other = { ids: (p: string) => `p${p}1` };
  it.each<[string, () => [VideoAction, VideoAction], boolean]>([
    [
      "the same clip",
      () => [
        act((x) => moveClips(x, ["b"], 10)),
        act((x) => setClipProps(x, ["b"], { volume: -3 })),
      ],
      true,
    ],
    [
      "two clips far apart",
      () => [
        act((x) => moveClips(x, ["b"], 10)),
        act((x) => setClipProps(x, ["v2"], { volume: -3 })),
      ],
      false,
    ],
    [
      "clips landing on the same frames of one track",
      () => [
        act((x) => placeClip(x, MUTA, 0, 50, 400, { targets: { video: "V2" } })),
        act((x) => placeClip(x, FOTO, 0, 50, 420, { targets: { video: "V2" } })),
      ],
      true,
    ],
    [
      "the same frames on two tracks",
      () => [
        act((x) => placeClip(x, MUTA, 0, 50, 400, { targets: { video: "V2" } })),
        act((x) =>
          addGenerator(x, { generator: "color", color: "#000000" }, 400, 50, {
            track: "V1",
            ...other,
          }),
        ),
      ],
      false,
    ],
    [
      "two new clips with the same id",
      () => [
        act((x) => placeClip(x, MUTA, 0, 50, 400, { targets: { video: "V2" } })),
        act((x) =>
          addGenerator(x, { generator: "color", color: "#000000" }, 400, 50, { track: "V1" }),
        ),
      ],
      true,
    ],
    [
      "a track locked while a clip lands on it",
      () => [
        act((x) => setTrack(x, "V2", { locked: true })),
        act((x) => placeClip(x, MUTA, 0, 50, 400, { targets: { video: "V2" } })),
      ],
      true,
    ],
    [
      "a transition on a clip the other moves",
      () => [
        act((x) => addTransition(x, "v1", "dissolve", 10)),
        act((x) => trimClip(x, "v2", "out", -10, { linked: false })),
      ],
      true,
    ],
    [
      "a marker and a clip",
      () => [act((x) => addMarker(x, 10)), act((x) => moveClips(x, ["b"], 10))],
      false,
    ],
    [
      "the format and anything",
      () => [act((x) => setFormat(x, { aspect: "1:1" })), act((x) => addMarker(x, 10))],
      true,
    ],
  ])("%s → %s", (_n, make, want) => {
    const [a, b] = make();
    expect(videoActionsConflict(a, b)).toBe(want);
    expect(videoActionsConflict(b, a)).toBe(want);
    expect(mapVideoAction(a, b)).toBe(want ? undefined : a);
  });

  it("a mapped edit applies after the other's as it was meant", () => {
    const a = act((x) => moveClips(x, ["b"], 100));
    const b = act((x) => trimClip(x, "v2", "out", -50, { linked: false }));
    const both = applyVideoAction(applyVideoAction(d, b), mapVideoAction(a, b) as VideoAction);
    expect(get(both, "b")?.start).toBe(140);
    expect(get(both, "v2")?.sourceRange.duration).toBe(100);
  });
});

// ---- transitions, texts, captions, format -------------------------------------------------

describe("transitions, texts, captions and the format", () => {
  it("a transition sits on the cut, follows a blade, goes when the clips part", () => {
    const d = addTransition(doc(), "v1", "dissolve", 21);
    expect(d.transitions).toEqual([
      {
        id: "t1",
        track: "V1",
        from: "v1",
        to: "v2",
        kind: "dissolve",
        inOffset: 10,
        outOffset: 11,
      },
    ]);
    expect(addTransition(doc(), "v2", "dissolve", 10).transitions).toEqual([]); // nothing after v2
    const cut = bladeAt(d, 50, ["v1"]);
    const right = trackClips(cut, "V1")[1] as VideoClip;
    expect(cut.transitions[0]).toMatchObject({ from: right.id, to: "v2", inOffset: 10 });
    expect(moveClips(d, ["v2"], 5).transitions).toEqual([]);
    expect(
      setTransition(d, "t1", { kind: "wipe_left", outOffset: 999 }).transitions[0],
    ).toMatchObject({
      kind: "wipe_left",
      outOffset: 150,
    });
  });

  it("a title goes on a free video track on top, or a new one", () => {
    const text = { generator: "text", text: "Fine", style: "title", position: "center" } as const;
    const a = addGenerator(doc(), text, 40, 30);
    expect(a.tracks.map((t) => t.id)).toEqual(["V1", "V2", "V3", "A1", "A2"]);
    expect(on(a, "V3")).toEqual([[40, 0, 30]]);
    const b = addGenerator(doc(), text, 200, 30);
    expect(on(b, "V2").at(-1)).toEqual([200, 0, 30]);
    const id = addedClips(doc(), b)[0] as string;
    expect(get(setGenerator(b, id, { text: "The end", position: "bottom" }), id)?.ref).toEqual({
      generator: "text",
      text: "The end",
      style: "title",
      position: "bottom",
    });
  });

  it("subtitles: added, replaced, their words dropped when the text changes", () => {
    let d = addCaption(doc(), 0, 30, "Ciao");
    d = addCaption(d, 30, 60, "a tutti");
    expect(d.captions.segments.map((s) => [s.id, s.start, s.text])).toEqual([
      ["s1", 0, "Ciao"],
      ["s2", 30, "a tutti"],
    ]);
    expect(addCaption(d, 10, 5, "x")).toBe(d);
  });

  it.each<[Partial<RgVideo["format"]>, [number, number, string]]>([
    [{ aspect: "9:16" }, [1080, 1920, "9:16"]],
    [{ aspect: "1:1" }, [1080, 1080, "1:1"]],
    [{ aspect: "free", width: 1001 }, [1002, 1080, "free"]],
  ])("format %j", (props, [w, h, a]) => {
    const f = setFormat(doc(), props).format;
    expect([f.width, f.height, f.aspect]).toEqual([w, h, a]);
  });

  it("another rate retimes every frame", () => {
    const d = retimeTimeline(addMarker(doc(), 15), { num: 60, den: 1 });
    expect(on(d, "V1")).toEqual([
      [0, 0, 200],
      [200, 600, 300],
    ]);
    expect(get(d, "v1")?.ref).toMatchObject({ frames: 2000 });
    expect(d.markers[0]?.frame).toBe(30);
    expect(get(d, "b")?.fadeIn).toBe(12);
  });
});

// ---- times -------------------------------------------------------------------------------

describe("times", () => {
  const ntsc = { num: 30000, den: 1001 };
  const pal = { num: 25, den: 1 };
  it.each<[number, typeof pal, string]>([
    [0, pal, "00:00:00:00"],
    [24, pal, "00:00:00:24"],
    [25 * 3661 + 3, pal, "01:01:01:03"],
    [30, ntsc, "00:00:01:00"],
    [-50, pal, "-00:00:02:00"],
  ])("timecode(%s) = %s", (f, r, want) => {
    expect(timecode(f, r)).toBe(want);
  });

  it.each<[unknown, number | undefined]>([
    [120, 120],
    ["120f", 120],
    ["4s", 100],
    ["4.5s", 113],
    ["4,5", 113],
    ["-2s", -50],
    ["00:00:04:10", 110],
    ["04:10", 110],
    ["01:00:00:00", 90000],
    ["00:00:00:25", undefined],
    ["00:61:00:00", undefined],
    ["ieri", undefined],
    [null, undefined],
  ])("parseTime(%j)", (v, want) => {
    expect(parseTime(v, pal)).toBe(want);
  });
});

// ---- cleaning -----------------------------------------------------------------------------

describe("cleanTimeline: a valid timeline from anything, never an exception", () => {
  const base = (clips: unknown[], extra: Record<string, unknown> = {}) =>
    cleanTimeline({
      formatVersion: 1,
      tracks: [{ id: "V1" }, { id: "V2" }, { id: "A1" }],
      clips,
      ...extra,
    });
  const c = (o: Record<string, unknown>) => ({
    id: "x",
    track: "V1",
    start: 0,
    sourceRange: { start: 0, duration: 50 },
    ref: A,
    ...o,
  });

  it.each<[string, () => unknown, unknown]>([
    [
      "garbage gives an empty timeline",
      () => [null, [], "x", 5, { clips: 5 }].map((r) => writeRgVideo(cleanTimeline(r))),
      Array(5).fill(writeRgVideo(newRgVideo())),
    ],
    [
      "V1 and A1 always there",
      () => cleanTimeline({ tracks: [{ id: "A3" }, { id: "Z1" }] }).tracks.map((t) => t.id),
      ["V1", "A1", "A3"],
    ],
    [
      "the kind comes from the id",
      () => cleanTimeline({ tracks: [{ id: "V2", kind: "Audio" }] }).tracks[1],
      { id: "V2", kind: "Video", name: "V2", locked: false, hidden: false },
    ],
    [
      "overlaps cut at the later clip's head",
      () =>
        base([
          c({ id: "p", start: 0 }),
          c({ id: "q", start: 30, sourceRange: { start: 100, duration: 50 } }),
        ]).clips.map((x) => [x.id, x.start, x.sourceRange.start, x.sourceRange.duration]),
      [
        ["p", 0, 0, 50],
        ["q", 50, 120, 30],
      ],
    ],
    [
      "a clip swallowed goes",
      () =>
        base([
          c({ id: "p" }),
          c({ id: "q", start: 10, sourceRange: { start: 0, duration: 20 } }),
        ]).clips.map((x) => x.id),
      ["p"],
    ],
    [
      "inside its file",
      () => base([c({ sourceRange: { start: 990, duration: 50 } })]).clips[0]?.sourceRange,
      { start: 990, duration: 10 },
    ],
    [
      "a picture without limit",
      () =>
        base([c({ ref: FOTO, sourceRange: { start: 7, duration: 5000 } })]).clips[0]?.sourceRange,
      { start: 0, duration: 5000 },
    ],
    ["no picture on an audio track", () => base([c({ track: "A1", ref: FOTO })]).clips, []],
    ["no silent file on an audio track", () => base([c({ track: "A1", ref: MUTA })]).clips, []],
    [
      "no text on an audio track",
      () => base([c({ track: "A1", ref: { generator: "text", text: "x" } })]).clips,
      [],
    ],
    ["unknown track: left out", () => base([c({ track: "V9" })]).clips, []],
    ["a link of one clip goes", () => base([c({ link: "g1" })]).clips[0]?.link, undefined],
    [
      "fades at most half, volume within",
      () => {
        const x = base([c({ fadeIn: 99, volume: 40 })]).clips[0];
        return [x?.fadeIn, x?.volume];
      },
      [25, 12],
    ],
    [
      "duplicate ids: the first",
      () => base([c({}), c({ start: 200 })]).clips.map((x) => x.start),
      [0],
    ],
    [
      "transitions only between adjacent clips",
      () =>
        base([c({ id: "p" }), c({ id: "q", start: 50 }), c({ id: "r", start: 200 })], {
          transitions: [
            {
              id: "t1",
              track: "V1",
              from: "p",
              to: "q",
              kind: "dissolve",
              inOffset: 5,
              outOffset: 500,
            },
            {
              id: "t2",
              track: "V1",
              from: "q",
              to: "r",
              kind: "dissolve",
              inOffset: 5,
              outOffset: 5,
            },
            { id: "t3", track: "V1", from: "p", to: "q", kind: "bogus", inOffset: 1, outOffset: 1 },
          ],
        }).transitions,
      [{ id: "t1", track: "V1", from: "p", to: "q", kind: "dissolve", inOffset: 5, outOffset: 50 }],
    ],
    [
      "marker colours as OTIO's",
      () =>
        cleanTimeline({
          markers: [
            { id: "m1", frame: 5, color: "red" },
            { id: "m2", frame: 1, color: "fuchsia" },
          ],
        }).markers.map((m) => [m.id, m.color]),
      [
        ["m2", "BLUE"],
        ["m1", "RED"],
      ],
    ],
    [
      "subtitles that end before they start go",
      () =>
        cleanTimeline({
          captions: {
            segments: [
              { id: "s1", start: 10, end: 5, text: "x" },
              { id: "s2", start: 0, end: 5, text: "ok" },
            ],
          },
        }).captions.segments.map((s) => s.id),
      ["s2"],
    ],
    [
      "probes correct the files",
      () =>
        cleanTimeline(
          { clips: [c({ sourceRange: { start: 0, duration: 999 } })] },
          { "a.mp4": { frames: 100, audio: false } },
        ).clips[0]?.ref,
      { media: "a.mp4", frames: 100, audio: false },
    ],
    [
      "a rate as a number",
      () => cleanTimeline({ format: { width: 1920, height: 1080, rate: 29.97 } }).format.rate,
      { num: 30000, den: 1001 },
    ],
  ])("%s", (_n, f, want) => {
    expect(f()).toEqual(want);
  });

  it("a clean timeline has no problems, and cleaning it again changes nothing", () => {
    const d = doc();
    expect(timelineProblems(d)).toEqual([]);
    expect(writeRgVideo(cleanTimeline(JSON.parse(writeRgVideo(d))))).toBe(writeRgVideo(d));
  });
});

// ---- the file -----------------------------------------------------------------------------

describe("the .rgvideo file, old and new", () => {
  it("empty is a new timeline; not JSON, a newer format or a bad version are refused", () => {
    expect(readRgVideo("")).toEqual(newRgVideo());
    expect(() => readRgVideo("<xml/>")).toThrow(/not JSON/);
    expect(() => readRgVideo("[1]")).toThrow(/not an object/);
    expect(() => readRgVideo('{"formatVersion":2}')).toThrow(NewerVideoFormat);
    expect(() => readRgVideo('{"formatVersion":2}')).toThrow(/newer RedGiant \(format 2/);
    expect(() => readRgVideo('{"formatVersion":"1"}')).toThrow(/not one RedGiant knows/);
  });

  it("reads montatore's timeline (no formatVersion) as the first version", () => {
    const montatore = {
      tracks: [
        { id: "V1", type: "video", name: "V1", locked: false, hidden: false },
        { id: "V2", type: "video", name: "V2", locked: true, hidden: false },
        { id: "A1", type: "audio", name: "A1", locked: false, muted: true },
      ],
      clips: [
        {
          id: "c1",
          track: "V1",
          media: 1,
          start: 0,
          in: 10,
          dur: 100,
          link: "g1",
          enabled: true,
          fadeIn: 0,
          fadeOut: 0,
        },
        {
          id: "c2",
          track: "A1",
          media: 1,
          start: 0,
          in: 10,
          dur: 100,
          link: "g1",
          enabled: true,
          volume: -3,
          fadeIn: 0,
          fadeOut: 0,
        },
        {
          id: "c3",
          track: "V2",
          media: 3,
          start: 20,
          in: 0,
          dur: 75,
          link: null,
          enabled: true,
          fadeIn: 6,
          fadeOut: 6,
          motion: { zoom: "out", pan: "left" },
        },
      ],
      markers: [{ id: "m1", frame: 30, color: "red", note: "qui" }],
      next: 7,
      generatedAt: "2026-10-31T10:00:00Z",
    };
    const d = readRgVideo(JSON.stringify(montatore));
    expect(d.tracks.map((t) => [t.id, t.kind, t.locked])).toEqual([
      ["V1", "Video", false],
      ["V2", "Video", true],
      ["A1", "Audio", false],
    ]);
    expect(d.tracks[2]?.muted).toBe(true);
    expect(d.clips.map((c) => [c.id, c.ref, c.sourceRange, c.link ?? null])).toEqual([
      ["c1", { media: "1" }, { start: 10, duration: 100 }, "g1"],
      ["c3", { media: "3", still: true }, { start: 0, duration: 75 }, null],
      ["c2", { media: "1" }, { start: 10, duration: 100 }, "g1"],
    ]);
    expect(d.clips[1]?.kenBurns).toEqual(kenBurnsPreset("out", "left"));
    expect(d.clips[2]?.volume).toBe(-3);
    expect(d.markers).toEqual([{ id: "m1", frame: 30, color: "RED", note: "qui" }]);
    expect(d.assembled).toEqual({ at: "2026-10-31T10:00:00Z" });
    expect(d.formatVersion).toBe(1);
  });

  it("a named version lives beside the timeline (A5)", () => {
    expect(rgvideoVersionPath("video/gita.rgvideo", "Prima del montaggio", "2026-11-16 1530")).toBe(
      "video/gita.versions/2026-11-16 1530 Prima del montaggio.rgvideo",
    );
    expect(rgvideoVersionPath("gita.rgvideo", 'a/b:"c"', "x")).toBe(
      "gita.versions/x a b c .rgvideo".replace(" .", "."),
    );
    const v = cleanTimeline({
      version: {
        name: "Bozza",
        at: "2026-11-16T15:30:00Z",
        of: "video/gita.rgvideo",
        reason: "before_assemble",
      },
    });
    expect(v.version).toEqual({
      name: "Bozza",
      at: "2026-11-16T15:30:00Z",
      of: "video/gita.rgvideo",
      reason: "before_assemble",
    });
  });
});

// ---- G41.5c: markers and subtitles follow the ripples; the speech cut from its text --------

describe("markers and subtitles follow the ripples", () => {
  const timed = (d: RgVideo) => ({
    markers: d.markers.map((m) => m.frame),
    caps: d.captions.segments.map((c) => [c.start, c.end, c.text]),
  });
  it.each<[string, (d: RgVideo) => RgVideo, ReturnType<typeof timed>]>([
    [
      "ripple delete of the first clip (every track closes)",
      (d) => rippleDeleteClips(liftClips(d, ["b"]), ["v1"]),
      { markers: [0, 20], caps: [[30, 60, "cinque"]] },
    ],
    [
      "a ripple trim closing 30 frames at 100",
      (d) => trimClip(d, "v1", "out", -30, { ripple: true }),
      {
        markers: [10, 50, 90],
        caps: [
          [0, 40, "uno due tre"],
          [45, 55, "quattro"],
          [100, 130, "cinque"],
        ],
      },
    ],
    [
      "a ripple trim opening 20 frames at 100",
      (d) => trimClip(trimClip(d, "v1", "out", -40), "v1", "out", 20, { ripple: true }),
      {
        markers: [10, 50, 140],
        caps: [
          [0, 40, "uno due tre"],
          [45, 55, "quattro"],
          [150, 180, "cinque"],
        ],
      },
    ],
    [
      "an insert (F9) at 45 opens 30 frames",
      (d) => placeClip(d, B, 0, 30, 45, { mode: "insert" }),
      {
        markers: [10, 80, 150],
        caps: [
          [0, 40, "uno due tre"],
          [75, 85, "quattro"],
          [160, 190, "cinque"],
        ],
      },
    ],
    [
      "a gap closed on a side track alone: they stay",
      (d) => closeGap(liftClips(d, ["a1"], { linked: false }), "A2", 10),
      {
        markers: [10, 50, 120],
        caps: [
          [0, 40, "uno due tre"],
          [45, 55, "quattro"],
          [130, 160, "cinque"],
        ],
      },
    ],
  ])("%s", (_n, f, want) => {
    expect(timed(f(withTimed(doc())))).toEqual(want);
  });

  it("a ripple delete on V2 alone, with V1 under it, leaves them where they are", () => {
    const d = rippleDeleteClips(withTimed(doc()), ["b"]);
    expect(timed(d).markers).toEqual([10, 50, 120]);
  });
});

describe("cutTimeRange: the speech cut from its text", () => {
  it("cuts every unlocked track, closes up, the subtitles lose the words that went", () => {
    const d = cutTimeRange(withTimed(doc()), 12, 28);
    expect(on(d, "V1")).toEqual([
      [0, 0, 12],
      [12, 28, 72],
      [84, 300, 150],
    ]);
    expect(on(d, "A1")).toEqual(on(d, "V1"));
    expect(on(d, "V2")).toEqual([[24, 10, 50]]);
    const first = d.captions.segments[0];
    expect([first?.start, first?.end, first?.text]).toEqual([0, 24, "uno tre"]);
    expect(first?.words).toEqual([
      { start: 0, end: 10, text: "uno" },
      { start: 14, end: 24, text: "tre" },
    ]);
    expect(d.markers.map((m) => m.frame)).toEqual([10, 34, 104]);
  });

  it("a line typed by hand loses the words cut, spread by their length", () => {
    const d = cutTimeRange(addCaption(doc(), 200, 240, "alfa beta"), 200, 220);
    expect(d.captions.segments.map((c) => [c.start, c.end, c.text, c.words])).toEqual([
      [200, 220, "beta", undefined],
    ]);
  });

  it("a locked track stays; nothing to cut gives the same timeline", () => {
    const d0 = setTrack(withTimed(doc()), "V2", { locked: true });
    const d = cutTimeRange(d0, 100, 120);
    expect(on(d, "V2")).toEqual([[40, 10, 50]]);
    expect(on(d, "V1")).toEqual([
      [0, 0, 100],
      [100, 320, 130],
    ]);
    expect(cutTimeRange(d0, 30, 30)).toBe(d0);
    const empty = newRgVideo();
    expect(cutTimeRange(empty, 0, 10)).toBe(empty);
  });
});

describe("texts measured once, for the page and the render", () => {
  it.each<
    [string, "title" | "lower_third", "center" | "top" | "bottom" | "lower_third", number, number]
  >([
    ["Il giro di Red Giant", "title", "center", 1280, 720],
    ["Marta Rossi, regista del documentario sulla costa", "lower_third", "lower_third", 1280, 720],
    ["Un titolo molto lungo che deve andare a capo in verticale", "title", "top", 1080, 1920],
    ["In fondo", "title", "bottom", 1080, 1080],
  ])("%s (%s, %s, %dx%d) stays in the safe area", (text, style, pos, w, h) => {
    const f = fitText(text, style, pos, w, h);
    const bold = style !== "plain";
    expect(Math.max(...f.lines.map((l) => textWidth(l, f.size, bold)))).toBeLessThanOrEqual(
      w - 2 * Math.ceil(w * TITLE_SAFE),
    );
    expect(f.lines.join(" ")).toBe(text);
    if (pos === "center")
      expect([f.top, f.bottom, f.left]).toEqual([undefined, undefined, undefined]);
    if (pos === "top") expect(f.top).toBe(Math.max(Math.round(h * 0.08), f.my + f.border));
    if (pos === "bottom") expect(f.bottom).toBe(Math.round(h * 0.08) + f.border);
    if (pos === "lower_third") {
      expect(f.left).toBe(f.mx + f.border);
      expect(f.top).toBeLessThanOrEqual(Math.round(h * 0.7));
    }
  });

  it("a subtitle moves with its words, never before 0", () => {
    const d = withTimed(doc());
    const id = d.captions.segments[0]?.id as string;
    const m = moveCaption(d, id, -50).captions.segments.find((x) => x.id === id);
    expect([m?.start, m?.end, m?.words?.[1]]).toEqual([0, 40, { start: 15, end: 25, text: "due" }]);
    const r = moveCaption(d, id, 5).captions.segments.find((x) => x.id === id);
    expect([r?.start, r?.words?.[2]?.start]).toEqual([5, 35]);
  });

  it("a subtitle's words: its own, or spread over its time by their length", () => {
    const own = { start: 0, end: 10, text: "a b", words: [{ start: 2, end: 4, text: "a" }] };
    expect(captionWords(own)).toEqual(own.words);
    expect(captionWords({ start: 100, end: 120, text: "uno  due" })).toEqual([
      { start: 100, end: 110, text: "uno" },
      { start: 110, end: 120, text: "due" },
    ]);
  });

  it("SRT and WebVTT in protocol (the page writes them too)", () => {
    const list = [{ start: 25, end: 50, text: "a <b>" }];
    expect(captionsToSrt(list, { num: 25, den: 1 })).toBe(
      "1\n00:00:01,000 --> 00:00:02,000\na <b>\n",
    );
    expect(captionsToVtt(list, { num: 25, den: 1 })).toBe(
      "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\na &lt;b&gt;\n",
    );
  });
});
