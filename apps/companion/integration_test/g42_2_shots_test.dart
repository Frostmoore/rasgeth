// G42.2: boards, an agent's port, Settings › Artifacts and a widget with its slider, on Linux
// (WebKitGTK) against a real RedGiant (the demo with DEMO_ARTIFACTS=1 DEMO_PORT=1), light and dark.
// Run in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for the phone's size), RG_SHOTS the
// folder for the pictures, RG_DEMO_LOG the demo's output (its session ids).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_screen.dart';
import 'package:rgcompanion/screens/artifacts_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';
final _log = Platform.environment['RG_DEMO_LOG'] ?? '/tmp/demo.log';
const _board = '0a1b2c3d4e5f';

Map<String, dynamic> _demo() {
  final out = <String, dynamic>{};
  for (final line in File(_log).readAsLinesSync()) {
    if (!line.startsWith('{')) continue;
    final j = jsonDecode(line);
    if (j is Map<String, dynamic>) out.addAll(j);
  }
  if (!out.containsKey('demoPort') || !out.containsKey('widgetSession')) {
    throw StateError('the demo did not say its sessions (DEMO_ARTIFACTS=1 DEMO_PORT=1?)');
  }
  return out;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boards, ports, artifacts and widgets on Linux', (t) async {
    final demo = _demo();
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final c = app.client!;
    final god = app.agents.firstWhere((a) => a.id == demo['god']);
    // The conversation that holds the board.
    String? boardSession;
    await t.runAsync(() async {
      for (final s in await c.sessions(agentId: god.id)) {
        final events = await c.sessionEvents(s.id);
        if (events.any(
          (e) =>
              e['type'] == 'variants.proposed' &&
              (e['payload'] as Map<String, dynamic>?)?['proposalId'] == _board,
        )) {
          boardSession = s.id;
          break;
        }
      }
    });
    if (boardSession == null) throw StateError('no board in the demo');
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);

      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: boardSession!, agent: god),
            ),
          )
          .ignore();
      await waitFor(t, () => find.byKey(const Key('variants-$_board')).evaluate().isNotEmpty);
      await shot(t, 'g42-2-chat-tavola-$_tag-$theme', wait: 1500);
      await t.tap(find.text("The site's home page").last);
      await waitFor(t, () => find.byKey(const Key('board-variant-1')).evaluate().isNotEmpty);
      await shot(t, 'g42-2-tavola-$_tag-$theme', wait: 12000);
      await t.tap(find.byKey(const Key('board-screen-phone')));
      await shot(t, 'g42-2-tavola-telefono-$_tag-$theme', wait: 9000);
      await t.tap(find.byKey(const Key('board-full-1')));
      await shot(t, 'g42-2-tavola-intera-$_tag-$theme', wait: 9000);
      await t.tap(find.byKey(const Key('board-full-close')));
      await frames(t, 800);
      nav.pop();
      await frames(t, 600);
      nav.pop();
      await frames(t, 800);

      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ConversationScreen(sessionId: demo['demoPortSession'] as String, agent: god),
            ),
          )
          .ignore();
      final line = find.textContaining('Prenotazioni');
      await waitFor(t, () => line.evaluate().isNotEmpty);
      await shot(t, 'g42-2-chat-porta-$_tag-$theme', wait: 1200);
      await t.tap(line.last);
      await waitFor(t, () => find.byType(EmbedScreen).evaluate().isNotEmpty);
      await shot(t, 'g42-2-porta-$_tag-$theme', wait: 9000);
      nav.pop();
      await frames(t, 600);
      nav.pop();
      await frames(t, 800);

      nav.push(MaterialPageRoute<void>(builder: (_) => const ArtifactsScreen())).ignore();
      await waitFor(t, () => find.textContaining('Calcolo preventivi').evaluate().isNotEmpty);
      await shot(t, 'g42-2-artefatti-$_tag-$theme', wait: 1500);
      nav.pop();
      await frames(t, 800);

      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ConversationScreen(sessionId: demo['widgetSession'] as String, agent: god),
            ),
          )
          .ignore();
      await shot(t, 'g42-2-widget-$_tag-$theme', wait: 12000);
      nav.pop();
      await frames(t, 800);
    }
  });
}
