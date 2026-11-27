// The context bar of a model's card (3.12.10): what the server says for Inkling 2 Mini UD-IQ3_XXS, from its header
// as read on 2026-11-27, with Rasgeth's settings (plan_contesto.md).
import type { GgufMeta } from "@redgiant/engine-local";
import { describe, expect, it } from "vitest";
import { contextChoice } from "../src/local-models.js";

const inkling: GgufMeta = {
  architecture: "inkling2_loop",
  layers: 24,
  contextLength: 1048576,
  experts: 128,
  expertsUsed: 8,
  kvBytesPerToken: 196608,
  kvGrowBytesPerToken: 32768,
  slidingWindow: 1024,
  pairBytes: 216,
};

describe("the context bar of a model's card (3.12.10)", () => {
  it("on a 16 GB card: about 32k with the recommended pass on Windows, less with llama.cpp's default pass", () => {
    const card = { kind: "gpu" as const, vramGb: 15.99 };
    const rec = contextChoice(inkling, 10.86, card, { windows: true, ubatch: 256 });
    expect(rec.trained).toBe(1048576);
    expect(rec.inCard).toBeGreaterThanOrEqual(32768);
    expect(rec.inCard).toBeLessThan(65536);
    const plain = contextChoice(inkling, 10.86, card, { windows: true });
    expect(plain.inCard).toBeLessThan(rec.inCard as number);
  });

  it("no card of its own: the context only takes RAM, no mark", () => {
    expect(contextChoice(inkling, 10.86, { kind: "cpu", vramGb: 0 }, { windows: false })).toEqual({
      trained: 1048576,
      inCard: null,
    });
    expect(
      contextChoice(inkling, 10.86, { kind: "igpu", vramGb: 0 }, { windows: false }).inCard,
    ).toBeNull();
  });
});
