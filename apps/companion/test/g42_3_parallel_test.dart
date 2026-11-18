// G42.3: parallel work in a conversation against the fake server (which answers as ws.ts and
// core.ts do): the sub-agents' tabs over the chat (one at work, one finished, one failed and closed),
// a sub-agent's view with its task and «Ferma» (`session.interrupt`), «x» on a finished tab
// (`subagent.close`), the background commands' strip with «Ferma» (`command.stop`), «Output» (the
// log), the finished ones under their line and «x» (`command.close`), the strip shrunk to a line.
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

void main() {
  late FakeRedGiant server;
  late AppController app;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
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
    await _settle(tester, 10);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  void subagents() {
    server
      ..subagentStarted('s1', 'sub_a', agentId: 'a7', title: 'Prove', task: 'Fai girare le prove.')
      ..subagentStarted('s1', 'sub_b', agentId: 'a3', title: 'Login')
      ..subagentStarted('s1', 'sub_c', agentId: 'a4', title: 'Ricerca')
      ..subagentEnded('s1', 'sub_b', summary: 'Fatto.')
      ..subagentEnded('s1', 'sub_c', status: 'failed')
      ..runningSessions.add('sub_a')
      ..store('sub_a', 'message.user', {'text': 'Fai girare le prove.'})
      ..store('sub_a', 'message.assistant', {
        'parts': [
          {'type': 'text', 'text': 'Le prove **girano**.'},
        ],
        'stopReason': 'end_turn',
      });
  }

  testWidgets('the sub-agents\' tabs: state, the sub-agent\'s view, Ferma and x', (tester) async {
    subagents();
    await open(tester);
    expect(find.byKey(const Key('sub-rows')), findsOneWidget);
    expect(find.byKey(const Key('sub-main-0')), findsOneWidget);
    expect(find.text('Agente principale'), findsOneWidget);
    for (final id in ['sub_a', 'sub_b', 'sub_c']) {
      expect(find.byKey(Key('sub-tab-$id')), findsOneWidget);
    }
    // The one at work has no «x»; the finished and the failed ones do.
    expect(find.byKey(const Key('sub-close-sub_a')), findsNothing);
    expect(find.byKey(const Key('sub-close-sub_b')), findsOneWidget);
    // The one at work wrote something new since it started: the ring.
    expect(find.byKey(const Key('sub-fresh-sub_a')), findsOneWidget);

    await tester.tap(find.byKey(const Key('sub-tab-sub_a')));
    await _settle(tester);
    expect(find.byKey(const Key('sub-task')), findsOneWidget);
    expect(find.textContaining('Compito da'), findsOneWidget);
    expect(find.text('Fai girare le prove.'), findsWidgets);
    expect(find.byKey(const Key('sub-bar')), findsOneWidget);
    expect(find.text('Lavora'), findsWidgets);
    expect(find.byKey(const Key('sub-crumbs')), findsOneWidget);
    // Nobody writes to it: no composer, the bar instead.
    expect(find.byKey(const Key('composer-text')), findsNothing);
    await tester.tap(find.byKey(const Key('sub-stop')));
    await _settle(tester, 3);
    expect(server.parallelActs, contains('interrupt sub_a'));
    // Seen: the ring goes.
    expect(find.byKey(const Key('sub-fresh-sub_a')), findsNothing);

    // Back to the main agent, then the finished tab closed for good.
    await tester.tap(find.byKey(const Key('sub-main-0')));
    await _settle(tester);
    expect(find.byKey(const Key('composer-text')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('sub-close-sub_b')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sub-close-sub_b')));
    await _settle(tester);
    expect(server.parallelActs, contains('subclose sub_b'));
    expect(find.byKey(const Key('sub-tab-sub_b')), findsNothing);
    await done(tester);
  });

  testWidgets('a finished sub-agent says how it ended; an unfinished one left by a restart, too', (
    tester,
  ) async {
    subagents();
    server.runningSessions.clear();
    await open(tester);
    await tester.ensureVisible(find.byKey(const Key('sub-tab-sub_b')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sub-tab-sub_b')));
    await _settle(tester);
    expect(find.byKey(const Key('sub-ended')), findsOneWidget);
    expect(find.text('Finito'), findsWidgets);
    expect(find.byKey(const Key('sub-stop')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('sub-tab-sub_a')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sub-tab-sub_a')));
    await _settle(tester);
    expect(find.byKey(const Key('sub-interrupted')), findsOneWidget);
    await done(tester);
  });

  testWidgets('the background commands\' strip: Ferma, Output, the finished ones, x, one line', (
    tester,
  ) async {
    server
      ..commandStarted('s1', 'c1', 'npm run dev')
      ..commandStarted('s1', 'c2', 'pnpm test')
      ..commandEnded('s1', 'c2', exitCode: 0)
      ..commandLogs['c1'] = [
        {'n': 1, 'clock': '10:00:01', 'at': 0.1, 'stream': 'out', 'text': 'ready on :5173'},
        {'n': 2, 'clock': '10:00:02', 'at': 1.2, 'stream': 'err', 'text': 'warning: slow'},
      ];
    await open(tester);
    expect(find.byKey(const Key('cmd-strip')), findsOneWidget);
    expect(find.text('1 in corso · 1 finiti'), findsOneWidget);
    expect(find.text('npm run dev'), findsOneWidget);
    // The finished ones stay folded under their line.
    expect(find.text('pnpm test'), findsNothing);

    await tester.tap(find.byKey(const Key('cmd-output-c1')));
    await _settle(tester);
    expect(find.byKey(const Key('cmd-output')), findsOneWidget);
    expect(find.text('ready on :5173'), findsOneWidget);
    expect(find.text('2 righe'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cmd-times')));
    await tester.pump();
    expect(find.textContaining('10:00:01 +0.1s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cmd-output-close')));
    await _settle(tester);

    await tester.tap(find.byKey(const Key('cmd-stop-c1')));
    await _settle(tester);
    expect(server.parallelActs, contains('stop c1'));
    // Stopped: both are finished now.
    expect(find.text('2 finiti'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cmd-done-toggle')));
    await _settle(tester, 2);
    expect(find.text('pnpm test'), findsOneWidget);
    expect(find.textContaining('codice d\'uscita 0'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cmd-x-c2')));
    await _settle(tester);
    expect(server.parallelActs, contains('close c2'));
    expect(find.text('pnpm test'), findsNothing);

    // One line, remembered on this device.
    await tester.tap(find.byKey(const Key('cmd-head')));
    await _settle(tester, 2);
    expect(find.text('npm run dev'), findsNothing);
    expect(app.commandStripMin, isTrue);
    expect(await app.prefs.get('cmdStrip'), 'min');
    await done(tester);
  });

  testWidgets('scrolled up, «Vai in fondo» brings the newest message back', (tester) async {
    for (var i = 0; i < 40; i++) {
      server.store('s1', 'message.user', {'text': 'Messaggio $i\n\nriga\n\nriga'});
    }
    await open(tester);
    expect(find.byKey(const Key('to-bottom')), findsNothing);
    await tester.drag(find.byKey(const Key('conversation-items')), const Offset(0, 900));
    await _settle(tester, 2);
    expect(find.byKey(const Key('to-bottom')), findsOneWidget);
    await tester.tap(find.byKey(const Key('to-bottom')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await _settle(tester, 2);
    expect(find.byKey(const Key('to-bottom')), findsNothing);
    await done(tester);
  });
}
