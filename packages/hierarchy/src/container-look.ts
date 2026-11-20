/**
 * Looking inside containers and hosts (3.9.8): `docker ps`, `docker inspect`, `pct exec N -- cat
 * …`, `kubectl get` only read, so the «Containers and clusters» rule must not ask for them (on
 * Coder an orchestrator working on Severino asked the person for every `pct exec … docker
 * inspect`). `containerLook` says whether a container or host command only looks, and what it
 * runs inside (for the other rules: `docker exec x cat .env` still reads a secret). Anything it
 * does not know, any write, any shell fed a script, stays a command that changes things. Pure.
 */
import { simpleCommands, substitutions, takeHeredocs } from "@redgiant/protocol";

/** The programs the «Containers and clusters» rule is about. */
export const CONTAINER_TOOLS: ReadonlySet<string> = new Set([
  "docker",
  "podman",
  "kubectl",
  "helm",
  "pct",
  "qm",
]);

/** What a looking command runs inside: words for the rules, and scripts given to a shell there. */
export interface Look {
  words: string[];
  scripts: string[];
}

const base = (w: string) => (w.split(/[\\/]/).at(-1) ?? "").toLowerCase();
// Each wrapper (a container, a shell, a script) takes two or three levels.
const MAX_DEPTH = 12;

/** Programs that only read or print, whatever their arguments (unless listed below). */
const READERS = new Set([
  "cat",
  "head",
  "tail",
  "ls",
  "stat",
  "wc",
  "du",
  "df",
  "file",
  "readlink",
  "realpath",
  "basename",
  "dirname",
  "pwd",
  "id",
  "whoami",
  "hostname",
  "uname",
  "date",
  "uptime",
  "free",
  "ps",
  "echo",
  "printf",
  "test",
  "[",
  "true",
  "false",
  "which",
  "grep",
  "egrep",
  "fgrep",
  "rg",
  "uniq",
  "cut",
  "tr",
  "jq",
  "ss",
  "netstat",
  "nproc",
  "lsblk",
  "getent",
  "md5sum",
  "sha256sum",
]);

/** Options of `find` that change or write something. */
const FIND_WRITES = /^-(delete|exec|execdir|ok|okdir|fprint0?|fprintf|fls)$/;
/** `ip` words that change the network. */
const IP_WRITES = new Set(["add", "del", "delete", "set", "flush", "change", "replace", "append"]);
/** git's subcommands that only read. */
const GIT_READS = new Set([
  "status",
  "diff",
  "log",
  "show",
  "rev-parse",
  "ls-files",
  "blame",
  "describe",
  "shortlog",
]);

/** The words after the leading `VAR=value` assignments. */
const command = (ws: string[]) =>
  ws.slice(
    Math.max(
      0,
      ws.findIndex((w) => !/^\w+=/.test(w)),
    ),
  );

/** The first word that is not an option, skipping the values of `valued` options. */
function sub(
  args: string[],
  valued: ReadonlySet<string>,
): { at: number; word: string } | undefined {
  for (let i = 0; i < args.length; i++) {
    const a = args[i] as string;
    if (a.startsWith("-")) {
      if (valued.has(a)) i++;
      continue;
    }
    return { at: i, word: a };
  }
  return undefined;
}

