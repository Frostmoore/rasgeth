import { mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { Redactor } from "@redgiant/events";
import { McpConnection } from "@redgiant/extensions";
import { catalogConfig, MCP_CATALOG, type McpCatalogEntry } from "@redgiant/protocol";
import { DockerSandboxProvider } from "@redgiant/sandbox";
import Docker from "dockerode";
import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { RoutesFile } from "../src/egress-routes.js";
import { McpSandboxes } from "../src/mcp-sandbox.js";
import { startServer } from "./helpers.js";

/**
 * Local MCP servers in their own container (G41.0), with a real Docker engine
 * (`REDGIANT_DOCKER_TESTS=1 pnpm test:docker`, never in CI).
 *   REDGIANT_MCP_IMAGE      default redgiant/mcp:dev (docker/mcp.Dockerfile)
 *   REDGIANT_TEST_DIR       a directory with the same path for this process and the engine
 *   REDGIANT_TEST_OUTBOUND  network the egress proxy uses to go out (default bridge)
 */
const env = process.env;
const image = env.REDGIANT_MCP_IMAGE ?? "redgiant/mcp:dev";
const base = resolve(
  env.REDGIANT_TEST_DIR ?? "/mnt/archive1/officina-dati/rg-test",
  `mcp-run-${Date.now()}`,
);
const outbound = env.REDGIANT_TEST_OUTBOUND ?? "bridge";
const here = dirname(fileURLToPath(import.meta.url));
const egressDist = resolve(here, "../../sandbox/dist");
const docker = new Docker();
const NET = "rg-test-mcp-internal";
const KEY = "probe-secret-never-elsewhere-7351";

/** A dependency-free MCP server that says what it sees: its key, its mounts, a fetch. */
const PROBE = `
const fs = require("node:fs");
let buf = "";
const send = (m) => process.stdout.write(JSON.stringify(m) + "\\n");
const tools = [{ name: "probe", inputSchema: { type: "object", properties: { url: { type: "string" } } } }];
const answer = async (m) => {
  if (m.method === "initialize")
    return send({ jsonrpc: "2.0", id: m.id, result: { protocolVersion: m.params.protocolVersion, capabilities: { tools: {} }, serverInfo: { name: "probe", version: "1" } } });
  if (m.method === "tools/list") return send({ jsonrpc: "2.0", id: m.id, result: { tools } });
  if (m.method !== "tools/call") return;
  const a = m.params.arguments || {};
  let out;
  if (a.url) {
    try {
      const r = await fetch(a.url, { signal: AbortSignal.timeout(15000) });
      out = { status: r.status, body: (await r.text()).slice(0, 200) };
    } catch (e) {
      out = { error: String((e.cause && e.cause.code) || e.message) };
    }
  } else
    out = {
      key: process.env.PROBE_KEY === ${JSON.stringify(KEY)},
      mounts: fs.readFileSync("/proc/self/mountinfo", "utf8"),
      files: fs.readdirSync("/workspace"),
    };
  send({ jsonrpc: "2.0", id: m.id, result: { content: [{ type: "text", text: JSON.stringify(out) }] } });
};
process.stdin.on("data", (d) => {
  buf += d;
  let i;
  while ((i = buf.indexOf("\\n")) >= 0) {
    const line = buf.slice(0, i).trim();
    buf = buf.slice(i + 1);
    if (!line) continue;
    const m = JSON.parse(line);
    if (m.id !== undefined) void answer(m);
  }
});
`;

/** A server that prints its key on its way out (it must never reach the page). */
const LEAK = `process.stderr.write("my key is " + process.env.PROBE_KEY + "\\n"); process.exit(3);`;

/** The person's own server (a private address), next to the egress proxy in the same engine. */
let upstream: Docker.Container;
let upIp = "";
const upPort = 8080;
let egress: Docker.Container;
let provider: DockerSandboxProvider;
let boxes: McpSandboxes;
const routes = join(base, "egress", "routes.json");

const sandboxOptions = () => ({
  provider,
  image,
  settleMs: 3000,
  sources: (r: Parameters<RoutesFile["setSources"]>[0]) => RoutesFile.for(routes).setSources(r),
});

beforeAll(async () => {
  if (!env.REDGIANT_DOCKER_TESTS) return;
  await mkdir(join(base, "egress"), { recursive: true });
  // RedGiant's own data next to the servers' folders: a sandbox must never see it.
  await mkdir(join(base, "keychain"), { recursive: true });
  await writeFile(join(base, "keychain", "vault.json"), "not for MCP servers");
  await writeFile(join(base, "policy.json"), JSON.stringify({ allow: ["example.com"] }));
  await writeFile(routes, "{}");
  await docker
    .getContainer("rg-test-mcp-upstream")
    .remove({ force: true })
    .catch(() => {});
  upstream = await docker.createContainer({
    name: "rg-test-mcp-upstream",
    Image: "node:22-alpine",
    Cmd: [
      "node",
      "-e",
      `require("http").createServer((q, s) => s.end("hello from the person's own server " + q.url)).listen(${upPort})`,
    ],
    HostConfig: { NetworkMode: outbound },
  });
  await upstream.start();
  upIp = (await upstream.inspect()).NetworkSettings.Networks[outbound]?.IPAddress ?? "";

  provider = new DockerSandboxProvider({
    image,
    network: NET,
    egressProxyUrl: "http://rg-test-mcp-egress:3128",
    prefix: "rg-test-mcp",
  });
  await provider.ensureNetwork();
  await docker
    .getContainer("rg-test-mcp-egress")
    .remove({ force: true })
    .catch(() => {});
  egress = await docker.createContainer({
    name: "rg-test-mcp-egress",
    Image: "node:22-alpine",
    Cmd: ["node", "/app/egress-main.js", "/policy.json", "3128", "/egress/routes.json"],
    HostConfig: {
      NetworkMode: outbound,
      Mounts: [
        { Type: "bind", Source: egressDist, Target: "/app", ReadOnly: true },
        { Type: "bind", Source: join(base, "policy.json"), Target: "/policy.json", ReadOnly: true },
        { Type: "bind", Source: join(base, "egress"), Target: "/egress", ReadOnly: true },
      ],
    },
  });
  await docker
    .getNetwork(NET)
    .connect({ Container: egress.id, EndpointConfig: { Aliases: ["rg-test-mcp-egress"] } });
  await egress.start();
  boxes = new McpSandboxes({ ...sandboxOptions(), dir: join(base, "mcp") });
}, 300_000);

afterAll(async () => {
  if (!env.REDGIANT_DOCKER_TESTS) return;
  await boxes?.stopAll();
  await provider?.removeAll();
  await egress?.remove({ force: true }).catch(() => {});
  await upstream?.remove({ force: true }).catch(() => {});
  await docker
    .getNetwork(NET)
    .remove()
    .catch(() => {});
  await rm(base, { recursive: true, force: true });
});

const text = (r: unknown) => JSON.parse((r as { content: string }).content);
const ctx = { ownerId: "me", projectId: null, agentId: "a", sessionId: "s" } as never;

describe.skipIf(!env.REDGIANT_DOCKER_TESTS)("local MCP servers in their sandbox (G41.0)", () => {
  it("sees only its own folder, has its key only in its process, reaches only its hosts", async () => {
    const ip = upIp;
    await mkdir(boxes.folder("me", "probe"), { recursive: true });
    await writeFile(join(boxes.folder("me", "probe"), "probe.cjs"), PROBE);
    const transport = {
      type: "stdio" as const,
      command: "node",
      args: ["probe.cjs"],
      hosts: [ip],
      privateHosts: [ip],
    };
    const conn = new McpConnection({ name: "probe", transport }, undefined, {
      secrets: { env: { PROBE_KEY: KEY } },
      spawn: (e) => boxes.spawn("me", "probe", transport, e),
    });
    const [probe] = await conn.tools();
    if (!probe) throw new Error("no probe tool");
    const seenInside = text(await probe.run({}, ctx));
    expect(seenInside.key).toBe(true);
    expect(seenInside.files).toEqual(["probe.cjs"]);
    // Of this test's folder, only the server's own is mounted: not the keychain, not the others.
    // (The engine's own view of the path: relative to its disk, ending the same.)
    const run = base.split("/").pop() as string;
    const mine = (seenInside.mounts as string)
      .split("\n")
      .filter((l) => l.includes(run))
      .map((l) => l.split(" ")[3]);
    expect(mine).toHaveLength(1);
    expect(mine[0]?.endsWith(`/${run}/mcp/me/probe`)).toBe(true);
    expect(seenInside.mounts).not.toContain("keychain");

    // Its host answers; a host every other sandbox may reach does not, for it.
    const own = text(await probe.run({ url: `http://${ip}:${upPort}/hello` }, ctx));
    expect(own).toMatchObject({ status: 200, body: "hello from the person's own server /hello" });
    const shared = text(await probe.run({ url: "http://example.com/" }, ctx));
    expect(shared.status).not.toBe(200);
    // The proxy refused it for this sandbox, by its own rule (its log of refusals says so).
    const log = (await egress.logs({ stdout: true, stderr: true })).toString();
    expect(log).toMatch(/"host":"example\.com","allowed":false[^}]*"source":"mcp:me\/probe"/);

    // The key is the process's own: not the container's, not another command's there.
    const id = McpSandboxes.id("me", "probe");
    const info = await docker.getContainer(`rg-test-mcp-${id}`).inspect();
    expect(JSON.stringify(info.Config.Env)).not.toContain(KEY);
    const exec = await docker
      .getContainer(`rg-test-mcp-${id}`)
      .exec({ Cmd: ["env"], AttachStdout: true, AttachStderr: true });
    const stream = await exec.start({ hijack: true, stdin: false });
    let out = "";
    stream.on("data", (d: Buffer) => {
      out += d.toString();
    });
    await new Promise((ok) => stream.on("end", ok));
    expect(out).toContain("HOME=/workspace");
    expect(out).not.toContain(KEY);
    // The proxy's file names the sandbox by its address, never a key.
    expect(await readFile(routes, "utf8")).not.toContain(KEY);
    await conn.close();
  });

  it("never shows its key in the page, even when the program prints it", async () => {
    const s = await startServer(
      () => ({ text: "ok" }),
      {},
      {
        mcpSandbox: { ...sandboxOptions(), dir: join(base, "core-mcp") },
        redactor: new Redactor(),
      },
    );
    try {
      const folder = s.core.mcpSandboxes?.folder("me", "leak") ?? "";
      await mkdir(folder, { recursive: true });
      await writeFile(join(folder, "leak.cjs"), LEAK);
      await s.api("PUT", "/api/extensions/mcp", {
        name: "leak",
        projectId: null,
        transport: { type: "stdio", command: "node", args: ["leak.cjs"] },
        secrets: { env: { PROBE_KEY: KEY } },
        confirmKeyInEnv: true,
      });
      const st = await s.api<{ name: string; state: string; error?: string }[]>(
        "GET",
        "/api/extensions/mcp/status",
      );
      expect(st.body[0]?.state).toBe("error");
      expect(st.body[0]?.error).toMatch(/my key is/);
      expect(JSON.stringify(st.body)).not.toContain(KEY);
    } finally {
      await s.close();
    }
  });

  it("installs shopify-dev at its pinned version and runs it with only its hosts open", async () => {
    const entry = MCP_CATALOG.find((e) => e.id === "shopify-dev") as McpCatalogEntry;
    const { transport } = catalogConfig(entry);
    if (transport.type !== "stdio") throw new Error("not local");
    const conn = new McpConnection({ name: "shopify-dev", transport }, undefined, {
      spawn: (e) => boxes.spawn("me", "shopify-dev", transport, e),
    });
    const tools = await conn.tools();
    console.log(
      "shopify-dev tools:",
      tools.map((t) => `${t.def.name} ${JSON.stringify(t.def.inputSchema).slice(0, 160)}`),
    );
    expect(tools.length).toBeGreaterThan(0);
    // Its documentation comes from shopify.dev, through the proxy (its hosts only).
    const learn = tools.find((t) => t.def.name === "mcp__shopify-dev__learn_shopify_api");
    if (!learn) throw new Error("no learn_shopify_api");
    const r = (await learn.run({ api: "admin" }, ctx)) as { content: string; isError: boolean };
    console.log("learn_shopify_api:", r.isError, r.content.length, r.content.slice(0, 200));
    expect(r.isError).toBe(false);
    expect(r.content.length).toBeGreaterThan(200);
    // Installed once: its folder keeps the version, the next start installs nothing.
    expect(
      await readFile(join(boxes.folder("me", "shopify-dev"), ".redgiant-installed.json"), "utf8"),
    ).toContain('"version":"1.18.0"');
    await conn.close();
  }, 600_000);
});
