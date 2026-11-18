// G40.10 against a real Rasgeth (the monorepo's demo server, FakeProvider, no real model): the
// app registers an endpoint of its own (a local HTTP listener standing in for the distributor),
// the server's own code seals the test notification and the withdrawal of a request for this
// device's keys, the app opens them; a quick yes to a critical request is refused by the server;
// the voice routes answer with their codes, said in Italian.
//   DEMO_PASSWORD=companion-test-1 DEMO_HOST=127.0.0.1 DEMO_REQUESTS=1 DEMO_CRITICAL=1 \
//     [DEMO_VOICE=1] node packages/web/scripts/demo-server.mjs 7651
//   RG_LIVE_URL=http://127.0.0.1:7651 [RG_LIVE_VOICE=1] flutter test test/push_live_test.dart
// Skipped without RG_LIVE_URL.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/push/notice.dart';
import 'package:rgcompanion/push/system_notifier.dart';
import 'package:rgcompanion/voice/voice_words.dart';

final _url = Platform.environment['RG_LIVE_URL'];
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _voice = Platform.environment['RG_LIVE_VOICE'] != null;

Future<T> within<T>(Future<T> f, [Duration d = const Duration(seconds: 20)]) => f.timeout(d);

/// A WAV of [seconds] of silence (16 kHz, mono, 16 bits).
Uint8List wav(double seconds) {
  final n = (16000 * seconds).round() * 2;
  final b = ByteData(44 + n);
  void s(int o, String t) {
    for (var i = 0; i < t.length; i++) {
      b.setUint8(o + i, t.codeUnitAt(i));
    }
  }

  s(0, 'RIFF');
  b.setUint32(4, 36 + n, Endian.little);
  s(8, 'WAVEfmt ');
  b.setUint32(16, 16, Endian.little);
  b.setUint16(20, 1, Endian.little);
  b.setUint16(22, 1, Endian.little);
  b.setUint32(24, 16000, Endian.little);
  b.setUint32(28, 32000, Endian.little);
  b.setUint16(32, 2, Endian.little);
  b.setUint16(34, 16, Endian.little);
  s(36, 'data');
  b.setUint32(40, n, Endian.little);
  return b.buffer.asUint8List();
}

void main() {
  final skip = _url == null ? 'RG_LIVE_URL not set' : null;
  final it = lookupAppLocalizations(const Locale('it'));

  test(
    'the server seals for this device; the app opens it; critical quick yes refused',
    () async {
      HttpOverrides.global = null;
      // The distributor's stand-in: every POST kept with its headers.
      final got = StreamController<({Map<String, String> headers, Uint8List body})>();
      final endpoint = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      endpoint.listen((r) async {
        final bytes = await r.fold<List<int>>([], (a, b) => a..addAll(b));
        got.add((
          headers: {
            'content-encoding': r.headers.value('content-encoding') ?? '',
            'authorization': r.headers.value('authorization') ?? '',
            'topic': r.headers.value('topic') ?? '',
          },
          body: Uint8List.fromList(bytes),
        ));
        r.response.statusCode = 201;
        await r.response.close();
      });
      final messages = StreamIterator(got.stream);
      final notes = MemoryNotifier();
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        notifier: notes,
      );
      expect(await app.connect(_url!, _password), isTrue, reason: '${app.error}');
      final sid = app.server!.id;
      final deviceId = app.hello!.deviceId!;
      final c = app.client!;
      expect((await c.pushInfo()).vapidPublicKey, isNotNull);

      // Registered as a distributor would give it.
      final up = 'http://127.0.0.1:${endpoint.port}/up/rgcompanion-test';
      expect(await app.pushCenter.onEndpoint(sid, up), isTrue);
      final me = (await c.devices()).firstWhere((d) => d.current);
      expect(me.push?['kind'], 'webpush');
      expect(me.push?['target'], '127.0.0.1:${endpoint.port}');

      // The test notification, sealed by the server.
      expect(await c.pushTest(deviceId), isNull);
      expect(await within(messages.moveNext()), isTrue);
      final test = messages.current;
      expect(test.headers['content-encoding'], 'aes128gcm');
      expect(test.headers['authorization'], startsWith('vapid t='));
      final n = await app.pushCenter.onMessage(sid, test.body);
      expect(n?.kind, NoticeKind.test);
      expect(notes.shown.values.single.title, anyOf('Prova delle notifiche', 'Notification test'));

      // A quick yes to a truly dangerous request: the server refuses it.
      final waiting = await c.permissions();
      // ignore: avoid_print
      print('waiting ${waiting.length}: ${[for (final r in waiting) r.isCritical]}');
      expect(waiting, isNotEmpty);
      final critical = waiting.where((r) => r.isCritical).firstOrNull;
      if (critical != null) {
        await expectLater(
          c.answerRequest(critical.requestId, allow: true),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 'open_app')),
        );
      }
      // A no from here (always allowed): its withdrawal comes sealed too, and takes away the
      // notification shown for it.
      final answered = waiting.firstWhere((r) => !r.isCritical, orElse: () => waiting.first);
      final shownId = notificationIdOf(sid, 'req:${answered.requestId}');
      notes.shown[shownId] = planFor(
        PushNotice(
          id: 'req:${answered.requestId}',
          kind: NoticeKind.request,
          server: 'x',
          title: 't',
          body: 'b',
          requestId: answered.requestId,
        ),
        sid,
      ) as ShowNotification;
      await c.answerRequest(answered.requestId, allow: false);
      expect(await within(messages.moveNext()), isTrue);
      final w = await app.pushCenter.onMessage(sid, messages.current.body);
      // ignore: avoid_print
      print('withdrawal: ${w?.title} / ${w?.body} via ${w?.closedVia}');
      expect(w?.closed, isTrue);
      expect(w?.requestId, answered.requestId);
      expect(notes.shown.containsKey(shownId), isFalse);

      // Off: the server forgets the channel.
      await app.pushCenter.registrar.unregister(c, sid, deviceId);
      expect((await c.devices()).firstWhere((d) => d.current).push, isNull);
      await messages.cancel();
      await endpoint.close(force: true);
      await app.disconnect();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('the voice routes: their codes in the person language', () async {
    HttpOverrides.global = null;
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.linux,
      liveEnabled: false,
    );
    expect(await app.connect(_url!, _password), isTrue, reason: '${app.error}');
    final c = app.client!;
    if (_voice) {
      // DEMO_VOICE: the demo's transcription service hears its sentence in every recording.
      expect(await c.transcribe(wav(1), 'audio/wav', 'it'), isNotEmpty);
    } else {
      try {
        await c.transcribe(wav(1), 'audio/wav', 'it');
        fail('the demo has no transcription without DEMO_VOICE');
      } on VoiceException catch (e) {
        // ignore: avoid_print
        print('transcribe: ${e.code} → ${voiceErrorText(it, e)}');
        expect(e.code, isNotNull);
        expect(voiceErrorText(it, e), isNot(it.voiceErrOther));
      }
    }
    // No key for reading in the demo: said, not a generic failure.
    try {
      await c.speech(provider: 'openai', model: 'gpt-4o-mini-tts', voice: 'marin', text: 'Ciao');
      fail('the demo has no OpenAI key');
    } on VoiceException catch (e) {
      // ignore: avoid_print
      print('speech: ${e.code} → ${voiceErrorText(it, e)}');
      expect(voiceErrorText(it, e), isNot(it.voiceErrOther));
    }
    await app.disconnect();
  }, skip: skip);
}
