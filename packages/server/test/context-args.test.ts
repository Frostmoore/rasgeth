// The engine's context arguments (3.12.10): the context booked, the recommended engine's reading pass for that context
// (Inkling 2 Mini on Rig, 2026-11-27: 256 up to 32k, 128 up to 64k, 64 beyond), and the processor threads the person
// chose on the model's card.
import { describe, expect, it } from "vitest";
import { contextArgs, threadArgs } from "../src/stream.js";

describe("context arguments (3.12.10)", () => {
  it.each([
    [32768, "256"],
    [65536, "128"],
    [131072, "64"],
  ])("Inkling's recommended engine at %i tokens reads in passes of %s", (ctx, ub) => {
    const { args } = contextArgs({ ctx, recommended: "inkling-2-mini" }, undefined, true);
    expect(args).toEqual(["-c", String(ctx), "-ub", ub, "-ctk", "q8_0", "-ctv", "q8_0"]);
  });

  it("the recommended engine alone books its own context; without it llama.cpp keeps its pass", () => {
    expect(contextArgs({ recommended: "inkling-2-mini" }, undefined, false)).toEqual({
      ctx: 65536,
      args: ["-c", "65536", "-ub", "128"],
    });
    expect(contextArgs({ ctx: 32768 }, undefined, false).args).toEqual(["-c", "32768"]);
  });

  it("threads only when chosen, writing and reading apart", () => {
    expect(threadArgs({})).toEqual([]);
    expect(threadArgs({ threads: 8 })).toEqual(["-t", "8"]);
    expect(threadArgs({ threads: 8, threadsBatch: 12 })).toEqual(["-t", "8", "-tb", "12"]);
    expect(threadArgs({ threadsBatch: 12 })).toEqual(["-tb", "12"]);
  });
});
