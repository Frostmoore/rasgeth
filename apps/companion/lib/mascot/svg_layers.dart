// The server's mascot SVG (`@redgiant/mascot`'s `mascotSvg`, colours written in) cut, in drawing
// order, into the layers the page's CSS moves: every group whose class is in the motion table
// (eyes, mouth, hand, tool, the z's, the bubble…) becomes a layer of its own, and the still parts
// between them become still layers. Each layer is a whole SVG with the same root, the definitions
// and the groups it sits in, so stacking them gives back the drawing exactly. The body's two
// wrappers (`core`, `ev`) are not layers: the app moves the layers inside them.
import 'package:flutter/widgets.dart' show Matrix4, Offset;

class MascotLayer {
  const MascotLayer({
    required this.svg,
    required this.inCore,
    this.el,
    this.origin = Offset.zero,
    this.restOpacity = 1,
    this.parent,
  });

  /// A whole SVG with just this layer.
  final String svg;

  /// Inside the body (moved by `core` and `ev`), or around it (halo, the state's sign).
  final bool inCore;

  /// The moving group's class; null for still parts.
  final String? el;

  /// Where it turns and scales, in the 100x100 box (its `transform-origin`).
  final Offset origin;

  /// Its opacity in the drawing (0 for what appears only while moving).
  final double restOpacity;

  /// The transforms of the groups it sits in (a subagent's smaller body), in box units.
  final Matrix4? parent;
}

class MascotLayers {
  const MascotLayers({required this.layers, required this.rhythm, required this.coreOrigin});

  final List<MascotLayer> layers;

  /// The mascot's sixteen rhythm numbers (`--k0`…`--k15` on the root); empty from older servers.
  final List<double> rhythm;

  /// Where the body turns and scales (`core`'s and `ev`'s `transform-origin`).
  final Offset coreOrigin;
}

final _tag = RegExp(r'<[^>]+>');
final _class = RegExp(r'\sclass="([^"\s]+)');
final _origin = RegExp(r'transform-origin:\s*([\d.-]+)px\s+([\d.-]+)px');
final _opacity = RegExp(r'\sopacity="([\d.]+)"');
final _transform = RegExp(r'\stransform="([^"]*)"');
final _rhythm = RegExp(r'--k(\d+):([\d.]+)');

/// Something drawn (not just groups opening and closing).
final _drawn = RegExp(r'<(?!/?g[\s>/])[a-zA-Z]');

final _cache = <String, MascotLayers>{};

/// The layers of [svg], cut at the groups in [moving] (kept for the last 200 drawings).
MascotLayers splitMascotSvg(String svg, Set<String> moving) {
  final hit = _cache.remove(svg);
  if (hit != null) return _cache[svg] = hit;
  final out = _split(svg, moving);
  _cache[svg] = out;
  if (_cache.length > 200) _cache.remove(_cache.keys.first);
  return out;
}

Offset? _originOf(String tag) {
  final o = _origin.firstMatch(tag);
  return o == null ? null : Offset(double.parse(o.group(1)!), double.parse(o.group(2)!));
}

