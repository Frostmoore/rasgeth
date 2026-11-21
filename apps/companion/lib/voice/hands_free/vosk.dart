// Hands-free voice (G42.16): the wake word heard on the device, as the page hears it in the
// browser: Vosk (Apache-2.0) with the language's small model and a grammar limited to the wake and
// stop phrases (wake.dart), so nothing said leaves the device before the wake word. The page runs
// Vosk in WASM; the app calls the same library's C API through dart:ffi, in an isolate of its own
// (loading the model takes seconds, and the microphone's pieces must not wait on the window).
//
// Where the library comes from: Android carries it in the APK (vosk-android's AAR, its
// `libvosk.so` for each ABI); Windows and Linux download alphacephei's own release once, with the
// model, when the person turns the wake word on, checked against the SHA-256 written here before
// it is ever loaded. macOS and iOS have no recogniser yet (a downloaded library would not pass the
// signed app's library validation): there a turn starts from «Talk now», and the app says so.
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'wake.dart';

/// The recogniser's library for a computer: alphacephei's release, pinned by its SHA-256.
class VoskEngine {
  const VoskEngine({
    required this.url,
    required this.sha256,
    required this.size,
    required this.folder,
    required this.libs,
  });

  final String url;
  final String sha256;

  /// Bytes of the zip (shown before it is downloaded).
  final int size;

  /// The zip's one folder.
  final String folder;

  /// The files to load, in this order (the last one is Vosk itself).
  final List<String> libs;
}

/// vosk-api 0.3.45 (2022-12-14, Apache-2.0), github.com/alphacep/vosk-api/releases.
const voskEngines = <String, VoskEngine>{
  'linux': VoskEngine(
    url: 'https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-linux-x86_64-0.3.45.zip',
    sha256: 'bbdc8ed85c43979f6443142889770ea95cbfbc56cffb5c5dcd73afa875c5fbb2',
    size: 7185065,
    folder: 'vosk-linux-x86_64-0.3.45',
    libs: ['libvosk.so'],
  ),
  'windows': VoskEngine(
    url: 'https://github.com/alphacep/vosk-api/releases/download/v0.3.45/vosk-win64-0.3.45.zip',
    sha256: 'f1dcc9cca460630f81ea8f71794f69c80bed6556d2a4e6237b5785e1d2dff34b',
    size: 14882445,
    folder: 'vosk-win64-0.3.45',
    // MinGW's runtime first, so Vosk finds it already loaded.
    libs: ['libwinpthread-1.dll', 'libgcc_s_seh-1.dll', 'libstdc++-6.dll', 'libvosk.dll'],
  ),
};

/// Where this device gets the recogniser: `bundled` (Android), `download` (Windows and Linux on
/// x86-64), or null: none here.
String? voskSource() {
  if (Platform.isAndroid) return 'bundled';
  if ((Platform.isWindows || Platform.isLinux) && _x64) return 'download';
  return null;
}

bool get _x64 {
  final v = Platform.version.toLowerCase();
  return v.contains('x64') || v.contains('x86_64');
}

/// What a Vosk result (`{"text": …, "result": [{"word", "conf"}…]}`) says.
({String text, List<HeardWord>? words}) voskHeard(String json) {
  try {
    final j = jsonDecode(json);
    if (j is! Map) return (text: '', words: null);
    final r = j['result'];
    return (
      text: j['text'] is String ? j['text'] as String : '',
      words: r is List
          ? [
              for (final w in r.whereType<Map<dynamic, dynamic>>())
                if (w['word'] is String && w['conf'] is num)
                  (word: w['word'] as String, conf: (w['conf'] as num).toDouble()),
            ]
          : null,
    );
  } on FormatException {
    return (text: '', words: null);
  }
}

/// Turns a recogniser's final results into wake or stop, as the page's `startVosk`.
class HeardFilter {
  HeardFilter({required this.lang, required this.sensitivity, required this.onHeard, this.own});

  final WakeLang lang;
  final String? own;
  final double Function() sensitivity;
  final void Function(String what) onHeard;

  void result(String json) {
    final h = voskHeard(json);
    final what = classifyHeard(lang, h.text, h.words, minConfFor(sensitivity()), own);
    if (what != null) onHeard(what);
  }
}

/// Starts a listener for the wake word (the real one: [VoskSpotter]; tests: a fake).
abstract class WakeEngine {
  /// `bundled`, `download`, or null when this device cannot hear the wake word.
  String? get source;

  /// The recogniser's download for this computer (null: bundled or none).
  VoskEngine? get download;

  Future<WakeSpotter> start({
    required List<String> libs,
    required String modelDir,
    required String grammar,
    required void Function(String json) onResult,
  });
}

class VoskWakeEngine implements WakeEngine {
  @override
  String? get source => voskSource();

  @override
  VoskEngine? get download =>
      source == 'download' ? voskEngines[Platform.isWindows ? 'windows' : 'linux'] : null;

  @override
  Future<WakeSpotter> start({
    required List<String> libs,
    required String modelDir,
    required String grammar,
    required void Function(String json) onResult,
  }) => VoskSpotter.start(libs: libs, modelDir: modelDir, grammar: grammar, onResult: onResult);
}

/// Vosk in an isolate of its own: 16 kHz samples in, final results (JSON) out.
class VoskSpotter implements WakeSpotter {
  VoskSpotter._(this._to, this._from, this._isolate);

