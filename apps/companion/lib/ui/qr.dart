// A QR code drawn here (G42.14, row 279): the page's `Qr` (ui.tsx) draws it with
// qrcode-generator (MIT, Kazuhiko Arase) at level M, the smallest version that holds the text, in
// byte mode; this is the same algorithm in Dart, mask choice included, so the app draws the very
// same squares (test/system_vectors_test.dart checks it against the library's own matrices,
// tool/system_vectors.mjs). Versions 1-20 (up to 666 bytes): addresses and authenticator links.
import 'dart:convert';

import 'package:flutter/material.dart';

/// Level M's blocks per version: (count, total codewords, data codewords), repeated.
const _blocksM = <List<int>>[
  [1, 26, 16],
  [1, 44, 28],
  [1, 70, 44],
  [2, 50, 32],
  [2, 67, 43],
  [4, 43, 27],
  [4, 49, 31],
  [2, 60, 38, 2, 61, 39],
  [3, 58, 36, 2, 59, 37],
  [4, 69, 43, 1, 70, 44],
  [1, 80, 50, 4, 81, 51],
  [6, 58, 36, 2, 59, 37],
  [8, 59, 37, 1, 60, 38],
  [4, 64, 40, 5, 65, 41],
  [5, 65, 41, 5, 66, 42],
  [7, 73, 45, 3, 74, 46],
  [10, 74, 46, 1, 75, 47],
  [9, 69, 43, 4, 70, 44],
  [3, 70, 44, 11, 71, 45],
  [3, 67, 41, 13, 68, 42],
];

const _align = <List<int>>[
  [],
  [6, 18],
  [6, 22],
  [6, 26],
  [6, 30],
  [6, 34],
  [6, 22, 38],
  [6, 24, 42],
  [6, 26, 46],
  [6, 28, 50],
  [6, 30, 54],
  [6, 32, 58],
  [6, 34, 62],
  [6, 26, 46, 66],
  [6, 26, 48, 70],
  [6, 26, 50, 74],
  [6, 30, 54, 78],
  [6, 30, 56, 82],
  [6, 30, 58, 86],
  [6, 34, 62, 90],
];

// GF(256) with 0x11d, as the library's QRMath.
final _exp = List<int>.filled(256, 0);
final _log = List<int>.filled(256, 0);
bool _tables = false;

void _initTables() {
  if (_tables) return;
  for (var i = 0; i < 8; i++) {
    _exp[i] = 1 << i;
  }
  for (var i = 8; i < 256; i++) {
    _exp[i] = _exp[i - 4] ^ _exp[i - 5] ^ _exp[i - 6] ^ _exp[i - 8];
  }
  for (var i = 0; i < 255; i++) {
    _log[_exp[i]] = i;
  }
  _tables = true;
}

int _gexp(int n) => _exp[((n % 255) + 255) % 255];

/// The error correction codewords of [data] ([ec] of them): the remainder of the division by
/// the generator polynomial.
List<int> _ecBytes(List<int> data, int ec) {
  // The generator: (x - a^0)(x - a^1)…(x - a^(ec-1)), highest power first.
  var gen = <int>[1];
  for (var i = 0; i < ec; i++) {
    final next = List<int>.filled(gen.length + 1, 0);
    for (var j = 0; j < gen.length; j++) {
      next[j] ^= gen[j];
      if (gen[j] != 0) next[j + 1] ^= _gexp(_log[gen[j]] + i);
    }
    gen = next;
  }
  final rem = [...data, ...List<int>.filled(ec, 0)];
  for (var i = 0; i < data.length; i++) {
    final coef = rem[i];
    if (coef == 0) continue;
    final lc = _log[coef];
    for (var j = 0; j < gen.length; j++) {
      if (gen[j] != 0) rem[i + j] ^= _gexp(_log[gen[j]] + lc);
    }
  }
  return rem.sublist(data.length);
}

int _digit(int d) {
  var n = 0;
  while (d != 0) {
    n++;
    d >>>= 1;
  }
  return n;
}

int _bchType(int data) {
  const g15 = 0x537, mask = 0x5412;
  var d = data << 10;
  while (_digit(d) - _digit(g15) >= 0) {
    d ^= g15 << (_digit(d) - _digit(g15));
  }
  return ((data << 10) | d) ^ mask;
}

int _bchVersion(int data) {
  const g18 = 0x1f25;
  var d = data << 12;
  while (_digit(d) - _digit(g18) >= 0) {
    d ^= g18 << (_digit(d) - _digit(g18));
  }
  return (data << 12) | d;
}

