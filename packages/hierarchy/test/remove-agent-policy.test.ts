// Removing an agent from the team (p3.8.9) in the permission policy, as a table. Nothing is deleted
// (the log stays, the agent can be restored), so it is never a critical request, and since 3.10
// (the person's decision of 2026-11-21) it asks nobody by default: the danger `remove-agent` stays
// on the Safety page but switched off, so in auto mode it is allowed with no request, no classifier
// and no parent. Switched back on, it is an ordinary request, human only, and the person's rules
// and modes apply to it as to any other. Plan and read-only modes still refuse it. Restoring is
// ordinary work.
import { describe, expect, it } from "vitest";
import {
  DEFAULT_DANGER_RULES,
  DEFAULT_POLICY,
  type Decision,
  evaluate,
  type PolicySettings,
  REMOVE_AGENT,
} from "../src/index.js";

const settings = (over: Partial<PolicySettings> = {}): PolicySettings => ({
  ...DEFAULT_POLICY,
  roots: ["/work/app"],
  ...over,
});

const remove = { agent_id: "agent_1", reason: "not needed any more" };
const on = DEFAULT_DANGER_RULES.map((r) => (r.id === REMOVE_AGENT ? { ...r, enabled: true } : r));

const TABLE: [
  string,
  string,
  "auto" | "manual" | "plan" | "readonly",
  Decision,
  string[],
  Partial<PolicySettings>?,
][] = [
  ["remove, auto mode", "remove_agent", "auto", "allow", []],
  ["remove, manual mode", "remove_agent", "manual", "ask", []],
  ["remove, plan mode", "remove_agent", "plan", "deny", []],
  ["remove, read-only mode", "remove_agent", "readonly", "deny", []],
  [
    "remove, a rule denies it",
    "remove_agent",
    "auto",
    "deny",
    [],
    { rules: [{ tool: "remove_agent", decision: "deny" }] },
  ],
  [
    "remove, the danger switched on, auto mode",
    "remove_agent",
    "auto",
    "ask",
    [REMOVE_AGENT],
    { danger: on },
  ],
  [
    "remove, the danger switched on, manual mode",
    "remove_agent",
    "manual",
    "ask",
    [REMOVE_AGENT],
    { danger: on },
  ],
  [
    "remove, the danger switched on, a rule allows it",
    "remove_agent",
    "auto",
    "allow",
    [REMOVE_AGENT],
    { danger: on, rules: [{ tool: "remove_agent", decision: "allow" }] },
  ],
  [
    "remove, the danger switched on, plan mode",
    "remove_agent",
    "plan",
    "deny",
    [REMOVE_AGENT],
    { danger: on },
  ],
  ["restore, auto mode", "restore_agent", "auto", "allow", []],
  ["restore, manual mode", "restore_agent", "manual", "ask", []],
  ["restore, read-only mode", "restore_agent", "readonly", "deny", []],
  ["resume, auto mode", "resume_agent", "auto", "allow", []],
  ["resume, manual mode", "resume_agent", "manual", "ask", []],
];

describe("remove_agent in the policy (p3.8.9): the table", () => {
  for (const [label, name, mode, decision, danger, over] of TABLE)
    it(`${decision}: ${label}`, () => {
      const input = name === "remove_agent" ? remove : { agent_id: "agent_1" };
      const e = evaluate(mode, { callId: "c", name, input }, settings(over));
      expect(e.decision).toBe(decision);
      expect(e.danger).toEqual(danger);
      expect(e.critical).toEqual([]);
    });

  it("is on the Safety page, switched off by default, and human only once switched on", () => {
    const rule = DEFAULT_DANGER_RULES.find((r) => r.id === REMOVE_AGENT);
    expect(rule?.enabled).toBe(false);
    expect(DEFAULT_POLICY.humanOnly).toContain(REMOVE_AGENT);
  });
});
