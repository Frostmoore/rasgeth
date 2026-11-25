// G42.15: Settings › Models and subscriptions, the same routes the page calls (`setup`,
// `claudeStatus`, `claudeLogin`, `claudeCode`, `claudeLogout`, `chatgptStatus`, `chatgptLogin`,
// `chatgptLogout`, `setupSubscriptions`, `setupKey`, `removeKey`, `setupServer`, `removeServer`,
// `setupModels`, `setupEngine`, `setEnginePower`, `localModels`, `downloadModel`, `removeModel`,
// `jobs`, `cancelJob`, `speedTest`, `modelsCatalog` in packages/web/src/api.ts). Keys only go out.
import '../../api/client.dart';
import '../../api/code.dart' show JobStepView;

String _id(String id) => Uri.encodeComponent(id);
String? _s(Object? o) => o is String ? o : null;
double _n(Object? o, [double or = 0]) => o is num ? o.toDouble() : or;
Map<String, dynamic> _m(Object? o) => o is Map ? o.cast<String, dynamic>() : const {};

/// The part of `GET /api/setup` this screen reads.
class ModelsSetup {
  ModelsSetup(this.raw);

  final Map<String, dynamic> raw;

  Map<String, dynamic> get config => _m(raw['config']);
  Map<String, dynamic> get secrets => _m(raw['secretsSet']);
  Map<String, dynamic> get locked => _m(raw['locked']);
  Map<String, dynamic> get hardware => _m(raw['hardware']);
  Map<String, dynamic> get suggestion => _m(hardware['suggestion']);
  Map<String, dynamic> get names => _m(raw['names']);
  Map<String, dynamic>? get engine =>
      raw['config'] is Map && config['engine'] is Map ? _m(config['engine']) : null;

  bool get claude => _m(config['subscriptions'])['claude'] == true;
  bool get chatgpt => _m(config['subscriptions'])['chatgpt'] == true;
  List<String> get keys => [
    for (final k in secrets['keys'] is List ? secrets['keys'] as List : const []) '$k',
  ];
  bool get serverKeySet => secrets['server'] == true;
  String? get serverUrl => _s(_m(config['server'])['baseUrl']);
  bool get ack => config['subscriptionAck'] == true;
  bool lockedOf(String k) => locked[k] == true;

  /// The ways of thinking in use (the page's `waysInUse`).
  List<String> get ways => [
    if (claude) 'claude',
    if (chatgpt) 'chatgpt',
    if (keys.isNotEmpty || lockedOf('anthropic')) 'keys',
    if (engine != null) 'local',
    if (serverUrl != null || lockedOf('server')) 'server',
  ];

  ({String provider, String model, String? effort})? _spec(String k) {
    final d = _m(config[k]);
    if (d['provider'] is! String || d['model'] is! String) return null;
    return (
      provider: d['provider'] as String,
      model: d['model'] as String,
      effort: _s(d['effort']),
    );
  }

  ({String provider, String model, String? effort})? get defaultModel => _spec('defaultModel');
  ({String provider, String model, String? effort})? get backupModel => _spec('backupModel');

  // ---- the local engine ----
  String get variant => _s(engine?['variant']) ?? _s(suggestion['engine']) ?? 'cpu';
  String? get activeModel => _s(engine?['model']);
  bool get engineOff => engine?['off'] == true;
  String get os => _s(hardware['os']) ?? '';
  bool get windowsEngine => hardware['windowsEngine'] == true;
  String get kind => _s(suggestion['kind']) ?? 'cpu';
  double get vramGb => _n(suggestion['vramGb']);
  double get maxModelGb => _n(suggestion['maxModelGb']);
  double get ramGb => _n(hardware['ramGb'], 16);
  double get freeRamGb => _n(hardware['freeRamGb'], ramGb);
  List<Map<String, dynamic>> get gpus => [
    for (final g in hardware['gpus'] is List ? hardware['gpus'] as List : const [])
      if (g is Map) g.cast<String, dynamic>(),
  ];

  // ---- the improvements the engine runs with (p3.12.6) ----
  bool get engineStream => engine?['stream'] == true;
  bool get engineBigChunks => engine?['bigChunks'] == true;
  bool get engineMoePrefetch => engine?['moePrefetch'] == true;
  bool get engineNoRepack => engine?['noRepack'] == true;

  /// `none`, `draft` or `ngram`: what speculative decoding the engine runs with.
  String get engineSpeculative => _s(engine?['speculative']) ?? 'none';

