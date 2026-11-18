// G42.7: the page's editors inside the app's Canvas. The save state the page says (`saveState`)
// in the native bar, a failure with why and «Try saving again» (Ctrl/Cmd+S to the page); the
// app's keys passed on when the focus is in the frame; «Ask the agent» (the page's action) only
// where there is a composer, its `askAgent` quoted in the conversation's composer (a phone goes
// back to the conversation); «Paste a picture» from the system's clipboard as `paste`, also with
// Ctrl/Cmd+V; an archived project's file said read only in the bar.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/canvas/canvas_shell.dart';
import 'package:rgcompanion/embed/embed_link.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/artifact_frame_view.dart';
import 'package:rgcompanion/ui/paste_files.dart';

import 'fake_server.dart';

/// A web view of the test's own: what it loaded, the scripts run in it, and the page's voice.
class _Host implements WebHost {
  _Host(this.all);

  final List<_Host> all;
  final out = StreamController<String>.broadcast();
  final scripts = <String>[];
  Uri? loaded;

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
  void dispose() {}
}

/// The system's clipboard, as the test wants it.
class _Clipboard extends ClipboardReader {
  List<PastedFile> copied = const [];
  Uint8List? picture;

  @override
  Future<List<PastedFile>> files() async => copied;

  @override
  Future<Uint8List?> image() async => picture;

  @override
  Future<bool> hasText() async => false;
}

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _ts = {'kind': 'file', 'scope': 'platform', 'path': 'src/a.ts'};
const _ora = {'kind': 'file', 'scope': 'platform', 'path': 'art/layers.ora'};
final _png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

Finder _composerWith(String text) => find.byWidgetPredicate(
  (w) => w is EditableText && w.controller.text.contains(text),
  description: 'a field with «$text»',
);

