// The voice of the app (G40.10): «press and talk» in the composer (recorded here, written down
// by RedGiant's transcription, `POST /api/transcribe`, the same as the page) and the answers read
// aloud by the voice chosen for RedGiant (`POST /api/voice/speech`), at the volume chosen.
// Failures are said in the person's language ([voiceErrorText]).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../api/servers.dart';
import '../l10n/app_localizations.dart';
import 'audio.dart';
import 'voice_catalog.g.dart';
import 'voice_types.dart';
import 'voice_words.dart';

class VoiceController extends ChangeNotifier {
  VoiceController({required this.prefs, VoiceRecorder? recorder, VoicePlayer? player})
    : _recorder = recorder,
      _player = player,
      _testPlayer = player;

  final AppPrefs prefs;
  VoiceRecorder? _recorder;
  VoicePlayer? _player;
  VoiceRecorder get recorder => _recorder ??= SystemRecorder();
  VoicePlayer get player => _player ??= SystemPlayer();

  /// Hands-free's chime (G42.16): its own player, so it never stops an answer being read; the
  /// test's player when one was given.
  final VoicePlayer? _testPlayer;
  late final VoicePlayer chimePlayer = _testPlayer ?? SystemPlayer();

  RedGiantClient? _client;
  String? _serverId;

  VoicePrefs settings = const VoicePrefs();

  /// The voice providers whose key the server has (null: not asked yet, or it cannot say).
  List<String>? keyed;

  bool recording = false;
  bool transcribing = false;

  /// Which text is being read (the item's key), for its button.
  String? speaking;

  /// The last failure, already in the person's words.
  String? problem;

  String get _prefsKey => 'voice:${_serverId ?? '-'}';

  /// The RedGiant in use changed.
  Future<void> attach(RedGiantClient? client, String? serverId) async {
    _client = client;
    _serverId = serverId;
    keyed = null;
    problem = null;
    settings = serverId == null
        ? const VoicePrefs()
        : VoicePrefs.fromJson(await prefs.get(_prefsKey));
    notifyListeners();
  }

  /// The providers with a key, from `GET /api/setup` (`secretsSet.voice`).
  Future<void> loadKeys() async {
    final c = _client;
    if (c == null) return;
    try {
      final s = await c.setupState();
      final set = s['secretsSet'];
      final v = set is Map<String, dynamic> ? set['voice'] : null;
      keyed = [for (final x in v is List ? v : const []) '$x'];
    } on ApiException {
      keyed ??= const [];
    }
    notifyListeners();
  }

  List<SpeechProvider> get available => readersWithKeys(speechProviders, keyed ?? const []);

  ReaderChoice? get reader => effectiveReader(settings, available);

  Future<void> _save() => prefs.set(_prefsKey, settings.toJson());

  Future<void> setReader(ReaderChoice r) async {
    settings = settings.copyWith(reader: r);
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(int v) async {
    settings = settings.copyWith(volume: v);
    notifyListeners();
    await _save();
  }

  // ---- press and talk ----

  Future<bool> startRecording(AppLocalizations l) async {
    if (recording || transcribing) return false;
    problem = null;
    try {
      if (!await recorder.allowed()) {
        problem = l.voiceMicDenied;
        notifyListeners();
        return false;
      }
      await recorder.start();
      recording = true;
    } on Object {
      problem = l.voiceMicFailed;
    }
    notifyListeners();
    return recording;
  }

  Future<void> cancelRecording() async {
    if (!recording) return;
    recording = false;
    notifyListeners();
    await recorder.cancel().catchError((_) {});
  }

  /// Stops and writes down what was said; null (and [problem]) when nothing came of it.
  Future<String?> stopAndTranscribe(AppLocalizations l, String lang) async {
    if (!recording) return null;
    recording = false;
    transcribing = true;
    notifyListeners();
    try {
      final rec = await recorder.stop();
      if (rec == null || rec.duration < const Duration(milliseconds: 300)) {
        problem = l.voiceTooShort;
        return null;
      }
      final c = _client;
      if (c == null) {
        problem = l.voiceErrServer;
        return null;
      }
      final text = (await c.transcribe(rec.bytes, rec.mimeType, lang)).trim();
      if (text.isEmpty) problem = l.voiceHeardNothing;
      return text.isEmpty ? null : text;
    } on Object catch (e) {
      problem = voiceErrorText(l, e);
      return null;
    } finally {
      transcribing = false;
      notifyListeners();
    }
  }

  // ---- reading aloud ----

  /// Reads [text] (Markdown) with the voice chosen; [key] names the item for its button. A
  /// second press on the same item stops it.
  Future<void> speak(String key, String text, AppLocalizations l) async {
    if (speaking == key) return stopSpeaking();
    await stopSpeaking();
    problem = null;
    if (keyed == null) await loadKeys();
    final r = reader;
    final c = _client;
    if (r == null || c == null) {
      problem = l.voiceNoReader;
      notifyListeners();
      return;
    }
    final said = textForSpeech(text);
    if (said.isEmpty) return;
    speaking = key;
    notifyListeners();
    try {
      final audio = await c.speech(
        provider: r.provider,
        model: r.model,
        voice: r.voice,
        text: said,
      );
      if (speaking != key) return;
      await player.play(audio.bytes, audio.mimeType, volume: settings.volume);
    } on Object catch (e) {
      if (speaking == key) problem = voiceErrorText(l, e);
    } finally {
      if (speaking == key) speaking = null;
      notifyListeners();
    }
  }

  /// Hands-free (G42.16): reads [said] (already plain) with the voice chosen and completes when
  /// it ends or is stopped; false when nobody can read here (no provider with a key).
  Future<bool> say(String said, AppLocalizations l) async {
    await stopSpeaking();
    if (keyed == null) await loadKeys();
    final r = reader;
    final c = _client;
    if (r == null || c == null || said.trim().isEmpty) return false;
    const key = 'hands-free';
    speaking = key;
    notifyListeners();
    try {
      final audio = await c.speech(
        provider: r.provider,
        model: r.model,
        voice: r.voice,
        text: textForSpeech(said),
      );
      if (speaking != key) return true;
      await player.play(audio.bytes, audio.mimeType, volume: settings.volume);
      return true;
    } on Object catch (e) {
      if (speaking == key) problem = voiceErrorText(l, e);
      return false;
    } finally {
      if (speaking == key) speaking = null;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    if (speaking == null) return;
    speaking = null;
    notifyListeners();
    await player.stop().catchError((_) {});
  }

  void clearProblem() {
    if (problem == null) return;
    problem = null;
    notifyListeners();
  }
}
