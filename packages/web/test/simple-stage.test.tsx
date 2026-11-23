// @vitest-environment jsdom
// «Oggi»'s stage (3.12.1, tavole-mascotte-chat/luna.html): God's mascot, giant, above the
// greeting; its mood follows the page's real facts (typing, routing, work, a decision waiting,
// work finished, an error) and, still, it makes a small gesture now and then, never the same twice
// in a row and never with reduced motion. Timers are vitest's fake ones, never real time.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import type { TopicView } from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const { fake, sent } = vi.hoisted(() => ({
  fake: {
    impl: {} as Record<string, (...a: never[]) => unknown>,
    calls: [] as [string, unknown[]][],
  },
  sent: [] as Record<string, unknown>[],
}));
vi.mock("../src/api.js", async (orig) => {
  const real = await orig<typeof import("../src/api.js")>();
  class Api {
    constructor() {
      // biome-ignore lint/correctness/noConstructorReturn: a stand-in for the whole API
      return new Proxy(
        {},
        {
          get:
            (_t, name: string) =>
            (...args: unknown[]) => {
              fake.calls.push([name, args]);
              const f = fake.impl[name] as ((...a: unknown[]) => unknown) | undefined;
              return Promise.resolve(f ? f(...args) : []);
            },
        },
      );
    }
  }
  class Live {
    send(m: Record<string, unknown>) {
      sent.push(m);
    }
    close() {}
  }
  return { ...real, Api, Live };
});
const state = await import("../src/state.js");
const { SimpleApp } = await import("../src/components/Simple.js");
const { SimpleStage } = await import("../src/components/SimpleStage.js");

const topic = (id: string, o: Partial<TopicView> = {}): TopicView => ({
  id,
  title: id,
  summary: null,
  state: "ready",
  lastAt: "2026-11-22T09:00:00.000Z",
  personAt: "2026-11-22T09:00:00.000Z",
  createdAt: "2026-11-22T09:00:00.000Z",
  pinned: false,
  archived: false,
  unread: 0,
  requests: 0,
  tasks: 0,
  projectId: null,
  from: null,
  ...o,
});
const facts = (o: Partial<import("../src/state.js").GiantFacts> = {}) => ({
  typing: false,
  routing: false,
  working: false,
  waiting: false,
  happy: false,
  error: false,
  ...o,
});
let reduce = false;

beforeAll(async () => {
  fake.impl.setup = () => ({ config: { completed: true, ui: "simple" } });
  await state.signIn("token").catch(() => {});
  window.matchMedia = ((q: string) => ({
    matches: q.includes("reduce") && reduce,
    media: q,
    addEventListener() {},
    removeEventListener() {},
    addListener() {},
    removeListener() {},
    onchange: null,
    dispatchEvent: () => false,
  })) as unknown as typeof window.matchMedia;
});

beforeEach(() => {
  lang.value = "it";
  reduce = false;
  fake.impl.topics = () => ({ topics: [], archived: 0 });
  state.agents.value = [
    {
      id: "god",
      name: "God",
      kind: "god",
      parentId: null,
    } as unknown as (typeof state.agents.value)[number],
  ];
  state.topics.value = [];
  state.topicsLoaded.value = true;
  state.topicsTrouble.value = null;
  state.approvals.value = [];
  state.questions.value = [];
  state.lastError.value = null;
  state.simpleTyping.value = false;
  state.godRouting.value = false;
  state.giantCheer.value = false;
  state.simpleScreen.value = { kind: "today" };
  state.stageFront.value = "god";
  state.chatAgentId.value = null;
  state.sessionRows.value = [];
  fake.calls.length = 0;
  sent.length = 0;
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});

const mood = (r: ReturnType<typeof render>) =>
  r.container.querySelector(".smp-giant")?.getAttribute("data-mood");

