// The render compiler (G41.3), pure: a timeline → segments, graphs as text, the sound's graph,
// captions and hashes. Each effect alone and together, a transition split by an edge on another
// track, J/L cuts at their limits, a vertical picture in 16:9, muted tracks and clips that are
// off, stable hashes. The real render (ffmpeg 9) is in video.docker.test.ts.
import {
  newRgVideo,
  type RgVideo,
  type VideoClip,
  type VideoRef,
  type VideoTrack,
  type VideoTransition,
} from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { captionsToSrt, captionsToVtt } from "../src/editor/video/captions.js";
import {
  compileVideo,
  EmptyTimeline,
  encoderArgs,
  filterPath,
  filterValue,
  fitText,
  joinArgs,
  loudnormApplyArgs,
  outputSize,
  parseLoudnorm,
  type RenderProbe,
  type RenderTarget,
  stepArgs,
  TITLE_SAFE,
  textWidth,
} from "../src/editor/video/compile.js";
import { parseProbe, renderProbeOf } from "../src/editor/video/probe.js";
import { captionsAss, subtitleLanguage } from "../src/editor/video/render-subtitles.js";

const R = { num: 25, den: 1 };
const TARGET: RenderTarget = { encoder: "libx264", fontsDir: "/srv/fonts", quality: "draft" };
const PROBES: Record<string, RenderProbe> = {
  "a.mp4": { frames: 1000, audio: true, fingerprint: "a1" },
  "b.mp4": { frames: 400, audio: true, fingerprint: "b1" },
  "photo.jpg": { frames: null, audio: false, fingerprint: "p1" },
  "music.m4a": { frames: 2000, audio: true, fingerprint: "m1" },
};

function clip(
  id: string,
  track: string,
  start: number,
  dur: number,
  ref: VideoRef,
  more: Partial<VideoClip> = {},
  src = 0,
): VideoClip {
  return {
    id,
    track,
    start,
    sourceRange: { start: src, duration: dur },
    ref,
    enabled: true,
    volume: 0,
    fadeIn: 0,
    fadeOut: 0,
    fit: "fill",
    ...more,
  };
}

const A = { media: "a.mp4" };
const B = { media: "b.mp4" };
const PHOTO = { media: "photo.jpg", still: true };
const MUSIC = { media: "music.m4a" };

function doc(
  clips: VideoClip[],
  more: { tracks?: VideoTrack[]; transitions?: VideoTransition[] } = {},
): RgVideo {
  const d = newRgVideo({ width: 640, height: 360, rate: R, aspect: "16:9" });
  d.tracks = more.tracks ?? [
    { id: "V1", kind: "Video", name: "V1", locked: false },
    { id: "V2", kind: "Video", name: "V2", locked: false },
    { id: "A1", kind: "Audio", name: "A1", locked: false },
    { id: "A2", kind: "Audio", name: "A2", locked: false },
  ];
  d.clips = clips;
  d.transitions = more.transitions ?? [];
  return d;
}

const spans = (d: RgVideo, probes = PROBES, t = TARGET) =>
  compileVideo(d, probes, t).segments.map((s) => [s.start, s.frames]);
const seg = (d: RgVideo, start: number, probes = PROBES, t = TARGET) => {
  const s = compileVideo(d, probes, t).segments.find((x) => x.start === start);
  if (!s) throw new Error(`no segment at ${start}`);
  return s;
};

/** montatore's case: V1 two pieces of A with a gap, V2 a B and a photo, A2 a clip. */
const montatore = () =>
  doc([
    clip("v1", "V1", 0, 38, A),
    clip("v2", "V1", 40, 23, A, { fadeIn: 5 }, 50),
    clip("b1", "V2", 12, 20, B, { fadeIn: 3, fadeOut: 3 }, 5),
    clip("p1", "V2", 32, 28, PHOTO, { kenBurns: { from: full, to: near } }),
    clip("x1", "A2", 10, 10, A, { volume: -6, fadeIn: 5, fadeOut: 5 }),
  ]);
const full = { x: 0, y: 0, w: 1, h: 1 };
const near = { x: 0.2, y: 0.1, w: 0.8, h: 0.8 };

