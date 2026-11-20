// 3.9.8, Coder on 2026-11-20: God on the person's Claude subscription switched the machines on
// (`request_tool`, «machines is on… You can use it from your next step») and at its next step
// could not call ssh_list: the engine's tool list was the one its turn started with. It asked for
// the tool again, gave up and delegated. Here every way a model runs takes the same story: switch
// a group on, then call one of its tools at the very next step of the same turn. The engines are
// faithful miniatures: Claude Code lists the MCP tools once per run (and stops when a PostToolUse
// hook says so), Codex takes dynamic tools only at `thread/start`.
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { Event } from "@redgiant/protocol";
import {
  type CompletionRequest,
  FakeProvider,
  type FakeTurn,
  loadedTools,
  ProviderRegistry,
} from "@redgiant/providers";
import {
  ChatgptSubscriptionProvider,
  type ClaudeSdk,
  ClaudeSubscriptionProvider,
} from "@redgiant/subscriptions";
import { afterEach, describe, expect, it } from "vitest";
import { keepKitDefaults, startServer } from "./helpers.js";

keepKitDefaults();

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
const stops: (() => void)[] = [];
afterEach(async () => {
  for (const f of stops.splice(0)) f();
  await s?.close();
  s = undefined;
});

type Step = { tool: string; input: unknown } | { text: string };

/** The model of the story: machines on, then ssh_list if it can, else ask again; then done. */
function model(visible: readonly string[], calls: readonly string[]): Step {
  if (calls.length === 0)
    return { tool: "request_tool", input: { tool: "machines", why: "to look at the machines" } };
  if (calls.length === 1 && visible.includes("ssh_list")) return { tool: "ssh_list", input: {} };
  if (calls.length === 1)
    return { tool: "request_tool", input: { tool: "ssh_list", why: "it is not callable" } };
  return { text: `done: ${calls.join(", ")}` };
}

/** An API model: what it may call is what the provider sends (deferred tools once surfaced). */
function apiScript(): (req: CompletionRequest) => FakeTurn {
  return (req) => {
    const calls = req.messages.flatMap((m) =>
      m.role === "assistant"
        ? m.parts.flatMap((p) => (p.type === "tool_call" ? [p.name] : []))
        : [],
    );
    const step = model(
      loadedTools(req.tools, req.messages).map((t) => t.name),
      calls,
    );
    return "text" in step
      ? { text: step.text }
      : { toolCalls: [{ name: step.tool, input: step.input }] };
  };
}

type McpTool = {
  name: string;
  handler: (args: unknown, extra: unknown) => Promise<{ content: { text: string }[] }>;
};

/**
 * Claude Code in miniature: each run lists the MCP server's tools once, refuses a tool it does
 * not list or allow, runs the PostToolUse hooks after each call and ends the run when one says
 * `continue: false`. The model's memory lasts across runs (`resume`).
 */
