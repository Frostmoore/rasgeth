import Flutter
import NetworkExtension
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RGSetupWifi") {
      SetupWifi.register(messenger: registrar.messenger())
    }
  }
}

/// The first start from the app (G40.8): RedGiant OS's temporary network, RedGiant-Setup-XXXX,
/// joined with NEHotspotConfiguration (the Hotspot Configuration entitlement). With the prefix
/// the system asks the person and joins the strongest match; `joinOnce` keeps the network only
/// while the app is in the foreground, and iOS keeps the phone's own connection for the rest.
enum SetupWifi {
  static let prefix = "RedGiant-Setup-"
  private static var channel: FlutterMethodChannel?
  private static var joined: String?

  static func register(messenger: FlutterBinaryMessenger) {
    let ch = FlutterMethodChannel(name: "rgcompanion/setup_wifi", binaryMessenger: messenger)
    ch.setMethodCallHandler { call, result in
      switch call.method {
      case "join":
        join(call.arguments as? [String: Any] ?? [:], result)
      case "leave":
        leave()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    channel = ch
  }

  private static func isSetupSsid(_ s: String) -> Bool {
    s.range(of: "^RedGiant-Setup-[A-Za-z0-9]{1,16}$", options: .regularExpression) != nil
  }

  private static func answer(_ result: @escaping FlutterResult, _ state: String, ssid: String? = nil, message: String? = nil) {
    var m: [String: Any] = ["state": state]
    if let s = ssid { m["ssid"] = s }
    if let t = message { m["message"] = t }
    DispatchQueue.main.async { result(m) }
  }

  private static func join(_ a: [String: Any], _ result: @escaping FlutterResult) {
    let p = a["prefix"] as? String ?? prefix
    let passphrase = a["passphrase"] as? String ?? ""
    let ssid = a["ssid"] as? String
    // Only the temporary network's own names: nothing else is ever asked for.
    guard p == prefix, ssid == nil || isSetupSsid(ssid!) else {
      answer(result, "failed", message: "bad_name")
      return
    }
    let config: NEHotspotConfiguration
    if let s = ssid {
      config = NEHotspotConfiguration(ssid: s, passphrase: passphrase, isWEP: false)
    } else {
      config = NEHotspotConfiguration(ssidPrefix: p, passphrase: passphrase, isWEP: false)
    }
    config.joinOnce = true
    NEHotspotConfigurationManager.shared.apply(config) { error in
      guard let e = error as NSError? else {
        joined = ssid
        answer(result, "joined", ssid: ssid)
        return
      }
      if e.domain == NEHotspotConfigurationErrorDomain,
         let code = NEHotspotConfigurationError(rawValue: e.code) {
        switch code {
        case .alreadyAssociated:
          answer(result, "joined", ssid: ssid)
        case .userDenied:
          answer(result, "cancelled")
        default:
          answer(result, "failed", message: e.localizedDescription)
        }
        return
      }
      answer(result, "failed", message: e.localizedDescription)
    }
  }

  /// The configuration of the exact network goes; one made with the prefix leaves with the app
  /// (`joinOnce`).
  private static func leave() {
    if let s = joined {
      NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: s)
    }
    joined = nil
  }
}
