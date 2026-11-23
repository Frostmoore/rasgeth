// @vitest-environment jsdom
// The simple interface (3.12, «B · Assistente»): «Oggi» with the greeting, the big box and the
// topics' cards; a topic read as a document with its decisions in a box and «in: Title · Move»;
// the archive with its search; a few settings and the switch to the full view, remembered per
// device. The fake server answers as the contract says (`topics.ts`: every answer goes through its
// zod schema).
import {
  type Event,
  GodMessageRequest,
  GodMessageResponse,
  MoveRequest,
  MoveResponse,
  type PermissionRequestInfo,
  TopicList,
  type TopicView,
} from "@redgiant/protocol";
import { act, cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const { fake, sent } = vi.hoisted(() => ({
  fake: {
    calls: [] as [string, unknown[]][],
    impl: {} as Record<string, (...a: never[]) => unknown>,
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
const { App } = await import("../src/components/App.js");
const { General } = await import("../src/components/General.js");

const iso = (m: number) => new Date(Date.UTC(2026, 10, 22, 9, m)).toISOString();
const topic = (id: string, title: string, o: Partial<TopicView> = {}): TopicView => ({
  id,
  title,
  summary: null,
  state: "ready",
  lastAt: iso(0),
  personAt: iso(0),
  createdAt: iso(0),
  pinned: false,
  archived: false,
  unread: 0,
  requests: 0,
  tasks: 0,
  projectId: null,
  from: null,
  ...o,
});

/** God's topics as the server keeps them: the contract's shapes, nothing more. */
class FakeTopics {
  active: TopicView[] = [];
  archived: TopicView[] = [];
  list(q: { archived?: boolean; q?: string } = {}) {
    const words = q.q?.toLowerCase() ?? "";
    const from = q.archived ? this.archived : this.active;
    return TopicList.parse({
      topics: from.filter((x) => `${x.title} ${x.summary ?? ""}`.toLowerCase().includes(words)),
      archived: this.archived.length,
    });
  }
  send(body: unknown) {
    const b = GodMessageRequest.parse(body);
    const known = b.topicId ? this.active.find((x) => x.id === b.topicId) : this.active[0];
    const to = known ?? topic("t_new", b.text.slice(0, 30), { state: "working" });
    if (!known) this.active.unshift(to);
    return GodMessageResponse.parse({
      sessionId: to.id,
      routed: {
        topicId: to.id,
        title: to.title,
        via: b.topicId ? "here" : "router",
        reason: b.topicId ? "written_here" : "router",
        isNew: !known,
        restored: false,
        uncertain: false,
      },
    });
  }
  move(_id: string, seq: number, body: unknown) {
    const b = MoveRequest.parse(body);
    const to =
      b.to === "new"
        ? topic("t_moved", b.title ?? "Nuovo", { state: "working" })
        : (this.active.find((x) => x.id === b.to) ?? this.archived.find((x) => x.id === b.to));
    if (!to) throw new Error("not a topic");
    if (b.to === "new") this.active.unshift(to);
    return MoveResponse.parse({
      sessionId: to.id,
      seq,
      throughSeq: seq + 1,
      routed: {
        topicId: to.id,
        title: to.title,
        via: "person",
        reason: "chosen",
        isNew: b.to === "new",
        restored: false,
        uncertain: false,
      },
      tasks: [],
    });
  }
  action(id: string, what: "archive" | "restore" | "read") {
    if (what === "archive") {
      const x = this.active.find((t) => t.id === id);
      this.active = this.active.filter((t) => t.id !== id);
      if (x) this.archived.push({ ...x, archived: true });
    }
    if (what === "restore") {
      const x = this.archived.find((t) => t.id === id);
      this.archived = this.archived.filter((t) => t.id !== id);
      if (x) this.active.unshift({ ...x, archived: false });
    }
    return { ok: true as const };
  }
}
let server = new FakeTopics();

const ev = (seq: number, type: string, payload: unknown, sessionId = "t_trip"): Event =>
  ({ seq, type, payload, sessionId, ts: iso(seq), hash: "", prevHash: "" }) as unknown as Event;

const tripEvents = (): Event[] => [
  ev(1, "topic.opened", { title: "Vacanza in Sardegna", by: "router" }),
  ev(2, "topic.routed", { via: "router", reason: "router", uncertain: true, confidence: 0.4 }),
  ev(3, "message.user", { text: "Mi trovi un volo per Cagliari il 14 luglio?" }),
  ev(4, "tool.call", { callId: "c1", tool: "web_search", input: { q: "voli" } }),
  ev(5, "tool.result", { callId: "c1", ok: true, output: "…" }),
  ev(6, "message.assistant", {
    parts: [{ type: "text", text: "Ne ho trovati tre. Il più comodo costa **89 €**." }],
    metrics: {
      inputTokens: 1,
      outputTokens: 1,
      cacheReadTokens: 0,
      cacheWriteTokens: 0,
      contextUsed: 1,
      contextWindow: 100,
      ms: 1,
    },
    costUsd: 0.01,
    model: "m",
    provider: "anthropic",
    stopReason: "end_turn",
  }),
];

beforeAll(async () => {
  fake.impl.setup = () => ({ config: { completed: true, ui: "simple", personName: "Riccardo" } });
  await state.signIn("token").catch(() => {});
});

beforeEach(() => {
  lang.value = "it";
  localStorage.clear();
  sent.length = 0;
  fake.calls.length = 0;
  server = new FakeTopics();
  server.active = [
    topic("t_trip", "Vacanza in Sardegna", {
      summary: "Ho trovato 3 voli per il 14 luglio",
      state: "waiting",
      requests: 1,
      unread: 1,
    }),
    topic("t_gift", "Regalo per la mamma", { summary: "Idee sotto i 50 €" }),
    topic("t_site", "Sito per lo zio", {
      summary: "Sto preparando la prima versione",
      state: "working",
    }),
  ];
  server.archived = [
    topic("t_old", "Bollette", { summary: "La luce di novembre", archived: true }),
  ];
  Object.assign(fake.impl, {
    topics: (q?: { archived?: boolean; q?: string }) => server.list(q),
    godMessage: (b: unknown) => server.send(b),
    moveMessage: (id: string, seq: number, b: unknown) => server.move(id, seq, b),
    topicAction: (id: string, what: "archive" | "restore" | "read") => server.action(id, what),
    telegramLinks: () => [],
    setupPerson: () => ({ ok: true }),
    updateSession: () => ({ ok: true }),
  });
  state.uiChoice.value = null;
  state.setupLoaded({ ui: "simple", personName: "Riccardo" });
  state.simpleScreen.value = { kind: "today" };
  state.approvals.value = [];
  state.questions.value = [];
  state.sessionView("t_trip").value = {
    events: tripEvents(),
    text: "",
    thinking: "",
    state: "idle",
    synced: true,
  };
  Element.prototype.scrollIntoView = vi.fn();
});
afterEach(cleanup);

const called = (name: string) => fake.calls.filter(([n]) => n === name).map(([, a]) => a);

describe("the simple interface's rules (pure)", () => {
  it("shows the device's choice, else the installation's, else the simple one", () => {
    expect(state.effectiveUi(null, undefined)).toBe("simple");
    expect(state.effectiveUi(null, "full")).toBe("full");
    expect(state.effectiveUi(null, "simple")).toBe("simple");
    expect(state.effectiveUi("full", "simple")).toBe("full");
    expect(state.effectiveUi("simple", "full")).toBe("simple");
  });

  it("greets by the hour", () => {
    expect([4, 5, 12, 13, 17, 18, 23].map(state.greetingKey)).toEqual([
      "smpEvening",
      "smpMorning",
      "smpMorning",
      "smpAfternoon",
      "smpAfternoon",
      "smpEvening",
      "smpEvening",
    ]);
  });

  it("reads a topic as a document: no tools, a routing line with its message, moved exchanges gone", () => {
    const events = [
      ...tripEvents(),
      ev(7, "topic.routed", { via: "here", reason: "written_here" }),
      ev(8, "message.user", { text: "E per il ritorno?" }),
      ev(9, "message.assistant", {
        parts: [{ type: "text", text: "Il 21 luglio." }],
        metrics: {
          inputTokens: 1,
          outputTokens: 1,
          cacheReadTokens: 0,
          cacheWriteTokens: 0,
          contextUsed: 1,
          contextWindow: 100,
          ms: 1,
        },
        costUsd: 0,
        model: "m",
        stopReason: "end_turn",
      }),
      ev(10, "message.moved", { seq: 3, throughSeq: 6, toSessionId: "t_gift", by: "person" }),
    ];
    const items = state.buildItems(events);
    const routed = items.find((i) => i.kind === "routed");
    expect(routed).toMatchObject({ kind: "routed", via: "router", uncertain: true, userSeq: 3 });
    expect(items.find((i) => i.kind === "user")).toMatchObject({ seq: 3 });
    const doc = state.documentItems(items);
    expect(doc.map((i) => i.kind)).toEqual(["user", "assistant", "moved"]);
    expect(doc[0]).toMatchObject({ text: "E per il ritorno?" });
    expect(doc[2]).toMatchObject({ toSessionId: "t_gift", seq: 3, throughSeq: 6 });
  });
});

describe("«Oggi»", () => {
  it("greets the person, offers the big box and shows the topics with their state in words", async () => {
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText("Vacanza in Sardegna")).toBeTruthy());
    expect(r.getByRole("heading", { level: 1 }).textContent).toMatch(/, Riccardo$/);
    expect(r.getByPlaceholderText("Chiedimi qualcosa…")).toBeTruthy();
    expect(r.getByText("IN CORSO")).toBeTruthy();
    expect(r.getByText("ti aspetto")).toBeTruthy();
    expect(r.getByText("al lavoro")).toBeTruthy();
    expect(r.getByText("pronto")).toBeTruthy();
    expect(r.getByText("Ho trovato 3 voli per il 14 luglio")).toBeTruthy();
    expect(r.getByText("Archivio (1)")).toBeTruthy();
    // Nothing technical in sight.
    expect(r.container.textContent).not.toMatch(/agent|strument|token|modell|\$/i);
    // No browser controls of its own: our switches, never checkboxes.
    expect(r.container.querySelector("input[type=checkbox], input[type=radio], select")).toBeNull();
  });

  it("sends what is asked to God without a topic, then opens the topic it went to", async () => {
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText("Vacanza in Sardegna")).toBeTruthy());
    const box = r.getByPlaceholderText("Chiedimi qualcosa…");
    fireEvent.input(box, { target: { value: "Mi serve un idraulico domani" } });
    fireEvent.keyDown(box, { key: "Enter" });
    await waitFor(() => expect(called("godMessage")).toHaveLength(1));
    expect(called("godMessage")[0]?.[0]).toEqual({ text: "Mi serve un idraulico domani" });
    await waitFor(() =>
      expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t_trip" }),
    );
    expect(r.getByRole("heading", { level: 2 }).textContent).toBe("Vacanza in Sardegna");
  });

  it("shows what was sent at once while God chooses its topic, the box already empty (3.12.1)", async () => {
    let answer: (v: unknown) => void = () => {};
    const routed = server.send.bind(server);
    fake.impl.godMessage = (b: unknown) =>
      new Promise((ok) => {
        answer = () => ok(routed(b));
      });
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText("Vacanza in Sardegna")).toBeTruthy());
    const box = r.getByPlaceholderText("Chiedimi qualcosa…") as HTMLTextAreaElement;
    fireEvent.input(box, { target: { value: "Mi serve un idraulico domani" } });
    fireEvent.keyDown(box, { key: "Enter" });
    await waitFor(() =>
      expect(r.getByRole("status").textContent).toContain("Mi serve un idraulico domani"),
    );
    expect(r.getByRole("status").textContent).toContain("Lo metto nell'argomento giusto…");
    expect(box.value).toBe("");
    answer(undefined);
    await waitFor(() =>
      expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t_trip" }),
    );
    expect(state.godRoutingText.value).toBeNull();
  });

  it("opens a card: its news counts as read", async () => {
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText("Vacanza in Sardegna")).toBeTruthy());
    fireEvent.click(r.getByText("Vacanza in Sardegna"));
    await waitFor(() => expect(called("topicAction")).toContainEqual(["t_trip", "read"]));
    expect(sent).toContainEqual({ type: "session.follow", sessionId: "t_trip" });
  });
});

