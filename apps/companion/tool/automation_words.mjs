// Writes the words of Settings › Automations (G42.9) into lib/l10n/app_en.arb and app_it.arb:
// every key the page's Automations.tsx, AutomationEditor.tsx and MagicAutomation.tsx show (and
// the few of Bell.tsx and EmailSettings.tsx they use), taken from packages/web/src/i18n.ts, it and
// en, as `au` + the key with a capital («axSayDoes» becomes «auAxSayDoes»), so the app says exactly
// what the page says; then the app's own few words (`OWN`). JSON is read and written with the
// parser; old `au…` keys are dropped first, so running it again changes nothing. Then
// `flutter gen-l10n`.
//
//   node apps/companion/tool/automation_words.mjs
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repo = join(here, "../../..");
const web = join(repo, "packages/web/src");
const app = join(here, "..");

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

// The keys: every literal the three components pass to t(), the ones they make at run time, and
// a few of the components next to them.
const files = ["Automations.tsx", "AutomationEditor.tsx", "MagicAutomation.tsx"].map((f) =>
  readFileSync(join(web, "components", f), "utf8"),
);
const keys = new Set();
for (const f of files) {
  for (const m of f.matchAll(/\bt\(\s*"([A-Za-z0-9_]+)"/g)) keys.add(m[1]);
  for (const m of f.matchAll(/"((?:ax|tpl)[A-Za-z0-9_]+)"/g)) if (m[1] in words.en) keys.add(m[1]);
}
const made = {
  axAfter_: ["ok", "failed", "timeout"],
  axCat_: ["work", "personal", "social", "other"],
  axFiles_: ["added", "changed", "removed"],
  axKind_: ["minutes", "once", "custom"],
  axMagicState_: ["building", "ready", "done", "dismissed"],
  axNeed_: ["chat", "email", "extension", "credential", "other"],
  axStart_: ["time", "message", "files", "after", "task", "startup"],
  axTask_: ["verified", "not_testable", "abandoned"],
  day_: ["0", "1", "2", "3", "4", "5", "6"],
  repoEvent_: ["push", "pull_request", "issues", "issue_comment", "release"],
  tplTitle_: ["morning", "weekly", "spending", "blank"],
  tplDesc_: ["morning", "weekly", "spending", "blank"],
  tplText_: ["morning", "weekly", "spending"],
  whenKind_: ["daily", "weekdays", "weekly", "monthly", "hours", "email", "repo", "webhook"],
};
for (const [head, tails] of Object.entries(made)) for (const t of tails) keys.add(head + t);
for (const k of [
  "automationNotices",
  "dismiss",
  "open",
  "axMailboxesWatching",
  "emailWatching",
  "emailNeedFirst",
  "asstNewRoutine",
]) {
  keys.add(k);
}

/** The app's own words (what only the app has: its menus, the YAML field's lines…). */
const OWN = {
  hubHint: {
    en: "When things happen by themselves: schedules, emails, chats, files, reminders",
    it: "Quando le cose succedono da sole: orari, email, chat, file, promemoria",
  },
  openChat: { en: "Open the conversation", it: "Apri la conversazione" },
  talkGod: { en: "Talk with God", it: "Parla con God" },
  mailboxesElsewhere: {
    en: "Mailboxes are added and changed in Settings › Channels and mailboxes.",
    it: "Le caselle si aggiungono e si cambiano in Impostazioni › Canali e caselle.",
  },
  noMailboxes: { en: "No mailbox connected yet.", it: "Ancora nessuna casella collegata." },
  copied: { en: "Copied", it: "Copiato" },
  copy: { en: "Copy", it: "Copia" },
  yamlLabel: { en: "The recipe in YAML", it: "La ricetta in YAML" },
  routineOpen: { en: "Open the routine", it: "Apri la routine" },
  noticeOpen: { en: "Open", it: "Apri" },
  noticeFailed: { en: "{name}: not done", it: "{name}: non riuscita" },
  pickTitle: { en: "Choose", it: "Scegli" },
  needOpenWhere: {
    en: "Open it in Settings › {where}",
    it: "Si fa in Impostazioni › {where}",
  },
  whereChats: { en: "Channels and mailboxes", it: "Canali e caselle" },
  whereExtensions: { en: "Extensions", it: "Estensioni" },
  whereKeychain: { en: "Keychain", it: "Portachiavi" },
  loadFailed: { en: "Could not read: {why}", it: "Non riesco a leggere: {why}" },
  readOnly: {
    en: "Automations can be changed only by the person (not from a project's device).",
    it: "Le automazioni le cambia solo la persona (non da un dispositivo di progetto).",
  },
};

const cap = (k) => k.charAt(0).toUpperCase() + k.slice(1);
const out = { en: {}, it: {} };
for (const k of [...keys].sort()) {
  if (!(k in words.en)) throw new Error(`the page has no English words for ${k}`);
  out.en[`au${cap(k)}`] = words.en[k];
  out.it[`au${cap(k)}`] = words.it[k] ?? words.en[k];
}
for (const [k, v] of Object.entries(OWN)) {
  out.en[`auOwn${cap(k)}`] = v.en;
  out.it[`auOwn${cap(k)}`] = v.it;
}

// A brace that is not a {placeholder} would break the ARB's ICU reading: never written.
const holders = (s) => [...new Set([...s.matchAll(/\{(\w+)\}/g)].map((m) => m[1]))];
for (const lang of ["en", "it"])
  for (const [k, v] of Object.entries(out[lang]))
    if (v.replace(/\{\w+\}/g, "").match(/[{}]/)) throw new Error(`${lang} ${k}: a stray brace`);
for (const [k, v] of Object.entries(out.it))
  for (const p of holders(v))
    if (!holders(out.en[k]).includes(p)) throw new Error(`it ${k}: {${p}} is not in the English`);

for (const lang of ["en", "it"]) {
  const file = join(app, `lib/l10n/app_${lang}.arb`);
  const arb = JSON.parse(readFileSync(file, "utf8"));
  for (const k of Object.keys(arb)) if (/^@?au[A-Z]/.test(k)) delete arb[k];
  for (const [k, v] of Object.entries(out[lang])) {
    arb[k] = v;
    const ph = holders(out.en[k]);
    if (lang === "en" && ph.length)
      arb[`@${k}`] = { placeholders: Object.fromEntries(ph.map((p) => [p, { type: "String" }])) };
  }
  writeFileSync(file, `${JSON.stringify(arb, null, 2)}\n`);
}
console.log(`${Object.keys(out.en).length} words written`);
