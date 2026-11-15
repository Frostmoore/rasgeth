// An agent's mascot (G40.2, study G40 section 3.6). The drawing is the server's own SVG, made by
// `@redgiant/mascot` (the same function the page uses), so faces, colours and proportions are
// identical by construction. Always alive: the app cuts the drawing into layers once
// (`splitMascotSvg`) and moves them with the library's motion table on one shared clock
// (`MascotClock`), each mascot with its own rhythm; nothing is redrawn, only transforms and
// opacity change. Until the SVG arrives (or without a server) it paints the spec's body outline.
// With «Reduce motion» (the system's or the app's) nothing moves: the state's sign stays.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';

import '../api/types.dart';
import 'clock.dart';
import 'mascot_source.dart';
import 'motion.dart';
import 'rhythm.dart';
import 'svg_layers.dart';

Color hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h.length == 3 ? h.split('').map((c) => '$c$c').join() : h, radix: 16);
  return Color(0xFF000000 | (v ?? 0x888888));
}

/// The rhythm in the drawing; from an older server (none in it), the app's own from the seed (or
/// the agent's id), so the mascots never all move with the same zero.
List<double> rhythmFor(MascotLayers layers, {String? seed, String? agentId}) {
  if (layers.rhythm.isNotEmpty) return layers.rhythm;
  return rhythmOf(seed != null && seed.isNotEmpty ? seed : agentId ?? '');
}

class MascotView extends StatefulWidget {
  const MascotView({
    super.key,
    this.agentId,
    this.spec,
    this.state = MascotState.idle,
    this.size = 64,
    this.label,
    this.svg,
    this.theme,
    this.animate,
    this.seconds,
  });

  /// Whose drawing to ask the [MascotScope]'s source for.
  final String? agentId;
  final MascotSpec? spec;
  final MascotState state;
  final double size;

  /// The accessible name («Mascot of Chat, thinking»); without one it is decorative.
  final String? label;

  /// A drawing already at hand (tests, previews): the source is not asked.
  final String? svg;

  /// Default: the app's brightness.
  final MascotTheme? theme;

  /// Default: on, unless the system or the app reduces motion.
  final bool? animate;

  /// A fixed moment of the motion (tests, film strips) instead of the shared clock.
  final double? seconds;

  /// 16-20 px: body and eyes only, no sign; only the eyes blink (as the library draws it).
  bool get tiny => size <= 20;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> {
  /// A small shift of its own when it appears (seconds, as the page's `--j`): two mascots drawn
  /// at the same moment, even twins, never move together.
  final double _shift = math.Random().nextDouble() * 2.5;
  List<double>? _ownRhythm;
  Future<String>? _future;
  String? _futureKey;
  bool _listening = false;

  MascotTheme get _theme =>
      widget.theme ??
      (Theme.of(context).brightness == Brightness.dark ? MascotTheme.dark : MascotTheme.light);

  bool get _moving {
    if (widget.seconds != null) return true;
    final reduced =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (MascotScope.maybeOf(context)?.reduceMotion ?? false);
    return widget.animate ?? !reduced;
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _syncClock() {
    final want = _moving && widget.seconds == null && TickerMode.valuesOf(context).enabled;
    if (want && !_listening) MascotClock.instance.attach(_tick);
    if (!want && _listening) MascotClock.instance.detach(_tick);
    _listening = want;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncClock();
  }

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    _syncClock();
  }

  @override
  void dispose() {
    if (_listening) MascotClock.instance.detach(_tick);
    super.dispose();
  }

  Future<String>? _load() {
    if (widget.svg != null) return null;
    final source = MascotScope.maybeOf(context)?.source;
    final id = widget.agentId;
    if (source == null || id == null) return null;
    final key = '$id|${widget.state.name}|${_theme.name}|${widget.tiny}';
    if (key != _futureKey) {
      _futureKey = key;
      _future = source.svg(id, widget.state, _theme, tiny: widget.tiny);
    }
    return _future;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final svg = widget.svg;
    final future = _load();
    final Widget art = svg != null
        ? _drawing(svg)
        : future == null
        ? _placeholder()
        : FutureBuilder<String>(
            future: future,
            builder: (context, snap) => snap.hasData ? _drawing(snap.data!) : _placeholder(),
          );
    final box = SizedBox(width: s, height: s, child: art);
    final label = widget.label;
    return label == null
        ? ExcludeSemantics(child: box)
        : Semantics(label: label, image: true, excludeSemantics: true, child: box);
  }

  List<double> _rhythmOf(MascotLayers layers, String svg) => layers.rhythm.isNotEmpty
      ? layers.rhythm
      : _ownRhythm ??= rhythmFor(layers, seed: widget.spec?.seed, agentId: widget.agentId);

  Widget _placeholder() => CustomPaint(
    size: Size.square(widget.size),
    painter: SpecPainter(spec: widget.spec, theme: _theme, state: widget.state),
  );

  Widget _drawing(String svg) {
    final s = widget.size;
    final table = MotionTable.instance;
    // Layers even when still: flutter_svg would show a hidden group (`opacity="0"`) whose shapes
    // have their own `fill-opacity` (the sleep bubble); the layers leave hidden groups out.
    final layers = splitMascotSvg(svg, table.elements);
    if (!_moving) return MascotLayersView(layers: layers, size: s);
    final t = widget.seconds ?? MascotClock.instance.seconds + _shift;
    final poses = table.poses(widget.state, t, _rhythmOf(layers, svg), tiny: widget.tiny);
    return MascotLayersView(layers: layers, poses: poses, size: s);
  }
}

/// The layers of one drawing in one pose ([poses] by group; none: the drawing at rest).
class MascotLayersView extends StatelessWidget {
  const MascotLayersView({
    super.key,
    required this.layers,
    required this.size,
    this.poses = const {},
  });

