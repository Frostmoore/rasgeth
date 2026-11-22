// The person's rules (3.12) as tables: conditions, which rules act, the margin, the examples and
// what rules decide about a tool call. A rule never says "allow": the table of GRANTS is all false.
import { RuleDraft, type RuleDraftInput, type RuleSample } from "@redgiant/protocol";
import { describe, expect, it } from "vitest";
import {
  budgetPct,
  conditionHolds,
  fireRules,
  GRANTS,
  globMatch,
  ruleProblems,
  toolFacts,
  toolVerdict,
  tryExamples,
  webhookFacts,
  windowMargin,
} from "../src/index.js";

const draft = (d: Partial<RuleDraftInput> & Pick<RuleDraftInput, "when" | "actions">) =>
  RuleDraft.parse({ name: "r", ...d });

describe("conditions", () => {
  const cases: [string, Parameters<typeof conditionHolds>[0], RuleSample, boolean][] = [
    ["lte holds", { field: "marginPct", op: "lte", value: 5 }, { marginPct: 5 }, true],
    ["lte fails", { field: "marginPct", op: "lte", value: 5 }, { marginPct: 5.1 }, false],
    ["lt", { field: "marginPct", op: "lt", value: 2 }, { marginPct: -3 }, true],
    ["gt", { field: "usedPct", op: "gt", value: 90 }, { usedPct: 91 }, true],
    ["gte", { field: "budgetPct", op: "gte", value: 80 }, { budgetPct: 79 }, false],
    ["number eq", { field: "usedPct", op: "eq", value: 50 }, { usedPct: 50 }, true],
    ["number from text", { field: "usedPct", op: "gt", value: 10 }, { usedPct: "12" }, true],
    ["missing fact never holds", { field: "marginPct", op: "lte", value: 5 }, {}, false],
    ["missing fact, neq", { field: "tool", op: "neq", value: "bash" }, {}, false],
    ["text eq, case", { field: "window", op: "eq", value: "7D" }, { window: "7d" }, true],
    ["text neq", { field: "tool", op: "neq", value: "bash" }, { tool: "read_file" }, true],
    [
      "glob",
      { field: "command", op: "matches", value: "git push*" },
      { command: "git push origin main" },
      true,
    ],
    [
      "glob is whole",
      { field: "command", op: "matches", value: "push*" },
      { command: "git push" },
      false,
    ],
    ["glob ?", { field: "path", op: "matches", value: "a?c" }, { path: "abc" }, true],
    [
      "glob dots are dots",
      { field: "path", op: "matches", value: "*.env" },
      { path: "x/aenv" },
      false,
    ],
    [
      "contains",
      { field: "command", op: "contains", value: "RM -RF" },
      { command: "sudo rm -rf /" },
      true,
    ],
    ["text with a number op", { field: "tool", op: "gt", value: "a" }, { tool: "b" }, false],
  ];
  it.each(cases)("%s", (_n, c, facts, want) => expect(conditionHolds(c, facts)).toBe(want));
  it("a glob has no regular expressions in it", () => {
    expect(globMatch("(a+)+$", "aaaa")).toBe(false);
    expect(globMatch("(a+)+$", "(a+)+$")).toBe(true);
  });
});

describe("problems", () => {
  const cases: [string, RuleDraft, string | null][] = [
    [
      "the margin warning is fine",
      draft({
        when: { event: "usage" },
        if: [{ field: "marginPct", op: "lte", value: 5 }],
        actions: [{ do: "notify" }],
      }),
      null,
    ],
    [
      "ask on a usage event",
      draft({ when: { event: "usage" }, actions: [{ do: "ask" }] }),
      'actions: "ask" works only before something runs',
    ],
    [
      "block on a schedule",
      draft({ when: { event: "schedule", cron: "0 9 * * *" }, actions: [{ do: "block" }] }),
      'actions: "block" works only',
    ],
    [
      "schedule without cron",
      draft({ when: { event: "schedule" }, actions: [{ do: "notify" }] }),
      "cron",
    ],
    [
      "a field the event lacks",
      draft({
        when: { event: "agent_done" },
        if: [{ field: "command", op: "contains", value: "x" }],
        actions: [{ do: "notify" }],
      }),
      'if: "command" is not known',
    ],
    [
      "a number field with text",
      draft({
        when: { event: "usage" },
        if: [{ field: "marginPct", op: "lte", value: "five" }],
        actions: [{ do: "notify" }],
      }),
      "needs a number",
    ],
    [
      "a text field with lt",
      draft({
        when: { event: "tool" },
        if: [{ field: "tool", op: "lt", value: "x" }],
        actions: [{ do: "block" }],
      }),
      "is a text",
    ],
    [
      "an empty command",
      draft({ when: { event: "agent_done" }, actions: [{ do: "command", command: " " }] }),
      "the command is empty",
    ],
    [
      "tools_off with nothing",
      draft({ when: { event: "usage" }, actions: [{ do: "tools_off" }] }),
      "which tools",
    ],
    [
      "ask and block together",
      draft({ when: { event: "tool" }, actions: [{ do: "ask" }, { do: "block" }] }),
      "either asks or blocks",
    ],
    [
      "block on a file is fine",
      draft({
        when: { event: "file" },
        if: [{ field: "path", op: "matches", value: "*.env" }],
        actions: [{ do: "block" }],
      }),
      null,
    ],
  ];
  it.each(cases)("%s", (_n, r, want) => {
    const p = ruleProblems(r);
    if (want === null) expect(p).toEqual([]);
    else expect(p.join("\n")).toContain(want);
  });
  it("there is no allow action", () => {
    expect(() => draft({ when: { event: "tool" }, actions: [{ do: "allow" } as never] })).toThrow();
    expect(Object.values(GRANTS).every((g) => g === false)).toBe(true);
  });
});

