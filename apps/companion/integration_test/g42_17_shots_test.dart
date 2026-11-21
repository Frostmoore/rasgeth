// G42.17 in the real app on Linux, against the demo server (FakeProvider, no model), light and
// dark, phone and computer: Settings with the new rows and no «All settings», the setup wizard
// (welcome, role, machine, mode, names, safety, the list of every step, the summary; nothing is
// finished), import from other agents (the ways, looking on this computer), external agents and
// one being added, the history of changes, the full-text search.
// Run by tool/linux_shots.sh:
//   RG_SCREEN=390x844 … integration_test/g42_17_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_17_shots_test.dart
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
import 'package:rgcompanion/screens/full_search_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/acp_screen.dart';
import 'package:rgcompanion/settings/import_screen.dart';
import 'package:rgcompanion/settings/platform_screen.dart';
import 'package:rgcompanion/setup/wizard/wizard_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.17: the first start and the rest', (t) async {
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

    Future<void> tap(Key key, [int ms = 1500]) async {
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 300);
      await t.tap(find.byKey(key).first);
      await frames(t, ms);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-platform')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await shot(t, '01_impostazioni_$tag');
      nav.pop();
      await frames(t, 600);

      // The wizard, one step at a time (saved as the page does; never finished here).
      unawaited(openSetupWizard(ctx));
      await frames(t, 2500);
      await shot(t, '02_wizard_benvenuto_$tag');
      await tap(const Key('wz-next'), 2000);
      await shot(t, '03_wizard_ruolo_$tag');
      await tap(const Key('wz-next'), 2000);
      await shot(t, '04_wizard_macchina_$tag');
      await tap(const Key('wz-next'), 2000);
      await shot(t, '05_wizard_modo_$tag');
      await tap(const Key('wz-next'), 2000);
      await shot(t, '06_wizard_modelli_$tag');
      await tap(const Key('wz-counter'), 1500);
      await shot(t, '07_wizard_passi_$tag');
      await tap(const Key('wz-jump-wzNames'), 2000);
      await shot(t, '08_wizard_nomi_$tag');
      await tap(const Key('wz-counter'), 1500);
      await tap(const Key('wz-jump-wzSafety'), 2000);
      await shot(t, '09_wizard_sicurezza_$tag');
      await tap(const Key('wz-counter'), 1500);
      await tap(const Key('wz-jump-wzDone'), 2000);
      await shot(t, '10_wizard_fine_$tag');
      nav.pop();
      await frames(t, 800);

      unawaited(openImportSettings(ctx));
      await frames(t, 2000);
      await shot(t, '11_importa_$tag');
      await tap(const Key('imp-way-scan'));
      await shot(t, '12_importa_cerca_$tag');
      await tap(const Key('imp-scan-go'), 4000);
      await shot(t, '13_importa_trovato_$tag');
      nav.pop();
      await frames(t, 800);

      unawaited(openAcpSettings(ctx));
      await frames(t, 2000);
      await shot(t, '14_agenti_esterni_$tag');
      if (find.byKey(const Key('acp-add')).evaluate().isNotEmpty) {
        await tap(const Key('acp-add'));
        if (find.byKey(const Key('acp-preset-claude-code')).evaluate().isNotEmpty) {
          await tap(const Key('acp-preset-claude-code'), 800);
        }
        await shot(t, '15_agente_esterno_nuovo_$tag');
        nav.pop();
        await frames(t, 600);
      }
      nav.pop();
      await frames(t, 800);

      unawaited(openPlatformSettings(ctx));
      await frames(t, 2500);
      await shot(t, '16_storia_modifiche_$tag');
      nav.pop();
      await frames(t, 800);

      unawaited(openFullSearch(ctx));
      await frames(t, 1500);
      await t.enterText(find.byKey(const Key('fsr-field')), 'ciao');
      await tap(const Key('fsr-go'), 2500);
      await shot(t, '17_cerca_$tag');
      nav.pop();
      await frames(t, 800);
    }
  });
}
