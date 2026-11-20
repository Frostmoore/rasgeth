/**
 * What a shell line really runs, for the ordinary danger rules (p3.8.9). The rules are patterns
 * on text: on the raw line `which docker`, a `for c in … sudo …` list for `command -v`, or
 * `process.env` in a script written by a heredoc, asked the person for nothing (the GAIA project's
 * requests on Coder, in auto mode). Here the line becomes the commands it runs, one per line (a
 * pipeline stays on one line, joined by ` | `), without the words that are only data:
 *
 * - the text of a heredoc written into a file (a heredoc fed to a shell, or a script written here
 *   and then run, sourced or given to a shell in the same line, is read as run: prudence);
 * - the arguments of `which`, `command -v`, `type` (unless they look like files: PowerShell's
 *   `type` is `cat`), `whereis`, `hash`, `echo`, `printf`, `true`, `false`, `:`;
 * - the pattern of `grep` and the script of `sed`/`awk` (their files stay);
 * - shell words (`for x in …`, `case … in`, `do`, `then`, `if`…) and `case` labels;
 * - `sudo -n true`, `sudo -v`, `sudo -l`: they only test whether sudo would ask (p3.8.9);
 * - `rm -r` of folders strictly inside the project's folders (or in /tmp), followed through `cd`:
 *   no variable, no `~`, no `.git`, never the project's root itself (p3.8.9, Coder: `rm -rf x`
 *   before extracting a zip again into x). Without the folders known, it stays.
 *
 * - containers and hosts only looked at (`docker ps`, `pct exec N -- cat …`, 3.9.8): only what they
 *   run inside stays (`containerLook`).
 *
 * `$(…)` and backticks are commands of their own. Interpreters' inline code (`python -c`,
 * `node -e`) stays as it is: what it runs cannot be known, so its words still count. Pure.
 */
import { posix } from "node:path";
import {
  HEREDOC_MARK,
  type Heredoc,
  type Simple,
  simpleCommands,
  substitutions,
  takeHeredocs,
} from "@redgiant/protocol";
import { CONTAINER_TOOLS, containerLook } from "./container-look.js";

const SHELLS = new Set(["bash", "sh", "zsh", "dash", "ksh"]);
/** Commands whose arguments are only words: they run nothing and read no file. */
const WORDS_ONLY = new Set(["which", "whereis", "hash", "echo", "printf", "true", "false", ":"]);
/** Shell words in front of a command. */
const KEYWORDS = new Set(["do", "then", "else", "elif", "if", "while", "until", "!", "time"]);
/** Shell words that are the whole simple command (`for x in a b`, `case $x in`, `done`). */
const WHOLE = new Set(["for", "select", "case", "done", "fi", "esac", "in", "function"]);

const base = (w: string) => (w.split(/[\\/]/).at(-1) ?? "").toLowerCase();
const isFileLike = (w: string) => /[./\\]/.test(w);
const scriptKey = (w: string) => posix.basename(posix.normalize(w.replace(/\\/g, "/")));

/** Where a line runs: the project's folders and the folder it starts in (the first one). */
export interface ShellPlace {
  roots?: readonly string[] | undefined;
  cwd?: string | undefined;
}

const TMP = ["/tmp", "/var/tmp"];
const strictlyIn = (p: string, base: string) =>
  p.startsWith(base.endsWith("/") ? base : `${base}/`);

/**
 * Whether `rm -r` of these paths only drops work inside the project (or scratch in /tmp): each one
 * strictly inside one of its folders, never the folder itself, never a `.git`, no variable or `~`
 * (unknown places). Posix paths only; anything else stays a danger.
 */
