// G42.12: the routes of Settings › Keychain, as the page calls them (`packages/web/src/api.ts`:
// `vault`, `addVault`, `editVault`, `removeVault`, `revealVault`, `previewVaultImport`,
// `confirmVaultImport`, `exportVault`, `importVaultFile`, `vaultBrowsers`, `vaultBrowserCode`,
// `unlinkVaultBrowser`), read leniently. A value comes back only through [revealVault], when the
// person asks to see or copy it.
import '../../api/client.dart';
import '../extensions/ext_catalog.dart' show Json;

String? _s(Object? o) => o is String ? o : null;
int? _n(Object? o) => o is num ? o.toInt() : null;
List<String> _strings(Object? o) => o is List ? [for (final x in o) x is String ? x : '$x'] : [];
Json _map(Object? o) => o is Map<String, dynamic> ? o : const {};
List<Json> _list(Object? o) => o is List ? [for (final x in o) _map(x)] : const [];

/// The part of the server that uses a key kept in the keychain (`VaultUsedBy`).
class VaultUsedBy {
  const VaultUsedBy(this.j);
  final Json j;
  String get key => _s(j['key']) ?? '';
  String get section => _s(j['section']) ?? '';
  String get kind => _s(j['kind']) ?? 'other';
  String get what => _s(j['what']) ?? '';
}

/// A credential, everything but its value (`VaultEntry`).
class VaultEntry {
  const VaultEntry(this.j);
  final Json j;
  String get id => _s(j['id']) ?? '';
  String get name => _s(j['name']) ?? '';
  String get service => _s(j['service']) ?? '';
  String? get brand => _s(j['brand']);
  String get category => _s(j['category']) ?? 'api';
  List<String> get tags => _strings(j['tags']);
  String get username => _s(j['username']) ?? '';
  String get url => _s(j['url']) ?? '';
  List<String> get hosts => _strings(j['hosts']);
  String get notes => _s(j['notes']) ?? '';
  String? get expires => _s(j['expires']);
  String get ask => _s(j['ask']) ?? 'session';
  Json get allow => _map(j['allow']);
  bool get allAgents => allow['allAgents'] != false;
  List<String> get agents => _strings(allow['agents']);
  List<String> get tools => _strings(allow['tools']);
  List<String> get automations => _strings(allow['automations']);
  Json get inject => _map(j['inject']);
  String get header => _s(inject['header']) ?? 'Authorization';
  String get format => _s(inject['format']) ?? 'Bearer {value}';
  int get length => _n(j['length']) ?? 0;
  String? get lastUsedAt => _s(j['lastUsedAt']);
  int get uses => _n(j['uses']) ?? 0;
  VaultUsedBy? get usedBy =>
      j['usedBy'] is Map<String, dynamic> ? VaultUsedBy(j['usedBy'] as Json) : null;
}

/// A key the server keeps elsewhere, listed so there is one place to see them (`VaultSystemEntry`).
class VaultSystemEntry {
  const VaultSystemEntry(this.j);
  final Json j;
  String get id => _s(j['id']) ?? '';
  String get service => _s(j['service']) ?? '';
  String get category => _s(j['category']) ?? 'other';
  String get section => _s(j['section']) ?? '';
  String get what => _s(j['what']) ?? '';
  String get kind => _s(j['kind']) ?? 'other';
  bool get locked => j['locked'] == true;
}

/// One use of a credential (`VaultUse`).
class VaultUse {
  const VaultUse(this.j);
  final Json j;
  String get id => _s(j['id']) ?? '';
  String get entryId => _s(j['entryId']) ?? '';
  String get name => _s(j['name']) ?? '';
  String get at => _s(j['at']) ?? '';
  String? get agentId => _s(j['agentId']);
  String? get agentName => _s(j['agentName']);
  String? get sessionId => _s(j['sessionId']);
  String get tool => _s(j['tool']) ?? '';
  String get host => _s(j['host']) ?? '';
  String get outcome => _s(j['outcome']) ?? 'used';
  String? get reason => _s(j['reason']);
}

