import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { PassThrough } from "node:stream";
import type { Sandbox, SandboxProvider, SandboxSpec, SourceRule } from "@redgiant/sandbox";
import {
  type ExecOptions,
  type ExecResult,
  LocalWorkspace,
  type SpawnedProcess,
  type SpawnOptions,
} from "@redgiant/tools";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { McpBlockedError, McpSandboxes, stdioPlan } from "../src/mcp-sandbox.js";
import { startServer } from "./helpers.js";

/** A made-up MCP program: answers initialize and tools/list (one tool, `ping`). */
function fakeServer(): SpawnedProcess {
  const stdin = new PassThrough();
  const stdout = new PassThrough();
  const stderr = new PassThrough();
  let done!: (code: number | null) => void;
  const exited = new Promise<number | null>((ok) => {
    done = ok;
  });
  let buf = "";
  stdin.on("data", (d: Buffer) => {
    buf += d.toString();
    for (let i = buf.indexOf("\n"); i >= 0; i = buf.indexOf("\n")) {
      const m = JSON.parse(buf.slice(0, i));
      buf = buf.slice(i + 1);
      const reply = (result: unknown) =>
        stdout.write(`${JSON.stringify({ jsonrpc: "2.0", id: m.id, result })}\n`);
      if (m.method === "initialize")
        reply({
          protocolVersion: m.params.protocolVersion,
          capabilities: { tools: {} },
          serverInfo: { name: "fake", version: "1" },
        });
      else if (m.method === "tools/list")
        reply({ tools: [{ name: "ping", inputSchema: { type: "object" } }] });
      else if (m.method === "tools/call") reply({ content: [{ type: "text", text: "pong" }] });
    }
  });
  return { stdin, stdout, stderr, cwd: "/workspace", exited, kill: () => done(null) };
}

/** Containers made up: what was created, run and started is written down. */
class FakeProvider implements SandboxProvider {
  readonly kind = "docker" as const;
  readonly created: SandboxSpec[] = [];
  readonly destroyed: string[] = [];
  readonly execs: { id: string; file: string; args: string[] }[] = [];
  readonly spawns: { id: string; file: string; args: string[]; o: SpawnOptions }[] = [];
  installExit = 0;

  async create(spec: SandboxSpec): Promise<Sandbox> {
    this.created.push(spec);
    const self = this;
    class Ws extends LocalWorkspace {
      override async execFile(file: string, args: string[], _o: ExecOptions): Promise<ExecResult> {
        self.execs.push({ id: spec.id, file, args });
        return {
          stdout: "",
          stderr: self.installExit ? "npm error 404 Not Found" : "",
          exitCode: self.installExit,
          timedOut: false,
        };
      }
      override async spawn(file: string, args: string[], o: SpawnOptions) {
        self.spawns.push({ id: spec.id, file, args, o });
        return fakeServer();
      }
    }
    return {
      id: spec.id,
      address: `10.9.0.${this.created.length}`,
      workspace: () => new Ws(spec.localPath),
      destroy: async () => {
        this.destroyed.push(spec.id);
      },
    };
  }
}

let dir: string;
beforeEach(async () => {
  dir = await mkdtemp(join(tmpdir(), "rg-mcpsbx-"));
});
afterEach(() => rm(dir, { recursive: true, force: true }));

