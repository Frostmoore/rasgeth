// The app's side of RedGiant's protocol: the shapes of `packages/protocol/src/devices.ts`
// (G40.1) and `packages/protocol/src/mascot.ts` (G40.2), read leniently (unknown fields are
// ignored, so a newer server does not break an older app within the same `appProtocol`).

/// The app protocol this build speaks (`APP_PROTOCOL_VERSION` in `@redgiant/protocol`).
const int kAppProtocolVersion = 1;

/// `DevicePlatform`.
enum DevicePlatform { android, ios, windows, macos, linux, other }

DevicePlatform devicePlatformFrom(String? s) =>
    DevicePlatform.values.firstWhere((p) => p.name == s, orElse: () => DevicePlatform.other);

/// `AgentKind`.
enum AgentKind { god, demigod, orchestrator, agent, subagent, inspector, assistant }

AgentKind agentKindFrom(String? s) =>
    AgentKind.values.firstWhere((k) => k.name == s, orElse: () => AgentKind.agent);

/// `MascotState`: idle, thinking, working, waiting for the person, blocked.
/// What a mascot shows; `active`: awake for two minutes after answering the person (3.8.1).
enum MascotState { idle, active, think, work, wait, error }

MascotState mascotStateFrom(String? s) =>
    MascotState.values.firstWhere((k) => k.name == s, orElse: () => MascotState.idle);

/// `MascotTheme`: the server writes a theme's colours into the SVG.
enum MascotTheme { light, dark }

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _str(Object? o) => o is String ? o : null;
int _int(Object? o) => o is num ? o.toInt() : 0;
double _num(Object? o) => o is num ? o.toDouble() : 0;

/// `AppHello.access`.
class AppAccess {
  const AppAccess({
    required this.password,
    required this.code,
    required this.token,
    this.firstAccess,
  });

  factory AppAccess.fromJson(Map<String, dynamic> j) => AppAccess(
    password: j['password'] == true,
    code: j['code'] == true,
    token: j['token'] == true,
    firstAccess: _str(j['firstAccess']),
  );

  final bool password;

  /// The authenticator app's code is asked after the password.
  final bool code;
  final bool token;

  /// While there is no password: `password`, `code` or `not_here`.
  final String? firstAccess;
}

/// `GET /api/app/hello`: what this RedGiant is, with or without a token.
class AppHello {
  const AppHello({
    required this.version,
    required this.appProtocol,
    required this.protocolVersion,
    required this.machine,
    required this.firstStartCompleted,
    required this.access,
    required this.signedIn,
    this.nodeFingerprint,
    this.deviceId,
    this.deviceName,
  });

  factory AppHello.fromJson(Map<String, dynamic> j) {
    if (j['app'] != 'redgiant') throw const FormatException('Not a RedGiant');
    final device = _map(j['device']);
    return AppHello(
      version: _str(j['version']),
      appProtocol: _int(j['appProtocol']),
      protocolVersion: _int(j['protocolVersion']),
      machine: _str(j['machine']) ?? 'RedGiant',
      firstStartCompleted: j['firstStartCompleted'] == true,
      access: AppAccess.fromJson(_map(j['access'])),
      signedIn: j['signedIn'] == true,
      nodeFingerprint: _str(j['nodeFingerprint']),
      deviceId: _str(device['id']),
      deviceName: _str(device['name']),
    );
  }

  /// RedGiant's version (null when run from the sources).
  final String? version;
  final int appProtocol;
  final int protocolVersion;

  /// The machine's name, never the owner's.
  final String machine;
  final bool firstStartCompleted;
  final AppAccess access;
  final bool signedIn;
  final String? nodeFingerprint;
  final String? deviceId;
  final String? deviceName;
}

/// Whether this app and a server understand each other (same idea as `assessRelease`).
enum Compatibility { ok, serverTooOld, serverTooNew }

Compatibility compatibilityOf(AppHello hello) => hello.appProtocol < kAppProtocolVersion
    ? Compatibility.serverTooOld
    : hello.appProtocol > kAppProtocolVersion
    ? Compatibility.serverTooNew
    : Compatibility.ok;

/// `DeviceView`: a device as listed, never its token.
class DeviceView {
  const DeviceView({
    required this.id,
    required this.name,
    required this.platform,
    required this.createdAt,
    this.lastUsedAt,
  });

