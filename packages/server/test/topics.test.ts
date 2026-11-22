// God's conversations by topic (3.12): routing (rules, the light router, God's fallback), the
// prefix that stays the same, `<meanwhile>`, «Move», the migration, the automatic archive, the
// summaries and the «for: Title» labels. PGlite + FakeProvider: no real model.
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { rebuildHistory } from "@redgiant/agent";
import { type Event, routeByRules } from "@redgiant/protocol";
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { type RouterFn, SUMMARY_SYSTEM, WarmRouter } from "../src/topics.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});
const here = dirname(fileURLToPath(import.meta.url));
const SET = JSON.parse(readFileSync(join(here, "fixtures/topics-routing.json"), "utf8")) as {
  lastGod: string;
  topics: { id: string; title: string; summary: string }[];
  messages: { text: string; want: string; rule?: string }[];
};

const textOf = (req: CompletionRequest, role: "user" | "assistant" = "user") => {
  const m = [...req.messages].reverse().find((x) => x.role === role);
  return (m?.parts ?? []).flatMap((p) => (p.type === "text" ? [p.text] : [])).join("\n");
};
const ME = "me";

/** God answers «answer: <first words>»; summaries answer JSON. */
const godScript =
  (more?: (req: CompletionRequest) => FakeTurn | undefined) =>
  (req: CompletionRequest): FakeTurn => {
    if (req.system === SUMMARY_SYSTEM)
      return {
        text: '{"summary":"Il preventivo per Rossi, quasi pronto.","title":"Preventivo Rossi"}',
      };
    const m = more?.(req);
    if (m) return m;
    return { text: `answer: ${textOf(req).split("\n")[0]?.slice(0, 40)}` };
  };

async function withGod(
  script: ReturnType<typeof godScript>,
  router?: RouterFn,
): Promise<{ s: Server; god: string }> {
  const srv = await startServer(
    script,
    {},
    {
      ...(router && {
        topicsRouter: async () => ({ fn: router, model: { provider: "fake", model: "router" } }),
      }),
    },
  );
  s = srv;
  const god = await srv.api<{ id: string }>("POST", "/api/agents", {
    kind: "god",
    parentId: null,
    name: "God",
  });
  return { s: srv, god: god.body.id };
}

const events = (srv: Server, sessionId: string) => srv.core.store.list({ sessionId });
const types = (es: Event[]) => es.map((e) => e.type).filter((t) => t !== "message.assistant.delta");

