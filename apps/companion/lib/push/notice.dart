// What a notification from RedGiant says (G40.10), as `PushNotice` in
// `packages/protocol/src/push.ts` (version 1), and what the app does with it: one pure rule,
// [planFor], tested as a table. A request's notification offers Yes and No only when the server
// offered them and the request is not truly dangerous; a critical one opens its own screen in
// the app. The update with `closed` withdraws the notification shown (answered elsewhere).
import 'dart:convert';

import '../brand.dart';

/// `automation` (G42.9): an automation's message for the person that no page or app showed.
/// `nudge` (3.12.1): God's friendly word of the day; its `sessionId` is the topic it is about.
enum NoticeKind { request, question, task, message, automation, test, nudge }

class PushNotice {
  const PushNotice({
    required this.id,
    required this.kind,
    required this.server,
    required this.title,
    required this.body,
    this.sessionId,
    this.requestId,
    this.actions = const [],
    this.critical = false,
    this.closed = false,
    this.closedVia,
  });

  /// A notice from its JSON, or null when it is not one this app understands (another version,
  /// a missing field): nothing is shown for it.
  static PushNotice? tryParse(List<int> bytes) {
    try {
      final j = jsonDecode(utf8.decode(bytes));
      if (j is! Map<String, dynamic> || j['v'] != 1) return null;
      final kind = NoticeKind.values.where((k) => k.name == j['kind']).firstOrNull;
      final id = j['id'];
      if (kind == null || id is! String || id.isEmpty) return null;
      final closed = j['closed'];
      return PushNotice(
        id: id,
        kind: kind,
        server: j['server'] is String ? j['server'] as String : kProductName,
        title: j['title'] is String ? j['title'] as String : '',
        body: j['body'] is String ? j['body'] as String : '',
        sessionId: j['sessionId'] is String ? j['sessionId'] as String : null,
        requestId: j['requestId'] is String ? j['requestId'] as String : null,
        actions: [
          for (final a in j['actions'] is List ? j['actions'] as List : const [])
            if (a == 'allow' || a == 'deny') a as String,
        ],
        critical: j['critical'] == true,
        closed: closed is Map,
        closedVia: closed is Map && closed['via'] is String ? closed['via'] as String : null,
      );
    } on FormatException {
      return null;
    }
  }

  final String id;
  final NoticeKind kind;

  /// The RedGiant's name (the machine's): said in the notification.
  final String server;
  final String title;
  final String body;
  final String? sessionId;
  final String? requestId;

  /// What the server offered: `allow`, `deny`.
  final List<String> actions;
  final bool critical;
  final bool closed;
  final String? closedVia;
}

/// A notification's quick answer.
enum QuickAnswer { allow, deny }

/// Which list the notification goes in (Android's channels; the importance of each).
enum NoticeChannel { requests, updates }

sealed class NotificationPlan {
  const NotificationPlan(this.id);

  /// The system's notification id: the same for a notice and the update that withdraws it.
  final int id;
}

class ShowNotification extends NotificationPlan {
  const ShowNotification(
    super.id, {
    required this.title,
    required this.body,
    required this.server,
    required this.channel,
    required this.answers,
    required this.payload,
    this.progress,
  });

  final String title;
  final String body;
  final String server;
  final NoticeChannel channel;

  /// The quick answers shown on the notification (none for a critical request).
  final List<QuickAnswer> answers;

  /// What a tap or an answer brings back to the app ([NoticeTap.fromPayload]).
  final String payload;

  /// A job that runs (G42.18): how far, 0-100, or -1 while the server does not count it yet (a
  /// bar that moves by itself). Null: not a job's. Shown quietly, once, then updated in place.
  final int? progress;
}

class WithdrawNotification extends NotificationPlan {
  const WithdrawNotification(super.id);
}

/// The system's id for a notice of one RedGiant: FNV-1a over both, in 31 bits (Android's ids
/// are positive ints; two RedGiants never share one by chance of the same request id).
int notificationIdOf(String serverId, String noticeId) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode('$serverId|$noticeId')) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h & 0x7fffffff;
}

/// What a notification carries back when it is tapped or answered.
class NoticeTap {
  const NoticeTap({
    required this.serverId,
    required this.noticeId,
    required this.kind,
    this.requestId,
    this.sessionId,
    this.critical = false,
  });

  static NoticeTap? fromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final j = jsonDecode(payload);
      if (j is! Map<String, dynamic>) return null;
      final kind = NoticeKind.values.where((k) => k.name == j['k']).firstOrNull;
      if (kind == null || j['s'] is! String || j['n'] is! String) return null;
      return NoticeTap(
        serverId: j['s'] as String,
        noticeId: j['n'] as String,
        kind: kind,
        requestId: j['r'] is String ? j['r'] as String : null,
        sessionId: j['c'] is String ? j['c'] as String : null,
        critical: j['x'] == true,
      );
    } on FormatException {
      return null;
    }
  }

  final String serverId;
  final String noticeId;
  final NoticeKind kind;
  final String? requestId;
  final String? sessionId;
  final bool critical;

  int get notificationId => notificationIdOf(serverId, noticeId);

  String toPayload() => jsonEncode({
    's': serverId,
    'n': noticeId,
    'k': kind.name,
    'r': ?requestId,
    'c': ?sessionId,
    if (critical) 'x': true,
  });
}

/// The rule: what the app shows for [n] from the RedGiant the app keeps as [serverId].
NotificationPlan planFor(PushNotice n, String serverId) {
  final id = notificationIdOf(serverId, n.id);
  if (n.closed) return WithdrawNotification(id);
  final isRequest = n.kind == NoticeKind.request && n.requestId != null;
  // Never a quick yes for a truly dangerous request, whatever the notice says: it opens its own
  // screen. A no is offered only alongside a yes, as the server's `quickActions` does.
  final answers = !isRequest || n.critical || !n.actions.contains('allow')
      ? const <QuickAnswer>[]
      : [QuickAnswer.allow, if (n.actions.contains('deny')) QuickAnswer.deny];
  return ShowNotification(
    id,
    title: n.title,
    body: n.body,
    server: n.server,
    channel: n.kind == NoticeKind.request || n.kind == NoticeKind.question
        ? NoticeChannel.requests
        : NoticeChannel.updates,
    answers: answers,
    payload: NoticeTap(
      serverId: serverId,
      noticeId: n.id,
      kind: n.kind,
      requestId: n.requestId,
      sessionId: n.sessionId,
      critical: n.critical,
    ).toPayload(),
  );
}
