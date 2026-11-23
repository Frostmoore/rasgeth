// God's conversations by topic (3.12): the person writes to God in one place; every topic is one
// of God's sessions with its own stable prefix; a routing step picks the topic (rules first, then a
// light model, then God himself) and the choice is an event in the log. Shapes for the routes and
// the page, the payloads of the topic events, and the pure rules (tested as tables).
import { z } from "zod";
import { MAX_QUOTES, MessageQuote } from "./chat-tools.js";
import { ImagePart } from "./messages.js";

// ---- events' payloads ------------------------------------------------------------------------

/** Who opened a topic. */
export const TopicOpenedBy = z.enum(["router", "person", "migration", "assistant", "god"]);
export type TopicOpenedBy = z.infer<typeof TopicOpenedBy>;

/** Where a message to God was written. */
export const TopicOrigin = z.enum([
  /** Inside an open topic (page, app, phone). */
  "topic",
  /** «Oggi»'s composer (one box for God). */
  "today",
  /** A chat through Demi-God (Telegram and the gateway's). */
  "chat",
  /** An assistant's ask_god. */
  "assistant",
  /** God's own messages (reminders, the day's summaries). */
  "god",
]);
export type TopicOrigin = z.infer<typeof TopicOrigin>;

/**
 * How a message reached its topic. here: written inside it; reply: it answers one of its
 * messages; person: chosen by hand (chip, «New topic», «Move»); rule: a rule (short reply, one
 * recent topic, a project's topic); router: the light model; fallback: no fast model, the most
 * likely topic by the rules (God may still move it); god: God moved it with route_message.
 */
export const TopicVia = z.enum(["here", "reply", "person", "rule", "router", "fallback", "god"]);
export type TopicVia = z.infer<typeof TopicVia>;

export const TopicOpenedPayload = z.object({
  title: z.string().min(1).max(120),
  by: TopicOpenedBy,
  origin: TopicOrigin.optional(),
  /** The assistant whose request opened it («from Ada» in «Oggi»). */
  from: z.string().max(80).optional(),
});

export const TopicRoutedPayload = z.object({
  via: TopicVia,
  /** A short code: written_here, reply, chosen, new_topic, short_reply, only_recent, project, … */
  reason: z.string().max(200),
  /** The router's confidence (0-1), when it decided. */
  confidence: z.number().min(0).max(1).optional(),
  /** Under 0.6: it went to the most likely topic; the page shows «in: Title · Move» prominently. */
  uncertain: z.boolean().optional(),
  /** The other topics the router weighed (ids). */
  alternatives: z.array(z.string()).max(12).optional(),
  /** The router's model ("provider/model"), when one decided. */
  model: z.string().max(200).optional(),
  origin: TopicOrigin.optional(),
});

export const TopicSummarizedPayload = z.object({
  summary: z.string().min(1).max(300),
  /** The last event the summary covers. */
  throughSeq: z.number().int().nonnegative(),
  /** A better title, proposed only in the first three exchanges. */
  title: z.string().min(1).max(120).optional(),
});

export const TopicArchivedPayload = z.object({
  by: z.enum(["idle", "person", "migration"]),
});

export const TopicRestoredPayload = z.object({
  by: z.enum(["person", "message", "report", "move", "router", "reply"]),
});

export const MessageMovedPayload = z.object({
  /** The person's message moved (its `message.user` event). */
  seq: z.number().int().nonnegative(),
  /** The last event moved with it (God's answer, or everything after with «from here on»). */
  throughSeq: z.number().int().nonnegative(),
  toSessionId: z.string(),
  by: z.enum(["person", "god", "migration"]),
});

export const TaskRedirectedPayload = z.object({
  taskId: z.string(),
  toSessionId: z.string(),
});

// ---- routes' shapes --------------------------------------------------------------------------

/** «ti aspetto» (a request or question waits for the person), «al lavoro», «pronto». */
export const TopicState = z.enum(["waiting", "working", "ready"]);
export type TopicState = z.infer<typeof TopicState>;

/** One topic as «Oggi» lists it (`GET /api/god/topics`). */
/** An agent on a topic's card: who opened it (`from`) or works on one of its tasks (`task`). */
export const TopicAgent = z.object({
  id: z.string(),
  role: z.enum(["from", "task"]),
});
export type TopicAgent = z.infer<typeof TopicAgent>;

