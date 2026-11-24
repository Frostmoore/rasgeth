import { describe, expect, it } from "vitest";
import {
  familyOf,
  groupTitle,
  type ModelRoute,
  modelFamilies,
  modelGroups,
  modelMatches,
  modelRoute,
  routeHint,
  routeLabel,
  routePhrase,
} from "../src/model-routes.js";

describe("modelRoute (G40.9b)", () => {
  const table: [string, string, string | undefined, ModelRoute][] = [
    [
      "claude-subscription",
      "claude-opus-5-5",
      undefined,
      { kind: "subscription", vendor: "anthropic", model: "claude-opus-5-5" },
    ],
    [
      "anthropic",
      "claude-opus-5-5",
      undefined,
      { kind: "key", vendor: "anthropic", model: "claude-opus-5-5" },
    ],
    [
      "chatgpt-subscription",
      "gpt-5.5",
      undefined,
      { kind: "subscription", vendor: "openai", model: "gpt-5.5" },
    ],
    ["openai", "gpt-5.5", undefined, { kind: "key", vendor: "openai", model: "gpt-5.5" }],
    ["gemini", "gemini-3-pro", undefined, { kind: "key", vendor: "gemini", model: "gemini-3-pro" }],
    [
      "node-rig",
      "claude-subscription:claude-opus-5-5",
      "Opus 5.5 (via Rig)",
      {
        kind: "node",
        vendor: "anthropic",
        model: "claude-opus-5-5",
        node: "Rig",
        through: "subscription",
      },
    ],
    [
      "node-rig",
      "openai:gpt-5.5",
      undefined,
      { kind: "node", vendor: "openai", model: "gpt-5.5", node: "rig", through: "key" },
    ],
    [
      "node-rig",
      "local:qwen3",
      undefined,
      { kind: "node", vendor: "local", model: "qwen3", node: "rig" },
    ],
    ["local", "qwen3-8b", undefined, { kind: "local", vendor: "local", model: "qwen3-8b" }],
    ["server", "llama", undefined, { kind: "local", vendor: "server", model: "llama" }],
    ["fake", "m1", undefined, { kind: "other", vendor: "fake", model: "m1" }],
  ];
  it.each(table)("%s / %s", (provider, model, name, want) => {
    expect(modelRoute(provider, model, name)).toEqual(want);
  });
});

describe("modelFamilies", () => {
  const choices = [
    { provider: "anthropic", model: "claude-opus-5-5", name: "Claude Opus 5.5" },
    { provider: "claude-subscription", model: "claude-opus-5-5", name: "Claude Opus 5.5" },
    { provider: "claude-subscription", model: "claude-haiku-4-5" },
    { provider: "openai", model: "gpt-5.5" },
    { provider: "node-rig", model: "anthropic:claude-opus-5-5", name: "Claude Opus 5.5 (via Rig)" },
    { provider: "local", model: "qwen3" },
  ];
  const families = modelFamilies(choices);

  it("shows each model once, with every way it can go, the subscription first", () => {
    const table: [string, string[]][] = [
      ["anthropic/claude-opus-5-5", ["subscription", "key", "node"]],
      ["anthropic/claude-haiku-4-5", ["subscription"]],
      ["openai/gpt-5.5", ["key"]],
      ["local/qwen3", ["local"]],
    ];
    expect(families.map((f) => [f.id, f.routes.map((r) => r.route.kind)])).toEqual(table);
  });

  it("keeps the name without the node's «(via …)»", () => {
    expect(families[0]?.name).toBe("Claude Opus 5.5");
    expect(modelFamilies([choices[4] as (typeof choices)[number]])[0]?.name).toBe(
      "Claude Opus 5.5",
    );
  });

  it("finds the family and the way of a chosen model", () => {
    const f = familyOf(families, { provider: "anthropic", model: "claude-opus-5-5" });
    expect(f?.family.id).toBe("anthropic/claude-opus-5-5");
    expect(f?.family.routes[f.index]?.route.kind).toBe("key");
    expect(familyOf(families, { provider: "anthropic", model: "nope" })).toBeUndefined();
  });
});

