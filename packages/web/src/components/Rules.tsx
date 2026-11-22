// Settings > Rules (3.12, «Regole della persona»): the person's own rules, which {product} enforces
// by itself: WHEN something happens, IF conditions hold, THEN it acts (tells, asks, blocks, stops
// the agents after they save, switches tools off, starts an automation or a command checked as an
// agent's). Beside the safety pages, not inside the automations (the person's choice of
// 2026-11-21). A rule switches on only when its two examples pass; every change is in the history
// and can be undone; a stop in place shows on top with «Resume». The magic rule: God builds it in
// a conversation and proposes it beside it, to approve, change or refuse.
import {
  type MagicRule,
  type PersonRule,
  RULE_FIELDS_BY_EVENT,
  type RuleAction,
  type RuleCondition,
  type RuleDraftInput,
  type RuleEventKind,
  type RuleField,
  type RuleFire,
  type RuleHold,
  type RuleOp,
  type RuleSample,
  type RuleTrial,
  type RuleVersion,
} from "@redgiant/protocol";
import { useEffect, useState } from "preact/hooks";
import { type Key, lang, t } from "../i18n.js";
import {
  IconAlert,
  IconBell,
  IconClock,
  IconLink,
  IconPencil,
  IconPlay,
  IconPlus,
  IconShield,
  IconSpark,
  IconStop,
  IconTrash,
  IconUndo,
  IconX,
  IconZap,
} from "../icons.js";
import { attempt, getApi, rulesVersion } from "../state.js";
import { explain } from "./Brain.js";
import { Chat } from "./Chat.js";
import { askConfirm } from "./dialogs.js";
import { MagicStart, type MagicWords, Steps } from "./MagicAutomation.js";
import { Acts, Head, SCard, Seg, Sub, Switch, WzPage } from "./SettingsKit.js";
import { DropChoice, Field, Modal } from "./ui.js";

const EVENTS: RuleEventKind[] = [
  "usage",
  "budget",
  "tool",
  "file",
  "agent_done",
  "schedule",
  "webhook",
];
const NUMERIC: RuleField[] = ["marginPct", "usedPct", "budgetPct"];
const TEXT_OPS: RuleOp[] = ["eq", "neq", "matches", "contains"];
const NUMBER_OPS: RuleOp[] = ["lte", "lt", "gte", "gt", "eq", "neq"];
const BEFORE: RuleEventKind[] = ["tool", "file"];
type ActionKind = RuleAction["do"];
const ACTIONS: ActionKind[] = [
  "notify",
  "ask",
  "block",
  "stop",
  "tools_off",
  "automation",
  "command",
];

const when = (iso: string) =>
  new Date(iso).toLocaleString(lang.value === "it" ? "it-IT" : "en-GB", {
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });

const evWord = (e: RuleEventKind) => t(`rlEv_${e}` as Key);
const fieldWord = (f: RuleField) => t(`rlField_${f}` as Key);
const opWord = (o: RuleOp) => t(`rlOp_${o}` as Key);
const actWord = (a: ActionKind) => t(`rlAct_${a}` as Key);

/** One condition in words: «margin ≤ 5» reads «the margin is at most 5». */
function condSentence(c: RuleCondition): string {
  return t("rlCondLine", { field: fieldWord(c.field), op: opWord(c.op), value: String(c.value) });
}

/** One action in words. */
function actSentence(a: RuleAction): string {
  switch (a.do) {
    case "notify":
      return a.text ? t("rlSayNotifyText", { text: a.text }) : t("rlSayNotify");
    case "ask":
      return t("rlSayAsk");
    case "block":
      return t("rlSayBlock");
    case "stop":
      return a.resume === "auto" ? t("rlSayStopAuto") : t("rlSayStop");
    case "tools_off":
      return t("rlSayToolsOff", { what: [...a.kits, ...a.tools].join(", ") });
    case "automation":
      return t("rlSayAutomation", { name: a.automation });
    case "command":
      return t("rlSayCommand", { command: a.command });
  }
}

/** The rule in three lines: when, if, then. */
export function ruleLines(r: Pick<RuleDraftInput, "when" | "if" | "actions">): string[] {
  const whenLine =
    r.when.event === "schedule"
      ? t("rlSayWhenTime", { cron: r.when.cron ?? "" })
      : t("rlSayWhen", { event: evWord(r.when.event) });
  const conds = r.if ?? [];
  return [
    whenLine,
    ...(conds.length ? [t("rlSayIf", { conds: conds.map(condSentence).join(t("rlAnd")) })] : []),
    t("rlSayThen", { acts: r.actions.map((a) => actSentence(a as RuleAction)).join(", ") }),
  ];
}

