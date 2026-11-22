// The person's rules (3.12), as pure functions tested as a table (`person-rules.test.ts`): what is
// wrong with a rule, which rules act on an event, the subscription margin, the rule's two
// examples, and what a tool call's rules decide. A rule never grants anything: the strongest thing
// it can say about a call is "block", the mildest "ask" (which only a person can turn into a yes).
import {
  type PersonRule,
  RULE_FIELDS_BY_EVENT,
  type RuleAction,
  type RuleCondition,
  type RuleDraft,
  type RuleEventKind,
  type RuleField,
  type RuleSample,
  type RuleTrial,
} from "@redgiant/protocol";

const RULE_FIELDS = RULE_FIELDS_BY_EVENT;

const NUMERIC = new Set<RuleField>(["marginPct", "usedPct", "budgetPct"]);
const NUMERIC_OPS = new Set(["lt", "lte", "gt", "gte"]);
/** Events where something is about to run: only there can a rule ask or block. */
const BEFORE = new Set<RuleEventKind>(["tool", "file"]);
/** Events that are a level rather than a moment: a rule acts when it starts holding. */
export const CONTINUOUS = new Set<RuleEventKind>(["usage", "budget"]);

/** What is wrong with a rule, in English, one problem per line; empty when it can be saved. */
export function ruleProblems(r: RuleDraft): string[] {
  const out: string[] = [];
  const fields = RULE_FIELDS[r.when.event];
  if (r.when.event === "schedule" && !r.when.cron?.trim())
    out.push("when: a time rule needs its schedule (cron)");
  for (const c of r.if) {
    if (!fields.includes(c.field))
      out.push(`if: "${c.field}" is not known for the event "${r.when.event}"`);
    else if (NUMERIC.has(c.field) && (typeof c.value !== "number" || !Number.isFinite(c.value)))
      out.push(`if: "${c.field}" needs a number`);
    else if (NUMERIC.has(c.field) && (c.op === "matches" || c.op === "contains"))
      out.push(`if: "${c.field}" is a number: compare it (lt, lte, gt, gte, eq, neq)`);
    else if (!NUMERIC.has(c.field) && NUMERIC_OPS.has(c.op))
      out.push(`if: "${c.field}" is a text: use eq, neq, matches or contains`);
    else if (typeof c.value === "string" && !c.value.trim())
      out.push(`if: "${c.field}" needs a value`);
  }
  for (const a of r.actions) {
    if ((a.do === "ask" || a.do === "block") && !BEFORE.has(r.when.event))
      out.push(`actions: "${a.do}" works only before something runs (a tool, a command, a file)`);
    if (a.do === "command" && !a.command.trim()) out.push("actions: the command is empty");
    if (a.do === "tools_off" && a.kits.length === 0 && a.tools.length === 0)
      out.push("actions: say which tools or kits to switch off");
  }
  const kinds = r.actions.map((a) => a.do);
  if (kinds.includes("ask") && kinds.includes("block"))
    out.push("actions: a rule either asks or blocks, not both");
  return out;
}

/** A pattern with * (anything) and ? (one character), whole text, case not counted. */
export function globMatch(pattern: string, text: string): boolean {
  const re = pattern
    .split("")
    .map((ch) => (ch === "*" ? ".*" : ch === "?" ? "." : ch.replace(/[\\^$.|+()[\]{}]/g, "\\$&")))
    .join("");
  return new RegExp(`^${re}$`, "is").test(text);
}

/** Whether one condition holds on the facts; a fact that is not there never holds. */
export function conditionHolds(c: RuleCondition, facts: RuleSample): boolean {
  const v = facts[c.field];
  if (v === undefined) return false;
  if (NUMERIC.has(c.field)) {
    const n = typeof v === "number" ? v : Number(v);
    const want = typeof c.value === "number" ? c.value : Number(c.value);
    if (!Number.isFinite(n) || !Number.isFinite(want)) return false;
    switch (c.op) {
      case "lt":
        return n < want;
      case "lte":
        return n <= want;
      case "gt":
        return n > want;
      case "gte":
        return n >= want;
      case "eq":
        return n === want;
      case "neq":
        return n !== want;
      default:
        return false;
    }
  }
  const text = String(v);
  const want = String(c.value);
  switch (c.op) {
    case "eq":
      return text.toLowerCase() === want.toLowerCase();
    case "neq":
      return text.toLowerCase() !== want.toLowerCase();
    case "matches":
      return globMatch(want, text);
    case "contains":
      return text.toLowerCase().includes(want.toLowerCase());
    default:
      return false;
  }
}

/** Whether a rule's conditions all hold on an event's facts (enabled or not). */
export function ruleHolds(r: Pick<RuleDraft, "if">, facts: RuleSample): boolean {
  return r.if.every((c) => conditionHolds(c, facts));
}

/**
 * The rules that act on an event. `active` holds the rules (by `id` + `key`) whose conditions
 * held at the last reading of a continuous event: those act once when they start holding and
 * again only after they stopped. The new set is returned, with the rules that stopped holding
 * (a stop with `resume: "auto"` is lifted then).
 */
