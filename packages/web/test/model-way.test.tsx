// @vitest-environment jsdom
// Subscription or API key (G40.9b): a model that goes both ways shows once, with a drawn choice of
// the way and a line on what it means; with one way the way still shows.
import { cleanup, fireEvent, render, screen, waitFor } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { ModelChoice } from "../src/api.js";
import { lang } from "../src/i18n.js";

const MODELS: ModelChoice[] = [
  { provider: "claude-subscription", model: "claude-opus-5-5", effort: true, name: "Opus 5.5" },
  { provider: "anthropic", model: "claude-opus-5-5", effort: true, name: "Opus 5.5" },
  { provider: "anthropic", model: "claude-haiku-4-5", effort: false, name: "Haiku 4.5" },
];
const updates: unknown[] = [];
const fakeApi = {
  models: () => Promise.resolve(MODELS),
  updateSession: (_id: string, body: unknown) => {
    updates.push(body);
    return Promise.resolve({});
  },
  conversations: () => Promise.resolve([]),
};
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => fakeApi,
  refreshConversations: () => Promise.resolve(),
}));

const { ModelSelect } = await import("../src/components/ModelSelect.js");
const { ModelMenu } = await import("../src/components/ModelMenu.js");

beforeEach(() => {
  lang.value = "it";
  updates.length = 0;
});
afterEach(cleanup);

/** Opens the drawn model menu and reads it: headings and models, in order. */
const options = (c: Element) => {
  fireEvent.click(c.querySelector(".model-drop .ui-drop-current") as Element);
  const list = document.querySelector(".ui-drop-list");
  return [...(list?.children ?? [])]
    .filter((e) => !e.matches("input"))
    .map((e) =>
      e.matches(".ui-drop-group")
        ? `# ${e.textContent}`
        : e.querySelector(".ui-drop-words span")?.textContent,
    );
};

describe("ModelSelect", () => {
  it("shows a model reached both ways once, with the drawn choice and its line", () => {
    const changes: unknown[] = [];
    const { container, getByText } = render(
      <ModelSelect
        value={{ provider: "claude-subscription", model: "claude-opus-5-5", effort: "high" }}
        onChange={(m) => changes.push(m)}
        models={MODELS}
      />,
    );
    expect(options(container)).toEqual([
      "# Anthropic · Abbonamento Claude",
      "Opus 5.5",
      "# Anthropic · Chiave API",
      "Opus 5.5",
      "Haiku 4.5",
    ]);
    fireEvent.click(container.querySelector(".model-drop .ui-drop-current") as Element);
    const sub = getByText("Abbonamento");
    expect(sub.getAttribute("aria-pressed")).toBe("true");
    expect(getByText("Nei limiti del tuo piano: non paghi a consumo.")).toBeTruthy();
    expect(container.querySelector("input[type=radio]")).toBeNull();
    fireEvent.click(getByText("Chiave API"));
    expect(changes).toEqual([{ provider: "anthropic", model: "claude-opus-5-5", effort: "high" }]);
  });

  it("says the line of the API key and keeps the way when the model changes", () => {
    const changes: { provider: string; model: string }[] = [];
    const { container, getByText } = render(
      <ModelSelect
        value={{ provider: "anthropic", model: "claude-opus-5-5" }}
        onChange={(m) => m && changes.push(m)}
        models={MODELS}
      />,
    );
    expect(getByText("A consumo con la tua chiave API: conta per il tetto di spesa.")).toBeTruthy();
    options(container);
    fireEvent.click(screen.getByRole("option", { name: "Haiku 4.5" }));
    expect(changes[0]).toEqual({ provider: "anthropic", model: "claude-haiku-4-5" });
    expect(container.querySelector("select")).toBeNull();
  });

  it("shows the only way as a small label", () => {
    lang.value = "en";
    const { container } = render(
      <ModelSelect
        value={{ provider: "anthropic", model: "claude-haiku-4-5" }}
        onChange={() => {}}
        models={MODELS}
      />,
    );
    expect(container.querySelector(".model-way-one")?.textContent).toBe("API key");
    expect(container.querySelector(".model-way-seg")).toBeNull();
  });
});

describe("The model menu by provider and way (2026-11-20)", () => {
  it("puts the newest first and searches a long list", () => {
    const many: ModelChoice[] = [
      { provider: "anthropic", model: "claude-haiku-4-5", effort: false, name: "Haiku 4.5" },
      {
        provider: "anthropic",
        model: "claude-fable-5-2",
        effort: true,
        name: "Fable 5.2",
        released: "2026-11-09",
      },
      ...Array.from({ length: 8 }, (_, i) => ({
        provider: "openrouter",
        model: `vendor/model-${i}`,
        effort: false,
      })),
    ];
    const { container } = render(
      <ModelSelect value={null} onChange={() => {}} models={many} empty="Il predefinito" />,
    );
    const shown = options(container);
    expect(shown.slice(0, 4)).toEqual([
      "Il predefinito",
      "# Anthropic · Chiave API",
      "Fable 5.2",
      "Haiku 4.5",
    ]);
    expect(shown).toContain("# OpenRouter · Chiave API");
    const search = screen.getByRole("searchbox", { name: "Cerca un modello" });
    fireEvent.input(search, { target: { value: "fable" } });
    expect(
      [...document.querySelectorAll(".ui-drop-list [role=option]")].map((o) => o.textContent),
    ).toEqual(["Fable 5.2"]);
    fireEvent.input(search, { target: { value: "nothing like it" } });
    expect(screen.getByText("Nessun risultato.")).toBeTruthy();
  });
});

describe("ModelMenu (the composer's …)", () => {
  it("switches the conversation to the API key with one tap", async () => {
    const { findByText } = render(
      <ModelMenu
        sessionId="s1"
        current={{ provider: "claude-subscription", model: "claude-opus-5-5", effort: "medium" }}
        own
        disabled={false}
      />,
    );
    fireEvent.click(await findByText("Chiave API"));
    await waitFor(() =>
      expect(updates).toEqual([
        { model: { provider: "anthropic", model: "claude-opus-5-5", effort: "medium" } },
      ]),
    );
  });
});
