// G42.16: the wake word heard on the device. What a recogniser's result means, against the page's
// own vectors (tool/voice_vectors.mjs, through a fake spotter's Vosk-shaped JSON); the files
// brought once with their bars against the fake Rasgeth (the server's job, the computer's library
// checked by its SHA-256, the model's .tar.gz unpacked); and Settings › Voice: the size before,
// the bar while it comes, ready, then the wake word and «basta» heard by a fake spotter.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show Archive, ArchiveFile, TarEncoder, ZipEncoder;
import 'package:cryptography/cryptography.dart' show Sha256;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/voice_screen.dart';
import 'package:rgcompanion/voice/audio.dart';
import 'package:rgcompanion/voice/hands_free/machine.dart';
import 'package:rgcompanion/voice/hands_free/runtime.dart';
import 'package:rgcompanion/voice/hands_free/vosk.dart';
import 'package:rgcompanion/voice/hands_free/wake.dart';
import 'package:rgcompanion/voice/hands_free/wake_model.dart';

import 'fake_server.dart';

/// A recogniser that says what the test tells it, as Vosk's final results.
class FakeSpotter implements WakeSpotter {
  FakeSpotter(this.onResult);

  final void Function(String json) onResult;
  int fed = 0;
  int resets = 0;
  bool disposed = false;

  void says(String text, [List<({String word, double conf})>? words]) => onResult(
    jsonEncode({
      if (words != null)
        'result': [
          for (final w in words) {'word': w.word, 'conf': w.conf, 'start': 0.1, 'end': 0.4},
        ],
      'text': text,
    }),
  );

  @override
  void feed(Float32List samples) => fed += samples.length;

  @override
  void reset() => resets++;

  @override
  void dispose() => disposed = true;
}

class FakeEngine implements WakeEngine {
  FakeEngine({this.source = 'bundled', this.download});

  @override
  final String? source;
  @override
  final VoskEngine? download;
  final started = <({List<String> libs, String modelDir, String grammar})>[];
  FakeSpotter? spotter;

  @override
  Future<WakeSpotter> start({
    required List<String> libs,
    required String modelDir,
    required String grammar,
    required void Function(String json) onResult,
  }) async {
    started.add((libs: libs, modelDir: modelDir, grammar: grammar));
    return spotter = FakeSpotter(onResult);
  }
}

class _Player implements VoicePlayer {
  final played = <String>[];

  @override
  Future<void> play(Uint8List bytes, String mimeType, {required int volume}) async =>
      played.add(mimeType);

  @override
  Future<void> stop() async {}
}

class _Mic implements MicStream {
  StreamController<Uint8List>? _c;

  @override
  Future<bool> allowed() async => true;

  @override
  Future<Stream<Uint8List>> start() async => (_c = StreamController<Uint8List>()).stream;

  @override
  Future<void> stop() async => _c?.close();

  void silence(int samples) => _c?.add(Uint8List(samples * 2));
}

/// A Vosk model as Rasgeth hands it over: one folder on top, `am/final.mdl` inside.
Uint8List modelTarGz(String name) {
  final a = Archive()
    ..add(ArchiveFile.bytes('$name/am/final.mdl', utf8.encode('model')))
    ..add(ArchiveFile.bytes('$name/conf/model.conf', utf8.encode('--sample-frequency=16000')))
    ..add(ArchiveFile.bytes('../evil.txt', utf8.encode('outside')));
  return Uint8List.fromList(gzip.encode(TarEncoder().encodeBytes(a)));
}

