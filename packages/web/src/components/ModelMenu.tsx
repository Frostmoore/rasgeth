import { keyProvider, OWN_SERVER_ID } from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import type { ModelChoice } from "../api.js";
import { localModelName } from "../format.js";
import { t } from "../i18n.js";
import { attempt, getApi, refreshConversations } from "../state.js";
import { effortOptions, ModelFamilySelect } from "./ModelSelect.js";
import { DropChoice } from "./ui.js";

type Model = { provider: string; model: string; effort?: string };
const AGENTS = "";

/** A model's name as people say it: claude-opus-5-5 → Opus 5.5; other ids stay as they are. */
export function modelName(id: string): string {
  const m = id.match(/^claude-([a-z]+)-(\d+)(?:-(\d+))?$/);
  if (!m) return localModelName(id);
  const family = (m[1] ?? "").charAt(0).toUpperCase() + (m[1] ?? "").slice(1);
  return `${family} ${m[2]}${m[3] ? `.${m[3]}` : ""}`;
}

/**
 * What the menus add after a model's name (3.5.4): "new" for a model just released, "data to be
 * confirmed" for one the provider lists and the models catalog does not know yet.
 */
export const modelNote = (m: { status?: "new" | "unconfirmed" | undefined }) =>
  m.status === "new"
    ? ` · ${t("modelNew")}`
    : m.status === "unconfirmed"
      ? ` · ${t("modelUnconfirmed")}`
      : "";

/** How a model is reached, in a word next to its name. */
export const via = (provider: string) =>
  provider.endsWith("-subscription")
    ? t("viaSubscription")
    : provider === "local" || provider === OWN_SERVER_ID
      ? t("viaLocal")
      : keyProvider(provider)
        ? "API"
        : provider;

/** The models the server offers, shared by every composer; asked again when a menu is opened. */
let cache: Promise<ModelChoice[]> | undefined;
const loadModels = (fresh = false) => {
  if (fresh) cache = undefined;
  cache ??= getApi()
    .models()
    .catch(() => {
      cache = undefined;
      return [];
    });
  return cache;
};

/**
 * The composer's model and effort, as in Officina: two of our drawn menus (3.10). The next message uses them; "the agent's" goes back to what the agent is set to.
 */
export function ModelMenu({
  sessionId,
  current,
  own,
  disabled,
}: {
  sessionId: string;
  /** What the conversation uses now (its own or the agent's). */
  current: Model | undefined;
  /** True when the conversation has its own model. */
  own: boolean;
  disabled: boolean;
}) {
  const [models, setModels] = useState<ModelChoice[]>([]);
  useEffect(() => void loadModels().then(setModels), []);

  const choose = async (m: Model | null) => {
    await attempt(() => getApi().updateSession(sessionId, { model: m }));
    await refreshConversations().catch(() => {});
  };
  const key = (m: { provider: string; model: string }) => `${m.provider}/${m.model}`;
  const effortOk =
    current !== undefined &&
    (models.find((m) => key(m) === key(current))?.effort ?? current.effort !== undefined);

  return (
    <>
      <ModelFamilySelect
        selectClass={`model ${own ? "own" : ""}`}
        title={t("modelHint")}
        disabled={disabled}
        // A way of thinking connected meanwhile shows up as soon as the menu is opened.
        onFocus={() => void loadModels(true).then(setModels)}
        value={own && current ? key(current) : AGENTS}
        empty={AGENTS}
        emptyText={!current ? t("modelPick") : own ? t("agentsModel") : modelName(current.model)}
        wayFor={current}
        models={models}
        onChange={(v, m) => {
          if (v === AGENTS || !m) return void choose(null);
          void choose({
            provider: m.provider,
            model: m.model,
            ...(m.effort && { effort: current?.effort ?? "medium" }),
          });
        }}
      />
      {current && effortOk && (
        <DropChoice
          class="model effort"
          label={t("effort")}
          title={t("effortHint")}
          disabled={disabled}
          value={current.effort ?? "medium"}
          options={effortOptions()}
          onChange={(v) => void choose({ ...current, effort: v })}
        />
      )}
    </>
  );
}
