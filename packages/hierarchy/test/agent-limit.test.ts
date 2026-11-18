// The project's agent limit (2026-11-18, decision «Limite di sotto-agenti per progetto»), as a
// table: what counts toward it, and whether more fit. The rule: besides the orchestrator, a
// project may have at most N agents (default 3, 0 = the orchestrator alone, at most 10). The
// project's own agents count, working or stopped (a stop is a pause), and so do the sub-agents at
// work now; the orchestrator, the inspectors, agents assigned from other projects, removed agents
// and sub-agents whose task ended do not. Lowering the limit removes nobody: it refuses new ones.
import { PROJECT_AGENTS_DEFAULT, PROJECT_AGENTS_MAX, ProjectMaxAgents } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import { agentRoom, countsTowardAgentLimit, type LimitNode } from "../src/index.js";

const a = (
  kind: LimitNode["kind"],
  status: LimitNode["status"] = "active",
  projectId: string | null = "p1",
): LimitNode => ({ kind, status, projectId });

const COUNTS: [string, LimitNode, boolean][] = [
  ["the orchestrator", a("orchestrator"), false],
  ["an agent at work", a("agent"), true],
  ["a stopped agent (a pause)", a("agent", "stopped"), true],
  ["a removed agent", a("agent", "removed"), false],
  ["a sub-agent at work", a("subagent"), true],
  ["a sub-agent whose task ended", a("subagent", "stopped"), false],
  ["a removed sub-agent", a("subagent", "removed"), false],
  ["the project's inspector", a("inspector"), false],
  ["an agent of another project (assigned here or not)", a("agent", "active", "p2"), false],
  ["God", a("god", "active", null), false],
  ["an assistant", a("assistant", "active", null), false],
];

describe("what counts toward a project's agent limit: the table", () => {
  it.each(COUNTS)("%s", (_, node, counts) => {
    expect(countsTowardAgentLimit(node, "p1")).toBe(counts);
  });
});

const team = (n: number, extra: LimitNode[] = []): LimitNode[] => [
  a("orchestrator"),
  a("inspector"),
  ...Array.from({ length: n }, () => a("agent")),
  ...extra,
];

const ROOM: [string, LimitNode[], number, number, boolean, number][] = [
  // [case, team, max, adding, ok, count]
  ["empty project, default limit", team(0), 3, 1, true, 0],
  ["two of three, one more", team(2), 3, 1, true, 2],
  ["three of three, one more", team(3), 3, 1, false, 3],
  ["limit 0: the orchestrator alone", team(0), 0, 1, false, 0],
  ["three of three, nothing new (a restart, a check)", team(3), 3, 0, true, 3],
  ["five over a lowered limit of 2: nobody removed, none new", team(5), 2, 0, true, 5],
  ["five over a lowered limit of 2, one more", team(5), 2, 1, false, 5],
  ["the limit raised to 6 over five", team(5), 6, 1, true, 5],
  ["a sub-agent at work counts", team(2, [a("subagent")]), 3, 1, false, 3],
  ["a finished sub-agent does not", team(2, [a("subagent", "stopped")]), 3, 1, true, 2],
  ["several at once, all fit", team(1), 4, 3, true, 1],
  ["several at once, one too many: none", team(1), 4, 4, false, 1],
  ["removed agents leave room", team(2, [a("agent", "removed")]), 3, 1, true, 2],
];

describe("whether more agents fit in a project: the table", () => {
  it.each(ROOM)("%s", (_, list, max, adding, ok, count) => {
    expect(agentRoom(list, "p1", max, adding)).toEqual({ ok, count, max });
  });

  it("the default is 3, the range 0 to 10", () => {
    expect(PROJECT_AGENTS_DEFAULT).toBe(3);
    expect(PROJECT_AGENTS_MAX).toBe(10);
    expect(ProjectMaxAgents.safeParse(0).success).toBe(true);
    expect(ProjectMaxAgents.safeParse(10).success).toBe(true);
    expect(ProjectMaxAgents.safeParse(11).success).toBe(false);
    expect(ProjectMaxAgents.safeParse(-1).success).toBe(false);
    expect(ProjectMaxAgents.safeParse(2.5).success).toBe(false);
  });
});
