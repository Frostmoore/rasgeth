// G42.3: group work against the fake server (which answers as app.ts, rooms.ts and ws.ts do):
// the Chat with its folders, «Earlier chats» and «Groups»; a new group; a group chat with its
// members, «Add an agent», «@» to call one, the answer coming with `room.changed`, a member taken
// out; an old everyday chat read, continued (the answer as server-sent events), moved to a folder,
// gone on as a group and deleted; a project's board with a new thread, a reply, resolve, block and
// reopen, a search; the inspector of a project.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/groups.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/project_board_screen.dart';
import 'package:rgcompanion/screens/daily_chat_screen.dart';
import 'package:rgcompanion/screens/room_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late FakeRedGiant server;
  late AppController app;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.permissions.clear();
  });
  tearDown(() => server.close());

  Future<void> start(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
    )..locale = const Locale('it');
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await _settle(tester);
  }

  void push(WidgetTester tester, Widget screen) => tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<void>(builder: (_) => screen))
      .ignore();

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  testWidgets('a group chat: members, @ to call one, the answer, add and take out', (tester) async {
    server.roomList.add({
      'id': 'room_1',
      'title': 'Rilascio',
      'members': [
        {'agentId': 'a0', 'sessionId': 'r0', 'costUsd': 0.12, 'context': 0.31},
        {'agentId': 'a3', 'sessionId': 'r3'},
      ],
      'createdAt': '2026-11-15T10:00:00.000Z',
      'lastAt': null,
      'answering': <String>[],
    });
    await start(tester);
    push(tester, const RoomScreen(roomId: 'room_1'));
    await _settle(tester);
    expect(find.text('Rilascio'), findsOneWidget);
    expect(find.byKey(const Key('room-member-a0')), findsOneWidget);
    expect(find.textContaining('risponde per primo', findRichText: true), findsOneWidget);
    expect(find.textContaining(r'$0.12 · 31%', findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('room-empty')), findsOneWidget);

    // «@» then the start of a name: the members it may be.
    await tester.enterText(find.byKey(const Key('room-text')), 'Allora @Cod');
    await tester.pump();
    expect(find.byKey(const Key('mention-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mention-Coder Web')));
    await tester.pump();
    expect(find.text('Allora @Coder Web '), findsOneWidget);
    await tester.enterText(find.byKey(const Key('room-text')), 'Allora @Coder Web come va?');
    await tester.tap(find.byKey(const Key('room-send')));
    await _settle(tester, 8);
    expect(server.roomPosts.single['text'], 'Allora @Coder Web come va?');
    // The one called answers (rooms.ts `mentions`), and the room is read again on room.changed.
    expect(find.textContaining('On it'), findsOneWidget);
    expect(find.byKey(const Key('room-empty')), findsNothing);

    // «Add an agent»: the person's own and each project's, in our sheet.
    await tester.tap(find.byKey(const Key('room-add')));
    await _settle(tester);
    expect(find.byKey(const Key('room-pick')), findsOneWidget);
    expect(find.byKey(const Key('room-pick-a5')), findsOneWidget);
    // Already in: not offered.
    expect(find.byKey(const Key('room-pick-a3')), findsNothing);
    await tester.tap(find.byKey(const Key('room-pick-a5')));
    await _settle(tester, 8);
    expect(server.rooms.last, {'room': 'room_1', 'agentId': 'a5'});
    expect(find.byKey(const Key('room-member-a5')), findsOneWidget);
    expect(find.textContaining('è entrato nella chat'), findsOneWidget);

    await tester.tap(find.byKey(const Key('room-remove-a3')));
    await _settle(tester, 8);
    expect(find.byKey(const Key('room-member-a3')), findsNothing);
    expect(find.textContaining('è uscito dalla chat'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a group that no longer exists says so', (tester) async {
    await start(tester);
    push(tester, const RoomScreen(roomId: 'room_9'));
    await _settle(tester);
    expect(find.byKey(const Key('room-gone')), findsOneWidget);
    await done(tester);
  });

  testWidgets('the Chat: folders, earlier chats, groups and a new group', (tester) async {
    server.oldChats.addAll([
      {
        'id': 'ch1',
        'title': 'La moka',
        'projectId': null,
        'createdAt': '2026-11-10T10:00:00.000Z',
        'updatedAt': '2026-11-10T10:00:00.000Z',
      },
      {
        'id': 'ch2',
        'title': 'Ricette',
        'folder': 'Cucina',
        'projectId': null,
        'createdAt': '2026-11-09T10:00:00.000Z',
        'updatedAt': '2026-11-09T10:00:00.000Z',
      },
    ]);
    server.roomList.add({
      'id': 'room_1',
      'title': 'Rilascio',
      'members': [
        {'agentId': 'a0', 'sessionId': 'r0'},
      ],
      'createdAt': '2026-11-15T10:00:00.000Z',
      'lastAt': null,
      'answering': ['a0'],
    });
    await start(tester);
    app.setTab(AppTab.chat);
    await _settle(tester);
    expect(find.text('CUCINA'), findsOneWidget);
    expect(find.byKey(const Key('old-chat-ch2')), findsOneWidget);
    expect(find.text('CHAT DI PRIMA'), findsOneWidget);
    expect(find.byKey(const Key('old-chat-ch1')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('chat-new-group')),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('chat-days')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('GRUPPI'), findsOneWidget);
    expect(find.byKey(const Key('room-tile-room_1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-new-group')));
    await _settle(tester, 8);
    expect(server.rooms.last['title'], 'Nuovo gruppo');
    expect(find.byType(RoomScreen), findsOneWidget);
    await done(tester);
  });

  testWidgets('an old chat: read, go on, delete', (tester) async {
    server.oldChats.add({
      'id': 'ch1',
      'title': 'La moka',
      'projectId': null,
      'createdAt': '2026-11-10T10:00:00.000Z',
      'updatedAt': '2026-11-10T10:00:00.000Z',
    });
    await start(tester);
    app.setTab(AppTab.chat);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('old-chat-ch1')));
    await _settle(tester);
    expect(find.byType(DailyChatScreen), findsOneWidget);
    expect(find.byKey(const Key('daily-hint')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('daily-text')), 'Quanta acqua?');
    await tester.tap(find.byKey(const Key('daily-send')));
    await _settle(tester, 8);
    expect(server.chatActs, contains('send ch1 Quanta acqua?'));
    expect(find.textContaining('The answer to'), findsOneWidget);
    // The person's message and the search it made, as a chip.
    expect(find.text('Quanta acqua?'), findsNWidgets(2));

    await tester.tap(find.byKey(const Key('daily-delete')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester, 8);
    expect(server.chatActs, contains('delete ch1'));
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(DailyChatScreen), findsNothing);
    await done(tester);
  });

  testWidgets('an old chat goes on as a group, with itself as context', (tester) async {
    server.oldChats.add({
      'id': 'ch1',
      'title': 'La moka',
      'projectId': null,
      'createdAt': '2026-11-10T10:00:00.000Z',
      'updatedAt': '2026-11-10T10:00:00.000Z',
    });
    server.chatEntries['ch1'] = [
      {
        'id': 1,
        'message': {
          'role': 'user',
          'parts': [
            {'type': 'text', 'text': 'Quanta acqua?'},
          ],
        },
        'shown': 'Quanta acqua?',
        'createdAt': '2026-11-10T10:00:00.000Z',
      },
    ];
    await start(tester);
    push(tester, DailyChatScreen(chat: ChatSummary.fromJson(server.oldChats.single)));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('daily-group')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('room-pick-a5')));
    await _settle(tester, 8);
    expect(server.rooms.last['members'], ['a5']);
    expect((server.rooms.last['context'] as String), contains('User: Quanta acqua?'));
    expect(find.byType(RoomScreen), findsOneWidget);

    await done(tester);
  });

  testWidgets('an old chat moves to a folder', (tester) async {
    server.oldChats.add({
      'id': 'ch1',
      'title': 'La moka',
      'projectId': null,
      'createdAt': '2026-11-10T10:00:00.000Z',
      'updatedAt': '2026-11-10T10:00:00.000Z',
    });
    await start(tester);
    app.setTab(AppTab.chat);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('old-chat-folder-ch1')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('conv-folder-new')));
    await _settle(tester);
    await tester.enterText(find.byKey(const Key('conv-folder-name')), 'Caffè');
    await tester.tap(find.byKey(const Key('dialog-yes')));
    await _settle(tester, 8);
    expect(server.chatActs, contains('folder ch1 Caffè'));
    expect(find.text('CAFFÈ'), findsOneWidget);
    await done(tester);
  });

  testWidgets('a project\'s inspector: its conversations and a new one', (tester) async {
    await start(tester);
    push(tester, const DailyChatScreen(projectId: 'demo', projectName: 'Demo'));
    await _settle(tester);
    expect(find.text('Inspector · Demo'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('daily-text')), 'Che succede?');
    await tester.tap(find.byKey(const Key('daily-send')));
    await _settle(tester, 8);
    expect(server.chatActs, ['new ch1', 'send ch1 Che succede?']);
    expect(server.oldChats.single['projectId'], 'demo');
    await done(tester);
  });

  for (final wide in [false, true]) {
    testWidgets('the board (${wide ? 'computer' : 'phone'}): thread, reply, states, search', (
      tester,
    ) async {
      await start(tester, size: wide ? const Size(1280, 800) : const Size(390, 844));
      push(tester, const ProjectBoardScreen(projectId: 'demo', title: 'Bacheca · Demo'));
      await _settle(tester);
      expect(find.text('Ancora nessun thread.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('board-new-title')), 'Login rotto');
      await tester.enterText(find.byKey(const Key('board-new-body')), 'Non entra nessuno');
      await tester.tap(find.byKey(const Key('board-new-kind')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('board-kind-blocker')).last);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('board-new-send')));
      await _settle(tester, 8);
      expect(server.boardActs, ['post th1 blocker']);
      expect(find.byKey(const Key('board-thread-view-th1')), findsOneWidget);
      expect(find.text('blocco'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('board-reply-body')).last,
        'Ci guardo @a3_00000000',
      );
      await tester.tap(find.byKey(const Key('board-reply-send')).last);
      await _settle(tester, 8);
      expect(server.boardActs.last, 'post th1 note');
      await tester.tap(find.byKey(const Key('board-block')).last);
      await _settle(tester, 8);
      expect(server.boardActs.last, 'status th1 blocked');
      await tester.tap(find.byKey(const Key('board-reopen')).last);
      await _settle(tester, 8);
      await tester.tap(find.byKey(const Key('board-resolve')).last);
      await _settle(tester, 8);
      expect(server.boardActs.sublist(server.boardActs.length - 2), [
        'status th1 open',
        'status th1 resolved',
      ]);
      expect(find.text('risolto'), findsWidgets);
      if (!wide) {
        await tester.tap(find.byKey(const Key('board-thread-back')));
        await _settle(tester);
      }
      await tester.enterText(find.byKey(const Key('board-search')), 'entra');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await _settle(tester);
      expect(find.byKey(const Key('board-result-po1')), findsOneWidget);
      await done(tester);
    });
  }

  testWidgets('the board by subproject (G42.5): its threads and the whole project\'s', (
    tester,
  ) async {
    Map<String, dynamic> thread(String id, String title, [String? sub]) => {
      'id': id,
      'projectId': 'demo',
      'subprojectId': ?sub,
      'title': title,
      'status': 'open',
      'createdBy': 'human',
      'updatedAt': '2026-11-15T10:00:00.000Z',
      'posts': 1,
      'summary': null,
    };
    server.subprojects.addAll([
      {'id': 'sub_1', 'projectId': 'demo', 'name': 'Sito', 'dir': 'sito'},
      {'id': 'sub_2', 'projectId': 'demo', 'name': 'App', 'dir': 'app'},
    ]);
    server.boardThreads.addAll([
      thread('th1', 'Per tutti'),
      thread('th2', 'Del sito', 'sub_1'),
      thread('th3', "Dell'app", 'sub_2'),
    ]);
    await start(tester);
    push(tester, const ProjectBoardScreen(projectId: 'demo', title: 'Bacheca · Demo'));
    await _settle(tester);
    for (final id in ['th1', 'th2', 'th3']) {
      expect(find.byKey(Key('board-thread-$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('board-sub')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('board-sub-sub_1')).last);
    await _settle(tester);
    expect(find.byKey(const Key('board-thread-th1')), findsOneWidget);
    expect(find.byKey(const Key('board-thread-th2')), findsOneWidget);
    expect(find.byKey(const Key('board-thread-th3')), findsNothing);
    await tester.enterText(find.byKey(const Key('board-new-title')), 'Nuova pagina');
    await tester.enterText(find.byKey(const Key('board-new-body')), 'Serve la pagina dei prezzi');
    await tester.tap(find.byKey(const Key('board-new-send')));
    await _settle(tester, 8);
    expect(server.boardThreads.last['subprojectId'], 'sub_1');
    await done(tester);
  });
}
