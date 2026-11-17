// Secrets in what people write (G42.1): lib/api/secrets.dart finds what the protocol's
// `findSecrets` finds, at the same UTF-16 positions, and hides them the same way
// (test/fixtures/secrets_vectors.json, made by tool/secrets_vectors.mjs with the protocol's code).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/secrets.dart';

final _fx = jsonDecode(
  File('test/fixtures/secrets_vectors.json').readAsStringSync(),
) as Map<String, dynamic>;
final _vectors = (_fx['vectors'] as List).cast<Map<String, dynamic>>();

void main() {
  test('the same well-known key formats, by name and in order', () {
    final patterns = (_fx['patterns'] as List).cast<Map<String, dynamic>>();
    expect(secretPatterns.map((p) => p.name).toList(), patterns.map((p) => p['name']).toList());
    for (var i = 0; i < patterns.length; i++) {
      // JavaScript's `source` writes "/" as "\/" (it is the literal's delimiter).
      final source = (patterns[i]['source'] as String).replaceAll(r'\/', '/');
      expect(secretPatterns[i].re.pattern, source, reason: patterns[i]['name'] as String);
    }
  });

  test('findSecrets: the same spans as the protocol', () {
    expect(_vectors.length, greaterThan(50));
    for (final v in _vectors) {
      final text = v['text'] as String;
      expect(
        findSecrets(text).map((s) => s.toJson()).toList(),
        v['found'],
        reason: jsonEncode(text),
      );
    }
  });

  test('hideSecrets and hasSecret: the same text and answer as the protocol', () {
    for (final v in _vectors) {
      final text = v['text'] as String;
      final hidden = hideSecrets(text, '[secret removed]');
      expect(hidden.text, v['hidden'], reason: jsonEncode(text));
      expect(hidden.found.length, (v['found'] as List).length);
      expect(hideSecrets(text).text, v['hiddenDefault'], reason: jsonEncode(text));
      expect(hasSecret(text), v['has'], reason: jsonEncode(text));
    }
  });

  test('positions are UTF-16 code units, as in JavaScript', () {
    const text = '😀 password: Zeta1234';
    final s = findSecrets(text).single;
    expect(s.start, 13);
    expect(s.kind, SecretKind.password);
    expect(text.substring(s.start, s.end), 'Zeta1234');
  });
}