describe("local MCP servers' sandboxes (G41.0)", () => {
  it("installs and runs each kind of command (a table)", () => {
    expect(stdioPlan({ command: "npx", args: ["-y", "@shopify/dev-mcp@1.18.0"] })).toEqual({
      install: {
        file: "npm",
        args: ["exec", "--yes", "--package=@shopify/dev-mcp@1.18.0", "--", "node", "-e", "0"],
      },
      run: {
        file: "npx",
        args: ["-y", "@shopify/dev-mcp@1.18.0"],
        env: { npm_config_offline: "true" },
      },
    });
    expect(
      stdioPlan({
        command: "uvx",
        args: ["postgres-mcp@0.3.0", "--access-mode=restricted"],
        overrides: ["pglast==7.20"],
      }),
    ).toEqual({
      install: {
        file: "uv",
        args: [
          "tool",
          "install",
          "--force",
          "postgres-mcp==0.3.0",
          "--overrides",
          ".redgiant-overrides.txt",
        ],
      },
      run: {
        file: "/workspace/.local/bin/postgres-mcp",
        args: ["--access-mode=restricted"],
        env: { UV_OFFLINE: "1" },
      },
    });
    expect(
      stdioPlan({ command: "uvx", args: ["--from", "tools==1.0.0", "mcp-git", "-v"] }).run,
    ).toEqual({
      file: "/workspace/.local/bin/mcp-git",
      args: ["-v"],
      env: { UV_OFFLINE: "1" },
    });
    expect(stdioPlan({ command: "node", args: ["server.mjs"] })).toEqual({
      run: { file: "node", args: ["server.mjs"], env: {} },
    });
    expect(() => stdioPlan({ command: "npx", args: ["-y", "foo@latest"] })).toThrow(
      McpBlockedError,
    );
  });

  it("makes one container per server, installs once with the registries, then opens only its hosts", async () => {
    const provider = new FakeProvider();
    const rules: SourceRule[][] = [];
    const boxes = new McpSandboxes({
      provider,
      dir,
      image: "redgiant/mcp:test",
      settleMs: 0,
      sources: async (r) => {
        rules.push(r);
      },
    });
    const t = {
      command: "npx",
      args: ["-y", "@shopify/dev-mcp@1.18.0"],
      hosts: ["shopify.dev"],
    };
    // Two starts at once: still one container and one install.
    const [a, b] = await Promise.all([
      boxes.spawn("me", "shopify-dev", t, { K: "v" }),
      boxes.spawn("me", "shopify-dev", t, {}),
    ]);
    a.kill();
    b.kill();
    expect(provider.created).toHaveLength(1);
    const spec = provider.created[0] as SandboxSpec;
    expect(spec).toMatchObject({
      id: "mcp-me-shopify-dev",
      image: "redgiant/mcp:test",
      localPath: join(dir, "me", "shopify-dev"),
      mount: { type: "bind", source: join(dir, "me", "shopify-dev") },
    });
    // Its keys are never the container's: only the started program's.
    expect(JSON.stringify(spec.env)).not.toContain('"K"');
    expect(provider.spawns.map((x) => x.o.env)).toContainEqual({
      K: "v",
      npm_config_offline: "true",
    });
    expect(provider.execs).toEqual([
      {
        id: "mcp-me-shopify-dev",
        file: "npm",
        args: ["exec", "--yes", "--package=@shopify/dev-mcp@1.18.0", "--", "node", "-e", "0"],
      },
    ]);
    // First the registry (installing), then only its hosts.
    expect(rules.map((r) => r.map((x) => x.allow))).toEqual([
      [["registry.npmjs.org"]],
      [["shopify.dev"]],
    ]);
    expect(rules.at(-1)?.[0]).toMatchObject({ address: "10.9.0.1", label: "mcp:me/shopify-dev" });
    // Started again: nothing installed; a new version installs again.
    (await boxes.spawn("me", "shopify-dev", t, {})).kill();
    expect(provider.execs).toHaveLength(1);
    (
      await boxes.spawn("me", "shopify-dev", { ...t, args: ["-y", "@shopify/dev-mcp@1.19.0"] }, {})
    ).kill();
    expect(provider.execs).toHaveLength(2);
    expect(provider.created).toHaveLength(1);
  });

  it("refuses what its sandbox cannot run, says why an install failed, and stops when idle", async () => {
    const provider = new FakeProvider();
    let now = 1_000;
    const rules: SourceRule[][] = [];
    const boxes = new McpSandboxes({
      provider,
      dir,
      settleMs: 0,
      idleMs: 60_000,
      now: () => now,
      sources: async (r) => {
        rules.push(r);
      },
    });
    for (const [t, reason] of [
      [{ command: "docker", args: ["run", "-i", "mcp/x"] }, "docker"],
      [{ command: "node", args: ["/home/me/server.js"] }, "host-path"],
      [{ command: "my-mcp" }, "command"],
      [{ command: "npx", args: ["-y", "foo"] }, "unpinned"],
    ] as const)
      await expect(boxes.spawn("me", "x", t, {})).rejects.toMatchObject({ reason });
    expect(provider.created).toHaveLength(0);
    provider.installExit = 1;
    await expect(
      boxes.spawn("me", "x", { command: "npx", args: ["-y", "foo@1.0.0"] }, {}),
    ).rejects.toThrow(/Could not install foo@1.0.0: npm error 404/);
    provider.installExit = 0;
    (await boxes.spawn("me", "x", { command: "npx", args: ["-y", "foo@1.0.0"] }, {})).kill();
    now += 30_000;
    boxes.used("me", "x");
    now += 45_000;
    expect(boxes.idle()).toEqual([]);
    now += 20_000;
    expect(boxes.idle()).toEqual([{ owner: "me", name: "x" }]);
    await boxes.stop("me", "x");
    expect(provider.destroyed).toEqual(["mcp-me-x"]);
    expect(boxes.running()).toEqual([]);
    // Its rule is gone from the proxy with it.
    expect(rules.at(-1)).toEqual([]);
  });
});

