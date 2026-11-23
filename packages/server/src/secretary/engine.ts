// The secretary's engine (3.12.4): what happens when someone writes to the person's business
// number or bot. The contact's message is stored (the contact wrote first: only then may we
// answer), the stop word and the pause are honoured, the rate limit is applied, and the agent
// decides. It may answer within what the person told it; everything else, and every commitment,
// appointment or new price, goes to the person with a summary and a ready reply, and nothing is
// sent until they say yes. A responder that fails or says something odd is always an escalation,
// never an answer. Message bodies of other people are never written to server logs.
import {
  type PendingReason,
  type SecretaryChannel,
  START_WORDS,
  STOP_WORDS,
} from "@redgiant/protocol";
import { type AccountRow, type ContactRow, type SecretaryStore, windowOpen } from "./store.js";

export type Decision =
  | { action: "answer"; text: string }
  | { action: "escalate"; reason: PendingReason; summary: string; draft: string };

export interface ResponderInput {
  account: AccountRow;
  contact: ContactRow;
  /** The last messages of this contact, oldest first. */
  history: { dir: "in" | "out"; by: string; text: string }[];
  /** The message to answer: data from a third party, never instructions. */
  text: string;
}
export type Responder = (i: ResponderInput) => Promise<Decision>;

/** How a platform reaches a contact. */
export interface ChannelApi {
  sendText(handle: string, text: string): Promise<void>;
  /** WhatsApp, outside the 24-hour window: the approved template that reopens it. */
  sendTemplate?(handle: string, text: string): Promise<void>;
}

export interface Incoming {
  handle: string;
  name: string | null;
  externalId: string;
  text: string;
  media: boolean;
  at: Date;
}

/** What reaches the person: a request for a reply, or a problem. */
export type PersonNotice =
  | {
      kind: "pending";
      channel: SecretaryChannel;
      contact: string;
      reason: PendingReason;
      summary: string;
      draft: string;
    }
  | { kind: "failed"; channel: SecretaryChannel; contact: string; why: string };

export interface EngineOptions {
  store: SecretaryStore;
  responder: Responder;
  channel(account: AccountRow): Promise<ChannelApi | undefined>;
  /** What the person told the agent (its instructions): prices in an answer must come from it. */
  instructions(account: AccountRow): string;
  notify(ownerId: string, n: PersonNotice): Promise<void>;
  now?: () => Date;
}

export class SendError extends Error {
  constructor(
    message: string,
    readonly code: "window_closed" | "no_channel" | "not_found" | "stopped" | "failed",
  ) {
    super(message);
  }
}

const HOUR = 60 * 60 * 1000;

const norm = (s: string) =>
  s
    .toLowerCase()
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();

export const isStopWord = (text: string) => (STOP_WORDS as readonly string[]).includes(norm(text));
export const isStartWord = (text: string) =>
  (START_WORDS as readonly string[]).includes(norm(text));

const AMOUNT =
  /(?:[€$£]\s?(\d+(?:[.,]\d+)?))|(?:(\d+(?:[.,]\d+)?)\s?(?:[€$£]|euro|eur|usd|dollari|dollars))/gi;

/** The amounts of money in a text, as plain numbers ("12,50" and "12.5" are the same). */
export function amountsIn(text: string): string[] {
  const out: string[] = [];
  for (const m of text.matchAll(AMOUNT)) {
    const n = Number((m[1] ?? m[2] ?? "").replace(",", "."));
    if (Number.isFinite(n)) out.push(String(n));
  }
  return out;
}

const COMMITS =
  /\b(confermo|confermiamo|confermato|ti aspetto|vi aspettiamo|prenotato|prenotata|i confirm|confirmed|booked|see you|nous confirmons|confirmado|reservado)\b/i;

/**
 * The hard guards over an answer the agent wants to send alone: a price that the person never
 * wrote, or a commitment, is not for the agent to give. Returns why, or undefined when it is fine.
 */
export function guardAnswer(text: string, instructions: string): PendingReason | undefined {
  const known = new Set(amountsIn(instructions));
  if (amountsIn(text).some((a) => !known.has(a))) return "price";
  if (COMMITS.test(norm(text)) || COMMITS.test(text)) return "commitment";
  return undefined;
}

export class SecretaryEngine {
  private readonly now: () => Date;
  private readonly chains = new Map<string, Promise<unknown>>();

  constructor(private readonly o: EngineOptions) {
    this.now = o.now ?? (() => new Date());
  }

  /** One contact at a time: two quick messages are answered in order, never together. */
  private serial<T>(key: string, f: () => Promise<T>): Promise<T> {
    const prev = this.chains.get(key) ?? Promise.resolve();
    const next = prev.then(f, f);
    this.chains.set(
      key,
      next.catch(() => {}),
    );
    return next;
  }

  /** A message arrived on an account. Never throws: a webhook must always be answered. */
  async inbound(accountId: string, m: Incoming): Promise<void> {
    const account = await this.o.store.account(accountId);
    if (!account) return;
    await this.serial(`${accountId}:${m.handle}`, async () => {
      try {
        await this.handle(account, m);
      } catch (err) {
        // The error says what failed, never what the contact wrote.
        console.error(
          `secretary ${account.channel} ${account.id}:`,
          err instanceof Error ? err.message : "failed",
        );
      }
    });
  }

