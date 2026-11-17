// 3.8.9: stopping is a pause, as on the page. «Stop…» asks in our dialog and says the open tasks
// wait; a stopped agent shows «Resume» in the context menu, the sheet, its settings and where the
// composer was in its conversations; resuming calls the server and the team reads it as working.
// «Remove…» stays another thing (out of the team), and «Stop what it is doing» only stops a turn.
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

  testWidgets('computer: «Stop…» asks and says it is a pause; then the menu says «Resume»', (
    tester,
  ) async {
    final app = await start(tester, size: const Size(1440, 900));
    await tester.tap(find.byKey(const Key('tile-a3')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-pause')), findsOneWidget);
    expect(find.byKey(const Key('agent-menu-resume')), findsNothing);
    expect(find.byKey(const Key('agent-menu-remove')), findsOneWidget);
    expect(find.text('Ferma…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-menu-pause')));
    await _settle(tester);
    final body = _dialogText(tester);
    expect(body, contains('È una pausa'));
    expect(body, contains('Riattiva'));
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.stops, ['a3']);
    expect(app.agents.firstWhere((a) => a.id == 'a3').active, isFalse);
    expect(find.text('Coder Web è in pausa: «Riattiva» lo riporta.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tile-a3')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-pause')), findsNothing);
    expect(find.byKey(const Key('agent-menu-resume')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-menu-resume')));
    await _settle(tester);
    expect(server.resumes, ['a3']);
    expect(app.agents.firstWhere((a) => a.id == 'a3').active, isTrue);
    expect(find.text('Coder Web lavora di nuovo: i compiti aperti ripartono.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('God has neither «Stop…» nor «Resume»', (tester) async {
    await start(tester, size: const Size(1440, 900));
    final godFace = find.descendant(
      of: find.byKey(const Key('desk-god')),
      matching: find.byType(InkWell),
    );
    await tester.tap(godFace.first, buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
    expect(find.byKey(const Key('agent-menu-pause')), findsNothing);
    expect(find.byKey(const Key('agent-menu-resume')), findsNothing);
    await done(tester);
  });

  testWidgets('phone: a stopped agent\'s sheet resumes it; a working one\'s says «Stop…»', (
    tester,
  ) async {
    server.agentOverrides['a3'] = {'status': 'stopped'};
    final app = await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
    await tester.longPress(find.byKey(const Key('agent-a3')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-pause')), findsNothing);
    final resume = find.byKey(const Key('agent-resume'));
    await tester.ensureVisible(resume);
    await tester.pump();
    await tester.tap(resume);
    await _settle(tester);
    expect(server.resumes, ['a3']);
    expect(app.agents.firstWhere((a) => a.id == 'a3').active, isTrue);
    // The word about it goes away, then the sheet again.
    await tester.pump(const Duration(seconds: 6));
    await _settle(tester);
    await tester.longPress(find.byKey(const Key('agent-a3')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-resume')), findsNothing);
    expect(find.byKey(const Key('agent-pause')), findsOneWidget);
    await done(tester);
  });

  test('«Resume» refused says why, and changes nothing', () async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
      liveEnabled: false,
    );
    await app.connect(server.base.toString(), 'secret');
    final a3 = app.agents.firstWhere((a) => a.id == 'a3');
    final r = await app.resumeAgent(a3);
    expect(r.why, contains('is not stopped'));
    expect(server.resumes, isEmpty);
    app.dispose();
  });
}
