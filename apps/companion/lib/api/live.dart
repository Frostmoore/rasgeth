// The live connection (G40.7): `/ws` signed in with the device's token, the same messages as the
// page (packages/protocol/src/wire.ts). The server sends the waiting requests right after
// `welcome`, then every page of the owner gets `permission.*`, `question.*` and
// `session.activity`; a followed conversation gets its history (`session.history`), its events,
// the streaming `delta`s and `session.state`. A heartbeat every 25 s: with nothing at all from the
// server within [LiveSocket.answerWithin] the link counts as dead (a phone back from the background,
// a computer back from sleep: the socket looks open and nothing arrives). When the link drops it
// comes back by itself and follows the same conversations again from the last event it had.
// Several screens may follow one conversation (the panel and its floating copy, a task's detail):
// the server hears only the first follow and the last unfollow, as the page's `Live` (p3.5.4).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'transport.dart';

/// `PROTOCOL_VERSION` of `@redgiant/protocol` (wire.ts).
const int kWireProtocolVersion = 2;

enum LiveStatus { connecting, open, down, refused }

typedef SocketOpener = Future<WebSocket> Function();

class LiveSocket {
  LiveSocket({
    required SocketOpener open,
    required this.token,
    this.heartbeat = const Duration(seconds: 25),
    this.answerWithin = const Duration(seconds: 10),
    this.welcomeWithin = const Duration(seconds: 15),
  }) : _open = open;

  factory LiveSocket.over(Transport t, String token) =>
      LiveSocket(open: () => t.socket('/ws'), token: token);

  final SocketOpener _open;
  final String token;
  final Duration heartbeat;

  /// How long the server may stay silent after a ping before the link counts as dead.
  final Duration answerWithin;

  /// How long an opened link may wait for `welcome` (p3.8.9: a server still starting after a
  /// blackout, a proxy that accepts and forwards nothing): then it is dropped and tried again
  /// with the back-off, never left «connecting» for ever.
  final Duration welcomeWithin;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<LiveStatus>.broadcast();
  LiveStatus status = LiveStatus.connecting;

  /// The conversations followed, with the last event's seq each one has.
  final followed = <String, int?>{};

  /// How many screens follow each conversation.
  final _followers = <String, int>{};

  WebSocket? _ws;
  Timer? _ping;
  Timer? _deadline;
  Timer? _retry;
  int _attempt = 0;
  int _tries = 0;
  bool _stopped = false;
  String? ownerId;
  String? serverVersion;

  Stream<Map<String, dynamic>> get messages => _messages.stream;
  Stream<LiveStatus> get statuses => _status.stream;

  void _set(LiveStatus s) {
    status = s;
    _status.add(s);
  }

  Future<void> start() => _connect();

