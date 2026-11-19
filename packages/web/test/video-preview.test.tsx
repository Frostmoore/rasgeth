// @vitest-environment jsdom
// G41.5a: a timeline played in the page. The player's pure parts (what each track shows or
// plays at a frame: fades, transitions as CSS, Ken Burns, crossfades, ducking, hidden and muted
// tracks), the player with fake media elements and a fake clock (which file plays, the next one
// loaded ahead, players moved back in line beyond DRIFT), and the preview in the canvas with a
// fake server (files prepared as jobs, then the links; «Anteprima esatta» as a job, then its video).
import { newRgVideo, type RgVideo, type VideoClip } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  audioLayers,
  captionAt,
  DRIFT,
  fadeGain,
  kenBurnsCss,
  type MediaLike,
  nextClip,
  TimelinePlayer,
  timelineEnd,
  videoLayers,
} from "../src/components/viewers/video/player.js";
import { lang } from "../src/i18n.js";

type Handler = (...args: unknown[]) => unknown;
const calls: [string, unknown[]][] = [];
let handlers: Record<string, Handler> = {};
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        const h = handlers[name];
        return h ? Promise.resolve(h(...args)) : Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));
const { VideoPreview, playerMediaOf } = await import("../src/components/viewers/VideoPreview.js");

const R = { num: 25, den: 1 };
const clip = (
  id: string,
  track: string,
  start: number,
  dur: number,
  media: string,
  more: Partial<VideoClip> = {},
): VideoClip => ({
  id,
  track,
  start,
  sourceRange: { start: 0, duration: dur },
  ref: { media },
  enabled: true,
  volume: 0,
  fadeIn: 0,
  fadeOut: 0,
  fit: "fill",
  ...more,
});

function timeline(): RgVideo {
  const d = newRgVideo({ width: 1280, height: 720, rate: R, aspect: "16:9" });
  d.tracks = [
    { id: "V1", kind: "Video", name: "V1", locked: false },
    { id: "V2", kind: "Video", name: "V2", locked: false },
    { id: "A1", kind: "Audio", name: "A1", locked: false },
    {
      id: "A2",
      kind: "Audio",
      name: "A2",
      locked: false,
      duck: { under: ["A1"], amountDb: -12, attackMs: 200, releaseMs: 600 },
    },
  ];
  d.clips = [
    clip("a", "V1", 0, 100, "a.mp4", { fadeIn: 10 }),
    clip("b", "V1", 100, 100, "b.mp4", { sourceRange: { start: 50, duration: 100 } }),
    clip("p", "V2", 200, 50, "foto.jpg", {
      ref: { media: "foto.jpg", still: true },
      kenBurns: { from: { x: 0, y: 0, w: 1, h: 1 }, to: { x: 0.2, y: 0.1, w: 0.5, h: 0.5 } },
    }),
    clip("t", "V2", 20, 40, "", {
      ref: { generator: "text", text: "Ciao", style: "title", position: "center" },
    }),
    clip("va", "A1", 0, 100, "a.mp4", { volume: -6 }),
    clip("vb", "A1", 100, 100, "b.mp4", { sourceRange: { start: 50, duration: 100 } }),
    clip("m", "A2", 0, 400, "music.m4a"),
  ];
  d.transitions = [
    { id: "x", track: "V1", from: "a", to: "b", kind: "dissolve", inOffset: 10, outOffset: 10 },
    { id: "y", track: "A1", from: "va", to: "vb", kind: "dissolve", inOffset: 5, outOffset: 5 },
  ];
  d.captions = {
    ...d.captions,
    segments: [{ id: "s1", start: 25, end: 50, text: "Buongiorno" }],
  };
  return d;
}

const MEDIA = {
  "a.mp4": { proxy: "/preview/a/proxy.mp4", file: "/preview/a/a.mp4", kind: "video" as const },
  "b.mp4": { file: "/preview/b/b.mp4", kind: "video" as const },
  "foto.jpg": { file: "/preview/f/foto.jpg", kind: "image" as const },
  "music.m4a": { file: "/preview/m/music.m4a", kind: "audio" as const },
};

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  handlers = {};
  for (const m of ["load", "pause"] as const)
    vi.spyOn(HTMLMediaElement.prototype, m).mockImplementation(() => {});
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(async () => {});
});
afterEach(() => {
  cleanup();
  vi.restoreAllMocks();
});

