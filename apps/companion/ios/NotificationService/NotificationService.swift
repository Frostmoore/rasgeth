// RGCompanion's Notification Service Extension (G40.10): PREPARED, NOT ACTIVE. It is not part of
// Runner.xcodeproj yet, so nothing here is built: it is switched on when the app is published
// with an Apple developer account (the APNs key belongs to the publisher, see
// packaging/push-relay and `kApnsEnabled` in lib/push/apns.dart).
//
// What it does: the blind relay passes APNs a generic alert ("RG_NOTICE") with `mutable-content`
// and the notice sealed for this device in `rg` (RFC 8291, aes128gcm, exactly as
// packages/server/src/push/ece.ts seals it). This extension opens it with the device's own key
// pair (kept in the shared keychain group by the app, one per RedGiant: whichever opens it is
// the right one), and shows the real title and text. A request never gets a quick "yes" when it
// is critical: the category without actions opens the app on the request's own screen.
//
// To switch it on (Xcode, once there is an account):
//   1. File > New > Target > Notification Service Extension, named "NotificationService",
//      bundle id it.rasgeth.app.NotificationService, the same deployment target as
//      Runner; replace its files with this folder's NotificationService.swift and Info.plist.
//   2. Keychain Sharing in BOTH Runner and NotificationService, group
//      it.rasgeth.app.shared (the app writes the keys there: lib/push/apns.dart).
//   3. Push Notifications capability in Runner; ios/Apns/ApnsRegistration.swift into Runner.
//   4. Set `kApnsEnabled = true` and the relay's address on the server
//      (REDGIANT_PUSH_RELAY_URL).
import CryptoKit
import Foundation
import Security
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {
  private var handler: ((UNNotificationContent) -> Void)?
  private var content: UNMutableNotificationContent?

  override func didReceive(
    _ request: UNNotificationRequest,
    withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
  ) {
    handler = contentHandler
    let c = (request.content.mutableCopy() as? UNMutableNotificationContent)
      ?? UNMutableNotificationContent()
    content = c
    guard let sealed = request.content.userInfo["rg"] as? String,
          let body = Data(base64URL: sealed)
    else {
      contentHandler(c)
      return
    }
    for keys in PushKeys.all() {
      guard let plain = try? WebPush.open(body, keys),
            let notice = try? JSONSerialization.jsonObject(with: plain) as? [String: Any],
            notice["v"] as? Int == 1
      else { continue }
      Notice.apply(notice, serverId: keys.serverId, to: c)
      contentHandler(c)
      return
    }
    // Not for any key of this device: the generic alert stays.
    contentHandler(c)
  }

  override func serviceExtensionTimeWillExpire() {
    if let h = handler, let c = content { h(c) }
  }
}

/// The device's keys for one RedGiant (`PushKeyPair.toJson`: the private scalar `d` and `auth`,
/// base64url), written by the app into the shared keychain group.
struct PushKeys {
  static let group = "it.rasgeth.app.shared"
  static let service = "flutter_secure_storage_service"
  static let prefix = "rgcompanion.apns."

  let serverId: String
  let d: Data
  let auth: Data

  static func all() -> [PushKeys] {
    let q: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccessGroup as String: group,
      kSecMatchLimit as String: kSecMatchLimitAll,
      kSecReturnAttributes as String: true,
      kSecReturnData as String: true,
    ]
    var out: CFTypeRef?
    guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess,
          let items = out as? [[String: Any]]
    else { return [] }
    return items.compactMap { item in
      guard let account = item[kSecAttrAccount as String] as? String,
            account.hasPrefix(prefix),
            let data = item[kSecValueData as String] as? Data,
            let j = try? JSONSerialization.jsonObject(with: data) as? [String: String],
            let d = j["d"].flatMap({ Data(base64URL: $0) }),
            let auth = j["auth"].flatMap({ Data(base64URL: $0) }),
            d.count == 32, auth.count == 16
      else { return nil }
      return PushKeys(serverId: String(account.dropFirst(prefix.count)), d: d, auth: auth)
    }
  }
}

enum WebPushError: Error { case shape, record }

/// RFC 8291 on the device, the same steps as lib/push/ece.dart.
enum WebPush {
  static func open(_ body: Data, _ k: PushKeys) throws -> Data {
    let b = [UInt8](body)
    guard b.count > 86 + 17, b[20] == 65 else { throw WebPushError.shape }
    let salt = Data(b[0..<16])
    let asPublic = Data(b[21..<86])
    let data = Data(b[86...])
    let priv = try P256.KeyAgreement.PrivateKey(rawRepresentation: k.d)
    let pub = try P256.KeyAgreement.PublicKey(x963Representation: asPublic)
    let shared = try priv.sharedSecretFromKeyAgreement(with: pub)
    let uaPublic = priv.publicKey.x963Representation
    let ikm = shared.hkdfDerivedSymmetricKey(
      using: SHA256.self,
      salt: k.auth,
      sharedInfo: Data("WebPush: info\u{0}".utf8) + uaPublic + asPublic,
      outputByteCount: 32
    )
    let cek = HKDF<SHA256>.deriveKey(
      inputKeyMaterial: ikm, salt: salt,
      info: Data("Content-Encoding: aes128gcm\u{0}".utf8), outputByteCount: 16)
    let nonce = HKDF<SHA256>.deriveKey(
      inputKeyMaterial: ikm, salt: salt,
      info: Data("Content-Encoding: nonce\u{0}".utf8), outputByteCount: 12)
    let nonceBytes = nonce.withUnsafeBytes { Data($0) }
    let box = try AES.GCM.SealedBox(
      nonce: AES.GCM.Nonce(data: nonceBytes),
      ciphertext: data.prefix(data.count - 16),
      tag: data.suffix(16))
    var record = [UInt8](try AES.GCM.open(box, using: cek))
    while let last = record.last, last == 0 { record.removeLast() }
    guard record.last == 2 else { throw WebPushError.record }
    record.removeLast()
    return Data(record)
  }
}

/// What the notification shows, as lib/push/notice.dart's `planFor`.
enum Notice {
  static func apply(_ n: [String: Any], serverId: String, to c: UNMutableNotificationContent) {
    if n["closed"] != nil {
      // Answered elsewhere: the relay sent it quietly; the app removes the one shown when it
      // next runs (APNs cannot withdraw without the app).
      c.title = n["title"] as? String ?? c.title
      c.body = n["body"] as? String ?? c.body
      return
    }
    c.title = n["title"] as? String ?? c.title
    c.body = n["body"] as? String ?? c.body
    c.subtitle = n["server"] as? String ?? ""
    c.threadIdentifier = serverId
    let kind = n["kind"] as? String ?? ""
    let critical = n["critical"] as? Bool ?? false
    let actions = n["actions"] as? [String] ?? []
    // RG_REQUEST has Yes and No (registered by the app); critical requests and the rest open it.
    c.categoryIdentifier =
      kind == "request" && !critical && actions.contains("allow") ? "RG_REQUEST" : "RG_OPEN"
    var info = c.userInfo
    info["rgNotice"] = [
      "s": serverId, "n": n["id"] as? String ?? "", "k": kind,
      "r": n["requestId"] as? String ?? "", "c": n["sessionId"] as? String ?? "",
      "x": critical,
    ]
    c.userInfo = info
  }
}

extension Data {
  init?(base64URL s: String) {
    var t = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    while t.count % 4 != 0 { t += "=" }
    self.init(base64Encoded: t)
  }
}
