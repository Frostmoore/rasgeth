// The secretary's rows (3.12.4): accounts (a WhatsApp number or a Telegram bot), one contact per
// person who writes, their messages and the replies waiting for the person. Like the daily chat,
// they are ordinary rows the person can read and delete; the keys live only in the keychain.
import { randomUUID } from "node:crypto";
import type { SqlClient } from "@redgiant/events";
import type {
  PendingReason,
  SecretaryChannel,
  SecretaryContactView,
  SecretaryMessageView,
  SecretaryPendingView,
} from "@redgiant/protocol";
import { WHATSAPP_WINDOW_MS } from "@redgiant/protocol";

export async function migrateSecretary(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_sec_accounts (
      id          text PRIMARY KEY,
      owner_id    text NOT NULL,
      channel     text NOT NULL,
      name        text NOT NULL,
      agent_id    text,
      label       text NOT NULL,
      config      jsonb NOT NULL DEFAULT '{}',
      webhook_ok  boolean NOT NULL DEFAULT false,
      limit_hour  integer NOT NULL DEFAULT 6,
      created_at  timestamptz NOT NULL DEFAULT now()
    )`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_sec_contacts (
      id          text PRIMARY KEY,
      account_id  text NOT NULL REFERENCES rg_sec_accounts(id) ON DELETE CASCADE,
      handle      text NOT NULL,
      name        text NOT NULL DEFAULT '',
      notes       text NOT NULL DEFAULT '',
      paused      boolean NOT NULL DEFAULT false,
      stopped     boolean NOT NULL DEFAULT false,
      unread      integer NOT NULL DEFAULT 0,
      last_at     timestamptz,
      last_in_at  timestamptz,
      last_text   text NOT NULL DEFAULT '',
      created_at  timestamptz NOT NULL DEFAULT now(),
      UNIQUE (account_id, handle)
    )`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_sec_messages (
      id          bigserial PRIMARY KEY,
      contact_id  text NOT NULL REFERENCES rg_sec_contacts(id) ON DELETE CASCADE,
      dir         text NOT NULL,
      by          text NOT NULL,
      text        text NOT NULL,
      external_id text,
      at          timestamptz NOT NULL DEFAULT now()
    )`);
  await db.query(
    "CREATE UNIQUE INDEX IF NOT EXISTS rg_sec_messages_ext ON rg_sec_messages (contact_id, external_id) WHERE external_id IS NOT NULL",
  );
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_sec_pending (
      id          text PRIMARY KEY,
      contact_id  text NOT NULL REFERENCES rg_sec_contacts(id) ON DELETE CASCADE,
      reason      text NOT NULL,
      summary     text NOT NULL,
      draft       text NOT NULL,
      status      text NOT NULL DEFAULT 'open',
      created_at  timestamptz NOT NULL DEFAULT now(),
      decided_at  timestamptz
    )`);
}

export interface AccountRow {
  id: string;
  ownerId: string;
  channel: SecretaryChannel;
  name: string;
  agentId: string | null;
  label: string;
  config: Record<string, unknown>;
  webhookOk: boolean;
  limitHour: number;
  createdAt: string;
}

export interface ContactRow {
  id: string;
  accountId: string;
  handle: string;
  name: string;
  notes: string;
  paused: boolean;
  stopped: boolean;
  unread: number;
  lastAt: string | null;
  lastInAt: string | null;
  lastText: string;
}

interface AccountSql {
  id: string;
  owner_id: string;
  channel: SecretaryChannel;
  name: string;
  agent_id: string | null;
  label: string;
  config: unknown;
  webhook_ok: boolean;
  limit_hour: number;
  created_at: string | Date;
}

interface ContactSql {
  id: string;
  account_id: string;
  handle: string;
  name: string;
  notes: string;
  paused: boolean;
  stopped: boolean;
  unread: number;
  last_at: string | Date | null;
  last_in_at: string | Date | null;
  last_text: string;
}

const iso = (d: string | Date | null) => (d === null ? null : new Date(d).toISOString());
const json = (v: unknown) =>
  (typeof v === "string" ? JSON.parse(v) : (v ?? {})) as Record<string, unknown>;

const account = (r: AccountSql): AccountRow => ({
  id: r.id,
  ownerId: r.owner_id,
  channel: r.channel,
  name: r.name,
  agentId: r.agent_id,
  label: r.label,
  config: json(r.config),
  webhookOk: r.webhook_ok,
  limitHour: r.limit_hour,
  createdAt: iso(r.created_at) as string,
});

const contact = (r: ContactSql): ContactRow => ({
  id: r.id,
  accountId: r.account_id,
  handle: r.handle,
  name: r.name,
  notes: r.notes,
  paused: r.paused,
  stopped: r.stopped,
  unread: r.unread,
  lastAt: iso(r.last_at),
  lastInAt: iso(r.last_in_at),
  lastText: r.last_text,
});

export class SecretaryStore {
  constructor(private readonly db: SqlClient) {}

