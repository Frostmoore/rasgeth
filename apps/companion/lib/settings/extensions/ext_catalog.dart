// G42.11: the page's catalog of services (MCP_CATALOG), the media providers (MEDIA_PROVIDERS) and
// the keychain's name rule, read from ext_catalog.g.dart (written from @redgiant/protocol by
// tool/ext_catalog.mjs), and `catalogConfig` ported from packages/protocol/src/mcp-catalog.ts:
// what the person typed for an entry becomes the server's transport and secrets, the very same
// (test/g42_11_extensions_test.dart checks it with the protocol's own vectors).
import 'dart:convert';

import 'ext_catalog.g.dart';

typedef Json = Map<String, dynamic>;

final Json _data = jsonDecode(extCatalogJson) as Json;

/// A text in the person's language (`{it, en}`).
String inLang(Object? o, String lang) {
  if (o is Map) return '${o[lang] ?? o['en'] ?? ''}';
  return '';
}

/// Steps in plain words for the person's language (`Guide`).
List<String> guideSteps(Object? o, String lang) {
  if (o is! Map) return const [];
  final l = o[lang] ?? o['en'];
  return l is List ? [for (final s in l) '$s'] : const [];
}

class CatalogField {
  const CatalogField(this.j);
  final Json j;
  String get env => '${j['env']}';
  bool get secret => j['secret'] == true;
  bool get optional => j['optional'] == true;
  String? get example => j['example'] as String?;
  String label(String lang) => inLang(j['label'], lang);
}

/// One service of the catalog, as the page's `McpCatalogEntry`.
class CatalogEntry {
  const CatalogEntry(this.j);
  final Json j;

  String get id => '${j['id']}';
  String get name => '${j['name']}';
  bool get official => j['official'] == true;
  String get category => '${j['category']}';
  String description(String lang) => inLang(j['description'], lang);
  Json get transport => j['transport'] as Json;
  Json get auth => j['auth'] as Json;
  String get authType => '${auth['type']}';
  String get homepage => '${j['homepage'] ?? ''}';
  Json? get userUrl => j['userUrl'] as Json?;
  bool get unverified => j['unverified'] == true;
  String? note(String lang) => j['note'] == null ? null : inLang(j['note'], lang);
  List<CatalogField> get fields => [
    for (final f in (auth['fields'] as List? ?? const [])) CatalogField(f as Json),
  ];
  Object? get guide => auth['guide'];
  bool get needsKey => authType == 'header' || authType == 'env';
  bool get signsIn => authType == 'oauth' || authType == 'app';
}

final List<CatalogEntry> mcpCatalog = [
  for (final e in _data['catalog'] as List) CatalogEntry(e as Json),
];

CatalogEntry? catalogEntry(String id) => mcpCatalog.where((e) => e.id == id).firstOrNull;

/// The kinds, in the page's order, that have at least one service.
final List<String> catalogCategories = [
  for (final c in const ['code', 'docs', 'web', 'data', 'work', 'design', 'cloud', 'home'])
    if (mcpCatalog.any((e) => e.category == c)) c,
];

/// What the person typed for an entry (the protocol's `CatalogInput`).
class CatalogInput {
  const CatalogInput({
    this.key = '',
    this.url = '',
    this.fields = const {},
    this.clientId = '',
    this.clientSecret = '',
  });
  final String key;
  final String url;
  final Map<String, String> fields;
  final String clientId;
  final String clientSecret;
}

