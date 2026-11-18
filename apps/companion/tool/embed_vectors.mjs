// Writes test/fixtures/embed_vectors.json from the page's own rules (packages/protocol/src/embed.ts,
// built): fragments as `embedHash` writes them and as `parseEmbedHash` reads them, the bridge's
// envelopes as `readEmbedEnvelope` takes or refuses them, and the app's messages as
// `readAppMessage` does. test/embed_link_test.dart and test/bridge_test.dart check the app's Dart
// against them (G42.0).
//
//   pnpm build && node apps/companion/tool/embed_vectors.mjs
import { writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const p = await import(
  pathToFileURL(join(here, "../../../packages/protocol/dist/embed.js")).href
);

const NONCE = "n0nce-n0nce_n0nce";
const base = { token: "rgd_abc123", bridge: NONCE, theme: "dark", lang: "it" };
const params = [
  { ...base, embed: "canvas", scope: "p1", path: "src/a b.ts", line: 12, session: "s1" },
  { ...base, theme: "light", lang: "en", embed: "canvas", scope: "outside", path: "Doc/è.pdf", page: 3 },
  { ...base, embed: "canvas", scope: "p1", path: "日本/a+b%.md" },
  { ...base, embed: "port", agent: "a-1", port: 5173, path: "/app?x=1" },
  { ...base, embed: "board", board: "s_1.0123456789ab" },
  { ...base, embed: "board", board: "s_1.0123456789ab", variant: 3, screen: "tablet" },
  { ...base, embed: "probe", font: "Inter, sans-serif" },
  { ...base, token: "a~b!c'(d)*e", embed: "probe" },
];
const badHashes = [
  "token=x&open=settings",
  "token=x&embed=shell&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it&extra=1",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it&theme=light",
  "embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it",
  "token=x&embed=probe&bridge=short&theme=dark&lang=it",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=blue&lang=it",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=de",
  "token=x&embed=canvas&bridge=n0nce-n0nce_n0nce&scope=p&theme=dark&lang=it",
  "token=x&embed=port&bridge=n0nce-n0nce_n0nce&agent=a&theme=dark&lang=it",
  "token=x&embed=port&bridge=n0nce-n0nce_n0nce&agent=a&port=70000&theme=dark&lang=it",
  "token=x&embed=canvas&bridge=n0nce-n0nce_n0nce&scope=p&path=a&line=-1&theme=dark&lang=it",
  "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.xyz&theme=dark&lang=it",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&scope=p&theme=dark&lang=it",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it&font=a%7Bb",
  "token=a+b&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it",
  "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&variant=9&theme=dark&lang=it",
  "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&variant=0&theme=dark&lang=it",
  "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&variant=1&theme=dark&lang=it",
  "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&screen=phone&theme=dark&lang=it",
  "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&variant=1&screen=tv&theme=dark&lang=it",
];
for (const h of badHashes) if (p.parseEmbedHash(h) !== null) throw new Error(`taken: ${h}`);

const env = (n, m) => JSON.stringify({ rg: "embed", n, m });
const pageMessages = [
  { t: "ready" },
  { t: "title", name: "a.xlsx", kind: "sheet", size: 2048 },
  { t: "title", name: "b" },
  { t: "saveState", state: "saving" },
  { t: "saveState", state: "error", error: "disk full" },
  { t: "saveAs", name: "a.pdf", url: "/api/files/raw?x=1" },
  { t: "saveAs", name: "a.txt", data: "aGVsbG8=", mime: "text/plain" },
  { t: "openFile", id: "f1", accept: [".png"], multiple: true },
  { t: "copy", text: "x" },
  { t: "share", url: "https://example.com/a" },
  { t: "share", title: "t", text: "words" },
  { t: "askAgent", text: "why this?", ref: { scope: "p", path: "a.ts", line: 3, lineEnd: 5 } },
  { t: "askAgent", text: "page", ref: { page: 2 } },
  { t: "external", url: "https://example.com" },
  { t: "previewLink", url: "https://example.com/a?b=1" },
  { t: "close" },
  { t: "back", handled: false },
  {
    t: "bar",
    actions: [
      { id: "art.app", label: "App", icon: "play", on: true },
      { id: "art.run", label: "Esegui", primary: true, hint: "Mai eseguito" },
      { id: "copy.edit", label: "Modifica una copia", icon: "pencil", disabled: true },
    ],
    note: "L'agente è andato a pagina 3",
    link: "/api/canvas/raw/abc?v=1",
    download: true,
  },
  { t: "bar", actions: [] },
  { t: "open", title: "a.odt", target: { kind: "file", scope: "p1", path: "a.odt" } },
  { t: "open", title: "a.pdf", target: { kind: "file", scope: "p1", path: "a.pdf", at: { page: 2 } } },
  { t: "open", title: "Sito", target: { kind: "port", agentId: "a1", port: 5173, path: "/x" } },
  // The editors (G42.7):
  { t: "saveState", state: "saved" },
  { t: "saveAs", name: "foto.png", data: "iVBORw0KGgo=", mime: "image/png" },
  { t: "askAgent", text: "riga\naltra", ref: { scope: "project:p1", path: "src/a.ts", line: 4, lineEnd: 9 } },
  { t: "bar", actions: [{ id: "ask", label: "Chiedi all'agente", icon: "chat", primary: true }] },
  { t: "bar", actions: [], paste: true },
  { t: "bar", actions: [], readOnly: true, download: true },
  // Refused:
  { t: "saveAs", name: "a", url: "/x", data: "AA==" },
  { t: "saveAs", name: "a" },
  { t: "saveAs", name: "a", url: "//evil.example/x" },
  { t: "saveAs", name: "", url: "/x" },
  { t: "share", title: "x" },
  { t: "external", url: "javascript:alert(1)" },
  { t: "previewLink", url: "file:///etc/passwd" },
  { t: "askAgent", text: "", ref: {} },
  { t: "askAgent", text: "x" },
  { t: "ready", x: 1 },
  { t: "title" },
  { t: "title", name: "a", size: -1 },
  { t: "saveState", state: "lost" },
  { t: "back", handled: "no" },
  { t: "shell" },
  "ready",
  { t: "bar", actions: [{ id: "A b", label: "x" }] },
  { t: "bar", actions: [{ id: "a", label: "" }] },
  { t: "bar", actions: [{ id: "a", label: "x", icon: "bomb" }] },
  { t: "bar", actions: Array.from({ length: 13 }, (_, i) => ({ id: `a${i}`, label: "x" })) },
  { t: "bar", actions: [], link: "https://evil.example/x" },
  { t: "bar", actions: [{ id: "a", label: "x", on: "yes" }] },
  { t: "bar" },
  { t: "open", title: "x" },
  { t: "open", title: "x", target: { kind: "shell" } },
  { t: "open", title: "x", target: { kind: "file", scope: "p" } },
  { t: "open", title: "x", target: { kind: "file", scope: "p", path: "a", at: { page: 0 } } },
  { t: "open", title: "x", target: { kind: "port", agentId: "a", port: "80" } },
  { t: "saveState", state: "unsaved" },
  { t: "saveState", state: "error", error: "x".repeat(501) },
  { t: "askAgent", text: "x".repeat(20001), ref: {} },
  { t: "askAgent", text: "x", ref: { line: -1 } },
  { t: "askAgent", text: "x", ref: { file: "a" } },
  { t: "saveAs", name: "a.png", data: "not base64!" },
  { t: "saveAs", name: "x".repeat(256), url: "/x" },
  { t: "bar", actions: [], paste: "yes" },
  { t: "bar", actions: [], readOnly: 1 },
];
const envelopes = [
  ...pageMessages.map((m) => env(NONCE, m)),
  env("another-nonce-123", { t: "ready" }),
  JSON.stringify({ rg: "app", n: NONCE, m: { t: "ready" } }),
  "not json",
  "[1,2]",
];

const appMessages = [
  { t: "theme", theme: "light" },
  { t: "lang", lang: "en" },
  { t: "font", family: "Inter, sans-serif" },
  { t: "back" },
  { t: "key", key: "save" },
  { t: "key", key: "redo" },
  { t: "files", id: "f1", files: [{ name: "a.png", type: "image/png", size: 3, data: "AAAA" }] },
  { t: "paste", text: "hello" },
  { t: "action", id: "art.source" },
  {
    t: "tabs",
    visible: true,
    tabs: [
      { title: "a.pdf", target: { kind: "file", scope: "p1", path: "a.pdf" }, active: true },
      { title: "Sito", target: { kind: "port", agentId: "a1", port: 5173 }, active: false },
    ],
  },
  { t: "tabs", visible: false, tabs: [] },
  // The editors (G42.7): a picture pasted from the system's clipboard, «Ask the agent».
  { t: "paste", files: [{ name: "pasted-2026-11-18-101500.png", type: "image/png", size: 8, data: "iVBORw0KGgo=" }] },
  { t: "paste", text: "hi", files: [] },
  { t: "action", id: "ask" },
  { t: "key", key: "undo" },
];
for (const m of appMessages) if (!p.readAppMessage({ rg: "app", m })) throw new Error(`refused: ${JSON.stringify(m)}`);
const png = { name: "a.png", type: "image/png", size: 3, data: "AAAA" };
const badAppMessages = [
  { t: "paste", files: [{ ...png, size: 25 * 1024 * 1024 + 1 }] },
  { t: "paste", files: [{ ...png, data: "%%" }] },
  { t: "paste", files: [{ ...png, name: "" }] },
  { t: "paste", files: Array(21).fill(png) },
  { t: "paste", image: "AAAA" },
  { t: "paste", text: 3 },
  { t: "key", key: "quit" },
  { t: "action", id: "Ask" },
  { t: "files", files: [{ ...png, extra: 1 }] },
];
for (const m of badAppMessages) if (p.readAppMessage({ rg: "app", m })) throw new Error(`taken: ${JSON.stringify(m)}`);

const out = {
  nonce: NONCE,
  hashes: params.map((x) => ({ params: x, hash: p.embedHash(x) })),
  badHashes,
  envelopes: envelopes.map((raw) => ({ raw, message: p.readEmbedEnvelope(raw, NONCE) })),
  appMessages,
  badAppMessages,
  boardScreens: p.BOARD_SCREENS,
  boardVariantsMax: p.BOARD_VARIANTS_MAX,
  encode: ["a b/c?d=e&f", "è~!'()*-._", "日本", "+%"].map((s) => ({ s, e: p.formEncode(s) })),
};
writeFileSync(join(here, "../test/fixtures/embed_vectors.json"), `${JSON.stringify(out, null, 2)}\n`);
console.log(`embed vectors: ${out.hashes.length} fragments, ${out.envelopes.length} envelopes`);
