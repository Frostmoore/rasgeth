// Echo (3.9.6) in the real app on Linux, against the demo server: the search over past
// conversations on the team's screen (phone) and as the panel's page (computer), light and dark:
// the box, the conversations found with their words marked, nothing found, one opened.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1":
//   RG_SCREEN=390x844 … integration_test/p396_echo_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/p396_echo_shots_test.dart
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
import 'package:rgcompanion/desktop/desk_controller.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.9.6: Echo', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2000);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final p = _phone ? 'telefono' : 'computer';

    Future<void> type(String words) async {
      await t.enterText(find.byKey(const Key('echo-box')), words);
      await frames(t, 400);
      await waitFor(
        t,
        () =>
            find.byKey(const Key('echo-results')).evaluate().isNotEmpty ||
            find.textContaining('Nessuna conversazione').evaluate().isNotEmpty,
      );
      await frames(t, 600);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';
      if (!_phone) {
        DeskScope.read(t.element(find.byKey(const Key('view-team'))))
            .show(const PanelPage(PanelScreen.echo));
        await frames(t, 1200);
      }
      await shot(t, 'p396_${tag}_01_casella');
      await type('report');
      await shot(t, 'p396_${tag}_02_risultati');
      await type('zzzqqq');
      await shot(t, 'p396_${tag}_03_niente');
      await type('report');
      await t.tap(
        find.byKey(const Key('echo-results')).evaluate().isEmpty
            ? find.byType(InkWell).first
            : find
                  .descendant(
                    of: find.byKey(const Key('echo-results')),
                    matching: find.byType(InkWell),
                  )
                  .first,
      );
      await frames(t, 2500);
      await shot(t, 'p396_${tag}_04_aperta');
      if (_phone) {
        nav.pop();
        await frames(t, 800);
      }
      // On a computer the panel shows the conversation now: the next round opens the search again.
      if (find.byKey(const Key('echo-box')).evaluate().isNotEmpty) {
        await t.enterText(find.byKey(const Key('echo-box')), '');
        await frames(t, 500);
      }
    }
  });
}
