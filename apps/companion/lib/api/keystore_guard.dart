// Windows' keystore file kept safe (3.9.8). flutter_secure_storage_windows keeps every entry in
// one DPAPI-encrypted file (flutter_secure_storage.dat in the app's folder) and deletes the whole
// file when one read of it fails. DPAPI fails where the user's key cannot be opened (the app
// started from a network logon, ssh with a key) and a read can fail while another copy of the
// app writes: either way every token was gone. So, before the keystore is first used:
// - DPAPI is tried on a few bytes; when it does not work here, the keystore is not touched at all
//   (the app asks to pair again, the file stays as it is for the next normal start);
// - the file is copied aside (.bak) at every start, and put back when it went missing.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'legacy_data.dart' show dpapiUnprotect;
import 'token_store.dart';

const kKeystoreFile = 'flutter_secure_storage.dat';

/// What the guard did at start, for the tests and the log.
enum KeystoreGuardResult { untouched, backedUp, restored, noDpapi }

/// [folder]: the app's own folder (path_provider's application support, as the plugin's).
/// [dpapiWorks] and [readable] (whether the file's bytes open): replaced in tests.
Future<KeystoreGuardResult> guardKeystore(
  String folder, {
  bool Function()? dpapiWorks,
  bool Function(Uint8List bytes)? readable,
}) async {
  if (!(dpapiWorks ?? dpapiRoundTrip)()) return KeystoreGuardResult.noDpapi;
  final sep = Platform.pathSeparator;
  final file = File('$folder$sep$kKeystoreFile');
  final bak = File('$folder$sep$kKeystoreFile.bak');
  try {
    if (await file.exists()) {
      // Only a file that opens: a broken one never replaces the last good copy.
      if (!(readable ?? _opens)(await file.readAsBytes())) return KeystoreGuardResult.untouched;
      await file.copy(bak.path);
      return KeystoreGuardResult.backedUp;
    }
    if (await bak.exists()) {
      await bak.copy(file.path);
      return KeystoreGuardResult.restored;
    }
  } on FileSystemException {
    // A file held elsewhere: the next start tries again.
  }
  return KeystoreGuardResult.untouched;
}

/// DPAPI for this user, both ways, on a few bytes.
bool dpapiRoundTrip() {
  if (!Platform.isWindows) return true;
  try {
    final sample = Uint8List.fromList(const [114, 103, 51, 57, 56]);
    return _listEquals(dpapiUnprotect(_protect(sample)), sample);
  } on Object {
    return false;
  }
}

Uint8List _protect(Uint8List plain) => using((alloc) {
  final pIn = alloc<Uint8>(plain.length);
  pIn.asTypedList(plain.length).setAll(0, plain);
  final inBlob = alloc.allocate<CRYPT_INTEGER_BLOB>(sizeOf<CRYPT_INTEGER_BLOB>());
  inBlob.ref.cbData = plain.length;
  inBlob.ref.pbData = pIn;
  final outBlob = alloc.allocate<CRYPT_INTEGER_BLOB>(sizeOf<CRYPT_INTEGER_BLOB>());
  final Win32Result(value: ok, error: err) = CryptProtectData(inBlob, null, null, null, 0, outBlob);
  if (!ok || outBlob.ref.pbData.address == NULL) {
    throw WindowsException(err.toHRESULT(), message: 'CryptProtectData');
  }
  try {
    return Uint8List.fromList(outBlob.ref.pbData.asTypedList(outBlob.ref.cbData));
  } finally {
    LocalFree(HLOCAL(outBlob.ref.pbData.cast()));
  }
});

bool _opens(Uint8List bytes) {
  try {
    return jsonDecode(utf8.decode(dpapiUnprotect(bytes))) is Map;
  } on Object {
    return false;
  }
}

bool _listEquals(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The keystore when it cannot be used safely here: nothing is read, written or deleted.
class UnavailableTokenStore implements TokenStore {
  @override
  Future<String?> read(String server) async => null;

  @override
  Future<void> write(String server, String token) async =>
      throw StateError('the keystore cannot be used in this session');

  @override
  Future<void> delete(String server) async {}
}
