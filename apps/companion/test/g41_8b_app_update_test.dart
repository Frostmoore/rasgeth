// G41.8b: the app on its own updates itself. The version's choice, the file's name and the install
// as tables; the signed list (a throwaway key from release.yml's own signer, tool/update_vectors.mjs:
// a wrong signature is refused and nothing else is fetched); the download against a fake GitHub
// with its bar, its cancel and a file that is not the signed one; «Update and restart» with where
// the person was; the Linux helper run for real on fake folders (replaced, and put back when the
// new version does not start); the Windows helper's text; the window's states.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/brand.dart';
import 'package:rgcompanion/app_update/choice.dart';
import 'package:rgcompanion/app_update/install.dart';
import 'package:rgcompanion/app_update/signature.dart';
import 'package:rgcompanion/app_update/swap.dart';
import 'package:rgcompanion/app_update/update_window.dart';
import 'package:rgcompanion/app_update/updater.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/theme/theme.dart';

import 'repo_files.dart';

final _v = jsonDecode(
  File('test/fixtures/update_vectors.json').readAsStringSync(),
) as Map<String, dynamic>;
final _key = UpdateKey(_v['modulus'] as String, _v['exponent'] as String);
final _sums = utf8.encode(_v['sums'] as String);
final _files = (_v['files'] as Map<String, dynamic>).cast<String, String>();

const _api = 'https://api.example';
const _dl = 'https://dl.example/v3.9.0';

Map<String, dynamic> _release(String tag, {bool sig = true, List<String>? names}) => {
  'tag_name': tag,
  'assets': [
    for (final n in [kSumsAsset, if (sig) '$kSumsAsset.sig', ...(names ?? _files.keys)])
      {'name': n, 'browser_download_url': '$_dl/$n', 'size': (_files[n] ?? '').length},
  ],
};

/// A fake GitHub: the release's JSON, its list, its signature and its packages; every URL asked.
class _Github {
  _Github({this.sig, this.body, this.latestFails = false, this.releaseSig = true});

  final String? sig;
  final Map<String, String>? body;
  final bool latestFails;
  final bool releaseSig;
  final asked = <String>[];

  /// A download that waits for the test (the cancel).
  StreamController<List<int>>? held;

  http.Client client() => MockClient.streaming((req, _) async {
    final u = req.url.toString();
    asked.add(u);
    http.StreamedResponse text(List<int> b, [int status = 200]) =>
        http.StreamedResponse(Stream.value(b), status, contentLength: b.length);
    if (u == '$_api/repos/$kReleaseRepo/releases/latest') {
      if (latestFails) throw const SocketException('offline');
      return text(utf8.encode(jsonEncode(_release('v3.9.0', sig: releaseSig))));
    }
    if (u.startsWith('$_api/repos/$kReleaseRepo/releases/tags/')) {
      return text(utf8.encode(jsonEncode(_release(u.split('/').last, sig: releaseSig))));
    }
    if (u == '$_dl/$kSumsAsset') return text(_sums);
    if (u == '$_dl/$kSumsAsset.sig') return text(utf8.encode(sig ?? _v['sig'] as String));
    for (final n in _files.keys) {
      if (u == '$_dl/$n') {
        final h = held;
        if (h != null) {
          return http.StreamedResponse(h.stream, 200, contentLength: 1000);
        }
        return text(utf8.encode((body ?? _files)[n]!));
      }
    }
    return text(const [], 404);
  });
}

class _Clock {
  DateTime t = DateTime(2026, 11, 18, 3);
  DateTime now() => t;
}

