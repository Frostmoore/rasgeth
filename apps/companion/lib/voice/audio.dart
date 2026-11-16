// The microphone and the loudspeaker (G40.10), behind two small interfaces so the screens are
// tested without devices: «press and talk» records a WAV (16 kHz, mono: what every
// transcription service the server knows takes), and an answer's audio is played at the volume
// chosen. Maintained packages: record (Android, iOS, Windows, macOS, Linux with parecord) and
// audioplayers.
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class Recording {
  const Recording(this.bytes, this.mimeType, this.duration);

  final Uint8List bytes;
  final String mimeType;
  final Duration duration;
}

abstract class VoiceRecorder {
  /// Asks for the microphone the first time; false when the person said no.
  Future<bool> allowed();
  Future<void> start();

  /// What was said, or null when nothing was recorded.
  Future<Recording?> stop();
  Future<void> cancel();
}

abstract class VoicePlayer {
  /// Plays [bytes] ([mimeType]) at [volume] percent; completes when it ends or is stopped.
  Future<void> play(Uint8List bytes, String mimeType, {required int volume});
  Future<void> stop();
}

class SystemRecorder implements VoiceRecorder {
  final AudioRecorder _rec = AudioRecorder();
  String? _path;
  DateTime? _started;

  @override
  Future<bool> allowed() => _rec.hasPermission();

  @override
  Future<void> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/rg-voice-${DateTime.now().microsecondsSinceEpoch}.wav';
    _path = path;
    _started = DateTime.now();
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
      path: path,
    );
  }

  @override
  Future<Recording?> stop() async {
    final out = await _rec.stop() ?? _path;
    final started = _started;
    _path = null;
    _started = null;
    if (out == null) return null;
    final f = File(out);
    if (!f.existsSync()) return null;
    final bytes = await f.readAsBytes();
    await f.delete().catchError((_) => f);
    // A WAV header alone: nothing was said.
    if (bytes.length <= 44) return null;
    return Recording(
      bytes,
      'audio/wav',
      started == null ? Duration.zero : DateTime.now().difference(started),
    );
  }

  @override
  Future<void> cancel() async {
    await _rec.cancel();
    _path = null;
    _started = null;
  }
}

class SystemPlayer implements VoicePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Uint8List bytes, String mimeType, {required int volume}) async {
    await _player.stop();
    await _player.setVolume((volume / 100).clamp(0.0, 1.0));
    final done = _player.onPlayerComplete.first;
    await _player.play(BytesSource(bytes, mimeType: mimeType.split(';').first));
    await Future.any([
      done,
      _player.onPlayerStateChanged.firstWhere((s) => s == PlayerState.stopped),
    ]);
  }

  @override
  Future<void> stop() => _player.stop();
}