export const TopicView = z.object({
  /** The topic's session id (open it like any conversation). */
  id: z.string(),
  title: z.string(),
  /** One line about it, written in the background; null until the first one. */
  summary: z.string().nullable(),
  state: TopicState,
  /** Last activity (ISO). */
  lastAt: z.string().nullable(),
  /** When the person last wrote there (ISO). */
  personAt: z.string().nullable(),
  createdAt: z.string(),
  pinned: z.boolean(),
  archived: z.boolean(),
  /** God's answers and task reports the person has not read yet (`POST …/read` clears them). */
  unread: z.number().int().nonnegative(),
  /** Permission requests and questions waiting for the person, of God or of agents under him. */
  requests: z.number().int().nonnegative(),
  /** Tasks God handed over from here, still open. */
  tasks: z.number().int().nonnegative(),
  projectId: z.string().nullable(),
  /** The assistant whose request opened it («from Ada»), else null. */
  from: z.string().nullable(),
  /**
   * The agents on its card (3.12.1): the assistant that opened it, then the agents of its open
   * tasks, each once; their mascots show small with their live state. Absent from servers before.
   */
  agents: z.array(TopicAgent).optional(),
});
export type TopicView = z.infer<typeof TopicView>;

export const TopicList = z.object({
  topics: z.array(TopicView),
  /** How many topics are archived («Archive (n)»). */
  archived: z.number().int().nonnegative(),
});
export type TopicList = z.infer<typeof TopicList>;

/** `GET /api/god/topics` query: the active ones; `archived=true` the archive (with `q`). */
export const TopicListQuery = z.object({
  archived: z
    .enum(["true", "false"])
    .optional()
    .transform((v) => v === "true"),
  /** Words in the title or summary (the archive's search; Echo searches the messages). */
  q: z.string().max(200).optional(),
});

/** What the router decided for one message (in the answer and in `session.routed`). */
export const TopicRouted = z.object({
  topicId: z.string(),
  title: z.string(),
  via: TopicVia,
  reason: z.string(),
  /** A topic opened for this message. */
  isNew: z.boolean(),
  /** An archived topic taken back for it. */
  restored: z.boolean(),
  /** Unsure: «in: Title · Move» shown prominently. */
  uncertain: z.boolean(),
  confidence: z.number().min(0).max(1).optional(),
});
export type TopicRouted = z.infer<typeof TopicRouted>;

/** `POST /api/god/messages`: a message to God, routed to a topic. */
export const GodMessageRequest = z.object({
  text: z.string().trim().min(1).max(100_000),
  /** Chosen by hand (a topic's chip, or written inside it): no routing. */
  topicId: z.string().optional(),
  /** «New topic»: a topic of its own (optional title, else the router's or the first line). */
  newTopic: z.boolean().optional(),
  title: z.string().trim().min(1).max(60).optional(),
  /** Passages it answers: their topic wins (quotes carry the quoted message's session). */
  quotes: z.array(MessageQuote).max(MAX_QUOTES).optional(),
  /** The session of the message it replies to (a quote from another topic). */
  replyTo: z.string().optional(),
  images: z.array(ImagePart).max(20).optional(),
  clientId: z.string().max(80).optional(),
  secretOk: z.boolean().optional(),
});
export type GodMessageRequest = z.infer<typeof GodMessageRequest>;

export const GodMessageResponse = z.object({
  sessionId: z.string(),
  routed: TopicRouted,
  /** God is answering something else there: it waits its turn. */
  queued: z.boolean().optional(),
});
export type GodMessageResponse = z.infer<typeof GodMessageResponse>;

/** `POST /api/sessions/:id/messages/:seq/move`: «Move» an exchange to another topic. */
export const MoveRequest = z.object({
  /** A topic's id, or "new". */
  to: z.string().min(1),
  /** The new topic's title (with "new"). */
  title: z.string().trim().min(1).max(60).optional(),
  /** Also every later message of the topic («from here on»). */
  fromHere: z.boolean().optional(),
});
export type MoveRequest = z.infer<typeof MoveRequest>;

export const MoveResponse = z.object({
  /** Where it went: God answers there again. */
  sessionId: z.string(),
  seq: z.number().int(),
  throughSeq: z.number().int(),
  routed: TopicRouted,
  /** Tasks whose reports now go to the new topic. */
  tasks: z.array(z.string()),
});
export type MoveResponse = z.infer<typeof MoveResponse>;

