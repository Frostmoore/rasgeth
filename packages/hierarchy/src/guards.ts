import type { AgentSessionOptions, PermissionDecision, ToolCallInfo } from "@redgiant/agent";
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
 * A tool call checked by the person's rules first, then by the broker (3.12): a rule may block it
 * or make only the person able to say yes; it never allows. Rules that cannot be read make it ask
 * the person: never a yes on a failure. Used by every session and by the external (ACP) agents'
 * own permission requests.
 */
export async function checkWithRules(
  broker: PermissionBroker,
  agent: AgentNode,
  call: ToolCallInfo,
  sessionId: string | undefined,
  rules: SessionRules | undefined,
  o: { ask?: boolean; signal?: AbortSignal } = {},
): Promise<PermissionDecision> {
  const r = rules
    ? await rules.beforeTool(call).catch(() => ({
        decision: "ask" as const,
        reasons: ["the person's rules could not be read"],
      }))
    : undefined;
  if (r?.decision === "block")
    return { allow: false, reason: `blocked by the person's rule ${r.reasons.join("; ")}` };
  return broker.check(agent, call, sessionId, {
    ...(o.ask && { ask: true }),
    ...(o.signal && { signal: o.signal }),
    ...(r?.decision === "ask" && {
      ask: true,
      personOnly: true,
      askReason: `the person's rule ${r.reasons.join("; ")}`,
    }),
  });
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
    permission: (call, ctx) => checkWithRules(o.broker, o.agent, call, ctx.sessionId, o.rules),
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
