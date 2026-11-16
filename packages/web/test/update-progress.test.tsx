// @vitest-environment jsdom
// An update followed in the page (3.8.1, the person: «si deve capire che sta aggiornando con eta e
// tutto»): RedGiant OS's steps with the running one lit, the images with their sizes and a real bar,
// the time left, a stop in plain words with «Try again», the restart lived through and the page
// reloading as the new version, which then says so; Windows' launcher followed the same way, and
// the steps of Docker's update with its command.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const MB = 1_000_000;
const calls: [string, unknown[]][] = [];
let answers: Record<string, unknown> = {};
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        const a = answers[name];
        if (typeof a === "function") return (a as () => Promise<unknown>)();
        if (name in answers) return Promise.resolve(a);
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  refresh: () => Promise.resolve(),
}));

const { OsUpdatesPanel } = await import("../src/components/OsSystem.js");
const { followTiming } = await import("../src/components/OsUpdateRun.js");
const { reloader, UpdatedNotice } = await import("../src/components/Updated.js");
const { LauncherProgress, Updates } = await import("../src/components/General.js");
const { updateStatus } = await import("../src/components/UpdateGate.js");
const { Dialogs } = await import("../src/components/dialogs.js");

const now = Date.now();
const iso = (s: number) => new Date(now + s * 1000).toISOString();
const base = { installed: "3.8.0", latest: "3.8.1", gate: "normal", note: null, checkedAt: null };
const run = {
  from: "3.8.0",
  startedAt: iso(-20),
  finishedAt: null,
  reason: null,
  steps: ["check", "download", "files", "install", "restart", "wait"],
  stepAt: { check: iso(-20), download: iso(-16) },
  plan: {
    images: [
      { name: "redgiant", ref: "ghcr.io/frostmoore/redgiant2:3.8.1", bytes: 412 * MB, here: false },
      {
        name: "postgres",
        ref: "ghcr.io/frostmoore/redgiant2-postgres:17",
        bytes: 96 * MB,
        here: true,
      },
    ],
    files: { name: "redgiant-os-files-3.8.1.tar.zst", bytes: 2 * MB },
  },
  progress: {
    done: 120 * MB,
    total: 300 * MB,
    bps: 8 * MB,
    eta: 23,
    items: [{ name: "redgiant", done: 120 * MB, total: 300 * MB, state: "down" }],
  },
};
const os = (update: Record<string, unknown>, running: boolean) => ({
  available: true,
  running,
  security: null,
  update: { ...base, step: null, run: null, ...update },
});
const downloading = os({ state: "applying", step: "download", run }, true);

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  answers = { setupOsUpdates: downloading };
  followTiming.every = 20;
  sessionStorage.clear();
});
afterEach(() => {
  cleanup();
  followTiming.every = 2000;
  updateStatus.value = null;
});

