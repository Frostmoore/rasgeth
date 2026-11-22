import type { AgentSessionOptions, ToolCallInfo } from "@redgiant/agent";
import { costUsd } from "@redgiant/providers";
import type { PermissionBroker } from "./broker.js";
import { budgetKeys, type PersistentBudget } from "./budget.js";
import type { AgentNode, Resolve } from "./scopes.js";

/** The person's rules (3.12), as a session sees them. */
export interface SessionRules {
  /** Before a tool runs: a rule may block it or make it ask, never allow it. */
  beforeTool(call: ToolCallInfo): Promise<{ decision: "run" | "ask" | "block"; reasons: string[] }>;
  /** Before a model call: a rule's stop holds it. */
  modelGate(): Promise<{ allow: boolean; reason?: string }>;
}

/**
 * Wires an agent's session to the hierarchy: every tool call goes through the person's rules and
 * the permission broker, every model call is checked against the rules' stops and the budgets
 * first and counted after.
 */
export function hierarchyGuards(o: {
  agent: AgentNode;
  resolve: Resolve;
  broker: PermissionBroker;
  budget: PersistentBudget;
  rules?: SessionRules;
}): Pick<AgentSessionOptions, "permission" | "beforeModelCall" | "onCompletion"> {
  const keys = () => budgetKeys(o.agent, o.resolve);
  const at = { ownerId: o.agent.ownerId, projectId: o.agent.projectId, agentId: o.agent.id };
  return {
    permission: async (call, ctx) => {
      // Rules that cannot be read make the call ask the person: never a yes on a failure.
      const r = o.rules
        ? await o.rules.beforeTool(call).catch(() => ({
            decision: "ask" as const,
            reasons: ["the person's rules could not be read"],
          }))
        : undefined;
      if (r?.decision === "block")
        return { allow: false, reason: `blocked by the person's rule ${r.reasons.join("; ")}` };
      return o.broker.check(
        o.agent,
        call,
        ctx.sessionId,
        r?.decision === "ask"
          ? {
              ask: true,
              personOnly: true,
              askReason: `the person's rule ${r.reasons.join("; ")}`,
            }
          : {},
      );
    },
    beforeModelCall: async () => {
      // A stop that cannot be read does not stop anything: the budgets still hold.
      const held = await o.rules?.modelGate().catch(() => ({ allow: true }));
      if (held && !held.allow) return held;
      const breaches = await o.budget.check(keys());
      if (breaches.length === 0) return { allow: true };
      const b = breaches[0];
      return { allow: false, reason: `budget exceeded (${b?.key.scope} ${b?.key.id})` };
    },
    // Returned, not fired and forgotten: the session awaits it before the next budget check.
    onCompletion: async (completion, usd) => {
      await o.budget.record(keys(), completion.usage, usd, at);
    },
  };
}

export { costUsd };