describe("God's topics: the routes and the routing", () => {
  it("«New topic» opens one, routed and named, listed in «Oggi»", async () => {
    const { s } = await withGod(godScript());
    const r = await s.api<{
      sessionId: string;
      routed: { isNew: boolean; via: string; title: string };
    }>("POST", "/api/god/messages", {
      text: "Prepara il preventivo per Rossi Srl\ncon hosting",
      newTopic: true,
    });
    expect(r.status).toBe(202);
    expect(r.body.routed).toMatchObject({
      isNew: true,
      via: "person",
      title: "Prepara il preventivo per Rossi Srl",
    });
    await s.core.topics
      .send(ME, { text: "e la manutenzione", topicId: r.body.sessionId })
      .then((x) => x.done);
    const es = await events(s, r.body.sessionId);
    const t = types(es);
    // The topic's start, why the message came, then the message.
    expect(t.slice(0, 4)).toEqual([
      "session.started",
      "topic.opened",
      "topic.routed",
      "message.user",
    ]);
    expect(t.filter((x) => x === "topic.routed")).toHaveLength(2);
    const list = await s.api<{
      topics: { id: string; title: string; state: string }[];
      archived: number;
    }>("GET", "/api/god/topics");
    expect(list.body.topics).toEqual([
      expect.objectContaining({
        id: r.body.sessionId,
        title: "Prepara il preventivo per Rossi Srl",
        state: "ready",
      }),
    ]);
    expect(list.body.archived).toBe(0);
    // Archive, restore and read: events, not rewrites.
    expect((await s.api("POST", `/api/god/topics/${r.body.sessionId}/archive`)).status).toBe(200);
    expect((await s.api<{ archived: number }>("GET", "/api/god/topics")).body.archived).toBe(1);
    expect((await s.api("POST", `/api/god/topics/${r.body.sessionId}/restore`)).status).toBe(200);
    expect((await s.api("POST", "/api/god/topics/sess_nope/read")).status).toBe(404);
    const after = types(await events(s, r.body.sessionId));
    expect(after).toContain("topic.archived");
    expect(after).toContain("topic.restored");
  });

  it("the light router picks the topic; an unsure choice is marked; a bad answer goes to the fallback", async () => {
    const answers: string[] = [];
    const router: RouterFn = async (call) => {
      expect(call.text).toContain("<topics>");
      return answers.shift() ?? "not json";
    };
    const { s } = await withGod(godScript(), router);
    const a = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await a.done;
    const b = await s.core.topics.send(ME, { text: "Backup del NAS", newTopic: true });
    await b.done;
    answers.push(`{"topic":"${a.sessionId}","confidence":0.9}`);
    const c = await s.core.topics.send(ME, {
      text: "aggiungi l'hosting al preventivo per il cliente",
    });
    expect(c.routed).toMatchObject({
      topicId: a.sessionId,
      via: "router",
      uncertain: false,
      isNew: false,
    });
    await c.done;
    answers.push(`{"topic":"${b.sessionId}","confidence":0.3}`);
    const d = await s.core.topics.send(ME, { text: "e quel disco che faceva rumore stanotte?" });
    expect(d.routed).toMatchObject({ topicId: b.sessionId, via: "router", uncertain: true });
    await d.done;
    answers.push('{"topic":"new","title":"Cena di sabato","confidence":0.8}');
    const e = await s.core.topics.send(ME, { text: "organizza una cena per otto persone sabato" });
    expect(e.routed).toMatchObject({ isNew: true, title: "Cena di sabato", via: "router" });
    await e.done;
    // Not JSON: never a topic at random, the fallback (the person wrote in «Cena» just now).
    answers.push("I think the first one");
    const f = await s.core.topics.send(ME, {
      text: "ricordami anche il vino per la cena di sabato sera",
    });
    expect(f.routed).toMatchObject({
      topicId: e.sessionId,
      via: "fallback",
      reason: "recent_person",
    });
    await f.done;
    // A topic the router made up: the fallback too.
    answers.push('{"topic":"sess_madeup","confidence":0.99}');
    const g = await s.core.topics.send(ME, { text: "e il dolce per la cena chi lo porta poi" });
    expect(g.routed.via).toBe("fallback");
    await g.done;
  });

  it("short replies go where God spoke last; the rules table holds on the 40 messages", async () => {
    // The 40 messages of phase 0 against the rules alone: only the short replies are decided.
    const now = Date.now();
    const active = SET.topics.map((t, i) => ({
      id: t.id,
      lastAt: now - (i + 1) * 3_600_000,
      ...(t.id === SET.lastGod && { godAt: now - 60_000 }),
    }));
    for (const m of SET.messages) {
      const r = routeByRules({ text: m.text, now, active });
      if (m.rule) expect(r, m.text).toEqual({ to: m.want, via: "rule", reason: m.rule });
      else expect(r, m.text).toBeUndefined();
    }
    expect(SET.messages).toHaveLength(40);
    // In the server: «ok» goes where God answered last, without the router.
    let asked = 0;
    const { s } = await withGod(godScript(), async () => {
      asked++;
      return "{}";
    });
    const a = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await a.done;
    const b = await s.core.topics.send(ME, { text: "Backup del NAS", newTopic: true });
    await b.done;
    const ok = await s.core.topics.send(ME, { text: "ok" });
    expect(ok.routed).toMatchObject({ topicId: b.sessionId, via: "rule", reason: "short_reply" });
    await ok.done;
    expect(asked).toBe(0);
  });

  it("the router's plumbing on the 40 messages: each answer lands where it says", async () => {
    const queue: string[] = [];
    const { s } = await withGod(godScript(), async () => queue.shift() ?? "{}");
    const ids = new Map<string, string>();
    for (const t of SET.topics) {
      const r = await s.core.topics.send(ME, { text: t.title, newTopic: true });
      await r.done;
      ids.set(t.id, r.sessionId);
    }
    let right = 0;
    for (const m of SET.messages.filter((x) => !x.rule).slice(0, 12)) {
      const want = m.want === "new" ? "new" : ids.get(m.want);
      queue.push(`{"topic":"${want}","title":"${m.text.slice(0, 20)}","confidence":0.9}`);
      const r = await s.core.topics.send(ME, { text: m.text });
      await r.done;
      if (m.want === "new" ? r.routed.isNew : r.routed.topicId === want) right++;
    }
    expect(right).toBe(12);
  });
});

