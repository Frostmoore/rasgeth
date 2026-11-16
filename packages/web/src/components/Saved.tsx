// «Salva» and «Salvati» (G40.14): a part of a message (selected) or a whole one goes into the
// person's own archive, with a note and tags if they like; the archive is a tab of its own, opened
// from the Chat's page: newest first, search, filters by tag and agent, the way back to the
// conversation at the right point, the note edited, deletion with a confirmation, Markdown export.
import { signal } from "@preact/signals";
import {
  normalizeTags,
  SAVED_NOTE_MAX,
  type SavedCreateBody,
  type SavedItem,
  type SavedList,
} from "@redgiant/protocol";
import { useEffect, useRef, useState } from "preact/hooks";
import { lang, t } from "../i18n.js";
import {
  IconBookmark,
  IconCheck,
  IconDownload,
  IconExternal,
  IconPencil,
  IconSearch,
  IconSpinner,
  IconTag,
  IconTrash,
} from "../icons.js";
import { renderMarkdown } from "../markdown.js";
import {
  agents,
  attempt,
  getApi,
  openSaved,
  openSession,
  openTab,
  pendingJump,
  sessionRows,
} from "../state.js";
import { askConfirm } from "./dialogs.js";
import { Modal, Pick } from "./ui.js";

/** What «Salva» is about to keep: where it is, and the passage as the person sees it. */
export type SaveDraft = {
  body: Omit<SavedCreateBody, "note" | "tags">;
  /** The passage as shown in the window (the whole message's text, for a whole one). */
  preview: string;
};

/** The «Salva» window: one for the whole page, opened by setting this. */
export const saveDraft = signal<SaveDraft | null>(null);

/** «Salva» on a whole message of the model (its menu under the bubble). */
export function SaveMessage({ draft }: { draft: SaveDraft }) {
  return (
    <button
      type="button"
      class="link msg-action"
      title={t("savedSaveMessageHint")}
      onClick={() => (saveDraft.value = draft)}
    >
      <IconBookmark size={13} />
      {t("savedSave")}
    </button>
  );
}

/** Tags typed with commas: the ones already chosen plus the new ones, each once. */
const withTyped = (chosen: string[], typed: string) =>
  normalizeTags([...chosen, ...typed.split(",")]);

function TagPicker({
  chosen,
  known,
  typed,
  onChosen,
  onTyped,
}: {
  chosen: string[];
  known: string[];
  typed: string;
  onChosen: (tags: string[]) => void;
  onTyped: (s: string) => void;
}) {
  const all = normalizeTags([...known, ...chosen]);
  return (
    <div class="saved-tags-edit">
      {all.length > 0 && (
        <div class="saved-tag-picks">
          {all.map((tag) => {
            const on = chosen.some((c) => c.toLowerCase() === tag.toLowerCase());
            return (
              <Pick
                key={tag}
                small
                on={on}
                onChange={(v) =>
                  onChosen(
                    v
                      ? normalizeTags([...chosen, tag])
                      : chosen.filter((c) => c.toLowerCase() !== tag.toLowerCase()),
                  )
                }
              >
                {tag}
              </Pick>
            );
          })}
        </div>
      )}
      <input
        type="text"
        value={typed}
        placeholder={t("savedTagsPlaceholder")}
        aria-label={t("savedTags")}
        onInput={(e) => onTyped((e.target as HTMLInputElement).value)}
      />
    </div>
  );
}

/** The window «Salva»: the passage, a note and tags (both optional), then «Salvato». */
export function SaveDialogHost() {
  const draft = saveDraft.value;
  if (!draft) return null;
  return (
    <div class="wz-look">
      <SaveDialog key={JSON.stringify(draft.body)} draft={draft} />
    </div>
  );
}

