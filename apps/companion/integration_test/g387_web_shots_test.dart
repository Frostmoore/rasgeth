// 3.8.7: widgets and artifacts on Linux, against a real RedGiant (the demo with DEMO_ARTIFACTS=1:
// God's humidity widget and the CSV explorer artifact). Linux has no web view the app can trust
// in a scrolling chat: the widget shows its words and «Apri nella pagina», the artifact its source
// under the same button. Run by hand in the agents' Docker (see the app's README), with RG_DEMO_LOG
// the demo's output (its session ids) and RG_SHOTS the folder for the pictures.
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

Map<String, dynamic> _demo() {
  for (final line in File(_log).readAsLinesSync().reversed) {
    if (!line.startsWith('{')) continue;
    final j = jsonDecode(line);
    if (j is Map<String, dynamic> && j.containsKey('widgetSession')) return j;
  }
  throw StateError('the demo did not say its sessions (DEMO_ARTIFACTS=1?)');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('widgets and artifacts on Linux', (t) async {
    final demo = _demo();
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    final god = app.agents.firstWhere((a) => a.id == demo['god']);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);

    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ConversationScreen(sessionId: demo['widgetSession'] as String, agent: god),
          ),
        )
        .ignore();
    await waitFor(t, () => find.byKey(const Key('widget-fallback')).evaluate().isNotEmpty);
    await shot(t, 'g387-linux-01-widget-fallback', wait: 1500);
    nav.pop();
    await frames(t);

    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ConversationScreen(sessionId: demo['plainWidgetSession'] as String, agent: god),
          ),
        )
        .ignore();
    await waitFor(t, () => find.byKey(const Key('widget-fallback')).evaluate().isNotEmpty);
    await shot(t, 'g387-linux-02-plain-widget-fallback', wait: 1500);
    nav.pop();
    await frames(t);

    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ConversationScreen(sessionId: demo['artifactSession'] as String, agent: god),
          ),
        )
        .ignore();
    final card = find.textContaining('esplora-csv');
    await waitFor(t, () => card.evaluate().isNotEmpty);
    await shot(t, 'g387-linux-03-artifact-line', wait: 900);
    // The card's «Apri» (the text may be the person's own message too).
    await t.tap(find.text('Apri').last);
    await waitFor(t, () => find.byKey(const Key('artifact-open-page')).evaluate().isNotEmpty);
    await shot(t, 'g387-linux-04-artifact-in-page', wait: 1200);
  });
}
