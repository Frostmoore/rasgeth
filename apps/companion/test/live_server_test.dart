// The app against a real RedGiant started locally with FakeProvider (no real model): the demo
// server of the monorepo with a password,
//   DEMO_PASSWORD=companion-test-1 DEMO_HOST=127.0.0.1 DEMO_REQUESTS=1 \
//     node packages/web/scripts/demo-server.mjs 7651
//   RG_LIVE_URL=http://127.0.0.1:7651 RG_LIVE_PASSWORD=companion-test-1 flutter test test/live_server_test.dart
// Skipped without RG_LIVE_URL (the CI runs the recorded vectors and the fake server instead).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/setup_channel.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart' show WallFilter;
import 'package:rgcompanion/desktop/wall.dart' show wallSections;
import 'package:rgcompanion/l10n/app_localizations.dart';

final _url = Platform.environment['RG_LIVE_URL'];
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

Future<void> until(
  bool Function() ok, {
  Duration within = const Duration(seconds: 20),
  String what = 'condition',
}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('$what not met');
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

  test(
    'two devices on one RedGiant: what one writes, and the answer, show live on the other',
    () async {
      Future<AppController> device(DevicePlatform p) async {
        final a = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p);
        expect(await a.connect(base.toString(), _password), isTrue, reason: '${a.error}');
        await until(() => a.liveStatus == LiveStatus.open);
        return a;
      }

      final phone = await device(DevicePlatform.android);
      final pc = await device(DevicePlatform.linux);
      final sid = await phone.newChatSession();
      expect(sid, isNotNull);
      final onPhone = phone.follow(sid!);
      final onPc = pc.follow(sid);
      // A second screen on it closes (the panel's floating copy): the first one stays live.
      pc.follow(sid);
      pc.unfollow(sid);
      await until(() => onPhone.synced && onPc.synced, what: 'synced');

      expect(await phone.send(sid, 'Written on the phone'), isTrue);
      await until(
        () => onPc.events.any((e) => e.type == 'message.user'),
        within: const Duration(seconds: 30),
        what: 'user on pc',
      );
      await until(
        () => onPc.events.any((e) => e.type == 'message.assistant') && !onPc.running,
        within: const Duration(seconds: 60),
        what: 'answer on pc',
      );
      final users = onPc.events.where((e) => e.type == 'message.user').length;
      // The other device lists the new conversation by itself.
      await until(() => pc.live.sessions.any((s) => s.id == sid), what: 'listed on the other');

      expect(await pc.send(sid, 'Written on the computer'), isTrue);
      await until(
        () => onPhone.events.where((e) => e.type == 'message.user').length > users,
        within: const Duration(seconds: 30),
        what: 'user on phone',
      );
      await until(
        () =>
            onPhone.events.where((e) => e.type == 'message.assistant').length >= 2 &&
            !onPhone.running,
        within: const Duration(seconds: 60),
        what: 'answer on phone',
      );
      await phone.disconnect();
      await pc.disconnect();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'p3.8.9: a project, its agents and a conversation made elsewhere show live in the app, and back',
    () async {
      Future<AppController> device(DevicePlatform p) async {
        final a = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p);
        expect(await a.connect(base.toString(), _password), isTrue, reason: '${a.error}');
        await until(() => a.liveStatus == LiveStatus.open);
        return a;
      }

      // The Windows app, the wall in view; the other device makes things as the page does.
      final pc = await device(DevicePlatform.windows);
      final other = await device(DevicePlatform.android);
      final c = other.client!;
      // A page on the same RedGiant: a bare /ws, following nothing.
      final page = await WebSocket.connect('${base.toString().replaceFirst('http', 'ws')}/ws');
      final heard = <Map<String, dynamic>>[];
      page.listen((d) => heard.add(jsonDecode(d as String) as Map<String, dynamic>));
      page.add(
        jsonEncode({'type': 'hello', 'protocolVersion': kWireProtocolVersion, 'token': c.token}),
      );
      await until(() => heard.any((m) => m['type'] == 'welcome'), what: 'page welcome');

      final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final project = await c.createProject('GAIA $stamp');
      await until(() => pc.projects.any((p) => p.id == project.id), what: 'the project in the app');
      final god = pc.agents.firstWhere((a) => a.kind == AgentKind.god);
      final orch = await c.createAgent(
        kind: 'orchestrator',
        parentId: god.id,
        name: 'Orchestratore $stamp',
        projectId: project.id,
      );
      final dev = await c.createAgent(
        kind: 'agent',
        parentId: orch.id,
        name: 'Sviluppatore $stamp',
        projectId: project.id,
      );
      await until(
        () => pc.agents.any((a) => a.id == orch.id) && pc.agents.any((a) => a.id == dev.id),
        what: 'the agents in the app',
      );
      final sid = await c.newSession(god.id);
      await until(() => pc.live.sessions.any((s) => s.id == sid), what: "God's conversation");
      await c.renameSession(sid, 'Rinominata $stamp');
      await until(
        () => pc.live.sessions.any((s) => s.id == sid && s.title == 'Rinominata $stamp'),
        what: 'the new title',
      );

      // The other way: what the app makes reaches the page at once.
      final before = heard.length;
      final made = await pc.createAgent(
        kind: 'agent',
        parentId: orch.id,
        name: 'Dalla app $stamp',
        projectId: project.id,
      );
      await until(
        () => heard
            .skip(before)
            .any((m) => m['type'] == 'lists.changed' && (m['lists'] as List).contains('agents')),
        what: 'lists.changed on the page',
      );
      await until(() => other.agents.any((a) => a.id == made.id), what: 'on the other device');
      await page.close();
      await pc.disconnect();
      await other.disconnect();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    "p3.8.9, the person's case: God makes an orchestrator with create_agent while the app is open",
    () async {
      Future<AppController> device(DevicePlatform p) async {
        final a = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p)
          ..locale = const Locale('it');
        expect(await a.connect(base.toString(), _password), isTrue, reason: '${a.error}');
        await until(() => a.liveStatus == LiveStatus.open);
        return a;
      }

      // The Windows app open on the wall; the page (another device) talks to God.
      final pc = await device(DevicePlatform.windows);
      final other = await device(DevicePlatform.android);
      final c = other.client!;
      final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final project = await c.createProject('GAIA $stamp');
      final god = pc.agents.firstWhere((a) => a.kind == AgentKind.god);
      final sid = await c.newSession(god.id);
      final name = 'Orchestratore GAIA $stamp';
      final page = await WebSocket.connect('${base.toString().replaceFirst('http', 'ws')}/ws');
      final heard = <Map<String, dynamic>>[];
      page.listen((d) => heard.add(jsonDecode(d as String) as Map<String, dynamic>));
      page.add(
        jsonEncode({'type': 'hello', 'protocolVersion': kWireProtocolVersion, 'token': c.token}),
      );
      await until(() => heard.any((m) => m['type'] == 'welcome'), what: 'page welcome');
      page.add(
        jsonEncode({
          'type': 'session.send',
          'sessionId': sid,
          'text': "Crea l'orchestratore $name nel progetto ${project.id}",
        }),
      );
      // Whatever the turn asks the person is allowed from the page, as she would.
      final answered = <String>{};
      await until(() {
        for (final m in heard.toList()) {
          final r = m['request'];
          if (m['type'] == 'permission.request' && r is Map && answered.add('${r['requestId']}')) {
            page.add(
              jsonEncode({
                'type': 'permission.resolve',
                'requestId': r['requestId'],
                'decision': 'allow',
              }),
            );
          }
        }
        return pc.agents.any((a) => a.name == name);
      }, what: 'the orchestrator in the app, without opening it again');
      final orch = pc.agents.firstWhere((a) => a.name == name);
      expect(orch.projectId, project.id);
      // On the wall and in the mascots' bar (both draw wallSections), under its project.
      final l = lookupAppLocalizations(const Locale('it'));
      final sections = wallSections(pc, l, byProject: true, filter: WallFilter.all);
      expect(
        sections.any((x) => x.title == project.name && x.agents.any((a) => a.id == orch.id)),
        isTrue,
      );
      expect(pc.projects.any((p) => p.id == project.id), isTrue);
      // God's new conversation, named by its first message, is in the lists.
      await until(
        () => pc.live.sessions.any((s) => s.id == sid && (s.title ?? '').startsWith('Crea')),
        what: "God's conversation with its title",
      );
      await page.close();
      await pc.disconnect();
      await other.disconnect();
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
