// The simple interface's state (3.12, the page's `state.ts` «The simple interface»): God's topics
// for «Oggi», the archive's search and the actions (ask God, move, archive, restore, read), with
// the pure rules the page has (`effectiveUi`, `greetingKey`).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../api/conversation.dart' show RgEvent, SessionRow;
import '../api/topics.dart';
import '../api/types.dart' show MascotState;

/// The interface to show: the device's choice, else the installation's, else the simple one
/// (3.12.1: an installation that never chose opens with the simple interface).
String effectiveUi(String? device, String? installed) => device ?? installed ?? 'simple';

/// A server before 3.12 answers 404 to God's topics (the page's `topicsMissing`).
bool topicsMissing(int status) => status == 404;

/// The greeting's words for the hour (the page's `greetingKey`).
String greetingKey(int hour) => hour >= 5 && hour < 13
    ? 'smpMorning'
    : hour >= 13 && hour < 18
    ? 'smpAfternoon'
    : 'smpEvening';

// ---------- God's giant mascot on «Oggi» (3.12.1, the page's `giantMood`) ----------

enum GiantMood { rest, listen, think, work, wait, happy, worried }

/// The mood from the page's real facts, the most urgent first (the page's `giantMood`).
GiantMood giantMood({
  bool typing = false,
  bool routing = false,
  bool working = false,
  bool waiting = false,
  bool happy = false,
  bool error = false,
}) {
  if (error) return GiantMood.worried;
  if (routing) return GiantMood.think;
  if (typing) return GiantMood.listen;
  if (happy) return GiantMood.happy;
  if (waiting) return GiantMood.wait;
  if (working) return GiantMood.work;
  return GiantMood.rest;
}

/// The drawing's state for each mood (the page's `GIANT_STATE`).
MascotState giantState(GiantMood m) => switch (m) {
  GiantMood.rest || GiantMood.listen || GiantMood.happy => MascotState.active,
  GiantMood.think => MascotState.think,
  GiantMood.work => MascotState.work,
  GiantMood.wait => MascotState.wait,
  GiantMood.worried => MascotState.error,
};

/// A still mascot's small gestures (the page's `IDLE_GESTURES`).
enum IdleGesture { lookL, lookR, hop, wiggle, wink, nod }

/// The next gesture: any of [from] but [last], so never the same twice in a row.
IdleGesture nextGesture(IdleGesture? last, List<IdleGesture> from, double Function() rand) {
  final pool = from.where((g) => g != last).toList();
  final list = pool.isEmpty ? from : pool;
  return list[(rand() * list.length).floor().clamp(0, list.length - 1)];
}

/// How long a still mascot waits before its next gesture: 3.5 to 8 s, never a fixed beat.
Duration gestureDelay(double Function() rand) =>
    Duration(milliseconds: (3500 + rand() * 4500).round());

/// How long a gesture lasts.
Duration gestureLength(IdleGesture g) => Duration(
  milliseconds: switch (g) {
    IdleGesture.lookL || IdleGesture.lookR => 1600,
    IdleGesture.hop => 800,
    IdleGesture.wink => 700,
    IdleGesture.wiggle || IdleGesture.nod => 900,
  },
);

/// Whether a topic that was at work is now ready (a piece of work finished).
bool finishedWork(List<TopicView> before, List<TopicView> after) {
  final was = {for (final x in before) x.id: x.state};
  return after.any((x) => x.state == TopicState.ready && was[x.id] == TopicState.working);
}

// ---------- Satellite and the Chat on «Oggi» (3.12.1, the page's `stageFront`) ----------

/// Who is in front on the orbit: God or Satellite (the Chat).
enum StageFront { god, chat }

/// How far round the orbit the one behind sits (radians, the page's `ORBIT_BACK`).
const double orbitBack = 2.55;

/// Where a mascot at [theta] on the orbit is drawn (the page's `orbitPlace`).
({double x, double y, double scale, int z, double light}) orbitPlace(double theta, double radius) {
  final z = math.cos(theta);
  final near = (z + 1) / 2;
  double r(double v) => (v * 100).round() / 100;
  return (
    x: r(math.sin(theta) * radius * 0.95),
    y: r((1 - z) * -38),
    scale: r(0.42 + 0.58 * near),
    z: (z * 100).round() + 100,
    light: r(0.55 + 0.45 * near),
  );
}

/// The Chat's latest conversations, newest first (the page's `recentChats`).
List<SessionRow> recentChats(List<SessionRow> rows, String? chatId, [int n = 5]) {
  if (chatId == null) return const [];
  final list = rows.where((r) => r.agentId == chatId && !r.archived).toList()
    ..sort((a, b) => (b.lastAt ?? b.createdAt).compareTo(a.lastAt ?? a.createdAt));
  return list.take(n).toList();
}

