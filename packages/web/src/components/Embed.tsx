// The page inside RGCompanion (G42.0): one thing only, with no bar, tab or menu of the page (the
// frame around it is the app's). Signed in with the device's token from the fragment, kept in
// memory only; theme, language and font are the app's and are not saved. Its own live connection,
// so collaboration, the agent's marks, proposals and `canvas.query`/`canvas.act` work as in the page.
import type { Accent, AppToEmbed, EmbedParams } from "@redgiant/protocol";
import { lazy, Suspense } from "preact/compat";
import { useEffect, useState } from "preact/hooks";
import { handleAppInput, installEmbedWays, onApp, toApp } from "../embed.js";
import { lang, t } from "../i18n.js";
import { previewLink } from "../preview-links.js";
import { activeSide, type CanvasTarget, canvasViewId, sideViews, signIn } from "../state.js";
import { theme } from "../theme.js";
import { tabOpened } from "../viewers/live.js";
import { asking, Dialogs } from "./dialogs.js";
import { shortcutsOpen } from "./Shortcuts.js";

// Each content comes only when asked for: the test page does not carry the editors.
const Canvas = lazy(() => import("./Canvas.js").then((m) => ({ default: m.Canvas })));
const Variants = lazy(() => import("./Variants.js").then((m) => ({ default: m.Variants })));
const VariantPreview = lazy(() =>
  import("./Variants.js").then((m) => ({ default: m.VariantPreview })),
);
const fileName = (path: string) => path.split(/[\\/]/).filter(Boolean).pop() ?? path;
const EmbedProbe = lazy(() => import("./EmbedProbe.js").then((m) => ({ default: m.EmbedProbe })));

let previewListeners = 0;
const onPreviewLink = (e: MessageEvent) => {
  const url = previewLink(e, document.querySelectorAll("iframe"));
  if (url) toApp({ t: "previewLink", url: url.href });
};

/**
 * Links an agent-made page inside wants to open (3.5.8, `preview-links.ts`): in an embed they go to
 * the app, which asks the person natively (G42.2). Only from our own `/preview/` frames, as in the
 * page. Returns how to stop.
 */
export function listenEmbedPreviewLinks(): () => void {
  // One listener for the window, however many ask: the person is never asked twice for a link.
  if (previewListeners++ === 0) window.addEventListener("message", onPreviewLink);
  let done = false;
  return () => {
    if (done) return;
    done = true;
    if (--previewListeners === 0) window.removeEventListener("message", onPreviewLink);
  };
}

/**
 * The app's look, applied without touching the page's own choices (`rg.theme`, `rg.lang`,
 * `rg.accent`).
 */
export function applyEmbedLook(o: {
  theme?: "light" | "dark";
  lang?: "it" | "en";
  font?: string;
  accent?: Accent;
}) {
  if (o.theme) {
    document.documentElement.dataset.theme = o.theme;
    // The page's own signal too (never saved): the sheet editor and others follow it (G42.8).
    theme.value = o.theme;
  }
  if (o.lang) {
    lang.value = o.lang;
    document.documentElement.lang = o.lang;
  }
  if (o.font) document.body.style.fontFamily = o.font;
  // The app's accent (3.10.4), never saved: red is `:root`'s own.
  if (o.accent) {
    if (o.accent === "red") delete document.documentElement.dataset.accent;
    else document.documentElement.dataset.accent = o.accent;
  }
}

/**
 * The app's «back»: the page closes its own things first (a question, the shortcuts, the whole
 * screen), then says whether it did; when it did not, the app goes back itself.
 */
export function embedBack(): boolean {
  const a = asking.value[0];
  if (a) {
    asking.value = asking.value.slice(1);
    if (a.kind === "confirm") a.done(false);
    else a.done(null);
    return true;
  }
  if (shortcutsOpen.value) {
    shortcutsOpen.value = false;
    return true;
  }
  if (document.fullscreenElement) {
    void document.exitFullscreen?.().catch(() => {});
    return true;
  }
  return false;
}

