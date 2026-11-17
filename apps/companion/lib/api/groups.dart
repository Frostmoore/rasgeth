// Group work as the app reads it (G42.3): group chats (`Room` of the page's api.ts, the events
// `room.message`/`room.member`), the project's board (`BoardThread`, `BoardPost`) and the old
// everyday chats (`ChatSummary`, `ChatEntry`). Read leniently, as conversation.dart.
import 'conversation.dart';
import 'types.dart';

String _s(Object? o) => o is String ? o : '';
String? _so(Object? o) => o is String ? o : null;
Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
List<dynamic> _list(Object? o) => o is List ? o : const [];

class RoomMember {
  const RoomMember({required this.agentId, required this.sessionId, this.costUsd, this.context});

  factory RoomMember.fromJson(Map<String, dynamic> j) => RoomMember(
    agentId: _s(j['agentId']),
    sessionId: _s(j['sessionId']),
    costUsd: (j['costUsd'] as num?)?.toDouble(),
    context: (j['context'] as num?)?.toDouble(),
  );

  final String agentId;
  final String sessionId;

  /// What its answers here cost, and how full its context is (0..1).
  final double? costUsd;
  final double? context;
}

/// A group chat (`GET /api/rooms`).
class Room {
  const Room({
    required this.id,
    required this.title,
    required this.members,
    required this.createdAt,
    this.lastAt,
    this.answering = const [],
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
    id: _s(j['id']),
    title: _s(j['title']),
    members: [
      for (final m in _list(j['members']).whereType<Map<String, dynamic>>()) RoomMember.fromJson(m),
    ],
    createdAt: _s(j['createdAt']),
    lastAt: _so(j['lastAt']),
    answering: [..._list(j['answering']).whereType<String>()],
  );

  final String id;
  final String title;
  final List<RoomMember> members;
  final String createdAt;
  final String? lastAt;

  /// The agents answering now.
  final List<String> answering;

  String get when => lastAt ?? createdAt;
}

/// One line of a group chat: a message (the person's, an agent's, the system's or the context it
/// started from) or someone joining or leaving.
class RoomLine {
  const RoomLine({
    required this.seq,
    required this.ts,
    required this.from,
    required this.name,
    required this.text,
    this.change,
  });

  /// From `room.message` and `room.member`; null for anything else.
  static RoomLine? fromEvent(RgEvent e) {
    final p = e.payload;
    if (p == null) return null;
    if (e.type == 'room.message') {
      return RoomLine(
        seq: e.seq,
        ts: e.ts,
        from: _s(p['from']),
        name: _s(p['name']),
        text: _s(p['text']),
      );
    }
    if (e.type == 'room.member') {
      return RoomLine(
        seq: e.seq,
        ts: e.ts,
        from: _s(p['agentId']),
        name: _s(p['name']),
        text: '',
        change: _s(p['change']),
      );
    }
    return null;
  }

  final int seq;
  final String ts;

  /// human, system, context, or the agent's id.
  final String from;
  final String name;
  final String text;

  /// added or removed (a `room.member`).
  final String? change;

  bool get human => from == 'human';
  bool get note => change != null || from == 'system';
}

/// A choice in «Add an agent» (the page's `joinable()` in Room.tsx): its id (or
/// `inspector:<projectId>`), its name and the group it shows under (null: «Yours»).
typedef Joinable = ({String id, String name, String? project, String? agentId});

/// The agents a group can take, by group: the person's own (God, assistants) first, then each
/// project's lead, agents and inspector. Members already in are left out.
List<Joinable> joinable(
  List<Agent> agents,
  List<Project> projects, {
  required Set<String> inChat,
  required String Function(String project) lead,
  required String Function(String project) inspector,
}) {
  final out = <Joinable>[];
  for (final a in agents) {
    if (inChat.contains(a.id) || !a.active) continue;
    if (a.kind == AgentKind.god || a.kind == AgentKind.assistant) {
      out.add((id: a.id, name: a.name, project: null, agentId: a.id));
    }
  }
  for (final p in projects) {
    final mine = agents.where((a) => a.projectId == p.id && a.active).toList();
    for (final a in mine.where((a) => a.kind == AgentKind.orchestrator)) {
      if (!inChat.contains(a.id))
        out.add((id: a.id, name: lead(p.name), project: p.name, agentId: a.id));
    }
    for (final a in mine.where((a) => a.kind == AgentKind.agent)) {
      if (!inChat.contains(a.id)) out.add((id: a.id, name: a.name, project: p.name, agentId: a.id));
    }
    final insp = mine.where((a) => a.kind == AgentKind.inspector).firstOrNull;
    if (insp == null || !inChat.contains(insp.id)) {
      out.add((
        id: insp?.id ?? 'inspector:${p.id}',
        name: inspector(p.name),
        project: p.name,
        agentId: insp?.id,
      ));
    }
  }
  return out;
}

/// The names the composer offers after «@» and that the server calls (`mentions` in rooms.ts).
List<String> mentionNames(Room room, List<Agent> agents) => [
  for (final m in room.members) ?agents.where((a) => a.id == m.agentId).firstOrNull?.name,
];

// ---------- The board ----------

class BoardThread {
  const BoardThread({
    required this.id,
    required this.title,
    required this.status,
    required this.createdBy,
    required this.updatedAt,
    required this.posts,
    this.projectId,
    this.subprojectId,
    this.summary,
  });