// ---------- A conversation in the simple interface (3.12.1, the page's `workWord`) ----------

/// Tools that look things up: the agent «is searching».
final _searchTools = RegExp('search|fetch|browse|read_url|web|lookup|find', caseSensitive: false);

/// What the agent is doing, in a word: `wait`, `think`, `search`, `work`; null when idle.
String? workWord(
  List<RgEvent> events, {
  required bool running,
  bool thinking = false,
  bool waiting = false,
}) {
  if (waiting) return 'wait';
  if (!running) return null;
  if (thinking) return 'think';
  final open = <String, String>{};
  for (final e in events) {
    final p = e.payload;
    if (p == null) continue;
    if (e.type == 'tool.call' && p['callId'] is String) {
      open[p['callId'] as String] = '${p['tool'] ?? ''}';
    } else if (e.type == 'tool.result') {
      open.remove(p['callId']);
    }
  }
  if (open.isEmpty) return 'think';
  return _searchTools.hasMatch(open.values.last) ? 'search' : 'work';
}

/// What a conversation cost so far, in dollars (shown at the top, for everyone).
double conversationCost(List<RgEvent> events) {
  var usd = 0.0;
  for (final e in events) {
    final c = e.payload?['costUsd'];
    if (e.type == 'message.assistant' && c is num) usd += c.toDouble();
  }
  return usd;
}

/// A ready-made assistant for everyday life (3.12, «Assistenti pronti»: still to be defined with
/// the person). «Oggi» shows them when [SimpleModel.assistants] has some; empty, nothing shows.
class SimpleAssistant {
  const SimpleAssistant({
    required this.id,
    required this.name,
    required this.line,
    required this.ask,
  });

  final String id;
  final String name;
  final String line;

  /// The first message to God that puts it to work.
  final String ask;
}

class SimpleModel extends ChangeNotifier {
  SimpleModel(this._client);

  final RedGiantClient? Function() _client;

  List<TopicView> topics = const [];
  int archivedCount = 0;
  bool loaded = false;
  List<TopicView> archived = const [];

  /// The ready-made assistants: none yet.
  List<SimpleAssistant> assistants = const [];

  /// The last error, in the server's words (shown once by the screen).
  String? error;

  /// Why the topics did not come (3.12.1, the page's `topicsTrouble`): `old`, a server before 3.12
  /// (no `/api/god/topics`, 404); `failed`, any other error. Null while they come, or once they came.
  String? trouble;

  Timer? _soon;

  /// The person is writing in «Oggi»'s box (the giant listens), a moment after the last key too.
  bool typing = false;
  Timer? _typing;

  /// A message to God is being routed (the giant thinks).
  bool routing = false;

  /// What the person sent from «Oggi» while God chooses its topic (shown at once, 3.12.1).
  String? routingText;

  /// God's nudge shown under him on «Oggi» (3.12.1), until opened or closed.
  GodNudge? nudge;

  /// A generic nudge opened: its words invite the person in «Oggi», until they write.
  String? invite;

  /// A topic a nudge opened, for «Oggi» to push once.
  String? openTopicId;

  void showNudge(GodNudge n) {
    if (nudge?.id == n.id) return;
    nudge = n;
    notifyListeners();
  }

  void closeNudge() {
    nudge = null;
    notifyListeners();
  }

  /// Opens a nudge: its topic, or only «Oggi» with the invitation. Nothing is created: a topic
  /// comes only when the person writes, and the nudge is written into no topic.
  void openNudge({String? topicId, String? text}) {
    nudge = null;
    front = StageFront.god;
    if (topicId != null) {
      openTopicId = topicId;
    } else {
      invite = text;
    }
    notifyListeners();
  }

  /// The person wrote: the invitation has done its job.
  void wrote() {
    if (invite == null) return;
    invite = null;
    notifyListeners();
  }

  /// Who is in front on «Oggi»'s orbit (3.12.1).
  StageFront front = StageFront.god;

  void bringFront(StageFront who) {
    if (front == who) return;
    front = who;
    typing = false;
    notifyListeners();
  }

  /// The conversation the big box sent to last (God's topic, or the Chat's new conversation):
  /// «Stop» on «Oggi» stops its turn (3.12.2).
  String? lastSent;

  /// A message to the Chat is on its way (Satellite thinks).
  bool chatSending = false;

