// The one-time split of God's old work conversation (3.12.2): grouped by work by the light model,
// quiet moves (no turn of God), the active/archived rule, idempotence, resuming, bad JSON, and the
// retitling of migrated topics. PGlite + FakeProvider: no real model.
import { rebuildHistory } from "@redgiant/agent";
import type { Event } from "@redgiant/protocol";
import type { CompletionRequest, FakeTurn } from "@redgiant/providers";
import { afterEach, describe, expect, it } from "vitest";
import { SPLIT_SYSTEM, SUMMARY_SYSTEM } from "../src/topics.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});
const ME = "me";
const DAY = 86_400_000;

interface Calls {
  split: string[];
  summary: string[];
  other: string[];
}

/** The model: split answers come from `splits` (in order), summaries retitle, anything else is God. */
function script(calls: Calls, splits: string[]) {
  return (req: CompletionRequest): FakeTurn => {
    const text = (req.messages.at(-1)?.parts ?? [])
      .flatMap((p) => (p.type === "text" ? [p.text] : []))
      .join("\n");
    if (req.system === SPLIT_SYSTEM) {
      calls.split.push(text);
      return { text: splits[calls.split.length - 1] ?? splits.at(-1) ?? "{}" };
    }
    if (req.system === SUMMARY_SYSTEM) {
      calls.summary.push(text);
      return { text: '{"summary":"A summary.","title":"A real title"}' };
    }
    calls.other.push(text);
    return { text: "God answers" };
  };
}

async function start(splits: string[]) {
  const calls: Calls = { split: [], summary: [], other: [] };
  const srv = await startServer(script(calls, splits));
  s = srv;
  const god = (
    await srv.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    })
  ).body.id;
  return { s: srv, god, calls };
}

const stamp = (n: number) => new Date(Date.now() - n).toISOString();

/** A legacy conversation of God with exchanges `[text, answer, age in ms]`, then the migration. */
async function legacy(
  srv: Server,
  god: string,
  id: string,
  title: string,
  rows: [string, string, number][],
  work = false,
) {
  const db = srv.core.db;
  await db.query(
    "INSERT INTO rg_sessions (id, owner_id, agent_id, title, last_at) VALUES ($1, $2, $3, $4, $5)",
    [id, ME, god, title, stamp(Math.min(...rows.map((r) => r[2])))],
  );
  if (work)
    await db.query("INSERT INTO rg_settings (owner_id, key, value) VALUES ($1, $2, $3)", [
      ME,
      `work_session:${god}`,
      JSON.stringify(id),
    ]);
  for (const [text, answer, age] of rows) {
    const base = { ownerId: ME, projectId: null, agentId: god, sessionId: id };
    const ts = stamp(age);
    await srv.core.store.append({
      ...base,
      ts,
      body: { type: "message.user", payload: { text } },
    });
    await srv.core.store.append({
      ...base,
      ts,
      body: {
        type: "message.assistant",
        payload: {
          parts: [{ type: "text", text: answer }],
          stopReason: "end_turn",
          provider: "fake",
          model: "fake",
          metrics: {
            startedAt: stamp(age),
            inputTokens: 1,
            cachedReadTokens: 0,
            cacheWriteTokens: 0,
            outputTokens: 1,
            contextUsed: 1,
            contextWindow: 1000,
            source: "server",
          },
          costUsd: 0,
        },
      },
    });
  }
}

const events = (srv: Server, sessionId: string) => srv.core.store.list({ sessionId });
const userTexts = (es: Event[]) =>
  rebuildHistory(es).flatMap((h) =>
    h.message.role === "user"
      ? [h.message.parts.flatMap((p) => (p.type === "text" ? [p.text] : [])).join("")]
      : [],
  );

/** 9 exchanges of three works plus small talk and a lone one; the last two works are recent. */
const ROWS: [string, string, number][] = [
  ["plugin GAIA ITAS: la pagina impostazioni", "A0", 10 * DAY],
  ["plugin GAIA ITAS: il salvataggio", "A1", 10 * DAY - 1000],
  ["plugin GAIA ITAS: i test", "A2", 9 * DAY],
  ["vaultwarden: il backup", "A3", 8 * DAY],
  ["vaultwarden: l'aggiornamento", "A4", 8 * DAY - 1000],
  ["che ore sono?", "A5", 7 * DAY],
  ["prova di rilascio 3.12", "A6", 2 * DAY],
  ["prova di rilascio: la CI", "A7", DAY],
  ["una cosa a parte", "A8", 6 * DAY],
];
const GROUPS = JSON.stringify({
  groups: [
    { title: "GAIA ITAS plugin", exchanges: [0, 1, 2], summary: "Il plugin WordPress." },
    { title: "Vaultwarden", exchanges: [3, 4], summary: "Backup e aggiornamento." },
    { title: "Prove di rilascio", exchanges: [6, 7], summary: "Le prove della 3.12." },
    { title: "Lo scarto", exchanges: [8], summary: "Uno solo." },
  ],
});

