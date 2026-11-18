// 3.8.7 in the real app on Linux, against the tests' fake Rasgeth: a turn from the send to the full
// answer, paced as the demo server's slow God (REDGIANT_DEMO_SLOW: 42k tokens of context, 75% from
// the cache, read in 16 steps of 0.3 s; reasoning, the answer, a tool, a second reading, the end),
// light and dark. With RG_SCREEN narrower than 600 the phone. Run with Xvfb (no demo server needed):
//   RG_SCREEN=390x844 RG_SHOTS=<folder> flutter test integration_test/g387_turn_shots_test.dart -d linux
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.8.7: the turn as the page shows it', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 3000);
    final p = _phone ? 'telefono' : 'computer';
    t
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
          ),
        )
        .ignore();
    await frames(t, 2500);

    const total = 42000, cached = 31500, steps = 16, stepMs = 300;
    Future<void> read(String theme, int call, {required List<int> shootAt}) async {
      for (var i = 0; i <= steps; i++) {
        fake.turnPrefill(
          's1',
          total: total,
          cached: cached,
          processed: (cached + (total - cached) * i / steps).round(),
          ms: i * stepMs,
        );
        if (shootAt.contains(i)) {
          await shot(t, 'g387-$p-$theme-$call-legge-$i', wait: stepMs);
        } else {
          await frames(t, stepMs);
        }
      }
    }

    Future<void> write(String kind, String text) async {
      for (final piece in RegExp(r'\S+\s*').allMatches(text)) {
        fake.turnDelta('s1', kind, piece[0]!);
        await frames(t, 60);
      }
    }

    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      fake.userMessage('s1', 'Fai il punto della settimana');
      fake.turnStart('s1');
      await shot(t, 'g387-$p-$theme-1-inviato', wait: 300);
      await read(theme, 1, shootAt: [8]);
      const thinking =
          'Guardo prima le attività aperte e il calendario, poi metto insieme le tre cose fatte e '
          'quelle ferme.';
      await write('thinking', thinking);
      await shot(t, 'g387-$p-$theme-1-ragiona', wait: 200);
      const first = 'Guardo le attività aperte e il calendario della settimana.';
      await write('text', first);
      await shot(t, 'g387-$p-$theme-1-scrive', wait: 200);
      fake.turnTool(
        's1',
        name: 'glob',
        input: {'pattern': '**/*'},
        output: 'notes/settimana.md\ncalendar.ics',
        thinking: thinking,
        text: first,
      );
      await read(theme, 2, shootAt: [4]);
      const answer =
          'Ecco il punto della settimana:\n\n- **fatto**: preventivo inviato, sito aggiornato\n'
          '- **fermo**: il rinnovo del dominio aspetta te\n\nVenerdì: la riunione delle 10.';
      await write('text', answer);
      await shot(t, 'g387-$p-$theme-2-scrive', wait: 200);
      fake.turnEnd(
        's1',
        text: answer,
        metrics: {
          'startedAt': '2026-11-17T10:00:00.000Z',
          'firstTokenAt': '2026-11-17T10:00:04.900Z',
          'endedAt': '2026-11-17T10:00:07.400Z',
          'inputTokens': total,
          'cachedReadTokens': cached,
          'outputTokens': 64,
          'contextUsed': total + 64,
          'contextWindow': 200000,
          'prefillMs': 4800,
          'decodeMs': 2500,
          'tokPerSec': 25.6,
        },
      );
      await shot(t, 'g387-$p-$theme-3-fine', wait: 1200);
    }
    app.setThemeMode(ThemeMode.light);
  });
}
