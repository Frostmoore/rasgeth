// G42.1 in the real app on Linux, against the demo server with DEMO_CONV=1 (FakeProvider, no real
// model): the conversation with everything the chat shows (demo-conversation.mjs: tools, diff,
// mail, steps, questions, plan, summaries, files, the step limit) and its live requests (a
// command, a tool asked back, an artifact's cap, an email to send, a plan), from the bottom to the
// top, then its copy (the fork); light and dark. RG_SCREEN narrower than 600 is the phone:
//   RG_SCREEN=390x844 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_CONV=1" \
//     bash tool/linux_shots.sh <folder> integration_test/g42_1_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

const _title = 'Il login di Bottega non funziona';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.1: the whole conversation as the page shows it', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.live.sessions.any((s) => s.title == _title));
    await waitFor(t, () => app.live.approvals.length >= 4, seconds: 40);
    await frames(t, 2000);
    final p = _phone ? 'telefono' : 'computer';
    final row = app.live.sessions.firstWhere((s) => s.title == _title);
    final agent = app.agents.firstWhere((a) => a.id == row.agentId);
    final fork = app.live.sessions.where((s) => s.agentId == agent.id && s.id != row.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    Future<void> tour(String sessionId, String name, String theme, {int max = 14}) async {
      t
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: sessionId, agent: agent),
            ),
          )
          .ignore();
      await frames(t, 3500);
      final list = find.byKey(const Key('conversation-items'));
      for (var i = 0; i < max; i++) {
        await shot(t, 'g42-1-$p-$theme-$name-${(i + 1).toString().padLeft(2, '0')}', wait: 700);
        final s = t.state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        );
        if (s.position.pixels >= s.position.maxScrollExtent - 1) break;
        // The list is reversed: older messages are further up.
        s.position.jumpTo(
          (s.position.pixels + s.position.viewportDimension * .85).clamp(
            0,
            s.position.maxScrollExtent,
          ),
        );
        await frames(t, 400);
      }
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await frames(t, 800);
    }

    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      await frames(t, 600);
      await tour(row.id, 'conv', theme, max: 24);
      if (fork.isNotEmpty) await tour(fork.first.id, 'fork', theme, max: 3);
    }
  });
}
