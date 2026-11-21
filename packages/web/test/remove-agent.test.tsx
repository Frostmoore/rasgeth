// @vitest-environment jsdom
// Removing an agent (p3.8.9): «Remove» in the agent's window, never for God, Demi-God or the Chat;
// our window says who goes with it, the turns that stop and the tasks that close; «Removed agents»
// with «Restore» and their conversations; the line that takes the composer's place.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
let restoreFails = false;
let resumeFails = false;
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "removePreview")
          return Promise.resolve(
            args[0] === "c"
              ? {
                  agent: { id: "c", name: "Chat", kind: "assistant" },
                  with: [],
                  tasks: 0,
                  running: 0,
                  allowed: false,
                }
              : {
                  agent: { id: "o1", name: "Shop lead", kind: "orchestrator" },
                  with: [
                    { id: "a1", name: "Coder", kind: "agent" },
                    { id: "a2", name: "Tester", kind: "agent" },
                  ],
                  tasks: 2,
                  running: 1,
                  allowed: true,
                },
          );
        if (name === "removeAgent") return Promise.resolve({ removed: ["o1", "a1", "a2"] });
        if (name === "stopAgent") return Promise.resolve({ stopped: ["o1"], waiting: 2 });
        if (name === "resumeAgent")
          return resumeFails
            ? Promise.reject(new Error("The project has another orchestrator now"))
            : Promise.resolve({ resumed: ["o1"], tasks: ["t1", "t2"] });
        if (name === "restoreAgent")
          return restoreFails
            ? Promise.reject(new Error("The project already has an orchestrator"))
            : Promise.resolve({ restored: ["o1"] });
        if (name === "sessions")
          return Promise.resolve(
            args[0] === "o1"
              ? [{ id: "s1", agentId: "o1", projectId: "shop", title: "Schede prodotto" }]
              : [],
          );
        if (name === "models") return Promise.resolve([]);
        if (name === "agentPrompt") return Promise.resolve({ text: "", custom: false });
        return Promise.resolve({});
      };
    },
  },
);
const refreshTeam = vi.fn(() => Promise.resolve());
const opened: unknown[] = [];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  refresh: () => Promise.resolve(),
  refreshTeam: () => refreshTeam(),
  openSession: (row: unknown) => opened.push(row),
}));

const { Hierarchy } = await import("../src/components/Hierarchy.js");
const { RemoveAgentDialog, RemovedAgentsList, RemovedNotice, StoppedNotice } = await import(
  "../src/components/RemovedAgents.js"
);
const { Dialogs } = await import("../src/components/dialogs.js");
const { t } = await import("../src/i18n.js");
const { agents, chatAgentId, removedAgents } = await import("../src/state.js");

const god = {
  id: "g",
  kind: "god",
  name: "God",
  parentId: null,
  projectId: null,
  status: "active",
};
const demigod = { ...god, id: "d", kind: "demigod", name: "Demi-God", parentId: "g" };
const chat = { ...god, id: "c", kind: "assistant", name: "Chat", parentId: "g" };
const lead = {
  ...god,
  id: "o1",
  kind: "orchestrator",
  name: "Shop lead",
  parentId: "g",
  projectId: "shop",
};
const removed = {
  ...lead,
  status: "removed",
  removed: {
    at: "2026-11-17T10:30:00Z",
    by: "God",
    reason: "the shop is closed",
    with: [{ id: "a1", name: "Coder", kind: "agent" }],
    sessions: 1,
  },
};

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  opened.length = 0;
  restoreFails = false;
  resumeFails = false;
  refreshTeam.mockClear();
  agents.value = [god, demigod, chat, lead] as never;
  chatAgentId.value = "c";
  removedAgents.value = [];
});
afterEach(cleanup);

const footOf = (r: ReturnType<typeof render>, name: string) => {
  fireEvent.click(r.getAllByText(name)[0] as HTMLElement);
  const foot = r.container.querySelector(".agent-panel-modal .ui-modal-foot") as HTMLElement;
  return foot.textContent ?? "";
};

