// The background commands of a conversation (G42.3), as the page's CommandStrip.tsx: the running
// ones always in view, with their start, a running time, «Output» and «Ferma» (no confirmation,
// `command.stop`); the finished ones in one line «N finished», opened on demand, with «Remove all
// finished» (`command.close`). The whole strip shrinks to one line and this device remembers it.
// «Output» opens the command's whole log, live while it runs, every line's time on request.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/live_model.dart';
import '../../api/metrics.dart' show duration;
import '../../api/parallel.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../dialogs.dart';
import '../icons.dart';

/// 15:03:12, the same on every system (the page's `hm`).
String hms(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}

String _short(String c) => c.length > 80 ? '${c.substring(0, 77)}...' : c;

/// What a finished command says of itself (the page's `cmdStatus_<status>`).
String commandStatusWords(AppLocalizations l, CommandRow r) {
  final code = r.exitCode?.toString() ?? '-';
  return switch (r.status) {
    'running' => l.cvCmdStatusRunning,
    'done' => l.cvCmdStatusDone(code),
    'failed' => l.cvCmdStatusFailed(code),
    'stopped' => l.cvCmdStatusStopped,
    _ => l.cvCmdStatusInterrupted,
  };
}

int _ms(String a, String b) {
  final x = DateTime.tryParse(a);
  final y = DateTime.tryParse(b);
  return x == null || y == null ? 0 : y.difference(x).inMilliseconds;
}

class CommandStrip extends StatefulWidget {
  const CommandStrip({super.key, required this.sessionId, required this.view});

  final String sessionId;
  final SessionView view;

  @override
  State<CommandStrip> createState() => _CommandStripState();
}

