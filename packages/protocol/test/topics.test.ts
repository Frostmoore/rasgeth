// God's conversations by topic (3.12): the router's rules, the fallback, the router's answer,
// titles, states and the automatic archive, as tables.
import { describe, expect, it } from "vitest";
import {
  EventBody,
  fallbackRoute,
  isShortReply,
  parseRouterAnswer,
  type RuleInput,
  type RuleTopic,
  routeByRules,
  shouldArchive,
  topicState,
  topicTitle,
} from "../src/index.js";

const NOW = Date.parse("2026-11-22T12:00:00Z");
const MIN = 60_000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;

const t = (id: string, o: Partial<RuleTopic> = {}): RuleTopic => ({
  id,
  lastAt: NOW - HOUR,
  ...o,
});

describe("isShortReply", () => {
  const TABLE: [string, boolean][] = [
    ["sì", true],
    ["Sì.", true],
    ["ok", true],
    ["fallo", true],
    ["la seconda", true],
    ["go ahead", true],
    ["va bene, procedi pure", true],
    ["perché?", false],
    ["what about the logs?", false],
    ["Controlla i log del server di stanotte e dimmi cosa è successo", false],
    ["", false],
    ["una riga\naltra", false],
  ];
  it.each(TABLE)("%j → %s", (text, short) => expect(isShortReply(text)).toBe(short));
});

describe("routeByRules", () => {
  const active = [
    t("a", { lastAt: NOW - 5 * MIN, godAt: NOW - 5 * MIN, personAt: NOW - 6 * MIN }),
    t("b", { lastAt: NOW - 30 * MIN, godAt: NOW - 30 * MIN, projectId: "p1" }),
  ];
  const base: RuleInput = { text: "Prepara il preventivo per il cliente nuovo", now: NOW, active };
  const TABLE: [string, Partial<RuleInput>, ReturnType<typeof routeByRules>][] = [
    ["written inside a topic", { here: "b" }, { to: "b", via: "here", reason: "written_here" }],
    [
      "here wins over everything",
      { here: "b", newTopic: true, chosen: "a", replyTo: "a" },
      { to: "b", via: "here", reason: "written_here" },
    ],
    ["new topic", { newTopic: true }, { to: "new", via: "person", reason: "new_topic" }],
    ["chosen by hand", { chosen: "b" }, { to: "b", via: "person", reason: "chosen" }],
    ["a reply", { replyTo: "b" }, { to: "b", via: "reply", reason: "reply" }],
    [
      "a short reply goes where God spoke last",
      { text: "sì" },
      { to: "a", via: "rule", reason: "short_reply" },
    ],
    [
      "God's own message about a project",
      { projectId: "p1" },
      { to: "b", via: "rule", reason: "project" },
    ],
    ["a project without a topic: undecided", { projectId: "p9" }, undefined],
    ["two topics, a long message: undecided", {}, undefined],
    [
      "one topic moved a few minutes ago",
      { active: [t("a", { lastAt: NOW - 3 * MIN })] },
      { to: "a", via: "rule", reason: "only_recent" },
    ],
    ["one topic, quiet for an hour: undecided", { active: [t("a")] }, undefined],
    ["no topics: undecided", { active: [] }, undefined],
    ["a short reply with no answer of God anywhere", { text: "ok", active: [t("a")] }, undefined],
  ];
  it.each(TABLE)("%s", (_name, over, want) =>
    expect(routeByRules({ ...base, ...over })).toEqual(want),
  );
});

describe("fallbackRoute", () => {
  const TABLE: [string, RuleTopic[], ReturnType<typeof fallbackRoute>][] = [
    [
      "the topic the person wrote in last, within two hours",
      [t("a", { personAt: NOW - 90 * MIN }), t("b", { personAt: NOW - 10 * MIN })],
      { to: "b", reason: "recent_person" },
    ],
    [
      "older than two hours: a new topic",
      [t("a", { personAt: NOW - 3 * HOUR })],
      { to: "new", reason: "nothing_recent" },
    ],
    ["no topics", [], { to: "new", reason: "nothing_recent" }],
  ];
  it.each(TABLE)("%s", (_n, active, want) =>
    expect(fallbackRoute({ active, now: NOW })).toEqual(want),
  );
});

