// Echo (3.9.6, roadmap «Agenti che imparano» point 2): every conversation indexed by itself and
// searched by its words, by the person (the search box over the conversations) and by the agents
// (`search_conversations`, «what we already did»).
//
// The index is filled from the event log, never from anything else: one row per message of the
// person or of an agent (`message.user`, `message.assistant`: their text only, never tool calls
// or results), read incrementally after a cursor (the last `seq` read) at start, shortly after
// every new message and before every search. Postgres full text with the `simple` configuration
// and prefixes (`word:*`): the same in every language. Erased events never come back: a
// `redaction` drops their rows, and every search joins the log (`NOT erased`) and the sessions'
// table (a conversation taken away is gone). The log is already redacted (`Redactor` in
// `append`); the text goes through the secrets' recogniser once more before it is indexed.
// Who may find what is `can(…, "read", agent)` (scopes.ts): `echoReaders`.

import type { Tool } from "@redgiant/agent";
import type { EventStore, SqlClient } from "@redgiant/events";
import { type AgentNode, type AgentRegistry, can } from "@redgiant/hierarchy";
import type { Event } from "@redgiant/protocol";
import { z } from "zod";

/** Characters of one message kept in the index (longer ones are cut there). */
const BODY_CHARS = 50_000;
/** Events read at a time while catching up. */
const BATCH = 500;
/** Messages ranked before they are grouped by conversation. */
const CANDIDATES = 300;
/** Marks around the words found, inside a snippet (turned into offsets before leaving). */
const START = "⟪";
const STOP = "⟫";

export async function migrateEcho(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_echo_messages (
      seq         bigint PRIMARY KEY,
      owner_id    text NOT NULL,
      session_id  text NOT NULL,
      agent_id    text,
      project_id  text,
      role        text NOT NULL,
      at          text NOT NULL,
      body        text NOT NULL,
      tsv         tsvector GENERATED ALWAYS AS (to_tsvector('simple', body)) STORED
    )`);
  await db.query(
    "CREATE INDEX IF NOT EXISTS rg_echo_messages_tsv ON rg_echo_messages USING gin (tsv)",
  );
  await db.query(
    "CREATE INDEX IF NOT EXISTS rg_echo_messages_session ON rg_echo_messages (session_id)",
  );
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_echo_cursor (
      id   integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
      seq  bigint NOT NULL
    )`);
}

/** Who wrote a message: the person, an agent of the conversation, or someone else for them. */
export type EchoRole = "person" | "agent" | "other";

/** One place in a conversation where the words are. `marks`: [start, end) of each word found. */
export interface EchoSnippet {
  role: EchoRole;
  at: string;
  text: string;
  marks: [number, number][];
}

/** One conversation found. */
export interface EchoHit {
  sessionId: string;
  title: string | null;
  agentId: string;
  projectId: string | null;
  /** When the best place found was written. */
  at: string;
  /** When the conversation last moved. */
  lastAt: string | null;
  /** Messages of the conversation with the words. */
  matches: number;
  snippets: EchoSnippet[];
}

export interface EchoSearch {
  query: string;
  /** The agents whose conversations may be found (`echoReaders`). */
  agents: readonly string[];
  limit?: number;
  /** Only this agent's conversations (it must be in `agents`). */
  agentId?: string;
  /** A conversation left out (the one asking: it already has its own history). */
  exceptSession?: string;
}

/** The words of a query, as a tsquery of prefixes (letters and digits only: always valid). */
export function echoQuery(query: string, join: "&" | "|"): string | null {
  const words = [
    ...new Set((query.toLowerCase().match(/[\p{L}\p{N}]+/gu) ?? []).filter((w) => w.length >= 2)),
  ].slice(0, 12);
  return words.length ? words.map((w) => `${w}:*`).join(` ${join} `) : null;
}

