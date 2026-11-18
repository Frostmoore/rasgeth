// G42.9: Settings › Automations, native. First the editor's pure part against the page's own
// functions (test/fixtures/automation_vectors.json from tool/automation_vectors.mjs: the cron of a
// choice and back, the schedule in words, the draft a recipe becomes, its YAML, its sentence, it
// and en); then the screens against the fake server, which reads the YAML as the real one does
// and gives the next times from the service's fake clock: the list, an automation's window
// (switch, run now, the webhook's secret shown once, runs, delete), the editor (templates, every
// part, the preview, the YAML by hand, a refusal), a reminder, a magic automation with God, an
// assistant's routine with the whole editor, the automations' messages in «For you», a device
// that may not change them.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart' show Project;
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/l10n/app_localizations_en.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/push/live_notices.dart';
import 'package:rgcompanion/push/notice.dart';
import 'package:rgcompanion/screens/agent_settings_screen.dart';
import 'package:rgcompanion/screens/inbox_screen.dart';
import 'package:rgcompanion/settings/automations/automation_draft.dart';
import 'package:rgcompanion/settings/automations/automation_types.dart';
import 'package:rgcompanion/settings/automations/automations_screen.dart';
import 'package:rgcompanion/settings/automations/time_zone.dart';

import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

/// The page's object without what JSON.stringify leaves out (`undefined`).
Map<String, Object?> _asPage(Map<String, Object?> m) =>
    jsonDecode(jsonEncode(m)) as Map<String, Object?>..removeWhere((k, v) => k == 'timezone' && v == null);

const _morning = '''
name: "morning"
description: "Il punto del mattino"
on:
  cron: "0 8 * * 1-5"
  timezone: "Europe/Rome"
agent: "god"
instructions: "Dimmi cosa è successo ieri."
''';

const _hook = '''
name: "from-hook"
description: "Dal webhook"
on:
  webhook: true
agent: "god"
instructions: "Leggi i dati."
''';

