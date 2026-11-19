// G38.7: every setting of an agent from the app. A right click on a computer opens the context
// menu (quick actions and «Agent settings…»), a long press on a phone the sheet with the same; the
// settings are the page's Settings › Agents tabs, saved through the same routes against the fake
// Rasgeth, which refuses as the real server does. God and the Chat keep their rules.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

import 'fake_server.dart';
import 'helpers.dart';

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
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    required Size size,
    DevicePlatform platform = DevicePlatform.linux,
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

  Future<void> tap(WidgetTester tester, String key, [int rounds = 8]) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.tap(f);
    await _settle(tester, rounds);
  }

  Future<void> group(WidgetTester tester, String name) => tap(tester, 'agent-group-$name');

  String note(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(const Key('agent-settings-note')),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data)
      .join();

  testWidgets('computer: right click on a tile, the menu, the settings panel', (tester) async {
    await start(tester, size: const Size(1440, 900));
    await tester.tap(find.byKey(const Key('tile-a3')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    for (final k in ['open', 'fresh', 'model', 'instructions', 'mascot', 'favourite', 'settings']) {
      expect(find.byKey(Key('agent-menu-$k')), findsOneWidget, reason: k);
    }
    expect(find.text("Impostazioni dell'agente…"), findsOneWidget);
    await tester.tap(find.byKey(const Key('agent-menu-settings')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-settings-panel')), findsOneWidget);
    expect(find.text('Impostazioni di Coder Web'), findsOneWidget);
    // Every group of the page's window.
    for (final g in ['general', 'work', 'memory', 'limits', 'tools', 'knowledge']) {
      expect(find.byKey(Key('agent-group-$g')), findsOneWidget, reason: g);
    }
    await tap(tester, 'agent-settings-close');
    expect(find.byKey(const Key('agent-settings-panel')), findsNothing);
    // The menu's favourite, straight away.
    await tester.tap(find.byKey(const Key('tile-a3')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tester.tap(find.byKey(const Key('agent-menu-favourite')));
    await _settle(tester, 4);
    await done(tester);
  });

  testWidgets('computer: God and the Chat on the wall have the menu too', (tester) async {
    final app = await start(tester, size: const Size(1440, 900));
    final godFace = find.descendant(
      of: find.byKey(const Key('desk-god')),
      matching: find.byType(InkWell),
    );
    await tester.tap(godFace.first, buttons: kSecondaryButton);
    await _settle(tester, 4);
    // God's face is drawn by hand: no «Change mascot».
    expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
    expect(find.byKey(const Key('agent-menu-mascot')), findsNothing);
    await tester.tapAt(const Offset(5, 890));
    await _settle(tester, 4);
    expect(app.chatAgentId, 'chat');
    await tester.tap(find.byKey(const Key('desk-chat')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
    await done(tester);
  });

  testWidgets('phone: long press, the sheet, the whole screen; general saved', (tester) async {
    final app = await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
    await bringToMiddle(tester, find.byKey(const Key('agent-a3')));
    await tester.longPress(find.byKey(const Key('agent-a3')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-sheet-a3')), findsOneWidget);
    await tap(tester, 'agent-settings');
    expect(find.byKey(const Key('agent-settings-screen')), findsOneWidget);
    // Name and job: PATCH /api/agents/:id, the team follows.
    await tester.enterText(find.byKey(const Key('as-name')), '  Coder Front  ');
    await tester.enterText(find.byKey(const Key('as-role')), 'Scrive il sito');
    await tester.pump();
    await tap(tester, 'as-save-general');
    expect(server.patches.last, {'agent': 'a3', 'name': 'Coder Front', 'role': 'Scrive il sito'});
    expect(app.agents.firstWhere((a) => a.id == 'a3').name, 'Coder Front');
    expect(note(tester), 'Salvato.');
    // An empty name never leaves.
    final before = server.patches.length;
    await tester.enterText(find.byKey(const Key('as-name')), '   ');
    await tester.pump();
    await tap(tester, 'as-save-general');
    expect(server.patches.length, before);
    expect(note(tester), 'Serve un nome.');
    // Its projects: a chip each, saved at once.
    await tap(tester, 'as-project-demo');
    expect(server.patches.last, {
      'agent': 'a3',
      'projects': ['demo'],
    });
    // A new face, confirmed in our own dialog.
    await tap(tester, 'as-mascot');
    await tap(tester, 'dialog-yes');
    expect(server.mascotChanges, ['a3']);
    // Stop, for good, confirmed.
    await tap(tester, 'as-stop');
    expect(find.byKey(const Key('dialog-yes')), findsOneWidget);
    await tap(tester, 'dialog-yes');
    expect(server.stops, ['a3']);
    expect(app.agents.firstWhere((a) => a.id == 'a3').active, isFalse);
    expect(find.byKey(const Key('agent-settings-stopped')), findsOneWidget);
    await done(tester);
  });

  testWidgets('phone: the conversation\'s header has the sheet too', (tester) async {
    await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
    // 3.8.8: a tap shows the agent's conversations; a new one opens from there.
    await tap(tester, 'agent-a3');
    expect(find.byKey(const Key('agent-convs-screen-a3')), findsOneWidget);
    await tap(tester, 'agent-conv-new');
    expect(find.byKey(const Key('conversation-agent')), findsOneWidget);
    await tester.longPress(find.byKey(const Key('conversation-agent')));
    await _settle(tester);
    expect(find.byKey(const Key('agent-sheet-a3')), findsOneWidget);
    await tap(tester, 'agent-settings');
    expect(find.byKey(const Key('agent-settings-screen')), findsOneWidget);
    await done(tester);
  });

  testWidgets('a refusal of the server is shown in its own words', (tester) async {
    await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
    await tester.longPress(find.byKey(const Key('agent-a2')));
    await _settle(tester);
    await tap(tester, 'agent-settings');
    // An orchestrator has no project chips (the server would refuse them).
    expect(find.byKey(const Key('as-project-demo')), findsNothing);
    await group(tester, 'limits');
    await tester.enterText(find.byKey(const Key('as-limit')), '-3');
    await tester.pump();
    await tap(tester, 'as-save-limit');
    expect(note(tester), 'Scrivi un importo maggiore di zero.');
    expect(server.budgetPuts, isEmpty);
    await group(tester, 'tools');
    expect(find.byKey(const Key('as-tool-bash-locked')), findsOneWidget);
    expect(find.byKey(const Key('as-tool-bash-off')), findsNothing);
    await done(tester);
  });

  testWidgets('model and way, memory, spending, tools, knowledge: each saved', (tester) async {
    final app = await start(tester, size: const Size(1440, 900));
    final a = app.agents.firstWhere((x) => x.id == 'a4');
    await tester.tap(find.byKey(const Key('tile-a4')), buttons: kSecondaryButton);
    await _settle(tester, 4);
    await tester.tap(find.byKey(const Key('agent-menu-settings')));
    await _settle(tester);
    // Mode.
    await group(tester, 'work');
    expect(find.byKey(const Key('agent-model')), findsOneWidget);
    await tap(tester, 'as-mode-plan');
    expect(server.patches.last, {'agent': 'a4', 'mode': 'plan'});
    expect(app.agents.firstWhere((x) => x.id == 'a4').mode, 'plan');
    // Memory: its notes, the summaries (the server's defaults shown), back to the defaults.
    await group(tester, 'memory');
    expect(
      find.text('Predefinito per il modello di questo agente: al 80%, tenendo il 12%.'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('as-notes-self-text')), 'Rispondi in breve');
    await tester.pump();
    await tap(tester, 'as-save-notes-self');
    expect(server.notes['self:a4'], 'Rispondi in breve');
    await tap(tester, 'as-save-compact');
    expect(server.patches.last, {
      'agent': 'a4',
      'compaction': {'at': .8, 'keep': .12},
    });
    await tap(tester, 'as-compact-reset');
    expect(server.patches.last, {'agent': 'a4', 'compaction': <String, Object?>{}});
    // Spending: a limit, then none.
    await group(tester, 'limits');
    await tester.enterText(find.byKey(const Key('as-limit')), '7,5');
    await tester.pump();
    await tap(tester, 'as-save-limit');
    expect(server.budgetPuts.last, {'scope': 'agent', 'id': 'a4', 'usd': 7.5});
    expect(find.text(r'$1.25'), findsOneWidget);
    await tap(tester, 'as-limit-remove');
    expect(server.budgetPuts.last, {'scope': 'agent', 'id': 'a4'});
    // Tools: one off for it, the edit rule; the essential ones locked.
    await group(tester, 'tools');
    expect(find.byKey(const Key('as-tool-read_file-locked')), findsOneWidget);
    await tap(tester, 'as-tool-grep-off');
    expect(server.toolChoices['a4'], {'grep': 'off'});
    await tap(tester, 'as-tool-grep-default');
    expect(server.toolChoices['a4'], {'grep': 'default'});
    await tap(tester, 'as-edit-propose');
    expect((server.editorSettings['agents'] as Map)['a4'], 'propose');
    // Knowledge: an exception for this agent.
    await group(tester, 'knowledge');
    await tap(tester, 'as-kb-contratti-on');
    expect(server.kbChoices['a4'], {'contratti': 'on'});
    expect(a.id, 'a4');
    await done(tester);
  });

  testWidgets('God and the Chat keep their rules', (tester) async {
    final app = await start(tester, size: const Size(430, 932), platform: DevicePlatform.android);
    await tester.longPress(find.byKey(const Key('team-god')));
    await _settle(tester);
    await tap(tester, 'agent-settings');
    // God: no new face, never stopped; its model's own words.
    expect(find.byKey(const Key('as-mascot')), findsNothing);
    expect(find.byKey(const Key('as-stop')), findsNothing);
    await group(tester, 'work');
    expect(find.textContaining('Il modello che usa God'), findsOneWidget);
    await tap(tester, 'agent-settings-back');
    // The Chat: never stopped; its model through its settings; its instructions are the Chat's.
    expect(app.chatAgentId, 'chat');
    await tester.longPress(find.byKey(const Key('team-chat')));
    await _settle(tester);
    await tap(tester, 'agent-settings');
    expect(find.text('La Chat di ogni giorno'), findsOneWidget);
    expect(find.byKey(const Key('as-stop')), findsNothing);
    await tester.enterText(find.byKey(const Key('as-name')), 'Chat di casa');
    await tester.pump();
    await tap(tester, 'as-save-general');
    expect(server.patches.last, {'agent': 'chat', 'name': 'Chat di casa'});
    await group(tester, 'work');
    expect(find.text('Istruzioni della Chat'), findsOneWidget);
    await tap(tester, 'agent-model');
    await tap(tester, 'model-inherit');
    expect(server.patches.last, {'chat': true, 'model': null});
    await done(tester);
  });
}
