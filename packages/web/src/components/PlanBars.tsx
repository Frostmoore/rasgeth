// The header's bars of a flat subscription (G21, 3.12.3): the 5-hour window (a dash while empty),
// the 7-day window with its margin against an even pace (colour from the margin, like Officina's
// bar) and the per-model windows. The tooltip says each window's reset time and when the plan was
// last read, in the person's timezone.
import { marginLevel, marginText, weeklyMargin } from "@redgiant/protocol";
import { lang, t } from "../i18n.js";
import type { PlanLimits } from "../api.js";
import { planBars } from "../state.js";

const level = (pct: number) => (pct >= 90 ? "high" : pct >= 70 ? "medium" : "");

/** The margin's colour class for the bar: comfortable green, tight amber, over red. */
const MARGIN_CLASS = { ok: "", warn: "medium", err: "high" } as const;

/** One bar of the header: a name, how full, the percentage, and an optional margin. */
export function Bar({
  name,
  pct,
  title,
  tone,
  margin,
}: {
  name: string;
  pct: number | null;
  title: string;
  /** Overrides the colour that the percentage would give (the 7-day bar's margin). */
  tone?: "" | "medium" | "high";
  margin?: number | null;
}) {
  const cls = tone ?? (pct === null ? "" : level(pct));
  return (
    <span class={`limit ${cls}`} title={title}>
      <span class="limit-name">{name}</span>
      <span class="limit-bar">
        <span style={{ width: `${Math.min(100, pct ?? 0)}%` }} />
      </span>
      <span class="limit-num">{pct === null ? "–" : `${Math.round(pct)}%`}</span>
      {margin != null && (
        <span class={`limit-margin ${marginLevel(margin)}`}>{marginText(margin)}</span>
      )}
    </span>
  );
}

/** A moment in the person's timezone, short: «Tue 17:59». */
export const whenText = (iso: string | number): string =>
  new Date(iso).toLocaleString(lang.value === "it" ? "it-IT" : "en-GB", {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });

export function PlanBars({ plan, now = Date.now() }: { plan: PlanLimits; now?: number }) {
  const read = plan.readAt ? t("limitReadAt", { when: whenText(plan.readAt) }) : t("limitNotRead");
  return (
    <div class="limits">
      {planBars(plan.windows).map((w) => {
        // The week's short name follows the page's language, whatever the provider sent.
        const name = w.id === "7d" ? t("limitWeekShort") : w.label;
        const week = w.id === "7d";
        const margin = week ? weeklyMargin(w, now) : null;
        const lines = [`${name}: ${w.usedPct === null ? "–" : `${w.usedPct}%`}`];
        if (margin !== null) lines[0] += ` · ${marginText(margin)}`;
        if (margin !== null) lines.push(t("limitMarginTip", { margin: marginText(margin) }));
        if (w.resetsAt) lines.push(t("limitResets", { when: whenText(w.resetsAt) }));
        lines.push(read);
        return (
          <Bar
            key={w.id}
            name={name}
            pct={w.usedPct}
            margin={margin}
            {...(margin !== null && { tone: MARGIN_CLASS[marginLevel(margin)] })}
            title={lines.join("\n")}
          />
        );
      })}
    </div>
  );
}