bool _mask(int p, int i, int j) => switch (p) {
  0 => (i + j) % 2 == 0,
  1 => i % 2 == 0,
  2 => j % 3 == 0,
  3 => (i + j) % 3 == 0,
  4 => ((i ~/ 2) + (j ~/ 3)) % 2 == 0,
  5 => (i * j) % 2 + (i * j) % 3 == 0,
  6 => ((i * j) % 2 + (i * j) % 3) % 2 == 0,
  _ => ((i * j) % 3 + (i + j) % 2) % 2 == 0,
};

class _Bits {
  final bytes = <int>[];
  int length = 0;

  void put(int n, int len) {
    for (var i = 0; i < len; i++) {
      bit(((n >>> (len - i - 1)) & 1) == 1);
    }
  }

  void bit(bool on) {
    final at = length ~/ 8;
    if (bytes.length <= at) bytes.add(0);
    if (on) bytes[at] |= 0x80 >>> (length % 8);
    length++;
  }
}

/// The squares of [text]'s QR code, by row then column (true: dark); null when it does not fit.
List<List<bool>>? qrModules(String text) {
  _initTables();
  final data = utf8.encode(text);
  for (var v = 1; v <= _blocksM.length; v++) {
    final blocks = <(int, int)>[];
    final t = _blocksM[v - 1];
    for (var i = 0; i < t.length; i += 3) {
      for (var k = 0; k < t[i]; k++) {
        blocks.add((t[i + 1], t[i + 2]));
      }
    }
    final dataCount = blocks.fold(0, (n, b) => n + b.$2);
    final lenBits = v < 10 ? 8 : 16;
    if (4 + lenBits + data.length * 8 > dataCount * 8) continue;
    final bits = _Bits()
      ..put(4, 4)
      ..put(data.length, lenBits);
    for (final b in data) {
      bits.put(b, 8);
    }
    if (bits.length + 4 <= dataCount * 8) bits.put(0, 4);
    while (bits.length % 8 != 0) {
      bits.bit(false);
    }
    while (bits.length < dataCount * 8) {
      bits.put(0xEC, 8);
      if (bits.length >= dataCount * 8) break;
      bits.put(0x11, 8);
    }
    // Every block's data and its error correction, interleaved.
    final dc = <List<int>>[], ec = <List<int>>[];
    var offset = 0;
    for (final (total, count) in blocks) {
      final d = bits.bytes.sublist(offset, offset + count);
      offset += count;
      dc.add(d);
      ec.add(_ecBytes(d, total - count));
    }
    final code = <int>[];
    for (final list in [dc, ec]) {
      final most = list.fold(0, (n, b) => b.length > n ? b.length : n);
      for (var i = 0; i < most; i++) {
        for (final b in list) {
          if (i < b.length) code.add(b[i]);
        }
      }
    }
    var best = 0;
    double? lowest;
    for (var p = 0; p < 8; p++) {
      final lost = _lostPoint(_make(v, code, p, true));
      if (lowest == null || lowest > lost) {
        lowest = lost;
        best = p;
      }
    }
    return [
      for (final row in _make(v, code, best, false)) [for (final m in row) m ?? false],
    ];
  }
  return null;
}