  final MascotLayers layers;
  final double size;
  final Map<String, MotionPose> poses;

  @override
  Widget build(BuildContext context) {
    final k = size / 100;
    final inner = <Widget>[];
    final children = <Widget>[];
    var coreAt = -1;
    for (final l in layers.layers) {
      final w = _layer(l, k);
      if (w == null) continue;
      if (l.inCore) {
        if (coreAt < 0) coreAt = children.length;
        inner.add(w);
      } else {
        children.add(w);
      }
    }
    if (coreAt >= 0) {
      Widget core = Stack(alignment: Alignment.topLeft, clipBehavior: Clip.none, children: inner);
      final o = layers.coreOrigin;
      for (final el in const ['ev', 'core']) {
        final p = poses[el];
        if (p != null && !p.movesNothing) core = _moved(core, p, o, null, k);
      }
      children.insert(coreAt, core);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.topLeft, clipBehavior: Clip.none, children: children),
    );
  }

  Widget? _layer(MascotLayer l, double k) {
    final p = l.el == null ? null : poses[l.el];
    final opacity = p?.opacity ?? l.restOpacity;
    if (opacity <= 0.004) return null;
    Widget w = SvgPicture.string(
      l.svg,
      width: size,
      height: size,
      allowDrawingOutsideViewBox: true,
    );
    if (p != null && !p.movesNothing) w = _moved(w, p, l.origin, l.parent, k);
    if (opacity < 0.996) w = Opacity(opacity: opacity.clamp(0.0, 1.0), child: w);
    return w;
  }

  /// The page's `translate rotate scale` around [origin], inside the groups' [parent] transform.
  static Widget _moved(Widget child, MotionPose p, Offset origin, Matrix4? parent, double k) {
    final a = Matrix4.identity()
      ..translateByDouble(origin.dx + p.dx, origin.dy + p.dy, 0, 1)
      ..rotateZ(p.rotate * math.pi / 180)
      ..scaleByDouble(p.sx, p.sy, 1, 1)
      ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
    var m = a;
    if (parent != null)
      m = parent.clone()
        ..multiply(a)
        ..multiply(Matrix4.inverted(parent));
    final screen = Matrix4.diagonal3Values(k, k, 1)
      ..multiply(m)
      ..multiply(Matrix4.diagonal3Values(1 / k, 1 / k, 1));
    return Transform(transform: screen, child: child);
  }
}

/// The spec's own drawing: the body outline in its colours (the shape and hue of the face), shown
/// while the full drawing loads or when there is none.
class SpecPainter extends CustomPainter {
  SpecPainter({required this.spec, required this.theme, required this.state});

  final MascotSpec? spec;
  final MascotTheme theme;
  final MascotState state;

  @override
  void paint(Canvas canvas, Size size) {
    final s = spec;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    if (s == null || s.bodyPath.isEmpty) {
      canvas.drawCircle(
        const Offset(50, 60),
        28,
        Paint()..color = const Color(0xFF8F96A3).withValues(alpha: .35),
      );
      canvas.restore();
      return;
    }
    final c = s.colorsFor(theme);
    if (s.kind == AgentKind.subagent) {
      canvas.translate(10, 18);
      canvas.scale(.8);
    }
    final path = parseSvgPathData(s.bodyPath);
    canvas.drawPath(
      path,
      Paint()..color = hexColor(state == MascotState.error ? c.blocked : c.body),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = hexColor(c.line)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = ui.StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SpecPainter old) =>
      old.spec != spec || old.theme != theme || old.state != state;
}
