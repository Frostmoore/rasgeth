// 3.12: Settings › Rules, native, against a fake server with the page's routes (`/api/rules…`,
// `/api/magic-rules…`) and answers: the rule in words (it and en, as the page's `ruleLines`), the
// draft sent as the page sends it (`toInput`), the list with its switches, a stop and «Resume»,
// the ready-made weekly margin added switched off, the history and «Undo», the editor with its
// examples and «Try», and the magic rule's proposal approved.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations_en.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/settings/person_rules/person_rules_screen.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

Future<Map<String, dynamic>> _body(HttpRequest r) async {
  final text = await utf8.decodeStream(r);
  return text.isEmpty ? {} : jsonDecode(text) as Map<String, dynamic>;
}

const _warn = {
  'name': 'Margine settimanale: avviso',
  'description': '',
  'when': {'event': 'usage'},
  'if': [
    {'field': 'window', 'op': 'eq', 'value': '7d'},
    {'field': 'marginPct', 'op': 'lte', 'value': 5},
  ],
  'actions': [
    {'do': 'notify', 'text': ''},
  ],
  'examples': {
    'fire': {'window': '7d', 'marginPct': 4},
    'pass': {'window': '7d', 'marginPct': 12},
  },
};

/// The rules as the server keeps them, with what the app sent.
class _FakeRules {
  _FakeRules(this.s) {
    s.routes['GET /api/rules'] = (r) =>
        s.answer(r, 200, {'rules': rules, 'holds': holds, 'fires': fires});
    s.routes['GET /api/magic-rules'] = (r) => s.answer(r, 200, magic);
    s.routes['POST /api/rules'] = (r) async {
      final b = await _body(r);
      sent.add(b);
      final rule = {
        ...(b['rule'] as Map<String, dynamic>),
        'id': 'rule_${rules.length + 1}',
        'enabled': b['enable'] == true,
        'origin': 'person',
        'version': 1,
        'createdAt': '2026-11-22T10:00:00.000Z',
        'updatedAt': '2026-11-22T10:00:00.000Z',
        'lastFiredAt': null,
      };
      rules.add(rule);
      await s.answer(r, 201, rule);
    };
    s.routes['POST /api/rules/try'] = (r) async {
      tried.add(await _body(r));
      await s.answer(r, 200, {'ok': true, 'fire': true, 'pass': true, 'problems': <String>[]});
    };
    s.routes['POST /api/rules/template'] = (r) async {
      sent.add(await _body(r));
      rules.add({..._warn, ..._meta('rule_t1'), 'origin': 'template'});
      await s.answer(r, 201, rules);
    };
    s.routes['POST /api/rules/resume'] = (r) async {
      sent.add(await _body(r));
      holds.clear();
      await s.answer(r, 200, {'holds': holds});
    };
  }

  final FakeRedGiant s;
  final rules = <Map<String, dynamic>>[];
  final holds = <Map<String, dynamic>>[];
  final fires = <Map<String, dynamic>>[];
  final magic = <Map<String, dynamic>>[];
  final sent = <Map<String, dynamic>>[];
  final tried = <Map<String, dynamic>>[];

  Map<String, dynamic> _meta(String id) => {
    'id': id,
    'enabled': false,
    'origin': 'person',
    'version': 1,
    'createdAt': '2026-11-22T10:00:00.000Z',
    'updatedAt': '2026-11-22T10:00:00.000Z',
    'lastFiredAt': null,
  };

  /// A rule already there, with its own routes.
  void add(String id, Map<String, dynamic> draft, {bool enabled = false}) {
    rules.add({...draft, ..._meta(id), 'enabled': enabled});
    s.routes['POST /api/rules/$id/enabled'] = (r) async {
      final b = await _body(r);
      sent.add({'enabled': b['enabled'], 'id': id});
      final rule = rules.firstWhere((x) => x['id'] == id)..['enabled'] = b['enabled'];
      await s.answer(r, 200, rule);
    };
    s.routes['GET /api/rules/history'] = (r) => s.answer(r, 200, [
      {
        'ruleId': id,
        'version': 2,
        'change': 'enabled',
        'by': 'person',
        'at': '2026-11-22T10:05:00.000Z',
        'rule': rules.firstWhere((x) => x['id'] == id),
      },
      {
        'ruleId': id,
        'version': 1,
        'change': 'created',
        'by': 'person',
        'at': '2026-11-22T10:00:00.000Z',
        'rule': rules.firstWhere((x) => x['id'] == id),
      },
    ]);
    s.routes['POST /api/rules/$id/undo'] = (r) async {
      sent.add({'undo': id});
      await s.answer(r, 200, {'rule': rules.firstWhere((x) => x['id'] == id)});
    };
  }
}

