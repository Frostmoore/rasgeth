// 3.8.3: the conversations «full window» on computers. Going in from the panel's header, the
// mascots' bar on the left (God's requests counted, the open one lit), changing agent from the
// bar, Escape (not while something is being written), Ctrl+Shift+F, back to the room, and the
// mode kept between one opening and the next.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.agentOverrides['a3'] = {'projectId': 'demo'};
    server.agentOverrides['a2'] = {'projectId': 'demo'};
  });
  tearDown(() => server.close());

  Future<AppController> start(WidgetTester tester, MemoryAppPrefs prefs) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: prefs,
            platform: DevicePlatform.linux,
            liveEnabled: false,
          )
          ..locale = const Locale('it')
          ..reduceMotion = true;
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(1440, 900);
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

  DeskController desk(WidgetTester tester) =>
      DeskScope.read(tester.element(find.byKey(const Key('desk-panel'))));

  Finder composer() => find
      .descendant(of: find.byKey(const Key('desk-panel')), matching: find.byType(TextField))
      .last;

  Future<void> esc(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester, 4);
  }

  testWidgets('in from the panel, the bar changes agent, Esc and Ctrl+Shift+F, kept', (
    tester,
  ) async {
    final prefs = MemoryAppPrefs();
    await start(tester, prefs);
    await tester.tap(find.byKey(const Key('tile-a3')));
    await _settle(tester);
    expect(find.byKey(const Key('desk-rail')), findsNothing);

    // The panel's header: «Full window».
    await tester.tap(find.byKey(const Key('panel-full')));
    await _settle(tester);
    expect(find.byKey(const Key('desk-rail')), findsOneWidget);
    expect(find.byKey(const Key('tile-a3')), findsNothing, reason: 'the wall is covered');
    expect(find.byKey(const Key('panel-unfull')), findsOneWidget);
    expect(prefs.values[DeskController.fullPref], '1');
    // God, the Chat and the agents in the bar; God's two requests counted.
    expect(find.byKey(const Key('rail-a0')), findsOneWidget);
    expect(find.byKey(const Key('rail-a3')), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('rail-asks-a0')), matching: find.text('2')),
      findsOneWidget,
    );
    expect(desk(tester).panelAgentId, 'a3');

    // Another agent from the bar: its conversation, still full window.
    await tester.tap(find.byKey(const Key('rail-a2')));
    await _settle(tester);
    expect(desk(tester).panelAgentId, 'a2');
    expect(find.byKey(const Key('desk-rail')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('desk-panel')),
        matching: find.byType(ConversationScreen),
      ),
      findsOneWidget,
    );

    // Escape while writing: nothing; with the field empty: back to the panel.
    await tester.enterText(composer(), 'una bozza');
    await _settle(tester, 3);
    await esc(tester);
    expect(find.byKey(const Key('desk-rail')), findsOneWidget);
    // The draft goes with the conversation into the panel and back.
    await tester.tap(find.byKey(const Key('panel-unfull')));
    await _settle(tester);
    expect(find.byKey(const Key('desk-rail')), findsNothing);
    expect(find.text('una bozza'), findsOneWidget);
    expect(prefs.values[DeskController.fullPref], isNull);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(tester, 4);
    expect(find.byKey(const Key('desk-rail')), findsOneWidget);
    expect(find.text('una bozza'), findsOneWidget);
    await tester.enterText(composer(), '');
    await _settle(tester, 3);
    await esc(tester);
    expect(find.byKey(const Key('desk-rail')), findsNothing);
    expect(find.byKey(const Key('desk-panel')), findsOneWidget);
    expect(find.byKey(const Key('tile-a3')), findsOneWidget);

    // The menu Vista has it too; then back to the room from the bar: the mode stays.
    await tester.tap(find.byKey(const Key('menu-Vista')));
    await _settle(tester, 3);
    await tester.tap(find.byKey(const Key('menuitem-full-window')));
    await _settle(tester);
    expect(find.byKey(const Key('desk-rail')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rail-room')));
    await _settle(tester);
    expect(find.byKey(const Key('desk-rail')), findsNothing);
    expect(find.byKey(const Key('desk-panel')), findsNothing);
    expect(find.byKey(const Key('tile-a3')), findsOneWidget);
    expect(prefs.values[DeskController.fullPref], '1');
    await done(tester);

    // Next opening: a conversation opens full window at once.
    await start(tester, prefs);
    await tester.tap(find.byKey(const Key('tile-a3')));
    await _settle(tester);
    expect(find.byKey(const Key('desk-rail')), findsOneWidget);
    expect(desk(tester).panelAgentId, 'a3');
    await done(tester);
  });

  // 3.8.4: from the «Chat» card the list opens in the panel; a chat opened from there is the panel's
  // conversation, with «full window» in its header, not a page pushed over the list without it.
  testWidgets('a chat opened from the Chat card has the full window button', (tester) async {
    final prefs = MemoryAppPrefs();
    await start(tester, prefs);
    await tester.tap(find.byKey(const Key('desk-chat')));
    await _settle(tester);
    expect(find.byKey(const Key('panel-full')), findsNothing);
    await tester.tap(find.byKey(const Key('chat-new')));
    await _settle(tester);
    expect(find.byKey(const Key('panel-full')), findsOneWidget);
    await tester.tap(find.byKey(const Key('panel-full')));
    await _settle(tester);
    expect(find.byKey(const Key('panel-unfull')), findsOneWidget);
    await done(tester);
  });
}
