// G40.10 on the screens, against the fake Rasgeth: Tu › Notifiche on Android (without a
// distributor it says so plainly; with one it registers with the server's VAPID key and the
// endpoint reaches the server), on a computer (on and off, a test); the computers' live
// notifications (shown behind other windows, withdrawn when answered); Tu › Voce; «press and
// talk» and «read aloud» in a conversation; «Share to Rasgeth».
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/push/distributors.dart';
import 'package:rgcompanion/push/notice.dart';
import 'package:rgcompanion/push/system_notifier.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/notifications_screen.dart';
import 'package:rgcompanion/screens/voice_screen.dart';
import 'package:rgcompanion/share/share_intake.dart';
import 'package:rgcompanion/voice/audio.dart';

import 'fake_server.dart';

class _Mic implements VoiceRecorder {
  @override
  Future<bool> allowed() async => true;

  @override
  Future<void> start() async {}

  @override
  Future<Recording?> stop() async =>
      Recording(Uint8List(32000), 'audio/wav', const Duration(seconds: 1));

  @override
  Future<void> cancel() async {}
}

class _Speaker implements VoicePlayer {
  final played = <int>[];

  @override
  Future<void> play(Uint8List bytes, String mimeType, {required int volume}) async =>
      played.add(bytes.length);

  @override
  Future<void> stop() async {}
}

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late FakeRedGiant server;
  late MemoryNotifier notes;
  late NoDistributors dist;
  late NoShareIntake share;
  late _Speaker speaker;

  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    notes = MemoryNotifier();
    dist = NoDistributors(supported: true);
    share = NoShareIntake();
    speaker = _Speaker();
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    DevicePlatform platform = DevicePlatform.android,
    Locale locale = const Locale('it'),
  }) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
            platform: platform,
            liveEnabled: false,
            notifier: notes,
            distributors: (_) async => dist,
            share: share,
            recorder: _Mic(),
            player: speaker,
          )
          ..locale = locale
          ..reduceMotion = true;
    await tester.runAsync(() async {
      await app.startSystems();
      await app.connect(server.base.toString(), 'secret');
    });
    tester.view.physicalSize = const Size(1290, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    return app;
  }

  Future<void> push(WidgetTester tester, Widget screen) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => screen));
    await _settle(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  group('Tu › Notifiche', () {
    testWidgets('Android without a distributor: said plainly, with how to get one', (tester) async {
      await start(tester);
      await tester.tap(find.byKey(const Key('tab-you')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-notifications')));
      await _settle(tester);
      expect(find.byKey(const Key('push-no-distributor')), findsOneWidget);
      expect(find.text('Su questo telefono non c\'è un distributore UnifiedPush.'), findsOneWidget);
      expect(find.textContaining('installa ntfy'), findsOneWidget);
      expect(find.textContaining('Spente su questo dispositivo'), findsOneWidget);
      expect(find.byKey(const Key('push-on')), findsNothing);
      // Installed meanwhile: «Look again» finds it.
      dist.installed.add('io.heckel.ntfy');
      await tester.tap(find.byKey(const Key('push-look-again')));
      await _settle(tester);
      expect(find.byKey(const Key('distributor-io.heckel.ntfy')), findsOneWidget);
      await done(tester);
    });

    testWidgets(
      'Android with ntfy: registered with the VAPID key, the endpoint reaches the server',
      (tester) async {
        dist.installed.addAll(['io.heckel.ntfy', 'org.unifiedpush.distributor.sunup']);
        final app = await start(tester);
        await push(tester, const NotificationsScreen());
        expect(find.text('ntfy'), findsOneWidget);
        expect(find.text('Sunup'), findsOneWidget);
        await tester.tap(find.byKey(const Key('distributor-org.unifiedpush.distributor.sunup')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('push-on')));
        await _settle(tester);
        expect(dist.chosen, 'org.unifiedpush.distributor.sunup');
        expect(dist.registered[app.server!.id], 'BPvapid-public-key');
        expect(find.textContaining('Sunup sta preparando'), findsOneWidget);
        // The distributor gives the endpoint (as UnifiedPushDistributors does: sent, then said).
        final sent = await tester.runAsync(
          () => app.pushCenter.onEndpoint(app.server!.id, 'https://push.example/up1'),
        );
        dist.give(EndpointReady(app.server!.id, 'https://push.example/up1', sent: sent!));
        await _settle(tester);
        expect(server.pushRegistrations['d1']?['endpoint'], 'https://push.example/up1');
        expect(find.byKey(const Key('push-said')), findsOneWidget);
        expect(
          find.text('Le notifiche sono attive: manda una prova per vederne una.'),
          findsOneWidget,
        );
        expect(find.text('Attive, attraverso Sunup'), findsOneWidget);
        // Turned off: the server forgets it.
        await tester.tap(find.byKey(const Key('push-off')));
        await _settle(tester);
        expect(server.pushDeletes, ['d1']);
        expect(dist.registered, isEmpty);
        await done(tester);
      },
    );

    testWidgets('a computer: on and off, and a test notification', (tester) async {
      final app = await start(tester, platform: DevicePlatform.linux, locale: const Locale('en'));
      await push(tester, const NotificationsScreen());
      expect(find.byKey(const Key('push-desktop')), findsOneWidget);
      expect(find.textContaining('even behind other windows'), findsOneWidget);
      await tester.tap(find.byKey(const Key('desktop-notify-off')));
      await tester.pumpAndSettle();
      expect(app.desktopNotify, isFalse);
      expect(await tester.runAsync(() => app.prefs.get('desktopNotify')), '0');
      await tester.tap(find.byKey(const Key('desktop-notify-on')));
      await tester.pumpAndSettle();
      expect(app.desktopNotify, isTrue);
      await tester.tap(find.byKey(const Key('desktop-test')));
      await _settle(tester);
      expect(notes.shown.values.single.title, 'Notification test');
      await done(tester);
    });
  });

  testWidgets(
    'the computers: a request behind other windows is notified, withdrawn when answered',
    (tester) async {
      final app = await start(tester, platform: DevicePlatform.windows);
      // The requests already there when the app opened are not notified again.
      final before = notes.shown.length;
      app.setForeground(false);
      app.live.apply({
        'type': 'permission.request',
        'request': {
          'requestId': 'r7',
          'agentId': 'a0',
          'agentName': 'God',
          'tool': 'run_command',
          'input': {'command': 'git status'},
          'reasons': <String>[],
          'danger': <String>[],
          'createdAt': '2026-11-16T10:00:00.000Z',
        },
      });
      await tester.pump();
      final id = notificationIdOf(app.server!.id, 'req:r7');
      expect(notes.shown.length, before + 1);
      expect(notes.shown[id]?.title, 'God chiede il permesso');
      expect(notes.shown[id]?.answers, [QuickAnswer.allow, QuickAnswer.deny]);
      // A critical one: no quick answer.
      app.live.apply({
        'type': 'permission.request',
        'request': {
          'requestId': 'r8',
          'agentId': 'a0',
          'agentName': 'God',
          'tool': 'run_command',
          'input': {'command': 'rm -rf /'},
          'reasons': <String>[],
          'danger': ['critical-delete'],
          'createdAt': '2026-11-16T10:00:00.000Z',
        },
      });
      await tester.pump();
      expect(notes.shown[notificationIdOf(app.server!.id, 'req:r8')]?.answers, isEmpty);
      // Answered elsewhere.
      app.live.apply({'type': 'permission.closed', 'requestId': 'r7', 'via': 'web'});
      await tester.pump();
      expect(notes.shown.containsKey(id), isFalse);
      expect(notes.cancelled, contains(id));
      // The window in front: nothing new is notified.
      app.setForeground(true);
      app.live.apply({
        'type': 'question.request',
        'request': {
          'requestId': 'q1',
          'agentId': 'a0',
          'agentName': 'God',
          'sessionId': 's1',
          'questions': [
            {'question': 'Quale?', 'options': <Object>[]},
          ],
          'createdAt': '2026-11-16T10:00:00.000Z',
        },
      });
      await tester.pump();
      expect(notes.shown.containsKey(notificationIdOf(app.server!.id, 'req:q1')), isFalse);
      await done(tester);
    },
  );

  testWidgets('Tu › Voce: the providers with a key, model, voice, volume', (tester) async {
    server.setup = {
      ...server.setup,
      'secretsSet': {
        'voice': ['openai', 'elevenlabs', 'groq'],
      },
    };
    final app = await start(tester);
    // G42.16: hands-free comes first on the page, as the page's Settings › Voice.
    tester.view.physicalSize = const Size(1290, 9000);
    await push(tester, const VoiceScreen());
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('ElevenLabs'), findsOneWidget);
    // Groq writes down, it does not read.
    expect(find.text('Groq'), findsNothing);
    expect(find.byKey(const Key('voice-voice-marin')), findsOneWidget);
    await tester.tap(find.byKey(const Key('voice-model-tts-1')));
    await tester.pumpAndSettle();
    expect(app.voice.reader?.model, 'tts-1');
    expect(app.voice.reader?.voice, 'alloy');
    await tester.tap(find.byKey(const Key('reader-elevenlabs')));
    await tester.pumpAndSettle();
    expect(app.voice.reader?.provider, 'elevenlabs');
    expect(find.text('La voce è quella dell\'account con la chiave.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('voice-try')));
    await _settle(tester);
    expect(server.speeches.single['provider'], 'elevenlabs');
    expect(speaker.played, [64]);
    await done(tester);
  });

  testWidgets('Tu › Voce without a voice in Rasgeth: said, with where to add one', (tester) async {
    await start(tester, locale: const Locale('en'));
    tester.view.physicalSize = const Size(1290, 9000);
    await push(tester, const VoiceScreen());
    expect(find.byKey(const Key('voice-no-reader')), findsOneWidget);
    expect(find.text('Rasgeth has no voice to read with yet.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a conversation: press and talk writes in the field; read aloud', (tester) async {
    server.setup = {
      ...server.setup,
      'secretsSet': {
        'voice': ['openai'],
      },
    };
    final app = await start(tester);
    await push(tester, ConversationScreen(sessionId: 's1', agent: app.agents.first));
    app.live.apply({
      'type': 'session.history',
      'sessionId': 's1',
      'events': [
        {
          'seq': 1,
          'ts': '2026-11-16T10:00:00.000Z',
          'type': 'message.assistant',
          'payload': {
            'parts': [
              {'type': 'text', 'text': 'Ecco **la risposta**.'},
            ],
            'stopReason': 'end_turn',
          },
        },
      ],
    });
    await _settle(tester);
    // A short tap says how.
    await tester.tap(find.byKey(const Key('composer-talk')));
    await tester.pumpAndSettle();
    expect(find.text('Tieni premuto per parlare'), findsWidgets);
    // Held down, let go.
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('composer-talk'))));
    await tester.pump(const Duration(milliseconds: 700));
    await _settle(tester, 4);
    expect(app.voice.recording, isTrue);
    expect(find.text('Ti ascolto… lascia per finire'), findsOneWidget);
    await g.up();
    await _settle(tester);
    expect(server.transcribed.single.lang, 'it');
    final field = tester.widget<TextField>(find.byKey(const Key('composer-text')));
    expect(field.controller!.text, 'che ore sono a Roma');
    // Read aloud.
    await tester.tap(find.byKey(const Key('read-aloud-a-2026-11-16T10:00:00.000Z')));
    await _settle(tester);
    expect(server.speeches.single['text'], 'Ecco la risposta.');
    expect(speaker.played, [64]);
    await done(tester);
  });

  testWidgets('Share to Rasgeth: to an agent, with a note and a photo', (tester) async {
    final dir = Directory.systemTemp.createTempSync('rg-share');
    addTearDown(() => dir.deleteSync(recursive: true));
    final photo = File('${dir.path}/foto.png')..writeAsBytesSync(Uint8List(40));
    final pdf = File('${dir.path}/conto.pdf')..writeAsBytesSync(Uint8List(70));
    final app = await start(tester);
    share.share([
      const SharedItem(kind: SharedKind.url, text: 'https://example.com/ricetta'),
      SharedItem(kind: SharedKind.image, path: photo.path, mimeType: 'image/png'),
      SharedItem(kind: SharedKind.file, path: pdf.path, mimeType: 'application/pdf'),
    ]);
    await _settle(tester);
    expect(find.text('Condividi con Rasgeth'), findsOneWidget);
    expect(find.text('https://example.com/ricetta'), findsOneWidget);
    expect(find.text('foto.png'), findsOneWidget);
    final agent = app.agents[1];
    await tester.tap(find.byKey(Key('share-to-${agent.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('share-note')), 'Guarda questa');
    await tester.tap(find.byKey(const Key('share-send')));
    await _settle(tester, 20);
    final m = server.sent.last;
    expect(m['text'], startsWith('Guarda questa\n\nhttps://example.com/ricetta'));
    expect(m['text'], contains('<attachment name="conto.pdf" path=".attachments/'));
    expect((m['images'] as List).single['mediaType'], 'image/png');
    expect(server.written.single['scope'], 'platform');
    expect(server.written.single['encoding'], 'base64');
    expect(app.pendingShare, isNull);
    // The conversation opens.
    expect(find.byKey(const Key('composer-text')), findsOneWidget);
    await done(tester);
  });

  testWidgets('Share to Rasgeth: put aside', (tester) async {
    final app = await start(tester, locale: const Locale('en'));
    share.share([const SharedItem(kind: SharedKind.text, text: 'a note')]);
    await _settle(tester);
    expect(find.text('Share to Rasgeth'), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-cancel')));
    await _settle(tester);
    expect(app.pendingShare, isNull);
    expect(find.text('Share to Rasgeth'), findsNothing);
    await done(tester);
  });
}
