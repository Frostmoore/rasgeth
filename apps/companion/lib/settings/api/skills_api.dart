// 3.9.7: the routes of Settings › Skills, as the page calls them (`packages/web/src/api.ts`:
// `installed`, `proposals`, `decideExtension`, `skillVersions`, `skillVersion`, `rollbackSkill`),
// read leniently (a field the server does not send is its empty value).
import '../../api/client.dart';

String? _s(Object? o) => o is String ? o : null;
int? _n(Object? o) => o is num ? o.toInt() : null;
List<String> _strings(Object? o) => o is List ? [for (final x in o) x is String ? x : '$x'] : [];
Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};

/// A skill installed for every project (`platform`) or for one (`project:<id>`).
class InstalledSkill {
  const InstalledSkill({required this.name, required this.description, required this.scope});

  factory InstalledSkill.fromJson(Map<String, dynamic> j) => InstalledSkill(
    name: _s(j['name']) ?? '',
    description: _s(j['description']) ?? '',
    scope: _s(j['scope']) ?? 'platform',
  );

  final String name;
  final String description;
  final String scope;
}

/// One version of an installed skill (the server's `SkillVersion`).
class SkillVersion {
  const SkillVersion({
    required this.version,
    required this.how,
    required this.author,
    required this.approvedBy,
    required this.reason,
    required this.fromVersion,
    required this.createdAt,
    required this.files,
    required this.restorable,
    required this.current,
  });

  factory SkillVersion.fromJson(Map<String, dynamic> j) => SkillVersion(
    version: _n(j['version']) ?? 0,
    how: _s(j['how']) ?? 'install',
    author: _s(j['author']),
    approvedBy: _s(j['approvedBy']),
    reason: _s(j['reason']),
    fromVersion: _n(j['fromVersion']),
    createdAt: _s(j['createdAt']) ?? '',
    files: _strings(j['files']),
    restorable: j['restorable'] != false,
    current: j['current'] == true,
  );

  final int version;

  /// baseline, edited, install, update, import or rollback.
  final String how;
  final String? author;
  final String? approvedBy;
  final String? reason;
  final int? fromVersion;
  final String createdAt;
  final List<String> files;
  final bool restorable;
  final bool current;
}

/// An agent's skill waiting for the person: a new one, or a new version of an installed one.
class SkillProposal {
  const SkillProposal({
    required this.id,
    required this.name,
    required this.author,
    required this.description,
    required this.body,
    required this.summary,
    required this.previousSkillMd,
    required this.proposedSkillMd,
    required this.scripts,
    required this.passed,
  });

  factory SkillProposal.fromJson(Map<String, dynamic> j) {
    final input = _map(j['input']);
    final files = _map(input['files']);
    final previous = j['previous'];
    return SkillProposal(
      id: _s(j['id']) ?? '',
      name: _s(j['name']) ?? '',
      author: _s(j['author']) ?? '',
      description: _s(input['description']) ?? '',
      body: _s(input['body']) ?? '',
      summary: _s(input['summary']),
      previousSkillMd: previous is Map<String, dynamic> ? _s(previous['skillMd']) : null,
      proposedSkillMd: _s(j['proposedSkillMd']),
      scripts: [
        for (final e in files.entries)
          if (_scriptExt.hasMatch(e.key) ||
              (e.value is String && (e.value as String).startsWith('#!')))
            e.key,
      ]..sort(),
      passed: [
        for (final r in j['report'] is List ? j['report'] as List : const [])
          if (r is Map) r['passed'] == true,
      ].every((p) => p),
    );
  }

  final String id;
  final String name;
  final String author;
  final String description;
  final String body;
  final String? summary;

  /// The installed skill it changes, as it is now (null for a new skill).
  final String? previousSkillMd;
  final String? proposedSkillMd;
  final List<String> scripts;
  final bool passed;

  bool get isUpdate => previousSkillMd != null;
}

/// The files that run as code, as the page and the server see them (`scriptFiles`).
final _scriptExt = RegExp(
  r'\.(sh|bash|zsh|ps1|psm1|bat|cmd|py|js|mjs|cjs|ts|mts|rb|pl|php|lua|exe|dll|so|dylib)$',
  caseSensitive: false,
);

extension SkillsApi on RedGiantClient {
  String _e(String s) => Uri.encodeComponent(s);

  Future<List<InstalledSkill>> installedSkills() async => [
    for (final x in arrayOf(await getJson('/api/extensions/installed')))
      if (x['kind'] == 'skill') InstalledSkill.fromJson(x),
  ];

  /// The agents' skills waiting for the person (tools are approved in the page).
  Future<List<SkillProposal>> waitingSkills() async => [
    for (final x in arrayOf(await getJson('/api/extensions/proposals', {'status': 'pending'})))
      if (x['kind'] == 'skill') SkillProposal.fromJson(x),
  ];

  Future<void> decideSkill(String id, {required bool approve}) => callJson(
    'POST',
    '/api/extensions/proposals/${_e(id)}/decision',
    {'decision': approve ? 'approve' : 'reject'},
  );

  Future<List<SkillVersion>> skillVersions(String name, String scope) async => [
    for (final x in arrayOf(
      await getJson('/api/extensions/skills/${_e(name)}/versions', {'scope': scope}),
    ))
      SkillVersion.fromJson(x),
  ];

  Future<String> skillVersionText(String name, String scope, int version) async =>
      _s(
        objectOf(
          await getJson('/api/extensions/skills/${_e(name)}/versions/$version', {'scope': scope}),
        )['skillMd'],
      ) ??
      '';

  /// «Go back to version N»: the new version's number.
  Future<int> rollbackSkill(String name, String scope, int version) async =>
      _n(
        objectOf(
          await callJson('POST', '/api/extensions/skills/${_e(name)}/rollback', {
            'version': version,
            'scope': scope,
          }),
        )['version'],
      ) ??
      0;
}