/** The text of a message event, or null when it has none worth finding. */
export function echoText(e: Event): { role: EchoRole; text: string } | null {
  if (e.erased || !e.payload || !e.sessionId) return null;
  if (e.type === "message.user") {
    const p = e.payload as { text?: unknown; from?: unknown };
    if (typeof p.text !== "string" || !p.text.trim()) return null;
    const from = typeof p.from === "string" ? p.from : undefined;
    return { role: !from || from === "telegram" ? "person" : "other", text: p.text };
  }
  if (e.type === "message.assistant") {
    const p = e.payload as { parts?: { type: string; text?: unknown }[] };
    const text = (p.parts ?? [])
      .flatMap((x) => (x.type === "text" && typeof x.text === "string" ? [x.text] : []))
      .join("\n")
      .trim();
    return text ? { role: "agent", text } : null;
  }
  return null;
}

/** A snippet from ts_headline with its marks taken out and kept as offsets. */
export function unmark(headline: string): { text: string; marks: [number, number][] } {
  let text = "";
  const marks: [number, number][] = [];
  let open = -1;
  for (const ch of headline) {
    if (ch === START) open = text.length;
    else if (ch === STOP) {
      if (open >= 0 && text.length > open) marks.push([open, text.length]);
      open = -1;
    } else text += ch;
  }
  return { text, marks };
}

export interface ConversationIndexOptions {
  db: SqlClient;
  store: EventStore;
  /** The secrets' recogniser (the log's Redactor); applied to every text before it is indexed. */
  redact: (text: string) => string;
  /** Milliseconds between a new message and the catch-up (0 in tests: right away). */
  delayMs?: number;
}

/** The conversations' index (Echo). */
export class ConversationIndex {
  private running: Promise<number> = Promise.resolve(0);
  private timer: ReturnType<typeof setTimeout> | undefined;
  private unsubscribe: (() => void) | undefined;

  constructor(private readonly o: ConversationIndexOptions) {}

  /** Follows the log: a catch-up now, then shortly after every message or erasure. */
  start(): () => void {
    this.unsubscribe ??= this.o.store.subscribe((e) => {
      if (e.type !== "message.user" && e.type !== "message.assistant" && e.type !== "redaction")
        return;
      if (this.timer) return;
      this.timer = setTimeout(() => {
        this.timer = undefined;
        void this.catchUp().catch(() => {});
      }, this.o.delayMs ?? 1000);
      this.timer.unref?.();
    });
    void this.catchUp().catch(() => {});
    return () => this.stop();
  }

  stop(): void {
    this.unsubscribe?.();
    this.unsubscribe = undefined;
    if (this.timer) clearTimeout(this.timer);
    this.timer = undefined;
  }

  /** Reads the log after the cursor into the index; one at a time. Returns the messages added. */
  catchUp(): Promise<number> {
    const next = this.running.catch(() => 0).then(() => this.readNew());
    this.running = next;
    return next;
  }

  private async readNew(): Promise<number> {
    const { db, store } = this.o;
    const [c] = await db.query<{ seq: string | number }>("SELECT seq FROM rg_echo_cursor");
    // Sequence numbers start at 0: nothing read yet is -1.
    let cursor = c ? Number(c.seq) : -1;
    let added = 0;
    for (;;) {
      const events = await store.list({
        fromSeq: cursor + 1,
        types: ["message.user", "message.assistant", "redaction"],
        limit: BATCH,
      });
      if (events.length === 0) break;
      const rows = events.flatMap((e) => {
        const m = echoText(e);
        return m && e.sessionId
          ? [
              {
                seq: e.seq,
                owner: e.ownerId,
                session: e.sessionId,
                agent: e.agentId,
                project: e.projectId,
                role: m.role,
                at: e.ts,
                body: this.o.redact(m.text).slice(0, BODY_CHARS),
              },
            ]
          : [];
      });
      const erasure = events.some((e) => e.type === "redaction");
      cursor = Math.max(...events.map((e) => e.seq));
      await db.transaction(async (tx) => {
        if (rows.length)
          await tx.query(
            `INSERT INTO rg_echo_messages (seq, owner_id, session_id, agent_id, project_id, role, at, body)
             SELECT * FROM unnest($1::bigint[], $2::text[], $3::text[], $4::text[], $5::text[], $6::text[], $7::text[], $8::text[])
             ON CONFLICT (seq) DO NOTHING`,
            [
              rows.map((r) => r.seq),
              rows.map((r) => r.owner),
              rows.map((r) => r.session),
              rows.map((r) => r.agent),
              rows.map((r) => r.project),
              rows.map((r) => r.role),
              rows.map((r) => r.at),
              rows.map((r) => r.body),
            ],
          );
        // An erasure (one event, a whole conversation, everything before a date): its rows go.
        if (erasure)
          await tx.query(
            "DELETE FROM rg_echo_messages m USING rg_events e WHERE e.seq = m.seq AND e.erased",
          );
        await tx.query(
          `INSERT INTO rg_echo_cursor (id, seq) VALUES (1, $1)
           ON CONFLICT (id) DO UPDATE SET seq = EXCLUDED.seq`,
          [cursor],
        );
      });
      added += rows.length;
      if (events.length < BATCH) break;
    }
    return added;
  }

