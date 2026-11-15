// @vitest-environment jsdom
// Subscription or API key (G40.9b): a model that goes both ways shows once, with a drawn choice of
// the way and a line on what it means; with one way the way still shows.
import { cleanup, fireEvent, render, waitFor } from "@testing-library/preact";
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

const options = (c: Element) =>
  [...(c.querySelector("select")?.querySelectorAll("option") ?? [])].map((o) => o.textContent);

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
    expect(options(container)).toEqual(["Opus 5.5", "Haiku 4.5"]);
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
    const select = container.querySelector("select") as HTMLSelectElement;
    fireEvent.change(select, { target: { value: "anthropic/claude-haiku-4-5" } });
    expect(changes[0]).toEqual({ provider: "anthropic", model: "claude-haiku-4-5" });
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