/** A request's or question's topic («for: Title»). */
export const TopicRef = z.object({ id: z.string(), title: z.string() });
export type TopicRef = z.infer<typeof TopicRef>;

// ---- rules (pure) ------------------------------------------------------------------------------

/** Days without activity after which a topic goes to the archive by itself. */
export const TOPIC_IDLE_DAYS = 3;
/** Under this the router is unsure. */
export const TOPIC_SURE = 0.6;
/** At most this many active topics go to the router. */
export const ROUTER_TOPICS = 12;
/** A new topic's title, at most. */
export const TOPIC_TITLE_MAX = 60;

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;

const SHORT_WORDS = new Set(
  [
    "si",
    "sì",
    "no",
    "ok",
    "okay",
    "va bene",
    "vabbene",
    "fallo",
    "fai pure",
    "procedi",
    "vai",
    "certo",
    "perfetto",
    "grazie",
    "la prima",
    "la seconda",
    "la terza",
    "il primo",
    "il secondo",
    "yes",
    "yep",
    "sure",
    "do it",
    "go ahead",
    "go on",
    "thanks",
    "the first",
    "the second",
    "the third",
    "first",
    "second",
  ].map((w) => w.normalize("NFC")),
);

/**
 * A short reply («sì», «ok», «fallo», «la seconda», or up to four words): it answers what God
 * last said to the person, wherever that was.
 */
export function isShortReply(text: string): boolean {
  const t = text
    .trim()
    .toLowerCase()
    .normalize("NFC")
    .replace(/[.!?,;:]+$/u, "")
    .trim();
  if (!t) return false;
  if (SHORT_WORDS.has(t)) return true;
  // A question or a request of its own is not a reply, however short.
  if (/[?]/.test(text)) return false;
  return t.split(/\s+/u).length <= 4 && t.length <= 30 && !/\n/.test(t);
}

/** One active topic as the rules see it (times in ms). */
export interface RuleTopic {
  id: string;
  /** Last activity. */
  lastAt: number;
  /** The person last wrote there. */
  personAt?: number | undefined;
  /** God last answered the person there. */
  godAt?: number | undefined;
  projectId?: string | null | undefined;
}

export interface RuleInput {
  text: string;
  now: number;
  /** Written inside this topic (page, app, phone). */
  here?: string | undefined;
  /** Chosen by hand («Oggi»'s chip). */
  chosen?: string | undefined;
  /** «New topic», /nuovo. */
  newTopic?: boolean | undefined;
  /** The topic of the message it replies to or quotes. */
  replyTo?: string | undefined;
  /** God's own message about a project. */
  projectId?: string | undefined;
  /** The active topics. */
  active: readonly RuleTopic[];
}

export type RuleDecision =
  | { to: string; via: "here" | "reply" | "person" | "rule"; reason: string }
  | { to: "new"; via: "person"; reason: "new_topic" };

/**
 * Level 1 of the router (always, free): the cases decided without a model, in order. Undefined:
 * the rules cannot tell (the light model, or the fallback, decides).
 */
export function routeByRules(i: RuleInput): RuleDecision | undefined {
  if (i.here) return { to: i.here, via: "here", reason: "written_here" };
  if (i.newTopic) return { to: "new", via: "person", reason: "new_topic" };
  if (i.chosen) return { to: i.chosen, via: "person", reason: "chosen" };
  if (i.replyTo) return { to: i.replyTo, via: "reply", reason: "reply" };
  const byGod = [...i.active]
    .filter((t) => t.godAt !== undefined)
    .sort((a, b) => (b.godAt ?? 0) - (a.godAt ?? 0))[0];
  if (byGod && isShortReply(i.text)) return { to: byGod.id, via: "rule", reason: "short_reply" };
  if (i.projectId) {
    const there = [...i.active]
      .filter((t) => t.projectId === i.projectId)
      .sort((a, b) => b.lastAt - a.lastAt)[0];
    if (there) return { to: there.id, via: "rule", reason: "project" };
  }
  const [only] = i.active;
  if (i.active.length === 1 && only && i.now - only.lastAt < 10 * MINUTE)
    return { to: only.id, via: "rule", reason: "only_recent" };
  return undefined;
}

