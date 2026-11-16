// The files derived from a clip for the page (G41.4, used by G41.5a): a light H.264 proxy the
// browser plays, a strip of frames for trimming and a waveform for the timeline. montatore's
// parameters (media.py): proxy CRF 28 inside a 960 box with a keyframe every 10 frames (seeking
// while dragging finds its frame at once), AAC 96k stereo, `+faststart`; strip of 160×90 tiles,
// one a second up to 120, read from the proxy; waveform 40 px a second (200 to 8000 px), 64 high.
// The waveform is drawn white on transparent, so the page can tint it for its theme (CSS mask).

import { PROGRESS_ARGS } from "./media-run.js";

export const PROXY_BOX = 960;
export const PROXY_CRF = 28;
export const PROXY_GOP = 10;
export const FILMSTRIP_TILE = { w: 160, h: 90 } as const;
export const FILMSTRIP_MAX = 120;
export const WAVEFORM_PX_PER_SEC = 40;
export const WAVEFORM_HEIGHT = 64;

/** Never larger, inside a box, even sides (H.264 wants them). */
export function boxFilter(size: number): string {
  return `scale=w='min(${size},iw)':h='min(${size},ih)':force_original_aspect_ratio=decrease:force_divisible_by=2`;
}

/** The proxy: first video stream (rotation applied by ffmpeg), first audio stream if any. */
export function proxyArgs(src: string, dst: string, audio: boolean): string[] {
  return [
    ...PROGRESS_ARGS,
    "-loglevel",
    "error",
    "-y",
    "-i",
    src,
    "-map",
    "0:v:0",
    "-vf",
    boxFilter(PROXY_BOX),
    "-c:v",
    "libx264",
    "-preset",
    "veryfast",
    "-crf",
    String(PROXY_CRF),
    "-pix_fmt",
    "yuv420p",
    "-g",
    String(PROXY_GOP),
    ...(audio ? ["-map", "0:a:0", "-c:a", "aac", "-b:a", "96k", "-ac", "2"] : []),
    "-movflags",
    "+faststart",
    "-f",
    "mp4",
    dst,
  ];
}

/** How many tiles a strip of a clip this long has. */
export function filmstripTiles(duration: number): number {
  return Math.max(1, Math.min(FILMSTRIP_MAX, Math.floor(duration) || 1));
}

/** One JPEG with the tiles side by side, taken at even steps. */
export function filmstripArgs(src: string, dst: string, duration: number): string[] {
  const { w, h } = FILMSTRIP_TILE;
  const tiles = filmstripTiles(duration);
  return [
    ...PROGRESS_ARGS,
    "-loglevel",
    "error",
    "-y",
    "-i",
    src,
    "-an",
    "-vf",
    `fps=${tiles}/${Math.max(duration, 0.1).toFixed(3)},scale=${w}:${h}:force_original_aspect_ratio=increase,crop=${w}:${h},tile=${tiles}x1`,
    "-frames:v",
    "1",
    "-c:v",
    "mjpeg",
    "-q:v",
    "5",
    "-f",
    "image2",
    dst,
  ];
}

export function waveformWidth(duration: number): number {
  return Math.max(200, Math.min(8000, Math.round(duration * WAVEFORM_PX_PER_SEC)));
}

/** A PNG of the sound (mono, square-root scale as montatore), white on transparent. */
export function waveformArgs(src: string, dst: string, duration: number): string[] {
  return [
    ...PROGRESS_ARGS,
    "-loglevel",
    "error",
    "-y",
    "-i",
    src,
    "-vn",
    "-filter_complex",
    `[0:a:0]aformat=channel_layouts=mono,showwavespic=s=${waveformWidth(duration)}x${WAVEFORM_HEIGHT}:colors=#ffffff:scale=sqrt`,
    "-frames:v",
    "1",
    // Named: the temporary file's name does not tell image2 the format.
    "-c:v",
    "png",
    "-f",
    "image2",
    dst,
  ];
}

/** The sound as 16 kHz mono 16-bit samples (raw), what whisper.cpp and the cloud services read. */
export function pcmArgs(src: string, dst: string): string[] {
  return [
    ...PROGRESS_ARGS,
    "-loglevel",
    "error",
    "-y",
    "-i",
    src,
    "-map",
    "0:a:0",
    "-vn",
    "-ac",
    "1",
    "-ar",
    "16000",
    "-f",
    "s16le",
    "-c:a",
    "pcm_s16le",
    dst,
  ];
}
