// The launchers' handoff (G40.12): the local RedGiant and a device token, never on the command
// line; the file is read once and deleted; only this computer's server is taken.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/handoff.dart';

import 'fake_server.dart';

String handoffJson(String address, String token, {String? deviceId, Object v = 1}) => jsonEncode({
  'v': v,
  'address': address,
  'token': token,
  'deviceId': ?deviceId,
  'machine': 'Rig',
});

void main() {
  group('LaunchHandoff.parse', () {
    const token = 'rgd_0123456789abcdef0123';

    test('a local server with its token', () {
      final h = LaunchHandoff.parse(handoffJson('http://127.0.0.1:7601/', token, deviceId: 'd9'))!;
      expect(h.address, 'http://127.0.0.1:7601');
      expect(h.token, token);
      expect(h.deviceId, 'd9');
      expect(h.machine, 'Rig');
      expect(
        LaunchHandoff.parse(handoffJson('http://localhost:7600', token))?.address,
        'http://localhost:7600',
      );
    });

    test('never another machine, https, a path, another version or a bad token', () {
      for (final bad in [
        handoffJson('http://192.168.1.53:7600', token),
        handoffJson('http://redgiant.local:7600', token),
        handoffJson('https://127.0.0.1:7600', token),
        handoffJson('http://127.0.0.1:7600/evil', token),
        handoffJson('http://127.0.0.1:7600', token, v: 2),
        handoffJson('http://127.0.0.1:7600', 'short'),
        handoffJson('http://127.0.0.1:7600', 'rgd_with a space inside it'),
        '{"v":1}',
        'not json',
        '[1]',
      ]) {
        expect(LaunchHandoff.parse(bad), isNull, reason: bad);
      }
    });
  });

  group('takeLaunchHandoff', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('rg-handoff'));
    tearDown(() => dir.delete(recursive: true));

    test('the file is read once and deleted', () async {
      final f = File('${dir.path}/h.json')
        ..writeAsStringSync(handoffJson('http://127.0.0.1:7600', 'rgd_0123456789abcdef0123'));
      final env = {kHandoffFileVar: f.path};
      final h = await takeLaunchHandoff(environment: env);
      expect(h?.token, 'rgd_0123456789abcdef0123');
      expect(f.existsSync(), isFalse);
      expect(await takeLaunchHandoff(environment: env), isNull);
    });

    test('a file that is not a handoff is deleted too, and gives nothing', () async {
      final f = File('${dir.path}/h.json')..writeAsStringSync('{"v":1,"address":"http://x"}');
      expect(await takeLaunchHandoff(environment: {kHandoffFileVar: f.path}), isNull);
      expect(f.existsSync(), isFalse);
    });

    test("the child's environment (macOS), and nothing at all", () async {
      final h = await takeLaunchHandoff(
        environment: {
          kHandoffVar: handoffJson('http://127.0.0.1:7600', 'rgd_0123456789abcdef0123'),
        },
      );
      expect(h?.address, 'http://127.0.0.1:7600');
      expect(await takeLaunchHandoff(environment: const {}), isNull);
      expect(await takeLaunchHandoff(environment: {kHandoffFileVar: '${dir.path}/none'}), isNull);
    });
  });

  group('AppController.restore with a handoff', () {
    late FakeRedGiant server;
    setUp(() async => server = await FakeRedGiant.start());
    tearDown(() => server.close());

    AppController make(MemoryTokenStore t, MemoryAppPrefs p) =>
        AppController(tokens: t, prefs: p, platform: DevicePlatform.windows, liveEnabled: false);

    test('the window opens on the local RedGiant, signed in, without a password', () async {
      server.tokens.add('rgd_from_the_launcher_1');
      final store = MemoryTokenStore();
      final app = make(store, MemoryAppPrefs());
      await app.restore(
        handoff: LaunchHandoff(
          address: server.base.toString(),
          token: 'rgd_from_the_launcher_1',
          deviceId: 'd7',
          machine: 'Rig',
        ),
      );
      expect(app.connected, isTrue);
      expect(app.servers, hasLength(1));
      expect(app.server?.label, 'Rig');
      expect(store.values.values, contains('rgd_from_the_launcher_1'));
      expect(server.requests.where((r) => r.startsWith('POST /api/app/pair')), isEmpty);
    });

    test("the next opening replaces the token and revokes the app's previous device", () async {
      server.tokens.addAll(['rgd_from_the_launcher_1', 'rgd_from_the_launcher_2']);
      final store = MemoryTokenStore();
      final prefs = MemoryAppPrefs();
      final first = make(store, prefs);
      await first.restore(
        handoff: LaunchHandoff(
          address: server.base.toString(),
          token: 'rgd_from_the_launcher_1',
          deviceId: 'd1',
        ),
      );
      expect(first.connected, isTrue);

      final again = make(store, prefs);
      await again.restore(
        handoff: LaunchHandoff(
          address: server.base.toString(),
          token: 'rgd_from_the_launcher_2',
          deviceId: 'd2',
        ),
      );
      expect(again.connected, isTrue);
      expect(again.servers, hasLength(1));
      expect(again.servers.single.deviceId, 'd2');
      expect(store.values.values, contains('rgd_from_the_launcher_2'));
      expect(store.values.values, isNot(contains('rgd_from_the_launcher_1')));
      await until(() => server.requests.contains('DELETE /api/devices/d1'));
      expect(server.devices.where((d) => d['id'] == 'd1'), isEmpty);
    });

    test('without a handoff the last RedGiant in use comes back as before', () async {
      final prefs = MemoryAppPrefs();
      await ServerBook(prefs)
          .put(SavedServer(id: 's1', label: 'Casa', address: server.base.toString()));
      final app = make(MemoryTokenStore(), prefs);
      await app.restore();
      expect(app.server?.id, 's1');
    });
  });
}

Future<void> until(bool Function() ok, {Duration within = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw StateError('not in time');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
