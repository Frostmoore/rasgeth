// What the live connection keeps up to date (G40.7): the conversations' rows and views, the
// requests waiting for the person and the counters «For you» and «In progress». [apply] takes one
// server message, as the page's state.ts does; it is pure enough to test without a socket.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../settings/automations/automation_types.dart' show AutomationNotice;
import 'conversation.dart';
import 'turn_queue.dart';
import 'types.dart';

/// One model request seen live (the page's `ModelCall` in state.ts): when it started, how far the
/// prompt was read (local engines report it with `prefill`), when the first word came and how much
/// has been written since.
class ModelCall {
  ModelCall(this.since);

  final DateTime since;
  PrefillProgress? prefill;
  DateTime? firstToken;
  int chars = 0;

  /// What the latest `delta` was: `text` or `thinking`.
  String? writing;
}

/// The reading of the context as the engine reports it (`prefill`: total, cached, processed, ms).
class PrefillProgress {
  const PrefillProgress({
    required this.total,
    required this.cached,
    required this.processed,
    required this.ms,
  });

  final int total;
  final int cached;
  final int processed;
  final int ms;
}

/// A message sent while the agent works (the page's `pending`): shown in line at once, with
/// «togli» (`session.unqueue` with its `clientId`), until the log has it.
class QueuedMessage {
  const QueuedMessage({required this.clientId, required this.text, required this.match});

  final String clientId;

  /// What the bubble shows (the person's words, without the attachments' text).
  final String text;

  /// The text as sent: the log's `message.user` with the same text takes it out of the line.
  final String match;
}

/// A followed conversation: its stored events, what is streaming, whether it runs.
class SessionView extends ChangeNotifier {
  SessionView(this.sessionId, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  final String sessionId;
  final List<RgEvent> events = [];
  String liveText = '';
  String liveThinking = '';
  bool running = false;
  bool synced = false;
  String? stopReason;

  /// The model call under way (the page's `v.call`): from the turn's start, and again after the
  /// tools' results or a person's message, until the model's message is stored.
  ModelCall? call;

  /// A summary is being made while the person waits (`session.compacting`).
  bool compacting = false;

  /// generate_image's picture as it forms (`image.progress`, the page's `drawing`): how far, and
  /// the last preview (base64 PNG). Gone with the tool's result or a new history.
  ({int percent, String? preview})? drawing;

  bool get calling => call != null;

  void _newCall() => call = ModelCall(_now());

  List<ChatItem> get items =>
      buildItems(events, liveText: liveText, liveThinking: liveThinking, sessionId: sessionId);

  /// Messages waiting in line (sent while it works).
  final List<QueuedMessage> queued = [];

  void queue(QueuedMessage m) {
    queued.add(m);
    notifyListeners();
  }

  void unqueue(String clientId) {
    queued.removeWhere((q) => q.clientId == clientId);
    notifyListeners();
  }

  /// In a model call that has not written text yet (or is reasoning): the mascot «thinks».
  bool get thinking => running && calling && liveText.isEmpty;

  void _add(RgEvent e) {
    if (events.isNotEmpty && e.seq <= events.last.seq) return;
    events.add(e);
    if (e.type == 'message.user' && queued.isNotEmpty) {
      final said = (e.payload?['text'] as String? ?? '').trim();
      final at = queued.indexWhere((q) => q.match.trim() == said);
      if (at >= 0) queued.removeAt(at);
    }
    if (e.type == 'tool.result') drawing = null;
    // A tool runs (2026-11-19: an engine's own picture comes without a model message first): no
    // model call is under way until its result.
    if (e.type == 'tool.call') call = null;
    if (e.type == 'message.assistant') {
      liveText = '';
      liveThinking = '';
      call = null;
    }
    if ((e.type == 'tool.result' || e.type == 'message.user') && running) _newCall();
  }

  void changed() => notifyListeners();

  /// «Cancella per sempre» (3.9.8): these events lose their words here at once, as in the log.
  void erase(Iterable<int> seqs) {
    final gone = seqs.toSet();
    for (var i = 0; i < events.length; i++) {
      final e = events[i];
      if (gone.contains(e.seq)) {
        events[i] = RgEvent(seq: e.seq, ts: e.ts, type: e.type, sessionId: e.sessionId);
      }
    }
    notifyListeners();
  }
}

/// An agent showed something in the Canvas, live (the page's `canvasEvent`, G42.2): a file or an
/// agent's port to open (or, [keep], to bring forward as it is: the agent moving in it).
class CanvasShown {
  const CanvasShown({
    required this.sessionId,
    required this.seq,
    required this.title,
    required this.target,
    this.keep = false,
  });

