// 3.9.8, Coder on 2026-11-20: God on the person's Claude subscription asked the project
// inspector, which answered «I'm on your flat subscription, without tools: no project_summary,
// files, git…». A subscription streams only without tools; the chat (inspector and daily Chat)
// now takes a turn of its engine with its own tools.
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { FakeProvider, ProviderRegistry } from "@redgiant/providers";
import { commitAll, ensureRepo } from "@redgiant/sandbox";
import { type ClaudeSdk, ClaudeSubscriptionProvider } from "@redgiant/subscriptions";
import { LocalWorkspace, type WebSearchProvider } from "@redgiant/tools";
import { afterEach, describe, expect, it } from "vitest";
import type { ChatEntry } from "../src/index.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

type McpTool = {
  name: string;
  handler: (args: unknown, extra: unknown) => Promise<{ content: { text: string }[] }>;
};

/**
 * Claude Code in miniature: it calls one of the MCP tools it was given (the inspector reads
 * NOTES.md, the Chat searches), then answers with what the tool said. Each run says which
 * conversation it continued.
 */
function claudeCode(runs: { resume?: string; prompt: string; tools: string[] }[]): ClaudeSdk {
  return {
    tool: (name, _d, _s, handler) => ({ name, handler }),
    createSdkMcpServer: (o) => o,
    query({ prompt, options }) {
      const listed = (options.mcpServers as Record<string, { tools: McpTool[] }>).redgiant.tools;
      const system = String(options.systemPrompt ?? "");
      const session = `sess-${runs.length + 1}`;
      const usage = { input_tokens: 1, output_tokens: 1 };
      async function* run() {
        let text = "";
        for await (const m of prompt as AsyncIterable<{
          message: { content: { text?: string }[] };
        }>) {
          text = m.message.content[0]?.text ?? "";
          break;
        }
        runs.push({
          ...(options.resume !== undefined && { resume: String(options.resume) }),
          prompt: text,
          tools: listed.map((t) => t.name),
        });
        yield { type: "system", subtype: "init", session_id: session };
        const [name, input] = system.startsWith("You are the inspector")
          ? ["read_file", { path: "NOTES.md" }]
          : ["web_search", { query: "weather Rome" }];
        const id = `toolu_${runs.length}`;
        yield {
          type: "assistant",
          parent_tool_use_id: null,
          session_id: session,
          message: {
            model: "claude-x",
            usage,
            content: [{ type: "tool_use", id, name: `mcp__redgiant__${name}`, input }],
          },
        };
        const tool = listed.find((t) => t.name === name);
        const out = tool
          ? (await tool.handler(input, { _meta: { "claudecode/toolUseId": id } })).content[0]?.text
          : "No such tool available";
        const answer = `ANSWER: ${String(out).replace(/\s+/g, " ").slice(0, 300)}`;
        yield {
          type: "assistant",
          parent_tool_use_id: null,
          session_id: session,
          message: { model: "claude-x", usage, content: [{ type: "text", text: answer }] },
        };
        yield { type: "result", subtype: "success", session_id: session, result: answer };
      }
      return run() as ReturnType<ClaudeSdk["query"]>;
    },
  };
}

const search: WebSearchProvider = {
  async search(query) {
    return [{ title: `About ${query}`, url: "https://example.org/rome", snippet: "21 °C, sunny." }];
  },
};

async function onSubscription(runs: Parameters<typeof claudeCode>[0]) {
  const home = await mkdtemp(join(tmpdir(), "rg-inspector-sub-"));
  return startServer(
    () => {
      throw new Error("no API model here");
    },
    {},
    {
      search,
      providers: new ProviderRegistry()
        .register(new FakeProvider(() => ({ text: "fake" })))
        .register(
          new ClaudeSubscriptionProvider({
            token: "",
            configDir: home,
            cwd: home,
            sdk: claudeCode(runs),
            nativeWebSearch: false,
          }) as never,
        ),
      defaultModel: { provider: "claude-subscription", model: "claude-x" },
    },
  );
}

describe("a chat on a flat subscription runs its tools through the engine (3.9.9)", () => {
  it("the inspector, asked by God, reads the project and the next question continues", async () => {
    const runs: Parameters<typeof claudeCode>[0] = [];
    s = await onSubscription(runs);
    const project = await s.core.projects.create("me", "Shop");
    const ws = new LocalWorkspace(project.path);
    await ensureRepo(ws);
    await writeFile(join(project.path, "NOTES.md"), "Checkout is done; payments are next.");
    await commitAll(ws, "Add the checkout notes");

    // What God's ask_inspector calls.
    const answer = await s.core.inspector.ask("me", "shop", "How is it going?");
    expect(answer).toContain("Checkout is done; payments are next.");
    expect(runs[0]?.tools).toEqual(
      expect.arrayContaining(["project_summary", "read_file", "git_log", "project_tasks"]),
    );
    // Read-only: nothing that writes or runs commands.
    expect(runs[0]?.tools).not.toEqual(
      expect.arrayContaining([expect.stringMatching(/^(write_file|edit_file|bash)$/)]),
    );
    expect(runs[0]?.resume).toBeUndefined();

    const chat = (await s.core.chat.list("me", { kind: "inspector", projectId: "shop" }))[0];
    const entries = await s.core.chat.entries("me", chat?.id as string);
    expect(entries.map((e) => e.message.role)).toEqual(["user", "assistant", "user", "assistant"]);
    expect(entries[1]?.message.parts[0]).toMatchObject({ type: "tool_call", name: "read_file" });
    expect(entries[2]?.message.parts[0]).toMatchObject({
      type: "tool_result",
      content: expect.stringContaining("Checkout is done"),
    });
    expect(entries[3]?.costUsd).toBe(0);
    // Outside the event log, as every chat.
    expect((await s.core.store.list({})).some((e) => e.type === "message.user")).toBe(false);

    // The same chat continues the engine's conversation, without a transcript.
    await s.core.inspector.ask("me", "shop", "And the payments?");
    expect(runs[1]?.resume).toBe("sess-1");
    expect(runs[1]?.prompt).toMatch(/And the payments\?$/);
    expect(runs[1]?.prompt).not.toContain("The conversation so far");
  });

  it("the daily Chat searches the web on the subscription", async () => {
    const runs: Parameters<typeof claudeCode>[0] = [];
    s = await onSubscription(runs);
    const chat = await s.core.chat.create("me", "New chat", { kind: "daily" });
    const events: string[] = [];
    await s.core.chat.send("me", chat.id, "Che tempo fa a Roma?", [], (e) => {
      events.push(e.type);
    });
    expect(runs[0]?.tools).toEqual(["fetch", "web_search"]);
    expect(events).toContain("tool");
    const entries: ChatEntry[] = await s.core.chat.entries("me", chat.id);
    const last = entries.at(-1)?.message.parts.find((p) => p.type === "text");
    expect(last?.type === "text" && last.text).toContain("https://example.org/rome");
  });
});
