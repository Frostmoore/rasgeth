// Recognising secrets in what people write (G42.1), a faithful port of
// packages/protocol/src/secrets.ts (`SECRET_PATTERNS`, `findSecrets`, `hideSecrets`, `hasSecret`):
// the server, every chat, the page and the app use one recogniser. Only real secrets count: values
// that look like keys, valid card numbers and IBANs, and a password or a PIN only when its value is
// there. Positions are UTF-16 code units, as in JavaScript (Dart strings are UTF-16 too).
// test/g42_1_secrets_test.dart checks the port against vectors made by the protocol's own code
// (tool/secrets_vectors.mjs): change the TypeScript first, then regenerate them.

/// One well-known key format; the event log's Redactor uses the same list.
class SecretPattern {
  const SecretPattern(this.name, this.re);

  final String name;
  final RegExp re;
}

/// Well-known key formats (the protocol's `SECRET_PATTERNS`, same names, same order).
final List<SecretPattern> secretPatterns = List.unmodifiable([
  SecretPattern(
    'private-key',
    RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----'),
  ),
  // A key starts a word and has digits: "elon-musk-s-2026-political-..." in a URL is not one.
  SecretPattern('anthropic-key', RegExp(r'\bsk-ant-(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{20,}')),
  SecretPattern('openai-key', RegExp(r'\bsk-(?:proj-)?(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{20,}')),
  SecretPattern(
    'github-token',
    RegExp(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})'),
  ),
  SecretPattern('huggingface-token', RegExp(r'\bhf_[A-Za-z0-9]{30,}')),
  SecretPattern('aws-access-key', RegExp(r'\bAKIA[0-9A-Z]{16}\b')),
  SecretPattern('google-api-key', RegExp(r'\bAIza[0-9A-Za-z_-]{35}\b')),
  SecretPattern('slack-token', RegExp(r'\bxox[abprs]-[A-Za-z0-9-]{10,}')),
  SecretPattern('telegram-bot-token', RegExp(r'\b\d{8,10}:[A-Za-z0-9_-]{35}\b')),
  SecretPattern('bearer', RegExp(r'(?<=\bBearer\s+)[A-Za-z0-9._~+/-]{20,}=*')),
]);

/// Words that describe a password rather than being one: «la password è lunga».
final Set<String> _notAValue =
    ('lunga corta sicura forte debole semplice facile difficile complicata comoda scaduta cambiata '
            'nuova vecchia salvata segreta giusta sbagliata uguale diversa sempre ancora stata nel nella '
            'sul sulla in un una il lo la le gli i di da per con che non '
            'long short strong weak secure safe simple easy hard complex expired changed new old saved '
            'secret right wrong same different always still in on the a an my your not stored kept')
        .split(' ')
        .toSet();

/// "password: X", "la password del wifi è X", "my password is X": the keyword, then its value.
final _password = RegExp(
  r'''\b(?:password|passwd|pwd|passcode|passphrase|parola d'ordine)(?:\s+(?:del|della|dello|dell'|di|of|for|per|to|on|su|sul|sulla|al|alla|mio|mia|my)\s+[^\s:=]+){0,2}\s*(?:[:=]\s*|\s(?:is|è|e'|era|sarebbe|vale|=)\s+)["'«]?([^\s"'»,;.]{3,})''',
  caseSensitive: false,
  unicode: true,
);

/// "PIN 1234", "il mio PIN è 12345", "CVV: 123": the number is there.
final _code = RegExp(
  r'\b(?:pin|puk|otp|cvv|cvc|codice segreto|codice pin)\b[^\d\n]{0,12}(\d{3,8})\b',
  caseSensitive: false,
  unicode: true,
);

/// "token: ...", "api key sk...", "chiave api = ...": a long value with letters and digits.
final _key = RegExp(
  r'''\b(?:api[ _-]?key|token|secret|chiave(?: api| segreta)?|access key)\s*(?:[:=]|\s(?:is|è)\s)?\s*["'«]?([A-Za-z0-9_\-./+]{16,})''',
  caseSensitive: false,
  unicode: true,
);

