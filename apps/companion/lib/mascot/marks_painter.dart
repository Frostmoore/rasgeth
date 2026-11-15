// The state's sign over a mascot, painted with the shapes of `marks()` in `@redgiant/mascot`
// (same coordinates on the 100x100 box): z z (idle), three dots (thinking), waves (working),
// the accent dot with its ring (waiting for the person), «!» (blocked). Visible without motion.
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../api/types.dart';

/// The theme's colours the library writes into the sign (`THEMES` in `@redgiant/mascot`).
class MarkColors {
  const MarkColors({required this.accent, required this.dim, required this.err});

  static const light = MarkColors(
    accent: Color(0xFFD23A2C),
    dim: Color(0xFF6B7385),
    err: Color(0xFFD23D3D),
  );
  static const dark = MarkColors(
    accent: Color(0xFFEF4B3A),
    dim: Color(0xFF8F96A3),
    err: Color(0xFFD23D3D),
  );

  static MarkColors of(MascotTheme t) => t == MascotTheme.dark ? dark : light;

  final Color accent;
  final Color dim;
  final Color err;
}

final _idle = [parseSvgPathData('M78 9h7l-7 8h7'), parseSvgPathData('M89 2h5l-5 6h5')];
final _work = [parseSvgPathData('M9 54q-3 6 0 12'), parseSvgPathData('M4 50q-4.5 10 0 20')];
final _bang = parseSvgPathData('M86 9.5v5.6M86 18.6v.1');

/// The opacity of a thinking dot (CSS `m-dot`: 0.3, up to 1 at 35%, back), [t] in 0..1.
double thinkDotOpacity(double t) {
  final p = t % 1;
  if (p < .35) return .3 + .7 * Curves.easeInOut.transform(p / .35);
  return 1 - .7 * Curves.easeInOut.transform((p - .35) / .65);
}

class MarksPainter extends CustomPainter {
  MarksPainter({required this.state, required this.colors, this.thinkPhase, this.ringPhase});

  final MascotState state;
  final MarkColors colors;

  /// Thinking: the cycle's position (0..1) of the dots' animation; null without motion.
  final double? thinkPhase;

  /// Waiting: the ring's position (0..1) in its cycle; null without motion.
  final double? ringPhase;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (state) {
      case MascotState.idle:
        for (final p in _idle) {
          canvas.drawPath(p, stroke(colors.dim, 2.2));
        }
      case MascotState.work:
        for (final p in _work) {
          canvas.drawPath(p, stroke(colors.dim, 2.4));
        }
      case MascotState.think:
        // At rest the dots are .35, .65 and 1 (the page's nth-child); moving, a wave of 0.3 s.
        const rest = [.35, .65, 1.0];
        for (var i = 0; i < 3; i++) {
          final ph = thinkPhase;
          final o = ph == null ? rest[i] : thinkDotOpacity(ph - i * .3 / 1.8);
          canvas.drawCircle(
            Offset(74 + 9.0 * i, 13),
            3.2,
            Paint()..color = colors.dim.withValues(alpha: o),
          );
        }
      case MascotState.wait:
        final ph = ringPhase;
        // CSS `m-ring`: up to 1.25 times and down to opacity .1 at half the cycle.
        final k = ph == null ? 0.0 : Curves.easeInOut.transform(1 - (2 * ph - 1).abs());
        canvas.save();
        canvas.translate(86, 14);
        canvas.scale(1 + .25 * k);
        canvas.drawCircle(
          Offset.zero,
          9,
          stroke(colors.accent.withValues(alpha: .45 - .35 * k), 2.2)..strokeCap = StrokeCap.butt,
        );
        canvas.restore();
        canvas.drawCircle(const Offset(86, 14), 5.5, Paint()..color = colors.accent);
      case MascotState.error:
        canvas.drawCircle(const Offset(86, 14), 8.5, Paint()..color = colors.err);
        canvas.drawPath(_bang, stroke(const Color(0xFFFFFFFF), 2.6));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MarksPainter old) =>
      old.state != state ||
      old.colors != colors ||
      old.thinkPhase != thinkPhase ||
      old.ringPhase != ringPhase;
}
