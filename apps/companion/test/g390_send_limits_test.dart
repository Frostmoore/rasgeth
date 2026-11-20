// 3.9.0: Ctrl+Enter (Cmd+Enter on macOS) sends from every conversation field while plain Enter keeps
// its meaning; the conversations' header shows the spending and the limits as the page's header
// (`GET /api/budgets`, `GET /api/limits`), read again when a turn ends.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/budgets.dart';
import 'package:rgcompanion/api/metrics.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/colors.dart';
import 'package:rgcompanion/ui/limits_bar.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

const _words = LimitWords(total: 'Totale', spent: 'Speso', context: 'Contesto', weekShort: '7g');

Map<String, dynamic> _budget(String scope, String id, double used, {double? limit}) => {
  'scope': scope,
  'id': id,
  'limit': {'usd': ?limit},
  'used': {'usd': used, 'tokens': 0},
};

void main() {
  group('headerBars, as the page\'s Limits', () {
    List<Budget> budgets(List<Map<String, dynamic>> l) => [for (final o in l) Budget.fromJson(o)!];

    test('budgets with limits: the total first, the percentages, the levels', () {
      final bars = headerBars(
        provider: 'anthropic',
        plans: const [],
        budgets: budgets([
          _budget('global', 'owner', 6.3, limit: 10),
          _budget('project', 'demo', 3.54, limit: 1),
          _budget('agent', 'a3', 0.75, limit: 1),
          _budget('agent', 'a2', 9),
        ]),
        words: _words,
        agentName: (id) => id == 'a3' ? 'Coder Web' : null,
      );
      expect([for (final b in bars) b.name], ['Totale', 'demo', 'Coder Web']);
      expect([for (final b in bars) b.text], ['63%', '354%', '75%']);
      expect([for (final b in bars) b.level], [BarLevel.normal, BarLevel.high, BarLevel.medium]);
      expect(bars[1].title, r'demo: $3.54 / $1.00');
    });

    test('the levels: yellow from 70%, red from 90%', () {
      expect(barLevel(69.9), BarLevel.normal);
      expect(barLevel(70), BarLevel.medium);
      expect(barLevel(89.9), BarLevel.medium);
      expect(barLevel(90), BarLevel.high);
      expect(barLevel(null), BarLevel.normal);
    });

    test('no limits: only what was spent; nothing at all: no bars', () {
      final bars = headerBars(
        provider: null,
        plans: const [],
        budgets: budgets([_budget('global', 'owner', 1.25)]),
        words: _words,
      );
      expect(bars.single.name, 'Speso');
      expect(bars.single.text, r'$1.25');
      expect(bars.single.bar, isFalse);
      expect(
        headerBars(provider: null, plans: const [], budgets: const [], words: _words),
        isEmpty,
      );
    });

    test('a flat subscription: its windows, 5h first (a dash when unknown), 7d in words', () {
      final bars = headerBars(
        provider: 'claude-sub',
        plans: [
          PlanLimits.fromJson({
            'provider': 'claude-sub',
            'windows': [
              {'id': '7d', 'label': '7d', 'usedPct': 41},
            ],
          })!,
        ],
        budgets: budgets([_budget('global', 'owner', 6.3, limit: 10)]),
        words: _words,
      );
      expect([for (final b in bars) b.name], ['5h', '7g']);
      expect([for (final b in bars) b.text], ['–', '41%']);
    });

    test('a local model: the context before the automatic summary', () {
      final bars = headerBars(
        provider: 'local',
        plans: const [],
        budgets: const [],
        words: _words,
        lastMetrics: MessageMetrics.fromJson({
          'startedAt': '2026-11-16T10:00:00Z',
          'inputTokens': 100,
          'outputTokens': 10,
          'contextUsed': 40000,
          'contextWindow': 100000,
        }),
      );
      expect(bars.single.name, 'Contesto');
      expect(bars.single.text, '50%');
    });

    test('limitsLayout: a row when it fits, else two stacked, else one, else none', () {
      expect(limitsLayout([100, 100, 100], 320), (count: 3, stacked: false));
      expect(limitsLayout([100, 100, 100], 250), (count: 2, stacked: true));
      expect(limitsLayout([100, 120], 110), (count: 1, stacked: false));
      expect(limitsLayout([100], 90), (count: 0, stacked: false));
      expect(limitsLayout([], 500), (count: 0, stacked: false));
    });
  });

  group('in the app', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      server.budgets = [
        _budget('global', 'owner', 6.3, limit: 10),
        _budget('project', 'demo', 3.54, limit: 1),
      ];
    });
    tearDown(() => server.close());

    Future<AppController> start(
      WidgetTester tester, {
      Size size = const Size(1440, 900),
      DevicePlatform platform = DevicePlatform.linux,
    }) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: platform,
              liveEnabled: false,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() async {
        await app.connect(server.base.toString(), 'secret');
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      return app;
    }

    Future<void> push(WidgetTester tester, Widget screen) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    Future<void> sendKeys(WidgetTester tester, {bool mac = false}) async {
      final mod = mac ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(mod);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(mod);
      await _settle(tester);
    }

    testWidgets('the composer: Enter does not send, Ctrl+Enter does', (tester) async {
      final app = await start(tester);
      await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
      await tester.enterText(find.byKey(const Key('composer-text')), 'Ciao');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      expect(server.sent, isEmpty);
      await sendKeys(tester);
      expect(server.sent.single['text'], startsWith('Ciao'));
      await done(tester);
    });

    testWidgets('on macOS it is Cmd+Enter (Ctrl+Enter does nothing there)', (tester) async {
      final app = await start(tester, platform: DevicePlatform.macos);
      await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
      await tester.enterText(find.byKey(const Key('composer-text')), 'Ciao');
      await sendKeys(tester);
      expect(server.sent, isEmpty);
      await sendKeys(tester, mac: true);
      expect(server.sent.single['text'], 'Ciao');
      await done(tester);
    });

    testWidgets('God\'s field on the wall: Ctrl+Enter sends, the conversation opens', (
      tester,
    ) async {
      await start(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('desk-god-field')),
          matching: find.byType(TextField),
        ),
        'Fai il punto',
      );
      await sendKeys(tester);
      expect(find.byKey(const Key('desk-panel')), findsOneWidget);
      expect(server.sent.any((m) => m['text'] == 'Fai il punto'), isTrue);
      // A new conversation each time (3.9.8), as Chat's field: never God's shared one.
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('desk-god-field')),
          matching: find.byType(TextField),
        ),
        'E adesso?',
      );
      await sendKeys(tester);
      final first = server.sent.firstWhere((m) => m['text'] == 'Fai il punto')['sessionId'];
      final second = server.sent.firstWhere((m) => m['text'] == 'E adesso?')['sessionId'];
      expect(first, isNot(second));
      expect(server.requests.where((q) => q.contains('/work-session')), isEmpty);
      // And the shortcut is listed.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester, 4);
      expect(find.byKey(const Key('shortcut-send')), findsOneWidget);
      expect(find.text('Ctrl+Invio'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the header: Total and the project\'s budget, red over 90%, live', (tester) async {
      final app = await start(tester);
      await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
      expect(find.byKey(const Key('header-limits')), findsOneWidget);
      expect(find.text('Totale'), findsOneWidget);
      expect(find.text('63%'), findsOneWidget);
      expect(find.text('354%'), findsOneWidget);
      final c = RgColors.of(tester.element(find.byKey(const Key('header-limits'))));
      Color fill(String key) => tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byKey(Key('limit-fill-$key')),
              matching: find.byType(ColoredBox),
            ),
          )
          .color;
      expect(fill('global:owner'), c.ok);
      expect(fill('project:demo'), c.err);
      // A turn ends: the spending is read again.
      server.budgets = [
        _budget('global', 'owner', 7.5, limit: 10),
        _budget('project', 'demo', 3.6, limit: 1),
      ];
      app.live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'idle'});
      await tester.pump(const Duration(milliseconds: 300));
      await _settle(tester);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('360%'), findsOneWidget);
      expect(fill('global:owner'), c.warn);
      await done(tester);
    });

    testWidgets('on a phone the two bars stand one over the other', (tester) async {
      final app = await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
      await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
      final limits = find.byKey(const Key('header-limits'));
      expect(limits, findsOneWidget);
      expect(tester.widget(limits), isA<Column>());
      expect(find.text('63%'), findsOneWidget);
      expect(find.text('354%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await done(tester);
    });
  });
}
