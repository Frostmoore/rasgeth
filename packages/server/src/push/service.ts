// Notifications from the server (G40.4, 3.8). A device (its token, G40.1) registers one channel:
// Web Push to its UnifiedPush endpoint, or APNs through the blind relay (ready, switched off
// while no relay is set: the APNs key belongs to whoever publishes the app). The service is one
// more channel of the requests «all at once» (G36.17): every request and question that reaches
// the person reaches the devices too, and the first answer, from anywhere, withdraws the
// notification (an update with the same topic / collapse id). It also tells a finished task of
// the person's own agents and an agent's answer when nobody watches that conversation (pure
// rules: `pushFor` in @redgiant/protocol). Nothing here decides a request: a quick answer from a
// notification goes through `HumanApprovals.decide` like any other, and only where the rules
// allow it (never a quick yes for a truly dangerous request).
//
// The VAPID key pair is the installation's, made once and kept in the keychain (G36.20); with the
// keychain locked nothing is sent by Web Push. Contents are never logged.

import type { SqlClient } from "@redgiant/events";
import {
  type Event,
  type PermissionRequestInfo,
  type PushChannelView,
  type PushNotice,
  type PushRegisterBody,
  type PushTrigger,
  pushFor,
  pushTest,
  pushWithdrawal,
  type QuestionRequestInfo,
} from "@redgiant/protocol";
import type { DeviceStore } from "../devices.js";
import type { Vault } from "../vault.js";
import { newVapidPrivate, type VapidKeys, validKeys, vapidKeys } from "./ece.js";
import { type Fetch, type SendResult, sendViaRelay, sendWebPush } from "./send.js";

export const VAPID_KEY = "push:vapid";

export async function migratePush(db: SqlClient): Promise<void> {
  await db.query(`
    CREATE TABLE IF NOT EXISTS rg_app_push (
      device_id     text PRIMARY KEY,
      owner_id      text NOT NULL,
      kind          text NOT NULL,
      target        text NOT NULL,
      p256dh        text NOT NULL,
      auth          text NOT NULL,
      environment   text,
      registered_at timestamptz NOT NULL DEFAULT now(),
      last_sent_at  timestamptz,
      last_error    text
    )`);
}

type Row = {
  device_id: string;
  owner_id: string;
  kind: "webpush" | "apns";
  target: string;
  p256dh: string;
  auth: string;
  environment: string | null;
  registered_at: Date | string;
  last_sent_at: Date | string | null;
  last_error: string | null;
};

/** What the service needs of the core (the tests give the real one). */
export interface PushHost {
  approvals: {
    on(e: "request", f: (owner: string, info: PermissionRequestInfo) => void): unknown;
    on(
      e: "closed",
      f: (owner: string, id: string, d: "allow" | "deny", via: string | undefined) => void,
    ): unknown;
  };
  questions: {
    on(e: "request", f: (owner: string, info: QuestionRequestInfo) => void): unknown;
    on(e: "closed", f: (owner: string, id: string, via: string | undefined) => void): unknown;
  };
  store: { subscribe(f: (e: Event) => void): () => void };
  tasks: {
    get(id: string):
      | {
          title: string;
          from?: { agentId: string; sessionId: string };
          closing?: Promise<void>;
          escalation?: unknown;
        }
      | undefined;
  };
  registry: { get(id: string): { name: string; parentId: string | null } | undefined };
  language(ownerId: string): string;
  machineName(ownerId: string): Promise<string>;
  /** A page or an app follows this conversation now. */
  isWatched(sessionId: string): boolean;
  onTurnEnded(
    f: (t: {
      ownerId: string;
      sessionId: string;
      agentId: string;
      byPerson: boolean;
      stopReason: string;
    }) => void,
  ): () => void;
}

export interface PushOptions {
  db: SqlClient;
  devices: DeviceStore;
  vault: Pick<Vault, "ready" | "systemValue" | "setSystem">;
  /** The blind relay for APNs (G40.4): empty or absent = switched off. */
  relayUrl?: string | undefined;
  /** VAPID's `sub` (RFC 8292): who runs this server, for the push service's operator. */
  subject?: string;
  fetch?: Fetch;
  timeoutMs?: number;
  retryDelayMs?: number;
  now?: () => number;
}

