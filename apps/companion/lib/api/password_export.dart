// Password managers' exports in a message (3.9.8), a faithful port of
// packages/protocol/src/password-export.ts (`findPasswordExports`, `passwordExportRows`,
// `withoutPasswordExports`): where an export is and how many passwords it holds, never a value.
// The app only holds the message and sends the export to the server's keychain; the rows are read
// there. test/g42_1_secrets_test.dart checks the port against the protocol's own vectors
// (tool/secrets_vectors.mjs): change the TypeScript first, then regenerate them.

import 'dart:convert';

/// Where an export is in a text (UTF-16 code units) and how many passwords it holds.
class PasswordExportSpan {
  const PasswordExportSpan(this.kind, this.start, this.end, this.rows);

  final String kind;
  final int start;
  final int end;
  final int rows;
}

({List<String> fields, int next}) _readRecord(String s, int at, String sep) {
  final fields = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var i = at;
  for (; i < s.length; i++) {
    final c = s[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < s.length && s[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
      continue;
    }
    if (c == '"' && field.toString().trim().isEmpty) {
      quoted = true;
      field.clear();
    } else if (c == sep) {
      fields.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      final next = c == '\r' && i + 1 < s.length && s[i + 1] == '\n' ? i + 2 : i + 1;
      fields.add(field.toString());
      return (fields: fields, next: next);
    } else {
      field.write(c);
    }
  }
  fields.add(field.toString());
  return (fields: fields, next: s.length);
}

const _passwordColumns = [
  'login_password',
  'password',
  'passwort',
  'pass',
  'pwd',
  "parola d'ordine",
  'mot de passe',
  'contraseña',
];
const _otherColumns = [
  'url',
  'uri',
  'login_uri',
  'website',
  'web site',
  'site',
  'name',
  'title',
  'username',
  'user name',
  'login name',
  'login_username',
  'login',
  'user',
  'email',
  'account',
  'sito',
  'nome',
  'titolo',
  'utente',
  'nome utente',
  'indirizzo',
];

String _kindOfHeader(Set<String> h) {
  if (h.contains('login_password') || h.contains('login_uri')) return 'bitwarden';
  if (h.contains('httprealm') || h.contains('formactionorigin')) return 'firefox';
  if (h.contains('login name') ||
      (h.contains('group') && h.contains('title')) ||
      h.contains('web site')) {
    return 'keepass';
  }
  if (h.contains('otpauth') || (h.contains('title') && h.contains('password'))) {
    return '1password';
  }
  if (h.contains('website') && h.contains('login')) return 'avira';
  if (h.contains('name') && h.contains('url') && h.contains('username')) return 'chrome';
  return 'csv';
}

int _trimEnd(String s, int end) {
  var e = end;
  while (e > 0 && (s[e - 1] == '\n' || s[e - 1] == '\r')) {
    e--;
  }
  return e;
}

({String sep, List<String> names, int next})? _headerAt(String s, int at) {
  final nl = s.indexOf('\n', at);
  final line = s.substring(at, nl < 0 ? s.length : nl);
  if (line.length > 600) return null;
  var sep = ',';
  var n = -1;
  for (final c in [',', ';', '\t']) {
    final k = line.split(c).length - 1;
    if (k > n) {
      n = k;
      sep = c;
    }
  }
  if (n < 1) return null;
  final r = _readRecord(s, at, sep);
  final names = [for (final f in r.fields) f.trim().toLowerCase()];
  if (!names.any(_passwordColumns.contains)) return null;
  if (!names.any(_otherColumns.contains)) return null;
  if (names.any((x) => x.length > 40)) return null;
  return (sep: sep, names: names, next: r.next);
}

List<PasswordExportSpan> _readCsv(String s) {
  final out = <PasswordExportSpan>[];
  var at = 0;
  while (at < s.length) {
    final head = _headerAt(s, at);
    final lineEnd = s.indexOf('\n', at);
    if (head == null) {
      if (lineEnd < 0) break;
      at = lineEnd + 1;
      continue;
    }
    var vi = -1;
    for (final c in _passwordColumns) {
      final i = head.names.indexOf(c);
      if (i >= 0) {
        vi = i;
        break;
      }
    }
    var rows = 0;
    var end = head.next;
    var p = head.next;
    while (p < s.length) {
      final r = _readRecord(s, p, head.sep);
      if (r.fields.length < 2 || r.fields.length > head.names.length + 2) break;
      if (r.fields.length < (head.names.length / 2).ceil()) break;
      final value = vi >= 0 && vi < r.fields.length ? r.fields[vi] : '';
      if (value.trim().isNotEmpty) rows++;
      end = r.next;
      p = r.next;
    }
    if (rows > 0) {
      out.add(PasswordExportSpan(_kindOfHeader(head.names.toSet()), at, _trimEnd(s, end), rows));
      at = end;
    } else {
      at = head.next;
    }
  }
  return out;
}

final _jsonPassword = RegExp(r'"(?:password|login_password)"\s*:\s*"((?:[^"\\]|\\.)+)"');
final _jsonDesignation = RegExp(r'"designation"\s*:\s*"password"');

int _walkJson(Object? v, [int depth = 0]) {
  if (depth > 12 || v == null) return 0;
  if (v is List) {
    var n = 0;
    for (final x in v) {
      n += _walkJson(x, depth + 1);
    }
    return n;
  }
  if (v is! Map) return 0;
  String str(Object? x) => x is String ? x : '';
  final login = v['login'] is Map ? v['login'] as Map : null;
  final details = v['details'];
  if (details is Map && details['loginFields'] is List) {
    final f = details['loginFields'] as List;
    final pw = f
        .whereType<Map<dynamic, dynamic>>()
        .where((x) => x['designation'] == 'password')
        .firstOrNull;
    if (str(pw?['value']).isNotEmpty) return 1;
  }
  final value = str(login?['password']).isNotEmpty
      ? str(login?['password'])
      : str(v['password']).isNotEmpty
      ? str(v['password'])
      : str(v['login_password']);
  if (value.isNotEmpty) return 1;
  var n = 0;
  for (final x in v.values) {
    n += _walkJson(x, depth + 1);
  }
  return n;
}

PasswordExportSpan? _readJson(String s) {
  final values = [
    for (final m in _jsonPassword.allMatches(s))
      if ((m[1] ?? '').trim().isNotEmpty) m,
  ];
  final designations = _jsonDesignation.allMatches(s).toList();
  var first = s.length;
  if (values.isNotEmpty && values.first.start < first) first = values.first.start;
  if (designations.isNotEmpty && designations.first.start < first) first = designations.first.start;
  if (first == s.length) return null;
  var start = first;
  final opener = RegExp(r'(?:^|\n)[ \t]*([[{])').firstMatch(s.substring(0, first));
  if (opener != null) start = opener.end - 1;
  final end =
      (s.lastIndexOf('}') > s.lastIndexOf(']') ? s.lastIndexOf('}') : s.lastIndexOf(']')) + 1;
  if (end <= start) return null;
  int rows;
  try {
    rows = _walkJson(jsonDecode(s.substring(start, end)));
  } catch (_) {
    rows = values.length;
  }
  final shaped =
      RegExp(r'"(?:items|logins|accounts|entries)"\s*:').hasMatch(s) || designations.isNotEmpty;
  if (rows == 0 || (rows < 2 && !shaped)) return null;
  final kind = designations.isNotEmpty
      ? '1password'
      : RegExp(r'"encrypted"\s*:\s*false').hasMatch(s) || RegExp(r'"login"\s*:\s*\{').hasMatch(s)
      ? 'bitwarden'
      : 'json';
  return PasswordExportSpan(kind, start, end, rows);
}

PasswordExportSpan? _readXml(String s) {
  var rows = 0;
  final pair = RegExp(r'<String>\s*<Key>([^<]*)</Key>\s*<Value[^>]*>([^<]*)</Value>\s*</String>');
  for (final m in RegExp(r'<Entry>([\s\S]*?)</Entry>').allMatches(s)) {
    for (final p in pair.allMatches(m[1] ?? '')) {
      if ((p[1] ?? '').toLowerCase() == 'password' && (p[2] ?? '').isNotEmpty) {
        rows++;
        break;
      }
    }
  }
  for (final m in RegExp(r'<pwentry>([\s\S]*?)</pwentry>', caseSensitive: false).allMatches(s)) {
    final v = RegExp(r'<password>([^<]*)</password>', caseSensitive: false).firstMatch(m[1] ?? '');
    if ((v?[1] ?? '').isNotEmpty) rows++;
  }
  if (rows == 0) return null;
  final open = RegExp(r'<\?xml|<KeePassFile|<pwlist', caseSensitive: false).firstMatch(s);
  final first = RegExp(r'<Entry>|<pwentry>', caseSensitive: false).firstMatch(s);
  final start = open?.start ?? first?.start ?? 0;
  final closes = RegExp(
    r'</KeePassFile>|</pwlist>|</Entry>|</pwentry>',
    caseSensitive: false,
  ).allMatches(s).toList();
  final end = closes.isEmpty ? s.length : closes.last.end;
  return PasswordExportSpan('keepass', start, end, rows);
}

final _site = RegExp(
  r'^(?:https?://\S+|(?:www\.)?[a-z0-9-]+(?:\.[a-z0-9-]+)*\.[a-z]{2,}(?:[/:]\S*)?)$',
  caseSensitive: false,
);
final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[a-z]{2,}$', caseSensitive: false);
final _user = RegExp(r'^[\p{L}\p{N}._+@-]{2,64}$', unicode: true);

/// Something that looks like a password: no spaces, at least two kinds of characters.
bool looksLikePassword(String v) {
  if (v.length < 6 || v.length > 128 || RegExp(r'\s').hasMatch(v)) return false;
  if (_site.hasMatch(v) || _email.hasMatch(v)) return false;
  if (RegExp(r'^[\d.,:/+-]+(?:ms|s|kb|mb|gb|%)?$', caseSensitive: false).hasMatch(v)) return false;
  final kinds = [
    RegExp('[a-z]'),
    RegExp('[A-Z]'),
    RegExp(r'\d'),
    RegExp('[^A-Za-z0-9]'),
  ].where((r) => r.hasMatch(v)).length;
  return kinds >= 2;
}

bool _listLine(String line) {
  final t = line.trim();
  if (t.length < 8 || t.length > 400) return false;
  final strong = RegExp(r'[\t;|,]').hasMatch(t);
  final parts = t
      .split(strong ? RegExp(r'\s*[\t;|,]\s*') : RegExp(r'\s+'))
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length < 3 || parts.length > 4) return false;
  final value = parts.last;
  final user = parts[parts.length - 2];
  final where = parts.sublist(0, parts.length - 2);
  final site = where.firstWhere(_site.hasMatch, orElse: () => '');
  if (!_user.hasMatch(user) || RegExp(r'^\d+$').hasMatch(user) || _site.hasMatch(value)) {
    return false;
  }
  if (site.isNotEmpty) {
    if (value.length < 4 ||
        RegExp(r'^\d{1,3}$').hasMatch(value) ||
        RegExp(r'^[\d.,:]+$').hasMatch(value)) {
      return false;
    }
    if (!looksLikePassword(value) && !(_email.hasMatch(user) || strong)) return false;
  } else if (!strong || !looksLikePassword(value)) {
    return false;
  }
  return true;
}