describe("segments", () => {
  it("cuts at every clip edge, as montatore (63 frames, six segments)", () => {
    const plan = compileVideo(montatore(), PROBES, TARGET);
    expect(plan.frames).toBe(63);
    expect(plan.seconds).toBeCloseTo(2.52);
    expect(spans(montatore())).toEqual([
      [0, 12],
      [12, 20],
      [32, 6],
      [38, 2],
      [40, 20],
      [60, 3],
    ]);
  });

  it("a video that covers the frame without fading is the base; otherwise black is", () => {
    const s12 = seg(montatore(), 12);
    expect(s12.inputs).toHaveLength(2);
    expect(s12.script).not.toContain("color=c=black:s=640x360");
    expect(s12.script).toContain("[0:v]fps=25/1,trim=end_frame=20");
    expect(s12.script).toMatch(/\[v\d+\]\[v\d+\]overlay=eof_action=pass/);
    // the B starts at its frame 5: 0.2 s into b.mp4
    expect(s12.inputs[1]).toEqual({
      before: ["-ss", "0.200000", "-t", "1.0500", "-an"],
      media: "b.mp4",
    });
    // in the gap of V1 only the photo: never a base (S53), over black
    const s38 = seg(montatore(), 38);
    expect(s38.inputs).toHaveLength(1);
    expect(s38.script).toContain("color=c=black:s=640x360:r=25/1");
    // the second piece of A fades in: over black
    const s40 = seg(montatore(), 40);
    expect(s40.script).toContain("color=c=black");
    expect(s40.script).toContain("fade=t=in:st=0:d=0.200000:alpha=1");
  });

  it("fades and Ken Burns go on in the clip's own time across segments", () => {
    const d = montatore();
    (d.clips[3] as VideoClip).fadeOut = 10;
    const s40 = seg(d, 40);
    // the photo is 8 frames in at 40: its time starts at 0.32 s
    expect(s40.script).toContain(
      "setpts=PTS+0.320000/TB,fade=t=out:st=0.720000:d=0.400000:alpha=1,setpts=PTS-0.320000/TB",
    );
    expect(seg(d, 32).script).toContain("((on+0)/27)");
    expect(s40.script).toContain("((on+8)/27)");
    expect(s40.script).toContain(":d=20:s=640x360:fps=25/1");
  });

  it("a timeline with nothing that plays is refused", () => {
    expect(() => compileVideo(doc([]), PROBES, TARGET)).toThrow(EmptyTimeline);
    expect(() =>
      compileVideo(doc([clip("v1", "V1", 0, 10, A, { enabled: false })]), PROBES, TARGET),
    ).toThrow(EmptyTimeline);
  });

  it("hidden tracks, muted tracks and clips that are off play nothing", () => {
    const d = doc([
      clip("v1", "V1", 0, 50, A),
      clip("v2", "V2", 10, 20, B),
      clip("off", "V1", 50, 30, A, { enabled: false }),
      clip("a1", "A1", 0, 50, A),
      clip("a2", "A2", 0, 120, MUSIC),
    ]);
    (d.tracks[1] as VideoTrack).hidden = true;
    (d.tracks[3] as VideoTrack).muted = true;
    const plan = compileVideo(d, PROBES, TARGET);
    expect(plan.frames).toBe(50);
    expect(plan.segments.map((s) => [s.start, s.frames])).toEqual([[0, 50]]);
    expect(plan.segments[0]?.inputs.map((i) => i.media)).toEqual(["a.mp4"]);
    expect(plan.audio.inputs.map((i) => i.media)).toEqual(["a.mp4"]);
  });
});

describe("pictures", () => {
  it.each([
    [
      "fill crops at the centre",
      {},
      "scale=640:360:force_original_aspect_ratio=increase:flags=lanczos:out_range=tv,crop=640:360,setsar=1",
    ],
    [
      "fit on black",
      { fit: "fit", background: "black" },
      "force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos:out_range=tv,setsar=1,pad=640:360:(ow-iw)/2:(oh-ih)/2:color=black",
    ],
    [
      "fit on nothing (what is below shows)",
      { fit: "fit" },
      "pad=640:360:(ow-iw)/2:(oh-ih)/2:color=black@0",
    ],
    ["fit on a blurred copy (A1)", { fit: "fit", background: "blur" }, "boxblur=8:2,scale=640:360"],
    [
      "a crop (A1, reframed)",
      { crop: { x: 0.35, y: 0, w: 0.316, h: 1 } },
      "crop=w=iw*0.3160:h=ih*1.0000:x=iw*0.3500:y=ih*0.0000,scale=640:360",
    ],
  ] as const)("a vertical photo in 16:9: %s", (_, more, expected) => {
    const s = seg(doc([clip("p", "V1", 0, 50, PHOTO, more as Partial<VideoClip>)]), 0);
    expect(s.script).toContain(expected);
    expect(s.script).toContain("loop=loop=-1:size=1,setpts=N*1/25/TB");
    expect(s.script).toContain("color=c=black:s=640x360");
  });

  it("a fitted video on black or blur covers the frame and is the base; on nothing it is not", () => {
    const base = (more: Partial<VideoClip>) =>
      !seg(doc([clip("v", "V1", 0, 50, B, more)]), 0).script.includes("color=c=black:s=640x360:r");
    expect(base({})).toBe(true);
    expect(base({ fit: "fit", background: "blur" })).toBe(true);
    expect(base({ fit: "fit", background: "black" })).toBe(true);
    expect(base({ fit: "fit" })).toBe(false);
    expect(base({ kenBurns: { from: full, to: near } })).toBe(true);
  });

  it("Ken Burns on a picture: prepared at twice the size, rectangles from and to", () => {
    const s = seg(doc([clip("p", "V1", 0, 100, PHOTO, { kenBurns: { from: full, to: near } })]), 0);
    expect(s.script).toContain("scale=1280:720:force_original_aspect_ratio=increase");
    expect(s.script).toContain(
      "zoompan=z='1/(1.0000+(-0.2000)*((on+0)/99))':x='iw*(0.0000+(0.2000)*((on+0)/99))':y='ih*(0.0000+(0.1000)*((on+0)/99))':d=100:s=640x360:fps=25/1",
    );
    // held on its last frame: never one short after zoompan (S53)
    expect(s.script).toContain("tpad=stop=-1:stop_mode=clone");
  });

  it("Ken Burns on a video: one frame out for each frame in", () => {
    const s = seg(doc([clip("v", "V1", 0, 40, A, { kenBurns: { from: near, to: full } })]), 0);
    expect(s.script).toContain(":d=1:s=640x360:fps=25/1");
    expect(s.script).not.toContain("1280:720");
  });

  it("the output is never enlarged; a smaller height keeps the shape", () => {
    const d = newRgVideo({ width: 1920, height: 1080, rate: R, aspect: "16:9" });
    expect(outputSize(d)).toEqual({ width: 1920, height: 1080 });
    expect(outputSize(d, 2160)).toEqual({ width: 1920, height: 1080 });
    expect(outputSize(d, 720)).toEqual({ width: 1280, height: 720 });
    expect(outputSize(d, 361)).toEqual({ width: 644, height: 362 });
    const v = newRgVideo({ width: 1080, height: 1920, rate: R, aspect: "9:16" });
    expect(outputSize(v, 1280)).toEqual({ width: 720, height: 1280 });
  });
});

