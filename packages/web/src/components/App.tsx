import { OWN_SERVER_ID, PRODUCT_NAME } from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { usd } from "../format.js";
import { lang, t } from "../i18n.js";
import {
  IconAlert,
  IconArchive,
  IconBell,
  IconBoard,
  IconBookmark,
  IconCanvas,
  IconChat,
  IconClose,
  IconEye,
  IconFolder,
  IconMenu,
  IconSearch,
  IconSettings,
  IconTree,
  IconUser,
  IconUsers,
  IconWifi,
  Logo,
} from "../icons.js";
import {
  activateTab,
  activeChat,
  activeTab,
  agents,
  approvals,
  attempt,
  budgets,
  chatAgentId,
  citationNote,
  closeTab,
  drawerOpen,
  explorerOpen,
  firstRun,
  lastError,
  limits,
  notices,
  openBoard,
  openCanvas,
  openTab,
  platformInfo,
  questions,
  refresh,
  type SettingsSection,
  sessionRows,
  sessionView,
  signIn,
  signOut,
  status,
  type Tab,
  tabs,
  takeFromLink,
  toggleExplorer,
  token,
  uiMode,
} from "../state.js";
import { useSwipeAway } from "../swipe.js";
import { Bell } from "./Bell.js";
import { Chat } from "./Chat.js";
import { DailyChat } from "./DailyChat.js";
import { Downloads } from "./Downloads.js";
import { Dialogs } from "./dialogs.js";
import { EngineLoading } from "./EngineLoading.js";
import { Explorer } from "./Explorer.js";
import { lazy } from "./lazy.js";
import { Mascot } from "./Mascot.js";
import { ConnectionLost, MemoryNotice } from "./PageHealth.js";
import { Bar, PlanBars } from "./PlanBars.js";
import { RenameNotice } from "./RenameNotice.js";
import { SaveDialogHost, SavedPage } from "./Saved.js";
import { preloadCanvas, SideArea } from "./SideArea.js";
import { Sidebar } from "./Sidebar.js";
import { SimpleApp } from "./Simple.js";
import { UpdateGate } from "./UpdateGate.js";
import { VoiceIndicator } from "./VoiceIndicator.js";
import { WhatsNew } from "./WhatsNew.js";

// Pages come when they open, not with the first chat (3.5.11): Settings and its pages, the
// first-run wizard, an assistant's page, the board, the project's agents, rooms, search…
const AssistantPage = lazy<{ agentId: string | null }>(() =>
  import("./Assistants.js").then((m) => m.AssistantPage),
);
const Board = lazy<{ projectId: string | null }>(() => import("./Board.js").then((m) => m.Board));
const Chats = lazy<Record<string, never>>(() => import("./Chats.js").then((m) => m.Chats));
const ProjectAgents = lazy<{ projectId: string }>(() =>
  import("./Hierarchy.js").then((m) => m.ProjectAgents),
);
const ArchivedProjectView = lazy<{ projectId: string }>(() =>
  import("./ProjectArchive.js").then((m) => m.ArchivedProjectView),
);
const RoomView = lazy<{ roomId: string }>(() => import("./Room.js").then((m) => m.RoomView));
const Search = lazy<{ close: () => void }>(() => import("./Search.js").then((m) => m.Search));
const Setup = lazy<{ onDone?: () => void }>(() => import("./Setup.js").then((m) => m.Setup));
const Login = lazy<Record<string, never>>(() => import("./Login.js").then((m) => m.Login));
const CitationNote = lazy<Record<string, never>>(() =>
  import("./Knowledge.js").then((m) => m.CitationNote),
);
const Variants = lazy<{ sessionId: string; proposalId: string }>(() =>
  import("./Variants.js").then((m) => m.Variants),
);
const Settings = lazy<{ section?: SettingsSection | undefined }>(() =>
  import("./Settings.js").then((m) => m.Settings),
);

/**
 * The header's bars follow how the open conversation is connected (G21): a flat subscription shows
 * its plan's windows (5h, 7d, per-model), a local model how full the context is before automatic
 * compaction, anything paid per token the budgets.
 */
function Limits() {
  const chat = activeChat();
  const provider = chat?.model?.provider;
  const plan = limits.value.find((l) => l.provider === provider);
  if (plan) return <PlanBars plan={plan} />;
  if (provider === "local" || provider === OWN_SERVER_ID) {
    const events = chat ? sessionView(chat.sessionId).value.events : [];
    const last = [...events].reverse().find((e) => e.type === "message.assistant");
    const m = last?.type === "message.assistant" ? last.payload?.metrics : undefined;
    const threshold = m ? Math.round(m.contextWindow * 0.8) : 0;
    return (
      <div class="limits">
        <Bar
          name={t("contextLeft")}
          pct={m ? (m.contextUsed / threshold) * 100 : 0}
          title={
            m
              ? t("contextHint", {
                  used: String(m.contextUsed),
                  window: String(m.contextWindow),
                  threshold: String(threshold),
                })
              : t("contextLeft")
          }
        />
      </div>
    );
  }
  return <Budgets />;
}

