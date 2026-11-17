// Agents at work together (3.8.10, the person: «dai la possibilità all'utente di poter scegliere un
// numero massimo di agenti che lavorano in parallelo»). The setting on the Agents page, the line of
// turns waiting for a place (in a window from the bar's meter, or under the setting), and the
// notice in a conversation that waits: «Queued (2nd of 3): waiting for a free place».
import { type CommandSettings, MAX_AT_WORK } from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import type { PlatformChange } from "../api.js";
import { lang, t } from "../i18n.js";
import { IconClock, IconToFront, IconUsers } from "../icons.js";
import {
  agents,
  attempt,
  getApi,
  getLive,
  openSessionById,
  queuePlace,
  sessionRows,
  turnQueue,
} from "../state.js";
import { explain } from "./Brain.js";
import { Mascot } from "./Mascot.js";
import { Chips } from "./SettingsKit.js";
import { Modal } from "./ui.js";

/** The ready choices: up to the protocol's highest. */
const CHOICES = [1, 2, 3, 4, 6, 8, 12, MAX_AT_WORK];
const NONE = "none";

/** The person moves a waiting conversation to the front of the line. */
async function moveFirst(sessionId: string): Promise<void> {
  turnQueue.value = await getApi().turnFirst(sessionId);
}

/** «2°» in Italian, «2nd» in English. */
export function ordinal(n: number): string {
  if (lang.value === "it") return `${n}°`;
  const tens = n % 100;
  const one = n % 10;
  const suffix =
    tens >= 11 && tens <= 13 ? "th" : one === 1 ? "st" : one === 2 ? "nd" : one === 3 ? "rd" : "th";
  return `${n}${suffix}`;
}

/** «queued (2nd of 3)», or undefined when the conversation does not wait. */
export function placeWords(sessionId: string): string | undefined {
  const p = queuePlace(sessionId);
  return p && t("tqPlace", { place: ordinal(p.place), of: String(p.of) });
}

function waitedFor(since: string, now: number): string {
  const min = Math.floor((now - Date.parse(since)) / 60_000);
  if (!(min >= 1)) return t("tqLessMinute");
  if (min < 60) return t("tqMinutes", { n: String(min) });
  return t("tqHours", { n: String(Math.floor(min / 60)) });
}

/** A clock that moves once a minute while the line shows. */
function useMinute(): number {
  const [now, setNow] = useState(Date.now());
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 30_000);
    return () => clearInterval(id);
  }, []);
  return now;
}

/** «At work 2/3» (or «At work 2» with no limit). */
function atWorkWords(): string {
  const q = turnQueue.value;
  return q.limit === null
    ? t("tqAtWork", { n: String(q.working) })
    : t("tqAtWorkOf", { n: String(q.working), max: String(q.limit) });
}

/** The places as a row of small cells: lit for those at work, empty for the free ones. */
function Places() {
  const q = turnQueue.value;
  const limit = q.limit;
  if (limit === null) return null;
  const cells = Math.max(limit, q.working);
  return (
    <span class="tq-cells" aria-hidden="true">
      {Array.from({ length: cells }, (_, i) => (
        <span
          // biome-ignore lint/suspicious/noArrayIndexKey: cells have no identity of their own
          key={i}
          class={`tq-cell${i < q.working ? " on" : ""}${i >= limit ? " over" : ""}`}
        />
      ))}
    </span>
  );
}

/** The line, in the order it starts: who, which conversation, since when; «Move first». */
export function TurnLineList({ onOpen }: { onOpen?: () => void }) {
  const now = useMinute();
  const q = turnQueue.value;
  if (q.queued.length === 0) return <p class="tq-empty">{t("tqLineEmpty")}</p>;
  return (
    <ol class="tq-list">
      {q.queued.map((w, i) => {
        const agent = agents.value.find((a) => a.id === w.agentId);
        const row = sessionRows.value.find((r) => r.id === w.sessionId);
        const title = row?.task ?? row?.title ?? "";
        return (
          <li key={w.sessionId} class={`tq-item${i === 0 ? " next" : ""}`}>
            <span class="tq-num">{ordinal(i + 1)}</span>
            {agent ? <Mascot agent={agent} size={28} /> : <IconUsers size={20} />}
            <button
              type="button"
              class="tq-who"
              title={t("tqOpen")}
              onClick={() => {
                onOpen?.();
                void openSessionById(w.sessionId, w.agentId);
              }}
            >
              <b>{agent?.name ?? w.agentId}</b>
              {title && <span class="tq-what">{title}</span>}
              <span class="tq-meta">
                <IconClock size={12} /> {t("tqSince", { span: waitedFor(w.since, now) })}
                {w.child && <span class="tq-tag">{t("tqChild")}</span>}
                {w.first && <span class="tq-tag moved">{t("tqMoved")}</span>}
              </span>
            </button>
            <span class="tq-acts">
              {i === 0 ? (
                <span class="tq-next">{t("tqNext")}</span>
              ) : (
                <button
                  type="button"
                  class="wz-btn small"
                  onClick={() => void attempt(() => moveFirst(w.sessionId))}
                >
                  <IconToFront size={14} /> {t("tqFirst")}
                </button>
              )}
              <button
                type="button"
                class="wz-btn small quiet"
                onClick={() =>
                  getLive().send({ type: "session.interrupt", sessionId: w.sessionId })
                }
              >
                {t("tqTakeOut")}
              </button>
            </span>
          </li>
        );
      })}
    </ol>
  );
}

