// The timeline played in the browser on the proxies (G41.5a), as montatore's playback.js: for
// every video track two <video> that take turns (one plays the clip, the other loads the next
// one a couple of seconds before; in a transition both show), pictures as <img> with Ken Burns
// as a CSS transform, texts and colours as HTML; for every audio track two hidden media elements
// with volume, fades and crossfades. Videos on video tracks are always muted: the sound comes
// from the audio tracks only, as in the render. The clock is the page's: while playing the frame
// comes from the time gone by, and a player more than DRIFT away is moved back in line.
// Dissolves are opacity, dips to black are brightness, wipes are clip-path, slides transform:
// the effects of compile.ts (G41.3) in CSS. «Anteprima esatta» (ffmpeg) shows the exact render.

import {
  clipEnd,
  clipLength,
  framesToSeconds,
  isMediaRef,
  type RgVideo,
  type VideoCaption,
  type VideoClip,
  type VideoKenBurns,
  type VideoTextRef,
  type VideoTransition,
} from "@redgiant/protocol";

/** Seconds before a clip when its file starts loading in the free player. */
export const PRELOAD = 2.0;
/** Seconds of difference beyond which a playing element is moved back in line. */
export const DRIFT = 0.12;

/** What the page has of a file: its proxy, the file itself, its kind. */
export interface PlayerMedia {
  proxy?: string;
  file?: string;
  kind?: "video" | "image" | "audio";
  missing?: boolean;
}
export type PlayerMediaMap = Record<string, PlayerMedia>;

/** Where a video file plays from: the proxy, or the file itself until the proxy is made. */
export const playSrc = (m: PlayerMedia | undefined): string | undefined =>
  m && !m.missing ? (m.proxy ?? m.file) : undefined;

// ---- pure: what shows at a frame ----------------------------------------------------------

/** Opacity or gain of a clip's own fades at a timeline frame, 0..1. */
export function fadeGain(c: VideoClip, frame: number): number {
  const f = frame - c.start;
  const L = clipLength(c);
  let g = 1;
  if (c.fadeIn > 0) g = Math.min(g, f / c.fadeIn);
  if (c.fadeOut > 0) g = Math.min(g, (L - f) / c.fadeOut);
  return Math.max(0, Math.min(1, g));
}

/** Ken Burns as compile.ts does it with zoompan: the rectangle shown moves from `from` to `to`. */
export function kenBurnsCss(kb: VideoKenBurns, p: number): string {
  const q = Math.max(0, Math.min(1, p));
  const lerp = (a: number, b: number) => a + (b - a) * q;
  const w = Math.max(0.01, lerp(kb.from.w, kb.to.w));
  const x = lerp(kb.from.x, kb.to.x);
  const y = lerp(kb.from.y, kb.to.y);
  return `scale(${(1 / w).toFixed(4)}) translate(${(-x * 100).toFixed(3)}%, ${(-y * 100).toFixed(3)}%)`;
}

/** One thing a video track shows at a frame. */
export interface VideoLayer {
  clip: VideoClip;
  kind: "video" | "image" | "text" | "color";
  /** Seconds into the file (videos). */
  time: number;
  opacity: number;
  /** Below 1 while dipping to black. */
  brightness: number;
  /** Ken Burns, a slide. */
  transform: string;
  clipPath: string;
  /** Above the other layer of the track (the incoming clip of a transition). */
  top: boolean;
}

const playing = (doc: RgVideo, track: string) =>
  doc.clips.filter((c) => c.track === track && c.enabled).sort((a, b) => a.start - b.start);

/** The transitions of a track that still sit between two adjacent clips. */
function liveTransitions(doc: RgVideo, track: string): VideoTransition[] {
  const byId = new Map(doc.clips.map((c) => [c.id, c]));
  return doc.transitions.filter((t) => {
    const a = byId.get(t.from);
    const b = byId.get(t.to);
    return t.track === track && !!a && !!b && a.enabled && b.enabled && clipEnd(a) === b.start;
  });
}

function kindOf(c: VideoClip, media: PlayerMediaMap): VideoLayer["kind"] {
  if (!isMediaRef(c.ref))
    return "generator" in c.ref && c.ref.generator === "color" ? "color" : "text";
  return c.ref.still || media[c.ref.media]?.kind === "image" ? "image" : "video";
}

