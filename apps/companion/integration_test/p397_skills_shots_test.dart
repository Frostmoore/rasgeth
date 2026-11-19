// 3.9.7 in the real app on Linux, against the demo server with a skill improved with use
// («release-notes»: the person's first version, an agent's second approved by the person, a third
// waiting with its reason), light and dark: the way in from Settings, Settings › Skills (the
// version waiting with what changes), the installed skill's versions, the comparison with the one
// in use, and «Go back to version 1» asked first.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1":
//   RG_SCREEN=390x844 … integration_test/p397_skills_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/p397_skills_shots_test.dart
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
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/skills_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.9.7: skills that improve with use', (t) async {
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

    Future<void> scrollTo(Key key, {Key within = const Key('skills-settings')}) async {
      if (find.byKey(key).evaluate().isEmpty) {
        await t.scrollUntilVisible(
          find.byKey(key),
          250,
          scrollable: find
              .descendant(of: find.byKey(within), matching: find.byType(Scrollable))
              .first,
        );
      }
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 500);
    }

    void back() => nav.pop();

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-skills')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await shot(t, '01_impostazioni_$tag');
      back();
      await frames(t, 600);

      unawaited(openSkills(ctx));
      await frames(t, 3000);
      await shot(t, '02_skill_$tag');
      final waiting = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && '${(w.key! as ValueKey<String>).value}'.startsWith('skill-diff-'),
      );
      if (waiting.evaluate().isNotEmpty) {
        await t.ensureVisible(waiting.first);
        await frames(t, 600);
      }
      await shot(t, '03_versione_in_attesa_$tag');
      await scrollTo(const Key('skill-installed-release-notes'));
      await t.tap(find.byKey(const Key('skill-installed-release-notes')));
      await frames(t, 2500);
      await shot(t, '04_versioni_$tag');
      await t.ensureVisible(find.byKey(const Key('skill-compare-1')));
      await frames(t, 400);
      await t.tap(find.byKey(const Key('skill-compare-1')));
      await frames(t, 2000);
      await shot(t, '05_confronto_$tag');
      await t.ensureVisible(find.byKey(const Key('skill-rollback-1')));
      await frames(t, 400);
      await t.tap(find.byKey(const Key('skill-rollback-1')));
      await frames(t, 1500);
      await shot(t, '06_torna_alla_versione_$tag');
      // No: the shots never change the demo.
      Navigator.of(t.element(find.byKey(const Key('skill-rollback-yes')))).pop(false);
      await frames(t, 800);
      Navigator.of(t.element(find.byKey(const Key('skill-history')))).pop();
      await frames(t, 800);
      back();
      await frames(t, 800);
    }
  });
}
