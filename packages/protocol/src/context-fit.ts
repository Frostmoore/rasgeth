// How much context a local model can keep with all of it in the graphics card (3.12.10, plan_contesto.md). The
// context is booked whole when the engine starts; when model, context and the engine's scratch do not fit, llama.cpp
// moves part of the model to the processor without saying so and writing gets 3-5 times slower (Inkling 2 Mini on an
// RTX 4080 SUPER: 50 t/s at 32 768 tokens, 10 t/s at 65 536). One pure rule, tested as a table on what Rig measured.

/** What the rule needs: the model's file and header, the card, and how the engine keeps the context. */
export interface ContextFitInput {
  /** The model's file(s), in GiB. */
  fileGb: number;
  /** The card's memory, in GiB. */
  vramGb: number;
  /** Left free for the desktop and the other programs (Windows moves memory out when it runs short). */
  marginGb: number;
  /** Keys and values a token of context takes at 16 bits, every layer (`GgufMeta.kvBytesPerToken`). */
  kvBytesPerToken: number;
  /** Without `--swa-full`: what a token adds when the sliding-window layers keep only their window. */
  kvGrowBytesPerToken?: number | undefined;
  slidingWindow?: number | undefined;
  /** Attention with relative positions: scratch bytes for each pair of tokens (reading pass x context). */
  pairBytes?: number | undefined;
  /** The engine keeps the whole conversation in the sliding-window layers too. */
  swaFull: boolean;
  /** Keys and values at 8 bits (q8_0) or 16. */
  kvBits: 8 | 16;
  /** Tokens of a reading pass (`-ub`, llama.cpp's default 512). */
  ubatch: number;
}

const GIB = 1024 ** 3;
/** The engine's own scratch beyond the context (measured about 0.3 GiB with flash attention). */
const BASE_GB = 0.3;

/** GiB the engine needs with `ctx` tokens of context. */
export function contextNeedGb(i: ContextFitInput, ctx: number): number {
  const scale = i.kvBits === 8 ? 0.5 : 1;
  const grows = !i.swaFull && i.kvGrowBytesPerToken !== undefined;
  const perToken = (grows ? (i.kvGrowBytesPerToken as number) : i.kvBytesPerToken) * scale;
  // Without --swa-full the window layers keep only their window, a fixed size.
  const window = grows
    ? (i.kvBytesPerToken - (i.kvGrowBytesPerToken as number)) *
      scale *
      Math.min(ctx, i.slidingWindow ?? 0)
    : 0;
  const scratch = (i.pairBytes ?? 0) * i.ubatch * ctx;
  return i.fileGb + (perToken * ctx + window + scratch) / GIB + BASE_GB;
}

/**
 * The longest context (a multiple of 1024, at least 1024, at most `max`) that keeps the model, its context and the
 * engine's scratch in the card with the margin free; 0 when the model alone does not fit.
 */
export function contextInCard(i: ContextFitInput, max: number): number {
  const room = i.vramGb - i.marginGb;
  if (contextNeedGb(i, 1024) > room) return 0;
  let lo = 1024;
  let hi = Math.max(1024, Math.floor(max / 1024) * 1024);
  if (contextNeedGb(i, hi) <= room) return hi;
  // The need grows with the context: the last 1024-step that fits.
  while (hi - lo > 1024) {
    const mid = Math.floor((lo + hi) / 2048) * 1024;
    if (contextNeedGb(i, mid) <= room) lo = mid;
    else hi = mid;
  }
  return lo;
}
