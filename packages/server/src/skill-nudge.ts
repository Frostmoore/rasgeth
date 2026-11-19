// Skills that come by themselves (G36.8): after a problem solved, the agent proposes a skill
// (instructions and, when useful, scripts) with a short account of what worked. Two parts:
//   - `SKILL_PROMPT`, in the system prompt of every agent that can propose (fixed for the session);
//   - `SkillNudge`, a postToolUse hook that, once per conversation and only after real effort (a
//     task closed by a verifier after many steps, or a success after several failures), adds one
//     line to that tool's result. Never a message of its own, never a question to the person: the
//     prompt prefix stays the same and the person only sees the proposal, in Extensions.
// 3.9.7, skills that improve with use: after a skill was loaded, friction (attempts failing after
// it, the person correcting the agent, or saying the skill could be better) adds one line, once
// per skill and conversation, asking for a new version of that skill (`frictionOf`, a table).

import type { Hooks } from "@redgiant/agent";
import { PRODUCT_NAME } from "@redgiant/protocol";

export const SKILL_PROMPT = [
  "## Skills from solved problems",
  "When you solve a problem in a way that was not obvious (it took several attempts, a workaround, a fact you had to " +
    "find out) and it is likely to come up again, propose a skill once the work is done: propose_extension with kind " +
    '"skill", short instructions in body, helper scripts as files with tests, and summary (two or three lines: the ' +
    "problem and what worked). First look with skill_search: if a skill already covers it, propose an update to that " +
    "skill (its name, updates true) instead of a new one. Not for routine work, one-off details or facts about the " +
    "person (those belong in memory). Never ask the person about it: the proposal waits for them in Extensions.",
  "When a skill you followed turned out wrong or incomplete (you had to retry, the person corrected you, or they said " +
    "it could be better), propose a new version of it once the work is done: its name, updates true, the improved body, " +
    "change (what the new version changes, one short line) and summary saying what went wrong. The person approves it " +
    "reading those two. At most one proposal per conversation, and only when it would really help the next time.",
].join("\n");

/** How much effort makes a nudge worth it. */
export const NUDGE = {
  /** Failed tool results after a skill_load, in the same turn, before the skill is in doubt. */
  skillFailures: 2,
  /** Failed tool results in one turn before a success counts as a struggle. */
  failures: 3,
  /** Steps in one turn before a verified task counts as non-trivial. */
  taskCalls: 8,
  /** Failures in one turn before a verified task counts as non-trivial. */
  taskFailures: 2,
} as const;

/** Tools whose success says nothing about a problem being solved. */
const QUIET = new Set([
  "ask_user",
  "propose_plan",
  "conversation_history",
  "memory",
  "skill_search",
  "skill_file",
  "skill_load",
]);

interface SessionState {
  calls: number;
  failures: number;
  nudged: boolean;
  proposed: boolean;
  loaded: Set<string>;
  /** The skill loaded last, and the failures since (this turn). */
  lastSkill?: string;
  afterLoad: number;
  /** The person's words this turn put the skill in doubt (3.9.7). */
  doubt?: Friction;
  /** Skills already nudged about in this conversation. */
  frictionNudged: Set<string>;
}

/** What the person's words say about the agent's work: a correction, or the skill itself. */
export type Friction = "correction" | "skill";

