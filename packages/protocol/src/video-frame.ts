// How a picture sits in the frame (G41.5d, A1): a horizontal shot reframed for 9:16 or 1:1 with a
// crop the person moves, filled or fitted, on black, on nothing or on a blurred copy of itself.
// The render does it with ffmpeg's crop, scale and pad (compile.ts `picture`); the page does the
// same geometry in CSS (`framePicture`), so what the preview shows is what the render makes.
// Pure functions, tested as a table.
import type { VideoClip, VideoRect } from "./doc-video.js";

export interface FrameSize {
  w: number;
  h: number;
}

/** Four decimals, as the render writes them; never past the picture's edge. */
const q = (n: number) => Math.round(n * 10_000) / 10_000;
const clamp = (n: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, n));

/** The crop as the render reads it: its width and height never past the right and bottom edges. */
export function cropOf(r: VideoRect): VideoRect {
  return { x: r.x, y: r.y, w: q(Math.min(r.w, 1 - r.x)), h: q(Math.min(r.h, 1 - r.y)) };
}

/** Do the source and the frame have different shapes (more than 1%)? Then a crop is worth moving. */
export function needsReframe(src: FrameSize, out: FrameSize): boolean {
  if (!(src.w > 0 && src.h > 0 && out.w > 0 && out.h > 0)) return false;
  return Math.abs(src.w / src.h / (out.w / out.h) - 1) > 0.01;
}

/**
 * The biggest crop of the source with the frame's shape, its centre at (cx, cy) of the source
 * (0..1) as far as the edges allow: a horizontal shot in 9:16 keeps its full height and a third
 * of its width, which the person then moves.
 */
export function reframeCrop(src: FrameSize, out: FrameSize, cx = 0.5, cy = 0.5): VideoRect {
  const s = src.w / src.h;
  const r = out.w / out.h;
  const w = s > r ? q(r / s) : 1;
  const h = s > r ? 1 : q(s / r);
  return {
    x: q(clamp(cx - w / 2, 0, 1 - w)),
    y: q(clamp(cy - h / 2, 0, 1 - h)),
    w,
    h,
  };
}

/** The crop moved by (dx, dy) of the source, kept inside it. */
export function moveCrop(r: VideoRect, dx: number, dy: number): VideoRect {
  const c = cropOf(r);
  return {
    x: q(clamp(c.x + dx, 0, 1 - c.w)),
    y: q(clamp(c.y + dy, 0, 1 - c.h)),
    w: c.w,
    h: c.h,
  };
}

/** Is the crop the whole picture (nothing to keep)? */
export const wholeCrop = (r: VideoRect | undefined): boolean =>
  !r || (r.x <= 0 && r.y <= 0 && r.w >= 1 && r.h >= 1);

/**
 * Where the whole source sits over the frame (fractions of the frame's width and height: it may
 * spill past it, the frame cuts what is outside) and, with a crop, the part of the source kept
 * (`clip`: insets as fractions of the source, for CSS `clip-path: inset(…)`). As compile.ts: the
 * crop first, then filled (scaled to cover, centred) or fitted (scaled to fit inside, centred).
 */
export function framePicture(
  src: FrameSize,
  out: FrameSize,
  fit: VideoClip["fit"],
  crop?: VideoRect,
): {
  left: number;
  top: number;
  width: number;
  height: number;
  clip?: { top: number; right: number; bottom: number; left: number };
} {
  const c = crop && !wholeCrop(crop) ? cropOf(crop) : { x: 0, y: 0, w: 1, h: 1 };
  const cw = Math.max(1e-6, c.w * src.w);
  const ch = Math.max(1e-6, c.h * src.h);
  const k = fit === "fit" ? Math.min(out.w / cw, out.h / ch) : Math.max(out.w / cw, out.h / ch);
  const width = (src.w * k) / out.w;
  const height = (src.h * k) / out.h;
  // The crop's centre lands on the frame's centre.
  const left = 0.5 - (c.x + c.w / 2) * width;
  const top = 0.5 - (c.y + c.h / 2) * height;
  const r = (n: number) => Math.round(n * 1_000_000) / 1_000_000;
  const box = { left: r(left), top: r(top), width: r(width), height: r(height) };
  if (c.w >= 1 && c.h >= 1) return box;
  return {
    ...box,
    clip: {
      top: r(c.y),
      right: r(Math.max(0, 1 - c.x - c.w)),
      bottom: r(Math.max(0, 1 - c.y - c.h)),
      left: r(c.x),
    },
  };
}
