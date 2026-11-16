/**
 * Local MCP servers in their own sandbox (G41.0): pure rules shared by the server and the page.
 * A local server runs in a container of its own (one per person and server), with only its own
 * folder mounted (the npm/uv cache), its packages at an exact version, installed once with the
 * registries open, then run with the network open only to its `hosts`.
 */

/** The programs that install packages, and the registries they need while installing. */
export type McpRunner = "npx" | "uvx";

export const MCP_INSTALL_HOSTS: Record<McpRunner, readonly string[]> = {
  npx: ["registry.npmjs.org"],
  uvx: ["pypi.org", "files.pythonhosted.org"],
};

/** The programs the MCP sandbox image has (docker/mcp.Dockerfile). */
export const MCP_SANDBOX_COMMANDS: readonly string[] = [
  "npx",
  "npm",
  "node",
  "uvx",
  "uv",
  "python3",
  "python",
  "bash",
  "sh",
];

/** The server's folder inside its sandbox (its cache and its own files). */
export const MCP_SANDBOX_HOME = "/workspace";

/** A package a local server runs, with its version when it names one exactly. */
export interface McpPin {
  runner: McpRunner;
  package: string;
  /** Exact (`1.2.3`, `1.2.3-beta.1`): absent when the command names none, a range or a tag. */
  version?: string;
  /** What the command named after the package (`latest`, `^1`), when not an exact version. */
  tag?: string;
  /** Where the package's name sits in the arguments. */
  index: number;
  /** uvx `--from <package> <command>`: the program to run, another than the package's name. */
  executable?: string;
}

const EXACT = /^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;

/** An exact version (never a range, a tag or `latest`). */
export const isExactVersion = (v: string): boolean => EXACT.test(v);

/** `@scope/name@1.2.3` → name and what follows the last `@` (a scope's own `@` is not a version). */
function splitNpm(spec: string): { name: string; version?: string } {
  const at = spec.lastIndexOf("@");
  if (at <= 0) return { name: spec };
  return { name: spec.slice(0, at), version: spec.slice(at + 1) };
}

/** `name==1.2.3`, `name@1.2.3`, `name`. */
function splitPy(spec: string): { name: string; version?: string } {
  const eq = spec.indexOf("==");
  if (eq > 0) return { name: spec.slice(0, eq), version: spec.slice(eq + 2) };
  const at = spec.indexOf("@");
  if (at > 0) return { name: spec.slice(0, at), version: spec.slice(at + 1) };
  return { name: spec };
}

/** npx flags that take a value (the value is not the package). */
const NPX_VALUED = new Set(["--package", "-p", "--call", "-c", "--registry", "--cache"]);
const UVX_VALUED = new Set(["--with", "--python", "-p", "--index", "--index-url", "--from"]);

/** The package a local server's command runs, if it runs one through npx or uvx. */
export function pinOf(command: string, args: readonly string[]): McpPin | undefined {
  const runner = runnerOf(command);
  if (!runner) return undefined;
  for (let i = 0; i < args.length; i++) {
    const a = args[i] ?? "";
    if (runner === "uvx" && a === "--from") {
      const spec = args[i + 1];
      if (!spec) return undefined;
      const p = splitPy(spec);
      return pinned(runner, p, i + 1, args[i + 2]);
    }
    if (a.startsWith("-")) {
      if ((runner === "npx" ? NPX_VALUED : UVX_VALUED).has(a)) i++;
      continue;
    }
    return pinned(runner, runner === "npx" ? splitNpm(a) : splitPy(a), i);
  }
  return undefined;
}

function pinned(
  runner: McpRunner,
  p: { name: string; version?: string },
  index: number,
  executable?: string,
): McpPin {
  const exact = p.version !== undefined && isExactVersion(p.version);
  return {
    runner,
    package: p.name,
    ...(exact && p.version
      ? { version: p.version }
      : p.version !== undefined
        ? { tag: p.version }
        : {}),
    index,
    ...(executable && { executable }),
  };
}

/** `npx`, `npx.cmd`, `/usr/bin/npx` → npx. */
function runnerOf(command: string): McpRunner | undefined {
  const base = command.split(/[\\/]/).pop()?.toLowerCase().replace(/\.(cmd|exe)$/, "");
  return base === "npx" || base === "uvx" ? base : undefined;
}

