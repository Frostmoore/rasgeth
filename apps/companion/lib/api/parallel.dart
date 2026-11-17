// Parallel work in a conversation (G42.3), as the page's state.ts: the sub-agents' tabs
// (`subagentTabs`, `subStatus`, `handedOver` in Chat.tsx) and the background commands' strip
// (`commandRows`). Pure: events in, rows out, checked against the page with shared vectors
// (tool/parallel_fixtures.mjs -> test/fixtures/parallel_vectors.json).
import 'conversation.dart';

/// A sub-agent started from a conversation: its tab there (the page's `SubTab`).
class SubTab {
  SubTab({
    required this.childSessionId,
    required this.childAgentId,
    required this.via,
    required this.title,
    required this.task,
    required this.fromSeq,
    required this.startedAt,
    this.callId,
  });

  final String childSessionId;
  final String childAgentId;
  final String? callId;
  final String via;
  final String title;
  final String task;

  /// Its part of its conversation: the events after this one (a work conversation is reused).
  final int fromSeq;
  final String startedAt;
  String? endedAt;

  /// null while no end is recorded (working, or died with a restart): done, failed or stopped.
  String? ended;
  String? summary;
  bool closed = false;

  Map<String, Object?> toJson() => {
    'childSessionId': childSessionId,
    'childAgentId': childAgentId,
    if (callId != null) 'callId': callId,
    'via': via,
    'title': title,
    'task': task,
    'fromSeq': fromSeq,
    'startedAt': startedAt,
    if (endedAt != null) 'endedAt': endedAt,
    if (ended != null) 'ended': ended,
    if (summary != null) 'summary': summary,
    'closed': closed,
  };
}

String _s(Object? o) => o is String ? o : '';
String? _so(Object? o) => o is String ? o : null;

/// The tabs of a conversation's sub-agents, from its events. A new task reopens a tab.
List<SubTab> subagentTabs(Iterable<RgEvent> events) {
  final tabs = <String, SubTab>{};
  for (final e in events) {
    final p = e.payload;
    if (p == null) continue;
    switch (e.type) {
      case 'subagent.started':
        final child = _s(p['childSessionId']);
        final via = _s(p['via']);
        // The same conversation given work again (a persistent agent): the tab follows the newest.
        tabs.remove(child);
        tabs[child] = SubTab(
          childSessionId: child,
          childAgentId: _s(p['childAgentId']),
          callId: _so(p['callId']),
          via: via,
          title: _s(p['title']),
          task: _s(p['task']),
          // A brand-new conversation is all its own; a reused one from this task on.
          fromSeq: via.startsWith('run_subagent') ? 0 : e.seq,
          startedAt: e.ts,
        );
      case 'subagent.ended':
        final tab = tabs[_s(p['childSessionId'])];
        if (tab != null) {
          tab.ended = _so(p['status']);
          tab.endedAt = e.ts;
          tab.summary = _so(p['summary']);
        }
      case 'subagent.closed':
        tabs[_s(p['childSessionId'])]?.closed = true;
    }
  }
  return tabs.values.toList();
}

/// What a tab's dot says: running, done, failed or stopped (also: died with a restart).
String subStatus(SubTab tab, {required bool childRunning, required bool parentRunning}) =>
    tab.ended ?? (childRunning || parentRunning ? 'running' : 'stopped');

/// The sub-agents this conversation handed work to that are still at it: no end recorded, and
/// the list says their conversation runs ([runningOf]: null when it does not know it yet, then
/// only while this conversation's turn runs: a tab left open by a restart is not work).
List<SubTab> handedOver(
  Iterable<RgEvent> events, {
  required bool parentRunning,
  required bool? Function(String sessionId) runningOf,
}) => [
  for (final tab in subagentTabs(events))
    if (tab.ended == null && (runningOf(tab.childSessionId) ?? parentRunning)) tab,
];

/// A background command as the strip shows it (the page's `CommandRow`).
class CommandRow {
  CommandRow({
    required this.id,
    required this.command,
    required this.by,
    required this.cwd,
    required this.path,
    required this.startedAt,
  });

  final String id;
  final String command;
  final String by;
  final String cwd;
  final String path;
  final String startedAt;
  String? endedAt;

  /// running, done, failed, stopped or interrupted.
  String status = 'running';
  int? exitCode;
  bool closed = false;

  bool get running => status == 'running';

  Map<String, Object?> toJson() => {
    'id': id,
    'command': command,
    'by': by,
    'cwd': cwd,
    'path': path,
    'startedAt': startedAt,
    if (endedAt != null) 'endedAt': endedAt,
    'status': status,
    'exitCode': exitCode,
    'closed': closed,
  };
}

/// The background commands of a conversation, from its events.
List<CommandRow> commandRows(Iterable<RgEvent> events) {
  final rows = <String, CommandRow>{};
  for (final e in events) {
    final p = e.payload;
    if (p == null) continue;
    switch (e.type) {
      case 'command.started':
        final id = _s(p['id']);
        rows[id] = CommandRow(
          id: id,
          command: _s(p['command']),
          by: _s(p['by']),
          cwd: _s(p['cwd']),
          path: _s(p['path']),
          startedAt: e.ts,
        );
      case 'command.ended':
        final r = rows[_s(p['id'])];
        if (r != null) {
          r.status = _s(p['status']);
          r.exitCode = (p['exitCode'] as num?)?.toInt();
          r.endedAt = e.ts;
        }
      case 'command.closed':
        rows[_s(p['id'])]?.closed = true;
    }
  }
  return rows.values.toList();
}

/// One line of a command's log (`GET /api/sessions/:id/commands/:cmd/output`).
class CommandLine {
  const CommandLine({
    required this.n,
    required this.clock,
    required this.at,
    required this.err,
    required this.text,
  });

  factory CommandLine.fromJson(Map<String, dynamic> j) => CommandLine(
    n: (j['n'] as num?)?.toInt() ?? 0,
    clock: _s(j['clock']),
    at: (j['at'] as num?)?.toDouble() ?? 0,
    err: j['stream'] == 'err',
    text: _s(j['text']),
  );

  final int n;
  final String clock;
  final double at;
  final bool err;
  final String text;
}

/// A command's log as the server reads it: its head and the lines from the one asked.
class CommandOutput {
  const CommandOutput({
    required this.lines,
    required this.running,
    this.started,
    this.folder,
    this.by,
  });

  factory CommandOutput.fromJson(Map<String, dynamic> j) {
    final log = j['log'] is Map<String, dynamic> ? j['log'] as Map<String, dynamic> : const {};
    return CommandOutput(
      started: _so(log['started']),
      folder: _so(log['folder']),
      by: _so(log['by']),
      running: j['running'] == true,
      lines: [
        for (final l in (j['lines'] as List? ?? const []).whereType<Map<String, dynamic>>())
          CommandLine.fromJson(l),
      ],
    );
  }

  final String? started;
  final String? folder;
  final String? by;
  final bool running;
  final List<CommandLine> lines;
}
