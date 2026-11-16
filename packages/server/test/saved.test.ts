// Saved passages (G40.14): parts of messages (or whole ones) kept in the person's own archive,
// with where they come from, a note and tags. The origin is read from the person's own
// conversation; another owner's items and messages are never reachable.
import { normalizeTags, type SavedItem, type SavedList, savedMarkdown } from "@redgiant/protocol";
import { afterEach, describe, expect, it } from "vitest";
import { SavedError } from "../src/index.js";
import { startServer, TOKEN } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

const ANSWER = "## Plan\n\nFirst **A**, then [B](https://example.com).\n\n- one\n- two";

async function conversation(server: Server) {
  const g = await server.api<{ id: string }>("POST", "/api/agents", {
    kind: "god",
    parentId: null,
    name: "God",
  });
  const sid = (
    await server.api<{ sessionId: string }>("POST", "/api/sessions", { agentId: g.body.id })
  ).body.sessionId;
  await (await server.core.send("me", sid, "what is the plan?")).done;
  const answer = (await server.core.history("me", sid)).find((e) => e.type === "message.assistant");
  if (!answer) throw new Error("no answer");
  return { agentId: g.body.id, sid, seq: answer.seq, at: answer.ts };
}

describe("tags and the export", () => {
  it("keeps each tag once, without the hash, at most twelve", () => {
    expect(normalizeTags([" #Idee ", "idee", "", "##work", "Work", "x"])).toEqual([
      "Idee",
      "work",
      "x",
    ]);
    expect(normalizeTags(Array.from({ length: 20 }, (_, i) => `t${i}`))).toHaveLength(12);
  });

  it("writes every item with its origin, the Markdown when known, note and tags", () => {
    const item: SavedItem = {
      id: "sav_1",
      text: "First A",
      markdown: "First **A**",
      whole: false,
      note: "remember",
      tags: ["plan"],
      source: {
        kind: "session",
        sessionId: "s1",
        seq: 3,
        agentId: "god",
        agentName: "God",
        title: "The plan",
        messageAt: "2026-11-15T10:00:00.000Z",
      },
      createdAt: "2026-11-16T09:00:00.000Z",
      updatedAt: "2026-11-16T09:00:00.000Z",
    };
    const md = savedMarkdown([item], "it");
    expect(md).toContain("# Salvati");
    expect(md).toContain("## The plan · God — 2026-11-15");
    expect(md).toContain("First **A**");
    expect(md).toContain("**Nota:** remember");
    expect(md).toContain("**Etichette:** #plan");
    expect(savedMarkdown([{ ...item, markdown: null }], "en")).toContain("\nFirst A\n");
  });
});