/** An action with its defaults, for the editor. */
function freshAction(kind: ActionKind): RuleAction {
  switch (kind) {
    case "notify":
      return { do: "notify", text: "" };
    case "ask":
      return { do: "ask", text: "" };
    case "block":
      return { do: "block", text: "" };
    case "stop":
      return { do: "stop", text: "", scope: "all", resume: "person" };
    case "tools_off":
      return { do: "tools_off", kits: [], tools: [] };
    case "automation":
      return { do: "automation", automation: "" };
    case "command":
      return { do: "command", command: "" };
  }
}

interface Draft {
  name: string;
  description: string;
  when: { event: RuleEventKind; cron?: string; timezone?: string };
  if: RuleCondition[];
  actions: RuleAction[];
  examples: { fire: RuleSample; pass: RuleSample };
}

const blank = (): Draft => ({
  name: "",
  description: "",
  when: { event: "tool" },
  if: [],
  actions: [{ do: "notify", text: "" }],
  examples: { fire: {}, pass: {} },
});

const fromRule = (r: RuleDraftInput): Draft => ({
  name: r.name,
  description: r.description ?? "",
  when: { ...r.when },
  if: (r.if ?? []).map((c) => ({ ...c })),
  actions: r.actions.map((a) => ({ ...(a as RuleAction) })),
  examples: { fire: { ...(r.examples?.fire ?? {}) }, pass: { ...(r.examples?.pass ?? {}) } },
});

/** The draft as the server reads it: examples only on the fields the conditions use. */
function toInput(d: Draft): RuleDraftInput {
  const used = [...new Set(d.if.map((c) => c.field))];
  const pick = (s: RuleSample) => {
    const out: RuleSample = {};
    for (const f of used) {
      const v = s[f];
      if (v === undefined || v === "") continue;
      out[f] = NUMERIC.includes(f) ? Number(v) : String(v);
    }
    return out;
  };
  const when =
    d.when.event === "schedule"
      ? {
          event: d.when.event,
          cron: d.when.cron ?? "",
          ...(d.when.timezone && { timezone: d.when.timezone }),
        }
      : { event: d.when.event };
  return {
    name: d.name.trim(),
    description: d.description,
    when,
    if: d.if.map((c) => ({
      ...c,
      value: NUMERIC.includes(c.field) ? Number(c.value) : String(c.value),
    })),
    actions: d.actions,
    examples: used.length ? { fire: pick(d.examples.fire), pass: pick(d.examples.pass) } : {},
  };
}

