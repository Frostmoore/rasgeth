// The person's rules (3.12) on a real server (PGlite, FakeProvider): saving, the examples before
// switching on, history and undo, a rule that blocks a command, one that asks (only the person,
// never a yes on no answer), the weekly margin (warn at +5, stop at +2, resume), a rule's command
// checked as God's own, and the magic rule built with God.
import { access, readFile } from "node:fs/promises";
import { join } from "node:path";
import type { MagicRule, PersonRule, RuleHold, RuleTrial } from "@redgiant/protocol";
import type { CompletionRequest } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const until = async (ok: () => boolean | Promise<boolean>) => {
  for (let i = 0; i < 200; i++) {
    if (await ok()) return;
    await new Promise((r) => setTimeout(r, 25));
  }
  throw new Error("timed out");
};

const toolResults = (req: CompletionRequest | undefined) =>
  (req?.messages ?? []).flatMap((m) =>
    m.parts.flatMap((p) => (p.type === "tool_result" ? [String(p.content)] : [])),
  );

async function god(server: Server) {
  return (
    await server.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    })
  ).body.id;
}

const NO_PUSH = {
  name: "No push",
  when: { event: "tool" },
  if: [{ field: "command", op: "matches", value: "git push*" }],
  actions: [{ do: "block", text: "not on Sundays" }],
  examples: { fire: { command: "git push origin main" }, pass: { command: "git status" } },
};

describe("rules: saving, examples, history and undo", () => {
  it("switch on only with passing examples; every change can be undone", async () => {
    s = await startServer(() => ({ text: "ok" }));
    const api = s.api;
    const bad = await api<{ error: string }>("POST", "/api/rules", {
      rule: { ...NO_PUSH, when: { event: "usage" } },
    });
    expect(bad.status).toBe(400);
    expect(bad.body.error).toContain("works only before something runs");

    const made = await api<PersonRule>("POST", "/api/rules", {
      rule: { ...NO_PUSH, examples: {} },
    });
    expect(made.status).toBe(201);
    expect(made.body.enabled).toBe(false);
    const id = made.body.id;
    const on = await api<{ error: string }>("POST", `/api/rules/${id}/enabled`, { enabled: true });
    expect(on.status).toBe(400);
    expect(on.body.error).toContain("add a case where the rule must act");

    const tried = await api<RuleTrial>("POST", "/api/rules/try", { rule: NO_PUSH });
    expect(tried.body).toEqual({ ok: true, fire: true, pass: true, problems: [] });
    await api("PUT", `/api/rules/${id}`, { rule: NO_PUSH });
    const enabled = await api<PersonRule>("POST", `/api/rules/${id}/enabled`, { enabled: true });
    expect(enabled.body).toMatchObject({ enabled: true, version: 3 });

    // A change that breaks the examples of a rule that is on is refused.
    const broken = await api("PUT", `/api/rules/${id}`, {
      rule: { ...NO_PUSH, examples: { fire: { command: "ls" }, pass: { command: "ls" } } },
    });
    expect(broken.status).toBe(400);

    const history = await api<{ change: string; version: number }[]>(
      "GET",
      `/api/rules/history?id=${id}`,
    );
    expect(history.body.map((h) => h.change)).toEqual(["enabled", "changed", "created"]);

    // Undo the switch-on, then the removal.
    expect(
      (await api<{ rule: PersonRule }>("POST", `/api/rules/${id}/undo`)).body.rule,
    ).toMatchObject({ enabled: false, version: 4 });
    await api("DELETE", `/api/rules/${id}`);
    expect((await api<{ rules: PersonRule[] }>("GET", "/api/rules")).body.rules).toEqual([]);
    const back = await api<{ rule: PersonRule }>("POST", `/api/rules/${id}/undo`);
    expect(back.body.rule).toMatchObject({ id, name: "No push", enabled: false });
    expect((await api<{ rules: PersonRule[] }>("GET", "/api/rules")).body.rules).toHaveLength(1);
    // Another owner sees none of it.
    expect(
      (await api<{ rules: PersonRule[] }>("GET", "/api/rules", undefined, "other-token-0123456789"))
        .body.rules,
    ).toEqual([]);
  });
});

