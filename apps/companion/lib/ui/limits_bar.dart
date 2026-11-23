// The spending and limits in a conversation's header (3.9.0), as the page's bars at the top:
// «Total [bar] 63%», a project's or an agent's budget, a plan's windows, a local model's context.
// Same colours and thresholds as `styles.css` (`.limit`): green, yellow from 70%, red from 90%.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../api/budgets.dart';
import '../api/conversation.dart';
import '../api/live_model.dart';
import '../api/metrics.dart';
import '../api/plan_margin.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';

/// How the bars sit in a header [room] wide: all in a row when they fit (up to the page's three),
/// else the first two one over the other (the header is as tall as the mascot), else the first.
/// [widths] are the bars' own widths; the gap between two in a row is [limitGap].
({int count, bool stacked}) limitsLayout(List<double> widths, double room) {
  final take = widths.take(3).toList();
  final inRow = take.fold<double>(0, (a, w) => a + w) + limitGap * (take.length - 1).clamp(0, 2);
  if (take.isEmpty) return (count: 0, stacked: false);
  if (inRow <= room) return (count: take.length, stacked: false);
  if (take.length >= 2 && take[0] <= room && take[1] <= room) return (count: 2, stacked: true);
  if (take[0] <= room) return (count: 1, stacked: false);
  return (count: 0, stacked: false);
}

const limitGap = 10.0;

/// The bars' text style (the page's 12px).
const _limitFont = 12.0;

/// The last answer's figures in [view] (the local model's context bar).
MessageMetrics? lastMetricsOf(SessionView view) {
  for (final e in view.events.reversed) {
    if (e.type == 'message.assistant') return MessageMetrics.fromJson(e.payload?['metrics']);
  }
  return null;
}

class HeaderLimits extends StatelessWidget {
  const HeaderLimits({super.key, required this.sessionId, required this.room, this.agent});

  final String sessionId;
  final Agent? agent;

  /// The width the header leaves to the bars.
  final double room;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final view = app.live.view(sessionId);
    return ListenableBuilder(
      listenable: Listenable.merge([app.spend, view]),
      builder: (context, _) {
        final l = AppLocalizations.of(context);
        final a = agent;
        final row = app.live.sessions.where((s) => s.id == sessionId).firstOrNull;
        final model = row?.model ?? a?.model ?? (a == null ? null : app.inheritedModelOf(a));
        final bars = headerBars(
          provider: model?.provider,
          plans: app.spend.plans,
          budgets: app.spend.budgets,
          words: LimitWords(
            total: l.limitsTotal,
            spent: l.limitsSpent,
            context: l.limitsContext,
            weekShort: l.limitsWeekShort,
            resets: l.cvLimitResets('{when}'),
            readAt: l.cvLimitReadAt('{when}'),
            notRead: l.cvLimitNotRead,
            marginTip: l.cvLimitMarginTip('{margin}'),
          ),
          whenText: DateFormat(
            'EEE d MMM HH:mm',
            Localizations.localeOf(context).toString(),
          ).format,
          lastMetrics: lastMetricsOf(view),
          agentName: (id) => app.agents.where((x) => x.id == id).firstOrNull?.name,
        );
        if (bars.isEmpty) return const SizedBox.shrink();
        final scaler = MediaQuery.textScalerOf(context);
        final fit = limitsLayout([for (final b in bars) LimitBarView.widthOf(b, scaler)], room);
        if (fit.count == 0) return const SizedBox.shrink();
        final shown = [for (final b in bars.take(fit.count)) LimitBarView(bar: b)];
        if (fit.stacked) {
          return Column(
            key: const Key('header-limits'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [shown[0], const SizedBox(height: 3), shown[1]],
          );
        }
        return Row(
          key: const Key('header-limits'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, w) in shown.indexed) ...[if (i > 0) const SizedBox(width: limitGap), w],
          ],
        );
      },
    );
  }
}

/// One bar: the name, the bar (unless only a figure), the percentage.
class LimitBarView extends StatelessWidget {
  const LimitBarView({super.key, required this.bar});

  final LimitBar bar;

  static double _text(String t, TextScaler scaler, {bool bold = false}) {
    final p = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(
          fontSize: _limitFont,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  /// How wide [bar] is drawn (the name is cut at 96).
  static double widthOf(LimitBar bar, TextScaler scaler) =>
      _text(bar.name, scaler).clamp(0, 96) +
      5 +
      (bar.bar ? 46 + 5 : 0) +
      _text(bar.text, scaler, bold: bar.level == BarLevel.high) +
      (bar.margin == null ? 0 : 5 + _text(marginText(bar.margin!), scaler, bold: true)) +
      1;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final fill = switch (bar.level) {
      BarLevel.high => c.err,
      BarLevel.medium => c.warn,
      BarLevel.normal => c.ok,
    };
    final high = bar.level == BarLevel.high;
    return Tooltip(
      message: bar.title,
      child: Row(
        key: Key('limit-${bar.key}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              bar.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: _limitFont, color: c.dim),
            ),
          ),
          const SizedBox(width: 5),
          if (bar.bar) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                width: 46,
                height: 6,
                child: ColoredBox(
                  color: c.panel2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      key: Key('limit-fill-${bar.key}'),
                      widthFactor: ((bar.pct ?? 0) / 100).clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: fill),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            bar.text,
            style: TextStyle(
              fontSize: _limitFont,
              color: high ? c.err : c.text,
              fontWeight: high ? FontWeight.w600 : FontWeight.normal,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (bar.margin != null) ...[
            const SizedBox(width: 5),
            Text(
              marginText(bar.margin!),
              key: Key('limit-margin-${bar.key}'),
              style: TextStyle(
                fontSize: _limitFont,
                fontWeight: FontWeight.w600,
                color: fill,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
