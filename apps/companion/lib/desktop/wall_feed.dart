// What the wall shows moving (G40.17): the latest actions of every project's agents (the project
// log, `GET /api/projects/:id/events`, read again every few seconds while the wall is in sight
// and the window in front) and, with the advanced interface, each project's state: branch,
// commits to send, changes, the last commit and the open tasks with their verifier.
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../api/code.dart';
import '../api/conversation.dart';
import '../app_state.dart';

/// The events that are an agent's action, for the wall's lines and the events' stream.
bool isAction(ProjectEvent e) =>
    e.error ||
    e.type == 'tool.call' ||
    e.type.startsWith('task.') ||
    e.type.startsWith('approval.') ||
    e.type.startsWith('permission.') ||
    e.type.startsWith('ci.') ||
    e.type == 'agent.blocked' ||
    e.type == 'session.tools_added';

/// One line of a wall tile: short, on one line.
String actionText(ProjectEvent e, {int max = 70}) {
  var s = e.summary.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (s.isEmpty) s = e.type;
  return s.length <= max ? s : '${s.substring(0, max - 1)}…';
}

/// A project's state for the advanced wall.
class ProjectStatus {
  const ProjectStatus({
    this.git,
    this.added = 0,
    this.removed = 0,
    this.files = 0,
    this.last,
    this.tasks = const [],
  });

  final GitState? git;
  final int added;
  final int removed;
  final int files;
  final GitCommit? last;
  final List<TaskRow> tasks;

  List<TaskRow> get open => tasks.where((t) => t.outcome == TaskOutcome.open).toList();
}

class WallFeed extends ChangeNotifier {
  WallFeed(this.app, {this.every = const Duration(seconds: 6), this.statusEvery = 4});

  final AppController app;
  final Duration every;

  /// The projects' state is read every [statusEvery] rounds (it costs more).
  final int statusEvery;

  final Map<String, List<ProjectEvent>> _events = {};
  final Map<String, ProjectStatus> status = {};
  Timer? _timer;
  int _round = 0;
  bool _busy = false;
  bool _disposed = false;

  /// The advanced wall wants the projects' state too.
  bool withStatus = false;

  bool get running => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(every, (_) => unawaited(refresh()));
    unawaited(refresh(status: true));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh({bool status = false}) async {
    final c = app.client;
    if (c == null || _busy || !app.connected) return;
    _busy = true;
    try {
      final projects = app.projects.where((p) => !p.archived).toList();
      for (final p in projects) {
        try {
          final page = await c.projectEvents(p.id, limit: 40);
          _events[p.id] = page.events;
        } on ApiException {
          // Next round.
        }
      }
      _round++;
      if (withStatus && (status || _round % statusEvery == 1)) {
        for (final p in projects) {
          final s = await _statusOf(c, p.id);
          if (s != null) this.status[p.id] = s;
        }
      }
    } finally {
      _busy = false;
    }
    if (!_disposed) notifyListeners();
  }

  Future<ProjectStatus?> _statusOf(RedGiantClient c, String projectId) async {
    try {
      final git = await c.gitState(projectId);
      var added = 0, removed = 0, files = 0;
      GitCommit? last;
      if (git.repo) {
        if (!git.clean) {
          final d = await c.gitDiff(projectId, const DiffSource.working());
          files = d.files.length;
          for (final f in d.files) {
            added += f.added;
            removed += f.removed;
          }
        }
        last = (await c.gitLog(projectId, limit: 1)).firstOrNull;
      }
      final tasks = await c.tasks(projectId);
      return ProjectStatus(
        git: git,
        added: added,
        removed: removed,
        files: files,
        last: last,
        tasks: tasks,
      );
    } on ApiException {
      return null;
    }
  }

  /// [agentId]'s latest actions, oldest first (the tile shows them as they happened).
  List<ProjectEvent> linesOf(String agentId, {int max = 3}) {
    final out = <ProjectEvent>[];
    for (final list in _events.values) {
      out.addAll(list.where((e) => e.agentId == agentId && isAction(e)));
    }
    out.sort((a, b) => b.ts.compareTo(a.ts));
    return out.take(max).toList().reversed.toList();
  }

  /// A project's latest actions, oldest first.
  List<ProjectEvent> projectLines(String projectId, {int max = 2}) =>
      (_events[projectId] ?? const <ProjectEvent>[])
          .where(isAction)
          .take(max)
          .toList()
          .reversed
          .toList();

  /// Every project's actions, newest first (the advanced wall's «stream of events»).
  List<ProjectEvent> recent({int max = 60}) {
    final out = <ProjectEvent>[
      for (final list in _events.values) ...list.where(isAction),
    ]..sort((a, b) => b.ts.compareTo(a.ts));
    return out.take(max).toList();
  }

  /// The project an event came from.
  String? projectOf(ProjectEvent e) {
    for (final entry in _events.entries) {
      if (entry.value.contains(e)) return entry.key;
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    super.dispose();
  }
}
