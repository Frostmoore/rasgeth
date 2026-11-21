// G42.11: the routes of Settings › Extensions, as the page calls them (`packages/web/src/api.ts`:
// `proposals`, `decideExtension`, `createExtension`, `installed`, `exportSkill`, `importSkill`,
// `mcpServers`, `setMcp`, `mcpStatus`, `mcpLogin`, `removeMcp`, the magic integrations and
// extensions `magicExt*`, and the generation's `setup`, `setupMedia`, `setupMediaNative`,
// `setupMediaKey`, `mediaVoices`), read leniently (a field the server does not send is its empty
// value).
import 'dart:typed_data';

import '../../api/client.dart';
import '../extensions/ext_catalog.dart' show Json;

String? _s(Object? o) => o is String ? o : null;
int? _n(Object? o) => o is num ? o.toInt() : null;
List<String> _strings(Object? o) => o is List ? [for (final x in o) x is String ? x : '$x'] : [];
Json _map(Object? o) => o is Map<String, dynamic> ? o : const {};
List<Json> _list(Object? o) => o is List ? [for (final x in o) _map(x)] : const [];
Map<String, String> _files(Object? o) => {
  for (final e in _map(o).entries) e.key: e.value is String ? e.value as String : '',
};

/// One test of a proposal or a magic part.
class TestResult {
  const TestResult(this.name, this.passed, this.detail);
  factory TestResult.fromJson(Json j) =>
      TestResult(_s(j['name']) ?? '', j['passed'] == true, _s(j['detail']) ?? '');
  final String name;
  final bool passed;
  final String detail;
}

/// An agent's tool or skill waiting for the person (or one whose tests failed).
class ExtProposal {
  const ExtProposal(this.j);
  final Json j;

  String get id => _s(j['id']) ?? '';
  String? get projectId => _s(j['projectId']);
  String get kind => _s(j['kind']) ?? 'skill';
  bool get isTool => kind == 'tool';
  String get name => _s(j['name']) ?? '';
  String get author => _s(j['author']) ?? '';
  String get status => _s(j['status']) ?? 'pending';
  Json get input => _map(j['input']);
  Json get spec => _map(input['spec']);
  String get description => _s(spec['description']) ?? _s(input['description']) ?? '';
  String? get command => _s(spec['command']);
  String? get body => _s(input['body']);
  String? get summary => _s(input['summary']);
  Map<String, String> get files => _files(input['files']);
  List<TestResult> get report => [for (final r in _list(j['report'])) TestResult.fromJson(r)];
  Json? get previous => j['previous'] is Map<String, dynamic> ? j['previous'] as Json : null;
  String? get previousSkillMd => _s(previous?['skillMd']);
  List<String> get previousFiles => _strings(previous?['files']);
  String? get proposedSkillMd => _s(j['proposedSkillMd']);
  String? get updateLine => _s(j['updateLine']);
  bool get isUpdate => kind == 'skill' && previous != null;

  /// The files that run as code (the page's own test in `ProposalView`).
  List<String> get scripts => kind != 'skill'
      ? const []
      : [
          for (final e in files.entries)
            if (RegExp(
                  r'\.(sh|bash|zsh|ps1|bat|cmd|py|js|mjs|cjs|ts|rb|pl|php)$',
                  caseSensitive: false,
                ).hasMatch(e.key) ||
                e.value.startsWith('#!'))
              e.key,
        ];

  /// The files the installed skill has that the new version keeps.
  List<String> get kept => [
    for (final f in previousFiles)
      if (!files.containsKey(f)) f,
  ];
}

/// A tool or skill installed, for every project (`platform`) or one (`project:<id>`).
class Installed {
  const Installed(this.j);
  final Json j;
  String get kind => _s(j['kind']) ?? 'skill';
  String get name => _s(j['name']) ?? '';
  String get description => _s(j['description']) ?? '';
  String get scope => _s(j['scope']) ?? 'platform';
  String get path => _s(j['path']) ?? '';
}

/// A server added (`McpEntry`).
class McpServer {
  const McpServer(this.j);
  final Json j;
  String get name => _s(j['name']) ?? '';
  String? get projectId => _s(j['project_id']);
  Json get transport => _map(j['transport']);

  /// Its address, or its command with its arguments.
  String get address => transport['type'] == 'http'
      ? _s(transport['url']) ?? ''
      : [_s(transport['command']) ?? '', ..._strings(transport['args'])].join(' ');
}

