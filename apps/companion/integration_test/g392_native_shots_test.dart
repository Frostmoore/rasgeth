// 3.9.2: the model's own generation, on Linux against a real Rasgeth (the demo with
// DEMO_NATIVE=1: an agent on a Codex stand-in that draws by itself). The picture in place in the
// chat, the «generating a picture» card, a picture by a path and one that cannot be read, and the
// setting in Settings › General › Pictures. RG_SHOT_TAG names the size (computer, phone:
// RG_SCREEN=390x844), RG_SHOTS the folder for the pictures.
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
import 'package:rgcompanion/settings/general_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _log = Platform.environment['RG_DEMO_LOG'] ?? '/tmp/demo.log';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

Map<String, dynamic> _sessions() {
  for (final line in File(_log).readAsLinesSync().reversed) {
    if (!line.startsWith('{')) continue;
    final j = jsonDecode(line);
    if (j is Map<String, dynamic> && j.containsKey('nativeSessions')) {
      return j['nativeSessions'] as Map<String, dynamic>;
    }
  }
  throw StateError('the demo did not say its native conversations (DEMO_NATIVE=1)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the model\'s own pictures in the chat, and the setting', (t) async {
    final s = _sessions();
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final agent = app.agents.firstWhere((a) => a.name == 'Grafica');
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    Future<void> open(String id) async {
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: id, agent: agent),
            ),
          )
          .ignore();
      await frames(t, 600);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final p = 'app-$_tag-$theme';

      await open(s['done'] as String);
      await waitFor(t, () => find.byType(Image).evaluate().isNotEmpty);
      await shot(t, '$p-01-immagine-in-chat', wait: 1500);
      nav.pop();
      await frames(t, 600);

      await open(s['slow'] as String);
      await waitFor(t, () => find.byKey(const Key('generating')).evaluate().isNotEmpty);
      await shot(t, '$p-03-sta-generando', wait: 900);
      nav.pop();
      await frames(t, 600);

      await open(s['path'] as String);
      final bad = find.byKey(const Key('chat-image-bad'));
      await waitFor(t, () => bad.evaluate().isNotEmpty);
      await t.ensureVisible(bad);
      await shot(t, '$p-04-non-disponibile', wait: 900);
      nav.pop();
      await frames(t, 600);

      nav
          .push(MaterialPageRoute<void>(builder: (_) => const GeneralSettingsScreen()))
          .ignore();
      final tile = find.byKey(const Key('general-tile-images'));
      await waitFor(t, () => find.text('Come vuoi Rasgeth?').evaluate().isNotEmpty);
      await frames(t, 600);
      // The list builds what is near: scrolled down to the pictures' square.
      if (tile.evaluate().isEmpty) {
        await t.scrollUntilVisible(tile, 250, scrollable: find.byType(Scrollable).last);
      }
      await t.ensureVisible(tile);
      await frames(t, 400);
      await t.tap(tile);
      final row = find.byKey(const Key('media-native-switch'));
      await waitFor(t, () => row.evaluate().isNotEmpty);
      await shot(t, '$p-05-impostazione', wait: 1200);
      // The panel closes (a sheet or a window), then the screen.
      nav.popUntil((r) => r.isFirst);
      await frames(t, 800);
    }
  });
}
