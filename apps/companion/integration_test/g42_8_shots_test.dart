// G42.8: the sheet, document and 3D editors in the Canvas's frame, on Linux (WebKitGTK) against a
// real Rasgeth (the demo with DEMO_CANVAS=1, DEMO_SAMPLES with an ODS with formulas, an ODT and a
// GLB, DEMO_ZETA with LibreOffice for the browser already on the server), light and dark. The ODT
// opens the isolated embed: the engine comes into the web view's storage with its bar the first
// time, then LibreOffice runs (or the page says why not). Run with tool/linux_shots.sh,
// RG_SHOTS the folder for the pictures, RG_SHOT_TAG computer | telefono.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/canvas/canvas_shell.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

/// The editors' files and how long each takes to draw.
const _files = [
  ('01-foglio-formule', 'campioni/spese-formule.ods', 6000),
  ('02-documento-docx', 'canvas/relazione.docx', 6000),
  ('03-presentazione-pptx', 'canvas/piano.pptx', 6000),
  ('04-3d-glb', 'campioni/scatola.glb', 4000),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the editors in the Canvas on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final c = app.client!;
    final god = app.agents.firstWhere((a) => a.name == 'God', orElse: () => app.agents.first);
    String? session;
    await t.runAsync(() async {
      final all = await c.sessions(agentId: god.id);
      session = all.isEmpty ? null : all.first.id;
    });
    if (session == null) throw StateError('no conversation of God in the demo');
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: session!, agent: god),
            ),
          )
          .ignore();
      await frames(t, 1500);
      final host = t.widget<CanvasHost>(find.byType(CanvasHost));
      Future<void> show(String path) async {
        const scope = 'platform';
        host.show(path.split('/').last, {'kind': 'file', 'scope': scope, 'path': path});
        await frames(t, 300);
        final shell = t.state<CanvasShellState>(find.byType(CanvasShell));
        final id = canvasTabId({'kind': 'file', 'scope': scope, 'path': path});
        try {
          await waitFor(t, () => shell.viewOf(id)?.ready ?? false, seconds: 30);
        } on StateError {
          debugPrint('not ready: $path');
        }
      }

      for (final (name, path, wait) in _files) {
        await show(path);
        await shot(t, 'g42-8-$_tag-$theme-$name', wait: wait);
      }
      // The full document editor: the bar while it comes down (the first time), then the editor.
      await show('campioni/lettera.odt');
      await shot(t, 'g42-8-$_tag-$theme-05-odt-avvio', wait: 2500);
      await shot(t, 'g42-8-$_tag-$theme-06-odt-editor', wait: theme == 'chiaro' ? 90000 : 30000);
      final model = t.state<CanvasShellState>(find.byType(CanvasShell)).widget.model;
      for (final tab in [...model.tabs]) {
        model.close(tab.id);
      }
      await frames(t, 600);
      if (_tag != 'computer') nav.pop();
      await frames(t, 600);
      nav.pop();
      await frames(t, 800);
    }
  });
}
