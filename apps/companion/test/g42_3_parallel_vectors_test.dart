// G42.3: the sub-agents' tabs and the background commands' strip are the page's, from the same
// events (test/fixtures/parallel_vectors.json, made by tool/parallel_fixtures.mjs with the page's
// own `subagentTabs`, `subStatus` and `commandRows`).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/parallel.dart';

void main() {
  final cases = jsonDecode(
    File('test/fixtures/parallel_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  for (final MapEntry(key: name, value: v as Map<String, dynamic>) in cases.entries) {
    test('$name: the same tabs, states and commands as the page', () {
      final events = [
        for (final e in (v['events'] as List).cast<Map<String, dynamic>>()) RgEvent.fromJson(e),
      ];
      final tabs = subagentTabs(events);
      expect([for (final t in tabs) t.toJson()], v['tabs']);
      expect([
        for (final t in tabs)
          [
            subStatus(t, childRunning: false, parentRunning: false),
            subStatus(t, childRunning: true, parentRunning: false),
            subStatus(t, childRunning: false, parentRunning: true),
          ],
      ], v['status']);
      expect([for (final r in commandRows(events)) r.toJson()], v['commands']);
    });
  }

  test(
    'handedOver: unfinished tabs whose conversation runs (or, unknown, while the parent runs)',
    () {
      final events = [
        for (final e in ((cases['three'] as Map)['events'] as List).cast<Map<String, dynamic>>())
          RgEvent.fromJson(e),
      ];
      expect(
        handedOver(events, parentRunning: false, runningOf: (_) => null).map((t) => t.title),
        isEmpty,
      );
      expect(handedOver(events, parentRunning: true, runningOf: (_) => null).map((t) => t.title), [
        'Prove',
      ]);
      expect(
        handedOver(events, parentRunning: true, runningOf: (id) => id == 'sess_a' ? false : null),
        isEmpty,
      );
    },
  );
}
