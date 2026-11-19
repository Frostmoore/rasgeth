// G42.4: Settings › General, native, against the fake Rasgeth (real HTTP, the page's routes): the
// look and the languages, the agents' language picker, the instructions for every agent with the
// refiner's before and after, the backup model, web search (try, save, the environment's lock),
// voice messages, pictures, debug mode, what's new and an error; the word diff against the page's
// own answers (tool/general_words.mjs).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/screens/new_agent_screen.dart' show RgSwitch;
import 'package:rgcompanion/settings/general_screen.dart';
import 'package:rgcompanion/settings/general_types.dart';
import 'package:rgcompanion/settings/general_words.g.dart';
import 'package:rgcompanion/settings/prompt_refiner.dart';
import 'package:rgcompanion/settings/word_diff.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<Map<String, dynamic>> _body(HttpRequest r) async =>
    jsonDecode(await utf8.decodeStream(r)) as Map<String, dynamic>;

void main() {
  group('from the page', () {
    test('the word diff gives the page\'s own parts and counts', () {
      final vectors =
          jsonDecode(File('test/fixtures/word_diff_vectors.json').readAsStringSync()) as List;
      expect(vectors, isNotEmpty);
      for (final v in vectors.cast<Map<String, dynamic>>()) {
        final parts = wordDiff(v['before'] as String, v['after'] as String);
        expect(
          [
            for (final p in parts) {'kind': p.kind.name, 'text': p.text},
          ],
          v['parts'],
          reason: '${v['before']} -> ${v['after']}',
        );
        final n = diffCounts(parts);
        expect({'del': n.del, 'add': n.add}, v['counts']);
      }
    });

    test('languages, search services and news come from the protocol and the page', () {
      expect(agentLanguages.first.code, 'it');
      expect(agentLanguages.where((l) => l.common).length, greaterThan(5));
      expect([for (final p in searchProviders) p.id], contains('searxng'));
      expect(sttProviders.map((p) => p.id), contains('openai'));
      expect(newsRows.first.version, newsVersion);
      for (final r in newsRows) {
        expect(generalWords['it']![r.title], isNotNull);
        expect(generalWords['en']![r.text], isNotNull);
      }
      final groups = newsSince(null, newsRows);
      expect(groups.first.version, newsVersion);
      expect(compareVersions('3.5.9', '3.5.10'), lessThan(0));
      expect(matchLanguages('francais').map((l) => l.code), contains('fr'));
    });

    test('tokens and cost as the page says them', () {
      final it = AppLocalizationsIt();
      expect(aboutTokens(it, 12), '12');
      expect(aboutTokens(it, 4203), '4.200');
      expect(refineCostWords(it, 4203, null), contains('4.200 token'));
    });
  });

  group('the screen', () {
    late FakeRedGiant server;
    final puts = <String, List<Map<String, dynamic>>>{};
    var debug = {'enabled': false, 'forced': false, 'bytes': 2048, 'files': 2};

    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      puts.clear();
      debug = {'enabled': false, 'forced': false, 'bytes': 2048, 'files': 2};
      final config = server.setup['config'] as Map<String, dynamic>;
      server.setup['canRunSearch'] = false;
      for (final p in [
        '/api/setup/languages',
        '/api/setup/instructions',
        '/api/setup/backup-model',
        '/api/setup/models',
        '/api/setup/media-native',
      ]) {
        server.routes['PUT $p'] = (r) async {
          final b = await _body(r);
          puts.putIfAbsent(p, () => []).add(b);
          if (p.endsWith('instructions')) config['instructions'] = b['text'];
          if (p.endsWith('languages') && b['agentLanguage'] != null) {
            config['agentLanguage'] = b['agentLanguage'];
          }
          if (p.endsWith('backup-model')) {
            b['model'] == null
                ? config.remove('backupModel')
                : config['backupModel'] = b['model'] as Object;
          }
          if (p.endsWith('models') && b['search'] != null) {
            config['searchProvider'] = (b['search'] as Map)['provider'];
          }
          return server.answer(r, 200, {'ok': true});
        };
      }
      server.routes['POST /api/setup/search/try'] = (r) async {
        final b = await _body(r);
        puts.putIfAbsent('try', () => []).add(b);
        return server.answer(r, 200, {'results': 7, 'first': 'Rasgeth'});
      };
      server.routes['GET /api/debug'] = (r) => server.answer(r, 200, debug);
      server.routes['PUT /api/debug'] = (r) async {
        final b = await _body(r);
        debug = {...debug, 'enabled': b['enabled'] == true};
        return server.answer(r, 200, debug);
      };
      server.routes['DELETE /api/debug/logs'] = (r) async {
        debug = {...debug, 'bytes': 0, 'files': 0};
        return server.answer(r, 200, debug);
      };
      server.routes['GET /api/debug/logs'] = (r) async {
        r.response.headers.contentType = ContentType.binary;
        r.response.add([1, 2, 3]);
        await r.response.close();
      };
    });
    tearDown(() => server.close());

    Future<AppController> start(
      WidgetTester tester, {
      Size size = const Size(420, 900),
      Locale locale = const Locale('it'),
    }) async {
      final app =
          AppController(
              tokens: MemoryTokenStore(),
              prefs: MemoryAppPrefs(),
              platform: DevicePlatform.android,
              liveEnabled: false,
            )
            ..locale = locale
            ..reduceMotion = true;
      await tester.runAsync(() async {
        await app.connect(server.base.toString(), 'secret');
      });
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const GeneralSettingsScreen())).ignore();
      await _settle(tester);
      return app;
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    /// Scrolls to [key] when the list has not built it yet, taps it, waits for the answer and
    /// for a route to come or go.
    Future<void> show(WidgetTester tester, Key key) async {
      if (find.byKey(key).evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          find.byKey(key),
          200,
          scrollable: find.byType(Scrollable).last,
        );
      }
      await tester.ensureVisible(find.byKey(key));
      await tester.pumpAndSettle();
    }

    Future<void> tap(WidgetTester tester, Key key) async {
      await show(tester, key);
      await tester.tap(find.byKey(key));
      await _settle(tester);
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('reads the setup: squares lit when set, the agents\' language in its own name', (
      tester,
    ) async {
      final config = server.setup['config'] as Map<String, dynamic>;
      config['agentLanguage'] = 'fr';
      config['instructions'] = 'Rispondi breve.';
      await start(tester);
      expect(find.text('Come vuoi Rasgeth?'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);
      expect(find.text('Francese · cambia'), findsOneWidget);
      expect(find.text('scritte'), findsOneWidget);
      // Voice messages are on (the fake's local whisper), pictures are not.
      await show(tester, const Key('general-tile-images'));
      expect(
        find.descendant(
          of: find.byKey(const Key('general-tile-voice')),
          matching: find.text('acceso'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('general-tile-images')),
          matching: find.text('acceso'),
        ),
        findsNothing,
      );
      expect(find.byKey(const Key('general-tile-debug')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the agents\' language: search, pick, saved through the page\'s route', (
      tester,
    ) async {
      await start(tester);
      await tap(tester, const Key('general-agent-lang'));
      expect(find.byKey(const Key('general-languages')), findsOneWidget);
      expect(find.text('Le più usate'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('general-lang-search')), 'deutsch');
      await tester.pumpAndSettle();
      await tap(tester, const Key('lang-de'));
      expect(puts['/api/setup/languages']!.single, {'agentLanguage': 'de'});
      expect(find.byKey(const Key('general-languages')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('general-agent-lang')),
          matching: find.text('Deutsch'),
        ),
        findsOneWidget,
      );
      await done(tester);
    });

    testWidgets('the interface\'s language changes the app and tells the server', (tester) async {
      final app = await start(tester);
      await tap(tester, const Key('general-ui-lang-en'));
      expect(app.locale, const Locale('en'));
      expect(puts['/api/setup/languages']!.single, {'language': 'en'});
      expect(find.text('Interface language'), findsOneWidget);
      await tap(tester, const Key('general-theme-dark'));
      expect(app.themeMode, ThemeMode.dark);
      await done(tester);
    });

    testWidgets('instructions for every agent: refine with the diff, use, save', (tester) async {
      await start(tester);
      await tap(tester, const Key('general-tile-instructions'));
      expect(find.byKey(const Key('general-instructions')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('general-instructions-text')), 'Be kind.');
      await tester.pumpAndSettle();
      await tap(tester, const Key('refine-open'));
      expect(find.byKey(const Key('refine-writer')), findsOneWidget);
      expect(find.text('Stima: circa 4.200 token, meno di un centesimo.'), findsOneWidget);
      expect(server.refines.last['target'], {'general': true});
      await tap(tester, const Key('refine-go'));
      expect(find.byKey(const Key('refine-diff')), findsOneWidget);
      expect(find.byKey(const Key('refine-count')), findsOneWidget);
      expect(find.text('Added: answer briefly.'), findsOneWidget);
      await tap(tester, const Key('refine-use'));
      expect(find.text('La versione nuova è nel campo: salva per tenerla.'), findsOneWidget);
      expect(puts['/api/setup/instructions'], isNull);
      await tap(tester, const Key('general-instructions-save'));
      expect(puts['/api/setup/instructions']!.single['text'], 'Be kind.\nAnswer briefly.');
      expect(find.byKey(const Key('general-instructions-saved')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the refiner\'s writer model is chosen and remembered', (tester) async {
      final app = await start(tester);
      await tap(tester, const Key('general-tile-instructions'));
      await tester.enterText(find.byKey(const Key('general-instructions-text')), 'Be kind.');
      await tap(tester, const Key('refine-open'));
      await tap(tester, const Key('refine-writer'));
      await tester.tap(find.byKey(const Key('model-anthropic/claude-haiku-5')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('model-use')));
      await _settle(tester);
      expect(await app.prefs.get('refiner.model'), contains('claude-haiku-5'));
      await tap(tester, const Key('refine-go'));
      expect((server.refines.last['model'] as Map)['model'], 'claude-haiku-5');
      await done(tester);
    });

    testWidgets('a refusal says why, in words', (tester) async {
      server.refineFails = 'no_model';
      await start(tester);
      await tap(tester, const Key('general-tile-instructions'));
      await tester.enterText(find.byKey(const Key('general-instructions-text')), 'Be kind.');
      await tap(tester, const Key('refine-open'));
      await tap(tester, const Key('refine-go'));
      expect(find.byKey(const Key('refine-error')), findsOneWidget);
      expect(
        find.text('Nessun modello collegato: collegane uno in Impostazioni, Modelli.'),
        findsOneWidget,
      );
      await done(tester);
    });

    testWidgets('the backup model: chosen in the sheet, «None» takes it away', (tester) async {
      await start(tester);
      await tap(tester, const Key('general-tile-backup'));
      await tester.tap(find.byKey(const Key('model-anthropic/claude-haiku-5')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('model-use')));
      await _settle(tester);
      expect((puts['/api/setup/backup-model']!.single['model'] as Map)['model'], 'claude-haiku-5');
      expect(
        find.descendant(
          of: find.byKey(const Key('general-tile-backup')),
          matching: find.textContaining('Haiku'),
        ),
        findsOneWidget,
      );
      await tap(tester, const Key('general-tile-backup'));
      await tester.tap(find.byKey(const Key('model-inherit')));
      await _settle(tester);
      expect(puts['/api/setup/backup-model']!.last['model'], isNull);
      await done(tester);
    });

    testWidgets('web search: a service with a key, tried then used', (tester) async {
      await start(tester);
      await tap(tester, const Key('general-tile-search'));
      await tap(tester, const Key('search-brave'));
      expect(find.text('Come configurare Brave Search'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('search-key')), 'BSA-123456');
      await tap(tester, const Key('search-try'));
      expect(puts['try']!.single, {'provider': 'brave', 'key': 'BSA-123456'});
      expect(find.text('Funziona: 7 risultati, il primo «Rasgeth».'), findsOneWidget);
      await tap(tester, const Key('search-use'));
      expect(puts['/api/setup/models']!.single, {
        'search': {'provider': 'brave', 'key': 'BSA-123456'},
      });
      expect(
        find.text('Da ora i modelli che non sanno cercare da soli usano Brave Search.'),
        findsOneWidget,
      );
      await done(tester);
    });

    testWidgets('set by the environment: shown, never changed', (tester) async {
      server.setup['locked'] = {'search': true, 'images': true};
      await start(tester);
      await tap(tester, const Key('general-tile-search'));
      expect(find.text('impostato dall\'ambiente'), findsOneWidget);
      expect(find.byKey(const Key('search-use')), findsNothing);
      await done(tester);
    });

    testWidgets('voice messages: a cloud provider needs its key, then saves', (tester) async {
      await start(tester);
      await tap(tester, const Key('general-tile-voice'));
      await tap(tester, const Key('voice-kind-openai'));
      await tap(tester, const Key('voice-save'));
      expect(find.text('Incolla prima la chiave di OpenAI.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('voice-key')), 'sk-proj-123456789');
      await tap(tester, const Key('voice-save'));
      final t = puts['/api/setup/models']!.single['transcription'] as Map;
      expect(t['api'], 'cloud');
      expect(t['provider'], 'openai');
      expect(t['model'], sttProviders.first.models.first.id);
      expect(t['key'], 'sk-proj-123456789');
      expect(find.byKey(const Key('voice-result')), findsOneWidget);
      await done(tester);
    });

    testWidgets('pictures: key and model', (tester) async {
      await start(tester);
      await tap(tester, const Key('general-tile-images'));
      await tester.enterText(find.byKey(const Key('images-key')), 'sk-images');
      await tester.enterText(find.byKey(const Key('images-model')), 'gpt-image-2.5-flare');
      await tap(tester, const Key('images-save'));
      expect(puts['/api/setup/models']!.single, {
        'images': {'key': 'sk-images', 'model': 'gpt-image-2.5-flare'},
      });
      await done(tester);
    });

    testWidgets('pictures: the model\'s own tool first, on by default, switched off', (
      tester,
    ) async {
      await start(tester);
      await tap(tester, const Key('general-tile-images'));
      expect(find.text('Usa lo strumento del modello quando c\'è'), findsOneWidget);
      expect(tester.widget<RgSwitch>(find.byType(RgSwitch).first).on, isTrue);
      await tap(tester, const Key('media-native-switch'));
      expect(puts['/api/setup/media-native']!.single, {'on': false});
      expect(tester.widget<RgSwitch>(find.byType(RgSwitch).first).on, isFalse);
      await done(tester);
    });

    testWidgets('debug mode: switch, download, delete', (tester) async {
      Uint8List? got;
      debugSaveLogs = (name, bytes) async {
        got = bytes;
        return true;
      };
      addTearDown(() => debugSaveLogs = null);
      await start(tester);
      await tap(tester, const Key('general-tile-debug'));
      expect(find.text('Registri tenuti: 2.0 KB in 2 file.'), findsOneWidget);
      await tap(tester, const Key('debug-switch'));
      expect(debug['enabled'], isTrue);
      await tap(tester, const Key('debug-download'));
      expect(got, [1, 2, 3]);
      await tap(tester, const Key('debug-clear'));
      await tester.tap(find.byKey(const Key('dialog-yes')));
      await _settle(tester);
      expect(debug['files'], 0);
      await done(tester);
    });

    testWidgets('what\'s new: every release, newest first', (tester) async {
      await start(tester);
      await tap(tester, const Key('general-tile-news'));
      expect(find.byKey(const Key('news-list')), findsOneWidget);
      expect(find.text('Versione $newsVersion'), findsOneWidget);
      expect(find.text(generalWords['it']![newsRows.first.title]!), findsOneWidget);
      await done(tester);
    });

    testWidgets('a failure says so', (tester) async {
      server.routes['GET /api/setup'] = (r) => server.answer(r, 500, {'error': 'boom'});
      await start(tester);
      expect(find.byKey(const Key('general-error')), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
      await done(tester);
    });

    testWidgets('on a computer it opens as a window', (tester) async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )..locale = const Locale('en');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      tester.view.physicalSize = const Size(1280, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      final ctx = tester.element(find.byType(Navigator).first);
      openGeneralSettings(ctx).ignore();
      await _settle(tester);
      expect(find.byKey(const Key('general-window')), findsOneWidget);
      expect(find.text('How do you want Rasgeth?'), findsOneWidget);
      await done(tester);
    });
  });
}
