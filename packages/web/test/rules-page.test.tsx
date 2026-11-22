// @vitest-environment jsdom
// 3.12: Settings › Rules. The rule in words (it and en), a stop in place with «Resume», a rule's
// switch, the ready-made weekly margin added switched off, and the editor's draft sent as the
// server reads it (numbers as numbers, the examples only on the fields the conditions use).
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
import { afterEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const calls: [string, unknown[]][] = [];
const rule = {
  id: "rule_1",
  name: "Niente push",
  description: "",
  enabled: true,
  origin: "person",
  version: 2,
  createdAt: "2026-11-22T10:00:00.000Z",
  updatedAt: "2026-11-22T10:00:00.000Z",
  lastFiredAt: null,
  when: { event: "tool" },
  if: [{ field: "command", op: "matches", value: "git push*" }],
  actions: [{ do: "block", text: "oggi no" }],
  examples: { fire: { command: "git push" }, pass: { command: "git status" } },
};
const hold = {
  ruleId: "rule_9",
  ruleName: "Margine settimanale: fermata",
  reason: "margine +1 punti",
  at: "2026-11-22T10:00:00.000Z",
  scope: "all",
  resume: "person",
};
const fakeApi = new Proxy(
  {},
  {
    get: (_t, name: string) => {
      if (name === "then") return undefined;
      return (...args: unknown[]) => {
        calls.push([name, args]);
        if (name === "rules") return Promise.resolve({ rules: [rule], holds: [hold], fires: [] });
        if (name === "tryRule")
          return Promise.resolve({ ok: true, fire: true, pass: true, problems: [] });
        return Promise.resolve(name === "magicRules" ? [] : {});
      };
    },
  },
);
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
}));

const { Rules, ruleLines } = await import("../src/components/Rules.js");

afterEach(() => {
  cleanup();
  calls.length = 0;
});

describe("Settings › Rules (3.12)", () => {
  it("says a rule in three lines, in both languages", () => {
    const margin = {
      when: { event: "usage" as const },
      if: [{ field: "marginPct" as const, op: "lte" as const, value: 2 }],
      actions: [
        { do: "stop" as const, text: "", scope: "all" as const, resume: "person" as const },
      ],
    };
    lang.value = "it";
    expect(ruleLines(margin)).toEqual([
      "Quando si legge il consumo dell'abbonamento",
      "se il margine (punti) è al massimo 2",
      "allora ferma gli agenti dopo che hanno salvato, finché non li riprendi",
    ]);
    lang.value = "en";
    expect(ruleLines(margin)[2]).toBe(
      "then stop the agents after they save, until you resume them",
    );
  });

  it("shows the stop with «Resume», the rule's switch and the ready-made margin", async () => {
    lang.value = "it";
    const r = render(<Rules />);
    await waitFor(() =>
      expect(r.getByText("Fermati dalla regola «Margine settimanale: fermata»")).toBeTruthy(),
    );
    fireEvent.click(r.getByText("Riprendi"));
    expect(calls.some(([n, a]) => n === "resumeRules" && a[0] === "rule_9")).toBe(true);
    fireEvent.click(r.getByRole("switch", { name: "Regola «Niente push» accesa" }));
    expect(calls.some(([n, a]) => n === "enableRule" && a[0] === "rule_1" && a[1] === false)).toBe(
      true,
    );
    fireEvent.click(r.getByText("Aggiungi le due regole"));
    expect(
      calls.some(([n, a]) => n === "addRuleTemplate" && a[0] === "weekly-margin" && a.length === 1),
    ).toBe(true);
    expect(r.container.querySelector('input[type="checkbox"], input[type="radio"]')).toBeNull();
  });

  it("the editor sends the draft as the server reads it", async () => {
    lang.value = "it";
    const r = render(<Rules />);
    await waitFor(() => expect(r.getByText("Niente push")).toBeTruthy());
    fireEvent.click(r.getByRole("button", { name: "Cambia" }));
    await waitFor(() => expect(r.container.querySelector(".rl-editor")).toBeTruthy());
    fireEvent.click(r.getByRole("button", { name: "Prova" }));
    await waitFor(() =>
      expect(
        r.getByText("I due esempi vanno come devono: la regola si può accendere."),
      ).toBeTruthy(),
    );
    const tried = calls.find(([n]) => n === "tryRule")?.[1][0];
    expect(tried).toEqual({
      name: "Niente push",
      description: "",
      when: { event: "tool" },
      if: [{ field: "command", op: "matches", value: "git push*" }],
      actions: [{ do: "block", text: "oggi no" }],
      examples: { fire: { command: "git push" }, pass: { command: "git status" } },
    });
  });
});
