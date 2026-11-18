// Plan 3.9.0 (N2/N5, block 3) in the real app on Linux against the demo server: the app says
// Rasgeth. The one-time notice of the new name over the team, the team without it, You with its
// sections and the first steps without a server; light and dark, it and en. On a phone-sized
// window and on a computer's (RG_SCREEN), named by RG_SHOT_TAG. Run by tool/linux_shots.sh:
//   RG_SCREEN=430x932 RG_SHOT_TAG=telefono … integration_test/rasgeth_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'telefono';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.9.0: Rasgeth in the app', (t) async {
    final fresh = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(fresh.restore);
    await t.pumpWidget(RGCompanionApp(controller: fresh));
    await frames(t, 2500);
    await shot(t, '$_tag-chiaro-00-primi-passi');

    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 3000);
    for (final lang in ['it', 'en']) {
      app.setLocale(Locale(lang));
      for (final theme in ['chiaro', 'scuro']) {
        app.renameDue = true;
        app.setThemeMode(theme == 'chiaro' ? ThemeMode.light : ThemeMode.dark);
        app.setTab(AppTab.team);
        await frames(t, 2500);
        String n(int i, String what) => '$_tag-$theme-$lang-${i.toString().padLeft(2, '0')}-$what';
        await shot(t, n(1, 'avviso-nome'));
        app.dismissRenameNotice();
        await frames(t, 1500);
        await shot(t, n(2, 'squadra'));
        app.setTab(AppTab.you);
        await frames(t, 2000);
        await shot(t, n(3, 'tu'));
      }
    }
  });
}
