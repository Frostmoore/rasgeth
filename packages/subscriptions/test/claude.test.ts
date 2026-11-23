import { mkdtemp, readFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { EngineTurn } from "@redgiant/agent";
import { describe, expect, it } from "vitest";
import {
  type ClaudeSdk,
  ClaudeSubscriptionProvider,
  claudeWindows,
  eventWindows,
} from "../src/index.js";

type Tool = {
  name: string;
  handler: (args: unknown, extra: unknown) => Promise<{ content: { text: string }[] }>;
};

/**
 * The Agent SDK in miniature: one assistant message calling a tool, the tool through the MCP
 * server the engine passed, then the answer and the result. It records the options it got.
 */
function fakeSdk(script: "tools" | "refused") {
  const asked: Record<string, unknown>[] = [];
  const sdk: ClaudeSdk = {
    tool: (name, _d, _s, handler) => ({ name, handler }),
    createSdkMcpServer: (o) => o,
    query({ prompt, options }) {
      asked.push(options);
      const server = (options.mcpServers as Record<string, { tools: Tool[] }> | undefined)
        ?.redgiant;
      // As the real engine: it answers control requests while it works, not once its result is out.
      let closing = false;
      async function* run() {
        for await (const _ of prompt) break;
        if (script === "refused") {
          yield {
            type: "result",
            subtype: "success",
            is_error: true,
            result: "Not logged in · Please run /login",
            session_id: "s-x",
          };
          return;
        }
        yield { type: "system", subtype: "init", session_id: "sess-1" };
        yield {
          type: "assistant",
          parent_tool_use_id: null,
          session_id: "sess-1",
          message: {
            model: "claude-opus-5-5",
            usage: { input_tokens: 10, cache_read_input_tokens: 90, output_tokens: 5 },
            content: [
              { type: "thinking", thinking: "Let me check." },
              {
                type: "tool_use",
                id: "toolu_1",
                name: "mcp__redgiant__read_file",
                input: { path: "a.txt" },
              },
            ],
          },
        };
        const out = await server?.tools
          .find((t) => t.name === "read_file")
          ?.handler({ path: "a.txt" }, {});
        yield {
          type: "assistant",
          parent_tool_use_id: null,
          session_id: "sess-1",
          message: {
            model: "claude-opus-5-5",
            usage: { input_tokens: 3, cache_read_input_tokens: 120, output_tokens: 7 },
            content: [{ type: "text", text: `It says: ${out?.content[0]?.text}` }],
          },
        };
        yield {
          type: "rate_limit_event",
          // The SDK's form: one window per event.
          rate_limit_info: {
            status: "allowed",
            rateLimitType: "seven_day",
            utilization: 0.12,
            resetsAt: 1793728800,
          },
        };
        closing = true;
        yield { type: "result", subtype: "success", session_id: "sess-1", result: "done" };
      }
      const it = run() as ReturnType<ClaudeSdk["query"]>;
      it.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET = async () =>
        closing
          ? new Promise(() => {})
          : {
              rate_limits: {
                five_hour: { utilization: 36.4, resets_at: "2026-11-01T18:00:00Z" },
                seven_day: { utilization: 12, resets_at: null },
                model_scoped: [{ display_name: "Fable", utilization: 80 }],
              },
            };
      it.supportedModels = async () => [
        { value: "default", resolvedModel: "claude-opus-5-5", displayName: "Default" },
        { value: "claude-nova-6", displayName: "Nova 6", supportsEffort: true },
        { value: "sonnet", displayName: "Sonnet" },
      ];
      return it;
    },
  };
  return { sdk, asked };
}

const turn = (over: Partial<EngineTurn> = {}) => {
  const log: string[] = [];
  const t: EngineTurn = {
    text: "What is in a.txt?",
    images: [],
    system: "You are God.",
    tools: [
      {
        name: "read_file",
        description: "Read",
        inputSchema: {
          type: "object",
          properties: { path: { type: "string" } },
          required: ["path"],
        },
      },
    ],
    model: { provider: "claude-subscription", model: "claude-opus-5-5", effort: "high" },
    resume: undefined,
    runTool: async (c) => {
      log.push(`tool ${c.callId} ${c.name} ${JSON.stringify(c.input)}`);
      return { content: "hello", isError: false };
    },
    onMessage: async (m) => {
      log.push(
        `message ${m.stopReason} ${m.parts.map((p) => p.type).join(",")} ctx=${m.metrics.contextUsed}`,
      );
    },
    ...over,
  };
  return { t, log };
};

describe("Claude on a subscription", () => {
  it("runs the turn in the engine with Rasgeth's tools only, and continues the same session", async () => {
    const { sdk, asked } = fakeSdk("tools");
    const p = new ClaudeSubscriptionProvider({
      token: "sk-ant-oat01-x",
      configDir: "/tmp/c",
      cwd: "/tmp",
      sdk,
    });
    const { t, log } = turn();
    expect(await p.engine.turn(t)).toEqual({ resume: "sess-1", stopReason: "end_turn" });
    expect(log).toEqual([
      "message tool_use thinking,tool_call ctx=105",
      'tool toolu_1 read_file {"path":"a.txt"}',
      "message end_turn text ctx=130",
    ]);
    expect(asked[0]).toMatchObject({
      model: "claude-opus-5-5",
      effort: "high",
      // Only its own web search: no AskUserQuestion (3.9.5), questions go through ask_user's card.
      tools: ["WebSearch"],
      skills: [],
      strictMcpConfig: true,
      permissionMode: "dontAsk",
      settingSources: [],
      systemPrompt: "You are God.",
      allowedTools: ["mcp__redgiant__read_file", "WebSearch"],
      env: { CLAUDE_CODE_OAUTH_TOKEN: "sk-ant-oat01-x", CLAUDE_CONFIG_DIR: "/tmp/c" },
    });
    expect(asked[0]).not.toHaveProperty("resume");
    await p.engine.turn(turn({ resume: "sess-1" }).t);
    expect(asked[1]).toMatchObject({ resume: "sess-1" });
  });

  it("reports a refused token as a rejected key", async () => {
    const { sdk } = fakeSdk("refused");
    const p = new ClaudeSubscriptionProvider({
      token: "bad",
      configDir: "/tmp/c",
      cwd: "/tmp",
      sdk,
    });
    await expect(p.engine.turn(turn().t)).rejects.toMatchObject({ rejectedKey: true });
  });

  it("keeps the plan's limits the turns report: events first, then the full reading", async () => {
    const { sdk, asked } = fakeSdk("tools");
    // Before the windows' resets (a window past its reset shows 0%).
    const p = new ClaudeSubscriptionProvider({
      token: "t",
      configDir: "/tmp/c",
      cwd: "/tmp",
      sdk,
      now: () => Date.parse("2026-10-31T12:00:00Z"),
    });
    expect(await p.limits()).toEqual([]);
    await p.engine.turn(turn().t);
    expect(await p.limits()).toEqual([
      { id: "5h", label: "5h", usedPct: 36, resetsAt: "2026-11-01T18:00:00Z" },
      { id: "7d", label: "7g", usedPct: 12, resetsAt: "2026-11-03T18:00:00.000Z" },
      { id: "model:Fable", label: "Fable", usedPct: 80 },
    ]);
    // Reading them made no extra request.
    expect(asked).toHaveLength(1);
    expect(
      eventWindows({ unifiedWindows: { seven_day: { utilization: 0.36, resetsAt: 1793728800 } } }),
    ).toEqual([{ id: "7d", label: "7g", usedPct: 36, resetsAt: "2026-11-03T18:00:00.000Z" }]);
    // The SDK's own form (3.9.8): one window per event.
    expect(
      eventWindows({
        status: "allowed",
        rateLimitType: "five_hour",
        utilization: 0.07,
        resetsAt: 1793728800,
      }),
    ).toEqual([{ id: "5h", label: "5h", usedPct: 7, resetsAt: "2026-11-03T18:00:00.000Z" }]);
    expect(eventWindows({ status: "allowed", rateLimitType: "seven_day" })).toEqual([]);
    // As recorded from the engine (2026-11-20): the flat form without a figure, the figure in
    // `unifiedWindows`.
    expect(
      eventWindows({
        status: "allowed",
        resetsAt: 1795543200,
        rateLimitType: "seven_day",
        overageStatus: "allowed",
        isUsingOverage: false,
        unifiedWindows: {
          seven_day: { utilization: 0.01, resetsAt: 1795543200, status: "allowed" },
        },
      }),
    ).toEqual([{ id: "7d", label: "7g", usedPct: 1, resetsAt: "2026-11-24T18:00:00.000Z" }]);
    expect(claudeWindows({})).toEqual([]);
  });

  it("reads the plan's limits on its own, without a message, and keeps them over a restart (3.9.8)", async () => {
    // The engine's usage answer as recorded on a Max plan (2026-11-20): no 5-hour window.
    const recorded = {
      subscription_type: "max",
      rate_limits_available: true,
      rate_limits: {
        five_hour: null,
        seven_day: { utilization: 2, resets_at: "2026-11-24T17:59:59.663875+00:00" },
        seven_day_opus: null,
        model_scoped: [
          { display_name: "Fable", utilization: 0, resets_at: "2026-11-24T18:00:00+00:00" },
        ],
      },
    };
    let clock = Date.parse("2026-11-20T17:00:00Z");
    const runs: { messages: number; aborted: () => boolean; options: Record<string, unknown> }[] =
      [];
    let answer: unknown = recorded;
    const sdk = {
      tool: () => ({}),
      createSdkMcpServer: (o: unknown) => o,
      query({
        prompt,
        options,
      }: {
        prompt: AsyncIterable<unknown>;
        options: Record<string, unknown>;
      }) {
        const run = {
          messages: 0,
          aborted: () => (options.abortController as AbortController).signal.aborted,
          options,
        };
        runs.push(run);
        void (async () => {
          for await (const _ of prompt) run.messages++;
        })();
        const it = (async function* () {})() as ReturnType<ClaudeSdk["query"]>;
        it.usage_EXPERIMENTAL_MAY_CHANGE_DO_NOT_RELY_ON_THIS_API_YET = async (o) => {
          expect(o).toEqual({ skipBehaviors: true });
          return answer;
        };
        return it;
      },
    } as unknown as ClaudeSdk;
    const dir = await mkdtemp(join(tmpdir(), "rg-limits-"));
    const file = join(dir, "plan-limits.json");
    const make = () =>
      new ClaudeSubscriptionProvider({
        token: "",
        configDir: dir,
        cwd: dir,
        sdk,
        readPlan: true,
        limitsFile: file,
        now: () => clock,
      });
    const p = make();
    const read = [
      { id: "7d", label: "7g", usedPct: 2, resetsAt: "2026-11-24T17:59:59.663875+00:00" },
      { id: "model:Fable", label: "Fable", usedPct: 0, resetsAt: "2026-11-24T18:00:00+00:00" },
    ];
    expect(await p.limits()).toEqual(read);
    // One engine run, no message sent to it (no model call), closed at once, no model chosen.
    expect(runs).toHaveLength(1);
    expect(runs[0]?.messages).toBe(0);
    expect(runs[0]?.aborted()).toBe(true);
    expect(runs[0]?.options).not.toHaveProperty("model");
    // Looked at again soon: no new run.
    clock += 60_000;
    expect(await p.limits()).toEqual(read);
    expect(runs).toHaveLength(1);
    expect(p.readAt()).toBe("2026-11-20T17:00:00.000Z");
    // Three minutes after the first look (3.12.3: every 2 minutes), looked at by two pages at once: one new
    // reading shared by both, with the new figure and the new reading time.
    clock += 2 * 60_000;
    answer = {
      rate_limits: { seven_day: { utilization: 3, resets_at: "2026-11-24T17:59:59.663875+00:00" } },
    };
    const [one, two] = await Promise.all([p.limits(), p.limits()]);
    expect(one).toEqual(two);
    await new Promise((r) => setTimeout(r, 20));
    expect(runs).toHaveLength(2);
    expect(p.readAt()).toBe("2026-11-20T17:03:00.000Z");
    expect((await p.limits()).find((w) => w.id === "7d")?.usedPct).toBe(3);
    // A reading that gives nothing keeps the old figures, and is tried again only after the pause.
    clock += 2 * 60_000 + 1;
    answer = { rate_limits_available: false, rate_limits: null };
    await p.limits();
    await new Promise((r) => setTimeout(r, 20));
    expect(runs).toHaveLength(3);
    expect(p.readAt()).toBe("2026-11-20T17:03:00.000Z");
    clock += 60_000;
    await p.limits();
    expect(runs).toHaveLength(3);
    clock += 61_000;
    await p.limits();
    expect(runs).toHaveLength(4);
    answer = recorded;
    clock = Date.parse("2026-11-20T17:10:00Z");
    await p.limits();
    await new Promise((r) => setTimeout(r, 20));
    await p.limits();
    // A restart shows the kept windows at once, before any reading answers.
    await new Promise((r) => setTimeout(r, 20));
    expect(JSON.parse(await readFile(file, "utf8")).windows).toEqual(read);
    answer = new Promise(() => {});
    const again = make();
    expect(await again.limits()).toEqual(read);
    // After the week's reset the kept figure is 0%, not last week's.
    clock = Date.parse("2026-11-25T09:00:00Z");
    expect(await again.limits()).toEqual([
      { id: "7d", label: "7g", usedPct: 0 },
      { id: "model:Fable", label: "Fable", usedPct: 0 },
    ]);
    // A token without the profile scope reads nothing: no bars, and no new run at every look.
    answer = { rate_limits_available: false, rate_limits: null };
    const dir2 = await mkdtemp(join(tmpdir(), "rg-limits-"));
    const bare = new ClaudeSubscriptionProvider({
      token: "t",
      configDir: dir2,
      cwd: dir2,
      sdk,
      readPlan: true,
      now: () => clock,
    });
    const before = runs.length;
    expect(await bare.limits()).toEqual([]);
    expect(await bare.limits()).toEqual([]);
    expect(runs.length).toBe(before + 1);
  });

  it("offers the catalog's models and those the engine says the plan has (3.5.4)", async () => {
    const { sdk } = fakeSdk("tools");
    const p = new ClaudeSubscriptionProvider({ token: "t", configDir: "/tmp/c", cwd: "/tmp", sdk });
    const before = await p.models();
    expect(before).toEqual([
      "claude-fable-5-2",
      "claude-opus-5-5",
      "claude-sonnet-5-5",
      "claude-haiku-5-5",
    ]);
    await p.engine.turn(turn().t);
    await new Promise((r) => setTimeout(r, 10));
    expect(await p.models()).toEqual([...before, "claude-nova-6"]);
    expect(p.modelInfo("claude-nova-6")).toMatchObject({ unconfirmed: true, name: "Nova 6" });
    expect(p.modelInfo("claude-fable-5-2")).toMatchObject({
      contextWindow: 1_000_000,
      name: "Claude Fable 5.2",
    });
  });

  it("gives two calls of one tool in the same instant two ids (no line left spinning)", async () => {
    const ids: string[] = [];
    const sdk: ClaudeSdk = {
      tool: (name, _d, _s, handler) => ({ name, handler }),
      createSdkMcpServer: (o) => o,
      query({ prompt, options }) {
        const server = (options.mcpServers as Record<string, { tools: Tool[] }>).redgiant;
        async function* run() {
          for await (const _ of prompt) break;
          // The engine calls the tools before its message reaches the loop, both at once.
          const bash = server?.tools.find((t) => t.name === "read_file");
          await Promise.all([bash?.handler({ path: "a" }, {}), bash?.handler({ path: "b" }, {})]);
          yield { type: "result", subtype: "success", session_id: "s", result: "done" };
        }
        return run() as ReturnType<ClaudeSdk["query"]>;
      },
    };
    const p = new ClaudeSubscriptionProvider({
      token: "t",
      configDir: "/tmp/c",
      cwd: "/tmp",
      sdk,
      now: () => 1000,
    });
    await p.engine.turn(
      turn({
        runTool: async (c) => {
          ids.push(c.callId);
          return { content: "x", isError: false };
        },
      }).t,
    );
    expect(ids).toHaveLength(2);
    expect(new Set(ids).size).toBe(2);
  });
});

describe("one answer without tools (3.9.8: the person's classifier)", () => {
  function onceSdk(result: { subtype: string; is_error?: boolean; result?: string }) {
    const asked: Record<string, unknown>[] = [];
    const prompts: unknown[] = [];
    const sdk: ClaudeSdk = {
      tool: (name, _d, _s, handler) => ({ name, handler }),
      createSdkMcpServer: (o) => o,
      query({ prompt, options }) {
        asked.push(options);
        async function* run() {
          for await (const m of prompt) prompts.push(m);
          yield { type: "system", subtype: "init", session_id: "s1" };
          yield {
            type: "assistant",
            parent_tool_use_id: null,
            session_id: "s1",
            message: {
              model: "claude-opus-5-5",
              content: [{ type: "text", text: '{"decision":"allow","reason":"ok"}' }],
              usage: { input_tokens: 10, output_tokens: 5 },
            },
          };
          yield { type: "result", session_id: "s1", ...result };
        }
        return run();
      },
    };
    return { sdk, asked, prompts };
  }
  const request = {
    model: "claude-opus-5-5",
    system: "You decide.",
    tools: [],
    messages: [{ role: "user" as const, parts: [{ type: "text" as const, text: "May it?" }] }],
  };

  it("answers through the engine with no tools at all", async () => {
    const f = onceSdk({ subtype: "success" });
    const p = new ClaudeSubscriptionProvider({ configDir: "/tmp/x", cwd: "/tmp", sdk: f.sdk });
    const events = [];
    for await (const e of p.stream(request)) events.push(e);
    const done = events.at(-1);
    expect(done?.type).toBe("done");
    if (done?.type !== "done") return;
    expect(done.completion.message.parts).toEqual([
      { type: "text", text: '{"decision":"allow","reason":"ok"}' },
    ]);
    expect(done.completion.provider).toBe("claude-subscription");
    expect(done.completion.usage.outputTokens).toBe(5);
    expect(f.asked[0]).toMatchObject({
      tools: [],
      allowedTools: [],
      maxTurns: 1,
      systemPrompt: "You decide.",
    });
    expect(f.asked[0]?.mcpServers).toBeUndefined();
    expect(JSON.stringify(f.prompts)).toContain("May it?");
  });

  it("an engine error is an error, never an answer", async () => {
    const f = onceSdk({ subtype: "success", is_error: true, result: "rate limited" });
    const p = new ClaudeSubscriptionProvider({ configDir: "/tmp/x", cwd: "/tmp", sdk: f.sdk });
    await expect(async () => {
      for await (const _ of p.stream(request));
    }).rejects.toThrow(/rate limited/);
  });

  it("a request with tools still never streams", async () => {
    const p = new ClaudeSubscriptionProvider({
      configDir: "/tmp/x",
      cwd: "/tmp",
      sdk: onceSdk({ subtype: "success" }).sdk,
    });
    await expect(async () => {
      for await (const _ of p.stream({
        ...request,
        tools: [{ name: "x", description: "x", inputSchema: {} }],
      }));
    }).rejects.toThrow(/runs through its engine/);
  });
});

describe("the warm engine (3.12, God's topics' router)", () => {
  it("starts the engine ahead, answers its one prompt with the router's instructions, then closes", async () => {
    const runs: { options: Record<string, unknown>; got?: string; at: number }[] = [];
    let clock = 0;
    const sdk: ClaudeSdk = {
      tool: (name, _d, _s, handler) => ({ name, handler }),
      createSdkMcpServer: (o) => o,
      query({ prompt, options }) {
        const run: { options: Record<string, unknown>; got?: string; at: number } = {
          options,
          at: clock,
        };
        runs.push(run);
        async function* out() {
          for await (const m of prompt) {
            const c = (m as { message: { content: { text: string }[] } }).message.content;
            run.got = c[0]?.text;
            break;
          }
          if (run.got === undefined) return;
          yield {
            type: "assistant",
            parent_tool_use_id: null,
            message: {
              model: "claude-haiku-4-5",
              content: [{ type: "text", text: '{"topic":"new","confidence":0.9}' }],
            },
          };
          yield { type: "result", subtype: "success", is_error: false, result: "" };
        }
        return out();
      },
    };
    const dir = await mkdtemp(join(tmpdir(), "rg-warm-"));
    const p = new ClaudeSubscriptionProvider({ token: "t", configDir: dir, cwd: dir, sdk });
    const warm = p.engine.prewarm({ model: "claude-haiku-4-5", system: "ROUTER" });
    // Started before anything is asked.
    await new Promise((r) => setTimeout(r, 0));
    expect(runs).toHaveLength(1);
    expect(runs[0]?.options).toMatchObject({
      systemPrompt: "ROUTER",
      maxTurns: 1,
      allowedTools: [],
    });
    clock = 15_000;
    expect(await warm.ask("<message>hi</message>")).toBe('{"topic":"new","confidence":0.9}');
    expect(runs[0]?.got).toBe("<message>hi</message>");
    warm.close();
    await expect(warm.ask("again")).rejects.toThrow(/closed/);
    // One closed before it was asked never sends anything.
    const idle = p.engine.prewarm({ model: "claude-haiku-4-5", system: "ROUTER" });
    idle.close();
    await new Promise((r) => setTimeout(r, 0));
    expect(runs[1]?.got).toBeUndefined();
  });
});
