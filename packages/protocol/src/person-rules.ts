// The person's rules (3.12, «Regole della persona»): WHEN something happens (an event), IF some
// conditions hold, THEN Rasgeth acts by itself (actions). A rule never grants more than the person
// has: there is no "allow" action, a command it runs goes through the same checks as an agent's.
import { z } from "zod";

/**
 * What a rule listens to. `usage`: a subscription's window was read (margin and use); `budget`: a
 * budget's use; `tool`: a tool or a command is about to run; `file`: a file is about to be written;
 * `agent_done`: an agent ended its turn; `schedule`: a time (cron); `webhook`: a call to the rule's own address (its body is data).
 */
export const RULE_EVENTS = [
  "usage",
  "budget",
  "tool",
  "file",
  "agent_done",
  "schedule",
  "webhook",
] as const;
export const RuleEventKind = z.enum(RULE_EVENTS);
export type RuleEventKind = z.infer<typeof RuleEventKind>;

/** The facts a condition can look at; `RULE_FIELDS` says which events have which. */
export const RULE_FIELD_NAMES = [
  "marginPct",
  "usedPct",
  "window",
  "provider",
  "budgetPct",
  "budget",
  "tool",
  "command",
  "path",
  "project",
  "agent",
  "stopReason",
  "body",
] as const;
export const RuleField = z.enum(RULE_FIELD_NAMES);
export type RuleField = z.infer<typeof RuleField>;

/** Which facts each event has (the editor offers these; a rule on another one is refused). */
export const RULE_FIELDS_BY_EVENT: Record<RuleEventKind, readonly RuleField[]> = {
  usage: ["marginPct", "usedPct", "window", "provider"],
  budget: ["budgetPct", "budget"],
  tool: ["tool", "command", "path", "project", "agent"],
  file: ["path", "tool", "project", "agent"],
  agent_done: ["agent", "project", "stopReason"],
  schedule: [],
  /** A call to the rule's own address: its body is data, only ever matched, never obeyed. */
  webhook: ["body"],
};

export const RULE_OPS = ["lt", "lte", "gt", "gte", "eq", "neq", "matches", "contains"] as const;
export const RuleOp = z.enum(RULE_OPS);
export type RuleOp = z.infer<typeof RuleOp>;

export const RuleCondition = z.object({
  field: RuleField,
  op: RuleOp,
  /** A number for the numeric fields, a text (a pattern with * and ? for `matches`) otherwise. */
  value: z.union([z.number(), z.string().max(500)]),
});
export type RuleCondition = z.infer<typeof RuleCondition>;

/** Where a notice goes: the page, the person's devices (push and the app), their linked chats. */
export const RuleNotifyTo = z.enum(["page", "app", "chats"]);
export type RuleNotifyTo = z.infer<typeof RuleNotifyTo>;

export const RuleAction = z.discriminatedUnion("do", [
  z.object({
    do: z.literal("notify"),
    text: z.string().max(2000).default(""),
    to: z.array(RuleNotifyTo).optional(),
  }),
  /** Only before something runs: the person is asked (the rule alone is never a yes). */
  z.object({ do: z.literal("ask"), text: z.string().max(2000).default("") }),
  /** Only before something runs: it does not run, the agent reads why. */
  z.object({ do: z.literal("block"), text: z.string().max(2000).default("") }),
  /**
   * Stops the agents after they save: no tool starts and no model call begins until the person
   * resumes (`resume: "person"`) or the conditions stop holding (`"auto"`).
   */
  z.object({
    do: z.literal("stop"),
    text: z.string().max(2000).default(""),
    scope: z.enum(["all", "project", "agent"]).default("all"),
    resume: z.enum(["person", "auto"]).default("person"),
  }),
  /** Switches tool kits or tools off for every agent (from the next conversations, G34.5). */
  z.object({
    do: z.literal("tools_off"),
    kits: z.array(z.string().max(80)).max(40).default([]),
    tools: z.array(z.string().max(80)).max(80).default([]),
  }),
  z.object({ do: z.literal("automation"), automation: z.string().min(1).max(200) }),
  /** A command in the project's sandbox, checked as an agent's (dangers, criticalOf, no secrets). */
  z.object({
    do: z.literal("command"),
    command: z.string().max(4000),
    project: z.string().max(200).optional(),
  }),
]);
export type RuleAction = z.infer<typeof RuleAction>;
export type RuleActionKind = RuleAction["do"];

export const RuleWhen = z.object({
  event: RuleEventKind,
  /** `schedule`: a cron expression and its time zone. */
  cron: z.string().max(120).optional(),
  timezone: z.string().max(80).optional(),
});
export type RuleWhen = z.infer<typeof RuleWhen>;

/** A made-up event for the rule's test: field → value. */
export const RuleSample = z.record(z.string(), z.union([z.number(), z.string()]));
export type RuleSample = z.infer<typeof RuleSample>;

