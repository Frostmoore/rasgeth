// The figures under an answer (G40.17): the app writes the very numbers the page's MetricsBar
// writes, from the same `message.assistant` events (test/fixtures/metrics_vectors.json, made by
// tool/metrics_fixtures.mjs with the page's own formatters), the same bar, whole on a computer and
// short on a phone until touched.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/metrics.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/metrics_line.dart';

final _fx = jsonDecode(
  File('test/fixtures/metrics_vectors.json').readAsStringSync(),
) as Map<String, dynamic>;
final _vectors = (_fx['vectors'] as List).cast<Map<String, dynamic>>();

List<ChatItem> _items(Map<String, dynamic> event, {int seq = 4}) => buildItems([
  RgEvent.fromJson({...event, 'seq': seq, 'ts': '2026-11-16T01:49:36.000Z'}),
]);

Widget _app(Widget child, {String locale = 'it', double width = 1000}) => MaterialApp(
  theme: buildTheme(Brightness.dark),
  locale: Locale(locale),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width - 40, child: child),
      ),
    ),
  ),
);

/// Every text the line shows, as one string.
String _shown(WidgetTester tester) => tester
    .widgetList<RichText>(
      find.descendant(of: find.byType(MetricsLine), matching: find.byType(RichText)),
    )
    .map((r) => r.text.toPlainText())
    .join(' | ');

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it');
    await initializeDateFormatting('en');
  });

  group('the page\'s formatters', () {
    test('kTokens, duration, usd: the same strings as format.ts', () {
      for (final [n, s] in (_fx['kTokens'] as List).cast<List<dynamic>>()) {
        expect(kTokens((n as num).toInt()), s, reason: 'kTokens($n)');
      }
      for (final [n, s] in (_fx['duration'] as List).cast<List<dynamic>>()) {
        expect(duration(n as num), s, reason: 'duration($n)');
      }
      for (final [n, s] in (_fx['usd'] as List).cast<List<dynamic>>()) {
        expect(usd((n as num).toDouble()), s, reason: 'usd($n)');
      }
      expect(duration(null), '–');
    });

    test('every event: the same figures, model name and clock as the page', () {
      for (final v in _vectors) {
        final event = v['event'] as Map<String, dynamic>;
        final page = v['page'] as Map<String, dynamic>;
        final a = _items(event).whereType<AssistantItem>().single;
        final m = a.metrics!;
        expect(kTokens(m.inputTokens), page['input']);
        expect(m.cachedReadTokens > 0 ? kTokens(m.cachedReadTokens) : null, page['cache']);
        expect(kTokens(m.outputTokens), page['output']);
        expect('${m.usedPercent}% / ${kTokens(m.contextWindow)}', page['context']);
        expect(duration(m.prefillMs), page['prefill']);
        expect(
          '${duration(m.decodeMs)}${m.tokPerSecText == null ? '' : ' · ${m.tokPerSecText}'}',
          page['generation'],
        );
        expect(
          m.kvRestoredTokens == null
              ? null
              // Persistar (3.10.3): the page's name for the context restored from the disk.
              : 'Persistar ${kTokens(m.kvRestoredTokens!)} (${duration(m.kvRestoreMs)})',
          page['ssd'],
        );
        expect(
          a.costUnknown ? 'unknown' : ((a.costUsd ?? 0) > 0 ? usd(a.costUsd!) : null),
          page['cost'],
        );
        expect(localModelName(a.model!), page['model']);
        final end = DateTime.parse(m.endedAt ?? m.startedAt);
        expect(clockOf(end, 'it'), page['clockIt']);
        expect(clockOf(end, 'en'), page['clockEn']);
        final bar = page['bar'] as Map<String, dynamic>;
        expect(m.share(m.cachedReadTokens) * 100, closeTo(bar['cached'] as num, 1e-9));
        expect(m.share(m.fresh) * 100, closeTo(bar['fresh'] as num, 1e-9));
        expect(m.share(m.outputTokens) * 100, closeTo(bar['out'] as num, 1e-9));
      }
    });

    test('no figures for imported or external agents\' messages, nor for broken ones', () {
      final e = _vectors.first['event'] as Map<String, dynamic>;
      final p = e['payload'] as Map<String, dynamic>;
      Map<String, dynamic> as(Map<String, dynamic> payload) => {...e, 'payload': payload};
      final withText = {
        ...p,
        'parts': [
          {'type': 'text', 'text': 'Fatto.'},
        ],
      };
      expect(
        _items(as({...withText, 'provider': 'import:claude-code'}))
            .whereType<AssistantItem>()
            .single
            .metrics,
        isNull,
      );
      expect(
        _items(as({...withText, 'provider': 'acp'})).whereType<AssistantItem>().single.metrics,
        isNull,
      );
      // A message that only asked for tools keeps its figures (as on the page)...
      final toolsOnly = _items(as({...p, 'stopReason': 'tool_use'}))
          .whereType<AssistantItem>()
          .single;
      expect(toolsOnly.text, isEmpty);
      expect(toolsOnly.metrics, isNotNull);
      // ...but without figures it shows nothing (the item is there, as on the page; the view
      // leaves it out).
      expect(
        _items(as({...p, 'metrics': null})).whereType<AssistantItem>().where(showsSomething),
        isEmpty,
      );
      expect(
        _items(
          as({
            ...p,
            'metrics': {...p['metrics'] as Map<String, dynamic>, 'contextWindow': 0},
          }),
        ).whereType<AssistantItem>().where(showsSomething),
        isEmpty,
      );
    });
  });

  group('the line under an answer', () {
    AssistantItem item(int i) =>
        _items(_vectors[i]['event'] as Map<String, dynamic>).whereType<AssistantItem>().single;

    testWidgets('on a computer: every figure, as on the page', (tester) async {
      final a = item(1);
      await tester.pumpWidget(_app(ChatItemView(item: a)));
      await tester.pumpAndSettle();
      final page = _vectors[1]['page'] as Map<String, dynamic>;
      final text = _shown(tester);
      expect(text, contains('letti ${page['input']} (cache ${page['cache']})'));
      expect(text, contains('generati ${page['output']}'));
      expect(text, contains('contesto ${page['context']}'));
      expect(text, contains('lettura ${page['prefill']}'));
      expect(text, contains('generazione ${page['generation']}'));
      expect(text, contains(page['ssd'] as String));
      expect(text, contains(clock(a.metrics!.endedAt, 'it')));
      expect(find.byKey(const Key('metrics-compact')), findsNothing);
      expect(find.byKey(const Key('metrics')), findsOneWidget);
      // The bar: the pieces in proportion to the window, the summary's mark at 80%.
      final w = tester.getSize(find.byKey(const Key('metrics-bar'))).width;
      final bar = page['bar'] as Map<String, dynamic>;
      expect(
        tester.getSize(find.byKey(const Key('seg-cached'))).width,
        closeTo((bar['cached'] as num) / 100 * w, .01),
      );
      expect(
        tester.getSize(find.byKey(const Key('seg-fresh'))).width,
        closeTo((bar['fresh'] as num) / 100 * w, .01),
      );
      // A piece too small to see keeps the page's 1px.
      expect(
        tester.getSize(find.byKey(const Key('seg-out'))).width,
        closeTo(((bar['out'] as num) / 100 * w).clamp(1, w), .01),
      );
      final mark =
          tester.getTopLeft(find.byKey(const Key('compact-mark'))).dx -
          tester.getTopLeft(find.byKey(const Key('metrics-bar'))).dx;
      expect(mark, closeTo(.8 * w, .01));
    });

    testWidgets('in English, the cost and the unknown cost', (tester) async {
      await tester.pumpWidget(_app(ChatItemView(item: item(0)), locale: 'en'));
      await tester.pumpAndSettle();
      var text = _shown(tester);
      expect(text, contains('in 30k (cache 30k)'));
      expect(text, contains('out 53'));
      expect(text, contains('context 6.4% / 475k'));
      expect(text, contains(r'$0.01'));
      await tester.pumpWidget(_app(ChatItemView(item: item(4)), locale: 'en'));
      await tester.pumpAndSettle();
      text = _shown(tester);
      expect(text, contains('cost not known'));
      expect(text, contains('generation 1000ms · 8 tok/s'));
    });

    testWidgets('a full window: the bar stops at its end', (tester) async {
      await tester.pumpWidget(_app(ChatItemView(item: item(3))));
      await tester.pumpAndSettle();
      final w = tester.getSize(find.byKey(const Key('metrics-bar'))).width;
      expect(tester.getSize(find.byKey(const Key('seg-cached'))).width, closeTo(w, .01));
      expect(_shown(tester), contains('contesto 124.5% / 1.0M'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a phone: short, whole at a touch, short again', (tester) async {
      final a = item(1);
      await tester.pumpWidget(_app(ChatItemView(item: a), width: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('metrics-compact')), findsOneWidget);
      expect(find.byKey(const Key('metrics-bar')), findsOneWidget);
      final short = _shown(tester);
      expect(
        short,
        'letti 19k · generati 1.3k · 15.3% · 41 tok/s · ${clock(a.metrics!.endedAt, 'it')}',
      );
      await tester.tap(find.byKey(const Key('metrics-compact')));
      await tester.pumpAndSettle();
      final whole = _shown(tester);
      expect(whole, contains('letti 19k (cache 17k)'));
      expect(whole, contains('generazione 31.3s · 41 tok/s'));
      // The page's title comes along: the model and where the timings come from.
      expect(whole, contains('GLM-4.5 Air Q4_K_S'));
      expect(whole, contains('tempi del server'));
      await tester.tap(find.byKey(const Key('metrics-open')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('metrics-compact')), findsOneWidget);
    });

    testWidgets('nothing while the answer streams', (tester) async {
      await tester.pumpWidget(
        _app(
          ChatItemView(
            item: AssistantItem(text: 'Sto', thinking: '', ts: '', live: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(MetricsLine), findsNothing);
    });
  });
}
