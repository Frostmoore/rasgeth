// 3.8.3 in the real app on Linux, against the tests' fake RedGiant: the conversations «full
// window» with the mascots' bar (the panel's button, another agent from the bar, a name on hover,
// dark theme, back to the panel). Run with Xvfb like tool/linux_shots.sh (no demo server needed):
//   RG_SCREEN=1440x900 RG_SHOTS=<folder> flutter test integration_test/g383_full_window_shots_test.dart -d linux
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _size = (Platform.environment['RG_SCREEN'] ?? '1440x900');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.8.3: full window with the mascots', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    fake.agentOverrides['a3'] = {'projectId': 'demo'};
    fake.agentOverrides['a2'] = {'projectId': 'demo'};
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 3000);
    final s = _size;

    await t.tap(find.byKey(const Key('tile-a3')));
    await frames(t, 2500);
    await shot(t, 'g383-$s-01-pannello');
    await t.tap(find.byKey(const Key('panel-full')));
    await frames(t, 2000);
    await shot(t, 'g383-$s-02-tutta-finestra', wait: 1500);
    await t.tap(find.byKey(const Key('rail-a0')));
    await frames(t, 2500);
    await shot(t, 'g383-$s-03-god', wait: 1500);
    // A name on hover.
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: t.getCenter(find.byKey(const Key('rail-a2'))));
    await frames(t, 1500);
    await shot(t, 'g383-$s-04-nome-al-passaggio');
    await mouse.moveTo(const Offset(700, 400));
    await mouse.removePointer();
    app.setThemeMode(ThemeMode.dark);
    await frames(t, 1500);
    await shot(t, 'g383-$s-05-scuro', wait: 1500);
    await t.tap(find.byKey(const Key('panel-unfull')));
    await frames(t, 1500);
    await shot(t, 'g383-$s-06-scuro-pannello', wait: 1500);
    app.setThemeMode(ThemeMode.light);
    await frames(t, 800);
  });
}
