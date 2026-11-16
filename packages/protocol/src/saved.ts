// Saved passages (G40.14, 3.8.1): a part of a message (or a whole one) the person keeps in a
// personal archive, with where it comes from (conversation, agent, message, date), an optional
// note and optional tags. Each item belongs to one owner; the server fills in the origin from
// the conversation itself, never from what the client says.
//   GET    /api/saved?q=&tag=&agentId=&before=&limit=   newest first, with the filters' facets
//   POST   /api/saved           SavedCreateBody          201 SavedItem
//   GET    /api/saved/:id                                 SavedItem
//   PATCH  /api/saved/:id       SavedUpdateBody          SavedItem (note and tags)
//   DELETE /api/saved/:id                                 { ok: true }
//   GET    /api/saved/export?q=&tag=&agentId=&lang=it|en  text/markdown (every match, up to 2000)
import { z } from "zod";

export const SAVED_TEXT_MAX = 20_000;
export const SAVED_MARKDOWN_MAX = 40_000;
export const SAVED_NOTE_MAX = 4_000;
export const SAVED_TAG_MAX = 40;
export const SAVED_TAGS_MAX = 12;
export const SAVED_PAGE_MAX = 200;

/** A tag as the person typed it: trimmed, without control characters, at most 40 characters. */
export const SavedTag = z
  .string()
  .trim()
  .min(1)
  .max(SAVED_TAG_MAX)
  .refine(
    (s) => [...s].every((ch) => ch.charCodeAt(0) >= 32 && ch.charCodeAt(0) !== 127),
    "no control characters",
  );

/**
 * Tags as they are kept: trimmed, a leading `#` dropped, the same tag once (whatever its case,
 * the first spelling wins), empty ones out, at most `SAVED_TAGS_MAX`.
 */
export function normalizeTags(tags: readonly string[]): string[] {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const raw of tags) {
    const tag = raw.trim().replace(/^#+/, "").trim().slice(0, SAVED_TAG_MAX);
    const key = tag.toLocaleLowerCase();
    if (!tag || seen.has(key)) continue;
    seen.add(key);
    out.push(tag);
    if (out.length >= SAVED_TAGS_MAX) break;
  }
  return out;
}

/**
 * Where a saved passage is, as the client points at it: an agent's conversation and the model's
 * message (its event's `seq`, with the place of the selection in the message's text), or a chat
 * of the older daily chat and its message's id.
 */
export const SavedSourceRef = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("session"),
    sessionId: z.string().min(1).max(200),
    seq: z.number().int().nonnegative(),
    start: z.number().int().nonnegative().optional(),
    end: z.number().int().nonnegative().optional(),
  }),
  z.object({
    kind: z.literal("chat"),
    chatId: z.string().min(1).max(200),
    messageId: z.number().int().nonnegative(),
  }),
]);
export type SavedSourceRef = z.infer<typeof SavedSourceRef>;

/** The origin as the server found it, kept with the item (it stays when the conversation goes). */
export const SavedSource = z.discriminatedUnion("kind", [
  z.object({
    kind: z.literal("session"),
    sessionId: z.string(),
    seq: z.number().int(),
    start: z.number().int().optional(),
    end: z.number().int().optional(),
    agentId: z.string().nullable(),
    agentName: z.string().nullable(),
    /** The conversation's title when it was saved. */
    title: z.string().nullable(),
    /** When the message was written. */
    messageAt: z.string().nullable(),
  }),
  z.object({
    kind: z.literal("chat"),
    chatId: z.string(),
    messageId: z.number().int(),
    agentId: z.string().nullable(),
    agentName: z.string().nullable(),
    title: z.string().nullable(),
    messageAt: z.string().nullable(),
  }),
]);
export type SavedSource = z.infer<typeof SavedSource>;

/**
 * `POST /api/saved`. Without `text` the whole message is saved (its text and its Markdown, read
 * by the server); with it, the selected part, and `markdown` when the client could rebuild it.
 */