describe("transitions", () => {
  const cut = (kind: VideoTransition["kind"], inOffset = 10, outOffset = 10) =>
    doc([clip("c1", "V1", 0, 50, A, {}, 100), clip("c2", "V1", 50, 50, B, {}, 100)], {
      transitions: [{ id: "t1", track: "V1", from: "c1", to: "c2", kind, inOffset, outOffset }],
    });

  it("a dissolve: its window is a segment with both clips, the files' handles used", () => {
    const plan = compileVideo(cut("dissolve"), PROBES, TARGET);
    expect(plan.segments.map((s) => [s.start, s.frames])).toEqual([
      [0, 40],
      [40, 20],
      [60, 40],
    ]);
    const w = plan.segments[1];
    // c1 goes on 10 frames past its out point (frames 140..159 of a.mp4), c2 starts 10 before
    expect(w?.inputs).toEqual([
      { before: ["-ss", "5.600000", "-t", "1.0500", "-an"], media: "a.mp4" },
      { before: ["-ss", "3.600000", "-t", "1.0500", "-an"], media: "b.mp4" },
    ]);
    expect(w?.script).toContain(
      "setpts=PTS+0.000000/TB,fade=t=in:st=0:d=0.800000:alpha=1,setpts=PTS-0.000000/TB",
    );
    expect(w?.script).not.toContain("tpad=start=");
    expect(plan.warnings).toEqual([]);
    // the clips keep their length: the total does not change
    expect(plan.frames).toBe(100);
  });

  it("without handles in the file the edge frames are held, and it says so", () => {
    const d = cut("dissolve");
    (d.clips[1] as VideoClip).sourceRange.start = 4;
    const probes = { ...PROBES, "a.mp4": { frames: 152, audio: true } };
    const plan = compileVideo(d, probes, TARGET);
    const w = plan.segments[1]?.script ?? "";
    expect(w).toContain("tpad=start=6:start_mode=clone");
    expect(w).toContain("[0:v]fps=25/1,trim=end_frame=12");
    expect(plan.warnings).toEqual([
      "c1 holds its last frame for 8 frames: the file has none after it",
      "c2 holds its first frame for 6 frames: the file has none before it",
    ]);
    // a file of unknown length: no frame is read past the clip
    const unknown = compileVideo(d, { "b.mp4": PROBES["b.mp4"] as RenderProbe }, TARGET);
    expect(unknown.warnings[0]).toBe(
      "c1 holds its last frame for 10 frames: the file's length is not known (ffprobe)",
    );
  });

  it("an edge on another track inside the window: the progress goes on in the next segment", () => {
    const d = cut("wipe_left");
    d.clips.push(
      clip("t", "V2", 45, 30, {
        generator: "text",
        text: "Ciao",
        style: "title",
        position: "center",
      }),
    );
    const plan = compileVideo(d, PROBES, TARGET);
    expect(plan.segments.map((s) => [s.start, s.frames])).toEqual([
      [0, 40],
      [40, 5],
      [45, 15],
      [60, 15],
      [75, 25],
    ]);
    expect(seg(d, 40).script).toContain("overlay=x='W*(1-min(1,(n+0)/20))':y='0':eval=frame");
    expect(seg(d, 45).script).toContain("overlay=x='W*(1-min(1,(n+5)/20))':y='0':eval=frame");
    expect(seg(d, 45).script).toContain("alphamerge");
  });

  it.each([
    ["wipe_right", "x='-W*(1-min(1,(n+0)/20))':y='0'", true],
    ["wipe_up", "x='0':y='H*(1-min(1,(n+0)/20))'", true],
    ["wipe_down", "x='0':y='-H*(1-min(1,(n+0)/20))'", true],
    ["slide_left", "x='W*(1-min(1,(n+0)/20))':y='0':eval=frame:eof_action", false],
    ["slide_right", "x='-W*(1-min(1,(n+0)/20))':y='0':eval=frame:eof_action", false],
    ["slide_up", "x='0':y='H*(1-min(1,(n+0)/20))':eval=frame:eof_action", false],
    ["slide_down", "x='0':y='-H*(1-min(1,(n+0)/20))':eval=frame:eof_action", false],
  ] as const)("%s", (kind, expr, mask) => {
    const s = seg(cut(kind), 40).script;
    expect(s).toContain(expr);
    expect(s.includes("alphamerge")).toBe(mask);
  });

  it("a dip to black needs no handles: fades to and from black at the cut", () => {
    const plan = compileVideo(cut("dip_to_black", 10, 15), PROBES, TARGET);
    expect(plan.segments.map((s) => [s.start, s.frames])).toEqual([
      [0, 50],
      [50, 50],
    ]);
    expect(plan.segments[0]?.script).toContain(
      "setpts=PTS+0.000000/TB,fade=t=out:st=1.600000:d=0.400000,setpts=PTS-0.000000/TB",
    );
    expect(plan.segments[1]?.script).toContain("fade=t=in:st=0:d=0.600000,");
    expect(plan.segments[1]?.script).not.toContain("alpha=1");
  });

  it("two windows in a clip too short for both: the second starts later", () => {
    const d = doc(
      [
        clip("c1", "V1", 0, 40, A, {}, 100),
        clip("c2", "V1", 40, 12, B, {}, 100),
        clip("c3", "V1", 52, 40, A, {}, 300),
      ],
      {
        transitions: [
          {
            id: "t1",
            track: "V1",
            from: "c1",
            to: "c2",
            kind: "dissolve",
            inOffset: 5,
            outOffset: 8,
          },
          {
            id: "t2",
            track: "V1",
            from: "c2",
            to: "c3",
            kind: "dissolve",
            inOffset: 8,
            outOffset: 5,
          },
        ],
      },
    );
    const plan = compileVideo(d, PROBES, TARGET);
    expect(plan.segments.map((s) => [s.start, s.frames])).toEqual([
      [0, 35],
      [35, 13],
      [48, 9],
      [57, 35],
    ]);
    expect(plan.warnings).toContain(
      "transition t2 starts 4 frames later: c2 is too short for two transitions",
    );
  });

  it("a transition whose clips are not adjacent, or one of them off, is left out", () => {
    const d = cut("dissolve");
    (d.clips[1] as VideoClip).enabled = false;
    expect(spans(d)).toEqual([[0, 50]]);
  });
});