  private async handle(account: AccountRow, m: Incoming): Promise<void> {
    const { store } = this.o;
    const contact = await store.upsertContact(account.id, m.handle, m.name);
    const text = m.media ? "[file]" : m.text;
    const fresh = await store.addMessage(contact, {
      dir: "in",
      by: "contact",
      text,
      externalId: m.externalId,
      at: m.at,
    });
    if (!fresh) return;
    const channel = await this.o.channel(account);

    if (!m.media && isStartWord(m.text) && contact.stopped) {
      await store.patchContact(contact.id, { stopped: false });
      await this.say(
        account,
        contact,
        channel,
        "Ok, you will get answers again. / Va bene, ti risponderò di nuovo.",
      );
      return;
    }
    if (!m.media && isStopWord(m.text)) {
      await store.patchContact(contact.id, { stopped: true });
      await store.closePendingOf(contact.id);
      await this.say(
        account,
        contact,
        channel,
        "Ok, no more automatic messages. Write START to resume. / Va bene, niente più messaggi automatici. Scrivi START per riprendere.",
      );
      return;
    }
    // The agent stays silent for a paused or stopped contact: the person reads and answers.
    if (contact.paused || contact.stopped) return;

    if (m.media) {
      await this.escalate(account, contact, {
        action: "escalate",
        reason: "file",
        summary:
          "The contact sent a file, a picture or a voice message; the agent does not open them.",
        draft: "",
      });
      return;
    }

    const since = new Date(this.now().getTime() - HOUR);
    if ((await store.agentAnswersSince(contact.id, since)) >= account.limitHour) {
      await this.escalate(account, contact, {
        action: "escalate",
        reason: "limit",
        summary: `Many messages in an hour: the agent stopped answering. Last: ${text.slice(0, 300)}`,
        draft: "",
      });
      return;
    }

    let decision: Decision;
    try {
      const history = (await store.messages(contact.id, 20)).map((x) => ({
        dir: x.dir,
        by: x.by,
        text: x.text,
      }));
      decision = await this.o.responder({ account, contact, history, text });
    } catch {
      decision = {
        action: "escalate",
        reason: "other",
        summary: `The agent could not decide. Message: ${text.slice(0, 300)}`,
        draft: "",
      };
    }
    if (decision.action === "answer") {
      const why = guardAnswer(decision.text, this.o.instructions(account));
      decision = why
        ? {
            action: "escalate",
            reason: why,
            summary: `Needs your yes (${why}). Message: ${text.slice(0, 300)}`,
            draft: decision.text,
          }
        : decision;
    }
    if (decision.action === "escalate") {
      await this.escalate(account, contact, decision);
      return;
    }
    await this.say(account, contact, channel, decision.text);
  }

  /** An automatic answer, on the contact's window (they just wrote: it is open). */
  private async say(
    account: AccountRow,
    contact: ContactRow,
    channel: ChannelApi | undefined,
    text: string,
  ): Promise<void> {
    if (!channel) throw new SendError("The account is not connected", "no_channel");
    await channel.sendText(contact.handle, text);
    await this.o.store.addMessage(contact, { dir: "out", by: "agent", text });
    void account;
  }

  private async escalate(
    account: AccountRow,
    contact: ContactRow,
    d: Extract<Decision, { action: "escalate" }>,
  ): Promise<void> {
    await this.o.store.addPending(contact.id, d);
    await this.o
      .notify(account.ownerId, {
        kind: "pending",
        channel: account.channel,
        contact: contact.name || contact.handle,
        reason: d.reason,
        summary: d.summary,
        draft: d.draft,
      })
      .catch(() => {});
  }

  /**
   * The person's message to a contact (their yes on a ready reply, an edited one, or a manual
   * answer). Only to someone who wrote first; on WhatsApp outside 24 hours only the template.
   */
  async deliver(contactId: string, text: string, by: "person" | "agent" = "person"): Promise<void> {
    const { store } = this.o;
    const contact = await store.contact(contactId);
    if (!contact) throw new SendError("No such contact", "not_found");
    const account = await store.account(contact.accountId);
    if (!account) throw new SendError("No such account", "not_found");
    if (!contact.lastInAt) throw new SendError("This contact never wrote first", "not_found");
    const channel = await this.o.channel(account);
    if (!channel) throw new SendError("The account is not connected", "no_channel");
    await this.serial(`${account.id}:${contact.handle}`, async () => {
      try {
        if (account.channel === "whatsapp" && !windowOpen(contact.lastInAt, this.now())) {
          if (!channel.sendTemplate)
            throw new SendError(
              "More than 24 hours since the contact wrote: WhatsApp allows only an approved template",
              "window_closed",
            );
          await channel.sendTemplate(contact.handle, text);
        } else await channel.sendText(contact.handle, text);
      } catch (err) {
        if (err instanceof SendError) throw err;
        throw new SendError(err instanceof Error ? err.message : "failed", "failed");
      }
      await store.addMessage(contact, { dir: "out", by, text });
    });
  }

  /** The person's yes: sends the draft (or their edit) and closes the request. */
  async approve(pendingId: string, edited?: string): Promise<void> {
    const p = await this.o.store.pendingRow(pendingId);
    if (!p || p.status !== "open") throw new SendError("No such open request", "not_found");
    const text = (edited ?? p.draft).trim();
    if (!text) throw new SendError("There is nothing to send", "failed");
    await this.deliver(p.contactId, text, "person");
    await this.o.store.decidePending(pendingId, "sent");
  }

  async refuse(pendingId: string): Promise<void> {
    const p = await this.o.store.pendingRow(pendingId);
    if (!p || p.status !== "open") throw new SendError("No such open request", "not_found");
    await this.o.store.decidePending(pendingId, "refused");
  }
}