  /// What the person measured here, one per model file and improvement.
  List<ImprovementTest> get improvementTests => [
    for (final t
        in config['improvementTests'] is List ? config['improvementTests'] as List : const [])
      if (t is Map) ImprovementTest(t.cast<String, dynamic>()),
  ];

  /// The speed measured for a file when it ran and was tuned.
  double? measuredTps(String file) {
    final e = engine;
    if (e == null || e['model'] != file) return null;
    for (final t in e['trials'] is List ? e['trials'] as List : const []) {
      if (t is Map && t['chosen'] == true && t['genTps'] is num)
        return (t['genTps'] as num).toDouble();
    }
    return null;
  }
}

/// A subscription's state: on, who is signed in, where its program comes from.
class SubStatus {
  SubStatus(Map<String, dynamic> j)
    : on = j['on'] == true,
      email = _s(_m(j['account'])['email']),
      plan = _s(_m(j['account'])['plan']),
      loggedIn = j['account'] is Map && (_m(j['account'])['loggedIn'] ?? true) == true,
      program = j.containsKey('program') ? (_s(j['program']) ?? 'none') : null,
      sharedLogin = j['sharedLogin'] == true;

  final bool on;
  final String? email;
  final String? plan;
  final bool loggedIn;

  /// bundled | downloaded | system | none (not here yet); null when the server does not say.
  final String? program;
  final bool sharedLogin;

  bool get signedIn => on && loggedIn && (email != null || plan != null);
}

/// A local model file of the suggestions, as the server chose it for this computer.
class GgufChoice {
  GgufChoice(Map<String, dynamic> j)
    : file = '${j['file'] ?? ''}',
      sizeGb = _n(j['sizeGb']),
      quant = _s(j['quant']),
      quality = _s(j['quality']) ?? 'good';

  final String file;
  final double sizeGb;
  final String? quant;
  final String quality;
}

/// The ids of the four improvements, in the order the server sends them (`IMPROVEMENT_IDS`).
const improvementIds = ['prefetch', 'bigChunks', 'speculative', 'noRepack'];

/// What can be turned on for a model here, with the reason when not (`Improvement`).
class Improvement {
  Improvement(Map<String, dynamic> j)
    : id = '${j['id'] ?? ''}',
      available = j['available'] == true,
      reason = _s(j['reason']),
      gpu = _s(j['gpu']),
      draft = j['draft'] == true;

  final String id;
  final bool available;

  /// needNvidia | needGpu | needMoe | needDeepField | missingEngine.
  final String? reason;

  /// The best card with its own memory (only with `needNvidia`).
  final String? gpu;
  final bool draft;
}

/// Tokens a second before and after.
class SpeedPair {
  SpeedPair(Map<String, dynamic> j) : before = _n(j['before']), after = _n(j['after']);

  final double before;
  final double after;
}

/// What we measured ourselves for a model (`TestedResult`).
class TestedResult {
  TestedResult(Map<String, dynamic> j)
    : improvement = '${j['improvement'] ?? ''}',
      hardware = '${j['hardware'] ?? ''}',
      read = j['read'] is Map ? SpeedPair(_m(j['read'])) : null,
      write = j['write'] is Map ? SpeedPair(_m(j['write'])) : null;

  final String improvement;
  final String hardware;
  final SpeedPair? read;
  final SpeedPair? write;
}

/// What the person measured on this computer (`config.improvementTests`).
class ImprovementTest {
  ImprovementTest(Map<String, dynamic> j)
    : model = '${j['model'] ?? ''}',
      improvement = '${j['improvement'] ?? ''}',
      read = SpeedPair(_m(j['read'])),
      write = SpeedPair(_m(j['write']));

  final String model;
  final String improvement;
  final SpeedPair read;
  final SpeedPair write;
}

/// A suggested local model (`LocalModelChoice`).
class LocalChoice {
  LocalChoice(Map<String, dynamic> j)
    : id = '${j['id'] ?? ''}',
      name = '${j['name'] ?? ''}',
      repo = '${j['repo'] ?? ''}',
      totalB = _n(j['totalB']),
      activeB = _n(j['activeB']),
      scores = {for (final e in _m(j['scores']).entries) e.key: _n(e.value).toInt()},
      file = j['file'] is Map ? GgufChoice(_m(j['file'])) : null,
      smallestGb = j['smallestGb'] is num ? (j['smallestGb'] as num).toDouble() : null,
      unavailable = j['unavailable'] == true,
      beyondMemory = j['beyondMemory'] == true,
      draftFile = j['draftFile'] is Map ? GgufChoice(_m(j['draftFile'])) : null,
      draftRepo = _s(_m(j['draft'])['repo']),
      improvements = [
        for (final i in j['improvements'] is List ? j['improvements'] as List : const [])
          if (i is Map) Improvement(i.cast<String, dynamic>()),
      ],
      tested = [
        for (final i in j['tested'] is List ? j['tested'] as List : const [])
          if (i is Map) TestedResult(i.cast<String, dynamic>()),
      ];