describe("texts and captions", () => {
  const title = (text: string, more: Partial<VideoClip> = {}, w = 640, h = 360) => {
    const d = doc([
      clip("v", "V1", 0, 50, A),
      clip("t", "V2", 0, 50, { generator: "text", text, style: "title", position: "center" }, more),
    ]);
    d.format = { ...d.format, width: w, height: h, aspect: w < h ? "9:16" : "16:9" };
    return seg(d, 0);
  };

  it("a title: drawtext with the server's font, the text in a file, no expansion", () => {
    const s = title("Titolo: 100% d'acqua");
    const [name, content] = Object.entries(s.files)[0] ?? [];
    expect(content).toBe("Titolo: 100% d'acqua");
    expect(s.script).toContain(
      `drawtext=fontfile=\\'/srv/fonts/Inter-Bold.ttf\\':textfile=${name}:expansion=none:text_align=C:fontsize=31`,
    );
    expect(s.script).toContain("x=(w-text_w)/2:y=(h-text_h)/2");
    expect(s.script).toContain("color=c=black@0:s=640x360");
  });

  it("sizes follow the short side; long lines are wrapped inside the frame", () => {
    const s = title("Una frase lunga che non entra in un quadro verticale stretto", {}, 360, 640);
    expect(s.script).toContain("fontsize=31");
    expect(Object.values(s.files)[0]).toBe(
      "Una frase lunga\nche non entra in un\nquadro verticale\nstretto",
    );
  });

  // Every text inside the title-safe area (5% from each side), whatever the shape.
  const SHAPES = [
    ["16:9", 640, 360],
    ["9:16", 360, 640],
    ["1:1", 360, 360],
    ["9:16 4K", 2160, 3840],
  ] as const;
  const TEXTS = [
    ["title", "center", "Titolo di prova"],
    ["title", "top", "Un titolo abbastanza lungo da andare a capo almeno una volta"],
    ["lower_third", "lower_third", "Mario Rossi, montatore"],
    ["lower_third", "lower_third", "Dottoressa Maria Margherita Bellavista, direttrice del museo"],
    ["subtitle", "bottom", "Supercalifragilistichespiralidoso"],
    ["title", "center", "Precipitevolissimevolmente"],
    ["caption", "bottom", "MMMMMMMMMMMMMMMMMMMM WWWWWWWWWWWWWW"],
    ["plain", "center", Array.from({ length: 12 }, (_, i) => `riga${i}`).join("\n")],
  ] as const;
  it.each(
    SHAPES.flatMap(([shape, w, h]) =>
      TEXTS.map(([style, pos, text]) => [shape, style, pos, text, w, h] as const),
    ),
  )("%s %s %s: «%s» stays inside", (_, style, pos, text, w, h) => {
    const f = fitText(text, style, pos, w, h);
    const bold = style === "title" || style === "lower_third";
    const mx = Math.ceil(w * TITLE_SAFE);
    const widest = Math.max(...f.lines.map((l) => textWidth(l, f.size, bold)));
    // the box's border included
    expect(widest + 2 * f.border).toBeLessThanOrEqual(w - 2 * mx);
    if (pos === "lower_third") expect(Number(f.x) - f.border).toBeGreaterThanOrEqual(mx);
    expect(f.lines.length * f.size * 1.25).toBeLessThanOrEqual(h * (1 - 2 * TITLE_SAFE));
    expect(f.lines.join(" ")).toBe(text.replace(/\s+/g, " "));
  });

  it.each([
    ["a short title keeps its size", "title", "center", "Titolo di prova", 640, 360, 31],
    ["the same title in 9:16 too", "title", "center", "Titolo di prova", 360, 640, 31],
    [
      "a word too long for 9:16: smaller, never cut",
      "title",
      "center",
      "Precipitevolissimevolmente",
      360,
      640,
      21,
    ],
    [
      "a word that fits in 16:9 keeps the size",
      "title",
      "center",
      "Precipitevolissimevolmente",
      640,
      360,
      31,
    ],
    [
      "the lower third in 9:16 (one line, inside)",
      "lower_third",
      "lower_third",
      "Mario Rossi, montatore",
      360,
      640,
      18,
    ],
    [
      "the lower third in 1:1",
      "lower_third",
      "lower_third",
      "Mario Rossi, montatore",
      360,
      360,
      18,
    ],
  ] as const)("%s", (_, style, pos, text, w, h, size) => {
    const f = fitText(text, style, pos, w, h);
    expect(f.size).toBe(size);
    expect(f.lines).toEqual([text]);
  });

  it("a long lower third in 9:16 wraps inside its box, starting at the safe margin", () => {
    const f = fitText(
      "Dottoressa Maria Margherita Bellavista, direttrice del museo",
      "lower_third",
      "lower_third",
      360,
      640,
    );
    expect(f.lines.length).toBeGreaterThan(1);
    expect([f.x, f.border]).toEqual(["23", 5]);
    expect(f.y).toBe("min(448\\,h-32-5-text_h)");
  });

  it("the estimate is never narrower than Inter (ffmpeg's bbox at 100 px)", () => {
    const measured = [
      ["Titolo di prova", 665, 691],
      ["Mario Rossi, montatore", 1077, 1124],
      ["MMMMWWWW", 744, 778],
      ["iiiilll", 156, 177],
      ["Supercalifragilistichespiralidoso", 1494, 1578],
      ["0123456789", 581, 612],
      ["Il secondo attraversa più segmenti", 1612, 1672],
    ] as const;
    for (const [text, regular, bold] of measured) {
      expect(textWidth(text, 100)).toBeGreaterThanOrEqual(regular);
      expect(textWidth(text, 100, true)).toBeGreaterThanOrEqual(bold);
    }
  });

  it("a subtitle word wider than the frame gets a smaller size; libass wraps the rest", () => {
    const long = [
      { id: "s", start: 0, end: 25, text: "Supercalifragilistichespiralidosissimamente" },
    ];
    const look = { style: "boxed", position: "bottom" } as const;
    const size = { width: 360, height: 640 };
    expect(captionsAss(long, look, R, size, 0, 25)).toMatch(/,,\{\\fs\d+\}Supercali/);
    const short = [{ id: "s", start: 0, end: 25, text: "Due parole" }];
    expect(captionsAss(short, look, R, size, 0, 25)).toContain(",,Due parole");
  });

  it("a text fades in alpha over what is below", () => {
    expect(title("Ciao", { fadeIn: 5 }).script).toContain("fade=t=in:st=0:d=0.200000:alpha=1");
  });

  it("filter values survive colons, apostrophes and Windows paths", () => {
    expect(filterValue("a:b")).toBe("\\'a:b\\'");
    expect(filterValue("it's")).toBe("\\'it\\'\\\\\\'\\'s\\'");
    expect(filterPath("C:\\Windows\\Fonts\\arial.ttf")).toBe("\\'C:/Windows/Fonts/arial.ttf\\'");
    expect(filterValue("[a],b;c")).toBe("\\'\\[a\\]\\,b\\;c\\'");
  });

  const caps = (burnIn: boolean) => {
    const d = doc([clip("v", "V1", 0, 100, A)]);
    d.captions = {
      language: "it",
      burnIn,
      style: "boxed",
      position: "bottom",
      segments: [
        { id: "s1", start: 10, end: 60, text: "Ciao {a tutti}" },
        { id: "s2", start: 70, end: 90, text: "Seconda" },
      ],
    };
    d.clips.push(clip("v2", "V2", 50, 50, B));
    return d;
  };

  it("burnt in: each segment carries the ASS of its own subtitles, times from its start", () => {
    const plan = compileVideo(caps(true), PROBES, TARGET);
    expect(plan.captions.mode).toBe("burn");
    const [first, second] = plan.segments;
    expect(first?.script).toContain("subtitles=filename=x-");
    expect(first?.script).toContain(":fontsdir=\\'/srv/fonts\\',format=yuv420p[vout]");
    const ass = (s: typeof first) => Object.values(s?.files ?? {})[0] ?? "";
    expect(ass(first)).toContain(
      "Dialogue: 0,0:00:00.40,0:00:02.00,Default,,0,0,0,,Ciao (a tutti)",
    );
    expect(ass(second)).toContain(
      "Dialogue: 0,0:00:00.00,0:00:00.40,Default,,0,0,0,,Ciao (a tutti)",
    );
    expect(ass(second)).toContain("Dialogue: 0,0:00:00.80,0:00:01.60,Default,,0,0,0,,Seconda");
    expect(plan.captions.srt).toContain("00:00:00,400 --> 00:00:02,400\nCiao {a tutti}");
  });

  it("as a text track: nothing in the picture, mov_text at the join", () => {
    const plan = compileVideo(caps(false), PROBES, TARGET);
    expect(plan.captions.mode).toBe("track");
    expect(plan.segments.every((s) => !s.script.includes("subtitles="))).toBe(true);
    const args = joinArgs(plan, "list.txt", "audio.m4a", "captions.srt", "out.mp4");
    expect(args).toEqual(
      expect.arrayContaining(["-map", "2:s", "-c:s", "mov_text", "language=ita", "+faststart"]),
    );
    expect(args.slice(-3)).toEqual(["-t", "4.000000", "out.mp4"]);
    const off = compileVideo(caps(false), PROBES, { ...TARGET, captions: "none" });
    expect(joinArgs(off, "l", "a", "s", "o")).not.toContain("mov_text");
    expect(off.captions.srt).toBeDefined();
  });

  it("SRT, WebVTT and ASS a table", () => {
    const list = [
      { id: "b", start: 50, end: 75, text: "Due <b> & tre" },
      { id: "a", start: 0, end: 25, text: "Uno\r\n\r\nriga" },
      { id: "e", start: 80, end: 80, text: "vuoto" },
    ];
    expect(captionsToSrt(list, R)).toBe(
      "1\n00:00:00,000 --> 00:00:01,000\nUno\nriga\n\n2\n00:00:02,000 --> 00:00:03,000\nDue <b> & tre\n",
    );
    expect(captionsToVtt(list, R)).toBe(
      "WEBVTT\n\n00:00:00.000 --> 00:00:01.000\nUno\nriga\n\n00:00:02.000 --> 00:00:03.000\nDue &lt;b&gt; &amp; tre\n",
    );
    const ass = captionsAss(
      list,
      { style: "bold", position: "top" },
      R,
      { width: 360, height: 640 },
      0,
      100,
    );
    expect(ass).toContain("PlayResX: 360\nPlayResY: 640");
    expect(ass).toContain(
      "Style: Default,Inter,20,&H00FFFFFF,&H00FFFFFF,&H00000000,&H60000000,-1,0,0,0,100,100,0,0,1,3,1,8,",
    );
    expect(ass).toContain(",,Uno\\Nriga");
    expect(
      captionsAss(
        list,
        { style: "plain", position: "bottom" },
        R,
        { width: 640, height: 360 },
        26,
        49,
      ),
    ).toBeUndefined();
    expect(subtitleLanguage("it-IT")).toBe("ita");
    expect(subtitleLanguage("")).toBe("und");
  });
});

