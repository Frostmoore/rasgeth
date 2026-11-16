// A model's answer the person can select (G40.14, as the page's QuotePicker): a selection inside
// one message offers our own menu, drawn with our icons, with «Copia», «Rispondi a questo»
// (G36.22: the passage goes above the composer) and «Salva» (the passage into the person's saved
// items). Where the selection is in the message's text comes from the selection itself.
import 'dart:async';

import 'package:flutter/material.dart';
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
  String _selected = '';

  @override
  void dispose() {
    _where.dispose();
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
        child: SafeMarkdown(widget.data, selectable: false),
      ),
    );
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
    return TextSelectionToolbar(
      anchorAbove: anchors.primaryAnchor,
      anchorBelow: anchors.secondaryAnchor ?? anchors.primaryAnchor,
      toolbarBuilder: (context, child) => Material(
        key: const Key('passage-menu'),
        color: c.panel,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: const EdgeInsets.all(3), child: child),
      ),
      children: [
        button(const Key('sel-copy'), RgIcons.copy, l.copy, onCopy),
        if (onReply != null) button(const Key('sel-reply'), RgIcons.reply, l.quoteReply, onReply!),
        if (onSave != null) button(const Key('sel-save'), RgIcons.bookmark, l.savedSave, onSave!),
      ],
    );
  }
}
