// G42.14 in the real app on Linux, against the demo server (FakeProvider, its OS helper acted out:
// a USB disk, SSH, Tailscale already running; DEMO_SSH=1 two machines behind a fake SSH server;
// DEMO_HTTPS=1 HTTPS at home on; DEMO_UPDATE=breaking with DEMO_INSTALL=docker a breaking
// update; never a real machine), light and dark: the breaking update's gate (the backup made by
// itself, then the steps), Settings with the system's rows, access from outside home (password,
// code with its QR, the ways, one's own infrastructure, Pi-hole), Settings › System (the machine,
// the role, data and backups, HTTPS, SSH, updates), the SSH machines and a machine's window, the
// nodes with a code, the backup file.
// Run by tool/linux_shots.sh with
//   RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_SSH=1 DEMO_HTTPS=1 DEMO_UPDATE=breaking DEMO_INSTALL=docker"
//   RG_SCREEN=390x844 … integration_test/g42_14_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_14_shots_test.dart
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
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/system/backup_screen.dart';
import 'package:rgcompanion/settings/system/machines_screen.dart';
import 'package:rgcompanion/settings/system/nodes_screen.dart';
import 'package:rgcompanion/settings/system/remote_screen.dart';
import 'package:rgcompanion/settings/system/system_screen.dart';
import 'package:rgcompanion/settings/system/update_gate.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.14: the system', (t) async {
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

    // The breaking update's gate opened by itself when the app connected: closed for the tour.
    if (find.byKey(const Key('sy-gate')).evaluate().isNotEmpty) {
      nav.pop();
      await frames(t, 800);
    }

    Future<void> scrollTo(Key list, Key key) async {
      if (find.byKey(key).evaluate().isEmpty) {
        await t.scrollUntilVisible(
          find.byKey(key),
          250,
          scrollable: find
              .descendant(of: find.byKey(list), matching: find.byType(Scrollable))
              .first,
        );
      }
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 500);
    }

    Future<void> tap(Key key, [int ms = 1500]) async {
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 300);
      await t.tap(find.byKey(key).first);
      await frames(t, ms);
    }

    void back() => nav.pop();

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      // The breaking update: the backup by itself, where it is, then the steps.
      final status = await t.runAsync(() => app.client!.updateStatus());
      if (status != null && status.gate == 'breaking') {
        unawaited(openUpdateGate(ctx, status));
        await frames(t, 6000);
        await shot(t, '01_rottura_backup_$tag');
        if (find.byKey(const Key('sy-gate-next')).evaluate().isNotEmpty) {
          await scrollTo(const Key('sy-gate'), const Key('sy-gate-next'));
          await tap(const Key('sy-gate-next'));
          await shot(t, '02_rottura_passi_$tag');
        }
        back();
        await frames(t, 800);
      }

      // Settings with the system's rows.
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await scrollTo(const Key('server-settings'), const Key('settings-backup'));
      await shot(t, '03_impostazioni_sistema_$tag');
      back();
      await frames(t, 600);

      // Access from outside home.
      const rl = Key('sy-remote-list');
      unawaited(openRemoteSettings(ctx));
      await frames(t, 3000);
      await shot(t, '04_accesso_password_$tag');
      await scrollTo(rl, const Key('sy-code-start'));
      await tap(const Key('sy-code-start'), 2000);
      await scrollTo(rl, const Key('sy-qr'));
      await shot(t, '05_accesso_codice_qr_$tag');
      await scrollTo(rl, const Key('sy-ways'));
      await shot(t, '06_accesso_vie_$tag');
      await scrollTo(rl, const Key('sy-oi-fold'));
      await tap(const Key('sy-oi-fold'));
      await shot(t, '07_infrastruttura_$tag');
      await scrollTo(rl, const Key('sy-oi-part-home'));
      await tap(const Key('sy-oi-part-home'));
      await shot(t, '08_servizi_di_casa_$tag');
      await scrollTo(rl, const Key('sy-pihole'));
      await shot(t, '09_pihole_$tag');
      back();
      await frames(t, 800);

      // Settings › System.
      const sl = Key('sy-system-list');
      unawaited(openSystemSettings(ctx));
      await frames(t, 3500);
      await shot(t, '10_sistema_macchina_$tag');
      await scrollTo(sl, const Key('sy-backups'));
      await shot(t, '11_sistema_backup_$tag');
      if (find.byKey(const Key('sy-net-targets')).evaluate().isNotEmpty ||
          find.byKey(const Key('sy-dest')).evaluate().isNotEmpty) {
        await scrollTo(sl, const Key('sy-net-targets'));
        await shot(t, '12_sistema_rete_backup_$tag');
      }
      if (find.byKey(const Key('sy-https')).evaluate().isNotEmpty) {
        await scrollTo(sl, const Key('sy-https'));
        await shot(t, '13_sistema_https_$tag');
      }
      await scrollTo(sl, const Key('sy-ssh'));
      await shot(t, '14_sistema_ssh_$tag');
      back();
      await frames(t, 800);

      // The SSH machines and a machine's window.
      unawaited(openMachinesSettings(ctx));
      await frames(t, 3000);
      await shot(t, '15_macchine_$tag');
      await scrollTo(const Key('sy-machines-list'), const Key('sy-mc-new'));
      await tap(const Key('sy-mc-new'), 1500);
      await shot(t, '16_macchina_nuova_$tag');
      back();
      await frames(t, 600);
      back();
      await frames(t, 800);

      // The nodes, with a code for ten minutes.
      unawaited(openNodesSettings(ctx));
      await frames(t, 3000);
      await shot(t, '17_nodi_$tag');
      await scrollTo(const Key('sy-nodes-list'), const Key('sy-nd-add'));
      if (find.byKey(const Key('sy-nd-add-go')).evaluate().isNotEmpty) {
        await tap(const Key('sy-nd-add-go'), 2500);
      }
      await shot(t, '18_nodi_codice_$tag');
      back();
      await frames(t, 800);

      // The backup file.
      unawaited(openBackupSettings(ctx));
      await frames(t, 2500);
      await shot(t, '19_backup_$tag');
      back();
      await frames(t, 800);
    }
  });
}
