// 3.9.8: a server whose token is gone (the keystore lost after the rename on Windows) stays in
// the list and asks to be paired again: «da abbinare di nuovo» and «Abbina di nuovo», then the
// password, then connected again. Native, on Linux against a real Rasgeth (the demo, no real
// model), light and dark. Run in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for the
// phone's size, RG_SHOT_TAG phone|computer), RG_SHOTS the folder for the pictures.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pairing a server again on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    app.renameDue = false;

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      final s = app.server!;
      // The token gone, as on the person's Windows after the rename.
      await t.runAsync(() async {
        await app.tokens.delete(s.id);
        await app.useServer(s);
      });
      app.setTab(AppTab.you);
      await frames(t, 1500);
      final tag = '${_tag}_$theme';
      final button = find.byKey(Key('pair-again-${s.id}'));
      final list = find.byKey(const Key('you-list'));
      await t.scrollUntilVisible(
        button,
        200,
        scrollable: find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      await frames(t, 500);
      await shot(t, '01_da_abbinare_$tag');
      await t.tap(button);
      await frames(t, 800);
      await t.enterText(find.byKey(const Key('pair-again-password')), _password);
      await shot(t, '02_password_$tag');
      await t.tap(find.byKey(const Key('pair-again-yes')));
      await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
      await frames(t, 1500);
      await shot(t, '03_ricollegato_$tag');
      expect(app.servers, hasLength(1));
    }
  });
}
