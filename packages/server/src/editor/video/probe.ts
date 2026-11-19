// ffprobe's answer made into a `MediaProbe` (G41.4), as montatore's probe.py: rotation from the
// display matrix or the old `rotate` tag (sides swapped at 90/270), the frame rate as a fraction,
// pictures told apart from one-frame videos, the camera's timecode and the shooting date. The one
// probe of the video editor: the analysis caches it (analysis.ts) and the render reads what it
// needs of it (`renderProbeOf`, G41.3). `probeFile` runs ffprobe with `runMedia` (no shell).

import { stat } from "node:fs/promises";
import type { MediaProbe, RgVideo, VideoProbe, VideoRate } from "@redgiant/protocol";
import type { RenderProbe } from "./compile.js";
import { type MediaRunner, runMedia } from "./media-run.js";

/** The arguments: JSON with the container and every stream. */
export function probeArgs(file: string): string[] {
  return ["-v", "error", "-print_format", "json", "-show_format", "-show_streams", file];
}

const IMAGE_CODECS = new Set([
  "mjpeg",
  "png",
  "webp",
  "bmp",
  "tiff",
  "gif",
  "heic",
  "hevc_image",
  "jpegxl",
  "avif",
  "jpeg2000",
]);

type Raw = Record<string, unknown>;
const obj = (v: unknown): Raw =>
  v && typeof v === "object" && !Array.isArray(v) ? (v as Raw) : {};
const num = (v: unknown): number | undefined => {
  const n = typeof v === "string" ? Number(v) : v;
  return typeof n === "number" && Number.isFinite(n) ? n : undefined;
};
const str = (v: unknown): string | null => (typeof v === "string" && v.trim() ? v.trim() : null);

function rotationOf(stream: Raw): number {
  for (const side of Array.isArray(stream.side_data_list) ? stream.side_data_list : []) {
    const r = num(obj(side).rotation);
    if (r !== undefined) return (((Math.round(r) % 360) + 360) % 360) as number;
  }
  const tag = num(obj(stream.tags).rotate);
  return tag === undefined ? 0 : ((Math.round(tag) % 360) + 360) % 360;
}

function rateOf(stream: Raw): VideoRate | null {
  for (const key of ["avg_frame_rate", "r_frame_rate"]) {
    const m = /^(\d+)\/(\d+)$/.exec(String(stream[key] ?? ""));
    const n = Number(m?.[1]);
    const d = Number(m?.[2]);
    if (n > 0 && d > 0) {
      const g = (a: number, b: number): number => (b ? g(b, a % b) : a);
      const k = g(n, d);
      return { num: n / k, den: d / k };
    }
  }
  return null;
}

/** ffprobe's JSON (`probeArgs`) as a `MediaProbe`; `size` is the file's bytes. */
export function parseProbe(json: unknown, size = 0): MediaProbe {
  const info = obj(json);
  const streams = (Array.isArray(info.streams) ? info.streams : []).map(obj);
  const fmt = obj(info.format);
  const video = streams.find(
    (s) => s.codec_type === "video" && obj(s.disposition).attached_pic !== 1,
  );
  const audio = streams.find((s) => s.codec_type === "audio");
  if (!video && !audio) throw new Error("the file holds no picture and no sound");
  const formatName = String(fmt.format_name ?? "");
  const frames = num(video?.nb_frames) ?? 0;
  const image =
    !!video &&
    ((IMAGE_CODECS.has(String(video.codec_name)) &&
      (frames <= 1 || formatName.includes("image2") || formatName.endsWith("_pipe"))) ||
      formatName.endsWith("_pipe") ||
      formatName === "image2");
  const rotation = video ? rotationOf(video) : 0;
  let width = Math.max(0, Math.round(num(video?.width) ?? 0));
  let height = Math.max(0, Math.round(num(video?.height) ?? 0));
  if (rotation === 90 || rotation === 270) [width, height] = [height, width];
  const duration = num(fmt.duration) ?? num(video?.duration) ?? num(audio?.duration);
  const tags = { ...obj(audio?.tags), ...obj(video?.tags), ...obj(fmt.tags) };
  const kind = image ? "image" : video ? "video" : "audio";
  return {
    kind,
    duration: image ? null : duration !== undefined && duration > 0 ? duration : 0,
    width,
    height,
    rotation,
    rate: kind === "video" && video ? rateOf(video) : null,
    codec: str(video?.codec_name),
    audio: !!audio && !image,
    audioCodec: image ? null : str(audio?.codec_name),
    sampleRate: image ? null : (num(audio?.sample_rate) ?? null),
    channels: image ? null : (num(audio?.channels) ?? null),
    timecode: str(obj(video?.tags).timecode) ?? str(obj(fmt.tags).timecode) ?? str(tags.timecode),
    createdAt: str(tags.creation_time),
    size: Math.max(0, Math.round(size)),
  };
}

/** What `cleanTimeline` needs of a file: its length in frames at the timeline's rate. */
export function videoProbeOf(p: MediaProbe, rate: VideoRate): VideoProbe {
  if (p.kind === "image") return { frames: null };
  const frames = Math.max(1, Math.floor(((p.duration ?? 0) * rate.num) / rate.den + 1e-6));
  return { frames, audio: p.audio };
}

/** The probes of a timeline's files, by their path in the project (for `cleanTimeline`). */
export function timelineProbes(
  doc: Pick<RgVideo, "format">,
  probes: Record<string, MediaProbe>,
): Record<string, VideoProbe> {
  const out: Record<string, VideoProbe> = {};
  for (const [path, p] of Object.entries(probes)) out[path] = videoProbeOf(p, doc.format.rate);
  return out;
}

/** What the render needs of a file (`compileVideo`): its length, its sound and a fingerprint. */
export function renderProbeOf(p: MediaProbe, rate: VideoRate, fingerprint?: string): RenderProbe {
  return { ...videoProbeOf(p, rate), audio: p.audio, ...(fingerprint && { fingerprint }) };
}

/** ffprobe answered, but not about a picture or a sound. */
export class UnreadableMedia extends Error {}

/**
 * Runs ffprobe on a file and reads it. A program that fails rejects with its `MediaRunError`, an
 * answer that is not a picture or a sound with `UnreadableMedia`, a cancel with an `AbortError`.
 */
export async function probeFile(
  ffprobe: string,
  file: string,
  o: { run?: MediaRunner; signal?: AbortSignal } = {},
): Promise<MediaProbe> {
  const { size } = await stat(file);
  const r = await (o.run ?? runMedia)(ffprobe, probeArgs(file), {
    stdout: true,
    ...(o.signal && { signal: o.signal }),
  });
  try {
    return parseProbe(JSON.parse(r.stdout), size);
  } catch (e) {
    throw new UnreadableMedia((e as Error).message);
  }
}
