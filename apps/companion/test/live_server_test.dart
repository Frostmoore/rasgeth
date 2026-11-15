// The app against a real RedGiant started locally with FakeProvider (no real model): the demo
// server of the monorepo with a password,
//   DEMO_PASSWORD=companion-test-1 DEMO_HOST=127.0.0.1 DEMO_REQUESTS=1 \
//     node packages/web/scripts/demo-server.mjs 7651
//   RG_LIVE_URL=http://127.0.0.1:7651 RG_LIVE_PASSWORD=companion-test-1 flutter test test/live_server_test.dart
// Skipped without RG_LIVE_URL (the CI runs the recorded vectors and the fake server instead).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/setup_channel.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';

final _url = Platform.environment['RG_LIVE_URL'];
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

Future<void> until(bool Function() ok, {Duration within = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  final skip = _url == null ? 'RG_LIVE_URL not set' : null;
  final base = Uri.parse(_url ?? 'http://127.0.0.1:1');

  test('setup channel: handshake, sign-in inside it, a device token, the same key', () async {
    final id = (await DeviceIdentity.create()).identity;
    final ch = await SetupChannel.dial(base, identity: id);
    final info = await ch.info();
    expect(info['fingerprint'], ch.peerFingerprint);
    expect(ch.peerFingerprint, startsWith('SHA256:'));
    final bad = await ch.http('POST', '/api/auth/login', json: {'password': 'wrong-password-x'});
    expect(bad.status, 400);
    expect(bad.body, contains('"wrong"'));
    // Not signed in: no device token.
    await expectLater(ch.device('x', 'linux'), throwsA(isA<SetupRequestException>()));
    final ok = await ch.http('POST', '/api/auth/login', json: {'password': _password});
    expect(ok.status, 200);
    final d = await ch.device('RGCompanion (test)', 'linux');
    expect(d.token, startsWith('rgd_'));
    expect(d.fingerprint, ch.peerFingerprint);
    await ch.close();

    final c = RedGiantClient(base, token: d.token);
    final h = await c.hello();
    expect(h.signedIn, isTrue);
    expect(h.nodeFingerprint, ch.peerFingerprint);

    // The same machine with a different pinned key: refused before anything is sent.
    await expectLater(
      SetupChannel.dial(base, identity: id, expect: 'SHA256:not-this-one'),
      throwsA(
        isA<SetupChannelException>()
            .having((e) => e.code, 'code', SetupChannelErrorCode.fingerprintChanged)
            .having((e) => e.seen, 'seen', ch.peerFingerprint),
      ),
    );
    // Pinned and right: it opens.
    final again = await SetupChannel.dial(base, identity: id, expect: ch.peerFingerprint);
    expect((await again.info())['fingerprint'], ch.peerFingerprint);
    await again.close();
  }, skip: skip);

  test(
    'pairing by REST, the live socket, a conversation with a streamed answer',
    () async {
      final prefs = MemoryAppPrefs();
      final tokens = MemoryTokenStore();
      final app = AppController(tokens: tokens, prefs: prefs, platform: DevicePlatform.linux);
      expect(await app.connect(base.toString(), _password), isTrue, reason: '${app.error}');
      expect(app.server?.fingerprint, startsWith('SHA256:'));
      expect(app.agents.any((a) => a.kind == AgentKind.god), isTrue);
      await until(() => app.liveStatus == LiveStatus.open);
      // ignore: avoid_print
      print('live open; approvals ${app.live.approvals.length}');
      // DEMO_REQUESTS: the waiting requests, critical ones among them.
      await until(() => app.live.approvals.isNotEmpty);
      expect(app.live.forYou, greaterThan(0));

      // The everyday Chat (outside the demo's project, which is over its budget on purpose).
      final sid = await app.newChatSession();
      expect(sid, isNotNull);
      expect(app.chatAgentId, isNotNull);
      expect(app.live.sessions.any((s) => s.id == sid && s.agentId == app.chatAgentId), isTrue);
      final view = app.follow(sid!);
      await until(() => view.synced);
      expect(await app.send(sid, 'Hello from the app'), isTrue);
      await until(() => view.events.any((e) => e.type == 'message.user'));
      await until(
        () => view.events.any((e) => e.type == 'message.assistant') && !view.running,
        within: const Duration(seconds: 60),
      );
      final items = view.items;
      expect(items.whereType<Object>().length, greaterThan(1));

      // A second start: the token from the keystore, nothing typed.
      final again = AppController(tokens: tokens, prefs: prefs, platform: DevicePlatform.linux);
      await again.restore();
      expect(again.connected, isTrue);
      expect(again.server?.id, app.server?.id);
      await app.disconnect();
      await again.disconnect();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('pairing through the setup channel: the API rides it when there is no https', () async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
    );
    expect(
      await app.pairViaChannel(base, _password),
      isTrue,
      reason: '${app.error} ${app.errorMessage}',
    );
    expect(app.client!.transport.kind, TransportKind.channel);
    expect(app.isLive, isFalse);
    expect(app.agents, isNotEmpty);
    expect(app.server!.setupAddress, base.toString());
    await app.disconnect();
  }, skip: skip);
}
