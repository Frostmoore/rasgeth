// The system's notifications (G40.10): Android (UnifiedPush messages, shown by the app), and the
// computers (Windows, macOS, Linux) while the app is open behind other windows, through one
// maintained package (flutter_local_notifications). iOS shows its own through the Notification
// Service Extension once APNs is on.
import 'dart:io' show Platform;
import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_localizations.dart';
import 'notice.dart';
import '../brand.dart';

/// A tap on a notification or one of its answers ([action]: `allow`, `deny`, or null for the
/// notification itself).
typedef NoticeResponse = void Function(NoticeTap tap, String? action);

abstract class SystemNotifier {
  /// Ready to show; [onResponse] gets taps and answers while the app runs.
  Future<void> init({NoticeResponse? onResponse});
  Future<void> apply(NotificationPlan plan, AppLocalizations l);
  Future<void> cancel(int id);

  /// Android 13+ and the Apple systems ask once; true when notifications may be shown.
  Future<bool> askPermission();

  /// A tap that started the app (Android, iOS, macOS).
  Future<NoticeTap?> launchTap();
}

/// For tests and for systems without notifications: remembers what it was told.
class MemoryNotifier implements SystemNotifier {
  final shown = <int, ShowNotification>{};
  final cancelled = <int>[];
  bool permission = true;
  NoticeResponse? onResponse;

  @override
  Future<void> init({NoticeResponse? onResponse}) async => this.onResponse = onResponse;

  @override
  Future<void> apply(NotificationPlan plan, AppLocalizations l) async {
    switch (plan) {
      case ShowNotification():
        shown[plan.id] = plan;
      case WithdrawNotification():
        await cancel(plan.id);
    }
  }

  @override
  Future<void> cancel(int id) async {
    shown.remove(id);
    cancelled.add(id);
  }

  @override
  Future<bool> askPermission() async => permission;

  @override
  Future<NoticeTap?> launchTap() async => null;
}

const _channelRequests = 'rg.requests';
const _channelUpdates = 'rg.updates';

/// The answers' ids, the same in every system's action.
String answerId(QuickAnswer a) => a.name;

/// The words of a notification without a BuildContext (the background isolate): the system's
/// language, or the one the person chose in the app.
AppLocalizations wordsFor(String? languageCode) {
  final code = languageCode ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupAppLocalizations(Locale(code == 'it' ? 'it' : 'en'));
}

class LocalSystemNotifier implements SystemNotifier {
  LocalSystemNotifier({this.background, FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// A top-level function (`@pragma('vm:entry-point')`): answers pressed while the app is closed.
  final DidReceiveBackgroundNotificationResponseCallback? background;
  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  @override
  Future<void> init({NoticeResponse? onResponse}) async {
    if (_ready) return;
    final l = wordsFor(null);
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_notification'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        linux: LinuxInitializationSettings(defaultActionName: l.notifyOpen),
        windows: const WindowsInitializationSettings(
          appName: kAppName,
          appUserModelId: 'RedGiant.RGCompanion',
          guid: '6b0f4f0e-3c2a-4b8e-9a51-2f8d6c1e7a40',
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final tap = NoticeTap.fromPayload(r.payload);
        if (tap != null) onResponse?.call(tap, r.actionId);
      },
      onDidReceiveBackgroundNotificationResponse: background,
    );
    if (!kIsWeb && Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          _channelRequests,
          l.notifyChannelRequests,
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        AndroidNotificationChannel(_channelUpdates, l.notifyChannelUpdates),
      );
    }
    _ready = true;
  }

  @override
  Future<bool> askPermission() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    if (Platform.isMacOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    return true;
  }

  @override
  Future<NoticeTap?> launchTap() async {
    try {
      final d = await _plugin.getNotificationAppLaunchDetails();
      if (d?.didNotificationLaunchApp != true) return null;
      return NoticeTap.fromPayload(d?.notificationResponse?.payload);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> apply(NotificationPlan plan, AppLocalizations l) async {
    switch (plan) {
      case WithdrawNotification(:final id):
        await cancel(id);
      case ShowNotification():
        await _show(plan, l);
    }
  }

  Future<void> _show(ShowNotification p, AppLocalizations l) async {
    final requests = p.channel == NoticeChannel.requests;
    String label(QuickAnswer a) => a == QuickAnswer.allow ? l.notifyAllow : l.notifyDeny;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        requests ? _channelRequests : _channelUpdates,
        requests ? l.notifyChannelRequests : l.notifyChannelUpdates,
        importance: requests ? Importance.high : Importance.defaultImportance,
        priority: requests ? Priority.high : Priority.defaultPriority,
        subText: p.server,
        styleInformation: BigTextStyleInformation(p.body),
        category: requests ? AndroidNotificationCategory.reminder : null,
        actions: [
          for (final a in p.answers)
            AndroidNotificationAction(
              answerId(a),
              label(a),
              // Answered in the background: the app does not open for a quick answer.
              showsUserInterface: false,
              cancelNotification: true,
            ),
        ],
      ),
      iOS: DarwinNotificationDetails(subtitle: p.server, threadIdentifier: p.server),
      macOS: DarwinNotificationDetails(subtitle: p.server, threadIdentifier: p.server),
      linux: LinuxNotificationDetails(
        actions: [
          for (final a in p.answers) LinuxNotificationAction(key: answerId(a), label: label(a)),
        ],
        urgency: requests ? LinuxNotificationUrgency.critical : LinuxNotificationUrgency.normal,
      ),
      windows: WindowsNotificationDetails(
        subtitle: p.server,
        actions: [
          for (final a in p.answers) WindowsAction(content: label(a), arguments: answerId(a)),
        ],
      ),
    );
    await _plugin.show(
      id: p.id,
      title: p.title,
      body: p.body,
      notificationDetails: details,
      payload: p.payload,
    );
  }
}
