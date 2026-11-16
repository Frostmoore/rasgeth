// Saved passages (G40.14) as the app reads them: the shapes of `packages/protocol/src/saved.ts`
// (`SavedItem`, `SavedList`), the tags kept the same way as the server (`normalizeTags`) and the
// page's `findPassage` for lighting a passage up again. Read leniently.

Map<String, dynamic> _map(Object? o) => o is Map<String, dynamic> ? o : const {};
String? _str(Object? o) => o is String ? o : null;
int? _int(Object? o) => o is num ? o.toInt() : null;
List<dynamic> _list(Object? o) => o is List ? o : const [];

const savedNoteMax = 4000;
const savedTagMax = 40;
const savedTagsMax = 12;
const savedTextMax = 20000;
const savedMarkdownMax = 40000;

/// Tags as they are kept: trimmed, a leading `#` dropped, the same tag once (whatever its case,
/// the first spelling wins), empty ones out, at most [savedTagsMax] (protocol's `normalizeTags`).
List<String> normalizeTags(Iterable<String> tags) {
  final out = <String>[];
  final seen = <String>{};
  for (final raw in tags) {
    var tag = raw.trim().replaceFirst(RegExp(r'^#+'), '').trim();
    if (tag.length > savedTagMax) tag = tag.substring(0, savedTagMax);
    final key = tag.toLowerCase();
    if (tag.isEmpty || seen.contains(key)) continue;
    seen.add(key);
    out.add(tag);
    if (out.length >= savedTagsMax) break;
  }
  return out;
}

/// Tags typed with commas: the chosen ones plus the new ones, each once.
List<String> withTyped(List<String> chosen, String typed) =>
    normalizeTags([...chosen, ...typed.split(',')]);

/// Where a saved passage comes from, as the server found it.
class SavedSource {
  const SavedSource({
    required this.kind,
    this.sessionId,
    this.seq,
    this.start,
    this.end,
    this.chatId,
    this.messageId,
    this.agentId,
    this.agentName,
    this.title,
    this.messageAt,
  });

  factory SavedSource.fromJson(Map<String, dynamic> j) => SavedSource(
    kind: _str(j['kind']) ?? 'session',
    sessionId: _str(j['sessionId']),
    seq: _int(j['seq']),
    start: _int(j['start']),
    end: _int(j['end']),
    chatId: _str(j['chatId']),
    messageId: _int(j['messageId']),
    agentId: _str(j['agentId']),
    agentName: _str(j['agentName']),
    title: _str(j['title']),
    messageAt: _str(j['messageAt']),
  );

  /// `session` (an agent's conversation) or `chat` (the older daily chat).
  final String kind;
  final String? sessionId;
  final int? seq;
  final int? start;
  final int? end;
  final String? chatId;
  final int? messageId;
  final String? agentId;
  final String? agentName;
  final String? title;
  final String? messageAt;

  bool get isSession => kind == 'session' && sessionId != null && seq != null;
}

