// A project's agent limit in the app (2026-11-18, parity with the page's `AgentLimitControl`):
// the project's menu says «Agenti al massimo: N» and opens our window with the slider (0 to 10,
// saved when the finger lets go); the project's view has the same slider by its team, and over
// the limit says that nobody is removed; the server's refusal is said in the person's words.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/client.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/ui/project_agents.dart';

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
    server.agentOverrides['a2'] = {'projectId': 'demo'};
    server.agentOverrides['a3'] = {'projectId': 'demo'};
  });
  tearDown(() => server.close());

  const phone = Size(430, 932);

  Future<AppController> start(WidgetTester tester) async {
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
    app.setAdvanced(true);
    tester.view.physicalSize = phone;
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

  Slider slider(WidgetTester tester) =>
      tester.widget<Slider>(find.byKey(const Key('agent-limit-slider-demo')).first);

  test('the project says its limit and its count; old servers: the default', () {
    final p = Project.fromJson({'id': 'x', 'name': 'X', 'maxAgents': 0, 'agents': 4});
    expect([p.maxAgents, p.agents], [0, 4]);
    final old = Project.fromJson({'id': 'x', 'name': 'X'});
    expect([old.maxAgents, old.agents], [3, null]);
    expect(Project.projectAgentsMax, 10);
  });

  test('the refusal in the person\'s words', () async {
    final l = await AppLocalizations.delegate.load(const Locale('it'));
    const e = ApiException(
      409,
      'The project "Shop" can have at most 3 agents…',
      code: 'agent_limit',
      vars: {'project': 'Shop', 'max': '3', 'count': '3'},
    );
    expect(
      apiErrorText(l, e),
      'Il progetto «Shop» può avere al massimo 3 agenti oltre all\'orchestratore: ne ha 3. '
      'Alza il limite dal menu del progetto o rimuovine uno.',
    );
    expect(apiErrorText(l, const ApiException(400, 'other')), 'other');
  });

  testWidgets('the project menu opens the slider; letting go saves it once', (tester) async {
    final app = await start(tester);
    app.setTab(AppTab.projects);
    await _settle(tester);
    await tester.longPress(find.byKey(const Key('project-demo')));
    await _settle(tester);
    expect(find.text('Agenti al massimo: 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('proj-menu-limit')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-limit-window')), findsOneWidget);
    expect(find.text('Agenti al massimo in questo progetto'), findsOneWidget);
    expect(find.textContaining('Ora: 2 agenti.'), findsOneWidget);
    final s = slider(tester);
    expect([s.min, s.max, s.divisions, s.value], [0, 10, 10, 3]);
    // Moving saves nothing; letting go saves once.
    s.onChanged!(1);
    s.onChanged!(0);
    await tester.pump();
    expect(server.maxAgentPuts, isEmpty);
    expect(tester.widget<Text>(find.byKey(const Key('agent-limit-value-demo'))).data, '0');
    slider(tester).onChangeEnd!(0);
    await _settle(tester);
    expect(server.maxAgentPuts, [0]);
    expect(app.projects.firstWhere((p) => p.id == 'demo').maxAgents, 0);
    expect(find.byKey(const Key('agent-limit-saved-demo')), findsOneWidget);
    // Over the limit now (2 agents, at most 0): nobody is removed, says the line.
    expect(find.byKey(const Key('agent-limit-over-demo')), findsOneWidget);
    expect(
      find.text(
        'Ne ha 2 agenti, più di 0: nessuno viene rimosso, ma non se ne creano di nuovi finché la '
        'squadra non scende sotto il limite.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('agent-limit-close')));
    await _settle(tester);
    await tester.longPress(find.byKey(const Key('project-demo')));
    await _settle(tester);
    expect(find.text('Agenti al massimo: Solo orchestratore'), findsOneWidget);
    await done(tester);
  });

  testWidgets('the project view has the same slider by its team', (tester) async {
    server.demoMaxAgents = 5;
    final app = await start(tester);
    app.setTab(AppTab.projects);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('project-demo')));
    await _settle(tester);
    final tile = find.byKey(const Key('agent-limit-demo'));
    await tester.scrollUntilVisible(tile, 200, scrollable: find.byType(Scrollable).last);
    expect(tile, findsOneWidget);
    expect(slider(tester).value, 5);
    expect(find.byKey(const Key('agent-limit-over-demo')), findsNothing);
    await done(tester);
  });
}
