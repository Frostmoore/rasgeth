// The model menus by provider and way, the newest first (G42.15, the person's 2026-11-20
// decision): lib/api/model_routes.dart's `modelGroups`, `groupTitle` and `modelMatches` against
// what the protocol makes of the same lists (tool/model_groups_vectors.mjs).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/model_routes.dart';
import 'package:rgcompanion/api/settings_types.dart';

void main() {
  final v = jsonDecode(
    File('test/fixtures/model_groups_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('groups, orders and names the models as the page', () {
    for (final list in v['vectors'] as List) {
      final choices = [
        for (final c in (list as Map<String, dynamic>)['choices'] as List)
          ModelChoice.fromJson(c as Map<String, dynamic>),
      ];
      final groups = modelGroups(choices);
      final want = list['groups'] as List;
      expect(groups.map((g) => g.id).toList(), [for (final g in want) (g as Map)['id']]);
      for (var i = 0; i < groups.length; i++) {
        final w = want[i] as Map<String, dynamic>;
        expect(groupTitle(groups[i], 'it'), w['it']);
        expect(groupTitle(groups[i], 'en'), w['en']);
        expect(groups[i].choices.map((c) => c.key).toList(), w['models']);
      }
    }
  });

  test('searches as the page', () {
    for (final s in v['searches'] as List) {
      final m = ModelChoice.fromJson((s as Map<String, dynamic>)['m'] as Map<String, dynamic>);
      expect(modelMatches(m, s['heading'] as String, s['query'] as String), s['matches']);
    }
  });
}
