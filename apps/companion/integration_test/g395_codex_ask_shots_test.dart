// 3.9.5: a question from the Codex engine, on Linux against a real Rasgeth (the demo with
// DEMO_CODEX_ASK=1: the Chat on Rasgeth's Codex adapter, a `codex app-server` stand-in that asks
// about a UPS and waits). The question card waiting for the person (no bulleted text, no answer
// before theirs), an option chosen, then the answer sent and Codex going on with it.
// RG_SHOT_TAG names the size (computer, phone: RG_SCREEN=390x844), RG_SHOTS the folder.
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

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _log = Platform.environment['RG_DEMO_LOG'] ?? '/tmp/demo.log';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

String _session() {
  for (final line in File(_log).readAsLinesSync().reversed) {
    if (!line.startsWith('{')) continue;
    final j = jsonDecode(line);
    if (j is Map<String, dynamic> && j['codexAskSession'] is String) {
      return j['codexAskSession'] as String;
    }
  }
  throw StateError('the demo did not say its Codex question (DEMO_CODEX_ASK=1)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a question from the Codex engine waits on the card', (t) async {
    final id = _session();
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.live.questions.any((q) => q.sessionId == id));
    final q = app.live.questions.firstWhere((q) => q.sessionId == id);
    final agent = app.agents.firstWhere((a) => a.id == q.agentId);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final card = find.byKey(Key('chat-question-${q.requestId}'));
    final option = find.byKey(
      Key('chat-option-${q.requestId}-0-${q.questions.first.options.first.label}'),
    );

    final passes = [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)];
    for (final (n, (theme, mode)) in passes.indexed) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final p = 'app-$_tag-$theme';
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: id, agent: agent),
            ),
          )
          .ignore();
      await frames(t, 600);
      await waitFor(t, () => card.evaluate().isNotEmpty);
      await t.ensureVisible(card);
      // Waiting for the person: the card, no «reading the context» under it.
      expect(find.byKey(const Key('turn-progress')), findsNothing);
      await shot(t, '$p-01-domanda', wait: 1200);
      await t.tap(option);
      await frames(t, 400);
      await shot(t, '$p-02-scelta', wait: 600);
      if (n == passes.length - 1) {
        await t.tap(find.byKey(Key('chat-answer-${q.requestId}')));
        await waitFor(
          t,
          () => find.textContaining('line-interactive', findRichText: true).evaluate().isNotEmpty,
        );
        await shot(t, '$p-03-risposta', wait: 1200);
      }
      nav.pop();
      await frames(t, 600);
    }
  });
}
