// Settings › Portrait («Mirror», 3.9.4; the person: «Il ritratto è una figata»): how the agents
// see the person, built by itself from the conversations. The traits grouped, each with where it
// comes from (its conversation opens), «Change», «Remove», «Not true»; a switch for the whole
// thing, which agents read it, the exact text they read, and «Forget everything».
import {
  PORTRAIT_CATEGORIES,
  type PortraitAgents,
  type PortraitCategory,
  type PortraitTrait,
  type PortraitView,
} from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import { ApiError } from "../api.js";
import { lang, t, tOptional } from "../i18n.js";
import { IconEye, IconPencil, IconPlus, IconTrash, IconX } from "../icons.js";
import { getApi, openSession } from "../state.js";
import { askConfirm } from "./dialogs.js";
import { Acts, Chips, Head, Sub, SwitchRow, WzPage } from "./SettingsKit.js";
import { Modal } from "./ui.js";

const portraitError = (err: unknown) =>
  (err instanceof ApiError && err.code && tOptional(`err_${err.code}`)) || (err as Error).message;

const day = (iso: string) =>
  new Date(iso).toLocaleDateString(lang.value === "it" ? "it-IT" : "en-US", {
    day: "numeric",
    month: "short",
    year: new Date(iso).getFullYear() === new Date().getFullYear() ? undefined : "numeric",
  });

export const categoryWords = (c: PortraitCategory) => t(`prCat_${c}`);

/** How sure, in words. */
export function sureWords(tr: PortraitTrait): string {
  if (tr.edited) return t("prByYou");
  if (tr.confidence >= 0.7) return t("prSure");
  if (tr.confidence >= 0.35) return t("prLikely");
  return t("prUnsure");
}

const categoryChips = () => PORTRAIT_CATEGORIES.map((c) => ({ id: c, label: categoryWords(c) }));

function Trait({
  tr,
  onEdit,
  onRemove,
  onDeny,
  onSources,
}: {
  tr: PortraitTrait;
  onEdit: () => void;
  onRemove: () => void;
  onDeny: () => void;
  onSources: () => void;
}) {
  return (
    <li class="mem-item pr-item" data-trait={tr.id}>
      <p class="mem-text">{tr.text}</p>
      <div class="mem-meta">
        <span>
          <span class={`pr-sure${tr.edited || tr.confidence >= 0.7 ? " on" : ""}`}>
            {sureWords(tr)}
          </span>
          {" · "}
          {tr.confirmations > 0
            ? t("prSeen", { n: String(tr.confirmations + 1) })
            : t("prSeenOnce")}
          {" · "}
          {day(tr.seenAt)}
          {tr.sources.length > 0 && (
            <>
              {" · "}
              <button type="button" class="wz-link mem-from" onClick={onSources}>
                {t("prWhere")}
              </button>
            </>
          )}
        </span>
        <span class="mem-acts">
          <button type="button" class="wz-btn small quiet" onClick={onEdit}>
            <IconPencil size={16} />
            {t("prEdit")}
          </button>
          <button type="button" class="wz-btn small quiet" onClick={onRemove}>
            <IconTrash size={16} />
            {t("prRemove")}
          </button>
          <button type="button" class="wz-btn small quiet mem-forget" onClick={onDeny}>
            <IconX size={16} />
            {t("prDeny")}
          </button>
        </span>
      </div>
    </li>
  );
}

