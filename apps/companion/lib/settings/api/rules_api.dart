// G42.4: the routes of Settings › Requests, Safety, Tools and Commands, as the page calls them
// (`packages/web/src/api.ts`): the person's choices are saved as configuration, so a save answers
// with the change (`PlatformChange`) that «Undo» takes back.
import '../../api/client.dart';

/// One tool as Settings › Tools shows it (`ToolView` in packages/protocol/src/tools.ts).
class ToolView {
  const ToolView({
    required this.id,
    required this.group,
    this.essential = false,
    this.tokens = 0,
    this.global = true,
    this.exceptions = const [],
    this.kit,
    this.state = 'on',
  });

  factory ToolView.fromJson(Map<String, dynamic> j) => ToolView(
    id: j['id'] is String ? j['id'] as String : '',
    group: j['group'] is String ? j['group'] as String : '',
    essential: j['essential'] == true,
    tokens: (j['tokens'] as num?)?.toInt() ?? 0,
    global: j['global'] != false,
    kit: j['kit'] is String ? j['kit'] as String : null,
    state: j['state'] is String ? j['state'] as String : (j['global'] == false ? 'off' : 'on'),
    exceptions: [
      for (final e in (j['exceptions'] is List ? j['exceptions'] as List : const []))
        if (e is Map<String, dynamic> && e['agentId'] is String)
          (
            agentId: e['agentId'] as String,
            name: e['name'] is String ? e['name'] as String : e['agentId'] as String,
          ),
    ],
  );

  final String id;
  final String group;
  final bool essential;
  final int tokens;

  /// On for every agent.
  final bool global;

  /// The agents whose own choice differs from the rule for everyone.
  final List<({String agentId, String name})> exceptions;

  /// Its kit (3.9.4; none for the essential ones).
  final String? kit;

  /// on (from the start) | auto (off by default) | off (switched off by the person).
  final String state;

  ToolView withGlobal(bool on, [String? kitState]) => ToolView(
    id: id,
    group: group,
    essential: essential,
    tokens: tokens,
    global: on,
    exceptions: exceptions,
    kit: kit,
    state: on ? (kitState ?? 'on') : 'off',
  );

  ToolView withState(String s) => ToolView(
    id: id,
    group: group,
    essential: essential,
    tokens: tokens,
    global: global,
    exceptions: exceptions,
    kit: kit,
    state: s,
  );
}

/// One kit of tools (3.9.4, `KitView`): what it weighs, its state and how it was chosen.
class KitView {
  const KitView({
    required this.id,
    this.entries = const [],
    this.tokens = 0,
    this.state = 'auto',
    this.byDefault = 'auto',
    this.own,
    this.global,
  });

  factory KitView.fromJson(Map<String, dynamic> j) => KitView(
    id: j['id'] is String ? j['id'] as String : '',
    entries: [for (final e in (j['entries'] is List ? j['entries'] as List : const [])) '$e'],
    tokens: (j['tokens'] as num?)?.toInt() ?? 0,
    state: j['state'] is String ? j['state'] as String : 'auto',
    byDefault: j['default'] is String ? j['default'] as String : 'auto',
    own: j['own'] is String ? j['own'] as String : null,
    global: j['global'] is String ? j['global'] as String : null,
  );

  final String id;
  final List<String> entries;
  final int tokens;
  final String state;

  /// Its state without a choice: the kit's default, or the agent's role.
  final String byDefault;

  /// The choice that sets it (the agent's own, in an agent's view), or none.
  final String? own;

  /// In an agent's view: the choice for every agent, or none.
  final String? global;

  KitView chosen(String? pick, {required bool forAgent}) => KitView(
    id: id,
    entries: entries,
    tokens: tokens,
    state: pick ?? (forAgent ? (global ?? byDefault) : byDefault),
    byDefault: byDefault,
    own: pick,
    global: global,
  );
}

/// The tools for every agent: the entries, and the tokens on every message now and saved.
class ToolsView {
  const ToolsView({
    required this.entries,
    this.total = 0,
    this.saved = 0,
    this.kits = const [],
    this.essential,
    this.agentId,
  });

  factory ToolsView.fromJson(Map<String, dynamic> j) => ToolsView(
    entries: [
      for (final e in (j['entries'] is List ? j['entries'] as List : const []))
        if (e is Map<String, dynamic>) ToolView.fromJson(e),
    ],
    total: (j['total'] as num?)?.toInt() ?? 0,
    saved: (j['saved'] as num?)?.toInt() ?? 0,
    kits: [
      for (final k in (j['kits'] is List ? j['kits'] as List : const []))
        if (k is Map<String, dynamic>) KitView.fromJson(k),
    ],
    essential: (j['essential'] as num?)?.toInt(),
    agentId: j['agentId'] is String ? j['agentId'] as String : null,
  );

  final List<ToolView> entries;

  /// Tokens on every message with what is on from the start, and the rest (3.9.4).
  final int total;
  final int saved;
  final List<KitView> kits;

  /// Tokens of the essential tools alone.
  final int? essential;

  /// The agent of the view; none for every agent.
  final String? agentId;

  ToolsView _with(List<ToolView> next, List<KitView> kitsNext) => ToolsView(
    entries: next,
    total: next.where((e) => e.state == 'on').fold(0, (n, e) => n + e.tokens),
    saved: next.where((e) => e.state != 'on').fold(0, (n, e) => n + e.tokens),
    kits: kitsNext,
    essential: essential,
    agentId: agentId,
  );

