// The weekly margin of a flat subscription, as Officina's usage bar shows it: how far ahead of (or
// behind) an even pace the week's use is. Pure and tested as a table; the page and the app follow
// these two functions (the app's mirror is `apps/companion/lib/api/plan_margin.dart`).

export const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/**
 * Margin in points: the share of the 7-day window already elapsed (its reset time minus 7 days,
 * up to `now`) minus the share used. Positive: room to spare; negative: ahead of the pace.
 * Null when the window's reset time is missing, unreadable or already past (a fresh window shows
 * 0% and no margin until the plan reports it again).
 */
export function weeklyMargin(
  w: { usedPct: number | null; resetsAt?: string | undefined },
  now: number,
): number | null {
  if (w.usedPct === null || !w.resetsAt) return null;
  const resets = Date.parse(w.resetsAt);
  if (!Number.isFinite(resets) || resets <= now) return null;
  const elapsed = Math.min(1, Math.max(0, (now - (resets - WEEK_MS)) / WEEK_MS)) * 100;
  return Math.round(elapsed - w.usedPct);
}

/** The 7-day bar's colour, from its margin and not from the percentage. */
export type MarginLevel = "ok" | "warn" | "err";

export const MARGIN_COMFORTABLE = 10;

export function marginLevel(margin: number): MarginLevel {
  if (margin >= MARGIN_COMFORTABLE) return "ok";
  if (margin >= 0) return "warn";
  return "err";
}

/** «+17», «−4», «0»: the margin as written next to the 7-day value (a true minus sign). */
export function marginText(margin: number): string {
  return margin > 0 ? `+${margin}` : margin < 0 ? `−${-margin}` : "0";
}