describe("God's topics: the prefix stays the same", () => {
  it("one system prompt for topics born together and across turns; <meanwhile> only in messages", async () => {
    const seen: CompletionRequest[] = [];
    const { s } = await withGod(
      godScript((req) => {
        seen.push(req);
        return undefined;
      }),
    );
    const a = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await a.done;
    const b = await s.core.topics.send(ME, { text: "Backup del NAS", newTopic: true });
    await b.done;
    const a2 = await s.core.topics.send(ME, { text: "e l'hosting?", topicId: a.sessionId });
    await a2.done;
    const god = seen.filter((r) => r.system !== SUMMARY_SYSTEM);
    expect(god.length).toBe(3);
    expect(new Set(god.map((r) => r.system)).size).toBe(1);
    expect(new Set(god.map((r) => JSON.stringify(r.tools.map((t) => t.name)))).size).toBe(1);
    expect(god[0]?.system).not.toContain("Preventivo");
    // The second topic's first message knows the first one, as data after the person's words.
    const first = textOf(god[1] as CompletionRequest);
    expect(first.startsWith("Backup del NAS")).toBe(true);
    expect(first).toContain("<meanwhile>");
    expect(first).toContain(a.sessionId);
    // The history rebuilt from the log is the one the session had: the new events change nothing.
    const es = await events(s, a.sessionId);
    const plain = es.filter((e) => !e.type.startsWith("topic.") && e.type !== "message.moved");
    expect(rebuildHistory(es)).toEqual(rebuildHistory(plain));
    expect(god[0]?.tools.map((t) => t.name)).toEqual(
      expect.arrayContaining(["list_topics", "read_topic", "route_message"]),
    );
  });

  it("without a router the message carries <topics>; God's route_message moves it and answers there", async () => {
    let target = "";
    const { s } = await withGod(
      godScript((req) => {
        const t = textOf(req);
        const results = req.messages.at(-1)?.parts.some((p) => p.type === "tool_result");
        if (t.includes("<topics>") && t.includes("Lisbona") && !results)
          return { toolCalls: [{ name: "route_message", input: { topic_id: target } }] };
        if (results) return { text: "Spostato." };
        return undefined;
      }),
    );
    const a = await s.core.topics.send(ME, { text: "Viaggio a Lisbona", newTopic: true });
    await a.done;
    target = a.sessionId;
    const b = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await b.done;
    // No router: the fallback picks the topic the person wrote in last (Rossi).
    const c = await s.core.topics.send(ME, {
      text: "che tempo farà a Lisbona a marzo, più o meno",
    });
    expect(c.routed).toMatchObject({ topicId: b.sessionId, via: "fallback" });
    await c.done;
    await waitIdle(s);
    const from = await events(s, b.sessionId);
    expect(from.find((e) => e.type === "message.moved")?.payload).toMatchObject({
      toSessionId: a.sessionId,
      by: "god",
    });
    const there = await events(s, a.sessionId);
    const moved = there.findLast((e) => e.type === "message.user");
    expect(moved?.payload).toMatchObject({
      text: "che tempo farà a Lisbona a marzo, più o meno",
      movedFrom: { sessionId: b.sessionId },
    });
    expect(there.findLast((e) => e.type === "topic.routed")?.payload).toMatchObject({ via: "god" });
  });
});

async function waitIdle(srv: Server, ms = 5000) {
  const end = Date.now() + ms;
  while (srv.core.busySessions().length > 0 && Date.now() < end)
    await new Promise((r) => setTimeout(r, 20));
}

