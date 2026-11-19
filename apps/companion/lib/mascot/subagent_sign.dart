// A sub-agent's sign instead of a mascot (decision «Mascotte solo per orchestratori e agenti di
// primo livello», 2026-11-19, board choice A): a ring in its parent's colour with a dot in the
// middle, the same drawing as `subagentSignSvg` in `@redgiant/mascot` on a 24x24 box. Asleep the
// ring fades and the dot goes; working an arc turns on a faded ring; thinking the dot pulses;
// waiting for the person a red badge blinks; blocked the ring turns red with a cross. It moves on
// the mascots' shared clock, and stays still with «Reduce motion».
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/types.dart';
import 'clock.dart';
import 'mascot_source.dart';
import 'mascot_view.dart' show hexColor;

/// The library's `THEMES` colours the sign uses (`dim`, `err`, `accent`, `panel`).
class SubagentSignColors {
  const SubagentSignColors({
    required this.ring,
    required this.err,
    required this.accent,
    required this.panel,
  });

  /// The ring: the parent's body colour in [theme], or the theme's grey without a parent.
  factory SubagentSignColors.of(MascotSpec? parent, MascotTheme theme) {
    final dark = theme == MascotTheme.dark;
    return SubagentSignColors(
      ring: parent != null
          ? hexColor(parent.colorsFor(theme).body)
          : Color(dark ? 0xFF8F96A3 : 0xFF6B7385),
      err: const Color(0xFFD23D3D),
      accent: Color(dark ? 0xFFEF4B3A : 0xFFD23A2C),
      panel: Color(dark ? 0xFF1C1F26 : 0xFFFFFFFF),
    );
  }

  final Color ring;
  final Color err;
  final Color accent;
  final Color panel;
}

class SubagentSign extends StatefulWidget {
  const SubagentSign({
    super.key,
    this.parent,
    this.state = MascotState.idle,
    this.size = 24,
    this.label,
    this.theme,
    this.animate,
    this.seconds,
  });

  /// The parent's mascot: the ring takes its colour (grey without one).
  final MascotSpec? parent;
  final MascotState state;
  final double size;

  /// The accessible name («Sub-agent Test UI, working»); without one it is decorative.
  final String? label;

  /// Default: the app's brightness.
  final MascotTheme? theme;

  /// Default: on, unless the system or the app reduces motion.
  final bool? animate;

  /// A fixed moment of the motion (tests) instead of the shared clock.
  final double? seconds;

  @override
  State<SubagentSign> createState() => _SubagentSignState();
}

class _SubagentSignState extends State<SubagentSign> {
  bool _listening = false;

  bool get _moving {
    if (widget.seconds != null) return true;
    final reduced =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (MascotScope.maybeOf(context)?.reduceMotion ?? false);
    return (widget.animate ?? !reduced) && _still.contains(widget.state) == false;
  }

  /// Asleep, awake and blocked nothing moves.
  static const _still = {MascotState.idle, MascotState.active, MascotState.error};

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
  void didUpdateWidget(SubagentSign old) {
    super.didUpdateWidget(old);
    _syncClock();
  }

  @override
  void dispose() {
    if (_listening) MascotClock.instance.detach(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        widget.theme ??
        (Theme.of(context).brightness == Brightness.dark ? MascotTheme.dark : MascotTheme.light);
    final t = _moving ? (widget.seconds ?? MascotClock.instance.seconds) : null;
    final box = CustomPaint(
      size: Size.square(widget.size),
      painter: SubagentSignPainter(
        colors: SubagentSignColors.of(widget.parent, theme),
        state: widget.state,
        seconds: t,
      ),
    );
    final label = widget.label;
    return label == null
        ? ExcludeSemantics(child: box)
        : Semantics(label: label, image: true, excludeSemantics: true, child: box);
  }
}

/// The sign on a 24x24 box scaled to the size; [seconds] null: the drawing at rest.
class SubagentSignPainter extends CustomPainter {
  const SubagentSignPainter({required this.colors, required this.state, this.seconds});

  final SubagentSignColors colors;
  final MascotState state;
  final double? seconds;

  /// The page's `rg-sign-fade`: full, 0.3 at half the period, full again.
  static double fade(double? t, double period) {
    if (t == null) return 1;
    final p = (t % period) / period;
    return 1 - 0.7 * (1 - (2 * p - 1).abs());
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    const c = Offset(12, 12);
    final ringColor = state == MascotState.error ? colors.err : colors.ring;
    Paint stroke(Color col, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = col;
    final faded = state == MascotState.work ? 0.3 : (state == MascotState.idle ? 0.5 : 1.0);
    canvas.drawCircle(c, 8, stroke(ringColor.withValues(alpha: faded), 3.2));
    if (state == MascotState.work) {
      // The page's arc: 16 of the 50.3 around (2 radians), turning once in 1.1 s.
      final turn = seconds == null ? 0.0 : (seconds! % 1.1) / 1.1 * 2 * math.pi;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 8), turn, 2, false, stroke(ringColor, 3.2));
    }
    if (state == MascotState.error) {
      final p = stroke(colors.err, 2.2);
      canvas.drawLine(const Offset(9.8, 9.8), const Offset(14.2, 14.2), p);
      canvas.drawLine(const Offset(14.2, 9.8), const Offset(9.8, 14.2), p);
    } else if (state != MascotState.idle) {
      final a = state == MascotState.think ? fade(seconds, 1.4) : 1.0;
      canvas.drawCircle(c, 3, Paint()..color = colors.ring.withValues(alpha: a));
    }
    if (state == MascotState.wait) {
      final a = fade(seconds, 1.2);
      const at = Offset(19.5, 4.5);
      canvas.drawCircle(at, 3.6, Paint()..color = colors.accent.withValues(alpha: a));
      canvas.drawCircle(at, 3.6, stroke(colors.panel.withValues(alpha: a), 1.6));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SubagentSignPainter old) =>
      old.state != state ||
      old.seconds != seconds ||
      old.colors.ring != colors.ring ||
      old.colors.accent != colors.accent;
}
