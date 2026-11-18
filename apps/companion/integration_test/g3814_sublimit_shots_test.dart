// 2026-11-18 in the real app on Linux against the demo server (a real RedGiant, FakeProvider): a
// project's agent limit. The project's sheet says «Agenti al massimo: N», its window has the
// slider; lowered under the team, the line says nobody is removed; the project's view has the same
// slider by its team. Light and dark, on a phone. Run by tool/linux_shots.sh:
//   RG_SCREEN=430x932 … integration_test/g3814_sublimit_shots_test.dart
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

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1200]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  testWidgets('2026-11-18: a project\'s agent limit', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 4000);
    final project = app.projects.first;
    final key = Key('agent-limit-slider-${project.id}');
    Future<void> setTo(int n) async {
      final s = t.widget<Slider>(find.byKey(key).first);
      s.onChanged!(n.toDouble());
      await frames(t, 300);
      t.widget<Slider>(find.byKey(key).first).onChangeEnd!(n.toDouble());
      await frames(t, 2000);
    }

    for (final theme in (Platform.environment['RG_THEME'] ?? 'chiaro scuro').split(' ')) {
      app.setThemeMode(theme == 'chiaro' ? ThemeMode.light : ThemeMode.dark);
      await frames(t, 1500);
      String n(int i, String what) => 'app-$theme-${i.toString().padLeft(2, '0')}-$what';
      app.setAdvanced(true);
      app.setTab(AppTab.projects);
      await frames(t, 2500);
      for (var i = 0; i < 3 && find.byKey(const Key('proj-menu-limit')).evaluate().isEmpty; i++) {
        await t.longPress(find.byKey(Key('project-${project.id}')));
        await frames(t, 1500);
      }
      await shot(t, n(1, 'menu-progetto'));
      await tap(t, find.byKey(const Key('proj-menu-limit')), 1500);
      await shot(t, n(2, 'finestra-limite'));
      await setTo(0);
      await shot(t, n(3, 'solo-orchestratore'));
      await setTo(3);
      await tap(t, find.byKey(const Key('agent-limit-close')).first);
      // The card's tap opens the project (as the sheet's «Open»).
      await tap(t, find.byKey(Key('project-${project.id}')).first, 2500);
      await shot(t, n(4, 'vista-progetto'));
      // The slider sits by the team, under the lead's conversations.
      final tile = find.byKey(Key('agent-limit-${project.id}'));
      final view = find.byKey(Key('proj-overview-${project.id}'));
      for (var i = 0; i < 12 && tile.evaluate().isEmpty; i++) {
        await t.drag(view.first, const Offset(0, -300));
        await frames(t, 300);
      }
      if (tile.evaluate().isNotEmpty) await t.ensureVisible(tile.first);
      await frames(t, 800);
      await shot(t, n(5, 'vista-progetto-limite'));
      await tap(t, find.byKey(const Key('proj-back')));
      app.setAdvanced(false);
      await frames(t, 1000);
    }
  });
}