function layerOf(doc: RgVideo, c: VideoClip, frame: number, media: PlayerMediaMap): VideoLayer {
  const kind = kindOf(c, media);
  const offset = frame - c.start;
  const rate = doc.format.rate;
  const L = clipLength(c);
  return {
    clip: c,
    kind,
    time: framesToSeconds(c.sourceRange.start + offset, rate),
    opacity: fadeGain(c, frame),
    brightness: 1,
    transform: c.kenBurns ? kenBurnsCss(c.kenBurns, offset / Math.max(1, L - 1)) : "",
    clipPath: "",
    top: false,
  };
}

/**
 * What a video track shows at a frame: nothing, one clip, or the two clips of a transition
 * (the outgoing one played on past its cut, the incoming one started before it, on their files'
 * handles). A hidden track shows nothing.
 */
export function videoLayers(
  doc: RgVideo,
  trackId: string,
  frame: number,
  media: PlayerMediaMap = {},
): VideoLayer[] {
  const track = doc.tracks.find((t) => t.id === trackId);
  if (!track || track.hidden) return [];
  const f = Math.floor(frame);
  const clips = playing(doc, trackId);
  const byId = new Map(clips.map((c) => [c.id, c]));
  for (const t of liveTransitions(doc, trackId)) {
    const a = byId.get(t.from) as VideoClip;
    const b = byId.get(t.to) as VideoClip;
    const cut = clipEnd(a);
    const lenA = Math.min(t.inOffset, clipLength(a));
    const lenB = Math.min(t.outOffset, clipLength(b));
    if (t.kind === "dip_to_black") {
      // The first clip fades to black before the cut, the second from black after it.
      if (f >= cut - lenA && f < cut) {
        const l = layerOf(doc, a, f, media);
        return [{ ...l, brightness: Math.max(0, (cut - f) / Math.max(1, lenA)) }];
      }
      if (f >= cut && f < cut + lenB) {
        const l = layerOf(doc, b, f, media);
        return [{ ...l, brightness: Math.min(1, (f - cut) / Math.max(1, lenB)) }];
      }
      continue;
    }
    const from = cut - lenA;
    const to = cut + lenB;
    if (f < from || f >= to || to <= from) continue;
    // As ffmpeg's fade and overlay in compile.ts: the frame inside the window over its length.
    const p = Math.min(1, (f - from) / (to - from));
    const la = layerOf(doc, a, f, media);
    const lb = { ...layerOf(doc, b, f, media), top: true };
    const [kind, dir] = t.kind.split("_") as [string, "left" | "right" | "up" | "down"];
    const rest = `${((1 - p) * 100).toFixed(2)}%`;
    if (t.kind === "dissolve") lb.opacity *= p;
    else if (kind === "wipe")
      lb.clipPath = {
        left: `inset(0 0 0 ${rest})`,
        right: `inset(0 ${rest} 0 0)`,
        up: `inset(${rest} 0 0 0)`,
        down: `inset(0 0 ${rest} 0)`,
      }[dir];
    else if (kind === "slide")
      lb.transform = `${
        {
          left: `translate(${rest}, 0)`,
          right: `translate(-${rest}, 0)`,
          up: `translate(0, ${rest})`,
          down: `translate(0, -${rest})`,
        }[dir]
      } ${lb.transform}`.trim();
    // Past its end the outgoing clip is not faded out by its own fade-out.
    if (f >= cut) la.opacity = 1;
    if (f < b.start) lb.opacity = t.kind === "dissolve" ? p : 1;
    return [la, lb];
  }
  const c = clips.find((x) => f >= x.start && f < clipEnd(x));
  return c ? [layerOf(doc, c, f, media)] : [];
}

/** One thing an audio track plays at a frame, with its gain (fades, crossfades, volume, duck). */
export interface AudioLayer {
  clip: VideoClip;
  time: number;
  gain: number;
}

const dbGain = (db: number) => 10 ** (db / 20);

