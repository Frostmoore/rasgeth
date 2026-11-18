// The app's side of the setup channel (G40.3 server, G40.7 app): a WebSocket at
// /api/setup-channel carrying the nodes' handshake (packages/server/src/nodes/channel.ts) in
// "setup" mode, with the app as the dialler.
//
//   1. the app sends a fresh X25519 key, its ed25519 identity and a nonce (`hello`);
//   2. RedGiant answers with its own and signs the transcript hash th (`welcome`);
//   3. the app checks the signature and, when RedGiant's key is already pinned, that it is the
//      same key (a different one: refused, nothing else is sent); then it signs th (`auth`) and
//      RedGiant answers `ready`.
// Keys: HKDF-SHA256 of the X25519 secret, salted with th, one ChaCha20-Poly1305 key per direction;
// every frame is `counter (8 bytes, big endian) | ciphertext | tag (16)` with the counter as the
// additional data and in the nonce, and must be exactly the next one.
//
// Inside, requests carry an `id` and get `{id, ok, ...}` back: `info`, `http` (the API's own
// requests, so the same rules apply), `device` (a device token and the local CA once signed in)
// and `home-network`. The password never travels in clear over the temporary network.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import '../brand.dart';

const String kChannelVersion = 'rg-node-v1';

final _ed = Ed25519();
final _x = X25519();
final _aead = Chacha20.poly1305Aead();
final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 64);

/// `SHA256:` and the unpadded base64 of the key's hash, as OpenSSH (and `fingerprintOf`) print it.
Future<String> fingerprintOf(List<int> raw) async {
  final h = await Sha256().hash(raw);
  return 'SHA256:${base64.encode(h.bytes).replaceAll(RegExp(r'=+$'), '')}';
}

/// The transcript hash: the version, the mode and both ends' key, identity and nonce.
Future<Uint8List> transcriptHash(
  String mode, {
  required List<int> dEph,
  required List<int> dId,
  required List<int> dNonce,
  required List<int> lEph,
  required List<int> lId,
  required List<int> lNonce,
}) async {
  final b = BytesBuilder(copy: false)
    ..add(utf8.encode(kChannelVersion))
    ..add(utf8.encode(mode));
  for (final p in [dEph, dId, dNonce, lEph, lId, lNonce]) {
    b.add(p);
  }
  return Uint8List.fromList((await Sha256().hash(b.takeBytes())).bytes);
}

/// The two directions' keys: dialler to listener, listener to dialler.
Future<({Uint8List d2l, Uint8List l2d})> channelKeys(List<int> secret, List<int> th) async {
  final k = await _hkdf.deriveKey(
    secretKey: SecretKey(secret),
    nonce: th,
    info: utf8.encode('$kChannelVersion keys'),
  );
  final okm = Uint8List.fromList(await k.extractBytes());
  return (d2l: okm.sublist(0, 32), l2d: okm.sublist(32, 64));
}

Uint8List _nonce(int n) {
  final b = ByteData(12)..setUint64(4, n);
  return b.buffer.asUint8List();
}

Uint8List _head(int n) => (ByteData(8)..setUint64(0, n)).buffer.asUint8List();

/// One encrypted frame with counter [n].
Future<Uint8List> sealFrame(List<int> key, int n, Object? message) async {
  final head = _head(n);
  final box = await _aead.encrypt(
    utf8.encode(jsonEncode(message)),
    secretKey: SecretKey(key),
    nonce: _nonce(n),
    aad: head,
  );
  return Uint8List.fromList([...head, ...box.cipherText, ...box.mac.bytes]);
}

/// The message in [frame] when it decrypts and carries exactly counter [expected]; else null.
Future<Object?> openFrame(List<int> key, int expected, List<int> frame) async {
  if (frame.length < 8 + 16) return null;
  final bytes = Uint8List.fromList(frame);
  final n = ByteData.sublistView(bytes, 0, 8).getUint64(0);
  if (n != expected) return null;
  try {
    final plain = await _aead.decrypt(
      SecretBox(
        bytes.sublist(8, bytes.length - 16),
        nonce: _nonce(n),
        mac: Mac(bytes.sublist(bytes.length - 16)),
      ),
      secretKey: SecretKey(key),
      aad: bytes.sublist(0, 8),
    );
    return jsonDecode(utf8.decode(plain));
  } on Object {
    return null;
  }
}