describe("a server before 3.12 (3.12.1)", () => {
  const fresh = () => {
    state.topics.value = [];
    state.topicsLoaded.value = false;
    state.topicsTrouble.value = null;
  };
  it("says in words that the server must be updated, and offers the full interface", async () => {
    fresh();
    // No God's topics on that server: its answer is a 404.
    fake.impl.topics = () => {
      throw Object.assign(new Error("Not found"), { status: 404 });
    };
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText(/aggiornare il server alla 3\.12/)).toBeTruthy());
    expect(r.queryByText("Un momento…")).toBeNull();
    fireEvent.click(r.getByRole("button", { name: "Vista completa" }));
    expect(state.uiMode.value).toBe("full");
  });

  it("any other error offers to try again, and the topics come", async () => {
    fresh();
    let fail = true;
    fake.impl.topics = () => {
      if (fail) throw Object.assign(new Error("Bad gateway"), { status: 502 });
      return server.list();
    };
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText(/non sono arrivati/)).toBeTruthy());
    fail = false;
    fireEvent.click(r.getByRole("button", { name: "Riprova" }));
    await waitFor(() => expect(r.getByText("Vacanza in Sardegna")).toBeTruthy());
    expect(r.queryByText(/non sono arrivati/)).toBeNull();
  });

  it("tells a 404 from the rest (pure)", () => {
    expect(state.topicsMissing({ status: 404 })).toBe(true);
    expect(state.topicsMissing({ status: 500 })).toBe(false);
    expect(state.topicsMissing(new Error("x"))).toBe(false);
    expect(state.topicsMissing(null)).toBe(false);
  });
});

