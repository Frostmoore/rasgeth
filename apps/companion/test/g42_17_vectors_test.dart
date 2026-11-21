// G42.17: the setup wizard's rules and the history's sentences against the page's own results
// (tool/wizard_vectors.mjs from wizard.ts, tool/changes_vectors.mjs from changes.ts).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/setup/wizard/wizard_logic.dart';
import 'package:rgcompanion/settings/platform_screen.dart';

void main() {
  final wz = jsonDecode(
    File('test/fixtures/wizard_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final ch = jsonDecode(
    File('test/fixtures/changes_vectors.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('the steps for every mode, role, local offer and password', () {
    expect(advancedSteps, wz['advanced']);
    for (final r in (wz['steps'] as List).cast<Map<String, dynamic>>()) {
      expect(
        stepsFor(
          r['mode'] as String?,
          role: r['role'] as String?,
          local: r['local'] as bool?,
          password: r['password'] == true,
        ),
        r['steps'],
        reason: '$r',
      );
    }
  });

  test('what may be skipped, and the step after each', () {
    for (final r in (wz['skip'] as List).cast<Map<String, dynamic>>()) {
      expect(
        skippable(r['step'] as String, mustSetPassword: r['must'] == true),
        r['skippable'],
        reason: '$r',
      );
    }
    for (final r in (wz['after'] as List).cast<Map<String, dynamic>>()) {
      expect(stepAfter((r['list'] as List).cast<String>(), r['from'] as String), r['to']);
    }
  });

  test('the ready choices of the approvals and the ways in use', () {
    expect(presets, (wz['presets'] as Map).map((k, v) => MapEntry(k, (v as List).cast<String>())));
    for (final r in (wz['presetOf'] as List).cast<Map<String, dynamic>>()) {
      expect(presetOf((r['humanOnly'] as List).cast<String>()), r['preset']);
    }
    for (final r in (wz['ways'] as List).cast<Map<String, dynamic>>()) {
      final o = (r['input'] as Map).cast<String, dynamic>();
      final s = <String, dynamic>{
        'config': {'subscriptions': o['subs'] ?? {}, 'engine': o['engine'], 'server': o['server']},
        'secretsSet': {'keys': o['keys'] ?? []},
        'locked': {'anthropic': o['lockedAnthropic'] == true, 'server': o['lockedServer'] == true},
      };
      expect(waysInUse(s), r['ways'], reason: '$o');
      expect(paysPerUse(s), r['paid'], reason: '$o');
    }
  });

  test('the history in sentences, it and en, as the page says them', () {
    final ChangeNames names = (agent: (id) => 'A-$id', project: (id) => 'P-$id');
    for (final lang in ['it', 'en']) {
      for (final r in ((ch['said'] as Map)[lang] as List).cast<Map<String, dynamic>>()) {
        final c = PlatformChange({
          'id': 'c1',
          'kind': r['code'] == true ? 'code' : 'config',
          'change': r['code'] == true ? 'Fix the bar' : 'raw',
          'stage': 'promoted',
          'target': r['target'],
          'before': r['before'],
          'after': r['after'],
        });
        expect(
          describeChange(c, names, lang),
          r['said'],
          reason: '$lang ${r['target']} ${r['before']} ${r['after']}',
        );
      }
      for (final e in ((ch['stages'] as Map)[lang] as Map).entries) {
        expect(codeStageText(e.key as String, lang), e.value);
      }
    }
  });
}
