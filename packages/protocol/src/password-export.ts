// Password managers' exports pasted in a message (3.9.8, the person's report: an Avira export of
// ~420 rows reached the log, Echo and the engine's transcript). Pure functions, mirrored in the app
// (apps/companion/lib/api/password_export.dart):
// - `findPasswordExports` says where an export is and how many passwords it holds (never a value),
//   for the composer's warning and the server's blanking;
// - `readPasswordExport` reads the rows, values included, only on the server and only to put them
//   in the keychain.
// Bitwarden (CSV and JSON), Avira, Chrome/Edge, Firefox, 1Password (CSV and 1pux text), KeePass
// (CSV and XML), any CSV with a password column, and plain «site user password» lists.

export type PasswordExportKind =
  | "bitwarden"
  | "avira"
  | "chrome"
  | "firefox"
  | "1password"
  | "keepass"
  | "csv"
  | "json"
  | "xml"
  | "list";

/** Where an export is in a text and how many passwords it holds. */
export interface PasswordExportSpan {
  kind: PasswordExportKind;
  /** [start, end) of the whole export, header included. */
  start: number;
  end: number;
  /** How many passwords (rows with a value). */
  rows: number;
}

/** One row of an export, value included (the server only). */
export interface ExportedCredential {
  service: string;
  username: string;
  value: string;
  url: string;
  notes: string;
}

// ---------------------------------------------------------------------------------------------
// CSV

/** Splits one CSV record starting at `at`: its fields and where the next record starts. */
function readRecord(s: string, at: number, sep: string): { fields: string[]; next: number } {
  const fields: string[] = [];
  let field = "";
  let quoted = false;
  let i = at;
  for (; i < s.length; i++) {
    const c = s[i];
    if (quoted) {
      if (c === '"') {
        if (s[i + 1] === '"') {
          field += '"';
          i++;
        } else quoted = false;
      } else field += c;
      continue;
    }
    if (c === '"' && field.trim() === "") {
      quoted = true;
      field = "";
    } else if (c === sep) {
      fields.push(field);
      field = "";
    } else if (c === "\n" || c === "\r") {
      const next = c === "\r" && s[i + 1] === "\n" ? i + 2 : i + 1;
      fields.push(field);
      return { fields, next };
    } else field += c;
  }
  fields.push(field);
  return { fields, next: s.length };
}

const PASSWORD_COLUMNS = [
  "login_password",
  "password",
  "passwort",
  "pass",
  "pwd",
  "parola d'ordine",
  "mot de passe",
  "contraseña",
];
const OTHER_COLUMNS = [
  "url",
  "uri",
  "login_uri",
  "website",
  "web site",
  "site",
  "name",
  "title",
  "username",
  "user name",
  "login name",
  "login_username",
  "login",
  "user",
  "email",
  "account",
  "sito",
  "nome",
  "titolo",
  "utente",
  "nome utente",
  "indirizzo",
];

/** The column names each kind calls its parts, the first one found wins. */
const COLUMNS: Record<keyof ExportedCredential, string[]> = {
  service: ["name", "title", "account", "service", "site", "nome", "titolo", "sito"],
  username: [
    "login_username",
    "username",
    "user name",
    "login name",
    "login",
    "user",
    "email",
    "nome utente",
    "utente",
  ],
  value: PASSWORD_COLUMNS,
  url: ["login_uri", "url", "uri", "website", "web site", "urls", "sito", "indirizzo"],
  notes: ["notes", "note", "comments", "comment", "notesplain"],
};

function kindOfHeader(h: Set<string>): PasswordExportKind {
  if (h.has("login_password") || h.has("login_uri")) return "bitwarden";
  if (h.has("httprealm") || h.has("formactionorigin")) return "firefox";
  if (h.has("login name") || (h.has("group") && h.has("title")) || h.has("web site"))
    return "keepass";
  if (h.has("otpauth") || (h.has("title") && h.has("password"))) return "1password";
  if (h.has("website") && h.has("login")) return "avira";
  if (h.has("name") && h.has("url") && h.has("username")) return "chrome";
  return "csv";
}

interface CsvExport {
  kind: PasswordExportKind;
  start: number;
  end: number;
  rows: ExportedCredential[];
  skipped: number;
}

const hostOf = (url: string): string => {
  try {
    const u = new URL(url.includes("://") ? url : `https://${url}`);
    return u.protocol === "http:" || u.protocol === "https:" ? u.hostname : "";
  } catch {
    return "";
  }
};

