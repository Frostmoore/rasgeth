// G42.17: the routes of the setup wizard, the imports, the external agents, the history of
// changes and the full-text search, answering on the fake Rasgeth as the real server does
// (app.ts): the same shapes, the same refusals (a variable that holds a secret, a promote without
// a supervisor), the setup's state changing with what the wizard saves.
import 'dart:convert';
import 'dart:io';

import 'fake_server.dart';

typedef Json = Map<String, dynamic>;

class FakeSetup {
  FakeSetup(this.server) {
    final r = server.routes;
    final config = server.setup['config'] as Json;
    server.setup['hardware'] = {
      'cpu': 'AMD Ryzen 9 9900X',
      'cores': 12,
      'ramGb': 64,
      'gpus': [],
      'diskFreeGb': 812,
    };
    server.setup['offer'] = {'local': true};
    server.setup['policy'] = {
      'humanOnly': ['platform', 'secrets-files'],
      'guardian': 'ask',
    };
    Future<Json> body(HttpRequest q) async {
      final t = await utf8.decodeStream(q);
      return t.isEmpty ? {} : (jsonDecode(t) as Json);
    }

    Future<void> ok(HttpRequest q, [Object v = const {'ok': true}]) => server.answer(q, 200, v);
    r['GET /api/auth/methods'] = (q) => ok(q, {'password': true, 'code': false});
    r['PUT /api/setup/languages'] = (q) async {
      final b = await body(q);
      saved.add('languages ${b['language']}');
      return ok(q);
    };
    r['PUT /api/setup/names'] = (q) async {
      final b = await body(q);
      server.setup['names'] = {'god': b['god'], 'demigod': b['demigod']};
      saved.add('names ${b['god']} ${b['demigod']}');
      return ok(q);
    };
    r['PUT /api/setup/mode'] = (q) async {
      config['mode'] = (await body(q))['mode'];
      saved.add('mode ${config['mode']}');
      return ok(q);
    };
    r['PUT /api/setup/interface'] = (q) async {
      config['ui'] = (await body(q))['ui'];
      saved.add('interface ${config['ui']}');
      return ok(q);
    };
    r['PUT /api/setup/role'] = (q) async {
      config['role'] = (await body(q))['role'];
      return ok(q);
    };
    r['PUT /api/setup/safety'] = (q) async {
      final b = await body(q);
      (server.setup['policy'] as Json)['humanOnly'] = b['humanOnly'];
      saved.add('safety ${(b['humanOnly'] as List).length}');
      return ok(q);
    };
    r['POST /api/setup/complete'] = (q) async {
      config['completed'] = true;
      saved.add('complete');
      return ok(q);
    };
    // ---- the setup code (a first start, no password yet) ----
    server.tokens.addAll(['rgs_session', 'rgd_setup']);
    server.openRoutes['POST /api/auth/setup-code'] = (q) async {
      final b = await body(q);
      if (b['code'] != '482913')
        return server.answer(q, 401, {'error': 'Wrong code', 'code': 'wrong'});
      return ok(q, {'token': 'rgs_session'});
    };
    r['POST /api/devices'] = (q) async {
      if (q.headers.value('authorization') != 'Bearer rgs_session') {
        return server.answer(q, 403, {'error': 'A device cannot make another', 'code': 'device'});
      }
      final b = await body(q);
      saved.add('device ${b['platform']}');
      return ok(q, {
        'token': 'rgd_setup',
        'device': {
          'id': 'd9',
          'name': b['name'],
          'platform': b['platform'],
          'createdAt': '2026-11-21T10:00:00.000Z',
          'lastUsedAt': null,
        },
      });
    };
    // ---- search ----
    r['GET /api/search'] = (q) => ok(q, [
      if ((q.uri.queryParameters['q'] ?? '').contains('lavatrice'))
        {
          'kind': 'session',
          'id': 's1',
          'agentId': 'a0',
          'projectId': null,
          'title': 'Garanzia',
          'at': '2026-11-20T10:00:00.000Z',
          'excerpt': 'la garanzia della lavatrice dura due anni',
        },
    ]);
    // ---- platform ----
    r['GET /api/platform'] = (q) => ok(q, {
      'sandbox': 'host',
      'metal': false,
      'codeChanges': true,
      'supervised': false,
      'lastGood': null,
      'releases': [],
    });
    r['GET /api/platform/changes'] = (q) => ok(q, changes);
    r['POST /api/platform/changes/c1/undo'] = (q) async {
      changes.first['stage'] = 'undone';
      saved.add('undo c1');
      return ok(q, changes.first);
    };
    r['POST /api/platform/changes/k1/discard'] = (q) async {
      changes.last['stage'] = 'discarded';
      saved.add('discard k1');
      return ok(q, changes.last);
    };
    // ---- external agents ----
    r['GET /api/acp/workers'] = (q) => ok(q, {
      'workers': workers,
      'presets': [
        {
          'id': 'claude-code',
          'name': 'Claude Code',
          'command': 'npx',
          'args': ['-y', '@agentclientprotocol/claude-agent-acp'],
        },
        {
          'id': 'gemini',
          'name': 'Gemini CLI',
          'command': 'gemini',
          'args': ['--acp'],
        },
      ],
    });
    r['POST /api/acp/try'] = (q) async {
      final b = await body(q);
      if ((b['env'] as Map? ?? {}).keys.any((k) => '$k'.contains('KEY'))) {
        return server.answer(q, 400, {
          'error': 'A variable may not hold a secret',
          'code': 'acp_env',
        });
      }
      return ok(q, {
        'name': 'gemini-cli',
        'version': '1.2',
        'loadSession': true,
        'signIn': ['oauth'],
      });
    };
    r['POST /api/acp/workers'] = (q) async {
      final b = await body(q);
      workers.add({...b, 'agentId': 'acp${workers.length + 1}', 'status': 'active'});
      return ok(q, workers.last);
    };
    // ---- import ----
    r['POST /api/import/scan'] = (q) async {
      final b = await body(q);
      saved.add('scan home=${b['home']} projects=${b['projects']}');
      if (b['claudeProjects'] == true) saved.add('scan claude projects');
      return ok(q, preview);
    };
    r['POST /api/import/apply'] = (q) async {
      final b = await body(q);
      applied = (b['choices'] as List).cast<Json>();
      return ok(q, {'id': 'j1', 'kind': 'import', 'state': 'running', 'steps': []});
    };
    r['GET /api/jobs/j1'] = (q) => ok(q, {
      'id': 'j1',
      'kind': 'import',
      'state': 'done',
      'steps': [],
      'result': {
        'id': 'i1',
        'createdAt': '2026-11-21T09:00:00.000Z',
        'sources': ['claude-code'],
        'done': [
          for (final c in applied ?? const <Json>[])
            {
              'itemId': c['id'],
              'kind': c['id'] == 'it2' ? 'skill' : 'instructions',
              'name': '${c['id']}',
              'ok': true,
            },
        ],
        'undoneAt': null,
      },
    });
    r['GET /api/import/history'] = (q) => ok(q, [
      if (applied != null)
        {
          'id': 'i1',
          'createdAt': '2026-11-21T09:00:00.000Z',
          'sources': ['claude-code'],
          'done': [
            for (final c in applied!)
              {'itemId': c['id'], 'kind': 'skill', 'name': '${c['id']}', 'ok': true},
          ],
          'undoneAt': undone ? '2026-11-21T09:05:00.000Z' : null,
        },
    ]);
    r['POST /api/import/i1/undo'] = (q) async {
      undone = true;
      saved.add('import undo');
      return ok(q, {
        'id': 'i1',
        'createdAt': '2026-11-21T09:00:00.000Z',
        'sources': ['claude-code'],
        'done': [],
        'undoneAt': '2026-11-21T09:05:00.000Z',
      });
    };
  }