/** «Where it comes from»: each conversation that showed it, newest first; one click opens it. */
function SourcesWindow({ tr, onClose }: { tr: PortraitTrait; onClose: () => void }) {
  return (
    <Modal title={t("prWhereTitle")} onClose={onClose}>
      <div class="wz-panel-in mem-edit">
        <p class="mem-forget-quote">{tr.text}</p>
        <ul class="pr-sources">
          {tr.sources.map((x) => (
            <li key={x.sessionId}>
              {x.agentId ? (
                <button
                  type="button"
                  class="wz-link"
                  onClick={() => {
                    onClose();
                    openSession({
                      id: x.sessionId,
                      agentId: x.agentId as string,
                      title: x.sessionTitle ?? null,
                    });
                  }}
                >
                  {x.sessionTitle ? `«${x.sessionTitle}»` : t("prUntitled")}
                </button>
              ) : (
                <span>{x.sessionTitle ? `«${x.sessionTitle}»` : t("prUntitled")}</span>
              )}
              <small>
                {x.agentName ? `${t("prWith", { name: x.agentName })} · ` : ""}
                {day(x.at)}
              </small>
            </li>
          ))}
        </ul>
      </div>
      <Acts>
        <button type="button" class="wz-btn" onClick={onClose}>
          {t("close")}
        </button>
      </Acts>
    </Modal>
  );
}

function EditWindow({ tr, onClose }: { tr: PortraitTrait; onClose: (saved: boolean) => void }) {
  const [text, setText] = useState(tr.text);
  const [cat, setCat] = useState<PortraitCategory>(tr.category);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();
  const save = async () => {
    setBusy(true);
    setError(undefined);
    try {
      await getApi().editTrait(tr.id, { text, category: cat });
      onClose(true);
    } catch (err) {
      setError(portraitError(err));
    } finally {
      setBusy(false);
    }
  };
  return (
    <Modal title={t("prEditTitle")} onClose={() => onClose(false)}>
      <div class="wz-panel-in mem-edit">
        <textarea
          class="wz-field"
          rows={3}
          maxLength={200}
          aria-label={t("prEditTitle")}
          value={text}
          onInput={(e) => setText((e.target as HTMLTextAreaElement).value)}
        />
        <Chips
          wrap
          options={categoryChips()}
          value={[cat]}
          onChange={(v) => v[0] && setCat(v[0])}
        />
        <p class="wz-lead2">{t("prEditNote")}</p>
        {error && <p class="mem-error">{error}</p>}
      </div>
      <Acts>
        <button type="button" class="wz-btn" onClick={() => onClose(false)}>
          {t("cancel")}
        </button>
        <button
          type="button"
          class="wz-btn primary"
          disabled={busy || !text.trim()}
          onClick={() => void save()}
        >
          {t("save")}
        </button>
      </Acts>
    </Modal>
  );
}

const AGENT_ROWS: (keyof PortraitAgents)[] = ["god", "orchestrators", "chat", "others"];

