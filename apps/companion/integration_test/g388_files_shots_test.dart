// 3.8.8 (G42.5) in the real app on Linux, against the demo server (a real RedGiant, FakeProvider):
// the conversation's files from the header's folder, light and dark. Computer (1440x900): the
// panel beside the Demo orchestrator's conversation, folders open, the right click menu, a file
// dragged onto the conversation, full window, an archived project read only. Phone (RG_SCREEN
// narrower than 600): the files screen, a row's sheet. Run by tool/linux_shots.sh:
//   RG_SCREEN=1440x900 … integration_test/g388_files_shots_test.dart
//   RG_SCREEN=390x844 … integration_test/g388_files_shots_test.dart
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder row(String path) => find.byKey(Key('files-row-$path'));

  Future<void> tap(WidgetTester t, Finder f, [int ms = 900]) async {
    await t.tap(f.first);
    await frames(t, ms);
  }

  testWidgets('G42.5: the conversation\'s files', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.agents.any((a) => a.name == 'Demo orchestrator'));
    await frames(t, 2000);
    final p = _phone ? 'telefono' : 'computer';
    final demo = app.agents.firstWhere((a) => a.name == 'Demo orchestrator');
    final old = app.agents.where((a) => a.name == 'Old site lead').firstOrNull;

    Future<void> open(Agent a) async {
      if (_phone) {
        final sid = await t.runAsync(() => app.openAgent(a));
        t
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => ConversationScreen(sessionId: sid!, agent: a),
              ),
            )
            .ignore();
      } else {
        await t.tap(find.byKey(Key('tile-${a.id}')));
      }
      await frames(t, 3000);
    }

    Future<void> close() async {
      if (_phone) {
        t.state<NavigatorState>(find.byType(Navigator).first).popUntil((r) => r.isFirst);
      } else {
        await t.tap(find.byKey(const Key('rail-room')));
      }
      await frames(t, 1200);
    }

    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      String name(int n, String what) => 'g388-files-$p-$theme-${'$n'.padLeft(2, '0')}-$what';
      await frames(t, 800);
      await open(demo);
      if (!_phone) {
        DeskScope.read(t.element(find.byKey(const Key('desk-panel')))).setFull(true);
        await frames(t, 1500);
      }
      await shot(t, name(1, 'conversazione-cartella'));
      await tap(t, find.byKey(const Key('conversation-files')), 2500);
      await shot(t, name(2, 'file'));
      await tap(t, row('src'), 1200);
      await tap(t, row('docs'), 1200);
      await shot(t, name(3, 'cartelle-aperte'));
      if (_phone) {
        await tap(t, find.byKey(const Key('files-more-docs/report.pdf')), 1200);
        await shot(t, name(4, 'azioni-del-file'));
        t.state<NavigatorState>(find.byType(Navigator).first).pop();
        await frames(t, 800);
        await tap(t, find.byKey(const Key('files-hidden')), 1500);
        await shot(t, name(5, 'nascosti'));
        await tap(t, find.byKey(const Key('files-hidden')), 800);
        await tap(t, row('docs/report.pdf'), 3500);
        await shot(t, name(6, 'aperto-nel-canvas'), wait: 1500);
      } else {
        // Hover, then the right click menu.
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: t.getCenter(row('docs/report.pdf')));
        await frames(t, 400);
        await shot(t, name(4, 'passaggio-del-mouse'));
        await t.tap(row('docs/report.pdf'), buttons: kSecondaryButton);
        await frames(t, 800);
        await shot(t, name(5, 'menu'));
        // Away from the menu (Esc would also leave the full window).
        await t.tapAt(const Offset(1300, 820));
        await frames(t, 600);
        // A file on its way to the conversation.
        final from = t.getCenter(row('src/app.py'));
        final to = t.getCenter(find.byKey(const Key('composer-box')));
        final g = await t.startGesture(from, kind: PointerDeviceKind.mouse);
        for (var i = 1; i <= 12; i++) {
          await g.moveTo(Offset.lerp(from, to, i / 12)!);
          await t.pump(const Duration(milliseconds: 30));
        }
        await shot(t, name(6, 'trascina-nella-conversazione'), wait: 300);
        await g.up();
        await frames(t, 1500);
        await shot(t, name(7, 'allegato'));
        await mouse.removePointer();
        await tap(t, find.byKey(const Key('files-full')), 1500);
        await shot(t, name(8, 'a-tutta-finestra'));
        await tap(t, find.byKey(const Key('files-unfull')), 1200);
        await tap(t, find.byKey(const Key('files-hidden')), 1500);
        await shot(t, name(9, 'nascosti'));
        await tap(t, find.byKey(const Key('files-hidden')), 800);
      }
      await close();
      if (old != null) {
        await open(old);
        if (_phone) await tap(t, find.byKey(const Key('conversation-files')), 2500);
        await shot(t, name(10, 'archiviato-sola-lettura'), wait: 1500);
        await close();
      }
      if (!_phone) {
        // Closed for the next round (the panel's state is kept).
        await open(demo);
        await tap(t, find.byKey(const Key('conversation-files')), 800);
        await close();
      }
    }
  });
}
