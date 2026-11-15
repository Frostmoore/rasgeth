// Sending one notification (G40.4): Web Push to a UnifiedPush endpoint (RFC 8030 + 8291 + 8292),
// or the same sealed content to the blind relay that passes it to APNs. Each try has a time
// limit; a network failure, a 429 or a 5xx is tried once more after a pause, then given up (no
// endless retries). 404 and 410 mean the subscription is gone: the caller deletes the channel.

import { createHash } from "node:crypto";
import type { PushNotice } from "@redgiant/protocol";
import { b64u, encrypt, type SubscriberKeys, type VapidKeys, vapidAuthorization } from "./ece.js";

export type Fetch = typeof fetch;

export interface SendOptions {
  fetch?: Fetch;
  /** One try's limit (default 10 s). */
  timeoutMs?: number;
  /** The pause before the one retry (default 2 s; tests 0). */
  retryDelayMs?: number;
}

export type SendResult =
  | { ok: true; status: number }
  | { ok: false; gone: boolean; error: string; status?: number };

/** A Topic header (RFC 8030 §5.4): 32 base64url characters, the same for one notice's updates. */
export const topicOf = (noticeId: string) =>
  createHash("sha256").update(noticeId).digest("base64url").slice(0, 32);

/** How long the push service keeps it for a device that is offline (seconds). */
const ttlOf = (n: PushNotice) =>
  n.kind === "request" || n.kind === "question" ? 3600 : n.kind === "test" ? 600 : 86_400;

const pause = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function tries(
  o: SendOptions,
  once: (signal: AbortSignal) => Promise<Response>,
): Promise<SendResult> {
  let last: SendResult = { ok: false, gone: false, error: "not sent" };
  for (let attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) await pause(o.retryDelayMs ?? 2000);
    try {
      const r = await once(AbortSignal.timeout(o.timeoutMs ?? 10_000));
      // Only the status matters; the body (if any) is not read into a log.
      await r.body?.cancel().catch(() => {});
      if (r.ok) return { ok: true, status: r.status };
      const gone = r.status === 404 || r.status === 410;
      last = { ok: false, gone, status: r.status, error: `HTTP ${r.status}` };
      if (!(r.status === 429 || r.status >= 500)) return last;
    } catch (err) {
      const e = err as Error;
      last = {
        ok: false,
        gone: false,
        error: e.name === "TimeoutError" ? "timed out" : `network: ${e.message}`.slice(0, 200),
      };
    }
  }
  return last;
}

const bodyOf = (n: PushNotice) => Buffer.from(JSON.stringify(n));

/** Web Push: encrypted for the device's keys, signed with the installation's VAPID key. */
export function sendWebPush(
  channel: { endpoint: string; keys: SubscriberKeys },
  notice: PushNotice,
  vapid: { keys: VapidKeys; subject: string },
  o: SendOptions = {},
): Promise<SendResult> {
  const f = o.fetch ?? fetch;
  const urgent = notice.kind === "request" || notice.kind === "question";
  return tries(o, (signal) => {
    // A fresh encryption per try (a new salt and key every message).
    const body = encrypt(bodyOf(notice), channel.keys);
    return f(channel.endpoint, {
      method: "POST",
      headers: {
        authorization: vapidAuthorization(channel.endpoint, vapid.keys, vapid.subject),
        "content-encoding": "aes128gcm",
        "content-type": "application/octet-stream",
        ttl: String(ttlOf(notice)),
        urgency: urgent && !notice.closed ? "high" : "normal",
        // The update that withdraws a request replaces it if it is still waiting to be delivered.
        topic: topicOf(notice.id),
      },
      body,
      signal,
      redirect: "error",
    });
  });
}

/**
 * The blind relay (switched off until the app is published): it receives only the content
 * sealed for the device and Apple's token, and passes them to APNs with the publisher's key.
 */
export function sendViaRelay(
  relayUrl: string,
  channel: { token: string; keys: SubscriberKeys; environment: "production" | "sandbox" },
  notice: PushNotice,
  o: SendOptions = {},
): Promise<SendResult> {
  const f = o.fetch ?? fetch;
  return tries(o, (signal) =>
    f(new URL("/v1/push", relayUrl), {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        token: channel.token,
        environment: channel.environment,
        sealed: b64u(encrypt(bodyOf(notice), channel.keys)),
        // An update replaces the notification shown (Apple's collapse id).
        collapseId: topicOf(notice.id),
        // The withdrawal of a request replaces it quietly.
        quiet: Boolean(notice.closed),
        ttl: ttlOf(notice),
      }),
      signal,
      redirect: "error",
    }),
  );
}