List<PasswordExportSpan> _readLists(String s) {
  final out = <PasswordExportSpan>[];
  int? start;
  var end = 0;
  var rows = 0;
  var others = 0;
  void close() {
    if (start != null && rows >= 3 && rows >= others * 2) {
      out.add(PasswordExportSpan('list', start!, end, rows));
    }
    start = null;
    rows = 0;
    others = 0;
  }

  var at = 0;
  while (at <= s.length) {
    final nl = s.indexOf('\n', at);
    final lineEnd = nl < 0 ? s.length : nl;
    var line = s.substring(at, lineEnd);
    if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
    if (_listLine(line)) {
      start ??= at;
      rows++;
      end = at + line.length;
    } else if (start != null && line.trim().isEmpty) {
      close();
    } else if (start != null) {
      others++;
      if (others > rows) close();
    }
    if (nl < 0) break;
    at = nl + 1;
  }
  close();
  return out;
}

/// Where the password exports are in a text, and how many passwords each holds.
List<PasswordExportSpan> findPasswordExports(String text) {
  if (text.length < 20) return const [];
  final found = <PasswordExportSpan>[];
  bool taken(int a, int b) => found.any((f) => a < f.end && f.start < b);
  found.addAll(_readCsv(text));
  final json = _readJson(text);
  if (json != null && !taken(json.start, json.end)) found.add(json);
  final xml = _readXml(text);
  if (xml != null && !taken(xml.start, xml.end)) found.add(xml);
  for (final l in _readLists(text)) {
    if (!taken(l.start, l.end)) found.add(l);
  }
  found.sort((a, b) => a.start - b.start);
  return found;
}

/// How many passwords the exports in a text hold (0: none).
int passwordExportRows(String text) => findPasswordExports(text).fold(0, (n, e) => n + e.rows);

/// The text with every export replaced by [mark] (the words around it stay).
String withoutPasswordExports(String text, [String mark = '[password export removed]']) {
  var out = text;
  for (final f in findPasswordExports(text).reversed) {
    out = '${out.substring(0, f.start)}$mark${out.substring(f.end)}';
  }
  return out;
}
