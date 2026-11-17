// A fake RedGiant on localhost, answering like `device-routes.ts` and `app.ts` do for the routes
// the app uses. Real HTTP, so the client is tested end to end.
import 'dart:convert';
import 'dart:io';

import 'helpers.dart';

class FakeRedGiant {
  FakeRedGiant._(this._server);

  final HttpServer _server;
  String password = 'secret';
  bool codeOn = false;
  int appProtocol = 1;
  int wrongTries = 0;
  final tokens = <String>{};
  final requests = <String>[];

  /// What the live socket received, and the sockets open.
  final received = <Map<String, dynamic>>[];
  final sockets = <WebSocket>[];

  /// As ws.ts and core.follow: who follows which conversation (a socket's follows end with it),
  /// and each conversation's log (seq grows over the whole log, as the event store's).
  final follows = <WebSocket, Set<String>>{};
  final logs = <String, List<Map<String, dynamic>>>{};
  int _seq = 1;

  /// Links that look open and are dead (a phone back from the background, a computer back from
  /// sleep): nothing answered on them, nothing sent. New connections work.
  final _dead = <WebSocket>{};
  void deaden() => _dead.addAll(sockets);

  /// A message written elsewhere (another device): stored, to every follower, then its answer.
  void say(String sid, String text) => _turn(sid, text);

  /// The followers of [sid] (the socket that wrote only if it follows too, as the real server).
  Iterable<WebSocket> followersOf(String sid) => [
    for (final e in follows.entries)
      if (e.value.contains(sid)) e.key,
  ];

  List<Map<String, dynamic>> _logOf(String sid) =>
      logs.putIfAbsent(sid, () => [_event(1, 'session.started', {}, sid: sid)]);

  /// A stored event: to every follower of its conversation.
  void _store(String sid, String type, Map<String, dynamic> payload) {
    final e = _event(++_seq, type, payload, sid: sid);
    _logOf(sid).add(e);
    _toFollowers(sid, {'type': 'event', 'sessionId': sid, 'event': e});
  }

  void _toFollowers(String sid, Map<String, dynamic> m) {
    for (final ws in followersOf(sid)) {
      if (!_dead.contains(ws)) ws.add(jsonEncode(m));
    }
  }

  /// `core.onOwnerActivity`: to every connection of the owner, followed or not.
  void _toAll(Map<String, dynamic> m) {
    for (final ws in sockets) {
      if (!_dead.contains(ws)) ws.add(jsonEncode(m));
    }
  }

  /// A turn of the scripted agent: the person's message, the streamed answer, the end.
  void _turn(String sid, String text) {
    _store(sid, 'message.user', {'text': text});
    _toAll({'type': 'session.activity', 'sessionId': sid, 'state': 'running'});
    _toFollowers(sid, {'type': 'session.state', 'sessionId': sid, 'state': 'running'});
    // As a local engine reports it (core.ts `live`: `prefill_progress` ⇒ `prefill`).
    _toFollowers(sid, {
      'type': 'prefill',
      'sessionId': sid,
      'total': 18400,
      'cached': 14200,
      'processed': 18400,
      'ms': 3000,
    });
    _toFollowers(sid, {
      'type': 'delta',
      'sessionId': sid,
      'kind': 'thinking',
      'text': 'Let me see',
    });
    _toFollowers(sid, {'type': 'delta', 'sessionId': sid, 'kind': 'text', 'text': 'Hello'});
    _store(sid, 'message.assistant', {
      'parts': [
        {'type': 'thinking', 'text': 'Let me see'},
        {'type': 'text', 'text': 'Hello **there**'},
      ],
      'stopReason': 'end_turn',
    });
    _toFollowers(sid, {
      'type': 'session.state',
      'sessionId': sid,
      'state': 'idle',
      'stopReason': 'end_turn',
    });
    _toAll({'type': 'session.activity', 'sessionId': sid, 'state': 'idle'});
  }

  final sessions = <Map<String, dynamic>>[
    {
      'id': 's1',
      'agentId': 'a0',
      'projectId': null,
      'createdAt': '2026-11-14T09:00:00.000Z',
      'lastAt': '2026-11-14T09:05:00.000Z',
      'title': 'Ieri',
      'archived': false,
      'running': false,
    },
  ];
  final permissions = <Map<String, dynamic>>[
    {
      'requestId': 'r1',
      'agentId': 'a0',
      'agentName': 'God',
      'projectId': null,
      'tool': 'run_command',
      'input': {'command': 'npm install'},
      'reasons': ['installs packages'],
      'danger': <String>[],
      'createdAt': '2026-11-15T10:00:00.000Z',
    },
    {
      'requestId': 'r2',
      'agentId': 'a0',
      'agentName': 'God',
      'projectId': null,
      'tool': 'run_command',
      'input': {'command': 'rm -rf /'},
      'reasons': ['deletes everything'],
      'danger': ['critical-delete'],
      'critical': [
        {'id': 'critical-delete', 'action': 'delete-disk', 'target': '/'},
      ],
      'createdAt': '2026-11-15T10:01:00.000Z',
    },
  ];
  final answered = <String, String>{};

  /// G42.1: questions waiting (`QuestionRequestInfo`), sent after `welcome` as ws.ts does; the
  /// answers given (`question.answer`), the `permission.resolve` messages as they came.
  final questions = <Map<String, dynamic>>[];
  final questionAnswers = <String, List<dynamic>>{};
  final resolves = <Map<String, dynamic>>[];

  /// Conversations whose agent works: a message sent there waits in line (core's queue, by its
  /// `clientId`) until [release]; `session.unqueue` takes it back.
  final busy = <String>{};
  final queued = <String, List<Map<String, dynamic>>>{};
  final unqueued = <String>[];

  /// The forks made (`POST /api/sessions/:id/fork`) and the summaries undone.
  final forks = <Map<String, dynamic>>[];
  final undone = <String>[];

  /// Events written as the server would have stored them, to every follower.
  void store(String sid, String type, Map<String, dynamic> payload) => _store(sid, type, payload);

  /// A question asked of the person (`core.person.ask`): stored, then to every connection.
  void ask(Map<String, dynamic> q) {
    questions.add(q);
    _store(q['sessionId'] as String, 'question.asked', {
      'requestId': q['requestId'],
      'questions': q['questions'],
      'plan': ?q['plan'],
    });
    _toAll({'type': 'question.request', 'request': q});
  }

  /// A permission asked of the person while the app is connected.
  void request(Map<String, dynamic> p) {
    permissions.add(p);
    _toAll({'type': 'permission.request', 'request': p});
  }

  /// The agent of [sid] works: [turnStart] and messages wait.
  void hold(String sid) {
    busy.add(sid);
    _toAll({'type': 'session.activity', 'sessionId': sid, 'state': 'running'});
    _toFollowers(sid, {'type': 'session.state', 'sessionId': sid, 'state': 'running'});
  }

  /// The turn ends: the messages in line are read (stored) in order.
  void release(String sid) {
    busy.remove(sid);
    for (final m in queued.remove(sid) ?? const <Map<String, dynamic>>[]) {
      _store(sid, 'message.user', {'text': m['text']});
    }
    _toFollowers(sid, {'type': 'session.state', 'sessionId': sid, 'state': 'idle'});
    _toAll({'type': 'session.activity', 'sessionId': sid, 'state': 'idle'});
  }

  // 3.8.1: what the app changed, for the tests to look at.
  final patches = <Map<String, dynamic>>[];
  final agentOverrides = <String, Map<String, dynamic>>{};
  Map<String, dynamic>? chatModel;
  final created = <Map<String, dynamic>>[];
  final newAgents = <Map<String, dynamic>>[];
  final toolChoices = <String, Map<String, String>>{};
  final mascotChanges = <String>[];

