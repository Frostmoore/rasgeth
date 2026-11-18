// Writes test/fixtures/automation_vectors.json (G42.9): what the page's own automation editor
// (packages/web/src/components/AutomationEditor.tsx) makes of a few schedules, recipes and drafts:
// the cron of a choice and back, the schedule in words, the draft a recipe becomes, its YAML and
// its sentence, in Italian and in English, so the app's Dart port
// (lib/settings/automations/automation_draft.dart) says and writes exactly the same. Recipes go
// through the protocol's `Recipe` first, as the server reads them (defaults filled in). The
// component is bundled for node with esbuild-wasm, as items_fixtures.mjs does. Deterministic.
//
//   node apps/companion/tool/automation_vectors.mjs
import { mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

process.env.TZ = "UTC";
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "../../..");
const web = join(root, "packages/web");
const tmp = "/mnt/archive1/officina-dati/rg-test/tmp/automation-vectors";
mkdirSync(tmp, { recursive: true });

const store = new Map([["rg.lang", "it"]]);
globalThis.localStorage = {
  getItem: (k) => store.get(k) ?? null,
  setItem: (k, v) => store.set(k, String(v)),
  removeItem: (k) => store.delete(k),
  clear: () => store.clear(),
};
globalThis.sessionStorage = globalThis.localStorage;
globalThis.window ??= globalThis;
globalThis.location ??= new URL("http://localhost/");
globalThis.addEventListener ??= () => {};
globalThis.matchMedia ??= () => ({ matches: false, addEventListener() {}, removeEventListener() {} });
if (!globalThis.navigator?.language) {
  Object.defineProperty(globalThis, "navigator", {
    value: { language: "it-IT", userAgent: "node" },
    configurable: true,
  });
}

const pnpm = join(root, "node_modules/.pnpm");
const wasm = readdirSync(pnpm).find((d) => d.startsWith("esbuild-wasm@"));
if (!wasm) throw new Error("esbuild-wasm is not in node_modules/.pnpm");
const esbuild = (await import(pathToFileURL(join(pnpm, wasm, "node_modules/esbuild-wasm/lib/main.js")).href))
  .default;
const bundle = join(tmp, "editor.mjs");
await esbuild.build({
  stdin: {
    contents: [
      'export { toCron, fromCron, fromOn, whenWords, blankDraft, fromRecipe, toYaml, sentence, whoOptions } from "./components/AutomationEditor.tsx";',
      'export { agents, projects } from "./state.ts";',
      'export { lang } from "./i18n.ts";',
      'export { Recipe } from "@redgiant/protocol";',
    ].join("\n"),
    resolveDir: join(web, "src"),
    loader: "ts",
  },
  bundle: true,
  platform: "node",
  format: "esm",
  outfile: bundle,
  logLevel: "error",
  loader: { ".css": "empty", ".svg": "empty", ".png": "empty", ".wasm": "empty" },
  jsx: "automatic",
  jsxImportSource: "preact",
  banner: { js: 'import { createRequire } from "node:module"; const require = createRequire(import.meta.url);' },
});
esbuild.stop?.();
const E = await import(`${pathToFileURL(bundle).href}?${Date.now()}`);

// The same team and projects the Dart test builds (as `GET /api/agents` and `/api/projects`).
const AGENTS = [
  { id: "a0", kind: "god", name: "God", status: "active", projectId: null },
  { id: "as1", kind: "assistant", name: "Segretaria", status: "active", projectId: null },
  { id: "o1", kind: "orchestrator", name: "Capo", status: "active", projectId: "demo" },
  { id: "d1", kind: "agent", name: "Dev", status: "active", projectId: "demo" },
  { id: "d2", kind: "agent", name: "Fermo", status: "stopped", projectId: "demo" },
];
const PROJECTS = [
  { id: "demo", name: "Demo" },
  { id: "site", name: "Sito" },
];
E.agents.value = AGENTS;
E.projects.value = PROJECTS;

const both = (f) => {
  const out = {};
  for (const l of ["it", "en"]) {
    E.lang.value = l;
    out[l] = f();
  }
  E.lang.value = "it";
  return out;
};

const crons = [
  ["0 8 * * *", false],
  ["30 7 * * 1-5", false],
  ["0 17 * * 5,1", false],
  ["0 */3 * * *", false],
  ["*/15 * * * *", false],
  ["0 9 1 * *", false],
  ["0 9 * 1 *", false],
  ["5 4 3 2 1 0", false],
  ["15 10 * * 1-3", false],
  [undefined, true],
  [undefined, false],
].map(([cron, webhook]) => ({ cron: cron ?? null, webhook, when: E.fromCron(cron, webhook) }));

const whens = [
  { kind: "daily", time: "08:00" },
  { kind: "weekdays", time: "07:30" },
  { kind: "weekly", time: "17:00", days: [5, 1, 3] },
  { kind: "weekly", time: "09:15", days: [] },
  { kind: "hours", every: 30 },
  { kind: "minutes", every: 0 },
  { kind: "monthly", time: "09:00", day: 12 },
  { kind: "webhook" },
  { kind: "repo", project: "demo", events: ["push", "release"] },
  { kind: "email", from: "banca", subject: "" },
  { kind: "email", from: "", subject: "" },
  { kind: "custom", cron: "0 9 * * 1" },
].map((w) => ({ when: w, cron: E.toCron(w), words: both(() => E.whenWords(w)) }));

