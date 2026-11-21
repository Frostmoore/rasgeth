// Writes the page's words of Settings › Extensions (G42.11: Extensions.tsx, MagicExtension.tsx,
// Media.tsx, the bell's proposals) and Settings › Keychain (G42.12: Keychain.tsx,
// KeychainBrowsers.tsx) into the app's ARB files, it and en, never by heart: every `t("…")` of
// those files, every key they name in a ternary or a table, and the families they build at run
// time (`extCat_<kind>`, `media_<kind>`, `mxState_<status>`, `kcCat_<category>`, `kcSys_<kind>`…).
// A page key `x` becomes the ARB key `xt` + `X` for the extensions (`extAdd` → `xtExtAdd`) and
// `vk` + `X` for the keychain (`kcAdd` → `vkKcAdd`), its `{name}` words placeholders. Keys already
// there are updated in place, new ones go at the end; the ARB is read and written as JSON (a
// parser, never text replacements). Then `flutter gen-l10n`.
//
//   node apps/companion/tool/ext_words.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { fillProduct } from "./product.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "../../..");
const web = join(repo, "packages/web/src");

// The page's words, it and en (a value may be split over lines with «+»), as kb_words.mjs.
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
  for (const m of text.matchAll(entry))
    words[lang][m[1]] = fillProduct(new Function(`return ${m[2]};`)());

const groups = [
  {
    prefix: "xt",
    files: ["Extensions.tsx", "MagicExtension.tsx", "Media.tsx"],
    families: ["extCat_", "extAuth_", "media_", "mxState_", "svHow_"],
    extra: [
      // MagicStart and its words (MagicAutomation.tsx), the bell's proposals (Bell.tsx).
      "axMagicStarting",
      "axMagicGo",
      "axMagicExamples",
      "extCatAll",
      "proposals",
      "noProposals",
      "open",
    ],
  },
  {
    prefix: "vk",
    files: ["Keychain.tsx", "KeychainBrowsers.tsx"],
    families: ["kcCat_", "kcSys_", "kcProt_", "kcUse_", "kcAsk_", "kcFormat_"],
    // The pages a key is set in (Keychain.tsx's PAGE_OF).
    extra: ["subscriptions", "telegram", "chats", "automations", "extensions"],
  },
];

const arbKey = (prefix, k) => `${prefix}${k[0].toUpperCase()}${k.slice(1)}`;
const holes = (s) => [...new Set([...s.matchAll(/\{([A-Za-z0-9_]+)\}/g)].map((m) => m[1]))].sort();

const chosen = [];
for (const g of groups) {
  const wanted = new Set(g.extra);
  for (const f of g.files) {
    const text = readFileSync(join(web, "components", f), "utf8");
    for (const m of text.matchAll(/\bt\(\s*"([A-Za-z0-9_]+)"/g)) wanted.add(m[1]);
    // Keys named in a ternary or a table (`t(x ? "extKindTool" : "extKindSkill")`, PAGE_OF).
    for (const m of text.matchAll(/"([A-Za-z0-9_]+)"/g))
      if (/[A-Z_]/.test(m[1]) && m[1] in words.en && m[1] in words.it) wanted.add(m[1]);
  }
  for (const k of Object.keys(words.en))
    if (g.families.some((p) => k.startsWith(p))) wanted.add(k);
  for (const lang of ["it", "en"])
    for (const k of wanted) if (!(k in words[lang])) throw new Error(`no ${lang} word ${k}`);
  chosen.push([g.prefix, wanted]);
}

for (const lang of ["en", "it"]) {
  const file = join(here, `../lib/l10n/app_${lang}.arb`);
  const arb = JSON.parse(readFileSync(file, "utf8"));
  for (const [prefix, wanted] of chosen)
    for (const k of [...wanted].sort()) {
      // A literal `{{vault:name}}` (kcHowHelp) is not a placeholder of the page: the app fills it
      // with `{ref}`, as ICU has no braces without a name.
      const ref = (s) => s.replace(/\{\{[^{}]+\}\}/g, "{ref}");
      const value = ref(words[lang][k]);
      const names = holes(value);
      const other = holes(ref(words[lang === "en" ? "it" : "en"][k]));
      if (names.join() !== other.join()) throw new Error(`${k}: it and en have different words`);
      arb[arbKey(prefix, k)] = value;
      if (lang === "en" && names.length)
        arb[`@${arbKey(prefix, k)}`] = {
          placeholders: Object.fromEntries(names.map((n) => [n, { type: "String" }])),
        };
    }
  writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);
}
console.log(chosen.map(([p, w]) => `${p}: ${w.size} words`).join(", "));