void main() {
  late FakeRedGiant server;
  late AppController app;
  late List<_Host> hosts;
  late _Clipboard clip;

  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.permissions.clear();
    hosts = [];
    debugWebHost = (_) => _Host(hosts);
    clip = _Clipboard();
    clipboardReader = clip;
  });
  tearDown(() async {
    debugWebHost = null;
    debugFrameSupport = null;
    clipboardReader = const SystemClipboardReader();
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

  Future<_Host> show(WidgetTester tester, Map<String, Object> target, String name) async {
    server.store('s1', 'canvas.show', {'title': name, 'target': target});
    await _settle(tester);
    final h = hosts.last;
    h
      ..say({'t': 'ready'})
      ..say({'t': 'title', 'name': name, 'kind': 'code', 'size': 1200});
    await _settle(tester);
    return h;
  }

  testWidgets('the save state in the native bar; a failure says why and saves again', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _ts, 'a.ts');
    h.say({'t': 'saveState', 'state': 'saving'});
    await _settle(tester, 2);
    expect(find.byKey(const Key('canvas-save-saving')), findsOneWidget);
    expect(find.text('Salvataggio…'), findsOneWidget);
    h.say({'t': 'saveState', 'state': 'saved'});
    await _settle(tester, 2);
    expect(find.byKey(const Key('canvas-save-saved')), findsOneWidget);
    expect(find.text('Salvato'), findsOneWidget);
    expect(find.byKey(const Key('canvas-save-retry')), findsNothing);
    h.say({'t': 'saveState', 'state': 'error', 'error': 'disco pieno'});
    await _settle(tester, 2);
    expect(find.byKey(const Key('canvas-save-error')), findsOneWidget);
    expect(find.text('Non salvato'), findsOneWidget);
    final tip = tester.widget<Tooltip>(
      find.ancestor(of: find.byKey(const Key('canvas-save-error')), matching: find.byType(Tooltip)),
    );
    expect(tip.message, contains('disco pieno'));
    await tester.tap(find.byKey(const Key('canvas-save-retry')));
    await _settle(tester, 2);
    expect(h.told.where((m) => m['t'] == 'key').map((m) => m['key']), ['save']);
    await done(tester);
  });

  testWidgets('the focus in the frame: Ctrl+S, Z, Shift+Z and F go to the page', (tester) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _ts, 'a.ts');
    Focus.of(tester.element(find.byKey(const Key('canvas-bar')))).requestFocus();
    await tester.pump();
    Future<void> chord(LogicalKeyboardKey k, {bool shift = false}) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(k);
      if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    await chord(LogicalKeyboardKey.keyS);
    await chord(LogicalKeyboardKey.keyZ);
    await chord(LogicalKeyboardKey.keyZ, shift: true);
    await chord(LogicalKeyboardKey.keyF);
    await _settle(tester, 2);
    expect(h.told.where((m) => m['t'] == 'key').map((m) => m['key']), [
      'save',
      'undo',
      'redo',
      'find',
    ]);
    await done(tester);
  });

  testWidgets('«Ask the agent»: the page\'s action, its question quoted in the composer', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _ts, 'a.ts');
    h.say({
      't': 'bar',
      'actions': [
        {'id': 'ask', 'label': "Chiedi all'agente", 'icon': 'chat'},
        {'id': 'keys', 'label': 'Scorciatoie', 'icon': 'keyboard'},
      ],
    });
    await _settle(tester, 2);
    await tester.tap(find.byKey(const Key('canvas-action-ask')));
    await _settle(tester, 2);
    expect(h.told.where((m) => m['t'] == 'action').map((m) => m['id']), ['ask']);
    // The page answers with what is selected and where.
    h.say({
      't': 'askAgent',
      'text': 'const a = 1;\nconst b = 2;',
      'ref': {'scope': 'platform', 'path': 'src/a.ts', 'line': 4, 'lineEnd': 5},
    });
    await _settle(tester, 3);
    expect(_composerWith('> const a = 1;\n> const b = 2;\n(src/a.ts:4-5)'), findsOneWidget);
    expect(find.text('Messo nel messaggio della conversazione'), findsOneWidget);
    // On a computer the Canvas stays beside the conversation.
    expect(find.byKey(const Key('canvas-panel')), findsOneWidget);
    await done(tester);
  });

  testWidgets('a phone: «Ask the agent» brings the conversation back with the question', (
    tester,
  ) async {
    await open(tester, const Size(390, 844));
    final h = await show(tester, _ts, 'a.ts');
    expect(find.byKey(const Key('canvas-screen')), findsOneWidget);
    h.say({
      't': 'askAgent',
      'text': 'perché?',
      'ref': {'scope': 'platform', 'path': 'src/a.ts', 'line': 7},
    });
    await _settle(tester, 12);
    expect(find.byKey(const Key('canvas-screen')), findsNothing);
    expect(_composerWith('> perché?\n(src/a.ts:7)'), findsOneWidget);
    await done(tester);
  });

  testWidgets('no composer (a Canvas of its own): no «Ask the agent»', (tester) async {
    await open(tester, const Size(390, 844));
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
    unawaited(
      showInCanvas(
        tester.element(find.byType(Navigator).first),
        title: 'a.ts',
        target: Map<String, dynamic>.from(_ts),
      ),
    );
    await _settle(tester);
    final h = hosts.last;
    h
      ..say({'t': 'ready'})
      ..say({
        't': 'bar',
        'actions': [
          {'id': 'ask', 'label': "Chiedi all'agente", 'icon': 'chat'},
          {'id': 'copy.edit', 'label': 'Modifica una copia', 'icon': 'pencil'},
        ],
      });
    await _settle(tester, 2);
    expect(find.byKey(const Key('canvas-action-copy.edit')), findsOneWidget);
    expect(find.byKey(const Key('canvas-action-ask')), findsNothing);
    await done(tester);
  });

  testWidgets('«Paste a picture»: the system\'s clipboard to the editor, also with Ctrl+V', (
    tester,
  ) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _ora, 'layers.ora');
    // Not offered until the page says the tab takes one.
    expect(find.byKey(const Key('canvas-action-paste')), findsNothing);
    h.say({'t': 'bar', 'actions': [], 'paste': true});
    await _settle(tester, 2);
    expect(find.text('Incolla immagine'), findsOneWidget);
    // Nothing on the clipboard: said, nothing sent.
    await tester.tap(find.byKey(const Key('canvas-action-paste')));
    await _settle(tester, 2);
    expect(find.text("Negli appunti non c'è un'immagine"), findsOneWidget);
    expect(h.told.where((m) => m['t'] == 'paste'), isEmpty);
    // A picture (a screenshot): as a file of the page's.
    clip.picture = _png;
    await tester.tap(find.byKey(const Key('canvas-action-paste')));
    await _settle(tester, 3);
    final pasted = h.told.where((m) => m['t'] == 'paste').toList();
    expect(pasted, hasLength(1));
    final f = (pasted.single['files'] as List).single as Map;
    expect(f['type'], 'image/png');
    expect(f['size'], 8);
    expect(f['data'], base64Encode(_png));
    expect(f['name'] as String, matches(RegExp(r'^pasted-\d{4}-\d\d-\d\d-\d{6}\.png$')));
    // A picture file copied in the file manager comes first, under its own name.
    clip.copied = [('schizzo.png', _png)];
    Focus.of(tester.element(find.byKey(const Key('canvas-bar')))).requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await _settle(tester, 3);
    final again = h.told.where((m) => m['t'] == 'paste').toList();
    expect(again, hasLength(2));
    expect(((again.last['files'] as List).single as Map)['name'], 'schizzo.png');
    await done(tester);
  });

  testWidgets('an archived project\'s file: «Sola lettura» in the bar', (tester) async {
    await open(tester, const Size(1400, 900));
    final h = await show(tester, _ts, 'a.ts');
    h.say({'t': 'bar', 'actions': [], 'readOnly': true, 'download': true});
    await _settle(tester, 2);
    expect(find.text('Codice · 1 KB · Sola lettura'), findsOneWidget);
    expect(find.byKey(const Key('canvas-download')), findsOneWidget);
    await done(tester);
  });
}
