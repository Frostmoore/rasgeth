// G42.5: projects, files and terminal, native, against the fake RedGiant (which answers as
// app.ts, projects.ts, setup.ts and terminal.ts). Projects in the phone's bar without the
// advanced interface, «New project» there; subprojects (listed under the project, made new or
// brought in, their image, their agents' conversations, their files opening on their folder);
// Settings › Projects (initialise git, archive, restore) and › Code (GitHub's token, Gitea started
// here with its job and the download's bar, a Gitea of one's own, the repositories again); the
// terminal drawn by xterm with a recorded session (colours, vim and htop in the other buffer,
// exit and «Open again»), the phone's keys, the computer's tab beside the conversation.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/code.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/files/files_explorer.dart';
import 'package:rgcompanion/settings/code_settings.dart';
import 'package:rgcompanion/settings/projects_settings.dart';
import 'package:rgcompanion/terminal/rg_terminal.dart';
import 'package:rgcompanion/terminal/terminal_screen.dart';
import 'package:rgcompanion/theme/theme.dart';

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

void main() {
  group('pure parts', () {
    test('a subproject\'s agent: the files open on its folder, with the ones above it', () {
      const sub = Subproject(id: 'sub_1', projectId: 'demo', name: 'Shop', dir: 'apps/shop');
      const a = Agent(
        id: 'a3',
        kind: AgentKind.agent,
        name: 'Coder',
        active: true,
        projectId: 'demo',
        subprojectId: 'sub_1',
      );
      final place = explorerPlaceOf(
        agent: a,
        projects: const [Project(id: 'demo', name: 'Demo')],
        subprojects: const [sub],
      );
      expect(place.scope, _demo);
      expect(place.focus, 'apps/shop');
      expect(foldersToReveal(place.focus), ['apps', 'apps/shop']);
      expect(foldersToReveal('/one/'), ['one']);
      expect(foldersToReveal(null), isEmpty);
      // The project's own agents: no focus.
      expect(
        explorerPlaceOf(
          agent: const Agent(
            id: 'a1',
            kind: AgentKind.agent,
            name: 'X',
            active: true,
            projectId: 'demo',
          ),
          subprojects: const [sub],
        ).focus,
        isNull,
      );
    });

    test('a held Ctrl or Alt changes the next character, as a terminal\'s keys', () {
      expect(withModifiers('c', ctrl: true), '\x03');
      expect(withModifiers('D', ctrl: true), '\x04');
      expect(withModifiers('x', alt: true), '\x1bx');
      expect(withModifiers('ab', ctrl: true), 'ab', reason: 'a paste is not a key');
      expect(withModifiers('a'), 'a');
    });

    test('git in the setup, as `GET /api/setup` says it', () {
      final none = GitSetup.fromSetup({'config': <String, dynamic>{}});
      expect((none.github, none.gitea), (false, false));
      final both = GitSetup.fromSetup({
        'config': {
          'git': {
            'github': {'login': 'severino'},
            'gitea': {'user': 'mario', 'publicUrl': 'https://git.casa', 'external': true},
          },
        },
      });
      expect(both.githubLogin, 'severino');
      expect(
        (both.giteaUser, both.giteaUrl, both.giteaExternal),
        ('mario', 'https://git.casa', true),
      );
      expect(hostOf('git.casa.lan/x'), 'git.casa.lan');
      expect(hostOf('https://git.example.org'), 'git.example.org');
    });

    test('a job\'s steps with the download\'s progress', () {
      final j = JobView.fromJson({
        'id': 'g',
        'kind': 'gitea',
        'state': 'running',
        'steps': [
          {
            'id': 'gitea_image',
            'state': 'running',
            'progress': {'done': 10, 'total': 100, 'rate': 5, 'secondsLeft': 18},
          },
          {'id': 'gitea_start', 'state': 'waiting'},
        ],
      });
      expect(j.kind, 'gitea');
      expect(j.steps.map((s) => (s.id, s.state, s.done, s.total, s.secondsLeft)).toList(), [
        ('gitea_image', 'running', 10, 100, 18),
        ('gitea_start', 'waiting', null, null, null),
      ]);
    });
  });

  late FakeRedGiant server;
  late FakeFiles fs;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    fs = FakeFiles()
      ..put(_demo, 'README.md', '# Demo\n')
      ..put(_demo, 'apps/shop/index.ts', 'export {};\n')
      ..put(_demo, 'apps/api/main.ts', 'export {};\n');
    server.files = fs;
    server.subprojects.add({
      'id': 'sub_1',
      'projectId': 'demo',
      'name': 'Shop',
      'dir': 'apps/shop',
      'createdAt': '2026-11-17T09:00:00.000Z',
    });
    server.agentOverrides['a3'] = {'projectId': 'demo', 'subprojectId': 'sub_1'};
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    DevicePlatform platform = DevicePlatform.android,
  }) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
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
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await _settle(tester, rounds);
  }

  testWidgets('phone: Projects in the bar without the advanced interface, «New project»', (
    tester,
  ) async {
    final app = await start(tester);
    expect(app.advanced, isFalse);
    expect(app.subprojects.map((s) => s.name), ['Shop']);
    await tap(tester, find.byKey(const Key('tab-projects')));
    expect(find.byKey(const Key('project-demo')), findsOneWidget);
    // The subprojects on the card; no git state without the advanced interface.
    expect(
      find.descendant(of: find.byKey(const Key('project-subs-demo')), matching: find.text('Shop')),
      findsOneWidget,
    );
    expect(server.requests.where((r) => r.contains('/git')), isEmpty);
    await tap(tester, find.byKey(const Key('projects-new')));
    await tester.enterText(find.byKey(const Key('new-project-name')), 'Negozio');
    await tap(tester, find.byKey(const Key('dialog-yes')), 14);
    expect(server.projectPosts.single['name'], 'Negozio');
    expect(app.projects.map((p) => p.name), contains('Negozio'));
    await done(tester);
  });

  testWidgets('subprojects: listed, opened, made new with an image, an existing one brought in', (
    tester,
  ) async {
    server.madeProjects.add({
      'id': 'proj_old',
      'name': 'Vecchio',
      'path': '/projects/Vecchio',
      'createdAt': '2026-11-01T10:00:00.000Z',
    });
    final app = await start(tester);
    await tap(tester, find.byKey(const Key('tab-projects')));
    await tap(tester, find.byKey(const Key('project-demo')), 12);
    await tester.scrollUntilVisible(
      find.byKey(const Key('sub-sub_1')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('apps/shop/ · 1 agente'), findsOneWidget);
    // Open: its agent's conversations (or that there are none yet).
    await tap(tester, find.byKey(const Key('sub-sub_1')));
    expect(find.byKey(const Key('sub-team-sub_1')), findsOneWidget);

    // A new one, in a folder of its choice, with its own image.
    await tap(tester, find.byKey(const Key('sub-new-demo')));
    expect(find.byKey(const Key('sub-window')), findsOneWidget);
    final create = find.byKey(const Key('sub-create'));
    expect(tester.widget<FilledButton>(create).onPressed, isNull, reason: 'a name is needed');
    await tester.enterText(find.byKey(const Key('sub-name')), 'Api');
    await tester.enterText(find.byKey(const Key('sub-dir')), 'apps/api');
    await tester.enterText(find.byKey(const Key('sub-image')), 'ghcr.io/cirruslabs/flutter:stable');
    await _settle(tester, 2);
    await tap(tester, create, 14);
    expect(find.byKey(const Key('sub-window')), findsNothing);
    expect(server.subprojects.last['dir'], 'apps/api');
    expect(server.subprojectImages['sub_2'], 'ghcr.io/cirruslabs/flutter:stable');
    expect(app.subprojects.map((s) => s.name), ['Shop', 'Api']);

    // The same folder again: the server's words, the window stays.
    await tap(tester, find.byKey(const Key('sub-new-demo')));
    await tester.enterText(find.byKey(const Key('sub-name')), 'Api');
    await tester.enterText(find.byKey(const Key('sub-dir')), 'apps/api');
    await _settle(tester, 2);
    await tap(tester, find.byKey(const Key('sub-create')), 10);
    expect(find.byKey(const Key('sub-error')), findsOneWidget);
    await tap(tester, find.byKey(const Key('sub-cancel')));

    // An existing project brought in: asked first (the page's words), then gone from the list.
    await tap(tester, find.byKey(const Key('sub-new-demo')));
    await tap(tester, find.byKey(const Key('sub-from-proj_old')));
    expect(find.byKey(const Key('sub-name')), findsNothing);
    await tap(tester, find.byKey(const Key('sub-create')));
    expect(find.textContaining('entra in questo come sottoprogetto'), findsOneWidget);
    await tap(tester, find.byKey(const Key('dialog-yes')), 14);
    expect(server.adopted, ['proj_old']);
    expect(app.projects.map((p) => p.id), isNot(contains('proj_old')));
    expect(app.subprojects.map((s) => s.name), ['Shop', 'Api', 'Vecchio']);
    await done(tester);
  });

  testWidgets('a subproject\'s files open on its folder; its agent\'s conversation too', (
    tester,
  ) async {
    final app = await start(tester);
    await tap(tester, find.byKey(const Key('tab-projects')));
    await tap(tester, find.byKey(const Key('project-demo')), 12);
    await tester.scrollUntilVisible(
      find.byKey(const Key('sub-files-sub_1')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tap(tester, find.byKey(const Key('sub-files-sub_1')), 14);
    expect(find.byType(FilesScreen), findsOneWidget);
    // The folders down to apps/shop are open, its file in sight; apps/api stays closed.
    expect(find.byKey(const Key('files-row-apps/shop/index.ts')), findsOneWidget);
    expect(find.byKey(const Key('files-row-apps/api/main.ts')), findsNothing);
    Navigator.of(tester.element(find.byType(FilesScreen))).pop();
    await _settle(tester);

    // From the subproject's agent's conversation: the same folder (the page's currentScope).
    final a3 = app.agents.firstWhere((a) => a.id == 'a3');
    expect(a3.subprojectId, 'sub_1');
    expect(explorerPlaceFor(app, 's1', a3).focus, 'apps/shop');
    await done(tester);
  });

  testWidgets('Settings › Projects: initialise git, archive with the window, restore', (
    tester,
  ) async {
    server.madeProjects.add({
      'id': 'proj_ng',
      'name': 'Senza git',
      'path': '/projects/Senza git',
      'createdAt': '2026-11-01T10:00:00.000Z',
      'git': false,
    });
    final app = await start(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const ProjectsSettingsScreen())).ignore();
    await _settle(tester);
    expect(find.text('/projects/Senza git'), findsOneWidget);
    expect(find.text('Senza repository git'), findsOneWidget);
    await tap(tester, find.byKey(const Key('ps-git-proj_ng')), 12);
    expect(server.gitInits, ['proj_ng']);
    expect(find.byKey(const Key('ps-notice')), findsOneWidget);
    expect(find.byKey(const Key('ps-git-proj_ng')), findsNothing);
    // Archive: the project's window first (who works, what pauses), then the archived list.
    await tap(tester, find.byKey(const Key('ps-archive-demo')), 10);
    await tap(tester, find.byKey(const Key('proj-archive-yes')), 14);
    expect(server.projectActs, ['archive demo']);
    expect(app.archivedProjects.map((p) => p.id), ['demo']);
    await tap(tester, find.byKey(const Key('ps-restore-demo')), 14);
    expect(server.projectActs, ['archive demo', 'restore demo']);
    expect(app.archivedProjects, isEmpty);
    // Where the code lives, one tap away.
    await tap(tester, find.byKey(const Key('ps-code')), 12);
    expect(find.byType(CodeSettingsScreen), findsOneWidget);
    await done(tester);
  });

  testWidgets('Settings › Code: GitHub\'s token, then disconnected', (tester) async {
    await start(tester, size: const Size(1200, 900), platform: DevicePlatform.linux);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const CodeSettingsScreen())).ignore();
    await _settle(tester);
    expect(find.text('Dove sta il codice?'), findsOneWidget);
    expect(find.byKey(const Key('cs-sync')), findsNothing, reason: 'nothing linked yet');
    await tap(tester, find.byKey(const Key('cs-github')));
    final save = find.byKey(const Key('cs-github-save'));
    await tester.enterText(find.byKey(const Key('cs-github-token')), 'short');
    await _settle(tester, 2);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('cs-github-token')), 'ghp_classic_token_00000000');
    await _settle(tester, 2);
    await tap(tester, save, 10);
    expect(find.text('GitHub did not accept the token'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cs-github-token')), 'github_pat_0123456789abcdef');
    await _settle(tester, 2);
    await tap(tester, save, 12);
    expect(find.text('Collegato come @severino'), findsOneWidget);
    await tap(tester, find.byKey(const Key('cs-done')), 10);
    expect(find.text('collegato'), findsOneWidget);
    // Linked: the projects' repositories made again, each with its outcome.
    await tap(tester, find.byKey(const Key('cs-sync')), 10);
    expect(find.text('Demo · repository pronta'), findsOneWidget);
    expect(find.text('Shop · GitHub answered 403'), findsOneWidget);
    await tap(tester, find.byKey(const Key('cs-github')));
    await tap(tester, find.byKey(const Key('cs-github-remove')), 10);
    expect(find.byKey(const Key('cs-github-token')), findsOneWidget);
    expect(server.gitCalls, [
      'PUT /api/setup/github',
      'PUT /api/setup/github',
      'POST /api/setup/git/sync',
      'DELETE /api/setup/github',
    ]);
    await done(tester);
  });

  testWidgets('Settings › Code: Gitea started here, its job with the download\'s bar', (
    tester,
  ) async {
    await start(tester, size: const Size(1200, 900), platform: DevicePlatform.linux);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const CodeSettingsScreen())).ignore();
    await _settle(tester);
    await tap(tester, find.byKey(const Key('cs-gitea')));
    final create = find.byKey(const Key('cs-gitea-create'));
    await tester.enterText(find.byKey(const Key('cs-gitea-user')), 'mario');
    await tester.enterText(find.byKey(const Key('cs-gitea-password')), 'una-password-lunga');
    await tester.enterText(find.byKey(const Key('cs-gitea-again')), 'una-password-diversa');
    await _settle(tester, 2);
    expect(find.text('Le due password sono diverse.'), findsOneWidget);
    expect(tester.widget<FilledButton>(create).onPressed, isNull);
    await tester.enterText(find.byKey(const Key('cs-gitea-again')), 'una-password-lunga');
    await _settle(tester, 2);
    await tap(tester, create, 4);
    // The job's first reading: the image coming down, how much, how fast, how long still.
    expect(find.byKey(const Key('cs-job')), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
      await _settle(tester, 4);
    }
    // Three readings later: done, and the settings say Gitea is there.
    expect(server.giteaPolls, greaterThanOrEqualTo(3));
    expect(find.text('Fatto.'), findsOneWidget);
    expect(find.text('Gitea è pronto, utente mario'), findsOneWidget);
    expect(find.byKey(const Key('cs-gitea-open')), findsOneWidget);
    await tap(tester, find.byKey(const Key('cs-gitea-stop')), 10);
    expect(server.gitCalls.last, 'DELETE /api/setup/gitea');
    await done(tester);
  });

  testWidgets('Gitea\'s steps: the bar with how much, how fast, how long still', (tester) async {
    final job = JobView.fromJson(server.giteaJob());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        theme: buildTheme(Brightness.light),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: JobSteps(job: job)),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('cs-job-bar-gitea_image')), findsOneWidget);
    expect(find.text('40,0 MB di 100,0 MB · 5,0 MB/s · ancora 12 s'), findsOneWidget);
  });

  testWidgets('Settings › Code: a Gitea of one\'s own; a name nobody knows said in words', (
    tester,
  ) async {
    await start(tester, size: const Size(1200, 900), platform: DevicePlatform.linux);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => const CodeSettingsScreen())).ignore();
    await _settle(tester);
    await tap(tester, find.byKey(const Key('cs-gitea')));
    await tap(tester, find.byKey(const Key('cs-gitea-existing')));
    await tester.enterText(find.byKey(const Key('cs-gitea-url')), 'git.nowhere.lan');
    await tester.enterText(find.byKey(const Key('cs-gitea-ext-user')), 'mario');
    await tester.enterText(find.byKey(const Key('cs-gitea-token')), 'token-1234567');
    await _settle(tester, 2);
    await tap(tester, find.byKey(const Key('cs-gitea-connect')), 10);
    expect(find.textContaining('RedGiant non trova git.nowhere.lan'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cs-gitea-url')), 'https://git.casa.lan');
    await tester.enterText(find.byKey(const Key('cs-gitea-token')), 'token-1234567');
    await _settle(tester, 2);
    await tap(tester, find.byKey(const Key('cs-gitea-connect')), 12);
    expect(find.text('Collegato a https://git.casa.lan, utente mario'), findsOneWidget);
    expect(find.text('Scollega'), findsOneWidget);
    await done(tester);
  });

  group('the terminal', () {
    Future<RgTerminalState> screen(WidgetTester tester, AppController app) async {
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => const TerminalScreen(scope: _demo, title: 'Terminale · Demo'),
            ),
          )
          .ignore();
      await _settle(tester);
      return tester.state<RgTerminalState>(find.byType(RgTerminal));
    }

    testWidgets('a recorded session: colours, vim and htop in the other buffer, exit', (
      tester,
    ) async {
      final app = await start(tester);
      final t = await screen(tester, app);
      // `hello` with the size the view measured, as the page's fit addon.
      final hello = server.termHellos.single;
      expect(hello['scope'], _demo);
      expect(hello['cols'], greaterThan(20));
      expect(hello['rows'], greaterThan(10));
      expect(t.terminal.buffer.getText(), contains(r'demo $'));
      expect(find.byKey(const Key('term-keys')), findsOneWidget, reason: 'a phone');

      t.terminal.textInput('ls --color\r');
      await _settle(tester);
      expect(t.terminal.buffer.getText(), contains('build.sh'));

      t.terminal.textInput('vim README.md\r');
      await _settle(tester);
      expect(t.terminal.isUsingAltBuffer, isTrue);
      expect(t.terminal.buffer.getText(), contains('# Demo shop'));
      expect(t.terminal.buffer.getText(), contains('"README.md" 1L, 12B'));
      // In vim the arrows are the program's (application cursor keys), from the row too.
      server.termInput.clear();
      await tap(tester, find.byKey(const Key('key-down')), 4);
      await tap(tester, find.byKey(const Key('key-esc')), 4);
      expect(server.termInput.take(2), [anyOf('\x1b[B', '\x1bOB'), '\x1b']);
      t.terminal.textInput(':q\r');
      await _settle(tester);
      expect(t.terminal.isUsingAltBuffer, isFalse);

      t.terminal.textInput('htop\r');
      await _settle(tester);
      expect(t.terminal.isUsingAltBuffer, isTrue);
      expect(t.terminal.buffer.getText(), contains('Load average'));
      // Ctrl held, then «c» from the keyboard: Ctrl+C.
      server.termInput.clear();
      await tap(tester, find.byKey(const Key('key-ctrl')), 2);
      t.terminal.textInput('c');
      await _settle(tester, 4);
      expect(server.termInput, ['\x03']);
      expect(t.terminal.isUsingAltBuffer, isFalse, reason: 'htop ended');

      // Bigger text: the terminal is measured again and the server told.
      await tap(tester, find.byKey(const Key('term-bigger')), 6);
      await tap(tester, find.byKey(const Key('term-bigger')), 6);
      expect(server.termResizes, isNotEmpty);

      // The shell ends: the page's grey line, and «Open again».
      t.terminal.textInput('exit\r');
      await _settle(tester);
      expect(t.ended, isTrue);
      expect(t.terminal.mainBuffer.getText(), contains('Il terminale si è chiuso.'));
      await tap(tester, find.byKey(const Key('term-reopen')), 12);
      expect(server.termHellos, hasLength(2));
      expect(t.ended, isFalse);
      await done(tester);
    });

    testWidgets('the files\' «Terminal» on a phone: the whole screen, any place', (tester) async {
      final app = await start(tester);
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
      await tap(tester, find.byKey(const Key('conversation-files')), 12);
      await tap(tester, find.byKey(const Key('files-terminal')), 12);
      expect(find.byType(TerminalScreen), findsOneWidget);
      expect(find.text('Terminale · Demo'), findsOneWidget);
      expect(server.termHellos.single['scope'], _demo);
      await done(tester);
    });

    testWidgets('computer: the files\' «Terminal» opens a tab beside the conversation', (
      tester,
    ) async {
      final app = await start(tester, size: const Size(1440, 900), platform: DevicePlatform.linux);
      await tap(tester, find.byKey(const Key('tile-a3')));
      await tap(tester, find.byKey(const Key('agent-conv-new')), 12);
      DeskScope.read(tester.element(find.byKey(const Key('desk-panel')))).setFull(true);
      await _settle(tester);
      await tap(tester, find.byKey(const Key('conversation-files')));
      expect(find.byKey(const Key('conversation-files-side')), findsOneWidget);
      await tap(tester, find.byKey(const Key('files-terminal')), 12);
      // Two things in the column: the tabs, the terminal in front.
      expect(find.byKey(const Key('side-tab-files')), findsOneWidget);
      expect(find.byKey(const Key('side-tab-term-1')), findsOneWidget);
      expect(find.byType(RgTerminal), findsOneWidget);
      expect(find.byKey(const Key('term-keys')), findsNothing, reason: 'a real keyboard');
      expect(server.termHellos.single['scope'], _demo);
      // A second one, then back to the files, then the first closed.
      await tap(tester, find.byKey(const Key('side-tab-files')));
      await tap(tester, find.byKey(const Key('files-terminal')), 12);
      expect(server.termHellos, hasLength(2));
      expect(find.byKey(const Key('side-tab-term-2')), findsOneWidget);
      await tap(tester, find.byKey(const Key('side-tab-close-term-1')), 6);
      expect(find.byKey(const Key('side-tab-term-1')), findsNothing);
      await tap(tester, find.byKey(const Key('side-tab-close-term-2')), 6);
      expect(find.byKey(const Key('side-tabs')), findsNothing);
      expect(app.connected, isTrue);
      await done(tester);
    });
  });
}
