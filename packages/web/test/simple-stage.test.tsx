// @vitest-environment jsdom
// «Oggi»'s stage (3.12.1, tavole-mascotte-chat/luna.html): God's mascot, giant, above the
// greeting; its mood follows the page's real facts (typing, routing, work, a decision waiting,
// work finished, an error) and, still, it makes a small gesture now and then, never the same twice
// in a row and never with reduced motion. Timers are vitest's fake ones, never real time.
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
    await act(() => vi.advanceTimersByTime(2600));
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
    await act(() => vi.advanceTimersByTime(4100));
    expect(mood(r)).toBe("rest");
  });

  it("makes a gesture now and then while still, a different one each time", async () => {
    vi.useFakeTimers();
    // The same draw every time: still never the same gesture twice in a row.
    vi.spyOn(Math, "random").mockReturnValue(0.999);
    const r = render(<SimpleStage />);
    const seen: string[] = [];
    for (let i = 0; i < 6; i++) {
      await act(() => vi.advanceTimersByTime(7996));
      const g = r.container.querySelector(".smp-giant")?.getAttribute("data-gesture");
      expect(g).toBeTruthy();
      if (g) seen.push(g);
      await act(() => vi.advanceTimersByTime(900));
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
    await act(() => vi.advanceTimersByTime(60_000));
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
    expect(r.container.querySelector(".smp-orbiter.chat.back")).not.toBeNull();
    expect(r.getByRole("img", { name: "Satellite: qui per te" })).toBeTruthy();
    expect(r.container.textContent).not.toMatch(/Luna/);
    fireEvent.click(r.getByRole("button", { name: "Satellite · Chat" }));
    expect(state.stageFront.value).toBe("chat");
    expect(r.container.querySelector(".smp-orbiter.chat.front")).not.toBeNull();
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
