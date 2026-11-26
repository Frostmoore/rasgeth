// @vitest-environment jsdom
// Whole projects from Claude Code in the import window (alpha 4.0): the scan asks for them, a project
// shows what it would bring and how it can come, and the choice goes with the import.
import type { ImportPreview } from "@redgiant/protocol";
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: { scan?: unknown; apply?: unknown } = {};
const preview: ImportPreview = {
  id: "pv_1",
  read: 1,
  unreadable: [],
  left: [],
  items: [
    {
      id: "i1",
      kind: "project",
      source: "claude-code",
      from: "/home/ana/code/site",
      name: "site",
      preview: "# Site",
      on: true,
      notes: [
        { code: "secrets-out", arg: "1" },
        { code: "machine-lines", arg: "1" },
      ],
      project: {
        path: "/home/ana/code/site",
        remote: "https://git.home.lan/ana/site.git",
        git: true,
        instructions: ["CLAUDE.md"],
        notes: 3,
        memory: 2,
        conversations: 4,
        secrets: [".env"],
        machine: [{ file: "CLAUDE.md", line: 2, text: "Deploy with `ssh web1`.", why: "ssh" }],
        bytes: 5_000_000,
        modes: ["adopt", "copy", "clone"],
      },
    },
  ],
};

vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () =>
    new Proxy(
      {},
      {
        get: (_t, name) => {
          if (name === "importScan")
            return (p: unknown) => {
              calls.scan = p;
              return Promise.resolve(preview);
            };
          if (name === "importApply")
            return (b: unknown) => {
              calls.apply = b;
              return Promise.resolve({
                id: "job_1",
                kind: "import_apply",
                state: "running",
                steps: [],
              });
            };
          return () => Promise.resolve([]);
        },
      },
    ),
}));

const { ImportFrom } = await import("../src/components/ImportFrom.js");

beforeEach(() => {
  lang.value = "it";
});
afterEach(() => cleanup());

describe("whole projects in the import window", () => {
  it("scans for Claude Code's projects, shows one and sends the chosen way", async () => {
    const { getByText, findByText, container } = render(<ImportFrom />);
    fireEvent.click(getByText("Cerca sul mio computer"));
    // The scan window's «Cerca» (the button in its foot).
    const go = await waitFor(() => {
      const b = [...document.querySelectorAll("button")].find(
        (x) => x.textContent?.trim() === "Cerca",
      );
      if (!b) throw new Error("no Cerca button");
      return b;
    });
    fireEvent.click(go);
    await waitFor(() => expect(calls.scan).toMatchObject({ claudeProjects: true }));
    await findByText("site");
    expect(container.textContent).toContain("Repository: https://git.home.lan/ana/site.git");
    expect(container.textContent).toContain("Restano fuori (segreti): .env");
    expect(container.textContent).toContain("1 righe legate a questo computer");
    // The way it comes: «Clone its repository», then import.
    fireEvent.click(getByText("Clona il repository"));
    fireEvent.click(getByText("Importa 1", { exact: false }));
    await waitFor(() =>
      expect(calls.apply).toMatchObject({
        id: "pv_1",
        choices: [{ id: "i1", on: true, mode: "clone" }],
      }),
    );
  });
});
