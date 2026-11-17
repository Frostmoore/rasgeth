// Sources as links (G42.1), the page's `linkCitations` (packages/web/src/markdown.ts) on the
// Markdown itself: when an answer ends with a numbered list whose every item links a web page
// (web_search's sources), each run of `[n]` in the text becomes one link named after the first
// source's site («example.com», «example.com +1» for more), pointing at it. Code (spans and
// blocks) and the list itself are left alone. A citation of the person's own documents (`#kb:`)
// stays as it is here: the knowledge's viewer comes with G42.10.
final _item = RegExp(r'^(\s{0,3})(\d+)[.)]\s+(.*)$');
final _link = RegExp(r'\[([^\]]*)\]\((https?://[^\s)]+)(?:\s+"[^"]*")?\)');

/// A source: its address, the site shown, and its title.
typedef CiteSource = ({String href, String site, String title});

/// The sources of [markdown] (its last list of links), by number.
Map<int, CiteSource> citationSources(String markdown) {
  final lines = markdown.split('\n');
  // The last ordered list: consecutive item lines (blank lines between items allowed).
  var end = lines.length - 1;
  while (end >= 0 && lines[end].trim().isEmpty) {
    end--;
  }
  final items = <int>[];
  for (var i = end; i >= 0; i--) {
    final l = lines[i];
    if (_item.hasMatch(l)) {
      items.insert(0, i);
    } else if (l.trim().isEmpty || (items.isNotEmpty && l.startsWith('   '))) {
      continue;
    } else {
      break;
    }
  }
  if (items.isEmpty) return const {};
  final out = <int, CiteSource>{};
  final first = int.parse(_item.firstMatch(lines[items.first])!.group(2)!);
  for (final (i, at) in items.indexed) {
    final text = _item.firstMatch(lines[at])!.group(3)!;
    final m = _link.firstMatch(text);
    if (m == null) return const {};
    final href = m.group(2)!;
    final host = Uri.tryParse(href)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
    if (host.isEmpty) continue;
    final plain = text.replaceAllMapped(_link, (x) => x.group(1)!);
    final title = plain.split(RegExp(r':\s')).first.trim();
    out[first + i] = (href: href, site: host, title: title.isEmpty ? host : title);
  }
  return out;
}

/// [markdown] with its citations as links, or as it is when it has no sources list.
String linkCitations(String markdown) {
  if (!RegExp(r'\[\d+\]').hasMatch(markdown)) return markdown;
  final sources = citationSources(markdown);
  if (sources.isEmpty) return markdown;
  final lines = markdown.split('\n');
  // Where the sources list starts: nothing from there on changes.
  var listAt = lines.length;
  for (var i = lines.length - 1; i >= 0; i--) {
    if (_item.hasMatch(lines[i])) {
      listAt = i;
    } else if (lines[i].trim().isNotEmpty && !lines[i].startsWith('   ')) {
      break;
    }
  }
  var fence = false;
  final out = <String>[];
  for (final (i, line) in lines.indexed) {
    if (RegExp(r'^\s{0,3}(```|~~~)').hasMatch(line)) fence = !fence;
    if (fence || i >= listAt) {
      out.add(line);
      continue;
    }
    // Inline code stays: only the parts between backticks are touched.
    final parts = line.split('`');
    for (var p = 0; p < parts.length; p += 2) {
      parts[p] = parts[p].replaceAllMapped(RegExp(r'(?:\[\d+\](?!\()\s*)+'), (m) {
        final found = [
          for (final x in RegExp(r'\[(\d+)\]').allMatches(m[0]!)) ?sources[int.parse(x.group(1)!)],
        ];
        if (found.isEmpty) return m[0]!;
        final head = found.first;
        final name = found.length > 1 ? '${head.site} +${found.length - 1}' : head.site;
        final space = RegExp(r'\s$').hasMatch(m[0]!) ? ' ' : '';
        return '[$name](${head.href} "${found.map((s) => s.title.replaceAll('"', "'")).join(' / ')}")$space';
      });
    }
    out.add(parts.join('`'));
  }
  return out.join('\n');
}