Future<String> sha256Of(List<int> bytes) async =>
    (await Sha256().hash(bytes)).bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('what a recogniser heard means what the page says (its vectors)', () {
    final v = jsonDecode(
      File('test/fixtures/voice_vectors.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final cases = ((v['wake'] as Map)['heard'] as List).cast<Map<String, dynamic>>();
    expect(cases, isNotEmpty);
    for (final r in cases) {
      final got = <String>[];
      final words = (r['words'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((x) => (word: x['word'] as String, conf: (x['conf'] as num).toDouble()))
          .toList();
      final filter = HeardFilter(
        lang: wakeLangOf(r['lang'] as String),
        own: r['own'] as String?,
        sensitivity: () => (r['sensitivity'] as num).toDouble(),
        onHeard: got.add,
      );
      FakeSpotter(filter.result).says(r['text'] as String, words);
      expect(got.singleOrNull, r['heard'], reason: '${r['text']} ${r['own']}');
    }
    // Not JSON, or no text: nothing.
    expect(voskHeard('nope').text, '');
    expect(voskHeard('{"text": ""}').words, isNull);
  });

  group('the files, against the fake Rasgeth', () {
    late FakeRedGiant server;
    late Directory dir;
    late RedGiantClient client;
    late Uint8List model;
    var modelReady = false;

    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      dir = await Directory.systemTemp.createTemp('wake');
      final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs());
      await app.connect(server.base.toString(), 'secret');
      client = app.client!;
      model = modelTarGz('vosk-model-small-it-0.22');
      modelReady = false;
      server.routes['GET /api/voice/wake-model'] = (r) => server.answer(r, 200, {
        'ready': modelReady,
        'file': 'vosk-model-small-it-0.22.tar.gz',
        'size': modelReady ? model.length : null,
      });
      var polls = 0;
      server.routes['POST /api/voice/wake-model'] = (r) => server.answer(r, 200, {
        'ready': false,
        'job': {
          'id': 'w1',
          'state': 'running',
          'steps': [
            {
              'id': 'download',
              'state': 'running',
              'progress': {'done': 10, 'total': 40, 'rate': 5, 'secondsLeft': 6},
            },
          ],
        },
      });
      server.routes['GET /api/jobs/w1'] = (r) {
        polls++;
        modelReady = polls >= 1;
        return server.answer(r, 200, {'id': 'w1', 'state': 'done', 'steps': <Object>[]});
      };
      server.routes['GET /api/voice/wake-models/vosk-model-small-it-0.22.tar.gz'] = (r) async {
        r.response
          ..statusCode = 200
          ..headers.contentType = ContentType('application', 'gzip')
          ..contentLength = model.length
          ..add(model);
        await r.response.close();
      };
    });
    tearDown(() async {
      await server.close();
      await dir.delete(recursive: true);
    });

    test('Android: the model from Rasgeth (its job first), unpacked, kept', () async {
      final store = WakeModelStore(engine: FakeEngine(), dir: () async => dir);
      final stages = <WakeStage>[];
      store.addListener(() => stages.add(store.stage));
      expect(await store.have(WakeLang.it), isNull);
      final files = await store.fetch(client, WakeLang.it);
      expect(files, isNotNull, reason: '${store.cause}');
      expect(files!.libs, ['libvosk.so']);
      expect(File('${files.modelDir}/am/final.mdl').readAsStringSync(), 'model');
      expect(File('${files.modelDir}/conf/model.conf').existsSync(), isTrue);
      // Nothing outside its folder.
      expect(File('${dir.path}/evil.txt').existsSync(), isFalse);
      expect(File('${dir.path}/wake/evil.txt').existsSync(), isFalse);
      expect(stages, containsAllInOrder([WakeStage.server, WakeStage.model]));
      // The next start finds it.
      expect((await store.have(WakeLang.it))?.modelDir, files.modelDir);
      expect(await store.sizeToGet(WakeLang.it, 1), 0);
    });

    test('a computer: the library checked by its SHA-256 before it is kept', () async {
      final zip = Uint8List.fromList(
        ZipEncoder().encodeBytes(
          Archive()
            ..add(ArchiveFile.bytes('vosk-test/libvosk.so', utf8.encode('lib')))
            ..add(ArchiveFile.bytes('vosk-test/vosk_api.h', utf8.encode('h'))),
        ),
      );
      final seen = <String>[];
      Future<void> fetch(Uri url, File out, void Function(int, int?) onProgress) async {
        await out.parent.create(recursive: true);
        await out.writeAsBytes(zip);
        onProgress(zip.length ~/ 2, zip.length);
        onProgress(zip.length, zip.length);
        seen.add('$url');
      }

      VoskEngine engine(String sha) => VoskEngine(
        url: 'https://example.com/vosk-test.zip',
        sha256: sha,
        size: zip.length,
        folder: 'vosk-test',
        libs: const ['libvosk.so'],
      );
      // The wrong file: refused, nothing kept.
      final bad = WakeModelStore(
        engine: FakeEngine(source: 'download', download: engine('0' * 64)),
        dir: () async => dir,
        fetch: fetch,
      );
      expect(await bad.sizeToGet(WakeLang.it, 1000), zip.length + 1000);
      expect(await bad.fetch(client, WakeLang.it), isNull);
      expect(bad.stage, WakeStage.error);
      expect(bad.error, 'checksum');
      expect(Directory('${dir.path}/wake/vosk-test').existsSync(), isFalse);
      // The right one.
      final store = WakeModelStore(
        engine: FakeEngine(source: 'download', download: engine(await sha256Of(zip))),
        dir: () async => dir,
        fetch: fetch,
      );
      final bars = <double>[];
      store.addListener(() {
        if (store.stage == WakeStage.engine && store.progress != null) {
          bars.add(store.progress!.done);
        }
      });
      final files = await store.fetch(client, WakeLang.it);
      expect(files, isNotNull, reason: '${store.cause}');
      expect(files!.libs, ['${dir.path}/wake/vosk-test/libvosk.so']);
      expect(File(files.libs.single).readAsStringSync(), 'lib');
      expect(File('${dir.path}/wake/vosk-test/vosk_api.h').existsSync(), isFalse);
      expect(bars.last, zip.length);
      expect(seen, ['https://example.com/vosk-test.zip', 'https://example.com/vosk-test.zip']);
    });

    test('Rasgeth could not get the model: said, never silently', () async {
      server.routes['GET /api/jobs/w1'] = (r) => server.answer(r, 200, {
        'id': 'w1',
        'state': 'failed',
        'steps': <Object>[],
        'error': {'message': 'offline'},
      });
      final store = WakeModelStore(engine: FakeEngine(), dir: () async => dir);
      expect(await store.fetch(client, WakeLang.it), isNull);
      expect(store.error, 'server');
    });
  });

  group('Settings › Voice', () {
    late FakeRedGiant server;
    late Directory dir;

    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      dir = await Directory.systemTemp.createTemp('wake');
      final model = modelTarGz('vosk-model-small-it-0.22');
      server.routes['GET /api/voice/wake-model'] = (r) => server.answer(r, 200, {
        'ready': true,
        'file': 'vosk-model-small-it-0.22.tar.gz',
        'size': 47 * 1024 * 1024,
      });
      server.routes['GET /api/voice/wake-models/vosk-model-small-it-0.22.tar.gz'] = (r) async {
        r.response
          ..statusCode = 200
          ..contentLength = model.length;
        // In two pieces, so the bar moves.
        r.response.add(model.sublist(0, model.length ~/ 2));
        await r.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        r.response.add(model.sublist(model.length ~/ 2));
        await r.response.close();
      };
    });
    tearDown(() async {
      await server.close();
      await dir.delete(recursive: true);
    });

    Future<void> settle(WidgetTester tester, [int rounds = 8]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump();
      }
    }

    testWidgets('the size, the bar, ready; then «Ehi Rasgeth» and «basta» are heard', (
      tester,
    ) async {
      final engine = FakeEngine();
      final mic = _Mic();
      final player = _Player();
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        mic: mic,
        player: player,
        micKeeper: NoMicKeeper(),
        wakeEngine: engine,
        wakeDir: () async => dir,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => const VoiceScreen()))
          .ignore();
      await settle(tester);
      await tester.tap(find.byKey(const Key('hf-enabled')));
      await settle(tester);
      expect(app.handsFree.settings.enabled, isTrue);
      // Nothing downloaded by itself: the size first, and the button.
      expect(engine.started, isEmpty);
      expect(find.byKey(const Key('hf-wake-about')), findsOneWidget);
      expect(find.textContaining('47 MB da scaricare una volta'), findsOneWidget);
      expect(find.textContaining('ha bisogno del suo modello vocale'), findsOneWidget);
      await tester.tap(find.byKey(const Key('hf-wake-get')));
      var sawBar = false;
      for (var i = 0; i < 200 && app.handsFree.spotter == null; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump();
        if (find.byKey(const Key('hf-wake-bar')).evaluate().isNotEmpty) {
          sawBar = true;
          expect(
            find.text('Porto il modello vocale su questo dispositivo (solo la prima volta)'),
            findsOneWidget,
          );
        }
      }
      expect(sawBar, isTrue);
      await settle(tester);
      expect(
        app.handsFree.wakeHeard,
        isTrue,
        reason: '${app.handsFree.wakeModel.stage} ${app.handsFree.wakeModel.cause}',
      );
      expect(engine.started.single.libs, ['libvosk.so']);
      expect(jsonDecode(engine.started.single.grammar), contains('ehi ras get'));
      expect(find.byKey(const Key('hf-wake-ready')), findsOneWidget);
      expect(find.text("La parola di attivazione è pronta: di' «Ehi Rasgeth»."), findsOneWidget);
      expect(app.handsFree.state.wake, isTrue);
      // The microphone's samples reach the recogniser while it waits.
      await tester.runAsync(() async {
        mic.silence(1600);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });
      expect(engine.spotter!.fed, 1600);
      // «Ehi Rasgeth»: a turn starts, and the recogniser forgets what it heard.
      engine.spotter!.says('ehi ras get', [
        (word: 'ehi', conf: 0.9),
        (word: 'ras', conf: 0.95),
        (word: 'get', conf: 0.93),
      ]);
      await tester.pump();
      expect(app.handsFree.state.phase, isNot(VoicePhase.idle));
      expect(engine.spotter!.resets, 1);
      // The two short notes: heard.
      expect(player.played, contains('audio/wav'));
      // «basta»: back to waiting.
      engine.spotter!.says('basta', [(word: 'basta', conf: 1)]);
      await tester.pump();
      expect(app.handsFree.state.phase, VoicePhase.idle);
      // A wake word of one's own: the recogniser starts again with its grammar.
      await tester.runAsync(() async {
        await app.handsFree.update(
          app.handsFree.settings.copyWith(wakeWords: {WakeLang.it: 'Ciao computer'}),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      expect(engine.started.length, 2);
      expect(jsonDecode(engine.started.last.grammar), contains('ciao computer'));
      // Off: the recogniser goes.
      final last = engine.spotter!;
      await tester.runAsync(() => app.handsFree.switchOff());
      expect(last.disposed, isTrue);
      expect(app.handsFree.wakeHeard, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    });
  });
}
