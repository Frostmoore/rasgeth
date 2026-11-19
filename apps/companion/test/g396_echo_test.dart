// Echo (3.9.6): the search over past conversations, as the page's box in the left bar: on the
// team's screen and as a page of the computer's panel, against the fake server answering as
// `GET /api/conversations/search` does; the words found marked from the server's offsets.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/echo_api.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/desktop/side_panel.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/echo_search.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  // The box waits 250 ms before it asks (the clock of the test moves only when told).
  await tester.pump(const Duration(milliseconds: 300));
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Map<String, dynamic> _hit(String id, String title, {bool archived = false}) => {
  'sessionId': id,
  'title': title,
  'agentId': 'a0',
  'projectId': null,
  'at': '2026-11-12T10:00:00.000Z',
  'lastAt': '2026-11-12T11:00:00.000Z',
  'matches': 3,
  'archived': archived,
  'snippets': [
    {
      'role': 'person',
      'at': '2026-11-12T10:00:00.000Z',
      'text': 'the invoices are wrong',
      'marks': [
        [4, 12],
      ],
    },
    {
      'role': 'agent',
      'at': '2026-11-12T10:01:00.000Z',
      'text': 'fixed the invoices rounding',
      'marks': [
        [10, 18],
      ],
    },
  ],
};

void main() {
  test('a hit reads the server\'s answer, offsets included, and skips what is broken', () {
    final h = EchoHit.fromJson(_hit('s1', 'Rounding', archived: true));
    expect(h.archived, isTrue);
    expect(h.matches, 3);
    expect(h.snippets.first.marks, [(4, 12)]);
    final odd = EchoSnippet.fromJson({
      'text': 'abc',
      'marks': [
        [0, 1],
        ['x', 2],
        [1],
      ],
    });
    expect(odd.marks, [(0, 1)]);
    expect(odd.role, 'other');
    // Marks out of the text, or overlapping, are left out: the text stays whole.
    final span = echoSpan(
      const EchoSnippet(role: 'agent', at: '', text: 'abcdef', marks: [(1, 3), (2, 4), (5, 99)]),
      const TextStyle(),
      Colors.yellow,
    );
    expect(span.toPlainText(), 'abcdef');
    expect(
      (span.children!.whereType<TextSpan>().where((s) => s.style?.backgroundColor != null))
          .map((s) => s.text),
      ['bc'],
    );
  });

  group('in the app', () {
    late FakeRedGiant server;
    final asked = <String>[];
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      asked.clear();
      server.routes['GET /api/conversations/search'] = (r) {
        final q = r.uri.queryParameters['q'] ?? '';
        asked.add(q);
        return server.answer(
          r,
          200,
          q.contains('nothing') ? <Object>[] : [_hit('s1', 'Rounding of invoices', archived: true)],
        );
      };
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 900)}) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: false,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() async {
        await app.connect(server.base.toString(), 'secret');
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      return app;
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the team\'s screen: the box, the conversations found, one opened', (tester) async {
      await start(tester);
      final box = find.byKey(const Key('echo-box'));
      expect(box, findsOneWidget);
      expect(find.text('Cerca nelle conversazioni passate'), findsOneWidget);
      await tester.enterText(box, 'i');
      await _settle(tester);
      expect(find.textContaining('Scrivi almeno due lettere'), findsOneWidget);
      expect(asked, isEmpty);
      await tester.enterText(box, 'invoices');
      await _settle(tester);
      expect(asked, ['invoices']);
      expect(find.text('Rounding of invoices'), findsOneWidget);
      expect(find.text('archiviato'), findsOneWidget);
      expect(find.textContaining('3 messaggi'), findsOneWidget);
      // The words found, marked.
      final marked = tester
          .widgetList<RichText>(find.byType(RichText))
          .expand((t) => _spans(t.text))
          .where((s) => s.style?.backgroundColor != null)
          .map((s) => s.text)
          .toList();
      expect(marked, ['invoices', 'invoices']);
      expect(find.textContaining('Tu: '), findsOneWidget);
      await tester.tap(find.byKey(const Key('echo-hit-s1')));
      await _settle(tester);
      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(tester.widget<ConversationScreen>(find.byType(ConversationScreen)).sessionId, 's1');
      await done(tester);
    });

    testWidgets('nothing found says so; clearing brings the team back', (tester) async {
      await start(tester);
      await tester.enterText(find.byKey(const Key('echo-box')), 'nothing here');
      await _settle(tester);
      expect(find.text('Nessuna conversazione passata ha queste parole.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('echo-clear')));
      await _settle(tester);
      expect(find.text('Nessuna conversazione passata ha queste parole.'), findsNothing);
      expect(find.byKey(const Key('echo-results')), findsNothing);
      await done(tester);
    });
  });

  testWidgets('on a computer: a page of the panel, named as the page names it', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Text(panelTitle(AppLocalizations.of(context), PanelScreen.echo)),
        ),
      ),
    );
    expect(find.text('Search past conversations'), findsOneWidget);
    expect(const PanelPage(PanelScreen.echo).id, 'page:echo');
  });

  test('the fake answer is what the server sends (one JSON list)', () {
    expect(jsonDecode(jsonEncode([_hit('s1', 't')])), isA<List<dynamic>>());
  });
}

Iterable<TextSpan> _spans(InlineSpan s) sync* {
  if (s is TextSpan) {
    yield s;
    for (final c in s.children ?? const <InlineSpan>[]) {
      yield* _spans(c);
    }
  }
}
