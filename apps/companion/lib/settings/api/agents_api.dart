// G42.4: the routes the native agents' pages use beyond the client's own (the page's api.ts):
// a new agent with every field of the page's wizards, personal assistants'
// services, skills and routines. (God's draft of a new agent's instructions: general_api.dart;
// subprojects, `Subproject`, are the client's own since G42.5.)
import '../../api/client.dart';
import '../../api/types.dart';

/// A service a personal assistant may use (an MCP server added for everyone) and its state.
class ServiceEntry {
  const ServiceEntry({required this.name, this.state, this.tools = 0});

  final String name;

  /// connected | login | error; null while checking.
  final String? state;
  final int tools;
}

/// A skill installed for every agent.
class SkillEntry {
  const SkillEntry({required this.name, required this.description});

  final String name;
  final String description;
}

/// A routine (an automation done by one agent): its title, its schedule, on or off.
class Routine {
  const Routine({
    required this.id,
    required this.name,
    required this.title,
    required this.enabled,
    this.cron,
    this.at,
    this.agent,
  });

  factory Routine.fromJson(Map<String, dynamic> j) {
    final recipe = j['recipe'] is Map<String, dynamic>
        ? j['recipe'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final on = recipe['on'] is Map<String, dynamic>
        ? recipe['on'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final name = j['name'] as String? ?? recipe['name'] as String? ?? '';
    final d = recipe['description'] as String?;
    return Routine(
      id: j['id'] as String? ?? '',
      name: name,
      title: d != null && d.isNotEmpty ? d : name,
      enabled: j['enabled'] != false,
      cron: on['cron'] as String?,
      at: on['at'] as String?,
      agent: recipe['agent'] as String?,
    );
  }

  final String id;
  final String name;
  final String title;
  final bool enabled;
  final String? cron;
  final String? at;
  final String? agent;
}

extension AgentsApi on RedGiantClient {
  /// `POST /api/agents` with every field the page's wizards send.
  Future<Agent> createAgentWith({
    required String kind,
    required String? parentId,
    required String name,
    String? projectId,
    String? subprojectId,
    String? role,
    AgentModel? model,
    String? mode,
    List<String>? connections,
  }) async => Agent.fromJson(
    objectOf(
      await callJson('POST', '/api/agents', {
        'kind': kind,
        'parentId': parentId,
        'name': name,
        'projectId': ?projectId,
        'subprojectId': ?subprojectId,
        'role': ?role,
        if (model != null) 'model': model.toJson(),
        'mode': ?mode,
        'connections': ?connections,
      }),
    ),
  );

  /// The services added for everyone (`GET /api/extensions/mcp`, not a project's) with their
  /// state (`GET /api/extensions/mcp/status`; a failure there leaves them «checking»).
  Future<List<ServiceEntry>> assistantServices() async {
    final servers = [
      for (final o in arrayOf(await getJson('/api/extensions/mcp')))
        if (o['project_id'] == null && o['name'] is String) o['name'] as String,
    ];
    List<Map<String, dynamic>> status = const [];
    try {
      status = arrayOf(await getJson('/api/extensions/mcp/status'));
    } on ApiException {
      status = const [];
    }
    return [
      for (final n in servers)
        () {
          final s = status.where((x) => x['name'] == n).firstOrNull;
          return ServiceEntry(
            name: n,
            state: s?['state'] as String?,
            tools: (s?['tools'] as num?)?.toInt() ?? 0,
          );
        }(),
    ];
  }

  /// The skills installed for every agent (`GET /api/extensions/installed`, platform scope).
  Future<List<SkillEntry>> platformSkills() async => [
    for (final o in arrayOf(await getJson('/api/extensions/installed')))
      if (o['kind'] == 'skill' && o['scope'] == 'platform')
        SkillEntry(
          name: o['name'] as String? ?? '',
          description: o['description'] as String? ?? '',
        ),
  ];

  /// The routines one agent does (`GET /api/automations`, by its id or its name).
  Future<List<Routine>> routinesOf(Agent a) async => [
    for (final o in arrayOf(await getJson('/api/automations')))
      if (Routine.fromJson(o) case final r when r.agent == a.id || r.agent == a.name) r,
  ];

  /// `POST /api/automations`: a recipe written as YAML (as the page's editor sends it).
  Future<void> createRoutine(String yaml) => callJson('POST', '/api/automations', {'yaml': yaml});

  /// `POST /api/automations/:id/enabled`.
  Future<void> setRoutineOn(String id, bool on) =>
      callJson('POST', '/api/automations/${Uri.encodeComponent(id)}/enabled', {'enabled': on});
}
