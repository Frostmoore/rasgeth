// G40.17's figures in the real app against a real RedGiant (the demo server, FakeProvider): under
// each answer the page's line (read, cache, generated, context, prefill, generation, tok/s, time)
// with its bar; short on a phone until touched, whole on a computer. Run by tool/linux_shots.sh:
//   RG_SCREEN=430x900 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_PRODUCTS=1" \
//     … integration_test/g382_meta_shots_test.dart          (phone)
//   RG_SCREEN=1280x800 …                                    (computer)
// RG_LOCALE=en for the English texts.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _locale = Platform.environment['RG_LOCALE'] ?? 'it';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G40.17: the figures under each answer', (t) async {
    final phone = t.view.physicalSize.width / t.view.devicePixelRatio < 600;
    if (phone) debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = Locale(_locale);
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t, 1500);
    final p = 'g382-${phone ? 'telefono' : 'computer'}-$_locale';

    await t.tap(find.byKey(const Key('tab-chat')));
    await frames(t, 2500);
    await t.tap(find.textContaining('moka').first);
    await frames(t, 3000);
    final line = find.byKey(Key(phone ? 'metrics-compact' : 'metrics'));
    await waitFor(t, () => line.evaluate().isNotEmpty);
    // The list is upside down: the first in the tree is the newest answer.
    await t.ensureVisible(line.first);
    await frames(t, 1200);
    await shot(t, '$p-01-risposta');
    if (phone) {
      await t.tap(line.first);
      await frames(t, 1200);
      await t.ensureVisible(find.byKey(const Key('metrics-open')));
      await frames(t, 800);
      await shot(t, '$p-02-aperta');
    } else {
      // The page's title: the model, the times, where they come from.
      final g = await t.createGesture(kind: PointerDeviceKind.mouse);
      await g.addPointer(location: t.getCenter(line.first));
      await g.moveTo(t.getCenter(line.first));
      await frames(t, 1500);
      await shot(t, '$p-02-dettagli');
      await g.removePointer();
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