function deletesOnlyWork(
  args: string[],
  cwd: string | undefined,
  roots: readonly string[],
): boolean {
  const targets = args.filter((a) => !a.startsWith("-"));
  if (targets.length === 0) return false;
  return targets.every((t) => {
    if (/[$`~\\]/.test(t)) return false;
    if (!t.startsWith("/") && !cwd) return false;
    const p = t.startsWith("/") ? posix.normalize(t) : posix.resolve(cwd as string, t);
    if (p.split("/").includes(".git")) return false;
    // A glob empties its folder: that folder must be strictly inside too.
    const at = /[*?[]/.test(posix.basename(p)) ? posix.dirname(p) : p;
    const inside = (base: string) => strictlyIn(at, posix.normalize(base).replace(/\/+$/, ""));
    return TMP.some(inside) || roots.some((r) => r.startsWith("/") && inside(r));
  });
}

/** sudo that only tests whether it would ask for a password: `sudo -n true`, `sudo -v`, `-l`. */
function sudoProbe(args: string[]): boolean {
  const opts = args.filter((a) => a.startsWith("-"));
  const rest = args.filter((a) => !a.startsWith("-"));
  if (
    opts.some((o) =>
      /^-[a-zA-Z]*[vlkK]|^--(validate|list|reset-timestamp|remove-timestamp)$/.test(o),
    ) &&
    rest.length === 0
  )
    return true;
  return (
    rest.length === 1 &&
    (rest[0] === "true" || rest[0] === ":") &&
    opts.every((o) => /^-[nS]+$/.test(o))
  );
}

/** One simple command as the rules read it: its words without the ones that are only data. */
function wordsRun(words: string[]): string[] {
  let ws = words;
  while (ws.length && (KEYWORDS.has(ws[0] as string) || /^[^\s()]*\)$/.test(ws[0] as string)))
    ws = ws.slice(1);
  const [first = "", ...args] = ws;
  const name = base(first);
  if (!name || WHOLE.has(name)) return [];
  if (WORDS_ONLY.has(name)) return [first];
  if ((name === "sudo" || name === "doas") && sudoProbe(args)) return [];
  if (name === "command" && args.some((a) => /^-[vV]+$/.test(a))) return [first];
  if (name === "type") return [first, ...args.filter(isFileLike)];
  if (name === "grep" || name === "egrep" || name === "fgrep" || name === "rg") {
    // The pattern: the first word that is not an option (or the value of -e).
    const out = [first];
    let dropped = false;
    for (let i = 0; i < args.length; i++) {
      const a = args[i] as string;
      if (a === "-e" || a === "--regexp") {
        i++;
        dropped = true;
      } else if (a.startsWith("-")) out.push(a);
      else if (!dropped) dropped = true;
      else out.push(a);
    }
    return out;
  }
  if (name === "sed" || name === "awk" || name === "gawk") {
    const out = [first];
    let dropped = false;
    for (let i = 0; i < args.length; i++) {
      const a = args[i] as string;
      if (a === "-e" || a === "--expression") {
        i++;
        dropped = true;
      } else if (a === "-f" || a === "-v") {
        out.push(a, args[++i] ?? "");
      } else if (a.startsWith("-")) out.push(a);
      else if (!dropped) dropped = true;
      else out.push(a);
    }
    return out;
  }
  return ws;
}

/**
 * The commands a shell line runs, one per line (a pipeline on one line, joined by ` | `), for the
 * danger rules' patterns. Pure.
 */
export function commandsRun(command: string, place: ShellPlace = {}, depth = 0): string {
  if (depth > 3) return "";
  const roots = place.roots ?? [];
  let cwd = place.cwd ?? roots[0];
  const { text, docs } = takeHeredocs(command);
  const lines: string[] = [];
  let pipe: string[] = [];
  /** Scripts written here by a heredoc, by file name: run later in the line, they are read. */
  const written = new Map<string, string>();
  const more = (s: string) => {
    const r = commandsRun(s, { roots, cwd }, depth + 1);
    if (r) lines.push(r);
  };
  for (const raw of simpleCommands(text)) {
    const mine: Heredoc[] = raw.words.flatMap((x) => {
      const m = HEREDOC_MARK.exec(x);
      return m ? [docs[Number(m[1])] as Heredoc] : [];
    });
    const c: Simple = { ...raw, words: raw.words.filter((x) => !HEREDOC_MARK.test(x)) };
    // $(…) and backticks run first, as commands of their own (in a heredoc only if unquoted).
    for (const s of substitutions(c.text)) more(s);
    for (const d of mine) if (!d.quoted) for (const s of substitutions(d.body)) more(s);
    const ws = wordsRun(c.words);
    const name = base(ws.find((w) => !/^\w+=/.test(w)) ?? "");
    const args = ws.slice(ws.findIndex((w) => !/^\w+=/.test(w)) + 1);
    const shell = SHELLS.has(name) && !args.some((a) => /^-[a-z]*c$/.test(a));
    if (mine.length) {
      if ((shell && !args.some((a) => !a.startsWith("-"))) || name === "ssh")
        for (const d of mine) more(d.body);
      else {
        const files = [
          ...c.redirects,
          ...(name === "tee" ? args.filter((a) => !a.startsWith("-")) : []),
        ];
        for (const f of files) written.set(scriptKey(f), mine.map((d) => d.body).join("\n"));
      }
    }
    if (written.size) {
      const script = shell
        ? args.find((a) => !a.startsWith("-"))
        : name === "source" || name === "."
          ? args[0]
          : /[\\/]/.test(ws[0] ?? "")
            ? ws[0]
            : undefined;
      const body = script !== undefined ? written.get(scriptKey(script)) : undefined;
      if (body !== undefined) more(body);
    }
    // `cd` moves the line (an unknown place: a variable, ~, a folder relative to an unknown one).
    if (name === "cd") {
      const to = args.find((a) => !a.startsWith("-"));
      cwd =
        to === undefined || /[$`~\\]/.test(to)
          ? undefined
          : to.startsWith("/")
            ? posix.normalize(to)
            : cwd && posix.resolve(cwd, to);
    }
    const onlyWork = name === "rm" && deletesOnlyWork(args, cwd, roots);
    // A container or host only looked at (3.9.8): what it runs inside, never the program itself.
    const look = CONTAINER_TOOLS.has(name)
      ? containerLook(ws.slice(ws.findIndex((w) => !/^\w+=/.test(w))))
      : undefined;
    if (look) {
      for (const s of look.scripts) more(s);
      const inner = wordsRun(look.words);
      if (inner.length) pipe.push(inner.join(" "));
    } else if (ws.length && !onlyWork) pipe.push(ws.join(" "));
    if (c.sep !== "|" && pipe.length) {
      lines.push(pipe.join(" | "));
      pipe = [];
    }
  }
  if (pipe.length) lines.push(pipe.join(" | "));
  return lines.join("\n");
}
