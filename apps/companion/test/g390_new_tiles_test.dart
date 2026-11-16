// 3.9.0: in the control room «New agent» and «New project» are tiles of their walls, as big as
// their neighbours: the last one right after the last agent (or project), or under «no agents»
// («no projects») when there is none. «New project» follows the page's flow: the name, then
// `POST /api/projects` and its orchestrator under God.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/new_project.dart';
import 'package:rgcompanion/desktop/wall.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/new_agent_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.agentOverrides['a3'] = {'projectId': 'demo'};
    server.agentOverrides['a2'] = {'projectId': 'demo'};
  });
  tearDown(() => server.close());

  Future<AppController> start(WidgetTester tester, {bool advanced = false}) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
            platform: DevicePlatform.linux,
            liveEnabled: false,
          )
          ..locale = const Locale('it')
          ..reduceMotion = true;
    await tester.runAsync(() async {
      await app.connect(server.base.toString(), 'secret');
    });
    if (advanced) app.setAdvanced(true);
    tester.view.physicalSize = const Size(1440, 900);
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

  Future<void> projectsView(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('view-projects')));
    await _settle(tester);
  }

  final it = lookupAppLocalizations(const Locale('it'));

  test('the notice once a project is made: with its orchestrator, or without git', () {
    expect(
      madeNotice(it, const Project(id: 'p', name: 'Shop', git: true)),
      'Progetto «Shop» creato, con il suo orchestratore.',
    );
    expect(
      madeNotice(it, const Project(id: 'p', name: 'Shop')),
      'Progetto «Shop» creato, con il suo orchestratore.',
    );
    expect(
      madeNotice(
        it,
        const Project(id: 'p', name: 'Shop', git: false, gitError: 'git is not installed'),
      ),
      contains('git non è ancora installato'),
    );
    expect(
      Project.fromJson({'id': 'p', 'name': 'S', 'git': false, 'gitError': 'boom'}).gitError,
      'boom',
    );
  });

  testWidgets('agents: «New agent» is the last tile, right after the last agent', (tester) async {
    await start(tester);
    final add = find.byKey(const Key('desk-new-agent'));
    expect(add, findsOneWidget);
    // Inside the wall's grid, as big as an agent's tile, never above the last agent.
    expect(find.ancestor(of: add, matching: find.byType(SliverGrid)), findsOneWidget);
    final last = find.byType(AgentTile).last;
    expect(tester.getSize(add), tester.getSize(last));
    final a = tester.getRect(add);
    final b = tester.getRect(last);
    expect(a.top == b.top ? a.left > b.left : a.top > b.top, isTrue);
    expect(find.text(it.teamNoAgents), findsNothing);
    // By state too: the last section ends with it.
    await tester.tap(find.byKey(const Key('seg-Per stato')));
    await _settle(tester, 3);
    expect(find.ancestor(of: add, matching: find.byType(SliverGrid)), findsOneWidget);
    await tester.tap(add);
    await _settle(tester);
    expect(find.byType(NewAgentScreen), findsOneWidget);
    await done(tester);
  });

  testWidgets('agents: none yet, «New agent» under the words that say so', (tester) async {
    server.onlyLeaders = true;
    await start(tester);
    final words = find.text(it.teamNoAgents);
    final add = find.byKey(const Key('desk-new-agent'));
    expect(words, findsOneWidget);
    expect(add, findsOneWidget);
    expect(find.ancestor(of: add, matching: find.byType(SliverGrid)), findsNothing);
    expect(tester.getRect(add).top, greaterThan(tester.getRect(words).bottom));
    expect(tester.getSize(add), const Size(330, 168));
    await done(tester);
  });

  testWidgets('projects: «New project» after the last one makes it with its orchestrator', (
    tester,
  ) async {
    await start(tester);
    await projectsView(tester);
    final add = find.byKey(const Key('desk-new-project'));
    final demo = find.byKey(const Key('project-tile-demo'));
    expect(add, findsOneWidget);
    expect(find.ancestor(of: add, matching: find.byType(SliverGrid)), findsOneWidget);
    expect(tester.getSize(add), tester.getSize(demo));
    expect(tester.getRect(add).left, greaterThan(tester.getRect(demo).left));
    expect(find.text(it.deskNewProject), findsOneWidget);
    // Given up: nothing is made.
    await tester.tap(add);
    await _settle(tester, 4);
    await tester.tap(find.text(it.cancel));
    await _settle(tester, 4);
    expect(server.projectPosts, isEmpty);
    // The name, then the project and its orchestrator under God, as on the page.
    await tester.tap(add);
    await _settle(tester, 4);
    await tester.enterText(find.byKey(const Key('new-project-name')), '  Negozio  ');
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester, 16);
    expect(server.projectPosts, [
      {'name': 'Negozio'},
    ]);
    expect(server.newAgents.single, {
      'kind': 'orchestrator',
      'parentId': 'a0',
      'name': 'Negozio',
      'projectId': 'proj_1',
    });
    expect(find.byKey(const Key('project-tile-proj_1')), findsOneWidget);
    expect(find.text('Progetto «Negozio» creato, con il suo orchestratore.'), findsOneWidget);
    // Still the last tile.
    final made = tester.getRect(find.byKey(const Key('project-tile-proj_1')));
    final a = tester.getRect(add);
    expect(a.top == made.top ? a.left > made.left : a.top > made.top, isTrue);
    await done(tester);
  });

  testWidgets('projects: none yet, «New project» under the words; without git it says so', (
    tester,
  ) async {
    server
      ..noProjects = true
      ..gitMissing = true;
    await start(tester);
    await projectsView(tester);
    final words = find.text(it.deskNoProjects);
    final add = find.byKey(const Key('desk-new-project'));
    expect(words, findsOneWidget);
    expect(add, findsOneWidget);
    expect(find.ancestor(of: add, matching: find.byType(SliverGrid)), findsNothing);
    expect(tester.getRect(add).top, greaterThan(tester.getRect(words).bottom));
    await tester.tap(add);
    await _settle(tester, 4);
    await tester.enterText(find.byKey(const Key('new-project-name')), 'Orto');
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester, 16);
    expect(server.projectPosts, [
      {'name': 'Orto'},
    ]);
    expect(find.textContaining('senza repository git'), findsOneWidget);
    expect(find.byKey(const Key('project-tile-proj_1')), findsOneWidget);
    expect(find.text(it.deskNoProjects), findsNothing);
    await done(tester);
  });
}
