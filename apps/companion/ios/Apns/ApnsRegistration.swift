// APNs registration for RGCompanion (G40.10): PREPARED, NOT ACTIVE. Not part of
// Runner.xcodeproj yet. When the app is published (see NotificationService.swift), add this file
// to Runner, the Push Notifications capability, and in AppDelegate:
//   ApnsRegistration.register(messenger: registrar.messenger())   // next to SetupWifi
//   override func application(_ a: UIApplication,
//       didRegisterForRemoteNotificationsWithDeviceToken t: Data) { ApnsRegistration.got(t) }
//   override func application(_ a: UIApplication,
//       didFailToRegisterForRemoteNotificationsWithError e: Error) { ApnsRegistration.failed(e) }
// The Dart side (`ApnsRegistration` in lib/push/apns.dart) asks for the token on the channel
// "rgcompanion/apns" and sends it with the device's keys to `PUT /api/devices/:id/push`.
import Flutter
import UIKit
import UserNotifications

enum ApnsRegistration {
  private static var pending: [FlutterResult] = []

  static func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "rgcompanion/apns", binaryMessenger: messenger)
    ch.setMethodCallHandler { call, result in
      guard call.method == "token" else { return result(FlutterMethodNotImplemented) }
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
        ok, _ in
        guard ok else { return DispatchQueue.main.async { result(nil) } }
        DispatchQueue.main.async {
          pending.append(result)
          UIApplication.shared.registerForRemoteNotifications()
        }
      }
    }
    // Yes / No on a request's notification (critical ones use RG_OPEN, without actions).
    let yes = UNNotificationAction(identifier: "allow", title: NSLocalizedString("Yes", comment: ""))
    let no = UNNotificationAction(identifier: "deny", title: NSLocalizedString("No", comment: ""))
    UNUserNotificationCenter.current().setNotificationCategories([
      UNNotificationCategory(identifier: "RG_REQUEST", actions: [yes, no], intentIdentifiers: []),
      UNNotificationCategory(identifier: "RG_OPEN", actions: [], intentIdentifiers: []),
    ])
  }

  static func got(_ token: Data) {
    let hex = token.map { String(format: "%02x", $0) }.joined()
    pending.forEach { $0(hex) }
    pending.removeAll()
  }

  static func failed(_ error: Error) {
    pending.forEach { $0(nil) }
    pending.removeAll()
  }
}
