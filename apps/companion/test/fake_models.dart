// G42.15: the ways of thinking and the local engine in memory, answering as the real server does
// (packages/server/src/setup-routes.ts, subscriptions routes, jobs): Claude's sign-in with the
// code of the tests («good-code#abc»), ChatGPT's device code, keys tried («wrong» is refused),
// the person's own server, the backup model, the suggested local models with their files, the
// download and the engine as jobs the test moves on by hand. It changes the fake server's
// `GET /api/setup` in place.
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeModels {
  FakeModels(this.setup) {
    setup['secretsSet'] = <String, dynamic>{
      ...?(setup['secretsSet'] as Map?)?.cast<String, dynamic>(),
    };
    setup['config'] = <String, dynamic>{...(setup['config'] as Map).cast<String, dynamic>()};
    _config['subscriptions'] ??= <String, dynamic>{};
    setup['hardware'] = {
      'os': 'linux',
      'cpu': 'AMD Ryzen 9',
      'cores': 16,
      'ramGb': 64,
      'freeRamGb': 48,
      'gpus': [
        {
          'name': 'NVIDIA GeForce RTX 4080 SUPER',
          'vramGb': 16,
          'vendor': 'nvidia',
          'integrated': false,
        },
      ],
      'windowsEngine': false,
      'suggestion': {'engine': 'cuda', 'maxModelGb': 60, 'kind': 'gpu', 'vramGb': 16},
    };
  }

  final Json setup;
  final calls = <String>[];
  final bodies = <String, Object?>{};

  bool claudeOn = false;
  String? claudeEmail;
  bool chatgptOn = false;
  String? chatgptEmail;
  final jobs = <Json>[];
  final files = <Json>[];
  int _jobs = 0;

  Json get _config => setup['config'] as Json;
  Json get _secrets =>
      (setup['secretsSet'] as Json?) ?? (setup['secretsSet'] = <String, dynamic>{});
  Json get _subs => _config['subscriptions'] as Json;

  static const models = [
    {
      'id': 'qwen3-30b',
      'name': 'Qwen3 30B A3B',
      'repo': 'unsloth/Qwen3-30B-A3B-GGUF',
      'totalB': 30,
      'activeB': 3,
      'scores': {'smart': 3, 'code': 3, 'tools': 4, 'languages': 4},
      'file': {
        'file': 'Qwen3-30B-A3B-Q4_K_M.gguf',
        'sizeGb': 18.5,
        'quant': 'Q4_K_M',
        'quality': 'good',
      },
      'smallestGb': 12.0,
    },
    {
      'id': 'gemma3-12b',
      'name': 'Gemma 3 12B',
      'repo': 'unsloth/gemma-3-12b-it-GGUF',
      'totalB': 12,
      'activeB': 12,
      'scores': {'smart': 3, 'code': 2, 'tools': 3, 'languages': 5},
      'file': {
        'file': 'gemma-3-12b-it-Q4_K_M.gguf',
        'sizeGb': 7.3,
        'quant': 'Q4_K_M',
        'quality': 'good',
      },
      'smallestGb': 5.0,
    },
    {
      'id': 'mistral-medium',
      'name': 'Mistral Medium 3.5 128B',
      'repo': 'unsloth/Mistral-Medium-3.5-128B-GGUF',
      'totalB': 125,
      'activeB': 125,
      'scores': {'smart': 5, 'code': 4, 'tools': 4, 'languages': 5},
      'file': {
        'file': 'Mistral-Medium-Q3_K_M.gguf',
        'sizeGb': 58,
        'quant': 'Q3_K_M',
        'quality': 'reduced',
      },
      'smallestGb': 50.0,
    },
  ];

  Json _sub(bool on, String? email) => {
    'on': on,
    'account': email == null ? null : {'loggedIn': true, 'email': email, 'plan': 'Max'},
    'program': 'bundled',
  };

  Json addJob(String kind, String model, {String state = 'running', List<Json>? steps}) {
    final j = <String, dynamic>{
      'id': 'job${++_jobs}',
      'kind': kind,
      'state': state,
      'vars': {'model': model},
      'steps': steps ?? [],
      'createdAt': '2026-11-20T10:00:00.000Z',
    };
    jobs.add(j);
    return j;
  }

  Future<Json> _body(HttpRequest r) async {
    final t = await utf8.decodeStream(r);
    return t.isEmpty ? <String, dynamic>{} : jsonDecode(t) as Json;
  }

  Future<bool> handle(HttpRequest r, String path, Future<void> Function(int, Object) json) async {
    final m = r.method;
    final known =
        path.startsWith('/api/subscriptions/') ||
        path == '/api/setup/subscriptions' ||
        path.startsWith('/api/setup/keys/') ||
        path == '/api/setup/server' ||
        path == '/api/setup/backup-model' ||
        path.startsWith('/api/setup/local-models') ||
        path.startsWith('/api/setup/engine') ||
        path.startsWith('/api/jobs');
    if (!known) return false;
    calls.add('$m $path');
    final b = m == 'GET' || m == 'DELETE' ? <String, dynamic>{} : await _body(r);
    if (b.isNotEmpty) bodies['$m $path'] = b;
    switch ((m, path)) {
      case ('GET', '/api/subscriptions/claude'):
        await json(200, _sub(claudeOn, claudeEmail));
      case ('POST', '/api/subscriptions/claude/login'):
        await json(200, {'url': 'https://claude.ai/oauth/authorize?demo=1'});
      case ('POST', '/api/subscriptions/claude/code'):
        if (b['code'] != 'good-code#abc') {
          await json(400, {'error': 'Anthropic did not accept this code'});
        } else {
          claudeOn = true;
          claudeEmail = 'mario@example.com';
          _subs['claude'] = true;
          await json(200, {'loggedIn': true, 'email': claudeEmail, 'plan': 'Max'});
        }
      case ('POST', '/api/subscriptions/claude/logout'):
        claudeOn = false;
        claudeEmail = null;
        _subs['claude'] = false;
        await json(200, {'ok': true});
      case ('GET', '/api/subscriptions/chatgpt'):
        await json(200, _sub(chatgptOn, chatgptEmail));
      case ('POST', '/api/subscriptions/chatgpt/login'):
        await json(200, {'url': 'https://auth.openai.com/codex/device', 'code': 'WXYZ-1234'});
      case ('POST', '/api/subscriptions/chatgpt/logout'):
        chatgptEmail = null;
        await json(200, {'ok': true});
      case ('PUT', '/api/setup/subscriptions'):
        if (b.containsKey('ack')) _config['subscriptionAck'] = b['ack'];
        if (b['chatgpt'] is bool) {
          chatgptOn = b['chatgpt'] as bool;
          _subs['chatgpt'] = chatgptOn;
        }
        if (b['claude'] is Map) {
          claudeOn = true;
          _subs['claude'] = true;
        }
        await json(200, {'ok': true});
      case ('PUT', '/api/setup/server'):
        final url = '${b['baseUrl']}';
        if (!url.startsWith('http')) {
          await json(400, {'error': 'Nothing answered at $url'});
        } else {
          _config['server'] = {'baseUrl': url};
          if (b['key'] != null) _secrets['server'] = true;
          await json(200, {
            'models': ['qwen3-8b', 'llama-4'],
          });
        }
      case ('DELETE', '/api/setup/server'):
        _config.remove('server');
        _secrets['server'] = false;
        await json(200, {'ok': true});
      case ('PUT', '/api/setup/backup-model'):
        if (b['model'] == null) {
          _config.remove('backupModel');
        } else {
          _config['backupModel'] = b['model'];
        }
        await json(200, {'ok': true});
      case ('GET', '/api/setup/local-models'):
        await json(200, {'models': models, 'files': files, 'diskFreeGb': 400});
      case ('POST', '/api/setup/local-models/download'):
        final name = '${b['file']}'.split('/').last;
        final j = addJob(
          'model_download',
          name,
          steps: [
            {
              'id': 'model_download',
              'state': 'running',
              'progress': {'done': 0, 'total': 18500000000},
            },
          ],
        );
        await json(200, j);
      case ('GET', '/api/jobs'):
        await json(200, jobs);
      case ('PUT', '/api/setup/engine'):
        final e = b['engine'];
        if (e == null) {
          _config.remove('engine');
          await json(200, <String, dynamic>{});
        } else {
          _config['engine'] = {'variant': (e as Map)['variant'], 'model': e['model']};
          await json(200, addJob('engine', '${e['model']}', state: 'done'));
        }
      case ('PUT', '/api/setup/engine/power'):
        final e = _config['engine'] as Json?;
        if (e != null) e['off'] = b['on'] != true;
        await json(200, <String, dynamic>{});
      case ('POST', '/api/setup/engine/speed-test'):
        final e = (b['engine'] as Map).cast<String, dynamic>();
        await json(
          200,
          addJob('speed_test', '${e['model']}', state: 'done')
            ..['vars'] = {
              'model': e['model'],
              'trials': jsonEncode([
                {'mode': 'none', 'state': 'done', 'proseTps': 42, 'codeTps': 40},
                {'mode': 'ngram', 'state': 'done', 'proseTps': 50, 'codeTps': 71},
              ]),
            },
        );
      default:
        final key = RegExp(r'^/api/setup/keys/([a-z]+)$').firstMatch(path);
        if (key != null && m == 'PUT') {
          if ('${b['key']}'.contains('wrong')) {
            await json(400, {'error': '${key.group(1)}: HTTP 401'});
          } else {
            final keys = [...(_secrets['keys'] as List? ?? const [])];
            if (!keys.contains(key.group(1))) keys.add(key.group(1));
            _secrets['keys'] = keys;
            await json(200, {
              'models': ['${key.group(1)}-large', '${key.group(1)}-small'],
            });
          }
          return true;
        }
        if (key != null && m == 'DELETE') {
          _secrets['keys'] = [...(_secrets['keys'] as List? ?? const [])]..remove(key.group(1));
          await json(200, {'ok': true});
          return true;
        }
        final file = RegExp(r'^/api/setup/local-models/([^/]+)$').firstMatch(path);
        if (file != null && m == 'DELETE') {
          files.removeWhere((f) => f['file'] == Uri.decodeComponent(file.group(1)!));
          await json(200, {'ok': true});
          return true;
        }
        final cancel = RegExp(r'^/api/jobs/([^/]+)/cancel$').firstMatch(path);
        if (cancel != null && m == 'POST') {
          for (final j in jobs) {
            if (j['id'] == cancel.group(1)) j['state'] = 'cancelled';
          }
          await json(200, {'ok': true});
          return true;
        }
        final one = RegExp(r'^/api/jobs/([^/]+)$').firstMatch(path);
        if (one != null && m == 'GET') {
          final j = jobs.where((x) => x['id'] == one.group(1)).firstOrNull;
          await json(j == null ? 404 : 200, j ?? {'error': 'No such job'});
          return true;
        }
        return false;
    }
    return true;
  }
}