/// How a server is doing (`McpStatus`): connected, login, error.
class McpState {
  const McpState(this.j);
  final Json j;
  String get name => _s(j['name']) ?? '';
  String get state => _s(j['state']) ?? 'error';
  int get tools => _n(j['tools']) ?? 0;
  String? get error => _s(j['error']);
}

/// A magic package's part (`MagicPart`).
class MagicPart {
  const MagicPart(this.j);
  final Json j;
  String get kind => _s(j['kind']) ?? 'tool';
  String get name => _s(j['name']) ?? '';
  String get description => _s(j['description']) ?? '';
  String? get command => _s(j['command']);
  Map<String, String> get files => _files(j['files']);
  String get proposalId => _s(j['proposalId']) ?? '';
  String get status => _s(j['status']) ?? 'pending';
  List<TestResult> get tests => [for (final r in _list(j['tests'])) TestResult.fromJson(r)];

  /// Its arguments by name, `?` after the optional ones (the page's `args`).
  List<String> get args {
    final schema = _map(j['inputSchema']);
    final required = _strings(schema['required']).toSet();
    return [for (final k in _map(schema['properties']).keys) required.contains(k) ? k : '$k?'];
  }
}

/// One thing that must hold before «Approve and install» (`MagicCheck`).
class MagicCheck {
  const MagicCheck(this.j);
  final Json j;
  String get kind => _s(j['kind']) ?? 'test';
  String get what => _s(j['what']) ?? '';
  bool get ok => j['ok'] == true;
  String? get detail => _s(j['detail']);
  String? get service => _s(j['service']);
  List<String> get hosts => _strings(j['hosts']);
  bool get exists => j['exists'] == true;
}

/// A magic integration or extension (G38.3, `MagicExtension`).
class MagicExt {
  const MagicExt(this.j);
  final Json j;
  String get id => _s(j['id']) ?? '';
  String get kind => _s(j['kind']) ?? 'integration';
  String get title => _s(j['title']) ?? '';
  String get request => _s(j['request']) ?? '';
  String get sessionId => _s(j['sessionId']) ?? '';
  String get agentId => _s(j['agentId']) ?? '';
  String get status => _s(j['status']) ?? 'building';
  Json? get proposal => j['proposal'] is Map<String, dynamic> ? j['proposal'] as Json : null;
  String get pTitle => _s(proposal?['title']) ?? '';
  String get pSummary => _s(proposal?['summary']) ?? '';
  List<String> get hosts => _strings(proposal?['hosts']);
  List<MagicPart> get parts => [for (final p in _list(proposal?['parts'])) MagicPart(p)];
  List<Json> get credentials => _list(proposal?['credentials']);
  List<MagicCheck> get checks => [for (final c in _list(j['checks'])) MagicCheck(c)];
  bool get canApprove => j['canApprove'] == true;
  List<String> get installed => _strings(j['installed']);
}

/// What the generation needs of `GET /api/setup`: the choices and which providers have a key.
class MediaSetup {
  const MediaSetup(this.j);
  final Json j;
  Json get _config => _map(j['config']);
  Json? choice(String kind) {
    final m = _map(_config['media'])[kind];
    return m is Map<String, dynamic> ? m : null;
  }

  bool get native => _config['mediaNative'] != false;
  bool hasKey(String provider) => _strings(_map(j['secretsSet'])['media']).contains(provider);
}

extension ExtensionsApi on RedGiantClient {
  String _e(String s) => Uri.encodeComponent(s);

  Future<List<ExtProposal>> extProposals({String? status}) async => [
    for (final x in arrayOf(
      await getJson('/api/extensions/proposals', status == null ? null : {'status': status}),
    ))
      ExtProposal(x),
  ];

  Future<void> decideExtension(String id, {required bool approve}) => callJson(
    'POST',
    '/api/extensions/proposals/${_e(id)}/decision',
    {'decision': approve ? 'approve' : 'reject'},
  );

  /// A skill the person writes (`NewSkill`): installed once made, they are its reviewer.
  Future<void> createSkill({
    required String? projectId,
    required String name,
    required String description,
    required String body,
  }) => callJson('POST', '/api/extensions/proposals', {
    'projectId': projectId,
    'input': {
      'kind': 'skill',
      'name': name,
      'description': description,
      'body': body,
      'untestableReason': 'Written by the user, who is also its reviewer.',
    },
  });