  // G38.7: Settings › Agents.
  final stops = <String>[];
  final notes = <String, String>{};
  final budgetPuts = <Map<String, dynamic>>[];
  final kbChoices = <String, Map<String, String>>{};
  final agentToolState = <String, Map<String, String>>{};
  Map<String, dynamic> editorSettings = {'agents': {}, 'files': {}, 'reexport': {}};
  static const _essential = {'read_file', 'bash', 'ask_user'};

  /// An agent's record, the Chat's included (the real registry has it).
  Map<String, dynamic>? _agentRecord(String id) {
    if (id == 'chat') {
      return {
        ...agents.first,
        'id': 'chat',
        'kind': 'assistant',
        'name': 'Chat',
        'parentId': 'a0',
        ...?agentOverrides['chat'],
      };
    }
    return agents.where((a) => a['id'] == id).firstOrNull;
  }

  /// The real `PATCH /api/agents/:id`'s refusals (its zod schema, then its rules).
  String? _patchRefused(Map<String, dynamic> a, Map<String, dynamic> b) {
    final name = b['name'];
    if (name != null && (name is! String || name.trim().isEmpty || name.trim().length > 60)) {
      return 'name: String must contain at least 1 character(s)';
    }
    final role = b['role'];
    if (role != null && (role is! String || role.isEmpty)) {
      return 'role: String must contain at least 1 character(s)';
    }
    final mode = b['mode'];
    if (mode != null && !const ['manual', 'auto', 'plan', 'readonly'].contains(mode)) {
      return 'mode: Invalid enum value';
    }
    final comp = b['compaction'];
    if (comp is Map) {
      final at = comp['at'];
      final keep = comp['keep'];
      if (at != null && (at is! num || at < .3 || at > .95)) {
        return 'compaction.at: Number must be between 0.3 and 0.95';
      }
      if (keep != null && (keep is! num || keep < 0 || keep > .5)) {
        return 'compaction.keep: Number must be between 0 and 0.5';
      }
    }
    final projects = b['projects'];
    if (projects is List && projects.isNotEmpty) {
      if (a['kind'] != 'agent' && a['kind'] != 'assistant') {
        return 'Only agents and personal agents can be assigned to projects';
      }
      for (final p in projects) {
        if (p != 'demo' && !madeProjects.any((m) => m['id'] == p)) return 'No project "$p"';
      }
    }
    return null;
  }

  final asides = <String>[];
  final rooms = <Map<String, dynamic>>[];
  final sent = <Map<String, dynamic>>[];

  /// 3.8.7: a turn step by step, in the real server's order (core.ts: `session.state` running once,
  /// `prefill` as the engine reads, `delta` thinking then text, the stored `message.assistant`,
  /// `session.state` idle), to every follower of [sid].
  void turnStart(String sid) {
    _toAll({'type': 'session.activity', 'sessionId': sid, 'state': 'running'});
    _toFollowers(sid, {'type': 'session.state', 'sessionId': sid, 'state': 'running'});
  }

  void turnPrefill(
    String sid, {
    required int total,
    required int cached,
    required int processed,
    required int ms,
  }) => _toFollowers(sid, {
    'type': 'prefill',
    'sessionId': sid,
    'total': total,
    'cached': cached,
    'processed': processed,
    'ms': ms,
  });

  void turnDelta(String sid, String kind, String text) =>
      _toFollowers(sid, {'type': 'delta', 'sessionId': sid, 'kind': kind, 'text': text});

  void turnCompacting(String sid, bool busy) =>
      _toFollowers(sid, {'type': 'session.compacting', 'sessionId': sid, 'busy': busy});

  /// A tool's call and result inside the turn: the model's message with the call, then its result
  /// (the next model call starts there).
  void turnTool(
    String sid, {
    required String name,
    required Map<String, dynamic> input,
    required String output,
    String thinking = '',
    String text = '',
  }) {
    final id = 'call_${_seq + 1}';
    _store(sid, 'message.assistant', {
      'parts': [
        if (thinking.isNotEmpty) {'type': 'thinking', 'text': thinking},
        if (text.isNotEmpty) {'type': 'text', 'text': text},
        {'type': 'tool_call', 'callId': id, 'name': name, 'input': input},
      ],
      'stopReason': 'tool_use',
    });
    _store(sid, 'tool.call', {'callId': id, 'tool': name, 'input': input});
    _store(sid, 'tool.result', {'callId': id, 'tool': name, 'output': output, 'ok': true});
  }

  /// The person's message, stored (as `session.send` does before the turn starts).
  void userMessage(String sid, String text) => _store(sid, 'message.user', {'text': text});

  void turnEnd(
    String sid, {
    String thinking = '',
    required String text,
    Map<String, dynamic>? metrics,
  }) {
    _store(sid, 'message.assistant', {
      'parts': [
        if (thinking.isNotEmpty) {'type': 'thinking', 'text': thinking},
        {'type': 'text', 'text': text},
      ],
      'stopReason': 'end_turn',
      'metrics': ?metrics,
    });
    _toFollowers(sid, {
      'type': 'session.state',
      'sessionId': sid,
      'state': 'idle',
      'stopReason': 'end_turn',
    });
    _toAll({'type': 'session.activity', 'sessionId': sid, 'state': 'idle'});
  }

  /// 3.8.5: an answer streaming in, piece by piece, on every open live socket (the stream
  /// cursor's tests), and its end.
  void streamPiece(String sid, String text) {
    for (final ws in sockets) {
      ws.add(jsonEncode({'type': 'session.state', 'sessionId': sid, 'state': 'running'}));
      ws.add(jsonEncode({'type': 'delta', 'sessionId': sid, 'kind': 'text', 'text': text}));
    }
  }

  void streamEnd(String sid, String text, {int seq = 3}) {
    for (final ws in sockets) {
      ws.add(
        jsonEncode({
          'type': 'event',
          'sessionId': sid,
          'event': _event(seq, 'message.assistant', {
            'parts': [
              {'type': 'text', 'text': text},
            ],
            'stopReason': 'end_turn',
          }),
        }),
      );
      ws.add(
        jsonEncode({
          'type': 'session.state',
          'sessionId': sid,
          'state': 'idle',
          'stopReason': 'end_turn',
        }),
      );
    }
  }

  /// `GET /api/budgets` and `GET /api/limits` (the conversations' header bars, 3.9.0): empty
  /// unless a test fills them.
  List<Map<String, dynamic>> budgets = [];
  List<Map<String, dynamic>> planLimits = [];
  final previews = <String>[];
  final prompts = <String, String>{};
  final promptPuts = <Map<String, dynamic>>[];
  final refines = <Map<String, dynamic>>[];
  String? refineFails;

  // The settings of this RedGiant (G40.8).
  String machine = 'RedGiant di casa';
  Map<String, dynamic> update = {
    'install': 'os',
    'installed': '3.8.0',
    'latest': '3.8.1',
    'checkedAt': '2026-11-15T09:00:00.000Z',
    'state': 'available',
    'gate': 'normal',
    'signed': true,
    'note': {
      'it': 'Aggiornamenti spiegati passo per passo.',
      'en': 'Updates explained step by step.',
    },
    'downloadUrl': null,
    'command': null,
    'backupDir': null,
    'canUpdateHere': true,
    'canUninstall': false,
  };
  Map<String, dynamic>? osUpdates;
  int updateActs = 0;

  /// The version hello and the live socket say (changes when an update ends).
  String version = '3.8.0';

  /// RedGiant restarting: every request and socket is cut off without an answer.
  bool down = false;

  /// What `POST /api/update/act` does (a test's script of the update); null: just counted.
  Map<String, dynamic>? Function()? onUpdateAct;

  /// Stops answering (the restart of an update): open sockets are cut too.
  Future<void> goDown() async {
    down = true;
    for (final ws in [...sockets]) {
      await ws.close(1001, 'restarting');
    }
    sockets.clear();
  }

