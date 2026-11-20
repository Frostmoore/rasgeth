import { EventStore, migrate, Redactor, type SqlClient } from "@redgiant/events";
import type { AgentNode, AgentRegistry } from "@redgiant/hierarchy";
import type { CompletionRequest } from "@redgiant/protocol";
import type { FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import {
  ConversationIndex,
  echoQuery,
  echoReaders,
  migrateEcho,
  resolveAgent,
  searchConversationsTool,
  unmark,
} from "../src/echo.js";
import { migrateProjects } from "../src/projects.js";
import { startServer } from "./helpers.js";
import { memoryDb } from "./pglite.js";

/** A log, the sessions' table and the index, with nothing else of the server. */
async function bare() {
  const { db } = await memoryDb();
  await migrate(db);
  await migrateProjects(db);
  await migrateEcho(db);
  const store = new EventStore(db);
  const redactor = new Redactor().addSecret("vault-entry", "correct-horse-battery");
  const index = new ConversationIndex({
    db,
    store,
    redact: (t) => redactor.redactText(t).text,
    delayMs: 0,
  });
  const session = async (id: string, agentId: string, title: string, owner = "me") => {
    await db.query(
      "INSERT INTO rg_sessions (id, owner_id, agent_id, project_id, title) VALUES ($1, $2, $3, $4, $5)",
      [id, owner, agentId, "p1", title],
    );
  };
  const say = (sessionId: string, agentId: string, text: string, owner = "me", from?: string) =>
    store.append({
      ownerId: owner,
      projectId: "p1",
      agentId,
      sessionId,
      body: { type: "message.user", payload: { text, ...(from ? { from } : {}) } },
    });
  const answer = (sessionId: string, agentId: string, text: string, owner = "me") =>
    store.append({
      ownerId: owner,
      projectId: "p1",
      agentId,
      sessionId,
      body: {
        type: "message.assistant",
        payload: {
          parts: [
            { type: "text", text },
            { type: "tool_call", id: "c1", name: "bash", input: { command: "echo toolnoise" } },
          ],
          stopReason: "tool_use",
        },
      } as never,
    });
  return { db, store, index, session, say, answer };
}

const count = async (db: SqlClient) =>
  Number((await db.query<{ n: string }>("SELECT count(*) AS n FROM rg_echo_messages"))[0]?.n);

describe("Echo: the conversations' index (3.9.6)", () => {
  it("indexes what the person and the agents said, never the tools, and finds it by prefixes", async () => {
    const b = await bare();
    await b.session("s1", "a1", "Invoices");
    await b.session("s2", "a1", "Holidays");
    await b.say("s1", "a1", "The invoices for Rossi are wrong since October");
    await b.answer("s1", "a1", "I fixed the rounding in billing.py; invoices now add up.");
    await b.say("s2", "a1", "Book the train to Lisbon");
    const hits = await b.index.search("me", { query: "invoice rounding", agents: ["a1"] });
    expect(hits.map((h) => h.sessionId)).toEqual(["s1"]);
    expect(hits[0]).toMatchObject({
      title: "Invoices",
      agentId: "a1",
      projectId: "p1",
      matches: 1,
    });
    const s = hits[0]?.snippets[0];
    expect(s?.role).toBe("agent");
    expect(s?.marks.map(([a, z]) => s.text.slice(a, z).toLowerCase())).toEqual(
      expect.arrayContaining(["rounding", "invoices"]),
    );
    // Every word in one message first; else any of them (here: two conversations).
    const either = await b.index.search("me", { query: "lisbon rossi", agents: ["a1"] });
    expect(either.map((h) => h.sessionId).sort()).toEqual(["s1", "s2"]);
    // Tool calls never enter the index.
    expect(await b.index.search("me", { query: "toolnoise", agents: ["a1"] })).toEqual([]);
    expect(await b.index.search("me", { query: "x", agents: ["a1"] })).toEqual([]);
  });

  it("is incremental: each catch-up reads only what came after its cursor", async () => {
    const b = await bare();
    await b.session("s1", "a1", "One");
    await b.say("s1", "a1", "first message about kiwis");
    expect(await b.index.catchUp()).toBe(1);
    expect(await b.index.catchUp()).toBe(0);
    await b.answer("s1", "a1", "second message about kiwis");
    await b.say("s1", "a1", "third, about mangoes");
    expect(await b.index.catchUp()).toBe(2);
    expect(await count(b.db)).toBe(3);
    // A new index on the same tables (a restart) goes on from the cursor, it does not start over.
    const again = new ConversationIndex({ db: b.db, store: b.store, redact: (t) => t });
    expect(await again.catchUp()).toBe(0);
    const [hit] = await again.search("me", { query: "kiwis", agents: ["a1"] });
    expect(hit?.matches).toBe(2);
  });

  it("follows the log by itself once started", async () => {
    const b = await bare();
    await b.session("s1", "a1", "Live");
    const stop = b.index.start();
    try {
      await b.say("s1", "a1", "papaya plantation");
      await expect.poll(async () => count(b.db), { timeout: 2000, interval: 20 }).toBe(1);
    } finally {
      stop();
    }
  });

  it("never returns erased messages, nor conversations taken away", async () => {
    const b = await bare();
    await b.session("s1", "a1", "Private");
    await b.session("s2", "a1", "Kept");
    const gone = await b.say("s1", "a1", "my blood test results: glucose fine");
    await b.say("s2", "a1", "the glucose meter manual is in docs/");
    await b.index.catchUp();
    expect((await b.index.search("me", { query: "glucose", agents: ["a1"] })).length).toBe(2);
    // Erased after it was indexed: the search joins the log, so it is gone at once…
    await b.store.erase(gone.seq, "the person asked");
    // …and the catch-up (its redaction event) drops the row.
    const hits = await b.index.search("me", { query: "glucose", agents: ["a1"] });
    expect(hits.map((h) => h.sessionId)).toEqual(["s2"]);
    expect(await count(b.db)).toBe(1);
    // Everything before a date (retention).
    await b.store.eraseBefore(new Date(Date.now() + 60_000), "retention", "me");
    expect(await b.index.search("me", { query: "glucose", agents: ["a1"] })).toEqual([]);
    expect(await count(b.db)).toBe(0);
    // A conversation removed from the list (an imported one taken away).
    await b.session("s3", "a1", "Imported");
    await b.say("s3", "a1", "imported note about glucose");
    expect((await b.index.search("me", { query: "glucose", agents: ["a1"] })).length).toBe(1);
    await b.db.query("DELETE FROM rg_sessions WHERE id = 's3'");
    expect(await b.index.search("me", { query: "glucose", agents: ["a1"] })).toEqual([]);
  });

  it("never gives back a secret: the recogniser runs once more before indexing", async () => {
    const b = await bare();
    await b.session("s1", "a1", "Keys");
    // The log here has no Redactor (as for a message sent with «Send anyway»).
    await b.say("s1", "a1", "use sk-ant-api03-abcdefghijklmnopqrstuvwx1234 for the deploy");
    await b.say("s1", "a1", "the wifi password reminder is correct-horse-battery deploy");
    const hits = await b.index.search("me", { query: "deploy", agents: ["a1"] });
    const text = JSON.stringify(hits);
    expect(text).not.toContain("sk-ant-api03");
    expect(text).not.toContain("correct-horse-battery");
    expect(
      await b.index.search("me", { query: "abcdefghijklmnopqrstuvwx1234", agents: ["a1"] }),
    ).toEqual([]);
    const rows = await b.db.query<{ body: string }>("SELECT body FROM rg_echo_messages");
    expect(rows.map((r) => r.body).join(" ")).toContain("[REDACTED:");
  });

  it("finds only the given agents' conversations of the same owner, never the one asking", async () => {
    const b = await bare();
    await b.session("s1", "a1", "Mine");
    await b.session("s2", "a2", "Another agent's");
    await b.session("s3", "a1", "Someone else's", "other");
    await b.say("s1", "a1", "the quokka report");
    await b.say("s2", "a2", "the quokka budget");
    await b.say("s3", "a1", "the quokka secret", "other");
    const ids = async (o: Parameters<ConversationIndex["search"]>[1], owner = "me") =>
      (await b.index.search(owner, o)).map((h) => h.sessionId).sort();
    expect(await ids({ query: "quokka", agents: ["a1", "a2"] })).toEqual(["s1", "s2"]);
    expect(await ids({ query: "quokka", agents: ["a1"] })).toEqual(["s1"]);
    expect(await ids({ query: "quokka", agents: ["a1", "a2"], agentId: "a2" })).toEqual(["s2"]);
    // agentId outside the allowed agents finds nothing.
    expect(await ids({ query: "quokka", agents: ["a1"], agentId: "a2" })).toEqual([]);
    expect(await ids({ query: "quokka", agents: ["a1", "a2"], exceptSession: "s1" })).toEqual([
      "s2",
    ]);
    expect(await ids({ query: "quokka", agents: [] })).toEqual([]);
    expect(await ids({ query: "quokka", agents: ["a1"] }, "other")).toEqual(["s3"]);
  });

  it("turns queries into prefixes of letters and digits, and headlines into offsets", () => {
    expect(echoQuery("Fattura  ROSSI 2026!", "&")).toBe("fattura:* & rossi:* & 2026:*");
    expect(echoQuery("a b 'or' & | !", "|")).toBe("or:*");
    expect(echoQuery("città perché", "|")).toBe("città:* | perché:*");
    expect(echoQuery("!", "&")).toBeNull();
    expect(unmark("the ⟪word⟫ here")).toEqual({ text: "the word here", marks: [[4, 8]] });
    expect(unmark("**bold** ⟪code⟫ `x`")).toEqual({ text: "bold code x", marks: [[5, 9]] });
  });
});

/** The team of scopes.test.ts in small: who may find whose conversations is `can`'s "read". */
const team: AgentNode[] = [
  { id: "G", name: "God", kind: "god", parentId: null, projectId: null, ownerId: "me" },
  { id: "O1", name: "Lead 1", kind: "orchestrator", parentId: "G", projectId: "p1", ownerId: "me" },
  { id: "A1", name: "Dev 1", kind: "agent", parentId: "O1", projectId: "p1", ownerId: "me" },
  { id: "S1", name: "Helper", kind: "subagent", parentId: "A1", projectId: "p1", ownerId: "me" },
  { id: "A2", name: "Dev 2", kind: "agent", parentId: "O1", projectId: "p1", ownerId: "me" },
  { id: "O2", name: "Lead 2", kind: "orchestrator", parentId: "G", projectId: "p2", ownerId: "me" },
  { id: "B1", name: "Dev 3", kind: "agent", parentId: "O2", projectId: "p2", ownerId: "me" },
  {
    id: "A9",
    name: "Old",
    kind: "agent",
    parentId: "G",
    projectId: "p9",
    ownerId: "me",
    archived: true,
  },
  { id: "X", name: "Theirs", kind: "god", parentId: null, projectId: null, ownerId: "other" },
];
const registry = {
  list: ({ ownerId }: { ownerId?: string } = {}) =>
    team.filter((a) => ownerId === undefined || a.ownerId === ownerId),
  resolve: (id: string) => team.find((a) => a.id === id),
} as unknown as AgentRegistry;

describe("Echo: who finds whose conversations", () => {
  // asker → the agents whose conversations it may find ("*": every agent of the owner).
  const TABLE = `
    human  *
    G      G O1 A1 S1 A2 O2 B1 A9
    O1     O1 A1 S1 A2
    O2     O2 B1
    A1     A1 S1
    A2     A2
    S1     S1
    A9     A9
  `;
  const rows = TABLE.trim()
    .split("\n")
    .map((l) => l.trim().split(/\s+/));
  it.each(rows)("%s finds %s", (asker, ...expected) => {
    const found =
      asker === "human"
        ? echoReaders(registry, "me", { kind: "human" })
        : echoReaders(registry, "me", {
            kind: "agent",
            agent: team.find((a) => a.id === asker) as AgentNode,
          });
    const all = team.filter((a) => a.ownerId === "me").map((a) => a.id);
    expect(found.sort()).toEqual((expected[0] === "*" ? all : expected).sort());
    // Never another owner's.
    expect(found).not.toContain("X");
  });
});

describe("Echo: search_conversations", () => {
  type Server = Awaited<ReturnType<typeof startServer>>;
  let s: Server | undefined;
  afterEach(async () => {
    await s?.close();
    s = undefined;
  });

  it("formats conversations with their link, place and passages; archived ones say so", async () => {
    const b = await bare();
    await b.session("s1", "a1", "Rounding [bug]");
    await b.answer("s1", "a1", "Fixed the rounding of invoices in billing.py");
    const tool = searchConversationsTool({
      index: () => b.index,
      readers: () => ["a1"],
      agentName: (id) => (id === "a1" ? "Dev 1" : id),
      projectName: async (id) => (id === "p1" ? "Shop" : null),
      archived: (id) => id === "p1",
    });
    const ctx = { ownerId: "me", projectId: null, agentId: "a2", sessionId: "s9" };
    const out = await tool.run({ query: "rounding" }, ctx);
    expect(out).toMatch(/^1 conversation found:/);
    expect(out).toContain("[Rounding bug](#conv:s1)");
    expect(out).toContain("Dev 1, project Shop, archived, read only");
    expect(out).toContain("Agent: Fixed the **rounding** of invoices");
    expect(await tool.run({ query: "lisbon" }, ctx)).toBe("No past conversation has «lisbon».");
    expect(await tool.run({ query: "rounding", agent_id: "a7" }, ctx)).toMatchObject({
      isError: true,
    });
    // 3.9.8: by name, by its kind's alias, and the caller's own conversations.
    expect(await tool.run({ query: "rounding", agent_id: "dev 1" }, ctx)).toMatch(
      /^1 conversation found:/,
    );
    expect(await tool.run({ query: "rounding", agent_id: "me" }, ctx)).toBe(
      "No past conversation has «rounding».",
    );
  });

  it("resolves an agent named by id, name, alias or kind prefix (3.9.8)", () => {
    const name = (id: string) => ({ god_x1: "God", a1: "Dev 1" })[id] ?? id;
    const agents = ["god_x1", "a1"];
    expect(resolveAgent("a1", agents, "god_x1", name)).toBe("a1");
    expect(resolveAgent("god", agents, "god_x1", name)).toBe("god_x1");
    expect(resolveAgent("God", agents, "a1", name)).toBe("god_x1");
    expect(resolveAgent("me", agents, "god_x1", name)).toBe("god_x1");
    expect(resolveAgent("DEV 1", agents, "god_x1", name)).toBe("a1");
    expect(resolveAgent("a7", agents, "god_x1", name)).toBeNull();
    expect(resolveAgent("god", ["god_x1", "god_x2"], null, () => "x")).toBeNull();
  });

  it("is an agent's tool on the server, and the page's search gives the same conversations", async () => {
    const results: string[] = [];
    let searching = false;
    s = await startServer((req: CompletionRequest): FakeTurn => {
      if (!searching) return { text: "Noted: the warehouse code is MAG-4471." };
      const last = req.messages.at(-1)?.parts.find((p) => p.type === "tool_result");
      if (last && last.type === "tool_result") {
        results.push(
          typeof last.content === "string" ? last.content : JSON.stringify(last.content),
        );
        return { text: "done" };
      }
      return {
        toolCalls: [{ id: "t1", name: "search_conversations", input: { query: "warehouse" } }],
      };
    });
    const god = (
      await s.api<{ id: string }>("POST", "/api/agents", {
        kind: "god",
        parentId: null,
        name: "God",
      })
    ).body.id;
    const old = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god })).body
      .sessionId;
    await (await s.core.send("me", old, "Where is the warehouse code written?")).done;
    searching = true;
    const now = (await s.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: god })).body
      .sessionId;
    await (await s.core.send("me", now, "what did we say about the warehouse?")).done;
    expect(results[0]).toMatch(/^1 conversation found:/);
    expect(results[0]).toContain(`(#conv:${old})`);
    expect(results[0]).not.toContain(`#conv:${now}`);
    expect(results[0]).toContain("MAG-4471");

    type Hit = { sessionId: string; archived: boolean; snippets: { text: string }[] };
    const page = (await s.api<Hit[]>("GET", "/api/conversations/search?q=warehouse")).body;
    expect(page.map((h) => h.sessionId).sort()).toEqual([now, old].sort());
    expect(page.every((h) => h.archived === false)).toBe(true);
    expect(
      (
        await s.api<Hit[]>(
          "GET",
          "/api/conversations/search?q=warehouse",
          undefined,
          "other-token-0123456789",
        )
      ).body,
    ).toEqual([]);
    expect((await s.api<Hit[]>("GET", "/api/conversations/search?q=")).body).toEqual([]);
  });
});
