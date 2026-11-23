// God's friendly nudges (3.12.1): at most one a day (or less), never at night, tied to real facts
// (a topic waiting, one standing still, one left for days), else a morning greeting; sentences
// from a fixed list filled with real data, no model; delivered as a notification, never written
// into a topic. The clock is the service's own (`now`, `tick(at)`), never real time.
import {
  DEFAULT_NUDGE_SETTINGS,
  type GodNudge,
  NUDGE_WORDS,
  nudgeDue,
  pickNudge,
  type TopicView,
} from "@redgiant/protocol";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { NudgeService, nudgeFacts } from "../src/nudges.js";
import { migratePlatform } from "../src/platform.js";
import { type Server, startServer } from "./helpers.js";
import { memoryDb } from "./pglite.js";

const H = 3_600_000;
const DAY = 24 * H;
/** 2026-11-23 00:00 UTC; the tests' clock is UTC (offset 0). */
const T0 = Date.UTC(2026, 10, 23);
const at = (day: number, hour: number) => T0 + day * DAY + hour * H;

const topic = (id: string, o: Partial<TopicView> = {}): TopicView => ({
  id,
  title: id,
  summary: null,
  state: "ready",
  lastAt: new Date(T0).toISOString(),
  personAt: null,
  createdAt: new Date(T0 - 10 * DAY).toISOString(),
  pinned: false,
  archived: false,
  unread: 0,
  requests: 0,
  tasks: 0,
  projectId: null,
  from: null,
  ...o,
});

describe("when a nudge may go (pure)", () => {
  const s = DEFAULT_NUDGE_SETTINGS;
  it("only by day, at most once a day, or less as chosen; never when switched off", () => {
    const table: [number, number | null, typeof s, boolean][] = [
      [at(0, 8), null, s, false],
      [at(0, 9), null, s, true],
      [at(0, 19), null, s, true],
      [at(0, 20), null, s, false],
      [at(0, 23), null, s, false],
      [at(0, 3), null, s, false],
      [at(0, 15), at(0, 9), s, false],
      [at(1, 9), at(0, 19), s, true],
      [at(1, 9), at(0, 9), { on: true, every: "two_days" }, false],
      [at(2, 9), at(0, 9), { on: true, every: "two_days" }, true],
      [at(6, 9), at(0, 9), { on: true, every: "week" }, false],
      [at(7, 9), at(0, 9), { on: true, every: "week" }, true],
      [at(0, 10), null, { on: false, every: "day" }, false],
    ];
    for (const [now, last, set, due] of table)
      expect(nudgeDue(now, 0, last, set), `${new Date(now).toISOString()} ${set.every}`).toBe(due);
    // The person's clock, not the server's: 08:30 UTC is 09:30 in Rome.
    expect(nudgeDue(at(0, 8) + 30 * 60_000, 60, null, s)).toBe(true);
  });

  it("speaks of what really waits, first; else a greeting; from the fixed words", () => {
    const facts = {
      waiting: [{ id: "t1", title: "Preventivo Rossi" }],
      stalled: [{ id: "t2", title: "Sito", days: 3 }],
      left: [{ id: "t3", title: "Viaggio", days: 5 }],
    };
    const w = pickNudge(facts, "it", 0);
    expect(w).toEqual({
      kind: "waiting",
      topicId: "t1",
      text: "Hai del lavoro in sospeso, sai? «Preventivo Rossi» aspetta una tua risposta.",
    });
    expect(pickNudge({ ...facts, waiting: [] }, "it", 0)).toMatchObject({
      kind: "stalled",
      topicId: "t2",
      text: "«Sito» è fermo da 3 giorni. Diamo un'occhiata insieme?",
    });
    expect(pickNudge({ waiting: [], stalled: [], left: facts.left }, "en", 1)).toMatchObject({
      kind: "left",
      text: "«Viaggio» has been there for 5 days. Carry on, or put it in the archive?",
    });
    const g = pickNudge({ waiting: [], stalled: [], left: [] }, "it", 0);
    expect(g).toEqual({
      kind: "greeting",
      topicId: null,
      text: "Ciao! A cosa lavoriamo oggi?",
    });
    // Day by day the words change, always from the list.
    const texts = new Set([0, 1, 2].map((d) => pickNudge(facts, "it", d).text));
    expect(texts.size).toBe(3);
    for (const lang of ["it", "en"] as const)
      for (const list of Object.values(NUDGE_WORDS[lang])) expect(list.length).toBeGreaterThan(1);
  });

  it("reads the facts from the topics: waiting, standing still, left for days", () => {
    const now = at(0, 10);
    const f = nudgeFacts(
      [
        topic("w", { state: "waiting" }),
        topic("s", { state: "working", tasks: 1, lastAt: new Date(now - 3 * DAY).toISOString() }),
        topic("busy", { state: "working", tasks: 1, lastAt: new Date(now - H).toISOString() }),
        topic("l", { lastAt: new Date(now - 4 * DAY).toISOString() }),
        topic("pinned", { pinned: true, lastAt: new Date(now - 9 * DAY).toISOString() }),
        topic("fresh", { lastAt: new Date(now - DAY).toISOString() }),
      ],
      now,
    );
    expect(f.waiting.map((x) => x.id)).toEqual(["w"]);
    expect(f.stalled).toEqual([{ id: "s", title: "s", days: 3 }]);
    expect(f.left).toEqual([{ id: "l", title: "l", days: 4 }]);
  });
});

