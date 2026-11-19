// 3.9.4: a sub-agent has no mascot of its own (decision of 2026-11-19), it shows the ring in its
// parent's colour: the team's tree and the Coder's conversation with its two sub-agents' tabs (one
// finished, one waiting for the person's yes), light and dark, in the real app against a real
// Rasgeth (the demo server, FakeProvider). Run by tool/linux_shots.sh with
//   RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_SUBSIGN=1" … \
//     integration_test/g394_subsign_shots_test.dart
// (RG_SCREEN=430x900 for a phone; RG_SHOT_PREFIX names the files).
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
import 'package:rgcompanion/mascot/subagent_sign.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _prefix = Platform.environment['RG_SHOT_PREFIX'] ?? 'g394';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("the sub-agents' sign in the tree and the tabs", (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    // A computer-sized window opens the control room, already on the connection form.
    final desk = find.byKey(const Key('tab-you')).evaluate().isEmpty;
    if (!desk) {
      await t.tap(find.byKey(const Key('tab-you')));
      await frames(t);
    }
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.agents.where((a) => a.kind == AgentKind.subagent).length >= 2);
    if (desk) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        app.setThemeMode(mode);
        await frames(t, 2500);
        await shot(t, '$_prefix-${mode.name}-01-room');
        final coder = app.agents.firstWhere((a) => a.name == 'Coder');
        final tile = find.byKey(Key('tile-${coder.id}'));
        await t.ensureVisible(tile);
        await t.tap(tile);
        await waitFor(t, () => find.text('Pagina prodotto').evaluate().isNotEmpty);
        await frames(t, 800);
        await t.tap(find.text('Pagina prodotto').first);
        await waitFor(t, () => find.byType(SubagentSign).evaluate().isNotEmpty);
        await frames(t, 2500);
        await shot(t, '$_prefix-${mode.name}-02-conversation');
        final tabs = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('sub-tab-'),
        );
        if (tabs.evaluate().length > 1) {
          await t.tap(tabs.at(1));
          await frames(t, 2500);
          await shot(t, '$_prefix-${mode.name}-03-subagent-tab');
        }
        debugPrint('TOUR desk ${mode.name}: ${find.byType(SubagentSign).evaluate().length} signs');
      }
      return;
    }
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      app.setThemeMode(mode);
      await t.tap(find.byKey(const Key('tab-team')));
      await frames(t, 1500);
      await t.tap(find.byKey(const Key('team-tree')));
      await frames(t, 2000);
      final signs = find.byType(SubagentSign).evaluate().length;
      debugPrint('TOUR tree ${mode.name}: $signs signs');
      await shot(t, '$_prefix-${mode.name}-01-tree');
      // The tree's own arrow is not the standard back button.
      await t.state<NavigatorState>(find.byType(Navigator).last).maybePop();
      await frames(t, 1200);
      final coder = app.agents.firstWhere((a) => a.name == 'Coder');
      await t.tap(find.text('Coder').first);
      await waitFor(t, () => find.text('Pagina prodotto').evaluate().isNotEmpty);
      await frames(t, 800);
      await t.tap(find.text('Pagina prodotto').first);
      await waitFor(t, () => find.byType(SubagentSign).evaluate().isNotEmpty);
      await frames(t, 2500);
      debugPrint('TOUR conversation of ${coder.id} ${mode.name}');
      await shot(t, '$_prefix-${mode.name}-02-conversation');
      // The waiting sub-agent's tab opened.
      final waiting = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('sub-tab-'),
      );
      if (waiting.evaluate().length > 1) {
        await t.tap(waiting.at(1));
        await frames(t, 2500);
        await shot(t, '$_prefix-${mode.name}-03-subagent-tab');
      }
      await t.tap(find.byKey(const Key('conversation-back')));
      await frames(t, 1200);
      await t.tap(find.byKey(const Key('agent-convs-back')));
      await frames(t, 1200);
    }
  });
}
