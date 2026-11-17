/**
 * What a shell command does, in one line the person reads before the command itself (p3.8.9:
 * «Scrive lo script start-wp.sh e lo esegue (start), poi contatta 127.0.0.1:8088» instead of the
 * raw JSON). Rules per program on the commands the line runs (`simpleCommands`, here-documents as
 * data), never a model: what only looks (ls, git status, which, df…) becomes one «Guarda …»; what
 * changes something says what and where; an unknown program says its name. Pure, it and en.
 */

import { HEREDOC_MARK, type Heredoc, simpleCommands, takeHeredocs } from "./shell-words.js";

type Lang = "it" | "en";
type Words = Record<Lang, string>;

/** What only looks, by kind: «Guarda file, stato di git e programmi installati (ls, …)». */
type LookKind = "files" | "git" | "programs" | "system";
const LOOK_WORDS: Record<LookKind, Words> = {
  files: { it: "file", en: "files" },
  git: { it: "stato di git", en: "git's state" },
  programs: { it: "programmi installati", en: "the installed programs" },
  system: { it: "il sistema", en: "the system" },
};
const LOOKS: Record<string, LookKind> = {
  ls: "files",
  dir: "files",
  cat: "files",
  head: "files",
  tail: "files",
  less: "files",
  more: "files",
  wc: "files",
  stat: "files",
  file: "files",
  tree: "files",
  find: "files",
  du: "files",
  grep: "files",
  rg: "files",
  pwd: "files",
  realpath: "files",
  readlink: "files",
  diff: "files",
  which: "programs",
  whereis: "programs",
  type: "programs",
  id: "system",
  df: "system",
  free: "system",
  uname: "system",
  whoami: "system",
  ps: "system",
  hostname: "system",
  uptime: "system",
  env: "system",
  printenv: "system",
  date: "system",
  lsb_release: "system",
  nproc: "system",
  lscpu: "system",
  lsblk: "system",
  top: "system",
  ss: "system",
  netstat: "system",
};
/** What reads the output of the command before it (`| head`): part of that step. */
const FILTERS = new Set([
  "head",
  "tail",
  "grep",
  "egrep",
  "sort",
  "uniq",
  "wc",
  "cut",
  "tr",
  "awk",
  "sed",
  "less",
  "more",
  "cat",
  "column",
  "jq",
  "xargs",
  "tee",
]);
/** Steps that say nothing by themselves. */
const SILENT = new Set([
  "cd",
  "pushd",
  "popd",
  "sleep",
  "true",
  "false",
  ":",
  "export",
  "set",
  "unset",
  "wait",
  "exit",
  "return",
  "local",
  "shift",
  "trap",
  "for",
  "select",
  "case",
  "esac",
  "do",
  "done",
  "if",
  "then",
  "else",
  "elif",
  "fi",
  "while",
  "until",
  "in",
  "function",
  "[",
  "[[",
  "test",
]);
const PREFIXES = new Set([
  "sudo",
  "doas",
  "env",
  "nohup",
  "setsid",
  "time",
  "nice",
  "exec",
  "builtin",
  "stdbuf",
]);
/** Printing a text: a step only when the line does nothing else. */
const PRINTS = new Set(["echo", "printf", "write-output", "write-host"]);
const SHELLS = new Set(["bash", "sh", "zsh", "dash", "ksh"]);
const INTERPRETERS = new Set([
  "node",
  "python",
  "python3",
  "php",
  "ruby",
  "perl",
  "deno",
  "bun",
  "tsx",
  "ts-node",
  "pwsh",
  "powershell",
]);
const PMS = new Set(["npm", "pnpm", "yarn", "bun"]);
const SYSTEM_PMS = new Set(["apt", "apt-get", "dnf", "yum", "brew", "apk", "zypper", "pacman"]);
/** Docker's options followed by a value (`-p 80:80`): not the image. */
const DOCKER_VALUE =
  /^(-[pvewulm]|--(name|network|env|volume|publish|workdir|entrypoint|user|label|mount|platform|env-file|memory|cpus|restart|hostname|add-host|device|gpus))$/;

