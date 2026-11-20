// 3.9.8: the app's data under its name before 3.9.0 (Windows: %APPDATA%\RedGiant\RGCompanion),
// carried once: each keystore entry written anew and read back before the old ones go; the
// RedGiants the new list lacks come back; a RedGiant without a token is never dropped, it asks
// to be paired again («Abbina di nuovo»).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/legacy_data.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_server.dart';

class FakeLegacy implements LegacySource {
  FakeLegacy(this.data, {this.fails = false});

  LegacyAppData? data;
  bool fails;
  int reads = 0;
  int forgotten = 0;

  @override
  Future<LegacyAppData?> read() async {
    reads++;
    if (fails) throw const FileSystemException('held by another program');
    return data;
  }

  @override
  Future<void> forgetSecrets() async {
    forgotten++;
    data = LegacyAppData(servers: data?.servers ?? const [], current: data?.current);
  }
}

/// A keystore whose writes do not stick (or throw) for some names.
class FlakyTokens extends MemoryTokenStore {
  FlakyTokens({this.lose = const {}, this.throwOn = const {}});

  final Set<String> lose;
  final Set<String> throwOn;

  @override
  Future<void> write(String server, String token) async {
    if (throwOn.contains(server)) throw StateError('keystore refused');
    if (lose.contains(server)) return;
    await super.write(server, token);
  }
}

/// A keystore that cannot be read at all (the plugin drops its file and throws).
class BrokenTokens extends MemoryTokenStore {
  @override
  Future<String?> read(String server) async => throw StateError('CryptUnprotectData');
}

const _coder = {
  'id': '833ct6le3fg8',
  'label': 'Coder',
  'address': 'https://coder.example.test',
  'fingerprint': 'SHA256:coder',
  'deviceId': 'dev_old',
};

LegacyAppData _old({Map<String, String>? secrets, List<Map<String, dynamic>>? servers}) =>
    LegacyAppData(
      servers: servers ?? [_coder],
      current: '833ct6le3fg8',
      secrets:
          secrets ??
          {
            'rgcompanion.token.833ct6le3fg8': 'rgd_old_token',
            'rgcompanion.token.identity': 'c2VlZA==',
            'rgcompanion.token.push.833ct6le3fg8': '{"k":1}',
            'someone.else': 'not ours',
          },
    );

void main() {
  group('carryLegacyData', () {
    test('the user’s case: an empty list and no keystore get the server and its token', () async {
      final prefs = MemoryAppPrefs()..values['servers'] = '[]';
      final tokens = MemoryTokenStore();
      final src = FakeLegacy(_old());
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
      final src = FakeLegacy(_old());
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
      final o = await carryLegacyData(source: FakeLegacy(_old()), prefs: prefs, tokens: tokens);
      expect(o.secretsKept, 1);
      expect(o.secretsCarried, 2);
      expect(await tokens.read('833ct6le3fg8'), 'rgd_new_token');
    });

    test('an entry that does not read back: the old ones stay, and the next start tries again', () async {
      final prefs = MemoryAppPrefs();
      final src = FakeLegacy(_old());
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
    });

    test('a keystore that throws on write counts as a failure, nothing removed', () async {
      final src = FakeLegacy(_old());
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
      final src = FakeLegacy(_old(), fails: true);
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
          source: FakeLegacy(_old()),
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
        source: FakeLegacy(_old()),
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
          'rgcompanion.servers': jsonEncode([_coder]),
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
      final plain = jsonEncode({'rgcompanion.token.t1': 'rgd_test_only', 'rgcompanion.token.identity': 'c2Vk'});
      final out = '${dir.path}${Platform.pathSeparator}flutter_secure_storage.dat';
      final script =
          'Add-Type -AssemblyName System.Security; '
          r"$b = [Text.Encoding]::UTF8.GetBytes($env:RG_PLAIN); "
          r'$e = [Security.Cryptography.ProtectedData]::Protect($b, $null, '
          "'CurrentUser'); "
          r'[IO.File]::WriteAllBytes($env:RG_OUT, $e)';
      final r = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', script],
        environment: {'RG_PLAIN': plain, 'RG_OUT': out},
      );
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final src = WindowsLegacySource(dir.path);
      final d = await src.read();
      expect(d!.secrets, {'rgcompanion.token.t1': 'rgd_test_only', 'rgcompanion.token.identity': 'c2Vk'});
      final tokens = MemoryTokenStore();
      final o = await carryLegacyData(source: src, prefs: MemoryAppPrefs(), tokens: tokens);
      expect(o.secretsCarried, 2);
      expect(o.oldSecretsForgotten, isTrue);
      expect(File(out).existsSync(), isFalse);
      expect(await tokens.read('t1'), 'rgd_test_only');
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
      final prefs = MemoryAppPrefs()..values['servers'] = jsonEncode([_coder]);
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
      final prefs = MemoryAppPrefs()..values['servers'] = jsonEncode([_coder]);
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
      final legacy = FakeLegacy(_old(secrets: {}));
      final app = make(MemoryTokenStore(), prefs, legacy: legacy);
      await app.restore();
      expect(app.servers.map((s) => s.label), ['Coder']);
      expect(app.server?.id, '833ct6le3fg8');
      // Its token was lost with the old keystore too: paired again, not dropped.
      expect(app.needsPairing, isTrue);
      expect(app.renameDue, isTrue, reason: 'this device knew the old name');
    });

    group('against a server', () {
      late FakeRedGiant server;
      setUp(() async => server = await FakeRedGiant.start());
      tearDown(() => server.close());

      test('the old token carried over signs in at once', () async {
        server.tokens.add('rgd_old_token');
        final prefs = MemoryAppPrefs()..values['servers'] = '[]';
        final coder = {..._coder, 'address': server.base.toString()}..remove('fingerprint');
        final legacy = FakeLegacy(
          _old(
            servers: [coder],
            secrets: {'rgcompanion.token.833ct6le3fg8': 'rgd_old_token'},
          ),
        );
        final tokens = MemoryTokenStore();
        final app = make(tokens, prefs, legacy: legacy);
        await app.restore();
        expect(app.connected, isTrue);
        expect(app.needsPairing, isFalse);
        expect(server.requests.where((r) => r.startsWith('POST /api/app/pair')), isEmpty);
      });

      test('«Abbina di nuovo»: the same entry, a new token, the old device revoked', () async {
        final prefs = MemoryAppPrefs()
          ..values['servers'] = jsonEncode([
            {..._coder, 'address': server.base.toString(), 'label': 'Lavoro'}..remove('fingerprint'),
          ]);
        final tokens = MemoryTokenStore();
        final app = make(tokens, prefs);
        await app.restore();
        expect(app.needsPairing, isTrue);
        expect(await app.pairAgain(app.server!, 'wrong'), isFalse);
        expect(app.servers, hasLength(1), reason: 'a wrong password drops nothing');
        expect(await app.pairAgain(app.servers.single, 'secret'), isTrue);
        expect(app.connected, isTrue);
        expect(app.needsPairing, isFalse);
        expect(app.servers, hasLength(1));
        expect(app.servers.single.label, 'Lavoro');
        expect(app.server?.id, app.servers.single.id);
        expect(await tokens.read(app.server!.id), isNotNull);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(server.requests, contains('DELETE /api/devices/dev_old'));
      });
    });
  });

  group('the screen', () {
    Future<AppController> shown(WidgetTester tester, Size size, ThemeMode mode) async {
      final prefs = MemoryAppPrefs()..values['servers'] = jsonEncode([_coder]);
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
