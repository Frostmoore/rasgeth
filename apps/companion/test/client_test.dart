import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_server.dart';

void main() {
  late FakeRedGiant server;
  setUp(() async => server = await FakeRedGiant.start());
  tearDown(() => server.close());

  group('RedGiantClient', () {
    test('the address the person types becomes scheme, host and port', () {
      expect(
        RedGiantClient.normalizeBase(Uri.parse('redgiant.local:8787')).toString(),
        'https://redgiant.local:8787',
      );
      expect(
        RedGiantClient.normalizeBase(Uri.parse('http://10.42.0.1:8787/x/y')).toString(),
        'http://10.42.0.1:8787',
      );
    });

    test('hello: who the server is, not signed in without a token', () async {
      final h = await RedGiantClient(server.base).hello();
      expect(h.machine, 'RedGiant di casa');
      expect(h.version, '3.8.0');
      expect(h.appProtocol, kAppProtocolVersion);
      expect(h.access.password, isTrue);
      expect(h.signedIn, isFalse);
      expect(compatibilityOf(h), Compatibility.ok);
    });

    test('pair: the password once for the device token, then the agents with it', () async {
      final c = RedGiantClient(server.base);
      final created = await c.pair(
        password: 'secret',
        name: 'RGCompanion (Linux)',
        platform: DevicePlatform.linux,
      );
      expect(created.token, startsWith('rgd_'));
      expect(created.device.platform, DevicePlatform.linux);
      expect(c.token, created.token);
      expect((await c.hello()).signedIn, isTrue);
      final agents = await c.agents();
      expect(agents.first.kind, AgentKind.god);
      expect(agents.first.mascot?.handDrawn, isTrue);
      expect(agents.every((a) => a.mascot != null), isTrue);
    });

    test('a wrong password says why, with the server code', () async {
      final c = RedGiantClient(server.base);
      await expectLater(
        c.pair(password: 'nope', name: 'x', platform: DevicePlatform.android),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having((e) => e.code, 'code', 'wrong'),
        ),
      );
      expect(c.token, isNull);
    });

    test('the code is asked when it is on', () async {
      server.codeOn = true;
      final c = RedGiantClient(server.base);
      await expectLater(
        c.pair(password: 'secret', name: 'x', platform: DevicePlatform.ios),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'code_needed')),
      );
      final ok = await c.pair(
        password: 'secret',
        code: '123456',
        name: 'x',
        platform: DevicePlatform.ios,
      );
      expect(ok.token, isNotEmpty);
    });

    test('without a token the agents are refused', () async {
      await expectLater(
        RedGiantClient(server.base).agents(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test("a mascot's SVG asks for state, theme and size", () async {
      final c = RedGiantClient(server.base);
      await c.pair(password: 'secret', name: 'x', platform: DevicePlatform.linux);
      final svg = await c.mascotSvg('a3', state: MascotState.think, theme: MascotTheme.dark);
      expect(svg, startsWith('<svg'));
      expect(svg, contains('st-think'));
      expect(server.requests.last, contains('format=svg'));
      expect(server.requests.last, contains('state=think'));
      expect(server.requests.last, contains('theme=dark'));
      final spec = await c.mascotSpec('a3');
      expect(spec.seed, 'Coder Web');
    });

    test('a closed port is «unreachable», not a crash', () async {
      final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = s.port;
      await s.close();
      await expectLater(
        RedGiantClient(Uri.parse('http://127.0.0.1:$port')).hello(),
        throwsA(isA<ApiException>().having((e) => e.unreachable, 'unreachable', isTrue)),
      );
    });

    test('a server that is not RedGiant is said so', () async {
      final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      other.listen((r) {
        r.response.write('<html>router</html>');
        r.response.close();
      });
      await expectLater(
        RedGiantClient(Uri.parse('http://127.0.0.1:${other.port}')).hello(),
        throwsA(isA<ApiException>().having((e) => e.unreachable, 'unreachable', isTrue)),
      );
      await other.close(force: true);
    });
  });

  group('AppController', () {
    test('connect keeps only the token, in the store; restore uses it', () async {
      final store = MemoryTokenStore();
      final app = AppController(tokens: store, platform: DevicePlatform.linux);
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      expect(app.connected, isTrue);
      expect(app.agents, isNotEmpty);
      expect(store.values.values.where((v) => v.startsWith('rgd_')), hasLength(1));
      expect(store.values.values.any((v) => v.contains('secret')), isFalse);
      expect(server.requests.where((r) => r.startsWith('POST /api/app/pair')), hasLength(1));

      final again = AppController(tokens: store, platform: DevicePlatform.linux);
      await again.restore();
      expect(again.connected, isTrue);
      expect(again.hello?.deviceName, 'RGCompanion (Linux)');
      expect(server.requests.where((r) => r.startsWith('POST /api/app/pair')), hasLength(1));

      await again.disconnect();
      expect(store.values, isEmpty);
    });

    test('a server speaking a newer app protocol is refused before the password', () async {
      server.appProtocol = kAppProtocolVersion + 1;
      final app = AppController(tokens: MemoryTokenStore(), platform: DevicePlatform.android);
      expect(await app.connect(server.base.toString(), 'secret'), isFalse);
      expect(app.error, ConnectError.tooNew);
      expect(server.requests.where((r) => r.startsWith('POST')), isEmpty);
    });

    test('a wrong password is ConnectError.wrong', () async {
      final app = AppController(tokens: MemoryTokenStore(), platform: DevicePlatform.android);
      expect(await app.connect(server.base.toString(), 'nope'), isFalse);
      expect(app.error, ConnectError.wrong);
      expect(app.connected, isFalse);
    });
  });
}
