// «New agent» from Team (3.8.1): the page's steps for the phone with the page's API — the kind
// (a project's agent, orchestrator, personal assistant), the project, the name and job with the
// face it will get, the model (optional, Subscription / API key), tools to switch off (never the
// essential ones), then `POST /api/agents` with the page's fields, its tools, the new agent in the
// grid, «Change mascot» and its conversation. Against the fake Rasgeth.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/new_agent_screen.dart';

import 'fake_server.dart';

AppController _app({Locale locale = const Locale('it')}) =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )
      ..locale = locale
      ..reduceMotion = true;

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// Real input and output (the fake server's HTTP) takes real time: under a loaded machine a fixed
/// number of rounds is not enough, so wait for what the screen must show, up to [limit].
Future<void> _until(
  WidgetTester tester,
  Finder finder, {
  Duration limit = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(limit);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 3));
}

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    // «Capo cantiere» leads the project Demo.
    server.agentOverrides['a2'] = {'projectId': 'demo'};
  });
  tearDown(() => server.close());

  Future<AppController> onTeam(WidgetTester tester, {Locale locale = const Locale('it')}) async {
    final app = _app(locale: locale);
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    return app;
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('new-agent-next')));
    await _settle(tester, 4);
  }

  testWidgets('a project\'s agent, step by step, with the page\'s API', (tester) async {
    final app = await onTeam(tester);
    await tester.tap(find.byKey(const Key('team-new-agent')));
    await tester.pumpAndSettle();
    expect(find.byType(NewAgentScreen), findsOneWidget);
    expect(find.text('Passo 1 di 8'), findsOneWidget);
    // Nothing chosen: no going on.
    expect(tester.widget<FilledButton>(find.byKey(const Key('new-agent-next'))).onPressed, isNull);
    await tester.tap(find.byKey(const Key('new-kind-agent')));
    await tester.pumpAndSettle();
    await next(tester);
    // The project: Demo has an orchestrator.
    expect(find.text('In quale progetto?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-project-demo')));
    await tester.pumpAndSettle();
    await next(tester);
    // What it does: a ready role, or the person's own words (G42.4).
    await tester.ensureVisible(find.byKey(const Key('new-role-custom')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-role-custom')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('new-agent-own')));
    await tester.enterText(find.byKey(const Key('new-agent-own')), 'scrive i test e li fa passare');
    await tester.pumpAndSettle();
    await next(tester);
    // The name; the face it will get, from the server.
    await tester.enterText(find.byKey(const Key('new-agent-name')), 'Collaudatore');
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester);
    expect(find.byKey(const Key('new-agent-mascot')), findsOneWidget);
    expect(server.previews.last, 'agent Collaudatore a2');
    await next(tester);
    // The model: the families with the way.
    expect(find.text('Che modello usa? (facoltativo)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-agent-model')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('model-anthropic/claude-sonnet-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('model-use')));
    await _settle(tester);
    expect(find.text('Claude Sonnet 5 · Abbonamento · Medio'), findsOneWidget);
    await next(tester);
    // How much it may do alone; then God writes its instructions (the fake God gives no tools).
    await next(tester);
    await _until(tester, find.byKey(const Key('new-tool-fetch')));
    // Tools by hand: the essential ones are not there to switch off.
    expect(find.byKey(const Key('new-tool-read_file')), findsNothing);
    expect(find.byKey(const Key('new-tool-ask_user')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('new-tool-fetch')));
    await tester.tap(find.byKey(const Key('new-tool-fetch')));
    await tester.pumpAndSettle();
    await next(tester);
    // A look at it all.
    expect(find.text('Ecco il nuovo agente'), findsOneWidget);
    expect(find.text('1 spenti'), findsOneWidget);
    expect(find.text('Crea'), findsOneWidget);
    await next(tester);
    // The agent is made through the server, then the screen says so.
    await _until(tester, find.byKey(const Key('new-agent-done')));
    expect(server.newAgents.single, {
      'kind': 'agent',
      'parentId': 'a2',
      'name': 'Collaudatore',
      'projectId': 'demo',
      'role': 'scrive i test e li fa passare',
      'model': {'provider': 'claude-subscription', 'model': 'claude-sonnet-5', 'effort': 'medium'},
      'mode': 'auto',
    });
    expect(server.toolChoices['agent_1'], {'fetch': 'off'});
    expect(find.text('Collaudatore è nella squadra.'), findsOneWidget);
    expect(app.agents.any((a) => a.name == 'Collaudatore'), isTrue);
    // «Change mascot», asked first.
    await tester.tap(find.byKey(const Key('new-agent-mascot-change')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.mascotChanges, ['agent_1']);
    // Its conversation opens; Team has it in the grid.
    await tester.tap(find.byKey(const Key('new-agent-open')));
    await _settle(tester);
    expect(find.byType(ConversationScreen), findsOneWidget);
    expect(
      tester.widget<ConversationScreen>(find.byType(ConversationScreen)).agent?.name,
      'Collaudatore',
    );
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byKey(const Key('agent-agent_1')), findsOneWidget);
    await _done(tester);
  });

  testWidgets('an orchestrator only where there is none; an assistant has no project', (
    tester,
  ) async {
    await onTeam(tester);
    await tester.tap(find.byKey(const Key('team-new-agent')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-kind-orchestrator')));
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.text('Ha già un orchestratore.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('new-project-demo')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.byKey(const Key('new-agent-next'))).onPressed, isNull);
    // Back to the kind: an assistant, five steps, under God.
    await tester.tap(find.byKey(const Key('new-agent-back')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-kind-assistant')));
    await tester.pumpAndSettle();
    await next(tester);
    expect(find.text('Passo 2 di 8'), findsOneWidget);
    await next(tester);
    await tester.enterText(find.byKey(const Key('new-agent-name')), 'Agenda');
    await tester.pumpAndSettle();
    await next(tester);
    // No services added for everyone.
    expect(find.byKey(const Key('new-no-services')), findsOneWidget);
    await next(tester);
    expect(find.text('Lo stesso di God'), findsOneWidget);
    await next(tester);
    await next(tester);
    await _until(tester, find.byKey(const Key('new-tool-fetch')));
    await next(tester);
    await next(tester);
    await _until(tester, find.byKey(const Key('new-agent-done')));
    final made = server.newAgents.single;
    expect(made['kind'], 'assistant');
    expect(made['parentId'], 'a0');
    expect(made['name'], 'Agenda');
    expect(made['mode'], 'auto');
    expect(made['connections'], isEmpty);
    expect(made['role'], startsWith('Tieni in ordine'));
    expect(server.toolChoices, isEmpty);
    await _done(tester);
  });

  testWidgets('in English', (tester) async {
    await onTeam(tester, locale: const Locale('en'));
    expect(find.text('Agents'), findsOneWidget);
    await tester.tap(find.byKey(const Key('team-new-agent')));
    await tester.pumpAndSettle();
    for (final t in [
      'What kind of agent do you need?',
      "A project's agent",
      'Personal assistant',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
    await _done(tester);
  });

  testWidgets('«Change mascot» in an agent\'s sheet too, never God\'s', (tester) async {
    server.created.add({
      'id': 'agent_9',
      'kind': 'assistant',
      'parentId': 'a0',
      'projectId': null,
      'name': 'Posta',
      'mascotSeed': 'Posta',
      'mascot': server.mascots[5].raw,
      'status': 'active',
    });
    await onTeam(tester);
    await tester.longPress(find.byKey(const Key('team-god')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-mascot-change')), findsNothing);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('agent-agent_9')),
      200,
      scrollable: find
          .descendant(of: find.byKey(const Key('team-scroll')), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const Key('agent-agent_9')));
    await _settle(tester);
    await tester.ensureVisible(find.byKey(const Key('agent-mascot-change')));
    await tester.tap(find.byKey(const Key('agent-mascot-change')));
    await tester.pumpAndSettle();
    expect(
      find.text('Dare a Posta una faccia nuova? Quella di adesso non torna più.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.mascotChanges, ['agent_9']);
    expect(find.text('Nuova faccia per Posta.'), findsOneWidget);
    await _done(tester);
  });

  test('kinds the person makes, as the page', () {
    expect(NewKind.values.map((k) => k.name), ['agent', 'orchestrator', 'assistant']);
    expect(AgentKind.values, contains(AgentKind.assistant));
  });
}
