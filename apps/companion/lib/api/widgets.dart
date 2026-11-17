// Widgets in answers (the page's 3.5.9, `packages/protocol/src/widget.ts` and `splitWidgets` /
// `streamingWithoutWidgets` in `packages/web/src/state.ts`), in Dart: a widget is a ```widget
// block of an agent's answer, run in the same isolated frame as an artifact. The app splits an
// answer exactly as the page and the server do, so a widget's index is the server's.
import 'dart:convert';

/// The sandbox of an artifact or a widget (`ARTIFACT_SANDBOX`): scripts and forms only, in an
/// opaque origin; no popups, modals, downloads or navigation of the page around it.
const String kArtifactSandbox = 'allow-scripts allow-forms';

/// The most a widget block may carry (`WIDGET_MAX_BYTES`); a bigger one stays text.
const int kWidgetMaxBytes = 64 * 1024;

/// The most a frame's «send to chat» may carry (`ARTIFACT_MESSAGE_MAX`).
const int kArtifactMessageMax = 4000;

/// How long after a click in the frame its message is taken as the person's (`ARTIFACT_CLICK_MS`).
const int kArtifactClickMs = 1500;

/// The most errors kept for one artifact or widget (`ARTIFACT_ERRORS_MAX`).
const int kArtifactErrorsMax = 20;

/// A piece of an answer: its text, or a widget block (`AnswerSegment`).
sealed class AnswerSegment {
  const AnswerSegment();
}

class TextSegment extends AnswerSegment {
  const TextSegment(this.text);

  final String text;

  @override
  bool operator ==(Object other) => other is TextSegment && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextSegment(${jsonEncode(text)})';
}

class WidgetSegment extends AnswerSegment {
  const WidgetSegment({
    required this.index,
    required this.title,
    required this.html,
    required this.closed,
    required this.tooBig,
  });

  /// Its place among the answer's widget blocks, from 0.
  final int index;

  /// What follows `widget` on the fence line, if anything.
  final String title;
  final String html;

  /// The fence was closed (while streaming the last block may still be open).
  final bool closed;

  /// Over [kWidgetMaxBytes]: shown as text, never run.
  final bool tooBig;

  @override
  bool operator ==(Object other) =>
      other is WidgetSegment &&
      other.index == index &&
      other.title == title &&
      other.html == html &&
      other.closed == closed &&
      other.tooBig == tooBig;

  @override
  int get hashCode => Object.hash(index, title, html, closed, tooBig);

  @override
  String toString() =>
      'WidgetSegment($index, ${jsonEncode(title)}, ${jsonEncode(html)}, closed: $closed, '
      'tooBig: $tooBig)';
}

// The same expressions as the page's (JavaScript and Dart share their syntax and meaning here).
final RegExp _open = RegExp(r'^(\s{0,3})(`{3,}|~{3,})\s*widget\b[ \t]*(.*)$', caseSensitive: false);
final RegExp _anyFence = RegExp(
  r'^\s{0,3}(`{3,}|~{3,})\s*widget\b',
  caseSensitive: false,
  multiLine: true,
);
final RegExp _streamFence = RegExp(r'(`{3,}|~{3,})\s*widget\b', caseSensitive: false);
final RegExp _edgeNewlines = RegExp(r'^\n+|\n+$');

/// An answer's text split around its ```widget blocks (`answerSegments`, pure). Text outside them
/// is left as it is; a block still open at the end (streaming) comes back with `closed: false`.
List<AnswerSegment> answerSegments(String text, [int first = 0]) {
  final out = <AnswerSegment>[];
  final lines = text.split('\n');
  var buf = <String>[];
  var index = first;
  void flush() {
    if (buf.isNotEmpty && buf.join('\n').trim().isNotEmpty) out.add(TextSegment(buf.join('\n')));
    buf = [];
  }

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final m = _open.firstMatch(line);
    if (m == null) {
      buf.add(line);
      continue;
    }
    final fence = m.group(2)!;
    final close = RegExp('^\\s{0,3}${fence[0] == '`' ? '`' : '~'}{${fence.length},}\\s*\$');
    final body = <String>[];
    var j = i + 1;
    var closed = false;
    for (; j < lines.length; j++) {
      if (close.hasMatch(lines[j])) {
        closed = true;
        break;
      }
      body.add(lines[j]);
    }
    flush();
    final html = body.join('\n');
    final tooBig = utf8.encode(html).length > kWidgetMaxBytes;
    out.add(
      WidgetSegment(
        index: index,
        title: (m.group(3) ?? '').trim(),
        html: html,
        closed: closed,
        tooBig: tooBig,
      ),
    );
    index++;
    i = j;
  }
  flush();
  return out;
}

/// A widget of an answer, as the chat shows it after the answer (the page's `splitWidgets`); its
/// html only for the computers that cannot run it (a preview of its words).
typedef AnswerWidget = ({int index, String title, String html});

/// An answer's text parts without their closed ```widget blocks, and the widgets (the page's
/// `splitWidgets`, pure). A block still open (a cut answer) or over 64 KB stays text, as code: it
/// is never run. Widgets are numbered across the parts, as the server numbers them.
({List<String> texts, List<AnswerWidget> widgets}) splitWidgets(List<String> texts) {
  final widgets = <AnswerWidget>[];
  var n = 0;
  final out = <String>[];
  for (final p in texts) {
    if (!_anyFence.hasMatch(p)) {
      out.add(p);
      continue;
    }
    final segs = answerSegments(p, n);
    n += segs.whereType<WidgetSegment>().length;
    out.add(
      segs
          .map((x) {
            switch (x) {
              case TextSegment(:final text):
                return text;
              case WidgetSegment(
                :final closed,
                :final tooBig,
                :final html,
                :final index,
                :final title,
              ):
                if (closed && !tooBig) {
                  widgets.add((index: index, title: title, html: html));
                  return '';
                }
                return closed ? '```html\n$html\n```' : '```html\n$html';
            }
          })
          .map((x) => x.replaceAll(_edgeNewlines, ''))
          .where((x) => x.trim().isNotEmpty)
          .join('\n\n'),
    );
  }
  return (texts: out, widgets: widgets);
}

/// An answer being written: a widget block shows as a short line ([preparing], in italics) until
/// it is closed and the answer is recorded, never as its code (`streamingWithoutWidgets`).
String streamingWithoutWidgets(String text, String preparing) {
  if (!_streamFence.hasMatch(text)) return text;
  return answerSegments(text)
      .map((x) => x is TextSegment ? x.text : '\n_${preparing}_\n')
      .join('\n\n');
}

/// The visible words of a widget's HTML, short: what the computers without a web view show of it
/// (Linux). Tags, scripts and styles out; nothing of it runs.
String widgetPreviewText(String html, {int max = 220}) {
  final noCode = html.replaceAll(
    RegExp(r'<(script|style|template)\b[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false),
    ' ',
  );
  final words = noCode
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return words.length > max ? '${words.substring(0, max).trimRight()}…' : words;
}
