// 3.8.9: removing an agent from the app, as the page does. The context menu and the long press
// sheet say «Remove…» (never for God, Demi-God or the Chat); our dialog lists who goes with it and
// the tasks that close; «Removed agents» shows when, by whom and why, and «Restore» brings it back.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

String _texts(WidgetTester tester, Finder of) => tester
    .widgetList<Text>(find.descendant(of: of, matching: find.byType(Text)))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');

String _dialogText(WidgetTester tester) => tester
    .widgetList<SelectableText>(
      find.descendant(of: find.byType(AlertDialog), matching: find.byType(SelectableText)),
    )
    .map((t) => t.data ?? '')
    .join('\n');

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    // Tester works under Coder Web: it goes with it.
    server.agentOverrides['a7'] = {'parentId': 'a3'};
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    required Size size,
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
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    return app;
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  test('a removed agent is never read as active', () {
    final a = Agent.fromJson({'id': 'x', 'kind': 'agent', 'name': 'X', 'status': 'removed'});
    expect(a.active, isFalse);
    final r = RemovedAgent.fromJson({
      'id': 'x',
      'kind': 'agent',
      'name': 'X',
      'status': 'removed',
      'removed': {
        'at': '2026-11-17T09:30:00.000Z',
        'by': 'God',
        'reason': 'not needed',
        'with': [
          {'id': 'y', 'name': 'Y', 'kind': 'subagent'},
        ],
        'sessions': 3,
      },
    });
    expect((r.by, r.byPerson, r.reason, r.sessions), ('God', false, 'not needed', 3));
    expect(r.others.single.kind, AgentKind.subagent);
  });

  testWidgets('computer: «Remove…» in the menu, the list in our dialog, the team without it', (
    tester,
  ) async {
    final app = await start(tester, size: const Size(1440, 900));
    await tester.tap(find.byKey(const Key('tile-a3')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-remove')), findsOneWidget);
    expect(find.text('Rimuovi…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-menu-remove')));
    await _settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    final body = _dialogText(tester);
    expect(body, contains('Insieme a lui: Tester'));
    expect(body, contains('Compiti aperti che si chiudono («agente rimosso»): 2'));
    expect(body, contains('Conversazioni al lavoro che si fermano ora: 1'));
    expect(body, contains('Agenti rimossi'));
    // «No» changes nothing.
    await tester.tap(find.byKey(const Key('dialog-no')));
    await _settle(tester, 4);
    expect(server.removedIds, isEmpty);
    await tester.tap(find.byKey(const Key('tile-a3')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tester.tap(find.byKey(const Key('agent-menu-remove')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.removedIds, {'a3', 'a7'});
    expect(server.requests.where((x) => x.startsWith('POST /api/agents/a3/remove')), hasLength(1));
    expect(app.agents.any((a) => a.id == 'a3' || a.id == 'a7'), isFalse);
    expect(find.byKey(const Key('tile-a3')), findsNothing);
    await done(tester);
  });

  testWidgets('computer: God and the Chat have no «Remove…»', (tester) async {
    await start(tester, size: const Size(1440, 900));
    final godFace = find.descendant(
      of: find.byKey(const Key('desk-god')),
      matching: find.byType(InkWell),
    );
    await tester.tap(godFace.first, buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
    expect(find.byKey(const Key('agent-menu-remove')), findsNothing);
    await tester.tapAt(const Offset(5, 890));
    await _settle(tester, 4);
    await tester.tap(find.byKey(const Key('desk-chat')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
    expect(find.byKey(const Key('agent-menu-remove')), findsNothing);
    await done(tester);
  });

  testWidgets('phone: the sheet removes; «Removed agents» shows it and restores it', (
    tester,
  ) async {
    final app = await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
    await tester.longPress(find.byKey(const Key('agent-a3')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-sheet-a3')), findsOneWidget);
    final remove = find.byKey(const Key('agent-remove'));
    await tester.ensureVisible(remove);
    await tester.pump();
    await tester.tap(remove);
    await _settle(tester);
    expect(_dialogText(tester), contains('Insieme a lui: Tester'));
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.removedIds, {'a3', 'a7'});
    expect(find.byKey(const Key('agent-sheet-a3')), findsNothing);
    expect(find.byKey(const Key('agent-a3')), findsNothing);

    // The row at the end of Team opens «Removed agents».
    final row = find.byKey(const Key('team-removed'));
    await tester.scrollUntilVisible(row, 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(row);
    await _settle(tester);
    final card = find.byKey(const Key('removed-a3'));
    expect(card, findsOneWidget);
    final words = _texts(tester, card);
    expect(words, contains('Coder Web'));
    expect(words, contains('da te'));
    expect(words, contains('Insieme a lui: Tester'));
    expect(words, contains('Conversazioni (1)'));
    await tester.tap(find.byKey(const Key('removed-restore-a3')));
    await _settle(tester);
    expect(server.restores, ['a3']);
    expect(server.removedIds, isEmpty);
    expect(find.byKey(const Key('removed-a3')), findsNothing);
    expect(find.text('Coder Web è di nuovo nella squadra.'), findsOneWidget);
    expect(find.text('Nessun agente rimosso.'), findsOneWidget);
    expect(app.agents.any((a) => a.id == 'a3'), isTrue);
    await done(tester);
  });
}