describe("RedGiant OS's update in the page", () => {
  it("shows the steps, what comes down with its size, a real bar and the time left", async () => {
    const r = render(<OsUpdatesPanel initial={downloading as never} />);
    const text = () => r.container.textContent ?? "";
    expect(text()).toContain("Aggiorno RedGiant dalla 3.8.0 alla 3.8.1");
    // The running step is the lit one.
    const current = r.container.querySelector('[aria-current="step"]');
    expect(current?.textContent).toContain("Scarico le immagini nuove");
    expect(current?.textContent).toContain("Il database (Postgres)");
    expect(current?.textContent).toContain("già qui");
    expect(r.container.querySelector('[role="progressbar"]')?.getAttribute("aria-valuenow")).toBe(
      "40",
    );
    expect(current?.textContent).toMatch(/MB\/s/);
    // The whole: 23 s of images, then the usual minutes of the steps after them.
    expect(text()).toContain("mancano circa 2 min");
    expect(text()).toContain("Controllo la firma della versione nuova");
    expect(text()).toContain("Riavvio RedGiant con la versione nuova");
    expect(text()).toContain("RedGiant continua a funzionare");
    // Nothing to press while it runs.
    expect(r.queryByText(/Cerca aggiornamenti/)).toBeNull();
  });

  it("follows an update already under way when the page opens", async () => {
    answers = { setupOsUpdates: downloading };
    const r = render(<OsUpdatesPanel />);
    await waitFor(() => expect(r.container.textContent).toContain("Scarico le immagini nuove"));
    expect(calls.filter(([n]) => n === "setupOsUpdates").length).toBeGreaterThan(0);
  });

  it("lives through RedGiant's restart and reloads as the new version", async () => {
    const reload = vi.fn();
    reloader.reload = reload;
    const seq = [
      () => Promise.resolve(downloading),
      () => Promise.reject(new Error("restarting")),
      () => Promise.reject(new Error("restarting")),
      () =>
        Promise.resolve(
          os(
            {
              state: "latest",
              installed: "3.8.1",
              gate: "none",
              run: { ...run, finishedAt: iso(0), progress: null },
            },
            false,
          ),
        ),
    ];
    let i = 0;
    answers = {
      setupOsUpdates: () => (seq[Math.min(i++, seq.length - 1)] as () => Promise<unknown>)(),
    };
    const r = render(<OsUpdatesPanel initial={downloading as never} />);
    await waitFor(() =>
      expect(r.container.textContent).toContain("la pagina si ricollega da sola appena risponde"),
    );
    expect(r.container.querySelector('[aria-current="step"]')?.textContent).toContain(
      "Riavvio RedGiant",
    );
    await waitFor(() =>
      expect(r.container.textContent).toContain("RedGiant 3.8.1 risponde: ricarico la pagina"),
    );
    expect(JSON.parse(sessionStorage.getItem("rg.updatedTo") ?? "{}")).toEqual({
      to: "3.8.1",
      from: "3.8.0",
    });
    await waitFor(() => expect(reload).toHaveBeenCalled(), { timeout: 3000 });
  });

  it("says why it stopped and what to do, and offers to try again", async () => {
    const stopped = os(
      {
        state: "error",
        run: {
          ...run,
          reason: "not_up",
          finishedAt: iso(0),
          progress: null,
          steps: [...run.steps, "rollback"],
          stepAt: Object.fromEntries([...run.steps, "rollback"].map((s) => [s, iso(-5)])),
        },
      },
      false,
    );
    answers = { setupOsUpdates: stopped, updateAct: {} };
    const r = render(
      <>
        <OsUpdatesPanel initial={stopped as never} />
        <Dialogs />
      </>,
    );
    expect(r.container.textContent).toContain("La versione nuova non è partita.");
    expect(r.container.textContent).toContain("RedGiant è tornato da solo alla 3.8.0");
    expect(r.container.querySelector(".st-run-step.failed")?.textContent).toContain(
      "Controllo che RedGiant risponda",
    );
    fireEvent.click(r.getByText("Riprova"));
    await waitFor(() => r.getByText("Aggiornare RedGiant alla 3.8.1?"));
    fireEvent.click(r.getByText("Aggiorna ora"));
    await waitFor(() => expect(calls.find(([n]) => n === "updateAct")?.[1]).toEqual(["update"]));
    // The steps show at once, before the machine writes its first state.
    await waitFor(() =>
      expect(r.container.querySelector('[aria-current="step"]')?.textContent).toContain(
        "Controllo la firma",
      ),
    );
  });

  it("tells the reloaded page it is the new version, with the version's notes", () => {
    // A version that brought no items of its own (independent of what's new in this release).
    sessionStorage.setItem("rg.updatedTo", JSON.stringify({ to: "99.0.1", from: "99.0.0" }));
    const r = render(<UpdatedNotice />);
    expect(r.getByText("RedGiant è aggiornato")).toBeTruthy();
    expect(r.container.ownerDocument.body.textContent).toContain(
      "Ora è la 99.0.1 (prima era la 99.0.0)",
    );
    const notes = r.getByText(/Le note della versione su GitHub/).closest("a");
    expect(notes?.getAttribute("href")).toMatch(/releases\/tag\/v99\.0\.1$/);
    fireEvent.click(r.getByText("Ok"));
    expect(sessionStorage.getItem("rg.updatedTo")).toBeNull();
    expect(r.queryByText("RedGiant è aggiornato")).toBeNull();
  });
});

describe("the other installations", () => {
  const status = {
    installed: "3.8.0",
    firstVersion: "3.7.0",
    latest: "3.8.1",
    checkedAt: null,
    state: "available",
    gate: "normal",
    signed: true,
    note: null,
    downloadUrl: null,
    command: "cd ~/redgiant && docker compose pull && docker compose up -d",
    backupDir: null,
    canUpdateHere: false,
    canUninstall: false,
  };

  it("Windows: the launcher's own bar, speed and time left, step by step", () => {
    const r = render(
      <LauncherProgress
        p={{
          version: "3.8.1",
          phase: "download",
          done: 30 * MB,
          total: 120 * MB,
          bps: 6 * MB,
          eta: 15,
          at: new Date().toISOString(),
        }}
      />,
    );
    expect(r.container.textContent).toContain("Aggiorno RedGiant alla 3.8.1");
    expect(r.container.querySelector(".st-run-step.done")?.textContent).toContain(
      "Cerco cosa è cambiato",
    );
    const current = r.container.querySelector('[aria-current="step"]');
    expect(current?.textContent).toContain("Scarico solo i file cambiati");
    expect(current?.textContent).toContain("25%");
    expect(r.container.textContent).toContain("La pagina si ricollega da sola");
  });

  it("Windows: «Update now» here, then the page follows it", async () => {
    updateStatus.value = { ...status, install: "windows", canUpdateHere: true } as never;
    answers = { updateAct: {}, updateStatus: { ...status, install: "windows" } };
    const r = render(<Updates />);
    expect(r.container.textContent).toContain("RedGiant scarica solo i file cambiati");
    fireEvent.click(r.getByText("Aggiorna alla 3.8.1"));
    await waitFor(() => expect(calls.find(([n]) => n === "updateAct")?.[1]).toEqual(["update"]));
    expect(r.queryByText("Aggiorna alla 3.8.1")).toBeNull();
  });

  it("Docker: the steps and the command to copy", () => {
    updateStatus.value = { ...status, install: "docker" } as never;
    const r = render(<Updates />);
    expect(r.container.textContent).toContain("Lancia il comando");
    expect(r.container.textContent).toContain("Docker mostra ogni immagine mentre scende");
    expect(r.container.querySelector("code")?.textContent).toBe(status.command);
    expect(r.queryByText("Aggiorna alla 3.8.1")).toBeNull();
  });
});
