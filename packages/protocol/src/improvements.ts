// What can be turned on for a local model (p3.12.6, «Improvements»): one pure rule, tested as a
// table. The server computes it for each model choice, the page and the app only render it.
import type { LocalModel } from "./local-models.js";

export const IMPROVEMENT_IDS = ["prefetch", "bigChunks", "speculative", "noRepack"] as const;
export type ImprovementId = (typeof IMPROVEMENT_IDS)[number];

/** Why an improvement is off (and locked), in a code each page explains in its words. */
export type ImprovementReason =
  | "needNvidia"
  | "needGpu"
  | "needMoe"
  | "needDeepField"
  | "missingEngine";

/** What the rule needs to know: the model, the computer, and what is switched on. */
export interface ImprovementInput {
  model: Pick<LocalModel, "totalB" | "activeB" | "draft">;
  /** The computer's graphics cards, as the setup describes them. */
  gpus: { name: string; vendor: string; integrated: boolean }[];
  /** Deep Field (the SSD streaming) is on. */
  deepField: boolean;
  /** The patched engine of Prefetch: there, not published/downloadable, or not applicable (null). */
  prefetchEngine?: "available" | "missing" | null | undefined;
}

export interface Improvement {
  id: ImprovementId;
  available: boolean;
  /** Set when not available: the first rule that is not met. */
  reason?: ImprovementReason;
  /**
   * The card the reason talks about: the best one with its own memory (`needNvidia`), undefined
   * when the computer has only the graphics built into the processor, or none.
   */
  gpu?: string;
  /** Speculative decoding only: the model's family has a small model for the `draft` way. */
  draft?: boolean;
}

/** A mixture of experts: few of its parameters work on each token. */
export function isMoe(m: Pick<LocalModel, "totalB" | "activeB">): boolean {
  return m.activeB < m.totalB * 0.5;
}

/** What we measured ourselves for a model: numbers in tokens a second, before and after. */
export interface TestedResult {
  improvement: ImprovementId;
  /** The computer it was measured on, in words («Intel i5-12500H»). */
  hardware: string;
  /** Reading a message. */
  read?: { before: number; after: number };
  /** Writing one token at a time. */
  write?: { before: number; after: number };
}

export function improvementsFor(input: ImprovementInput): Improvement[] {
  const own = input.gpus.filter((g) => !g.integrated);
  const nvidia = own.find((g) => g.vendor === "nvidia");
  const moe = isMoe(input.model);
  const bestGpu = (nvidia ?? own[0])?.name;
  const off = (id: ImprovementId, reason: ImprovementReason, gpu?: string): Improvement => ({
    id,
    available: false,
    reason,
    ...(gpu !== undefined && { gpu }),
  });
  const prefetch = (): Improvement => {
    if (!nvidia) return off("prefetch", "needNvidia", bestGpu);
    if (!moe) return off("prefetch", "needMoe");
    if (!input.deepField) return off("prefetch", "needDeepField");
    if (input.prefetchEngine !== "available") return off("prefetch", "missingEngine");
    return { id: "prefetch", available: true };
  };
  const bigChunks = (): Improvement => {
    if (own.length === 0) return off("bigChunks", "needGpu");
    if (!moe) return off("bigChunks", "needMoe");
    if (!input.deepField) return off("bigChunks", "needDeepField");
    return { id: "bigChunks", available: true };
  };
  return [
    prefetch(),
    bigChunks(),
    { id: "speculative", available: true, draft: Boolean(input.model.draft) },
    { id: "noRepack", available: true },
  ];
}
