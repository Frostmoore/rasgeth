// Writes test/fixtures/parallel_vectors.json (G42.3): conversations with sub-agents and background
// commands, and what the page's own `subagentTabs`, `subStatus` and `commandRows`
// (packages/web/src/state.ts) make of them, so the app's Dart port (lib/api/parallel.dart) shows
// the same tabs and the same strip. Deterministic. state.ts is bundled for node with esbuild-wasm,
// found in this repo's store or in the one $RG_MODULES points to (a built worktree's node_modules).
//
//   node apps/companion/tool/parallel_fixtures.mjs
import { existsSync, mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

process.env.TZ = "UTC";
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "../../..");
const web = join(root, "packages/web");
const tmp = "/mnt/archive1/officina-dati/rg-test/tmp/parallel-fixtures";
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

const modules = [process.env.RG_MODULES, join(root, "node_modules")].find(
  (m) => m && existsSync(join(m, ".pnpm")),
);
if (!modules) throw new Error("no node_modules/.pnpm: run pnpm install or set RG_MODULES");
const pnpm = join(modules, ".pnpm");
const wasm = readdirSync(pnpm).find((d) => d.startsWith("esbuild-wasm@"));
if (!wasm) throw new Error("esbuild-wasm is not in node_modules/.pnpm");
const esbuild = (await import(pathToFileURL(join(pnpm, wasm, "node_modules/esbuild-wasm/lib/main.js")).href))
  .default;
const bundle = join(tmp, "state.mjs");
await esbuild.build({
  stdin: {
    contents: 'export { subagentTabs, subStatus, commandRows } from "./state.ts";',
    resolveDir: join(web, "src"),
    loader: "ts",
  },
  bundle: true,
  platform: "node",
  format: "esm",
  outfile: bundle,
  logLevel: "error",
  // The page's own dependencies sit in its package's node_modules (pnpm's links).
  nodePaths: [join(dirname(modules), "packages/web/node_modules"), modules],
  loader: { ".css": "empty", ".svg": "empty", ".png": "empty", ".wasm": "empty" },
  jsx: "automatic",
  jsxImportSource: "preact",
  banner: { js: 'import { createRequire } from "node:module"; const require = createRequire(import.meta.url);' },
});
esbuild.stop?.();
const { subagentTabs, subStatus, commandRows } = await import(`${pathToFileURL(bundle).href}?${Date.now()}`);

const T0 = Date.parse("2026-11-17T09:00:00.000Z");
const envelope = (bodies, sessionId = "sess_main") =>
  bodies.map((b, i) => ({
    id: `evt_${String(i + 1).padStart(4, "0")}`,
    seq: i + 1,
    ts: new Date(T0 + (i + 1) * 1000).toISOString(),
    ownerId: "local",
    projectId: "demo",
    agentId: "agent_god",
    sessionId,
    type: b.type,
    payload: b.payload ?? null,
    erased: b.payload === null,
  }));
const started = (child, agent, via, title, task = `Il compito di ${title}.`) => ({
  type: "subagent.started",
  payload: { childSessionId: child, childAgentId: agent, callId: `call_${child}`, via, title, task },
});
const ended = (child, status, summary) => ({
  type: "subagent.ended",
  payload: { childSessionId: child, status, ...(summary && { summary }) },
});
const cmd = (id, command) => ({
  type: "command.started",
  payload: { id, command, file: `/data/${id}.log`, path: "/workspace", cwd: "/workspace/app", by: "Coder" },
});
const cmdEnd = (id, status, exitCode) => ({ type: "command.ended", payload: { id, status, exitCode } });

const cases = {
  // Three sub-agents: one at work, one finished, one failed; a tab closed by the person.
  three: [
    { type: "session.started", payload: { agentId: "agent_god" } },
    { type: "message.user", payload: { text: "Prepara il rilascio" } },
    started("sess_a", "agent_tester", "run_subagent", "Prove"),
    started("sess_b", "agent_dev", "delegate", "Login"),
    started("sess_c", "agent_research", "run_subagents", "Ricerca"),
    ended("sess_b", "done", "Fatto: il login funziona."),
    ended("sess_c", "failed"),
    { type: "subagent.closed", payload: { childSessionId: "sess_c" } },
  ],
  // A persistent agent given work twice: the tab follows the newest task and opens again.
  reused: [
    started("sess_p", "agent_dev", "delegate", "Prima"),
    ended("sess_p", "done", "ok"),
    { type: "subagent.closed", payload: { childSessionId: "sess_p" } },
    started("sess_p", "agent_dev", "delegate", "Seconda"),
    { type: "subagent.ended", payload: { childSessionId: "sess_other", status: "stopped" } },
  ],
  // An erased event and an end for a tab never started change nothing.
  quiet: [{ type: "subagent.started", payload: null }, ended("sess_none", "done")],
  // Background commands: running, done, failed, stopped, interrupted, one taken off the strip.
  commands: [
    cmd("c1", "npm run dev"),
    cmd("c2", "pnpm test"),
    cmd("c3", "pnpm build --filter web"),
    cmd("c4", "python -m http.server 8000"),
    cmd("c5", "make long"),
    cmdEnd("c2", "done", 0),
    cmdEnd("c3", "failed", 2),
    cmdEnd("c4", "stopped", null),
    cmdEnd("c5", "interrupted", null),
    { type: "command.closed", payload: { id: "c4" } },
    cmdEnd("c9", "done", 0),
  ],
};

const out = {};
for (const [name, bodies] of Object.entries(cases)) {
  const events = envelope(bodies);
  const tabs = subagentTabs(events);
  out[name] = {
    events,
    tabs: JSON.parse(JSON.stringify(tabs)),
    status: tabs.map((tab) => [
      subStatus(tab, false, false),
      subStatus(tab, true, false),
      subStatus(tab, false, true),
    ]),
    commands: JSON.parse(JSON.stringify(commandRows(events))),
  };
}
const file = join(here, "../test/fixtures/parallel_vectors.json");
writeFileSync(file, `${JSON.stringify(out, null, 2)}\n`);
console.log(`parallel_vectors.json: ${Object.keys(out).length} cases`);
