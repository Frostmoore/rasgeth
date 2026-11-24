// The secretary's service (3.12.4): the accounts the person connects (a WhatsApp Business number
// or a Telegram bot), their keys in the keychain, the public webhooks and the person's side of the
// contacts (list, read, take over, pause, answer ready replies). The platforms are reached through
// an injected `fetch`: tests give a fake, never Meta or Telegram.
import { randomBytes } from "node:crypto";
import type { SqlClient } from "@redgiant/events";
import type {
  SecretaryAccountView,
  SecretaryChannel,
  SecretaryContactView,
  SecretaryPendingView,
  TelegramBotInput,
  WhatsAppBusinessInput,
} from "@redgiant/protocol";
import type { SystemKeyMeta, Vault } from "../vault.js";
import {
  type ChannelApi,
  type EngineOptions,
  type Incoming,
  type PersonNotice,
  type Responder,
  SecretaryEngine,
} from "./engine.js";
import { checkRemote, checkTelegramToken, checkWhatsAppToken, type StepResult } from "./guide.js";
import { type AccountRow, migrateSecretary, SecretaryStore } from "./store.js";
import * as tg from "./telegram.js";
import * as wa from "./whatsapp.js";

export class SecretaryError extends Error {
  constructor(
    message: string,
    readonly code: string,
  ) {
    super(message);
  }
}

export interface SecretaryOptions {
  db: SqlClient;
  vault: Vault;
  responder: Responder;
  /** What the person told the agent that answers on this account. */
  instructions: (account: AccountRow) => string;
  /** How the person is told (their chats and the page); the text is made by the caller. */
  notify: (ownerId: string, n: PersonNotice) => Promise<void>;
  /** The ordinary request delivery for a ready reply (page, chats, phone); see the engine. */
  ask?: EngineOptions["ask"];
  /** RedGiant's address from outside home, or undefined with no way in. */
  publicUrl: () => string | undefined;
  fetch?: wa.Fetch;
  graphRoot?: string;
  telegramRoot?: string;
  now?: () => Date;
}

const WEBHOOK = {
  whatsapp: (id: string) => `/api/secretary/whatsapp/${id}/webhook`,
  telegram: (id: string) => `/api/secretary/telegram/${id}/webhook`,
};

export class SecretaryService {
  readonly store: SecretaryStore;
  readonly engine: SecretaryEngine;
  private readonly f: wa.Fetch;
  private readonly now: () => Date;

  constructor(private readonly o: SecretaryOptions) {
    this.f = o.fetch ?? ((url, init) => fetch(url, init));
    this.now = o.now ?? (() => new Date());
    this.store = new SecretaryStore(o.db);
    this.engine = new SecretaryEngine({
      store: this.store,
      responder: o.responder,
      instructions: o.instructions,
      notify: o.notify,
      ...(o.ask && { ask: o.ask }),
      now: this.now,
      channel: (a) => this.channelFor(a),
    });
  }

  migrate(): Promise<void> {
    return migrateSecretary(this.o.db);
  }

  private keyOf(id: string, what: string) {
    return `secretary:${id}:${what}`;
  }

  private meta(a: AccountRow, what: string): SystemKeyMeta {
    const wa = a.channel === "whatsapp";
    return {
      name: `secretary-${a.id.slice(0, 8)}-${what}`,
      service: wa ? "WhatsApp Business" : "Telegram bot",
      brand: wa ? "whatsapp" : "telegram",
      category: "api",
      hosts: [wa ? "graph.facebook.com" : "api.telegram.org"],
      inject: { header: "", format: "{value}" },
      section: "secretary",
      kind: "chat",
      what: `${what} of the secretary's ${a.label || a.channel}`,
    };
  }

  private secret(a: AccountRow, what: string): string | undefined {
    return this.o.vault.ready
      ? this.o.vault.systemValue(a.ownerId, this.keyOf(a.id, what))
      : undefined;
  }

