// The first start from the app (G40.8) on a desktop, driven through its own screens against a
// real Rasgeth that has never been set up (the demo server with DEMO_FRESH=1 DEMO_SETUP_AP=1:
// Rasgeth OS's temporary network acted out, FakeProvider, no real model). The Wi-Fi joining is
// a fake one (no real network is touched); everything else is the real app and the real server:
// the setup channel, the access, the home network (a Wi-Fi password refused, then the cable),
// Rasgeth found again with the same key, the languages, a way of thinking, the names; then
// «Settings of <name>». With RG_SHOTS set, the screen is captured at each step. Run by
// tool/linux_shots.sh in the agents' Docker.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/first_start_screen.dart';
import 'package:rgcompanion/setup/first_start.dart';
import 'package:rgcompanion/setup/wifi.dart';

final _url = Platform.environment['RG_LIVE_URL'] ?? 'http://127.0.0.1:7651';
final _shots = Platform.environment['RG_SHOTS'];

/// Joins nothing real: the demo is the temporary network.
class _ActedWifi implements SetupWifi {
  @override
  bool get automatic => true;

  @override
  bool get needsName => true;

  @override
  Future<List<SeenNetwork>> scan() async => const [SeenNetwork('Rasgeth-Setup-D3M0', 82)];

  @override
  Future<JoinResult> join({String? ssid}) async =>
      JoinResult(JoinState.joined, ssid: ssid ?? 'Rasgeth-Setup-D3M0');

  @override
  Future<void> leave() async {}
}

Future<void> frames(WidgetTester t, [int ms = 1200]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> waitFor(WidgetTester t, bool Function() ok, {int seconds = 40}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw StateError('condition not met');
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 50));
  }
  // The screen catches up with what is true now.
  await frames(t, 300);
}

Future<void> shot(WidgetTester t, String name) async {
  await frames(t, 900);
  final dir = _shots;
  if (dir == null) return;
  await t.runAsync(
    () => Process.run('import', ['-window', 'root', '$dir/$name.png']).then((r) {
      if (r.exitCode != 0) throw StateError('import: ${r.stderr}');
    }),
  );
}

Future<void> scrollTo(WidgetTester t, Key list, Finder f) async {
  await t.scrollUntilVisible(
    f,
    250,
    scrollable: find.descendant(of: find.byKey(list), matching: find.byType(Scrollable)).first,
  );
  await frames(t, 400);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Rasgeth sets a new Rasgeth up', (t) async {
    final base = Uri.parse(_url);
    final app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs())
      ..locale = const Locale('it');
    late final FirstStartFlow flow;
    flow = FirstStartFlow(
      app,
      wifi: _ActedWifi(),
      setupBases: [base],
      poll: const Duration(milliseconds: 400),
      homeTimeout: const Duration(seconds: 20),
      findHome: (s, address) => flow.probeHome(s, address ?? base.authority),
    );
    await t.pumpWidget(RGCompanionApp(controller: app));
    await frames(t);
    await shot(t, 'fs-01-team-empty');

    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => FirstStartScreen(flow: flow)));
    await frames(t);
    await t.runAsync(flow.scan);
    await frames(t);
    await shot(t, 'fs-02-intro');

    await t.tap(find.byKey(const Key('fs-by-hand')));
    await frames(t);
    await shot(t, 'fs-03-by-hand');
    await t.tap(find.byKey(const Key('fs-joined')));
    await waitFor(t, () => flow.step == FsStep.access);
    await frames(t);
    await t.enterText(find.byKey(const Key('fs-password')), 'corta');
    await t.enterText(find.byKey(const Key('fs-password-again')), 'corta');
    await t.tap(find.byKey(const Key('fs-access-go')));
    await shot(t, 'fs-04-access-weak');
    await t.enterText(find.byKey(const Key('fs-password')), 'companion-first-1');
    await t.enterText(find.byKey(const Key('fs-password-again')), 'companion-first-1');
    await t.tap(find.byKey(const Key('fs-access-go')));
    await waitFor(t, () => flow.step == FsStep.home);
    await shot(t, 'fs-05-home');

    await t.tap(find.byKey(const Key('fs-net-Casa Rossi')));
    await frames(t, 400);
    await t.enterText(find.byKey(const Key('fs-home-password')), 'sbagliata');
    await shot(t, 'fs-06-home-password');
    await t.tap(find.byKey(const Key('fs-home-join')));
    await waitFor(t, () => flow.step == FsStep.homeWait);
    await shot(t, 'fs-07-home-wait');
    await waitFor(t, () => flow.step == FsStep.home && flow.error != null, seconds: 60);
    await shot(t, 'fs-08-home-refused');

    await t.tap(find.byKey(const Key('fs-cable')));
    await waitFor(t, () => flow.step == FsStep.language, seconds: 60);
    await shot(t, 'fs-09-language');
    await t.tap(find.byKey(const Key('fs-language-go')));
    await waitFor(t, () => flow.step == FsStep.brain);
    await t.tap(find.byKey(const Key('fs-way-key')));
    await frames(t, 400);
    await shot(t, 'fs-10-brain-key');
    await t.tap(find.byKey(const Key('fs-way-claude')));
    await frames(t, 400);
    await shot(t, 'fs-11-brain-claude');
    await t.tap(find.byKey(const Key('fs-brain-go')));
    await waitFor(t, () => flow.step == FsStep.names);
    await t.enterText(find.byKey(const Key('fs-god')), 'Zeus');
    await shot(t, 'fs-12-names');
    await t.tap(find.byKey(const Key('fs-names-go')));
    await waitFor(t, () => flow.step == FsStep.done, seconds: 60);
    await shot(t, 'fs-13-done');
    await t.tap(find.byKey(const Key('fs-done')));
    await waitFor(t, () => app.agents.isNotEmpty);
    await frames(t, 2500);
    await shot(t, 'fs-14-team');

    // «Settings of <name>».
    await t.tap(find.byKey(const Key('tab-you')));
    await frames(t);
    await shot(t, 'set-01-you');
    await t.tap(find.byKey(const Key('open-server-settings')));
    await waitFor(t, () => find.byKey(const Key('settings-devices')).evaluate().isNotEmpty);
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await frames(t);
    await shot(t, 'set-02-settings');
    await scrollTo(t, const Key('server-settings'), find.byKey(const Key('settings-outside')));
    await shot(t, 'set-03-settings-more');
    await scrollTo(t, const Key('server-settings'), find.byKey(const Key('settings-hub')));
    await shot(t, 'set-04-settings-hub');
    await t.drag(find.byKey(const Key('server-settings')), const Offset(0, 3000));
    await frames(t, 400);
    await t.tap(find.byKey(const Key('settings-rename')));
    await frames(t, 400);
    await t.enterText(find.byKey(const Key('dialog-text')), 'Mini PC salotto');
    await shot(t, 'set-05-rename');
    await t.tap(find.byKey(const Key('dialog-yes')));
    await waitFor(t, () => app.displayName == 'Mini PC salotto');
    await frames(t);
    await shot(t, 'set-06-renamed');
    app.setThemeMode(ThemeMode.dark);
    await frames(t);
    await shot(t, 'set-07-settings-dark');
  });
}