  factory DeviceView.fromJson(Map<String, dynamic> j) => DeviceView(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    platform: devicePlatformFrom(_str(j['platform'])),
    createdAt: _str(j['createdAt']) ?? '',
    lastUsedAt: _str(j['lastUsedAt']),
  );

  final String id;
  final String name;
  final DevicePlatform platform;
  final String createdAt;
  final String? lastUsedAt;
}

/// `DeviceCreated`: the only answer with a device's token in clear.
class DeviceCreated {
  const DeviceCreated({required this.token, required this.device});

  factory DeviceCreated.fromJson(Map<String, dynamic> j) {
    final token = _str(j['token']);
    if (token == null || token.isEmpty) throw const FormatException('No token');
    return DeviceCreated(token: token, device: DeviceView.fromJson(_map(j['device'])));
  }

  final String token;
  final DeviceView device;
}

/// `MascotColors`: one theme's colours, as sRGB hex.
class MascotColors {
  const MascotColors({
    required this.body,
    required this.line,
    required this.soft,
    required this.blocked,
    required this.second,
    required this.cap,
  });

  factory MascotColors.fromJson(Map<String, dynamic> j) => MascotColors(
    body: _str(j['body']) ?? '#888888',
    line: _str(j['line']) ?? '#444444',
    soft: _str(j['soft']) ?? '#cccccc',
    blocked: _str(j['blocked']) ?? '#999999',
    second: _str(j['second']) ?? '#888888',
    cap: _str(j['cap']) ?? '#888888',
  );

  final String body;
  final String line;
  final String soft;
  final String blocked;
  final String second;
  final String cap;
}

/// `MascotSpec`: an agent's face, the same everywhere (page, app, nodes).
class MascotSpec {
  const MascotSpec({
    required this.v,
    required this.seed,
    required this.kind,
    required this.handDrawn,
    required this.hue,
    required this.chroma,
    required this.parts,
    required this.bodyPath,
    required this.light,
    required this.dark,
  });

  factory MascotSpec.fromJson(Map<String, dynamic> j) {
    final colors = _map(j['colors']);
    return MascotSpec(
      v: _int(j['v']),
      seed: _str(j['seed']) ?? '',
      kind: agentKindFrom(_str(j['kind'])),
      handDrawn: j['handDrawn'] == true,
      hue: _num(j['hue']),
      chroma: _num(j['chroma']),
      parts: _map(j['parts']).map((k, v) => MapEntry(k, '$v')),
      bodyPath: _str(j['bodyPath']) ?? '',
      light: MascotColors.fromJson(_map(colors['light'])),
      dark: MascotColors.fromJson(_map(colors['dark'])),
    );
  }

  /// Version of the generator's tables.
  final int v;
  final String seed;
  final AgentKind kind;
  final bool handDrawn;
  final double hue;
  final double chroma;

  /// The parts' names (body, eyes, mouth, head, pattern, holds).
  final Map<String, String> parts;

  /// The body's outline as an SVG path on a 100x100 box.
  final String bodyPath;
  final MascotColors light;
  final MascotColors dark;

  MascotColors colorsFor(MascotTheme theme) => theme == MascotTheme.dark ? dark : light;
}

/// An agent as `GET /api/agents` lists it (the fields the app uses).
/// A chosen model (`ModelSpec`): provider, model and, when the model takes one, the effort.
class AgentModel {
  const AgentModel({required this.provider, required this.model, this.effort});

  static AgentModel? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    final p = _str(o['provider']);
    final m = _str(o['model']);
    if (p == null || m == null || p.isEmpty || m.isEmpty) return null;
    return AgentModel(provider: p, model: m, effort: _str(o['effort']));
  }

  final String provider;
  final String model;

  /// low | medium | high | max.
  final String? effort;

  String get key => '$provider/$model';

  Map<String, Object?> toJson() => {'provider': provider, 'model': model, 'effort': ?effort};

  @override
  bool operator ==(Object other) =>
      other is AgentModel &&
      other.provider == provider &&
      other.model == model &&
      other.effort == effort;

  @override
  int get hashCode => Object.hash(provider, model, effort);
}

/// How an agent asks before acting (`PermissionMode`), in the page's order.
const agentModes = ['manual', 'auto', 'plan', 'readonly'];

/// The efforts a model may take (the protocol's `Effort`).
const efforts = ['low', 'medium', 'high', 'max'];