/** A header line at `at` (or null): its separator and its lower-case names. */
function headerAt(s: string, at: number): { sep: string; names: string[]; next: number } | null {
  const end = s.indexOf("\n", at);
  const line = s.slice(at, end < 0 ? s.length : end);
  if (line.length > 600) return null;
  const counts = [",", ";", "\t"].map((c) => [c, line.split(c).length - 1] as const);
  const [sep, n] = counts.reduce((a, b) => (b[1] > a[1] ? b : a));
  if (n < 1) return null;
  const { fields, next } = readRecord(s, at, sep);
  const names = fields.map((f) => f.trim().toLowerCase());
  if (!names.some((x) => PASSWORD_COLUMNS.includes(x))) return null;
  if (!names.some((x) => OTHER_COLUMNS.includes(x))) return null;
  // A header names its columns: no long values, no spaces in most.
  if (names.some((x) => x.length > 40)) return null;
  return { sep, names, next };
}

function readCsvExports(s: string): CsvExport[] {
  const out: CsvExport[] = [];
  let at = 0;
  while (at < s.length) {
    const head = headerAt(s, at);
    const lineEnd = s.indexOf("\n", at);
    if (!head) {
      if (lineEnd < 0) break;
      at = lineEnd + 1;
      continue;
    }
    const col = (names: string[]) => {
      for (const n of names) {
        const i = head.names.indexOf(n);
        if (i >= 0) return i;
      }
      return -1;
    };
    const idx = Object.fromEntries(Object.entries(COLUMNS).map(([k, v]) => [k, col(v)])) as Record<
      keyof ExportedCredential,
      number
    >;
    const rows: ExportedCredential[] = [];
    let skipped = 0;
    let end = head.next;
    let p = head.next;
    while (p < s.length) {
      const { fields, next } = readRecord(s, p, head.sep);
      // An empty line or a record of another shape ends the export.
      if (fields.length < 2 || fields.length > head.names.length + 2) break;
      if (fields.length < Math.ceil(head.names.length / 2)) break;
      const get = (k: keyof ExportedCredential) =>
        idx[k] >= 0 ? (fields[idx[k]] ?? "").trim() : "";
      const value = idx.value >= 0 ? (fields[idx.value] ?? "") : "";
      if (value.trim()) {
        const url = get("url");
        rows.push({
          service: get("service") || hostOf(url) || "Login",
          username: get("username"),
          value,
          url,
          notes: get("notes"),
        });
      } else skipped++;
      end = next;
      p = next;
    }
    if (rows.length > 0) {
      out.push({
        kind: kindOfHeader(new Set(head.names)),
        start: at,
        end: trimEnd(s, end),
        rows,
        skipped,
      });
      at = end;
    } else at = head.next;
  }
  return out;
}

/** The end of a span without the line break after it. */
function trimEnd(s: string, end: number): number {
  let e = end;
  while (e > 0 && (s[e - 1] === "\n" || s[e - 1] === "\r")) e--;
  return e;
}

// ---------------------------------------------------------------------------------------------
// JSON (Bitwarden, 1Password's 1pux text, others)

const JSON_PASSWORD = /"(?:password|login_password)"\s*:\s*"((?:[^"\\]|\\.)+)"/g;
const JSON_DESIGNATION = /"designation"\s*:\s*"password"/g;

interface Found {
  kind: PasswordExportKind;
  start: number;
  end: number;
  rows: ExportedCredential[];
}

function walkJson(v: unknown, out: ExportedCredential[], depth = 0): void {
  if (depth > 12 || v === null || typeof v !== "object") return;
  if (Array.isArray(v)) {
    for (const x of v) walkJson(x, out, depth + 1);
    return;
  }
  const o = v as Record<string, unknown>;
  const str = (x: unknown) => (typeof x === "string" ? x : "");
  const login = (o.login && typeof o.login === "object" ? o.login : null) as Record<
    string,
    unknown
  > | null;
  // 1Password's 1pux: details.loginFields with designations; overview.title and url.
  const details = o.details as { loginFields?: unknown } | undefined;
  const overview = (o.overview ?? {}) as Record<string, unknown>;
  if (details && Array.isArray(details.loginFields)) {
    const f = details.loginFields as Record<string, unknown>[];
    const by = (d: string) => str(f.find((x) => x?.designation === d)?.value);
    const value = by("password");
    if (value) {
      const url = str(overview.url);
      out.push({
        service: str(overview.title) || hostOf(url) || "Login",
        username: by("username"),
        value,
        url,
        notes: "",
      });
      return;
    }
  }
  const value = str(login?.password) || str(o.password) || str(o.login_password);
  if (value) {
    const uris = login?.uris;
    const url =
      (Array.isArray(uris) ? str((uris[0] as { uri?: unknown } | undefined)?.uri) : "") ||
      str(o.url) ||
      str(o.uri) ||
      str(o.website);
    out.push({
      service: str(o.name) || str(o.title) || hostOf(url) || "Login",
      username: str(login?.username) || str(o.username) || str(o.login) || str(o.email),
      value,
      url,
      notes: str(o.notes),
    });
    return;
  }
  for (const x of Object.values(o)) walkJson(x, out, depth + 1);
}