  factory BoardThread.fromJson(Map<String, dynamic> j) => BoardThread(
    id: _s(j['id']),
    projectId: _so(j['projectId']),
    subprojectId: _so(j['subprojectId']),
    title: _s(j['title']),
    status: _s(j['status']).isEmpty ? 'open' : _s(j['status']),
    createdBy: _s(j['createdBy']),
    updatedAt: _s(j['updatedAt']),
    posts: (j['posts'] as num?)?.toInt() ?? 0,
    summary: _so(j['summary']),
  );

  final String id;
  final String? projectId;
  final String? subprojectId;
  final String title;

  /// open, resolved or blocked.
  final String status;
  final String createdBy;
  final String updatedAt;
  final int posts;
  final String? summary;
}

class BoardPost {
  const BoardPost({
    required this.id,
    required this.threadId,
    required this.author,
    required this.kind,
    required this.body,
    required this.createdAt,
    this.title,
  });

  factory BoardPost.fromJson(Map<String, dynamic> j) => BoardPost(
    id: _s(j['id']),
    threadId: _s(j['threadId']),
    author: _s(j['author']),
    kind: _s(j['kind']).isEmpty ? 'note' : _s(j['kind']),
    body: _s(j['body']),
    createdAt: _s(j['createdAt']),
    title: _so(j['title']),
  );

  final String id;
  final String threadId;

  /// human, or an agent's id.
  final String author;

  /// task, result, question, decision, blocker or note.
  final String kind;
  final String body;
  final String createdAt;

  /// The thread's title (search results only).
  final String? title;
}

/// The board's post kinds, in the page's order (`postKinds`).
const boardKinds = ['task', 'result', 'question', 'decision', 'blocker', 'note'];

/// `@<kind>_<8 hex>` in a post becomes the agent's name in bold, as the page does.
String boardMentions(String body, String Function(String id) nameOf) =>
    body.replaceAllMapped(RegExp(r'@([a-z]+_[0-9a-f]{8})\b'), (m) {
      final n = nameOf(m[1]!);
      return n.isEmpty ? m[0]! : '**@$n**';
    });

// ---------- The old everyday chats ----------

/// A chat of the old everyday Chat (`GET /api/chats`) or a project's inspector.
class ChatSummary {
  const ChatSummary({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.folder,
  });

  factory ChatSummary.fromJson(Map<String, dynamic> j) => ChatSummary(
    id: _s(j['id']),
    title: _s(j['title']),
    folder: _so(j['folder']),
    createdAt: _s(j['createdAt']),
    updatedAt: _s(j['updatedAt']),
  );

  final String id;
  final String title;
  final String? folder;
  final String createdAt;
  final String updatedAt;
}

/// One exchange of such a chat: the person's message and, once there, the answer.
class ChatEntry {
  const ChatEntry({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.thinking = '',
    this.tools = const [],
    this.shown = true,
    this.costUsd,
  });

  factory ChatEntry.fromJson(Map<String, dynamic> j) {
    final m = _map(j['message']);
    final parts = _list(m['parts']).whereType<Map<String, dynamic>>().toList();
    final role = _s(m['role']);
    final text = StringBuffer();
    final thinking = StringBuffer();
    final tools = <({String name, String what})>[];
    for (final p in parts) {
      switch (p['type']) {
        case 'text' when role == 'assistant':
          text.write(_s(p['text']));
        case 'thinking':
          thinking.write(_s(p['text']));
        case 'tool_call':
          final input = _map(p['input']);
          tools.add((name: _s(p['name']), what: _s(input['query'] ?? input['url'] ?? '')));
      }
    }
    return ChatEntry(
      id: '${j['id']}',
      role: role,
      // The person's words as shown (the page's `shown`: null for tool results).
      text: role == 'user' ? _s(j['shown']) : text.toString(),
      thinking: thinking.toString(),
      tools: tools,
      shown: role != 'user' || j['shown'] is String,
      createdAt: _s(j['createdAt']),
      costUsd: (j['costUsd'] as num?)?.toDouble(),
    );
  }

  final String id;

  /// user or assistant.
  final String role;
  final String text;
  final String thinking;
  final List<({String name, String what})> tools;

  /// A person's message the server keeps but does not show (null `shown` in the page).
  final bool shown;
  final String createdAt;
  final double? costUsd;
}