describe("which rules act", () => {
  const margin = (id: string, at: number, enabled = true) => ({
    id,
    enabled,
    when: { event: "usage" as const },
    if: [
      { field: "window" as const, op: "eq" as const, value: "7d" },
      { field: "marginPct" as const, op: "lte" as const, value: at },
    ],
  });
  const warn = margin("warn", 5);
  const stop = margin("stop", 2);
  it("a level acts once when it starts holding, again after it stopped", () => {
    const rules = [warn, stop];
    const steps: [number, string[], string[]][] = [
      [10, [], []],
      [5, ["warn"], []],
      [4, [], []],
      [1, ["stop"], []],
      [0, [], []],
      [3, [], ["stop"]],
      [8, [], ["warn"]],
      [4, ["warn"], []],
    ];
    let active = new Set<string>();
    for (const [m, fired, released] of steps) {
      const r = fireRules(rules, "usage", { window: "7d", marginPct: m }, active, "claude/7d");
      expect([m, r.fired.map((x) => x.id)]).toEqual([m, fired]);
      expect([m, r.released.map((x) => x.id)]).toEqual([m, released]);
      active = r.active;
    }
  });
  it("other windows and switched-off rules do nothing", () => {
    expect(fireRules([warn], "usage", { window: "5h", marginPct: 0 }).fired).toEqual([]);
    expect(
      fireRules([margin("x", 5, false)], "usage", { window: "7d", marginPct: 0 }).fired,
    ).toEqual([]);
    expect(fireRules([warn], "tool", { window: "7d", marginPct: 0 }).fired).toEqual([]);
  });
  it("a moment acts every time", () => {
    const push = {
      id: "push",
      enabled: true,
      when: { event: "tool" as const },
      if: [{ field: "command" as const, op: "matches" as const, value: "git push*" }],
    };
    const facts = { tool: "bash", command: "git push" };
    expect(fireRules([push], "tool", facts).fired).toHaveLength(1);
    expect(fireRules([push], "tool", facts).fired).toHaveLength(1);
  });
});

describe("tool verdict", () => {
  const r = (name: string, actions: RuleDraftInput["actions"]) =>
    draft({ name, when: { event: "tool" }, actions });
  const cases: [string, ReturnType<typeof r>[], "run" | "ask" | "block"][] = [
    ["nothing acted", [], "run"],
    ["only a notice", [r("a", [{ do: "notify" }])], "run"],
    ["ask", [r("a", [{ do: "ask", text: "sure?" }])], "ask"],
    ["block wins over ask", [r("a", [{ do: "ask" }]), r("b", [{ do: "block" }])], "block"],
  ];
  it.each(cases)("%s", (_n, fired, want) => expect(toolVerdict(fired).decision).toBe(want));
  it("says which rule and why", () => {
    expect(toolVerdict([r("No push", [{ do: "block", text: "not today" }])]).reasons).toEqual([
      "«No push»: not today",
    ]);
  });
});

