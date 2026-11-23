// What an agent is connected to (3.12.3, decision «ogni agente con collegamenti senza limite»):
// any number of typed references, by kind. A mailbox is one of Settings > Mail, a chat is a
// platform the person linked, a calendar is one of Settings > Calendars, an MCP server is named as
// before. Older versions kept only MCP names (strings): they read as `mcp` references, nothing lost.
import { z } from "zod";

export const CONNECTION_KINDS = ["mailbox", "chat", "calendar", "mcp"] as const;
export const ConnectionKind = z.enum(CONNECTION_KINDS);
export type ConnectionKind = z.infer<typeof ConnectionKind>;

export const AgentConnection = z.object({
  kind: ConnectionKind,
  /** A mailbox's or calendar's id, a chat platform's name, an MCP server's name. */
  ref: z.string().min(1).max(200),
});
export type AgentConnection = z.infer<typeof AgentConnection>;

/** What a client may send: the old form (an MCP server's name) or the typed reference. */
export const AgentConnectionInput = z.union([
  z
    .string()
    .min(1)
    .transform((ref): AgentConnection => ({ kind: "mcp", ref })),
  AgentConnection,
]);

/** Old and new forms to the typed list, without repeats (the first one stays). */
export function normalizeConnections(value: unknown): AgentConnection[] {
  if (!Array.isArray(value)) return [];
  const seen = new Set<string>();
  const out: AgentConnection[] = [];
  for (const v of value) {
    const c =
      typeof v === "string"
        ? AgentConnection.safeParse({ kind: "mcp", ref: v })
        : AgentConnection.safeParse(v);
    if (!c.success) continue;
    const key = `${c.data.kind}:${c.data.ref}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(c.data);
  }
  return out;
}

/** The references of one kind. */
export const connectionRefs = (
  list: readonly AgentConnection[] | undefined,
  kind: ConnectionKind,
): string[] => (list ?? []).filter((c) => c.kind === kind).map((c) => c.ref);

/** Whether the agent has at least one connection of this kind (then it sees only those). */
export const hasConnectionKind = (
  list: readonly AgentConnection[] | undefined,
  kind: ConnectionKind,
): boolean => (list ?? []).some((c) => c.kind === kind);