  final String sessionId;
  final int seq;
  final String title;

  /// `{kind: file, scope, path}` or `{kind: port, agentId, port, path?}`.
  final Map<String, dynamic> target;
  final bool keep;
}

/// The agents' shared browser as the app watches it (G42.3, the page's Screen.tsx): the latest
/// frame (`browser.frame`, JPEG), who has control and where it is (`browser.state`).
class BrowserView extends ChangeNotifier {
  Uint8List? frame;
  int width = 0;
  int height = 0;

  /// agents or person.
  String control = 'agents';
  String url = '';

  /// The assistant being taught a task now, if any.
  String? teaching;

  /// The server has no browser (no Docker): `error` with `unavailable` while watching.
  bool unavailable = false;
  bool watching = false;

  bool get mine => control == 'person';

  void apply(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'browser.frame':
        try {
          frame = base64Decode(m['data'] as String? ?? '');
        } on FormatException {
          return;
        }
        width = (m['width'] as num?)?.toInt() ?? width;
        height = (m['height'] as num?)?.toInt() ?? height;
      case 'browser.state':
        control = m['control'] == 'person' ? 'person' : 'agents';
        url = m['url'] as String? ?? '';
        teaching = m['teaching'] as String?;
      case 'error' when watching && m['code'] == 'unavailable':
        unavailable = true;
      default:
        return;
    }
    notifyListeners();
  }

  void reset() {
    frame = null;
    unavailable = false;
    control = 'agents';
    url = '';
    teaching = null;
  }
}

class LiveModel extends ChangeNotifier {
  LiveModel({DateTime Function()? now}) : now = now ?? DateTime.now;

  /// How long an agent stays awake after its last answer to the person (the page's `ACTIVE_FOR_MS`).
  static const activeFor = Duration(minutes: 2);

  /// The clock (tests give a fake one).
  final DateTime Function() now;
  Timer? _asleep;
  DateTime? _asleepAt;

  List<SessionRow> sessions = const [];
  List<PermissionRequest> approvals = const [];
  List<QuestionRequest> questions = const [];
  final Map<String, SessionView> views = {};

  /// The person's agents at work and the line of turns waiting for a place (3.8.10).
  TurnQueue turns = TurnQueue.empty;

  /// What agents show in the Canvas while the person watches (G42.2): once per event, never when
  /// the log replays. The conversation on screen opens its Canvas with it, as the page does.
  final _canvasShown = StreamController<CanvasShown>.broadcast();
  Stream<CanvasShown> get canvasShown => _canvasShown.stream;
  final _canvasSeen = <String>{};

  /// A `canvas.show` or `canvas.act` seen live (the page's `canvasEvent`): the followed copy and
  /// the owner-wide one (`canvas.open`) may both come; the first one counts.
  void _canvasEvent(String sid, Map<String, dynamic> e) {
    final type = e['type'];
    if (type != 'canvas.show' && type != 'canvas.act') return;
    final p = e['payload'];
    if (p is! Map<String, dynamic> || p['target'] is! Map<String, dynamic>) return;
    final key = '$sid:${e['seq']}';
    if (!_canvasSeen.add(key)) return;
    if (_canvasSeen.length > 500) _canvasSeen.remove(_canvasSeen.first);
    _canvasShown.add(
      CanvasShown(
        sessionId: sid,
        seq: (e['seq'] as num?)?.toInt() ?? 0,
        title: p['title'] is String ? p['title'] as String : '',
        target: p['target'] as Map<String, dynamic>,
        keep: type == 'canvas.act',
      ),
    );
  }

