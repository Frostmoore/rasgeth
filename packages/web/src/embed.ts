// The page inside RGCompanion (G42.0): `#embed=…` in the address (packages/protocol/src/embed.ts).
// The fragment is read once and taken out of the address; the token stays in memory only. The page
// talks to the app through one function, `toApp` (the web view's channel, with the nonce the app
// gave), and hears it through `onApp` (messages the app posts to this window). In an embed some of
// the page's own ways out go to the app instead: the clipboard, downloads, links to other sites.
import {
  type AppToEmbed,
  EMBED_CHANNEL,
  type EmbedAction,
  type EmbedParams,
  type EmbedTab,
  type EmbedToApp,
  embedEnvelope,
  parseEmbedHash,
  readAppMessage,
} from "@redgiant/protocol";

let params: EmbedParams | null = null;

/** The embed this page was opened as (after `takeEmbed`), or null: the page as usual. */
export const embedParams = () => params;
export const embedded = () => params !== null;

/**
 * Reads the embed from the fragment and takes the whole fragment out of the address at once (the
 * token is in it). Null when the fragment is not a valid embed.
 */
export function takeEmbed(): EmbedParams | null {
  const p = parseEmbedHash(location.hash);
  if (location.hash) history.replaceState(history.state, "", location.pathname + location.search);
  params = p;
  return p;
}

/** For tests: forget the embed. */
export function resetEmbed(): void {
  params = null;
  appCanvas = null;
  barSent = "";
  actions.clear();
}

/**
 * The app's Canvas (G42.6, its `tabs` message): its tabs and whether this page is the one in
 * view. Null until the app says: the page then answers for its own tab only.
 */
let appCanvas: { visible: boolean; tabs: EmbedTab[] } | null = null;
export const appCanvasNow = () => appCanvas;
export function setAppCanvas(c: { visible: boolean; tabs: EmbedTab[] } | null): void {
  appCanvas = c;
}

/** What the bar's actions do, by id, as the Canvas set them last. */
const actions = new Map<string, () => void>();
let barSent = "";

/**
 * The Canvas's own buttons, for the app's bar (G42.6): sent when they change, and what each does
 * kept here for the app's `action`.
 */
export function setEmbedBar(
  bar: {
    actions: (EmbedAction & { run: () => void })[];
    note?: string | undefined;
    link?: string | undefined;
    download?: boolean | undefined;
  },
): void {
  actions.clear();
  for (const a of bar.actions) actions.set(a.id, a.run);
  const m: EmbedToApp = {
    t: "bar",
    actions: bar.actions.map(({ run: _run, ...a }) => a),
    ...(bar.note ? { note: bar.note.slice(0, 300) } : {}),
    ...(bar.link ? { link: bar.link } : {}),
    ...(bar.download !== undefined && { download: bar.download }),
  };
  const key = JSON.stringify(m);
  if (key === barSent) return;
  if (toApp(m)) barSent = key;
}

/** The app used one of the bar's actions. */
export function runEmbedAction(id: string): boolean {
  const run = actions.get(id);
  run?.();
  return !!run;
}

type Channel = { postMessage: (s: string) => void };
type HostWindow = Window & {
  [EMBED_CHANNEL]?: Channel;
  chrome?: { webview?: Channel };
};

/** Sends [m] to the app; false when there is no app (a browser) or no embed. */
export function toApp(m: EmbedToApp): boolean {
  const p = params;
  if (!p) return false;
  const w = window as HostWindow;
  const channel = w[EMBED_CHANNEL] ?? w.chrome?.webview;
  if (!channel) return false;
  try {
    channel.postMessage(embedEnvelope(p.bridge, m));
    return true;
  } catch {
    return false;
  }
}

/** Listens to the app (its messages are posted to this very window); returns how to stop. */
export function onApp(f: (m: AppToEmbed) => void): () => void {
  const listen = (e: MessageEvent) => {
    if (e.source !== window || e.origin !== location.origin) return;
    const m = readAppMessage(e.data);
    if (m) f(m);
  };
  window.addEventListener("message", listen);
  return () => window.removeEventListener("message", listen);
}

/** A link the app should open outside: http(s) on another origin. */
export function externalLink(href: string): string | undefined {
  try {
    const u = new URL(href, location.href);
    if (u.protocol !== "http:" && u.protocol !== "https:") return undefined;
    return u.origin === location.origin ? undefined : u.href;
  } catch {
    return undefined;
  }
}

