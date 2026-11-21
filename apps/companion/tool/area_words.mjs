// Writes the page's words of Settings › Telegram, Chats and the mailboxes (G42.13, prefix `ch`)
// and of Settings › Models and subscriptions (G42.15, prefix `mo`) into the app's ARB files, it
// and en, never by heart: every word key the listed page files name (in `t("…")` and in their
// tables of keys, like ChatPlatforms' FIELDS and STEPS), the families they build at run time
// (`effort_<x>`, `lmEngine_<v>`, `axCat_<c>`…) and a few more. Each page key `x` becomes the ARB
// key prefix + `X` (`wzTgStep1` → `chWzTgStep1`), its `{name}` words placeholders. Keys already
// there are updated in place, new ones go at the end; the ARB is read and written as JSON (a
// parser, never text replacements). Then `flutter gen-l10n`.
//
//   node apps/companion/tool/area_words.mjs
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

const areas = [
  {
    prefix: "ch",
    files: ["SetupTelegram.tsx", "Telegram.tsx", "ChatPlatforms.tsx", "EmailSettings.tsx"],
    families: ["axCat_"],
    extra: ["chats", "telegram", "unlink", "remove", "emailTitle", "uiAdvanced"],
  },
  {
    prefix: "mo",
    files: [
      "ModelsPage.tsx",
      "Brain.tsx",
      "SetupAssign.tsx",
      "LocalModels.tsx",
      "ModelSelect.tsx",
      "ModelMenu.tsx",
      "ModelsCatalogRow.tsx",
    ],
    families: ["effort_", "lmEngine_", "wzEffort_", "lmQuality_", "lmScore_", "lmSpeedMode_"],
    extra: [
      "subscriptions",
      "modelSearch",
      "uiDropNone",
      "modelNew",
      "modelUnconfirmed",
      "job_model_download",
      "job_engine",
      "job_engine_load",
      "job_speed_test",
      ...["image", "start", "load", "try", "tune", "none", "draft", "ngram", "preload"].map(
        (s) => `job_step_${s}`,
      ),
      "job_step_model_download",
      ...[
        "out_of_memory",
        "model_missing",
        "no_gpu",
        "bad_file",
        "load_timeout",
        "engine_stopped",
        "checksum",
        "incomplete",
      ].map((e) => `job_error_${e}`),
      "wzBrainQ",
      "uiOf",
      "uiLessThanMinute",
      "uiAboutMinutes",
      "uiAboutHours",
    ],
  },
];
// Literals that happen to be word keys but are not words of these screens.
const skip = new Set(["cancel", "save", "close", "model", "on", "off", "url", "token", "number"]);

const holes = (s) => [...new Set([...s.matchAll(/\{([A-Za-z0-9_]+)\}/g)].map((m) => m[1]))].sort();
const arbs = Object.fromEntries(
  ["en", "it"].map((lang) => {
    const file = join(here, `../lib/l10n/app_${lang}.arb`);
    return [lang, { file, arb: JSON.parse(readFileSync(file, "utf8")) }];
  }),
);
for (const a of areas) {
  const wanted = new Set();
  for (const f of a.files) {
    const text = readFileSync(join(web, "components", f), "utf8");
    for (const m of text.matchAll(/"([A-Za-z][A-Za-z0-9_]+)"/g))
      if (!skip.has(m[1]) && m[1] in words.en && m[1] in words.it) wanted.add(m[1]);
  }
  for (const k of Object.keys(words.en))
    if (a.families.some((p) => k.startsWith(p)) && k in words.it) wanted.add(k);
  for (const k of a.extra) if (k in words.en && k in words.it) wanted.add(k);
  const key = (k) => `${a.prefix}${k[0].toUpperCase()}${k.slice(1)}`;
  for (const lang of ["en", "it"]) {
    const { arb } = arbs[lang];
    for (const k of [...wanted].sort()) {
      const value = words[lang][k];
      const names = holes(value);
      const other = holes(words[lang === "en" ? "it" : "en"][k]);
      if (names.join() !== other.join()) throw new Error(`${k}: it and en have different words`);
      arb[key(k)] = value;
      if (lang === "en" && names.length)
        arb[`@${key(k)}`] = {
          placeholders: Object.fromEntries(names.map((n) => [n, { type: "String" }])),
        };
    }
  }
  console.log(`${a.prefix}: ${wanted.size} words`);
}
for (const { file, arb } of Object.values(arbs)) writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);
