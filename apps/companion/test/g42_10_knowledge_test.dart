// G42.10: Settings › Knowledge and Shared memory native, against the fake server that answers as
// the real one (test/fake_knowledge.dart): reading, changing, the server's refusals in words, the
// downloads with their bar, the shared memory's undo, the `#kb:` citations, and the way in from
// «Settings of <name>» and from an agent's tabs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/settings/knowledge_cite.dart';
import 'package:rgcompanion/settings/knowledge_screen.dart';
import 'package:rgcompanion/settings/memory_screen.dart';
import 'package:rgcompanion/ui/citations.dart';

import 'fake_knowledge.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('a #kb: citation: its piece, its place in the person\'s words, its short name', () {
    expect(kbChunkOf('#kb:41'), '41');
    expect(kbChunkOf('#kb:x'), isNull);
    expect(kbChunkOf('https://example.com'), isNull);
    expect(
      kbSite('istruzioni-della-lavatrice-nuova.pdf, pag. 12'),
      'istruzioni-della-lavat…, pag. 12',
    );
    const md = 'La garanzia dura due anni [1].\n\nFonti:\n\n1. [lavatrice.pdf, p. 12](#kb:41)\n';
    final out = linkCitations(md, kbTitle: (t) => t.replaceAll(', p. ', ', pag. '));
    expect(out, contains('[lavatrice.pdf, pag. 12](#kb:41 "lavatrice.pdf, pag. 12")'));
    // The list item says the page in the person's language too.
    expect(out, contains('1. [lavatrice.pdf, pag. 12](#kb:41)'));
    // Web sources are as before.
    const web = 'Vedi [1].\n\n1. [Titolo](https://www.example.com/a)\n';
    expect(linkCitations(web), contains('[example.com](https://www.example.com/a'));
  });

  test('an agent\'s collection reads the server\'s scope object', () {
    final c = AgentCollection.fromJson({
      'id': 'c',
      'name': 'N',
      'scope': {'kind': 'project', 'projectId': 'demo'},
      'byScope': true,
      'on': true,
    });
    expect(c.scope, 'project');
    expect(c.scopeId, 'demo');
    expect(
      AgentCollection.fromJson({
        'scope': {'kind': 'all'},
      }).scope,
      'global',
    );
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeKnowledge kb;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      kb = FakeKnowledge();
      server.knowledge = kb;
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 6000)}) async {
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

    Future<void> push(WidgetTester tester, Widget screen) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
      await _settle(tester);
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('reading: the state with its bar, the collections, the disk', (tester) async {
      await start(tester);
      await push(tester, const KnowledgeScreen(poll: false));
      expect(find.byKey(const Key('knowledge-settings')), findsOneWidget);
      // 600 of 1,800 pieces with a vector: still working, with the bar and the time left.
      final words = tester.widget<Text>(find.byKey(const Key('kb-bar-words'))).data!;
      expect(words, startsWith('33% · 600 di 1800'));
      expect(words, contains('mancano circa 10 min'));
      expect(find.byKey(const Key('kb-col-c1')), findsOneWidget);
      expect(find.text('Home manuals'), findsOneWidget);
      // Who it is for, with the project's name.
      expect(find.textContaining('Per il progetto'), findsWidgets);
      await tester.ensureVisible(find.byKey(const Key('kb-rebuild')));
      expect(find.text('333,8 MB'), findsOneWidget);
      expect(find.byKey(const Key('kb-meaning')), findsNothing);
      await done(tester);
    });

    testWidgets('the knowledge not running: the reason in words', (tester) async {
      server.knowledge = null;
      server.routes['GET /api/knowledge'] = (r) =>
          server.answer(r, 400, {'error': 'The knowledge is not running', 'code': 'no_vector'});
      await start(tester);
      await push(tester, const KnowledgeScreen(poll: false));
      expect(find.textContaining('non è ancora pronta su questo computer'), findsOneWidget);
      await done(tester);
    });

    testWidgets('a collection: made, a source added and refused, its scope, removed', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const KnowledgeScreen(poll: false));
      await tap(tester, 'kb-new');
      expect(find.byKey(const Key('kb-new-window')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('kb-new-name')), 'Contratti');
      await tester.pump();
      await tap(tester, 'kb-scope-project');
      await tap(tester, 'kb-new-make');
      final made = kb.collections.last;
      expect(made['name'], 'Contratti');
      expect(made['scope'], {'kind': 'project', 'projectId': 'demo'});
      // Its window opens by itself.
      expect(find.byKey(const Key('kb-collection-window')), findsOneWidget);
      expect(find.textContaining('Ancora nessuna fonte'), findsOneWidget);
      await tap(tester, 'kb-add-source');
      expect(find.byKey(const Key('kb-add-window')), findsOneWidget);
      // A folder that is not there: the server's reason in words.
      await tester.enterText(find.byKey(const Key('kb-path')), '/nowhere/x');
      await tester.pump();
      await tap(tester, 'kb-add');
      expect(find.textContaining('Quella fonte non si può leggere'), findsOneWidget);
      // A web page.
      await tap(tester, 'kb-kind-url');
      await tester.enterText(find.byKey(const Key('kb-url')), 'https://example.org/');
      await tester.pump();
      await tap(tester, 'kb-add');
      final id = made['id'] as String;
      expect(kb.sources[id]!.single['spec'], {'kind': 'url', 'url': 'https://example.org/'});
      expect(find.text('https://example.org/'), findsOneWidget);
      final sid = kb.sources[id]!.single['id'] as String;
      await tap(tester, 'kb-rescan-$sid');
      expect(kb.sources[id]!.single['state'], 'scanning');
      await tap(tester, 'kb-remove-source-$sid');
      expect(kb.sources[id], isEmpty);
      // For whom: everyone, saved.
      await tap(tester, 'kb-scope-all');
      await tap(tester, 'kb-save-scope');
      expect(made['scope'], {'kind': 'all'});
      await tap(tester, 'kb-remove');
      expect(find.byKey(const Key('kb-remove-ask')), findsOneWidget);
      await tap(tester, 'kb-remove-yes');
      expect(kb.collections.any((c) => c['id'] == id), isFalse);
      await done(tester);
    });

    testWidgets('mail and conversations need the person\'s yes; files from the device', (
      tester,
    ) async {
      await start(tester);
      await push(
        tester,
        KnowledgeScreen(
          poll: false,
          pickFiles: () async => [
            ('garanzia.txt', 'Due anni'.codeUnits),
            ('../note.md', '# Note'.codeUnits),
          ],
        ),
      );
      await tap(tester, 'kb-col-c1');
      // What could not be read, and why.
      expect(find.text('scontrino.jpg'), findsOneWidget);
      await tap(tester, 'kb-add-source');
      await tap(tester, 'kb-kind-mail');
      final add = tester.widget<FilledButton>(find.byKey(const Key('kb-add')));
      expect(add.onPressed, isNull);
      await tap(tester, 'kb-consent');
      await tap(tester, 'kb-add');
      final mail = kb.sources['c1']!.last['spec'] as Map;
      expect(mail['kind'], 'mail');
      expect(mail['mailbox'], 'box_lavoro');
      expect(mail['consent'], true);
      expect(mail['days'], 365);
      // Files sent from this device: into God's folder, one source for them.
      await tap(tester, 'kb-upload');
      expect(
        kb.writes.keys,
        containsAll(['platform:knowledge/c1/garanzia.txt', 'platform:knowledge/c1/note.md']),
      );
      final up = kb.sources['c1']!.last['spec'] as Map;
      expect(up, {'kind': 'workspace', 'scope': 'platform', 'path': 'knowledge/c1'});
      // Sent again: the same source is read again, not added twice.
      await tap(tester, 'kb-upload');
      expect(
        kb.sources['c1']!.where((s) => (s['spec'] as Map)['path'] == 'knowledge/c1'),
        hasLength(1),
      );
      await done(tester);
    });

    testWidgets('try a search, and a citation that opens a text', (tester) async {
      await start(tester);
      await push(tester, const KnowledgeScreen(poll: false));
      await tester.ensureVisible(find.byKey(const Key('kb-try-field')));
      await tester.enterText(find.byKey(const Key('kb-try-field')), 'garanzia lavatrice');
      await tester.pump();
      await tap(tester, 'kb-try');
      expect(kb.bodies['POST /api/knowledge/search'], {'query': 'garanzia lavatrice', 'limit': 8});
      expect(find.byKey(const Key('kb-hit-0')), findsOneWidget);
      expect(find.text('pagina 12'), findsOneWidget);
      expect(find.textContaining('14 ms'), findsOneWidget);
      // A mail's text opens in a window.
      final ctx = tester.element(find.byKey(const Key('kb-hit-0')));
      openKbCitation(ctx, '42').ignore();
      await _settle(tester);
      expect(find.byKey(const Key('kb-cite-note')), findsOneWidget);
      expect(find.text('Il preventivo è di 4.200 euro.'), findsOneWidget);
      await done(tester);
    });

    testWidgets('models: local, the reranker with its download bar, the cloud refused', (
      tester,
    ) async {
      await start(tester, size: const Size(1200, 6000));
      await push(tester, const KnowledgeScreen(poll: false));
      await tap(tester, 'kb-model-qwen3-embedding-0.6b');
      expect(kb.embedding, {'provider': 'local', 'model': 'qwen3-embedding-0.6b'});
      await tap(tester, 'kb-rerank-bge-reranker-v2-m3');
      expect(kb.rerank, {'provider': 'local', 'model': 'bge-reranker-v2-m3'});
      expect(kb.calls, contains('POST /api/knowledge/models/download'));
      // The download, with its real bar (bytes, speed, time left).
      expect(find.textContaining('BGE Reranker v2 M3 (636 MB)'), findsOneWidget);
      expect(find.textContaining('31% · '), findsOneWidget);
      // A cloud API with a wrong key: said here, now; nothing changes.
      await tap(tester, 'kb-model-cloud');
      await tester.enterText(find.byKey(const Key('kb-cloud-key')), 'bad');
      await tester.pump();
      await tap(tester, 'kb-cloud-use');
      expect(find.byKey(const Key('kb-cloud-error')), findsOneWidget);
      expect(find.textContaining('controlla la chiave'), findsOneWidget);
      expect(kb.embedding?['provider'], 'local');
      await tester.enterText(find.byKey(const Key('kb-cloud-key')), 'openai_kb');
      await tester.pump();
      await tap(tester, 'kb-cloud-use');
      expect(kb.embedding, {
        'provider': 'openai',
        'model': 'text-embedding-3-small',
        'credential': 'openai_kb',
      });
      await done(tester);
    });

    testWidgets('meaning off: why, and the one button; pause, backup, OCR, rebuild', (
      tester,
    ) async {
      kb.embedding = null;
      await start(tester);
      await push(tester, const KnowledgeScreen(poll: false));
      expect(find.byKey(const Key('kb-meaning')), findsOneWidget);
      await tap(tester, 'kb-meaning-on');
      expect(find.byKey(const Key('kb-meaning-window')), findsOneWidget);
      await tap(tester, 'kb-meaning-yes');
      expect(kb.embedding, {'provider': 'local', 'model': 'qwen3-embedding-0.6b'});
      expect(find.byKey(const Key('kb-meaning')), findsNothing);
      await tap(tester, 'kb-pause');
      expect(kb.paused, isTrue);
      await tap(tester, 'kb-ocr-lang-fra');
      expect(kb.ocrLanguages, ['ita', 'eng', 'fra']);
      await tap(tester, 'kb-ocr-download');
      expect(kb.bodies['POST /api/knowledge/ocr/download'], {
        'languages': ['ita', 'eng', 'fra'],
      });
      await tap(tester, 'kb-backup-vectors');
      expect(kb.backupVectors, isTrue);
      await tap(tester, 'kb-rebuild');
      await tap(tester, 'kb-rebuild-yes');
      expect(kb.calls, contains('POST /api/knowledge/rebuild'));
      await done(tester);
    });

    testWidgets('shared memory: add, the same again, edit, delete and undo, forget', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const SharedMemoryScreen());
      expect(find.byKey(const Key('memory-settings')), findsOneWidget);
      expect(find.text('Si chiama Severino e scrive in italiano'), findsWidgets);
      expect(find.textContaining('Imparato da sola'), findsWidgets);
      expect(find.textContaining('Presentazioni'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('mem-add-field')), 'Preferisce risposte brevi');
      await tester.pump();
      await tap(tester, 'mem-add');
      expect(kb.entries.map((e) => e['text']), contains('Preferisce risposte brevi'));
      // The same fact again changes nothing, and says so.
      await tester.enterText(find.byKey(const Key('mem-add-field')), 'preferisce risposte brevi!');
      await tester.pump();
      await tap(tester, 'mem-add');
      expect(find.byKey(const Key('mem-note')), findsOneWidget);
      expect(kb.entries, hasLength(3));
      // Edited into another memory's words: refused in words.
      final id = kb.entries.last['id'] as String;
      await tap(tester, 'mem-edit-$id');
      await tester.enterText(
        find.byKey(const Key('mem-edit-field')),
        'Il lunedì mattina non fissare appuntamenti',
      );
      await tester.pump();
      await tap(tester, 'mem-edit-save');
      expect(find.byKey(const Key('mem-edit-error')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('mem-edit-field')), 'Preferisce risposte corte');
      await tester.pump();
      await tap(tester, 'mem-edit-save');
      expect(kb.entries.last['text'], 'Preferisce risposte corte');
      // Deleted, then back from the bar under the list.
      await tap(tester, 'mem-remove-$id');
      expect(kb.entries.any((e) => e['id'] == id), isFalse);
      await tap(tester, 'mem-undo-removed');
      expect(kb.entries.any((e) => e['id'] == id), isTrue);
      // An undone change cannot be undone twice: the history shows it «Annullata».
      expect(find.text('Annullata'), findsWidgets);
      // Forgotten for good, after saying so.
      await tap(tester, 'mem-forget-$id');
      expect(find.byKey(const Key('mem-forget-window')), findsOneWidget);
      await tap(tester, 'mem-forget-yes');
      expect(kb.entries.any((e) => e['id'] == id), isFalse);
      expect(kb.changes.where((c) => c['memoryId'] == id).every((c) => c['text'] == ''), isTrue);
      await tap(tester, 'mem-auto');
      expect(kb.auto, isFalse);
      await done(tester);
    });

    testWidgets('an undo refused by the server is said in words', (tester) async {
      await start(tester);
      await push(tester, const SharedMemoryScreen());
      final first = kb.entries.first;
      // Changed elsewhere since: the old «added» cannot be taken back.
      kb.entries.first['text'] = 'Altro';
      final seq = kb.changes.first['seq'] as int;
      await tap(tester, 'mem-undo-$seq');
      expect(find.byKey(const Key('mem-error')), findsOneWidget);
      expect(find.textContaining('annulla prima la modifica più recente'), findsOneWidget);
      expect(first['id'], isNotNull);
      await done(tester);
    });

    testWidgets('the way in: «Settings of <name>» and an agent\'s tabs', (tester) async {
      final app = await start(tester);
      await push(tester, const SizedBox());
      final ctx = tester.element(find.byType(SizedBox).last);
      openKnowledgeSettings(ctx).ignore();
      await _settle(tester);
      expect(find.byKey(const Key('knowledge-settings')), findsOneWidget);
      Navigator.of(tester.element(find.byKey(const Key('knowledge-settings')))).pop();
      await _settle(tester);
      openSharedMemory(ctx).ignore();
      await _settle(tester);
      expect(find.byKey(const Key('memory-settings')), findsOneWidget);
      expect(app.connected, isTrue);
      await done(tester);
    });
  });
}
