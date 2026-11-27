// What a GGUF file says about its model (2026-11-03, for SSD streaming): its architecture,
// layers, the context it was trained for, its experts (mixture of experts or dense), and what
// one token of context costs in memory. Only the header is read, in pieces, so it works on a
// file on disk and on one on Hugging Face (HTTP ranges) alike; the tokenizer's long lists that
// follow the model's keys are not read.

export interface GgufMeta {
  architecture: string;
  name?: string;
  layers: number;
  /** The context it was trained for, in tokens. */
  contextLength: number;
  /** Experts a layer has (0: a dense model) and those used for each token. */
  experts: number;
  expertsUsed: number;
  /** Bytes of keys and values for one token of context, at 16 bits. */
  kvBytesPerToken: number;
  /** The words the model knows, when the header says (`<arch>.vocab_size`; 0 when it does not). */
  vocabSize?: number;
  /** Its MTP heads (`<arch>.nextn_predict_layers`), when it has some: what MTP decoding needs. */
  mtpLayers?: number;
  /**
   * Sliding-window models (3.12.10): bytes of keys and values a token adds at 16 bits when only the layers that see
   * the whole conversation keep it (no `--swa-full`), and the window the others keep. Unset: every layer grows.
   */
  kvGrowBytesPerToken?: number;
  slidingWindow?: number;
  /**
   * Attention with relative positions (Inkling 2, 3.12.10): its scratch grows with the reading pass times the
   * context, about these bytes for each pair of tokens (fitted on Rig: 216 bytes for 24 heads). Unset for the others.
   */
  pairBytes?: number;
}

/** Reads `length` bytes at `offset` (fewer at the end of the file). */
export type ReadAt = (offset: number, length: number) => Promise<Uint8Array>;

const CHUNK = 1 << 20;

class Cursor {
  private buf = new Uint8Array(0);
  private start = 0;
  pos = 0;
  constructor(private readonly read: ReadAt) {}

  private async need(n: number): Promise<void> {
    if (this.pos + n <= this.start + this.buf.length) return;
    const more = await this.read(this.start + this.buf.length, Math.max(CHUNK, n));
    if (more.length === 0) throw new Error("The GGUF header ends early");
    // Keep only what is still ahead: the part already read is dropped.
    const keep = this.buf.subarray(this.pos - this.start);
    const next = new Uint8Array(keep.length + more.length);
    next.set(keep);
    next.set(more, keep.length);
    this.buf = next;
    this.start = this.pos;
    await this.need(n);
  }

  private async view(n: number): Promise<DataView> {
    await this.need(n);
    const v = new DataView(this.buf.buffer, this.buf.byteOffset + this.pos - this.start, n);
    this.pos += n;
    return v;
  }

  async u32() {
    return (await this.view(4)).getUint32(0, true);
  }
  async u64() {
    return Number((await this.view(8)).getBigUint64(0, true));
  }
  async bytes(n: number): Promise<Uint8Array> {
    await this.need(n);
    const b = this.buf.slice(this.pos - this.start, this.pos - this.start + n);
    this.pos += n;
    return b;
  }
  async string() {
    return new TextDecoder().decode(await this.bytes(await this.u64()));
  }
  /** Moves past `n` bytes without keeping them. */
  async skip(n: number) {
    while (n > 0) {
      const step = Math.min(n, CHUNK);
      await this.need(step);
      this.pos += step;
      n -= step;
    }
  }
}

/** Sizes of GGUF's scalar types (8 is a string, 9 an array). */
const SIZES: Record<number, number> = {
  0: 1,
  1: 1,
  2: 2,
  3: 2,
  4: 4,
  5: 4,
  6: 4,
  7: 1,
  10: 8,
  11: 8,
  12: 8,
};

async function value(c: Cursor, type: number): Promise<unknown> {
  switch (type) {
    case 0:
      return (await c.bytes(1))[0];
    case 4:
      return c.u32();
    case 5:
      return (await c.u32()) | 0;
    case 10:
    case 11:
      return c.u64();
    case 6: {
      const b = await c.bytes(4);
      return new DataView(b.buffer).getFloat32(0, true);
    }
    case 7:
      return (await c.bytes(1))[0] !== 0;
    case 8:
      return c.string();
    case 9: {
      const inner = await c.u32();
      const n = await c.u64();
      // Short lists of whole numbers are read (per-layer head counts, 2026-11-27); the rest are skipped (the
      // tokenizer's are not read at all).
      if ((inner === 4 || inner === 5) && n <= 1024) {
        const out: number[] = [];
        for (let i = 0; i < n; i++) out.push(inner === 5 ? (await c.u32()) | 0 : await c.u32());
        return out;
      }
      // Short lists of yes/no (which layers see through a sliding window).
      if (inner === 7 && n <= 1024) {
        const out: boolean[] = [];
        for (let i = 0; i < n; i++) out.push((await c.bytes(1))[0] !== 0);
        return out;
      }
      if (inner === 8) for (let i = 0; i < n; i++) await c.skip(await c.u64());
      else await c.skip(n * (SIZES[inner] ?? 0));
      return undefined;
    }
    default: {
      const size = SIZES[type];
      if (size === undefined) throw new Error(`Unknown GGUF value type ${type}`);
      const b = await c.bytes(size);
      return size === 2 ? new DataView(b.buffer).getUint16(0, true) : b[0];
    }
  }
}

