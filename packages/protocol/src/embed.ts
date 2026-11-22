// The page inside RGCompanion (G42.0, plan_g42_parita.md «Come funziona l'embed»): the server's own
// page (`/`) opened by the app in a web view on one thing only (a Canvas file, an agent's port, a
// board of variants, the test page), with everything after `#` and never in the query: a fragment
// never reaches the server nor a log. The device's token is read and taken out of the address at
// once and kept in memory only; theme and language come from the app and are not saved.
//
// The bridge: the page talks to the app through one channel (`EMBED_CHANNEL`, a JavaScript channel
// of the web view; `chrome.webview` on Windows) with an envelope that carries the nonce the app put
// in the fragment (`bridge`), so nothing else in the page (a sandboxed preview inside the Canvas)
// can speak for it. The app answers by posting `{ rg: "app", m }` to the page's own window.
// The app mirrors these rules in Dart (lib/embed/), checked against vectors made from here
// (apps/companion/tool/embed_vectors.mjs).

import { z } from "zod";
import { ACCENTS } from "./accent.js";
import { CanvasTargetSchema } from "./canvas.js";

/** What an embed shows. */
export const EMBED_KINDS = ["canvas", "port", "board", "probe"] as const;
export type EmbedKind = (typeof EMBED_KINDS)[number];

/** The web view's channel to the app (page → app). */
export const EMBED_CHANNEL = "RGEmbed";
/** The most files one message carries (app → page). */
export const EMBED_FILES_MAX = 20;
/** The biggest file one message carries, before base64. */
export const EMBED_FILE_MAX = 25 * 1024 * 1024;

/** The fragment's keys, in the order `embedHash` writes them. */
export const EMBED_HASH_ORDER = [
  "token",
  "embed",
  "bridge",
  "scope",
  "path",
  "line",
  "page",
  "session",
  "agent",
  "port",
  "board",
  "variant",
  "screen",
  "theme",
  "lang",
  "font",
  "accent",
] as const;

/**
 * The real screens a board's variants are scaled down from (as in Officina, G25.4): the page's
 * board and the app's draw a variant at one of these widths.
 */
export const BOARD_SCREENS = {
  computer: { width: 1280, height: 800 },
  tablet: { width: 820, height: 1100 },
  phone: { width: 390, height: 780 },
} as const;
export type BoardScreen = keyof typeof BOARD_SCREENS;
export const BOARD_SCREEN_NAMES = Object.keys(BOARD_SCREENS) as BoardScreen[];
/** The most variants a board has (`publish_board`). */
export const BOARD_VARIANTS_MAX = 8;

const NUMBER = /^\d{1,9}$/;
const count = z.number().int().min(0).max(999_999_999);
const board = /^[\w-]+\.[0-9a-f]{12}$/;

export const EmbedParams = z
  .object({
    token: z.string().min(1).max(1000).regex(/^\S+$/),
    embed: z.enum(EMBED_KINDS),
    /** The bridge's nonce: every message to the app carries it. */
    bridge: z.string().regex(/^[A-Za-z0-9_-]{16,64}$/),
    scope: z.string().min(1).max(200).optional(),
    path: z.string().min(1).max(4000).optional(),
    /** Where to open a file: a text's line, a PDF's page. */
    line: count.optional(),
    page: count.optional(),
    /** The conversation the Canvas belongs to (its errors and «ask the agent» go there). */
    session: z.string().min(1).max(200).optional(),
    agent: z.string().min(1).max(200).optional(),
    port: z.number().int().min(1).max(65535).optional(),
    /** `<sessionId>.<proposalId>`, as a board's link from Telegram. */
    board: z.string().regex(board).optional(),
    /**
     * One variant of the board only (1-based), drawn at a screen's width and scaled to the web
     * view (G42.2): the app draws the board itself and holds each variant in a frame of its own.
     */
    variant: z.number().int().min(1).max(BOARD_VARIANTS_MAX).optional(),
    screen: z.enum(BOARD_SCREEN_NAMES as [BoardScreen, ...BoardScreen[]]).optional(),
    theme: z.enum(["light", "dark"]),
    lang: z.enum(["it", "en"]),
    /** The app's font family, when it is not the system's. */
    font: z
      .string()
      .min(1)
      .max(200)
      .regex(/^[^;{}<>]+$/)
      .optional(),
    /** The accent colour the person chose in the app (3.10.4); none: Rasgeth's red. */
    accent: z.enum(ACCENTS).optional(),
  })
  .strict()
  .superRefine((p, ctx) => {
    const need = (ok: boolean, what: string) => {
      if (!ok) ctx.addIssue({ code: "custom", message: `${p.embed} needs ${what}` });
    };
    if (p.embed === "canvas") need(!!p.scope && !!p.path, "scope and path");
    if (p.embed === "port") need(!!p.agent && p.port !== undefined, "agent and port");
    if (p.embed === "board") need(!!p.board, "board");
    if (p.embed !== "canvas")
      need(p.scope === undefined && p.line === undefined && p.page === undefined, "no file");
    if (p.embed !== "port") need(p.agent === undefined && p.port === undefined, "no port");
    if (p.embed !== "board") need(p.board === undefined, "no board");
    if (p.embed !== "board" || p.variant === undefined)
      need(p.variant === undefined && p.screen === undefined, "no variant");
  });
