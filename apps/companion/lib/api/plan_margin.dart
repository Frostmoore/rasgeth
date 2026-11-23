// The weekly margin of a flat subscription (3.12.3), mirror of `packages/protocol/src/plan-margin.ts`
// (the page's and the app's bars follow the same two functions; the vectors are in the tests of both).

const weekMs = 7 * 24 * 60 * 60 * 1000;

/// Margin in points: the share of the 7-day window already elapsed (its reset time minus 7 days,
/// up to [now]) minus the share used. Null without a usable reset time, a figure, or when the
/// window is already past.
int? weeklyMargin({required double? usedPct, required String? resetsAt, required DateTime now}) {
  if (usedPct == null || resetsAt == null) return null;
  final resets = DateTime.tryParse(resetsAt);
  if (resets == null) return null;
  final resetMs = resets.millisecondsSinceEpoch;
  final nowMs = now.millisecondsSinceEpoch;
  if (resetMs <= nowMs) return null;
  final elapsed = ((nowMs - (resetMs - weekMs)) / weekMs).clamp(0.0, 1.0) * 100;
  // JavaScript's Math.round: halves go up (also for negative values).
  return (elapsed - usedPct + 0.5).floor();
}

/// The 7-day bar's colour from its margin (comfortable from +10, tight from 0, over below).
enum MarginLevel { ok, warn, err }

const marginComfortable = 10;

MarginLevel marginLevel(int margin) => margin >= marginComfortable
    ? MarginLevel.ok
    : margin >= 0
    ? MarginLevel.warn
    : MarginLevel.err;

/// «+17», «−4», «0» (a true minus sign).
String marginText(int margin) => margin > 0
    ? '+$margin'
    : margin < 0
    ? '−${-margin}'
    : '0';