  private async keep(a: AccountRow, what: string, value: string | null) {
    await this.o.vault.setSystem(a.ownerId, this.keyOf(a.id, what), value, this.meta(a, what));
  }

  /** The platform's side of an account, from the keychain; undefined while it is not complete. */
  async channelFor(a: AccountRow): Promise<ChannelApi | undefined> {
    const token = this.secret(a, "token");
    if (!token) return undefined;
    if (a.channel === "telegram") {
      const root = this.o.telegramRoot ?? tg.TELEGRAM_ROOT;
      return { sendText: async (h, t) => void (await tg.sendMessage(this.f, token, h, t, root)) };
    }
    const phoneNumberId = String(a.config.phoneNumberId ?? "");
    if (!phoneNumberId) return undefined;
    const root = this.o.graphRoot ?? wa.GRAPH_ROOT;
    const creds = { token, phoneNumberId };
    const template = a.config.template as { name: string; language: string } | undefined;
    return {
      sendText: async (h, t) => void (await wa.sendText(this.f, creds, h, t, root)),
      ...(template && {
        sendTemplate: async (h: string, t: string) =>
          void (await wa.sendTemplate(this.f, creds, h, template, t, root)),
      }),
    };
  }

  view(a: AccountRow): SecretaryAccountView {
    const base = this.o.publicUrl()?.replace(/\/+$/, "");
    return {
      id: a.id,
      channel: a.channel,
      name: a.name,
      agentId: a.agentId,
      label: a.label,
      webhookUrl: base ? `${base}${WEBHOOK[a.channel](a.id)}` : null,
      verifyToken: a.channel === "whatsapp" ? (this.secret(a, "verify") ?? null) : null,
      webhookOk: a.webhookOk,
      complete: this.secret(a, "token") !== undefined,
      limitPerHour: a.limitHour,
      createdAt: a.createdAt,
    };
  }

  async accounts(ownerId: string): Promise<SecretaryAccountView[]> {
    return (await this.store.accounts(ownerId)).map((a) => this.view(a));
  }

  private async own(ownerId: string, id: string): Promise<AccountRow> {
    const a = await this.store.account(id);
    if (!a || a.ownerId !== ownerId) throw new SecretaryError("No such account", "not_found");
    return a;
  }

  // The guide ------------------------------------------------------------------------------

  /** A check the guide runs on its own (nothing is kept). */
  async check(
    channel: SecretaryChannel,
    step: string,
    p: { token?: string | undefined; phoneNumberId?: string | undefined },
  ): Promise<StepResult> {
    if (step === "remote") return checkRemote(this.o.publicUrl());
    if (channel === "telegram" && step === "token")
      return checkTelegramToken(this.f, p.token ?? "", this.o.telegramRoot);
    if (channel === "whatsapp" && (step === "token" || step === "number"))
      return checkWhatsAppToken(
        this.f,
        { token: p.token ?? "", phoneNumberId: p.phoneNumberId ?? "" },
        this.o.graphRoot,
      );
    return { ok: false, code: "unknown_step" };
  }

  /**
   * WhatsApp, first step: the account exists before Meta calls (Meta checks the webhook while the
   * person fills its form), with its address and a verify token Rasgeth made. Needs remote access.
   */
  async startWhatsApp(
    ownerId: string,
    name: string,
    agentId?: string,
  ): Promise<SecretaryAccountView> {
    const remote = checkRemote(this.o.publicUrl());
    if (!remote.ok) throw new SecretaryError("Remote access is not set up", remote.code);
    const a = await this.store.addAccount({
      ownerId,
      channel: "whatsapp",
      name,
      agentId: agentId ?? null,
      label: "WhatsApp Business",
      config: { draft: true },
      limitHour: 6,
    });
    await this.keep(a, "verify", randomBytes(18).toString("hex"));
    return this.view(a);
  }