  /// [id] switched on or off, the sums counted again (lit at once; the server's answer follows).
  ToolsView flipped(String id, bool on) {
    String? kitOf(ToolView e) => kits.where((k) => k.id == e.kit).firstOrNull?.state;
    return _with([for (final e in entries) e.id == id ? e.withGlobal(on, kitOf(e)) : e], kits);
  }

  /// A kit's choice changed ([pick] null: back to the default), the sums counted again.
  ToolsView withKit(String id, String? pick) {
    final forAgent = agentId != null;
    final next = [for (final k in kits) k.id == id ? k.chosen(pick, forAgent: forAgent) : k];
    final state = next.where((k) => k.id == id).firstOrNull?.state;
    return _with([
      for (final e in entries)
        e.kit == id && state != null && (forAgent || e.global) ? e.withState(state) : e,
    ], next);
  }
}

/// A request decided without the person (`UnattendedDecision`).
class UnattendedDecision {
  const UnattendedDecision({
    required this.id,
    required this.kind,
    required this.agentId,
    required this.agentName,
    required this.what,
    required this.decision,
    required this.by,
    required this.reason,
    required this.createdAt,
    this.sessionId,
    this.model,
    this.danger = const [],
  });

  static UnattendedDecision? fromJson(Map<String, dynamic> j) {
    String? s(String k) => j[k] is String ? j[k] as String : null;
    final id = s('id');
    if (id == null) return null;
    return UnattendedDecision(
      id: id,
      kind: s('kind') ?? 'approval',
      agentId: s('agentId') ?? '',
      agentName: s('agentName') ?? '',
      what: s('what') ?? '',
      decision: s('decision') ?? 'deny',
      by: s('by') ?? 'timeout',
      reason: s('reason') ?? '',
      createdAt: s('createdAt') ?? '',
      sessionId: s('sessionId'),
      model: s('model'),
      danger: [for (final d in (j['danger'] is List ? j['danger'] as List : const [])) '$d'],
    );
  }

  final String id;
  final String kind;
  final String agentId;
  final String agentName;
  final String? sessionId;
  final String what;
  final List<String> danger;

  /// allow | deny | answered | blocked.
  final String decision;

  /// classifier | timeout.
  final String by;
  final String reason;
  final String? model;
  final String createdAt;
}

extension RulesApi on RedGiantClient {
  /// The id of the change a save made (for «Undo»), when the server says it.
  String? _change(Object? o) =>
      o is Map<String, dynamic> && o['id'] is String ? o['id'] as String : null;

  /// `POST /api/platform/changes/:id/undo`: a saved choice taken back.
  Future<void> undoChange(String id) =>
      callJson('POST', '/api/platform/changes/${Uri.encodeComponent(id)}/undo', const {});

  /// `GET /api/settings/requests`: `settings`, `defaults`, `defaultModel` and `critical`.
  Future<Map<String, dynamic>> requestSettings() async =>
      objectOf(await getJson('/api/settings/requests'));

  /// `PUT /api/settings/requests`.
  Future<String?> setRequestSettings(Map<String, dynamic> s) async =>
      _change(await callJson('PUT', '/api/settings/requests', s));

  /// `GET /api/unattended`: the requests decided without the person, newest first.
  Future<List<UnattendedDecision>> unattended() async => [
    for (final j in arrayOf(await getJson('/api/unattended'))) ?UnattendedDecision.fromJson(j),
  ];

  /// `GET /api/settings/commands` whole: `settings`, `defaults`, `serverMaxTurns`.
  Future<Map<String, dynamic>> commandLimits() async =>
      objectOf(await getJson('/api/settings/commands'));

  /// `PUT /api/settings/commands`: the whole settings again.
  Future<String?> saveCommandLimits(Map<String, dynamic> s) async =>
      _change(await callJson('PUT', '/api/settings/commands', s));

  /// `GET /api/setup`: the Safety page reads `policy`, `budgetUsd`, `config.retentionDays`,
  /// `secretsSet.keys`, `locked.anthropic` and `names.god` from it.
  Future<Map<String, dynamic>> setupState() async => objectOf(await getJson('/api/setup'));

  /// `PUT /api/setup/safety`.
  Future<void> setSafety(Map<String, dynamic> b) => callJson('PUT', '/api/setup/safety', b);

  /// `GET /api/tools`: every tool for every agent; with [agentId], what that agent gets.
  Future<ToolsView> toolsView({String? agentId}) async => ToolsView.fromJson(
    objectOf(await getJson('/api/tools', agentId == null ? null : {'agentId': agentId})),
  );

  /// `PUT /api/tools/kits`: the kits for every agent (3.9.4): on | auto | off | default.
  Future<void> setKits(Map<String, String> kits) =>
      callJson('PUT', '/api/tools/kits', {'kits': kits});

  /// `PUT /api/agents/:id/tools/kits`: one agent's kits (default: as for every agent).
  Future<void> setAgentKits(String agentId, Map<String, String> kits) =>
      callJson('PUT', '/api/agents/${Uri.encodeComponent(agentId)}/tools/kits', {'kits': kits});

  /// `PUT /api/tools`: the tools off for every agent (the essential ones are refused).
  Future<void> setToolsOff(List<String> off) => callJson('PUT', '/api/tools', {'off': off});

  /// `GET /api/extensions/installed`: the extensions' tools (every agent has them).
  Future<List<({String name, String description})>> extensionTools() async => [
    for (final x in arrayOf(await getJson('/api/extensions/installed')))
      if (x['kind'] == 'tool' && x['name'] is String)
        (
          name: x['name'] as String,
          description: x['description'] is String ? x['description'] as String : '',
        ),
  ];
}
