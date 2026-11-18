// G42.10 in the real app on Linux, against the demo server with its knowledge (DEMO_KNOWLEDGE=1:
// three collections, one read a third of the way, a picture waiting for the OCR, an answer that
// cites the documents; embeddings acted out, no model), light and dark: «Settings of <name>» with
// the two new rows, Settings › Knowledge (its state with the bar, the collections, try a search,
// the models, the OCR and the disk), a collection's window, adding a source, Shared memory, an
// agent's Knowledge and Memory tabs, and the conversation whose answer cites the documents.
// Run by tool/linux_shots.sh with RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_KNOWLEDGE=1":
//   RG_SCREEN=390x844 … integration_test/g42_10_shots_test.dart
//   RG_SCREEN=1440x900 … integration_test/g42_10_shots_test.dart
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
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/knowledge_screen.dart';
import 'package:rgcompanion/settings/memory_screen.dart';
import 'package:rgcompanion/ui/dialogs.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('G42.10: knowledge and memory', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await frames(t, 2000);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    final ctx = nav.context;
    final p = _phone ? 'telefono' : 'computer';
    final god = app.agents.firstWhere((a) => a.kind == AgentKind.god);

    // A page builds only what is near the screen: it scrolls until [key] is there.
    Future<void> scrollTo(Key key) async {
      if (find.byKey(key).evaluate().isEmpty) {
        for (final page in const [Key('knowledge-settings'), Key('memory-settings')]) {
          if (find.byKey(page).evaluate().isEmpty) continue;
          await t.scrollUntilVisible(
            find.byKey(key),
            250,
            scrollable: find
                .descendant(of: find.byKey(page), matching: find.byType(Scrollable))
                .first,
          );
        }
      }
      await t.ensureVisible(find.byKey(key).first);
      await frames(t, 500);
    }

    Future<void> tap(Key key, [int ms = 1500]) async {
      await scrollTo(key);
      await t.tap(find.byKey(key).first);
      await frames(t, ms);
    }

    void back() => nav.pop();

    for (final (theme, mode) in [('chiaro', ThemeMode.light), ('scuro', ThemeMode.dark)]) {
      app.setThemeMode(mode);
      await frames(t, 600);
      final tag = '${p}_$theme';

      // «Settings of <name>» with Knowledge and Shared memory.
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen())));
      await frames(t, 2500);
      await t.scrollUntilVisible(
        find.byKey(const Key('settings-memory')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await shot(t, '01_impostazioni_$tag');
      back();
      await frames(t, 600);

      // Settings › Knowledge, from the top down.
      unawaited(openKnowledgeSettings(ctx));
      await frames(t, 3500);
      await shot(t, '02_conoscenza_stato_$tag');
      await scrollTo(const Key('kb-try-field'));
      await t.enterText(find.byKey(const Key('kb-try-field')), 'garanzia lavatrice');
      await frames(t, 300);
      await tap(const Key('kb-try'), 2500);
      await shot(t, '03_conoscenza_prova_$tag');
      await scrollTo(const Key('kb-rerank-none'));
      await shot(t, '04_conoscenza_modelli_$tag');
      await scrollTo(const Key('kb-rebuild'));
      await shot(t, '05_conoscenza_ocr_disco_$tag');
      // A collection's window, then adding a source.
      // Back to the top, where the collections are.
      t
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const Key('knowledge-settings')),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position
          .jumpTo(0);
      await frames(t, 500);
      await t.ensureVisible(find.textContaining('Home manuals').first);
      await frames(t, 500);
      await t.tap(find.textContaining('Home manuals').first);
      await frames(t, 2500);
      await shot(t, '06_collezione_$tag');
      await tap(const Key('kb-add-source'), 2000);
      await shot(t, '07_aggiungi_fonte_$tag');
      await tap(const Key('kb-kind-chats'), 1000);
      await shot(t, '08_fonte_conversazioni_$tag');
      back();
      await frames(t, 800);
      back();
      await frames(t, 800);
      back();
      await frames(t, 800);

      // Shared memory.
      unawaited(openSharedMemory(ctx));
      await frames(t, 2500);
      await shot(t, '09_memoria_$tag');
      await scrollTo(const Key('mem-used'));
      await shot(t, '10_memoria_modifiche_$tag');
      back();
      await frames(t, 800);

      // God's Knowledge and Memory tabs.
      for (final (n, group) in [('11', AgentGroup.knowledge), ('12', AgentGroup.memory)]) {
        unawaited(_settings(ctx, god, group));
        await frames(t, 3000);
        await shot(t, '${n}_agente_${group.name}_$tag');
        back();
        await frames(t, 800);
      }

      // The answer that cites the documents.
      final cited = app.live.sessions
          .where((s) => (s.title ?? '').toLowerCase().contains('garanzia'))
          .firstOrNull;
      if (cited != null) {
        unawaited(
          nav.push(
            MaterialPageRoute<void>(
              builder: (_) => ConversationScreen(sessionId: cited.id, agent: god),
            ),
          ),
        );
        await frames(t, 4000);
        await shot(t, '13_citazioni_$tag');
        back();
        await frames(t, 800);
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
