// The shapes the app reads for the first start (G40.8) and the settings of the RedGiant it is
// connected to: `@redgiant/protocol`'s setup-network.ts, release.ts (UpdateStatus, and 3.8.1's
// UpdateProgress), firstboot.ts (OsUpdates with 3.8.1's OsUpdateRun), devices and push. Read
// leniently: a field an older server lacks is null, an unknown one is ignored.

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _str(Object? o) => o is String ? o : null;
int? _intOrNull(Object? o) => o is num ? o.toInt() : null;
double _num(Object? o) => o is num ? o.toDouble() : 0;
List<Map<String, dynamic>> _list(Object? o) =>
    o is List ? o.whereType<Map<String, dynamic>>().toList() : const [];

/// `SetupWifiNetwork`: a network RedGiant saw before opening the temporary one.
class HomeWifi {
  const HomeWifi({required this.ssid, required this.security, required this.signal});

  factory HomeWifi.fromJson(Map<String, dynamic> j) => HomeWifi(
    ssid: _str(j['ssid']) ?? '',
    security: _str(j['security']) ?? 'psk',
    signal: _intOrNull(j['signal']) ?? -100,
  );

  final String ssid;

  /// iwd's kind: psk, open, 8021x, wep…
  final String security;

  /// dBm.
  final int signal;

  bool get open => security == 'open';

  /// Networks RedGiant cannot join (enterprise, WEP): shown, not chosen.
  bool get usable => security != '8021x' && security != 'wep';

  /// 0-100, as the page's Wi-Fi panel.
  int get quality => (2 * (signal + 100)).clamp(0, 100);
}

/// `SetupHomeTry`: the last home network tried from the temporary network.
class HomeTry {
  const HomeTry({required this.state, required this.ssid, this.error, required this.at});

  static HomeTry? fromJson(Object? o) {
    final j = _map(o);
    final s = _str(j['state']);
    if (s != 'connected' && s != 'failed') return null;
    return HomeTry(
      state: s!,
      ssid: _str(j['ssid']) ?? '',
      error: _str(j['error']),
      at: _intOrNull(j['at']) ?? 0,
    );
  }

  final String state;
  final String ssid;

  /// The helper's code (connect_failed, not_found, wifi_off…).
  final String? error;
  final int at;

  bool get failed => state == 'failed';
}

/// `SetupNetworkStatus`, the part the app uses.
class SetupNetworkStatus {
  const SetupNetworkStatus({
    required this.active,
    required this.mode,
    required this.ssid,
    required this.trying,
    required this.networks,
    this.lastTry,
  });

  factory SetupNetworkStatus.fromJson(Map<String, dynamic> j) => SetupNetworkStatus(
    active: j['active'] == true,
    mode: _str(j['mode']) ?? 'off',
    ssid: _str(j['ssid']) ?? '',
    trying: j['trying'] == true,
    networks: [for (final n in _list(j['networks'])) HomeWifi.fromJson(n)]
      ..sort((a, b) => b.signal.compareTo(a.signal)),
    lastTry: HomeTry.fromJson(j['lastTry']),
  );

  final bool active;

  /// off, setup or maintenance.
  final String mode;
  final String ssid;
  final bool trying;
  final List<HomeWifi> networks;
  final HomeTry? lastTry;
}

/// `GET /api/setup-network` (and the setup channel's `info`): where the app is, the network.
class SetupNetworkInfo {
  const SetupNetworkInfo({required this.here, this.ssid, this.status});

  factory SetupNetworkInfo.fromJson(Map<String, dynamic> j) {
    final s = j['status'] ?? j['network'];
    return SetupNetworkInfo(
      here: _str(j['here']) ?? 'home',
      ssid: _str(j['ssid']),
      status: s is Map<String, dynamic> ? SetupNetworkStatus.fromJson(s) : null,
    );
  }

  /// home, setup or maintenance.
  final String here;
  final String? ssid;
  final SetupNetworkStatus? status;
}

/// `SetupHomeResult`.
class HomeResult {
  const HomeResult({required this.state, this.address});

