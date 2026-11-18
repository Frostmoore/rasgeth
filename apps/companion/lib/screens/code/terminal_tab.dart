// Terminal (G40.11): the agents' commands read only (their `bash` calls and what they printed),
// and the person's own shell over `/term`, as the page opens it (same token, scope and rules: an
// archived project has none). G42.5: the shell is a real terminal (`RgTerminal`, xterm: vim,
// htop, colours), with the keys row on a phone. The text grows and shrinks with two fingers.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../terminal/rg_terminal.dart';
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

/// The person's own shell (G42.5: a real terminal, `RgTerminal`), with the keys row on a phone.
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
  late bool _open = widget.autoOpen && !widget.ctx.readOnly;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (!_open) {
      return Center(
        child: SingleChildScrollView(
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
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('term-open'),
                  onPressed: widget.ctx.readOnly ? null : () => setState(() => _open = true),
                  icon: const RgIcon(RgIcons.terminal, size: 18, color: Colors.white),
                  label: Text(l.codeTermOpen),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return RgTerminal(
      key: const Key('own-terminal'),
      client: widget.ctx.client,
      scope: widget.ctx.scope,
      font: widget.font,
      keys: !widget.compact,
      command: widget.command,
    );
  }
}
