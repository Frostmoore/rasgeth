// Tool groups (3.9.4, decision «Strumenti spenti di serie, accesi a gruppi quando servono»): the
// kits of the tools page, each with what it holds, what it weighs when on and its state: off by
// default (the agent switches it on itself when the work needs it), always on, or off by the person
// (the agent has to ask). For every agent, or for one agent (its own choice, or as for everyone).
import type { KitState, KitView, ToolsView } from "@redgiant/protocol";
import { useState } from "preact/hooks";
import { type Key, t } from "../i18n.js";
import { IconLock } from "../icons.js";
import { getApi } from "../state.js";
import { Seg } from "./SettingsKit.js";
import { aboutTokens, toolName } from "./ToolsPage.js";

type Pick = KitState | "default";

export const kitName = (id: string) => t(`kit_${id}` as Key);
export const kitDoes = (id: string) => t(`kitDo_${id}` as Key);
const stateWord = (s: KitState) => t(s === "on" ? "kitOn" : s === "off" ? "kitOff" : "kitAuto");

/** The view as it will be once a kit's state changes (the server's answer follows). */
export function withKit(view: ToolsView, id: string, own: KitState | null): ToolsView {
  const kits = view.kits.map((k) =>
    k.id === id
      ? { ...k, own, state: own ?? (view.agentId ? (k.global ?? k.default) : k.default) }
      : k,
  );
  const stateOf = new Map(kits.map((k) => [k.id, k.state] as const));
  const entries = view.entries.map((e) =>
    e.kit === id && e.own == null && (view.agentId !== null || e.global)
      ? { ...e, state: stateOf.get(e.kit) ?? e.state }
      : e,
  );
  const sum = (on: boolean) =>
    entries.filter((e) => (e.state === "on") === on).reduce((n, e) => n + e.tokens, 0);
  return { ...view, kits, entries, total: sum(true), saved: sum(false) };
}

function KitRow({
  k,
  view,
  busy,
  onPick,
}: {
  k: KitView;
  view: ToolsView;
  busy: boolean;
  onPick: (p: Pick) => void;
}) {
  const forAgent = view.agentId !== null;
  const names = k.entries.map(toolName).join(", ");
  const options: [Pick, string][] = [
    ...(forAgent ? [["default", t("toolsDefault")] as [Pick, string]] : []),
    ["auto", t("kitAuto")],
    ["on", t("kitOn")],
    ["off", t("kitOff")],
  ];
  const value: Pick = forAgent ? (k.own ?? "default") : k.state;
  return (
    <div
      class={`tl-kit${k.state === "on" ? " on" : k.state === "off" ? " off" : ""}`}
      data-kit={k.id}
    >
      <div class="tl-main">
        <div class="tl-text">
          <div class="tl-name">
            <b>{kitName(k.id)}</b>
            <code class="tl-id">{k.id}</code>
            <span class={`tl-kit-state ${k.state}`}>{stateWord(k.state)}</span>
          </div>
          <span>{kitDoes(k.id)}</span>
          <small class="tl-weight">
            {t("kitWeight", { n: aboutTokens(k.tokens) })}
            {k.default === "on" && k.id !== "core" ? ` · ${t("kitRole")}` : ""}
          </small>
          {forAgent && (
            <small class="tl-kit-tools">
              {t("kitAsAll", { state: stateWord(k.global ?? k.default) })}
            </small>
          )}
          <small class="tl-kit-tools">{t("kitTools", { list: names })}</small>
        </div>
      </div>
      <div class={`tl-pick${busy ? " busy" : ""}`}>
        <Seg<Pick> label={kitName(k.id)} value={value} onChange={onPick} options={options} />
      </div>
    </div>
  );
}

/** The kits of a tools view, with their states; changes are sent at once and the view reread. */
export function ToolKits({
  view,
  setView,
  setError,
  load,
  agentName,
}: {
  view: ToolsView;
  setView: (v: ToolsView) => void;
  setError: (e: string) => void;
  load: () => Promise<void>;
  agentName?: string;
}) {
  const [busy, setBusy] = useState(false);
  const pick = async (k: KitView, p: Pick) => {
    // For every agent, choosing the default clears the choice.
    const send: Pick = view.agentId === null && p === k.default ? "default" : p;
    setView(withKit(view, k.id, send === "default" ? null : send));
    setBusy(true);
    try {
      if (view.agentId) await getApi().setAgentKits(view.agentId, { [k.id]: send });
      else await getApi().setKits({ [k.id]: send });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setBusy(false);
      await load();
    }
  };
  return (
    <section class="tl-kits">
      <h2 class="wz-sub">{t("kitsTitle")}</h2>
      <p class="tl-lead">{agentName ? t("kitsAgentLead", { name: agentName }) : t("kitsLead")}</p>
      {view.essential !== undefined && (
        <p class="tl-kit-essential">
          <IconLock size={14} /> {t("kitEssential", { n: aboutTokens(view.essential) })}
        </p>
      )}
      <div class="tl-list">
        {view.kits.map((k) => (
          <KitRow key={k.id} k={k} view={view} busy={busy} onPick={(p) => void pick(k, p)} />
        ))}
      </div>
    </section>
  );
}
