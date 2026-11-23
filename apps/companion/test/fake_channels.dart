// G42.13: Telegram, the other chats and the mailboxes in memory, answering as the real server
// does (packages/server/src/setup-routes.ts, telegram/chats routes, app.ts `/api/settings/email`
// and `/api/settings/mailboxes`): the same shapes, a refused token or password with its message,
// passwords never sent back. It changes the fake server's `GET /api/setup` (`secretsSet`).
import 'dart:convert';
import 'dart:io';

typedef Json = Map<String, dynamic>;

class FakeChannels {
  FakeChannels(this.setup) {
    // The fake server's literal has a narrower type: a map of anything from here on.
    setup['secretsSet'] = <String, dynamic>{
      ...?(setup['secretsSet'] as Map?)?.cast<String, dynamic>(),
    };
  }

  /// The fake server's `GET /api/setup`, changed in place.
  final Json setup;

  final calls = <String>[];
  final bodies = <String, Object?>{};

  String? telegramToken;
  final telegramLinks = <Json>[];
  final chatSettings = <String, Map<String, String>>{};
  final chatLinks = <String, List<Json>>{};
  Json? single;
  final boxes = <Json>[];

  /// 3.12.3: the calendars (never their secrets) and the chats linked.
  final calendars = <Json>[];
  final passwords = <String, String>{};
  int _ids = 0;

  Json get _secrets =>
      (setup['secretsSet'] as Json?) ?? (setup['secretsSet'] = <String, dynamic>{});

  void _sync() {
    _secrets['telegram'] = telegramToken != null;
    _secrets['chats'] = chatSettings.keys.toList();
  }

  /// Someone presses Start in Telegram (the bot links them).
  void linkTelegram(int id, String username) => telegramLinks.add({
    'userId': id,
    'chatId': id,
    'username': username,
    'linkedAt': '2026-11-20T10:00:00.000Z',
  });

  /// Someone sends the code from a chat.
  void linkChat(String p, String id, String? username) => (chatLinks[p] ??= []).add({
    'userId': id,
    'username': username,
    'linkedAt': '2026-11-20T10:00:00.000Z',
  });

  Future<Json> _body(HttpRequest r) async {
    final t = await utf8.decodeStream(r);
    return t.isEmpty ? <String, dynamic>{} : jsonDecode(t) as Json;
  }

  Json _box(Json b) => {
    'id': b['id'],
    'name': b['name'],
    'category': b['category'],
    'host': b['host'],
    'port': b['port'],
    'secure': b['secure'],
    'user': b['user'],
    if (b['smtp'] != null) 'smtp': b['smtp'],
    'agents': b['agents'] == true,
  };

