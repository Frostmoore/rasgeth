// 3.9.7: Settings › Skills native, against the fake server that answers as the real one
// (test/fake_skills.dart): a new version waiting shows its reason and what changes word by word
// and is approved here (tools stay for the page); an installed skill's versions show who, why and
// the one in use; an earlier one is compared and brought back only after the person confirms; and
// the way in from Settings.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/api/skills_api.dart';
import 'package:rgcompanion/settings/prompt_refiner.dart' show WordDiffView;
import 'package:rgcompanion/settings/skills_screen.dart';

import 'fake_server.dart';
import 'fake_skills.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('reads the server\'s shapes leniently', () {
    final v = SkillVersion.fromJson({'version': 3, 'how': 'rollback', 'fromVersion': 1});
    expect(v.restorable, isTrue);
    expect(v.current, isFalse);
    expect(v.author, isNull);
    final p = SkillProposal.fromJson({
      'id': 'p',
      'name': 'x',
      'input': {
        'files': {'run.sh': 'echo', 'notes.md': 'x', 'tool': '#!/bin/sh'},
      },
      'report': [
        {'passed': true},
        {'passed': false},
      ],
    });
    expect(p.isUpdate, isFalse);
    expect(p.scripts, ['run.sh', 'tool']);
    expect(p.passed, isFalse);
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeSkills fake;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      fake = FakeSkills();
      server.skills = fake;
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: false,
            )
            ..locale = const Locale('it')
            ..reduceMotion = true;
      await tester.runAsync(() async {
        await app.connect(server.base.toString(), 'secret');
      });
      tester.view.physicalSize = const Size(420, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      return app;
    }

    Future<void> push(WidgetTester tester, Widget screen) async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
      await _settle(tester);
    }

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('a new version waiting: its reason, what changes, approved here', (tester) async {
      await start(tester);
      await push(tester, const SkillsScreen());
      expect(find.byKey(const Key('skills-settings')), findsOneWidget);
      expect(find.text('Cosa hanno imparato gli agenti'), findsOneWidget);
      expect(find.byKey(const Key('skill-waiting-prop_1')), findsOneWidget);
      // Tools are approved in the page, not here.
      expect(find.byKey(const Key('skill-waiting-prop_t')), findsNothing);
      expect(find.textContaining('Nuova versione di una skill installata'), findsOneWidget);
      expect(find.text('The due date was missed.'), findsOneWidget);
      expect(find.byKey(const Key('skill-diff-prop_1')), findsOneWidget);
      expect(find.textContaining('dalla loro conversazione successiva'), findsWidgets);
      await tap(tester, 'skill-approve-prop_1');
      expect(fake.bodies['POST /api/extensions/proposals/prop_1/decision'], {
        'decision': 'approve',
      });
      expect(find.byKey(const Key('skill-waiting-prop_1')), findsNothing);
      expect(find.text('Non ti aspetta niente.'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the versions: who, why, the one in use; compare and go back after a yes', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const SkillsScreen());
      // Only skills are listed.
      expect(find.byKey(const Key('skill-installed-csv')), findsNothing);
      await tap(tester, 'skill-installed-invoice-pdf');
      expect(find.byKey(const Key('skill-history')), findsOneWidget);
      expect(find.text('Versione 2'), findsOneWidget);
      expect(find.text('in uso'), findsOneWidget);
      expect(
        find.textContaining('installata da sola (la tua scelta in Sicurezza)'),
        findsOneWidget,
      );
      expect(find.textContaining('approvata da te'), findsOneWidget);
      expect(find.textContaining('The VAT was read from the wrong table twice.'), findsOneWidget);
      // The one in use has nothing to go back to.
      expect(find.byKey(const Key('skill-rollback-2')), findsNothing);
      await tap(tester, 'skill-compare-1');
      expect(
        find.descendant(
          of: find.byKey(const Key('skill-history')),
          matching: find.byType(WordDiffView),
        ),
        findsOneWidget,
      );
      await tap(tester, 'skill-rollback-1');
      expect(find.byKey(const Key('skill-rollback-window')), findsOneWidget);
      // Nothing happens before the yes.
      expect(fake.bodies.containsKey('POST /api/extensions/skills/invoice-pdf/rollback'), isFalse);
      await tap(tester, 'skill-rollback-yes');
      expect(fake.bodies['POST /api/extensions/skills/invoice-pdf/rollback'], {
        'version': 1,
        'scope': 'platform',
      });
      expect(find.text('Tornata alla versione 1: adesso è la versione 3.'), findsOneWidget);
      expect(find.text('Ritorno alla versione 1'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the way in: Settings › Skills', (tester) async {
      await start(tester);
      await push(tester, const ServerSettingsScreen());
      await tap(tester, 'settings-skills');
      expect(find.byKey(const Key('skills-settings')), findsOneWidget);
      await done(tester);
    });
  });
}
