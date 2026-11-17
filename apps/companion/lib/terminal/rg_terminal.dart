// The person's terminal (G42.5), the page's `TerminalView.tsx` drawn natively with `xterm`
// (4.0.0, MIT): a real terminal over `/term` (terminal.ts), so full-screen programs (vim, htop,
// less), colours, the cursor and the mouse modes work as in the page. The same `hello` with the
// token, the scope and the size the view measured, then input, resize, output and exit; the same
// rules (an archived project has none, the server counts the terminals). The page's colours
// (background, text, cursor, selection) with xterm.js's own palette for the 16 colours.
//
// On a phone [keys] adds the row over the keyboard (Esc, Tab, Ctrl and Alt that hold for the next
// key, arrows, Home/End, PgUp/PgDn, | ~ / -, paste, show or hide the keyboard). On a computer
// the keyboard is the computer's: Ctrl+Shift+C copies, Ctrl+V or Ctrl+Shift+V pastes (Cmd on a
// Mac), every other Ctrl goes to the program as in the page (Ctrl+C, Ctrl+A for tmux…).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart' as xt;

import '../api/client.dart';
import '../api/code.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/highlight.dart' show monoFallback, monoFamily;
import '../ui/icons.dart';

/// The page's terminal colours (TerminalView.tsx) over xterm.js's default 16 (Tango).
const rgTerminalTheme = xt.TerminalTheme(
  cursor: Color(0xFFEF4B3A),
  selection: Color(0xFF5A2320),
  foreground: Color(0xFFE8DFDC),
  background: Color(0xFF120F10),
  black: Color(0xFF2E3436),
  red: Color(0xFFCC0000),
  green: Color(0xFF4E9A06),
  yellow: Color(0xFFC4A000),
  blue: Color(0xFF3465A4),
  magenta: Color(0xFF75507B),
  cyan: Color(0xFF06989A),
  white: Color(0xFFD3D7CF),
  brightBlack: Color(0xFF555753),
  brightRed: Color(0xFFEF2929),
  brightGreen: Color(0xFF8AE234),
  brightYellow: Color(0xFFFCE94F),
  brightBlue: Color(0xFF729FCF),
  brightMagenta: Color(0xFFAD7FA8),
  brightCyan: Color(0xFF34E2E2),
  brightWhite: Color(0xFFEEEEEC),
  searchHitBackground: Color(0xFFFCE94F),
  searchHitBackgroundCurrent: Color(0xFF8AE234),
  searchHitForeground: Color(0xFF120F10),
);

/// The terminal's background, for what sits around it.
const rgTerminalBg = Color(0xFF120F10);

bool get _apple =>
    defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

bool get _touch =>
    defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

xt.TerminalTargetPlatform get _target => switch (defaultTargetPlatform) {
  TargetPlatform.android => xt.TerminalTargetPlatform.android,
  TargetPlatform.iOS => xt.TerminalTargetPlatform.ios,
  TargetPlatform.macOS => xt.TerminalTargetPlatform.macos,
  TargetPlatform.windows => xt.TerminalTargetPlatform.windows,
  TargetPlatform.linux => xt.TerminalTargetPlatform.linux,
  TargetPlatform.fuchsia => xt.TerminalTargetPlatform.fuchsia,
};

/// Copy and paste as a terminal has them; never Ctrl+A or Ctrl+C alone (they go to the program).
Map<ShortcutActivator, Intent> get terminalShortcuts => _apple
    ? {
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true): CopySelectionTextIntent.copy,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): const PasteTextIntent(
          SelectionChangedCause.keyboard,
        ),
      }
    : {
        const SingleActivator(LogicalKeyboardKey.keyC, control: true, shift: true):
            CopySelectionTextIntent.copy,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true):
            const PasteTextIntent(SelectionChangedCause.keyboard),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): const PasteTextIntent(
          SelectionChangedCause.keyboard,
        ),
      };

/// What a held Ctrl or Alt makes of the next character typed: Ctrl+letter its control code,
/// Alt the character after Esc (as a terminal's meta key).
String withModifiers(String data, {bool ctrl = false, bool alt = false}) {
  var out = data;
  if (ctrl && out.length == 1) out = TermKeys.ctrl(out);
  if (alt) out = '\x1b$out';
  return out;
}

/// Opens a shell: the client's own, or the tests'.
typedef TermOpener = Future<TermSession> Function(String scope, int cols, int rows);

/// One shell in [scope], drawn by xterm.
class RgTerminal extends StatefulWidget {
  const RgTerminal({
    super.key,
    required this.client,
    required this.scope,
    this.font = 13,
    this.keys = false,
    this.autofocus = true,
    this.command,
    this.open,
  });

