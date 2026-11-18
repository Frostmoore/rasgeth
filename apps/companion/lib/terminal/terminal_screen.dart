// The terminal as a screen of its own (G42.5): on a phone the whole screen, with the keys row over
// the keyboard (the page's terminal tab, `openTab({type: "terminal"})`, where a phone has no room
// for a side area). Its head: the page's title («Terminal · <place>»), text smaller and bigger.
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'rg_terminal.dart';

/// «Terminal · Demo»: the page's own title for a terminal tab.
String terminalTitle(AppLocalizations l, String place) => '${l.fxTerminal} · $place';

/// A terminal in [scope], the whole screen.
Future<void> openTerminalScreen(
  BuildContext context, {
  required String scope,
  required String title,
  String? command,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => TerminalScreen(scope: scope, title: title, command: command),
  ),
);

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({
    super.key,
    required this.scope,
    required this.title,
    this.command,
    this.open,
  });

  final String scope;
  final String title;
  final String? command;

  /// Tests: their own shell.
  final TermOpener? open;

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  double _font = 13;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final client = app.client;
    final phone = !app.desktop;
    return Scaffold(
      backgroundColor: rgTerminalBg,
      appBar: AppBar(
        leading: IconButton(
          key: const Key('term-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            RgIcon(RgIcons.terminal, size: 18, color: c.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                key: const Key('term-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('term-smaller'),
            tooltip: l.codeTextSmaller,
            onPressed: () => setState(() => _font = (_font - 1).clamp(8, 28)),
            icon: RgIcon(RgIcons.minus, size: 18, color: c.dim),
          ),
          IconButton(
            key: const Key('term-bigger'),
            tooltip: l.codeTextBigger,
            onPressed: () => setState(() => _font = (_font + 1).clamp(8, 28)),
            icon: RgIcon(RgIcons.plus, size: 18, color: c.dim),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: client == null
          ? const SizedBox.shrink()
          : RgTerminal(
              key: const Key('term-screen'),
              client: client,
              scope: widget.scope,
              font: _font,
              keys: phone,
              command: widget.command,
              open: widget.open,
            ),
    );
  }
}