/** The rule's editor: when, if, then, its two examples and «Try». */
export function RuleEditor({
  seed,
  submitLabel,
  submit,
  onDone,
  onCancel,
}: {
  seed?: RuleDraftInput | undefined;
  submitLabel?: string;
  submit: (rule: RuleDraftInput, enable: boolean) => Promise<unknown>;
  onDone: () => void;
  onCancel: () => void;
}) {
  const [d, setD] = useState<Draft>(seed ? fromRule(seed) : blank());
  const [trial, setTrial] = useState<RuleTrial | null>(null);
  const [error, setError] = useState<string>();
  const [busy, setBusy] = useState(false);
  const set = (p: Partial<Draft>) => {
    setTrial(null);
    setD({ ...d, ...p });
  };
  const fields = RULE_FIELDS_BY_EVENT[d.when.event];
  const used = [...new Set(d.if.map((c) => c.field))];
  const save = async (enable: boolean) => {
    setBusy(true);
    setError(undefined);
    try {
      await submit(toInput(d), enable);
      onDone();
    } catch (err) {
      setError(explain(err));
    } finally {
      setBusy(false);
    }
  };
  const tryIt = async () => {
    setError(undefined);
    try {
      setTrial(await getApi().tryRule(toInput(d)));
    } catch (err) {
      setError(explain(err));
    }
  };
  const setCond = (i: number, c: Partial<RuleCondition>) =>
    set({ if: d.if.map((x, j) => (j === i ? ({ ...x, ...c } as RuleCondition) : x)) });
  const setAct = (i: number, a: RuleAction) =>
    set({ actions: d.actions.map((x, j) => (j === i ? a : x)) });
  const sample = (kind: "fire" | "pass", f: RuleField, v: string) =>
    set({ examples: { ...d.examples, [kind]: { ...d.examples[kind], [f]: v } } });
  const kinds = ACTIONS.filter(
    (k) => BEFORE.includes(d.when.event) || (k !== "ask" && k !== "block"),
  );
  return (
    <div class="rl-editor">
      <Field label={t("rlName")}>
        <input
          class="wz-field"
          value={d.name}
          placeholder={t("rlNamePh")}
          onInput={(e) => set({ name: (e.target as HTMLInputElement).value })}
        />
      </Field>
      <Field label={t("rlWords")}>
        <textarea
          class="wz-field"
          rows={2}
          value={d.description}
          placeholder={t("rlWordsPh")}
          onInput={(e) => set({ description: (e.target as HTMLTextAreaElement).value })}
        />
      </Field>

      <h3 class="rl-part">
        <span class="rl-part-tag">{t("rlWhen")}</span> {t("rlWhenQ")}
      </h3>
      <DropChoice
        label={t("rlWhen")}
        value={d.when.event}
        options={EVENTS.map((e) => ({ id: e, label: evWord(e), hint: t(`rlEvHint_${e}` as Key) }))}
        onChange={(event) =>
          set({
            when: { event, ...(event === "schedule" && { cron: d.when.cron ?? "0 9 * * 1-5" }) },
            if: d.if.filter((c) => RULE_FIELDS_BY_EVENT[event].includes(c.field)),
            actions: d.actions.filter(
              (a) => BEFORE.includes(event) || (a.do !== "ask" && a.do !== "block"),
            ),
          })
        }
      />
      {d.when.event === "schedule" && (
        <div class="rl-row2">
          <Field label={t("rlCron")} help={t("rlCronHelp")}>
            <input
              class="wz-field mono"
              value={d.when.cron ?? ""}
              onInput={(e) =>
                set({ when: { ...d.when, cron: (e.target as HTMLInputElement).value } })
              }
            />
          </Field>
          <Field label={t("rlTimezone")}>
            <input
              class="wz-field"
              value={d.when.timezone ?? ""}
              placeholder="Europe/Rome"
              onInput={(e) =>
                set({ when: { ...d.when, timezone: (e.target as HTMLInputElement).value } })
              }
            />
          </Field>
        </div>
      )}

      <h3 class="rl-part">
        <span class="rl-part-tag">{t("rlIf")}</span> {t("rlIfQ")}
      </h3>
      {d.if.length === 0 && <p class="dim">{t("rlIfNone")}</p>}
      {d.if.map((c, i) => {
        const numeric = NUMERIC.includes(c.field);
        return (
          <div class="rl-cond" key={String(i)}>
            <DropChoice
              label={t("rlField")}
              value={c.field}
              options={fields.map((f) => ({ id: f, label: fieldWord(f) }))}
              onChange={(field) =>
                setCond(i, {
                  field,
                  op: NUMERIC.includes(field) ? "lte" : "matches",
                  value: NUMERIC.includes(field) ? 5 : "",
                })
              }
            />
            <DropChoice
              label={t("rlOp")}
              value={c.op}
              options={(numeric ? NUMBER_OPS : TEXT_OPS).map((o) => ({ id: o, label: opWord(o) }))}
              onChange={(op) => setCond(i, { op })}
            />
            <input
              class={`wz-field${numeric ? "" : " mono"}`}
              aria-label={t("rlValue")}
              inputMode={numeric ? "decimal" : undefined}
              value={String(c.value)}
              placeholder={c.op === "matches" ? t("rlGlobPh") : ""}
              onInput={(e) => setCond(i, { value: (e.target as HTMLInputElement).value })}
            />
            <button
              type="button"
              class="wz-btn quiet small icon"
              aria-label={t("rlRemoveCond")}
              title={t("rlRemoveCond")}
              onClick={() => set({ if: d.if.filter((_, j) => j !== i) })}
            >
              <IconX size={16} />
            </button>
          </div>
        );
      })}
      {fields.length > 0 && (
        <button
          type="button"
          class="wz-btn small"
          onClick={() => {
            const field = fields[0] as RuleField;
            set({
              if: [
                ...d.if,
                {
                  field,
                  op: NUMERIC.includes(field) ? "lte" : "matches",
                  value: NUMERIC.includes(field) ? 5 : "",
                },
              ],
            });
          }}
        >
          <IconPlus size={16} /> {t("rlAddCond")}
        </button>
      )}

      <h3 class="rl-part">
        <span class="rl-part-tag">{t("rlThen")}</span> {t("rlThenQ")}
      </h3>
      {d.actions.map((a, i) => (
        <div class="rl-act" key={String(i)}>
          <div class="rl-act-head">
            <DropChoice
              label={t("rlThen")}
              value={a.do}
              options={kinds.map((k) => ({
                id: k,
                label: actWord(k),
                hint: t(`rlActHint_${k}` as Key),
              }))}
              onChange={(k) => setAct(i, freshAction(k))}
            />
            {d.actions.length > 1 && (
              <button
                type="button"
                class="wz-btn quiet small icon"
                aria-label={t("rlRemoveAct")}
                title={t("rlRemoveAct")}
                onClick={() => set({ actions: d.actions.filter((_, j) => j !== i) })}
              >
                <IconX size={16} />
              </button>
            )}
          </div>
          {(a.do === "notify" || a.do === "ask" || a.do === "block" || a.do === "stop") && (
            <input
              class="wz-field"
              aria-label={t("rlActText")}
              placeholder={t(a.do === "notify" ? "rlNotifyPh" : "rlReasonPh")}
              value={a.text}
              onInput={(e) => setAct(i, { ...a, text: (e.target as HTMLInputElement).value })}
            />
          )}
          {a.do === "notify" && (
            <div class="wz-chips st-chips one">
              {(["page", "app", "chats"] as const).map((to) => {
                const now = a.to ?? ["page", "app", "chats"];
                const on = now.includes(to);
                return (
                  <button
                    key={to}
                    type="button"
                    class={`wz-chip${on ? " on" : ""}`}
                    aria-pressed={on}
                    onClick={() =>
                      setAct(i, { ...a, to: on ? now.filter((x) => x !== to) : [...now, to] })
                    }
                  >
                    {t(`rlTo_${to}` as Key)}
                  </button>
                );
              })}
            </div>
          )}
          {a.do === "stop" && (
            <>
              <Seg
                label={t("rlScope")}
                value={a.scope}
                options={[
                  ["all", t("rlScope_all")],
                  ["project", t("rlScope_project")],
                  ["agent", t("rlScope_agent")],
                ]}
                onChange={(scope) => setAct(i, { ...a, scope })}
              />
              <Seg
                label={t("rlResume")}
                value={a.resume}
                options={[
                  ["person", t("rlResume_person")],
                  ["auto", t("rlResume_auto")],
                ]}
                onChange={(resume) => setAct(i, { ...a, resume })}
              />
            </>
          )}
          {a.do === "tools_off" && (
            <input
              class="wz-field mono"
              aria-label={t("rlToolsOff")}
              placeholder={t("rlToolsOffPh")}
              value={[...a.kits.map((k) => `kit:${k}`), ...a.tools].join(", ")}
              onInput={(e) => {
                const words = (e.target as HTMLInputElement).value
                  .split(",")
                  .map((w) => w.trim())
                  .filter(Boolean);
                setAct(i, {
                  ...a,
                  kits: words.filter((w) => w.startsWith("kit:")).map((w) => w.slice(4)),
                  tools: words.filter((w) => !w.startsWith("kit:")),
                });
              }}
            />
          )}
          {a.do === "automation" && (
            <input
              class="wz-field"
              aria-label={t("rlAutomation")}
              placeholder={t("rlAutomationPh")}
              value={a.automation}
              onInput={(e) => setAct(i, { ...a, automation: (e.target as HTMLInputElement).value })}
            />
          )}
          {a.do === "command" && (
            <>
              <input
                class="wz-field mono"
                aria-label={t("rlCommand")}
                placeholder="./scripts/save.sh"
                value={a.command}
                onInput={(e) => setAct(i, { ...a, command: (e.target as HTMLInputElement).value })}
              />
              <input
                class="wz-field"
                aria-label={t("rlProject")}
                placeholder={t("rlProjectPh")}
                value={a.project ?? ""}
                onInput={(e) => {
                  const project = (e.target as HTMLInputElement).value;
                  const { project: _p, ...rest } = a;
                  setAct(i, project ? { ...rest, project } : rest);
                }}
              />
              <p class="dim small">{t("rlCommandSafe")}</p>
            </>
          )}
        </div>
      ))}
      {d.actions.length < 10 && (
        <button
          type="button"
          class="wz-btn small"
          onClick={() => set({ actions: [...d.actions, freshAction("notify")] })}
        >
          <IconPlus size={16} /> {t("rlAddAct")}
        </button>
      )}

      {used.length > 0 && (
        <>
          <h3 class="rl-part">
            <span class="rl-part-tag">{t("rlExamples")}</span> {t("rlExamplesQ")}
          </h3>
          <div class="rl-examples">
            {(["fire", "pass"] as const).map((kind) => (
              <div class={`rl-example ${kind}`} key={kind}>
                <b>{t(kind === "fire" ? "rlExFire" : "rlExPass")}</b>
                {used.map((f) => (
                  <Field key={f} label={fieldWord(f)}>
                    <input
                      class="wz-field"
                      value={String(d.examples[kind][f] ?? "")}
                      onInput={(e) => sample(kind, f, (e.target as HTMLInputElement).value)}
                    />
                  </Field>
                ))}
                {trial && trial[kind] !== null && (
                  <span class={`rl-verdict ${trial[kind] ? "ok" : "bad"}`}>
                    {t(trial[kind] ? "rlExOk" : "rlExBad")}
                  </span>
                )}
              </div>
            ))}
          </div>
        </>
      )}
      {trial && (
        <div class={`notice ${trial.ok ? "ok" : "error"}`} role="status">
          {trial.ok ? t("rlTrialOk") : trial.problems.join(" · ")}
        </div>
      )}
      {error && <p class="notice error">{error}</p>}
      <Acts>
        <button type="button" class="wz-btn quiet" onClick={onCancel}>
          {t("cancel")}
        </button>
        <button type="button" class="wz-btn" onClick={() => void tryIt()}>
          <IconPlay size={16} /> {t("rlTry")}
        </button>
        <button
          type="button"
          class="wz-btn"
          disabled={busy || !d.name.trim()}
          onClick={() => void save(false)}
        >
          {t("rlSaveOff")}
        </button>
        <button
          type="button"
          class="wz-btn primary"
          disabled={busy || !d.name.trim()}
          onClick={() => void save(true)}
        >
          {submitLabel ?? t("rlSaveOn")}
        </button>
      </Acts>
    </div>
  );
}

