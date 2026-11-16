// Texts of a timeline measured once, for the render and the page alike (G41.5c): the size, the
// lines and the place of a title or a lower third come from the same functions, so what the page
// shows wraps where the render wraps. Subtitles' SRT and WebVTT are here too (the page offers
// them as files). Pure: text in, numbers and text out.

import type { VideoCaption, VideoRate, VideoTextRef } from "./doc-video.js";
import { framesToSeconds } from "./video-timeline.js";

/** How a text style is drawn: its share of the short side, its font, a box or a shadow. */
export const TEXT_LOOK = {
  title: { font: "Inter-Bold.ttf", size: 0.085, bold: true, box: false, shadow: true },
  subtitle: { font: "Inter-Regular.ttf", size: 0.055, bold: false, box: false, shadow: true },
  lower_third: { font: "Inter-Bold.ttf", size: 0.05, bold: true, box: true, shadow: false },
  caption: { font: "Inter-Regular.ttf", size: 0.045, bold: false, box: true, shadow: false },
  plain: { font: "Inter-Regular.ttf", size: 0.05, bold: false, box: false, shadow: false },
} as const satisfies Record<
  VideoTextRef["style"],
  { font: string; size: number; bold: boolean; box: boolean; shadow: boolean }
>;

/** The title-safe margin: every text stays this far (a share of the side) from each edge. */
export const TITLE_SAFE = 0.05;

/**
 * A text's width in pixels at `size`, estimated from Inter's glyphs (measured with ffmpeg's
 * bbox at 100 px: lowercase 0.44-0.58 em, "MMMMWWWW" 0.93, "iiiilll" 0.22, digits 0.58; bold
 * about 5% wider). The classes are rounded up: the estimate is never narrower than the text.
 */