  /// Group chats changed (`room.changed`): the number goes up, [lastRoom] says which.
  final roomsChanged = ValueNotifier<int>(0);
  String? lastRoom;

  /// A board changed (`board.changed`): the number goes up, [lastThread] says which thread.
  final boardChanged = ValueNotifier<int>(0);
  String? lastThread;

  /// An automation was edited or one of its runs started or ended (`automations.changed`, G42.9):
  /// the number goes up, Settings › Automations reads its list again.
  final automationsChanged = ValueNotifier<int>(0);

  /// G42.17: the history of changes moved (`platform.changed`): Settings › Platform reads it again.
  final platformChanged = ValueNotifier<int>(0);

  /// 3.12: God's topics changed (`topics.changed`, `session.routed`): «Oggi» reads them again.
  final topicsChanged = ValueNotifier<int>(0);

  /// The server's own error on the live link (`error`, 3.10, G42.17b): what the page shows as its
  /// `lastError`; the app shows it once as a notice. The browser's `unavailable` is not one.
  final serverError = ValueNotifier<String?>(null);

  /// The automations' messages for the person (`automation.notice`, `notify.to: [web]`), newest
  /// first, the latest 50 (the page's bell keeps the same).
  List<AutomationNotice> notices = const [];

  /// «Dismiss» on one of [notices].
  void dismissNotice(String runId) {
    notices = notices.where((n) => n.runId != runId).toList();
    notifyListeners();
  }

  /// The shared browser, while a screen watches it.
  final browser = BrowserView();

  /// Where the last answered request was decided (`via`), for the person to see.
  String? lastClosedVia;

  /// How each request closed while the app watched (p3.8.9): the answer and where it was given,
  /// for a request's screen still open in this window («You already answered from the page:
  /// allowed»). The latest 100.
  final Map<String, ({String decision, String? via})> closedRequests = {};

  /// A conversation the app did not list: the caller reloads the rows.
  VoidCallback? onUnknownSession;

  /// The server said the owner's agents, projects or conversation rows changed elsewhere
  /// (`lists.changed`, p3.8.9: another page or device, God, an automation): the caller reads
  /// those lists again. Also called with `agents` for an agent the app does not know yet.
  void Function(Set<String> lists)? onListsChanged;

  /// Whether the app knows this agent (the caller's team); null: never asked.
  bool Function(String agentId)? knowsAgent;

  /// A turn ended (`session.state` not running): the header's spending is read again.
  VoidCallback? onTurnEnded;

  int get forYou => approvals.length + questions.length;

  /// What «For you» counts: the requests and the automations' messages (G42.9, the page's `waiting`).
  int get waiting => forYou + notices.length;
  int get inProgress => sessions.where((s) => s.running && !s.archived).length;

  List<PersonRequest> get requests =>
      [...approvals, ...questions]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  SessionView view(String sessionId) =>
      views.putIfAbsent(sessionId, () => SessionView(sessionId, now: now));

  void setSessions(List<SessionRow> rows, {bool fresh = false}) {
    // A conversation the socket said runs keeps running until it says otherwise; [fresh] rows
    // (read after the link came back: the socket may have missed the end) are taken as they are.
    final live = fresh ? const <String, bool>{} : {for (final s in sessions) s.id: s.running};
    sessions = [for (final r in rows) live[r.id] == true && !r.running ? r.withRunning(true) : r];
    notifyListeners();
  }

  /// Something set from outside (the line after «Passa avanti»): the screens draw again.
  void changed() => notifyListeners();

  void setApprovals(List<PermissionRequest> list) {
    approvals = list;
    notifyListeners();
  }

  void clear() {
    sessions = const [];
    approvals = const [];
    questions = const [];
    turns = TurnQueue.empty;
    for (final v in views.values) {
      v.dispose();
    }
    views.clear();
    notifyListeners();
  }

