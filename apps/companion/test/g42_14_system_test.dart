// G42.14: the system's settings, native, against the fake server's system (test/fake_system.dart,
// never a real machine): access from outside home (the password with the others signed out on a
// yes, the authenticator's code with its QR, a wrong code refused, Tailscale's job, «Switch off»,
// one's own infrastructure with the blocks filled in and «Try a name», «reachable already»,
// Pi-hole), Settings › System (the machine, the role asked first, a disk for backups, when they
// run, a backup now, a backup restored after a yes, SSH needing a key, Wi-Fi, HTTPS trusted, the
// restart asked), the SSH machines (added, the first key trusted, a changed key replaced only after
// a yes), the nodes (a code, a pair confirmed with its digits, renamed, unpaired, placements), the
// backup file (made, saved, sent, its names chosen, imported), the breaking update's gate (the
// backup made by itself, where it is, the steps), and the rows in Settings.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rgcompanion/api/conversation.dart' show Project;
import 'package:rgcompanion/api/servers.dart';
import 'package:rgcompanion/api/settings_types.dart';
import 'package:rgcompanion/api/token_store.dart';
import 'package:rgcompanion/api/types.dart' show DevicePlatform;
import 'package:rgcompanion/app.dart';
import 'package:rgcompanion/app_state.dart';
import 'package:rgcompanion/screens/server_settings_screen.dart';
import 'package:rgcompanion/settings/system/backup_screen.dart';
import 'package:rgcompanion/settings/system/emulators_screen.dart';
import 'package:rgcompanion/settings/system/machines_screen.dart';
import 'package:rgcompanion/settings/system/nodes_screen.dart';
import 'package:rgcompanion/settings/system/os_panels.dart' show httpsTrustedHere;
import 'package:rgcompanion/settings/system/remote_screen.dart';
import 'package:rgcompanion/settings/system/system_screen.dart';
import 'package:rgcompanion/settings/system/update_gate.dart';

import 'fake_server.dart';
import 'fake_system.dart';

Future<void> _settle(WidgetTester tester, [int rounds = 12]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }
}