describe("the giant's mood (pure)", () => {
  it("follows the facts, the most urgent first", () => {
    const table: [Partial<import("../src/state.js").GiantFacts>, string][] = [
      [{}, "rest"],
      [{ typing: true }, "listen"],
      [{ routing: true, typing: true }, "think"],
      [{ working: true }, "work"],
      [{ waiting: true, working: true }, "wait"],
      [{ happy: true, waiting: true }, "happy"],
      [{ error: true, routing: true, happy: true }, "worried"],
    ];
    for (const [f, m] of table) expect(state.giantMood(facts(f))).toBe(m);
    expect(state.GIANT_STATE.worried).toBe("error");
    expect(state.GIANT_STATE.rest).toBe("active");
  });

  it("never makes the same gesture twice in a row, and waits a different time", () => {
    let last: import("../src/state.js").IdleGesture | null = null;
    const seen = new Set<string>();
    let x = 0.13;
    const rand = () => {
      x = (x * 9301 + 0.49297) % 1;
      return x;
    };
    for (let i = 0; i < 200; i++) {
      const g = state.nextGesture(last, state.IDLE_GESTURES, rand);
      expect(g).not.toBe(last);
      seen.add(g);
      last = g;
    }
    expect(seen.size).toBe(state.IDLE_GESTURES.length);
    expect(state.nextGesture("hop", state.IDLE_GESTURES, () => 0.999)).not.toBe("hop");
    expect(state.gestureDelay(() => 0)).toBe(3500);
    expect(state.gestureDelay(() => 1)).toBe(8000);
  });

  it("is happy when a topic at work becomes ready", () => {
    expect(state.finishedWork([topic("a", { state: "working" })], [topic("a")])).toBe(true);
    expect(state.finishedWork([topic("a", { state: "waiting" })], [topic("a")])).toBe(false);
    expect(state.finishedWork([], [topic("a")])).toBe(false);
  });
});

describe("«Oggi»'s stage", () => {
  it("shows God giant above the greeting, its mood in words for screen readers", async () => {
    const r = render(<SimpleApp />);
    const giant = r.container.querySelector(".smp-giant");
    expect(giant).not.toBeNull();
    // Above the greeting.
    const h1 = r.getByRole("heading", { level: 1 });
    expect(giant?.compareDocumentPosition(h1) ?? 0).toBe(Node.DOCUMENT_POSITION_FOLLOWING);
    expect(r.getByRole("img", { name: "God: qui per te" })).toBeTruthy();
    expect(mood(r)).toBe("rest");
  });

  it("listens while the person types, then rests again", async () => {
    vi.useFakeTimers();
    const r = render(<SimpleApp />);
    fireEvent.input(r.getByPlaceholderText("Chiedimi qualcosa…"), { target: { value: "Ciao" } });
    expect(mood(r)).toBe("listen");
    await act(() => {
      vi.advanceTimersByTime(2600);
    });
    expect(mood(r)).toBe("rest");
  });

  it("thinks while God routes, works and waits as the topics say, worries on an error", async () => {
    let answer: (v: unknown) => void = () => {};
    fake.impl.godMessage = () => new Promise((ok) => (answer = ok));
    const r = render(<SimpleStage />);
    const routed = state.askGod("Un idraulico");
    await waitFor(() => expect(mood(r)).toBe("think"));
    answer({ sessionId: "t1", routed: { topicId: "t1", title: "Idraulico", via: "new" } });
    await routed;
    await waitFor(() => expect(mood(r)).not.toBe("think"));
    act(() => {
      state.topics.value = [topic("t1", { state: "working" })];
    });
    expect(mood(r)).toBe("work");
    act(() => {
      state.topics.value = [topic("t1", { state: "waiting" })];
    });
    expect(mood(r)).toBe("wait");
    act(() => {
      state.lastError.value = "Qualcosa non va";
    });
    expect(mood(r)).toBe("worried");
    expect(r.container.querySelector(".masc.st-error")).not.toBeNull();
  });

  it("is happy for a while when work finishes", async () => {
    vi.useFakeTimers();
    state.topics.value = [topic("t1", { state: "working" })];
    fake.impl.topics = () => ({ topics: [topic("t1")], archived: 0 });
    const r = render(<SimpleStage />);
    await act(() => state.refreshTopics());
    expect(mood(r)).toBe("happy");
    await act(() => {
      vi.advanceTimersByTime(4100);
    });
    expect(mood(r)).toBe("rest");
  });

  it("makes a gesture now and then while still, a different one each time", async () => {
    vi.useFakeTimers();
    // The same draw every time: still never the same gesture twice in a row.
    vi.spyOn(Math, "random").mockReturnValue(0.999);
    const r = render(<SimpleStage />);
    const seen: string[] = [];
    for (let i = 0; i < 6; i++) {
      await act(() => {
        vi.advanceTimersByTime(7996);
      });
      const g = r.container.querySelector(".smp-giant")?.getAttribute("data-gesture");
      expect(g).toBeTruthy();
      if (g) seen.push(g);
      await act(() => {
        vi.advanceTimersByTime(900);
      });
      expect(r.container.querySelector(".smp-giant")?.getAttribute("data-gesture")).toBeNull();
    }
    vi.restoreAllMocks();
    for (let i = 1; i < seen.length; i++) expect(seen[i]).not.toBe(seen[i - 1]);
    // God's eyes are one drawing: it never winks.
    expect(seen).not.toContain("wink");
  });

  it("makes no gesture with reduced motion", async () => {
    reduce = true;
    vi.useFakeTimers();
    const r = render(<SimpleStage />);
    await act(() => {
      vi.advanceTimersByTime(60_000);
    });
    expect(r.container.querySelector(".smp-giant")?.getAttribute("data-gesture")).toBeNull();
  });
});

