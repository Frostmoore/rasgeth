// @vitest-environment jsdom
// One model picker everywhere (roadmap, 3.12.4): grouped by how the model is paid, newest first
// in each group, a search, the model in use highlighted and scrolled into view, the keys.
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { cleanup, fireEvent, render } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { ModelChoice } from "../src/api.js";
import { lang } from "../src/i18n.js";

const MODELS: ModelChoice[] = [
  {
    provider: "claude-subscription",
    model: "claude-sonnet-5",
    name: "Sonnet 5",
    released: "2026-05-01",
  },
  {
    provider: "claude-subscription",
    model: "claude-opus-5-5",
    name: "Opus 5.5",
    released: "2026-09-01",
    status: "new",
  },
  { provider: "anthropic", model: "claude-opus-5-5", name: "Opus 5.5", released: "2026-09-01" },
  { provider: "chatgpt-subscription", model: "gpt-5.5", name: "GPT 5.5", released: "2026-04-10" },
  { provider: "chatgpt-subscription", model: "gpt-6", name: "GPT 6", released: "2026-10-01" },
  { provider: "openai", model: "gpt-5.5", name: "GPT 5.5", released: "2026-04-10" },
  { provider: "local", model: "qwen3-8b" },
  { provider: "server", model: "llama-5" },
];
vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () => ({ models: () => Promise.resolve(MODELS) }),
}));
const { ModelSelect } = await import("../src/components/ModelSelect.js");

beforeEach(() => {
  lang.value = "it";
});
afterEach(cleanup);

const open = (c: Element) =>
  fireEvent.click(c.querySelector(".model-drop .ui-drop-current") as Element);
const list = () => document.querySelector(".ui-drop-list") as HTMLElement;
/** Headings and models, in the order the list shows them. */
const shown = () =>
  [...list().children]
    .filter((e) => !e.matches("input,p"))
    .map((e) =>
      e.matches(".ui-drop-group")
        ? `# ${e.textContent}`
        : e.querySelector(".ui-drop-words span")?.textContent,
    );

describe("the model picker", () => {
  it("groups by how the model is paid, newest first, in both languages", () => {
    const r = render(<ModelSelect value={null} onChange={() => {}} models={MODELS} />);
    open(r.container);
    expect(shown()).toEqual([
      "Scegli un modello",
      "# Abbonamento Claude",
      "Opus 5.5 · nuovo",
      "Sonnet 5",
      "# Chiave API Anthropic",
      "Opus 5.5",
      "# Abbonamento ChatGPT",
      "GPT 6",
      "GPT 5.5",
      "# Chiave API OpenAI",
      "GPT 5.5",
      "# Motore locale",
      "qwen3-8b",
      "# Server tuo",
      "llama-5",
    ]);
    cleanup();
    lang.value = "en";
    const e = render(<ModelSelect value={null} onChange={() => {}} models={MODELS} />);
    open(e.container);
    expect(shown().filter((x) => x?.startsWith("#"))).toEqual([
      "# Claude subscription",
      "# Anthropic API key",
      "# ChatGPT subscription",
      "# OpenAI API key",
      "# Local engine",
      "# Your own server",
    ]);
  });

  it("has a search by name or id, and says so when nothing matches", () => {
    const r = render(<ModelSelect value={null} onChange={() => {}} models={MODELS} />);
    open(r.container);
    const search = list().querySelector("input") as HTMLInputElement;
    fireEvent.input(search, { target: { value: "gpt-6" } });
    expect(shown()).toEqual(["# Abbonamento ChatGPT", "GPT 6"]);
    fireEvent.input(search, { target: { value: "sonnet" } });
    expect(shown()).toEqual(["# Abbonamento Claude", "Sonnet 5"]);
    fireEvent.input(search, { target: { value: "chiave api" } });
    expect(shown().filter((x) => x?.startsWith("#"))).toEqual([
      "# Chiave API Anthropic",
      "# Chiave API OpenAI",
    ]);
    fireEvent.input(search, { target: { value: "zzz" } });
    expect(list().querySelector(".ui-drop-none")).not.toBeNull();
  });

  it("highlights the model in use and scrolls it into view", () => {
    const seen: string[] = [];
    HTMLElement.prototype.scrollIntoView = function (this: HTMLElement) {
      seen.push(this.textContent ?? "");
    };
    const r = render(
      <ModelSelect
        value={{ provider: "anthropic", model: "claude-opus-5-5" }}
        onChange={() => {}}
        models={MODELS}
      />,
    );
    open(r.container);
    const on = list().querySelectorAll("button.on");
    expect(on.length).toBe(1);
    expect(on[0]?.getAttribute("aria-selected")).toBe("true");
    // The one under «Chiave API Anthropic», not the subscription's with the same name.
    expect(on[0]?.previousElementSibling?.textContent).toBe("Chiave API Anthropic");
    expect(seen.some((x) => x.includes("Opus 5.5"))).toBe(true);
  });

  it("chooses with the keys: arrows from the search, a letter goes to the search", () => {
    const picks: unknown[] = [];
    const r = render(<ModelSelect value={null} onChange={(m) => picks.push(m)} models={MODELS} />);
    open(r.container);
    const search = list().querySelector("input") as HTMLInputElement;
    search.focus();
    fireEvent.keyDown(search, { key: "ArrowDown" });
    const first = list().querySelector("button[role=option]") as HTMLElement;
    expect(document.activeElement).toBe(first);
    fireEvent.keyDown(first, { key: "g" });
    expect(document.activeElement).toBe(search);
    // The first row is «pick a model»; the next is the newest of the first group.
    fireEvent.keyDown(search, { key: "ArrowDown" });
    fireEvent.keyDown(document.activeElement as Element, { key: "ArrowDown" });
    fireEvent.click(document.activeElement as Element);
    expect(picks).toEqual([{ provider: "claude-subscription", model: "claude-opus-5-5" }]);
  });
});

describe("one picker everywhere", () => {
  const src = join(import.meta.dirname, "../src");
  const files = (d: string): string[] =>
    readdirSync(d, { withFileTypes: true }).flatMap((e) =>
      e.isDirectory() ? files(join(d, e.name)) : /\.tsx?$/.test(e.name) ? [join(d, e.name)] : [],
    );
  const all = files(src).map((f) => [f.slice(src.length + 1), readFileSync(f, "utf8")] as const);

  it("builds the grouped list in one place only", () => {
    const own = (re: RegExp) => all.filter(([, s]) => re.test(s)).map(([f]) => f);
    expect(own(/\bmodelGroups\(/)).toEqual(["components/ModelSelect.tsx"]);
    expect(own(/(^|[^`])<select[\s>]/m)).toEqual([]);
    expect(own(/modelOptions\(/)).toEqual(["components/ModelSelect.tsx"]);
  });

  it("every screen that reads the models draws them with that picker", () => {
    const reading = all
      .filter(([f, s]) => /\.models\(\)|useModels\(/.test(s) && !/Model(Select|Menu)\.tsx$/.test(f))
      .filter(([f]) => !/Setup\.tsx|ModelsPage/.test(f));
    expect(reading.length).toBeGreaterThan(5);
    for (const [f, s] of reading) expect(/<ModelSelect|<ModelFamilySelect/.test(s), f).toBe(true);
  });
});