export type EmbedParams = z.infer<typeof EmbedParams>;

/** `application/x-www-form-urlencoded`, as `URLSearchParams` writes it (the Dart side does the same). */
export function formEncode(s: string): string {
  let out = "";
  for (const b of new TextEncoder().encode(s)) {
    const c = String.fromCharCode(b);
    if (/[A-Za-z0-9*\-._]/.test(c)) out += c;
    else if (b === 0x20) out += "+";
    else out += `%${b.toString(16).toUpperCase().padStart(2, "0")}`;
  }
  return out;
}

/** The fragment (without `#`) for [p]: its keys in `EMBED_HASH_ORDER`, the absent ones left out. */
export function embedHash(p: EmbedParams): string {
  const parsed = EmbedParams.parse(p);
  const values = parsed as Record<string, string | number | undefined>;
  return EMBED_HASH_ORDER.flatMap((k) => {
    const v = values[k];
    return v === undefined ? [] : [`${k}=${formEncode(String(v))}`];
  }).join("&");
}

/**
 * The embed a fragment asks for (with or without `#`), or null: not an embed, a key it does not
 * know, a key twice, a value out of its rules.
 */
export function parseEmbedHash(hash: string): EmbedParams | null {
  const h = new URLSearchParams(hash.startsWith("#") ? hash.slice(1) : hash);
  if (!h.has("embed")) return null;
  const seen = new Set<string>();
  const raw: Record<string, string | number> = {};
  for (const [k, v] of h) {
    if (seen.has(k)) return null;
    seen.add(k);
    if (k === "line" || k === "page" || k === "port" || k === "variant") {
      if (!NUMBER.test(v)) return null;
      raw[k] = Number(v);
    } else raw[k] = v;
  }
  const r = EmbedParams.safeParse(raw);
  return r.success ? r.data : null;
}

/** Whether a page's fragment asks for an embed at all (cheap, before the page picks its root). */
export const isEmbedHash = (hash: string) =>
  new URLSearchParams(hash.startsWith("#") ? hash.slice(1) : hash).has("embed");

// ---------- The bridge ----------

const text = (max: number) => z.string().max(max);
/** Where «ask the agent» points: a file, its lines, a page. */
export const EmbedRef = z
  .object({
    scope: text(200).optional(),
    path: text(4000).optional(),
    line: count.optional(),
    lineEnd: count.optional(),
    page: count.optional(),
  })
  .strict();
export type EmbedRef = z.infer<typeof EmbedRef>;

/** A link inside the server (a signed `/…` path), never another origin. */
const serverPath = z
  .string()
  .max(4000)
  .regex(/^\/(?!\/)/);
const webLink = z
  .string()
  .max(4000)
  .regex(/^https?:\/\/[^\s]+$/i);

/**
 * The drawn icons a Canvas action may carry in the app's bar (G42.6): the app draws its own
 * (`RgIcons`), never a picture the page sends.
 */
export const EMBED_ACTION_ICONS = [
  "play",
  "code",
  "folderPlus",
  "pencil",
  "brush",
  "alert",
  "keyboard",
  /** «Ask the agent» (G42.7). */
  "chat",
] as const;
export type EmbedActionIcon = (typeof EMBED_ACTION_ICONS)[number];

/** An action's id: what the app sends back when the person uses it. */
const actionId = z
  .string()
  .min(1)
  .max(40)
  .regex(/^[a-z][a-z0-9.-]*$/);

/**
 * One of the Canvas's own buttons (G42.6), drawn by the app in its bar instead of the page's head:
 * the artifact's «App»/«Source», «Run», «Make it a project», «Edit a copy», «Edit the picture»,
 * the keyboard map. Its words are the page's, in the page's language.
 */
export const EmbedAction = z
  .object({
    id: actionId,
    label: z.string().min(1).max(80),
    icon: z.enum(EMBED_ACTION_ICONS).optional(),
    /** One of a pair that is lit (the artifact's App or Source). */
    on: z.boolean().optional(),
    disabled: z.boolean().optional(),
    /** The bar's main thing (the artifact's «Run»). */
    primary: z.boolean().optional(),
    hint: text(300).optional(),
  })
  .strict();