const row = (id: string, o: Partial<import("../src/state.js").SessionRow> = {}) =>
  ({
    id,
    agentId: "chat",
    projectId: null,
    createdAt: "2026-11-20T10:00:00.000Z",
    lastAt: null,
    title: null,
    pinned: false,
    archived: false,
    running: false,
    ...o,
  }) as import("../src/state.js").SessionRow;

describe("Satellite, the Chat, on the same orbit (3.12.1)", () => {
  it("places the one in front big in the middle, the one behind small, dim and higher (pure)", () => {
    const front = state.orbitPlace(0, 200);
    expect(front).toEqual({ x: 0, y: 0, scale: 1, z: 200, light: 1, blur: 0 });
    const back = state.orbitPlace(state.ORBIT_BACK, 200);
    expect(back.scale).toBeLessThan(0.5);
    expect(back.z).toBeLessThan(front.z);
    expect(back.y).toBeLessThan(-60);
    expect(back.light).toBeLessThan(0.6);
    expect(state.orbitPlace(-state.ORBIT_BACK, 200).x).toBe(-back.x);
  });

  it("lists the Chat's latest conversations, newest first (pure)", () => {
    const rows = [
      row("a", { lastAt: "2026-11-21T10:00:00.000Z" }),
      row("b", { lastAt: "2026-11-22T10:00:00.000Z" }),
      row("c", { archived: true }),
      row("d", { agentId: "god" }),
    ];
    expect(state.recentChats(rows, "chat").map((r) => r.id)).toEqual(["b", "a"]);
    expect(state.recentChats(rows, null)).toEqual([]);
  });

  it("sits behind God; its name brings it in front, and the screen becomes the Chat's", () => {
    state.chatAgentId.value = "chat";
    state.sessionRows.value = [row("s1", { title: "Ricetta della carbonara" })];
    const r = render(<SimpleApp />);
    expect(r.container.querySelector(".smp-orbiter.god.front")).not.toBeNull();
    expect(r.container.querySelector(".smp-orbiter.sat.back")).not.toBeNull();
    expect(r.getByRole("img", { name: "Satellite: qui per te" })).toBeTruthy();
    expect(r.container.textContent).not.toMatch(/Luna/);
    fireEvent.click(r.getByRole("button", { name: "Satellite · Chat" }));
    expect(state.stageFront.value).toBe("chat");
    expect(r.container.querySelector(".smp-orbiter.sat.front")).not.toBeNull();
    expect(r.getByText("Due chiacchiere? Sono qui.")).toBeTruthy();
    expect(r.getByPlaceholderText("Scrivi a Satellite...")).toBeTruthy();
    expect(r.getByText("LE ULTIME CHIACCHIERE")).toBeTruthy();
    expect(r.getByText("Ricetta della carbonara")).toBeTruthy();
    expect(r.queryByText("IN CORSO")).toBeNull();
    // Back to God with his name.
    fireEvent.click(r.getByRole("button", { name: "God" }));
    expect(state.stageFront.value).toBe("god");
    expect(r.getByText("IN CORSO")).toBeTruthy();
  });

  it("turns with a swipe either way, or a tap on the one behind", () => {
    const r = render(<SimpleStage />);
    const stage = r.container.querySelector(".smp-stage") as HTMLElement;
    fireEvent.pointerDown(stage, { clientX: 300 });
    fireEvent.pointerUp(stage, { clientX: 120 });
    expect(state.stageFront.value).toBe("chat");
    fireEvent.pointerDown(stage, { clientX: 120 });
    fireEvent.pointerUp(stage, { clientX: 300 });
    expect(state.stageFront.value).toBe("god");
    // A short move is a tap: on the one behind, it comes in front.
    const back = r.container.querySelector(".smp-orbiter.back") as HTMLElement;
    fireEvent.pointerDown(back, { clientX: 200 });
    fireEvent.pointerUp(back, { clientX: 205 });
    expect(state.stageFront.value).toBe("chat");
  });

  it("writing there talks to the Chat agent: a new conversation, the message, then it opens", async () => {
    fake.impl.chatAgent = () => ({ id: "chat", name: "Chat", kind: "assistant", parentId: "god" });
    fake.impl.startSession = () => ({ sessionId: "s9" });
    state.stageFront.value = "chat";
    const r = render(<SimpleApp />);
    fireEvent.input(r.getByPlaceholderText("Scrivi a Satellite..."), {
      target: { value: "Che film vedo stasera?" },
    });
    fireEvent.click(r.getByRole("button", { name: "Invia" }));
    await waitFor(() => expect(state.simpleScreen.value).toMatchObject({ kind: "chat", id: "s9" }));
    expect(fake.calls.find(([n]) => n === "startSession")?.[1]).toEqual(["chat"]);
    expect(fake.calls.some(([n]) => n === "godMessage")).toBe(false);
    expect(sent).toContainEqual(
      expect.objectContaining({
        type: "session.send",
        sessionId: "s9",
        text: "Che film vedo stasera?",
      }),
    );
    // Inside, a reply goes to the same conversation, never to God.
    sent.length = 0;
    fireEvent.input(r.getByPlaceholderText("Rispondi…"), { target: { value: "E domani?" } });
    fireEvent.click(r.getByRole("button", { name: "Invia" }));
    expect(sent).toContainEqual(
      expect.objectContaining({ type: "session.send", sessionId: "s9", text: "E domani?" }),
    );
  });
});

