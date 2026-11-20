// 3.10: «Save as…» written to disk as it comes, on Linux against a real Rasgeth (the demo with
// DEMO_VIDEO=<folder>, whose `video/finale.mp4` is big): the finished video opened in the Canvas,
// the bar's «Download», the bar under the chat while it comes (how much, how fast, how long,
// «Annulla»), then «Salvato». The system's window is replaced by a path in /tmp (a test cannot
// drive the portal). RG_SHOTS the folder, RG_SHOT_TAG computer, RG_SHOT_THEME chiaro | scuro.
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
import 'package:rgcompanion/ui/chat/file_download.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';
final _theme = Platform.environment['RG_SHOT_THEME'] ?? 'chiaro';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the finished video saved with its bar', (t) async {
    final out = Directory('/tmp/rg-save-shots')..createSync(recursive: true);
    final dest = '${out.path}/finale.mp4';
    debugPickSavePath = (name) async {
      await File(dest).writeAsBytes(const []);
      return dest;
    };
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
    host.show('finale.mp4', {'kind': 'file', 'scope': 'project:demo', 'path': 'video/finale.mp4'});
    await frames(t, 3000);
    final download = find.byKey(const Key('canvas-download'));
    if (download.evaluate().isEmpty) throw StateError('no «Download» in the bar');
    await t.tap(download);
    // The bar as soon as it shows, then twice more while it moves.
    for (var i = 0; i < 100 && find.byKey(const Key('download-words')).evaluate().isEmpty; i++) {
      await frames(t, 50);
    }
    await shot(t, 'g310-save-$_tag-$_theme-01-bar', wait: 400);
    await shot(t, 'g310-save-$_tag-$_theme-02-bar', wait: 700);
    for (var i = 0; i < 600 && !(File(dest).existsSync() && File(dest).lengthSync() > 0); i++) {
      await frames(t, 100);
    }
    await shot(t, 'g310-save-$_tag-$_theme-03-saved', wait: 1500);
    debugPrint('saved: ${File(dest).existsSync() ? File(dest).lengthSync() : -1} bytes; '
        'left in the folder: ${out.listSync().map((e) => e.path).join(', ')}');
    if (nav.canPop()) nav.pop();
    await frames(t, 600);
  });
}