describe("God's topics: «Move»", () => {
  it("moves an exchange: the history it leaves is unchanged, God answers again there with the old answer as data, tasks follow", async () => {
    const seen: CompletionRequest[] = [];
    const { s, god } = await withGod(
      godScript((req) => {
        seen.push(req);
        return undefined;
      }),
    );
    const a = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await a.done;
    const b = await s.core.topics.send(ME, { text: "Backup del NAS", newTopic: true });
    await b.done;
    // The person wrote about the NAS in the quote's topic.
    const wrong = await s.core.topics.send(ME, { text: "il NAS fa rumore", topicId: a.sessionId });
    await wrong.done;
    const before = await events(s, a.sessionId);
    const seq = before.findLast((e) => e.type === "message.user")?.seq ?? -1;
    // A task handed over in that exchange.
    const godRec = s.core.registry.get(god);
    if (!godRec) throw new Error("no God");
    const task = await s.core.tasks.open(godRec, "sess_child", "Check the disk", {
      agentId: god,
      sessionId: a.sessionId,
      name: "God",
    });
    const r = await s.api<{ sessionId: string; tasks: string[]; throughSeq: number }>(
      "POST",
      `/api/sessions/${a.sessionId}/messages/${seq}/move`,
      { to: b.sessionId },
    );
    expect(r.status).toBe(200);
    expect(r.body).toMatchObject({ sessionId: b.sessionId, tasks: [task.id] });
    await waitIdle(s);
    const after = await events(s, a.sessionId);
    expect(rebuildHistory(after)).toEqual(rebuildHistory(before));
    expect(after.find((e) => e.type === "message.moved")?.payload).toMatchObject({
      seq,
      toSessionId: b.sessionId,
      by: "person",
    });
    expect(s.core.tasks.get(task.id)?.from?.sessionId).toBe(b.sessionId);
    const there = await events(s, b.sessionId);
    const msg = there.findLast((e) => e.type === "message.user");
    expect(msg?.payload).toMatchObject({
      text: "il NAS fa rumore",
      movedFrom: { sessionId: a.sessionId, seq },
    });
    const notes = ((msg?.payload ?? {}) as { notes?: string[] }).notes?.join("\n") ?? "";
    expect(notes).toContain("<earlier_answer>");
    expect(notes).toContain("answer: il NAS fa rumore");
    expect(
      there.at(-1)?.type === "message.assistant" ||
        there.some((e) => e.seq > (msg?.seq ?? 0) && e.type === "message.assistant"),
    ).toBe(true);
    // The next turn where it left carries one line: leave it out.
    const next = await s.core.topics.send(ME, {
      text: "torniamo al preventivo",
      topicId: a.sessionId,
    });
    await next.done;
    expect(textOf(seen.at(-1) as CompletionRequest)).toContain(
      "moved the exchange about «il NAS fa rumore»",
    );
    // A restart rebuilds the redirection from the log.
    const { TaskTracker } = await import("../src/orchestration.js");
    const fresh = new TaskTracker(s.core.store);
    await fresh.rebuild();
    expect(fresh.get(task.id)?.from?.sessionId).toBe(b.sessionId);
    // Moving back undoes it.
    const back = await s.api<{ sessionId: string }>(
      "POST",
      `/api/sessions/${b.sessionId}/messages/${msg?.seq}/move`,
      { to: a.sessionId },
    );
    expect(back.body.sessionId).toBe(a.sessionId);
    await waitIdle(s);
  });

  it("«from here on» moves the later messages too, into a new topic", async () => {
    const { s } = await withGod(godScript());
    const a = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await a.done;
    const one = await s.core.topics.send(ME, {
      text: "cena sabato per otto",
      topicId: a.sessionId,
    });
    await one.done;
    const two = await s.core.topics.send(ME, { text: "e il vino rosso", topicId: a.sessionId });
    await two.done;
    const es = await events(s, a.sessionId);
    const seq = es.find(
      (e) => e.type === "message.user" && e.payload?.text === "cena sabato per otto",
    )?.seq;
    const r = await s.core.topics.move(ME, a.sessionId, seq ?? -1, {
      to: "new",
      title: "Cena di sabato",
      fromHere: true,
    });
    await r.done;
    expect(r.routed).toMatchObject({ isNew: true, title: "Cena di sabato" });
    expect(r.throughSeq).toBeGreaterThan(seq ?? 0);
    const there = await events(s, r.sessionId);
    expect(there.find((e) => e.type === "message.user")?.payload).toMatchObject({
      text: "cena sabato per otto\n\ne il vino rosso",
    });
  });
});