describe("labels", () => {
  const sub = modelRoute("claude-subscription", "m");
  const key = modelRoute("anthropic", "m");
  const node = modelRoute("node-rig", "claude-subscription:m", "M (via Rig)");
  const table: [ModelRoute, string, string, string, string][] = [
    [
      sub,
      "Abbonamento",
      "Subscription",
      "Nei limiti del tuo piano: non paghi a consumo.",
      "Within your plan's limits: nothing is paid per use.",
    ],
    [
      key,
      "Chiave API",
      "API key",
      "A consumo con la tua chiave API: conta per il tetto di spesa.",
      "Paid per use with your API key: it counts toward the spending cap.",
    ],
    [
      node,
      "Tramite Rig",
      "Via Rig",
      "Passa dal computer Rig, con il suo abbonamento.",
      "Goes through the computer Rig, with its subscription.",
    ],
  ];
  it.each(table)("%j", (route, it_, en, hintIt, hintEn) => {
    expect(routeLabel(route, "it")).toBe(it_);
    expect(routeLabel(route, "en")).toBe(en);
    expect(routeHint(route, "it")).toBe(hintIt);
    expect(routeHint(route, "en")).toBe(hintEn);
  });

  it("says the way in a sentence", () => {
    const table: [string, string, string, string][] = [
      ["claude-subscription", "m", " con l'abbonamento", " with the subscription"],
      ["anthropic", "m", " con la chiave API", " with the API key"],
      ["node-rig", "openai:m", " tramite rig", " via rig"],
      ["local", "m", " in locale", " locally"],
      ["fake", "m", "", ""],
    ];
    for (const [p, m, it_, en] of table) {
      expect(routePhrase(p, m, "it")).toBe(it_);
      expect(routePhrase(p, m, "en")).toBe(en);
    }
  });
});

describe("modelGroups (2026-11-20: by provider and way, the newest first)", () => {
  type C = { provider: string; model: string; name?: string; released?: string };
  const choices: C[] = [
    { provider: "local", model: "qwen3-8b" },
    { provider: "anthropic", model: "claude-sonnet-5", released: "2026-05-01" },
    { provider: "openai", model: "gpt-5.5", released: "2026-04-10" },
    { provider: "claude-subscription", model: "claude-sonnet-5", released: "2026-05-01" },
    { provider: "claude-subscription", model: "claude-opus-5-5", released: "2026-09-01" },
    { provider: "claude-subscription", model: "claude-haiku-5" },
    { provider: "anthropic", model: "claude-opus-5-5", released: "2026-09-01" },
    {
      provider: "node-rig",
      model: "claude-subscription:claude-opus-5-5",
      name: "Opus 5.5 (via Rig)",
    },
    { provider: "server", model: "llama-4" },
    { provider: "chatgpt-subscription", model: "gpt-5.5", released: "2026-04-10" },
    { provider: "chatgpt-subscription", model: "gpt-6", released: "2026-10-01" },
    { provider: "deepseek", model: "deepseek-v4" },
    { provider: "acme", model: "x-1" },
  ];
  const groups = modelGroups(choices);

  it("orders the groups: companies, subscription before key, then nodes, then local", () => {
    expect(groups.map((g) => g.id)).toEqual([
      "claude-subscription",
      "anthropic",
      "chatgpt-subscription",
      "openai",
      "deepseek",
      "acme",
      "node-rig|anthropic",
      "local",
      "server",
    ]);
  });

  it("puts the newest first, undated after in the provider's order", () => {
    expect(groups[0]?.choices.map((c) => c.model)).toEqual([
      "claude-opus-5-5",
      "claude-sonnet-5",
      "claude-haiku-5",
    ]);
    expect(groups[2]?.choices.map((c) => c.model)).toEqual(["gpt-6", "gpt-5.5"]);
  });

  it("names each group clearly, it and en", () => {
    const table: [string, string, string][] = [
      ["claude-subscription", "Abbonamento Claude", "Claude subscription"],
      ["anthropic", "Chiave API Anthropic", "Anthropic API key"],
      ["chatgpt-subscription", "Abbonamento ChatGPT", "ChatGPT subscription"],
      ["openai", "Chiave API OpenAI", "OpenAI API key"],
      ["deepseek", "Chiave API DeepSeek", "DeepSeek API key"],
      ["acme", "acme", "acme"],
      ["node-rig|anthropic", "Tramite Rig · Anthropic", "Via Rig · Anthropic"],
      ["local", "Motore locale", "Local engine"],
      ["server", "Server tuo", "Your own server"],
    ];
    for (const [id, it_, en] of table) {
      const g = groups.find((x) => x.id === id);
      expect(g && groupTitle(g, "it")).toBe(it_);
      expect(g && groupTitle(g, "en")).toBe(en);
    }
  });

  it("finds a model by its name, id or heading", () => {
    const m = { provider: "anthropic", model: "claude-opus-5-5", name: "Opus 5.5" };
    expect(modelMatches(m, "Anthropic API key", "")).toBe(true);
    expect(modelMatches(m, "Anthropic API key", "opus")).toBe(true);
    expect(modelMatches(m, "Anthropic API key", "api KEY")).toBe(true);
    expect(modelMatches(m, "Anthropic API key", "gpt")).toBe(false);
  });
});
