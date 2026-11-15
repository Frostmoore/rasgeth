// The live connection (G40.7): `/ws` signed in with the device's token, the same messages as the
// page (packages/protocol/src/wire.ts). The server sends the waiting requests right after
// `welcome`, then every page of the owner gets `permission.*`, `question.*` and
// `session.activity`; a followed conversation gets its history (`session.history`), its events,
// the streaming `delta`s and `session.state`. A heartbeat every 25 s; when the link drops it comes
// back by itself and follows the same conversations again from the last event it had.
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
  }) : _open = open;

  factory LiveSocket.over(Transport t, String token) =>
      LiveSocket(open: () => t.socket('/ws'), token: token);

  final SocketOpener _open;
  final String token;
  final Duration heartbeat;

  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _status = StreamController<LiveStatus>.broadcast();
  LiveStatus status = LiveStatus.connecting;

  /// The conversations followed, with the last event's seq each one has.
  final followed = <String, int?>{};

  WebSocket? _ws;
  Timer? _ping;
  Timer? _retry;
  int _attempt = 0;
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
    _set(LiveStatus.connecting);
    WebSocket ws;
    try {
      ws = await _open().timeout(const Duration(seconds: 15));
    } on Object {
      return _later();
    }
    if (_stopped) {
      await ws.close(1000);
      return;
    }
    _ws = ws;
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
        if (m['type'] == 'welcome') {
          _attempt = 0;
          ownerId = m['ownerId'] as String?;
          serverVersion = m['version'] as String?;
          _set(LiveStatus.open);
          _ping?.cancel();
          _ping = Timer.periodic(heartbeat, (_) => send({'type': 'ping'}));
          for (final e in followed.entries) {
            _follow(e.key, e.value);
          }
        }
        if (m['type'] == 'session.history' || m['type'] == 'event') _track(m);
        _messages.add(m);
      },
      onDone: () {
        _ping?.cancel();
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

  void _later() {
    if (_stopped) return;
    _set(LiveStatus.down);
    final s = [1, 2, 4, 8, 15, 30][_attempt.clamp(0, 5)];
    _attempt++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: s), _connect);
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
    if (followed.containsKey(sessionId)) return;
    followed[sessionId] = null;
    _follow(sessionId, null);
  }

  void unfollow(String sessionId) {
    followed.remove(sessionId);
    send({'type': 'session.unfollow', 'sessionId': sessionId});
  }

  Future<void> close() async {
    _stopped = true;
    _ping?.cancel();
    _retry?.cancel();
    await _ws?.close(1000);
    _ws = null;
    await _messages.close();
    await _status.close();
  }
}