class Agent {
  const Agent({
    required this.id,
    required this.kind,
    required this.name,
    required this.active,
    this.parentId,
    this.projectId,
    this.role,
    this.mascot,
    this.model,
    this.mode,
    this.mascotSeed,
    this.compactAt,
    this.compactKeep,
    this.projects = const [],
    this.status = 'active',
    this.connections = const [],
    this.skills,
    this.subprojectId,
  });

  factory Agent.fromJson(Map<String, dynamic> j) {
    final m = j['mascot'];
    return Agent(
      id: _str(j['id']) ?? '',
      kind: agentKindFrom(_str(j['kind'])),
      name: _str(j['name']) ?? '',
      // Stopped, or removed from the team (3.8.9: only the «Removed agents» list has those).
      active: j['status'] != 'stopped' && j['status'] != 'removed',
      parentId: _str(j['parentId']),
      projectId: _str(j['projectId']),
      role: _str(j['role']),
      mascot: m is Map<String, dynamic> ? MascotSpec.fromJson(m) : null,
      model: AgentModel.fromJson(j['model']),
      mode: _str(j['mode']),
      mascotSeed: _str(j['mascotSeed']),
      compactAt: ((j['compaction'] as Map?)?['at'] as num?)?.toDouble(),
      compactKeep: ((j['compaction'] as Map?)?['keep'] as num?)?.toDouble(),
      projects: [
        for (final p in (j['projects'] as List?) ?? const <Object?>[])
          if (p is String) p,
      ],
      status: _str(j['status']) ?? 'active',
      connections: [
        for (final p in (j['connections'] as List?) ?? const <Object?>[])
          if (p is String) p,
      ],
      skills: j['skills'] is List
          ? [
              for (final p in j['skills'] as List)
                if (p is String) p,
            ]
          : null,
      subprojectId: _str(j['subprojectId']),
    );
  }

  final String id;
  final AgentKind kind;
  final String name;

  /// `status: "active"` (false: stopped).
  final bool active;
  final String? parentId;
  final String? projectId;
  final String? role;
  final MascotSpec? mascot;

  /// Its own model (null: the one above it, or the default).
  final AgentModel? model;

  /// manual | auto | plan | readonly (null: auto).
  final String? mode;
  final String? mascotSeed;

  /// Where its conversations are summarised (G24.14c, `compaction.at`; null: the default 0.8).
  final double? compactAt;

  /// How much of the end stays word for word (`compaction.keep`; null: the server's default).
  final double? compactKeep;

  /// Other projects it is assigned to (agents and personal agents only).
  final List<String> projects;

  /// The server's `status`: active | stopped | removed.
  final String status;

  /// A personal assistant's services (MCP servers by name, G24.11).
  final List<String> connections;

  /// The skills it uses (null: every skill, new ones too; G24.14c).
  final List<String>? skills;

  /// Where in its project it works (a subproject), if not the whole project.
  final String? subprojectId;

  Agent withModel(AgentModel? m) => Agent(
    id: id,
    kind: kind,
    name: name,
    active: active,
    parentId: parentId,
    projectId: projectId,
    role: role,
    mascot: mascot,
    model: m,
    mode: mode,
    mascotSeed: mascotSeed,
    compactAt: compactAt,
    compactKeep: compactKeep,
    projects: projects,
    status: status,
    connections: connections,
    skills: skills,
    subprojectId: subprojectId,
  );
}

/// Who goes with an agent when it is removed (3.8.9): an id, a name, a kind.
class AgentBrief {
  const AgentBrief({required this.id, required this.name, required this.kind});

  factory AgentBrief.fromJson(Map<String, dynamic> j) => AgentBrief(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    kind: agentKindFrom(_str(j['kind'])),
  );

  final String id;
  final String name;
  final AgentKind kind;
}

/// `GET /api/agents/:id/remove-preview` (3.8.9): what removing the agent takes with it.
class RemovePreview {
  const RemovePreview({
    required this.agent,
    this.others = const [],
    this.tasks = 0,
    this.running = 0,
    this.allowed = true,
    this.why,
  });

  factory RemovePreview.fromJson(Map<String, dynamic> j) => RemovePreview(
    agent: AgentBrief.fromJson(_map(j['agent'])),
    others: [
      for (final w in (j['with'] as List?) ?? const <Object?>[])
        if (w is Map<String, dynamic>) AgentBrief.fromJson(w),
    ],
    tasks: (j['tasks'] as num?)?.toInt() ?? 0,
    running: (j['running'] as num?)?.toInt() ?? 0,
    allowed: j['allowed'] != false,
    why: _str(j['why']),
  );

