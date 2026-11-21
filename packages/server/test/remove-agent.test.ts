// Stopping, resuming, removing and restoring agents (p3.8.9). The person: «dai anche a God la
// possibilità di rimuovere gli agenti». And the GAIA collaudo of 2026-11-17: God paused the whole
// team near the week's limit with stop_agent, could not bring it back and made «Orchestratore
// GAIA 3». So stopping is a pause (the open tasks wait, resuming lets them go on in the same
// conversation, nothing is made again) and removing takes an agent out of the team (its turns stop,
// its open tasks close as «agent removed», its history stays readable, and it can be restored).
// Removing asks nobody by default (3.10, the person's decision of 2026-11-21: «al limite ne spawna un
// altro se gli serve»): the danger remove-agent is off unless the person switches it on in
// Settings > Safety (`enabledDanger`); then it is an ordinary request only they answer, never a
// critical one.

import { existsSync } from "node:fs";
import { writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { Event, PermissionRequestInfo } from "@redgiant/protocol";
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { commitAll, worktreeBranch, worktreeDir } from "@redgiant/sandbox";
import { LocalWorkspace } from "@redgiant/tools";
import { afterEach, describe, expect, it } from "vitest";
import { pausedNote } from "../src/resume-work.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  const server = s;
  s = undefined;
  await server?.close();
}, 60_000);

const textOf = (req: CompletionRequest | undefined) =>
  req?.messages
    .at(-1)
    ?.parts.flatMap((p) =>
      p.type === "text" ? [p.text] : p.type === "tool_result" ? [p.content] : [],
    )
    .join("\n") ?? "";

/** The agent's turn holds (it «works») until it is stopped or removed. */
let holding: string | null = null;
let server: () => Server = () => {
  throw new Error("no server");
};

/**
 * Any agent: «CALL <tool> <json>» makes that call; «HOLD» works until the agent stops; the note
 * of a resume closes the task; a tool's result is answered with «RESULT: …»; else «ok».
 */
function script(req: CompletionRequest): FakeTurn {
  const last = req.messages.at(-1);
  if (last?.parts.some((p) => p.type === "tool_result")) return { text: `RESULT: ${textOf(req)}` };
  const said = textOf(req);
  if (said.startsWith(pausedNote({ id: "", title: "" }).slice(0, 30)))
    return { toolCalls: [{ name: "complete_task", input: { verify_command: "exit 0" } }] };
  if (said === "HOLD") {
    holding = "on";
    return { text: "working on it, step by step, slowly" };
  }
  const m = said.match(/^CALL (\w+) ([\s\S]+)$/);
  if (m?.[1] && m[2]) return { toolCalls: [{ name: m[1], input: JSON.parse(m[2]) }] };
  return { text: "ok" };
}

/** Holds a turn while `holding` is on and its agent still works. */
async function tick(): Promise<void> {
  while (holding === "on") {
    const dev = server()
      .core.registry.list({ ownerId: "me", removed: true })
      .find((a) => a.name === "Dev");
    if (dev && dev.status !== "active") holding = null;
    else await new Promise((r) => setTimeout(r, 10));
  }
}

async function until(what: () => Promise<boolean> | boolean, ms = 20_000): Promise<void> {
  const end = Date.now() + ms;
  while (!(await what())) {
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 20));
  }
}

async function start() {
  holding = null;
  s = await startServer(script, { tick });
  const srv = s;
  server = () => srv;
  return srv;
}

/** God, the shop's orchestrator and its agent Dev, with an open task Dev is working on. */
async function team(srv: Server) {
  await srv.api("POST", "/api/projects", { name: "Shop" });
  const make = async (body: Record<string, unknown>) =>
    (await srv.api<{ id: string }>("POST", "/api/agents", body)).body.id;
  const god = await make({ kind: "god", parentId: null, name: "God" });
  const orch = await make({ kind: "orchestrator", parentId: god, projectId: "shop", name: "Orch" });
  const dev = await make({ kind: "agent", parentId: orch, projectId: "shop", name: "Dev" });
  const session = async (agentId: string) =>
    (await srv.api<{ sessionId: string }>("POST", "/api/sessions", { agentId })).body.sessionId;
  const godSid = await session(god);
  const orchSid = await session(orch);
  const devRecord = srv.core.registry.get(dev);
  if (!devRecord) throw new Error("no Dev");
  const devSid = await srv.core.workSession(devRecord);
  const task = await srv.core.tasks.open(devRecord, devSid, "Code it", {
    agentId: orch,
    sessionId: orchSid,
    name: "Orch",
  });
  void (await srv.core.send("me", devSid, "HOLD")).done.catch(() => {});
  await until(() => srv.core.isRunning(devSid));
  return { god, orch, dev, godSid, orchSid, devSid, task };
}