export async function readGgufMeta(read: ReadAt): Promise<GgufMeta> {
  const c = new Cursor(read);
  const magic = new TextDecoder().decode(await c.bytes(4));
  if (magic !== "GGUF") throw new Error("Not a GGUF file");
  const version = await c.u32();
  if (version < 2) throw new Error(`GGUF version ${version} is too old`);
  await c.u64(); // tensors
  const count = await c.u64();
  const kv = new Map<string, unknown>();
  for (let i = 0; i < count; i++) {
    const key = await c.string();
    // The tokenizer's keys come after the model's and hold huge lists: enough was read.
    if (key.startsWith("tokenizer.")) break;
    kv.set(key, await value(c, await c.u32()));
  }
  const arch = String(kv.get("general.architecture") ?? "");
  if (!arch) throw new Error("The GGUF file names no architecture");
  const num = (k: string) => {
    const v = kv.get(`${arch}.${k}`);
    return typeof v === "number" ? v : 0;
  };
  const layers = num("block_count");
  // A count may be one number for every layer or a list with one per layer (Inkling 2, 2026-11-27: read as 0, the
  // context looked free and Deep Field asked for a million tokens).
  const perLayer = (k: string): number[] => {
    const v = kv.get(`${arch}.${k}`);
    if (Array.isArray(v)) return v.map((x) => (typeof x === "number" ? x : 0));
    return Array.from({ length: layers }, () => (typeof v === "number" ? v : 0));
  };
  const headsBy = perLayer("attention.head_count");
  const kvHeadsBy = perLayer("attention.head_count_kv").map((n, i) => n || headsBy[i] || 0);
  const heads = Math.max(0, ...headsBy);
  const embed = num("embedding_length");
  const keyLen = num("attention.key_length") || (heads ? embed / heads : 0);
  const valueLen = num("attention.value_length") || keyLen;
  // Looped models run layers [start, end) `count` times, each pass with its own keys and values.
  const loops = num("loop.count");
  const from = num("loop.start");
  const to = num("loop.end");
  // Hybrid models (Qwen 3.5+): only every `full_attention_interval`-th layer has attention, the others a recurrent
  // state of fixed size; only the attention layers keep keys and values.
  const interval = num("full_attention_interval");
  const attends = (i: number) => interval <= 1 || (i + 1) % interval === 0;
  const passes = (i: number) => (attends(i) ? (loops > 1 && i >= from && i < to ? loops : 1) : 0);
  const kvPerToken = kvHeadsBy
    .slice(0, layers || kvHeadsBy.length)
    .reduce((sum, n, i) => sum + n * (keyLen + valueLen) * 2 * passes(i), 0);
  // A sliding window: the layers marked true keep only the last `sliding_window` tokens.
  const window = num("attention.sliding_window");
  const pattern = kv.get(`${arch}.attention.sliding_window_pattern`);
  const swaLayer = (i: number) => Array.isArray(pattern) && pattern[i] === true;
  const kvGrow =
    window > 0 && Array.isArray(pattern)
      ? kvHeadsBy
          .slice(0, layers || kvHeadsBy.length)
          .reduce(
            (sum, n, i) => sum + (swaLayer(i) ? 0 : n * (keyLen + valueLen) * 2 * passes(i)),
            0,
          )
      : undefined;
  const relative = num("attention.relative_length") > 0;
  const name = kv.get("general.name");
  return {
    architecture: arch,
    ...(typeof name === "string" && { name }),
    layers,
    contextLength: num("context_length"),
    experts: num("expert_count"),
    expertsUsed: num("expert_used_count"),
    kvBytesPerToken: Math.round(kvPerToken),
    ...(num("vocab_size") > 0 && { vocabSize: num("vocab_size") }),
    ...(num("nextn_predict_layers") > 0 && { mtpLayers: num("nextn_predict_layers") }),
    ...(kvGrow !== undefined && { kvGrowBytesPerToken: Math.round(kvGrow), slidingWindow: window }),
    ...(relative && { pairBytes: Math.round(heads * 9) }),
  };
}

/** A file on disk, read a piece at a time. */
export async function readLocalGgufMeta(path: string): Promise<GgufMeta> {
  const { open } = await import("node:fs/promises");
  const f = await open(path, "r");
  try {
    return await readGgufMeta(async (offset, length) => {
      const b = new Uint8Array(length);
      const { bytesRead } = await f.read(b, 0, length, offset);
      return b.subarray(0, bytesRead);
    });
  } finally {
    await f.close();
  }
}

/** A file over HTTP with range requests (Hugging Face's resolve links answer them). */
export function readRemoteGgufMeta(
  url: string,
  fetchImpl: typeof fetch = fetch,
): Promise<GgufMeta> {
  return readGgufMeta(async (offset, length) => {
    const r = await fetchImpl(url, {
      headers: { range: `bytes=${offset}-${offset + length - 1}` },
    });
    if (r.status !== 206 && r.status !== 200) throw new Error(`HTTP ${r.status} reading ${url}`);
    const b = new Uint8Array(await r.arrayBuffer());
    // A server that ignores ranges sends everything: keep only the part asked for.
    return r.status === 200 ? b.subarray(offset, offset + length) : b;
  });
}
