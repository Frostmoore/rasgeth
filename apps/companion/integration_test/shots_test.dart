// The real app on a desktop, driven through its own screens against a real Rasgeth started
// locally with FakeProvider (packages/web/scripts/demo-server.mjs with DEMO_PASSWORD): pairing
// from You, the live team, For you with a critical request, a new Chat with its answer, Activity
// and the Canvas. With RG_SHOTS set, the screen is captured at each step (ImageMagick `import`
// under Xvfb). Run by tool/linux_shots.sh in the agents' Docker.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/live.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/canvas_screen.dart';

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _password = Platform.environment['RG_LIVE_PASSWORD'] ?? 'companion-test-1';
final _shots = Platform.environment['RG_SHOTS'];

Future<void> frames(WidgetTester t, [int ms = 1200]) async {
  // The mascots move: pumpAndSettle would never settle.
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> waitFor(WidgetTester t, bool Function() ok, {int seconds = 30}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw StateError('condition not met');
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> shot(WidgetTester t, String name, {int wait = 900}) async {
  await frames(t, wait);
  // Where the tour is, so an exception in the log can be placed.
  debugPrint('shot: $name');
  final dir = _shots;
  if (dir == null) return;
  await t.runAsync(
    () => Process.run('import', ['-window', 'root', '$dir/$name.png']).then((r) {
      if (r.exitCode != 0) throw StateError('import: ${r.stderr}');
    }),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Rasgeth against a real Rasgeth', (t) async {
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await shot(t, 'linux-01-start');

    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await t.enterText(find.byKey(const Key('server-address')), _url);
    await t.enterText(find.byKey(const Key('server-password')), _password);
    await shot(t, 'linux-02-pairing');
    await t.tap(find.byKey(const Key('server-connect')));
    await waitFor(t, () => app.connected && app.liveStatus == LiveStatus.open);
    await waitFor(t, () => app.live.approvals.isNotEmpty);
    await shot(t, 'linux-03-you-paired');

    await t.tap(find.byKey(const Key('tab-team')));
    await frames(t, 2500);
    await shot(t, 'linux-04-team-live');
    // G40.9: the mascots always move: a few frames of the team, 0.4 s apart.
    for (var i = 0; i < 6; i++) {
      await shot(t, 'linux-04-team-frame-$i', wait: 400);
    }
    // The long press: what the agent is doing, its actions; then a favourite.
    Finder byPrefix(String p) => find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith(p),
    );
    final cards = byPrefix('agent-').evaluate().toList();
    if (cards.length > 1) {
      await t.longPress(find.byWidget(cards[1].widget));
      await frames(t);
      await shot(t, 'linux-04b-agent-sheet');
      await t.tap(find.byKey(const Key('agent-favourite')));
      await frames(t, 400);
      await t.tapAt(const Offset(20, 20));
      await frames(t);
      await shot(t, 'linux-04c-team-favourite');
    }
    final projects = byPrefix('team-filter-').evaluate().where((e) {
      final k = (e.widget.key! as ValueKey<String>).value;
      return k != 'team-filters' && k != 'team-filter-all' && k != 'team-filter-favourites';
    }).toList();
    if (projects.isNotEmpty) {
      await t.tap(find.byWidget(projects.first.widget));
      await frames(t);
      await shot(t, 'linux-04d-team-project');
      app.setTeamFilter(TeamFilter.all);
      await frames(t);
    }

    await t.tap(find.byKey(const Key('tab-inbox')));
    await frames(t);
    await shot(t, 'linux-05-for-you');
    final critical = app.live.approvals.where((r) => r.isCritical).firstOrNull;
    if (critical != null) {
      await t.tap(find.byKey(Key('open-${critical.requestId}')));
      await frames(t);
      await shot(t, 'linux-06-critical');
      await t.tap(find.byKey(const Key('critical-no')));
      await frames(t);
    }
    await shot(t, 'linux-06b-after-critical');
    // G40.9: an ordinary request on top of the stack, half swiped to the right. The demo's
    // classifier answers its ordinary requests by itself: for the picture only, one is shown
    // in the app (its answer goes to a request the server does not know, and is dropped).
    if (byPrefix('swipe-').evaluate().isEmpty) {
      app.live.apply({
        'type': 'permission.request',
        'request': {
          'requestId': 'shots-ordinary',
          'agentId': app.agents.first.id,
          'agentName': app.agents.first.name,
          'projectId': null,
          'tool': 'bash',
          'input': {'command': 'npm install --save-dev vitest'},
          'reasons': ['Installs packages'],
          'danger': <String>[],
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        },
      });
      for (var i = 0; i < 4 && byPrefix('swipe-').evaluate().isEmpty; i++) {
        if (find.byKey(const Key('inbox-later')).evaluate().isEmpty) break;
        await t.tap(find.byKey(const Key('inbox-later')));
        await frames(t, 300);
      }
    }
    final swipe = byPrefix('swipe-');
    if (swipe.evaluate().isNotEmpty) {
      await shot(t, 'linux-05b-stack');
      final g = await t.startGesture(t.getCenter(swipe.first));
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(15, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await shot(t, 'linux-05c-swiping-yes', wait: 100);
      await g.moveBy(const Offset(120, 0));
      await g.up();
      await frames(t);
      await shot(t, 'linux-05d-after-swipe');
    }

    // The field over the bar: a new conversation with Chat, at once.
    await t.enterText(find.byKey(const Key('chat-field')), 'Ciao! Cosa sai fare?');
    await t.tap(find.byKey(const Key('chat-send')));
    await waitFor(t, () => find.byKey(const Key('conversation-items')).evaluate().isNotEmpty);
    final sid = app.live.views.keys.last;
    await waitFor(t, () {
      final v = app.live.views[sid]!;
      return v.events.any((e) => e.type == 'message.assistant') && !v.running;
    }, seconds: 60);
    await shot(t, 'linux-07-chat-conversation');
    final toggle = find.byKey(const Key('thinking-toggle'));
    if (toggle.evaluate().isNotEmpty) {
      await t.tap(toggle.first);
      await shot(t, 'linux-08-reasoning-open');
    }
    await t.tap(find.byKey(const Key('conversation-back')));
    await frames(t);
    await shot(t, 'linux-09-chat-days');

    await t.tap(find.byKey(const Key('tab-activity')));
    await frames(t, 2500);
    await shot(t, 'linux-10-activity');

    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    unawaitedPush(nav, 'README.md');
    await frames(t, 2500);
    await shot(t, 'linux-11-canvas-markdown');
    nav.pop();
    await frames(t);

    app.setThemeMode(ThemeMode.dark);
    await t.tap(find.byKey(const Key('tab-team')));
    await frames(t, 2000);
    await shot(t, 'linux-12-team-dark');
    // The app taken down while its mascots move: nothing may break on the way out.
    await t.pumpWidget(const SizedBox());
    await frames(t, 500);
    debugPrint('tour: closed');
  });
}

void unawaitedPush(NavigatorState nav, String path) {
  nav.push(
    MaterialPageRoute<void>(
      builder: (_) => CanvasScreen(scope: 'project:demo', path: path, title: path),
    ),
  );
}
