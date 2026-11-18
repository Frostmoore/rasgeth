// Proposal A (decision D9): the bar Team | Chat | For you | Activity | You, the Chat's field
// always over it, it/en, themes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/mascot/mascot_source.dart';
import 'package:rgcompanion/mascot/mascot_view.dart';

import 'helpers.dart';

class FixtureMascots implements MascotSource {
  FixtureMascots(this.byId);

  final Map<String, MascotFixture> byId;
  final asked = <String>[];

  @override
  Future<String> svg(String agentId, MascotState state, MascotTheme theme, {bool tiny = false}) {
    asked.add('$agentId ${state.name} ${theme.name}');
    final f = byId[agentId]!;
    return Future.value(tiny ? f.tiny : f.svgOf(theme, state));
  }
}

AppController _controller({Locale locale = const Locale('it')}) =>
    AppController(tokens: MemoryTokenStore(), platform: DevicePlatform.android)
      ..locale = locale
      ..reduceMotion = true;

Future<void> _pump(WidgetTester tester, AppController app) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the six places, in order, in Italian (Projects for everyone, G42.5)', (
    tester,
  ) async {
    final app = _controller();
    await _pump(tester, app);
    final labels = ['Squadra', 'Chat', 'Da te', 'Attività', 'Progetti', 'Tu'];
    final xs = [for (final t in app.tabs) tester.getCenter(find.byKey(Key('tab-${t.name}'))).dx];
    expect(xs, orderedEquals([...xs]..sort()));
    for (final (i, t) in app.tabs.indexed) {
      expect(
        find.descendant(of: find.byKey(Key('tab-${t.name}')), matching: find.text(labels[i])),
        findsOneWidget,
      );
    }
    expect(app.tab, AppTab.team);
    expect(find.text('Nessun RedGiant collegato'), findsOneWidget);
  });

  testWidgets('each tab opens its place; the Chat field stays over the bar', (tester) async {
    final app = _controller();
    await _pump(tester, app);
    final headers = {
      AppTab.chat: 'Chat',
      AppTab.inbox: 'Da te',
      AppTab.activity: 'Attività',
      AppTab.you: 'Tu',
      AppTab.team: 'Nessun RedGiant collegato',
    };
    for (final MapEntry(key: tab, value: title) in headers.entries) {
      await tester.tap(find.byKey(Key('tab-${tab.name}')));
      await tester.pumpAndSettle();
      expect(app.tab, tab);
      expect(find.text(title).hitTestable(), findsWidgets);
      final field = tester.getRect(find.byKey(const Key('chat-field')));
      final bar = tester.getRect(find.byKey(const Key('tab-team')));
      expect(field.bottom, lessThanOrEqualTo(bar.top));
    }
    expect(
      tester.getSemantics(find.byKey(const Key('tab-team'))),
      isSemantics(label: 'Squadra', isButton: true, isSelected: true),
    );
  });

  testWidgets('the field starts a new conversation with Chat at once', (tester) async {
    final app = _controller();
    await _pump(tester, app);
    await tester.tap(find.byKey(const Key('tab-activity')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('chat-field')), 'Che tempo fa domani?');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(app.tab, AppTab.chat);
    // Taken by the Chat at once; without a RedGiant it says where to connect one.
    expect(app.chatDraft, isNull);
    expect(find.text('Collegalo da Tu.'), findsWidgets);
    final field = tester.widget<TextField>(find.byKey(const Key('chat-field')));
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('an empty field sends nothing', (tester) async {
    final app = _controller();
    await _pump(tester, app);
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(app.tab, AppTab.team);
    expect(app.chatDraft, isNull);
  });

  testWidgets('in English', (tester) async {
    await _pump(tester, _controller(locale: const Locale('en')));
    for (final l in ['Team', 'Chat', 'For you', 'Activity', 'Projects', 'You']) {
      expect(find.text(l), findsWidgets);
    }
    expect(find.text('No RedGiant connected'), findsOneWidget);
  });

  testWidgets('You › Theme switches the app to dark and back', (tester) async {
    final app = _controller();
    await _pump(tester, app);
    await tester.tap(find.byKey(const Key('tab-you')));
    await tester.pumpAndSettle();
    // Under the RedGiants and «Set up a new RedGiant» (G40.8).
    await tester.scrollUntilVisible(
      find.byKey(const Key('reduce-motion')),
      200,
      scrollable: find
          .descendant(of: find.byKey(const Key('you-list')), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scuro'));
    await tester.pumpAndSettle();
    expect(app.themeMode, ThemeMode.dark);
    final ctx = tester.element(find.byKey(const Key('chat-field')));
    expect(Theme.of(ctx).brightness, Brightness.dark);
    expect(Theme.of(ctx).scaffoldBackgroundColor, const Color(0xFF15171C));
    await tester.tap(find.text('Chiaro'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byKey(const Key('chat-field')))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'the team shows God, then first-level agents with their mascots and states in words',
    (tester) async {
      final fixtures = loadMascots();
      final byId = {for (final (i, f) in fixtures.indexed) 'a$i': f};
      final source = FixtureMascots(byId);
      final app = _controller()
        ..agents = [
          for (final MapEntry(key: id, value: f) in byId.entries)
            Agent(id: id, kind: f.spec.kind, name: f.seed, active: true, mascot: f.spec),
        ]
        ..mascots = source;
      await _pump(tester, app);
      await settleSvgs(tester);
      expect(find.byKey(const Key('team-grid')), findsOneWidget);
      // Subagents and inspectors are not first level.
      expect(find.text('Tester'), findsNothing);
      expect(find.text('Revisore'), findsNothing);
      expect(find.text('God'), findsOneWidget);
      // Demi-God (Telegram's voice) is not in Team.
      expect(find.text('Demi'), findsNothing);
      // God's card and the agents' grid (the Chat's card waits for its agent).
      expect(find.byType(MascotView), findsNWidgets(5));
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Mascotte di God, fermo',
        ),
        findsOneWidget,
      );
      expect(source.asked, contains('a0 idle light'));
    },
  );
}
