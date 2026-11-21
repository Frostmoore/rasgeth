// G42.13: Settings › Telegram, Chats and the mailboxes native, against the fake server that
// answers as the real one (test/fake_channels.dart): the three steps of Telegram with the token
// tried and refused, the pairing code and the linked accounts; a chat platform switched on with
// what it needs, its code, its account unlinked and switched off; the mailboxes added, changed
// and removed, a refused password said in words; the way in from «Settings of <name>».
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/channels/chats_screen.dart';
import 'package:rgcompanion/settings/channels/mailboxes.dart';
import 'package:rgcompanion/settings/channels/telegram_screen.dart';

import 'fake_channels.dart';
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
  late FakeChannels ch;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    ch = FakeChannels(server.setup);
    server.channels = ch;
  });
  tearDown(() => server.close());

  Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 4000)}) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
            platform: DevicePlatform.android,
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

  Future<void> push(WidgetTester tester, Widget screen) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
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

  testWidgets('Telegram: BotFather, a refused token, the code, the account, unlink', (
    tester,
  ) async {
    final opened = <Uri>[];
    await start(tester);
    await push(
      tester,
      TelegramScreen(
        poll: false,
        openUrl: (u) async {
          opened.add(u);
          return true;
        },
      ),
    );
    expect(find.text('Rasgeth sul tuo telefono'), findsWidgets);
    expect(find.text('adesso'), findsOneWidget);
    await tap(tester, 'tg-open-botfather');
    expect(opened.single.toString(), 'https://t.me/BotFather');
    // A token too short cannot be tried; a wrong one is refused in words.
    await tester.enterText(find.byKey(const Key('tg-token')), 'short');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byKey(const Key('tg-check'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('tg-token')), '123456789:AAH-wrong-token-here');
    await tap(tester, 'tg-check');
    expect(find.text('Telegram did not accept this token'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('tg-token')), '123456789:AAH-good-token-here');
    await tap(tester, 'tg-check');
    expect(ch.telegramToken, '123456789:AAH-good-token-here');
    expect(find.text('K7Q2'), findsOneWidget);
    await tap(tester, 'tg-open-bot');
    expect(opened.last.toString(), 'https://t.me/rasgeth_bot?start=K7Q2');
    // Start pressed in Telegram: the account shows up, with Unlink.
    ch.linkTelegram(42, 'mario');
    await push(tester, const TelegramScreen(poll: false));
    expect(find.byKey(const Key('tg-linked')), findsOneWidget);
    expect(find.byKey(const Key('tg-account-42')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('tg-account-42')));
    await tester.tap(
      find.descendant(of: find.byKey(const Key('tg-account-42')), matching: find.text('Scollega')),
    );
    await _settle(tester);
    expect(ch.telegramLinks, isEmpty);
    expect(find.byKey(const Key('tg-account-42')), findsNothing);
    await done(tester);
  });

  testWidgets('Telegram set by the administrator: no field to change it', (tester) async {
    (server.setup['locked'] as Map)['telegram'] = true;
    await start(tester);
    await push(tester, const TelegramScreen(poll: false));
    expect(find.byKey(const Key('tg-token')), findsNothing);
    expect(find.text('impostato dall\'ambiente'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a chat: what it needs, refused, on with its code, an account, off', (tester) async {
    await start(tester);
    await push(tester, const ChatPlatformsScreen(poll: false));
    expect(find.byKey(const Key('chat-tile-discord')), findsOneWidget);
    expect(find.byKey(const Key('chat-tile-imessage')), findsOneWidget);
    await tap(tester, 'chat-tile-slack');
    expect(find.byKey(const Key('chat-form')), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const Key('chat-connect'))).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('chat-field-botToken')), 'xoxb-wrong');
    await tester.enterText(find.byKey(const Key('chat-field-appToken')), 'xapp-1');
    await tap(tester, 'chat-connect');
    expect(find.text('Slack refused the token'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('chat-field-botToken')), 'xoxb-1');
    await tap(tester, 'chat-connect');
    expect(ch.chatSettings['slack'], {'botToken': 'xoxb-1', 'appToken': 'xapp-1'});
    expect(find.byKey(const Key('chat-on')), findsOneWidget);
    expect(find.text('/start P9X4'), findsOneWidget);
    await tap(tester, 'chat-done');
    // The square is lit and says it waits for an account; then who is linked.
    expect(find.text('Acceso: manda il codice dalla chat'), findsOneWidget);
    ch.linkChat('slack', 'U1', 'mario');
    await tap(tester, 'chat-tile-slack');
    expect(find.byKey(const Key('chat-account-U1')), findsOneWidget);
    await tap(tester, 'chat-done');
    expect(find.text('Collegato: mario'), findsOneWidget);
    await tap(tester, 'chat-tile-slack');
    await tap(tester, 'chat-off');
    expect(ch.chatSettings.containsKey('slack'), isFalse);
    expect(find.byKey(const Key('chat-form')), findsOneWidget);
    await done(tester);
  });

  testWidgets('iMessage: the numbered steps and its switch', (tester) async {
    await start(tester);
    await push(tester, const ChatPlatformsScreen(poll: false));
    await tap(tester, 'chat-tile-imessage');
    expect(find.text('Passo per passo'), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('5.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('chat-field-url')), 'http://mac.local:1234');
    await tester.enterText(find.byKey(const Key('chat-field-password')), 'pw');
    await tap(tester, 'chat-field-privateApi');
    await tap(tester, 'chat-connect');
    expect(ch.chatSettings['imessage']?['privateApi'], 'on');
    await done(tester);
  });

  testWidgets('mailboxes: the single one, then many by category, changed and removed', (
    tester,
  ) async {
    await start(tester);
    await push(tester, const Scaffold(body: SingleChildScrollView(child: MailboxesSection())));
    expect(find.byKey(const Key('mailbox-one')), findsOneWidget);
    expect(find.text('Non collegata'), findsOneWidget);
    await tap(tester, 'mailbox-one');
    await tester.enterText(find.byKey(const Key('em-host')), 'imap.example.com');
    await tester.enterText(find.byKey(const Key('em-user')), 'mario@example.com');
    await tester.enterText(find.byKey(const Key('em-password')), 'wrong');
    await tap(tester, 'em-save');
    expect(find.text('The mailbox refused the user or the password'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('em-password')), 'app-password');
    await tap(tester, 'em-save');
    expect(ch.single?['user'], 'mario@example.com');
    expect(find.textContaining('mario@example.com'), findsWidgets);
    // Many mailboxes: one added with its category and «Agents can use it».
    ch.boxes.add({
      'id': 'w1',
      'name': 'Lavoro',
      'category': 'work',
      'host': 'imap.work.it',
      'port': 993,
      'secure': true,
      'user': 'm@work.it',
      'agents': false,
    });
    await push(tester, const Scaffold(body: SingleChildScrollView(child: MailboxesSection())));
    expect(find.byKey(const Key('mailbox-w1')), findsOneWidget);
    await tap(tester, 'mailbox-add');
    await tester.enterText(find.byKey(const Key('mb-name')), 'Casa');
    await tap(tester, 'mb-cat-personal');
    await tester.enterText(find.byKey(const Key('mb-host')), 'imap.casa.it');
    await tester.enterText(find.byKey(const Key('mb-user')), 'm@casa.it');
    await tester.enterText(find.byKey(const Key('mb-password')), 'pw');
    await tap(tester, 'mb-agents');
    await tap(tester, 'mb-advanced');
    await tester.enterText(find.byKey(const Key('mb-smtp-host')), 'smtp.casa.it');
    await tap(tester, 'mb-save');
    final added = ch.bodies['POST /api/settings/mailboxes'] as Map;
    expect(added['category'], 'personal');
    expect(added['agents'], true);
    expect(added['smtp'], {'host': 'smtp.casa.it', 'port': 465, 'secure': true});
    expect(ch.boxes.last.containsKey('password'), isFalse);
    expect(find.text('Personale'), findsWidgets);
    // Changed without a new password: it stays; then removed.
    await tap(tester, 'mailbox-w1');
    await tester.enterText(find.byKey(const Key('mb-custom')), 'Clienti');
    await tap(tester, 'mb-save');
    final changed = ch.bodies['PUT /api/settings/mailboxes/w1'] as Map;
    expect(changed['category'], 'Clienti');
    expect(changed.containsKey('password'), isFalse);
    expect(find.text('Clienti'), findsWidgets);
    await tap(tester, 'mailbox-w1');
    await tap(tester, 'mb-remove');
    expect(ch.boxes.where((b) => b['id'] == 'w1'), isEmpty);
    await done(tester);
  });

  testWidgets('the way in: Telegram and Chats from «Settings of <name>»', (tester) async {
    await start(tester);
    await push(tester, const ServerSettingsScreen());
    await tap(tester, 'settings-telegram');
    expect(find.byKey(const Key('telegram-page')), findsOneWidget);
    await tester.tap(find.byKey(const Key('rules-back')));
    await _settle(tester);
    await tester.pump(const Duration(seconds: 1));
    await tap(tester, 'settings-chats');
    expect(find.byKey(const Key('chats-page')), findsOneWidget);
    await done(tester);
  });
}
