// The notifications' registration and handling (G40.10) against the fake RedGiant: the keys are
// made once and kept (the server gets only the public half), `PUT /api/devices/:id/push` with the
// distributor's endpoint, `DELETE` and the keys forgotten; a message sealed for the device is
// shown and its withdrawal takes it away; a quick answer goes to `POST /api/app/requests/:id/answer`,
// never a quick yes for a critical request.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/push/ece.dart';
import 'package:rgcompanion/push/notice.dart';
import 'package:rgcompanion/push/push_center.dart';
import 'package:rgcompanion/push/registrar.dart';
import 'package:rgcompanion/push/system_notifier.dart';

import 'fake_server.dart';

void main() {
  late FakeRedGiant fake;
  late MemoryAppPrefs prefs;
  late MemoryTokenStore tokens;
  late MemoryNotifier shown;
  late PushCenter center;

  setUp(() async {
    HttpOverrides.global = null;
    fake = await FakeRedGiant.start();
    fake.tokens.add('rgd_1');
    prefs = MemoryAppPrefs();
    tokens = MemoryTokenStore();
    shown = MemoryNotifier();
    await ServerBook(prefs)
        .put(SavedServer(id: 'srv1', label: 'Casa', address: fake.base.toString(), deviceId: 'd1'));
    await tokens.write('srv1', 'rgd_1');
    center = PushCenter(prefs: prefs, tokens: tokens, notifier: shown);
  });
  tearDown(() => fake.close());

  Uint8List sealFor(PushKeyPair k, String json) =>
      encryptPush(utf8.encode(json), uaPublic: k.publicKey, auth: k.authSecret);

  test('the endpoint goes to the server with the public keys only; the keys stay', () async {
    expect(await center.onEndpoint('srv1', 'https://ntfy.sh/upAbc123'), isTrue);
    final body = fake.pushRegistrations['d1']!;
    expect(body['kind'], 'webpush');
    expect(body['endpoint'], 'https://ntfy.sh/upAbc123');
    final keys = (body['keys'] as Map<String, dynamic>).cast<String, String>();
    expect(keys.keys, unorderedEquals(['p256dh', 'auth']));
    final mine = await center.registrar.keysFor('srv1');
    expect(keys['p256dh'], mine.p256dh);
    expect(keys['auth'], mine.auth);
    expect(body.toString(), isNot(contains(b64u(mine.privateKey))));
    final st = await center.registrar.stateOf('srv1');
    expect(st?.kind, 'webpush');
    expect(st?.target, 'https://ntfy.sh/upAbc123');

    // A new endpoint later: the same keys.
    expect(await center.onEndpoint('srv1', 'https://ntfy.sh/upNew'), isTrue);
    expect((fake.pushRegistrations['d1']!['keys'] as Map)['p256dh'], mine.p256dh);
  });

  test('without a token or for an unknown RedGiant nothing is sent', () async {
    expect(await center.onEndpoint('nobody', 'https://ntfy.sh/x'), isFalse);
    await tokens.delete('srv1');
    expect(await center.onEndpoint('srv1', 'https://ntfy.sh/x'), isFalse);
    expect(fake.pushRegistrations, isEmpty);
  });

  test('unregistering tells the server and forgets the keys', () async {
    await center.onEndpoint('srv1', 'https://ntfy.sh/upAbc123');
    final before = await center.registrar.keysFor('srv1');
    final c = RedGiantClient(fake.base, token: 'rgd_1');
    await center.registrar.unregister(c, 'srv1', 'd1');
    expect(fake.pushDeletes, ['d1']);
    expect(fake.pushRegistrations, isEmpty);
    expect(await center.registrar.stateOf('srv1'), isNull);
    expect((await center.registrar.keysFor('srv1')).p256dh, isNot(before.p256dh));
    // Nothing registered: a 404 is not a failure.
    await center.registrar.unregister(c, 'srv1', 'd1');
    c.close();
  });

  test('the APNs body is prepared with the same keys', () async {
    final k = await center.registrar.keysFor('srv1');
    final b = PushRegistrar.apnsBody('a' * 64, k);
    expect(b['kind'], 'apns');
    expect(b['environment'], 'production');
    expect(b['keys'], k.publicJson);
  });

  test('a message sealed for this device is shown; its withdrawal takes it away', () async {
    final k = await center.registrar.keysFor('srv1');
    final n = await center.onMessage(
      'srv1',
      sealFor(
        k,
        '{"v":1,"id":"req:r1","kind":"request","server":"Casa","title":"God chiede il permesso",'
        '"body":"npm install","requestId":"r1","actions":["allow","deny"]}',
      ),
    );
    expect(n?.requestId, 'r1');
    final id = notificationIdOf('srv1', 'req:r1');
    expect(shown.shown[id]?.answers, [QuickAnswer.allow, QuickAnswer.deny]);
    await center.onMessage(
      'srv1',
      sealFor(
        k,
        '{"v":1,"id":"req:r1","kind":"request","server":"Casa","title":"Richiesta chiusa",'
        '"body":"Già risposta","requestId":"r1","closed":{"via":"app (Pixel)"}}',
      ),
    );
    expect(shown.shown, isEmpty);
    expect(shown.cancelled, [id]);
  });

  test('a message for another device, or garbage, shows nothing', () async {
    await center.registrar.keysFor('srv1');
    final other = PushKeyPair.generate();
    expect(
      await center.onMessage('srv1', sealFor(other, '{"v":1,"id":"test:x","kind":"test"}')),
      isNull,
    );
    expect(await center.onMessage('srv1', Uint8List.fromList([1, 2, 3])), isNull);
    expect(await center.onMessage('unknown', Uint8List(200)), isNull);
    expect(shown.shown, isEmpty);
  });

  test('a message the distributor already decrypted is read as it is', () async {
    final n = await center.onMessage(
      'srv1',
      Uint8List.fromList(
        '{"v":1,"id":"test:x","kind":"test","title":"Prova","body":"ok"}'.codeUnits,
      ),
      decrypted: true,
    );
    expect(n?.kind, NoticeKind.test);
  });

  group('quick answers', () {
    NoticeTap tap(String requestId, {bool critical = false}) => NoticeTap(
      serverId: 'srv1',
      noticeId: 'req:$requestId',
      kind: NoticeKind.request,
      requestId: requestId,
      critical: critical,
    );

    test('Yes on an ordinary request answers it and takes the notification away', () async {
      expect(await center.answer(tap('r1'), QuickAnswer.allow), AnswerOutcome.done);
      expect(fake.answered['r1'], 'allow');
      expect(shown.cancelled, [notificationIdOf('srv1', 'req:r1')]);
    });

    test('No is always sent', () async {
      expect(await center.answer(tap('r2', critical: true), QuickAnswer.deny), AnswerOutcome.done);
      expect(fake.answered['r2'], 'deny');
    });

    test('a quick yes on a critical request is never sent', () async {
      expect(
        await center.answer(tap('r2', critical: true), QuickAnswer.allow),
        AnswerOutcome.openApp,
      );
      expect(fake.answered, isEmpty);
      expect(fake.requests.where((r) => r.contains('/answer')), isEmpty);
    });

    test('the server refusing a quick yes: the notification says to open the app', () async {
      // A forged payload without the critical mark: the server's own rule refuses it.
      expect(await center.answer(tap('r2'), QuickAnswer.allow), AnswerOutcome.openApp);
      expect(fake.answered, isEmpty);
      final s = shown.shown[notificationIdOf('srv1', 'req:r2')]!;
      expect(s.answers, isEmpty);
      expect(s.title, 'The answer did not go');
    });

    test('answered elsewhere already: the notification goes', () async {
      expect(await center.answer(tap('gone'), QuickAnswer.allow), AnswerOutcome.gone);
      expect(shown.cancelled, [notificationIdOf('srv1', 'req:gone')]);
    });
  });
}
