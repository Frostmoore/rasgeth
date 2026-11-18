// Proposal A's interface (G40.9): Team with favourites, the project filter and the long press
// (what the agent is doing, «Stop», «Open the task»); For you as a stack of cards, ordinary
// requests answered by a swipe, critical ones first and never swiped; new Chat conversations
// named by their first message unless the server named them.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/inbox_screen.dart';

AppController _app({MemoryAppPrefs? prefs}) =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: prefs ?? MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )
      ..locale = const Locale('it')
      ..reduceMotion = true;

Future<void> _pump(WidgetTester tester, AppController app) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

const _god = Agent(id: 'god', kind: AgentKind.god, name: 'God', active: true);
const _coder = Agent(
  id: 'coder',
  kind: AgentKind.orchestrator,
  name: 'Coder Web',
  active: true,
  projectId: 'demo',
  role: 'Builds the web front-end',
);
const _research = Agent(id: 'res', kind: AgentKind.agent, name: 'Ricercatore', active: true);

AppController _team({MemoryAppPrefs? prefs}) {
  final app = _app(prefs: prefs)
    ..agents = [_research, _coder, _god]
    ..projects = const [Project(id: 'demo', name: 'Demo'), Project(id: 'site', name: 'Sito')];
  app.live.setSessions(const [
    SessionRow(
      id: 's9',
      agentId: 'coder',
      projectId: 'demo',
      createdAt: '2026-11-15T09:00:00.000Z',
      lastAt: '2026-11-15T09:30:00.000Z',
      title: 'Export to CSV',
      running: true,
      task: 'Add the --json flag',
    ),
  ]);
  return app;
}

List<String> _names(WidgetTester tester) => [
  for (final e in find.byKey(const Key('team-grid')).evaluate())
    for (final t
        in find
            .descendant(of: find.byWidget(e.widget), matching: find.byType(Text))
            .evaluate()
            .map((x) => (x.widget as Text).data ?? ''))
      if (['God', 'Coder Web', 'Ricercatore'].contains(t)) t,
];

Map<String, dynamic> _req(String id, {bool critical = false, String at = '10:00'}) => {
  'requestId': id,
  'agentId': 'god',
  'agentName': 'God',
  'projectId': null,
  'tool': 'run_command',
  'input': {'command': critical ? 'rm -rf /srv' : 'npm install $id'},
  'reasons': [critical ? 'deletes for good' : 'installs packages'],
  'danger': critical ? ['critical-delete'] : <String>[],
  if (critical)
    'critical': [
      {'id': 'critical-delete', 'action': 'delete-disk', 'target': '/srv'},
    ],
  'createdAt': '2026-11-15T$at:00.000Z',
};

