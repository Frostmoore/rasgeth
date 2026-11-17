// G42.4: Settings › Budgets, native, as the page's `Budgets.tsx`: this month's total big with its
// days drawn as bars, then everything, each project and each agent (those that spent something or
// have a limit) as boxes, lit when they have a limit; a box opens a window (a sheet from below on a
// phone) with the wizard's amounts or another one, or no limit. Limits count everything spent
// since they were set (`PUT /api/budgets`), the days come from `GET /api/budgets/daily`.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../api/budgets.dart';
import '../api/client.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import 'rules_kit.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openBudgetsSettings(BuildContext context) =>
    openRulesPage(context, (panel) => BudgetsScreen(panel: panel));

/// One day's spending of one row (`GET /api/budgets/daily`).
class DailySpend {
  const DailySpend({required this.day, required this.scope, required this.id, required this.usd});

  final String day;
  final String scope;
  final String id;
  final double usd;

  static DailySpend? fromJson(Map<String, dynamic> j) {
    final day = j['day'];
    final scope = j['scope'];
    final id = j['id'];
    final usd = j['usd'];
    if (day is! String || scope is! String || id is! String || usd is! num) return null;
    return DailySpend(day: day, scope: scope, id: id, usd: usd.toDouble());
  }
}

extension BudgetsApi on RedGiantClient {
  /// `GET /api/budgets/daily?from=YYYY-MM-DD`.
  Future<List<DailySpend>> spendDaily(String from) async => [
    for (final o in arrayOf(await getJson('/api/budgets/daily', {'from': from})))
      ?DailySpend.fromJson(o),
  ];
}

/// The days of this month up to today, as the page's `monthDays`.
List<String> monthDays([DateTime? now]) {
  final n = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return [for (var d = 1; d <= n.day; d++) '${n.year}-${two(n.month)}-${two(d)}'];
}

/// Dollars as the page writes them (`format.ts` `usd`).
String usdWords(double v) =>
    v == 0 ? r'$0' : (v < 0.01 ? '\$${v.toStringAsFixed(4)}' : '\$${v.toStringAsFixed(2)}');

/// Tokens as the page's `kTokens`: «12k», «1.2M».
String kTokenWords(double n) {
  if (n >= 1e6) return '${(n / 1e6).toStringAsFixed(1)}M';
  if (n >= 1e3) return '${(n / 1e3).round()}k';
  return '${n.round()}';
}

String limitWords(AppLocalizations l, Budget b) => b.limitUsd != null
    ? usdWords(b.limitUsd!)
    : b.limitTokens != null
    ? l.g4BuTokens(kTokenWords(b.limitTokens!))
    : l.g4BuNoLimit;

