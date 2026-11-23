// 3.12.3: copying an answer gives clean text (a line per paragraph and per list item, «- » for
// bullets, a blank line between blocks, inline code and code blocks included).
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/markdown.dart';
import 'package:rgcompanion/ui/passage_selection.dart';

const _answer = '''## Shortcode

- `[gaia_home]`: home con i 3 percorsi di iscrizione
- `[gaia_registrazione]`: modulo di iscrizione (`tipo="unico|multiplo|pensione"` per fissare il percorso)
- `[gaia_login]`: accesso

Poi il testo finale, su una riga.

1. primo
2. secondo

```php
echo 1;
echo 2;
```''';

const _expected = '''Shortcode

- [gaia_home]: home con i 3 percorsi di iscrizione
- [gaia_registrazione]: modulo di iscrizione (tipo="unico|multiplo|pensione" per fissare il percorso)
- [gaia_login]: accesso

Poi il testo finale, su una riga.

1. primo
2. secondo

echo 1;
echo 2;''';

void main() {
  late List<String> copied;
  setUp(() {
    copied = [];
  });

  Future<void> show(WidgetTester tester, {void Function(PickedPassage)? onReply}) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      c,
    ) async {
      if (c.method == 'Clipboard.setData') copied.add((c.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('it'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SelectableAnswer(data: _answer, onReply: onReply, onSave: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> copy(WidgetTester tester) async {
    final ctx = tester.element(find.byType(SafeMarkdown));
    Actions.invoke(ctx, CopySelectionTextIntent.copy);
    await tester.pump();
  }

  testWidgets('select all and copy: clean text, one line per item', (tester) async {
    await show(tester);
    tester.state<SelectableRegionState>(find.byType(SelectableRegion)).selectAll();
    await tester.pump();
    await copy(tester);
    expect(copied, [_expected]);
  });

  testWidgets('a partial selection inside one item copies just that', (tester) async {
    await show(tester);
    // Drag across the words «accesso» (end of the third item) from its start.
    final item = find.textContaining('accesso', findRichText: true);
    final box = tester.getRect(item.first);
    final g = await tester.startGesture(
      Offset(box.left + 1, box.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await g.moveTo(Offset(box.right - 1, box.center.dy));
    await g.up();
    await tester.pump();
    await copy(tester);
    expect(copied.single.contains('\n'), isFalse);
    expect(copied.single, contains('accesso'));
  });

  testWidgets('a selection inside inline code works', (tester) async {
    await show(tester);
    final item = find.textContaining('gaia_login', findRichText: true);
    expect(item, findsWidgets);
    final box = tester.getRect(item.first);
    final g = await tester.startGesture(
      Offset(box.left + 2, box.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await g.moveTo(Offset(box.left + 60, box.center.dy));
    await g.up();
    await tester.pump();
    await copy(tester);
    expect(copied, isNotEmpty);
    expect(copied.single, contains('[gai'));
  });
}
