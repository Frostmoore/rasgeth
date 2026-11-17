// 3.8.8 (G42.5): the conversation's files, as the page's folder button and Explorer. The place of
// a conversation (a table), the families' icons (a table), the panel beside the conversation on a
// computer (kept open, full window, covering when narrow), every action against the fake
// RedGiant's workspace (which answers as files.ts), an archived project read only, the phone's
// screen, and a file dragged onto the conversation attached to the message.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/attachments.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/screens/canvas_screen.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/files/files_explorer.dart';
import 'package:rgcompanion/ui/file_icons.dart';

import 'fake_files.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

const _demo = 'project:demo';

FakeFiles _workspace() => FakeFiles()
  ..put(_demo, 'README.md', '# Demo\n')
  ..put(_demo, 'notes.txt', 'remember the prices\n')
  ..put(_demo, 'src/app.ts', 'export const year = 2026;\n')
  ..put(_demo, 'src/prices.ts', 'export const vat = 22;\n')
  ..put(_demo, 'docs/manual.pdf', [0x25, 0x50, 0x44, 0x46, 0, 1, 2])
  ..put(_demo, 'assets/big.bin', List<int>.filled(300000, 7))
  ..put(_demo, '.env', 'SECRET=no\n')
  ..mkdir(_demo, '.git');