describe("removing an agent (p3.8.9)", () => {
  it("offers «Rimuovi» for an orchestrator, never for God, Demi-God or the Chat", () => {
    const r = render(<Hierarchy />);
    expect(footOf(r, "Shop lead")).toContain("Rimuovi");
    for (const name of ["God", "Demi-God", "Chat"]) {
      cleanup();
      const again = render(<Hierarchy />);
      fireEvent.click(again.getAllByText(name)[0] as HTMLElement);
      const foot = again.container.querySelector(".agent-panel-modal .ui-modal-foot");
      expect(foot?.textContent ?? "", name).not.toContain("Rimuovi");
    }
  });

  it("offers it for a stopped agent too", () => {
    agents.value = [god, { ...lead, status: "stopped" }] as never;
    const r = render(<Hierarchy />);
    fireEvent.click(r.getByLabelText("Anche quelli fermati"));
    expect(footOf(r, "Shop lead")).toContain("Rimuovi");
  });

  it("says who goes with it, the turns and the tasks, then removes in our window", async () => {
    const confirm = vi.spyOn(window, "confirm");
    const r = render(<Hierarchy />);
    footOf(r, "Shop lead");
    fireEvent.click(
      r.getByText("Rimuovi", { selector: ".agent-panel-modal .ui-modal-foot button" }),
    );
    await waitFor(() => expect(r.getByText("Rimuovere Shop lead dalla squadra?")).toBeTruthy());
    await waitFor(() =>
      expect(r.getByText("Rimossi insieme, perché lavorano sotto di lui:")).toBeTruthy(),
    );
    expect(r.getByText(/Coder/)).toBeTruthy();
    expect(r.getByText(/Tester/)).toBeTruthy();
    expect(r.getByText("Il suo turno in corso si ferma subito.")).toBeTruthy();
    expect(r.getByText("2 compiti aperti si chiudono, come «agente rimosso».")).toBeTruthy();
    expect(
      r.getByText("«Ripristina» lo riporta indietro, con quelli rimossi insieme a lui."),
    ).toBeTruthy();
    // The remove window is a window of its own, on top of the agent's.
    const windows = [...r.container.querySelectorAll(".ui-modal")];
    expect(windows.at(-1)?.getAttribute("aria-label")).toBe("Rimuovere Shop lead dalla squadra?");
    fireEvent.click(r.getByText(/Rimuovi 3 agenti/));
    await waitFor(() => expect(calls.some((c) => c[0] === "removeAgent")).toBe(true));
    expect(calls.find((c) => c[0] === "removeAgent")?.[1][0]).toBe("o1");
    await waitFor(() => expect(r.container.querySelector(".ui-modal")).toBeNull());
    expect(refreshTeam).toHaveBeenCalled();
    expect(confirm).not.toHaveBeenCalled();
  });

  it("refuses in words when the server says it may not", async () => {
    const r = render(<RemoveAgentDialog agent={chat as never} onClose={() => {}} />);
    await waitFor(() =>
      expect(
        r.getByText("Chat non si può rimuovere: God, Demi-God e la Chat fanno parte di Rasgeth."),
      ).toBeTruthy(),
    );
    expect(r.queryByText("Rimuovi", { selector: "button" })).toBeNull();
  });
});

describe("removed agents (p3.8.9)", () => {
  it("lists each removal with when, by whom, why and with whom; «Ripristina» restores", async () => {
    removedAgents.value = [removed] as never;
    const r = render(<RemovedAgentsList />);
    expect(r.getByText("Shop lead")).toBeTruthy();
    expect(r.getByText(/da God/)).toBeTruthy();
    expect(r.getByText("Motivo: the shop is closed")).toBeTruthy();
    expect(r.getByText("Con: Coder")).toBeTruthy();
    fireEvent.click(r.getByText("Ripristina"));
    await waitFor(() => expect(calls.some((c) => c[0] === "restoreAgent")).toBe(true));
    expect(calls.find((c) => c[0] === "restoreAgent")?.[1][0]).toBe("o1");
    await waitFor(() => expect(refreshTeam).toHaveBeenCalled());
  });

  it("says what work not merged a removal left, and how to get it back (3.10.2)", () => {
    removedAgents.value = [
      {
        ...removed,
        removed: {
          ...removed.removed,
          kept: [{ id: "a1", name: "Coder", branch: "rg/a1", commits: 2, changes: 3 }],
        },
      },
    ] as never;
    const r = render(<RemovedAgentsList />);
    expect(r.getByText("Coder · Lavoro non unito: 2 commit, 3 file modificati")).toBeTruthy();
    expect(r.getByText("Resta nel ramo rg/a1: ripristina l'agente per riprenderlo.")).toBeTruthy();
    r.unmount();
    lang.value = "en";
    const e = render(<RemovedAgentsList />);
    expect(e.getByText("Coder · Work not merged: 2 commit(s), 3 changed file(s)")).toBeTruthy();
  });

  it("shows why a restore fails", async () => {
    restoreFails = true;
    removedAgents.value = [removed] as never;
    const r = render(<RemovedAgentsList />);
    fireEvent.click(r.getByText("Ripristina"));
    await waitFor(() => expect(r.container.querySelector(".notice.error")).not.toBeNull());
  });

  it("opens its conversations, read only", async () => {
    removedAgents.value = [removed] as never;
    const r = render(<RemovedAgentsList />);
    fireEvent.click(r.getByText("Conversazioni (1)"));
    await waitFor(() => expect(r.getByText("Schede prodotto")).toBeTruthy());
    // Those removed with it are asked too.
    expect(calls.filter((c) => c[0] === "sessions").map((c) => c[1][0])).toEqual(["o1", "a1"]);
    fireEvent.click(r.getByText("Schede prodotto"));
    expect(opened).toEqual([{ id: "s1", agentId: "o1", title: "Schede prodotto" }]);
  });

  it("filters by project on a project's page, and says when there are none", () => {
    removedAgents.value = [removed] as never;
    const r = render(<RemovedAgentsList projectId="other" />);
    expect(r.getByText("Nessun agente rimosso.")).toBeTruthy();
  });

  it("puts a line with «Ripristina» where the composer was, also for one removed with it", async () => {
    removedAgents.value = [removed] as never;
    const r = render(<RemovedNotice agentId="a1" />);
    expect(
      r.getByText("Coder è stato rimosso dalla squadra: ripristinalo per scrivergli."),
    ).toBeTruthy();
    fireEvent.click(r.getByText("Ripristina"));
    await waitFor(() => expect(calls.some((c) => c[0] === "restoreAgent")).toBe(true));
    // The removal's own agent is restored, with those removed with it.
    expect(calls.find((c) => c[0] === "restoreAgent")?.[1][0]).toBe("o1");
    cleanup();
    removedAgents.value = [];
    expect(render(<RemovedNotice agentId="a1" />).container.textContent).toBe("");
  });
});

