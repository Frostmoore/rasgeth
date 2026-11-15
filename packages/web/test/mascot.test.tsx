// @vitest-environment jsdom
// The mascots in the page (G40.2): every agent shows its face (the server's spec, or made from
// its seed), its live state from what the page already knows, named for screen readers in both
// languages; in the bar, the tabs, the tree and over the chat; «Change mascot» asks first; the
// CSS has both themes and no animation with reduced motion.
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { mascotSpec } from "@redgiant/mascot";
import { cleanup, fireEvent, render, screen } from "@testing-library/preact";
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const { api } = vi.hoisted(() => ({
  api: {} as Record<string, ReturnType<typeof vi.fn>>,
}));
vi.mock("../src/api.js", async (orig) => {
  const real = await orig<typeof import("../src/api.js")>();
  class Api {
    constructor() {
      // biome-ignore lint/correctness/noConstructorReturn: a stand-in for the whole API
      return new Proxy(
        {},
        { get: (_t, name) => (api as Record<string, unknown>)[name as string] ?? (async () => []) },
      );
    }
  }
  class Live {
    send() {}
    close() {}
  }
  return { ...real, Api, Live };
});

const state = await import("../src/state.js");
const { agentMascotState } = await import("../src/mascot-state.js");
const { Mascot } = await import("../src/components/Mascot.js");
const { Sidebar } = await import("../src/components/Sidebar.js");
const { Chat } = await import("../src/components/Chat.js");
const { AgentPanel } = await import("../src/components/Hierarchy.js");
const { Dialogs } = await import("../src/components/dialogs.js");
const { agents, approvals, projects, sessionRows, sessionView, questions } = state;
beforeAll(async () => {
  await state.signIn("token").catch(() => {});
});

const orchSpec = mascotSpec("Coder Web", "orchestrator");
const team = () =>
  [
    { id: "god", name: "God", kind: "god", parentId: null, projectId: null, status: "active" },
    {
      id: "orch",
      name: "Front-end",
      kind: "orchestrator",
      parentId: "god",
      projectId: "demo",
      status: "active",
      mascotSeed: "Coder Web",
      mascot: orchSpec,
    },
    {
      id: "asst",
      name: "Agenda",
      kind: "assistant",
      parentId: "god",
      projectId: null,
      status: "active",
      mascotSeed: "Agenda",
    },
  ] as never;
const row = (id: string, agentId: string, extra: Record<string, unknown> = {}) => ({
  id,
  agentId,
  projectId: "demo",
  createdAt: "2026-11-15T08:00:00.000Z",
  lastAt: "2026-11-15T09:00:00.000Z",
  title: `Title ${id}`,
  pinned: false,
  archived: false,
  running: false,
  ...extra,
});

beforeEach(() => {
  lang.value = "it";
  localStorage.setItem("rg.remoteNotice", "hidden");
  localStorage.setItem("rg.barSection", "agents");
  projects.value = [{ id: "demo", name: "Demo" }] as never;
  agents.value = team();
  sessionRows.value = [];
  approvals.value = [];
  questions.value = [];
  Element.prototype.scrollIntoView = vi.fn();
});
afterEach(() => cleanup());

describe("the live state", () => {
  it("waits for the person, thinks, works, is blocked or idle, from what the page knows", () => {
    expect(agentMascotState("orch")).toBe("idle");
    sessionRows.value = [row("s1", "orch", { running: true })];
    // Not followed: at work.
    expect(agentMascotState("orch")).toBe("work");
    // Followed, the model has not written yet: thinking.
    sessionView("s1").value = {
      ...sessionView("s1").value,
      state: "running",
      call: { since: 1, chars: 0 },
    };
    expect(agentMascotState("orch")).toBe("think");
    sessionView("s1").value = {
      ...sessionView("s1").value,
      call: { since: 1, chars: 5, firstToken: 2, writing: "text" },
    };
    expect(agentMascotState("orch")).toBe("work");
    approvals.value = [{ requestId: "r1", agentId: "orch" }] as never;
    expect(agentMascotState("orch")).toBe("wait");
    approvals.value = [];
    sessionRows.value = [row("s1", "orch")];
    sessionView("s1").value = {
      ...sessionView("s1").value,
      state: "idle",
      call: undefined,
      events: [{ seq: 9, type: "budget.exceeded", payload: {} }] as never,
    };
    expect(agentMascotState("orch")).toBe("error");
  });
});

