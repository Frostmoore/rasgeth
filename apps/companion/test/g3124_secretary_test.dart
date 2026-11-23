// 3.12.4: Settings › Messages native against the fake server (test/fake_secretary.dart): the
// requests with a ready reply (send as it is, edit, refuse), a conversation (pause the agent), the
// WhatsApp guide that stops at remote access and moves on step by step, and the Telegram guide.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/settings/channels/secretary_screen.dart';

import 'fake_secretary.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late FakeRedGiant server;
  late FakeSecretary sc;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    sc = FakeSecretary();
    server.secretary = sc;
  });
  tearDown(() => server.close());

  Future<void> start(WidgetTester tester, {String lang = 'en'}) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
            platform: DevicePlatform.android,
            liveEnabled: false,
          )
          ..locale = Locale(lang)
          ..reduceMotion = true;
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const SecretaryScreen(poll: false))).ignore();
    await _settle(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await _settle(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  testWidgets('a request with a ready reply: send as it is, edited, or refuse', (tester) async {
    await start(tester);
    expect(find.text('Wants a table for 4 on Friday'), findsOneWidget);
    expect(find.text('Luca'), findsWidgets);
    await tap(tester, 'sc-send-p1');
    expect(sc.calls, contains('POST /api/secretary/pending/p1/approve'));
    expect(sc.bodies['/api/secretary/pending/p1/approve'], <String, dynamic>{});
    expect(find.byKey(const Key('sc-pending-p1')), findsNothing);
    await done(tester);
  });

  testWidgets('an edited reply goes as the person wrote it; refusing sends nothing', (
    tester,
  ) async {
    await start(tester);
    await tester.enterText(find.byKey(const Key('sc-draft-p1')), 'Friday at 9.');
    await tester.pump();
    expect(find.text('Send my version'), findsOneWidget);
    await tap(tester, 'sc-send-p1');
    expect(sc.bodies['/api/secretary/pending/p1/approve'], {'text': 'Friday at 9.'});
    await done(tester);
  });

  testWidgets('refuse closes the request', (tester) async {
    await start(tester);
    await tap(tester, 'sc-refuse-p1');
    expect(sc.calls, contains('POST /api/secretary/pending/p1/refuse'));
    await done(tester);
  });

  testWidgets('a conversation: read it, pause the agent for this person', (tester) async {
    await start(tester);
    await tap(tester, 'sc-contact-c1');
    expect(find.text('Can you fix my car?'), findsWidgets);
    await tap(tester, 'sc-pause');
    expect(sc.bodies['/api/secretary/contacts/c1'], {'paused': true});
    await done(tester);
  });

  testWidgets('the WhatsApp guide stops at remote access and says where to set it', (tester) async {
    await start(tester);
    await tap(tester, 'sc-add-wa');
    expect(find.textContaining('Remote access is not set up'), findsOneWidget);
    expect(find.byKey(const Key('sc-open-remote')), findsOneWidget);
    expect(sc.calls.contains('POST /api/secretary/whatsapp/start'), isFalse);
    await done(tester);
  });

  testWidgets('the WhatsApp guide goes on when the checks pass; a wrong token stays', (
    tester,
  ) async {
    sc.remoteOk = true;
    await start(tester);
    await tap(tester, 'sc-add-wa');
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    await tap(tester, 'sc-wa-next-2');
    await tester.enterText(find.byKey(const Key('sc-wa-phone')), '1055555555');
    await tester.pump();
    await tap(tester, 'sc-wa-next-3');
    sc.tokenOk = false;
    await tester.enterText(find.byKey(const Key('sc-wa-token')), 'x' * 30);
    await tester.pump();
    await tap(tester, 'sc-wa-test');
    expect(find.textContaining('The token is wrong or expired'), findsOneWidget);
    sc.tokenOk = true;
    await tap(tester, 'sc-wa-test');
    expect(find.byKey(const Key('sc-wa-secret')), findsOneWidget);
    await done(tester);
  });

  testWidgets('Telegram: the token is tried, then the bot is connected', (tester) async {
    sc.remoteOk = true;
    await start(tester);
    await tap(tester, 'sc-add-tg');
    await tester.pump(const Duration(seconds: 1));
    await _settle(tester);
    await tap(tester, 'sc-tg-next-2');
    await tester.enterText(
      find.byKey(const Key('sc-tg-token')),
      '123456:ABCDEFGHIJKLMNOPQRSTUVWXYZ012345',
    );
    await tester.pump();
    await tap(tester, 'sc-tg-test');
    expect(find.textContaining('salone_bot'), findsOneWidget);
    await done(tester);
  });

  testWidgets('it speaks Italian', (tester) async {
    await start(tester, lang: 'it');
    expect(find.text('Collega WhatsApp Business'), findsOneWidget);
    await done(tester);
  });
}
