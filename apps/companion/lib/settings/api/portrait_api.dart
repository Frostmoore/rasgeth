// 3.9.4: the routes of Settings › Portrait («Mirror»), as the page calls them
// (`packages/web/src/api.ts`: `portrait`, `addTrait`, `editTrait`, `removeTrait`, `denyTrait`,
// `forgetPortrait`, `setPortrait`), with the shapes of `packages/protocol/src/portrait.ts` read
// leniently (a field the server does not send is its empty value).
import '../../api/client.dart';

String? _s(Object? o) => o is String ? o : null;
int _i(Object? o) => o is num ? o.toInt() : 0;
double _d(Object? o) => o is num ? o.toDouble() : 0;
Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
List<Map<String, dynamic>> _list(Object? o) => o is List
    ? [
        for (final x in o)
          if (x is Map<String, dynamic>) x,
      ]
    : const [];

/// The trait groups, in the order the page and the agents' text use.
const portraitCategories = ['preference', 'style', 'habit', 'project', 'avoid', 'about'];

class PortraitSource {
  const PortraitSource({
    required this.sessionId,
    required this.at,
    this.agentId,
    this.sessionTitle,
    this.agentName,
  });

  factory PortraitSource.fromJson(Map<String, dynamic> j) => PortraitSource(
    sessionId: _s(j['sessionId']) ?? '',
    at: _s(j['at']) ?? '',
    agentId: _s(j['agentId']),
    sessionTitle: _s(j['sessionTitle']),
    agentName: _s(j['agentName']),
  );

  final String sessionId;
  final String at;
  final String? agentId;
  final String? sessionTitle;
  final String? agentName;
}

class PortraitTrait {
  const PortraitTrait({
    required this.id,
    required this.text,
    required this.category,
    required this.confidence,
    required this.seenAt,
    required this.by,
    required this.edited,
    required this.confirmations,
    required this.sources,
  });

  factory PortraitTrait.fromJson(Map<String, dynamic> j) => PortraitTrait(
    id: _s(j['id']) ?? '',
    text: _s(j['text']) ?? '',
    category: portraitCategories.contains(j['category']) ? j['category'] as String : 'about',
    confidence: _d(j['confidence']),
    seenAt: _s(j['seenAt']) ?? '',
    by: _s(j['by']) ?? 'auto',
    edited: j['edited'] == true,
    confirmations: _i(j['confirmations']),
    sources: [for (final x in _list(j['sources'])) PortraitSource.fromJson(x)],
  );

  final String id;
  final String text;
  final String category;
  final double confidence;
  final String seenAt;
  final String by;
  final bool edited;
  final int confirmations;
  final List<PortraitSource> sources;
}

/// Which agents read the portrait when a conversation starts.
class PortraitAgents {
  const PortraitAgents({
    this.god = true,
    this.orchestrators = true,
    this.chat = true,
    this.others = false,
  });

  factory PortraitAgents.fromJson(Map<String, dynamic> j) => PortraitAgents(
    god: j['god'] != false,
    orchestrators: j['orchestrators'] != false,
    chat: j['chat'] != false,
    others: j['others'] == true,
  );

  final bool god;
  final bool orchestrators;
  final bool chat;
  final bool others;

  static const keys = ['god', 'orchestrators', 'chat', 'others'];

  bool of(String k) => switch (k) {
    'god' => god,
    'orchestrators' => orchestrators,
    'chat' => chat,
    _ => others,
  };

  PortraitAgents withValue(String k, bool on) => PortraitAgents(
    god: k == 'god' ? on : god,
    orchestrators: k == 'orchestrators' ? on : orchestrators,
    chat: k == 'chat' ? on : chat,
    others: k == 'others' ? on : others,
  );

  Map<String, Object> toJson() => {
    'god': god,
    'orchestrators': orchestrators,
    'chat': chat,
    'others': others,
  };
}

class PortraitView {
  const PortraitView({
    required this.on,
    required this.agents,
    required this.traits,
    required this.text,
    required this.denied,
  });

  factory PortraitView.fromJson(Map<String, dynamic> j) => PortraitView(
    on: j['on'] != false,
    agents: PortraitAgents.fromJson(_map(j['agents'])),
    traits: [for (final t in _list(j['traits'])) PortraitTrait.fromJson(t)],
    text: _s(j['text']) ?? '',
    denied: _i(j['denied']),
  );

  final bool on;
  final PortraitAgents agents;
  final List<PortraitTrait> traits;

  /// The portrait exactly as the agents read it ("" when none).
  final String text;
  final int denied;
}

extension PortraitApi on RedGiantClient {
  String _e(String s) => Uri.encodeComponent(s);

  Future<PortraitView> portrait() async =>
      PortraitView.fromJson(objectOf(await getJson('/api/portrait')));

  Future<void> addTrait(String text, String category) =>
      callJson('POST', '/api/portrait', {'text': text, 'category': category});

  Future<void> editTrait(String id, {String? text, String? category}) =>
      callJson('PUT', '/api/portrait/${_e(id)}', {'text': ?text, 'category': ?category});

  Future<void> removeTrait(String id) => callJson('DELETE', '/api/portrait/${_e(id)}');

  /// «Not true»: gone, and never proposed again.
  Future<void> denyTrait(String id) =>
      callJson('POST', '/api/portrait/${_e(id)}/deny', const <String, Object>{});

  Future<void> forgetPortrait() =>
      callJson('POST', '/api/portrait/forget', const <String, Object>{});

  Future<void> setPortrait({bool? on, PortraitAgents? agents}) =>
      callJson('PUT', '/api/portrait/settings', {'on': ?on, 'agents': ?agents?.toJson()});
}