function SaveDialog({ draft }: { draft: SaveDraft }) {
  const [note, setNote] = useState("");
  const [chosen, setChosen] = useState<string[]>([]);
  const [typed, setTyped] = useState("");
  const [known, setKnown] = useState<string[]>([]);
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string>();
  const close = () => (saveDraft.value = null);
  useEffect(() => {
    void getApi()
      .savedList({ limit: 1 })
      .then(
        (l) => setKnown(l.tags.map((x) => x.tag)),
        () => {},
      );
  }, []);
  const save = async () => {
    setBusy(true);
    setError(undefined);
    try {
      const tags = withTyped(chosen, typed);
      await getApi().saveItem({
        ...draft.body,
        ...(note.trim() && { note: note.trim() }),
        ...(tags.length > 0 && { tags }),
      });
      setDone(true);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  };
  if (done)
    return (
      <Modal
        title={t("savedDoneTitle")}
        onClose={close}
        icon={<IconCheck size={18} />}
        foot={
          <div class="saved-foot">
            <button type="button" class="wz-btn quiet" onClick={close}>
              {t("close")}
            </button>
            <button
              type="button"
              class="wz-btn primary"
              onClick={() => {
                close();
                openSaved();
              }}
            >
              {t("savedOpenArchive")}
            </button>
          </div>
        }
      >
        <p class="ui-help">{t("savedDoneText")}</p>
      </Modal>
    );
  return (
    <Modal
      title={draft.body.text ? t("savedSaveTitle") : t("savedSaveMessageTitle")}
      onClose={close}
      icon={<IconBookmark size={18} />}
      foot={
        <div class="saved-foot">
          <button type="button" class="wz-btn quiet" onClick={close}>
            {t("cancel")}
          </button>
          <button type="button" class="wz-btn primary" disabled={busy} onClick={() => void save()}>
            {busy ? <IconSpinner size={13} /> : <IconBookmark size={13} />} {t("savedSave")}
          </button>
        </div>
      }
    >
      <div class="saved-dialog">
        <blockquote class="saved-preview">{draft.preview}</blockquote>
        <label class="ui-field">
          <span class="ui-label">{t("savedNote")}</span>
          <textarea
            rows={3}
            maxLength={SAVED_NOTE_MAX}
            value={note}
            placeholder={t("savedNotePlaceholder")}
            onInput={(e) => setNote((e.target as HTMLTextAreaElement).value)}
          />
        </label>
        <div class="ui-field">
          <span class="ui-label">{t("savedTags")}</span>
          <TagPicker
            chosen={chosen}
            known={known}
            typed={typed}
            onChosen={setChosen}
            onTyped={setTyped}
          />
        </div>
        {error && <p class="notice error">{error}</p>}
      </div>
    </Modal>
  );
}

const when = (iso: string | null) =>
  iso
    ? new Date(iso).toLocaleString(lang.value, {
        day: "numeric",
        month: "short",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      })
    : "";

/** Back to where a saved passage comes from: the conversation opens and the passage lights up. */
export function openSavedSource(item: SavedItem): boolean {
  const s = item.source;
  if (s.kind === "session") {
    const agentId = s.agentId ?? sessionRows.value.find((r) => r.id === s.sessionId)?.agentId;
    if (!agentId) return false;
    pendingJump.value = {
      sessionId: s.sessionId,
      seq: s.seq,
      ...(s.start !== undefined && { start: s.start }),
      ...(s.end !== undefined && { end: s.end }),
      text: item.text,
    };
    openSession({ id: s.sessionId, agentId, title: s.title });
    return true;
  }
  pendingJump.value = { chatId: s.chatId, messageId: s.messageId, text: item.text };
  openTab({ id: `daily:${s.chatId}`, type: "dailychat", title: s.title ?? "", chatId: s.chatId });
  return true;
}

function SavedCard({
  item,
  known,
  onChanged,
  onRemoved,
}: {
  item: SavedItem;
  known: string[];
  onChanged: (i: SavedItem) => void;
  onRemoved: (id: string) => void;
}) {
  const [editing, setEditing] = useState(false);
  const [note, setNote] = useState(item.note);
  const [chosen, setChosen] = useState(item.tags);
  const [typed, setTyped] = useState("");
  const s = item.source;
  const agentName =
    (s.agentId && agents.value.find((a) => a.id === s.agentId)?.name) || s.agentName || null;
  const from = [s.title, agentName].filter(Boolean).join(" · ") || t("savedUnknownOrigin");
  const save = async () => {
    const r = await attempt(() =>
      getApi().updateSaved(item.id, { note, tags: withTyped(chosen, typed) }),
    );
    if (!r) return;
    onChanged(r);
    setTyped("");
    setEditing(false);
  };
  const remove = async () => {
    const yes = await askConfirm(t("savedDeleteTitle"), {
      text: t("savedDeleteText"),
      yes: t("savedDelete"),
      danger: true,
    });
    if (!yes) return;
    if (await attempt(() => getApi().deleteSaved(item.id))) onRemoved(item.id);
  };
  return (
    <article class="saved-card" data-id={item.id}>
      <header class="saved-origin">
        <IconBookmark size={13} />
        <strong>{from}</strong>
        <span class="dim">{when(s.messageAt ?? item.createdAt)}</span>
        {item.whole && <span class="chip muted">{t("savedWhole")}</span>}
      </header>
      {item.markdown ? (
        <div
          class="md saved-body"
          // Sanitised: every rendered Markdown goes through DOMPurify.
          dangerouslySetInnerHTML={{ __html: renderMarkdown(item.markdown) }}
        />
      ) : (
        <div class="saved-body saved-plain">{item.text}</div>
      )}
      {editing ? (
        <div class="saved-edit">
          <label class="ui-field">
            <span class="ui-label">{t("savedNote")}</span>
            <textarea
              rows={3}
              maxLength={SAVED_NOTE_MAX}
              value={note}
              placeholder={t("savedNotePlaceholder")}
              onInput={(e) => setNote((e.target as HTMLTextAreaElement).value)}
            />
          </label>
          <div class="ui-field">
            <span class="ui-label">{t("savedTags")}</span>
            <TagPicker
              chosen={chosen}
              known={known}
              typed={typed}
              onChosen={setChosen}
              onTyped={setTyped}
            />
          </div>
          <div class="saved-foot">
            <button
              type="button"
              class="wz-btn small quiet"
              onClick={() => {
                setNote(item.note);
                setChosen(item.tags);
                setTyped("");
                setEditing(false);
              }}
            >
              {t("cancel")}
            </button>
            <button type="button" class="wz-btn small primary" onClick={() => void save()}>
              {t("save")}
            </button>
          </div>
        </div>
      ) : (
        <>
          {item.note && <p class="saved-note">{item.note}</p>}
          {item.tags.length > 0 && (
            <div class="saved-tags">
              {item.tags.map((tag) => (
                <span key={tag} class="chip">
                  <IconTag size={11} /> {tag}
                </span>
              ))}
            </div>
          )}
        </>
      )}
      <footer class="saved-actions">
        <span class="dim">{t("savedOn", { when: when(item.createdAt) })}</span>
        <div class="spacer" />
        <button type="button" class="link msg-action" onClick={() => openSavedSource(item)}>
          <IconExternal size={13} /> {t("savedOpen")}
        </button>
        {!editing && (
          <button type="button" class="link msg-action" onClick={() => setEditing(true)}>
            <IconPencil size={13} /> {t("savedEdit")}
          </button>
        )}
        <button type="button" class="link msg-action danger" onClick={() => void remove()}>
          <IconTrash size={13} /> {t("savedDelete")}
        </button>
      </footer>
    </article>
  );
}

const download = (blob: Blob, name: string) => {
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = name;
  a.click();
  URL.revokeObjectURL(a.href);
};

/** «Salvati»: the person's archive, a tab of its own. */
export function SavedPage() {
  const [q, setQ] = useState("");
  const [query, setQuery] = useState("");
  const [tag, setTag] = useState<string | null>(null);
  const [agentId, setAgentId] = useState<string | null>(null);
  const [list, setList] = useState<SavedList | null>(null);
  const [loading, setLoading] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined);
  const filters = {
    ...(query && { q: query }),
    ...(tag && { tag }),
    ...(agentId && { agentId }),
  };
  const load = async (more = false) => {
    setLoading(true);
    const before = more ? list?.items.at(-1)?.createdAt : undefined;
    const r = await attempt(() =>
      getApi().savedList({ ...filters, ...(before && { before }), limit: 50 }),
    );
    setLoading(false);
    if (!r) return;
    setList(more && list ? { ...r, items: [...list.items, ...r.items] } : r);
  };
  useEffect(() => {
    void load();
  }, [query, tag, agentId]);
  useEffect(() => () => clearTimeout(timer.current), []);
  const known = list?.tags.map((x) => x.tag) ?? [];
  const filtered = Boolean(query || tag || agentId);
  return (
    <div class="saved-page wz-look">
      <header>
        <div class="chats-title">
          <IconBookmark size={22} />
          <h1>{t("savedTitle")}</h1>
        </div>
        <p class="ui-help">{t("savedHint")}</p>
      </header>
      <div class="saved-bar">
        <label class="saved-search">
          <IconSearch size={15} />
          <input
            type="search"
            value={q}
            placeholder={t("savedSearch")}
            aria-label={t("savedSearch")}
            onInput={(e) => {
              const v = (e.target as HTMLInputElement).value;
              setQ(v);
              clearTimeout(timer.current);
              timer.current = setTimeout(() => setQuery(v.trim()), 250);
            }}
          />
        </label>
        <button
          type="button"
          class="wz-btn small quiet"
          disabled={!list || list.items.length === 0}
          onClick={() =>
            void attempt(() =>
              getApi().exportSaved(filters, lang.value === "it" ? "it" : "en"),
            ).then((b) => b && download(b, `${lang.value === "it" ? "salvati" : "saved"}.md`))
          }
        >
          <IconDownload size={14} /> {t("savedExport")}
        </button>
      </div>
      {list && (list.tags.length > 0 || list.agents.length > 1) && (
        <div class="saved-filters">
          {list.tags.length > 0 && (
            <fieldset class="saved-filter">
              <legend class="ui-label">{t("savedTags")}</legend>
              {list.tags.map((x) => (
                <Pick
                  key={x.tag}
                  small
                  on={tag?.toLowerCase() === x.tag.toLowerCase()}
                  onChange={(on) => setTag(on ? x.tag : null)}
                >
                  {x.tag} <span class="dim">{x.count}</span>
                </Pick>
              ))}
            </fieldset>
          )}
          {list.agents.length > 1 && (
            <fieldset class="saved-filter">
              <legend class="ui-label">{t("savedAgents")}</legend>
              {list.agents.map((a) => (
                <Pick
                  key={a.id}
                  small
                  on={agentId === a.id}
                  onChange={(on) => setAgentId(on ? a.id : null)}
                >
                  {a.name} <span class="dim">{a.count}</span>
                </Pick>
              ))}
            </fieldset>
          )}
        </div>
      )}
      {list && list.items.length === 0 && (
        <p class="saved-empty dim">{filtered ? t("savedNoMatch") : t("savedEmpty")}</p>
      )}
      <div class="saved-list">
        {list?.items.map((item) => (
          <SavedCard
            key={item.id}
            item={item}
            known={known}
            onChanged={(n) =>
              setList((l) => l && { ...l, items: l.items.map((x) => (x.id === n.id ? n : x)) })
            }
            onRemoved={(id) => {
              setList((l) => l && { ...l, items: l.items.filter((x) => x.id !== id) });
              // The filters' counts move too.
              void getApi()
                .savedList({ ...filters, limit: 1 })
                .then(
                  (r) => setList((l) => l && { ...l, tags: r.tags, agents: r.agents }),
                  () => {},
                );
            }}
          />
        ))}
      </div>
      {list?.more && (
        <button
          type="button"
          class="wz-btn small quiet saved-more"
          disabled={loading}
          onClick={() => void load(true)}
        >
          {t("savedMore")}
        </button>
      )}
      {loading && !list && (
        <p class="dim">
          <IconSpinner size={13} /> {t("loading")}
        </p>
      )}
    </div>
  );
}
