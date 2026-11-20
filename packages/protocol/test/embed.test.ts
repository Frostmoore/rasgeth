// The page inside RGCompanion (G42.0): the fragment as a table (parameters → fragment → back),
// the token never in a query, unknown or wrong values refused, and the bridge's envelope.
import { describe, expect, it } from "vitest";
import {
  AppToEmbed,
  EMBED_ASK_ACTION,
  EMBED_KEYS,
  EMBED_TIMELINE_KEYS,
  type EmbedParams,
  EmbedToApp,
  embedEnvelope,
  embedHash,
  formEncode,
  isEmbedHash,
  parseEmbedHash,
  readAppMessage,
  readEmbedEnvelope,
} from "../src/index.js";

const NONCE = "n0nce-n0nce_n0nce";
const base = { token: "rgd_abc123", bridge: NONCE, theme: "dark", lang: "it" } as const;

const good: [string, EmbedParams, string][] = [
  [
    "a file in the Canvas, at a line",
    { ...base, embed: "canvas", scope: "p1", path: "src/a b.ts", line: 12, session: "s1" },
    "token=rgd_abc123&embed=canvas&bridge=n0nce-n0nce_n0nce&scope=p1&path=src%2Fa+b.ts&line=12&session=s1&theme=dark&lang=it",
  ],
  [
    "a PDF at a page, light, in English",
    {
      ...base,
      theme: "light",
      lang: "en",
      embed: "canvas",
      scope: "outside",
      path: "Doc/è.pdf",
      page: 3,
    },
    "token=rgd_abc123&embed=canvas&bridge=n0nce-n0nce_n0nce&scope=outside&path=Doc%2F%C3%A8.pdf&page=3&theme=light&lang=en",
  ],
  [
    "an agent's port",
    { ...base, embed: "port", agent: "a-1", port: 5173, path: "/app?x=1" },
    "token=rgd_abc123&embed=port&bridge=n0nce-n0nce_n0nce&path=%2Fapp%3Fx%3D1&agent=a-1&port=5173&theme=dark&lang=it",
  ],
  [
    "a board",
    { ...base, embed: "board", board: "s_1.0123456789ab" },
    "token=rgd_abc123&embed=board&bridge=n0nce-n0nce_n0nce&board=s_1.0123456789ab&theme=dark&lang=it",
  ],
  [
    "one variant of a board, at a phone's width (G42.2)",
    { ...base, embed: "board", board: "s_1.0123456789ab", variant: 2, screen: "phone" },
    "token=rgd_abc123&embed=board&bridge=n0nce-n0nce_n0nce&board=s_1.0123456789ab&variant=2&screen=phone&theme=dark&lang=it",
  ],
  [
    "the test page with the app's font",
    { ...base, embed: "probe", font: "Inter, sans-serif" },
    "token=rgd_abc123&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it&font=Inter%2C+sans-serif",
  ],
];