// Stopping is a pause (p3.8.9, the GAIA collaudo: a paused team could not come back): «Riattiva»
// in the agent's window and in its conversation; «Ferma» says it is a pause, «Rimuovi» another thing.
describe("stopping is a pause, «Riattiva» brings it back (p3.8.9)", () => {
  const stopped = { ...lead, status: "stopped" };

  it("a stopped agent's window says it is paused and offers «Riattiva» besides «Rimuovi»", async () => {
    agents.value = [god, stopped] as never;
    const r = render(<Hierarchy />);
    fireEvent.click(r.getByLabelText("Anche quelli fermati"));
    const foot = footOf(r, "Shop lead");
    expect(foot).toContain("Riattiva");
    expect(foot).toContain("Rimuovi");
    expect(foot).not.toContain("Ferma");
    expect(
      r.getByText("In pausa: i suoi compiti aperti aspettano. «Riattiva» lo riporta al lavoro."),
    ).toBeTruthy();
    fireEvent.click(r.getByText("Riattiva"));
    await waitFor(() =>
      expect(
        r.getByText(
          "Shop lead è di nuovo al lavoro: 2 compiti aperti ripartono da dove si erano fermati.",
        ),
      ).toBeTruthy(),
    );
    expect(calls.find((c) => c[0] === "resumeAgent")?.[1]).toEqual(["o1"]);
    expect(refreshTeam).toHaveBeenCalled();
  });

  it("says why it cannot come back", async () => {
    resumeFails = true;
    agents.value = [god, stopped] as never;
    const r = render(<Hierarchy />);
    fireEvent.click(r.getByLabelText("Anche quelli fermati"));
    footOf(r, "Shop lead");
    fireEvent.click(r.getByText("Riattiva"));
    await waitFor(() =>
      expect(r.getByText("The project has another orchestrator now")).toBeTruthy(),
    );
  });

  it("«Ferma» asks in our window that it is a pause, and says the tasks wait", async () => {
    const r = render(
      <>
        <Hierarchy />
        <Dialogs />
      </>,
    );
    footOf(r, "Shop lead");
    fireEvent.click(r.getByText("Ferma"));
    await waitFor(() => expect(r.getByText("Fermare Shop lead?")).toBeTruthy());
    const ask = r.getByText(/È una pausa: i suoi turni si fermano ora/);
    expect(ask.textContent).toContain("«Riattiva» lo riporta al lavoro");
    expect(ask.textContent).toContain("«Rimuovi»");
    fireEvent.click(r.getByText("Ferma (pausa)"));
    await waitFor(() =>
      expect(
        r.getByText("Shop lead è fermato (in pausa): 2 compiti aperti aspettano «Riattiva»."),
      ).toBeTruthy(),
    );
    expect(calls.some((c) => c[0] === "stopAgent")).toBe(true);
  });

  it("puts a line with «Riattiva» where the composer was, only while it is stopped", async () => {
    agents.value = [god, stopped] as never;
    const r = render(<StoppedNotice agentId="o1" />);
    expect(r.getByText("Shop lead è fermato (in pausa): riattivalo per riprendere.")).toBeTruthy();
    fireEvent.click(r.getByText("Riattiva"));
    await waitFor(() => expect(calls.some((c) => c[0] === "resumeAgent")).toBe(true));
    cleanup();
    agents.value = [god, lead] as never;
    expect(render(<StoppedNotice agentId="o1" />).container.textContent).toBe("");
  });

  it("names the tools apart: stop is a pause, remove takes it out of the team", () => {
    expect(t("toolDo_stop_agent")).toBe("Mette in pausa un agente sotto di sé; si riattiva.");
    expect(t("toolDo_resume_agent")).toContain("ripartono");
    expect(t("toolDo_remove_agent")).toContain("squadra");
    lang.value = "en";
    expect(t("toolDo_stop_agent")).toBe("Pauses an agent under it; it can be resumed.");
    expect(t("tool_resume_agent")).toBe("Resume agents");
    expect(t("agentStopAsk", { name: "X" })).toBe("Stop X?");
  });
});
