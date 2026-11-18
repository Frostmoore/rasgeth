// G42.6: the Canvas's native frame around the page's viewers. The tabs (a few web views alive
// together), the bar the page fills (`title`, `bar`) with the tab's own buttons sent back as
// `action`, a tab the page asks for (`open`), the app's tabs told to every page (`tabs`, for an
// agent that looks), «Maximize» over the conversation, the whole screen, the phone's Canvas screen
// with the same tabs, and the app's own viewers when the page cannot be shown or does not answer.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/canvas/canvas_shell.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/screens/canvas_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/artifact_frame_view.dart';

import 'fake_server.dart';

/// A web view of the test's own: what it loaded, the scripts run in it, and the page's voice.
class _Host implements WebHost {
  _Host(this.all);

  final List<_Host> all;
  final out = StreamController<String>.broadcast();
  final scripts = <String>[];
  Uri? loaded;
  bool disposed = false;

  EmbedParams get params => parseEmbedHash(loaded!.fragment)!;

  void say(Map<String, Object?> m) =>
      out.add(jsonEncode({'rg': 'embed', 'n': params.bridge, 'm': m}));

  /// The app's messages to the page, decoded.
  List<Map<String, dynamic>> get told => [
    for (final s in scripts)
      if (s.startsWith('window.postMessage('))
        (jsonDecode(s.substring('window.postMessage('.length, s.lastIndexOf(', location.origin')))
                as Map<String, dynamic>)['m']
            as Map<String, dynamic>,
  ];

  @override
  Stream<String> get messages => out.stream;

  @override
  Future<void> load(Uri url, WebRules r) async {
    loaded = url;
    all.add(this);
  }

  @override
  Future<void> run(String script) async => scripts.add(script);

  @override
  Future<void> reload() async {}

  @override
  Widget view({required bool eager}) => const SizedBox.expand(key: Key('fake-web'));

  @override
  void dispose() => disposed = true;
}

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _pdf = {'kind': 'file', 'scope': 'platform', 'path': 'docs/report.pdf'};
const _md = {'kind': 'file', 'scope': 'platform', 'path': 'note.md'};
const _port = {'kind': 'port', 'agentId': 'a0', 'port': 5173};

