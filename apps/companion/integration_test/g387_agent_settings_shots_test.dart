// G38.7 in the real app on Linux against the demo server (a real Rasgeth, FakeProvider): an
// agent's context menu (right click) and its settings panel on a computer, the long press's sheet
// and the whole settings screen on a phone, light and dark. Run by tool/linux_shots.sh:
//   RG_SCREEN=1440x900 … integration_test/g387_agent_settings_shots_test.dart
//   RG_SCREEN=430x932  … (the phone)
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

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1200]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  Future<void> tour(WidgetTester t, String theme) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 4000);
    final a = app.agents.firstWhere((x) => x.kind == AgentKind.agent && x.active);
    final where = _phone ? 'telefono' : 'computer';
    final groups = ['general', 'work', 'memory', 'limits', 'tools', 'knowledge'];

    Future<void> openSettings(String theme) async {
      if (_phone) {
        final card = find.byKey(Key('agent-${a.id}'));
        await t.ensureVisible(card);
        await frames(t, 1500);
        for (var i = 0; i < 3 && find.byKey(const Key('agent-settings')).evaluate().isEmpty; i++) {
          await t.longPress(card);
          await frames(t, 1500);
        }
        await shot(t, 'g387-$where-$theme-01-pressione-lunga');
        await tap(t, find.byKey(const Key('agent-settings')));
      } else {
        await t.tap(find.byKey(Key('tile-${a.id}')), buttons: kSecondaryButton);
        await frames(t, 800);
        await shot(t, 'g387-$where-$theme-01-clic-destro');
        await tap(t, find.byKey(const Key('agent-menu-settings')));
      }
    }

    {
      app.setThemeMode(theme == 'chiaro' ? ThemeMode.light : ThemeMode.dark);
      await frames(t, 1200);
      await openSettings(theme);
      for (final (i, g) in groups.indexed) {
        await tap(t, find.byKey(Key('agent-group-$g')), 1500);
        await shot(t, 'g387-$where-$theme-${(i + 2).toString().padLeft(2, '0')}-$g');
      }
      // Back where it was opened.
      await tap(t, find.byKey(Key(_phone ? 'agent-settings-back' : 'agent-settings-close')), 1200);
      // God has its own menu (no new face) and its own settings (never stopped).
      final god = app.god!;
      if (_phone) {
        await t.drag(find.byKey(const Key('team-scroll')), const Offset(0, 2000));
        await frames(t, 800);
        await t.longPress(find.byKey(const Key('team-god')));
        await frames(t, 1200);
        await shot(t, 'g387-$where-$theme-08-god-foglio');
        await tap(t, find.byKey(const Key('agent-settings')));
      } else {
        await t.tap(
          find
              .descendant(of: find.byKey(const Key('desk-god')), matching: find.byType(InkWell))
              .first,
          buttons: kSecondaryButton,
        );
        await frames(t, 800);
        await shot(t, 'g387-$where-$theme-08-god-menu');
        await tap(t, find.byKey(const Key('agent-menu-settings')));
      }
      await shot(t, 'g387-$where-$theme-09-god-generale');
      await tap(t, find.byKey(Key(_phone ? 'agent-settings-back' : 'agent-settings-close')), 1200);
      expect(god.kind, AgentKind.god);
    }
    app.setThemeMode(ThemeMode.light);
    await frames(t, 600);
  }

  testWidgets('G38.7: an agent\'s menu and settings, light', (t) => tour(t, 'chiaro'));
  testWidgets('G38.7: an agent\'s menu and settings, dark', (t) => tour(t, 'scuro'));
}