function claudeCode(): ClaudeSdk {
  const calls: string[] = [];
  let runs = 0;
  return {
    tool: (name, _d, _s, handler) => ({ name, handler }),
    createSdkMcpServer: (o) => o,
    query({ prompt, options }) {
      const listed = (options.mcpServers as Record<string, { tools: McpTool[] }>).redgiant.tools;
      const allowed = options.allowedTools as string[];
      const visible = listed
        .map((t) => t.name)
        .filter((n) => allowed.includes(`mcp__redgiant__${n}`));
      const hooks =
        (
          options.hooks as
            | { PostToolUse?: { hooks: (() => Promise<{ continue?: boolean }>)[] }[] }
            | undefined
        )?.PostToolUse?.flatMap((h) => h.hooks) ?? [];
      const session = "sess-1";
      runs++;
      const usage = { input_tokens: 1, output_tokens: 1 };
      async function* run() {
        for await (const _ of prompt) break;
        yield { type: "system", subtype: "init", session_id: session };
        for (;;) {
          const step = model(visible, calls);
          if ("text" in step) {
            yield {
              type: "assistant",
              parent_tool_use_id: null,
              session_id: session,
              message: { model: "claude-x", usage, content: [{ type: "text", text: step.text }] },
            };
            yield { type: "result", subtype: "success", session_id: session, result: step.text };
            return;
          }
          const id = `toolu_${runs}_${calls.length}`;
          calls.push(step.tool);
          yield {
            type: "assistant",
            parent_tool_use_id: null,
            session_id: session,
            message: {
              model: "claude-x",
              usage,
              content: [
                { type: "tool_use", id, name: `mcp__redgiant__${step.tool}`, input: step.input },
              ],
            },
          };
          const tool = listed.find((t) => t.name === step.tool);
          // Not listed: Claude Code answers the model "No such tool available" itself.
          if (!tool || !visible.includes(step.tool)) continue;
          await tool.handler(step.input, { _meta: { "claudecode/toolUseId": id } });
          let go = true;
          for (const h of hooks) if ((await h()).continue === false) go = false;
          if (!go) {
            yield { type: "result", subtype: "success", session_id: session, result: "" };
            return;
          }
        }
      }
      return run() as ReturnType<ClaudeSdk["query"]>;
    },
  };
}

async function onEngine(provider: string): Promise<Server> {
  const home = await mkdtemp(join(tmpdir(), "rg-same-turn-"));
  const engine =
    provider === "claude-subscription"
      ? new ClaudeSubscriptionProvider({
          token: "",
          configDir: home,
          cwd: home,
          sdk: claudeCode(),
          nativeWebSearch: false,
        })
      : new ChatgptSubscriptionProvider({
          home,
          cwd: join(home, "work"),
          command: {
            file: process.execPath,
            args: [join(import.meta.dirname, "fake-codex-tools.mjs")],
          },
          nativeWebSearch: false,
        });
  if (engine instanceof ChatgptSubscriptionProvider) stops.push(() => engine.stop());
  return startServer(
    () => ({ text: "unused" }),
    {},
    {
      providers: new ProviderRegistry()
        .register(new FakeProvider(() => ({ text: "fake" })))
        .register(engine as never),
      defaultModel: { provider, model: provider === "claude-subscription" ? "claude-x" : "gpt-x" },
    },
  );
}

describe.each([
  ["an API with deferred loading (Anthropic)", "deferred"],
  ["an API without it (OpenAI-compatible, local)", "plain"],
  ["the Claude subscription (Claude Code)", "claude-subscription"],
  ["the ChatGPT subscription (Codex)", "chatgpt-subscription"],
])("a group switched on is callable at the next step, on %s (3.9.8)", (_name, kind) => {
  it("request_tool, then one of its tools in the same turn: it runs", async () => {
    s =
      kind === "deferred" || kind === "plain"
        ? await startServer(apiScript(), {
            contextWindow: 65_536,
            ...(kind === "deferred" && { deferredTools: true }),
          })
        : await onEngine(kind);
    const god = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const { body } = await s.api<{ sessionId: string }>("POST", "/api/sessions", {
      agentId: god.body.id,
    });
    const sid = body.sessionId;
    await (await s.core.send("me", sid, "What machines are there?", { watch: true })).done;
    const log = (await s.core.store.list({ sessionId: sid })) as Event[];
    const calls = log.flatMap((e) =>
      e.type === "tool.call" && e.payload ? [(e.payload as { tool: string }).tool] : [],
    );
    expect(calls).toEqual(["request_tool", "ssh_list"]);
    const results = log.flatMap((e) =>
      e.type === "tool.result" && e.payload ? [e.payload as { output: string; ok: boolean }] : [],
    );
    expect(results[0]?.output).toMatch(/machines is on \(.*ssh_list.*\)/);
    // ssh_list itself answered (no machine yet), not «unknown tool».
    expect(results[1]?.output).not.toMatch(/Unknown tool|is off in this conversation/);
    // Resumed, the conversation has the same tools.
    const added = log.filter((e) => e.type === "session.tools_added");
    expect(added).toHaveLength(1);
  });
});
