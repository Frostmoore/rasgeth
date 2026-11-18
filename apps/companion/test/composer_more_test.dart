// The composer's «…» in the app (3.8.1): the page's panel as a sheet, with the same items,
// effects and states, against the fake Rasgeth: the mode (the agent's), the model of this
// conversation with the way and the effort, «Meanwhile» with «Bring into the chat»,
// «Summarise» (`/compact` over the same send), «Add an agent» (a group chat from this
// conversation), what hides them and what waits while the agent works, in both languages.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'fake_server.dart';

AppController _app({Locale locale = const Locale('it')}) =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )
      ..locale = locale
      ..reduceMotion = true;

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 3));
}

Map<String, dynamic> _ev(int seq, String type, Map<String, dynamic> payload) => {
  'seq': seq,
  'ts': '2026-11-15T10:0$seq:00.000Z',
  'type': type,
  'payload': payload,
};

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
  });
  tearDown(() => server.close());

  /// The app on Coder Web's conversation `s1`, with [events] in it.
  Future<AppController> onConversation(
    WidgetTester tester, {
    List<Map<String, dynamic>> events = const [],
    Locale locale = const Locale('it'),
    String agentId = 'a3',
  }) async {
    server.sessions.first['agentId'] = agentId;
    final app = _app(locale: locale);
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    final agent = app.agents.firstWhere((a) => a.id == agentId);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: 's1', agent: agent),
      ),
    );
    await tester.pumpAndSettle();
    app.live.apply({'type': 'session.history', 'sessionId': 's1', 'events': events});
    await tester.pumpAndSettle();
    return app;
  }

  final talked = [
    _ev(1, 'session.started', {}),
    _ev(2, 'message.user', {'text': 'Make the CSV export'}),
    _ev(3, 'message.assistant', {
      'parts': [
        {'type': 'text', 'text': 'Done: export.csv'},
      ],
      'stopReason': 'end_turn',
    }),
    _ev(4, 'message.user', {'text': 'And the JSON one?'}),
    _ev(5, 'message.assistant', {
      'parts': [
        {'type': 'text', 'text': 'Also done.'},
      ],
      'stopReason': 'end_turn',
    }),
  ];

  Future<void> openMore(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('composer-more')));
    await _settle(tester);
    expect(find.byKey(const Key('more-sheet')), findsOneWidget);
  }

  testWidgets('mode: the agent\'s, for all its conversations; the «…» says it changed', (
    tester,
  ) async {
    final app = await onConversation(tester, events: talked);
    expect(find.byKey(const Key('composer-more-mark')), findsNothing);
    await openMore(tester);
    expect(find.text('Modalità: Automatico'), findsOneWidget);
    for (final m in ['Chiedi', 'Automatico', 'Piano', 'Sola lettura']) {
      expect(find.text(m), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('mode-plan')));
    await _settle(tester);
    expect(server.patches.last, {'agent': 'a3', 'mode': 'plan'});
    expect(find.text('Modalità: Piano'), findsOneWidget);
    expect(app.agents.firstWhere((a) => a.id == 'a3').mode, 'plan');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('composer-more-mark')), findsOneWidget);
    await _done(tester);
  });

  testWidgets('model of this conversation: the way and the effort, or the agent\'s', (
    tester,
  ) async {
    await onConversation(tester, events: talked);
    await openMore(tester);
    expect(find.text('Modello: Il modello predefinito'), findsOneWidget);
    await tester.tap(find.byKey(const Key('more-model')));
    await _settle(tester);
    expect(find.text('Modello di questa conversazione'), findsOneWidget);
    expect(find.text('Modello dell\'agente'), findsOneWidget);
    await tester.tap(find.byKey(const Key('model-anthropic/claude-sonnet-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('way-claude-subscription/claude-sonnet-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('effort-low')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('model-use')));
    await _settle(tester);
    expect(server.sessions.first['model'], {
      'provider': 'claude-subscription',
      'model': 'claude-sonnet-5',
      'effort': 'low',
    });
    expect(find.text('Modello: Claude Sonnet 5 · Abbonamento · Basso'), findsOneWidget);
    // Back to the agent's.
    await tester.tap(find.byKey(const Key('more-model')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('model-inherit')));
    await _settle(tester);
    expect(server.sessions.first['model'], isNull);
    await _done(tester);
  });

  testWidgets('meanwhile: a question on the side, then into the chat', (tester) async {
    await onConversation(tester, events: talked);
    await openMore(tester);
    await tester.tap(find.byKey(const Key('more-aside')));
    await _settle(tester);
    expect(find.text('Fuori dalla conversazione'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('aside-field')), 'How many rows?');
    await tester.tap(find.byKey(const Key('aside-ask')));
    await _settle(tester);
    expect(server.asides, ['s1: How many rows?']);
    expect(find.text('Meanwhile: 42'), findsOneWidget);
    await tester.tap(find.byKey(const Key('aside-to-chat-as1')));
    await _settle(tester);
    expect(server.asides.last, 'chat as1');
    expect(find.text('Portato nella chat.'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('summarise: /compact with what to keep, over the same send', (tester) async {
    await onConversation(tester, events: talked);
    await openMore(tester);
    await tester.tap(find.byKey(const Key('more-compact')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Riassumo la conversazione adesso. Qualcosa da tenere in particolare? (facoltativo)',
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('dialog-text')), 'the CSV columns');
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.sent.last['text'], '/compact the CSV columns');
    expect(find.text('Sto riassumendo la conversazione.'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('add an agent: a group chat from this conversation', (tester) async {
    await onConversation(tester, events: talked);
    await openMore(tester);
    await tester.ensureVisible(find.byKey(const Key('more-room')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('more-room')));
    await _settle(tester);
    expect(find.text('Chi aggiungi alla chat di gruppo?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('room-pick-a4')));
    await _settle(tester);
    expect(server.rooms.first, {
      'members': <dynamic>[],
      'from': {'agentId': 'a3', 'sessionId': 's1'},
    });
    expect(server.rooms.last, {'room': 'room_1', 'agentId': 'a4'});
    await _done(tester);
  });

  testWidgets('a new conversation: no «Meanwhile» nor «Summarise»; Demi-God: no group', (
    tester,
  ) async {
    await onConversation(tester, agentId: 'a1');
    await openMore(tester);
    expect(find.byKey(const Key('more-aside')), findsNothing);
    expect(find.byKey(const Key('more-compact')), findsNothing);
    expect(find.byKey(const Key('more-room')), findsNothing);
    expect(find.byKey(const Key('more-model')), findsOneWidget);
    await _done(tester);
  });

  testWidgets('while it works: the model, summarise and the group wait; meanwhile does not', (
    tester,
  ) async {
    final app = await onConversation(tester, events: talked);
    app.live.apply({'type': 'session.state', 'sessionId': 's1', 'state': 'running'});
    await tester.pumpAndSettle();
    await openMore(tester);
    expect(find.text('Sta lavorando: il modello si cambia quando ha finito.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('more-model')));
    await tester.pumpAndSettle();
    expect(find.text('Modello di questa conversazione'), findsNothing);
    await tester.tap(find.byKey(const Key('more-compact')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dialog-text')), findsNothing);
    expect(find.text('Mentre lavora non si può.'), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('more-aside')));
    await _settle(tester);
    expect(find.text('Una domanda al volo, mentre l\'agente lavora…'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('in English', (tester) async {
    await onConversation(tester, events: talked, locale: const Locale('en'));
    await openMore(tester);
    expect(find.text('Mode: Automatic'), findsOneWidget);
    expect(find.text('Model: The default model'), findsOneWidget);
    for (final t in ['Meanwhile', 'Summarise', 'Add an agent', 'Read only']) {
      expect(find.text(t), findsOneWidget);
    }
    await _done(tester);
  });

  test(
    'the modes in the page\'s order',
    () => expect(agentModes, ['manual', 'auto', 'plan', 'readonly']),
  );
}