/** Settings › Portrait. */
export function PortraitPage() {
  const [v, setV] = useState<PortraitView>();
  const [error, setError] = useState<string>();
  const [text, setText] = useState("");
  const [cat, setCat] = useState<PortraitCategory>("preference");
  const [editing, setEditing] = useState<PortraitTrait | null>(null);
  const [sources, setSources] = useState<PortraitTrait | null>(null);
  const [showText, setShowText] = useState(false);
  const load = () =>
    getApi()
      .portrait()
      .then(setV, (err) => setError(portraitError(err)));
  useEffect(() => {
    void load();
  }, []);
  const run = async (f: () => Promise<unknown>) => {
    setError(undefined);
    try {
      await f();
      await load();
      return true;
    } catch (err) {
      setError(portraitError(err));
      return false;
    }
  };
  if (!v) return <WzPage>{error && <p class="mem-error">{error}</p>}</WzPage>;
  const add = async () => {
    if (!text.trim()) return;
    if (await run(() => getApi().addTrait(text, cat))) setText("");
  };
  const forget = async () => {
    const yes = await askConfirm(t("prForgetTitle"), {
      text: t("prForgetText"),
      yes: t("prForget"),
      danger: true,
    });
    if (yes) await run(() => getApi().forgetPortrait());
  };
  const groups = PORTRAIT_CATEGORIES.map((c) => ({
    c,
    traits: v.traits.filter((x) => x.category === c),
  })).filter((g) => g.traits.length > 0);
  return (
    <WzPage
      class="mem-page pr-page"
      after={
        <>
          {editing && (
            <EditWindow
              key={editing.id}
              tr={editing}
              onClose={(saved) => {
                setEditing(null);
                if (saved) void load();
              }}
            />
          )}
          {sources && (
            <SourcesWindow key={sources.id} tr={sources} onClose={() => setSources(null)} />
          )}
        </>
      }
    >
      <Head eyebrow={t("prEyebrow")} q={t("prTitle")} lead={t("prLead")} />

      <div class="mem-block">
        <SwitchRow
          title={t("prOnTitle")}
          help={v.on ? t("prOnOn") : t("prOnOff")}
          on={v.on}
          onChange={(on) => void run(() => getApi().setPortrait({ on }))}
        />
      </div>

      <Sub title={t("prWhoTitle")} lead={t("prWhoLead")} />
      <div class="mem-block pr-who">
        {AGENT_ROWS.map((k) => (
          <SwitchRow
            key={k}
            title={t(`prWho_${k}`)}
            on={v.agents[k]}
            disabled={!v.on}
            onChange={(on) =>
              void run(() => getApi().setPortrait({ agents: { ...v.agents, [k]: on } }))
            }
          />
        ))}
      </div>

      <Sub
        title={`${t("prListTitle")} · ${v.traits.length === 1 ? t("prCountOne") : t("prCount", { n: String(v.traits.length) })}`}
        lead={t("prListLead")}
      />
      <div class="wz-card wz-left mem-box">
        <form
          class="mem-add"
          onSubmit={(e) => {
            e.preventDefault();
            void add();
          }}
        >
          <input
            class="wz-field"
            maxLength={200}
            enterkeyhint="done"
            aria-label={t("prAddPlaceholder")}
            placeholder={t("prAddPlaceholder")}
            value={text}
            onInput={(e) => setText((e.target as HTMLInputElement).value)}
          />
          <button type="submit" class="wz-btn primary" disabled={!text.trim()}>
            <IconPlus size={18} />
            {t("prAdd")}
          </button>
        </form>
        {text.trim() && (
          <Chips
            wrap
            options={categoryChips()}
            value={[cat]}
            onChange={(x) => x[0] && setCat(x[0])}
          />
        )}
        {error && <p class="mem-error">{error}</p>}
        {groups.length === 0 ? (
          <p class="mem-empty">{v.on ? t("prEmpty") : t("prEmptyOff")}</p>
        ) : (
          groups.map((g) => (
            <section class="pr-group" key={g.c}>
              <h4 class="pr-group-title">{categoryWords(g.c)}</h4>
              <ul class="mem-list">
                {g.traits.map((tr) => (
                  <Trait
                    key={tr.id}
                    tr={tr}
                    onEdit={() => setEditing(tr)}
                    onRemove={() => void run(() => getApi().removeTrait(tr.id))}
                    onDeny={() => void run(() => getApi().denyTrait(tr.id))}
                    onSources={() => setSources(tr)}
                  />
                ))}
              </ul>
            </section>
          ))
        )}
        {v.denied > 0 && (
          <p class="mem-note">
            {v.denied === 1 ? t("prDeniedOne") : t("prDenied", { n: String(v.denied) })}
          </p>
        )}
      </div>

      {v.text && (
        <>
          <Sub title={t("prTextTitle")} lead={t("prTextLead")} />
          <div class="wz-card wz-left mem-box">
            <button type="button" class="wz-btn small" onClick={() => setShowText(!showText)}>
              <IconEye size={16} />
              {showText ? t("prTextHide") : t("prTextShow")}
            </button>
            {showText && <pre class="pr-text">{v.text}</pre>}
          </div>
        </>
      )}

      <Sub title={t("prForgetTitle")} lead={t("prForgetLead")} />
      <div class="mem-block">
        <button
          type="button"
          class="wz-btn mem-forget"
          disabled={v.traits.length === 0 && v.denied === 0}
          onClick={() => void forget()}
        >
          <IconTrash size={16} />
          {t("prForget")}
        </button>
      </div>
    </WzPage>
  );
}