/// The app's own long-term identity (ed25519): RedGiant recognises the same device coming back.
class DeviceIdentity {
  DeviceIdentity._(this.keyPair, this.raw, this.fingerprint);

  final SimpleKeyPair keyPair;
  final Uint8List raw;
  final String fingerprint;

  static Future<DeviceIdentity> fromSeed(List<int> seed) async {
    final kp = await _ed.newKeyPairFromSeed(seed);
    final raw = Uint8List.fromList((await kp.extractPublicKey()).bytes);
    return DeviceIdentity._(kp, raw, await fingerprintOf(raw));
  }

  static Future<({DeviceIdentity identity, Uint8List seed})> create() async {
    final seed = Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)));
    return (identity: await fromSeed(seed), seed: seed);
  }

  Future<Uint8List> sign(List<int> data) async =>
      Uint8List.fromList((await _ed.sign(data, keyPair: keyPair)).bytes);
}

Future<bool> verifyEd25519(List<int> raw, List<int> data, List<int> sig) async {
  if (raw.length != 32 || sig.length != 64) return false;
  try {
    return await _ed.verify(
      data,
      signature: Signature(sig, publicKey: SimplePublicKey(raw, type: KeyPairType.ed25519)),
    );
  } on Object {
    return false;
  }
}

enum SetupChannelErrorCode {
  /// RedGiant answered with another key than the pinned one: nothing was sent.
  fingerprintChanged,

  /// Another device is setting this RedGiant up (one at a time).
  busy,
  protocol,
  unreachable,
  timeout,
  closed,
}

class SetupChannelException implements Exception {
  const SetupChannelException(this.code, this.message, {this.seen});

  final SetupChannelErrorCode code;
  final String message;

  /// The fingerprint RedGiant showed (when it changed).
  final String? seen;

  @override
  String toString() => 'SetupChannelException(${code.name}): $message';
}

/// The answer to a request inside the channel that was not `ok`.
class SetupRequestException implements Exception {
  const SetupRequestException(this.code, this.message);

  /// `unauthorized`, `bad_request`, `unavailable`, `not_installed`, `failed`…
  final String code;
  final String message;

  @override
  String toString() => 'SetupRequestException($code): $message';
}

const _closeCodes = {
  4003: SetupChannelErrorCode.protocol,
  4006: SetupChannelErrorCode.protocol,
  4008: SetupChannelErrorCode.busy,
};

/// `http(s)://host[:port]` as the setup channel's WebSocket URL.
Uri setupChannelUrl(Uri base) => base.replace(
  scheme: base.scheme == 'https' || base.scheme == 'wss' ? 'wss' : 'ws',
  path: '/api/setup-channel',
  query: null,
);

/// An open setup channel: requests in, answers out, encrypted and in order.
class SetupChannel {
  SetupChannel._(this._ws, this._sendKey, this._recvKey, this.peerFingerprint, this.th);

  final WebSocket _ws;
  final Uint8List _sendKey;
  final Uint8List _recvKey;

  /// RedGiant's key, to pin (trust on first use) or as checked against the pinned one.
  final String peerFingerprint;
  final Uint8List th;

  int _sent = 0;
  int _received = 0;
  int _nextId = 1;
  final _waiting = <Object, Completer<Map<String, dynamic>>>{};
  Future<void> _receiving = Future.value();
  StreamSubscription<dynamic>? _sub;
  bool _closed = false;

  bool get isOpen => !_closed;