/** A whole word: no letter or digit right before or after (`\b` does not know «à»). */
const word = (re: string) => String.raw`(?<![\p{L}\p{N}])${re}(?![\p{L}\p{N}])`;
const SKILL_WORD = word(String.raw`(?:skill|skills|abilità|abilita)`);
const BETTER = word(
  String.raw`(?:migliorar\p{L}*|miglior\p{L}*|meglio|better|improv\p{L}*|aggiorn\p{L}*|updat\p{L}*|sbagliat\p{L}*|wrong|manc\p{L}*|missing|incomplet\p{L}*|outdated|vecchi\p{L}*|corregg\p{L}*|fix\p{L}*)`,
);
const ABOUT_SKILL = [
  new RegExp(String.raw`${SKILL_WORD}[^.!?\n]{0,60}?${BETTER}`, "iu"),
  new RegExp(String.raw`${BETTER}[^.!?\n]{0,40}?${SKILL_WORD}`, "iu"),
];
/** How a correction starts, in Italian and English. */
const CORRECTION = new RegExp(
  String.raw`^\s*(?:no(?:\s*[,.!]|\s+(?:così|non|aspetta|wait|that|it)(?![\p{L}]))|${word(String.raw`(?:non\s+(?:è|e'|era|va|funziona)|sbagliat\p{L}*|hai\s+sbagliato|ti\s+sei\s+sbagliat\p{L}*|ma\s+no|guarda\s+che|in\s+realtà|wrong|that'?s\s+(?:not|wrong)|not\s+(?:what|like\s+that|right)|actually|nope)`)})`,
  "iu",
);

/**
 * What the person's message says about the work done with a skill (3.9.7): "skill" when they say
 * the skill could be better, "correction" when they correct the agent, nothing otherwise.
 */
export function frictionOf(text: string | undefined): Friction | undefined {
  if (!text?.trim()) return undefined;
  if (ABOUT_SKILL.some((re) => re.test(text))) return "skill";
  if (CORRECTION.test(text)) return "correction";
  return undefined;
}

/** The line asking for a new version of a skill (exported for the tests). */
export function frictionText(o: {
  skill: string;
  why: "failures" | Friction;
  failures: number;
}): string {
  const what =
    o.why === "failures"
      ? `${o.failures} attempts failed after you loaded the skill "${o.skill}".`
      : o.why === "correction"
        ? `The person corrected you after you followed the skill "${o.skill}".`
        : `The person said the skill "${o.skill}" could be better.`;
  return `\n\n[${PRODUCT_NAME}] ${what} Once this works, if the skill was wrong or missed a step, propose a new version of it: propose_extension with kind "skill", name "${o.skill}", updates true, the improved body, change (what it changes, one short line) and summary saying what went wrong. If the skill was not the cause, ignore this; do not mention it to the person.`;
}

/** The text added to the result (exported for the tests). */
export function nudgeText(o: { failures: number; task: boolean; loaded: string[] }): string {
  const what = o.task
    ? "The task is verified."
    : `That worked after ${o.failures} failed attempts.`;
  const update =
    o.loaded.length > 0
      ? ` You used the skill ${o.loaded.map((n) => `"${n}"`).join(", ")}: if it lacked what you found out, propose an update to it (same name, updates true) instead of a new skill.`
      : " Check skill_search first: if a skill covers it, propose an update to it instead.";
  return `\n\n[${PRODUCT_NAME}] ${what} If the way you solved it was not obvious and would help again, propose a skill when you are done (propose_extension, kind "skill", with summary).${update} If it was routine, ignore this; do not mention it to the person.`;
}

/**
 * Watches each conversation's tool results and nudges at most once per conversation (G36.8).
 * The counts start again with each turn of the person (`turnStarted`).
 */
export class SkillNudge {
  private readonly sessions = new Map<string, SessionState>();

  constructor(private readonly limit = 2000) {}

  private state(sessionId: string): SessionState {
    let s = this.sessions.get(sessionId);
    if (!s) {
      s = {
        calls: 0,
        failures: 0,
        nudged: false,
        proposed: false,
        loaded: new Set(),
        afterLoad: 0,
        frictionNudged: new Set(),
      };
      this.sessions.set(sessionId, s);
      // Old conversations are forgotten first: a nudge more after a long while does no harm.
      if (this.sessions.size > this.limit) {
        const oldest = this.sessions.keys().next().value;
        if (oldest !== undefined) this.sessions.delete(oldest);
      }
    }
    return s;
  }

  /**
   * A new turn: the effort is counted again from here. `personSaid`: the person's own words, when
   * they started it (3.9.7: a correction after a skill puts the skill in doubt).
   */
  turnStarted(sessionId: string, personSaid?: string): void {
    const s = this.sessions.get(sessionId);
    if (s) {
      s.calls = 0;
      s.failures = 0;
      s.afterLoad = 0;
      delete s.doubt;
      if (s.lastSkill) {
        const f = frictionOf(personSaid);
        if (f) s.doubt = f;
      }
    }
  }

  /** The postToolUse hook for one agent's conversations. */
  hook(): NonNullable<Hooks["postToolUse"]>[number] {
    return (call, result, ctx) => {
      const s = this.state(ctx.sessionId);
      if (call.name === "propose_extension") {
        s.proposed = true;
        return undefined;
      }
      if (call.name === "skill_load" && !result.isError) {
        const name = (call.input as { name?: unknown } | undefined)?.name;
        if (typeof name === "string") {
          s.loaded.add(name);
          s.lastSkill = name;
          s.afterLoad = 0;
        }
      }
      if (QUIET.has(call.name)) return undefined;
      s.calls++;
      if (result.isError) {
        s.failures++;
        if (s.lastSkill) s.afterLoad++;
        return undefined;
      }
      if (s.proposed) return undefined;
      // 3.9.7: friction after a skill asks for a new version of it, once per skill.
      const skill = s.lastSkill;
      if (skill && !s.frictionNudged.has(skill)) {
        const why =
          s.doubt ?? (s.afterLoad >= NUDGE.skillFailures ? ("failures" as const) : undefined);
        if (why) {
          s.frictionNudged.add(skill);
          s.nudged = true;
          delete s.doubt;
          return {
            content: result.content + frictionText({ skill, why, failures: s.afterLoad }),
            isError: false,
          };
        }
      }
      if (s.nudged) return undefined;
      const verified =
        call.name === "complete_task" && /^Verified:/.test(result.content.trimStart());
      const task = verified && (s.calls >= NUDGE.taskCalls || s.failures >= NUDGE.taskFailures);
      const struggle = !verified && s.failures >= NUDGE.failures;
      if (!task && !struggle) return undefined;
      s.nudged = true;
      return {
        content:
          result.content + nudgeText({ failures: s.failures, task, loaded: [...s.loaded].sort() }),
        isError: false,
      };
    };
  }
}
