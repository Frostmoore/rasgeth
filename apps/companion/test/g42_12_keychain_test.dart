// G42.12: Settings › Keychain native, against the fake server that answers as the real one
// (test/fake_vault.dart): the list, the keys in use (read only for deleting) and the ones kept
// elsewhere, a value shown only after our window and dropped when hidden, a credential added with
// the generator and changed without its value, deleted after a yes, a CSV's preview and the rows
// kept, a sealed file, the sealed export, the browsers, a closed keychain, and a secret held back
// in the composer put in the keychain («Mettilo nel portachiavi»).
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/extensions/ext_catalog.dart';
import 'package:rgcompanion/settings/vault/keychain_screen.dart';

import 'fake_server.dart';
import 'fake_vault.dart' show FakeVault;

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('names, hosts, expiry and the generator, as the page\'s', () {
    expect(vaultName('Revolut Business'), 'revolut_business');
    expect(vaultName('  Café Örebro!  '), 'cafe_orebro');
    expect(vaultName('x' * 60).length, 40);
    expect(vaultNameRe.hasMatch('revolut_api'), isTrue);
    expect(vaultNameRe.hasMatch('Revolut'), isFalse);
    expect(vaultNameRe.hasMatch('a'), isFalse);
    expect(hostsOf('https://B2B.revolut.com/api/1.0, *.example.com  api.x.io'), [
      'b2b.revolut.com',
      '*.example.com',
      'api.x.io',
    ]);
    final now = DateTime.utc(2026, 11, 21, 12);
    expect(daysLeft('2026-11-30T12:00:00.000Z', now), 9);
    expect(daysLeft('2026-11-20T12:00:00.000Z', now), -1);
    expect(daysLeft(null, now), isNull);
    final r = Random(7);
    final p = generatePassword(24, 'symbols', r);
    expect(p.length, 24);
    expect(p.split('').every(passwordSets['symbols']!.contains), isTrue);
    final pin = generatePassword(6, 'digits', r);
    expect(RegExp(r'^\d{6}$').hasMatch(pin), isTrue);
    // Never the look-alikes the page leaves out.
    expect(passwordSets['letters']!.contains('l'), isFalse);
    expect(passwordSets['letters']!.contains('0'), isFalse);
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeVault vault;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      vault = FakeVault();
      server.vault = vault;
    });
    tearDown(() => server.close());

    Future<AppController> start(
      WidgetTester tester, {
      Size size = const Size(420, 9000),
      bool live = false,
    }) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: live,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() async {
        await app.connect(server.base.toString(), 'secret');
      });
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

    Future<void> type(WidgetTester tester, String key, String text) async {
      await tester.ensureVisible(find.byKey(Key(key)).first);
      await tester.enterText(find.byKey(Key(key)).first, text);
      await tester.pump();
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the list: credentials, the ones in use, the keys kept elsewhere, the uses', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const KeychainScreen(poll: false));
      expect(find.byKey(const Key('keychain-settings')), findsOneWidget);
      expect(find.byKey(const Key('kc-safe')), findsOneWidget);
      expect(find.byKey(const Key('kc-item-v1')), findsOneWidget);
      expect(find.byKey(const Key('kc-item-used-by-v2')), findsOneWidget);
      expect(find.text('Usata da: Modelli e abbonamenti'), findsOneWidget);
      expect(find.byKey(const Key('kc-system-s1')), findsOneWidget);
      expect(find.byKey(const Key('kc-system-s2')), findsOneWidget);
      expect(find.byKey(const Key('kc-use-u2')), findsOneWidget);
      expect(find.text('Not an allowed address'), findsOneWidget);
      expect(find.byKey(const Key('kc-browser-b1')), findsOneWidget);
      // A kind and a search.
      await tap(tester, 'kc-filter-bank');
      expect(find.byKey(const Key('kc-item-v2')), findsNothing);
      await tap(tester, 'kc-filter-all');
      await type(tester, 'kc-search', 'anthropic');
      await _settle(tester);
      expect(find.byKey(const Key('kc-item-v1')), findsNothing);
      expect(find.byKey(const Key('kc-item-v2')), findsOneWidget);
      // No value ever came to the app.
      expect(vault.reveals, 0);
      await done(tester);
    });

    testWidgets('a value: shown only after our window, hidden again; changed without it', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const KeychainScreen(poll: false));
      await tap(tester, 'kc-item-v1');
      expect(find.byKey(const Key('kc-window')), findsOneWidget);
      expect(find.text('rv-secret-v1'), findsNothing);
      await tap(tester, 'kc-show');
      expect(find.byKey(const Key('kc-confirm')), findsOneWidget);
      await tap(tester, 'kc-confirm-no');
      expect(vault.reveals, 0);
      await tap(tester, 'kc-show');
      await tap(tester, 'kc-confirm-yes');
      expect(vault.reveals, 1);
      expect(find.text('rv-secret-v1'), findsOneWidget);
      await tap(tester, 'kc-hide');
      expect(find.text('rv-secret-v1'), findsNothing);
      // Changed: the value is not sent again.
      await type(tester, 'kc-notes', 'Il conto dell\'ufficio');
      await tap(tester, 'kc-save');
      final body = vault.bodies['PUT /api/vault/v1']! as Map<String, dynamic>;
      expect(body.containsKey('value'), isFalse);
      expect(body['notes'], 'Il conto dell\'ufficio');
      expect(body['hosts'], ['b2b.revolut.com']);
      expect(find.byKey(const Key('kc-window')), findsNothing);
      await done(tester);
    });

    testWidgets('a key in use: «Used by», never deleted here; another one deleted after a yes', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const KeychainScreen(poll: false));
      await tap(tester, 'kc-item-v2');
      expect(find.byKey(const Key('kc-used-by')), findsOneWidget);
      expect(find.byKey(const Key('kc-remove')), findsNothing);
      Navigator.of(tester.element(find.byKey(const Key('kc-used-by')))).pop();
      await _settle(tester);
      await tap(tester, 'kc-item-v1');
      await tap(tester, 'kc-remove');
      await tap(tester, 'kc-confirm-yes');
      expect(vault.calls, contains('DELETE /api/vault/v1'));
      expect(find.byKey(const Key('kc-item-v1')), findsNothing);
      await done(tester);
    });

    testWidgets('a new credential: its name from the service, a password made, saved', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const KeychainScreen(poll: false));
      await tap(tester, 'kc-add');
      expect(tester.widget<FilledButton>(find.byKey(const Key('kc-save'))).onPressed, isNull);
      await type(tester, 'kc-service', 'Stripe Live');
      await _settle(tester, 3);
      await tap(tester, 'kc-generate');
      await tap(tester, 'kc-gen-digits');
      final pin = tester.widget<SelectableText>(find.byKey(const Key('kc-gen-out'))).data!;
      expect(RegExp(r'^\d+$').hasMatch(pin), isTrue);
      await tap(tester, 'kc-gen-use');
      await type(tester, 'kc-url', 'https://api.stripe.com/v1');
      await tap(tester, 'kc-cat-login');
      await tap(tester, 'kc-ask-always');
      await tap(tester, 'kc-save');
      final body = vault.bodies['POST /api/vault']! as Map<String, dynamic>;
      expect(body['name'], 'stripe_live');
      expect(body['service'], 'Stripe Live');
      expect(body['value'], pin);
      expect(body['hosts'], ['api.stripe.com']);
      expect(body['category'], 'login');
      expect(body['ask'], 'always');
      expect(body['inject'], {'header': 'Authorization', 'format': 'Bearer {value}'});
      await done(tester);
    });

    testWidgets('importing: a CSV previewed and the rows kept; a sealed file; the export', (
      tester,
    ) async {
      await start(tester);
      var file = ('export.csv', 'name,url,username,password\nGmail,,me,pw');
      String? exported;
      await push(
        tester,
        KeychainScreen(
          poll: false,
          pickFile: () async => file,
          saveFile: (name, text) async {
            exported = '$name|$text';
            return true;
          },
        ),
      );
      await tap(tester, 'kc-import-open');
      await tap(tester, 'kc-import-pick');
      expect(find.byKey(const Key('kc-import-found')), findsOneWidget);
      expect(find.textContaining('3 password'), findsOneWidget);
      await tap(tester, 'kc-import-row-2');
      await tap(tester, 'kc-import-go');
      expect(vault.bodies['POST /api/vault-import/confirm'], {
        'id': 'imp1',
        'keep': [0, 1],
      });
      expect(find.byKey(const Key('kc-imported')), findsOneWidget);
      await tap(tester, 'kc-import-close');
      // A sealed keychain file: its passphrase, a wrong one said in words.
      file = ('k.rgkeychain', 'REDGIANT-KEYCHAIN 1\nsealed');
      await tap(tester, 'kc-import-open');
      await tap(tester, 'kc-import-pick');
      await type(tester, 'kc-import-pass', 'wrong');
      await tap(tester, 'kc-import-go');
      expect(find.text('Wrong passphrase'), findsOneWidget);
      await type(tester, 'kc-import-pass', 'right-pass');
      await tap(tester, 'kc-import-go');
      expect(find.byKey(const Key('kc-imported')), findsOneWidget);
      await tap(tester, 'kc-import-close');
      // The sealed export: the two passphrases must match.
      await tap(tester, 'kc-export-open');
      await type(tester, 'kc-export-a', 'long-passphrase');
      await type(tester, 'kc-export-b', 'long-passphrasX');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('kc-export-go'))).onPressed, isNull);
      await type(tester, 'kc-export-b', 'long-passphrase');
      await tap(tester, 'kc-export-go');
      expect(vault.bodies['POST /api/vault-export'], {'passphrase': 'long-passphrase'});
      expect(exported, startsWith('rasgeth-keychain-'));
      expect(exported, endsWith('.rgkeychain|REDGIANT-KEYCHAIN 1\nsealed-bytes'));
      expect(find.byKey(const Key('kc-exported')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the browsers: a code to link one, one unlinked after a yes', (tester) async {
      await start(tester);
      await push(tester, const KeychainScreen(poll: false));
      await tap(tester, 'kc-link');
      await tap(tester, 'kc-br-firefox');
      expect(find.textContaining('about:debugging'), findsOneWidget);
      await tap(tester, 'kc-br-make');
      expect(find.text('K7Q-4ZP'), findsOneWidget);
      Navigator.of(tester.element(find.byKey(const Key('kc-br-code')))).pop();
      await _settle(tester);
      await tap(tester, 'kc-unlink-b1');
      await tap(tester, 'kc-confirm-yes');
      expect(vault.calls, contains('DELETE /api/vault-browsers/b1'));
      expect(find.byKey(const Key('kc-browser-b1')), findsNothing);
      await done(tester);
    });

    testWidgets('a closed keychain says why; the way in from the settings', (tester) async {
      vault.ready = false;
      await start(tester);
      await push(tester, const ServerSettingsScreen());
      await tap(tester, 'settings-keychain');
      expect(find.byKey(const Key('kc-closed')), findsOneWidget);
      expect(find.text('Its folder is inside a git repository.'), findsOneWidget);
      await done(tester);
    });

    testWidgets('a secret held back in the composer goes into the keychain, then the message', (
      tester,
    ) async {
      final app = await start(tester, size: const Size(390, 2400), live: true);
      await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
      await tester.enterText(
        find.byKey(const Key('composer-text')),
        'usa questa chiave sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789ABCD',
      );
      await tester.tap(find.byKey(const Key('composer-send')));
      await _settle(tester);
      await tap(tester, 'secret-vault');
      expect(find.byKey(const Key('kc-window')), findsOneWidget);
      // The value is there, visible; the person names the service.
      expect(find.text('sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789ABCD'), findsOneWidget);
      await type(tester, 'kc-service', 'Anthropic test');
      await _settle(tester, 3);
      await tap(tester, 'kc-save');
      final body = vault.bodies['POST /api/vault']! as Map<String, dynamic>;
      expect(body['value'], 'sk-ant-api03-abcdefghijklmnopqrstuvwxyz0123456789ABCD');
      expect(body['name'], 'anthropic_test');
      final sent = server.received.lastWhere((m) => m['type'] == 'session.send');
      expect(sent['text'], contains('[secret removed: now in the keychain]'));
      expect(sent['text'], isNot(contains('sk-ant')));
      await done(tester);
    });
  });
}
