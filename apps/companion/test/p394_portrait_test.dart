// 3.9.4: Settings › Portrait («Mirror») native, against the fake server that answers as the real
// one (test/fake_portrait.dart): the traits grouped with how sure and where each comes from, «Not
// true», «Remove», «Change» with its category, who reads it, the agents' text, a secret refused in
// words, «Forget everything» said first, and the way in from Settings.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/api/portrait_api.dart';
import 'package:rgcompanion/settings/portrait_screen.dart';

import 'fake_portrait.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('reads the server\'s shapes leniently', () {
    final v = PortraitView.fromJson({
      'traits': [
        {'id': 'a', 'text': 'x', 'category': 'nope', 'confidence': 0.5},
      ],
    });
    expect(v.on, isTrue);
    expect(v.agents.others, isFalse);
    expect(v.traits.single.category, 'about');
    expect(v.agents.withValue('others', true).toJson(), {
      'god': true,
      'orchestrators': true,
      'chat': true,
      'others': true,
    });
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakePortrait fake;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      fake = FakePortrait();
      server.portrait = fake;
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

    testWidgets('the traits grouped, how sure, where each comes from', (tester) async {
      await start(tester);
      await push(tester, const PortraitScreen());
      expect(find.byKey(const Key('portrait-settings')), findsOneWidget);
      expect(find.text('Come ti vedono gli agenti'), findsOneWidget);
      // Groups in the page's order.
      final groups = [
        for (final c in ['preference', 'style', 'project'])
          tester.getTopLeft(find.byKey(Key('portrait-group-$c'))).dy,
      ];
      expect(groups, orderedEquals([...groups]..sort()));
      expect(find.text('Sicuro'), findsOneWidget);
      expect(find.text('Probabile'), findsOneWidget);
      expect(find.text('Scritto da te'), findsOneWidget);
      expect(find.textContaining('visto 3 volte'), findsOneWidget);
      expect(find.byKey(const Key('portrait-denied')), findsOneWidget);
      // A trait without a source has no «Where it comes from».
      expect(find.byKey(const Key('portrait-where-t2')), findsNothing);
      await tap(tester, 'portrait-where-t1');
      expect(find.text('«Release notes»'), findsOneWidget);
      await tap(tester, 'portrait-source-sess-1');
      expect(find.byType(ConversationScreen), findsOneWidget);
      await done(tester);
    });

    testWidgets('not true, remove, change with its category; a secret refused in words', (
      tester,
    ) async {
      await start(tester);
      await push(tester, const PortraitScreen());
      await tap(tester, 'portrait-deny-t2');
      expect(fake.calls, contains('POST /api/portrait/t2/deny'));
      expect(find.byKey(const Key('portrait-trait-t2')), findsNothing);
      expect(find.textContaining('2 tratti che hai detto non veri'), findsOneWidget);
      await tap(tester, 'portrait-edit-t1');
      await tester.enterText(find.byKey(const Key('portrait-edit-field')), 'Wants a password: x');
      await tap(tester, 'portrait-edit-cat-avoid');
      await tap(tester, 'portrait-edit-save');
      expect(find.byKey(const Key('portrait-edit-error')), findsOneWidget);
      expect(find.textContaining('i segreti non entrano mai nel ritratto'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('portrait-edit-field')),
        'Prefers very short answers',
      );
      await tap(tester, 'portrait-edit-save');
      expect(fake.bodies['PUT /api/portrait/t1'], {
        'text': 'Prefers very short answers',
        'category': 'avoid',
      });
      expect(find.text('Prefers very short answers'), findsOneWidget);
      await tap(tester, 'portrait-remove-t3');
      expect(fake.calls, contains('DELETE /api/portrait/t3'));
      await done(tester);
    });

    testWidgets('who reads it, the text, add by hand, forget everything', (tester) async {
      await start(tester);
      await push(tester, const PortraitScreen());
      await tap(tester, 'portrait-who-others');
      expect(fake.bodies['PUT /api/portrait/settings'], {
        'agents': {'god': true, 'orchestrators': true, 'chat': true, 'others': true},
      });
      await tap(tester, 'portrait-text-toggle');
      expect(find.byKey(const Key('portrait-text')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('portrait-add-field')), 'Likes examples');
      await _settle(tester);
      await tap(tester, 'portrait-add-cat-style');
      await tap(tester, 'portrait-add');
      expect(fake.bodies['POST /api/portrait'], {'text': 'Likes examples', 'category': 'style'});
      // Forget everything: said first; «Cancel» does nothing.
      await tap(tester, 'portrait-forget');
      expect(find.byKey(const Key('portrait-forget-window')), findsOneWidget);
      await tap(tester, 'portrait-forget-yes');
      expect(fake.calls, contains('POST /api/portrait/forget'));
      expect(
        find.text('Ancora nessun tratto: il ritratto si riempie mentre parli con gli agenti.'),
        findsOneWidget,
      );
      await tap(tester, 'portrait-on');
      expect(fake.bodies['PUT /api/portrait/settings'], {'on': false});
      await done(tester);
    });

    testWidgets('the way in: Settings › Portrait', (tester) async {
      await start(tester);
      await push(tester, const ServerSettingsScreen());
      await tap(tester, 'settings-portrait');
      expect(find.byKey(const Key('portrait-settings')), findsOneWidget);
      await done(tester);
    });
  });
}
