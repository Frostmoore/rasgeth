// The advanced interface's data (G40.11): a project's git state, commits, branches, unified diffs
// cut into files and hunks (a hunk goes back to the server as a patch of its own), the project's
// log, file search, the files' list and a shell over `/term`, as `code-routes.ts` and the page's
// Explorer give them.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'transport.dart';

String? _s(Object? o) => o is String ? o : null;
int _i(Object? o) => o is num ? o.toInt() : 0;

class GitChange {
  const GitChange({required this.path, required this.status, required this.staged});

  factory GitChange.fromJson(Map<String, dynamic> j) => GitChange(
    path: _s(j['path']) ?? '',
    status: _s(j['status']) ?? 'M',
    staged: j['staged'] == true,
  );

  final String path;

  /// M, A, D, R, ? (new, not in git yet) or U (in conflict).
  final String status;
  final bool staged;
}

class GitState {
  const GitState({
    required this.repo,
    this.branch,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    this.changes = const [],
  });

  factory GitState.fromJson(Map<String, dynamic> j) => GitState(
    repo: j['repo'] == true,
    branch: _s(j['branch']),
    upstream: _s(j['upstream']),
    ahead: _i(j['ahead']),
    behind: _i(j['behind']),
    changes: [
      for (final c in (j['changes'] is List ? j['changes'] as List : const []))
        if (c is Map<String, dynamic>) GitChange.fromJson(c),
    ],
  );

  final bool repo;
  final String? branch;
  final String? upstream;
  final int ahead;
  final int behind;
  final List<GitChange> changes;

  bool get clean => changes.isEmpty;
}

class GitCommit {
  const GitCommit({
    required this.hash,
    required this.short,
    required this.author,
    required this.date,
    required this.refs,
    required this.subject,
    this.parents = const [],
  });

  factory GitCommit.fromJson(Map<String, dynamic> j) => GitCommit(
    hash: _s(j['hash']) ?? '',
    short: _s(j['short']) ?? '',
    author: _s(j['author']) ?? '',
    date: _s(j['date']) ?? '',
    refs: _s(j['refs']) ?? '',
    subject: _s(j['subject']) ?? '',
    parents: [
      for (final p in (j['parents'] is List ? j['parents'] as List : const []))
        if (p is String) p,
    ],
  );

  /// The parents' full hashes (the graph on computers, G40.17); empty from older servers.
  final List<String> parents;

  final String hash;
  final String short;
  final String author;
  final String date;
  final String refs;
  final String subject;
}

class GitBranch {
  const GitBranch({
    required this.name,
    required this.current,
    this.upstream,
    this.ahead = 0,
    this.behind = 0,
    this.subject = '',
  });

  factory GitBranch.fromJson(Map<String, dynamic> j) => GitBranch(
    name: _s(j['name']) ?? '',
    current: j['current'] == true,
    upstream: _s(j['upstream']),
    ahead: _i(j['ahead']),
    behind: _i(j['behind']),
    subject: _s(j['subject']) ?? '',
  );

  final String name;
  final bool current;
  final String? upstream;
  final int ahead;
  final int behind;
  final String subject;
}

enum DiffLineKind { context, added, removed, note }

class DiffLine {
  const DiffLine(this.kind, this.text, {this.oldNo, this.newNo});

  final DiffLineKind kind;
  final String text;
  final int? oldNo;
  final int? newNo;
}

class DiffHunk {
  DiffHunk(this.header, this.oldStart, this.newStart);

  /// `@@ -12,6 +12,8 @@ export function Prices()`.
  final String header;
  final int oldStart;
  final int newStart;
  final lines = <DiffLine>[];

  /// The hunk as git wrote it (its header and lines), to send back.
  final raw = StringBuffer();

  int get added => lines.where((l) => l.kind == DiffLineKind.added).length;
  int get removed => lines.where((l) => l.kind == DiffLineKind.removed).length;
}

class DiffFile {
  DiffFile(this.path);

  String path;
  String? oldPath;
  bool isNew = false;
  bool isDeleted = false;
  bool binary = false;

  /// `diff --git`, `index`, `---`, `+++`…: what comes before the first hunk.
  final header = StringBuffer();
  final hunks = <DiffHunk>[];

  int get added => hunks.fold(0, (n, h) => n + h.added);
  int get removed => hunks.fold(0, (n, h) => n + h.removed);
}

final _hunkHead = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');