class SavedItem {
  const SavedItem({
    required this.id,
    required this.text,
    required this.markdown,
    required this.whole,
    required this.note,
    required this.tags,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedItem.fromJson(Map<String, dynamic> j) => SavedItem(
    id: _str(j['id']) ?? '',
    text: _str(j['text']) ?? '',
    markdown: _str(j['markdown']),
    whole: j['whole'] == true,
    note: _str(j['note']) ?? '',
    tags: _list(j['tags']).whereType<String>().toList(),
    source: SavedSource.fromJson(_map(j['source'])),
    createdAt: _str(j['createdAt']) ?? '',
    updatedAt: _str(j['updatedAt']) ?? '',
  );

  final String id;
  final String text;

  /// The passage's Markdown, when known (always for a whole message).
  final String? markdown;
  final bool whole;
  final String note;
  final List<String> tags;
  final SavedSource source;
  final String createdAt;
  final String updatedAt;
}

/// `GET /api/saved`: a page, and every tag and agent of the person's items (for the filters).
class SavedList {
  const SavedList({
    required this.items,
    required this.more,
    required this.tags,
    required this.agents,
  });

  factory SavedList.fromJson(Map<String, dynamic> j) => SavedList(
    items: [
      for (final i in _list(j['items']).whereType<Map<String, dynamic>>()) SavedItem.fromJson(i),
    ],
    more: j['more'] == true,
    tags: [
      for (final t in _list(j['tags']).whereType<Map<String, dynamic>>())
        (tag: _str(t['tag']) ?? '', count: _int(t['count']) ?? 0),
    ],
    agents: [
      for (final a in _list(j['agents']).whereType<Map<String, dynamic>>())
        (id: _str(a['id']) ?? '', name: _str(a['name']) ?? '', count: _int(a['count']) ?? 0),
    ],
  );

  final List<SavedItem> items;
  final bool more;
  final List<({String tag, int count})> tags;
  final List<({String id, String name, int count})> agents;
}

String _squash(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Where a passage is in a text now (the page's `findPassage`): by its place first, else by its
/// words, else by its first line.
({int from, int to})? findPassage(String all, String text, {int? start, int? end}) {
  if (start != null && end != null && start <= end && end <= all.length) {
    if (_squash(all.substring(start, end)) == _squash(text)) return (from: start, to: end);
  }
  final exact = text.isEmpty ? -1 : all.indexOf(text);
  if (exact >= 0) return (from: exact, to: exact + text.length);
  final line = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).firstOrNull ?? '';
  final loose = line.isEmpty ? -1 : all.indexOf(line);
  return loose >= 0 ? (from: loose, to: loose + line.length) : null;
}

// Between two words of a passage, in the Markdown it was read from: spaces, emphasis, code
// marks, brackets, a link's target, a list's or a heading's mark.
const _gap = r'(?:[\s*_`~#>|\[\]]|\]\([^)]*\)|^\s*(?:[-+]|\d+[.)])\s)+';
const _markup = '*_`~[]|#>';

/// Where a passage read on screen is in the Markdown source of its message: exactly, then word by
/// word with the Markdown's marks allowed in between, then by its first line ([findPassage]).
({int from, int to})? findInMarkdown(String source, String text, {int? start, int? end}) {
  final plain = findPassage(source, text, start: start, end: end);
  if (plain != null && plain.to - plain.from >= _squash(text).length) return plain;
  final words = text
      .split(RegExp(r'\s+'))
      .map((w) => w.replaceAll(RegExp(r'^[•·\-*]+$'), ''))
      .where((w) => w.isNotEmpty)
      .take(80)
      .toList();
  if (words.isNotEmpty) {
    final re = RegExp(words.map(RegExp.escape).join(_gap), multiLine: true);
    final m = re.firstMatch(source);
    if (m != null) return (from: m.start, to: m.end);
  }
  return plain;
}

/// The parts of `source[from, to)` that are words on screen (no Markdown marks, no line breaks,
/// no link targets): each can be wrapped in a mark of its own without breaking the Markdown.
List<({int from, int to})> plainRuns(String source, int from, int to) {
  final skip = List<bool>.filled(source.length, false);
  for (final m in RegExp(r'\]\([^)]*\)').allMatches(source)) {
    for (var i = m.start; i < m.end; i++) {
      skip[i] = true;
    }
  }
  // Code is shown as it is: a mark inside it would show too.
  for (final m in RegExp(r'```[\s\S]*?(?:```|$)|`[^`\n]*`').allMatches(source)) {
    for (var i = m.start; i < m.end; i++) {
      skip[i] = true;
    }
  }
  for (final m in RegExp(r'^\s*(?:[-+]|\d+[.)])\s', multiLine: true).allMatches(source)) {
    for (var i = m.start; i < m.end; i++) {
      skip[i] = true;
    }
  }
  final runs = <({int from, int to})>[];
  int? open;
  for (var i = from; i <= to; i++) {
    final plain = i < to && !skip[i] && source[i] != '\n' && !_markup.contains(source[i]);
    if (plain) {
      open ??= i;
    } else if (open != null) {
      if (source.substring(open, i).trim().isNotEmpty) runs.add((from: open, to: i));
      open = null;
    }
  }
  return runs;
}

/// The marks around a lit passage, private characters no message has.
const markOpen = '';
const markClose = '';

/// The Markdown with the passage's words between [markOpen] and [markClose] (null: not found).
String? markPassage(String source, String text, {int? start, int? end}) {
  final at = findInMarkdown(source, text, start: start, end: end);
  if (at == null) return null;
  final runs = plainRuns(source, at.from, at.to);
  if (runs.isEmpty) return null;
  final out = StringBuffer();
  var last = 0;
  for (final r in runs) {
    out
      ..write(source.substring(last, r.from))
      ..write(markOpen)
      ..write(source.substring(r.from, r.to))
      ..write(markClose);
    last = r.to;
  }
  out.write(source.substring(last));
  return out.toString();
}
