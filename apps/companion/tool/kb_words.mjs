// Writes the page's words of Settings › Knowledge and Shared memory into the app's ARB files
// (G42.10), it and en, never by heart: every `t("…")` of Knowledge.tsx, KnowledgeFiles.tsx,
// AgentKnowledge.tsx, SharedMemory.tsx, AgentMemory.tsx and CompactionSettings.tsx, the families
// they build at run time (`kbKind_<kind>`, `kbErr_<code>`, `memDid_<action>`…), the citation words
// of markdown.ts and the knowledge's downloads (`job_download_knowledge_model`…). Each page key
// `x` becomes the ARB key `kn` + `X` (`kbStateReady` → `knKbStateReady`), its `{name}` words
// placeholders. Keys already there are updated in place, new ones go at the end; the ARB is read
// and written as JSON (a parser, never text replacements). Then `flutter gen-l10n`.
//
//   node apps/companion/tool/kb_words.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "../../..");
const web = join(repo, "packages/web/src");

// The page's words, it and en (a value may be split over lines with «+»), as general_words.mjs.
const src = readFileSync(join(web, "i18n.ts"), "utf8");
const itAt = src.indexOf("\nconst it:");
const parts = { en: src.slice(0, itAt), it: src.slice(itAt) };
const lit = String.raw`(?:"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')`;
const entry = new RegExp(
  String.raw`^ {2}([A-Za-z0-9_]+):\s*\n?\s*(${lit}(?:\s*\+\s*\n?\s*${lit})*),?$`,
  "gm",
);
const words = { it: {}, en: {} };
for (const [lang, text] of Object.entries(parts))
  for (const m of text.matchAll(entry)) words[lang][m[1]] = new Function(`return ${m[2]};`)();

const files = [
  "Knowledge.tsx",
  "KnowledgeFiles.tsx",
  "AgentKnowledge.tsx",
  "SharedMemory.tsx",
  "AgentMemory.tsx",
  "CompactionSettings.tsx",
];
// Words the app has already under its own names.
const skip = new Set(["cancel", "save"]);
const wanted = new Set();
for (const f of files) {
  const text = readFileSync(join(web, "components", f), "utf8");
  for (const m of text.matchAll(/\bt\(\s*"([A-Za-z0-9_]+)"/g)) if (!skip.has(m[1])) wanted.add(m[1]);
}
// The families built at run time, and the words of the citations and the downloads.
const families = [
  "kbKind_",
  "kbKindText_",
  "kbMeaningOff_",
  "kbProv_",
  "kbSrcState_",
  "kbWhy_",
  "kbErr_",
  "err_memory_",
  "memDid_",
  "memUndid_",
];
for (const k of Object.keys(words.en)) if (families.some((p) => k.startsWith(p))) wanted.add(k);
for (const k of [
  "kbPage",
  "kbLines",
  "kbLine",
  "kbCiteFallback",
  "kbMail",
  "kbChat",
  "job_download_knowledge_model",
  "job_download_ocr",
  "job_download_pgvector",
  "job_step_tool_download",
  "job_step_model_download",
  "job_step_ocr_program",
  "job_step_ocr_languages",
  "job_error_checksum",
  "job_error_pgvector_unavailable",
  // The bar's words (ui.tsx `progressText`, `timeLeft`).
  "uiOf",
  "uiLessThanMinute",
  "uiAboutMinutes",
  "uiAboutHours",
])
  wanted.add(k);
for (const lang of ["it", "en"])
  for (const k of wanted) if (!(k in words[lang])) throw new Error(`no ${lang} word ${k}`);

const arbKey = (k) => `kn${k[0].toUpperCase()}${k.slice(1)}`;
const holes = (s) => [...new Set([...s.matchAll(/\{([A-Za-z0-9_]+)\}/g)].map((m) => m[1]))].sort();

for (const lang of ["en", "it"]) {
  const file = join(here, `../lib/l10n/app_${lang}.arb`);
  const arb = JSON.parse(readFileSync(file, "utf8"));
  for (const k of [...wanted].sort()) {
    const value = words[lang][k];
    const names = holes(value);
    const other = holes(words[lang === "en" ? "it" : "en"][k]);
    if (names.join() !== other.join()) throw new Error(`${k}: it and en have different words`);
    arb[arbKey(k)] = value;
    if (lang === "en" && names.length)
      arb[`@${arbKey(k)}`] = {
        placeholders: Object.fromEntries(names.map((n) => [n, { type: "String" }])),
      };
  }
  writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);
}
console.log(`${wanted.size} words`);
