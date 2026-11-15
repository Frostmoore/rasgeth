// The server's mascot SVG (`@redgiant/mascot`'s `mascotSvg`, colours written in) cut into the
// layers the page's CSS animates, so the app moves the same parts without redrawing them:
//   base     everything but the state's sign, the tool and the headset;
//   tool     the hand and its tool (`g.tool`), rotated while working;
//   headset  the orchestrator's headset (`g.hs`), pulsing while working.
// The state's sign (`g.mk`) is painted by the app (`MarksPainter`), with the same shapes.
import 'dart:ui' show Offset;

class MascotLayers {
  const MascotLayers({required this.base, this.tool, this.toolOrigin, this.headset});

  final String base;
  final String? tool;

  /// Where the tool turns, in the 100x100 box (the page's `transform-origin`).
  final Offset? toolOrigin;
  final String? headset;
}

final _gOpen = RegExp(r'<g\b([^>]*?)(/?)>');
final _gAny = RegExp(r'<g\b[^>]*?/?>|</g>');

/// The `<g>` element of [cls] (its first class), with its start and end.
({int start, int end, String attrs})? _group(String svg, String cls) {
  final m = RegExp('<g class="$cls(?:\\s[^"]*)?"[^>]*>').firstMatch(svg);
  if (m == null) return null;
  var depth = 0;
  for (final t in _gAny.allMatches(svg, m.start)) {
    final s = t.group(0)!;
    if (s == '</g>') {
      depth--;
      if (depth == 0) return (start: m.start, end: t.end, attrs: m.group(0)!);
    } else if (!s.endsWith('/>')) {
      depth++;
    }
  }
  return null;
}

/// The `transform`s of the groups still open at [index] (outermost first).
List<String> _transformsAt(String svg, int index) {
  final open = <String?>[];
  for (final t in _gAny.allMatches(svg.substring(0, index))) {
    final s = t.group(0)!;
    if (s == '</g>') {
      if (open.isNotEmpty) open.removeLast();
    } else if (!s.endsWith('/>')) {
      final attrs = _gOpen.firstMatch(s)?.group(1) ?? '';
      open.add(RegExp(r'\stransform="([^"]*)"').firstMatch(attrs)?.group(1));
    }
  }
  return [for (final t in open) ?t];
}

String _root(String svg) => RegExp(r'<svg\b[^>]*>').firstMatch(svg)?.group(0) ?? '<svg>';

/// [inner] as an SVG of its own, inside the same transforms as where it was cut.
String _alone(String svg, String inner, List<String> transforms) {
  final open = transforms.map((t) => '<g transform="$t">').join();
  final close = '</g>' * transforms.length;
  return '${_root(svg)}$open$inner$close</svg>';
}

/// Removes the state's sign; with [split] also cuts the tool and the headset out.
MascotLayers splitMascotSvg(String svg, {bool split = true}) {
  var base = svg;
  final marks = _group(base, 'mk');
  if (marks != null) base = base.replaceRange(marks.start, marks.end, '');
  if (!split) return MascotLayers(base: base);

  String? tool;
  Offset? origin;
  final t = _group(base, 'tool');
  if (t != null) {
    tool = _alone(base, base.substring(t.start, t.end), _transformsAt(base, t.start));
    final o = RegExp(r'transform-origin:\s*([\d.-]+)px\s+([\d.-]+)px').firstMatch(t.attrs);
    if (o != null) origin = Offset(double.parse(o.group(1)!), double.parse(o.group(2)!));
    base = base.replaceRange(t.start, t.end, '');
  }
  String? headset;
  final h = _group(base, 'hs');
  if (h != null) {
    headset = _alone(base, base.substring(h.start, h.end), _transformsAt(base, h.start));
    base = base.replaceRange(h.start, h.end, '');
  }
  return MascotLayers(base: base, tool: tool, toolOrigin: origin, headset: headset);
}
