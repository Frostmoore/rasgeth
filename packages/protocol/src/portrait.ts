import { z } from "zod";

/**
 * The person's portrait («Mirror», 3.9.4): what the agents learned by themselves about how the
 * person is, from the conversations, each trait with where it comes from. Rebuilt from the
 * `portrait.*` events; the person sees and corrects it, and their edits win.
 */
export const PortraitCategory = z.enum([
  /** Tastes and choices: tools, formats, languages. */
  "preference",
  /** How they like to be spoken to. */
  "style",
  /** How and when they work. */
  "habit",
  /** What they are working on now. */
  "project",
  /** Things to avoid with them. */
  "avoid",
  /** Lasting facts about them. */
  "about",
]);
export type PortraitCategory = z.infer<typeof PortraitCategory>;
export const PORTRAIT_CATEGORIES = PortraitCategory.options;

/** Where a trait was seen: a conversation, the agent in it, when the person wrote it. */
export const PortraitSource = z.object({
  sessionId: z.string(),
  agentId: z.string().nullable(),
  /** When the person wrote the message it comes from. */
  at: z.string(),
  /** Filled by the server for the page: the conversation's title and the agent's name. */
  sessionTitle: z.string().nullable().optional(),
  agentName: z.string().nullable().optional(),
});
export type PortraitSource = z.infer<typeof PortraitSource>;

export const PortraitTrait = z.object({
  id: z.string(),
  text: z.string(),
  category: PortraitCategory,
  /** 0–1, after the decay of time: what the agents read is the surer part. */
  confidence: z.number(),
  createdAt: z.string(),
  updatedAt: z.string(),
  /** The last time a conversation said it again (or the person wrote it). */
  seenAt: z.string(),
  /** "auto" (learned) or "human" (written by the person). */
  by: z.string(),
  /** The person wrote or corrected it: it never decays and the learning pass leaves it as it is. */
  edited: z.boolean(),
  /** Conversations said it again, this many times. */
  confirmations: z.number().int(),
  /** The newest few, newest first. */
  sources: z.array(PortraitSource),
});
export type PortraitTrait = z.infer<typeof PortraitTrait>;

/** Which agents read the portrait when a conversation starts. */
export const PortraitAgents = z.object({
  god: z.boolean(),
  orchestrators: z.boolean(),
  chat: z.boolean(),
  /** Every other agent and assistant (a project's agents, sub-agents). */
  others: z.boolean(),
});
export type PortraitAgents = z.infer<typeof PortraitAgents>;
export const DEFAULT_PORTRAIT_AGENTS: PortraitAgents = {
  god: true,
  orchestrators: true,
  chat: true,
  others: false,
};

export const PortraitView = z.object({
  /** It builds itself from the conversations and reaches the agents; off: neither. */
  on: z.boolean(),
  agents: PortraitAgents,
  traits: z.array(PortraitTrait),
  /** The portrait exactly as the agents read it at the start of a conversation ("" when none). */
  text: z.string(),
  limit: z.number().int(),
  /** Traits the person said are not true: never proposed again. */
  denied: z.number().int(),
});
export type PortraitView = z.infer<typeof PortraitView>;

/** One change to a trait, as the event log keeps it. */
export const PortraitTraitPayload = z.object({
  traitId: z.string(),
  /**
   * From the learning pass: add, confirm (said again), weaken (less sure), contradict (a newer
   * statement replaces it, or without text it drops). From the person: add, edit, remove, deny
   * («not true»: gone, and never proposed again).
   */
  op: z.enum(["add", "confirm", "weaken", "contradict", "edit", "remove", "deny"]),
  text: z.string().optional(),
  category: PortraitCategory.optional(),
  /** The model's confidence for an added trait (0–1). */
  confidence: z.number().optional(),
  source: z
    .object({ sessionId: z.string(), agentId: z.string().nullable(), at: z.string() })
    .optional(),
  /** "auto" or "human". */
  by: z.string(),
});
export type PortraitTraitPayload = z.infer<typeof PortraitTraitPayload>;