/** The person answers every request from the page; keeps what they saw. */
function person(srv: Server) {
  const seen: PermissionRequestInfo[] = [];
  srv.core.approvals.on("request", (owner, info) => {
    seen.push(info);
    srv.core.approvals.decide(owner, info.requestId, "allow");
  });
  return seen;
}

/** What the call made in this message returned (its tool result), or the answer. */
const say = async (srv: Server, sid: string, text: string) => {
  const before = (await srv.core.store.list({ sessionId: sid })).at(-1)?.seq ?? -1;
  await (await srv.core.send("me", sid, text)).done;
  const result = (await srv.core.store.list({ sessionId: sid, types: ["tool.result"] })).find(
    (e) => e.seq > before,
  );
  return result
    ? (result.payload as { output: string }).output
    : textOf(srv.provider.requests.at(-1));
};
const call = (tool: string, input: unknown) => `CALL ${tool} ${JSON.stringify(input)}`;
const events = async (srv: Server, sid: string) =>
  (await srv.api<Event[]>("GET", `/api/sessions/${sid}/events`)).body;

describe("stopping is a pause, resuming lets the work go on (p3.8.9)", () => {
  it("God stops the team: turns stop, tasks wait; it resumes them in the same conversation, nothing new", async () => {
    const srv = await start();
    const t = await team(srv);
    person(srv);
    const said = await say(
      srv,
      t.godSid,
      call("stop_agent", { agent_id: t.orch, reason: "near the weekly limit" }),
    );
    expect(said).toMatch(/^Stopped \(paused\): /);
    expect(said).toContain(`Orch (${t.orch})`);
    expect(said).toContain(`Dev (${t.dev})`);
    expect(said).toContain("1 open task(s) wait");
    expect(srv.core.registry.get(t.orch)?.status).toBe("stopped");
    expect(srv.core.registry.get(t.dev)?.status).toBe("stopped");
    await until(() => !srv.core.isRunning(t.devSid));
    // The task waits: nothing closed it as abandoned.
    expect(srv.core.tasks.get(t.task.id)?.outcome).toBeUndefined();
    expect(await srv.core.store.list({ types: ["task.closed"] })).toEqual([]);
    // A stopped agent's conversation is read, never written.
    const refused = await srv.api<{ code: string }>("POST", `/api/sessions/${t.devSid}/messages`, {
      text: "go on",
    });
    expect(refused.status).toBe(423);
    expect(refused.body.code).toBe("agent_stopped");

    // A new lead in its place is refused: the stopped one is resumed.
    const again = await say(
      srv,
      t.godSid,
      call("create_agent", {
        kind: "orchestrator",
        name: "Orch 3",
        role: "Runs the shop",
        project_id: "shop",
      }),
    );
    expect(again).toContain("resume it with resume_agent");

    const resumed = await say(srv, t.godSid, call("resume_agent", { agent_id: t.orch }));
    expect(resumed).toMatch(/^Resumed: Orch .*Dev /);
    expect(resumed).toContain(t.task.id);
    expect(srv.core.registry.get(t.dev)?.status).toBe("active");
    // Dev goes on in the same conversation, told it was paused, and closes its task.
    await until(async () => srv.core.tasks.get(t.task.id)?.outcome === "verified");
    const devLog = await events(srv, t.devSid);
    const notes = devLog.filter(
      (e) => e.type === "message.user" && e.payload?.text.startsWith("[You were stopped (paused)"),
    );
    expect(notes).toHaveLength(1);
    expect(devLog.some((e) => e.type === "message.user" && e.payload?.text === "HOLD")).toBe(true);
    // Its report goes back to the orchestrator; nobody was made again.
    await until(async () =>
      (await events(srv, t.orchSid)).some(
        (e) => e.type === "message.user" && e.payload?.text.includes("<task_report"),
      ),
    );
    const all = srv.core.registry.list({ ownerId: "me", removed: true });
    expect(all.map((a) => `${a.kind}:${a.name}:${a.status}`).sort()).toEqual([
      "agent:Dev:active",
      "god:God:active",
      "orchestrator:Orch:active",
    ]);
    const kinds = (await srv.core.store.list({})).map((e) => e.type);
    expect(kinds).toContain("agent.stopped");
    expect(kinds).toContain("agent.resumed");
  });

  it("the person resumes from the page; the tools say pause and removal apart", async () => {
    const srv = await start();
    const t = await team(srv);
    expect((await srv.api("POST", `/api/agents/${t.dev}/stop`, {})).status).toBe(200);
    await until(() => !srv.core.isRunning(t.devSid));
    const r = await srv.api<{ resumed: string[]; tasks: string[] }>(
      "POST",
      `/api/agents/${t.dev}/resume`,
    );
    expect(r.status).toBe(200);
    expect(r.body).toEqual({ resumed: [t.dev], tasks: [t.task.id] });
    await until(async () => srv.core.tasks.get(t.task.id)?.outcome === "verified");
    // Resuming an agent that works is refused.
    expect((await srv.api("POST", `/api/agents/${t.dev}/resume`)).status).toBe(409);
    await say(srv, t.godSid, "hello");
    const tools = srv.provider.requests.at(-1)?.tools ?? [];
    const desc = (n: string) => tools.find((x) => x.name === n)?.description ?? "";
    expect(desc("stop_agent")).toContain("Pause");
    expect(desc("stop_agent")).toContain("resume_agent");
    expect(desc("resume_agent")).toContain("never create a new one");
    expect(desc("remove_agent")).toContain("To pause an agent use stop_agent");
    expect(srv.provider.requests.at(-1)?.system).toContain("A stopped agent is paused, not gone");
  });
});