/**
 * What an audio track plays at a frame. A transition on an audio track is a crossfade on the
 * handles; a track with `duck` goes down by its amount while one of its `under` tracks plays
 * (the render follows the voice's level; here the clips' presence). A muted track plays nothing.
 */
export function audioLayers(doc: RgVideo, trackId: string, frame: number): AudioLayer[] {
  const track = doc.tracks.find((t) => t.id === trackId);
  if (!track || track.muted) return [];
  const f = Math.floor(frame);
  const rate = doc.format.rate;
  const clips = playing(doc, trackId).filter(
    (c) => isMediaRef(c.ref) && !c.ref.still && c.ref.audio !== false,
  );
  const duck =
    (track.duck?.under.some((u) => audioLayers({ ...doc, transitions: [] }, u, f).length) ?? false)
      ? dbGain(track.duck?.amountDb ?? -12)
      : 1;
  const at = (c: VideoClip, g: number): AudioLayer => ({
    clip: c,
    time: framesToSeconds(c.sourceRange.start + f - c.start, rate),
    gain: Math.min(1, g * dbGain(c.volume) * duck),
  });
  const byId = new Map(clips.map((c) => [c.id, c]));
  for (const t of liveTransitions(doc, trackId)) {
    const a = byId.get(t.from);
    const b = byId.get(t.to);
    if (!a || !b) continue;
    const cut = clipEnd(a);
    const from = cut - Math.min(t.inOffset, clipLength(a));
    const to = cut + Math.min(t.outOffset, clipLength(b));
    if (f < from || f >= to) continue;
    const p = (f - from) / Math.max(1, to - from);
    return [at(a, 1 - p), at(b, p)];
  }
  const c = clips.find((x) => f >= x.start && f < clipEnd(x));
  return c ? [at(c, fadeGain(c, f))] : [];
}

/** The subtitle shown at a frame. */
export const captionAt = (doc: RgVideo, frame: number): VideoCaption | undefined =>
  doc.captions.segments.find((s) => frame >= s.start && frame < s.end && s.text.trim());

/** The last frame anything plays (the timeline's length). */
export const timelineEnd = (doc: RgVideo): number =>
  doc.clips.reduce((m, c) => (c.enabled ? Math.max(m, clipEnd(c)) : m), 0);

/** The next clip of a track to start after a frame (what to load ahead). */
export function nextClip(doc: RgVideo, trackId: string, frame: number): VideoClip | undefined {
  return playing(doc, trackId).find((c) => c.start > frame);
}

/** How compile.ts draws a text (share of the short side, box, shadow), for the HTML copy. */
export const TEXT_LOOK: Record<
  VideoTextRef["style"],
  { size: number; bold: boolean; box: boolean; shadow: boolean }
> = {
  title: { size: 0.085, bold: true, box: false, shadow: true },
  subtitle: { size: 0.055, bold: false, box: false, shadow: true },
  lower_third: { size: 0.05, bold: true, box: true, shadow: false },
  caption: { size: 0.045, bold: false, box: true, shadow: false },
  plain: { size: 0.05, bold: false, box: false, shadow: false },
};

// ---- the elements ---------------------------------------------------------------------------

/** What the player needs of a media element (tests give fakes). */
export interface MediaLike {
  src: string;
  currentTime: number;
  readonly paused: boolean;
  playbackRate: number;
  volume: number;
  muted: boolean;
  preload: string;
  style: { opacity: string; transform: string; clipPath: string; filter: string; zIndex: string };
  play(): Promise<void> | undefined;
  pause(): void;
  load(): void;
  removeAttribute(name: string): void;
}

interface Slot {
  el: MediaLike;
  /** The file loaded (its URL). */
  src: string | null;
  /** The clip it shows now (or is loaded for). */
  clip: string | null;
}

interface TrackEls {
  layer: HTMLElement;
  slots: [Slot, Slot];
  /** Pictures, texts and colours: one box each for the two layers of a transition. */
  imgs: [HTMLImageElement, HTMLImageElement];
  boxes: [HTMLElement, HTMLElement];
  kind: "Video" | "Audio";
}