const base = (w: string) => (w.split(/[\\/]/).at(-1) ?? "").replace(/\.exe$/i, "").toLowerCase();
const plain = (args: string[]) => args.filter((a) => !a.startsWith("-"));
const hostOf = (args: string[]) => {
  for (const a of args)
    if (/^https?:\/\//i.test(a))
      try {
        return new URL(a).host;
      } catch {
        // not a URL after all
      }
  return undefined;
};
const cut = (s: string, max = 60) => (s.length > max ? `${s.slice(0, max - 1)}…` : s);
const list = (l: Lang, xs: string[], max = 2) => {
  const shown = xs.slice(0, max).map((x) => cut(x, 50));
  const more = xs.length - shown.length;
  const and = l === "it" ? " e " : " and ";
  if (more > 0) return `${shown.join(", ")}${and}${l === "it" ? `altri ${more}` : `${more} more`}`;
  return shown.length <= 1
    ? (shown[0] ?? "")
    : `${shown.slice(0, -1).join(", ")}${and}${shown.at(-1)}`;
};
const inParens = (xs: string[]) => (xs.length ? ` (${cut(xs.slice(0, 3).join(" "), 60)})` : "");
const lower = (s: string) => s.charAt(0).toLowerCase() + s.slice(1);
const upper = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

/** One step of the line: words, or the shared «look» step, or a script written (and maybe run). */
type Step =
  | { kind: "say"; words: Words; filler?: boolean }
  | { kind: "look"; kinds: LookKind[]; names: string[] }
  | { kind: "write"; path: string; ran?: string[] };

/** What one program does, both languages; undefined when it says nothing. */
function sayOf(name: string, args: string[], depth: number): Words | "look" | undefined {
  const p = plain(args);
  const both = (it: string, en: string): Words => ({ it, en });
  if (SHELLS.has(name)) {
    const c = args.findIndex((a) => /^-[a-z]*c$/.test(a));
    if (c >= 0) return inner(args[c + 1] ?? "", depth);
    if (p[0])
      return both(
        `Esegue lo script ${base(p[0])}${inParens(p.slice(1))}`,
        `Runs the script ${base(p[0])}${inParens(p.slice(1))}`,
      );
    return undefined;
  }
  if (name === "ssh") {
    let i = 0;
    while (i < args.length && (args[i] as string).startsWith("-"))
      i += /^-[bcDEeFIiJLlmOoPpRSWw]$/.test(args[i] as string) ? 2 : 1;
    const host = args[i] ?? "?";
    const rest = args.slice(i + 1).join(" ");
    const there = rest ? inner(rest, depth) : undefined;
    return there
      ? both(`Su ${host}: ${lower(there.it)}`, `On ${host}: ${lower(there.en)}`)
      : both(`Apre una sessione su ${host}`, `Opens a session on ${host}`);
  }
  if (name === "git") {
    const sub = p[0] ?? "";
    const rest = p.slice(1);
    if (
      [
        "status",
        "log",
        "diff",
        "show",
        "remote",
        "rev-parse",
        "describe",
        "blame",
        "ls-files",
      ].includes(sub) ||
      (sub === "branch" && rest.length === 0)
    )
      return "look";
    if (sub === "push")
      return rest[0]
        ? both(
            `Manda i commit a ${rest[0]}${inParens(rest.slice(1))}`,
            `Pushes the commits to ${rest[0]}${inParens(rest.slice(1))}`,
          )
        : both("Manda i commit", "Pushes the commits");
    if (sub === "commit") return both("Fa un commit", "Makes a commit");
    if (sub === "add") return both("Prepara dei file per il commit", "Stages files for a commit");
    if (sub === "pull" || sub === "fetch")
      return both("Scarica le modifiche del repository", "Fetches the repository's changes");
    if (sub === "clone")
      return both(
        `Copia il repository ${cut(rest[0] ?? "?")}`,
        `Clones the repository ${cut(rest[0] ?? "?")}`,
      );
    if (sub === "checkout" || sub === "switch")
      return both(
        `Passa a ${rest[0] ?? "un altro ramo"}`,
        `Switches to ${rest[0] ?? "another branch"}`,
      );
    return both(`Esegue git ${sub}`.trim(), `Runs git ${sub}`.trim());
  }
  if (PMS.has(name)) {
    const sub = p[0] ?? "install";
    const rest = p.slice(1);
    if (["install", "i", "add", "ci"].includes(sub))
      return both(
        `Installa i pacchetti${inParens(rest)}`,
        `Installs the packages${inParens(rest)}`,
      );
    const script = sub === "run" ? (rest[0] ?? "") : sub;
    if (["test", "t"].includes(script)) return both("Esegue i test", "Runs the tests");
    if (script === "build") return both("Compila il progetto", "Builds the project");
    if (sub === "publish") return both("Pubblica il pacchetto", "Publishes the package");
    if (sub === "exec" || sub === "dlx" || sub === "x")
      return both(`Esegue ${rest[0] ?? "un programma"}`, `Runs ${rest[0] ?? "a program"}`);
    return both(`Esegue lo script ${script} del progetto`, `Runs the project's script ${script}`);
  }
  if (["pip", "pip3", "uv", "pipx"].includes(name) && p.includes("install")) {
    const names = p.slice(p.indexOf("install") + 1);
    return both(
      `Installa i pacchetti Python${inParens(names)}`,
      `Installs the Python packages${inParens(names)}`,
    );
  }
  if (SYSTEM_PMS.has(name)) {
    const sub = p[0] ?? "";
    if (["install", "add", "-S"].includes(sub))
      return both(
        `Installa programmi di sistema${inParens(p.slice(1))}`,
        `Installs system programs${inParens(p.slice(1))}`,
      );
    if (["remove", "purge", "del", "uninstall"].includes(sub))
      return both(
        `Toglie programmi di sistema${inParens(p.slice(1))}`,
        `Removes system programs${inParens(p.slice(1))}`,
      );
    return both(
      `Aggiorna o cerca programmi di sistema (${name} ${sub})`.trim(),
      `Updates or looks up system programs (${name} ${sub})`.trim(),
    );
  }
  if (name === "docker" || name === "podman") {
    const sub = p[0] ?? "";
    if (sub === "run") {
      const after = args.slice(args.indexOf("run") + 1);
      let image: string | undefined;
      for (let i = 0; i < after.length; i++) {
        const a = after[i] as string;
        if (DOCKER_VALUE.test(a)) i++;
        else if (!a.startsWith("-")) {
          image = a;
          break;
        }
      }
      return both(
        `Avvia un container${inParens(image ? [image] : [])}`,
        `Starts a container${inParens(image ? [image] : [])}`,
      );
    }
    if (sub === "compose") {
      if (p.includes("up"))
        return both("Avvia i container del progetto", "Starts the project's containers");
      if (p.includes("down") || p.includes("stop"))
        return both("Ferma i container del progetto", "Stops the project's containers");
    }
    if (sub === "build") return both("Costruisce un'immagine", "Builds an image");
    if (["ps", "images", "logs", "inspect", "version", "info"].includes(sub)) return "look";
    return both(`Usa ${name} ${sub}`.trim(), `Uses ${name} ${sub}`.trim());
  }
  if (name === "curl" || name === "wget") {
    const host = hostOf(args) ?? "?";
    const saves = name === "wget" || args.some((a) => /^-(o|O|-output|-remote-name)$/.test(a));
    return saves
      ? both(`Scarica da ${host}`, `Downloads from ${host}`)
      : both(`Contatta ${host}`, `Contacts ${host}`);
  }
  if (INTERPRETERS.has(name)) {
    const server = name === "php" ? args[args.indexOf("-S") + 1] : undefined;
    if (args.includes("-S") && server) {
      const port = server.split(":").at(-1);
      return both(`Avvia un server sulla porta ${port}`, `Starts a server on port ${port}`);
    }
    if (args.includes("-m") && args[args.indexOf("-m") + 1] === "http.server")
      return both("Avvia un server di file", "Starts a file server");
    if (args.some((a) => /^-(c|e|r|-eval|Command)$/i.test(a)))
      return both(`Esegue codice ${name}`, `Runs ${name} code`);
    const file = p.find((a) => a !== "-m");
    if (file)
      return both(
        `Esegue lo script ${base(file)} con ${name}`,
        `Runs the script ${base(file)} with ${name}`,
      );
    return both(`Esegue ${name}`, `Runs ${name}`);
  }
  if (
    ["pytest", "vitest", "jest", "mocha", "phpunit"].includes(name) ||
    (["cargo", "go"].includes(name) && p[0] === "test")
  )
    return both("Esegue i test", "Runs the tests");
  if (name === "tsc" || (["cargo", "go"].includes(name) && p[0] === "build"))
    return both("Compila il progetto", "Builds the project");
  if (name === "make") return both(`Esegue make${inParens(p)}`, `Runs make${inParens(p)}`);
  if (["rm", "del", "erase", "rmdir", "rd", "remove-item", "unlink", "shred"].includes(name))
    return both(`Cancella ${list("it", p) || "dei file"}`, `Deletes ${list("en", p) || "files"}`);
  if (name === "mkdir")
    return both(`Crea la cartella ${p[0] ?? "?"}`, `Creates the folder ${p[0] ?? "?"}`);
  if (name === "touch")
    return both(`Crea il file ${p[0] ?? "?"}`, `Creates the file ${p[0] ?? "?"}`);
  if (name === "cp" || name === "copy" || name === "copy-item")
    return both(
      `Copia ${p[0] ?? "?"} in ${p.at(-1) ?? "?"}`,
      `Copies ${p[0] ?? "?"} to ${p.at(-1) ?? "?"}`,
    );
  if (name === "mv" || name === "move" || name === "move-item")
    return both(
      `Sposta ${p[0] ?? "?"} in ${p.at(-1) ?? "?"}`,
      `Moves ${p[0] ?? "?"} to ${p.at(-1) ?? "?"}`,
    );
  if (name === "ln")
    return both(`Crea un collegamento a ${p[0] ?? "?"}`, `Creates a link to ${p[0] ?? "?"}`);
  if (name === "chmod" || name === "chown")
    return both(
      `Cambia i permessi di ${list("it", p.slice(1)) || "?"}`,
      `Changes the permissions of ${list("en", p.slice(1)) || "?"}`,
    );
  if (name === "tar" || name === "unzip" || name === "zip" || name === "7z") {
    const extract = name === "unzip" || (name === "tar" && /x/.test(args[0] ?? "")) || p[0] === "x";
    const file = p.find((a) => /\.(tar|tgz|gz|zip|7z|xz|bz2)$/.test(a)) ?? p[0] ?? "?";
    return extract
      ? both(`Estrae ${file}`, `Extracts ${file}`)
      : both(`Crea l'archivio ${file}`, `Creates the archive ${file}`);
  }
  if (name === "kill" || name === "pkill" || name === "killall") {
    const what = name === "kill" ? [] : p;
    return both(`Ferma dei processi${inParens(what)}`, `Stops processes${inParens(what)}`);
  }
  if (name === "systemctl" || name === "service") {
    const [a = "", b = ""] =
      name === "service" ? [p[1] ?? "", p[0] ?? ""] : [p[0] ?? "", p[1] ?? ""];
    const verbs: Record<string, Words> = {
      start: { it: "Avvia", en: "Starts" },
      stop: { it: "Ferma", en: "Stops" },
      restart: { it: "Riavvia", en: "Restarts" },
      reload: { it: "Ricarica", en: "Reloads" },
      enable: { it: "Attiva all'avvio", en: "Enables at boot" },
      disable: { it: "Disattiva all'avvio", en: "Disables at boot" },
    };
    const v = verbs[a];
    if (v) return both(`${v.it} il servizio ${b}`, `${v.en} the service ${b}`);
    return "look";
  }
  if (name === "echo" || name === "printf" || name === "write-output" || name === "write-host")
    return both("Scrive un testo nel risultato", "Prints a text");
  if (name === "command" && args.some((a) => /^-[vV]+$/.test(a))) return "look";
  if (LOOKS[name]) return "look";
  return both(`Esegue ${cut(name, 40)}`, `Runs ${cut(name, 40)}`);
}

/** The line inside `bash -c '…'` or `ssh host '…'`, said in one sentence of its own. */
function inner(command: string, depth: number): Words | undefined {
  if (depth > 2) return undefined;
  const steps = stepsOf(command, depth + 1);
  if (!steps.length) return undefined;
  return { it: sentence("it", steps), en: sentence("en", steps) };
}

function stepsOf(command: string, depth: number): Step[] {
  const { text, docs } = takeHeredocs(command);
  const steps: Step[] = [];
  const written = new Map<string, Extract<Step, { kind: "write" }>>();
  let look: Extract<Step, { kind: "look" }> | undefined;
  let afterPipe = false;
  for (const c of simpleCommands(text)) {
    const piped = afterPipe;
    afterPipe = c.sep === "|";
    const mine: Heredoc[] = c.words.flatMap((x) => {
      const m = HEREDOC_MARK.exec(x);
      return m ? [docs[Number(m[1])] as Heredoc] : [];
    });
    let ws = c.words.filter((x) => !HEREDOC_MARK.test(x));
    // Shell words and `case` labels in front.
    while (
      ws.length &&
      (["do", "then", "else", "elif", "if", "while", "until", "!"].includes(ws[0] as string) ||
        /^[^\s()]*\)$/.test(ws[0] as string))
    )
      ws = ws.slice(1);
    let admin = false;
    for (;;) {
      const b = base(ws[0] ?? "");
      if (/^\w+=/.test(ws[0] ?? "")) ws = ws.slice(1);
      else if (b === "timeout" || b === "xargs") {
        // timeout [options] 60 cmd…, xargs [options] cmd…
        ws = ws.slice(1);
        while (ws[0]?.startsWith("-")) ws = ws.slice(1);
        if (b === "timeout" && /^\d/.test(ws[0] ?? "")) ws = ws.slice(1);
      } else if (PREFIXES.has(b)) {
        if (b === "sudo" || b === "doas") admin = true;
        ws = ws.slice(1);
        while (ws[0]?.startsWith("-")) ws = ws.slice(/^-(u|g|n)$/.test(ws[0]) ? 2 : 1);
      } else break;
    }
    const [first = "", ...args] = ws;
    const name = base(first);
    const files = c.redirects.filter((r) => !/^\/dev\//.test(r) && !/^&/.test(r));
    if (!name && !files.length) continue;
    if (SILENT.has(name)) continue;
    if (piped && FILTERS.has(name)) continue;
    // A here-document written into a file: the file is what matters.
    const target = files[0] ?? (name === "tee" ? plain(args)[0] : undefined);
    if (mine.length && target && !SHELLS.has(name)) {
      const w: Step = { kind: "write", path: target };
      written.set(base(target), w);
      steps.push(w);
      continue;
    }
    // A script written above and run now: one step, «writes the script and runs it».
    const runs = SHELLS.has(name)
      ? plain(args)[0]
      : name === "source" || name === "."
        ? args[0]
        : /[\\/]/.test(first)
          ? first
          : undefined;
    const done = runs !== undefined ? written.get(base(runs)) : undefined;
    if (done) {
      done.ran =
        SHELLS.has(name) || name === "source" || name === "." ? plain(args).slice(1) : args;
      continue;
    }
    // chmod +x on the script just written says nothing.
    if (
      name === "chmod" &&
      plain(args)
        .slice(1)
        .every((a) => written.has(base(a)))
    )
      continue;
    if (
      /[\\/]/.test(first) &&
      !LOOKS[name] &&
      /\.(sh|bash|ps1|py|js|rb|pl)$|^[^.]*$/.test(name) &&
      !INTERPRETERS.has(name)
    ) {
      steps.push({
        kind: "say",
        words: {
          it: `Esegue lo script ${name}${inParens(args)}`,
          en: `Runs the script ${name}${inParens(args)}`,
        },
      });
      continue;
    }
    if ((name === "echo" || name === "printf" || name === "cat") && files.length && !mine.length) {
      steps.push({
        kind: "say",
        words: { it: `Scrive in ${files[0]}`, en: `Writes into ${files[0]}` },
      });
      continue;
    }
    if (mine.length && SHELLS.has(name)) {
      const said = inner(mine.map((d) => d.body).join("\n"), depth);
      if (said) steps.push({ kind: "say", words: said });
      continue;
    }
    const said = sayOf(name, args, depth);
    if (said === undefined) continue;
    if (said === "look") {
      const kind: LookKind =
        LOOKS[name] ?? (name === "git" ? "git" : name === "command" ? "programs" : "system");
      const label =
        name === "git" || name === "docker" || name === "podman" || name === "systemctl"
          ? `${name} ${plain(args)[0] ?? args[0] ?? ""}`.trim()
          : name === "command"
            ? "command -v"
            : name;
      if (!look) {
        look = { kind: "look", kinds: [], names: [] };
        steps.push(look);
      }
      if (!look.kinds.includes(kind)) look.kinds.push(kind);
      if (!look.names.includes(label)) look.names.push(label);
      continue;
    }
    steps.push({
      kind: "say",
      words: admin
        ? { it: `${said.it}, come amministratore`, en: `${said.en}, as administrator` }
        : said,
      ...(PRINTS.has(name) && { filler: true }),
    });
  }
  // Printing a text says something only when nothing else happens.
  const real = steps.filter((x) => !(x.kind === "say" && x.filler));
  return pipeIntoShell(command, real.length ? real : steps);
}

/** `curl … | sh`: the download step says it runs what it gets. */
function pipeIntoShell(command: string, steps: Step[]): Step[] {
  if (!/(curl|wget)[^|\n]*\|\s*(sudo\s+)?(ba|z)?sh\b/.test(command)) return steps;
  return steps.map((s) =>
    s.kind === "say" && /^(Scarica da|Contatta) /.test(s.words.it)
      ? {
          kind: "say",
          words: {
            it: `${s.words.it.replace(/^Contatta /, "Scarica da ")} ed esegue quello che riceve`,
            en: `${s.words.en.replace(/^Contacts /, "Downloads from ")} and runs what it gets`,
          },
        }
      : s,
  );
}

function stepText(l: Lang, s: Step): string {
  if (s.kind === "say") return s.words[l];
  if (s.kind === "write") {
    if (s.ran === undefined)
      return l === "it" ? `Scrive il file ${s.path}` : `Writes the file ${s.path}`;
    const args = inParens(s.ran);
    return l === "it"
      ? `Scrive lo script ${s.path} e lo esegue${args}`
      : `Writes the script ${s.path} and runs it${args}`;
  }
  const kinds = s.kinds.map((k) => LOOK_WORDS[k][l]);
  const what =
    kinds.length <= 1
      ? (kinds[0] ?? "")
      : `${kinds.slice(0, -1).join(", ")}${l === "it" ? " e " : " and "}${kinds.at(-1)}`;
  const names = s.names.slice(0, 5).join(", ");
  return l === "it" ? `Guarda ${what} (${names})` : `Looks at ${what} (${names})`;
}

/** The steps as one sentence: the first three, then how many more. */
function sentence(l: Lang, steps: Step[]): string {
  const shown = steps.slice(0, 3).map((s, i) => (i === 0 ? stepText(l, s) : lower(stepText(l, s))));
  const more = steps.length - shown.length;
  const tail = more > 0 ? (l === "it" ? ` e altri ${more} passi` : ` and ${more} more steps`) : "";
  return upper(shown.join(l === "it" ? ", poi " : ", then ") + tail);
}

/**
 * What a shell command does, in the person's language: «Guarda file e programmi installati (ls,
 * which)», «Scrive lo script x.sh e lo esegue (start), poi contatta 127.0.0.1:8088». The command
 * stays in the details. Pure.
 */
export function shellSummary(
  lang: string,
  command: string,
  o: { background?: boolean | undefined } = {},
): string {
  const l: Lang = lang === "it" ? "it" : "en";
  if (!command.trim()) return l === "it" ? "Esegue un comando vuoto" : "Runs an empty command";
  const steps = stepsOf(command, 0);
  const said = steps.length
    ? sentence(l, steps)
    : l === "it"
      ? `Esegue il comando: ${cut(command.replace(/\s*\n\s*/g, "; "), 120)}`
      : `Runs the command: ${cut(command.replace(/\s*\n\s*/g, "; "), 120)}`;
  const line = o.background
    ? l === "it"
      ? `In sottofondo: ${lower(said)}`
      : `In the background: ${lower(said)}`
    : said;
  return line.length > 190 ? `${line.slice(0, 189)}…` : line;
}
