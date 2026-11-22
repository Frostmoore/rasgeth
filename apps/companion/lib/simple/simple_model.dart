// The simple interface's state (3.12, the page's `state.ts` «The simple interface»): God's topics
// for «Oggi», the archive's search and the actions (ask God, move, archive, restore, read), with
// the pure rules the page has (`effectiveUi`, `greetingKey`).
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/client.dart';
import '../api/topics.dart';

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

  Future<void> refresh() async {
    final c = _client();
    if (c == null) return;
    try {
      final l = await c.topics();
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
  Future<TopicSent?> ask(String text, {String? topicId}) async {
    final words = text.trim();
    if (words.isEmpty) return null;
    final r = await _try((c) => c.godMessage(words, topicId: topicId));
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
    super.dispose();
  }
}