void main() {
  group('the page\'s editor, in Dart', () {
    final v =
        jsonDecode(File('test/fixtures/automation_vectors.json').readAsStringSync())
            as Map<String, dynamic>;
    final agents = [
      for (final a in v['agents'] as List) Agent.fromJson(a as Map<String, dynamic>),
    ];
    final projects = [
      for (final p in v['projects'] as List) Project.fromJson(p as Map<String, dynamic>),
    ];
    final words = <String, AppLocalizations>{'it': AppLocalizationsIt(), 'en': AppLocalizationsEn()};
    final whoIt = whoOptions(words['it']!, agents);
    final zone = v['timezone'] as String;
    const others = {'morning': 'Il punto del mattino'};

    test('a cron expression back to its choice', () {
      for (final c in v['crons'] as List) {
        final m = c as Map<String, dynamic>;
        expect(
          fromCron(m['cron'] as String?, m['webhook'] as bool).toJson(),
          m['when'],
          reason: '${m['cron']}',
        );
      }
    });

    test('a choice\'s cron and its words, it and en', () {
      for (final c in v['whens'] as List) {
        final m = c as Map<String, dynamic>;
        final w = When.fromJson(m['when'] as Map<String, dynamic>);
        expect(toCron(w), m['cron'], reason: '${m['when']}');
        for (final lang in ['it', 'en']) {
          expect(whenWords(words[lang]!, w), (m['words'] as Map)[lang], reason: '$lang ${m['when']}');
        }
      }
    });

    test('a recipe becomes the same draft, the same YAML, the same sentence', () {
      for (final c in v['recipes'] as List) {
        final m = c as Map<String, dynamic>;
        final recipe = m['recipe'] as Map<String, dynamic>;
        final d = fromRecipe(recipe, whoIt, projects);
        expect(_asPage(d.toJson()), m['draft'], reason: '${recipe['name']}');
        expect(toYaml(d, recipe['name'] as String, whoIt, zone: zone), m['yaml']);
        for (final lang in ['it', 'en']) {
          final who = whoOptions(words[lang]!, agents);
          expect(
            sentence(words[lang]!, fromRecipe(recipe, who, projects), who, others),
            (m['sentence'] as Map)[lang],
            reason: '$lang ${recipe['name']}',
          );
        }
      }
    });

    test('a draft left by the editor: the same YAML and sentence', () {
      for (final c in v['drafts'] as List) {
        final m = c as Map<String, dynamic>;
        final d = Draft.fromJson(m['draft'] as Map<String, dynamic>);
        expect(toYaml(d, 'draft-test', whoIt, zone: zone), m['yaml'], reason: d.title);
        for (final lang in ['it', 'en']) {
          final who = whoOptions(words[lang]!, agents);
          expect(sentence(words[lang]!, d, who, others), (m['sentence'] as Map)[lang]);
        }
      }
    });

    test('the device\'s zone by its name; a notice as the server says it', () {
      expect(zoneFrom('/usr/share/zoneinfo/Europe/Rome'), 'Europe/Rome');
      expect(zoneFrom('America/Argentina/Buenos_Aires\n'), 'America/Argentina/Buenos_Aires');
      expect(zoneFrom('CET'), isNull);
      expect(zoneFrom('UTC'), 'UTC');
      const n = AutomationNotice(
        runId: 'r1',
        automationId: 'au1',
        name: 'Il punto',
        status: 'failed',
        sessionId: 's1',
        text: 'Non riesco.',
      );
      final p = automationNoticeFor(n, 'Casa', words['it']!);
      expect(p.id, 'auto:r1');
      expect(p.kind, NoticeKind.automation);
      // The server's words (`pushFor`, protocol/src/push.ts).
      expect(p.title, 'Il punto: non riuscita');
      expect(planFor(p, 'srv'), isA<ShowNotification>());
    });

    test('a slug as the page makes names', () {
      expect(slug('Il punto del mattino!'), 'il-punto-del-mattino');
      expect(slug('Perché è così'), 'perche-e-cosi');
      expect(slug('***'), 'automation');
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

    Future<void> tap(WidgetTester tester, String key) async {
      final f = find.byKey(Key(key));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await _settle(tester, 8);
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('the list: magic, new, reminder, the automations lit when on', (tester) async {
      server.automations.add(_morning, id: 'au1');
      server.automations.add(_hook, id: 'au2', enabled: false);
      server.automations.addRun('au1', {'status': 'failed'});
      server.automations.boxes.add({'id': 'mb1', 'name': 'Lavoro', 'category': 'work'});
      await start(tester);
      await push(tester, const AutomationsScreen());
      expect(find.text('Automazioni'), findsWidgets);
      expect(find.byKey(const Key('au-magic')), findsOneWidget);
      expect(find.byKey(const Key('au-new')), findsOneWidget);
      expect(find.byKey(const Key('au-new-reminder')), findsOneWidget);
      expect(find.text('Il punto del mattino'), findsOneWidget);
      expect(find.text('Dal lunedì al venerdì alle 08:00.'), findsOneWidget);
      // Its state: on, the last run, the next one (the service's clock: Wednesday 7:30 UTC).
      expect(find.textContaining('Attiva · non riuscita · Prossima'), findsOneWidget);
      expect(find.textContaining('Spenta'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('au-sources')));
      expect(find.text('Lavoro'), findsOneWidget);
      expect(find.text('Lavoro', skipOffstage: false), findsOneWidget);
      await done(tester);
    });

    testWidgets('an automation\'s window: off, run now, a new secret once, delete', (
      tester,
    ) async {
      server.automations.add(_hook, id: 'au2');
      server.automations.addRun('au2', {
        'status': 'ok',
        'trigger': 'webhook',
        'summary': 'Tutto **bene**.',
        'sessionId': 'sess_r',
        'delivery': {
          'status': 'delivered',
          'to': ['telegram'],
        },
      });
      await start(tester);
      await push(tester, const AutomationsScreen());
      await tap(tester, 'au-row-au2');
      expect(find.byKey(const Key('au-view-au2')), findsOneWidget);
      expect(find.textContaining('/api/automations/au2/hook'), findsOneWidget);
      expect(find.text('consegnato: telegram'), findsOneWidget);
      expect(find.text('webhook'), findsOneWidget);
      // Off: the server says so, the switch follows.
      await tap(tester, 'au-switch');
      expect(server.automations.list.single['enabled'], isFalse);
      expect(find.text('Spenta: non parte da sola.'), findsOneWidget);
      // A new secret: shown only now.
      expect(find.byKey(const Key('au-secret-once')), findsNothing);
      await tap(tester, 'au-secret');
      expect(find.byKey(const Key('au-secret-once')), findsOneWidget);
      expect(find.textContaining('rgwh_au2_new'), findsOneWidget);
      // Run now: started, and the run is there.
      await tap(tester, 'au-run');
      expect(find.byKey(const Key('au-started')), findsOneWidget);
      expect(server.automations.runs['au2']!.first['trigger'], 'manual');
      expect(find.text('a mano'), findsOneWidget);
      // Delete, with our window first.
      await tap(tester, 'au-delete');
      expect(find.text('Elimina'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
      await _settle(tester);
      expect(server.automations.list, isEmpty);
      expect(find.byKey(const Key('au-view-au2')), findsNothing);
      expect(find.byKey(const Key('au-empty')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a new automation: a template, the parts, the next times, saved as YAML', (
      tester,
    ) async {
      await start(tester, size: const Size(1200, 900));
      await push(tester, const AutomationsScreen());
      await tap(tester, 'au-new');
      expect(find.byKey(const Key('au-editor')), findsOneWidget);
      // The morning template is chosen: title, instructions, working days at 8.
      expect(find.text('Il punto del mattino'), findsWidgets);
      expect(find.text('Dal lunedì al venerdì alle 08:00.'), findsOneWidget);
      // The next times come from the server (its fake clock: Wednesday 18 November, 7:30 UTC).
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await _settle(tester);
      expect(find.byKey(const Key('au-next-0')), findsOneWidget);
      expect(find.textContaining('18 nov'), findsOneWidget);
      // Every week, on Monday and Friday at 8.
      await tap(tester, 'au-when-weekly');
      await tap(tester, 'au-day-1');
      expect(find.text('Ogni settimana il venerdì, lunedì alle 08:00.'), findsOneWidget);
      // Also on an email; only with some words; a reminder of the budget.
      await tap(tester, 'au-start-email');
      await tester.enterText(find.byKey(const Key('au-email-from')), 'banca');
      await tap(tester, 'au-cond-words');
      await tester.enterText(find.byKey(const Key('au-only-words')), 'bonifico, estratto');
      await tester.pump();
      await tap(tester, 'au-budget');
      await tap(tester, 'au-tell-failure');
      await tap(tester, 'au-to-telegram');
      expect(
        find.textContaining('oppure quando arriva un\'email (da banca)'),
        findsOneWidget,
      );
      await tap(tester, 'au-save');
      final y = server.automations.yamls.single;
      expect(y, contains('  cron: "0 8 * * 5,1"'.replaceFirst('5,1', '1,5')));
      expect(y, contains('    from: "banca"'));
      expect(y, contains('  words: ["bonifico","estratto"]'));
      expect(y, contains('budgetUsd: 0.5'));
      expect(y, contains('  when: "failure"'));
      expect(y, contains('  to: ["telegram"]'));
      // The window of what was made opens.
      expect(find.byKey(const Key('au-editor')), findsNothing);
      expect(find.byKey(Key('au-view-${server.automations.list.single['id']}')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the YAML by hand: the server says why not, the save says it again', (
      tester,
    ) async {
      server.automations.add(_morning, id: 'au1');
      await start(tester, size: const Size(1200, 900));
      await push(tester, const AutomationsScreen());
      await tap(tester, 'au-row-au1');
      await tap(tester, 'au-edit');
      expect(find.byKey(const Key('au-editor')), findsOneWidget);
      // No template choice when changing one.
      expect(find.byKey(const Key('au-tpl-morning')), findsNothing);
      await tap(tester, 'au-advanced-toggle');
      expect(find.byKey(const Key('au-yaml')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('au-yaml')), 'name: "morning"\non:\n  cron: "x"\n');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await _settle(tester);
      expect(find.byKey(const Key('au-server-says')), findsOneWidget);
      expect(find.textContaining('Invalid cron expression'), findsOneWidget);
      await tap(tester, 'au-save');
      expect(find.byKey(const Key('au-error')), findsOneWidget);
      // Back to the form: what it writes again.
      await tap(tester, 'au-yaml-back');
      server.automations.refuseNext = 'agent: "Nessuno" is not an agent';
      await tap(tester, 'au-save');
      expect(find.textContaining('is not an agent'), findsOneWidget);
      await tap(tester, 'au-save');
      expect(server.automations.yamls.single, contains('name: "morning"'));
      expect(find.byKey(const Key('au-view-au1')), findsOneWidget);
      await done(tester);
    });

    testWidgets('a reminder: what, which day, what time; a device that may not', (tester) async {
      await start(tester);
      await push(tester, const AutomationsScreen());
      await tap(tester, 'au-new-reminder');
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('au-reminder-save'))).onPressed,
        isNull,
      );
      await tester.enterText(find.byKey(const Key('au-reminder-text')), 'Chiama il dentista');
      await tester.pump();
      await tap(tester, 'au-reminder-time');
      await tap(tester, 'au-time-h-16');
      await tap(tester, 'au-time-m-30');
      await tap(tester, 'au-time-ok');
      server.automations.forbidden = true;
      await tap(tester, 'au-reminder-save');
      expect(find.byKey(const Key('au-error')), findsOneWidget);
      expect(find.textContaining('Only the person'), findsOneWidget);
      server.automations.forbidden = false;
      await tap(tester, 'au-reminder-save');
      final y = server.automations.yamls.single;
      expect(y, contains('reminder: "Chiama il dentista"'));
      expect(y, matches(RegExp(r'  at: "\d{4}-\d\d-\d\dT16:30"')));
      expect(y, contains('  timezone: '));
      expect(find.text('Chiama il dentista'), findsWidgets);
      await done(tester);
    });

    testWidgets('a magic automation: God builds it, the proposal, the yes', (tester) async {
      await start(tester, size: const Size(1200, 900));
      await push(tester, const AutomationsScreen());
      await tap(tester, 'au-magic');
      expect(find.byKey(const Key('au-magic-go')), findsOneWidget);
      await tap(tester, 'au-magic-ex-0');
      await tap(tester, 'au-magic-go');
      final id = server.automations.magic.single['id'] as String;
      expect(server.automations.magic.single['request'], startsWith('Ogni giorno alle 15'));
      expect(find.byKey(const Key('au-magic-steps')), findsOneWidget);
      expect(find.byKey(const Key('au-magic-dismiss')), findsOneWidget);
      // God proposes; something is missing: the yes waits.
      server.automations.propose(
        id,
        _morning,
        summary: 'Ogni mattina ti scrivo il punto.',
        needs: [
          {'kind': 'chat', 'what': 'whatsapp', 'why': 'Per scriverti', 'ready': false},
        ],
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(seconds: 5));
      await _settle(tester);
      expect(find.byKey(const Key('au-proposal')), findsOneWidget);
      expect(find.text('La chat WhatsApp'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(const Key('au-magic-approve'))).onPressed,
        isNull,
      );
      // Now it is there.
      final m = server.automations.magic.single;
      ((m['proposal'] as Map)['needs'] as List).first['ready'] = true;
      await tester.pump(const Duration(seconds: 5));
      await _settle(tester);
      await tap(tester, 'au-magic-approve');
      expect(server.automations.magic.single['status'], 'done');
      expect(server.automations.list, hasLength(1));
      expect(find.byKey(Key('au-view-${server.automations.list.single['id']}')), findsOneWidget);
      await done(tester);
    });

    testWidgets('an assistant\'s new routine: the whole editor, its agent chosen', (tester) async {
      server.agentOverrides['a5'] = {'connections': <String>[]};
      final app = await start(tester, size: const Size(1200, 900));
      final a5 = app.agents.firstWhere((a) => a.id == 'a5');
      expect(a5.kind, AgentKind.assistant);
      server.automations.add(
        _morning.replaceFirst('agent: "god"', 'agent: "a5"'),
        id: 'au1',
      );
      await push(
        tester,
        AgentSettingsScreen(agentId: 'a5', agent: a5, initial: AgentGroup.assistant),
      );
      expect(find.text('Il punto del mattino'), findsOneWidget);
      expect(find.text('Dal lunedì al venerdì alle 08:00 · Attiva'), findsOneWidget);
      await tap(tester, 'as-new-routine');
      expect(find.byKey(const Key('au-editor')), findsOneWidget);
      expect(find.text(a5.name), findsWidgets);
      await tap(tester, 'au-save');
      final y = server.automations.yamls.single;
      expect(y, contains('agent: "a5"'));
      expect(find.byKey(const Key('au-editor')), findsNothing);
      // Its window from the row: the same as in Settings › Automations.
      await tap(tester, 'as-routine-open-au1');
      expect(find.byKey(const Key('au-view-au1')), findsOneWidget);
      await done(tester);
    });

    testWidgets('the messages of automations in For you, and the list read again', (tester) async {
      final app = await start(tester);
      await push(tester, const InboxScreen());
      expect(find.byKey(const Key('au-notices')), findsNothing);
      app.live.apply({
        'type': 'automation.notice',
        'automationId': 'au1',
        'runId': 'run7',
        'name': 'Il punto',
        'status': 'failed',
        'sessionId': 'sess_7',
        'text': 'Non riesco a leggere la posta.',
      });
      // The same message twice is one.
      app.live.apply({
        'type': 'automation.notice',
        'automationId': 'au1',
        'runId': 'run7',
        'name': 'Il punto',
        'status': 'failed',
        'sessionId': 'sess_7',
        'text': 'Non riesco a leggere la posta.',
      });
      await _settle(tester);
      expect(app.live.notices, hasLength(1));
      expect(app.live.waiting, 1);
      expect(find.text('Non riesco a leggere la posta.'), findsOneWidget);
      expect(find.text('failed'), findsOneWidget);
      await tap(tester, 'au-notice-dismiss-run7');
      expect(app.live.notices, isEmpty);
      // `automations.changed`: the number goes up.
      final before = app.live.automationsChanged.value;
      app.live.apply({'type': 'automations.changed', 'automationId': 'au1'});
      expect(app.live.automationsChanged.value, before + 1);
      await done(tester);
    });
  });
}
