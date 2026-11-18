// @vitest-environment jsdom
// A project's agent limit (2026-11-18): in Settings › Projects (and above the project's team) our
// slider in steps, 0 to 10, default 3, saved a moment after the last step; the line under it says
// how many count now, and when the team is over the limit that nobody is removed. The server's
// refusal reaches the person in their words (`err_agent_limit`).
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { ApiError } from "../src/api.js";
import { explain } from "../src/explain.js";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  refreshProjects: () => Promise.resolve(),
}));

const { ProjectsPage } = await import("../src/components/ProjectArchive.js");
const { AgentLimitControl, SAVE_AFTER_MS } = await import("../src/components/ProjectAgentLimit.js");
const { projects } = await import("../src/state.js");

const base = { path: "/w/shop", createdAt: "2026-11-18T00:00:00Z", git: true };

beforeEach(() => {
  calls.length = 0;
  lang.value = "it";
});
afterEach(() => {
  cleanup();
  vi.useRealTimers();
});

const slider = (r: ReturnType<typeof render>) =>
  r.getByLabelText("Agenti al massimo in questo progetto") as HTMLInputElement;

describe("a project's agent limit on the page (2026-11-18)", () => {
  it("Settings › Projects: one slider per project, 0 to 10, with the default and the count", () => {
    projects.value = [
      { ...base, id: "shop", name: "Shop", agents: 2 },
      { ...base, id: "blog", name: "Blog", maxAgents: 0, agents: 0 },
    ];
    const r = render(<ProjectsPage />);
    const all = r.getAllByLabelText("Agenti al massimo in questo progetto") as HTMLInputElement[];
    expect(all).toHaveLength(2);
    expect(all.map((s) => [s.type, s.min, s.max, s.step, s.value])).toEqual([
      ["range", "0", "10", "1", "3"],
      ["range", "0", "10", "1", "0"],
    ]);
    expect(r.container.textContent).toContain("Ora: 2 agenti.");
    expect(r.container.textContent).toContain("Ora: nessuno.");
    // 0 is said in words: the orchestrator alone.
    expect(r.container.textContent).toContain("Solo orchestratore");
    // Never a native checkbox, radio or number field.
    expect(r.container.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
    expect(r.container.querySelector('input[type="number"]')).toBeNull();
  });

  it("saves once, a moment after the last step", async () => {
    vi.useFakeTimers();
    const r = render(<AgentLimitControl project={{ ...base, id: "shop", name: "Shop" }} />);
    for (const v of ["4", "5", "6"]) fireEvent.input(slider(r), { target: { value: v } });
    expect(calls).toEqual([]);
    vi.advanceTimersByTime(SAVE_AFTER_MS + 10);
    expect(calls).toEqual([["setProjectMaxAgents", ["shop", 6]]]);
    vi.useRealTimers();
    await waitFor(() => expect(r.container.textContent).toContain("Salvato."));
  });

  it("back to where it was: nothing to save", () => {
    vi.useFakeTimers();
    const r = render(<AgentLimitControl project={{ ...base, id: "shop", name: "Shop" }} />);
    fireEvent.input(slider(r), { target: { value: "5" } });
    fireEvent.input(slider(r), { target: { value: "3" } });
    vi.advanceTimersByTime(SAVE_AFTER_MS * 2);
    expect(calls).toEqual([]);
  });

  it("over the limit: nobody is removed, says the line", () => {
    const r = render(
      <AgentLimitControl
        project={{ ...base, id: "shop", name: "Shop", maxAgents: 1, agents: 3 }}
      />,
    );
    expect(r.container.querySelector(".pal-over")?.textContent).toBe(
      "Ne ha 3 agenti, più di 1: nessuno viene rimosso, ma non se ne creano di nuovi finché la squadra non scende sotto il limite.",
    );
  });

  it("the server's refusal, in the person's words (it and en)", () => {
    const err = new ApiError(409, "The project ...", "agent_limit", {
      project: "Shop",
      max: "3",
      count: "3",
    });
    expect(explain(err)).toBe(
      "Il progetto «Shop» può avere al massimo 3 agenti oltre all'orchestratore: ne ha 3. Alza il limite in Impostazioni › Progetti o rimuovine uno.",
    );
    lang.value = "en";
    expect(explain(err)).toBe(
      "The project «Shop» can have at most 3 agents besides its orchestrator: it has 3. Raise the limit in Settings › Projects or remove one.",
    );
  });
});
