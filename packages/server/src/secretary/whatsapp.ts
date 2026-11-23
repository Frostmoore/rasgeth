// WhatsApp Business through Meta's Cloud API, for the secretary (3.12.4): other people write to the
// person's business number. Incoming messages come by webhook (signed with the app secret in
// `X-Hub-Signature-256`); outgoing ones go to `/{phone-number-id}/messages`. Free text is allowed
// only within 24 hours of the contact's last message; after that only an approved template.
import { createHmac, timingSafeEqual } from "node:crypto";

export type Fetch = typeof fetch;

export const GRAPH_ROOT = "https://graph.facebook.com/v21.0";

export interface WaInbound {
  /** The contact's number (WhatsApp id). */
  handle: string;
  name: string | null;
  /** Meta's message id: Meta retries, so the engine drops repeats. */
  externalId: string;
  text: string;
  /** A picture, audio or document came: the secretary never opens them, the person does. */
  media: boolean;
  at: Date;
}

export class GraphError extends Error {
  constructor(
    message: string,
    readonly status: number,
    /** Meta's error code (190: token expired or wrong; 100: wrong id; 131047: window closed). */
    readonly code?: number,
  ) {
    super(message);
  }
}

/** The signature check: false for anything that does not come from Meta with our secret. */
export function validSignature(
  appSecret: string,
  rawBody: string,
  header: string | undefined,
): boolean {
  const expected = Buffer.from(
    `sha256=${createHmac("sha256", appSecret).update(rawBody).digest("hex")}`,
  );
  const got = Buffer.from(header ?? "");
  return got.length === expected.length && timingSafeEqual(got, expected);
}

/** Meta's subscription check: the challenge back only when our verify token was sent. */
export function verifyHandshake(
  verifyToken: string,
  query: Record<string, string | undefined>,
): string | undefined {
  if (query["hub.mode"] !== "subscribe") return undefined;
  const sent = Buffer.from(query["hub.verify_token"] ?? "");
  const ours = Buffer.from(verifyToken);
  if (sent.length !== ours.length || !timingSafeEqual(sent, ours)) return undefined;
  return query["hub.challenge"];
}

interface WaPayload {
  entry?: {
    changes?: {
      value?: {
        metadata?: { phone_number_id?: string };
        contacts?: { wa_id?: string; profile?: { name?: string } }[];
        messages?: {
          from?: string;
          id?: string;
          timestamp?: string;
          type?: string;
          text?: { body?: string };
          button?: { text?: string };
          interactive?: { button_reply?: { title?: string }; list_reply?: { title?: string } };
        }[];
      };
    }[];
  }[];
}

/** The messages in a webhook body (status updates carry none); only for our own number. */
export function parseWebhook(rawBody: string, phoneNumberId: string): WaInbound[] {
  let body: WaPayload;
  try {
    body = JSON.parse(rawBody) as WaPayload;
  } catch {
    return [];
  }
  const out: WaInbound[] = [];
  for (const entry of body.entry ?? [])
    for (const change of entry.changes ?? []) {
      const v = change.value;
      if (!v || (v.metadata?.phone_number_id && v.metadata.phone_number_id !== phoneNumberId))
        continue;
      for (const m of v.messages ?? []) {
        if (!m.from || !m.id) continue;
        const text =
          m.text?.body ??
          m.button?.text ??
          m.interactive?.button_reply?.title ??
          m.interactive?.list_reply?.title ??
          "";
        const ts = Number(m.timestamp);
        out.push({
          handle: m.from,
          name: v.contacts?.find((c) => c.wa_id === m.from)?.profile?.name ?? null,
          externalId: m.id,
          text,
          media: !text,
          at: Number.isFinite(ts) && ts > 0 ? new Date(ts * 1000) : new Date(),
        });
      }
    }
  return out;
}

export interface WaCredentials {
  token: string;
  phoneNumberId: string;
}

async function graph(
  f: Fetch,
  token: string,
  url: string,
  init: RequestInit = {},
): Promise<Record<string, unknown>> {
  let res: Response;
  try {
    res = await f(url, {
      ...init,
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    });
  } catch {
    throw new GraphError("Meta cannot be reached", 0);
  }
  const body = (await res.json().catch(() => ({}))) as {
    error?: { message?: string; code?: number };
  } & Record<string, unknown>;
  if (!res.ok)
    throw new GraphError(
      body.error?.message ?? `Meta answered ${res.status}`,
      res.status,
      body.error?.code,
    );
  return body;
}

/** The guide's test call: the token works and the number id is that of a WhatsApp number. */
export async function checkCredentials(
  f: Fetch,
  c: WaCredentials,
  root = GRAPH_ROOT,
): Promise<{ number: string; verifiedName: string }> {
  const r = await graph(
    f,
    c.token,
    `${root}/${encodeURIComponent(c.phoneNumberId)}?fields=display_phone_number,verified_name`,
  );
  return {
    number: typeof r.display_phone_number === "string" ? r.display_phone_number : c.phoneNumberId,
    verifiedName: typeof r.verified_name === "string" ? r.verified_name : "",
  };
}

/** Free text: only to a number that wrote first and within the window (the engine checks both). */
export async function sendText(
  f: Fetch,
  c: WaCredentials,
  to: string,
  text: string,
  root = GRAPH_ROOT,
): Promise<string | undefined> {
  const r = await graph(f, c.token, `${root}/${encodeURIComponent(c.phoneNumberId)}/messages`, {
    method: "POST",
    body: JSON.stringify({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to,
      type: "text",
      text: { body: text.slice(0, 4000), preview_url: false },
    }),
  });
  return (r.messages as { id?: string }[] | undefined)?.[0]?.id;
}

/** A template with one body variable: the way to write again after the 24 hours. */
export async function sendTemplate(
  f: Fetch,
  c: WaCredentials,
  to: string,
  template: { name: string; language: string },
  variable: string,
  root = GRAPH_ROOT,
): Promise<string | undefined> {
  const r = await graph(f, c.token, `${root}/${encodeURIComponent(c.phoneNumberId)}/messages`, {
    method: "POST",
    body: JSON.stringify({
      messaging_product: "whatsapp",
      recipient_type: "individual",
      to,
      type: "template",
      template: {
        name: template.name,
        language: { code: template.language },
        components: [
          { type: "body", parameters: [{ type: "text", text: variable.slice(0, 1000) }] },
        ],
      },
    }),
  });
  return (r.messages as { id?: string }[] | undefined)?.[0]?.id;
}
