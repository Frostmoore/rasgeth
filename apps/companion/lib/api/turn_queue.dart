// Agents at work together (3.8.10): the person's limit and the line of turns waiting for a place,
// as the server sends it (`turns.queue` after the welcome and at every change, `GET /api/turns`).
// The line is in the order its turns will start; «2nd of 3» is a conversation's place in it.

/// One turn waiting for a place.
class QueuedTurn {
  const QueuedTurn({
    required this.sessionId,
    required this.agentId,
    required this.since,
    this.child = false,
    this.first = false,
  });

  final String sessionId;
  final String agentId;

  /// When it started waiting.
  final DateTime? since;

  /// Asked by a turn that waits for its answer (a sub-agent): it goes before the others.
  final bool child;

  /// The person moved it to the front.
  final bool first;

  static QueuedTurn? fromJson(Object? o) {
    if (o is! Map) return null;
    final sid = o['sessionId'];
    final aid = o['agentId'];
    if (sid is! String || aid is! String) return null;
    return QueuedTurn(
      sessionId: sid,
      agentId: aid,
      since: o['since'] is String ? DateTime.tryParse(o['since'] as String) : null,
      child: o['child'] == true,
      first: o['first'] == true,
    );
  }
}

/// A place in line: «[place]° di [of]».
typedef LinePlace = ({int place, int of});

/// The person's agents at work and their line.
class TurnQueue {
  const TurnQueue({this.limit, this.working = 0, this.running = const [], this.queued = const []});

  static const empty = TurnQueue();

  /// The person's limit; null: no limit.
  final int? limit;

  /// Turns holding a place.
  final int working;

  /// Every turn at work: (sessionId, agentId).
  final List<({String sessionId, String agentId})> running;

  /// The line, in the order it starts.
  final List<QueuedTurn> queued;

  bool get isEmpty => queued.isEmpty;

  /// Worth a line in the status bar: someone waits or the person chose a limit.
  bool get shown => queued.isNotEmpty || limit != null;

  static TurnQueue fromJson(Map<String, dynamic> m) => TurnQueue(
    limit: m['limit'] is num ? (m['limit'] as num).toInt() : null,
    working: m['working'] is num ? (m['working'] as num).toInt() : 0,
    running: [
      for (final r in (m['running'] is List ? m['running'] as List : const []))
        if (r is Map && r['sessionId'] is String && r['agentId'] is String)
          (sessionId: r['sessionId'] as String, agentId: r['agentId'] as String),
    ],
    queued: [
      for (final q in (m['queued'] is List ? m['queued'] as List : const []))
        ?QueuedTurn.fromJson(q),
    ],
  );

  /// A conversation's place in line, if it waits.
  LinePlace? placeOf(String sessionId) {
    final i = queued.indexWhere((q) => q.sessionId == sessionId);
    return i < 0 ? null : (place: i + 1, of: queued.length);
  }

  /// The first place in line of any conversation of this agent, if one waits.
  LinePlace? placeOfAgent(String agentId) {
    final i = queued.indexWhere((q) => q.agentId == agentId);
    return i < 0 ? null : (place: i + 1, of: queued.length);
  }

  /// The person moved [sessionId] first: the line as the server will send it next.
  TurnQueue withFirst(String sessionId) {
    final i = queued.indexWhere((q) => q.sessionId == sessionId);
    if (i <= 0) return this;
    final q = queued[i];
    final moved = QueuedTurn(
      sessionId: q.sessionId,
      agentId: q.agentId,
      since: q.since,
      child: q.child,
      first: true,
    );
    return TurnQueue(
      limit: limit,
      working: working,
      running: running,
      queued: [moved, ...queued.where((x) => x.sessionId != sessionId)],
    );
  }
}
