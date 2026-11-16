// 3.8.5: the cursor of an answer being written follows the last character, in whatever Markdown
// block it is (paragraph, list, table, quote, heading, code), and goes away when the answer ends.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/stream_cursor.dart';

import 'fake_server.dart';

const m = streamCursorMark;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('withStreamCursor', () {
    final table = <String, String>{
      'Ciao': 'Ciao$m',
      'Ciao\n\n': 'Ciao$m',
      '': m,
      '- uno\n- due': '- uno\n- due$m',
      '- uno\n- ': '- uno\n- $m',
      '1. uno\n2. due\n': '1. uno\n2. due$m',
      '| a | b |\n|---|---|\n| 1 | 2 |': '| a | b |\n|---|---|\n| 1 | 2 $m |',
      '| a | b |\n|---|---|\n| 1 | 2': '| a | b |\n|---|---|\n| 1 | 2$m',
      '> detto': '> detto$m',
      '## Titolo': '## Titolo$m',
      '```dart': '```dart\n$m',
      '```dart\nvar a = 1;': '```dart\nvar a = 1;$m',
      '```dart\nvar a = 1;\n```': '```dart\nvar a = 1;$m\n```',
      'testo\n```\nx\n```\ndopo': 'testo\n```\nx\n```\ndopo$m',
    };
    for (final e in table.entries) {
      test(e.key.replaceAll('\n', r'\n'), () => expect(withStreamCursor(e.key), e.value));
    }
  });

  group('in a conversation', () {
    late FakeRedGiant server;
    late AppController app;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    Future<void> open(WidgetTester tester, {bool still = false}) async {
      app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
            )
            ..locale = const Locale('it')
            ..reduceMotion = still;
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: 's1', agent: app.agents.first),
            ),
          )
          .ignore();
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    final cursor = find.byKey(const Key('stream-cursor'));

    /// The text of the line (the rich text) the cursor sits in.
    String lineOf(WidgetTester tester) {
      final rich = tester.renderObject<RenderParagraph>(
        find.ancestor(of: cursor, matching: find.byType(RichText)).first,
      );
      return rich.text.toPlainText();
    }

    testWidgets('a paragraph, then a list: the cursor follows; gone at the end', (tester) async {
      await open(tester);
      expect(cursor, findsNothing);
      server.streamPiece('s1', 'Ecco il ');
      await _settle(tester);
      expect(cursor, findsOneWidget);
      expect(lineOf(tester), contains('Ecco il'));
      server.streamPiece('s1', 'piano:\n\n- primo\n- secondo\n- ter');
      await _settle(tester);
      expect(cursor, findsOneWidget);
      expect(lineOf(tester), contains('ter'));
      expect(lineOf(tester), isNot(contains('secondo')));
      server.streamEnd('s1', 'Ecco il piano:\n\n- primo\n- secondo\n- terzo');
      await _settle(tester);
      expect(cursor, findsNothing);
      expect(find.textContaining('terzo', findRichText: true), findsWidgets);
      await done(tester);
    });

    testWidgets('a table: the cursor in its last cell', (tester) async {
      await open(tester);
      server.streamPiece('s1', '| Giorno | Cosa |\n|---|---|\n| lun | spesa |\n| mar | pal');
      await _settle(tester);
      expect(find.descendant(of: find.byType(Table), matching: cursor), findsOneWidget);
      expect(lineOf(tester), contains('pal'));
      server.streamPiece('s1', 'estra |');
      await _settle(tester);
      expect(find.descendant(of: find.byType(Table), matching: cursor), findsOneWidget);
      expect(lineOf(tester), contains('palestra'));
      await done(tester);
    });

    testWidgets('a block of code, a numbered list, a quote, a heading', (tester) async {
      await open(tester);
      server.streamPiece('s1', 'Prova:\n\n```dart\nvoid main() {\n  print(1);');
      await _settle(tester);
      expect(cursor, findsOneWidget);
      expect(lineOf(tester), contains('print(1);'));
      expect(
        find.descendant(of: find.byType(SingleChildScrollView), matching: cursor),
        findsWidgets,
      );
      server.streamPiece('s1', '\n}\n```\n\n1. uno\n2. du');
      await _settle(tester);
      expect(lineOf(tester), allOf(contains('du'), isNot(contains('uno'))));
      server.streamPiece('s1', 'e\n\n> una cita');
      await _settle(tester);
      expect(lineOf(tester), contains('una cita'));
      server.streamPiece('s1', 'zione\n\n## Fine');
      await _settle(tester);
      expect(lineOf(tester), contains('Fine'));
      expect(cursor, findsOneWidget);
      await done(tester);
    });

    testWidgets('«Reduce motion»: the cursor stands still', (tester) async {
      await open(tester, still: true);
      server.streamPiece('s1', 'Fermo');
      await _settle(tester);
      expect(tester.widget<StreamCursor>(find.byType(StreamCursor)).still, isTrue);
      expect(tester.hasRunningAnimations, isFalse);
      await done(tester);
    });
  });
}
