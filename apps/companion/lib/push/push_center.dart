// The notifications' one place (G40.10), the same in the app and in the background isolate the
// system starts for a message or an answer: a message is opened with this device's keys and
// shown (or withdrawn), a distributor's new endpoint is sent to the server, a quick answer goes
// to `POST /api/app/requests/:id/answer` (a critical request never takes a quick yes: the app
// opens it on its own screen).
import 'dart:async';
import 'dart:typed_data';

import '../api/client.dart';
import '../api/servers.dart';
import '../api/token_store.dart';
import '../api/transport.dart';
import '../l10n/app_localizations.dart';
import 'notice.dart';
import 'registrar.dart';
import 'system_notifier.dart';
import '../brand.dart';

typedef PushClientFactory = RedGiantClient Function(SavedServer server, String token);

/// What a quick answer from a notification came to.
enum AnswerOutcome { done, openApp, gone, failed }

class PushCenter {
  PushCenter({
    required this.prefs,
    required this.tokens,
    required this.notifier,
    PushClientFactory? clients,
  }) : _clients = clients;

  final AppPrefs prefs;
  final TokenStore tokens;
  final SystemNotifier notifier;
  final PushClientFactory? _clients;
  late final PushRegistrar registrar = PushRegistrar(tokens: tokens, prefs: prefs);
  late final ServerBook _book = ServerBook(prefs);

  Future<AppLocalizations> words() async => wordsFor(await prefs.get('locale'));

  Future<SavedServer?> serverOf(String serverId) async =>
      (await _book.load()).where((s) => s.id == serverId).firstOrNull;

  /// A client for [serverId] with its device token, or null when it cannot be reached without
  /// the app (no token, or only through the setup channel, which needs the password).
  Future<RedGiantClient?> clientOf(String serverId) async {
    final s = await serverOf(serverId);
    final token = await tokens.read(serverId);
    if (s == null || token == null) return null;
    if (transportFor(s.base, hasCa: s.caPem != null) == TransportKind.channel) return null;
    return _clients?.call(s, token) ?? RedGiantClient(s.base, token: token, caPem: s.caPem);
  }

  /// A message for the UnifiedPush instance [serverId]: shown, replaced or withdrawn. Returns
  /// the notice, or null when it was not one for this device.
  Future<PushNotice?> onMessage(
    String serverId,
    Uint8List content, {
    bool decrypted = false,
  }) async {
    final n = await registrar.open(serverId, content, decrypted: decrypted);
    if (n == null) return null;
    await notifier.apply(planFor(n, serverId), await words());
    return n;
  }

  /// The distributor gave [endpoint] for [serverId] (the first time, or a new one).
  Future<bool> onEndpoint(String serverId, String endpoint, {String? deviceId}) async {
    final c = await clientOf(serverId);
    if (c == null) return false;
    try {
      final id = deviceId ?? (await serverOf(serverId))?.deviceId ?? (await c.hello()).deviceId;
      if (id == null) return false;
      await registrar.registerWebPush(c, serverId, id, endpoint);
      return true;
    } on ApiException {
      return false;
    } finally {
      c.close();
    }
  }

  /// The distributor dropped this registration: the server is told when it can be reached.
  Future<void> onUnregistered(String serverId) async {
    final c = await clientOf(serverId);
    try {
      final id = c == null
          ? null
          : (await serverOf(serverId))?.deviceId ?? (await c.hello()).deviceId;
      await registrar.unregister(c, serverId, id);
    } on ApiException {
      await registrar.forget(serverId);
    } finally {
      c?.close();
    }
  }

  /// A Yes or a No pressed on a notification.
  Future<AnswerOutcome> answer(NoticeTap tap, QuickAnswer a) async {
    final requestId = tap.requestId;
    final l = await words();
    // Never a quick yes for a truly dangerous request (the notification has none: this is the
    // last check, for a forged payload).
    if (requestId == null || (a == QuickAnswer.allow && tap.critical)) {
      return AnswerOutcome.openApp;
    }
    final c = await clientOf(tap.serverId);
    if (c == null) {
      await _sayOpenApp(tap, l);
      return AnswerOutcome.failed;
    }
    try {
      await c.answerRequest(requestId, allow: a == QuickAnswer.allow);
      await notifier.cancel(tap.notificationId);
      return AnswerOutcome.done;
    } on ApiException catch (e) {
      if (e.code == 'not_found') {
        // Answered elsewhere or no longer needed.
        await notifier.cancel(tap.notificationId);
        return AnswerOutcome.gone;
      }
      await _sayOpenApp(tap, l);
      return e.code == 'open_app' ? AnswerOutcome.openApp : AnswerOutcome.failed;
    } finally {
      c.close();
    }
  }

  /// The quick answer did not go: the same notification says so, without answers, and a tap
  /// opens the request in the app.
  Future<void> _sayOpenApp(NoticeTap tap, AppLocalizations l) async {
    final s = await serverOf(tap.serverId);
    await notifier.apply(
      ShowNotification(
        tap.notificationId,
        title: l.notifyAnswerFailedTitle,
        body: l.notifyAnswerFailedBody,
        server: s?.label ?? kProductName,
        channel: NoticeChannel.requests,
        answers: const [],
        payload: tap.toPayload(),
      ),
      l,
    );
  }
}