export interface PlayerOptions {
  stage: HTMLElement;
  audioBox: HTMLElement;
  /** Makes a <video> or <audio> (tests: fakes). */
  media?: (tag: "video" | "audio") => MediaLike & HTMLElement;
  now?: () => number;
  schedule?: (f: () => void) => number;
  cancel?: (id: number) => void;
  onFrame?: (frame: number) => void;
  onEnd?: (frame: number) => void;
}

export class TimelinePlayer {
  doc: RgVideo | null = null;
  media: PlayerMediaMap = {};
  frame = 0;
  playing = false;
  rate = 1;
  private readonly tracks = new Map<string, TrackEls>();
  private caption: HTMLElement | null = null;
  private t0 = 0;
  private f0 = 0;
  private timer: number | null = null;
  private readonly o: Required<Omit<PlayerOptions, "onFrame" | "onEnd">> &
    Pick<PlayerOptions, "onFrame" | "onEnd">;

  constructor(o: PlayerOptions) {
    this.o = {
      media: (tag) => document.createElement(tag) as unknown as MediaLike & HTMLElement,
      now: () => performance.now(),
      schedule: (f) => requestAnimationFrame(f),
      cancel: (id) => cancelAnimationFrame(id),
      ...o,
    };
  }

  get fps(): number {
    return this.doc ? this.doc.format.rate.num / this.doc.format.rate.den : 25;
  }

  setDoc(doc: RgVideo, media: PlayerMediaMap): void {
    this.doc = doc;
    this.media = media;
    this.ensureTracks();
    this.render(this.frame, this.playing);
  }

  seek(frame: number): void {
    this.frame = Math.max(0, Math.round(frame));
    if (this.playing) {
      this.t0 = this.o.now();
      this.f0 = this.frame;
    }
    this.render(this.frame, this.playing);
  }

  play(rate = 1): void {
    if (!this.doc) return;
    if (this.frame >= timelineEnd(this.doc) - 1) this.frame = 0;
    this.rate = rate;
    this.playing = true;
    this.t0 = this.o.now();
    this.f0 = this.frame;
    if (this.timer !== null) this.o.cancel(this.timer);
    this.timer = this.o.schedule(() => this.tick());
  }

  /** One step of the clock (the scheduler calls it; tests too). */
  tick(): void {
    if (!this.playing || !this.doc) return;
    const f = this.f0 + ((this.o.now() - this.t0) / 1000) * this.fps * this.rate;
    const end = timelineEnd(this.doc);
    if (f >= end || f < 0) {
      this.frame = Math.max(0, Math.min(end, Math.round(f)));
      this.pause();
      this.o.onEnd?.(this.frame);
      return;
    }
    this.frame = Math.floor(f);
    this.render(f, this.rate > 0);
    this.o.onFrame?.(this.frame);
    this.timer = this.o.schedule(() => this.tick());
  }

  pause(): void {
    this.playing = false;
    if (this.timer !== null) this.o.cancel(this.timer);
    this.timer = null;
    for (const t of this.tracks.values()) for (const s of t.slots) s.el.pause();
    this.render(this.frame, false);
  }

  destroy(): void {
    this.pause();
    for (const t of this.tracks.values()) {
      for (const s of t.slots) {
        s.el.removeAttribute("src");
        s.el.load();
      }
      t.layer.remove();
    }
    this.tracks.clear();
    this.caption?.remove();
    this.caption = null;
  }

  // ---- elements -------------------------------------------------------------------------

