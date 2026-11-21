// 3.10.1: the device's own lock (fingerprint, face, PIN or password, through local_auth) before a
// keychain value is shown or copied. Where the system has no lock set, the person is told so and
// asked; where local_auth does not work (Linux, Android 8 and older, whose dialog needs an AppCompat
// theme the app does not use) the app keeps its own confirmation, as before.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// What asking the device for its lock gave.
enum DeviceUnlockResult {
  /// The person unlocked the device.
  unlocked,

  /// The person cancelled, or the lock refused: nothing is shown.
  refused,

  /// The system has no lock set (no PIN, no fingerprint, no face): nothing can check who it is.
  noLock,

  /// The system's lock cannot be asked from here: the app's own confirmation stands in.
  unsupported,
}

/// The device's lock, replaced in tests.
abstract class DeviceUnlock {
  Future<DeviceUnlockResult> unlock(String reason);
}

/// The one the app uses; tests put their own here.
DeviceUnlock deviceUnlock = SystemUnlock();

/// The system's own lock through local_auth.
class SystemUnlock implements DeviceUnlock {
  SystemUnlock({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  static const _device = MethodChannel('rgcompanion/device');

  /// Android's API level (MainActivity answers it); 0 when it does not.
  static Future<int> _androidSdk() async {
    try {
      return await _device.invokeMethod<int>('sdk') ?? 0;
    } on Object {
      return 0;
    }
  }

  @override
  Future<DeviceUnlockResult> unlock(String reason) async {
    if (!(Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows)) {
      return DeviceUnlockResult.unsupported;
    }
    // Android 9 (API 28) and later show the system's own sheet; before, a dialog that needs an
    // AppCompat theme.
    if (Platform.isAndroid && await _androidSdk() < 28) return DeviceUnlockResult.unsupported;
    try {
      if (!await _auth.isDeviceSupported()) return DeviceUnlockResult.noLock;
      final ok = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return ok ? DeviceUnlockResult.unlocked : DeviceUnlockResult.refused;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.noBiometricsEnrolled => DeviceUnlockResult.noLock,
        LocalAuthExceptionCode.uiUnavailable => DeviceUnlockResult.unsupported,
        _ => DeviceUnlockResult.refused,
      };
    } on MissingPluginException {
      return DeviceUnlockResult.unsupported;
    } on PlatformException {
      return DeviceUnlockResult.unsupported;
    }
  }
}