void main() {
  group('the rule in words, as the page', () {
    test('when, if, then: it and en', () {
      expect(ruleLines(AppLocalizationsIt(), _warn), [
        'Quando si legge il consumo dell\'abbonamento',
        'se la finestra è 7d e il margine (punti) è al massimo 5',
        'allora ti avvisa',
      ]);
      expect(
        ruleLines(AppLocalizationsEn(), {
          'when': {'event': 'tool'},
          'if': [
            {'field': 'command', 'op': 'matches', 'value': 'git push*'},
          ],
          'actions': [
            {'do': 'block', 'text': 'no'},
            {'do': 'stop', 'resume': 'person'},
          ],
        }),
        [
          'When a tool or command is about to run',
          'if the command looks like git push*',
          'then block it, stop the agents after they save, until you resume them',
        ],
      );
    });

    test('the draft goes as the page sends it: numbers, examples on the used fields', () {
      expect(
        ruleInput({
          'name': ' Margin ',
          'description': '',
          'when': {'event': 'usage', 'cron': 'x'},
          'if': [
            {'field': 'marginPct', 'op': 'lte', 'value': '5'},
          ],
          'actions': [
            {'do': 'notify', 'text': ''},
          ],
          'examples': {
            'fire': {'marginPct': '3', 'tool': 'bash'},
            'pass': {'marginPct': '9'},
          },
        }),
        {
          'name': 'Margin',
          'description': '',
          'when': {'event': 'usage'},
          'if': [
            {'field': 'marginPct', 'op': 'lte', 'value': 5},
          ],
          'actions': [
            {'do': 'notify', 'text': ''},
          ],
          'examples': {
            'fire': {'marginPct': 3},
            'pass': {'marginPct': 9},
          },
        },
      );
    });
  });

  group('in the app', () {
    late FakeRedGiant server;
    late _FakeRules fake;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      fake = _FakeRules(server);
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

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester, 8);
    }

    Future<void> type(WidgetTester tester, String key, String text) async {
      await tester.ensureVisible(find.byKey(Key(key)));
      await tester.pump();
      await tester.enterText(find.byKey(Key(key)), text);
      await tester.pump();
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('a stop and «Resume», a switch, the ready-made margin, history and undo', (
      tester,
    ) async {
      fake.add('rule_1', {..._warn, 'name': 'Niente push'}, enabled: true);
      fake.holds.add({
        'ruleId': 'rule_9',
        'ruleName': 'Margine settimanale: fermata',
        'reason': 'margine +1 punti',
        'at': '2026-11-22T10:00:00.000Z',
        'scope': 'all',
        'resume': 'person',
      });
      fake.fires.add({
        'id': 'fire_1',
        'ruleId': 'rule_1',
        'ruleName': 'Niente push',
        'at': '2026-11-22T10:01:00.000Z',
        'event': 'tool',
        'facts': {'tool': 'bash'},
        'results': ['blocked'],
      });
      await start(tester, size: const Size(1200, 2000));
      await push(tester, const PersonRulesScreen());
      expect(find.text('Cosa deve tenere d\'occhio Rasgeth per te?'), findsOneWidget);
      expect(find.text('Fermati dalla regola «Margine settimanale: fermata»'), findsOneWidget);
      await tap(tester, 'pr-resume-rule_9');
      expect(fake.sent.last, {'ruleId': 'rule_9'});
      expect(find.byKey(const Key('pr-hold-rule_9')), findsNothing);
      // The rule in words, its switch off.
      expect(find.text('allora ti avvisa'), findsOneWidget);
      await tap(tester, 'pr-switch-rule_1');
      expect(fake.sent.last, {'enabled': false, 'id': 'rule_1'});
      // What the rules did.
      expect(find.byKey(const Key('pr-fire-fire_1')), findsOneWidget);
      // The ready-made weekly margin: added switched off.
      await tap(tester, 'pr-template');
      expect(fake.sent.last, {'template': 'weekly-margin', 'enable': false});
      expect(find.byKey(const Key('pr-template-card')), findsNothing);
      // History and undo.
      await tap(tester, 'pr-history-rule_1');
      expect(find.byKey(const Key('pr-version-2')), findsOneWidget);
      expect(find.text('tu, versione 2'), findsOneWidget);
      await tap(tester, 'pr-undo');
      expect(fake.sent.last, {'undo': 'rule_1'});
      await done(tester);
    });

    testWidgets('the editor: when, if, then, the examples, Try, save switched on', (tester) async {
      await start(tester, size: const Size(1200, 2600));
      await push(tester, const PersonRulesScreen());
      expect(
        find.text(
          'Ancora nessuna regola. Descrivine una a God con «Regola magica», o scrivila tu.',
        ),
        findsOneWidget,
      );
      await tap(tester, 'pr-new');
      await type(tester, 'pr-name', 'Niente push');
      await tap(tester, 'pr-ev-tool');
      // Ask and block are offered only before something runs.
      expect(find.byKey(const Key('pr-ak-0-block')), findsOneWidget);
      await tap(tester, 'pr-add-cond');
      await tap(tester, 'pr-cf-0-command');
      await type(tester, 'pr-cv-0', 'git push*');
      await tap(tester, 'pr-ak-0-block');
      await type(tester, 'pr-at-0', 'non oggi');
      await type(tester, 'pr-xfire-command', 'git push origin main');
      await type(tester, 'pr-xpass-command', 'git status');
      await tap(tester, 'pr-try');
      expect(find.byKey(const Key('pr-trial')), findsOneWidget);
      expect(find.byKey(const Key('pr-verdict-fire')), findsOneWidget);
      await tap(tester, 'pr-save-on');
      expect(fake.sent.last, {
        'rule': {
          'name': 'Niente push',
          'description': '',
          'when': {'event': 'tool'},
          'if': [
            {'field': 'command', 'op': 'matches', 'value': 'git push*'},
          ],
          'actions': [
            {'do': 'block', 'text': 'non oggi'},
          ],
          'examples': {
            'fire': {'command': 'git push origin main'},
            'pass': {'command': 'git status'},
          },
        },
        'enable': true,
      });
      expect(find.byKey(const Key('pr-rule-rule_1')), findsOneWidget);
      // A usage rule offers neither ask nor block.
      await tap(tester, 'pr-new');
      await tap(tester, 'pr-ev-usage');
      expect(find.byKey(const Key('pr-ak-0-block')), findsNothing);
      expect(find.byKey(const Key('pr-ak-0-stop')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the magic rule: God\'s proposal beside the conversation, approved', (
      tester,
    ) async {
      final approved = <Map<String, dynamic>>[];
      final proposal = {
        'id': 'mrule_1',
        'title': 'Niente push',
        'request': 'Niente git push',
        'sessionId': 's-magic',
        'agentId': 'a1',
        'status': 'ready',
        'proposal': {
          'rule': {..._warn, 'name': 'Niente push'},
          'summary': 'Ti avviso quando il margine scende.',
          'missing': <String>[],
          'trial': {'ok': true, 'fire': true, 'pass': true, 'problems': <String>[]},
          'at': '2026-11-22T10:00:00.000Z',
        },
        'ruleId': null,
        'createdAt': '2026-11-22T10:00:00.000Z',
        'updatedAt': '2026-11-22T10:00:00.000Z',
      };
      fake.magic.add(proposal);
      server.routes['GET /api/magic-rules/mrule_1'] = (r) => server.answer(r, 200, proposal);
      server.routes['POST /api/magic-rules/mrule_1/approve'] = (r) async {
        approved.add(await _body(r));
        proposal['status'] = 'done';
        await server.answer(r, 200, {'magic': proposal, 'rule': {}});
      };
      await start(tester, size: const Size(1200, 2000));
      await push(tester, const PersonRulesScreen());
      await tap(tester, 'pr-magic-mrule_1');
      expect(find.byKey(const Key('pr-mg-proposal')), findsOneWidget);
      expect(find.text('Ti avviso quando il margine scende.'), findsOneWidget);
      await tap(tester, 'pr-mg-approve');
      expect(approved.single, <String, dynamic>{});
      expect(find.byKey(const Key('pr-mg-proposal')), findsNothing);
      await done(tester);
    });
  });
}
