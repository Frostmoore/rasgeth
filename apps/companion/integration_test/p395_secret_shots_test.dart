// 3.9.5 in the real app on Linux, against the tests' fake Rasgeth: the secret warning with
// «Invia comunque» (2026-11-19), light and dark. With RG_SCREEN narrower than 600 the phone. Run
// with Xvfb like tool/linux_shots.sh:
//   RG_SCREEN=390x844 RG_SHOTS=<folder> flutter test integration_test/p395_secret_shots_test.dart -d linux
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

  testWidgets('3.9.5: the secret warning with «Invia comunque»', (t) async {
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
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
          ),
        )
        .ignore();
    await frames(t, 2500);
    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      await frames(t, 800);
      final field = find.byKey(const Key('composer-text')).last;
      await t.enterText(
        field,
        'il codice del pacco è Ab3dE5fG7hJ9kL1mN3pQ5rS7tU, puoi controllarlo?',
      );
      await t.tap(find.byKey(const Key('composer-send')).last);
      await frames(t, 1200);
      await shot(t, 'p395-$p-${dark ? 'scuro' : 'chiaro'}-avviso-segreto');
      await t.tap(find.byKey(const Key('secret-back')));
      await frames(t, 800);
    }
    app.setThemeMode(ThemeMode.light);
  });
}
