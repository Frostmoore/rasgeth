// A model's answer the person can select (G40.14, as the page's QuotePicker): a selection inside
// one message offers our own menu, drawn with our icons, with «Copia», «Rispondi a questo»
// (G36.22: the passage goes above the composer) and «Salva» (the passage into the person's saved
// items). Where the selection is in the message's text comes from the selection itself.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'icons.dart';
import 'markdown.dart';

/// A passage picked in a message: its text and where it is in the message as shown.
class PickedPassage {
  const PickedPassage({required this.text, this.start, this.end});

  final String text;
  final int? start;
  final int? end;
}

/// The answer's Markdown, selectable, with our menu over the selection.
class SelectableAnswer extends StatefulWidget {
  const SelectableAnswer({super.key, required this.data, this.onReply, this.onSave});

  /// The Markdown (with the marks of a lit passage, when there is one).
  final String data;
  final ValueChanged<PickedPassage>? onReply;
  final ValueChanged<PickedPassage>? onSave;

  @override
  State<SelectableAnswer> createState() => _SelectableAnswerState();
}

class _SelectableAnswerState extends State<SelectableAnswer> {
  final _where = SelectionListenerNotifier();
  final _text = AnswerSelectionDelegate();
  String _selected = '';

  @override
  void dispose() {
    _where.dispose();
    _text.dispose();
    super.dispose();
  }

  PickedPassage? _picked() {
    final text = _selected.trim();
    if (text.isEmpty) return null;
    final range = _where.registered ? _where.selection.range : null;
    if (range == null) return PickedPassage(text: text);
    final a = range.startOffset;
    final b = range.endOffset;
    return PickedPassage(text: text, start: a < b ? a : b, end: a < b ? b : a);
  }

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      onSelectionChanged: (content) => _selected = content?.plainText ?? '',
      contextMenuBuilder: (context, region) {
        void done() {
          region.hideToolbar();
          region.clearSelection();
        }

        return PassageMenu(
          anchors: region.contextMenuAnchors,
          onCopy: () {
            final text = _selected;
            done();
            if (text.isNotEmpty) unawaited(Clipboard.setData(ClipboardData(text: text)));
          },
          onReply: widget.onReply == null
              ? null
              : () {
                  final p = _picked();
                  done();
                  if (p != null) widget.onReply!(p);
                },
          onSave: widget.onSave == null
              ? null
              : () {
                  final p = _picked();
                  done();
                  if (p != null) widget.onSave!(p);
                },
        );
      },
      child: SelectionListener(
        selectionNotifier: _where,
        // One container for the whole answer: its delegate writes the copied text (lines, «- »).
        child: SelectionContainer(
          delegate: _text,
          child: SafeMarkdown(widget.data, selectable: false, reading: true),
        ),
      ),
    );
  }
}

/// What a piece of the answer's text is, for the copied text.
enum _Piece { bullet, itemText, text }

/// Whether a drawn list mark («•», «1.»): the only short text that stands alone left of an item.
bool _isBulletMark(String text, Size size) =>
    size.width < 64 && (text == '•' || RegExp(r'^\d+\.$').hasMatch(text));

/// The text of a selected passage of an answer as plain text a person would write: every
/// paragraph, heading and list item on its own line, «- » (or «1. ») before an item, a blank line
/// between blocks, a code block with its lines. Flutter joins the selected texts of the blocks
/// with nothing, so «Title», a bullet and a paragraph came out as one line with «•» in it.
/// Positions (`contentLength`, ranges) are the default ones: only the copied text changes.
class AnswerSelectionDelegate extends StaticSelectionContainerDelegate {
  @override
  SelectedContent? getSelectedContent() {
    final out = StringBuffer();
    Rect? prev;
    _Piece? kind;
    var any = false;
    for (final s in selectables) {
      final content = s.getSelectedContent();
      if (content == null || content.plainText.isEmpty) continue;
      any = true;
      final at = s.getTransformTo(null).getTranslation();
      final rect = Rect.fromLTWH(at.x, at.y, s.size.width, s.size.height);
      var text = content.plainText;
      final bullet = _isBulletMark(text, s.size);
      if (bullet) text = text == '•' ? '- ' : '$text ';
      if (prev != null) {
        if (kind == _Piece.bullet) {
          // The text of the item follows its mark.
        } else if (bullet) {
          out.write(kind == _Piece.itemText ? '\n' : '\n\n');
        } else if (rect.top >= prev.bottom - 1) {
          out.write('\n\n');
        } else if (rect.left >= prev.right - 1) {
          out.write('\t');
        }
      }
      kind = bullet
          ? _Piece.bullet
          : (kind == _Piece.bullet ||
                    (kind == _Piece.itemText && prev != null && rect.top < prev.bottom - 1)
                ? _Piece.itemText
                : _Piece.text);
      out.write(text);
      prev = rect;
    }
    return any ? SelectedContent(plainText: out.toString()) : null;
  }
}

/// Our menu over a selection: drawn buttons on the theme's panel, never the system's.
class PassageMenu extends StatelessWidget {
  const PassageMenu({
    super.key,
    required this.anchors,
    required this.onCopy,
    this.onReply,
    this.onSave,
  });

  final TextSelectionToolbarAnchors anchors;
  final VoidCallback onCopy;
  final VoidCallback? onReply;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    Widget button(Key key, RgIcons icon, String label, VoidCallback onTap) => InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RgIcon(icon, size: 15, color: c.text),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    // Placed as the system's menu is (above the selection, below when there is no room), but
    // all ours: one row that shrinks to fit, never an overflow «more» of the system.
    final media = MediaQuery.of(context);
    const gap = 8.0;
    const height = 44.0;
    final above = anchors.primaryAnchor;
    final below = anchors.secondaryAnchor ?? anchors.primaryAnchor;
    final top = media.padding.top + gap;
    return Padding(
      padding: EdgeInsets.fromLTRB(gap, top, gap, gap),
      child: CustomSingleChildLayout(
        delegate: TextSelectionToolbarLayoutDelegate(
          anchorAbove: above - Offset(gap, top + gap),
          anchorBelow: below - Offset(gap, top - gap),
          fitsAbove: above.dy - top - gap >= height,
        ),
        child: Material(
          key: const Key('passage-menu'),
          color: c.panel,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(const Key('sel-copy'), RgIcons.copy, l.copy, onCopy),
                  if (onReply != null)
                    button(const Key('sel-reply'), RgIcons.reply, l.quoteReplyShort, onReply!),
                  if (onSave != null)
                    button(const Key('sel-save'), RgIcons.bookmark, l.savedSave, onSave!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
