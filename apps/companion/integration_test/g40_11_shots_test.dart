// G40.11 in the real app against a real RedGiant (the demo server, FakeProvider): the switch in
// Tu › Interfaccia, Projects with git, and a project's tabs (Tasks, Files, Diff, Terminal, Log,
// Git), the agent's sheet with Files, Diff and Terminal. Run by tool/linux_shots.sh with
//   RG_SCREEN=430x900 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_CODE=1" \
//     … integration_test/g40_11_shots_test.dart
// and, for a tablet held sideways (two panels), RG_SCREEN=1280x800 RG_TABLET=1.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/team_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tablet = Platform.environment['RG_TABLET'] == '1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1500]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  testWidgets('G40.11: the advanced interface', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _tablet ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected);
    await frames(t, 1500);
    final p = _tablet ? 'g4011-tablet' : 'g4011';

    // ---- Tu › Interfaccia ----
    await t.scrollUntilVisible(
      find.byKey(const Key('advanced-toggle')),
      200,
      scrollable: find
          .descendant(of: find.byKey(const Key('you-list')), matching: find.byType(Scrollable))
          .first,
    );
    await tap(t, find.byKey(const Key('advanced-toggle')));
    await t.scrollUntilVisible(
      find.byKey(const Key('advanced-terminals')),
      100,
      scrollable: find
          .descendant(of: find.byKey(const Key('you-list')), matching: find.byType(Scrollable))
          .first,
    );
    if (!_tablet) await shot(t, '$p-01-tu-interfaccia');

    // ---- Projects ----
    await tap(t, find.byKey(const Key('tab-projects')), 2500);
    if (!_tablet) await shot(t, '$p-02-progetti');
    await tap(t, find.byKey(const Key('project-demo')), 2500);
    if (!_tablet) await shot(t, '$p-03-compiti');

    // ---- Files ----
    await tap(t, find.byKey(const Key('ptab-files')), 2000);
    await tap(t, find.byKey(const Key('file-src')), 1500);
    await shot(t, '$p-04-file-cartella');
    await tap(t, find.byKey(const Key('file-src/app.py')), 2000);
    await shot(t, '$p-05-file-aperto');
    if (!_tablet) {
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await frames(t, 800);
      await t.enterText(find.byKey(const Key('files-search')), 'json');
      await frames(t, 2000);
      await shot(t, '$p-06-file-ricerca');
      await t.enterText(find.byKey(const Key('files-search')), '');
      await frames(t, 800);
    }

    // ---- Diff ----
    await tap(t, find.byKey(const Key('ptab-diff')), 2500);
    await shot(t, '$p-07-diff');
    if (!_tablet) {
      final comment = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && '${(w.key! as ValueKey<String>).value}'.startsWith('hunk-comment-@@'),
      );
      await tap(t, comment.first);
      await t.enterText(find.byKey(const Key('hunk-comment-text')), 'Mostra anche un esempio nel README');
      await frames(t, 600);
      await shot(t, '$p-08-diff-commenta');
      // Not through ensureVisible: it would slide the project's pages too.
      FocusManager.instance.primaryFocus?.unfocus();
      await frames(t, 600);
      await t.tap(find.byKey(const Key('diff-next')));
      await frames(t, 1500);
      await shot(t, '$p-09-diff-secondo-file');

      // ---- Terminal ----
      await tap(t, find.byKey(const Key('ptab-terminal')), 1500);
      await tap(t, find.byKey(const Key('term-open')), 4000);
      await t.enterText(find.byKey(const Key('term-input')), 'git status -s');
      await t.testTextInput.receiveAction(TextInputAction.send);
      await frames(t, 3000);
      await shot(t, '$p-10-terminale-mio');

      // ---- Log ----
      await tap(t, find.byKey(const Key('ptab-log')), 2500);
      await shot(t, '$p-11-log');
      await tap(t, find.byKey(const Key('log-errors')), 2500);
      final first = find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && RegExp(r'^log-\d+$').hasMatch('${(w.key! as ValueKey<String>).value}'),
      );
      await tap(t, first.first, 1200);
      await shot(t, '$p-12-log-errori-json');

      // ---- Git ----
      await tap(t, find.byKey(const Key('ptab-git')), 2500);
      await shot(t, '$p-13-git');
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await frames(t, 1000);

      // ---- The agent's sheet ----
      final coder = app.agents.firstWhere((a) => a.projectId == 'demo' && a.kind == AgentKind.agent);
      await tap(t, find.byKey(const Key('tab-team')), 1500);
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      unawaited(showAgentSheet(nav.context, coder));
      await frames(t, 1500);
      await shot(t, '$p-14-scheda-agente');
      await tap(t, find.byKey(const Key('agent-code-terminal')), 3000);
      await shot(t, '$p-15-terminale-agente');
    }
  });
}
