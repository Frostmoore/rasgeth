// G42.9: an automation as the server sends it (`Automation`, `AutomationRun`, `MagicAutomation`,
// `MagicNeed` in packages/protocol/src/automations.ts), and the mailboxes the editor chooses from
// (`GET /api/settings/mailboxes`). The recipe stays the JSON the server read (zod's defaults
// filled in): the editor's draft is made from it (`fromRecipe`), never a second schema here.

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _str(Object? o) => o is String ? o : null;

class AutomationRun {
  const AutomationRun({
    required this.id,
    required this.automationId,
    required this.trigger,
    required this.status,
    required this.sessionId,
    required this.summary,
    required this.startedAt,
    required this.finishedAt,
    this.delivery,
  });

  factory AutomationRun.fromJson(Map<String, dynamic> j) {
    final d = j['delivery'];
    return AutomationRun(
      id: _str(j['id']) ?? '',
      automationId: _str(j['automationId']) ?? '',
      trigger: _str(j['trigger']) ?? 'manual',
      status: _str(j['status']) ?? 'running',
      sessionId: _str(j['sessionId']),
      summary: _str(j['summary']) ?? '',
      startedAt: _str(j['startedAt']) ?? '',
      finishedAt: _str(j['finishedAt']),
      delivery: d is Map<String, dynamic> ? RunDelivery.fromJson(d) : null,
    );
  }

  final String id;
  final String automationId;

  /// cron, webhook, manual, missed, email, message, files, after, task, startup, retry.
  final String trigger;

  /// running, ok, failed, timeout, skipped, queued.
  final String status;
  final String? sessionId;
  final String summary;
  final String startedAt;
  final String? finishedAt;
  final RunDelivery? delivery;
}

/// Whether a run's message reached the person (`AutomationDelivery`).
class RunDelivery {
  const RunDelivery({required this.status, required this.to, this.reason});

  factory RunDelivery.fromJson(Map<String, dynamic> j) => RunDelivery(
    status: _str(j['status']) ?? 'failed',
    to: [
      for (final x in j['to'] is List ? j['to'] as List : const [])
        if (x is String) x,
    ],
    reason: _str(j['reason']),
  );

  /// delivered, failed, no-chat.
  final String status;
  final List<String> to;
  final String? reason;
}

class Automation {
  const Automation({
    required this.id,
    required this.name,
    required this.yaml,
    required this.recipe,
    required this.enabled,
    required this.hasWebhookSecret,
    required this.nextRunAt,
    required this.lastRun,
    this.error,
  });

  factory Automation.fromJson(Map<String, dynamic> j) {
    final last = j['lastRun'];
    return Automation(
      id: _str(j['id']) ?? '',
      name: _str(j['name']) ?? '',
      yaml: _str(j['yaml']) ?? '',
      recipe: _map(j['recipe']),
      enabled: j['enabled'] == true,
      hasWebhookSecret: j['hasWebhookSecret'] == true,
      nextRunAt: _str(j['nextRunAt']),
      lastRun: last is Map<String, dynamic> ? AutomationRun.fromJson(last) : null,
      error: _str(j['error']),
    );
  }

  final String id;
  final String name;
  final String yaml;

  /// The recipe as the server read it (`Recipe`, defaults filled in).
  final Map<String, dynamic> recipe;
  final bool enabled;
  final bool hasWebhookSecret;
  final String? nextRunAt;
  final AutomationRun? lastRun;

  /// Why the stored recipe no longer reads.
  final String? error;

  Map<String, dynamic> get on => _map(recipe['on']);
  String get description => _str(recipe['description']) ?? '';

  /// Its title: the description, else the name (as the page's tiles).
  String get title => description.isNotEmpty ? description : name;
  String? get reminder => _str(recipe['reminder']);
  String get agent => _str(recipe['agent']) ?? 'god';
  String? get project => _str(recipe['project']);
}

/// Something a magic automation still needs (`MagicNeed`).
class MagicNeed {
  const MagicNeed({
    required this.kind,
    required this.what,
    required this.why,
    this.service,
    this.host,
    this.ready,
  });

  factory MagicNeed.fromJson(Map<String, dynamic> j) => MagicNeed(
    kind: _str(j['kind']) ?? 'other',
    what: _str(j['what']) ?? '',
    why: _str(j['why']) ?? '',
    service: _str(j['service']),
    host: _str(j['host']),
    ready: j['ready'] is bool ? j['ready'] as bool : null,
  );

  /// chat, email, extension, credential, other.
  final String kind;
  final String what;
  final String why;
  final String? service;
  final String? host;
  final bool? ready;
}

class MagicProposal {
  const MagicProposal({
    required this.yaml,
    required this.recipe,
    required this.summary,
    required this.needs,
  });

  final String yaml;
  final Map<String, dynamic> recipe;
  final String summary;
  final List<MagicNeed> needs;
}

/// A conversation with God that builds an automation (`MagicAutomation`).
class MagicAutomation {
  const MagicAutomation({
    required this.id,
    required this.title,
    required this.request,
    required this.sessionId,
    required this.agentId,
    required this.status,
    required this.proposal,
    required this.automationId,
  });

  factory MagicAutomation.fromJson(Map<String, dynamic> j) {
    final p = j['proposal'];
    return MagicAutomation(
      id: _str(j['id']) ?? '',
      title: _str(j['title']) ?? '',
      request: _str(j['request']) ?? '',
      sessionId: _str(j['sessionId']) ?? '',
      agentId: _str(j['agentId']) ?? '',
      status: _str(j['status']) ?? 'building',
      proposal: p is Map<String, dynamic>
          ? MagicProposal(
              yaml: _str(p['yaml']) ?? '',
              recipe: _map(p['recipe']),
              summary: _str(p['summary']) ?? '',
              needs: [
                for (final n in p['needs'] is List ? p['needs'] as List : const [])
                  if (n is Map<String, dynamic>) MagicNeed.fromJson(n),
              ],
            )
          : null,
      automationId: _str(j['automationId']),
    );
  }

  final String id;
  final String title;
  final String request;
  final String sessionId;
  final String agentId;

  /// building, ready, done, dismissed.
  final String status;
  final MagicProposal? proposal;
  final String? automationId;
}

/// A mailbox the editor can choose (`MailboxInfo`: never its password).
class MailboxInfo {
  const MailboxInfo({
    required this.id,
    required this.name,
    required this.category,
    this.user = '',
    this.host = '',
    this.canSend = false,
  });

  factory MailboxInfo.fromJson(Map<String, dynamic> j) => MailboxInfo(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    category: _str(j['category']) ?? 'other',
    user: _str(j['user']) ?? '',
    host: _str(j['host']) ?? '',
    canSend: j['smtp'] is Map,
  );

  final String id;
  final String name;
  final String category;
  final String user;
  final String host;
  final bool canSend;
}

/// An automation's message for the person (`automation.notice` on the wire).
class AutomationNotice {
  const AutomationNotice({
    required this.runId,
    required this.automationId,
    required this.name,
    required this.status,
    required this.sessionId,
    required this.text,
  });

  static AutomationNotice? fromWire(Map<String, dynamic> m) {
    final runId = _str(m['runId']);
    if (runId == null) return null;
    return AutomationNotice(
      runId: runId,
      automationId: _str(m['automationId']) ?? '',
      name: _str(m['name']) ?? '',
      status: _str(m['status']) ?? 'ok',
      sessionId: _str(m['sessionId']),
      text: _str(m['text']) ?? '',
    );
  }

  final String runId;
  final String automationId;
  final String name;
  final String status;
  final String? sessionId;
  final String text;
}
