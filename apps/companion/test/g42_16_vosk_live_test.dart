// G42.16, live: the real Vosk library through dart:ffi (VoskSpotter, in its isolate) with a real
// small model and spoken audio, the wake phrase, another sentence and «stop». Skipped unless the
// files are given (nothing is downloaded here):
//   RG_VOSK_LIB=…/libvosk.so RG_VOSK_MODEL=…/vosk-model-small-en-us-0.15 \
//   RG_VOSK_WAVS=<folder with hey.wav, other.wav, stop.wav: 16-bit mono, any rate> \
//   flutter test test/g42_16_vosk_live_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/voice/hands_free/vosk.dart';
import 'package:rgcompanion/voice/hands_free/wake.dart';

/// A 16-bit mono WAV at 16 kHz (linear resampling), with silence around it.
Float32List wav16k(File f) {
  final b = ByteData.sublistView(f.readAsBytesSync());
  var at = 12;
  var rate = 16000;
  Float32List? pcm;
  while (at + 8 <= b.lengthInBytes) {
    final id = String.fromCharCodes(b.buffer.asUint8List(b.offsetInBytes + at, 4));
    var size = b.getUint32(at + 4, Endian.little);
    if (id == 'fmt ') rate = b.getUint32(at + 12, Endian.little);
    if (id == 'data') {
      // espeak writes a streaming header: the size up to the end.
      if (size == 0 || at + 8 + size > b.lengthInBytes) size = b.lengthInBytes - at - 8;
      pcm = Float32List(size ~/ 2);
      for (var i = 0; i < pcm.length; i++) {
        pcm[i] = b.getInt16(at + 8 + i * 2, Endian.little) / 32768;
      }
      break;
    }
    at += 8 + size + (size & 1);
  }
  final src = pcm!;
  final n = (src.length * 16000 / rate).floor();
  final out = Float32List(8000 + n + 24000);
  for (var i = 0; i < n; i++) {
    final x = i * rate / 16000;
    final j = x.floor();
    final k = j + 1 < src.length ? j + 1 : j;
    out[8000 + i] = src[j] + (src[k] - src[j]) * (x - j);
  }
  return out;
}

void main() {
  final lib = Platform.environment['RG_VOSK_LIB'];
  final model = Platform.environment['RG_VOSK_MODEL'];
  final wavs = Platform.environment['RG_VOSK_WAVS'];
  final skip = lib == null || model == null || wavs == null ? 'RG_VOSK_* not set' : null;

  test(
    'the real Vosk hears the wake word and «stop», and nothing in another sentence',
    () async {
      final heard = <String>[];
      final raw = <String>[];
      final filter = HeardFilter(lang: WakeLang.en, sensitivity: () => 0.5, onHeard: heard.add);
      final s = await VoskSpotter.start(
        libs: [lib!],
        modelDir: model!,
        grammar: wakeGrammar(WakeLang.en),
        onResult: (json) {
          raw.add(json);
          filter.result(json);
        },
      );
      Future<List<String>> say(String name) async {
        heard.clear();
        final audio = wav16k(File('$wavs/$name.wav'));
        for (var i = 0; i < audio.length; i += 1600) {
          s.feed(
            Float32List.sublistView(audio, i, i + 1600 > audio.length ? audio.length : i + 1600),
          );
        }
        await Future<void>.delayed(const Duration(seconds: 3));
        final got = [...heard];
        s.reset();
        return got;
      }

      expect(await say('hey'), ['wake'], reason: raw.join('\n'));
      expect(await say('other'), isEmpty, reason: raw.join('\n'));
      expect(await say('stop'), ['stop'], reason: raw.join('\n'));
      s.dispose();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
