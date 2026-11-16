// Every chat (2026-11-03): opened from the green button in the left bar. The chats as cards, in
// their folders, a card to start a new one, and the group chats with several agents. A chat is
// a conversation with the Chat's agent (every tool, the canvas, the progress line); the chats
// made before it are kept below, as they were.
import { useEffect, useState } from "preact/hooks";
import type { ChatSummary } from "../api.js";
import { t } from "../i18n.js";
import {
  IconArchive,
  IconBookmark,
  IconChat,
  IconFolder,
  IconPencil,
  IconPlus,
  IconUsers,
} from "../icons.js";
import {
  agents,
  attempt,
  chatAgentId,
  chatRows,
  getApi,
  openSaved,
  openSession,
  openTab,
  refresh,
  refreshConversations,
  rooms,
  type SessionRow,
  sessionRows,
} from "../state.js";
import { FolderMenu } from "./FolderMenu.js";
import { Mascot } from "./Mascot.js";
import { PromptEditor } from "./PromptEditor.js";
import { Modal } from "./ui.js";

const when = (iso: string) =>
  new Date(iso).toLocaleString([], {
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });

function ChatCard({ c, folders }: { c: ChatSummary; folders: string[] }) {
  return (
    <div class="chat-card">
      <button
        type="button"
        class="chat-card-open"
        onClick={() =>
          openTab({ id: `daily:${c.id}`, type: "dailychat", title: c.title, chatId: c.id })
        }
      >
        <IconChat size={16} />
        <strong>{c.title}</strong>
        <small>{when(c.updatedAt)}</small>
      </button>
      <FolderMenu
        current={c.folder ?? null}
        folders={folders}
        onPick={(f) =>
          void attempt(() => getApi().setChatFolder(c.id, f)).then(refreshConversations)
        }
      />
    </div>
  );
}

/** A conversation with the Chat's agent, as a card. */
function SessionCard({ r, folders }: { r: SessionRow; folders: string[] }) {
  return (
    <div class="chat-card">
      <button type="button" class="chat-card-open" onClick={() => openSession(r)}>
        <IconChat size={16} />
        <strong>{r.title ?? t("newChat")}</strong>
        {r.running && <span class="dot running" />}
      </button>
      {!r.archived && (
        <FolderMenu
          current={r.folder ?? null}
          folders={folders}
          onPick={(f) =>
            void attempt(() => getApi().updateSession(r.id, { folder: f })).then(
              refreshConversations,
            )
          }
        />
      )}
      {/* Archived (2026-11-15): out of the list, read and brought back from «Archived». */}
      <button
        type="button"
        class="icon-button"
        title={r.archived ? t("unarchive") : t("archive")}
        aria-label={r.archived ? t("unarchive") : t("archive")}
        onClick={() =>
          void attempt(() => getApi().updateSession(r.id, { archived: !r.archived })).then(
            refreshConversations,
          )
        }
      >
        <IconArchive size={15} />
      </button>
    </div>
  );
}