  final String id;
  final String name;
  final String repo;
  final double totalB;
  final double activeB;
  final Map<String, int> scores;
  final GgufChoice? file;
  final double? smallestGb;
  final bool unavailable;
  final bool beyondMemory;

  /// The small model for speculative decoding, when the family has one, and its repository.
  final GgufChoice? draftFile;
  final String? draftRepo;

  /// Empty with an older server (then only No Repack and Speculative Decoding stay on offer).
  final List<Improvement> improvements;
  final List<TestedResult> tested;

  Improvement? improvement(String id) => improvements.where((i) => i.id == id).firstOrNull;
}

/// A file of the models folder: ready, or a download paused halfway.
class LocalFile {
  LocalFile(Map<String, dynamic> j)
    : file = '${j['file'] ?? ''}',
      bytes = _n(j['bytes']).toInt(),
      partial = j['partial'] == true;

  final String file;
  final int bytes;
  final bool partial;
}

/// A job of the server with its words (`vars`): downloads, the engine, the speed test.
class LmJob {
  LmJob(Map<String, dynamic> j)
    : id = '${j['id'] ?? ''}',
      kind = '${j['kind'] ?? ''}',
      state = _s(j['state']) ?? 'running',
      vars = {for (final e in _m(j['vars']).entries) e.key: '${e.value}'},
      steps = [
        for (final s in j['steps'] is List ? j['steps'] as List : const [])
          if (s is Map) JobStepView.fromJson(s.cast<String, dynamic>()),
      ],
      errorCode = _s(_m(j['error'])['code']),
      errorMessage = _s(_m(j['error'])['message']);

  final String id;
  final String kind;
  final String state;
  final Map<String, String> vars;
  final List<JobStepView> steps;
  final String? errorCode;
  final String? errorMessage;
}

/// The name a repository's file gets in the models folder (as the server names it).
String targetName(String file) => file.split('/').last.replaceAll(RegExp(r'[^\w.-]+'), '_');

extension ModelsApi on RedGiantClient {
  Future<ModelsSetup> modelsSetup() async => ModelsSetup(await setupState());

  Future<SubStatus> claudeSub() async => SubStatus(await claudeStatus());
  Future<SubStatus> chatgptSub() async => SubStatus(await chatgptStatus());

  /// `POST /api/subscriptions/claude/logout`.
  Future<void> claudeLogout() => callJson('POST', '/api/subscriptions/claude/logout', const {});

  /// `POST /api/subscriptions/chatgpt/logout`.
  Future<void> chatgptLogout() => callJson('POST', '/api/subscriptions/chatgpt/logout', const {});

  /// `DELETE /api/setup/keys/:id`.
  Future<void> removeKey(String id) => callJson('DELETE', '/api/setup/keys/${_id(id)}');

  /// `PUT /api/setup/server`: the person's own server, tried; its models.
  Future<List<String>> setupServer(String baseUrl, {String? key}) async {
    final r = objectOf(
      await callJson('PUT', '/api/setup/server', {'baseUrl': baseUrl, 'key': ?key}),
    );
    return [for (final m in r['models'] is List ? r['models'] as List : const []) '$m'];
  }

  /// `DELETE /api/setup/server`.
  Future<void> removeServer() => callJson('DELETE', '/api/setup/server');

  /// `PUT /api/setup/models`.
  Future<void> setupModels(Map<String, Object?> b) => callJson('PUT', '/api/setup/models', b);

  /// `GET /api/setup/local-models?variant=…`: the suggestions and the folder's files.
  Future<({List<LocalChoice> models, List<LocalFile> files})> localModels(
    String variant, {
    bool stream = false,
  }) async {
    final j = objectOf(
      await getJson('/api/setup/local-models', {'variant': variant, if (stream) 'stream': '1'}),
    );
    return (
      models: [
        for (final m in j['models'] is List ? j['models'] as List : const [])
          if (m is Map) LocalChoice(m.cast<String, dynamic>()),
      ],
      files: [
        for (final f in j['files'] is List ? j['files'] as List : const [])
          if (f is Map) LocalFile(f.cast<String, dynamic>()),
      ],
    );
  }

