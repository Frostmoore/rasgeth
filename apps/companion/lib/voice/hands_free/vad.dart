// Hands-free voice (G42.16): when the person starts and stops speaking, from the microphone's
// loudness alone, as the page's packages/web/src/voice/vad.ts (checked with its vectors). The
// room's own noise is learned while nobody speaks, speech is what stays clearly above it for a
// while; the end is a pause long enough. Pure: frames in, events out.
import 'dart:math' as math;
import 'dart:typed_data';

enum VadEvent { start, end }

/// The loudness of a frame: root mean square of its samples (-1…1).
double rms(Float32List frame) {
  var sum = 0.0;
  for (var i = 0; i < frame.length; i++) {
    final v = frame[i];
    sum += v * v;
  }
  return frame.isEmpty ? 0 : math.sqrt(sum / frame.length);
}

/// How many times the floor speech must be, for a sensitivity: 0 → 6×, 0.5 → 3.5×, 1 → 1.8×.
double ratioFor(double sensitivity) {
  final s = sensitivity.clamp(0.0, 1.0);
  return 6 - s * 5 + s * s * 0.8;
}

/// Below this nothing is speech, however quiet the room.
const _absoluteMin = 0.004;
const _frameMs = 20;
const _calibrationFrames = 15;

class Vad {
  Vad({
    required this.sampleRate,
    double sensitivity = 0.5,
    this.minSpeechMs = 200,
    this.endSilenceMs = 900,
    this.maxSpeechMs = 30000,
    double boost = 1,
  }) : _frame = jsRound(sampleRate * _frameMs / 1000),
       sensitivity = sensitivity,
       boost = boost;

  final int sampleRate;
  final int minSpeechMs;
  final int endSilenceMs;
  final int maxSpeechMs;
  final int _frame;
  Float32List _pending = Float32List(0);

  /// The room's noise, learned from quiet frames.
  double floor = 0.003;
  bool _speaking = false;
  int _loudMs = 0;
  int _quietMs = 0;
  int _speechMs = 0;
  int _calibrating = _calibrationFrames;

  /// Louder than usual is needed (barge-in over the answer's own voice): a multiplier.
  double boost;

  /// 0 (only clear, loud speech) … 1 (even a soft voice).
  double sensitivity;

  bool get inSpeech => _speaking;

  /// The level that counts as speech now.
  double get threshold => math.max(_absoluteMin, floor * ratioFor(sensitivity)) * boost;

  /// Forgets the speech in progress (the floor stays: the room is the same).
  void reset() {
    _speaking = false;
    _loudMs = 0;
    _quietMs = 0;
    _speechMs = 0;
  }

  /// Feeds samples (any length); returns what happened in them, in order.
  List<VadEvent> push(Float32List samples) {
    final all = Float32List(_pending.length + samples.length)
      ..setAll(0, _pending)
      ..setAll(_pending.length, samples);
    final out = <VadEvent>[];
    var at = 0;
    for (; at + _frame <= all.length; at += _frame) {
      final e = _step(rms(Float32List.sublistView(all, at, at + _frame)));
      if (e != null) out.add(e);
    }
    _pending = Float32List.fromList(Float32List.sublistView(all, at));
    return out;
  }

  VadEvent? _step(double level) {
    if (_calibrating > 0) {
      final n = _calibrationFrames - _calibrating;
      floor = n == 0 ? math.max(level, 0.0005) : (floor * n + level) / (n + 1);
      _calibrating--;
      return null;
    }
    final loud = level > threshold;
    if (!loud) {
      // The floor follows quiet frames: quickly down, slowly up (a fan switched on).
      floor = level < floor ? floor * 0.7 + level * 0.3 : floor * 0.98 + level * 0.02;
      floor = math.max(floor, 0.0005);
    } else {
      // A noise that never stops slowly becomes the room's.
      floor = floor * 0.999 + level * 0.001;
    }
    if (!_speaking) {
      _loudMs = loud ? _loudMs + _frameMs : math.max(0, _loudMs - _frameMs * 2);
      if (_loudMs >= minSpeechMs) {
        _speaking = true;
        _quietMs = 0;
        _speechMs = _loudMs;
        return VadEvent.start;
      }
      return null;
    }
    _speechMs += _frameMs;
    _quietMs = loud ? 0 : _quietMs + _frameMs;
    if (_quietMs >= endSilenceMs || _speechMs >= maxSpeechMs) {
      reset();
      return VadEvent.end;
    }
    return null;
  }
}

/// JavaScript's Math.round (halves go up, -0.5 → 0), so the numbers are the page's.
int jsRound(double x) => (x + 0.5).floor();

/// Mono samples at another rate (averaging, enough for speech at 16 kHz).
Float32List downsample(Float32List input, int from, int to) {
  if (from == to) return input;
  final ratio = from / to;
  final out = Float32List((input.length / ratio).floor());
  for (var i = 0; i < out.length; i++) {
    final a = (i * ratio).floor();
    final b = math.min(input.length, ((i + 1) * ratio).floor());
    var sum = 0.0;
    for (var j = a; j < b; j++) {
      sum += input[j];
    }
    out[i] = b > a ? sum / (b - a) : 0;
  }
  return out;
}

/// 16-bit mono WAV of these samples, what every transcription service reads.
Uint8List encodeWav(Float32List pcm, int rate) {
  final out = ByteData(44 + pcm.length * 2);
  void text(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      out.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  text(0, 'RIFF');
  out.setUint32(4, 36 + pcm.length * 2, Endian.little);
  text(8, 'WAVEfmt ');
  out.setUint32(16, 16, Endian.little);
  out.setUint16(20, 1, Endian.little);
  out.setUint16(22, 1, Endian.little);
  out.setUint32(24, rate, Endian.little);
  out.setUint32(28, rate * 2, Endian.little);
  out.setUint16(32, 2, Endian.little);
  out.setUint16(34, 16, Endian.little);
  text(36, 'data');
  out.setUint32(40, pcm.length * 2, Endian.little);
  for (var i = 0; i < pcm.length; i++) {
    out.setInt16(44 + i * 2, jsRound(pcm[i].clamp(-1.0, 1.0) * 32767), Endian.little);
  }
  return out.buffer.asUint8List();
}

/// 16-bit little-endian PCM (what the microphone's stream gives) as samples in -1…1.
Float32List pcm16ToFloat(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final out = Float32List(bytes.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768;
  }
  return out;
}
