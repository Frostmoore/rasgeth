// A small real RedGiant whose data survive a restart (p3.8.9): PGlite in a folder, a scripted
// model, a password for the app to pair. For the app's test of a server that goes away and comes
// back with the same database (the person's Coder after a blackout):
//   RESTART_DIR=/some/folder DEMO_PASSWORD=companion-test-1 node packages/web/scripts/restart-server.mjs 7652
// Kill it (even with SIGKILL) and start it again with the same RESTART_DIR: devices, agents and
// conversations are still there; the requests that were waiting are gone, as on the real server.
// A message with «chiedi» makes the agent run a command that needs the person's yes.
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import { PGlite } from "@electric-sql/pglite";
import { FakeProvider, ProviderRegistry } from "@redgiant/providers";
import { RedGiantCore, SetupService, serve, TokenAuth } from "@redgiant/server";

const port = Number(process.argv[2] ?? 7652);
const dir = process.env.RESTART_DIR;
if (!dir) throw new Error("RESTART_DIR is needed");
await mkdir(dir, { recursive: true });
const pg = await PGlite.create(join(dir, "pg"));
const wrap = (q) => ({
  query: async (text, params) => (await q.query(text, params)).rows,
  transaction: (fn) => (q instanceof PGlite ? q.transaction((tx) => fn(wrap(tx))) : fn(wrap(q))),
});

const lastUser = (req) => {
  for (let i = req.messages.length - 1; i >= 0; i--) {
    const m = req.messages[i];
    if (m?.role !== "user") continue;
    if (m.parts.every((p) => p.type === "tool_result")) return null;
    return m.parts.map((p) => (p.type === "text" ? p.text : "")).join("");
  }
  return null;
};
const brain = (req) => {
  const asked = lastUser(req);
  if (asked?.includes("chiedi"))
    return { toolCalls: [{ name: "bash", input: { command: `echo ${Date.now()}` } }] };
  return { text: "Fatto." };
};

const core = await RedGiantCore.create({
  db: wrap(pg),
  providers: new ProviderRegistry().register(new FakeProvider(brain, { contextWindow: 32_768 })),
  workspacesDir: join(dir, "workspaces"),
  platformDir: join(dir, "platform"),
  defaultModel: { provider: "fake", model: "fake" },
  askAgent: async () => "escalate",
});
const me = { type: "human", ownerId: "local" };
// The first start makes God and an agent that asks before running commands; the next ones find them.
let god = core.registry.list({ ownerId: "local" }).find((a) => a.kind === "god");
if (!god) god = await core.registry.create(me, { kind: "god", parentId: null, name: "God" });
let project = (await core.projects.list("local")).find((p) => p.id === "riavvio");
if (!project) project = await core.projects.create("local", "Riavvio");
let asker = core.registry.list({ ownerId: "local" }).find((a) => a.name === "Chiede");
if (!asker) {
  asker = await core.registry.create(me, {
    kind: "orchestrator",
    parentId: god.id,
    name: "Chiede",
    projectId: project.id,
  });
  await core.registry.configure(me, asker.id, { mode: "manual" });
}
const setup = new SetupService({
  db: core.db,
  core,
  dataDir: join(dir, "data"),
  ownerId: "local",
  hooks: {},
});
await setup.applyAtStartup();
core.vaultSystem = async () => setup.keysForVault();
await setup.complete();
if (process.env.DEMO_PASSWORD) await core.logins.setPassword("local", process.env.DEMO_PASSWORD);
const running = await serve(core, new TokenAuth({ "restart-token-0123456789": "local" }), {
  port,
  host: process.env.DEMO_HOST ?? "127.0.0.1",
  setup,
  issueDeviceToken: (ownerId, device) => core.devices.create(ownerId, device),
});
console.log(JSON.stringify({ url: running.url, god: god.id, asker: asker.id }));