  final RedGiantClient client;

  /// `project:<id>`, `assistants` or `platform`, as the page's terminal.
  final String scope;
  final double font;

  /// A phone: the row of extra keys under the terminal (over the keyboard).
  final bool keys;
  final bool autofocus;

  /// Run as soon as the shell is ready (the palette's «!»).
  final String? command;

  /// Tests: their own shell.
  final TermOpener? open;

  @override
  State<RgTerminal> createState() => RgTerminalState();
}

class RgTerminalState extends State<RgTerminal> {
  late final xt.Terminal terminal = xt.Terminal(
    maxLines: 5000,
    platform: _target,
    onOutput: _typed,
    onResize: (w, h, _, _) => _session?.resize(w, h),
  );
  final controller = xt.TerminalController();
  final focus = FocusNode(debugLabel: 'terminal');

  TermSession? _session;
  StreamSubscription<String>? _sub;
  bool _opening = false;
  bool _ended = false;
  bool _ctrl = false;
  bool _alt = false;

  /// While the keys row sends a key of its own: its bytes go as they are.
  bool _raw = false;

  /// What reached the shell, for the tests.
  @visibleForTesting
  TermSession? get session => _session;

  bool get ended => _ended;

  @override
  void initState() {
    super.initState();
    // Once laid out: the size the view measured goes in `hello`, as the page's fit addon does.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    final s = _session;
    if (s != null) {
      s.onEnd = null;
      unawaited(s.close());
    }
    controller.dispose();
    focus.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_opening) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _opening = true;
      _ended = false;
    });
    final cols = terminal.viewWidth > 1 ? terminal.viewWidth : 80;
    final rows = terminal.viewHeight > 1 ? terminal.viewHeight : 24;
    try {
      final open = widget.open ?? (s, c, r) => widget.client.openTerminal(s, cols: c, rows: r);
      final s = await open(widget.scope, cols, rows);
      if (!mounted) {
        unawaited(s.close());
        return;
      }
      s.onEnd = () {
        if (!mounted) return;
        terminal.write('\r\n\x1b[90m${l.codeTermClosed}\x1b[0m\r\n');
        setState(() => _ended = true);
      };
      _sub = s.output.listen(terminal.write);
      setState(() => _session = s);
      // The view may have been measured again while the shell opened.
      if (terminal.viewWidth != cols || terminal.viewHeight != rows) {
        s.resize(terminal.viewWidth, terminal.viewHeight);
      }
      final first = widget.command;
      if (first != null && first.trim().isNotEmpty) s.input('$first\r');
    } on Object catch (e) {
      if (!mounted) return;
      terminal.write('\r\n\x1b[31m${e is ApiException ? e.message : '$e'}\x1b[0m\r\n');
      setState(() => _ended = true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  /// «Open again» after the shell ended: a new one, the old lines kept above.
  Future<void> reopen() async {
    await _sub?.cancel();
    _sub = null;
    _session = null;
    await _start();
  }

  /// Everything typed (the keyboard, a paste, the keys row) goes to the shell from here.
  void _typed(String data) {
    final s = _session;
    if (s == null) return;
    if (_raw || (!_ctrl && !_alt)) {
      s.input(data);
      return;
    }
    s.input(withModifiers(data, ctrl: _ctrl, alt: _alt));
    setState(() => _ctrl = _alt = false);
  }

  /// A key of the row (an arrow, Esc…): through the terminal, which knows the program's modes
  /// (vim's arrows are not the shell's), with a held Ctrl or Alt.
  void key(xt.TerminalKey k) {
    _raw = true;
    try {
      terminal.keyInput(k, ctrl: _ctrl, alt: _alt);
    } finally {
      _raw = false;
    }
    if (_ctrl || _alt) setState(() => _ctrl = _alt = false);
  }

  /// A character of the row (| ~ / -), as if typed.
  void text(String t) => terminal.textInput(t);

  Future<void> paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text;
    if (t != null && t.isNotEmpty) {
      _raw = true;
      try {
        terminal.paste(t);
      } finally {
        _raw = false;
      }
    }
  }

  void _toggleKeyboard() {
    if (focus.hasFocus) {
      focus.unfocus();
    } else {
      focus.requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final view = ColoredBox(
      color: rgTerminalBg,
      child: Stack(
        children: [
          Positioned.fill(
            child: xt.TerminalView(
              terminal,
              key: const Key('term-view'),
              controller: controller,
              focusNode: focus,
              autofocus: widget.autofocus,
              theme: rgTerminalTheme,
              textStyle: xt.TerminalStyle(
                fontSize: widget.font,
                fontFamily: monoFamily,
                fontFamilyFallback: monoFallback,
              ),
              padding: const EdgeInsets.all(8),
              keyboardAppearance: Brightness.dark,
              deleteDetection: _touch,
              shortcuts: terminalShortcuts,
              readOnly: _session == null || _ended,
            ),
          ),
          if (_ended)
            Positioned(
              right: 12,
              bottom: 12,
              child: FilledButton.icon(
                key: const Key('term-reopen'),
                onPressed: _opening ? null : reopen,
                icon: const RgIcon(RgIcons.refresh, size: 16, color: Colors.white),
                label: Text(l.termOpenAgain),
              ),
            ),
          if (_opening && _session == null)
            const Positioned(
              right: 12,
              top: 10,
              child: RgSpinner(size: 16, color: Color(0xFFE8DFDC)),
            ),
        ],
      ),
    );
    if (!widget.keys) return view;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: view),
        TermKeysRow(
          ctrl: _ctrl,
          alt: _alt,
          keyboardShown: focus.hasFocus,
          onCtrl: () => setState(() => _ctrl = !_ctrl),
          onAlt: () => setState(() => _alt = !_alt),
          onKey: key,
          onText: text,
          onPaste: () => unawaited(paste()),
          onKeyboard: _toggleKeyboard,
        ),
      ],
    );
  }
}