const RULE_WORDS: MagicWords = {
  title: "rlMagic",
  lead: "rlMagicLead",
  ask: "rlMagicAsk",
  placeholder: "rlMagicPh",
  examples: ["rlMagicEx1", "rlMagicEx2", "rlMagicEx3"],
  promises: ["rlMagicPromise1", "rlMagicPromise2", "rlMagicPromise3"],
};

/** A magic rule's window: God's proposal beside (on a phone above) the conversation. */
function MagicRuleChat({
  m,
  onClose,
  onChange,
}: {
  m: MagicRule;
  onClose: () => void;
  onChange: () => void;
}) {
  const [editing, setEditing] = useState(false);
  const [why, setWhy] = useState<string | null>(null);
  const [error, setError] = useState<string>();
  const p = m.proposal;
  if (editing && p)
    return (
      <Modal wide title={p.rule.name} onClose={() => setEditing(false)}>
        <RuleEditor
          seed={p.rule}
          submitLabel={t("rlMagicApprove")}
          submit={(rule) => getApi().approveMagicRule(m.id, rule)}
          onDone={() => {
            onChange();
            onClose();
          }}
          onCancel={() => setEditing(false)}
        />
      </Modal>
    );
  return (
    <Modal
      wide
      title={`${t("rlMagic")}: ${m.title}`}
      sub={t(`axMagicState_${m.status}` as Key)}
      icon={
        <span class="mg-orb">
          <IconSpark size={20} />
        </span>
      }
      class="mg-window mg-chat-window"
      onClose={onClose}
    >
      <div class="mg-chat">
        <aside class="mg-side">
          <Steps status={m.status} labels={["rlMagicStep1", "rlMagicStep2", "rlMagicStep3"]} />
          {m.status === "ready" && p && (
            <section class="mg-proposal">
              <div class="mg-proposal-head">
                <span class="mg-orb small">
                  <IconSpark size={16} />
                </span>
                <b>{t("rlMagicProposal")}</b>
              </div>
              <h3>{p.rule.name}</h3>
              {p.summary && <p class="mg-summary">{p.summary}</p>}
              <div class="ax-says">
                <div class="ax-says-lines">
                  {ruleLines(p.rule).map((line, i) => (
                    <p key={String(i)} class={i === 0 ? "first" : ""}>
                      {line}
                    </p>
                  ))}
                </div>
              </div>
              {p.missing.length > 0 && (
                <div class="mg-missing" role="status">
                  <p class="mg-missing-lead">
                    <IconAlert size={18} /> {t("rlMagicMissing")}
                  </p>
                  <ul>
                    {p.missing.map((x) => (
                      <li key={x}>{x}</li>
                    ))}
                  </ul>
                </div>
              )}
              <p class={`notice ${p.trial.ok ? "ok" : "error"}`}>
                {p.trial.ok
                  ? t("rlTrialOk")
                  : `${t("rlMagicNotTested")} ${p.trial.problems.join(" · ")}`}
              </p>
              {why !== null && (
                <Field label={t("axMagicWhy")}>
                  <textarea
                    class="wz-field"
                    rows={2}
                    value={why}
                    onInput={(e) => setWhy((e.target as HTMLTextAreaElement).value)}
                  />
                </Field>
              )}
              {error && <p class="notice error">{error}</p>}
              <div class="mg-acts">
                {why === null ? (
                  <button type="button" class="wz-btn quiet" onClick={() => setWhy("")}>
                    {t("rlMagicRefuse")}
                  </button>
                ) : (
                  <button
                    type="button"
                    class="wz-btn quiet"
                    onClick={() =>
                      void attempt(() =>
                        getApi().rejectMagicRule(m.id, why.trim() || undefined),
                      ).then(() => {
                        setWhy(null);
                        onChange();
                      })
                    }
                  >
                    {t("axMagicSendNo")}
                  </button>
                )}
                <button type="button" class="wz-btn" onClick={() => setEditing(true)}>
                  {t("rlMagicChange")}
                </button>
                <button
                  type="button"
                  class="wz-btn primary"
                  onClick={() =>
                    void getApi()
                      .approveMagicRule(m.id)
                      .then(() => {
                        onChange();
                        onClose();
                      })
                      .catch((err) => setError(explain(err)))
                  }
                >
                  {t("rlMagicApprove")}
                </button>
              </div>
            </section>
          )}
          {m.status === "done" && <p class="notice ok">{t("rlMagicDone")}</p>}
          {m.status === "building" && (
            <div class="mg-hint">
              <span>{t("rlMagicBuilding")}</span>
              <button
                type="button"
                class="wz-link inl"
                onClick={() =>
                  void attempt(() => getApi().dismissMagicRule(m.id)).then(() => {
                    onChange();
                    onClose();
                  })
                }
              >
                {t("axMagicDismiss")}
              </button>
            </div>
          )}
        </aside>
        <div class="mg-chat-body">
          <Chat sessionId={m.sessionId} agentId={m.agentId} />
        </div>
      </div>
    </Modal>
  );
}

