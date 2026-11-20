// 3.9.8: against a server (a real socket, so no widget binding in this file): the old token
// carried over signs in at once; «Abbina di nuovo» keeps the same entry and revokes the old device.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/legacy_data.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_legacy.dart';
import 'fake_server.dart';

AppController make(MemoryTokenStore t, MemoryAppPrefs p, {LegacySource? legacy}) => AppController(
  tokens: t,
  prefs: p,
  platform: DevicePlatform.windows,
  liveEnabled: false,
  legacy: legacy,
);

void main() {
  group('against a server', () {
    late FakeRedGiant server;
    setUp(() async => server = await FakeRedGiant.start());
    tearDown(() => server.close());

    test('the old token carried over signs in at once', () async {
      server.tokens.add('rgd_old_token');
      final prefs = MemoryAppPrefs()..values['servers'] = '[]';
      final coder = {...kCoder, 'address': server.base.toString()}..remove('fingerprint');
      final legacy = FakeLegacy(
        oldData(servers: [coder], secrets: {'rgcompanion.token.833ct6le3fg8': 'rgd_old_token'}),
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
          {...kCoder, 'address': server.base.toString(), 'label': 'Lavoro'}..remove('fingerprint'),
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

    for (final how in ['throw', 'lose', 'hang']) {
      test('a token the keystore does not keep ($how): told, undone, nothing piles up', () async {
        final prefs = MemoryAppPrefs();
        final app = AppController(
          tokens: FailingWrites(how),
          prefs: prefs,
          platform: DevicePlatform.windows,
          liveEnabled: false,
        )..keystoreTimeout = const Duration(milliseconds: 200);
        expect(await app.connect(server.base.toString(), 'secret'), isFalse);
        expect(app.error, ConnectError.keystore);
        expect(app.errorMessage, isNotEmpty);
        expect(app.connecting, isFalse);
        expect(app.servers, isEmpty, reason: 'no server saved without its token');
        final paired = server.requests.where((r) => r.startsWith('POST /api/app/pair')).length;
        final revoked = server.requests.where((r) => r.startsWith('DELETE /api/devices/')).length;
        expect(paired, 1);
        expect(revoked, 1, reason: 'the device just made is revoked');
      });
    }

    test(
      '«Togli quelli mai usati»: the never-used devices go, this one and the used ones stay',
      () async {
        server.devices.addAll([
          {
            'id': 'u1',
            'name': 'Rasgeth (Windows)',
            'platform': 'windows',
            'createdAt': '2026-11-19T10:00:00.000Z',
            'lastUsedAt': null,
          },
          {
            'id': 'u2',
            'name': 'Rasgeth (Windows)',
            'platform': 'windows',
            'createdAt': '2026-11-19T11:00:00.000Z',
            'lastUsedAt': null,
          },
        ]);
        final before = server.devices.length;
        final c = RedGiantClient(server.base, token: 'rgd_x');
        server.tokens.add('rgd_x');
        expect(await c.forgetUnusedDevices(), 2);
        expect(server.devices, hasLength(before - 2));
        expect(server.devices.map((d) => d['id']), isNot(contains('u1')));
        expect(await c.forgetUnusedDevices(), 0);
        c.close();
      },
    );
  });
}
