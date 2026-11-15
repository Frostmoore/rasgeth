// The first start's and the settings' rules as tables (G40.8), the client of the settings against
// the fake RedGiant, and their screens: «Settings of <name>», the first start's own steps.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/names.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/settings_types.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/api/web_settings.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations_it.dart';
import 'package:rgcompanion/screens/first_start_screen.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/setup/first_start.dart';
import 'package:rgcompanion/setup/wifi.dart';

import 'fake_server.dart';
import 'fake_wifi.dart';

AppController _app({DevicePlatform platform = DevicePlatform.android}) =>
    AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: platform,
        liveEnabled: false,
      )
      ..locale = const Locale('it')
      ..reduceMotion = true;

Future<void> _pump(WidgetTester tester, AppController app) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RGCompanionApp(controller: app));
  await tester.pumpAndSettle();
}

/// Real requests in a widget test: real time for the sockets, then the frames, a few times over.
Future<void> _settle(WidgetTester tester, [int rounds = 20]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  group('rules', () {
    test('the readable name: never a container\'s id', () {
      for (final (label, machine, shown) in [
        ('350003b5f4e6', '350003b5f4e6', 'RedGiant'),
        (null, '350003b5f4e6', 'RedGiant'),
        ('Casa', '350003b5f4e6', 'Casa'),
        ('350003b5f4e6', 'Mini PC salotto', 'Mini PC salotto'),
        (null, 'redgiant', 'RedGiant'),
        (null, 'localhost', 'RedGiant'),
        ('', '', 'RedGiant'),
        (null, 'coder', 'coder'),
        (null, 'deadbeefcafe0123', 'RedGiant'),
        (null, 'cafe', 'cafe'),
        (null, '20251115', '20251115'),
      ]) {
        expect(
          readableName(label: label, machine: machine),
          shown,
          reason: '$label $machine',
        );
      }
    });

    test('«All settings»: a WebView where there is one, never over plain http on the network', () {
      for (final (p, k, m) in [
        (DevicePlatform.android, TransportKind.pinnedHttps, FullSettingsMode.webView),
        (DevicePlatform.ios, TransportKind.publicHttps, FullSettingsMode.webView),
        (DevicePlatform.macos, TransportKind.loopback, FullSettingsMode.webView),
        (DevicePlatform.windows, TransportKind.loopback, FullSettingsMode.browser),
        (DevicePlatform.linux, TransportKind.pinnedHttps, FullSettingsMode.browser),
        (DevicePlatform.android, TransportKind.channel, FullSettingsMode.unavailable),
        (DevicePlatform.linux, TransportKind.channel, FullSettingsMode.unavailable),
      ]) {
        expect(fullSettingsMode(p, k), m, reason: '$p $k');
      }
    });

    test('the token rides the fragment, never the query', () {
      final u = fullSettingsUrl(Uri.parse('https://redgiant.local:8443'), token: 'rgd_a+b/c');
      expect(u.toString(), 'https://redgiant.local:8443/#token=rgd_a%2Bb%2Fc&open=settings');
      expect(u.query, isEmpty);
      expect(
        fullSettingsUrl(Uri.parse('https://x.ts.net')).toString(),
        'https://x.ts.net/#open=settings',
      );
    });

    test('a certificate goes on only when it is the very one checked against the local CA', () {
      for (final (presented, pinned, ok) in [
        (<int>[1, 2, 3], <int>[1, 2, 3], true),
        (<int>[1, 2, 3], <int>[1, 2, 4], false),
        (<int>[1, 2], <int>[1, 2, 3], false),
        (null, <int>[1, 2, 3], false),
        (<int>[1, 2, 3], null, false),
        (<int>[], <int>[], false),
      ]) {
        expect(sslProceed(presented, pinned), ok, reason: '$presented $pinned');
      }
      expect(sameOrigin(Uri.parse('https://a.local/x'), Uri.parse('https://a.local')), isTrue);
      expect(sameOrigin(Uri.parse('https://a.local:8443/'), Uri.parse('https://a.local')), isFalse);
      expect(sameOrigin(Uri.parse('https://evil.example/'), Uri.parse('https://a.local')), isFalse);
    });

    test('the first start\'s line only goes forward', () {
      final order = [
        FsStep.intro,
        FsStep.connecting,
        FsStep.access,
        FsStep.home,
        FsStep.homeWait,
        FsStep.language,
        FsStep.brain,
        FsStep.names,
        FsStep.finishing,
        FsStep.done,
      ];
      final values = [for (final s in order) progressOf(s)];
      for (var i = 1; i < values.length; i++) {
        expect(values[i], greaterThanOrEqualTo(values[i - 1]));
      }
      expect(values.last, 1);
    });

    test('the helper\'s reasons in words, a fallback for the unknown ones', () {
      final l = AppLocalizationsIt();
      expect(homeErrorText(l, 'connect_failed'), contains('password'));
      expect(homeErrorText(l, 'no_cable'), contains('cavo'));
      expect(homeErrorText(l, 'something_new'), l.homeErrFailed);
    });

    test('3.8.1\'s bar and steps, read when the server has them', () {
      final u = UpdateStatus.fromJson({
        'install': 'windows',
        'installed': '3.8.0',
        'latest': '3.8.1',
        'state': 'available',
        'gate': 'normal',
        'canUpdateHere': true,
        'progress': {
          'version': '3.8.1',
          'phase': 'download',
          'done': 50,
          'total': 200,
          'bps': 10,
          'eta': 15,
          'at': 'x',
        },
      });
      expect(u.phase, 'download');
      expect(u.progress!.fraction, .25);
      final older = UpdateStatus.fromJson({'install': 'docker', 'state': 'latest', 'gate': 'none'});
      expect(older.progress, isNull);
      final os = OsUpdates.fromJson({
        'available': true,
        'running': true,
        'update': {
          'state': 'applying',
          'step': 'download',
          'run': {
            'steps': ['check', 'download'],
            'progress': {'done': 1, 'total': 4, 'bps': 2, 'eta': 90, 'items': []},
          },
        },
      });
      expect(os.steps, ['check', 'download']);
      expect(os.progress!.fraction, .25);
      final l = AppLocalizationsIt();
      expect(
        progressText(
          l,
          const Progress(done: 50 * 1048576, total: 200 * 1048576, bps: 2 * 1048576, eta: 90),
        ),
        '50.0 MB di 200 MB · 2.0 MB/s · mancano 2 min',
      );
      expect(updateStepText(l, 'rollback'), 'Ritorno alla versione di prima');
    });
  });

  group('the settings\' client', () {
    late FakeRedGiant server;
    setUp(() async {
      // flutter_test answers every HttpClient with 400 once a widget test is in the file.
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    test('devices, a sign-out, a test notification, updates, the model, the name', () async {
      final app = _app();
      expect(await app.connect(server.base.toString(), 'secret'), isTrue);
      final c = app.client!;
      final devices = await c.devices();
      expect(devices.map((d) => d.name), contains('Telefono di Mario'));
      expect(devices.firstWhere((d) => d.current).push?['target'], 'ntfy.sh');
      await c.revokeDevice('d2');
      expect(server.devices.map((d) => d['id']), ['d1']);
      expect(await c.pushTest('d1'), isNull);
      expect(server.pushTests, ['d1']);
      final u = await c.updateStatus();
      expect(u.available, isTrue);
      expect(u.noteIn('it'), contains('passo'));
      expect((await c.updateLook()).checkedAt, '2026-11-15T12:00:00.000Z');
      await c.updateNow();
      expect(server.updateActs, 1);
      expect(await c.osUpdates(), isNull);
      final s = await c.setupSummary();
      expect(s.defaultModel, 'anthropic/claude-sonnet-5');
      expect(s.remoteUrl, 'https://casa.tail1234.ts.net');
      expect((await c.models()).map((m) => m.label), contains('Claude Haiku 5'));
      await c.setDefaultModel('anthropic', 'claude-haiku-5', effort: 'medium');
      expect((await c.setupSummary()).defaultModel, 'anthropic/claude-haiku-5');
      await app.renameRedGiant('Casa Rossi');
      expect(server.machine, 'Casa Rossi');
      expect(app.displayName, 'Casa Rossi');
      expect(app.server!.label, 'Casa Rossi');
    });
  });

  group('screens', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    testWidgets('Settings of <name>: its name, the update, the devices, the model', (tester) async {
      final app = _app();
      server.machine = '350003b5f4e6';
      await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
      await _pump(tester, app);
      // The container's id is not a name: «RedGiant».
      expect(find.text('RedGiant'), findsWidgets);
      await tester.tap(find.byKey(const Key('tab-you')));
      await tester.pumpAndSettle();
      expect(find.text('Impostazioni di RedGiant'), findsOneWidget);
      await tester.tap(find.byKey(const Key('open-server-settings')));
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(find.text('È disponibile la versione 3.8.1'), findsOneWidget);
      expect(find.byKey(const Key('update-now')), findsOneWidget);
      Future<void> see(Finder f, [double by = 200]) => tester.scrollUntilVisible(
        f,
        by,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('server-settings')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await see(find.text('Telefono di Mario'));
      expect(find.text('questo dispositivo'), findsOneWidget);
      await see(find.text('Attive, attraverso ntfy.sh'));
      await see(find.byKey(const Key('settings-model')));
      expect(find.text('Claude Sonnet 5 · Chiave API'), findsOneWidget);
      // The model reached both ways shows once, with the way to choose and its line (G40.9b).
      await tester.tap(find.byKey(const Key('settings-model')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('model-anthropic/claude-sonnet-5')), findsOneWidget);
      expect(find.text('Abbonamento o Chiave API'), findsOneWidget);
      expect(find.text('Chiave API'), findsWidgets);
      expect(
        find.text('A consumo con la tua chiave API: conta per il tetto di spesa.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('way-claude-subscription/claude-sonnet-5')));
      await tester.pumpAndSettle();
      expect(find.text('Nei limiti del tuo piano: non paghi a consumo.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('model-anthropic/claude-sonnet-5')));
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(
        (server.setup['config'] as Map<String, dynamic>)['defaultModel'],
        containsPair('provider', 'claude-subscription'),
      );
      expect(find.text('Claude Sonnet 5 · Abbonamento'), findsOneWidget);
      await see(find.byKey(const Key('outside-link')));
      expect(find.text('https://casa.tail1234.ts.net'), findsOneWidget);
      // On a phone, the page's Settings inside the app.
      await see(find.byKey(const Key('settings-all')));
      expect(
        find.text(
          "La pagina Impostazioni completa di RedGiant, dentro l'app, con l'accesso di questo "
          'dispositivo.',
        ),
        findsOneWidget,
      );

      // Signing another device out asks first.
      await see(find.byKey(const Key('revoke-d2')), -200);
      await tester.tap(find.byKey(const Key('revoke-d2')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Telefono di Mario'), findsWidgets);
      await tester.tap(find.byKey(const Key('dialog-yes')));
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(server.devices.map((d) => d['id']), ['d1']);
      expect(find.text('Telefono di Mario'), findsNothing);

      // Renamed: in the app and on the server.
      await tester.drag(find.byKey(const Key('server-settings')), const Offset(0, 3000));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-rename')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('dialog-text')), 'Casa Rossi');
      await tester.tap(find.byKey(const Key('dialog-yes')));
      await tester.pumpAndSettle();
      await _settle(tester);
      expect(server.machine, 'Casa Rossi');
      expect(find.text('Impostazioni di Casa Rossi'), findsOneWidget);
      // The requests' own time limits, still counting in the fake clock.
      await tester.pump(const Duration(seconds: 30));
    });

    testWidgets('no RedGiant yet: the team offers to set one up', (tester) async {
      final app = _app();
      await _pump(tester, app);
      expect(find.byKey(const Key('team-setup-new')), findsOneWidget);
      await tester.tap(find.byKey(const Key('team-setup-new')));
      await tester.pumpAndSettle();
      expect(find.text('Configura un RedGiant nuovo'), findsWidgets);
      expect(find.byKey(const Key('fs-join')), findsOneWidget);
    });

    testWidgets('the first start by hand: the network\'s name and its password on screen', (
      tester,
    ) async {
      final app = _app(platform: DevicePlatform.macos);
      final flow = FirstStartFlow(app, wifi: const ManualWifi());
      await _pump(tester, app);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => FirstStartScreen(flow: flow)));
      await tester.pumpAndSettle();
      // macOS joins by hand only.
      expect(find.byKey(const Key('fs-join')), findsNothing);
      await tester.tap(find.byKey(const Key('fs-by-hand')));
      await tester.pumpAndSettle();
      expect(find.text(kSetupSsidPattern), findsOneWidget);
      expect(find.text(kSetupPassphrase), findsOneWidget);
      expect(find.textContaining('Il menu Wi-Fi in alto a destra'), findsOneWidget);
      expect(find.byKey(const Key('fs-joined')), findsOneWidget);
    });

    testWidgets('the access: two passwords, the page\'s rule, before anything is sent', (
      tester,
    ) async {
      final app = _app();
      final flow = FirstStartFlow(app, wifi: FakeWifi())..step = FsStep.access;
      await _pump(tester, app);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => FirstStartScreen(flow: flow)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('fs-password')), 'corta');
      await tester.enterText(find.byKey(const Key('fs-password-again')), 'corta');
      await tester.tap(find.byKey(const Key('fs-access-go')));
      await tester.pumpAndSettle();
      expect(find.text('Almeno 10 caratteri, non tutti uguali.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('fs-password')), 'una password lunga');
      await tester.enterText(find.byKey(const Key('fs-password-again')), 'un\'altra password');
      await tester.tap(find.byKey(const Key('fs-access-go')));
      await tester.pumpAndSettle();
      expect(find.text('Le due password sono diverse.'), findsOneWidget);
      expect(flow.remembersPassword, isFalse);
    });

    testWidgets('the home network: the networks RedGiant saw, the password only where needed', (
      tester,
    ) async {
      final app = _app();
      final flow = FirstStartFlow(app, wifi: FakeWifi())
        ..step = FsStep.home
        ..network = SetupNetworkStatus.fromJson({
          'active': true,
          'mode': 'setup',
          'ssid': 'RedGiant-Setup-D3M0',
          'networks': [
            {'ssid': 'Ospiti', 'security': 'open', 'signal': -79},
            {'ssid': 'Casa Rossi', 'security': 'psk', 'signal': -48},
            {'ssid': 'Ufficio', 'security': '8021x', 'signal': -60},
          ],
        });
      await _pump(tester, app);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => FirstStartScreen(flow: flow)));
      await tester.pumpAndSettle();
      // The strongest first.
      final ys = [
        for (final n in ['Casa Rossi', 'Ufficio', 'Ospiti'])
          tester.getTopLeft(find.byKey(Key('fs-net-$n'))).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
      await tester.tap(find.byKey(const Key('fs-net-Ospiti')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fs-home-password')), findsNothing);
      await tester.tap(find.byKey(const Key('fs-net-Casa Rossi')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fs-home-password')), findsOneWidget);
      expect(find.text('Usa «Casa Rossi»'), findsOneWidget);
      expect(find.byKey(const Key('fs-cable')), findsOneWidget);
    });
  });
}