describe("sound", () => {
  it("every clip in its place in samples, volume, fades, amix without normalizing", () => {
    const plan = compileVideo(montatore(), PROBES, { ...TARGET, loudnorm: false });
    const a = plan.audio;
    expect(a.inputs).toEqual([
      { before: ["-ss", "0.000000", "-t", "0.6500", "-vn"], media: "a.mp4" },
    ]);
    expect(a.script).toContain(
      "[0:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,atrim=end_sample=19200,asetpts=PTS-STARTPTS,afade=t=in:ns=9600,afade=t=out:ss=9600:ns=9600,volume=-6.0dB,adelay=delays=19200S:all=1",
    );
    expect(a.script).toContain("apad,atrim=end_sample=120960");
    expect(a.name).toMatch(/^audio-[0-9a-f]{24}\.m4a$/);
    expect(a.output).toEqual([
      "-map",
      "[aout]",
      "-c:a",
      "aac",
      "-b:a",
      "256k",
      "-ar",
      "48000",
      "-ac",
      "2",
    ]);
  });

  it("silence when no clip sounds", () => {
    const plan = compileVideo(doc([clip("v", "V1", 0, 25, A)]), PROBES, TARGET);
    expect(plan.audio.inputs).toEqual([]);
    expect(plan.audio.script).toBe("anullsrc=r=48000:cl=stereo,atrim=end_sample=48000[aout]\n");
  });

  it("J-cut and L-cut: the sound of the next shot starts before its picture, or the last runs on", () => {
    const d = doc([
      clip("v1", "V1", 0, 50, A, { link: "g1" }),
      clip("v2", "V1", 50, 50, B, { link: "g2" }),
      // J: b's sound 10 frames early; L: a's sound would run under b, here it ends at 40
      clip("a1", "A1", 0, 40, A, { link: "g1" }),
      clip("a2", "A1", 40, 60, B, { link: "g2" }, 0),
    ]);
    const plan = compileVideo(d, PROBES, TARGET);
    expect(plan.segments.map((s) => [s.start, s.frames])).toEqual([
      [0, 50],
      [50, 50],
    ]);
    expect(plan.audio.script).toContain("atrim=end_sample=115200");
    expect(plan.audio.script).toContain("adelay=delays=76800S:all=1");
    // at the timeline's very start and end
    const edge = doc([clip("v", "V1", 0, 50, A), clip("a", "A1", 0, 60, A)]);
    expect(compileVideo(edge, PROBES, TARGET).frames).toBe(60);
    expect(spans(edge)).toEqual([
      [0, 50],
      [50, 10],
    ]);
    expect(seg(edge, 50).inputs).toEqual([]);
  });

  it("a crossfade on an audio track uses the files' handles; a dip fades out and in", () => {
    const d = doc([clip("a1", "A1", 0, 50, A, {}, 100), clip("a2", "A1", 50, 50, B, {}, 100)], {
      transitions: [
        {
          id: "t",
          track: "A1",
          from: "a1",
          to: "a2",
          kind: "dissolve",
          inOffset: 10,
          outOffset: 10,
        },
      ],
    });
    const s = compileVideo(d, PROBES, TARGET).audio;
    expect(s.inputs.map((i) => i.before.slice(0, 4))).toEqual([
      ["-ss", "4.000000", "-t", "2.6500"],
      ["-ss", "3.600000", "-t", "2.6500"],
    ]);
    expect(s.script).toContain("afade=t=out:ss=76800:ns=38400");
    expect(s.script).toContain("afade=t=in:ns=38400");
    expect(s.script).toContain("adelay=delays=76800S:all=1");
    (d.transitions[0] as VideoTransition).kind = "dip_to_black";
    const dip = compileVideo(d, PROBES, TARGET).audio;
    expect(dip.script).toContain("afade=t=out:ss=76800:ns=19200");
    expect(dip.script).toContain("adelay=delays=96000S:all=1");
  });

  it("music ducked under the voice, the amount as sidechaincompress's mix", () => {
    const d = doc([clip("a1", "A1", 0, 50, A), clip("m", "A2", 0, 100, MUSIC, { volume: -8 })]);
    (d.tracks[3] as VideoTrack).duck = {
      under: ["A1"],
      amountDb: -12,
      attackMs: 200,
      releaseMs: 600,
    };
    const s = compileVideo(d, PROBES, TARGET).audio.script;
    expect(s).toContain("[tA1]asplit=2[tA1m][tA1sA2]");
    expect(s).toContain("[tA1sA2]apad[scA2]");
    expect(s).toContain(
      "[tA2][scA2]sidechaincompress=threshold=0.003:ratio=20:attack=200.00:release=600.00:makeup=1:mix=0.7488,atrim=end_sample=192000[dA2]",
    );
    expect(s).toContain("[tA1m][dA2]amix=inputs=2:normalize=0");
    // a voice track with nothing on it: no ducking
    const quiet = doc([clip("m", "A2", 0, 100, MUSIC)]);
    (quiet.tracks[3] as VideoTrack).duck = {
      under: ["A1"],
      amountDb: -12,
      attackMs: 200,
      releaseMs: 600,
    };
    expect(compileVideo(quiet, PROBES, TARGET).audio.script).not.toContain("sidechaincompress");
  });

  it("A2: with loudnorm the mix is FLAC, measured and corrected in two passes", () => {
    const plan = compileVideo(montatore(), PROBES, TARGET);
    expect(plan.loudness).toBe(true);
    expect(plan.audio.name).toMatch(/^mix-[0-9a-f]{24}\.flac$/);
    expect(plan.audio.output).toEqual(["-map", "[aout]", "-c:a", "flac"]);
    const printed = `[Parsed_loudnorm_0 @ 0x1]\n{\n\t"input_i" : "-21.30",\n\t"input_tp" : "-3.02",\n\t"input_lra" : "4.10",\n\t"input_thresh" : "-31.55",\n\t"output_i" : "-14.1",\n\t"target_offset" : "0.12"\n}\n`;
    const m = parseLoudnorm(printed);
    expect(m).toEqual({
      input_i: "-21.30",
      input_tp: "-3.02",
      input_lra: "4.10",
      input_thresh: "-31.55",
      target_offset: "0.12",
    });
    expect(loudnormApplyArgs("mix.flac", m, "a.m4a")).toContain(
      "loudnorm=I=-14:TP=-1.5:LRA=11:measured_I=-21.30:measured_TP=-3.02:measured_LRA=4.10:measured_thresh=-31.55:offset=0.12:linear=true,aresample=48000",
    );
    // a silent mix: no measure, encoded as it is
    expect(parseLoudnorm('{ "input_i" : "-inf", "input_tp" : "-inf" }')).toBeUndefined();
    expect(loudnormApplyArgs("mix.flac", undefined, "a.m4a")).not.toContain("-af");
  });
});

