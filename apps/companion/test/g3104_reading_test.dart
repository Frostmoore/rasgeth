// 3.10.4: answers easier to read («Lettura comoda», the page's `.md-read`), the accent colour
// chosen in «Tu › Aspetto» (saved on this device, applied to the whole theme, readable in both
// themes) and a streaming reply followed only while the person lets it.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/colors.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/accent_picker.dart';
import 'package:rgcompanion/ui/markdown.dart';

import 'fake_server.dart';

const _answer = '''# Il piano

Un paragrafo con **una parola forte** e un [link](https://example.com).

## I passi

- primo
- secondo

### Dettagli

1. uno
2. due

> una citazione''';

double _lum(Color c) {
  double f(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
}

double _contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Brightness b = Brightness.light,
  RgAccent accent = RgAccent.red,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(b, accent),
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

/// The style of the run of text that holds [words] (its own merged over its parents').
TextStyle _styleOf(WidgetTester tester, String words) {
  TextStyle? walk(InlineSpan span, TextStyle up) {
    if (span is! TextSpan) return null;
    final here = up.merge(span.style);
    if ((span.text ?? '').contains(words)) return here;
    for (final c in span.children ?? const <InlineSpan>[]) {
      final f = walk(c, here);
      if (f != null) return f;
    }
    return null;
  }

  for (final p in tester.renderObjectList<RenderParagraph>(find.byType(RichText))) {
    final f = walk(p.text, const TextStyle());
    if (f != null) return f;
  }
  throw StateError('no «$words»');
}

void main() {
  group('«Lettura comoda»', () {
    for (final b in Brightness.values) {
      for (final a in [RgAccent.red, RgAccent.blue]) {
        testWidgets('sizes, bars and colours (${b.name}, ${a.name})', (tester) async {
          await _pump(
            tester,
            const SafeMarkdown(_answer, reading: true, selectable: false),
            b: b,
            accent: a,
          );
          final c = (b == Brightness.dark ? RgColors.dark : RgColors.light).withAccent(a, b);
          final body = _styleOf(tester, 'Un paragrafo');
          expect(body.fontSize, 17);
          expect(body.height, 1.55);
          expect(body.color, c.text);
          final bold = _styleOf(tester, 'una parola forte');
          expect(bold.fontWeight, FontWeight.w700);
          expect(bold.color, c.text);
          expect(_styleOf(tester, 'link').color, c.accent2);
          for (final (tag, words, size, bar) in [
            ('h1', 'Il piano', 24.0, 4.0),
            ('h2', 'I passi', 20.5, 4.0),
            ('h3', 'Dettagli', 18.5, 3.0),
          ]) {
            final h = _styleOf(tester, words);
            expect(h.fontSize, size, reason: tag);
            expect(h.fontWeight, FontWeight.w700, reason: tag);
            expect(h.color, c.text, reason: tag);
            final box = tester.widget<Container>(find.byKey(Key('md-heading-$tag')));
            final side = (box.decoration! as BoxDecoration).border! as Border;
            expect(side.left.color, c.accent, reason: tag);
            expect(side.left.width, bar, reason: tag);
            expect(box.padding, const EdgeInsets.only(left: 12), reason: tag);
          }
          expect(_styleOf(tester, '•').color, c.accent2);
          expect(_styleOf(tester, '1.').color, c.accent2);
        });
      }
    }

    testWidgets('cards and summaries keep the compact look', (tester) async {
      await _pump(tester, const SafeMarkdown(_answer, selectable: false));
      expect(_styleOf(tester, 'Un paragrafo').fontSize, 15);
      expect(_styleOf(tester, 'Il piano').fontSize, 21);
      expect(find.byKey(const Key('md-heading-h1')), findsNothing);
    });
  });

  group('the accent colour', () {
    test('every accent is readable in both themes (WCAG)', () {
      for (final a in RgAccent.values) {
        for (final b in Brightness.values) {
          final c = (b == Brightness.dark ? RgColors.dark : RgColors.light).withAccent(a, b);
          final where = '${a.name} ${b.name}';
          expect(_contrast(c.accent2, c.panel), greaterThanOrEqualTo(4.5), reason: where);
          expect(
            _contrast(Colors.white, c.accent),
            greaterThanOrEqualTo(b == Brightness.light ? 4.5 : 3.5),
            reason: where,
          );
          expect(_contrast(c.accent, c.panel), greaterThanOrEqualTo(3), reason: where);
        }
      }
    });

    test('red is the palette itself; the others change only the accent and the bubble', () {
      expect(RgColors.light.withAccent(RgAccent.red, Brightness.light), same(RgColors.light));
      final g = RgColors.dark.withAccent(RgAccent.green, Brightness.dark);
      expect(g.accent, const Color(0xFF22985D));
      expect(g.text, RgColors.dark.text);
      expect(g.critical, RgColors.dark.critical);
      expect(
        buildTheme(Brightness.light, RgAccent.violet).colorScheme.primary,
        RgAccent.violet.swatch,
      );
    });

    testWidgets('chosen with drawn swatches, saved on this device, applied', (tester) async {
      final prefs = MemoryAppPrefs();
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: prefs,
        platform: DevicePlatform.android,
      );
      await _pump(
        tester,
        AnimatedBuilder(
          animation: app,
          builder: (_, _) => AccentPicker(app: app),
        ),
      );
      expect(find.byType(Radio<RgAccent>), findsNothing);
      expect(find.text('Azzurro'), findsOneWidget);
      await tester.tap(find.byKey(const Key('accent-blue')));
      await tester.pump();
      expect(app.accent, RgAccent.blue);
      expect(prefs.values['accent'], 'blue');
      await tester.tap(find.byKey(const Key('accent-red')));
      await tester.pump();
      expect(prefs.values.containsKey('accent'), isFalse);
      prefs.values['accent'] = 'amber';
      final again = AppController(
        tokens: MemoryTokenStore(),
        prefs: prefs,
        platform: DevicePlatform.android,
      );
      await tester.runAsync(() => again.restore());
      expect(again.accent, RgAccent.amber);
    });
  });

  group('following a streaming reply', () {
    late FakeRedGiant server;
    late AppController app;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    Future<void> settle(WidgetTester tester, [int rounds = 6]) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> open(WidgetTester tester) async {
      for (var i = 0; i < 30; i++) {
        server.store('s1', 'message.user', {'text': 'Messaggio $i\n\nriga\n\nriga'});
      }
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await settle(tester, 10);
    }

    ScrollPosition position(WidgetTester tester) => tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byKey(const Key('conversation-items')),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

    String lines(int from, int n) =>
        [for (var i = from; i < from + n; i++) 'Riga $i della risposta, scritta in fretta.\n\n']
            .join();

    testWidgets('at the bottom it follows; a drag stops it and new text moves nothing', (
      tester,
    ) async {
      await open(tester);
      server.streamPiece('s1', lines(0, 6));
      await settle(tester);
      var p = position(tester);
      expect(p.pixels, lessThanOrEqualTo(4));
      expect(find.byKey(const Key('to-bottom')), findsNothing);
      // Still following: more text, still at the bottom.
      server.streamPiece('s1', lines(6, 6));
      await settle(tester);
      p = position(tester);
      expect(p.pixels, lessThanOrEqualTo(4));
      // The finger moves the view up a little: it stays there while text keeps coming.
      await tester.drag(find.byKey(const Key('conversation-items')), const Offset(0, 300));
      await settle(tester);
      expect(position(tester).pixels, greaterThan(100));
      final seen = tester.getTopLeft(find.textContaining('Riga 3 ', findRichText: true)).dy;
      for (var i = 0; i < 3; i++) {
        server.streamPiece('s1', lines(12 + i * 4, 4));
        await settle(tester, 3);
      }
      // The offset took the new text below; what the person reads did not move.
      expect(tester.getTopLeft(find.textContaining('Riga 3 ', findRichText: true)).dy, seen);
      expect(find.byKey(const Key('new-text')), findsOneWidget);
      expect(find.text('Nuovo testo'), findsOneWidget);
      // «Nuovo testo»: back at the bottom, following again.
      await tester.tap(find.byKey(const Key('to-bottom')));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      await settle(tester);
      p = position(tester);
      expect(p.pixels, lessThanOrEqualTo(4));
      expect(find.byKey(const Key('to-bottom')), findsNothing);
      server.streamPiece('s1', lines(30, 6));
      await settle(tester);
      p = position(tester);
      expect(p.pixels, lessThanOrEqualTo(4));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    });

    testWidgets('a finger held still keeps the view; lifted away from the bottom it stays', (
      tester,
    ) async {
      await open(tester);
      server.streamPiece('s1', lines(0, 4));
      await settle(tester, 12);
      Finder words() => find.textContaining('Riga 1 ', findRichText: true);
      final seen = tester.getTopLeft(words()).dy;
      final g = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('conversation-items'))),
      );
      server.streamPiece('s1', lines(4, 8));
      await settle(tester);
      expect(tester.getTopLeft(words()).dy, seen);
      await g.up();
      await settle(tester);
      expect(tester.getTopLeft(words()).dy, seen);
      expect(find.byKey(const Key('new-text')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    });
  });
}
