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
enum MascotState { idle, think, work, wait, error }

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
  });

  factory Agent.fromJson(Map<String, dynamic> j) {
    final m = j['mascot'];
    return Agent(
      id: _str(j['id']) ?? '',
      kind: agentKindFrom(_str(j['kind'])),
      name: _str(j['name']) ?? '',
      active: j['status'] != 'stopped',
      parentId: _str(j['parentId']),
      projectId: _str(j['projectId']),
      role: _str(j['role']),
      mascot: m is Map<String, dynamic> ? MascotSpec.fromJson(m) : null,
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
}
