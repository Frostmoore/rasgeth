// G42.4: Settings › Budgets native (the month, everything, projects and agents, the limit's
// window with the wizard's amounts), renaming a device, and the settings of every day reachable
// from «Settings of <name>».
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/budgets_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('the month\'s days and the page\'s dollars', () {
    expect(monthDays(DateTime(2026, 11, 3)), ['2026-11-01', '2026-11-02', '2026-11-03']);
    expect(usdWords(0), r'$0');
    expect(usdWords(0.004), r'$0.0040');
    expect(usdWords(12.5), r'$12.50');
    expect(kTokenWords(1200), '1k');
    expect(kTokenWords(2500000), '2.5M');
  });

  group('in the app', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 900)}) async {
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
      tester.view.physicalSize = size;
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

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    void daily() {
      server.extraJson['GET /api/budgets/daily'] = [
        {'day': '2026-11-01', 'scope': 'global', 'id': 'owner', 'usd': 1.5, 'tokens': 9000},
        {'day': '2026-11-02', 'scope': 'global', 'id': 'owner', 'usd': 0.5, 'tokens': 3000},
        {'day': '2026-11-02', 'scope': 'agent', 'id': 'a1', 'usd': 0.5, 'tokens': 3000},
      ];
    }

    testWidgets('reading: the month, everything and the agents that spent', (tester) async {
      server.budgets = [
        {
          'scope': 'global',
          'id': 'owner',
          'limit': {'usd': 50},
          'used': {'usd': 12, 'tokens': 1},
        },
        {
          'scope': 'agent',
          'id': 'a1',
          'limit': {},
          'used': {'usd': 0.5, 'tokens': 3000},
        },
      ];
      daily();
      final app = await start(tester);
      await push(tester, BudgetsScreen(now: DateTime(2026, 11, 2)));
      expect(find.text(r'$2.00'), findsOneWidget);
      expect(find.byKey(const Key('bu-chart')), findsOneWidget);
      expect(find.byKey(const Key('bu-row-global-owner')), findsOneWidget);
      expect(find.text(r'Limite $50.00'), findsOneWidget);
      final a1 = app.agents.firstWhere((a) => a.id == 'a1');
      await tester.ensureVisible(find.byKey(const Key('bu-row-agent-a1')));
      expect(find.text(a1.name), findsWidgets);
      // An agent that spent nothing and has no limit is not a row of zeros.
      expect(find.byKey(const Key('bu-row-agent-a2')), findsNothing);
      await tester.tap(find.byKey(const Key('bu-how')));
      await _settle(tester);
      expect(find.textContaining('I limiti contano tutto'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bu-how-ok')));
      await _settle(tester);
      await done(tester);
    });

    testWidgets('a limit: an amount of the wizard, another one, no limit, an error', (
      tester,
    ) async {
      server.budgets = [
        {
          'scope': 'global',
          'id': 'owner',
          'limit': {},
          'used': {'usd': 3, 'tokens': 1},
        },
      ];
      daily();
      await start(tester);
      await push(tester, BudgetsScreen(now: DateTime(2026, 11, 2)));
      await tester.tap(find.byKey(const Key('bu-row-global-owner')));
      await _settle(tester);
      expect(find.byKey(const Key('bu-limit')), findsOneWidget);
      expect(find.text('Scegli una cifra, o scrivine un\'altra.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bu-amount-20')));
      await tester.pump();
      expect(find.textContaining(r'A $20 i suoi agenti'), findsOneWidget);
      await tester.tap(find.byKey(const Key('bu-save')));
      await _settle(tester);
      expect(server.budgetPuts.single, {'scope': 'global', 'id': 'owner', 'usd': 20});
      expect(find.byKey(const Key('bu-limit')), findsNothing);
      expect(find.text(r'Limite $20.00'), findsOneWidget);

      // Another amount, written.
      await tester.tap(find.byKey(const Key('bu-row-global-owner')));
      await _settle(tester);
      await tester.enterText(find.byKey(const Key('bu-other')), '7,5');
      await tester.pump();
      await tester.tap(find.byKey(const Key('bu-save')));
      await _settle(tester);
      expect(server.budgetPuts.last['usd'], 7.5);

      // No limit: the amount goes away.
      await tester.tap(find.byKey(const Key('bu-row-global-owner')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('bu-remove')));
      await _settle(tester);
      expect(server.budgetPuts.last.containsKey('usd'), isFalse);

      // The server says no: the window stays, with why.
      server.routes['PUT /api/budgets'] = (r) =>
          server.answer(r, 400, {'error': 'usd: Number must be greater than 0'});
      await tester.tap(find.byKey(const Key('bu-row-global-owner')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('bu-amount-5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('bu-save')));
      await _settle(tester);
      expect(find.byKey(const Key('bu-error')), findsOneWidget);
      expect(find.byKey(const Key('bu-limit')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the page cannot be read: it says why', (tester) async {
      server.routes['GET /api/budgets'] = (r) => server.answer(r, 500, {'error': 'broken'});
      await start(tester);
      await push(tester, const BudgetsScreen());
      expect(find.byKey(const Key('rules-error')), findsOneWidget);
      expect(find.textContaining('broken'), findsOneWidget);
      await done(tester);
    });

    testWidgets('renaming a device, and the settings of every day', (tester) async {
      await start(tester);
      await push(tester, const ServerSettingsScreen());
      await tester.scrollUntilVisible(
        find.byKey(const Key('rename-d2')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const Key('rename-d2')));
      await _settle(tester);
      expect(find.text('Un nome nuovo per «Telefono di Mario»'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('device-name')), '  Pixel di casa  ');
      await tester.tap(find.text('Rinomina').last);
      await _settle(tester);
      expect(server.devices.firstWhere((d) => d['id'] == 'd2')['name'], 'Pixel di casa');
      expect(find.text('Pixel di casa'), findsOneWidget);
      // This device can be renamed too, never revoked from here.
      expect(find.byKey(const Key('rename-d1')), findsOneWidget);
      expect(find.byKey(const Key('revoke-d1')), findsNothing);

      // A row opens its page.
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-budgets')),
        300,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      for (final id in [
        'general',
        'agents',
        'tools',
        'commands',
        'requests',
        'safety',
        'budgets',
      ]) {
        expect(find.byKey(Key('settings-$id')), findsOneWidget, reason: id);
      }
      // «Agents at work together» lives in Commands now: no second row.
      expect(find.byKey(const Key('settings-at-work')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('settings-budgets')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-budgets')));
      await _settle(tester);
      expect(find.byKey(const Key('budgets-settings')), findsOneWidget);
      await done(tester);
    });
  });
}
