// What the live connection keeps up to date (G40.7): the conversations' rows and views, the
// requests waiting for the person and the counters «For you» and «In progress». [apply] takes one
// server message, as the page's state.ts does; it is pure enough to test without a socket.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'conversation.dart';
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
    if (e.type == 'message.assistant') {
      liveText = '';
      liveThinking = '';
      call = null;
    }
    if ((e.type == 'tool.result' || e.type == 'message.user') && running) _newCall();
  }

  void changed() => notifyListeners();
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

  /// Where the last answered request was decided (`via`), for the person to see.
  String? lastClosedVia;

  /// How each request closed while the app watched (p3.8.9): the answer and where it was given,
  /// for a request's screen still open in this window («You already answered from the page:
  /// allowed»). The latest 100.
  final Map<String, ({String decision, String? via})> closedRequests = {};

  /// A conversation the app did not list: the caller reloads the rows.
  VoidCallback? onUnknownSession;

  /// A turn ended (`session.state` not running): the header's spending is read again.
  VoidCallback? onTurnEnded;

  int get forYou => approvals.length + questions.length;
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

  void setApprovals(List<PermissionRequest> list) {
    approvals = list;
    notifyListeners();
  }

  void clear() {
    sessions = const [];
    approvals = const [];
    questions = const [];
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
      case 'question.closed':
        questions = questions.where((a) => a.requestId != m['requestId']).toList();
        lastClosedVia = m['via'] as String?;
      case 'session.activity':
        final running = m['state'] == 'running';
        if (sid == null) break;
        if (!sessions.any((s) => s.id == sid)) onUnknownSession?.call();
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
        for (final e in (m['events'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
          v._add(RgEvent.fromJson(e));
        }
        v.synced = true;
        v.changed();
      case 'event':
        if (sid == null) break;
        final v = view(sid);
        v._add(RgEvent.fromJson(_map(m['event'])));
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