  /// One message from `/ws`.
  void apply(Map<String, dynamic> m) {
    final type = m['type'];
    final sid = m['sessionId'] is String ? m['sessionId'] as String : null;
    switch (type) {
      // A new link (the first or after a drop): the server sends every waiting request again right
      // after it, so the ones answered meanwhile elsewhere go; a followed conversation's
      // `session.state` comes again too (the rows are read again by the caller, [setSessions]).
      case 'welcome':
        approvals = const [];
        questions = const [];
        for (final v in views.values) {
          if (v.running) {
            v.running = false;
            v.call = null;
            v.compacting = false;
            v.liveText = '';
            v.liveThinking = '';
            v.changed();
          }
        }
      case 'permission.request':
        final r = PermissionRequest.fromJson(_map(m['request']));
        approvals = [...approvals.where((a) => a.requestId != r.requestId), r];
      case 'permission.closed':
        approvals = approvals.where((a) => a.requestId != m['requestId']).toList();
        lastClosedVia = m['via'] as String?;
        final id = m['requestId'];
        if (id is String) {
          closedRequests.remove(id);
          closedRequests[id] = (
            decision: m['decision'] == 'allow' ? 'allow' : 'deny',
            via: m['via'] as String?,
          );
          while (closedRequests.length > 100) {
            closedRequests.remove(closedRequests.keys.first);
          }
        }
      case 'question.request':
        final q = QuestionRequest.fromJson(_map(m['request']));
        questions = [...questions.where((a) => a.requestId != q.requestId), q];
        if (!sessions.any((s) => s.id == q.sessionId)) onUnknownSession?.call();
      case 'room.changed':
        lastRoom = m['roomId'] as String?;
        roomsChanged.value++;
        return;
      case 'board.changed':
        lastThread = m['threadId'] as String?;
        boardChanged.value++;
        return;
      case 'automations.changed':
        automationsChanged.value++;
        return;
      case 'platform.changed':
        platformChanged.value++;
        return;
      case 'topics.changed' || 'session.routed':
        topicsChanged.value++;
        return;
      case 'automation.notice':
        final n = AutomationNotice.fromWire(m);
        if (n == null || notices.any((x) => x.runId == n.runId)) return;
        notices = [n, ...notices].take(50).toList();
      case 'error' when m['code'] != 'unavailable':
        final text = m['message'];
        if (text is String && text.trim().isNotEmpty) serverError.value = text.trim();
        return;
      case 'browser.frame' || 'browser.state' || 'error':
        browser.apply(m);
        return;
      case 'turns.queue':
        turns = TurnQueue.fromJson(m);
      case 'question.closed':
        questions = questions.where((a) => a.requestId != m['requestId']).toList();
        lastClosedVia = m['via'] as String?;
      case 'lists.changed':
        final lists = {...(m['lists'] as List? ?? const []).whereType<String>()};
        if (lists.isNotEmpty) onListsChanged?.call(lists);
        return;
      case 'session.activity':
        final running = m['state'] == 'running';
        if (sid == null) break;
        if (!sessions.any((s) => s.id == sid)) onUnknownSession?.call();
        // An agent made after the team was read (God's, from the page): the team again.
        final agent = m['agentId'];
        if (agent is String && knowsAgent?.call(agent) == false) onListsChanged?.call({'agents'});
        final replied = m['repliedAt'] is String ? m['repliedAt'] as String : null;
        sessions = [
          for (final s in sessions) s.id == sid ? s.copy(running: running, repliedAt: replied) : s,
        ];
        final v = views[sid];
        if (v != null) {
          if (running && !v.running) v._newCall();
          v.running = running;
        }
      case 'session.history':
        if (sid == null) break;
        final v = view(sid);
        if (m['incremental'] != true) v.events.clear();
        // As the page: a history (after a reconnection too) ends a picture forming.
        v.drawing = null;
        for (final e in (m['events'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
          v._add(RgEvent.fromJson(e));
        }
        v.synced = true;
        v.changed();
      case 'event':
        if (sid == null) break;
        final v = view(sid);
        // Shown while the person watches: the Canvas opens by itself (not when the log replays).
        if (v.synced && !v.events.any((e) => e.seq == (m['event'] as Map?)?['seq'])) {
          _canvasEvent(sid, _map(m['event']));
        }
        v._add(RgEvent.fromJson(_map(m['event'])));
        v.changed();
      // An agent showed something from a conversation the app does not follow (the server sends
      // it to every connection of the person): the Canvas opens all the same.
      case 'canvas.open':
        if (sid != null) _canvasEvent(sid, _map(m['event']));
      case 'image.progress':
        if (sid == null) break;
        final v = view(sid);
        final preview = m['preview'] is String ? m['preview'] as String : null;
        v.drawing = (
          percent: (m['percent'] as num?)?.round().clamp(0, 100) ?? 0,
          preview: preview ?? v.drawing?.preview,
        );
        v.changed();
      case 'delta':
        if (sid == null) break;
        final v = view(sid);
        final text = m['text'] is String ? m['text'] as String : '';
        final c = v.call ?? ModelCall(now());
        c.firstToken ??= now();
        c.chars += text.length;
        c.writing = m['kind'] == 'thinking' ? 'thinking' : 'text';
        v.call = c;
        if (m['kind'] == 'thinking') {
          v.liveThinking += text;
        } else {
          v.liveText += text;
        }
        v.changed();
      case 'prefill':
        if (sid == null) break;
        final v = view(sid);
        int n(String k) => (m[k] as num?)?.round() ?? 0;
        (v.call ??= ModelCall(now())).prefill = PrefillProgress(
          total: n('total'),
          cached: n('cached'),
          processed: n('processed'),
          ms: n('ms'),
        );
        v.changed();
      case 'session.compacting':
        if (sid == null) break;
        final v = view(sid);
        v.compacting = m['busy'] == true;
        v.changed();
      case 'session.state':
        if (sid == null) break;
        final v = view(sid);
        final running = m['state'] == 'running';
        // As the page: a turn that starts running starts a new call, idle ends it
        // (a `session.state` running again for the same turn, as after a follow, keeps it).
        if (running) {
          if (!v.running || v.call == null) v._newCall();
        } else {
          v.call = null;
          v.compacting = false;
        }
        v.running = running;
        v.stopReason = m['stopReason'] as String?;
        if (!v.running) {
          v.liveText = '';
          v.liveThinking = '';
        }
        sessions = [for (final s in sessions) s.id == sid ? s.withRunning(v.running) : s];
        v.changed();
        if (!running) onTurnEnded?.call();
      default:
        return;
    }
    notifyListeners();
  }

  /// What an agent's mascot shows: the page's `agentMascotState` (packages/web/src/mascot-state.ts).
  MascotState mascotStateOf(String agentId) {
    if (approvals.any((r) => r.agentId == agentId) || questions.any((q) => q.agentId == agentId)) {
      return MascotState.wait;
    }
    final rows = sessions.where((r) => r.agentId == agentId && !r.archived).toList();
    final running = rows.where((r) => r.running);
    if (running.isNotEmpty) {
      final thinking = running.any((r) => views[r.id]?.thinking ?? false);
      return thinking ? MascotState.think : MascotState.work;
    }
    if (rows.isEmpty) return MascotState.idle;
    rows.sort((a, b) => b.when.compareTo(a.when));
    final events = views[rows.first.id]?.events;
    final last = events == null || events.isEmpty ? null : events.last;
    if (last != null && blockingEvents.contains(last.type)) return MascotState.error;
    // Awake for two minutes after answering the person.
    DateTime? replied;
    for (final r in rows) {
      final t = r.repliedAt == null ? null : DateTime.tryParse(r.repliedAt!);
      if (t != null && (replied == null || t.isAfter(replied))) replied = t;
    }
    if (replied != null) {
      final t = now();
      final until = replied.add(activeFor);
      if (t.isBefore(until) && t.isAfter(replied.subtract(const Duration(minutes: 1)))) {
        _fallAsleepAt(until);
        return MascotState.active;
      }
    }
    return MascotState.idle;
  }

  /// Tells the mascots when the first awake one falls asleep again.
  void _fallAsleepAt(DateTime at) {
    if (_asleepAt != null && !at.isBefore(_asleepAt!) && (_asleep?.isActive ?? false)) return;
    _asleep?.cancel();
    _asleepAt = at;
    _asleep = Timer(at.difference(now()) + const Duration(milliseconds: 50), () {
      _asleepAt = null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _asleep?.cancel();
    super.dispose();
  }
}

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
