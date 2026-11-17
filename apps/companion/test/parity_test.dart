// G42.0 (D1): the parity table (parity.json) names the app's files that do what the page does;
// every one must exist, and the rows keep their rules (the monorepo's
// packages/web/test/companion-parity.test.ts checks the rows against the page's lists).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final table = jsonDecode(File('parity.json').readAsStringSync()) as Map<String, Object?>;
  final groups = ['settings', 'viewers', 'chat', 'client', 'server'];

  test('has its five groups', () {
    for (final g in groups) {
      expect(table[g], isA<Map<String, Object?>>(), reason: g);
    }
  });

  test('every file it names exists in the app', () {
    final missing = <String>[];
    for (final g in groups) {
      for (final e in (table[g]! as Map<String, Object?>).entries) {
        final row = e.value! as Map<String, Object?>;
        for (final f in (row['files'] as List? ?? const []).cast<String>()) {
          if (!File(f).existsSync()) missing.add('$g.${e.key}: $f');
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('a row the app does (native, embed, partial) names a file; one it lacks, a phase', () {
    final wrong = <String>[];
    for (final g in groups) {
      for (final e in (table[g]! as Map<String, Object?>).entries) {
        final row = e.value! as Map<String, Object?>;
        final app = row['app'];
        final files = (row['files'] as List? ?? const []);
        if (!['native', 'embed', 'partial', 'no', 'n/a'].contains(app)) wrong.add('${e.key}: $app');
        if (['native', 'embed', 'partial'].contains(app) && files.isEmpty)
          wrong.add('${e.key}: no file');
        if (['no', 'partial'].contains(app) && row['phase'] == null)
          wrong.add('${e.key}: no phase');
      }
    }
    expect(wrong, isEmpty);
  });
}
