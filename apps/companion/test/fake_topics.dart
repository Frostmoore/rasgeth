// 3.12: God's topics (topic-routes.ts, topics.ts) in memory, answering as the contract says
// (`packages/protocol/src/topics.ts`): «Oggi»'s list (pinned first) and the archive with its
// search, a message routed or written inside a topic, «Move» to another topic or a new one,
// archive, restore and read; the interface and the person's name of the setup.
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

Json topicJson(
  String id,
  String title, {
  String? summary,
  String state = 'ready',
  bool archived = false,
  bool pinned = false,
  int unread = 0,
  int requests = 0,
  String lastAt = '2026-11-22T09:00:00.000Z',
}) => {
  'id': id,
  'title': title,
  'summary': summary,
  'state': state,
  'lastAt': lastAt,
  'personAt': lastAt,
  'createdAt': '2026-11-22T08:00:00.000Z',
  'pinned': pinned,
  'archived': archived,
  'unread': unread,
  'requests': requests,
  'tasks': 0,
  'projectId': null,
  'from': null,
};

class FakeTopics {
  final calls = <String>[];
  final bodies = <String, Object?>{};
  final active = <Json>[];
  final archived = <Json>[];
  String? ui;
  String? personName;

  Json _routed(Json t, String via, {bool isNew = false}) => {
    'topicId': t['id'],
    'title': t['title'],
    'via': via,
    'reason': via == 'here' ? 'written_here' : 'router',
    'isNew': isNew,
    'restored': false,
    'uncertain': false,
  };

  Json? _find(String id) =>
      active.where((t) => t['id'] == id).firstOrNull ??
      archived.where((t) => t['id'] == id).firstOrNull;

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    final m = r.method;
    final mine =
        path.startsWith('/api/god/') ||
        RegExp(r'^/api/sessions/[^/]+/messages/\d+/move$').hasMatch(path) ||
        path == '/api/setup/interface' ||
        path == '/api/setup/person';
    if (!mine) return false;
    final q = r.uri.queryParameters;
    calls.add('$m $path${q.isEmpty ? '' : '?${Uri(queryParameters: q).query}'}');
    Object? body;
    if (m != 'GET') {
      final text = await utf8.decodeStream(r);
      body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      bodies['$m $path'] = body;
    }
    final b = body is Json ? body : <String, dynamic>{};
    Future<bool> ok(Object o, [int s = 200]) async {
      await json(s, o);
      return true;
    }

    if (m == 'GET' && path == '/api/god/topics') {
      final words = (q['q'] ?? '').toLowerCase();
      final from = q['archived'] == 'true' ? archived : active;
      final list = [
        for (final t in from)
          if ('${t['title']} ${t['summary'] ?? ''}'.toLowerCase().contains(words)) t,
      ]..sort((a, c) => (c['pinned'] == true ? 1 : 0) - (a['pinned'] == true ? 1 : 0));
      return ok({'topics': list, 'archived': archived.length});
    }
    if (m == 'POST' && path == '/api/god/messages') {
      final text = b['text'];
      if (text is! String || text.trim().isEmpty) return ok({'error': 'text'}, 400);
      final inside = b['topicId'] is String ? _find(b['topicId'] as String) : null;
      if (inside != null)
        return ok({'sessionId': inside['id'], 'routed': _routed(inside, 'here')}, 202);
      // The router picks the first active topic; none: a new one named by the first words.
      final first = active.firstOrNull;
      if (first != null && b['newTopic'] != true) {
        return ok({'sessionId': first['id'], 'routed': _routed(first, 'router')}, 202);
      }
      final t = topicJson('t_new', text.trim(), state: 'working');
      active.insert(0, t);
      return ok({'sessionId': 't_new', 'routed': _routed(t, 'router', isNew: true)}, 202);
    }
    final move = RegExp(r'^/api/sessions/([^/]+)/messages/(\d+)/move$').firstMatch(path);
    if (m == 'POST' && move != null) {
      final to = b['to'];
      final seq = int.parse(move.group(2)!);
      Json? t;
      if (to == 'new') {
        t = topicJson('t_moved', (b['title'] as String?) ?? 'Nuovo argomento', state: 'working');
        active.insert(0, t);
      } else if (to is String) {
        t = _find(to);
      }
      if (t == null) return ok({'error': 'Not one of God\'s topics'}, 404);
      return ok({
        'sessionId': t['id'],
        'seq': seq,
        'throughSeq': seq + 1,
        'routed': _routed(t, 'person', isNew: to == 'new'),
        'tasks': <String>[],
      });
    }
    final act = RegExp(r'^/api/god/topics/([^/]+)/(archive|restore|read)$').firstMatch(path);
    if (m == 'POST' && act != null) {
      final id = act.group(1)!;
      final t = _find(id);
      if (t == null) return ok({'error': 'Not one of God\'s topics'}, 404);
      switch (act.group(2)) {
        case 'archive':
          active.remove(t);
          archived.add({...t, 'archived': true});
        case 'restore':
          archived.remove(t);
          active.insert(0, {...t, 'archived': false});
        case 'read':
          t['unread'] = 0;
      }
      return ok({'ok': true});
    }
    if (m == 'PUT' && path == '/api/setup/interface') {
      ui = b['ui'] as String?;
      return ok({'ok': true});
    }
    if (m == 'PUT' && path == '/api/setup/person') {
      personName = b['name'] as String?;
      return ok({'ok': true});
    }
    return ok({'error': 'Not found'}, 404);
  }
}
