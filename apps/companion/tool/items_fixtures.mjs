// Writes test/fixtures/items_vectors.json (G42.1): the events of the demo's conversation with
// everything (packages/web/scripts/demo-conversation.mjs) as the server sends them, and what the
// page's own `buildItems` (packages/web/src/state.ts) makes of them, so the app's Dart port shows
// exactly the same items. A few small cases apart (`cases`). Deterministic: run it again and the
// file does not change. state.ts is bundled for node with esbuild-wasm (a dependency in the store).
//
//   node apps/companion/tool/items_fixtures.mjs
import { mkdirSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

process.env.TZ = "UTC";
const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "../../..");
const web = join(root, "packages/web");
const tmp = "/mnt/archive1/officina-dati/rg-test/tmp/items-fixtures";
mkdirSync(tmp, { recursive: true });

// The browser bits state.ts touches when loaded: an Italian page with nothing saved.
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
const bundle = join(tmp, "state.mjs");
await esbuild.build({
  stdin: {
    contents:
      'export { buildItems } from "./state.ts"; export { t, lang } from "./i18n.ts"; export { withVoiceHint } from "./voice/speakable.ts";',
    resolveDir: join(web, "src"),
    loader: "ts",
  },
  bundle: true,
  platform: "node",
  format: "esm",
  outfile: bundle,
  logLevel: "error",
  // CSS, pictures and workers the viewers import: nothing buildItems needs.
  loader: { ".css": "empty", ".svg": "empty", ".png": "empty", ".wasm": "empty" },
  jsx: "automatic",
  jsxImportSource: "preact",
  banner: { js: 'import { createRequire } from "node:module"; const require = createRequire(import.meta.url);' },
});
esbuild.stop?.();
const { buildItems, t, lang, withVoiceHint } = await import(`${pathToFileURL(bundle).href}?${Date.now()}`);
lang.value = "it";

const conv = await import(pathToFileURL(join(web, "scripts/demo-conversation.mjs")).href);

const T0 = Date.parse("2026-11-17T09:00:00.000Z");
/** Events as the server sends them: ids, seqs from `first`, fixed times one second apart. */
const envelope = (bodies, { sessionId, agentId = "agent_dev", first = 1 }) =>
  bodies.map((b, i) => ({
    id: `evt_${String(first + i).padStart(4, "0")}`,
    seq: first + i,
    ts: new Date(T0 + (first + i) * 1000).toISOString(),
    ownerId: "local",
    projectId: "demo",
    agentId,
    sessionId,
    type: b.type,
    payload: b.payload,
    erased: b.payload === null,
  }));
const items = (events) => JSON.parse(JSON.stringify(buildItems(events)));

const sessionId = "sess_conv000001";
const child = { sessionId: "sess_tester00001", agentId: "agent_tester" };
const events = envelope(
  conv.conversationEvents({
    agentId: "agent_dev",
    sessionId,
    firstSeq: 1,
    startAt: "2026-11-17T09:00:00.000Z",
    withStart: true,
    child,
  }),
  { sessionId },
);

// The fork: the origin up to the edited message, then its own events (what session.follow sends).
const edited = events.findLast((e) => e.type === "message.user" && !e.payload.from);
const forkId = "sess_fork000001";
const forkOwn = envelope(
  [
    {
      type: "session.forked",
      payload: {
        fromSessionId: sessionId,
        throughSeq: edited.seq - 1,
        fromTitle: "Il login di Bottega non funziona",
        how: "edit",
      },
    },
    ...conv.forkEvents(),
  ],
  { sessionId: forkId, first: 1001 },
);
const forkLog = [...events.filter((e) => e.seq < edited.seq), ...forkOwn];

// ---------- Small cases ----------

const metrics = {
  startedAt: "2026-11-17T09:00:00.000Z",
  endedAt: "2026-11-17T09:00:02.000Z",
  inputTokens: 1200,
  cachedReadTokens: 1000,
  cacheWriteTokens: 0,
  outputTokens: 40,
  contextUsed: 1240,
  contextWindow: 200000,
  source: "client",
};
const said = (text, stopReason = "end_turn", extra = []) => ({
  type: "message.assistant",
  payload: {
    parts: [{ type: "text", text }, ...extra],
    stopReason,
    provider: "anthropic",
    model: "claude-opus-5-5",
    metrics,
    costUsd: 0.001,
  },
});
const toolCall = (callId, name, input) => ({
  type: "tool_call",
  callId,
  name,
  input,
  rawInput: JSON.stringify(input),
});
const user = (text, extra = {}) => ({ type: "message.user", payload: { text, ...extra } });
const caseOf = (name, bodies) => {
  const ev = envelope(bodies, { sessionId: `sess_case_${name}` });
  return { name, events: ev, items: items(ev) };
};

