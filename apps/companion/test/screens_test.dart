// The screens of G40.7: For you (critical requests full screen, never the quick yes), a
// conversation (reasoning folded, safe Markdown), the RedGiants in You.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/conversation_screen.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/markdown.dart';

AppController _app() => AppController(
  tokens: MemoryTokenStore(),
  prefs: MemoryAppPrefs(),
  platform: DevicePlatform.android,
  liveEnabled: false,
)..locale = const Locale('it');

Future<void> _pump(WidgetTester tester, AppController app) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

Widget _alone(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  locale: const Locale('it'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Map<String, dynamic> _req(String id, {bool critical = false}) => {
  'requestId': id,
  'agentId': 'a0',
  'agentName': 'God',
  'projectId': null,
  'tool': 'run_command',
  'input': {'command': critical ? 'rm -rf /srv' : 'npm install'},
  'reasons': [critical ? 'deletes for good' : 'installs packages'],
  'danger': critical ? ['critical-delete'] : <String>[],
  if (critical)
    'critical': [
      {'id': 'critical-delete', 'action': 'delete-disk', 'target': '/srv'},
    ],
  'createdAt': '2026-11-15T10:0${critical ? 1 : 0}:00.000Z',
};

void main() {
  testWidgets('For you: Yes/No on ordinary requests; critical ones only from their screen', (
    tester,
  ) async {
    final app = _app();
    app.live
      ..apply({'type': 'permission.request', 'request': _req('r1')})
      ..apply({'type': 'permission.request', 'request': _req('r2', critical: true)});
    await _pump(tester, app);
    // The pill on Team counts them.
    expect(find.text('2'), findsWidgets);
    await tester.tap(find.byKey(const Key('tab-inbox')));
    await tester.pumpAndSettle();
    // The critical one on top of the stack: no quick yes.
    expect(find.byKey(const Key('allow-r2')), findsNothing);
    expect(find.text('Davvero pericolosa, da God'), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-later')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('allow-r1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('inbox-later')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open-r2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('critical-screen')), findsOneWidget);
    expect(find.text('Cancellazione definitiva: /srv'), findsOneWidget);
    // The yes asks once more; cancelling leaves the request waiting.
    await tester.tap(find.byKey(const Key('critical-yes')));
    await tester.pumpAndSettle();
    expect(find.text('Sei sicuro?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dialog-no')));
    await tester.pumpAndSettle();
    expect(app.live.approvals.map((r) => r.requestId), contains('r2'));
    // Answered elsewhere meanwhile: the screen says where.
    app.live.apply({
      'type': 'permission.closed',
      'requestId': 'r2',
      'decision': 'deny',
      'via': 'telegram',
    });
    await tester.pumpAndSettle();
    expect(find.text('Già risposta (telegram).'), findsOneWidget);
    expect(find.byKey(const Key('critical-yes')), findsNothing);
  });

  testWidgets('a question: its options, the answer only once each one has a choice', (
    tester,
  ) async {
    final app = _app();
    app.live.apply({
      'type': 'question.request',
      'request': {
        'requestId': 'q1',
        'sessionId': 's1',
        'agentId': 'a0',
        'agentName': 'God',
        'projectId': null,
        'questions': [
          {
            'question': 'Quale database?',
            'options': [
              {'label': 'Postgres'},
              {'label': 'SQLite'},
            ],
            'multiSelect': false,
          },
        ],
        'createdAt': '2026-11-15T10:00:00.000Z',
      },
    });
    await _pump(tester, app);
    await tester.tap(find.byKey(const Key('tab-inbox')));
    await tester.pumpAndSettle();
    final answer = find.byKey(const Key('answer-q1'));
    expect(tester.widget<FilledButton>(answer).onPressed, isNull);
    await tester.tap(find.byKey(const Key('option-q1-0-SQLite')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(answer).onPressed, isNotNull);
    // No socket here: it says so instead of pretending.
    await tester.tap(answer);
    await tester.pumpAndSettle();
    expect(find.textContaining('connessione viva'), findsOneWidget);
  });

  testWidgets('an answer: the reasoning folded, Markdown without raw HTML nor remote images', (
    tester,
  ) async {
    await tester.pumpWidget(
      _alone(
        ChatItemView(
          item: AssistantItem(
            text:
                'Ecco **fatto**. <img src="https://tracker.example/x.png"> '
                '![logo](https://tracker.example/logo.png)\n\n- [x] uno\n- [ ] due',
            thinking: 'Prima guardo i file.',
            ts: '',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ragionamento'), findsOneWidget);
    expect(find.byKey(const Key('thinking-text')), findsNothing);
    await tester.tap(find.byKey(const Key('thinking-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('thinking-text')), findsOneWidget);
    // The tag is text, not an element; the picture is not fetched (its alt text shows).
    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('<img', findRichText: true), findsOneWidget);
    expect(find.text('logo'), findsOneWidget);
    // Task lists with our marks, never the system's checkboxes.
    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(SafeMarkdown), findsOneWidget);
  });

  testWidgets('a file the agent handed over opens the Canvas', (tester) async {
    await tester.pumpWidget(
      _alone(
        const ChatItemView(
          item: FileItem(
            scope: 'project:demo',
            path: 'docs/report.pdf',
            name: 'report.pdf',
            mime: 'application/pdf',
            size: 1000,
          ),
        ),
      ),
    );
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('Apri'), findsOneWidget);
  });

  testWidgets('You: the RedGiants saved, how each is reached, its pinned key', (tester) async {
    final app = _app()
      ..servers = const [
        SavedServer(
          id: 'casa',
          label: 'Casa',
          address: 'https://redgiant.local',
          fingerprint: 'SHA256:abc',
          caPem: '-----BEGIN CERTIFICATE-----',
        ),
        SavedServer(id: 'lavoro', label: 'Lavoro', address: 'https://lavoro.tail1.ts.net'),
      ];
    await _pump(tester, app);
    await tester.tap(find.byKey(const Key('tab-you')));
    await tester.pumpAndSettle();
    expect(find.text('Casa'), findsOneWidget);
    expect(find.text('Lavoro'), findsOneWidget);
    expect(find.textContaining('solo con il suo certificato'), findsOneWidget);
    expect(find.textContaining('https pubblico'), findsOneWidget);
    expect(find.text('Chiave: SHA256:abc'), findsOneWidget);
    expect(find.byKey(const Key('use-lavoro')), findsOneWidget);
  });
}
