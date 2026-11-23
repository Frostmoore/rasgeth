// A ready-made set applied to a new agent (3.12.3): the table is in the protocol; here its
// instructions, its model effort hint and the sentence about what is left to connect.
import { type AgentSet, agentSetOf, type ConnectionKind } from "@redgiant/protocol";

const WHERE: Record<ConnectionKind, string> = {
  mailbox: "a mailbox (Settings > Mail, then the agent's settings)",
  chat: "a chat (Settings > Chats, then the agent's settings)",
  calendar: "a calendar (Settings > Calendars, then the agent's settings)",
  mcp: "an MCP server",
};

/** What the set adds to what the creator gave: its instructions first, the creator's after. */
export function withAgentSet<
  T extends {
    systemPrompt?: string | undefined;
    model?: { effort?: string | undefined } | undefined;
  },
>(input: T, set: AgentSet): T {
  const own = input.systemPrompt?.trim();
  return {
    ...input,
    systemPrompt: own
      ? `${set.instructions}\n\nAdditions from the person:\n${own}`
      : set.instructions,
    ...(input.model &&
      !input.model.effort && { model: { ...input.model, effort: set.model.effort } }),
  };
}

/** The sentence for the creator: what the agent still needs the person to connect. */
export function setLeftToConnect(setId: string, have: readonly ConnectionKind[]): string {
  const set = agentSetOf(setId);
  const missing = set?.wants.filter((k) => !have.includes(k)) ?? [];
  return missing.length
    ? ` Still to connect by the person: ${missing.map((k) => WHERE[k]).join("; ")}.`
    : "";
}
