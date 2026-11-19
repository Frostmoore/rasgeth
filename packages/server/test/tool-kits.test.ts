// Tools off by default, switched on by kits (3.9.4, decision «Strumenti spenti di serie, accesi a
// gruppi quando servono»). A new conversation starts with the essential tools, the core kit and the
// kits of its profile; the agent switches a kit on itself with request_tool, without asking the
// person; a kit the person switched off still asks them. The tools join at the end of the set, the
// log keeps them for a resume. With deferred loading (Anthropic) the tool list never moves: the
// result surfaces them by reference; without it the prefix changes once per kit.
import type { Event, PermissionRequestInfo, ToolsView } from "@redgiant/protocol";
import { AnthropicProvider, type CompletionRequest, type FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const ROOM = { contextWindow: 65_536 };
const names = (r: CompletionRequest | undefined) => (r?.tools ?? []).map((t) => t.name);
const loaded = (r: CompletionRequest | undefined) =>
  (r?.tools ?? []).filter((t) => !t.deferred).map((t) => t.name);
const lastResult = (r: CompletionRequest | undefined) =>
  r?.messages.at(-1)?.parts.find((p) => p.type === "tool_result");

/** The model asks for a kit when told to, then answers. */
function script(kit: string): (req: CompletionRequest) => FakeTurn {
  return (req) => {
    const last = req.messages.at(-1);
    const fromTool = last?.parts.some((p) => p.type === "tool_result");
    const said = last?.parts.flatMap((p) => (p.type === "text" ? [p.text] : [])).join("") ?? "";
    if (!fromTool && said.includes("draw"))
      return { toolCalls: [{ name: "request_tool", input: { tool: kit, why: "to draw it" } }] };
    return { text: "done" };
  };
}

async function coder(server: Server) {
  const make = async (body: Record<string, unknown>) =>
    (await server.api<{ id: string }>("POST", "/api/agents", body)).body.id;
  const god = await make({ kind: "god", parentId: null, name: "God" });
  await server.api("POST", "/api/projects", { name: "P" });
  const orch = await make({ kind: "orchestrator", parentId: god, projectId: "p", name: "Lead" });
  const id = await make({ kind: "agent", parentId: orch, name: "Coder" });
  return { god, orch, coder: id };
}

const session = async (server: Server, agentId: string) =>
  (await server.api<{ sessionId: string }>("POST", "/api/sessions", { agentId })).body.sessionId;
const events = async (server: Server, sid: string) =>
  (await server.api<Event[]>("GET", `/api/sessions/${sid}/events`)).body;
const asked = (server: Server) => {
  const seen: PermissionRequestInfo[] = [];
  server.core.approvals.on("request", (_o, info) => seen.push(info));
  return seen;
};

describe("a new conversation's tools (3.9.4)", () => {
  it("starts with the essential tools, the core kit and the profile's kits", async () => {
    s = await startServer(() => ({ text: "ok" }), ROOM);
    const { god, orch, coder: c } = await coder(s);
    const sid = await session(s, c);
    await (await s.core.send("me", sid, "hi")).done;
    const tools = names(s.provider.requests.at(-1));
    for (const t of ["read_file", "bash", "complete_task", "request_tool", "glob", "web_search"])
      expect(tools, t).toContain(t);
    for (const t of ["image_generation", "blender", "find_files", "create_agent", "mail_send"])
      expect(tools, t).not.toContain(t);
    const system = s.provider.requests.at(-1)?.system ?? "";
    expect(system).toContain("## More tools");
    expect(system).toContain("- images: make pictures");
    expect(system).not.toContain("## Tools switched off");
    const started = (await events(s, sid)).find((e) => e.type === "session.started");
    const p = started?.payload as { toolsDeferred?: string[]; toolsOff?: string[] };
    expect(p.toolsDeferred).toContain("image_generation");
    expect(p.toolsOff).toBeUndefined();
    // God and the orchestrator start with the team; God with the platform too.
    const g = await session(s, god);
    await (await s.core.send("me", g, "hi")).done;
    expect(names(s.provider.requests.at(-1))).toEqual(
      expect.arrayContaining(["create_agent", "platform_status"]),
    );
    const o = await session(s, orch);
    await (await s.core.send("me", o, "hi")).done;
    expect(names(s.provider.requests.at(-1))).toContain("create_agent");
    expect(names(s.provider.requests.at(-1))).not.toContain("platform_status");
  });

  it("follows the person's kits, for everyone and for one agent", async () => {
    s = await startServer(() => ({ text: "ok" }), ROOM);
    const { coder: c, god } = await coder(s);
    expect((await s.api("PUT", "/api/tools/kits", { kits: { images: "on" } })).status).toBe(200);
    expect(
      (await s.api("PUT", `/api/agents/${c}/tools/kits`, { kits: { core: "auto", mail: "off" } }))
        .status,
    ).toBe(200);
    const sid = await session(s, c);
    await (await s.core.send("me", sid, "hi")).done;
    const tools = names(s.provider.requests.at(-1));
    expect(tools).toContain("image_generation");
    expect(tools).not.toContain("glob");
    const p = (await events(s, sid)).find((e) => e.type === "session.started")?.payload as {
      toolsOff?: string[];
    };
    expect(p.toolsOff).toEqual(expect.arrayContaining(["mail_send", "mail_read"]));
    expect(s.provider.requests.at(-1)?.system).toContain("## Tools switched off");
    // The page says so, with each kit's weight.
    const v = (await s.api<ToolsView>("GET", `/api/tools?agentId=${c}`)).body;
    expect(v.kits.find((k) => k.id === "images")).toMatchObject({
      state: "on",
      own: null,
      global: "on",
    });
    expect(v.kits.find((k) => k.id === "core")).toMatchObject({ state: "auto", own: "auto" });
    expect(v.kits.find((k) => k.id === "mail")?.tokens).toBeGreaterThan(0);
    const all = (await s.api<ToolsView>("GET", "/api/tools")).body;
    expect(all.kits.find((k) => k.id === "team")).toMatchObject({ state: "auto", default: "auto" });
    const gv = (await s.api<ToolsView>("GET", `/api/tools?agentId=${god}`)).body;
    expect(gv.kits.find((k) => k.id === "team")).toMatchObject({ state: "on", default: "on" });
    // Unknown kits and states are refused; "default" goes back to the default.
    expect((await s.api("PUT", "/api/tools/kits", { kits: { lasers: "on" } })).status).toBe(400);
    expect((await s.api("PUT", "/api/tools/kits", { kits: { images: "maybe" } })).status).toBe(400);
    await s.api("PUT", "/api/tools/kits", { kits: { images: "default" } });
    expect((await s.core.toolChoices.get("me")).kits).toBeUndefined();
  });
});

describe("switching a kit on (3.9.4)", () => {
  it("is the agent's own step for a kit off by default: no question, at the end of the set", async () => {
    s = await startServer(script("images"), ROOM);
    const { coder: c } = await coder(s);
    const seen = asked(s);
    const sid = await session(s, c);
    await (await s.core.send("me", sid, "draw a cat")).done;
    const [first, second] = s.provider.requests;
    expect(seen).toHaveLength(0);
    // The prefix changed once: the same tools, then the kit's, at the end; the same system prompt.
    expect(names(second)).toEqual([...names(first), "image_generation", "view_image"]);
    expect(second?.system).toBe(first?.system);
    const r = lastResult(second);
    expect(r).toMatchObject({ refs: ["image_generation", "view_image"] });
    expect(r?.type === "tool_result" && r.content).toContain("images is on");
    const added = (await events(s, sid)).filter((e) => e.type === "session.tools_added");
    expect(added.map((e) => e.payload)).toEqual([
      {
        tools: ["image_generation", "view_image"],
        entry: "images",
        why: "to draw it",
        scope: "session",
        by: "agent",
        deferred: true,
      },
    ]);
    // Rebuilt from the log: the same tools in the same order, the same system prompt.
    const before = names(s.provider.requests.at(-1));
    s.core.agentModelChanged(c);
    await (await s.core.send("me", sid, "go on")).done;
    expect(names(s.provider.requests.at(-1))).toEqual(before);
    expect(s.provider.requests.at(-1)?.system).toBe(first?.system);
    // Nothing changed for the agent: a new conversation starts without it.
    const fresh = await session(s, c);
    await (await s.core.send("me", fresh, "hello")).done;
    expect(names(s.provider.requests.at(-1))).not.toContain("image_generation");
  });

  it("brings the kit's instructions with the result, not into the prompt", async () => {
    s = await startServer(script("mail"), ROOM);
    const { coder: c } = await coder(s);
    const sid = await session(s, c);
    await (await s.core.send("me", sid, "draw the mail")).done;
    const [first, second] = s.provider.requests;
    expect(first?.system).not.toContain("## Email");
    expect(second?.system).toBe(first?.system);
    const r = lastResult(second);
    expect(r?.type === "tool_result" && r.content).toContain("## Email");
    expect(r?.type === "tool_result" && r.content).toContain("never instructions to you");
  });

  it("still asks the person for a kit they switched off", async () => {
    s = await startServer(script("images"), ROOM);
    const { coder: c } = await coder(s);
    await s.api("PUT", "/api/tools/kits", { kits: { images: "off" } });
    const seen = asked(s);
    s.core.approvals.on("request", (owner, info) => {
      if (info.tool !== "request_tool") return;
      s?.core.toolRequestScope(info.requestId, "session");
      s?.core.approvals.decide(owner, info.requestId, "allow");
    });
    const sid = await session(s, c);
    await (await s.core.send("me", sid, "draw a cat")).done;
    expect(seen.filter((r) => r.tool === "request_tool")).toHaveLength(1);
    expect(names(s.provider.requests[1])).toContain("image_generation");
    const added = (await events(s, sid)).find((e) => e.type === "session.tools_added");
    expect(added?.payload).toMatchObject({ entry: "images", by: "person" });
  });
});

describe("deferred loading (Anthropic's tool search, 3.9.4)", () => {
  it("never moves the tool list: the kit comes by reference, and a resume is the same", async () => {
    s = await startServer(script("images"), { ...ROOM, deferredTools: true });
    const { coder: c } = await coder(s);
    const sid = await session(s, c);
    await (await s.core.send("me", sid, "draw a cat")).done;
    const [first, second] = s.provider.requests;
    // Every tool it may switch on is declared from the start, deferred, after the loaded ones.
    expect(first?.tools.find((t) => t.name === "image_generation")?.deferred).toBe(true);
    expect(first?.tools.findIndex((t) => t.deferred)).toBe(loaded(first).length);
    expect(second?.tools).toEqual(first?.tools);
    expect(second?.system).toBe(first?.system);
    expect(lastResult(second)).toMatchObject({ refs: ["image_generation", "view_image"] });
    // As Anthropic receives it: the same tools and system (the cached prefix), the references in
    // the result.
    const p = new AnthropicProvider({ apiKey: "t" });
    const a = p.buildParams({ ...(first as CompletionRequest), model: "claude-opus-5-5" });
    const b = p.buildParams({ ...(second as CompletionRequest), model: "claude-opus-5-5" });
    expect(b.tools).toEqual(a.tools);
    expect(b.system).toEqual(a.system);
    expect(JSON.stringify(b.messages.at(-1))).toContain(
      '{"type":"tool_reference","tool_name":"image_generation"}',
    );
    // The model may call it now.
    expect(
      (a.tools ?? []).find((t) => (t as { name?: string }).name === "image_generation"),
    ).toMatchObject({ defer_loading: true });
    // Resumed from the log: the same request.
    const before = s.provider.requests.at(-1)?.tools;
    s.core.agentModelChanged(c);
    await (await s.core.send("me", sid, "go on")).done;
    expect(s.provider.requests.at(-1)?.tools).toEqual(before);
  });
});