  /// Dials RedGiant at [base] and runs the handshake. [expect]: the pinned fingerprint, when
  /// there is one; [socket]: tests (another way to open the WebSocket).
  static Future<SetupChannel> dial(
    Uri base, {
    required DeviceIdentity identity,
    String? expect,
    Duration timeout = const Duration(seconds: 15),
    HttpClient? httpClient,
  }) async {
    final url = setupChannelUrl(base);
    WebSocket ws;
    try {
      ws = await WebSocket.connect(url.toString(), customClient: httpClient).timeout(timeout);
    } on TimeoutException {
      throw const SetupChannelException(
        SetupChannelErrorCode.timeout,
        '$kProductName did not answer in time',
      );
    } on Object catch (e) {
      throw SetupChannelException(SetupChannelErrorCode.unreachable, 'Cannot reach $url: $e');
    }
    final inbox = StreamQueue(ws);
    try {
      final eph = await _x.newKeyPair();
      final ephPub = (await eph.extractPublicKey()).bytes;
      final nonce = List.generate(32, (_) => Random.secure().nextInt(256));
      ws.add(
        jsonEncode({
          't': 'hello',
          'v': kChannelVersion,
          'mode': 'setup',
          'eph': base64.encode(ephPub),
          'id': base64.encode(identity.raw),
          'nonce': base64.encode(nonce),
        }),
      );
      final w = await inbox.nextJson(timeout, ws);
      if (w['t'] != 'welcome') {
        throw const SetupChannelException(
          SetupChannelErrorCode.protocol,
          'Not a $kProductName setup channel',
        );
      }
      final peerRaw = _b64(w['id']);
      final peerEph = _b64(w['eph']);
      final th = await transcriptHash(
        'setup',
        dEph: ephPub,
        dId: identity.raw,
        dNonce: nonce,
        lEph: peerEph,
        lId: peerRaw,
        lNonce: _b64(w['nonce']),
      );
      if (!await verifyEd25519(peerRaw, [...utf8.encode('listener'), ...th], _b64(w['sig']))) {
        throw const SetupChannelException(
          SetupChannelErrorCode.protocol,
          "$kProductName's signature is wrong",
        );
      }
      final fp = await fingerprintOf(peerRaw);
      if (expect != null && fp != expect) {
        throw SetupChannelException(
          SetupChannelErrorCode.fingerprintChanged,
          '$kProductName answered with another key: another computer may be in its place',
          seen: fp,
        );
      }
      final sig = await identity.sign([...utf8.encode('dialler'), ...th]);
      ws.add(jsonEncode({'t': 'auth', 'sig': base64.encode(sig)}));
      final r = await inbox.nextJson(timeout, ws);
      if (r['t'] != 'ready') {
        throw const SetupChannelException(SetupChannelErrorCode.protocol, 'Unexpected answer');
      }
      final secret = await _x.sharedSecretKey(
        keyPair: eph,
        remotePublicKey: SimplePublicKey(peerEph, type: KeyPairType.x25519),
      );
      final k = await channelKeys(await secret.extractBytes(), th);
      final ch = SetupChannel._(ws, k.d2l, k.l2d, fp, th);
      ch._listen(inbox);
      return ch;
    } on Object {
      await ws.close(1000);
      rethrow;
    }
  }

  void _listen(StreamQueue inbox) {
    for (final f in inbox.rest()) {
      _take(f);
    }
    _sub = inbox.subscription
      ..onData(_take)
      ..onDone(() => _shut(_ws.closeCode, _ws.closeReason));
  }

  void _take(dynamic data) {
    // Frames are opened one after the other: the counters must stay in order.
    _receiving = _receiving.then((_) async {
      if (_closed) return;
      if (data is! List<int>) return _fail('a plain frame on the link');
      final m = await openFrame(_recvKey, _received, data);
      if (m is! Map<String, dynamic>) {
        return _fail('a frame that does not decrypt or is out of order');
      }
      _received++;
      final c = _waiting.remove(m['id']);
      c?.complete(m);
    });
  }

  void _fail(String why) {
    unawaited(_ws.close(4006, why));
    _shut(4006, why);
  }

  void _shut(int? code, String? reason) {
    if (_closed) return;
    _closed = true;
    final e = SetupChannelException(
      _closeCodes[code] ?? SetupChannelErrorCode.closed,
      reason == null || reason.isEmpty ? 'The setup channel closed' : reason,
    );
    for (final c in _waiting.values) {
      c.completeError(e);
    }
    _waiting.clear();
  }