/// JSON web tokens, and long random strings with lower case, upper case and digits mixed.
final _random = [
  RegExp(r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*'),
  RegExp(
    r'\b(?=[A-Za-z0-9+/_-]*\d)(?=[A-Za-z0-9+/_-]*[a-z])(?=[A-Za-z0-9+/_-]*[A-Z])[A-Za-z0-9+/_-]{24,}\b',
  ),
];

final _card = RegExp(r'\b\d(?:[ -]?\d){12,18}\b');
final _iban = RegExp(
  r'\b[A-Z]{2}\d{2}(?:\s?[A-Z0-9]{4}){2,7}(?:\s?[A-Z0-9]{1,4})?\b',
  caseSensitive: false,
);
final _digit = RegExp(r'\d');

bool _luhn(String digits) {
  var sum = 0;
  for (var i = 0; i < digits.length; i++) {
    var d = digits.codeUnitAt(digits.length - 1 - i) - 0x30;
    if (i % 2 == 1) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
  }
  return sum % 10 == 0;
}

bool _ibanValid(String raw) {
  final s = raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  if (s.length < 15 || s.length > 34) return false;
  final moved = s.substring(4) + s.substring(0, 4);
  var rest = 0;
  for (final ch in moved.split('')) {
    final c = ch.codeUnitAt(0);
    final v = c >= 0x41 && c <= 0x5A ? '${c - 55}' : ch;
    for (final d in v.split('')) {
      // JavaScript's Number(d) of a non-digit is NaN and poisons the rest: never valid then.
      final n = int.tryParse(d);
      if (n == null) return false;
      rest = (rest * 10 + n) % 97;
    }
  }
  return rest == 1;
}

/// The kinds of secret (the protocol's `SecretSpan["kind"]`).
enum SecretKind { key, password, code, card, iban }

/// One secret found in a text: where its value is, what kind, and the value itself.
class SecretSpan {
  const SecretSpan({
    required this.start,
    required this.end,
    required this.kind,
    required this.value,
  });

  /// [start, end) of the value only, in UTF-16 code units: «password: hunter2» spans «hunter2».
  final int start;
  final int end;
  final SecretKind kind;
  final String value;

  Map<String, Object> toJson() => {'start': start, 'end': end, 'kind': kind.name, 'value': value};

  @override
  bool operator ==(Object other) =>
      other is SecretSpan &&
      other.start == start &&
      other.end == end &&
      other.kind == kind &&
      other.value == value;

  @override
  int get hashCode => Object.hash(start, end, kind, value);

  @override
  String toString() => 'SecretSpan($start, $end, ${kind.name}, $value)';
}

class _Span {
  _Span(this.start, this.end, this.kind);

  final int start;
  int end;
  final SecretKind kind;
}

/// Where the secrets are in a text, sorted and merged when they overlap.
List<SecretSpan> findSecrets(String text) {
  final out = <_Span>[];
  void add(RegExpMatch m, SecretKind kind, [String? value]) {
    final whole = m[0]!;
    final v = value ?? whole;
    final i = whole.lastIndexOf(v);
    final at = m.start + (i < 0 ? 0 : i);
    out.add(_Span(at, at + v.length, kind));
  }

  for (final p in secretPatterns) {
    for (final m in p.re.allMatches(text)) add(m, SecretKind.key);
  }
  for (final m in _password.allMatches(text)) {
    final v = m[1];
    if (v != null && v.isNotEmpty && !_notAValue.contains(v.toLowerCase())) {
      add(m, SecretKind.password, v);
    }
  }
  for (final m in _code.allMatches(text)) {
    final v = m[1];
    if (v != null && v.isNotEmpty) add(m, SecretKind.code, v);
  }
  for (final m in _key.allMatches(text)) {
    final v = m[1];
    if (v != null && v.isNotEmpty && _digit.hasMatch(v)) add(m, SecretKind.key, v);
  }
  for (final re in _random) {
    for (final m in re.allMatches(text)) add(m, SecretKind.key);
  }
  for (final m in _card.allMatches(text)) {
    if (_luhn(m[0]!.replaceAll(RegExp(r'\D'), ''))) add(m, SecretKind.card);
  }
  for (final m in _iban.allMatches(text)) {
    if (_ibanValid(m[0]!)) add(m, SecretKind.iban);
  }
  // A stable sort, as JavaScript's.
  final indexed = [for (var i = 0; i < out.length; i++) (i, out[i])];
  indexed.sort((a, b) {
    final byStart = a.$2.start - b.$2.start;
    if (byStart != 0) return byStart;
    final byEnd = b.$2.end - a.$2.end;
    if (byEnd != 0) return byEnd;
    return a.$1 - b.$1;
  });
  final merged = <_Span>[];
  for (final (_, s) in indexed) {
    final last = merged.isEmpty ? null : merged.last;
    if (last != null && s.start < last.end) {
      if (s.end > last.end) last.end = s.end;
    } else {
      merged.add(_Span(s.start, s.end, s.kind));
    }
  }
  return [
    for (final s in merged)
      SecretSpan(start: s.start, end: s.end, kind: s.kind, value: text.substring(s.start, s.end)),
  ];
}

/// True when the text holds a secret.
bool hasSecret(String text) => findSecrets(text).isNotEmpty;

/// The text with each secret's value replaced by [mark] (the words around it stay).
({String text, List<SecretSpan> found}) hideSecrets(String text, [String mark = '[secret]']) {
  final found = findSecrets(text);
  var out = text;
  for (final s in found.reversed) {
    out = '${out.substring(0, s.start)}$mark${out.substring(s.end)}';
  }
  return (text: out, found: found);
}