  private ensureTracks(): void {
    const doc = this.doc as RgVideo;
    const ids = new Set(doc.tracks.map((t) => t.id));
    for (const [id, t] of this.tracks) {
      if (!ids.has(id)) {
        for (const s of t.slots) {
          s.el.removeAttribute("src");
          s.el.load();
        }
        t.layer.remove();
        this.tracks.delete(id);
      }
    }
    for (const t of doc.tracks) {
      if (this.tracks.has(t.id)) continue;
      const layer = document.createElement("div");
      layer.className = "vp-layer";
      layer.dataset.track = t.id;
      const tag = t.kind === "Video" ? "video" : "audio";
      const mk = (): Slot => {
        const el = this.o.media(tag);
        el.muted = t.kind === "Video";
        el.preload = "auto";
        if (t.kind === "Video") {
          (el as unknown as HTMLVideoElement).playsInline = true;
          el.className = "vp-video";
        }
        el.style.opacity = "0";
        layer.appendChild(el);
        return { el, src: null, clip: null };
      };
      const img = () => {
        const i = document.createElement("img");
        i.className = "vp-picture";
        i.alt = "";
        i.style.opacity = "0";
        layer.appendChild(i);
        return i;
      };
      const box = () => {
        const b = document.createElement("div");
        b.className = "vp-box";
        b.style.opacity = "0";
        layer.appendChild(b);
        return b;
      };
      const entry: TrackEls = {
        layer,
        slots: [mk(), mk()],
        imgs: t.kind === "Video" ? [img(), img()] : ([] as unknown as TrackEls["imgs"]),
        boxes: t.kind === "Video" ? [box(), box()] : ([] as unknown as TrackEls["boxes"]),
        kind: t.kind,
      };
      (t.kind === "Video" ? this.o.stage : this.o.audioBox).appendChild(layer);
      this.tracks.set(t.id, entry);
    }
    // Layers: V1 at the bottom, V2 over it…; the subtitles over everything.
    doc.tracks
      .filter((t) => t.kind === "Video")
      .forEach((t, i) => {
        const e = this.tracks.get(t.id);
        if (e) e.layer.style.zIndex = String(i + 1);
      });
    if (!this.caption) {
      this.caption = document.createElement("div");
      this.caption.className = "vp-caption";
      this.o.stage.appendChild(this.caption);
    }
    this.caption.style.zIndex = String(doc.tracks.length + 2);
  }

  // ---- sync -----------------------------------------------------------------------------

  render(frame: number, playing: boolean): void {
    const doc = this.doc;
    if (!doc) return;
    for (const t of doc.tracks) {
      const e = this.tracks.get(t.id);
      if (!e) continue;
      if (e.kind === "Video") this.syncVideo(t.id, e, frame, playing);
      else this.syncAudio(t.id, e, frame, playing);
    }
    this.syncCaption(Math.floor(frame));
  }

  /** The slot for a file: the one that has it (the same clip first), else the other free one. */
  private slotFor(e: TrackEls, src: string, clip: string, taken: Set<Slot>): Slot {
    const free = e.slots.filter((s) => !taken.has(s));
    const slot =
      free.find((s) => s.src === src && s.clip === clip) ??
      free.find((s) => s.src === src) ??
      free.find((s) => s.clip === null) ??
      (free.at(-1) as Slot);
    if (slot.src !== src) {
      slot.src = src;
      slot.el.src = src;
      slot.el.load();
    }
    slot.clip = clip;
    return slot;
  }

  private drive(el: MediaLike, time: number, playing: boolean): void {
    if (playing) {
      el.playbackRate = this.rate;
      if (el.paused || Math.abs(el.currentTime - time) > DRIFT) el.currentTime = time;
      if (el.paused) void el.play()?.catch(() => {});
    } else {
      if (!el.paused) el.pause();
      if (Math.abs(el.currentTime - time) > 0.5 / this.fps) el.currentTime = time;
    }
  }

  private idle(s: Slot): void {
    s.el.style.opacity = "0";
    if (!s.el.paused) s.el.pause();
    s.el.volume = 0;
  }