/// The row of keys a phone's keyboard lacks, under the terminal.
class TermKeysRow extends StatelessWidget {
  const TermKeysRow({
    super.key,
    required this.ctrl,
    required this.alt,
    required this.keyboardShown,
    required this.onCtrl,
    required this.onAlt,
    required this.onKey,
    required this.onText,
    required this.onPaste,
    required this.onKeyboard,
  });

  final bool ctrl;
  final bool alt;
  final bool keyboardShown;
  final VoidCallback onCtrl;
  final VoidCallback onAlt;
  final void Function(xt.TerminalKey) onKey;
  final void Function(String) onText;
  final VoidCallback onPaste;
  final VoidCallback onKeyboard;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    Widget k(String id, String label, VoidCallback tap, {RgIcons? icon, bool on = false}) =>
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: TermKey(key: Key('key-$id'), label: label, icon: icon, on: on, onTap: tap),
        );
    return Container(
      key: const Key('term-keys'),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            children: [
              k('esc', 'Esc', () => onKey(xt.TerminalKey.escape)),
              k('tab', 'Tab', () => onKey(xt.TerminalKey.tab)),
              k('ctrl', 'Ctrl', onCtrl, on: ctrl),
              k('alt', 'Alt', onAlt, on: alt),
              k(
                'left',
                l.termKeyLeft,
                () => onKey(xt.TerminalKey.arrowLeft),
                icon: RgIcons.arrowLeft,
              ),
              k('up', l.termKeyUp, () => onKey(xt.TerminalKey.arrowUp), icon: RgIcons.arrowUp),
              k(
                'down',
                l.termKeyDown,
                () => onKey(xt.TerminalKey.arrowDown),
                icon: RgIcons.arrowDown,
              ),
              k(
                'right',
                l.termKeyRight,
                () => onKey(xt.TerminalKey.arrowRight),
                icon: RgIcons.arrowRight,
              ),
              k('pipe', '|', () => onText('|')),
              k('tilde', '~', () => onText('~')),
              k('slash', '/', () => onText('/')),
              k('dash', '-', () => onText('-')),
              k('home', 'Home', () => onKey(xt.TerminalKey.home)),
              k('end', 'End', () => onKey(xt.TerminalKey.end)),
              k('pgup', 'PgUp', () => onKey(xt.TerminalKey.pageUp)),
              k('pgdn', 'PgDn', () => onKey(xt.TerminalKey.pageDown)),
              k('paste', l.termPaste, onPaste, icon: RgIcons.copy),
              k(
                'keyboard',
                keyboardShown ? l.termHideKeyboard : l.termShowKeyboard,
                onKeyboard,
                icon: RgIcons.keyboard,
                on: keyboardShown,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One key of the row: a label or a drawn icon, lit while held (Ctrl, Alt).
class TermKey extends StatelessWidget {
  const TermKey({super.key, required this.label, required this.onTap, this.icon, this.on = false});

  final String label;
  final RgIcons? icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final fg = on ? Colors.white : c.text;
    return Semantics(
      button: true,
      toggled: on ? true : null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: on ? c.accent : c.panel2,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          // Never takes the focus from the terminal: the keyboard stays up.
          canRequestFocus: false,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 38),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: icon != null
                ? RgIcon(icon!, size: 17, color: fg)
                : Text(
                    label,
                    style: TextStyle(
                      fontFamily: monoFamily,
                      fontFamilyFallback: monoFallback,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
