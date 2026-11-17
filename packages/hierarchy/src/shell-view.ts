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
 * - shell words (`for x in …`, `case … in`, `do`, `then`, `if`…) and `case` labels.
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
} from "./critical.js";

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

/** One simple command as the rules read it: its words without the ones that are only data. */
function wordsRun(words: string[]): string[] {
  let ws = words;
  while (ws.length && (KEYWORDS.has(ws[0] as string) || /^[^\s()]*\)$/.test(ws[0] as string)))
    ws = ws.slice(1);
  const [first = "", ...args] = ws;
  const name = base(first);
  if (!name || WHOLE.has(name)) return [];
  if (WORDS_ONLY.has(name)) return [first];
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
export function commandsRun(command: string, depth = 0): string {
  if (depth > 3) return "";
  const { text, docs } = takeHeredocs(command);
  const lines: string[] = [];
  let pipe: string[] = [];
  /** Scripts written here by a heredoc, by file name: run later in the line, they are read. */
  const written = new Map<string, string>();
  const more = (s: string) => {
    const r = commandsRun(s, depth + 1);
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
    if (ws.length) pipe.push(ws.join(" "));
    if (c.sep !== "|" && pipe.length) {
      lines.push(pipe.join(" | "));
      pipe = [];
    }
  }
  if (pipe.length) lines.push(pipe.join(" | "));
  return lines.join("\n");
}
