// Web Push decryption on the device (G40.10): RFC 8291, the "aes128gcm" content coding of
// RFC 8188, exactly as `packages/server/src/push/ece.ts` seals a notice. The device makes its
// own P-256 key pair and 16-byte secret ([PushKeyPair]); the server gets only the public half
// (`p256dh`) and the secret (`auth`), the distributor (ntfy…) sees only ciphertext.
//
//   ecdh_secret = ECDH(ua_private, as_public)
//   IKM   = HKDF(salt = auth_secret, ikm = ecdh_secret, info = "WebPush: info\0" ua_public as_public, 32)
//   CEK   = HKDF(salt, IKM, "Content-Encoding: aes128gcm\0", 16)
//   NONCE = HKDF(salt, IKM, "Content-Encoding: nonce\0", 12)
//   body  = salt(16) | rs(4) | idlen(1) = 65 | as_public(65) | AES-128-GCM(plaintext | 0x02)
//
// Pure Dart (pointycastle): the same code runs in the app, in the background isolate that
// shows a notification, and in the tests with the RFC's vectors.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// The record size the server uses (one record per message).
const int kRecordSize = 4096;
const int _header = 16 + 4 + 1 + 65;

String b64u(List<int> b) => base64Url.encode(b).replaceAll('=', '');

Uint8List unb64u(String s) {
  final pad = (4 - s.length % 4) % 4;
  return base64Url.decode(s + '=' * pad);
}

final ECDomainParameters _p256 = ECDomainParameters('prime256v1');

class PushCryptoException implements Exception {
  const PushCryptoException(this.message);

  final String message;

  @override
  String toString() => 'PushCryptoException: $message';
}

/// The device's keys for one RedGiant: what `PUT /api/devices/:id/push` sends as `keys`
/// ([p256dh], [auth]) and the private half that never leaves the device.
class PushKeyPair {
  PushKeyPair._(this.privateKey, this.publicKey, this.authSecret);

  /// A new key pair and secret from the system's secure random source.
  factory PushKeyPair.generate([Random? random]) {
    final rnd = random ?? Random.secure();
    final seed = Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
    final gen = ECKeyGenerator()
      ..init(
        ParametersWithRandom(
          ECKeyGeneratorParameters(_p256),
          FortunaRandom()..seed(KeyParameter(seed)),
        ),
      );
    final pair = gen.generateKeyPair();
    final d = _bytes32(pair.privateKey.d!);
    final q = pair.publicKey.Q!.getEncoded(false);
    final auth = Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
    return PushKeyPair._(d, Uint8List.fromList(q), auth);
  }

  /// From the private scalar (32 bytes) and the secret: the public key is computed again.
  factory PushKeyPair.fromPrivate(Uint8List d, Uint8List auth) {
    if (d.length != 32 || auth.length != 16) {
      throw const PushCryptoException('A 32-byte key and a 16-byte secret');
    }
    final q = (_p256.G * _int(d))!.getEncoded(false);
    return PushKeyPair._(Uint8List.fromList(d), Uint8List.fromList(q), Uint8List.fromList(auth));
  }

  factory PushKeyPair.fromJson(Map<String, dynamic> j) =>
      PushKeyPair.fromPrivate(unb64u(j['d'] as String? ?? ''), unb64u(j['auth'] as String? ?? ''));

  /// The private scalar (32 bytes, big-endian).
  final Uint8List privateKey;

  /// The uncompressed public point (65 bytes, starting with 4).
  final Uint8List publicKey;
  final Uint8List authSecret;

  String get p256dh => b64u(publicKey);
  String get auth => b64u(authSecret);

  /// What the server registers: never the private key.
  Map<String, String> get publicJson => {'p256dh': p256dh, 'auth': auth};

  /// What the device keeps in its secure storage.
  Map<String, String> toJson() => {'d': b64u(privateKey), 'auth': auth};
}

BigInt _int(List<int> b) {
  var r = BigInt.zero;
  for (final x in b) {
    r = (r << 8) | BigInt.from(x);
  }
  return r;
}

Uint8List _bytes32(BigInt v) {
  final out = Uint8List(32);
  var x = v;
  for (var i = 31; i >= 0; i--) {
    out[i] = (x & BigInt.from(0xff)).toInt();
    x = x >> 8;
  }
  return out;
}

Uint8List _hmac(Uint8List key, List<int> data) {
  final h = HMac(SHA256Digest(), 64)..init(KeyParameter(key));
  return h.process(Uint8List.fromList(data));
}