  async addAccount(a: Omit<AccountRow, "id" | "createdAt" | "webhookOk"> & { id?: string }) {
    const id = a.id ?? randomUUID();
    await this.db.query(
      `INSERT INTO rg_sec_accounts (id, owner_id, channel, name, agent_id, label, config, limit_hour)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [id, a.ownerId, a.channel, a.name, a.agentId, a.label, JSON.stringify(a.config), a.limitHour],
    );
    return (await this.account(id)) as AccountRow;
  }

  async account(id: string): Promise<AccountRow | undefined> {
    const [r] = await this.db.query<AccountSql>("SELECT * FROM rg_sec_accounts WHERE id = $1", [
      id,
    ]);
    return r && account(r);
  }

  async accounts(ownerId: string): Promise<AccountRow[]> {
    return (
      await this.db.query<AccountSql>(
        "SELECT * FROM rg_sec_accounts WHERE owner_id = $1 ORDER BY created_at, id",
        [ownerId],
      )
    ).map(account);
  }

  async updateAccount(
    id: string,
    p: {
      name?: string;
      label?: string;
      agentId?: string | null;
      webhookOk?: boolean;
      limitHour?: number;
      config?: Record<string, unknown>;
    },
  ) {
    const sets: string[] = [];
    const args: unknown[] = [id];
    const add = (col: string, v: unknown) => {
      args.push(v);
      sets.push(`${col} = $${args.length}`);
    };
    if (p.name !== undefined) add("name", p.name);
    if (p.label !== undefined) add("label", p.label);
    if (p.agentId !== undefined) add("agent_id", p.agentId);
    if (p.webhookOk !== undefined) add("webhook_ok", p.webhookOk);
    if (p.limitHour !== undefined) add("limit_hour", p.limitHour);
    if (p.config !== undefined) add("config", JSON.stringify(p.config));
    if (sets.length)
      await this.db.query(`UPDATE rg_sec_accounts SET ${sets.join(", ")} WHERE id = $1`, args);
  }

  async removeAccount(id: string) {
    await this.db.query("DELETE FROM rg_sec_accounts WHERE id = $1", [id]);
  }

  async contact(id: string): Promise<ContactRow | undefined> {
    const [r] = await this.db.query<ContactSql>("SELECT * FROM rg_sec_contacts WHERE id = $1", [
      id,
    ]);
    return r && contact(r);
  }

  async contactByHandle(accountId: string, handle: string): Promise<ContactRow | undefined> {
    const [r] = await this.db.query<ContactSql>(
      "SELECT * FROM rg_sec_contacts WHERE account_id = $1 AND handle = $2",
      [accountId, handle],
    );
    return r && contact(r);
  }

  /** The contact who wrote; created at the first message (nobody is ever written to before). */
  async upsertContact(accountId: string, handle: string, name: string | null): Promise<ContactRow> {
    const found = await this.contactByHandle(accountId, handle);
    if (found) {
      if (name && !found.name)
        await this.db.query("UPDATE rg_sec_contacts SET name = $2 WHERE id = $1", [found.id, name]);
      return (await this.contact(found.id)) as ContactRow;
    }
    const id = randomUUID();
    await this.db.query(
      "INSERT INTO rg_sec_contacts (id, account_id, handle, name) VALUES ($1, $2, $3, $4)",
      [id, accountId, handle, name ?? ""],
    );
    return (await this.contact(id)) as ContactRow;
  }

  async patchContact(
    id: string,
    p: { name?: string; notes?: string; paused?: boolean; stopped?: boolean; unread?: number },
  ) {
    const sets: string[] = [];
    const args: unknown[] = [id];
    const add = (col: string, v: unknown) => {
      args.push(v);
      sets.push(`${col} = $${args.length}`);
    };
    if (p.name !== undefined) add("name", p.name);
    if (p.notes !== undefined) add("notes", p.notes);
    if (p.paused !== undefined) add("paused", p.paused);
    if (p.stopped !== undefined) add("stopped", p.stopped);
    if (p.unread !== undefined) add("unread", p.unread);
    if (sets.length)
      await this.db.query(`UPDATE rg_sec_contacts SET ${sets.join(", ")} WHERE id = $1`, args);
  }

  /** False when this external id was already stored (the platform retries deliveries). */
  async addMessage(
    c: ContactRow,
    m: {
      dir: "in" | "out";
      by: "contact" | "agent" | "person";
      text: string;
      externalId?: string;
      at?: Date;
    },
  ): Promise<boolean> {
    const at = m.at ?? new Date();
    const rows = await this.db.query<{ id: number }>(
      `INSERT INTO rg_sec_messages (contact_id, dir, by, text, external_id, at)
       VALUES ($1, $2, $3, $4, $5, $6) ON CONFLICT DO NOTHING RETURNING id`,
      [c.id, m.dir, m.by, m.text, m.externalId ?? null, at],
    );
    if (rows.length === 0) return false;
    await this.db.query(
      `UPDATE rg_sec_contacts SET last_at = $2, last_text = $3,
         last_in_at = CASE WHEN $4 THEN $2 ELSE last_in_at END,
         unread = CASE WHEN $4 THEN unread + 1 ELSE unread END
       WHERE id = $1`,
      [c.id, at, m.text.slice(0, 200), m.dir === "in"],
    );
    return true;
  }

  async messages(contactId: string, limit = 200): Promise<SecretaryMessageView[]> {
    const rows = await this.db.query<{
      id: string | number;
      dir: "in" | "out";
      by: SecretaryMessageView["by"];
      text: string;
      at: string | Date;
    }>(
      "SELECT id, dir, by, text, at FROM rg_sec_messages WHERE contact_id = $1 ORDER BY id DESC LIMIT $2",
      [contactId, limit],
    );
    return rows
      .reverse()
      .map((r) => ({
        id: Number(r.id),
        dir: r.dir,
        by: r.by,
        text: r.text,
        at: iso(r.at) as string,
      }));
  }

  /** Automatic answers sent to this contact since `since` (the rate limit). */
  async agentAnswersSince(contactId: string, since: Date): Promise<number> {
    const [r] = await this.db.query<{ n: string | number }>(
      "SELECT count(*) AS n FROM rg_sec_messages WHERE contact_id = $1 AND dir = 'out' AND by = 'agent' AND at >= $2",
      [contactId, since],
    );
    return Number(r?.n ?? 0);
  }

  async listContacts(ownerId: string, now: Date): Promise<SecretaryContactView[]> {
    const rows = await this.db.query<
      ContactSql & { channel: SecretaryChannel; pending: string | number }
    >(
      `SELECT c.*, a.channel,
         (SELECT count(*) FROM rg_sec_pending p WHERE p.contact_id = c.id AND p.status = 'open') AS pending
       FROM rg_sec_contacts c JOIN rg_sec_accounts a ON a.id = c.account_id
       WHERE a.owner_id = $1 ORDER BY c.last_at DESC NULLS LAST, c.created_at DESC`,
      [ownerId],
    );
    return rows.map((r) => this.view(contact(r), r.channel, Number(r.pending), now));
  }

  view(c: ContactRow, channel: SecretaryChannel, pending: number, now: Date): SecretaryContactView {
    return {
      id: c.id,
      accountId: c.accountId,
      channel,
      handle: c.handle,
      name: c.name,
      notes: c.notes,
      paused: c.paused,
      stopped: c.stopped,
      unread: c.unread,
      lastAt: c.lastAt,
      lastText: c.lastText,
      windowOpen: channel === "telegram" || windowOpen(c.lastInAt, now),
      pending,
    };
  }

  async removeContact(id: string) {
    await this.db.query("DELETE FROM rg_sec_contacts WHERE id = $1", [id]);
  }

  async addPending(
    contactId: string,
    p: { reason: PendingReason; summary: string; draft: string },
  ): Promise<string> {
    const id = randomUUID();
    await this.db.query(
      "INSERT INTO rg_sec_pending (id, contact_id, reason, summary, draft) VALUES ($1, $2, $3, $4, $5)",
      [id, contactId, p.reason, p.summary, p.draft],
    );
    return id;
  }

  async pending(ownerId: string, onlyOpen = true): Promise<SecretaryPendingView[]> {
    const rows = await this.db.query<{
      id: string;
      contact_id: string;
      reason: PendingReason;
      summary: string;
      draft: string;
      status: SecretaryPendingView["status"];
      created_at: string | Date;
      name: string;
      handle: string;
      channel: SecretaryChannel;
    }>(
      `SELECT p.*, c.name, c.handle, a.channel FROM rg_sec_pending p
       JOIN rg_sec_contacts c ON c.id = p.contact_id JOIN rg_sec_accounts a ON a.id = c.account_id
       WHERE a.owner_id = $1 ${onlyOpen ? "AND p.status = 'open'" : ""} ORDER BY p.created_at DESC`,
      [ownerId],
    );
    return rows.map((r) => ({
      id: r.id,
      contactId: r.contact_id,
      contactName: r.name || r.handle,
      channel: r.channel,
      reason: r.reason,
      summary: r.summary,
      draft: r.draft,
      status: r.status,
      createdAt: iso(r.created_at) as string,
    }));
  }

  async pendingRow(id: string) {
    const [r] = await this.db.query<{
      id: string;
      contact_id: string;
      draft: string;
      status: string;
    }>("SELECT id, contact_id, draft, status FROM rg_sec_pending WHERE id = $1", [id]);
    return r && { id: r.id, contactId: r.contact_id, draft: r.draft, status: r.status };
  }

  async decidePending(id: string, status: "sent" | "refused") {
    await this.db.query("UPDATE rg_sec_pending SET status = $2, decided_at = now() WHERE id = $1", [
      id,
      status,
    ]);
  }

  async closePendingOf(contactId: string) {
    await this.db.query(
      "UPDATE rg_sec_pending SET status = 'refused', decided_at = now() WHERE contact_id = $1 AND status = 'open'",
      [contactId],
    );
  }
}

/** The WhatsApp customer-service window: open for 24 hours after the contact's last message. */
export function windowOpen(lastInAt: string | null, now: Date): boolean {
  return lastInAt !== null && now.getTime() - new Date(lastInAt).getTime() < WHATSAPP_WINDOW_MS;
}
