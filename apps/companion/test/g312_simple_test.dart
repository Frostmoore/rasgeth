// 3.12: the simple interface in the app, as the page's (components/Simple.tsx), against the fake
// server that answers as the topics' contract says (test/fake_topics.dart): «Oggi» with the
// greeting, the big box and the topics' cards with their state in words; a topic read as a
// document with «in: Titolo · Sposta» and its decisions in a box; «Sposta» to another topic; the
// archive with its search; a few settings and the switch to the full view, kept on this device.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/simple/simple_model.dart';
import 'package:rgcompanion/simple/simple_shell.dart';

import 'fake_server.dart';
import 'fake_topics.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 8]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Map<String, dynamic> _words(String what) => {
  'it': {'what': what, 'reasons': <String>[], 'critical': <String>[], 'dangers': <Object>[]},
  'en': {'what': what, 'reasons': <String>[], 'critical': <String>[], 'dangers': <Object>[]},
};

void main() {
  test('the rules, as the page\'s', () {
    expect(effectiveUi(null, null), 'full');
    expect(effectiveUi(null, 'simple'), 'simple');
    expect(effectiveUi('full', 'simple'), 'full');
    expect([4, 5, 12, 13, 17, 18, 23].map(greetingKey).toList(), [
      'smpEvening',
      'smpMorning',
      'smpMorning',
      'smpAfternoon',
      'smpAfternoon',
      'smpEvening',
      'smpEvening',
    ]);
  });

  test('a topic as a document, from the page\'s vectors', () {
    final v = jsonDecode(File('test/fixtures/items_vectors.json').readAsStringSync()) as Map;
    final c = (v['cases'] as List).cast<Map<String, dynamic>>().firstWhere(
      (c) => c['name'] == 'topics',
    );
    final items = buildItems([
      for (final e in (c['events'] as List).cast<Map<String, dynamic>>()) RgEvent.fromJson(e),
    ]);
    final routed = items.whereType<RoutedItem>().first;
    expect(routed.uncertain, isTrue);
    expect(routed.userSeq, 3);
    expect(items.whereType<UserItem>().last.movedFrom?.sessionId, 'sess_other');
    // The moved exchange leaves the document; «written here» and tools are never in it.
    expect(documentItems(items).map((i) => i.kind).toList(), [
      'routed',
      'user',
      'assistant',
      'moved',
    ]);
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeTopics topics;
    late AppController app;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      server.permissions.clear();
      topics = FakeTopics();
      server.topics = topics;
      topics.active.addAll([
        topicJson(
          't_trip',
          'Vacanza in Sardegna',
          summary: 'Ho trovato 3 voli per il 14 luglio',
          state: 'waiting',
          unread: 1,
          requests: 1,
        ),
        topicJson('t_gift', 'Regalo per la mamma', summary: 'Idee sotto i 50 €'),
        topicJson('t_site', 'Sito per lo zio', state: 'working'),
      ]);
      topics.archived.add(
        topicJson('t_bills', 'Bollette', summary: 'La luce di novembre', archived: true),
      );
    });
    tearDown(() => server.close());

    Future<void> open(WidgetTester tester, {Size size = const Size(390, 844)}) async {
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
      )..locale = const Locale('it');
      (server.setup['config'] as Map<String, dynamic>)['personName'] = 'Riccardo';
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      app.setUi('simple');
      await _settle(tester, 3);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    Future<void> tap(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester);
    }

    testWidgets('«Oggi»: the greeting, the big box, the topics with their state in words', (
      tester,
    ) async {
      await open(tester);
      expect(find.byType(SimpleShell), findsOneWidget);
      final hello = tester.widget<Text>(find.byKey(const Key('simple-greeting'))).data!;
      expect(hello, endsWith(', Riccardo'));
      expect(find.text('Chiedimi qualcosa…'), findsOneWidget);
      expect(find.text('IN CORSO'), findsOneWidget);
      expect(find.text('ti aspetto'), findsOneWidget);
      expect(find.text('al lavoro'), findsOneWidget);
      expect(find.text('pronto'), findsOneWidget);
      expect(find.text('Appena iniziato'), findsOneWidget);
      expect(find.text('Archivio (1)'), findsOneWidget);
      // Nothing technical in sight: no team, agents, tools.
      expect(
        find.textContaining(RegExp('agent|strument|token', caseSensitive: false)),
        findsNothing,
      );
      await done(tester);
    });

    testWidgets('asks God from «Oggi» and opens the topic it went to', (tester) async {
      await open(tester);
      await tester.enterText(find.byKey(const Key('simple-ask')), 'Mi serve un idraulico');
      await tap(tester, find.byKey(const Key('simple-ask-send')));
      expect(topics.bodies['POST /api/god/messages'], {'text': 'Mi serve un idraulico'});
      expect(find.byType(TopicScreen), findsOneWidget);
      expect(find.text('Vacanza in Sardegna'), findsWidgets);
      await done(tester);
    });

    testWidgets('a topic as a document: «in: Titolo · Sposta», the decision box, the move', (
      tester,
    ) async {
      server.store('t_trip', 'topic.routed', {
        'via': 'router',
        'reason': 'router',
        'uncertain': true,
      });
      server.store('t_trip', 'message.user', {'text': 'Mi trovi un volo per Cagliari?'});
      final userSeq = (server.logs['t_trip']!.last['seq'] as num).toInt();
      server.store('t_trip', 'tool.call', {'callId': 'c1', 'tool': 'web_search', 'input': {}});
      server.store('t_trip', 'message.assistant', {
        'parts': [
          {'type': 'text', 'text': 'Ne ho trovati tre. Il più comodo costa **89 €**.'},
        ],
        'stopReason': 'end_turn',
        'model': 'm',
        'costUsd': 0,
      });
      await open(tester);
      await tap(tester, find.byKey(const Key('topic-t_trip')));
      expect(find.byType(TopicScreen), findsOneWidget);
      expect(topics.calls, contains('POST /api/god/topics/t_trip/read'));
      expect(find.byKey(const Key('routed-unsure')), findsOneWidget);
      expect(find.textContaining('web_search'), findsNothing);
      expect(find.text('Rispondi…'), findsOneWidget);

      // A request in plain words, in the box, answered with one button.
      server.request({
        'requestId': 'rq1',
        'agentId': 'a0',
        'agentName': 'God',
        'sessionId': 't_trip',
        'tool': 'browser_click',
        'input': {},
        'reasons': <String>[],
        'danger': <String>[],
        'askedTo': 'human',
        'createdAt': '2026-11-22T09:00:00.000Z',
        'words': _words('Preme «Prenota» sul sito della compagnia'),
        'topic': {'id': 't_trip', 'title': 'Vacanza in Sardegna'},
      });
      await _settle(tester);
      expect(find.text('Posso procedere?'), findsOneWidget);
      expect(find.text('Preme «Prenota» sul sito della compagnia'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      await tap(tester, find.byKey(const Key('decide-yes-rq1')));
      expect(
        server.received.where((m) => m['type'] == 'permission.resolve').single,
        containsPair('decision', 'allow'),
      );

      // «Sposta» to another topic: the move is asked, then that topic opens.
      await tap(tester, find.byKey(Key('routed-move-$userSeq')));
      expect(find.byKey(const Key('move-sheet')), findsOneWidget);
      await tap(tester, find.byKey(const Key('move-to-t_gift')));
      expect(topics.bodies['POST /api/sessions/t_trip/messages/$userSeq/move'], {'to': 't_gift'});
      expect(find.text('Regalo per la mamma'), findsWidgets);
      await done(tester);
    });

    testWidgets('a plain question is its buttons, as the board («Vuoi che lo prenoti?»)', (
      tester,
    ) async {
      server.ask({
        'requestId': 'q1',
        'sessionId': 't_trip',
        'agentId': 'a0',
        'agentName': 'God',
        'projectId': null,
        'createdAt': '2026-11-22T09:00:00.000Z',
        'questions': [
          {
            'question': 'Vuoi che lo prenoti?',
            'options': [
              {'label': 'Sì, prenota'},
              {'label': 'Mostrami gli altri'},
            ],
            'multiSelect': false,
          },
        ],
        'topic': {'id': 't_trip', 'title': 'Vacanza in Sardegna'},
      });
      await open(tester);
      await tap(tester, find.byKey(const Key('topic-t_trip')));
      expect(find.text('Vuoi che lo prenoti?'), findsOneWidget);
      expect(find.byKey(const Key('ask-q1-other')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 900));
      await tap(tester, find.byKey(const Key('ask-q1-0')));
      final answer = server.received.where((m) => m['type'] == 'question.answer').single;
      expect(answer['answers'], [
        ['Sì, prenota'],
      ]);
      await done(tester);
    });

    testWidgets('the archive: found with words, taken back with a tap', (tester) async {
      await open(tester);
      await tap(tester, find.byKey(const Key('simple-archive')));
      expect(find.text('Bollette'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('archive-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await _settle(tester);
      expect(topics.calls, contains('GET /api/god/topics?archived=true&q=zzz'));
      expect(find.text('Niente con queste parole.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('archive-search')), 'luce');
      await tester.pump(const Duration(milliseconds: 300));
      await _settle(tester);
      await tap(tester, find.byKey(const Key('archived-t_bills')));
      expect(topics.calls, contains('POST /api/god/topics/t_bills/restore'));
      expect(find.byType(TopicScreen), findsOneWidget);
      await done(tester);
    });

    testWidgets('a few settings; «Vista completa» switches this device to the full view', (
      tester,
    ) async {
      await open(tester, size: const Size(1280, 860));
      expect(find.byType(SimpleShell), findsOneWidget);
      await tap(tester, find.byKey(const Key('simple-settings')));
      expect(find.text('Chiedimi prima di spendere'), findsOneWidget);
      expect(find.text('Riccardo'), findsOneWidget);
      await tap(tester, find.byKey(const Key('simple-full-view')));
      expect(app.simpleUi, isFalse);
      expect(await app.prefs.get('ui'), 'full');
      expect(find.byType(SimpleShell), findsNothing);
      await done(tester);
    });
  });
}
