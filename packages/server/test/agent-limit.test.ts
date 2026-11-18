// A project's agent limit (2026-11-18, decision «Limite di sotto-agenti per progetto»): the
// person chooses how many agents a project may have besides its orchestrator (default 3, 0 = the
// orchestrator alone, at most 10). Every way of making an agent obeys it (create_agent, the
// page's wizard, run_subagent, restoring a removed agent), with a clear refusal; raising it lets
// new ones in; lowering it removes nobody. The choice is in the history and undoable.
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
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

/** «CALL <tool> <json>» makes that call; a tool's result is answered with «RESULT: …». */
function script(req: CompletionRequest): FakeTurn {
  const last = req.messages.at(-1);
  if (last?.parts.some((p) => p.type === "tool_result")) return { text: `RESULT: ${textOf(req)}` };
  const m = textOf(req).match(/^CALL (\w+) ([\s\S]+)$/);
  if (m?.[1] && m[2]) return { toolCalls: [{ name: m[1], input: JSON.parse(m[2]) }] };
  return { text: "ok" };
}

/** God and the shop's orchestrator, with a conversation each; the person says yes to all. */
async function start() {
  s = await startServer(script);
  const srv = s;
  srv.core.approvals.on("request", (owner, info) =>
    srv.core.approvals.decide(owner, info.requestId, "allow"),
  );
  await srv.api("POST", "/api/projects", { name: "Shop" });
  const make = async (body: Record<string, unknown>) =>
    (await srv.api<{ id: string }>("POST", "/api/agents", body)).body.id;
  const god = await make({ kind: "god", parentId: null, name: "God" });
  const orch = await make({ kind: "orchestrator", parentId: god, projectId: "shop", name: "Orch" });
  const session = async (agentId: string) =>
    (await srv.api<{ sessionId: string }>("POST", "/api/sessions", { agentId })).body.sessionId;
  return { srv, god, orch, session, orchSid: await session(orch), godSid: await session(god) };
}

/** What the call made in this message returned (its tool result). */
const say = async (srv: Server, sid: string, text: string) => {
  const before = (await srv.core.store.list({ sessionId: sid })).at(-1)?.seq ?? -1;
  await (await srv.core.send("me", sid, text)).done;
  const result = (await srv.core.store.list({ sessionId: sid, types: ["tool.result"] })).find(
    (e) => e.seq > before,
  );
  return (result?.payload as { output: string } | undefined)?.output ?? "";
};
const call = (tool: string, input: unknown) => `CALL ${tool} ${JSON.stringify(input)}`;
const createAgent = (name: string) =>
  call("create_agent", { kind: "agent", name, role: `Does ${name}` });
const team = (srv: Server) =>
  srv.core.registry
    .list({ ownerId: "me", projectId: "shop" })
    .filter((a) => a.kind === "agent")
    .map((a) => a.name)
    .sort();
const limit = (srv: Server, maxAgents: number) =>
  srv.api<{ id: string; before: unknown; after: unknown; detail?: string }>(
    "PUT",
    "/api/projects/shop/max-agents",
    { maxAgents },
  );
type ProjectOut = { id: string; maxAgents: number; agents?: number };
const project = async (srv: Server) =>
  (await srv.api<ProjectOut[]>("GET", "/api/projects")).body.find((p) => p.id === "shop");

