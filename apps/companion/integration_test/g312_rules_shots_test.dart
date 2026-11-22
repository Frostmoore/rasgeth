// 3.12 in the real app on Linux, against the tests' fake Rasgeth: Settings › Rules with a stop in
// place, the rules and what they did, the editor with its examples tried, the history, God's
// magic rule beside its conversation, a webhook rule's address; light and dark. With RG_SCREEN
// narrower than 600 the phone. Run with Xvfb like tool/linux_shots.sh (no demo server needed):
//   RG_SCREEN=390x844 RG_SHOTS=<folder> flutter test integration_test/g312_rules_shots_test.dart -d linux
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/settings/person_rules/person_rules_screen.dart';

import '../test/fake_server.dart';
import 'shots_test.dart' show frames, shot, waitFor;

final _phone =
    (int.tryParse((Platform.environment['RG_SCREEN'] ?? '1440x900').split('x').first) ?? 1440) <
    600;

const _at = '2026-11-22T10:00:00.000Z';

Map<String, dynamic> _rule(
  String id,
  Map<String, dynamic> d, {
  bool on = true,
  String origin = 'person',
}) => {
  'description': '',
  'examples': <String, dynamic>{},
  ...d,
  'id': id,
  'enabled': on,
  'origin': origin,
  'version': 2,
  'createdAt': _at,
  'updatedAt': _at,
  'lastFiredAt': _at,
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('3.12: Settings › Rules', (t) async {
    final fake = await FakeRedGiant.start();
    addTearDown(fake.close);
    final push = _rule('rule_1', {
      'name': 'Niente push la domenica',
      'description': 'Il fine settimana niente codice online',
      'when': {'event': 'tool'},
      'if': [
        {'field': 'command', 'op': 'matches', 'value': 'git push*'},
      ],
      'actions': [
        {'do': 'block', 'text': 'oggi no'},
        {'do': 'notify', 'text': ''},
      ],
      'examples': {
        'fire': {'command': 'git push origin main'},
        'pass': {'command': 'git status'},
      },
    });
    final rules = [
      push,
      _rule('rule_2', {
        'name': 'Margine settimanale: fermata',
        'when': {'event': 'usage'},
        'if': [
          {'field': 'window', 'op': 'eq', 'value': '7d'},
          {'field': 'marginPct', 'op': 'lte', 'value': 2},
        ],
        'actions': [
          {'do': 'notify', 'text': ''},
          {'do': 'stop', 'text': '', 'scope': 'all', 'resume': 'person'},
        ],
      }, origin: 'template'),
      _rule('rule_3', {
        'name': 'Deploy fallito',
        'when': {'event': 'webhook'},
        'if': [
          {'field': 'body', 'op': 'contains', 'value': 'failed'},
        ],
        'actions': [
          {'do': 'notify', 'text': 'Il deploy è fallito'},
        ],
      }, on: false),
    ];
    final magic = {
      'id': 'mrule_1',
      'title': 'Budget al 80%',
      'request': 'Avvisami quando il budget arriva all\'80%',
      'sessionId': 's1',
      'agentId': 'a1',
      'status': 'ready',
      'proposal': {
        'rule': {
          'name': 'Budget all\'80%',
          'description': '',
          'when': {'event': 'budget'},
          'if': [
            {'field': 'budgetPct', 'op': 'gte', 'value': 80},
          ],
          'actions': [
            {'do': 'notify', 'text': ''},
          ],
          'examples': {
            'fire': {'budgetPct': 85},
            'pass': {'budgetPct': 30},
          },
        },
        'summary':
            'Quando un budget arriva all\'80% ti avviso nella pagina, nell\'app e su Telegram.',
        'missing': <String>[],
        'trial': {'ok': true, 'fire': true, 'pass': true, 'problems': <String>[]},
        'at': _at,
      },
      'ruleId': null,
      'createdAt': _at,
      'updatedAt': _at,
    };
    Future<void> ok(HttpRequest r, Object body) => fake.answer(r, 200, body);
    fake.routes['GET /api/rules'] = (r) => ok(r, {
      'rules': rules,
      'holds': [
        {
          'ruleId': 'rule_2',
          'ruleName': 'Margine settimanale: fermata',
          'reason': 'claude 7d: margine +1 punti, 69% usato',
          'at': _at,
          'scope': 'all',
          'resume': 'person',
        },
      ],
      'fires': [
        {
          'id': 'f1',
          'ruleId': 'rule_2',
          'ruleName': 'Margine settimanale: fermata',
          'at': _at,
          'event': 'usage',
          'facts': {'window': '7d', 'marginPct': 1},
          'results': ['notified: page, app', 'stopped (all)'],
        },
        {
          'id': 'f2',
          'ruleId': 'rule_1',
          'ruleName': 'Niente push la domenica',
          'at': _at,
          'event': 'tool',
          'facts': {'tool': 'bash'},
          'results': ['blocked', 'notified: page'],
        },
      ],
    });
    fake.routes['GET /api/magic-rules'] = (r) => ok(r, [magic]);
    fake.routes['GET /api/magic-rules/mrule_1'] = (r) => ok(r, magic);
    fake.routes['POST /api/rules/try'] = (r) async {
      await utf8.decodeStream(r);
      await ok(r, {'ok': true, 'fire': true, 'pass': true, 'problems': <String>[]});
    };
    fake.routes['GET /api/rules/history'] = (r) => ok(r, [
      {
        'ruleId': 'rule_1',
        'version': 2,
        'change': 'enabled',
        'by': 'person',
        'at': _at,
        'rule': push,
      },
      {
        'ruleId': 'rule_1',
        'version': 1,
        'change': 'created',
        'by': 'person',
        'at': _at,
        'rule': push,
      },
    ]);
    fake.routes['POST /api/rules/rule_3/secret'] = (r) => ok(r, {'webhookSecret': 'rgwh_Zq8…'});

    final app = AppController(
      tokens: MemoryTokenStore(),
      prefs: MemoryAppPrefs(),
      platform: _phone ? DevicePlatform.android : DevicePlatform.linux,
    )..locale = const Locale('it');
    await t.runAsync(() => app.connect(fake.base.toString(), 'secret'));
    await t.pumpWidget(RGCompanionApp(controller: app));
    await waitFor(t, () => app.connected);
    await frames(t, 2000);
    final p = _phone ? 'telefono' : 'computer';

    /// Scrolls the page until [f] is built (the list builds only what is near the screen).
    Future<void> reveal(Finder f) async {
      final page = find.byKey(const Key('pr-page'));
      if (f.evaluate().isEmpty && page.evaluate().isNotEmpty) {
        final list = find.descendant(of: page, matching: find.byType(Scrollable)).first;
        final pos = t.state<ScrollableState>(list).position;
        await t.scrollUntilVisible(
          f,
          pos.pixels >= pos.maxScrollExtent ? -300 : 300,
          scrollable: list,
          maxScrolls: 60,
        );
      }
      await t.ensureVisible(f.first);
      await frames(t, 300);
    }

    Future<void> tap(String key) async {
      final f = find.byKey(Key(key)).first;
      await reveal(find.byKey(Key(key)));
      await frames(t, 300);
      await t.tap(f);
      await frames(t, 900);
    }

    Future<void> back() async {
      final nav = t.state<NavigatorState>(find.byType(Navigator).last);
      nav.pop();
      await frames(t, 700);
    }

    for (final dark in [false, true]) {
      final tone = dark ? 'scuro' : 'chiaro';
      app.setThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const PersonRulesScreen())).ignore();
      await frames(t, 1500);
      await shot(t, 'app-$p-$tone-01-pagina');
      await reveal(find.byKey(const Key('pr-rule-rule_1')));
      await shot(t, 'app-$p-$tone-02-regole');
      await reveal(find.byKey(const Key('pr-fire-f2')));
      await shot(t, 'app-$p-$tone-03-cosa-hanno-fatto');
      await tap('pr-edit-rule_1');
      await tap('pr-try');
      await shot(t, 'app-$p-$tone-04-editor');
      await t.ensureVisible(find.byKey(const Key('pr-trial')));
      await shot(t, 'app-$p-$tone-05-editor-prova');
      await back();
      await tap('pr-history-rule_1');
      await shot(t, 'app-$p-$tone-06-storia');
      await back();
      await tap('pr-hook-rule_3');
      await tap('dialog-yes');
      await shot(t, 'app-$p-$tone-07-webhook');
      await back();
      await tap('pr-magic-mrule_1');
      await shot(t, 'app-$p-$tone-08-magica', wait: 1500);
      await back();
      await back();
    }
  });
}
