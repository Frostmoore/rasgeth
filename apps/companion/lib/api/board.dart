// A board of variants ("tavola", G25.4) in the app (G42.2): the page's `boardOf` (Variants.tsx)
// over a conversation's events, the person's answers, and a board's link from a chat
// (`#tavola=<session>.<proposal>`, as Telegram sends it). The app draws the board natively; each
// variant is the page inside a web view (`embed=board&variant=n&screen=…`).
import '../embed/embed_link.dart' show boardScreens;

class BoardVariant {
  const BoardVariant({required this.title, this.note, this.bytes = 0});

  final String title;
  final String? note;
  final int bytes;
}

/// What the person said: a choice (with its comment, if any) or a comment, on a variant (1-based)
/// or on the whole board (null).
class BoardAnswer {
  const BoardAnswer({required this.variant, required this.choice, this.comment, required this.ts});

  final int? variant;
  final bool choice;
  final String? comment;
  final String ts;
}

class Board {
  const Board({
    required this.proposalId,
    required this.title,
    this.description,
    required this.variants,
    required this.at,
    required this.answers,
    required this.chosen,
  });

  final String proposalId;
  final String title;
  final String? description;
  final List<BoardVariant> variants;

  /// When it was published (the event's `ts`).
  final String at;
  final List<BoardAnswer> answers;

  /// The variant chosen last, or null.
  final int? chosen;

  List<BoardAnswer> answersOn(int? variant) => [
    for (final a in answers)
      if (a.variant == variant) a,
  ];
}

String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

/// The board [proposalId] and what was said about it, from a conversation's events (the page's
/// `boardOf`): the last `variants.proposed` with that id, every `variants.answered`, the last choice.
Board? boardOf(List<Map<String, dynamic>> events, String proposalId) {
  Map<String, dynamic>? proposed;
  var at = '';
  final answers = <BoardAnswer>[];
  for (final e in events) {
    final p = e['payload'];
    if (p is! Map<String, dynamic> || p['proposalId'] != proposalId) continue;
    if (e['type'] == 'variants.proposed') {
      proposed = p;
      at = '${e['ts'] ?? ''}';
    } else if (e['type'] == 'variants.answered') {
      answers.add(
        BoardAnswer(
          variant: (p['variant'] as num?)?.toInt(),
          choice: p['choice'] == true,
          comment: _str(p['comment']),
          ts: '${e['ts'] ?? ''}',
        ),
      );
    }
  }
  if (proposed == null) return null;
  final chosen = answers.reversed.where((a) => a.choice).firstOrNull?.variant;
  return Board(
    proposalId: proposalId,
    title: '${proposed['title'] ?? ''}',
    description: _str(proposed['description']),
    variants: [
      for (final v in (proposed['variants'] as List? ?? const []).whereType<Map<String, dynamic>>())
        BoardVariant(
          title: '${v['title'] ?? ''}',
          note: _str(v['note']),
          bytes: (v['bytes'] as num?)?.toInt() ?? 0,
        ),
    ],
    at: at,
    answers: answers,
    chosen: chosen,
  );
}

final _boardLink = RegExp(r'^([\w-]+)\.([0-9a-f]{12})$');

/// A board's link from a chat (`https://…/#tavola=<session>.<proposal>`, the page's `takeFromLink`):
/// the conversation and the board, or null when the link is not one.
({String sessionId, String proposalId})? boardFromLink(String? href) {
  if (href == null) return null;
  final u = Uri.tryParse(href);
  if (u == null || (u.scheme != 'http' && u.scheme != 'https') || u.fragment.isEmpty) return null;
  Map<String, String> h;
  try {
    h = Uri.splitQueryString(u.fragment);
  } on FormatException {
    return null;
  }
  final m = _boardLink.firstMatch(h['tavola'] ?? '');
  if (m == null) return null;
  return (sessionId: m.group(1)!, proposalId: m.group(2)!);
}

/// The width of a board's column on a computer for each screen (the page's `COLUMN`).
const boardColumns = <String, double>{'computer': 460, 'tablet': 380, 'phone': 280};

/// A screen's width over its height (an `AspectRatio`): a variant's frame keeps the real screen's shape.
double boardAspect(String screen) {
  final s = boardScreens[screen] ?? boardScreens['computer']!;
  return s.width / s.height;
}