const iso = (d: Date | string) => new Date(d).toISOString();

export class PushService {
  private readonly vapidCache = new Map<string, VapidKeys>();
  /** The agent's last words in each conversation, for its notification when the turn ends. */
  private readonly lastWords = new Map<string, string>();
  /** Notifications being sent: tests and shutdown wait for them. */
  private readonly inFlight = new Set<Promise<unknown>>();

  constructor(private readonly o: PushOptions) {
    // A revoked device's channel goes with it.
    o.devices.on("revoked", (ownerId, ids) => {
      void this.o.db
        .query("DELETE FROM rg_app_push WHERE owner_id = $1 AND device_id = ANY($2::text[])", [
          ownerId,
          ids,
        ])
        .catch(() => {});
    });
  }

  private now() {
    return this.o.now?.() ?? Date.now();
  }

  /** APNs works only through the relay, which stays off until the app is published. */
  get relayOn(): boolean {
    return Boolean(this.o.relayUrl?.trim());
  }

  /** The installation's VAPID keys, made the first time (null while the keychain is locked). */
  async vapid(ownerId: string): Promise<VapidKeys | null> {
    const cached = this.vapidCache.get(ownerId);
    if (cached) return cached;
    if (!this.o.vault.ready) return null;
    let d = this.o.vault.systemValue(ownerId, VAPID_KEY);
    if (!d) {
      d = newVapidPrivate();
      await this.o.vault.setSystem(ownerId, VAPID_KEY, d, {
        name: "push-vapid",
        service: "Web Push (VAPID)",
        category: "other",
        // Never sent anywhere: it signs the notifications' tokens inside the server.
        hosts: [],
        inject: { header: "", format: "{value}" },
        section: "devices",
        kind: "other",
        what: "signing key of the notifications to the devices",
      });
    }
    const keys = vapidKeys(d);
    this.vapidCache.set(ownerId, keys);
    return keys;
  }

  // --- Channels ---------------------------------------------------------------------------

  /** Registers (or replaces) where a device's notifications go. */
  async register(ownerId: string, deviceId: string, b: PushRegisterBody): Promise<PushChannelView> {
    if (!validKeys(b.keys)) throw new PushError("The device's keys are not valid", "bad_keys");
    const [own] = await this.o.db.query<{ id: string }>(
      "SELECT id FROM rg_app_devices WHERE id = $1 AND owner_id = $2 AND revoked_at IS NULL",
      [deviceId, ownerId],
    );
    if (!own) throw new PushError("No such device", "not_found");
    // The installation's VAPID key exists from the first registration (a locked keychain only
    // delays it: the channel shows «keychain locked» until it opens).
    if (b.kind === "webpush") await this.vapid(ownerId).catch(() => null);
    const target = b.kind === "webpush" ? b.endpoint : b.token.toLowerCase();
    const env = b.kind === "apns" ? (b.environment ?? "production") : null;
    const [r] = await this.o.db.query<Row>(
      `INSERT INTO rg_app_push (device_id, owner_id, kind, target, p256dh, auth, environment, registered_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       ON CONFLICT (device_id) DO UPDATE SET kind = EXCLUDED.kind, target = EXCLUDED.target,
         p256dh = EXCLUDED.p256dh, auth = EXCLUDED.auth, environment = EXCLUDED.environment,
         registered_at = EXCLUDED.registered_at, last_sent_at = NULL, last_error = NULL
       WHERE rg_app_push.owner_id = EXCLUDED.owner_id
       RETURNING *`,
      [
        deviceId,
        ownerId,
        b.kind,
        target,
        b.keys.p256dh,
        b.keys.auth,
        env,
        new Date(this.now()).toISOString(),
      ],
    );
    if (!r) throw new PushError("No such device", "not_found");
    return this.view(r);
  }

  async unregister(ownerId: string, deviceId: string): Promise<boolean> {
    const rows = await this.o.db.query<{ device_id: string }>(
      "DELETE FROM rg_app_push WHERE owner_id = $1 AND device_id = $2 RETURNING device_id",
      [ownerId, deviceId],
    );
    return rows.length > 0;
  }

