// RGCompanion (G40, 3.8): the RedGiant app for Android, iOS, Windows, macOS and Linux. One
// Flutter project; on computers the launchers stay the local server's keeper.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'api/discovery.dart';
import 'api/keystore_guard.dart';
import 'api/legacy_data.dart';
import 'api/servers.dart';
import 'api/token_store.dart';
import 'app.dart';
import 'app_state.dart';
import 'app_update/start.dart';
import 'app_update/swap.dart' show UpdateStart;
import 'desktop/handoff.dart';
import 'desktop/single_instance.dart';
import 'desktop/tray.dart';
import 'push/background.dart';
import 'push/distributors.dart';
import 'push/system_notifier.dart';
import 'share/share_intake.dart';

Future<void> main(List<String> args) async {
  // Android starts the app's code without its window for a UnifiedPush message (G40.10).
  if (args.contains('--unifiedpush-bg')) return runPushInBackground();
  WidgetsFlutterBinding.ensureInitialized();
  final computer = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  // One copy per person (3.10.2): another one running comes to the front, and this one ends
  // before it touches the keystore (its launcher's handoff file is still taken and deleted).
  SingleInstance? instance;
  if (computer) {
    try {
      instance = SingleInstance(Directory((await getApplicationSupportDirectory()).path));
      if (!await instance.claim()) {
        await takeLaunchHandoff().catchError((_) => null);
        exit(0);
      }
    } on Object {
      // Without the app's folder there is nothing to coordinate with.
    }
  }
  // Windows (3.9.8): the keystore's file kept aside, and not touched where DPAPI cannot open it.
  TokenStore? tokens;
  if (Platform.isWindows) {
    try {
      final g = await guardKeystore((await getApplicationSupportDirectory()).path);
      if (g == KeystoreGuardResult.noDpapi) tokens = UnavailableTokenStore();
    } on Object {
      // The keystore as it is.
    }
  }
  final controller = AppController(
    tokens: tokens,
    prefs: SharedAppPrefs(),
    discovery: BonsoirRedGiantDiscovery(),
    notifier: LocalSystemNotifier(background: notificationAnswerInBackground),
    distributors: UnifiedPushDistributors.start,
    share: SystemShareIntake.supported ? SystemShareIntake() : null,
    // Windows moved the app's folder with the name (3.9.0): the old one's data, carried once.
    legacy: Platform.isWindows ? WindowsLegacySource() : null,
  );
  // The computers notify only while the window is behind others.
  AppLifecycleListener(
    onStateChange: (s) => controller.setForeground(s == AppLifecycleState.resumed),
  );
  // Opened by RedGiant.exe or RedGiant.app (G40.12): the local server and a token for it, read
  // (and its file deleted) before anything else.
  final handoff = await takeLaunchHandoff();
  // The app on its own updates itself (G41.8b): where the person was before an update first.
  final updates = await prepareAppUpdater(controller, args);
  // The computers (G42.17): the window may close into the system tray, notifications still come.
  if (computer) await SystemDesktopWindow.prepare().catchError((_) {});
  runApp(RGCompanionApp(controller: controller));
  if (computer) {
    final tray = TrayKeeper(controller, SystemDesktopWindow());
    unawaited(tray.start());
    // Another copy started (show), or an installer replacing the files (quit: for real).
    instance?.onCommand = (c) => unawaited(c == 'quit' ? tray.quit() : tray.open());
  }
  // The window is up: the update's helper may stop waiting (or the old version says why it is back).
  await WidgetsBinding.instance.endOfFrame;
  await updates?.started(UpdateStart.parse(args));
  updates?.startChecking();
  await controller.startSystems();
  await controller.restore(handoff: handoff);
  unawaited(controller.takeLaunch());
}