describe("the agents' strip at the bottom (3.12.1, «Striscia fitta»)", () => {
  const agent = (id: string, kind: string, o: Record<string, unknown> = {}) =>
    ({
      id,
      name: id,
      kind,
      parentId: "god",
      status: "active",
      ...o,
    }) as unknown as (typeof state.agents.value)[number];
  const team = () => [
    agent("God", "god", { parentId: null }),
    agent("chat", "assistant", { name: "Chat" }),
    agent("Demi-God", "demigod"),
    agent("Ada", "orchestrator"),
    agent("Pixel", "agent", { parentId: "Ada" }),
    agent("Tester", "subagent", { parentId: "Pixel" }),
    agent("Old", "agent", { status: "stopped" }),
  ];

  it("keeps every agent with a face but God and the Chat (pure)", () => {
    expect(state.stripAgents(team(), "chat").map((a) => a.id)).toEqual([
      "Demi-God",
      "Ada",
      "Pixel",
    ]);
    expect(state.nearestIndex([10, 50, 90], 62)).toBe(1);
    expect(state.nearestIndex([], 5)).toBe(-1);
  });

  it("enlarges the one under the finger, its neighbours a little, with its balloon", async () => {
    state.agents.value = team();
    state.chatAgentId.value = "chat";
    state.sessionRows.value = [
      row("s4", { agentId: "Ada", title: "Il sito", lastAt: "2026-11-22T10:00:00.000Z" }),
    ];
    const r = render(<SimpleApp />);
    expect(r.getByText("I TUOI AGENTI")).toBeTruthy();
    const minis = [...r.container.querySelectorAll(".smp-sm")] as HTMLElement[];
    expect(minis).toHaveLength(3);
    fireEvent.focus(minis[1] as HTMLElement);
    expect(minis[1]?.classList.contains("on")).toBe(true);
    expect(minis[0]?.classList.contains("near")).toBe(true);
    expect(minis[2]?.classList.contains("near")).toBe(true);
    const balloon = r.container.querySelector(".smp-balloon") as HTMLElement;
    expect(balloon.textContent).toContain("Ada");
    expect(balloon.textContent).toContain("Apri la chat");
    expect(balloon.textContent).toContain("fermo");
    // Sliding along the strip moves the pick.
    fireEvent.pointerMove(r.container.querySelector(".smp-strip") as HTMLElement, { clientX: 0 });
    expect(minis[0]?.classList.contains("on")).toBe(true);
    // The balloon opens that agent's conversation.
    fireEvent.focus(minis[1] as HTMLElement);
    fireEvent.click(r.container.querySelector(".smp-balloon") as HTMLElement);
    await waitFor(() => expect(state.simpleScreen.value).toMatchObject({ kind: "chat", id: "s4" }));
  });

  it("keeps one balloon when the pick changes, and a press outside picks nobody (3.12.2)", async () => {
    state.agents.value = team();
    state.chatAgentId.value = "chat";
    const r = render(<SimpleApp />);
    const minis = [...r.container.querySelectorAll(".smp-sm")] as HTMLElement[];
    expect(r.container.querySelector(".smp-balloon.show")).toBeNull();
    fireEvent.focus(minis[0] as HTMLElement);
    fireEvent.focus(minis[1] as HTMLElement);
    // One balloon for the whole strip: the old one shrank, the new one grew, the balloon moved.
    expect(r.container.querySelectorAll(".smp-balloon")).toHaveLength(1);
    expect(r.container.querySelectorAll(".smp-sm.on")).toHaveLength(1);
    expect(minis[0]?.classList.contains("on")).toBe(false);
    expect(minis[1]?.classList.contains("on")).toBe(true);
    expect(r.container.querySelector(".smp-balloon.show b")?.textContent).toBe("Ada");
    // A press on the strip itself keeps the pick.
    fireEvent.pointerDown(r.container.querySelector(".smp-strip") as HTMLElement, { clientX: 0 });
    expect(r.container.querySelector(".smp-balloon.show")).not.toBeNull();
    // A press outside the strip and its balloon: nobody is picked, the sizes are back.
    fireEvent.pointerDown(r.container.querySelector(".smp-hero") ?? document.body);
    await waitFor(() => expect(r.container.querySelector(".smp-balloon.show")).toBeNull());
    expect(r.container.querySelectorAll(".smp-sm.on, .smp-sm.near")).toHaveLength(0);
  });

  it("floats at the bottom of the window, with room under the content (3.12.2)", () => {
    const css = readFileSync(join(import.meta.dirname, "..", "src", "styles.css"), "utf8");
    const rule = css.match(/\n\.smp-strip-wrap \{[^}]*\}/)?.[0] ?? "";
    expect(rule).toContain("position: sticky");
    expect(rule).toContain("bottom: 0");
    expect(rule).toContain("env(safe-area-inset-bottom");
    // Opaque over the content, in both themes (the page's own background).
    expect(rule).toContain("var(--bg)");
    expect(css).toMatch(/\.smp-today \.smp-wrap > \.smp-strip-wrap \{\s*margin-top: auto;/);
  });

  it("starts a conversation with an agent that has none", async () => {
    state.agents.value = team();
    state.chatAgentId.value = "chat";
    fake.impl.startSession = () => ({ sessionId: "s7" });
    const r = render(<SimpleApp />);
    const minis = [...r.container.querySelectorAll(".smp-sm")] as HTMLElement[];
    fireEvent.focus(minis[2] as HTMLElement);
    fireEvent.click(r.container.querySelector(".smp-balloon") as HTMLElement);
    await waitFor(() => expect(state.simpleScreen.value).toMatchObject({ kind: "chat", id: "s7" }));
    expect(fake.calls.find(([n]) => n === "startSession")?.[1]).toEqual(["Pixel"]);
  });

  it("is not there without agents", () => {
    state.agents.value = [agent("God", "god", { parentId: null })];
    const r = render(<SimpleApp />);
    expect(r.container.querySelector(".smp-strip")).toBeNull();
  });
});

