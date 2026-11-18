// Subscription or API key (G40.9b) in the real app against a real Rasgeth whose demo has both a
// Claude subscription and an Anthropic key (FakeProvider): «Settings of <name>» › default model,
// one entry per model with the way to choose and its line. Run by tool/linux_shots.sh with
//   RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_API_KEY=1" … integration_test/model_way_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the default model: subscription or API key', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t, 1500);
    await waitFor(t, () => find.byKey(const Key('open-server-settings')).evaluate().isNotEmpty);
    await t.tap(find.byKey(const Key('open-server-settings')));
    await frames(t, 1500);
    final model = find.byKey(const Key('settings-model'));
    await t.scrollUntilVisible(
      model,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('server-settings')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await shot(t, 'linux-way-01-settings');
    await t.tap(model);
    await frames(t, 1200);
    expect(find.byKey(const Key('model-anthropic/claude-opus-5-5')), findsOneWidget);
    await shot(t, 'linux-way-02-sheet-subscription');
    await t.tap(find.byKey(const Key('way-anthropic/claude-opus-5-5')).first);
    await frames(t, 600);
    await shot(t, 'linux-way-03-sheet-key');
    await t.tap(find.byKey(const Key('model-anthropic/claude-opus-5-5')));
    await frames(t, 2500);
    await shot(t, 'linux-way-04-chosen');
    expect(find.textContaining('· Chiave API'), findsWidgets);
  });
}
