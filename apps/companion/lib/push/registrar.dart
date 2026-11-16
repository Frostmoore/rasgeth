// Where a RedGiant's notifications go, from the app's side (G40.10). Per RedGiant the app keeps
// its own Web Push keys ([PushKeyPair], in the system's keystore beside the device token), tells
// the server where to send (`PUT /api/devices/:id/push`: the UnifiedPush distributor's endpoint,
// or Apple's device token) and opens what arrives with [decryptPush]. The server never gets the
// private key; the distributor and Apple see only ciphertext.
import 'dart:convert';
import 'dart:typed_data';

import '../api/client.dart';
import '../api/servers.dart';
import '../api/token_store.dart';
import 'ece.dart';
import 'notice.dart';

/// What the app remembers of one RedGiant's channel (in the preferences, never a key).
class PushChannelState {
  const PushChannelState({required this.kind, required this.target, required this.registeredAt});

  static PushChannelState? fromJson(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, dynamic> || j['kind'] is! String || j['target'] is! String) {
        return null;
      }
      return PushChannelState(
        kind: j['kind'] as String,
        target: j['target'] as String,
        registeredAt: j['registeredAt'] is String ? j['registeredAt'] as String : '',
      );
    } on FormatException {
      return null;
    }
  }

  /// `webpush` or `apns`.
  final String kind;

  /// The endpoint (Web Push) or Apple's token.
  final String target;
  final String registeredAt;

  String toJson() => jsonEncode({'kind': kind, 'target': target, 'registeredAt': registeredAt});
}

class PushRegistrar {
  PushRegistrar({required this.tokens, required this.prefs, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// The keystore that keeps the device tokens: the push keys live there too.
  final TokenStore tokens;
  final AppPrefs prefs;
  final DateTime Function() _now;

  static String _keysKey(String serverId) => 'push.$serverId';
  static String _stateKey(String serverId) => 'push:$serverId';

  /// This device's keys for [serverId], made the first time and kept.
  Future<PushKeyPair> keysFor(String serverId) async {
    final raw = await tokens.read(_keysKey(serverId));
    if (raw != null) {
      try {
        return PushKeyPair.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        // Unreadable: new keys (the server gets them with the next registration).
      }
    }
    final k = PushKeyPair.generate();
    await tokens.write(_keysKey(serverId), jsonEncode(k.toJson()));
    return k;
  }

  Future<PushChannelState?> stateOf(String serverId) async =>
      PushChannelState.fromJson(await prefs.get(_stateKey(serverId)));

  /// The body of `PUT /api/devices/:id/push` for a UnifiedPush endpoint.
  static Map<String, Object?> webPushBody(String endpoint, PushKeyPair keys) => {
    'kind': 'webpush',
    'endpoint': endpoint,
    'keys': keys.publicJson,
  };

  /// The body for Apple (prepared: iOS registers only once the app is published).
  static Map<String, Object?> apnsBody(
    String deviceToken,
    PushKeyPair keys, {
    bool sandbox = false,
  }) => {
    'kind': 'apns',
    'token': deviceToken,
    'keys': keys.publicJson,
    'environment': sandbox ? 'sandbox' : 'production',
  };

  /// Tells the server to send to [endpoint] (a distributor's new endpoint, or the same again).
  Future<void> registerWebPush(
    RedGiantClient client,
    String serverId,
    String deviceId,
    String endpoint,
  ) async {
    final keys = await keysFor(serverId);
    await client.registerPush(deviceId, webPushBody(endpoint, keys));
    await prefs.set(
      _stateKey(serverId),
      PushChannelState(
        kind: 'webpush',
        target: endpoint,
        registeredAt: _now().toUtc().toIso8601String(),
      ).toJson(),
    );
  }

  /// Apple's device token, with the same keys: what the Notification Service Extension uses.
  Future<void> registerApns(
    RedGiantClient client,
    String serverId,
    String deviceId,
    String deviceToken, {
    bool sandbox = false,
  }) async {
    final keys = await keysFor(serverId);
    await client.registerPush(deviceId, apnsBody(deviceToken, keys, sandbox: sandbox));
    await prefs.set(
      _stateKey(serverId),
      PushChannelState(
        kind: 'apns',
        target: deviceToken,
        registeredAt: _now().toUtc().toIso8601String(),
      ).toJson(),
    );
  }

  /// No more notifications from [serverId]: the server forgets the channel, the app its keys.
  Future<void> unregister(RedGiantClient? client, String serverId, String? deviceId) async {
    if (client != null && deviceId != null) await client.unregisterPush(deviceId);
    await forget(serverId);
  }

  /// Forgets the channel and the keys (a RedGiant removed from the app).
  Future<void> forget(String serverId) async {
    await prefs.set(_stateKey(serverId), null);
    await tokens.delete(_keysKey(serverId));
  }

  /// Opens a message for [serverId]: decrypted with this device's keys, or already decrypted by
  /// the distributor's library ([decrypted]). Null when it is not a notice for this device.
  Future<PushNotice?> open(String serverId, Uint8List content, {bool decrypted = false}) async {
    if (decrypted) {
      final n = PushNotice.tryParse(content);
      if (n != null) return n;
    }
    final raw = await tokens.read(_keysKey(serverId));
    if (raw == null) return null;
    try {
      final keys = PushKeyPair.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      return PushNotice.tryParse(decryptPush(content, keys));
    } on PushCryptoException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