describe("the agents on a topic's card (3.12.1)", () => {
  it("shows who opened it and who works on its tasks; nobody, nothing", async () => {
    state.agents.value = [
      { id: "God", name: "God", kind: "god", parentId: null, status: "active" },
      { id: "ada", name: "Ada", kind: "assistant", parentId: "God", status: "active" },
      { id: "pixel", name: "Pixel", kind: "orchestrator", parentId: "God", status: "active" },
    ] as unknown as typeof state.agents.value;
    fake.impl.topics = () => ({
      topics: [
        topic("t1", {
          from: "Ada",
          agents: [
            { id: "ada", role: "from" },
            { id: "pixel", role: "task" },
          ],
        }),
        topic("t2"),
      ],
      archived: 0,
    });
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.container.querySelectorAll(".smp-card").length).toBe(2));
    const cards = [...r.container.querySelectorAll(".smp-card")];
    const minis = cards[0]?.querySelectorAll(".smp-card-agent") ?? [];
    expect(minis).toHaveLength(2);
    expect(minis[0]?.getAttribute("title")).toBe("Ada, fermo");
    expect(minis[1]?.getAttribute("title")).toBe("Pixel, fermo");
    expect(cards[1]?.querySelector(".smp-card-agents")).toBeNull();
  });
});