/**
 * Level 3 (no fast model, or it failed): the topic the person wrote in during the last two hours,
 * else a new one. God may still move it with route_message.
 */
export function fallbackRoute(
  i: Pick<RuleInput, "active" | "now">,
): { to: string; reason: "recent_person" } | { to: "new"; reason: "nothing_recent" } {
  const recent = [...i.active]
    .filter((t) => t.personAt !== undefined && i.now - t.personAt < 2 * HOUR)
    .sort((a, b) => (b.personAt ?? 0) - (a.personAt ?? 0))[0];
  return recent
    ? { to: recent.id, reason: "recent_person" }
    : { to: "new", reason: "nothing_recent" };
}

/** What the light model answers. */
export const RouterAnswer = z.object({
  topic: z.string().min(1),
  title: z.string().trim().min(1).max(200).optional(),
  confidence: z.number().min(0).max(1),
});
export type RouterAnswer = z.infer<typeof RouterAnswer>;

/**
 * The router's answer read from its text (a JSON object, maybe in a code fence). Undefined when
 * it is not valid or names a topic that is not active: then the fallback decides, never a topic at
 * random.
 */
export function parseRouterAnswer(
  text: string,
  active: readonly string[],
): { to: string; title?: string; confidence: number } | undefined {
  const m = text.match(/\{[\s\S]*\}/);
  if (!m) return undefined;
  let json: unknown;
  try {
    json = JSON.parse(m[0]);
  } catch {
    return undefined;
  }
  const r = RouterAnswer.safeParse(json);
  if (!r.success) return undefined;
  const to = r.data.topic === "new" ? "new" : r.data.topic;
  if (to !== "new" && !active.includes(to)) return undefined;
  const title = r.data.title ? topicTitle(r.data.title) : undefined;
  return { to, confidence: r.data.confidence, ...(title && { title }) };
}

/** A title as kept: one line, at most 60 characters (cut at a word). */
export function topicTitle(text: string): string {
  const line =
    text
      .split("\n")
      .map((l) => l.trim())
      .find(Boolean) ?? "";
  const clean = line
    .replace(/^["'«“]+|["'»”]+$/gu, "")
    .replace(/\s+/gu, " ")
    .trim();
  if (clean.length <= TOPIC_TITLE_MAX) return clean;
  const cut = clean.slice(0, TOPIC_TITLE_MAX);
  const space = cut.lastIndexOf(" ");
  return `${(space > 30 ? cut.slice(0, space) : cut).trimEnd()}…`;
}

/** A topic's state for «Oggi». */
export function topicState(t: {
  running: boolean;
  queued: boolean;
  tasks: number;
  requests: number;
}): TopicState {
  if (t.requests > 0) return "waiting";
  if (t.running || t.queued || t.tasks > 0) return "working";
  return "ready";
}

/**
 * Whether a topic goes to the archive by itself: idle three days (no message of the person, no
 * answer of God), never when pinned, with open tasks or with a request or question waiting.
 */
export function shouldArchive(t: {
  lastAt: number;
  now: number;
  pinned: boolean;
  archived: boolean;
  tasks: number;
  requests: number;
  running: boolean;
  idleDays?: number;
}): boolean {
  if (t.archived || t.pinned || t.tasks > 0 || t.requests > 0 || t.running) return false;
  return t.now - t.lastAt >= (t.idleDays ?? TOPIC_IDLE_DAYS) * 24 * HOUR;
}

/**
 * The one-time split of the old work conversation (3.12.2): the model groups exchanges by work.
 * `exchanges` are the numbers of the lines it was shown.
 */
export const SplitGroup = z.object({
  title: z.string().min(1),
  exchanges: z.array(z.number().int().nonnegative()).min(1),
  summary: z.string().optional(),
});
export type SplitGroup = z.infer<typeof SplitGroup>;
export const SplitAnswer = z.object({ groups: z.array(SplitGroup) });

/** The groups of a model's answer, or undefined when it is not usable JSON. */
export function parseSplitAnswer(text: string): SplitGroup[] | undefined {
  const json = text.match(/\{[\s\S]*\}/u)?.[0];
  if (!json) return undefined;
  try {
    const r = SplitAnswer.safeParse(JSON.parse(json));
    return r.success ? r.data.groups : undefined;
  } catch {
    return undefined;
  }
}