export type EmbedAction = z.infer<typeof EmbedAction>;
/** The most actions one bar carries. */
export const EMBED_ACTIONS_MAX = 12;
/**
 * The action «Ask the agent» about what is selected (G42.7): the app shows it only where it has a
 * conversation's composer to put it in, and the page answers its `action` with `askAgent`.
 */
export const EMBED_ASK_ACTION = "ask";

/** One of the app's Canvas tabs, as the page's `canvas.state` names them (G42.6). */
export const EmbedTab = z
  .object({ title: text(300), target: CanvasTargetSchema, active: z.boolean() })
  .strict();
export type EmbedTab = z.infer<typeof EmbedTab>;

/** Page → app. */
export const EmbedToApp = z.discriminatedUnion("t", [
  /** The content is drawn: the app takes its own indicator away. */
  z.object({ t: z.literal("ready") }).strict(),
  /** What the app's bar shows: the name, its kind and weight. */
  z
    .object({
      t: z.literal("title"),
      name: text(300),
      kind: text(40).optional(),
      size: count.optional(),
    })
    .strict(),
  z
    .object({
      t: z.literal("saveState"),
      state: z.enum(["saved", "saving", "error"]),
      error: text(500).optional(),
    })
    .strict(),
  /** «Save as…»: a signed link of the server, or the bytes (base64). */
  z
    .object({
      t: z.literal("saveAs"),
      name: z.string().min(1).max(255),
      url: serverPath.optional(),
      data: z
        .string()
        .max(Math.ceil(EMBED_FILE_MAX / 3) * 4)
        .regex(/^[A-Za-z0-9+/]*={0,2}$/)
        .optional(),
      mime: text(200).optional(),
    })
    .strict()
    .refine((m) => (m.url === undefined) !== (m.data === undefined), "url or data"),
  /** The page wants files: the app picks them and answers `files` with the same id. */
  z
    .object({
      t: z.literal("openFile"),
      id: z.string().min(1).max(64),
      accept: z.array(text(100)).max(20).optional(),
      multiple: z.boolean().optional(),
    })
    .strict(),
  z.object({ t: z.literal("copy"), text: text(1_000_000) }).strict(),
  z
    .object({
      t: z.literal("share"),
      title: text(300).optional(),
      text: text(100_000).optional(),
      url: webLink.optional(),
    })
    .strict()
    .refine((m) => m.text !== undefined || m.url !== undefined, "text or url"),
  /** «Ask the agent»: the selection and where it is, to the app's own conversation. */
  z
    .object({ t: z.literal("askAgent"), text: z.string().min(1).max(20_000), ref: EmbedRef })
    .strict(),
  /** A link to open outside the app. */
  z.object({ t: z.literal("external"), url: webLink }).strict(),
  /**
   * A link an agent-made page inside wants to open (the page's `preview-links.ts`, 3.5.8): the
   * app asks the person, natively, before it opens anywhere (G42.2).
   */
  z.object({ t: z.literal("previewLink"), url: webLink }).strict(),
  z.object({ t: z.literal("close") }).strict(),
  /** The answer to the app's `back`: whether the page closed something of its own. */
  z.object({ t: z.literal("back"), handled: z.boolean() }).strict(),
  /**
   * The Canvas's bar (G42.6), drawn by the app: the tab's own buttons, what the agent just did in
   * it («The agent went to page 3»), the signed link of what is shown (for «Open outside»), and
   * whether it is a file one can download (not a site nor an artifact).
   */
  z
    .object({
      t: z.literal("bar"),
      actions: z.array(EmbedAction).max(EMBED_ACTIONS_MAX),
      note: text(300).optional(),
      link: serverPath.optional(),
      download: z.boolean().optional(),
      /**
       * The tab takes a picture from the system's clipboard (the image editor, G42.7): the app
       * offers «Paste a picture» and passes Ctrl/Cmd+V on as `paste`.
       */
      paste: z.boolean().optional(),
      /** An archived project's file (G42.7): only looked at, the app's bar says so. */
      readOnly: z.boolean().optional(),
    })
    .strict(),
  /** Something to open in another tab of the app's Canvas (an open copy made, a file inside). */
  z.object({ t: z.literal("open"), title: text(300), target: CanvasTargetSchema }).strict(),
  /**
   * A long job the person started in the tab (a video's render, G42.18): the app follows it
   * itself (`GET /api/jobs/:id`) and shows how far it is in the system's notifications, also when
   * the tab is closed. Only the id and the words of its notification: the job's own state comes
   * from the server.
   */
  z
    .object({
      t: z.literal("job"),
      id: z
        .string()
        .min(1)
        .max(64)
        .regex(/^[A-Za-z0-9_-]+$/),
      title: z.string().min(1).max(200),
    })
    .strict(),
]);
export type EmbedToApp = z.infer<typeof EmbedToApp>;

