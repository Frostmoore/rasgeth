// 3.10.1: a keychain value behind the device's own lock (fingerprint, face, PIN), with the
// person's yes where the device has none and our window where the lock cannot be asked; and a
// pairing undone by the keystore shows its technical words under a small «Dettagli».
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/servers.dart' show MemoryAppPrefs;
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/l10n/app_localizations.dart';
import 'package:rgcompanion/screens/you_screen.dart';
import 'package:rgcompanion/settings/vault/device_unlock.dart';
import 'package:rgcompanion/settings/vault/keychain_screen.dart';

import 'fake_legacy.dart' show FailingWrites;
import 'fake_server.dart';
import 'fake_vault.dart' show FakeVault;

Future<void> _settle(WidgetTester tester, [int rounds = 14]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 400));
}

/// The device's lock, answering what the test says and noting why it was asked.
class FakeUnlock implements DeviceUnlock {
  FakeUnlock(this.answer);

  DeviceUnlockResult answer;
  final reasons = <String>[];

  @override
  Future<DeviceUnlockResult> unlock(String reason) async {
    reasons.add(reason);
    return answer;
  }
}

void main() {
  test(
    'where local_auth cannot be asked (these tests run on Linux), our window stands in',
    () async {
      expect(Platform.isLinux, isTrue);
      expect(await SystemUnlock().unlock('x'), DeviceUnlockResult.unsupported);
    },
  );

  group('the keychain behind the device lock', () {
    late FakeRedGiant server;
    late FakeVault vault;
    late FakeUnlock lock;
    final copied = <String>[];
    final before = deviceUnlock;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
      vault = FakeVault();
      server.vault = vault;
      lock = FakeUnlock(DeviceUnlockResult.unlocked);
      deviceUnlock = lock;
      copied.clear();
    });
    tearDown(() async {
      deviceUnlock = before;
      await server.close();
    });

    Future<void> open(WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
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
      tester.view.physicalSize = const Size(420, 9000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(RGCompanionApp(controller: app));
      await _settle(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const KeychainScreen(poll: false))).ignore();
      await _settle(tester);
      await tap(tester, 'kc-item-v1');
    }

    Future<void> done(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(minutes: 3));
    }

    testWidgets('unlocked: shown and copied without our window', (tester) async {
      await open(tester);
      await tap(tester, 'kc-show');
      expect(find.byKey(const Key('kc-confirm')), findsNothing);
      expect(lock.reasons, ['Sblocca per vedere il segreto']);
      expect(vault.reveals, 1);
      expect(find.text('rv-secret-v1'), findsOneWidget);
      // On the screen already: copying asks nothing more.
      await tap(tester, 'kc-copy');
      expect(lock.reasons, hasLength(1));
      expect(copied, ['rv-secret-v1']);
      await tap(tester, 'kc-hide');
      await tap(tester, 'kc-copy');
      expect(lock.reasons.last, 'Sblocca per copiare il segreto');
      expect(copied.last, 'rv-secret-v1');
      await done(tester);
    });

    testWidgets('refused: nothing comes, and it says so', (tester) async {
      lock.answer = DeviceUnlockResult.refused;
      await open(tester);
      await tap(tester, 'kc-show');
      await tap(tester, 'kc-copy');
      expect(vault.reveals, 0);
      expect(copied, isEmpty);
      expect(find.text('rv-secret-v1'), findsNothing);
      expect(find.text('Non sbloccato: il segreto resta nascosto.'), findsOneWidget);
      await done(tester);
    });

    testWidgets('a device without a lock says so and asks, for showing and for copying', (
      tester,
    ) async {
      lock.answer = DeviceUnlockResult.noLock;
      await open(tester);
      await tap(tester, 'kc-show');
      expect(find.text('Questo dispositivo non ha un blocco'), findsOneWidget);
      await tap(tester, 'kc-confirm-no');
      expect(vault.reveals, 0);
      await tap(tester, 'kc-copy');
      expect(find.text('Questo dispositivo non ha un blocco'), findsOneWidget);
      await tap(tester, 'kc-confirm-yes');
      expect(copied, ['rv-secret-v1']);
      await tap(tester, 'kc-show');
      await tap(tester, 'kc-confirm-yes');
      expect(find.text('rv-secret-v1'), findsOneWidget);
      await done(tester);
    });

    testWidgets('no lock to ask: our window for showing, copying as before', (tester) async {
      lock.answer = DeviceUnlockResult.unsupported;
      await open(tester);
      await tap(tester, 'kc-show');
      expect(find.text('Mostrare il segreto?'), findsOneWidget);
      await tap(tester, 'kc-confirm-no');
      expect(vault.reveals, 0);
      await tap(tester, 'kc-copy');
      expect(find.byKey(const Key('kc-confirm')), findsNothing);
      expect(copied, ['rv-secret-v1']);
      await done(tester);
    });
  });

  group('a pairing the keystore undid', () {
    late FakeRedGiant server;
    setUp(() async {
      HttpOverrides.global = null;
      server = await FakeRedGiant.start();
    });
    tearDown(() => server.close());

    for (final lang in ['it', 'en']) {
      testWidgets('the advice and the technical words under «Dettagli» ($lang)', (tester) async {
        final app = AppController(
          tokens: FailingWrites('throw'),
          prefs: MemoryAppPrefs(),
          platform: DevicePlatform.windows,
          liveEnabled: false,
        )..keystoreTimeout = const Duration(milliseconds: 200);
        final ok = await tester.runAsync(() => app.connect(server.base.toString(), 'secret'));
        expect(ok, isFalse);
        expect(app.error, ConnectError.keystore);
        await tester.pumpWidget(
          AppScope(
            controller: app,
            child: MaterialApp(
              locale: Locale(lang),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: SingleChildScrollView(child: AddServer())),
            ),
          ),
        );
        await _settle(tester);
        final words = tester.widget<Text>(find.byKey(const Key('server-error'))).data!;
        expect(
          words,
          contains(
            lang == 'it'
                ? 'riavvia il computer e accedi con la password, non con il PIN'
                : 'restart the computer and sign in with your password, not the PIN',
          ),
        );
        expect(find.byKey(const Key('server-error-detail')), findsNothing);
        expect(find.text(lang == 'it' ? 'Dettagli' : 'Details'), findsOneWidget);
        await tester.tap(find.byKey(const Key('server-error-details')));
        await tester.pump();
        final detail = tester.widget<SelectableText>(find.byKey(const Key('server-error-detail')));
        expect(detail.data, contains('Access denied'));
        expect(detail.data, app.errorMessage);
        await tester.tap(find.byKey(const Key('server-error-details')));
        await tester.pump();
        expect(find.byKey(const Key('server-error-detail')), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('no details for the other errors', (tester) async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.windows,
        liveEnabled: false,
      );
      await tester.runAsync(() => app.connect(server.base.toString(), 'wrong'));
      expect(app.error, isNot(ConnectError.keystore));
      await tester.pumpWidget(
        AppScope(
          controller: app,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: AddServer())),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const Key('server-error')), findsOneWidget);
      expect(find.byKey(const Key('server-error-details')), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

Future<void> tap(WidgetTester tester, String key) async {
  final f = find.byKey(Key(key));
  await tester.ensureVisible(f.first);
  await tester.pump();
  await tester.tap(f.first);
  await _settle(tester);
}