async function seed(srv: Server, god: string, rows = ROWS) {
  await legacy(srv, god, "sess_work", "Lavoro", rows, true);
  await srv.core.topics.prepare(ME);
}

describe("the split of «Before topics»", () => {
  it("groups the exchanges by work, moves them quietly, and archives the idle ones", async () => {
    const { s, god, calls } = await start([GROUPS]);
    await seed(s, god);
    expect(await s.core.topics.splitBefore(ME)).toBe(3);
    expect(calls.split).toHaveLength(1);
    expect(calls.other).toEqual([]); // God never answered again
    const list = await s.api<{ topics: { id: string; title: string; summary: string }[] }>(
      "GET",
      "/api/god/topics",
    );
    // Only the recent work is active; the old ones are archived (idle); the lone exchange stayed.
    expect(list.body.topics.map((t) => t.title)).toEqual(["Prove di rilascio"]);
    const arch = await s.api<{ topics: { id: string; title: string }[] }>(
      "GET",
      "/api/god/topics?archived=true",
    );
    const titles = arch.body.topics.map((t) => t.title).sort();
    expect(titles).toEqual(["Before topics", "GAIA ITAS plugin", "Vaultwarden"]);
    const gaia = arch.body.topics.find((t) => t.title === "GAIA ITAS plugin");
    const es = await events(s, gaia?.id ?? "");
    expect(es.find((e) => e.type === "topic.opened")?.payload).toMatchObject({
      title: "GAIA ITAS plugin",
      by: "migration",
    });
    expect(es.at(-1)?.type).toBe("topic.archived");
    expect(es.findLast((e) => e.type === "topic.summarized")?.payload).toMatchObject({
      summary: "Il plugin WordPress.",
    });
    // History rebuilt from the log: the moved exchanges, in order, with God's old answers.
    expect(userTexts(es)).toEqual(ROWS.slice(0, 3).map((r) => r[0]));
    const h = rebuildHistory(es).map((x) => x.message.role);
    expect(h).toEqual(["user", "assistant", "user", "assistant", "user", "assistant"]);
    expect(es.find((e) => e.type === "message.user")?.payload).toMatchObject({
      movedFrom: { sessionId: "sess_work" },
    });
    // The source keeps everything and says where each exchange went.
    const src = await events(s, "sess_work");
    const moved = src.filter((e) => e.type === "message.moved");
    expect(moved).toHaveLength(7);
    expect(moved[0]?.payload).toMatchObject({ by: "migration" });
    expect(src.filter((e) => e.type === "message.user")).toHaveLength(9);
    expect(userTexts(src)).toHaveLength(9);
    // The title's list view sees the summary and the real dates.
    const rel = list.body.topics[0];
    expect(rel?.summary).toBe("Le prove della 3.12.");
    // Once only.
    expect(await s.core.topics.splitBefore(ME)).toBe(0);
    expect(calls.split).toHaveLength(1);
  });

  it("is idempotent across restarts and when asked again", async () => {
    const { s, god, calls } = await start([GROUPS]);
    await seed(s, god);
    await s.core.topics.modernize(ME);
    const n = (await s.core.store.list({})).length;
    s.core.topics["ready"].clear();
    await s.core.topics.modernize(ME);
    expect((await s.core.store.list({})).length).toBe(n);
    expect(calls.split).toHaveLength(1);
  });

  it("resumes where it stopped: moved exchanges are not moved twice", async () => {
    const second = JSON.stringify({
      groups: [{ title: "GAIA ITAS plugin", exchanges: [1, 2], summary: "Il plugin." }],
    });
    const { s, god, calls } = await start([GROUPS, second]);
    await seed(s, god);
    const real = s.core.topics["moveQuiet"].bind(s.core.topics);
    let n = 0;
    s.core.topics["moveQuiet"] = (async (...a: Parameters<typeof real>) => {
      if (++n === 3) throw new Error("power cut");
      return real(...a);
    }) as typeof real;
    await expect(s.core.topics.splitBefore(ME)).rejects.toThrow("power cut");
    expect(await s.core.db.query("SELECT 1 FROM rg_settings WHERE key = 'topics_split'")).toEqual(
      [],
    );
    s.core.topics["moveQuiet"] = real;
    await s.core.topics.splitBefore(ME);
    const src = await events(s, "sess_work");
    const seqs = src.flatMap((e) =>
      e.type === "message.moved" && e.payload ? [e.payload.seq] : [],
    );
    expect(new Set(seqs).size).toBe(seqs.length); // none twice
    expect(calls.split).toHaveLength(2);
    // The second ask only showed what was left (6 lines: 2 already moved).
    expect(calls.split[1]?.match(/^\d+ \|/gmu)).toHaveLength(7);
  });

  it("tolerates bad JSON: retries once, then leaves the exchanges where they are", async () => {
    const { s, god, calls } = await start(["not json at all", GROUPS]);
    await seed(s, god);
    expect(await s.core.topics.splitBefore(ME)).toBe(3);
    expect(calls.split).toHaveLength(2); // the retry got the good answer
  });

  it("gives up on a batch after two bad answers and keeps its exchanges", async () => {
    const bad = await start(["nope", "still {not json"]);
    await seed(bad.s, bad.god);
    expect(await bad.s.core.topics.splitBefore(ME)).toBe(0);
    expect(bad.calls.split).toHaveLength(2);
    expect((await events(bad.s, "sess_work")).some((e) => e.type === "message.moved")).toBe(false);
    expect(
      await bad.s.core.db.query("SELECT 1 FROM rg_settings WHERE key = 'topics_split'"),
    ).toHaveLength(1);
  });

  it("ignores numbers it was not shown and exchanges already taken by a group", async () => {
    const odd = JSON.stringify({
      groups: [
        { title: "Uno", exchanges: [0, 1, 99], summary: "x" },
        { title: "Due", exchanges: [1, 2, 3], summary: "y" },
      ],
    });
    const { s, god } = await start([odd]);
    await seed(s, god);
    expect(await s.core.topics.splitBefore(ME)).toBe(2);
    const src = await events(s, "sess_work");
    expect(src.filter((e) => e.type === "message.moved")).toHaveLength(4);
  });

  it("an open task of a moved exchange keeps a topic active", async () => {
    // The last exchange (where a task opened now falls) belongs to the old plugin work.
    const rows: [string, string, number][] = [
      ...ROWS.slice(0, 8),
      ["plugin GAIA ITAS: ancora", "A8", 10 * DAY],
    ];
    const groups = JSON.stringify({
      groups: [
        { title: "GAIA ITAS plugin", exchanges: [0, 1, 2, 8], summary: "x" },
        { title: "Vaultwarden", exchanges: [3, 4], summary: "y" },
      ],
    });
    const { s, god } = await start([groups]);
    await seed(s, god, rows);
    const godRec = s.core.registry.get(god);
    if (!godRec) throw new Error("no God");
    await s.core.tasks.open(godRec, "sess_x", "Old task", {
      agentId: god,
      sessionId: "sess_work",
      name: "God",
    });
    await s.core.topics.splitBefore(ME);
    const list = await s.api<{ topics: { title: string }[] }>("GET", "/api/god/topics");
    expect(list.body.topics.map((t) => t.title)).toEqual(["GAIA ITAS plugin"]);
  });
});

describe("the retitling of migrated topics", () => {
  it("renames the ones still named by their first line, archived too, once", async () => {
    const { s, god, calls } = await start(["{}"]);
    await legacy(s, god, "sess_a", "Come configuro nginx", [
      ["Come configuro nginx\nper il sito", "ok", DAY],
    ]);
    await legacy(s, god, "sess_b", "Vecchia cosa", [["Vecchia cosa", "ok", 20 * DAY]]);
    await legacy(s, god, "sess_c", "Titolo scelto da me", [["Altro testo", "ok", DAY]]);
    await s.core.topics.prepare(ME);
    expect(await s.core.topics.retitleMigrated(ME)).toBe(2);
    expect(calls.summary).toHaveLength(2);
    const rows = await s.core.db.query<{ id: string; title: string; archived: boolean }>(
      "SELECT id, title, archived FROM rg_sessions WHERE owner_id = $1 ORDER BY id",
      [ME],
    );
    expect(rows.map((r) => r.title)).toEqual([
      "A real title",
      "A real title",
      "Titolo scelto da me",
    ]);
    expect(rows[1]?.archived).toBe(true);
    expect(await s.core.topics.retitleMigrated(ME)).toBe(0);
    expect(calls.summary).toHaveLength(2);
  });
});
