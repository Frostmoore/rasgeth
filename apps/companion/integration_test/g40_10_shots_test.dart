// G40.10 in the real app against a real RedGiant (the demo server, FakeProvider): Tu ›
// Notifiche on a computer and, drawn as on Android, without a distributor, choosing one and
// on (the endpoint registered on the server, the test notification sealed by it and opened
// here); Tu › Voce; «press and talk» and «read aloud» in a conversation; «Share to RedGiant».
// A phone-sized window. Run by tool/linux_shots.sh with
//   RG_SCREEN=430x900 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_REQUESTS=1 DEMO_VOICE=1" \
//     … integration_test/g40_10_shots_test.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/push/distributors.dart';
import 'package:rgcompanion/push/system_notifier.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/notifications_screen.dart';
import 'package:rgcompanion/screens/share_screen.dart';
import 'package:rgcompanion/screens/voice_screen.dart';
import 'package:rgcompanion/share/share_intake.dart';
import 'package:rgcompanion/voice/audio.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

/// One second of silence as the microphone would record it (the demo hears its sentence).
class _Mic implements VoiceRecorder {
  @override
  Future<bool> allowed() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<Recording?> stop() async {
    final b = ByteData(44 + 32000);
    for (final (o, s) in [(0, 'RIFF'), (8, 'WAVEfmt '), (36, 'data')]) {
      for (var i = 0; i < s.length; i++) {
        b.setUint8(o + i, s.codeUnitAt(i));
      }
    }
    b
      ..setUint32(4, 36 + 32000, Endian.little)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, 16000, Endian.little)
      ..setUint32(28, 32000, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint32(40, 32000, Endian.little);
    return Recording(b.buffer.asUint8List(), 'audio/wav', const Duration(seconds: 1));
  }

  @override
  Future<void> cancel() async {}
}