typedef _Who = ({String scope, String id, String name});

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key, this.panel = false, this.now});

  final bool panel;

  /// For tests: the day the month is drawn up to.
  final DateTime? now;

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  List<Budget>? _rows;
  List<DailySpend> _daily = const [];
  String? _error;

  late final List<String> _days = monthDays(widget.now);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final rows = await c.budgets();
      List<DailySpend> daily;
      try {
        daily = await c.spendDaily(_days.first);
      } on ApiException {
        daily = const [];
      }
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _daily = daily;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).errGeneric(e.message));
    }
  }

  Budget _rowFor(String scope, String id) =>
      _rows?.where((b) => b.scope == scope && b.id == id).firstOrNull ??
      Budget(scope: scope, id: id, usedUsd: 0, usedTokens: 0);

  double _monthOf(String scope, String id) =>
      _daily.where((d) => d.scope == scope && d.id == id).fold(0.0, (s, d) => s + d.usd);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final monthName = DateFormat.MMMM(l.localeName).format(widget.now ?? DateTime.now());
    final perDay = [
      for (final day in _days)
        _daily.where((d) => d.day == day && d.scope == 'global').fold(0.0, (s, d) => s + d.usd),
    ];
    final month = perDay.fold(0.0, (s, v) => s + v);
    final rows = _rows;
    final global = rows?.where((b) => b.scope == 'global').firstOrNull;
    final projects = <_Who>[
      for (final p in app.projects) (scope: 'project', id: p.id, name: p.name),
    ];
    final agents = <_Who>[
      for (final a in app.agents)
        if (_spentOrLimited(_rowFor('agent', a.id))) (scope: 'agent', id: a.id, name: a.name),
    ];
    int byMonth(_Who a, _Who b) => _monthOf(b.scope, b.id).compareTo(_monthOf(a.scope, a.id));

    Widget group(String title, List<_Who> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(title: title),
        _Boxes(
          children: [
            for (final x in list..sort(byMonth))
              _Box(
                key: Key('bu-row-${x.scope}-${x.id}'),
                row: _rowFor(x.scope, x.id),
                name: x.name,
                month: x.scope == 'global' ? month : _monthOf(x.scope, x.id),
                onOpen: () => _open(x),
              ),
          ],
        ),
      ],
    );

    return RulesPage(
      pageKey: const Key('budgets-settings'),
      title: l.g4BuTitle,
      panel: widget.panel,
      question: usdWords(month),
      lead: '${l.g4BuThisMonth(monthName)} · ${l.g4BuLead}',
      children: [
        if (_error != null) RulesLoading(error: _error),
        if (rows == null && _error == null) const RulesLoading(),
        if (rows != null) ...[
          _Chart(days: _days, perDay: perDay),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('bu-how'),
              onPressed: _how,
              icon: RgIcon(RgIcons.info, size: 16, color: c.accent),
              label: Text(l.g4BuHowLink),
            ),
          ),
          if (global != null)
            group(l.g4BuTotal, [(scope: 'global', id: global.id, name: l.g4BuEverything)])
          else
            RulesSub(title: l.g4BuTotal, lead: l.g4BuNothingYet),
          if (projects.isNotEmpty) group(l.g4BuProjects, projects),
          if (agents.isNotEmpty) group(l.g4BuAgents, agents),
        ],
      ],
    );
  }

  static bool _spentOrLimited(Budget b) =>
      b.usedUsd > 0 || b.limitUsd != null || b.limitTokens != null;

  Future<void> _how() async {
    final l = AppLocalizations.of(context);
    await _sheet<void>(
      context,
      title: l.g4BuHowLink,
      child: (close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.g4BuHow, style: TextStyle(color: RgColors.of(context).text, height: 1.45)),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('bu-how-ok'),
              onPressed: () => close(null),
              child: Text(l.g4BuUnderstood),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(_Who x) async {
    final saved = await _sheet<bool>(
      context,
      title: AppLocalizations.of(context).g4BuLimitFor(x.name),
      child: (close) => _LimitWindow(row: _rowFor(x.scope, x.id), onClose: close),
    );
    if (saved == true && mounted) await _load();
  }
}

/// A window over the page on a computer, a sheet from below on a phone (the page's Modal).
Future<T?> _sheet<T>(
  BuildContext context, {
  required String title,
  required Widget Function(void Function(T?) close) child,
}) {
  final c = RgColors.of(context);
  Widget body(BuildContext ctx) => Padding(
    padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.viewInsetsOf(ctx).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
        ),
        const SizedBox(height: 12),
        child((v) => Navigator.of(ctx).pop(v)),
      ],
    ),
  );
  if (MediaQuery.sizeOf(context).width >= 760) {
    return showRgWindow<T>(
      context: context,
      builder: (ctx) => Dialog(
        key: const Key('bu-window'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: body(ctx)),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: KeyedSubtree(key: const Key('bu-window'), child: body(ctx)),
    ),
  );
}

/// The month's days as bars (the page's `sb-chart`), with the first and the last day under.
class _Chart extends StatelessWidget {
  const _Chart({required this.days, required this.perDay});

