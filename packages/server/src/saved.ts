// Saved passages (G40.14, 3.8.1): the person's own archive of parts of messages (or whole ones),
// each with where it comes from, an optional note and optional tags. One owner per item, as
// everything else of the multi-user model: every query is bound to the owner, and the origin is
// read from the owner's own conversation (a session in `rg_sessions` and its event log, or a
// daily chat's row), never taken from the client.

import { randomBytes } from "node:crypto";
import { sessionLog } from "@redgiant/agent";
import type { EventStore, SqlClient } from "@redgiant/events";
import {
  type ChatMessage,
  normalizeTags,
  SAVED_PAGE_MAX,
  type SavedCreateBody,
  type SavedItem,
  type SavedList,
  type SavedQuery,
  type SavedSource,
  type SavedUpdateBody,
} from "@redgiant/protocol";

export async function migrateSaved(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_saved (
      id          text PRIMARY KEY,
      owner_id    text NOT NULL,
      agent_id    text,
      text        text NOT NULL,
      markdown    text,
      whole       boolean NOT NULL DEFAULT false,
      note        text NOT NULL DEFAULT '',
      tags        jsonb NOT NULL DEFAULT '[]'::jsonb,
      source      jsonb NOT NULL,
      created_at  timestamptz NOT NULL DEFAULT now(),
      updated_at  timestamptz NOT NULL DEFAULT now()
    )`);
  await db.query(
    "CREATE INDEX IF NOT EXISTS rg_saved_owner_created ON rg_saved (owner_id, created_at DESC)",
  );
}

export class SavedError extends Error {
  constructor(
    message: string,
    readonly status: 400 | 404,
  ) {
    super(message);
  }
}

type Row = {
  id: string;
  text: string;
  markdown: string | null;
  whole: boolean;
  note: string;
  tags: unknown;
  source: unknown;
  created_at: Date | string;
  updated_at: Date | string;
};
const COLUMNS = "id, text, markdown, whole, note, tags, source, created_at, updated_at";
const parse = <T>(v: unknown): T => (typeof v === "string" ? JSON.parse(v) : v) as T;
const iso = (d: Date | string) => new Date(d).toISOString();
const view = (r: Row): SavedItem => ({
  id: r.id,
  text: r.text,
  markdown: r.markdown,
  whole: r.whole,
  note: r.note,
  tags: parse<string[]>(r.tags),
  source: parse<SavedSource>(r.source),
  createdAt: iso(r.created_at),
  updatedAt: iso(r.updated_at),
});

/** `%` and `_` in the search are the person's characters, not patterns. */
const like = (q: string) => `%${q.replace(/[\\%_]/g, (ch) => `\\${ch}`)}%`;

const textOf = (parts: readonly { type: string; text?: string }[]) =>
  parts
    .flatMap((p) => (p.type === "text" && typeof p.text === "string" ? [p.text] : []))
    .join("")
    .trim();

/** Markdown down to plain text, near enough for a whole message's `text` (searching, lists). */
export function plainOf(markdown: string): string {
  return markdown
    .replace(/```[^\n]*\n([\s\S]*?)```/g, "$1")
    .replace(/!\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/\[([^\]]+)\]\([^)]*\)/g, "$1")
    .replace(/^\s{0,3}(#{1,6}|>)\s?/gm, "")
    .replace(/(\*\*|__)(.+?)\1/g, "$2")
    .replace(/`([^`]+)`/g, "$1")
    .trim();
}

export interface SavedOrigins {
  db: SqlClient;
  events: Pick<EventStore, "list">;
  agentName: (id: string) => string | null;
}

/** What a message of the owner says and where it is; null when it is not theirs (or not there). */
export async function findOrigin(
  o: SavedOrigins,
  ownerId: string,
  ref: SavedCreateBody["source"],
): Promise<{ source: SavedSource; markdown: string } | null> {
  if (ref.kind === "session") {
    const [row] = await o.db.query<{ agent_id: string; title: string | null }>(
      "SELECT agent_id, title FROM rg_sessions WHERE id = $1 AND owner_id = $2",
      [ref.sessionId, ownerId],
    );
    if (!row) return null;
    const event = (await sessionLog(o.events, ref.sessionId)).find(
      (e) => e.seq === ref.seq && e.type === "message.assistant",
    );
    if (!event || event.type !== "message.assistant" || !event.payload) return null;
    return {
      markdown: textOf(event.payload.parts),
      source: {
        kind: "session",
        sessionId: ref.sessionId,
        seq: ref.seq,
        ...(ref.start !== undefined && { start: ref.start }),
        ...(ref.end !== undefined && { end: ref.end }),
        agentId: row.agent_id,
        agentName: o.agentName(row.agent_id),
        title: row.title,
        messageAt: event.ts,
      },
    };
  }
  const [row] = await o.db.query<{
    title: string;
    message: unknown;
    created_at: Date | string;
  }>(
    `SELECT c.title, m.message, m.created_at FROM rg_chat_messages m
     JOIN rg_chats c ON c.id = m.chat_id
     WHERE m.id = $1 AND m.chat_id = $2 AND c.owner_id = $3`,
    [ref.messageId, ref.chatId, ownerId],
  );
  if (!row) return null;
  const message = parse<ChatMessage>(row.message);
  if (message.role !== "assistant") return null;
  return {
    markdown: textOf(message.parts as { type: string; text?: string }[]),
    source: {
      kind: "chat",
      chatId: ref.chatId,
      messageId: ref.messageId,
      agentId: null,
      agentName: null,
      title: row.title,
      messageAt: iso(row.created_at),
    },
  };
}

export class SavedStore {
  constructor(
    private readonly db: SqlClient,
    private readonly origins: SavedOrigins,
    private readonly o: { now?: () => number } = {},
  ) {}

  private now() {
    return new Date(this.o.now?.() ?? Date.now()).toISOString();
  }

  async create(ownerId: string, body: SavedCreateBody): Promise<SavedItem> {
    const origin = await findOrigin(this.origins, ownerId, body.source);
    if (!origin) throw new SavedError("That message is not one of yours", 404);
    const whole = body.text === undefined;
    if (whole && !origin.markdown) throw new SavedError("That message has no text to save", 400);
    const text = whole ? plainOf(origin.markdown) || origin.markdown : (body.text as string);
    const markdown = whole ? origin.markdown : (body.markdown ?? null);
    const id = `sav_${randomBytes(8).toString("hex")}`;
    const now = this.now();
    const [r] = await this.db.query<Row>(
      `INSERT INTO rg_saved (id, owner_id, agent_id, text, markdown, whole, note, tags, source,
         created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $10) RETURNING ${COLUMNS}`,
      [
        id,
        ownerId,
        origin.source.agentId,
        text,
        markdown,
        whole,
        (body.note ?? "").trim(),
        JSON.stringify(normalizeTags(body.tags ?? [])),
        JSON.stringify(origin.source),
        now,
      ],
    );
    if (!r) throw new Error("The item was not saved");
    return view(r);
  }

  async get(ownerId: string, id: string): Promise<SavedItem | null> {
    const [r] = await this.db.query<Row>(
      `SELECT ${COLUMNS} FROM rg_saved WHERE id = $1 AND owner_id = $2`,
      [id, ownerId],
    );
    return r ? view(r) : null;
  }

  /** Newest first; `q` in the passage, its Markdown, the note or the conversation's title. */
  async list(ownerId: string, q: SavedQuery = {}, cap = SAVED_PAGE_MAX): Promise<SavedList> {
    const args: unknown[] = [ownerId];
    const where = ["owner_id = $1"];
    const arg = (v: unknown) => {
      args.push(v);
      return `$${args.length}`;
    };
    if (q.q) {
      const p = arg(like(q.q));
      where.push(
        `(text ILIKE ${p} OR coalesce(markdown, '') ILIKE ${p} OR note ILIKE ${p} OR coalesce(source->>'title', '') ILIKE ${p})`,
      );
    }
    if (q.tag)
      where.push(
        `EXISTS (SELECT 1 FROM jsonb_array_elements_text(tags) t WHERE lower(t) = lower(${arg(q.tag)}))`,
      );
    if (q.agentId) where.push(`agent_id = ${arg(q.agentId)}`);
    if (q.before) where.push(`created_at < ${arg(q.before)}`);
    const limit = Math.min(q.limit ?? 50, cap);
    const rows = await this.db.query<Row>(
      `SELECT ${COLUMNS} FROM rg_saved WHERE ${where.join(" AND ")}
       ORDER BY created_at DESC, id DESC LIMIT ${arg(limit + 1)}`,
      args,
    );
    const tags = await this.db.query<{ tag: string; count: string | number }>(
      `SELECT min(t) AS tag, count(*) AS count FROM rg_saved, jsonb_array_elements_text(tags) t
       WHERE owner_id = $1 GROUP BY lower(t) ORDER BY lower(t)`,
      [ownerId],
    );
    const agents = await this.db.query<{
      id: string;
      name: string | null;
      count: string | number;
    }>(
      `SELECT agent_id AS id, max(source->>'agentName') AS name, count(*) AS count FROM rg_saved
       WHERE owner_id = $1 AND agent_id IS NOT NULL GROUP BY agent_id`,
      [ownerId],
    );
    return {
      items: rows.slice(0, limit).map(view),
      more: rows.length > limit,
      tags: tags.map((t) => ({ tag: t.tag, count: Number(t.count) })),
      agents: agents
        .map((a) => ({
          id: a.id,
          name: this.origins.agentName(a.id) ?? a.name ?? a.id,
          count: Number(a.count),
        }))
        .sort((a, b) => a.name.localeCompare(b.name)),
    };
  }

  async update(ownerId: string, id: string, b: SavedUpdateBody): Promise<SavedItem | null> {
    const args: unknown[] = [id, ownerId, this.now()];
    const sets = ["updated_at = $3"];
    if (b.note !== undefined) {
      args.push(b.note.trim());
      sets.push(`note = $${args.length}`);
    }
    if (b.tags !== undefined) {
      args.push(JSON.stringify(normalizeTags(b.tags)));
      sets.push(`tags = $${args.length}`);
    }
    const [r] = await this.db.query<Row>(
      `UPDATE rg_saved SET ${sets.join(", ")} WHERE id = $1 AND owner_id = $2 RETURNING ${COLUMNS}`,
      args,
    );
    return r ? view(r) : null;
  }

  async remove(ownerId: string, id: string): Promise<boolean> {
    const rows = await this.db.query<{ id: string }>(
      "DELETE FROM rg_saved WHERE id = $1 AND owner_id = $2 RETURNING id",
      [id, ownerId],
    );
    return rows.length > 0;
  }
}
