// p3.8.9 (the person's Coder, 3.8.7): on the web page God made a project with an orchestrator and
// two agents; the app open at the same time still said «no other agents», without the project or
// God's new conversation. Every client of the owner must hear when their agents, projects or
// conversation rows change elsewhere (`lists.changed`), and another owner must hear nothing.
import type { ServerMessage } from "@redgiant/protocol";
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { OTHER, startServer, wsClient } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  const server = s;
  s = undefined;
  await server?.close();
}, 60_000);

const call = (name: string, input: unknown): FakeTurn => ({ toolCalls: [{ name, input }] });
const results = (req: CompletionRequest) => {
  let n = 0;
  for (let i = req.messages.length - 1; i >= 0; i--) {
    const m = req.messages[i];
    if (m?.role !== "user") continue;
    if (m.parts.every((p) => p.type === "tool_result")) n++;
    else break;
  }
  return n;
};

/** God makes a project and its orchestrator, as on the person's page. */
function god(req: CompletionRequest): FakeTurn {
  if (!req.system.startsWith("You are God")) return { text: "ok" };
  const n = results(req);
  if (n === 0) return call("create_project", { name: "GAIA ITAS" });
  if (n === 1)
    return call("create_agent", {
      kind: "orchestrator",
      name: "Orchestratore",
      role: "Runs the plugin",
      project_id: "gaia-itas",
    });
  return { text: "Done." };
}

const lists = (ms: ServerMessage[]) =>
  new Set(ms.flatMap((m) => (m.type === "lists.changed" ? m.lists : [])));

describe("lists.changed (p3.8.9)", () => {
  it("tells every client of the owner, followed or not, what God made; nobody else", async () => {
    s = await startServer(god);
    const server = s;
    const g = await server.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    // The app: connected, following nothing (the wall in view).
    const app = await wsClient(server.url);
    const other = await wsClient(server.url, OTHER);
    await app.waitFor("welcome");
    await other.waitFor("welcome");
    // The page opens a new conversation with God: the app hears of it at once.
    const { body } = await server.api<{ sessionId: string }>("POST", "/api/sessions", {
      agentId: g.body.id,
    });
    await app.waitFor("lists.changed", (m) => m.lists.includes("sessions"));
    const page = await wsClient(server.url);
    page.send({ type: "session.follow", sessionId: body.sessionId });
    await page.waitFor("session.synced");
    const allow = setInterval(() => {
      for (const m of page.messages.splice(0))
        if (m.type === "permission.request")
          page.send({
            type: "permission.resolve",
            requestId: m.request.requestId,
            decision: "allow",
          });
    }, 20);
    try {
      page.send({ type: "session.send", sessionId: body.sessionId, text: "Fai il progetto" });
      await app.waitFor("lists.changed", (m) => m.lists.includes("projects"), 15_000);
      await app.waitFor("lists.changed", (m) => m.lists.includes("agents"), 15_000);
      // The first message named the conversation: the rows are read again for its title.
      await app.waitFor(
        "session.activity",
        (m) => m.sessionId === body.sessionId && m.state === "idle",
        15_000,
      );
    } finally {
      clearInterval(allow);
    }
    expect(lists(app.messages)).toEqual(new Set(["agents", "projects", "sessions"]));
    const listed = await server.api<{ id: string; name: string }[]>("GET", "/api/agents");
    expect(listed.body.map((a) => a.name)).toContain("Orchestratore");

    // Renamed, pinned, archived, a new face, a project archived, from another device: the app
    // hears each.
    const after = async (what: string, change: () => Promise<unknown>) => {
      const before = app.messages.length;
      await change();
      const end = Date.now() + 5000;
      while (!lists(app.messages.slice(before)).has(what)) {
        if (Date.now() > end) throw new Error(`no lists.changed ${what}`);
        await new Promise((r) => setTimeout(r, 20));
      }
    };
    const sid = body.sessionId;
    await after("sessions", () => server.api("PATCH", `/api/sessions/${sid}`, { title: "GAIA" }));
    await after("sessions", () => server.api("PATCH", `/api/sessions/${sid}`, { pinned: true }));
    await after("sessions", () => server.api("PATCH", `/api/sessions/${sid}`, { archived: true }));
    const orch = listed.body.find((a) => a.name === "Orchestratore")?.id ?? "";
    await after("agents", () => server.api("POST", `/api/agents/${orch}/mascot`));
    await after("projects", () => server.api("POST", "/api/projects/gaia-itas/archive"));

    // Another person's connection hears none of it.
    expect(other.messages.some((m) => m.type === "lists.changed")).toBe(false);
    app.close();
    other.close();
    page.close();
  }, 60_000);
});