describe("budget use", () => {
  const cases: [
    string,
    Parameters<typeof budgetPct>[0],
    Parameters<typeof budgetPct>[1],
    number | undefined,
  ][] = [
    ["money", { usd: 8, tokens: 0 }, { usd: 10 }, 80],
    ["tokens", { usd: 0, tokens: 500 }, { tokens: 2000 }, 25],
    ["the larger of both", { usd: 9, tokens: 100 }, { usd: 10, tokens: 1000 }, 90],
    ["over the limit", { usd: 12, tokens: 0 }, { usd: 10 }, 120],
    ["no limit", { usd: 5, tokens: 5 }, {}, undefined],
    ["a zero limit compares nothing", { usd: 5, tokens: 0 }, { usd: 0 }, undefined],
  ];
  it.each(cases)("%s", (_n, used, limit, want) => expect(budgetPct(used, limit)).toBe(want));
});

describe("webhook", () => {
  it("the body is data to match, cut, never more", () => {
    expect(webhookFacts({ amount: 120 })).toEqual({ body: '{"amount":120}' });
    expect(webhookFacts("x".repeat(9000)).body).toHaveLength(8000);
    const r = draft({
      when: { event: "webhook" },
      if: [{ field: "body", op: "contains", value: "failed" }],
      actions: [{ do: "notify" }],
    });
    expect(ruleProblems(r)).toEqual([]);
    expect(conditionHolds(r.if[0] as never, webhookFacts({ status: "FAILED" }))).toBe(true);
    // Nothing runs before a webhook: it cannot ask or block.
    expect(
      ruleProblems(draft({ when: { event: "webhook" }, actions: [{ do: "block" }] })).join(),
    ).toContain("works only before something runs");
  });
});

describe("margin", () => {
  const now = Date.parse("2026-11-22T12:00:00Z");
  const week = 7 * 24 * 3_600_000;
  const cases: [string, Parameters<typeof windowMargin>[0], number | undefined][] = [
    // 4.7 days of 7 passed (67%), 36% used: +31 (the user's reading of 2026-11-22).
    [
      "the 22/11 reading",
      { id: "7d", usedPct: 36, resetsAt: new Date(now + 0.33 * week).toISOString() },
      31,
    ],
    ["just reset", { id: "7d", usedPct: 0, resetsAt: new Date(now + week).toISOString() }, 0],
    ["late, all used", { id: "7d", usedPct: 100, resetsAt: new Date(now).toISOString() }, 0],
    [
      "spending ahead of time",
      { id: "7d", usedPct: 60, resetsAt: new Date(now + 0.5 * week).toISOString() },
      -10,
    ],
    [
      "five hours",
      { id: "5h", usedPct: 20, resetsAt: new Date(now + 2.5 * 3_600_000).toISOString() },
      30,
    ],
    ["no reset time", { id: "7d", usedPct: 20 }, undefined],
  ];
  it.each(cases)("%s", (_n, w, want) => expect(windowMargin(w, now)).toBe(want));
});

describe("tool facts", () => {
  it("reads the command and the path", () => {
    expect(toolFacts({ name: "bash", input: { command: "ls" } }, { agent: "Ada" })).toEqual({
      facts: { tool: "bash", command: "ls", agent: "Ada" },
      writes: false,
    });
    expect(toolFacts({ name: "write_file", input: { path: "a/.env" } }).writes).toBe(true);
    expect(toolFacts({ name: "Edit", input: { file_path: "a.ts" } }).facts.path).toBe("a.ts");
    expect(toolFacts({ name: "read_file", input: { path: "a.ts" } }).writes).toBe(false);
  });
});

describe("examples", () => {
  const base = {
    when: { event: "usage" as const },
    if: [{ field: "marginPct" as const, op: "lte" as const, value: 5 }],
    actions: [{ do: "notify" as const }],
  };
  const cases: [string, RuleDraftInput["examples"], boolean, string | null][] = [
    ["both right", { fire: { marginPct: 3 }, pass: { marginPct: 9 } }, true, null],
    ["no examples", {}, false, "add a case where the rule must act"],
    [
      "fire does not fire",
      { fire: { marginPct: 9 }, pass: { marginPct: 10 } },
      false,
      "does not make it act",
    ],
    ["pass fires", { fire: { marginPct: 1 }, pass: { marginPct: 2 } }, false, "makes it act"],
  ];
  it.each(cases)("%s", (_n, examples, ok, problem) => {
    const t = tryExamples(draft({ ...base, examples }));
    expect(t.ok).toBe(ok);
    if (problem) expect(t.problems.join("\n")).toContain(problem);
  });
  it("a rule without conditions has no case to pass", () => {
    const t = tryExamples(
      draft({ when: { event: "schedule", cron: "0 9 * * 1" }, actions: [{ do: "notify" }] }),
    );
    expect(t).toEqual({ ok: true, fire: true, pass: null, problems: [] });
  });
});