  /**
   * The conversations of `agents` with the words of the query, best first: every word (as a
   * prefix) in one message, else any of them. Up to two snippets each.
   */
  async search(ownerId: string, s: EchoSearch): Promise<EchoHit[]> {
    const limit = Math.min(Math.max(s.limit ?? 10, 1), 50);
    const agents = s.agentId ? s.agents.filter((a) => a === s.agentId) : [...s.agents];
    if (agents.length === 0) return [];
    await this.catchUp();
    for (const join of ["&", "|"] as const) {
      const q = echoQuery(s.query, join);
      if (!q) return [];
      const hits = await this.find(ownerId, q, agents, limit, s.exceptSession);
      if (hits.length || join === "|" || !q.includes("&")) return hits;
    }
    return [];
  }

  private async find(
    ownerId: string,
    q: string,
    agents: string[],
    limit: number,
    exceptSession: string | undefined,
  ): Promise<EchoHit[]> {
    const params: unknown[] = [ownerId, q, agents, CANDIDATES];
    const except = exceptSession ? ` AND m.session_id <> $${params.push(exceptSession)}` : "";
    const rows = await this.o.db.query<{
      seq: string | number;
      session_id: string;
      agent_id: string;
      project_id: string | null;
      title: string | null;
      last_at: string | Date | null;
      role: EchoRole;
      at: string;
      rank: number;
    }>(
      `SELECT m.seq, m.session_id, s.agent_id, s.project_id, s.title, s.last_at, m.role, m.at,
              ts_rank_cd(m.tsv, to_tsquery('simple', $2)) AS rank
       FROM rg_echo_messages m
       JOIN rg_events e ON e.seq = m.seq AND NOT e.erased
       JOIN rg_sessions s ON s.id = m.session_id AND s.owner_id = m.owner_id
       WHERE m.owner_id = $1 AND s.agent_id = ANY($3::text[])
         AND m.tsv @@ to_tsquery('simple', $2)${except}
       ORDER BY rank DESC, m.seq DESC
       LIMIT $4`,
      params,
    );
    const bySession = new Map<string, typeof rows>();
    for (const r of rows) bySession.set(r.session_id, [...(bySession.get(r.session_id) ?? []), r]);
    const chosen = [...bySession.values()].slice(0, limit);
    const seqs = chosen.flatMap((list) => list.slice(0, 2).map((r) => Number(r.seq)));
    const heads = new Map<number, string>();
    if (seqs.length)
      for (const h of await this.o.db.query<{ seq: string | number; head: string }>(
        `SELECT seq, ts_headline('simple', body, to_tsquery('simple', $2),
                  'MinWords=12, MaxWords=32, StartSel=${START}, StopSel=${STOP}') AS head
         FROM rg_echo_messages WHERE seq = ANY($1::bigint[])`,
        [seqs, q],
      ))
        heads.set(Number(h.seq), h.head);
    return chosen.map((list) => {
      const best = list[0] as (typeof list)[number];
      return {
        sessionId: best.session_id,
        title: best.title,
        agentId: best.agent_id,
        projectId: best.project_id,
        at: best.at,
        lastAt: best.last_at ? new Date(best.last_at).toISOString() : null,
        matches: list.length,
        snippets: list.slice(0, 2).map((r) => ({
          role: r.role,
          at: r.at,
          ...unmark(heads.get(Number(r.seq)) ?? ""),
        })),
      };
    });
  }
}