/// HKDF-SHA256 for up to 32 bytes (one block is all RFC 8291 needs).
Uint8List hkdf(Uint8List salt, Uint8List ikm, List<int> info, int length) {
  final prk = _hmac(salt, ikm);
  final t = _hmac(prk, [...info, 1]);
  return Uint8List.sublistView(t, 0, length);
}

Uint8List _ecdh(Uint8List privateKey, Uint8List publicKey) {
  final ECPoint? point;
  try {
    point = _p256.curve.decodePoint(publicKey);
  } on Object {
    throw const PushCryptoException('Not a P-256 public key');
  }
  final agreement = ECDHBasicAgreement()..init(ECPrivateKey(_int(privateKey), _p256));
  return _bytes32(agreement.calculateAgreement(ECPublicKey(point, _p256)));
}

({Uint8List cek, Uint8List nonce}) _keys(
  Uint8List shared,
  Uint8List auth,
  Uint8List salt,
  Uint8List uaPublic,
  Uint8List asPublic,
) {
  final ikm = hkdf(auth, shared, [
    ...utf8.encode('WebPush: info\x00'),
    ...uaPublic,
    ...asPublic,
  ], 32);
  return (
    cek: hkdf(salt, ikm, utf8.encode('Content-Encoding: aes128gcm\x00'), 16),
    nonce: hkdf(salt, ikm, utf8.encode('Content-Encoding: nonce\x00'), 12),
  );
}

Uint8List _gcm(bool encrypt, Uint8List key, Uint8List nonce, Uint8List data) {
  final c = GCMBlockCipher(AESEngine())
    ..init(encrypt, AEADParameters(KeyParameter(key), 128, nonce, Uint8List(0)));
  return c.process(data);
}

/// Opens one message sealed for [keys]. Throws [PushCryptoException] when it is not for this
/// device (another key, a changed byte) or not a single last record.
Uint8List decryptPush(Uint8List body, PushKeyPair keys) {
  if (body.length < _header + 17) throw const PushCryptoException('Too short');
  final salt = Uint8List.sublistView(body, 0, 16);
  final idlen = body[20];
  if (idlen != 65 || body.length < 21 + idlen + 17) {
    throw const PushCryptoException('Not an aes128gcm message');
  }
  final asPublic = Uint8List.sublistView(body, 21, 21 + idlen);
  final data = Uint8List.sublistView(body, 21 + idlen);
  final shared = _ecdh(keys.privateKey, asPublic);
  final k = _keys(shared, keys.authSecret, salt, keys.publicKey, asPublic);
  final Uint8List record;
  try {
    record = _gcm(false, k.cek, k.nonce, data);
  } on InvalidCipherTextException {
    throw const PushCryptoException('Not for this device');
  } on ArgumentError {
    throw const PushCryptoException('Not for this device');
  }
  // The last record ends with 0x02 and zero padding.
  var end = record.length - 1;
  while (end >= 0 && record[end] == 0) {
    end--;
  }
  if (end < 0 || record[end] != 2) throw const PushCryptoException('Not the last record');
  return Uint8List.sublistView(record, 0, end);
}

/// Seals [plaintext] for a subscriber, as the server does: the tests' round trips and the RFC's
/// vector ([salt] and [asPrivate] fixed there, new for every message otherwise).
Uint8List encryptPush(
  List<int> plaintext, {
  required Uint8List uaPublic,
  required Uint8List auth,
  Uint8List? salt,
  Uint8List? asPrivate,
  Random? random,
}) {
  final rnd = random ?? Random.secure();
  final as = asPrivate == null
      ? PushKeyPair.generate(rnd)
      : PushKeyPair.fromPrivate(asPrivate, Uint8List(16));
  final s = salt ?? Uint8List.fromList(List<int>.generate(16, (_) => rnd.nextInt(256)));
  final shared = _ecdh(as.privateKey, uaPublic);
  final k = _keys(shared, auth, s, uaPublic, as.publicKey);
  final sealed = _gcm(true, k.cek, k.nonce, Uint8List.fromList([...plaintext, 2]));
  final rs = ByteData(4)..setUint32(0, kRecordSize);
  return Uint8List.fromList([
    ...s,
    ...rs.buffer.asUint8List(),
    as.publicKey.length,
    ...as.publicKey,
    ...sealed,
  ]);
}