/** Spending against the limits, like Officina's usage bars; the global budget first. */
function Budgets() {
  const limited = budgets.value.filter(
    (b) => b.limit.usd !== undefined || b.limit.tokens !== undefined,
  );
  const global = budgets.value.find((b) => b.scope === "global");
  if (limited.length === 0)
    return (
      <div class="limits">
        {global && (
          <span class="limit" title={t("budgets")}>
            <span class="limit-name">{t("spent")}</span>
            <span class="limit-num">{usd(global.used.usd)}</span>
          </span>
        )}
      </div>
    );
  return (
    <div class="limits">
      {limited.slice(0, 3).map((b) => {
        const pct =
          b.limit.usd !== undefined
            ? (b.used.usd / b.limit.usd) * 100
            : (b.used.tokens / (b.limit.tokens ?? 1)) * 100;
        const level = pct >= 90 ? "high" : pct >= 70 ? "medium" : "";
        const name =
          b.scope === "global"
            ? t("total")
            : b.scope === "project"
              ? b.id
              : (agents.value.find((a) => a.id === b.id)?.name ?? b.id);
        return (
          <span
            key={`${b.scope}:${b.id}`}
            class={`limit ${level}`}
            title={`${name}: ${usd(b.used.usd)}${b.limit.usd !== undefined ? ` / ${usd(b.limit.usd)}` : ""}`}
          >
            <span class="limit-name">{name}</span>
            <span class="limit-bar">
              <span style={{ width: `${Math.min(100, pct)}%` }} />
            </span>
            <span class="limit-num">{Math.round(pct)}%</span>
          </span>
        );
      })}
    </div>
  );
}

/** The agent a tab talks to (G40.2: its mascot is the tab's icon). */
const tabAgent = (tab: Tab) => {
  const id =
    tab.type === "chat" || tab.type === "assistant"
      ? tab.agentId
      : tab.type === "dailychat"
        ? chatAgentId.value
        : null;
  if (id) return agents.value.find((a) => a.id === id);
  return tab.type === "inspector"
    ? agents.value.find(
        (a) => a.kind === "inspector" && a.projectId === tab.projectId && !a.subprojectId,
      )
    : undefined;
};

const tabIcon = (tab: Tab) =>
  tab.type === "chat" ? null : tab.type === "dailychat" ? (
    <IconChat size={13} />
  ) : tab.type === "board" ? (
    <IconBoard size={13} />
  ) : tab.type === "inspector" ? (
    <IconEye size={13} />
  ) : tab.type === "assistant" ? (
    <IconUser size={13} />
  ) : tab.type === "room" ? (
    <IconUsers size={13} />
  ) : tab.type === "chats" ? (
    <IconChat size={13} />
  ) : tab.type === "saved" ? (
    <IconBookmark size={13} />
  ) : tab.type === "agents" ? (
    <IconTree size={13} />
  ) : tab.type === "tavola" ? (
    <IconCanvas size={13} />
  ) : tab.type === "archived" ? (
    <IconArchive size={13} />
  ) : (
    <IconSettings size={13} />
  );

/** The tabs in the middle: conversations and the other views, each with its own state. */
function Tabs() {
  if (tabs.value.length === 0) return null;
  return (
    <div class="tabs" role="tablist">
      {tabs.value.map((tab) => {
        const agent = tabAgent(tab);
        const running =
          tab.type === "chat" && sessionRows.value.some((r) => r.id === tab.sessionId && r.running);
        const label =
          tab.type === "settings"
            ? t("settings")
            : tab.type === "chat"
              ? (agent?.name ?? "")
              : tab.title;
        const detail = tab.type === "chat" ? tab.title : "";
        return (
          <div key={tab.id} class={`tab ${activeTab.value === tab.id ? "active" : ""}`}>
            <button
              type="button"
              role="tab"
              aria-selected={activeTab.value === tab.id}
              class="tab-label"
              onClick={() => activateTab(tab.id)}
              title={`${label} ${detail}`}
            >
              {/* Its agent's face (G40.2); at this size the state is the dot, as before. */}
              {agent && <Mascot agent={agent} size={20} />}
              {running ? <span class="dot running" /> : !agent && tabIcon(tab)}
              <span class="lp">{label}</span>
              {detail && detail !== label && <span class="lt">{detail}</span>}
            </button>
            <button
              type="button"
              class="icon-button"
              title={t("close")}
              onClick={() => closeTab(tab.id)}
            >
              <IconClose size={13} />
            </button>
          </div>
        );
      })}
    </div>
  );
}

