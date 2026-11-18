// 3.8.10 in the real app on Linux, against the tests' fake RedGiant: agents at work together. Two
// places taken, three turns in line: the wall with the tiles in line, the status bar, the queue's
// window, a conversation waiting and the setting, light and dark. With RG_SCREEN narrower than 600
// the phone. Run with Xvfb (no demo server needed):
//   RG_SCREEN=390x844 RG_SHOTS=<folder> flutter test integration_test/g3810_queue_shots_test.dart -d linux
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/at_work_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

Map<String, dynamic> _row(String id, String agent, String title, {bool running = false}) => {
  'id': id,
  'agentId': agent,
  'projectId': null,
  'createdAt': '2026-11-17T09:00:00.000Z',
  'lastAt': '2026-11-17T10:00:00.000Z',
  'title': title,
  'archived': false,
  'running': running,
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.8.10: agents at work together', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    fake.commandSettings = {...fake.commandSettings, 'maxAtWork': 2};
    fake.sessions.addAll([
      _row('w2', 'a2', 'Piano della release', running: true),
      _row('w3', 'a3', 'Pagina dei prezzi', running: true),
      _row('s4', 'a4', 'Analisi dei concorrenti'),
      _row('s5', 'a5', 'Riordina la posta di ieri'),
      _row('s7', 'a7', 'Test del login'),
    ]);
    final since = DateTime.now().toUtc();
    String ago(int min) => since.subtract(Duration(minutes: min)).toIso8601String();
    final view = {
      'limit': 2,
      'working': 2,
      'running': [
        {'sessionId': 'w2', 'agentId': 'a2'},
        {'sessionId': 'w3', 'agentId': 'a3'},
      ],
      'queued': [
        {'sessionId': 's7', 'agentId': 'a7', 'since': ago(1), 'child': true},
        {'sessionId': 's4', 'agentId': 'a4', 'since': ago(6)},
        {'sessionId': 's5', 'agentId': 'a5', 'since': ago(4)},
      ],
    };
    fake.turnQueue = view;
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await waitFor(t, () => app.live.turns.queued.length == 3);
    await frames(t, 3000);
    final p = _phone ? 'telefono' : 'computer';
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ricercatore = app.agents.firstWhere((a) => a.id == 'a4');

    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      await frames(t, 1500);
      if (!_phone) {
        await shot(t, 'g3810-$p-$theme-1-parete');
        await t.tap(find.byKey(const Key('status-queue')));
        await shot(t, 'g3810-$p-$theme-2-coda');
        await t.tap(find.byKey(const Key('queue-close')));
        await frames(t, 600);
      }
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's4', agent: ricercatore),
            ),
          )
          .ignore();
      await shot(t, 'g3810-$p-$theme-3-conversazione', wait: 2500);
      if (_phone) {
        await t.tap(find.byKey(const Key('queue-banner-see')));
        await shot(t, 'g3810-$p-$theme-2-coda');
        await t.tap(find.byKey(const Key('queue-close')));
        await frames(t, 600);
      }
      nav.pop();
      await frames(t, 800);
      nav.push(MaterialPageRoute<void>(builder: (_) => const CommandsScreen())).ignore();
      await shot(t, 'g3810-$p-$theme-4-impostazione', wait: 2500);
      nav.pop();
      await frames(t, 800);
    }
  });
}
