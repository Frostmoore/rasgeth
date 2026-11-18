// The fake Rasgeth's files (G42.5): an in-memory workspace per scope answering the routes of
// the page's Explorer as `packages/server/src/files.ts` and `app.ts` do: list (folders first,
// `.git` left out), content (text or base64, 5 MB), write (expectedModifiedAt, ifExists fail /
// keep-both « (2)» / replace, parents made), op (mkdir, rename, delete to `.trash/<stamp>/…`, for
// good inside it, the root refused), raw, search, and `/api/artifacts/import`. An archived
// project's scope refuses every change with 423, as `assertWritable`.
import 'dart:convert';
import 'dart:io';

class FakeFiles {
  /// scope → path → bytes.
  final files = <String, Map<String, List<int>>>{};

  /// scope → folders (every parent of a file counts too).
  final dirs = <String, Set<String>>{};
  final times = <String, String>{};

  /// Scopes of archived projects: read only.
  final readOnly = <String>{};

  /// What changed, as the server's `workspace.changed` events.
  final changes = <Map<String, Object?>>[];
  int _clock = 0;

  String _now() =>
      DateTime.utc(2026, 11, 16, 10).add(Duration(seconds: ++_clock)).toIso8601String();

  Map<String, List<int>> _files(String scope) => files.putIfAbsent(scope, () => {});
  Set<String> _dirs(String scope) => dirs.putIfAbsent(scope, () => {});

  void _mkdirs(String scope, String path) {
    final parts = path.split('/');
    for (var i = 1; i <= parts.length; i++) {
      _dirs(scope).add(parts.take(i).join('/'));
    }
  }

  /// A file for the tests (text or bytes), its folders made.
  void put(String scope, String path, Object content) {
    final bytes = content is String ? utf8.encode(content) : content as List<int>;
    _files(scope)[path] = bytes;
    times['$scope:$path'] = _now();
    final i = path.lastIndexOf('/');
    if (i > 0) _mkdirs(scope, path.substring(0, i));
  }

  void mkdir(String scope, String path) => _mkdirs(scope, path);

  bool isFile(String scope, String path) => _files(scope).containsKey(path);
  bool isDir(String scope, String path) => path.isEmpty || _dirs(scope).contains(path);
  String? text(String scope, String path) {
    final b = _files(scope)[path];
    return b == null ? null : utf8.decode(b);
  }

  /// The workspace's own path rules: relative, no «..» (`ws.resolve`).
  static String? norm(String p) {
    var s = p.replaceAll('\\', '/').trim();
    if (s.startsWith('/')) return null;
    final out = <String>[];
    for (final part in s.split('/')) {
      if (part.isEmpty || part == '.') continue;
      if (part == '..') return null;
      out.add(part);
    }
    s = out.join('/');
    return s;
  }

  static final _scope = RegExp(r'^(platform|assistants|project:[a-z0-9-]+)$');