describe("encoding and hashes", () => {
  it("H.264 High yuv420p BT.709 with libx264 or NVENC", () => {
    expect(encoderArgs("libx264", "good", R)).toEqual([
      "-c:v",
      "libx264",
      "-preset",
      "fast",
      "-crf",
      "20",
      "-profile:v",
      "high",
      "-pix_fmt",
      "yuv420p",
      "-g",
      "25",
      "-bf",
      "2",
      "-r",
      "25/1",
      "-color_range",
      "tv",
      "-colorspace",
      "bt709",
      "-color_primaries",
      "bt709",
      "-color_trc",
      "bt709",
      "-map_metadata",
      "-1",
    ]);
    expect(encoderArgs("h264_nvenc", "best", { num: 30000, den: 1001 }).slice(0, 12)).toEqual([
      "-c:v",
      "h264_nvenc",
      "-preset",
      "p7",
      "-tune",
      "hq",
      "-rc",
      "vbr",
      "-cq",
      "18",
      "-b:v",
      "0",
    ]);
  });

  it("a step's command line: inputs through the media's path, the graph from a file", () => {
    const s = seg(montatore(), 12);
    const args = stepArgs(s, (m) => `/progetto/${m}`, "g.graph", "out.mp4");
    expect(args.slice(0, 9)).toEqual([
      "-hide_banner",
      "-nostdin",
      "-y",
      "-ss",
      "0.480000",
      "-t",
      "1.0500",
      "-an",
      "-i",
    ]);
    expect(args).toContain("/progetto/b.mp4");
    expect(args[args.indexOf("-/filter_complex") + 1]).toBe("g.graph");
    expect(args[args.indexOf("-frames:v") + 1]).toBe("20");
    expect(args.at(-1)).toBe("out.mp4");
  });

  it("hashes are stable, change with the segment's content and files, not with the others", () => {
    const one = compileVideo(montatore(), PROBES, TARGET);
    const two = compileVideo(montatore(), PROBES, TARGET);
    expect(two.segments.map((s) => s.hash)).toEqual(one.segments.map((s) => s.hash));
    expect(two.audio.hash).toBe(one.audio.hash);
    expect(new Set(one.segments.map((s) => s.hash)).size).toBe(one.segments.length);
    // the B's fade changes only the segment it is in
    const d = montatore();
    (d.clips[2] as VideoClip).fadeIn = 4;
    const edited = compileVideo(d, PROBES, TARGET).segments.map((s) => s.hash);
    expect(edited.filter((h, i) => h !== one.segments[i]?.hash)).toHaveLength(1);
    // a file that changed (its fingerprint) changes the segments that read it
    const changed = compileVideo(
      montatore(),
      { ...PROBES, "b.mp4": { ...PROBES["b.mp4"], fingerprint: "b2" } },
      TARGET,
    );
    expect(
      changed.segments.filter((s, i) => s.hash !== one.segments[i]?.hash).map((s) => s.start),
    ).toEqual([12]);
    // another encoder or quality: other segments
    const nv = compileVideo(montatore(), PROBES, { ...TARGET, encoder: "h264_nvenc" });
    expect(nv.segments[0]?.hash).not.toBe(one.segments[0]?.hash);
    expect(one.segments[0]?.name).toBe(`seg-${one.segments[0]?.hash}.mp4`);
  });

  it("speed (A3) is not rendered yet, and says so", () => {
    const plan = compileVideo(doc([clip("v", "V1", 0, 25, A, { speed: 2 })]), PROBES, TARGET);
    expect(plan.warnings).toEqual([
      "speed is not rendered yet (3.10): those clips play at normal speed",
    ]);
  });
});

