// Conversations, requests and tasks as the app reads them (G40.7): the shapes of
// `GET /api/sessions`, the events (`packages/protocol/src/events.ts`), `PermissionRequestInfo`
// and `QuestionRequestInfo` (wire.ts, questions.ts), `GET /api/projects/:id/tasks`. Read
// leniently. [buildItems] is the app's `buildItems` (packages/web/src/state.ts): pure, events in,
// chat items out.
import 'types.dart';

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _str(Object? o) => o is String ? o : null;
List<dynamic> _list(Object? o) => o is List ? o : const [];

/// A row of `GET /api/sessions`.
class SessionRow {
  const SessionRow({
    required this.id,
    required this.agentId,
    required this.createdAt,
    this.projectId,
    this.lastAt,
    this.repliedAt,
    this.title,
    this.archived = false,
    this.running = false,
    this.task,
    this.model,
  });

  factory SessionRow.fromJson(Map<String, dynamic> j) => SessionRow(
    id: _str(j['id']) ?? '',
    agentId: _str(j['agentId']) ?? '',
    projectId: _str(j['projectId']),
    createdAt: _str(j['createdAt']) ?? '',
    lastAt: _str(j['lastAt']),
    repliedAt: _str(j['repliedAt']),
    title: _str(j['title']),
    archived: j['archived'] == true,
    running: j['running'] == true,
    task: _str(j['task']),
    model: AgentModel.fromJson(j['model']),
  );

  final String id;
  final String agentId;
  final String? projectId;
  final String createdAt;
  final String? lastAt;

  /// When the agent last answered the person here (3.8.1): its mascot stays awake a while.
  final String? repliedAt;
  final String? title;
  final bool archived;
  final bool running;

  /// The title of the task open in it.
  final String? task;

  /// The conversation's own model (null: its agent's).
  final AgentModel? model;

  String get when => lastAt ?? createdAt;

  SessionRow withTitle(String t) => copy(title: t);

  SessionRow withRunning(bool r) => copy(running: r);

  SessionRow copy({String? title, bool? running, String? repliedAt}) => SessionRow(
    id: id,
    agentId: agentId,
    projectId: projectId,
    createdAt: createdAt,
    lastAt: lastAt,
    repliedAt: repliedAt ?? this.repliedAt,
    title: title ?? this.title,
    archived: archived,
    running: running ?? this.running,
    task: task,
    model: model,
  );
}

/// One stored event (the fields the app uses).
class RgEvent {
  const RgEvent({required this.seq, required this.ts, required this.type, this.payload});

  factory RgEvent.fromJson(Map<String, dynamic> j) => RgEvent(
    seq: (j['seq'] as num?)?.toInt() ?? 0,
    ts: _str(j['ts']) ?? '',
    type: _str(j['type']) ?? '',
    payload: j['erased'] == true ? null : _map(j['payload']),
  );

  final int seq;
  final String ts;
  final String type;

  /// null when erased.
  final Map<String, dynamic>? payload;
}

/// What a conversation shows, one item after the other.
sealed class ChatItem {
  const ChatItem();
}

class UserItem extends ChatItem {
  const UserItem({required this.text, required this.ts, this.images = 0, this.from});

  final String text;
  final String ts;
  final int images;

  /// Another agent, an automation, a chat platform (null: the person).
  final String? from;
}

class AssistantItem extends ChatItem {
  const AssistantItem({
    required this.text,
    required this.thinking,
    required this.ts,
    this.live = false,
  });

  final String text;
  final String thinking;
  final String ts;

  /// Still being written (the deltas not persisted yet).
  final bool live;
}

class ToolItem extends ChatItem {
  ToolItem({required this.callId, required this.tool, required this.input});

  final String callId;
  final String tool;
  final Object? input;
  bool? ok;
  String? output;
}

enum NoticeLevel { info, ok, warn, error }

class NoticeItem extends ChatItem {
  const NoticeItem(this.level, this.text);

  final NoticeLevel level;
  final String text;
}

/// `canvas.show`: a file (or a port) the agent showed.
class CanvasItem extends ChatItem {
  const CanvasItem({required this.title, required this.target});

  final String title;
  final Map<String, dynamic> target;

  String? get scope => _str(target['scope']);
  String? get path => _str(target['path']);
  bool get isFile => target['kind'] == 'file';
}

/// `file.sent`: a file the agent handed over.
class FileItem extends ChatItem {
  const FileItem({
    required this.scope,
    required this.path,
    required this.name,
    required this.mime,
    required this.size,
    this.caption,
  });

  final String scope;
  final String path;
  final String name;
  final String mime;
  final int size;
  final String? caption;
}

const _hiddenTools = {'ask_user', 'propose_plan'};