describe("removing an agent from the team (p3.8.9)", () => {
  it("God removes one asking nobody: turns stop, tasks close, it leaves the lists, history stays, it comes back", async () => {
    const srv = await start();
    const t = await team(srv);
    const seen = person(srv);
    const preview = await srv.api<{
      with: { id: string }[];
      tasks: number;
      running: number;
      allowed: boolean;
    }>("GET", `/api/agents/${t.orch}/remove-preview`);
    expect(preview.body).toMatchObject({
      with: [{ id: t.dev }],
      tasks: 1,
      running: 1,
      allowed: true,
    });

    const said = await say(
      srv,
      t.godSid,
      call("remove_agent", { agent_id: t.dev, reason: "not needed any more" }),
    );
    expect(said).toContain("Removed from the team: Dev");
    // Nobody was asked: not the person, not the classifier, not a parent.
    expect(seen.find((r) => r.tool === "remove_agent")).toBeUndefined();
    await until(() => !srv.core.isRunning(t.devSid));

    // The task closed, said why, and went back to who handed it over.
    const closed = (await srv.core.store.list({ types: ["task.closed"] })).map((e) => e.payload);
    expect(closed).toEqual([
      { taskId: t.task.id, outcome: "abandoned", reason: "agent removed: not needed any more" },
    ]);
    await until(async () =>
      (await events(srv, t.orchSid)).some(
        (e) => e.type === "message.user" && e.payload?.text.includes('outcome="abandoned"'),
      ),
    );
    // Out of every list; its conversations still read by its id.
    const agents = (await srv.api<{ id: string }[]>("GET", "/api/agents")).body;
    expect(agents.map((a) => a.id)).not.toContain(t.dev);
    const sessions = (await srv.api<{ id: string }[]>("GET", "/api/sessions")).body;
    expect(sessions.map((x) => x.id)).not.toContain(t.devSid);
    const own = (await srv.api<{ id: string }[]>("GET", `/api/sessions?agentId=${t.dev}`)).body;
    expect(own.map((x) => x.id)).toContain(t.devSid);
    expect((await events(srv, t.devSid)).some((e) => e.type === "message.user")).toBe(true);
    const removed = (
      await srv.api<
        {
          id: string;
          status: string;
          removed: { by: string; reason: string; with: unknown[]; sessions: number };
        }[]
      >("GET", "/api/agents/removed")
    ).body;
    expect(removed).toEqual([
      expect.objectContaining({
        id: t.dev,
        status: "removed",
        removed: expect.objectContaining({
          by: "God",
          reason: "not needed any more",
          with: [],
          sessions: 1,
        }),
      }),
    ]);
    const refused = await srv.api<{ code: string }>("POST", `/api/sessions/${t.devSid}/messages`, {
      text: "hello?",
    });
    expect(refused.status).toBe(423);
    expect(refused.body.code).toBe("agent_removed");

    // A namesake made now is a new agent, and the creator hears of the old one.
    const made = await say(
      srv,
      t.orchSid,
      call("create_agent", { kind: "agent", name: "Dev", role: "Codes" }),
    );
    expect(made).toMatch(/Created agent Dev \(agent_[0-9a-f]+\)/);
    expect(made).toContain(`Dev (${t.dev}) is removed — restore_agent brings that one back`);

    // God, Demi-God and the Chat are never removed.
    const chat = await srv.core.chatAgent("me");
    expect(
      await say(srv, t.godSid, call("remove_agent", { agent_id: chat.id, reason: "x" })),
    ).toContain("never removed");
    expect(
      await say(srv, t.godSid, call("remove_agent", { agent_id: t.god, reason: "x" })),
    ).toContain("never removed");
    expect((await srv.api("POST", `/api/agents/${chat.id}/remove`, {})).status).toBe(403);
    expect((await srv.api("POST", `/api/agents/${t.god}/remove`, {})).status).toBe(403);

    // The person restores it: back as it was, with its history whole.
    const back = await srv.api<{ restored: string[] }>("POST", `/api/agents/${t.dev}/restore`);
    expect(back.body).toEqual({ restored: [t.dev] });
    expect(srv.core.registry.get(t.dev)?.status).toBe("active");
    expect((await srv.api<unknown[]>("GET", "/api/agents/removed")).body).toEqual([]);
    const log = (await srv.core.store.list({})).map((e) => e.type);
    expect(log).toContain("agent.removed");
    expect(log).toContain("agent.restored");
    expect((await events(srv, t.devSid)).some((e) => e.type === "message.user")).toBe(true);
  });

  it("asks the person once they switch the danger on, also over a policy saved before 3.10", async () => {
    const srv = await start();
    const t = await team(srv);
    const seen = person(srv);
    // A policy saved before (no enabledDanger, remove-agent among the human-only ones) asks nobody.
    await srv.core.policies.set("me", {
      rules: [],
      humanOnly: ["platform", "remove-agent"],
      disabledDanger: [],
      guardian: "ask",
      skills: "ask",
    } as never);
    const god = srv.core.registry.get(t.god);
    if (!god) throw new Error("no God");
    expect(
      srv.core.policies.settingsFor(god, false).danger.find((d) => d.id === "remove-agent")
        ?.enabled,
    ).toBe(false);
    // Switched on (Settings > Safety saves `enabledDanger`): removing asks the person.
    await srv.core.policies.set("me", {
      ...srv.core.policies.get("me"),
      enabledDanger: ["remove-agent"],
    });
    const said = await say(
      srv,
      t.godSid,
      call("remove_agent", { agent_id: t.dev, reason: "not needed any more" }),
    );
    expect(said).toContain("Removed from the team: Dev");
    const asked = seen.find((r) => r.tool === "remove_agent");
    expect(asked?.danger).toContain("remove-agent");
    expect(asked?.critical ?? []).toEqual([]);
  });

  it("removes an orchestrator with its agents; restoring waits for its place to be free", async () => {
    const srv = await start();
    const t = await team(srv);
    const r = await srv.api<{ removed: string[] }>("POST", `/api/agents/${t.orch}/remove`, {
      reason: "a fresh start",
    });
    expect(r.body.removed).toEqual([t.orch, t.dev]);
    const list = (
      await srv.api<{ id: string; removed: { by: string; with: { id: string }[] } }[]>(
        "GET",
        "/api/agents/removed",
      )
    ).body;
    expect(list.map((x) => x.id)).toEqual([t.orch]);
    expect(list[0]?.removed.by).toBe("person");
    expect(list[0]?.removed.with.map((w) => w.id)).toEqual([t.dev]);
    // Dev went with it: it is restored with it, not alone.
    expect((await srv.api("POST", `/api/agents/${t.dev}/restore`)).status).toBe(409);
    const lead = await srv.api<{ id: string }>("POST", "/api/agents", {
      kind: "orchestrator",
      parentId: t.god,
      projectId: "shop",
      name: "Orch 2",
    });
    expect(lead.status).toBe(201);
    const taken = await srv.api<{ error: string }>("POST", `/api/agents/${t.orch}/restore`);
    expect(taken.status).toBe(409);
    expect(taken.body.error).toContain("has another orchestrator");
    await srv.api("POST", `/api/agents/${lead.body.id}/remove`, {});
    const back = await srv.api<{ restored: string[] }>("POST", `/api/agents/${t.orch}/restore`);
    expect(back.body.restored).toEqual([t.orch, t.dev]);
    expect(srv.core.registry.get(t.dev)?.status).toBe("active");
  });
});

