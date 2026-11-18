// 3.8.9 in the real app on Linux against the demo server (a real Rasgeth, FakeProvider): «Stop…»
// is a pause (our dialog says the open tasks wait), a stopped agent's menu says «Resume», its
// settings and its conversations too; «Remove…» stays another thing. Light and dark. Run by
// tool/linux_shots.sh:
//   RG_SCREEN=1440x900 … integration_test/g389_pause_shots_test.dart
import 'dart:io';

import 'package:flutter/gestures.dart';
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1200]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  testWidgets('3.8.9: stop is a pause, resume brings it back', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 4000);
    final a = app.agents.firstWhere((x) => x.kind == AgentKind.agent && x.active);
    Future<void> menu() async {
      await t.tap(find.byKey(Key('tile-${a.id}')), buttons: kSecondaryButton);
      await frames(t, 800);
    }

    for (final theme in ['chiaro', 'scuro']) {
      app.setThemeMode(theme == 'chiaro' ? ThemeMode.light : ThemeMode.dark);
      await frames(t, 1200);
      await menu();
      await shot(t, 'app-$theme-01-menu-ferma-rimuovi');
      await tap(t, find.byKey(const Key('agent-menu-pause')));
      await shot(t, 'app-$theme-02-conferma-pausa');
      await tap(t, find.byKey(const Key('dialog-yes')), 2500);
      await waitFor(t, () => app.agents.any((x) => x.id == a.id && !x.active));
      await frames(t, 1500);
      await menu();
      await shot(t, 'app-$theme-03-menu-riattiva');
      await tap(t, find.byKey(const Key('agent-menu-settings')), 2000);
      await shot(t, 'app-$theme-04-impostazioni-riattiva');
      await tap(t, find.byKey(const Key('as-resume')), 2500);
      await waitFor(t, () => app.agents.any((x) => x.id == a.id && x.active));
      await frames(t, 1500);
      await shot(t, 'app-$theme-05-riattivato');
      await tap(t, find.byKey(const Key('agent-settings-close')), 1200);
      await menu();
      await tap(t, find.byKey(const Key('agent-menu-remove')), 2000);
      await shot(t, 'app-$theme-06-conferma-rimozione');
      await tap(t, find.byKey(const Key('dialog-no')), 1000);
    }
  });
}
