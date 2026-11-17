// 3.8.9: work cut by a restart goes on without anything made twice. On 2026-11-17 a blackout
// stopped Coder while two agents of the GAIA project were in the middle of their tasks; after the
// start nothing resumed them, delegating to the orchestrator failed (3.8.7: its work conversation
// was read back twice as JSON), and God and then the new orchestrator made «Orchestratore GAIA 2»,
// «Sviluppatore plugin 2» and «Ambiente e QA 2». Here the same story runs on one database with two
// cores: the first dies in the middle of the agent's turn, the second is the restart.
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { ChatMessage, Event } from "@redgiant/protocol";
import {
  type CompletionRequest,
  FakeProvider,
  type FakeScript,
  type FakeTurn,
  ProviderRegistry,
} from "@redgiant/providers";
import { describe, expect, it } from "vitest";
import { RedGiantCore } from "../src/index.js";
import { resumeNote, turnCut } from "../src/resume-work.js";
import { memoryDb } from "./pglite.js";

const textOf = (m: ChatMessage | undefined) =>
  m?.parts
    .flatMap((p) => (p.type === "text" ? [p.text] : p.type === "tool_result" ? [p.content] : []))
    .join("\n") ?? "";

/** Tool results since the last plain user message, and that message. */
function step(req: CompletionRequest): { n: number; results: string[]; said: string } {
  const results: string[] = [];
  for (let i = req.messages.length - 1; i >= 0; i--) {
    const m = req.messages[i];
    if (m?.role !== "user") continue;
    if (m.parts.some((p) => p.type === "tool_result")) results.unshift(textOf(m));
    else return { n: results.length, results, said: textOf(m) };
  }
  return { n: results.length, results, said: "" };
}
const idIn = (text: string, kind: string) =>
  text.match(new RegExp(`\\((${kind}_[0-9a-f]+)\\)`))?.[1] ?? "";
const call = (name: string, input: unknown): FakeTurn => ({ toolCalls: [{ name, input }] });
const role = (req: CompletionRequest) =>
  req.system.startsWith("You are God")
    ? "god"
    : req.system.startsWith("You are the orchestrator")
      ? "orchestrator"
      : "agent";
const ok = `node -e "process.exit(0)"`;

async function until(what: () => Promise<boolean> | boolean, ms = 20_000): Promise<void> {
  const end = Date.now() + ms;
  while (!(await what())) {
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 20));
  }
}

const at = (seq: number, type: string, payload: unknown): Event =>
  ({
    seq,
    id: `e${seq}`,
    ts: new Date(1_800_000_000_000 + seq * 1000).toISOString(),
    ownerId: "me",
    projectId: null,
    agentId: "a",
    sessionId: "s",
    type,
    payload,
    payloadHash: "",
    prevHash: null,
    hash: "",
    erased: false,
  }) as unknown as Event;
const said = (seq: number) => at(seq, "message.user", { text: "go" });
const answer = (seq: number, stopReason: string) =>
  at(seq, "message.assistant", {
    parts: [],
    stopReason,
    provider: "fake",
    model: "m",
    metrics: {},
    costUsd: 0,
  });

describe("turnCut", () => {
  it.each([
    ["nothing yet", [], false],
    ["a message the model never answered", [said(1)], true],
    [
      "a call made, its result not yet",
      [said(1), answer(2, "tool_use"), at(3, "tool.call", {})],
      true,
    ],
    [
      "a result written, the next step not yet",
      [said(1), answer(2, "tool_use"), at(3, "tool.call", {}), at(4, "tool.result", {})],
      true,
    ],
    ["the model's last word", [said(1), answer(2, "end_turn")], false],
    ["the step limit's summary", [said(1), answer(2, "max_turns")], false],
    ["stopped in the middle (the server's stop)", [said(1), answer(2, "aborted")], true],
    [
      "an engine's turn that ended",
      [said(1), at(2, "engine.session", { id: "x" }), at(3, "file", {})],
      false,
    ],
    [
      "other events after the end do not count",
      [said(1), answer(2, "end_turn"), at(3, "subagent.ended", {})],
      false,
    ],
    ["a reminder after the end starts a turn", [answer(2, "end_turn"), said(3)], true],
  ])("%s", (_name, events, cut) => {
    expect(turnCut(events as Event[])).toBe(cut);
  });
});

