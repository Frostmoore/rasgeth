// G42.0: as the page's no-native-dialogs and no-native-inputs tests. The app draws its own on/off
// and choices (`settings_kit.dart`) and opens every window through `lib/ui/dialogs.dart`: no
// Checkbox or Radio anywhere, no showDialog / showGeneralDialog / showCupertinoDialog elsewhere.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _controls = RegExp(
  r'\b(Checkbox|CheckboxListTile|CheckboxMenuButton|Radio|RadioListTile|RadioMenuButton|'
  r'CupertinoCheckbox|CupertinoRadio)\s*(<[^>]*>)?\s*(\.adaptive)?\(',
);
final _dialogs = RegExp(
  r'\b(showDialog|showGeneralDialog|showCupertinoDialog|showAdaptiveDialog)\s*<?',
);

/// The offending lines of [source] (comments left out).
List<String> offending(String source, {required bool dialogsAllowed}) {
  final out = <String>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].replaceFirst(RegExp(r'//.*$'), '');
    if (_controls.hasMatch(line) || (!dialogsAllowed && _dialogs.hasMatch(line))) {
      out.add('${i + 1}: ${lines[i].trim()}');
    }
  }
  return out;
}

void main() {
  test('the rule finds what it should', () {
    expect(offending('Checkbox(value: true)', dialogsAllowed: true), hasLength(1));
    expect(offending('Radio<int>(value: 1)', dialogsAllowed: true), hasLength(1));
    expect(offending('showDialog<void>(context: c)', dialogsAllowed: false), hasLength(1));
    expect(offending('showDialog<void>(context: c)', dialogsAllowed: true), isEmpty);
    expect(offending('// a Checkbox( in words', dialogsAllowed: false), isEmpty);
    expect(offending('RgSwitch(value: on)', dialogsAllowed: false), isEmpty);
  });

  test('no native control or dialog in the app', () {
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
      final path = f.path.replaceAll('\\', '/');
      final allowed = path.endsWith('lib/ui/dialogs.dart');
      for (final o in offending(f.readAsStringSync(), dialogsAllowed: allowed)) {
        found.add('$path:$o');
      }
    }
    expect(found, isEmpty);
  });
}
