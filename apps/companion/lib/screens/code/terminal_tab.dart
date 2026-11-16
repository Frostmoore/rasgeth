// Terminal (G40.11): the agents' commands read only (their `bash` calls and what they printed),
// and the person's own shell over `/term`, as the page opens it (same token, scope and rules: an
// archived project has none), with a row of keys over the keyboard (Esc, Tab, Ctrl, arrows, |, ~)
// and the recent commands as pills. The text grows and shrinks with two fingers.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import 'project_screen.dart';

class TerminalTab extends StatefulWidget {
  const TerminalTab({super.key, required this.ctx, this.startAgent});

  final ProjectCtx ctx;

  /// Opened from an agent's sheet: that agent's terminal.
  final String? startAgent;

  @override
  State<TerminalTab> createState() => _TerminalTabState();
}

class _TerminalTabState extends State<TerminalTab> with AutomaticKeepAliveClientMixin {
  /// null: the person's own shell.
  late String? _agent = widget.startAgent;
  double _font = 13;
  double _pinchFrom = 13;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final agents = widget.ctx.agents;
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Row(
            children: [
              PickChip(
                key: const Key('term-mine'),
                icon: RgIcons.terminal,
                selected: _agent == null,
                label: l.codeTermMine,
                onTap: () => setState(() => _agent = null),
              ),
              for (final a in agents) ...[
                const SizedBox(width: 6),
                PickChip(
                  key: Key('term-agent-${a.id}'),
                  icon: RgIcons.lock,
                  selected: _agent == a.id,
                  label: a.name,
                  onTap: () => setState(() => _agent = a.id),
                ),
              ],
              const SizedBox(width: 12),
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
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onScaleStart: (_) => _pinchFrom = _font,
            onScaleUpdate: (d) {
              if (d.pointerCount < 2) return;
              setState(() => _font = (_pinchFrom * d.scale).clamp(8, 28));
            },
            child: _agent == null
                ? OwnShell(key: const Key('own-shell'), ctx: widget.ctx, font: _font)
                : AgentCommands(
                    key: ValueKey(_agent),
                    ctx: widget.ctx,
                    agentId: _agent!,
                    font: _font,
                  ),
          ),
        ),
      ],
    );
  }
}

TextStyle _mono(double size, Color color) => TextStyle(
  fontFamily: monoFamily,
  fontFamilyFallback: monoFallback,
  fontSize: size,
  height: 1.35,
  color: color,
);

const _termBg = Color(0xFF120F10);
const _termFg = Color(0xFFE8DFDC);

/// An agent's commands, read only.
class AgentCommands extends StatefulWidget {
  const AgentCommands({
    super.key,
    required this.ctx,
    required this.agentId,
    required this.font,
    this.every,
    this.compact = false,
  });

  final ProjectCtx ctx;
  final String agentId;
  final double font;

  /// Computers (G40.17): read again this often, as the agent works.
  final Duration? every;

  /// Without the line over the commands (the computers' grid has its own header).
  final bool compact;

  @override
  State<AgentCommands> createState() => _AgentCommandsState();
}

