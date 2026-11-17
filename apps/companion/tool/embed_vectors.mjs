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
  { t: "close" },
  { t: "back", handled: false },
  // Refused:
  { t: "saveAs", name: "a", url: "/x", data: "AA==" },
  { t: "saveAs", name: "a" },
  { t: "saveAs", name: "a", url: "//evil.example/x" },
  { t: "saveAs", name: "", url: "/x" },
  { t: "share", title: "x" },
  { t: "external", url: "javascript:alert(1)" },
  { t: "askAgent", text: "", ref: {} },
  { t: "askAgent", text: "x" },
  { t: "ready", x: 1 },
  { t: "title" },
  { t: "title", name: "a", size: -1 },
  { t: "saveState", state: "lost" },
  { t: "back", handled: "no" },
  { t: "shell" },
  "ready",
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
];
for (const m of appMessages) if (!p.readAppMessage({ rg: "app", m })) throw new Error(`refused: ${JSON.stringify(m)}`);

const out = {
  nonce: NONCE,
  hashes: params.map((x) => ({ params: x, hash: p.embedHash(x) })),
  badHashes,
  envelopes: envelopes.map((raw) => ({ raw, message: p.readEmbedEnvelope(raw, NONCE) })),
  appMessages,
  encode: ["a b/c?d=e&f", "è~!'()*-._", "日本", "+%"].map((s) => ({ s, e: p.formEncode(s) })),
};
writeFileSync(join(here, "../test/fixtures/embed_vectors.json"), `${JSON.stringify(out, null, 2)}\n`);
console.log(`embed vectors: ${out.hashes.length} fragments, ${out.envelopes.length} envelopes`);
