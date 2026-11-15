// The first start from the app (G40.8) against a real RedGiant that has never been set up, with
// RedGiant OS's temporary network acted out by the demo server (FakeProvider, no real model):
//   DEMO_FRESH=1 DEMO_SETUP_AP=1 DEMO_HOST=127.0.0.1 node packages/web/scripts/demo-server.mjs 7652
//   RG_SETUP_URL=http://127.0.0.1:7652 flutter test test/first_start_live_test.dart
// Every address of this machine counts as the temporary network there; the Wi-Fi joining is the
// fake one (no real network is touched). Each run needs a fresh demo (the access is created once).
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/transport.dart';
import 'package:rgcompanion/api/types.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/setup/first_start.dart';

import 'fake_wifi.dart';

final _url = Platform.environment['RG_SETUP_URL'];

Future<void> until(bool Function() ok, {Duration within = const Duration(seconds: 40)}) async {
  final end = DateTime.now().add(within);
  while (!ok()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  final skip = _url == null ? 'RG_SETUP_URL not set' : null;
  final base = Uri.parse(_url ?? 'http://127.0.0.1:1');

  test(
    'a new RedGiant set up from the app: access, home network, names, completed',
    () async {
      final app = AppController(
        tokens: MemoryTokenStore(),
        prefs: MemoryAppPrefs(),
        platform: DevicePlatform.android,
      );
      final wifi = FakeWifi();
      // At home: the demo's own address (mDNS is the system's, not in a test); [home] false
      // acts out a phone that does not find it there.
      var home = true;
      late final FirstStartFlow flow;
      flow = FirstStartFlow(
        app,
        wifi: wifi,
        setupBases: [base],
        poll: const Duration(milliseconds: 300),
        homeTimeout: const Duration(seconds: 8),
        findHome: (s, address) async => home ? flow.probeHome(s, address ?? base.authority) : null,
      );
      await flow.joinAutomatically();
      expect(wifi.joins, 1);
      expect(flow.step, FsStep.access, reason: '${flow.error} ${flow.detail}');
      expect(flow.fingerprint, startsWith('SHA256:'));
      expect(flow.network?.networks.map((n) => n.ssid), contains('Casa Rossi'));

      await flow.createAccess('companion-first-1');
      expect(flow.step, FsStep.home, reason: '${flow.error} ${flow.detail}');
      expect(flow.saved?.fingerprint, flow.fingerprint);
      expect(app.servers, hasLength(1));

      // A Wi-Fi network whose password does not work: RedGiant comes back and says so.
      await flow.chooseWifi('Casa Rossi', 'sbagliata');
      await until(() => flow.step == FsStep.home && flow.error != null);
      expect(flow.error, FsError.homeFailed);
      expect(flow.code, 'connect_failed');
      expect(wifi.leaves, greaterThan(0));
      expect(app.client!.transport.kind, TransportKind.loopback);

      // Not found at home this time: back on the temporary network (joined again, the channel
      // with the same key, signed in again with the password kept meanwhile), with the reason.
      home = false;
      final joins = wifi.joins;
      await flow.chooseWifi('Vodafone-A1B2C3', 'sbagliata');
      await until(
        () => flow.step == FsStep.home && flow.error != null,
        within: const Duration(seconds: 60),
      );
      expect(flow.error, FsError.homeFailed);
      expect(flow.code, 'connect_failed');
      expect(wifi.joins, joins + 1);
      expect(flow.client!.transport.kind, TransportKind.channel);
      home = true;
      // Then the cable.
      await flow.chooseCable();
      await until(() => flow.step == FsStep.language, within: const Duration(seconds: 60));
      expect(flow.error, isNull, reason: flow.detail);
      expect(app.connected, isTrue);
      expect(app.client!.transport.kind, TransportKind.loopback);
      expect(app.hello?.nodeFingerprint, flow.fingerprint);

      await flow.saveLanguages('it', 'it');
      expect(flow.step, FsStep.brain, reason: '${flow.error} ${flow.detail}');
      flow.brainNext();
      await flow.saveNames('Zeus', 'Hermes', language: 'it');
      expect(flow.step, FsStep.done, reason: '${flow.error} ${flow.detail}');
      final s = await app.client!.setupSummary();
      expect(s.completed, isTrue);
      expect(s.godName, 'Zeus');
      expect(s.language, 'it');
      expect((await app.client!.hello()).firstStartCompleted, isTrue);
      expect(flow.remembersPassword, isFalse);
      flow.dispose();
      await app.disconnect();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
