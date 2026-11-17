// 3.8.10: agents at work together. The app reads `turns.queue` (the line in the order it starts,
// «2° di 3»), saves the person's limit with the other command limits as they are, and shows a
// conversation waiting for a place with «Passa avanti» (POST /api/turns/:id/first) and the queue.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/turn_queue.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations_en.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/screens/at_work_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/turn_queue_view.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Map<String, dynamic> _q(String sid, String agent, {bool first = false}) => {
  'sessionId': sid,
  'agentId': agent,
  'since': '2026-11-17T10:00:00.000Z',
  if (first) 'first': true,
};

Map<String, dynamic> _view({int? limit = 2, int working = 2, List<Map<String, dynamic>>? queued}) =>
    {
      'limit': limit,
      'working': working,
      'running': [
        {'sessionId': 'w1', 'agentId': 'a1'},
        {'sessionId': 'w2', 'agentId': 'a2'},
      ],
      'queued': queued ?? [_q('s9', 'a3'), _q('s1', 'a0'), _q('s8', 'a4')],
    };

void main() {
  group('the line', () {
    test('turns.queue: places, «2° di 3», an agent\'s first place', () {
      final live = LiveModel();
      live.apply({'type': 'turns.queue', ..._view()});
      expect(live.turns.limit, 2);
      expect(live.turns.working, 2);
      expect(live.turns.running, hasLength(2));
      expect(live.turns.placeOf('s1'), (place: 2, of: 3));
      expect(live.turns.placeOf('w1'), isNull);
      expect(live.turns.placeOfAgent('a4'), (place: 3, of: 3));
      expect(live.turns.shown, isTrue);
      live.apply({'type': 'turns.queue', 'limit': null, 'working': 0, 'running': [], 'queued': []});
      expect(live.turns.shown, isFalse);
      expect(TurnQueue.fromJson({'queued': 'nonsense'}).queued, isEmpty);
    });

    test('moving one first, as the server will send it', () {
      final q = TurnQueue.fromJson(_view()).withFirst('s8');
      expect([for (final x in q.queued) x.sessionId], ['s8', 's9', 's1']);
      expect(q.queued.first.first, isTrue);
    });

    test('ordinals in both languages', () {
      final it = AppLocalizationsIt();
      final en = AppLocalizationsEn();
      expect(queuedWords(it, (place: 2, of: 3)), 'in coda (2° di 3)');
      expect(queuedWords(en, (place: 2, of: 3)), 'queued (2nd of 3)');
      expect(
        [
          for (final n in [1, 3, 4, 11, 12, 13, 21, 22]) nthWord(en, n),
        ],
        ['1st', '3rd', '4th', '11th', '12th', '13th', '21st', '22nd'],
      );
    });
  });

  group('in the app', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 900)}) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
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

    testWidgets('the setting saves maxAtWork and keeps the other limits', (tester) async {
      server.commandSettings = {...server.commandSettings, 'maxAtWork': 5};
      await start(tester);
      await push(tester, const AtWorkScreen());
      // The saved value that is not a ready choice is shown too.
      expect(find.byKey(const Key('at-work-5')), findsOneWidget);
      await tester.tap(find.byKey(const Key('at-work-2')));
      await _settle(tester);
      expect(server.commandPuts.single['maxAtWork'], 2);
      expect(server.commandPuts.single['maxPerSession'], 4);
      expect(find.text('Salvato: vale per i turni che partono da adesso.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('at-work-none')));
      await tester.tap(find.byKey(const Key('at-work-none')));
      await _settle(tester);
      expect(server.commandPuts.last['maxAtWork'], isNull);
      expect(server.commandPuts.last.containsKey('maxAtWork'), isTrue);
      await done(tester);
    });

    testWidgets('a conversation waiting: the banner, «Passa avanti», the queue', (tester) async {
      final app = await start(tester);
      server.turnQueue = _view();
      app.live.apply({'type': 'turns.queue', ..._view()});
      await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
      expect(find.byKey(const Key('queue-banner')), findsOneWidget);
      expect(find.text('In coda (2° di 3): aspetta che si liberi un posto'), findsOneWidget);
      await tester.tap(find.byKey(const Key('queue-banner-first')));
      await _settle(tester);
      expect(server.turnFirsts, ['s1']);
      expect(app.live.turns.placeOf('s1'), (place: 1, of: 3));
      // First now: no «Passa avanti» left, the queue still one tap away.
      expect(find.byKey(const Key('queue-banner-first')), findsNothing);
      await tester.tap(find.byKey(const Key('queue-banner-see')));
      await _settle(tester);
      expect(find.byKey(const Key('queue-window')), findsOneWidget);
      expect(find.text('2 posti occupati su 2'), findsOneWidget);
      expect(find.byKey(const Key('queue-row-s9')), findsOneWidget);
      expect(find.text('Prossimo'), findsOneWidget);
      // Started meanwhile: the banner goes.
      app.live.apply({'type': 'turns.queue', ..._view(queued: [])});
      await tester.tap(find.byKey(const Key('queue-close')));
      await _settle(tester);
      expect(find.byKey(const Key('queue-banner')), findsNothing);
      await done(tester);
    });
  });
}