describe("a topic", () => {
  const request: PermissionRequestInfo = {
    requestId: "rq1",
    agentId: "god",
    agentName: "God",
    sessionId: "t_trip",
    tool: "bash",
    input: { command: "rm -rf /tmp/old" },
    reasons: [],
    danger: [],
    askedTo: "human",
    createdAt: iso(9),
    topic: { id: "t_trip", title: "Vacanza in Sardegna" },
  } as unknown as PermissionRequestInfo;

  it("reads as a document: the answer, no tools, «in: Title · Move» when unsure", async () => {
    await state.refreshTopics();
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    expect(r.getByText("Mi trovi un volo per Cagliari il 14 luglio?")).toBeTruthy();
    expect(r.container.querySelector(".md-read strong")?.textContent).toBe("89 €");
    expect(r.container.textContent).not.toContain("web_search");
    const line = r.container.querySelector(".smp-routed.unsure");
    expect(line?.textContent).toContain("Non ero sicuro: l'ho messo qui");
    expect(line?.textContent).toContain("Sposta");
    expect(r.getByPlaceholderText("Rispondi…")).toBeTruthy();
  });

  it("has the «back to the bottom» button once the person scrolled up, and following again after it", async () => {
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    expect(r.container.querySelector(".to-bottom")).toBeNull();
    fireEvent.wheel(r.container.querySelector(".smp-doc") as Element, { deltaY: -40 });
    const button = await waitFor(() => {
      const b = r.container.querySelector(".to-bottom");
      expect(b).not.toBeNull();
      return b as HTMLElement;
    });
    expect(button.getAttribute("title")).toBe("Vai in fondo");
    fireEvent.click(button);
    await waitFor(() => expect(r.container.querySelector(".to-bottom")).toBeNull());
  });

  it("writes inside the topic: no routing elsewhere", async () => {
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    const box = r.getByPlaceholderText("Rispondi…");
    fireEvent.input(box, { target: { value: "Prendi quello delle 9:40" } });
    fireEvent.click(r.getByLabelText("Invia"));
    await waitFor(() =>
      expect(called("godMessage")[0]?.[0]).toEqual({
        text: "Prendi quello delle 9:40",
        topicId: "t_trip",
      }),
    );
    expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t_trip" });
  });

  it("moves an exchange to another topic, then opens it", async () => {
    await state.refreshTopics();
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    const line = r.container.querySelector(".smp-routed.unsure") as HTMLElement;
    fireEvent.click(line.querySelector("button") as HTMLElement);
    await waitFor(() => expect(r.getByText("Sposta in un altro argomento")).toBeTruthy());
    // The search finds the archived ones too.
    fireEvent.input(r.getByPlaceholderText("Cerca nei tuoi argomenti"), {
      target: { value: "boll" },
    });
    await waitFor(() => expect(called("topics")).toContainEqual([{ archived: true, q: "boll" }]));
    await waitFor(() => expect(r.getByText("Bollette")).toBeTruthy());
    fireEvent.input(r.getByPlaceholderText("Cerca nei tuoi argomenti"), { target: { value: "" } });
    await waitFor(() => expect(r.getByText("Regalo per la mamma")).toBeTruthy());
    fireEvent.click(r.getByText("Regalo per la mamma"));
    await waitFor(() => expect(called("moveMessage")).toEqual([["t_trip", 3, { to: "t_gift" }]]));
    await waitFor(() =>
      expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t_gift" }),
    );
  });

  it("puts a request in plain words in an evident box, answered with one button", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    state.approvals.value = [request];
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    const box = r.container.querySelector(".smp-decide") as HTMLElement;
    expect(box.textContent).toContain("Posso procedere?");
    // The technical names stay out: the sentence says what happens.
    expect(box.textContent).not.toContain("bash");
    await act(async () => {
      vi.advanceTimersByTime(1000);
    });
    fireEvent.click(r.getByText("Sì, procedi"));
    expect(sent).toContainEqual({
      type: "permission.resolve",
      requestId: "rq1",
      decision: "allow",
      remember: false,
      scope: "once",
    });
    vi.useRealTimers();
  });

  it("asks a plain question with its buttons, as the board («Vuoi che lo prenoti?»)", async () => {
    vi.useFakeTimers({ shouldAdvanceTime: true });
    const asked = {
      requestId: "q1",
      questions: [
        {
          question: "Vuoi che lo prenoti?",
          options: [{ label: "Sì, prenota" }, { label: "Mostrami gli altri" }],
          multiSelect: false,
        },
      ],
    };
    state.sessionView("t_trip").value = {
      ...state.sessionView("t_trip").value,
      events: [...tripEvents(), ev(7, "question.asked", asked)],
    };
    state.questions.value = [
      {
        ...asked,
        sessionId: "t_trip",
        agentId: "god",
        agentName: "God",
        projectId: null,
        createdAt: iso(7),
      },
    ] as never;
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    const box = r.container.querySelector(".smp-decide") as HTMLElement;
    expect(box.textContent).toContain("Vuoi che lo prenoti?");
    expect(box.querySelectorAll(".smp-btn")).toHaveLength(3);
    await act(async () => {
      vi.advanceTimersByTime(1000);
    });
    fireEvent.click(r.getByText("Sì, prenota"));
    expect(sent).toContainEqual({
      type: "question.answer",
      requestId: "q1",
      answers: [["Sì, prenota"]],
    });
    vi.useRealTimers();
  });

  it("archives the topic from its menu", async () => {
    await state.refreshTopics();
    state.openTopic("t_trip", "Vacanza in Sardegna");
    const r = render(<SimpleApp />);
    fireEvent.click(r.getByLabelText("Altro"));
    fireEvent.click(r.getByText("Metti in archivio"));
    await waitFor(() => expect(called("topicAction")).toContainEqual(["t_trip", "archive"]));
    await waitFor(() => expect(state.simpleScreen.value).toEqual({ kind: "today" }));
  });
});

