// A device's H.264 decoded in the page (3.11 phase 7): WebCodecs where the browser has it and can
// decode the stream's profile, drawn on a canvas, ~50 ms instead of the JPEGs' ~100-150 ms. Annex B
// as scrcpy sends it: the configuration (SPS/PPS) goes in front of the next key frame, deltas before
// the first key frame are dropped. Anything that does not work says so once, and the view goes back
// to JPEG frames.

/** Whether this browser has a video decoder at all. */
export const hasVideoDecoder = (): boolean =>
  typeof (globalThis as { VideoDecoder?: unknown }).VideoDecoder === "function";

const hex = (n: number) => n.toString(16).padStart(2, "0").toUpperCase();

/** The codec string (`avc1.PPCCLL`) of the stream, from the first SPS in Annex B bytes. Pure. */
export function codecFromSps(b: Uint8Array): string | undefined {
  for (let i = 0; i + 4 < b.length; i++) {
    const three = b[i] === 0 && b[i + 1] === 0 && b[i + 2] === 1;
    if (!three) continue;
    const nal = b[i + 3] as number;
    if ((nal & 0x1f) === 7 && i + 6 < b.length)
      return `avc1.${hex(b[i + 4] as number)}${hex(b[i + 5] as number)}${hex(b[i + 6] as number)}`;
  }
  return undefined;
}

export const fromBase64 = (s: string): Uint8Array =>
  Uint8Array.from(atob(s), (c) => c.charCodeAt(0));

export interface VideoPacketMessage {
  data: string;
  config: boolean;
  key: boolean;
  width: number;
  height: number;
}

interface DecoderLike {
  state: string;
  configure(c: { codec: string; optimizeForLatency?: boolean }): void;
  decode(chunk: unknown): void;
  close(): void;
}

/** Decodes packets onto a canvas; `failed` once if this browser cannot. */
export class H264Canvas {
  private decoder: DecoderLike | undefined;
  private codec: string | undefined;
  private config: Uint8Array | undefined;
  private started = false;
  private ts = 0;
  private dead = false;

  constructor(
    private readonly canvas: () => HTMLCanvasElement | null,
    private readonly failed: (why: string) => void,
    private readonly drawn: () => void = () => {},
  ) {}

  private fail(why: string) {
    if (this.dead) return;
    this.dead = true;
    this.close();
    this.failed(why);
  }

  async push(p: VideoPacketMessage): Promise<void> {
    if (this.dead) return;
    const bytes = fromBase64(p.data);
    if (p.config) {
      const codec = codecFromSps(bytes);
      if (!codec) return this.fail("No SPS in the configuration");
      this.config = bytes;
      this.started = false;
      if (codec !== this.codec) {
        const VD = (
          globalThis as {
            VideoDecoder?: { isConfigSupported(c: unknown): Promise<{ supported?: boolean }> };
          }
        ).VideoDecoder;
        const ok = await VD?.isConfigSupported({ codec, optimizeForLatency: true }).catch(
          () => undefined,
        );
        if (!ok?.supported) return this.fail(`This browser does not decode ${codec}`);
        this.decoder?.close();
        this.decoder = this.make();
        this.decoder.configure({ codec, optimizeForLatency: true });
        this.codec = codec;
      }
      return;
    }
    if (!this.decoder || this.decoder.state !== "configured") return;
    if (!this.started && !p.key) return;
    let data = bytes;
    if (p.key && this.config) {
      data = new Uint8Array(this.config.length + bytes.length);
      data.set(this.config);
      data.set(bytes, this.config.length);
    }
    this.started = true;
    const Chunk = (globalThis as { EncodedVideoChunk?: new (i: unknown) => unknown })
      .EncodedVideoChunk;
    if (!Chunk) return this.fail("No EncodedVideoChunk");
    try {
      this.ts += 33_333;
      this.decoder.decode(new Chunk({ type: p.key ? "key" : "delta", timestamp: this.ts, data }));
    } catch (e) {
      this.fail(e instanceof Error ? e.message : String(e));
    }
  }

  private make(): DecoderLike {
    const VD = (globalThis as { VideoDecoder?: new (i: unknown) => DecoderLike }).VideoDecoder;
    if (!VD) throw new Error("No VideoDecoder");
    return new VD({
      output: (frame: { displayWidth: number; displayHeight: number; close(): void }) => {
        const c = this.canvas();
        if (c) {
          if (c.width !== frame.displayWidth) c.width = frame.displayWidth;
          if (c.height !== frame.displayHeight) c.height = frame.displayHeight;
          c.getContext("2d")?.drawImage(frame as unknown as CanvasImageSource, 0, 0);
          this.drawn();
        }
        frame.close();
      },
      error: (e: Error) => this.fail(e.message),
    });
  }

  close(): void {
    try {
      this.decoder?.close();
    } catch {}
    this.decoder = undefined;
    this.codec = undefined;
  }
}
