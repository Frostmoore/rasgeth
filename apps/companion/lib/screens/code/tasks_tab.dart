// Tasks (G40.11): the project's board as one column under the other (In progress, To verify,
// Done), each task with its verifier and the result; a tap opens the agent's thread.
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/conversation.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/icons.dart';
import '../conversation_screen.dart';
import 'project_screen.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key, required this.ctx});

  final ProjectCtx ctx;

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> with AutomaticKeepAliveClientMixin {
  List<TaskRow>? _tasks;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await widget.ctx.client.tasks(widget.ctx.project.id);
      if (mounted)
        setState(() {
          _tasks = t;
          _error = null;
        });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final tasks = _tasks;
    if (tasks == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    }
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [EmptyState(icon: RgIcons.checkSquare, text: l.codeNoTasks)],
        ),
      );
    }
    final columns = [
      (TaskColumn.running, l.codeColRunning),
      (TaskColumn.toVerify, l.codeColToVerify),
      (TaskColumn.done, l.codeColDone),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('tasks-board'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final (col, title) in columns) ...[
            _ColumnHead(title: title, count: tasks.where((t) => t.column == col).length),
            for (final t in tasks.where((t) => t.column == col))
              _TaskCard(ctx: widget.ctx, task: t),
          ],
        ],
      ),
    );
  }
}

class _ColumnHead extends StatelessWidget {
  const _ColumnHead({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: c.text),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(99)),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 12, color: c.dim, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.ctx, required this.task});

  final ProjectCtx ctx;
  final TaskRow task;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final t = task;
    final (String line, Color color) = switch (t.outcome) {
      TaskOutcome.verified => (l.codeTaskVerified, c.ok),
      TaskOutcome.notTestable => (l.codeTaskNotTestable(t.note ?? ''), c.dim),
      TaskOutcome.abandoned => (l.codeTaskAbandoned(t.note ?? ''), c.err),
      TaskOutcome.open =>
        t.verifier == null
            ? (l.codeTaskNoVerifier, c.dim)
            : (
                l.codeTaskVerifier(
                  t.verifier!,
                  t.verified == true ? l.codeTaskPassed : l.codeTaskFailed,
                ),
                t.verified == true ? c.ok : c.warnText,
              ),
    };
    void open() {
      final sid = t.sessionId;
      if (sid == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(sessionId: sid, agent: ctx.agentById(t.agentId)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          key: Key('task-${t.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: t.sessionId == null ? null : open,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                      ),
                      const SizedBox(height: 2),
                      Text(t.agentName, style: TextStyle(color: c.dim, fontSize: 12.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RgIcon(
                            t.outcome == TaskOutcome.verified || t.verified == true
                                ? RgIcons.check
                                : t.outcome == TaskOutcome.abandoned
                                ? RgIcons.x
                                : RgIcons.checkSquare,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              line,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 12.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: Key('task-diff-${t.id}'),
                  tooltip: l.codeTaskDiff,
                  onPressed: () => ctx.openDiff(DiffSource.task(t.id, label: t.title)),
                  icon: RgIcon(RgIcons.diff, size: 19, color: c.dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
