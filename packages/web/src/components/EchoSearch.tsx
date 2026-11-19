// Echo (3.9.6): the search box over past conversations, at the top of the left bar. The results
// are the ones the agents' `search_conversations` gives (GET /api/conversations/search): while a
// search is typed they take the place of the bar's lists; clearing it brings the lists back.

import type { ComponentChildren } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import type { EchoHit } from "../api.js";
import { t } from "../i18n.js";
import { IconClose, IconSearch } from "../icons.js";
import { agents, attempt, getApi, openSessionById, projects } from "../state.js";

/** A snippet with the words found marked: text from the server, offsets, never HTML. */
export function Snippet({ text, marks }: { text: string; marks: [number, number][] }) {
  const out: ComponentChildren[] = [];
  let at = 0;
  for (const [a, b] of marks) {
    if (a < at || b > text.length) continue;
    out.push(text.slice(at, a), <mark key={a}>{text.slice(a, b)}</mark>);
    at = b;
  }
  out.push(text.slice(at));
  return <>{out}</>;
}

/** Where a conversation is: project and agent, as the list says them. */
function placeOf(h: EchoHit): string {
  const agent = agents.value.find((a) => a.id === h.agentId)?.name ?? "";
  const project = projects.value.find((p) => p.id === h.projectId)?.name;
  return project ? `${project} · ${agent}` : agent;
}

/** The box and, once two letters are typed, the conversations found in place of `children`. */
export function EchoSearch({ children }: { children: ComponentChildren }) {
  const [q, setQ] = useState("");
  const [hits, setHits] = useState<EchoHit[] | null>(null);
  const asked = useRef(0);
  const query = q.trim();
  useEffect(() => {
    if (query.length < 2) {
      setHits(null);
      return;
    }
    const n = ++asked.current;
    const timer = setTimeout(() => {
      void attempt(() => getApi().searchConversations(query)).then((r) => {
        // Only the latest question's answer is shown.
        if (r && n === asked.current) setHits(r);
      });
    }, 250);
    return () => clearTimeout(timer);
  }, [query]);
  const clear = () => {
    asked.current++;
    setQ("");
    setHits(null);
  };
  return (
    <>
      <form class="echo-bar" onSubmit={(e) => e.preventDefault()}>
        <IconSearch size={14} />
        <input
          value={q}
          placeholder={t("echoSearch")}
          aria-label={t("echoSearch")}
          onInput={(e) => setQ((e.target as HTMLInputElement).value)}
          onKeyDown={(e) => e.key === "Escape" && clear()}
        />
        {q && (
          <button type="button" class="icon-button" title={t("echoClear")} onClick={clear}>
            <IconClose size={13} />
          </button>
        )}
      </form>
      {query.length === 0 ? (
        children
      ) : query.length < 2 ? (
        <div class="echo-results">
          <div class="empty">{t("echoHint")}</div>
        </div>
      ) : (
        <div class="echo-results" aria-live="polite">
          {hits?.length === 0 && <div class="empty">{t("echoNone")}</div>}
          {hits?.map((h) => (
            <button
              type="button"
              key={h.sessionId}
              class="echo-hit"
              onClick={() => void openSessionById(h.sessionId, h.agentId)}
            >
              <span class="echo-title">{h.title ?? t("newConversation")}</span>
              <span class="echo-place">
                {placeOf(h)}
                {h.archived && <span class="echo-archived">{t("echoArchived")}</span>}
              </span>
              <span class="echo-date">
                {new Date(h.at).toLocaleDateString()} ·{" "}
                {h.matches === 1 ? t("echoMatch") : t("echoMatches", { n: String(h.matches) })}
              </span>
              {h.snippets
                .filter((s) => s.text)
                .map((s) => (
                  <span class="echo-snippet" key={s.at}>
                    <b>
                      {s.role === "person"
                        ? t("echoYou")
                        : (agents.value.find((a) => a.id === h.agentId)?.name ?? "")}
                      :
                    </b>{" "}
                    <Snippet text={s.text} marks={s.marks} />
                  </span>
                ))}
            </button>
          ))}
        </div>
      )}
    </>
  );
}
