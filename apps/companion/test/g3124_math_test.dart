// 3.12.4: formulas in an answer (the page's KaTeX): `$…$`, `\(…\)`, `$$…$$`, `\[…\]`, never in code,
// «$5 e $10» stays text, a formula the parser cannot read shows as its source, copying gives LaTeX.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/markdown.dart';
import 'package:rgcompanion/ui/math_text.dart';
import 'package:rgcompanion/ui/passage_selection.dart';

const _softmax = r'P(i)=\frac{e^{z_i}}{\sum_j e^{z_j}}';

List<String> _found(String md) => [
  for (final p in extractMath(md).pieces) '${p.display ? 'D' : 'I'}:${p.tex}',
];

void main() {
  group('extractMath (the same table as the page)', () {
    final table = <(String, String, List<String>)>[
      ('inline dollars', r'so $x^2$ here', ['I:x^2']),
      ('inline parentheses', r'so \(x^2\) here', ['I:x^2']),
      ('display dollars', r'$$x^2$$', ['D:x^2']),
      ('display brackets', '\\[ $_softmax \\]', ['D:$_softmax']),
      ('display over lines', 'Before\n\n\$\$\na = b\n\$\$\n\nAfter', ['D:a = b']),
      ('price pair', r'costs $5 and $10 today', []),
      ('price then formula', r'from $10 or $x$ only', ['I:x']),
      ('space after the opening dollar', r'a $ x$ b', []),
      ('space before the closing dollar', r'a $x $ b', []),
      ('digit after the closing dollar', r'a $x$5 b', []),
      ('escaped dollar', r'a \$x\$ b', []),
      ('lone dollar', r'only $ here', []),
      ('unclosed display', r'$$x^2', []),
      ('price then code', r'is $10 or `$x$` ok', []),
      ('inline code', r'use `$x$` and `\(y\)`', []),
      ('fenced code', '```tex\n\$\$x\$\$\n\\[y\\]\n```', []),
      ('list', '- one \$a\$\n- two \$b\$', ['I:a', 'I:b']),
    ];
    for (final (name, md, expected) in table) {
      test(name, () => expect(_found(md), expected));
    }

    test('the text keeps no delimiters and the source round-trips', () {
      final m = extractMath('Softmax: \\[ $_softmax \\] and \\(z_i\\)');
      expect(m.text, isNot(contains(r'\[')));
      expect(m.text, contains('Softmax:'));
      expect(m.pieces.first.source, '\$\$$_softmax\$\$');
    });
  });

  late List<String> copied;
  setUp(() => copied = []);

  Future<void> show(WidgetTester tester, Widget child) async {
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
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
    await tester.pump();
  }

  testWidgets('inline and display formulas are drawn, not shown as source', (tester) async {
    await show(
      tester,
      SafeMarkdown(
        'Il peso \\(z_i\\) vale\n\n\\[ $_softmax \\]\n\ne costa \$5 e \$10.',
        reading: true,
      ),
    );
    expect(find.byType(Math), findsNWidgets(2));
    expect(find.textContaining(r'\[', findRichText: true), findsNothing);
    expect(find.textContaining(r'$5 e $10', findRichText: true), findsOneWidget);
  });

  testWidgets('a formula in code stays text', (tester) async {
    await show(tester, const SafeMarkdown('Scrivi `\$x\$` così'));
    expect(find.byType(Math), findsNothing);
  });

  testWidgets('a formula in a heading and in a list', (tester) async {
    await show(tester, const SafeMarkdown('# Titolo \$a\$\n\n- voce \$b\$', reading: true));
    expect(find.byType(Math), findsNWidgets(2));
  });

  testWidgets('a formula the parser cannot read shows its source', (tester) async {
    await show(tester, const SafeMarkdown(r'rotta $\frac{1$ qui'));
    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'$\frac{1$', findRichText: true), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('select all and copy: the formulas as LaTeX', (tester) async {
    await show(
      tester,
      SelectableAnswer(data: 'Il peso \\(z_i\\) vale\n\n\\[ $_softmax \\]\n\nFine.'),
    );
    tester.state<SelectableRegionState>(find.byType(SelectableRegion)).selectAll();
    await tester.pump();
    Actions.invoke(tester.element(find.byType(SafeMarkdown)), CopySelectionTextIntent.copy);
    await tester.pump();
    expect(copied, hasLength(1));
    expect(copied.single, startsWith('Il peso \$z_i\$ vale'));
    expect(copied.single, contains(r'$z_i$'));
    expect(copied.single, contains('\$\$$_softmax\$\$'));
    expect(copied.single, isNot(contains('\uE003')));
    expect(copied.single, isNot(contains('\uE004')));
  });
}
