// 3.8.11: a widget in the chat on Linux (WebKitGTK), against a real Rasgeth (the demo with
// DEMO_ARTIFACTS=1: God's humidity widget). The frame must show the widget's content, not an empty
// box. Run in the agents' Docker with tool/linux_shots.sh (RG_DEMO_ENV with DEMO_ARTIFACTS=1),
// RG_SHOTS the folder for the pictures (the X screen, so the native web view is in them).
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
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _log = Platform.environment['RG_DEMO_LOG'] ?? '/tmp/demo.log';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

Map<String, dynamic> _demo() {
  for (final line in File(_log).readAsLinesSync().reversed) {
    if (!line.startsWith('{')) continue;
    final j = jsonDecode(line);
    if (j is Map<String, dynamic> && j.containsKey('widgetSession')) return j;
  }
  throw StateError('the demo did not say its sessions (DEMO_ARTIFACTS=1?)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a widget in the chat on Linux shows its content', (t) async {
    final demo = _demo();
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final god = app.agents.firstWhere((a) => a.id == demo['god']);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  ConversationScreen(sessionId: demo['widgetSession'] as String, agent: god),
            ),
          )
          .ignore();
      await waitFor(t, () => find.byKey(const Key('artifact-frame-view')).evaluate().isNotEmpty);
      // The widget tells its height once drawn: the frame grows past its first 48 px.
      await waitFor(
        t,
        () => t.getSize(find.byKey(const Key('artifact-frame-view'))).height > 60,
        seconds: 20,
      );
      debugPrint('frame height: ${t.getSize(find.byKey(const Key('artifact-frame-view'))).height}');
      await shot(t, 'g3811-widget-linux-$_tag-$theme', wait: 4000);
      nav.pop();
      await frames(t, 800);
    }
  });
}