  /// From «Oggi» with Satellite in front: a new conversation with the Chat agent and its first
  /// message (sent by [send], the app's own way). The conversation's id, or null.
  Future<String?> askChat(
    String text, {
    required Future<String?> Function() chatAgent,
    required Future<bool> Function(String sessionId, String text, List<Map<String, Object?>> images)
    send,
    List<Map<String, Object?>> images = const [],
  }) async {
    final words = text.trim();
    if (words.isEmpty) return null;
    chatSending = true;
    notifyListeners();
    try {
      final id = await chatAgent();
      if (id == null) return null;
      final sid = await _try((c) => c.newSession(id));
      if (sid == null) return null;
      if (!await send(sid, words, images)) return null;
      lastSent = sid;
      return sid;
    } finally {
      chatSending = false;
      notifyListeners();
    }
  }

  /// A piece of work just finished (the giant is happy for a few seconds).
  bool cheer = false;
  Timer? _cheer;

  void typed(String words) {
    final now = words.trim().isNotEmpty;
    _typing?.cancel();
    if (now) {
      _typing = Timer(const Duration(milliseconds: 2500), () {
        typing = false;
        notifyListeners();
      });
    }
    if (now == typing) return;
    typing = now;
    notifyListeners();
  }

  void cheerUp([Duration d = const Duration(seconds: 4)]) {
    cheer = true;
    _cheer?.cancel();
    _cheer = Timer(d, () {
      cheer = false;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> refresh() async {
    final c = _client();
    if (c == null) return;
    try {
      final l = await c.topics();
      if (loaded && finishedWork(topics, l.topics)) cheerUp();
      topics = l.topics;
      archivedCount = l.archived;
      loaded = true;
      trouble = null;
      notifyListeners();
    } on ApiException catch (e) {
      // Never «Un momento…» for ever: say why (the screen offers what to do); the next change
      // tries again.
      if (!loaded) {
        trouble = topicsMissing(e.status) ? 'old' : 'failed';
        notifyListeners();
      }
    }
  }

  void refreshSoon() {
    if (_soon?.isActive ?? false) return;
    _soon = Timer(const Duration(milliseconds: 200), () => unawaited(refresh()));
  }

  Future<void> searchArchive(String q) async {
    final c = _client();
    if (c == null) return;
    try {
      archived = (await c.topics(archived: true, q: q)).topics;
      notifyListeners();
    } on ApiException {
      // Kept as it was.
    }
  }

  TopicView? topic(String id) =>
      topics.where((t) => t.id == id).firstOrNull ?? archived.where((t) => t.id == id).firstOrNull;

  String? titleOf(String id) => topic(id)?.title;

  Future<T?> _try<T>(Future<T> Function(RedGiantClient c) f) async {
    final c = _client();
    if (c == null) return null;
    try {
      error = null;
      return await f(c);
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      return null;
    }
  }

  /// A message to God: routed (null [topicId]) or written inside a topic. Where it went, or null.
  Future<TopicSent?> ask(
    String text, {
    String? topicId,
    List<Map<String, Object?>> images = const [],
  }) async {
    final words = text.trim();
    if (words.isEmpty) return null;
    routing = true;
    if (topicId == null) routingText = words;
    notifyListeners();
    final r = await _try((c) => c.godMessage(words, topicId: topicId, images: images));
    routing = false;
    routingText = null;
    if (r != null) lastSent = r.sessionId;
    notifyListeners();
    if (r != null) refreshSoon();
    return r;
  }

  /// «Move» the exchange at [seq] to [to] (a topic's id, or `new` with [title]).
  Future<TopicSent?> move(String sessionId, int seq, String to, {String? title}) async {
    final r = await _try((c) => c.moveMessage(sessionId, seq, to, title: title));
    if (r != null) refreshSoon();
    return r;
  }

  /// Opened: its news count as read.
  void opened(String id) {
    final t = topics.where((x) => x.id == id).firstOrNull;
    if (t == null || t.unread == 0) return;
    topics = [for (final x in topics) x.id == id ? x.read() : x];
    notifyListeners();
    unawaited(_try((c) => c.topicAction(id, 'read')));
  }

  Future<bool> archive(String id) async {
    final ok = await _try((c) async {
      await c.topicAction(id, 'archive');
      return true;
    });
    if (ok != true) return false;
    topics = topics.where((t) => t.id != id).toList();
    archivedCount++;
    notifyListeners();
    refreshSoon();
    return true;
  }

  Future<bool> restore(String id) async {
    final ok = await _try((c) async {
      await c.topicAction(id, 'restore');
      return true;
    });
    if (ok != true) return false;
    await refresh();
    return true;
  }

  Future<void> rename(String id, String title) async {
    await _try((c) => c.renameSession(id, title));
    await refresh();
  }

  Future<void> pin(String id, bool pinned) async {
    await _try((c) => c.updateSession(id, pinned: pinned));
    await refresh();
  }

  void clear() {
    topics = const [];
    archived = const [];
    archivedCount = 0;
    loaded = false;
    trouble = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _soon?.cancel();
    _typing?.cancel();
    _cheer?.cancel();
    super.dispose();
  }
}