describe("the archive", () => {
  it("finds a topic with words and takes it back with a tap", async () => {
    state.simpleScreen.value = { kind: "archive" };
    const r = render(<SimpleApp />);
    await waitFor(() => expect(r.getByText("Bollette")).toBeTruthy());
    fireEvent.input(r.getByPlaceholderText("Cerca nei tuoi argomenti"), {
      target: { value: "zzz" },
    });
    await waitFor(() => expect(r.getByText("Niente con queste parole.")).toBeTruthy());
    fireEvent.input(r.getByPlaceholderText("Cerca nei tuoi argomenti"), {
      target: { value: "luce" },
    });
    await waitFor(() => expect(r.getByText("Bollette")).toBeTruthy());
    fireEvent.click(r.getByText("Bollette"));
    await waitFor(() => expect(called("topicAction")).toContainEqual(["t_old", "restore"]));
    await waitFor(() =>
      expect(state.simpleScreen.value).toMatchObject({ kind: "topic", id: "t_old" }),
    );
  });
});

describe("the switch between the simple and the full view", () => {
  it("opens the simple view when the installation chose it, the full one once this device switches", async () => {
    const r = render(<App />);
    await waitFor(() => expect(r.container.querySelector(".app-simple")).not.toBeNull());
    fireEvent.click(r.getByLabelText("Impostazioni"));
    expect(r.getByText("Avvisi su questo dispositivo")).toBeTruthy();
    expect(r.getByText("Chiedimi prima di spendere")).toBeTruthy();
    fireEvent.click(r.getByRole("switch", { name: "Vista completa" }));
    expect(state.uiMode.value).toBe("full");
    expect(localStorage.getItem("rg.ui")).toBe("full");
    await waitFor(() => expect(r.container.querySelector(".app-simple")).toBeNull());
  });

  it("goes back to the simple view from Settings > General, on this device only", async () => {
    state.setUiMode("full");
    fake.impl.setup = () => ({
      config: { completed: true },
      secretsSet: { keys: [] },
      hardware: null,
    });
    const r = render(<General />);
    await waitFor(() => expect(r.getByText("Interfaccia")).toBeTruthy());
    fireEvent.click(r.getByText("Semplice"));
    expect(state.uiMode.value).toBe("simple");
    expect(localStorage.getItem("rg.ui")).toBe("simple");
  });

  it("keeps the person's name: the greeting follows", async () => {
    state.simpleScreen.value = { kind: "settings" };
    const r = render(<SimpleApp />);
    expect(r.getByText("Riccardo")).toBeTruthy();
    state.personName.value = "";
    state.simpleScreen.value = { kind: "today" };
    await waitFor(() =>
      expect(r.getByRole("heading", { level: 1 }).textContent).not.toContain(","),
    );
  });
});
