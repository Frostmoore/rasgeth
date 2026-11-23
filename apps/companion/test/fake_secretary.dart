// 3.12.4: the secretary's routes in memory, answering as packages/server/src/app.ts does: accounts,
// contacts, ready replies (approve/refuse), the guides' checks and the WhatsApp account made before
// Meta calls. Keys go in and never come out.
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeSecretary {
  final calls = <String>[];
  final bodies = <String, Object?>{};
  bool remoteOk = false;
  bool tokenOk = true;
  bool webhookOk = false;
  final accounts = <Json>[];
  final pending = <Json>[
    {
      'id': 'p1',
      'contactId': 'c1',
      'contactName': 'Luca',
      'channel': 'whatsapp',
      'reason': 'commitment',
      'summary': 'Wants a table for 4 on Friday',
      'draft': 'Friday at 8 is fine.',
      'status': 'open',
    },
  ];
  final contacts = <Json>[
    {
      'id': 'c1',
      'accountId': 'a1',
      'channel': 'whatsapp',
      'handle': '393331112222',
      'name': 'Luca',
      'notes': '',
      'paused': false,
      'stopped': false,
      'unread': 2,
      'lastText': 'Can you fix my car?',
      'windowOpen': true,
      'pending': 1,
    },
  ];

  Future<Json> _body(HttpRequest r) async {
    final s = await utf8.decoder.bind(r).join();
    return s.isEmpty ? <String, dynamic>{} : jsonDecode(s) as Json;
  }

  Future<bool> handle(HttpRequest r, String path, Future<void> Function(int, Object) json) async {
    if (!path.startsWith('/api/secretary/')) return false;
    final m = r.method;
    calls.add('$m $path');
    if (path == '/api/secretary/accounts' && m == 'GET') {
      await json(200, {'accounts': accounts});
      return true;
    }
    if (path == '/api/secretary/contacts' && m == 'GET') {
      await json(200, {
        'contacts': contacts,
        'pending': pending.where((p) => p['status'] == 'open').toList(),
      });
      return true;
    }
    if (path == '/api/secretary/check' && m == 'POST') {
      final b = await _body(r);
      bodies[path] = b;
      if (b['step'] == 'remote') {
        await json(
          200,
          remoteOk
              ? {'ok': true, 'code': 'ok', 'detail': 'https://rg.example.test'}
              : {'ok': false, 'code': 'no_remote'},
        );
      } else if (!tokenOk) {
        await json(200, {'ok': false, 'code': 'bad_token'});
      } else if (b['channel'] == 'telegram') {
        await json(200, {'ok': true, 'code': 'ok', 'username': 'salone_bot'});
      } else {
        await json(200, {
          'ok': true,
          'code': 'ok',
          'number': '+39 333 1234567',
          'verifiedName': 'Salone',
        });
      }
      return true;
    }
    if (path == '/api/secretary/whatsapp/start' && m == 'POST') {
      final a = {
        'id': 'a2',
        'channel': 'whatsapp',
        'name': '',
        'agentId': null,
        'label': 'WhatsApp Business',
        'webhookUrl': 'https://rg.example.test/api/secretary/whatsapp/a2/webhook',
        'verifyToken': 'verify-token-123',
        'webhookOk': false,
        'complete': false,
        'limitPerHour': 6,
      };
      accounts.add(a);
      await json(201, a);
      return true;
    }
    final finish = RegExp(r'^/api/secretary/whatsapp/([^/]+)/finish$').firstMatch(path);
    if (finish != null && m == 'POST') {
      bodies[path] = await _body(r);
      final a = accounts.firstWhere((x) => x['id'] == finish.group(1));
      a['complete'] = true;
      a['label'] = '+39 333 1234567';
      await json(200, a);
      return true;
    }
    if (path == '/api/secretary/telegram' && m == 'POST') {
      bodies[path] = await _body(r);
      accounts.add({
        'id': 'a3',
        'channel': 'telegram',
        'name': '',
        'label': '@salone_bot',
        'webhookOk': true,
        'complete': true,
        'limitPerHour': 6,
      });
      await json(201, accounts.last);
      return true;
    }
    final act = RegExp(r'^/api/secretary/pending/([^/]+)/(approve|refuse)$').firstMatch(path);
    if (act != null && m == 'POST') {
      bodies[path] = await _body(r);
      pending.firstWhere((p) => p['id'] == act.group(1))['status'] = act.group(2) == 'approve'
          ? 'sent'
          : 'refused';
      await json(200, {'ok': true});
      return true;
    }
    final one = RegExp(r'^/api/secretary/contacts/([^/]+)$').firstMatch(path);
    if (one != null) {
      final c = contacts.firstWhere((x) => x['id'] == one.group(1));
      if (m == 'GET') {
        await json(200, {
          'contact': c,
          'messages': [
            {'id': 1, 'dir': 'in', 'by': 'contact', 'text': 'Can you fix my car?'},
          ],
          'pending': pending.where((p) => p['status'] == 'open').toList(),
        });
        return true;
      }
      if (m == 'PATCH') {
        final b = await _body(r);
        bodies[path] = b;
        c.addAll(b);
        await json(200, {'ok': true});
        return true;
      }
    }
    await json(404, {'error': 'No such secretary route'});
    return true;
  }
}
