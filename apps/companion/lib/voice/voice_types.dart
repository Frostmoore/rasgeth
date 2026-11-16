// The voice in the app (G40.10): who reads the answers aloud (a provider through the server,
// `POST /api/voice/speech`, the same as the page's Settings › Voice) and how loud. The choice
// belongs to this device and this RedGiant (the keys are the server's), kept in the preferences.
import 'dart:convert';

class VoiceOption {
  const VoiceOption(this.id, this.label);

  final String id;
  final String label;
}

class SpeechModel {
  const SpeechModel(this.id, this.label, this.voices);

  final String id;
  final String label;

  /// Empty: the provider's own voices (ElevenLabs reads them from the account).
  final List<VoiceOption> voices;
}

class SpeechProvider {
  const SpeechProvider(this.id, this.name, this.models);

  final String id;
  final String name;
  final List<SpeechModel> models;
}

/// Who reads, with which model and voice.
class ReaderChoice {
  const ReaderChoice({required this.provider, required this.model, this.voice});

  static ReaderChoice? fromJson(Object? j) {
    if (j is! Map<String, dynamic> || j['provider'] is! String || j['model'] is! String) {
      return null;
    }
    return ReaderChoice(
      provider: j['provider'] as String,
      model: j['model'] as String,
      voice: j['voice'] is String ? j['voice'] as String : null,
    );
  }

  final String provider;
  final String model;
  final String? voice;

  Map<String, Object?> toJson() => {'provider': provider, 'model': model, 'voice': ?voice};

  @override
  bool operator ==(Object other) =>
      other is ReaderChoice &&
      other.provider == provider &&
      other.model == model &&
      other.voice == voice;

  @override
  int get hashCode => Object.hash(provider, model, voice);
}

/// The quietest and loudest the app reads, in percent. The page goes up to 200 with Web Audio;
/// the systems' players stop at 100 (the phone's own volume does the rest).
const int kMinVolume = 25;
const int kMaxVolume = 100;
const int kDefaultVolume = 100;

class VoicePrefs {
  const VoicePrefs({this.reader, this.volume = kDefaultVolume});

  static VoicePrefs fromJson(String? raw) {
    if (raw == null) return const VoicePrefs();
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic>) return const VoicePrefs();
      final v = j['volume'];
      return VoicePrefs(
        reader: ReaderChoice.fromJson(j['reader']),
        volume: v is int ? v.clamp(kMinVolume, kMaxVolume) : kDefaultVolume,
      );
    } on FormatException {
      return const VoicePrefs();
    }
  }

  /// Null: nobody chosen yet (the first provider with a key is offered).
  final ReaderChoice? reader;
  final int volume;

  VoicePrefs copyWith({ReaderChoice? reader, int? volume, bool clearReader = false}) => VoicePrefs(
    reader: clearReader ? null : (reader ?? this.reader),
    volume: (volume ?? this.volume).clamp(kMinVolume, kMaxVolume),
  );

  String toJson() => jsonEncode({'reader': reader?.toJson(), 'volume': volume});
}

/// The providers that can read here: those with text-to-speech whose key the server has
/// (`secretsSet.voice` of `GET /api/setup`).
List<SpeechProvider> readersWithKeys(List<SpeechProvider> all, Iterable<String> keyed) => [
  for (final p in all)
    if (keyed.contains(p.id) && p.models.isNotEmpty) p,
];

/// The reader to use: the one chosen if its provider still has a key and still knows the model,
/// otherwise the first model (and voice) of the first provider with a key; null when none.
ReaderChoice? effectiveReader(VoicePrefs prefs, List<SpeechProvider> available) {
  final r = prefs.reader;
  if (r != null) {
    final p = available.where((x) => x.id == r.provider).firstOrNull;
    final m = p?.models.where((x) => x.id == r.model).firstOrNull;
    if (m != null) {
      final voiceOk = r.voice == null || m.voices.isEmpty || m.voices.any((v) => v.id == r.voice);
      return voiceOk ? r : ReaderChoice(provider: r.provider, model: r.model, voice: _first(m));
    }
  }
  final p = available.firstOrNull;
  final m = p?.models.firstOrNull;
  if (p == null || m == null) return null;
  return ReaderChoice(provider: p.id, model: m.id, voice: _first(m));
}

String? _first(SpeechModel m) => m.voices.firstOrNull?.id;

/// A text as the reader gets it: Markdown's marks and code blocks out, at most 4000 characters
/// (the route's limit), cut at a sentence when it can.
String textForSpeech(String markdown, {int max = 4000}) {
  var t = markdown
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'!\[[^\]]*\]\([^)]*\)'), (_) => '')
      .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!)
      .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*>\s?', multiLine: true), '')
      .replaceAll(RegExp(r'[*_~|]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (t.length <= max) return t;
  t = t.substring(0, max);
  final dot = t.lastIndexOf(RegExp(r'[.!?]\s'));
  return dot > max ~/ 2 ? t.substring(0, dot + 1) : t;
}
