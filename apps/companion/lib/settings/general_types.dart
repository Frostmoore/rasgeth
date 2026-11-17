// The shapes of Settings › General (G42.4): the rows the page's catalogs are generated into
// (general_words.g.dart) and the part of `GET /api/setup` and `GET /api/debug` the screen reads.
import '../api/types.dart';

/// One of `AGENT_LANGUAGES` (protocol, languages.ts).
class AgentLanguageRow {
  const AgentLanguageRow(this.code, this.native, this.en, this.it, {this.common = false});

  final String code;
  final String native;
  final String en;
  final String it;
  final bool common;

  /// The name in the interface's language.
  String nameIn(String lang) => lang == 'it' ? it : en;
}

/// One of `SEARCH_PROVIDERS` (protocol, search.ts).
class SearchProviderRow {
  const SearchProviderRow(
    this.id,
    this.name, {
    required this.needsUrl,
    required this.keyUrl,
    this.keyExample,
  });

  final String id;
  final String name;
  final bool needsUrl;
  final String keyUrl;
  final String? keyExample;
}

/// A speech to text model of a provider in the cloud.
class SttModelRow {
  const SttModelRow(this.id, this.label, {this.usd, this.per, this.closes});

  final String id;
  final String label;
  final double? usd;

  /// minute | kchars | mtokens.
  final String? per;
  final String? closes;
}

/// One of `VOICE_PROVIDERS` that writes down what is said (protocol, voice.ts).
class SttProviderRow {
  const SttProviderRow(
    this.id,
    this.name, {
    required this.keyUrl,
    required this.keyExample,
    required this.models,
  });

  final String id;
  final String name;
  final String keyUrl;
  final String keyExample;
  final List<SttModelRow> models;
}

/// An item of «What's new» (WhatsNew.tsx's `ITEMS`): its release and its words' keys.
class NewsRow {
  const NewsRow(this.version, this.title, this.text);

  final String version;
  final String title;
  final String text;
}

/// Release order, as the page's `compareVersions`: negative when [a] came before [b].
int compareVersions(String a, String b) {
  List<int> parts(String s) => [for (final x in s.split('.')) int.tryParse(x) ?? 0];
  final pa = parts(a);
  final pb = parts(b);
  for (var i = 0; i < (pa.length > pb.length ? pa.length : pb.length); i++) {
    final d = (i < pa.length ? pa[i] : 0) - (i < pb.length ? pb[i] : 0);
    if (d != 0) return d;
  }
  return 0;
}

/// As the page's `newsSince`: grouped by release, newest first, the written order inside one.
List<({String version, List<NewsRow> items})> newsSince(String? seen, List<NewsRow> rows) {
  final groups = <String, List<NewsRow>>{};
  for (final r in rows) {
    if (seen != null && compareVersions(r.version, seen) <= 0) continue;
    groups.putIfAbsent(r.version, () => []).add(r);
  }
  final keys = groups.keys.toList()..sort((a, b) => compareVersions(b, a));
  return [for (final k in keys) (version: k, items: groups[k]!)];
}

/// How voice messages are written down (`config.transcription`).
class Transcription {
  const Transcription({required this.api, this.url = '', this.provider, this.model});

  static Transcription? fromJson(Object? o) {
    if (o is! Map<String, dynamic> || o['api'] is! String) return null;
    return Transcription(
      api: o['api'] as String,
      url: o['url'] is String ? o['url'] as String : '',
      provider: o['provider'] is String ? o['provider'] as String : null,
      model: o['model'] is String ? o['model'] as String : null,
    );
  }

  /// local | whisper-asr | openai | cloud.
  final String api;
  final String url;
  final String? provider;
  final String? model;

  /// The card it belongs to: local, remote, compatible, or the provider's id.
  String get kind => switch (api) {
    'local' => 'local',
    'whisper-asr' => 'remote',
    'openai' => 'compatible',
    _ => provider ?? 'compatible',
  };
}

/// What Settings › General reads of `GET /api/setup`.
class GeneralState {
  const GeneralState({
    this.language,
    this.agentLanguage,
    this.instructions = '',
    this.backupModel,
    this.searchProvider,
    this.searxngUrl,
    this.searxngManaged = false,
    this.canRunSearch = false,
    this.transcription,
    this.transcriptionKey = false,
    this.imagesModel,
    this.imagesKey = false,
    this.searchKeys = const [],
    this.voiceKeys = const [],
    this.locked = const {},
  });

  factory GeneralState.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> map(Object? o) => o is Map<String, dynamic> ? o : const {};
    String? str(Object? o) => o is String && o.isNotEmpty ? o : null;
    List<String> list(Object? o) => [
      if (o is List)
        for (final x in o) '$x',
    ];
    final c = map(j['config']);
    final s = map(j['secretsSet']);
    final locked = map(j['locked']);
    return GeneralState(
      language: str(c['language']),
      agentLanguage: str(c['agentLanguage']),
      instructions: c['instructions'] is String ? c['instructions'] as String : '',
      backupModel: AgentModel.fromJson(c['backupModel']),
      searchProvider: str(c['searchProvider']) ?? (str(c['searxngUrl']) != null ? 'searxng' : null),
      searxngUrl: str(c['searxngUrl']),
      searxngManaged: c['searxngManaged'] == true,
      canRunSearch: j['canRunSearch'] == true,
      transcription: Transcription.fromJson(c['transcription']),
      transcriptionKey: s['transcription'] == true,
      imagesModel: str(c['imagesModel']),
      imagesKey: s['images'] == true,
      searchKeys: list(s['search']),
      voiceKeys: list(s['voice']),
      locked: {
        for (final e in locked.entries)
          if (e.value == true) e.key,
      },
    );
  }

  final String? language;
  final String? agentLanguage;
  final String instructions;
  final AgentModel? backupModel;
  final String? searchProvider;
  final String? searxngUrl;
  final bool searxngManaged;
  final bool canRunSearch;
  final Transcription? transcription;
  final bool transcriptionKey;
  final String? imagesModel;
  final bool imagesKey;

  /// The search services with a key kept.
  final List<String> searchKeys;

  /// The voice providers with a key ready (the chat's, the generation's or the voice's).
  final List<String> voiceKeys;

  /// What the environment set (search, voice, images…): shown, never changed.
  final Set<String> locked;
}

/// `GET /api/debug`.
class DebugState {
  const DebugState({
    required this.enabled,
    required this.forced,
    required this.bytes,
    required this.files,
  });

  factory DebugState.fromJson(Map<String, dynamic> j) => DebugState(
    enabled: j['enabled'] == true,
    forced: j['forced'] == true,
    bytes: (j['bytes'] as num?)?.toInt() ?? 0,
    files: (j['files'] as num?)?.toInt() ?? 0,
  );

  final bool enabled;
  final bool forced;
  final int bytes;
  final int files;
}
