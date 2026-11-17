// Agents at work together (3.8.10): with the person's limit reached the next turn waits in line,
// never lost: it starts in order, the person can move one first, their own messages never wait,
// a turn waiting for a sub-agent lends it its place, and a restart rebuilds the line from the log.
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { AgentRecord } from "@redgiant/protocol";
import { FakeProvider, type FakeScript, ProviderRegistry } from "@redgiant/providers";
import { describe, expect, it } from "vitest";
import { RedGiantCore } from "../src/index.js";
import { memoryDb } from "./pglite.js";

async function until(what: () => Promise<boolean> | boolean, ms = 20_000): Promise<void> {
  const end = Date.now() + ms;
  while (!(await what())) {
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 10));
  }
}

/** A provider per worker, each held until its gate opens. */
function workers(n: number) {
  const gates = Array.from({ length: n }, () => {
    let open!: () => void;
    const p = new Promise<void>((ok) => {
      open = ok;
    });
    return { p, open };
  });
  const providers = gates.map(
    (g, i) =>
      new FakeProvider(() => ({ text: `worker ${i + 1} done` }), {
        id: `w${i + 1}`,
        tick: () => g.p,
      }),
  );
  return { gates, providers };
}

type Db = Awaited<ReturnType<typeof memoryDb>>["db"];

async function makeCore(db: Db, dir: string, extra: FakeProvider[], god: FakeScript = []) {
  const reg = new ProviderRegistry().register(new FakeProvider(god));
  for (const p of extra) reg.register(p);
  return RedGiantCore.create({
    db,
    providers: reg,
    workspacesDir: join(dir, "workspaces"),
    platformDir: join(dir, "platform"),
    defaultModel: { provider: "fake", model: "m" },
    askAgent: async () => "escalate",
  });
}

async function team(core: RedGiantCore, n: number) {
  const me = { type: "human" as const, ownerId: "me" };
  const god = await core.registry.create(me, { kind: "god", parentId: null, name: "God" });
  const helpers: AgentRecord[] = [];
  for (let i = 1; i <= n; i++)
    helpers.push(
      await core.registry.create(me, {
        kind: "assistant",
        parentId: god.id,
        name: `Helper ${i}`,
        role: "Helps",
        model: { provider: `w${i}`, model: "m" },
      }),
    );
  return { god, helpers };
}

const queuedIds = (core: RedGiantCore) => core.turnQueue("me").queued.map((q) => q.sessionId);

