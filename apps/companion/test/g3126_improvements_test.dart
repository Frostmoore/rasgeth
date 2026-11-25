// p3.12.6: the «Improvements» in a local model's card, as the page's: the section with its four
// cards, the one dimmed with its lock and reason, the gold one we tried ourselves, the activation
// carrying No Repack, and the measurement asked first, then its window with both ways' speeds.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/settings/api/models_api.dart';
import 'package:rgcompanion/settings/models/improvements.dart';
import 'package:rgcompanion/settings/models/models_screen.dart';
import 'package:rgcompanion/theme/colors.dart';

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
  test('the engine body carries only what is on, Deep Field gating the first two', () {
    const all = EngineChoices(
      bigChunks: true,
      prefetch: true,
      noRepack: true,
      speculative: 'draft',
    );
    expect(all.body('cuda', 'm.gguf'), {'variant': 'cuda', 'model': 'm.gguf', 'noRepack': true});
    expect(all.body('cuda', 'm.gguf', stream: true, draftModel: 'small.gguf'), {
      'variant': 'cuda',
      'model': 'm.gguf',
      'stream': true,
      'bigChunks': true,
      'moePrefetch': true,
      'noRepack': true,
      'speculative': 'draft',
      'draftModel': 'small.gguf',
    });
    expect(const EngineChoices().body('cpu', 'm.gguf'), {'variant': 'cpu', 'model': 'm.gguf'});
    expect(const EngineChoices(speculative: 'mtp').body('cpu', 'm.gguf'), {
      'variant': 'cpu',
      'model': 'm.gguf',
      'speculative': 'mtp',
    });
  });

  test('the gain in words', () {
    expect(gainText(2.88, 3.21), '+11%');
    expect(gainText(10, 9), '-10%');
    expect(gainText(0, 3), '');
  });

  test('the gold of the page is in both themes', () {
    expect(RgColors.light.gold, isNot(RgColors.dark.gold));
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

    testWidgets('the section, a dimmed card with its reason and the gold one', (tester) async {
      await open(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.byKey(const Key('impr-section')), findsOneWidget);
      expect(find.text('Miglioramenti'), findsOneWidget);
      for (final id in ['prefetch', 'bigChunks', 'speculative', 'noRepack']) {
        expect(find.byKey(Key('impr-$id')), findsOneWidget, reason: id);
      }
      expect(find.text('Speculative Decoding'), findsOneWidget);
      // No MTP heads in this model: the choice is not offered.
      expect(find.byKey(const Key('impr-spec-ngram')), findsOneWidget);
      expect(find.byKey(const Key('impr-spec-mtp')), findsNothing);
      // Locked: the reason in words, and a dimmed card.
      expect(find.byKey(const Key('impr-lock-prefetch')), findsOneWidget);
      expect(find.textContaining('serve Deep Field'), findsNWidgets(2));
      final dim = tester.widget<Opacity>(
        find
            .ancestor(of: find.byKey(const Key('impr-prefetch')), matching: find.byType(Opacity))
            .first,
      );
      expect(dim.opacity, lessThan(1));
      // Gold: the star and our numbers.
      expect(find.byKey(const Key('impr-tested-noRepack')), findsOneWidget);
      expect(find.textContaining('Provato da noi su questo modello'), findsOneWidget);
      expect(find.textContaining('Scrittura da 2,88 a 3,21 token/s (+11%)'), findsOneWidget);
      expect(find.byKey(const Key('impr-tested-prefetch')), findsNothing);
      await done(tester);
    });

    testWidgets('the same in English', (tester) async {
      await open(tester, lang: 'en');
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.text('Improvements'), findsOneWidget);
      expect(find.textContaining('Tried by us on this model'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the activation carries No Repack; the measure asks first, then shows both ways', (
      tester,
    ) async {
      fm.files.add({'file': 'Qwen3-30B-A3B-Q4_K_M.gguf', 'bytes': 18500000000, 'partial': false});
      await open(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      // A switch that is locked does nothing.
      await tap(tester, 'impr-switch-prefetch');
      await tap(tester, 'impr-switch-noRepack');
      await tap(tester, 'lm-start');
      expect(fm.bodies['PUT /api/setup/engine'], {
        'engine': {'variant': 'cuda', 'model': 'Qwen3-30B-A3B-Q4_K_M.gguf', 'noRepack': true},
      });
      // The measure: asked first (No), then yes.
      await tap(tester, 'impr-measure-noRepack');
      expect(
        find.text(
          'Misurare No Repack su questo computer?'.replaceFirst('No Repack', 'Qwen3 30B A3B'),
        ),
        findsOneWidget,
      );
      await tap(tester, 'dialog-no');
      expect(fm.calls.where((c) => c.contains('improvement-test')), isEmpty);
      await tap(tester, 'impr-measure-noRepack');
      await tap(tester, 'dialog-yes');
      expect(fm.bodies['POST /api/setup/engine/improvement-test'], {
        'engine': {'variant': 'cuda', 'model': 'Qwen3-30B-A3B-Q4_K_M.gguf', 'noRepack': true},
        'improvement': 'noRepack',
      });
      expect(find.byKey(const Key('impr-run')), findsOneWidget);
      expect(find.text('Senza'), findsOneWidget);
      expect(find.text('Con'), findsOneWidget);
      expect(find.text('2,9'), findsOneWidget);
      expect(find.text('3,3'), findsOneWidget);
      await done(tester);
    });

    testWidgets('the MTP choice only where the model has it, its gold line, the activation', (
      tester,
    ) async {
      fm.files.add({'file': 'Qwen3.8-27B-Q4_K_M.gguf', 'bytes': 16500000000, 'partial': false});
      fm.files.add({'file': 'Qwen3-30B-A3B-Q4_K_M.gguf', 'bytes': 18500000000, 'partial': false});
      await open(tester);
      await tap(tester, 'lm-tab-slow');
      await tap(tester, 'lm-card-qwen3.8-27b');
      expect(find.byKey(const Key('impr-spec-mtp')), findsOneWidget);
      expect(
        find.textContaining(
          "Con l'MTP del modello. Scrittura da 2,98 a 3,88 token/s (+30%). Intel i5-12500H.",
        ),
        findsOneWidget,
      );
      await tap(tester, 'impr-spec-mtp');
      expect(find.textContaining('nessun secondo modello'), findsOneWidget);
      await tap(tester, 'lm-start');
      expect(fm.bodies['PUT /api/setup/engine'], {
        'engine': {'variant': 'cuda', 'model': 'Qwen3.8-27B-Q4_K_M.gguf', 'speculative': 'mtp'},
      });
      await done(tester);
    });

    testWidgets('the measure button needs the model on disk', (tester) async {
      await open(tester);
      await tap(tester, 'lm-card-qwen3-30b');
      expect(find.byKey(const Key('impr-measure-noRepack')), findsNothing);
      await done(tester);
    });
  });
}
