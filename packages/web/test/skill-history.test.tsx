// @vitest-environment jsdom
// 3.9.7: skills that improve with use. An installed skill shows its versions (who, why, when, the
// one in use); an earlier one is compared with the one in use and brought back after the person
// confirms in our dialog; a proposed new version shows what changes, word by word.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Proposal, SkillVersion } from "../src/api.js";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const version = (o: Partial<SkillVersion>): SkillVersion => ({
  name: "invoice-pdf",
  scope: "platform",
  version: 1,
  how: "install",
  author: "agent_x",
  approvedBy: "human",
  reason: null,
  fromVersion: null,
  proposalId: null,
  createdAt: "2026-11-19T10:00:00Z",
  files: [],
  restorable: true,
  current: false,
  ...o,
});
let versions: SkillVersion[] = [];
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "skillVersions") return Promise.resolve(versions);
        if (name === "skillVersion")
          return Promise.resolve({
            name: "invoice-pdf",
            version: args[2],
            skillMd:
              args[2] === 1 ? "The total is on the last page." : "The VAT is above the total.",
          });
        if (name === "rollbackSkill")
          return Promise.resolve({ name: "invoice-pdf", version: 3, fromVersion: args[2] });
        if (["proposals", "installed", "mcpServers", "mcpStatus", "magicExts"].includes(name))
          return Promise.resolve([]);
        return Promise.resolve({});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { SkillHistory } = await import("../src/components/Extensions.js");
const { asking } = await import("../src/components/dialogs.js");

beforeEach(() => {
  lang.value = "it";
  calls.length = 0;
  asking.value = [];
  versions = [
    version({
      version: 2,
      how: "update",
      approvedBy: "auto",
      reason: "L'IVA era letta dalla tabella sbagliata.",
      current: true,
    }),
    version({ version: 1, reason: "Prime fatture lette a mano." }),
  ];
});
afterEach(() => cleanup());

describe("a skill's versions (3.9.7)", () => {
  it("lists them newest first with who, why and the one in use", async () => {
    const r = render(<SkillHistory name="invoice-pdf" scope="platform" />);
    await waitFor(() => expect(r.getByText("Versione 2")).toBeTruthy());
    expect(r.getByText("in uso")).toBeTruthy();
    expect(r.getByText("Nuova versione")).toBeTruthy();
    expect(r.getByText("Prima versione")).toBeTruthy();
    expect(r.container.textContent).toContain("installata da sola (la tua scelta in Sicurezza)");
    expect(r.container.textContent).toContain("approvata da te");
    expect(r.container.textContent).toContain("L'IVA era letta dalla tabella sbagliata.");
    // The one in use cannot be «brought back»: only the earlier ones.
    expect(r.queryByText("Torna alla versione 2")).toBeNull();
    expect(r.getByText("Torna alla versione 1")).toBeTruthy();
  });

  it("compares an earlier one with the one in use, and goes back after our dialog", async () => {
    const r = render(<SkillHistory name="invoice-pdf" scope="platform" />);
    await waitFor(() => expect(r.getByText("Confronta con quella in uso")).toBeTruthy());
    fireEvent.click(r.getByText("Confronta con quella in uso"));
    await waitFor(() => expect(r.getByTestId("rf-before")).toBeTruthy());
    expect(r.getByTestId("rf-before").textContent).toContain("last page");
    expect(r.getByTestId("rf-after").textContent).toContain("above the total");
    fireEvent.click(r.getByTestId("skill-rollback-1"));
    await waitFor(() => expect(asking.value.length).toBe(1));
    // Nothing happens before the person says yes.
    expect(calls.some(([n]) => n === "rollbackSkill")).toBe(false);
    asking.value[0]?.done(true as never);
    await waitFor(() =>
      expect(r.getByText("Tornata alla versione 1: adesso è la versione 3.")).toBeTruthy(),
    );
    expect(calls.find(([n]) => n === "rollbackSkill")?.[1]).toEqual(["invoice-pdf", "platform", 1]);
  });

  it("says when a version was too large to keep", async () => {
    versions = [
      version({ version: 2, current: true }),
      version({ version: 1, restorable: false, author: "human", approvedBy: null }),
    ];
    const r = render(<SkillHistory name="invoice-pdf" scope="platform" />);
    await waitFor(() =>
      expect(r.getByText("Troppo grande per essere conservata: non può tornare.")).toBeTruthy(),
    );
    expect(r.queryByTestId("skill-rollback-1")).toBeNull();
    // The person's own version says «di te».
    expect(r.container.textContent).toContain("di te ·");
  });
});

describe("a proposed new version (3.9.7)", () => {
  it("is decided on one line, what changed and why; every difference on request", async () => {
    const p: Proposal = {
      id: "prop_1",
      projectId: null,
      kind: "skill",
      name: "invoice-pdf",
      author: "agent_x",
      status: "pending",
      report: [{ name: "no tests", passed: true, detail: "Not testable: instructions" }],
      createdAt: "2026-11-19T10:00:00Z",
      input: {
        description: "Read invoices",
        body: "The VAT is above the total.",
        summary: "L'IVA era letta dalla tabella sbagliata.",
        updates: true,
      },
      previous: { skillMd: "The total is on the last page.", files: [], scope: "platform" },
      proposedSkillMd: "The VAT is above the total.",
      updateLine: "Letta l'IVA dalla tabella sopra il totale: era letta da quella sbagliata",
    };
    const { ProposalView } = await import("../src/components/Extensions.js");
    const r = render(<ProposalView p={p} onDone={() => {}} onClose={() => {}} />);
    expect(r.getByTestId("update-line").textContent).toBe(
      "Cosa è cambiato e perchéLetta l'IVA dalla tabella sopra il totale: era letta da quella sbagliata",
    );
    // The whole comparison only when asked.
    expect(r.getByTestId("proposal-diff").querySelector("del")).toBeNull();
    fireEvent.click(r.getByTestId("proposal-compare"));
    expect(r.getByTestId("proposal-diff").querySelector("del")?.textContent).toBeTruthy();
    expect(r.getByTestId("proposal-diff").querySelector("ins")?.textContent).toBeTruthy();
    expect(r.container.textContent).toContain("dalla loro conversazione successiva");
  });
});
