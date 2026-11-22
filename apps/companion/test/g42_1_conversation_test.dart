// G42.1: the conversation does what the page's does, against the fake server (which answers as
// ws.ts and app.ts do): requests answered in the chat with «per questa chat», «sempre», «nega e
// spiega» and an artifact's cap; a switched-off tool asked back; questions and plans answered in
// the chat and kept there; a message sent while the agent works waits in line and can be taken
// back; «Continua da qui» and «Modifica» make a copy; the last summary asked by hand is undone; the
// steps above the composer; the tool lines; a secret held back before it leaves.
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

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Past the cards' arming (800 ms, the page's `useArmed`).
Future<void> _armed(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 900));
  await _settle(tester, 2);
}

Map<String, dynamic> _words(String what) => {
  'it': {'what': what, 'reasons': <String>[], 'critical': <String>[], 'dangers': <Object>[]},
  'en': {'what': what, 'reasons': <String>[], 'critical': <String>[], 'dangers': <Object>[]},
};

void main() {
  late FakeRedGiant server;
  late AppController app;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    // Only this test's requests (the defaults belong to «Da te»'s tests).
    server.permissions.clear();
  });
  tearDown(() => server.close());

  Future<void> open(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
    )..locale = const Locale('it');
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = size;
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
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  Map<String, dynamic> perm(
    String id, {
    String tool = 'bash',
    Object? input,
    List<String>? danger,
  }) => {
    'requestId': id,
    'agentId': 'a0',
    'agentName': 'God',
    'projectId': null,
    'tool': tool,
    'input': input ?? {'command': 'npm test'},
    'reasons': ['Runs a command'],
    'danger': danger ?? <String>[],
    'createdAt': '2026-11-17T10:00:00.000Z',
    'sessionId': 's1',
    'words': _words('Esegue il comando: npm test'),
  };

  testWidgets('a permission in the chat: the words, armed, «per questa chat»', (tester) async {
    server.permissions.add(perm('p1'));
    await open(tester);
    expect(find.byKey(const Key('chat-request-p1')), findsOneWidget);
    expect(find.text('Esegue il comando: npm test'), findsOneWidget);
    // Not yet armed: a tap decides nothing.
    await tester.tap(find.byKey(const Key('chat-session-p1')), warnIfMissed: false);
    await _settle(tester, 2);
    expect(server.resolves, isEmpty);
    await _armed(tester);
    await tester.ensureVisible(find.byKey(const Key('chat-session-p1')));
    await tester.tap(find.byKey(const Key('chat-session-p1')));
    await _settle(tester);
    expect(server.resolves.single, containsPair('scope', 'session'));
    expect(server.resolves.single, containsPair('decision', 'allow'));
    expect(server.resolves.single, containsPair('remember', false));
    // The server's `permission.closed` takes every copy away, here and in «Da te».
    expect(find.byKey(const Key('chat-request-p1')), findsNothing);
    expect(app.live.approvals, isEmpty);
    await done(tester);
  });

  testWidgets('«sempre», and «nega e spiega» with the words the agent reads', (tester) async {
    server.permissions.addAll([perm('p1'), perm('p2')]);
    await open(tester);
    await _armed(tester);
    await tester.ensureVisible(find.byKey(const Key('chat-always-p1')));
    await tester.tap(find.byKey(const Key('chat-always-p1')));
    await _settle(tester);
    expect(server.resolves.last, containsPair('scope', 'always'));
    expect(server.resolves.last, containsPair('remember', true));
    await tester.ensureVisible(find.byKey(const Key('chat-why-p2')));
    // 3.10.4: the bigger text may scroll it into view: armed again.
    await _armed(tester);
    await tester.tap(find.byKey(const Key('chat-why-p2')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('chat-why-text-p2')), 'non quel file, l\'altro');
    await _settle(tester, 2);
    await tester.tap(find.byKey(const Key('chat-why-send-p2')));
    await _settle(tester);
    expect(server.resolves.last, containsPair('decision', 'deny'));
    expect(server.resolves.last, containsPair('reason', 'non quel file, l\'altro'));
    await done(tester);
  });

  testWidgets('a dangerous one has no «sempre»; a truly dangerous one opens its own screen', (
    tester,
  ) async {
    server.permissions.addAll([
      perm('p1', danger: ['git-push']),
      {
        ...perm('p2', input: {'command': 'rm -rf /etc'}, danger: ['critical-system']),
        'critical': [
          {'id': 'critical-system', 'action': 'system-delete', 'target': '/etc'},
        ],
      },
    ]);
    await open(tester);
    await _armed(tester);
    expect(find.byKey(const Key('chat-always-p1')), findsNothing);
    expect(find.byKey(const Key('chat-session-p1')), findsNothing);
    expect(find.byKey(const Key('chat-allow-p2')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('chat-open-p2')));
    await tester.tap(find.byKey(const Key('chat-open-p2')));
    await _settle(tester);
    expect(find.byKey(const Key('critical-screen')), findsOneWidget);
    await done(tester);
  });

  testWidgets('«consenti sempre per questo lavoro» on a danger, never on a truly dangerous one', (
    tester,
  ) async {
    server.permissions.addAll([
      perm('p1', input: {'command': 'docker restart caddy'}, danger: ['containers']),
      perm('p2'),
      {
        ...perm('p3', input: {'command': 'rm -rf /etc'}, danger: ['critical-system']),
        'critical': [
          {'id': 'critical-system', 'action': 'system-delete', 'target': '/etc'},
        ],
      },
    ]);
    await open(tester);
    await _armed(tester);
    expect(find.byKey(const Key('chat-work-p2')), findsNothing);
    expect(find.byKey(const Key('chat-work-p3')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('chat-work-p1')));
    // Scrolled into view: armed again (the page's `useArmed`).
    await _armed(tester);
    await tester.tap(find.byKey(const Key('chat-work-p1')));
    await _settle(tester);
    expect(server.resolves.last, containsPair('scope', 'work'));
    expect(server.resolves.last, containsPair('decision', 'allow'));
    expect(server.resolves.last, containsPair('remember', false));
    await done(tester);
  });

  testWidgets('a switched-off tool asked back, and an artifact\'s spending cap', (tester) async {
    server.permissions.addAll([
      perm('t1', tool: 'request_tool', input: {'tool': 'web_fetch', 'why': 'leggere la guida'}),
      perm('g1', tool: 'artifact_capability', input: {'capability': 'ask', 'path': 'app.html'}),
    ]);
    await open(tester);
    expect(find.textContaining('leggere la guida'), findsOneWidget);
    await _armed(tester);
    await tester.ensureVisible(find.byKey(const Key('chat-always-t1')));
    await tester.tap(find.byKey(const Key('chat-always-t1')));
    await _settle(tester);
    expect(server.resolves.last, containsPair('scope', 'always'));
    await tester.ensureVisible(find.byKey(const Key('chat-cap-2.0')));
    // 3.10.4: the bigger text may scroll it into view: armed again.
    await _armed(tester);
    await tester.tap(find.byKey(const Key('chat-cap-2.0')));
    await _settle(tester, 2);
    expect(find.text('Consenti, fino a 2 \$'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('chat-allow-g1')));
    // 3.10.4: the bigger text may scroll it into view: armed again.
    await _armed(tester);
    await tester.tap(find.byKey(const Key('chat-allow-g1')));
    await _settle(tester);
    expect(server.resolves.last, containsPair('capUsd', 2.0));
    await done(tester);
  });

  testWidgets('a question in the chat: options, «Altro», then it stays answered', (tester) async {
    await open(tester);
    server.ask({
      'requestId': 'q1',
      'sessionId': 's1',
      'agentId': 'a0',
      'agentName': 'God',
      'projectId': null,
      'createdAt': '2026-11-17T10:00:00.000Z',
      'questions': [
        {
          'question': 'Quale database?',
          'options': [
            {'label': 'Postgres'},
            {'label': 'SQLite', 'description': 'un file solo'},
          ],
          'multiSelect': false,
        },
        {
          'question': 'Quali prove?',
          'options': [
            {'label': 'Unità'},
            {'label': 'Integrazione'},
          ],
          'multiSelect': true,
        },
      ],
    });
    await _settle(tester);
    expect(find.byKey(const Key('chat-question-q1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-option-q1-0-SQLite')));
    await tester.ensureVisible(find.byKey(const Key('chat-option-q1-1-Unità')));
    await tester.tap(find.byKey(const Key('chat-option-q1-1-Unità')));
    await tester.tap(find.byKey(const Key('chat-option-q1-1-Integrazione')));
    await tester.enterText(find.byKey(const Key('chat-other-q1-1')), 'a mano');
    await _settle(tester, 2);
    await tester.ensureVisible(find.byKey(const Key('chat-answer-q1')));
    await tester.tap(find.byKey(const Key('chat-answer-q1')));
    await _settle(tester);
    expect(server.questionAnswers['q1'], [
      ['SQLite'],
      ['Unità', 'Integrazione', 'a mano'],
    ]);
    // `question.answered` arrives in the log: the card stays, with what was said.
    expect(find.byKey(const Key('chat-question-done-q1')), findsOneWidget);
    expect(find.text('Unità; Integrazione; a mano'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a plan: approved with one tap, or revised with words', (tester) async {
    await open(tester);
    for (final id in ['pl1', 'pl2']) {
      server.ask({
        'requestId': id,
        'sessionId': 's1',
        'agentId': 'a0',
        'agentName': 'God',
        'projectId': null,
        'createdAt': '2026-11-17T10:00:00.000Z',
        'plan': '## Piano\n\n1. Leggere\n2. Scrivere',
        'questions': [
          {
            'question': 'Approvi il piano?',
            'options': [
              {'label': 'Approve'},
              {'label': 'Keep planning'},
            ],
            'multiSelect': false,
          },
        ],
      });
    }
    await _settle(tester);
    await tester.ensureVisible(find.byKey(const Key('plan-approve-pl1')));
    await tester.tap(find.byKey(const Key('plan-approve-pl1')));
    await _settle(tester);
    expect(server.questionAnswers['pl1'], [
      ['Approve'],
    ]);
    await tester.ensureVisible(find.byKey(const Key('plan-feedback-pl2')));
    await tester.enterText(find.byKey(const Key('plan-feedback-pl2')), 'prima i test');
    await _settle(tester, 2);
    expect(find.text('Manda il commento'), findsOneWidget);
    await tester.tap(find.byKey(const Key('plan-revise-pl2')));
    await _settle(tester);
    expect(server.questionAnswers['pl2'], [
      ['prima i test'],
    ]);
    await done(tester);
  });

  testWidgets('a message sent while it works waits in line; «togli» takes it back', (tester) async {
    await open(tester);
    server.hold('s1');
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('composer-text')), 'e poi i test');
    await tester.tap(find.byKey(const Key('composer-send')));
    await _settle(tester);
    final sent = server.received.lastWhere((m) => m['type'] == 'session.send');
    final id = sent['clientId'] as String;
    expect(find.byKey(Key('queued-$id')), findsOneWidget);
    expect(find.byKey(const Key('composer-stop')), findsOneWidget);
    await tester.tap(find.byKey(const Key('unqueue')));
    await _settle(tester);
    expect(server.unqueued, [id]);
    expect(find.byKey(Key('queued-$id')), findsNothing);
    // Another one is read when the turn ends: out of the line, into the log.
    await tester.enterText(find.byKey(const Key('composer-text')), 'ultima cosa');
    await tester.tap(find.byKey(const Key('composer-send')));
    await _settle(tester);
    expect(find.text('ultima cosa'), findsOneWidget);
    server.release('s1');
    await _settle(tester);
    expect(find.byKey(const Key('unqueue')), findsNothing);
    expect(find.text('ultima cosa'), findsOneWidget);
    await done(tester);
  });

  testWidgets('«Continua da qui» and «Modifica» make a copy; the original stays', (tester) async {
    await open(tester);
    server.say('s1', 'Prima domanda');
    await _settle(tester);
    final seq = server.logs['s1']!.firstWhere((e) => e['type'] == 'message.user')['seq'] as int;
    await tester.ensureVisible(find.byKey(Key('fork-here-e$seq')));
    await tester.tap(find.byKey(Key('fork-here-e$seq')));
    await _settle(tester);
    expect(server.forks.single, containsPair('fromSeq', seq));
    // The copy opens, with its mark and the way back.
    expect(find.byKey(const Key('fork-back-s1')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('fork-back-s1')))).pop();
    await _settle(tester);
    await tester.ensureVisible(find.byKey(Key('edit-e$seq')));
    await tester.tap(find.byKey(Key('edit-e$seq')));
    await _settle(tester);
    await tester.enterText(find.byKey(Key('edit-text-e$seq')), 'Domanda corretta');
    await _settle(tester, 2);
    await tester.tap(find.byKey(Key('edit-send-e$seq')));
    await _settle(tester, 10);
    expect(server.forks.last, containsPair('beforeSeq', seq));
    final to = server.forks.last['to'] as String;
    expect(
      server.received
          .where((m) => m['type'] == 'session.send' && m['sessionId'] == to)
          .single['text'],
      'Domanda corretta',
    );
    await done(tester);
  });

  testWidgets('the summary asked by hand is undone; steps above the composer; tool lines', (
    tester,
  ) async {
    await open(tester);
    server
      ..store('s1', 'tool.call', {
        'callId': 'c1',
        'tool': 'update_todos',
        'input': {
          'todos': [
            {'content': 'Leggere il codice', 'status': 'completed'},
            {'content': 'Scrivere la prova', 'status': 'in_progress'},
            {'content': 'Lanciare la suite', 'status': 'pending'},
          ],
        },
      })
      ..store('s1', 'tool.result', {'callId': 'c1', 'ok': true, 'output': 'ok'})
      ..store('s1', 'tool.call', {
        'callId': 'c2',
        'tool': 'edit_file',
        'input': {'path': 'src/login.ts'},
      })
      ..store('s1', 'tool.result', {
        'callId': 'c2',
        'ok': true,
        'output': 'Edited src/login.ts\n```diff\n@@ -1,2 +1,2 @@\n-const a = 1;\n+const a = 2;\n+const b = 3;\n```',
      })
      ..store('s1', 'tool.call', {
        'callId': 'c3',
        'tool': 'bash',
        'input': {'command': 'npm test'},
      })
      ..store('s1', 'tool.result', {'callId': 'c3', 'ok': false, 'output': '1 failed'})
      ..store('s1', 'compaction', {'summary': 'Riassunto: il login.', 'reason': 'manual'});
    await _settle(tester);
    expect(find.text('Passi: 1 su 3 fatti'), findsOneWidget);
    expect(find.text('Scrivere la prova'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('-1'), findsOneWidget);
    expect(find.byKey(const Key('tool-diff')), findsOneWidget);
    expect(find.text('npm test'), findsOneWidget);
    final seq = server.logs['s1']!.lastWhere((e) => e['type'] == 'compaction')['seq'] as int;
    await tester.ensureVisible(find.byKey(Key('compaction-undo-$seq')));
    await tester.tap(find.byKey(Key('compaction-undo-$seq')));
    await _settle(tester);
    expect(server.undone, ['s1']);
    expect(find.byKey(Key('compaction-undo-$seq')), findsNothing);
    expect(
      find.text('Riassunto annullato: la conversazione intera torna al modello'),
      findsNothing,
    );
    await done(tester);
  });

  testWidgets('a secret is held back before it leaves; sent without it', (tester) async {
    await open(tester);
    await tester.enterText(
      find.byKey(const Key('composer-text')),
      'usa questa chiave sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789ABCD',
    );
    await tester.tap(find.byKey(const Key('composer-send')));
    await _settle(tester);
    expect(server.received.where((m) => m['type'] == 'session.send'), isEmpty);
    expect(find.text('Invia senza'), findsOneWidget);
    await tester.tap(find.text('Invia senza'));
    await _settle(tester);
    final sent = server.received.lastWhere((m) => m['type'] == 'session.send');
    expect(sent['text'], contains('[secret removed]'));
    expect(sent['text'], isNot(contains('sk-ant')));
    await done(tester);
  });

  testWidgets('«Invia comunque»: as written, with the choice (2026-11-19)', (tester) async {
    await open(tester);
    const odd = 'il codice del pacco è Ab3dE5fG7hJ9kL1mN3pQ5rS7tU';
    await tester.enterText(find.byKey(const Key('composer-text')), odd);
    await tester.tap(find.byKey(const Key('composer-send')));
    await _settle(tester);
    expect(server.received.where((m) => m['type'] == 'session.send'), isEmpty);
    expect(find.textContaining('Non è un segreto'), findsOneWidget);
    await tester.tap(find.byKey(const Key('secret-send-anyway')));
    await _settle(tester);
    final sent = server.received.lastWhere((m) => m['type'] == 'session.send');
    expect(sent['text'], odd);
    expect(sent['secretOk'], isTrue);
    await done(tester);
  });

  testWidgets('a pasted shop link goes without asking (2026-11-19)', (tester) async {
    await open(tester);
    const link =
        'https://www.amazon.it/dp/B0CHWRXH8B?crid=2X3K9QZ7M1ABC&dib=eyJ2IjoiMSJ9.M4fWq7XkPz3RtY8sLmN2bVcQ9wEaH5jK1oUiP0lZxCv6BnM.Xk9Lq2Wm8NvBz3PcRf7HtY5gJu1&dib_tag=se';
    await tester.enterText(find.byKey(const Key('composer-text')), link);
    await tester.tap(find.byKey(const Key('composer-send')));
    await _settle(tester);
    final sent = server.received.lastWhere((m) => m['type'] == 'session.send');
    expect(sent['text'], link);
    expect(sent.containsKey('secretOk'), isFalse);
    await done(tester);
  });

  testWidgets('a long paste becomes a card beside the message', (tester) async {
    await open(tester);
    final long = List.filled(60, 'riga di log').join('\n');
    await tester.enterText(find.byKey(const Key('composer-text')), 'guarda: ');
    await _settle(tester, 2);
    await tester.enterText(find.byKey(const Key('composer-text')), 'guarda: $long');
    await _settle(tester, 2);
    expect(find.byKey(const Key('pasted-0')), findsOneWidget);
    final field = tester.widget<TextField>(find.byKey(const Key('composer-text')));
    expect(field.controller!.text, 'guarda: ');
    await done(tester);
  });
}