  /// `POST /api/setup/local-models/download`: a job; cancelling it pauses, again goes on.
  Future<LmJob> downloadModel(String repo, String file, String variant) async => LmJob(
    objectOf(
      await callJson('POST', '/api/setup/local-models/download', {
        'repo': repo,
        'file': file,
        'variant': variant,
      }),
    ),
  );

  /// `DELETE /api/setup/local-models/:file?variant=…`.
  Future<void> removeModel(String file, String variant) =>
      callJson('DELETE', '/api/setup/local-models/${_id(file)}?variant=${_id(variant)}');

  /// `GET /api/jobs`.
  Future<List<LmJob>> lmJobs() async => [
    for (final j in arrayOf(await getJson('/api/jobs'))) LmJob(j),
  ];

  /// `POST /api/jobs/:id/cancel`.
  Future<void> cancelLmJob(String id) => callJson('POST', '/api/jobs/${_id(id)}/cancel', const {});

  /// `PUT /api/setup/engine`: the local engine with this model (a job), or stopped (null).
  Future<void> setupEngine(Map<String, Object?>? engine) =>
      callJson('PUT', '/api/setup/engine', {'engine': engine});

  /// `PUT /api/setup/engine/power`: the model in use on or off, kept.
  Future<void> setEnginePower(bool on) => callJson('PUT', '/api/setup/engine/power', {'on': on});

  /// `POST /api/setup/engine/speed-test`: what speculative decoding gains here (a job).
  Future<LmJob> speedTest(Map<String, Object?> engine, List<String> modes) async => LmJob(
    objectOf(
      await callJson('POST', '/api/setup/engine/speed-test', {'engine': engine, 'modes': modes}),
    ),
  );

  /// `POST /api/setup/engine/improvement-test`: what one improvement gains here (a job).
  Future<LmJob> improvementTest(Map<String, Object?> engine, String improvement) async => LmJob(
    objectOf(
      await callJson('POST', '/api/setup/engine/improvement-test', {
        'engine': engine,
        'improvement': improvement,
      }),
    ),
  );

  /// `GET /api/jobs/:id`.
  Future<LmJob> lmJob(String id) async => LmJob(objectOf(await getJson('/api/jobs/${_id(id)}')));
}

/// What the card's improvements switch on for one start (p3.12.6): the activation's body.
class EngineChoices {
  const EngineChoices({
    this.bigChunks = false,
    this.prefetch = false,
    this.noRepack = false,
    this.speculative = 'none',
  });

  final bool bigChunks;
  final bool prefetch;
  final bool noRepack;

  /// none | draft | ngram.
  final String speculative;

  EngineChoices copy({bool? bigChunks, bool? prefetch, bool? noRepack, String? speculative}) =>
      EngineChoices(
        bigChunks: bigChunks ?? this.bigChunks,
        prefetch: prefetch ?? this.prefetch,
        noRepack: noRepack ?? this.noRepack,
        speculative: speculative ?? this.speculative,
      );

  /// The choices the engine runs with now.
  factory EngineChoices.running(ModelsSetup s) => EngineChoices(
    bigChunks: s.engineBigChunks,
    prefetch: s.engineMoePrefetch,
    noRepack: s.engineNoRepack,
    speculative: s.engineSpeculative,
  );

  /// The body of `PUT /api/setup/engine` (and of the improvement test): only what is on; Big
  /// Chunks and Prefetch only with Deep Field (`stream`); the small model by its file [draftModel].
  Map<String, Object?> body(
    String variant,
    String model, {
    bool stream = false,
    String? draftModel,
  }) => {
    'variant': variant,
    'model': model,
    if (stream) 'stream': true,
    if (stream && bigChunks) 'bigChunks': true,
    if (stream && prefetch) 'moePrefetch': true,
    if (noRepack) 'noRepack': true,
    if (speculative == 'ngram') 'speculative': 'ngram',
    if (speculative == 'draft' && draftModel != null) ...{
      'speculative': 'draft',
      'draftModel': draftModel,
    },
  };

  /// Whether it is what the engine runs with now (so the start button is not needed).
  bool sameAs(ModelsSetup s, {required bool stream}) =>
      (stream && bigChunks) == s.engineBigChunks &&
      (stream && prefetch) == s.engineMoePrefetch &&
      noRepack == s.engineNoRepack &&
      speculative == s.engineSpeculative;
}