function readJsonExport(s: string): Found | null {
  const values = [...s.matchAll(JSON_PASSWORD)].filter((m) => (m[1] ?? "").trim());
  const designations = [...s.matchAll(JSON_DESIGNATION)];
  const first = Math.min(values[0]?.index ?? s.length, designations[0]?.index ?? s.length);
  if (first === s.length) return null;
  // The JSON around the matches: from the first line opening it to its last closing bracket.
  let start = first;
  for (const m of s.slice(0, first).matchAll(/(?:^|\n)[ \t]*([[{])/g))
    if (m.index !== undefined) {
      start = m.index + m[0].length - 1;
      break;
    }
  const end = Math.max(s.lastIndexOf("}"), s.lastIndexOf("]")) + 1;
  if (end <= start) return null;
  const rows: ExportedCredential[] = [];
  try {
    walkJson(JSON.parse(s.slice(start, end)), rows);
  } catch {
    // A partial paste: the values only, by their keys.
    for (const m of values)
      rows.push({
        service: "Login",
        username: "",
        value: JSON.parse(`"${m[1]}"`) as string,
        url: "",
        notes: "",
      });
  }
  // One password in some JSON is a setting; an export has items and logins (or many of them).
  const shaped = /"(?:items|logins|accounts|entries)"\s*:/.test(s) || designations.length > 0;
  if (rows.length === 0 || (rows.length < 2 && !shaped)) return null;
  const kind: PasswordExportKind = designations.length
    ? "1password"
    : /"encrypted"\s*:\s*false/.test(s) || /"login"\s*:\s*\{/.test(s)
      ? "bitwarden"
      : "json";
  return { kind, start, end, rows };
}

// ---------------------------------------------------------------------------------------------
// XML (KeePass 2 and 1)

const unxml = (x: string) =>
  x
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&amp;/g, "&");

function readXmlExport(s: string): Found | null {
  const rows: ExportedCredential[] = [];
  for (const m of s.matchAll(/<Entry>([\s\S]*?)<\/Entry>/g)) {
    const f: Record<string, string> = {};
    for (const p of (m[1] ?? "").matchAll(
      /<String>\s*<Key>([^<]*)<\/Key>\s*<Value[^>]*>([^<]*)<\/Value>\s*<\/String>/g,
    ))
      f[(p[1] ?? "").toLowerCase()] = unxml(p[2] ?? "");
    if (f.password)
      rows.push({
        service: f.title || hostOf(f.url ?? "") || "Login",
        username: f.username ?? "",
        value: f.password,
        url: f.url ?? "",
        notes: f.notes ?? "",
      });
  }
  for (const m of s.matchAll(/<pwentry>([\s\S]*?)<\/pwentry>/gi)) {
    const tag = (n: string) =>
      unxml(new RegExp(`<${n}>([^<]*)</${n}>`, "i").exec(m[1] ?? "")?.[1] ?? "");
    const value = tag("password");
    if (value)
      rows.push({
        service: tag("title") || hostOf(tag("url")) || "Login",
        username: tag("username"),
        value,
        url: tag("url"),
        notes: tag("notes"),
      });
  }
  if (rows.length === 0) return null;
  const open = /<\?xml|<KeePassFile|<pwlist/i.exec(s);
  const first = /<Entry>|<pwentry>/i.exec(s);
  const start = open?.index ?? first?.index ?? 0;
  const closes = [...s.matchAll(/<\/KeePassFile>|<\/pwlist>|<\/Entry>|<\/pwentry>/gi)];
  const last = closes.at(-1);
  const end = last ? (last.index ?? 0) + last[0].length : s.length;
  return { kind: "keepass", start, end, rows };
}

// ---------------------------------------------------------------------------------------------
// Plain lists: «site user password», one per line

const SITE = /^(?:https?:\/\/\S+|(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)*\.[a-z]{2,}(?:[/:]\S*)?)$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[a-z]{2,}$/i;
const USER = /^[\p{L}\p{N}._+@-]{2,64}$/u;

/** Something that looks like a password: no spaces, at least two kinds of characters. */
export function looksLikePassword(v: string): boolean {
  if (v.length < 6 || v.length > 128 || /\s/.test(v)) return false;
  if (SITE.test(v) || EMAIL.test(v)) return false;
  // Dates, times, numbers, versions, sizes and durations are not passwords.
  if (/^[\d.,:/+-]+(?:ms|s|kb|mb|gb|%)?$/i.test(v)) return false;
  const kinds = [/[a-z]/, /[A-Z]/, /\d/, /[^A-Za-z0-9]/].filter((r) => r.test(v)).length;
  return kinds >= 2;
}

/** One line of a plain list, or null. */
function listLine(line: string): ExportedCredential | null {
  const t = line.trim();
  if (t.length < 8 || t.length > 400) return null;
  const strong = /[\t;|,]/.test(t);
  const parts = t
    .split(strong ? /\s*[\t;|,]\s*/ : /\s+/)
    .map((p) => p.trim())
    .filter(Boolean);
  if (parts.length < 3 || parts.length > 4) return null;
  const value = parts.at(-1) ?? "";
  const user = parts.at(-2) ?? "";
  const where = parts.slice(0, -2);
  const site = where.find((p) => SITE.test(p)) ?? "";
  if (!USER.test(user) || /^\d+$/.test(user) || SITE.test(value)) return null;
  // A site and a user, or (with a clear separator) a name: then the value must look like one.
  if (site) {
    if (value.length < 4 || /^\d{1,3}$/.test(value) || /^[\d.,:]+$/.test(value)) return null;
    if (!looksLikePassword(value) && !(EMAIL.test(user) || strong)) return null;
  } else if (!strong || !looksLikePassword(value)) return null;
  const name = where.find((p) => p !== site) ?? "";
  return { service: name || hostOf(site) || "Login", username: user, value, url: site, notes: "" };
}

function readLists(s: string): Found[] {
  const out: Found[] = [];
  let run: { start: number; end: number; rows: ExportedCredential[]; others: number } | null = null;
  const close = () => {
    if (run && run.rows.length >= 3 && run.rows.length >= run.others * 2)
      out.push({ kind: "list", start: run.start, end: run.end, rows: run.rows });
    run = null;
  };
  let at = 0;
  while (at <= s.length) {
    const nl = s.indexOf("\n", at);
    const end = nl < 0 ? s.length : nl;
    const line = s.slice(at, end).replace(/\r$/, "");
    const row = listLine(line);
    if (row) {
      run ??= { start: at, end, rows: [], others: 0 };
      run.rows.push(row);
      run.end = at + line.length;
    } else if (run && line.trim() === "") {
      close();
    } else if (run) {
      run.others++;
      if (run.others > run.rows.length) close();
    }
    if (nl < 0) break;
    at = nl + 1;
  }
  close();
  return out;
}

// ---------------------------------------------------------------------------------------------

function readAll(text: string): Found[] {
  const found: Found[] = [];
  const taken = (a: number, b: number) => found.some((f) => a < f.end && f.start < b);
  for (const c of readCsvExports(text)) found.push(c);
  const json = readJsonExport(text);
  if (json && !taken(json.start, json.end)) found.push(json);
  const xml = readXmlExport(text);
  if (xml && !taken(xml.start, xml.end)) found.push(xml);
  for (const l of readLists(text)) if (!taken(l.start, l.end)) found.push(l);
  return found.sort((a, b) => a.start - b.start);
}

/** Where the password exports are in a text, and how many passwords each holds. */
export function findPasswordExports(text: string): PasswordExportSpan[] {
  if (text.length < 20) return [];
  return readAll(text).map(({ kind, start, end, rows }) => ({
    kind,
    start,
    end,
    rows: rows.length,
  }));
}

/** How many passwords the exports in a text hold (0: none). */
export const passwordExportRows = (text: string): number =>
  findPasswordExports(text).reduce((n, e) => n + e.rows, 0);

/** The rows of every export in a text, values included: the server only, for the keychain. */
export function readPasswordExport(text: string): {
  kind: PasswordExportKind | null;
  rows: ExportedCredential[];
} {
  const all = readAll(text);
  return { kind: all[0]?.kind ?? null, rows: all.flatMap((f) => f.rows) };
}

/** The text with every export replaced by `mark` (the words around it stay). */
export function withoutPasswordExports(
  text: string,
  mark = "[password export removed]",
): { text: string; rows: number } {
  const found = findPasswordExports(text);
  let out = text;
  for (const f of [...found].reverse()) out = `${out.slice(0, f.start)}${mark}${out.slice(f.end)}`;
  return { text: out, rows: found.reduce((n, f) => n + f.rows, 0) };
}