class _AgentCommandsState extends State<AgentCommands> {
  List<AgentCommand>? _cmds;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    final every = widget.every;
    if (every != null) _timer = Timer.periodic(every, (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = widget.ctx.client;
      final sessions = await c.sessions(agentId: widget.agentId);
      final out = <AgentCommand>[];
      for (final s in sessions.take(3).toList().reversed) {
        out.addAll(agentCommands(await c.sessionEvents(s.id)));
      }
      if (mounted)
        setState(() {
          _cmds = out;
          _error = null;
        });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final cmds = _cmds;
    if (cmds == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    }
    return Column(
      children: [
        if (!widget.compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 6, 4),
            child: Row(
              children: [
                RgIcon(RgIcons.lock, size: 14, color: c.dim),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l.codeTermReadOnly, style: TextStyle(color: c.dim, fontSize: 12.5)),
                ),
                IconButton(
                  key: const Key('term-agent-reload'),
                  tooltip: l.codeReload,
                  onPressed: _load,
                  icon: RgIcon(RgIcons.refresh, size: 17, color: c.dim),
                ),
              ],
            ),
          ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: _termBg,
            child: cmds.isEmpty
                ? Center(child: Text(l.codeTermNoCommands, style: _mono(widget.font, c.dim)))
                : ListView(
                    key: const Key('term-agent-lines'),
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    children: [
                      SelectableText.rich(
                        TextSpan(
                          style: _mono(widget.font, _termFg),
                          children: [
                            for (final x in cmds) ...[
                              TextSpan(
                                text: r'$ ',
                                style: TextStyle(color: c.accent2, fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: '${x.command}\n',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              if (x.output != null)
                                TextSpan(
                                  text: '${x.output!.trimRight()}\n',
                                  style: TextStyle(
                                    color: x.ok == false ? const Color(0xFFFF8A8F) : null,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// The person's own shell, with the keys over the keyboard.
class OwnShell extends StatefulWidget {
  const OwnShell({
    super.key,
    required this.ctx,
    required this.font,
    this.compact = false,
    this.autoOpen = false,
    this.command,
  });

  final ProjectCtx ctx;
  final double font;

  /// Computers (G40.17): a real keyboard, no row of extra keys.
  final bool compact;

  /// Opened at once, without its button.
  final bool autoOpen;

  /// Run as soon as it opens (the palette's «!»).
  final String? command;

  @override
  State<OwnShell> createState() => _OwnShellState();
}

class _OwnShellState extends State<OwnShell> {
  TermSession? _term;
  StreamSubscription<String>? _sub;
  final _buf = TermBuffer();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _error;
  bool _ctrl = false;
  bool _opening = false;
  List<String> _recent = const [];

  String get _recentKey =>
      'recentCommands:${widget.ctx.app.server?.id ?? '-'}:${widget.ctx.project.id}';

  @override
  void initState() {
    super.initState();
    unawaited(_loadRecent());
    if (widget.autoOpen && !widget.ctx.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_open());
      });
    }
  }

  Future<void> _loadRecent() async {
    final raw = await widget.ctx.app.prefs.get(_recentKey);
    if (mounted && raw != null && raw.isNotEmpty) setState(() => _recent = raw.split('\n'));
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_term?.close());
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final t = await widget.ctx.client.openTerminal(widget.ctx.scope, cols: 60, rows: 30);
      _sub = t.output.listen(
        (d) {
          _buf.write(d);
          if (!mounted) return;
          setState(() {});
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
          });
        },
        onDone: () {
          if (mounted)
            setState(() => _error = _term?.error ?? AppLocalizations.of(context).codeTermClosed);
        },
      );
      setState(() => _term = t);
      final first = widget.command;
      if (first != null && first.trim().isNotEmpty) _submit(first);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _key(String bytes) => _term?.input(bytes);

  void _submit([String? text]) {
    final t = text ?? _input.text;
    _term?.input('$t${TermKeys.enter}');
    _input.clear();
    final cmd = t.trim();
    if (cmd.isEmpty) return;
    final list = [cmd, ..._recent.where((x) => x != cmd)].take(8).toList();
    setState(() => _recent = list);
    unawaited(widget.ctx.app.prefs.set(_recentKey, list.join('\n')));
  }

  void _changed(String v) {
    // Ctrl held: the next letter typed goes as its control code (Ctrl+C).
    if (_ctrl && v.isNotEmpty) {
      _key(TermKeys.ctrl(v.substring(v.length - 1)));
      _input.text = v.substring(0, v.length - 1);
      setState(() => _ctrl = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final term = _term;
    if (term == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RgIcon(RgIcons.terminal, size: 40, color: c.dim),
              const SizedBox(height: 10),
              Text(
                l.codeTermIntro,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.dim),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.err),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('term-open'),
                onPressed: _opening || widget.ctx.readOnly ? null : _open,
                icon: const RgIcon(RgIcons.terminal, size: 18, color: Colors.white),
                label: Text(l.codeTermOpen),
              ),
            ],
          ),
        ),
      );
    }
    Widget key(String label, String bytes, {Key? k}) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _Key(key: k, label: label, onTap: () => _key(bytes)),
    );
    Widget icon(RgIcons i, String bytes, String name) => Padding(
      padding: const EdgeInsets.only(right: 6),
      child: _Key(key: Key('key-$name'), icon: i, label: name, onTap: () => _key(bytes)),
    );
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: _termBg,
            child: SingleChildScrollView(
              key: const Key('term-output'),
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              child: SelectableText(_buf.text, style: _mono(widget.font, _termFg)),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(6),
            child: Text(_error!, style: TextStyle(color: c.err, fontSize: 12.5)),
          ),
        if (_recent.isNotEmpty)
          SingleChildScrollView(
            key: const Key('term-recent'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                for (final r in _recent)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: PickChip(label: r, onTap: () => _submit(r)),
                  ),
              ],
            ),
          ),
        if (!widget.compact)
          SingleChildScrollView(
            key: const Key('term-keys'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
            child: Row(
              children: [
                key('Esc', TermKeys.esc, k: const Key('key-esc')),
                key('Tab', TermKeys.tab, k: const Key('key-tab')),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _Key(
                    key: const Key('key-ctrl'),
                    label: 'Ctrl',
                    on: _ctrl,
                    onTap: () => setState(() => _ctrl = !_ctrl),
                  ),
                ),
                icon(RgIcons.arrowLeft, TermKeys.left, 'left'),
                icon(RgIcons.arrowUp, TermKeys.up, 'up'),
                icon(RgIcons.arrowDown, TermKeys.down, 'down'),
                icon(RgIcons.arrowRight, TermKeys.right, 'right'),
                key('|', '|', k: const Key('key-pipe')),
                key('~', '~', k: const Key('key-tilde')),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
          child: TextField(
            key: const Key('term-input'),
            controller: _input,
            onChanged: _changed,
            onSubmitted: (_) => _submit(),
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.send,
            style: _mono(14, c.text),
            decoration: InputDecoration(isDense: true, hintText: l.codeTermHint, prefixText: r'$ '),
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({super.key, required this.label, required this.onTap, this.icon, this.on = false});

  final String label;
  final RgIcons? icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
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
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 36),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: icon != null
                ? RgIcon(icon!, size: 17, color: on ? Colors.white : c.text)
                : Text(
                    label,
                    style: _mono(
                      14,
                      on ? Colors.white : c.text,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }
}
