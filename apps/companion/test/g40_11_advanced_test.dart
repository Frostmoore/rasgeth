// G40.11 against the fake RedGiant: the switch in Tu › Interfaccia (kept per RedGiant), Projects
// with git, and every tab of a project (Tasks, Files, Diff, Terminal, Log, Git), the agent's
// sheet with Files, Diff and Terminal, an archived project read only; and the pure parts (the
// patch cut into hunks, the terminal's buffer, an agent's commands).
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/code.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/code/project_screen.dart';
import 'package:rgcompanion/screens/team_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('pure parts', () {
    test('a patch cut into files and hunks, each hunk a patch of its own', () {
      const patch =
          'diff --git a/a.ts b/a.ts\n'
          'index 1..2 100644\n'
          '--- a/a.ts\n'
          '+++ b/a.ts\n'
          '@@ -1,2 +1,2 @@ top\n'
          ' keep\n'
          '-old\n'
          '+new\n'
          '@@ -10 +10,2 @@\n'
          ' x\n'
          '+y\n'
          r'\ No newline at end of file'
          '\n'
          'diff --git a/n.txt b/n.txt\n'
          'new file mode 100644\n'
          '--- /dev/null\n'
          '+++ b/n.txt\n'
          '@@ -0,0 +1 @@\n'
          '+hi\n';
      final files = parsePatch(patch);
      expect(files.map((f) => f.path), ['a.ts', 'n.txt']);
      final a = files.first;
      expect(a.hunks, hasLength(2));
      expect(a.added, 2);
      expect(a.removed, 1);
      expect(a.hunks.first.lines.map((l) => (l.kind, l.oldNo, l.newNo)).toList(), [
        (DiffLineKind.context, 1, 1),
        (DiffLineKind.removed, 2, null),
        (DiffLineKind.added, null, 2),
      ]);
      expect(a.hunks.last.lines.last.kind, DiffLineKind.note);
      expect(
        hunkPatch(a, a.hunks.first),
        'diff --git a/a.ts b/a.ts\nindex 1..2 100644\n--- a/a.ts\n+++ b/a.ts\n'
        '@@ -1,2 +1,2 @@ top\n keep\n-old\n+new\n',
      );
      expect(files.last.isNew, isTrue);
    });

    test('the terminal buffer drops colours, applies \\r, backspace and erase', () {
      final b = TermBuffer()
        ..write('\x1b[32mok\x1b[0m line\r\n')
        ..write('abc\b\bX\n')
        ..write('progress 10%\rprogress 99%\n')
        ..write('long text\r\x1b[Kshort\n')
        ..write('\x1b]0;title\x07\$ ');
      expect(b.lines, ['ok line', 'aXc', 'progress 99%', 'short', r'$ ']);
      expect(TermKeys.ctrl('c'), '\x03');
      expect(TermKeys.ctrl('D'), '\x04');
    });

    test("an agent's commands with what they printed", () {
      final cmds = agentCommands([
        {
          'type': 'tool.call',
          'payload': {
            'callId': '1',
            'tool': 'bash',
            'input': {'command': 'ls'},
          },
        },
        {
          'type': 'tool.call',
          'payload': {
            'callId': '2',
            'tool': 'read_file',
            'input': {'path': 'x'},
          },
        },
        {
          'type': 'tool.result',
          'payload': {'callId': '1', 'ok': false, 'output': 'nope'},
        },
      ]);
      expect(cmds, hasLength(1));
      expect((cmds.single.command, cmds.single.output, cmds.single.ok), ('ls', 'nope', false));
    });

    test('the board: in progress, to verify (a verifier ran), done', () {
      TaskRow t(String outcome, Map<String, Object>? v) => TaskRow.fromJson({
        'id': 'x',
        'title': 'x',
        'outcome': outcome,
        'openedAt': '',
        'verifier': v,
      });
      expect(t('open', null).column, TaskColumn.running);
      expect(t('open', {'command': 'npm test', 'passed': false}).column, TaskColumn.toVerify);
      expect(t('verified', {'command': 'npm test', 'passed': true}).column, TaskColumn.done);
      expect(t('abandoned', null).column, TaskColumn.done);
    });
  });

  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.agentOverrides['a1'] = {
      'projectId': 'demo',
      'kind': 'orchestrator',
      'name': 'Coder Web',
    };
    server.sessions.add({
      'id': 's9',
      'agentId': 'a1',
      'projectId': 'demo',
      'createdAt': '2026-11-15T09:00:00.000Z',
      'lastAt': '2026-11-15T09:10:00.000Z',
      'title': 'Prices',
      'archived': false,
      'running': false,
    });
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    bool advanced = true,
    MemoryAppPrefs? prefs,
    Size size = const Size(1290, 2700),
  }) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: prefs ?? MemoryAppPrefs(),
            platform: DevicePlatform.android,
            liveEnabled: false,
          )
          ..locale = const Locale('it')
          ..reduceMotion = true;
    await tester.runAsync(() async {
      await app.connect(server.base.toString(), 'secret');
    });
    if (advanced) app.setAdvanced(true);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    return app;
  }

  Future<void> openProject(WidgetTester tester, AppController app, {ProjectTab? tab}) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectScreen(
          project: const Project(id: 'demo', name: 'Demo'),
          initial: tab ?? ProjectTab.tasks,
        ),
      ),
    );
    await _settle(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  testWidgets('Tu › Interfaccia: the switch adds Projects to the bar, kept per RedGiant', (
    tester,
  ) async {
    final prefs = MemoryAppPrefs();
    final app = await start(tester, advanced: false, prefs: prefs);
    expect(find.byKey(const Key('tab-projects')), findsNothing);
    await tester.tap(find.byKey(const Key('tab-you')));
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.byKey(const Key('advanced-toggle')),
      200,
      scrollable: find
          .descendant(of: find.byKey(const Key('you-list')), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('Interfaccia avanzata'), findsOneWidget);
    await tester.tap(find.byKey(const Key('advanced-toggle')));
    await _settle(tester);
    expect(app.advanced, isTrue);
    expect(find.byKey(const Key('advanced-terminals')), findsOneWidget);
    expect(await prefs.get('advanced:${app.server!.id}'), '1');
    expect(find.byKey(const Key('tab-projects')), findsOneWidget);
    // The bar's order: Projects right before You.
    final xs = [for (final t in app.tabs) tester.getCenter(find.byKey(Key('tab-${t.name}'))).dx];
    expect(xs, orderedEquals([...xs]..sort()));
    expect(app.tabs.indexOf(AppTab.projects), app.tabs.length - 2);

    await tester.tap(find.byKey(const Key('tab-projects')));
    await _settle(tester);
    expect(find.byKey(const Key('project-demo')), findsOneWidget);
    expect(find.text('p2.4.0'), findsOneWidget);
    expect(find.text('3 modifiche'), findsOneWidget);
    expect(find.textContaining('Coder Web'), findsOneWidget);
    expect(find.textContaining('2 compiti in corso'), findsOneWidget);

    // Off again: the bar loses Projects and the app goes back to You.
    app.setAdvanced(false);
    await _settle(tester);
    expect(find.byKey(const Key('tab-projects')), findsNothing);
    expect(app.tab, AppTab.you);
    expect(await prefs.get('advanced:${app.server!.id}'), isNull);
    await done(tester);
  });

  testWidgets("the agent's sheet: Files, Diff and Terminal only with the switch on", (
    tester,
  ) async {
    final app = await start(tester);
    final coder = app.agents.firstWhere((a) => a.id == 'a1');
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(showAgentSheet(nav.context, coder));
    await _settle(tester);
    expect(find.byKey(const Key('agent-code-files')), findsOneWidget);
    expect(find.byKey(const Key('agent-code-diff')), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-code-terminal')));
    await _settle(tester);
    // The agent's terminal, read only, with its commands.
    expect(find.byKey(const Key('term-agent-lines')), findsOneWidget);
    expect(find.textContaining('git status -s', findRichText: true), findsOneWidget);
    expect(find.textContaining('Sola lettura'), findsOneWidget);
    nav.pop();
    await _settle(tester);
    app.setAdvanced(false);
    unawaited(showAgentSheet(nav.context, coder));
    await _settle(tester);
    expect(find.byKey(const Key('agent-code-files')), findsNothing);
    await done(tester);
  });

  testWidgets('Tasks: one column under the other, with the verifier; a tap opens the thread', (
    tester,
  ) async {
    final app = await start(tester);
    await openProject(tester, app);
    expect(find.byKey(const Key('project-git-line')), findsOneWidget);
    expect(find.text('p2.4.0 · 3 modifiche'), findsOneWidget);
    final board = find.byKey(const Key('tasks-board'));
    for (final t in ['In corso', 'Da verificare', 'Fatti']) {
      expect(find.descendant(of: board, matching: find.text(t)), findsOneWidget);
    }
    expect(find.text('verificatore: npm test · non passato'), findsOneWidget);
    expect(find.text('verificatore non ancora eseguito'), findsOneWidget);
    expect(find.text('verificato · uscita 0'), findsOneWidget);
    final running = tester.getTopLeft(find.text('Prices page')).dy;
    final verify = tester.getTopLeft(find.text('Add the --json flag')).dy;
    final doneY = tester.getTopLeft(find.text('Fix the README')).dy;
    expect(running < verify && verify < doneY, isTrue);
    await tester.tap(find.byKey(const Key('task-task_1')));
    await _settle(tester);
    expect(find.byKey(const Key('composer-text')), findsOneWidget);
    await done(tester);
  });

  testWidgets('Files: folders one per screen with crumbs, search, view and a small edit', (
    tester,
  ) async {
    final app = await start(tester);
    await openProject(tester, app, tab: ProjectTab.files);
    expect(find.byKey(const Key('file-README.md')), findsOneWidget);
    // The git mark next to a changed file.
    await tester.tap(find.byKey(const Key('file-src')));
    await _settle(tester);
    expect(find.byKey(const Key('file-src/prices.ts')), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
    expect(find.text('Demo'), findsWidgets);
    await tester.tap(find.widgetWithText(TextButton, 'Demo'));
    await _settle(tester);
    expect(find.byKey(const Key('file-README.md')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('files-search')), 'year');
    await tester.pump(const Duration(milliseconds: 350));
    await _settle(tester);
    expect(find.text('src/prices.ts:13'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('files-search')), '');
    await _settle(tester);

    await tester.tap(find.byKey(const Key('file-README.md')));
    await _settle(tester);
    expect(find.byKey(const Key('file-view')), findsOneWidget);
    expect(find.textContaining('# Report', findRichText: true), findsOneWidget);
    await tester.tap(find.byKey(const Key('file-edit')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('file-editor')), '# Report\n\nnew line');
    await tester.tap(find.byKey(const Key('file-save')));
    await _settle(tester);
    final saved = server.written.last;
    expect(saved['path'], 'README.md');
    expect(saved['content'], '# Report\n\nnew line');
    expect(saved['encoding'], 'utf8');
    expect(saved['expectedModifiedAt'], '2026-11-15T10:00:00.000Z');
    expect(find.text('Salvato.'), findsOneWidget);
    await done(tester);
  });

  testWidgets('Diff: unified, a file per screen; keep, discard (asked) and comment', (
    tester,
  ) async {
    final app = await start(tester);
    await openProject(tester, app, tab: ProjectTab.diff);
    expect(find.text('src/prices.ts'), findsOneWidget);
    expect(find.text('1 di 2'), findsOneWidget);
    expect(find.textContaining('const vat', findRichText: true), findsOneWidget);
    const head = '@@ -12,3 +12,4 @@ export function prices()';
    await tester.tap(find.byKey(const Key('hunk-keep-$head')));
    await _settle(tester);
    expect(server.hunks.single['action'], 'keep');
    expect(
      server.hunks.single['patch'],
      startsWith('diff --git a/src/prices.ts b/src/prices.ts\n'),
    );
    expect(server.hunks.single['patch'], endsWith('   return list;\n'));
    expect(find.text('Tenuto'), findsWidgets);

    await tester.tap(find.byKey(const Key('hunk-comment-$head')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('hunk-comment-text')), 'Show the VAT too');
    await tester.tap(find.byKey(const Key('hunk-comment-send')));
    await _settle(tester);
    expect(server.sent.last['text'], contains('Show the VAT too'));
    expect(server.sent.last['text'], contains('```diff'));
    expect(find.text('Mandato a Coder Web.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('diff-next')));
    await _settle(tester);
    expect(find.text('2 di 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hunk-discard-@@ -1 +1 @@')));
    await _settle(tester);
    expect(find.text('Scartare questa modifica?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.hunks.last['action'], 'discard');
    expect(server.hunks.last['patch'], contains('+++ b/README.md'));

    // Which diff: a task's, a commit's.
    await tester.tap(find.byKey(const Key('diff-source')));
    await _settle(tester);
    await tester.tap(find.text('Commit abc1234 Prices 2026'));
    await _settle(tester);
    expect(server.requests.where((r) => r.contains('git/diff?commit=abc1234')), isNotEmpty);
    await done(tester);
  });

  testWidgets('Terminal: my shell over /term with the extra keys and the recent commands', (
    tester,
  ) async {
    final app = await start(tester);
    await openProject(tester, app, tab: ProjectTab.terminal);
    await tester.tap(find.byKey(const Key('term-open')));
    await _settle(tester);
    expect(server.termHellos.single['scope'], 'project:demo');
    expect(server.termHellos.single['token'], app.client!.token);
    expect(find.textContaining(r'demo $'), findsOneWidget);
    await tester.tap(find.byKey(const Key('key-esc')));
    await tester.tap(find.byKey(const Key('key-tab')));
    await tester.tap(find.byKey(const Key('key-up')));
    await tester.tap(find.byKey(const Key('key-ctrl')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('term-input')), 'c');
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('term-input')), 'git status -s');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await _settle(tester);
    expect(server.termInput, ['\x1b', '\t', '\x1b[A', '\x03', 'git status -s\r']);
    expect(
      find.descendant(
        of: find.byKey(const Key('term-recent')),
        matching: find.text('git status -s'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('term-bigger')));
    await _settle(tester);
    // An agent's: read only.
    await tester.tap(find.byKey(const Key('term-agent-a1')));
    await _settle(tester);
    expect(find.textContaining('M src/prices.ts', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('term-input')), findsNothing);
    await done(tester);
  });

  testWidgets('Log: errors only, and the JSON of an event', (tester) async {
    final app = await start(tester);
    await openProject(tester, app, tab: ProjectTab.log);
    expect(find.text('tool.call'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('log-errors')));
    await tester.tap(find.byKey(const Key('log-errors')));
    await _settle(tester);
    expect(server.requests.last, contains('errors=1'));
    expect(find.text('tool.call'), findsNothing);
    expect(find.text('agent.blocked'), findsOneWidget);
    await tester.tap(find.byKey(const Key('log-2')));
    await _settle(tester);
    expect(find.byKey(const Key('log-json-2')), findsOneWidget);
    expect(find.textContaining('"output": "token expired"'), findsOneWidget);
    await done(tester);
  });

  testWidgets('Git: commit, and a push that waits for the answer in «Da te»', (tester) async {
    final app = await start(tester);
    await openProject(tester, app, tab: ProjectTab.git);
    expect(find.byKey(const Key('git-branch')), findsOneWidget);
    expect(find.text('segue origin/p2.4.0'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('git-message')), 'Prices 2026');
    await tester.tap(find.byKey(const Key('git-commit')));
    await _settle(tester);
    expect(server.commits, ['Prices 2026']);
    expect(find.text('Commit def5678 fatto.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('git-push')));
    await _settle(tester);
    expect(server.pushes, 1);
    expect(find.byKey(const Key('git-push-waiting')), findsOneWidget);
    server.jobs['job1'] = 'done';
    await tester.pump(const Duration(milliseconds: 1600));
    await _settle(tester);
    expect(find.byKey(const Key('git-push-waiting')), findsNothing);
    expect(find.text('Push fatto.'), findsOneWidget);
    // A commit opens its diff.
    await tester.scrollUntilVisible(
      find.byKey(const Key('commit-abc1234')),
      200,
      scrollable: find
          .descendant(of: find.byKey(const Key('git-list')), matching: find.byType(Scrollable))
          .first,
    );
    // The note «Push fatto.» goes, so it does not cover the row.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
        .removeCurrentSnackBar();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('commit-abc1234')));
    await _settle(tester);
    // The Diff tab is built at the end of the slide, then asks for the commit.
    await _settle(tester);
    expect(server.requests.where((r) => r.contains('git/diff?commit=abc1234')), isNotEmpty);
    await done(tester);
  });

  testWidgets('an archived project is read only: no keep, discard, edit or terminal', (
    tester,
  ) async {
    server.archived = true;
    final app = await start(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const ProjectScreen(
          project: Project(id: 'demo', name: 'Demo', archived: true),
          initial: ProjectTab.diff,
        ),
      ),
    );
    await _settle(tester);
    expect(find.textContaining('Progetto archiviato'), findsOneWidget);
    expect(
      find.byKey(const Key('hunk-keep-@@ -12,3 +12,4 @@ export function prices()')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('hunk-discard-@@ -12,3 +12,4 @@ export function prices()')),
      findsNothing,
    );
    await tester.ensureVisible(find.byKey(const Key('ptab-git')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ptab-git')));
    await _settle(tester);
    expect(find.byKey(const Key('git-commit')), findsNothing);
    expect(find.byKey(const Key('git-push')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('ptab-terminal')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ptab-terminal')));
    await _settle(tester);
    final open = tester.widget<FilledButton>(find.byKey(const Key('term-open')));
    expect(open.onPressed, isNull);
    expect(app.advanced, isTrue);
    await done(tester);
  });

  testWidgets('a tablet held sideways: tree and file side by side', (tester) async {
    final app = await start(tester, size: const Size(3600, 2400));
    await openProject(tester, app, tab: ProjectTab.files);
    expect(find.text('Scegli un file a sinistra.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('file-README.md')));
    await _settle(tester);
    expect(find.byKey(const Key('file-view')), findsOneWidget);
    expect(find.byKey(const Key('files-list')), findsOneWidget);
    await done(tester);
  });
}
