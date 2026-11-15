// Team as the user drew it, the agents' «Model», the composer's «…», «New agent» and the
// mascots never in step (3.8.1), in the real app against a real RedGiant (the demo server,
// FakeProvider). A phone-sized window. Run by tool/linux_shots.sh with
//   RG_SCREEN=430x900 RG_DEMO_ENV="DEMO_PASSWORD=companion-test-1 DEMO_API_KEY=1" … \
//     integration_test/squad_shots_test.dart
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
import 'package:rgcompanion/mascot/mascot_view.dart';
import 'package:rgcompanion/mascot/motion.dart';
import 'package:rgcompanion/mascot/svg_layers.dart';

import 'shots_test.dart' show frames, shot, waitFor;

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';

/// A film strip: [mascots] side by side, one row every half second from [from] to [to] seconds,
/// each at that fixed moment; under a mascot in the middle of a hop, a mark.
class FilmStrip extends StatelessWidget {
  const FilmStrip({super.key, required this.mascots, required this.from, required this.to});

  final List<({String name, String svg})> mascots;
  final double from;
  final double to;

  @override
  Widget build(BuildContext context) {
    final hop = MotionTable.instance.states[MascotState.idle]!.firstWhere(
      (t) => t.el == 'ev' && t.prop == MotionProp.translate,
    );
    final rows = <double>[for (var t = from; t <= to + 1e-9; t += .5) t];
    final cell = (MediaQuery.sizeOf(context).width - 56) / mascots.length;
    return ColoredBox(
      color: const Color(0xFFF7F4EF),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                'Mascotte ferme, ${from.toStringAsFixed(0)}-${to.toStringAsFixed(0)} s: '
                'il segno sotto chi sta saltando',
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 50),
                for (final m in mascots)
                  SizedBox(
                    width: cell,
                    child: Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF333333)),
                    ),
                  ),
              ],
            ),
            for (final t in rows)
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      '${t.toStringAsFixed(1)} s',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF555555)),
                    ),
                  ),
                  for (final m in mascots)
                    SizedBox(
                      width: cell,
                      height: cell * .62 + 8,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          MascotView(
                            svg: m.svg,
                            state: MascotState.idle,
                            theme: MascotTheme.light,
                            size: cell * .62,
                            seconds: t,
                          ),
                          if (hop.rareProgress(
                                t,
                                rhythmFor(splitMascotSvg(m.svg, MotionTable.instance.elements)),
                              ) !=
                              null)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                width: cell * .5,
                                height: 4,
                                color: const Color(0xFFE8553D),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Team, Model, the «…», New agent and the film of the mascots', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await t.tap(find.byKey(const Key('tab-team')));
    await waitFor(t, () => app.chatAgentId != null);
    await frames(t, 2500);
    await shot(t, 'g40-squad-01-team');
    // God's conversation (a tap on its card): an answer, then the «…».
    await t.tap(find.byKey(const Key('team-god')));
    await waitFor(t, () => find.byKey(const Key('composer-text')).evaluate().isNotEmpty);
    await frames(t, 1500);
    await t.enterText(find.byKey(const Key('composer-text')), 'Ciao God, come va?');
    await t.tap(find.byKey(const Key('composer-send')));
    await frames(t, 5000);
    await shot(t, 'g40-squad-06-conversation');
    await t.tap(find.byKey(const Key('composer-more')));
    await frames(t, 1500);
    await shot(t, 'g40-squad-07-more');
    await t.tap(find.byKey(const Key('mode-plan')));
    await frames(t, 1500);
    await shot(t, 'g40-squad-08-more-plan');
    final aside = find.byKey(const Key('more-aside'));
    if (aside.evaluate().isNotEmpty) {
      await t.tap(aside);
      await frames(t, 1200);
      await t.enterText(find.byKey(const Key('aside-field')), 'Quanti agenti ho?');
      await t.tap(find.byKey(const Key('aside-ask')));
      await frames(t, 4000);
      await shot(t, 'g40-squad-09-meanwhile');
      await t.tapAt(const Offset(20, 20));
      await frames(t, 800);
    }
    await t.tap(find.byKey(const Key('mode-auto')));
    await frames(t, 1000);
    await t.tapAt(const Offset(20, 20));
    await frames(t, 800);
    await t.tap(find.byKey(const Key('conversation-back')));
    await frames(t, 2000);
    // God answered: awake, «active».
    await shot(t, 'g40-squad-06b-team-god-active');
    final grid = find.byKey(const Key('team-scroll'));
    await t.drag(grid, const Offset(0, -400));
    await frames(t, 800);
    await shot(t, 'g40-squad-02-team-agents');
    await t.drag(grid, const Offset(0, 800));
    await frames(t, 800);

    // God's sheet: «Model» with its way; the families with Subscription / API key.
    await t.longPress(find.byKey(const Key('team-god')));
    await frames(t, 1500);
    await shot(t, 'g40-squad-03-god-sheet');
    await t.tap(find.byKey(const Key('agent-model')));
    await frames(t, 1500);
    final family = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('model-anthropic/'),
    );
    if (family.evaluate().isNotEmpty) {
      await t.tap(family.first);
      await frames(t, 800);
    }
    await shot(t, 'g40-squad-04-model-sheet');
    final use = find.byKey(const Key('model-use'));
    if (use.evaluate().isNotEmpty) {
      await t.tap(use);
      await frames(t, 2000);
      await shot(t, 'g40-squad-05-god-model-saved');
    } else {
      await t.tapAt(const Offset(20, 20));
      await frames(t, 800);
      await t.longPress(find.byKey(const Key('team-god')));
      await frames(t, 1500);
    }

    // God's instructions, from the same sheet: the editor, then «Improve the instructions».
    await t.ensureVisible(find.byKey(const Key('agent-instructions')));
    await frames(t, 300);
    await t.tap(find.byKey(const Key('agent-instructions')));
    await frames(t, 2000);
    await shot(t, 'g40-squad-05b-instructions');
    final body = find
        .descendant(of: find.byKey(const Key('prompt-body')), matching: find.byType(Scrollable))
        .first;
    await t.scrollUntilVisible(find.byKey(const Key('refine-open')), 300, scrollable: body);
    await frames(t, 300);
    await t.tap(find.byKey(const Key('refine-open')));
    await frames(t, 2500);
    await t.scrollUntilVisible(find.byKey(const Key('refine-estimate')), 300, scrollable: body);
    await frames(t, 500);
    await shot(t, 'g40-squad-05c-instructions-improve');
    await t.tap(find.byKey(const Key('prompt-close')));
    await frames(t, 1000);

    // A tap on God's card again after the sheets (the tour reports what it sees).
    await t.tap(find.byKey(const Key('team-god')));
    for (var i = 0; i < 20; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pump(const Duration(milliseconds: 50));
    }
    final reopened = find.byKey(const Key('conversation-back')).evaluate().isNotEmpty;
    debugPrint('TOUR god card after the sheets: ${reopened ? 'opens' : 'does not open'}');
    if (reopened) {
      await t.tap(find.byKey(const Key('conversation-back')));
      await frames(t, 1500);
    }
    // A card never long-pressed, after the same sheets.
    final other = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('agent-') &&
          w is InkWell,
    );
    if (other.evaluate().isNotEmpty) {
      await t.tap(other.first);
      for (var i = 0; i < 20; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump(const Duration(milliseconds: 50));
      }
      final opened = find.byKey(const Key('conversation-back')).evaluate().isNotEmpty;
      debugPrint('TOUR another card after the sheets: ${opened ? 'opens' : 'does not open'}');
      if (opened) {
        await t.tap(find.byKey(const Key('conversation-back')));
        await frames(t, 1500);
      }
    }
    // And God's card with a fresh pointer: a long press opens its sheet?
    await t.longPress(find.byKey(const Key('team-god')));
    await frames(t, 1200);
    debugPrint(
      'TOUR god long press after the sheets: '
      '${find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('agent-sheet-')).evaluate().isNotEmpty ? 'sheet' : 'nothing'}',
    );
    await t.tapAt(const Offset(20, 20));
    await frames(t, 1200);
    await shot(t, 'g40-squad-10-team');

    // New agent: an assistant, step by step.
    await t.tap(find.byKey(const Key('team-new-agent')));
    await frames(t, 1200);
    await shot(t, 'g40-squad-11-new-kind');
    await t.tap(find.byKey(const Key('new-kind-assistant')));
    await frames(t, 400);
    await t.tap(find.byKey(const Key('new-agent-next')));
    await frames(t, 800);
    await t.enterText(find.byKey(const Key('new-agent-name')), 'Agenda');
    await t.enterText(
      find.byKey(const Key('new-agent-role')),
      'tiene in ordine i miei appuntamenti',
    );
    await frames(t, 2500);
    await shot(t, 'g40-squad-12-new-name');
    await t.tap(find.byKey(const Key('new-agent-next')));
    await frames(t, 800);
    await shot(t, 'g40-squad-13-new-model');
    await t.tap(find.byKey(const Key('new-agent-next')));
    await frames(t, 2500);
    await shot(t, 'g40-squad-14-new-tools');
    await t.tap(find.byKey(const Key('new-agent-next')));
    await frames(t, 800);
    await shot(t, 'g40-squad-15-new-review');
    await t.tap(find.byKey(const Key('new-agent-next')));
    await waitFor(t, () => find.byKey(const Key('new-agent-done')).evaluate().isNotEmpty);
    await frames(t, 2000);
    await shot(t, 'g40-squad-16-new-done');
    await t.tap(find.byKey(const Key('new-agent-open')));
    await frames(t, 3000);
    await shot(t, 'g40-squad-17-new-conversation');
    await t.tap(find.byKey(const Key('conversation-back')));
    await frames(t, 2000);
    await shot(t, 'g40-squad-18-team-with-new');

    // The film: six mascots asleep, each at the same fixed moments.
    final c = app.client!;
    final six = app.agents.where((a) => a.kind != AgentKind.god).take(6).toList();
    final svgs = <({String name, String svg})>[];
    for (final a in six) {
      final svg = await t.runAsync(() => c.mascotSvg(a.id, theme: MascotTheme.light));
      svgs.add((name: a.name, svg: svg!));
    }
    for (final (i, (from, to)) in [(0.0, 5.0), (5.5, 10.0)].indexed) {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilmStrip(mascots: svgs, from: from, to: to),
          ),
        ),
      );
      await frames(t, 800);
      await shot(t, 'g40-squad-film-${i + 1}');
    }
  });
}
