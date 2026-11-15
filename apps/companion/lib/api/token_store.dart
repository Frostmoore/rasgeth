// Where the app keeps a device's token: the system's keystore (Keychain on iOS and macOS,
// Keystore-backed storage on Android, Credential Manager on Windows, libsecret on Linux), never
// a plain file. One token per RedGiant, keyed by its address (by its fingerprint from G40.7).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStore {
  Future<String?> read(String server);
  Future<void> write(String server, String token);
  Future<void> delete(String server);
}

String _key(String server) => 'rgcompanion.token.$server';

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String server) => _storage.read(key: _key(server));

  @override
  Future<void> write(String server, String token) =>
      _storage.write(key: _key(server), value: token);

  @override
  Future<void> delete(String server) => _storage.delete(key: _key(server));
}

/// For tests (and for platforms without a keystore): forgotten when the app closes.
class MemoryTokenStore implements TokenStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String server) async => values[_key(server)];

  @override
  Future<void> write(String server, String token) async => values[_key(server)] = token;

  @override
  Future<void> delete(String server) async => values.remove(_key(server));
}