describe("a removed agent's worktree and branch (3.10.1)", () => {
  const branches = async (path: string) =>
    (
      await new LocalWorkspace(path).execFile("git", ["branch", "--format=%(refname:short)"], {
        timeoutMs: 10_000,
      })
    ).stdout;

  it("go when nothing on them is new; a restored agent gets a fresh worktree", async () => {
    const srv = await start();
    const t = await team(srv);
    const path = (await srv.core.projects.get("me", "shop"))?.path ?? "";
    const wt = join(path, worktreeDir(t.dev));
    await until(() => existsSync(join(wt, ".git")));
    const said = await say(
      srv,
      t.godSid,
      call("remove_agent", { agent_id: t.dev, reason: "not needed any more" }),
    );
    expect(said).toContain("Removed from the team: Dev");
    expect(said).not.toContain("kept");
    expect(existsSync(wt)).toBe(false);
    expect(await branches(path)).not.toContain(worktreeBranch(t.dev));

    await srv.api("POST", `/api/agents/${t.dev}/restore`);
    await (await srv.core.send("me", t.devSid, "hello")).done;
    expect(existsSync(join(wt, ".git"))).toBe(true);
    expect(await branches(path)).toContain(worktreeBranch(t.dev));
  });

  it("stay when they hold work not in the project, and the parent hears what", async () => {
    const srv = await start();
    const t = await team(srv);
    const path = (await srv.core.projects.get("me", "shop"))?.path ?? "";
    const wt = join(path, worktreeDir(t.dev));
    await until(() => existsSync(join(wt, ".git")));
    await writeFile(join(wt, "pay.ts"), "export const pay = 1;\n");
    await commitAll(new LocalWorkspace(wt), "Add payments");
    await writeFile(join(wt, "draft.md"), "half done\n");
    const said = await say(
      srv,
      t.godSid,
      call("remove_agent", { agent_id: t.dev, reason: "not needed any more" }),
    );
    expect(said).toContain(`Not merged, so kept: Dev: branch ${worktreeBranch(t.dev)}`);
    expect(said).toMatch(/1 commit\(s\) not in the project: [0-9a-f]+ Add payments/);
    expect(said).toContain("1 uncommitted change(s): ?? draft.md");
    expect(existsSync(join(wt, "draft.md"))).toBe(true);
    expect(await branches(path)).toContain(worktreeBranch(t.dev));

    // The removed list says it too (3.10.2), for the page and the app; restoring clears it.
    type Removed = { id: string; removed: { kept: unknown[] } }[];
    const listed = (await srv.api<Removed>("GET", "/api/agents/removed")).body;
    expect(listed.find((r) => r.id === t.dev)?.removed.kept).toEqual([
      { id: t.dev, name: "Dev", branch: worktreeBranch(t.dev), commits: 1, changes: 1 },
    ]);
    await srv.api("POST", `/api/agents/${t.dev}/restore`);
    expect(srv.core.registry.get(t.dev)?.removed).toBeUndefined();
  });

  it("are listed for an agent removed with its orchestrator, under the orchestrator", async () => {
    const srv = await start();
    const t = await team(srv);
    const path = (await srv.core.projects.get("me", "shop"))?.path ?? "";
    const wt = join(path, worktreeDir(t.dev));
    await until(() => existsSync(join(wt, ".git")));
    await writeFile(join(wt, "a.ts"), "export const a = 1;\n");
    await writeFile(join(wt, "b.ts"), "export const b = 1;\n");
    await srv.api("POST", `/api/agents/${t.orch}/remove`, {});
    type Removed = { id: string; removed: { kept: { id: string; changes: number }[] } }[];
    const listed = (await srv.api<Removed>("GET", "/api/agents/removed")).body;
    expect(listed.map((r) => r.id)).toEqual([t.orch]);
    expect(listed[0]?.removed.kept).toEqual([
      expect.objectContaining({ id: t.dev, name: "Dev", commits: 0, changes: 2 }),
    ]);
  });
});
