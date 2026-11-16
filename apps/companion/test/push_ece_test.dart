// Web Push decryption on the device (G40.10): RFC 8291's own vector (Appendix A), messages sealed
// by the server's code (tool/push_vectors.mjs with packages/server/src/push/ece.ts), round trips
// with fresh keys, and what must fail (another device's key, a changed byte, a cut message).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/push/ece.dart';
import 'package:rgcompanion/push/notice.dart';

// RFC 8291, Appendix A.
const _rfc = (
  plaintext: 'When I grow up, I want to be a watermelon',
  asPrivate: 'yfWPiYE-n46HLnH0KqZOF1fJJU3MYrct3AELtAQ-oRw',
  asPublic:
      'BP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A8',
  uaPrivate: 'q1dXpw3UpT5VOmu_cf_v6ih07Aems3njxI-JWgLcM94',
  uaPublic:
      'BCVxsr7N_eNgVRqvHtD0zTZsEc6-VV-JvLexhqUzORcxaOzi6-AYWXvTBHm4bjyPjs7Vd8pZGH6SRpkNtoIAiw4',
  salt: 'DGv6ra1nlYgDCS1FRnbzlw',
  auth: 'BTBZMqHH6r4Tts7J_aSIgg',
  message: 'DGv6ra1nlYgDCS1FRnbzlwAAEABBBP4z9KsN6nGRTbVYI_c7VJSPQTBtkgcy27mlmlMoZIIgDll6e3vCYLocInmYWAmS6TlzAC8wEqKK6PBru3jl7A_yl95bQpu6cVPTpK4Mqgkf1CXztLVBSt2Ks3oZwbuwXPXLWyouBWLVWGNWQexSgSxsj_Qulcy4a-fN',
);

PushKeyPair get _ua => PushKeyPair.fromPrivate(unb64u(_rfc.uaPrivate), unb64u(_rfc.auth));

void main() {
  group('RFC 8291', () {
    test('the user agent key gives the RFC public key', () {
      expect(_ua.p256dh, _rfc.uaPublic);
      expect(PushKeyPair.fromPrivate(unb64u(_rfc.asPrivate), Uint8List(16)).p256dh, _rfc.asPublic);
    });

    test('decrypts the RFC message', () {
      expect(utf8.decode(decryptPush(unb64u(_rfc.message), _ua)), _rfc.plaintext);
    });

    test('seals exactly the RFC message with its salt and key', () {
      final out = encryptPush(
        utf8.encode(_rfc.plaintext),
        uaPublic: unb64u(_rfc.uaPublic),
        auth: unb64u(_rfc.auth),
        salt: unb64u(_rfc.salt),
        asPrivate: unb64u(_rfc.asPrivate),
      );
      expect(b64u(out), _rfc.message);
    });

    test('refuses another key, a changed byte and a cut message', () {
      final body = unb64u(_rfc.message);
      expect(() => decryptPush(body, PushKeyPair.generate()), throwsA(isA<PushCryptoException>()));
      final changed = Uint8List.fromList(body)..[body.length - 3] ^= 1;
      expect(() => decryptPush(changed, _ua), throwsA(isA<PushCryptoException>()));
      expect(
        () => decryptPush(Uint8List.sublistView(body, 0, 90), _ua),
        throwsA(isA<PushCryptoException>()),
      );
      final otherAuth = PushKeyPair.fromPrivate(unb64u(_rfc.uaPrivate), Uint8List(16));
      expect(() => decryptPush(body, otherAuth), throwsA(isA<PushCryptoException>()));
    });
  });

  group('fresh keys', () {
    test('a new pair is a valid P-256 point and a 16-byte secret; keys survive saving', () {
      final k = PushKeyPair.generate();
      expect(k.publicKey.length, 65);
      expect(k.publicKey.first, 4);
      expect(k.authSecret.length, 16);
      expect(k.publicJson.keys, unorderedEquals(['p256dh', 'auth']));
      expect(k.publicJson.values.join(), isNot(contains(b64u(k.privateKey))));
      final again = PushKeyPair.fromJson(k.toJson());
      expect(again.p256dh, k.p256dh);
      expect(again.auth, k.auth);
    });

    test('round trip, every message different', () {
      final k = PushKeyPair.generate();
      final text = utf8.encode('Una richiesta per te');
      final a = encryptPush(text, uaPublic: k.publicKey, auth: k.authSecret);
      final b = encryptPush(text, uaPublic: k.publicKey, auth: k.authSecret);
      expect(a, isNot(equals(b)));
      expect(utf8.decode(decryptPush(a, k)), 'Una richiesta per te');
      expect(utf8.decode(decryptPush(b, k)), 'Una richiesta per te');
    });
  });

  group('sealed by the server', () {
    final fx = jsonDecode(
      File('test/fixtures/push_vectors.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final dev = fx['device'] as Map<String, dynamic>;
    final keys = PushKeyPair.fromJson(dev);
    final messages = (fx['messages'] as Map<String, dynamic>).cast<String, Map<String, dynamic>>();

    test('the device keys are the ones the server sealed for', () {
      expect(keys.p256dh, dev['p256dh']);
    });

    for (final name in messages.keys) {
      test('opens the server message "$name" into the same notice', () {
        final m = messages[name]!;
        final plain = decryptPush(unb64u(m['body'] as String), keys);
        expect(jsonDecode(utf8.decode(plain)), m['notice']);
        expect(PushNotice.tryParse(plain), isNotNull);
      });
    }
  });
}