/** A redirect into a file (not /dev/null, not a descriptor). */
const writesFile = (redirects: string[]) =>
  redirects.some((r) => !/^\/dev\//.test(r) && !r.startsWith("&"));

/** Whether a whole script only reads (each command, each pipeline, no heredoc, no `$(…)`). */
function scriptReads(script: string, depth: number): boolean {
  if (depth > MAX_DEPTH) return false;
  const { text, docs } = takeHeredocs(script);
  if (docs.length || substitutions(text).length) return false;
  const all = simpleCommands(text);
  return all.length > 0 && all.every((c) => !writesFile(c.redirects) && reads(c.words, depth + 1));
}

/** A shell given a script with -c: the script; otherwise undefined. */
function shellScript(ws: string[]): string | undefined {
  const name = base(ws[0] ?? "");
  if (!["sh", "bash", "ash", "dash", "zsh"].includes(name)) return undefined;
  const c = ws.findIndex((w) => /^-[a-z]*c$/.test(w));
  return c > 0 ? ws[c + 1] : undefined;
}

/** Whether one command (its words, no file redirect) only reads. */
function reads(words: string[], depth: number): boolean {
  if (depth > MAX_DEPTH) return false;
  const ws = command(words);
  const name = base(ws[0] ?? "");
  const args = ws.slice(1);
  if (!name) return true;
  const script = shellScript(ws);
  if (script !== undefined) return scriptReads(script, depth + 1);
  if (CONTAINER_TOOLS.has(name)) return containerLook(ws, depth + 1) !== undefined;
  if (name === "find") return !args.some((a) => FIND_WRITES.test(a));
  if (name === "sed") return !args.some((a) => /^(-[a-zA-Z]*i|--in-place)/.test(a));
  if (name === "sort") return !args.some((a) => /^(-o|--output)/.test(a));
  // One variable, never the whole environment (its secrets).
  if (name === "printenv") return args.length > 0;
  if (name === "ip") return !args.some((a) => IP_WRITES.has(a));
  if (name === "git") {
    const s = sub(args, new Set(["-C", "-c", "--git-dir", "--work-tree"]));
    if (!s) return false;
    if (GIT_READS.has(s.word)) return true;
    // Listing only: no names after it (`git branch x` makes one).
    return (
      ["branch", "remote", "tag"].includes(s.word) &&
      args.slice(s.at + 1).every((a) => a.startsWith("-") && !/^-[dDmMcC]$|--delete/.test(a))
    );
  }
  return READERS.has(name);
}

/** What a command run inside a container or a host is, when it only reads. */
function inside(inner: string[], depth: number): Look | undefined {
  if (inner.length === 0 || depth > MAX_DEPTH) return undefined;
  const script = shellScript(inner);
  if (script !== undefined)
    return scriptReads(script, depth + 1) ? { words: [], scripts: [script] } : undefined;
  const name = base(command(inner)[0] ?? "");
  if (CONTAINER_TOOLS.has(name)) return containerLook(command(inner), depth + 1);
  return reads(inner, depth + 1) ? { words: inner, scripts: [] } : undefined;
}

const DOCKER_GLOBAL = new Set(["-H", "--host", "--context", "-c", "--config", "-l", "--log-level"]);
const DOCKER_READS = new Set([
  "ps",
  "inspect",
  "logs",
  "images",
  "stats",
  "top",
  "port",
  "version",
  "info",
  "history",
  "diff",
  "search",
]);
/** `docker <object> <verb>`: the objects, and the verbs that only read. */
const DOCKER_OBJECTS = new Set([
  "container",
  "image",
  "network",
  "volume",
  "system",
  "context",
  "node",
  "service",
  "stack",
  "secret",
  "config",
  "plugin",
  "buildx",
]);
const OBJECT_READS = new Set([
  "ls",
  "list",
  "ps",
  "inspect",
  "df",
  "info",
  "logs",
  "top",
  "port",
  "stats",
  "history",
  "show",
]);
const COMPOSE_VALUED = new Set([
  "-f",
  "--file",
  "-p",
  "--project-name",
  "--project-directory",
  "--env-file",
  "--profile",
  "--ansi",
  "--parallel",
]);
const COMPOSE_READS = new Set(["ps", "config", "logs", "ls", "images", "top", "version", "port"]);
const EXEC_VALUED = new Set([
  "-u",
  "--user",
  "-w",
  "--workdir",
  "-e",
  "--env",
  "--env-file",
  "--detach-keys",
]);
const KUBE_VALUED = new Set([
  "-n",
  "--namespace",
  "--context",
  "--kubeconfig",
  "--cluster",
  "--user",
  "-s",
  "--server",
  "-c",
  "--container",
  "-l",
  "--selector",
  "-o",
  "--output",
]);
const KUBE_READS = new Set([
  "get",
  "describe",
  "logs",
  "top",
  "version",
  "explain",
  "api-resources",
  "api-versions",
  "cluster-info",
]);
const HELM_READS = new Set([
  "list",
  "ls",
  "status",
  "get",
  "history",
  "show",
  "search",
  "version",
  "template",
  "lint",
  "env",
]);
const PVE_READS = new Set(["list", "config", "status", "pending", "df", "listsnapshot", "cpusets"]);

/**
 * A container or host command that only looks (`ws` starts with its program), with what it runs
 * inside; undefined when it may change something.
 */
export function containerLook(ws: string[], depth = 0): Look | undefined {
  if (depth > MAX_DEPTH) return undefined;
  const name = base(ws[0] ?? "");
  const args = ws.slice(1);
  const none: Look = { words: [], scripts: [] };
  if (name === "docker" || name === "podman") {
    const s = sub(args, DOCKER_GLOBAL);
    if (!s) return none;
    const rest = args.slice(s.at + 1);
    if (DOCKER_READS.has(s.word)) return none;
    if (DOCKER_OBJECTS.has(s.word)) {
      const verb = sub(rest, new Set());
      return verb && OBJECT_READS.has(verb.word) ? none : undefined;
    }
    if (s.word === "compose") {
      const verb = sub(rest, COMPOSE_VALUED);
      return verb && COMPOSE_READS.has(verb.word) ? none : undefined;
    }
    if (s.word === "exec") {
      if (rest.some((a) => a === "--privileged")) return undefined;
      const target = sub(rest, EXEC_VALUED);
      return target ? inside(rest.slice(target.at + 1), depth + 1) : undefined;
    }
    return undefined;
  }
  if (name === "kubectl") {
    const s = sub(args, KUBE_VALUED);
    if (!s) return none;
    const rest = args.slice(s.at + 1);
    if (KUBE_READS.has(s.word)) return none;
    if (s.word === "config") {
      const verb = sub(rest, new Set());
      return verb && ["view", "get-contexts", "current-context"].includes(verb.word)
        ? none
        : undefined;
    }
    if (s.word === "auth") return sub(rest, new Set())?.word === "can-i" ? none : undefined;
    if (s.word === "exec") {
      const dash = rest.indexOf("--");
      return dash >= 0 ? inside(rest.slice(dash + 1), depth + 1) : undefined;
    }
    return undefined;
  }
  if (name === "helm") {
    const s = sub(args, new Set(["-n", "--namespace", "--kube-context"]));
    return !s || HELM_READS.has(s.word) ? none : undefined;
  }
  if (name === "pct" || name === "qm") {
    const s = sub(args, new Set());
    if (!s) return none;
    if (PVE_READS.has(s.word)) return none;
    if (name === "pct" && s.word === "exec") {
      const dash = args.indexOf("--", s.at);
      return dash >= 0 ? inside(args.slice(dash + 1), depth + 1) : undefined;
    }
    return undefined;
  }
  return undefined;
}