  private view(r: Row): PushChannelView {
    const blocked =
      r.kind === "apns" && !this.relayOn
        ? ("relay_off" as const)
        : r.kind === "webpush" && !this.o.vault.ready && !this.vapidCache.has(r.owner_id)
          ? ("keychain_locked" as const)
          : undefined;
    return {
      kind: r.kind,
      registeredAt: iso(r.registered_at),
      target: r.kind === "webpush" ? hostOf(r.target) : "APNs",
      lastSentAt: r.last_sent_at ? iso(r.last_sent_at) : null,
      lastError: r.last_error,
      ...(blocked && { blocked }),
    };
  }

  /** Each device's channel, for Settings › Devices. */
  async views(ownerId: string): Promise<Map<string, PushChannelView>> {
    const rows = await this.channels(ownerId);
    return new Map(rows.map((r) => [r.device_id, this.view(r)]));
  }

  private channels(ownerId: string, deviceId?: string): Promise<Row[]> {
    return this.o.db.query<Row>(
      `SELECT p.* FROM rg_app_push p JOIN rg_app_devices d ON d.id = p.device_id
       WHERE p.owner_id = $1 AND d.revoked_at IS NULL${deviceId ? " AND p.device_id = $2" : ""}
       ORDER BY p.registered_at, p.device_id`,
      deviceId ? [ownerId, deviceId] : [ownerId],
    );
  }

  // --- Sending ----------------------------------------------------------------------------

  private async sendOne(r: Row, notice: PushNotice): Promise<SendResult> {
    const keys = { p256dh: r.p256dh, auth: r.auth };
    const o = {
      ...(this.o.fetch && { fetch: this.o.fetch }),
      ...(this.o.timeoutMs !== undefined && { timeoutMs: this.o.timeoutMs }),
      ...(this.o.retryDelayMs !== undefined && { retryDelayMs: this.o.retryDelayMs }),
    };
    let result: SendResult;
    if (r.kind === "apns") {
      if (!this.relayOn) return { ok: false, gone: false, error: "APNs relay switched off" };
      result = await sendViaRelay(
        this.o.relayUrl as string,
        {
          token: r.target,
          keys,
          environment: r.environment === "sandbox" ? "sandbox" : "production",
        },
        notice,
        o,
      );
    } else {
      const vapid = await this.vapid(r.owner_id).catch(() => null);
      if (!vapid) return { ok: false, gone: false, error: "keychain locked" };
      result = await sendWebPush(
        { endpoint: r.target, keys },
        notice,
        { keys: vapid, subject: this.o.subject ?? "mailto:redgiant@localhost" },
        o,
      );
    }
    if (result.ok)
      await this.o.db
        .query(
          "UPDATE rg_app_push SET last_sent_at = $2::timestamptz, last_error = NULL WHERE device_id = $1",
          [r.device_id, new Date(this.now()).toISOString()],
        )
        .catch(() => {});
    else if (result.gone)
      // The subscription is gone for good (404/410): the device registers again when it can.
      await this.o.db
        .query("DELETE FROM rg_app_push WHERE device_id = $1", [r.device_id])
        .catch(() => {});
    else
      await this.o.db
        .query("UPDATE rg_app_push SET last_error = $2 WHERE device_id = $1", [
          r.device_id,
          result.error,
        ])
        .catch(() => {});
    return result;
  }

  /** Sends a notice to every device of the owner with a channel (each on its own). */
  send(ownerId: string, notice: PushNotice): Promise<void> {
    const p = (async () => {
      const rows = await this.channels(ownerId);
      await Promise.allSettled(rows.map((r) => this.sendOne(r, notice)));
    })().catch(() => {});
    this.inFlight.add(p);
    void p.finally(() => this.inFlight.delete(p));
    return p;
  }

  /** «Send a test» (Settings › Devices): to that device only, with what happened. */
  async test(ownerId: string, deviceId: string): Promise<SendResult | null> {
    const [r] = await this.channels(ownerId, deviceId);
    if (!r) return null;
    const server = await this.machine(ownerId);
    return this.sendOne(
      r,
      pushTest(this.lang(ownerId), server, new Date(this.now()).toISOString()),
    );
  }

