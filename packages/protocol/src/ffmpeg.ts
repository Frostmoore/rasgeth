/**
 * ffmpeg as RedGiant needs it (G41.1): what a build can do, read from its own words
 * (`ffmpeg -hide_banner -filters`, `-encoders`, `-version`), and which H.264 encoder to use.
 * Pure functions, shared by the server and (G41.7) the nodes that report their ffmpeg.
 */
import { z } from "zod";

/** The filters the video editor's render uses (G41.3): a PATH ffmpeg without them is not used. */
export const FFMPEG_FILTERS_WANTED = [
  "xfade",
  "zoompan",
  "drawtext",
  "subtitles",
  "sidechaincompress",
  "loudnorm",
] as const;

/** The H.264 encoders RedGiant picks from (NVIDIA's first, when it really works). */
export const FFMPEG_ENCODERS_WANTED = ["h264_nvenc", "libx264"] as const;
export type H264Encoder = (typeof FFMPEG_ENCODERS_WANTED)[number];

/** The oldest major version used when it is already on the computer. */
export const FFMPEG_MIN_MAJOR = 7;

/** What a computer's ffmpeg is (a node reports it in G41.7). */
export const FfmpegInfo = z.object({
  /** As ffmpeg says it ("n9.0.2-39-g7adfbe40dc-20261031", "7.1.1-1+b1"). */
  version: z.string(),
  major: z.number().int().nullable(),
  /** Where it comes from: REDGIANT_FFMPEG, RedGiant's own download, or the PATH. */
  source: z.enum(["env", "ours", "path"]),
  ffprobe: z.boolean(),
  /** Wanted filters it lacks (empty for RedGiant's own builds). */
  missing: z.array(z.string()),
  /** Wanted encoders it has. */
  encoders: z.array(z.enum(FFMPEG_ENCODERS_WANTED)),
});
export type FfmpegInfo = z.infer<typeof FfmpegInfo>;

export interface FfmpegFeatures {
  filters: Set<string>;
  encoders: Set<string>;
}

/**
 * The filters and encoders a build lists. Filter lines are ` TS xfade  VV->V  Cross fade…` (two
 * flag columns in 9.0, three before); encoder lines ` V....D libx264  libx264 H.264…`. The legend
 * above the `------` line is skipped.
 */
export function ffmpegFeatures(filtersText: string, encodersText = ""): FfmpegFeatures {
  const filters = new Set<string>();
  for (const line of filtersText.split(/\r?\n/)) {
    const m = /^\s?([A-Z.|]{2,3})\s+([A-Za-z0-9_]+)\s+([AVN|]*->[AVN|]*)\s/.exec(line);
    if (m?.[2]) filters.add(m[2]);
  }
  const encoders = new Set<string>();
  for (const line of encodersText.split(/\r?\n/)) {
    const m = /^\s?([VASD][A-Z.]{5})\s+([A-Za-z0-9_-]+)\s/.exec(line);
    if (m?.[2] && m[2] !== "=") encoders.add(m[2]);
  }
  return { filters, encoders };
}

/** The version from `ffmpeg -version`'s first line, and its major number when it has one. */
export function ffmpegVersion(text: string): { version: string; major: number | null } {
  const m = /ffmpeg version (\S+)/.exec(text);
  const version = m?.[1] ?? "";
  // Releases: "9.0.2", "n9.0.2-39-g…" (BtbN), "7.1.1-1+b1" (Debian). Git builds ("N-128910-g…")
  // carry no number: unknown.
  const n = /^n?(\d+)\.\d+/.exec(version);
  return { version, major: n?.[1] ? Number(n[1]) : null };
}

/** Whether an ffmpeg already on the computer is good enough, and if not why. */
export function ffmpegUsable(
  versionText: string,
  features: FfmpegFeatures,
): { ok: true } | { ok: false; why: string } {
  const { version, major } = ffmpegVersion(versionText);
  if (major === null) return { ok: false, why: `unknown version ${version || "(none)"}` };
  if (major < FFMPEG_MIN_MAJOR)
    return { ok: false, why: `version ${version} is older than ${FFMPEG_MIN_MAJOR}` };
  const missing = FFMPEG_FILTERS_WANTED.filter((f) => !features.filters.has(f));
  if (missing.length) return { ok: false, why: `no ${missing.join(", ")}` };
  return { ok: true };
}

/**
 * The H.264 encoder for a render: NVENC only when the build has it, the computer has an NVIDIA
 * GPU and a one-frame try worked (`nvencWorks`); otherwise libx264; none when the build has
 * neither (an LGPL build).
 */
export function pickEncoder(
  features: FfmpegFeatures,
  gpus: readonly { vendor: string }[],
  nvencWorks: boolean,
): H264Encoder | undefined {
  if (features.encoders.has("h264_nvenc") && gpus.some((g) => g.vendor === "nvidia") && nvencWorks)
    return "h264_nvenc";
  return features.encoders.has("libx264") ? "libx264" : undefined;
}
