// «Instructions» in the agent's sheet (3.8.1), as the page's PromptEditor and PromptRefiner:
// the text in use (its own, or the built-in one as a starting point), Save, «Restore the built-in
// ones», «Improve the instructions» with its estimate, and the line saying they apply to new
// conversations; God's and every agent's through `/api/agents/:id/prompt`, the Chat's through
// `/api/chat/prompt`. Against the fake RedGiant.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/instructions_screen.dart';

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
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 3));
}

String _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byKey(const Key('prompt-text'))).controller!.text;

void main() {
  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
  });
  tearDown(() => server.close());

  Future<AppController> onTeam(WidgetTester tester, {Locale locale = const Locale('it')}) async {
    final app = _app(locale: locale);
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
    return app;
  }

  Future<void> open(WidgetTester tester, Key card) async {
    await tester.longPress(find.byKey(card));
    await _settle(tester);
    await tester.ensureVisible(find.byKey(const Key('agent-instructions')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('agent-instructions')));
    await _settle(tester);
    expect(find.byType(InstructionsScreen), findsOneWidget);
  }

  testWidgets('an agent: the built-in ones as a start, saved as its own, then back', (
    tester,
  ) async {
    await onTeam(tester);
    await open(tester, const Key('agent-a3'));
    expect(find.text('Istruzioni di Coder Web'), findsOneWidget);
    expect(find.text('Istruzioni predefinite'), findsOneWidget);
    expect(_field(tester), 'You are a3. Built-in instructions.');
    // It says when they apply (a conversation keeps the ones it started with).
    expect(
      find.textContaining('valgono per le conversazioni nuove: quelle già aperte tengono le loro'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(find.byKey(const Key('prompt-save'))).onPressed, isNull);
    expect(find.byKey(const Key('prompt-reset')), findsNothing);
    await tester.enterText(find.byKey(const Key('prompt-text')), 'You are a3. Write tests first.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prompt-save')));
    await _settle(tester);
    expect(server.promptPuts.last, {'who': 'a3', 'text': 'You are a3. Write tests first.'});
    expect(find.text('Istruzioni tue'), findsOneWidget);
    expect(find.text('Salvato.'), findsOneWidget);
    // Back to the built-in ones, asked first.
    await tester.ensureVisible(find.byKey(const Key('prompt-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prompt-reset')));
    await tester.pumpAndSettle();
    expect(
      find.text('Tornare alle istruzioni predefinite? Il tuo testo andrà perso.'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester);
    expect(server.promptPuts.last, {'who': 'a3', 'text': null});
    expect(find.text('Istruzioni predefinite'), findsOneWidget);
    expect(_field(tester), 'You are a3. Built-in instructions.');
    await _done(tester);
  });

  testWidgets('improve the instructions: the estimate, the new text in the field, then save', (
    tester,
  ) async {
    await onTeam(tester);
    await open(tester, const Key('team-god'));
    expect(find.text('Istruzioni di God'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('refine-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refine-open')));
    await _settle(tester);
    expect(find.text('Stima: circa 4.200 token, meno di un centesimo.'), findsOneWidget);
    expect(server.refines.last['target'], {'agentId': 'a0'});
    await tester.ensureVisible(find.byKey(const Key('refine-wish')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('refine-wish')), 'più breve');
    await tester.ensureVisible(find.byKey(const Key('refine-go')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refine-go')));
    await _settle(tester);
    expect(server.refines.last['request'], 'più breve');
    expect(find.text('Added: answer briefly.'), findsOneWidget);
    expect(
      find.text(
        'Speso: circa 4.300 token, nessuna spesa in denaro (modello locale o abbonamento).',
      ),
      findsOneWidget,
    );
    // Nothing saved until the person saves.
    expect(server.promptPuts, isEmpty);
    await tester.ensureVisible(find.byKey(const Key('refine-use')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refine-use')));
    await tester.pumpAndSettle();
    expect(_field(tester), 'You are a0. Built-in instructions.\nAnswer briefly.');
    expect(find.text('La versione nuova è nel campo: salva per tenerla.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('prompt-save')));
    await _settle(tester);
    expect(server.promptPuts.single['who'], 'a0');
    await _done(tester);
  });

  testWidgets('a refusal says why, in words', (tester) async {
    server.refineFails = 'budget';
    await onTeam(tester);
    await open(tester, const Key('agent-a3'));
    await tester.ensureVisible(find.byKey(const Key('refine-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refine-open')));
    await _settle(tester);
    await tester.ensureVisible(find.byKey(const Key('refine-go')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refine-go')));
    await _settle(tester);
    expect(find.text('Il budget è finito: alzalo in Impostazioni, Budget.'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('the Chat: «the Chat\'s instructions», through its own address', (tester) async {
    final app = await onTeam(tester);
    expect(app.chatAgentId, 'chat');
    await open(tester, const Key('team-chat'));
    expect(find.text('Istruzioni della Chat'), findsWidgets);
    await tester.enterText(find.byKey(const Key('prompt-text')), 'Be kind.');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prompt-save')));
    await _settle(tester);
    expect(server.promptPuts.single, {'who': 'chat', 'text': 'Be kind.'});
    expect(server.requests, contains('PUT /api/chat/prompt'));
    await tester.ensureVisible(find.byKey(const Key('refine-open')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('refine-open')));
    await _settle(tester);
    expect(server.refines.last['target'], {'chat': true});
    await _done(tester);
  });

  testWidgets('in English', (tester) async {
    await onTeam(tester, locale: const Locale('en'));
    await open(tester, const Key('agent-a3'));
    expect(find.text('Instructions of Coder Web'), findsOneWidget);
    expect(find.text('Built-in instructions'), findsOneWidget);
    expect(find.textContaining('New instructions apply to new conversations'), findsOneWidget);
    expect(find.text('Improve the instructions'), findsOneWidget);
    await _done(tester);
  });

  test('cost in words', () {
    expect(const RefineCost(tokens: 10, usd: null).tokens, 10);
  });
}