describe("the nudge service (fake clock)", () => {
  let list: TopicView[];
  let sent: GodNudge[];
  let svc: NudgeService;
  beforeEach(async () => {
    const { db } = await memoryDb();
    await migratePlatform(db);
    list = [];
    sent = [];
    svc = new NudgeService({
      db,
      topics: async () => list,
      language: () => "it",
      godName: () => "God",
      deliver: (_o, n) => sent.push(n),
      now: () => at(0, 0),
      offsetMin: () => 0,
    });
  });

  it("sends one a day at most, by day, about what waits; a greeting only in the morning", async () => {
    list = [topic("t1", { title: "Preventivo Rossi", state: "waiting" })];
    expect(await svc.tick("me", at(0, 7))).toBeNull();
    const first = await svc.tick("me", at(0, 9));
    expect(first).toMatchObject({ kind: "waiting", topicId: "t1" });
    expect(first?.text).toContain("Preventivo Rossi");
    expect(await svc.tick("me", at(0, 15))).toBeNull();
    expect(sent).toHaveLength(1);
    // The next day nothing waits: a morning greeting, never in the afternoon.
    list = [];
    expect(await svc.tick("me", at(1, 15))).toBeNull();
    expect(await svc.tick("me", at(2, 10))).toMatchObject({ kind: "greeting", topicId: null });
    expect(sent).toHaveLength(2);
  });

  it("follows the person's choice: off, or once a week", async () => {
    await svc.setSettings("me", { on: false, every: "day" });
    expect(await svc.tick("me", at(0, 10))).toBeNull();
    await svc.setSettings("me", { on: true, every: "week" });
    expect(await svc.settings("me")).toEqual({ on: true, every: "week" });
    expect(await svc.tick("me", at(0, 10))).not.toBeNull();
    expect(await svc.tick("me", at(3, 10))).toBeNull();
    expect(await svc.tick("me", at(7, 10))).not.toBeNull();
  });
});

describe("God's nudge in the server", () => {
  let s: Server | undefined;
  afterEach(async () => {
    await s?.close();
    s = undefined;
  });

  it("keeps the settings, reaches the open pages, and writes nothing into any topic", async () => {
    s = await startServer(() => ({ text: "ok" }));
    await s.api("POST", "/api/agents", { kind: "god", parentId: null, name: "God" });
    expect((await s.api("GET", "/api/god/nudges")).body).toEqual({ on: true, every: "day" });
    expect((await s.api("PUT", "/api/god/nudges", { on: true, every: "sometimes" })).status).toBe(
      400,
    );
    expect((await s.api("PUT", "/api/god/nudges", { on: true, every: "two_days" })).status).toBe(
      200,
    );
    expect((await s.api("GET", "/api/god/nudges")).body).toEqual({ on: true, every: "two_days" });
    const heard: GodNudge[] = [];
    s.core.onNudge((_o, n) => heard.push(n));
    const before = (await s.core.store.list({})).length;
    // A morning, by the person's clock: whatever the server's zone, 10:00 there.
    const now =
      Date.UTC(2026, 10, 23, 10) + new Date(Date.UTC(2026, 10, 23)).getTimezoneOffset() * 60_000;
    const n = await s.core.nudges.tick("me", now);
    expect(n?.kind).toBe("greeting");
    expect(heard).toEqual([n]);
    // A notification only: no event, no topic made.
    expect((await s.core.store.list({})).length).toBe(before);
    expect((await s.core.topics.list("me")).topics).toHaveLength(0);
  });
});
