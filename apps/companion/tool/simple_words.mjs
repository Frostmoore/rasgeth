// Writes the simple interface's words (3.12) into lib/l10n/app_it.arb and app_en.arb from the
// page's own packages/web/src/i18n.ts (`smp…`, `ui…`, `wzLook…`), it and en, never by heart; the
// ARB keys keep the page's names. `{product}` is filled with the name, other `{x}` stay
// placeholders. Then `flutter gen-l10n` writes the Dart.
//
//   node apps/companion/tool/simple_words.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { fillProduct } from "./product.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "../../..");
const src = readFileSync(join(repo, "packages/web/src/i18n.ts"), "utf8");
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

const wanted = Object.keys(words.en).filter(
  (k) => /^(smp[A-Z]|wzLook|ui(Title|Help|Simple|Full)$)/.test(k) && k in words.it,
);
if (wanted.length < 60) throw new Error(`only ${wanted.length} words found`);

for (const lang of ["it", "en"]) {
  const file = join(here, `../lib/l10n/app_${lang}.arb`);
  const arb = JSON.parse(readFileSync(file, "utf8"));
  for (const k of wanted) {
    const text = words[lang][k];
    arb[k] = text;
    if (lang === "en") {
      const names = [...new Set([...text.matchAll(/\{(\w+)\}/g)].map((m) => m[1]))];
      if (names.length)
        arb[`@${k}`] = {
          placeholders: Object.fromEntries(names.map((n) => [n, { type: "String" }])),
        };
      else delete arb[`@${k}`];
    }
  }
  writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);
}
console.log(`${wanted.length} words`);