  /// Answers a files route; false when [path] is not one.
  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    final q = r.uri.queryParameters;
    final m = r.method;
    final routes = {
      'GET /api/files/list',
      'GET /api/files/content',
      'PUT /api/files/content',
      'POST /api/files/op',
      'GET /api/files/raw',
      'GET /api/files/search',
      'POST /api/artifacts/import',
    };
    if (!routes.contains('$m $path')) return false;
    Map<String, dynamic> body = const {};
    List<int> raw = const [];
    if (m == 'PUT' || (m == 'POST' && path == '/api/files/op')) {
      body = jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;
    } else if (m == 'POST') {
      raw = [for (final chunk in await r.toList()) ...chunk];
    }
    final scope = '${body['scope'] ?? q['scope'] ?? ''}';
    if (!_scope.hasMatch(scope)) {
      await json(400, {'error': 'Invalid scope "$scope"'});
      return true;
    }
    final change = m != 'GET';
    if (change && readOnly.contains(scope)) {
      await json(423, {
        'error': 'The project is archived: restore it to change it',
        'code': 'project_archived',
      });
      return true;
    }
    final p = norm('${body['path'] ?? q['path'] ?? '.'}');
    if (p == null) {
      await json(400, {'error': 'Path escapes the workspace'});
      return true;
    }
    final fs = _files(scope);
    switch ('$m $path') {
      case 'GET /api/files/list':
        if (!isDir(scope, p)) {
          await json(404, {'error': 'Not found: $p'});
          return true;
        }
        final kids = <Map<String, Object?>>[];
        bool child(String x) => p.isEmpty
            ? !x.contains('/')
            : x.startsWith('$p/') && !x.substring(p.length + 1).contains('/');
        for (final d in _dirs(scope)) {
          if (d.isEmpty || !child(d) || d.split('/').last == '.git') continue;
          kids.add({
            'name': d.split('/').last,
            'path': d,
            'type': 'dir',
            'size': 0,
            'modifiedAt': '2026-11-16T10:00:00.000Z',
          });
        }
        for (final MapEntry(key: f, value: b) in fs.entries) {
          if (!child(f)) continue;
          kids.add({
            'name': f.split('/').last,
            'path': f,
            'type': 'file',
            'size': b.length,
            'modifiedAt': times['$scope:$f'],
          });
        }
        kids.sort((a, b) {
          final da = a['type'] == 'dir', db = b['type'] == 'dir';
          if (da != db) return da ? -1 : 1;
          // As `localeCompare`: letters before case.
          final x = a['name']! as String, y = b['name']! as String;
          final byLetters = x.toLowerCase().compareTo(y.toLowerCase());
          return byLetters != 0 ? byLetters : x.compareTo(y);
        });
        await json(200, kids);
      case 'GET /api/files/content':
        final b = fs[p];
        if (b == null) {
          await json(isDir(scope, p) ? 400 : 404, {
            'error': isDir(scope, p) ? '$p is not a file' : 'Not found: $p',
          });
          return true;
        }
        if (b.length > 5 * 1024 * 1024) {
          await json(400, {'error': '$p is larger than 5 MB: download it instead'});
          return true;
        }
        String? text;
        try {
          text = utf8.decode(b);
          if (text.contains('\u0000')) text = null;
        } on FormatException {
          text = null;
        }
        await json(200, {
          'path': p,
          'encoding': text == null ? 'base64' : 'utf8',
          'content': text ?? base64.encode(b),
          'size': b.length,
          'modifiedAt': times['$scope:$p'],
        });
      case 'PUT /api/files/content':
        var target = p;
        final now = fs.containsKey(p) ? times['$scope:$p'] : null;
        if (body.containsKey('expectedModifiedAt') && body['expectedModifiedAt'] != now) {
          await json(409, {'error': '$p changed since it was opened', 'modifiedAt': now});
          return true;
        }
        final ifExists = body['ifExists'];
        if (now != null && ifExists == 'fail') {
          await json(409, {'error': '$p already exists', 'modifiedAt': now});
          return true;
        }
        if (now != null && ifExists == 'keep-both') {
          final slash = p.lastIndexOf('/');
          final dir = slash < 0 ? '' : p.substring(0, slash + 1);
          final base = p.substring(slash + 1);
          final dot = base.lastIndexOf('.');
          final stem = dot > 0 ? base.substring(0, dot) : base;
          final ext = dot > 0 ? base.substring(dot) : '';
          for (var n = 2; ; n++) {
            final c = '$dir$stem ($n)$ext';
            if (!fs.containsKey(c) && !isDir(scope, c)) {
              target = c;
              break;
            }
          }
        }
        final content = '${body['content'] ?? ''}';
        put(
          scope,
          target,
          body['encoding'] == 'base64' ? base64.decode(content) : utf8.encode(content),
        );
        changes.add({'scope': scope, 'action': 'write', 'path': target});
        await json(200, {'path': target, 'modifiedAt': times['$scope:$target']});
      case 'POST /api/files/op':
        final op = body['op'];
        if (op == 'mkdir') {
          if (p.isNotEmpty) _mkdirs(scope, p);
          changes.add({'scope': scope, 'action': 'mkdir', 'path': p});
          await json(200, {'ok': true});
          return true;
        }
        final file = fs.containsKey(p);
        final dir = !file && isDir(scope, p);
        if (p.isEmpty) {
          await json(400, {
            'error': op == 'rename'
                ? 'The workspace root cannot be renamed'
                : 'The workspace root cannot be deleted',
          });
          return true;
        }
        if (!file && !dir) {
          await json(404, {'error': 'Not found: $p'});
          return true;
        }
        String? to;
        if (op == 'rename') {
          to = norm('${body['to'] ?? ''}');
          if (to == null || to.isEmpty) {
            await json(400, {'error': 'The workspace root cannot be renamed'});
            return true;
          }
        } else if (op == 'delete') {
          if (p == '.trash' || p.startsWith('.trash/')) {
            _move(scope, p, null);
            changes.add({'scope': scope, 'action': 'delete', 'path': p});
            await json(200, {'ok': true});
            return true;
          }
          to = '.trash/2026-11-16T10-00-${(_clock++).toString().padLeft(2, '0')}/$p';
        } else {
          await json(400, {'error': 'Unknown op'});
          return true;
        }
        _move(scope, p, to);
        changes.add({'scope': scope, 'action': op, 'path': p, 'to': to});
        await json(200, {'ok': true});
      case 'GET /api/files/raw':
        final b = fs[p];
        if (b == null) {
          await json(404, {'error': 'Not found: $p'});
          return true;
        }
        r.response.headers.contentType = ContentType.binary;
        r.response.add(b);
        await r.response.close();
      case 'GET /api/files/search':
        final needle = (q['q'] ?? '').toLowerCase();
        final hits = <Map<String, Object?>>[];
        for (final MapEntry(key: f, value: b) in fs.entries) {
          if (f.toLowerCase().contains(needle)) hits.add({'path': f});
          String text;
          try {
            text = utf8.decode(b);
          } on FormatException {
            continue;
          }
          for (final (i, line) in text.split('\n').indexed) {
            if (line.toLowerCase().contains(needle)) {
              hits.add({'path': f, 'line': i + 1, 'text': line});
            }
          }
        }
        await json(200, hits);
      case 'POST /api/artifacts/import':
        // A `.rgartifact` is a zip: anything else is refused.
        if (raw.length < 4 || raw[0] != 0x50 || raw[1] != 0x4b) {
          await json(400, {'error': 'Not an artifact (.rgartifact)'});
          return true;
        }
        var target = 'artefatti/imported.html';
        for (var n = 2; fs.containsKey(target); n++) {
          target = 'artefatti/imported ($n).html';
        }
        put(scope, target, '<!doctype html><title>Imported</title>');
        changes.add({'scope': scope, 'action': 'write', 'path': target});
        await json(200, {
          'path': target,
          'name': 'Imported',
          'header': {'name': 'Imported'},
          'dataIgnored': false,
        });
    }
    return true;
  }

  /// A file or folder to [to] (null: gone for good), what is inside with it.
  void _move(String scope, String from, String? to) {
    final fs = _files(scope);
    final ds = _dirs(scope);
    String? moved(String x) => x == from
        ? to
        : x.startsWith('$from/')
        ? (to == null ? null : '$to${x.substring(from.length)}')
        : x;
    for (final f in fs.keys.toList()) {
      final n = moved(f);
      if (n == f) continue;
      final b = fs.remove(f)!;
      final t = times.remove('$scope:$f');
      if (n != null) {
        fs[n] = b;
        times['$scope:$n'] = t ?? _now();
        final i = n.lastIndexOf('/');
        if (i > 0) _mkdirs(scope, n.substring(0, i));
      }
    }
    for (final d in ds.toList()) {
      final n = moved(d);
      if (n == d) continue;
      ds.remove(d);
      if (n != null) _mkdirs(scope, n);
    }
    if (to != null) {
      final i = to.lastIndexOf('/');
      if (i > 0) _mkdirs(scope, to.substring(0, i));
    }
  }
}