const CHANGE_WORDS: Record<RuleVersion["change"], Key> = {
  created: "rlChCreated",
  changed: "rlChChanged",
  enabled: "rlChEnabled",
  disabled: "rlChDisabled",
  removed: "rlChRemoved",
  undone: "rlChUndone",
};

/** A rule's history, newest first, with «Undo the last change». */
function History({
  id,
  name,
  onClose,
  onChange,
}: {
  id: string;
  name: string;
  onClose: () => void;
  onChange: () => void;
}) {
  const [list, setList] = useState<RuleVersion[] | null>(null);
  const load = () =>
    void getApi()
      .ruleHistory(id)
      .then(setList, () => setList([]));
  useEffect(load, [id]);
  return (
    <Modal title={t("rlHistoryOf", { name })} onClose={onClose}>
      <ol class="rl-history">
        {(list ?? []).map((v) => (
          <li key={`${v.version}`}>
            <span class="rl-h-when">{when(v.at)}</span>
            <b>{t(CHANGE_WORDS[v.change])}</b>
            <span class="dim">
              {t("rlHistoryBy", {
                by: v.by === "person" ? t("rlByYou") : v.by,
                version: String(v.version),
              })}
            </span>
            {v.rule && <small>{ruleLines(v.rule).join(" · ")}</small>}
          </li>
        ))}
      </ol>
      <Acts>
        <button type="button" class="wz-btn quiet" onClick={onClose}>
          {t("close")}
        </button>
        <button
          type="button"
          class="wz-btn"
          disabled={!list?.length}
          onClick={() =>
            void attempt(() => getApi().undoRule(id)).then(() => {
              onChange();
              load();
            })
          }
        >
          <IconUndo size={16} /> {t("rlUndo")}
        </button>
      </Acts>
    </Modal>
  );
}