  final AgentBrief agent;

  /// The agents below it, removed with it (the server's `with`).
  final List<AgentBrief> others;

  /// Open tasks that close («agent removed») and turns that stop.
  final int tasks;
  final int running;

  /// False for God, Demi-God and the Chat: nobody removes them.
  final bool allowed;
  final String? why;
}

/// One entry of `GET /api/agents/removed` (3.8.9): the agent as it was, and its removal.
class RemovedAgent {
  const RemovedAgent({
    required this.agent,
    required this.at,
    required this.by,
    this.reason = '',
    this.others = const [],
    this.sessions = 0,
  });

  factory RemovedAgent.fromJson(Map<String, dynamic> j) {
    final r = _map(j['removed']);
    return RemovedAgent(
      agent: Agent.fromJson(j),
      at: _str(r['at']) ?? '',
      by: _str(r['by']) ?? 'person',
      reason: _str(r['reason']) ?? '',
      others: [
        for (final w in (r['with'] as List?) ?? const <Object?>[])
          if (w is Map<String, dynamic>) AgentBrief.fromJson(w),
      ],
      sessions: (r['sessions'] as num?)?.toInt() ?? 0,
    );
  }

  final Agent agent;

  /// When (ISO), and by whom: `person`, or the name of the agent that did it.
  final String at;
  final String by;
  final String reason;

  /// Removed together with it (restored together too).
  final List<AgentBrief> others;

  /// Its conversations, still readable.
  final int sessions;

  bool get byPerson => by == 'person';
}

/// One entry of the tools' catalog (`GET /api/tools`).
class ToolEntry {
  const ToolEntry({
    required this.id,
    required this.group,
    this.essential = false,
    this.globalOn = true,
    this.own,
    bool? on,
    this.tokens = 0,
  }) : on = on ?? globalOn;

  factory ToolEntry.fromJson(Map<String, dynamic> j) => ToolEntry(
    id: _str(j['id']) ?? '',
    group: _str(j['group']) ?? '',
    essential: j['essential'] == true,
    globalOn: j['global'] != false,
    own: _str(j['own']),
    on: j['on'] is bool ? j['on'] as bool : null,
    tokens: (j['tokens'] as num?)?.toInt() ?? 0,
  );

  /// One agent's own choice (`on` | `off`; null: as for every agent).
  final String? own;

  /// What the agent gets.
  final bool on;

  /// About what it weighs on every message.
  final int tokens;

  final String id;
  final String group;

  /// Never switched off.
  final bool essential;

  /// On for every agent (not switched off in Settings › Tools).
  final bool globalOn;
}

/// An agent's instructions as the person reads them (`PromptView`).
class PromptView {
  const PromptView({required this.text, required this.isDefault, required this.defaultText});

  factory PromptView.fromJson(Map<String, dynamic> j) => PromptView(
    text: _str(j['text']) ?? '',
    isDefault: j['isDefault'] != false,
    defaultText: _str(j['defaultText']) ?? '',
  );

  final String text;
  final bool isDefault;
  final String defaultText;
}

/// What «Improve the instructions» takes or took: tokens and dollars (null: no money).
class RefineCost {
  const RefineCost({required this.tokens, this.usd});

  factory RefineCost.fromJson(Map<String, dynamic> j) => RefineCost(
    tokens: _int(j['inputTokens']) + _int(j['outputTokens']),
    usd: j['usd'] is num ? (j['usd'] as num).toDouble() : null,
  );

  final int tokens;
  final double? usd;
}

/// One collection as an agent reads it (`KnowledgeAgentCollection`).
class AgentCollection {
  const AgentCollection({
    required this.id,
    required this.name,
    required this.scope,
    required this.byScope,
    required this.on,
    this.own,
    this.chunks = 0,
  });

  factory AgentCollection.fromJson(Map<String, dynamic> j) => AgentCollection(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    scope: _str(j['scope']) ?? 'global',
    byScope: j['byScope'] == true,
    on: j['on'] == true,
    own: _str(j['own']),
    chunks: (j['chunks'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;

  /// global | agent | project.
  final String scope;

  /// Reachable by where it belongs alone.
  final bool byScope;
  final bool on;

  /// The person's own choice for this agent (on | off; null: by where it belongs).
  final String? own;
  final int chunks;
}
