// G42.0: `EmbedView`, the page inside the app, with a web view of the test's own. The app's
// indicator until the page says it is drawn, the bridge only with the nonce, back asked to the
// page first, the clipboard the app's, the app's theme and language followed, a native error with
// «Try again», the right engine on every system, and «All settings» inside the app everywhere.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/embed/embed_view.dart';
import 'package:rgcompanion/embed/web_host.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/full_settings_screen.dart';
import 'package:rgcompanion/theme/theme.dart';

class FakeWebHost implements WebHost {
  final out = StreamController<String>.broadcast();
  final scripts = <String>[];
  Uri? loaded;
  WebRules? rules;
  int reloads = 0;
  bool disposed = false;

  /// The page answers the app's back with this (null: it does not answer).
  bool? answersBack = false;
  String nonce = 'n0nce-n0nce_n0nce';

  void say(Map<String, Object?> m, {String? withNonce}) =>
      out.add(jsonEncode({'rg': 'embed', 'n': withNonce ?? nonce, 'm': m}));

  @override
  Stream<String> get messages => out.stream;

  @override
  Future<void> load(Uri url, WebRules r) async {
    loaded = url;
    rules = r;
  }

  @override
  Future<void> run(String script) async {
    scripts.add(script);
    if (script.contains('"t":"back"') && answersBack != null) {
      scheduleMicrotask(() => say({'t': 'back', 'handled': answersBack}));
    }
  }

  @override
  Future<void> reload() async => reloads++;

  @override
  Widget view({required bool eager}) => const SizedBox.expand(key: Key('fake-web'));

  @override
  void dispose() => disposed = true;
}

