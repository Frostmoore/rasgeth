// G42.4: the settings of every day, native, on Linux against a real Rasgeth (the demo, no real
// model), light and dark: «Settings of <name>» with its rows, General, Requests, Safety, Tools,
// Commands, Budgets, the tree of agents, the new agent, an assistant's services and routines and
// an agent's settings. Run in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for the
// phone's size, RG_SHOT_TAG phone|computer), RG_SHOTS the folder for the pictures.
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
import 'package:rgcompanion/screens/new_agent_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/agents/agent_tree.dart';
import 'package:rgcompanion/settings/budgets_screen.dart';
import 'package:rgcompanion/settings/commands_screen.dart';
import 'package:rgcompanion/settings/general_screen.dart';
import 'package:rgcompanion/settings/requests_screen.dart';
import 'package:rgcompanion/settings/safety_screen.dart';
import 'package:rgcompanion/settings/tools_screen.dart';
import 'package:rgcompanion/ui/dialogs.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the settings of every day on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 1500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final assistant = app.agents.where((a) => a.kind == AgentKind.assistant).firstOrNull;
    final lead = app.agents.where((a) => a.kind == AgentKind.orchestrator).firstOrNull;

    Future<void> page(String name, Future<void> Function() open, {int wait = 2500}) async {
      unawaited(open());
      await frames(t, wait);
      await shot(t, name);
      nav.pop();
      await frames(t, 600);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${_tag}_$theme';

      // «Settings of <name>», scrolled to the settings of every day.
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-budgets')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await t.ensureVisible(find.byKey(const Key('settings-hub')));
      await shot(t, '01_impostazioni_$tag');
      nav.pop();
      await frames(t, 600);

      await page('02_generale_$tag', () => openGeneralSettings(ctx));
      await page('03_richieste_$tag', () => openRequestsSettings(ctx));
      await page('04_sicurezza_$tag', () => openSafetySettings(ctx));
      await page('05_strumenti_$tag', () => openToolsSettings(ctx));
      await page('06_comandi_$tag', () => openCommandsSettings(ctx));
      await page('07_budget_$tag', () => openBudgetsSettings(ctx));
      await page('08_albero_$tag', () => openAgentTree(ctx), wait: 3000);
      await page('09_nuovo_agente_$tag', () => openNewAgent(ctx));
      if (assistant != null) {
        await page(
          '10_assistente_$tag',
          () => _settings(ctx, assistant, AgentGroup.assistant),
          wait: 3000,
        );
      }
      if (lead != null) {
        await page('11_agente_$tag', () => _settings(ctx, lead, AgentGroup.general), wait: 3000);
      }
    }
  });
}

/// An agent's settings opened at one group (as openAgentSettings, with the group).
Future<void> _settings(BuildContext context, Agent a, AgentGroup group) {
  final size = MediaQuery.sizeOf(context);
  final screen = AgentSettingsScreen(
    agentId: a.id,
    agent: a,
    panel: size.width >= 760,
    initial: group,
  );
  if (size.width >= 760) {
    return showRgWindow<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 780, maxHeight: size.height * .9),
          child: screen,
        ),
      ),
    );
  }
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
