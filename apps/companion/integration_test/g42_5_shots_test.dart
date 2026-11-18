// G42.5 in the real app on Linux, against the demo server (a real Rasgeth, FakeProvider), light
// and dark: Projects in the bar without the advanced interface, a project with its subprojects
// (one made here, through the page's routes), its files opening on the subproject's folder, a
// real shell over /term drawn by xterm (colours, `top` in the other buffer, the phone's keys or
// the computer's tab beside the conversation), Settings › Projects and › Code with GitHub's and
// Gitea's windows. The terminal is the live check: what it shows came from the demo's shell.
// Run by tool/linux_shots.sh:
//   RG_SCREEN=390x844 … integration_test/g42_5_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_5_shots_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/desk_controller.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/project_overview_screen.dart';
import 'package:rgcompanion/settings/code_settings.dart';
import 'package:rgcompanion/settings/projects_settings.dart';
import 'package:rgcompanion/terminal/rg_terminal.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 900]) async {
    await t.ensureVisible(f.first);
    await frames(t, 200);
    await t.tap(f.first);
    await frames(t, ms);
  }

  NavigatorState nav(WidgetTester t) => t.state<NavigatorState>(find.byType(Navigator).first);

  testWidgets('G42.5: projects, subprojects, files and the terminal', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.agents.any((a) => a.name == 'Demo orchestrator'));
    await frames(t, 2000);
    final p = _phone ? 'telefono' : 'computer';
    final demo = app.agents.firstWhere((a) => a.name == 'Demo orchestrator');
    final project = app.projects.firstWhere((x) => x.id == demo.projectId);

    /// The shell has answered (the live check): its prompt, then what a command printed.
    Future<RgTerminalState> shell() async {
      final term = t.state<RgTerminalState>(find.byType(RgTerminal).last);
      await waitFor(t, () => term.session != null, seconds: 20);
      await frames(t, 1500);
      term.terminal.textInput(
        "printf '\\033[1;31mrosso \\033[32mverde \\033[34mblu \\033[33mgiallo\\033[0m\\n'; "
        'ls -la --color=always | head -n 8\r',
      );
      await waitFor(t, () => term.terminal.buffer.getText().contains('verde'), seconds: 20);
      await frames(t, 1200);
      return term;
    }

    // procps' top draws over the whole screen (it clears it, without the other buffer).
    Future<void> top(RgTerminalState term, String name) async {
      term.terminal.textInput('top -d 1\r');
      await waitFor(t, () => term.terminal.buffer.getText().contains('PID'), seconds: 20);
      await frames(t, 2500);
      await shot(t, name);
      term.terminal.textInput('q');
      await frames(t, 1500);
      term.terminal.textInput('clear\r');
      await frames(t, 800);
    }

    for (final dark in [false, true]) {
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final theme = dark ? 'scuro' : 'chiaro';
      String name(int n, String what) => 'g42-5-$p-$theme-${'$n'.padLeft(2, '0')}-$what';
      await frames(t, 800);

      // ---- Projects, the project and its subprojects ----
      if (_phone) {
        await tap(t, find.byKey(const Key('tab-projects')), 2500);
        await shot(t, name(1, 'progetti'));
        await tap(t, find.byKey(Key('project-${project.id}')), 2500);
      } else {
        DeskScope.read(t.element(find.byKey(const Key('view-team')))).showProject(project.id);
        await frames(t, 2500);
      }
      final newSub = find.byKey(Key('sub-new-${project.id}'));
      await t.scrollUntilVisible(newSub, 200, scrollable: find.byType(Scrollable).last);
      await frames(t, 600);
      await shot(t, name(2, 'progetto-sottoprogetti'));
      await tap(t, newSub, 1200);
      final made = app.subprojectsOf(project.id).isNotEmpty;
      await t.enterText(find.byKey(const Key('sub-name')), 'Negozio');
      await t.enterText(find.byKey(const Key('sub-dir')), 'apps/negozio');
      await frames(t, 600);
      await shot(t, name(3, 'nuovo-sottoprogetto'));
      if (made) {
        await tap(t, find.byKey(const Key('sub-cancel')), 1000);
      } else {
        await tap(t, find.byKey(const Key('sub-create')), 3500);
      }
      final sub = app.subprojectsOf(project.id).first;
      await tap(t, find.byKey(Key('sub-${sub.id}')), 1200);
      await t.scrollUntilVisible(
        find.byKey(Key('sub-team-${sub.id}')),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await shot(t, name(4, 'sottoprogetto-aperto'));
      await tap(t, find.byKey(Key('sub-files-${sub.id}')), 3000);
      await shot(t, name(5, 'file-del-sottoprogetto'));
      nav(t).popUntil((r) => r.isFirst);
      await frames(t, 1000);

      // ---- the terminal: the files' «Terminal» ----
      if (_phone) {
        final sid = await t.runAsync(() => app.openAgent(demo));
        nav(t)
            .push(
              MaterialPageRoute<void>(
                builder: (_) => ConversationScreen(sessionId: sid!, agent: demo),
              ),
            )
            .ignore();
        await frames(t, 3000);
        await tap(t, find.byKey(const Key('conversation-files')), 2500);
        await tap(t, find.byKey(const Key('files-terminal')), 2500);
        final term = await shell();
        await shot(t, name(6, 'terminale'));
        await tap(t, find.byKey(const Key('key-ctrl')), 500);
        await shot(t, name(7, 'terminale-ctrl'));
        await tap(t, find.byKey(const Key('key-ctrl')), 300);
        await top(term, name(8, 'terminale-top'));
        nav(t).popUntil((r) => r.isFirst);
        await frames(t, 1000);
      } else {
        await t.tap(find.byKey(Key('tile-${demo.id}')));
        await frames(t, 1500);
        await t.tap(find.byKey(const Key('agent-conv-new')));
        await frames(t, 3000);
        DeskScope.read(t.element(find.byKey(const Key('desk-panel')))).setFull(true);
        await frames(t, 1500);
        if (find.byKey(const Key('conversation-files-side')).evaluate().isEmpty) {
          await tap(t, find.byKey(const Key('conversation-files')), 2500);
        }
        await tap(t, find.byKey(const Key('files-terminal')), 2500);
        final term = await shell();
        await shot(t, name(6, 'terminale-scheda'));
        await top(term, name(8, 'terminale-top'));
        await tap(t, find.byKey(const Key('side-tab-files')), 1200);
        await shot(t, name(7, 'schede-file-e-terminale'));
        final close = find.byKey(const Key('side-tab-close-term-1'));
        if (close.evaluate().isNotEmpty) await tap(t, close, 800);
        DeskScope.read(t.element(find.byKey(const Key('desk-panel')))).setFull(false);
        await t.tap(find.byKey(const Key('rail-room')));
        await frames(t, 1500);
      }

      // ---- Settings › Projects and › Code ----
      nav(t).push(MaterialPageRoute<void>(builder: (_) => const ProjectsSettingsScreen())).ignore();
      await frames(t, 2000);
      await shot(t, name(9, 'impostazioni-progetti'));
      nav(t).pop();
      await frames(t, 800);
      nav(t).push(MaterialPageRoute<void>(builder: (_) => const CodeSettingsScreen())).ignore();
      await frames(t, 2500);
      await shot(t, name(10, 'impostazioni-codice'));
      await tap(t, find.byKey(const Key('cs-github')), 1500);
      await shot(t, name(11, 'github'));
      await tap(t, find.byKey(const Key('cs-done')), 1200);
      await tap(t, find.byKey(const Key('cs-gitea')), 1500);
      await shot(t, name(12, 'gitea'));
      await tap(t, find.byKey(const Key('cs-gitea-existing')), 800);
      await shot(t, name(13, 'gitea-esistente'));
      await tap(t, find.byKey(const Key('cs-done')), 1200);
      nav(t).popUntil((r) => r.isFirst);
      await frames(t, 1000);
      if (_phone) app.setTab(AppTab.team);
      // The project's panel closed for the next round.
      if (!_phone) {
        DeskScope.read(t.element(find.byKey(const Key('view-team')))).closePanel();
      }
      await frames(t, 800);
      expect(find.byType(ProjectOverview), findsNothing);
    }
  });
}
