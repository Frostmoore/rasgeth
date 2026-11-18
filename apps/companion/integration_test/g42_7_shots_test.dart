// G42.7: the page's editors inside the app's Canvas, on Linux (WebKitGTK) against a real RedGiant
// (the demo with DEMO_CANVAS=1, whose God edits the file open when asked: «Migliora il totale»,
// «Prepara il modulo», «Aggiungi l'etichetta», «Metti il fiore come livello»). For each editor:
// open, the page's «Modifiche» panel opened, the agent's edit arriving (its marks), the native bar
// with the save state; then a selection in the text with «Chiedi all'agente» in the native bar.
// Run in the agents' Docker with tool/linux_shots.sh, one theme per run (a fresh demo each time:
// the agent's edits apply once): RG_SHOTS the folder, RG_SHOT_TAG computer | telefono,
// RG_SHOT_THEME chiaro | scuro, RG_SCREEN the window's size.
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
final _theme = Platform.environment['RG_SHOT_THEME'] ?? 'chiaro';

/// The four editors: the file, what makes the demo's God edit it, how long the edit takes to show.
const _editors = [
  ('01-testo', 'canvas/app.py', 'Migliora il totale', 4000),
  ('02-pdf', 'canvas/modulo.pdf', 'Prepara il modulo', 6000),
  ('03-svg', 'canvas/poster.svg', "Aggiungi l'etichetta", 5000),
  ('04-immagine', 'canvas/poster.ora', 'Metti il fiore come livello', 7000),
];

/// The page's «Modifiche» toggle in the editor's bar, clicked as a person would.
const _openChanges =
    "document.querySelector('.doc-bar button[aria-controls=\"doc-changes\"]:not([aria-pressed=\"true\"])')?.click();";

/// Lines 13 to 15 of the text selected, through the editor itself (its content element keeps its
/// view); the page's own selection as a fallback.
const _selectLines = '''
(() => {
  const c = document.querySelector('.cm-content');
  if (!c) return;
  c.focus();
  const v = c.cmView?.view ?? c.cmView?.rootView?.view;
  if (v) {
    const d = v.state.doc;
    v.dispatch({ selection: { anchor: d.line(13).from, head: d.line(15).to } });
    return;
  }
  const lines = c.querySelectorAll('.cm-line');
  const a = lines[2], b = lines[4] ?? lines[lines.length - 1];
  if (a && b) getSelection().setBaseAndExtent(a, 0, b, b.childNodes.length);
})();
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the four editors in the Canvas on Linux, with the agent\'s marks', (t) async {
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
    app.setThemeMode(_theme == 'scuro' ? ThemeMode.dark : ThemeMode.light);
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
    const scope = 'platform';
    Future<EmbedViewStateLike?> openFile(String path) async {
      host.show(path.split('/').last, {'kind': 'file', 'scope': scope, 'path': path});
      await frames(t, 300);
      final shell = t.state<CanvasShellState>(find.byType(CanvasShell));
      final id = canvasTabId({'kind': 'file', 'scope': scope, 'path': path});
      try {
        await waitFor(t, () => shell.viewOf(id)?.ready ?? false, seconds: 30);
      } on StateError {
        debugPrint('not ready: $path');
      }
      final v = shell.viewOf(id);
      return v == null ? null : EmbedViewStateLike(v.runForTest);
    }

    for (final (name, path, words, wait) in _editors) {
      final view = await openFile(path);
      // The editor loads its engine (pdf.js, the drawing's, the picture's) before its bar is there.
      await frames(t, 3000);
      await t.runAsync(() => view?.run(_openChanges) ?? Future<void>.value());
      await frames(t, 600);
      await t.runAsync(() => c.sendMessage(session!, words));
      await shot(t, 'g42-7-$_tag-$_theme-$name', wait: wait);
    }
    // A selection in the text: «Chiedi all'agente» in the native bar.
    final text = await openFile('canvas/app.py');
    // Tried again until the editor has its text (the tab may load again: one view alive on Linux).
    for (var i = 0; i < 20 && find.byKey(const Key('canvas-action-ask')).evaluate().isEmpty; i++) {
      await frames(t, 800);
      await t.runAsync(() => text?.run(_selectLines) ?? Future<void>.value());
    }
    if (find.byKey(const Key('canvas-action-ask')).evaluate().isEmpty) {
      debugPrint('no «Chiedi all\'agente» in the bar');
    }
    await shot(t, 'g42-7-$_tag-$_theme-05-chiedi', wait: 1200);
    final model = t.state<CanvasShellState>(find.byType(CanvasShell)).widget.model;
    for (final tab in [...model.tabs]) {
      model.close(tab.id);
    }
    await frames(t, 600);
    if (_tag != 'computer') nav.pop();
    await frames(t, 600);
    nav.pop();
    await frames(t, 800);
  });
}

/// A page's script runner (`EmbedViewState.runForTest`).
class EmbedViewStateLike {
  EmbedViewStateLike(this.run);
  final Future<void> Function(String script) run;
}
