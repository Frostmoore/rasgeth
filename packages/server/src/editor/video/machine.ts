// This machine's ffmpeg for renders (G41.7): which one it has (or that it can download the pinned
// build of G41.1), its graphics cards, whether NVENC really encodes here (`nvencWorks`: one frame
// tried, a build listing it is not enough) and so the encoder a render uses (`pickEncoder`). The
// same answer serves a render here and a node's capabilities; it is measured once per ffmpeg
// (a new download or a different one on the PATH measures again).
//
// On Windows an ffmpeg installed with WinGet is used as it is: `locateFfmpeg` resolves its
// shortcut to the real program (the shortcut does not start from another program).

import {
  type FfmpegInfo,
  type H264Encoder,
  type NodeGpu,
  type NodeMedia,
  pickEncoder,
} from "@redgiant/protocol";
import {
  downloadFfmpeg,
  type FfmpegProgress,
  type FoundFfmpeg,
  ffmpegBuild,
  ffmpegInfo,
  locateFfmpeg,
  nvencWorks,
} from "../../ffmpeg.js";
import { detectHardware } from "../../hardware.js";

/** ffmpeg and ffprobe ready to run. */
export interface ReadyFfmpeg {
  ffmpeg: string;
  ffprobe: string;
}

/** What renders need of a machine (tests give a fixed one: `fixedMachine`). */
export interface MediaMachineLike {
  gpus(): Promise<NodeGpu[]>;
  media(): Promise<NodeMedia>;
  /** The encoder a render uses here (libx264 when nothing better is known). */
  encoder(): Promise<H264Encoder>;
  /** ffmpeg and ffprobe, downloaded with this progress when missing. */
  ensure(p: FfmpegProgress): Promise<ReadyFfmpeg>;
  /** The ffmpeg already here, without downloading. */
  found(): ReadyFfmpeg | undefined;
}

export interface MediaMachineOptions {
  dataDir: string;
  /** Tests and other systems: the cards, the ffmpeg found, its answers. */
  gpus?: () => Promise<NodeGpu[]>;
  locate?: () => FoundFfmpeg | undefined;
  info?: (found: FoundFfmpeg) => Promise<FfmpegInfo>;
  nvenc?: (ffmpeg: string) => Promise<boolean>;
  download?: (p: FfmpegProgress) => Promise<ReadyFfmpeg>;
  canDownload?: boolean;
}

export class MediaMachine implements MediaMachineLike {
  private cards: Promise<NodeGpu[]> | undefined;
  private measured: { key: string; value: Promise<NodeMedia> } | undefined;
  private downloading: Promise<ReadyFfmpeg> | undefined;

  constructor(private readonly o: MediaMachineOptions) {}

  gpus(): Promise<NodeGpu[]> {
    this.cards ??= (
      this.o.gpus ?? (async () => (await detectHardware({ dataDir: this.o.dataDir })).gpus)
    )().catch(() => []);
    return this.cards;
  }

  found(): ReadyFfmpeg | undefined {
    const f = this.locate();
    return f?.ffprobe ? { ffmpeg: f.ffmpeg, ffprobe: f.ffprobe } : undefined;
  }

  media(): Promise<NodeMedia> {
    const f = this.locate();
    const download = this.o.canDownload ?? ffmpegBuild() !== undefined;
    const key = f ? `${f.ffmpeg}\n${f.ffprobe ?? ""}` : "";
    if (this.measured?.key === key) return this.measured.value;
    const value = (async (): Promise<NodeMedia> => {
      if (!f) return { download, nvenc: false };
      const info = await (this.o.info ?? ffmpegInfo)(f);
      const gpus = await this.gpus();
      const listed = info.encoders.includes("h264_nvenc");
      const nvidia = gpus.some((g) => g.vendor === "nvidia");
      const nvenc =
        listed && nvidia && (await (this.o.nvenc ?? nvencWorks)(f.ffmpeg).catch(() => false));
      const encoder = pickEncoder(
        { filters: new Set(), encoders: new Set(info.encoders) },
        gpus,
        nvenc,
      );
      return { ffmpeg: info, download, nvenc, ...(encoder && { encoder }) };
    })().catch((): NodeMedia => ({ download, nvenc: false }));
    this.measured = { key, value };
    return value;
  }

  async encoder(): Promise<H264Encoder> {
    return (await this.media()).encoder ?? "libx264";
  }

  async ensure(p: FfmpegProgress): Promise<ReadyFfmpeg> {
    const here = this.found();
    if (here) return here;
    this.downloading ??= (
      this.o.download ?? ((q: FfmpegProgress) => downloadFfmpeg(this.o.dataDir, q))
    )(p).finally(() => {
      this.downloading = undefined;
    });
    const got = await this.downloading;
    // Measured again with the new one.
    this.measured = undefined;
    return got;
  }

  private locate(): FoundFfmpeg | undefined {
    return (this.o.locate ?? (() => locateFfmpeg(this.o.dataDir)))();
  }
}

/** A machine whose answers are fixed (tests, and a server whose ffmpeg is a fake). */
export function fixedMachine(
  ready: ReadyFfmpeg | undefined,
  media: NodeMedia,
  gpus: NodeGpu[] = [],
  download?: (p: FfmpegProgress) => Promise<ReadyFfmpeg>,
): MediaMachineLike {
  let have = ready;
  return {
    gpus: async () => gpus,
    media: async () => media,
    encoder: async () => media.encoder ?? "libx264",
    found: () => have,
    ensure: async (p) => {
      if (have) return have;
      if (!download) throw new Error("There is no ffmpeg here and none to download");
      have = await download(p);
      return have;
    },
  };
}