class _CommandStripState extends State<CommandStrip> {
  bool _showDone = false;
  Timer? _tick;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  /// Ticks once a second while something runs.
  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on && _tick != null) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: widget.view,
      builder: (context, _) {
        final rows = commandRows(widget.view.events).where((r) => !r.closed).toList();
        final running = rows.where((r) => r.running).toList();
        final done = rows.where((r) => !r.running).toList();
        _ticking(running.isNotEmpty);
        if (rows.isEmpty) return const SizedBox.shrink();
        return _strip(context, app, running, done);
      },
    );
  }

  Widget _strip(
    BuildContext context,
    AppController app,
    List<CommandRow> running,
    List<CommandRow> done,
  ) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final min = app.commandStripMin;
    final sid = widget.sessionId;
    final now = app.live.now();
    final summary = [
      if (running.isNotEmpty) l.cvCmdRunningN('${running.length}'),
      if (done.isNotEmpty) l.cvCmdDoneN('${done.length}'),
    ].join(' · ');
    final small = TextStyle(
      color: c.dim,
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    Widget output(CommandRow r) => _Link(
      key: Key('cmd-output-${r.id}'),
      text: l.cvCmdOutput,
      onTap: () => showCommandOutput(context, sessionId: sid, id: r.id, view: widget.view),
    );
    return Semantics(
      container: true,
      label: l.cvCmdStrip,
      child: Container(
        key: const Key('cmd-strip'),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .4),
        decoration: BoxDecoration(
          color: c.panel2,
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tooltip(
                message: min ? l.cvCmdOpenStrip : l.cvCmdShrinkStrip,
                child: InkWell(
                  key: const Key('cmd-head'),
                  onTap: () => app.setCommandStripMin(!min),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Row(
                      children: [
                        RgIcon(RgIcons.terminal, size: 13, color: c.dim),
                        const SizedBox(width: 8),
                        StateDot(running.isNotEmpty ? 'running' : 'done'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(summary, style: TextStyle(color: c.dim, fontSize: 13)),
                        ),
                        RgIcon(
                          min ? RgIcons.chevronRight : RgIcons.chevronDown,
                          size: 13,
                          color: c.dim,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!min) ...[
                for (final (i, r) in running.indexed)
                  _Row(
                    key: Key('cmd-row-${r.id}'),
                    dashed: i > 0,
                    dot: 'running',
                    command: r.command,
                    time: Text(
                      '${hms(r.startedAt)} · ${duration(now.difference(DateTime.parse(r.startedAt)).inMilliseconds)}',
                      style: small,
                    ),
                    actions: [
                      output(r),
                      _StopButton(
                        key: Key('cmd-stop-${r.id}'),
                        onTap: () => app.stopCommand(sid, r.id),
                      ),
                    ],
                  ),
                if (done.isNotEmpty)
                  _Dashed(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          InkWell(
                            key: const Key('cmd-done-toggle'),
                            onTap: () => setState(() => _showDone = !_showDone),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RgIcon(
                                    _showDone ? RgIcons.chevronDown : RgIcons.chevronRight,
                                    size: 12,
                                    color: c.accent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l.cvCmdFinishedN('${done.length}'),
                                    style: TextStyle(color: c.accent, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          _Link(
                            key: const Key('cmd-remove-finished'),
                            text: l.cvCmdRemoveFinished,
                            onTap: () {
                              for (final r in done) {
                                app.closeCommand(sid, r.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_showDone)
                  for (final r in done)
                    _Row(
                      key: Key('cmd-row-${r.id}'),
                      dashed: true,
                      dot: r.status,
                      command: r.command,
                      time: Text(
                        [
                          hms(r.startedAt),
                          if (r.endedAt != null) duration(_ms(r.startedAt, r.endedAt!)),
                          commandStatusWords(l, r),
                        ].join(' · '),
                        style: small,
                      ),
                      actions: [
                        output(r),
                        Tooltip(
                          message: l.cvCmdRemove,
                          child: InkWell(
                            key: Key('cmd-x-${r.id}'),
                            borderRadius: BorderRadius.circular(4),
                            onTap: () => app.closeCommand(sid, r.id),
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: RgIcon(RgIcons.x, size: 11, color: c.dim),
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The state's dot (the page's `.cmd-dot` and `.sub-dot`): green with a halo while it runs, red
/// when it failed or was stopped, grey otherwise.
class StateDot extends StatelessWidget {
  const StateDot(this.status, {super.key, this.size = 8});

  final String status;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = switch (status) {
      'running' => c.ok,
      'failed' || 'stopped' || 'interrupted' => c.err,
      _ => c.dim,
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: col,
        shape: BoxShape.circle,
        boxShadow: status == 'running'
            ? [BoxShadow(color: c.ok.withValues(alpha: .25), spreadRadius: 3)]
            : null,
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: DashedTopLine(RgColors.of(context).line), child: child);
}

/// A dashed line on top (the page's `border-top: 1px dashed var(--line)`).
class DashedTopLine extends CustomPainter {
  DashedTopLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, .5), Offset(x + 3, .5), p);
    }
  }

  @override
  bool shouldRepaint(DashedTopLine old) => old.color != color;
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.dashed,
    required this.dot,
    required this.command,
    required this.time,
    required this.actions,
  });

  final bool dashed;
  final String dot;
  final String command;
  final Widget time;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final text = Tooltip(
      message: command,
      child: Text(
        _short(command),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.text),
      ),
    );
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      // Narrow (the page's 700 px): the time and the buttons go under the command.
      child: LayoutBuilder(
        builder: (context, box) {
          final gap = <Widget>[
            for (final a in actions) ...[const SizedBox(width: 10), a],
          ];
          if (box.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StateDot(dot),
                    const SizedBox(width: 8),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      Flexible(child: time),
                      const Spacer(),
                      ...gap,
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              StateDot(dot),
              const SizedBox(width: 10),
              Expanded(child: text),
              const SizedBox(width: 10),
              time,
              ...gap,
            ],
          );
        },
      ),
    );
    return dashed ? _Dashed(child: row) : row;
  }
}

class _Link extends StatelessWidget {
  const _Link({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Text(text, style: TextStyle(color: c.accent, fontSize: 13)),
      ),
    );
  }
}

/// «Ferma» (the page's `.cmd-stop`): red words and a thin red border.
class _StopButton extends StatelessWidget {
  const _StopButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color.lerp(c.line, c.err, .45)!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RgIcon(RgIcons.stop, size: 11, color: c.err),
            const SizedBox(width: 5),
            Text(l.cvCmdStop, style: TextStyle(color: c.err, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// «Output»: the command's whole log in our window, read again every 2 s while it runs.
Future<void> showCommandOutput(
  BuildContext context, {
  required String sessionId,
  required String id,
  required SessionView view,
}) => showRgWindow<void>(
  context: context,
  builder: (_) => CommandOutputWindow(sessionId: sessionId, id: id, view: view),
);

class CommandOutputWindow extends StatefulWidget {
  const CommandOutputWindow({
    super.key,
    required this.sessionId,
    required this.id,
    required this.view,
  });

  final String sessionId;
  final String id;
  final SessionView view;

  @override
  State<CommandOutputWindow> createState() => _CommandOutputWindowState();
}

class _CommandOutputWindowState extends State<CommandOutputWindow> {
  final _lines = <CommandLine>[];
  CommandOutput? _head;
  bool _times = false;
  bool _missing = false;
  int _last = 0;
  Timer? _timer;
  final _scroll = ScrollController();
  late final AppController _app = AppScope.read(context);

  CommandRow? get _row =>
      commandRows(widget.view.events).where((r) => r.id == widget.id).firstOrNull;

  @override
  void initState() {
    super.initState();
    unawaited(_pull());
    widget.view.addListener(_changed);
    _schedule();
  }

  void _changed() {
    if (!mounted) return;
    _schedule();
    setState(() {});
  }

  void _schedule() {
    final running = _row?.running ?? false;
    if (running && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_pull()));
    } else if (!running && _timer != null) {
      _timer?.cancel();
      _timer = null;
      unawaited(_pull());
    }
  }

  Future<void> _pull() async {
    final c = _app.client;
    if (c == null) return;
    try {
      final r = await c.commandOutput(
        widget.sessionId,
        widget.id,
        from: _last > 0 ? _last + 1 : null,
      );
      if (!mounted) return;
      final follow = !_scroll.hasClients || _scroll.position.maxScrollExtent - _scroll.offset < 80;
      setState(() {
        _head = r;
        if (r.lines.isNotEmpty) {
          _last = r.lines.last.n;
          _lines.addAll(r.lines);
          if (_lines.length > 5000) _lines.removeRange(0, _lines.length - 5000);
        }
      });
      if (follow) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
        });
      }
    } on Exception {
      if (mounted) setState(() => _missing = true);
    }
  }

  @override
  void dispose() {
    widget.view.removeListener(_changed);
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final row = _row;
    String when(String iso) {
      final d = DateTime.tryParse(iso)?.toLocal();
      return d == null
          ? iso
          : '${MaterialLocalizations.of(context).formatShortDate(d)} ${hms(iso)}';
    }

    Widget meta(String k, String v) => Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: TextStyle(color: c.dim, fontSize: 12)),
          ),
          Expanded(
            child: Text(v, style: TextStyle(color: c.text, fontSize: 12)),
          ),
        ],
      ),
    );
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      key: const Key('cmd-output'),
      backgroundColor: c.panel,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 760, maxHeight: size.height * .9),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 10, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.cvCmdOutputTitle,
                      style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    key: const Key('cmd-output-close'),
                    tooltip: l.cvClose,
                    onPressed: () => Navigator.pop(context),
                    icon: RgIcon(RgIcons.x, size: 18, color: c.dim),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.panel2,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        row?.command ?? '',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.text),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (row != null) ...[
                      meta(l.cvCmdStarted, _head?.started ?? when(row.startedAt)),
                      if (row.endedAt != null)
                        meta(l.cvCmdEnded, '${when(row.endedAt!)} · ${commandStatusWords(l, row)}'),
                      meta(l.cvCmdFolder, _head?.folder ?? row.cwd),
                      meta(l.cvCmdBy, _head?.by ?? row.by),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        InkWell(
                          key: const Key('cmd-times'),
                          onTap: () => setState(() => _times = !_times),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SmallSwitch(on: _times),
                              const SizedBox(width: 8),
                              Text(l.cvCmdShowTimes, style: TextStyle(color: c.text, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l.cvCmdLines('${_lines.length}'),
                          style: TextStyle(color: c.dim, fontSize: 13),
                        ),
                        const Spacer(),
                        if (row?.running ?? false)
                          _StopButton(
                            key: const Key('cmd-output-stop'),
                            onTap: () => _app.stopCommand(widget.sessionId, widget.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Container(
                    key: const Key('cmd-output-lines'),
                    constraints: const BoxConstraints(minHeight: 160),
                    decoration: BoxDecoration(
                      // The page's terminal colours (`.cmd-output-lines`), the same in both themes.
                      color: const Color(0xFF11141A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _missing && _lines.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              l.cvCmdNoLog,
                              style: const TextStyle(color: Color(0xFF8A93A3), fontSize: 12),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            itemCount: _lines.length,
                            itemBuilder: (context, i) {
                              final ln = _lines[i];
                              return Text.rich(
                                TextSpan(
                                  children: [
                                    if (_times)
                                      TextSpan(
                                        text: '${ln.clock} +${ln.at.toStringAsFixed(1)}s ',
                                        style: const TextStyle(color: Color(0xFF8A93A3)),
                                      ),
                                    TextSpan(text: ln.text.isEmpty ? ' ' : ln.text),
                                  ],
                                ),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.45,
                                  color: ln.err ? const Color(0xFFFF9B8F) : const Color(0xFFE6E6E6),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's small `.cmd-switch` (28 x 16): ours, never a native switch.
class _SmallSwitch extends StatelessWidget {
  const _SmallSwitch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      toggled: on,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 16,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: on ? c.accent : c.line,
          borderRadius: BorderRadius.circular(8),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: c.panel, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
