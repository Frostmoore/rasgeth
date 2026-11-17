// 3.8.8: the menus and the lists the user asked for, against the fake RedGiant (which checks the
// bodies as the real routes do). God's card answers a right click anywhere on it and its click
// shows God's conversations, as every agent's does; a conversation's menu (open, pin, folder,
// archive and back, export) in every list, the Chat's with «Archived (n)»; a project's click
// shows its conversations, its menu archives it (the page's window first) and restores it; the
// bell in the bar replaces the «For you» card, with its count, the critical badge and the quick
// answers.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/ui/conversation_menu.dart';

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
    // A project with its lead (a2, an orchestrator) and an agent (a3).
    server.agentOverrides['a2'] = {'projectId': 'demo'};
    server.agentOverrides['a3'] = {'projectId': 'demo'};
  });
  tearDown(() => server.close());

  const computer = Size(1440, 900);
  const phone = Size(430, 932);

  Future<AppController> start(
    WidgetTester tester, {
    Size size = computer,
    DevicePlatform platform = DevicePlatform.linux,
    bool advanced = false,
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
    if (advanced) app.setAdvanced(true);
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

  Future<void> right(WidgetTester tester, Finder f, {Offset? at}) async {
    await tester.ensureVisible(f);
    await tester.pump();
    if (at != null) {
      await tester.tapAt(tester.getTopLeft(f) + at, buttons: kSecondaryButton);
    } else {
      await tester.tap(f, buttons: kSecondaryButton);
    }
    await _settle(tester, 4);
  }

  Future<void> away(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester, 4);
  }

  group('God and the agents', () {
    testWidgets('computer: a right click anywhere on God\'s card opens its menu', (tester) async {
      await start(tester);
      final card = find.byKey(const Key('desk-god'));
      // Not on the face: on the card's empty right part, and on its name.
      final size = tester.getSize(card);
      await right(tester, card, at: Offset(size.width - 20, size.height / 2));
      expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
      expect(find.byKey(const Key('agent-menu-list')), findsOneWidget);
      expect(find.text('Conversazioni con God'), findsOneWidget);
      // God's rules: no new face.
      expect(find.byKey(const Key('agent-menu-mascot')), findsNothing);
      await away(tester);
      await right(tester, find.text('God').first);
      expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
      await away(tester);
      // The Chat's card too.
      await right(tester, find.byKey(const Key('desk-chat')));
      expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
      await away(tester);
      await done(tester);
    });

    testWidgets('computer: the strip\'s God (other views) and the palette have the menu', (
      tester,
    ) async {
      await start(tester);
      await tap(tester, 'view-activity');
      await right(tester, find.byKey(const Key('strip-god')));
      expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
      await away(tester);
      // A click on the strip's God: its conversations in the panel.
      await tap(tester, 'strip-god');
      expect(find.byKey(const Key('panel-agent-a0')), findsOneWidget);
      // The palette: a right click on an agent and on a conversation.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester, 4);
      await right(tester, find.byKey(const Key('palette-agent-a0')));
      expect(find.byKey(const Key('agent-menu-settings')), findsOneWidget);
      await away(tester);
      await right(tester, find.byKey(const Key('palette-session-s1')));
      expect(find.byKey(const Key('conv-menu-archive')), findsOneWidget);
      // «Open» opens it and closes the palette.
      await tester.tap(find.byKey(const Key('conv-menu-open')));
      await _settle(tester);
      expect(find.byKey(const Key('palette')), findsNothing);
      expect(find.byType(ConversationScreen), findsOneWidget);
      await done(tester);
    });

    testWidgets('computer: a click on God, on an agent: their conversations in the panel', (
      tester,
    ) async {
      await start(tester);
      await tap(tester, 'desk-god');
      expect(find.byKey(const Key('panel-agent-a0')), findsOneWidget);
      expect(find.byKey(const Key('conv-s1')), findsOneWidget);
      expect(find.text('Ieri'), findsOneWidget);
      // Nothing archived yet: no «Archived (n)».
      expect(find.byKey(const Key('conv-archived-toggle')), findsNothing);
      // A row opens its conversation in the panel.
      await tap(tester, 'conv-s1');
      expect(find.byType(ConversationScreen), findsOneWidget);
      // Another agent: its list, empty, and a new conversation from it.
      await tap(tester, 'tile-a3');
      expect(find.byKey(const Key('panel-agent-a3')), findsOneWidget);
      expect(find.text('Ancora nessuna conversazione: iniziane una.'), findsOneWidget);
      final before = server.sessions.length;
      await tap(tester, 'agent-conv-new');
      expect(server.sessions.length, before + 1);
      expect(server.sessions.last['agentId'], 'a3');
      expect(find.byType(ConversationScreen), findsOneWidget);
      await done(tester);
    });

    testWidgets('phone: God\'s card, a tap shows its list, a long press its sheet', (tester) async {
      await start(tester, size: phone, platform: DevicePlatform.android);
      await tester.longPress(find.byKey(const Key('team-god')));
      await _settle(tester);
      expect(find.byKey(const Key('agent-sheet-a0')), findsOneWidget);
      expect(find.byKey(const Key('agent-list')), findsOneWidget);
      await tap(tester, 'agent-list');
      expect(find.byKey(const Key('agent-convs-screen-a0')), findsOneWidget);
      await tap(tester, 'agent-convs-back');
      await _settle(tester);
      expect(find.byKey(const Key('agent-convs-screen-a0')), findsNothing);
      await tap(tester, 'team-god');
      expect(find.byKey(const Key('agent-convs-screen-a0')), findsOneWidget);
      expect(find.byKey(const Key('conv-s1')), findsOneWidget);
      await done(tester);
    });
  });

  group('a conversation\'s menu', () {
    testWidgets('computer: pin, folder, archive and back, export', (tester) async {
      final saved = <String, Uint8List>{};
      conversationSaver = (name, bytes) async {
        saved[name] = bytes;
        return true;
      };
      addTearDown(() => conversationSaver = (_, _) async => false);
      await start(tester);
      await tap(tester, 'desk-god');
      final row = find.byKey(const Key('conv-s1'));
      await right(tester, row);
      for (final k in ['open', 'pin', 'folder', 'archive', 'export']) {
        expect(find.byKey(Key('conv-menu-$k')), findsOneWidget, reason: k);
      }
      // The page has no «Rename» for a conversation.
      expect(find.text('Rinomina'), findsNothing);
      await tester.tap(find.byKey(const Key('conv-menu-pin')));
      await _settle(tester);
      expect(server.sessionPatches.last, {'id': 's1', 'pinned': true});
      expect(find.byKey(const Key('conv-pinned-s1')), findsOneWidget);
      // A new folder, with our window (never a system prompt); the name is trimmed.
      await right(tester, row);
      await tester.tap(find.byKey(const Key('conv-menu-folder')));
      await _settle(tester, 4);
      await tester.tap(find.byKey(const Key('conv-folder-new')));
      await _settle(tester, 4);
      await tester.enterText(find.byKey(const Key('conv-folder-name')), '  Lavoro  ');
      await tester.tap(find.byKey(const Key('dialog-yes')));
      await _settle(tester);
      expect(server.sessionPatches.last, {'id': 's1', 'folder': 'Lavoro'});
      expect(find.text('LAVORO'), findsOneWidget);
      // Out of the folder: `folder: null`.
      await right(tester, row);
      await tester.tap(find.byKey(const Key('conv-menu-folder')));
      await _settle(tester, 4);
      await tester.tap(find.byKey(const Key('conv-folder-out')));
      await _settle(tester);
      expect(server.sessionPatches.last, {'id': 's1', 'folder': null});
      // Export: the server's Markdown, saved where the person says.
      await right(tester, row);
      await tester.tap(find.byKey(const Key('conv-menu-export')));
      await _settle(tester);
      expect(server.exported, ['s1']);
      expect(saved.keys, ['Ieri.md']);
      expect(String.fromCharCodes(saved['Ieri.md']!), startsWith('# Ieri'));
      // Archive: out of the list, under «Archived (1)»; back with «Bring back».
      await right(tester, row);
      await tester.tap(find.byKey(const Key('conv-menu-archive')));
      await _settle(tester);
      expect(server.sessionPatches.last, {'id': 's1', 'archived': true});
      expect(find.byKey(const Key('conv-s1')), findsNothing);
      expect(find.text('Archiviate (1)'), findsOneWidget);
      await tap(tester, 'conv-archived-toggle');
      expect(find.byKey(const Key('conv-s1')), findsOneWidget);
      await right(tester, row);
      expect(find.text('Riporta'), findsOneWidget);
      await tester.tap(find.byKey(const Key('conv-menu-archive')));
      await _settle(tester);
      expect(server.sessionPatches.last, {'id': 's1', 'archived': false});
      expect(find.text('Nessuna conversazione archiviata.'), findsOneWidget);
      await tap(tester, 'conv-archived-toggle');
      expect(find.byKey(const Key('conv-s1')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the fake server refuses what the real one refuses', (tester) async {
      final app = await start(tester);
      expect(await tester.runAsync(() => app.updateSession('s1', folder: '')), isFalse);
      expect(await tester.runAsync(() => app.updateSession('s1', folder: 'x' * 61)), isFalse);
      expect(await tester.runAsync(() => app.updateSession('nope', pinned: true)), isFalse);
      expect(server.sessionPatches, isEmpty);
      await done(tester);
    });

    testWidgets('phone: the Chat\'s list, a long press, «Archived (n)»', (tester) async {
      server.sessions.add({
        'id': 'c1',
        'agentId': 'chat',
        'projectId': null,
        'createdAt': '2026-11-16T09:00:00.000Z',
        'lastAt': '2026-11-16T09:05:00.000Z',
        'title': 'Ricetta del pane',
        'pinned': false,
        'archived': false,
        'folder': null,
        'running': false,
      });
      final app = await start(tester, size: phone, platform: DevicePlatform.android);
      app.setTab(AppTab.chat);
      await _settle(tester);
      expect(find.byKey(const Key('chat-c1')), findsOneWidget);
      await tester.longPress(find.byKey(const Key('chat-c1')));
      await _settle(tester);
      expect(find.byKey(const Key('conv-sheet-c1')), findsOneWidget);
      await tester.tap(find.byKey(const Key('conv-menu-archive')));
      await _settle(tester);
      expect(server.sessionPatches.last, {'id': 'c1', 'archived': true});
      expect(find.byKey(const Key('chat-c1')), findsNothing);
      await tap(tester, 'conv-archived-toggle');
      expect(find.byKey(const Key('chat-c1')), findsOneWidget);
      await done(tester);
    });
  });

  group('projects', () {
    testWidgets('computer: a click shows its conversations, the menu archives and restores', (
      tester,
    ) async {
      server.projectWorking = [
        {'sessionId': 's1', 'agentId': 'a3', 'agentName': 'Coder Web', 'title': 'Il carrello'},
      ];
      server.projectAutomations = [
        {'id': 'au1', 'name': 'Rapporto del lunedì'},
      ];
      final app = await start(tester);
      // The wall's section of the project: a click opens it.
      await tap(tester, 'section-project-demo');
      expect(find.byKey(const Key('proj-overview-demo')), findsOneWidget);
      await tap(tester, 'view-projects');
      await tap(tester, 'project-tile-demo');
      expect(find.byKey(const Key('proj-overview-demo')), findsOneWidget);
      expect(find.byKey(const Key('agent-conv-new')), findsOneWidget);
      await right(tester, find.byKey(const Key('project-tile-demo')));
      expect(find.byKey(const Key('proj-menu-open')), findsOneWidget);
      expect(find.byKey(const Key('proj-menu-agents')), findsOneWidget);
      expect(find.byKey(const Key('proj-menu-restore')), findsNothing);
      await tester.tap(find.byKey(const Key('proj-menu-archive')));
      await _settle(tester);
      // The page's window: who is working, the automations, what happens.
      expect(find.byKey(const Key('proj-archive-window')), findsOneWidget);
      expect(find.text('Archiviare «Demo»?'), findsOneWidget);
      expect(find.byKey(const Key('proj-archive-working')), findsOneWidget);
      expect(find.text('Coder Web · Il carrello'), findsOneWidget);
      expect(find.textContaining('Rapporto del lunedì'), findsOneWidget);
      expect(find.text('Ferma e archivia'), findsOneWidget);
      // Cancel: nothing happens.
      await tester.tap(find.byKey(const Key('dialog-no')));
      await _settle(tester);
      expect(server.projectActs, isEmpty);
      await right(tester, find.byKey(const Key('project-tile-demo')));
      await tester.tap(find.byKey(const Key('proj-menu-archive')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('proj-archive-yes')));
      await _settle(tester);
      expect(server.projectActs, ['archive demo']);
      expect(app.archivedProjects.map((p) => p.id), ['demo']);
      // Read only now: the badge, «Restore», no new conversation.
      expect(find.byKey(const Key('proj-badge')), findsOneWidget);
      expect(find.byKey(const Key('agent-conv-new')), findsNothing);
      expect(find.text('Archiviati (1)'), findsOneWidget);
      await tap(tester, 'projects-archived-toggle');
      expect(find.byKey(const Key('archived-project-demo')), findsOneWidget);
      await right(tester, find.byKey(const Key('archived-project-demo')));
      expect(find.byKey(const Key('proj-menu-restore')), findsOneWidget);
      expect(find.byKey(const Key('proj-menu-archive')), findsNothing);
      await tester.tap(find.byKey(const Key('proj-menu-restore')));
      await _settle(tester);
      expect(server.projectActs, ['archive demo', 'restore demo']);
      expect(app.archivedProjects, isEmpty);
      expect(find.byKey(const Key('project-tile-demo')), findsOneWidget);
      await done(tester);
    });

    testWidgets('phone: a tap shows the project, a long press its sheet', (tester) async {
      final app = await start(
        tester,
        size: phone,
        platform: DevicePlatform.android,
        advanced: true,
      );
      app.setTab(AppTab.projects);
      await _settle(tester);
      await tester.longPress(find.byKey(const Key('project-demo')));
      await _settle(tester);
      expect(find.byKey(const Key('proj-sheet-demo')), findsOneWidget);
      expect(find.byKey(const Key('proj-menu-tasks')), findsOneWidget);
      await tester.tap(find.byKey(const Key('proj-menu-archive')));
      await _settle(tester);
      expect(find.text('Archivia'), findsWidgets);
      await tester.tap(find.byKey(const Key('proj-archive-yes')));
      await _settle(tester);
      expect(server.projectActs, ['archive demo']);
      await tap(tester, 'project-demo');
      expect(find.byKey(const Key('proj-screen-demo')), findsOneWidget);
      expect(find.byKey(const Key('proj-archived-note')), findsOneWidget);
      await tap(tester, 'proj-restore');
      expect(server.projectActs, ['archive demo', 'restore demo']);
      await done(tester);
    });
  });

  group('the bell', () {
    testWidgets('the count, the critical badge, open and close, a quick answer', (tester) async {
      await start(tester);
      // «For you» left the wall.
      expect(find.byKey(const Key('desk-foryou')), findsNothing);
      // r2 is truly dangerous: the solid badge.
      expect(find.byKey(const Key('desk-bell-badge-critical')), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(const Key('desk-bell')), matching: find.text('2')),
        findsOneWidget,
      );
      await tap(tester, 'desk-bell');
      expect(find.byKey(const Key('bell-panel')), findsOneWidget);
      expect(find.text('PERMESSI (2)'), findsOneWidget);
      // The critical one first, without a quick yes.
      expect(find.byKey(const Key('bell-look-r2')), findsOneWidget);
      expect(find.byKey(const Key('bell-allow-r2')), findsNothing);
      expect(find.byKey(const Key('bell-allow-r1')), findsOneWidget);
      // Esc closes; the status bar opens the same.
      await away(tester);
      expect(find.byKey(const Key('bell-panel')), findsNothing);
      await tap(tester, 'status-foryou');
      expect(find.byKey(const Key('bell-panel')), findsOneWidget);
      // A quick yes, through the app's route; the count follows.
      await tap(tester, 'bell-allow-r1');
      expect(server.answered['r1'], 'allow');
      expect(find.byKey(const Key('bell-request-r1')), findsNothing);
      // A click outside closes it.
      await tester.tapAt(const Offset(200, 600));
      await _settle(tester, 4);
      expect(find.byKey(const Key('bell-panel')), findsNothing);
      expect(
        find.descendant(of: find.byKey(const Key('desk-bell')), matching: find.text('1')),
        findsOneWidget,
      );
      // «See all»: the full list in the panel.
      await tap(tester, 'desk-bell');
      await tap(tester, 'bell-see-all');
      expect(find.byKey(const Key('bell-panel')), findsNothing);
      expect(find.byKey(const Key('desk-panel')), findsOneWidget);
      await done(tester);
    });

    testWidgets('an ordinary request: the plain badge; the shortcut is in the list', (
      tester,
    ) async {
      server.permissions.removeWhere((p) => p['requestId'] == 'r2');
      await start(tester);
      expect(find.byKey(const Key('desk-bell-badge')), findsOneWidget);
      expect(find.byKey(const Key('desk-bell-badge-critical')), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester, 4);
      expect(find.byKey(const Key('bell-panel')), findsOneWidget);
      await tap(tester, 'bell-deny-r1');
      expect(server.answered['r1'], 'deny');
      await away(tester);
      // Ctrl+/: the shortcuts, the bell's among them.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.slash);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester, 4);
      expect(find.text('Richieste e notifiche'), findsOneWidget);
      expect(find.text('Ctrl+Maiusc+D'), findsOneWidget);
      await done(tester);
    });
  });
}
