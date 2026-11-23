// Spending and limits for the conversations' header (3.9.0), as the page's `Limits` in
// `packages/web/src/components/App.tsx`: a flat subscription shows its plan's windows (5h, 7d…), a
// local model how full the context is before the automatic summary, anything paid per token the
// budgets (`GET /api/budgets`; the plans from `GET /api/limits`). [headerBars] is pure and tested;
// [SpendModel] keeps both lists and reads them again when a turn ends, as the page does.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'client.dart';
import 'metrics.dart';
import 'plan_margin.dart';

/// One row of `GET /api/budgets`.
class Budget {
  const Budget({
    required this.scope,
    required this.id,
    this.limitUsd,
    this.limitTokens,
    this.usedUsd = 0,
    this.usedTokens = 0,
  });

  static Budget? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    final scope = o['scope'];
    final id = o['id'];
    if (scope is! String || id is! String) return null;
    final limit = o['limit'] is Map<String, dynamic>
        ? o['limit'] as Map<String, dynamic>
        : const {};
    final used = o['used'] is Map<String, dynamic> ? o['used'] as Map<String, dynamic> : const {};
    return Budget(
      scope: scope,
      id: id,
      limitUsd: (limit['usd'] as num?)?.toDouble(),
      limitTokens: (limit['tokens'] as num?)?.toDouble(),
      usedUsd: (used['usd'] as num?)?.toDouble() ?? 0,
      usedTokens: (used['tokens'] as num?)?.toDouble() ?? 0,
    );
  }

  /// agent, project or global.
  final String scope;
  final String id;
  final double? limitUsd;
  final double? limitTokens;
  final double usedUsd;
  final double usedTokens;

  bool get limited => limitUsd != null || limitTokens != null;
}

/// One window of a flat subscription (`GET /api/limits`).
class PlanWindow {
  const PlanWindow({required this.id, required this.label, this.usedPct, this.resetsAt});

  final String id;
  final String label;

  /// null: not known yet (the page's «–»).
  final double? usedPct;
  final String? resetsAt;
}

class PlanLimits {
  const PlanLimits({required this.provider, required this.windows, this.readAt});

  static PlanLimits? fromJson(Object? o) {
    if (o is! Map<String, dynamic> || o['provider'] is! String) return null;
    return PlanLimits(
      provider: o['provider'] as String,
      readAt: o['readAt'] as String?,
      windows: [
        for (final w in (o['windows'] as List? ?? const []).whereType<Map<String, dynamic>>())
          if (w['id'] is String)
            PlanWindow(
              id: w['id'] as String,
              label: w['label'] is String ? w['label'] as String : w['id'] as String,
              usedPct: (w['usedPct'] as num?)?.toDouble(),
              resetsAt: w['resetsAt'] as String?,
            ),
      ],
    );
  }

  final String provider;
  final List<PlanWindow> windows;

  /// When the plan was last read (ISO), for the tooltip; null: unknown.
  final String? readAt;
}

/// How full a bar is: the page's `level` (red from 90%, yellow from 70%).
enum BarLevel { normal, medium, high }

BarLevel barLevel(double? pct) => pct == null
    ? BarLevel.normal
    : pct >= 90
    ? BarLevel.high
    : pct >= 70
    ? BarLevel.medium
    : BarLevel.normal;

/// One bar of the header: a name, how full (null: no bar, only [text]), the figure, the hint.
class LimitBar {
  const LimitBar({
    required this.key,
    required this.name,
    required this.pct,
    required this.text,
    required this.title,
    this.bar = true,
    this.margin,
    this.marginTone,
  });

  final String key;
  final String name;
  final double? pct;
  final String text;
  final String title;

  /// false: only the name and the figure (the spending without limits).
  final bool bar;

  /// The 7-day window's margin against an even pace (3.12.3); null: none.
  final int? margin;

  /// The colour the margin gives the bar, in place of the percentage's.
  final BarLevel? marginTone;

  BarLevel get level => marginTone ?? barLevel(pct);
}

/// The words of the bars, in the person's language.
class LimitWords {
  const LimitWords({
    required this.total,
    required this.spent,
    required this.context,
    required this.weekShort,
    this.resets = 'Resets {when}',
    this.readAt = 'Plan read {when}',
    this.notRead = 'Plan not read yet',
    this.marginTip = 'Margin {margin} points against an even pace over the week',
  });

  final String total;
  final String spent;
  final String context;
  final String weekShort;

  /// Tooltip lines (3.12.3): `{when}` and `{margin}` are filled in.
  final String resets;
  final String readAt;
  final String notRead;
  final String marginTip;
}

/// The page's own server id (`OWN_SERVER_ID` in `@redgiant/protocol`).
const ownServerId = 'server';

String _two(int n) => n.toString().padLeft(2, '0');

String _plainWhen(DateTime d) =>
    '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';

String _pctText(double? pct) => pct == null ? '–' : '${jsRound(pct)}%';

