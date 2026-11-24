// A Telegram bot for the secretary (3.12.4): the person makes it with @BotFather and others write
// to it. Updates come by webhook with Telegram's secret header; answers go through `sendMessage`.
import { timingSafeEqual } from "node:crypto";
import { type Fetch, GraphError } from "./whatsapp.js";

export const TELEGRAM_ROOT = "https://api.telegram.org";

export interface TgInbound {
  handle: string;
  name: string | null;
  externalId: string;
  text: string;
  media: boolean;
  at: Date;
}

export function validSecret(secret: string, header: string | undefined): boolean {
  const a = Buffer.from(secret);
  const b = Buffer.from(header ?? "");
  return a.length === b.length && timingSafeEqual(a, b);
}

interface TgUpdate {
  update_id?: number;
  message?: {
    message_id?: number;
    date?: number;
    text?: string;
    chat?: {
      id?: number;
      type?: string;
      first_name?: string;
      last_name?: string;
      username?: string;
    };
  };
}

/** Only private chats: a bot added to a group is not a customer's conversation. */
export function parseUpdate(raw: unknown): TgInbound | undefined {
  const u = raw as TgUpdate;
  const m = u?.message;
  if (!m?.chat?.id || m.chat.type !== "private") return undefined;
  const name =
    [m.chat.first_name, m.chat.last_name].filter(Boolean).join(" ") || m.chat.username || null;
  return {
    handle: String(m.chat.id),
    name,
    externalId: `${u.update_id ?? ""}:${m.message_id ?? ""}`,
    text: m.text ?? "",
    media: !m.text,
    at: m.date ? new Date(m.date * 1000) : new Date(),
  };
}

async function api<T>(
  f: Fetch,
  token: string,
  method: string,
  body: Record<string, unknown> | undefined,
  root: string,
): Promise<T> {
  let res: Response;
  try {
    res = await f(`${root}/bot${token}/${method}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body ?? {}),
    });
  } catch {
    throw new GraphError("Telegram cannot be reached", 0);
  }
  const out = (await res.json().catch(() => ({}))) as {
    ok?: boolean;
    result?: T;
    description?: string;
    error_code?: number;
  };
  if (!res.ok || !out.ok)
    throw new GraphError(
      out.description ?? `Telegram answered ${res.status}`,
      res.status,
      out.error_code,
    );
  return out.result as T;
}

/** The guide's test call: the token is a real bot's. */
export async function getMe(f: Fetch, token: string, root = TELEGRAM_ROOT) {
  const r = await api<{ id: number; username?: string; first_name?: string }>(
    f,
    token,
    "getMe",
    undefined,
    root,
  );
  return { id: r.id, username: r.username ?? "", name: r.first_name ?? "" };
}

export async function setWebhook(
  f: Fetch,
  token: string,
  url: string,
  secret: string,
  root = TELEGRAM_ROOT,
): Promise<void> {
  await api(
    f,
    token,
    "setWebhook",
    { url, secret_token: secret, allowed_updates: ["message"], drop_pending_updates: false },
    root,
  );
}

export async function deleteWebhook(f: Fetch, token: string, root = TELEGRAM_ROOT): Promise<void> {
  await api(f, token, "deleteWebhook", {}, root);
}

export async function sendMessage(
  f: Fetch,
  token: string,
  chatId: string,
  text: string,
  root = TELEGRAM_ROOT,
): Promise<string> {
  const r = await api<{ message_id: number }>(
    f,
    token,
    "sendMessage",
    { chat_id: chatId, text: text.slice(0, 4000) },
    root,
  );
  return String(r.message_id);
}