describe("probe", () => {
  const rate = { num: 30000, den: 1001 };
  it.each([
    [
      "a video with sound",
      {
        streams: [
          {
            codec_type: "video",
            codec_name: "h264",
            width: 3840,
            height: 2160,
            duration: "10.010000",
          },
          { codec_type: "audio", codec_name: "aac", duration: "10.0" },
        ],
        format: { format_name: "mov,mp4,m4a,3gp,3g2,mj2", duration: "10.010000" },
      },
      { frames: 300, audio: true },
      [3840, 2160],
    ],
    [
      "a photo",
      {
        streams: [
          {
            codec_type: "video",
            codec_name: "mjpeg",
            width: 600,
            height: 900,
            duration: "0.040000",
          },
        ],
        format: { format_name: "image2", duration: "0.040000" },
      },
      { frames: null, audio: false },
      [600, 900],
    ],
    [
      "music with a cover picture",
      {
        streams: [
          { codec_type: "audio", codec_name: "mp3", duration: "180.5" },
          {
            codec_type: "video",
            codec_name: "mjpeg",
            width: 500,
            height: 500,
            disposition: { attached_pic: 1 },
          },
        ],
        format: { format_name: "mp3", duration: "180.500000" },
      },
      { frames: 5409, audio: true },
      [0, 0],
    ],
  ])("%s: what the render reads of the analysis' probe", (_, json, expected, size) => {
    const p = parseProbe(json, 1000);
    expect(renderProbeOf(p, rate)).toEqual(expected);
    expect([p.width, p.height]).toEqual(size);
  });
  it("nothing readable is refused; the fingerprint is carried", () => {
    expect(() => parseProbe({})).toThrow();
    const p = parseProbe({ streams: [{ codec_type: "audio" }], format: { duration: "1" } });
    expect(renderProbeOf(p, R, "10:20")).toEqual({ frames: 25, audio: true, fingerprint: "10:20" });
  });
});