describe("rules before a tool runs", () => {
  it("a rule blocks a command: the agent reads why, the fire is written down", async () => {
    let call = 0;
    s = await startServer(() =>
      ++call === 1
        ? { toolCalls: [{ name: "bash", input: { command: "git push origin main" } }] }
        : { text: "done" },
    );
    const g = await god(s);
    await s.api("POST", "/api/rules", { rule: NO_PUSH, enable: true });
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g })).body
      .sessionId;
    await (await s.core.send("me", sid, "Push it")).done;
    const results = toolResults(s.provider.requests.at(-1));
    expect(results.join("\n")).toContain("blocked by the person's rule «No push»: not on Sundays");
    await s.core.rules.settled();
    const fires = (
      await s.api<{ fires: { ruleName: string; results: string[] }[] }>("GET", "/api/rules")
    ).body.fires;
    expect(fires[0]).toMatchObject({ ruleName: "No push", results: ["blocked"] });
  });

  it("a rule that asks reaches only the person; a no stops the call", async () => {
    let call = 0;
    s = await startServer(() =>
      ++call === 1
        ? { toolCalls: [{ name: "bash", input: { command: "echo hello" } }] }
        : { text: "done" },
    );
    const g = await god(s);
    await s.api("POST", "/api/rules", {
      enable: true,
      rule: {
        name: "Ask for echo",
        when: { event: "tool" },
        if: [{ field: "command", op: "contains", value: "echo" }],
        actions: [{ do: "ask", text: "check it first" }],
        examples: { fire: { command: "echo x" }, pass: { command: "ls" } },
      },
    });
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g })).body
      .sessionId;
    const { done } = await s.core.send("me", sid, "Say hello");
    await until(() => (s?.core.approvals.list("me").length ?? 0) > 0);
    const [req] = s.core.approvals.list("me");
    expect(req?.reasons.join(" ")).toContain("«Ask for echo»: check it first");
    s.core.approvals.decide("me", req?.requestId ?? "", "deny");
    await done;
    expect(toolResults(s.provider.requests.at(-1)).join("\n")).toContain("denied");
  });
});

describe("the weekly margin (the user's own install)", () => {
  it("warns at +5, stops at +2 after saving, and the person resumes", async () => {
    let call = 0;
    s = await startServer(() =>
      ++call === 2
        ? { toolCalls: [{ name: "bash", input: { command: "ls" } }] }
        : { text: `answer ${call}` },
    );
    const g = await god(s);
    const notices: string[] = [];
    s.core.onNotice((_o, text) => {
      notices.push(text);
      return true;
    });
    const made = await s.api<PersonRule[]>("POST", "/api/rules/template", {
      template: "weekly-margin",
      enable: true,
    });
    expect(made.body.map((r) => [r.name, r.enabled])).toEqual([
      ["Weekly margin: warning", true],
      ["Weekly margin: stop", true],
    ]);
    const now = Date.parse("2026-11-22T12:00:00Z");
    const week = 7 * 24 * 3_600_000;
    // 60% of the week passed.
    const reading = (usedPct: number) => [
      {
        provider: "claude-subscription",
        windows: [{ id: "7d", usedPct, resetsAt: new Date(now + 0.4 * week).toISOString() }],
      },
    ];
    await s.core.rules.usage("me", reading(40), now); // +20: nothing
    expect(notices).toEqual([]);
    await s.core.rules.usage("me", reading(56), now); // +4: the warning, once
    await s.core.rules.usage("me", reading(57), now); // +3: nothing new
    expect(notices).toHaveLength(1);
    expect(notices[0]).toContain("Rule «Weekly margin: warning»");
    expect(notices[0]).toContain("margin +4 points");

    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g })).body
      .sessionId;
    await (await s.core.send("me", sid, "first")).done;
    await s.core.rules.usage("me", reading(59), now); // +1: the stop
    await s.core.rules.settled();
    const holds = (await s.api<{ holds: RuleHold[] }>("GET", "/api/rules")).body.holds;
    expect(holds).toMatchObject([{ ruleName: "Weekly margin: stop", scope: "all" }]);
    expect(notices.some((n) => n.includes("stopped the agents"))).toBe(true);

    // Held: the next turn does not reach the model.
    const asked = s.provider.requests.length;
    const r = await (await s.core.send("me", sid, "second")).done;
    expect(r.stopReason).toBe("budget");
    expect(r.reason).toContain("Weekly margin: stop");
    expect(s.provider.requests.length).toBe(asked);

    // Resumed by the person: the work goes on.
    expect(
      (await s.api<{ holds: RuleHold[] }>("POST", "/api/rules/resume", {})).body.holds,
    ).toEqual([]);
    const after = await (await s.core.send("me", sid, "third")).done;
    expect(after.stopReason).toBe("end_turn");
  });

  it("a stop blocks the tools of a turn already running (it saves and stops)", async () => {
    let call = 0;
    s = await startServer(() =>
      ++call === 1
        ? { toolCalls: [{ name: "bash", input: { command: "ls" } }] }
        : { text: "where I am" },
    );
    const g = await god(s);
    await s.api("POST", "/api/rules", {
      enable: true,
      rule: {
        name: "Stop now",
        when: { event: "usage" },
        if: [{ field: "marginPct", op: "lte", value: 2 }],
        actions: [{ do: "stop" }],
        examples: { fire: { marginPct: 0 }, pass: { marginPct: 9 } },
      },
    });
    await s.core.rules.usage("me", [
      {
        provider: "p",
        windows: [{ id: "7d", usedPct: 100, resetsAt: new Date(Date.now() + 1000).toISOString() }],
      },
    ]);
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g })).body
      .sessionId;
    // The gate before the model holds it at once; the tool gate says the same to running turns.
    const r = await (await s.core.send("me", sid, "go")).done;
    expect(r.stopReason).toBe("budget");
    const v = await s.core.rules.beforeTool(
      "me",
      { agentId: g, agent: "God" },
      { name: "bash", input: { command: "ls" } },
    );
    expect(v.decision).toBe("block");
    expect(v.reasons[0]).toContain("do not call more tools");
  });
});

