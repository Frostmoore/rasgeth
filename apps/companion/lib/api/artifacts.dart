// Settings › Artifacts in the app (G42.2, the page's `Artifacts.tsx`): every artifact of the
// person in every place they see, its facts, and what it asks for. The capability words and
// sentences are the protocol's (`artifact-bridge.ts`: `parseCapability`, `capabilityWord`,
// `capabilitySentence`), checked against `test/fixtures/artifact_vectors.json`
// (tool/artifact_vectors.mjs).

import '../brand.dart';

/// The caps «ask» may have, and the one preselected (`ARTIFACT_ASK_CAPS`, `…_DEFAULT`).
const artifactAskCaps = [0.1, 0.5, 2.0, 5.0];
const artifactAskCapDefault = 0.5;

/// The folder artifacts live in (`ARTIFACT_DIR`).
const artifactDir = 'artefatti';

/// A `.rgartifact` by its name.
bool isRgArtifact(String name) => RegExp(r'\.rgartifact$', caseSensitive: false).hasMatch(name);

/// A capability an artifact may ask for: `ask`, `storage`, or `files` with its folder.
class ArtifactCapability {
  const ArtifactCapability(this.kind, [this.dir]);

  final String kind;

  /// `files`: a folder of the artifact's project, relative, ending in «/».
  final String? dir;

  /// The canonical word (`capabilityWord`): «files:dati/».
  String get word => kind == 'files' ? 'files:$dir' : kind;
}

// One folder name: no separators, no dot first, nothing hidden, no control characters.
final _segment = RegExp(r'^(?!\.)[^\\/:*?"<>|\u0000-\u001f\u007f]{1,120}$');

/// A capability from the header's words, or null (`parseCapability`).
ArtifactCapability? parseCapability(String word) {
  final w = word.trim();
  if (w == 'ask' || w == 'storage') return ArtifactCapability(w);
  final m = RegExp(r'^files:(.+)$').firstMatch(w);
  final rest = m?.group(1);
  if (rest == null || rest.length > 200) return null;
  final parts = rest.replaceFirst(RegExp(r'/+$'), '').split('/');
  if (parts.isEmpty || !parts.every((p) => _segment.hasMatch(p) && p.trim() == p)) return null;
  return ArtifactCapability('files', '${parts.join('/')}/');
}

/// A capability in the person's words (`capabilitySentence`); [agent] answers `ask`.
String capabilitySentence(String lang, String capability, [String? agent]) {
  final it = lang == 'it';
  final c = parseCapability(capability);
  if (c == null) return capability;
  if (c.kind == 'files') {
    return it
        ? 'leggere i file della cartella ${c.dir} del progetto (solo lettura)'
        : "read the files in the project's folder ${c.dir} (read only)";
  }
  if (c.kind == 'storage') {
    return it
        ? 'tenere dati suoi su $kProductName (solo testo, fino a 5 MB)'
        : 'keep data of its own on $kProductName (text only, up to 5 MB)';
  }
  final who = agent != null && agent.isNotEmpty
      ? (it ? '«$agent»' : '“$agent”')
      : (it ? "l'agente che l'ha fatto" : 'the agent that made it');
  return it
      ? 'fare domande a $who, che risponde senza strumenti e spende dal tuo budget fino al tetto che scegli'
      : 'ask $who questions, answered with no tools and paid from your budget up to the cap you choose';
}

/// What the person granted (`ArtifactGrant`): `ask` with its agent, cap and spending.
class ArtifactGrant {
  const ArtifactGrant({
    required this.capability,
    this.agentId,
    this.capUsd,
    this.spentUsd,
    required this.at,
  });

  factory ArtifactGrant.fromJson(Map<String, dynamic> j) => ArtifactGrant(
    capability: '${j['capability'] ?? ''}',
    agentId: j['agentId'] as String?,
    capUsd: (j['capUsd'] as num?)?.toDouble(),
    spentUsd: (j['spentUsd'] as num?)?.toDouble(),
    at: '${j['at'] ?? ''}',
  );

  final String capability;
  final String? agentId;
  final double? capUsd;
  final double? spentUsd;
  final String at;
}

/// One artifact (`ArtifactInfo` of the page's api.ts).
class ArtifactInfo {
  const ArtifactInfo({
    required this.scope,
    required this.place,
    required this.path,
    required this.file,
    required this.name,
    required this.version,
    required this.libs,
    required this.wants,
    required this.grants,
    required this.hasData,
    required this.from,
    required this.size,
    required this.modifiedAt,
    required this.readOnly,
    required this.pendingRun,
  });

  factory ArtifactInfo.fromJson(Map<String, dynamic> j) => ArtifactInfo(
    scope: '${j['scope'] ?? ''}',
    place: '${j['place'] ?? ''}',
    path: '${j['path'] ?? ''}',
    file: '${j['file'] ?? ''}',
    name: '${j['name'] ?? ''}',
    version: (j['version'] as num?)?.toInt(),
    libs: [...(j['libs'] as List? ?? const []).whereType<String>()],
    wants: [...(j['wants'] as List? ?? const []).whereType<String>()],
    grants: [
      for (final g in (j['grants'] as List? ?? const []).whereType<Map<String, dynamic>>())
        ArtifactGrant.fromJson(g),
    ],
    hasData: j['hasData'] == true,
    from: j['from'] as String?,
    size: (j['size'] as num?)?.toInt() ?? 0,
    modifiedAt: '${j['modifiedAt'] ?? ''}',
    readOnly: j['readOnly'] == true,
    pendingRun: j['pendingRun'] == true,
  );

  final String scope;
  final String place;
  final String path;
  final String file;
  final String name;
  final int? version;
  final List<String> libs;
  final List<String> wants;
  final List<ArtifactGrant> grants;
  final bool hasData;
  final String? from;
  final int size;
  final String modifiedAt;
  final bool readOnly;
  final bool pendingRun;

  /// What it asks for, canonical and once each (unknown words dropped), as the page shows them.
  List<ArtifactCapability> get wanted {
    final out = <String, ArtifactCapability>{};
    for (final w in wants) {
      final c = parseCapability(w);
      if (c != null) out[c.word] = c;
    }
    return [...out.values];
  }

  ArtifactGrant? grantOf(String word) => grants.where((g) => g.capability == word).firstOrNull;
}

/// The artifacts grouped by place, the places in the order the server lists them.
List<(String scope, List<ArtifactInfo> items)> artifactGroups(List<ArtifactInfo> list) {
  final groups = <String, List<ArtifactInfo>>{};
  for (final a in list) {
    groups.putIfAbsent(a.scope, () => []).add(a);
  }
  return [for (final e in groups.entries) (e.key, e.value)];
}

/// Bytes as the page writes them (`bytes` in format.ts).
String artifactBytes(int n) => n >= 1073741824
    ? '${(n / 1073741824).toStringAsFixed(2)} GB'
    : n >= 1048576
    ? '${(n / 1048576).toStringAsFixed(1)} MB'
    : n >= 1024
    ? '${(n / 1024).toStringAsFixed(1)} KB'
    : '$n B';
