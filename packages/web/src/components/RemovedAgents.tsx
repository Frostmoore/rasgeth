// Removing an agent (p3.8.9, the person: «dai anche a God la possibilità di rimuovere gli agenti»).
// The window that says what goes before it does (who below goes with it, the turns that stop, the
// tasks that close), the «Removed agents» section with «Restore» and each one's conversations,
// read only, and the line that takes the composer's place in them. Nothing is deleted.
import { useEffect, useState } from "preact/hooks";
import type { Agent, RemovedAgent, RemovePreview, SessionInfo } from "../api.js";
import { explain } from "../explain.js";
import { t } from "../i18n.js";
import { IconChat, IconRestore, IconTrash } from "../icons.js";
import {
  chatAgentId,
  getApi,
  openSession,
  projects,
  refreshTeam,
  removalOf,
  removedAgents,
} from "../state.js";
import { Mascot } from "./Mascot.js";
import { Acts } from "./SettingsKit.js";
import { Modal } from "./ui.js";

const day = (iso: string) =>
  new Date(iso).toLocaleString([], {
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
const projectName = (id: string | null) =>
  (id && projects.value.find((p) => p.id === id)?.name) || id || "";

/** Whether the page offers «Remove» for it: never God, Demi-God or the Chat (the server agrees). */
export const removable = (a: Agent) =>
  a.kind !== "god" && a.kind !== "demigod" && a.id !== chatAgentId.value;

/** Brings a removal back (with those removed with it): an error in words, or nothing. */
export async function restoreRemoved(r: { id: string }): Promise<string | undefined> {
  try {
    await getApi().restoreAgent(r.id);
    await refreshTeam();
    return undefined;
  } catch (err) {
    return explain(err);
  }
}

/**
 * «Remove»: first what goes with it (from the server: those below it, the open tasks, the turns at
 * work), then the person's yes in our window. The agent moves to «Removed agents».
 */
export function RemoveAgentDialog({
  agent,
  onClose,
}: {
  agent: Agent;
  onClose: (removed: boolean) => void;
}) {
  const [preview, setPreview] = useState<RemovePreview>();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string>();
  useEffect(() => {
    void getApi()
      .removePreview(agent.id)
      .then(setPreview, (err) => setError(explain(err)));
  }, [agent.id]);
  const remove = async () => {
    setBusy(true);
    setError(undefined);
    try {
      await getApi().removeAgent(agent.id);
      await refreshTeam();
      onClose(true);
    } catch (err) {
      setError(explain(err));
      setBusy(false);
    }
  };
  const others = preview?.with ?? [];
  const allowed = preview?.allowed !== false;
  return (
    <Modal
      title={t("raAskTitle", { name: agent.name })}
      icon={<Mascot agent={agent} size={40} decorative />}
      onClose={() => onClose(false)}
      foot={
        <Acts>
          <button type="button" class="wz-btn" disabled={busy} onClick={() => onClose(false)}>
            {t("cancel")}
          </button>
          {allowed && (
            <button
              type="button"
              class="wz-btn primary danger"
              disabled={busy || !preview}
              onClick={() => void remove()}
            >
              <IconTrash size={16} />{" "}
              {others.length > 0 ? t("raRemoveN", { n: String(others.length + 1) }) : t("raRemove")}
            </button>
          )}
        </Acts>
      }
    >
      <div class="wz-panel-in ra-ask">
        {!preview && !error && <p class="dim">{t("loading")}</p>}
        {preview && !allowed && (
          <p class="notice warn" role="alert">
            {t("raNotAllowed", { name: agent.name })}
          </p>
        )}
        {preview && allowed && (
          <>
            <p class="wz-lead2">{t("raAskLead", { name: agent.name })}</p>
            {others.length > 0 && (
              <div class="notice warn ra-with" role="alert">
                <b>{t("raWithLead")}</b>
                <ul>
                  {others.map((w) => (
                    <li key={w.id}>
                      {w.name} <span class="dim">· {t(`kind_${w.kind}`)}</span>
                    </li>
                  ))}
                </ul>
              </div>
            )}
            <ul class="pa-facts">
              <li>
                {preview.running === 0
                  ? t("raRunningNone")
                  : preview.running === 1
                    ? t("raRunningOne")
                    : t("raRunningN", { n: String(preview.running) })}
              </li>
              <li>
                {preview.tasks === 0
                  ? t("raTasksNone")
                  : preview.tasks === 1
                    ? t("raTasksOne")
                    : t("raTasksN", { n: String(preview.tasks) })}
              </li>
              <li>{t("raFactHistory")}</li>
              <li>{t("raFactRestore")}</li>
            </ul>
          </>
        )}
        {error && <p class="notice error">{error}</p>}
      </div>
    </Modal>
  );
}

/** The conversations of a removal (its agent and those removed with it), each opened read only. */
function RemovedConversations({ r }: { r: RemovedAgent }) {
  const [rows, setRows] = useState<(SessionInfo & { who: string })[]>();
  useEffect(() => {
    const who = [{ id: r.id, name: r.name }, ...r.removed.with];
    void Promise.all(
      who.map((w) =>
        getApi()
          .sessions(w.id)
          .then(
            (list) => list.map((s) => ({ ...s, who: w.name })),
            () => [],
          ),
      ),
    ).then((all) => setRows(all.flat()));
  }, [r.id]);
  if (!rows) return <p class="dim">{t("loading")}</p>;
  if (rows.length === 0) return <p class="dim ra-none">{t("raNoConversations")}</p>;
  return (
    <div class="ra-sessions">
      {rows.map((s) => (
        <button
          type="button"
          key={s.id}
          class="ra-session"
          onClick={() => openSession({ id: s.id, agentId: s.agentId, title: s.title ?? s.who })}
        >
          <IconChat size={14} />
          <span class="ra-session-title">{s.title ?? t("raUntitled")}</span>
          {s.agentId !== r.id && <small class="dim">{s.who}</small>}
        </button>
      ))}
    </div>
  );
}

/** «Removed agents»: each removal with when, by whom, why, who went with it; «Restore». */
export function RemovedAgentsList({ projectId = null }: { projectId?: string | null }) {
  const [error, setError] = useState<{ id: string; text: string }>();
  const [busy, setBusy] = useState<string>();
  const [open, setOpen] = useState<string>();
  const list = removedAgents.value.filter(
    (r) => !projectId || r.projectId === projectId || r.projects?.includes(projectId),
  );
  if (list.length === 0) return <p class="dim ra-empty">{t("raNone")}</p>;
  return (
    <div class="ra-list">
      {list.map((r) => (
        <div key={r.id} class="ra-item">
          <div class="ra-head">
            <Mascot agent={r} size={36} decorative />
            <div class="ra-main">
              <b class="ra-name">{r.name}</b>
              <small class="dim">
                {t(`kind_${r.kind}`)}
                {r.projectId ? ` · ${projectName(r.projectId)}` : ""}
              </small>
              <small class="ra-when">
                {t("raWhen", { day: day(r.removed.at) })}{" "}
                {r.removed.by === "person" ? t("raByYou") : t("raByAgent", { name: r.removed.by })}
              </small>
              {r.removed.reason && (
                <small class="dim ra-reason">{t("raReason", { reason: r.removed.reason })}</small>
              )}
              {r.removed.with.length > 0 && (
                <small class="dim ra-with-line">
                  {t("raWithLine", { names: r.removed.with.map((w) => w.name).join(", ") })}
                </small>
              )}
            </div>
            <div class="ra-acts">
              <button
                type="button"
                class="wz-btn small"
                aria-expanded={open === r.id}
                onClick={() => setOpen(open === r.id ? undefined : r.id)}
              >
                <IconChat size={15} /> {t("raConversations", { n: String(r.removed.sessions) })}
              </button>
              <button
                type="button"
                class="wz-btn small primary"
                disabled={busy === r.id}
                onClick={() => {
                  setBusy(r.id);
                  setError(undefined);
                  void restoreRemoved(r).then((e) => {
                    if (e) setError({ id: r.id, text: e });
                    setBusy(undefined);
                  });
                }}
              >
                <IconRestore size={15} /> {t("raRestore")}
              </button>
            </div>
          </div>
          {error?.id === r.id && <p class="notice error">{error.text}</p>}
          {open === r.id && <RemovedConversations r={r} />}
        </div>
      ))}
    </div>
  );
}

/** Where the composer was, in a conversation of a removed agent: «Restore» brings it back. */
export function RemovedNotice({ agentId }: { agentId: string }) {
  const r = removalOf(agentId);
  const [error, setError] = useState<string>();
  if (!r) return null;
  const name =
    r.id === agentId ? r.name : (r.removed.with.find((w) => w.id === agentId)?.name ?? r.name);
  return (
    <div class="pa-notice ra-notice" role="status">
      <span class="pa-badge">
        <IconTrash size={13} /> {t("raBadge")}
      </span>
      <span class="pa-notice-text">{t("raChatReadOnly", { name })}</span>
      <button
        type="button"
        class="wz-btn primary small"
        onClick={() => void restoreRemoved(r).then(setError)}
      >
        {t("raRestore")}
      </button>
      {error && <span class="notice error">{error}</span>}
    </div>
  );
}
