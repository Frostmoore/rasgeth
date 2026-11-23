// G42.4: agents, native as the page's Settings › Agents. The tree beyond the first level (the
// page's TreeView rules as one pure function, three levels, assigned agents, the stopped ones),
// «Agent under it», the new agent's steps with God's proposal (instructions and tools, `tools_off`
// never essential), a personal assistant's services, routines, skills and shared notes, the
// server's refusals, and an archived project's agent read only. Against the fake Rasgeth.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/agent_settings_screen.dart';
import 'package:rgcompanion/settings/agents/add_agent_under.dart';
import 'package:rgcompanion/settings/agents/agent_tree.dart';

import 'fake_server.dart';

Agent _a(
  String id,
  String kind, {
  String? parent,
  String? project,
  List<String>? projects,
  String status = 'active',
}) => Agent.fromJson({
  'id': id,
  'kind': kind,
  'name': id.toUpperCase(),
  'parentId': parent,
  'projectId': project,
  'projects': ?projects,
  'status': status,
});

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<Map<String, dynamic>> _body(HttpRequest r) async =>
    jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;

void main() {
  group('the tree, as the page draws it', () {
    final all = [
      _a('g', 'god'),
      _a('d', 'demigod', parent: 'g'),
      _a('s', 'assistant', parent: 'g'),
      _a('o', 'orchestrator', parent: 'g', project: 'demo'),
      _a('i', 'inspector', parent: 'g', project: 'demo'),
      _a('x', 'agent', parent: 'o', project: 'demo'),
      _a('y', 'subagent', parent: 'x', project: 'demo'),
      _a('w', 'agent', parent: 'o', project: 'demo', status: 'stopped'),
      _a('z', 'agent', parent: 'o2', project: 'site', projects: ['demo']),
      _a('o2', 'orchestrator', parent: 'g', project: 'site'),
    ];

    test('God on top, the group under it, a frame per project, three levels', () {
      final f = agentForest(all);
      expect([for (final r in f.roots) r.id], ['g']);
      expect([for (final a in f.near) a.id], ['d', 's']);
      expect([for (final p in f.frames) p.projectId], ['demo', 'site']);
      final demo = f.frames.first;
      expect([for (final n in demo.leads) n.agent.id], ['o', 'i']);
      final o = demo.leads.first;
      expect(o.plus, isTrue);
      expect(
        [for (final (n, d) in o.walk()) '${n.agent.id}$d${n.assigned ? '*' : ''}'],
        ['o0', 'x1', 'y2', 'z1*'],
      );
      // The inspector has nobody under it and no «Agent under it».
      expect(demo.leads.last.children, isEmpty);
      expect(demo.leads.last.plus, isFalse);
    });

    test('the stopped ones on request; one project from its lead down', () {
      final f = agentForest(all, showStopped: true);
      expect(
        [for (final (n, _) in f.frames.first.leads.first.walk()) n.agent.id],
        ['o', 'x', 'y', 'w', 'z'],
      );
      final only = agentForest(all, projectId: 'demo');
      expect(only.roots, isEmpty);
      expect([for (final p in only.frames) p.projectId], ['demo']);
      // The assigned agent's own orchestrator is not in this project: it hangs, dashed, here.
      expect(
        [for (final (n, _) in only.frames.single.leads.first.walk()) n.agent.id],
        ['o', 'x', 'y', 'z'],
      );
    });

    test('who may hang under whom (the page\'s CHILDREN, never a helper by hand)', () {
      expect(addableUnder(_a('g', 'god')), [
        AgentKind.demigod,
        AgentKind.orchestrator,
        AgentKind.inspector,
        AgentKind.assistant,
      ]);
      expect(addableUnder(_a('o', 'orchestrator')), [AgentKind.agent]);
      expect(addableUnder(_a('x', 'agent')), isEmpty);
      expect(canAddUnder(_a('o', 'orchestrator', status: 'stopped')), isFalse);
    });
  });

  group('in the app', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      // A three-level team in Demo: its lead, an agent, the agent's helper; the inspector.
      server.agentOverrides['a2'] = {'projectId': 'demo'};
      server.agentOverrides['a3'] = {'projectId': 'demo', 'parentId': 'a2'};
      server.agentOverrides['a4'] = {'projectId': 'demo', 'parentId': 'a2'};
      server.agentOverrides['a6'] = {'projectId': 'demo'};
      server.agentOverrides['a7'] = {'projectId': 'demo', 'parentId': 'a3'};
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 900)}) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
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

    Future<void> push(WidgetTester tester, Widget screen) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
      await _settle(tester);
    }

    /// The screen's own list (the tallest scrolling down; text fields scroll too).
    Finder mainList(WidgetTester tester) {
      final lists = [
        for (final e in find.byType(Scrollable).evaluate())
          if ((e.widget as Scrollable).axisDirection == AxisDirection.down) e,
      ]..sort((x, y) => (y.size?.height ?? 0).compareTo(x.size?.height ?? 0));
      return find.byElementPredicate((e) => e == lists.first);
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      // A row the lazy list has not built (below, or scrolled away above): scroll to it.
      for (final step in [300.0, -300.0]) {
        if (f.evaluate().isNotEmpty) break;
        try {
          await tester.scrollUntilVisible(f, step, scrollable: mainList(tester), maxScrolls: 30);
        } on StateError {
          // Not that way.
        }
      }
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await _settle(tester, 6);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the tree from Team: three levels, open and close, settings, agent under it', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.byKey(const Key('team-tree')));
      await _settle(tester);
      expect(find.byType(AgentTreeScreen), findsOneWidget);
      expect(find.text('La tua squadra'), findsOneWidget);
      // Constellation (3.10.3): the name, and what it is beside it.
      expect(find.text('Constellation'), findsOneWidget);
      expect(find.text('la squadra di agenti, a livelli'), findsOneWidget);
      expect(find.byKey(const Key('tree-project-demo')), findsOneWidget);
      // The helper, two levels under the lead.
      expect(find.byKey(const Key('tree-node-a7')), findsOneWidget);
      // One project only.
      await tap(tester, 'tree-filter-demo');
      expect(find.byKey(const Key('tree-node-a5')), findsNothing);
      expect(find.byKey(const Key('tree-node-a2')), findsOneWidget);
      await tap(tester, 'tree-filter-all');
      expect(find.byKey(const Key('tree-node-a5')), findsOneWidget);
      await tap(tester, 'tree-toggle-a3');
      expect(find.byKey(const Key('tree-node-a7')), findsNothing);
      await tap(tester, 'tree-toggle-a3');
      expect(find.byKey(const Key('tree-node-a7')), findsOneWidget);
      // A tap opens its settings.
      await tap(tester, 'tree-node-a7');
      expect(find.byType(AgentSettingsScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('agent-settings-back')));
      await _settle(tester);
      // «Agent under it», the page's technical form.
      await tap(tester, 'tree-add-a2');
      expect(find.byType(AddAgentUnder), findsOneWidget);
      expect(find.text('Aggiungi un agente sotto Capo cantiere'), findsOneWidget);
      // Under a lead only an agent: no kind to choose.
      expect(find.byKey(const Key('add-kind-agent')), findsNothing);
      await tester.enterText(find.byKey(const Key('add-name')), 'Collaudatore');
      await tester.enterText(find.byKey(const Key('add-role')), 'prova tutto');
      await tap(tester, 'add-mode-plan');
      await tap(tester, 'add-create');
      await _settle(tester, 30);
      expect(server.newAgents.single, {
        'kind': 'agent',
        'parentId': 'a2',
        'name': 'Collaudatore',
        'role': 'prova tutto',
        'mode': 'plan',
      });
      await tester.pumpAndSettle();
      expect(find.byType(AddAgentUnder), findsNothing);
      await done(tester);
    });

    testWidgets('«Agent under it» says the server\'s refusal', (tester) async {
      server.routes['POST /api/agents'] = (r) async {
        await utf8.decodeStream(r);
        await server.answer(r, 400, {'error': 'Only one orchestrator per project'});
      };
      final app = await start(tester);
      await push(tester, AddAgentUnder(parent: app.god!));
      await tap(tester, 'add-kind-orchestrator');
      await tester.enterText(find.byKey(const Key('add-name')), 'Capo 2');
      await tester.pump();
      await tap(tester, 'add-create');
      expect(find.byKey(const Key('add-under-error')), findsOneWidget);
      expect(find.textContaining('Only one orchestrator per project'), findsOneWidget);
      await done(tester);
    });

    testWidgets('a project\'s agent: ready role, subproject, mode, God\'s proposal', (
      tester,
    ) async {
      server.subprojects.add({'id': 'web', 'projectId': 'demo', 'name': 'Sito', 'dir': 'site'});
      Map<String, dynamic>? asked;
      server.routes['POST /api/prompts/refine'] = (r) async {
        asked = await _body(r);
        await server.answer(r, 200, {
          'text': 'You review the site. Be brief.',
          'changes': 'Fitted to reviewing.',
          'inputTokens': 3000,
          'outputTokens': 900,
          'usd': null,
          'model': {'provider': 'claude-subscription', 'model': 'claude-sonnet-5'},
          'tools': [
            {'id': 'fetch', 'on': false, 'why': 'not needed to review', 'tokens': 310},
            {'id': 'web_search', 'on': true, 'why': 'to check links', 'tokens': 280},
          ],
        });
      };
      await start(tester);
      await tester.tap(find.byKey(const Key('team-new-agent')));
      await _settle(tester);
      await tap(tester, 'new-kind-agent');
      await tap(tester, 'new-agent-next');
      expect(find.text('Passo 2 di 9'), findsOneWidget);
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-project-demo');
      // Demo has a subproject: where it works.
      expect(find.text('Dove lavora'), findsOneWidget);
      await tap(tester, 'new-sub-web');
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-role-reviewer');
      await tap(tester, 'new-agent-next');
      // Named after its role, until the person types another.
      expect(
        tester.widget<TextField>(find.byKey(const Key('new-agent-name'))).controller!.text,
        'Revisore',
      );
      await tester.enterText(find.byKey(const Key('new-agent-name')), 'Revisore del sito');
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-agent-next');
      // How much it may do alone; the button says God writes next, and about what it costs.
      await tap(tester, 'new-mode-plan');
      expect(find.text('Avanti: God scrive le sue istruzioni'), findsOneWidget);
      expect(find.textContaining('Stima:'), findsOneWidget);
      await tap(tester, 'new-agent-next');
      await _settle(tester);
      expect(asked?['goal'], 'draft');
      expect((asked?['target'] as Map)['draft'], {
        'kind': 'agent',
        'name': 'Revisore del sito',
        'role': startsWith('Review changes for bugs'),
        'projectId': 'demo',
        'mode': 'plan',
      });
      expect(find.byKey(const Key('tool-proposal')), findsOneWidget);
      // God switched one off; the person keeps it so. No hand list: God chose.
      expect(find.byKey(const Key('new-tool-fetch')), findsNothing);
      await tap(tester, 'new-agent-next');
      expect(find.text('Ecco il nuovo agente'), findsOneWidget);
      expect(find.text('Sito (site/)'), findsOneWidget);
      expect(find.text('1 spenti'), findsOneWidget);
      await tap(tester, 'new-agent-next');
      await _settle(tester);
      expect(server.newAgents.single, {
        'kind': 'agent',
        'parentId': 'a2',
        'name': 'Revisore del sito',
        'projectId': 'demo',
        'subprojectId': 'web',
        'role': 'Revisore',
        'mode': 'plan',
      });
      expect(server.promptPuts.single, {
        'who': 'agent_1',
        'text': 'You review the site. Be brief.',
      });
      expect(server.toolChoices['agent_1'], {'fetch': 'off'});
      expect(find.byKey(const Key('new-agent-done')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a personal assistant: ready job, its services, God without tools', (tester) async {
      server.extraJson['GET /api/extensions/mcp'] = [
        {
          'name': 'notion',
          'project_id': null,
          'transport': {'type': 'http', 'url': 'x'},
        },
        {
          'name': 'demo-db',
          'project_id': 'demo',
          'transport': {'type': 'http', 'url': 'y'},
        },
      ];
      server.extraJson['GET /api/extensions/mcp/status'] = [
        {'name': 'notion', 'projectId': null, 'state': 'connected', 'tools': 5},
      ];
      await start(tester);
      await tester.tap(find.byKey(const Key('team-new-agent')));
      await _settle(tester);
      await tap(tester, 'new-kind-assistant');
      expect(find.byKey(const Key('new-agent-ask-god')), findsOneWidget);
      await tap(tester, 'new-agent-next');
      // 3.12.3: «Parti da…», here an empty agent made step by step.
      expect(find.byKey(const Key('new-agent-start')), findsOneWidget);
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-job-secretary');
      await tap(tester, 'new-agent-next');
      expect(
        tester.widget<TextField>(find.byKey(const Key('new-agent-name'))).controller!.text,
        'Segretaria',
      );
      expect(
        tester.widget<TextField>(find.byKey(const Key('new-agent-role'))).controller!.text,
        startsWith('Tieni in ordine le mie attività'),
      );
      await tap(tester, 'new-agent-next');
      // Only the services added for everyone, with their state.
      expect(find.text('Notion'), findsOneWidget);
      expect(find.text('Funziona · 5 strumenti'), findsOneWidget);
      expect(find.byKey(const Key('conn-mcp-demo-db')), findsNothing);
      await tap(tester, 'conn-mcp-notion');
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-mode-manual');
      await tap(tester, 'new-agent-next');
      await _settle(tester);
      // The fake God gives no tools: the hand list, never the essential ones.
      expect(find.byKey(const Key('new-tool-fetch')), findsOneWidget);
      expect(find.byKey(const Key('new-tool-read_file')), findsNothing);
      await tap(tester, 'new-tool-fetch');
      await tap(tester, 'new-agent-next');
      await tap(tester, 'new-agent-next');
      await _settle(tester);
      final made = server.newAgents.single;
      expect(made['kind'], 'assistant');
      expect(made['parentId'], 'a0');
      expect(made['name'], 'Segretaria');
      expect(made['connections'], [
        {'kind': 'mcp', 'ref': 'notion'},
      ]);
      expect(made['mode'], 'manual');
      expect(made['role'], startsWith('Tieni in ordine'));
      expect(made.containsKey('projectId'), isFalse);
      expect(server.toolChoices['agent_1'], {'fetch': 'off'});
      await done(tester);
    });

    testWidgets('an assistant\'s services, routines, skills and shared notes', (tester) async {
      server.agentOverrides['a5'] = {'connections': <String>[]};
      server.extraJson['GET /api/extensions/mcp'] = [
        {
          'name': 'notion',
          'project_id': null,
          'transport': {'type': 'http', 'url': 'x'},
        },
        {
          'name': 'gmail',
          'project_id': null,
          'transport': {'type': 'http', 'url': 'z'},
        },
      ];
      server.extraJson['GET /api/extensions/mcp/status'] = [
        {'name': 'notion', 'projectId': null, 'state': 'connected', 'tools': 5},
        {'name': 'gmail', 'projectId': null, 'state': 'login', 'tools': 0},
      ];
      server.extraJson['GET /api/extensions/installed'] = [
        {'kind': 'skill', 'scope': 'platform', 'name': 'fatture', 'description': 'Le fatture'},
        {'kind': 'skill', 'scope': 'project', 'name': 'altro', 'description': ''},
      ];
      var routines = <Map<String, dynamic>>[
        {
          'id': 'r1',
          'name': 'morning',
          'enabled': true,
          'recipe': {
            'name': 'morning',
            'description': 'Il punto del mattino',
            'agent': 'a5',
            'on': {'cron': '0 8 * * 1-5'},
          },
        },
        {
          'id': 'r2',
          'name': 'other',
          'enabled': true,
          'recipe': {
            'name': 'other',
            'agent': 'a3',
            'on': {'cron': '0 9 * * *'},
          },
        },
      ];
      final enabled = <Map<String, dynamic>>[];
      final yamls = <String>[];
      server.routes['GET /api/automations'] = (r) => server.answer(r, 200, routines);
      server.routes['POST /api/automations/r1/enabled'] = (r) async {
        final b = await _body(r);
        enabled.add(b);
        routines = [
          {...routines.first, 'enabled': b['enabled']},
          routines.last,
        ];
        await server.answer(r, 200, routines.first);
      };
      server.routes['POST /api/automations'] = (r) async {
        final y = (await _body(r))['yaml'] as String;
        yamls.add(y);
        if (yamls.length == 1) {
          await server.answer(r, 400, {'error': 'on.cron: Invalid cron'});
          return;
        }
        routines = [
          ...routines,
          {
            'id': 'r3',
            'name': 'new',
            'enabled': true,
            'recipe': {
              'name': 'new',
              'description': 'Le scadenze',
              'agent': 'a5',
              'on': {'cron': '30 7 * * 1-5'},
            },
          },
        ];
        await server.answer(r, 200, {'automation': routines.last});
      };
      server.notes['user'] = 'Sono Severino.';
      final app = await start(tester);
      final a5 = app.agents.firstWhere((a) => a.id == 'a5');
      await push(
        tester,
        AgentSettingsScreen(agentId: 'a5', agent: a5, initial: AgentGroup.assistant),
      );
      expect(find.byKey(const Key('as-assistant')), findsOneWidget);
      expect(find.text('Il punto del mattino'), findsOneWidget);
      expect(find.text('Dal lunedì al venerdì alle 08:00 · Attiva'), findsOneWidget);
      // Another agent's routine is not here; nor a project's skill.
      expect(find.byKey(const Key('as-routine-r2')), findsNothing);
      expect(find.byKey(const Key('as-skill-altro')), findsNothing);
      // A routine off.
      await tap(tester, 'as-routine-r1');
      expect(enabled.single, {'enabled': false});
      expect(find.text('Dal lunedì al venerdì alle 08:00 · Spenta'), findsOneWidget);
      // A skill off: the others stay (the list, no longer «every one»).
      await tap(tester, 'as-skill-fatture');
      expect(server.patches.last, {'agent': 'a5', 'skills': <String>[]});
      // A new routine: the whole editor of Settings › Automations (G42.9), this assistant
      // already chosen; the server refuses the first time and says why.
      await tap(tester, 'as-new-routine');
      expect(find.byKey(const Key('au-editor')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('au-title')), 'Le scadenze');
      await tester.enterText(
        find.byKey(const Key('au-instructions')),
        'Dimmi le scadenze della settimana',
      );
      await tester.pump();
      await tap(tester, 'au-save');
      expect(find.byKey(const Key('au-error')), findsOneWidget);
      expect(find.textContaining('Invalid cron'), findsOneWidget);
      await tap(tester, 'au-save');
      // A busy machine: the answer and the window's close may take a few more frames.
      for (var i = 0; i < 30 && find.byKey(const Key('au-editor')).evaluate().isNotEmpty; i++) {
        await _settle(tester, 2);
      }
      expect(yamls.last, contains('  cron: "0 8 * * 1-5"'));
      expect(yamls.last, contains('agent: "a5"'));
      expect(yamls.last, contains('description: "Le scadenze"'));
      expect(find.byKey(const Key('au-editor')), findsNothing);
      // The routine's window opened after the save: closed, the row is there.
      if (find.byKey(const Key('au-window-close')).evaluate().isNotEmpty) {
        await tap(tester, 'au-window-close');
      }
      expect(find.text('Le scadenze'), findsWidgets);
      // Its memory: what every agent knows about the person.
      await tap(tester, 'agent-group-memory');
      expect(find.byKey(const Key('as-notes-user')), findsOneWidget);
      expect(find.text('Sono Severino.'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the agent card: its conversation, agent under it, God rewrites for a new job', (
      tester,
    ) async {
      final app = await start(tester);
      final lead = app.agents.firstWhere((a) => a.id == 'a2');
      await push(tester, AgentSettingsScreen(agentId: 'a2', agent: lead));
      expect(find.byKey(const Key('as-open-chat')), findsOneWidget);
      expect(find.byKey(const Key('as-add-under')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('as-role')), 'Guida il sito e le sue traduzioni');
      await tap(tester, 'as-save-general');
      expect(find.byKey(const Key('as-rewrite-offer')), findsOneWidget);
      await tap(tester, 'as-rewrite-no');
      expect(find.byKey(const Key('as-rewrite-offer')), findsNothing);
      await tap(tester, 'as-add-under');
      expect(find.byType(AddAgentUnder), findsOneWidget);
      await done(tester);
    });

    testWidgets('an archived project\'s agent only reads', (tester) async {
      server.archived = true;
      final app = await start(tester);
      final a3 = app.agents.firstWhere((a) => a.id == 'a3');
      await push(tester, AgentSettingsScreen(agentId: 'a3', agent: a3));
      expect(find.byKey(const Key('agent-settings-archived')), findsOneWidget);
      // The groups still open (to read); their controls do nothing.
      await tap(tester, 'agent-group-work');
      expect(find.byKey(const Key('agent-settings-archived')), findsOneWidget);
      await tester.tap(find.byKey(const Key('as-mode-plan')), warnIfMissed: false);
      await _settle(tester);
      expect(server.patches, isEmpty);
      await done(tester);
    });

    test('the client reads subprojects, services and routines as the page', () async {
      server.subprojects.add({'id': 'web', 'projectId': 'demo', 'name': 'Sito', 'dir': 'site'});
      final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs());
      await app.connect(server.base.toString(), 'secret');
      final subs = await app.client!.subprojects('demo');
      expect([for (final s in subs) '${s.id} ${s.dir}'], ['web site']);
    });
  });
}
