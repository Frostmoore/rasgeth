// G42.16: hands-free voice in the app. The controller through fake ports, as the page's
// voice.test.ts «a whole conversation through the controller» (time moves only when the test
// says); the device's settings clamped as the page's; and the app at work against the fake
// Rasgeth: the microphone's stream (fake), the indicator at the top with its words, «Talk now»,
// the words written down and sent to the conversation in front marked as said by voice, the
// answer read with the voice chosen, «Stop», «Switch off», Settings › Voice with the wake word
// checked by the server, and Android's foreground service kept and released.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/voice_screen.dart';
import 'package:rgcompanion/voice/audio.dart';
import 'package:rgcompanion/voice/hands_free/controller.dart';
import 'package:rgcompanion/voice/hands_free/machine.dart';
import 'package:rgcompanion/voice/hands_free/runtime.dart';
import 'package:rgcompanion/voice/hands_free/settings.dart';
import 'package:rgcompanion/voice/hands_free/wake.dart';

import 'fake_server.dart';
import 'g42_16_voice_vectors_test.dart' show noise, tone;

Float32List join(List<Float32List> parts) {
  final out = Float32List(parts.fold(0, (n, p) => n + p.length));
  var at = 0;
  for (final p in parts) {
    out.setAll(at, p);
    at += p.length;
  }
  return out;
}

class _Ports implements VoicePorts {
  _Ports([this.answer = 'Sono le **tre**.']);

  final String answer;
  final log = <String>[];
  final _timers = <({void Function() fn, int at, int id})>[];
  int _now = 0;
  int _id = 0;
  Completer<void>? _speaking;
  Future<String> Function(Uint8List wav)? onTranscribe;
  Future<String> Function(String text)? onAsk;

  @override
  Future<String> transcribe(Uint8List wav) async {
    log.add('transcribe:${wav.length > 44 ? 'audio' : 'empty'}');
    return onTranscribe != null ? onTranscribe!(wav) : 'che ore sono';
  }

  @override
  Future<String> ask(String text, Future<void> stop) async {
    log.add('ask:$text');
    return onAsk != null ? onAsk!(text) : answer;
  }

  @override
  Future<void> speak(String text) {
    log.add('speak:$text');
    _speaking = Completer<void>();
    return _speaking!.future;
  }

  void finishSpeaking() {
    final s = _speaking;
    if (s != null && !s.isCompleted) s.complete();
  }

  @override
  void hush() {
    log.add('hush');
    finishSpeaking();
  }

  @override
  void chime() => log.add('chime');

  @override
  String more() => 'Il resto è sullo schermo.';

  @override
  Object setTimer(void Function() fn, Duration after) {
    _timers.add((fn: fn, at: _now + after.inMilliseconds, id: ++_id));
    return _id;
  }

  @override
  void clearTimer(Object id) => _timers.removeWhere((t) => t.id == id);

  void tick(int ms) {
    _now += ms;
    for (final t in _timers.where((t) => t.at <= _now).toList()) {
      _timers.remove(t);
      t.fn();
    }
  }
}