/// The page's `buildItems`, the parts the app shows: events in order, plus the text and
/// reasoning still streaming.
List<ChatItem> buildItems(List<RgEvent> events, {String liveText = '', String liveThinking = ''}) {
  final out = <ChatItem>[];
  final open = <String, ToolItem>{};
  for (final e in events) {
    final p = e.payload;
    if (p == null) {
      out.add(NoticeItem(NoticeLevel.warn, '${e.type} (erased)'));
      continue;
    }
    switch (e.type) {
      case 'message.user':
        final from = _str(p['from']);
        if (from == 'redgiant') break;
        out.add(
          UserItem(
            text: _str(p['text']) ?? '',
            ts: e.ts,
            images: _list(p['images']).length,
            from: from,
          ),
        );
      case 'message.assistant':
        final parts = _list(p['parts']).whereType<Map<String, dynamic>>();
        final text = parts.where((x) => x['type'] == 'text').map((x) => _str(x['text']) ?? '');
        final thinking = parts
            .where((x) => x['type'] == 'thinking')
            .map((x) => _str(x['text']) ?? '');
        final t = text.join('\n\n').trim();
        final th = thinking.join('\n\n').trim();
        if (t.isNotEmpty || th.isNotEmpty) {
          out.add(AssistantItem(text: t, thinking: th, ts: e.ts));
        }
        if (p['stopReason'] != 'tool_use') {
          for (final c in open.values) {
            c.ok ??= false;
            c.output ??= '';
          }
          open.clear();
        }
      case 'tool.call':
        final tool = _str(p['tool']) ?? '';
        if (_hiddenTools.contains(tool)) break;
        final item = ToolItem(callId: _str(p['callId']) ?? '', tool: tool, input: p['input']);
        open[item.callId] = item;
        out.add(item);
      case 'tool.result':
        final c = open.remove(_str(p['callId']));
        if (c != null) {
          c.ok = p['ok'] == true;
          c.output = _str(p['output']) ?? '';
        }
      case 'canvas.show':
        out.add(CanvasItem(title: _str(p['title']) ?? '', target: _map(p['target'])));
      case 'file.sent':
        out.add(
          FileItem(
            scope: _str(p['scope']) ?? '',
            path: _str(p['path']) ?? '',
            name: _str(p['name']) ?? '',
            mime: _str(p['mime']) ?? '',
            size: (p['size'] as num?)?.toInt() ?? 0,
            caption: _str(p['caption']),
          ),
        );
      case 'hook.blocked':
        out.add(NoticeItem(NoticeLevel.error, _str(p['reason']) ?? 'blocked'));
      case 'budget.exceeded':
        out.add(
          NoticeItem(
            NoticeLevel.error,
            r'$ '
            '${p['scope']}: ${p['used']} / ${p['limit']}',
          ),
        );
      case 'task.opened':
        out.add(NoticeItem(NoticeLevel.info, _str(p['title']) ?? ''));
      case 'task.verified':
        out.add(
          NoticeItem(
            p['passed'] == true ? NoticeLevel.ok : NoticeLevel.error,
            _str(p['verifier']) ?? '',
          ),
        );
      default:
        break;
    }
  }
  if (liveText.isNotEmpty || liveThinking.isNotEmpty) {
    out.add(AssistantItem(text: liveText, thinking: liveThinking, ts: '', live: true));
  }
  return out;
}

/// Events that leave a conversation blocked until the person does something.
const blockingEvents = {'budget.exceeded', 'hook.blocked'};

/// The todos of a conversation: the last `update_todos` input.
({int done, int total})? todosOf(List<RgEvent> events) {
  for (final e in events.reversed) {
    if (e.type != 'tool.call' || e.payload?['tool'] != 'update_todos') continue;
    final todos = _list(_map(e.payload?['input'])['todos']).whereType<Map<String, dynamic>>();
    if (todos.isEmpty) continue;
    return (done: todos.where((t) => t['status'] == 'completed').length, total: todos.length);
  }
  return null;
}

/// The verifiers a conversation ran for its tasks (`task.verified`), the last first.
List<({String taskId, String verifier, bool passed})> verifiersOf(List<RgEvent> events) => [
  for (final e in events.reversed)
    if (e.type == 'task.verified' && e.payload != null)
      (
        taskId: _str(e.payload!['taskId']) ?? '',
        verifier: _str(e.payload!['verifier']) ?? '',
        passed: e.payload!['passed'] == true,
      ),
];

/// `CriticalDetail`: what a truly dangerous call does.
class CriticalDetail {
  const CriticalDetail({required this.id, required this.action, this.target});

  factory CriticalDetail.fromJson(Map<String, dynamic> j) => CriticalDetail(
    id: _str(j['id']) ?? '',
    action: _str(j['action']) ?? '',
    target: _str(j['target']),
  );

  final String id;
  final String action;
  final String? target;
}

/// A request waiting for the person: a permission (`permission.request`) or a question.
sealed class PersonRequest {
  const PersonRequest();

  String get requestId;
  String get agentId;
  String get agentName;
  String get createdAt;
}

class PermissionRequest extends PersonRequest {
  const PermissionRequest({
    required this.requestId,
    required this.agentId,
    required this.agentName,
    required this.tool,
    required this.input,
    required this.reasons,
    required this.danger,
    required this.critical,
    required this.createdAt,
    this.sessionId,
  });