function View({ tab }: { tab: Tab }) {
  switch (tab.type) {
    case "chat":
      return <Chat sessionId={tab.sessionId} agentId={tab.agentId} />;
    case "dailychat":
      return <DailyChat chatId={tab.chatId} tabId={tab.id} />;
    case "board":
      return <Board projectId={tab.projectId} />;
    case "inspector":
      return <DailyChat projectId={tab.projectId} />;
    case "settings":
      return <Settings section={tab.section} />;
    case "assistant":
      return <AssistantPage key={tab.id} agentId={tab.agentId} />;
    case "room":
      return <RoomView key={tab.id} roomId={tab.roomId} />;
    case "chats":
      return <Chats />;
    case "saved":
      return <SavedPage />;
    case "agents":
      return <ProjectAgents key={tab.id} projectId={tab.projectId} />;
    case "tavola":
      return <Variants key={tab.id} sessionId={tab.sessionId} proposalId={tab.proposalId} />;
    case "archived":
      return <ArchivedProjectView key={tab.id} projectId={tab.projectId} />;
  }
}

/** What a link asked to open once signed in (`#open=settings`), used once (G42.0). */
export function takeOpenIntent(): "settings" | undefined {
  const open = sessionStorage.getItem("rg.open");
  sessionStorage.removeItem("rg.open");
  return open === "settings" ? "settings" : undefined;
}

/** The file a link asked to show in the Canvas once signed in (`#open=canvas`, G42.8), once. */
export function takeOpenFile(): { scope: string; path: string } | undefined {
  const raw = sessionStorage.getItem("rg.openFile");
  sessionStorage.removeItem("rg.openFile");
  try {
    const f = raw ? (JSON.parse(raw) as { scope?: unknown; path?: unknown }) : undefined;
    return typeof f?.scope === "string" && typeof f.path === "string"
      ? { scope: f.scope, path: f.path }
      : undefined;
  } catch {
    return undefined;
  }
}