/** What the person (or God) writes: everything but the server's own fields. */
export const RuleDraft = z.object({
  name: z.string().trim().min(1).max(120),
  /** The rule in the person's words. */
  description: z.string().max(2000).default(""),
  when: RuleWhen,
  if: z.array(RuleCondition).max(20).default([]),
  actions: z.array(RuleAction).min(1).max(10),
  /** One case that must make it act and one that must not: tested before it is switched on. */
  examples: z.object({ fire: RuleSample.optional(), pass: RuleSample.optional() }).default({}),
});
export type RuleDraft = z.infer<typeof RuleDraft>;
export type RuleDraftInput = z.input<typeof RuleDraft>;

export const PersonRule = RuleDraft.extend({
  id: z.string(),
  enabled: z.boolean(),
  origin: z.enum(["person", "god", "template"]),
  /** Grows by one at each change; the history keeps every version. */
  version: z.number().int(),
  createdAt: z.string(),
  updatedAt: z.string(),
  lastFiredAt: z.string().nullable(),
});
export type PersonRule = z.infer<typeof PersonRule>;

/** One step of a rule's history: what it was after the change (null once removed). */
export const RuleVersion = z.object({
  ruleId: z.string(),
  version: z.number().int(),
  change: z.enum(["created", "changed", "enabled", "disabled", "removed", "undone"]),
  by: z.string(),
  at: z.string(),
  rule: PersonRule.nullable(),
});
export type RuleVersion = z.infer<typeof RuleVersion>;

/** A rule that acted: when, on what, and what it did. */
export const RuleFire = z.object({
  id: z.string(),
  ruleId: z.string(),
  ruleName: z.string(),
  at: z.string(),
  event: RuleEventKind,
  facts: RuleSample,
  /** What each action did, in words ("notified on page, app", "blocked", "command exited 0"). */
  results: z.array(z.string()),
});
export type RuleFire = z.infer<typeof RuleFire>;

/** A stop a rule put in place: nothing starts in its scope until it is lifted. */
export const RuleHold = z.object({
  ruleId: z.string(),
  ruleName: z.string(),
  reason: z.string(),
  at: z.string(),
  scope: z.enum(["all", "project", "agent"]),
  projectId: z.string().optional(),
  agentId: z.string().optional(),
  resume: z.enum(["person", "auto"]),
});
export type RuleHold = z.infer<typeof RuleHold>;

/** The outcome of a rule's two examples. */
export const RuleTrial = z.object({
  ok: z.boolean(),
  /** Whether the "must act" case acted, and the "must pass" case passed (null: no example). */
  fire: z.boolean().nullable(),
  pass: z.boolean().nullable(),
  problems: z.array(z.string()),
});
export type RuleTrial = z.infer<typeof RuleTrial>;

/**
 * A magic rule (3.12): a conversation with God that builds a rule. God asks what is missing,
 * tests it on the examples and proposes it; only the person's yes makes it a rule.
 */
export const MagicRule = z.object({
  id: z.string(),
  title: z.string(),
  request: z.string(),
  sessionId: z.string(),
  agentId: z.string(),
  status: z.enum(["building", "ready", "done", "dismissed"]),
  proposal: z
    .object({
      rule: RuleDraft,
      summary: z.string(),
      /** What God says is still missing, in the person's words. */
      missing: z.array(z.string()),
      trial: RuleTrial,
      at: z.string(),
    })
    .nullable(),
  ruleId: z.string().nullable(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export type MagicRule = z.infer<typeof MagicRule>;

/** Ready-made rules the person can add with one tap; none is ever on by default. */
export const RULE_TEMPLATES = {
  /**
   * The weekly subscription margin (the user's own install, 2026-11-20): warn at +5, stop at +2.
   * Margin = how much of the week has passed minus how much of it is used, in points.
   */
  "weekly-margin": [
    {
      name: { it: "Margine settimanale: avviso", en: "Weekly margin: warning" },
      draft: {
        description: "",
        when: { event: "usage" },
        if: [
          { field: "window", op: "eq", value: "7d" },
          { field: "marginPct", op: "lte", value: 5 },
        ],
        actions: [{ do: "notify", text: "" }],
        examples: {
          fire: { window: "7d", marginPct: 4, usedPct: 60 },
          pass: { window: "7d", marginPct: 12, usedPct: 50 },
        },
      },
    },
    {
      name: { it: "Margine settimanale: fermata", en: "Weekly margin: stop" },
      draft: {
        description: "",
        when: { event: "usage" },
        if: [
          { field: "window", op: "eq", value: "7d" },
          { field: "marginPct", op: "lte", value: 2 },
        ],
        actions: [
          { do: "notify", text: "" },
          { do: "stop", text: "", scope: "all", resume: "person" },
        ],
        examples: {
          fire: { window: "7d", marginPct: 1, usedPct: 70 },
          pass: { window: "7d", marginPct: 4, usedPct: 60 },
        },
      },
    },
  ],
} as const satisfies Record<
  string,
  readonly { name: { it: string; en: string }; draft: Omit<RuleDraftInput, "name"> }[]
>;
export type RuleTemplateId = keyof typeof RULE_TEMPLATES;