describe("awake after answering (active)", () => {
  const at = (iso: string) => Date.parse(iso);
  const replied = "2026-11-15T10:00:00.000Z";
  // [what the rows say, seconds after the answer, the state]
  const table: [string, Record<string, unknown>, number, string][] = [
    ["just answered the person", { repliedAt: replied }, 1, "active"],
    ["a minute and a half later", { repliedAt: replied }, 90, "active"],
    ["two minutes later: asleep again", { repliedAt: replied }, 121, "idle"],
    ["never answered", {}, 1, "idle"],
    ["answering again: running wins", { repliedAt: replied, running: true }, 1, "work"],
  ];
  it.each(table)("%s", (_name, extra, seconds, want) => {
    sessionRows.value = [row("s9", "orch", extra)];
    expect(agentMascotState("orch", at(replied) + seconds * 1000)).toBe(want);
  });

  it("a request for the person comes first, and only the person's own conversations count", () => {
    sessionRows.value = [row("s9", "orch", { repliedAt: replied })];
    approvals.value = [{ requestId: "r1", agentId: "orch" }] as never;
    expect(agentMascotState("orch", at(replied) + 1000)).toBe("wait");
    approvals.value = [];
    expect(agentMascotState("asst", at(replied) + 1000)).toBe("idle");
  });

  it("learns of the answer from the live connection, and falls asleep by itself", async () => {
    vi.useFakeTimers();
    try {
      const early = "2026-11-15T07:00:00.000Z";
      const { mascotNow } = await import("../src/mascot-state.js");
      vi.setSystemTime(at(early));
      mascotNow.value = Date.now();
      sessionRows.value = [row("s9", "orch", { running: true })];
      state.applyMessage({
        type: "session.activity",
        sessionId: "s9",
        agentId: "orch",
        state: "idle",
        repliedAt: early,
      } as never);
      expect(sessionRows.value[0]?.repliedAt).toBe(early);
      expect(agentMascotState("orch")).toBe("active");
      vi.advanceTimersByTime(121_000);
      expect(agentMascotState("orch")).toBe("idle");
    } finally {
      vi.useRealTimers();
    }
  });
});

describe("the face", () => {
  it("draws the server's spec, named with its state in both languages", () => {
    const { container } = render(<Mascot agent={agents.value[1] as never} size={32} />);
    const svg = container.querySelector("svg.masc") as SVGElement;
    expect(svg.getAttribute("aria-label")).toBe("Mascotte di Front-end, fermo");
    expect(svg.getAttribute("style")).toContain(`--h:${orchSpec.hue}`);
    expect(container.querySelector(".hs")).toBeTruthy();
    cleanup();
    lang.value = "en";
    approvals.value = [{ requestId: "r1", agentId: "orch" }] as never;
    const again = render(<Mascot agent={agents.value[1] as never} size={32} />);
    expect(again.container.querySelector("svg")?.getAttribute("aria-label")).toBe(
      "Mascot of Front-end, waiting for you",
    );
    expect(again.container.querySelector("svg.st-wait .mk.wait")).toBeTruthy();
  });

  it("makes the face from the seed when the server sent none, the same as the server's", () => {
    const { container } = render(<Mascot agent={agents.value[2] as never} size={48} />);
    const spec = mascotSpec("Agenda", "assistant");
    expect(container.querySelector("svg")?.getAttribute("style")).toContain(`--h:${spec.hue}`);
  });
});

