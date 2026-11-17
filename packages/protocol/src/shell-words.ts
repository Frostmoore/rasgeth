/**
 * A shell line read roughly as bash, PowerShell or cmd would (p3.8.9: shared by the truly
 * dangerous rules, `criticalOf`, the danger rules' `commandsRun` and the request's sentence,
 * `requestSentence`): simple commands with their words and redirections, and here-documents taken
 * out as data. Pure.
 */

export interface Simple {
  words: string[];
  /** Files the output goes to (> and >>). */
  redirects: string[];
  /** The text of this command, as written. */
  text: string;
  /** What ends it: `|` sends its output to the next one (p3.8.9). */
  sep?: string;
}

/** Splits a command line into simple commands, roughly as bash, PowerShell or cmd would. */
export function simpleCommands(command: string): Simple[] {
  const out: Simple[] = [];
  let words: string[] = [];
  let redirects: string[] = [];
  let cur = "";
  let has = false;
  let quote: string | null = null;
  let start = 0;
  let nextIsRedirect = false;
  const push = () => {
    if (has) {
      if (nextIsRedirect) {
        if (!cur.startsWith("&")) redirects.push(cur);
        nextIsRedirect = false;
      } else words.push(cur);
    }
    cur = "";
    has = false;
  };
  const end = (i: number) => {
    push();
    const sep = command.slice(i, i + 2) === "||" ? "||" : (command[i] ?? "");
    if (words.length || redirects.length)
      out.push({ words, redirects, text: command.slice(start, i).trim(), sep });
    words = [];
    redirects = [];
    start = i + 1;
  };
  for (let i = 0; i < command.length; i++) {
    const c = command[i] as string;
    if (quote) {
      if (c === quote) quote = null;
      else cur += c;
      continue;
    }
    if (c === "'" || c === '"') {
      quote = c;
      has = true;
      continue;
    }
    const two = command.slice(i, i + 2);
    if (two === "&&" || two === "||") {
      end(i);
      start = i + 2;
      i++;
      continue;
    }
    if (c === ";" || c === "|" || c === "\n" || (c === "&" && command[i + 1] !== ">")) {
      end(i);
      continue;
    }
    // Redirections: > >> 2> &> *> >|, and 2>&1 (not a file).
    if (c === ">" || (/[12*&]/.test(c) && command[i + 1] === ">" && !has)) {
      push();
      if (c !== ">") i++;
      while (command[i + 1] === ">") i++;
      if (command[i + 1] === "|") i++;
      if (command[i + 1] === "&") {
        i++;
        while (i + 1 < command.length && /\d/.test(command[i + 1] as string)) i++;
        continue;
      }
      nextIsRedirect = true;
      continue;
    }
    if (c === " " || c === "\t" || c === "\r") {
      push();
      continue;
    }
    if ((c === "(" || c === ")" || c === "{" || c === "}") && !has) continue;
    cur += c;
    has = true;
  }
  end(command.length);
  return out;
}

/** A here-document (`<<EOF … EOF`): its text, and whether `$(…)` in it runs (delimiter unquoted). */
export interface Heredoc {
  body: string;
  quoted: boolean;
}
export const HEREDOC_MARK = /^__rg_heredoc_(\d+)__$/;

/**
 * Takes the here-documents out of a command (p3.8.9, 146.jpg): their text is data for the command
 * that gets it, not commands run now. Each operator becomes a word `__rg_heredoc_N__` the command
 * keeps, so the rules know who reads it (a shell runs it, `cat > file` writes it). Quotes are
 * followed across lines, roughly: an operator inside quotes is text (`bash -c '…'` reads its own).
 */
export function takeHeredocs(command: string): { text: string; docs: Heredoc[] } {
  const docs: Heredoc[] = [];
  const out: string[] = [];
  const lines = command.split("\n");
  let quote: string | null = null;
  for (let n = 0; n < lines.length; n++) {
    const line = lines[n] as string;
    const pending: { delim: string; strip: boolean; doc: Heredoc }[] = [];
    let text = "";
    for (let i = 0; i < line.length; i++) {
      const c = line[i] as string;
      if (quote) {
        if (c === quote) quote = null;
        else if (c === "\\" && quote === '"') {
          text += c + (line[i + 1] ?? "");
          i++;
          continue;
        }
        text += c;
        continue;
      }
      if (c === "\\") {
        text += c + (line[i + 1] ?? "");
        i++;
        continue;
      }
      if (c === "'" || c === '"') {
        quote = c;
        text += c;
        continue;
      }
      const m = /^<<(-?)[ \t]*(?:'([^']*)'|"([^"]*)"|\\?([^\s;&|<>()'"]+))/.exec(line.slice(i));
      if (m && line[i - 1] !== "<" && line[i + 2] !== "<") {
        const doc: Heredoc = { body: "", quoted: m[2] !== undefined || m[3] !== undefined };
        pending.push({ delim: m[2] ?? m[3] ?? m[4] ?? "", strip: m[1] === "-", doc });
        text += ` __rg_heredoc_${docs.length}__ `;
        docs.push(doc);
        i += m[0].length - 1;
        continue;
      }
      text += c;
    }
    out.push(text);
    // The bodies follow the line, one after the other, each up to its delimiter alone on a line.
    for (const p of pending) {
      const body: string[] = [];
      while (++n < lines.length) {
        const l = p.strip ? (lines[n] as string).replace(/^\t+/, "") : (lines[n] as string);
        if (l === p.delim) break;
        body.push(l);
      }
      p.doc.body = body.join("\n");
    }
  }
  return { text: out.join("\n"), docs };
}

/** What runs when an unquoted here-document is read: its `$(…)` and backticks. */
export const substitutions = (body: string) =>
  [...body.matchAll(/\$\(((?:[^()]|\([^()]*\))*)\)|`([^`]*)`/g)].map((m) => m[1] ?? m[2] ?? "");
