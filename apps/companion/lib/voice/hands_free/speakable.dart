// Hands-free voice (G42.16): what an answer sounds like, as the page's
// packages/web/src/voice/speakable.ts (checked with its vectors). A message said by voice carries a
// note for the model at its end; the voice reads the answer's spoken version when there is one,
// otherwise the answer without its Markdown, code and tables, cut to a few sentences.

const _hintOpen = '<voice-mode>';
const _hintClose = '</voice-mode>';

/// The note for the model, in English as every instruction the product gives a model.
const voiceHint =
    'The person is talking to you by voice, hands-free, and your answer will be read aloud. '
    'Answer in plain spoken sentences: no tables, no Markdown, no lists unless needed. '
    'If the full answer needs code, a list or many details, write first a short spoken version '
    '(at most three sentences) inside <spoken></spoken>, then the full answer for the screen.';

/// The person's words with the note for the model at the end.
String withVoiceHint(String text) => '$text\n\n$_hintOpen$voiceHint$_hintClose';

/// The answer's spoken version, if the agent wrote one.
String? spokenPart(String markdown) {
  final m = RegExp(r'<spoken>([\s\S]*?)</spoken>', caseSensitive: false).firstMatch(markdown);
  final said = m?.group(1)?.trim();
  return said == null || said.isEmpty ? null : said;
}

final _rules = <(RegExp, String Function(Match))>[
  (RegExp(r'<spoken>[\s\S]*?</spoken>', caseSensitive: false), (_) => ' '),
  (RegExp(r'```[\s\S]*?(```|$)'), (_) => '\n'),
  (RegExp(r'~~~[\s\S]*?(~~~|$)'), (_) => '\n'),
  (RegExp(r'^\s*\|.*\|\s*$', multiLine: true), (_) => ''),
  (RegExp(r'<[^>]+>'), (_) => ' '),
  (RegExp(r'!\[[^\]]*\]\([^)]*\)'), (_) => ''),
  (RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!),
  (RegExp(r'https?://\S+'), (_) => ''),
  (RegExp(r'`([^`]+)`'), (m) => m[1]!),
  (RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), (_) => ''),
  (RegExp(r'^\s{0,3}>\s?', multiLine: true), (_) => ''),
  (RegExp(r'^\s*(?:[-*+]|\d+[.)])\s+', multiLine: true), (_) => ''),
  (RegExp(r'^\s*(?:-{3,}|\*{3,}|_{3,})\s*$', multiLine: true), (_) => ''),
  (RegExp(r'(\*\*|__|\*|_|~~)(?=\S)([\s\S]*?\S)\1'), (m) => m[2]!),
];
final _endMark = RegExp(r'[.!?:;…]$');

/// Markdown as it sounds: no code, tables, marks, addresses or HTML.
String plainSpeech(String markdown) {
  var t = markdown;
  for (final (re, to) in _rules) {
    t = t.replaceAllMapped(re, to);
  }
  return t
      .split(RegExp(r'\n+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => _endMark.hasMatch(l) ? l : '$l.')
      .join(' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Sentences, kept whole.
List<String> sentences(String text) => [
  for (final m in RegExp(r'[^.!?…]+(?:[.!?…]+|$)').allMatches(text))
    if (m[0]!.trim().isNotEmpty) m[0]!.trim(),
];

/// What the voice says for an answer: its spoken version, or the answer made plain; a long one is
/// cut after the sentences that fit in [maxChars], with [more] («the rest is on screen») after.
String speakable(String markdown, String more, {int maxChars = 450}) {
  final said = spokenPart(markdown);
  if (said != null) return plainSpeech(said);
  final plain = plainSpeech(markdown);
  if (plain.length <= maxChars) return plain;
  var out = '';
  for (final s in sentences(plain)) {
    if (out.isNotEmpty && out.length + s.length + 1 > maxChars) break;
    out = out.isNotEmpty ? '$out $s' : s;
  }
  // One sentence longer than all the room: cut at a word.
  if (out.length > maxChars) {
    out = '${out.substring(0, maxChars).replaceFirst(RegExp(r'\s+\S*$'), '')}…';
  }
  return '$out $more'.trim();
}

/// Pieces short enough for one reading.
List<String> chunksForVoice(String text, {int max = 220}) {
  final out = <String>[];
  for (final s in sentences(text)) {
    final last = out.isEmpty ? null : out.last;
    if (last != null && last.length + s.length + 1 <= max) {
      out[out.length - 1] = '$last $s';
    } else if (s.length <= max) {
      out.add(s);
    } else {
      for (var i = 0; i < s.length; i += max) {
        out.add(s.substring(i, i + max > s.length ? s.length : i + max));
      }
    }
  }
  return out;
}