/// The protocol's `catalogConfig`: the transport and the secrets the server's `PUT
/// /api/extensions/mcp` wants. Throws [FormatException] with the protocol's words when something
/// is missing.
Json catalogConfig(CatalogEntry entry, CatalogInput given) {
  final a = entry.auth;
  final type = entry.authType;
  final k = given.key.trim();
  if ((type == 'header' || type == 'env') && k.isEmpty) {
    throw FormatException('${entry.name} needs a key');
  }
  Json transport = Map.of(entry.transport);
  final userUrl = entry.userUrl;
  if (userUrl != null && transport['type'] == 'http') {
    final base = given.url.trim().replaceAll(RegExp(r'/+$'), '');
    if (!RegExp(r'^https?://[^\s]+$').hasMatch(base)) {
      throw FormatException('${entry.name} needs its address');
    }
    final path = '${userUrl['path']}';
    transport = {'type': 'http', 'url': base.endsWith(path) ? base : '$base$path'};
  }
  if (transport['type'] == 'http' && (type == 'oauth' || type == 'app')) {
    transport = {...transport, 'oauth': true};
  }
  if (type == 'app') {
    final id = given.clientId.trim();
    final secret = given.clientSecret.trim();
    if (id.isEmpty || (a['secret'] == true && secret.isEmpty)) {
      throw FormatException("${entry.name} needs your app's details");
    }
    return {
      'transport': transport,
      'secrets': {
        'app': {
          'clientId': id,
          if (secret.isNotEmpty) 'clientSecret': secret,
          if (a['scope'] is String && (a['scope'] as String).isNotEmpty) 'scope': a['scope'],
          if (a['authParams'] is Map) 'authParams': a['authParams'],
        },
      },
    };
  }
  if (type == 'fields') {
    final env = <String, String>{};
    for (final f in entry.fields) {
      final v = (given.fields[f.env] ?? '').trim();
      if (v.isEmpty && !f.optional) throw FormatException('${entry.name} needs ${f.label('en')}');
      if (v.isNotEmpty) env[f.env] = v;
    }
    return {
      'transport': transport,
      'secrets': {'env': env},
    };
  }
  return {
    'transport': transport,
    if (type == 'header')
      'secrets': {
        'headers': {'${a['header']}': '${a['prefix'] ?? ''}$k'},
      },
    if (type == 'env')
      'secrets': {
        'env': {'${a['env']}': k},
      },
  };
}

// ---- generation (G25.3) ----

final List<String> mediaKinds = [for (final k in (_data['media'] as Json)['kinds'] as List) '$k'];

class MediaModel {
  const MediaModel(this.id, this.label);
  final String id;
  final String label;
}

class MediaProvider {
  const MediaProvider(this.j);
  final Json j;
  String get id => '${j['id']}';
  String get name => '${j['name']}';
  String get keyUrl => '${j['keyUrl'] ?? ''}';
  String get keyExample => '${j['keyExample'] ?? ''}';
  List<MediaModel> models(String kind) => [
    for (final m in ((j['models'] as Json?)?[kind] as List? ?? const []))
      MediaModel('${(m as Json)['id']}', '${m['label']}'),
  ];
  List<MediaModel> get voices => [
    for (final v in (j['voices'] as List? ?? const []))
      MediaModel('${(v as Json)['id']}', '${v['label']}'),
  ];
}

final List<MediaProvider> mediaProviders = [
  for (final p in (_data['media'] as Json)['providers'] as List) MediaProvider(p as Json),
];

MediaProvider? mediaProvider(String id) => mediaProviders.where((p) => p.id == id).firstOrNull;

// ---- the keychain (G42.12) ----

/// The protocol's `VAULT_NAME_RE`: a credential's name.
final RegExp vaultNameRe = RegExp('${_data['vaultName']}');

/// A credential's name from its service, as the page's `vaultName`: lower case, underscores,
/// accents dropped, at most 40 characters.
String vaultName(String service) {
  const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝÑÇ';
  const to = 'aaaaaaeeeeiiiiooooouuuuyyncAAAAAAEEEEIIIIOOOOOUUUUYNC';
  final b = StringBuffer();
  for (final ch in service.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    b.write(i >= 0 ? to[i].toLowerCase() : ch);
  }
  var s = b.toString().replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  if (s.length > 40) s = s.substring(0, 40);
  return s;
}
