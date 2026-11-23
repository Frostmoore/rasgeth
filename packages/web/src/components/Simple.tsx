// The simple interface (3.12, design «B · Assistente», tavole-semplice/b-assistente.html): for
// everyday people who do not know what an agent is. Three screens: «Oggi» (a greeting, one big
// box for God, the topics in progress with their state), a topic read as a clean document with its
// decisions in an evident box, and a few settings in groups with «Full view» at the bottom. The
// archive is found with its search. No agents, tools, figures or permissions jargon in sight.

import type { ImagePart } from "@redgiant/protocol";
import {
  criticalSentences,
  isCriticalRequest,
  type PermissionRequestInfo,
  PRODUCT_NAME,
  type QuestionRequestInfo,
  requestSentence,
  type TopicView,
} from "@redgiant/protocol";
import type { ComponentChildren } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import { usd } from "../format.js";
import { lang, setLang, t } from "../i18n.js";
import {
  IconArchive,
  IconArrowDown,
  IconChevronLeft,
  IconClose,
  IconFile,
  IconMonitor,
  IconMoon,
  IconMore,
  IconPaperclip,
  IconPin,
  IconPlus,
  IconSearch,
  IconSend,
  IconSettings,
  IconStop,
  IconSun,
  Logo,
} from "../icons.js";
import { renderAnswer, renderStreamingMarkdown } from "../markdown.js";
import { agentMascotState } from "../mascot-state.js";
import {
  agents,
  archivedCount,
  archivedTopics,
  archiveTopic,
  askChat,
  askGod,
  attempt,
  buildItems,
  type ChatItem,
  chatAgentId,
  conversationCost,
  documentItems,
  getApi,
  getLive,
  godNudge,
  godRoutingText,
  greetingKey,
  interruptSession,
  lastError,
  loadNudgeSettings,
  moveExchange,
  nudgeInvite,
  nudgeSettings,
  openChat,
  openNudge,
  openTopic,
  personName,
  projects,
  questions,
  recentChats,
  refreshTopics,
  restoreTopic,
  saveNudgeSettings,
  searchArchive,
  sendInChat,
  sessionRows,
  sessionView,
  setUiMode,
  signOut,
  simpleAssistants,
  simpleLastSent,
  simpleScreen,
  simpleTyping,
  stageFront,
  TOPIC_STATE_WORDS,
  topics,
  topicsLoaded,
  topicsTrouble,
  topicTitle,
  waitingElsewhere,
  waitingIn,
  workWord,
} from "../state.js";
import { setTheme, theme } from "../theme.js";
import { setVoiceSettings, voiceSettings } from "../voice/settings.js";
import { AccentPicker } from "./AccentPicker.js";
import { useArmed } from "./armed.js";
import { FileCard } from "./Chat.js";
import { type Attachment, packMessage, takeFiles } from "./Composer.js";
import { askText } from "./dialogs.js";
import { FoundCard } from "./FoundWidgets.js";
import { useFollow } from "./follow-hook.js";
import { Mascot } from "./Mascot.js";
import { NudgeControls } from "./NudgeControls.js";
import { ProductCards } from "./ProductCards.js";
import { QuestionCard } from "./QuestionCard.js";
import { Seg, Switch } from "./SettingsKit.js";
import { SimpleStage } from "./SimpleStage.js";
import { SimpleStrip } from "./SimpleStrip.js";
import { Telegram } from "./Telegram.js";
import { Modal } from "./ui.js";

/** The simple interface, all of it. */
export function SimpleApp() {
  useEffect(() => {
    void refreshTopics().catch(() => {});
  }, []);
  const s = simpleScreen.value;
  return (
    <div class="smp">
      {lastError.value && (
        <div class="smp-error" role="alert">
          <span>{lastError.value}</span>
          <button type="button" class="smp-link" onClick={() => (lastError.value = null)}>
            {t("close")}
          </button>
        </div>
      )}
      {s.kind === "today" && <Today />}
      {s.kind === "topic" && <TopicScreen key={s.id} id={s.id} title={s.title} />}
      {s.kind === "chat" && <TopicScreen key={s.id} id={s.id} title={s.title} chat />}
      {s.kind === "archive" && <ArchiveScreen />}
      {s.kind === "requests" && <RequestsScreen />}
      {s.kind === "settings" && <SettingsScreen />}
    </div>
  );
}

const goToday = () => (simpleScreen.value = { kind: "today" });

/**
 * The simple interface's box: one place to write («Chiedimi qualcosa…», «Rispondi…»). 3.12.2: an
 * attach button (the full composer's files and limits, chips to remove before sending) and, while
 * the conversation it writes to is working, a stop button (the same interruption).
 */