describe("a restart in the middle of a task (3.8.9)", () => {
  it("resumes the cut turn, delegates to the same agents and makes nothing twice", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-restart-"));
    const { db } = await memoryDb();
    const core = (script: FakeScript, tick?: () => Promise<void>) =>
      RedGiantCore.create({
        db,
        providers: new ProviderRegistry().register(new FakeProvider(script, tick ? { tick } : {})),
        workspacesDir: join(dir, "workspaces"),
        platformDir: join(dir, "platform"),
        defaultModel: { provider: "fake", model: "m" },
        askAgent: async () => "escalate",
      });

    // ---- Before the blackout: God → orchestrator → agent, and the agent dies mid-turn.
    let dead = false;
    const first = await core(
      (req) => {
        const { n, results } = step(req);
        const last = results.at(-1) ?? "";
        switch (role(req)) {
          case "god":
            if (n === 0) return call("create_project", { name: "Gaia" });
            if (n === 1)
              return call("create_agent", {
                kind: "orchestrator",
                name: "Orch",
                role: "Runs Gaia",
                project_id: "gaia",
              });
            if (n === 2)
              return call("delegate", {
                agent_id: idIn(last, "orchestrator"),
                title: "Build",
                task: "Build the plugin",
              });
            return { text: "Handed over." };
          case "orchestrator":
            if (n === 0) return call("create_agent", { kind: "agent", name: "Dev", role: "Codes" });
            if (n === 1)
              return call("delegate", {
                agent_id: idIn(last, "agent"),
                title: "Code it",
                task: "Write a.txt",
              });
            return { text: "Dev is on it." };
          default:
            if (n === 0) return call("write_file", { path: "a.txt", content: "A\n" });
            // The power goes: this answer never comes.
            dead = true;
            return { text: "never" };
        }
      },
      () => (dead ? new Promise<void>(() => {}) : Promise.resolve()),
    );
    const god = await first.registry.create(
      { type: "human", ownerId: "me" },
      { kind: "god", parentId: null, name: "God" },
    );
    const godSession = await first.startSession("me", god.id);
    await (await first.send("me", godSession, "Make the Gaia plugin", { watch: true })).done;
    await until(() => dead);
    const orch = first.registry.list({ ownerId: "me" }).find((a) => a.kind === "orchestrator");
    const dev = first.registry.list({ ownerId: "me" }).find((a) => a.kind === "agent");
    expect(orch && dev).toBeTruthy();
    const orchSession = await first.workSession(orch as never);
    const devSession = await first.workSession(dev as never);
    const devEvents = await first.store.list({ sessionId: devSession });
    expect(devEvents.at(-1)?.type).toBe("tool.result");

    // ---- The restart: a second server on the same database; the first one never speaks again.
    const asked: { role: string; req: CompletionRequest }[] = [];
    const second = await core((req) => {
      const { n, results, said } = step(req);
      asked.push({ role: role(req), req });
      switch (role(req)) {
        case "god":
          if (said.includes("<task_report")) return { text: "Noted." };
          if (n === 0)
            return call("delegate", {
              agent_id: orch?.id,
              title: "Check",
              task: "Check the work after the blackout",
            });
          return { text: `Checked: ${results[0]}` };
        case "orchestrator":
          if (said.includes("<task_report")) {
            // A model that makes its agent again: the same one comes back, not a second.
            if (n === 0) return call("create_agent", { kind: "agent", name: "Dev", role: "Codes" });
            if (n === 1) return call("complete_task", { verify_command: ok });
            return { text: "Built." };
          }
          if (n === 0) return call("complete_task", { verify_command: ok });
          return { text: "Checked." };
        default:
          if (n === 0) return call("complete_task", { verify_command: ok });
          return { text: "a.txt is there." };
      }
    });
    try {
      const resumed = await second.resumeInterrupted({ retryMs: [] });
      // Only the turn that was cut: the orchestrator had ended its own, waiting for Dev.
      expect(resumed.sessions).toEqual([devSession]);
      await resumed.done;
      const godSaid = async () =>
        (await second.store.list({ sessionId: godSession, types: ["message.assistant"] })).some(
          (e) => textOf(e.payload as ChatMessage) === "Noted.",
        );
      await until(godSaid);

      // The agent went on knowing what happened, with its history whole.
      const devAsk = asked.find((a) => a.role === "agent")?.req;
      const devText = (devAsk?.messages ?? []).map(textOf).join("\n");
      expect(devText).toContain(resumeNote({ id: "", title: "" }).slice(0, 40));
      expect(devText).toContain("Code it");
      expect(devAsk?.messages.some((m) => m.parts.some((p) => p.type === "tool_result"))).toBe(
        true,
      );

      // The person asks God after the blackout: delegating to the same orchestrator works, in the
      // conversation it already had (3.8.7 threw here: «… is not valid JSON»).
      const before = (await second.store.list({ sessionId: godSession })).at(-1)?.seq ?? 0;
      await (
        await second.send("me", godSession, "There was a blackout: check the agents", {
          watch: true,
        })
      ).done;
      const delegated = (
        await second.store.list({ sessionId: godSession, types: ["tool.result"] })
      ).filter((e) => e.seq > before);
      expect(delegated.map((e) => (e.payload as { ok: boolean; output: string }).output)).toEqual([
        expect.stringMatching(/^Task task_[0-9a-f]+ handed to Orch\b/),
      ]);
      expect(await second.workSession(orch as never)).toBe(orchSession);
      await until(async () => {
        const closed = await second.store.list({ types: ["task.closed"] });
        return closed.length === 3;
      });

      // Nothing made twice: one project, one orchestrator, one agent, none called «… 2».
      const agents = second.registry.list({ ownerId: "me" });
      expect(agents.map((a) => `${a.kind}:${a.name}:${a.status}`).sort()).toEqual([
        "agent:Dev:active",
        "god:God:active",
        "orchestrator:Orch:active",
      ]);
      expect((await second.projects.list("me")).map((p) => p.id)).toEqual(["gaia"]);
      const all = await second.store.list();
      const of = (t: Event["type"]) => all.filter((e) => e.type === t);
      expect(of("agent.spawned")).toHaveLength(3);
      expect(of("task.opened").map((e) => (e.payload as { title: string }).title)).toEqual([
        "Build",
        "Code it",
        "Check",
      ]);
      expect(of("task.closed").map((e) => (e.payload as { outcome: string }).outcome)).toEqual([
        "verified",
        "verified",
        "verified",
      ]);
      const again = of("tool.result").find(
        (e) =>
          e.sessionId === orchSession &&
          (e.payload as { output: string }).output.includes("already exists"),
      );
      expect((again?.payload as { output: string } | undefined)?.output).toMatch(
        new RegExp(`^Dev \\(${dev?.id}\\) already exists under you`),
      );
      // The tab the blackout left open in the orchestrator's conversation ends with the work.
      const tabs = of("subagent.ended").filter(
        (e) =>
          e.sessionId === orchSession &&
          (e.payload as { childSessionId: string }).childSessionId === devSession,
      );
      expect(tabs.map((e) => (e.payload as { status: string }).status)).toEqual(["done"]);
      expect((await second.store.verify()).ok).toBe(true);

      // Started again, nothing is resumed twice.
      expect((await second.resumeInterrupted({ retryMs: [] })).sessions).toEqual([]);
    } finally {
      await second.close();
      await Promise.race([first.close(), new Promise((r) => setTimeout(r, 2000))]);
    }
  }, 60_000);

  it("creating the same project or delegating the same open task again changes nothing", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-twice-"));
    const { db } = await memoryDb();
    let orchestrator = "";
    const redgiant = await RedGiantCore.create({
      db,
      providers: new ProviderRegistry().register(
        new FakeProvider((req) => {
          const { n, results } = step(req);
          if (role(req) === "god") {
            if (n === 0) return call("create_project", { name: "Gaia" });
            // The same call again, as a model does after a result cut by a restart.
            if (n === 1) return call("create_project", { name: "Gaia" });
            if (n === 2)
              return call("create_agent", {
                kind: "orchestrator",
                name: "Orch",
                role: "Runs Gaia",
                project_id: "gaia",
              });
            orchestrator ||= idIn(results[2] ?? "", "orchestrator");
            if (n === 3 || n === 4)
              return call("delegate", { agent_id: orchestrator, title: "Build", task: "Build it" });
            return { text: "Done." };
          }
          // The orchestrator stays at work on «Build»: it waits for the person's answer.
          return call("ask_user", {
            questions: [
              { question: "Which colour?", options: [{ label: "Red" }, { label: "Blue" }] },
            ],
          });
        }),
      ),
      workspacesDir: join(dir, "workspaces"),
      platformDir: join(dir, "platform"),
      defaultModel: { provider: "fake", model: "m" },
      askAgent: async () => "escalate",
    });
    try {
      const god = await redgiant.registry.create(
        { type: "human", ownerId: "me" },
        { kind: "god", parentId: null, name: "God" },
      );
      const sid = await redgiant.startSession("me", god.id);
      await (await redgiant.send("me", sid, "Make Gaia", { watch: true })).done;
      const outputs = (await redgiant.store.list({ sessionId: sid, types: ["tool.result"] })).map(
        (e) => (e.payload as { output: string }).output,
      );
      expect(outputs[0]).toMatch(/^Created project gaia /);
      expect(outputs[1]).toMatch(/^Project gaia already exists .*nothing was created again/);
      expect(outputs[3]).toMatch(/^Task task_[0-9a-f]+ handed to Orch\b/);
      expect(outputs[4]).toMatch(
        /^Task task_[0-9a-f]+ \(«Build»\) is already with Orch and still open: nothing was handed over again/,
      );
      expect((await redgiant.projects.list("me")).map((p) => p.id)).toEqual(["gaia"]);
      expect(await redgiant.store.list({ types: ["task.opened"] })).toHaveLength(1);
      expect(
        await redgiant.store.list({ sessionId: sid, types: ["subagent.started"] }),
      ).toHaveLength(1);
    } finally {
      await redgiant.close();
    }
  }, 60_000);

  it("a stop of the server (an update) keeps the cut task open, and the next start resumes it", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-stop-"));
    const { db } = await memoryDb();
    let hang = false;
    const options = (script: FakeScript, tick?: () => Promise<void>) => ({
      db,
      providers: new ProviderRegistry().register(new FakeProvider(script, tick ? { tick } : {})),
      workspacesDir: join(dir, "workspaces"),
      platformDir: join(dir, "platform"),
      defaultModel: { provider: "fake" as const, model: "m" },
      askAgent: async () => "escalate" as const,
    });
    const first = await RedGiantCore.create(
      options(
        (req) => {
          const { n, results } = step(req);
          if (role(req) === "god") {
            if (n === 0) return call("create_project", { name: "Gaia" });
            if (n === 1)
              return call("create_agent", {
                kind: "orchestrator",
                name: "Orch",
                role: "Runs Gaia",
                project_id: "gaia",
              });
            if (n === 2)
              return call("delegate", {
                agent_id: idIn(results[1] ?? "", "orchestrator"),
                title: "Build",
                task: "Build it",
              });
            return { text: "Handed over." };
          }
          if (n === 0) return call("write_file", { path: "a.txt", content: "A\n" });
          hang = true;
          return { text: "never" };
        },
        async () => {
          while (hang) await new Promise((r) => setTimeout(r, 10));
        },
      ),
    );
    const god = await first.registry.create(
      { type: "human", ownerId: "me" },
      { kind: "god", parentId: null, name: "God" },
    );
    const godSession = await first.startSession("me", god.id);
    await (await first.send("me", godSession, "Make Gaia", { watch: true })).done;
    await until(() => hang);
    const orch = first.registry.list({ ownerId: "me" }).find((a) => a.kind === "orchestrator");
    const orchSession = await first.workSession(orch as never);
    // The update stops the server: the turn is cut, its task is not given up.
    const closing = first.close();
    await new Promise((r) => setTimeout(r, 50));
    hang = false;
    await closing;
    await until(
      async () =>
        (await first.store.list({ sessionId: godSession, types: ["subagent.ended"] })).length > 0,
    );
    await new Promise((r) => setTimeout(r, 200));
    expect(await first.store.list({ types: ["task.closed"] })).toEqual([]);

    const second = await RedGiantCore.create(
      options((req) => {
        const { n, said } = step(req);
        if (role(req) === "god") return { text: said.includes("<task_report") ? "Noted." : "ok" };
        if (n === 0) return call("complete_task", { verify_command: ok });
        return { text: "Built." };
      }),
    );
    try {
      const resumed = await second.resumeInterrupted({ retryMs: [] });
      expect(resumed.sessions).toEqual([orchSession]);
      await resumed.done;
      const closed = await second.store.list({ types: ["task.closed"] });
      expect(closed.map((e) => (e.payload as { outcome: string }).outcome)).toEqual(["verified"]);
    } finally {
      await second.close();
    }
  }, 60_000);
});