describe("God's friendly nudge (3.12.1)", () => {
  it("arrives on the live connection: once, in «Oggi» and in the full view's bell", () => {
    state.notices.value = [];
    const m = {
      type: "god.nudge" as const,
      nudge: {
        id: "d1-waiting",
        kind: "waiting" as const,
        topicId: "t1",
        text: "«Sito» aspetta te.",
        at: "2026-11-23T09:00:00.000Z",
      },
    };
    state.applyMessage(m);
    state.applyMessage(m);
    expect(state.godNudge.value?.id).toBe("d1-waiting");
    expect(state.notices.value).toHaveLength(1);
    expect(state.notices.value[0]).toMatchObject({ sessionId: "t1", text: "«Sito» aspetta te." });
  });

  const nudge = (o: Partial<import("@redgiant/protocol").GodNudge> = {}) => ({
    id: "2026-11-23-greeting",
    kind: "greeting" as const,
    topicId: null,
    text: "Ciao! A cosa lavoriamo oggi?",
    at: "2026-11-23T09:00:00.000Z",
    ...o,
  });

  it("a generic one opens only «Oggi» with the invitation: nothing is made until the person writes", async () => {
    const r = render(<SimpleApp />);
    act(() => {
      state.godNudge.value = nudge();
    });
    fireEvent.click(r.getByRole("button", { name: "Ciao! A cosa lavoriamo oggi?" }));
    expect(state.godNudge.value).toBeNull();
    expect(state.simpleScreen.value).toEqual({ kind: "today" });
    // The invitation is the lead; no message, no topic.
    expect(r.getByText("Ciao! A cosa lavoriamo oggi?")).toBeTruthy();
    expect(fake.calls.some(([n]) => n === "godMessage")).toBe(false);
    expect(sent.filter((m) => m.type === "session.send")).toEqual([]);
    // Only when the person writes does a topic come (God routes the message as ever).
    fake.impl.godMessage = () => ({
      sessionId: "t9",
      routed: { topicId: "t9", title: "Oggi", via: "new", reason: "new_topic" },
    });
    fireEvent.input(r.getByPlaceholderText("Chiedimi qualcosa…"), {
      target: { value: "Il preventivo" },
    });
    fireEvent.click(r.getByRole("button", { name: "Invia" }));
    await waitFor(() =>
      expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t9" }),
    );
    // Its words were never sent: the message is the person's alone.
    expect(fake.calls.find(([n]) => n === "godMessage")?.[1]).toEqual([{ text: "Il preventivo" }]);
    expect(state.nudgeInvite.value).toBeNull();
  });

  it("one about a topic opens that topic; closing it does nothing else", () => {
    state.topics.value = [topic("t1", { title: "Preventivo Rossi", state: "waiting" })];
    const r = render(<SimpleApp />);
    act(() => {
      state.godNudge.value = nudge({
        kind: "waiting",
        topicId: "t1",
        text: "«Preventivo Rossi» aspetta te.",
      });
    });
    fireEvent.click(r.getByRole("button", { name: "«Preventivo Rossi» aspetta te." }));
    expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t1" });
    act(() => {
      state.simpleScreen.value = { kind: "today" };
      state.godNudge.value = nudge();
    });
    fireEvent.click(r.getByRole("button", { name: "Chiudi" }));
    expect(state.godNudge.value).toBeNull();
    expect(state.simpleScreen.value).toEqual({ kind: "today" });
  });

  it("is switched off or made rarer from the simple settings", async () => {
    fake.impl.nudgeSettings = () => ({ on: true, every: "day" });
    fake.impl.setNudgeSettings = () => ({ ok: true });
    state.simpleScreen.value = { kind: "settings" };
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText("Un saluto da God ogni tanto")).toBeTruthy());
    fireEvent.click(r.getByRole("button", { name: "Una volta a settimana" }));
    expect(fake.calls.find(([n]) => n === "setNudgeSettings")?.[1]).toEqual([
      { on: true, every: "week" },
    ]);
    fireEvent.click(r.getByRole("switch", { name: "Un saluto da God ogni tanto" }));
    expect(fake.calls.filter(([n]) => n === "setNudgeSettings").at(-1)?.[1]).toEqual([
      { on: false, every: "week" },
    ]);
  });
});

