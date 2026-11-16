// 3.8.5: the cursor of an answer being written. While the text streams in, a small red bar (the
// theme's accent) follows the last character written, wherever it is in the Markdown: a paragraph,
// an item of a list, a cell of a table, a quote, a heading, a block of code. It flickers like a very
// light flame (a warm glow that breathes, never a hard blink); with «Reduce motion» it stays still.
// It goes away when the answer is done.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../theme/colors.dart';

/// Where the cursor goes in the text (a private-use character, as the saved passages' marks).
const streamCursorMark = '';

final _fence = RegExp(r'^ {0,3}(```|~~~)');

/// The text with the cursor's mark after its last character: trailing line breaks are left out
/// (the cursor stays on the last line written), a table row's closing `|` keeps the cursor in its
/// last cell, and a fence line keeps the cursor inside its code block (after an opening fence, on the
/// block's first line; before a closing one, at the end of the code).
String withStreamCursor(String text) {
  var t = text.replaceAll(streamCursorMark, '');
  t = t.replaceFirst(RegExp(r'[\r\n]+$'), '');
  if (t.isEmpty) return streamCursorMark;
  final cut = t.lastIndexOf('\n');
  final head = cut < 0 ? '' : t.substring(0, cut + 1);
  final last = t.substring(cut + 1);
  if (_fence.hasMatch(last)) {
    final fences = '\n$t'.split('\n').where(_fence.hasMatch).length;
    if (fences.isOdd) return '$t\n$streamCursorMark';
    final before = head.replaceFirst(RegExp(r'\n$'), '');
    return '$before$streamCursorMark\n$last';
  }
  final row = RegExp(r'^(\s*\|.*?)(\|\s*)$').firstMatch(last);
  if (row != null && !RegExp(r'^[\s|:\-]+$').hasMatch(last)) {
    return '$head${row[1]!.trimRight()} $streamCursorMark ${row[2]}';
  }
  return '$t$streamCursorMark';
}

/// The mark in inline text: the cursor.
class StreamCursorSyntax extends md.InlineSyntax {
  StreamCursorSyntax() : super(streamCursorMark);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.empty('rgcursor'));
    return true;
  }
}

/// The cursor inside the line it ends: a span, so it flows with the words.
class StreamCursorBuilder extends MarkdownElementBuilder {
  StreamCursorBuilder({required this.still});

  final bool still;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final size = (parentStyle?.fontSize ?? 15) * 1.05;
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: StreamCursor(height: size, still: still),
          ),
        ],
      ),
    );
  }
}

/// A block of code with the cursor in it (the code text holds the mark): the same box the
/// Markdown draws, with the code scrolling sideways and the cursor after its last character.
class StreamCursorCodeBuilder extends MarkdownElementBuilder {
  StreamCursorCodeBuilder({required this.still, required this.style, required this.padding});

  final bool still;
  final TextStyle? style;
  final EdgeInsets padding;

  @override
  Widget? visitText(md.Text text, TextStyle? preferredStyle) {
    final s = text.text.replaceFirst(RegExp(r'\n$'), '');
    final at = s.indexOf(streamCursorMark);
    final st = style ?? preferredStyle;
    final span = at < 0
        ? TextSpan(text: s, style: st)
        : TextSpan(
            style: st,
            children: [
              TextSpan(text: s.substring(0, at)),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: StreamCursor(height: (st?.fontSize ?? 13.5) * 1.1, still: still),
              ),
              TextSpan(text: s.substring(at + 1)),
            ],
          );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Text.rich(span),
    );
  }
}

/// The cursor itself: a rounded bar in the accent's colour, its top warmer, with a soft glow that
/// breathes unevenly like a small flame. Still when [still].
class StreamCursor extends StatefulWidget {
  const StreamCursor({super.key, this.height = 16, this.still = false});

  final double height;
  final bool still;

  @override
  State<StreamCursor> createState() => _StreamCursorState();
}

class _StreamCursorState extends State<StreamCursor> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.still) _c.repeat();
  }

  @override
  void didUpdateWidget(StreamCursor old) {
    super.didUpdateWidget(old);
    if (widget.still && _c.isAnimating) {
      _c.stop();
    } else if (!widget.still && !_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      excludeSemantics: true,
      child: Padding(
        key: const Key('stream-cursor'),
        padding: const EdgeInsets.only(left: 2),
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            // Three slow waves out of step: a flicker that never repeats exactly within a cycle.
            final p = _c.value * 2 * math.pi;
            final f = widget.still
                ? 0.5
                : 0.5 +
                      0.22 * math.sin(p * 2) +
                      0.16 * math.sin(p * 5 + 1.3) +
                      0.12 * math.sin(p * 9 + 0.4);
            final warm = Color.lerp(c.accent, c.warn, 0.25 + 0.35 * f)!;
            return Transform.scale(
              alignment: Alignment.bottomCenter,
              scaleY: 0.94 + 0.08 * f,
              child: Container(
                width: widget.height * 0.42,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.height * 0.14),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      c.accent,
                      c.accent,
                      warm.withValues(alpha: 0.75 + 0.25 * f),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: c.accent.withValues(alpha: 0.18 + 0.22 * f),
                      blurRadius: 3 + 5 * f,
                      spreadRadius: 0.2 + 0.6 * f,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
