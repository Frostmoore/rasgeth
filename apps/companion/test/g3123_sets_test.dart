// 3.12.3: the ready-made agent sets («Parti da…»), an agent's connections (any number, by kind) and
// the calendars, native as the page's. Against the fake Rasgeth.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/set_types.dart';
import 'package:rgcompanion/screens/agent_settings_screen.dart';
import 'package:rgcompanion/settings/agents/agent_sets.g.dart';
import 'package:rgcompanion/settings/channels/calendars.dart';

import 'fake_channels.dart';
import 'fake_server.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late FakeRedGiant server;
  late FakeChannels ch;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    ch = FakeChannels(server.setup);
    server.channels = ch;
  });
  tearDown(() => server.close());

  Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 4000)}) async {
    final app =
        AppController(
            tokens: MemoryTokenStore(),
            prefs: MemoryAppPrefs(),
            platform: DevicePlatform.android,
            liveEnabled: false,
          )
          ..locale = const Locale('it')
          ..reduceMotion = true;
    await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
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
    await _settle(tester);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  test('the sets are the protocol\'s: five, in the board\'s order, in both languages', () {
    expect(
      [for (final s in agentSets) s.id],
      ['researcher', 'email', 'messages', 'sheets', 'agenda'],
    );
    for (final s in agentSets) {
      expect(s.name.it, isNotEmpty);
      expect(s.name.en, isNotEmpty);
      expect(s.description.it, isNotEmpty);
      expect(s.asks, isNotEmpty);
    }
    final AgentSet email = agentSets.firstWhere((s) => s.id == 'email');
    expect(email.wants, ['mailbox']);
    expect(email.speed, 'fast');
    expect(email.effort, 'low');
    expect(agentSets.firstWhere((s) => s.id == 'agenda').wants, ['calendar']);
    expect(agentSets.firstWhere((s) => s.id == 'messages').wants, ['chat']);
  });

  test('old MCP names read as typed connections; typed ones as they are', () {
    final a = Agent.fromJson({
      'id': 'x',
      'kind': 'assistant',
      'name': 'X',
      'status': 'active',
      'connections': [
        'notes',
        {'kind': 'mailbox', 'ref': 'box_1'},
        {'kind': 'bogus'},
      ],
    });
    expect(a.connections, [
      const AgentConnection(kind: 'mcp', ref: 'notes'),
      const AgentConnection(kind: 'mailbox', ref: 'box_1'),
    ]);
  });

  testWidgets('a new agent from a set: the steps without a job and without God\'s draft', (
    tester,
  ) async {
    ch.boxes.add({
      'id': 'w1',
      'name': 'Lavoro',
      'category': 'work',
      'host': 'imap.work.it',
      'port': 993,
      'secure': true,
      'user': 'm@work.it',
      'agents': true,
    });
    ch.boxes.add({
      'id': 'w2',
      'name': 'Casa',
      'category': 'personal',
      'host': 'imap.casa.it',
      'port': 993,
      'secure': true,
      'user': 'm@casa.it',
      'agents': true,
    });
    await start(tester);
    await tester.tap(find.byKey(const Key('team-new-agent')));
    await _settle(tester);
    await tap(tester, 'new-kind-assistant');
    await tap(tester, 'new-agent-next');
    // «Parti da…»: the five sets and an empty agent.
    expect(find.text('Parti da…'), findsOneWidget);
    for (final n in [
      'Ricercatore',
      'Email',
      'Segretario sui messaggi',
      'Fogli di lavoro',
      'Agenda e promemoria',
    ]) {
      expect(find.text(n), findsOneWidget, reason: n);
    }
    await tap(tester, 'new-set-email');
    expect(find.byKey(const Key('new-set-asks')), findsOneWidget);
    expect(find.textContaining('Inviare un\'email te lo chiede sempre'), findsOneWidget);
    expect(find.textContaining('Da collegare: caselle di posta'), findsOneWidget);
    expect(find.textContaining('Modello: veloce, effort basso'), findsOneWidget);
    await tap(tester, 'new-agent-next');
    // The job step is skipped: the name is the set's.
    expect(
      tester.widget<TextField>(find.byKey(const Key('new-agent-name'))).controller!.text,
      'Email',
    );
    await tap(tester, 'new-agent-next');
    // Its connections: any number of mailboxes.
    await tap(tester, 'conn-mailbox-w1');
    await tap(tester, 'conn-mailbox-w2');
    await tap(tester, 'new-agent-next');
    await tap(tester, 'new-agent-next');
    await tap(tester, 'new-mode-manual');
    // Next goes to the review: no instructions step, God writes nothing.
    await tap(tester, 'new-agent-next');
    expect(find.byKey(const Key('new-tool-fetch')), findsNothing);
    await tap(tester, 'new-agent-next');
    await _settle(tester);
    final made = server.newAgents.single;
    expect(made['kind'], 'assistant');
    expect(made['preset'], 'email');
    expect(made['name'], 'Email');
    expect(made['connections'], [
      {'kind': 'mailbox', 'ref': 'w1'},
      {'kind': 'mailbox', 'ref': 'w2'},
    ]);
    await done(tester);
  });

  testWidgets('an agent\'s connections: every kind, any number, saved as typed references', (
    tester,
  ) async {
    ch.boxes.add({
      'id': 'w1',
      'name': 'Lavoro',
      'category': 'work',
      'host': 'imap.work.it',
      'port': 993,
      'secure': true,
      'user': 'm@work.it',
      'agents': true,
    });
    ch.linkTelegram(42, 'mario');
    ch.linkChat('whatsapp', '39333', null);
    ch.calendars.addAll([
      {
        'id': 'cal_1',
        'name': 'Casa',
        'kind': 'caldav',
        'url': 'https://dav/x/',
        'writable': true,
        'agents': true,
      },
      {
        'id': 'cal_2',
        'name': 'Google',
        'kind': 'ics',
        'url': 'google.com',
        'writable': false,
        'agents': true,
      },
    ]);
    server.agentOverrides['a5'] = {
      'connections': [
        {'kind': 'mailbox', 'ref': 'gone_box'},
      ],
    };
    final app = await start(tester);
    final a5 = app.agents.firstWhere((a) => a.id == 'a5');
    await push(
      tester,
      AgentSettingsScreen(agentId: 'a5', agent: a5, initial: AgentGroup.connections),
    );
    expect(find.byKey(const Key('as-connections')), findsOneWidget);
    expect(find.text('Lavoro'), findsOneWidget);
    expect(find.text('Telegram'), findsOneWidget);
    expect(find.text('Whatsapp'), findsOneWidget);
    expect(find.text('Solo lettura'), findsOneWidget);
    // What was connected and is gone can be switched off.
    expect(find.byKey(const Key('conn-gone-mailbox-gone_box')), findsOneWidget);
    for (final k in [
      'conn-mailbox-w1',
      'conn-chat-telegram',
      'conn-chat-whatsapp',
      'conn-calendar-cal_1',
      'conn-calendar-cal_2',
      'conn-gone-mailbox-gone_box',
    ]) {
      await tap(tester, k);
    }
    await tap(tester, 'as-save-connections');
    final saved = (server.patches.last['connections'] as List).cast<Map<String, dynamic>>();
    expect(saved.map((c) => '${c['kind']}:${c['ref']}').toSet(), {
      'mailbox:w1',
      'chat:telegram',
      'chat:whatsapp',
      'calendar:cal_1',
      'calendar:cal_2',
    });
    await done(tester);
  });

  testWidgets('calendars: a CalDAV one with its password, an iCal address read only, remove', (
    tester,
  ) async {
    await start(tester);
    await push(tester, const Scaffold(body: SingleChildScrollView(child: CalendarsSection())));
    expect(find.byKey(const Key('calendar-add')), findsOneWidget);
    await tap(tester, 'calendar-add');
    await tester.enterText(find.byKey(const Key('cal-name')), 'Casa');
    await tester.enterText(find.byKey(const Key('cal-url')), 'https://dav.example/me/casa/');
    await tester.enterText(find.byKey(const Key('cal-user')), 'marta');
    await tester.enterText(find.byKey(const Key('cal-password')), 'wrong-password');
    await tap(tester, 'cal-save');
    expect(find.text('The server refused the user or the password'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('cal-password')), 's3cret');
    await tap(tester, 'cal-agents');
    await tap(tester, 'cal-save');
    final body = ch.bodies['POST /api/settings/calendars'] as Map;
    expect(body, {
      'name': 'Casa',
      'kind': 'caldav',
      'url': 'https://dav.example/me/casa/',
      'user': 'marta',
      'password': 's3cret',
      'agents': true,
    });
    // The secret never comes back.
    expect(ch.calendars.single.containsKey('password'), isFalse);
    expect(find.text('CalDAV · si scrive'), findsOneWidget);
    // An iCal address: no user, no password, and Google's limit said out loud.
    await tap(tester, 'calendar-add');
    await tap(tester, 'cal-kind-ics');
    expect(find.byKey(const Key('cal-user')), findsNothing);
    expect(
      find.textContaining('Scrivere su Google Calendar con l\'accesso non c\'è'),
      findsOneWidget,
    );
    await tester.enterText(find.byKey(const Key('cal-name')), 'Google');
    await tester.enterText(
      find.byKey(const Key('cal-url')),
      'https://calendar.google.com/ical/secret/basic.ics',
    );
    await tap(tester, 'cal-save');
    expect(ch.calendars.last['writable'], false);
    expect(find.text('iCal · solo lettura'), findsOneWidget);
    // Remove.
    await tap(tester, 'calendar-${ch.calendars.first['id']}');
    await tap(tester, 'cal-remove');
    expect(ch.calendars, hasLength(1));
    await done(tester);
  });
}