  /** WhatsApp, last step: the token, the number and the app secret, checked and then kept. */
  async finishWhatsApp(
    ownerId: string,
    id: string,
    input: WhatsAppBusinessInput,
  ): Promise<SecretaryAccountView> {
    const a = await this.own(ownerId, id);
    if (a.channel !== "whatsapp") throw new SecretaryError("Not a WhatsApp account", "not_found");
    const r = await checkWhatsAppToken(
      this.f,
      { token: input.token, phoneNumberId: input.phoneNumberId },
      this.o.graphRoot,
    );
    if (!r.ok) throw new SecretaryError(r.detail ?? "Meta refused the token", r.code);
    await this.keep(a, "token", input.token);
    await this.keep(a, "appsecret", input.appSecret);
    await this.store.updateAccount(id, {
      label: r.number ?? a.label,
      name: input.name || a.name,
      ...(input.agentId && { agentId: input.agentId }),
      config: {
        phoneNumberId: input.phoneNumberId,
        ...(input.template && { template: input.template }),
      },
    });
    return this.view((await this.store.account(id)) as AccountRow);
  }

  async connectTelegram(ownerId: string, input: TelegramBotInput): Promise<SecretaryAccountView> {
    const remote = checkRemote(this.o.publicUrl());
    if (!remote.ok) throw new SecretaryError("Remote access is not set up", remote.code);
    const me = await checkTelegramToken(this.f, input.token, this.o.telegramRoot);
    if (!me.ok) throw new SecretaryError(me.detail ?? "Telegram refused the token", me.code);
    const a = await this.store.addAccount({
      ownerId,
      channel: "telegram",
      name: input.name,
      agentId: input.agentId ?? null,
      label: me.username ? `@${me.username}` : "Telegram bot",
      config: {},
      limitHour: 6,
    });
    try {
      const secret = randomBytes(24).toString("hex");
      await this.keep(a, "token", input.token);
      await this.keep(a, "verify", secret);
      const base = (this.o.publicUrl() as string).replace(/\/+$/, "");
      await tg.setWebhook(
        this.f,
        input.token,
        `${base}${WEBHOOK.telegram(a.id)}`,
        secret,
        this.o.telegramRoot,
      );
    } catch (err) {
      await this.removeAccount(ownerId, a.id);
      throw new SecretaryError(
        err instanceof Error ? err.message : "Telegram refused the webhook",
        "webhook_failed",
      );
    }
    await this.store.updateAccount(a.id, { webhookOk: true });
    return this.view((await this.store.account(a.id)) as AccountRow);
  }

  async updateAccount(
    ownerId: string,
    id: string,
    p: {
      name?: string | undefined;
      agentId?: string | null | undefined;
      limitPerHour?: number | undefined;
    },
  ): Promise<SecretaryAccountView> {
    await this.own(ownerId, id);
    await this.store.updateAccount(id, {
      ...(p.name !== undefined && { name: p.name }),
      ...(p.agentId !== undefined && { agentId: p.agentId }),
      ...(p.limitPerHour !== undefined && { limitHour: Math.max(1, Math.min(60, p.limitPerHour)) }),
    });
    return this.view((await this.store.account(id)) as AccountRow);
  }

  async removeAccount(ownerId: string, id: string): Promise<void> {
    const a = await this.own(ownerId, id);
    if (a.channel === "telegram") {
      const token = this.secret(a, "token");
      if (token) await tg.deleteWebhook(this.f, token, this.o.telegramRoot).catch(() => {});
    }
    for (const what of ["token", "appsecret", "verify"])
      await this.keep(a, what, null).catch(() => {});
    await this.store.removeAccount(id);
  }

  // The public webhooks -----------------------------------------------------------------------