  factory HomeResult.fromJson(Map<String, dynamic> j) =>
      HomeResult(state: _str(j['state']) ?? 'trying', address: _str(j['address']));

  /// connected (the cable: [address] on the home network) or trying (Wi-Fi).
  final String state;
  final String? address;

  bool get connected => state == 'connected';
}

/// How far a download (or a phase) is: bytes, speed and the seconds left.
class Progress {
  const Progress({
    required this.done,
    required this.total,
    required this.bps,
    this.eta,
    this.items = const [],
  });

  static Progress? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    return Progress(
      done: _num(o['done']),
      total: _num(o['total']),
      bps: _num(o['bps']),
      eta: _intOrNull(o['eta']),
      items: [
        for (final i in _list(o['items']))
          ProgressItem(
            name: _str(i['name']) ?? '',
            done: _num(i['done']),
            total: _num(i['total']),
            state: _str(i['state']) ?? 'wait',
          ),
      ],
    );
  }

  final double done;
  final double total;
  final double bps;
  final int? eta;

  /// RedGiant OS: each image (or the system's files' archive) on its own.
  final List<ProgressItem> items;

  /// 0-1, or null while the total is not known.
  double? get fraction => total > 0 ? (done / total).clamp(0, 1).toDouble() : null;
}

/// One image of a download: wait, down, extract, done, error.
class ProgressItem {
  const ProgressItem({
    required this.name,
    required this.done,
    required this.total,
    required this.state,
  });

  final String name;
  final double done;
  final double total;
  final String state;
}

/// `UpdateStatus` (`GET /api/update/status`), with 3.8.1's `progress` when the server has it.
class UpdateStatus {
  const UpdateStatus({
    required this.install,
    this.installed,
    this.latest,
    required this.state,
    required this.gate,
    this.checkedAt,
    this.note,
    this.command,
    this.downloadUrl,
    required this.canUpdateHere,
    this.phase,
    this.progress,
    this.firstVersion,
  });

  factory UpdateStatus.fromJson(Map<String, dynamic> j) {
    final note = _map(j['note']);
    final p = _map(j['progress']);
    return UpdateStatus(
      install: _str(j['install']) ?? 'source',
      installed: _str(j['installed']),
      latest: _str(j['latest']),
      state: _str(j['state']) ?? 'unknown',
      gate: _str(j['gate']) ?? 'none',
      checkedAt: _str(j['checkedAt']),
      note: note.isEmpty ? null : note,
      command: _str(j['command']),
      downloadUrl: _str(j['downloadUrl']),
      canUpdateHere: j['canUpdateHere'] == true,
      phase: _str(p['phase']),
      progress: Progress.fromJson(j['progress']),
      firstVersion: _str(j['firstVersion']),
    );
  }

  /// The version this installation was born with (kept with its data), null when unknown.
  final String? firstVersion;

  /// windows, mac, docker, os, source.
  final String install;
  final String? installed;
  final String? latest;

  /// latest, available, unreachable, unknown.
  final String state;

  /// none, normal, mandatory, breaking.
  final String gate;
  final String? checkedAt;

  /// `ReleaseNote`: `{it, en}` texts.
  final Map<String, dynamic>? note;

  /// Docker: the commands that bring the new image.
  final String? command;
  final String? downloadUrl;
  final bool canUpdateHere;

  /// 3.8.1, Windows: scan, download, installer, build, restart, failed.
  final String? phase;
  final Progress? progress;

  bool get available => state == 'available';

  String? noteIn(String lang) => _str(note?[lang]) ?? _str(note?['en']);
}

/// `OsUpdateRun` (3.8.1): an update RedGiant OS is applying, or applied last.
class OsRun {
  const OsRun({
    this.from,
    this.startedAt,
    this.finishedAt,
    this.reason,
    this.steps = const [],
    this.stepAt = const {},
    this.images = const [],
    this.filesBytes = 0,
    this.progress,
  });

