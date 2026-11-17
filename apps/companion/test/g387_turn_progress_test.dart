// 3.8.7: from the moment a message is sent to the full answer, the app shows what the page shows
// (packages/web/src/components/TurnProgress.tsx, state.ts): the card of the model call under way
// (reading the context with its bar, tokens, speed and cache; then reasoning or writing with the
// tokens written and their speed), the reasoning as it comes, the answer with its cursor, then the
// message's figures. The fake server sends the turn's messages in the real server's order.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/turn_progress.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('the live model follows the call as state.ts', () {
    var now = DateTime(2026, 11, 17, 10);
    late LiveModel live;
    setUp(() {
      now = DateTime(2026, 11, 17, 10);
      live = LiveModel(now: () => now);
    });
    Map<String, dynamic> ev(int seq, String type) => {
      'type': 'event',
      'sessionId': 's1',
      'event': {
        'id': 'e$seq',
        'seq': seq,
        'ts': '',
        'sessionId': 's1',
        'type': type,
        'payload': {},
      },
    };

    test('running, prefill, deltas, a tool, the end', () {
      live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
      final v = live.view('s1');
      expect(v.call!.since, now);
      expect(v.call!.firstToken, isNull);
      live.apply({
        'type': 'prefill',
        'sessionId': 's1',
        'total': 18400,
        'cached': 14200,
        'processed': 16300,
        'ms': 1500,
      });
      expect(v.call!.prefill!.processed, 16300);
      // The same turn said running again (a follow): the call stays.
      final first = v.call;
      live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
      expect(v.call, same(first));
      now = now.add(const Duration(seconds: 3));
      live.apply({'type': 'delta', 'sessionId': 's1', 'kind': 'thinking', 'text': 'Vediamo'});
      expect(v.call!.firstToken, now);
      expect(v.call!.writing, 'thinking');
      expect(v.thinking, isTrue);
      live.apply({'type': 'delta', 'sessionId': 's1', 'kind': 'text', 'text': 'Ecco'});
      expect(v.call!.chars, 11);
      expect(v.call!.writing, 'text');
      live.apply(ev(2, 'message.assistant'));
      expect(v.call, isNull);
      live.apply(ev(3, 'tool.result'));
      expect(v.call, isNotNull);
      expect(v.call!.prefill, isNull);
      live.apply({'type': 'session.compacting', 'sessionId': 's1', 'busy': true});
      expect(v.compacting, isTrue);
      live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'idle'});
      expect(v.call, isNull);
      expect(v.compacting, isFalse);
    });
  });

  group('the card, as TurnProgress.tsx', () {
    final t0 = DateTime(2026, 11, 17, 10);
    Future<void> card(WidgetTester tester, ModelCall call, DateTime now, String lang) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.light),
          locale: Locale(lang),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TurnProgress(call: call, now: () => now, still: true),
          ),
        ),
      );
    }

    testWidgets('waiting, with no word from the provider', (tester) async {
      await card(tester, ModelCall(t0), t0.add(const Duration(milliseconds: 2500)), 'it');
      expect(find.text('Legge il contesto'), findsOneWidget);
      expect(find.text('2.5 s'), findsOneWidget);
      expect(
        find.text('Il fornitore non dice a che punto è: aspetto il primo token'),
        findsOneWidget,
      );
    });

    testWidgets('reading, as the engine reports it', (tester) async {
      final c = ModelCall(t0)
        ..prefill = const PrefillProgress(total: 18400, cached: 14200, processed: 16300, ms: 1500);
      await card(tester, c, t0.add(const Duration(milliseconds: 12400)), 'it');
      expect(find.text('12 s'), findsOneWidget);
      expect(find.text('16k di 18k token'), findsOneWidget);
      expect(find.text('1400 token/s'), findsOneWidget);
      expect(find.text('77% dalla cache'), findsOneWidget);
      final bar = tester.getSize(find.byKey(const Key('turn-progress-bar')));
      final fill = tester.getSize(
        find.descendant(
          of: find.byKey(const Key('turn-progress-bar')),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(fill.width / bar.width, closeTo(16300 / 18400, 0.01));
    });

    testWidgets('writing, in English', (tester) async {
      final c = ModelCall(t0)
        ..prefill = const PrefillProgress(total: 18400, cached: 14200, processed: 18400, ms: 3000)
        ..firstToken = t0.add(const Duration(seconds: 3))
        ..chars = 400
        ..writing = 'text';
      await card(tester, c, t0.add(const Duration(seconds: 5)), 'en');
      expect(find.text('Writing'), findsOneWidget);
      expect(find.text('2.0 s'), findsOneWidget);
      expect(find.text('about 100 tokens'), findsOneWidget);
      expect(find.text('about 50 tokens/s'), findsOneWidget);
      expect(find.text('context of 18k read in 3.0 s, 77% from the cache'), findsOneWidget);
    });

    testWidgets('reasoning, without a prefill', (tester) async {
      final c = ModelCall(t0)
        ..firstToken = t0.add(const Duration(milliseconds: 1200))
        ..chars = 40
        ..writing = 'thinking';
      await card(tester, c, t0.add(const Duration(milliseconds: 1700)), 'it');
      expect(find.text('Ragiona'), findsOneWidget);
      expect(find.text('circa 10 token'), findsOneWidget);
      // Under 0.8 s of writing the speed is not said yet.
      expect(find.textContaining('token/s'), findsNothing);
      expect(find.text('primo token dopo 1.2 s'), findsOneWidget);
    });
  });

  group('in a conversation, from the send to the answer', () {
    late FakeRedGiant server;
    late AppController app;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    testWidgets('card, reasoning, answer, figures', (tester) async {
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await _settle(tester);
      final card = find.byKey(const Key('turn-progress'));
      expect(card, findsNothing);

      server.turnStart('s1');
      await _settle(tester);
      expect(card, findsOneWidget);
      expect(find.text('Legge il contesto'), findsOneWidget);
      expect(find.textContaining('aspetto il primo token'), findsOneWidget);

      server.turnPrefill('s1', total: 18400, cached: 14200, processed: 16300, ms: 1500);
      await _settle(tester);
      expect(find.text('16k di 18k token'), findsOneWidget);
      expect(find.text('1400 token/s'), findsOneWidget);
      expect(find.text('77% dalla cache'), findsOneWidget);

      server.turnDelta('s1', 'thinking', 'Prima guardo il calendario. ');
      await _settle(tester);
      expect(find.text('Ragiona'), findsOneWidget);
      expect(find.byKey(const Key('thinking-live')), findsOneWidget);
      expect(find.text('Prima guardo il calendario. '), findsOneWidget);
      expect(find.textContaining('contesto di 18k letto in'), findsOneWidget);

      server.turnDelta('s1', 'text', 'Ecco il punto');
      await _settle(tester);
      expect(find.text('Scrive'), findsOneWidget);
      expect(find.byKey(const Key('thinking-live')), findsNothing);
      expect(find.byKey(const Key('stream-cursor')), findsOneWidget);
      expect(find.textContaining('contesto di 18k letto in'), findsOneWidget);

      // A summary in the middle: it takes the card's place, as the page.
      server.turnCompacting('s1', true);
      await _settle(tester);
      expect(find.text('Sto riassumendo la conversazione…'), findsOneWidget);
      expect(card, findsNothing);
      server.turnCompacting('s1', false);
      await _settle(tester);
      expect(card, findsOneWidget);

      server.turnEnd(
        's1',
        thinking: 'Prima guardo il calendario.',
        text: 'Ecco il punto della settimana.',
        metrics: {
          'startedAt': '2026-11-17T10:00:00.000Z',
          'firstTokenAt': '2026-11-17T10:00:03.000Z',
          'endedAt': '2026-11-17T10:00:05.000Z',
          'inputTokens': 18400,
          'cachedReadTokens': 14200,
          'outputTokens': 120,
          'contextUsed': 18520,
          'contextWindow': 32768,
          'prefillMs': 3000,
          'decodeMs': 2000,
          'tokPerSec': 60,
        },
      );
      await _settle(tester);
      expect(card, findsNothing);
      expect(find.byKey(const Key('stream-cursor')), findsNothing);
      expect(find.textContaining('60 tok/s', findRichText: true), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    });
  });
}
