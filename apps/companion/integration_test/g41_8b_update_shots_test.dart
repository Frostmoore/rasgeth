// G41.8b: the window of the app's own update, on Linux over the room connected to a real Rasgeth
// (the demo), light and dark: a version found, the download with its bar, ready to restart, a
// wrong signature, and the two words after a restart (updated, gone back). GitHub is a fake with
// the throwaway key of tool/update_vectors.mjs; nothing is installed. RG_SHOTS names the folder.
//   bash tool/linux_shots.sh <folder> integration_test/g41_8b_update_shots_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/brand.dart';
import 'package:rgcompanion/app_update/install.dart';
import 'package:rgcompanion/app_update/signature.dart';
import 'package:rgcompanion/app_update/swap.dart';
import 'package:rgcompanion/app_update/update_window.dart';
import 'package:rgcompanion/app_update/updater.dart';
import 'package:rgcompanion/desktop/desktop_shell.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
const _api = 'https://api.example';
const _dl = 'https://dl.example/v3.9.0';
const _mb = 1024 * 1024;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app\'s own update window', (t) async {
    final v = jsonDecode(
      File(
        Platform.environment['RG_UPDATE_VECTORS'] ??
            '${Directory.current.path}/test/fixtures/update_vectors.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final key = UpdateKey(v['modulus'] as String, v['exponent'] as String);
    final files = (v['files'] as Map<String, dynamic>).cast<String, String>();
    final tmp = Directory.systemTemp.createTempSync('g41-8b-shots-');

    var held = StreamController<List<int>>();
    var sig = v['sig'] as String;
    http.Client github() => MockClient.streaming((req, _) async {
      final u = req.url.toString();
      http.StreamedResponse text(List<int> b) =>
          http.StreamedResponse(Stream.value(b), 200, contentLength: b.length);
      if (u.endsWith('/releases/latest')) {
        return text(
          utf8.encode(
            jsonEncode({
              'tag_name': 'v3.9.0',
              'assets': [
                for (final n in [kSumsAsset, '$kSumsAsset.sig', ...files.keys])
                  {'name': n, 'browser_download_url': '$_dl/$n', 'size': 48 * _mb},
              ],
            }),
          ),
        );
      }
      if (u == '$_dl/$kSumsAsset') return text(utf8.encode(v['sums'] as String));
      if (u == '$_dl/$kSumsAsset.sig') return text(utf8.encode(sig));
      return http.StreamedResponse(held.stream, 200, contentLength: 48 * _mb);
    });

    var clock = DateTime(2026, 11, 18, 3);
    AppUpdater updater() => AppUpdater(
      spot: InstallSpot(system: 'linux', dir: '${tmp.path}/app', exe: '${tmp.path}/app/x'),
      current: '3.8.14',
      prefs: MemoryAppPrefs(),
      folder: () async => '${tmp.path}/updates',
      client: github(),
      now: () => clock,
      key: key,
      apiBase: _api,
      unpack: (a, into) async => into,
      swap: (_, _) async {},
      quit: () {},
    );

    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => find.byType(DesktopShell).evaluate().isNotEmpty);

    Future<void> open(AppUpdater u) async {
      final ctx = t.element(find.byType(DesktopShell));
      unawaited(openAppUpdateWindow(ctx, u));
      await frames(t, 500);
    }

    Future<void> close() async {
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.pop();
      await frames(t, 500);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      sig = v['sig'] as String;

      // 1. Found.
      final u = updater();
      await t.runAsync(u.check);
      await open(u);
      await shot(t, 'g41-8b-$theme-01-trovata');

      // 2. Downloading: 19 MB of 48 at about 6 MB/s.
      held = StreamController<List<int>>();
      final going = u.download();
      await t.runAsync(pumpEventQueue);
      final chunk = List.filled(_mb, 1);
      for (var i = 0; i < 19; i++) {
        clock = clock.add(const Duration(milliseconds: 160));
        held.add(chunk);
        await t.runAsync(pumpEventQueue);
      }
      await shot(t, 'g41-8b-$theme-02-scarica');

      // 3. Cancelled, then the signed file is here.
      await t.runAsync(u.cancel);
      await t.runAsync(() => going);
      unawaited(held.close());
      final sep = Platform.pathSeparator;
      final dir = Directory('${tmp.path}${sep}updates${sep}3.9.0')..createSync(recursive: true);
      File('${dir.path}$sep$kLinuxTarAsset').writeAsStringSync(files[kLinuxTarAsset]!);
      await t.runAsync(u.download);
      await shot(t, 'g41-8b-$theme-03-pronta');
      await close();

      // 4. A wrong signature.
      sig = v['otherKeySig'] as String;
      final bad = updater();
      await t.runAsync(bad.check);
      await open(bad);
      await shot(t, 'g41-8b-$theme-04-firma-sbagliata');
      await close();

      // 5. After a good restart, and 6. after going back.
      for (final (name, args) in [
        ('05-aggiornata', ['${kUpdatedFromArg}3.8.12']),
        ('06-tornata-indietro', ['${kUpdateFailedArg}3.9.0']),
      ]) {
        final n = updater();
        await t.runAsync(() => n.started(UpdateStart.parse(args)));
        await open(n);
        await shot(t, 'g41-8b-$theme-$name');
        await close();
      }
      tmp.listSync().forEach((e) => e.deleteSync(recursive: true));
    }
    tmp.deleteSync(recursive: true);
  });
}