/// Paths compared whatever the separator (the app joins with Windows' `\\`, the test writes `/`).
String _slash(String path) => path.replaceAll(r'\', '/');

const _updateKey = 'packaging/windows/launcher/UpdateKey.cs';

void main() {
  group('the version offered (table)', () {
    final rows = <(String, Map<String, Object?>, UpdateChoice)>[
      ('a build from the sources', {'current': ''}, const UpdateChoice(UpdateWhy.dev)),
      ('a pre-release build', {'current': '3.9.0-rc1'}, const UpdateChoice(UpdateWhy.dev)),
      (
        'newer on GitHub',
        {'current': '3.8.14', 'latest': 'v3.9.0'},
        const UpdateChoice(UpdateWhy.latest, '3.9.0'),
      ),
      (
        'numbers, not text (3.10 > 3.9)',
        {'current': '3.9.4', 'latest': 'v3.10.0'},
        const UpdateChoice(UpdateWhy.latest, '3.10.0'),
      ),
      (
        'the same',
        {'current': '3.9.0', 'latest': 'v3.9.0'},
        const UpdateChoice(UpdateWhy.upToDate),
      ),
      (
        'older on GitHub (a newer local build)',
        {'current': '3.9.1', 'latest': 'v3.9.0'},
        const UpdateChoice(UpdateWhy.upToDate),
      ),
      (
        'skipped by the person',
        {'current': '3.8.14', 'latest': 'v3.9.0', 'skipped': '3.9.0'},
        const UpdateChoice(UpdateWhy.skipped),
      ),
      (
        'skipped, but asked from the menu',
        {'current': '3.8.14', 'latest': 'v3.9.0', 'skipped': '3.9.0', 'asked': true},
        const UpdateChoice(UpdateWhy.latest, '3.9.0'),
      ),
      (
        'an older skip does not hide a newer one',
        {'current': '3.8.14', 'latest': 'v3.9.1', 'skipped': '3.9.0'},
        const UpdateChoice(UpdateWhy.latest, '3.9.1'),
      ),
      (
        'GitHub wins over the Rasgeth',
        {'current': '3.8.14', 'latest': 'v3.9.1', 'server': '3.9.0'},
        const UpdateChoice(UpdateWhy.latest, '3.9.1'),
      ),
      (
        'GitHub unreadable: the Rasgeth\'s newer version',
        {'current': '3.8.14', 'server': '3.9.0'},
        const UpdateChoice(UpdateWhy.server, '3.9.0'),
      ),
      (
        'GitHub unreadable, Rasgeth older',
        {'current': '3.9.0', 'server': '3.8.12'},
        const UpdateChoice(UpdateWhy.unknown),
      ),
      (
        'GitHub unreadable, Rasgeth from the sources',
        {'current': '3.9.0', 'server': null},
        const UpdateChoice(UpdateWhy.unknown),
      ),
      (
        'a pre-release on GitHub is not a version',
        {'current': '3.9.0', 'latest': 'v3.9.1-rc1'},
        const UpdateChoice(UpdateWhy.unknown),
      ),
      (
        'the Rasgeth\'s version, skipped',
        {'current': '3.8.14', 'server': '3.9.0', 'skipped': '3.9.0'},
        const UpdateChoice(UpdateWhy.skipped),
      ),
    ];
    for (final (name, a, want) in rows) {
      test(name, () {
        expect(
          chooseUpdate(
            current: a['current'] as String,
            latest: a['latest'] as String?,
            server: a['server'] as String?,
            skipped: a['skipped'] as String?,
            asked: a['asked'] as bool? ?? false,
          ),
          want,
        );
      });
    }
  });

  test('the package of each system, also after a rename (table)', () {
    final rows = <(String, List<String>, String?)>[
      ('windows', [kWindowsSetupAsset, kLinuxTarAsset], kWindowsSetupAsset),
      ('linux', [kWindowsSetupAsset, kLinuxTarAsset], kLinuxTarAsset),
      ('windows', ['Rasgeth-Setup.exe', 'rasgeth-linux-x64.tar.gz'], 'Rasgeth-Setup.exe'),
      ('linux', ['Rasgeth-Setup.exe', 'rasgeth-linux-x64.tar.gz'], 'rasgeth-linux-x64.tar.gz'),
      ('windows', ['A-Setup.exe', 'B-Setup.exe'], null),
      ('linux', [kWindowsSetupAsset], null),
      ('macos', [kWindowsSetupAsset, kLinuxTarAsset], null),
    ];
    for (final (system, listed, want) in rows) {
      expect(assetFor(system, listed), want, reason: '$system $listed');
    }
  });

  test('which install updates itself (table)', () {
    const win = r'C:\Users\Pixel\AppData\Local\Programs\Rasgeth App';
    const red = r'C:\Program Files\Rasgeth';
    const home = '/home/pixel';
    final rows = <(String, String, Map<String, String>, List<String>, InstallSpot?)>[
      (
        'windows',
        '$win\\rasgeth-app.exe',
        {},
        ['$win\\unins000.exe'],
        const InstallSpot(system: 'windows', dir: win, exe: '$win\\rasgeth-app.exe'),
      ),
      // Rasgeth-Setup.exe's copy: Rasgeth.exe one folder up.
      ('windows', '$red\\app\\rasgeth-app.exe', {}, ['$red\\Rasgeth.exe'], null),
      // A build somewhere else (no uninstaller): never replaced.
      ('windows', r'D:\build\rasgeth-app.exe', {}, [], null),
      // Opened by the launcher.
      (
        'windows',
        '$win\\rasgeth-app.exe',
        {'RGCOMPANION_HANDOFF_FILE': r'C:\t\h.json'},
        ['$win\\unins000.exe'],
        null,
      ),
      (
        'linux',
        '$home/.local/share/rasgeth-app/rasgeth-app',
        {'HOME': home},
        [],
        const InstallSpot(
          system: 'linux',
          dir: '$home/.local/share/rasgeth-app',
          exe: '$home/.local/share/rasgeth-app/rasgeth-app',
        ),
      ),
      (
        'linux',
        '/data/x/rasgeth-app/rasgeth-app',
        {'HOME': home, 'XDG_DATA_HOME': '/data/x/'},
        [],
        const InstallSpot(
          system: 'linux',
          dir: '/data/x/rasgeth-app',
          exe: '/data/x/rasgeth-app/rasgeth-app',
        ),
      ),
      // Run from the unpacked archive, not installed.
      (
        'linux',
        '$home/Downloads/rasgeth-app-linux-x64/bundle/rasgeth-app',
        {'HOME': home},
        [],
        null,
      ),
      ('linux', '$home/.local/share/rasgeth-app/rasgeth-app', {}, [], null),
      // The Mac's app comes only with Rasgeth.
      ('macos', '/Applications/Rasgeth.app/Contents/Helpers/Rasgeth App.app', {}, [], null),
      ('android', '/data/app/rgcompanion', {}, [], null),
    ];
    for (final (system, exe, env, files, want) in rows) {
      expect(
        standaloneSpot(system: system, exePath: exe, env: env, exists: files.contains),
        want,
        reason: '$system $exe $env',
      );
    }
  });

  group('the signed list', () {
    test('a good signature is read', () {
      final s = signedSums(_sums, _v['sig'] as String, key: _key);
      expect(s, isNotNull);
      expect(s!.keys, unorderedEquals(_files.keys));
    });
    test('another key, a changed list, garbage, nothing: refused', () {
      expect(signedSums(_sums, _v['otherKeySig'] as String, key: _key), isNull);
      expect(
        signedSums(utf8.encode(_v['changedSums'] as String), _v['sig'] as String, key: _key),
        isNull,
      );
      expect(signedSums(_sums, 'not base64 !!', key: _key), isNull);
      expect(signedSums(_sums, '', key: _key), isNull);
      expect(signedSums(_sums, base64.encode(List.filled(384, 7)), key: _key), isNull);
    });
    test('the built-in key is the real one: it refuses the throwaway key\'s signature', () {
      expect(signedSums(_sums, _v['sig'] as String), isNull);
    });
    test('the built-in key is the launcher\'s (UpdateKey.cs)', skip: repoSkip(_updateKey), () {
      final cs = repoFile(_updateKey)!.readAsStringSync();
      expect(RegExp('<Modulus>([^<]*)</Modulus>').firstMatch(cs)!.group(1), kUpdateKeyModulus);
      expect(RegExp('<Exponent>([^<]*)</Exponent>').firstMatch(cs)!.group(1), kUpdateKeyExponent);
    });
    test('lines that are not sha256sum\'s are not trusted half', () {
      final h = 'a' * 64;
      expect(parseSums('$h  a.exe\n$h *b.tar.gz\n'), {'a.exe': h, 'b.tar.gz': h});
      expect(parseSums('$h  a.exe\nsomething else\n'), isNull);
      expect(parseSums('$h  ../a.exe\n'), isNull);
      expect(parseSums('$h  dir/a.exe\n'), isNull);
      expect(parseSums('$h  a.exe\n$h  a.exe\n'), isNull);
      expect(parseSums(''), isNull);
    });
  });

  group('the updater', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('g41-8b-'));
    tearDown(() => tmp.deleteSync(recursive: true));

    AppUpdater make(
      _Github gh, {
      String system = 'linux',
      InstallSpot? spot,
      bool noSpot = false,
      String current = '3.8.14',
      String? server,
      AppPrefs? prefs,
      _Clock? clock,
      List<SwapPlan>? plans,
      List<String>? quits,
      bool swapFails = false,
    }) => AppUpdater(
      spot: noSpot
          ? null
          : spot ?? InstallSpot(system: system, dir: '${tmp.path}/app', exe: '${tmp.path}/app/x'),
      current: current,
      prefs: prefs ?? MemoryAppPrefs(),
      folder: () async => '${tmp.path}/updates',
      client: gh.client(),
      serverVersion: () => server,
      now: (clock ?? _Clock()).now,
      key: _key,
      apiBase: _api,
      processId: () => 4242,
      unpack: (archive, into) async {
        // The archive's bytes are the signed ones: a bundle stands for what tar would give.
        Directory('$into/rasgeth-app-linux-x64/bundle').createSync(recursive: true);
        File('$into/rasgeth-app-linux-x64/bundle/rasgeth-app').writeAsStringSync('new');
        return '$into/rasgeth-app-linux-x64/bundle';
      },
      swap: (plan, folder) async {
        plans?.add(plan);
        if (swapFails) throw const SwapNotStarted('no alive file');
      },
      quit: () => quits?.add('quit'),
    );

    test('found: the signed sha256 of this system\'s package', () async {
      final gh = _Github();
      final u = make(gh);
      await u.check();
      expect(u.stage, AppUpdateStage.available);
      expect(u.found!.version, '3.9.0');
      expect(u.found!.asset, kLinuxTarAsset);
      expect(u.found!.sha256, parseSums(_v['sums'] as String)![kLinuxTarAsset]);
    });

    test('a wrong signature: refused, and no package is ever asked', () async {
      for (final sig in [_v['otherKeySig'] as String, 'garbage']) {
        final gh = _Github(sig: sig);
        final u = make(gh);
        await u.check();
        expect(u.stage, AppUpdateStage.failed);
        expect(u.error, AppUpdateError.signature);
        expect(u.found, isNull);
        expect(gh.asked.where((a) => a.endsWith('.exe') || a.endsWith('.tar.gz')), isEmpty);
        await u.download();
        expect(gh.asked.where((a) => a.endsWith('.exe') || a.endsWith('.tar.gz')), isEmpty);
      }
    });

    test('a release without the signature: refused', () async {
      final u = make(_Github(releaseSig: false));
      await u.check();
      expect(u.error, AppUpdateError.signature);
    });

    test('Rasgeth\'s copy, a build from the sources: never asks anything', () async {
      for (final u in [make(_Github(), noSpot: true), make(_Github(), current: '')]) {
        await u.check(asked: true);
        expect(u.enabled, isFalse);
        expect(u.stage, AppUpdateStage.idle);
      }
    });

    test('up to date, skipped, and GitHub offline with a newer Rasgeth', () async {
      final same = make(_Github(), current: '3.9.0');
      await same.check();
      expect(same.stage, AppUpdateStage.upToDate);

      final prefs = MemoryAppPrefs()..values['appUpdateSkip'] = '3.9.0';
      final skipped = make(_Github(), prefs: prefs);
      await skipped.check();
      expect(skipped.stage, AppUpdateStage.idle);
      await skipped.check(asked: true);
      expect(skipped.stage, AppUpdateStage.available);

      final gh = _Github(latestFails: true);
      final viaServer = make(gh, server: '3.9.0');
      await viaServer.check();
      expect(viaServer.found!.why, UpdateWhy.server);
      expect(gh.asked, contains('$_api/repos/$kReleaseRepo/releases/tags/v3.9.0'));

      final offline = make(_Github(latestFails: true));
      await offline.check();
      expect(offline.error, AppUpdateError.network);
    });

    test('the download: hashed, kept, unpacked; Windows keeps the installer', () async {
      final u = make(_Github());
      await u.check();
      await u.download();
      expect(u.stage, AppUpdateStage.ready);
      expect(
        File('${tmp.path}/updates/3.9.0/$kLinuxTarAsset').readAsStringSync(),
        _files[kLinuxTarAsset],
      );
      expect(File('${tmp.path}/updates/3.9.0/$kLinuxTarAsset.part').existsSync(), isFalse);

      final plans = <SwapPlan>[];
      final w = make(_Github(), system: 'windows', plans: plans);
      await w.check();
      expect(w.found!.asset, kWindowsSetupAsset);
      await w.download();
      expect(w.stage, AppUpdateStage.ready);
      await w.apply(const ResumeState());
      expect(_slash(plans.single.package), _slash('${tmp.path}/updates/3.9.0/$kWindowsSetupAsset'));
    });

    test('a file that is not the signed one: deleted, never used', () async {
      final u = make(_Github(body: {..._files, kLinuxTarAsset: 'something else'}));
      await u.check();
      await u.download();
      expect(u.stage, AppUpdateStage.failed);
      expect(u.error, AppUpdateError.checksum);
      expect(Directory('${tmp.path}/updates/3.9.0').listSync(), isEmpty);
    });

    test('the bar (bytes, speed, time left) and the cancel', () async {
      final gh = _Github()..held = StreamController<List<int>>();
      final clock = _Clock();
      final u = make(gh, clock: clock);
      await u.check();
      final going = u.download();
      await pumpEventQueue();
      expect(u.stage, AppUpdateStage.downloading);
      // The download starts its clock when it listens: the fake clock moves only after that.
      for (var n = 0; n < 50 && !gh.held!.hasListener; n++) {
        await pumpEventQueue();
      }
      expect(gh.held!.hasListener, isTrue);
      for (var i = 0; i < 4; i++) {
        clock.t = clock.t.add(const Duration(seconds: 1));
        gh.held!.add(List.filled(100, 1));
        // Each chunk must reach the updater before the clock moves again, or the speed is measured
        // over the wrong span (a slow CI runner delivers two chunks in one turn).
        for (var n = 0; n < 50 && u.progress?.done != (i + 1) * 100; n++) {
          await pumpEventQueue();
        }
      }
      final p = u.progress!;
      expect(p.done, 400);
      expect(p.total, 1000);
      expect(p.bps, closeTo(100, 1));
      expect(p.eta, 6);
      expect(File('${tmp.path}/updates/3.9.0/$kLinuxTarAsset.part').existsSync(), isTrue);
      await u.cancel();
      await going;
      expect(u.stage, AppUpdateStage.available);
      expect(u.progress, isNull);
      expect(File('${tmp.path}/updates/3.9.0/$kLinuxTarAsset.part').existsSync(), isFalse);
      expect(File('${tmp.path}/updates/3.9.0/$kLinuxTarAsset').existsSync(), isFalse);
      unawaited(gh.held!.close());
    });

    test('«Update and restart»: where the person is, the helper, then the app closes', () async {
      final plans = <SwapPlan>[];
      final quits = <String>[];
      final u = make(_Github(), plans: plans, quits: quits);
      await u.check();
      await u.download();
      await u.apply(const ResumeState(sessionId: 's1', view: 'projects', full: true));
      final p = plans.single;
      expect(p.system, 'linux');
      expect(p.pid, 4242);
      expect(p.dir, '${tmp.path}/app');
      expect(p.fromVersion, '3.8.14');
      expect(p.toVersion, '3.9.0');
      expect(_slash(p.package), endsWith('/unpacked/rasgeth-app-linux-x64/bundle'));
      expect(_slash(p.alive), '${_slash(tmp.path)}/updates/helper-alive');
      expect(quits, ['quit']);

      // The next start (new or old version) takes it once.
      final next = make(_Github(), current: '3.9.0');
      final r = await next.takeResume();
      expect(r!.sessionId, 's1');
      expect(r.view, 'projects');
      expect(r.full, isTrue);
      expect(await next.takeResume(), isNull);
    });

    test('a helper that does not start: the app stays open, failed', () async {
      final plans = <SwapPlan>[];
      final quits = <String>[];
      final u = make(_Github(), plans: plans, quits: quits, swapFails: true);
      await u.check();
      await u.download();
      await u.apply(const ResumeState(sessionId: 's1'));
      expect(plans, hasLength(1));
      expect(quits, isEmpty);
      expect(u.stage, AppUpdateStage.failed);
      expect(u.error, AppUpdateError.swap);
    });

    test('at the next start: the marker, the notice, a failed version skipped', () async {
      final prefs = MemoryAppPrefs();
      final marker = '${tmp.path}/started-3.9.0';
      final updated = make(_Github(), current: '3.9.0', prefs: prefs);
      await updated.started(UpdateStart.parse(['$kMarkerArg$marker', '${kUpdatedFromArg}3.8.14']));
      expect(File(marker).readAsStringSync(), 'ok');
      expect(updated.updatedFrom, '3.8.14');

      final back = make(_Github(), prefs: prefs);
      await back.started(UpdateStart.parse(['${kUpdateFailedArg}3.9.0']));
      expect(back.failedVersion, '3.9.0');
      expect(prefs.values['appUpdateSkip'], '3.9.0');
      await back.check();
      expect(back.stage, AppUpdateStage.idle, reason: 'not offered again by itself');
    });
  });

  group('the Linux helper, run for real on fake folders', skip: !Platform.isLinux, () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('g41-8b-swap-'));
    tearDown(() => tmp.deleteSync(recursive: true));

    // A fake app: writes what it was started with into out.txt; the good one writes the marker.
    void fakeApp(String dir, String name, {required bool starts}) {
      Directory(dir).createSync(recursive: true);
      File('$dir/version.txt').writeAsStringSync(name);
      final f = File('$dir/$kExeName');
      f.writeAsStringSync('''
#!/bin/sh
echo "$name \$*" >> ${tmp.path}/out.txt
${starts ? '''for a in "\$@"; do case "\$a" in $kMarkerArg*) echo ok > "\${a#$kMarkerArg}";; esac; done
sleep 5''' : 'exit 1'}
''');
      Process.runSync('chmod', ['+x', f.path]);
    }

    Future<(int, String)> run({required bool newStarts}) async {
      final dest = '${tmp.path}/share/rgcompanion';
      fakeApp(dest, 'old', starts: true);
      fakeApp('${tmp.path}/new/bundle', 'new', starts: newStarts);
      final running = await Process.start('sleep', ['0.6']);
      final plan = SwapPlan(
        system: 'linux',
        pid: running.pid,
        dir: dest,
        exe: '$dest/$kExeName',
        fromVersion: '3.8.14',
        toVersion: '3.9.0',
        package: '${tmp.path}/new/bundle',
        marker: '${tmp.path}/started',
        log: '${tmp.path}/update.log',
        alive: '${tmp.path}/alive',
        waitSeconds: 3,
      );
      File('${tmp.path}/swap.sh').writeAsStringSync(linuxSwapScript(plan));
      final r = await Process.run('/bin/sh', ['${tmp.path}/swap.sh']);
      // The started app writes its line a moment later (detached).
      final out = File('${tmp.path}/out.txt');
      for (var i = 0; i < 50 && !out.existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return (r.exitCode, out.existsSync() ? out.readAsStringSync() : '');
    }

    test('replaced, the new version started with its marker, the old folder gone', () async {
      final (code, out) = await run(newStarts: true);
      final dest = '${tmp.path}/share/rgcompanion';
      expect(code, 0, reason: File('${tmp.path}/update.log').readAsStringSync());
      expect(File('$dest/version.txt').readAsStringSync(), 'new');
      expect(Directory('$dest.previous').existsSync(), isFalse);
      expect(out, contains('new $kMarkerArg${tmp.path}/started ${kUpdatedFromArg}3.8.14'));
      expect(File('${tmp.path}/started').existsSync(), isTrue);
      expect(File('${tmp.path}/alive').existsSync(), isTrue, reason: 'written first');
    });

    test('the new version does not start: the old folder back, the old version told', () async {
      final (code, out) = await run(newStarts: false);
      final dest = '${tmp.path}/share/rgcompanion';
      expect(code, 2, reason: File('${tmp.path}/update.log').readAsStringSync());
      expect(File('$dest/version.txt').readAsStringSync(), 'old');
      expect(Directory('$dest.previous').existsSync(), isFalse);
      expect(out, contains('old ${kUpdateFailedArg}3.9.0'));
      expect(File('${tmp.path}/update.log').readAsStringSync(), contains('going back to 3.8.14'));
    });
  });

  test('the Windows helper: silent for this user, kept folder, going back', () {
    final s = windowsSwapScript(
      const SwapPlan(
        system: 'windows',
        pid: 7,
        dir: r"C:\Users\O'Brien\AppData\Local\Programs\Rasgeth App",
        exe: r"C:\Users\O'Brien\AppData\Local\Programs\Rasgeth App\rasgeth-app.exe",
        fromVersion: '3.8.14',
        toVersion: '3.9.0',
        package: r"C:\Users\O'Brien\AppData\Roaming\Rasgeth\Rasgeth\app-update\3.9.0\Rasgeth-App-Setup.exe",
        marker: r'C:\m',
        log: r'C:\l',
        alive: r'C:\a',
      ),
    );
    expect(s, contains("'/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'"));
    expect(s, isNot(contains('/ALLUSERS')));
    expect(s, isNot(contains('RunAs')));
    expect(s, contains(r"$dest = 'C:\Users\O''Brien\AppData\Local\Programs\Rasgeth App'"));
    expect(s, contains(r'Copy-Item -LiteralPath $dest -Destination $prev'));
    expect(s, contains(r'Move-Item -LiteralPath $prev -Destination $dest'));
    expect(s, contains(kUpdateFailedArg));
    expect(s, contains(kMarkerArg));
  });

  group('the window', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('g41-8b-ui-'));
    tearDown(() => tmp.deleteSync(recursive: true));

    Widget host(AppUpdater u) => MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: const Locale('it'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: AppUpdateWindow(updater: u)),
    );

    testWidgets('found, downloading with its bar, cancelled, ready', (t) async {
      final gh = _Github()..held = StreamController<List<int>>();
      final clock = _Clock();
      final plans = <SwapPlan>[];
      final u = AppUpdater(
        spot: InstallSpot(system: 'windows', dir: '${tmp.path}/app', exe: '${tmp.path}/app/x'),
        current: '3.8.14',
        prefs: MemoryAppPrefs(),
        folder: () async => '${tmp.path}/updates',
        client: gh.client(),
        now: clock.now,
        key: _key,
        apiBase: _api,
        swap: (p, _) async => plans.add(p),
        quit: () {},
      );
      await t.runAsync(u.check);
      await t.pumpWidget(host(u));
      expect(find.text('È uscita la versione 3.9.0: hai la 3.8.14.'), findsOneWidget);
      await t.tap(find.byKey(const Key('app-update-download')));
      await t.runAsync(pumpEventQueue);
      for (var i = 0; i < 3; i++) {
        clock.t = clock.t.add(const Duration(seconds: 1));
        gh.held!.add(List.filled(100, 1));
        await t.runAsync(pumpEventQueue);
      }
      await t.pump();
      expect(find.byKey(const Key('app-update-bar')), findsOneWidget);
      expect(find.text('Scarico la 3.9.0'), findsOneWidget);
      expect(find.byKey(const Key('app-update-bar-text')), findsOneWidget);
      await t.tap(find.byKey(const Key('app-update-cancel')));
      await t.runAsync(pumpEventQueue);
      await t.pump();
      expect(u.stage, AppUpdateStage.available);
      expect(find.byKey(const Key('app-update-download')), findsOneWidget);
      // The part is closed, then deleted (real I/O: Windows cannot delete an open file).
      final part = File('${tmp.path}/updates/3.9.0/$kWindowsSetupAsset.part');
      for (var i = 0; i < 50 && (u.busy || part.existsSync()); i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pump();
      }
      expect(part.existsSync(), isFalse);
      expect(u.busy, isFalse);
      unawaited(gh.held!.close());

      gh.held = null;
      await t.runAsync(u.download);
      await t.pump();
      expect(find.text('Aggiorna e riavvia'), findsOneWidget);
      await t.tap(find.byKey(const Key('app-update-apply')));
      // The resume file is real I/O: let it finish outside the test's fake time.
      for (var i = 0; i < 50 && plans.isEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pump();
      }
      expect(plans, hasLength(1));
    });

    testWidgets('a wrong signature says so, and nothing to download', (t) async {
      final u = AppUpdater(
        spot: InstallSpot(system: 'linux', dir: '${tmp.path}/app', exe: '${tmp.path}/app/x'),
        current: '3.8.14',
        prefs: MemoryAppPrefs(),
        folder: () async => '${tmp.path}/updates',
        client: _Github(sig: _v['otherKeySig'] as String).client(),
        key: _key,
        apiBase: _api,
      );
      await t.runAsync(u.check);
      await t.pumpWidget(host(u));
      expect(find.byKey(const Key('app-update-error')), findsOneWidget);
      expect(find.byKey(const Key('app-update-download')), findsNothing);
      expect(find.byKey(const Key('app-update-apply')), findsNothing);
    });
  });
}
