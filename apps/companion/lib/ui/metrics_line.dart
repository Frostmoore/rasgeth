// The figures under an agent's answer (G40.17), the page's MetricsBar
// (packages/web/src/components/MetricsBar.tsx): a thin bar of the context window (read from the
// cache, read new, generated) with the summary's mark, and the numbers beside it: read (cache),
// generated, context, prefill, generation and tok/s, the SSD restore, the cost, the time.
// On a computer the whole line; on a phone-sized window a short one that opens at a touch.
import 'package:flutter/material.dart';

import '../api/metrics.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'systems.dart';
import 'highlight.dart' show monoFallback, monoFamily;

/// The page's `.metrics-bar` colours: the track and the cached piece (the same in both themes).
const metricsTrack = Color(0xFF241D1E);
const metricsCached = Color(0xFF7A2F28);

/// The page's `.metrics-text em` (the cache figure).
const metricsCacheText = Color(0xFFC46B5F);

/// Windows narrower than this get the short line (a phone).
const metricsCompactBelow = 600.0;

class MetricsLine extends StatefulWidget {
  const MetricsLine({
    super.key,
    required this.metrics,
    this.model,
    this.costUsd,
    this.costUnknown = false,
    this.compactAt = 0.8,
    this.compact,
  });

  final MessageMetrics metrics;
  final String? model;
  final double? costUsd;
  final bool costUnknown;

  /// Where a summary is made (G24.14c): the yellow mark on the bar.
  final double? compactAt;

  /// The short form; null: by the window's width.
  final bool? compact;

  @override
  State<MetricsLine> createState() => _MetricsLineState();
}

class _MetricsLineState extends State<MetricsLine> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final m = widget.metrics;
    final compact = widget.compact ?? MediaQuery.sizeOf(context).width < metricsCompactBelow;
    final style = TextStyle(
      fontSize: 11.5,
      color: c.dim,
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      height: 1.35,
    );
    final time = clock(m.endedAt ?? m.startedAt, l.localeName);
    final bar = _Bar(
      m: m,
      compactAt: widget.compactAt,
      mark: c.warn,
      fresh: c.accent,
      out: c.accent2,
    );

    if (compact && !_open) {
      // read · generated · context · tok/s · time
      final short = [
        '${l.metricsInput} ${kTokens(m.inputTokens)}',
        '${l.metricsOutput} ${kTokens(m.outputTokens)}',
        '${m.usedPercent}%',
        ?m.tokPerSecText,
        time,
      ].join(' · ');
      return Semantics(
        button: true,
        expanded: false,
        label: l.metricsShowAll,
        child: InkWell(
          key: const Key('metrics-compact'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _open = true),
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar,
                const SizedBox(height: 3),
                Text(short, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );
    }

    final costUsd = widget.costUsd;
    final parts = <Widget>[
      Text.rich(
        TextSpan(
          text: '${l.metricsInput} ${kTokens(m.inputTokens)}',
          children: [
            if (m.cachedReadTokens > 0)
              TextSpan(
                text: ' (${l.metricsCache} ${kTokens(m.cachedReadTokens)})',
                style: const TextStyle(color: metricsCacheText),
              ),
          ],
        ),
        style: style,
      ),
      Text('${l.metricsOutput} ${kTokens(m.outputTokens)}', style: style),
      Text('${l.metricsContext} ${m.usedPercent}% / ${kTokens(m.contextWindow)}', style: style),
      Text('${l.metricsPrefill} ${duration(m.prefillMs)}', style: style),
      Text(
        '${l.metricsGeneration} ${duration(m.decodeMs)}'
        '${m.tokPerSecText == null ? '' : ' · ${m.tokPerSecText}'}',
        style: style,
      ),
      if (m.kvRestoredTokens != null)
        Tooltip(
          message: l.metricsRestoredFromDisk,
          child: Text(
            '${sysName(context, RgSystem.persistar)} ${kTokens(m.kvRestoredTokens!)} (${duration(m.kvRestoreMs)})',
            style: style,
          ),
        ),
      if (widget.costUnknown)
        Tooltip(
          message: l.metricsCostUnknownHint,
          child: Text(l.metricsCostUnknown, style: style),
        )
      else if (costUsd != null && costUsd > 0)
        Text(usd(costUsd), style: style),
      Text(time, style: style),
    ];
    final title = [
      if (widget.model != null) localModelName(widget.model!),
      '${l.metricsStart} ${clock(m.startedAt, l.localeName)}',
      if (m.firstTokenAt != null) '${l.metricsFirstToken} ${clock(m.firstTokenAt, l.localeName)}',
      if (m.endedAt != null) '${l.metricsEnd} ${clock(m.endedAt, l.localeName)}',
      m.source == 'client' ? l.metricsTimedByClient : l.metricsServerTimings,
    ].join('\n');
    final whole = Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar,
          const SizedBox(height: 3),
          Wrap(spacing: 12, runSpacing: 4, children: parts),
        ],
      ),
    );
    if (compact) {
      // Open on a phone: a touch folds it again; the details of the title come along.
      return Semantics(
        button: true,
        expanded: true,
        child: InkWell(
          key: const Key('metrics-open'),
          borderRadius: BorderRadius.circular(6),
          onTap: () => setState(() => _open = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              whole,
              Text(title.replaceAll('\n', ' · '), style: style.copyWith(fontSize: 10.5)),
            ],
          ),
        ),
      );
    }
    return Tooltip(
      key: const Key('metrics'),
      message: title,
      waitDuration: const Duration(milliseconds: 500),
      child: whole,
    );
  }
}

/// The context window as a 4px bar: cached, fresh and generated pieces, the summary's mark.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.m,
    required this.compactAt,
    required this.mark,
    required this.fresh,
    required this.out,
  });

  final MessageMetrics m;
  final double? compactAt;
  final Color mark;
  final Color fresh;
  final Color out;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 920),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth.isFinite ? box.maxWidth : 300.0;
          // The page's `min-width: 1px` on each piece.
          double width(int n) => (m.share(n) * w).clamp(1.0, w);
          final at = compactAt;
          return SizedBox(
            key: const Key('metrics-bar'),
            width: w,
            height: 4,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ColoredBox(
                      color: metricsTrack,
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        maxWidth: double.infinity,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              key: const Key('seg-cached'),
                              width: width(m.cachedReadTokens),
                              height: 4,
                              child: const ColoredBox(color: metricsCached),
                            ),
                            SizedBox(
                              key: const Key('seg-fresh'),
                              width: width(m.fresh),
                              height: 4,
                              child: ColoredBox(color: fresh),
                            ),
                            SizedBox(
                              key: const Key('seg-out'),
                              width: width(m.outputTokens),
                              height: 4,
                              child: ColoredBox(color: out),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (at != null)
                  Positioned(
                    key: const Key('compact-mark'),
                    left: (at * w).clamp(0.0, w - 2),
                    top: -2,
                    bottom: -2,
                    width: 2,
                    child: ColoredBox(color: mark),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
