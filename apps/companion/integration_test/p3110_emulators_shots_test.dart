// 3.11 phase 1 in the real app on Linux, against the demo server (FakeProvider; DEMO_EMULATORS=1:
// a Windows machine's report with an SDK found through Android Studio's settings, an old emulator,
// two virtual devices, one running, a phone over USB and one over Wi-Fi waiting for its yes; never
// a real emulator), light and dark: Settings with the Emulators row, then Settings › Emulators.
// Run by tool/linux_shots.sh with
//   RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_EMULATORS=1"
//   RG_SCREEN=390x844 … integration_test/p3110_emulators_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/p3110_emulators_shots_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart' show DevicePlatform;
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/system/emulators_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.11: Settings › Emulators', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final p = _phone ? 'telefono' : 'computer';
    // Whatever window opened by itself (what's new, an update) closes first.
    while (nav.canPop()) {
      nav.pop();
      await frames(t, 600);
    }

    Future<void> scrollTo(Key list, Key key) async {
      if (find.byKey(key).evaluate().isEmpty) {
        await t.scrollUntilVisible(
          find.byKey(key),
          250,
          scrollable: find
              .descendant(of: find.byKey(list), matching: find.byType(Scrollable))
              .first,
        );
      }
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 500);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await scrollTo(const Key('server-settings'), const Key('settings-emulators'));
      await shot(t, '01_impostazioni_emulatori_$tag');
      nav.pop();
      await frames(t, 600);

      const list = Key('sy-emulators-list');
      unawaited(openEmulatorsSettings(ctx));
      await frames(t, 3000);
      await shot(t, '02_emulatori_$tag');
      await scrollTo(list, const Key('sy-em-again'));
      await shot(t, '03_emulatori_accesi_$tag');
      await scrollTo(list, const Key('sy-em-max-2'));
      await shot(t, '04_emulatori_cartella_$tag');
      nav.pop();
      await frames(t, 800);
    }
  });
}
