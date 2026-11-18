// G42.10: the knowledge (packages/server/src/knowledge/routes.ts) and the shared memory (app.ts
// `/api/memory`, shared-memory.ts) in memory, answering as the real server does: the same shapes,
// the same refusals with their codes (`not_found`, `bad_choice`, `embedding_failed`,
// `memory_empty`, `memory_long`, `memory_same`, `memory_moved`, `memory_undone`…), zod's 400s for
// a bad body, and the undo rules of the shared memory (a change taken back once, only while what
// it did is still what the memory holds).
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeKnowledge {
  FakeKnowledge({bool demo = true}) {
    if (demo) _demo();
  }

  /// Every request, «METHOD /path», and every body sent.
  final calls = <String>[];
  final bodies = <String, Object?>{};

  // ---- knowledge ----
  bool vectorOk = true;
  Json? embedding = {'provider': 'local', 'model': 'embeddinggemma-300m'};
  Json? rerank;
  int threads = 0;
  bool ocrOn = false;
  List<String> ocrLanguages = ['ita', 'eng'];
  bool backupVectors = false;
  bool paused = false;
  int embedded = 600;
  int total = 1800;
  int queueDocuments = 0;
  final collections = <Json>[];
  final sources = <String, List<Json>>{};
  final documents = <String, List<Json>>{};
  final jobs = <Json>[];
  final writes = <String, String>{};
  int _ids = 0;

  /// The cloud key that the server's one try refuses.
  String badKey = 'bad';

  // ---- shared memory ----
  bool auto = true;
  final entries = <Json>[];
  final changes = <Json>[];
  int _seq = 100;

  void _demo() {
    collections.addAll([
      {
        'id': 'c1',
        'name': 'Home manuals',
        'scope': {'kind': 'all'},
        'language': 'italian',
        'description': 'Warranties, instructions and recipes',
        'createdAt': '2026-11-10T10:00:00.000Z',
        'documents': 14,
        'chunks': 212,
      },
      {
        'id': 'c2',
        'name': 'Project notes',
        'scope': {'kind': 'project', 'projectId': 'demo'},
        'language': 'italian',
        'createdAt': '2026-11-11T10:00:00.000Z',
        'documents': 3,
        'chunks': 18,
      },
    ]);
    sources['c1'] = [
      {
        'id': 's1',
        'collectionId': 'c1',
        'spec': {'kind': 'folder', 'path': '/home/demo/Documenti/Home manuals', 'exclude': []},
        'state': 'ready',
        'documents': 14,
        'lastScanAt': '2026-11-18T08:00:00.000Z',
      },
    ];
    sources['c2'] = [
      {
        'id': 's2',
        'collectionId': 'c2',
        'spec': {'kind': 'workspace', 'scope': 'project:demo', 'path': '.'},
        'state': 'scanning',
        'documents': 3,
        'lastScanAt': null,
      },
    ];
    documents['c1'] = [
      {
        'id': 'd9',
        'sourceId': 's1',
        'collectionId': 'c1',
        'path': 'scontrino.jpg',
        'title': 'scontrino.jpg',
        'kind': 'image',
        'state': 'skipped',
        'reason': 'needs_ocr',
        'pages': null,
        'chunks': 0,
        'bytes': 3,
        'indexedAt': null,
      },
    ];
    _addMemory('Si chiama Severino e scrive in italiano', by: 'auto', session: true);
    _addMemory('Il lunedì mattina non fissare appuntamenti', by: 'human');
  }

  String _id(String p) => '$p${++_ids}';

  Json _collection(String id) =>
      collections.firstWhere((c) => c['id'] == id, orElse: () => const {});

  Json status() => {
    'meaning': embedding == null
        ? {'on': false, 'off': 'no_model'}
        : vectorOk
        ? {'on': true}
        : {'on': false, 'off': 'no_vector', 'detail': 'vector.so missing'},
    'vector': vectorOk ? {'ok': true, 'version': '0.8.0'} : {'ok': false, 'reason': 'not loaded'},
    'settings': {
      'embedding': embedding,
      'rerank': rerank,
      'threads': threads,
      'agents': {},
      'ocr': {'on': ocrOn, 'languages': ocrLanguages},
      'backupVectors': backupVectors,
    },
    'indexes': [
      if (embedding != null)
        {
          'id': 1,
          'provider': embedding!['provider'],
          'model': embedding!['model'],
          'dims': 768,
          'state': embedded < total ? 'building' : 'ready',
          'active': true,
          'embedded': embedded,
          'total': total,
          'ann': false,
          'createdAt': '2026-11-18T08:00:00.000Z',
          'readyAt': null,
        },
    ],
    'queue': {
      'documents': queueDocuments,
      'chunks': total - embedded,
      'running': !paused,
      'paused': paused,
      if (embedded < total) 'perMinute': 120,
      if (embedded < total) 'etaSeconds': ((total - embedded) / 2).round(),
    },
    'collections': collections.length,
    'chunks': total,
    'ocr': {'on': ocrOn, 'languages': ocrLanguages, 'ready': false, 'waiting': 1},
  };

  Json models() => {
    'providers': ['local', 'openai'],
    'rerankProviders': ['local'],
    'local': [
      {
        'id': 'qwen3-embedding-0.6b',
        'name': 'Qwen3-Embedding 0.6B',
        'sizeMb': 639,
        'dims': 1024,
        'defaultDims': 1024,
        'recommended': true,
        'here': false,
      },
      {
        'id': 'embeddinggemma-300m',
        'name': 'EmbeddingGemma 300M',
        'sizeMb': 334,
        'dims': 768,
        'defaultDims': 768,
        'here': true,
      },
    ],
    'localRerank': [
      {
        'id': 'bge-reranker-v2-m3',
        'name': 'BGE Reranker v2 M3',
        'sizeMb': 636,
        'recommended': true,
        'here': false,
      },
    ],
    'cloud': [
      {'provider': 'openai', 'model': 'text-embedding-3-small', 'dims': 1536},
      {'provider': 'voyage', 'model': 'voyage-3.5', 'dims': 1024},
    ],
    'languages': ['italian', 'simple'],
    'ocr': [
      {'id': 'ita', 'name': 'Italiano', 'sizeKb': 1622, 'here': false},
      {'id': 'eng', 'name': 'English', 'sizeKb': 2884, 'here': false},
      {'id': 'fra', 'name': 'Français', 'sizeKb': 691, 'here': false},
    ],
  };

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    final m = r.method;
    // An agent's own choices stay with the fake server's agents (g387).
    if (path.startsWith('/api/knowledge/agents/')) return false;
    if (!path.startsWith('/api/knowledge') &&
        !path.startsWith('/api/memory') &&
        path != '/api/jobs' &&
        !(m == 'PUT' && path == '/api/files/content')) {
      return false;
    }
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

    Future<bool> refuse(String code, String message, [int s = 400]) =>
        ok({'error': message, 'code': code}, code == 'not_found' ? 404 : s);
    Future<bool> zod(String message) => ok({'error': message}, 400);

    if (path == '/api/jobs' && m == 'GET') return ok(jobs);
    if (m == 'PUT' && path == '/api/files/content') {
      writes['${b['scope']}:${b['path']}'] = '${b['content']}';
      return ok({'path': b['path'], 'modifiedAt': '2026-11-18T09:00:00.000Z'});
    }
    if (path.startsWith('/api/memory')) return _memory(m, path, b, ok, refuse);

    if (m == 'GET' && path == '/api/knowledge') return ok(status());
    if (m == 'GET' && path == '/api/knowledge/models') return ok(models());
    if (m == 'GET' && path == '/api/knowledge/disk') {
      return ok({'texts': 2400000, 'vectors': 5100000, 'models': 350000000, 'ocr': 0});
    }
    if (m == 'GET' && path == '/api/knowledge/mailboxes') {
      return ok({
        'mailboxes': [
          {'id': 'box_lavoro', 'name': 'Lavoro'},
        ],
      });
    }
    if (m == 'PUT' && path == '/api/knowledge/settings') {
      if (b.containsKey('embedding')) {
        final e = b['embedding'];
        if (e is Map && e['provider'] != 'local' && e['credential'] == badKey) {
          return refuse('embedding_failed', 'The API answered 401');
        }
        embedding = e is Json ? e : null;
      }
      if (b.containsKey('rerank')) rerank = b['rerank'] is Json ? b['rerank'] as Json : null;
      if (b['threads'] is int) threads = b['threads'] as int;
      if (b['backupVectors'] is bool) backupVectors = b['backupVectors'] as bool;
      if (b['ocr'] case {'on': final bool on, 'languages': final List<dynamic> langs}) {
        ocrOn = on;
        ocrLanguages = [for (final x in langs) '$x'];
      }
      return ok(status()['settings'] as Object);
    }
    if (m == 'POST' && path == '/api/knowledge/models/download') {
      final role = b['role'];
      final id = b['id'];
      if (role != 'embed' && role != 'rerank') return zod('role: Invalid option');
      final model = [
        ...(models()['local'] as List),
        ...(models()['localRerank'] as List),
      ].cast<Json>().where((x) => x['id'] == id).firstOrNull;
      if (model == null) return refuse('bad_choice', 'Unknown local model "$id"');
      jobs.add({
        'id': _id('j'),
        'kind': 'download_knowledge_model',
        'vars': {'model': model['name'], 'size': '${model['sizeMb']} MB'},
        'state': 'running',
        'steps': [
          {'id': 'tool_download', 'state': 'done'},
          {
            'id': 'model_download',
            'state': 'running',
            'progress': {
              'done': 200000000,
              'total': 639000000,
              'rate': 12000000,
              'secondsLeft': 37,
            },
          },
        ],
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return ok({'ok': true}, 202);
    }
    if (m == 'POST' && path == '/api/knowledge/ocr/download') {
      final langs = b['languages'];
      if (langs is! List || langs.isEmpty) return zod('languages: Too small');
      jobs.add({
        'id': _id('j'),
        'kind': 'download_ocr',
        'vars': {'languages': langs.join(', '), 'size': '8 MB'},
        'state': 'running',
        'steps': [
          {'id': 'ocr_program', 'state': 'running'},
          {'id': 'ocr_languages', 'state': 'waiting'},
        ],
        'startedAt': DateTime.now().toUtc().toIso8601String(),
      });
      return ok({'ok': true}, 202);
    }
    if (m == 'POST' && path == '/api/knowledge/rebuild') {
      embedded = 0;
      return ok({'ok': true});
    }
    if (m == 'POST' && path == '/api/knowledge/pause') {
      if (b['paused'] is! bool) return zod('paused: Invalid input');
      paused = b['paused'] as bool;
      return ok({'ok': true});
    }
    if (path == '/api/knowledge/collections') {
      if (m == 'GET') return ok({'collections': collections});
      if (m == 'POST') {
        final name = '${b['name'] ?? ''}'.trim();
        if (name.isEmpty || name.length > 120) return zod('name: Too small: expected string');
        final c = {
          'id': _id('c'),
          'name': name,
          'scope': b['scope'] ?? {'kind': 'all'},
          'language': 'italian',
          'createdAt': '2026-11-18T09:00:00.000Z',
          'documents': 0,
          'chunks': 0,
        };
        collections.add(c);
        sources[c['id'] as String] = [];
        return ok(c, 201);
      }
    }
    if (m == 'POST' && path == '/api/knowledge/search') {
      final q = '${b['query'] ?? ''}'.trim();
      if (q.isEmpty) return zod('query: Too small: expected string to have >=1 characters');
      final words = q.toLowerCase().contains('garanzia');
      return ok({
        'hits': [
          if (words)
            {
              'citation': {
                'collectionId': 'c1',
                'documentId': 'd1',
                'chunkId': '41',
                'source': 'folder',
                'path': 'lavatrice.pdf',
                'title': 'lavatrice.pdf',
                'heading': 'Garanzia',
                'page': 12,
              },
              'text': 'La garanzia della lavatrice dura due anni dalla data di acquisto.',
              'score': .82,
              'ranks': {'meaning': 1, 'words': 1},
            },
        ],
        'strategy': 'exact',
        'indexId': 1,
        'ms': 14,
      });
    }
    final open = RegExp(r'^/api/knowledge/open/(\d+)$').firstMatch(path);
    if (m == 'GET' && open != null) {
      return switch (open[1]) {
        '41' => ok({
          'title': 'lavatrice.pdf',
          'target': {
            'kind': 'file',
            'scope': 'platform',
            'path': 'knowledge/lavatrice.md',
            'at': {'page': 12},
          },
          'citation': {},
        }),
        '42' => ok({
          'title': 'Preventivo cucina',
          'text': 'Il preventivo è di 4.200 euro.',
          'citation': {},
        }),
        _ => refuse('not_found', 'No such piece'),
      };
    }
    final one = RegExp(r'^/api/knowledge/collections/([^/]+)(/.*)?$').firstMatch(path);
    if (one != null) {
      final id = Uri.decodeComponent(one[1]!);
      final rest = one[2] ?? '';
      final c = _collection(id);
      if (c.isEmpty) return refuse('not_found', 'No such collection');
      if (rest.isEmpty && m == 'PUT') {
        if (b['scope'] is Json) c['scope'] = b['scope'];
        return ok(c);
      }
      if (rest.isEmpty && m == 'DELETE') {
        collections.remove(c);
        return ok({'ok': true});
      }
      if (rest == '/sources' && m == 'GET') return ok({'sources': sources[id] ?? []});
      if (rest == '/sources' && m == 'POST') {
        final kind = b['kind'];
        final bad = switch (kind) {
          'folder' || 'file' => '${b['path'] ?? ''}'.isEmpty,
          'url' => !(Uri.tryParse('${b['url']}')?.hasScheme ?? false),
          'workspace' => '${b['scope'] ?? ''}'.isEmpty,
          'mail' => b['consent'] != true || '${b['mailbox'] ?? ''}'.isEmpty,
          'chats' => b['consent'] != true,
          _ => true,
        };
        if (bad) return zod('Invalid input');
        if (kind == 'folder' && '${b['path']}'.startsWith('/nowhere')) {
          return refuse('bad_source', 'No such folder');
        }
        final s = {
          'id': _id('s'),
          'collectionId': id,
          'spec': b,
          'state': 'waiting',
          'documents': 0,
          'lastScanAt': null,
        };
        (sources[id] ??= []).add(s);
        return ok(s, 201);
      }
      final src = RegExp(r'^/sources/([^/]+)$').firstMatch(rest);
      if (src != null && m == 'DELETE') {
        final list = sources[id] ?? [];
        final before = list.length;
        list.removeWhere((s) => s['id'] == Uri.decodeComponent(src[1]!));
        if (list.length == before) return refuse('not_found', 'No such source');
        return ok({'ok': true});
      }
      if (rest == '/rescan' && m == 'POST') {
        for (final s in sources[id] ?? <Json>[]) {
          if (b['source'] == null || s['id'] == b['source']) s['state'] = 'scanning';
        }
        return ok({'ok': true});
      }
      if (rest == '/documents' && m == 'GET') {
        final st = r.uri.queryParameters['state'];
        return ok({
          'documents': [
            for (final d in documents[id] ?? <Json>[])
              if (st == null || d['state'] == st) d,
          ],
        });
      }
    }
    return false;
  }

  // ---- shared memory, as shared-memory.ts ----

  String _now() => DateTime.now().toUtc().toIso8601String();

  void _record(
    String id,
    String action,
    String text, {
    String? before,
    int? undoOf,
    String by = 'human',
  }) {
    final seq = ++_seq;
    changes.add({
      'seq': seq,
      'ts': _now(),
      'memoryId': id,
      'action': action,
      'text': text,
      'before': ?before,
      'by': by,
      'sessionId': null,
      'undoOf': ?undoOf,
    });
    if (undoOf != null) {
      changes.firstWhere((c) => c['seq'] == undoOf)['undoneBy'] = seq;
    }
    final at = entries.indexWhere((e) => e['id'] == id);
    if (action == 'removed') {
      if (at >= 0) entries.removeAt(at);
    } else if (action == 'edited' && at >= 0) {
      entries[at] = {...entries[at], 'text': text, 'updatedAt': _now()};
    } else if (action == 'added') {
      final old = changes.where((c) => c['memoryId'] == id).first;
      entries.add({
        'id': id,
        'text': text,
        'createdAt': old['ts'],
        'updatedAt': _now(),
        'by': old['by'],
        'sessionId': old['by'] == 'auto' ? 'sx' : null,
        'agentId': old['by'] == 'auto' ? 'a0' : null,
        'sessionTitle': old['by'] == 'auto' ? 'Presentazioni' : null,
        'agentName': old['by'] == 'auto' ? 'God' : null,
      });
    }
  }

  void _addMemory(String text, {String by = 'human', bool session = false}) =>
      _record(_id('m'), 'added', text, by: by);

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ').trim();

  int get _used => entries.fold(0, (n, e) => n + '- ${e['text']}\n'.length);

  Json view() => {
    'auto': auto,
    'entries': entries,
    'changes': changes.reversed.take(50).toList(),
    'used': _used,
    'limit': 10000,
  };

  Future<bool> _memory(
    String m,
    String path,
    Json b,
    Future<bool> Function(Object o, [int s]) ok,
    Future<bool> Function(String code, String message, [int s]) refuse,
  ) async {
    String check(Object? t) => '${t ?? ''}'.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (m == 'GET' && path == '/api/memory') return ok(view());
    if (m == 'PUT' && path == '/api/memory/settings') {
      if (b['auto'] is! bool) return ok({'error': 'auto is required'}, 400);
      auto = b['auto'] as bool;
      return ok({'ok': true});
    }
    if (m == 'POST' && path == '/api/memory/undo') {
      final seq = b['seq'];
      if (seq is! int) return ok({'error': 'seq is required'}, 400);
      final c = changes.where((x) => x['seq'] == seq).firstOrNull;
      if (c == null) return refuse('memory_gone', 'No such change.');
      if (c['undoneBy'] != null) return refuse('memory_undone', 'That change was already undone.');
      if (c['action'] == 'forgotten') {
        return refuse('memory_forgotten', 'A forgotten memory cannot come back.');
      }
      final id = c['memoryId'] as String;
      final now = entries.where((e) => e['id'] == id).firstOrNull;
      Future<bool> moved() => refuse('memory_moved', 'The memory changed again since.');
      switch (c['action']) {
        case 'added':
          if (now?['text'] != c['text']) return moved();
          _record(id, 'removed', c['text'] as String, undoOf: seq);
        case 'edited':
          if (now?['text'] != c['text'] || c['before'] == null) return moved();
          _record(id, 'edited', c['before'] as String, before: c['text'] as String, undoOf: seq);
        default:
          if (now != null) return moved();
          _record(id, 'added', c['text'] as String, undoOf: seq);
      }
      return ok({'ok': true});
    }
    if (m == 'POST' && path == '/api/memory') {
      if (b['text'] is! String || (b['text'] as String).isEmpty) {
        return ok({'error': 'text is required'}, 400);
      }
      final t = check(b['text']);
      if (t.isEmpty) return refuse('memory_empty', 'Write something to remember.');
      if (t.length > 400) return refuse('memory_long', 'One memory is at most 400 characters.');
      final same = entries.where((e) => _norm('${e['text']}') == _norm(t)).firstOrNull;
      if (same != null) return ok({'entry': same, 'duplicate': true});
      _addMemory(t);
      return ok({'entry': entries.last, 'duplicate': false});
    }
    final one = RegExp(r'^/api/memory/([^/]+)(/forget)?$').firstMatch(path);
    if (one == null) return false;
    final id = Uri.decodeComponent(one[1]!);
    final now = entries.where((e) => e['id'] == id).firstOrNull;
    if (one[2] != null && m == 'POST') {
      if (!changes.any((c) => c['memoryId'] == id)) {
        return refuse('memory_gone', 'That memory is not there any more.');
      }
      for (final c in changes.where((c) => c['memoryId'] == id)) {
        c['text'] = '';
        c.remove('before');
      }
      entries.removeWhere((e) => e['id'] == id);
      changes.add({
        'seq': ++_seq,
        'ts': _now(),
        'memoryId': id,
        'action': 'forgotten',
        'text': '',
        'by': 'human',
        'sessionId': null,
      });
      return ok({'ok': true});
    }
    if (m == 'PUT') {
      final t = check(b['text']);
      if (t.isEmpty) return refuse('memory_empty', 'Write something to remember.');
      if (t.length > 400) return refuse('memory_long', 'One memory is at most 400 characters.');
      if (now == null) return refuse('memory_gone', 'That memory is not there any more.');
      if (now['text'] == t) return ok(now);
      if (entries.any((e) => e['id'] != id && _norm('${e['text']}') == _norm(t))) {
        return refuse('memory_same', 'Already remembered.');
      }
      _record(id, 'edited', t, before: now['text'] as String);
      return ok(entries.firstWhere((e) => e['id'] == id));
    }
    if (m == 'DELETE') {
      if (now == null) return refuse('memory_gone', 'That memory is not there any more.');
      _record(id, 'removed', now['text'] as String);
      return ok({'ok': true});
    }
    return false;
  }
}