  factory PermissionRequest.fromJson(Map<String, dynamic> j) => PermissionRequest(
    requestId: _str(j['requestId']) ?? '',
    agentId: _str(j['agentId']) ?? '',
    agentName: _str(j['agentName']) ?? '',
    tool: _str(j['tool']) ?? '',
    input: j['input'],
    reasons: _list(j['reasons']).whereType<String>().toList(),
    danger: _list(j['danger']).whereType<String>().toList(),
    critical: [
      for (final c in _list(j['critical']).whereType<Map<String, dynamic>>())
        CriticalDetail.fromJson(c),
    ],
    createdAt: _str(j['createdAt']) ?? '',
    sessionId: _str(j['sessionId']),
  );

  @override
  final String requestId;
  @override
  final String agentId;
  @override
  final String agentName;
  final String tool;
  final Object? input;
  final List<String> reasons;
  final List<String> danger;
  final List<CriticalDetail> critical;
  @override
  final String createdAt;
  final String? sessionId;

  /// Truly dangerous (G36.17b): a full screen of its own, never the quick yes. The server says
  /// so with `critical` (from `criticalOf`); the dangers' ids of `critical.ts` count too.
  bool get isCritical => critical.isNotEmpty || danger.any(criticalDangers.contains);
}

/// The critical dangers' ids (`CRITICAL_IDS` in packages/protocol/src/critical.ts).
const criticalDangers = {
  'critical-system',
  'critical-delete',
  'critical-secret',
  'critical-payment',
  'critical-protections',
};

class QuestionOption {
  const QuestionOption(this.label, [this.description]);

  final String label;
  final String? description;
}

class Question {
  const Question({
    required this.question,
    this.header,
    required this.options,
    this.multiSelect = false,
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    question: _str(j['question']) ?? '',
    header: _str(j['header']),
    options: [
      for (final o in _list(j['options']).whereType<Map<String, dynamic>>())
        QuestionOption(_str(o['label']) ?? '', _str(o['description'])),
    ],
    multiSelect: j['multiSelect'] == true,
  );

  final String question;
  final String? header;
  final List<QuestionOption> options;
  final bool multiSelect;
}

class QuestionRequest extends PersonRequest {
  const QuestionRequest({
    required this.requestId,
    required this.agentId,
    required this.agentName,
    required this.sessionId,
    required this.questions,
    required this.createdAt,
    this.plan,
  });

  factory QuestionRequest.fromJson(Map<String, dynamic> j) => QuestionRequest(
    requestId: _str(j['requestId']) ?? '',
    agentId: _str(j['agentId']) ?? '',
    agentName: _str(j['agentName']) ?? '',
    sessionId: _str(j['sessionId']) ?? '',
    questions: [
      for (final q in _list(j['questions']).whereType<Map<String, dynamic>>()) Question.fromJson(q),
    ],
    createdAt: _str(j['createdAt']) ?? '',
    plan: _str(j['plan']),
  );

  @override
  final String requestId;
  @override
  final String agentId;
  @override
  final String agentName;
  final String sessionId;
  final List<Question> questions;
  @override
  final String createdAt;
  final String? plan;
}

class Project {
  const Project({required this.id, required this.name, this.archived = false});

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: _str(j['id']) ?? '',
    name: _str(j['name']) ?? '',
    archived: j['archivedAt'] != null,
  );

  final String id;
  final String name;
  final bool archived;
}

enum TaskOutcome { open, verified, notTestable, abandoned }

TaskOutcome taskOutcomeFrom(String? s) => switch (s) {
  'verified' => TaskOutcome.verified,
  'not_testable' => TaskOutcome.notTestable,
  'abandoned' => TaskOutcome.abandoned,
  _ => TaskOutcome.open,
};

/// A task (RD17) as `GET /api/projects/:id/tasks` lists it.
class TaskRow {
  const TaskRow({
    required this.id,
    required this.title,
    required this.agentName,
    required this.outcome,
    required this.openedAt,
    this.agentId,
    this.sessionId,
    this.projectId,
  });

  factory TaskRow.fromJson(Map<String, dynamic> j, {String? projectId}) => TaskRow(
    id: _str(j['id']) ?? '',
    title: _str(j['title']) ?? '',
    agentId: _str(j['agentId']),
    agentName: _str(j['agentName']) ?? '-',
    sessionId: _str(j['sessionId']),
    outcome: taskOutcomeFrom(_str(j['outcome'])),
    openedAt: _str(j['openedAt']) ?? '',
    projectId: projectId,
  );

  final String id;
  final String title;
  final String? agentId;
  final String agentName;
  final String? sessionId;
  final TaskOutcome outcome;
  final String openedAt;
  final String? projectId;

  bool get done => outcome != TaskOutcome.open;
}

/// `GET /api/files/content`.
class FileContent {
  const FileContent({
    required this.path,
    required this.text,
    required this.base64,
    required this.size,
  });

  factory FileContent.fromJson(Map<String, dynamic> j) {
    final b64 = j['encoding'] == 'base64';
    return FileContent(
      path: _str(j['path']) ?? '',
      text: b64 ? null : _str(j['content']),
      base64: b64 ? _str(j['content']) : null,
      size: (j['size'] as num?)?.toInt() ?? 0,
    );
  }

  final String path;
  final String? text;
  final String? base64;
  final int size;
}
