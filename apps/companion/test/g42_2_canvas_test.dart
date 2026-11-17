// G42.2: the Canvas opens by itself when an agent shows something while the person watches, as
// the page's `canvasEvent`/`openCanvas`: once per event, never when the log replays; a panel on
// the right of the conversation on a computer (tabs, the same thing again brings its tab
// forward, an agent moving in a tab leaves it as it is), the whole screen on a phone.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/live_model.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/embed_screen.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/screens/canvas_panel.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'fake_server.dart';

class _Host implements WebHost {
  _Host(this.all);

  final List<_Host> all;
  Uri? loaded;

  @override
  Stream<String> get messages => const Stream.empty();

  @override
  Future<void> load(Uri url, WebRules r) async {
    loaded = url;
    all.add(this);
  }

  @override
  Future<void> run(String script) async {}

  @override
  Future<void> reload() async {}

  @override
  Widget view({required bool eager}) => const SizedBox.expand(key: Key('fake-web'));

  @override
  void dispose() {}
}

Map<String, dynamic> _ev(int seq, String type, Map<String, dynamic> p) => {
  'seq': seq,
  'ts': '2026-11-17T10:00:00.000Z',
  'sessionId': 's1',
  'type': type,
  'payload': p,
};

const _port = {'kind': 'port', 'agentId': 'a0', 'port': 5173};
const _file = {'kind': 'file', 'scope': 'platform', 'path': 'note.md'};

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('what agents show, seen live (the page\'s canvasEvent)', () {
    test('once per event, never from the replayed log; canvas.act brings forward only', () async {
      final m = LiveModel();
      final got = <CanvasShown>[];
      final sub = m.canvasShown.listen(got.add);
      // The log as it is replayed: nothing opens.
      m.apply({
        'type': 'session.history',
        'sessionId': 's1',
        'events': [
          _ev(1, 'canvas.show', {'title': 'Old', 'target': _file}),
        ],
      });
      m.apply({
        'type': 'event',
        'sessionId': 's1',
        'event': _ev(2, 'canvas.show', {'title': 'Il sito', 'target': _port}),
      });
      // The owner-wide copy of the same event, then another conversation's.
      m.apply({
        'type': 'canvas.open',
        'sessionId': 's1',
        'event': _ev(2, 'canvas.show', {'title': 'Il sito', 'target': _port}),
      });
      m.apply({
        'type': 'canvas.open',
        'sessionId': 's9',
        'event': _ev(4, 'canvas.act', {'title': 'Nota', 'target': _file}),
      });
      // Something else, or a target that is not one.
      m.apply({
        'type': 'event',
        'sessionId': 's1',
        'event': _ev(5, 'message.user', {'text': 'x'}),
      });
      m.apply({
        'type': 'event',
        'sessionId': 's1',
        'event': _ev(6, 'canvas.show', {'title': 'x'}),
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        [for (final s in got) '${s.sessionId} ${s.seq} ${s.title} ${s.keep}'],
        ['s1 2 Il sito false', 's9 4 Nota true'],
      );
      await sub.cancel();
    });
  });

  group('the panel\'s tabs (the page\'s openCanvas)', () {
    test('a tab each, the same again forward, an agent moving leaves it, the last closes it', () {
      final m = CanvasPanelModel();
      m.show('Il sito', _port);
      m.show('Nota', _file);
      expect([for (final t in m.tabs) t.title], ['Il sito', 'Nota']);
      expect(m.current?.title, 'Nota');
      m.show('Il sito, di nuovo', _port);
      expect(m.tabs.length, 2);
      expect(m.current?.title, 'Il sito, di nuovo');
      m.show('Nota mossa', _file, keep: true);
      expect(m.current?.title, 'Nota');
      m.show('niente', const {'kind': 'file', 'scope': 'platform'});
      expect(m.tabs.length, 2);
      m.hide();
      expect(m.open, isFalse);
      expect(m.tabs.length, 2, reason: 'the tabs stay; the line in the chat brings them back');
      m.show('Nota', _file);
      expect(m.open, isTrue);
      m.close(canvasTabId(_file));
      expect(m.current?.isPort, isTrue);
      m.close(canvasTabId(_port));
      expect(m.open, isFalse);
      expect(canvasTabId({..._port, 'path': '/a'}), 'canvas:a0:5173:/a');
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
      await server.close();
    });

    Future<void> open(WidgetTester tester, Size size) async {
      app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.linux,
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

    testWidgets('a computer: shown live, the panel opens on the right with the page in it', (
      tester,
    ) async {
      await open(tester, const Size(1400, 900));
      expect(find.byKey(const Key('canvas-panel')), findsNothing);
      server.store('s1', 'canvas.show', {'title': 'Il sito', 'target': _port});
      await _settle(tester);
      expect(find.byKey(const Key('canvas-panel')), findsOneWidget);
      final p = parseEmbedHash(hosts.last.loaded!.fragment)!;
      expect('${p.embed.name} ${p.agent} ${p.port} ${p.session}', 'port a0 5173 s1');
      // Another thing: a tab of its own, in front.
      server.store('s1', 'canvas.show', {'title': 'Nota', 'target': _file});
      await _settle(tester);
      expect(find.byKey(Key('canvas-tab-${canvasTabId(_port)}')), findsOneWidget);
      expect(parseEmbedHash(hosts.last.loaded!.fragment)!.embed, EmbedKind.canvas);
      // Back to the chat: the area goes; the line in the chat brings it back.
      await tester.tap(find.byKey(const Key('canvas-panel-hide')));
      await _settle(tester, 2);
      expect(find.byKey(const Key('canvas-panel')), findsNothing);
      final line = find.textContaining('Il sito');
      await tester.ensureVisible(line.first);
      await tester.pump();
      await tester.tap(line.first);
      await _settle(tester, 2);
      expect(find.byKey(const Key('canvas-panel')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a phone: shown live, the whole screen; the replayed log opens nothing', (
      tester,
    ) async {
      server.store('s1', 'canvas.show', {'title': 'Vecchio', 'target': _port});
      await open(tester, const Size(390, 844));
      expect(find.byType(EmbedScreen), findsNothing);
      // The big card of a phone.
      expect(find.text('Vecchio'), findsOneWidget);
      server.store('s1', 'canvas.show', {'title': 'Il sito', 'target': _port});
      await _settle(tester);
      expect(find.byType(EmbedScreen), findsOneWidget);
      expect(find.byKey(const Key('canvas-panel')), findsNothing);
      expect(jsonEncode(parseEmbedHash(hosts.last.loaded!.fragment)!.toJson()), contains('5173'));
      await done(tester);
    });
  });
}
