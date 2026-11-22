// Markdown, safely (the page's `renderMarkdown` with DOMPurify, in Flutter terms): no raw HTML is
// ever interpreted (a tag shows as the text it is), no image is fetched from the network (the
// alt text shows instead: nothing leaks where the person reads), links open outside the app only
// for http(s) and mailto, after the person says yes. Task lists use our drawn marks, never the
// system's checkboxes. A passage between `markOpen` and `markClose` (api/saved.dart) is lit up:
// a saved passage or a quote, found again in its message.
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../api/board.dart' show boardFromLink;
import '../api/saved.dart';
import '../l10n/app_localizations.dart';
import '../screens/board_screen.dart' show openBoard;
import '../settings/knowledge_cite.dart' show kbChunkOf, kbCiteTitle, openKbCitation;
import '../theme/colors.dart';
import 'citations.dart';
import 'code_block.dart';
import 'dialogs.dart';
import 'icons.dart';
import 'stream_cursor.dart';

/// GitHub's Markdown without the inline HTML syntax: `<b>` stays the text «<b>».
final md.ExtensionSet safeExtensions = md.ExtensionSet(
  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
  md.ExtensionSet.gitHubFlavored.inlineSyntaxes.where((s) => s is! md.InlineHtmlSyntax).toList(),
);

/// The words of a lit passage: `markOpen` … `markClose`, never with Markdown marks inside.
class _MarkSyntax extends md.InlineSyntax {
  _MarkSyntax() : super('$markOpen([^$markOpen$markClose]*)$markClose');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('rgmark', match[1]!));
    return true;
  }
}

class _MarkBuilder extends MarkdownElementBuilder {
  _MarkBuilder(this.color);

  final Color color;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => Text.rich(
    TextSpan(
      text: element.textContent,
      style: (parentStyle ?? const TextStyle()).copyWith(backgroundColor: color),
    ),
  );
}

/// The links the app may open (outside, in the system's browser or mail app).
bool openableLink(String? href) {
  final u = Uri.tryParse(href ?? '');
  return u != null && (u.scheme == 'https' || u.scheme == 'http' || u.scheme == 'mailto');
}

class SafeMarkdown extends StatelessWidget {
  const SafeMarkdown(
    this.data, {
    super.key,
    this.selectable = true,
    this.cursor = false,
    this.cursorStill = false,
    this.reading = false,
  });

  final String data;
  final bool selectable;

  /// An answer to read (3.10.4, «Lettura comoda», the page's `.md-read`): bigger text with room
  /// between lines and paragraphs, headings with the accent's bar. Off: the compact look of cards
  /// and summaries.
  final bool reading;

  /// An answer being written: the cursor after its last character (3.8.5, `stream_cursor.dart`).
  final bool cursor;

  /// «Reduce motion»: the cursor without its flicker.
  final bool cursorStill;

