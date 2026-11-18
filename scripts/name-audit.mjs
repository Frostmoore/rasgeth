#!/usr/bin/env node
// The name guard (plan 3.9.0, N1): RedGiant and RGCompanion are now Rasgeth. Every occurrence of
// an old name in the repository's text files is judged by one pure function, `auditText`:
//
// - visible: text a person reads (strings, documents, pages, file names people download, the
//   address on the network, the command they type) — forbidden;
// - comment: inside a comment, or an ARB entry's description for translators — allowed;
// - internal: the inside that stays (decision 2026-11-18 «cambia tutto ciò che si vede, l'interno
//   può restare»): REDGIANT_* variables, @redgiant/* packages, identifiers, ids, services, data
//   folders… — allowed;
// - kept: a name that stays on purpose, listed in scripts/name-keep.json with its group and why.
//
//   node scripts/name-audit.mjs            lists the visible occurrences by phase, exits 0
//   node scripts/name-audit.mjs --strict   the same, and exits 1 when there is one
//   options: --lines (every visible line), --markdown, --json
//
// Only Node's own modules: it runs in CI before anything is installed.
import { execFileSync } from "node:child_process";
import { appendFileSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

/** The old names in any form: RedGiant, Red Giant, REDGIANT, redgiant, RGCompanion, rgcompanion. */
const NAME = /red ?giant|rgcompanion/gi;

/** The inside that stays, whatever the file (checked before comments and visible forms). */
export const INTERNAL = [
  ["env", /\bREDGIANT_\w*/g, "REDGIANT_* variables stay, without aliases (choice 11)"],
  ["package", /@redgiant\/[\w-]+/g, "the @redgiant/* packages stay (choice 9)"],
  ["dart-package", /package:rgcompanion\//g, "the Dart package rgcompanion stays (choice 9)"],
  [
    "image",
    /ghcr\.io\/frostmoore\/redgiant2[\w-]*|\bredgiant2-(?:sandbox|engine|postgres)[\w-]*/gi,
    "Docker images keep their names (choice 12)",
  ],
  [
    "service",
    /\bredgiant-[\w@.-]*\.(?:service|socket|timer|path|target)\b/g,
    "systemd services redgiant-* stay (choice 9)",
  ],
  [
    "data-folder",
    /\/var\/lib\/redgiant\b|\/usr\/(?:lib|share)\/redgiant-os\b|\/etc\/redgiant-os\b|~\/redgiant\b|\$HOME\/redgiant\b|Application Support\/RedGiant\b|Software\\+RedGiant\b|RedGiant-backups\b/g,
    "existing data folders never move (choice 5)",
  ],
  ["mdns", /_redgiant\._tcp/g, "the mDNS service type stays (choice 9)"],
  [
    "project-folder",
    /(?<![\w@])\.redgiant\b/g,
    "the .redgiant/ folders in projects stay (choice 9)",
  ],
  ["header", /X-RedGiant-[\w-]+/g, "HTTP headers are not shown (choice 9)"],
  [
    "app-id",
    /\bcom\.redgiant\.[\w.]+|keychain@redgiant\.local|\bRedGiant\.RGCompanion\b/g,
    "ids nobody sees keep permissions, keychain and notifications (choice 6)",
  ],
  ["keychain-service", /\bredgiant-vault\b/g, "the Mac keychain's service: renaming locks it"],
  [
    "widget-api",
    /\bredgiant\.[A-Za-z_]\w*\s*\(|\bredgiant:[a-z][\w-]*|\bwindow\.redgiant\b/g,
    "the API widgets and artifacts call (window.redgiant, redgiant:* events): code, not text",
  ],
];

/** Lower-case forms a person still sees: in code they are flagged although lower case. */
export const VISIBLE = [
  ["address", /\bredgiant\.local\b/g],
  ["repository", /\bredgiant2\b/g],
  ["os-files", /\bredgiant-os-(?:stack|files|release)\b|\bredgiant-os-(?:\$\{|<|\{|\d|v\d)/g],
  ["app-files", /\brgcompanion-(?:linux|macos|android)\b|\bredgiant-keychain-\w*/g],
  ["backup-files", /\bredgiant-[\w*-]*\.rgbackup\b/g],
  [
    "commands",
    /\bredgiant-acp\b|\bredgiant-proxmox\.sh\b|\bredgiant\.cmd\b|"redgiant"\s*:\s*"\.\//g,
  ],
];

/** The plan's phase that owns a file (the first that matches). */
export const PHASES = [
  [/^\.github\//, "N7"],
  [/^packaging\/(stores|update)\/|^packaging\/release-kind\.json$/, "N7"],
  [/^packaging\/windows\/|^apps\/companion\/windows\//, "N3"],
  [/^packaging\/mac\/|^apps\/companion\/macos\//, "N4"],
  [/^apps\/companion\/(android|ios|linux)\//, "N5"],
  [/^packaging\/(linux-app|push-relay)\/|^apps\/companion\/pubspec\.yaml$/, "N5"],
  [/^apps\/companion\/lib\/(app_update\/)?brand\.dart$/, "N5"],
  [/^packaging\/icon\//, "N8"],
  [/^packaging\/os\/|^packages\/cli\/|^docker\/|^compose\.yaml$|^install\.(sh|ps1|cmd)$/, "N6"],
  [/^(docs|site)\/|\.md$/i, "N10"],
  [/^packages\/|^apps\/companion\//, "N2"],
];

export const PHASE_NAMES = {
  N2: "texts (page, app, channels, server, protocol)",
  N3: "Windows",
  N4: "Mac",
  N5: "the app on phones and Linux",
  N6: "Docker, command line and OS",
  N7: "release, CI and published files",
  N8: "icons",
  N10: "documents, README, site",
  other: "elsewhere",
};

export function phaseOf(path) {
  for (const [re, phase] of PHASES) if (re.test(path)) return phase;
  return "other";
}

/** A glob on repository paths: `**` any folders, `*` within one name, `?` one character. */
export function globToRegExp(glob) {
  let re = "";
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === "*" && glob[i + 1] === "*") {
      i++;
      if (glob[i + 1] === "/") {
        i++;
        re += "(?:.*/)?";
      } else re += ".*";
    } else if (c === "*") re += "[^/]*";
    else if (c === "?") re += "[^/]";
    else re += c.replace(/[.+^${}()|[\]\\]/g, "\\$&");
  }
  return new RegExp(`^${re}$`);
}

/** scripts/name-keep.json: `{ path?, pattern?, key?, group, why }`, path or pattern required. */
export function parseKeep(list) {
  if (!Array.isArray(list)) throw new Error("name-keep: a list of entries");
  return list.map((e, i) => {
    const at = `name-keep[${i}]`;
    if (typeof e?.group !== "string" || !e.group) throw new Error(`${at}: no group`);
    if (typeof e.why !== "string" || !e.why) throw new Error(`${at}: no why`);
    if (!e.path && !e.pattern) throw new Error(`${at}: a path or pattern is needed`);
    return {
      index: i,
      group: e.group,
      why: e.why,
      pathRe: e.path ? globToRegExp(e.path) : null,
      patternRe: e.pattern ? new RegExp(e.pattern, "g") : null,
      keyRe: e.key ? new RegExp(e.key) : null,
    };
  });
}

const extOf = (path) => {
  const base = path.split("/").pop();
  return base.includes(".") ? base.split(".").pop().toLowerCase() : "";
};

const SLASH = new Set(
  "ts tsx js mjs cjs dart cs swift kt kts gradle c cc cpp h hpp m mm java go rs rc jsonc css scss less xcconfig".split(
    " ",
  ),
);
const HASH = new Set(
  "sh bash zsh py yml yaml toml rb conf service socket timer path target desktop cmake nsh env gitignore dockerignore gitattributes properties network".split(
    " ",
  ),
);
const MARKUP = new Set("md markdown html htm xml plist svg xaml xib storyboard".split(" "));
/** Where a lower-case name is prose a person reads. */
const PROSE = new Set("md markdown html htm txt issue".split(" "));

function familyOf(path, firstLine) {
  const base = path.split("/").pop();
  const ext = extOf(path);
  if (MARKUP.has(ext) || firstLine.startsWith("<?xml")) return "markup";
  if (ext === "patch" || ext === "diff") return "patch";
  if (ext === "jinja" || ext === "j2") return "jinja";
  if (SLASH.has(ext)) return "slash";
  if (ext === "iss") return "iss";
  if (ext === "cmd" || ext === "bat") return "cmd";
  if (ext === "ps1" || ext === "psm1") return "ps";
  if (
    HASH.has(ext) ||
    base === "Dockerfile" ||
    base.endsWith(".Dockerfile") ||
    base === "CMakeLists.txt" ||
    base === "Makefile" ||
    base === "Caddyfile" ||
    firstLine.startsWith("#!") ||
    (ext === "" && firstLine.startsWith("#"))
  )
    return "hash";
  if (ext === "" && firstLine.startsWith("//")) return "slash";
  return "none";
}

const BLOCK_END = { "/*": "*/", "<!--": "-->", "<#": "#>", "{#": "#}" };

/** The parts of a line that are comments ([start, end) pairs), and the block left open. */
function comments(line, family, open) {
  if (family === "patch") {
    // A line a patch adds, removes or keeps: its first character, then code (C and C++ here).
    const c = comments(line.slice(1), "slash", open);
    return { ranges: c.ranges.map(([s, e]) => [s + 1, e + 1]), open: c.open };
  }
  const ranges = [];
  let i = 0;
  if (open) {
    const end = line.indexOf(BLOCK_END[open]);
    if (end < 0) return { ranges: [[0, line.length]], open };
    i = end + BLOCK_END[open].length;
    ranges.push([0, i]);
    open = null;
  }
  const trimmed = line.trimStart();
  if (family === "cmd" && /^(@?rem\b|::)/i.test(trimmed))
    return { ranges: [[0, line.length]], open };
  if (family === "iss" && trimmed.startsWith(";")) return { ranges: [[0, line.length]], open };
  if (family === "none") return { ranges, open };
  const quotes = family !== "markup";
  let quote = null;
  for (; i < line.length; i++) {
    const c = line[i];
    if (quote) {
      if (c === "\\") i++;
      else if (c === quote) quote = null;
      continue;
    }
    if (quotes && (c === '"' || c === "'" || c === "`")) {
      quote = c;
      continue;
    }
    const prev = i > 0 ? line[i - 1] : " ";
    const block = (start) => {
      const end = line.indexOf(BLOCK_END[start], i + start.length);
      if (end < 0) {
        ranges.push([i, line.length]);
        return { done: true, open: start };
      }
      ranges.push([i, end + BLOCK_END[start].length]);
      i = end + BLOCK_END[start].length - 1;
      return { done: false };
    };
    if (family === "jinja") {
      if (line.startsWith("{#", i)) {
        const b = block("{#");
        if (b.done) return { ranges, open: b.open };
      }
      continue;
    }
    if (family === "markup") {
      if (line.startsWith("<!--", i)) {
        const b = block("<!--");
        if (b.done) return { ranges, open: b.open };
      }
      continue;
    }
    if (family === "slash" || family === "iss") {
      if (line.startsWith("//", i) && prev !== ":") {
        ranges.push([i, line.length]);
        break;
      }
      if (family === "slash" && line.startsWith("/*", i)) {
        const b = block("/*");
        if (b.done) return { ranges, open: b.open };
      }
      continue;
    }
    if (family === "ps" && line.startsWith("<#", i)) {
      const b = block("<#");
      if (b.done) return { ranges, open: b.open };
      continue;
    }
    if ((family === "hash" || family === "ps") && c === "#" && /\s/.test(prev)) {
      ranges.push([i, line.length]);
      break;
    }
  }
  return { ranges, open };
}

/** The braces a line opens minus those it closes, outside double-quoted strings (ARB). */
function depth(line) {
  let d = 0;
  let quoted = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (quoted) {
      if (c === "\\") i++;
      else if (c === '"') quoted = false;
    } else if (c === '"') quoted = true;
    else if (c === "{") d++;
    else if (c === "}") d--;
  }
  return d;
}

const KEY = /^\s*(?:"([\w@$.-]+)"|'([\w@.-]+)'|([A-Za-z_$][\w$]*))\s*:/;

const inside = (re, line, at) => {
  re.lastIndex = 0;
  for (const m of line.matchAll(re)) if (m.index <= at && at < m.index + m[0].length) return true;
  return false;
};

const tokenAt = (line, at, len) => {
  let s = at;
  let e = at + len;
  while (s > 0 && /[\w.-]/.test(line[s - 1])) s--;
  while (e < line.length && /[\w.-]/.test(line[e])) e++;
  return line.slice(s, e).replace(/^[.-]+|[.-]+$/g, "");
};

/** Every occurrence of an old name in one file, with its verdict. Pure. */
export function auditText(path, text, keep = []) {
  const lines = text.split(/\r?\n/);
  const family = familyOf(path, lines[0] ?? "");
  const prose = PROSE.has(extOf(path));
  const arb = extOf(path) === "arb";
  const json = arb || extOf(path) === "json";
  const phase = phaseOf(path);
  const forPath = keep.filter((e) => !e.pathRe || e.pathRe.test(path));
  const out = [];
  let open = null;
  let lastKey = null;
  let meta = 0;
  lines.forEach((line, n) => {
    const c = comments(line, family, open);
    open = c.open;
    let inMeta = meta > 0;
    if (arb) {
      if (meta === 0 && /^\s*"@[^"@][^"]*"\s*:\s*\{/.test(line)) {
        inMeta = true;
        meta = Math.max(0, depth(line));
      } else if (meta > 0) meta = Math.max(0, meta + depth(line));
    }
    const k = KEY.exec(line);
    if (k && !inMeta) lastKey = k[1] ?? k[2] ?? k[3];
    // A JSON file's "$comment" (a note for whoever reads the file) is a comment.
    if (json && k?.[1] === "$comment") inMeta = true;
    for (const m of line.matchAll(NAME)) {
      const at = m.index;
      const f = { path, line: n + 1, token: tokenAt(line, at, m[0].length), phase };
      const kept = forPath.find(
        (e) =>
          (!e.patternRe || inside(e.patternRe, line, at)) &&
          (!e.keyRe || (lastKey !== null && e.keyRe.test(lastKey))),
      );
      const internal = INTERNAL.find(([, re]) => inside(re, line, at));
      const before = line[at - 1] ?? "";
      const after = line[at + m[0].length] ?? "";
      if (kept)
        out.push({ ...f, kind: "kept", group: kept.group, why: kept.why, keep: kept.index });
      else if (internal) out.push({ ...f, kind: "internal", group: internal[0], why: internal[2] });
      else if (inMeta || c.ranges.some(([s, e]) => s <= at && at < e))
        out.push({ ...f, kind: "comment" });
      else if (VISIBLE.some(([, re]) => inside(re, line, at)))
        out.push({
          ...f,
          kind: "visible",
          group: VISIBLE.find(([, re]) => inside(re, line, at))[0],
        });
      else if (/[\w$]/.test(before) || /[\w$]/.test(after))
        out.push({ ...f, kind: "internal", group: "identifier", why: "a name in the code" });
      else if (/[A-Z ]/.test(m[0]) || prose) out.push({ ...f, kind: "visible" });
      else
        out.push({
          ...f,
          kind: "internal",
          group: "technical",
          why: "a lower-case technical name",
        });
    }
  });
  return out;
}

/** The visible occurrences by phase and file, every occurrence by kind, visible ones by token. */
export function summarize(findings) {
  const byKind = { visible: 0, comment: 0, internal: 0, kept: 0 };
  const phases = {};
  const tokens = {};
  for (const f of findings) {
    byKind[f.kind]++;
    if (f.kind !== "visible") continue;
    phases[f.phase] ??= { count: 0, files: {} };
    phases[f.phase].count++;
    phases[f.phase].files[f.path] = (phases[f.phase].files[f.path] ?? 0) + 1;
    tokens[f.token] ??= { count: 0, files: {} };
    tokens[f.token].count++;
    tokens[f.token].files[f.path] = (tokens[f.token].files[f.path] ?? 0) + 1;
  }
  return { visible: byKind.visible, byKind, phases, tokens };
}

const sortedFiles = (files) =>
  Object.entries(files).sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1));
const phaseOrder = (s) =>
  Object.keys(s.phases).sort(
    (a, b) => (a === "other") - (b === "other") || a.localeCompare(b, "en", { numeric: true }),
  );

export function markdown(s, unused = []) {
  const out = [
    `**${s.visible}** visible occurrences of the old names; ${s.byKind.comment} in comments, ${s.byKind.internal} internal, ${s.byKind.kept} kept (scripts/name-keep.json).`,
    "",
  ];
  for (const p of phaseOrder(s)) {
    const files = sortedFiles(s.phases[p].files);
    out.push(
      `### ${p} — ${PHASE_NAMES[p] ?? p}: ${s.phases[p].count} in ${files.length} files`,
      "",
    );
    for (const [f, n] of files) out.push(`- \`${f}\` ${n}`);
    out.push("");
  }
  if (unused.length) out.push(`Unused entries of name-keep.json: ${unused.join(", ")}`, "");
  return out.join("\n");
}

function main() {
  const { values } = parseArgs({
    options: {
      strict: { type: "boolean", default: false },
      lines: { type: "boolean", default: false },
      markdown: { type: "boolean", default: false },
      json: { type: "boolean", default: false },
    },
  });
  const root = execFileSync("git", ["rev-parse", "--show-toplevel"], { encoding: "utf8" }).trim();
  const keepList = JSON.parse(readFileSync(join(root, "scripts/name-keep.json"), "utf8"));
  const keep = parseKeep(keepList);
  const files = execFileSync("git", ["ls-files", "-z"], {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 1 << 26,
  })
    .split("\0")
    .filter(Boolean);
  const findings = [];
  for (const path of files) {
    let buf;
    try {
      buf = readFileSync(join(root, path));
    } catch {
      continue; // a submodule or a file deleted in the work tree
    }
    if (buf.subarray(0, 8000).includes(0)) continue; // binary
    findings.push(...auditText(path, buf.toString("utf8"), keep));
  }
  const s = summarize(findings);
  const used = new Set(findings.filter((f) => f.kind === "kept").map((f) => f.keep));
  const unused = keepList.flatMap((e, i) => (used.has(i) ? [] : [`#${i} ${e.path ?? e.pattern}`]));
  if (values.json) {
    console.log(
      JSON.stringify(
        { ...s, unused, findings: findings.filter((f) => f.kind === "visible") },
        null,
        1,
      ),
    );
  } else if (values.markdown) {
    console.log(markdown(s, unused));
  } else {
    console.log(
      `name-audit: ${s.visible} visible occurrences of the old names (${s.byKind.comment} in comments, ${s.byKind.internal} internal, ${s.byKind.kept} kept)`,
    );
    for (const p of phaseOrder(s)) {
      const files = sortedFiles(s.phases[p].files);
      console.log(`\n${p} ${PHASE_NAMES[p] ?? ""}: ${s.phases[p].count} in ${files.length} files`);
      for (const [f, n] of files) console.log(`  ${String(n).padStart(5)}  ${f}`);
    }
    if (values.lines) {
      console.log("");
      for (const f of findings)
        if (f.kind === "visible") console.log(`${f.path}:${f.line}: ${f.token}`);
    }
    for (const u of unused) console.log(`unused keep entry: ${u}`);
  }
  if (process.env.GITHUB_STEP_SUMMARY) {
    appendFileSync(
      process.env.GITHUB_STEP_SUMMARY,
      `## Old names (name-audit)\n\n${markdown(s, unused)}\n`,
    );
  }
  if (s.visible > 0) {
    if (process.env.GITHUB_ACTIONS) {
      const how = values.strict ? "error" : "warning";
      console.log(
        `::${how} title=Old names::${s.visible} visible occurrences of RedGiant/RGCompanion (name-audit)`,
      );
    }
    if (values.strict) process.exit(1);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
