// The RedGiants the app knows (G40.7: home, work…), each with its pinned key, the local CA and
// where its device token is. What is kept here is public (addresses, fingerprints, the CA's
// certificate); the tokens and the app's own key stay in the system's keystore ([TokenStore]).
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedServer {
  const SavedServer({
    required this.id,
    required this.label,
    required this.address,
    this.fingerprint,
    this.caPem,
    this.deviceId,
    this.setupAddress,
  });

  factory SavedServer.fromJson(Map<String, dynamic> j) => SavedServer(
    id: j['id'] as String? ?? '',
    label: j['label'] as String? ?? 'RedGiant',
    address: j['address'] as String? ?? '',
    fingerprint: j['fingerprint'] as String?,
    caPem: j['caPem'] as String?,
    deviceId: j['deviceId'] as String?,
    setupAddress: j['setupAddress'] as String?,
  );

  /// The app's own id for it (the token's key in the keystore).
  final String id;

  /// The machine's name (or the person's own: «Casa», «Lavoro»).
  final String label;

  /// Where requests go: `https://redgiant.local`, `https://x.ts.net`, `http://127.0.0.1:7600`.
  final String address;

  /// RedGiant's key (`SHA256:…`), pinned at pairing: a different one is refused.
  final String? fingerprint;

  /// The machine's local CA (PEM): with it, https trusts only that CA.
  final String? caPem;
  final String? deviceId;

  /// The channel's address (`http://host:7600`), when requests ride the setup channel.
  final String? setupAddress;

  Uri get base => Uri.parse(address);

  SavedServer copyWith({
    String? label,
    String? address,
    String? fingerprint,
    String? caPem,
    String? deviceId,
    String? setupAddress,
  }) => SavedServer(
    id: id,
    label: label ?? this.label,
    address: address ?? this.address,
    fingerprint: fingerprint ?? this.fingerprint,
    caPem: caPem ?? this.caPem,
    deviceId: deviceId ?? this.deviceId,
    setupAddress: setupAddress ?? this.setupAddress,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'address': address,
    if (fingerprint != null) 'fingerprint': fingerprint,
    if (caPem != null) 'caPem': caPem,
    if (deviceId != null) 'deviceId': deviceId,
    if (setupAddress != null) 'setupAddress': setupAddress,
  };
}

/// The app's settings that survive a restart: appearance, language, the RedGiants, the current one.
abstract class AppPrefs {
  Future<String?> get(String key);
  Future<void> set(String key, String? value);
}

class SharedAppPrefs implements AppPrefs {
  SharedPreferencesAsync? _p;
  SharedPreferencesAsync get _prefs => _p ??= SharedPreferencesAsync();

  @override
  Future<String?> get(String key) => _prefs.getString('rgcompanion.$key');

  @override
  Future<void> set(String key, String? value) => value == null
      ? _prefs.remove('rgcompanion.$key')
      : _prefs.setString('rgcompanion.$key', value);
}

class MemoryAppPrefs implements AppPrefs {
  final Map<String, String> values = {};

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String? value) async =>
      value == null ? values.remove(key) : values[key] = value;
}

class ServerBook {
  ServerBook(this.prefs);

  final AppPrefs prefs;

  Future<List<SavedServer>> load() async {
    final raw = await prefs.get('servers');
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return [for (final j in list.whereType<Map<String, dynamic>>()) SavedServer.fromJson(j)]
          .where((s) => s.id.isNotEmpty && s.address.isNotEmpty)
          .toList();
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<SavedServer> servers) =>
      prefs.set('servers', jsonEncode([for (final s in servers) s.toJson()]));

  /// Adds or replaces (same id; or the same pinned key: the same RedGiant reached anew).
  Future<List<SavedServer>> put(SavedServer s) async {
    final list = [...await load()];
    final i = list.indexWhere(
      (o) => o.id == s.id || (s.fingerprint != null && o.fingerprint == s.fingerprint),
    );
    if (i >= 0) {
      list[i] = s;
    } else {
      list.add(s);
    }
    await save(list);
    return list;
  }

  Future<List<SavedServer>> remove(String id) async {
    final list = [...await load()]..removeWhere((s) => s.id == id);
    await save(list);
    return list;
  }
}
