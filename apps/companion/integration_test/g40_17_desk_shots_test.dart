// G40.17 in the real app on Linux against a real RedGiant (the demo server, FakeProvider): the
// computers' control room. Run by tool/linux_shots.sh with a computer's window:
//   RG_SCREEN=1440x900 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_CODE=1 DEMO_REQUESTS=1 \
//     DEMO_CRITICAL=1" … integration_test/g40_17_desk_shots_test.dart
// and RG_SCREEN=1024x700 for the small window (prefix g4017-1024).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
final _screen = Platform.environment['RGCOMPANION_WINDOW'] ?? '1440x900';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1500]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  Future<void> keys(WidgetTester t, List<LogicalKeyboardKey> mods, LogicalKeyboardKey key) async {
    for (final m in mods) {
      await t.sendKeyDownEvent(m);
    }
    await t.sendKeyEvent(key);
    for (final m in mods.reversed) {
      await t.sendKeyUpEvent(m);
    }
    await frames(t, 900);
  }

  const ctrl = LogicalKeyboardKey.controlLeft;

  testWidgets('G40.17: the control room', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    final small = _screen.startsWith('1024');
    final p = small ? 'g4017-1024' : 'g4017';
    // Not connected yet: the room shows where to connect.
    await shot(t, '$p-00-da-collegare');
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t, 4000);

    // ---- The squad's wall ----
    await shot(t, '$p-01-sala', wait: 2500);
    final coder = app.agents.firstWhere(
      (a) => a.projectId == 'demo' && a.kind == AgentKind.agent,
      orElse: () => app.agents.firstWhere((a) => a.projectId != null),
    );
    // 3.8.8: the tile shows the agent's conversations; a new one opens in the panel.
    await tap(t, find.byKey(Key('tile-${coder.id}')), 2000);
    await tap(t, find.byKey(const Key('agent-conv-new')), 3000);
    await shot(t, '$p-02-pannello-conversazione');

    // ---- The palette ----
    await keys(t, [ctrl], LogicalKeyboardKey.keyK);
    await t.enterText(find.byKey(const Key('palette-field')), coder.name.substring(0, 3));
    await shot(t, '$p-03-palette', wait: 1500);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(t, 600);

    // ---- The quick Chat ----
    await keys(t, [ctrl, LogicalKeyboardKey.shiftLeft], LogicalKeyboardKey.space);
    await frames(t, 2500);
    await shot(t, '$p-04-chat-rapida');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(t, 800);

    // ---- A floating panel ----
    await tap(t, find.byKey(const Key('panel-detach')), 1500);
    await shot(t, '$p-05-pannello-staccato');
    await tap(t, find.byKey(const Key('menu-Finestra')), 600);
    await tap(t, find.byKey(const Key('menuitem-dock-all')), 1200);

    // ---- The bell's drop-down (3.8.8, «For you» left the wall), the menus ----
    await tap(t, find.byKey(const Key('desk-bell')), 2000);
    await shot(t, '$p-06-da-te');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(t, 500);
    await tap(t, find.byKey(const Key('menu-Vista')), 800);
    await shot(t, '$p-07-menu-vista', wait: 400);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(t, 500);

    // ---- Dark ----
    app.setThemeMode(ThemeMode.dark);
    await frames(t, 1200);
    await shot(t, '$p-08-sala-scura');
    await tap(t, find.byKey(const Key('view-projects')), 2500);
    await shot(t, '$p-09-progetti-scuro');
    app.setThemeMode(ThemeMode.light);
    await frames(t, 800);

    // ---- The advanced interface ----
    app.setAdvanced(true);
    await frames(t, 5000);
    await shot(t, '$p-10-avanzata-progetti', wait: 2500);
    await tap(t, find.byKey(const Key('project-tile-demo')), 5000);
    await shot(t, '$p-11-codice-diff');
    await tap(t, find.byKey(const Key('diff-mode-1')), 1200);
    await shot(t, '$p-12-codice-in-linea');
    await tap(t, find.byKey(const Key('view-terminals')), 5000);
    await shot(t, '$p-13-terminali', wait: 2500);
    await tap(t, find.byKey(const Key('view-git')), 4000);
    await shot(t, '$p-14-git');
    await tap(t, find.byKey(const Key('view-log')), 4000);
    await shot(t, '$p-15-log');
    await t.enterText(find.byKey(const Key('log-search')), 'tipo:tool.*');
    await frames(t, 800);
    final row = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          RegExp(r'^log-row-\d+$').hasMatch((w.key! as ValueKey<String>).value),
    );
    if (row.evaluate().isNotEmpty) await tap(t, row.first, 1200);
    await shot(t, '$p-16-log-evento');
    await keys(t, [ctrl], LogicalKeyboardKey.keyK);
    await t.enterText(find.byKey(const Key('palette-field')), '! git status');
    await shot(t, '$p-17-palette-avanzata', wait: 1500);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await frames(t, 5000);
    await shot(t, '$p-18-terminale-mio');
    app.setThemeMode(ThemeMode.dark);
    await tap(t, find.byKey(const Key('view-code')), 4000);
    await shot(t, '$p-19-codice-scuro');
  });
}
