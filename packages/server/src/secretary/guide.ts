// The guides that connect a business channel step by step (3.12.4). Each step has a check that
// talks to the platform (injected fetch: tests use fakes, never Meta or Telegram) and answers with
// a short code the page and the app say in their own words. The guide never keeps what it is
// given: the keys go to the keychain only when the person finishes it.
import { getMe, TELEGRAM_ROOT } from "./telegram.js";
import { checkCredentials, type Fetch, GRAPH_ROOT, GraphError } from "./whatsapp.js";

export const WHATSAPP_STEPS = [
  "remote",
  "app",
  "number",
  "token",
  "secret",
  "webhook",
  "subscribe",
  "template",
] as const;
export const TELEGRAM_STEPS = ["botfather", "token", "webhook"] as const;

export interface StepResult {
  ok: boolean;
  /** `ok`, or why not: `no_remote`, `bad_token`, `bad_number`, `no_access`, `unreachable`... */
  code: string;
  detail?: string;
}

/** Remote access (Settings > Remote access) is what lets Meta and Telegram reach this server. */
export function checkRemote(publicUrl: string | undefined): StepResult {
  if (!publicUrl) return { ok: false, code: "no_remote" };
  if (!/^https:\/\//i.test(publicUrl)) return { ok: false, code: "not_https", detail: publicUrl };
  return { ok: true, code: "ok", detail: publicUrl };
}

function fromError(err: unknown): StepResult {
  if (err instanceof GraphError) {
    if (err.status === 0) return { ok: false, code: "unreachable", detail: err.message };
    // Meta: 190 is an expired or wrong token; 100 a wrong id; 10 and 200 a token without access.
    if (err.code === 190 || err.status === 401)
      return { ok: false, code: "bad_token", detail: err.message };
    if (err.code === 100 || err.status === 404)
      return { ok: false, code: "bad_number", detail: err.message };
    if (err.code === 10 || err.code === 200 || err.status === 403)
      return { ok: false, code: "no_access", detail: err.message };
    return { ok: false, code: "failed", detail: err.message };
  }
  return { ok: false, code: "failed", detail: err instanceof Error ? err.message : "failed" };
}

/** Steps «number» and «token»: one test call to the Graph API with the token and the number id. */
export async function checkWhatsAppToken(
  f: Fetch,
  c: { token: string; phoneNumberId: string },
  root = GRAPH_ROOT,
): Promise<StepResult & { number?: string; verifiedName?: string }> {
  try {
    const r = await checkCredentials(f, c, root);
    return { ok: true, code: "ok", number: r.number, verifiedName: r.verifiedName };
  } catch (err) {
    return fromError(err);
  }
}

export async function checkTelegramToken(
  f: Fetch,
  token: string,
  root = TELEGRAM_ROOT,
): Promise<StepResult & { username?: string }> {
  try {
    const me = await getMe(f, token, root);
    return { ok: true, code: "ok", username: me.username };
  } catch (err) {
    const r = fromError(err);
    return r.code === "bad_number" ? { ...r, code: "bad_token" } : r;
  }
}

/** The app secret is the string that signs the webhook: Meta shows 32 hex characters. */
export function checkAppSecret(secret: string): StepResult {
  return /^[0-9a-f]{32}$/i.test(secret.trim())
    ? { ok: true, code: "ok" }
    : { ok: false, code: "bad_secret" };
}
