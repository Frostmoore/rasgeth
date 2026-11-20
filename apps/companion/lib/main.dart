// RGCompanion (G40, 3.8): the RedGiant app for Android, iOS, Windows, macOS and Linux. One
// Flutter project; on computers the launchers stay the local server's keeper.
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'api/discovery.dart';
import 'api/legacy_data.dart';
import 'api/servers.dart';
import 'app.dart';
import 'app_state.dart';
import 'app_update/start.dart';
import 'app_update/swap.dart' show UpdateStart;
import 'desktop/handoff.dart';
import 'push/background.dart';
import 'push/distributors.dart';
import 'push/system_notifier.dart';
import 'share/share_intake.dart';

Future<void> main(List<String> args) async {
  // Android starts the app's code without its window for a UnifiedPush message (G40.10).
  if (args.contains('--unifiedpush-bg')) return runPushInBackground();
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController(
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
  runApp(RGCompanionApp(controller: controller));
  // The window is up: the update's helper may stop waiting (or the old version says why it is back).
  await WidgetsBinding.instance.endOfFrame;
  await updates?.started(UpdateStart.parse(args));
  updates?.startChecking();
  await controller.startSystems();
  await controller.restore(handoff: handoff);
  unawaited(controller.takeLaunch());
}