describe("a project's agent limit (2026-11-18)", () => {
  it("default 3: the orchestrator's fourth create_agent is refused, clearly, and nothing is made", async () => {
    const { srv, orchSid } = await start();
    expect(await project(srv)).toMatchObject({ maxAgents: 3, agents: 0 });
    for (const name of ["Dev", "Tester", "Writer"])
      expect(await say(srv, orchSid, createAgent(name))).toMatch(/^Created agent /);
    const refused = await say(srv, orchSid, createAgent("Designer"));
    expect(refused).toContain(
      'The project "Shop" can have at most 3 agents besides its orchestrator: it has 3.',
    );
    expect(refused).toContain("ask the person to raise the limit");
    expect(refused).toContain("or remove an agent first");
    expect(team(srv)).toEqual(["Dev", "Tester", "Writer"]);
    expect(await project(srv)).toMatchObject({ maxAgents: 3, agents: 3 });
  });

  it("0: the orchestrator works alone; the page's wizard gets a code it says in the person's words", async () => {
    const { srv, orch, orchSid } = await start();
    expect((await limit(srv, 0)).status).toBe(200);
    const refused = await say(srv, orchSid, createAgent("Dev"));
    expect(refused).toContain('The project "Shop" works with its orchestrator alone');
    expect(refused).not.toContain("remove an agent");
    const page = await srv.api<{ error: string; code: string; vars: Record<string, string> }>(
      "POST",
      "/api/agents",
      { kind: "agent", parentId: orch, projectId: "shop", name: "Dev" },
    );
    expect(page.status).toBe(409);
    expect(page.body.code).toBe("agent_limit");
    expect(page.body.vars).toEqual({ project: "Shop", max: "0", count: "0" });
    expect(team(srv)).toEqual([]);
    // Saved with the project: read again from the database.
    expect((await srv.core.projects.get("me", "shop"))?.maxAgents).toBe(0);
    expect(await srv.core.projects.agentLimits()).toContainEqual({
      ownerId: "me",
      id: "shop",
      name: "Shop",
      max: 0,
    });
  });

  it("raising it lets new agents in; the change is in the history and undone like any other", async () => {
    const { srv, orchSid } = await start();
    await limit(srv, 1);
    expect(await say(srv, orchSid, createAgent("Dev"))).toMatch(/^Created agent /);
    expect(await say(srv, orchSid, createAgent("Tester"))).toContain("at most 1 agent besides");
    const raised = await limit(srv, 2);
    expect(raised.body).toMatchObject({ before: { maxAgents: 1 }, after: { maxAgents: 2 } });
    expect(await say(srv, orchSid, createAgent("Tester"))).toMatch(/^Created agent /);
    // Undo: back to 1, nobody removed.
    const undo = await srv.api<{ after: unknown }>(
      "POST",
      `/api/platform/changes/${raised.body.id}/undo`,
    );
    expect(undo.status).toBe(200);
    expect(undo.body.after).toEqual({ maxAgents: 1 });
    expect((await project(srv))?.maxAgents).toBe(1);
    expect(team(srv)).toEqual(["Dev", "Tester"]);
    const changes = (
      await srv.api<{ target?: string; stage: string }[]>("GET", "/api/platform/changes")
    ).body.filter((c) => c.target === "project-agents:shop");
    expect(changes.map((c) => c.stage).sort()).toEqual(["promoted", "promoted", "undone"]);
    // Only the person chooses it: God has no way to raise it by itself.
    await expect(srv.core.config.projectAgents("me", "god", "shop", 10)).rejects.toThrow(
      "Only the person",
    );
    expect((await limit(srv, 11)).status).toBe(400);
    expect((await limit(srv, -1)).status).toBe(400);
  });

  it("lowering it removes nobody; it stops new ones, restoring and sub-agents too, until under", async () => {
    const { srv, orchSid, session } = await start();
    for (const name of ["Dev", "Tester", "Writer"]) await say(srv, orchSid, createAgent(name));
    const lowered = await limit(srv, 1);
    expect(lowered.status).toBe(200);
    expect(lowered.body.detail).toContain("none removed");
    expect(team(srv)).toEqual(["Dev", "Tester", "Writer"]);
    expect(await project(srv)).toMatchObject({ maxAgents: 1, agents: 3 });
    expect(await say(srv, orchSid, createAgent("Designer"))).toContain("it has 3");

    // A sub-agent is an agent at work too: Dev cannot start one while the project is full.
    const dev = srv.core.registry.list({ ownerId: "me" }).find((a) => a.name === "Dev");
    if (!dev) throw new Error("no Dev");
    const devSid = await session(dev.id);
    expect(await say(srv, devSid, call("run_subagent", { title: "Look", task: "Look" }))).toContain(
      "at most 1 agent besides its orchestrator: it has 3",
    );
    expect(
      srv.core.registry.list({ ownerId: "me", removed: true }).some((a) => a.kind === "subagent"),
    ).toBe(false);

    // Two removed: under the limit only when one is left; a removed one comes back only if it fits.
    const writer = srv.core.registry.list({ ownerId: "me" }).find((a) => a.name === "Writer");
    const tester = srv.core.registry.list({ ownerId: "me" }).find((a) => a.name === "Tester");
    if (!writer || !tester) throw new Error("no team");
    expect((await srv.api("POST", `/api/agents/${writer.id}/remove`, {})).status).toBe(200);
    expect((await srv.api("POST", `/api/agents/${tester.id}/remove`, {})).status).toBe(200);
    expect(await project(srv)).toMatchObject({ agents: 1 });
    const back = await srv.api<{ code?: string }>("POST", `/api/agents/${writer.id}/restore`);
    expect(back.status).toBe(409);
    expect(back.body.code).toBe("agent_limit");
    expect(srv.core.registry.get(writer.id)?.status).toBe("removed");
    // Raised to 2: Writer comes back.
    await limit(srv, 2);
    expect((await srv.api("POST", `/api/agents/${writer.id}/restore`)).status).toBe(200);
    expect(team(srv)).toEqual(["Dev", "Writer"]);
  });

  it("the orchestrator and the inspector never count, nor agents of other projects", async () => {
    const { srv, god, godSid } = await start();
    await limit(srv, 0);
    // The inspector is made by the server for the project: never refused.
    await srv.core.inspectorAgent("me", "shop");
    expect(await project(srv)).toMatchObject({ agents: 0 });
    // Another project's agents are counted there.
    await srv.api("POST", "/api/projects", { name: "Blog" });
    expect(
      await say(
        srv,
        godSid,
        call("create_agent", {
          kind: "orchestrator",
          name: "Blog lead",
          role: "Runs the blog",
          project_id: "blog",
        }),
      ),
    ).toMatch(/^Created orchestrator /);
    const lead = srv.core.registry.list({ ownerId: "me" }).find((a) => a.name === "Blog lead");
    expect(
      (
        await srv.api("POST", "/api/agents", {
          kind: "agent",
          parentId: lead?.id,
          projectId: "blog",
          name: "Blogger",
        })
      ).status,
    ).toBe(201);
    expect(await project(srv)).toMatchObject({ agents: 0 });
    expect(god).toBeTruthy();
  });
});
