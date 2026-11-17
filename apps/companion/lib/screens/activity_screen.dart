// Activity (G40.7): the tasks (RD17) of every project, in progress and done, grouped by agent,
// each with its bar: running (moving), the steps of its conversation's todo list when it is open,
// full when it closed (verified, not testable, abandoned). A tap shows the verifiers it ran.
import 'package:flutter/material.dart';

import '../api/conversation.dart';
import '../api/live_model.dart';
import '../api/turn_queue.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import '../ui/turn_queue_view.dart';
import 'conversation_screen.dart';

/// Tasks grouped by agent, in progress first, the latest first.
List<({String agent, List<TaskRow> tasks})> tasksByAgent(List<TaskRow> tasks) {
  final g = <String, List<TaskRow>>{};
  for (final t in tasks) {
    (g[t.agentName] ??= []).add(t);
  }
  int order(TaskRow a, TaskRow b) =>
      a.done != b.done ? (a.done ? 1 : -1) : b.openedAt.compareTo(a.openedAt);
  final out = [for (final e in g.entries) (agent: e.key, tasks: e.value..sort(order))];
  out.sort((a, b) {
    final ao = a.tasks.any((t) => !t.done), bo = b.tasks.any((t) => !t.done);
    return ao != bo ? (ao ? -1 : 1) : a.agent.compareTo(b.agent);
  });
  return out;
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Future<List<TaskRow>>? _tasks;
  Object? _client;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (app.client != _client) {
      _client = app.client;
      _tasks = _fetch();
    }
  }

  Future<List<TaskRow>>? _fetch() {
    final c = AppScope.read(context).client;
    return c == null ? null : allTasks(c);
  }

  void _reload() {
    final f = _fetch();
    setState(() {
      _tasks = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: l.tabActivity,
          trailing: app.connected
              ? IconButton(
                  key: const Key('activity-refresh'),
                  tooltip: l.refresh,
                  onPressed: _reload,
                  icon: RgIcon(RgIcons.refresh, size: 20, color: c.dim),
                )
              : null,
        ),
        Expanded(
          child: _tasks == null
              ? EmptyState(icon: RgIcons.list, text: l.connectFromYou)
              : FutureBuilder<List<TaskRow>>(
                  future: _tasks,
                  builder: (context, s) {
                    if (s.hasError) {
                      return EmptyState(icon: RgIcons.alert, text: l.openFailed);
                    }
                    if (!s.hasData) return const Center(child: CircularProgressIndicator());
                    final groups = tasksByAgent(s.data!);
                    if (groups.isEmpty) {
                      return EmptyState(icon: RgIcons.list, text: l.activityEmpty);
                    }
                    return ListenableBuilder(
                      listenable: app.live,
                      builder: (context, _) => RefreshIndicator(
                        onRefresh: () async => _reload(),
                        child: ListView(
                          key: const Key('activity-list'),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            for (final g in groups) ...[
                              Semantics(
                                header: true,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                                  child: Text(
                                    g.agent,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: c.dim,
                                    ),
                                  ),
                                ),
                              ),
                              for (final t in g.tasks)
                                TaskTile(
                                  task: t,
                                  running: app.live.sessions.any(
                                    (x) => x.id == t.sessionId && x.running,
                                  ),
                                  todos: t.sessionId == null
                                      ? null
                                      : todosOf(app.live.views[t.sessionId]?.events ?? const []),
                                  queued: t.sessionId == null || t.done
                                      ? null
                                      : app.live.turns.placeOf(t.sessionId!),
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

String outcomeWord(AppLocalizations l, TaskOutcome o, bool running) => switch (o) {
  TaskOutcome.open => running ? l.taskRunning : l.taskOpen,
  TaskOutcome.verified => l.taskVerified,
  TaskOutcome.notTestable => l.taskNotTestable,
  TaskOutcome.abandoned => l.taskAbandoned,
};

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.running, this.todos, this.queued});

  final TaskRow task;
  final bool running;
  final ({int done, int total})? todos;

  /// Its conversation waits for a place (3.8.10).
  final LinePlace? queued;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final t = task;
    final color = switch (t.outcome) {
      TaskOutcome.open => running ? c.ok : c.dim,
      TaskOutcome.verified => c.ok,
      TaskOutcome.notTestable => c.warn,
      TaskOutcome.abandoned => c.err,
    };
    final td = todos;
    final double? value = t.done
        ? 1
        : td != null && td.total > 0
        ? td.done / td.total
        : running
        ? null
        : 0;
    final word = outcomeWord(l, t.outcome, running);
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
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (_) => TaskDetail(task: t),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.title,
                        style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
                      ),
                    ),
                    if (queued != null) ...[
                      const SizedBox(width: 8),
                      QueuePill(key: Key('task-queued-${t.id}'), place: queued!, dense: true),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: word,
                  value: value == null ? null : '${(value * 100).round()}%',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      color: color,
                      backgroundColor: c.panel2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  td != null && !t.done ? '$word · ${td.done}/${td.total}' : word,
                  style: TextStyle(fontSize: 12.5, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A task's details: its steps and the verifiers its conversation ran (from the history).
class TaskDetail extends StatefulWidget {
  const TaskDetail({super.key, required this.task});

  final TaskRow task;

  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  late final AppController app;
  SessionView? view;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
    final sid = widget.task.sessionId;
    if (sid != null) view = app.follow(sid);
  }

  @override
  void dispose() {
    final sid = widget.task.sessionId;
    if (sid != null) app.unfollow(sid);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final t = widget.task;
    final v = view;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: ListenableBuilder(
          listenable: v ?? app.live,
          builder: (context, _) {
            final events = v?.events ?? const <RgEvent>[];
            final verifiers = verifiersOf(events).where((x) => x.taskId == t.id).toList();
            final todos = todosOf(events);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
                ),
                Text(t.agentName, style: TextStyle(color: c.dim)),
                const SizedBox(height: 12),
                if (todos != null)
                  Text(l.taskSteps(todos.done, todos.total), style: TextStyle(color: c.text)),
                const SizedBox(height: 8),
                Text(
                  l.verifiers,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.dim, fontSize: 13),
                ),
                if (verifiers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      v != null && !v.synced && app.isLive ? l.loading : l.noVerifier,
                      style: TextStyle(color: c.dim),
                    ),
                  ),
                for (final x in verifiers)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RgIcon(
                          x.passed ? RgIcons.check : RgIcons.x,
                          size: 16,
                          color: x.passed ? c.ok : c.err,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SelectableText(
                            x.verifier,
                            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (t.sessionId != null)
                  FilledButton(
                    key: const Key('task-open'),
                    onPressed: () {
                      final agent = app.agents.where((a) => a.id == t.agentId).firstOrNull;
                      Navigator.of(context)
                        ..pop()
                        ..push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ConversationScreen(sessionId: t.sessionId!, agent: agent),
                          ),
                        );
                    },
                    child: Text(l.openConversation),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
