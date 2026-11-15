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
      },
  ];

  Future<void> _handle(HttpRequest r) async {
    requests.add('${r.method} ${r.uri}');
    final token = _bearer(r);
    final path = r.uri.path;
    if (r.method == 'GET' && path == '/api/app/hello') {
      return _json(r, 200, {
        'app': 'redgiant',
        'version': '3.8.0',
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
    if (!tokens.contains(token)) return _json(r, 401, {'error': 'Unauthorized'});
    if (r.method == 'GET' && path == '/api/agents') return _json(r, 200, agents);
    if (r.method == 'GET' && path == '/api/sessions') {
      final a = r.uri.queryParameters['agentId'];
      return _json(r, 200, [
        for (final x in sessions)
          if (a == null || x['agentId'] == a) x,
      ]);
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
    final one = RegExp(r'^/api/sessions/([^/]+)(/messages|/interrupt)?$').firstMatch(path);
    if (one != null) {
      final row = sessions.where((x) => x['id'] == one.group(1)).firstOrNull;
      if (row == null) return _json(r, 404, {'error': 'Not found'});
      final body = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
      if (r.method == 'PATCH' && one.group(2) == null) {
        row.addAll(body);
        return _json(r, 200, {'ok': true});
      }
      if (r.method == 'POST' && one.group(2) == '/messages') return _json(r, 202, {'ok': true});
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
        {'id': 'demo', 'name': 'Demo', 'path': '/p', 'createdAt': '2026-11-01T00:00:00.000Z'},
      ]);
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

  /// `/ws` as ws.ts: hello with a token, welcome, the waiting requests, follow and send.
  Future<void> _socket(HttpRequest r) async {
    final ws = await WebSocketTransformer.upgrade(r);
    sockets.add(ws);
    void send(Map<String, dynamic> m) => ws.add(jsonEncode(m));
    ws.listen((data) {
      final m = jsonDecode(data as String) as Map<String, dynamic>;
      received.add(m);
      switch (m['type']) {
        case 'hello':
          if (!tokens.contains(m['token'])) {
            ws.close(4003, 'unauthorized');
            return;
          }
          send({'type': 'welcome', 'protocolVersion': 2, 'ownerId': 'me', 'version': '3.8.0'});
          for (final p in permissions) {
            send({'type': 'permission.request', 'request': p});
          }
        case 'session.follow':
          send({
            'type': 'session.history',
            'sessionId': m['sessionId'],
            'events': [_event(1, 'session.started', {})],
            'lastSeq': 1,
            'incremental': false,
          });
          send({'type': 'session.state', 'sessionId': m['sessionId'], 'state': 'idle'});
        case 'session.send':
          final sid = m['sessionId'];
          send({
            'type': 'event',
            'sessionId': sid,
            'event': _event(2, 'message.user', {'text': m['text']}),
          });
          send({'type': 'session.state', 'sessionId': sid, 'state': 'running'});
          send({'type': 'delta', 'sessionId': sid, 'kind': 'thinking', 'text': 'Let me see'});
          send({'type': 'delta', 'sessionId': sid, 'kind': 'text', 'text': 'Hello'});
          send({
            'type': 'event',
            'sessionId': sid,
            'event': _event(3, 'message.assistant', {
              'parts': [
                {'type': 'thinking', 'text': 'Let me see'},
                {'type': 'text', 'text': 'Hello **there**'},
              ],
              'stopReason': 'end_turn',
            }),
          });
          send({
            'type': 'session.state',
            'sessionId': sid,
            'state': 'idle',
            'stopReason': 'end_turn',
          });
        case 'permission.resolve':
          permissions.removeWhere((p) => p['requestId'] == m['requestId']);
          answered[m['requestId'] as String] = m['decision'] as String;
          send({
            'type': 'permission.closed',
            'requestId': m['requestId'],
            'decision': m['decision'],
            'via': 'app (test)',
          });
        case 'ping':
          send({'type': 'pong'});
      }
    });
  }

  Map<String, dynamic> _event(int seq, String type, Map<String, dynamic> payload) => {
    'id': 'e$seq',
    'seq': seq,
    'ts': '2026-11-15T10:00:0$seq.000Z',
    'ownerId': 'me',
    'projectId': null,
    'agentId': 'a0',
    'sessionId': 's1',
    'erased': false,
    'type': type,
    'payload': payload,
  };
}
