// 3.12: God's topics, as the page calls them (`packages/web/src/api.ts`: `topics`, `godMessage`,
// `moveMessage`, `topicAction`, `setupInterface`, `setupPerson`), with the shapes of
// `packages/protocol/src/topics.ts` read leniently (a field the server does not send is its empty
// value).
import 'client.dart';

String? _s(Object? o) => o is String ? o : null;
int _i(Object? o) => o is num ? o.toInt() : 0;
List<Map<String, dynamic>> _list(Object? o) => o is List
    ? [
        for (final x in o)
          if (x is Map<String, dynamic>) x,
      ]
    : const [];

/// «ti aspetto», «al lavoro», «pronto» (`TopicState`).
enum TopicState {
  waiting,
  working,
  ready;

  static TopicState parse(Object? o) => switch (o) {
    'waiting' => TopicState.waiting,
    'working' => TopicState.working,
    _ => TopicState.ready,
  };
}

/// One topic as «Oggi» lists it (`TopicView`).
class TopicView {
  const TopicView({
    required this.id,
    required this.title,
    this.summary,
    this.state = TopicState.ready,
    this.lastAt,
    this.personAt,
    this.createdAt = '',
    this.pinned = false,
    this.archived = false,
    this.unread = 0,
    this.requests = 0,
    this.tasks = 0,
    this.projectId,
    this.from,
  });

  factory TopicView.fromJson(Map<String, dynamic> j) => TopicView(
    id: _s(j['id']) ?? '',
    title: _s(j['title']) ?? '',
    summary: _s(j['summary']),
    state: TopicState.parse(j['state']),
    lastAt: _s(j['lastAt']),
    personAt: _s(j['personAt']),
    createdAt: _s(j['createdAt']) ?? '',
    pinned: j['pinned'] == true,
    archived: j['archived'] == true,
    unread: _i(j['unread']),
    requests: _i(j['requests']),
    tasks: _i(j['tasks']),
    projectId: _s(j['projectId']),
    from: _s(j['from']),
  );

  final String id;
  final String title;
  final String? summary;
  final TopicState state;
  final String? lastAt;
  final String? personAt;
  final String createdAt;
  final bool pinned;
  final bool archived;
  final int unread;
  final int requests;
  final int tasks;
  final String? projectId;

  /// The assistant whose request opened it («da Ada»).
  final String? from;

  TopicView read() => TopicView(
    id: id,
    title: title,
    summary: summary,
    state: state,
    lastAt: lastAt,
    personAt: personAt,
    createdAt: createdAt,
    pinned: pinned,
    archived: archived,
    requests: requests,
    tasks: tasks,
    projectId: projectId,
    from: from,
  );
}

/// `TopicList`: the active topics (or the archive's) and how many are archived.
class TopicList {
  const TopicList(this.topics, this.archived);

  factory TopicList.fromJson(Map<String, dynamic> j) =>
      TopicList([for (final t in _list(j['topics'])) TopicView.fromJson(t)], _i(j['archived']));

  final List<TopicView> topics;
  final int archived;
}

/// What the router decided for one message (`TopicRouted`).
class TopicRouted {
  const TopicRouted({
    required this.topicId,
    required this.title,
    this.via = 'router',
    this.isNew = false,
    this.restored = false,
    this.uncertain = false,
  });

  factory TopicRouted.fromJson(Map<String, dynamic> j) => TopicRouted(
    topicId: _s(j['topicId']) ?? '',
    title: _s(j['title']) ?? '',
    via: _s(j['via']) ?? 'router',
    isNew: j['isNew'] == true,
    restored: j['restored'] == true,
    uncertain: j['uncertain'] == true,
  );

  final String topicId;
  final String title;
  final String via;
  final bool isNew;
  final bool restored;
  final bool uncertain;
}

/// Where a message to God went (`GodMessageResponse`, `MoveResponse`).
class TopicSent {
  const TopicSent(this.sessionId, this.routed);

  factory TopicSent.fromJson(Map<String, dynamic> j) => TopicSent(
    _s(j['sessionId']) ?? '',
    TopicRouted.fromJson(
      j['routed'] is Map<String, dynamic> ? j['routed'] as Map<String, dynamic> : const {},
    ),
  );

  final String sessionId;
  final TopicRouted routed;
}

extension TopicsApi on RedGiantClient {
  /// `GET /api/god/topics`: the active ones; [archived] the archive, [q] words in it.
  Future<TopicList> topics({bool archived = false, String? q}) async => TopicList.fromJson(
    objectOf(
      await getJson('/api/god/topics', {
        if (archived) 'archived': 'true',
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      }),
    ),
  );

  /// `POST /api/god/messages`: routed by God, or written inside [topicId].
  Future<TopicSent> godMessage(
    String text, {
    String? topicId,
    bool newTopic = false,
    String? title,
  }) async => TopicSent.fromJson(
    objectOf(
      await callJson('POST', '/api/god/messages', {
        'text': text,
        'topicId': ?topicId,
        if (newTopic) 'newTopic': true,
        'title': ?title,
      }),
    ),
  );

  /// `POST /api/sessions/:id/messages/:seq/move`: «Move» to [to] (a topic's id, or `new`).
  Future<TopicSent> moveMessage(String sessionId, int seq, String to, {String? title}) async =>
      TopicSent.fromJson(
        objectOf(
          await callJson(
            'POST',
            '/api/sessions/${Uri.encodeComponent(sessionId)}/messages/$seq/move',
            {'to': to, if (title != null && title.trim().isNotEmpty) 'title': title.trim()},
          ),
        ),
      );

  /// `POST /api/god/topics/:id/archive | restore | read`.
  Future<void> topicAction(String id, String what) =>
      callJson('POST', '/api/god/topics/${Uri.encodeComponent(id)}/$what');

  /// `PUT /api/setup/interface`: the interface new devices open with.
  Future<void> setupInterface(String ui) => callJson('PUT', '/api/setup/interface', {'ui': ui});

  /// `PUT /api/setup/person`: what the person likes to be called (null: no name).
  Future<void> setupPerson(String? name) => callJson('PUT', '/api/setup/person', {'name': name});
}
