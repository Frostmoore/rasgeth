// A device's H.264 (scrcpy) turned into JPEG frames for the page and the app (3.11, phase 2), the
// same `ScreenFrame` the agents' browser sends. ffmpeg decodes with the least delay it can and
// writes every frame; we keep at most one every `minGapMs` (~15 a second) and always the last one,
// so a still screen ends on its true picture. A new configuration (the screen turned, a new size)
// starts a new ffmpeg: one decoder never sees two sizes.
import { type ChildProcess, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";
import type { DeviceFrame } from "./host.js";

/** scrcpy's server, carried by Rasgeth and checked by its hash before every use (Apache-2.0). */
export const SCRCPY_VERSION = "3.3.3";
export const SCRCPY_SHA256 = "7e70323ba7f259649dd4acce97ac4fefbae8102b2c6d91e2e7be613fd5354be0";
export const SCRCPY_JAR = fileURLToPath(
  new URL(`../../vendor/scrcpy/scrcpy-server-v${SCRCPY_VERSION}`, import.meta.url),
);

/** The jar's bytes, refused when they are not the pinned build. */
export async function scrcpyJar(path = SCRCPY_JAR): Promise<Uint8Array> {
  const bytes = await readFile(path);
  const sum = createHash("sha256").update(bytes).digest("hex");
  if (sum !== SCRCPY_SHA256)
    throw new Error(`scrcpy-server ${SCRCPY_VERSION} does not match its pinned SHA-256`);
  return new Uint8Array(bytes);
}

/** Whole JPEGs out of a byte stream (SOI ... EOI); the rest is kept for the next call. */
export class JpegSplitter {
  private buf: Buffer = Buffer.alloc(0);

  push(chunk: Buffer): Buffer[] {
    this.buf = this.buf.length ? Buffer.concat([this.buf, chunk]) : chunk;
    const out: Buffer[] = [];
    for (;;) {
      const start = this.buf.indexOf(SOI);
      if (start < 0) {
        this.buf = Buffer.alloc(0);
        break;
      }
      const end = this.buf.indexOf(EOI, start + 2);
      if (end < 0) {
        if (start > 0) this.buf = this.buf.subarray(start);
        break;
      }
      out.push(Buffer.from(this.buf.subarray(start, end + 2)));
      this.buf = this.buf.subarray(end + 2);
    }
    return out;
  }
}
const SOI = Buffer.from([0xff, 0xd8]);
const EOI = Buffer.from([0xff, 0xd9]);

/** At most one frame per `gapMs`, and the last one always (after the gap). */
export class FrameGate {
  private last = Number.NEGATIVE_INFINITY;
  private pending: DeviceFrame | undefined;
  private timer: NodeJS.Timeout | undefined;

  constructor(
    private readonly send: (f: DeviceFrame) => void,
    private readonly gapMs = 66,
    private readonly now: () => number = Date.now,
  ) {}

  push(f: DeviceFrame): void {
    const t = this.now();
    if (t - this.last >= this.gapMs && !this.timer) {
      this.last = t;
      this.send(f);
      return;
    }
    this.pending = f;
    this.timer ??= setTimeout(
      () => {
        this.timer = undefined;
        const p = this.pending;
        this.pending = undefined;
        if (p) {
          this.last = this.now();
          this.send(p);
        }
      },
      Math.max(0, this.gapMs - (t - this.last)),
    );
  }

  close(): void {
    if (this.timer) clearTimeout(this.timer);
    this.timer = undefined;
    this.pending = undefined;
  }
}

/** ffmpeg's arguments: H.264 in, every frame out as JPEG, as soon as it is decoded. */
export const DECODE_ARGS = [
  "-hide_banner",
  "-loglevel",
  "error",
  // One thread (frame threads hold frames back) and the least probing; `-fflags nobuffer` is left
  // out on purpose: with it ffmpeg 7 wrote no frame at all (phase 2 on Rig).
  "-threads",
  "1",
  "-probesize",
  "32",
  "-analyzeduration",
  "0",
  "-f",
  "h264",
  "-i",
  "pipe:0",
  "-fps_mode",
  "passthrough",
  "-f",
  "image2pipe",
  "-c:v",
  "mjpeg",
  "-q:v",
  "5",
  "pipe:1",
];

/** H.264 packets in, JPEG frames out. */
export class H264ToJpeg {
  private proc: ChildProcess | undefined;
  private readonly gate: FrameGate;
  constructor(
    private readonly ffmpeg: string,
    /** The screen's size now (it follows the stream). */
    private readonly sizeOf: () => { width: number; height: number },
    onFrame: (f: DeviceFrame) => void,
    private readonly failed: (why: string) => void,
    gapMs = 66,
  ) {
    this.gate = new FrameGate(onFrame, gapMs);
  }

  /** A configuration packet (SPS/PPS): a new decoder for this size. */
  configure(config: Uint8Array): void {
    this.stopDecoder();
    const p = spawn(this.ffmpeg, DECODE_ARGS, {
      stdio: ["pipe", "pipe", "pipe"],
      windowsHide: true,
    });
    const split = new JpegSplitter();
    let err = "";
    p.stdout?.on("data", (d: Buffer) => {
      for (const jpeg of split.push(d))
        this.gate.push({ data: jpeg.toString("base64"), ...this.sizeOf() });
    });
    p.stderr?.on("data", (d: Buffer) => {
      err = (err + d.toString()).slice(-2000);
    });
    p.stdin?.on("error", () => {});
    p.on("error", (e) => this.failed(`ffmpeg did not start: ${e.message}`));
    p.on("exit", (code) => {
      if (this.proc === p && code) this.failed(`ffmpeg stopped (${code}): ${err.trim()}`);
    });
    this.proc = p;
    p.stdin?.write(config);
  }

  /** A frame's packet. */
  data(packet: Uint8Array): void {
    this.proc?.stdin?.write(packet);
  }

  private stopDecoder(): void {
    const p = this.proc;
    this.proc = undefined;
    if (p) {
      p.stdin?.end();
      p.kill();
    }
  }

  close(): void {
    this.stopDecoder();
    this.gate.close();
  }
}
