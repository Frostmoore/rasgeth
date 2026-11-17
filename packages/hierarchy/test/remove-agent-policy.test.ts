// Removing an agent from the team (p3.8.9) in the permission policy, as a table. Nothing is deleted
// (the log stays, the agent can be restored), so it is an ordinary request, never a critical one:
// the danger `remove-agent`, on the Safety page, human only by default, and the person's rules and
// modes apply to it as to any other (an allow rule, the danger switched off, «don't ask me
// anything» with the classifier). Restoring is ordinary work.
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
const off = DEFAULT_DANGER_RULES.map((r) => (r.id === REMOVE_AGENT ? { ...r, enabled: false } : r));

const TABLE: [
  string,
  string,
  "auto" | "manual" | "plan" | "readonly",
  Decision,
  string[],
  Partial<PolicySettings>?,
][] = [
  ["remove, auto mode", "remove_agent", "auto", "ask", [REMOVE_AGENT]],
  ["remove, manual mode", "remove_agent", "manual", "ask", [REMOVE_AGENT]],
  [
    "remove, a rule allows it",
    "remove_agent",
    "auto",
    "allow",
    [REMOVE_AGENT],
    { rules: [{ tool: "remove_agent", decision: "allow" }] },
  ],
  [
    "remove, a rule denies it",
    "remove_agent",
    "auto",
    "deny",
    [REMOVE_AGENT],
    { rules: [{ tool: "remove_agent", decision: "deny" }] },
  ],
  ["remove, the danger switched off", "remove_agent", "auto", "allow", [], { danger: off }],
  ["remove, plan mode", "remove_agent", "plan", "deny", [REMOVE_AGENT]],
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

  it("is on the Safety page and human only by default: parent agents never answer it", () => {
    expect(DEFAULT_DANGER_RULES.map((r) => r.id)).toContain(REMOVE_AGENT);
    expect(DEFAULT_POLICY.humanOnly).toContain(REMOVE_AGENT);
  });
});