  /** Resolves when every notification being sent is done (tests, shutdown). */
  async idle(): Promise<void> {
    while (this.inFlight.size > 0) await Promise.allSettled([...this.inFlight]);
  }

  // --- What is notified -------------------------------------------------------------------

  private host: PushHost | undefined;
  private lang(ownerId: string) {
    return this.host?.language(ownerId) ?? "en";
  }
  private machine(ownerId: string) {
    return this.host?.machineName(ownerId).catch(() => "RedGiant") ?? Promise.resolve("RedGiant");
  }

  private async notify(ownerId: string, t: PushTrigger): Promise<void> {
    const notice = pushFor(t, this.lang(ownerId), await this.machine(ownerId));
    if (notice) await this.send(ownerId, notice);
  }

  private async withdraw(ownerId: string, requestId: string, via: string | undefined) {
    await this.send(
      ownerId,
      pushWithdrawal(requestId, via, this.lang(ownerId), await this.machine(ownerId)),
    );
  }

  private track(p: Promise<unknown>): void {
    const q = p.catch(() => {});
    this.inFlight.add(q);
    void q.finally(() => this.inFlight.delete(q));
  }

  /**
   * An automation's message for the person that no page or app showed (`notify.to: [web]`,
   * G42.9): it reaches the devices as a notification, as the page's bell would show it.
   */
  automationNotice(
    ownerId: string,
    text: string,
    info: {
      automationId: string;
      runId: string;
      name: string;
      status: string;
      sessionId: string | null;
    },
  ): void {
    this.track(this.notify(ownerId, { type: "automation", ...info, text }));
  }

  /** Listens to the core: requests, questions, tasks and answers nobody watches. */
  attach(h: PushHost): void {
    this.host = h;
    const run = (p: Promise<unknown>) => this.track(p);
    h.approvals.on("request", (owner, info) => run(this.notify(owner, { type: "approval", info })));
    h.approvals.on("closed", (owner, id, _d, via) => run(this.withdraw(owner, id, via)));
    h.questions.on("request", (owner, info) => run(this.notify(owner, { type: "question", info })));
    h.questions.on("closed", (owner, id, via) => run(this.withdraw(owner, id, via)));
    h.store.subscribe((e) => {
      if (e.type === "message.assistant" && e.payload && e.sessionId) {
        const text = e.payload.parts.flatMap((p) => (p.type === "text" ? [p.text] : [])).join("");
        if (text.trim()) this.lastWords.set(e.sessionId, text);
      } else if (e.type === "task.closed" && e.payload) {
        const task = h.tasks.get(e.payload.taskId);
        if (!task) return;
        const outcome = e.payload.outcome;
        run(
          (async () => {
            // Given up: it may be handed to the backup model, whose own end is told instead.
            await task.closing?.catch(() => {});
            const from = task.from && h.registry.get(task.from.agentId);
            await this.notify(e.ownerId, {
              type: "task",
              taskId: e.payload.taskId,
              title: task.title,
              outcome,
              sessionId: task.from?.sessionId,
              forPerson: Boolean(from && from.parentId === null),
              escalated: Boolean(task.escalation),
            });
          })(),
        );
      }
    });
    h.onTurnEnded((t) => {
      const text = this.lastWords.get(t.sessionId) ?? "";
      this.lastWords.delete(t.sessionId);
      if (!t.byPerson) return;
      run(
        this.notify(t.ownerId, {
          type: "message",
          sessionId: t.sessionId,
          agentName: h.registry.get(t.agentId)?.name ?? "RedGiant",
          text,
          byPerson: t.byPerson,
          watched: h.isWatched(t.sessionId),
          stopReason: t.stopReason,
        }),
      );
    });
  }
}

export class PushError extends Error {
  constructor(
    message: string,
    readonly code: "bad_keys" | "not_found",
  ) {
    super(message);
  }
}

function hostOf(endpoint: string): string {
  try {
    return new URL(endpoint).host;
  } catch {
    return "?";
  }
}
