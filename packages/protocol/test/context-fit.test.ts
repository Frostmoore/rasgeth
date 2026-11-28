// How much context stays in the card (3.12.10): the rule against what Rig measured with Inkling 2 Mini UD-IQ3_XXS on
// an RTX 4080 SUPER (16 GiB) on 2026-11-27 (plan_contesto.md): fitting configurations wrote at ~50 t/s, the others
// had part of the model moved to the processor (10-20 t/s) or stalled.
import { describe, expect, it } from "vitest";
import {
  type ContextFitInput,
  contextInCard,
  contextNeedGb,
  hotCells,
} from "../src/context-fit.js";

const inkling = (o: Partial<ContextFitInput>): ContextFitInput => ({
  fileGb: 10.86,
  vramGb: 15.99,
  marginGb: 1,
  kvBytesPerToken: 196608,
  kvGrowBytesPerToken: 32768,
  slidingWindow: 1024,
  pairBytes: 144,
  swaFull: true,
  kvBits: 16,
  ubatch: 512,
  ...o,
});

describe("context in the card (3.12.10)", () => {
  it.each([
    // [what, settings, context, fits, measured]
    ["16k, KV q8, --swa-full", { kvBits: 8 }, 16384, true, "50 t/s"],
    ["32k, KV q8, --swa-full", { kvBits: 8 }, 32768, false, "20 t/s"],
    ["65k, Rasgeth's old default", {}, 65536, false, "10 t/s"],
    ["65k, no --swa-full, KV q8", { swaFull: false, kvBits: 8 }, 65536, false, "17 t/s"],
    [
      "65k, no --swa-full, q8, -ub 256, margin 2.5",
      { swaFull: false, kvBits: 8 as const, ubatch: 256, marginGb: 2.5 },
      65536,
      false,
      "21 t/s",
    ],
    [
      "32k, no --swa-full, q8, -ub 256, margin 2.5",
      { swaFull: false, kvBits: 8 as const, ubatch: 256, marginGb: 2.5 },
      32768,
      true,
      "50 t/s",
    ],
    [
      "65k, no --swa-full, q8, -ub 128, margin 2.5",
      { swaFull: false, kvBits: 8 as const, ubatch: 128, marginGb: 2.5 },
      65536,
      true,
      "44 t/s",
    ],
    [
      "65k, no --swa-full, q8, -ub 64, margin 2.5",
      { swaFull: false, kvBits: 8 as const, ubatch: 64, marginGb: 2.5 },
      65536,
      true,
      "47 t/s",
    ],
  ] as const)("%s at %i tokens: fits %s (%s)", (_w, o, ctx, fits) => {
    const i = inkling(o);
    expect(contextNeedGb(i, ctx) <= i.vramGb - i.marginGb).toBe(fits);
  });

  it("finds the longest context that fits, 0 when the model alone does not, the trained one when all fits", () => {
    const best = inkling({ swaFull: false, kvBits: 8, ubatch: 256, marginGb: 2.5 });
    const n = contextInCard(best, 1048576);
    expect(n).toBeGreaterThanOrEqual(32768);
    expect(n).toBeLessThan(65536);
    expect(n % 1024).toBe(0);
    expect(contextNeedGb(best, n + 1024)).toBeGreaterThan(best.vramGb - best.marginGb);
    expect(contextInCard(inkling({ vramGb: 8 }), 65536)).toBe(0);
    // A small model on a big card: everything up to the most asked for.
    expect(contextInCard(inkling({ fileGb: 2, vramGb: 48, pairBytes: undefined }), 32768)).toBe(
      32768,
    );
  });

  it("with the pass shrinking as the context grows (Inkling's recommended engine) 64k fits, 128k does not", () => {
    const passes = (ctx: number) => (ctx <= 32768 ? 256 : ctx <= 65536 ? 128 : 64);
    const n = contextInCard(
      inkling({ swaFull: false, kvBits: 8, ubatch: passes, marginGb: 2.5 }),
      1048576,
    );
    expect(n).toBeGreaterThanOrEqual(65536);
    expect(n).toBeLessThan(131072);
  });
});

describe("cells kept in the card with the long context (C.4 tappa C)", () => {
  const rig = { fileGb: 10.86, vramGb: 15.99, marginGb: 2.5, kvGrowBytesPerToken: 32768 };
  it.each([
    // [what, input, booked context, at least, at most]
    [
      "Rig, Inkling, 1M booked: about 32-40k (32k measured with the margin free, 64k was too many)",
      rig,
      1048576,
      32768,
      40960,
    ],
    ["the booked context is smaller: all of it", rig, 16384, 16384, 16384],
    [
      "a 24 GB card on Linux: much more",
      { ...rig, vramGb: 24, marginGb: 1 },
      1048576,
      500000,
      700000,
    ],
    ["the model alone fills the card: none", { ...rig, vramGb: 12 }, 1048576, 0, 0],
    ["no growing layers: none", { ...rig, kvGrowBytesPerToken: 0 }, 1048576, 0, 0],
  ] as const)("%s", (_w, input, ctx, lo, hi) => {
    const n = hotCells(input, ctx);
    expect(n).toBeGreaterThanOrEqual(lo);
    expect(n).toBeLessThanOrEqual(hi);
    expect(n % 256).toBe(0);
  });
});
