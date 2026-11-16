// A small highlighter for the advanced interface's viewer and diff (G40.11): comments, strings,
// numbers and the keywords of the usual languages, coloured with the theme. Not a parser: a
// line at a time, enough to read code on a phone.
import 'package:flutter/painting.dart';

import '../theme/colors.dart';

const _keywords = {
  'abstract',
  'as',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'def',
  'default',
  'del',
  'do',
  'elif',
  'else',
  'enum',
  'export',
  'extends',
  'false',
  'final',
  'finally',
  'fn',
  'for',
  'from',
  'func',
  'function',
  'if',
  'impl',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'lambda',
  'let',
  'match',
  'mut',
  'new',
  'nil',
  'None',
  'not',
  'null',
  'or',
  'and',
  'package',
  'pass',
  'private',
  'protected',
  'pub',
  'public',
  'raise',
  'return',
  'self',
  'static',
  'struct',
  'super',
  'switch',
  'this',
  'throw',
  'true',
  'True',
  'False',
  'try',
  'type',
  'typeof',
  'undefined',
  'use',
  'var',
  'void',
  'while',
  'with',
  'yield',
  'echo',
  'fi',
  'then',
  'esac',
  'done',
  'local',
};

/// Languages whose comments start with `#`.
bool _hashComments(String? ext) => const {
  'py',
  'sh',
  'bash',
  'yml',
  'yaml',
  'toml',
  'rb',
  'r',
  'conf',
  'ini',
  'dockerfile',
  'mk',
}.contains(ext);

final _token = RegExp(
  r'''(//.*$|/\*.*?(?:\*/|$)|<!--.*?(?:-->|$))|("(?:[^"\\]|\\.)*"?|'(?:[^'\\]|\\.)*'?|`(?:[^`\\]|\\.)*`?)|(\b\d[\d_.xXa-fA-F]*\b)|([A-Za-z_$][\w$]*)''',
);
final _hashToken = RegExp(
  r'''(#.*$)|("(?:[^"\\]|\\.)*"?|'(?:[^'\\]|\\.)*'?)|(\b\d[\d_.]*\b)|([A-Za-z_$][\w$]*)''',
);

/// The extension of [path] in lower case (a Dockerfile counts as one).
String? extOf(String path) {
  final name = path.split('/').last.toLowerCase();
  if (name == 'dockerfile' || name == 'makefile') return name == 'makefile' ? 'mk' : name;
  final i = name.lastIndexOf('.');
  return i < 0 ? null : name.substring(i + 1);
}

/// One line as coloured spans.
List<TextSpan> highlightLine(String line, String? ext, RgColors c) {
  if (const {'md', 'txt', 'csv', 'log', null}.contains(ext)) return [TextSpan(text: line)];
  final re = _hashComments(ext) ? _hashToken : _token;
  final out = <TextSpan>[];
  var at = 0;
  for (final m in re.allMatches(line)) {
    if (m.start > at) out.add(TextSpan(text: line.substring(at, m.start)));
    final text = m.group(0)!;
    final Color? color;
    var bold = false;
    if (m.group(1) != null) {
      color = c.dim;
    } else if (m.group(2) != null) {
      color = c.ok;
    } else if (m.group(3) != null) {
      color = c.warnText;
    } else if (_keywords.contains(text)) {
      color = c.accent2;
      bold = true;
    } else {
      color = null;
    }
    out.add(
      TextSpan(
        text: text,
        style: color == null
            ? null
            : TextStyle(color: color, fontWeight: bold ? FontWeight.w600 : null),
      ),
    );
    at = m.end;
  }
  if (at < line.length) out.add(TextSpan(text: line.substring(at)));
  return out;
}

const monoFamily = 'monospace';
const monoFallback = ['JetBrains Mono', 'Cascadia Code', 'Menlo', 'Consolas', 'DejaVu Sans Mono'];
