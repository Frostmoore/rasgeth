// The improvements we measured ourselves on each catalog model (2026-11-27, the user: «crea il file con i
// miglioramenti adatti a ogni modello in modo che la gente lo sappia già»): only the ones that made the model
// faster, with the computer they were measured on. The model's card draws them with a gold border; every
// other improvement stays the person's to try. What was tried without a gain is written here too, so it is
// not tried again in vain. Speeds in tokens a second, before and after, on the same engine and settings.

import type { TestedResult } from "./improvements.js";

export const TESTED_IMPROVEMENTS: Readonly<Record<string, readonly TestedResult[]>> = {
  // Qwen 3.8 27B Q4_K_M, Coder (Intel i5-12500H, processor only), 2026-11-24/25 (plan_motore_locale.md).
  "qwen3.8-27b": [
    // llama.cpp re-arranges the weights for the processor; writing was faster without it, reading unchanged.
    { improvement: "noRepack", hardware: "Intel i5-12500H", write: { before: 2.88, after: 3.21 } },
    // The model's own MTP heads, 2 drafts, 128 tokens, 54 W.
    {
      improvement: "speculative",
      mode: "mtp",
      hardware: "Intel i5-12500H",
      write: { before: 2.98, after: 3.88 },
    },
  ],
  // Inkling 2 Mini UD-IQ3_XXS, 2026-11-27, Rasgeth's own engines and settings (plan_motore_locale.md). No MTP heads.
  // Coder (Intel i5-12500H, processor only): no gain from No Repack (6.7 -> 6.8, 4.6 -> 4.6: IQ files are not
  // re-arranged); Speculative from the text already written helps text that repeats itself (+17% to +53%) but
  // writes a rewritten file 11% slower (229/384 drafts accepted), so it is not shown for the processor.
  // Rig (NVIDIA RTX 4080 SUPER 16 GB): No Repack no gain (9.4 -> 9.4); Deep Field, Big Chunks and Prefetch do not
  // start with big passes (the attention needs ~220 bytes per pair of tokens: 4096 x 65536 asked 58.7 GB).
  "inkling-2-mini": [
    // Speculative from the text already written: a rewritten file 9.4 -> 12.7 (+35%), text that repeats itself
    // 7.5 -> 16.4, a plain question unchanged (9.6 -> 10.2); at 32k context 19.0 -> 23.5 on the same file.
    {
      improvement: "speculative",
      mode: "ngram",
      hardware: "NVIDIA RTX 4080 SUPER",
      write: { before: 9.4, after: 12.7 },
    },
  ],
};

/**
 * An engine set up for one model (3.12.10, the user: «possiamo scegliere il motore per ogni modello. default quello di
 * serie, su quelli testati consigliamo quello che funziona meglio»): what we measured faster than Rasgeth's own
 * settings on a computer, offered with a gold border on the model's card, never applied by itself. Only words of
 * ours reach the engine: the page names the model, the server takes the settings from here.
 */
export interface RecommendedEngine {
  /** Tokens of a reading pass (`-ub`). */
  ubatch?: number;
  /** The context to keep (tokens): the longest that keeps everything in the card where it was measured. */
  ctx?: number;
  /** The computer it was measured on, in words. */
  hardware: string;
  /** Writing, tokens a second: Rasgeth's own settings, then these. */
  write: { before: number; after: number };
}

export const RECOMMENDED_ENGINES: Readonly<Record<string, RecommendedEngine>> = {
  // Inkling 2 Mini UD-IQ3_XXS on Rig, 2026-11-27 (plan_contesto.md): its attention's scratch grows with the reading
  // pass times the context; 256-token passes and 32 768 tokens keep it all in a 16 GB card. A rewritten file
  // 9.4 -> 47.6 t/s, a long text 7.5 -> 49.7, the second turn of a conversation from the cache in 0.3 s.
  "inkling-2-mini": {
    ubatch: 256,
    ctx: 32768,
    hardware: "NVIDIA RTX 4080 SUPER",
    write: { before: 9.4, after: 47.6 },
  },
};

/** The engine we recommend for a model, when we measured one. */
export function recommendedFor(id: string): RecommendedEngine | undefined {
  return RECOMMENDED_ENGINES[id];
}

/** What we measured for a model, the improvements that helped (empty when none or not tried). */
export function testedFor(id: string): TestedResult[] {
  return [...(TESTED_IMPROVEMENTS[id] ?? [])];
}
