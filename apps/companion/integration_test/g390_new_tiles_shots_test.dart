// 3.9.0 in the real app on Linux: «New agent» and «New project» as the last tiles of their walls,
// against the demo server (a project really made, with its orchestrator), and the empty walls
// against the tests' fake Rasgeth (no agents, no projects). Run by tool/linux_shots.sh:
//   RG_SCREEN=1440x900 … integration_test/g390_new_tiles_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1500]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  Future<AppController> connect(WidgetTester t, String url, String password) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), url);
    await t.enterText(find.byKey(const Key('server-password')), password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t, 4000);
    return app;
  }

  testWidgets('3.9.0: the new tiles, with agents and projects', (t) async {
    final app = await connect(t, _url, _password);
    // The squad: «New agent» right after the last agent.
    await shot(t, 'g390-01-agenti-tessera', wait: 2500);
    await t.ensureVisible(find.byKey(const Key('desk-new-agent')));
    await shot(t, 'g390-01b-agenti-tessera-in-fondo', wait: 1500);
    // Projects: «New project» after the last project; the dialog; the project made.
    await tap(t, find.byKey(const Key('view-projects')), 2500);
    await shot(t, 'g390-02-progetti-tessera', wait: 1500);
    await tap(t, find.byKey(const Key('desk-new-project')));
    await t.enterText(find.byKey(const Key('new-project-name')), 'Orto');
    await shot(t, 'g390-03-nuovo-progetto-nome');
    await tap(t, find.byKey(const Key('dialog-yes')), 600);
    await waitFor(t, () => app.projects.any((p) => p.name == 'Orto'));
    await shot(t, 'g390-04-progetto-creato', wait: 1500);
    // The advanced projects' wall keeps it last too.
    app.setAdvanced(true);
    await frames(t, 2500);
    await shot(t, 'g390-05-progetti-avanzata');
    app.setAdvanced(false);
    await frames(t, 800);
    // Dark theme, the squad again.
    app.setThemeMode(ThemeMode.dark);
    await tap(t, find.byKey(const Key('view-team')), 2000);
    await shot(t, 'g390-06-agenti-scuro', wait: 1500);
    app.setThemeMode(ThemeMode.light);
  });

  testWidgets('3.9.0: the new tiles on empty walls', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    fake
      ..onlyLeaders = true
      ..noProjects = true;
    await connect(t, fake.base.toString(), 'secret');
    await shot(t, 'g390-07-nessun-agente', wait: 2000);
    await tap(t, find.byKey(const Key('view-projects')), 2500);
    await shot(t, 'g390-08-nessun-progetto', wait: 1500);
  });
}
