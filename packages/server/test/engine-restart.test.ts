// 3.9.8, Coder on 2026-11-20: the server stopped in the middle of an orchestrator's turn on the
// person's Claude subscription. After the start the page reconnected at once and read the
// conversations back, which built them before the subscription's provider was there (it comes up
// once its program is found): those conversations had no engine, so the resume and the person's
// next message to God went to a stream the provider does not have («A Claude subscription runs
// through its engine, not as a stream») and nothing answered. Here two cores share a database:
// the first stops mid-turn, the second is the restart, its provider registered late.
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { EngineTurn } from "@redgiant/agent";
import type { Event } from "@redgiant/protocol";
import { FakeProvider, ProviderRegistry } from "@redgiant/providers";
import { describe, expect, it } from "vitest";
import { RedGiantCore } from "../src/index.js";
import { memoryDb } from "./pglite.js";

const metrics = () => ({
  startedAt: new Date().toISOString(),
  endedAt: new Date().toISOString(),
  inputTokens: 1,
  cachedReadTokens: 0,
  cacheWriteTokens: 0,
  outputTokens: 1,
  contextUsed: 2,
  contextWindow: 200_000,
  prefillMs: 0,
  decodeMs: 0,
  tokPerSec: 0,
  source: "server" as const,
});

type Script = (t: EngineTurn, say: (text: string) => Promise<void>, n: number) => Promise<void>;

/** A Claude subscription in miniature: its engine runs the turns, it has no stream. */
class FakeSubscription {
  readonly id: string;
  readonly engine: { id: string; turn: (t: EngineTurn) => Promise<never> | Promise<unknown> };
  turns = 0;
  constructor(script: Script, id = "claude-subscription") {
    this.id = id;
    this.engine = {
      id,
      turn: async (t: EngineTurn) => {
        const n = this.turns++;
        let calls = 0;
        const say = async (text: string) =>
          t.onMessage({
            parts: [{ type: "text", text }],
            stopReason: "end_turn",
            metrics: metrics(),
            model: t.model.model,
          });
        const use = async (name: string, input: unknown) => {
          const callId = `c${n}_${calls++}`;
          await t.onMessage({
            parts: [{ type: "tool_call", callId, name, input }],
            stopReason: "tool_use",
            metrics: metrics(),
            model: t.model.model,
          });
          return t.runTool({ callId, name, input });
        };
        (t as EngineTurn & { use?: typeof use }).use = use;
        await script(t, say, n);
        return { resume: `thread-${n}`, stopReason: "end_turn" as const };
      },
    };
  }
  modelInfo(model: string) {
    return { id: model, contextWindow: 200_000, maxOutputTokens: 8000 };
  }
  // biome-ignore lint/correctness/useYield: as the real one, a subscription never streams.
  async *stream(): AsyncIterable<never> {
    throw new Error(`A ${this.id} runs through its engine, not as a stream`);
  }
}

const use = (t: EngineTurn, name: string, input: unknown) =>
  (
    t as EngineTurn & {
      use: (n: string, i: unknown) => Promise<{ content: string; isError: boolean }>;
    }
  ).use(name, input);
const idIn = (text: string, kind: string) =>
  text.match(new RegExp(`\\((${kind}_[0-9a-f]+)\\)`))?.[1] ?? "";
const roleOf = (t: EngineTurn) =>
  t.system.startsWith("You are God")
    ? "god"
    : t.system.startsWith("You are the orchestrator")
      ? "orchestrator"
      : "agent";

async function until(what: () => Promise<boolean> | boolean, ms = 20_000): Promise<void> {
  const end = Date.now() + ms;
  while (!(await what())) {
    if (Date.now() > end) throw new Error("timed out");
    await new Promise((r) => setTimeout(r, 20));
  }
}

