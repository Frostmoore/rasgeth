// p3.8.9 in the real app on Linux, against the demo server with DEMO_REQWORDS=1 (FakeProvider, no
// real model): a request's plain line first (a script written and run, a truly dangerous delete),
// the critical screen with its way out, and the same screen answered elsewhere. RG_SCREEN narrower
// than 600 is the phone:
//   RG_SCREEN=400x860 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_REQWORDS=1" \
//     bash tool/linux_shots.sh <folder> integration_test/g389_req_words_shots_test.dart
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

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1280x800').split('x').first) ?? 1280) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('p3.8.9: requests in plain words, and a way out of the critical screen', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.live.approvals.length >= 2);
    final d = _phone ? 'phone' : 'computer';
    await frames(t, 1500);
    await shot(t, '$d-01-start');
    final inbox = find.byKey(const Key('tab-inbox'));
    if (inbox.evaluate().isNotEmpty) {
      await t.tap(inbox);
      await frames(t);
      await shot(t, '$d-02-for-you');
    }
    final critical = app.live.approvals.firstWhere((r) => r.isCritical);
    final open = [
      Key('open-${critical.requestId}'),
      Key('desk-critical-open-${critical.requestId}'),
    ].map(find.byKey).where((f) => f.evaluate().isNotEmpty).firstOrNull;
    if (open != null) {
      await t.tap(open.first);
      await frames(t);
      await shot(t, '$d-03-critical');
      // Answered from the page meanwhile: the screen says so and offers «Close».
      app.live.apply({
        'type': 'permission.closed',
        'requestId': critical.requestId,
        'decision': 'deny',
        'via': 'web',
      });
      await frames(t, 600);
      await shot(t, '$d-04-critical-answered-elsewhere', wait: 300);
      await t.tap(find.byKey(const Key('critical-done-close')));
      await frames(t);
      await shot(t, '$d-05-after-close');
    }
  });
}