describe("a conversation in the simple view: no technical details (3.12.1)", () => {
  const ev = (seq: number, type: string, payload: unknown) =>
    ({
      seq,
      type,
      payload,
      sessionId: "s5",
      ts: `2026-11-23T09:00:0${seq}.000Z`,
      hash: "",
      prevHash: "",
    }) as unknown as import("@redgiant/protocol").Event;
  const answer = (seqNo: number) =>
    ev(seqNo, "message.assistant", {
      parts: [
        { type: "thinking", text: "Ragionamento segreto sui voli" },
        { type: "text", text: "Il volo più comodo costa 89 euro." },
      ],
      metrics: {
        inputTokens: 1200,
        outputTokens: 80,
        cacheReadTokens: 0,
        cacheWriteTokens: 0,
        contextUsed: 1280,
        contextWindow: 200000,
        ms: 900,
      },
      costUsd: 0.25,
      model: "claude-opus-5-5",
      provider: "anthropic",
      stopReason: "end_turn",
    });
  const events = () => [
    ev(1, "message.user", { text: "Un volo per Cagliari?" }),
    ev(2, "tool.call", { callId: "c1", tool: "web_search", input: { q: "voli Cagliari" } }),
    ev(3, "tool.result", { callId: "c1", ok: true, output: "risultato grezzo della ricerca" }),
    answer(4),
  ];
  const team = () => {
    state.agents.value = [
      { id: "God", name: "God", kind: "god", parentId: null, status: "active" },
      { id: "chat", name: "Chat", kind: "assistant", parentId: "God", status: "active" },
    ] as unknown as typeof state.agents.value;
    state.chatAgentId.value = "chat";
    state.sessionRows.value = [row("s5", { title: "Voli" })];
  };

  it("shows the words and the cost at the top, never tools, results, reasoning or figures", () => {
    team();
    state.sessionView("s5").value = {
      events: events(),
      text: "",
      thinking: "",
      state: "idle",
      synced: true,
    };
    state.simpleScreen.value = { kind: "chat", id: "s5", title: "Voli" };
    const r = render(<SimpleApp />);
    const text = r.container.textContent ?? "";
    expect(text).toContain("Il volo più comodo costa 89 euro.");
    expect(text).toContain("Un volo per Cagliari?");
    expect(text).toContain("Speso qui: $0.25");
    for (const hidden of [
      "web_search",
      "risultato grezzo",
      "Ragionamento segreto",
      "1.2k",
      "claude-opus",
    ])
      expect(text, hidden).not.toContain(hidden);
  });

  it("while the agent works: its mascot and a word, «sta cercando…» for a search", () => {
    team();
    state.sessionView("s5").value = {
      events: events().slice(0, 2),
      text: "",
      thinking: "",
      state: "running",
      synced: true,
    };
    state.simpleScreen.value = { kind: "chat", id: "s5", title: "Voli" };
    const r = render(<SimpleApp />);
    const line = r.container.querySelector(".smp-working");
    expect(line?.textContent).toBe("sta cercando…");
    expect(line?.querySelector(".mascot")).not.toBeNull();
    expect(r.container.textContent).not.toContain("web_search");
  });

  it("says the word for each moment (pure)", () => {
    const e = events();
    expect(state.workWord(e, false, false, false)).toBeNull();
    expect(state.workWord(e, false, false, true)).toBe("smpDoingWait");
    expect(state.workWord(e.slice(0, 1), true, false, false)).toBe("smpDoingThink");
    expect(state.workWord(e.slice(0, 2), true, false, false)).toBe("smpDoingSearch");
    expect(state.workWord(e.slice(0, 2), true, true, false)).toBe("smpDoingThink");
    const run = [e[0], ev(2, "tool.call", { callId: "c2", tool: "write_file", input: {} })];
    expect(state.workWord(run as never, true, false, false)).toBe("smpDoingWork");
    expect(state.conversationCost(e)).toBe(0.25);
  });

  it("the full view still shows them", async () => {
    team();
    state.sessionView("s5").value = {
      events: events(),
      text: "",
      thinking: "",
      state: "idle",
      synced: true,
    };
    const { Chat } = await import("../src/components/Chat.js");
    const r = render(<Chat sessionId="s5" agentId="chat" />);
    const text = r.container.textContent ?? "";
    expect(text).toContain("Il volo più comodo costa 89 euro.");
    // The tool's line and the per-message figures are there.
    expect(text).toMatch(/cerca|search/i);
    expect(r.container.querySelector(".metrics, .metrics-bar, [class*=metric]")).not.toBeNull();
  });
});