/**
 * The agents whose conversations someone may find: the person every agent of theirs still in the
 * team, an agent those it may read (`can`, "read": itself, its sub-agents, its project's for an
 * orchestrator…). Archived projects stay readable: their conversations are found, and open read only.
 */
export function echoReaders(
  registry: AgentRegistry,
  ownerId: string,
  asker: { kind: "human" } | { kind: "agent"; agent: AgentNode },
): string[] {
  const team = registry.list({ ownerId });
  if (asker.kind === "human") return team.map((a) => a.id);
  const me = { type: "agent" as const, agent: asker.agent };
  return team.filter((a) => can(me, "read", a, registry.resolve)).map((a) => a.id);
}

/** A snippet for a model: the words found in **bold**. */
function boldMarks(s: EchoSnippet): string {
  let out = "";
  let at = 0;
  for (const [a, b] of s.marks) {
    out += `${s.text.slice(at, a)}**${s.text.slice(a, b)}**`;
    at = b;
  }
  return out + s.text.slice(at);
}

export interface EchoToolHost {
  index: () => ConversationIndex | undefined;
  /** The agents this agent may read, now (the team changes during a session). */
  readers: () => string[];
  agentName: (id: string) => string;
  projectName: (id: string | null) => Promise<string | null>;
  archived: (projectId: string | null) => boolean;
}

const Input = z.object({
  query: z.string().trim().min(1).max(500),
  limit: z.number().int().min(1).max(20).optional(),
  agent_id: z.string().min(1).optional(),
});

/** `search_conversations`: «what we already did», for an agent. */
export function searchConversationsTool(host: EchoToolHost): Tool<z.infer<typeof Input>> {
  return {
    def: {
      name: "search_conversations",
      description:
        "Search past conversations (yours and those of the agents you may see) by their words: what was already " +
        "decided, tried or done. Each conversation found comes with its title, date, agent, one or two passages and a " +
        "link [title](#conv:<id>) the person can open: cite it when you use what you found. Not the current conversation " +
        "(use conversation_history for that).",
      inputSchema: {
        type: "object",
        properties: {
          query: { type: "string", description: "The words to look for." },
          limit: {
            type: "integer",
            description: "Conversations to return (default 8, at most 20).",
          },
          agent_id: { type: "string", description: "Only this agent's conversations." },
        },
        required: ["query"],
      },
    },
    schema: Input,
    run: async ({ query, limit, agent_id }, ctx) => {
      const index = host.index();
      if (!index) return { content: "The conversations' search is not available.", isError: true };
      const agents = host.readers();
      if (agent_id && !agents.includes(agent_id))
        return {
          content: `You may not see the conversations of agent ${agent_id}.`,
          isError: true,
        };
      const hits = await index.search(ctx.ownerId, {
        query,
        agents,
        limit: limit ?? 8,
        ...(agent_id ? { agentId: agent_id } : {}),
        exceptSession: ctx.sessionId,
      });
      if (hits.length === 0) return `No past conversation has «${query}».`;
      const names = await Promise.all(
        hits.map((h) => host.projectName(h.projectId).catch(() => null)),
      );
      const lines = hits.map((h, i) => {
        const title = (h.title ?? "Untitled conversation").replace(/[[\]]/g, "");
        const project = names[i];
        const where = [
          host.agentName(h.agentId),
          project ? `project ${project}` : null,
          host.archived(h.projectId) ? "archived, read only" : null,
        ]
          .filter(Boolean)
          .join(", ");
        const passages = h.snippets
          .filter((s) => s.text)
          .map(
            (s) =>
              `   - ${s.role === "person" ? "Person" : s.role === "agent" ? "Agent" : "Other"}: ${boldMarks(s)}`,
          );
        return [
          `${i + 1}. [${title}](#conv:${h.sessionId}) · ${h.at.slice(0, 10)} · ${where} · ${h.matches} message${h.matches === 1 ? "" : "s"}`,
          ...passages,
        ].join("\n");
      });
      return `${hits.length} conversation${hits.length === 1 ? "" : "s"} found:\n${lines.join("\n")}`;
    },
  };
}
