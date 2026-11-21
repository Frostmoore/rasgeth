// G42.13: Settings › Telegram, Chats and the mailboxes, the same routes the page calls
// (`setupTelegram`, `telegramPair`, `telegramLinks`, `telegramUnlink`, `setupChat`, `chatPair`,
// `chatLinks`, `chatUnlink`, `teamsApp`, `emailSettings`, `mailboxes`, `addMailbox`,
// `updateMailbox`, `removeMailbox` in packages/web/src/api.ts). Passwords and tokens only go
// out: the server never sends them back.
import 'dart:typed_data';

import '../../api/client.dart';

String _id(String id) => Uri.encodeComponent(id);

/// The chat platforms besides Telegram, in the page's order (`ChatPlatform`).
const chatPlatforms = ['discord', 'slack', 'signal', 'whatsapp', 'matrix', 'teams', 'imessage'];

/// An account that talks to Demi-God on a chat (Telegram's id is a number, the others' a string).
class ChatLink {
  const ChatLink({required this.userId, this.username, this.linkedAt});

  factory ChatLink.fromJson(Map<String, dynamic> j) => ChatLink(
    userId: '${j['userId'] ?? ''}',
    username: j['username'] is String ? j['username'] as String : null,
    linkedAt: j['linkedAt'] is String ? j['linkedAt'] as String : null,
  );

  final String userId;
  final String? username;
  final String? linkedAt;

  String get who => username ?? userId;
}

/// The code to send from a chat (and, for Telegram, the bot and its link).
class PairCode {
  const PairCode({required this.code, this.bot, this.link});

  final String code;
  final String? bot;
  final String? link;

  /// Telegram: the bot's link carrying the code (`…?start=<code>`).
  String? get url => link == null ? null : '$link?start=$code';
}

/// One mailbox as the server shows it (G33.3; never its password).
class Mailbox {
  const Mailbox({
    required this.id,
    required this.name,
    required this.category,
    this.host = '',
    this.port = 993,
    this.secure = true,
    this.user = '',
    this.smtpHost,
    this.smtpPort,
    this.agents = false,
  });

  factory Mailbox.fromJson(Map<String, dynamic> j) {
    final smtp = j['smtp'] is Map ? (j['smtp'] as Map).cast<String, dynamic>() : null;
    return Mailbox(
      id: '${j['id'] ?? ''}',
      name: '${j['name'] ?? ''}',
      category: j['category'] is String ? j['category'] as String : 'other',
      host: '${j['host'] ?? ''}',
      port: (j['port'] as num?)?.toInt() ?? 993,
      secure: j['secure'] != false,
      user: '${j['user'] ?? ''}',
      smtpHost: smtp?['host'] is String ? smtp!['host'] as String : null,
      smtpPort: (smtp?['port'] as num?)?.toInt(),
      agents: j['agents'] == true,
    );
  }

  final String id;
  final String name;
  final String category;
  final String host;
  final int port;
  final bool secure;
  final String user;
  final String? smtpHost;
  final int? smtpPort;
  final bool agents;
}

/// The single mailbox of before (G24.14c), as `GET /api/settings/email` says it.
class SingleMailbox {
  const SingleMailbox({required this.configured, this.host, this.port, this.secure, this.user});

  factory SingleMailbox.fromJson(Map<String, dynamic> j) => SingleMailbox(
    configured: j['configured'] == true,
    host: j['host'] is String ? j['host'] as String : null,
    port: (j['port'] as num?)?.toInt(),
    secure: j['secure'] is bool ? j['secure'] as bool : null,
    user: j['user'] is String ? j['user'] as String : null,
  );

  final bool configured;
  final String? host;
  final int? port;
  final bool? secure;
  final String? user;
}

/// The usual categories of the mailboxes, before the person's own.
const mailCategories = ['work', 'personal', 'social', 'other'];

extension ChannelsApi on RedGiantClient {
  // ---- Telegram ----

  /// `PUT /api/setup/telegram`: the bot's token, checked by the server (null: the bot goes).
  Future<String?> setupTelegram(String? token) async {
    final r = await callJson('PUT', '/api/setup/telegram', {'token': token});
    return r is Map && r['username'] is String ? r['username'] as String : null;
  }