  final FakeRedGiant server;
  final saved = <String>[];
  List<Json>? applied;
  bool undone = false;
  final workers = <Json>[
    {
      'agentId': 'acp0',
      'name': 'Codex',
      'projectId': null,
      'status': 'stopped',
      'command': 'npx',
      'args': ['-y', '@agentclientprotocol/codex-acp'],
      'env': {},
    },
  ];
  final changes = <Json>[
    {
      'id': 'c1',
      'kind': 'config',
      'change': 'raw',
      'stage': 'promoted',
      'target': 'budget:global:me',
      'before': {'usd': 5},
      'after': {'usd': 20},
      'detail': null,
      'by': 'human',
      'createdAt': '2026-11-20T10:00:00.000Z',
      'updatedAt': '2026-11-20T10:00:00.000Z',
    },
    {
      'id': 'k1',
      'kind': 'code',
      'change': 'A clearer bar',
      'stage': 'tested',
      'target': null,
      'before': null,
      'after': null,
      'detail': 'diff --git a b',
      'by': 'a0',
      'createdAt': '2026-11-20T11:00:00.000Z',
      'updatedAt': '2026-11-20T11:30:00.000Z',
    },
  ];
  final Json preview = {
    'id': 'u1',
    'read': 4,
    'unreadable': [],
    'left': [
      {'from': '~/.claude/settings.json', 'what': 'hooks'},
    ],
    'items': [
      {
        'id': 'itp',
        'kind': 'project',
        'source': 'claude-code',
        'from': '/home/ana/code/site',
        'name': 'site',
        'preview': '# Site',
        'on': false,
        'notes': [
          {'code': 'secrets-out', 'arg': '1'},
        ],
        'project': {
          'path': '/home/ana/code/site',
          'remote': 'https://git.home.lan/ana/site.git',
          'git': true,
          'instructions': ['CLAUDE.md'],
          'notes': 3,
          'memory': 2,
          'conversations': 4,
          'secrets': ['.env'],
          'machine': [
            {'file': 'CLAUDE.md', 'line': 2, 'text': 'Deploy with ssh web1.', 'why': 'ssh'},
          ],
          'bytes': 5000000,
          'modes': ['adopt', 'copy', 'clone'],
        },
      },
      {
        'id': 'it1',
        'kind': 'instructions',
        'source': 'claude-code',
        'from': '~/.claude/CLAUDE.md',
        'name': 'CLAUDE.md',
        'preview': 'Always answer in Italian.',
        'on': true,
        'notes': [],
      },
      {
        'id': 'it2',
        'kind': 'skill',
        'source': 'codex',
        'from': '~/.codex/prompts/review.md',
        'name': 'review',
        'preview': 'Review the diff',
        'on': true,
        'notes': [
          {'code': 'as-skill'},
        ],
      },
      {
        'id': 'it3',
        'kind': 'mcp',
        'source': 'cursor',
        'from': '~/.cursor/mcp.json',
        'name': 'github',
        'preview': 'npx github-mcp',
        'exists': 'same',
        'on': false,
        'notes': [],
      },
    ],
  };
}