describe("where the faces are", () => {
  it("in the bar: God, the personal agents and the projects' orchestrators", () => {
    render(<Sidebar />);
    expect(screen.getByRole("img", { name: "Mascotte di God, fermo" })).toBeTruthy();
    expect(screen.getByRole("img", { name: "Mascotte di Agenda, fermo" })).toBeTruthy();
  });

  it("over the chat: the face and the state in words", () => {
    sessionRows.value = [row("s2", "orch", { running: true })];
    const { container } = render(<Chat sessionId="s2" agentId="orch" />);
    const head = container.querySelector(".chat-agent") as HTMLElement;
    expect(head.textContent).toContain("Front-end");
    expect(head.textContent).toContain("lavora");
    expect(head.querySelector("svg.masc.st-work")).toBeTruthy();
  });

  it("«Change mascot» asks first, then asks the server for a new face", async () => {
    api.changeMascot = vi.fn(async () => ({ ...agents.value[1], mascotSeed: "x" }));
    render(
      <>
        <AgentPanel agent={agents.value[1] as never} onClose={() => {}} onAdd={() => {}} />
        <Dialogs />
      </>,
    );
    fireEvent.click(screen.getByRole("button", { name: "Cambia mascotte" }));
    expect(api.changeMascot).not.toHaveBeenCalled();
    await screen.findByText(/Dare a Front-end una faccia nuova/);
    const buttons = screen.getAllByRole("button", { name: "Cambia mascotte" });
    fireEvent.click(buttons.at(-1) as HTMLElement);
    await vi.waitFor(() => expect(api.changeMascot).toHaveBeenCalledWith("orch"));
  });

  it("never offers to change God's, drawn by hand", () => {
    render(<AgentPanel agent={agents.value[0] as never} onClose={() => {}} onAdd={() => {}} />);
    expect(screen.queryByText("Cambia mascotte")).toBe(null);
    expect(screen.getByText(/disegnata a mano/)).toBeTruthy();
  });
});

describe("the styles", () => {
  const css = readFileSync(join(import.meta.dirname, "..", "src", "styles.css"), "utf8");
  it("gives the mascots' lightness in the light, dark and system themes", () => {
    expect(css.match(/--mL: 0\.62;/g)).toHaveLength(1);
    expect(css.match(/--mL: 0\.74;/g)).toHaveLength(2);
  });
  it("keeps the mascots moving with the library's motion, once, paused while the page is hidden", () => {
    render(<Mascot agent={agents.value[1] as never} size={64} state="idle" />);
    render(<Mascot agent={agents.value[2] as never} size={64} state="work" />);
    const styles = document.querySelectorAll("style#rg-mascot-motion");
    expect(styles).toHaveLength(1);
    expect(styles[0]?.textContent).toContain(".masc.st-idle:not(.tiny) .core{animation:");
    // Each mascot carries its own rhythm, so neighbours do not move together.
    const svgs = [...document.querySelectorAll("svg.masc")].map((s) => s.getAttribute("style"));
    expect(svgs[0]).toMatch(/--k0:/);
    expect(new Set(svgs).size).toBe(svgs.length);
    Object.defineProperty(document, "hidden", { configurable: true, get: () => true });
    document.dispatchEvent(new Event("visibilitychange"));
    expect(document.documentElement.classList.contains("rg-hidden")).toBe(true);
    Object.defineProperty(document, "hidden", { configurable: true, get: () => false });
    document.dispatchEvent(new Event("visibilitychange"));
    expect(document.documentElement.classList.contains("rg-hidden")).toBe(false);
    expect(css).toMatch(/\.rg-hidden \.masc \* \{\s*animation-play-state: paused !important;/);
  });
  it("stops every animation with reduced motion, keeping the sign", () => {
    expect(css).toMatch(
      /@media \(prefers-reduced-motion: reduce\) \{\s*\.masc,\s*\.masc \* \{\s*animation: none !important;/,
    );
  });
});
