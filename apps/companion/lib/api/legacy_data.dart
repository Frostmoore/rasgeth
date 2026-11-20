// What the app kept under its name before 3.9.0, carried over once (3.9.8).
//
// Windows is the one system where the rename moved the app's data: path_provider's folder is
// %APPDATA%\<CompanyName>\<ProductName>, RedGiant\RGCompanion before and Rasgeth\Rasgeth now.
// main.cpp copies the old folder at the first start under the new name, but the secure storage
// (flutter_secure_storage.dat, DPAPI-encrypted for the user) can still go missing in the new
// one: the plugin deletes its whole file when one read of it fails, and an app that finds no
// token used to show «unreachable», whose only way out was to forget the RedGiant. So the first
// start of 3.9.8 reads the old folder itself: the keystore's entries the new one lacks are
// written, read back and only then removed from the old file; the RedGiants the new list lacks
// (one forgotten that way, too) come back, to be paired again if their token is gone.
//
// macOS and Linux kept their identity across the rename (bundle id and application id
// `com.redgiant.companion`, the keychain's service and libsecret's label and account derive from
// it, the token keys are the same `rgcompanion.token.*`): nothing moved, nothing to carry.
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'servers.dart';
import 'token_store.dart';

/// The old app's data: its saved RedGiants (raw JSON objects), the one in use, and its keystore's
/// entries ([secrets], full keys as the plugin keeps them, e.g. `rgcompanion.token.<id>`).
class LegacyAppData {
  const LegacyAppData({this.servers = const [], this.current, this.secrets = const {}});

  final List<Map<String, dynamic>> servers;
  final String? current;
  final Map<String, String> secrets;
}

/// Where the old app's data are read from (a fake in tests).
abstract class LegacySource {
  /// Null: there is no old app's data here. Throws when they are there but cannot be read now.
  Future<LegacyAppData?> read();

  /// Removes the old keystore's entries (only after each one was written anew and read back).
  Future<void> forgetSecrets();
}

/// What one carrying did, for the log and the tests.
class LegacyOutcome {
  const LegacyOutcome({
    this.ran = false,
    this.secretsCarried = 0,
    this.secretsKept = 0,
    this.secretsFailed = 0,
    this.serversRecovered = 0,
    this.oldSecretsForgotten = false,
  });

  /// False: done before (or nothing to do on this system).
  final bool ran;

  /// Entries written into the new keystore and read back equal.
  final int secretsCarried;

  /// Entries the new keystore already had (never overwritten).
  final int secretsKept;
  final int secretsFailed;
  final int serversRecovered;
  final bool oldSecretsForgotten;
}

/// The marker in the app's settings: set once everything was carried.
const kLegacyCarriedKey = 'legacyCarried';

const _tokenPrefix = 'rgcompanion.token.';

/// Carries the old app's data once ([source] null: nothing to carry on this system).
/// Secrets first, each one verified; the old ones are removed only when all of them made it,
/// and the marker is set only then (a failure tries again at the next start). The RedGiants
/// come back whatever happens to the tokens: without one the app asks to pair again.
Future<LegacyOutcome> carryLegacyData({
  required LegacySource? source,
  required AppPrefs prefs,
  required TokenStore tokens,
}) async {
  if (source == null || await prefs.get(kLegacyCarriedKey) != null) {
    return const LegacyOutcome();
  }
  final LegacyAppData? old;
  try {
    old = await source.read();
  } on Object {
    // There but unreadable now (a file held by another program): the next start tries again.
    return const LegacyOutcome(ran: true, secretsFailed: 1);
  }
  if (old == null) {
    await prefs.set(kLegacyCarriedKey, '1');
    return const LegacyOutcome(ran: true);
  }

  var carried = 0;
  var kept = 0;
  var failed = 0;
  for (final e in old.secrets.entries) {
    // Only the app's own entries, under the names the app reads them by.
    if (!e.key.startsWith(_tokenPrefix) || e.key.length == _tokenPrefix.length) continue;
    final name = e.key.substring(_tokenPrefix.length);
    try {
      final now = await tokens.read(name);
      if (now != null) {
        kept++;
        continue;
      }
      await tokens.write(name, e.value);
      if (await tokens.read(name) == e.value) {
        carried++;
      } else {
        failed++;
      }
    } on Object {
      failed++;
    }
  }

  final book = ServerBook(prefs);
  final have = await book.load();
  var list = [...have];
  var recovered = 0;
  for (final j in old.servers) {
    final s = SavedServer.fromJson(j);
    if (s.id.isEmpty || s.address.isEmpty) continue;
    final known = list.any(
      (o) =>
          o.id == s.id ||
          (s.fingerprint != null && o.fingerprint == s.fingerprint) ||
          o.address == s.address,
    );
    if (known) continue;
    list = [...list, s];
    recovered++;
  }
  if (recovered > 0) {
    await book.save(list);
    if (await prefs.get('current') == null) {
      final cur = old.current;
      final back = list.where((s) => s.id == cur).firstOrNull ?? list.first;
      await prefs.set('current', back.id);
    }
  }

  var forgotten = false;
  if (failed == 0) {
    if (old.secrets.isNotEmpty) {
      try {
        await source.forgetSecrets();
        forgotten = true;
      } on Object {
        // Everything is in the new keystore anyway: the old file only stays behind.
      }
    }
    await prefs.set(kLegacyCarriedKey, '1');
  }
  return LegacyOutcome(
    ran: true,
    secretsCarried: carried,
    secretsKept: kept,
    secretsFailed: failed,
    serversRecovered: recovered,
    oldSecretsForgotten: forgotten,
  );
}

