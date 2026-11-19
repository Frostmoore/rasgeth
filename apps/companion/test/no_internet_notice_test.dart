// Without internet (3.9.1, as the page's banner): what on the server waits for the network is
// said over the home, read again while something waits, and gone once it connected.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/theme/theme.dart';
import 'package:rgcompanion/ui/no_internet_notice.dart';

import 'fake_server.dart';

void main() {
  test('the labels of GET /api/platform (table)', () {
    for (final (body, want) in [
      (
        {
          'waitingNetwork': [
            {'id': 'key:anthropic', 'label': 'Anthropic'},
            {'id': 'telegram', 'label': 'Telegram'},
          ],
        },
        ['Anthropic', 'Telegram'],
      ),
      ({'waitingNetwork': <Object>[]}, <String>[]),
      // A server before 3.9.1 says nothing of it.
      ({'sandbox': 'host'}, <String>[]),
      (null, <String>[]),
    ]) {
      expect(NoInternetModel.labelsOf(body), want, reason: '$body');
    }
  });

  group('the server in use', () {
    late FakeRedGiant server;
    var waiting = <Map<String, String>>[];
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      waiting = [
        {'id': 'key:openai', 'label': 'OpenAI'},
        {'id': 'telegram', 'label': 'Telegram'},
      ];
      server.routes['GET /api/platform'] = (r) async {
        r.response.headers.contentType = ContentType.json;
        r.response.write(jsonEncode({'sandbox': 'host', 'waitingNetwork': waiting}));
        await r.response.close();
      };
    });
    tearDown(() => server.close());

    testWidgets('said over the home, gone once the network is back', (tester) async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
        liveEnabled: false,
      )..reduceMotion = true;
      app.noInternet.every = const Duration(milliseconds: 50);
      await tester.runAsync(app.restore);
      app.locale = const Locale('it');
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await tester.runAsync(() => app.noInternet.refresh(app.client));
      expect(app.noInternet.parts, ['OpenAI', 'Telegram']);
      // The notice alone (the home's other screens read the server too).
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            locale: const Locale('it'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const Scaffold(body: NoInternetNotice()),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('no-internet-notice')), findsOneWidget);
      expect(find.textContaining('In attesa della rete: OpenAI, Telegram'), findsOneWidget);

      // The network is back: the next read empties the list and the notice goes.
      waiting = [];
      await tester.runAsync(() async {
        for (var i = 0; i < 100 && app.noInternet.parts.isNotEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pump();
      expect(app.noInternet.parts, isEmpty);
      expect(find.byKey(const Key('no-internet-notice')), findsNothing);
      app.noInternet.clear();
    });
  });
}
