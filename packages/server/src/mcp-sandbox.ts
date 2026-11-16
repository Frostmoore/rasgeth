// Local MCP servers in a sandbox of their own (G41.0). One container per person and server,
// created once and reused, stopped when nobody used it for a while; only the server's own folder is
// mounted (its npm/uv cache and files), never RedGiant's data, database or keychain. Its package
// installs at its exact version with the registries open, then runs with the network open only to
// its hosts (the egress proxy's source rules). Its keys reach the program's own variables
// (`docker exec` Env), never the container's, a log or an answer.
import { mkdir, readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import {
  isExactVersion,
  MCP_INSTALL_HOSTS,
  MCP_SANDBOX_HOME,
  type McpPin,
  type McpStdioProblem,
  pinOf,
  stdioProblem,
} from "@redgiant/protocol";
import type { Sandbox, SandboxProvider, SourceRule } from "@redgiant/sandbox";
import type { SpawnedProcess, Workspace } from "@redgiant/tools";
import { slug } from "./projects.js";

/** The sandbox image of local MCP servers (docker/mcp.Dockerfile). */
export const MCP_IMAGE = "ghcr.io/frostmoore/redgiant2-mcp:latest";

/** A local server as the configuration keeps it. */
export interface McpStdio {
  command: string;
  args?: string[];
  env?: Record<string, string>;
  cwd?: string;
  hosts?: string[];
  privateHosts?: string[];
  overrides?: string[];
}

/** A local server that cannot run as it is: the page says why and what to do. */
export class McpBlockedError extends Error {
  constructor(
    readonly reason: McpStdioProblem | "unpinned" | "install",
    message: string,
  ) {
    super(message);
  }
}

export interface McpSandboxOptions {
  /** Containers (Docker); without one, local servers do not start (never on this computer). */
  provider: SandboxProvider;
  /** Where each server's folder lives (`<dir>/<owner>/<server>`), inside the data volume. */
  dir: string;
  /** Another image than `MCP_IMAGE` (tests, mirrors). */
  image?: string;
  /** Hands the egress proxy every MCP sandbox's rule (its routes file). */
  sources?: (rules: SourceRule[]) => Promise<void>;
  /** How long the proxy takes to read new rules (it reads its file every 2 s). */
  settleMs?: number;
  /** Stopped after this long without use (default 30 minutes). */
  idleMs?: number;
  now?: () => number;
  /** How long an install may take (default 10 minutes). */
  installMs?: number;
}

const MARKER = ".redgiant-installed.json";
const OVERRIDES = ".redgiant-overrides.txt";

/** What a pinned package installs with, and how it then runs without the registries. */
export function stdioPlan(
  t: McpStdio,
  pin = pinOf(t.command, t.args ?? []),
): {
  install?: { file: string; args: string[] };
  run: { file: string; args: string[]; env: Record<string, string> };
} {
  const args = t.args ?? [];
  if (!pin) return { run: { file: t.command, args, env: {} } };
  if (!pin.version)
    throw new McpBlockedError(
      "unpinned",
      `${pin.package} has no exact version: give it one (${pin.package}@1.2.3)`,
    );
  if (pin.runner === "npx")
    return {
      install: {
        file: "npm",
        args: ["exec", "--yes", `--package=${pin.package}@${pin.version}`, "--", "node", "-e", "0"],
      },
      // The same cache entry, without asking the registry again.
      run: { file: "npx", args, env: { npm_config_offline: "true" } },
    };
  const exe = pin.executable ?? pin.package;
  return {
    install: {
      file: "uv",
      args: [
        "tool",
        "install",
        "--force",
        `${pin.package}==${pin.version}`,
        ...(t.overrides?.length ? ["--overrides", OVERRIDES] : []),
      ],
    },
    // The tool installed in its folder; what followed the package (or `--from x cmd`) are its own.
    run: {
      file: `${MCP_SANDBOX_HOME}/.local/bin/${exe}`,
      args: args.slice(pin.index + (pin.executable ? 2 : 1)),
      env: { UV_OFFLINE: "1" },
    },
  };
}

interface Box {
  sandbox: Promise<Sandbox>;
  lastUsed: number;
  /** The rule the proxy has for it now. */
  rule?: SourceRule;
}

export class McpSandboxes {
  private readonly boxes = new Map<string, Box>();
  private readonly installing = new Map<string, Promise<void>>();
  private readonly now: () => number;

  constructor(private readonly o: McpSandboxOptions) {
    this.now = o.now ?? Date.now;
  }

  private key = (owner: string, name: string) => `${owner}/${name}`;

  /** The server's own folder (its /workspace). */
  folder(owner: string, name: string): string {
    return join(this.o.dir, slug(owner) || "owner", name);
  }

  /** The id of its sandbox (and its container's name). */
  static id = (owner: string, name: string) => `mcp-${slug(owner) || "owner"}-${name}`;

  /** Created once and reused: never two `create` for the same id. */
  private box(owner: string, name: string): Box {
    const key = this.key(owner, name);
    let b = this.boxes.get(key);
    if (!b) {
      const dir = this.folder(owner, name);
      const created: Box = {
        lastUsed: this.now(),
        sandbox: mkdir(dir, { recursive: true }).then(() =>
          this.o.provider.create({
            id: McpSandboxes.id(owner, name),
            localPath: dir,
            mount: { type: "bind", source: dir },
            image: this.o.image ?? MCP_IMAGE,
            env: {
              HOME: MCP_SANDBOX_HOME,
              NODE_USE_ENV_PROXY: "1",
              UV_PYTHON_DOWNLOADS: "never",
            },
            limits: { cpus: 1, memoryMb: 1024, pids: 256 },
          }),
        ),
      };
      created.sandbox.catch(() => {
        if (this.boxes.get(key) === created) this.boxes.delete(key);
      });
      this.boxes.set(key, created);
      b = created;
    }
    return b;
  }

  /** Gives the proxy this sandbox's way out, and waits until it has read it. */
  private async allow(b: Box, sb: Sandbox, label: string, allow: string[], priv: string[] = []) {
    if (!this.o.sources || !sb.address) return;
    const rule: SourceRule = {
      address: sb.address,
      allow: [...allow],
      ...(priv.length && { allowPrivate: [...priv] }),
      label,
    };
    if (JSON.stringify(rule) === JSON.stringify(b.rule)) return;
    b.rule = rule;
    await this.publish();
    await new Promise((ok) => setTimeout(ok, this.o.settleMs ?? 2500));
  }

  private publish(): Promise<void> {
    const rules = [...this.boxes.values()].flatMap((b) => (b.rule ? [b.rule] : []));
    return this.o.sources?.(rules) ?? Promise.resolve();
  }

  /** Installs the pinned package once (again when its version changes). */
  private async install(
    owner: string,
    name: string,
    b: Box,
    sb: Sandbox,
    t: McpStdio,
    pin: McpPin,
    install: { file: string; args: string[] },
  ): Promise<void> {
    const dir = this.folder(owner, name);
    const want = JSON.stringify({
      runner: pin.runner,
      package: pin.package,
      version: pin.version,
      overrides: t.overrides ?? [],
    });
    const had = await readFile(join(dir, MARKER), "utf8").catch(() => "");
    if (had === want) return;
    const key = this.key(owner, name);
    let job = this.installing.get(key);
    if (!job) {
      job = (async () => {
        if (t.overrides?.length)
          await writeFile(join(dir, OVERRIDES), `${t.overrides.join("\n")}\n`);
        await this.allow(b, sb, `mcp:${key}`, [...MCP_INSTALL_HOSTS[pin.runner]]);
        const ws = sb.workspace();
        const r = await ws.execFile(install.file, install.args, {
          timeoutMs: this.o.installMs ?? 600_000,
        });
        if (r.exitCode !== 0) {
          const tail = `${r.stderr}\n${r.stdout}`.trim().split("\n").slice(-4).join(" ");
          throw new McpBlockedError(
            "install",
            `Could not install ${pin.package}@${pin.version}${r.timedOut ? " (too slow)" : ""}: ${tail.slice(-400)}`,
          );
        }
        await writeFile(join(dir, MARKER), want);
      })().finally(() => this.installing.delete(key));
      this.installing.set(key, job);
    }
    await job;
  }

  /**
   * Starts the server's program in its sandbox, its package installed first. `env` (its keys
   * among them) goes to this process only.
   */
  async spawn(
    owner: string,
    name: string,
    t: McpStdio,
    env: Record<string, string>,
  ): Promise<SpawnedProcess> {
    const problem = stdioProblem(t);
    if (problem)
      throw new McpBlockedError(
        problem,
        problem === "docker"
          ? "This server starts Docker itself, which its sandbox has not got"
          : problem === "command"
            ? `"${t.command}" is not in the MCP sandbox (it has npx, uvx, node, python3)`
            : "This server uses a path of the server's computer, which its sandbox cannot see",
      );
    const pin = pinOf(t.command, t.args ?? []);
    const plan = stdioPlan(t, pin);
    const b = this.box(owner, name);
    b.lastUsed = this.now();
    const sb = await b.sandbox;
    if (plan.install && pin) await this.install(owner, name, b, sb, t, pin, plan.install);
    await this.allow(b, sb, `mcp:${this.key(owner, name)}`, t.hosts ?? [], t.privateHosts ?? []);
    const ws: Workspace = sb.workspace();
    if (!ws.spawn) throw new Error("This sandbox cannot start programs");
    const cwd = t.cwd?.startsWith(`${MCP_SANDBOX_HOME}/`)
      ? t.cwd.slice(MCP_SANDBOX_HOME.length + 1)
      : t.cwd && t.cwd !== MCP_SANDBOX_HOME
        ? t.cwd
        : undefined;
    return ws.spawn(plan.run.file, plan.run.args, {
      env: { ...plan.run.env, ...env },
      ...(cwd && { cwd }),
    });
  }

  /** A tool of the server ran: it is not idle. */
  used(owner: string, name: string): void {
    const b = this.boxes.get(this.key(owner, name));
    if (b) b.lastUsed = this.now();
  }

  /** The servers nobody used for `idleMs` (their connection is closed first, then `stop`). */
  idle(): { owner: string; name: string }[] {
    const limit = this.o.idleMs ?? 30 * 60_000;
    const out: { owner: string; name: string }[] = [];
    for (const [key, b] of this.boxes) {
      if (this.now() - b.lastUsed < limit) continue;
      const at = key.indexOf("/");
      out.push({ owner: key.slice(0, at), name: key.slice(at + 1) });
    }
    return out;
  }

  /** Stops (removes) the server's container; its folder and installed package stay. */
  async stop(owner: string, name: string): Promise<void> {
    const key = this.key(owner, name);
    const b = this.boxes.get(key);
    if (!b) return;
    this.boxes.delete(key);
    if (b.rule) await this.publish().catch(() => {});
    await b.sandbox.then(
      (sb) => sb.destroy(),
      () => {},
    );
  }

  /** Forgets the installed version (the next start installs again). */
  async forget(owner: string, name: string): Promise<void> {
    await writeFile(join(this.folder(owner, name), MARKER), "").catch(() => {});
  }

  /** The servers running now (for tests and the status). */
  running(): string[] {
    return [...this.boxes.keys()];
  }

  async stopAll(): Promise<void> {
    for (const key of [...this.boxes.keys()]) {
      const at = key.indexOf("/");
      await this.stop(key.slice(0, at), key.slice(at + 1));
    }
  }
}

/** A package's newest version on npm or PyPI (read by the server, never by a sandbox). */
export async function latestVersion(
  runner: "npx" | "uvx",
  pkg: string,
  fetchFn: typeof fetch = fetch,
): Promise<string> {
  const url =
    runner === "npx"
      ? `https://registry.npmjs.org/${pkg.startsWith("@") ? `@${encodeURIComponent(pkg.slice(1))}` : encodeURIComponent(pkg)}/latest`
      : `https://pypi.org/pypi/${encodeURIComponent(pkg)}/json`;
  const res = await fetchFn(url, { signal: AbortSignal.timeout(15_000) });
  if (!res.ok) throw new Error(`${url}: ${res.status}`);
  const body = (await res.json()) as { version?: string; info?: { version?: string } };
  const v = runner === "npx" ? body.version : body.info?.version;
  if (!v || !isExactVersion(v)) throw new Error(`${pkg}: no version in the registry's answer`);
  return v;
}