  final List<String> days;
  final List<double> perDay;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final top = math.max(perDay.fold(0.0, math.max), 0.000001);
    return Container(
      key: const Key('bu-chart'),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Semantics(
        label: l.g4BuChart,
        child: Column(
          children: [
            SizedBox(
              height: 96,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final (i, v) in perDay.indexed)
                    Expanded(
                      child: Tooltip(
                        message: '${days[i].substring(8)}: ${usdWords(v)}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: FractionallySizedBox(
                            heightFactor: math.max(.02, v / top),
                            alignment: Alignment.bottomCenter,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: v > 0 ? c.accent : c.line,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: TextStyle(color: c.dim, fontSize: 11.5)),
                Text('${days.length}', style: TextStyle(color: c.dim, fontSize: 11.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The boxes, two in a row when there is room (the page's `sb-boxes`).
class _Boxes extends StatelessWidget {
  const _Boxes({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final two = box.maxWidth >= 520;
      final w = two ? (box.maxWidth - 10) / 2 : box.maxWidth;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

/// One box: what it spent this month and since the start, its limit and how far it got.
class _Box extends StatelessWidget {
  const _Box({
    super.key,
    required this.row,
    required this.name,
    required this.month,
    required this.onOpen,
  });

  final Budget row;
  final String name;
  final double month;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final limit = row.limitUsd;
    final has = limit != null || row.limitTokens != null;
    final pct = limit != null && limit > 0 ? math.min(1.0, row.usedUsd / limit) : 0.0;
    final over = limit != null && row.usedUsd >= limit;
    final tone = over ? c.err : (has ? c.accent : c.line);
    return Material(
      color: has ? c.accentSoft.withValues(alpha: over ? 0 : .55) : c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tone, width: has ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.text),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: has ? c.accent.withValues(alpha: .14) : c.panel2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      has ? l.g4BuLimitIs(limitWords(l, row)) : l.g4BuNoLimit,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: has ? c.accent : c.dim,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${l.g4BuMonth(usdWords(month))} · ${l.g4BuEver(usdWords(row.usedUsd))}',
                style: TextStyle(color: c.dim, fontSize: 13),
              ),
              if (limit != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: c.line)),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: ColoredBox(color: over ? c.err : c.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                over ? l.g4BuStopped : l.g4BuChange,
                style: TextStyle(
                  color: over ? c.err : c.accent,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _amounts = ['5', '20', '50', '100'];

/// The window of one box: the wizard's amounts or another one, or no limit.
class _LimitWindow extends StatefulWidget {
  const _LimitWindow({required this.row, required this.onClose});

  final Budget row;
  final void Function(bool?) onClose;

  @override
  State<_LimitWindow> createState() => _LimitWindowState();
}

class _LimitWindowState extends State<_LimitWindow> {
  late String _value = widget.row.limitUsd == null ? '' : _plain(widget.row.limitUsd!);
  late final _field = TextEditingController(text: _amounts.contains(_value) ? '' : _value);
  bool _busy = false;
  String? _error;

  static String _plain(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  double? get _n {
    final n = double.tryParse(_value.trim().replaceAll(',', '.'));
    return n != null && n.isFinite && n > 0 ? n : null;
  }

  Future<void> _save(double? usd) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.setBudget(widget.row.scope, widget.row.id, usd: usd);
      widget.onClose(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).errGeneric(e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.row;
    final n = _n;
    final has = r.limitUsd != null || r.limitTokens != null;
    return Column(
      key: const Key('bu-limit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l.g4BuLimitNow(limitWords(l, r))} · ${l.g4BuEver(usdWords(r.usedUsd))}',
          style: TextStyle(color: c.dim, fontSize: 13.5),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RgChoice<String>(
              options: [for (final v in _amounts) (v, '\$$v')],
              value: n != null && _amounts.any((a) => double.parse(a) == n)
                  ? _amounts.firstWhere((a) => double.parse(a) == n)
                  : null,
              keyOf: (v) => 'bu-amount-$v',
              onChanged: (v) => setState(() {
                _value = v;
                _field.clear();
              }),
            ),
            SizedBox(
              width: 120,
              child: TextField(
                key: const Key('bu-other'),
                controller: _field,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                decoration: InputDecoration(
                  isDense: true,
                  prefixText: r'$ ',
                  hintText: l.g4BuOther,
                  labelText: l.g4BuLimitLabel,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onChanged: (v) => setState(() => _value = v),
                onSubmitted: (_) {
                  if (n != null) unawaited(_save(n));
                },
              ),
            ),
          ],
        ),
        RuleSay(n != null ? l.g4BuLimitSay(_plain(n)) : l.g4BuLimitPick),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            key: const Key('bu-error'),
            style: TextStyle(color: c.err),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            if (has)
              TextButton(
                key: const Key('bu-remove'),
                onPressed: _busy ? null : () => _save(null),
                child: Text(l.g4BuRemoveLimit),
              ),
            OutlinedButton(
              key: const Key('bu-cancel'),
              onPressed: () => widget.onClose(false),
              child: Text(l.cancel),
            ),
            FilledButton(
              key: const Key('bu-save'),
              onPressed: _busy || n == null ? null : () => _save(n),
              child: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}