export function textWidth(text: string, size: number, bold = false): number {
  let em = 0;
  for (const ch of text) {
    if (/[iljI.,:;'!|ìíïî`]/.test(ch)) em += 0.3;
    else if (/[\sfrt()[\]/\-"]/.test(ch)) em += 0.4;
    else if (/[mwMW@%]/.test(ch)) em += 0.95;
    else if (/\p{Lu}/u.test(ch)) em += 0.72;
    else if (/[0-9]/.test(ch)) em += 0.62;
    else em += 0.58;
  }
  return em * size * (bold ? 1.05 : 1);
}

/** Words on lines no wider than `room` pixels (a word wider than that stays whole). */
export function wrapToWidth(text: string, room: number, size: number, bold = false): string[] {
  const lines: string[] = [];
  for (const para of text.replace(/\r\n?/g, "\n").split("\n")) {
    let cur = "";
    for (const word of para.split(/\s+/).filter(Boolean)) {
      const next = cur ? `${cur} ${word}` : word;
      if (cur && textWidth(next, size, bold) > room) {
        lines.push(cur);
        cur = word;
      } else cur = next;
    }
    lines.push(cur);
  }
  return lines;
}

export interface FittedText {
  size: number;
  lines: string[];
  /** The box's border around a lower third (0 without a box). */
  border: number;
  /** drawtext's x and y (ffmpeg expressions). */
  x: string;
  y: string;
  align: "C" | "L";
  /**
   * The same place in pixels of the frame, for the page: the first line's top (or the last
   * line's bottom, from the bottom edge, for "bottom"; undefined for "center": centred), and the
   * left edge of the lines (undefined: centred between the safe margins).
   */
  top?: number;
  bottom?: number;
  left?: number;
  /** The safe margins (left and right, top and bottom). */
  mx: number;
  my: number;
}

/**
 * A text placed inside the title-safe area (5% from each side): its size follows the short
 * side (the same title fits 16:9, 9:16 and 1:1), its words go on new lines when a line is too
 * wide, and when a single word or the lines' height still do not fit the size goes down. A
 * lower third's box is inside the area too: it grows to the left edge of the area and wraps,
 * it is never cut.
 */
export function fitText(
  text: string,
  style: VideoTextRef["style"],
  position: VideoTextRef["position"],
  w: number,
  h: number,
): FittedText {
  const look = TEXT_LOOK[style];
  const bold = look.bold;
  const side = Math.min(w, h);
  const border = look.box ? Math.max(2, Math.round(side * 0.015)) : 0;
  const shadow = look.shadow ? Math.max(1, Math.round(side / 360)) : 0;
  const mx = Math.ceil(w * TITLE_SAFE);
  const my = Math.ceil(h * TITLE_SAFE);
  const room = w - 2 * mx - 2 * border - shadow;
  // Lines take 1.25 of the size (line_spacing 0.25); top, bottom and the lower third start
  // lower than the area's edge, so they have less height.
  const top = {
    center: my,
    top: Math.round(h * 0.08),
    bottom: my,
    lower_third: Math.round(h * 0.7),
  }[position];
  const height = position === "lower_third" ? h - my - top : h - 2 * my;
  let size = Math.max(8, Math.round(side * look.size));
  let lines = wrapToWidth(text, room, size, bold);
  const fits = () =>
    Math.max(...lines.map((l) => textWidth(l, size, bold))) <= room &&
    lines.length * size * 1.25 + 2 * border <= Math.max(height, size * 1.25 + 2 * border);
  while (!fits() && size > 8) {
    size = Math.max(8, Math.floor(size * 0.92));
    lines = wrapToWidth(text, room, size, bold);
  }
  const lo = `h-${my}-${border}-text_h`;
  const y = {
    center: "(h-text_h)/2",
    top: `${Math.max(top, my + border)}`,
    bottom: `h-text_h-${Math.round(h * 0.08) + border}`,
    // Moved up when its lines would go past the bottom of the area.
    lower_third: `min(${top}\\,${lo})`,
  }[position];
  // The page's numbers: drawtext's text_h is about the lines' height.
  const textH = Math.round(lines.length * size * 1.25 - size * 0.25);
  const place: Pick<FittedText, "top" | "bottom" | "left"> =
    position === "top"
      ? { top: Math.max(top, my + border) }
      : position === "bottom"
        ? { bottom: Math.round(h * 0.08) + border }
        : position === "lower_third"
          ? { top: Math.min(top, h - my - border - textH), left: mx + border }
          : {};
  return {
    size,
    lines,
    border,
    x: position === "lower_third" ? `${mx + border}` : "(w-text_w)/2",
    y,
    align: position === "lower_third" ? "L" : "C",
    ...place,
    mx,
    my,
  };
}

// -------------------------------------------------------------------------------------------
// Subtitles' files (their words, `captionWords`, are in video-timeline.ts: the ripples use them)

function clock(seconds: number, sep: "," | "."): string {
  const ms = Math.max(0, Math.round(seconds * 1000));
  const p = (n: number, w = 2) => String(n).padStart(w, "0");
  const hh = Math.floor(ms / 3_600_000);
  const m = Math.floor(ms / 60_000) % 60;
  const s = Math.floor(ms / 1000) % 60;
  return `${p(hh)}:${p(m)}:${p(s)}${sep}${p(ms % 1000, 3)}`;
}

type Timed = Pick<VideoCaption, "start" | "end" | "text">;

function ordered<T extends Timed>(captions: readonly T[]): T[] {
  return captions.filter((c) => c.end > c.start && c.text.trim()).sort((a, b) => a.start - b.start);
}

/** A cue's text: trimmed, one line break at most between lines (a blank line ends a cue). */
function cueText(text: string): string {
  return text
    .trim()
    .replace(/\r\n?/g, "\n")
    .replace(/\n{2,}/g, "\n");
}

/** The timeline's captions (frames at `rate`) as SubRip: the render's sidecar and text track. */
export function captionsToSrt(captions: readonly Timed[], rate: VideoRate): string {
  return ordered(captions)
    .map(
      (c, i) =>
        `${i + 1}\n${clock(framesToSeconds(c.start, rate), ",")} --> ${clock(framesToSeconds(c.end, rate), ",")}\n${cueText(c.text)}\n`,
    )
    .join("\n");
}

/**
 * The timeline's captions as WebVTT (the browser's `<track>`, the render's sidecar). The text is
 * escaped (& < >), so a "-->" inside a cue cannot end its timing line.
 */
export function captionsToVtt(captions: readonly Timed[], rate: VideoRate): string {
  const cues = ordered(captions).map((c) => {
    const text = cueText(c.text).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    return `${clock(framesToSeconds(c.start, rate), ".")} --> ${clock(framesToSeconds(c.end, rate), ".")}\n${text}\n`;
  });
  return `WEBVTT\n\n${cues.join("\n")}`;
}
