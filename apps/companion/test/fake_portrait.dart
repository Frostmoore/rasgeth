// 3.9.4: the person's portrait (app.ts `/api/portrait`, portrait.ts) in memory, answering as the
// real server does: the same shapes, the same refusals with their codes (`portrait_secret`,
// `portrait_gone`…), «not true» counted and never back, «forget everything» emptying it all.
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakePortrait {
  final calls = <String>[];
  final bodies = <String, Object?>{};
  bool on = true;
  Json agents = {'god': true, 'orchestrators': true, 'chat': true, 'others': false};
  int denied = 1;
  int _ids = 0;
  final traits = <Json>[
    {
      'id': 't1',
      'text': 'Prefers short answers',
      'category': 'style',
      'confidence': 0.82,
      'createdAt': '2026-11-10T10:00:00.000Z',
      'updatedAt': '2026-11-12T10:00:00.000Z',
      'seenAt': '2026-11-12T10:00:00.000Z',
      'by': 'auto',
      'edited': false,
      'confirmations': 2,
      'sources': [
        {
          'sessionId': 'sess-1',
          'agentId': 'god',
          'at': '2026-11-12T10:00:00.000Z',
          'sessionTitle': 'Release notes',
          'agentName': 'God',
        },
      ],
    },
    {
      'id': 't2',
      'text': 'Works on Rasgeth 3.9',
      'category': 'project',
      'confidence': 0.45,
      'createdAt': '2026-11-18T10:00:00.000Z',
      'updatedAt': '2026-11-18T10:00:00.000Z',
      'seenAt': '2026-11-18T10:00:00.000Z',
      'by': 'auto',
      'edited': false,
      'confirmations': 0,
      'sources': <Json>[],
    },
    {
      'id': 't3',
      'text': 'Likes green tea',
      'category': 'preference',
      'confidence': 1,
      'createdAt': '2026-11-01T10:00:00.000Z',
      'updatedAt': '2026-11-01T10:00:00.000Z',
      'seenAt': '2026-11-01T10:00:00.000Z',
      'by': 'human',
      'edited': true,
      'confirmations': 0,
      'sources': <Json>[],
    },
  ];

  static const _order = ['preference', 'style', 'habit', 'project', 'avoid', 'about'];

  Json view() {
    final sorted = [...traits]
      ..sort(
        (a, b) => _order.indexOf(a['category'] as String) - _order.indexOf(b['category'] as String),
      );
    return {
      'on': on,
      'agents': agents,
      'traits': sorted,
      'text': sorted.isEmpty
          ? ''
          : "## The person's portrait\n\n${[for (final t in sorted) '- ${t['text']}'].join('\n')}",
      'limit': 1600,
      'denied': denied,
    };
  }

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    if (!path.startsWith('/api/portrait')) return false;
    final m = r.method;
    calls.add('$m $path');
    Object? body;
    if (m != 'GET' && m != 'DELETE') {
      final text = await utf8.decodeStream(r);
      body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      bodies['$m $path'] = body;
    }
    final b = body is Json ? body : <String, dynamic>{};
    Future<bool> ok(Object o, [int s = 200]) async {
      await json(s, o);
      return true;
    }

    Future<bool> refuse(String code, String message) => ok({'error': message, 'code': code}, 400);
    if (m == 'GET' && path == '/api/portrait') return ok(view());
    if (m == 'PUT' && path == '/api/portrait/settings') {
      if (b['on'] is bool) on = b['on'] as bool;
      if (b['agents'] is Json) agents = b['agents'] as Json;
      return ok({'ok': true});
    }
    if (m == 'POST' && path == '/api/portrait/forget') {
      traits.clear();
      denied = 0;
      return ok({'ok': true});
    }
    String? secret(Object? t) =>
        t is String && RegExp('password', caseSensitive: false).hasMatch(t) ? t : null;
    if (m == 'POST' && path == '/api/portrait') {
      if (secret(b['text']) != null) {
        return refuse('portrait_secret', 'secrets never go into the portrait');
      }
      final id = 'n${++_ids}';
      traits.add({
        ...traits.last,
        'id': id,
        'text': b['text'],
        'category': b['category'] ?? 'about',
        'by': 'human',
        'edited': true,
        'confidence': 1,
        'sources': <Json>[],
      });
      return ok({'id': id});
    }
    final one = RegExp(r'^/api/portrait/([^/]+)(/deny)?$').firstMatch(path);
    if (one == null) return false;
    final id = Uri.decodeComponent(one.group(1)!);
    final i = traits.indexWhere((t) => t['id'] == id);
    if (i < 0) return refuse('portrait_gone', 'That trait is not there any more.');
    if (m == 'DELETE') {
      traits.removeAt(i);
      return ok({'ok': true});
    }
    if (m == 'POST' && one.group(2) != null) {
      traits.removeAt(i);
      denied++;
      return ok({'ok': true});
    }
    if (m == 'PUT') {
      if (secret(b['text']) != null) {
        return refuse('portrait_secret', 'secrets never go into the portrait');
      }
      traits[i] = {
        ...traits[i],
        if (b['text'] is String) 'text': b['text'],
        if (b['category'] is String) 'category': b['category'],
        'edited': true,
        'confidence': 1,
      };
      return ok({'ok': true});
    }
    return false;
  }
}
