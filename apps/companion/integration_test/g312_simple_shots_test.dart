// 3.12 in the real app on Linux, against the demo server with God's topics (DEMO_TOPICS=1: the
// installation opens simple, greets Riccardo), light and dark: «Oggi», a topic read as a document
// with its decision, «Sposta», the archive and the settings — the board «B · Assistente».
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_TOPICS=1":
//   RG_SCREEN=390x844 … integration_test/g312_simple_shots_test.dart
//   RG_SCREEN=1280x820 … integration_test/g312_simple_shots_test.dart
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
import 'package:rgcompanion/theme/colors.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1280x820').split('x').first) ?? 1280) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.12: the simple interface', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    app.setAccent(RgAccent.blue);
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.simpleUi && app.simple.loaded);
    await frames(t, 1500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final p = _phone ? 'telefono' : 'computer';

    Future<void> tap(Key key, [int ms = 1500]) async {
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 300);
      await t.tap(find.byKey(key).first);
      await frames(t, ms);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 800);
      final tag = '${p}_$theme';
      await shot(t, 'app_${tag}_01_oggi');

      final trip = app.simple.topics.firstWhere((x) => x.title == 'Vacanza in Sardegna');
      await tap(Key('topic-${trip.id}'), 2500);
      await shot(t, 'app_${tag}_02_conversazione');

      final move = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('routed-move-'),
      );
      await t.tap(move.first);
      await frames(t, 1500);
      await shot(t, 'app_${tag}_03_sposta');
      nav.pop();
      await frames(t, 800);
      nav.pop();
      await frames(t, 800);

      await tap(const Key('simple-archive'), 1500);
      await shot(t, 'app_${tag}_04_archivio');
      nav.pop();
      await frames(t, 800);

      await tap(const Key('simple-settings'), 1500);
      await shot(t, 'app_${tag}_05_impostazioni');
      nav.pop();
      await frames(t, 800);
    }
  });
}