/** One rule: its switch, its words, when it last acted, and what can be done with it. */
function RuleCard({
  r,
  onEdit,
  onHistory,
  onChange,
}: {
  r: PersonRule;
  onEdit: () => void;
  onHistory: () => void;
  onChange: () => void;
}) {
  const [error, setError] = useState<string>();
  const [hook, setHook] = useState<string | null>(null);
  return (
    <div class={`rl-card${r.enabled ? " on" : ""}`}>
      <div class="rl-card-head">
        <span class="rl-card-ico">
          {BEFORE.includes(r.when.event) ? (
            <IconShield size={18} />
          ) : r.when.event === "schedule" ? (
            <IconClock size={18} />
          ) : (
            <IconZap size={18} />
          )}
        </span>
        <div class="rl-card-title">
          <b>{r.name}</b>
          <small>
            {r.origin === "god"
              ? t("rlByGod")
              : r.origin === "template"
                ? t("rlByTemplate")
                : t("rlByYou")}
            {r.lastFiredAt ? ` · ${t("rlLastFired", { when: when(r.lastFiredAt) })}` : ""}
          </small>
        </div>
        <Switch
          on={r.enabled}
          label={t("rlOnOff", { name: r.name })}
          onChange={(on) => {
            setError(undefined);
            void getApi()
              .enableRule(r.id, on)
              .then(onChange)
              .catch((err) => setError(explain(err)));
          }}
        />
      </div>
      {r.description && <p class="rl-card-words">{r.description}</p>}
      <div class="rl-lines">
        {ruleLines(r).map((line, i) => (
          <p key={String(i)}>{line}</p>
        ))}
      </div>
      {error && <p class="notice error">{error}</p>}
      <div class="rl-card-acts">
        <button type="button" class="wz-btn small" onClick={onEdit}>
          <IconPencil size={15} /> {t("rlEdit")}
        </button>
        <button type="button" class="wz-btn small" onClick={onHistory}>
          <IconUndo size={15} /> {t("rlHistory")}
        </button>
        {r.when.event === "webhook" && (
          <button
            type="button"
            class="wz-btn small"
            onClick={() =>
              void askConfirm(t("rlHookQ"), { text: t("rlHookQLead"), yes: t("rlHookMake") }).then(
                (yes) => {
                  if (!yes) return;
                  void getApi()
                    .rotateRuleSecret(r.id)
                    .then((x) => setHook(x.webhookSecret))
                    .catch((err) => setError(explain(err)));
                },
              )
            }
          >
            <IconLink size={15} /> {t("rlHook")}
          </button>
        )}
        <button
          type="button"
          class="wz-btn small quiet"
          onClick={() =>
            void askConfirm(t("rlRemoveQ", { name: r.name }), {
              text: t("rlRemoveLead"),
              yes: t("rlRemove"),
              danger: true,
            }).then((yes) => {
              if (yes) void attempt(() => getApi().removeRule(r.id)).then(onChange);
            })
          }
        >
          <IconTrash size={15} /> {t("rlRemove")}
        </button>
      </div>
      {hook && (
        <Modal title={t("rlHookTitle", { name: r.name })} onClose={() => setHook(null)}>
          <p class="wz-lead2">{t("rlHookLead")}</p>
          <Field label={t("rlHookAddress")}>
            <input
              class="wz-field mono"
              readOnly
              value={`${location.origin}/api/rules/${r.id}/hook`}
            />
          </Field>
          <Field label={t("rlHookSecret")} help={t("rlHookSecretHelp")}>
            <input class="wz-field mono" readOnly value={hook} />
          </Field>
          <Acts>
            <button type="button" class="wz-btn primary" onClick={() => setHook(null)}>
              {t("close")}
            </button>
          </Acts>
        </Modal>
      )}
    </div>
  );
}

