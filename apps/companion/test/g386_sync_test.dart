// 3.8.6: two devices on one RedGiant see each other's messages live. The fake server sends a
// conversation's events only to the connections that follow it and honours `session.unfollow`, as
// core.follow and ws.ts do; before, it sent them to the writer only and hid the bugs below.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_server.dart';

Future<void> until(
  bool Function() ok, {
  String what = 'condition',
  Duration within = const Duration(seconds: 5),
}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('$what not met');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

int users(SessionView v) => v.events.where((e) => e.type == 'message.user').length;

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
  });
  tearDown(() => server.close());

  Future<AppController> device(DevicePlatform p) async {
    final a = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p);
    expect(await a.connect(server.base.toString(), 'secret'), isTrue, reason: '${a.error}');
    await until(() => a.liveStatus == LiveStatus.open, what: 'live');
    addTearDown(a.disconnect);
    return a;
  }

  test('what the phone writes, and the answer, show on the computer, and back', () async {
    final phone = await device(DevicePlatform.android);
    final pc = await device(DevicePlatform.linux);
    final onPhone = phone.follow('s1');
    final onPc = pc.follow('s1');
    await until(() => onPhone.synced && onPc.synced, what: 'synced');

    expect(await phone.send('s1', 'from the phone'), isTrue);
    await until(() => users(onPc) == 1, what: 'the message on the computer');
    await until(
      () => onPc.events.any((e) => e.type == 'message.assistant') && !onPc.running,
      what: 'the answer on the computer',
    );
    expect(await pc.send('s1', 'from the computer'), isTrue);
    await until(() => users(onPhone) == 2, what: 'the message on the phone');
    expect(onPhone.items.length, onPc.items.length);
  });

  test('two screens on one conversation: closing one leaves the other live', () async {
    // The computer's panel and its floating copy (or a task's detail over the conversation):
    // the new screen follows before the old one is disposed and unfollows.
    final pc = await device(DevicePlatform.linux);
    final phone = await device(DevicePlatform.android);
    final view = pc.follow('s1');
    pc.follow('s1');
    pc.unfollow('s1');
    await until(() => view.synced, what: 'synced');
    phone.follow('s1');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await phone.send('s1', 'from the phone'), isTrue);
    await until(() => users(view) == 1, what: 'the message on the computer');
    // The last screen closing does tell the server.
    pc.unfollow('s1');
    await until(
      () => server.received.where((m) => m['type'] == 'session.unfollow').length == 1,
      what: 'one unfollow',
    );
  });

  group('a link that looks open and is dead', () {
    Future<LiveSocket> socket({Duration heartbeat = const Duration(hours: 1)}) async {
      server.tokens.add('rgd_sync');
      final s = LiveSocket(
        open: () => WebSocket.connect('ws://${server.base.authority}/ws'),
        token: 'rgd_sync',
        heartbeat: heartbeat,
        answerWithin: const Duration(milliseconds: 200),
      );
      addTearDown(s.close);
      await s.start();
      await until(() => s.status == LiveStatus.open, what: 'open');
      return s;
    }

    Future<void> missedThenBack(LiveSocket s, void Function() wake) async {
      final model = LiveModel();
      final sub = s.messages.listen(model.apply);
      addTearDown(sub.cancel);
      s.follow('s1');
      await until(() => model.view('s1').synced, what: 'synced');
      server.deaden();
      // Written on another device while this link is dead: nothing arrives on it.
      server.say('s1', 'from the phone');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(users(model.view('s1')), 0);
      wake();
      await until(() => users(model.view('s1')) == 1, what: 'the missed message');
      expect(server.sockets.length, 1);
    }

    test('the heartbeat finds it, comes back and follows again from the last event', () async {
      final s = await socket(heartbeat: const Duration(milliseconds: 100));
      await missedThenBack(s, () {});
    });

    test('back in the foreground it is asked at once', () async {
      final s = await socket();
      await missedThenBack(s, s.checkNow);
    });
  });

  test('a new link: requests answered elsewhere meanwhile go away', () {
    final m = LiveModel();
    m.apply({
      'type': 'permission.request',
      'request': {
        'requestId': 'r1',
        'sessionId': 's1',
        'agentId': 'a0',
        'tool': 'bash',
        'input': <String, dynamic>{},
        'createdAt': '2026-11-17T10:00:00.000Z',
      },
    });
    expect(m.forYou, 1);
    // The server sends every waiting request again right after `welcome`.
    m.apply({'type': 'welcome', 'protocolVersion': 2, 'ownerId': 'me'});
    expect(m.forYou, 0);
  });
}
