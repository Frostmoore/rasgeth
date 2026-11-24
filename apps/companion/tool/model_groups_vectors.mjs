// Writes test/fixtures/model_groups_vectors.json: lists of models and what @redgiant/protocol's
// own `modelGroups`, `groupTitle` and `modelMatches` make of them (the menus by provider and way,
// the newest first: 2026-11-20, the person), so test/g42_15_model_groups_test.dart checks that
// lib/api/model_routes.dart groups, orders and names them the very same way (G42.15).
//
//   pnpm exec tsc -b packages/protocol && node apps/companion/tool/model_groups_vectors.mjs
import { writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const lib = resolve(process.argv[2] ?? join(here, "../../../packages/protocol/dist/index.js"));
const { modelGroups, groupTitle, modelMatches } = await import(pathToFileURL(lib).href);

const lists = [
  [],
  [
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
    { provider: "node-rig", model: "openai:gpt-5.5", name: "GPT-5.5 (via Rig)" },
    { provider: "node-coder", model: "local:qwen3", name: "qwen3 (via Coder)" },
    { provider: "server", model: "llama-4" },
    { provider: "chatgpt-subscription", model: "gpt-5.5", released: "2026-04-10" },
    { provider: "chatgpt-subscription", model: "gpt-6", released: "2026-10-01" },
    { provider: "deepseek", model: "deepseek-v4" },
    { provider: "gemini", model: "gemini-3-pro", released: "2026-03-01" },
    { provider: "gemini", model: "gemini-3-flash", released: "2026-03-01" },
    { provider: "acme", model: "x-1" },
    { provider: "openrouter", model: "meta/llama-5" },
  ],
  [
    { provider: "fake", model: "m1" },
    { provider: "fake", model: "m2", released: "2026-01-01" },
    { provider: "zeta", model: "z" },
  ],
];

const vectors = lists.map((choices) => {
  const groups = modelGroups(choices);
  return {
    choices,
    groups: groups.map((g) => ({
      id: g.id,
      it: groupTitle(g, "it"),
      en: groupTitle(g, "en"),
      models: g.choices.map((c) => `${c.provider}/${c.model}`),
    })),
  };
});

const searches = [
  [{ provider: "anthropic", model: "claude-opus-5-5", name: "Opus 5.5" }, "Anthropic API key", ""],
  [{ provider: "anthropic", model: "claude-opus-5-5", name: "Opus 5.5" }, "Anthropic API key", "OPUS"],
  [{ provider: "anthropic", model: "claude-opus-5-5" }, "Anthropic API key", "api k"],
  [{ provider: "anthropic", model: "claude-opus-5-5" }, "Anthropic API key", "5-5"],
  [{ provider: "anthropic", model: "claude-opus-5-5" }, "Anthropic API key", "gpt"],
].map(([m, heading, query]) => ({ m, heading, query, matches: modelMatches(m, heading, query) }));

const out = join(here, "../test/fixtures/model_groups_vectors.json");
writeFileSync(out, `${JSON.stringify({ vectors, searches }, null, 2)}\n`);
console.log(`wrote ${vectors.length} lists, ${searches.length} searches`);
