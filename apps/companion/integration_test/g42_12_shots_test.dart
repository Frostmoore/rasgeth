// G42.12 in the real app on Linux, against the demo server: two credentials are added through the
// server's own route first (a bank's key with its address, an expiring login), then, light and
// dark: «Settings of <name>» with the new row, Settings › Keychain from the top down (how it is
// sealed, what expires, the list, the keys kept elsewhere, the uses, the browsers, import and
// export), a credential's window, a new one with the generator, the import window and the window
// that links a browser with its code.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1":
//   RG_SCREEN=390x844 … integration_test/g42_12_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_12_shots_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/api/keychain_api.dart';
import 'package:rgcompanion/settings/vault/keychain_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

Map<String, dynamic> _entry(
  String name,
  String service,
  String category,
  String url, {
  String? expires,
}) => {
  'name': name,
  'service': service,
  'category': category,
  'tags': ['lavoro'],
  'username': 'ufficio@example.com',
  'value': 'demo-value-$name-0123456789',
  'url': url,
  'hosts': [Uri.parse(url).host],
  'notes': '',
  'expires': expires,
  'ask': 'session',
  'allow': {
    'allAgents': true,
    'agents': <String>[],
    'tools': <String>[],
    'automations': <String>[],
  },
  'inject': {'header': 'Authorization', 'format': 'Bearer {value}'},
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.12: keychain', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2000);
    await t.runAsync(() async {
      final c = app.client!;
      for (final e in [
        _entry('revolut_api', 'Revolut Business', 'bank', 'https://b2b.revolut.com/api/1.0'),
        _entry(
          'gestionale',
          'Gestionale dello studio',
          'login',
          'https://gestionale.example.com',
          expires: DateTime.now().add(const Duration(days: 12)).toUtc().toIso8601String(),
        ),
      ]) {
        try {
          await c.addVault(e);
        } on ApiException {
          // Already there from the other screen's run.
        }
      }
    });
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final p = _phone ? 'telefono' : 'computer';

    Future<void> scrollTo(Key key) async {
      if (find.byKey(key).evaluate().isEmpty) {
        await t.scrollUntilVisible(
          find.byKey(key),
          250,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('keychain-settings')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 500);
    }

    Future<void> tap(Key key, [int ms = 1500]) async {
      await scrollTo(key);
      await t.tap(find.byKey(key).first);
      await frames(t, ms);
    }

    void back() => nav.pop();

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-keychain')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await shot(t, '01_impostazioni_$tag');
      back();
      await frames(t, 600);

      unawaited(openKeychainSettings(ctx));
      await frames(t, 3000);
      await shot(t, '02_portachiavi_$tag');
      await scrollTo(const Key('kc-filter-all'));
      await shot(t, '03_portachiavi_elenco_$tag');
      await scrollTo(const Key('kc-browsers'));
      await shot(t, '04_portachiavi_usi_browser_$tag');
      await scrollTo(const Key('kc-import-open'));
      await shot(t, '05_portachiavi_porta_$tag');
      // Back to the top, where the list and «Add» are.
      t
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const Key('keychain-settings')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await frames(t, 600);
      // A credential's window.
      final item = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('kc-item-') &&
            !(w.key! as ValueKey<String>).value.startsWith('kc-item-used-by-'),
      );
      if (item.evaluate().isNotEmpty) {
        await t.ensureVisible(item.first);
        await frames(t, 400);
        await t.tap(item.first);
        await frames(t, 2000);
        await shot(t, '06_credenziale_$tag');
        back();
        await frames(t, 800);
      }
      // A new one with the generator, from the top again.
      t
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const Key('keychain-settings')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await frames(t, 600);
      await tap(const Key('kc-add'), 1500);
      await t.enterText(find.byKey(const Key('kc-service')), 'Stripe');
      await frames(t, 300);
      await t.ensureVisible(find.byKey(const Key('kc-generate')));
      await t.tap(find.byKey(const Key('kc-generate')));
      await frames(t, 800);
      await t.ensureVisible(find.byKey(const Key('kc-generator')));
      await frames(t, 400);
      await shot(t, '07_nuova_generatore_$tag');
      back();
      await frames(t, 800);
      await tap(const Key('kc-import-open'), 1500);
      await shot(t, '08_importa_$tag');
      back();
      await frames(t, 800);
      await tap(const Key('kc-link'), 1500);
      await t.tap(find.byKey(const Key('kc-br-make')));
      await frames(t, 2000);
      await shot(t, '09_collega_browser_$tag');
      back();
      await frames(t, 800);
      back();
      await frames(t, 800);
    }
  });
}