export function App() {
  const [ready, setReady] = useState(false);
  const [search, setSearch] = useState(false);
  const [bell, setBell] = useState(false);
  // On a phone the left bar slides away with the finger (2026-11-03).
  const side = useRef<HTMLElement>(null);
  useSwipeAway(side, "left", () => (drawerOpen.value = false), drawerOpen.value);

  useEffect(() => {
    // An app or the installer opens the page with #token=…: signed in at once, the address is
    // cleaned (G39.7). A board's link from Telegram (G25.4): opened once signed in, even after
    // the password page.
    const link = takeFromLink();
    if (link.token) token.value = link.token;
    if (link.board) sessionStorage.setItem("rg.tavola", link.board);
    // RGCompanion's «All settings» (G40.8): the page opens on Settings, even after the password
    // page (G42.0: the intention waits in the tab's storage and is used once).
    if (link.open) sessionStorage.setItem("rg.open", link.open);
    // RGCompanion's «Open in the browser» for a document (G42.8): shown once signed in.
    if (link.file) sessionStorage.setItem("rg.openFile", JSON.stringify(link.file));
    // The app's look for its «All settings», not saved as the page's own choice.
    if (link.theme) document.documentElement.dataset.theme = link.theme;
    if (link.lang) lang.value = link.lang;
    if (token.value)
      void signIn(token.value)
        .catch(() => signOut())
        .finally(() => setReady(true));
    else setReady(true);
  }, []);

  // The project's files shown: a file is about to open, its editor's code comes ahead (3.5.11).
  useEffect(() => {
    if (explorerOpen.value) preloadCanvas();
  }, [explorerOpen.value]);

  useEffect(() => {
    if (!ready || !token.value) return;
    if (takeOpenIntent() === "settings")
      openTab({ id: "settings", type: "settings", title: t("settings") });
    const file = takeOpenFile();
    if (file) openCanvas(file.path.split(/[\\/]/).pop() ?? file.path, { kind: "file", ...file });
  }, [ready, token.value]);

  useEffect(() => {
    if (!ready || !token.value) return;
    const board = sessionStorage.getItem("rg.tavola")?.match(/^([\w-]+)\.([0-9a-f]{12})$/);
    if (!board) return;
    sessionStorage.removeItem("rg.tavola");
    openBoard(board[1] ?? "", board[2] ?? "", t("boardTab"));
  }, [ready, token.value]);

  useEffect(() => {
    if (!token.value) return;
    const timer = setInterval(() => void attempt(refresh), 15_000);
    return () => clearInterval(timer);
  }, [token.value]);

  const waiting = approvals.value.length + questions.value.length + notices.value.length;
  useEffect(() => {
    document.title = waiting ? `(${waiting}) ${PRODUCT_NAME}` : PRODUCT_NAME;
  }, [waiting]);

  if (!ready) return null;
  if (!token.value) return <Login />;
  // First run: the wizard takes the whole page until it is completed.
  if (firstRun.value)
    return (
      <div class="app">
        <Setup
          onDone={() => {
            firstRun.value = false;
          }}
        />
        {/* A mandatory update holds the wizard too (G36.19). */}
        <UpdateGate />
        <Dialogs />
      </div>
    );

  // The simple interface (3.12), chosen on this device or by the installation.
  if (uiMode.value === "simple")
    return (
      <div class="app app-simple">
        <SimpleApp />
        <UpdateGate />
        <Dialogs />
        <ConnectionLost />
      </div>
    );

  const tab = tabs.value.find((x) => x.id === activeTab.value);
  const info = platformInfo.value;
  return (
    <div class={`app ${drawerOpen.value ? "drawer-open" : ""}`}>
      <header class="top">
        <button
          type="button"
          class="icon-button menu"
          aria-label={t("menu")}
          onClick={() => (drawerOpen.value = !drawerOpen.value)}
        >
          <IconMenu />
        </button>
        <span class="brand">
          <Logo /> <span class="name">{PRODUCT_NAME}</span>
        </span>
        <Limits />
        <VoiceIndicator />
        <button
          type="button"
          class={`icon-button ${explorerOpen.value ? "on" : ""}`}
          title={t("projectFiles")}
          aria-label={t("projectFiles")}
          onClick={() => toggleExplorer()}
        >
          <IconFolder size={19} />
        </button>
        <button
          type="button"
          class="icon-button"
          title={t("searchConversations")}
          aria-label={t("searchConversations")}
          onClick={() => setSearch(!search)}
        >
          <IconSearch />
        </button>
        <button
          type="button"
          class={`icon-button bell ${waiting ? "on" : ""}`}
          title={t("waitingForYou")}
          aria-label={t("waitingForYou")}
          onClick={() => setBell(!bell)}
        >
          <IconBell />
          {waiting > 0 && <span class="badge">{waiting}</span>}
        </button>
        <span
          class={`conn ${status.value}`}
          title={t(
            status.value === "online"
              ? "online"
              : status.value === "connecting"
                ? "connecting"
                : "offline",
          )}
        />
      </header>
      <EngineLoading />
      <WhatsNew />
      <UpdateGate />
      {/* Our own questions, never the browser's (2026-11-09). */}
      <Dialogs />
      {/* «Salva» a passage or a message (G40.14). */}
      <SaveDialogHost />
      {citationNote.value && <CitationNote />}
      <ConnectionLost />
      <MemoryNotice />
      {/* «RedGiant is now called Rasgeth», once (plan 3.9.0, choice 17). */}
      <RenameNotice />
      {lastError.value && (
        <div class="banner error">
          <IconAlert /> {lastError.value}
          <button
            type="button"
            class="icon-button"
            title={t("close")}
            onClick={() => (lastError.value = null)}
          >
            <IconClose />
          </button>
        </div>
      )}
      {info?.keyProblems?.map((k) => (
        <div key={k.provider} class="banner error">
          <IconAlert />{" "}
          {t("keyRefused", { provider: k.provider, message: k.message.slice(0, 160) })}
          <button
            type="button"
            class="link"
            onClick={() =>
              openTab({ id: "settings", type: "settings", title: t("settings"), section: "setup" })
            }
          >
            {t("openSetup")}
          </button>
        </div>
      ))}
      {info?.waitingNetwork && info.waitingNetwork.length > 0 && (
        <div class="banner no-internet">
          <IconWifi />{" "}
          {t("noInternet", { parts: info.waitingNetwork.map((p) => p.label).join(", ") })}
        </div>
      )}
      {info?.metal && (
        <div class="banner error">
          <IconAlert /> {t("metalWarning")}
        </div>
      )}
      <div class="body">
        {search && <Search close={() => setSearch(false)} />}
        {bell && <Bell close={() => setBell(false)} />}
        <aside class="side" ref={side}>
          <Sidebar />
        </aside>
        <button
          type="button"
          class="veil"
          aria-label={t("close")}
          onClick={() => (drawerOpen.value = false)}
        />
        <main class="main">
          <Tabs />
          {tab ? (
            tabs.value.map((x) => (
              <div key={x.id} class="view" hidden={x.id !== tab.id}>
                <View tab={x} />
              </div>
            ))
          ) : (
            <div class="welcome">
              <Logo size={64} />
              <h1>{PRODUCT_NAME}</h1>
              <p>{t("welcomeText")}</p>
            </div>
          )}
        </main>
        {explorerOpen.value && <Explorer />}
        <SideArea />
      </div>
      <Downloads />
    </div>
  );
}
