// APNs on iOS (G40.10): PREPARED, SWITCHED OFF until the app is published with an Apple account
// (the APNs key belongs to the publisher; the server sends through the blind relay of
// packaging/push-relay, switched off as well). The code is ready: Apple's device token from the
// channel `rgcompanion/apns` (ios/Apns/ApnsRegistration.swift), registered as `kind: apns` with
// this device's own keys, which are also copied into the keychain group the Notification
// Service Extension reads (ios/NotificationService: it decrypts the notice on the phone).
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/client.dart';
import 'push_center.dart';

/// Switched on when the app is published (with the extension's target and the relay).
const bool kApnsEnabled = false;

/// The keychain group shared with the Notification Service Extension.
const String kApnsKeychainGroup = 'com.redgiant.companion.shared';

class ApnsRegistration {
  static const _channel = MethodChannel('rgcompanion/apns');

  /// Whether iPhone notifications can be turned on in this build.
  static bool get available => kApnsEnabled && !kIsWeb && Platform.isIOS;

  /// Registers this iPhone for [serverId]; false when APNs is off or the person said no.
  static Future<bool> register(
    PushCenter center,
    RedGiantClient client,
    String serverId,
    String deviceId, {
    bool sandbox = kDebugMode,
  }) async {
    if (!available) return false;
    final token = await _channel.invokeMethod<String>('token');
    if (token == null || token.isEmpty) return false;
    await center.registrar.registerApns(client, serverId, deviceId, token, sandbox: sandbox);
    final keys = await center.registrar.keysFor(serverId);
    await const FlutterSecureStorage().write(
      key: 'rgcompanion.apns.$serverId',
      value: jsonEncode(keys.toJson()),
      iOptions: const IOSOptions(groupId: kApnsKeychainGroup),
    );
    return true;
  }
}