  static OsRun? fromJson(Object? o) {
    if (o is! Map<String, dynamic>) return null;
    final plan = _map(o['plan']);
    return OsRun(
      from: _str(o['from']),
      startedAt: _str(o['startedAt']),
      finishedAt: _str(o['finishedAt']),
      reason: _str(o['reason']),
      steps: [for (final s in (o['steps'] is List ? o['steps'] as List : const [])) '$s'],
      stepAt: {
        for (final e in _map(o['stepAt']).entries)
          if (e.value is String) e.key: e.value as String,
      },
      images: [
        for (final i in _list(plan['images']))
          (name: _str(i['name']) ?? '', bytes: _num(i['bytes']), here: i['here'] == true),
      ],
      filesBytes: _num(_map(plan['files'])['bytes']),
      progress: Progress.fromJson(o['progress']),
    );
  }

  /// The version it left.
  final String? from;
  final String? startedAt;
  final String? finishedAt;

  /// Why it stopped: download, files, not_up, no_images, breaking.
  final String? reason;

  /// check, download, files, install, restart, wait, rollback (in order).
  final List<String> steps;

  /// When each step began (ISO).
  final Map<String, String> stepAt;

  /// The images it downloads, with their size and whether they are here already.
  final List<({String name, double bytes, bool here})> images;

  /// The system's files' archive, in bytes (0: none).
  final double filesBytes;
  final Progress? progress;

  /// The bytes the images still need from the internet.
  double get imageBytes => images.fold(0, (n, i) => n + (i.here ? 0 : i.bytes));
}

/// `OsUpdates` (`GET /api/setup/os-updates`): RedGiant OS's own updater, with 3.8.1's run.
class OsUpdates {
  const OsUpdates({
    required this.available,
    required this.running,
    this.state,
    this.installed,
    this.latest,
    this.gate,
    this.step,
    this.steps = const [],
    this.reason,
    this.progress,
    this.run,
    this.rebootRequired = false,
  });

  factory OsUpdates.fromJson(Map<String, dynamic> j) {
    final u = _map(j['update']);
    final run = OsRun.fromJson(u['run']);
    return OsUpdates(
      available: j['available'] == true,
      running: j['running'] == true,
      state: _str(u['state']),
      installed: _str(u['installed']),
      latest: _str(u['latest']),
      gate: _str(u['gate']),
      step: _str(u['step']),
      steps: run?.steps ?? const [],
      reason: run?.reason,
      progress: run?.progress,
      run: run,
      rebootRequired: _map(j['security'])['rebootRequired'] == true,
    );
  }

  final bool available;
  final bool running;

  /// latest, available, applying, error, breaking, unsigned, unreachable.
  final String? state;
  final String? installed;
  final String? latest;

  /// none, normal, mandatory, breaking.
  final String? gate;

  /// check, download, files, install, restart, wait, rollback.
  final String? step;
  final List<String> steps;
  final String? reason;
  final Progress? progress;

  /// 3.8.1: the update in progress, or the last one (null before 3.8.1's updater).
  final OsRun? run;
  final bool rebootRequired;

  /// The machine is applying an update now.
  bool get updating => running || state == 'applying';
}

/// `GET /api/devices`: a device with whether it is this one and its notifications.
class DeviceRow {
  const DeviceRow({
    required this.id,
    required this.name,
    required this.platform,
    required this.createdAt,
    this.lastUsedAt,
    this.current = false,
    this.push,
  });

  factory DeviceRow.fromJson(Map<String, dynamic> j) {
    final p = j['push'];
    return DeviceRow(
      id: _str(j['id']) ?? '',
      name: _str(j['name']) ?? '',
      platform: _str(j['platform']) ?? 'other',
      createdAt: _str(j['createdAt']) ?? '',
      lastUsedAt: _str(j['lastUsedAt']),
      current: j['current'] == true,
      push: p is Map<String, dynamic> ? p : null,
    );
  }

  final String id;
  final String name;
  final String platform;
  final String createdAt;
  final String? lastUsedAt;
  final bool current;

  /// The device's notifications as the server keeps them (`PushView`), null without.
  final Map<String, dynamic>? push;
}