describe("a rule's command", () => {
  it("runs in the sandbox when allowed, and a truly dangerous one waits for the person", async () => {
    s = await startServer(() => ({ text: "finished" }));
    const g = await god(s);
    await s.api("POST", "/api/rules", {
      enable: true,
      rule: {
        name: "Mark the end",
        when: { event: "agent_done" },
        if: [{ field: "agent", op: "eq", value: "God" }],
        actions: [{ do: "command", command: "echo ended > ruled.txt" }],
        examples: { fire: { agent: "God" }, pass: { agent: "Ada" } },
      },
    });
    const sid = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g })).body
      .sessionId;
    await (await s.core.send("me", sid, "hi")).done;
    await until(async () => {
      await s?.core.rules.settled();
      return access(join(s?.core.platformPath("me") ?? "", "ruled.txt")).then(
        () => true,
        () => false,
      );
    });
    expect((await readFile(join(s.core.platformPath("me"), "ruled.txt"), "utf8")).trim()).toBe(
      "ended",
    );

    // Deleting for good is truly dangerous: the person is asked; their no means nothing runs.
    await s.api("POST", "/api/rules", {
      enable: true,
      rule: {
        name: "Clean all",
        when: { event: "agent_done" },
        actions: [{ do: "command", command: "rm -rf ~/" }],
      },
    });
    await (await s.core.send("me", sid, "again")).done;
    await until(() => (s?.core.approvals.list("me").length ?? 0) > 0);
    const [req] = s.core.approvals.list("me");
    expect(req?.critical?.length).toBeGreaterThan(0);
    s.core.approvals.decide("me", req?.requestId ?? "", "deny");
    await s.core.rules.settled();
    const fires = (
      await s.api<{ fires: { ruleName: string; results: string[] }[] }>("GET", "/api/rules")
    ).body.fires;
    expect(fires.find((f) => f.ruleName === "Clean all")?.results[0]).toContain(
      "command failed: not run",
    );
  });
});

describe("magic rules (God builds the rule)", () => {
  it("God proposes beside the conversation; the person approves and it is on", async () => {
    const proposed = new Set<string>();
    s = await startServer((req: CompletionRequest) => {
      const last = req.messages.at(-1);
      if (last?.role === "user" && last.parts.some((p) => p.type === "tool_result"))
        return { text: "Look at the proposal." };
      if (proposed.has(req.messages.length.toString())) return { text: "ok" };
      proposed.add(req.messages.length.toString());
      return {
        toolCalls: [
          {
            name: "propose_rule",
            input: {
              rule: { ...NO_PUSH, name: "Niente push" },
              summary: "Blocco ogni git push.",
              missing: [],
            },
          },
        ],
      };
    });
    await god(s);
    const created = await s.api<MagicRule>("POST", "/api/magic-rules", {
      request: "Non lasciare che nessuno faccia git push",
    });
    expect(created.status).toBe(201);
    let m: MagicRule | undefined;
    await until(async () => {
      m = (await s?.api<MagicRule>("GET", `/api/magic-rules/${created.body.id}`))?.body;
      return m?.status === "ready";
    });
    expect(m?.proposal?.trial.ok).toBe(true);
    const first = s.provider.requests[0] as CompletionRequest;
    expect(first.system).toContain("This conversation builds a rule");
    expect(first.tools?.some((t) => t.name === "propose_rule")).toBe(true);
    expect((await s.api<{ rules: PersonRule[] }>("GET", "/api/rules")).body.rules).toEqual([]);
    const yes = await s.api<{ rule: PersonRule; magic: MagicRule }>(
      "POST",
      `/api/magic-rules/${created.body.id}/approve`,
      {},
    );
    expect(yes.body.rule).toMatchObject({ name: "Niente push", enabled: true, origin: "god" });
    expect(yes.body.magic.status).toBe("done");
  });
});