void main() {
  group('Team', () {
    testWidgets(
      'God on its card, then the agents by name; a project shows those that worked in it',
      (tester) async {
        final app = _team();
        await _pump(tester, app);
        expect(
          find.descendant(of: find.byKey(const Key('team-god')), matching: find.text('God')),
          findsOneWidget,
        );
        expect(_names(tester), ['Coder Web', 'Ricercatore']);
        await tester.tap(find.byKey(const Key('team-filter-demo')));
        await tester.pumpAndSettle();
        expect(_names(tester), ['Coder Web']);
        // The filters scroll sideways.
        await tester.scrollUntilVisible(
          find.byKey(const Key('team-filter-site')),
          80,
          scrollable: find.descendant(
            of: find.byKey(const Key('team-filters')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.ensureVisible(find.byKey(const Key('team-filter-site')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('team-filter-site')));
        await tester.pumpAndSettle();
        expect(find.text('Nessun agente ha lavorato in questo progetto.'), findsOneWidget);
        app.setTeamFilter(TeamFilter.all);
        await tester.pumpAndSettle();
        expect(_names(tester), hasLength(2));
      },
    );

    testWidgets('a long press: what it is doing, Stop, Open the task, the favourite', (
      tester,
    ) async {
      final prefs = MemoryAppPrefs();
      final app = _team(prefs: prefs);
      await _pump(tester, app);
      await tester.longPress(find.byKey(const Key('agent-coder')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('agent-sheet-coder')), findsOneWidget);
      expect(find.text('Cosa sta facendo'), findsOneWidget);
      expect(find.text('Export to CSV'), findsOneWidget);
      expect(find.text('Compito: Add the --json flag'), findsOneWidget);
      expect(find.text('Builds the web front-end'), findsOneWidget);

      await tester.tap(find.byKey(const Key('agent-stop')));
      await tester.pumpAndSettle();
      expect(find.text('Interrotto: Coder Web'), findsOneWidget);

      // The favourite: first in the grid, with its star, kept for this Rasgeth.
      await tester.tap(find.byKey(const Key('agent-favourite')));
      await tester.pumpAndSettle();
      expect(app.isFavourite('coder'), isTrue);
      expect(prefs.values['favourites:-'], 'coder');

      await tester.tap(find.byKey(const Key('agent-open-task')));
      await tester.pumpAndSettle();
      expect(find.byType(ConversationScreen), findsOneWidget);
      expect(tester.widget<ConversationScreen>(find.byType(ConversationScreen)).sessionId, 's9');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_names(tester), ['Coder Web', 'Ricercatore']);
      await tester.tap(find.byKey(const Key('team-filter-favourites')));
      await tester.pumpAndSettle();
      expect(_names(tester), ['Coder Web']);
    });

    testWidgets('an idle agent: no Stop, no task; favourites filter empty says how', (
      tester,
    ) async {
      final app = _team();
      await _pump(tester, app);
      await tester.longPress(find.byKey(const Key('agent-res')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('agent-sheet-res')),
          matching: find.text('Ora è fermo.'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('agent-stop')), findsNothing);
      expect(find.byKey(const Key('agent-open-task')), findsNothing);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('team-filter-favourites')));
      await tester.pumpAndSettle();
      expect(
        find.text('Nessun preferito: tieni premuto un agente per aggiungerlo.'),
        findsOneWidget,
      );
    });
  });

  group('For you', () {
    test('critical requests first, then the oldest; «Later» at the bottom', () {
      final r = [
        PermissionRequest.fromJson(_req('a', at: '10:00')),
        PermissionRequest.fromJson(_req('b', at: '09:00')),
        PermissionRequest.fromJson(_req('c', critical: true, at: '11:00')),
      ];
      expect(stackOrder(r, []).map((x) => x.requestId), ['c', 'b', 'a']);
      expect(stackOrder(r, ['c']).map((x) => x.requestId), ['b', 'a', 'c']);
    });

    testWidgets('a stack: critical on top and never swiped, ordinary ones answered by a swipe', (
      tester,
    ) async {
      // With semantics on, as with a screen reader (a card leaving must not break its tree).
      final semantics = tester.ensureSemantics();
      final app = _app();
      app.live
        ..apply({'type': 'permission.request', 'request': _req('r1')})
        ..apply({'type': 'permission.request', 'request': _req('r2', critical: true)})
        ..apply({'type': 'permission.request', 'request': _req('r3', at: '10:05')});
      await _pump(tester, app);
      await tester.tap(find.byKey(const Key('tab-inbox')));
      await tester.pumpAndSettle();
      expect(find.text('1 di 3'), findsOneWidget);
      // The critical one on top: no swipe, its hint; a tap opens its screen.
      expect(find.byKey(const Key('swipe-r2')), findsNothing);
      expect(
        find.text('Davvero pericolosa: non si scorre, si guarda a schermo intero.'),
        findsOneWidget,
      );
      await tester.drag(find.byKey(const Key('request-r2')), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(app.live.approvals.map((r) => r.requestId), contains('r2'));
      await tester.tap(find.text('rm -rf /srv'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('critical-screen')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      // Later: the next one comes up.
      await tester.tap(find.byKey(const Key('inbox-later')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('swipe-r1')), findsOneWidget);
      expect(find.text('Scorri a destra per dire sì, a sinistra per dire no.'), findsOneWidget);

      // A short drag springs back; past the threshold right is yes.
      await tester.drag(find.byKey(const Key('swipe-r1')), const Offset(40, 0));
      await tester.pumpAndSettle();
      expect(app.live.approvals.map((r) => r.requestId), contains('r1'));
      await tester.drag(find.byKey(const Key('swipe-r1')), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(app.live.approvals.map((r) => r.requestId), isNot(contains('r1')));
      expect(find.text('Sì a God'), findsOneWidget);

      // Left is no.
      await tester.drag(find.byKey(const Key('swipe-r3')), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(app.live.approvals.map((r) => r.requestId), ['r2']);
      expect(find.text('No a God'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('Chat titles', () {
    test('from the first line of the first message, cut at a word', () {
      expect(AppController.titleFrom('  Ciao!\nCome stai?'), 'Ciao!');
      expect(
        AppController.titleFrom(
          'Mi prepari una lista della spesa per una cena di sei persone con un dolce al cioccolato?',
        ),
        'Mi prepari una lista della spesa per una cena di sei…',
      );
      expect(AppController.titleFrom('a   b\tc'), 'a b c');
    });
  });
}
