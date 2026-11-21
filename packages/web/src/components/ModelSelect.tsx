// One way to choose a model wherever one is chosen (G24.14d): the wizard, an agent's settings,
// the chat's settings. Our drawn list (3.10), by provider and way with the newest first. The models connected now, by name, each once (G40.9b): a model that can go
// through the subscription and through the API key shows the two as a drawn choice, with a line
// on what each means; with one way the way still shows, as a small label.
import {
  familyOf,
  groupTitle,
  KEY_PROVIDERS,
  type ModelFamily,
  modelFamilies,
  modelGroups,
  OWN_SERVER_ID,
  routeHint,
  routeLabel,
} from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import type { ModelChoice } from "../api.js";
import { lang, t } from "../i18n.js";
import { getApi } from "../state.js";
import { modelName, modelNote } from "./ModelMenu.js";
import { DropChoice, type DropOption } from "./ui.js";

const EFFORTS = ["low", "medium", "high", "max"] as const;

/** A model as the API gives it: provider, id and, when it has one, the effort. */
export type Spec = { provider: string; model: string; effort?: string };
const key = (m: { provider: string; model: string }) => `${m.provider}/${m.model}`;

/** The models connected now (asked again each time: one may have just been connected). */
export function useModels(): ModelChoice[] | undefined {
  const [models, setModels] = useState<ModelChoice[]>();
  useEffect(
    () =>
      void getApi()
        .models()
        .then(setModels, () => setModels([])),
    [],
  );
  return models;
}

/** The company behind a family, in words (the optgroups when there are several). */
export function vendorName(id: string): string {
  if (id === "local") return t("brainLocal");
  if (id === OWN_SERVER_ID) return t("brainServer");
  return KEY_PROVIDERS.find((p) => p.id === id)?.name ?? id;
}

/** A family's name in the menus: the catalog's, else the id as people say it. */
export const familyName = (f: ModelFamily<ModelChoice>) => f.name ?? modelName(f.model);

/** A way's label and line, in the page's language. */
export const wayLabel = (f: ModelFamily<ModelChoice>, i: number) => {
  const r = f.routes[i];
  return r ? routeLabel(r.route, lang.value, r.choice.provider) : "";
};
export const wayHint = (f: ModelFamily<ModelChoice>, i: number) => {
  const r = f.routes[i];
  return r ? routeHint(r.route, lang.value) : "";
};

/** The way a chosen model goes, as a word: «Abbonamento», «Chiave API»… (empty when unknown). */
export function wayOf(models: ModelChoice[], m: { provider: string; model: string }): string {
  const at = familyOf(modelFamilies(models), m);
  return at ? wayLabel(at.family, at.index) : "";
}

/** Who makes a chosen model and how it goes: «Anthropic (Claude) · Abbonamento». */
export function sourceOf(models: ModelChoice[], m: { provider: string; model: string }): string {
  const at = familyOf(modelFamilies(models), m);
  return at ? `${vendorName(at.family.vendor)} · ${wayLabel(at.family, at.index)}` : m.provider;
}

/**
 * How the chosen model goes (G40.9b): with several ways a drawn choice and its line, with one a
 * small label. `compact` leaves the line out and puts it in the tooltip.
 */
export function ModelWay({
  family,
  index,
  onPick,
  compact,
}: {
  family: ModelFamily<ModelChoice>;
  index: number;
  onPick: (m: ModelChoice) => void;
  compact?: boolean;
}) {
  const hint = wayHint(family, index);
  if (family.routes.length < 2)
    return (
      <span class="model-way-one" title={hint}>
        {wayLabel(family, 0)}
      </span>
    );
  return (
    <div class={`model-way${compact ? " compact" : ""}`}>
      <fieldset class="model-way-seg" aria-label={t("modelWay")}>
        {family.routes.map((r, i) => (
          <button
            type="button"
            key={key(r.choice)}
            class={`model-way-opt${i === index ? " on" : ""}`}
            aria-pressed={i === index}
            title={wayHint(family, i)}
            onClick={() => i !== index && onPick(r.choice)}
          >
            {wayLabel(family, i)}
          </button>
        ))}
      </fieldset>
      {!compact && <p class="model-way-hint">{hint}</p>}
    </div>
  );
}

