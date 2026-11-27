// How much context stays in the card (3.12.10): the rule against what Rig measured with Inkling 2 Mini UD-IQ3_XXS on
// an RTX 4080 SUPER (16 GiB) on 2026-11-27 (plan_contesto.md): fitting configurations wrote at ~50 t/s, the others
// had part of the model moved to the processor (10-20 t/s) or stalled.
import { describe, expect, it } from "vitest";
import { type ContextFitInput, contextInCard, contextNeedGb } from "../src/context-fit.js";

const inkling = (o: Partial<ContextFitInput>): ContextFitInput => ({
  fileGb: 10.86,
  vramGb: 15.99,
  marginGb: 1,
  kvBytesPerToken: 196608,
  kvGrowBytesPerToken: 32768,
  slidingWindow: 1024,
  pairBytes: 216,
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
});
