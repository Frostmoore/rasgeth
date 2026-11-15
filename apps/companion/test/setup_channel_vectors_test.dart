// The setup channel's formulas against vectors recorded with node:crypto the way the server's
// nodes/channel.ts computes them (tool/setup_vectors.mjs): transcript, signatures, keys, frames.
import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/setup_channel.dart';

void main() {
  final v = jsonDecode(
    File('test/fixtures/setup_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  List<int> b(String k) => base64.decode(v[k] as String);

  test('the identities and their fingerprints, from the same seeds', () async {
    final seeds = v['seeds'] as Map<String, dynamic>;
    final d = await DeviceIdentity.fromSeed(base64.decode(seeds['dialler'] as String));
    final l = await DeviceIdentity.fromSeed(base64.decode(seeds['listener'] as String));
    expect(d.raw, b('dId'));
    expect(l.raw, b('lId'));
    expect(d.fingerprint, v['diallerFingerprint']);
    expect(l.fingerprint, v['listenerFingerprint']);
  });

  test('transcript hash, signatures both ways', () async {
    final th = await transcriptHash(
      'setup',
      dEph: b('dEph'),
      dId: b('dId'),
      dNonce: b('dNonce'),
      lEph: b('lEph'),
      lId: b('lId'),
      lNonce: b('lNonce'),
    );
    expect(base64.encode(th), v['th']);
    final seeds = v['seeds'] as Map<String, dynamic>;
    final d = await DeviceIdentity.fromSeed(base64.decode(seeds['dialler'] as String));
    // ed25519 signatures are deterministic: the app signs exactly as Node does.
    expect(base64.encode(await d.sign([...utf8.encode('dialler'), ...th])), v['diallerSig']);
    expect(
      await verifyEd25519(b('lId'), [...utf8.encode('listener'), ...th], b('listenerSig')),
      isTrue,
    );
    // Another transcript (or the other side's label) never verifies.
    expect(
      await verifyEd25519(b('lId'), [...utf8.encode('dialler'), ...th], b('listenerSig')),
      isFalse,
    );
  });

  test('the X25519 secret and the two directions\' keys', () async {
    final x = X25519();
    final kp = await x.newKeyPairFromSeed(b('dEphPriv'));
    expect((await kp.extractPublicKey()).bytes, b('dEph'));
    final s = await x.sharedSecretKey(
      keyPair: kp,
      remotePublicKey: SimplePublicKey(b('lEph'), type: KeyPairType.x25519),
    );
    final secret = await s.extractBytes();
    expect(base64.encode(secret), v['secret']);
    final k = await channelKeys(secret, b('th'));
    expect(base64.encode(k.d2l), v['d2l']);
    expect(base64.encode(k.l2d), v['l2d']);
  });

  test('frames: sealed like Node, opened only with the right counter and key', () async {
    for (final f in (v['frames'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final key = b(f['key'] as String);
      final n = f['n'] as int;
      final frame = base64.decode(f['frame'] as String);
      expect(base64.encode(await sealFrame(key, n, f['message'])), f['frame']);
      expect(await openFrame(key, n, frame), f['message']);
      // Replayed or reordered: refused.
      expect(await openFrame(key, n + 1, frame), isNull);
      // Changed by one bit: refused.
      final bent = [...frame]..[10] ^= 1;
      expect(await openFrame(key, n, bent), isNull);
      // The other direction's key: refused.
      final other = b(f['key'] == 'd2l' ? 'l2d' : 'd2l');
      expect(await openFrame(other, n, frame), isNull);
    }
  });

  test('the channel\'s address from RedGiant\'s', () {
    expect(
      setupChannelUrl(Uri.parse('http://10.42.0.1')).toString(),
      'ws://10.42.0.1/api/setup-channel',
    );
    expect(
      setupChannelUrl(Uri.parse('https://redgiant.local:8787')).toString(),
      'wss://redgiant.local:8787/api/setup-channel',
    );
  });
}