/// A unified patch (git's) cut into files and hunks, with the line numbers of both sides.
List<DiffFile> parsePatch(String patch) {
  final files = <DiffFile>[];
  DiffFile? f;
  DiffHunk? h;
  var oldNo = 0;
  var newNo = 0;
  for (final line in const LineSplitter().convert(patch)) {
    if (line.startsWith('diff --git ')) {
      final m = RegExp(r'^diff --git a/(.*) b/(.*)$').firstMatch(line);
      f = DiffFile(m?.group(2) ?? line.substring(11));
      if (m != null && m.group(1) != m.group(2)) f.oldPath = m.group(1);
      files.add(f);
      h = null;
      f.header.writeln(line);
      continue;
    }
    if (f == null) continue;
    final head = _hunkHead.firstMatch(line);
    if (head != null) {
      oldNo = int.parse(head.group(1)!);
      newNo = int.parse(head.group(2)!);
      h = DiffHunk(line, oldNo, newNo);
      f.hunks.add(h);
      h.raw.writeln(line);
      continue;
    }
    if (h == null) {
      f.header.writeln(line);
      if (line.startsWith('new file')) f.isNew = true;
      if (line.startsWith('deleted file')) f.isDeleted = true;
      if (line.startsWith('Binary files')) f.binary = true;
      if (line.startsWith('+++ b/')) f.path = line.substring(6);
      continue;
    }
    h.raw.writeln(line);
    if (line.startsWith('+')) {
      h.lines.add(DiffLine(DiffLineKind.added, line.substring(1), newNo: newNo++));
    } else if (line.startsWith('-')) {
      h.lines.add(DiffLine(DiffLineKind.removed, line.substring(1), oldNo: oldNo++));
    } else if (line.startsWith(r'\')) {
      h.lines.add(DiffLine(DiffLineKind.note, line));
    } else {
      h.lines.add(
        DiffLine(
          DiffLineKind.context,
          line.isEmpty ? '' : line.substring(1),
          oldNo: oldNo++,
          newNo: newNo++,
        ),
      );
    }
  }
  return files;
}

/// A hunk as two columns (the computers' side-by-side diff, G40.17): context on both sides, a
/// run of removed lines next to the run of added lines that follows it, a blank where one side
/// has fewer.
List<(DiffLine?, DiffLine?)> sideBySideRows(DiffHunk h) {
  final out = <(DiffLine?, DiffLine?)>[];
  final removed = <DiffLine>[];
  final added = <DiffLine>[];
  void flush() {
    final n = removed.length > added.length ? removed.length : added.length;
    for (var i = 0; i < n; i++) {
      out.add((i < removed.length ? removed[i] : null, i < added.length ? added[i] : null));
    }
    removed.clear();
    added.clear();
  }

  for (final line in h.lines) {
    switch (line.kind) {
      case DiffLineKind.removed:
        if (added.isNotEmpty) flush();
        removed.add(line);
      case DiffLineKind.added:
        added.add(line);
      case DiffLineKind.context:
        flush();
        out.add((line, line));
      case DiffLineKind.note:
        flush();
        out.add((line, null));
    }
  }
  flush();
  return out;
}

/// One hunk as a patch of its own (its file's header and the hunk): what `git apply` takes.
String hunkPatch(DiffFile f, DiffHunk h) => '${f.header}${h.raw}';

/// `GET /api/projects/:id/git/diff`.
class DiffView {
  const DiffView({
    required this.kind,
    required this.title,
    required this.files,
    this.agentId,
    this.truncated = false,
  });

  factory DiffView.fromJson(Map<String, dynamic> j) => DiffView(
    kind: _s(j['kind']) ?? 'working',
    title: _s(j['title']) ?? '',
    agentId: _s(j['agentId']),
    files: parsePatch(_s(j['patch']) ?? ''),
    truncated: j['truncated'] == true,
  );

  /// working, agent or commit.
  final String kind;
  final String title;
  final String? agentId;
  final List<DiffFile> files;
  final bool truncated;
}

/// Which diff: the working tree, a task's, an agent's or a commit's.
class DiffSource {
  const DiffSource.working() : task = null, agent = null, commit = null, label = null;
  const DiffSource.task(String this.task, {this.label}) : agent = null, commit = null;
  const DiffSource.agent(String this.agent, {this.label}) : task = null, commit = null;
  const DiffSource.commit(String this.commit, {this.label}) : task = null, agent = null;

  final String? task;
  final String? agent;
  final String? commit;
  final String? label;

  /// For hunks and comments: the agent's worktree, when the diff is an agent's.
  bool get working => task == null && agent == null && commit == null;

  Map<String, String> get query => {'task': ?task, 'agent': ?agent, 'commit': ?commit};

  @override
  bool operator ==(Object other) =>
      other is DiffSource && other.task == task && other.agent == agent && other.commit == commit;

  @override
  int get hashCode => Object.hash(task, agent, commit);
}

class ProjectEvent {
  const ProjectEvent({
    required this.seq,
    required this.ts,
    required this.type,
    required this.error,
    this.agentId,
    this.agentName,
    this.sessionId,
    this.payload,
  });

  factory ProjectEvent.fromJson(Map<String, dynamic> j) => ProjectEvent(
    seq: _i(j['seq']),
    ts: _s(j['ts']) ?? '',
    type: _s(j['type']) ?? '',
    error: j['error'] == true,
    agentId: _s(j['agentId']),
    agentName: _s(j['agentName']),
    sessionId: _s(j['sessionId']),
    payload: j['payload'],
  );

  final int seq;
  final String ts;
  final String type;
  final bool error;
  final String? agentId;
  final String? agentName;
  final String? sessionId;
  final Object? payload;

  /// The detail, as the page's log shows it.
  String get json => const JsonEncoder.withIndent('  ').convert(payload);

  /// One line that says what happened.
  String get summary {
    final p = payload;
    if (p is! Map) return '';
    String? pick(List<String> keys) {
      for (final k in keys) {
        final v = p[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    if (type == 'tool.call') {
      final input = p['input'];
      final cmd = input is Map ? input['command'] ?? input['path'] ?? input['query'] : null;
      return '${p['tool'] ?? ''}${cmd is String ? ': $cmd' : ''}';
    }
    if (type == 'message.assistant' && p['parts'] is List) {
      for (final part in p['parts'] as List) {
        if (part is Map && part['type'] == 'text' && part['text'] is String) {
          return (part['text'] as String).trim();
        }
      }
    }
    return pick(['text', 'output', 'title', 'message', 'reason', 'error', 'verifier', 'path']) ??
        '';
  }
}

class EventsPage {
  const EventsPage({required this.events, required this.types, required this.agents});

  factory EventsPage.fromJson(Map<String, dynamic> j) => EventsPage(
    events: [
      for (final e in (j['events'] is List ? j['events'] as List : const []))
        if (e is Map<String, dynamic>) ProjectEvent.fromJson(e),
    ],
    types: [
      for (final t in (j['types'] is List ? j['types'] as List : const []))
        if (t is String) t,
    ],
    agents: [
      for (final a in (j['agents'] is List ? j['agents'] as List : const []))
        if (a is Map && a['id'] is String) (id: a['id'] as String, name: '${a['name'] ?? a['id']}'),
    ],
  );

  final List<ProjectEvent> events;
  final List<String> types;
  final List<({String id, String name})> agents;
}

class SearchHit {
  const SearchHit({required this.path, this.line, this.text});

  factory SearchHit.fromJson(Map<String, dynamic> j) =>
      SearchHit(path: _s(j['path']) ?? '', line: (j['line'] as num?)?.toInt(), text: _s(j['text']));

  final String path;
  final int? line;
  final String? text;
}

/// `GET /api/files/list`.
class FileEntry {
  const FileEntry({
    required this.name,
    required this.path,
    required this.dir,
    required this.size,
    required this.modifiedAt,
  });

  factory FileEntry.fromJson(Map<String, dynamic> j) => FileEntry(
    name: _s(j['name']) ?? '',
    path: _s(j['path']) ?? '',
    dir: j['type'] == 'dir',
    size: _i(j['size']),
    modifiedAt: _s(j['modifiedAt']) ?? '',
  );

  final String name;
  final String path;
  final bool dir;
  final int size;
  final String modifiedAt;
}

/// `GET /api/files/content` with its time (a small edit is saved only if nobody changed it since).
class FileText {
  const FileText({required this.path, required this.size, required this.modifiedAt, this.text});

  factory FileText.fromJson(Map<String, dynamic> j) => FileText(
    path: _s(j['path']) ?? '',
    text: j['encoding'] == 'base64' ? null : _s(j['content']),
    size: _i(j['size']),
    modifiedAt: _s(j['modifiedAt']) ?? '',
  );

  final String path;

  /// null: not text (a picture, a binary).
  final String? text;
  final int size;
  final String modifiedAt;
}

/// A background action of the server (`/api/jobs/:id`): a push waiting for the person, Gitea
/// starting (G42.5: with its steps, as the page's `JobView`).
class JobView {
  const JobView({
    required this.id,
    required this.state,
    this.errorCode,
    this.errorMessage,
    this.kind = '',
    this.steps = const [],
  });

  factory JobView.fromJson(Map<String, dynamic> j) {
    final e = j['error'];
    return JobView(
      id: _s(j['id']) ?? '',
      state: _s(j['state']) ?? 'running',
      errorCode: e is Map ? _s(e['code']) : null,
      errorMessage: e is Map ? _s(e['message']) : null,
      kind: _s(j['kind']) ?? '',
      steps: [
        for (final s in (j['steps'] as List? ?? const []).whereType<Map<String, dynamic>>())
          JobStepView.fromJson(s),
      ],
    );
  }

  final String id;

  /// What it does (`gitea`, `push`…).
  final String kind;

  /// Each step (`gitea_image`, `gitea_start`, `account`), with its progress when it counts.
  final List<JobStepView> steps;

  /// running, done, failed, cancelled.
  final String state;
  final String? errorCode;
  final String? errorMessage;

  bool get running => state == 'running';
}

/// A job's step (protocol `JobStep`): waiting | running | done | failed | skipped, and for a
/// download how much, of how much, how fast and how long still.
class JobStepView {
  const JobStepView({
    required this.id,
    required this.state,
    this.done,
    this.total,
    this.rate,
    this.secondsLeft,
  });

  factory JobStepView.fromJson(Map<String, dynamic> j) {
    final p = j['progress'];
    num? n(String k) => p is Map && p[k] is num ? p[k] as num : null;
    return JobStepView(
      id: _s(j['id']) ?? '',
      state: _s(j['state']) ?? 'waiting',
      done: n('done')?.toInt(),
      total: n('total')?.toInt(),
      rate: n('rate')?.toDouble(),
      secondsLeft: n('secondsLeft')?.toInt(),
    );
  }

  final String id;
  final String state;
  final int? done;
  final int? total;
  final double? rate;
  final int? secondsLeft;
}

/// One line of «Create the repositories now» (`POST /api/setup/git/sync`).
class GitSyncRow {
  const GitSyncRow({required this.project, required this.ok, this.error});

  factory GitSyncRow.fromJson(Map<String, dynamic> j) =>
      GitSyncRow(project: _s(j['project']) ?? '', ok: j['ok'] == true, error: _s(j['error']));

  final String project;
  final bool ok;
  final String? error;
}

/// A bash command an agent ran and what it printed: its terminal, read only.
class AgentCommand {
  const AgentCommand({required this.command, this.output, this.ok});

  final String command;
  final String? output;
  final bool? ok;
}

/// The agent's commands out of a conversation's events (`tool.call` bash and its result).
List<AgentCommand> agentCommands(List<Map<String, dynamic>> events) {
  final calls = <String, String>{};
  final order = <String>[];
  final results = <String, ({String output, bool ok})>{};
  for (final e in events) {
    final p = e['payload'];
    if (p is! Map) continue;
    final id = p['callId'];
    if (id is! String) continue;
    if (e['type'] == 'tool.call' && p['tool'] == 'bash') {
      final input = p['input'];
      final cmd = input is Map ? input['command'] : null;
      if (cmd is String) {
        calls[id] = cmd;
        order.add(id);
      }
    } else if (e['type'] == 'tool.result' && calls.containsKey(id)) {
      results[id] = (output: '${p['output'] ?? ''}', ok: p['ok'] == true);
    }
  }
  return [
    for (final id in order)
      AgentCommand(command: calls[id]!, output: results[id]?.output, ok: results[id]?.ok),
  ];
}

final _csi = RegExp(r'\x1b\[[0-9;?]*[ -/]*[@-~]');
final _osc = RegExp(r'\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)');
final _esc = RegExp(r'\x1b[()][A-Za-z0-9]|\x1b[=>78DEHM]');

/// What a shell prints, as lines to read: colours and cursor moves dropped, `\r` and backspace
/// applied. Not a full terminal (no full-screen programs): enough for commands and their output.
class TermBuffer {
  TermBuffer({this.maxLines = 2000});

  final int maxLines;
  final lines = <String>[''];

  void write(String data) {
    // «Erase to the end of the line» becomes a mark (0x01) applied where the cursor is.
    final clean = data
        .replaceAll(_osc, '')
        .replaceAll(RegExp(r'\x1b\[0?K'), '\x01')
        .replaceAll(_csi, '')
        .replaceAll(_esc, '');
    var cur = StringBuffer(lines.removeLast());
    var col = cur.length;
    for (final ch in clean.runes) {
      if (ch == 0x0a) {
        lines.add(cur.toString());
        cur = StringBuffer();
        col = 0;
      } else if (ch == 0x0d) {
        col = 0;
      } else if (ch == 0x01) {
        final s = cur.toString();
        if (col < s.length) cur = StringBuffer(s.substring(0, col));
      } else if (ch == 0x08) {
        if (col > 0) col--;
      } else if (ch == 0x07 || ch < 0x20 && ch != 0x09) {
        continue;
      } else {
        final s = cur.toString();
        final c = String.fromCharCode(ch);
        cur = StringBuffer(
          col >= s.length ? '$s$c' : '${s.substring(0, col)}$c${s.substring(col + 1)}',
        );
        col++;
      }
    }
    lines.add(cur.toString());
    if (lines.length > maxLines) lines.removeRange(0, lines.length - maxLines);
  }

  String get text => lines.join('\n');
}

/// The keys over the keyboard, as bytes for the shell.
abstract final class TermKeys {
  static const esc = '\x1b';
  static const tab = '\t';
  static const up = '\x1b[A';
  static const down = '\x1b[B';
  static const right = '\x1b[C';
  static const left = '\x1b[D';
  static const enter = '\r';

  /// Ctrl with a letter: its control code (Ctrl+C → 0x03).
  static String ctrl(String letter) {
    final c = letter.toLowerCase().codeUnitAt(0);
    if (c < 0x61 || c > 0x7a) return letter;
    return String.fromCharCode(c - 0x60);
  }
}

/// One shell over `/term` (terminal.ts): `hello` with the token, scope and size, then input and
/// resize in, output and exit out. The same rules as the page: the server checks the token, the
/// scope (an archived project has none) and the number of terminals.
class TermSession {
  TermSession._(this._ws);

  final WebSocket _ws;
  final _out = StreamController<String>.broadcast();
  String? terminalId;
  String? error;
  bool closed = false;

  /// The shell ended (`exit`), as the page's «terminal closed» line says.
  bool exited = false;

  /// Called once when the shell ends or the link goes (the terminal writes its line).
  void Function()? onEnd;

  Stream<String> get output => _out.stream;

  static Future<TermSession> open(
    Transport transport, {
    required String token,
    required String scope,
    int cols = 80,
    int rows = 24,
  }) async {
    final ws = await transport.socket('/term');
    final t = TermSession._(ws);
    ws.add(
      jsonEncode({'type': 'hello', 'token': token, 'scope': scope, 'cols': cols, 'rows': rows}),
    );
    ws.listen(
      (data) {
        if (data is! String) return;
        final m = jsonDecode(data);
        if (m is! Map) return;
        switch (m['type']) {
          case 'ready':
            t.terminalId = _s(m['terminalId']);
          case 'output':
            if (m['data'] is String) t._out.add(m['data'] as String);
          case 'error':
            // As the page writes it: red, on a line of its own.
            t.error = _s(m['message']);
            t._out.add('\r\n\x1b[31m${t.error}\x1b[0m\r\n');
          case 'exit':
            t.closed = true;
            t.exited = true;
            t._end();
        }
      },
      onDone: () {
        t.closed = true;
        t._end();
        if (!t._out.isClosed) unawaited(t._out.close());
      },
      onError: (Object _) {
        t.closed = true;
        t._end();
      },
    );
    return t;
  }

  bool _ended = false;
  void _end() {
    if (_ended) return;
    _ended = true;
    onEnd?.call();
  }

  void input(String data) {
    if (!closed) _ws.add(jsonEncode({'type': 'input', 'data': data}));
  }

  void resize(int cols, int rows) {
    if (!closed) {
      _ws.add(
        jsonEncode({'type': 'resize', 'cols': cols.clamp(10, 500), 'rows': rows.clamp(4, 300)}),
      );
    }
  }

  Future<void> close() async {
    closed = true;
    await _ws.close(1000);
  }
}
