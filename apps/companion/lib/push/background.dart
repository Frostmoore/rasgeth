// The app without its window (G40.10): Android starts the Dart code for a UnifiedPush message
// (`main` with `--unifiedpush-bg`) and for a notification's answer pressed while the app is
// closed (a background isolate). Both build the same [PushCenter] from the saved RedGiants and
// the keystore: nothing else of the app starts.
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api/servers.dart';
import '../api/token_store.dart';
import 'distributors.dart';
import 'notice.dart';
import 'push_center.dart';
import 'system_notifier.dart';

PushCenter backgroundCenter() => PushCenter(
  prefs: SharedAppPrefs(),
  tokens: SecureTokenStore(),
  notifier: LocalSystemNotifier(background: notificationAnswerInBackground),
);

/// `main(['--unifiedpush-bg'])`: listen for the message that woke the app, show it, done.
Future<void> runPushInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  final center = backgroundCenter();
  await center.notifier.init();
  await UnifiedPushDistributors.start(center);
}

QuickAnswer? quickAnswerOf(String? actionId) =>
    QuickAnswer.values.where((a) => a.name == actionId).firstOrNull;

/// A Yes or a No pressed on a notification while the app is closed.
@pragma('vm:entry-point')
Future<void> notificationAnswerInBackground(NotificationResponse r) async {
  DartPluginRegistrant.ensureInitialized();
  final tap = NoticeTap.fromPayload(r.payload);
  final a = quickAnswerOf(r.actionId);
  if (tap == null || a == null) return;
  final center = backgroundCenter();
  await center.notifier.init();
  await center.answer(tap, a);
}