void main() {
  late FakeRedGiant server;
  late FakeSystem sys;
  setUp(() async {
    HttpOverrides.global = null;
    server = await FakeRedGiant.start();
    sys = FakeSystem();
    server.system = sys;
    nodesEvery = const Duration(hours: 1);
  });
  tearDown(() => server.close());

  Future<AppController> start(WidgetTester tester, {Size size = const Size(420, 7000)}) async {
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

  /// Frames until the layout stops moving (a route that slides in, a window that opens).
  Future<void> calm(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 3),
      );
    } on FlutterError {
      // Something keeps moving (a spinner): enough frames anyway.
    }
  }

  Future<void> push(WidgetTester tester, Widget screen) async {
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute<void>(builder: (_) => screen)).ignore();
    await _settle(tester);
    await calm(tester);
  }

  Future<void> tap(WidgetTester tester, String key, [int rounds = 8]) async {
    final f = find.byKey(Key(key));
    await calm(tester);
    await tester.ensureVisible(f.first);
    await calm(tester);
    await tester.tap(f.first);
    await _settle(tester, rounds);
    await calm(tester);
  }

  Future<void> type(WidgetTester tester, String key, String text) async {
    await calm(tester);
    await tester.ensureVisible(find.byKey(Key(key)));
    await calm(tester);
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  /// A job's second read: the fake's jobs end at once, read again after a second.
  Future<void> jobs(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 1));
      await _settle(tester, 4);
    }
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 3));
  }

  testWidgets('access: the password, the code with its QR, the sessions', (tester) async {
    await start(tester);
    await push(tester, const RemoteSettingsScreen());
    expect(find.text('Accesso da fuori casa'), findsWidgets);
    // The password is set: change it, the others signed out after a yes.
    await tap(tester, 'sy-password-change');
    await type(tester, 'sy-password-new', 'una-password-lunga');
    await type(tester, 'sy-password-again', 'una-password-diversa');
    expect(find.text('Le due password sono diverse.'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('sy-password-save'))).onPressed,
      isNull,
    );
    await type(tester, 'sy-password-again', 'una-password-lunga');
    await tap(tester, 'sy-password-save');
    await tap(tester, 'dialog-yes');
    expect(sys.bodies['PUT /api/auth/password'], {
      'password': 'una-password-lunga',
      'signOutOthers': true,
    });
    // The authenticator: its secret and QR, a wrong code refused, the right one.
    await tap(tester, 'sy-code-start');
    expect(find.byKey(const Key('sy-qr')), findsOneWidget);
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    await type(tester, 'sy-code-digits', '654321');
    await tap(tester, 'sy-code-confirm');
    expect(sys.code, isFalse);
    await type(tester, 'sy-code-digits', '123456');
    await tap(tester, 'sy-code-confirm');
    expect(sys.code, isTrue);
    expect(find.byKey(const Key('sy-code-off')), findsOneWidget);
    // Sign out everywhere, from its fold.
    await tap(tester, 'sy-sessions');
    await tap(tester, 'sy-sign-out-all');
    expect(sys.calls, contains('POST /api/auth/sessions/revoke'));
    await done(tester);
  });

  testWidgets('access: Tailscale, off, own infrastructure, a name, Pi-hole', (tester) async {
    final opened = <Uri>[];
    remoteOpenLink = (u) async {
      opened.add(u);
      return true;
    };
    await start(tester);
    await push(tester, const RemoteSettingsScreen());
    await tap(tester, 'sy-remote-connect');
    expect(sys.bodies['POST /api/setup/remote'], {'way': 'tailscale'});
    await jobs(tester);
    expect(find.byKey(const Key('sy-remote-url')), findsOneWidget);
    expect(find.text('https://rasgeth.tail1234.ts.net'), findsOneWidget);
    await tap(tester, 'sy-remote-url');
    expect(opened.last.host, 'rasgeth.tail1234.ts.net');
    await tap(tester, 'sy-remote-off');
    expect(sys.remote, isNull);
    // Own infrastructure: the blocks filled with what the server saw.
    await tap(tester, 'sy-oi-fold');
    expect(find.textContaining('rasgeth.local {'), findsWidgets);
    expect(find.textContaining('reverse_proxy 192.168.1.50:7600'), findsWidgets);
    await tap(tester, 'sy-oi-part-vpn');
    expect(find.text('tailscale up --advertise-routes=192.168.1.0/24'), findsOneWidget);
    await tap(tester, 'sy-oi-part-home');
    await type(tester, 'sy-oi-service', 'git.home.example.com');
    await tap(tester, 'sy-oi-probe');
    expect(find.byKey(const Key('sy-oi-verdict')), findsOneWidget);
    expect(sys.bodies['POST /api/setup/net/probe'], {'name': 'git.home.example.com'});
    await tap(tester, 'sy-oi-skip');
    expect(sys.bodies['PUT /api/setup/reachable'], {'on': true, 'url': 'https://rasgeth.local'});
    // Pi-hole: a wrong address keeps it from starting.
    await type(tester, 'sy-pihole-ip', '192.168.1.300');
    expect(tester.widget<FilledButton>(find.byKey(const Key('sy-pihole-start'))).onPressed, isNull);
    await type(tester, 'sy-pihole-ip', '192.168.1.50');
    await tap(tester, 'sy-pihole-start');
    expect(sys.bodies['POST /api/setup/pihole'], {'lanIp': '192.168.1.50'});
    await jobs(tester);
    await tap(tester, 'sy-pihole-password');
    expect(find.text('pi-hole-word'), findsOneWidget);
    await tap(tester, 'sy-pihole-stop');
    expect(sys.pihole, isNull);
    await done(tester);
  });

  testWidgets('system: the machine, the role asked, a disk, when, now, a restore', (tester) async {
    await start(tester);
    await push(tester, const SystemSettingsScreen());
    expect(find.textContaining('AMD Ryzen 7 5800X'), findsOneWidget);
    expect(find.textContaining('NVIDIA GeForce RTX 3070 (8 GB)'), findsOneWidget);
    // The role changes only after a yes.
    await tap(tester, 'sy-role-node');
    await tap(tester, 'dialog-no');
    expect(sys.calls, isNot(contains('PUT /api/setup/role')));
    // A disk for backups, then when they run.
    await tap(tester, 'sy-disk-5E3A-91F0');
    expect(sys.bodies['POST /api/setup/backups/disk'], {'uuid': '5E3A-91F0'});
    expect(find.byKey(const Key('sy-dest')), findsOneWidget);
    await tap(tester, 'sy-every-weekly');
    expect(sys.schedule['every'], 'weekly');
    await tap(tester, 'sy-hour-plus');
    expect(sys.schedule['hour'], 4);
    await tap(tester, 'sy-backup-now');
    expect(sys.calls, contains('POST /api/setup/backups/run'));
    // The backups there: one restored after a yes.
    await tap(tester, 'sy-list-show');
    await tap(tester, 'sy-restore-rasgeth-2026-11-20/backup.rgbackup');
    await tap(tester, 'dialog-yes');
    await jobs(tester);
    expect(find.textContaining('14'), findsWidgets);
    expect(sys.bodies['POST /api/setup/backups/restore'], {
      'id': 'rasgeth-2026-11-20/backup.rgbackup',
    });
    await done(tester);
  });

  testWidgets('system: SSH needs a key, Wi-Fi, HTTPS trusted, the restart asked', (tester) async {
    httpsTrustedHere = (_) async => true;
    await start(tester);
    await push(tester, const SystemSettingsScreen());
    // SSH: on without a key says so, with one it switches on.
    await tap(tester, 'sy-ssh-on');
    expect(sys.calls, isNot(contains('PUT /api/setup/ssh')));
    await type(tester, 'sy-ssh-key', 'ssh-ed25519 AAAAC3Nza mario@pc');
    await tap(tester, 'sy-ssh-on');
    expect(sys.bodies['PUT /api/setup/ssh'], {'on': true, 'key': 'ssh-ed25519 AAAAC3Nza mario@pc'});
    // Wi-Fi: a wrong password refused in words, the open network joined.
    await tap(tester, 'sy-wifi-Ufficio');
    await type(tester, 'sy-wifi-password', 'sbagliata');
    await tap(tester, 'sy-wifi-join');
    expect(find.byKey(const Key('sy-wifi-join')), findsOneWidget);
    await tap(tester, 'sy-wifi-Ospiti');
    await tap(tester, 'sy-wifi-join');
    expect(sys.bodies['POST /api/setup/wifi/connect'], {'ssid': 'Ospiti', 'password': ''});
    // HTTPS: the certificate's QR, then «this device trusts it».
    expect(find.byKey(const Key('sy-https-qr')), findsOneWidget);
    await tap(tester, 'sy-https-check');
    expect(sys.https['redirect'], isTrue);
    expect(find.byKey(const Key('sy-https-redirect')), findsOneWidget);
    // The restart is asked first.
    await tap(tester, 'sy-os-reboot');
    await tap(tester, 'dialog-yes');
    expect(sys.calls, contains('POST /api/setup/os/reboot'));
    await done(tester);
  });

  testWidgets('machines: added, the first key trusted, a changed key replaced on a yes', (
    tester,
  ) async {
    await start(tester);
    await push(tester, const MachinesScreen());
    await tap(tester, 'sy-mc-new');
    await type(tester, 'sy-mc-name', 'nas');
    await type(tester, 'sy-mc-host', '192.168.1.30');
    await type(tester, 'sy-mc-user', 'mario');
    await tap(tester, 'sy-mc-save');
    expect(sys.machines.single['name'], 'nas');
    expect(find.byKey(const Key('sy-mc-m1')), findsOneWidget);
    expect(find.textContaining('ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDemoKey'), findsOneWidget);
    // The first test shows the machine's key; trusted, the test passes.
    await tap(tester, 'sy-mc-test-m1');
    expect(find.byKey(const Key('sy-mc-tofu')), findsOneWidget);
    await tap(tester, 'sy-mc-trust');
    expect(sys.machines.single['hostKey'], isNotNull);
    expect(find.byKey(const Key('sy-mc-result')), findsOneWidget);
    // A different key afterwards: red, replaced only after a yes.
    sys.testCode['m1'] = 'host-key-changed';
    await tap(tester, 'sy-mc-test-m1');
    expect(find.byKey(const Key('sy-mc-changed')), findsOneWidget);
    expect(find.text('SHA256:oldKeyOldKeyOldKey'), findsOneWidget);
    await tap(tester, 'sy-mc-replace');
    await tap(tester, 'dialog-no');
    expect(sys.calls.where((c) => c.endsWith('/trust')), hasLength(1));
    await done(tester);
  });

  testWidgets('emulators: the report, a folder refused then used, how many at once, the nodes', (
    tester,
  ) async {
    await start(tester);
    await push(tester, const EmulatorsScreen());
    expect(find.textContaining('Pronta: qui possono girare gli emulatori (1'), findsOneWidget);
    expect(
      find.textContaining(r'D:\Android\Sdk · dalle impostazioni di Android Studio'),
      findsOneWidget,
    );
    expect(find.text('Emulatore · Medium_Phone_API_35'), findsOneWidget);
    expect(find.text('Telefono via Wi-Fi · aspetta il tuo sì sul telefono'), findsOneWidget);
    expect(find.textContaining("L'emulatore è vecchio"), findsOneWidget);
    // 3.11 phase 2: the devices one can open, between this machine and the SDK folder.
    expect(find.byKey(const Key('sy-em-dev-emulator-5554')), findsOneWidget);
    expect(find.byKey(const Key('sy-em-open-avd:Tablet')), findsOneWidget);
    expect(find.byKey(const Key('sy-em-stop-avd:Tablet')), findsNothing);
    // The nodes: a Mac with Xcode and no SDK, and one older than 3.11.
    expect(find.text('Mac mini'), findsOneWidget);
    expect(find.text('iPhone 18 (iOS 27.2)'), findsOneWidget);
    expect(find.textContaining('Il ponte per immagine e tocchi'), findsOneWidget);
    expect(find.text('Non installato'), findsOneWidget);
    expect(find.textContaining('più vecchio della 3.11'), findsOneWidget);
    // A folder without an SDK is refused in the server's words; then one is used and forgotten.
    await type(tester, 'sy-em-path', r'E:\vuota');
    await tap(tester, 'sy-em-path-save');
    expect(find.textContaining('No Android SDK in that folder'), findsOneWidget);
    await type(tester, 'sy-em-path', r'E:\android-sdk');
    await tap(tester, 'sy-em-path-save');
    expect(sys.bodies['PUT /api/emulators/settings'], {'sdkPath': r'E:\android-sdk'});
    expect(find.textContaining('la cartella che hai scelto'), findsOneWidget);
    await tap(tester, 'sy-em-path-forget');
    expect(sys.bodies['PUT /api/emulators/settings'], {'sdkPath': null});
    await tap(tester, 'sy-em-max-3');
    expect(sys.bodies['PUT /api/emulators/settings'], {'maxRunning': 3});
    final before = sys.calls.where((c) => c == 'GET /api/emulators').length;
    await calm(tester);
    await tester.ensureVisible(find.byKey(const Key('sy-em-again')));
    await calm(tester);
    expect(
      tester.widget<ButtonStyleButton>(find.byKey(const Key('sy-em-again'))).onPressed,
      isNotNull,
    );
    await tap(tester, 'sy-em-again', 16);
    expect(sys.calls.where((c) => c == 'GET /api/emulators').length, before + 1);
    expect(find.byType(Checkbox), findsNothing);
    await done(tester);
  });

  testWidgets('emulators: the guided install, only with the licences accepted (3.11 phase 5)', (
    tester,
  ) async {
    sys.emulatorReport = {
      ...sys.emulatorReport,
      'android': {
        'looked': [
          {'path': r'C:\Users\Ada\AppData\Local\Android\Sdk', 'source': 'standard'},
        ],
        'avds': <Object>[],
        'attached': <Object>[],
        'accel': {'ok': false, 'reason': 'unknown'},
      },
      'missing': ['sdk'],
      'ready': false,
    };
    await start(tester);
    await push(tester, const EmulatorsScreen());
    expect(find.byKey(const Key('ei-update')), findsNothing);
    await tap(tester, 'ei-install', 16);
    expect(sys.bodies['POST /api/emulators/install/plan'], <String, dynamic>{});
    expect(find.textContaining(r'C:\Users\Ada\AppData\Local\Android\Sdk'), findsOneWidget);
    expect(find.text('il posto standard di questo sistema'), findsOneWidget);
    expect(find.textContaining('Gli strumenti a riga di comando di Android 22.0'), findsOneWidget);
    expect(find.textContaining('Il telefono virtuale Rasgeth_Phone_API_35'), findsOneWidget);
    expect(find.textContaining('Da scaricare: '), findsOneWidget);
    expect(find.textContaining('Android SDK License Agreement'), findsOneWidget);
    // Install waits for the licences accepted (our switch, never a checkbox).
    await calm(tester);
    await tester.ensureVisible(find.byKey(const Key('ei-start')));
    expect(tester.widget<ButtonStyleButton>(find.byKey(const Key('ei-start'))).onPressed, isNull);
    expect(find.byType(Checkbox), findsNothing);
    await tap(tester, 'ei-accept');
    expect(
      tester.widget<ButtonStyleButton>(find.byKey(const Key('ei-start'))).onPressed,
      isNotNull,
    );
    await tap(tester, 'ei-start', 16);
    expect(sys.bodies['POST /api/emulators/install/start'], {
      'planId': 'P1',
      'licenceAccepted': true,
    });
    // The job's bar: bytes, speed and time left.
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.textContaining('/s'), findsWidgets);
    expect(find.byKey(const Key('ei-stop')), findsOneWidget);
    final before = sys.calls.where((c) => c == 'GET /api/emulators').length;
    await jobs(tester);
    await calm(tester);
    expect(find.textContaining('Fatto. Il resoconto'), findsOneWidget);
    // The report is read again at the end.
    expect(sys.calls.where((c) => c == 'GET /api/emulators').length, greaterThan(before));
    await done(tester);
  });

  testWidgets('emulators: the iOS bridge install on a Mac, only with the yes (3.12.2)', (
    tester,
  ) async {
    sys.emulatorReport = {
      ...sys.emulatorReport,
      'os': 'macos',
      'arch': 'arm64',
      'ios': {
        'xcode': '27.2',
        'simulators': [
          {'name': 'iPhone 18', 'udid': 'U1', 'runtime': 'iOS 27.2', 'state': 'shutdown'},
        ],
        'ready': false,
      },
      'missing': ['ios-bridge'],
      'ready': false,
    };
    await start(tester);
    await push(tester, const EmulatorsScreen());
    await tap(tester, 'ib-install', 16);
    expect(sys.bodies['POST /api/emulators/ios-bridge/plan'], <String, dynamic>{});
    expect(find.textContaining('serve-sim 0.1.49'), findsOneWidget);
    expect(find.text('Apache-2.0'), findsOneWidget);
    expect(find.textContaining('Togliendo quella cartella lo togli'), findsOneWidget);
    expect(sys.bodies.containsKey('POST /api/emulators/ios-bridge/start'), isFalse);
    await tap(tester, 'ib-start', 16);
    expect(sys.bodies['POST /api/emulators/ios-bridge/start'], {'planId': 'IB1'});
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await jobs(tester);
    await calm(tester);
    expect(find.textContaining('Il ponte iOS è installato'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
    await done(tester);
  });

  testWidgets('emulators: the iOS bridge says why it cannot be installed', (tester) async {
    sys.emulatorReport = {
      ...sys.emulatorReport,
      'os': 'macos',
      'arch': 'x64',
      'ios': {'xcode': '27.2', 'simulators': <Object>[], 'ready': false},
      'missing': ['ios-bridge'],
      'ready': false,
    };
    sys.iosBridgePlan = {...sys.iosBridgePlan, 'blocked': 'intel'}..remove('planId');
    await start(tester);
    await push(tester, const EmulatorsScreen());
    await tap(tester, 'ib-install', 16);
    expect(find.byKey(const Key('ib-blocked')), findsOneWidget);
    expect(find.textContaining('Mac Intel'), findsOneWidget);
    expect(find.byKey(const Key('ib-start')), findsNothing);
    await done(tester);
  });

  testWidgets('emulators: the update of an old emulator asks for its own plan', (tester) async {
    await start(tester);
    await push(tester, const EmulatorsScreen());
    await tap(tester, 'ei-update', 16);
    expect(sys.bodies['POST /api/emulators/install/plan'], {'only': 'emulator-update'});
    expect(find.textContaining("L'emulatore, all'ultima versione 37.3.10"), findsOneWidget);
    expect(find.byKey(const Key('ei-folder')), findsNothing);
    await done(tester);
  });

  testWidgets('nodes: a code, a pair confirmed with its digits, renamed, unpaired', (tester) async {
    final app = await start(tester);
    app.projects = [
      Project.fromJson({'id': 'p1', 'name': 'Sito'}),
    ];
    await push(tester, const NodesScreen());
    expect(find.text('Severino'), findsWidgets);
    await tap(tester, 'sy-nd-add-go');
    expect(find.byKey(const Key('sy-nd-code')), findsOneWidget);
    expect(find.text('K7QM-4XRP'), findsOneWidget);
    // A node asks: its six digits and both fingerprints, then the yes.
    sys.pending.add({
      'fingerprint': 'SHA256:rigRigRigRig5678',
      'name': 'Rig',
      'sas': '482 913',
      'side': 'principal',
      'at': '2026-11-21T10:00:00.000Z',
    });
    await tap(tester, 'sy-nd-code-stop');
    expect(find.text('482 913'), findsOneWidget);
    expect(find.text('SHA256:rigRigRigRig5678'), findsWidgets);
    await tap(tester, 'sy-nd-confirm');
    expect(sys.bodies['POST /api/nodes/confirm'], {'fingerprint': 'SHA256:rigRigRigRig5678'});
    expect(find.byKey(const Key('sy-nd-SHA256:rigRigRigRig5678')), findsOneWidget);
    // Where the project's commands go.
    expect(find.byKey(const Key('sy-nd-place-p1')), findsOneWidget);
    await tap(tester, 'sy-nd-cmd-p1-SHA256:rigRigRigRig5678');
    expect(sys.bodies['PUT /api/nodes/placements'], {
      'scope': 'project:p1',
      'commands': 'SHA256:rigRigRigRig5678',
    });
    await tap(tester, 'sy-nd-rename-SHA256:rigRigRigRig5678');
    await calm(tester);
    await tester.enterText(find.byKey(const Key('sy-nd-rename-field')), 'Rig di casa');
    await tap(tester, 'dialog-yes');
    expect(sys.children.single['name'], 'Rig di casa');
    await tap(tester, 'sy-nd-unpair-SHA256:rigRigRigRig5678');
    await tap(tester, 'dialog-yes');
    expect(sys.children, isEmpty);
    await done(tester);
  });

  testWidgets('backup: made and saved, a file sent, names chosen, imported', (tester) async {
    final saved = <String, int>{};
    backupSave = (name, bytes) async {
      saved[name] = bytes.length;
      return true;
    };
    backupPick = () async => ('vecchio.rgbackup', Uint8List(2048));
    await start(tester);
    await push(tester, const BackupScreen());
    await tap(tester, 'sy-export-make');
    await jobs(tester);
    await tap(tester, 'sy-export-download', 16);
    expect(saved, {'rasgeth-2026-11-21.rgbackup': 4096});
    await tap(tester, 'sy-import-choose', 16);
    expect(sys.bodies['POST /api/backup/upload'], 2048);
    expect(find.text('Sito'), findsOneWidget);
    await tap(tester, 'sy-import-name-god-Zeus');
    await tap(tester, 'sy-import-go');
    expect(sys.bodies['POST /api/backup/import'], {'id': 'up1', 'godName': 'Zeus'});
    await jobs(tester);
    expect(find.byKey(const Key('sy-import-done')), findsOneWidget);
    await done(tester);
  });

  testWidgets('a breaking update: the backup by itself, where it is, the steps', (tester) async {
    await start(tester);
    final s = UpdateStatus.fromJson({
      'install': 'docker',
      'installed': '3.10.0',
      'latest': '4.0.0',
      'state': 'available',
      'gate': 'breaking',
      'canUpdateHere': false,
      'command': 'docker compose pull && docker compose up -d',
    });
    await push(tester, UpdateGateScreen(s: s));
    expect(sys.calls, contains('POST /api/update/safety-backup'));
    await jobs(tester);
    expect(find.byKey(const Key('sy-gate-where')), findsOneWidget);
    expect(find.text('/home/mario/Documents/Rasgeth backup'), findsOneWidget);
    // The keychain sealed in, on request.
    await tap(tester, 'sy-gate-keys-add');
    await type(tester, 'sy-gate-pass', 'una-frase-segreta');
    await tap(tester, 'sy-gate-keys-again');
    expect(sys.bodies['POST /api/update/safety-backup'], {
      'keychainPassphrase': 'una-frase-segreta',
    });
    await jobs(tester);
    await tap(tester, 'sy-gate-next');
    expect(find.byKey(const Key('sy-gate-guide')), findsOneWidget);
    expect(find.text('docker compose down -v'), findsOneWidget);
    await done(tester);
  });

  testWidgets('the rows in Settings open the native screens', (tester) async {
    await start(tester);
    await push(tester, const ServerSettingsScreen());
    for (final (row, back) in [
      ('settings-remote', 'sy-remote-back'),
      ('settings-system', 'sy-system-back'),
      ('settings-machines', 'sy-machines-back'),
      ('settings-nodes', 'sy-nodes-back'),
      ('settings-backup', 'sy-backup-back'),
    ]) {
      await tap(tester, row);
      expect(find.byKey(Key(back)), findsOneWidget, reason: row);
      await tap(tester, back);
    }
    await done(tester);
  });
}