/** «Save as…» through the app: a link of this server goes as its path, anything else as bytes. */
export async function saveThroughApp(url: string, name: string): Promise<boolean> {
  if (!embedded()) return false;
  const u = new URL(url, location.href);
  if (u.origin === location.origin && u.protocol !== "blob:")
    return toApp({ t: "saveAs", name, url: u.pathname + u.search });
  try {
    const bytes = new Uint8Array(await (await fetch(url)).arrayBuffer());
    let bin = "";
    for (let i = 0; i < bytes.length; i += 0x8000)
      bin += String.fromCharCode(...bytes.subarray(i, i + 0x8000));
    return toApp({ t: "saveAs", name, data: btoa(bin) });
  } catch {
    return false;
  }
}

/** The editor's save state, for the app's bar. */
export function reportSave(s: "saving" | "saved" | "unsaved" | "failed" | undefined): void {
  if (s === "saving" || s === "saved") toApp({ t: "saveState", state: s });
  else if (s === "failed") toApp({ t: "saveState", state: "error" });
}

const waitingFiles = new Map<string, (files: File[]) => void>();
let fileSeq = 0;

/** Files from the app's picker (the page's own picker does not open in every web view). */
export function filesFromApp(accept: string[] = [], multiple = false): Promise<File[]> {
  const id = `f${++fileSeq}`;
  return new Promise((done) => {
    if (!toApp({ t: "openFile", id, accept, multiple })) return done([]);
    waitingFiles.set(id, done);
  });
}

const toFile = (f: { name: string; type: string; data: string }) => {
  const bin = atob(f.data);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return new File([bytes], f.name, { type: f.type });
};

/** The page's keys for the app's `key` (Ctrl/Cmd+S, Z, Shift+Z, F). */
const KEYS = {
  save: { key: "s" },
  undo: { key: "z" },
  redo: { key: "z", shiftKey: true },
  find: { key: "f" },
} as const;

/**
 * What the page does with the app's messages that are not the root's (theme, language, font and
 * back are): keys go to what has the focus, files to whoever asked or as a drop on the page.
 */
export function handleAppInput(m: AppToEmbed): boolean {
  if (m.t === "key") {
    const mac = /Mac|iPhone|iPad/.test(navigator.platform);
    const target = document.activeElement ?? document.body;
    target.dispatchEvent(
      new KeyboardEvent("keydown", {
        ...KEYS[m.key],
        ctrlKey: !mac,
        metaKey: mac,
        bubbles: true,
        cancelable: true,
      }),
    );
    return true;
  }
  if (m.t === "files") {
    const files = m.files.map(toFile);
    const wait = m.id ? waitingFiles.get(m.id) : undefined;
    if (m.id && wait) {
      waitingFiles.delete(m.id);
      wait(files);
    } else window.dispatchEvent(new CustomEvent("rg-embed-files", { detail: files }));
    return true;
  }
  if (m.t === "action") return runEmbedAction(m.id);
  if (m.t === "tabs") {
    setAppCanvas({ visible: m.visible, tabs: m.tabs });
    return true;
  }
  if (m.t === "paste") {
    window.dispatchEvent(
      new CustomEvent("rg-embed-paste", {
        detail: { text: m.text, files: (m.files ?? []).map(toFile) },
      }),
    );
    return true;
  }
  return false;
}

/**
 * In an embed the page's ways out go to the app: what the page copies, links to other sites
 * (clicked or opened), and `window.open`. Returns how to undo it (tests).
 */
export function installEmbedWays(): () => void {
  const clip = navigator.clipboard;
  const write = clip?.writeText?.bind(clip);
  if (clip)
    Object.defineProperty(clip, "writeText", {
      configurable: true,
      value: async (text: string) => {
        const sent = toApp({ t: "copy", text });
        try {
          await write?.(text);
        } catch (e) {
          if (!sent) throw e;
        }
      },
    });
  const click = (e: MouseEvent) => {
    const a = (e.target as Element | null)?.closest?.("a[href]") as HTMLAnchorElement | null;
    if (!a || a.hasAttribute("download")) return;
    const url = externalLink(a.href);
    if (!url) return;
    e.preventDefault();
    toApp({ t: "external", url });
  };
  document.addEventListener("click", click, true);
  const open = window.open;
  window.open = ((href?: string | URL, ...rest: unknown[]) => {
    const url = href === undefined ? undefined : externalLink(String(href));
    if (url) {
      toApp({ t: "external", url });
      return null;
    }
    return (open as (...a: unknown[]) => Window | null).call(window, href, ...rest);
  }) as typeof window.open;
  return () => {
    if (clip) Object.defineProperty(clip, "writeText", { configurable: true, value: write });
    document.removeEventListener("click", click, true);
    window.open = open;
  };
}