  Future<bool> handle(HttpRequest r, String path, Future<void> Function(int, Object) json) async {
    final m = r.method;
    final known =
        path == '/api/setup/telegram' ||
        path.startsWith('/api/telegram/') ||
        path.startsWith('/api/setup/chats/') ||
        path.startsWith('/api/chats/') ||
        path == '/api/settings/email' ||
        path.startsWith('/api/settings/mailboxes') ||
        path == '/api/connections/options' ||
        path.startsWith('/api/settings/calendars');
    if (!known) return false;
    calls.add('$m $path');
    if (path == '/api/setup/telegram' && m == 'PUT') {
      final b = await _body(r);
      bodies[path] = b;
      final token = b['token'] as String?;
      if (token != null && token.contains('wrong')) {
        await json(400, {'error': 'Telegram did not accept this token'});
        return true;
      }
      telegramToken = token;
      _sync();
      await json(200, token == null ? <String, dynamic>{} : {'username': 'rasgeth_bot'});
      return true;
    }
    if (path == '/api/telegram/pair' && m == 'POST') {
      await json(200, {
        'code': 'K7Q2',
        'expiresAt': '2026-11-20T10:10:00.000Z',
        'bot': 'rasgeth_bot',
        'link': 'https://t.me/rasgeth_bot',
      });
      return true;
    }
    if (path == '/api/telegram/links' && m == 'GET') {
      await json(200, telegramLinks);
      return true;
    }
    final tgOne = RegExp(r'^/api/telegram/links/(\d+)$').firstMatch(path);
    if (tgOne != null && m == 'DELETE') {
      telegramLinks.removeWhere((x) => '${x['userId']}' == tgOne.group(1));
      await json(200, {'ok': true});
      return true;
    }
    final setupChat = RegExp(r'^/api/setup/chats/([a-z]+)$').firstMatch(path);
    if (setupChat != null && m == 'PUT') {
      final p = setupChat.group(1)!;
      final b = await _body(r);
      bodies[path] = b;
      final s = b['settings'];
      if (s == null) {
        chatSettings.remove(p);
        chatLinks.remove(p);
      } else {
        final values = (s as Map).cast<String, dynamic>();
        if (values.values.any((v) => '$v'.contains('wrong'))) {
          await json(400, {'error': '${p[0].toUpperCase()}${p.substring(1)} refused the token'});
          return true;
        }
        chatSettings[p] = {for (final e in values.entries) e.key: '${e.value}'};
      }
      _sync();
      await json(200, {'ok': true});
      return true;
    }
    final pair = RegExp(r'^/api/chats/([a-z]+)/pair$').firstMatch(path);
    if (pair != null && m == 'POST') {
      await json(200, {'code': 'P9X4', 'expiresAt': '2026-11-20T10:10:00.000Z'});
      return true;
    }
    final links = RegExp(r'^/api/chats/([a-z]+)/links$').firstMatch(path);
    if (links != null && m == 'GET') {
      await json(200, chatLinks[links.group(1)] ?? const []);
      return true;
    }
    final link = RegExp(r'^/api/chats/([a-z]+)/links/([^/]+)$').firstMatch(path);
    if (link != null && m == 'DELETE') {
      chatLinks[link.group(1)]?.removeWhere(
        (x) => x['userId'] == Uri.decodeComponent(link.group(2)!),
      );
      await json(200, {'ok': true});
      return true;
    }
    if (path == '/api/chats/teams/app.zip' && m == 'GET') {
      r.response.headers.contentType = ContentType('application', 'zip');
      r.response.add(List<int>.filled(32, 1));
      await r.response.close();
      return true;
    }
    if (path == '/api/settings/email') {
      if (m == 'GET') {
        final s = single;
        await json(
          200,
          s == null ? {'configured': false} : {'configured': true, ...s}
            ..remove('password'),
        );
        return true;
      }
      if (m == 'PUT') {
        final b = await _body(r);
        bodies[path] = b;
        if ('${b['password']}'.contains('wrong')) {
          await json(400, {'error': 'The mailbox refused the user or the password'});
          return true;
        }
        single = {'host': b['host'], 'port': b['port'], 'secure': b['secure'], 'user': b['user']};
        await json(200, {'ok': true});
        return true;
      }
      if (m == 'DELETE') {
        single = null;
        await json(200, {'ok': true});
        return true;
      }
    }
    // 3.12.3: what an agent may be connected to, as `GET /api/connections/options` says it.
    if (path == '/api/connections/options' && m == 'GET') {
      await json(200, {
        'mailboxes': [
          for (final b in boxes)
            if (b['agents'] == true) {'id': b['id'], 'name': b['name'], 'address': b['user']},
        ],
        'chats': [
          if (telegramLinks.isNotEmpty) 'telegram',
          for (final e in chatLinks.entries)
            if (e.value.isNotEmpty) e.key,
        ],
        'calendars': [
          for (final c in calendars)
            if (c['agents'] == true) {'id': c['id'], 'name': c['name'], 'writable': c['writable']},
        ],
        'mcp': <String>[],
      });
      return true;
    }
    if (path == '/api/settings/calendars') {
      if (m == 'GET') {
        await json(200, {'calendars': calendars});
        return true;
      }
      if (m == 'POST') {
        final b = await _body(r);
        bodies['POST $path'] = b;
        if ('${b['password']}'.contains('wrong')) {
          await json(400, {'error': 'The server refused the user or the password'});
          return true;
        }
        final host = Uri.tryParse('${b['url']}')?.host ?? '';
        final ics = b['kind'] == 'ics';
        final c = {
          'id': 'cal_${++_ids}',
          'name': '${b['name']}'.isEmpty ? host : b['name'],
          'kind': b['kind'],
          'url': ics ? host : b['url'],
          if (!ics) 'user': b['user'],
          'writable': !ics,
          if (b['agents'] == true) 'agents': true,
          'createdAt': '2026-11-23T10:00:00.000Z',
        };
        calendars.add(c);
        await json(201, c);
        return true;
      }
    }
    final calOne = RegExp(r'^/api/settings/calendars/([^/]+)$').firstMatch(path);
    if (calOne != null) {
      final id = calOne.group(1);
      if (m == 'PUT') {
        final b = await _body(r);
        bodies['PUT $path'] = b;
        final c = calendars.firstWhere((x) => x['id'] == id);
        if (b['name'] is String) c['name'] = b['name'];
        if (b['agents'] == true) {
          c['agents'] = true;
        } else if (b.containsKey('agents')) {
          c.remove('agents');
        }
        await json(200, c);
        return true;
      }
      if (m == 'DELETE') {
        calendars.removeWhere((x) => x['id'] == id);
        await json(200, {'ok': true});
        return true;
      }
    }
    if (path == '/api/settings/mailboxes') {
      if (m == 'GET') {
        final cats = {
          ...['work', 'personal', 'social', 'other'],
          for (final b in boxes) b['category'] as String,
        };
        await json(200, {
          'boxes': [for (final b in boxes) _box(b)],
          'categories': cats.toList(),
        });
        return true;
      }
      if (m == 'POST') {
        final b = await _body(r);
        bodies['POST $path'] = b;
        if ('${b['password']}'.contains('wrong')) {
          await json(400, {'error': 'The mailbox refused the user or the password'});
          return true;
        }
        final id = 'mb${++_ids}';
        passwords[id] = '${b['password']}';
        final box = {...b, 'id': id}..remove('password');
        boxes.add(box);
        await json(200, _box(box));
        return true;
      }
    }
    final one = RegExp(r'^/api/settings/mailboxes/([^/]+)$').firstMatch(path);
    if (one != null) {
      final id = Uri.decodeComponent(one.group(1)!);
      final i = boxes.indexWhere((b) => b['id'] == id);
      if (i < 0) {
        await json(404, {'error': 'No such mailbox'});
        return true;
      }
      if (m == 'PUT') {
        final b = await _body(r);
        bodies['PUT $path'] = b;
        if (b['password'] != null) passwords[id] = '${b['password']}';
        boxes[i] = {...boxes[i], ...b}..remove('password');
        await json(200, _box(boxes[i]));
        return true;
      }
      if (m == 'DELETE') {
        boxes.removeAt(i);
        await json(200, {'ok': true});
        return true;
      }
    }
    return false;
  }
}
