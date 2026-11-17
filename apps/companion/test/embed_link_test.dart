// G42.0: the embed's address as the page writes and reads it (test/fixtures/embed_vectors.json,
// from tool/embed_vectors.mjs over packages/protocol/src/embed.ts): the same fragment byte for
// byte, the token never in a query, and what the page refuses refused here too.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/embed/embed_link.dart';

void main() {
  final v = jsonDecode(File('test/fixtures/embed_vectors.json').readAsStringSync()) as Map;

  EmbedParams fromJson(Map<String, Object?> j) => EmbedParams(
    token: j['token']! as String,
    embed: EmbedKind.values.byName(j['embed']! as String),
    bridge: j['bridge']! as String,
    theme: j['theme']! as String,
    lang: j['lang']! as String,
    scope: j['scope'] as String?,
    path: j['path'] as String?,
    line: j['line'] as int?,
    page: j['page'] as int?,
    session: j['session'] as String?,
    agent: j['agent'] as String?,
    port: j['port'] as int?,
    board: j['board'] as String?,
    font: j['font'] as String?,
  );

  test('the page\'s encoding, byte for byte', () {
    for (final e in (v['encode'] as List).cast<Map>()) {
      expect(formEncode(e['s'] as String), e['e'], reason: '${e['s']}');
    }
  });

  test('every fragment as the page writes it, and read back', () {
    for (final h in (v['hashes'] as List).cast<Map>()) {
      final p = fromJson((h['params'] as Map).cast<String, Object?>());
      expect(embedHash(p), h['hash']);
      expect(parseEmbedHash('#${h['hash']}')?.toJson(), h['params']);
    }
  });

  test('refused as the page refuses', () {
    for (final h in (v['badHashes'] as List).cast<String>()) {
      expect(parseEmbedHash(h), isNull, reason: h);
    }
  });

  test('the address: the page at /, no query, the token only in the fragment', () {
    final p = fromJson(((v['hashes'] as List).first as Map)['params'] as Map<String, Object?>);
    final u = embedUrl(Uri.parse('https://rg.local:7443/some/where?x=1#y'), p);
    expect(u.path, '/');
    expect(u.hasQuery, isFalse);
    expect(u.query, isEmpty);
    expect(u.fragment, startsWith('token='));
    expect(u.toString(), startsWith('https://rg.local:7443/#token='));
  });

  test('an embed the page would refuse is never written', () {
    const p = EmbedParams(
      token: 't',
      embed: EmbedKind.canvas,
      bridge: 'n0nce-n0nce_n0nce',
      theme: 'dark',
      lang: 'it',
    );
    expect(() => embedHash(p), throwsArgumentError);
  });

  test('a nonce the page takes', () {
    for (var i = 0; i < 50; i++) {
      final n = newEmbedNonce(Random(i));
      expect(RegExp(r'^[A-Za-z0-9_-]{16,64}$').hasMatch(n), isTrue);
    }
  });
}