/** The arguments with the package at `version` (for "Update", and to pin a server at its first start). */
export function withVersion(command: string, args: readonly string[], version: string): string[] {
  const pin = pinOf(command, args);
  if (!pin) throw new Error("This server does not run a package through npx or uvx");
  if (!isExactVersion(version)) throw new Error(`"${version}" is not an exact version`);
  const out = [...args];
  const fromUv = pin.runner === "uvx" && args[pin.index - 1] === "--from";
  out[pin.index] =
    pin.runner === "npx"
      ? `${pin.package}@${version}`
      : fromUv
        ? `${pin.package}==${version}`
        : `${pin.package}@${version}`;
  return out;
}

/** The command line of a catalog entry's package (`npx -y <package>@<version> …`). */
export function stdioArgs(t: {
  command: McpRunner;
  package: string;
  version: string;
  args: readonly string[];
}): string[] {
  return t.command === "npx"
    ? ["-y", `${t.package}@${t.version}`, ...t.args]
    : [`${t.package}@${t.version}`, ...t.args];
}

/**
 * Why a local server cannot run in its sandbox as it is, or nothing (G41.0 point 4): a program
 * the image has not got (Docker itself among them), or a path of the server's computer.
 */
export type McpStdioProblem = "docker" | "command" | "host-path";

export function stdioProblem(t: {
  command: string;
  args?: readonly string[];
  cwd?: string;
}): McpStdioProblem | undefined {
  const base = t.command.split(/[\\/]/).pop()?.toLowerCase().replace(/\.(cmd|exe)$/, "") ?? "";
  if (base === "docker" || base === "podman") return "docker";
  const hostPath = (p: string) =>
    /^[A-Za-z]:[\\/]/.test(p) ||
    p.startsWith("\\\\") ||
    p.startsWith("~") ||
    (p.startsWith("/") && p !== MCP_SANDBOX_HOME && !p.startsWith(`${MCP_SANDBOX_HOME}/`));
  const inside = t.command.startsWith("./") || t.command.startsWith(`${MCP_SANDBOX_HOME}/`);
  if (!inside && (hostPath(t.command) || t.command.includes("\\"))) return "host-path";
  if (!inside && !MCP_SANDBOX_COMMANDS.includes(t.command)) return "command";
  if (t.cwd && hostPath(t.cwd)) return "host-path";
  // A path given as an argument, alone or as a flag's value (`--config=/home/x/c.json`).
  for (const a of t.args ?? []) {
    const v = a.includes("=") && a.startsWith("-") ? a.slice(a.indexOf("=") + 1) : a;
    if (hostPath(v)) return "host-path";
  }
  return undefined;
}

/** A host's name in an address (`https://site/x`, `postgresql://u:p@db:5432/n`), or nothing. */
export function hostOf(address: string): string | undefined {
  const text = address.trim();
  if (!text) return undefined;
  try {
    const u = new URL(text.includes("://") ? text : `https://${text}`);
    const h = u.hostname.replace(/^\[|\]$/g, "").toLowerCase();
    return h || undefined;
  } catch {
    return undefined;
  }
}

/** A host name or `*.domain` the person may give for a server's way out. */
export const HOST_PATTERN = /^(\*\.)?[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)*$/;

/** The hosts the person typed (spaces, commas or lines), cleaned; the wrong ones apart. */
export function parseHosts(text: string): { hosts: string[]; wrong: string[] } {
  const hosts: string[] = [];
  const wrong: string[] = [];
  for (const raw of text.split(/[\s,]+/)) {
    const w = raw.trim().toLowerCase();
    if (!w) continue;
    const h = w.startsWith("*.") ? w : (hostOf(w) ?? w);
    if (HOST_PATTERN.test(h) && h.length <= 253) {
      if (!hosts.includes(h)) hosts.push(h);
    } else wrong.push(raw.trim());
  }
  return { hosts, wrong };
}

/**
 * A server's state for the page: connected, waiting to sign in, failing; for local servers also
 * `confirm` (its keys go in its variables: the person has not confirmed yet), `unavailable` (no
 * Docker: local servers do not start here) and `blocked` (it cannot run in its sandbox as it is:
 * `reason` says why).
 */
export type McpState = "connected" | "login" | "error" | "confirm" | "unavailable" | "blocked";

/** Why a local server waits: what its window says and what to do. */
export type McpBlockReason = McpStdioProblem | "unpinned" | "install" | "no-docker";

export interface McpServerStatus {
  name: string;
  projectId: string | null;
  state: McpState;
  tools: number;
  error?: string;
  reason?: McpBlockReason;
  /** A local server's package and its version (for "Update"). */
  package?: string;
  version?: string;
  /** Its keys reach the program's variables in its sandbox (G41.0). */
  keyInEnv?: boolean;
  /** Who confirmed that, and when. */
  envConfirmed?: { by: string; at: string };
}