describe("agents at work together (3.8.10)", () => {
  it("N=2 and four tasks: two work, two wait, then start in order; one moved first", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-limit-"));
    const { db } = await memoryDb();
    const w = workers(4);
    const core = await makeCore(db, dir, w.providers);
    try {
      await core.commandSettings.set("me", { maxAtWork: 2 });
      const { helpers } = await team(core, 4);
      const sids = await Promise.all(helpers.map((h) => core.workSession(h)));
      const sent = [];
      for (const [i, sid] of sids.entries())
        sent.push(await core.send("me", sid, `Task ${i + 1}`, { queue: true }));
      expect(sent.map((s) => s.waiting === true)).toEqual([false, false, true, true]);
      await until(() => (w.providers[0]?.requests.length ?? 0) > 0);
      await until(() => (w.providers[1]?.requests.length ?? 0) > 0);
      expect(w.providers[2]?.requests.length).toBe(0);
      expect(core.turnQueue("me")).toMatchObject({ limit: 2, working: 2 });
      expect(queuedIds(core)).toEqual([sids[2], sids[3]]);
      expect(core.busySessions().sort()).toEqual([...sids].sort());
      // In the log: the line can be rebuilt.
      const queued = await core.store.list({ sessionId: sids[2], types: ["turn.queued"] });
      expect(queued[0]?.payload).toMatchObject({ text: "Task 3" });

      // The person moves the fourth first.
      expect(core.turnFirst("me", sids[3] as string)).toBe(true);
      expect(queuedIds(core)).toEqual([sids[3], sids[2]]);

      w.gates[0]?.open();
      await sent[0]?.done;
      await until(() => (w.providers[3]?.requests.length ?? 0) > 0);
      expect(w.providers[2]?.requests.length).toBe(0);
      expect(queuedIds(core)).toEqual([sids[2]]);

      w.gates[1]?.open();
      await until(() => (w.providers[2]?.requests.length ?? 0) > 0);
      expect(queuedIds(core)).toEqual([]);
      w.gates[2]?.open();
      w.gates[3]?.open();
      const results = await Promise.all(sent.map((s) => s.done));
      expect(results.map((r) => r.stopReason)).toEqual(Array(4).fill("end_turn"));
      const left = await core.store.list({ types: ["turn.unqueued"] });
      expect(left.map((e) => e.sessionId)).toEqual([sids[3], sids[2]]);
      expect(core.turnQueue("me")).toMatchObject({ working: 0, running: [], queued: [] });
    } finally {
      for (const g of w.gates) g.open();
      await core.close();
    }
  });

  it("the person's own message never waits; stopping a waiting turn takes it out of line", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-limit-"));
    const { db } = await memoryDb();
    const w = workers(3);
    const core = await makeCore(db, dir, w.providers);
    try {
      await core.commandSettings.set("me", { maxAtWork: 1 });
      const { helpers } = await team(core, 3);
      const [a, b, c] = await Promise.all(helpers.map((h) => core.workSession(h)));
      const first = await core.send("me", a as string, "Work", { queue: true });
      const second = await core.send("me", b as string, "Work too", { queue: true });
      expect(second.waiting).toBe(true);
      // The person writes to the third: at once, over the limit.
      const mine = await core.send("me", c as string, "Hello", { watch: true });
      expect(mine.waiting).toBeUndefined();
      await until(() => (w.providers[2]?.requests.length ?? 0) > 0);
      expect(core.turnQueue("me").working).toBe(2);
      // Stopped while it waits: it leaves the line, answered «aborted», and never starts.
      expect(await core.interrupt("me", b as string)).toBe(true);
      expect((await second.done).stopReason).toBe("aborted");
      expect(queuedIds(core)).toEqual([]);
      const out = await core.store.list({ sessionId: b, types: ["turn.unqueued"] });
      expect(out[0]?.payload).toMatchObject({ outcome: "withdrawn" });
      for (const g of w.gates) g.open();
      await first.done;
      await mine.done;
      expect(w.providers[1]?.requests.length).toBe(0);
    } finally {
      for (const g of w.gates) g.open();
      await core.close();
    }
  });

  it("the person writes where a turn waits: it starts now", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-limit-"));
    const { db } = await memoryDb();
    const w = workers(2);
    const core = await makeCore(db, dir, w.providers);
    try {
      await core.commandSettings.set("me", { maxAtWork: 1 });
      const { helpers } = await team(core, 2);
      const [a, b] = await Promise.all(helpers.map((h) => core.workSession(h)));
      await core.send("me", a as string, "Work", { queue: true });
      const waiting = await core.send("me", b as string, "Task", { queue: true });
      expect(waiting.waiting).toBe(true);
      const mine = await core.send("me", b as string, "Now, please", { watch: true, queue: true });
      expect(mine.queued).toBe(true);
      await until(() => (w.providers[1]?.requests.length ?? 0) > 0);
      expect(queuedIds(core)).toEqual([]);
      for (const g of w.gates) g.open();
      await waiting.done;
      await mine.done;
    } finally {
      for (const g of w.gates) g.open();
      await core.close();
    }
  });

  it("a turn waiting for an assistant's answer lends it its place (no deadlock at 1)", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-limit-"));
    const { db } = await memoryDb();
    const w = workers(1);
    let helperId = "";
    const core = await makeCore(db, dir, w.providers, (req) =>
      req.messages.some((m) => m.parts.some((p) => p.type === "tool_result"))
        ? { text: "God: the helper answered." }
        : {
            toolCalls: [
              { name: "ask_assistant", input: { assistant_id: helperId, request: "Help" } },
            ],
          },
    );
    try {
      await core.commandSettings.set("me", { maxAtWork: 1 });
      const { god, helpers } = await team(core, 1);
      helperId = helpers[0]?.id ?? "";
      w.gates[0]?.open();
      const godSession = await core.startSession("me", god.id);
      // God's turn is an automation's (not the person's): it holds the only place.
      const { done } = await core.send("me", godSession, "Ask the helper", { queue: true });
      const r = await done;
      expect(r.stopReason).toBe("end_turn");
      expect(w.providers[0]?.requests.length).toBe(1);
      expect(core.turnQueue("me")).toMatchObject({ working: 0, queued: [] });
    } finally {
      await core.close();
    }
  });

  it("after a restart the line comes back from the log, in its order", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-limit-"));
    const { db } = await memoryDb();
    const before = workers(3);
    const first = await makeCore(db, dir, before.providers);
    await first.commandSettings.set("me", { maxAtWork: 1 });
    const { helpers } = await team(first, 3);
    const sids = await Promise.all(helpers.map((h) => first.workSession(h)));
    for (const [i, sid] of sids.entries())
      await first.send("me", sid, `Task ${i + 1}`, { queue: true });
    await until(() => (before.providers[0]?.requests.length ?? 0) > 0);
    expect(queuedIds(first)).toEqual([sids[1], sids[2]]);
    // The power goes: the first server never speaks again.

    const after = workers(3);
    const second = await makeCore(db, dir, after.providers);
    try {
      const { sessions } = await second.resumeQueued();
      expect(sessions).toEqual([sids[1], sids[2]]);
      // Limit 1 (kept in the settings) and nothing at work: the second task starts, the third waits.
      await until(() => (after.providers[1]?.requests.length ?? 0) > 0);
      expect(queuedIds(second)).toEqual([sids[2]]);
      const said = after.providers[1]?.requests[0]?.messages.at(-1);
      expect(JSON.stringify(said)).toContain("Task 2");
      // No second `turn.queued`: the same place in line, closed once it starts.
      expect(await second.store.list({ types: ["turn.queued"] })).toHaveLength(2);
      after.gates[1]?.open();
      await until(() => (after.providers[2]?.requests.length ?? 0) > 0);
      after.gates[2]?.open();
      await until(async () => (await second.store.list({ types: ["turn.unqueued"] })).length === 2);
      // Started again once only: a third start finds nothing left.
      expect((await second.resumeQueued()).sessions).toEqual([]);
    } finally {
      for (const g of [...before.gates, ...after.gates]) g.open();
      await second.close();
    }
  });
});