  /** Meta's subscription check; marks the account's webhook as confirmed. */
  async whatsappHandshake(
    id: string,
    query: Record<string, string | undefined>,
  ): Promise<string | undefined> {
    const a = await this.store.account(id);
    const verify = a && this.secret(a, "verify");
    if (!a || a.channel !== "whatsapp" || !verify) return undefined;
    const challenge = wa.verifyHandshake(verify, query);
    if (challenge !== undefined) await this.store.updateAccount(id, { webhookOk: true });
    return challenge;
  }

  /** False when the signature is wrong; `done` settles once every message was handled. */
  async whatsappWebhook(
    id: string,
    raw: string,
    signature: string | undefined,
  ): Promise<{ ok: boolean; done: Promise<void> }> {
    const a = await this.store.account(id);
    const secret = a && this.secret(a, "appsecret");
    if (!a || a.channel !== "whatsapp" || !secret || !wa.validSignature(secret, raw, signature))
      return { ok: false, done: Promise.resolve() };
    const msgs = wa.parseWebhook(raw, String(a.config.phoneNumberId ?? ""));
    const done = (async () => {
      for (const m of msgs) await this.engine.inbound(id, m satisfies Incoming);
    })();
    return { ok: true, done };
  }

  async telegramWebhook(
    id: string,
    secretHeader: string | undefined,
    body: unknown,
  ): Promise<{ ok: boolean; done: Promise<void> }> {
    const a = await this.store.account(id);
    const secret = a && this.secret(a, "verify");
    if (!a || a.channel !== "telegram" || !secret || !tg.validSecret(secret, secretHeader))
      return { ok: false, done: Promise.resolve() };
    const m = tg.parseUpdate(body);
    return { ok: true, done: m ? this.engine.inbound(id, m) : Promise.resolve() };
  }

  // The person's side -------------------------------------------------------------------------

  contacts(ownerId: string): Promise<SecretaryContactView[]> {
    return this.store.listContacts(ownerId, this.now());
  }

  pending(ownerId: string): Promise<SecretaryPendingView[]> {
    return this.store.pending(ownerId);
  }

  private async ownContact(ownerId: string, id: string) {
    const c = await this.store.contact(id);
    const a = c && (await this.store.account(c.accountId));
    if (!c || !a || a.ownerId !== ownerId) throw new SecretaryError("No such contact", "not_found");
    return { c, a };
  }

  /** The conversation; reading it marks it read. */
  async conversation(ownerId: string, id: string) {
    const { c, a } = await this.ownContact(ownerId, id);
    const messages = await this.store.messages(id);
    await this.store.patchContact(id, { unread: 0 });
    const fresh = (await this.store.contact(id)) as typeof c;
    const pending = (await this.store.pending(ownerId)).filter((p) => p.contactId === id);
    return {
      contact: this.store.view(fresh, a.channel, pending.length, this.now()),
      messages,
      pending,
    };
  }

  async patchContact(
    ownerId: string,
    id: string,
    p: { name?: string | undefined; notes?: string | undefined; paused?: boolean | undefined },
  ): Promise<void> {
    await this.ownContact(ownerId, id);
    await this.store.patchContact(id, p);
  }

  async deleteContact(ownerId: string, id: string): Promise<void> {
    await this.ownContact(ownerId, id);
    await this.store.removeContact(id);
  }

  /** The person writes to a contact by hand (taking over). */
  async send(ownerId: string, id: string, text: string): Promise<void> {
    await this.ownContact(ownerId, id);
    await this.engine.deliver(id, text, "person");
  }

  async approve(ownerId: string, pendingId: string, edited?: string): Promise<void> {
    await this.ownPending(ownerId, pendingId);
    await this.engine.approve(pendingId, edited);
  }

  async refuse(ownerId: string, pendingId: string): Promise<void> {
    await this.ownPending(ownerId, pendingId);
    await this.engine.refuse(pendingId);
  }

  private async ownPending(ownerId: string, pendingId: string) {
    const p = await this.store.pendingRow(pendingId);
    if (!p) throw new SecretaryError("No such request", "not_found");
    await this.ownContact(ownerId, p.contactId);
  }
}
