// 3.8.8 in the real app on Linux against the demo server (a real RedGiant, FakeProvider): God's
// card and its menu, an agent's conversations, a conversation's menu, a project's conversations,
// menu and «Archive» window, the bell in the bar; on a phone the same with long presses and whole
// screens. Light and dark. Run by tool/linux_shots.sh with RG_SCREEN=1440x900, 1100x700, 430x932:
//   … integration_test/g388_menus_shots_test.dart
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/desktop/wall.dart';
import 'package:rgcompanion/screens/agent_conversations_screen.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _screen = Platform.environment['RG_SCREEN'] ?? '1440x900';
final _phone = (int.tryParse(_screen.split('x').first) ?? 1440) < 600;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tap(WidgetTester t, Finder f, [int ms = 1200]) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    await t.tap(f);
    await frames(t, ms);
  }

  Future<void> right(WidgetTester t, Finder f, {Offset? at, int ms = 900}) async {
    await t.ensureVisible(f);
    await frames(t, 200);
    if (at != null) {
      await t.tapAt(t.getTopLeft(f) + at, buttons: kSecondaryButton);
    } else {
      await t.tap(f, buttons: kSecondaryButton);
    }
    await frames(t, ms);
  }

  /// Closes the sheet on top (as the system's back).
  Future<void> closeSheet(WidgetTester t) async {
    final f = find.byType(BottomSheet);
    if (f.evaluate().isNotEmpty) Navigator.of(t.element(f.last)).pop();
    await frames(t, 1000);
  }

  Future<void> esc(WidgetTester t) async {
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await frames(t, 700);
  }

  testWidgets('3.8.8: menus, lists, the bell', (t) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(_url, _password));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 4000);
    final where = _phone ? 'telefono' : 'computer-$_screen';
    final god = app.god!;
    final project = app.projects.firstOrNull;

    // One theme per run (RG_THEME): a fresh app for each, as a person opens it.
    for (final theme in (Platform.environment['RG_THEME'] ?? 'chiaro scuro').split(' ')) {
      app.setThemeMode(theme == 'chiaro' ? ThemeMode.light : ThemeMode.dark);
      await frames(t, 1500);
      String n(int i, String what) => 'g388-$where-$theme-${i.toString().padLeft(2, '0')}-$what';
      if (_phone) {
        app.setTab(AppTab.team);
        await frames(t, 1500);
        await shot(t, n(1, 'squadra'));
        final card = find.byKey(const Key('team-god'));
        // As G38.7's shots: right after a page closes the first press can go astray here.
        for (var i = 0; i < 3 && find.byKey(const Key('agent-list')).evaluate().isEmpty; i++) {
          await t.longPress(card);
          await frames(t, 1500);
        }
        await shot(t, n(2, 'god-pressione-lunga'));
        // The sheet's «Conversations with God» (the card's tap does the same).
        await tap(t, find.byKey(const Key('agent-list')), 2500);
        await shot(t, n(3, 'god-conversazioni'));
        final row = find.byType(SessionTile);
        if (row.evaluate().isNotEmpty) {
          await t.longPress(row.first);
          await frames(t, 1500);
          await shot(t, n(4, 'conversazione-pressione-lunga'));
          await closeSheet(t);
        }
        await tap(t, find.byKey(const Key('agent-convs-back')));
        app.setTab(AppTab.chat);
        await frames(t, 1800);
        await shot(t, n(5, 'chat'));
        if (project != null) {
          app.setAdvanced(true);
          app.setTab(AppTab.projects);
          await frames(t, 2500);
          for (
            var i = 0;
            i < 3 && find.byKey(const Key('proj-menu-open')).evaluate().isEmpty;
            i++
          ) {
            await t.longPress(find.byKey(Key('project-${project.id}')));
            await frames(t, 1500);
          }
          await shot(t, n(6, 'progetto-pressione-lunga'));
          // The sheet's «Open» (the card's tap does the same).
          await tap(t, find.byKey(const Key('proj-menu-open')), 2500);
          await shot(t, n(7, 'progetto-conversazioni'));
          await tap(t, find.byKey(const Key('proj-more')));
          await tap(t, find.byKey(const Key('proj-menu-archive')), 2000);
          await shot(t, n(8, 'archivia-finestra'));
          await tap(t, find.byKey(const Key('dialog-no')));
          await tap(t, find.byKey(const Key('proj-back')));
          app.setAdvanced(false);
          await frames(t, 1000);
        }
        continue;
      }
      // ---- The computer ----
      final desk = find.byKey(const Key('view-team'));
      await tap(t, desk);
      await shot(t, n(1, 'sala-campanella'), wait: 2000);
      final card = find.byKey(const Key('desk-god'));
      final size = t.getSize(card);
      await right(t, card, at: Offset(size.width - 60, size.height - 30));
      await shot(t, n(2, 'god-clic-destro'));
      await esc(t);
      await tap(t, card, 2000);
      await shot(t, n(3, 'god-conversazioni'));
      final row = find.byType(SessionTile);
      if (row.evaluate().isNotEmpty) {
        await right(t, row.first);
        await shot(t, n(4, 'conversazione-clic-destro'));
        await esc(t);
      }
      final tile = find.byType(AgentTile);
      if (tile.evaluate().isNotEmpty) {
        await tap(t, tile.first, 2000);
        await shot(t, n(5, 'agente-conversazioni'));
      }
      await tap(t, find.byKey(const Key('desk-bell')), 1500);
      await shot(t, n(6, 'campanella-aperta'));
      await esc(t);
      // The full window's bar: the agents under their project's lead, a group closed.
      if (tile.evaluate().isNotEmpty) {
        await tap(t, tile.first, 1500);
        await tap(t, find.byKey(const Key('agent-conv-new')), 2500);
        if (find.byKey(const Key('panel-full')).evaluate().isNotEmpty) {
          await tap(t, find.byKey(const Key('panel-full')), 2000);
        }
        await shot(t, n(10, 'barra-albero'));
        final fold = find.byWidgetPredicate(
          (w) =>
              w.key is ValueKey<String> &&
              (w.key! as ValueKey<String>).value.startsWith('rail-fold-'),
        );
        if (fold.evaluate().isNotEmpty) {
          await tap(t, fold.first, 1200);
          await shot(t, n(11, 'barra-gruppo-chiuso'));
          await tap(t, fold.first, 1200);
        }
        await tap(t, find.byKey(const Key('panel-unfull')), 1500);
      }
      if (project != null) {
        await tap(t, find.byKey(const Key('view-projects')), 2000);
        final pt = find.byKey(Key('project-tile-${project.id}'));
        await right(t, pt);
        await shot(t, n(7, 'progetto-clic-destro'));
        await esc(t);
        await tap(t, pt, 2500);
        await shot(t, n(8, 'progetto-conversazioni'));
        await right(t, pt);
        await tap(t, find.byKey(const Key('proj-menu-archive')), 2500);
        await shot(t, n(9, 'archivia-finestra'));
        await tap(t, find.byKey(const Key('dialog-no')));
      }
      await t.tap(find.byKey(const Key('panel-close')));
      await frames(t, 800);
      // God's face is a hand-drawn one: no «change mascot» (the menu was shot above).
      expect(god.kind, AgentKind.god);
    }
  });
}
