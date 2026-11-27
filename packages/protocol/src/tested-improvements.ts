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

/** What we measured for a model, the improvements that helped (empty when none or not tried). */
export function testedFor(id: string): TestedResult[] {
  return [...(TESTED_IMPROVEMENTS[id] ?? [])];
}
