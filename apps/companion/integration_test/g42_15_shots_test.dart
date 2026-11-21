// G42.15 in the real app on Linux, against the demo server with keys of Anthropic and OpenAI
// (DEMO_KEYS=1) and its FakeProvider models, light and dark: Settings › Models and
// subscriptions (the ways, the default model, who uses which), the keys' window, Claude's window,
// the model sheet by provider and way with the newest first, the model on this computer (the
// machine, the engine, the models) and a model's window.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_KEYS=1":
//   RG_SCREEN=390x844 … integration_test/g42_15_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_15_shots_test.dart
import 'dart:async';
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
import 'package:rgcompanion/settings/models/models_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.15: models and subscriptions', (t) async {
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
    final ctx = nav.context;
    final p = _phone ? 'telefono' : 'computer';

    Future<void> scrollTo(Key key) async {
      if (find.byKey(key).evaluate().isEmpty) {
        await t.scrollUntilVisible(
          find.byKey(key),
          250,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('models-page')),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 500);
    }

    Future<void> tap(Key key, [int ms = 1500]) async {
      await scrollTo(key);
      await t.tap(find.byKey(key).first);
      await frames(t, ms);
    }

    void back() => nav.pop();

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      unawaited(openModelsSettings(ctx, openUrl: (_) async => true));
      await frames(t, 3500);
      await shot(t, '01_modelli_$tag');
      await tap(const Key('way-keys'), 2000);
      await shot(t, '02_chiavi_$tag');
      back();
      await frames(t, 800);
      await tap(const Key('way-claude'), 2000);
      await shot(t, '03_claude_$tag');
      back();
      await frames(t, 800);
      await scrollTo(const Key('role-backup'));
      await shot(t, '04_chi_usa_$tag');
      await tap(const Key('models-default'), 2000);
      await shot(t, '05_scelta_modello_$tag');
      back();
      await frames(t, 800);
      await scrollTo(const Key('lm-machine'));
      await shot(t, '06_locale_$tag');
      final card = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('lm-card-'),
      );
      if (card.evaluate().isNotEmpty) {
        await t.ensureVisible(card.first);
        await frames(t, 400);
        await shot(t, '07_locale_modelli_$tag');
        await t.tap(card.first);
        await frames(t, 1500);
        await shot(t, '08_locale_modello_$tag');
        back();
        await frames(t, 800);
      }
      back();
      await frames(t, 800);
    }
  });
}