  final SendPort _to;
  final ReceivePort _from;
  final Isolate _isolate;
  bool _gone = false;

  /// Loads [libs] in order, then the model in [modelDir] with [grammar]; fails with the reason.
  static Future<VoskSpotter> start({
    required List<String> libs,
    required String modelDir,
    required String grammar,
    required void Function(String json) onResult,
  }) async {
    final from = ReceivePort();
    final ready = Completer<SendPort>();
    from.listen((m) {
      if (m is SendPort && !ready.isCompleted) {
        ready.complete(m);
      } else if (m is List && m.length == 2 && m[0] == 'error' && !ready.isCompleted) {
        ready.completeError(StateError('${m[1]}'));
      } else if (m is String) {
        onResult(m);
      }
    });
    final isolate = await Isolate.spawn(_worker, (
      reply: from.sendPort,
      libs: libs,
      model: modelDir,
      grammar: grammar,
    ), debugName: 'vosk');
    try {
      final to = await ready.future;
      return VoskSpotter._(to, from, isolate);
    } on Object {
      from.close();
      isolate.kill();
      rethrow;
    }
  }

  @override
  void feed(Float32List samples) {
    if (_gone || samples.isEmpty) return;
    final pcm = Int16List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      pcm[i] = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    }
    _to.send(TransferableTypedData.fromList([pcm]));
  }

  @override
  void reset() {
    if (!_gone) _to.send('reset');
  }

  @override
  void dispose() {
    if (_gone) return;
    _gone = true;
    _to.send('dispose');
    // The worker frees the model and exits; a moment later it is stopped in any case.
    Timer(const Duration(seconds: 2), () {
      _from.close();
      _isolate.kill();
    });
  }
}

typedef _ModelNew = Pointer<Void> Function(Pointer<Utf8>);
typedef _ModelNewC = Pointer<Void> Function(Pointer<Utf8>);
typedef _Free = void Function(Pointer<Void>);
typedef _FreeC = Void Function(Pointer<Void>);
typedef _RecNew = Pointer<Void> Function(Pointer<Void>, double, Pointer<Utf8>);
typedef _RecNewC = Pointer<Void> Function(Pointer<Void>, Float, Pointer<Utf8>);
typedef _SetInt = void Function(Pointer<Void>, int);
typedef _SetIntC = Void Function(Pointer<Void>, Int32);
typedef _Accept = int Function(Pointer<Void>, Pointer<Int16>, int);
typedef _AcceptC = Int32 Function(Pointer<Void>, Pointer<Int16>, Int32);
typedef _Result = Pointer<Utf8> Function(Pointer<Void>);
typedef _LogLevel = void Function(int);
typedef _LogLevelC = Void Function(Int32);

void _worker(({SendPort reply, List<String> libs, String model, String grammar}) a) {
  final DynamicLibrary lib;
  final Pointer<Void> model;
  final Pointer<Void> rec;
  final _Free modelFree;
  final _Free recFree;
  final _Accept accept;
  final _Result result;
  final _Free recReset;
  try {
    DynamicLibrary? last;
    for (final path in a.libs) {
      last = DynamicLibrary.open(path);
    }
    lib = last!;
    lib.lookupFunction<_LogLevelC, _LogLevel>('vosk_set_log_level')(-1);
    final modelNew = lib.lookupFunction<_ModelNewC, _ModelNew>('vosk_model_new');
    modelFree = lib.lookupFunction<_FreeC, _Free>('vosk_model_free');
    final recNew = lib.lookupFunction<_RecNewC, _RecNew>('vosk_recognizer_new_grm');
    recFree = lib.lookupFunction<_FreeC, _Free>('vosk_recognizer_free');
    recReset = lib.lookupFunction<_FreeC, _Free>('vosk_recognizer_reset');
    accept = lib.lookupFunction<_AcceptC, _Accept>('vosk_recognizer_accept_waveform_s');
    result = lib.lookupFunction<_Result, _Result>('vosk_recognizer_result');
    final setWords = lib.lookupFunction<_SetIntC, _SetInt>('vosk_recognizer_set_words');
    final path = a.model.toNativeUtf8();
    model = modelNew(path);
    calloc.free(path);
    if (model == nullptr) throw StateError('model');
    final g = a.grammar.toNativeUtf8();
    rec = recNew(model, 16000, g);
    calloc.free(g);
    if (rec == nullptr) {
      modelFree(model);
      throw StateError('recognizer');
    }
    setWords(rec, 1);
  } on Object catch (e) {
    a.reply.send(['error', '$e']);
    return;
  }
  final inbox = ReceivePort();
  var buf = calloc<Int16>(8000);
  var cap = 8000;
  inbox.listen((m) {
    if (m is TransferableTypedData) {
      final pcm = m.materialize().asInt16List();
      if (pcm.length > cap) {
        calloc.free(buf);
        cap = pcm.length;
        buf = calloc<Int16>(cap);
      }
      buf.asTypedList(pcm.length).setAll(0, pcm);
      if (accept(rec, buf, pcm.length) == 1) {
        a.reply.send(result(rec).toDartString());
      }
    } else if (m == 'reset') {
      recReset(rec);
    } else if (m == 'dispose') {
      inbox.close();
      recFree(rec);
      modelFree(model);
      calloc.free(buf);
      Isolate.exit();
    }
  });
  a.reply.send(inbox.sendPort);
}