  final devices = <Map<String, dynamic>>[
    {
      'id': 'd1',
      'name': 'RGCompanion (Linux)',
      'platform': 'linux',
      'createdAt': '2026-11-15T10:00:00.000Z',
      'lastUsedAt': '2026-11-15T11:00:00.000Z',
      'current': true,
      'push': {
        'kind': 'webpush',
        'registeredAt': '2026-11-15T10:00:00.000Z',
        'target': 'ntfy.sh',
        'lastSentAt': null,
        'lastError': null,
      },
    },
    {
      'id': 'd2',
      'name': 'Telefono di Mario',
      'platform': 'android',
      'createdAt': '2026-11-14T10:00:00.000Z',
      'lastUsedAt': '2026-11-14T20:00:00.000Z',
      'push': null,
    },
  ];
  final pushTests = <String>[];

  // G40.11: the advanced interface.
  bool archived = false;

  /// The control room's «new» tiles (3.9.0): without the demo project, without any agent but
  /// God and Demi-God, the projects made with `POST /api/projects` (and their bodies), and a
  /// server where git is missing (the new project has no repository).
  bool noProjects = false;
  bool onlyLeaders = false;
  bool gitMissing = false;
  final madeProjects = <Map<String, dynamic>>[];
  final projectPosts = <Map<String, dynamic>>[];
  final hunks = <Map<String, dynamic>>[];
  final commits = <String>[];
  int pushes = 0;
  final jobs = <String, String>{};
  final termHellos = <Map<String, dynamic>>[];
  final termInput = <String>[];
  String patch =
      'diff --git a/src/prices.ts b/src/prices.ts\n'
      'index 1111111..2222222 100644\n'
      '--- a/src/prices.ts\n'
      '+++ b/src/prices.ts\n'
      '@@ -12,3 +12,4 @@ export function prices()\n'
      '   const list = useList();\n'
      '-  const year = 2025;\n'
      '+  const year = 2026;\n'
      '+  const vat = list.vat ?? 22;\n'
      '   return list;\n'
      'diff --git a/README.md b/README.md\n'
      '--- a/README.md\n'
      '+++ b/README.md\n'
      '@@ -1 +1 @@\n'
      '-# Demo\n'
      '+# Demo shop\n';

  // G40.10: notifications, voice and the files the composer writes.
  String? vapidPublicKey = 'BPvapid-public-key';
  final pushRegistrations = <String, Map<String, dynamic>>{};
  final pushDeletes = <String>[];
  final transcribed = <({String mime, String lang, int bytes})>[];
  String transcription = 'che ore sono a Roma';
  Map<String, dynamic>? transcribeError;
  final speeches = <Map<String, dynamic>>[];
  Map<String, dynamic>? speechError;
  final written = <Map<String, dynamic>>[];
  Map<String, dynamic> setup = {
    'config': {
      'completed': true,
      'language': 'it',
      'defaultModel': {'provider': 'anthropic', 'model': 'claude-sonnet-5', 'effort': 'medium'},
      'transcription': {'api': 'local', 'url': ''},
      'remote': {'way': 'tailscale', 'url': 'https://casa.tail1234.ts.net'},
    },
    'secretsSet': {
      'keys': ['anthropic'],
    },
    'locked': {},
    'names': {'god': 'God', 'demigod': 'Demi-God'},
  };
  // G40.14 and G40.16: the saved passages, the bodies the app sent, the product pictures.
  final saved = <Map<String, dynamic>>[];
  final savedPosts = <Map<String, dynamic>>[];
  final savedPatches = <Map<String, dynamic>>[];
  final savedDeletes = <String>[];
  final savedExports = <Map<String, String>>[];

  /// The most items a page gives, whatever the app asks.
  int savedPage = 200;
  final productImages = <String, List<int>>{};
  int _savedSeq = 0;
  int _sessionSeq = 1;
  late final mascots = loadMascots();

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<FakeRedGiant> start() async {
    final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final fake = FakeRedGiant._(s);
    s.listen(fake._handle);
    return fake;
  }

  Future<void> close() => _server.close(force: true);

  String? _bearer(HttpRequest r) {
    final h = r.headers.value('authorization');
    return h != null && h.startsWith('Bearer ') ? h.substring(7) : null;
  }

  Future<void> _json(HttpRequest r, int status, Object body) async {
    r.response.statusCode = status;
    r.response.headers.contentType = ContentType.json;
    r.response.write(jsonEncode(body));
    await r.response.close();
  }

  List<Map<String, dynamic>> get agents => [
    for (final (i, m) in mascots.indexed)
      if (!onlyLeaders || m.kind == 'god' || m.kind == 'demigod')
        {
          'id': 'a$i',
          'kind': m.kind,
          'parentId': i == 0 ? null : 'a0',
          'projectId': null,
          'persistent': true,
          'name': m.seed,
          'mascotSeed': m.seed,
          'mascot': m.raw,
          'status': 'active',
          'futureField': {'ignored': true},
          ...?agentOverrides['a$i'],
        },
    ...created,
  ];