export const SavedCreateBody = z.object({
  source: SavedSourceRef,
  text: z.string().trim().min(1).max(SAVED_TEXT_MAX).optional(),
  markdown: z.string().trim().min(1).max(SAVED_MARKDOWN_MAX).optional(),
  note: z.string().max(SAVED_NOTE_MAX).optional(),
  tags: z
    .array(SavedTag)
    .max(SAVED_TAGS_MAX * 2)
    .optional(),
});
export type SavedCreateBody = z.infer<typeof SavedCreateBody>;

/** `PATCH /api/saved/:id`: the note and the tags (the passage itself never changes). */
export const SavedUpdateBody = z
  .object({
    note: z.string().max(SAVED_NOTE_MAX).optional(),
    tags: z
      .array(SavedTag)
      .max(SAVED_TAGS_MAX * 2)
      .optional(),
  })
  .refine((b) => b.note !== undefined || b.tags !== undefined, "note or tags");
export type SavedUpdateBody = z.infer<typeof SavedUpdateBody>;

export const SavedItem = z.object({
  id: z.string(),
  text: z.string(),
  /** The passage's Markdown, when known (always for a whole message). */
  markdown: z.string().nullable(),
  /** The whole message, not a part of it. */
  whole: z.boolean(),
  note: z.string(),
  tags: z.array(z.string()),
  source: SavedSource,
  createdAt: z.string(),
  updatedAt: z.string(),
});
export type SavedItem = z.infer<typeof SavedItem>;

/** `GET /api/saved` filters. `before`: the `createdAt` of the last item of the previous page. */
export const SavedQuery = z.object({
  q: z.string().trim().max(200).optional(),
  tag: z.string().trim().max(SAVED_TAG_MAX).optional(),
  agentId: z.string().max(200).optional(),
  before: z.string().datetime().optional(),
  limit: z.coerce.number().int().min(1).max(SAVED_PAGE_MAX).optional(),
});
export type SavedQuery = z.infer<typeof SavedQuery>;

/** `GET /api/saved`: a page, and every tag and agent of the owner's items (for the filters). */
export const SavedList = z.object({
  items: z.array(SavedItem),
  /** There are older items than this page's last. */
  more: z.boolean(),
  tags: z.array(z.object({ tag: z.string(), count: z.number().int() })),
  agents: z.array(z.object({ id: z.string(), name: z.string(), count: z.number().int() })),
});
export type SavedList = z.infer<typeof SavedList>;

const EXPORT_WORDS = {
  it: { title: "Salvati", from: "Da", note: "Nota", tags: "Etichette", saved: "salvato il" },
  en: { title: "Saved", from: "From", note: "Note", tags: "Tags", saved: "saved on" },
} as const;

/**
 * The archive as one Markdown file (the page's «Esporta», the server's `/api/saved/export`): each
 * item under a heading with its origin, the passage (its Markdown when known), note and tags.
 */
export function savedMarkdown(items: readonly SavedItem[], lang: "it" | "en" = "en"): string {
  const w = EXPORT_WORDS[lang];
  const day = (iso: string | null) => (iso ? iso.slice(0, 10) : "");
  const out = [`# ${w.title}`, ""];
  for (const it of items) {
    const s = it.source;
    const head = [s.title, s.agentName].filter(Boolean).join(" · ") || s.agentId || "";
    out.push(`## ${head || w.title} — ${day(s.messageAt ?? it.createdAt)}`, "");
    out.push(`_${w.from}: ${head || "?"}; ${w.saved} ${day(it.createdAt)}_`, "");
    out.push((it.markdown ?? it.text).trim(), "");
    if (it.note.trim()) out.push(`**${w.note}:** ${it.note.trim()}`, "");
    if (it.tags.length) out.push(`**${w.tags}:** ${it.tags.map((t) => `#${t}`).join(" ")}`, "");
    out.push("---", "");
  }
  return `${out.join("\n").trimEnd()}\n`;
}
