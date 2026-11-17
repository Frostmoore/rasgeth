// p3.8.9: the person's Coder came back after a blackout and «not even the requests sync any
// more between the page and the app». A real RedGiant (packages/web/scripts/restart-server.mjs,
// PGlite in a folder, a scripted model) is killed while the app and a page are connected, stays
// down a while and starts again with the same database. The app must notice, come back, drop the
// requests that died with the old process, and from there get the new ones and their answers
// live, both ways. Run with (from the repository, the server started once first)
//   packages/web/scripts/restart-server-ctl.sh start
//   RG_RESTART_URL=http://127.0.0.1:7652 RG_RESTART_CTL=$PWD/packages/web/scripts/restart-server-ctl.sh \
//     flutter test test/restart_server_test.dart   (in apps/companion)
// `freeze` stops the server answering with the links open, `kill` kills it with SIGKILL, `start`
// starts it again on the same data. Skipped without them.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';

final _url = Platform.environment['RG_RESTART_URL'];
final _ctl = Platform.environment['RG_RESTART_CTL'];
const _password = 'companion-test-1';

Future<void> until(
  bool Function() ok, {
  Duration within = const Duration(seconds: 30),
  String what = 'condition',
}) async {
  // ignore: avoid_print
  print('waiting: $what');
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('$what not met');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<void> ctl(String what) async {
  // ignore: avoid_print
  print('rs.sh $what');
  if (what == 'start') {
    // Detached: the server outlives the script, whose output stays open with it.
    await Process.start(_ctl!, [what], mode: ProcessStartMode.detached);
    final end = DateTime.now().add(const Duration(seconds: 60));
    while (true) {
      try {
        final c = HttpClient()..connectionTimeout = const Duration(seconds: 2);
        final r = await (await c.getUrl(Uri.parse('$_url/api/app/hello'))).close();
        await r.drain<void>();
        c.close();
        if (r.statusCode == 200) return;
      } on Object {
        // Not yet.
      }
      if (DateTime.now().isAfter(end)) throw StateError('the server did not come back');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
  }
  final r = await Process.run(_ctl!, [what]).timeout(const Duration(seconds: 90));
  if (r.exitCode != 0) throw StateError('rs.sh $what: ${r.stderr}');
}

/// The page's live connection, as packages/web's `Live`: hello with `reloads`, and again after a
/// drop (the page's own reconnection is not under test here, what the server sends it is).
class Page {
  Page(this.base, this.token);
  final Uri base;
  final String token;
  WebSocket? ws;
  final heard = <Map<String, dynamic>>[];
  final waiting = <String>{};

  Future<void> open() async {
    final w = ws = await WebSocket.connect('${base.toString().replaceFirst('http', 'ws')}/ws');
    final mine = heard.length;
    w.listen((d) {
      final m = jsonDecode(d as String) as Map<String, dynamic>;
      heard.add(m);
      // As state.ts after this fix: a new link starts from what the server sends again.
      if (m['type'] == 'welcome') waiting.clear();
      if (m['type'] == 'permission.request') {
        waiting.add((m['request'] as Map<String, dynamic>)['requestId'] as String);
      }
      if (m['type'] == 'permission.closed') waiting.remove(m['requestId']);
    }, onError: (_) {});
    w.add(
      jsonEncode({
        'type': 'hello',
        'protocolVersion': kWireProtocolVersion,
        'token': token,
        'reloads': true,
      }),
    );
    await until(() => heard.skip(mine).any((m) => m['type'] == 'welcome'), what: 'page welcome');
  }

  void resolve(String id, String decision) =>
      ws!.add(jsonEncode({'type': 'permission.resolve', 'requestId': id, 'decision': decision}));
}

void main() {
  final skip = _url == null || _ctl == null ? 'RG_RESTART_URL and RG_RESTART_CTL not set' : null;
  final base = Uri.parse(_url ?? 'http://127.0.0.1:1');

  test(
    'the server dies and comes back: requests sync again, page and app, both ways',
    () async {
      Future<AppController> device(DevicePlatform p) async {
        final a = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p);
        expect(await a.connect(base.toString(), _password), isTrue, reason: '${a.error}');
        await until(() => a.liveStatus == LiveStatus.open, what: 'live');
        return a;
      }

      final pc = await device(DevicePlatform.windows);
      final phone = await device(DevicePlatform.android);
      final page = Page(base, phone.client!.token!);
      await page.open();
      final asker = pc.agents.firstWhere((a) => a.name == 'Chiede');
      final sid = await phone.client!.newSession(asker.id);

      // A request before the blackout: on the app and on the page.
      expect(await phone.send(sid, 'chiedi'), isTrue);
      await until(() => pc.live.approvals.isNotEmpty, what: 'the request on the app');
      await until(() => page.waiting.isNotEmpty, what: 'the request on the page');

      // The blackout: the machine stops answering with every link still open (frozen, nothing
      // closed: what a power cut looks like from the app), then the process is gone, down a
      // while, and up again on the same data.
      await ctl('freeze');
      await until(
        () => pc.liveStatus != LiveStatus.open,
        within: const Duration(seconds: 60),
        what: 'the app sees it go',
      );
      await ctl('kill');
      await Future<void>.delayed(const Duration(seconds: 8));
      await ctl('start');
      await page.open();

      // Back by itself; the request that died with the old process is gone everywhere.
      await until(
        () => pc.liveStatus == LiveStatus.open,
        within: const Duration(seconds: 60),
        what: 'the app back',
      );
      await until(() => pc.live.approvals.isEmpty, what: 'the dead request gone from the app');
      expect(page.waiting, isEmpty);

      // A new one reaches both; the page answers it, the app sees it closed.
      expect(await phone.send(sid, 'chiedi ancora'), isTrue);
      await until(() => pc.live.approvals.isNotEmpty, what: 'the new request on the app');
      await until(() => page.waiting.isNotEmpty, what: 'the new request on the page');
      page.resolve(page.waiting.first, 'allow');
      await until(() => pc.live.approvals.isEmpty, what: 'closed on the app');

      // And the other way: asked again, answered in the app, closed on the page.
      await until(() => !pc.live.sessions.any((s) => s.id == sid && s.running), what: 'idle');
      expect(await phone.send(sid, 'chiedi di nuovo'), isTrue);
      await until(() => pc.live.approvals.isNotEmpty, what: 'the third request on the app');
      await until(() => page.waiting.isNotEmpty, what: 'the third request on the page');
      final r = pc.live.approvals.first;
      expect(await pc.resolvePermission(r, allow: true, fromFullScreen: true), isTrue);
      await until(() => page.waiting.isEmpty, what: 'closed on the page');

      await page.ws?.close();
      await pc.disconnect();
      await phone.disconnect();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