function AskBox({
  hint,
  onSend,
  big = false,
  listened = false,
  scope = "platform",
  sessionId,
}: {
  hint: string;
  /** The words (with the attachments written into them) and the pictures for the model. */
  onSend: (text: string, images: ImagePart[]) => Promise<unknown>;
  big?: boolean;
  /** The giant mascot listens while the person types here (3.12.1). */
  listened?: boolean;
  /** Where files other than pictures and texts are saved (as the full composer: the agent's workspace). */
  scope?: string;
  /** The conversation it writes to, for «Stop»; none yet: the one last sent from here. */
  sessionId?: string | undefined;
}) {
  const [text, setText] = useState("");
  const [files, setFiles] = useState<Attachment[]>([]);
  const [problem, setProblem] = useState<string | null>(null);
  const typing = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  useEffect(
    () => () => {
      clearTimeout(typing.current);
      if (listened) simpleTyping.value = false;
    },
    [listened],
  );
  const typed = (words: string) => {
    setText(words);
    if (!listened) return;
    // Listening while keys come, and a moment after the last one.
    simpleTyping.value = words.trim() !== "";
    clearTimeout(typing.current);
    typing.current = setTimeout(() => (simpleTyping.value = false), 2500);
  };
  const [busy, setBusy] = useState(false);
  const area = useRef<HTMLTextAreaElement>(null);
  const target = sessionId ?? simpleLastSent.value;
  const running = target ? sessionView(target).value.state === "running" : false;
  const send = async () => {
    const words = text.trim();
    if ((!words && files.length === 0) || busy) return;
    setBusy(true);
    const kept = files;
    // The box empties at once; what was written comes back only if it could not go.
    setText("");
    setFiles([]);
    let r: unknown;
    try {
      const msg = await packMessage(words, kept, (path, data) =>
        getApi().write(scope, path, data, "base64"),
      );
      r = await onSend(msg.text.trim() || t("seeAttachments"), msg.images);
    } catch (e) {
      setProblem((e as Error).message);
    }
    setBusy(false);
    if (r === undefined) {
      setText(words);
      setFiles(kept);
    }
    area.current?.focus();
  };
  const add = async (list: FileList | File[]) => {
    const r = await takeFiles(files, [...list]);
    setProblem(r.problem);
    setFiles((now) => [...now, ...r.picked].slice(0, 10));
  };
  // The box grows with what is written, up to a few lines.
  useEffect(() => {
    const el = area.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${Math.min(el.scrollHeight, 180)}px`;
  }, [text]);
  return (
    <div class={`smp-ask${big ? " big" : ""}`}>
      {(files.length > 0 || problem) && (
        <div class="smp-ask-chips">
          {files.map((f) => (
            <span key={f.name} class="smp-chip" data-attachment={f.kind}>
              {f.kind === "image" ? <img src={f.url} alt="" /> : <IconFile size={13} />}
              <span class="smp-chip-name">{f.name}</span>
              <button
                type="button"
                class="smp-chip-x"
                aria-label={t("remove")}
                title={t("remove")}
                onClick={() => setFiles(files.filter((x) => x !== f))}
              >
                <IconClose size={11} />
              </button>
            </span>
          ))}
          {problem && <span class="smp-ask-problem">{problem}</span>}
        </div>
      )}
      <div class="smp-ask-row">
        <label class="smp-attach" title={t("attach")}>
          <IconPaperclip size={19} />
          <input
            type="file"
            multiple
            hidden
            aria-label={t("attach")}
            onChange={(e) => {
              const input = e.target as HTMLInputElement;
              if (input.files) void add(input.files);
              input.value = "";
            }}
          />
        </label>
        <textarea
          ref={area}
          rows={1}
          value={text}
          placeholder={hint}
          aria-label={hint}
          onInput={(e) => typed((e.target as HTMLTextAreaElement).value)}
          onKeyDown={(e) => {
            if (e.key === "Enter" && !e.shiftKey && !e.isComposing) {
              e.preventDefault();
              void send();
            }
          }}
        />
        {running && target && (
          <button
            type="button"
            class="smp-send smp-stop"
            aria-label={t("interrupt")}
            title={t("interrupt")}
            onClick={() => interruptSession(target)}
          >
            <IconStop size={16} />
          </button>
        )}
        <button
          type="button"
          class="smp-send"
          aria-label={t("smpSend")}
          title={t("smpSend")}
          disabled={busy || (!text.trim() && files.length === 0)}
          onClick={() => void send()}
        >
          <IconSend size={18} />
        </button>
      </div>
    </div>
  );
}

/** «Oggi»: the greeting, the big box, the topics in progress. */
function Today() {
  const name = personName.value.trim();
  const key = greetingKey(new Date().getHours());
  const list = topics.value;
  const elsewhere = waitingElsewhere();
  const others = elsewhere.approvals.length + elsewhere.questions.length;
  // Satellite in front (3.12.1): the Chat's words, box and latest conversations.
  const chat = stageFront.value === "chat";
  return (
    <div class={`smp-screen smp-today${chat ? " with-chat" : ""}`}>
      <div class="smp-wrap">
        <header class="smp-bar">
          <span class="smp-brand">
            <Logo size={22} /> {PRODUCT_NAME}
          </span>
          <button
            type="button"
            class="smp-icon"
            aria-label={t("smpSettings")}
            title={t("smpSettings")}
            onClick={() => (simpleScreen.value = { kind: "settings" })}
          >
            <IconSettings size={20} />
          </button>
        </header>
        <SimpleStage />
        {godNudge.value && !chat && <NudgeBalloon />}
        <div class="smp-hero">
          <h1>{name ? t(`${key}Name`, { name }) : t(key)}</h1>
          <p>
            {!chat && nudgeInvite.value
              ? nudgeInvite.value
              : t(chat ? "smpChatLead" : "smpHeroLead")}
          </p>
        </div>
        <AskBox
          key={chat ? "chat" : "god"}
          big
          listened
          hint={t(chat ? "smpChatHint" : "smpAskHint")}
          onSend={(text, images) => {
            // A generic nudge's invitation goes once the person writes (the topic comes now).
            nudgeInvite.value = null;
            return chat ? askChat(text, images) : askGod(text, { images });
          }}
        />
        {!chat && godRoutingText.value && (
          <div class="smp-routing" role="status">
            <span class="smp-routing-text">{godRoutingText.value}</span>
            <span class="smp-routing-line">{t("smpRouting")}</span>
          </div>
        )}
        {chat ? <RecentChats /> : null}
        {!chat && others > 0 && (
          <button
            type="button"
            class="smp-waiting-line"
            onClick={() => (simpleScreen.value = { kind: "requests" })}
          >
            <span class="smp-dot" />
            {t(others === 1 ? "smpOtherOne" : "smpOtherMany", { n: String(others) })}
          </button>
        )}
        {/* The ready-made assistants (3.12, to be defined with the person): none yet, nothing shown. */}
        {!chat && simpleAssistants.value.length > 0 && (
          <div class="smp-assistants">
            {simpleAssistants.value.map((a) => (
              <button
                type="button"
                key={a.id}
                class="smp-assistant"
                onClick={() => void askGod(a.ask)}
              >
                <b>{a.name}</b>
                <span>{a.line}</span>
              </button>
            ))}
          </div>
        )}
        {!chat && <div class="smp-lbl">{t("smpInProgress")}</div>}
        {chat ? null : list.length === 0 && topicsTrouble.value ? (
          <TopicsTrouble why={topicsTrouble.value} />
        ) : list.length === 0 ? (
          <p class="smp-empty">{t(topicsLoaded.value ? "smpNoTopics" : "smpLoading")}</p>
        ) : (
          <div class="smp-cards">
            {list.map((x) => (
              <TopicCard key={x.id} x={x} />
            ))}
          </div>
        )}
        {!chat && (
          <div class="smp-foot">
            <button
              type="button"
              class="smp-link"
              onClick={() => (simpleScreen.value = { kind: "archive" })}
            >
              <IconArchive size={15} /> {t("smpArchive", { n: String(archivedCount.value) })}
            </button>
          </div>
        )}
        <SimpleStrip />
      </div>
    </div>
  );
}

/**
 * God's friendly nudge (3.12.1), as a balloon under him: a tap opens its topic, or only «Oggi»'s
 * invitation for a generic one; nothing is created until the person writes.
 */
function NudgeBalloon() {
  const n = godNudge.value;
  if (!n) return null;
  return (
    <div class="smp-nudge" role="status">
      <button type="button" class="smp-nudge-open" onClick={() => openNudge(n)}>
        {n.text}
      </button>
      <button
        type="button"
        class="smp-icon smp-nudge-close"
        aria-label={t("close")}
        title={t("close")}
        onClick={() => (godNudge.value = null)}
      >
        <IconClose size={16} />
      </button>
    </div>
  );
}

/** Satellite's list: the Chat's latest conversations, newest first. */
function RecentChats() {
  const rows = recentChats(sessionRows.value, chatAgentId.value);
  return (
    <>
      <div class="smp-lbl">{t("smpRecentChats")}</div>
      {rows.length === 0 ? (
        <p class="smp-empty">{t("smpNoChats")}</p>
      ) : (
        <div class="smp-cards">
          {rows.map((r) => (
            <button
              type="button"
              key={r.id}
              class="smp-card smp-chat-card"
              onClick={() => openChat(r.id, r.title ?? t("smpUntitledChat"))}
            >
              <span class="smp-card-t">{r.title ?? t("smpUntitledChat")}</span>
              <span class="smp-card-p">{whenSaid(r.lastAt ?? r.createdAt)}</span>
            </button>
          ))}
        </div>
      )}
    </>
  );
}

/** When a chat was last used, in plain words («Oggi, 13:05», «Ieri», a date). */
function whenSaid(iso: string): string {
  const at = new Date(iso);
  const now = new Date();
  const day = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  const days = Math.round((day(now) - day(at)) / 86_400_000);
  const locale = lang.value === "it" ? "it-IT" : "en-GB";
  if (days === 0)
    return t("smpTodayAt", {
      time: at.toLocaleTimeString(locale, { hour: "2-digit", minute: "2-digit" }),
    });
  if (days === 1) return t("smpYesterday");
  return at.toLocaleDateString(locale, { day: "numeric", month: "long" });
}

/**
 * The topics did not come (3.12.1): a server before 3.12 is said in words, with the full interface
 * offered; any other error offers to try again. Never «Un momento…» for ever.
 */
function TopicsTrouble({ why }: { why: "old" | "failed" }) {
  return (
    <div class="smp-trouble" role="status">
      <p>{t(why === "old" ? "smpOldServer" : "smpTopicsFailed")}</p>
      <div class="smp-trouble-do">
        {why === "failed" && (
          <button
            type="button"
            class="smp-btn"
            onClick={() => void refreshTopics().catch(() => {})}
          >
            {t("smpTryAgain")}
          </button>
        )}
        <button
          type="button"
          class={why === "old" ? "smp-btn" : "smp-btn soft"}
          onClick={() => setUiMode("full")}
        >
          {t("smpFullView")}
        </button>
      </div>
    </div>
  );
}

/** One topic's card: its title, a line about it, its state in words. */
function TopicCard({ x }: { x: TopicView }) {
  const word = t(TOPIC_STATE_WORDS[x.state]);
  return (
    <button
      type="button"
      class={`smp-card ${x.state}${x.unread > 0 ? " unread" : ""}`}
      onClick={() => openTopic(x.id, x.title)}
    >
      <span class="smp-card-t">
        {x.pinned && <IconPin size={13} />}
        {x.title}
      </span>
      <span class="smp-card-p">{x.summary ?? t("smpJustStarted")}</span>
      {x.from && <span class="smp-card-from">{t("smpFrom", { name: x.from })}</span>}
      <CardMascots ids={(x.agents ?? []).map((a) => a.id)} />
      <span class={`smp-pill ${x.state}`}>
        {word}
        {x.unread > 0 && (
          <span class="smp-new">
            <span class="sr-only">{t("smpUnread")}</span>
          </span>
        )}
      </span>
    </button>
  );
}

/**
 * The agents on a topic's card (3.12.1): who opened it and who works on its tasks, small and
 * overlapping like the strip, each with its live state; nobody, nothing.
 */
function CardMascots({ ids }: { ids: readonly string[] }) {
  const list = ids.flatMap((id) => {
    const a = agents.value.find((x) => x.id === id);
    return a ? [a] : [];
  });
  if (list.length === 0) return null;
  return (
    <span class="smp-card-agents">
      {list.map((a, i) => (
        <span
          key={a.id}
          class="smp-card-agent"
          style={{ "--i": String(i) }}
          title={t("smpAgentIs", {
            name: a.name,
            state: t(`mascotState_${agentMascotState(a.id)}`),
          })}
        >
          <Mascot agent={a} size={28} />
        </span>
      ))}
    </span>
  );
}

/** The agent at work, in a conversation of the simple interface: its mascot and a word. */
function WorkLine({
  agentId,
  word,
}: {
  agentId: string | undefined;
  word: NonNullable<ReturnType<typeof workWord>>;
}) {
  const agent = agents.value.find((a) => a.id === agentId);
  return (
    <p class="smp-working" role="status">
      {agent ? (
        <Mascot agent={agent} size={32} decorative />
      ) : (
        <span class="smp-dots" aria-hidden="true">
          <i />
          <i />
          <i />
        </span>
      )}
      {t(word)}
    </p>
  );
}

/** The top of a screen: back, a title, and what else it offers. */
function TopBar({
  title,
  back = goToday,
  children,
}: {
  title: string;
  back?: () => void;
  children?: ComponentChildren;
}) {
  return (
    <header class="smp-top">
      <button type="button" class="smp-icon smp-back" aria-label={t("smpBack")} onClick={back}>
        <IconChevronLeft size={22} />
      </button>
      <h2>{title}</h2>
      {children}
    </header>
  );
}

/** A topic, read as a document; its decisions in a box; «Rispondi…» at the bottom. */
function TopicScreen({ id, title, chat = false }: { id: string; title: string; chat?: boolean }) {
  const scroller = useRef<HTMLDivElement>(null);
  const follow = useFollow(scroller, id);
  const [menu, setMenu] = useState(false);
  const [moving, setMoving] = useState<number | null>(null);
  useEffect(() => {
    const live = getLive();
    live.send({ type: "session.follow", sessionId: id });
    return () => live.send({ type: "session.unfollow", sessionId: id });
  }, [id]);
  const view = sessionView(id).value;
  const items = documentItems(buildItems(view.events));
  const known = topics.value.find((x) => x.id === id);
  const name = (chat ? sessionRows.value.find((r) => r.id === id)?.title : known?.title) ?? title;
  const waiting = waitingIn(id);
  // Questions of an agent under God: not in this log, shown with the rest of the decisions.
  const askedHere = new Set(items.flatMap((i) => (i.kind === "question" ? [i.requestId] : [])));
  const otherQuestions = waiting.questions.filter((q) => !askedHere.has(q.requestId));
  const working = view.state === "running";
  // Who works here (its mascot while it works): God in a topic, else the conversation's agent.
  const agentId = chat
    ? sessionRows.value.find((r) => r.id === id)?.agentId
    : agents.value.find((a) => a.kind === "god")?.id;
  const doing = workWord(
    view.events,
    working,
    working &&
      !!view.call &&
      (view.call.writing === "thinking" || view.call.firstToken === undefined),
    waiting.approvals.length + otherQuestions.length > 0,
  );
  const cost = conversationCost(view.events);
  return (
    <div class="smp-screen smp-topic">
      <div class="smp-wrap">
        <TopBar title={name}>
          {/* What this conversation cost: everyone's to know (3.12.1). */}
          {cost > 0 && <span class="smp-cost">{t("smpSpentHere", { usd: usd(cost) })}</span>}
          {!chat && (
            <button
              type="button"
              class="smp-icon"
              aria-label={t("smpMore")}
              title={t("smpMore")}
              aria-expanded={menu}
              onClick={() => setMenu(!menu)}
            >
              <IconMore size={20} />
            </button>
          )}
          {!chat && menu && (
            <TopicMenu id={id} title={name} pinned={!!known?.pinned} close={() => setMenu(false)} />
          )}
        </TopBar>
        <div class="smp-doc-wrap">
          <div class="smp-doc" ref={scroller} tabIndex={-1}>
            {items.length === 0 && !view.text && (
              <p class="smp-empty">{t(view.synced ? "smpEmptyTopic" : "smpLoading")}</p>
            )}
            {items.map((item) => (
              <DocItem key={item.key} item={item} topicId={id} onMove={setMoving} />
            ))}
            {view.text && (
              <div
                class="md md-read smp-answer"
                dangerouslySetInnerHTML={{ __html: renderStreamingMarkdown(view.text) }}
              />
            )}
            {/* While it works: only its mascot and a word, no tools, no reasoning (3.12.1). */}
            {doing && !view.text && <WorkLine agentId={agentId} word={doing} />}
            {waiting.approvals.map((r) => (
              <Decision key={r.requestId} r={r} />
            ))}
            {otherQuestions.map((q) => (
              <QuestionBox key={q.requestId} q={q} />
            ))}
          </div>
          {follow.away && (
            <button
              type="button"
              class={`to-bottom${follow.unseen ? " unseen" : ""}`}
              title={t("toBottom")}
              aria-label={t("toBottom")}
              onClick={follow.toBottom}
            >
              <IconArrowDown />
              {follow.unseen && <span>{t("newText")}</span>}
            </button>
          )}
        </div>
        <AskBox
          hint={t("smpReplyHint")}
          sessionId={id}
          onSend={async (text, images) => {
            const r = chat
              ? sendInChat(id, text, images) || undefined
              : await askGod(text, { topicId: id, images });
            follow.toBottom();
            return r;
          }}
        />
      </div>
      {moving !== null && <MoveWindow from={id} seq={moving} close={() => setMoving(null)} />}
    </div>
  );
}

/** The topic's few actions: rename, pin, archive. */
function TopicMenu({
  id,
  title,
  pinned,
  close,
}: {
  id: string;
  title: string;
  pinned: boolean;
  close: () => void;
}) {
  const act = (f: () => Promise<unknown>) => {
    close();
    void f().then(() => refreshTopics().catch(() => {}));
  };
  return (
    <div class="smp-menu" role="menu">
      <button
        type="button"
        role="menuitem"
        onClick={() =>
          act(async () => {
            const name = await askText(t("smpRename"), title);
            if (name?.trim())
              await attempt(() => getApi().updateSession(id, { title: name.trim() }));
          })
        }
      >
        {t("smpRename")}
      </button>
      <button
        type="button"
        role="menuitem"
        onClick={() => act(() => attempt(() => getApi().updateSession(id, { pinned: !pinned })))}
      >
        {t(pinned ? "smpUnpin" : "smpPin")}
      </button>
      <button type="button" role="menuitem" onClick={() => act(() => archiveTopic(id))}>
        {t("smpArchiveThis")}
      </button>
    </div>
  );
}

const answerText = (item: Extract<ChatItem, { kind: "assistant" }>) =>
  item.parts
    .flatMap((p) => (p.type === "text" ? [p.text] : []))
    .join("\n\n")
    .trim();

/** One piece of the document. */
function DocItem({
  item,
  topicId,
  onMove,
}: {
  item: ChatItem;
  topicId: string;
  onMove: (seq: number) => void;
}) {
  switch (item.kind) {
    case "user": {
      // Attachments travel in the text: only the words show here.
      const cut = item.text.search(/\n\n<attachment name="/);
      const words = cut < 0 ? item.text : item.text.slice(0, cut);
      return (
        <div class="smp-me-row">
          {item.movedFrom && <span class="smp-note">{t("smpMovedHere")}</span>}
          <div class="smp-me">{words}</div>
          <button type="button" class="smp-move-link" onClick={() => onMove(item.seq)}>
            {t("smpMove")}
          </button>
        </div>
      );
    }
    case "routed": {
      const title = topicTitle(topicId) ?? "";
      return (
        <p class={`smp-routed${item.uncertain ? " unsure" : ""}`}>
          {/* Unsure: said short, the topic is the one on screen; sure: «in: Title». */}
          <span>
            {item.uncertain ? (
              t("smpRoutedUnsure")
            ) : (
              <>
                {t("smpRoutedIn")} <b>{title}</b>
              </>
            )}
          </span>
          {item.userSeq !== undefined && (
            <>
              {" · "}
              <button
                type="button"
                class="smp-link"
                onClick={() => item.userSeq !== undefined && onMove(item.userSeq)}
              >
                {t("smpMove")}
              </button>
            </>
          )}
        </p>
      );
    }
    case "moved": {
      const to = topicTitle(item.toSessionId);
      return (
        <p class="smp-routed moved">
          <button
            type="button"
            class="smp-link"
            onClick={() => openTopic(item.toSessionId, to ?? "")}
          >
            {to ? t("smpMovedTo", { title: to }) : t("smpMovedElsewhere")}
          </button>
        </p>
      );
    }
    case "assistant":
      return (
        <div
          class="md md-read smp-answer"
          dangerouslySetInnerHTML={{ __html: renderAnswer(answerText(item)) }}
        />
      );
    case "question":
      return item.answers === undefined &&
        questions.value.some((q) => q.requestId === item.requestId) ? (
        <QuestionBox
          q={{ requestId: item.requestId, questions: item.questions, plan: item.plan }}
        />
      ) : (
        <div class="smp-decided">
          <QuestionCard
            requestId={item.requestId}
            questions={item.questions}
            plan={item.plan}
            answers={item.answers}
            open={false}
          />
        </div>
      );
    case "products":
      return <ProductCards title={item.title} products={item.products} />;
    case "found":
      return <FoundCard widget={item.widget} sessionId={topicId} />;
    case "file":
      return <FileCard item={item} />;
    default:
      return null;
  }
}

/** A project's or agent's name for a request's words. */
const nameOf = (r: PermissionRequestInfo) => (id: string) =>
  r.names?.[id] ??
  agents.value.find((a) => a.id === id)?.name ??
  projects.value.find((p) => p.id === id)?.name;

/**
 * A request in plain words, in an evident box: what would happen, «Yes» or «No». A truly dangerous
 * one says it can't be undone and what it does, in red; one click still decides.
 */
export function Decision({ r }: { r: PermissionRequestInfo }) {
  const { ref, armed } = useArmed<HTMLDivElement>(r.requestId);
  const critical = isCriticalRequest(r);
  const what = requestSentence(lang.value, r.tool, r.input, nameOf(r));
  const resolve = (decision: "allow" | "deny") => {
    if (!armed) return;
    getLive().send({
      type: "permission.resolve",
      requestId: r.requestId,
      decision,
      remember: false,
      scope: "once",
    });
  };
  return (
    <fieldset class={`smp-decide${critical ? " critical" : ""}`} aria-label={t("smpDecide")}>
      <b>{t(critical ? "smpAskCritical" : "smpAskAllow")}</b>
      <p>{what}</p>
      {critical && (
        <ul>
          {criticalSentences(lang.value, r).map((x) => (
            <li key={x}>{x}</li>
          ))}
        </ul>
      )}
      {r.topic && r.topic.id !== r.sessionId && simpleScreen.value.kind !== "topic" && (
        <span class="smp-note">{t("smpFor", { title: r.topic.title })}</span>
      )}
      <div ref={ref} class={`smp-decide-acts${armed ? "" : " arming"}`}>
        <button type="button" class="smp-btn" onClick={() => resolve("allow")}>
          {t("smpYes")}
        </button>
        <button type="button" class="smp-btn soft" onClick={() => resolve("deny")}>
          {t("smpNo")}
        </button>
      </div>
    </fieldset>
  );
}

/**
 * A question waiting for the person, in the same box. One plain choice (the board's «Vuoi che lo
 * prenoti?») is its buttons, the first one filled, with «Altro…» for words of one's own; anything
 * else (several questions, several choices, a plan) is the usual card.
 */
function QuestionBox({
  q,
}: {
  q: Pick<QuestionRequestInfo, "requestId" | "questions" | "plan"> & {
    topic?: QuestionRequestInfo["topic"];
  };
}) {
  const { ref, armed } = useArmed<HTMLDivElement>(q.requestId);
  const [other, setOther] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const one = q.questions.length === 1 && q.plan === undefined ? q.questions[0] : undefined;
  const answer = (text: string) => {
    if (!armed || sent || !text.trim()) return;
    getLive().send({ type: "question.answer", requestId: q.requestId, answers: [[text.trim()]] });
    setSent(true);
  };
  return (
    <div class="smp-decide">
      {q.topic && simpleScreen.value.kind !== "topic" && (
        <span class="smp-note">{t("smpFor", { title: q.topic.title })}</span>
      )}
      {one && !one.multiSelect ? (
        <>
          <b>{one.question}</b>
          <div ref={ref} class={`smp-decide-acts${armed && !sent ? "" : " arming"}`}>
            {one.options.map((o, n) => (
              <button
                type="button"
                key={o.label}
                class={n === 0 ? "smp-btn" : "smp-btn soft"}
                title={o.description}
                onClick={() => answer(o.label)}
              >
                {o.label}
              </button>
            ))}
            {other === null && (
              <button type="button" class="smp-btn soft" onClick={() => setOther("")}>
                {t("smpOther")}
              </button>
            )}
          </div>
          {other !== null && (
            <div class="smp-other">
              <input
                value={other}
                placeholder={t("smpOtherHint")}
                aria-label={t("smpOtherHint")}
                onInput={(e) => setOther((e.target as HTMLInputElement).value)}
                onKeyDown={(e) => e.key === "Enter" && answer(other)}
              />
              <button type="button" class="smp-btn" onClick={() => answer(other)}>
                {t("smpSend")}
              </button>
            </div>
          )}
        </>
      ) : (
        <QuestionCard requestId={q.requestId} questions={q.questions} plan={q.plan} open />
      )}
    </div>
  );
}

/**
 * «Move»: the exchange goes to another topic, an archived one (found with its search) or a new one;
 * God answers there again.
 */
function MoveWindow({ from, seq, close }: { from: string; seq: number; close: () => void }) {
  const [q, setQ] = useState("");
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    const timer = setTimeout(() => void searchArchive(q).catch(() => {}), q ? 250 : 0);
    return () => clearTimeout(timer);
  }, [q]);
  const go = async (to: string, title?: string) => {
    if (busy) return;
    setBusy(true);
    const ok = await moveExchange(from, seq, to, title);
    setBusy(false);
    if (ok) close();
  };
  const active = topics.value.filter((x) => x.id !== from);
  const words = q.trim().toLowerCase();
  const shown = words
    ? active.filter((x) => `${x.title} ${x.summary ?? ""}`.toLowerCase().includes(words))
    : active;
  return (
    <Modal title={t("smpMoveTitle")} sub={t("smpMoveLead")} onClose={close} class="smp-modal">
      <button
        type="button"
        class="smp-move-row new"
        disabled={busy}
        onClick={async () => {
          const title = await askText(t("smpNewTopic"), "", { label: t("smpNewTopicName") });
          if (title !== null) await go("new", title || undefined);
        }}
      >
        <IconPlus size={16} /> {t("smpNewTopic")}
      </button>
      <label class="smp-search">
        <IconSearch size={16} />
        <input
          type="search"
          value={q}
          placeholder={t("smpSearchHint")}
          aria-label={t("smpSearchHint")}
          onInput={(e) => setQ((e.target as HTMLInputElement).value)}
        />
      </label>
      {shown.map((x) => (
        <button
          type="button"
          key={x.id}
          class="smp-move-row"
          disabled={busy}
          onClick={() => void go(x.id)}
        >
          <b>{x.title}</b>
          {x.summary && <span>{x.summary}</span>}
        </button>
      ))}
      {archivedTopics.value.length > 0 && <div class="smp-lbl">{t("smpInArchive")}</div>}
      {archivedTopics.value
        .filter((x) => x.id !== from)
        .map((x) => (
          <button
            type="button"
            key={x.id}
            class="smp-move-row"
            disabled={busy}
            onClick={() => void go(x.id)}
          >
            <b>{x.title}</b>
            {x.summary && <span>{x.summary}</span>}
          </button>
        ))}
    </Modal>
  );
}

const dayText = (iso: string | null) =>
  iso ? new Date(iso).toLocaleDateString(lang.value, { day: "numeric", month: "long" }) : "";

/** The archive: the topics that rested, found with words; one tap takes one back. */
function ArchiveScreen() {
  const [q, setQ] = useState("");
  useEffect(() => {
    const timer = setTimeout(() => void searchArchive(q).catch(() => {}), q ? 250 : 0);
    return () => clearTimeout(timer);
  }, [q]);
  const list = archivedTopics.value;
  return (
    <div class="smp-screen smp-archive">
      <div class="smp-wrap">
        <TopBar title={t("smpArchiveTitle")} />
        <div class="smp-set">
          <p class="smp-lead">{t("smpArchiveLead")}</p>
          <label class="smp-search">
            <IconSearch size={16} />
            <input
              type="search"
              value={q}
              placeholder={t("smpSearchHint")}
              aria-label={t("smpSearchHint")}
              onInput={(e) => setQ((e.target as HTMLInputElement).value)}
            />
          </label>
          {list.length === 0 ? (
            <p class="smp-empty">{t(q.trim() ? "smpNothingFound" : "smpArchiveEmpty")}</p>
          ) : (
            <div class="smp-grp">
              {list.map((x) => (
                <button
                  type="button"
                  key={x.id}
                  class="smp-row smp-archived"
                  onClick={() => void restoreTopic(x.id, x.title)}
                >
                  <span>
                    <b>{x.title}</b>
                    {x.summary && <span class="smp-row-sub">{x.summary}</span>}
                  </span>
                  <span class="smp-row-val">{dayText(x.lastAt)}</span>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

/** What waits for the person outside the topics (an automation's request). */
function RequestsScreen() {
  const w = waitingElsewhere();
  return (
    <div class="smp-screen smp-requests">
      <div class="smp-wrap">
        <TopBar title={t("smpRequestsTitle")} />
        <div class="smp-doc">
          {w.approvals.length + w.questions.length === 0 && (
            <p class="smp-empty">{t("smpNothingWaits")}</p>
          )}
          {w.approvals.map((r) => (
            <Decision key={r.requestId} r={r} />
          ))}
          {w.questions.map((q) => (
            <QuestionBox key={q.requestId} q={q} />
          ))}
        </div>
      </div>
    </div>
  );
}

/** The browser's notifications on this device: on once allowed. */
function useNotifications(): [NotificationPermission | "none", () => void] {
  const supported = typeof Notification !== "undefined";
  const [state, setState] = useState<NotificationPermission | "none">(
    supported ? Notification.permission : "none",
  );
  return [
    state,
    () => {
      if (supported) void Notification.requestPermission().then(setState);
    },
  ];
}

/** A row of a group: its words on the left, its control or value on the right. */
function SetRow({
  title,
  help,
  children,
  onClick,
  stack,
}: {
  title: string;
  help?: string;
  children?: ComponentChildren;
  onClick?: () => void;
  /** On a phone the control goes under the words (a row of choices, the colours). */
  stack?: boolean;
}) {
  const body = (
    <>
      <span>
        {title}
        {help && <span class="smp-row-sub">{help}</span>}
      </span>
      {children}
    </>
  );
  return onClick ? (
    <button type="button" class="smp-row" onClick={onClick}>
      {body}
    </button>
  ) : (
    <div class={`smp-row${stack ? " stack" : ""}`}>{body}</div>
  );
}

/** Few settings, in groups; «Full view» at the bottom. */
function SettingsScreen() {
  const [notify, askNotify] = useNotifications();
  const [telegram, setTelegram] = useState(false);
  const [linked, setLinked] = useState(false);
  useEffect(() => {
    if (telegram) return;
    void getApi()
      .telegramLinks()
      .then(
        (l) => setLinked(l.length > 0),
        () => setLinked(false),
      );
  }, [telegram]);
  const name = personName.value;
  return (
    <div class="smp-screen smp-settings">
      <div class="smp-wrap">
        <TopBar title={t("smpSettings")} />
        <div class="smp-set">
          <div class="smp-grp">
            <SetRow
              title={t("smpNotify")}
              help={notify === "denied" ? t("smpNotifyBlocked") : undefined}
            >
              <Switch
                on={notify === "granted"}
                label={t("smpNotify")}
                disabled={notify === "denied" || notify === "none"}
                onChange={askNotify}
              />
            </SetRow>
            <SetRow title={t("smpVoice")} help={t("smpVoiceHelp")}>
              <Switch
                on={voiceSettings.value.enabled}
                label={t("smpVoice")}
                onChange={(on) => setVoiceSettings({ enabled: on })}
              />
            </SetRow>
            {/* God's friendly nudges (3.12.1): on or off, and how often. */}
            <SetRow title={t("nudgeTitle")} help={t("nudgeHelp")} stack>
              <NudgeControls />
            </SetRow>
            <SetRow title={t("smpSpend")} help={t("smpSpendHelp")}>
              <span class="smp-row-val">{t("smpAlways")}</span>
            </SetRow>
          </div>
          <div class="smp-grp">
            <SetRow
              title={t("smpYourName")}
              onClick={async () => {
                const v = await askText(t("smpYourName"), name, { label: t("smpYourNameLabel") });
                if (v === null) return;
                if ((await attempt(() => getApi().setupPerson(v.trim() || null))) !== undefined)
                  personName.value = v.trim();
              }}
            >
              <span class="smp-row-val">{name || t("smpNoName")}</span>
            </SetRow>
            <SetRow title={t("telegram")} onClick={() => setTelegram(true)}>
              <span class={linked ? "smp-row-val" : "smp-row-act"}>
                {t(linked ? "smpLinked" : "smpLink")}
              </span>
            </SetRow>
          </div>
          <div class="smp-grp">
            <SetRow title={t("smpTheme")} stack>
              <Seg
                label={t("smpTheme")}
                value={theme.value}
                onChange={setTheme}
                options={[
                  ["system", [<IconMonitor key="m" size={15} />, " ", t("themeSystem")]],
                  ["light", [<IconSun key="s" size={15} />, " ", t("themeLight")]],
                  ["dark", [<IconMoon key="d" size={15} />, " ", t("themeDark")]],
                ]}
              />
            </SetRow>
            <SetRow title={t("smpColour")} stack>
              <AccentPicker />
            </SetRow>
            <SetRow title={t("smpLanguage")} stack>
              <Seg
                label={t("smpLanguage")}
                value={lang.value}
                onChange={(l) => {
                  setLang(l);
                  void attempt(() => getApi().setupLanguages({ language: l }));
                }}
                options={[
                  ["it", "Italiano"],
                  ["en", "English"],
                ]}
              />
            </SetRow>
          </div>
          <div class="smp-grp">
            <SetRow title={t("smpFullView")} help={t("smpFullViewHelp")}>
              <Switch on={false} label={t("smpFullView")} onChange={() => setUiMode("full")} />
            </SetRow>
            <SetRow title={t("smpSignOut")} onClick={() => signOut()} />
          </div>
        </div>
      </div>
      {telegram && (
        <Modal title={t("telegram")} onClose={() => setTelegram(false)} wide>
          <Telegram />
        </Modal>
      )}
    </div>
  );
}