void feedAll(void Function(Float32List) feed, Float32List audio) {
  for (var i = 0; i < audio.length; i += 2048) {
    feed(Float32List.sublistView(audio, i, math.min(audio.length, i + 2048)));
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

final _options = HandsFreeOptions(
  sensitivity: () => 0.5,
  bargeIn: () => true,
  followup: () => const Duration(seconds: 8),
);

class _Mic implements MicStream {
  bool allow = true;
  StreamController<Uint8List>? _c;
  int starts = 0;
  int stops = 0;

  @override
  Future<bool> allowed() async => allow;

  @override
  Future<Stream<Uint8List>> start() async {
    starts++;
    _c = StreamController<Uint8List>();
    return _c!.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    await _c?.close();
  }

  /// Samples as the microphone gives them: 16-bit little-endian, split at an odd byte.
  void say(Float32List audio) {
    final b = ByteData(audio.length * 2);
    for (var i = 0; i < audio.length; i++) {
      b.setInt16(i * 2, (audio[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
    final bytes = b.buffer.asUint8List();
    for (var i = 0; i < bytes.length; i += 4097) {
      _c?.add(Uint8List.sublistView(bytes, i, math.min(bytes.length, i + 4097)));
    }
  }
}

class _Player implements VoicePlayer {
  final played = <String>[];
  Completer<void>? playing;
  int stops = 0;

  @override
  Future<void> play(Uint8List bytes, String mimeType, {required int volume}) {
    played.add('$mimeType $volume');
    if (mimeType == 'audio/wav') return Future.value();
    playing = Completer<void>();
    return playing!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
    final p = playing;
    if (p != null && !p.isCompleted) p.complete();
  }
}

void main() {
  group('a whole conversation through the controller', () {
    test('Speak → question → answer read → follow-up without speaking again → idle', () async {
      final f = _Ports();
      final c = HandsFreeController(f, _options);
      c.dispatch(const VoiceStart(wake: false));
      feedAll(c.feed, noise(1, 0.002));
      c.dispatch(const VoiceWake());
      expect(c.phase, VoicePhase.listening);
      feedAll(c.feed, join([tone(1.2, 0.2), noise(1.2, 0.002)]));
      expect(c.phase, VoicePhase.transcribing);
      await flush();
      await flush();
      expect(c.phase, VoicePhase.speaking);
      expect(f.log, ['chime', 'transcribe:audio', 'ask:che ore sono', 'speak:Sono le tre.']);
      f.finishSpeaking();
      await flush();
      expect(c.phase, VoicePhase.followup);
      feedAll(c.feed, join([tone(1, 0.2), noise(1.2, 0.002)]));
      await flush();
      await flush();
      expect(c.phase, VoicePhase.speaking);
      expect(f.log.where((l) => l.startsWith('ask:')), hasLength(2));
      f.finishSpeaking();
      await flush();
      f.tick(8000);
      expect(c.phase, VoicePhase.idle);
      expect(c.state.heard, 'che ore sono');
    });

    test('speaking over the answer stops it and listens', () async {
      final f = _Ports('Una risposta lunga.');
      final c = HandsFreeController(f, _options);
      c.dispatch(const VoiceStart(wake: true));
      feedAll(c.feed, noise(0.5, 0.002));
      c.heard('wake');
      feedAll(c.feed, join([tone(1, 0.2), noise(1.2, 0.002)]));
      await flush();
      await flush();
      expect(c.phase, VoicePhase.speaking);
      feedAll(c.feed, tone(0.6, 0.4));
      expect(f.log, contains('hush'));
      expect(c.phase, VoicePhase.listening);
      feedAll(c.feed, noise(1.2, 0.002));
      expect(c.phase, VoicePhase.transcribing);
    });

    test('«basta» heard stops everything; a stop said as a request too', () async {
      final f = _Ports();
      final c = HandsFreeController(f, _options);
      c.dispatch(const VoiceStart(wake: true));
      feedAll(c.feed, noise(0.5, 0.002));
      c.heard('wake');
      feedAll(c.feed, join([tone(1, 0.2), noise(1.2, 0.002)]));
      await flush();
      await flush();
      c.heard('stop');
      expect(c.phase, VoicePhase.idle);
      expect(f.log.last, 'hush');

      final g = _Ports()..onTranscribe = (_) async => 'basta grazie';
      final d = HandsFreeController(g, _options);
      d.dispatch(const VoiceStart(wake: true));
      feedAll(d.feed, noise(0.5, 0.002));
      d.heard('wake');
      feedAll(d.feed, join([tone(1, 0.2), noise(1.2, 0.002)]));
      await flush();
      expect(d.phase, VoicePhase.idle);
      expect(g.log.any((l) => l.startsWith('ask:')), isFalse);
    });

    test('nothing said after «Speak»: back to waiting', () {
      final f = _Ports();
      final c = HandsFreeController(
        f,
        HandsFreeOptions(
          sensitivity: () => 0.5,
          bargeIn: () => true,
          followup: () => const Duration(seconds: 8),
          listen: const Duration(seconds: 5),
        ),
      );
      c.dispatch(const VoiceStart(wake: true));
      feedAll(c.feed, noise(0.5, 0.002));
      c.heard('wake');
      feedAll(c.feed, noise(2, 0.002));
      f.tick(5000);
      expect(c.phase, VoicePhase.idle);
    });

    test('an answer that comes after «Stop» is not read', () async {
      final f = _Ports();
      final release = Completer<String>();
      f.onAsk = (_) => release.future;
      final c = HandsFreeController(f, _options);
      c.dispatch(const VoiceStart(wake: true));
      feedAll(c.feed, noise(0.5, 0.002));
      c.heard('wake');
      feedAll(c.feed, join([tone(1, 0.2), noise(1.2, 0.002)]));
      await flush();
      expect(c.phase, VoicePhase.thinking);
      c.dispatch(const VoiceStopEvent());
      release.complete('tardi');
      await flush();
      expect(c.phase, VoicePhase.idle);
      expect(f.log.any((l) => l.startsWith('speak:')), isFalse);
    });

    test('a failure is said in the state and the turn ends', () async {
      final f = _Ports()
        ..onTranscribe = (_) async => throw const SaidError('Nessun servizio di trascrizione');
      final c = HandsFreeController(f, _options);
      c.dispatch(const VoiceStart(wake: true));
      feedAll(c.feed, noise(0.5, 0.002));
      c.heard('wake');
      feedAll(c.feed, join([tone(1, 0.2), noise(1.2, 0.002)]));
      await flush();
      expect(c.phase, VoicePhase.idle);
      expect(c.state.error, 'Nessun servizio di trascrizione');
    });
  });

  test('settings on this device start from the defaults and clamp what was saved', () {
    final d = HandsFreeSettings.fromJson(null, 'it');
    expect([d.enabled, d.wake, d.sensitivity, d.lang, d.followupSec, d.bargeIn, d.target.fixed], [
      false,
      true,
      0.5,
      WakeLang.it,
      8,
      true,
      false,
    ]);
    expect(d.currentWake, 'Ehi Rasgeth');
    final s = HandsFreeSettings.fromJson(
      jsonEncode({
        'enabled': true,
        'wake': false,
        'wakeWords': {'en': 'Hey computer', 'it': 'x' * 80},
        'sensitivity': 4,
        'lang': 'en',
        'followupSec': 99,
        'bargeIn': false,
        'target': {'kind': 'session', 'sessionId': 's1', 'title': 'Casa'},
      }),
      'it',
    );
    expect(s.enabled, isTrue);
    expect(s.wake, isFalse);
    expect(s.sensitivity, 1);
    expect(s.followupSec, 30);
    expect(s.wakeWords[WakeLang.it]!.length, 60);
    expect(s.currentWake, 'Hey computer');
    expect(s.target.sessionId, 's1');
    expect(HandsFreeSettings.fromJson(s.toJson(), 'it').toJson(), s.toJson());
    expect(HandsFreeSettings.fromJson('{', 'en').lang, WakeLang.en);
  });

  group('in the app, against the fake Rasgeth', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    Future<void> settle(WidgetTester tester, [int rounds = 10]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump();
      }
    }

    Future<(AppController, _Mic, _Player, NoMicKeeper)> open(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      final mic = _Mic();
      final player = _Player();
      final keeper = NoMicKeeper();
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        player: player,
        mic: mic,
        micKeeper: keeper,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await settle(tester);
      return (app, mic, player, keeper);
    }

    Future<void> done(WidgetTester tester, AppController app) async {
      await tester.runAsync(() => app.handsFree.switchOff());
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    Future<void> until(WidgetTester tester, bool Function() ok) async {
      for (var i = 0; i < 60 && !ok(); i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      }
      await tester.pump();
    }

    testWidgets('Settings › Voice switches it on, the wake word checked by the server', (
      tester,
    ) async {
      final (app, mic, _, keeper) = await open(tester, size: const Size(390, 3000));
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => const VoiceScreen()))
          .ignore();
      await settle(tester);
      expect(find.text('Voce a mani libere su questo dispositivo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('hf-enabled')));
      await settle(tester);
      expect(app.handsFree.settings.enabled, isTrue);
      expect(mic.starts, 1);
      expect(keeper.kept, 1);
      expect(app.handsFree.state.phase, VoicePhase.idle);
      // Kept for this device and this Rasgeth.
      final saved = await app.prefs.get('handsfree:${app.server!.id}');
      expect(jsonDecode(saved!)['enabled'], isTrue);
      // A wake word of one's own, checked with the server's speech model.
      server.routes['GET /api/voice/wake-words'] = (r) => server.answer(r, 200, {
        'ready': true,
        'missing': r.uri.queryParameters['words']!.contains('giove') ? ['giove'] : <String>[],
      });
      await tester.enterText(find.byKey(const Key('hf-wake-word')), 'Ehi Giove');
      await tester.tap(find.byKey(const Key('hf-wake-use')));
      await settle(tester);
      expect(find.textContaining('non conosce «giove»'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('hf-wake-word')), 'Ciao computer');
      await tester.tap(find.byKey(const Key('hf-wake-use')));
      await settle(tester);
      expect(app.handsFree.settings.currentWake, 'Ciao computer');
      expect(find.text("Ora di' «Ciao computer»."), findsOneWidget);
      // A stop word is refused before the server is asked.
      await tester.enterText(find.byKey(const Key('hf-wake-word')), 'Basta');
      await tester.tap(find.byKey(const Key('hf-wake-use')));
      await tester.pump();
      expect(find.byKey(const Key('hf-wake-result')), findsOneWidget);
      // Off: the microphone closes and the service ends.
      await tester.tap(find.byKey(const Key('hf-enabled')));
      await settle(tester);
      expect(keeper.released, greaterThan(0));
      expect(mic.stops, greaterThan(0));
      await done(tester, app);
    });

    testWidgets('«Talk now» in front of a conversation: written down, sent by voice, read', (
      tester,
    ) async {
      final (app, mic, player, _) = await open(tester);
      server.transcription = 'che ore sono';
      app.voice.keyed = ['openai'];
      app.showingConversation('s1');
      await tester.runAsync(() async {
        await app.handsFree.update(app.handsFree.settings.copyWith(enabled: true));
      });
      await settle(tester, 3);
      expect(find.byKey(const Key('hf-indicator')), findsOneWidget);
      expect(find.text('Mani libere: tocca per parlare'), findsOneWidget);
      await tester.tap(find.byKey(const Key('hf-indicator')));
      await settle(tester, 3);
      expect(find.byKey(const Key('hf-pop')), findsOneWidget);
      await tester.tap(find.byKey(const Key('hf-talk')));
      await settle(tester, 2);
      expect(app.handsFree.state.phase, VoicePhase.listening);
      await tester.runAsync(() async {
        mic.say(join([noise(0.3, 0.002), tone(1.2, 0.2), noise(1.3, 0.002)]));
      });
      await until(tester, () => server.speeches.isNotEmpty);
      expect(server.transcribed.single.mime, 'audio/wav');
      expect(server.transcribed.single.lang, 'it');
      final m = server.received.lastWhere((x) => x['type'] == 'session.send');
      expect(m['sessionId'], 's1');
      expect(m['via'], 'voice');
      expect((m['text'] as String).startsWith('che ore sono\n\n<voice-mode>'), isTrue);
      expect(app.handsFree.state.heard, 'che ore sono');
      // The fake's turn answers «Hello **there**»: read plain, with the voice chosen.
      expect(server.speeches.single['text'], 'Hello there.');
      expect(app.handsFree.state.phase, VoicePhase.speaking);
      expect(find.text('Sto parlando'), findsWidgets);
      await tester.tap(find.byKey(const Key('hf-stop')));
      await settle(tester, 3);
      expect(app.handsFree.state.phase, VoicePhase.idle);
      expect(player.stops, greaterThan(0));
      await tester.runAsync(() => app.handsFree.switchOff());
      await settle(tester, 2);
      expect(find.byKey(const Key('hf-indicator')), findsNothing);
      await done(tester, app);
    });

    testWidgets('no conversation in front and none chosen: said, never sent', (tester) async {
      final (app, mic, _, _) = await open(tester);
      server.transcription = 'ciao';
      await tester.runAsync(() async {
        await app.handsFree.talkNow();
        mic.say(join([noise(0.3, 0.002), tone(1.2, 0.2), noise(1.3, 0.002)]));
      });
      await until(tester, () => app.handsFree.state.error != null);
      expect(
        app.handsFree.state.error,
        'Apri una conversazione, o scegline una in Impostazioni, Voce',
      );
      expect(server.received.where((x) => x['via'] == 'voice'), isEmpty);
      await done(tester, app);
    });

    testWidgets('the microphone refused: said by the indicator, no service', (tester) async {
      final (app, mic, _, keeper) = await open(tester, size: const Size(1280, 800));
      mic.allow = false;
      await tester.runAsync(() async {
        await app.handsFree.update(app.handsFree.settings.copyWith(enabled: true));
      });
      await settle(tester, 3);
      expect(app.handsFree.micState, MicState.denied);
      expect(keeper.kept, 0);
      expect(find.text('Microfono non permesso'), findsWidgets);
      await done(tester, app);
    });
  });
}
