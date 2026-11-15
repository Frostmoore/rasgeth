// Team as the user drew it (3.8.1): God's big card on top (its mascot, state and what it is
// doing; a tap opens its conversation), the Chat's wide card under it (a tap opens the Chat), then
// «Agents» and the grid of the others. Demi-God is not in Team (Telegram's voice). Filters and
// favourites are the grid's only. Against the fake RedGiant.
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

AppController _app() =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )
      ..locale = const Locale('it')
      ..reduceMotion = true;

Future<void> _pump(WidgetTester tester, AppController app) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

/// The tree gone and the clock run on, so no timer of the app is left behind.
Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 3));
}

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

List<String> _grid(WidgetTester tester) => [
  for (final e in find.byKey(const Key('team-grid')).evaluate())
    for (final t
        in find
            .descendant(of: find.byWidget(e.widget), matching: find.byType(Text))
            .evaluate()
            .map((x) => (x.widget as Text).data ?? ''))
      if (!['fermo', 'attivo', 'lavora', 'pensa', 'aspetta te', 'bloccato'].contains(t)) t,
];

void main() {
  late FakeRedGiant server;
  setUp(() async {
    // Real HTTP to the fake RedGiant (widget tests answer 400 to every request otherwise).
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
  });
  tearDown(() => server.close());

  testWidgets('God on top, the Chat under it, then «Agenti»; no Demi-God', (tester) async {
    final app = _app();
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    await _pump(tester, app);
    await _settle(tester);
    final god = find.byKey(const Key('team-god'));
    final chat = find.byKey(const Key('team-chat'));
    final header = find.byKey(const Key('team-agents-header'));
    expect(find.descendant(of: god, matching: find.text('God')), findsOneWidget);
    expect(find.descendant(of: chat, matching: find.text('Chat')), findsOneWidget);
    expect(find.text('Agenti'), findsOneWidget);
    // In this order, top to bottom.
    expect(tester.getRect(god).bottom, lessThanOrEqualTo(tester.getRect(chat).top));
    expect(tester.getRect(chat).bottom, lessThanOrEqualTo(tester.getRect(header).top));
    // God's card is the big one.
    expect(tester.getSize(god).height, greaterThan(tester.getSize(chat).height));
    // What God is doing, in words.
    expect(find.byKey(const Key('team-god-doing')), findsOneWidget);
    // The others by name; never God, the Chat, Demi-God, subagents or inspectors.
    expect(_grid(tester), ['Assistente mail', 'Capo cantiere', 'Coder Web', 'Ricercatore']);
    expect(find.text('Demi'), findsNothing);
    await _done(tester);
  });

  testWidgets('a tap on God opens its conversation, on the Chat opens the Chat', (tester) async {
    final app = _app();
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    await _pump(tester, app);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('team-chat')));
    await tester.pumpAndSettle();
    expect(app.tab, AppTab.chat);
    await tester.tap(find.byKey(const Key('tab-team')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team-god')));
    await _settle(tester);
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(tester.widget<ConversationScreen>(find.byType(ConversationScreen)).agent?.name, 'God');
    expect(server.requests, contains('POST /api/agents/a0/work-session'));
    await _done(tester);
  });

  testWidgets('filters and favourites are the grid\'s: God and the Chat stay', (tester) async {
    final app = _app();
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    app.toggleFavourite('a3');
    await _pump(tester, app);
    await _settle(tester);
    // The favourite first.
    expect(_grid(tester).first, 'Coder Web');
    await tester.tap(find.byKey(const Key('team-filter-favourites')));
    await tester.pumpAndSettle();
    expect(_grid(tester), ['Coder Web']);
    expect(find.byKey(const Key('team-god')), findsOneWidget);
    expect(find.byKey(const Key('team-chat')), findsOneWidget);
    // A long press on God's card shows its sheet too.
    await tester.longPress(find.byKey(const Key('team-god')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('agent-sheet-a0')), findsOneWidget);
    await _done(tester);
  });
}