/// Windows before 3.9.0: %APPDATA%\RedGiant\RGCompanion ([folder] for the tests).
class WindowsLegacySource implements LegacySource {
  WindowsLegacySource([String? folder]) : folder = folder ?? _defaultFolder();

  final String? folder;

  static String? _defaultFolder() {
    final roaming = Platform.environment['APPDATA'];
    if (roaming == null || roaming.isEmpty) return null;
    return '$roaming\\RedGiant\\RGCompanion';
  }

  File get _prefs => File('$folder${Platform.pathSeparator}shared_preferences.json');
  File get _secrets => File('$folder${Platform.pathSeparator}flutter_secure_storage.dat');

  @override
  Future<LegacyAppData?> read() async {
    if (folder == null) return null;
    final p = _prefs;
    final d = _secrets;
    final hasPrefs = await p.exists();
    final hasSecrets = await d.exists();
    if (!hasPrefs && !hasSecrets) return null;
    var servers = const <Map<String, dynamic>>[];
    String? current;
    if (hasPrefs) {
      try {
        final j = jsonDecode(await p.readAsString());
        if (j is Map) {
          final raw = j['rgcompanion.servers'];
          final list = raw is String ? jsonDecode(raw) : null;
          if (list is List) servers = list.whereType<Map<String, dynamic>>().toList();
          final c = j['rgcompanion.current'];
          if (c is String) current = c;
        }
      } on FormatException {
        // An unreadable list: nothing from it.
      }
    }
    var secrets = const <String, String>{};
    if (hasSecrets) {
      final plain = utf8.decode(dpapiUnprotect(await d.readAsBytes()));
      final j = jsonDecode(plain);
      if (j is Map) {
        secrets = {
          for (final e in j.entries)
            if (e.key is String && e.value is String) e.key as String: e.value as String,
        };
      }
    }
    return LegacyAppData(servers: servers, current: current, secrets: secrets);
  }

  @override
  Future<void> forgetSecrets() async {
    final d = _secrets;
    if (await d.exists()) await d.delete();
  }
}

/// Decrypts what flutter_secure_storage_windows wrote: DPAPI for the current user, no entropy.
Uint8List dpapiUnprotect(Uint8List encrypted) => using((alloc) {
  final pIn = alloc<Uint8>(encrypted.length);
  pIn.asTypedList(encrypted.length).setAll(0, encrypted);
  final inBlob = alloc.allocate<CRYPT_INTEGER_BLOB>(sizeOf<CRYPT_INTEGER_BLOB>());
  inBlob.ref.cbData = encrypted.length;
  inBlob.ref.pbData = pIn;
  final outBlob = alloc.allocate<CRYPT_INTEGER_BLOB>(sizeOf<CRYPT_INTEGER_BLOB>());
  final Win32Result(value: ok, error: err) = CryptUnprotectData(
    inBlob,
    null,
    null,
    null,
    0,
    outBlob,
  );
  if (!ok || outBlob.ref.pbData.address == NULL) {
    throw WindowsException(err.toHRESULT(), message: 'CryptUnprotectData');
  }
  try {
    return Uint8List.fromList(outBlob.ref.pbData.asTypedList(outBlob.ref.cbData));
  } finally {
    LocalFree(HLOCAL(outBlob.ref.pbData.cast()));
  }
});
