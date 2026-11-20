// G42.18: the video timeline inside the app's Canvas, on Linux (WebKitGTK) against a real Rasgeth
// (the demo with DEMO_VIDEO=<folder>: `video/montaggio.rgvideo` in the Demo project, its proxies made
// by the ffmpeg of REDGIANT_FFMPEG). The timeline open with «Timeline video» in the native bar; the
// app's keys from its own bar (L plays, K stops, Ctrl+B cuts at the cursor); a file of the tree
// handed over as the app drops it; «Chiedi all'agente qui» put in the conversation's composer.
// Run in the agents' Docker with tool/linux_shots.sh, one theme per run: RG_SHOTS the folder,
// RG_SHOT_TAG computer | telefono, RG_SHOT_THEME chiaro | scuro, RG_SCREEN the window's size.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const _scope = 'project:demo';
const _path = 'video/montaggio.rgvideo';

/// The editor's ruler clicked a little in (the playhead inside the first clip).
const _cursor = '''
(() => {
  const r = document.querySelector('.ve-ruler');
  if (!r) return;
  const b = r.getBoundingClientRect();
  const o = { bubbles: true, clientX: b.left + b.width * 0.18, clientY: b.top + 6, button: 0 };
  r.dispatchEvent(new PointerEvent('pointerdown', o));
  window.dispatchEvent(new PointerEvent('pointerup', o));
  r.dispatchEvent(new MouseEvent('click', o));
  document.activeElement?.blur();
})();
''';

/// «Chiedi all'agente qui» opened with a question, then sent (it goes to the app's composer).
const _ask = '''
(async () => {
  const b = document.querySelector('.ve-bar button[aria-label^="Chiedi all\\'agente qui"]');
  b?.click();
  await new Promise((r) => setTimeout(r, 300));
  const box = document.querySelector('.ve-ask textarea');
  if (!box) return;
  const set = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set;
  set.call(box, 'Accorcia questa parte a due secondi');
  box.dispatchEvent(new Event('input', { bubbles: true }));
  await new Promise((r) => setTimeout(r, 200));
  [...document.querySelectorAll('.ve-ask button')].find((x) => x.textContent.trim() === 'Manda')?.click();
})();
''';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the video timeline in the Canvas on Linux', (t) async {
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
    host.show('montaggio.rgvideo', {'kind': 'file', 'scope': _scope, 'path': _path});
    await frames(t, 300);
    final shell = t.state<CanvasShellState>(find.byType(CanvasShell));
    final id = canvasTabId({'kind': 'file', 'scope': _scope, 'path': _path});
    try {
      await waitFor(t, () => shell.viewOf(id)?.ready ?? false, seconds: 60);
    } on StateError {
      debugPrint('not ready: $_path');
    }
    final view = shell.viewOf(id);
    // The proxies and the strips of frames are made the first time (ffmpeg).
    await frames(t, 12000);
    await shot(t, 'g42-18-$_tag-$_theme-01-timeline', wait: 1500);

    // The app's keys, from its own bar: L plays, K stops, Ctrl+B cuts at the cursor.
    await t.runAsync(() => view?.runForTest(_cursor) ?? Future<void>.value());
    await frames(t, 600);
    final bar = find.byKey(const Key('canvas-bar'));
    if (bar.evaluate().isNotEmpty) {
      Focus.of(t.element(bar)).requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.keyL);
      await frames(t, 1500);
      await shot(t, 'g42-18-$_tag-$_theme-02-playing', wait: 300);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await frames(t, 400);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyB);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await shot(t, 'g42-18-$_tag-$_theme-03-cut', wait: 1500);
    } else {
      debugPrint('no native bar');
    }

    // A file of the project's tree, handed over as the app drops it (at a point of the lane).
    final box = find.byKey(ValueKey('canvas-content-$id'));
    if (box.evaluate().isNotEmpty) {
      final r = t.getRect(box);
      await t.runAsync(
        () =>
            view?.dropProjectFile(
              scope: _scope,
              path: 'video/foto.jpg',
              global: Offset(r.left + r.width * 0.8, r.top + r.height * 0.72),
            ) ??
            Future<void>.value(),
      );
      await shot(t, 'g42-18-$_tag-$_theme-04-dropped', wait: 2500);
    }

    // «Chiedi all'agente qui»: the question in the conversation's composer (on a phone the
    // conversation comes back).
    await t.runAsync(() => view?.runForTest(_ask) ?? Future<void>.value());
    await shot(t, 'g42-18-$_tag-$_theme-05-chiedi', wait: 2000);

    final model = t.state<CanvasShellState>(find.byType(CanvasShell)).widget.model;
    for (final tab in [...model.tabs]) {
      model.close(tab.id);
    }
    await frames(t, 600);
    if (nav.canPop()) nav.pop();
    await frames(t, 800);
  });
}