/// `ModelChoice` (`GET /api/models`).
class ModelChoice {
  const ModelChoice({required this.provider, required this.model, this.name, this.effort = false});

  factory ModelChoice.fromJson(Map<String, dynamic> j) => ModelChoice(
    provider: _str(j['provider']) ?? '',
    model: _str(j['model']) ?? '',
    name: _str(j['name']),
    effort: j['effort'] == true,
  );

  final String provider;
  final String model;
  final String? name;
  final bool effort;

  String get key => '$provider/$model';
  String get label => name ?? model;
}

/// The part of `GET /api/setup` the app shows: names, languages, model, voice, access from outside.
class SetupSummary {
  const SetupSummary({
    required this.completed,
    this.language,
    this.agentLanguage,
    this.defaultModel,
    this.defaultEffort,
    this.godName,
    this.demigodName,
    this.keys = const [],
    this.claude = false,
    this.chatgpt = false,
    this.transcription,
    this.speech,
    this.remoteUrl,
    this.remoteWay,
    this.reachableUrl,
    this.lockedModel = false,
  });

  factory SetupSummary.fromJson(Map<String, dynamic> j) {
    final config = _map(j['config']);
    final dm = _map(config['defaultModel']);
    final names = _map(j['names']);
    final secrets = _map(j['secretsSet']);
    final subs = _map(config['subscriptions']);
    final tr = _map(config['transcription']);
    final speech = _map(_map(config['media'])['speech']);
    final remote = _map(config['remote']);
    final reach = _map(config['reachable']);
    return SetupSummary(
      completed: config['completed'] == true,
      language: _str(config['language']),
      agentLanguage: _str(config['agentLanguage']),
      defaultModel: dm.isEmpty ? null : '${dm['provider']}/${dm['model']}',
      defaultEffort: _str(dm['effort']),
      godName: _str(names['god']),
      demigodName: _str(names['demigod']),
      keys: [for (final k in (secrets['keys'] is List ? secrets['keys'] as List : const [])) '$k'],
      claude: subs['claude'] == true || secrets['claudeSubscription'] == true,
      chatgpt: subs['chatgpt'] == true,
      transcription: tr.isEmpty
          ? null
          : (tr['api'] == 'cloud' ? '${tr['provider']} · ${tr['model']}' : '${tr['api']}'),
      speech: speech.isEmpty
          ? null
          : '${speech['provider']} · ${speech['voice'] ?? speech['model']}',
      remoteUrl: _str(remote['url']),
      remoteWay: _str(remote['way']),
      reachableUrl: _str(reach['url']),
      lockedModel: _map(j['locked'])['defaultModel'] == true,
    );
  }

  final bool completed;
  final String? language;
  final String? agentLanguage;

  /// `provider/model`.
  final String? defaultModel;
  final String? defaultEffort;
  final String? godName;
  final String? demigodName;
  final List<String> keys;
  final bool claude;
  final bool chatgpt;
  final String? transcription;
  final String? speech;
  final String? remoteUrl;

  /// tailscale, cloudflare, caddy.
  final String? remoteWay;
  final String? reachableUrl;
  final bool lockedModel;

  /// Some way of thinking is connected (a key or a subscription).
  bool get hasBrain => keys.isNotEmpty || claude || chatgpt;
}

/// The providers with a key of one's own (`KEY_PROVIDERS`, the ones the app offers first).
const List<({String id, String name, String example})> kKeyProviders = [
  (id: 'anthropic', name: 'Anthropic (Claude)', example: 'sk-ant-api03-…'),
  (id: 'openai', name: 'OpenAI (GPT)', example: 'sk-proj-…'),
  (id: 'gemini', name: 'Google Gemini', example: 'AIza…'),
  (id: 'openrouter', name: 'OpenRouter', example: 'sk-or-v1-…'),
  (id: 'mistral', name: 'Mistral', example: ''),
  (id: 'deepseek', name: 'DeepSeek', example: 'sk-…'),
  (id: 'xai', name: 'xAI (Grok)', example: 'xai-…'),
  (id: 'groq', name: 'Groq', example: 'gsk_…'),
];