/** An effort in words, for the drawn menus. */
export const effortOptions = () =>
  EFFORTS.map((x) => ({ id: x as string, label: t(`effort_${x}` as never) }));

/**
 * The models as the menus list them (2026-11-20, the person): under a heading per provider and
 * way («Anthropic · Abbonamento Claude», «Anthropic · Chiave API»…), the newest first in each.
 */
export function modelOptions(models: ModelChoice[]): DropOption<string>[] {
  return modelGroups(models).flatMap((g) => {
    const group = groupTitle(g, lang.value);
    return g.choices.map((c) => ({
      id: key(c),
      label: `${c.name ?? modelName(c.model)}${modelNote(c)}`,
      group,
    }));
  });
}

/**
 * The model menu (our drawn list, by provider and way, with a search when it is long) and the way
 * under it. `value` and `onChange` speak `provider/model` ("" for `empty`), like the forms that
 * keep a string.
 */
export function ModelFamilySelect({
  value,
  onChange,
  models,
  empty,
  label,
  selectClass,
  title,
  disabled,
  onFocus,
  compact,
  emptyText,
  wayFor,
}: {
  value: string;
  onChange: (v: string, m?: ModelChoice) => void;
  models: ModelChoice[];
  /** What "no model of its own" means here; absent: one is needed. */
  empty?: string;
  /** The empty option's text when it differs from `empty`'s meaning (the composer's). */
  emptyText?: string;
  label?: string;
  selectClass?: string;
  title?: string;
  disabled?: boolean;
  /** Called as the list opens (a way connected meanwhile shows up). */
  onFocus?: () => void;
  compact?: boolean;
  /** The model whose way shows when `value` is empty (the agent's, in the composer). */
  wayFor?: { provider: string; model: string } | undefined;
}) {
  const families = modelFamilies(models);
  const [provider = "", ...rest] = value.split("/");
  const at = value ? familyOf(families, { provider, model: rest.join("/") }) : undefined;
  const way = at ?? (!value && wayFor ? familyOf(families, wayFor) : undefined);
  const listed = modelOptions(models);
  const options: DropOption<string>[] = [
    ...(empty !== undefined || !value
      ? [{ id: "", label: emptyText ?? empty ?? t("modelPick") }]
      : []),
    ...(value && !at ? [{ id: value, label: modelName(rest.join("/")) }] : []),
    ...listed,
  ];
  return (
    <>
      <DropChoice
        class={`model-drop${selectClass ? ` ${selectClass}` : ""}`}
        label={label ?? t("model")}
        {...(title !== undefined && { title })}
        {...(disabled !== undefined && { disabled })}
        {...(onFocus && { onOpen: onFocus })}
        {...(listed.length > 8 && { search: t("modelSearch") })}
        value={value}
        options={options}
        onChange={(v) => {
          if (!v) return onChange("");
          const m = models.find((x) => key(x) === v);
          if (m) onChange(v, m);
        }}
      />
      {way && (
        <ModelWay
          family={way.family}
          index={way.index}
          compact={compact ?? false}
          onPick={(m) => !disabled && onChange(key(m), m)}
        />
      )}
    </>
  );
}

export function ModelSelect({
  value,
  onChange,
  empty,
  label,
  models,
}: {
  value: Spec | null;
  onChange: (m: Spec | null) => void;
  /** What "no model of its own" means here (the default, the parent's…); absent: one is needed. */
  empty?: string;
  label?: string;
  models: ModelChoice[];
}) {
  const effort = value && models.find((m) => key(m) === key(value))?.effort;
  return (
    <div class="model-select">
      <ModelFamilySelect
        value={value ? key(value) : ""}
        models={models}
        {...(empty !== undefined && { empty })}
        {...(label !== undefined && { label })}
        onChange={(_, m) => {
          if (!m) return onChange(null);
          onChange({
            provider: m.provider,
            model: m.model,
            ...(m.effort && { effort: value?.effort ?? "medium" }),
          });
        }}
      />
      {value && effort && (
        <DropChoice
          class="effort-drop"
          label={t("effort")}
          title={t("effortHint")}
          value={value.effort ?? "medium"}
          options={effortOptions()}
          onChange={(v) => onChange({ ...value, effort: v })}
        />
      )}
    </div>
  );
}
