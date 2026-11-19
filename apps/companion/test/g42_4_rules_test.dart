// G42.4: Settings › Requests, Safety, Tools and Commands, native, against the fake server with the
// page's routes and answers: reading, changing (the body sent as the page sends it), «Undo», an
// error, the essential tools that never switch off, and the agents at work inside Commands.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations_en.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/l10n/rule_words.g.dart';
import 'package:rgcompanion/settings/api/rules_api.dart';
import 'package:rgcompanion/settings/commands_screen.dart';
import 'package:rgcompanion/settings/requests_screen.dart';
import 'package:rgcompanion/settings/rules_kit.dart';
import 'package:rgcompanion/settings/safety_screen.dart';
import 'package:rgcompanion/settings/tool_kits.dart';
import 'package:rgcompanion/settings/tools_screen.dart';

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
  group('pure rules', () {
    test('spans and presets as the page', () {
      final it = AppLocalizationsIt();
      final en = AppLocalizationsEn();
      expect(spanWords(it, 10 * 60000), '10 min');
      expect(spanWords(it, 3600000), '1 ora');
      expect(spanWords(en, 6 * 3600000), '6 h');
      expect(spanWords(it, 7 * 86400000), '7 giorni');
      expect(spanWords(en, 86400000), '1 day');
      expect(presetOf([...safetyPresets['free']!].reversed.toList()), 'free');
      expect(presetOf(dangerIds), 'careful');
      expect(presetOf(['git-push']), isNull);
    });

    test('the essential tools never go into the list switched off', () {
      final view = ToolsView.fromJson({
        'entries': [
          {'id': 'read_file', 'group': 'files', 'essential': true, 'global': true, 'tokens': 40},
          {'id': 'grep', 'group': 'files', 'global': false, 'tokens': 30},
          {'id': 'fetch', 'group': 'web', 'global': true, 'tokens': 50},
        ],
      });
      expect(toolsOffAfter(view.entries, 'fetch', false), ['grep', 'fetch']);
      expect(toolsOffAfter(view.entries, 'read_file', false), ['grep']);
      expect(toolsOffAfter(view.entries, 'grep', true), isEmpty);
      final flipped = view.flipped('fetch', false);
      expect(flipped.total, 40);
      expect(flipped.saved, 80);
    });

    test('the protocol words are both languages', () {
      for (final lang in ['it', 'en']) {
        for (final id in criticalIds) {
          expect(ruleWords[lang]!.critical[id]!.examples, isNotEmpty);
        }
        for (final id in dangerIds) {
          expect(ruleWords[lang]!.dangers[id]!.name, isNot(id));
        }
      }
    });
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

    /// Scrolls the page until [f] is built and on screen (the page's list builds lazily).
    Future<void> reveal(WidgetTester tester, Finder f) async {
      final list = find
          .descendant(of: find.byType(RulesPage), matching: find.byType(Scrollable))
          .first;
      if (f.evaluate().isEmpty) {
        // Down first, then up: the list keeps only what is near the screen.
        final pos = tester.state<ScrollableState>(list).position;
        await tester.scrollUntilVisible(
          f,
          pos.pixels >= pos.maxScrollExtent ? -250 : 250,
          scrollable: list,
          maxScrolls: 80,
        );
      }
      await tester.ensureVisible(f);
      await tester.pump();
    }

    Future<void> tap(WidgetTester tester, String key) async {
      await reveal(tester, find.byKey(Key(key)));
      await tester.tap(find.byKey(Key(key)));
      await _settle(tester);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    final undos = <String>[];
    void undoRoute(FakeRedGiant s) {
      s.routes['POST /api/platform/changes/chg7/undo'] = (r) async {
        undos.add('chg7');
        await s.answer(r, 200, {'id': 'chg7'});
      };
    }

    testWidgets('Requests: read, «Don\'t ask me anything», the time, save and undo', (
      tester,
    ) async {
      var settings = <String, dynamic>{'mode': 'ask', 'timeoutMs': null, 'afterTimeout': 'no'};
      final puts = <Map<String, dynamic>>[];
      server.routes['GET /api/settings/requests'] = (r) => server.answer(r, 200, {
        'settings': settings,
        'defaults': {'mode': 'ask', 'timeoutMs': null, 'afterTimeout': 'no'},
        'defaultModel': {'provider': 'anthropic', 'model': 'claude-haiku-4-5'},
        'critical': criticalIds,
      });
      server.routes['PUT /api/settings/requests'] = (r) async {
        final b = await _body(r);
        puts.add(b);
        settings = b;
        await server.answer(r, 200, {'id': 'chg7'});
      };
      server.routes['GET /api/unattended'] = (r) => server.answer(r, 200, [
        {
          'id': 'u1',
          'requestId': 'q1',
          'kind': 'approval',
          'agentId': 'a1',
          'agentName': 'Orso',
          'projectId': null,
          'sessionId': 's1',
          'what': 'git push origin main',
          'danger': ['git-push'],
          'decision': 'allow',
          'by': 'classifier',
          'reason': 'An ordinary push of the work asked.',
          'model': 'anthropic/claude-haiku-4-5',
          'createdAt': '2026-11-17T10:00:00.000Z',
        },
      ]);
      undoRoute(server);
      await start(tester);
      await push(tester, const RequestsScreen());
      expect(find.text('Quando un agente ha bisogno di te'), findsOneWidget);
      // With «Ask me» and no time limit, no classifier card.
      expect(find.byKey(const Key('rq-classifier')), findsNothing);
      await tap(tester, 'rq-mode-classifier');
      await reveal(tester, find.byKey(const Key('rq-classifier')));
      expect(find.byKey(const Key('rq-classifier')), findsOneWidget);
      expect(find.textContaining('Il modello leggero ('), findsOneWidget);
      await tap(tester, 'rq-time-900000');
      expect(find.text('Se non rispondi entro 15 min, è un no.'), findsOneWidget);
      await tap(tester, 'rules-save');
      expect(puts.single, {'mode': 'classifier', 'timeoutMs': 900000, 'afterTimeout': 'no'});
      expect(find.text('Salvato: vale dalla prossima richiesta.'), findsOneWidget);
      await tap(tester, 'rules-undo');
      expect(undos, ['chg7']);
      expect(find.byKey(const Key('rules-undone')), findsOneWidget);
      await reveal(tester, find.byKey(const Key('rq-critical-critical-delete')));
      expect(find.byKey(const Key('rq-critical-critical-delete')), findsOneWidget);
      expect(find.text('Cancellare per sempre cose importanti'), findsOneWidget);
      // The decision taken without the person, with its reason and the danger's words.
      await reveal(tester, find.byKey(const Key('rq-decision-u1')));
      expect(find.text('Mandare il codice online'), findsOneWidget);
      expect(find.textContaining('An ordinary push'), findsOneWidget);
      await done(tester);
    });

    testWidgets('Requests: an error says why', (tester) async {
      server.routes['GET /api/settings/requests'] = (r) =>
          server.answer(r, 500, {'error': 'settings broken'});
      await start(tester);
      await push(tester, const RequestsScreen());
      expect(find.byKey(const Key('rules-error')), findsOneWidget);
      expect(find.textContaining('settings broken'), findsOneWidget);
      await done(tester);
    });

    testWidgets('Safety: read, a preset, the custom switches, save', (tester) async {
      final puts = <Map<String, dynamic>>[];
      server.setup = {
        ...server.setup,
        'policy': {
          'humanOnly': [...safetyPresets['balanced']!],
          'disabledDanger': [],
          'guardian': 'ask',
          'skills': 'ask',
          'dangers': [
            for (final d in dangerIds) {'id': d},
          ],
        },
        'budgetUsd': 50,
        'config': {...server.setup['config'] as Map<String, dynamic>, 'retentionDays': 90},
      };
      server.routes['PUT /api/setup/safety'] = (r) async {
        puts.add(await _body(r));
        await server.answer(r, 200, {'ok': true});
      };
      await start(tester);
      await push(tester, const SafetyScreen());
      expect(find.text('Sicurezza e costi'), findsWidgets);
      expect(find.textContaining('Approvi tu quello che non si può annullare'), findsOneWidget);
      await tap(tester, 'sf-guardian-auto');
      await tap(tester, 'sf-preset-free');
      await tap(tester, 'sf-personalize');
      expect(find.byKey(const Key('sf-custom')), findsOneWidget);
      await tap(tester, 'sf-danger-git-push');
      await tap(tester, 'sf-custom-done');
      expect(
        find.text('Una scelta tua: 3 cose su ${dangerIds.length} le approvi solo tu.'),
        findsOneWidget,
      );
      await tap(tester, 'sf-budget-100');
      await tap(tester, 'sf-keep-30');
      await tap(tester, 'rules-save');
      expect(puts.single, {
        'guardian': 'auto',
        'skills': 'ask',
        'humanOnly': ['platform', 'secrets-files', 'git-push'],
        'budgetUsd': 100,
        'retentionDays': 30,
      });
      expect(find.byKey(const Key('rules-saved')), findsOneWidget);
      await done(tester);
    });

    testWidgets('Safety: nothing paid per use, no limit to set; a refusal is said', (tester) async {
      server.setup = {
        ...server.setup,
        'secretsSet': {'keys': <String>[]},
        'policy': {'humanOnly': <String>[], 'dangers': <Object>[]},
        'budgetUsd': null,
      };
      final puts = <Map<String, dynamic>>[];
      server.routes['PUT /api/setup/safety'] = (r) async {
        puts.add(await _body(r));
        await server.answer(r, 403, {'error': 'only the owner'});
      };
      await start(tester);
      await push(tester, const SafetyScreen());
      expect(find.byKey(const Key('sf-nothing-paid')), findsOneWidget);
      await tap(tester, 'rules-save');
      expect(puts.single.containsKey('budgetUsd'), isFalse);
      expect(find.textContaining('only the owner'), findsOneWidget);
      await done(tester);
    });

    testWidgets('Tools: weights, a switch, the locked essential, exceptions, search', (
      tester,
    ) async {
      final offs = <List<String>>[];
      final agentPuts = <Map<String, dynamic>>[];
      var off = <String>['grep'];
      server.routes['GET /api/tools'] = (r) => server.answer(r, 200, {
        'agentId': null,
        'total': 120 * (3 - off.length),
        'saved': 120 * off.length,
        'entries': [
          for (final (id, group, essential) in const [
            ('read_file', 'files', true),
            ('grep', 'files', false),
            ('fetch', 'web', false),
          ])
            {
              'id': id,
              'group': group,
              'essential': essential,
              'tools': [id],
              'chars': 300,
              'tokens': 120,
              'global': !off.contains(id),
              if (id == 'fetch')
                'exceptions': [
                  {'agentId': 'a1', 'name': 'Orso', 'state': 'off'},
                ],
            },
        ],
      });
      server.routes['PUT /api/tools'] = (r) async {
        final b = await _body(r);
        off = [for (final x in b['off'] as List) '$x'];
        offs.add(off);
        await server.answer(r, 200, {'id': 'chg8'});
      };
      server.routes['PUT /api/agents/a1/tools'] = (r) async {
        agentPuts.add(await _body(r));
        await server.answer(r, 200, {'id': 'chg9'});
      };
      server.routes['GET /api/extensions/installed'] = (r) => server.answer(r, 200, [
        {
          'kind': 'tool',
          'name': 'weather',
          'description': 'The weather where you are.',
          'scope': 'user',
        },
        {'kind': 'skill', 'name': 'notes'},
      ]);
      await start(tester);
      await push(tester, const ToolsScreen());
      expect(find.text("All'inizio: circa 240 token a ogni messaggio"), findsOneWidget);
      expect(
        find.text("Spenti all'inizio: 120 token che pesano solo se si accende un gruppo"),
        findsOneWidget,
      );
      expect(find.byKey(const Key('tl-tool-read_file-locked')), findsOneWidget);
      await reveal(tester, find.byKey(const Key('tl-tool-fetch-except')));
      expect(find.text('Spento per: Orso (scelta loro)'), findsOneWidget);
      // The essential one does nothing when tapped.
      await tap(tester, 'tl-tool-read_file');
      expect(offs, isEmpty);
      await tap(tester, 'tl-tool-fetch');
      expect(offs.single, ['grep', 'fetch']);
      await tap(tester, 'tl-tool-grep');
      expect(offs.last, ['fetch']);
      await tap(tester, 'tl-tool-fetch-reset');
      expect(agentPuts.single, {
        'tools': {'fetch': 'default'},
      });
      await reveal(tester, find.byKey(const Key('tl-ext-weather')));
      expect(find.byKey(const Key('tl-ext-weather')), findsOneWidget);
      expect(find.byKey(const Key('tl-ext-notes')), findsNothing);
      await reveal(tester, find.byKey(const Key('tl-search')));
      await tester.enterText(find.byKey(const Key('tl-search')), 'zzz');
      await _settle(tester);
      expect(find.byKey(const Key('tl-none')), findsOneWidget);
      await done(tester);
    });

    testWidgets('Tools: groups with their weight and state, for everyone and for an agent', (
      tester,
    ) async {
      final kitPuts = <Map<String, dynamic>>[];
      final agentKitPuts = <Map<String, dynamic>>[];
      Map<String, dynamic> view(String? agentId) => {
        'agentId': agentId,
        'total': 300,
        'saved': 1200,
        'essential': 235,
        'entries': [
          {
            'id': 'browser',
            'group': 'web',
            'essential': false,
            'kit': 'browser',
            'state': 'auto',
            'tools': ['browser_open'],
            'chars': 3500,
            'tokens': 1200,
            'global': true,
          },
        ],
        'kits': [
          {
            'id': 'browser',
            'entries': ['browser'],
            'tokens': 1200,
            'state': agentId == null ? 'auto' : 'on',
            'default': 'auto',
            'own': agentId == null ? null : 'on',
            if (agentId != null) 'global': null,
          },
        ],
      };
      server.routes['GET /api/tools'] = (r) =>
          server.answer(r, 200, view(r.uri.queryParameters['agentId']));
      server.routes['PUT /api/tools/kits'] = (r) async {
        kitPuts.add(await _body(r));
        await server.answer(r, 200, {'id': 'chg10'});
      };
      server.routes['PUT /api/agents/a1/tools/kits'] = (r) async {
        agentKitPuts.add(await _body(r));
        await server.answer(r, 200, {'id': 'chg11'});
      };
      server.routes['GET /api/extensions/installed'] = (r) => server.answer(r, 200, []);
      await start(tester);
      await push(tester, const ToolsScreen());
      await reveal(tester, find.byKey(const Key('tl-kit-browser')));
      expect(find.text('Gruppi di strumenti'), findsOneWidget);
      expect(find.text('Strumenti essenziali, sempre accesi: circa 240 token'), findsOneWidget);
      expect(find.text('circa 1.200 token quando è acceso'), findsOneWidget);
      expect(find.text('Spento di serie (di serie)'), findsOneWidget);
      expect(find.textContaining('spento di serie'), findsWidgets);
      await tap(tester, 'tl-kit-browser-on');
      expect(kitPuts.single, {
        'kits': {'browser': 'on'},
      });
      await done(tester);
      // An agent's window: as for everyone, or its own choice.
      await start(tester);
      await push(
        tester,
        const RulesPage(
          pageKey: Key('agent-kits'),
          title: 'Orso',
          question: '',
          panel: false,
          children: [AgentKits(agentId: 'a1', agentName: 'Orso')],
        ),
      );
      await reveal(tester, find.byKey(const Key('tl-kit-browser')));
      expect(find.text('Come per tutti: Spento di serie'), findsOneWidget);
      await tap(tester, 'tl-kit-browser-off');
      expect(agentKitPuts.single, {
        'kits': {'browser': 'off'},
      });
      await done(tester);
    });

    testWidgets('Tools: an error says why', (tester) async {
      server.routes['GET /api/tools'] = (r) => server.answer(r, 500, {'error': 'no catalog'});
      await start(tester);
      await push(tester, const ToolsScreen());
      expect(find.textContaining('no catalog'), findsOneWidget);
      await done(tester);
    });

    testWidgets('Commands: the limits saved together, the defaults, undo; at work at once', (
      tester,
    ) async {
      server.routes['GET /api/settings/commands'] = (r) => server.answer(r, 200, {
        'settings': server.commandSettings,
        'defaults': {
          'maxPerSession': 4,
          'maxMs': 86400000,
          'maxLogBytes': 8388608,
          'bashMaxMs': 600000,
          'maxAtWork': null,
        },
        'serverMaxTurns': 200,
      });
      undoRoute(server);
      await start(tester);
      await push(tester, const CommandsScreen());
      expect(find.text('Quanto possono durare i comandi degli agenti?'), findsOneWidget);
      // Agents at work together: saved at once, the other limits as they are.
      await tap(tester, 'at-work-3');
      expect(server.commandPuts.single['maxAtWork'], 3);
      expect(server.commandPuts.single['maxPerSession'], 4);
      // The other limits: only with «Save», and they keep the agents at work.
      await tap(tester, 'cm-at-once-none');
      expect(
        find.textContaining('Senza limite: un agente può avviarne quanti vuole'),
        findsOneWidget,
      );
      await tap(tester, 'cm-steps-none');
      expect(server.commandPuts, hasLength(1));
      await tap(tester, 'rules-save');
      expect(server.commandPuts.last['maxPerSession'], isNull);
      expect(server.commandPuts.last['maxTurns'], isNull);
      expect(server.commandPuts.last.containsKey('maxTurns'), isTrue);
      expect(server.commandPuts.last['maxAtWork'], 3);
      expect(
        find.text('Salvato: vale dal prossimo comando e dal prossimo messaggio.'),
        findsOneWidget,
      );
      await tap(tester, 'cm-defaults');
      expect(server.commandPuts.last['maxPerSession'], 4);
      expect(server.commandPuts.last['maxAtWork'], 3);
      await done(tester);
    });

    testWidgets('Commands: a refused save says why and keeps the choice', (tester) async {
      server.routes['PUT /api/settings/commands'] = (r) =>
          server.answer(r, 400, {'error': 'maxMs too long'});
      await start(tester);
      await push(tester, const CommandsScreen());
      await tap(tester, 'cm-long-3600000');
      await tap(tester, 'rules-save');
      expect(find.textContaining('maxMs too long'), findsOneWidget);
      await done(tester);
    });

    testWidgets('on a computer the page is a panel over the window', (tester) async {
      await start(tester, size: const Size(1280, 800));
      final ctx = tester.element(find.byType(Navigator).first);
      openToolsSettings(ctx).ignore();
      await _settle(tester);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byKey(const Key('tools-settings')), findsOneWidget);
      await tap(tester, 'rules-back');
      expect(find.byKey(const Key('tools-settings')), findsNothing);
      openRequestsSettings(ctx).ignore();
      await _settle(tester);
      expect(find.byKey(const Key('requests-settings')), findsOneWidget);
      await done(tester);
    });
  });
}