describe.each([
  ["claude-subscription", "claude-sonnet-4-5"],
  ["chatgpt-subscription", "gpt-5"],
])("a restart with conversations on %s (3.9.8)", (provider, model) => {
  it("the cut task resumes and the person's next message gets its turn, though the provider came up late", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-engine-restart-"));
    const { db } = await memoryDb();
    const options = (registry: ProviderRegistry) => ({
      db,
      providers: registry,
      workspacesDir: join(dir, "workspaces"),
      platformDir: join(dir, "platform"),
      defaultModel: { provider, model },
      askAgent: async () => "escalate" as const,
    });

    // ---- Before the stop: God hands a task to an orchestrator, whose turn never ends.
    let cut = false;
    const before = new FakeSubscription(async (t, say) => {
      if (roleOf(t) === "god") {
        await use(t, "create_project", { name: "Gaia" });
        const made = await use(t, "create_agent", {
          kind: "orchestrator",
          name: "Orch",
          role: "Runs Gaia",
          project_id: "gaia",
        });
        await use(t, "delegate", {
          agent_id: idIn(made.content, "orchestrator"),
          title: "Build",
          task: "Build it",
        });
        return say("Handed over.");
      }
      // The orchestrator is at work when the server stops.
      cut = true;
      await new Promise<void>((ok) => t.signal?.addEventListener("abort", () => ok()));
    }, provider);
    const first = await RedGiantCore.create(
      options(new ProviderRegistry().register(new FakeProvider([])).register(before as never)),
    );
    const god = await first.registry.create(
      { type: "human", ownerId: "me" },
      { kind: "god", parentId: null, name: "God" },
    );
    const godSession = await first.startSession("me", god.id);
    await (await first.send("me", godSession, "Make Gaia", { watch: true })).done;
    await until(() => cut);
    const orch = first.registry.list({ ownerId: "me" }).find((a) => a.kind === "orchestrator");
    const orchSession = await first.workSession(orch as never);
    await Promise.race([first.close(), new Promise((r) => setTimeout(r, 3000))]);

    // ---- The restart: the subscription's provider is not there yet (its program is starting).
    const registry = new ProviderRegistry().register(new FakeProvider([]));
    const second = await RedGiantCore.create(options(registry));
    const asked: string[] = [];
    const after = new FakeSubscription(async (t, say) => {
      asked.push(`${roleOf(t)}: ${t.text.slice(0, 60)}`);
      if (roleOf(t) === "orchestrator") {
        await use(t, "complete_task", { verify_command: `node -e "process.exit(0)"` });
        return say("Built.");
      }
      return say(t.text.includes("<task_report") ? "Noted." : "Gaia is built.");
    }, provider);
    try {
      // The page reconnects first: it reads both conversations back (they are built here).
      await second.history("me", godSession);
      await second.history("me", orchSession);
      setTimeout(() => registry.register(after as never), 300);

      const resumed = await second.resumeInterrupted({ retryMs: [] });
      expect(resumed.sessions).toEqual([orchSession]);
      await resumed.done;
      const closed = await second.store.list({ types: ["task.closed"] });
      expect(closed.map((e) => (e.payload as { outcome: string }).outcome)).toEqual(["verified"]);

      // God hears the report first (its own turn), then the person writes.
      await until(async () =>
        (await second.store.list({ sessionId: godSession, types: ["message.assistant"] })).some(
          (e) => (e.payload as { parts: { text?: string }[] }).parts[0]?.text === "Noted.",
        ),
      );
      await until(() => !second.isRunning(godSession));
      // The person's next message to God starts a turn, on the engine.
      await (await second.send("me", godSession, "A che punto siamo?", { watch: true })).done;
      const answers = (await second.store.list({
        sessionId: godSession,
        types: ["message.assistant"],
      })) as Event[];
      const last = answers.at(-1)?.payload as { parts: { text?: string }[] } | undefined;
      expect(last?.parts[0]?.text).toBe("Gaia is built.");
      expect(asked.some((a) => a.startsWith("god: A che punto siamo?"))).toBe(true);
    } finally {
      await second.close();
    }
  }, 60_000);

  it("without the provider at all, a message says why instead of streaming", async () => {
    const dir = await mkdtemp(join(tmpdir(), "rg-engine-missing-"));
    const { db } = await memoryDb();
    const core = await RedGiantCore.create({
      db,
      providers: new ProviderRegistry().register(new FakeProvider([])),
      workspacesDir: join(dir, "workspaces"),
      platformDir: join(dir, "platform"),
      defaultModel: { provider, model },
      askAgent: async () => "escalate",
    });
    try {
      const god = await core.registry.create(
        { type: "human", ownerId: "me" },
        { kind: "god", parentId: null, name: "God" },
      );
      const sid = await core.startSession("me", god.id);
      const live = (
        core as unknown as {
          live: Map<string, { session: { o: { engineOnly?: { waitMs?: number } } } }>;
        }
      ).live;
      await core.history("me", sid);
      const session = live.get(sid)?.session;
      if (session?.o.engineOnly) session.o.engineOnly.waitMs = 200;
      const { done } = await core.send("me", sid, "Ciao", { watch: true });
      await expect(done).rejects.toThrow(/subscription is not ready yet/);
    } finally {
      await core.close();
    }
  }, 30_000);
});