/// The page's `Limits`: what the header shows for a conversation using [provider].
/// [lastMetrics] is the conversation's last answer's figures (the local model's context bar);
/// [agentName] gives an agent budget its name.
List<LimitBar> headerBars({
  required String? provider,
  required List<PlanLimits> plans,
  required List<Budget> budgets,
  required LimitWords words,
  MessageMetrics? lastMetrics,
  String? Function(String agentId)? agentName,
  DateTime? now,
  String Function(DateTime)? whenText,
}) {
  final plan = plans.where((p) => p.provider == provider).firstOrNull;
  if (plan != null) {
    // The 5h window is always there (a dash while the plan gives no figure for it, 3.12.3), then
    // the 7-day one, then the rest as the provider sent them (a stable sort, as the page's).
    final windows = [
      if (!plan.windows.any((w) => w.id == '5h')) const PlanWindow(id: '5h', label: '5h'),
      ...plan.windows,
    ];
    int rank(String id) => id == '5h' ? 0 : (id == '7d' ? 1 : 2);
    final sorted = [
      for (final r in [0, 1, 2]) ...windows.where((w) => rank(w.id) == r),
    ];
    final fmt = whenText ?? _plainWhen;
    final clock = now ?? DateTime.now();
    final readAt = plan.readAt == null ? null : DateTime.tryParse(plan.readAt!);
    final read = readAt == null
        ? words.notRead
        : words.readAt.replaceAll('{when}', fmt(readAt.toLocal()));
    return [
      for (final w in sorted)
        () {
          final week = w.id == '7d';
          final name = week ? words.weekShort : w.label;
          final margin = week
              ? weeklyMargin(usedPct: w.usedPct, resetsAt: w.resetsAt, now: clock)
              : null;
          final resetsAt = w.resetsAt == null ? null : DateTime.tryParse(w.resetsAt!);
          final lines = [
            '$name: ${_pctText(w.usedPct)}${margin == null ? '' : ' · ${marginText(margin)}'}',
            if (margin != null) words.marginTip.replaceAll('{margin}', marginText(margin)),
            if (resetsAt != null) words.resets.replaceAll('{when}', fmt(resetsAt.toLocal())),
            read,
          ];
          return LimitBar(
            key: 'plan:${w.id}',
            name: name,
            pct: w.usedPct,
            text: _pctText(w.usedPct),
            title: lines.join('\n'),
            margin: margin,
            marginTone: margin == null
                ? null
                : switch (marginLevel(margin)) {
                    MarginLevel.ok => BarLevel.normal,
                    MarginLevel.warn => BarLevel.medium,
                    MarginLevel.err => BarLevel.high,
                  },
          );
        }(),
    ];
  }
  if (provider == 'local' || provider == ownServerId) {
    final m = lastMetrics;
    final threshold = m == null ? 0 : jsRound(m.contextWindow * 0.8);
    final pct = m == null || threshold == 0 ? 0.0 : m.contextUsed / threshold * 100;
    return [
      LimitBar(
        key: 'context',
        name: words.context,
        pct: pct,
        text: _pctText(pct),
        title: m == null
            ? words.context
            : '${words.context}: ${m.contextUsed} / $threshold (${m.contextWindow})',
      ),
    ];
  }
  final limited = budgets.where((b) => b.limited).toList();
  if (limited.isEmpty) {
    final global = budgets.where((b) => b.scope == 'global').firstOrNull;
    if (global == null) return const [];
    return [
      LimitBar(
        key: 'spent',
        name: words.spent,
        pct: null,
        text: usd(global.usedUsd),
        title: '${words.spent}: ${usd(global.usedUsd)}',
        bar: false,
      ),
    ];
  }
  return [
    for (final b in limited.take(3))
      () {
        final pct = b.limitUsd != null
            ? b.usedUsd / b.limitUsd! * 100
            : b.usedTokens / (b.limitTokens ?? 1) * 100;
        final name = b.scope == 'global'
            ? words.total
            : b.scope == 'project'
            ? b.id
            : (agentName?.call(b.id) ?? b.id);
        return LimitBar(
          key: '${b.scope}:${b.id}',
          name: name,
          pct: pct,
          text: _pctText(pct),
          title: '$name: ${usd(b.usedUsd)}${b.limitUsd != null ? ' / ${usd(b.limitUsd!)}' : ''}',
        );
      }(),
  ];
}

/// The budgets and the plans' windows of the RedGiant in use, read again when a turn ends.
class SpendModel extends ChangeNotifier {
  List<Budget> budgets = const [];
  List<PlanLimits> plans = const [];
  bool loaded = false;
  Timer? _soon;
  Timer? _poll;
  RedGiantClient? _client;
  bool _reading = false;

  /// How often the open app asks for the plan's windows again (3.12.3); the server shares one
  /// reading among all the pages and apps.
  static const pollEvery = Duration(minutes: 2);

  Future<void> refresh(RedGiantClient? c) async {
    if (c == null || _reading) return;
    _client = c;
    _poll ??= Timer.periodic(pollEvery, (_) {
      if (plans.isNotEmpty) unawaited(refresh(_client));
    });
    _reading = true;
    try {
      final b = await c.budgets().catchError((_) => budgets);
      final p = await c.planLimits().catchError((_) => plans);
      budgets = b;
      plans = p;
      loaded = true;
      notifyListeners();
    } finally {
      _reading = false;
    }
  }

  /// A turn just ended: what it spent shows in a moment (several endings, one read).
  void refreshSoon(RedGiantClient? c) {
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 250), () => unawaited(refresh(c)));
  }

  void clear() {
    _soon?.cancel();
    _poll?.cancel();
    _poll = null;
    _client = null;
    budgets = const [];
    plans = const [];
    loaded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _soon?.cancel();
    _poll?.cancel();
    super.dispose();
  }
}
