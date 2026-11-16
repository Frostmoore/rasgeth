// Subtitles for a render (G41.3): an ASS file for libass when they are burnt into the picture
// (one per segment, its times from the segment's start), an SRT for the MP4's text track
// (mov_text) and the SRT and WebVTT files saved beside the video. Pure: text in, text out.
// G41.4 splits the transcript into lines (`captionLines`); here every subtitle is written as
// it is, wrapped by libass when it is too long for the picture.
import {
  framesToSeconds,
  type VideoCaption,
  type VideoCaptionSettings,
  type VideoRate,
} from "@redgiant/protocol";

const two = (n: number) => String(n).padStart(2, "0");
const three = (n: number) => String(n).padStart(3, "0");

/** HH:MM:SS,mmm (SRT) or HH:MM:SS.mmm (WebVTT). */
function clock(seconds: number, sep: "," | "."): string {
  const ms = Math.max(0, Math.round(seconds * 1000));
  const h = Math.floor(ms / 3_600_000);
  const m = Math.floor(ms / 60_000) % 60;
  const s = Math.floor(ms / 1000) % 60;
  return `${two(h)}:${two(m)}:${two(s)}${sep}${three(ms % 1000)}`;
}

/** H:MM:SS.cc, ASS's own clock (hundredths). */
function assClock(seconds: number): string {
  const cs = Math.max(0, Math.round(seconds * 100));
  const h = Math.floor(cs / 360_000);
  const m = Math.floor(cs / 6000) % 60;
  const s = Math.floor(cs / 100) % 60;
  return `${h}:${two(m)}:${two(s)}.${two(cs % 100)}`;
}

const sorted = (caps: readonly VideoCaption[]) =>
  caps.filter((c) => c.end > c.start && c.text.trim()).sort((a, b) => a.start - b.start);

/** The subtitles as SRT, times in the timeline. */
export function captionsSrt(caps: readonly VideoCaption[], rate: VideoRate): string {
  return sorted(caps)
    .map(
      (c, i) =>
        `${i + 1}\n${clock(framesToSeconds(c.start, rate), ",")} --> ${clock(framesToSeconds(c.end, rate), ",")}\n${c.text
          .trim()
          .replace(/\r\n?/g, "\n")
          .replace(/\n{2,}/g, "\n")}\n`,
    )
    .join("\n");
}

/** The subtitles as WebVTT (the cue text escaped: & < > and no "-->"). */
export function captionsVtt(caps: readonly VideoCaption[], rate: VideoRate): string {
  const cues = sorted(caps).map((c) => {
    const text = c.text
      .trim()
      .replace(/\r\n?/g, "\n")
      .replace(/\n{2,}/g, "\n")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
    return `${clock(framesToSeconds(c.start, rate), ".")} --> ${clock(framesToSeconds(c.end, rate), ".")}\n${text}\n`;
  });
  return `WEBVTT\n\n${cues.join("\n")}`;
}

/** Text as ASS shows it literally: braces would start an override, a new line is \N. */
function assText(text: string): string {
  return text
    .trim()
    .replace(/\r\n?/g, "\n")
    .replace(/\\/g, "\\​")
    .replace(/\{/g, "(")
    .replace(/\}/g, ")")
    .replace(/\n+/g, "\\N");
}

/** The font libass uses: the family of the server's `Inter-*.ttf` (fontsdir). */
export const SUBTITLE_FONT = "Inter";

/**
 * The ASS file libass burns into one segment: the subtitles that show between `from` and `to`
 * (timeline frames), their times from `from`. Sizes follow the output's height; "boxed" is a
 * box behind the text (BorderStyle 3: libass draws it in the outline colour), "bold" a thick
 * outline, "plain" a thin one.
 */
export function captionsAss(
  caps: readonly VideoCaption[],
  settings: Pick<VideoCaptionSettings, "style" | "position">,
  rate: VideoRate,
  size: { width: number; height: number },
  from: number,
  to: number,
): string | undefined {
  const shown = sorted(caps).filter((c) => c.end > from && c.start < to);
  if (!shown.length) return undefined;
  const { width: w, height: h } = size;
  const side = Math.min(w, h);
  const fontSize = Math.max(8, Math.round(side * 0.055));
  const marginV = Math.round(h * 0.06);
  const marginLR = Math.round(w * 0.08);
  const align = settings.position === "top" ? 8 : 2;
  const box = settings.style === "boxed";
  const bold = settings.style === "bold" ? -1 : 0;
  const border = box ? 3 : 1;
  const outline = box ? Math.max(2, Math.round(side * 0.012)) : settings.style === "bold" ? 3 : 2;
  const shadow = settings.style === "bold" ? 1 : 0;
  const outlineColour = box ? "&H60000000" : "&H00000000";
  const lines = [
    "[Script Info]",
    "ScriptType: v4.00+",
    `PlayResX: ${w}`,
    `PlayResY: ${h}`,
    "WrapStyle: 0",
    "ScaledBorderAndShadow: yes",
    "",
    "[V4+ Styles]",
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
    `Style: Default,${SUBTITLE_FONT},${fontSize},&H00FFFFFF,&H00FFFFFF,${outlineColour},&H60000000,${bold},0,0,0,100,100,0,0,${border},${outline},${shadow},${align},${marginLR},${marginLR},${marginV},1`,
    "",
    "[Events]",
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text",
  ];
  for (const c of shown) {
    const start = framesToSeconds(Math.max(0, c.start - from), rate);
    const end = framesToSeconds(Math.min(to, c.end) - from, rate);
    lines.push(
      `Dialogue: 0,${assClock(start)},${assClock(end)},Default,,0,0,0,,${assText(c.text)}`,
    );
  }
  return `${lines.join("\n")}\n`;
}

/** ISO 639-2 for the MP4's text track (BCP 47 "it" → "ita"); "und" when not known. */
export function subtitleLanguage(bcp47: string): string {
  const base = bcp47.toLowerCase().split(/[-_]/)[0] ?? "";
  const table: Record<string, string> = {
    it: "ita",
    en: "eng",
    fr: "fra",
    de: "deu",
    es: "spa",
    pt: "por",
    nl: "nld",
    ru: "rus",
    zh: "zho",
    ja: "jpn",
    ko: "kor",
    ar: "ara",
    pl: "pol",
    sv: "swe",
    tr: "tur",
    el: "ell",
    ro: "ron",
    uk: "ukr",
  };
  return table[base] ?? "und";
}
