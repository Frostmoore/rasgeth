// «Model» in the agent's sheet (3.8.1): God's, the Chat's and every agent's long press shows its
// model with the way (Subscription / API key, G40.9b) and changes it with the page's own API —
// `PATCH /api/agents/:id` for God and the agents, `PUT /api/chat/settings` for the Chat — or goes
// back to the one above. Against the fake Rasgeth.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/ui/icons.dart';

import 'fake_server.dart';

AppController _app() =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )
      ..locale = const Locale('it')
      ..reduceMotion = true;

Future<void> _pump(WidgetTester tester, AppController app) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 3));
}

String _now(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('agent-model-now'))).data ?? '';

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
  });
  tearDown(() => server.close());

  Future<AppController> connected(WidgetTester tester) async {
    final app = _app();
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    await _pump(tester, app);
    await _settle(tester);
    return app;
  }

  testWidgets('an agent: the way and the effort, saved with PATCH /api/agents/:id', (tester) async {
    final app = await connected(tester);
    await tester.longPress(find.byKey(const Key('agent-a3')));
    await _settle(tester);
    expect(find.text('Modello'), findsOneWidget);
    expect(_now(tester), 'Lo stesso di chi sta sopra');
    await tester.tap(find.byKey(const Key('agent-model')));
    await _settle(tester);
    expect(find.text('Modello di Coder Web'), findsOneWidget);
    expect(find.text('Ora: Lo stesso di chi sta sopra'), findsOneWidget);
    // By provider and way (G42.15): each way its own row, under its heading and what it means.
    expect(find.byKey(const Key('model-group-claude-subscription')), findsOneWidget);
    expect(find.byKey(const Key('model-group-anthropic')), findsOneWidget);
    expect(find.byKey(const Key('model-claude-subscription/claude-sonnet-5')), findsOneWidget);
    expect(find.text('Nei limiti del tuo piano: non paghi a consumo.'), findsOneWidget);
    // The search is always there (3.12.4), the model in use first of all lit.
    expect(find.byKey(const Key('model-search')), findsOneWidget);
    await tester.tap(find.byKey(const Key('model-anthropic/claude-sonnet-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('effort-high')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('model-use')));
    await _settle(tester);
    expect(server.patches.last, {
      'agent': 'a3',
      'model': {'provider': 'anthropic', 'model': 'claude-sonnet-5', 'effort': 'high'},
    });
    expect(find.text('Salvato: i suoi prossimi messaggi lo usano.'), findsOneWidget);
    expect(_now(tester), 'Claude Sonnet 5 · Chiave API · Alto');
    expect(app.agents.firstWhere((a) => a.id == 'a3').model?.provider, 'anthropic');
    // Back to the one above: model null.
    await tester.tap(find.byKey(const Key('agent-model')));
    await _settle(tester);
    expect(find.text('Ora: Claude Sonnet 5 · Chiave API · Alto'), findsOneWidget);
    await tester.tap(find.byKey(const Key('model-inherit')));
    await _settle(tester);
    expect(server.patches.last, {'agent': 'a3', 'model': null});
    expect(_now(tester), 'Lo stesso di chi sta sopra');
    await _done(tester);
  });

  testWidgets('God: its own model, or the default', (tester) async {
    await connected(tester);
    await tester.longPress(find.byKey(const Key('team-god')));
    await _settle(tester);
    expect(_now(tester), 'Il modello predefinito');
    await tester.tap(find.byKey(const Key('agent-model')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('model-anthropic/claude-haiku-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('model-use')));
    await _settle(tester);
    expect(server.patches.last, {
      'agent': 'a0',
      'model': {'provider': 'anthropic', 'model': 'claude-haiku-5', 'effort': 'medium'},
    });
    expect(_now(tester), 'Claude Haiku 5 · Chiave API · Medio');
    await _done(tester);
  });

  testWidgets('the Chat: through its settings, as the page\'s Chat header', (tester) async {
    server.chatModel = {'provider': 'claude-subscription', 'model': 'claude-sonnet-5'};
    final app = await connected(tester);
    expect(app.chatAgentId, 'chat');
    await tester.longPress(find.byKey(const Key('team-chat')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-sheet-chat')), findsOneWidget);
    expect(_now(tester), 'Claude Sonnet 5 · Abbonamento');
    await tester.tap(find.byKey(const Key('agent-model')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('model-inherit')));
    await _settle(tester);
    expect(server.patches.last, {'chat': true, 'model': null});
    expect(server.patches.where((p) => p['agent'] == 'chat'), isEmpty);
    expect(_now(tester), 'Il modello predefinito');
    await _done(tester);
  });

  testWidgets('search by name or id, the headings say how it is paid, the current one is lit', (
    tester,
  ) async {
    server.chatModel = {'provider': 'claude-subscription', 'model': 'claude-sonnet-5'};
    await connected(tester);
    await tester.longPress(find.byKey(const Key('team-chat')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('agent-model')));
    await _settle(tester);
    // Headings: how it is paid first («Abbonamento Claude», «Chiave API Anthropic»).
    expect(find.text('ABBONAMENTO CLAUDE'), findsOneWidget);
    expect(find.text('CHIAVE API ANTHROPIC'), findsOneWidget);
    // The model in use is the lit row (its check), and only that one.
    expect(
      find.descendant(
        of: find.byKey(const Key('model-claude-subscription/claude-sonnet-5')),
        matching: find.byType(RgIcon),
      ),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('model-search')), 'haiku');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('model-anthropic/claude-haiku-5')), findsOneWidget);
    expect(find.byKey(const Key('model-anthropic/claude-sonnet-5')), findsNothing);
    await tester.enterText(find.byKey(const Key('model-search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('model-none')), findsOneWidget);
    await _done(tester);
  });

  test('one picker everywhere: the grouped list is built in one file only', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    bool uses(File f, Pattern p) => f.readAsStringSync().contains(p);
    expect(files.where((f) => uses(f, 'modelGroups(')).map((f) => f.path).toList()..sort(), [
      'lib/api/model_routes.dart',
      'lib/ui/model_sheet.dart',
    ]);
    // Never a native drop-down for a model: every choice goes through showModelPicker.
    expect(files.where((f) => uses(f, 'DropdownButton')).toList(), isEmpty);
    final choosing = files
        .where((f) => !f.path.endsWith('client.dart') && !f.path.endsWith('app_state.dart'))
        .where((f) => uses(f, RegExp(r'\.models\(\)|modelChoices\(')));
    expect(choosing, isNotEmpty);
    for (final f in choosing) {
      expect(uses(f, 'model_sheet.dart'), isTrue, reason: f.path);
    }
  });

  test('a model in words, and the protocol\'s efforts', () {
    expect(efforts, ['low', 'medium', 'high', 'max']);
    expect(const AgentModel(provider: 'a', model: 'b').toJson(), {'provider': 'a', 'model': 'b'});
  });
}
