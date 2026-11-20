// 3.9.8, Coder on 2026-11-20: God, the parent of every agent, sent all 32 of its agents'
// permission requests to the person ("escalate"). The parent decides with one model request
// without tools; on a subscription that request threw (a subscription only ran sessions'
// turns), and the broker turns any failure into "escalate". Now the subscription answers it.
import { mkdtemp } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import type { AgentNode, ApprovalRequest } from "@redgiant/hierarchy";
import { FakeProvider, ProviderRegistry } from "@redgiant/providers";
import { type ClaudeSdk, ClaudeSubscriptionProvider } from "@redgiant/subscriptions";
import { afterEach, describe, expect, it } from "vitest";
import { modelApprover } from "../src/index.js";
import { startServer } from "./helpers.js";

type Server = Awaited<ReturnType<typeof startServer>>;
let s: Server | undefined;
afterEach(async () => {
  await s?.close();
  s = undefined;
});

/** Claude Code answering one request without tools: the parent's word. */
function claudeCode(word: string, asked: Record<string, unknown>[]): ClaudeSdk {
  return {
    tool: (name, _d, _s, handler) => ({ name, handler }),
    createSdkMcpServer: (o) => o,
    query({ prompt, options }) {
      asked.push(options);
      async function* run() {
        for await (const _ of prompt) break;
        yield { type: "system", subtype: "init", session_id: "s1" };
        yield {
          type: "assistant",
          parent_tool_use_id: null,
          session_id: "s1",
          message: {
            model: "claude-x",
            usage: { input_tokens: 1, output_tokens: 1 },
            content: [{ type: "text", text: word }],
          },
        };
        yield { type: "result", subtype: "success", session_id: "s1", result: word };
      }
      return run() as ReturnType<ClaudeSdk["query"]>;
    },
  };
}

describe("a parent on a subscription decides its agents' requests (3.9.8)", () => {
  it.each([
    ["ALLOW", "allow"],
    ["DENY: it would delete the build", "deny"],
  ])("the parent's %s is its decision, not an escalation", async (word, decision) => {
    const home = await mkdtemp(join(tmpdir(), "rg-approver-"));
    const asked: Record<string, unknown>[] = [];
    const providers = new ProviderRegistry()
      .register(new FakeProvider(() => ({ text: "fake" })))
      .register(
        new ClaudeSubscriptionProvider({
          token: "",
          configDir: home,
          cwd: home,
          sdk: claudeCode(word, asked),
        }) as never,
      );
    const model = { provider: "claude-subscription", model: "claude-x" };
    s = await startServer(() => ({ text: "unused" }), {}, { providers, defaultModel: model });
    const made = await s.api<{ id: string }>("POST", "/api/agents", {
      kind: "god",
      parentId: null,
      name: "God",
    });
    const god = s.core.registry.get(made.body.id);
    if (!god) throw new Error("no god");
    const approve = modelApprover({
      registry: s.core.registry,
      providers,
      budget: s.core.budget,
      defaultModel: model,
      systemFor: () => "You are God.",
    });
    const req: ApprovalRequest = {
      requestId: "r1",
      requester: { ...god, id: "a1", name: "Dev", kind: "agent" } as AgentNode,
      call: { name: "run_command", input: { command: "npm test" } },
      reasons: ["a command"],
      danger: [],
    };
    expect(await approve(god, req)).toBe(decision);
    expect(asked[0]).toMatchObject({ tools: [], maxTurns: 1 });
  });
});
