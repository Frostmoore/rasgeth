// 3.12.4: formulas in an answer, as the page draws them with KaTeX (packages/web/src/markdown.ts):
// `$…$` and `\(…\)` inline, `$$…$$` and `\[…\]` display. They are taken out of the text before
// Markdown reads it (it would eat the backslashes), never from code (fenced blocks and spans);
// «$5 e $10» stays text (no space after the opening `$` or before the closing one, no digit after
// it). A formula the parser cannot read shows as its source; selecting it copies the LaTeX.
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

const _open = '\uE001';
const _close = '\uE002';

/// Marks the start of a formula's source in the copied text (see `AnswerSelectionDelegate`).
const mathCopyInline = '\uE003';
const mathCopyDisplay = '\uE004';

/// One formula found in a text.
class MathPiece {
  const MathPiece(this.tex, {required this.display});

  final String tex;
  final bool display;

  /// The source as a person writes it: `$…$` or `$$…$$`.
  String get source => display ? '\$\$$tex\$\$' : '\$$tex\$';
}

/// A text with its formulas replaced by marks, and the formulas themselves.
class MathText {
  const MathText(this.text, this.pieces);

  final String text;
  final List<MathPiece> pieces;
}

final _fenceStart = RegExp(r'^( {0,3})(`{3,}|~{3,})[^\n]*(?:\n|$)');

({String tex, int end})? _inlineDollar(String s, int at) {
  if (at + 1 >= s.length) return null;
  final first = s[at + 1];
  if (RegExp(r'[\s$]').hasMatch(first)) return null;
  for (var j = at + 1; j < s.length; j++) {
    final ch = s[j];
    // Never across a line or a code span: «\$10 e `\$x\$`» is a price and code.
    if (ch == '\n' || ch == '`') return null;
    if (ch == r'\') {
      j++;
      continue;
    }
    if (ch != r'$') continue;
    // The first `$` after the opening one decides: no space before it, no digit after it.
    if (RegExp(r'\s').hasMatch(s[j - 1]) ||
        (j + 1 < s.length && RegExp(r'\d').hasMatch(s[j + 1]))) {
      return null;
    }
    return (tex: s.substring(at + 1, j), end: j + 1);
  }
  return null;
}

/// The formulas of [md] out of its text (the same rules as the page's `extractMath`).
MathText extractMath(String md) {
  if (!md.contains(r'$') && !md.contains(r'\')) return MathText(md, const []);
  final pieces = <MathPiece>[];
  final out = StringBuffer();
  void put(String tex, bool display) {
    pieces.add(MathPiece(tex.trim(), display: display));
    out.write('$_open${pieces.length - 1}$_close');
  }

  var i = 0;
  var lineStart = true;
  while (i < md.length) {
    final ch = md[i];
    if (lineStart) {
      final rest = md.substring(i, i + 400 > md.length ? md.length : i + 400);
      final fence = _fenceStart.firstMatch(rest);
      if (fence != null) {
        final mark = fence[2]!;
        final closing = RegExp(
          '\\n {0,3}${mark[0] == '~' ? '~' : '`'}{${mark.length},}[ \\t]*(?=\\n|\$)',
        );
        final m = closing.firstMatch(md.substring(i + fence[0]!.length - 1));
        final end = m == null ? md.length : i + fence[0]!.length - 1 + m.end;
        out.write(md.substring(i, end));
        i = end;
        lineStart = false;
        continue;
      }
    }
    lineStart = ch == '\n';
    if (ch == '`') {
      var n = 1;
      while (i + n < md.length && md[i + n] == '`') {
        n++;
      }
      final run = '`' * n;
      var k = md.indexOf(run, i + n);
      while (k >= 0 && k + n < md.length && md[k + n] == '`') {
        k = md.indexOf(run, k + n + 1);
      }
      final end = k >= 0 ? k + n : i + n;
      out.write(md.substring(i, end));
      i = end;
      continue;
    }
    if (ch == r'\') {
      final next = i + 1 < md.length ? md[i + 1] : '';
      if (next == '[' || next == '(') {
        final close = md.indexOf(next == '[' ? r'\]' : r'\)', i + 2);
        final tex = close > 0 ? md.substring(i + 2, close) : '';
        if (close > 0 && tex.trim().isNotEmpty && !(next == '(' && tex.contains('\n\n'))) {
          put(tex, next == '[');
          i = close + 2;
          continue;
        }
      }
      out.write(md.substring(i, i + 2 > md.length ? md.length : i + 2));
      i += 2;
      continue;
    }
    if (ch == r'$') {
      if (i + 1 < md.length && md[i + 1] == r'$') {
        final close = md.indexOf(r'$$', i + 2);
        final tex = close > 0 ? md.substring(i + 2, close) : '';
        if (close > 0 && tex.trim().isNotEmpty) {
          put(tex, true);
          i = close + 2;
          continue;
        }
        out.write(r'$$');
        i += 2;
        continue;
      }
      final found = _inlineDollar(md, i);
      if (found != null) {
        put(found.tex, false);
        i = found.end;
        continue;
      }
    }
    out.write(ch);
    i++;
  }
  return MathText(out.toString(), pieces);
}

/// The mark of a formula in inline text: an `rgmath` element holding its source.
class MathSyntax extends md.InlineSyntax {
  MathSyntax(this.pieces) : super('$_open(\\d+)$_close');

  final List<MathPiece> pieces;

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final i = int.parse(match[1]!);
    if (i >= pieces.length) return false;
    final piece = pieces[i];
    final el = md.Element.text('rgmath', piece.tex);
    if (piece.display) el.attributes['display'] = '1';
    parser.addNode(el);
    return true;
  }
}

/// A formula drawn: centred and scrollable when display, in the line when inline; its source
/// (invisible, over it) is what a selection copies.
class MathView extends StatelessWidget {
  const MathView(this.tex, {super.key, required this.display, required this.style});

  final String tex;
  final bool display;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final source = display ? '\$\$$tex\$\$' : '\$$tex\$';
    final shown = Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: style,
      onErrorFallback: (_) => Text(source, style: style),
    );
    // The copied text: the mark tells the answer's delegate what it is.
    final copy = '${display ? mathCopyDisplay : mathCopyInline}$source';
    final body = Stack(
      children: [
        shown,
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.fill,
            child: Text(copy, style: style.copyWith(color: const Color(0x00000000))),
          ),
        ),
      ],
    );
    if (!display) return body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(widthFactor: 1, child: body),
      ),
    );
  }
}

/// The builder of the `rgmath` element (inline formulas sit in the line, display ones are
/// blocks of their own).
class MathBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => MathView(
    element.textContent,
    display: element.attributes['display'] == '1',
    style: parentStyle ?? preferredStyle ?? const TextStyle(),
  );
}
