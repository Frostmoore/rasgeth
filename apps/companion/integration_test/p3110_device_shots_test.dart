// 3.11 phase 2 in the real app on Linux, against the demo server (FakeProvider; DEMO_EMULATORS=1
// with DEMO_DEVICE_JPEG: the devices' screens are that picture, never a real emulator), light and
// dark: Settings › Emulators at the devices, then «Apri» on the first device that can open, its
// screen in the phone's frame, the same after taking control, and control given back.
// Run by tool/linux_shots.sh with
//   RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_EMULATORS=1 DEMO_DEVICE_JPEG=<a jpeg>"
//   RG_SCREEN=390x844 … integration_test/p3110_device_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/p3110_device_shots_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart' show DevicePlatform;
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/settings/system/emulators_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.11: a device screen', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final p = _phone ? 'telefono' : 'computer';
    // Whatever window opened by itself (what's new, an update) closes first.
    while (nav.canPop()) {
      nav.pop();
      await frames(t, 600);
    }

    const list = Key('sy-emulators-list');
    Future<void> scrollTo(Finder f) async {
      if (f.evaluate().isEmpty) {
        await t.scrollUntilVisible(
          f,
          250,
          scrollable: find
              .descendant(of: find.byKey(list), matching: find.byType(Scrollable))
              .first,
        );
      }
      await t.ensureVisible(f.first);
      // A little back up, so the part's title shows above the row.
      await t.drag(find.byKey(list), const Offset(0, 160));
      await frames(t, 500);
    }

    // The first «Apri» that can open (a phone waiting for its yes cannot).
    final open = find.byWidgetPredicate(
      (w) =>
          w is FilledButton &&
          w.onPressed != null &&
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('sy-em-open-'),
    );

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      unawaited(openEmulatorsSettings(ctx));
      await frames(t, 3000);
      await scrollTo(find.byKey(const Key('sy-em-devices')));
      await scrollTo(open);
      await shot(t, '01_dispositivi_$tag');

      await t.tap(open.first);
      await frames(t, 800);
      await waitFor(t, () => find.byKey(const Key('dv-frame')).evaluate().isNotEmpty);
      await frames(t, 1500);
      await shot(t, '02_schermo_$tag');

      await t.tap(find.byKey(const Key('dv-take')));
      await waitFor(
        t,
        () => find
            .byWidgetPredicate((w) => w is OutlinedButton && w.key == const Key('dv-take'))
            .evaluate()
            .isNotEmpty,
      );
      await frames(t, 1500);
      await shot(t, '03_controllo_$tag');

      // Control goes back before leaving.
      await t.tap(find.byKey(const Key('dv-take')));
      await waitFor(
        t,
        () => find
            .byWidgetPredicate((w) => w is FilledButton && w.key == const Key('dv-take'))
            .evaluate()
            .isNotEmpty,
      );
      await frames(t, 1000);
      await shot(t, '04_restituito_$tag');
      nav.pop();
      await frames(t, 800);
      nav.pop();
      await frames(t, 800);
    }
  });
}