describe("the saved routes", () => {
  it("saves a part and a whole message with their origin; lists, searches, filters, edits, deletes", async () => {
    s = await startServer(() => ({ text: ANSWER }));
    const c = await conversation(s);

    const part = await s.api<SavedItem>("POST", "/api/saved", {
      source: { kind: "session", sessionId: c.sid, seq: c.seq, start: 8, end: 15 },
      text: "First A",
      markdown: "First **A**",
      note: "  the first step ",
      tags: ["#Plan", "plan", "ideas"],
    });
    expect(part.status).toBe(201);
    expect(part.body).toMatchObject({
      text: "First A",
      markdown: "First **A**",
      whole: false,
      note: "the first step",
      tags: ["Plan", "ideas"],
      source: {
        kind: "session",
        sessionId: c.sid,
        seq: c.seq,
        start: 8,
        end: 15,
        agentId: c.agentId,
        agentName: "God",
        title: "what is the plan?",
        messageAt: c.at,
      },
    });

    // The whole message: its Markdown from the log, its text near plain.
    const whole = await s.api<SavedItem>("POST", "/api/saved", {
      source: { kind: "session", sessionId: c.sid, seq: c.seq },
    });
    expect(whole.status).toBe(201);
    expect(whole.body.whole).toBe(true);
    expect(whole.body.markdown).toBe(ANSWER);
    expect(whole.body.text).toContain("First A, then B.");
    expect(whole.body.text).not.toContain("**");

    // Not a model's message, or no message there: not found.
    const wrong = await s.api("POST", "/api/saved", {
      source: { kind: "session", sessionId: c.sid, seq: c.seq - 1 },
    });
    expect(wrong.status).toBe(404);
    const bad = await s.api("POST", "/api/saved", { source: { kind: "session" } });
    expect(bad.status).toBe(400);

    const all = await s.api<SavedList>("GET", "/api/saved");
    expect(all.body.items.map((i) => i.id)).toEqual([whole.body.id, part.body.id]);
    expect(all.body.tags).toEqual([
      { tag: "ideas", count: 1 },
      { tag: "Plan", count: 1 },
    ]);
    expect(all.body.agents).toEqual([{ id: c.agentId, name: "God", count: 2 }]);

    const found = await s.api<SavedList>("GET", "/api/saved?q=first%20step");
    expect(found.body.items.map((i) => i.id)).toEqual([part.body.id]);
    // `%` is a character, not a pattern.
    expect((await s.api<SavedList>("GET", "/api/saved?q=%25")).body.items).toEqual([]);
    const tagged = await s.api<SavedList>("GET", "/api/saved?tag=plan");
    expect(tagged.body.items.map((i) => i.id)).toEqual([part.body.id]);
    const byAgent = await s.api<SavedList>(
      "GET",
      `/api/saved?agentId=${encodeURIComponent(c.agentId)}&limit=1`,
    );
    expect(byAgent.body.items.map((i) => i.id)).toEqual([whole.body.id]);
    expect(byAgent.body.more).toBe(true);
    const next = await s.api<SavedList>(
      "GET",
      `/api/saved?limit=1&before=${encodeURIComponent(whole.body.createdAt)}`,
    );
    expect(next.body.items.map((i) => i.id)).toEqual([part.body.id]);

    const edited = await s.api<SavedItem>("PATCH", `/api/saved/${part.body.id}`, {
      note: "changed",
      tags: [],
    });
    expect(edited.body).toMatchObject({ note: "changed", tags: [], text: "First A" });
    expect((await s.api("PATCH", `/api/saved/${part.body.id}`, {})).status).toBe(400);

    const r = await fetch(`${s.url}/api/saved/export?lang=it`, {
      headers: { authorization: `Bearer ${TOKEN}` },
    });
    expect(r.headers.get("content-type")).toContain("text/markdown");
    const md = await r.text();
    expect(md).toContain("# Salvati");
    expect(md).toContain("**Nota:** changed");
    expect(md).toContain(ANSWER);

    expect((await s.api("DELETE", `/api/saved/${part.body.id}`)).status).toBe(200);
    expect((await s.api("GET", `/api/saved/${part.body.id}`)).status).toBe(404);
    expect((await s.api("DELETE", `/api/saved/${part.body.id}`)).status).toBe(404);
  });

  it("never reaches another owner's messages or items", async () => {
    s = await startServer(() => ({ text: ANSWER }));
    const c = await conversation(s);
    const mine = await s.core.saved.create("me", {
      source: { kind: "session", sessionId: c.sid, seq: c.seq },
    });
    // Someone else cannot save from my conversation, nor see, change or delete my items.
    await expect(
      s.core.saved.create("other", { source: { kind: "session", sessionId: c.sid, seq: c.seq } }),
    ).rejects.toBeInstanceOf(SavedError);
    expect(await s.core.saved.get("other", mine.id)).toBeNull();
    expect(await s.core.saved.update("other", mine.id, { note: "x" })).toBeNull();
    expect(await s.core.saved.remove("other", mine.id)).toBe(false);
    expect((await s.core.saved.list("other")).items).toEqual([]);
    expect((await s.core.saved.list("me")).items).toHaveLength(1);
  });

  it("saves from a daily chat of the owner", async () => {
    s = await startServer(() => ({ text: "ok" }));
    const db = s.core.db;
    await db.query("INSERT INTO rg_chats (id, owner_id, title) VALUES ($1, $2, $3)", [
      "chat_1",
      "me",
      "Recipes",
    ]);
    const [m] = await db.query<{ id: string | number }>(
      "INSERT INTO rg_chat_messages (chat_id, message) VALUES ($1, $2) RETURNING id",
      [
        "chat_1",
        JSON.stringify({ role: "assistant", parts: [{ type: "text", text: "Use *salt*." }] }),
      ],
    );
    const r = await s.api<SavedItem>("POST", "/api/saved", {
      source: { kind: "chat", chatId: "chat_1", messageId: Number(m?.id) },
    });
    expect(r.status).toBe(201);
    expect(r.body).toMatchObject({
      markdown: "Use *salt*.",
      whole: true,
      source: { kind: "chat", chatId: "chat_1", title: "Recipes", agentId: null },
    });
    await expect(
      s.core.saved.create("other", {
        source: { kind: "chat", chatId: "chat_1", messageId: Number(m?.id) },
      }),
    ).rejects.toBeInstanceOf(SavedError);
  });
});
