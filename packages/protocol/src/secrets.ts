// Recognising secrets in what people write (G33.2, extracted in G33.4 so the shared memory, every
// chat and the web page use one recogniser). Only real secrets count (2026-11-07, the person on the
// first filter: «Decisamente troppo severo»): values that look like keys, valid card numbers and
// IBANs, and a password or a PIN only when its value is there. Talking about passwords («il
// password manager è comodo», «uso il PIN sul telefono») is fine.

import { findPasswordExports } from "./password-export.js";

/** Well-known key formats; the event log's Redactor uses the same list. */
export const SECRET_PATTERNS: readonly { name: string; re: RegExp }[] = [
  {
    name: "private-key",
    re: /-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----/g,
  },
  // A key starts a word and has digits: "elon-musk-s-2026-political-…" in a URL is not one.
  { name: "anthropic-key", re: /\bsk-ant-(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{20,}/g },
  { name: "openai-key", re: /\bsk-(?:proj-)?(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{20,}/g },
  { name: "github-token", re: /\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})/g },
  { name: "huggingface-token", re: /\bhf_[A-Za-z0-9]{30,}/g },
  { name: "aws-access-key", re: /\bAKIA[0-9A-Z]{16}\b/g },
  { name: "google-api-key", re: /\bAIza[0-9A-Za-z_-]{35}\b/g },
  { name: "slack-token", re: /\bxox[abprs]-[A-Za-z0-9-]{10,}/g },
  { name: "telegram-bot-token", re: /\b\d{8,10}:[A-Za-z0-9_-]{35}\b/g },
  { name: "bearer", re: /(?<=\bBearer\s+)[A-Za-z0-9._~+/-]{20,}=*/g },
];

/** Words that describe a password rather than being one: «la password è lunga». */
const NOT_A_VALUE = new Set(
  (
    "lunga corta sicura forte debole semplice facile difficile complicata comoda scaduta cambiata " +
    "nuova vecchia salvata segreta giusta sbagliata uguale diversa sempre ancora stata nel nella " +
    "sul sulla in un una il lo la le gli i di da per con che non " +
    "long short strong weak secure safe simple easy hard complex expired changed new old saved " +
    "secret right wrong same different always still in on the a an my your not stored kept"
  ).split(" "),
);