describe("what plays at a frame", () => {
  it("fades, a dissolve on the handles, Ken Burns, texts; a hidden track shows nothing", () => {
    const d = timeline();
    expect(fadeGain(d.clips[0] as VideoClip, 5)).toBe(0.5);
    const v = (f: number, track = "V1") =>
      videoLayers(d, track, f, MEDIA).map((l) => [
        l.clip.id,
        l.kind,
        Number(l.time.toFixed(2)),
        Number(l.opacity.toFixed(2)),
        l.top,
      ]);
    expect(v(50)).toEqual([["a", "video", 2, 1, false]]);
    // the dissolve: 10 frames before the cut and 10 after, "b" over "a", started on its handle
    expect(v(89)).toEqual([["a", "video", 3.56, 1, false]]);
    expect(v(95)).toEqual([
      ["a", "video", 3.8, 1, false],
      ["b", "video", 1.8, 0.25, true],
    ]);
    expect(v(105)).toEqual([
      ["a", "video", 4.2, 1, false],
      ["b", "video", 2.2, 0.75, true],
    ]);
    expect(v(110)).toEqual([["b", "video", 2.4, 1, false]]);
    // Ken Burns: the rectangle moves from the whole picture to a quarter
    const kb = videoLayers(d, "V2", 249, MEDIA)[0];
    expect(kb?.kind).toBe("image");
    expect(kb?.transform).toBe(
      kenBurnsCss({ from: { x: 0, y: 0, w: 1, h: 1 }, to: { x: 0.2, y: 0.1, w: 0.5, h: 0.5 } }, 1),
    );
    expect(
      kenBurnsCss({ from: { x: 0, y: 0, w: 1, h: 1 }, to: { x: 0.2, y: 0.1, w: 0.5, h: 0.5 } }, 1),
    ).toBe("scale(2.0000) translate(-20.000%, -10.000%)");
    expect(v(30, "V2")).toEqual([["t", "text", 0.4, 1, false]]);
    d.tracks[0] = { ...(d.tracks[0] as RgVideo["tracks"][number]), hidden: true };
    expect(videoLayers(d, "V1", 50, MEDIA)).toEqual([]);
  });

  it("wipes, slides and dips to black as CSS", () => {
    const d = timeline();
    const at = (kind: string, f: number) => {
      d.transitions = [
        {
          id: "x",
          track: "V1",
          from: "a",
          to: "b",
          kind: kind as "dissolve",
          inOffset: 10,
          outOffset: 10,
        },
      ];
      return videoLayers(d, "V1", f, MEDIA);
    };
    expect(at("wipe_left", 100)[1]?.clipPath).toBe("inset(0 0 0 50.00%)");
    expect(at("wipe_up", 100)[1]?.clipPath).toBe("inset(50.00% 0 0 0)");
    expect(at("slide_right", 100)[1]?.transform).toBe("translate(-50.00%, 0)");
    expect(at("slide_down", 100)[1]?.transform).toBe("translate(0, -50.00%)");
    // a dip: one clip at a time, through black
    expect(at("dip_to_black", 95).map((l) => [l.clip.id, l.brightness])).toEqual([["a", 0.5]]);
    expect(at("dip_to_black", 105).map((l) => [l.clip.id, l.brightness])).toEqual([["b", 0.5]]);
  });

  it("sound: volume, a crossfade, the music ducked under the voice, a muted track silent", () => {
    const d = timeline();
    const a = (track: string, f: number) =>
      audioLayers(d, track, f).map((l) => [
        l.clip.id,
        Number(l.time.toFixed(2)),
        Number(l.gain.toFixed(3)),
      ]);
    expect(a("A1", 50)).toEqual([["va", 2, 0.501]]);
    expect(a("A1", 99)).toEqual([
      ["va", 3.96, 0.301],
      ["vb", 1.96, 0.4],
    ]);
    // −12 dB while A1 speaks, back up after
    expect(a("A2", 50)).toEqual([["m", 2, 0.251]]);
    expect(a("A2", 300)).toEqual([["m", 12, 1]]);
    d.tracks[2] = { ...(d.tracks[2] as RgVideo["tracks"][number]), muted: true };
    expect(a("A1", 50)).toEqual([]);
    expect(a("A2", 50)).toEqual([["m", 2, 1]]);
  });

  it("subtitles, the next clip, the end", () => {
    const d = timeline();
    expect(captionAt(d, 30)?.text).toBe("Buongiorno");
    expect(captionAt(d, 50)).toBeUndefined();
    expect(nextClip(d, "V1", 60)?.id).toBe("b");
    expect(timelineEnd(d)).toBe(400);
  });
});

/** A media element the test can look into: playing, where, what it loaded. */
function fakeEl(tag: "video" | "audio") {
  const el = document.createElement("div") as unknown as MediaLike &
    HTMLElement & { loads: number; tag: string; paused: boolean };
  Object.assign(el, {
    tag,
    src: "",
    currentTime: 0,
    paused: true,
    playbackRate: 1,
    volume: 1,
    muted: false,
    preload: "",
    loads: 0,
    play() {
      el.paused = false;
      return Promise.resolve();
    },
    pause() {
      el.paused = true;
    },
    load() {
      el.loads++;
    },
  });
  return el;
}