void main() {
  group('the place of a conversation (the page\'s currentScope)', () {
    const demo = Project(id: 'demo', name: 'Demo');
    const old = Project(id: 'old', name: 'Old site', archived: true);
    Agent agent(AgentKind kind, [String? projectId]) =>
        Agent(id: 'x', kind: kind, name: 'X', active: true, projectId: projectId);
    final table = <(String, ExplorerPlace, String, bool)>[
      ('God', explorerPlaceOf(agent: agent(AgentKind.god)), 'platform', false),
      ('the Chat (no agent)', explorerPlaceOf(), 'platform', false),
      (
        'a personal agent',
        explorerPlaceOf(agent: agent(AgentKind.assistant, 'demo'), projects: [demo]),
        'assistants',
        false,
      ),
      (
        'a project agent',
        explorerPlaceOf(agent: agent(AgentKind.agent, 'demo'), projects: [demo]),
        'project:demo',
        false,
      ),
      (
        'an archived project',
        explorerPlaceOf(agent: agent(AgentKind.agent, 'old'), archived: [old]),
        'project:old',
        true,
      ),
      (
        'the conversation\'s project when the agent has none',
        explorerPlaceOf(agent: agent(AgentKind.agent), sessionProjectId: 'demo', projects: [demo]),
        'project:demo',
        false,
      ),
    ];
    for (final (name, place, scope, ro) in table) {
      test(name, () {
        expect(place.scope, scope);
        expect(place.readOnly, ro);
      });
    }
    test('the project travels with its place (the title)', () {
      expect(
        explorerPlaceOf(agent: agent(AgentKind.agent, 'demo'), projects: [demo]).project?.name,
        'Demo',
      );
    });
  });

  test('each file\'s family, as the page\'s tabIconFor', () {
    const table = {
      'clip.MP4': FileFamily.video,
      'song.flac': FileFamily.audio,
      'logo.svg': FileFamily.image,
      'manual.pdf': FileFamily.pdf,
      'README.md': FileFamily.document,
      'notes.txt': FileFamily.document,
      'offer.docx': FileFamily.document,
      'prices.csv': FileFamily.sheet,
      'budget.xlsx': FileFamily.sheet,
      'deck.key': FileFamily.slides,
      'chair.glb': FileFamily.model,
      'backup.tar.gz': FileFamily.archive,
      'app.ts': FileFamily.code,
      'Dockerfile': FileFamily.code,
      'Inter.woff2': FileFamily.font,
      'package.json': FileFamily.data,
      'poster.psd': FileFamily.design,
      'drawing.ora': FileFamily.design,
      'index.html': FileFamily.site,
      'LICENSE': FileFamily.document,
      'blob.bin': FileFamily.file,
      'noext': FileFamily.file,
    };
    for (final MapEntry(key: name, value: f) in table.entries) {
      expect(fileFamilyOf(name), f, reason: name);
    }
    expect(extensionOf('a/b/backup.tar.gz'), 'tgz');
  });

  test('a file named by its path travels as a path, nothing written', () async {
    var writes = 0;
    final m = await packMessage('look', const [
      AttachedPath('big.bin', 'assets/big.bin', 300000),
    ], upload: (_, _) async => writes++);
    expect(writes, 0);
    expect(m.text, contains('<attachment name="big.bin" path="assets/big.bin" size="300000" />'));
  });

  late FakeRedGiant server;
  late FakeFiles fs;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    fs = _workspace();
    server.files = fs;
    server.agentOverrides['a3'] = {'projectId': 'demo'};
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester,
    MemoryAppPrefs prefs, {
    Size size = const Size(1440, 900),
    DevicePlatform platform = DevicePlatform.linux,
  }) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: prefs,
            platform: platform,
            liveEnabled: false,
          )
          ..locale = const Locale('it')
          ..reduceMotion = true;
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
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

  Future<void> tap(WidgetTester tester, Finder f, [int rounds = 8]) async {
    await tester.tap(f);
    await _settle(tester, rounds);
  }

  DeskController desk(WidgetTester tester) =>
      DeskScope.read(tester.element(find.byKey(const Key('desk-panel'))));

  Finder row(String path) => find.byKey(Key('files-row-$path'));

  testWidgets('computer: the folder button opens the files beside the conversation, kept', (
    tester,
  ) async {
    final prefs = MemoryAppPrefs();
    await start(tester, prefs);
    await tap(tester, find.byKey(const Key('tile-a3')));
    // The side panel is narrow: the files cover the conversation, and close.
    await tap(tester, find.byKey(const Key('conversation-files')));
    expect(find.byKey(const Key('conversation-files-cover')), findsOneWidget);
    expect(find.byKey(const Key('files-full')), findsNothing, reason: 'already the whole room');
    expect(prefs.values['explorerOpen'], isNull, reason: 'covering is not kept');
    await tap(tester, find.byKey(const Key('files-close')));
    expect(find.byKey(const Key('conversation-files-cover')), findsNothing);

    // Full window: a panel beside the conversation, the project's tree.
    desk(tester).setFull(true);
    await _settle(tester);
    await tap(tester, find.byKey(const Key('conversation-files')));
    expect(find.byKey(const Key('conversation-files-side')), findsOneWidget);
    expect(prefs.values['explorerOpen'], '1');
    expect(
      find.descendant(
        of: find.byKey(const Key('files-title')),
        matching: find.text('Demo'),
        matchRoot: true,
      ),
      findsOneWidget,
    );
    // Folders first, hidden files and .git left out, the families drawn.
    final order = [
      for (final p in ['assets', 'docs', 'src', 'notes.txt', 'README.md'])
        tester.getTopLeft(row(p)).dy,
    ];
    expect(order, [...order]..sort());
    expect(row('.env'), findsNothing);
    expect(row('.git'), findsNothing);
    expect(
      find.descendant(
        of: row('README.md'),
        matching: find.byKey(const ValueKey('file-icon-document')),
      ),
      findsOneWidget,
    );
    // A folder opens in place.
    await tap(tester, row('src'));
    expect(row('src/app.ts'), findsOneWidget);
    expect(
      find.descendant(
        of: row('src/app.ts'),
        matching: find.byKey(const ValueKey('file-icon-code')),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('files-where'))).textSpan!.toPlainText(),
      'Cartella: /src',
      reason: 'new things go into the selected folder',
    );

    // Full window for the files, and back beside the conversation.
    await tap(tester, find.byKey(const Key('files-full')));
    expect(find.byKey(const Key('conversation-files-cover')), findsOneWidget);
    expect(prefs.values['explorerFull'], '1');
    expect(row('src/app.ts'), findsOneWidget, reason: 'the tree keeps what was open');
    await tap(tester, find.byKey(const Key('files-unfull')));
    expect(find.byKey(const Key('conversation-files-side')), findsOneWidget);
    expect(prefs.values['explorerFull'], isNull);

    // Wider by dragging its edge, kept.
    final before = tester.getSize(find.byKey(const Key('conversation-files-side'))).width;
    await tester.drag(
      find.descendant(
        of: find.byKey(const Key('files-resizer')),
        matching: find.byKey(const Key('panel-resizer')),
      ),
      const Offset(-80, 0),
    );
    await _settle(tester, 20);
    expect(
      tester.getSize(find.byKey(const Key('conversation-files-side'))).width,
      greaterThan(before + 40),
    );
    expect(int.parse(prefs.values['explorerWidth']!), greaterThan(before + 40));

    // A file opens in the app's Canvas.
    await tap(tester, row('README.md'), 14);
    expect(find.byType(CanvasScreen), findsOneWidget);
    await done(tester);

    // The next conversation opens with its files.
    await start(tester, prefs);
    await tap(tester, find.byKey(const Key('tile-a3')));
    expect(desk(tester).full, isTrue);
    expect(find.byKey(const Key('conversation-files-side')), findsOneWidget);
    await tap(tester, find.byKey(const Key('conversation-files')));
    expect(find.byKey(const Key('conversation-files-side')), findsNothing);
    expect(prefs.values['explorerOpen'], isNull);
    await done(tester);
  });

  testWidgets('computer: a file dragged onto the conversation goes with the message', (
    tester,
  ) async {
    final prefs = MemoryAppPrefs()..values['explorerOpen'] = '1';
    await start(tester, prefs);
    await tap(tester, find.byKey(const Key('tile-a3')));
    desk(tester).setFull(true);
    await _settle(tester);
    expect(find.byKey(const Key('conversation-files-side')), findsOneWidget);
    await tap(tester, row('assets'));

    Future<void> dragToChat(String path) async {
      final from = tester.getCenter(row(path));
      final to = tester.getCenter(find.byKey(const Key('composer-box')));
      final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 1; i <= 10; i++) {
        await g.moveTo(Offset.lerp(from, to, i / 10)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byKey(const Key('conversation-file-drop')), findsOneWidget);
      await g.up();
      await _settle(tester);
    }

    // A big file of the agent's own project: named by its path. A text: its content.
    await dragToChat('assets/big.bin');
    await dragToChat('notes.txt');
    final chips = find.byKey(const Key('composer-attachments'));
    expect(find.descendant(of: chips, matching: find.text('big.bin')), findsOneWidget);
    expect(find.descendant(of: chips, matching: find.text('notes.txt')), findsOneWidget);
    await tester.enterText(
      find
          .descendant(of: find.byKey(const Key('desk-panel')), matching: find.byType(TextField))
          .last,
      'guarda',
    );
    await tap(tester, find.byKey(const Key('composer-send')));
    final text = '${server.sent.last['text']}';
    expect(text, contains('<attachment name="big.bin" path="assets/big.bin" size="300000" />'));
    expect(text, contains('<attachment name="notes.txt">\nremember the prices\n'));
    expect(fs.changes, isEmpty, reason: 'nothing written again');
    await done(tester);
  });

  /// The explorer on its own (pickers and saver given), inside the app.
  Future<
    ({
      List<String> opened,
      List<String> asked,
      Map<String, Uint8List> saved,
      List<(String, Uint8List)> toPick,
    })
  >
  explorer(WidgetTester tester, {bool computer = true, String scope = _demo}) async {
    final out = (
      opened: <String>[],
      asked: <String>[],
      saved: <String, Uint8List>{},
      toPick: <(String, Uint8List)>[],
    );
    final app = await start(
      tester,
      MemoryAppPrefs(),
      platform: computer ? DevicePlatform.linux : DevicePlatform.android,
      size: computer ? const Size(1440, 900) : const Size(390, 844),
    );
    final place = explorerPlaceOf(
      agent: Agent(
        id: 'a3',
        kind: AgentKind.agent,
        name: 'X',
        active: true,
        projectId: scope.substring(8),
      ),
      projects: [...app.projects],
      archived: [
        ...app.archivedProjects,
        if (fs.readOnly.contains(scope))
          Project(id: scope.substring(8), name: 'Old', archived: true),
      ],
    );
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: FilesExplorer(
                place: place,
                computer: computer,
                onOpen: (path, _) => out.opened.add(path),
                onAsk: out.asked.add,
                onClose: () {},
                saveFile: (name, bytes) async {
                  out.saved[name] = bytes;
                  return true;
                },
                pickFiles: () async => List.of(out.toPick),
              ),
            ),
          ),
        )
        .ignore();
    await _settle(tester);
    return out;
  }

  Future<void> answer(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField).last, text);
    await tap(tester, find.byKey(const Key('dialog-yes')));
  }

  testWidgets('every action of the page, against the workspace', (tester) async {
    final x = await explorer(tester);
    // New folder (opened), new file inside it: the selected folder is where they go.
    await tap(tester, find.byKey(const Key('files-new-folder')));
    await answer(tester, 'drafts/2026');
    expect(fs.isDir(_demo, 'drafts/2026'), isTrue);
    expect(row('drafts/2026'), findsOneWidget);
    await tap(tester, row('drafts/2026'));
    await tap(tester, find.byKey(const Key('files-new-file')));
    expect(
      tester.widget<TextField>(find.byKey(const Key('files-new-name'))).controller!.text,
      'drafts/2026/',
    );
    await answer(tester, 'drafts/2026/idea.md');
    expect(fs.text(_demo, 'drafts/2026/idea.md'), '');
    expect(row('drafts/2026/idea.md'), findsOneWidget);

    // Rename from the right click menu.
    await tester.tap(row('notes.txt'), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('files-menu-delete')), findsOneWidget);
    await tap(tester, find.byKey(const Key('files-menu-rename')));
    await answer(tester, 'docs/notes.txt');
    expect(fs.isFile(_demo, 'notes.txt'), isFalse);
    expect(fs.text(_demo, 'docs/notes.txt'), 'remember the prices\n');

    // Delete: asked with our window, then into .trash; inside .trash for good.
    await tester.tap(row('README.md'), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tap(tester, find.byKey(const Key('files-menu-delete')));
    expect(find.textContaining('Spostare README.md nel cestino'), findsOneWidget);
    await tap(tester, find.byKey(const Key('dialog-yes')));
    expect(fs.isFile(_demo, 'README.md'), isFalse);
    final trashed = fs.files[_demo]!.keys.firstWhere((p) => p.endsWith('/README.md'));
    expect(trashed, startsWith('.trash/'));
    expect(row('.trash'), findsNothing, reason: 'hidden files stay hidden');
    await tap(tester, find.byKey(const Key('files-hidden')));
    expect(row('.trash'), findsOneWidget);
    expect(row('.env'), findsOneWidget);
    await tester.tap(row('.trash'), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tap(tester, find.byKey(const Key('files-menu-delete')));
    expect(find.textContaining('Eliminare .trash per sempre?'), findsOneWidget);
    await tap(tester, find.byKey(const Key('dialog-no')));
    expect(fs.isFile(_demo, trashed), isTrue, reason: 'cancelled: nothing happens');

    // Upload into the selected folder; a taken name asks: keep both, then replace.
    await tap(tester, row('src'));
    x.toPick
      ..add(('app.ts', Uint8List.fromList(utf8.encode('// new'))))
      ..add(('logo.png', Uint8List.fromList([0x89, 0x50, 0x4e, 0x47])));
    await tap(tester, find.byKey(const Key('files-upload')));
    expect(find.byKey(const Key('files-taken')), findsOneWidget);
    expect(find.textContaining('src/app.ts esiste già qui.'), findsOneWidget);
    await tap(tester, find.byKey(const Key('files-keep-both')));
    expect(fs.text(_demo, 'src/app (2).ts'), '// new');
    expect(fs.text(_demo, 'src/app.ts'), 'export const year = 2026;\n');
    expect(fs.isFile(_demo, 'src/logo.png'), isTrue);
    expect(row('src/app (2).ts'), findsOneWidget);
    x.toPick
      ..clear()
      ..add(('app.ts', Uint8List.fromList(utf8.encode('// newer'))));
    await tap(tester, find.byKey(const Key('files-upload')));
    await tap(tester, find.byKey(const Key('files-replace')));
    expect(fs.text(_demo, 'src/app.ts'), '// newer');

    // A .rgartifact is imported and opened, never written as it is.
    x.toPick
      ..clear()
      ..add(('board.rgartifact', Uint8List.fromList([0x50, 0x4b, 3, 4, 1])));
    await tap(tester, find.byKey(const Key('files-upload')));
    expect(fs.isFile(_demo, 'artefatti/imported.html'), isTrue);
    expect(fs.isFile(_demo, 'src/board.rgartifact'), isFalse);
    expect(x.opened.last, 'artefatti/imported.html');

    // Download: the file's bytes, where the person chooses.
    await tester.tap(row('docs'));
    await _settle(tester);
    await tester.tap(row('docs/manual.pdf'), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tap(tester, find.byKey(const Key('files-menu-download')));
    expect(x.saved['manual.pdf'], [0x25, 0x50, 0x44, 0x46, 0, 1, 2]);

    // Ask the agent, copy the path, open: the conversation's composer and the Canvas.
    await tester.tap(row('docs/manual.pdf'), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tap(tester, find.byKey(const Key('files-menu-ask')));
    expect(x.asked, ['docs/manual.pdf']);
    await tap(tester, row('docs/manual.pdf'));
    expect(x.opened.last, 'docs/manual.pdf');

    // Search: by name and by content, a hit opens.
    await tester.enterText(find.byKey(const Key('files-search')), 'vat');
    await tester.pump(const Duration(milliseconds: 350));
    await _settle(tester);
    expect(find.byKey(const Key('files-hit-src/prices.ts')), findsOneWidget);
    await tap(tester, find.byKey(const Key('files-hit-src/prices.ts')));
    expect(x.opened.last, 'src/prices.ts');

    // Every change went through the routes (the server's own log).
    expect(
      [for (final c in fs.changes) c['action']],
      ['mkdir', 'write', 'rename', 'delete', 'write', 'write', 'write', 'write'],
    );
    await done(tester);
  });

  testWidgets('an archived project\'s files: read only', (tester) async {
    fs.readOnly.add('project:old');
    fs.put('project:old', 'index.html', '<p>old</p>');
    await explorer(tester, scope: 'project:old');
    expect(find.byKey(const Key('files-read-only')), findsOneWidget);
    expect(find.text('Sola lettura: il progetto è archiviato'), findsOneWidget);
    for (final k in ['files-new-file', 'files-new-folder', 'files-upload', 'files-terminal']) {
      expect(find.byKey(Key(k)), findsNothing, reason: k);
    }
    await tester.tap(row('index.html'), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('files-menu-open')), findsOneWidget);
    expect(find.byKey(const Key('files-menu-download')), findsOneWidget);
    expect(find.byKey(const Key('files-menu-rename')), findsNothing);
    expect(find.byKey(const Key('files-menu-delete')), findsNothing);
    expect(find.byKey(const Key('files-menu-ask')), findsNothing);
    await done(tester);
  });

  testWidgets('the server refuses an archived project\'s changes too (423)', (tester) async {
    fs.readOnly.add(_demo);
    final app = await start(tester, MemoryAppPrefs());
    final client = app.client!;
    await tester.runAsync(() async {
      for (final f in <Future<void> Function()>[
        () => client.fileOp('delete', _demo, 'README.md'),
        () => client.uploadFile(_demo, 'x.txt', [1]),
        () => client.importArtifact(_demo, [0x50, 0x4b, 3, 4]),
      ]) {
        await expectLater(f(), throwsA(isA<Object>().having((e) => '$e', 'e', contains('423'))));
      }
    });
    expect(fs.isFile(_demo, 'README.md'), isTrue);
    await done(tester);
  });

  testWidgets('phone: a screen of its own, a file opens in the Canvas, ask the agent', (
    tester,
  ) async {
    final app = await start(
      tester,
      MemoryAppPrefs(),
      platform: DevicePlatform.android,
      size: const Size(390, 844),
    );
    final a3 = app.agents.firstWhere((a) => a.id == 'a3');
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => ConversationScreen(sessionId: 's1', agent: a3),
          ),
        )
        .ignore();
    await _settle(tester);
    await tap(tester, find.byKey(const Key('conversation-files')));
    expect(find.byType(FilesScreen), findsOneWidget);
    expect(find.byKey(const Key('files-back')), findsOneWidget);
    expect(row('README.md'), findsOneWidget);
    // Rows tall enough for a finger.
    expect(tester.getSize(row('README.md')).height, greaterThanOrEqualTo(44));
    await tap(tester, row('README.md'), 14);
    expect(find.byType(CanvasScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(CanvasScreen))).pop();
    await _settle(tester);
    await _settle(tester, 2);
    // «…»: the sheet; «Ask the agent» goes back to the conversation with the line written.
    await tap(tester, find.byKey(const Key('files-more-notes.txt')));
    expect(find.byKey(const Key('files-menu-rename')), findsOneWidget);
    await tap(tester, find.byKey(const Key('files-menu-ask')));
    await _settle(tester, 2);
    expect(find.byType(FilesScreen), findsNothing);
    expect(find.textContaining('Sul file `notes.txt`:'), findsOneWidget);
    await done(tester);
  });
}
