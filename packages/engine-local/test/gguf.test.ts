import { describe, expect, it } from "vitest";
import { readGgufMeta } from "../src/index.js";

/** A small GGUF header: the model's keys, then a long tokenizer list that must not be read. */
function gguf(kv: [string, number, unknown][]): Uint8Array {
  const parts: number[] = [];
  const u32 = (n: number) => {
    const b = new DataView(new ArrayBuffer(4));
    b.setUint32(0, n, true);
    parts.push(...new Uint8Array(b.buffer));
  };
  const u64 = (n: number) => {
    const b = new DataView(new ArrayBuffer(8));
    b.setBigUint64(0, BigInt(n), true);
    parts.push(...new Uint8Array(b.buffer));
  };
  const str = (s: string) => {
    const e = new TextEncoder().encode(s);
    u64(e.length);
    parts.push(...e);
  };
  parts.push(...new TextEncoder().encode("GGUF"));
  u32(3);
  u64(0);
  u64(kv.length + 1);
  for (const [k, type, v] of kv) {
    str(k);
    u32(type);
    if (type === 4) u32(v as number);
    else if (type === 8) str(v as string);
    else if (type === 9 && typeof (v as unknown[])[0] === "boolean") {
      u32(7);
      u64((v as boolean[]).length);
      for (const x of v as boolean[]) parts.push(x ? 1 : 0);
    } else if (type === 9) {
      u32(4);
      u64((v as number[]).length);
      for (const x of v as number[]) u32(x);
    }
  }
  str("tokenizer.ggml.tokens");
  u32(9);
  u32(8);
  u64(1_000_000); // claimed, never there: reading stops before it
  return new Uint8Array(parts);
}

const reader = (b: Uint8Array) => async (offset: number, length: number) =>
  b.subarray(offset, offset + length);

