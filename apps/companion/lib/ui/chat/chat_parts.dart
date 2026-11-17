// The conversation's smaller pieces (G42.1), as the page's Chat.tsx and ChatTools.tsx draw them:
// the agent's steps pinned above the composer (`Todos`), the mark where it was summarised
// (`CompactionMark`, with «Annulla» for the last one asked by hand), where a copy of another
// conversation starts (`ForkMark`), «Continua» under the summary at the step limit (`GoOn`), a
// cache that was missed, the notices, a line for a file shown in the canvas, a board of
// variants, a message waiting in line with «togli», the same agent at work elsewhere
// (`Elsewhere`) and the archived project's line where the composer was (`ArchivedNotice`).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../api/conversation.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';
import '../markdown.dart';
import '../pause_agent.dart';

/// The agent's list of steps (update_todos), pinned above the composer until every step is done
/// and the agent has stopped.
class TodosPanel extends StatefulWidget {
  const TodosPanel({super.key, required this.items, required this.running});

  final List<ChatItem> items;
  final bool running;

  @override
  State<TodosPanel> createState() => _TodosPanelState();
}

class _TodosPanelState extends State<TodosPanel> {
  bool _folded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final todos = latestTodos(widget.items);
    final done = todos.where((x) => x.status == 'completed').length;
    if (todos.isEmpty || (done == todos.length && !widget.running)) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Container(
          key: const Key('todos'),
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                key: const Key('todos-head'),
                onTap: () => setState(() => _folded = !_folded),
                child: Row(
                  children: [
                    RgIcon(
                      _folded ? RgIcons.chevronRight : RgIcons.chevronDown,
                      size: 12,
                      color: c.dim,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l.cvTodosTitle('$done', '${todos.length}'),
                      style: TextStyle(color: c.dim, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (!_folded)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final x in todos)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: SizedBox(
                                    width: 12,
                                    child: switch (x.status) {
                                      'completed' => _Dot(filled: true, color: c.ok),
                                      'in_progress' => RgSpinner(size: 12, color: c.text),
                                      _ => _Dot(filled: false, color: c.dim),
                                    },
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    x.content,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: x.status == 'completed' ? c.dim : c.text,
                                      decoration: x.status == 'completed'
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

class _Dot extends StatelessWidget {
  const _Dot({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? color : null,
      border: Border.all(color: color),
    ),
  );
}

/// «La conversazione è stata riassunta qui»: the summary opens; the last one asked by hand undoes.
class CompactionMark extends StatefulWidget {
  const CompactionMark({super.key, required this.item, required this.sessionId});

  final CompactionItem item;
  final String sessionId;

  @override
  State<CompactionMark> createState() => _CompactionMarkState();
}

class _CompactionMarkState extends State<CompactionMark> {
  bool _open = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final it = widget.item;
    final words = it.undone
        ? l.cvCompactionUndone
        : switch (it.reason) {
            'manual' => l.cvCompactionManual,
            'emergency' => l.cvCompactionEmergency,
            'engine' => l.cvCompactionEngine,
            _ => l.cvCompactionAuto,
          };
    return Container(
      key: Key('compaction-${it.seq}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: it.summary.isEmpty ? null : () => setState(() => _open = !_open),
                  child: Row(
                    children: [
                      RgIcon(RgIcons.layers, size: 13, color: c.dim),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          words,
                          style: TextStyle(
                            color: c.dim,
                            fontSize: 12.5,
                            decoration: it.undone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (it.summary.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        RgIcon(
                          _open ? RgIcons.chevronDown : RgIcons.chevronRight,
                          size: 12,
                          color: c.dim,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (it.undoable)
                TextButton(
                  key: Key('compaction-undo-${it.seq}'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          // The «undone» event arrives live and marks this summary.
                          await AppScope.read(context).undoCompaction(widget.sessionId);
                          if (mounted) setState(() => _busy = false);
                        },
                  child: Text(l.cvUndo),
                ),
            ],
          ),
          if (_open && it.summary.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6), child: SafeMarkdown(it.summary)),
        ],
      ),
    );
  }
}

/// Where this conversation's own part starts, with the way back to the one it comes from.
class ForkMark extends StatelessWidget {
  const ForkMark({super.key, required this.item, this.onOpen});

  final ForkItem item;
  final void Function(String sessionId)? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.maybeRead(context);
    final title =
        app?.live.sessions.where((r) => r.id == item.fromSessionId).firstOrNull?.title ??
        item.fromTitle ??
        l.cvForkOrigin;
    Widget line() => Expanded(child: Container(height: 1, color: c.line));
    return Padding(
      key: Key('fork-${item.key}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          line(),
          const SizedBox(width: 8),
          RgIcon(RgIcons.branch, size: 13, color: c.dim),
          const SizedBox(width: 6),
          Flexible(
            flex: 4,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                Text(
                  item.how == 'continue' ? l.cvForkStartsHere : l.cvForkEdited,
                  style: TextStyle(color: c.dim, fontSize: 12),
                ),
                InkWell(
                  key: Key('fork-back-${item.fromSessionId}'),
                  onTap: onOpen == null ? null : () => onOpen!(item.fromSessionId),
                  child: Text(l.cvForkBack(title), style: TextStyle(color: c.accent, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          line(),
        ],
      ),
    );
  }
}

/// Under the closing summary at the step limit: one tap says «Continua» for the person.
class GoOnButton extends StatefulWidget {
  const GoOnButton({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<GoOnButton> createState() => _GoOnButtonState();
}

class _GoOnButtonState extends State<GoOnButton> {
  bool _sent = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: l.cvStepLimitContinueHint,
        child: Opacity(
          opacity: _sent ? .55 : 1,
          child: Material(
            color: c.accentSoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: c.accent),
            ),
            child: InkWell(
              key: const Key('go-on'),
              borderRadius: BorderRadius.circular(8),
              onTap: _sent
                  ? null
                  : () {
                      setState(() => _sent = true);
                      AppScope.read(context).send(widget.sessionId, l.cvStepLimitGoOn);
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RgIcon(RgIcons.play, size: 11, color: c.text, filled: true),
                    const SizedBox(width: 6),
                    Text(l.cvStepLimitContinue, style: TextStyle(color: c.text, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A notice of the log (`.notice`): its colour by tone, a drawn icon, never a symbol.
class NoticeLine extends StatelessWidget {
  const NoticeLine({super.key, required this.level, required this.text, this.trailing});

  final NoticeLevel level;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final color = switch (level) {
      NoticeLevel.error => c.err,
      NoticeLevel.warn => c.warnText,
      NoticeLevel.ok => c.ok,
      NoticeLevel.info => c.dim,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RgIcon(
              level == NoticeLevel.error || level == NoticeLevel.warn
                  ? RgIcons.alert
                  : RgIcons.info,
              size: 13,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(text, style: TextStyle(color: color, fontSize: 13)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The words of a notice item (the codes the page says with `t()`).
String noticeText(AppLocalizations l, NoticeItem n, String lang) {
  if (n.code == 'imported') {
    final at = DateTime.tryParse(n.params['date'] ?? '');
    final date = at == null
        ? ''
        : ' (${lang == 'it' ? '${at.day}/${at.month}/${at.year}' : '${at.month}/${at.day}/${at.year}'})';
    return l.cvImpChatNotice(n.params['source'] ?? n.text, date);
  }
  return n.text;
}

/// A line in the agent's message (G34.1): «Ha aperto (file) nel Canvas», a tap shows it again.
class CanvasLine extends StatelessWidget {
  const CanvasLine({super.key, required this.title, required this.onTap, this.icon = RgIcons.file});

  final String title;
  final VoidCallback? onTap;
  final RgIcons icon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final words = l.cvCanvasOpened('\u0000').split('\u0000');
    return Align(
      alignment: Alignment.centerLeft,
      child: Tooltip(
        message: l.cvCanvasShown,
        child: Material(
          color: c.panel,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RgIcon(icon, size: 15, color: c.dim),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: words.first,
                        children: [
                          TextSpan(
                            text: title,
                            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                          ),
                          if (words.length > 1) TextSpan(text: words[1]),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.dim, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// On a phone (G42.2): what the agent showed in the Canvas as a card the size of a finger, the
/// whole width: its name, what it is (a site on a port, or a file) and «Apri»; the Canvas whole.
class CanvasCard extends StatelessWidget {
  const CanvasCard({super.key, required this.title, required this.onTap, this.port, this.path});

  final String title;
  final VoidCallback? onTap;

  /// An agent's port (a site), or null for a file.
  final int? port;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final what = port != null
        ? [l.cvEmbedPort('$port'), if (path != null && path!.isNotEmpty) path!].join(' · ')
        : (path ?? '');
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.accentDim,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: RgIcon(
                    port != null ? RgIcons.globe : RgIcons.file,
                    size: 20,
                    color: c.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      what.isEmpty ? l.cvCanvasShown : what,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.dim, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l.cvArOpen,
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
              ),
              RgIcon(RgIcons.chevronRight, size: 16, color: c.accent),
            ],
          ),
        ),
      ),
    );
  }
}

/// A board of variants (G25.4): what the person chose, or that it waits.
class VariantsCard extends StatelessWidget {
  const VariantsCard({super.key, required this.item, this.onOpen});

  final VariantsItem item;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(RgIcons.canvas, size: 16, color: c.accent),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        item.chosen == null
                            ? l.cvBoardWaiting('${item.count}')
                            : l.cvBoardDone('${item.chosen}'),
                        style: TextStyle(color: c.dim, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A message sent while the agent works: in line, a little faded, with «togli».
class QueuedBubble extends StatelessWidget {
  const QueuedBubble({super.key, required this.text, required this.onRemove});

  final String text;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: l.cvSentWhileWorking,
        child: Opacity(
          opacity: .7,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            decoration: BoxDecoration(
              color: c.user,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(text, style: TextStyle(color: c.text, fontSize: 15)),
                ),
                IconButton(
                  key: const Key('unqueue'),
                  tooltip: l.cvUnqueue,
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: RgIcon(RgIcons.x, size: 13, color: c.dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The same agent (or one under it) at work in another conversation, or asking there.
class ElsewhereLine extends StatelessWidget {
  const ElsewhereLine({
    super.key,
    required this.agentName,
    required this.title,
    required this.asks,
    required this.onOpen,
  });

  final String agentName;
  final String title;
  final bool asks;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          RgIcon(RgIcons.info, size: 13, color: c.text),
          Text(
            asks ? l.cvElsewhereAsks(agentName, title) : l.cvElsewhereWorking(agentName, title),
            style: TextStyle(color: c.text, fontSize: 13),
          ),
          InkWell(
            onTap: onOpen,
            child: Text(l.cvOpen, style: TextStyle(color: c.accent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Where the composer was, in a removed agent's conversation (3.8.9): read only; «Removed agents»
/// brings it back.
class RemovedNotice extends StatelessWidget {
  const RemovedNotice({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('removed-notice'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          RgIcon(RgIcons.lock, size: 15, color: c.dim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.raReadOnly(name), style: TextStyle(color: c.text, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// Where the composer was, in a stopped agent's conversation (3.8.9, a pause): read only, with
/// «Resume», which brings it back and lets its open tasks go on here.
class StoppedNotice extends StatefulWidget {
  const StoppedNotice({super.key, required this.agent});

  final Agent agent;

  @override
  State<StoppedNotice> createState() => _StoppedNoticeState();
}

class _StoppedNoticeState extends State<StoppedNotice> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('stopped-notice'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          RgIcon(RgIcons.pause, size: 15, color: c.dim),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.paReadOnly(widget.agent.name),
              style: TextStyle(color: c.text, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            key: const Key('stopped-resume'),
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await resumeAgentNow(context, widget.agent);
                    if (mounted) setState(() => _busy = false);
                  },
            child: Text(l.paResume),
          ),
        ],
      ),
    );
  }
}

/// Where the composer was, in a conversation of an archived project: read only, «Ripristina».
class ArchivedNotice extends StatefulWidget {
  const ArchivedNotice({super.key, required this.project});

  final Project project;

  @override
  State<ArchivedNotice> createState() => _ArchivedNoticeState();
}

class _ArchivedNoticeState extends State<ArchivedNotice> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final warnLine = Color.lerp(c.warn, c.line, .45)!;
    return Container(
      key: const Key('archived-notice'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color.lerp(c.panel, c.warn, .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: warnLine),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: Color.lerp(c.panel, c.warn, .14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: warnLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(RgIcons.archive, size: 13, color: c.warnText),
                const SizedBox(width: 5),
                Text(
                  l.cvPaBadge,
                  style: TextStyle(color: c.warnText, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            l.cvPaChatReadOnly(widget.project.name),
            style: TextStyle(color: c.text, fontSize: 14),
          ),
          FilledButton(
            key: const Key('archived-restore'),
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await AppScope.read(context).restoreProject(widget.project.id);
                    if (mounted) setState(() => _busy = false);
                  },
            child: Text(l.cvPaRestore),
          ),
        ],
      ),
    );
  }
}

/// generate_image's picture as it forms (G42.2, the page's `drawing`, `image.progress`): the last
/// preview (or a frame that shimmers until there is one), a thin bar, «Sto disegnando… n%».
class DrawingCard extends StatefulWidget {
  const DrawingCard({super.key, required this.percent, this.preview});

  final int percent;

  /// The last preview, base64 PNG.
  final String? preview;

  @override
  State<DrawingCard> createState() => _DrawingCardState();
}

class _DrawingCardState extends State<DrawingCard> with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  Uint8List? _bytes;
  String? _of;

  Uint8List? get _picture {
    final p = widget.preview;
    if (p != _of) {
      _of = p;
      try {
        _bytes = p == null ? null : base64Decode(p);
      } on FormatException {
        _bytes = null;
      }
    }
    return _bytes;
  }

  /// The frame shimmers only while there is no preview, and never with «reduce motion».
  void _sync() {
    final run = _picture == null && !MediaQuery.disableAnimationsOf(context);
    if (run && !_shimmer.isAnimating) unawaited(_shimmer.repeat());
    if (!run && _shimmer.isAnimating) _shimmer.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(DrawingCard old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final picture = _picture;
    return Align(
      key: const Key('drawing'),
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: c.line),
                ),
                child: picture != null
                    ? Image.memory(
                        picture,
                        key: const Key('drawing-preview'),
                        gaplessPlayback: true,
                      )
                    : AspectRatio(
                        aspectRatio: 1,
                        child: AnimatedBuilder(
                          animation: _shimmer,
                          builder: (context, _) => DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1 - 2 * _shimmer.value + 1, -.3),
                                end: Alignment(1 - 2 * _shimmer.value + 1, .3),
                                colors: [c.panel2, c.line, c.panel2],
                                stops: const [.4, .5, .6],
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: widget.percent / 100,
                minHeight: 4,
                color: c.accent,
                backgroundColor: c.panel2,
              ),
            ),
            const SizedBox(height: 6),
            Text(l.cvDrawing('${widget.percent}'), style: TextStyle(color: c.dim, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