describe("the embed's fragment", () => {
  it.each(good)("%s: written in order and read back", (_name, params, hash) => {
    expect(embedHash(params)).toBe(hash);
    expect(parseEmbedHash(hash)).toEqual(params);
    expect(parseEmbedHash(`#${hash}`)).toEqual(params);
    expect(isEmbedHash(`#${hash}`)).toBe(true);
  });

  it("is a fragment: a link built from it has no query, so the token never reaches the server", () => {
    const [, params] = good[0] ?? [];
    const u = new URL(`https://rg.local:7443/#${embedHash(params as EmbedParams)}`);
    expect(u.search).toBe("");
    expect(u.pathname).toBe("/");
    expect(u.hash).toContain("token=");
  });

  const bad: [string, string][] = [
    ["not an embed", "token=x&open=settings"],
    ["an unknown kind", "token=x&embed=shell&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it"],
    ["an unknown key", `${good[3]?.[2]}&extra=1`],
    ["a key twice", `${good[3]?.[2]}&theme=light`],
    ["no token", "embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it"],
    ["a short nonce", "token=x&embed=probe&bridge=short&theme=dark&lang=it"],
    ["an unknown theme", "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=blue&lang=it"],
    ["an unknown language", "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=de"],
    [
      "a canvas without a path",
      "token=x&embed=canvas&bridge=n0nce-n0nce_n0nce&scope=p&theme=dark&lang=it",
    ],
    [
      "a port without its number",
      "token=x&embed=port&bridge=n0nce-n0nce_n0nce&agent=a&theme=dark&lang=it",
    ],
    [
      "a port out of range",
      "token=x&embed=port&bridge=n0nce-n0nce_n0nce&agent=a&port=70000&theme=dark&lang=it",
    ],
    [
      "a line that is not a number",
      "token=x&embed=canvas&bridge=n0nce-n0nce_n0nce&scope=p&path=a&line=-1&theme=dark&lang=it",
    ],
    [
      "a board link of another shape",
      "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.xyz&theme=dark&lang=it",
    ],
    [
      "a file on the test page",
      "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&scope=p&theme=dark&lang=it",
    ],
    [
      "a font that would break the style",
      "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it&font=a%7Bb",
    ],
    [
      "a variant out of a board's range",
      "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&variant=9&theme=dark&lang=it",
    ],
    [
      "a variant of no board",
      "token=x&embed=probe&bridge=n0nce-n0nce_n0nce&variant=1&theme=dark&lang=it",
    ],
    [
      "a screen without its variant",
      "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&screen=phone&theme=dark&lang=it",
    ],
    [
      "an unknown screen",
      "token=x&embed=board&bridge=n0nce-n0nce_n0nce&board=s.0123456789ab&variant=1&screen=tv&theme=dark&lang=it",
    ],
    ["a token with a space", "token=a+b&embed=probe&bridge=n0nce-n0nce_n0nce&theme=dark&lang=it"],
  ];
  it.each(bad)("refuses %s", (_name, hash) => {
    expect(parseEmbedHash(hash)).toBeNull();
  });

  it("encodes as URLSearchParams does", () => {
    for (const s of ["a b/c?d=e&f", "è~!'()*-._", "日本", "+%"])
      expect(formEncode(s)).toBe(new URLSearchParams({ x: s }).toString().slice(2));
  });
});

