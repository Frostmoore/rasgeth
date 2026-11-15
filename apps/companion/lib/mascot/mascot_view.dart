// An agent's mascot (G40.2, study G40 section 3.6). The drawing is the server's own SVG, made by
// `@redgiant/mascot` (the same function the page uses), so faces, colours and proportions are
// identical by construction; the app cuts it into layers and moves them like the page's CSS.
// Until the SVG arrives (or without a server) it paints the spec's body outline in its colours.
// With «Reduce motion» (the system's or the app's) nothing moves: the state's sign stays.
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path_drawing/path_drawing.dart';

import '../api/types.dart';
import 'marks_painter.dart';
import 'mascot_source.dart';
import 'motion.dart';
import 'svg_layers.dart';

Color hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h.length == 3 ? h.split('').map((c) => '$c$c').join() : h, radix: 16);
  return Color(0xFF000000 | (v ?? 0x888888));
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

  /// 16-20 px: body and eyes only, no sign, no motion (as the library draws it).
  bool get tiny => size <= 20;

  @override
  State<MascotView> createState() => _MascotViewState();
}

class _MascotViewState extends State<MascotView> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(
    (d) => setState(() => _seconds = d.inMicroseconds / 1e6),
  );
  double _seconds = 0;
  Future<String>? _future;
  String? _futureKey;

  MascotTheme get _theme =>
      widget.theme ??
      (Theme.of(context).brightness == Brightness.dark ? MascotTheme.dark : MascotTheme.light);

  bool get _moving {
    if (widget.tiny || widget.state == MascotState.error) return false;
    final reduced =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (MascotScope.maybeOf(context)?.reduceMotion ?? false);
    return widget.animate ?? !reduced;
  }

  void _syncTicker() {
    final want = _moving && TickerMode.valuesOf(context).enabled;
    if (want && !_ticker.isActive) _ticker.start();
    if (!want && _ticker.isActive) {
      _ticker.stop();
      _seconds = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  @override
  void didUpdateWidget(MascotView old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker.dispose();
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

  Widget _placeholder() => CustomPaint(
    size: Size.square(widget.size),
    painter: SpecPainter(spec: widget.spec, theme: _theme, state: widget.state),
  );

  Widget _drawing(String svg) {
    final s = widget.size;
    final moving = _moving;
    final t = _seconds;
    final layers = splitMascotSvg(svg, split: !widget.tiny);
    final k = s / 100;
    Widget pic(String text) =>
        SvgPicture.string(text, width: s, height: s, allowDrawingOutsideViewBox: true);

    final working = widget.state == MascotState.work && moving;
    final children = <Widget>[pic(layers.base)];
    if (layers.headset != null) {
      children.add(Opacity(opacity: working ? headsetOpacity(t) : 1, child: pic(layers.headset!)));
    }
    if (layers.tool != null) {
      final o = layers.toolOrigin ?? const Offset(50, 73);
      children.add(
        Transform.rotate(
          angle: working ? toolAngle(t) : 0,
          origin: Offset((o.dx - 50) * k, (o.dy - 50) * k),
          child: pic(layers.tool!),
        ),
      );
    }
    final m = moving ? coreMotion(widget.state, t) : CoreMotion.still;
    final core = Transform(
      // Around 50,90 of the box, like `.masc .core { transform-origin: 50px 90px }`.
      origin: Offset(50 * k, 90 * k),
      transform: Matrix4.identity()
        ..translateByDouble(0, m.dy * k, 0, 1)
        ..rotateZ(m.rotate)
        ..scaleByDouble(m.scaleX, m.scaleY, 1, 1),
      child: Stack(children: children),
    );
    if (widget.tiny) return core;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        core,
        CustomPaint(
          size: Size.square(s),
          painter: MarksPainter(
            state: widget.state,
            colors: MarkColors.of(_theme),
            thinkPhase: moving && widget.state == MascotState.think ? thinkPhase(t) : null,
            ringPhase: moving && widget.state == MascotState.wait ? ringPhase(t) : null,
          ),
        ),
      ],
    );
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
