// «Start from…» in the create-agent flow (3.12.3): the ready-made sets, from the protocol's one
// table. A set is not a feature: it sets up an agent. Each card says what the agent does, which
// model it wants, what it always asks you and what is left to connect.
import { AGENT_SETS, type AgentSet, type Words } from "@redgiant/protocol";
import { lang, t } from "../i18n.js";
import { Choice } from "./ui.js";

/** A set's words in the interface's language. */
export const say = (w: Words): string => w[lang.value] ?? w.en;

/** What the set wants connected, in words. */
const KIND_WORD = {
  mailbox: "connMailboxes",
  chat: "connChats",
  calendar: "connCalendars",
  mcp: "connServices",
} as const;

export function SetDetails({ set }: { set: AgentSet }) {
  const wants = set.wants.map((k) => t(KIND_WORD[k]).toLowerCase()).join(", ");
  return (
    <ul class="set-details ui-help">
      <li>
        {t("setModel", {
          speed: t(`setSpeed_${set.model.speed}`),
          effort: t(`setEffort_${set.model.effort}`),
        })}
      </li>
      <li>{t("setAsks", { what: set.asks.map((a) => say(a.text)).join("; ") })}</li>
      <li>{wants ? t("setWants", { what: wants }) : t("setWantsNothing")}</li>
    </ul>
  );
}

/** The choice of a set, or none: the agent is then made step by step as before. */
export function SetPicker({
  value,
  onChange,
}: {
  value: AgentSet["id"] | undefined;
  onChange: (id: AgentSet["id"] | undefined) => void;
}) {
  const chosen = AGENT_SETS.find((s) => s.id === value);
  return (
    <div class="set-picker">
      <h3>{t("setStartFrom")}</h3>
      <p class="ui-help">{t("setStartHelp")}</p>
      <Choice<AgentSet["id"] | "none">
        value={[value ?? "none"]}
        onChange={([v]) => onChange(v && v !== "none" ? v : undefined)}
        options={[
          { id: "none", title: t("setNone"), description: t("setNoneHint") },
          ...AGENT_SETS.map((s) => ({
            id: s.id,
            title: say(s.name),
            description: say(s.description),
          })),
        ]}
      />
      {chosen && <SetDetails set={chosen} />}
    </div>
  );
}