MascotLayers _split(String svg, Set<String> moving) {
  final rootMatch = RegExp(r'<svg\b[^>]*>').firstMatch(svg);
  final root = rootMatch?.group(0) ?? '<svg>';
  final close = svg.lastIndexOf('</svg>');
  final body = svg.substring(rootMatch?.end ?? 0, close < 0 ? svg.length : close);
  final defs = StringBuffer();
  final layers = <MascotLayer>[];
  // The groups open where we are: their opening tag, and whether it is `core`/`ev` (not drawn).
  final open = <({String tag, bool wrapper})>[];
  var inCore = 0;
  var coreOrigin = const Offset(50, 90);
  // The still part being collected, with the groups that were open when it began.
  final still = StringBuffer();
  var stillPrefix = '';
  var stillInCore = false;

  String prefix() => open.where((o) => !o.wrapper).map((o) => o.tag).join();
  int depth() => open.where((o) => !o.wrapper).length;
  String whole(String prefixTags, String inner, int closes) =>
      '$root<defs>$defs</defs>$prefixTags$inner${'</g>' * closes}</svg>';

  void flush() {
    if (_drawn.hasMatch(still.toString())) {
      layers.add(
        MascotLayer(svg: whole(stillPrefix, still.toString(), depth()), inCore: stillInCore),
      );
    }
    still.clear();
    stillPrefix = prefix();
    stillInCore = inCore > 0;
  }

  final tags = _tag.allMatches(body).toList();
  var i = 0;
  while (i < tags.length) {
    final t = tags[i].group(0)!;
    if (t.startsWith('<defs')) {
      // Definitions (clip paths, gradients) go into every layer.
      var j = i;
      while (j < tags.length && tags[j].group(0) != '</defs>') {
        j++;
      }
      defs.write(body.substring(tags[i].end, j < tags.length ? tags[j].start : body.length));
      i = j + 1;
      continue;
    }
    if (t == '</g>') {
      final o = open.isEmpty ? null : open.removeLast();
      if (o != null && o.wrapper) {
        flush();
        inCore--;
        stillInCore = inCore > 0;
      } else {
        still.write(t);
      }
      i++;
      continue;
    }
    final isGroup = t.startsWith('<g') && !t.endsWith('/>');
    final cls = _class.firstMatch(t)?.group(1);
    if (isGroup && (cls == 'core' || cls == 'ev')) {
      flush();
      if (cls == 'core') coreOrigin = _originOf(t) ?? coreOrigin;
      open.add((tag: t, wrapper: true));
      inCore++;
      stillInCore = true;
      i++;
      continue;
    }
    if (cls != null && moving.contains(cls)) {
      // A moving group: everything up to its own closing tag.
      var j = i;
      if (isGroup) {
        var d = 0;
        for (j = i; j < tags.length; j++) {
          final s = tags[j].group(0)!;
          if (s == '</g>') {
            d--;
            if (d == 0) break;
          } else if (s.startsWith('<g') && !s.endsWith('/>')) {
            d++;
          }
        }
      }
      final end = j < tags.length ? tags[j].end : body.length;
      flush();
      final op = _opacity.firstMatch(t);
      layers.add(
        MascotLayer(
          svg: whole(
            prefix(),
            t.replaceFirst(_opacity, '') + body.substring(tags[i].end, end),
            depth(),
          ),
          inCore: inCore > 0,
          el: cls,
          origin: _originOf(t) ?? const Offset(50, 50),
          restOpacity: op == null ? 1 : double.parse(op.group(1)!),
          parent: _parentOf(open),
        ),
      );
      i = j + 1;
      continue;
    }
    if (isGroup) open.add((tag: t, wrapper: false));
    still.write(t);
    i++;
  }
  flush();
  final k = <int, double>{
    for (final m in _rhythm.allMatches(root)) int.parse(m.group(1)!): double.parse(m.group(2)!),
  };
  final rhythm = k.isEmpty
      ? const <double>[]
      : List<double>.generate(k.keys.reduce((a, b) => a > b ? a : b) + 1, (n) => k[n] ?? 0);
  return MascotLayers(layers: layers, rhythm: rhythm, coreOrigin: coreOrigin);
}

/// The groups' transforms (`translate` and `scale`, the ones the library writes on groups).
Matrix4? _parentOf(List<({String tag, bool wrapper})> open) {
  Matrix4? m;
  for (final o in open) {
    if (o.wrapper) continue;
    final tr = _transform.firstMatch(o.tag)?.group(1);
    if (tr == null) continue;
    final g = Matrix4.identity();
    for (final f in RegExp(r'(\w+)\(([^)]*)\)').allMatches(tr)) {
      final v = f
          .group(2)!
          .split(RegExp(r'[\s,]+'))
          .where((s) => s.isNotEmpty)
          .map(double.parse)
          .toList();
      if (f.group(1) == 'translate') {
        g.translateByDouble(v[0], v.length > 1 ? v[1] : 0, 0, 1);
      } else if (f.group(1) == 'scale') {
        g.scaleByDouble(v[0], v.length > 1 ? v[1] : v[0], 1, 1);
      }
    }
    m = m == null ? g : (m..multiply(g));
  }
  return m;
}
