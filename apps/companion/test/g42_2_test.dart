// G42.2: boards of variants, an agent's port, preview links, Settings › Artifacts and the picture
// that forms, as the page does them. Pure rules as tables (`boardOf`, a board's link, the
// capabilities' words and sentences from the protocol's vectors); the screens against the fake
// server, with a web view of the test's own (each variant and each port is the page in `embed`).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/artifacts.dart';
import 'package:rgcompanion/api/board.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/artifacts_screen.dart';
import 'package:rgcompanion/screens/board_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/chat/chat_parts.dart';

import 'fake_server.dart';

/// A web view of the test's own: what was loaded, what the page says.
class FakeHost implements WebHost {
  FakeHost(this.all);

  final List<FakeHost> all;
  final out = StreamController<String>.broadcast();
  Uri? loaded;
  int reloads = 0;

  void say(Map<String, Object?> m) {
    final nonce = parseEmbedHash(loaded!.fragment)!.bridge;
    out.add(jsonEncode({'rg': 'embed', 'n': nonce, 'm': m}));
  }

  @override
  Stream<String> get messages => out.stream;

  @override
  Future<void> load(Uri url, WebRules r) async {
    loaded = url;
    all.add(this);
  }

  @override
  Future<void> run(String script) async {}

  @override
  Future<void> reload() async => reloads++;

  @override
  Widget view({required bool eager}) => const SizedBox.expand(key: Key('fake-web'));

  @override
  void dispose() {}
}

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Map<String, dynamic> _ev(int seq, String type, Map<String, dynamic> payload, {String? ts}) => {
  'seq': seq,
  'ts': ts ?? '2026-11-17T10:0$seq:00.000Z',
  'sessionId': 's1',
  'type': type,
  'payload': payload,
};

const _board = '0a1b2c3d4e5f';
final _proposed = _ev(2, 'variants.proposed', {
  'proposalId': _board,
  'title': "The site's home page",
  'description': 'Three ways to the front page.',
  'variants': [
    {'title': 'Dark', 'note': 'Red on black', 'bytes': 10},
    {'title': 'Light', 'bytes': 11},
    {'title': 'Night', 'bytes': 12},
  ],
});