  /// One request; its answer (`ok: true`) or a [SetupRequestException].
  Future<Map<String, dynamic>> request(
    Map<String, Object?> message, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_closed) {
      throw const SetupChannelException(SetupChannelErrorCode.closed, 'The channel is closed');
    }
    final id = _nextId++;
    final c = Completer<Map<String, dynamic>>();
    _waiting[id] = c;
    final n = _sent++;
    _ws.add(await sealFrame(_sendKey, n, {...message, 'id': id}));
    final r = await c.future.timeout(
      timeout,
      onTimeout: () {
        _waiting.remove(id);
        throw const SetupChannelException(
          SetupChannelErrorCode.timeout,
          '$kProductName did not answer in time',
        );
      },
    );
    if (r['ok'] != true) {
      throw SetupRequestException(
        r['error'] is String ? r['error'] as String : 'failed',
        r['message'] is String ? r['message'] as String : 'It did not work',
      );
    }
    return r;
  }

  /// The machine's fingerprint, version, where the app is (`setup`, `home`…), the first access.
  Future<Map<String, dynamic>> info() => request({'t': 'info'});

  /// One API request, carried inside the channel: `{status, type, body}`.
  Future<({int status, String type, String body})> http(
    String method,
    String path, {
    Object? json,
  }) async {
    final r = await request({
      't': 'http',
      'method': method,
      'path': path,
      if (json != null) 'body': jsonEncode(json),
    });
    return (
      status: (r['status'] as num?)?.toInt() ?? 0,
      type: r['type'] is String ? r['type'] as String : '',
      body: r['body'] is String ? r['body'] as String : '',
    );
  }

  /// Signed in: a token for this device and the machine's local CA (PEM, or null without one).
  Future<({String token, String deviceId, String? ca, String fingerprint})> device(
    String name,
    String platform,
  ) async {
    final r = await request({'t': 'device', 'name': name, 'platform': platform});
    final token = r['token'];
    if (token is! String || token.isEmpty) {
      throw const SetupChannelException(SetupChannelErrorCode.protocol, 'No token');
    }
    return (
      token: token,
      deviceId: r['deviceId'] is String ? r['deviceId'] as String : '',
      ca: r['ca'] is String ? r['ca'] as String : null,
      fingerprint: r['fingerprint'] is String ? r['fingerprint'] as String : peerFingerprint,
    );
  }

  /// Signed in: the home network (`{cable: true}` or `{ssid, password}`), «try and come back».
  Future<Map<String, dynamic>> homeNetwork(Map<String, Object?> choice) =>
      request({'t': 'home-network', ...choice}, timeout: const Duration(minutes: 3));

  Future<void> close() async {
    _shut(1000, 'closed');
    await _sub?.cancel();
    await _ws.close(1000);
  }
}

Uint8List _b64(Object? v) {
  try {
    return base64.decode(v is String ? v : '');
  } on FormatException {
    return Uint8List(0);
  }
}

/// What a socket receives during the handshake, in order; what comes after it waits for the
/// link instead of being lost.
class StreamQueue {
  StreamQueue(Stream<dynamic> s) {
    subscription = s.listen(
      (d) {
        _queue.add(d);
        _wake?.complete();
        _wake = null;
      },
      onDone: () {
        _done = true;
        _wake?.complete();
        _wake = null;
      },
    );
  }

  late final StreamSubscription<dynamic> subscription;
  final _queue = <dynamic>[];
  bool _done = false;
  Completer<void>? _wake;

  Future<Map<String, dynamic>> nextJson(Duration timeout, WebSocket ws) async {
    final deadline = DateTime.now().add(timeout);
    while (_queue.isEmpty) {
      if (_done) {
        final code = ws.closeCode;
        throw SetupChannelException(
          _closeCodes[code] ?? SetupChannelErrorCode.closed,
          ws.closeReason?.isNotEmpty == true
              ? ws.closeReason!
              : '$kProductName closed the channel ($code)',
        );
      }
      final left = deadline.difference(DateTime.now());
      if (left <= Duration.zero) {
        throw const SetupChannelException(
          SetupChannelErrorCode.timeout,
          '$kProductName did not answer in time',
        );
      }
      final w = _wake = Completer<void>();
      await w.future.timeout(left, onTimeout: () {});
    }
    final m = _queue.removeAt(0);
    if (m is! String) {
      throw const SetupChannelException(
        SetupChannelErrorCode.protocol,
        'Unexpected frame in the handshake',
      );
    }
    try {
      final j = jsonDecode(m);
      if (j is Map<String, dynamic>) return j;
    } on FormatException {
      // below
    }
    throw const SetupChannelException(SetupChannelErrorCode.protocol, 'Unreadable handshake');
  }

  /// Hands over what came after the handshake (the subscription keeps going).
  List<dynamic> rest() {
    final r = _queue.toList();
    _queue.clear();
    return r;
  }
}
