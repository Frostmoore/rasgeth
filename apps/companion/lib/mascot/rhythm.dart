// The mascots' rhythm and their irregular rare events, ported from `@redgiant/mascot`
// (`rhythmOf`, `rareStarts` in packages/mascot/src): the same 32-bit integers, checked against the
// library's numbers in test/fixtures/motion_vectors.json.
//
// The rhythm comes in the server's SVG (`--k0`…`--k15`); an older server sends none, and then the
// app makes it from the seed itself, so mascots never all move with the same zero.

const _m32 = 0xFFFFFFFF;

/// `Math.imul`: the low 32 bits of the product, as an unsigned number.
int imul32(int a, int b) {
  a &= _m32;
  b &= _m32;
  final lo = (a & 0xFFFF) * b;
  final hi = ((a >> 16) * b) & 0xFFFF;
  return (lo + (hi << 16)) & _m32;
}

/// The board's hash of the seed (cyrb128's last word, UTF-16 code units).
int seedHash(String str) {
  var h1 = 1779033703, h2 = 3144134277, h3 = 1013904242, h4 = 2773480762;
  for (final k in str.codeUnits) {
    h1 = h2 ^ imul32(h1 ^ k, 597399067);
    h2 = h3 ^ imul32(h2 ^ k, 2869860233);
    h3 = h4 ^ imul32(h3 ^ k, 951274213);
    h4 = h1 ^ imul32(h4 ^ k, 2716044179);
  }
  h1 = imul32(h3 ^ (h1 >> 18), 597399067);
  h2 = imul32(h4 ^ (h2 >> 22), 2869860233);
  h3 = imul32(h1 ^ (h3 >> 17), 951274213);
  h4 = imul32(h2 ^ (h4 >> 19), 2716044179);
  return (h1 ^ h2 ^ h3 ^ h4) & _m32;
}

/// mulberry32 seeded by [seedHash].
double Function() seededRandom(String seed) {
  var a = seedHash(seed);
  return () {
    a = (a + 0x6d2b79f5) & _m32;
    var t = imul32(a ^ (a >> 15), 1 | a);
    t = ((t + imul32(t ^ (t >> 7), 61 | t)) & _m32) ^ t;
    return ((t ^ (t >> 14)) & _m32) / 4294967296;
  };
}

/// A seed's sixteen rhythm numbers (the library's `rhythmOf`).
List<double> rhythmOf(String seed) {
  final r = seededRandom('$seed\u0000motion');
  return List<double>.generate(16, (_) => (r() * 1000).round() / 1000);
}

/// The library's `mix32` (lowbias32).
int mix32(int x) {
  var h = x & _m32;
  h = imul32(h ^ (h >> 16), 0x7feb352d);
  h = imul32(h ^ (h >> 15), 0x846ca68b);
  return (h ^ (h >> 16)) & _m32;
}

int _nameHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = imul32(h ^ c, 0x01000193);
  }
  return h;
}

/// JavaScript's `Math.round` (halves go up, also below zero).
int _jsRound(double v) => (v + 0.5).floor();

int _rareBase(String ev, List<double> k) {
  var h = _nameHash(ev);
  for (final v in k) {
    h = mix32(h ^ (_jsRound(v * 1000) & _m32));
  }
  return h;
}

double _unit(int base, int n) => mix32(base + imul32(n, 0x9e3779b9)) / 4294967296;

double _r4(double n) => _jsRound(n * 10000) / 10000;

/// When a rare event of gap [g0]..[g1] seconds starts, between [from] and [to], for a mascot of
/// rhythm [k] (phase number [pk]): the library's `rareStarts`.
List<double> rareStarts(
  String ev,
  double g0,
  double g1,
  int? pk,
  List<double> k,
  double from,
  double to,
) {
  final p = (g0 + g1) / 2;
  final j = (g1 - g0) / 2;
  final shift = (pk != null && pk < k.length ? k[pk] : 0) * p;
  final base = _rareBase(ev, k);
  final out = <double>[];
  for (var n = ((from + shift) / p).floor() - 1; n * p - shift < to; n++) {
    final s = n * p + _unit(base, n) * j - shift;
    if (s >= from && s < to) out.add(_r4(s));
  }
  return out;
}
