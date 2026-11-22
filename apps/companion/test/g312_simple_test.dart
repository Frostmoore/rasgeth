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
import 'package:rgcompanion/api/topics.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/simple/simple_giant.dart';
import 'package:rgcompanion/simple/simple_model.dart';
import 'package:rgcompanion/simple/simple_shell.dart';
import 'package:rgcompanion/simple/simple_strip.dart';

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
    expect(effectiveUi(null, null), 'simple');
    expect(effectiveUi(null, 'full'), 'full');
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
      // Nothing technical in sight: no tools or figures (the strip at the bottom shows «I tuoi
      // agenti» by their faces, the person's choice of 3.12.1).
      expect(find.textContaining(RegExp('strument|token', caseSensitive: false)), findsNothing);
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

    testWidgets('3.12.1: God giant above the greeting; it listens while the person types', (
      tester,
    ) async {
      await open(tester);
      expect(find.byKey(const Key('simple-stage')), findsOneWidget);
      final giantY = tester.getTopLeft(find.byKey(const Key('simple-stage'))).dy;
      expect(giantY, lessThan(tester.getTopLeft(find.byKey(const Key('simple-greeting'))).dy));
      // A topic waits for the person: so does the giant.
      expect(find.byKey(const Key('simple-giant-wait')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('simple-ask')), 'Ciao');
      await tester.pump();
      expect(find.byKey(const Key('simple-giant-listen')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 2600));
      expect(find.byKey(const Key('simple-giant-listen')), findsNothing);
      await done(tester);
    });

    testWidgets('3.12.1: Satellite behind God; its name brings it in front, the Chat\'s screen', (
      tester,
    ) async {
      server.sessionMadeElsewhere('chat', title: 'Ricetta della carbonara');
      await open(tester);
      expect(app.simple.front, StageFront.god);
      expect(find.bySemanticsLabel(RegExp('^Satellite: ')), findsOneWidget);
      expect(find.textContaining('Luna'), findsNothing);
      await tap(tester, find.byKey(const Key('simple-front-chat')));
      await tester.pump(const Duration(seconds: 1));
      expect(app.simple.front, StageFront.chat);
      expect(find.text('Due chiacchiere? Sono qui.'), findsOneWidget);
      expect(find.text('Scrivi a Satellite...'), findsOneWidget);
      expect(find.text('LE ULTIME CHIACCHIERE'), findsOneWidget);
      expect(find.text('Ricetta della carbonara'), findsOneWidget);
      expect(find.text('IN CORSO'), findsNothing);
      // Writing there talks to the Chat agent: a new conversation of its own, then it opens.
      final before = server.sessions.length;
      await tester.enterText(find.byKey(const Key('simple-ask')), 'Che film vedo stasera?');
      await tap(tester, find.byKey(const Key('simple-ask-send')));
      expect(server.sessions.length, before + 1);
      expect(server.sessions.last['agentId'], 'chat');
      expect(find.byType(TopicScreen), findsOneWidget);
      expect(topics.calls.where((c) => c.startsWith('POST /api/god/messages')), isEmpty);
      await done(tester);
    });

    testWidgets('3.12.1: the agents\' strip: a tap enlarges one, its balloon opens its chat', (
      tester,
    ) async {
      await open(tester, size: const Size(390, 2200));
      expect(find.text('I TUOI AGENTI'), findsOneWidget);
      // God and sub-agents are not in it.
      expect(find.byKey(const Key('strip-a0')), findsNothing);
      expect(find.byKey(const Key('strip-a1')), findsOneWidget);
      expect(find.byKey(const Key('strip-a8')), findsNothing);
      expect(find.byKey(const Key('strip-balloon')), findsNothing);
      await tap(tester, find.byKey(const Key('strip-a2')));
      expect(find.byKey(const Key('strip-balloon')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('strip-balloon')),
          matching: find.text('Apri la chat'),
        ),
        findsOneWidget,
      );
      final before = server.sessions.length;
      await tap(tester, find.byKey(const Key('strip-balloon')));
      expect(find.byType(TopicScreen), findsOneWidget);
      expect(server.sessions.length, before + 1);
      expect(server.sessions.last['agentId'], 'a2');
      await done(tester);
    });

    testWidgets('3.12.1: a card shows the agents of its topic; a card with nobody, none', (
      tester,
    ) async {
      topics.active.first['agents'] = [
        {'id': 'a5', 'role': 'from'},
        {'id': 'a2', 'role': 'task'},
      ];
      await open(tester, size: const Size(390, 2200));
      expect(find.byKey(const Key('card-agent-a5')), findsOneWidget);
      expect(find.byKey(const Key('card-agent-a2')), findsOneWidget);
      // The other cards have nobody.
      expect(find.byWidgetPredicate((w) => '${w.key}'.contains('card-agent-')), findsNWidgets(2));
      await done(tester);
    });

    testWidgets('3.12.1: a swipe turns the orbit either way', (tester) async {
      await open(tester);
      await tester.fling(find.byKey(const Key('simple-stage')), const Offset(-300, 0), 1200);
      await tester.pump(const Duration(seconds: 1));
      expect(app.simple.front, StageFront.chat);
      await tester.fling(find.byKey(const Key('simple-stage')), const Offset(300, 0), 1200);
      await tester.pump(const Duration(seconds: 1));
      expect(app.simple.front, StageFront.god);
      await done(tester);
    });

    testWidgets('3.12.1: a server before 3.12 (no topics routes) is said, the full view offered', (
      tester,
    ) async {
      server.topics = null;
      await open(tester);
      expect(find.byKey(const Key('simple-trouble-old')), findsOneWidget);
      expect(find.textContaining('aggiornare il server alla 3.12'), findsOneWidget);
      expect(find.text('Un momento…'), findsNothing);
      await tap(tester, find.byKey(const Key('simple-trouble-full')));
      expect(app.simpleUi, isFalse);
      expect(find.byType(SimpleShell), findsNothing);
      await done(tester);
    });

    testWidgets('3.12.1: any other error offers to try again, then the topics come', (
      tester,
    ) async {
      final kept = server.topics;
      server.topics = null;
      server.routes['GET /api/god/topics'] = (q) => server.answer(q, 502, {'error': 'Bad gateway'});
      await open(tester);
      expect(find.byKey(const Key('simple-trouble-failed')), findsOneWidget);
      server.routes.remove('GET /api/god/topics');
      server.topics = kept;
      await tap(tester, find.byKey(const Key('simple-trouble-retry')));
      expect(find.byKey(const Key('simple-trouble-failed')), findsNothing);
      expect(find.text('Vacanza in Sardegna'), findsOneWidget);
      await done(tester);
    });
  });

  test('3.12.1: the giant\'s mood follows the facts, the most urgent first', () {
    expect(giantMood(), GiantMood.rest);
    expect(giantMood(typing: true), GiantMood.listen);
    expect(giantMood(routing: true, typing: true), GiantMood.think);
    expect(giantMood(working: true), GiantMood.work);
    expect(giantMood(waiting: true, working: true), GiantMood.wait);
    expect(giantMood(happy: true, waiting: true), GiantMood.happy);
    expect(giantMood(error: true, routing: true, happy: true), GiantMood.worried);
    expect(giantState(GiantMood.worried), MascotState.error);
    expect(giantState(GiantMood.rest), MascotState.active);
    IdleGesture? last;
    var x = 0.13;
    double rand() => x = (x * 9301 + 0.49297) % 1;
    final seen = <IdleGesture>{};
    for (var i = 0; i < 200; i++) {
      final g = nextGesture(last, IdleGesture.values, rand);
      expect(g, isNot(last));
      seen.add(g);
      last = g;
    }
    expect(seen.length, IdleGesture.values.length);
    expect(gestureDelay(() => 0), const Duration(milliseconds: 3500));
    expect(gestureDelay(() => 1), const Duration(milliseconds: 8000));
    final working = TopicView.fromJson(topicJson('a', 'A', state: 'working'));
    final ready = TopicView.fromJson(topicJson('a', 'A'));
    expect(finishedWork([working], [ready]), isTrue);
    final withAgents = TopicView.fromJson({
      ...topicJson('b', 'B'),
      'agents': [
        {'id': 'ada', 'role': 'from'},
        {'id': 'pixel', 'role': 'task'},
      ],
    });
    expect(withAgents.agents, ['ada', 'pixel']);
    expect(withAgents.read().agents, ['ada', 'pixel']);
    expect(ready.agents, isEmpty);
    expect(finishedWork([ready], [ready]), isFalse);
  });

  Widget giantApp(Widget child, {bool reduce = false}) => MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduce),
      child: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('3.12.1: still, the giant makes a gesture now and then, never the same twice', (
    tester,
  ) async {
    await tester.pumpWidget(
      giantApp(const GiantMascot(agent: null, mood: GiantMood.rest, rand: _fixed)),
    );
    final st = tester.state<GiantMascotState>(find.byType(GiantMascot));
    final seen = <IdleGesture>[];
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 7996));
      expect(st.gesture, isNotNull);
      seen.add(st.gesture!);
      await tester.pump(gestureLength(st.gesture!));
      expect(st.gesture, isNull);
    }
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i], isNot(seen[i - 1]));
    }
    expect(seen, isNot(contains(IdleGesture.wink)));
    // At work: no gestures.
    await tester.pumpWidget(
      giantApp(const GiantMascot(agent: null, mood: GiantMood.work, rand: _fixed)),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(tester.state<GiantMascotState>(find.byType(GiantMascot)).gesture, isNull);
    expect(find.byKey(const Key('simple-giant-work')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('3.12.1: with reduced motion the giant stays still', (tester) async {
    await tester.pumpWidget(
      giantApp(const GiantMascot(agent: null, mood: GiantMood.rest, rand: _fixed), reduce: true),
    );
    await tester.pump(const Duration(seconds: 60));
    expect(tester.state<GiantMascotState>(find.byType(GiantMascot)).gesture, isNull);
    expect(tester.state<GiantMascotState>(find.byType(GiantMascot)).moving, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test('3.12.1: the orbit\'s places and the Chat\'s latest conversations', () {
    final front = orbitPlace(0, 200);
    expect([front.x, front.y, front.scale, front.z, front.light], [0, 0, 1, 200, 1]);
    final back = orbitPlace(orbitBack, 200);
    expect(back.scale, lessThan(0.5));
    expect(back.z, lessThan(front.z));
    expect(orbitPlace(-orbitBack, 200).x, -back.x);
    SessionRow row(String id, {String agent = 'chat', String? at, bool archived = false}) =>
        SessionRow.fromJson({
          'id': id,
          'agentId': agent,
          'createdAt': '2026-11-20T10:00:00.000Z',
          'lastAt': at,
          'title': null,
          'archived': archived,
          'running': false,
        });
    final rows = [
      row('a', at: '2026-11-21T10:00:00.000Z'),
      row('b', at: '2026-11-22T10:00:00.000Z'),
      row('c', archived: true),
      row('d', agent: 'god'),
    ];
    expect(recentChats(rows, 'chat').map((r) => r.id), ['b', 'a']);
    expect(recentChats(rows, null), isEmpty);
  });

  test('3.12.1: the strip keeps every agent with a face but God and the Chat', () {
    Agent a(String id, String kind, {String status = 'active'}) =>
        Agent.fromJson({'id': id, 'name': id, 'kind': kind, 'status': status, 'parentId': null});
    final list = [
      a('god', 'god'),
      a('chat', 'assistant'),
      a('demi', 'demigod'),
      a('ada', 'orchestrator'),
      a('tester', 'subagent'),
      a('old', 'agent', status: 'stopped'),
    ];
    expect(stripAgents(list, 'chat').map((x) => x.id), ['demi', 'ada']);
    expect(nearestIndex([10, 50, 90], 62), 1);
    expect(nearestIndex([], 5), -1);
  });

  test('3.12.1: a 404 is an old server, the rest is not', () {
    expect(topicsMissing(404), isTrue);
    expect(topicsMissing(502), isFalse);
    expect(topicsMissing(0), isFalse);
  });
}

double _fixed() => 0.999;
