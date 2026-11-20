// 3.9.8: against a server (a real socket, so no widget binding in this file): the old token
// carried over signs in at once; «Abbina di nuovo» keeps the same entry and revokes the old device.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
          {...kCoder, 'address': server.base.toString(), 'label': 'Lavoro'}
            ..remove('fingerprint'),
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
}