class _Speaker implements VoicePlayer {
  @override
  Future<void> play(Uint8List bytes, String mimeType, {required int volume}) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<AppController> connected(
    WidgetTester t, {
    DevicePlatform platform = DevicePlatform.linux,
    Distributors? dist,
    MemoryNotifier? notes,
  }) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: platform,
      notifier: notes ?? MemoryNotifier(),
      distributors: dist == null ? null : (_) async => dist,
      recorder: _Mic(),
      player: _Speaker(),
    )..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(app.startSystems);
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t);
    return app;
  }

  Future<void> open(WidgetTester t, Widget screen) async {
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => screen)));
    await frames(t, 1500);
  }

  void back(WidgetTester t) => t.state<NavigatorState>(find.byType(Navigator).first).pop();

  testWidgets('G40.10: notifications, voice, sharing', (t) async {
    // ---- a computer: You, then Notifications ----
    var app = await connected(t);
    await shot(t, 'g4010-01-tu');
    await t.tap(find.byKey(const Key('open-notifications')));
    await frames(t, 1500);
    await shot(t, 'g4010-02-notifiche-computer');
    back(t);
    await frames(t);

    // ---- Android, drawn here: no distributor, then two, then on ----
    final dist = NoDistributors(supported: true);
    final notes = MemoryNotifier();
    app = await connected(t, platform: DevicePlatform.android, dist: dist, notes: notes);
    await open(t, const NotificationsScreen());
    await shot(t, 'g4010-03-notifiche-android-senza-distributore');
    dist.installed.addAll(['io.heckel.ntfy', 'org.unifiedpush.distributor.sunup']);
    await t.tap(find.byKey(const Key('push-look-again')));
    await frames(t, 1500);
    await shot(t, 'g4010-04-notifiche-android-scegli');

    // The distributor's stand-in: a local listener the real server sends to.
    final got = StreamController<Uint8List>();
    final endpoint = await t.runAsync(() => HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    endpoint!.listen((r) async {
      final bytes = await r.fold<List<int>>([], (a, b) => a..addAll(b));
      got.add(Uint8List.fromList(bytes));
      r.response.statusCode = 201;
      await r.response.close();
    });
    final inbox = StreamIterator(got.stream);
    await t.tap(find.byKey(const Key('push-on')));
    await frames(t, 1500);
    await shot(t, 'g4010-05-notifiche-android-attendo');
    final sid = app.server!.id;
    final up = 'http://127.0.0.1:${endpoint.port}/up/shots';
    final sent = await t.runAsync(() => app.pushCenter.onEndpoint(sid, up));
    dist.give(EndpointReady(sid, up, sent: sent!));
    await frames(t, 2000);
    await shot(t, 'g4010-06-notifiche-android-attive');
    // The test, sealed by the server for this device and opened here.
    await t.tap(find.byKey(const Key('push-test-here')));
    final moved = await t.runAsync(() => inbox.moveNext().timeout(const Duration(seconds: 20)));
    expect(moved, isTrue);
    final n = await t.runAsync(() => app.pushCenter.onMessage(sid, inbox.current));
    debugPrint('push test opened: ${n?.title} / ${n?.body}');
    expect(n?.title, anyOf('Prova delle notifiche', 'Notification test'));
    await frames(t);
    await shot(t, 'g4010-07-notifiche-android-prova');
    app.setThemeMode(ThemeMode.dark);
    await frames(t);
    await shot(t, 'g4010-08-notifiche-android-scuro');
    app.setThemeMode(ThemeMode.light);
    back(t);
    await frames(t);

    // ---- Voice: none in the demo, then a key for OpenAI ----
    await open(t, const VoiceScreen());
    await frames(t, 1500);
    await shot(t, 'g4010-09-voce-senza');
    back(t);
    await t.runAsync(
      () => app.client!.transport.send(
        'PUT',
        '/api/setup/voice-keys/openai',
        headers: {
          'authorization': 'Bearer ${app.client!.token}',
          'content-type': 'application/json',
        },
        body: utf8.encode(jsonEncode({'key': 'sk-proj-shots-0123456789'})),
      ),
    );
    await open(t, const VoiceScreen());
    await frames(t, 1500);
    await shot(t, 'g4010-10-voce-openai');
    back(t);
    await frames(t);

    // ---- A conversation with the Chat: press and talk, read aloud ----
    final chat = await t.runAsync(app.newChatSession);
    await open(t, ConversationScreen(sessionId: chat!, agent: app.chatAgent));
    await t.enterText(find.byKey(const Key('composer-text')), 'Ciao, come stai?');
    await t.tap(find.byKey(const Key('composer-send')));
    await waitFor(
      t,
      () => find
          .byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('read-aloud-'),
          )
          .evaluate()
          .isNotEmpty,
      seconds: 60,
    );
    await frames(t, 1500);
    await shot(t, 'g4010-11-conversazione-leggi');
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('composer-talk'))));
    await frames(t, 900);
    await shot(t, 'g4010-12-premi-e-parla', wait: 200);
    await g.up();
    await waitFor(t, () => !app.voice.transcribing, seconds: 30);
    await frames(t, 900);
    await shot(t, 'g4010-13-trascritto');
    final read = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('read-aloud-'),
    );
    await t.tap(read.first);
    await waitFor(t, () => app.voice.speaking == null && app.voice.problem != null, seconds: 40);
    await frames(t);
    debugPrint('read aloud: ${app.voice.problem}');
    await shot(t, 'g4010-14-leggi-errore');
    back(t);
    await frames(t);

    // ---- Share to RedGiant ----
    final dir = await t.runAsync(() => Directory.systemTemp.createTemp('rg-share'));
    final png = File('${dir!.path}/ricevuta.png');
    final pdf = File('${dir.path}/bolletta.pdf');
    await t.runAsync(() async {
      await png.writeAsBytes(
        await File('assets/icon/rgcompanion-512.png').exists()
            ? await File('assets/icon/rgcompanion-512.png').readAsBytes()
            : Uint8List(64),
      );
      await pdf.writeAsBytes(utf8.encode('%PDF-1.4\n% demo\n'));
    });
    await open(
      t,
      ShareScreen(
        items: [
          const SharedItem(kind: SharedKind.url, text: 'https://example.com/ricetta-della-nonna'),
          SharedItem(kind: SharedKind.image, path: png.path, mimeType: 'image/png'),
          SharedItem(kind: SharedKind.file, path: pdf.path, mimeType: 'application/pdf'),
        ],
      ),
    );
    await shot(t, 'g4010-15-condividi');
    final someone = app.agents.where((a) => a.id != app.chatAgentId && a.active).first;
    await t.tap(find.byKey(Key('share-to-${someone.id}')));
    await t.enterText(find.byKey(const Key('share-note')), 'Salvala tra le ricette, grazie');
    await frames(t);
    await shot(t, 'g4010-16-condividi-scelto');
    await t.tap(find.byKey(const Key('share-send')));
    await waitFor(
      t,
      () => find.byKey(const Key('composer-text')).evaluate().isNotEmpty,
      seconds: 30,
    );
    await frames(t, 2500);
    await shot(t, 'g4010-17-condiviso');
    await inbox.cancel();
    await t.runAsync(() => endpoint.close(force: true));
  });
}
