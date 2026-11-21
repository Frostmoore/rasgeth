// G42.12: Settings › Keychain against an in-memory server answering as app.ts does: the keychain's
// view (the person's credentials, one a part of the server uses, the keys it keeps elsewhere, the
// uses), adding, changing and deleting (refused for an entry in use, as the server does), a value
// shown only on request (each reveal counted), a CSV's preview and its confirmation, the sealed
// export and import, and the browsers with their code.
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeVault {
  final calls = <String>[];
  final bodies = <String, Object?>{};
  int reveals = 0;
  bool ready = true;

  final entries = <Json>[
    {
      'id': 'v1',
      'name': 'revolut_api',
      'service': 'Revolut Business',
      'category': 'bank',
      'tags': ['work'],
      'username': 'office@example.com',
      'url': 'https://b2b.revolut.com/api/1.0',
      'hosts': ['b2b.revolut.com'],
      'notes': '',
      'expires': null,
      'ask': 'session',
      'allow': {
        'allAgents': true,
        'agents': <String>[],
        'tools': <String>[],
        'automations': <String>[],
      },
      'inject': {'header': 'Authorization', 'format': 'Bearer {value}'},
      'length': 32,
      'createdAt': '2026-11-01T10:00:00.000Z',
      'updatedAt': '2026-11-01T10:00:00.000Z',
      'lastUsedAt': '2026-11-20T09:30:00.000Z',
      'uses': 3,
    },
    {
      'id': 'v2',
      'name': 'anthropic',
      'service': 'Anthropic',
      'category': 'api',
      'tags': <String>[],
      'username': '',
      'url': '',
      'hosts': ['api.anthropic.com'],
      'notes': '',
      'expires': '2026-11-30T12:00:00.000Z',
      'ask': 'never',
      'allow': {
        'allAgents': true,
        'agents': <String>[],
        'tools': <String>[],
        'automations': <String>[],
      },
      'inject': {'header': 'x-api-key', 'format': '{value}'},
      'length': 40,
      'createdAt': '2026-11-01T10:00:00.000Z',
      'updatedAt': '2026-11-01T10:00:00.000Z',
      'lastUsedAt': null,
      'uses': 0,
      'usedBy': {
        'key': 'setup:keys.anthropic',
        'section': 'subscriptions',
        'kind': 'provider',
        'what': 'Anthropic',
      },
    },
  ];
  final system = <Json>[
    {
      'id': 's1',
      'service': 'Telegram',
      'category': 'other',
      'section': 'telegram',
      'what': 'the bot',
      'kind': 'chat',
    },
    {
      'id': 's2',
      'service': 'OpenAI',
      'category': 'api',
      'section': 'subscriptions',
      'what': 'images',
      'kind': 'provider',
      'locked': true,
    },
  ];
  final uses = <Json>[
    {
      'id': 'u1',
      'entryId': 'v1',
      'name': 'revolut_api',
      'at': '2026-11-20T09:30:00.000Z',
      'agentId': 'a1',
      'agentName': 'Coder',
      'sessionId': 'sx',
      'tool': 'use_credential',
      'host': 'b2b.revolut.com',
      'method': 'GET',
      'outcome': 'used',
    },
    {
      'id': 'u2',
      'entryId': 'v1',
      'name': 'revolut_api',
      'at': '2026-11-20T09:10:00.000Z',
      'agentId': 'a1',
      'agentName': 'Coder',
      'sessionId': 'sx',
      'tool': 'use_credential',
      'host': 'evil.example.com',
      'method': 'POST',
      'outcome': 'refused',
      'reason': 'Not an allowed address',
    },
  ];
  final browsers = <Json>[
    {
      'id': 'b1',
      'name': 'Opera on the desk',
      'browser': 'opera',
      'createdAt': '2026-11-10T10:00:00.000Z',
      'lastSeenAt': '2026-11-20T08:00:00.000Z',
    },
  ];

  Future<bool> handle(
    HttpRequest r,
    String path,
    Future<void> Function(int status, Object body) json,
  ) async {
    if (!path.startsWith('/api/vault')) return false;
    final m = r.method;
    calls.add('$m $path');
    Object? body;
    if (m == 'POST' || m == 'PUT') {
      final text = await utf8.decodeStream(r);
      body = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
      bodies['$m $path'] = body;
    }
    final b = body is Json ? body : const <String, dynamic>{};
    Future<bool> ok(Object o, [int s = 200]) async {
      await json(s, o);
      return true;
    }

    if (m == 'GET' && path == '/api/vault') {
      return ok({
        'ready': ready,
        if (!ready) 'reason': 'Its folder is inside a git repository.',
        'protection': ready ? 'file' : null,
        'entries': ready ? entries : <Json>[],
        'system': ready ? system : <Json>[],
        'uses': ready ? uses : <Json>[],
        'proxy': true,
      });
    }
    if (m == 'POST' && path == '/api/vault') {
      final e = {
        ...b,
        'id': 'v${entries.length + 1}',
        'length': '${b['value'] ?? ''}'.length,
        'lastUsedAt': null,
        'uses': 0,
      }..remove('value');
      entries.add(e);
      return ok(e, 201);
    }
    final reveal = RegExp(r'^/api/vault/([^/]+)/reveal$').firstMatch(path);
    if (m == 'POST' && reveal != null) {
      reveals++;
      return ok({'value': 'rv-secret-${reveal.group(1)}'});
    }
    final one = RegExp(r'^/api/vault/([^/]+)$').firstMatch(path);
    if (one != null) {
      final e = entries.where((x) => x['id'] == one.group(1)).firstOrNull;
      if (e == null) return ok({'error': 'Not found'}, 404);
      if (m == 'PUT') {
        e.addAll({...b}..remove('value'));
        return ok(e);
      }
      if (m == 'DELETE') {
        if (e['usedBy'] != null) return ok({'error': 'In use: remove it from its page'}, 409);
        entries.remove(e);
        return ok({'ok': true});
      }
    }
    if (m == 'POST' && path == '/api/vault-import/preview') {
      if (!'${b['csv']}'.contains(',')) return ok({'error': 'Not a CSV'}, 400);
      return ok({
        'id': 'imp1',
        'format': 'bitwarden',
        'skipped': 1,
        'rows': [
          {
            'service': 'Gmail',
            'username': 'me@example.com',
            'url': '',
            'notes': '',
            'length': 12,
            'name': 'gmail',
            'exists': false,
          },
          {
            'service': 'GitHub',
            'username': 'me',
            'url': 'https://github.com',
            'notes': '',
            'length': 20,
            'name': 'github',
            'exists': false,
          },
          {
            'service': 'Bank',
            'username': '',
            'url': 'https://bank.example',
            'notes': '',
            'length': 8,
            'name': 'bank',
            'exists': true,
          },
        ],
      });
    }
    if (m == 'POST' && path == '/api/vault-import/confirm') {
      return ok({'added': (b['keep'] as List).length});
    }
    if (m == 'POST' && path == '/api/vault-export') {
      return ok({'file': 'REDGIANT-KEYCHAIN 1\nsealed-bytes'});
    }
    if (m == 'POST' && path == '/api/vault-import/sealed') {
      if (b['passphrase'] != 'right-pass') return ok({'error': 'Wrong passphrase'}, 400);
      return ok({'added': 2});
    }
    if (m == 'GET' && path == '/api/vault-browsers') return ok(browsers);
    if (m == 'POST' && path == '/api/vault-browsers/code') {
      return ok({
        'code': 'K7Q-4ZP',
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)).toUtc().toIso8601String(),
      });
    }
    final unlink = RegExp(r'^/api/vault-browsers/([^/]+)$').firstMatch(path);
    if (m == 'DELETE' && unlink != null) {
      browsers.removeWhere((x) => x['id'] == unlink.group(1));
      return ok({'ok': true});
    }
    return false;
  }
}