/** The line in a window (from the bar's meter and a conversation's notice). */
export function TurnLineModal({ onClose }: { onClose: () => void }) {
  return (
    <Modal
      title={t("tqLineTitle")}
      icon={<IconUsers size={20} />}
      sub={
        <span class="tq-sub">
          <Places /> {atWorkWords()}
          {turnQueue.value.queued.length > 0 &&
            ` · ${t("tqWaitingN", { n: String(turnQueue.value.queued.length) })}`}
        </span>
      }
      onClose={onClose}
    >
      <p class="tq-lead">{t("tqLineLead")}</p>
      <TurnLineList onOpen={onClose} />
    </Modal>
  );
}

/**
 * In the bar, above the agents (3.8.10): «At work 2/2 · 3 waiting», shown while someone waits or
 * a limit is set and agents work; a click opens the line.
 */
export function TurnMeter() {
  const [open, setOpen] = useState(false);
  const q = turnQueue.value;
  if (q.queued.length === 0 && (q.limit === null || q.working === 0)) return null;
  return (
    <>
      <button
        type="button"
        class={`tq-meter${q.queued.length > 0 ? " waiting" : ""}`}
        onClick={() => setOpen(true)}
        title={t("tqSeeLine")}
      >
        <Places />
        <span class="tq-meter-text">
          {atWorkWords()}
          {q.queued.length > 0 && (
            <b class="tq-meter-wait">
              {" · "}
              {t("tqWaitingN", { n: String(q.queued.length) })}
            </b>
          )}
        </span>
      </button>
      {open && <TurnLineModal onClose={() => setOpen(false)} />}
    </>
  );
}

/** Above the message box of a conversation that waits for a place. */
export function QueuedNotice({ sessionId }: { sessionId: string }) {
  const [open, setOpen] = useState(false);
  const p = queuePlace(sessionId);
  if (!p) return null;
  return (
    <div class="tq-notice" role="status">
      <span class="tq-notice-ico">
        <IconClock size={16} />
      </span>
      <span class="tq-notice-text">
        <b>{t("tqBanner", { place: ordinal(p.place), of: String(p.of) })}</b>
        <span>{t("tqBannerHint", { n: String(turnQueue.value.working) })}</span>
      </span>
      {p.place > 1 && (
        <button
          type="button"
          class="wz-btn primary small"
          onClick={() => void attempt(() => moveFirst(sessionId))}
        >
          <IconToFront size={14} /> {t("tqFirst")}
        </button>
      )}
      <button type="button" class="wz-btn small" onClick={() => setOpen(true)}>
        {t("tqSeeLine")}
      </button>
      {open && <TurnLineModal onClose={() => setOpen(false)} />}
    </div>
  );
}

/**
 * The setting, on the Agents page: «Agents at work together, at most: N», saved at once (in the
 * history, undoable), with the line under it.
 */
export function AtWorkCard() {
  const [s, setS] = useState<CommandSettings>();
  const [saved, setSaved] = useState<PlatformChange | "undone">();
  const [error, setError] = useState<string>();
  const load = () =>
    getApi()
      .commandSettings()
      .then((r) => setS(r.settings))
      .catch((err) => setError(explain(err)));
  useEffect(() => {
    void load();
    void getApi()
      .turns()
      .then((v) => {
        // An older server has no line: nothing to show.
        if (Array.isArray(v?.queued)) turnQueue.value = v;
      })
      .catch(() => {});
  }, []);
  const now = s?.maxAtWork ?? null;
  const ready: (number | null)[] = [null, ...CHOICES];
  const all = ready.includes(now) ? ready : [...ready, now];
  const pick = async (v: string | undefined) => {
    if (!s) return;
    const next = { ...s, maxAtWork: v === undefined || v === NONE ? null : Number(v) };
    setError(undefined);
    try {
      setSaved(await getApi().setCommandSettings(next));
      setS(next);
    } catch (err) {
      setError(explain(err));
    }
  };
  const undo = async () => {
    if (!saved || saved === "undone") return;
    try {
      await getApi().undoChange(saved.id);
      setSaved("undone");
      await load();
    } catch (err) {
      setError(explain(err));
    }
  };
  return (
    <section class="wz-card tq-card" aria-label={t("tqTitle")}>
      <div class="tq-card-head">
        <span class="tq-card-ico">
          <IconUsers size={20} />
        </span>
        <div class="tq-card-text">
          <h2>{t("tqTitle")}</h2>
          <p>{t("tqLead")}</p>
        </div>
        <span class="tq-card-now">
          <Places />
          <span>{atWorkWords()}</span>
        </span>
      </div>
      {s ? (
        <Chips
          options={all.map((v) => ({
            id: v === null ? NONE : String(v),
            label: v === null ? t("tqNoLimit") : String(v),
          }))}
          value={[now === null ? NONE : String(now)]}
          onChange={([v]) => void pick(v)}
        />
      ) : (
        !error && <p class="dim">{t("loading")}</p>
      )}
      <p class="tq-note">{now === null ? t("tqNoLimitNote") : t("tqLower")}</p>
      {saved && saved !== "undone" && (
        <p class="tq-saved">
          {t("tqSaved")}{" "}
          <button type="button" class="wz-link inl" onClick={() => void undo()}>
            {t("tqUndo")}
          </button>
        </p>
      )}
      {saved === "undone" && <p class="tq-saved">{t("tqUndone")}</p>}
      {error && <p class="notice error">{error}</p>}
      {(turnQueue.value.queued.length > 0 || now !== null) && (
        <div class="tq-card-line">
          <h3>{t("tqLineTitle")}</h3>
          <TurnLineList />
        </div>
      )}
    </section>
  );
}