  Future<void> _connect() async {
    if (_stopped) return;
    final mine = ++_tries;
    _set(LiveStatus.connecting);
    WebSocket ws;
    try {
      ws = await _open().timeout(const Duration(seconds: 15));
    } on Object {
      // A newer try is under way ([reconnectNow]): it decides.
      if (mine != _tries) return;
      return _later();
    }
    if (_stopped || mine != _tries) {
      await ws.close(1000);
      return;
    }
    _ws = ws;
    _deadline?.cancel();
    _deadline = Timer(welcomeWithin, () => _noWelcome(ws));
    ws.add(jsonEncode({'type': 'hello', 'protocolVersion': kWireProtocolVersion, 'token': token}));
    ws.listen(
      (data) {
        if (data is! String) return;
        Object? m;
        try {
          m = jsonDecode(data);
        } on FormatException {
          return;
        }
        if (m is! Map<String, dynamic>) return;
        if (!identical(_ws, ws)) return;
        // Anything from the server counts as life (`welcome` comes first: its wait ends too).
        _deadline?.cancel();
        _deadline = null;
        if (m['type'] == 'welcome') {
          _attempt = 0;
          ownerId = m['ownerId'] as String?;
          serverVersion = m['version'] as String?;
          _set(LiveStatus.open);
          _ping?.cancel();
          _ping = Timer.periodic(heartbeat, (_) => _beat());
          for (final e in followed.entries) {
            _follow(e.key, e.value);
          }
        }
        if (m['type'] == 'session.history' || m['type'] == 'event') _track(m);
        if (m['type'] == 'pong') return;
        _messages.add(m);
      },
      onDone: () {
        // A socket already dropped as dead: its end changes nothing.
        if (!identical(_ws, ws)) return;
        _ping?.cancel();
        _deadline?.cancel();
        _ws = null;
        // 4003: the token was refused or the device revoked; 4002: another protocol.
        if (ws.closeCode == 4003 || ws.closeCode == 4002) {
          _set(LiveStatus.refused);
          return;
        }
        _later();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _track(Map<String, dynamic> m) {
    final id = m['sessionId'];
    if (id is! String || !followed.containsKey(id)) return;
    if (m['type'] == 'event') {
      final seq = (m['event'] as Map<String, dynamic>?)?['seq'];
      if (seq is num) followed[id] = seq.toInt();
    } else {
      final last = m['lastSeq'];
      if (last is num) followed[id] = last.toInt();
    }
  }

  /// A ping; silence until [answerWithin] drops the link and comes back.
  void _beat() {
    final ws = _ws;
    if (ws == null || status != LiveStatus.open || !send({'type': 'ping'})) return;
    _deadline ??= Timer(answerWithin, () => _drop(ws));
  }

  /// Opened, and no `welcome`: dropped, and tried again after the back-off.
  void _noWelcome(WebSocket ws) {
    if (_stopped || !identical(_ws, ws) || status == LiveStatus.open) return;
    _deadline = null;
    _ws = null;
    unawaited(ws.close(1000).catchError((_) {}));
    _later();
  }

  /// The link looks open and is not: dropped without waiting for its end, and tried again now.
  void _drop(WebSocket ws) {
    if (_stopped || !identical(_ws, ws)) return;
    _ping?.cancel();
    _deadline = null;
    _ws = null;
    unawaited(ws.close(1000).catchError((_) {}));
    _attempt = 0;
    _later(immediately: true);
  }

  /// The app came back to the foreground: an open link is asked whether it still lives, a down one
  /// is tried again at once.
  void checkNow() {
    if (_stopped) return;
    if (status == LiveStatus.open) {
      _beat();
    } else {
      retryNow();
    }
  }

  void _later({bool immediately = false}) {
    if (_stopped) return;
    _set(LiveStatus.down);
    final s = [1, 2, 4, 8, 15, 30][_attempt.clamp(0, 5)];
    _attempt++;
    _retry?.cancel();
    _retry = Timer(immediately ? Duration.zero : Duration(seconds: s), _connect);
  }

  /// Right now, even while a try hangs on a server that went away (RedGiant answers again after
  /// an update): the older try is dropped when it ends.
  void reconnectNow() {
    if (_stopped || status == LiveStatus.open) return;
    _retry?.cancel();
    _attempt = 0;
    unawaited(_connect());
  }

  /// Right now, not after the back-off (the app came to the foreground, the person asked).
  void retryNow() {
    if (_stopped || status == LiveStatus.open || status == LiveStatus.connecting) return;
    _retry?.cancel();
    _attempt = 0;
    unawaited(_connect());
  }

  bool send(Map<String, Object?> m) {
    final ws = _ws;
    if (ws == null || status != LiveStatus.open) return false;
    ws.add(jsonEncode(m));
    return true;
  }

  void _follow(String sessionId, int? afterSeq) => send({
    'type': 'session.follow',
    'sessionId': sessionId,
    'history': true,
    'afterSeq': ?afterSeq,
  });

  void follow(String sessionId) {
    final n = _followers[sessionId] ?? 0;
    _followers[sessionId] = n + 1;
    if (n > 0) return;
    followed[sessionId] = null;
    _follow(sessionId, null);
  }

  /// One screen less: the server stops sending only when no screen follows it any more.
  void unfollow(String sessionId) {
    final n = _followers[sessionId] ?? 0;
    if (n > 1) {
      _followers[sessionId] = n - 1;
      return;
    }
    if (n == 0) return;
    _followers.remove(sessionId);
    followed.remove(sessionId);
    send({'type': 'session.unfollow', 'sessionId': sessionId});
  }

  Future<void> close() async {
    _stopped = true;
    _ping?.cancel();
    _deadline?.cancel();
    _retry?.cancel();
    await _ws?.close(1000);
    _ws = null;
    await _messages.close();
    await _status.close();
  }
}