// Recipes as people and God write them; the protocol fills in what they leave out.
const recipes = [
  {
    name: "morning",
    description: "Il punto del mattino",
    on: { cron: "0 8 * * 1-5", timezone: "Europe/Rome" },
    agent: "god",
    instructions: "Dimmi cosa è successo ieri.",
  },
  {
    name: "invoices",
    description: "Fatture in arrivo",
    on: {
      email: { from: "fatture@", subject: "Fattura", categories: ["work"] },
      files: { project: "site", path: "in", pattern: "*.pdf", changes: ["added"] },
      cron: "0 */2 * * *",
    },
    only: {
      hours: { from: "09:00", to: "18:00" },
      days: [5, 1, 2],
      words: ["urgente", "scade"],
      match: "all",
      without: ["spam"],
      maxPerDay: 4,
      cooldownMinutes: 30,
    },
    agent: "Dev",
    project: "demo",
    model: "anthropic/claude-x",
    effort: "high",
    instructions: "Registra le fatture nuove nel foglio e dimmi il totale.",
    session: "continue",
    approve: true,
    budgetUsd: 1.5,
    timeoutMinutes: 45,
    overlap: "queue",
    missed: "run",
    onFailure: { retries: 2, retryMinutes: 10, run: "morning" },
    notify: { when: "failure", to: ["telegram", "email"], email: "io@example.com", box: "mb1" },
  },
  {
    name: "chat-words",
    description: "",
    on: {
      message: { platforms: ["whatsapp", "telegram"], from: "Anna", words: ["spesa"], handle: true },
      after: { automation: "morning", status: ["failed"] },
      task: { project: "demo", outcome: ["abandoned"] },
      startup: true,
    },
    agent: "orchestrator",
    project: "demo",
    instructions: "Aggiungi alla lista della spesa quello che scrive Anna, e avvisa se qualcosa non va per il verso giusto anche quando il messaggio è molto lungo e non sta in una riga.",
    notify: { when: "never" },
  },
  {
    name: "repo-prs",
    description: "Le pull request",
    on: { webhook: true, events: ["pull_request", "issues"] },
    agent: "as1",
    instructions: "Guarda la pull request.",
    notify: { to: ["web"] },
  },
  {
    name: "hook",
    description: "Dal webhook",
    on: { webhook: true, cron: "*/20 * * * *" },
    agent: "god",
    instructions: "Leggi i dati.",
    only: { dates: { from: "2026-12-01" } },
  },
  {
    name: "reminder-dentist",
    description: "Dentista",
    on: { at: "2026-11-20T15:30", timezone: "Europe/Rome" },
    reminder: "Dentista alle 16",
  },
  {
    name: "lost",
    description: "Un agente che non c'è più",
    on: { cron: "0 9 * * *" },
    agent: "Fantasma",
    instructions: "Niente.",
  },
].map((r) => E.Recipe.parse(r));

const others = [{ name: "morning", recipe: { description: "Il punto del mattino" } }];
const fromRecipes = recipes.map((recipe) => {
  const draft = E.fromRecipe(recipe);
  return {
    recipe,
    draft,
    yaml: E.toYaml(draft, recipe.name),
    sentence: both(() => E.sentence(E.fromRecipe(recipe), others)),
  };
});

// Drafts as the editor leaves them after a few choices (what fromRecipe never makes).
const base = () => E.blankDraft();
const drafts = [
  base(),
  { ...base(), title: "  Spaces  ", starts: [], instructions: "  x  " },
  {
    ...base(),
    title: "Ogni sera",
    starts: ["time", "webhook", "repo"],
    time: { kind: "weekly", time: "21:05", days: [6, 0] },
    repo: { project: "site", events: [] },
    whoKey: "a:d1",
    instructions: "Controlla.",
    only: { ...base().only, days: [], senders: " ", words: " ", match: "all", dates: true },
    notifyTo: ["email"],
    notifyEmail: " ",
    retries: 1,
    retryMinutes: 5,
    timeout: 30,
  },
  {
    ...base(),
    title: "Promemoria",
    does: "reminder",
    reminder: "Chiama la nonna",
    starts: ["time"],
    time: { kind: "hours", every: 40 },
    budget: 2,
    model: "x/y",
    session: "continue",
    missed: "run",
    approve: true,
  },
  {
    ...base(),
    title: "Una volta",
    starts: ["time", "message"],
    time: { kind: "once", at: "2026-12-24T18:00" },
    message: { platforms: [], from: "", chat: "123", words: "ciao, buongiorno", handle: false },
    missed: "run",
    whoKey: "p:as1",
    instructions: "Saluta.",
    budget: 0.25,
    only: { ...base().only, dates: true, dateTo: "2027-01-06", maxPerDay: 2 },
  },
].map((draft) => ({
  draft,
  yaml: E.toYaml(draft, "draft-test"),
  sentence: both(() => E.sentence(draft, others)),
}));

const out = {
  $comment: "Generated by tool/automation_vectors.mjs from the page's AutomationEditor.tsx. Do not edit.",
  agents: AGENTS,
  projects: PROJECTS,
  timezone: "UTC",
  crons,
  whens,
  recipes: fromRecipes,
  drafts,
};
writeFileSync(join(here, "../test/fixtures/automation_vectors.json"), `${JSON.stringify(out, null, 2)}\n`);
console.log(`${crons.length} crons, ${whens.length} schedules, ${fromRecipes.length} recipes, ${drafts.length} drafts`);