describe("parseRouterAnswer", () => {
  const active = ["sess_a", "sess_b"];
  const TABLE: [string, string, ReturnType<typeof parseRouterAnswer>][] = [
    ["a topic", '{"topic":"sess_a","confidence":0.9}', { to: "sess_a", confidence: 0.9 }],
    [
      "in a code fence, new with a title",
      '```json\n{"topic":"new","title":"Preventivo Rossi","confidence":0.8}\n```',
      { to: "new", title: "Preventivo Rossi", confidence: 0.8 },
    ],
    ["an unknown topic", '{"topic":"sess_z","confidence":0.9}', undefined],
    ["not JSON", "I think it belongs to the first topic", undefined],
    ["broken JSON", '{"topic":"sess_a",', undefined],
    ["no confidence", '{"topic":"sess_a"}', undefined],
    ["confidence out of range", '{"topic":"sess_a","confidence":3}', undefined],
  ];
  it.each(TABLE)("%s", (_n, text, want) => expect(parseRouterAnswer(text, active)).toEqual(want));
});

describe("topicTitle", () => {
  const TABLE: [string, string][] = [
    ["Preventivo Rossi", "Preventivo Rossi"],
    ["«Preventivo Rossi»\nsecond line", "Preventivo Rossi"],
    ["  \n  Spaces   between  words ", "Spaces between words"],
    [
      "A very long title that keeps going well beyond the sixty characters allowed for one",
      "A very long title that keeps going well beyond the sixty…",
    ],
  ];
  it.each(TABLE)("%j", (text, want) => {
    expect(topicTitle(text)).toBe(want);
    expect(topicTitle(text).length).toBeLessThanOrEqual(61);
  });
});

describe("topicState", () => {
  const TABLE: [Parameters<typeof topicState>[0], string][] = [
    [{ running: false, queued: false, tasks: 0, requests: 0 }, "ready"],
    [{ running: true, queued: false, tasks: 0, requests: 0 }, "working"],
    [{ running: false, queued: true, tasks: 0, requests: 0 }, "working"],
    [{ running: false, queued: false, tasks: 2, requests: 0 }, "working"],
    [{ running: true, queued: false, tasks: 1, requests: 1 }, "waiting"],
  ];
  it.each(TABLE)("%j → %s", (s, want) => expect(topicState(s)).toBe(want));
});

describe("shouldArchive", () => {
  const base = {
    lastAt: NOW - 3 * DAY,
    now: NOW,
    pinned: false,
    archived: false,
    tasks: 0,
    requests: 0,
    running: false,
  };
  const TABLE: [string, Partial<typeof base>, boolean][] = [
    ["idle three days", {}, true],
    ["idle two days and 23 hours", { lastAt: NOW - 3 * DAY + HOUR }, false],
    ["pinned", { pinned: true }, false],
    ["open tasks", { tasks: 1 }, false],
    ["a request waits", { requests: 1 }, false],
    ["working now", { running: true }, false],
    ["already archived", { archived: true }, false],
  ];
  it.each(TABLE)("%s → %s", (_n, over, want) =>
    expect(shouldArchive({ ...base, ...over })).toBe(want),
  );
});

describe("topic events", () => {
  it("parse", () => {
    for (const body of [
      { type: "topic.opened", payload: { title: "Preventivo", by: "router", origin: "today" } },
      {
        type: "topic.routed",
        payload: { via: "router", reason: "router", confidence: 0.4, uncertain: true },
      },
      { type: "topic.summarized", payload: { summary: "Il preventivo per Rossi.", throughSeq: 4 } },
      { type: "topic.archived", payload: { by: "idle" } },
      { type: "topic.restored", payload: { by: "report" } },
      {
        type: "message.moved",
        payload: { seq: 3, throughSeq: 5, toSessionId: "s2", by: "person" },
      },
      { type: "task.redirected", payload: { taskId: "t1", toSessionId: "s2" } },
      { type: "message.user", payload: { text: "x", movedFrom: { sessionId: "s1", seq: 3 } } },
    ])
      expect(EventBody.safeParse(body).success, body.type).toBe(true);
    expect(EventBody.safeParse({ type: "topic.archived", payload: { by: "tired" } }).success).toBe(
      false,
    );
  });
});
