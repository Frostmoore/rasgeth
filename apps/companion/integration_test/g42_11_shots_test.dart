// G42.11 in the real app on Linux, against the demo server (DEMO_MAGIC=1: God's packages for the
// magic integrations and extensions; the demo's own proposals, a server that signs in, installed
// skills), light and dark: «Settings of <name>» with the new row, Settings › Extensions from the
// top down (magic, what waits, services, generation, catalog, installed, made by hand), an agent's
// new version of a skill, a catalog entry with its key, a kind of generation, a magic package
// beside its conversation, and a skill's .zip import.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_MAGIC=1":
//   RG_SCREEN=390x844 … integration_test/g42_11_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_11_shots_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/extensions/extensions_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.11: extensions', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2000);
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
                of: find.byKey(const Key('extensions-settings')),
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
        find.byKey(const Key('settings-extensions')),
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

      unawaited(openExtensionsSettings(ctx));
      await frames(t, 3500);
      await shot(t, '02_estensioni_magia_$tag');
      final pending = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('xt-prop-'),
      );
      if (pending.evaluate().isNotEmpty) {
        await t.ensureVisible(pending.first);
        await frames(t, 500);
        await shot(t, '03_estensioni_proposte_$tag');
        await t.tap(pending.last);
        await frames(t, 2000);
        await shot(t, '04_proposta_$tag');
        back();
        await frames(t, 800);
      }
      await scrollTo(const Key('xt-media'));
      await shot(t, '05_servizi_generazione_$tag');
      await tap(const Key('xt-media-tile-image'), 2500);
      await shot(t, '06_generazione_immagini_$tag');
      back();
      await frames(t, 800);
      await scrollTo(const Key('xt-catalog'));
      await shot(t, '07_catalogo_$tag');
      await tap(const Key('xt-cat-entry-github'), 2000);
      await shot(t, '08_catalogo_github_$tag');
      back();
      await frames(t, 800);
      await scrollTo(const Key('xt-own-import'));
      await shot(t, '09_installate_a_mano_$tag');
      await tap(const Key('xt-own-import'), 1500);
      await shot(t, '10_importa_skill_$tag');
      back();
      await frames(t, 800);
      // A magic package beside its conversation.
      t
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const Key('extensions-settings')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await frames(t, 600);
      final magic = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('xt-magic-mx'),
      );
      if (magic.evaluate().isNotEmpty) {
        await t.ensureVisible(magic.first);
        await frames(t, 400);
        await t.tap(magic.first);
        await frames(t, 4000);
        await shot(t, '11_magia_pacchetto_$tag');
        back();
        await frames(t, 800);
      }
      back();
      await frames(t, 800);
    }
  });
}
