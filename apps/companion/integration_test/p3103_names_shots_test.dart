// 3.10.3: Rasgeth's named systems in the app, on Linux against a real Rasgeth (the demo, no real
// model), light and dark: Settings' list (Constellation, Event Horizon), the tree of agents, the
// requests, safety and costs, and the local models (Deep Field, Persistar). Run in the agents'
// Docker with tool/linux_shots.sh, RG_SHOTS the folder for the pictures.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/agents/agent_tree.dart';
import 'package:rgcompanion/settings/models/models_screen.dart';
import 'package:rgcompanion/settings/requests_screen.dart';
import 'package:rgcompanion/settings/safety_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the named systems on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 1500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;

    Future<void> page(String name, Future<void> Function() open, {int wait = 2500}) async {
      unawaited(open());
      await frames(t, wait);
      await shot(t, name);
      nav.pop();
      await frames(t, 600);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-safety')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.ensureVisible(find.byKey(const Key('settings-agents')));
      await frames(t, 600);
      await shot(t, 'app-$theme-01-settings');
      nav.pop();
      await frames(t, 600);
      await page('app-$theme-02-constellation', () => openAgentTree(ctx));
      await page('app-$theme-03-event-horizon-requests', () => openRequestsSettings(ctx));
      await page('app-$theme-04-event-horizon-safety', () => openSafetySettings(ctx));
      unawaited(openModelsSettings(ctx));
      await frames(t, 3000);
      final machine = find.byKey(const Key('lm-machine'));
      final local = find.text('Un modello su questo computer');
      if (machine.evaluate().isEmpty && local.evaluate().isNotEmpty) {
        await t.tap(local.first);
        await frames(t, 3000);
      }
      if (machine.evaluate().isNotEmpty) {
        await t.ensureVisible(machine);
        await frames(t, 800);
      }
      await shot(t, 'app-$theme-05-deep-field-persistar');
      nav.pop();
      await frames(t, 600);
    }
  });
}