/** A file the app hands the page. */
export const EmbedFile = z
  .object({
    name: z.string().min(1).max(255),
    type: text(200),
    size: z.number().int().min(0).max(EMBED_FILE_MAX),
    data: z
      .string()
      .max(Math.ceil(EMBED_FILE_MAX / 3) * 4)
      .regex(/^[A-Za-z0-9+/]*={0,2}$/),
  })
  .strict();
export type EmbedFile = z.infer<typeof EmbedFile>;

/**
 * The keys the app passes on (Ctrl/Cmd+S, Z, Shift+Z, F) when the web view does not hold them.
 * G42.18: a video timeline's own too, J, K, L (shuttle), I, O (in and out) and Ctrl/Cmd+B (blade),
 * passed on only while a timeline is the tab in view.
 */
export const EMBED_KEYS = [
  "save",
  "undo",
  "redo",
  "find",
  "shuttleBack",
  "pause",
  "shuttleForward",
  "markIn",
  "markOut",
  "blade",
] as const;
export type EmbedKey = (typeof EMBED_KEYS)[number];
/** The keys a video timeline takes (G42.18): the app passes them on only to a timeline. */
export const EMBED_TIMELINE_KEYS: readonly EmbedKey[] = [
  "shuttleBack",
  "pause",
  "shuttleForward",
  "markIn",
  "markOut",
  "blade",
];

/** App → page. */
export const AppToEmbed = z.discriminatedUnion("t", [
  z.object({ t: z.literal("theme"), theme: z.enum(["light", "dark"]) }).strict(),
  z.object({ t: z.literal("lang"), lang: z.enum(["it", "en"]) }).strict(),
  /** The accent colour changed in the app (3.10.4). */
  z.object({ t: z.literal("accent"), accent: z.enum(ACCENTS) }).strict(),
  z
    .object({
      t: z.literal("font"),
      family: z
        .string()
        .min(1)
        .max(200)
        .regex(/^[^;{}<>]+$/),
    })
    .strict(),
  /** The system's back: the page closes its own panel first, then answers `back`. */
  z.object({ t: z.literal("back") }).strict(),
  z.object({ t: z.literal("key"), key: z.enum(EMBED_KEYS) }).strict(),
  /** Files picked (the answer to `openFile`, same id) or dropped on the app (no id). */
  z
    .object({
      t: z.literal("files"),
      id: z.string().min(1).max(64).optional(),
      files: z.array(EmbedFile).max(EMBED_FILES_MAX),
    })
    .strict(),
  z
    .object({
      t: z.literal("paste"),
      text: text(1_000_000).optional(),
      files: z.array(EmbedFile).max(EMBED_FILES_MAX).optional(),
    })
    .strict(),
  /** One of the bar's actions used (its `id`). */
  z.object({ t: z.literal("action"), id: actionId }).strict(),
  /**
   * A file of a project dragged from the app's own file tree and dropped on the page (G42.18), at
   * a point of the page (CSS pixels from its top left): a video timeline places it on the track
   * under that point, as a file dragged from the page's own tree would be.
   */
  z
    .object({
      t: z.literal("drop"),
      scope: z.string().min(1).max(200),
      path: z.string().min(1).max(4000),
      x: z.number().min(0).max(100_000),
      y: z.number().min(0).max(100_000),
    })
    .strict(),
  /**
   * The app's Canvas now (G42.6): its tabs, and whether this page is the one in view. The page
   * answers an agent's `canvas.query` with them, as a tab of the page's own Canvas would.
   */
  z
    .object({ t: z.literal("tabs"), visible: z.boolean(), tabs: z.array(EmbedTab).max(50) })
    .strict(),
]);
export type AppToEmbed = z.infer<typeof AppToEmbed>;

/** What the page sends: `{ rg: "embed", n: nonce, m }` as JSON. */
export function embedEnvelope(nonce: string, m: EmbedToApp): string {
  return JSON.stringify({ rg: "embed", n: nonce, m: EmbedToApp.parse(m) });
}

/** A page's message as the app reads it: null unless it is the page's (its nonce) and well formed. */
export function readEmbedEnvelope(raw: string, nonce: string): EmbedToApp | null {
  let v: unknown;
  try {
    v = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!v || typeof v !== "object") return null;
  const e = v as { rg?: unknown; n?: unknown; m?: unknown };
  if (e.rg !== "embed" || e.n !== nonce) return null;
  const r = EmbedToApp.safeParse(e.m);
  return r.success ? r.data : null;
}

/** An app's message as the page reads it (posted to its own window): null unless well formed. */
export function readAppMessage(data: unknown): AppToEmbed | null {
  if (!data || typeof data !== "object") return null;
  const e = data as { rg?: unknown; m?: unknown };
  if (e.rg !== "app") return null;
  const r = AppToEmbed.safeParse(e.m);
  return r.success ? r.data : null;
}
