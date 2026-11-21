// G42.11: Settings › Extensions against an in-memory server answering as app.ts does: the agents'
// proposals and their decision, a skill written by hand, the installed tools and skills, a skill's
// .zip exported and imported (409 when the name is taken, `replace=1` then), the MCP servers with
// their state and sign-in, the magic integrations and extensions, and the generation's choices and
// keys (written into the fake server's own `setup`, as the real one keeps them).
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeExtensions {
  FakeExtensions(this.setup);

  /// The fake server's `GET /api/setup` answer: the media choices live in it.
  final Json setup;
  final calls = <String>[];
  final bodies = <String, Object?>{};
  final imports = <List<int>>[];
  final installedNames = <String>{'release-notes'};

  final proposals = <Json>[
    {
      'id': 'p_tool',
      'projectId': 'demo',
      'kind': 'tool',
      'name': 'word-count',
      'author': 'a1',
      'status': 'pending',
      'report': [
        {'name': 'counts three words', 'passed': true, 'detail': '3'},
      ],
      'createdAt': '2026-11-20T10:00:00.000Z',
      'input': {
        'spec': {'description': 'Counts the words of a text', 'command': 'node count.mjs'},
        'files': {'count.mjs': 'console.log(3)'},
      },
    },
    {
      'id': 'p_skill',
      'projectId': null,
      'kind': 'skill',
      'name': 'release-notes',
      'author': 'a1',
      'status': 'pending',
      'report': <Json>[],
      'createdAt': '2026-11-20T10:00:00.000Z',
      'input': {
        'description': 'How we write release notes',
        'body': 'Group changes by user impact. Link every line to its pull request.',
        'summary': 'The person asked where a change came from.',
        'updates': true,
        'files': {'check.sh': '#!/bin/sh\necho ok'},
      },
      'previous': {
        'skillMd': 'Group changes by user impact.',
        'files': ['examples.md'],
        'scope': 'platform',
      },
      'proposedSkillMd': 'Group changes by user impact. Link every line to its pull request.',
      'updateLine': 'Every line links to its pull request: the person asked twice',
    },
    {
      'id': 'p_failed',
      'projectId': null,
      'kind': 'tool',
      'name': 'pdf-split',
      'author': 'a1',
      'status': 'failed',
      'report': [
        {'name': 'splits a PDF', 'passed': false, 'detail': 'qpdf: not found\nexit 127'},
      ],
      'createdAt': '2026-11-20T09:00:00.000Z',
      'input': {
        'spec': {'description': 'Splits a PDF in pages', 'command': 'qpdf'},
      },
    },
  ];

  final mcp = <Json>[
    {
      'name': 'docs',
      'project_id': null,
      'transport': {'type': 'http', 'url': 'https://mcp.example.com/mcp', 'oauth': true},
    },
  ];
  final status = <Json>[
    {'name': 'docs', 'projectId': null, 'state': 'login', 'tools': 0},
  ];

  final magic = <Json>[
    {
      'id': 'mx1',
      'kind': 'integration',
      'title': 'Notion',
      'request': 'Connect me to Notion: search my pages',
      'sessionId': 's1',
      'agentId': 'god',
      'status': 'ready',
      'proposal': {
        'name': 'notion',
        'title': 'Notion pages',
        'summary': 'Searches your Notion pages and creates new ones.',
        'hosts': ['api.notion.com'],
        'credentials': [
          {'name': 'notion_api', 'service': 'Notion', 'why': 'To read your pages', 'hosts': []},
        ],
        'parts': [
          {
            'kind': 'tool',
            'name': 'notion-search',
            'description': 'Searches pages',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'query': {'type': 'string'},
                'limit': {'type': 'number'},
              },
              'required': ['query'],
            },
            'command': 'node search.mjs',
            'files': {'search.mjs': 'fetch("https://api.notion.com/v1/search")'},
            'proposalId': 'mp1',
            'status': 'pending',
            'tests': [
              {'name': 'searches', 'passed': true, 'detail': ''},
            ],
          },
        ],
        'at': '2026-11-20T10:00:00.000Z',
      },
      'checks': [
        {
          'kind': 'credential',
          'what': 'notion_api',
          'ok': false,
          'service': 'Notion',
          'hosts': ['api.notion.com'],
          'exists': false,
        },
      ],
      'canApprove': false,
      'installed': <String>[],
    },
  ];

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    final m = r.method;
    final ours =
        path.startsWith('/api/extensions/') ||
        path.startsWith('/api/magic-ext') ||
        path.startsWith('/api/setup/media');
    if (!ours) return false;
    calls.add('$m $path${r.uri.query.isEmpty ? '' : '?${r.uri.query}'}');
    Future<bool> ok(Object o, [int s = 200]) async {
      await json(s, o);
      return true;
    }

    // A skill's .zip comes as raw bytes.
    if (m == 'POST' && path == '/api/extensions/skills/import') {
      final bytes = <int>[for (final c in await r.toList()) ...c];
      imports.add(bytes);
      if (r.uri.queryParameters['replace'] != '1' && installedNames.contains('ponytail')) {
        return ok({'error': 'A skill named ponytail exists'}, 409);
      }
      installedNames.add('ponytail');
      return ok({'name': 'ponytail', 'description': 'Hair', 'replaced': false}, 201);
    }
    final export = RegExp(r'^/api/extensions/skills/([^/]+)/export$').firstMatch(path);
    if (m == 'GET' && export != null) {
      r.response.statusCode = 200;
      r.response.headers.contentType = ContentType('application', 'zip');
      r.response.add([0x50, 0x4b, 3, 4, 1, 2, 3]);
      await r.response.close();
      return true;
    }
    Object? body;
    if (m == 'POST' || m == 'PUT') {
      final text = await utf8.decodeStream(r);
      body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      bodies['$m $path'] = body;
    }
    final b = body is Json ? body : const <String, dynamic>{};

    if (m == 'GET' && path == '/api/extensions/proposals') {
      final s = r.uri.queryParameters['status'];
      return ok([
        for (final p in proposals)
          if (s == null || p['status'] == s) p,
      ]);
    }
    if (m == 'POST' && path == '/api/extensions/proposals') {
      final input = b['input'] as Json;
      installedNames.add('${input['name']}');
      return ok({'id': 'p_new', 'status': 'installed', 'name': input['name']}, 201);
    }
    final decide = RegExp(r'^/api/extensions/proposals/([^/]+)/decision$').firstMatch(path);
    if (m == 'POST' && decide != null) {
      proposals.removeWhere((p) => p['id'] == decide.group(1));
      return ok({'ok': true});
    }
    if (m == 'GET' && path == '/api/extensions/installed') {
      return ok([
        for (final n in installedNames)
          {
            'kind': 'skill',
            'name': n,
            'description': 'How we write release notes',
            'scope': 'platform',
            'path': 'skills/$n/SKILL.md',
          },
        {
          'kind': 'tool',
          'name': 'csv-chart',
          'description': 'A CSV as a chart',
          'scope': 'project:demo',
          'path': 'tools/csv-chart/tool.json',
        },
      ]);
    }
    if (m == 'GET' && RegExp(r'^/api/extensions/skills/[^/]+/versions$').hasMatch(path)) {
      return ok(<Json>[]);
    }
    if (m == 'GET' && path == '/api/extensions/mcp') return ok(mcp);
    if (m == 'GET' && path == '/api/extensions/mcp/status') return ok(status);
    if (m == 'PUT' && path == '/api/extensions/mcp') {
      mcp.removeWhere((x) => x['name'] == b['name']);
      mcp.add({'name': b['name'], 'project_id': b['projectId'], 'transport': b['transport']});
      final oauth = (b['transport'] as Json)['oauth'] == true;
      status.add({
        'name': b['name'],
        'projectId': b['projectId'],
        'state': oauth ? 'login' : 'connected',
        'tools': oauth ? 0 : 4,
      });
      return ok({'ok': true});
    }
    final login = RegExp(r'^/api/extensions/mcp/([^/]+)/login$').firstMatch(path);
    if (m == 'POST' && login != null) {
      return ok({'authorizeUrl': 'https://auth.example.com/authorize?server=${login.group(1)}'});
    }
    final remove = RegExp(r'^/api/extensions/mcp/([^/]+)$').firstMatch(path);
    if (m == 'DELETE' && remove != null) {
      mcp.removeWhere((x) => x['name'] == remove.group(1));
      status.removeWhere((x) => x['name'] == remove.group(1));
      return ok({'ok': true});
    }

    // ---- magic ----
    if (m == 'GET' && path == '/api/magic-ext') return ok(magic);
    if (m == 'POST' && path == '/api/magic-ext') {
      final made = {
        'id': 'mx_new',
        'kind': b['kind'],
        'title': 'CSV chart',
        'request': b['request'],
        'sessionId': 's1',
        'agentId': 'god',
        'status': 'building',
        'proposal': null,
        'checks': <Json>[],
        'canApprove': false,
        'installed': <String>[],
      };
      magic.insert(0, made);
      return ok(made, 201);
    }
    final one = RegExp(r'^/api/magic-ext/([^/]+)(?:/([a-z]+))?$').firstMatch(path);
    if (one != null) {
      final x = magic.where((y) => y['id'] == one.group(1)).firstOrNull;
      if (x == null) return ok({'error': 'Not found'}, 404);
      final act = one.group(2);
      if (m == 'GET' && act == null) return ok(x);
      if (m == 'DELETE') {
        magic.remove(x);
        return ok({'ok': true});
      }
      if (act == 'credential') {
        x['checks'] = [
          for (final c in x['checks'] as List) {...(c as Json), 'ok': true, 'exists': true},
        ];
        x['canApprove'] = true;
      }
      if (act == 'approve') {
        x['status'] = 'done';
        x['installed'] = ['notion-search'];
      }
      if (act == 'reject') x['status'] = 'building';
      if (act == 'uninstall') x['status'] = 'dismissed';
      return ok(x);
    }

    // ---- generation ----
    final config = setup['config'] as Json;
    final secrets = setup['secretsSet'] as Json;
    if (m == 'PUT' && path == '/api/setup/media-native') {
      config['mediaNative'] = b['on'];
      return ok({'ok': true});
    }
    final key = RegExp(r'^/api/setup/media-keys/([^/]+)$').firstMatch(path);
    if (m == 'PUT' && key != null) {
      final list = [...(secrets['media'] as List? ?? const [])];
      if (b['key'] != null) list.add(key.group(1));
      secrets['media'] = [for (final x in list) '$x'];
      return ok({'ok': true});
    }
    if (m == 'GET' && path == '/api/setup/media/voices') {
      return ok([
        {'id': 'marin', 'label': 'Marin'},
        {'id': 'cedar', 'label': 'Cedar'},
      ]);
    }
    final kind = RegExp(r'^/api/setup/media/([a-z]+)$').firstMatch(path);
    if (m == 'PUT' && kind != null) {
      final media = {...(config['media'] as Json? ?? const {})};
      if (b['choice'] == null) {
        media.remove(kind.group(1));
      } else {
        media[kind.group(1)!] = b['choice'];
      }
      config['media'] = media;
      return ok({'ok': true});
    }
    return false;
  }
}