describe("local MCP servers in the core (G41.0)", () => {
  type Server = Awaited<ReturnType<typeof startServer>>;
  let s: Server | undefined;
  afterEach(async () => {
    await s?.close();
    s = undefined;
  });
  type St = {
    name: string;
    state: string;
    reason?: string;
    package?: string;
    version?: string;
    keyInEnv?: boolean;
  };

  it("moves the servers saved before to their sandbox: pinned, waiting for a yes, or stopped with the reason", async () => {
    const provider = new FakeProvider();
    s = await startServer(
      () => ({ text: "ok" }),
      {},
      {
        mcpSandbox: { provider, settleMs: 0 },
        mcpLatest: async (runner, pkg) => (pkg === "mine-mcp" ? "2.1.0" : "9.9.9"),
      },
    );
    const db = s.core.db;
    const put = (name: string, transport: unknown) =>
      db.query(
        "INSERT INTO rg_mcp_servers (owner_id, name, project_id, transport) VALUES ($1, $2, NULL, $3)",
        ["me", name, JSON.stringify(transport)],
      );
    // Rows as 3.8 kept them.
    await put("shopify-dev", {
      type: "stdio",
      command: "npx",
      args: ["-y", "@shopify/dev-mcp@latest"],
    });
    await put("wordpress", {
      type: "stdio",
      command: "npx",
      args: ["-y", "@automattic/mcp-wordpress-remote"],
    });
    await s.core.mcpCredentials.save("me", "wordpress", {
      env: { WP_API_URL: "https://blog.example.com/wp-json/mcp", WP_API_PASSWORD: "app-pass-xyz" },
    });
    await put("mine", { type: "stdio", command: "npx", args: ["-y", "mine-mcp"] });
    await put("desk", { type: "stdio", command: "node", args: ["/home/me/desk/index.js"] });
    await put("boxed", { type: "stdio", command: "docker", args: ["run", "-i", "x/y"] });

    const st = (await s.api<St[]>("GET", "/api/extensions/mcp/status")).body;
    const by = (n: string) => st.find((x) => x.name === n);
    expect(by("shopify-dev")).toMatchObject({
      state: "connected",
      package: "@shopify/dev-mcp",
      version: "1.18.0",
    });
    expect(by("wordpress")).toMatchObject({ state: "confirm", keyInEnv: true, version: "0.5.5" });
    expect(by("mine")).toMatchObject({ state: "connected", version: "2.1.0" });
    expect(by("desk")).toMatchObject({ state: "blocked", reason: "host-path" });
    expect(by("boxed")).toMatchObject({ state: "blocked", reason: "docker" });
    expect(JSON.stringify(st)).not.toContain("app-pass-xyz");
    const rows = await s.api<{ name: string; transport: { args: string[]; hosts?: string[] } }[]>(
      "GET",
      "/api/extensions/mcp",
    );
    const saved = (n: string) => rows.body.find((r) => r.name === n)?.transport;
    expect(saved("shopify-dev")).toMatchObject({
      args: ["-y", "@shopify/dev-mcp@1.18.0"],
      hosts: ["shopify.dev", "cdn.shopify.com"],
    });
    expect(saved("wordpress")).toMatchObject({
      args: ["-y", "@automattic/mcp-wordpress-remote@0.5.5"],
      hosts: ["blog.example.com"],
    });
    expect(saved("mine")?.args).toEqual(["-y", "mine-mcp@2.1.0"]);
    // WordPress starts once the person says yes; its key only in that program's variables.
    await s.api("POST", "/api/extensions/mcp/wordpress/confirm-env");
    const wp = (await s.api<St[]>("GET", "/api/extensions/mcp/status")).body.find(
      (x) => x.name === "wordpress",
    );
    expect(wp?.state).toBe("connected");
    const spawn = provider.spawns.find((x) => x.id === "mcp-me-wordpress");
    expect(spawn?.o.env).toMatchObject({ WP_API_PASSWORD: "app-pass-xyz" });
    const spec = provider.created.find((x) => x.id === "mcp-me-wordpress");
    expect(JSON.stringify(spec)).not.toContain("app-pass-xyz");
  });

  it("updates a server to the version the person chose", async () => {
    const provider = new FakeProvider();
    s = await startServer(
      () => ({ text: "ok" }),
      {},
      { mcpSandbox: { provider, settleMs: 0 }, mcpLatest: async () => "1.19.0" },
    );
    await s.api("PUT", "/api/extensions/mcp", {
      name: "shopify-dev",
      projectId: null,
      transport: {
        type: "stdio",
        command: "npx",
        args: ["-y", "@shopify/dev-mcp@1.18.0"],
        hosts: ["shopify.dev"],
      },
    });
    await s.api("GET", "/api/extensions/mcp/status");
    const check = await s.api("GET", "/api/extensions/mcp/shopify-dev/update");
    expect(check.body).toEqual({
      package: "@shopify/dev-mcp",
      runner: "npx",
      version: "1.18.0",
      latest: "1.19.0",
    });
    expect(
      (await s.api("POST", "/api/extensions/mcp/shopify-dev/update", { version: "latest" })).status,
    ).toBe(400);
    expect(
      (await s.api("POST", "/api/extensions/mcp/shopify-dev/update", { version: "1.19.0" })).status,
    ).toBe(200);
    // Its container stops; the next start installs the new version in a new one.
    expect(provider.destroyed).toEqual(["mcp-me-shopify-dev"]);
    const st = (await s.api<St[]>("GET", "/api/extensions/mcp/status")).body[0];
    expect(st).toMatchObject({ state: "connected", version: "1.19.0" });
    expect(provider.execs.map((e) => e.args[2])).toEqual([
      "--package=@shopify/dev-mcp@1.18.0",
      "--package=@shopify/dev-mcp@1.19.0",
    ]);
  });

  it("without Docker local servers wait, and say so", async () => {
    s = await startServer(() => ({ text: "ok" }), {}, { mcpSandbox: undefined });
    expect((await s.api("GET", "/api/extensions/mcp/local")).body).toEqual({ available: false });
    await s.api("PUT", "/api/extensions/mcp", {
      name: "shopify-dev",
      projectId: null,
      transport: { type: "stdio", command: "npx", args: ["-y", "@shopify/dev-mcp@1.18.0"] },
    });
    expect((await s.api<St[]>("GET", "/api/extensions/mcp/status")).body).toEqual([
      expect.objectContaining({ name: "shopify-dev", state: "unavailable", reason: "no-docker" }),
    ]);
  });
});
