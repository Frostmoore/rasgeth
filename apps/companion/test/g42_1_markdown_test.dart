// G42.1: an answer's sources and code as the page shows them (`linkCitations`, the code renderer
// of packages/web/src/markdown.ts).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/citations.dart';
import 'package:rgcompanion/ui/markdown.dart';

const _answer = '''Il cookie va su SameSite=Lax [1] e Secure solo in HTTPS [2][3].

Nel codice `[1]` resta com'è.

```ts
const a = [1];
```

Fonti:

1. [SameSite cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies): MDN
2. [Secure attribute](https://www.owasp.org/secure): OWASP
3. [RFC 6265](https://datatracker.ietf.org/doc/html/rfc6265)''';

void main() {
  test('runs of [n] become one link named after the first source\'s site', () {
    final out = linkCitations(_answer);
    expect(
      out,
      contains(
        '[developer.mozilla.org](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies "SameSite cookies")',
      ),
    );
    expect(
      out,
      contains('[owasp.org +1](https://www.owasp.org/secure "Secure attribute / RFC 6265")'),
    );
    // Code and the list itself stay.
    expect(out, contains('`[1]`'));
    expect(out, contains('const a = [1];'));
    expect(out, contains('1. [SameSite cookies]'));
  });

  test('without a list of links nothing changes', () {
    const plain = 'Vedi [1].\n\n1. una cosa\n2. un\'altra';
    expect(linkCitations(plain), plain);
    expect(citationSources(plain), isEmpty);
  });

  testWidgets('a code block: its language, coloured, «Copia» then «Copiato»', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      c,
    ) async {
      if (c.method == 'Clipboard.setData') copied.add((c.arguments as Map)['text'] as String);
      return null;
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SingleChildScrollView(child: SafeMarkdown(_answer))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('code-block')), findsOneWidget);
    expect(find.text('ts'), findsOneWidget);
    await tester.tap(find.byKey(const Key('code-copy')));
    await tester.pump();
    expect(copied, ['const a = [1];']);
    expect(find.text('Copiato'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Copia'), findsOneWidget);
  });
}
