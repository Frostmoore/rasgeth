// 3.9.4: the tool groups, native, on Linux against a real Rasgeth (the demo, no real model), light
// and dark: Settings › Tools with its groups (off by default, always on, off by you) and an agent's
// Tools with its own choice. Run in the agents' Docker with tool/linux_shots.sh (RG_SCREEN for the
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
import 'package:rgcompanion/settings/tools_screen.dart';
import 'package:rgcompanion/ui/dialogs.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _tag = Platform.environment['RG_SHOT_TAG'] ?? 'computer';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the tool groups on Linux', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.runAsync(() => app.connect(_url, _password));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 1500);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final coder =
        app.agents.where((a) => a.kind == AgentKind.agent).firstOrNull ??
        app.agents.where((a) => a.kind == AgentKind.orchestrator).firstOrNull;

    Future<void> scrollTo(Key key) async {
      final f = find.byKey(key);
      final list = find.byType(Scrollable).last;
      if (f.evaluate().isEmpty) {
        await t.scrollUntilVisible(f, 300, scrollable: list, maxScrolls: 80);
      }
      await t.ensureVisible(f);
      await frames(t, 500);
    }

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${_tag}_$theme';

      unawaited(openToolsSettings(ctx));
      await frames(t, 3000);
      await shot(t, '01_strumenti_$tag');
      await scrollTo(const Key('tl-kit-team'));
      await shot(t, '02_gruppi_$tag');
      await scrollTo(const Key('tl-kit-mail'));
      await shot(t, '03_gruppi_fine_$tag');
      nav.pop();
      await frames(t, 600);

      if (coder != null) {
        unawaited(_settings(ctx, coder, AgentGroup.tools));
        await frames(t, 3000);
        await scrollTo(const Key('tl-kit-core'));
        await shot(t, '04_agente_gruppi_$tag');
        nav.pop();
        await frames(t, 600);
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
