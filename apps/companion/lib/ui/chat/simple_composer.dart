// The composer of the group pieces (G42.3): a group chat, the old everyday chats, a board's reply.
// The same box as the conversation's (panel-2, accent border when focused, the red send), with
// the «@» suggestions of the page's Composer.tsx when [mentions] are given.
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';
import '../send_keys.dart';

final _mentionAt = RegExp(r'(?:^|\s)@([^@\n]{0,30})$');

/// «@» then the start of a name: the names it may be (the page's `mention-list`).
List<String> mentionOptions(String text, List<String> names) {
  final m = _mentionAt.firstMatch(text);
  if (m == null) return const [];
  final part = m.group(1)!.toLowerCase();
  return names.where((n) => n.toLowerCase().startsWith(part)).toList();
}

/// [text] with the «@…» it ends with completed to [name] and a space.
String completeMention(String text, String name) {
  final m = _mentionAt.firstMatch(text);
  if (m == null) return text;
  return '${text.substring(0, text.length - m.group(1)!.length)}$name ';
}

class SimpleComposer extends StatefulWidget {
  const SimpleComposer({
    super.key,
    required this.onSend,
    this.hint,
    this.mentions,
    this.sending = false,
    this.fieldKey = const Key('simple-composer-text'),
    this.sendKey = const Key('simple-composer-send'),
    this.minLines = 1,
  });

  /// The text written; true when it went (the field empties).
  final Future<bool> Function(String text) onSend;
  final String? hint;
  final List<String>? mentions;
  final bool sending;
  final Key fieldKey;
  final Key sendKey;
  final int minLines;

  @override
  State<SimpleComposer> createState() => _SimpleComposerState();
}

class _SimpleComposerState extends State<SimpleComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode(debugLabel: 'simple-composer');
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    _focus.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _busy || widget.sending) return;
    setState(() => _busy = true);
    final ok = await widget.onSend(t);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final busy = _busy || widget.sending;
    final options = widget.mentions == null
        ? const <String>[]
        : mentionOptions(_text.text, widget.mentions!);
    return Container(
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: c.panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _focus.hasFocus ? c.accent : c.line, width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(4, 4, 6, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (options.isNotEmpty)
              Padding(
                key: const Key('mention-list'),
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final n in options)
                      ActionChip(
                        key: Key('mention-$n'),
                        label: Text('@$n'),
                        onPressed: () {
                          final t = completeMention(_text.text, n);
                          _text.value = TextEditingValue(
                            text: t,
                            selection: TextSelection.collapsed(offset: t.length),
                          );
                          _focus.requestFocus();
                        },
                      ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: SendKeys(
                    onSend: busy ? null : _send,
                    child: TextField(
                      key: widget.fieldKey,
                      controller: _text,
                      focusNode: _focus,
                      minLines: widget.minLines,
                      maxLines: 8,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(color: c.text, fontSize: 15.5, height: 1.35),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l.composerSend,
                  child: Tooltip(
                    message: l.composerSend,
                    child: Material(
                      color: busy ? c.dim : c.accent,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        key: widget.sendKey,
                        borderRadius: BorderRadius.circular(10),
                        onTap: busy ? null : _send,
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Center(child: RgIcon(RgIcons.send, size: 18, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
