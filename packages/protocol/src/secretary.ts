// The message secretary (3.12.4, decision «Il segretario risponde alle persone»): the agent answers
// OTHER people (customers, contacts) on a WhatsApp Business number or a Telegram bot connected to
// it. Each contact has its own conversation; what the agent may not answer goes to the person with
// a summary and a ready reply. These shapes are shared by the server, the page and the app.
import { z } from "zod";

export const SECRETARY_CHANNELS = ["whatsapp", "telegram"] as const;
export const SecretaryChannel = z.enum(SECRETARY_CHANNELS);
export type SecretaryChannel = z.infer<typeof SecretaryChannel>;

/** What the person types in the guide to connect a WhatsApp Business number (Meta Cloud API). */
export const WhatsAppBusinessInput = z.object({
  name: z.string().trim().max(80).default(""),
  agentId: z.string().min(1).max(100).optional(),
  phoneNumberId: z
    .string()
    .trim()
    .regex(/^\d{5,25}$/, "digits only"),
  token: z.string().trim().min(20).max(1000),
  appSecret: z.string().trim().min(8).max(200),
  /** The approved message template that reopens a conversation outside the 24-hour window. */
  template: z
    .object({ name: z.string().trim().min(1).max(100), language: z.string().trim().min(2).max(10) })
    .optional(),
});
export type WhatsAppBusinessInput = z.infer<typeof WhatsAppBusinessInput>;

/** What the person types in the guide to connect a Telegram bot (made with @BotFather). */
export const TelegramBotInput = z.object({
  name: z.string().trim().max(80).default(""),
  agentId: z.string().min(1).max(100).optional(),
  token: z
    .string()
    .trim()
    .regex(/^\d+:[\w-]{20,}$/, "the token BotFather gave you"),
});
export type TelegramBotInput = z.infer<typeof TelegramBotInput>;

export interface SecretaryAccountView {
  id: string;
  channel: SecretaryChannel;
  name: string;
  /** The agent that answers on it (its connection `chat` has `secretary:<id>` as reference). */
  agentId: string | null;
  /** The handle shown to the person: the bot's @name or the WhatsApp number's id. */
  label: string;
  /** Where the platform posts the messages; null while there is no way in from outside. */
  webhookUrl: string | null;
  /** Meta's check token, shown once in the guide (Telegram: none). */
  verifyToken: string | null;
  /** The platform confirmed the webhook (WhatsApp: Meta's handshake; Telegram: setWebhook). */
  webhookOk: boolean;
  /** The guide was finished: keys kept, the account answers. */
  complete: boolean;
  /** Per-contact limit of automatic answers an hour. */
  limitPerHour: number;
  createdAt: string;
}

export interface SecretaryContactView {
  id: string;
  accountId: string;
  channel: SecretaryChannel;
  /** The number (WhatsApp) or the chat id (Telegram). */
  handle: string;
  name: string;
  notes: string;
  /** The agent no longer answers this contact; the person does. */
  paused: boolean;
  /** The contact said the stop word: no automatic answer until they write «start». */
  stopped: boolean;
  unread: number;
  lastAt: string | null;
  lastText: string;
  /** WhatsApp: the 24-hour window is open (free text allowed). Telegram: always true. */
  windowOpen: boolean;
  pending: number;
}

export interface SecretaryMessageView {
  id: number;
  dir: "in" | "out";
  /** Who wrote an outgoing message. */
  by: "contact" | "agent" | "person";
  text: string;
  at: string;
}

export const PENDING_REASONS = [
  "unknown",
  "commitment",
  "price",
  "file",
  "limit",
  "other",
] as const;
export type PendingReason = (typeof PENDING_REASONS)[number];

export interface SecretaryPendingView {
  id: string;
  contactId: string;
  contactName: string;
  channel: SecretaryChannel;
  reason: PendingReason;
  /** What the contact wants, in a line or two. */
  summary: string;
  /** The ready reply: the person sends it as it is, edits it or refuses. */
  draft: string;
  status: "open" | "sent" | "refused";
  createdAt: string;
}

/** One step of the guide, with its result once checked. */
export interface GuideStepView {
  id: string;
  state: "todo" | "ok" | "error";
  /** A short code the page and the app say in their own words. */
  code: string;
  detail?: string | undefined;
}

/** The stop words in every language the product speaks (a contact says one to be left alone). */
export const STOP_WORDS = [
  "stop",
  "basta",
  "annulla",
  "unsubscribe",
  "arret",
  "para",
  "ende",
] as const;
export const START_WORDS = ["start", "riprendi", "riprendere", "reprendre", "empezar"] as const;

/** The WhatsApp customer-service window: free text only within 24 hours of the contact's message. */
export const WHATSAPP_WINDOW_MS = 24 * 60 * 60 * 1000;

/** What a guide step's check answers (`ok`, or why not as a short code the page words itself). */
export interface SecretaryCheck {
  ok: boolean;
  code: string;
  detail?: string;
  /** WhatsApp: the number and the business name the token reached. */
  number?: string;
  verifiedName?: string;
  /** Telegram: the bot's @name. */
  username?: string;
}
