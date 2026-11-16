// G40.17: RGCompanion's own interface on computers, the «control room» of board C. The pure parts
// as tables (the palette's prefixes and ranking, the git graph's lanes, the side-by-side diff,
// the Log's search line, shortcuts' words, the layout's threshold), then the room against the
// fake RedGiant in windows of 1440x900 and 1024x700: the wall, the side panel, the palette, the
// shortcuts, the floating panels, the quick Chat, the menus and the advanced views.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/code.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/advanced/git_view.dart';
import 'package:rgcompanion/desktop/advanced/log_view.dart';
import 'package:rgcompanion/desktop/desk_menu.dart';
import 'package:rgcompanion/desktop/desktop_shell.dart';
import 'package:rgcompanion/desktop/palette.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/home_shell.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

GitCommit _c(String h, List<String> parents) =>
    GitCommit(hash: h, short: h, author: '', date: '', refs: '', subject: h, parents: parents);

ProjectEvent _e(
  int seq,
  String type, {
  String agent = 'Coder Web',
  Object? payload,
  bool error = false,
  String ts = '2026-11-16T10:00:00Z',
}) => ProjectEvent(seq: seq, ts: ts, type: type, error: error, agentName: agent, payload: payload);

void main() {
  group('pure parts', () {
    test('the palette prefixes, plain and advanced', () {
      final table = <(String, bool, PaletteSection?, String)>[
        ('ric', false, null, 'ric'),
        ('@ric', false, PaletteSection.agents, 'ric'),
        ('> test', false, PaletteSection.commands, 'test'),
        ('/tema', false, PaletteSection.commands, 'tema'),
        ('#pricing', false, null, '#pricing'),
        ('#pricing', true, PaletteSection.files, 'pricing'),
        (':total', true, PaletteSection.lines, 'total'),
        ('! pnpm test', true, PaletteSection.terminal, 'pnpm test'),
        ('?pnpm', true, PaletteSection.events, 'pnpm'),
        ('  ', true, null, ''),
      ];
      for (final (raw, adv, only, text) in table) {
        final q = parsePaletteQuery(raw, advanced: adv);
        expect((q.only, q.text), (only, text), reason: raw);
      }
    });

    test('the palette ranks the start of a name first, then words, anywhere, letters', () {
      expect(matchScore('cod', 'Coder Web'), 0);
      expect(matchScore('web', 'Coder Web'), 1);
      expect(matchScore('der', 'Coder Web'), 2);
      expect(matchScore('negozio', 'Coder Web', 'pensa · Negozio'), 3);
      expect(matchScore('cdw', 'Coder Web'), 4);
      expect(matchScore('xyz', 'Coder Web'), isNull);
      expect(matchScore('perche', 'Perché no'), 0);
      PaletteItem it(String key, PaletteSection s, String title) =>
          PaletteItem(key: key, section: s, title: title, run: () {});
      final items = [
        it('c1', PaletteSection.commands, 'Ferma il Ricercatore'),
        it('a1', PaletteSection.agents, 'Analista'),
        it('a2', PaletteSection.agents, 'Ricercatore'),
        it('s1', PaletteSection.conversations, 'Report vendite'),
      ];
      expect(filterPalette(items, const PaletteQuery('ric')).map((i) => i.key), ['a2', 'c1']);
      expect(filterPalette(items, const PaletteQuery('')).map((i) => i.key), [
        'a1',
        'a2',
        's1',
        'c1',
      ]);
      expect(
        filterPalette(
          items,
          const PaletteQuery('ric', only: PaletteSection.commands),
        ).map((i) => i.key),
        ['c1'],
      );
    });

    test('the git graph: a line, a branch and its merge', () {
      final line = layoutGraph([
        _c('c', ['b']),
        _c('b', ['a']),
        _c('a', []),
      ]);
      expect(line.map((r) => (r.col, r.fromTop, r.toBottom)), [
        (0, false, true),
        (0, true, true),
        (0, true, false),
      ]);
      // m merges s (side) into b; both come from a.
      final merge = layoutGraph([
        _c('m', ['b', 's']),
        _c('s', ['a']),
        _c('b', ['a']),
        _c('a', []),
      ]);
      expect(merge[0].col, 0);
      expect(merge[0].branchesOut, [1]);
      expect(merge[1].col, 1);
      expect(merge[1].through, [0]);
      expect(merge[2].col, 0);
      expect(merge[2].through, [1]);
      expect(merge[3].col, 0);
      expect(merge[3].mergesIn, [1]);
      expect(merge.map((r) => r.width).reduce((a, b) => a > b ? a : b), 2);
      expect(refNames('HEAD -> p2.4.0, github/p2.4.0, tag: v2.3.2'), [
        'p2.4.0',
        'github/p2.4.0',
        'tag: v2.3.2',
      ]);
    });

    test('a hunk side by side: context on both sides, removed next to added', () {
      final files = parsePatch(
        'diff --git a/a.ts b/a.ts\n--- a/a.ts\n+++ b/a.ts\n'
        '@@ -1,4 +1,5 @@\n keep\n-old 1\n-old 2\n+new 1\n same\n+added\n',
      );
      final rows = sideBySideRows(files.single.hunks.single);
      String? t(DiffLine? l) => l?.text;
      expect(rows.map((r) => (t(r.$1), t(r.$2))), [
        ('keep', 'keep'),
        ('old 1', 'new 1'),
        ('old 2', null),
        ('same', 'same'),
        (null, 'added'),
      ]);
    });

    test("the Log's search line, read and written back", () {
      final q = parseLogQuery(
        'agente:"Coder Web","Tester" tipo:tool.*,approval.* pnpm solo:errori',
      );
      expect(q.agents, ['Coder Web', 'Tester']);
      expect(q.types, ['tool.*', 'approval.*']);
      expect(q.text, 'pnpm');
      expect(q.errors, isTrue);
      expect(
        formatLogQuery(q),
        'agente:"Coder Web","Tester" tipo:tool.*,approval.* solo:errori pnpm',
      );
      expect(parseLogQuery(formatLogQuery(q, italian: false)).agents, q.agents);
      final en = parseLogQuery('agent:Tester type:task.* when:today only:requests');
      expect(en.agents, ['Tester']);
      expect(en.types, ['task.*']);
      expect((en.when, en.requests), (LogWhen.today, true));
      final call = _e(
        1,
        'tool.call',
        payload: {
          'tool': 'bash',
          'input': {'command': 'pnpm test'},
        },
      );
      final asked = _e(2, 'approval.requested', agent: 'Tester', payload: {'text': 'git push'});
      final failed = _e(3, 'tool.result', error: true, payload: {'output': 'pnpm: 3 failed'});
      bool m(String q, ProjectEvent e) =>
          logMatches(e, parseLogQuery(q), now: DateTime.parse('2026-11-16T10:30:00Z'));
      expect(m('agente:"Coder Web" pnpm', call), isTrue);
      expect(m('agente:"Coder Web"', asked), isFalse);
      expect(m('tipo:approval.*', asked), isTrue);
      expect(m('tipo:tool.call', failed), isFalse);
      expect(m('solo:errori', failed), isTrue);
      expect(m('solo:errori', call), isFalse);
      expect(m('solo:richieste', asked), isTrue);
      expect(m('quando:ora', call), isTrue);
      expect(m('quando:ora', _e(4, 'tool.call', ts: '2026-11-15T09:00:00Z')), isFalse);
    });

    test('shortcuts in words: Ctrl on Windows and Linux, Cmd on macOS', () {
      final it = lookupAppLocalizations(const Locale('it'));
      final en = lookupAppLocalizations(const Locale('en'));
      expect(shortcutLabel(cmdKey(LogicalKeyboardKey.keyK, mac: false), it, mac: false), 'Ctrl+K');
      expect(shortcutLabel(cmdKey(LogicalKeyboardKey.keyK, mac: true), it, mac: true), 'Cmd+K');
      expect(
        shortcutLabel(cmdKey(LogicalKeyboardKey.keyD, mac: false, shift: true), it, mac: false),
        'Ctrl+Maiusc+D',
      );
      expect(
        shortcutLabel(cmdKey(LogicalKeyboardKey.space, mac: false, shift: true), en, mac: false),
        'Ctrl+Shift+Space',
      );
      expect(
        shortcutLabel(cmdKey(LogicalKeyboardKey.backslash, mac: true), it, mac: true),
        r'Cmd+\',
      );
    });

    test('the layout: computers from the chosen width, phones never', () {
      final pc = AppController(platform: DevicePlatform.windows, liveEnabled: false);
      expect(pc.desktopLayoutFor(1440), isTrue);
      expect(pc.desktopLayoutFor(1024), isTrue);
      expect(pc.desktopLayoutFor(800), isFalse);
      pc.setDesktopFrom(1200);
      expect(pc.desktopLayoutFor(1024), isFalse);
      pc.setDesktopFrom(0);
      expect(pc.desktopLayoutFor(500), isTrue);
      pc.setDesktopFrom(-1);
      expect(pc.desktopLayoutFor(3000), isFalse);
      final phone = AppController(platform: DevicePlatform.android, liveEnabled: false);
      expect(phone.desktopLayoutFor(1440), isFalse);
    });
  });

  late FakeRedGiant server;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    server.agentOverrides['a3'] = {'projectId': 'demo'};
    server.agentOverrides['a2'] = {'projectId': 'demo'};
    server.sessions.add({
      'id': 's9',
      'agentId': 'a3',
      'projectId': 'demo',
      'createdAt': '2026-11-15T09:00:00.000Z',
      'lastAt': '2026-11-15T09:10:00.000Z',
      'title': 'Pagina prezzi',
      'archived': false,
      'running': false,
    });
  });
  tearDown(() => server.close());

  Future<AppController> start(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
    bool advanced = false,
    MemoryAppPrefs? prefs,
    DevicePlatform platform = DevicePlatform.linux,
  }) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: prefs ?? MemoryAppPrefs(),
            platform: platform,
            liveEnabled: false,
          )
          ..locale = const Locale('it')
          ..reduceMotion = true;
    await tester.runAsync(() async {
      await app.connect(server.base.toString(), 'secret');
    });
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

  Future<void> keys(
    WidgetTester tester,
    List<LogicalKeyboardKey> mods,
    LogicalKeyboardKey key,
  ) async {
    for (final m in mods) {
      await tester.sendKeyDownEvent(m);
    }
    await tester.sendKeyEvent(key);
    for (final m in mods.reversed) {
      await tester.sendKeyUpEvent(m);
    }
    await _settle(tester, 6);
  }

  const ctrl = LogicalKeyboardKey.controlLeft;
  const shift = LogicalKeyboardKey.shiftLeft;

  for (final size in const [Size(1440, 900), Size(1024, 700)]) {
    testWidgets('${size.width.toInt()}x${size.height.toInt()}: the room, the wall and the panel', (
      tester,
    ) async {
      await start(tester, size: size);
      expect(find.byType(DesktopShell), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(TabBarA), findsNothing);
      // God, the Chat and «For you» at the top; the menus drawn (Linux); the status bar.
      expect(find.byKey(const Key('desk-god')), findsOneWidget);
      expect(find.byKey(const Key('desk-chat')), findsOneWidget);
      expect(find.byKey(const Key('desk-foryou')), findsOneWidget);
      expect(find.byKey(const Key('desk-menubar')), findsOneWidget);
      expect(find.byKey(const Key('desk-status')), findsOneWidget);
      expect(find.text('2 da te'), findsOneWidget);
      // The truly dangerous request takes the top of the room.
      expect(find.byKey(const Key('desk-critical-r2')), findsOneWidget);
      // The wall: grouped by project, God and Demi-God not on it.
      expect(find.byKey(const Key('tile-a3')), findsOneWidget);
      expect(find.byKey(const Key('tile-a0')), findsNothing);
      expect(find.text('DEMO'), findsOneWidget);
      await tester.tap(find.byKey(const Key('seg-Per stato')));
      await _settle(tester, 3);
      expect(find.text('DEMO'), findsNothing);
      // A tile opens its agent's conversation in the side panel.
      await tester.tap(find.byKey(const Key('tile-a3')));
      await _settle(tester);
      expect(find.byKey(const Key('desk-panel')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('desk-panel')),
          matching: find.byType(ConversationScreen),
        ),
        findsOneWidget,
      );
      // The panel's edge resizes it.
      final before = tester.getSize(find.byKey(const Key('desk-panel'))).width;
      await tester.drag(find.byKey(const Key('panel-resizer')), const Offset(-80, 0));
      await _settle(tester, 3);
      expect(tester.getSize(find.byKey(const Key('desk-panel'))).width, greaterThan(before));
      // Ctrl+\ closes and opens it again.
      await keys(tester, [ctrl], LogicalKeyboardKey.backslash);
      expect(find.byKey(const Key('desk-panel')), findsNothing);
      await keys(tester, [ctrl], LogicalKeyboardKey.backslash);
      expect(find.byKey(const Key('desk-panel')), findsOneWidget);
      // Taken out: it floats; put back: it is in the panel again.
      await tester.tap(find.byKey(const Key('panel-detach')));
      await _settle(tester);
      expect(find.byKey(const Key('desk-panel')), findsNothing);
      expect(find.byKey(const Key('floating-s9')), findsOneWidget);
      await tester.drag(find.byKey(const Key('floating-title-s9')), const Offset(-60, 40));
      await _settle(tester, 3);
      await tester.tap(find.byKey(const Key('floating-dock-s9')));
      await _settle(tester);
      expect(find.byKey(const Key('floating-s9')), findsNothing);
      expect(find.byKey(const Key('desk-panel')), findsOneWidget);
      await done(tester);
    });
  }

  testWidgets('the palette: Ctrl+K, agents and commands, Enter opens, Tab asks', (tester) async {
    final app = await start(tester);
    await keys(tester, [ctrl], LogicalKeyboardKey.keyK);
    expect(find.byKey(const Key('palette')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('palette-field')), 'cod');
    await _settle(tester, 4);
    expect(find.byKey(const Key('palette-agent-a3')), findsOneWidget);
    expect(find.byKey(const Key('palette-new-agent')), findsOneWidget);
    // Enter: the first row (Coder Web) in the panel.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.byKey(const Key('palette')), findsNothing);
    expect(find.byKey(const Key('desk-panel')), findsOneWidget);
    // Commands by their prefix; Esc closes.
    await keys(tester, [ctrl], LogicalKeyboardKey.keyK);
    await tester.enterText(find.byKey(const Key('palette-field')), '>tema');
    await _settle(tester, 4);
    expect(find.byKey(const Key('palette-command-theme-dark')), findsOneWidget);
    expect(find.byKey(const Key('palette-agent-a3')), findsNothing);
    await tester.tap(find.byKey(const Key('palette-command-theme-dark')));
    await _settle(tester, 4);
    expect(app.themeMode, ThemeMode.dark);
    // Tab: ask the agent without opening its conversation.
    await keys(tester, [ctrl], LogicalKeyboardKey.keyK);
    await tester.enterText(find.byKey(const Key('palette-field')), '@ricerc');
    await _settle(tester, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _settle(tester, 3);
    expect(find.text('A Ricercatore'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('palette-field')), 'Una domanda veloce');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.byKey(const Key('palette')), findsNothing);
    expect(server.requests.any((r) => r.startsWith('POST /api/sessions')), isTrue);
    await keys(tester, [ctrl], LogicalKeyboardKey.keyK);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester, 3);
    expect(find.byKey(const Key('palette')), findsNothing);
    await done(tester);
  });

  testWidgets('shortcuts: views, For you, the advanced switch, the quick Chat', (tester) async {
    final app = await start(tester);
    await keys(tester, [ctrl, shift], LogicalKeyboardKey.keyD);
    expect(find.byKey(const Key('desk-panel')), findsOneWidget);
    expect(find.text('Da te'), findsWidgets);
    await keys(tester, [ctrl], LogicalKeyboardKey.digit2);
    expect(find.byKey(const Key('desk-projects')), findsOneWidget);
    await keys(tester, [ctrl], LogicalKeyboardKey.digit3);
    expect(find.byKey(const Key('desk-strip')), findsOneWidget);
    await keys(tester, [ctrl, shift], LogicalKeyboardKey.keyA);
    expect(app.advanced, isTrue);
    expect(find.byKey(const Key('view-git')), findsOneWidget);
    await keys(tester, [ctrl], LogicalKeyboardKey.digit1);
    expect(find.byKey(const Key('desk-wall')), findsOneWidget);
    // The quick Chat: today's conversation or a new one, over the room.
    await keys(tester, [ctrl, shift], LogicalKeyboardKey.space);
    await _settle(tester);
    expect(find.byKey(const Key('quick-chat')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quick-chat-expand')));
    await _settle(tester);
    expect(find.byKey(const Key('quick-chat')), findsNothing);
    expect(find.byKey(const Key('desk-panel')), findsOneWidget);
    // Ctrl+G: God's field.
    await keys(tester, [ctrl], LogicalKeyboardKey.keyG);
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('desk-god-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.focusNode?.hasFocus, isTrue);
    await done(tester);
  });

  testWidgets('the menus: drawn on Linux, every command there', (tester) async {
    final app = await start(tester);
    await tester.ensureVisible(find.byKey(const Key('menu-Vista')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu-Vista')));
    await _settle(tester, 3);
    expect(find.byKey(const Key('menuitem-view-projects')), findsOneWidget);
    await tester.tap(find.byKey(const Key('menuitem-advanced')));
    await _settle(tester, 3);
    expect(app.advanced, isTrue);
    await tester.ensureVisible(find.byKey(const Key('menu-Aiuto')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('menu-Aiuto')));
    await _settle(tester, 3);
    await tester.tap(find.byKey(const Key('menuitem-shortcuts')));
    await _settle(tester, 3);
    expect(find.text('Scorciatoie da tastiera'), findsWidgets);
    expect(find.text('Ctrl+K'), findsWidgets);
    await done(tester);
  });

  testWidgets('the advanced views: projects, code, terminals, git, log', (tester) async {
    await start(tester, advanced: true);
    await tester.ensureVisible(find.byKey(const Key('view-projects')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('view-projects')));
    await _settle(tester);
    expect(find.byKey(const Key('project-tile-demo')), findsOneWidget);
    expect(find.text('p2.4.0'), findsWidgets);
    expect(find.byKey(const Key('desk-event-stream')), findsOneWidget);
    expect(find.byKey(const Key('desk-open-tasks')), findsOneWidget);
    // A project's tile opens it in Code: changes, tree, the diff side by side.
    await tester.tap(find.byKey(const Key('project-tile-demo')));
    await _settle(tester, 16);
    expect(find.byKey(const Key('change-src/prices.ts')), findsOneWidget);
    expect(find.byKey(const Key('diff-side-by-side')), findsOneWidget);
    await tester.tap(find.byKey(const Key('diff-mode-1')));
    await _settle(tester, 4);
    expect(find.byKey(const Key('diff-side-by-side')), findsNothing);
    await tester.tap(find.byKey(const Key('tree-src')));
    await _settle(tester, 6);
    await tester.tap(find.byKey(const Key('tree-src/prices.ts')));
    await _settle(tester, 8);
    expect(find.byKey(const Key('doc-tab-1')), findsOneWidget);
    // Terminals: the agents' read only, a shell of one's own.
    await tester.ensureVisible(find.byKey(const Key('view-terminals')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('view-terminals')));
    await _settle(tester, 10);
    // The project's agents are there at first; their row takes them away and back.
    expect(find.byKey(const Key('term-cell-a3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('term-agent-row-a3')));
    await _settle(tester, 4);
    expect(find.byKey(const Key('term-cell-a3')), findsNothing);
    await tester.tap(find.byKey(const Key('term-agent-row-a3')));
    await _settle(tester, 10);
    expect(find.byKey(const Key('term-cell-a3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('term-new')));
    await _settle(tester, 10);
    expect(find.byKey(const Key('term-cell-own-demo')), findsOneWidget);
    expect(find.text('sola lettura'), findsWidgets);
    // Git: the graph of every branch, the chosen commit with its files.
    await tester.ensureVisible(find.byKey(const Key('view-git')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('view-git')));
    await _settle(tester, 14);
    expect(find.byKey(const Key('git-graph')), findsOneWidget);
    expect(find.byKey(const Key('commit-abc1234')), findsOneWidget);
    expect(find.byKey(const Key('commit-0001111')), findsOneWidget);
    expect(find.text('Commit scelto'.toUpperCase()), findsOneWidget);
    expect(server.requests.any((r) => r.contains('/git/log') && r.contains('all=1')), isTrue);
    // Log: the table, a search, the event as JSON.
    await tester.ensureVisible(find.byKey(const Key('view-log')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('view-log')));
    await _settle(tester, 10);
    expect(find.byKey(const Key('log-row-1')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('log-search')), 'solo:errori');
    await _settle(tester, 3);
    expect(find.byKey(const Key('log-row-1')), findsNothing);
    expect(find.byKey(const Key('log-row-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('log-row-2')));
    await _settle(tester, 3);
    expect(find.byKey(const Key('log-json')), findsOneWidget);
    await done(tester);
  });

  testWidgets('narrow window, «never» or a phone: the phone shell as before', (tester) async {
    await start(tester, size: const Size(800, 900));
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(DesktopShell), findsNothing);
    await done(tester);
    final app = await start(tester);
    expect(find.byType(DesktopShell), findsOneWidget);
    app.setDesktopFrom(-1);
    await _settle(tester, 3);
    expect(find.byType(HomeShell), findsOneWidget);
    await done(tester);
    await start(tester, platform: DevicePlatform.android);
    expect(find.byType(HomeShell), findsOneWidget);
    await done(tester);
  });

  testWidgets('Tu › Aspetto: the layout choice on computers, kept', (tester) async {
    final prefs = MemoryAppPrefs();
    final app = await start(tester, size: const Size(1440, 900), prefs: prefs);
    app.setDesktopFrom(-1);
    await _settle(tester, 3);
    expect(find.byType(HomeShell), findsOneWidget);
    await tester.tap(find.byKey(const Key('tab-you')));
    await _settle(tester, 4);
    await tester.scrollUntilVisible(
      find.byKey(const Key('desktop-layout')),
      200,
      scrollable: find
          .descendant(of: find.byKey(const Key('you-list')), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('Sempre'));
    await _settle(tester, 4);
    expect(app.desktopFrom, 0);
    expect(await prefs.get('desktopFrom'), '0');
    expect(find.byType(DesktopShell), findsOneWidget);
    await done(tester);
  });
}