describe("TimelinePlayer", () => {
  const setup = () => {
    const stage = document.createElement("div");
    const audioBox = document.createElement("div");
    const made: ReturnType<typeof fakeEl>[] = [];
    let now = 0;
    const frames: number[] = [];
    const p = new TimelinePlayer({
      stage,
      audioBox,
      media: (tag) => {
        const el = fakeEl(tag);
        made.push(el);
        return el;
      },
      now: () => now,
      schedule: () => 1,
      cancel: () => {},
      onFrame: (f) => frames.push(f),
    });
    p.setDoc(timeline(), MEDIA);
    const shown = (track: string) =>
      [...(stage.querySelector(`[data-track="${track}"]`)?.children ?? [])] as HTMLElement[];
    const slots = (track: string) => made.filter((m) => m.parentElement?.dataset.track === track);
    return { p, stage, slots, shown, frames, at: (ms: number) => (now = ms) };
  };

  it("seeks: the proxy (or the file) of the clip, muted pictures, sound from the audio tracks", () => {
    const { p, slots, stage } = setup();
    p.seek(50);
    const v1 = slots("V1");
    expect(v1).toHaveLength(2);
    const on = v1.find((s) => s.style.opacity !== "0");
    expect(on?.src).toBe("/preview/a/proxy.mp4");
    expect(on?.currentTime).toBe(2);
    expect(on?.muted).toBe(true);
    expect(on?.paused).toBe(true);
    // b.mp4 has no proxy yet: its file plays
    p.seek(150);
    expect(v1.find((s) => s.style.opacity !== "0")?.src).toBe("/preview/b/b.mp4");
    const a1 = slots("A1").find((s) => s.volume > 0);
    expect(a1?.src).toBe("/preview/b/b.mp4");
    expect(a1?.muted).toBe(false);
    // the text and the subtitle are HTML over the pictures
    p.seek(30);
    expect([...stage.querySelectorAll(".vp-text")].map((e) => e.textContent)).toContain("Ciao");
    expect(stage.querySelector(".vp-caption")?.textContent).toBe("Buongiorno");
    p.seek(220);
    const img = stage.querySelector<HTMLImageElement>('[data-track="V2"] img.vp-picture');
    expect(img?.getAttribute("src")).toBe("/preview/f/foto.jpg");
    expect(img?.style.transform).toMatch(/^scale\(/);
  });

  it("plays on the page's clock: loads the next clip ahead, moves a drifting player back", () => {
    const { p, slots, at, frames } = setup();
    p.seek(40);
    at(0);
    p.play();
    at(1000); // 25 frames later: 65, less than 2 s before the dissolve's window
    p.tick();
    expect(frames.at(-1)).toBe(65);
    const v1 = slots("V1");
    const playing = v1.find((s) => !s.paused);
    expect(playing?.src).toBe("/preview/a/proxy.mp4");
    const idle = v1.find((s) => s !== playing);
    // the free player holds b.mp4 at its first frame, before it is needed
    expect(idle?.src).toBe("/preview/b/b.mp4");
    expect(idle?.currentTime).toBe(2);
    // a player that drifted beyond DRIFT is moved back; within it, left alone
    if (playing) playing.currentTime = 2.6 + DRIFT * 2;
    at(1040);
    p.tick();
    expect(playing?.currentTime).toBeCloseTo(2.64, 5);
    if (playing) playing.currentTime = 2.7;
    at(1080);
    p.tick();
    expect(playing?.currentTime).toBe(2.7);
    // in the dissolve both players show
    at(2200);
    p.tick();
    expect(v1.filter((s) => s.style.opacity !== "0" && !s.paused)).toHaveLength(2);
    p.pause();
    expect([...v1, ...slots("A1")].every((s) => s.paused)).toBe(true);
  });

  it("a muted track stays silent, a hidden one dark; the end stops it", () => {
    const { p, slots, at } = setup();
    const d = timeline();
    d.tracks = d.tracks.map((t) =>
      t.id === "V1" ? { ...t, hidden: true } : t.id === "A1" ? { ...t, muted: true } : t,
    );
    p.setDoc(d, MEDIA);
    p.seek(50);
    p.play();
    at(10);
    p.tick();
    expect(slots("V1").every((s) => s.style.opacity === "0" && s.paused)).toBe(true);
    expect(slots("A1").every((s) => s.volume === 0 && s.paused)).toBe(true);
    expect(slots("A2").some((s) => !s.paused && s.volume === 1)).toBe(true);
    at(60_000);
    p.tick();
    expect(p.playing).toBe(false);
    expect(p.frame).toBe(400);
  });
});

describe("VideoPreview", () => {
  it("prepares the files as jobs, then plays on their links; the exact preview as a job, then its video", async () => {
    const doc = timeline();
    const file = { scope: "project:p1", path: "montaggi/film.rgvideo" };
    let round = 0;
    handlers.read = () => ({ encoding: "utf8", content: JSON.stringify(doc), path: file.path });
    handlers.canvasVersion = () => ({ version: 1 });
    handlers.videoPrepare = () => {
      round++;
      return {
        fonts: { regular: "/preview/i/Inter-Regular.ttf", bold: "/preview/i/Inter-Bold.ttf" },
        media:
          round === 1
            ? [
                { media: "a.mp4", file: "/preview/a/a.mp4", jobs: ["j1"] },
                { media: "b.mp4", missing: true, jobs: [] },
                { media: "foto.jpg", kind: "image", file: "/preview/f/foto.jpg", jobs: [] },
                { media: "music.m4a", file: "/preview/m/music.m4a", jobs: [] },
              ]
            : [
                {
                  media: "a.mp4",
                  kind: "video",
                  file: "/preview/a/a.mp4",
                  proxy: "/preview/a/proxy.mp4",
                  probe: { duration: 4 },
                  filmstrip: { url: "/preview/a/filmstrip.jpg", tiles: 4 },
                  jobs: [],
                },
                { media: "b.mp4", missing: true, jobs: [] },
                { media: "foto.jpg", kind: "image", file: "/preview/f/foto.jpg", jobs: [] },
                { media: "music.m4a", file: "/preview/m/music.m4a", jobs: [] },
              ],
      };
    };
    handlers.job = (id: unknown) =>
      id === "j1"
        ? { id: "j1", kind: "video_proxy", vars: { name: "a.mp4" }, state: "done", steps: [] }
        : {
            id: "e1",
            kind: "video_preview",
            vars: { name: "film.rgvideo" },
            state: "done",
            steps: [],
            result: { id: "0123456789abcdef01234567", start: 0, frames: 125, warnings: [] },
          };
    handlers.videoExact = () => ({ job: { id: "e1", state: "running" } });
    handlers.videoExactLink = () => ({ url: "/preview/e/0123.mp4" });
    const r = render(<VideoPreview file={file} />);
    await waitFor(() => expect(r.container.querySelector(".vp-tracks")).not.toBeNull());
    expect(await r.findByText("Un file non è nel progetto: b.mp4")).toBeTruthy();
    // the job ended: asked again, now with the proxy and the strip
    await waitFor(() => expect(round).toBe(2));
    await waitFor(() => expect(r.container.querySelector(".vp-strip:not(.still)")).not.toBeNull());
    expect(
      (r.container.querySelector(".vp-strip:not(.still)") as HTMLElement).style.backgroundImage,
    ).toContain("filmstrip.jpg");
    expect(document.getElementById("vp-fonts")?.textContent).toContain("Inter-Regular.ttf");
    expect(r.container.querySelector(".vp-tc")?.textContent).toContain("00:00:00:00");
    expect(r.getAllByRole("slider")).toHaveLength(1);
    // keys: a frame on, a second on
    fireEvent.keyDown(r.container.querySelector(".vp") as HTMLElement, { key: "ArrowRight" });
    fireEvent.keyDown(r.container.querySelector(".vp") as HTMLElement, {
      key: "ArrowRight",
      shiftKey: true,
    });
    await waitFor(() =>
      expect(r.container.querySelector(".vp-tc")?.textContent).toContain("00:00:01:01"),
    );
    fireEvent.click(r.getByRole("button", { name: "10 s" }));
    fireEvent.click(r.getByRole("button", { name: /Anteprima esatta/ }));
    await waitFor(() => expect(r.container.querySelector(".vp-exact video")).not.toBeNull());
    expect(calls.find(([n]) => n === "videoExact")?.[1]).toEqual([file.scope, file.path, 26, 276]);
    expect(r.container.querySelector(".vp-exact video")?.getAttribute("src")).toBe(
      "/preview/e/0123.mp4",
    );
    expect(r.container.querySelector(".vp-exact-bar")?.textContent).toContain(
      "Anteprima esatta da",
    );
    fireEvent.click(r.getByRole("button", { name: "Torna alla timeline" }));
    await waitFor(() => expect(r.container.querySelector(".vp-exact")).toBeNull());
    // no native controls of choice anywhere
    expect(
      r.container.querySelector('input[type="checkbox"], input[type="radio"], select'),
    ).toBeNull();
  });

  it("the page's map of files", () => {
    expect(
      playerMediaOf([
        { media: "a.mp4", kind: "video", proxy: "/p", file: "/f", jobs: [] },
        { media: "x.mp4", missing: true, jobs: [] },
      ]),
    ).toEqual({ "a.mp4": { proxy: "/p", file: "/f", kind: "video" }, "x.mp4": { missing: true } });
  });
});