export function Chats() {
  const [error, setError] = useState<string>();
  const [instructions, setInstructions] = useState(false);
  const [showArchived, setShowArchived] = useState(false);
  useEffect(() => {
    void refreshConversations().catch(() => {});
    void getApi()
      .chatAgent()
      .then(
        (a) => {
          chatAgentId.value = a.id;
          return refresh();
        },
        (e: unknown) => setError((e as Error).message),
      );
  }, []);
  const all = sessionRows.value.filter((r) => r.agentId === chatAgentId.value);
  const mine = all.filter((r) => !r.archived);
  const archived = all.filter((r) => r.archived);
  const old = chatRows.value;
  const folders = [
    ...new Set([...mine, ...old].flatMap((c) => (c.folder ? [c.folder] : []))),
  ].sort();
  const newChat = () =>
    void attempt(async () => {
      const id = chatAgentId.value ?? (await getApi().chatAgent()).id;
      const { sessionId } = await getApi().startSession(id);
      await refreshConversations();
      openSession({ id: sessionId, agentId: id, title: null });
    });
  const chatAgent = agents.value.find((a) => a.id === chatAgentId.value);
  return (
    <div class="chats-page">
      <header>
        <div class="chats-title">
          {chatAgent && <Mascot agent={chatAgent} size={48} />}
          <h1>{t("dailyChat")}</h1>
        </div>
        <p class="ui-help">{t("chatHint")}</p>
        {error && <p class="notice error">{error}</p>}
        <div class="chats-head-actions">
          <button type="button" class="chats-prompt" onClick={() => setInstructions(true)}>
            <IconPencil size={15} /> {t("chatInstructions")}
          </button>
          {/* The person's saved passages (G40.14): kept from the conversations, a tab of its own. */}
          <button type="button" class="chats-prompt chats-saved" onClick={openSaved}>
            <IconBookmark size={15} /> {t("savedTitle")}
          </button>
        </div>
      </header>
      {/* The Chat's instructions, built-in or its own (2026-11-06). */}
      {instructions && (
        <div class="wz-look">
          <Modal wide title={t("chatInstructions")} onClose={() => setInstructions(false)}>
            <PromptEditor
              load={() => getApi().chatPrompt()}
              save={(text) => getApi().setChatPrompt(text)}
              target={{ chat: true }}
            />
          </Modal>
        </div>
      )}
      <div class="chat-grid">
        <button type="button" class="chat-card chat-card-new" onClick={newChat}>
          <IconPlus size={18} /> {t("newChat")}
        </button>
        {mine
          .filter((r) => !r.folder)
          .map((r) => (
            <SessionCard key={r.id} r={r} folders={folders} />
          ))}
      </div>
      {folders.map((f) => (
        <section key={f} class="chats-folder">
          <h2>
            <IconFolder size={15} /> {f}
          </h2>
          <div class="chat-grid">
            {mine
              .filter((r) => r.folder === f)
              .map((r) => (
                <SessionCard key={r.id} r={r} folders={folders} />
              ))}
            {old
              .filter((c) => c.folder === f)
              .map((c) => (
                <ChatCard key={c.id} c={c} folders={folders} />
              ))}
          </div>
        </section>
      ))}
      {old.some((c) => !c.folder) && (
        <section class="chats-folder">
          <h2>
            <IconChat size={15} /> {t("chatsBefore")}
          </h2>
          <div class="chat-grid">
            {old
              .filter((c) => !c.folder)
              .map((c) => (
                <ChatCard key={c.id} c={c} folders={folders} />
              ))}
          </div>
        </section>
      )}
      {archived.length > 0 && (
        <section class="chats-folder">
          <button
            type="button"
            class="chats-archived-toggle"
            aria-expanded={showArchived}
            onClick={() => setShowArchived(!showArchived)}
          >
            <IconArchive size={15} /> {t("chatsArchived", { n: String(archived.length) })}
          </button>
          {showArchived && (
            <div class="chat-grid">
              {archived.map((r) => (
                <SessionCard key={r.id} r={r} folders={folders} />
              ))}
            </div>
          )}
        </section>
      )}
      <section class="chats-folder">
        <h2>
          <IconUsers size={15} /> {t("groups")}
        </h2>
        <p class="ui-help">{t("groupsEmpty")}</p>
        <div class="chat-grid">
          <button
            type="button"
            class="chat-card chat-card-new"
            onClick={() =>
              void attempt(() => getApi().createRoom({ members: [], title: t("groupNew") })).then(
                async (r) => {
                  if (!r) return;
                  await refresh();
                  openTab({ id: `room:${r.id}`, type: "room", title: r.title, roomId: r.id });
                },
              )
            }
          >
            <IconPlus size={18} /> {t("groupNew")}
          </button>
          {rooms.value.map((r) => (
            <div key={r.id} class="chat-card">
              <button
                type="button"
                class="chat-card-open"
                onClick={() =>
                  openTab({ id: `room:${r.id}`, type: "room", title: r.title, roomId: r.id })
                }
              >
                <IconUsers size={16} />
                <strong>{r.title}</strong>
                {r.answering.length > 0 && <span class="dot running" />}
              </button>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