  Future<List<Installed>> installedExtensions() async => [
    for (final x in arrayOf(await getJson('/api/extensions/installed'))) Installed(x),
  ];

  /// A skill's folder as a .zip, to share it.
  Future<Uint8List> exportSkill(String name, String scope) =>
      rawBytes('GET', '/api/extensions/skills/${_e(name)}/export', query: {'scope': scope});

  /// A shared skill (.zip) into [scope]; a 409 means one of that name is there (ask, then
  /// [replace]).
  Future<String> importSkill(List<int> zip, String scope, {bool replace = false}) async =>
      _s(
        objectOf(
          await rawCall(
            'POST',
            '/api/extensions/skills/import',
            query: {'scope': scope, if (replace) 'replace': '1'},
            body: zip,
          ),
        )['name'],
      ) ??
      '';

  Future<List<McpServer>> mcpServers() async => [
    for (final x in arrayOf(await getJson('/api/extensions/mcp'))) McpServer(x),
  ];

  Future<List<McpState>> mcpStatus() async => [
    for (final x in arrayOf(await getJson('/api/extensions/mcp/status'))) McpState(x),
  ];

  Future<void> setMcp(Json body) => callJson('PUT', '/api/extensions/mcp', body);

  Future<void> removeMcp(String name) => callJson('DELETE', '/api/extensions/mcp/${_e(name)}');

  /// Signs in to a server: null when it already works, or the service's sign-in page.
  Future<String?> mcpLogin(String name, String origin) async => _s(
    objectOf(
      await callJson('POST', '/api/extensions/mcp/${_e(name)}/login', {'origin': origin}),
    )['authorizeUrl'],
  );

  // ---- magic integrations and extensions (G38.3) ----

  Future<List<MagicExt>> magicExts() async {
    final r = await getJson('/api/magic-ext');
    return r is List ? [for (final x in arrayOf(r)) MagicExt(x)] : const [];
  }

  Future<MagicExt> magicExt(String id) async =>
      MagicExt(objectOf(await getJson('/api/magic-ext/${_e(id)}')));

  Future<MagicExt> _magic(String path, [Object? body]) async =>
      MagicExt(objectOf(await callJson('POST', path, body ?? const <String, dynamic>{})));

  Future<MagicExt> startMagicExt(String kind, String request) =>
      _magic('/api/magic-ext', {'kind': kind, 'request': request});
  Future<MagicExt> approveMagicExt(String id) => _magic('/api/magic-ext/${_e(id)}/approve');
  Future<MagicExt> rejectMagicExt(String id, String? reason) =>
      _magic('/api/magic-ext/${_e(id)}/reject', {'reason': ?reason});
  Future<MagicExt> retestMagicExt(String id) => _magic('/api/magic-ext/${_e(id)}/retest');
  Future<MagicExt> addMagicExtCredential(String id, String name, String value) =>
      _magic('/api/magic-ext/${_e(id)}/credential', {'name': name, 'value': value});
  Future<MagicExt> bindMagicExtCredential(String id, String name) =>
      _magic('/api/magic-ext/${_e(id)}/bind', {'name': name});
  Future<MagicExt> updateMagicExt(String id, String request) =>
      _magic('/api/magic-ext/${_e(id)}/update', {'request': request});
  Future<void> uninstallMagicExt(String id) =>
      callJson('POST', '/api/magic-ext/${_e(id)}/uninstall', const <String, dynamic>{});
  Future<void> dismissMagicExt(String id) => callJson('DELETE', '/api/magic-ext/${_e(id)}');

  // ---- generation (G25.3) ----

  Future<MediaSetup> mediaSetup() async => MediaSetup(objectOf(await getJson('/api/setup')));

  Future<void> setMedia(String kind, Json? choice) =>
      callJson('PUT', '/api/setup/media/${_e(kind)}', {'choice': choice});

  Future<void> setMediaNative(bool on) => callJson('PUT', '/api/setup/media-native', {'on': on});

  Future<void> setMediaKey(String provider, String? key) =>
      callJson('PUT', '/api/setup/media-keys/${_e(provider)}', {'key': key});

  Future<List<(String, String)>> mediaVoices(String provider) async => [
    for (final v in arrayOf(await getJson('/api/setup/media/voices', {'provider': provider})))
      (_s(v['id']) ?? '', _s(v['label']) ?? ''),
  ];
}
