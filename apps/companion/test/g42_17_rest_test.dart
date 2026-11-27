// G42.17: the rest of the page, native, against the fake Rasgeth (test/fake_setup.dart): the setup
// wizard (the counter, every step, saved when left, the summary and «Finish»), the import from
// other agents (look, choose, import, undo), the external agents (list, add from a ready command,
// try, a secret refused), the history of changes (sentences, undo, discard), the full-text search,
// and Settings with no more «All settings».
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/full_search_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/acp_screen.dart';
import 'package:rgcompanion/settings/import_screen.dart';
import 'package:rgcompanion/settings/platform_screen.dart';
import 'package:rgcompanion/settings/general_words.g.dart' show newsVersion;
import 'package:rgcompanion/setup/wizard/wizard_screen.dart';

import 'fake_server.dart';
import 'fake_setup.dart';

void main() {
  late FakeRedGiant server;
  late FakeSetup fake;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    fake = FakeSetup(server);
  });
  tearDown(() => server.close());

  Future<void> settle(WidgetTester tester, [int rounds = 10]) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<AppController> start(WidgetTester tester, {Size size = const Size(390, 1400)}) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
      liveEnabled: false,
    )..locale = const Locale('it');
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await settle(tester);
    return app;
  }

  Future<void> push(WidgetTester tester, Widget screen) async {
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .ignore();
    await settle(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final f = find.byKey(Key(key));
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await settle(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  testWidgets('the wizard: every step in order, saved when left, then «Finish»', (tester) async {
    await start(tester);
    await push(tester, const SetupWizardScreen());
    // A password was there already: its step is not offered (15 steps, standard mode).
    expect(find.text('1 di 15'), findsOneWidget);
    expect(find.text('Ciao. Prepariamo Rasgeth.'), findsOneWidget);
    await tap(tester, 'wz-next');
    expect(fake.saved, contains('languages it'));
    expect(find.text('Che cosa sarà questo Rasgeth?'), findsOneWidget);
    await tap(tester, 'wz-next');
    // The machine, as the server measured it.
    expect(find.textContaining('AMD Ryzen 9 9900X'), findsOneWidget);
    await tap(tester, 'wz-next');
    // Advanced adds the code's step.
    await tap(tester, 'wz-pick-advanced');
    await tap(tester, 'wz-next');
    expect(fake.saved, contains('mode advanced'));
    expect(find.text('5 di 16'), findsOneWidget);
    // The counter opens every step: jump to the names.
    await tap(tester, 'wz-counter');
    expect(find.byKey(const Key('wz-jump')), findsOneWidget);
    await tap(tester, 'wz-jump-wzNames');
    await tester.enterText(find.byKey(const Key('wz-god')), 'Zeus');
    await tap(tester, 'wz-next');
    expect(fake.saved, contains('names Zeus Demi-God'));
    // Safety: a ready choice.
    await tap(tester, 'wz-counter');
    await tap(tester, 'wz-jump-wzSafety');
    await tap(tester, 'wz-pick-balanced');
    await tap(tester, 'wz-next');
    expect(fake.saved, contains('safety 8'));
    // The summary, then «Finish».
    expect(find.byKey(const Key('wz-recap')), findsOneWidget);
    expect(find.text('Zeus · Demi-God'), findsOneWidget);
    expect(find.text('Equilibrata'), findsOneWidget);
    await tap(tester, 'wz-next');
    expect(fake.saved.last, 'complete');
    expect(find.byKey(const Key('wz')), findsNothing);
    await done(tester);
  });

  testWidgets('3.12.1: a fresh install has «Semplice» preselected, and leaving saves it', (
    tester,
  ) async {
    final app = await start(tester);
    (server.setup['config'] as Map<String, dynamic>).remove('ui');
    await push(tester, const SetupWizardScreen(start: 'wzLook'));
    expect(find.text('Come vuoi vedere Rasgeth?'), findsOneWidget);
    await tap(tester, 'wz-next');
    expect(fake.saved, contains('interface simple'));
    expect(app.uiDefault, 'simple');
    await done(tester);
  });

  testWidgets('3.12.1: an installation that already chose the full one keeps it', (tester) async {
    (server.setup['config'] as Map<String, dynamic>)['ui'] = 'full';
    final app = await start(tester);
    await push(tester, const SetupWizardScreen(start: 'wzLook'));
    await tap(tester, 'wz-next');
    expect(fake.saved, isNot(contains('interface simple')));
    expect(app.simpleUi, isFalse);
    await done(tester);
  });

  testWidgets('a password too short is said, never sent', (tester) async {
    await start(tester);
    server.routes['GET /api/auth/methods'] = (q) =>
        server.answer(q, 200, {'password': false, 'code': false});
    await push(tester, const SetupWizardScreen(start: 'wzAccount'));
    expect(find.text('3 di 16'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('wz-password')), 'corta');
    await tester.enterText(find.byKey(const Key('wz-password-again')), 'corta');
    await tap(tester, 'wz-next');
    expect(find.byKey(const Key('wz-password-problem')), findsOneWidget);
    await done(tester);
  });

  testWidgets('import: look on this computer, choose, import, undo', (tester) async {
    await start(tester, size: const Size(390, 3000));
    await push(tester, const ImportScreen(panel: false, poll: Duration(milliseconds: 10)));
    await tap(tester, 'imp-way-scan');
    await tap(tester, 'imp-scan-go');
    expect(fake.saved, contains('scan home=true projects=true'));
    expect(find.text('CLAUDE.md'), findsOneWidget);
    expect(find.text('review'), findsOneWidget);
    // What is already here starts off; the person switches the skill off too.
    await tap(tester, 'imp-item-it2');
    await tap(tester, 'imp-do');
    expect(fake.applied!.map((c) => c['id']), ['it1']);
    expect(find.byKey(const Key('imp-done')), findsOneWidget);
    expect(find.byKey(const Key('imp-history')), findsOneWidget);
    await tap(tester, 'imp-done-undo');
    expect(fake.saved, contains('import undo'));
    await done(tester);
  });

  testWidgets('import (alpha 4.0): a whole project from Claude Code, cloned, with its facts', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 3000));
    await push(tester, const ImportScreen(panel: false, poll: Duration(milliseconds: 10)));
    await tap(tester, 'imp-way-scan');
    await tester.enterText(
      find.byKey(const Key('imp-scan-repos')),
      'https://git.home.lan/ana/site.git\nnot-an-address',
    );
    await tester.pump();
    await tap(tester, 'imp-scan-go');
    expect(fake.saved, contains('scan claude projects'));
    expect(fake.saved, contains('scan repos https://git.home.lan/ana/site.git'));
    expect(find.text('site'), findsOneWidget);
    expect(find.textContaining('Repository: https://git.home.lan/ana/site.git'), findsOneWidget);
    expect(find.textContaining('Restano fuori (segreti): .env'), findsOneWidget);
    // Chosen, then «Clone its repository».
    await tap(tester, 'imp-item-itp');
    await tap(tester, 'imp-mode-itp-clone');
    await tap(tester, 'imp-do');
    final project = fake.applied!.firstWhere((c) => c['id'] == 'itp');
    expect(project['mode'], 'clone');
    expect(project['knowledge'], true);
    await done(tester);
  });

  testWidgets('external agents: the list, a ready command tried and added, a secret refused', (
    tester,
  ) async {
    final app = await start(tester);
    await push(tester, const AcpScreen(panel: false));
    expect(find.text('Codex'), findsOneWidget);
    if (app.projects.isEmpty) {
      expect(find.byKey(const Key('acp-add')), findsNothing);
      await done(tester);
      return;
    }
    await tap(tester, 'acp-add');
    await tap(tester, 'acp-preset-gemini');
    await tester.enterText(find.byKey(const Key('acp-env')), 'GEMINI_API_KEY=abc');
    await tap(tester, 'acp-try');
    expect(find.text('A variable may not hold a secret'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('acp-env')), '');
    await tap(tester, 'acp-try');
    expect(find.textContaining('gemini-cli 1.2'), findsOneWidget);
    await tap(tester, 'acp-save');
    expect(fake.workers.last['command'], 'gemini');
    expect(find.text('Gemini CLI'), findsOneWidget);
    await done(tester);
  });

  testWidgets('the history of changes in sentences, undo and discard', (tester) async {
    await start(tester);
    await push(tester, const PlatformScreen(panel: false));
    expect(find.text('Alzato il limite di spesa totale da \$5.00 a \$20.00'), findsOneWidget);
    expect(find.text('Modifica al codice: A clearer bar'), findsOneWidget);
    // Not supervised: no «Promote», said why.
    expect(find.byKey(const Key('pl-promote-k1')), findsNothing);
    await tap(tester, 'pl-undo-c1');
    expect(fake.saved, contains('undo c1'));
    await tap(tester, 'pl-discard-k1');
    expect(fake.saved, contains('discard k1'));
    await done(tester);
  });

  testWidgets('the words in every conversation, the excerpt marked', (tester) async {
    await start(tester);
    await push(tester, const FullSearchScreen());
    await tester.enterText(find.byKey(const Key('fsr-field')), 'lavatrice');
    await tap(tester, 'fsr-go');
    expect(find.text('Garanzia'), findsOneWidget);
    expect(find.byKey(const Key('fsr-hit-0')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('fsr-field')), 'nulla');
    await tap(tester, 'fsr-go');
    expect(find.byKey(const Key('fsr-none')), findsOneWidget);
    await done(tester);
  });

  testWidgets('Settings: redo the setup, import, external agents, history; no «All settings»', (
    tester,
  ) async {
    await start(tester, size: const Size(390, 9000));
    await push(tester, const ServerSettingsScreen());
    for (final k in ['redo-setup', 'import', 'acp', 'platform']) {
      expect(find.byKey(Key('settings-$k')), findsOneWidget, reason: k);
    }
    expect(find.byKey(const Key('settings-all')), findsNothing);
    await tap(tester, 'settings-redo-setup');
    expect(find.byKey(const Key('wz')), findsOneWidget);
    await done(tester);
  });

  testWidgets('what is new after an update: once, then gone; never on a first install', (
    tester,
  ) async {
    final prefs = MemoryAppPrefs()..values['newsSeen'] = '3.0.0';
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: prefs,
      platform: DevicePlatform.android,
      liveEnabled: false,
    )..locale = const Locale('it');
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(RGCompanionApp(controller: app));
    await settle(tester);
    expect(find.byKey(const Key('news-band')), findsOneWidget);
    await tap(tester, 'news-dismiss');
    expect(find.byKey(const Key('news-band')), findsNothing);
    expect(prefs.values['newsSeen'], isNot('3.0.0'));
    await done(tester);
  });

  testWidgets('what is new on a computer: the window of the page, only what is newer, once', (
    tester,
  ) async {
    final prefs = MemoryAppPrefs()..values['newsSeen'] = '3.12.8';
    Future<AppController> open() async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: prefs,
        platform: DevicePlatform.linux,
        liveEnabled: false,
      )..locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await settle(tester);
      return app;
    }

    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open();
    final window = find.byKey(const Key('news-window'));
    expect(window, findsOneWidget);
    expect(find.byKey(const Key('news-band')), findsNothing);
    // Only the releases after the one this device saw, newest first.
    expect(find.text('Le novità di Rasgeth $newsVersion'), findsOneWidget);
    expect(find.text('Versione 3.12.10'), findsOneWidget);
    expect(find.text('Versione 3.12.8'), findsNothing);
    expect(find.byKey(const Key('news-news31210Models')), findsOneWidget);
    expect(find.byKey(const Key('news-news3128Projects')), findsNothing);
    final ok = find.byKey(const Key('news-ok'));
    await tester.scrollUntilVisible(
      ok,
      300,
      scrollable: find.descendant(of: window, matching: find.byType(Scrollable)).first,
    );
    await tap(tester, 'news-ok');
    expect(window, findsNothing);
    expect(prefs.values['newsSeen'], newsVersion);
    // Never again on this device.
    await tester.pumpWidget(const SizedBox());
    await open();
    expect(find.byKey(const Key('news-window')), findsNothing);
    await done(tester);
  });

  testWidgets('signed in with a setup code: a device of its own, then the wizard', (tester) async {
    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: DevicePlatform.android,
      liveEnabled: false,
    )..locale = const Locale('it');
    late bool wrong;
    late bool right;
    await tester.runAsync(() async {
      wrong = await app.connectWithSetupCode(server.base.toString(), '000000');
      right = await app.connectWithSetupCode(server.base.toString(), '482913');
    });
    expect(wrong, isFalse);
    expect(right, isTrue, reason: '${app.error} ${app.errorMessage}');
    expect(app.viaSetupCode, isTrue);
    expect(fake.saved, contains('device android'));
    expect(app.connected, isTrue);
  });
}
