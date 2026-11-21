// G42.13 in the real app on Linux, against the demo server with the keys of a version before
// moved into the keychain (DEMO_KEYS=1: a Telegram bot, Matrix on, a mailbox), light and dark:
// «Settings of <name>» with the new rows, Settings › Telegram (the steps, the chat Telegram will
// show), Settings › Chats (the squares, a platform's window with its steps, Matrix on), the
// mailboxes in Settings › Automations and a mailbox's window.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_KEYS=1":
//   RG_SCREEN=390x844 … integration_test/g42_13_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_13_shots_test.dart
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
import 'package:rgcompanion/settings/automations/automations_screen.dart';
import 'package:rgcompanion/settings/channels/chats_screen.dart';
import 'package:rgcompanion/settings/channels/telegram_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.13: channels and mailboxes', (t) async {
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
        await t.scrollUntilVisible(find.byKey(key), 250, scrollable: find.byType(Scrollable).last);
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

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-models')),
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

      unawaited(openTelegramSettings(ctx));
      await frames(t, 3500);
      await shot(t, '02_telegram_$tag');
      await scrollTo(const Key('tg-step-3'));
      await shot(t, '03_telegram_passo3_$tag');
      back();
      await frames(t, 800);

      unawaited(openChatPlatforms(ctx));
      await frames(t, 3000);
      await shot(t, '04_chat_$tag');
      await tap(const Key('chat-tile-teams'), 2000);
      await shot(t, '05_chat_teams_$tag');
      back();
      await frames(t, 800);
      await tap(const Key('chat-tile-matrix'), 2500);
      await shot(t, '06_chat_matrix_acceso_$tag');
      back();
      await frames(t, 800);
      back();
      await frames(t, 800);

      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const AutomationsScreen())));
      await frames(t, 3000);
      await scrollTo(const Key('au-sources'));
      await shot(t, '07_caselle_$tag');
      final box = find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('mailbox-box'),
      );
      if (box.evaluate().isNotEmpty) {
        await t.tap(box.first);
        await frames(t, 1500);
        await shot(t, '08_casella_$tag');
        back();
        await frames(t, 800);
      }
      await tap(const Key('mailbox-add'), 1500);
      await shot(t, '09_casella_nuova_$tag');
      back();
      await frames(t, 800);
      back();
      await frames(t, 800);
    }
  });
}
