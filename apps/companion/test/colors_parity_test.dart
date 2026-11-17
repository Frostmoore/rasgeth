// G42.0: the app's colours are the page's. Reads packages/web/src/styles.css (`:root` and
// `html[data-theme="dark"]`, the first of each) and checks every variable against `RgColors`;
// the dark theme takes the light one's where it does not set its own (as CSS does).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/theme/colors.dart';

Map<String, String> _block(String css, String selector) {
  final start = css.indexOf('$selector {');
  if (start < 0) throw StateError('no $selector in styles.css');
  final body = css.substring(start + selector.length + 2, css.indexOf('\n}', start));
  return {
    for (final m in RegExp(r'--([\w-]+):\s*(#[0-9a-fA-F]{6})\s*;').allMatches(body))
      m.group(1)!: m.group(2)!.toLowerCase(),
  };
}

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

Map<String, Color> _vars(RgColors c) => {
  'bg': c.bg,
  'panel': c.panel,
  'panel-2': c.panel2,
  'line': c.line,
  'text': c.text,
  'dim': c.dim,
  'accent': c.accent,
  'accent-2': c.accent2,
  'accent-soft': c.accentSoft,
  'accent-dim': c.accentDim,
  'ok': c.ok,
  'warn': c.warn,
  'warn-text': c.warnText,
  'err': c.err,
  'critical': c.critical,
  'critical-ink': c.criticalInk,
  'critical-soft': c.criticalSoft,
  'critical-text': c.criticalText,
  'user': c.user,
  'code': c.code,
};

void main() {
  final css = File('../../packages/web/src/styles.css').readAsStringSync();
  final light = _block(css, ':root');
  final dark = {...light, ..._block(css, 'html[data-theme="dark"]')};

  for (final (name, page, app) in [
    ('light', light, RgColors.light),
    ('dark', dark, RgColors.dark),
  ]) {
    test('the $name theme: every colour of the page, the same in the app', () {
      final diff = <String>[];
      for (final e in _vars(app).entries) {
        final want = page[e.key];
        if (want == null) {
          diff.add('--${e.key} is not in styles.css');
        } else if (_hex(e.value) != want) {
          diff.add('--${e.key}: page $want, app ${_hex(e.value)}');
        }
      }
      expect(diff, isEmpty);
    });
  }
}