/** A stop a rule put in place, with «Resume». */
function HoldBar({ h, onChange }: { h: RuleHold; onChange: () => void }) {
  return (
    <div class="rl-hold" role="alert">
      <span class="rl-hold-ico">
        <IconStop size={20} />
      </span>
      <div>
        <b>{t("rlHoldTitle", { name: h.ruleName })}</b>
        <small>
          {h.reason} · {t("rlHoldSince", { when: when(h.at) })}
        </small>
      </div>
      <button
        type="button"
        class="wz-btn primary small"
        onClick={() => void attempt(() => getApi().resumeRules(h.ruleId)).then(onChange)}
      >
        <IconPlay size={15} /> {t("rlResumeNow")}
      </button>
    </div>
  );
}

function FireRow({ f }: { f: RuleFire }) {
  return (
    <li>
      <span class="rl-h-when">{when(f.at)}</span>
      <b>{f.ruleName}</b>
      <span class="dim">{f.results.join(" · ")}</span>
    </li>
  );
}

type Loaded = Awaited<ReturnType<ReturnType<typeof getApi>["rules"]>>;

/** Settings > Rules. */
export function Rules() {
  const [data, setData] = useState<Loaded | null>(null);
  const [magic, setMagic] = useState<MagicRule[]>([]);
  const [editing, setEditing] = useState<PersonRule | "new" | null>(null);
  const [history, setHistory] = useState<PersonRule | null>(null);
  const [starting, setStarting] = useState(false);
  const [open, setOpen] = useState<MagicRule | null>(null);
  const [error, setError] = useState<string>();
  const load = () => {
    void getApi()
      .rules()
      .then(setData, (err) => setError(explain(err)));
    void getApi()
      .magicRules()
      .then(setMagic, () => setMagic([]));
  };
  // Read at once, and again whenever the server says the rules changed (a fire, a stop, a magic
  // rule's proposal: `rules.changed`), never on a timer.
  const version = rulesVersion.value;
  useEffect(() => {
    load();
  }, [version]);
  const reopen = async (id: string) => {
    load();
    const m = await getApi()
      .magicRule(id)
      .catch(() => null);
    if (m && open?.id === id) setOpen(m);
  };
  useEffect(() => {
    if (open) void reopen(open.id);
  }, [version]);
  const rules = data?.rules ?? [];
  const hasMargin = rules.some((r) => r.origin === "template");
  return (
    <WzPage
      class="rl-page"
      after={
        <>
          {editing && (
            <Modal
              wide
              title={editing === "new" ? t("rlNew") : editing.name}
              onClose={() => setEditing(null)}
            >
              <RuleEditor
                seed={editing === "new" ? undefined : editing}
                submit={async (rule, enable) => {
                  if (editing === "new") return getApi().createRule(rule, enable);
                  const saved = await getApi().updateRule(editing.id, rule);
                  if (enable && !saved.enabled) await getApi().enableRule(saved.id, true);
                  return saved;
                }}
                onDone={() => {
                  setEditing(null);
                  load();
                }}
                onCancel={() => setEditing(null)}
              />
            </Modal>
          )}
          {history && (
            <History
              id={history.id}
              name={history.name}
              onClose={() => setHistory(null)}
              onChange={load}
            />
          )}
          {starting && (
            <MagicStart<MagicRule>
              words={RULE_WORDS}
              start={(text) => getApi().startMagicRule(text)}
              onClose={() => setStarting(false)}
              onStarted={(m) => {
                setStarting(false);
                setOpen(m);
                load();
              }}
            />
          )}
          {open && (
            <MagicRuleChat
              m={open}
              onClose={() => setOpen(null)}
              onChange={() => void reopen(open.id)}
            />
          )}
        </>
      }
    >
      <Head eyebrow={t("rlEyebrow")} q={t("rlQ")} lead={t("rlLead")} />
      {(data?.holds ?? []).map((h) => (
        <HoldBar key={h.ruleId} h={h} onChange={load} />
      ))}
      {error && <p class="notice error">{error}</p>}
      <div class="rl-start">
        <button type="button" class="wz-btn primary" onClick={() => setStarting(true)}>
          <IconSpark size={18} /> {t("rlMagic")}
        </button>
        <button type="button" class="wz-btn" onClick={() => setEditing("new")}>
          <IconPlus size={18} /> {t("rlNew")}
        </button>
      </div>
      {magic.length > 0 && (
        <div class="rl-magic-list">
          {magic
            .filter((m) => m.status !== "done")
            .map((m) => (
              <button key={m.id} type="button" class="rl-magic-item" onClick={() => setOpen(m)}>
                <IconSpark size={16} />
                <span>{m.title}</span>
                <small>{t(`axMagicState_${m.status}` as Key)}</small>
              </button>
            ))}
        </div>
      )}
      <Sub title={t("rlListTitle")} lead={rules.length ? t("rlListLead") : t("rlNone")} />
      {rules.map((r) => (
        <RuleCard
          key={r.id}
          r={r}
          onEdit={() => setEditing(r)}
          onHistory={() => setHistory(r)}
          onChange={load}
        />
      ))}
      {!hasMargin && (
        <SCard icon={<IconBell size={20} />} title={t("rlTplMargin")} q={t("rlTplMarginQ")}>
          <p class="dim">{t("rlTplMarginLead")}</p>
          <Acts>
            <button
              type="button"
              class="wz-btn"
              onClick={() =>
                void attempt(() => getApi().addRuleTemplate("weekly-margin")).then(load)
              }
            >
              <IconPlus size={16} /> {t("rlTplAdd")}
            </button>
          </Acts>
        </SCard>
      )}
      {(data?.fires.length ?? 0) > 0 && (
        <>
          <Sub title={t("rlFiresTitle")} lead={t("rlFiresLead")} />
          <ol class="rl-history">
            {(data?.fires ?? []).map((f) => (
              <FireRow key={f.id} f={f} />
            ))}
          </ol>
        </>
      )}
    </WzPage>
  );
}