  Future<void> _handle(HttpRequest r) async {
    if (down) {
      // As a server that is not there: the connection drops without an answer.
      final sock = await r.response.detachSocket(writeHeaders: false);
      sock.destroy();
      return;
    }
    requests.add('${r.method} ${r.uri}');
    final token = _bearer(r);
    final path = r.uri.path;
    if (r.method == 'GET' && path == '/api/app/hello') {
      return _json(r, 200, {
        'app': 'redgiant',
        'version': version,
        'appProtocol': appProtocol,
        'protocolVersion': 12,
        'machine': machine,
        'firstStartCompleted': true,
        'access': {'password': true, 'code': codeOn, 'token': true},
        'signedIn': tokens.contains(token),
        if (tokens.contains(token)) 'device': {'id': 'd1', 'name': 'RGCompanion (Linux)'},
      });
    }
    if (r.method == 'POST' && path == '/api/app/pair') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      if (b['password'] is! String || b['name'] is! String || b['platform'] is! String) {
        return _json(r, 400, {
          'error': 'A password, a name and a platform are needed',
          'code': 'bad',
        });
      }
      if (wrongTries >= 5) return _json(r, 429, {'error': 'Too many', 'code': 'too_many'});
      if (b['password'] != password) {
        wrongTries++;
        return _json(r, 401, {'error': 'Wrong password', 'code': 'wrong'});
      }
      if (codeOn && b['code'] == null) {
        return _json(r, 401, {'error': 'The code', 'code': 'code_needed'});
      }
      final t = 'rgd_${tokens.length + 1}';
      tokens.add(t);
      return _json(r, 200, {
        'token': t,
        'device': {
          'id': 'd${tokens.length}',
          'name': b['name'],
          'platform': b['platform'],
          'createdAt': '2026-11-15T10:00:00.000Z',
          'lastUsedAt': null,
          'lastAddress': null,
        },
      });
    }
    if (path == '/ws' && WebSocketTransformer.isUpgradeRequest(r)) return _socket(r);
    if (path == '/term' && WebSocketTransformer.isUpgradeRequest(r)) return _term(r);
    if (!tokens.contains(token)) return _json(r, 401, {'error': 'Unauthorized'});
    if (r.method == 'GET' && path == '/api/agents') return _json(r, 200, agents);
    if (r.method == 'GET' && path == '/api/budgets') return _json(r, 200, budgets);
    if (r.method == 'GET' && path == '/api/limits') return _json(r, 200, planLimits);
    if (r.method == 'GET' && path == '/api/sessions') {
      final a = r.uri.queryParameters['agentId'];
      return _json(r, 200, [
        for (final x in sessions)
          if (a == null || x['agentId'] == a) x,
      ]);
    }
    // «Continua da qui» / «Modifica» (G36.23, app.ts `/fork`): a new conversation with the events
    // up to the message (`fromSeq` included, `beforeSeq` not), then `session.forked`.
    final fork = RegExp(r'^/api/sessions/([^/]+)/fork$').firstMatch(path);
    if (r.method == 'POST' && fork != null) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      final from = fork.group(1)!;
      final row = sessions.where((x) => x['id'] == from).firstOrNull;
      if (row == null) return _json(r, 404, {'error': 'No such session'});
      final id = 's${++_sessionSeq}';
      forks.add({'from': from, 'to': id, ...b});
      sessions.add({...row, 'id': id, 'title': '${row['title'] ?? ''} (2)', 'running': false});
      final upTo = b['fromSeq'] is num ? (b['fromSeq'] as num).toInt() : null;
      final before = b['beforeSeq'] is num ? (b['beforeSeq'] as num).toInt() : null;
      logs[id] = [
        for (final e in _logOf(from))
          if ((upTo == null || (e['seq'] as int) <= upTo) &&
              (before == null || (e['seq'] as int) < before))
            {...e, 'sessionId': id},
      ];
      _store(id, 'session.forked', {
        'fromSessionId': from,
        'fromTitle': row['title'],
        'how': upTo != null ? 'continue' : 'edit',
      });
      return _json(r, 201, {'sessionId': id});
    }
    final undo = RegExp(r'^/api/sessions/([^/]+)/compaction/undo$').firstMatch(path);
    if (r.method == 'POST' && undo != null) {
      final sid = undo.group(1)!;
      final last = _logOf(sid).reversed.where((e) => e['type'] == 'compaction').firstOrNull;
      if (last == null) return _json(r, 409, {'error': 'Nothing to undo'});
      undone.add(sid);
      _store(sid, 'compaction.undone', {'compactionSeq': last['seq']});
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'POST' && path == '/api/sessions') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      final id = 's${++_sessionSeq}';
      sessions.add({
        'id': id,
        'agentId': b['agentId'],
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'lastAt': null,
        'title': null,
        'archived': false,
        'running': false,
      });
      return _json(r, 201, {'sessionId': id});
    }
    // An agent's model and mode (PATCH), the Chat's settings, new agents, tools, mascots (3.8.1).
    final agentOne = RegExp(r'^/api/agents/([^/]+)$').firstMatch(path);
    if (r.method == 'PATCH' && agentOne != null) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      patches.add({'agent': agentOne.group(1), ...b});
      final base = _agentRecord(agentOne.group(1)!);
      if (base == null) return _json(r, 404, {'error': 'Agent not found'});
      // The real route's schema and rules (packages/server/src/app.ts, configureAgent).
      final why = _patchRefused(base, b);
      if (why != null) return _json(r, 400, {'error': why});
      if (b['name'] is String) b['name'] = (b['name'] as String).trim();
      final own = agentOverrides.putIfAbsent(agentOne.group(1)!, () => {});
      own.addAll(b);
      return _json(r, 200, {...base, ...own});
    }
    // G38.7: the rest of Settings › Agents, with the real server's rules.
    final stopOne = RegExp(r'^/api/agents/([^/]+)/stop$').firstMatch(path);
    if (r.method == 'POST' && stopOne != null) {
      final id = stopOne.group(1)!;
      if (_agentRecord(id) == null) return _json(r, 404, {'error': 'Agent not found'});
      stops.add(id);
      final under = [
        id,
        for (final a in agents)
          if (a['parentId'] == id) a['id'] as String,
      ];
      for (final x in under) {
        agentOverrides.putIfAbsent(x, () => {})['status'] = 'stopped';
      }
      return _json(r, 200, {'stopped': under});
    }
    final compactOf = RegExp(r'^/api/agents/([^/]+)/compaction-defaults$').firstMatch(path);
    if (r.method == 'GET' && compactOf != null) {
      if (_agentRecord(compactOf.group(1)!) == null) {
        return _json(r, 404, {'error': 'Agent not found'});
      }
      return _json(r, 200, {'at': .8, 'keep': .12});
    }
    if (path == '/api/notes') {
      final q = r.uri.queryParameters;
      final scope = q['scope'];
      final who = switch (scope) {
        'self' => q['agentId'] == null ? null : 'self:${q['agentId']}',
        'project' => q['projectId'] == null ? null : 'project:${q['projectId']}',
        'user' => 'user',
        _ => null,
      };
      if (who == null) return _json(r, 400, {'error': 'scope is user, self or project'});
      if (r.method == 'GET') return _json(r, 200, {'text': notes[who] ?? ''});
      final b = jsonDecode(await utf8.decodeStream(r));
      if (b is! Map || b['text'] is! String) {
        return _json(r, 400, {'error': 'text is required'});
      }
      notes[who] = b['text'] as String;
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'PUT' && path == '/api/budgets') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      final usd = b['usd'];
      if (usd != null && (usd is! num || usd <= 0)) {
        return _json(r, 400, {'error': 'usd: Number must be greater than 0'});
      }
      budgetPuts.add(b);
      budgets.removeWhere((x) => x['scope'] == b['scope'] && x['id'] == b['id']);
      budgets.add({
        'scope': b['scope'],
        'id': b['id'],
        'limit': {'usd': ?usd},
        'used': {'usd': 1.25, 'tokens': 4000},
      });
      return _json(r, 200, {'ok': true});
    }
    final kbOf = RegExp(r'^/api/knowledge/agents/([^/]+)$').firstMatch(path);
    if (kbOf != null) {
      final id = kbOf.group(1)!;
      if (r.method == 'PUT') {
        final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
        final pick = b['pick'];
        if (b['collection'] is! String || (pick != null && pick != 'on' && pick != 'off')) {
          return _json(r, 400, {'error': 'collection and pick (on, off or null)'});
        }
        final own = kbChoices.putIfAbsent(id, () => {});
        pick == null
            ? own.remove(b['collection'])
            : own[b['collection'] as String] = pick as String;
      }
      return _json(r, 200, {
        'collections': [
          for (final (cid, name, scope, byScope) in const [
            ('manuali', 'Manuali', 'global', true),
            ('contratti', 'Contratti', 'project', false),
          ])
            {
              'id': cid,
              'name': name,
              'scope': scope,
              'byScope': byScope,
              'own': kbChoices[id]?[cid],
              'on': switch (kbChoices[id]?[cid]) {
                'on' => true,
                'off' => false,
                _ => byScope,
              },
              'chunks': 12,
            },
        ],
      });
    }
    if (path == '/api/settings/editor') {
      if (r.method == 'GET') return _json(r, 200, {'settings': editorSettings});
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      editorSettings = b;
      return _json(r, 200, {'ok': true});
    }
    if (path == '/api/chat/settings') {
      if (r.method == 'GET') return _json(r, 200, {'model': ?chatModel});
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      chatModel = b['model'] as Map<String, dynamic>?;
      patches.add({'chat': true, ...b});
      return _json(r, 200, {'model': chatModel});
    }
    if (r.method == 'POST' && path == '/api/agents') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      if ((b['name'] as String? ?? '').trim().isEmpty) {
        return _json(r, 400, {'error': 'A name is needed'});
      }
      final made = {
        'id': 'agent_${created.length + 1}',
        'kind': b['kind'],
        'parentId': b['parentId'],
        'projectId': b['projectId'],
        'persistent': true,
        'name': b['name'],
        'role': b['role'],
        'model': b['model'],
        'mode': b['mode'],
        'mascotSeed': b['name'],
        'mascot': mascots[3].raw,
        'status': 'active',
      };
      created.add(made);
      newAgents.add(b);
      return _json(r, 201, made);
    }
    final promptOf = RegExp(r'^/api/agents/([^/]+)/prompt$').firstMatch(path);
    if (promptOf != null || path == '/api/chat/prompt') {
      final key = promptOf?.group(1) ?? 'chat';
      final builtIn = 'You are ${key == 'chat' ? 'Chat' : key}. Built-in instructions.';
      if (r.method == 'PUT') {
        final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
        promptPuts.add({'who': key, 'text': b['text']});
        final t = b['text'] as String?;
        if (t == null || t.trim().isEmpty || t.trim() == builtIn) {
          prompts.remove(key);
        } else {
          prompts[key] = t;
        }
      }
      final own = prompts[key];
      return _json(r, 200, {
        'text': own ?? builtIn,
        'isDefault': own == null,
        'defaultText': builtIn,
      });
    }
    if (r.method == 'POST' && path.startsWith('/api/prompts/refine')) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      refines.add({'path': path, ...b});
      if (path.endsWith('/estimate')) {
        return _json(r, 200, {
          'inputTokens': 3000,
          'outputTokens': 1200,
          'usd': 0.004,
          'model': {'provider': 'anthropic', 'model': 'claude-haiku-5'},
          'base': b['text'],
        });
      }
      if (refineFails != null) return _json(r, 400, {'error': 'x', 'code': refineFails});
      return _json(r, 200, {
        'text': '${b['text']}\nAnswer briefly.',
        'changes': 'Added: answer briefly.',
        'inputTokens': 3000,
        'outputTokens': 1300,
        'usd': null,
        'model': {'provider': 'claude-subscription', 'model': 'claude-sonnet-5'},
      });
    }
    final agentTools = RegExp(r'^/api/agents/([^/]+)/tools$').firstMatch(path);
    if (r.method == 'PUT' && agentTools != null) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      final tools = (b['tools'] as Map).cast<String, String>();
      // As `Platform.setTools`: essential tools never switch off.
      final essential = [
        for (final e in tools.entries)
          if (e.value == 'off' && _essential.contains(e.key)) e.key,
      ];
      if (essential.isNotEmpty) {
        return _json(r, 400, {
          'error': 'These tools are essential and cannot be switched off: ${essential.join(', ')}',
        });
      }
      toolChoices[agentTools.group(1)!] = tools;
      final own = agentToolState.putIfAbsent(agentTools.group(1)!, () => {});
      for (final e in tools.entries) {
        e.value == 'default' ? own.remove(e.key) : own[e.key] = e.value;
      }
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'GET' && path == '/api/tools') {
      final forAgent = r.uri.queryParameters['agentId'];
      final own = forAgent == null ? null : agentToolState[forAgent];
      return _json(r, 200, {
        'agentId': forAgent,
        'total': 1000,
        'saved': 0,
        'entries': [
          for (final (id, group, essential) in const [
            ('read_file', 'files', true),
            ('bash', 'files', true),
            ('grep', 'files', false),
            ('fetch', 'web', false),
            ('ask_user', 'people', true),
          ])
            {
              'id': id,
              'group': group,
              'essential': essential,
              'tools': [id],
              'chars': 100,
              'tokens': 30,
              'global': true,
              if (forAgent != null) 'own': essential ? null : own?[id],
              if (forAgent != null) 'on': essential || own?[id] != 'off',
            },
        ],
      });
    }
    if (r.method == 'GET' && path == '/api/mascot/preview') {
      final q = r.uri.queryParameters;
      previews.add('${q['kind']} ${q['name']} ${q['parentId']}');
      if ((q['name'] ?? '').isEmpty) return _json(r, 400, {'error': 'A name'});
      r.response.headers.contentType = ContentType('image', 'svg+xml', charset: 'utf-8');
      r.response.write(mascots[3].svg[q['theme'] ?? 'light']!['idle']);
      return r.response.close();
    }
    final mascotNew = RegExp(r'^/api/agents/([^/]+)/mascot$').firstMatch(path);
    if (r.method == 'POST' && mascotNew != null) {
      mascotChanges.add(mascotNew.group(1)!);
      final a = created.where((x) => x['id'] == mascotNew.group(1)).firstOrNull;
      if (a == null) return _json(r, 404, {'error': 'Agent not found'});
      a['mascot'] = mascots[4].raw;
      a['mascotSeed'] = '${a['name']}~abc123';
      return _json(r, 200, a);
    }
    final aside = RegExp(r'^/api/sessions/([^/]+)/aside$').firstMatch(path);
    if (r.method == 'POST' && aside != null) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      asides.add('${aside.group(1)}: ${b['question']}');
      return _json(r, 201, {
        'aside': {'id': 'as${asides.length}', 'answer': 'Meanwhile: 42'},
      });
    }
    final asideChat = RegExp(r'^/api/sessions/([^/]+)/asides/([^/]+)/chat$').firstMatch(path);
    if (r.method == 'POST' && asideChat != null) {
      asides.add('chat ${asideChat.group(2)}');
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'POST' && path == '/api/rooms') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      rooms.add(b);
      return _json(r, 201, {
        'id': 'room_1',
        'title': 'Group',
        'members': [b['from']],
        'createdAt': '2026-11-15T10:00:00.000Z',
        'lastAt': null,
        'answering': <String>[],
      });
    }
    final roomMember = RegExp(r'^/api/rooms/([^/]+)/members$').firstMatch(path);
    if (r.method == 'POST' && roomMember != null) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      rooms.add({'room': roomMember.group(1), ...b});
      return _json(r, 200, {'ok': true});
    }
    final work = RegExp(r'^/api/agents/([^/]+)/work-session$').firstMatch(path);
    if (r.method == 'POST' && work != null) {
      final id = 's${++_sessionSeq}';
      sessions.add({
        'id': id,
        'agentId': work.group(1),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'lastAt': null,
        'title': null,
        'archived': false,
        'running': false,
      });
      return _json(r, 200, {'sessionId': id});
    }
    final one = RegExp(r'^/api/sessions/([^/]+)(/messages|/interrupt)?$').firstMatch(path);
    if (one != null) {
      final row = sessions.where((x) => x['id'] == one.group(1)).firstOrNull;
      if (row == null) return _json(r, 404, {'error': 'Not found'});
      final body = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      if (r.method == 'PATCH' && one.group(2) == null) {
        row.addAll(body);
        return _json(r, 200, {'ok': true});
      }
      if (r.method == 'POST' && one.group(2) == '/messages') {
        sent.add({'sessionId': one.group(1), ...body});
        return _json(r, 202, {'ok': true});
      }
      if (r.method == 'POST' && one.group(2) == '/interrupt') {
        return _json(r, 200, {'interrupted': true});
      }
    }
    if (r.method == 'GET' && path == '/api/chat/agent') {
      return _json(r, 200, {...agents.first, 'id': 'chat', 'kind': 'assistant', 'name': 'Chat'});
    }
    if (r.method == 'GET' && path == '/api/permissions') return _json(r, 200, permissions);
    final ans = RegExp(r'^/api/app/requests/([^/]+)/answer$').firstMatch(path);
    if (r.method == 'POST' && ans != null) {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      final p = permissions.where((x) => x['requestId'] == ans.group(1)).firstOrNull;
      if (p == null) return _json(r, 404, {'error': 'Not found', 'code': 'not_found'});
      if (b['decision'] == 'allow' && (p['danger'] as List).isNotEmpty) {
        return _json(r, 403, {'error': 'Open the app', 'code': 'open_app'});
      }
      answered[ans.group(1)!] = b['decision'] as String;
      permissions.remove(p);
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'GET' && path == '/api/update/status') return _json(r, 200, update);
    if (r.method == 'POST' && path == '/api/update/look') {
      update = {...update, 'checkedAt': '2026-11-15T12:00:00.000Z'};
      return _json(r, 200, update);
    }
    if (r.method == 'POST' && path == '/api/update/act') {
      updateActs++;
      final refused = onUpdateAct?.call();
      if (refused != null) return _json(r, 400, refused);
      return _json(r, 200, {'ok': true});
    }
    if (path == '/api/setup/os-updates' || path == '/api/setup/os-updates/check') {
      final os = osUpdates;
      return os == null ? _json(r, 400, {'error': 'Not RedGiant OS'}) : _json(r, 200, os);
    }
    if (r.method == 'GET' && path == '/api/devices') return _json(r, 200, devices);
    final dev = RegExp(r'^/api/devices/([^/]+)$').firstMatch(path);
    if (r.method == 'DELETE' && dev != null) {
      devices.removeWhere((d) => d['id'] == dev.group(1));
      return _json(r, 200, {'ok': true});
    }
    final pt = RegExp(r'^/api/devices/([^/]+)/push/test$').firstMatch(path);
    if (r.method == 'POST' && pt != null) {
      pushTests.add(pt.group(1)!);
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'GET' && path == '/api/setup') return _json(r, 200, setup);
    if (r.method == 'GET' && path == '/api/app/push') {
      return _json(r, 200, {'vapidPublicKey': vapidPublicKey, 'apns': false});
    }
    final pr = RegExp(r'^/api/devices/([^/]+)/push$').firstMatch(path);
    if (pr != null && r.method == 'PUT') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      pushRegistrations[pr.group(1)!] = b;
      return _json(r, 200, {
        'kind': b['kind'],
        'registeredAt': '2026-11-16T10:00:00.000Z',
        'target': b['kind'] == 'webpush' ? Uri.parse(b['endpoint'] as String).host : 'APNs',
        'lastSentAt': null,
        'lastError': null,
      });
    }
    if (pr != null && r.method == 'DELETE') {
      pushDeletes.add(pr.group(1)!);
      if (pushRegistrations.remove(pr.group(1)) == null) {
        return _json(r, 404, {'error': 'No notifications registered'});
      }
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'POST' && path == '/api/transcribe') {
      final bytes = await r.fold<List<int>>([], (a, b) => a..addAll(b));
      transcribed.add((
        mime: r.headers.contentType?.mimeType ?? '',
        lang: r.uri.queryParameters['lang'] ?? '',
        bytes: bytes.length,
      ));
      final e = transcribeError;
      if (e != null) return _json(r, 502, e);
      return _json(r, 200, {'text': transcription});
    }
    if (r.method == 'POST' && path == '/api/voice/speech') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      speeches.add(b);
      final e = speechError;
      if (e != null) return _json(r, 400, e);
      r.response.headers.contentType = ContentType('audio', 'mpeg');
      r.response.add(List<int>.filled(64, 7));
      return r.response.close();
    }
    if (r.method == 'PUT' && path == '/api/files/content') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      written.add(b);
      return _json(r, 200, {'path': b['path'], 'modifiedAt': '2026-11-16T10:00:00.000Z'});
    }
    if (r.method == 'GET' && path == '/api/models') {
      return _json(r, 200, [
        // The same model through the subscription and the API key (G40.9b).
        {
          'provider': 'claude-subscription',
          'model': 'claude-sonnet-5',
          'effort': true,
          'name': 'Claude Sonnet 5',
        },
        {
          'provider': 'anthropic',
          'model': 'claude-sonnet-5',
          'effort': true,
          'name': 'Claude Sonnet 5',
        },
        {
          'provider': 'anthropic',
          'model': 'claude-haiku-5',
          'effort': true,
          'name': 'Claude Haiku 5',
        },
      ]);
    }
    if (r.method == 'PUT' && path == '/api/setup/models') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      (setup['config'] as Map<String, dynamic>)['defaultModel'] = b['defaultModel'];
      return _json(r, 200, {'ok': true});
    }
    if (r.method == 'PUT' && path == '/api/nodes/name') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      machine = b['name'] as String;
      return _json(r, 200, {});
    }
    if (r.method == 'GET' && path == '/api/projects') {
      return _json(r, 200, [
        if (!noProjects)
          {
            'id': 'demo',
            'name': 'Demo',
            'path': '/p',
            'createdAt': '2026-11-01T00:00:00.000Z',
            if (archived) 'archivedAt': '2026-11-16T00:00:00.000Z',
          },
        ...madeProjects,
      ]);
    }
    if (r.method == 'POST' && path == '/api/projects') {
      final b = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      projectPosts.add(b);
      final name = (b['name'] as String? ?? '').trim();
      if (name.isEmpty) return _json(r, 400, {'error': 'A name is needed'});
      final made = {
        'id': 'proj_${madeProjects.length + 1}',
        'name': name,
        'path': '/projects/$name',
        'createdAt': '2026-11-16T10:00:00.000Z',
        'git': !gitMissing,
        if (gitMissing) 'gitError': 'git is not installed',
      };
      madeProjects.add(made);
      return _json(r, 201, made);
    }
    if (r.method == 'GET' && path == '/api/projects/demo/tasks') {
      return _json(r, 200, [
        {
          'id': 'task_1',
          'title': 'Add the --json flag',
          'agentId': 'a1',
          'agentName': 'Coder Web',
          'sessionId': 's1',
          'outcome': 'open',
          'openedAt': '2026-11-15T09:00:00.000Z',
          'verifier': {'command': 'npm test', 'passed': false},
          'note': null,
        },
        {
          'id': 'task_2',
          'title': 'Prices page',
          'agentId': 'a1',
          'agentName': 'Coder Web',
          'sessionId': null,
          'outcome': 'open',
          'openedAt': '2026-11-15T10:00:00.000Z',
          'verifier': null,
          'note': null,
        },
        {
          'id': 'task_0',
          'title': 'Fix the README',
          'agentId': 'a1',
          'agentName': 'Coder Web',
          'sessionId': null,
          'outcome': 'verified',
          'openedAt': '2026-11-14T09:00:00.000Z',
        },
      ]);
    }
    if (r.method == 'GET' && path == '/api/files/content') {
      final p = r.uri.queryParameters['path'] ?? '';
      return _json(r, 200, {
        'path': p,
        'encoding': 'utf8',
        'content': '# Report\n\n<b>bold?</b> and a [link](https://example.com)',
        'size': 40,
        'modifiedAt': '2026-11-15T10:00:00.000Z',
      });
    }
    if (await _code(r, path)) return;
    if (await _saved(r, path)) return;
    final m = RegExp(r'^/api/agents/a(\d+)/mascot$').firstMatch(path);
    if (r.method == 'GET' && m != null) {
      final i = int.parse(m.group(1)!);
      if (i >= mascots.length) return _json(r, 404, {'error': 'Agent not found'});
      final fx = mascots[i];
      final q = r.uri.queryParameters;
      if (q['format'] != 'svg') return _json(r, 200, fx.raw);
      final size = int.parse(q['size'] ?? '128');
      r.response.headers.contentType = ContentType('image', 'svg+xml', charset: 'utf-8');
      r.response.write(size <= 20 ? fx.tiny : fx.svg[q['theme'] ?? 'light']![q['state'] ?? 'idle']);
      return r.response.close();
    }
    return _json(r, 404, {'error': 'Not found'});
  }

  /// The advanced interface's routes (code-routes.ts, the Explorer's), for the demo project.
  Future<bool> _code(HttpRequest r, String path) async {
    Future<Map<String, dynamic>> body() async =>
        jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
    Future<bool> json(int status, Object b) async {
      await _json(r, status, b);
      return true;
    }

    final q = r.uri.queryParameters;
    final get = r.method == 'GET';
    if (get && path == '/api/projects/demo/git') {
      return json(200, {
        'repo': true,
        'branch': 'p2.4.0',
        'upstream': 'origin/p2.4.0',
        'ahead': 2,
        'behind': 0,
        'changes': [
          {'path': 'src/prices.ts', 'status': 'M', 'staged': false},
          {'path': 'README.md', 'status': 'M', 'staged': false},
          {'path': 'notes.txt', 'status': '?', 'staged': false},
        ],
      });
    }
    if (get && path == '/api/projects/demo/git/log') {
      return json(200, [
        {
          'hash': 'abc1234ffff',
          'short': 'abc1234',
          'author': 'Coder Web',
          'date': '2026-11-15T10:00:00Z',
          'refs': 'HEAD -> p2.4.0',
          'subject': 'Prices 2026',
          'parents': ['0001111ffff'],
        },
        if (q['all'] == '1') ...[
          {
            'hash': '0001111ffff',
            'short': '0001111',
            'author': 'Tu',
            'date': '2026-11-14T10:00:00Z',
            'refs': 'origin/main, main, tag: v2.3.2',
            'subject': 'First commit',
            'parents': <String>[],
          },
        ],
      ]);
    }
    if (get && path == '/api/projects/demo/git/branches') {
      return json(200, [
        {'name': 'p2.4.0', 'current': true, 'upstream': 'origin/p2.4.0', 'ahead': 2, 'behind': 0},
        {'name': 'main', 'current': false, 'upstream': null, 'ahead': 0, 'behind': 0},
      ]);
    }
    if (get && path == '/api/projects/demo/git/diff') {
      return json(200, {
        'kind': q['commit'] != null
            ? 'commit'
            : (q['agent'] != null || q['task'] != null ? 'agent' : 'working'),
        'title': q['task'] != null ? 'Add the --json flag' : '',
        'agentId': q['task'] != null ? 'a1' : q['agent'],
        'patch': patch,
        'truncated': false,
      });
    }
    if (r.method == 'POST' && path == '/api/projects/demo/git/hunk') {
      if (archived) return json(423, {'error': 'archived', 'code': 'project_archived'});
      final b = await body();
      hunks.add(b);
      return json(200, {
        'ok': true,
        'backup': b['action'] == 'discard' ? '.trash/diffs/x.patch' : null,
      });
    }
    if (r.method == 'POST' && path == '/api/projects/demo/git/commit') {
      final b = await body();
      commits.add(b['message'] as String);
      return json(200, {'commit': 'def5678'});
    }
    if (r.method == 'POST' && path == '/api/projects/demo/git/push') {
      pushes++;
      jobs['job1'] = 'running';
      return json(202, {
        'id': 'job1',
        'kind': 'git_push',
        'state': 'running',
        'steps': [],
        'vars': {},
      });
    }
    final job = RegExp(r'^/api/jobs/([^/]+)$').firstMatch(path);
    if (get && job != null) {
      final state = jobs[job.group(1)] ?? 'done';
      return json(200, {
        'id': job.group(1),
        'state': state,
        if (state == 'failed') 'error': {'code': 'denied', 'message': 'Not pushed'},
      });
    }
    if (get && path == '/api/projects/demo/events') {
      final all = [
        {
          'seq': 3,
          'ts': '2026-11-15T09:31:05.000Z',
          'type': 'agent.blocked',
          'agentId': 'a1',
          'agentName': 'Coder Web',
          'sessionId': 's1',
          'error': true,
          'payload': {'reason': 'I need a new bank access'},
        },
        {
          'seq': 2,
          'ts': '2026-11-15T09:31:04.000Z',
          'type': 'tool.result',
          'agentId': 'a1',
          'agentName': 'Coder Web',
          'sessionId': 's1',
          'error': true,
          'payload': {'callId': 'c1', 'ok': false, 'output': 'token expired'},
        },
        {
          'seq': 1,
          'ts': '2026-11-15T09:31:02.000Z',
          'type': 'tool.call',
          'agentId': 'a1',
          'agentName': 'Coder Web',
          'sessionId': 's1',
          'error': false,
          'payload': {
            'callId': 'c1',
            'tool': 'bash',
            'input': {'command': 'npm test'},
          },
        },
      ];
      return json(200, {
        'events': [
          for (final e in all)
            if ((q['errors'] != '1' || e['error'] == true) &&
                (q['type'] == null || e['type'] == q['type']))
              e,
        ],
        'types': ['agent.blocked', 'tool.call', 'tool.result'],
        'agents': [
          {'id': 'a1', 'name': 'Coder Web'},
        ],
      });
    }
    final ev = RegExp(r'^/api/sessions/([^/]+)/events$').firstMatch(path);
    if (get && ev != null) {
      return json(200, [
        _event(1, 'tool.call', {
          'callId': 'c1',
          'tool': 'bash',
          'input': {'command': 'git status -s'},
        }),
        _event(2, 'tool.result', {'callId': 'c1', 'ok': true, 'output': ' M src/prices.ts'}),
      ]);
    }
    if (get && path == '/api/files/search') {
      return json(200, [
        {'path': 'src/prices.ts', 'line': 13, 'text': 'const year = 2026;'},
      ]);
    }
    if (get && path == '/api/files/list') {
      final dir = q['path'] ?? '.';
      return json(
        200,
        dir == 'src'
            ? [
                {
                  'name': 'prices.ts',
                  'path': 'src/prices.ts',
                  'type': 'file',
                  'size': 4200,
                  'modifiedAt': '2026-11-15T10:00:00.000Z',
                },
              ]
            : [
                {
                  'name': 'src',
                  'path': 'src',
                  'type': 'dir',
                  'size': 0,
                  'modifiedAt': '2026-11-15T10:00:00.000Z',
                },
                {
                  'name': 'README.md',
                  'path': 'README.md',
                  'type': 'file',
                  'size': 1100,
                  'modifiedAt': '2026-11-15T10:00:00.000Z',
                },
              ],
      );
    }
    return false;
  }

  /// `/term` as terminal.ts: hello, ready, then input echoed back as output.
  Future<void> _term(HttpRequest r) async {
    final ws = await WebSocketTransformer.upgrade(r);
    ws.listen((data) {
      final m = jsonDecode(data as String) as Map<String, dynamic>;
      if (m['type'] == 'hello') {
        termHellos.add(m);
        if (!tokens.contains(m['token'])) {
          ws.close(4003, 'unauthorized');
          return;
        }
        ws.add(jsonEncode({'type': 'ready', 'terminalId': 'term_1'}));
        ws.add(jsonEncode({'type': 'output', 'data': '\x1b[32mdemo\x1b[0m \$ '}));
      } else if (m['type'] == 'input') {
        termInput.add(m['data'] as String);
        ws.add(
          jsonEncode({'type': 'output', 'data': (m['data'] as String).replaceAll('\r', '\r\n')}),
        );
      }
    });
  }

  /// A saved item as `SavedItem` (protocol/saved.ts).
  Map<String, dynamic> savedItem({
    required String id,
    required String text,
    String? markdown,
    bool whole = false,
    String note = '',
    List<String> tags = const [],
    String sessionId = 's1',
    int seq = 3,
    int? start,
    int? end,
    String agentId = 'a0',
    String agentName = 'God',
    String? title = 'Ieri',
    required String createdAt,
  }) => {
    'id': id,
    'text': text,
    'markdown': markdown,
    'whole': whole,
    'note': note,
    'tags': tags,
    'source': {
      'kind': 'session',
      'sessionId': sessionId,
      'seq': seq,
      'start': ?start,
      'end': ?end,
      'agentId': agentId,
      'agentName': agentName,
      'title': title,
      'messageAt': createdAt,
    },
    'createdAt': createdAt,
    'updatedAt': createdAt,
  };

  List<Map<String, dynamic>> _savedMatching(Map<String, String> q) {
    final text = q['q']?.toLowerCase();
    final tag = q['tag']?.toLowerCase();
    final agent = q['agentId'];
    final before = q['before'];
    final list = saved.where((i) {
      if (text != null && !('${i['text']} ${i['note']}').toLowerCase().contains(text)) {
        return false;
      }
      if (tag != null && !(i['tags'] as List).any((t) => '$t'.toLowerCase() == tag)) return false;
      if (agent != null && (i['source'] as Map)['agentId'] != agent) return false;
      if (before != null && (i['createdAt'] as String).compareTo(before) >= 0) return false;
      return true;
    }).toList()..sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    return list;
  }

  /// `/api/saved` (saved-routes.ts) and `/api/products/images/:id` (app.ts).
  Future<bool> _saved(HttpRequest r, String path) async {
    Future<bool> json(int status, Object b) async {
      await _json(r, status, b);
      return true;
    }

    Future<Map<String, dynamic>> body() async =>
        jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
    final img = RegExp(r'^/api/products/images/([0-9a-f]{64})$').firstMatch(path);
    if (r.method == 'GET' && img != null) {
      final bytes = productImages[img.group(1)];
      if (bytes == null) return json(404, {'error': 'Picture not found'});
      r.response.statusCode = 200;
      r.response.headers.contentType = ContentType('image', 'png');
      r.response.add(bytes);
      await r.response.close();
      return true;
    }
    if (r.method == 'GET' && path == '/api/saved') {
      final q = r.uri.queryParameters;
      final all = _savedMatching(q);
      final limit = [
        int.tryParse(q['limit'] ?? '') ?? 50,
        savedPage,
      ].reduce((a, b) => a < b ? a : b);
      final tags = <String, int>{};
      final agents = <String, ({String name, int count})>{};
      for (final i in saved) {
        for (final t in i['tags'] as List) {
          tags['$t'] = (tags['$t'] ?? 0) + 1;
        }
        final s = i['source'] as Map;
        final a = agents[s['agentId']];
        agents[s['agentId'] as String] = (
          name: s['agentName'] as String,
          count: (a?.count ?? 0) + 1,
        );
      }
      return json(200, {
        'items': all.take(limit).toList(),
        'more': all.length > limit,
        'tags': [
          for (final e in tags.entries) {'tag': e.key, 'count': e.value},
        ],
        'agents': [
          for (final e in agents.entries)
            {'id': e.key, 'name': e.value.name, 'count': e.value.count},
        ],
      });
    }
    if (r.method == 'GET' && path == '/api/saved/export') {
      final q = r.uri.queryParameters;
      savedExports.add(q);
      final items = _savedMatching(q);
      r.response.statusCode = 200;
      r.response.headers.contentType = ContentType('text', 'markdown', charset: 'utf-8');
      r.response.write(
        '# ${q['lang'] == 'it' ? 'Salvati' : 'Saved'}\n\n'
        '${items.map((i) => i['text']).join('\n\n---\n\n')}\n',
      );
      await r.response.close();
      return true;
    }
    if (r.method == 'POST' && path == '/api/saved') {
      final b = await body();
      savedPosts.add(b);
      final src = b['source'] as Map<String, dynamic>;
      final item = savedItem(
        id: 'sv${++_savedSeq}',
        text: (b['text'] as String?) ?? 'The whole message',
        markdown: b['markdown'] as String?,
        whole: b['text'] == null,
        note: (b['note'] as String?) ?? '',
        tags: [for (final t in (b['tags'] as List? ?? const [])) '$t'],
        sessionId: src['sessionId'] as String,
        seq: src['seq'] as int,
        start: src['start'] as int?,
        end: src['end'] as int?,
        createdAt: '2026-11-16T12:00:${_savedSeq.toString().padLeft(2, '0')}.000Z',
      );
      saved.add(item);
      return json(201, item);
    }
    final one = RegExp(r'^/api/saved/([^/]+)$').firstMatch(path);
    if (one != null) {
      final id = one.group(1)!;
      final item = saved.where((i) => i['id'] == id).firstOrNull;
      if (item == null) return json(404, {'error': 'Saved item not found'});
      if (r.method == 'PATCH') {
        final b = await body();
        savedPatches.add({'id': id, ...b});
        if (b['note'] != null) item['note'] = b['note'];
        if (b['tags'] != null) item['tags'] = [for (final t in b['tags'] as List) '$t'];
        return json(200, item);
      }
      if (r.method == 'DELETE') {
        savedDeletes.add(id);
        saved.remove(item);
        return json(200, {'ok': true});
      }
      if (r.method == 'GET') return json(200, item);
    }
    return false;
  }

  /// `/ws` as ws.ts: hello with a token, welcome, the waiting requests, follow and send.
  Future<void> _socket(HttpRequest r) async {
    final ws = await WebSocketTransformer.upgrade(r);
    sockets.add(ws);
    void send(Map<String, dynamic> m) {
      if (!_dead.contains(ws)) ws.add(jsonEncode(m));
    }

    ws.listen(
      (data) {
        final m = jsonDecode(data as String) as Map<String, dynamic>;
        received.add(m);
        if (_dead.contains(ws)) return;
        switch (m['type']) {
          case 'hello':
            if (!tokens.contains(m['token'])) {
              ws.close(4003, 'unauthorized');
              return;
            }
            send({'type': 'welcome', 'protocolVersion': 2, 'ownerId': 'me', 'version': version});
            for (final p in permissions) {
              send({'type': 'permission.request', 'request': p});
            }
            for (final q in questions) {
              send({'type': 'question.request', 'request': q});
            }
          case 'session.follow':
            final sid = m['sessionId'] as String;
            // Twice on one connection: the second does nothing (ws.ts `follows.has`).
            if (!(follows[ws] ??= {}).add(sid)) return;
            final after = m['afterSeq'] is num ? (m['afterSeq'] as num).toInt() : null;
            final past = [
              for (final e in _logOf(sid))
                if (after == null || (e['seq'] as int) > after) e,
            ];
            send({
              'type': 'session.history',
              'sessionId': sid,
              'events': past,
              'lastSeq': past.isEmpty ? (after ?? -1) : past.last['seq'],
              'incremental': after != null,
            });
            send({'type': 'session.state', 'sessionId': sid, 'state': 'idle'});
          case 'session.unfollow':
            follows[ws]?.remove(m['sessionId']);
          case 'session.send':
            final sid = m['sessionId'] as String;
            if (busy.contains(sid)) {
              (queued[sid] ??= []).add(m);
            } else {
              _turn(sid, m['text'] as String);
            }
          case 'session.unqueue':
            unqueued.add(m['clientId'] as String);
            queued[m['sessionId']]?.removeWhere((q) => q['clientId'] == m['clientId']);
          case 'question.answer':
            final q = questions.where((x) => x['requestId'] == m['requestId']).firstOrNull;
            if (q == null) {
              send({'type': 'error', 'code': 'not_found', 'message': 'No such open question'});
              return;
            }
            questions.remove(q);
            questionAnswers[m['requestId'] as String] = m['answers'] as List<dynamic>;
            _store(q['sessionId'] as String, 'question.answered', {
              'requestId': m['requestId'],
              'answers': m['answers'],
            });
            _toAll({'type': 'question.closed', 'requestId': m['requestId'], 'via': 'app (test)'});
          case 'permission.resolve':
            resolves.add(m);
            permissions.removeWhere((p) => p['requestId'] == m['requestId']);
            answered[m['requestId'] as String] = m['decision'] as String;
            // To every connection of the owner (approvals' `closed`).
            _toAll({
              'type': 'permission.closed',
              'requestId': m['requestId'],
              'decision': m['decision'],
              'via': 'app (test)',
            });
          case 'ping':
            send({'type': 'pong'});
        }
      },
      onDone: () {
        sockets.remove(ws);
        follows.remove(ws);
        _dead.remove(ws);
      },
    );
  }

  Map<String, dynamic> _event(
    int seq,
    String type,
    Map<String, dynamic> payload, {
    String sid = 's1',
  }) => {
    'id': 'e$seq',
    'seq': seq,
    'ts': '2026-11-15T10:00:0$seq.000Z',
    'ownerId': 'me',
    'projectId': null,
    'agentId': 'a0',
    'sessionId': sid,
    'erased': false,
    'type': type,
    'payload': payload,
  };
}
