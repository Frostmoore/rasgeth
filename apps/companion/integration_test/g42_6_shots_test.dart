// G42.6: the Canvas's native frame around the page's viewers, on Linux (WebKitGTK) against a real
// RedGiant (the demo with DEMO_CANVAS=1 and DEMO_SAMPLES, one file for each viewer kind), light and
// dark. Run in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for the phone's size),
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

/// One file for each of the page's viewer kinds (canvas/ from DEMO_CANVAS, campioni/ from
/// DEMO_SAMPLES), and how long its viewer takes to draw.
const _files = [
  ('01-pdf', 'canvas/modulo.pdf', 2500),
  ('02-immagine', 'canvas/fiore.png', 1200),
  ('03-svg', 'campioni/logo.svg', 1200),
  ('04-video', 'campioni/clip.mp4', 2500),
  ('05-audio', 'campioni/suono.wav', 1500),
  ('06-markdown', 'campioni/note.md', 2000),
  ('07-codice', 'canvas/app.py', 2000),
  ('08-tabella', 'canvas/conti.csv', 2000),
  ('09-albero', 'campioni/dati.json', 2000),
  ('10-documento', 'canvas/relazione.docx', 6000),
  ('11-presentazione', 'canvas/piano.pptx', 6000),
  ('12-3d', 'canvas/sedia.obj', 3000),
  ('13-archivio', 'campioni/archivio.zip', 1500),
  ('14-font', 'campioni/carattere.ttf', 1500),
  ('15-livelli', 'canvas/poster.ora', 3000),
  ('16-sito', 'campioni/sito', 2000),
  ('17-artefatto', 'artefatti/galleria-kit.html', 3000),
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Canvas with one file of each kind on Linux', (t) async {
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
      for (final (name, path, wait) in _files) {
        const scope = 'platform';
        host.show(path.split('/').last, {'kind': 'file', 'scope': scope, 'path': path});
        await frames(t, 300);
        final shell = t.state<CanvasShellState>(find.byType(CanvasShell));
        final id = canvasTabId({'kind': 'file', 'scope': scope, 'path': path});
        try {
          await waitFor(t, () => shell.viewOf(id)?.ready ?? false, seconds: 25);
        } on StateError {
          debugPrint('not ready: $path');
        }
        await shot(t, 'g42-6-$_tag-$theme-$name', wait: wait);
      }
      // The frame's ways: maximized over the conversation (a computer), the whole screen.
      final model = t.state<CanvasShellState>(find.byType(CanvasShell)).widget.model;
      model.select(canvasTabId({'kind': 'file', 'scope': 'platform', 'path': 'canvas/modulo.pdf'}));
      await frames(t, 800);
      if (_tag == 'computer') {
        model.setMax(true);
        await shot(t, 'g42-6-$_tag-$theme-20-ingrandito', wait: 1500);
        model.setMax(false);
      }
      model.setFull(true);
      await shot(t, 'g42-6-$_tag-$theme-21-schermo-intero', wait: 1500);
      model.setFull(false);
      await frames(t, 600);
      for (final tab in [...model.tabs]) {
        model.close(tab.id);
      }
      await frames(t, 600);
      if (_tag != 'computer') await t.pageBack();
      await frames(t, 600);
      await t.pageBack();
      await frames(t, 800);
    }
  });
}
