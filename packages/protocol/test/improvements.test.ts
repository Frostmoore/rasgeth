import { describe, expect, it } from "vitest";
import { type ImprovementInput, improvementsFor, isMoe, LOCAL_MODELS } from "../src/index.js";

const moe = { totalB: 80, activeB: 3 };
const dense = { totalB: 27, activeB: 27 };
const rtx = { name: "RTX 4080", vendor: "nvidia", integrated: false };
const radeon = { name: "Radeon RX 7800", vendor: "amd", integrated: false };
const igpu = { name: "Intel Iris Xe", vendor: "intel", integrated: true };

const run = (o: Partial<ImprovementInput>, id: string) =>
  improvementsFor({
    model: moe,
    gpus: [rtx],
    deepField: true,
    prefetchEngine: "available",
    ...o,
  }).find((x) => x.id === id);

describe("what can be turned on (p3.12.6)", () => {
  it("lists the four improvements, always in the same order", () => {
    const all = improvementsFor({ model: moe, gpus: [], deepField: false });
    expect(all.map((x) => x.id)).toEqual(["prefetch", "bigChunks", "speculative", "noRepack"]);
  });

  it("tells a mixture of experts from a dense model", () => {
    expect(isMoe(moe)).toBe(true);
    expect(isMoe(dense)).toBe(false);
  });

  // [name, input, improvement, available, reason]
  const table: [string, Partial<ImprovementInput>, string, boolean, string?][] = [
    ["prefetch with everything", {}, "prefetch", true],
    ["prefetch without NVIDIA (AMD)", { gpus: [radeon] }, "prefetch", false, "needNvidia"],
    ["prefetch with only the integrated card", { gpus: [igpu] }, "prefetch", false, "needNvidia"],
    [
      "prefetch with an integrated NVIDIA",
      { gpus: [{ ...rtx, integrated: true }] },
      "prefetch",
      false,
      "needNvidia",
    ],
    ["prefetch on a dense model", { model: dense }, "prefetch", false, "needMoe"],
    ["prefetch without Deep Field", { deepField: false }, "prefetch", false, "needDeepField"],
    [
      "prefetch with the engine missing",
      { prefetchEngine: "missing" },
      "prefetch",
      false,
      "missingEngine",
    ],
    [
      "prefetch where the engine does not apply",
      { prefetchEngine: null },
      "prefetch",
      false,
      "missingEngine",
    ],
    ["big chunks with everything (AMD too)", { gpus: [radeon] }, "bigChunks", true],
    ["big chunks without a card of its own", { gpus: [igpu] }, "bigChunks", false, "needGpu"],
    ["big chunks without any card", { gpus: [] }, "bigChunks", false, "needGpu"],
    ["big chunks on a dense model", { model: dense }, "bigChunks", false, "needMoe"],
    ["big chunks without Deep Field", { deepField: false }, "bigChunks", false, "needDeepField"],
    ["speculative on nothing", { gpus: [], model: dense, deepField: false }, "speculative", true],
    ["no repack on nothing", { gpus: [], model: dense, deepField: false }, "noRepack", true],
  ];
  it.each(table)("%s", (_n, input, id, available, reason) => {
    const got = run(input, id);
    expect(got?.available).toBe(available);
    expect(got?.reason).toBe(reason);
  });

  it("names the card in the NVIDIA reason: the best own one, or none for the integrated", () => {
    expect(run({ gpus: [igpu, radeon] }, "prefetch")?.gpu).toBe("Radeon RX 7800");
    expect(run({ gpus: [igpu] }, "prefetch")?.gpu).toBeUndefined();
  });

  it("says whether speculative decoding has a small model", () => {
    expect(
      run({ model: { ...dense, draft: { repo: "a/b", quant: "Q8_0" } } }, "speculative")?.draft,
    ).toBe(true);
    expect(run({ model: dense }, "speculative")?.draft).toBe(false);
  });

  it("says whether the model has MTP heads of its own", () => {
    expect(run({ model: { ...dense, mtp: true } }, "speculative")?.mtp).toBe(true);
    expect(run({ model: dense }, "speculative")?.mtp).toBe(false);
  });

  it("marks MTP only on models whose GGUF header says so", () => {
    expect(LOCAL_MODELS.filter((m) => m.mtp).map((m) => m.id)).toEqual(["qwen3.8-27b"]);
  });

  it("keeps only what we really measured in the catalogue", () => {
    const tested = LOCAL_MODELS.flatMap((m) => (m.tested ?? []).map((t) => ({ id: m.id, ...t })));
    expect(tested).toEqual([
      // tested-improvements.ts: Inkling 2 Mini on Rig (2026-11-27).
      {
        id: "inkling-2-mini",
        improvement: "speculative",
        mode: "ngram",
        hardware: "NVIDIA RTX 4080 SUPER",
        write: { before: 9.4, after: 12.7 },
      },
      {
        id: "qwen3.8-27b",
        improvement: "noRepack",
        hardware: "Intel i5-12500H",
        write: { before: 2.88, after: 3.21 },
      },
      {
        id: "qwen3.8-27b",
        improvement: "speculative",
        mode: "mtp",
        hardware: "Intel i5-12500H",
        write: { before: 2.98, after: 3.88 },
      },
    ]);
  });
});