/** What the embed shows, from its parameters. */
export function embedTarget(p: EmbedParams): CanvasTarget | undefined {
  if (p.embed === "canvas" && p.scope && p.path) {
    const at =
      p.line !== undefined || p.page !== undefined ? { line: p.line, page: p.page } : undefined;
    return { kind: "file", scope: p.scope, path: p.path, ...(at && { at }) };
  }
  if (p.embed === "port" && p.agent && p.port !== undefined)
    return { kind: "port", agentId: p.agent, port: p.port, ...(p.path && { path: p.path }) };
  return undefined;
}

/**
 * The embed's one tab (G42.6): the page's Canvas holds it as its only side view, so what works
 * on a tab of the page works here (an open copy shown in its original's tab, an agent's move,
 * `canvas.query`). Returns its id.
 */
export function embedTab(title: string, target: CanvasTarget): string {
  const id = canvasViewId(target);
  if (!sideViews.value.some((v) => v.id === id)) tabOpened(id);
  sideViews.value = [{ id, type: "canvas", title, target }];
  activeSide.value = id;
  return id;
}

/** Mounted once its lazy siblings are: the content is drawn, the app takes its indicator away. */
function Ready() {
  useEffect(() => {
    const id = requestAnimationFrame(() => toApp({ t: "ready" }));
    return () => cancelAnimationFrame(id);
  }, []);
  return null;
}

export function EmbedRoot({ params }: { params: EmbedParams }) {
  const [state, setState] = useState<"wait" | "ok" | "error">("wait");
  useEffect(() => {
    applyEmbedLook(params);
    const undo = installEmbedWays();
    const unlisten = listenEmbedPreviewLinks();
    const off = onApp((m: AppToEmbed) => {
      if (m.t === "theme") applyEmbedLook({ theme: m.theme });
      else if (m.t === "lang") applyEmbedLook({ lang: m.lang });
      else if (m.t === "font") applyEmbedLook({ font: m.family });
      else if (m.t === "accent") applyEmbedLook({ accent: m.accent });
      else if (m.t === "back") toApp({ t: "back", handled: embedBack() });
      else handleAppInput(m);
    });
    void signIn(params.token, { keep: false }).then(
      () => setState("ok"),
      () => setState("error"),
    );
    return () => {
      off();
      undo();
      unlisten();
    };
  }, []);
  const asked = embedTarget(params);
  const [tabId] = useState(() =>
    asked
      ? embedTab(
          asked.kind === "file"
            ? fileName(asked.path)
            : t("embedPort", { port: String(asked.port) }),
          asked,
        )
      : undefined,
  );
  // What the tab shows now (an original's open copy replaces it in the same tab, p3.5.12).
  const view = sideViews.value.find((v) => v.id === tabId);
  const target = view?.type === "canvas" ? view.target : asked;
  const name =
    target?.kind === "file"
      ? (view?.title ?? fileName(target.path))
      : target?.kind === "port"
        ? t("embedPort", { port: String(target.port) })
        : params.embed === "board"
          ? params.variant
            ? `${t("boardTab")} · ${params.variant}`
            : t("boardTab")
          : t("embedProbeTitle");
  useEffect(() => {
    if (state === "ok") toApp({ t: "title", name });
  }, [state]);
  const [session, proposal] = params.board?.split(".") ?? [];
  const content =
    state === "error" ? (
      <p class="notice error embed-error" role="alert">
        {t("embedSignInFailed")}
      </p>
    ) : target ? (
      <Canvas
        bare
        title={name}
        target={target}
        onShown={(s) => toApp({ t: "title", name, kind: s.kind, size: s.size })}
      />
    ) : session && proposal && params.variant ? (
      <VariantPreview
        sessionId={session}
        proposalId={proposal}
        variant={params.variant}
        screen={params.screen ?? "computer"}
      />
    ) : session && proposal ? (
      <Variants sessionId={session} proposalId={proposal} />
    ) : (
      <EmbedProbe />
    );
  return (
    <div class="embed-root" data-embed={params.embed}>
      {state === "wait" ? (
        <div class="empty" />
      ) : (
        <Suspense fallback={<div class="empty" />}>
          {content}
          <Ready />
        </Suspense>
      )}
      <Dialogs />
    </div>
  );
}
