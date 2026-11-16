// What a render needs to know of a file (G41.3): its length at the timeline's rate (`ref.frames`,
// for the handles of transitions and `cleanTimeline`), whether it is a picture, whether it has
// sound, and a fingerprint for the segments' cache. ffprobe's JSON is read by a pure function;
// `probeMedia` runs ffprobe with execFile (the path may come from a person or an agent).
// G41.4 has a fuller probe (`probe.ts`: rotation, timecode, `videoProbeOf`): at the merge this one
// can become `videoProbeOf(parseProbe(...))` plus the fingerprint.
import { execFile } from "node:child_process";
import { stat } from "node:fs/promises";
import type { VideoRate } from "@redgiant/protocol";
import type { RenderProbe } from "./compile.js";

export interface RenderMediaProbe extends RenderProbe {
  width?: number;
  height?: number;
  /** Seconds, as ffprobe says (absent for a picture). */
  seconds?: number;
}

interface ProbeStream {
  codec_type?: string;
  codec_name?: string;
  width?: number;
  height?: number;
  duration?: string;
  disposition?: { attached_pic?: number };
}

/** The arguments `probeFromJson` reads. */
export const PROBE_ARGS = [
  "-v",
  "error",
  "-show_entries",
  "format=format_name,duration:stream=codec_type,codec_name,width,height,duration:stream_disposition=attached_pic",
  "-of",
  "json",
];

const IMAGE_CODECS = new Set(["mjpeg", "png", "webp", "bmp", "tiff", "jpegxl", "jpeg2000", "qoi"]);

/** ffprobe's JSON made into what the timeline uses; `frames` null = a picture (no length). */
export function probeFromJson(json: unknown, rate: VideoRate, fingerprint?: string): RenderMediaProbe {
  const j = (json && typeof json === "object" ? json : {}) as {
    streams?: ProbeStream[];
    format?: { format_name?: string; duration?: string };
  };
  const streams = Array.isArray(j.streams) ? j.streams : [];
  const video = streams.find((s) => s.codec_type === "video" && !s.disposition?.attached_pic);
  const audio = streams.some((s) => s.codec_type === "audio");
  const fmt = j.format?.format_name ?? "";
  const fp = fingerprint ? { fingerprint } : {};
  const size = video?.width && video.height ? { width: video.width, height: video.height } : {};
  const still =
    !!video &&
    !audio &&
    (/^image2$|_pipe$/.test(fmt) || IMAGE_CODECS.has(video.codec_name ?? "")) &&
    !(Number(video.duration ?? j.format?.duration) > 0.5);
  if (still) return { frames: null, audio: false, ...size, ...fp };
  const secs = Number(video?.duration ?? j.format?.duration ?? Number.NaN);
  const seconds = Number.isFinite(secs) && secs > 0 ? secs : undefined;
  const frames =
    seconds === undefined
      ? undefined
      : Math.max(1, Math.floor((seconds * rate.num) / rate.den + 1e-6));
  return {
    ...(frames !== undefined && { frames }),
    audio,
    ...size,
    ...(seconds !== undefined && { seconds }),
    ...fp,
  };
}

/** Runs ffprobe on a file (no shell) and reads it; the fingerprint is its size and time. */
export async function probeMedia(
  ffprobe: string,
  file: string,
  rate: VideoRate,
): Promise<RenderMediaProbe> {
  const st = await stat(file);
  const out = await new Promise<string>((resolve, reject) =>
    execFile(
      ffprobe,
      [...PROBE_ARGS, file],
      { maxBuffer: 4 * 1024 * 1024, windowsHide: true },
      (err, stdout, stderr) =>
        err
          ? reject(new Error(`ffprobe could not read ${file}: ${stderr || err.message}`))
          : resolve(stdout),
    ),
  );
  return probeFromJson(JSON.parse(out), rate, `${st.size}:${Math.round(st.mtimeMs)}`);
}
