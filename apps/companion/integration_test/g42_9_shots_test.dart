// G42.9: Settings › Automations, native, on Linux against a real RedGiant (the demo with
// DEMO_MAGIC=1, no real model), light and dark: the list, an automation's window with its runs,
// the editor (top, the parts, the advanced part with the YAML), a reminder, the magic start, the
// magic conversation with God's proposal, an assistant's routines, the messages in For you. Run
// in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for the phone's size, RG_SHOT_TAG
// telefono|computer), RG_SHOTS the folder for the pictures.
import 'dart:async';
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
import 'package:rgcompanion/screens/agent_settings_screen.dart';
import 'package:rgcompanion/screens/inbox_screen.dart';
import 'package:rgcompanion/settings/api/automations_api.dart';
import 'package:rgcompanion/settings/automations/automation_editor.dart';
import 'package:rgcompanion/settings/automations/automations_screen.dart';
import 'package:rgcompanion/settings/automations/magic_automation.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the automations on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 1500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final c = app.client!;
    final list = (await t.runAsync(c.automations))!;
    final digest = list.where((a) => a.name == 'morning-digest').firstOrNull ?? list.first;
    final magic = (await t.runAsync(c.magicAutomations))!;
    final ready = magic.where((m) => m.status == 'ready').firstOrNull;
    final assistant = app.agents.where((a) => a.kind == AgentKind.assistant).firstOrNull;

    Future<void> closeTop() async {
      nav.pop();
      await frames(t, 700);
    }

    Future<void> scrollTo(Key key) async {
      await t.ensureVisible(find.byKey(key));
      await frames(t, 500);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${_tag}_$theme';

      unawaited(openAutomationsSettings(ctx));
      await frames(t, 3000);
      await shot(t, '01_elenco_$tag');
      await scrollTo(Key('au-row-${digest.id}'));
      await shot(t, '02_elenco_sotto_$tag');

      // An automation's window with its runs.
      unawaited(openAutomation(ctx, digest, onChanged: () {}));
      await frames(t, 2500);
      await shot(t, '03_automazione_$tag');
      await closeTop();

      // The editor: the top, then When with the next times, then the advanced part and the YAML.
      unawaited(openAutomationEditor(ctx, title: 'Nuova automazione'));
      await frames(t, 2500);
      await shot(t, '04_editor_$tag');
      await scrollTo(const Key('au-next'));
      await shot(t, '05_editor_quando_$tag');
      await scrollTo(const Key('au-approve'));
      await shot(t, '06_editor_cosa_$tag');
      await t.tap(find.byKey(const Key('au-advanced-toggle')));
      await frames(t, 600);
      await scrollTo(const Key('au-yaml'));
      await shot(t, '07_editor_yaml_$tag');
      await closeTop();

      // A reminder, and the magic start.
      await t.tap(find.byKey(const Key('au-new-reminder')));
      await frames(t, 1500);
      await shot(t, '08_promemoria_$tag');
      await closeTop();
      await t.ensureVisible(find.byKey(const Key('au-magic')));
      await t.tap(find.byKey(const Key('au-magic')));
      await frames(t, 1500);
      await t.tap(find.byKey(const Key('au-magic-ex-0')));
      await frames(t, 600);
      await shot(t, '09_magia_$tag');
      await closeTop();

      // God's proposal beside the conversation.
      if (ready != null) {
        unawaited(openMagicChat(ctx, ready, onChange: () {}));
        await frames(t, 4000);
        await shot(t, '10_magia_proposta_$tag');
        await closeTop();
      }
      await closeTop();

      // An assistant's routines.
      if (assistant != null) {
        unawaited(
          nav.push(
            MaterialPageRoute<void>(
              builder: (_) => AgentSettingsScreen(
                agentId: assistant.id,
                agent: assistant,
                initial: AgentGroup.assistant,
              ),
            ),
          ),
        );
        await frames(t, 3000);
        await scrollTo(const Key('as-new-routine'));
        await shot(t, '11_routine_$tag');
        await closeTop();
      }

      // The automations' messages in For you.
      app.live.apply({
        'type': 'automation.notice',
        'automationId': digest.id,
        'runId': 'shot-$theme',
        'name': digest.title,
        'status': 'ok',
        'sessionId': null,
        'text': 'Ieri: due lavori finiti in Demo, un problema aperto sul login, nessuna decisione.',
      });
      unawaited(
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SafeArea(child: InboxScreen())),
          ),
        ),
      );
      await frames(t, 1500);
      await shot(t, '12_per_te_$tag');
      await closeTop();
      app.live.dismissNotice('shot-$theme');
    }
  });
}