describe("God's topics: migration, archive, summaries, labels", () => {
  it("migrates God's conversations once: recent ones active, old ones and the work conversation archived", async () => {
    const { s, god } = await withGod(godScript());
    const db = s.core.db;
    const day = 86_400_000;
    const at = (ago: number) => new Date(Date.now() - ago).toISOString();
    for (const [id, title, last, archived] of [
      ["sess_recent", "Recente", at(day), false],
      ["sess_old", "Vecchia", at(10 * day), false],
      ["sess_hand", "Archiviata a mano", at(day), true],
      ["sess_work", "Lavoro", at(60_000), false],
    ] as const)
      await db.query(
        "INSERT INTO rg_sessions (id, owner_id, agent_id, title, last_at, archived) VALUES ($1, $2, $3, $4, $5, $6)",
        [id, ME, god, title, last, archived],
      );
    await db.query("INSERT INTO rg_settings (owner_id, key, value) VALUES ($1, $2, $3)", [
      ME,
      `work_session:${god}`,
      JSON.stringify("sess_work"),
    ]);
    const list = await s.api<{ topics: { id: string }[]; archived: number }>(
      "GET",
      "/api/god/topics",
    );
    expect(list.body.topics.map((t) => t.id)).toEqual(["sess_recent"]);
    expect(list.body.archived).toBe(3);
    const work = await events(s, "sess_work");
    expect(work.map((e) => e.type)).toEqual(["topic.opened", "topic.archived"]);
    expect(work[0]?.payload).toMatchObject({ title: "Before topics", by: "migration" });
    expect((await events(s, "sess_old")).at(-1)?.payload).toEqual({ by: "idle" });
    expect((await events(s, "sess_hand")).map((e) => e.type)).toEqual(["topic.opened"]);
    // The old apps' work conversation: the latest active topic.
    const w = await s.api<{ sessionId: string }>("POST", `/api/agents/${god}/work-session`);
    expect(w.body.sessionId).toBe("sess_recent");
    // Once only.
    s.core.topics["ready"].clear();
    await s.core.topics.prepare(ME);
    expect((await events(s, "sess_work")).length).toBe(2);
  });

  it("archives topics idle for three days (never pinned or with open tasks), and a message brings one back", async () => {
    const { s, god } = await withGod(godScript());
    const mk = async (text: string) => {
      const r = await s.core.topics.send(ME, { text, newTopic: true });
      await r.done;
      return r.sessionId;
    };
    const idle = await mk("Viaggio");
    const pinned = await mk("Fissato");
    const busy = await mk("Con un compito");
    await s.api("PATCH", `/api/sessions/${pinned}`, { pinned: true });
    const godRec = s.core.registry.get(god);
    if (!godRec) throw new Error("no God");
    await s.core.tasks.open(godRec, "sess_x", "A task", {
      agentId: god,
      sessionId: busy,
      name: "God",
    });
    const later = Date.now() + 3 * 86_400_000 + 60_000;
    const r = await s.core.topics.tick(ME, later);
    expect(r.archived).toEqual([idle]);
    expect((await events(s, idle)).findLast((e) => e.type === "topic.archived")?.payload).toEqual({
      by: "idle",
    });
    // The person writes there again: it comes back.
    const back = await s.core.topics.send(ME, { text: "e allora?", topicId: idle });
    await back.done;
    const list = await s.core.topics.list(ME);
    expect(list.topics.map((t) => t.id)).toContain(idle);
    expect((await events(s, idle)).findLast((e) => e.type === "topic.restored")?.payload).toEqual({
      by: "message",
    });
  });

  it("writes a one-line summary of a quiet topic, and a better title in its first exchanges", async () => {
    const { s } = await withGod(godScript());
    const r = await s.core.topics.send(ME, { text: "preventivo rossi da fare", newTopic: true });
    await r.done;
    const out = await s.core.topics.tick(ME, Date.now() + 10 * 60_000);
    expect(out.summarized).toEqual([r.sessionId]);
    const list = await s.core.topics.list(ME);
    expect(list.topics[0]).toMatchObject({
      summary: "Il preventivo per Rossi, quasi pronto.",
      title: "Preventivo Rossi",
    });
    // Nothing new since: no second summary.
    expect((await s.core.topics.tick(ME, Date.now() + 20 * 60_000)).summarized).toEqual([]);
  });

  it("labels requests with their topic, up the chain of tasks; counts them in «Oggi»; unread answers", async () => {
    const { s, god } = await withGod(godScript());
    const r = await s.core.topics.send(ME, { text: "Preventivo Rossi", newTopic: true });
    await r.done;
    const godRec = s.core.registry.get(god);
    if (!godRec) throw new Error("no God");
    await s.core.tasks.open(godRec, "sess_orch", "Build it", {
      agentId: god,
      sessionId: r.sessionId,
      name: "God",
    });
    await s.core.tasks.open(godRec, "sess_sub", "A part", {
      agentId: "orch",
      sessionId: "sess_orch",
      name: "Orch",
    });
    expect(s.core.topics.topicOf("sess_sub")).toEqual({
      id: r.sessionId,
      title: "Preventivo Rossi",
    });
    expect(s.core.topics.topicOf("sess_alone")).toBeUndefined();
    const asked = s.core.questions.ask(ME, {
      requestId: "q1",
      sessionId: "sess_sub",
      agentId: "orch",
      agentName: "Orch",
      projectId: null,
      questions: [{ question: "Which colour?", options: [{ label: "Red" }, { label: "Blue" }] }],
      createdAt: new Date().toISOString(),
    } as never);
    expect(s.core.questions.list(ME)[0]?.topic).toEqual({
      id: r.sessionId,
      title: "Preventivo Rossi",
    });
    const list = await s.core.topics.list(ME);
    expect(list.topics[0]).toMatchObject({ requests: 1, tasks: 1, state: "waiting", unread: 1 });
    s.core.questions.answer(ME, "q1", [["Red"]]);
    await asked;
    expect((await s.api("POST", `/api/god/topics/${r.sessionId}/read`)).status).toBe(200);
    expect((await s.core.topics.list(ME)).topics[0]).toMatchObject({
      unread: 0,
      requests: 0,
      state: "working",
    });
  });

  it("an assistant's ask_god opens a topic «from» it", async () => {
    const { s } = await withGod(godScript());
    const sid = await s.core.topicFor(
      s.core.registry.list({ ownerId: ME }).find((a) => a.kind === "god") as never,
      "Che impegni ho domani?",
      "assistant",
      "Ada",
    );
    const list = await s.core.topics.list(ME);
    expect(list.topics.find((t) => t.id === sid)).toMatchObject({ from: "Ada" });
    expect((await events(s, sid)).find((e) => e.type === "topic.opened")?.payload).toMatchObject({
      by: "assistant",
      from: "Ada",
    });
  });
});

describe("WarmRouter", () => {
  it("answers with the engine started ahead and starts the next one at once", async () => {
    const started: { text?: string; closed: boolean }[] = [];
    const engine = {
      prewarm: () => {
        const p = { closed: false } as { text?: string; closed: boolean };
        started.push(p);
        return {
          ask: async (text: string) => {
            p.text = text;
            return `{"topic":"new","confidence":1}`;
          },
          close: () => {
            p.closed = true;
          },
        };
      },
    };
    const w = new WarmRouter(engine);
    const call = {
      system: "sys",
      text: "hello",
      model: { provider: "claude-subscription", model: "haiku" },
    };
    w.warm(call);
    expect(started).toHaveLength(1);
    expect(await w.ask(call)).toContain("new");
    // The one warmed answered, then closed; the next is ready.
    expect(started[0]).toEqual({ text: "hello", closed: true });
    expect(started).toHaveLength(2);
    expect(started[1]?.closed).toBe(false);
    w.close();
    expect(started[1]?.closed).toBe(true);
  });
});
