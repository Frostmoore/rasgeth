// G42.9: Settings › Automations' routes, the same the page calls (`automations`, `previewAutomation`,
// `magic…`, `repoHook`, `mailboxes` in packages/web/src/api.ts). A recipe always travels as YAML,
// as the page's editor sends it; the server reads it and says why not.
import '../../api/client.dart';
import '../automations/automation_types.dart';

/// What a save answers: the automation, and its webhook's secret the only time it is shown.
typedef AutomationSaved = ({Automation automation, String? webhookSecret});

/// The server's reading of a YAML while the person writes: why not, and the next times.
typedef AutomationPreview = ({String? error, List<String> next});

String _id(String id) => Uri.encodeComponent(id);

extension AutomationsApi on RedGiantClient {
  AutomationSaved _saved(Object? o) {
    final j = objectOf(o);
    final s = j['webhookSecret'];
    return (
      automation: Automation.fromJson(objectOf(j['automation'])),
      webhookSecret: s is String && s.isNotEmpty ? s : null,
    );
  }

  /// `GET /api/automations`.
  Future<List<Automation>> automations() async => [
    for (final o in arrayOf(await getJson('/api/automations'))) Automation.fromJson(o),
  ];

  /// `POST /api/automations` with the recipe's YAML.
  Future<AutomationSaved> createAutomation(String yaml) async =>
      _saved(await callJson('POST', '/api/automations', {'yaml': yaml}));

  /// `PUT /api/automations/:id`.
  Future<AutomationSaved> updateAutomation(String id, String yaml) async =>
      _saved(await callJson('PUT', '/api/automations/${_id(id)}', {'yaml': yaml}));

  /// `DELETE /api/automations/:id`.
  Future<void> deleteAutomation(String id) => callJson('DELETE', '/api/automations/${_id(id)}');

  /// `POST /api/automations/:id/enabled`.
  Future<Automation> enableAutomation(String id, bool enabled) async => Automation.fromJson(
    objectOf(await callJson('POST', '/api/automations/${_id(id)}/enabled', {'enabled': enabled})),
  );

  /// `POST /api/automations/:id/run`: started now (or skipped: one is running).
  Future<AutomationRun> runAutomation(String id) async =>
      AutomationRun.fromJson(objectOf(await callJson('POST', '/api/automations/${_id(id)}/run')));

  /// `POST /api/automations/:id/secret`: a new webhook secret, shown only this once.
  Future<String> rotateAutomationSecret(String id) async {
    final j = objectOf(await callJson('POST', '/api/automations/${_id(id)}/secret'));
    return j['webhookSecret'] is String ? j['webhookSecret'] as String : '';
  }

  /// `GET /api/automations/:id/runs`: the recent runs, newest first.
  Future<List<AutomationRun>> automationRuns(String id) async => [
    for (final o in arrayOf(await getJson('/api/automations/${_id(id)}/runs')))
      AutomationRun.fromJson(o),
  ];

  /// `POST /api/automations/preview`.
  Future<AutomationPreview> previewAutomation(String yaml, [int count = 5]) async {
    final j = objectOf(
      await callJson('POST', '/api/automations/preview', {'yaml': yaml, 'count': count}),
    );
    return (
      error: j['error'] is String ? j['error'] as String : null,
      next: [
        for (final n in j['next'] is List ? j['next'] as List : const [])
          if (n is String) n,
      ],
    );
  }

  /// `POST /api/automations/:id/repo-hook`: the routine's webhook on Gitea or GitHub.
  Future<void> repoHook(String id, String secret, String project) => callJson(
    'POST',
    '/api/automations/${_id(id)}/repo-hook',
    {'secret': secret, 'project': project},
  );

  /// `GET /api/settings/mailboxes` (passwords never come back).
  Future<List<MailboxInfo>> mailboxes() async {
    final j = objectOf(await getJson('/api/settings/mailboxes'));
    return [
      for (final b in j['boxes'] is List ? j['boxes'] as List : const [])
        if (b is Map<String, dynamic>) MailboxInfo.fromJson(b),
    ];
  }

  // --- Magic automations (G33.3) ---------------------------------------------------------

  /// `GET /api/magic`.
  Future<List<MagicAutomation>> magicAutomations() async => [
    for (final o in arrayOf(await getJson('/api/magic'))) MagicAutomation.fromJson(o),
  ];

  /// `GET /api/magic/:id`.
  Future<MagicAutomation> magicAutomation(String id) async =>
      MagicAutomation.fromJson(objectOf(await getJson('/api/magic/${_id(id)}')));

  /// `POST /api/magic`: a conversation with God starts.
  Future<MagicAutomation> startMagic(String request) async => MagicAutomation.fromJson(
    objectOf(await callJson('POST', '/api/magic', {'request': request})),
  );

  /// `POST /api/magic/:id/approve`, with the YAML changed in the editor first or as God wrote it.
  Future<AutomationSaved> approveMagic(String id, [String? yaml]) async =>
      _saved(await callJson('POST', '/api/magic/${_id(id)}/approve', {'yaml': ?yaml}));

  /// `POST /api/magic/:id/reject`, with what is wrong.
  Future<void> rejectMagic(String id, [String? reason]) =>
      callJson('POST', '/api/magic/${_id(id)}/reject', {'reason': ?reason});

  /// `DELETE /api/magic/:id`.
  Future<void> dismissMagic(String id) => callJson('DELETE', '/api/magic/${_id(id)}');
}
