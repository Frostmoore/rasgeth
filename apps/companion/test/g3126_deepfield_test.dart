// p3.12.6: Deep Field's switch in the computer's box, as the page's: on and off with its line, the
// reason when the computer cannot, «How it works», the plan, the model list asked with `stream`, the
// improvements it unlocks and the activation carrying it.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/settings/api/models_api.dart';
import 'package:rgcompanion/settings/models/models_screen.dart';

import 'fake_models.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  test('availability as the page computes it', () {
    ModelsSetup with_(Map<String, dynamic> hw) =>
        ModelsSetup({'config': <String, dynamic>{}, 'hardware': hw});
    expect(with_({}).streamAvailability('cuda').warn, 'unknownDisk');
    final hdd = with_({
      'disks': [
        {'name': '/', 'freeGb': 900, 'ssd': false},
      ],
    }).streamAvailability('cuda');
    expect((hdd.ok, hdd.reason), (false, 'hdd'));
    final small = with_({
      'disks': [
        {'name': '/', 'freeGb': 12.0, 'ssd': true},
      ],
    }).streamAvailability('cuda');
    expect((small.ok, small.reason, small.freeGb), (false, 'noRoom', 12.0));
    final maybe = with_({
      'modelDisk': {'windows': 'D'},
      'disks': [
        {'name': 'C', 'freeGb': 5, 'ssd': false},
        {'name': 'D', 'freeGb': 300, 'ssd': null},
      ],
    }).streamAvailability('windows');
    expect((maybe.ok, maybe.warn, maybe.disk), (true, 'maybeSsd', 'D'));
  });

  group('in the app', () {
    late FakeRedGiant server;
    late FakeModels fm;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      fm = FakeModels(server.setup);
      server.modelsFake = fm;
    });
    tearDown(() => server.close());

    void disk({bool ssd = true, double free = 500}) {
      (server.setup['hardware'] as Map<String, dynamic>)['disks'] = [
        {'name': '/', 'freeGb': free, 'ssd': ssd},
      ];
    }

    Future<void> open(WidgetTester tester, {String lang = 'it'}) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: false,
            )
            ..locale = Locale(lang)
            ..reduceMotion = true;
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(420, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ModelsScreen(poll: false, openUrl: (_) async => true),
            ),
          )
          .ignore();
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

    testWidgets('the switch shows and toggles, asking the list with stream', (tester) async {
      disk();
      await open(tester);
      expect(find.byKey(const Key('lm-stream-switch')), findsOneWidget);
      expect(
        find.text('Spento: girano solo i modelli che stanno nella scheda e nella RAM.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('lm-stream-why')), findsNothing);
      expect(fm.queries.last, isNot(contains('stream')));
      await tap(tester, 'lm-stream-switch');
      expect(fm.queries.last, contains('stream=1'));
      expect(find.textContaining('Acceso'), findsOneWidget);
      await tap(tester, 'lm-stream-switch');
      expect(fm.queries.last, isNot(contains('stream')));
      await done(tester);
    });

    testWidgets('how it works opens its dialog', (tester) async {
      disk();
      await open(tester, lang: 'en');
      await tap(tester, 'lm-stream-how');
      expect(find.byKey(const Key('lm-stream-info')), findsOneWidget);
      expect(find.textContaining('mixture-of-experts'), findsOneWidget);
      await tap(tester, 'kb-window-close');
      expect(find.byKey(const Key('lm-stream-info')), findsNothing);
      await done(tester);
    });

    testWidgets('disabled with its reason when the disk is spinning', (tester) async {
      disk(ssd: false);
      await open(tester, lang: 'en');
      expect(find.byKey(const Key('lm-stream-why')), findsOneWidget);
      expect(find.textContaining('is a spinning disk'), findsOneWidget);
      await tap(tester, 'lm-stream-switch');
      expect(fm.queries.where((q) => q.contains('stream')), isEmpty);
      await done(tester);
    });

    testWidgets('disabled with its reason when there is no room', (tester) async {
      disk(free: 8);
      await open(tester, lang: 'en');
      expect(find.textContaining('has only 8.0 GB free'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the plan shows when the engine runs with it', (tester) async {
      disk();
      (server.setup['config'] as Map<String, dynamic>)['engine'] = {
        'variant': 'cuda',
        'model': 'Qwen3-30B-A3B-Q4_K_M.gguf',
        'stream': true,
        'plan': {
          'ctx': 32768,
          'moeCacheMib': 2048,
          'source': 'ssd',
          'ssdGbPerWord': 1.25,
          'ramGb': 40,
        },
      };
      await open(tester, lang: 'en');
      expect(find.byKey(const Key('lm-stream-plan')), findsOneWidget);
      expect(find.textContaining('context up to 32k'), findsOneWidget);
      expect(find.textContaining('1.25 GB'), findsOneWidget);
      expect(fm.queries.last, contains('stream=1'));
      await done(tester);
    });

    testWidgets('Prefetch unlocks with it on and the activation carries stream', (tester) async {
      disk();
      fm.files.add({'file': 'Qwen3-30B-A3B-Q4_K_M.gguf', 'bytes': 18500000000, 'partial': false});
      await open(tester);
      await tap(tester, 'lm-stream-switch');
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.byKey(const Key('impr-lock-prefetch')), findsNothing);
      await tap(tester, 'impr-switch-prefetch');
      await tap(tester, 'lm-start');
      expect(fm.bodies['PUT /api/setup/engine'], {
        'engine': {
          'variant': 'cuda',
          'model': 'Qwen3-30B-A3B-Q4_K_M.gguf',
          'stream': true,
          'moePrefetch': true,
        },
      });
      await done(tester);
    });

    testWidgets('with it off Prefetch stays locked and no stream goes out', (tester) async {
      disk();
      await open(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.byKey(const Key('impr-lock-prefetch')), findsOneWidget);
      await done(tester);
    });
  });
}