const cases = [
  caseOf("erased", [
    user("Il mio codice fiscale è RSSMRA80A01H501U"),
    { type: "message.user", payload: null },
    said("Ricevuto."),
  ]),
  caseOf("same-call-id", [
    user("Fai due cose."),
    said("Due comandi.", "tool_use", [
      toolCall("dup", "bash", { command: "echo uno" }),
      toolCall("dup", "bash", { command: "echo due" }),
    ]),
    { type: "tool.call", payload: { callId: "dup", tool: "bash", input: { command: "echo uno" } } },
    { type: "tool.call", payload: { callId: "dup", tool: "bash", input: { command: "echo due" } } },
    { type: "tool.result", payload: { callId: "dup", ok: true, output: "Exit code: 0\nstdout:\nuno\n" } },
    { type: "tool.result", payload: { callId: "dup", ok: true, output: "Exit code: 0\nstdout:\ndue\n" } },
    said("Fatto."),
  ]),
  caseOf("lost-result", [
    user("Compila il progetto."),
    said("Compilo.", "tool_use", [toolCall("c1", "bash", { command: "pnpm build" })]),
    { type: "tool.call", payload: { callId: "c1", tool: "bash", input: { command: "pnpm build" } } },
    said("Ho fermato la compilazione come mi hai chiesto.", "aborted"),
  ]),
  (() => {
    const ev = envelope(
      [
        user("Riassumi tutto."),
        said("Ecco il riassunto."),
        {
          type: "compaction",
          payload: { summary: "La persona ha chiesto un riassunto.", fromSeq: 1, toSeq: 2, reason: "manual" },
        },
      ],
      { sessionId: "sess_case_compaction" },
    );
    const before = items(ev);
    const undone = [
      ...ev,
      ...envelope([{ type: "compaction.undone", payload: { compactionSeq: 3 } }], {
        sessionId: "sess_case_compaction",
        first: 4,
      }),
    ];
    return {
      name: "compaction-undoable-then-undone",
      events: undone,
      items: items(undone),
      // The same log before the undo: the summary can be undone.
      itemsBeforeUndo: before,
    };
  })(),
  caseOf("variants", [
    user("Fammi tre versioni della pagina di accesso."),
    {
      type: "variants.proposed",
      payload: {
        proposalId: "prop_1",
        title: "Pagina di accesso",
        description: "Tre stili",
        variants: [
          { title: "Chiara", bytes: 2100 },
          { title: "Scura", note: "Per la sera", bytes: 2300 },
          { title: "Minima", bytes: 1500 },
        ],
      },
    },
    { type: "variants.answered", payload: { proposalId: "prop_1", variant: 2, choice: true } },
  ]),
  caseOf("imported", [
    {
      type: "session.imported",
      payload: { source: "chatgpt", title: "Ricette", messages: 2, originalId: "abc" },
    },
    user("Una ricetta con le zucchine?"),
    {
      type: "message.assistant",
      payload: {
        parts: [{ type: "text", text: "Zucchine trifolate: aglio, olio e prezzemolo." }],
        stopReason: "end_turn",
        provider: "import:chatgpt",
        model: "gpt-4o",
        metrics,
        costUsd: 0,
      },
    },
  ]),
  caseOf("permissions", [
    user("Installa le dipendenze."),
    said("Installo.", "tool_use", [toolCall("p1", "bash", { command: "npm install" })]),
    { type: "tool.call", payload: { callId: "p1", tool: "bash", input: { command: "npm install" } } },
    {
      type: "permission.requested",
      payload: { requestId: "r1", callId: "p1", reason: "Runs a command", askedTo: "human" },
    },
    { type: "permission.resolved", payload: { requestId: "r1", decision: "allow", by: "human", via: "web" } },
    { type: "tool.result", payload: { callId: "p1", ok: true, output: "Exit code: 0\nstdout:\nadded 12 packages\n" } },
    {
      type: "permission.requested",
      payload: { requestId: "r2", callId: "p2", reason: "Deletes files", askedTo: "orchestrator_1" },
    },
    { type: "permission.resolved", payload: { requestId: "r2", decision: "deny", by: "orchestrator_1" } },
    { type: "permission.resolved", payload: { requestId: "r3", decision: "escalate", by: "orchestrator_1" } },
  ]),
  caseOf("voice", [
    user(withVoiceHint("che ore sono a Roma adesso"), { via: "voice" }),
    said("Sono le 10:30."),
  ]),
  // 3.8.7: an answer's ```widget blocks become widgets right after it (an open one stays code),
  // also after an answer that asks for tools.
  caseOf("widgets", [
    user("Fammi vedere l'umidità e la temperatura."),
    said("Leggo i sensori.\n```widget Sensori\n<p>in lettura</p>\n```", "tool_use", [
      toolCall("w1", "bash", { command: "sensors" }),
    ]),
    { type: "tool.call", payload: { callId: "w1", tool: "bash", input: { command: "sensors" } } },
    { type: "tool.result", payload: { callId: "w1", ok: true, output: "Exit code: 0\nstdout:\n60% 21C\n" } },
    said(
      "Ecco:\n```widget Umidità\n<b>60%</b>\n```\nE la temperatura:\n```widget\n<i>21</i>\n```\n```widget Aperto\n<p>non chiuso",
    ),
  ]),
];

const out = {
  words: { toolNoResult: t("toolNoResult") },
  events,
  items: items(events),
  fork: { sessionId: forkId, events: forkLog, items: items(forkLog) },
  cases,
};
const file = join(here, "../test/fixtures/items_vectors.json");
mkdirSync(dirname(file), { recursive: true });
writeFileSync(file, `${JSON.stringify(out, null, 2)}\n`);
const kinds = new Set([...out.items, ...out.fork.items, ...cases.flatMap((c) => c.items)].map((i) => i.kind));
console.log(`${file}: ${events.length} events, ${out.items.length} items; kinds: ${[...kinds].sort().join(", ")}`);
