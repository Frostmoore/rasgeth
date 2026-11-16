import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
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
    AppController make(MemoryTokenStore t, MemoryAppPrefs p, {bool live = true}) =>
        AppController(tokens: t, prefs: p, platform: DevicePlatform.linux, liveEnabled: live);

    test('connect keeps only the token, in the keystore; a restart uses it', () async {
      final store = MemoryTokenStore();
      final prefs = MemoryAppPrefs();
      final app = make(store, prefs, live: false);
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      expect(app.connected, isTrue);
      expect(app.agents, isNotEmpty);
      expect(app.servers, hasLength(1));
      expect(store.values.values.where((v) => v.startsWith('rgd_')), hasLength(1));
      expect(store.values.values.any((v) => v.contains('secret')), isFalse);
      expect(prefs.values.values.any((v) => v.contains('rgd_') || v.contains('secret')), isFalse);
      expect(server.requests.where((r) => r.startsWith('POST /api/app/pair')), hasLength(1));

      final again = make(store, prefs, live: false);
      await again.restore();
      expect(again.connected, isTrue);
      expect(again.hello?.deviceName, 'RGCompanion (Linux)');
      expect(server.requests.where((r) => r.startsWith('POST /api/app/pair')), hasLength(1));

      await again.disconnect();
      expect(store.values, isEmpty);
      expect(again.servers, isEmpty);
    });

    test("a new Chat's first message names it; a title from the server stays", () async {
      final app = make(MemoryTokenStore(), MemoryAppPrefs(), live: false);
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      final sid = await app.newChatSession();
      expect(sid, isNotNull);
      expect(await app.send(sid!, 'Che tempo fa domani a Bologna?\nE dopodomani?'), isTrue);
      await until(() => server.requests.any((x) => x.startsWith('PATCH /api/sessions/$sid')));
      expect(
        server.sessions.firstWhere((x) => x['id'] == sid)['title'],
        'Che tempo fa domani a Bologna?',
      );
      expect(
        app.live.sessions.firstWhere((x) => x.id == sid).title,
        'Che tempo fa domani a Bologna?',
      );
      // A second message does not rename it; a conversation the server named keeps its title.
      expect(await app.send(sid, 'Grazie'), isTrue);
      expect(server.requests.where((x) => x.startsWith('PATCH')), hasLength(1));
      final other = await app.newChatSession();
      server.sessions.firstWhere((x) => x['id'] == other)['title'] = 'Dal server';
      await app.refresh();
      expect(await app.send(other!, 'Ciao'), isTrue);
      expect(server.requests.where((x) => x.startsWith('PATCH')), hasLength(1));
    });

    test(
      'Stop on the long press interrupts every turn the agent runs (REST without socket)',
      () async {
        final app = make(MemoryTokenStore(), MemoryAppPrefs(), live: false);
        expect(await app.connect(server.base.toString(), 'secret'), isTrue);
        server.sessions.first['running'] = true;
        await app.refresh();
        final agentId = server.sessions.first['agentId'] as String;
        expect(app.runningOf(agentId), hasLength(1));
        expect(await app.stopAgent(agentId), isTrue);
        expect(server.requests, contains(startsWith('POST /api/sessions/s1/interrupt')));
      },
    );

    test('theme, language and motion survive a restart', () async {
      final prefs = MemoryAppPrefs();
      final app = make(MemoryTokenStore(), prefs)
        ..setThemeMode(ThemeMode.dark)
        ..setLocale(const Locale('en'))
        ..setReduceMotion(true);
      await Future<void>.delayed(Duration.zero);
      expect(app.themeMode, ThemeMode.dark);
      final again = make(MemoryTokenStore(), prefs);
      await again.restore();
      expect(again.themeMode, ThemeMode.dark);
      expect(again.locale, const Locale('en'));
      expect(again.reduceMotion, isTrue);
    });

    test('a server speaking a newer app protocol is refused before the password', () async {
      server.appProtocol = kAppProtocolVersion + 1;
      final app = make(MemoryTokenStore(), MemoryAppPrefs());
      expect(await app.connect(server.base.toString(), 'secret'), isFalse);
      expect(app.error, ConnectError.tooNew);
      expect(server.requests.where((r) => r.startsWith('POST')), isEmpty);
    });

    test('a wrong password is ConnectError.wrong', () async {
      final app = make(MemoryTokenStore(), MemoryAppPrefs());
      expect(await app.connect(server.base.toString(), 'nope'), isFalse);
      expect(app.error, ConnectError.wrong);
      expect(app.connected, isFalse);
    });

    test('the live socket: requests, a followed conversation streaming, the answers', () async {
      final app = make(MemoryTokenStore(), MemoryAppPrefs());
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      await until(() => app.liveStatus == LiveStatus.open);
      expect(server.received.first['type'], 'hello');
      expect(server.received.first['token'], startsWith('rgd_'));
      expect(app.live.forYou, 2);
      final quick = app.live.approvals.firstWhere((r) => r.requestId == 'r1');
      final critical = app.live.approvals.firstWhere((r) => r.requestId == 'r2');
      expect(quick.isCritical, isFalse);
      expect(critical.isCritical, isTrue);
      // Never the quick yes for a critical one.
      expect(await app.resolvePermission(critical, allow: true), isFalse);
      expect(server.answered, isEmpty);
      expect(await app.resolvePermission(quick, allow: true), isTrue);
      await until(() => app.live.forYou == 1);
      expect(server.answered['r1'], 'allow');
      expect(app.live.lastClosedVia, 'app (test)');
      expect(await app.resolvePermission(critical, allow: true, fromFullScreen: true), isTrue);
      await until(() => app.live.forYou == 0);

      final view = app.follow('s1');
      await until(() => view.synced);
      expect(await app.send('s1', 'Ciao'), isTrue);
      await until(() => view.events.any((e) => e.type == 'message.assistant') && !view.running);
      final items = view.items;
      expect(items.whereType<UserItem>().single.text, 'Ciao');
      final a = items.whereType<AssistantItem>().single;
      expect(a.text, 'Hello **there**');
      expect(a.thinking, 'Let me see');
      expect(view.liveText, isEmpty);
      await app.disconnect();
    });

    test('Chat: its agent, a new conversation listed', () async {
      final app = make(MemoryTokenStore(), MemoryAppPrefs(), live: false);
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      final id = await app.newChatSession();
      expect(app.chatAgentId, 'chat');
      expect(app.live.sessions.any((s) => s.id == id && s.agentId == 'chat'), isTrue);
    });

    test('Activity: the tasks of every project', () async {
      final app = make(MemoryTokenStore(), MemoryAppPrefs(), live: false);
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      final tasks = await allTasks(app.client!);
      expect(tasks.map((t) => t.title), ['Add the --json flag', 'Prices page', 'Fix the README']);
      expect(tasks.first.done, isFalse);
      expect(tasks.last.outcome, TaskOutcome.verified);
    });
  });
}

Future<void> until(bool Function() ok, {Duration within = const Duration(seconds: 10)}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw StateError('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
