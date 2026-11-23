// 3.12.3: the weekly margin of a flat subscription in the header's bars, as the page's `PlanBars`
// (`packages/web/src/components/PlanBars.tsx`): the same vectors as `packages/protocol/test/
// plan-margin.test.ts`, the 5-hour window always there, the 7-day colour from the margin, the
// tooltip's reset and reading times, and the bar drawn in the app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/budgets.dart';
import 'package:rgcompanion/api/plan_margin.dart';
import 'package:rgcompanion/theme/colors.dart';
import 'package:rgcompanion/ui/limits_bar.dart';

const _words = LimitWords(total: 'Totale', spent: 'Speso', context: 'Contesto', weekShort: '7g');
final _now = DateTime.utc(2026, 11, 23, 12);
String _in(double days) =>
    _now.add(Duration(milliseconds: (days * 86400000).round())).toIso8601String();

PlanLimits _plan(double used, double daysLeft, {String? readAt = '2026-11-23T11:58:00Z'}) =>
    PlanLimits.fromJson({
      'provider': 'claude-sub',
      'readAt': ?readAt,
      'windows': [
        {'id': '7d', 'label': '7g', 'usedPct': used, 'resetsAt': _in(daysLeft)},
        {'id': 'model:Fable', 'label': 'Fable', 'usedPct': 0},
      ],
    })!;

List<LimitBar> _bars(PlanLimits p) =>
    headerBars(provider: 'claude-sub', plans: [p], budgets: const [], words: _words, now: _now);

void main() {
  group('weeklyMargin, the protocol\'s vectors', () {
    int? m(double used, double left) => weeklyMargin(usedPct: used, resetsAt: _in(left), now: _now);
    test('the table', () {
      expect(m(70, 0.91), 17);
      expect(m(54, 3.5), -4);
      expect(m(50, 3.5), 0);
      expect(m(0, 7), 0);
      expect(m(50, 0.07), 49);
      expect(m(5, 9), -5);
    });
    test('null without a usable reset time, a figure, or past', () {
      expect(weeklyMargin(usedPct: 10, resetsAt: null, now: _now), isNull);
      expect(weeklyMargin(usedPct: 10, resetsAt: 'nonsense', now: _now), isNull);
      expect(weeklyMargin(usedPct: null, resetsAt: _in(2), now: _now), isNull);
      expect(weeklyMargin(usedPct: 10, resetsAt: _in(-1), now: _now), isNull);
    });
    test('levels and text', () {
      expect(marginLevel(40), MarginLevel.ok);
      expect(marginLevel(10), MarginLevel.ok);
      expect(marginLevel(9), MarginLevel.warn);
      expect(marginLevel(0), MarginLevel.warn);
      expect(marginLevel(-1), MarginLevel.err);
      expect([17, -4, 0].map(marginText).toList(), ['+17', '−4', '0']);
    });
  });

  group('headerBars for a plan', () {
    test('5h always first (a dash), the week with its margin, then the model window', () {
      final bars = _bars(_plan(70, 0.91));
      expect([for (final b in bars) b.name], ['5h', '7g', 'Fable']);
      expect([for (final b in bars) b.text], ['–', '70%', '0%']);
      expect(bars[1].margin, 17);
      expect(bars[0].margin, isNull);
      expect(bars[2].margin, isNull);
    });

    test('the week\'s colour follows the margin, not the percentage', () {
      expect(_bars(_plan(70, 0.91))[1].level, BarLevel.normal);
      expect(_bars(_plan(85, 0.91))[1].level, BarLevel.medium);
      expect(_bars(_plan(60, 3.5))[1].level, BarLevel.high);
      // No reset time: the percentage's colour, no margin.
      final p = PlanLimits.fromJson({
        'provider': 'claude-sub',
        'windows': [
          {'id': '7d', 'label': '7d', 'usedPct': 75},
        ],
      })!;
      final week = _bars(p)[1];
      expect(week.margin, isNull);
      expect(week.level, BarLevel.medium);
    });

    test('the tooltip: the margin, the reset time, the reading time; or that none was read', () {
      final title = _bars(_plan(70, 0.91))[1].title.split('\n');
      expect(title[0], '7g: 70% · +17');
      expect(title[1], 'Margin +17 points against an even pace over the week');
      expect(title[2], startsWith('Resets 2026-11-'));
      expect(title[3], startsWith('Plan read 2026-11-23 '));
      final none = _bars(_plan(70, 0.91, readAt: null))[1].title;
      expect(none, endsWith('Plan not read yet'));
    });
  });

  testWidgets('the bar is drawn with its margin next to the 7-day value', (tester) async {
    final bars = _bars(_plan(40, 3.5));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(children: [for (final b in bars) LimitBarView(bar: b)]),
        ),
      ),
    );
    expect(find.text('–'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    final margin = tester.widget<Text>(find.byKey(const Key('limit-margin-plan:7d')));
    expect(margin.data, '+10');
    final c = RgColors.of(tester.element(find.byKey(const Key('limit-margin-plan:7d'))));
    // 50% of the week gone, 40% used: +10, comfortable, green.
    expect(margin.style?.color, c.ok);
    expect(find.byKey(const Key('limit-margin-plan:5h')), findsNothing);
  });
}
