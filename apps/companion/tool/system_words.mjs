// Writes the page's words of the system's settings (G42.14, prefix `sy`): access from outside home
// (RemoteSettings, RemoteAccess, OwnInfra, Pihole), Settings › System (FirstBoot, OsSystem), the
// mandatory and breaking updates (UpdateGate), SSH machines, nodes, backups and their
// destinations, into the app's ARB files, it and en, never by heart: every word key the listed
// page files name, the families they build at run time (`fbMissing_<x>`, `osErr_<code>`,
// `job_step_<id>`…) and a few more. Each page key `x` becomes `sy` + `X` (`mcTitle` → `syMcTitle`),
// its `{name}` words placeholders (sorted). Keys already there are updated in place, new ones go at
// the end; the ARB is read and written as JSON (a parser, never text replacements). It also writes
// `lib/settings/system/system_words.g.dart`: the page's key to the word, for the families. Then
// `flutter gen-l10n`.
//
//   node apps/companion/tool/system_words.mjs
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

const prefix = "sy";
const files = [
  "RemoteSettings.tsx",
  "RemoteAccess.tsx",
  "OwnInfra.tsx",
  "Pihole.tsx",
  "FirstBoot.tsx",
  "OsSystem.tsx",
  "UpdateGate.tsx",
  "Machines.tsx",
  "Nodes.tsx",
  "Backup.tsx",
  "BackupTargets.tsx",
  "Emulators.tsx",
  "EmulatorInstall.tsx",
  "DeviceScreen.tsx",
];
const families = [
  "fbMissing_",
  "fbMethod_",
  "fbSshWhy_",
  "fbErr_",
  "fbHostBad_",
  "osWifiWhy_",
  "osHttpsHow_",
  "osUpd_",
  "osErr_",
  "oiProbe",
  "err_",
  "dsState_",
];
// Jobs this area follows: their titles and their steps.
const jobs = ["remote", "pihole", "backup", "import", "restore", "safety_backup", "proxmox_mount"];
const extra = [
  "wzRemote",
  "fbSystemSection",
  "mcSection",
  "ndSection",
  "emSection",
  "backup",
  "remove",
  "cancel",
  "wzBack",
  "save",
  "uiDone",
  "uiNotNeeded",
  "uiAdvanced",
  "updLooking",
  "updLook",
  "loginCode",
  "lmRecommended",
  "wzRecommended",
  "brainDisconnect",
  "tgQr",
  "gitGiteaAgain",
  "gitGiteaMismatch",
  "kcPassphrase",
  "kcPassphraseHelp",
  "kcImported",
  "wzCpu",
  "wzThreads",
  "wzMemory",
  "wzGpu",
  "wzNoGpu",
  "wzFree",
  "wzStorage",
  "gitGiteaGuide",
  "screenTake",
  "screenGiveBack",
  "screenStarting",
];
// Literals that happen to be word keys but are not words of these screens.
const skip = new Set(["close", "model", "on", "off", "url", "token", "number", "name", "path"]);

const holes = (s) => [...new Set([...s.matchAll(/\{([A-Za-z0-9_]+)\}/g)].map((m) => m[1]))].sort();
const arbs = Object.fromEntries(
  ["en", "it"].map((lang) => {
    const file = join(here, `../lib/l10n/app_${lang}.arb`);
    return [lang, { file, arb: JSON.parse(readFileSync(file, "utf8")) }];
  }),
);
const wanted = new Set();
const has = (k) => k in words.en && k in words.it;
for (const f of files) {
  const text = readFileSync(join(web, "components", f), "utf8");
  for (const m of text.matchAll(/"([A-Za-z][A-Za-z0-9_]+)"/g))
    if (!skip.has(m[1]) && has(m[1])) wanted.add(m[1]);
}
for (const k of Object.keys(words.en))
  if (families.some((p) => k.startsWith(p)) && k in words.it) wanted.add(k);
for (const j of jobs) {
  if (has(`job_${j}`)) wanted.add(`job_${j}`);
  for (const k of Object.keys(words.en))
    if (k.startsWith(`job_step_${j}`) && k in words.it) wanted.add(k);
}
// Every step any job of these says (the steps are not prefixed by the job's kind).
for (const k of Object.keys(words.en)) if (k.startsWith("job_step_") && k in words.it) wanted.add(k);
for (const k of extra) if (has(k)) wanted.add(k);

const dartName = (k) => `${prefix}${k[0].toUpperCase()}${k.slice(1)}`;
// A brace that is not a word's hole (`{"ok":true}` in a sentence) cannot stand in an ARB without
// ICU escaping (off: the Italian apostrophes would turn into quotes): it becomes the placeholders
// `{lb}` and `{rb}`, which syWord fills with the braces themselves.
const braces = (s) =>
  s
    .replace(/\{([A-Za-z0-9_]+)\}/g, "\u0000$1\u0001")
    .replaceAll("{", "\u0002")
    .replaceAll("}", "\u0003")
    .replace(/\u0000([A-Za-z0-9_]+)\u0001/g, "{$1}")
    .replaceAll("\u0002", "{lb}")
    .replaceAll("\u0003", "{rb}");
for (const lang of ["it", "en"]) for (const k of wanted) words[lang][k] = braces(words[lang][k]);
const sorted = [...wanted].sort();
for (const lang of ["en", "it"]) {
  const { arb } = arbs[lang];
  for (const k of sorted) {
    const value = words[lang][k];
    const names = holes(value);
    const other = holes(words[lang === "en" ? "it" : "en"][k]);
    if (names.join() !== other.join()) throw new Error(`${k}: it and en have different words`);
    arb[dartName(k)] = value;
    if (lang === "en" && names.length)
      arb[`@${dartName(k)}`] = {
        placeholders: Object.fromEntries(names.map((n) => [n, { type: "String" }])),
      };
  }
}
for (const { file, arb } of Object.values(arbs)) writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);

// The page's key to the word: families and keys built at run time.
const lines = [
  "// Generated by tool/system_words.mjs from the page (i18n.ts): do not edit.",
  "// ignore_for_file: lines_longer_than_80_chars",
  "import '../../l10n/app_localizations.dart';",
  "",
  "/// The page's word [key] (`osErr_busy`, `job_step_tailscale`…) with its values, or null.",
  "String? syWord(AppLocalizations l, String key, [Map<String, String> v = const {}]) =>",
  "    switch (key) {",
];
for (const k of sorted) {
  const names = holes(words.en[k]);
  const call = names.length
    ? `l.${dartName(k)}(${names
        .map((n) => `v['${n}'] ?? '${n === "lb" ? "{" : n === "rb" ? "}" : ""}'`)
        .join(", ")})`
    : `l.${dartName(k)}`;
  lines.push(`      '${k}' => ${call},`);
}
lines.push("      _ => null,", "    };", "");
writeFileSync(join(here, "../lib/settings/system/system_words.g.dart"), lines.join("\n"));
console.log(`${prefix}: ${wanted.size} words`);
