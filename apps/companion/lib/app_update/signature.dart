// The signed list of the app's packages (G41.8b): `SHA256SUMS-companion` and its `.sig`, made by
// release.yml with packaging/update/sign.mjs (RSA, SHA-256, PKCS #1 v1.5, base64), the same check
// as the Windows launcher's `Delta.SignatureValid` and the server's release.json. The list is read
// only after its signature is valid; a package is used only when its sha256 is the listed one.
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// The public half of the update key, as packaging/windows/launcher/UpdateKey.cs holds it (.NET's
/// RSAKeyValue: modulus and exponent, base64). sign.mjs and the tests check that the three copies
/// (this one, UpdateKey.cs, packages/server/src/release-key.ts) are the same key.
const kUpdateKeyModulus =
    'mpVtgHyQOGFUMbOO+pc6sZqcebFuyJ6MiEl4JT0dkiKS4dSY356lpcq7n2eGV97Ev1XcS0ulj9tD4NI+QjXnd19l6kZ1CALz'
    '9SDpFtUJXQ+iXgOFepiBosdQM4IIANA8k073TNR0LciY33sOGlCMxL1yKiJBf4j9pJpbrmGJf+7p/SMXnnx+LNz4gHAVn3lO'
    'oedcOU/8/Z3zsOuQE4nH7ySI+fFwQ4iW4hqXmPXCNNVQPCU3N7S39xgzh2v5GdlKcBP00X0WD96NS1l4iapUUGNukMPo5YN1'
    'Ihp5FC4wjTcMqMWDI9bNDUoLP9vEekMqNNEWMUEsXamDH4Cm3QDlWHFR98PmrQZZPX8Rwzbz8c+2riP1O6K7zL9zGLboxwFp'
    'dMVFilx7ggYZDx+7R93qOWg1a3mqCKuTEZlCCDgbR8Inyi4uCsjTjtUF5wpL+38ApRXIJt3hVuVcu3IukFjisGbARheBFA8d'
    'RhrLDaHF1s1KhV1e4MW3cGIDZusf8WTH';
const kUpdateKeyExponent = 'AQAB';

class UpdateKey {
  const UpdateKey(this.modulus, this.exponent);

  /// Base64, big-endian, as in .NET's XML.
  final String modulus;
  final String exponent;

  static const builtIn = UpdateKey(kUpdateKeyModulus, kUpdateKeyExponent);

  RSAPublicKey toRsa() => RSAPublicKey(_big(base64.decode(modulus)), _big(base64.decode(exponent)));
}

BigInt _big(List<int> bytes) {
  var r = BigInt.zero;
  for (final b in bytes) {
    r = (r << 8) | BigInt.from(b);
  }
  return r;
}

/// True when [signature] (the `.sig` file: base64, a newline at its end) is [data] signed with the
/// private half of [key]. Never throws: anything that is not a valid signature is false.
bool signatureValid(List<int> data, String signature, {UpdateKey key = UpdateKey.builtIn}) {
  final Uint8List sig;
  try {
    sig = base64.decode(signature.trim());
  } on FormatException {
    return false;
  }
  if (sig.isEmpty || sig.length > 1024 || key.modulus.isEmpty) return false;
  try {
    // DigestInfo's prefix for SHA-256 (PKCS #1 v1.5), as RSA-SHA256 everywhere else.
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201')
      ..init(false, PublicKeyParameter<RSAPublicKey>(key.toRsa()));
    return signer.verifySignature(Uint8List.fromList(data), RSASignature(sig));
  } on Object {
    return false;
  }
}

/// `sha256sum`'s lines (`<64 hex>  <name>`, or `<hex> *<name>`) as name → hex, lower case. Null
/// when a line is not one (a list someone edited by hand is not trusted half).
Map<String, String>? parseSums(String text) {
  final out = <String, String>{};
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trimRight();
    if (line.isEmpty) continue;
    final m = RegExp(r'^([0-9a-fA-F]{64}) [ *](\S.*)$').firstMatch(line);
    if (m == null) return null;
    final name = m.group(2)!;
    if (name.contains('/') || name.contains(r'\') || name.startsWith('.')) return null;
    if (out.containsKey(name)) return null;
    out[name] = m.group(1)!.toLowerCase();
  }
  return out.isEmpty ? null : out;
}

/// The sums of a release, read only through a valid signature (null otherwise).
Map<String, String>? signedSums(List<int> sums, String signature, {UpdateKey? key}) {
  if (!signatureValid(sums, signature, key: key ?? UpdateKey.builtIn)) return null;
  try {
    return parseSums(utf8.decode(sums));
  } on FormatException {
    return null;
  }
}

/// A sha256 fed as the bytes arrive.
class Sha256Sink {
  final _d = SHA256Digest();

  void add(List<int> chunk) {
    final b = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
    _d.update(b, 0, b.length);
  }

  String close() {
    final out = Uint8List(_d.digestSize);
    _d.doFinal(out, 0);
    return [for (final b in out) b.toRadixString(16).padLeft(2, '0')].join();
  }
}
