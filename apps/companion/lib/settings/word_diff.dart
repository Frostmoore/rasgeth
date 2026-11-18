// The before and after of a text, word by word (G42.4), as the page's word-diff.ts for the
// instructions' refiner: a longest common subsequence over words, punctuation and spaces, line by
// line when the texts are too long. Its answers are checked against the page's own
// (test/fixtures/word_diff_vectors.json, tool/general_words.mjs).
import 'dart:typed_data';

enum DiffKind { same, del, add }

class DiffPart {
  DiffPart(this.kind, this.text);

  final DiffKind kind;
  String text;
}

final _words = RegExp(r"\s+|[\p{L}\p{N}_{}']+|[^\p{L}\p{N}_{}'\s]", unicode: true);
final _lines = RegExp(r'[^\n]*\n|[^\n]+$');

/// Above this many cells the table would be slow on a phone: lines instead of words.
const _maxCells = 3000000;

List<String> _split(RegExp re, String s) => [for (final m in re.allMatches(s)) m[0]!];

List<DiffPart> _lcs(List<String> a, List<String> b) {
  var start = 0;
  while (start < a.length && start < b.length && a[start] == b[start]) {
    start++;
  }
  var end = 0;
  while (end < a.length - start &&
      end < b.length - start &&
      a[a.length - 1 - end] == b[b.length - 1 - end]) {
    end++;
  }
  final x = a.sublist(start, a.length - end);
  final y = b.sublist(start, b.length - end);
  final n = x.length;
  final m = y.length;
  final table = Uint32List((n + 1) * (m + 1));
  int at(int i, int j) => i * (m + 1) + j;
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      table[at(i, j)] = x[i] == y[j]
          ? table[at(i + 1, j + 1)] + 1
          : (table[at(i + 1, j)] > table[at(i, j + 1)] ? table[at(i + 1, j)] : table[at(i, j + 1)]);
    }
  }
  final out = <DiffPart>[];
  void push(DiffKind kind, String text) {
    if (out.isNotEmpty && out.last.kind == kind) {
      out.last.text += text;
    } else {
      out.add(DiffPart(kind, text));
    }
  }

  if (start > 0) push(DiffKind.same, a.sublist(0, start).join());
  var i = 0;
  var j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && x[i] == y[j]) {
      push(DiffKind.same, x[i]);
      i++;
      j++;
    } else if (j < m && (i == n || table[at(i, j + 1)] >= table[at(i + 1, j)])) {
      push(DiffKind.add, y[j]);
      j++;
    } else {
      push(DiffKind.del, x[i]);
      i++;
    }
  }
  if (end > 0) push(DiffKind.same, a.sublist(a.length - end).join());
  return out;
}

/// The parts of [before] and [after], in order; `del` only in the before, `add` only in the after.
List<DiffPart> wordDiff(String before, String after) {
  final a = _split(_words, before);
  final b = _split(_words, after);
  if (a.length * b.length <= _maxCells) return _lcs(a, b);
  return _lcs(_split(_lines, before), _split(_lines, after));
}

final _nonSpace = RegExp(r'\S+');

/// How many words went and came.
({int del, int add}) diffCounts(List<DiffPart> parts) {
  int count(DiffKind k) =>
      parts.where((p) => p.kind == k).fold(0, (n, p) => n + _nonSpace.allMatches(p.text).length);
  return (del: count(DiffKind.del), add: count(DiffKind.add));
}