describe("GGUF header (2026-11-03)", () => {
  it("reads a mixture of experts: layers, context, experts and the KV cost of a token", async () => {
    const meta = await readGgufMeta(
      reader(
        gguf([
          ["general.architecture", 8, "qwen3moe"],
          ["general.name", 8, "Qwen3 Coder 30B A3B"],
          ["qwen3moe.block_count", 4, 48],
          ["qwen3moe.context_length", 4, 262144],
          ["qwen3moe.embedding_length", 4, 2048],
          ["qwen3moe.attention.head_count", 4, 32],
          ["qwen3moe.attention.head_count_kv", 4, 4],
          ["qwen3moe.attention.key_length", 4, 128],
          ["qwen3moe.attention.value_length", 4, 128],
          ["qwen3moe.expert_count", 4, 128],
          ["qwen3moe.expert_used_count", 4, 8],
          ["qwen3moe.rope.dimension_sections", 9, [1, 2, 3]],
        ]),
      ),
    );
    expect(meta).toEqual({
      architecture: "qwen3moe",
      name: "Qwen3 Coder 30B A3B",
      layers: 48,
      contextLength: 262144,
      experts: 128,
      expertsUsed: 8,
      // 48 layers × 4 KV heads × (128 + 128) × 2 bytes
      kvBytesPerToken: 98304,
    });
  });

  it("counts heads given layer by layer and the layers a looped model runs again (Inkling 2, 2026-11-27)", async () => {
    // Read as 0 before: the context looked free and Deep Field asked for a million tokens.
    const header = gguf([
      ["general.architecture", 8, "inkling2_loop"],
      ["inkling2_loop.block_count", 4, 24],
      ["inkling2_loop.context_length", 4, 1048576],
      ["inkling2_loop.embedding_length", 4, 2304],
      ["inkling2_loop.attention.head_count", 9, Array(24).fill(24)],
      ["inkling2_loop.attention.head_count_kv", 9, Array(24).fill(8)],
      ["inkling2_loop.attention.key_length", 4, 128],
      ["inkling2_loop.attention.value_length", 4, 128],
      ["inkling2_loop.expert_count", 4, 128],
      ["inkling2_loop.expert_used_count", 4, 8],
      ["inkling2_loop.loop.count", 4, 3],
      ["inkling2_loop.loop.start", 4, 6],
      ["inkling2_loop.loop.end", 4, 18],
    ]);
    const meta = await readGgufMeta(async (o, n) => header.subarray(o, o + n));
    // 24 layers, 12 of them three times: 48 passes of 8 heads x (128 + 128) x 2 bytes, as llama.cpp's KV buffer.
    expect(meta.kvBytesPerToken).toBe(48 * 8 * (128 + 128) * 2);
    expect(meta.kvBytesPerToken).toBe(196608);
  });

  it("says what grows without --swa-full, the attention's scratch, and skips a hybrid's recurrent layers (3.12.10)", async () => {
    const pattern = Array.from({ length: 24 }, (_, i) => i % 6 !== 5);
    const inkling = gguf([
      ["general.architecture", 8, "inkling2_loop"],
      ["inkling2_loop.block_count", 4, 24],
      ["inkling2_loop.attention.head_count", 9, Array(24).fill(24)],
      ["inkling2_loop.attention.head_count_kv", 9, Array(24).fill(8)],
      ["inkling2_loop.attention.key_length", 4, 128],
      ["inkling2_loop.attention.value_length", 4, 128],
      ["inkling2_loop.loop.count", 4, 3],
      ["inkling2_loop.loop.start", 4, 6],
      ["inkling2_loop.loop.end", 4, 18],
      ["inkling2_loop.attention.sliding_window", 4, 1024],
      ["inkling2_loop.attention.sliding_window_pattern", 9, pattern],
      ["inkling2_loop.attention.relative_length", 4, 16],
    ]);
    const m = await readGgufMeta(async (o, n) => inkling.subarray(o, o + n));
    // Layers 5, 11, 17, 23 see everything; 11 and 17 run three times: 8 passes x 4096 bytes.
    expect(m).toMatchObject({ kvGrowBytesPerToken: 32768, slidingWindow: 1024, pairBytes: 216 });
    // Qwen 3.5+: only every fourth layer has attention (measured header: 20480 bytes a token).
    const qwen = gguf([
      ["general.architecture", 8, "qwen35moe"],
      ["qwen35moe.block_count", 4, 40],
      ["qwen35moe.attention.head_count", 4, 16],
      ["qwen35moe.attention.head_count_kv", 4, 2],
      ["qwen35moe.attention.key_length", 4, 256],
      ["qwen35moe.attention.value_length", 4, 256],
      ["qwen35moe.full_attention_interval", 4, 4],
    ]);
    const q = await readGgufMeta(async (o, n) => qwen.subarray(o, o + n));
    expect(q.kvBytesPerToken).toBe(10 * 2 * (256 + 256) * 2);
    expect(q.kvGrowBytesPerToken).toBeUndefined();
    expect(q.pairBytes).toBeUndefined();
  });

  it("a model with MTP heads says how many (3.12.6: MTP decoding needs them)", async () => {
    const meta = await readGgufMeta(
      reader(
        gguf([
          ["general.architecture", 8, "qwen35"],
          ["qwen35.block_count", 4, 65],
          ["qwen35.nextn_predict_layers", 4, 1],
        ]),
      ),
    );
    expect(meta.mtpLayers).toBe(1);
    const plain = await readGgufMeta(
      reader(
        gguf([
          ["general.architecture", 8, "qwen3"],
          ["qwen3.block_count", 4, 40],
        ]),
      ),
    );
    expect(plain.mtpLayers).toBeUndefined();
  });

  it("a dense model has no experts; a file that is not GGUF is refused", async () => {
    const meta = await readGgufMeta(
      reader(
        gguf([
          ["general.architecture", 8, "gemma3"],
          ["gemma3.block_count", 4, 48],
          ["gemma3.context_length", 4, 131072],
          ["gemma3.embedding_length", 4, 3840],
          ["gemma3.attention.head_count", 4, 16],
          ["gemma3.attention.head_count_kv", 4, 8],
        ]),
      ),
    );
    expect(meta.experts).toBe(0);
    expect(meta.kvBytesPerToken).toBe(48 * 8 * (240 + 240) * 2);
    await expect(
      readGgufMeta(reader(new TextEncoder().encode("PK\u0003\u0004zip"))),
    ).rejects.toThrow("Not a GGUF file");
  });
});