/** "password: X", "la password del wifi è X", "my password is X": the keyword, then its value. */
const PASSWORD =
  /\b(?:password|passwd|pwd|passcode|passphrase|parola d'ordine)(?:\s+(?:del|della|dello|dell'|di|of|for|per|to|on|su|sul|sulla|al|alla|mio|mia|my)\s+[^\s:=]+){0,2}\s*(?:[:=]\s*|\s(?:is|è|e'|era|sarebbe|vale|=)\s+)["'«]?([^\s"'»,;.]{3,})/giu;
/** "PIN 1234", "il mio PIN è 12345", "CVV: 123": the number is there. */
const CODE = /\b(?:pin|puk|otp|cvv|cvc|codice segreto|codice pin)\b[^\d\n]{0,12}(\d{3,8})\b/giu;
/** "token: …", "api key sk…", "chiave api = …": a long value with letters and digits. */
const KEY =
  /\b(?:api[ _-]?key|token|secret|chiave(?: api| segreta)?|access key)\s*(?:[:=]|\s(?:is|è)\s)?\s*["'«]?([A-Za-z0-9_\-./+]{16,})/giu;
/** JSON web tokens (only real ones: see `isJwt`). */
const JWT = /\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*/g;
/** Long random strings with lower case, upper case and digits mixed. */
const RANDOM =
  /\b(?=[A-Za-z0-9+/_-]*\d)(?=[A-Za-z0-9+/_-]*[a-z])(?=[A-Za-z0-9+/_-]*[A-Z])[A-Za-z0-9+/_-]{24,}\b/g;

/**
 * A JSON web token's header names its algorithm: `eyJ2IjoiMSJ9.…` ({"v":"1"}, Amazon's `dib`
 * parameter, 2026-11-19) only looks like one.
 */
export function isJwt(token: string): boolean {
  const head = token.split(".")[0] ?? "";
  try {
    const b64 = head.replace(/-/g, "+").replace(/_/g, "/");
    const json = JSON.parse(atob(b64 + "=".repeat((4 - (b64.length % 4)) % 4))) as unknown;
    return (
      typeof json === "object" &&
      json !== null &&
      typeof (json as { alg?: unknown }).alg === "string"
    );
  } catch {
    return false;
  }
}

/** http(s) links; the punctuation that ends a sentence is not part of them. */
const LINK = /\bhttps?:\/\/[^\s<>"'«»]+?(?=[.,;:!?)\]]*(?:[\s<>"'«»]|$))/gi;
/** A link's parameters (query and fragment): `name=value`. */
const LINK_PARAM = /[?&#;]([^=&#;?\s]+)=([^&#;\s]*)/g;
/**
 * A parameter whose name says it carries a secret (2026-11-19): token, access_token,
 * X-Amz-Signature, X-Amz-Credential, sig, api_key, key… (the whole name or its last part).
 */
const SECRET_PARAM =
  /^(?:.*[-_.])?(?:token|secret|signature|sig|password|passwd|pwd|apikey|api[-_]?key|key|credential|credentials|auth|authorization)$/i;

/** Where the links are: [start, end). */
function linksIn(text: string): [number, number][] {
  return [...text.matchAll(LINK)].map((m) => [m.index ?? 0, (m.index ?? 0) + m[0].length]);
}

function luhn(digits: string): boolean {
  let sum = 0;
  for (let i = 0; i < digits.length; i++) {
    let d = Number(digits[digits.length - 1 - i]);
    if (i % 2 === 1) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 === 0;
}

function ibanValid(raw: string): boolean {
  const s = raw.replace(/\s+/g, "").toUpperCase();
  if (s.length < 15 || s.length > 34) return false;
  const moved = s.slice(4) + s.slice(0, 4);
  let rest = 0;
  for (const ch of moved) {
    const v = ch >= "A" && ch <= "Z" ? String(ch.charCodeAt(0) - 55) : ch;
    for (const d of v) rest = (rest * 10 + Number(d)) % 97;
  }
  return rest === 1;
}

/** One secret found in a text: where its value is, what kind, and the value itself. */
export interface SecretSpan {
  /** [start, end) of the value only: «password: hunter2» spans «hunter2». */
  start: number;
  end: number;
  kind: "key" | "password" | "code" | "card" | "iban" | "export";
  value: string;
  /** A password manager's export (3.9.8): how many passwords it holds. */
  rows?: number;
}

/** Where the secrets are in a text, sorted and merged when they overlap. */
export function findSecrets(text: string): SecretSpan[] {
  const out: Omit<SecretSpan, "value">[] = [];
  // A password manager's export (3.9.8) is one span: its rows, not each value in them.
  for (const x of findPasswordExports(text))
    out.push({ start: x.start, end: x.end, kind: "export", rows: x.rows });
  const add = (m: RegExpMatchArray, kind: SecretSpan["kind"], value = m[0]) => {
    const at = (m.index ?? 0) + Math.max(0, m[0].lastIndexOf(value));
    out.push({ start: at, end: at + value.length, kind });
  };
  // Inside a link only a known key format, a real JWT or a parameter named for a secret counts
  // (2026-11-19): its ids, tracking codes and the like are not secrets.
  const links = linksIn(text);
  const inLink = (at: number) => links.some(([a, b]) => at >= a && at < b);
  const outside = (kind: SecretSpan["kind"]) => (m: RegExpMatchArray, value?: string) => {
    const before = out.length;
    add(m, kind, value);
    const s = out[before];
    if (s && inLink(s.start)) out.pop();
  };
  for (const { re } of SECRET_PATTERNS) for (const m of text.matchAll(re)) add(m, "key");
  for (const m of text.matchAll(JWT)) if (isJwt(m[0])) add(m, "key");
  for (const [a, b] of links)
    for (const m of text.slice(a, b).matchAll(LINK_PARAM)) {
      const [name, value] = [m[1] ?? "", m[2] ?? ""];
      if (value.length < 8 || !SECRET_PARAM.test(name)) continue;
      const at = a + (m.index ?? 0) + 1 + name.length + 1;
      out.push({ start: at, end: at + value.length, kind: "key" });
    }
  for (const m of text.matchAll(PASSWORD))
    if (m[1] && !NOT_A_VALUE.has(m[1].toLowerCase())) outside("password")(m, m[1]);
  for (const m of text.matchAll(CODE)) if (m[1]) outside("code")(m, m[1]);
  for (const m of text.matchAll(KEY)) if (m[1] && /\d/.test(m[1])) outside("key")(m, m[1]);
  for (const m of text.matchAll(RANDOM)) outside("key")(m);
  for (const m of text.matchAll(/\b\d(?:[ -]?\d){12,18}\b/g))
    if (luhn(m[0].replace(/\D/g, ""))) outside("card")(m);
  for (const m of text.matchAll(/\b[A-Z]{2}\d{2}(?:\s?[A-Z0-9]{4}){2,7}(?:\s?[A-Z0-9]{1,4})?\b/gi))
    if (ibanValid(m[0])) outside("iban")(m);
  out.sort((a, b) => a.start - b.start || b.end - a.end);
  const merged: Omit<SecretSpan, "value">[] = [];
  for (const s of out) {
    const last = merged.at(-1);
    if (last && s.start < last.end) {
      last.end = Math.max(last.end, s.end);
      if (s.kind === "export") {
        last.kind = "export";
        last.rows = (last.rows ?? 0) + (s.rows ?? 0);
      }
    } else merged.push({ ...s });
  }
  return merged.map((s) => ({ ...s, value: text.slice(s.start, s.end) }));
}

/** One secret that matters when something leaves the computer (G36.17b). */
export interface LeakableSecret {
  /** A well-known key's format (`SECRET_PATTERNS`), or "password", or "token". */
  name: string;
  value: string;
}

/**
 * The secrets that matter when something leaves (G36.17b, the truly dangerous requests): keys in a
 * well-known format, and passwords or tokens written with their value. Long random strings, PINs,
 * card numbers and IBANs are left out: in commands and files they are mostly ids, hashes and
 * timestamps, and an IBAN is meant to be shared.
 */
export function leakableSecrets(text: string): LeakableSecret[] {
  const out: (LeakableSecret & { at: number })[] = [];
  // One name per place: "sk-ant-…" is Anthropic's, not also OpenAI's "sk-…".
  const add = (name: string, value: string, at: number) => {
    if (!out.some((o) => at < o.at + o.value.length && o.at < at + value.length))
      out.push({ name, value, at });
  };
  for (const { name, re } of SECRET_PATTERNS)
    for (const m of text.matchAll(re)) add(name, m[0], m.index ?? 0);
  const valueAt = (m: RegExpMatchArray, v: string) => (m.index ?? 0) + m[0].lastIndexOf(v);
  for (const m of text.matchAll(PASSWORD))
    if (m[1] && !NOT_A_VALUE.has(m[1].toLowerCase())) add("password", m[1], valueAt(m, m[1]));
  for (const m of text.matchAll(KEY))
    if (m[1] && /\d/.test(m[1])) add("token", m[1], valueAt(m, m[1]));
  return out.map(({ name, value }) => ({ name, value }));
}

/** True when the text holds a secret. */
export const hasSecret = (text: string): boolean => findSecrets(text).length > 0;

/** The text with each secret's value replaced by `mark` (the words around it stay). */
export function hideSecrets(
  text: string,
  mark = "[secret]",
): { text: string; found: SecretSpan[] } {
  const found = findSecrets(text);
  let out = text;
  for (const s of [...found].reverse()) out = `${out.slice(0, s.start)}${mark}${out.slice(s.end)}`;
  return { text: out, found };
}
