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
        'machine': 'RedGiant di casa',
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
    if (!tokens.contains(token)) return _json(r, 401, {'error': 'Unauthorized'});
    if (r.method == 'GET' && path == '/api/agents') return _json(r, 200, agents);
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
}
