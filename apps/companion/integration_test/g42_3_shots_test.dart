// G42.3 in the real app on Linux, against the demo server with DEMO_SUBAGENTS=1 (FakeProvider, no
// real model): God's conversation with three sub-agents and three background commands (the tabs,
// the strip, a sub-agent's view, a command's output), the group chat «December release», the Chat
// with its groups and the earlier chat, the old chat itself, the project's board with a thread, and
// the agents' shared browser (with no Docker the demo has none: its pictures are given to the app
// as the server would send them); light and dark. RG_SCREEN narrower than 600 is the phone:
//   RG_SCREEN=390x844 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_SUBAGENTS=1" \
//     bash tool/linux_shots.sh <folder> integration_test/g42_3_shots_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/screens/board_screen.dart';
import 'package:rgcompanion/screens/browser_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/daily_chat_screen.dart';
import 'package:rgcompanion/screens/room_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

/// What the demo printed when it was ready (its sessions), from tool/linux_shots.sh's log.
Map<String, dynamic> _demo() {
  final line = File('/tmp/demo.log')
      .readAsLinesSync()
      .lastWhere((l) => l.trimLeft().startsWith('{') && l.contains('"url"'));
  return jsonDecode(line) as Map<String, dynamic>;
}

/// A browser's screen as a picture: a page with a header, a title and a few lines (what the
/// screencast would send), drawn here because the demo has no Docker browser.
List<int> _page() {
  final p = img.Image(width: 1280, height: 800)..clear(img.ColorRgb8(250, 250, 252));
  img.fillRect(p, x1: 0, y1: 0, x2: 1280, y2: 72, color: img.ColorRgb8(34, 40, 56));
  img.fillRect(p, x1: 40, y1: 24, x2: 220, y2: 48, color: img.ColorRgb8(210, 58, 44));
  for (final (i, w) in [300, 520, 460, 610, 380].indexed) {
    img.fillRect(
      p,
      x1: 80,
      y1: 140 + i * 60,
      x2: 80 + w,
      y2: 164 + i * 60,
      color: img.ColorRgb8(200, 205, 215),
    );
  }
  img.fillRect(p, x1: 80, y1: 480, x2: 300, y2: 530, color: img.ColorRgb8(46, 157, 91));
  img.fillRect(p, x1: 760, y1: 140, x2: 1200, y2: 560, color: img.ColorRgb8(226, 232, 240));
  return img.encodeJpg(p, quality: 80);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.3: parallel work and groups as the page shows them', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final demo = _demo();
    final sub = demo['subSession'] as String;
    await waitFor(t, () => app.live.sessions.any((s) => s.id == sub), seconds: 40);
    await frames(t, 1500);
    final p = _phone ? 'telefono' : 'computer';
    final god = app.agents.firstWhere((a) => a.kind == AgentKind.god);
    final rooms = await t.runAsync(() => app.client!.rooms());
    final room = rooms!.firstWhere((r) => r.title == 'December release');
    final chats = await t.runAsync(() => app.client!.chats());
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> open(Widget screen) async {
      nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
      await frames(t, 2500);
    }

    Future<void> back() async {
      nav.pop();
      await frames(t, 800);
    }

    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      String name(String what) => 'g42-3-$p-$theme-$what';
      await frames(t, 600);

      // God's conversation: the tabs on top, the strip of commands, then a sub-agent.
      app.openSubPath(sub, const []);
      await open(ConversationScreen(sessionId: sub, agent: god));
      await shot(t, name('01-linguette'), wait: 1500);
      final tabs = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('sub-tab-'),
      );
      final ids = [
        for (final e in tabs.evaluate()) (e.widget.key! as ValueKey<String>).value.substring(8),
      ];
      final outputs = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('cmd-output-'),
      );
      if (outputs.evaluate().isNotEmpty) {
        await t.tap(outputs.first);
        await shot(t, name('02-output'), wait: 2500);
        await t.tap(find.byKey(const Key('cmd-output-close')));
        await frames(t, 600);
      }
      final toggle = find.byKey(const Key('cmd-done-toggle'));
      if (toggle.evaluate().isNotEmpty) {
        await t.tap(toggle);
        await shot(t, name('03-comandi-finiti'));
        await t.tap(toggle);
      }
      for (final (i, id) in ids.indexed) {
        app.openSubPath(sub, [id]);
        await shot(t, name('04-sotto-agente-${i + 1}'), wait: 1800);
      }
      app.openSubPath(sub, const []);
      await back();

      // The group chat.
      await open(RoomScreen(roomId: room.id));
      await shot(t, name('05-stanza'), wait: 1500);
      await back();

      // The Chat: its days, the earlier chat and the groups.
      // On a computer the Chat is the control room's panel (as the page's tab «Chat»).
      DeskController? desk;
      if (_phone) {
        app.setTab(AppTab.chat);
      } else {
        desk = DeskScope.maybeRead(
          t.element(
            find.descendant(of: find.byType(DeskScope), matching: find.byType(Scaffold)).first,
          ),
        );
        desk?.show(const PanelPage(PanelScreen.chat));
      }
      await frames(t, 1500);
      await shot(t, name('06-chat'));
      final list = find.byKey(const Key('chat-days'));
      if (list.evaluate().isNotEmpty) {
        final s = t.state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        );
        s.position.jumpTo(s.position.maxScrollExtent);
        await shot(t, name('07-chat-gruppi'));
        s.position.jumpTo(0);
      }
      app.setTab(AppTab.team);
      desk?.closePanel();
      await frames(t, 600);
      if (chats!.isNotEmpty) {
        await open(DailyChatScreen(chat: chats.first));
        await shot(t, name('08-chat-di-prima'), wait: 1500);
        await back();
      }

      // The project's board, with its first thread open on a computer.
      await open(const BoardScreen(projectId: 'demo', title: 'Bacheca · Demo'));
      await shot(t, name('09-bacheca'));
      final firstThread = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('board-thread-') &&
            !(w.key! as ValueKey<String>).value.startsWith('board-thread-view') &&
            !(w.key! as ValueKey<String>).value.startsWith('board-thread-back'),
      );
      final target = firstThread;
      if (target.evaluate().isNotEmpty) {
        await t.tap(target.first);
        await shot(t, name('10-thread'), wait: 1800);
        if (_phone) await back();
      }
      await back();

      // The shared browser: the demo has none (no Docker), the app says so; then its pictures as
      // the server sends them, with the person in control.
      await open(const BrowserScreen());
      await shot(t, name('11-browser-assente'));
      final b = app.live.browser
        ..unavailable = false
        ..watching = true;
      b.apply({
        'type': 'browser.state',
        'control': 'agents',
        'url': 'https://shop.example.org/orders',
      });
      b.apply({
        'type': 'browser.frame',
        'data': base64Encode(_page()),
        'width': 1280,
        'height': 800,
      });
      await shot(t, name('12-browser'));
      b.apply({
        'type': 'browser.state',
        'control': 'person',
        'url': 'https://shop.example.org/orders',
      });
      await shot(t, name('13-browser-mio'));
      await back();
    }
  });
}
