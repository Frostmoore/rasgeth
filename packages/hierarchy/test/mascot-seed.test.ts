// The mascots' seeds in the registry (G40.2): fixed at creation, kept on rename, given once to
// agents made before mascots, different faces within one RedGiant, and «Change mascot».
import { EventStore, migrate, type SqlClient } from "@redgiant/events";
import { mascotSignature } from "@redgiant/mascot";
import { beforeEach, describe, expect, it } from "vitest";
import { AgentRegistry, HierarchyError, migrateHierarchy } from "../src/index.js";
import { memoryDb } from "./pglite.js";

const human = { type: "human" as const, ownerId: "me" };
let db: SqlClient;
let store: EventStore;
let registry: AgentRegistry;

beforeEach(async () => {
  ({ db } = await memoryDb());
  await migrate(db);
  await migrateHierarchy(db);
  store = new EventStore(db);
  registry = new AgentRegistry(db, store);
  await registry.load();
});

async function team() {
  const god = await registry.create(human, { kind: "god", parentId: null, name: "God" });
  const orch = await registry.create(human, {
    kind: "orchestrator",
    parentId: god.id,
    projectId: "p1",
    name: "Coder Web",
  });
  return { god, orch };
}

describe("mascot seeds", () => {
  it("fixes the seed at creation and keeps it through a rename and a restart", async () => {
    const { orch } = await team();
    expect(orch.mascotSeed).toBe("Coder Web");
    const before = registry.mascotOf(orch.id);
    await registry.rename(orch.id, "Front-end");
    expect(registry.get(orch.id)?.mascotSeed).toBe("Coder Web");
    const again = new AgentRegistry(db, store);
    await again.load();
    expect(again.get(orch.id)?.mascotSeed).toBe("Coder Web");
    expect(again.mascotOf(orch.id)).toEqual(before);
    // The spawn event carries it: the log knows every face.
    const spawned = (await store.list({ types: ["agent.spawned"] })).map(
      (e) => (e.payload as { agent: { id: string; mascotSeed?: string } }).agent,
    );
    expect(spawned.find((x) => x.id === orch.id)?.mascotSeed).toBe("Coder Web");
  });

  it("gives a taken face's agent the next seed (name#1, name#2…)", async () => {
    const { orch } = await team();
    const a = await registry.create(human, { kind: "agent", parentId: orch.id, name: "Twin" });
    const b = await registry.create(human, { kind: "agent", parentId: orch.id, name: "Twin" });
    expect(a.mascotSeed).toBe("Twin");
    expect(b.mascotSeed).toMatch(/^Twin#\d+$/);
    const faces = registry
      .list({ ownerId: "me" })
      .filter((x) => x.kind !== "god")
      .map((x) => mascotSignature(registry.mascotOf(x.id) as never));
    expect(new Set(faces).size).toBe(faces.length);
  });

  // Decision «Mascotte solo per orchestratori e agenti di primo livello» (2026-11-19).
  it("gives a subagent no mascot: no seed, no spec, no preview, no change", async () => {
    const { orch } = await team();
    const coder = await registry.create(human, { kind: "agent", parentId: orch.id, name: "Coder" });
    const sub = await registry.create(
      { type: "agent", agent: coder },
      { kind: "subagent", parentId: coder.id, name: "Tester" },
    );
    expect(sub.mascotSeed).toBeUndefined();
    expect(registry.mascotOf(sub.id)).toBeUndefined();
    const row = await db.query<{ mascot_seed: string | null }>(
      "SELECT mascot_seed FROM rg_agents WHERE id = $1",
      [sub.id],
    );
    expect(row[0]?.mascot_seed).toBeNull();
    expect(registry.previewMascot("me", "Tester", "subagent")).toBeUndefined();
    expect(registry.previewMascot("me", "Tester", "agent")?.kind).toBe("agent");
    await expect(registry.changeMascot(human, sub.id)).rejects.toThrow(HierarchyError);
    // A restart does not give it one, and an older sub-agent that kept a seed shows none.
    await db.query("UPDATE rg_agents SET mascot_seed = 'Tester' WHERE id = $1", [sub.id]);
    const again = new AgentRegistry(db, store);
    await again.load();
    expect(again.mascotOf(sub.id)).toBeUndefined();
    await db.query("UPDATE rg_agents SET mascot_seed = NULL WHERE id = $1", [sub.id]);
    const later = new AgentRegistry(db, store);
    await later.load();
    expect(later.get(sub.id)?.mascotSeed).toBeUndefined();
    const logged = await store.list({ types: ["agent.mascot_changed"] });
    expect(logged.some((e) => (e.payload as { agentId: string }).agentId === sub.id)).toBe(false);
  });

  it("gives the agents made before mascots their name of today, once, saved and logged", async () => {
    const { god, orch } = await team();
    await registry.create(human, { kind: "agent", parentId: orch.id, name: "Old one" });
    // As a database from before G40.2: no seeds.
    await db.query("UPDATE rg_agents SET mascot_seed = NULL");
    const migrated = new AgentRegistry(db, store);
    await migrated.load();
    const seeds = migrated.list({ ownerId: "me" }).map((a) => [a.name, a.mascotSeed]);
    expect(Object.fromEntries(seeds)).toEqual({
      God: "God",
      "Coder Web": "Coder Web",
      "Old one": "Old one",
    });
    const logged = await store.list({ types: ["agent.mascot_changed"] });
    expect(logged).toHaveLength(3);
    // Decided once: a second start changes nothing and logs nothing.
    await migrated.rename(god.id, "Zeus");
    const later = new AgentRegistry(db, store);
    await later.load();
    expect(later.get(god.id)?.mascotSeed).toBe("God");
    expect(await store.list({ types: ["agent.mascot_changed"] })).toHaveLength(3);
  });

  it("changes a mascot only when the person asks, never God's", async () => {
    const { god, orch } = await team();
    const before = registry.mascotOf(orch.id);
    const changed = await registry.changeMascot(human, orch.id);
    expect(changed.mascotSeed).not.toBe("Coder Web");
    expect(mascotSignature(registry.mascotOf(orch.id) as never)).not.toBe(
      mascotSignature(before as never),
    );
    const row = await db.query<{ mascot_seed: string }>(
      "SELECT mascot_seed FROM rg_agents WHERE id = $1",
      [orch.id],
    );
    expect(row[0]?.mascot_seed).toBe(changed.mascotSeed);
    await expect(registry.changeMascot(human, god.id)).rejects.toThrow(HierarchyError);
    await expect(registry.changeMascot({ type: "agent", agent: god }, orch.id)).rejects.toThrow(
      HierarchyError,
    );
  });
});
