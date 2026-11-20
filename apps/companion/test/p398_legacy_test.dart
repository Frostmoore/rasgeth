// 3.9.8: the app's data under its name before 3.9.0 (Windows: %APPDATA%\RedGiant\RGCompanion),
// carried once: each keystore entry written anew and read back before the old ones go; the
// RedGiants the new list lacks come back; a RedGiant without a token is never dropped, it asks
// to be paired again («Abbina di nuovo»).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/keystore_guard.dart';
import 'package:rgcompanion/api/legacy_data.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_legacy.dart';

/// DPAPI needs the user's interactive logon: over ssh (a network logon with a key) Windows
/// answers «access denied», so there the round trip is skipped, saying why.
Object _dpapiSkip() {
  if (!Platform.isWindows) return 'Windows only';
  final r = Process.runSync('powershell', [
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    "\$ErrorActionPreference = 'Stop'; Add-Type -AssemblyName System.Security; "
        '[void][Security.Cryptography.ProtectedData]::Protect([byte[]](1), \$null, '
        "'CurrentUser'); 'ok'",
  ]);
  if (r.exitCode == 0 && '${r.stdout}'.trim() == 'ok') return false;
  return 'DPAPI is not available in this session (a network logon?): ${r.stderr}'.trim();
}

void main() {
  group('carryLegacyData', () {
    test('the user’s case: an empty list and no keystore get the server and its token', () async {
      final prefs = MemoryAppPrefs()..values['servers'] = '[]';
      final tokens = MemoryTokenStore();
      final src = FakeLegacy(oldData());
      final o = await carryLegacyData(source: src, prefs: prefs, tokens: tokens);
      expect(o.ran, isTrue);
      expect(o.secretsCarried, 3);
      expect(o.secretsKept, 0);
      expect(o.secretsFailed, 0);
      expect(o.serversRecovered, 1);
      expect(o.oldSecretsForgotten, isTrue);
      expect(await tokens.read('833ct6le3fg8'), 'rgd_old_token');
      expect(await tokens.read('identity'), 'c2VlZA==');
      expect(await tokens.read('push.833ct6le3fg8'), '{"k":1}');
      // Only the app's own entries.
      expect(tokens.values.keys, isNot(contains('someone.else')));
      final list = await ServerBook(prefs).load();
      expect(list.map((s) => s.id), ['833ct6le3fg8']);
      expect(list.single.fingerprint, 'SHA256:coder');
      expect(list.single.deviceId, 'dev_old');
      expect(await prefs.get('current'), '833ct6le3fg8');
      expect(await prefs.get(kLegacyCarriedKey), '1');
      expect(src.forgotten, 1);
    });

    test('once: a second start reads nothing', () async {
      final prefs = MemoryAppPrefs();
      final src = FakeLegacy(oldData());
      await carryLegacyData(source: src, prefs: prefs, tokens: MemoryTokenStore());
      final again = await carryLegacyData(source: src, prefs: prefs, tokens: MemoryTokenStore());
      expect(again.ran, isFalse);
      expect(src.reads, 1);
    });

    test('no source (macOS, Linux, phones): nothing at all', () async {
      final prefs = MemoryAppPrefs();
      final o = await carryLegacyData(source: null, prefs: prefs, tokens: MemoryTokenStore());
      expect(o.ran, isFalse);
      expect(prefs.values, isEmpty);
    });

    test('no old folder: marked done, nothing else', () async {
      final prefs = MemoryAppPrefs();
      final o = await carryLegacyData(
        source: FakeLegacy(null),
        prefs: prefs,
        tokens: MemoryTokenStore(),
      );
      expect(o.ran, isTrue);
      expect(o.serversRecovered, 0);
      expect(await prefs.get(kLegacyCarriedKey), '1');
      expect(await prefs.get('servers'), isNull);
    });

    test('the new keystore wins: what it has is never overwritten', () async {
      final prefs = MemoryAppPrefs();
      final tokens = MemoryTokenStore();
      await tokens.write('833ct6le3fg8', 'rgd_new_token');
      final o = await carryLegacyData(source: FakeLegacy(oldData()), prefs: prefs, tokens: tokens);
      expect(o.secretsKept, 1);
      expect(o.secretsCarried, 2);
      expect(await tokens.read('833ct6le3fg8'), 'rgd_new_token');
    });

    test(
      'an entry that does not read back: the old ones stay, and the next start tries again',
      () async {
        final prefs = MemoryAppPrefs();
        final src = FakeLegacy(oldData());
        final flaky = FlakyTokens(lose: {'833ct6le3fg8'});
        final o = await carryLegacyData(source: src, prefs: prefs, tokens: flaky);
        expect(o.secretsFailed, 1);
        expect(o.secretsCarried, 2);
        expect(o.oldSecretsForgotten, isFalse);
        expect(src.forgotten, 0);
        expect(await prefs.get(kLegacyCarriedKey), isNull);
        // The server is back anyway (to be paired again if its token never comes).
        expect((await ServerBook(prefs).load()).map((s) => s.id), ['833ct6le3fg8']);

        final good = MemoryTokenStore()..values.addAll(flaky.values);
        final next = await carryLegacyData(source: src, prefs: prefs, tokens: good);
        expect(next.secretsFailed, 0);
        expect(next.secretsCarried, 1);
        expect(next.secretsKept, 2);
        expect(next.serversRecovered, 0, reason: 'not added twice');
        expect(src.forgotten, 1);
        expect(await good.read('833ct6le3fg8'), 'rgd_old_token');
        expect(await prefs.get(kLegacyCarriedKey), '1');
      },
    );

    test('a keystore that throws on write counts as a failure, nothing removed', () async {
      final src = FakeLegacy(oldData());
      final o = await carryLegacyData(
        source: src,
        prefs: MemoryAppPrefs(),
        tokens: FlakyTokens(throwOn: {'identity'}),
      );
      expect(o.secretsFailed, 1);
      expect(src.forgotten, 0);
    });

    test('an old folder that cannot be read now: nothing changes, tried again later', () async {
      final prefs = MemoryAppPrefs();
      final src = FakeLegacy(oldData(), fails: true);
      final o = await carryLegacyData(source: src, prefs: prefs, tokens: MemoryTokenStore());
      expect(o.ran, isTrue);
      expect(o.secretsFailed, 1);
      expect(prefs.values, isEmpty);
      src.fails = false;
      final next = await carryLegacyData(source: src, prefs: prefs, tokens: MemoryTokenStore());
      expect(next.serversRecovered, 1);
    });

    test('servers already known (same id, same key, same address) are not added again', () async {
      for (final known in [
        {'id': '833ct6le3fg8', 'label': 'X', 'address': 'https://other.test'},
        {'id': 'n1', 'label': 'X', 'address': 'https://other.test', 'fingerprint': 'SHA256:coder'},
        {'id': 'n2', 'label': 'X', 'address': 'https://coder.example.test'},
      ]) {
        final prefs = MemoryAppPrefs()
          ..values['servers'] = jsonEncode([known])
          ..values['current'] = known['id']!;
        final o = await carryLegacyData(
          source: FakeLegacy(oldData()),
          prefs: prefs,
          tokens: MemoryTokenStore(),
        );
        expect(o.serversRecovered, 0, reason: '$known');
        expect(await ServerBook(prefs).load(), hasLength(1));
        expect(await prefs.get('current'), known['id']);
      }
    });

    test('a new server stays the one in use; the old one joins the list', () async {
      final prefs = MemoryAppPrefs()
        ..values['servers'] = jsonEncode([
          {'id': 'home', 'label': 'Casa', 'address': 'https://home.test'},
        ])
        ..values['current'] = 'home';
      final o = await carryLegacyData(
        source: FakeLegacy(oldData()),
        prefs: prefs,
        tokens: MemoryTokenStore(),
      );
      expect(o.serversRecovered, 1);
      expect((await ServerBook(prefs).load()).map((s) => s.id), ['home', '833ct6le3fg8']);
      expect(await prefs.get('current'), 'home');
    });
  });

  group('WindowsLegacySource', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('rg398-legacy-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('no folder or an empty one: nothing', () async {
      expect(await WindowsLegacySource('${dir.path}/none').read(), isNull);
      expect(await WindowsLegacySource(dir.path).read(), isNull);
    });

    test('the old settings file: the servers and the one in use (no keystore file)', () async {
      File('${dir.path}/shared_preferences.json').writeAsStringSync(
        jsonEncode({
          'rgcompanion.servers': jsonEncode([kCoder]),
          'rgcompanion.current': '833ct6le3fg8',
          'rgcompanion.advanced:833ct6le3fg8': '1',
        }),
      );
      final d = await WindowsLegacySource(dir.path).read();
      expect(d, isNotNull);
      expect(d!.servers.single['id'], '833ct6le3fg8');
      expect(d.current, '833ct6le3fg8');
      expect(d.secrets, isEmpty);
    });

    test('the old keystore file, DPAPI for this user (Windows only)', () async {
      // A test file of our own, protected the way the plugin protects it (CurrentUser, no
      // entropy): never the person's own.
      final plain = jsonEncode({
        'rgcompanion.token.t1': 'rgd_test_only',
        'rgcompanion.token.identity': 'c2Vk',
      });
      final sep = Platform.pathSeparator;
      final out = '${dir.path}${sep}flutter_secure_storage.dat';
      final plainFile = File('${dir.path}${sep}plain.json')..writeAsStringSync(plain);
      final script =
          'Add-Type -AssemblyName System.Security; '
          '\$b = [IO.File]::ReadAllBytes(\'${plainFile.path}\'); '
          '\$e = [Security.Cryptography.ProtectedData]::Protect(\$b, \$null, '
          '[Security.Cryptography.DataProtectionScope]::CurrentUser); '
          '[IO.File]::WriteAllBytes(\'$out\', \$e)';
      final r = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]);
      plainFile.deleteSync();
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final src = WindowsLegacySource(dir.path);
      final d = await src.read();
      expect(d!.secrets, {
        'rgcompanion.token.t1': 'rgd_test_only',
        'rgcompanion.token.identity': 'c2Vk',
      });
      final tokens = MemoryTokenStore();
      final o = await carryLegacyData(source: src, prefs: MemoryAppPrefs(), tokens: tokens);
      expect(o.secretsCarried, 2);
      expect(o.oldSecretsForgotten, isTrue);
      expect(File(out).existsSync(), isFalse);
      expect(await tokens.read('t1'), 'rgd_test_only');
    }, skip: _dpapiSkip());
  });

  group('guardKeystore', () {
    late Directory dir;
    late File dat;
    late File bak;
    setUp(() {
      dir = Directory.systemTemp.createTempSync('rg398-guard-');
      dat = File('${dir.path}${Platform.pathSeparator}$kKeystoreFile');
      bak = File('${dir.path}${Platform.pathSeparator}$kKeystoreFile.bak');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    bool yes() => true;
    bool opens(List<int> b) => b.isNotEmpty && b.first == 1;

    test('where DPAPI does not work the keystore is not touched at all', () async {
      dat.writeAsBytesSync([1, 2, 3]);
      final g = await guardKeystore(dir.path, dpapiWorks: () => false, readable: opens);
      expect(g, KeystoreGuardResult.noDpapi);
      expect(bak.existsSync(), isFalse);
      expect(dat.readAsBytesSync(), [1, 2, 3]);
    });

    test('a file that opens is copied aside', () async {
      dat.writeAsBytesSync([1, 2, 3]);
      expect(
        await guardKeystore(dir.path, dpapiWorks: yes, readable: opens),
        KeystoreGuardResult.backedUp,
      );
      expect(bak.readAsBytesSync(), [1, 2, 3]);
    });

    test('a file gone comes back from the copy', () async {
      bak.writeAsBytesSync([1, 9]);
      expect(
        await guardKeystore(dir.path, dpapiWorks: yes, readable: opens),
        KeystoreGuardResult.restored,
      );
      expect(dat.readAsBytesSync(), [1, 9]);
      expect(bak.existsSync(), isTrue);
    });

    test('a broken file never replaces the last good copy', () async {
      dat.writeAsBytesSync([0, 0]);
      bak.writeAsBytesSync([1, 9]);
      expect(
        await guardKeystore(dir.path, dpapiWorks: yes, readable: opens),
        KeystoreGuardResult.untouched,
      );
      expect(bak.readAsBytesSync(), [1, 9]);
    });

    test('nothing there: nothing made', () async {
      expect(
        await guardKeystore(dir.path, dpapiWorks: yes, readable: opens),
        KeystoreGuardResult.untouched,
      );
      expect(dir.listSync(), isEmpty);
    });

    test('the keystore of a session without DPAPI reads nothing and writes nothing', () async {
      final t = UnavailableTokenStore();
      expect(await t.read('x'), isNull);
      await expectLater(t.write('x', 'y'), throwsStateError);
      await t.delete('x');
    });

    test('the probe sees what PowerShell sees (Windows: false over ssh, true at the desk)', () {
      expect(dpapiRoundTrip(), _dpapiSkip() == false);
    }, skip: !Platform.isWindows);
  });

  group('a RedGiant without its token', () {
    AppController make(MemoryTokenStore t, MemoryAppPrefs p, {LegacySource? legacy}) =>
        AppController(
          tokens: t,
          prefs: p,
          platform: DevicePlatform.windows,
          liveEnabled: false,
          legacy: legacy,
        );

    test('stays in the list, asks to be paired again, at every start', () async {
      final prefs = MemoryAppPrefs()..values['servers'] = jsonEncode([kCoder]);
      for (var i = 0; i < 2; i++) {
        final app = make(MemoryTokenStore(), prefs);
        await app.restore();
        expect(app.servers.map((s) => s.id), ['833ct6le3fg8']);
        expect(app.server?.id, '833ct6le3fg8');
        expect(app.needsPairing, isTrue);
        expect(app.error, ConnectError.signInAgain);
      }
      expect(jsonDecode(prefs.values['servers']!), hasLength(1));
    });

    test('an unreadable keystore is a pairing again, never an error that loses the list', () async {
      final prefs = MemoryAppPrefs()..values['servers'] = jsonEncode([kCoder]);
      final app = AppController(
        tokens: BrokenTokens(),
        prefs: prefs,
        platform: DevicePlatform.windows,
        liveEnabled: false,
      );
      await app.restore();
      expect(app.needsPairing, isTrue);
      expect(app.servers, hasLength(1));
    });

    test('the user’s case at start: the old folder brings the server back', () async {
      final prefs = MemoryAppPrefs()..values['servers'] = '[]';
      final legacy = FakeLegacy(oldData(secrets: {}));
      final app = make(MemoryTokenStore(), prefs, legacy: legacy);
      await app.restore();
      expect(app.servers.map((s) => s.label), ['Coder']);
      expect(app.server?.id, '833ct6le3fg8');
      // Its token was lost with the old keystore too: paired again, not dropped.
      expect(app.needsPairing, isTrue);
      expect(app.renameDue, isTrue, reason: 'this device knew the old name');
    });
  });

  group('the screen', () {
    Future<AppController> shown(WidgetTester tester, Size size, ThemeMode mode) async {
      final prefs = MemoryAppPrefs()..values['servers'] = jsonEncode([kCoder]);
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: prefs,
        platform: size.width > 900 ? DevicePlatform.windows : DevicePlatform.android,
        liveEnabled: false,
      )..reduceMotion = true;
      await tester.runAsync(app.restore);
      app
        ..locale = const Locale('it')
        ..themeMode = mode
        ..renameDue = false;
      app.setTab(AppTab.you);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await tester.pumpAndSettle();
      return app;
    }

    for (final size in [const Size(420, 900), const Size(1280, 800)]) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        testWidgets('«Abbina di nuovo» on the server, not «non raggiungibile» ($size, $mode)', (
          tester,
        ) async {
          await shown(tester, size, mode);
          final button = find.byKey(const Key('pair-again-833ct6le3fg8'));
          await tester.scrollUntilVisible(button, 200, scrollable: find.byType(Scrollable).first);
          expect(find.text('da abbinare di nuovo'), findsWidgets);
          expect(
            find.descendant(
              of: find.byKey(const Key('server-status-833ct6le3fg8')),
              matching: find.text('non raggiungibile'),
            ),
            findsNothing,
          );
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('pair-again-password')), findsOneWidget);
          expect(find.text('Abbina di nuovo Coder'), findsOneWidget);
          await tester.tap(find.text('Annulla'));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('pair-again-password')), findsNothing);
        });
      }
    }
  });
}