List<List<bool?>> _make(int v, List<int> code, int maskPattern, bool test) {
  final n = v * 4 + 17;
  final m = List.generate(n, (_) => List<bool?>.filled(n, null));
  void probe(int row, int col) {
    for (var r = -1; r <= 7; r++) {
      if (row + r < 0 || n <= row + r) continue;
      for (var c = -1; c <= 7; c++) {
        if (col + c < 0 || n <= col + c) continue;
        m[row + r][col + c] =
            (0 <= r && r <= 6 && (c == 0 || c == 6)) ||
            (0 <= c && c <= 6 && (r == 0 || r == 6)) ||
            (2 <= r && r <= 4 && 2 <= c && c <= 4);
      }
    }
  }

  probe(0, 0);
  probe(n - 7, 0);
  probe(0, n - 7);
  final pos = _align[v - 1];
  for (final row in pos) {
    for (final col in pos) {
      if (m[row][col] != null) continue;
      for (var r = -2; r <= 2; r++) {
        for (var c = -2; c <= 2; c++) {
          m[row + r][col + c] = r == -2 || r == 2 || c == -2 || c == 2 || (r == 0 && c == 0);
        }
      }
    }
  }
  for (var r = 8; r < n - 8; r++) {
    if (m[r][6] != null) continue;
    m[r][6] = r % 2 == 0;
  }
  for (var c = 8; c < n - 8; c++) {
    if (m[6][c] != null) continue;
    m[6][c] = c % 2 == 0;
  }
  // Level M is 0 in the format bits.
  final type = _bchType(maskPattern);
  for (var i = 0; i < 15; i++) {
    final on = !test && ((type >> i) & 1) == 1;
    if (i < 6) {
      m[i][8] = on;
    } else if (i < 8) {
      m[i + 1][8] = on;
    } else {
      m[n - 15 + i][8] = on;
    }
  }
  for (var i = 0; i < 15; i++) {
    final on = !test && ((type >> i) & 1) == 1;
    if (i < 8) {
      m[8][n - i - 1] = on;
    } else if (i < 9) {
      m[8][15 - i - 1 + 1] = on;
    } else {
      m[8][15 - i - 1] = on;
    }
  }
  m[n - 8][8] = !test;
  if (v >= 7) {
    final bits = _bchVersion(v);
    for (var i = 0; i < 18; i++) {
      final on = !test && ((bits >> i) & 1) == 1;
      m[i ~/ 3][i % 3 + n - 8 - 3] = on;
      m[i % 3 + n - 8 - 3][i ~/ 3] = on;
    }
  }
  var inc = -1, row = n - 1, bitIndex = 7, byteIndex = 0;
  for (var col = n - 1; col > 0; col -= 2) {
    if (col == 6) col -= 1;
    while (true) {
      for (var c = 0; c < 2; c++) {
        if (m[row][col - c] == null) {
          var dark = false;
          if (byteIndex < code.length) dark = ((code[byteIndex] >>> bitIndex) & 1) == 1;
          if (_mask(maskPattern, row, col - c)) dark = !dark;
          m[row][col - c] = dark;
          bitIndex--;
          if (bitIndex == -1) {
            byteIndex++;
            bitIndex = 7;
          }
        }
      }
      row += inc;
      if (row < 0 || n <= row) {
        row -= inc;
        inc = -inc;
        break;
      }
    }
  }
  return m;
}

/// The library's penalty (its own weights), so the same mask wins.
double _lostPoint(List<List<bool?>> m) {
  final n = m.length;
  bool d(int r, int c) => m[r][c] ?? false;
  var lost = 0.0;
  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n; col++) {
      var same = 0;
      final dark = d(row, col);
      for (var r = -1; r <= 1; r++) {
        if (row + r < 0 || n <= row + r) continue;
        for (var c = -1; c <= 1; c++) {
          if (col + c < 0 || n <= col + c) continue;
          if (r == 0 && c == 0) continue;
          if (dark == d(row + r, col + c)) same++;
        }
      }
      if (same > 5) lost += 3 + same - 5;
    }
  }
  for (var row = 0; row < n - 1; row++) {
    for (var col = 0; col < n - 1; col++) {
      var count = 0;
      if (d(row, col)) count++;
      if (d(row + 1, col)) count++;
      if (d(row, col + 1)) count++;
      if (d(row + 1, col + 1)) count++;
      if (count == 0 || count == 4) lost += 3;
    }
  }
  bool finder(bool Function(int) at) =>
      at(0) && !at(1) && at(2) && at(3) && at(4) && !at(5) && at(6);
  for (var row = 0; row < n; row++) {
    for (var col = 0; col < n - 6; col++) {
      if (finder((k) => d(row, col + k))) lost += 40;
    }
  }
  for (var col = 0; col < n; col++) {
    for (var row = 0; row < n - 6; row++) {
      if (finder((k) => d(row + k, col))) lost += 40;
    }
  }
  var dark = 0;
  for (final r in m) {
    for (final x in r) {
      if (x ?? false) dark++;
    }
  }
  final ratio = (100 * dark / n / n - 50).abs() / 5;
  return lost + ratio * 10;
}

/// The QR code of [text] on white with its quiet margin (the page's `Qr`: cell 5, margin 2).
class QrCode extends StatelessWidget {
  const QrCode({super.key, required this.text, required this.label, this.size = 168});

  final String text;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final m = qrModules(text);
    return Semantics(
      image: true,
      label: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: m == null ? null : CustomPaint(painter: _QrPainter(m)),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.m);

  final List<List<bool>> m;

  @override
  void paint(Canvas canvas, Size size) {
    final cells = m.length + 4;
    final cell = size.width / cells;
    final p = Paint()..color = Colors.black;
    for (var r = 0; r < m.length; r++) {
      for (var c = 0; c < m.length; c++) {
        if (m[r][c]) {
          // A hair larger, so no seam shows between two dark squares.
          canvas.drawRect(Rect.fromLTWH((c + 2) * cell, (r + 2) * cell, cell + .4, cell + .4), p);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.m != m;
}