  Future<void> _open(BuildContext context, String? href) async {
    // A board's link (`#tavola=…`, as Telegram sends it): the board, here in the app (G42.2).
    final board = boardFromLink(href);
    if (board != null) {
      await openBoard(context, sessionId: board.sessionId, proposalId: board.proposalId);
      return;
    }
    // A citation of the person's documents (G42.10): where it points, here in the app.
    final chunk = kbChunkOf(href);
    if (chunk != null) {
      await openKbCitation(context, chunk);
      return;
    }
    if (!openableLink(href)) return;
    final l = AppLocalizations.of(context);
    final ok = await askConfirm(context, title: l.linkOpenTitle, body: href!, yes: l.linkOpen);
    if (ok) await launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final look = reading ? MarkdownLook.reading : MarkdownLook.compact;
    final base = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: c.text, fontSize: look.body, height: look.height);
    final code = base.copyWith(
      fontFamily: 'monospace',
      fontSize: reading ? look.body * 0.86 : 13.5,
      backgroundColor: c.panel2,
    );
    TextStyle heading(double size) => base.copyWith(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: reading ? 1.25 : base.height,
    );
    final marked = data.contains(markOpen);
    return MarkdownBody(
      // Sources as links once the answer is whole (the page's `renderAnswer`).
      data: cursor
          ? withStreamCursor(data)
          : linkCitations(data, kbTitle: (t) => kbCiteTitle(AppLocalizations.of(context), t)),
      // The cursor is a widget inside the text: an answer being written is not selectable yet.
      selectable: selectable && !cursor,
      extensionSet: safeExtensions,
      inlineSyntaxes: [if (marked) _MarkSyntax(), if (cursor) StreamCursorSyntax()],
      builders: {
        if (marked) 'rgmark': _MarkBuilder(c.accentDim),
        if (reading)
          for (final (tag, bar) in const [('h1', 4.0), ('h2', 4.0), ('h3', 3.0)])
            tag: HeadingBarBuilder(
              bar: bar,
              color: c.accent,
              selectable: selectable && !cursor,
              code: code,
              mark: c.accentDim,
              still: cursorStill,
            ),
        if (cursor) 'rgcursor': StreamCursorBuilder(still: cursorStill),
        if (cursor)
          'pre': StreamCursorCodeBuilder(
            still: cursorStill,
            style: code,
            padding: const EdgeInsets.all(8),
          )
        else
          'pre': CodeBlockBuilder(),
      },
      onTapLink: (text, href, title) => _open(context, href),
      imageBuilder: (uri, title, alt) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: c.panel2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RgIcon(RgIcons.image, size: 15, color: c.dim),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                // 2026-11-19: a path the app cannot open (an engine's folder, a file of the
                // agent's) says so plainly; a web picture shows its name (nothing is fetched).
                const {'http', 'https', 'data'}.contains(uri.scheme)
                    ? ((alt == null || alt.isEmpty) ? uri.toString() : alt)
                    : AppLocalizations.of(context)
                          .cvImageUnreachable((alt == null || alt.isEmpty) ? uri.toString() : alt),
                style: TextStyle(color: c.dim, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      checkboxBuilder: (v) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: RgIcon(v ? RgIcons.checkSquare : RgIcons.square, size: 16, color: v ? c.ok : c.dim),
      ),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: base,
        // Reading: paragraphs 16 apart (6 between blocks plus 10 under a paragraph), list items 6,
        // headings 18 above and 10 below, as the page's `.md-read`.
        blockSpacing: reading ? 6 : null,
        pPadding: reading ? const EdgeInsets.only(bottom: 10) : null,
        listBullet: reading ? base.copyWith(color: c.accent2) : base,
        a: base.copyWith(
          color: reading ? c.accent2 : c.accent,
          decoration: TextDecoration.underline,
          decorationColor: reading ? c.accent2 : c.accent,
        ),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        code: code,
        codeblockDecoration: BoxDecoration(
          color: c.panel2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.line),
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              // Reading: a neutral soft bar, the accent stays for headings, marks and links.
              color: reading ? c.text.withValues(alpha: 0.2) : c.accentDim,
              width: 3,
            ),
          ),
        ),
        blockquote: reading ? base.copyWith(color: Color.lerp(c.panel, c.text, 0.85)) : null,
        blockquotePadding: reading ? const EdgeInsets.fromLTRB(12, 2, 0, 2) : null,
        h1: heading(look.h1),
        h2: heading(look.h2),
        h3: heading(look.h3),
        tableBody: base,
        tableHead: base.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// The sizes of the two looks (3.10.4): the page's `.md` and `.md.md-read`.
class MarkdownLook {
  const MarkdownLook._(this.body, this.height, this.h1, this.h2, this.h3);

  /// Cards, summaries, plans: as before 3.10.4.
  static const compact = MarkdownLook._(15, 1.4, 21, 18.5, 16.5);

  /// Answers (the person's choice «Lettura comoda», memory/decisioni.md).
  static const reading = MarkdownLook._(17, 1.55, 24, 20.5, 18.5);

  final double body;
  final double height;
  final double h1;
  final double h2;
  final double h3;
}

/// A heading with the accent's bar on its left (3.10.4, the page's `.md-read h1`): 12 px between
/// the bar and the words, the inline marks of the words kept (bold, italic, code, a lit passage).
class HeadingBarBuilder extends MarkdownElementBuilder {
  HeadingBarBuilder({
    required this.bar,
    required this.color,
    required this.selectable,
    required this.code,
    required this.mark,
    this.still = false,
  });

  final double bar;
  final Color color;
  final bool selectable;
  final TextStyle code;
  final Color mark;

  /// An answer being written: its cursor without the flicker («Reduce motion»).
  final bool still;

  int _headings = 0;

  @override
  bool isBlockElement() => true;

  List<InlineSpan> _spans(List<md.Node>? nodes, TextStyle style) => [
    for (final n in nodes ?? const <md.Node>[])
      if (n is md.Element)
        switch (n.tag) {
          'code' => TextSpan(
            text: n.textContent,
            style: style.merge(code.copyWith(fontSize: (style.fontSize ?? 17) * 0.86)),
          ),
          'em' => TextSpan(
            children: _spans(n.children, style.copyWith(fontStyle: FontStyle.italic)),
          ),
          'del' => TextSpan(
            children: _spans(n.children, style.copyWith(decoration: TextDecoration.lineThrough)),
          ),
          'rgmark' => TextSpan(
            text: n.textContent,
            style: style.copyWith(backgroundColor: mark),
          ),
          'rgcursor' => WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: StreamCursor(height: (style.fontSize ?? 17) * 1.05, still: still),
          ),
          _ => TextSpan(children: _spans(n.children, style)),
        }
      else
        TextSpan(text: n.textContent),
  ];

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final style = preferredStyle ?? const TextStyle();
    final span = TextSpan(style: style, children: _spans(element.children, style));
    return Container(
      // One key per heading: several of the same level in one answer (3.10.5: the same key twice
      // turned a whole answer into Flutter's red error box).
      key: Key('md-heading-${element.tag}-${_headings++}'),
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: bar),
        ),
      ),
      child: selectable ? SelectableText.rich(span) : Text.rich(span),
    );
  }
}