void main() {
  group('the tabs (pure)', () {
    test('a few web views alive: the one in front and the last seen', () {
      expect(canvasAliveMax(phone: false, linux: false), 3);
      expect(canvasAliveMax(phone: true, linux: false), 2);
      expect(canvasAliveMax(phone: false, linux: true), 1);
      final m = CanvasPanelModel()
        ..show('a', _pdf)
        ..show('b', _md)
        ..show('c', _port);
      expect(m.alive(2), {canvasTabId(_port), canvasTabId(_md)});
      m.select(canvasTabId(_pdf));
      expect(m.alive(2), {canvasTabId(_pdf), canvasTabId(_port)});
      expect(m.alive(1), {canvasTabId(_pdf)});
      m.close(canvasTabId(_port));
      expect(m.alive(3), {canvasTabId(_pdf), canvasTabId(_md)});
    });

    test('the app\'s tabs as the page\'s `tabs` names them; what the page said, per tab', () {
      final m = CanvasPanelModel()
        ..show('Rapporto', {
          ..._pdf,
          'at': {'page': 3},
        })
        ..show('Il sito', _port);
      expect(m.wireTabs(), [
        {
          'title': 'Rapporto',
          'target': {
            'kind': 'file',
            'scope': 'platform',
            'path': 'docs/report.pdf',
            'at': {'page': 3},
          },
          'active': false,
        },
        {
          'title': 'Il sito',
          'target': {'kind': 'port', 'agentId': 'a0', 'port': 5173},
          'active': true,
        },
      ]);
      m.tell(canvasTabId(_pdf), (w) => w.copyWith(kind: 'pdf', size: 2048));
      m.tell(canvasTabId(_pdf), (w) => w.copyWith(save: 'saving'));
      expect(m.info[canvasTabId(_pdf)]?.kind, 'pdf');
      expect(m.info[canvasTabId(_pdf)]?.save, 'saving');
      m.tell('nothing', (w) => w.copyWith(kind: 'x'));
      expect(m.info.containsKey('nothing'), isFalse);
      m.close(canvasTabId(_pdf));
      expect(m.info, isEmpty);
      m.setMax(true);
      m.close(canvasTabId(_port));
      expect((m.open, m.max), (false, false));
    });
  });

  group('in the conversation, against the fake server', () {
    late FakeRedGiant server;
    late AppController app;
    late List<_Host> hosts;

    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      server.permissions.clear();
      hosts = [];
      debugWebHost = (_) => _Host(hosts);
    });
    tearDown(() async {
      debugWebHost = null;
      debugFrameSupport = null;
      await server.close();
    });

    Future<void> open(WidgetTester tester, Size size) async {
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: size.width < 600 ? DevicePlatform.android : DevicePlatform.windows,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = size;
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

    testWidgets('a computer: the frame, the bar the page fills, its buttons, a tab it asks for', (
      tester,
    ) async {
      await open(tester, const Size(1400, 900));
      server.store('s1', 'canvas.show', {'title': 'Rapporto', 'target': _pdf});
      await _settle(tester);
      expect(find.byKey(const Key('canvas-panel')), findsOneWidget);
      expect(find.byKey(const Key('canvas-strip')), findsOneWidget);
      final h = hosts.last;
      expect(
        '${h.params.embed.name} ${h.params.scope} ${h.params.path} ${h.params.session}',
        'canvas platform docs/report.pdf s1',
      );
      // The page: drawn, its kind and weight, its bar.
      h
        ..say({'t': 'ready'})
        ..say({'t': 'title', 'name': 'report.pdf', 'kind': 'pdf', 'size': 2048})
        ..say({
          't': 'bar',
          'actions': [
            {'id': 'copy.edit', 'label': 'Modifica una copia', 'icon': 'pencil'},
            {'id': 'keys', 'label': 'Scorciatoie', 'icon': 'keyboard'},
          ],
          'note': "L'agente è andato a pagina 3",
          'link': '/preview/T/docs/report.pdf?v=1-0',
          'download': true,
        });
      await _settle(tester);
      expect(find.byKey(const Key('canvas-title')), findsOneWidget);
      expect(find.text('report.pdf'), findsWidgets);
      expect(find.text('PDF · 2 KB'), findsOneWidget);
      expect(find.text("L'agente è andato a pagina 3"), findsOneWidget);
      expect(find.byKey(const Key('canvas-download')), findsOneWidget);
      // The app tells the page its tabs, this one in view.
      expect(h.told.where((m) => m['t'] == 'tabs').last, {
        't': 'tabs',
        'visible': true,
        'tabs': [
          {
            'title': 'Rapporto',
            'target': {'kind': 'file', 'scope': 'platform', 'path': 'docs/report.pdf'},
            'active': true,
          },
        ],
      });
      // A button of the page's, drawn by the app: back to the page as `action`.
      await tester.tap(find.byKey(const Key('canvas-action-copy.edit')));
      await _settle(tester, 2);
      expect(h.told.any((m) => m['t'] == 'action' && m['id'] == 'copy.edit'), isTrue);
      // The page asks for another tab (the open copy it made): a tab of the app's.
      h.say({
        't': 'open',
        'title': 'report.odg',
        'target': {'kind': 'file', 'scope': 'platform', 'path': 'docs/report.pdf.open/report.odg'},
      });
      await _settle(tester);
      expect(
        find.byKey(const Key('canvas-tab-canvas:platform:docs/report.pdf.open/report.odg')),
        findsOneWidget,
      );
      expect(hosts.last.params.path, 'docs/report.pdf.open/report.odg');
      // The first stays alive behind (a computer keeps three), and is told it is not in view.
      expect(h.disposed, isFalse);
      expect(h.told.where((m) => m['t'] == 'tabs').last['visible'], isFalse);
      await done(tester);
    });

    testWidgets('a computer: «Maximize» covers the conversation, the whole screen only the page', (
      tester,
    ) async {
      await open(tester, const Size(1400, 900));
      server.store('s1', 'canvas.show', {'title': 'Il sito', 'target': _port});
      await _settle(tester);
      final normal = tester.getSize(find.byKey(const Key('canvas-panel'))).width;
      expect(normal, lessThan(1000));
      await tester.tap(find.byKey(const Key('canvas-max')));
      await _settle(tester, 2);
      expect(tester.getSize(find.byKey(const Key('canvas-panel'))).width, 1400);
      expect(find.text('Torna alla chat'), findsOneWidget);
      await tester.tap(find.byKey(const Key('canvas-full')));
      await _settle(tester, 2);
      expect(find.byKey(const Key('canvas-strip')), findsNothing);
      expect(find.byKey(const Key('canvas-bar')), findsNothing);
      await tester.tap(find.byKey(const Key('canvas-full-exit')));
      await _settle(tester, 2);
      expect(find.byKey(const Key('canvas-bar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('canvas-panel-hide')));
      await _settle(tester, 2);
      expect(tester.getSize(find.byKey(const Key('canvas-panel'))).width, normal);
      // The same web view all along: nothing loaded again.
      expect(hosts, hasLength(1));
      await done(tester);
    });

    testWidgets('a phone: the Canvas screen with the conversation\'s tabs', (tester) async {
      await open(tester, const Size(390, 844));
      server.store('s1', 'canvas.show', {'title': 'Il sito', 'target': _port});
      await _settle(tester);
      expect(find.byKey(const Key('canvas-screen')), findsOneWidget);
      expect(find.byKey(const Key('canvas-back')), findsOneWidget);
      // Another thing shown while it is open: a tab in the same screen.
      server.store('s1', 'canvas.show', {'title': 'Rapporto', 'target': _pdf});
      await _settle(tester);
      expect(find.byKey(const Key('canvas-screen')), findsOneWidget);
      expect(find.byKey(Key('canvas-tab-${canvasTabId(_port)}')), findsOneWidget);
      expect(find.byKey(Key('canvas-tab-${canvasTabId(_pdf)}')), findsOneWidget);
      expect(hosts.last.params.embed, EmbedKind.canvas);
      // A phone keeps two web views: a third tab lets the oldest go.
      server.store('s1', 'canvas.show', {'title': 'Nota', 'target': _md});
      await _settle(tester);
      expect(hosts.first.disposed, isTrue);
      await tester.tap(find.byKey(const Key('canvas-back')));
      await _settle(tester, 12);
      expect(find.byKey(const Key('canvas-screen')), findsNothing);
      await done(tester);
    });

    testWidgets('the page does not answer: the app\'s own viewer, «Riprova»', (tester) async {
      await open(tester, const Size(1400, 900));
      server.store('s1', 'canvas.show', {'title': 'Nota', 'target': _md});
      await _settle(tester);
      expect(find.byKey(const Key('embed-fallback')), findsNothing);
      await tester.pump(const Duration(seconds: 26));
      await _settle(tester);
      expect(find.byKey(const Key('embed-fallback')), findsOneWidget);
      expect(find.byKey(const Key('canvas-markdown')), findsOneWidget);
      expect(find.byKey(const Key('embed-fallback-retry')), findsOneWidget);
      await done(tester);
    });

    testWidgets('no page inside the app (no safe way): the native screen', (tester) async {
      debugFrameSupport = (_) => FrameSupport.none;
      await open(tester, const Size(390, 844));
      unawaited(
        openCanvas(
          tester.element(find.byType(ConversationScreen)),
          scope: 'platform',
          path: 'note.md',
        ),
      );
      await _settle(tester);
      expect(find.byType(CanvasScreen), findsOneWidget);
      expect(find.byKey(const Key('canvas-markdown')), findsOneWidget);
      expect(hosts, isEmpty);
      await done(tester);
    });
  });
}