void main() {
  group('a board, from the conversation\'s events (the page\'s boardOf)', () {
    test('the last proposal with its id, every answer, the last choice', () {
      final events = [
        _ev(1, 'variants.proposed', {
          'proposalId': 'ffffffffffff',
          'title': 'Another',
          'variants': [],
        }),
        _proposed,
        _ev(3, 'variants.answered', {'proposalId': _board, 'variant': 2, 'choice': true}),
        _ev(4, 'variants.answered', {
          'proposalId': _board,
          'variant': 3,
          'choice': false,
          'comment': 'Bluer',
        }),
        _ev(5, 'variants.answered', {
          'proposalId': _board,
          'variant': null,
          'choice': false,
          'comment': 'All',
        }),
        _ev(6, 'variants.answered', {'proposalId': 'ffffffffffff', 'variant': 1, 'choice': true}),
      ];
      final b = boardOf(events, _board)!;
      expect(b.title, "The site's home page");
      expect(b.description, 'Three ways to the front page.');
      expect([for (final v in b.variants) v.title], ['Dark', 'Light', 'Night']);
      expect(b.variants.first.note, 'Red on black');
      expect(b.at, '2026-11-17T10:02:00.000Z');
      expect(b.chosen, 2);
      expect(b.answersOn(3).single.comment, 'Bluer');
      expect(b.answersOn(null).single.comment, 'All');
      expect(boardOf(events, '000000000000'), isNull);
      // No choice yet: none chosen; a later choice wins.
      expect(boardOf([_proposed], _board)!.chosen, isNull);
      expect(
        boardOf([
          ...events,
          _ev(7, 'variants.answered', {'proposalId': _board, 'variant': 1, 'choice': true}),
        ], _board)!.chosen,
        1,
      );
    });

    test('a board\'s link from a chat (#tavola=…), and what is not one', () {
      const table = <String?, String?>{
        'https://rg.example.com/#tavola=s_1.0a1b2c3d4e5f': 's_1/0a1b2c3d4e5f',
        'http://192.168.1.5:7443/#token=x&tavola=abc-9.0123456789ab': 'abc-9/0123456789ab',
        'https://rg.example.com/#tavola=s.XYZ': null,
        'https://rg.example.com/?tavola=s.0123456789ab': null,
        'javascript:alert(1)#tavola=s.0123456789ab': null,
        'https://example.com/page': null,
        null: null,
      };
      for (final e in table.entries) {
        final b = boardFromLink(e.key);
        expect(b == null ? null : '${b.sessionId}/${b.proposalId}', e.value, reason: e.key);
      }
    });

    test('the frames keep the real screen\'s shape; the columns are the page\'s', () {
      expect(boardAspect('computer'), 1280 / 800);
      expect(boardAspect('phone'), 390 / 780);
      expect(boardColumns.keys, boardScreens.keys);
    });
  });

  group('artifacts\' capabilities, as the protocol says them', () {
    final v = jsonDecode(File('test/fixtures/artifact_vectors.json').readAsStringSync()) as Map;

    test('the words taken and refused, canonical', () {
      for (final w in (v['words'] as List).cast<Map<String, dynamic>>()) {
        expect(parseCapability(w['w'] as String)?.word, w['word'], reason: '«${w['w']}»');
      }
      expect(artifactAskCaps, [for (final c in v['caps'] as List) (c as num).toDouble()]);
      expect(artifactAskCapDefault, (v['capDefault'] as num).toDouble());
    });

    test('the sentences, in both languages, with and without the agent', () {
      for (final s in (v['sentences'] as List).cast<Map<String, dynamic>>()) {
        expect(
          capabilitySentence(s['lang'] as String, s['c'] as String, s['agent'] as String?),
          s['s'],
          reason: '${s['lang']} ${s['c']} ${s['agent']}',
        );
      }
    });

    test('an artifact as the server lists it: what it asks for once each, its grants', () {
      final a = ArtifactInfo.fromJson({
        'scope': 'project:demo',
        'place': 'Demo',
        'path': 'artefatti/a.html',
        'file': 'a.html',
        'name': 'A',
        'version': 2,
        'libs': ['d3'],
        'wants': ['ask', ' ask', 'files:dati', 'network'],
        'grants': [
          {'capability': 'ask', 'agentId': 'a1', 'capUsd': 2, 'spentUsd': 0.25, 'at': 'x'},
        ],
        'hasData': true,
        'size': 2048,
        'modifiedAt': '2026-11-17T10:00:00.000Z',
        'readOnly': false,
        'pendingRun': false,
      });
      expect([for (final c in a.wanted) c.word], ['ask', 'files:dati/']);
      expect(a.grantOf('ask')?.capUsd, 2);
      expect(a.grantOf('files:dati/'), isNull);
      expect(artifactBytes(a.size), '2.0 KB');
      expect(isRgArtifact('x.RGARTIFACT'), isTrue);
      expect(isRgArtifact('x.zip'), isFalse);
    });
  });

  group('the picture that forms (image.progress)', () {
    test('percent and the last preview; gone with the tool\'s result or a history', () {
      final m = LiveModel();
      m.apply({'type': 'image.progress', 'sessionId': 's1', 'percent': 30, 'preview': 'AAAA'});
      expect(m.view('s1').drawing, (percent: 30, preview: 'AAAA'));
      m.apply({'type': 'image.progress', 'sessionId': 's1', 'percent': 60});
      expect(m.view('s1').drawing, (percent: 60, preview: 'AAAA'));
      m.apply({
        'type': 'event',
        'sessionId': 's1',
        'event': _ev(9, 'tool.result', {'callId': 'c'}),
      });
      expect(m.view('s1').drawing, isNull);
      m.apply({'type': 'image.progress', 'sessionId': 's1', 'percent': 10});
      m.apply({'type': 'session.history', 'sessionId': 's1', 'events': [], 'incremental': true});
      expect(m.view('s1').drawing, isNull);
    });

    testWidgets('the card: the preview, the bar, the words', (tester) async {
      const png =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      Widget card(String? preview) => MaterialApp(
        locale: const Locale('it'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: buildTheme(Brightness.light),
        home: Scaffold(body: DrawingCard(percent: 42, preview: preview)),
      );
      await tester.pumpWidget(card(png));
      expect(find.byKey(const Key('drawing-preview')), findsOneWidget);
      expect(find.text('Disegno… 42%'), findsOneWidget);
      expect(
        tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator)).value,
        .42,
      );
      // No preview yet: the frame that shimmers.
      await tester.pumpWidget(card(null));
      expect(find.byKey(const Key('drawing-preview')), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('screens against the fake server', () {
    late FakeRedGiant server;
    late AppController app;
    late List<FakeHost> hosts;
    final posted = <Map<String, dynamic>>[];
    final events = <Map<String, dynamic>>[];

    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      server.permissions.clear();
      hosts = [];
      posted.clear();
      events
        ..clear()
        ..addAll([_ev(1, 'session.started', {}), _proposed]);
      debugWebHost = (_) => FakeHost(hosts);
      Future<void> record(HttpRequest r) async {
        final body = await utf8.decodeStream(r);
        posted.add({
          'route': '${r.method} ${r.uri.path}',
          if (r.uri.hasQuery) 'query': r.uri.queryParameters,
          if (body.isNotEmpty) 'body': jsonDecode(body),
        });
      }

      server.routes['GET /api/sessions/s1/events'] = (r) => server.answer(r, 200, events);
      server.routes['POST /api/sessions/s1/variants'] = (r) async {
        await record(r);
        final b = posted.last['body'] as Map<String, dynamic>;
        events.add(
          _ev(events.length + 1, 'variants.answered', {
            'proposalId': b['proposalId'],
            'variant': b['variant'],
            'choice': b['choice'] == true,
            'comment': ?b['comment'],
          }),
        );
        return server.answer(r, 200, {'ok': true});
      };
    });
    tearDown(() async {
      debugWebHost = null;
      await server.close();
    });

    Future<void> open(
      WidgetTester tester,
      Widget screen, {
      Size size = const Size(390, 844),
    }) async {
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => screen))
          .ignore();
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the board: native around, each variant the page alone at its screen\'s width', (
      tester,
    ) async {
      await open(
        tester,
        const BoardScreen(sessionId: 's1', proposalId: _board),
        size: const Size(1280, 900),
      );
      expect(find.text("The site's home page"), findsOneWidget);
      expect(find.text('Three ways to the front page.'), findsOneWidget);
      expect(find.text('Red on black'), findsOneWidget);
      expect(find.byKey(const Key('board-variant-3')), findsOneWidget);
      // One web view per variant, each the board's embed for its number, at the computer's width.
      final frames = [for (final h in hosts) ?parseEmbedHash(h.loaded!.fragment)];
      expect(frames.map((p) => '${p.embed.name} ${p.board} ${p.variant} ${p.screen}'), [
        'board s1.$_board 1 computer',
        'board s1.$_board 2 computer',
        'board s1.$_board 3 computer',
      ]);
      expect({for (final p in frames) p.bridge}.length, 3, reason: 'a nonce of its own each');
      expect(hosts.first.loaded!.hasQuery, isFalse);
      // The phone's width: the frames load again, at that width.
      await tester.tap(find.byKey(const Key('board-screen-phone')));
      await _settle(tester);
      expect(
        [for (final h in hosts.skip(3)) parseEmbedHash(h.loaded!.fragment)!.screen],
        ['phone', 'phone', 'phone'],
      );
      // A comment needs words; a choice does not.
      await tester.ensureVisible(find.byKey(const Key('board-send-2')));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('board-send-2')));
      await _settle(tester, 2);
      expect(find.text('Scrivi un commento'), findsOneWidget);
      expect(posted, isEmpty);
      await tester.ensureVisible(find.byKey(const Key('board-choose-2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('board-choose-2')));
      await _settle(tester);
      expect(posted.single['body'], {'proposalId': _board, 'variant': 2, 'choice': true});
      expect(find.byKey(const Key('board-chosen-2')), findsOneWidget);
      expect(find.text("Mandato all'agente"), findsOneWidget);
      // A comment on the whole board: variant null, the words, and it shows under it.
      await tester.ensureVisible(find.byKey(const Key('board-comment-all')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('board-comment-all')), 'Il colore della 2');
      await tester.tap(find.byKey(const Key('board-send-all')));
      await _settle(tester);
      expect(posted.last['body'], {
        'proposalId': _board,
        'variant': null,
        'comment': 'Il colore della 2',
      });
      expect(find.textContaining('commento: Il colore della 2'), findsOneWidget);
      await done(tester);
    });

    testWidgets('a board on the phone: one column; full screen, then «I choose this»', (
      tester,
    ) async {
      await open(tester, const BoardScreen(sessionId: 's1', proposalId: _board));
      final w1 = tester.getSize(find.byKey(const Key('board-variant-1'))).width;
      expect(w1, closeTo(390 - 28, 1));
      await tester.tap(find.byKey(const Key('board-full-1')));
      await _settle(tester);
      expect(find.text('1. Dark'), findsOneWidget);
      expect(parseEmbedHash(hosts.last.loaded!.fragment)!.variant, 1);
      await tester.tap(find.byKey(const Key('board-full-choose')));
      await _settle(tester);
      expect(posted.single['body'], {'proposalId': _board, 'variant': 1, 'choice': true});
      expect(find.byKey(const Key('board-chosen-1')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a board that is no longer there says so', (tester) async {
      await open(tester, const BoardScreen(sessionId: 's1', proposalId: '000000000000'));
      expect(find.text("Questa tavola non c'è più"), findsOneWidget);
      await done(tester);
    });

    testWidgets('from the chat: the board\'s card opens the board, a port\'s line the port', (
      tester,
    ) async {
      server.store('s1', 'variants.proposed', _proposed['payload'] as Map<String, dynamic>);
      server.store('s1', 'canvas.show', {
        'title': 'Il sito',
        'target': {'kind': 'port', 'agentId': 'a0', 'port': 5173, 'path': '/app'},
      });
      String? portLinkBody;
      server.routes['POST /api/canvas/link'] = (r) async {
        portLinkBody = await utf8.decodeStream(r);
        return server.answer(r, 200, {'url': '/preview/p0rt/app'});
      };
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
      // The port: the page in embed=port, the agent's name and the port under its title.
      final line = find.textContaining('Il sito');
      await tester.ensureVisible(line.first);
      await tester.pump();
      await tester.tap(line.first);
      await _settle(tester);
      final p = parseEmbedHash(hosts.last.loaded!.fragment)!;
      expect('${p.embed.name} ${p.agent} ${p.port} ${p.path} ${p.session}', 'port a0 5173 /app s1');
      expect(find.byKey(const Key('canvas-title')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('canvas-title'))).data, 'Il sito');
      expect(
        tester.widget<Text>(find.byKey(const Key('canvas-meta'))).data,
        contains('Porta 5173'),
      );
      // The page's own title does not replace the agent's words.
      hosts.last.say({'t': 'ready'});
      hosts.last.say({'t': 'title', 'name': 'Porta 5173', 'kind': 'site'});
      await _settle(tester, 2);
      expect(tester.widget<Text>(find.byKey(const Key('canvas-title'))).data, 'Il sito');
      await tester.tap(find.byKey(const Key('canvas-panel-reload')));
      await _settle(tester, 2);
      expect(hosts.last.reloads, 1);
      // A link a preview inside wants: asked natively, nothing opened by itself.
      hosts.last.say({'t': 'previewLink', 'url': 'https://example.com/doc'});
      await _settle(tester, 2);
      expect(find.text('La pagina vuole aprire un link'), findsOneWidget);
      expect(find.text('https://example.com/doc'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog-no')));
      await _settle(tester, 2);
      expect(portLinkBody, isNull, reason: 'the signed link only for «Open in the browser»');
      await tester.tap(find.byKey(const Key('canvas-back')));
      await _settle(tester);
      // The board's card.
      await tester.ensureVisible(find.byKey(const Key('variants-$_board')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('variants-$_board')));
      await _settle(tester);
      expect(find.byType(BoardScreen), findsOneWidget);
      await done(tester);
    });

    testWidgets('Settings › Artifacts: by place, facts, permissions, grant with a cap, delete', (
      tester,
    ) async {
      Map<String, dynamic> art(
        String scope,
        String place,
        String file,
        String name, {
        List<String> wants = const [],
        List<Map<String, dynamic>> grants = const [],
        bool readOnly = false,
        bool pendingRun = false,
      }) => {
        'scope': scope,
        'place': place,
        'projectId': null,
        'path': 'artefatti/$file',
        'file': file,
        'name': name,
        'header': true,
        'version': 4,
        'libs': ['preact', 'chartjs'],
        'wants': wants,
        'granted': [for (final g in grants) g['capability']],
        'grants': grants,
        'hasData': false,
        'from': 'a0',
        'size': 3072,
        'modifiedAt': '2026-11-17T10:00:00.000Z',
        'readOnly': readOnly,
        'pendingRun': pendingRun,
      };
      var list = [
        art(
          'platform',
          'Platform',
          'torneo.html',
          'Tabellone del torneo',
          wants: ['ask', 'storage'],
        ),
        art(
          'assistants',
          'Desk',
          'csv.html',
          'Visualizzatore CSV',
          wants: ['files:dati/'],
          grants: [
            {'capability': 'files:dati/', 'at': '2026-11-17T10:00:00.000Z'},
          ],
        ),
      ];
      server.routes['GET /api/artifacts'] = (r) => server.answer(r, 200, list);
      for (final route in ['grant', 'revoke']) {
        server.routes['POST /api/artifacts/$route'] = (r) async {
          posted.add({'route': route, 'body': jsonDecode(await utf8.decodeStream(r))});
          return server.answer(r, 200, <Object>[]);
        };
      }
      server.routes['POST /api/files/op'] = (r) async {
        posted.add({'route': 'op', 'body': jsonDecode(await utf8.decodeStream(r))});
        list = [list.last];
        return server.answer(r, 200, {'ok': true});
      };
      await open(tester, const ArtifactsScreen(), size: const Size(390, 2400));
      expect(find.text('Artefatti'), findsWidgets);
      expect(find.text('Tabellone del torneo'), findsOneWidget);
      // God's folder and the desk in the person's words.
      expect(find.text('Cartella di God'), findsOneWidget);
      expect(find.textContaining('versione 4'), findsWidgets);
      expect(find.textContaining('librerie: preact, chartjs'), findsWidgets);
      expect(find.textContaining('3.0 KB'), findsWidgets);
      expect(find.textContaining('fare domande a «God»'), findsOneWidget);
      expect(
        find.byKey(const Key('artifact-revoke-artefatti/csv.html-files:dati/')),
        findsOneWidget,
      );
      // «ask» with the cap the person picks.
      await tester.tap(find.byKey(const Key('artifact-cap-artefatti/torneo.html-2.0')));
      await _settle(tester, 2);
      await tester.tap(find.byKey(const Key('artifact-grant-artefatti/torneo.html-ask')));
      await _settle(tester);
      expect(posted.last, {
        'route': 'grant',
        'body': {
          'scope': 'platform',
          'path': 'artefatti/torneo.html',
          'capability': 'ask',
          'capUsd': 2.0,
        },
      });
      await tester.ensureVisible(
        find.byKey(const Key('artifact-revoke-artefatti/csv.html-files:dati/')),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('artifact-revoke-artefatti/csv.html-files:dati/')));
      await _settle(tester);
      expect(posted.last['body'], {
        'scope': 'assistants',
        'path': 'artefatti/csv.html',
        'capability': 'files:dati/',
      });
      // Delete: our window first, then the explorer's deletion.
      await tester.ensureVisible(find.byKey(const Key('artifact-delete-artefatti/torneo.html')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('artifact-delete-artefatti/torneo.html')));
      await _settle(tester, 2);
      expect(find.text('Eliminare «Tabellone del torneo»?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dialog-yes')));
      await _settle(tester);
      expect(posted.last['body'], {
        'op': 'delete',
        'scope': 'platform',
        'path': 'artefatti/torneo.html',
      });
      expect(find.text('Tabellone del torneo'), findsNothing);
      // Export: the two ways, in our window.
      await tester.tap(find.byKey(const Key('artifact-export-artefatti/csv.html')));
      await _settle(tester, 2);
      expect(find.byKey(const Key('artifact-export-zip')), findsOneWidget);
      expect(find.byKey(const Key('artifact-export-html')), findsOneWidget);
      await done(tester);
    });

    testWidgets('no artifacts yet: the empty card', (tester) async {
      server.routes['GET /api/artifacts'] = (r) => server.answer(r, 200, <Object>[]);
      await open(tester, const ArtifactsScreen());
      expect(find.byKey(const Key('artifacts-empty')), findsOneWidget);
      await done(tester);
    });
  });
}