void main() {
  late FakeWebHost host;
  late AppController app;
  WebEngine? asked;

  setUp(() {
    host = FakeWebHost();
    asked = null;
    debugWebHost = (e) {
      asked = e;
      return host;
    };
  });
  tearDown(() => debugWebHost = null);

  Widget wrap(
    Widget child, {
    ThemeMode mode = ThemeMode.light,
    Locale locale = const Locale('it'),
  }) => AppScope(
    controller: app,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );

  Future<void> show(
    WidgetTester tester, {
    DevicePlatform platform = DevicePlatform.android,
    String? nonce = 'n0nce-n0nce_n0nce',
    ThemeMode mode = ThemeMode.light,
    Locale locale = const Locale('it'),
    void Function(EmbedTitle)? onTitle,
  }) async {
    app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: platform);
    await tester.pumpWidget(
      wrap(
        EmbedView(
          url: Uri.parse('https://rg.local:7443/embed.html#token=t&embed=probe'),
          nonce: nonce,
          onTitle: onTitle,
        ),
        mode: mode,
        locale: locale,
      ),
    );
    await tester.pump();
  }

  test('the engine of every system', () {
    expect(webEngineFor(DevicePlatform.android), WebEngine.flutter);
    expect(webEngineFor(DevicePlatform.ios), WebEngine.flutter);
    expect(webEngineFor(DevicePlatform.macos), WebEngine.flutter);
    expect(webEngineFor(DevicePlatform.windows), WebEngine.windows);
    expect(webEngineFor(DevicePlatform.linux), WebEngine.linux);
  });

  test('only the server stays inside the view', () {
    final r = WebRules(
      origin: Uri.parse('https://rg.local:7443/embed.html'),
      background: Colors.black,
    );
    expect(r.stays(Uri.parse('https://rg.local:7443/api/x')), isTrue);
    expect(r.stays(Uri.parse('about:blank')), isTrue);
    expect(r.stays(Uri.parse('https://rg.local:8443/')), isFalse);
    expect(r.stays(Uri.parse('https://evil.example/')), isFalse);
    expect(r.stays(Uri.parse('http://rg.local:7443/')), isFalse);
  });

  testWidgets('the app\'s indicator until the page is drawn; only its nonce counts', (
    tester,
  ) async {
    EmbedTitle? title;
    await show(tester, onTitle: (t) => title = t, platform: DevicePlatform.linux);
    expect(asked, WebEngine.linux);
    expect(host.loaded.toString(), 'https://rg.local:7443/embed.html#token=t&embed=probe');
    expect(host.rules?.background, const Color(0xFFF6F7F9));
    expect(find.byKey(embedWaitKey), findsOneWidget);
    host.say({'t': 'ready'}, withNonce: 'another-nonce-12345');
    await tester.pump();
    expect(find.byKey(embedWaitKey), findsOneWidget);
    host
      ..say({'t': 'title', 'name': 'a.xlsx', 'kind': 'sheet', 'size': 10})
      ..say({'t': 'ready'});
    await tester.pump();
    await tester.pump();
    expect(find.byKey(embedWaitKey), findsNothing);
    expect(title?.name, 'a.xlsx');
    expect(title?.kind, 'sheet');
  });

  testWidgets('back: the page first; when it took it the screen stays', (tester) async {
    await show(tester);
    host.say({'t': 'ready'});
    await tester.pump();
    final s = tester.state<EmbedViewState>(find.byType(EmbedView));
    host.answersBack = true;
    expect(await tester.runAsync(s.pageTookBack), isTrue);
    host.answersBack = false;
    expect(await tester.runAsync(s.pageTookBack), isFalse);
    host.answersBack = null; // the page never answers: the app goes back itself
    expect(await tester.runAsync(s.pageTookBack), isFalse);
    expect(host.scripts.where((x) => x.contains('"t":"back"')), hasLength(3));
  });

  testWidgets('what the page copies goes to the app\'s clipboard', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      c,
    ) async {
      if (c.method == 'Clipboard.setData') copied.add((c.arguments as Map)['text'] as String);
      return null;
    });
    await show(tester);
    host.say({'t': 'copy', 'text': 'ciao'});
    await tester.pump();
    expect(copied, ['ciao']);
    expect(find.text('Copiato'), findsOneWidget);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('the app\'s theme and language follow into the page', (tester) async {
    await show(tester);
    host.say({'t': 'ready'});
    await tester.pump();
    final view = EmbedView(
      url: Uri.parse('https://rg.local:7443/embed.html#token=t&embed=probe'),
      nonce: host.nonce,
    );
    await tester.pumpWidget(wrap(view, mode: ThemeMode.dark));
    await tester.pump(const Duration(seconds: 1));
    expect(host.scripts, contains(contains('"t":"theme","theme":"dark"')));
    await tester.pumpWidget(wrap(view, mode: ThemeMode.dark, locale: const Locale('en')));
    await tester.pump(const Duration(seconds: 1));
    expect(host.scripts, contains(contains('"t":"lang","lang":"en"')));
  });

  testWidgets('an error is said in the app, with «Try again»; the web view leaves', (tester) async {
    await show(tester);
    host.rules?.onError?.call('certificate');
    await tester.pump();
    expect(find.byKey(const Key('embed-error')), findsOneWidget);
    expect(find.byKey(const Key('fake-web')), findsNothing);
    await tester.tap(find.byKey(const Key('embed-retry')));
    await tester.pump();
    expect(host.reloads, 1);
    expect(find.byKey(const Key('fake-web')), findsOneWidget);
  });

  testWidgets('the whole page (no bridge) is ready once loaded', (tester) async {
    await show(tester, nonce: null);
    expect(find.byKey(embedWaitKey), findsOneWidget);
    host.rules?.onProgress?.call(100);
    await tester.pump();
    expect(find.byKey(embedWaitKey), findsNothing);
  });

  for (final p in [DevicePlatform.windows, DevicePlatform.linux, DevicePlatform.android]) {
    testWidgets('«All settings» inside the app on ${p.name}, token in the fragment', (
      tester,
    ) async {
      app = AppController(tokens: MemoryTokenStore(), prefs: MemoryAppPrefs(), platform: p);
      await tester.pumpWidget(
        wrap(
          FullSettingsScreen(
            base: Uri.parse('https://rg.local:7443'),
            token: 'rgd_x',
            title: 'Casa',
          ),
        ),
      );
      await tester.pump();
      expect(asked, webEngineFor(p));
      expect(
        host.loaded.toString(),
        'https://rg.local:7443/#token=rgd_x&open=settings&theme=light&lang=it',
      );
      expect(host.loaded?.query, isEmpty);
      expect(find.text('Casa'), findsOneWidget);
    });
  }
}
