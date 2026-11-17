// A request's screen always has a way out (p3.8.9, after a screen left with no exit once answered
// from the page): the close button, Esc, and, answered elsewhere, the answer said with «Close» and
// a close by itself. The plain line comes first, the command below.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';

AppController _app() => AppController(
  tokens: MemoryTokenStore(),
  prefs: MemoryAppPrefs(),
  platform: DevicePlatform.android,
  liveEnabled: false,
)..locale = const Locale('it');

const _what =
    'Scrive lo script /tmp/gaia-shared/start-wp.sh e lo esegue (start), poi contatta 127.0.0.1:8088';

Map<String, dynamic> _req(String id, {bool critical = true}) => {
  'requestId': id,
  'agentId': 'a0',
  'agentName': 'Ambiente e QA',
  'projectId': null,
  'tool': 'bash',
  'input': {'command': "cat > /tmp/gaia-shared/start-wp.sh <<'EOF'\nrm -rf \"\$OUT/\"\nEOF"},
  'reasons': ['truly dangerous: deletes \$OUT/'],
  'danger': critical ? ['critical-delete'] : <String>[],
  if (critical)
    'critical': [
      {'id': 'critical-delete', 'action': 'delete-variable', 'target': '\$OUT/'},
    ],
  'words': {
    'it': {
      'what': _what,
      'reasons': <String>[],
      'critical': critical ? ['Cancella per sempre \$OUT/: se la variabile è vuota…'] : <String>[],
      'dangers': <Map<String, String>>[],
    },
  },
  'createdAt': '2026-11-17T10:00:00.000Z',
};

Future<AppController> _open(WidgetTester tester, {bool critical = true}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final app = _app();
  app.live.apply({'type': 'permission.request', 'request': _req('r1', critical: critical)});
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('tab-inbox')));
  await tester.pumpAndSettle();
  if (critical) {
    await tester.tap(find.byKey(const Key('open-r1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critical-screen')), findsOneWidget);
  }
  return app;
}

void main() {
  testWidgets('the plain line first, the command small below', (tester) async {
    await _open(tester);
    expect(find.byKey(const Key('critical-what')), findsOneWidget);
    expect(find.text(_what), findsOneWidget);
    final what = tester.getTopLeft(find.byKey(const Key('critical-what')));
    final input = tester.getTopLeft(find.byKey(const Key('critical-input')));
    expect(what.dy, lessThan(input.dy));
  });

  testWidgets('the ordinary card in For you says the plain line too', (tester) async {
    await _open(tester, critical: false);
    expect(find.byKey(const Key('inbox-what-r1')), findsOneWidget);
    expect(find.text(_what), findsOneWidget);
  });

  testWidgets('the close button leaves the screen, the request still waiting', (tester) async {
    final app = await _open(tester);
    await tester.tap(find.byKey(const Key('critical-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critical-screen')), findsNothing);
    expect(app.live.approvals.map((r) => r.requestId), contains('r1'));
  });

  testWidgets('Esc leaves the screen', (tester) async {
    await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critical-screen')), findsNothing);
  });

  testWidgets('answered from the page: says so with the answer, «Close» closes', (tester) async {
    final app = await _open(tester);
    app.live.apply({
      'type': 'permission.closed',
      'requestId': 'r1',
      'decision': 'allow',
      'via': 'web',
    });
    await tester.pump();
    expect(
      find.text("Hai già risposto dalla pagina o da un'altra finestra: consentita."),
      findsOneWidget,
    );
    expect(find.byKey(const Key('critical-yes')), findsNothing);
    expect(find.byKey(const Key('critical-close')), findsOneWidget);
    await tester.tap(find.byKey(const Key('critical-done-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critical-screen')), findsNothing);
  });

  testWidgets('answered elsewhere: closes by itself after a few seconds', (tester) async {
    final app = await _open(tester);
    app.live.apply({
      'type': 'permission.closed',
      'requestId': 'r1',
      'decision': 'deny',
      'via': 'timeout',
    });
    await tester.pump();
    expect(find.text('Nessuno ha risposto in tempo: negata.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('critical-screen')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critical-screen')), findsNothing);
  });
}