describe("the bridge", () => {
  it("takes the page's messages only with the nonce, and only well formed", () => {
    const m = {
      t: "askAgent",
      text: "why this?",
      ref: { scope: "p", path: "a.ts", line: 3, lineEnd: 5 },
    } as const;
    const raw = embedEnvelope(NONCE, m);
    expect(readEmbedEnvelope(raw, NONCE)).toEqual(m);
    expect(readEmbedEnvelope(raw, "another-nonce-123")).toBeNull();
    expect(readEmbedEnvelope("not json", NONCE)).toBeNull();
    expect(
      readEmbedEnvelope(JSON.stringify({ rg: "embed", n: NONCE, m: { t: "shell" } }), NONCE),
    ).toBeNull();
  });

  const pageGood: EmbedToApp[] = [
    { t: "ready" },
    { t: "title", name: "a.xlsx", kind: "sheet", size: 2048 },
    { t: "saveState", state: "error", error: "disk full" },
    { t: "saveAs", name: "a.pdf", url: "/api/files/raw?x=1" },
    { t: "saveAs", name: "a.txt", data: "aGVsbG8=", mime: "text/plain" },
    { t: "openFile", id: "f1", accept: [".png"], multiple: true },
    { t: "copy", text: "x" },
    { t: "share", url: "https://example.com/a" },
    { t: "external", url: "https://example.com" },
    { t: "previewLink", url: "https://example.com/a?b=1" },
    { t: "close" },
    { t: "back", handled: false },
    {
      t: "bar",
      actions: [
        { id: "art.app", label: "App", icon: "play", on: true },
        { id: "art.run", label: "Esegui", primary: true, hint: "Mai eseguito" },
      ],
      note: "L'agente è andato a pagina 3",
      link: "/api/canvas/raw/abc?v=1",
      download: true,
    },
    { t: "bar", actions: [] },
    { t: "open", title: "a.odt", target: { kind: "file", scope: "p1", path: "a.odt" } },
    { t: "open", title: "Sito", target: { kind: "port", agentId: "a1", port: 5173 } },
  ];
  it.each(pageGood.map((m) => [m.t, m]))("page → app %s", (_t, m) => {
    expect(EmbedToApp.safeParse(m).success).toBe(true);
  });

  const pageBad: [string, unknown][] = [
    ["saveAs with both", { t: "saveAs", name: "a", url: "/x", data: "AA==" }],
    ["saveAs with neither", { t: "saveAs", name: "a" }],
    ["saveAs to another origin", { t: "saveAs", name: "a", url: "//evil.example/x" }],
    ["share with nothing", { t: "share", title: "x" }],
    ["an external javascript: link", { t: "external", url: "javascript:alert(1)" }],
    ["a preview's link to a file", { t: "previewLink", url: "file:///etc/passwd" }],
    ["an empty question", { t: "askAgent", text: "", ref: {} }],
    ["an extra field", { t: "ready", x: 1 }],
    [
      "an action with an id of other characters",
      { t: "bar", actions: [{ id: "A b", label: "x" }] },
    ],
    ["an action with no words", { t: "bar", actions: [{ id: "a", label: "" }] }],
    [
      "an icon the app does not draw",
      { t: "bar", actions: [{ id: "a", label: "x", icon: "bomb" }] },
    ],
    [
      "too many actions",
      { t: "bar", actions: Array.from({ length: 13 }, (_, i) => ({ id: `a${i}`, label: "x" })) },
    ],
    ["a bar's link to another origin", { t: "bar", actions: [], link: "https://evil.example/x" }],
    ["an open with no target", { t: "open", title: "x" }],
    ["an open of something else", { t: "open", title: "x", target: { kind: "shell" } }],
  ];
  it.each(pageBad)("page → app refuses %s", (_n, m) => {
    expect(EmbedToApp.safeParse(m).success).toBe(false);
  });

  it("app → page: only `{ rg: 'app', m }` with a known message", () => {
    expect(readAppMessage({ rg: "app", m: { t: "key", key: "save" } })).toEqual({
      t: "key",
      key: "save",
    });
    expect(readAppMessage({ rg: "app", m: { t: "key", key: "quit" } })).toBeNull();
    expect(readAppMessage({ rg: "embed", m: { t: "back" } })).toBeNull();
    expect(readAppMessage("back")).toBeNull();
    const file = { name: "a.png", type: "image/png", size: 3, data: "AAAA" };
    expect(AppToEmbed.safeParse({ t: "files", id: "f1", files: [file] }).success).toBe(true);
    expect(AppToEmbed.safeParse({ t: "files", files: Array(21).fill(file) }).success).toBe(false);
    expect(AppToEmbed.safeParse({ t: "font", family: "x;}" }).success).toBe(false);
  });

  it("app → page: the bar's actions and the app's Canvas tabs (G42.6)", () => {
    expect(AppToEmbed.safeParse({ t: "action", id: "art.source" }).success).toBe(true);
    expect(AppToEmbed.safeParse({ t: "action", id: "" }).success).toBe(false);
    expect(AppToEmbed.safeParse({ t: "action", id: "x", more: 1 }).success).toBe(false);
    const tab = {
      title: "a.pdf",
      target: { kind: "file", scope: "p1", path: "a.pdf" },
      active: true,
    };
    expect(AppToEmbed.safeParse({ t: "tabs", visible: true, tabs: [tab] }).success).toBe(true);
    expect(AppToEmbed.safeParse({ t: "tabs", visible: false, tabs: [] }).success).toBe(true);
    expect(AppToEmbed.safeParse({ t: "tabs", tabs: [tab] }).success).toBe(false);
    expect(
      AppToEmbed.safeParse({ t: "tabs", visible: true, tabs: Array(51).fill(tab) }).success,
    ).toBe(false);
    expect(
      AppToEmbed.safeParse({ t: "tabs", visible: true, tabs: [{ ...tab, active: "yes" }] }).success,
    ).toBe(false);
  });

  it("the editors' messages (G42.7): saveState, askAgent, paste, saveAs, the bar's paste and read only", () => {
    const ok = (m: unknown) => EmbedToApp.safeParse(m).success;
    expect(ok({ t: "saveState", state: "saved" })).toBe(true);
    expect(ok({ t: "saveState", state: "saving" })).toBe(true);
    expect(ok({ t: "saveState", state: "error", error: "x".repeat(500) })).toBe(true);
    expect(ok({ t: "saveState", state: "error", error: "x".repeat(501) })).toBe(false);
    expect(ok({ t: "saveState", state: "unsaved" })).toBe(false);
    expect(ok({ t: "saveState" })).toBe(false);
    expect(ok({ t: "askAgent", text: "why?", ref: { scope: "p", path: "a.ts", line: 3 } })).toBe(
      true,
    );
    expect(ok({ t: "askAgent", text: "x".repeat(20_001), ref: {} })).toBe(false);
    expect(ok({ t: "askAgent", text: "x", ref: { line: -1 } })).toBe(false);
    expect(ok({ t: "askAgent", text: "x", ref: { file: "a" } })).toBe(false);
    expect(ok({ t: "saveAs", name: "a.png", data: "iVBORw0KGgo=", mime: "image/png" })).toBe(true);
    expect(ok({ t: "saveAs", name: "a.png", data: "not base64!" })).toBe(false);
    expect(ok({ t: "saveAs", name: "x".repeat(256), url: "/x" })).toBe(false);
    expect(
      ok({ t: "bar", actions: [{ id: EMBED_ASK_ACTION, label: "Chiedi", icon: "chat" }] }),
    ).toBe(true);
    expect(ok({ t: "bar", actions: [], paste: true, readOnly: true })).toBe(true);
    expect(ok({ t: "bar", actions: [], paste: "yes" })).toBe(false);
    expect(ok({ t: "bar", actions: [], readOnly: 1 })).toBe(false);
    const app = (m: unknown) => AppToEmbed.safeParse(m).success;
    const file = { name: "a.png", type: "image/png", size: 3, data: "AAAA" };
    expect(app({ t: "paste", files: [file] })).toBe(true);
    expect(app({ t: "paste", text: "hi", files: [] })).toBe(true);
    expect(app({ t: "paste", files: [{ ...file, size: 25 * 1024 * 1024 + 1 }] })).toBe(false);
    expect(app({ t: "paste", files: [{ ...file, data: "%%" }] })).toBe(false);
    expect(app({ t: "paste", image: "AAAA" })).toBe(false);
    expect(app({ t: "action", id: EMBED_ASK_ACTION })).toBe(true);
  });

  it("the video timeline's (G42.18): its keys, a file from the app's tree, a render to follow", () => {
    const app = (m: unknown) => AppToEmbed.safeParse(m).success;
    for (const key of EMBED_TIMELINE_KEYS) expect(app({ t: "key", key })).toBe(true);
    expect(EMBED_TIMELINE_KEYS.every((k) => EMBED_KEYS.includes(k))).toBe(true);
    expect(app({ t: "key", key: "j" })).toBe(false);
    expect(app({ t: "drop", scope: "project:p1", path: "girato/a b.mp4", x: 412.5, y: 0 })).toBe(
      true,
    );
    expect(app({ t: "drop", scope: "p", path: "a.mp4", x: -1, y: 0 })).toBe(false);
    expect(app({ t: "drop", scope: "p", path: "", x: 0, y: 0 })).toBe(false);
    expect(app({ t: "drop", scope: "p", path: "a.mp4", x: 0 })).toBe(false);
    expect(app({ t: "drop", scope: "p", path: "a.mp4", x: 0, y: 0, files: [] })).toBe(false);
    const ok = (m: unknown) => EmbedToApp.safeParse(m).success;
    expect(ok({ t: "job", id: "6f1c2d3e-0a1b-4c5d-8e9f-0123456789ab", title: "Video" })).toBe(true);
    expect(ok({ t: "job", id: "a/b", title: "x" })).toBe(false);
    expect(ok({ t: "job", id: "a", title: "" })).toBe(false);
    expect(ok({ t: "job", id: "a", title: "x".repeat(201) })).toBe(false);
    expect(ok({ t: "job", id: "a", title: "x", progress: 3 })).toBe(false);
  });
});
