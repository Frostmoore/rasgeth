// 3.8.11: «Download» on the files an agent sent, on Linux against a real RedGiant (the demo, whose
// God showed a picture and a document: its `filesSession`). The system's «Save as» is a stand-in
// here (Xvfb has no portal); the card, then «Saved». RG_SHOT_TAG names the size (computer, phone:
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
import 'package:rgcompanion/ui/chat/file_download.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _log = Platform.environment['RG_DEMO_LOG'] ?? '/tmp/demo.log';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

Map<String, dynamic> _demo() {
  for (final line in File(_log).readAsLinesSync().reversed) {
    if (!line.startsWith('{')) continue;
    final j = jsonDecode(line);
    if (j is Map<String, dynamic> && j.containsKey('filesSession')) return j;
  }
  throw StateError('the demo did not say its files conversation');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('download a file the agent sent', (t) async {
    final demo = _demo();
    final saved = <String>[];
    debugSaveBytes = (name, bytes) async {
      saved.add('$name ${bytes.length}');
      return true;
    };
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
                  ConversationScreen(sessionId: demo['filesSession'] as String, agent: god),
            ),
          )
          .ignore();
      final download = find.byKey(const Key('file-download-report.txt'));
      await waitFor(t, () => download.evaluate().isNotEmpty);
      await t.ensureVisible(download);
      await shot(t, 'g3811-scarica-$_tag-$theme-01-scheda', wait: 1500);
      await t.tap(download);
      await waitFor(t, () => find.text('Salvato: report.txt').evaluate().isNotEmpty);
      await shot(t, 'g3811-scarica-$_tag-$theme-02-salvato', wait: 400);
      debugPrint('saved: $saved');
      nav.pop();
      await frames(t, 800);
    }
    debugSaveBytes = null;
  });
}