export function fireRules<R extends Pick<PersonRule, "id" | "enabled" | "when" | "if">>(
  rules: readonly R[],
  event: RuleEventKind,
  facts: RuleSample,
  active: ReadonlySet<string> = new Set(),
  key = "",
): { fired: R[]; active: Set<string>; released: R[] } {
  const next = new Set(active);
  const fired: R[] = [];
  const released: R[] = [];
  for (const r of rules) {
    if (!r.enabled || r.when.event !== event) continue;
    const holds = ruleHolds(r, facts);
    if (!CONTINUOUS.has(event)) {
      if (holds) fired.push(r);
      continue;
    }
    const k = `${r.id}\u0000${key}`;
    if (holds && !active.has(k)) {
      fired.push(r);
      next.add(k);
    } else if (!holds && active.has(k)) {
      next.delete(k);
      released.push(r);
    }
  }
  return { fired, active: next, released };
}

/** What the rules that acted on a tool call decide: block wins over ask. */
export function toolVerdict(fired: readonly Pick<PersonRule, "name" | "actions">[]): {
  decision: "run" | "ask" | "block";
  reasons: string[];
} {
  const reasons = (kind: "ask" | "block") =>
    fired.flatMap((r) =>
      r.actions
        .filter((a): a is Extract<RuleAction, { do: typeof kind }> => a.do === kind)
        .map((a) => (a.text.trim() ? `«${r.name}»: ${a.text.trim()}` : `«${r.name}»`)),
    );
  const block = reasons("block");
  if (block.length) return { decision: "block", reasons: block };
  const ask = reasons("ask");
  if (ask.length) return { decision: "ask", reasons: ask };
  return { decision: "run", reasons: [] };
}

/** How long a subscription window lasts: 5 hours, otherwise a week (also the per-model ones). */
export function windowLengthMs(id: string): number {
  return id === "5h" ? 5 * 3_600_000 : 7 * 24 * 3_600_000;
}

/**
 * The margin of a subscription window, in points: how much of the window has passed minus how
 * much of it is used (+31: well ahead; 0: on pace; negative: spending faster than time). Undefined
 * without a reset time.
 */
export function windowMargin(
  w: { id: string; usedPct: number; resetsAt?: string | undefined },
  now: number,
): number | undefined {
  if (!w.resetsAt) return undefined;
  const reset = Date.parse(w.resetsAt);
  if (!Number.isFinite(reset)) return undefined;
  const len = windowLengthMs(w.id);
  const left = Math.min(Math.max(reset - now, 0), len);
  const passedPct = (1 - left / len) * 100;
  return Math.round((passedPct - w.usedPct) * 10) / 10;
}

/** The facts of a tool call: its name, the command it runs, the path it touches. */
export function toolFacts(
  call: { name: string; input: unknown },
  where: { project?: string | undefined; agent?: string | undefined } = {},
): { facts: RuleSample; writes: boolean } {
  const input = (call.input ?? {}) as Record<string, unknown>;
  const name = call.name.toLowerCase();
  const facts: RuleSample = { tool: call.name };
  if (where.project) facts.project = where.project;
  if (where.agent) facts.agent = where.agent;
  if (typeof input.command === "string") facts.command = input.command;
  const path =
    typeof input.path === "string"
      ? input.path
      : typeof input.file_path === "string"
        ? input.file_path
        : undefined;
  if (path) facts.path = path;
  const writes =
    path !== undefined &&
    [
      "write_file",
      "edit_file",
      "edit_package",
      "canvas_edit",
      "write",
      "edit",
      "multiedit",
    ].includes(name);
  return { facts, writes };
}

/** The rule's two examples: the "act" case must act, the "pass" case must not. */
export function tryExamples(r: RuleDraft): RuleTrial {
  const problems = ruleProblems(r);
  // No conditions: it acts on every such event (or at every time); there is no case to pass.
  if (r.if.length === 0) return { ok: problems.length === 0, fire: true, pass: null, problems };
  const fire = r.examples.fire ? ruleHolds(r, r.examples.fire) : null;
  const pass = r.examples.pass ? !ruleHolds(r, r.examples.pass) : null;
  if (fire === null) problems.push("examples: add a case where the rule must act");
  else if (!fire) problems.push("examples: the case where it must act does not make it act");
  if (pass === null) problems.push("examples: add a case where the rule must not act");
  else if (!pass) problems.push("examples: the case where it must not act makes it act");
  return { ok: problems.length === 0, fire, pass, problems };
}

/**
 * Whether a rule could give anything the person has not: never, by construction (no action
 * allows). Kept as a function so a new action kind has to say so here, in the table.
 */
export const GRANTS: Record<RuleAction["do"], false> = {
  notify: false,
  ask: false,
  block: false,
  stop: false,
  tools_off: false,
  automation: false,
  command: false,
};
