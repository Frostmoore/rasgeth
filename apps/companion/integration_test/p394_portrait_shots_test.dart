// 3.9.4 in the real app on Linux, against the demo server with its portrait (six traits learned
// from a conversation, one written by hand, one said not true), light and dark: the way in from
// Settings, Settings › Portrait (the switch, who reads it, the traits grouped), «Where it comes
// from», «Change» with its category, and the text the agents read.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1":
//   RG_SCREEN=390x844 … integration_test/p394_portrait_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/p394_portrait_shots_test.dart
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
import 'package:rgcompanion/settings/portrait_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.9.4: the portrait', (t) async {
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
                of: find.byKey(const Key('portrait-settings')),
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
        find.byKey(const Key('settings-portrait')),
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

      unawaited(openPortrait(ctx));
      await frames(t, 3000);
      await shot(t, '02_ritratto_$tag');
      await scrollTo(const Key('portrait-trait-pt1'));
      await shot(t, '03_tratti_$tag');
      await tap(const Key('portrait-where-pt1'), 1200);
      await shot(t, '04_da_dove_viene_$tag');
      Navigator.of(t.element(find.byKey(const Key('portrait-sources')))).pop();
      await frames(t, 800);
      await tap(const Key('portrait-edit-pt1'), 1200);
      await shot(t, '05_cambia_$tag');
      Navigator.of(t.element(find.byKey(const Key('portrait-edit-field')))).pop();
      await frames(t, 800);
      await tap(const Key('portrait-text-toggle'), 1000);
      await scrollTo(const Key('portrait-text'));
      await shot(t, '06_testo_agenti_$tag');
      back();
      await frames(t, 800);
    }
  });
}