/// The keychain as the page sees it (`VaultView`).
class VaultView {
  const VaultView(this.j);
  final Json j;
  bool get ready => j['ready'] == true;
  String? get reason => _s(j['reason']);
  String? get protection => _s(j['protection']);
  List<VaultEntry> get entries => [for (final e in _list(j['entries'])) VaultEntry(e)];
  List<VaultSystemEntry> get system => [for (final e in _list(j['system'])) VaultSystemEntry(e)];
  List<VaultUse> get uses => [for (final e in _list(j['uses'])) VaultUse(e)];
  bool get proxy => j['proxy'] == true;
}

/// One row of a password manager's export, before it is saved (`VaultImportRow`).
class VaultImportRow {
  const VaultImportRow(this.j);
  final Json j;
  String get service => _s(j['service']) ?? '';
  String get username => _s(j['username']) ?? '';
  String get url => _s(j['url']) ?? '';
  String get name => _s(j['name']) ?? '';
  bool get exists => j['exists'] == true;
}

class VaultImportPreview {
  const VaultImportPreview(this.j);
  final Json j;
  String get id => _s(j['id']) ?? '';
  String get format => _s(j['format']) ?? 'generic';
  List<VaultImportRow> get rows => [for (final r in _list(j['rows'])) VaultImportRow(r)];
  int get skipped => _n(j['skipped']) ?? 0;
}

/// A browser linked to the keychain (`VaultBrowser`).
class VaultBrowser {
  const VaultBrowser(this.j);
  final Json j;
  String get id => _s(j['id']) ?? '';
  String get name => _s(j['name']) ?? '';
  String get browser => _s(j['browser']) ?? 'other';
  String get createdAt => _s(j['createdAt']) ?? '';
  String? get lastSeenAt => _s(j['lastSeenAt']);
}

extension KeychainApi on RedGiantClient {
  String _e(String s) => Uri.encodeComponent(s);

  Future<VaultView> vault() async => VaultView(objectOf(await getJson('/api/vault')));

  Future<void> addVault(Json body) => callJson('POST', '/api/vault', body);

  Future<void> editVault(String id, Json body) => callJson('PUT', '/api/vault/${_e(id)}', body);

  Future<void> removeVault(String id) => callJson('DELETE', '/api/vault/${_e(id)}');

  /// The value, on the person's own request (confirmed in the app first).
  Future<String> revealVault(String id) async =>
      _s(objectOf(await callJson('POST', '/api/vault/${_e(id)}/reveal'))['value']) ?? '';

  Future<VaultImportPreview> previewVaultImport(String csv) async => VaultImportPreview(
    objectOf(await callJson('POST', '/api/vault-import/preview', {'csv': csv})),
  );

  Future<int> confirmVaultImport(String id, List<int> keep) async =>
      _n(
        objectOf(
          await callJson('POST', '/api/vault-import/confirm', {'id': id, 'keep': keep}),
        )['added'],
      ) ??
      0;

  /// A sealed export, as text, for the passphrase.
  Future<String> exportVault(String passphrase) async =>
      _s(
        objectOf(await callJson('POST', '/api/vault-export', {'passphrase': passphrase}))['file'],
      ) ??
      '';

  Future<int> importVaultFile(String file, String passphrase) async =>
      _n(
        objectOf(
          await callJson('POST', '/api/vault-import/sealed', {
            'file': file,
            'passphrase': passphrase,
          }),
        )['added'],
      ) ??
      0;

  Future<List<VaultBrowser>> vaultBrowsers() async => [
    for (final b in arrayOf(await getJson('/api/vault-browsers'))) VaultBrowser(b),
  ];

  /// A code that links one browser, valid ten minutes.
  Future<({String code, String expiresAt})> vaultBrowserCode() async {
    final o = objectOf(await callJson('POST', '/api/vault-browsers/code'));
    return (code: _s(o['code']) ?? '', expiresAt: _s(o['expiresAt']) ?? '');
  }

  Future<void> unlinkVaultBrowser(String id) => callJson('DELETE', '/api/vault-browsers/${_e(id)}');
}
