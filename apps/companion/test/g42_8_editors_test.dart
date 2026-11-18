// G42.8: the sheet, document and 3D editors in the Canvas's frame. Documents and presentations
// open the embed isolated as a whole (`/embed-isolated.html`: LibreOffice's frame gets
// SharedArrayBuffer in WKWebView and WebKitGTK too), every other file the usual embed; the editors'
// «Save as…» comes over the bridge, and a document's «Open in the browser» is the page's own link.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';

import 'fake_server.dart';

/// A web view of the test's own: what it loaded and the page's voice.
class _Host implements WebHost {
  _Host(this.all);

  final List<_Host> all;
  final out = StreamController<String>.broadcast();
  Uri? loaded;

  EmbedParams get params => parseEmbedHash(loaded!.fragment)!;

  void say(Map<String, Object?> m) =>
      out.add(jsonEncode({'rg': 'embed', 'n': params.bridge, 'm': m}));

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
  Future<void> reload() async {}

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

Map<String, Object?> _file(String path) => {'kind': 'file', 'scope': 'platform', 'path': path};

void main() {
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

  Future<void> open(WidgetTester tester) async {
    app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.windows,
    )..locale = const Locale('it');
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(1400, 900);
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

  testWidgets('documents and slides open the isolated embed, sheets and 3D the usual one', (
    tester,
  ) async {
    await open(tester);
    final paths = {
      'docs/relazione.docx': '/embed-isolated.html',
      'docs/piano.pptx': '/embed-isolated.html',
      'docs/note.odt': '/embed-isolated.html',
      'dati/conti.ods': '/embed.html',
      'dati/budget.xlsx': '/embed.html',
      'modelli/sedia.glb': '/embed.html',
    };
    for (final p in paths.keys) {
      server.store('s1', 'canvas.show', {'title': p.split('/').last, 'target': _file(p)});
      await _settle(tester);
    }
    final seen = {for (final h in hosts) h.params.path: h.loaded!.path};
    expect(seen, paths);
    // Nothing but the fragment carries the tab: no query on either page.
    expect(hosts.every((h) => !h.loaded!.hasQuery), isTrue);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  });

  testWidgets('a document\'s bar: the page\'s link for «Open in the browser», «Save as…»', (
    tester,
  ) async {
    await open(tester);
    server.store('s1', 'canvas.show', {'title': 'relazione.odt', 'target': _file('relazione.odt')});
    await _settle(tester);
    final h = hosts.last;
    h
      ..say({'t': 'ready'})
      ..say({'t': 'title', 'name': 'relazione.odt', 'kind': 'document', 'size': 4096})
      ..say({
        't': 'bar',
        'actions': <Object>[],
        'link': '/#open=canvas&scope=platform&path=relazione.odt',
        'download': true,
      });
    await _settle(tester);
    expect(find.byKey(const Key('canvas-panel-outside')), findsOneWidget);
    expect(find.byKey(const Key('canvas-download')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  });
}