  /// `POST /api/telegram/pair`: a code, the bot and its link.
  Future<PairCode> telegramPair() async {
    final j = objectOf(await callJson('POST', '/api/telegram/pair', const {}));
    return PairCode(
      code: '${j['code'] ?? ''}',
      bot: '${j['bot'] ?? ''}',
      link: '${j['link'] ?? ''}',
    );
  }

  /// `GET /api/telegram/links`.
  Future<List<ChatLink>> telegramLinks() async => [
    for (final o in arrayOf(await getJson('/api/telegram/links'))) ChatLink.fromJson(o),
  ];

  /// `DELETE /api/telegram/links/:userId`.
  Future<void> telegramUnlink(String userId) =>
      callJson('DELETE', '/api/telegram/links/${_id(userId)}');

  // ---- the other chats (G29.5, G36.9) ----

  /// `PUT /api/setup/chats/:p`: what it needs, tried by the server (null: switched off).
  Future<void> setupChat(String p, Map<String, String>? settings) =>
      callJson('PUT', '/api/setup/chats/${_id(p)}', {'settings': settings});

  /// `POST /api/chats/:p/pair`: the code to send from that chat.
  Future<PairCode> chatPair(String p) async {
    final j = objectOf(await callJson('POST', '/api/chats/${_id(p)}/pair', const {}));
    return PairCode(code: '${j['code'] ?? ''}');
  }

  /// `GET /api/chats/:p/links`.
  Future<List<ChatLink>> chatLinks(String p) async => [
    for (final o in arrayOf(await getJson('/api/chats/${_id(p)}/links'))) ChatLink.fromJson(o),
  ];

  /// `DELETE /api/chats/:p/links/:userId`.
  Future<void> chatUnlink(String p, String userId) =>
      callJson('DELETE', '/api/chats/${_id(p)}/links/${_id(userId)}');

  /// `GET /api/chats/teams/app.zip?host=…`: the Teams app to upload, made for this server.
  Future<Uint8List> teamsApp() =>
      serverBytes('/api/chats/teams/app.zip?host=${Uri.encodeQueryComponent(base.authority)}');

  // ---- mailboxes (G24.14c, G33.3) ----

  /// `GET /api/settings/email`: the single mailbox of before.
  Future<SingleMailbox> emailSettings() async =>
      SingleMailbox.fromJson(objectOf(await getJson('/api/settings/email')));

  /// `PUT /api/settings/email`: tried before it is kept.
  Future<void> setEmailSettings({
    required String host,
    required int port,
    required bool secure,
    required String user,
    required String password,
  }) => callJson('PUT', '/api/settings/email', {
    'host': host,
    'port': port,
    'secure': secure,
    'user': user,
    'password': password,
  });

  /// `DELETE /api/settings/email`.
  Future<void> removeEmailSettings() => callJson('DELETE', '/api/settings/email');

  /// `GET /api/settings/mailboxes`: every mailbox and the categories in use.
  Future<({List<Mailbox> boxes, List<String> categories})> mailboxList() async {
    final j = objectOf(await getJson('/api/settings/mailboxes'));
    return (
      boxes: [
        for (final b in j['boxes'] is List ? j['boxes'] as List : const [])
          if (b is Map<String, dynamic>) Mailbox.fromJson(b),
      ],
      categories: [
        for (final c in j['categories'] is List ? j['categories'] as List : mailCategories)
          if (c is String) c,
      ],
    );
  }

  /// `POST /api/settings/mailboxes`: a new mailbox, tried before it is kept.
  Future<void> addMailbox(Map<String, Object?> b) => callJson('POST', '/api/settings/mailboxes', b);

  /// `PUT /api/settings/mailboxes/:id`: the password stays unless a new one is written.
  Future<void> updateMailbox(String id, Map<String, Object?> b) =>
      callJson('PUT', '/api/settings/mailboxes/${_id(id)}', b);

  /// `DELETE /api/settings/mailboxes/:id`.
  Future<void> removeMailbox(String id) => callJson('DELETE', '/api/settings/mailboxes/${_id(id)}');
}
