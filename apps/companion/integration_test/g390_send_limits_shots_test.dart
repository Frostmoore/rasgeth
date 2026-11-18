// 3.9.0 in the real app on Linux, against the tests' fake Rasgeth: the spending and the limits in
// the conversations' header (the panel, a wider panel, the full conversation, dark theme), Ctrl+Enter
// from God's field, the shortcuts' list; with RG_SCREEN narrower than 600 the phone's header.
// Run with Xvfb like tool/linux_shots.sh (no demo server needed):
//   RG_SCREEN=1440x900 RG_SHOTS=<folder> flutter test integration_test/g390_send_limits_shots_test.dart -d linux
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

Map<String, dynamic> _budget(String scope, String id, double used, double limit) => {
  'scope': scope,
  'id': id,
  'limit': {'usd': limit},
  'used': {'usd': used, 'tokens': 0},
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> ctrl(WidgetTester t, LogicalKeyboardKey key) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(key);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await frames(t, 1500);
  }

  testWidgets('3.9.0: spending in the header, Ctrl+Enter', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    fake.budgets = [
      _budget('global', 'local', 25.2, 40),
      _budget('project', 'demo', 17.7, 5),
      _budget('agent', 'a3', 0.78, 1),
    ];
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 3000);

    Future<void> openFull() async {
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await frames(t, 2500);
    }

    if (_phone) {
      await openFull();
      await shot(t, 'g390-21-telefono-intestazione', wait: 1500);
      app.setThemeMode(ThemeMode.dark);
      await shot(t, 'g390-22-telefono-scuro', wait: 1500);
      return;
    }

    // God's field: Ctrl+Enter sends and opens the conversation in the panel.
    final god = find.descendant(
      of: find.byKey(const Key('desk-god-field')),
      matching: find.byType(TextField),
    );
    await t.tap(god);
    await t.enterText(god, 'Fai il punto della settimana');
    await shot(t, 'g390-10-god-scritto');
    await ctrl(t, LogicalKeyboardKey.enter);
    await shot(t, 'g390-11-pannello-limiti', wait: 2500);
    // A wider panel: the bars in a row.
    final desk = DeskScope.of(t.element(find.byKey(const Key('desk-panel'))));
    desk.setPanelWidth(760, 1440);
    await shot(t, 'g390-12-pannello-largo', wait: 1500);
    // The shortcuts' list.
    await ctrl(t, LogicalKeyboardKey.slash);
    await shot(t, 'g390-13-scorciatoie');
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(t, 800);
    // The full conversation; dark theme.
    await openFull();
    await shot(t, 'g390-14-conversazione-intera', wait: 1500);
    app.setThemeMode(ThemeMode.dark);
    await shot(t, 'g390-15-conversazione-scuro', wait: 1500);
    app.setThemeMode(ThemeMode.light);
  });
}