  private syncVideo(id: string, e: TrackEls, frame: number, playing: boolean): void {
    const doc = this.doc as RgVideo;
    const layers = videoLayers(doc, id, frame, this.media);
    const taken = new Set<Slot>();
    let img = 0;
    let box = 0;
    for (const l of layers) {
      const look = (el: { style: CSSStyleDeclaration | MediaLike["style"] }) => {
        el.style.opacity = String(l.opacity);
        el.style.transform = l.transform;
        el.style.clipPath = l.clipPath;
        el.style.filter = l.brightness < 1 ? `brightness(${l.brightness.toFixed(3)})` : "";
        el.style.zIndex = l.top ? "2" : "1";
      };
      if (l.kind === "video" && isMediaRef(l.clip.ref)) {
        const src = playSrc(this.media[l.clip.ref.media]);
        if (!src) continue;
        const slot = this.slotFor(e, src, l.clip.id, taken);
        taken.add(slot);
        (slot.el as unknown as HTMLElement).className =
          `vp-video${l.clip.fit === "fit" ? " fit" : ""}`;
        look(slot.el);
        this.drive(slot.el, l.time, playing);
      } else if (l.kind === "image" && isMediaRef(l.clip.ref)) {
        const m = this.media[l.clip.ref.media];
        const el = e.imgs[img++] as HTMLImageElement;
        const src = m && !m.missing ? (m.file ?? "") : "";
        if (el.dataset.src !== src) {
          el.src = src;
          el.dataset.src = src;
        }
        el.className = `vp-picture${l.clip.fit === "fit" ? " fit" : ""}`;
        look(el);
      } else {
        const el = e.boxes[box++] as HTMLElement;
        look(el);
        if (l.kind === "color" && "color" in l.clip.ref) {
          el.className = "vp-box vp-color";
          el.style.background = l.clip.ref.color;
          el.textContent = "";
        } else if ("text" in l.clip.ref) {
          const ref = l.clip.ref as VideoTextRef;
          const look_ = TEXT_LOOK[ref.style];
          el.className = `vp-box vp-text pos-${ref.position}${look_.box ? " boxed" : ""}${look_.shadow ? " shadow" : ""}${look_.bold ? " bold" : ""}`;
          el.style.background = "";
          el.style.setProperty("--size", String(look_.size));
          setText(el, ref.text);
        }
      }
    }
    for (const s of e.slots) if (!taken.has(s)) this.idle(s);
    for (let i = img; i < 2; i++) (e.imgs[i] as HTMLImageElement).style.opacity = "0";
    for (let i = box; i < 2; i++) (e.boxes[i] as HTMLElement).style.opacity = "0";
    this.preload(id, e, frame, playing, taken);
  }

  private syncAudio(id: string, e: TrackEls, frame: number, playing: boolean): void {
    const doc = this.doc as RgVideo;
    const taken = new Set<Slot>();
    for (const l of audioLayers(doc, id, frame)) {
      if (!isMediaRef(l.clip.ref)) continue;
      const src = playSrc(this.media[l.clip.ref.media]);
      if (!src) continue;
      const slot = this.slotFor(e, src, l.clip.id, taken);
      taken.add(slot);
      slot.el.volume = Math.max(0, Math.min(1, l.gain));
      this.drive(slot.el, l.time, playing);
    }
    for (const s of e.slots) if (!taken.has(s)) this.idle(s);
    this.preload(id, e, frame, playing, taken);
  }

  /** Loads the track's next clip ahead in the free element, at its first frame. */
  private preload(id: string, e: TrackEls, frame: number, playing: boolean, taken: Set<Slot>) {
    if (!playing || !this.doc) return;
    const next = nextClip(this.doc, id, frame);
    if (!next || !isMediaRef(next.ref)) return;
    if ((next.start - frame) / this.fps > PRELOAD) return;
    const m = this.media[next.ref.media];
    if (m?.kind === "image" || next.ref.still) return;
    const src = playSrc(m);
    if (!src) return;
    if ([...taken].some((s) => s.clip === next.id)) return;
    const free = e.slots.find((s) => !taken.has(s));
    if (!free) return;
    if (free.src !== src) {
      free.src = src;
      free.el.src = src;
      free.el.load();
    }
    free.clip = next.id;
    const t = framesToSeconds(next.sourceRange.start, this.doc.format.rate);
    if (Math.abs(free.el.currentTime - t) > DRIFT) free.el.currentTime = t;
  }

  private syncCaption(frame: number): void {
    const el = this.caption;
    const doc = this.doc;
    if (!el || !doc) return;
    const c = captionAt(doc, frame);
    const s = doc.captions;
    el.className = `vp-caption ${s.style} ${s.position}`;
    el.style.opacity = c ? "1" : "0";
    setText(el, c?.text.trim() ?? "");
  }
}

/** A text in a box's inner span (its background is a box behind each line, as drawtext's). */
function setText(el: HTMLElement, text: string): void {
  let span = el.firstElementChild as HTMLElement | null;
  if (span?.tagName !== "SPAN") {
    el.textContent = "";
    span = document.createElement("span");
    el.appendChild(span);
  }
  if (span.textContent !== text) span.textContent = text;
}
