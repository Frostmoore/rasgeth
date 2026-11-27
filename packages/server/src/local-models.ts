// The suggested local models for this computer (G24.3): for each one, the best file that fits
// (`suggest`), its quality in words, or why none fits.
import type { GgufMeta } from "@redgiant/engine-local";
import {
  contextInCard,
  type Improvement,
  type ImprovementInput,
  improvementsFor,
  LOCAL_MODELS,
  type LocalModel,
} from "@redgiant/protocol";
import { betterNearby, type GgufFile, HuggingFace, offered, qualityOf, suggest } from "./hf.js";
import { NORMAL_CTX } from "./stream.js";

/**
 * A file's quality among its repository's (2026-11-04): by its name, unless it is about as big as
 * the largest one. gpt-oss ships its experts already at about 4 bits, so its "Q2_K" weighs almost
 * as much as the original and loses almost nothing: "reduced" would be wrong.
 */
export function qualityAmong(f: GgufFile, files: GgufFile[]): "high" | "good" | "reduced" {
  const sizes = files.filter(offered).map((x) => x.sizeGb);
  const largest = Math.max(0, ...sizes);
  // One file alone says nothing about the others: its name decides.
  return sizes.length > 1 && f.sizeGb >= largest * 0.9 ? "high" : qualityOf(f.quant);
}

/** Room left on the models' disk after a download beyond memory. */
const DISK_MARGIN_GB = 10;

export interface LocalModelChoice extends LocalModel {
  /** The best file that fits, with its size and quality; none if even the smallest is too big. */
  file: (GgufFile & { quality: "high" | "good" | "reduced" }) | null;
  /** The smallest file worth offering, to say how much room it would need. */
  smallestGb: number | null;
  /** Hugging Face could not be asked (offline): the card says so. */
  unavailable?: boolean;
  /** SSD stream: bigger than RAM and card together, part of it read from the SSD at each token. */
  beyondMemory?: boolean;
  /** Every version worth offering, smallest first: the person may pick another (2026-11-04). */
  versions?: (GgufFile & { quality: "high" | "good" | "reduced" })[];
  /** The small model's file for speculative decoding, when the family has one. */
  draftFile?: GgufFile;
  /**
   * What can be turned on for this model on this computer, with the reason when not (p3.12.6):
   * `improvementsFor`. What we measured ourselves is `tested` (from the catalogue).
   */
  improvements?: Improvement[];
}

/** What the page knows about the computer and the engine, for each model's improvements. */
export type ImprovementContext = Pick<ImprovementInput, "gpus" | "deepField" | "prefetchEngine">;

/**
 * The patched engine of Prefetch for the engine chosen: on Windows the release's zip, in Docker
 * the `cuda` image; null where it does not apply (a Mac, Vulkan, the processor).
 */
export function prefetchEngineFor(
  variant: string | undefined,
  hw: { os: string; dockerGpu: boolean; onWindows?: boolean; windowsEngine?: boolean },
  state: {
    moePrefetch: "available" | "missing" | null;
    moePrefetchImage: "available" | "missing" | null;
  },
): "available" | "missing" | null {
  if (hw.os === "darwin") return null;
  if (variant === "windows") return hw.onWindows || hw.windowsEngine ? state.moePrefetch : null;
  if (variant === "cuda") return (hw.dockerGpu && state.moePrefetchImage) || null;
  return null;
}

export async function localModelChoices(
  hf: HuggingFace,
  budgetGb: number,
  /** SSD stream (2026-11-04): a model bigger than memory may still come, if the disk has room. */
  stream?: { diskFreeGb: number },
  /** The files already in the models folder: a model downloaded shows the file it has (2026-11-04). */
  have: ReadonlySet<string> = new Set(),
  /** The computer, for each model's improvements (p3.12.6). */
  improve?: ImprovementContext,
): Promise<LocalModelChoice[]> {
  const improvements = (m: LocalModel) =>
    improve ? { improvements: improvementsFor({ ...improve, model: m }) } : {};
  return Promise.all(
    LOCAL_MODELS.map(async (m) => {
      try {
        const [files, draftFiles] = await Promise.all([
          hf.files(m.repo),
          m.draft ? hf.files(m.draft.repo).catch(() => []) : Promise.resolve([]),
        ]);
        const draftFile = draftFiles.find((f) => f.quant === m.draft?.quant);
        const mine = files
          .filter((f) => have.has(HuggingFace.target(f.file)))
          .sort((a, b) => b.sizeGb - a.sizeGb)[0];
        const best = mine ?? suggest(files, budgetGb);
        const smallest = files.find(offered);
        // Nothing fits in memory: with SSD stream the smallest good file still runs, reading
        // what does not fit from the SSD (slower, said in the table).
        const beyond =
          !best && stream && smallest && smallest.sizeGb <= stream.diskFreeGb - DISK_MARGIN_GB
            ? smallest
            : undefined;
        // A file the person has is shown as it is; otherwise the best one for about the same room.
        const found = best ?? beyond;
        const file = found && !mine ? betterNearby(files, found) : found;
        return {
          ...m,
          file: file ? { ...file, quality: qualityAmong(file, files) } : null,
          smallestGb: smallest?.sizeGb ?? null,
          versions: files.filter(offered).map((f) => ({ ...f, quality: qualityAmong(f, files) })),
          ...(draftFile && { draftFile }),
          ...improvements(m),
          ...((beyond || (file && file.sizeGb > budgetGb)) && { beyondMemory: true }),
        };
      } catch {
        return { ...m, file: null, smallestGb: null, unavailable: true, ...improvements(m) };
      }
    }),
  );
}

/**
 * The context bar of a model's card (3.12.10, plan_contesto.md): the longest context the model knows, and how much of
 * it stays in the card with Rasgeth's settings (no --swa-full, keys and values at 8 bits, the margin left free on
 * Windows, the recommended engine's reading pass when it is on). `inCard` is null without a card of its own (the
 * processor, or one memory shared with it): there the context only takes more RAM.
 */
export function contextChoice(
  meta: GgufMeta,
  fileGb: number,
  hw: { kind: "gpu" | "gpu-unknown" | "igpu" | "cpu"; vramGb: number },
  opts: { windows: boolean; ubatch?: number | undefined },
): { trained: number; inCard: number | null } {
  const trained = meta.contextLength || NORMAL_CTX;
  if (hw.kind !== "gpu" || hw.vramGb <= 0) return { trained, inCard: null };
  const inCard = contextInCard(
    {
      fileGb,
      vramGb: hw.vramGb,
      marginGb: opts.windows ? 2.5 : 1,
      kvBytesPerToken: meta.kvBytesPerToken,
      kvGrowBytesPerToken: meta.kvGrowBytesPerToken,
      slidingWindow: meta.slidingWindow,
      pairBytes: meta.pairBytes,
      swaFull: false,
      kvBits: 8,
      ubatch: opts.ubatch ?? 512,
    },
    trained,
  );
  return { trained, inCard };
}
