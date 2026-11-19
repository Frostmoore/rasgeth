// Echo (3.9.6): past conversations searched by their words, `GET /api/conversations/search`,
// the same results as the page's box in the left bar and the agents' search_conversations.
import 'client.dart';

/// A place in a conversation with the words; [marks] are [start, end) offsets of each word found.
class EchoSnippet {
  const EchoSnippet({
    required this.role,
    required this.at,
    required this.text,
    required this.marks,
  });

  factory EchoSnippet.fromJson(Map<String, dynamic> j) => EchoSnippet(
    role: j['role'] is String ? j['role'] as String : 'other',
    at: j['at'] is String ? j['at'] as String : '',
    text: j['text'] is String ? j['text'] as String : '',
    marks: [
      for (final m in (j['marks'] is List ? j['marks'] as List : const []))
        if (m is List && m.length == 2 && m[0] is int && m[1] is int) (m[0] as int, m[1] as int),
    ],
  );

  /// "person", "agent" or "other".
  final String role;
  final String at;
  final String text;
  final List<(int, int)> marks;
}

/// One past conversation found.
class EchoHit {
  const EchoHit({
    required this.sessionId,
    required this.title,
    required this.agentId,
    required this.projectId,
    required this.at,
    required this.matches,
    required this.archived,
    required this.snippets,
  });

  factory EchoHit.fromJson(Map<String, dynamic> j) => EchoHit(
    sessionId: j['sessionId'] as String,
    title: j['title'] is String ? j['title'] as String : null,
    agentId: j['agentId'] is String ? j['agentId'] as String : '',
    projectId: j['projectId'] is String ? j['projectId'] as String : null,
    at: j['at'] is String ? j['at'] as String : '',
    matches: j['matches'] is int ? j['matches'] as int : 1,
    archived: j['archived'] == true,
    snippets: [
      for (final s in (j['snippets'] is List ? j['snippets'] as List : const []))
        if (s is Map<String, dynamic>) EchoSnippet.fromJson(s),
    ],
  );

  final String sessionId;
  final String? title;
  final String agentId;
  final String? projectId;
  final String at;
  final int matches;
  final bool archived;
  final List<EchoSnippet> snippets;
}

extension EchoApi on RedGiantClient {
  Future<List<EchoHit>> searchConversations(String query, {int limit = 20}) async {
    final r = await getJson('/api/conversations/search', {'q': query, 'limit': '$limit'});
    return [
      for (final h in (r is List ? r : const []))
        if (h is Map<String, dynamic> && h['sessionId'] is String) EchoHit.fromJson(h),
    ];
  }
}
