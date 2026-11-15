// The mascots' light animations, the same as the page's CSS (styles.css, `.masc`): only
// transforms and opacity, cycles of 1-4 seconds. [seconds] is the time since the mascot appeared.
import 'dart:math' as math;

import 'package:flutter/animation.dart';

import '../api/types.dart';

/// A CSS-like keyframe track: ([at], value) pairs on 0..1, ease-in-out between them.
double keyframes(double phase, List<(double, double)> frames) {
  final p = phase % 1;
  for (var i = 1; i < frames.length; i++) {
    final (a, va) = frames[i - 1];
    final (b, vb) = frames[i];
    if (p <= b) {
      final t = b == a ? 1.0 : (p - a) / (b - a);
      return va + (vb - va) * Curves.easeInOut.transform(t.clamp(0, 1));
    }
  }
  return frames.last.$2;
}

double _phase(double seconds, double period) => (seconds % period) / period;

/// How the body (`.core`, turning around 50,90 of the box) moves now.
class CoreMotion {
  const CoreMotion({this.scaleX = 1, this.scaleY = 1, this.rotate = 0, this.dy = 0});

  final double scaleX;
  final double scaleY;

  /// Radians.
  final double rotate;

  /// In the box's units (100 = the mascot's height).
  final double dy;

  static const still = CoreMotion();

  bool get isStill => scaleX == 1 && scaleY == 1 && rotate == 0 && dy == 0;
}

CoreMotion coreMotion(MascotState state, double seconds) {
  switch (state) {
    case MascotState.idle:
      // m-breathe 3.6 s: scale(1.02, 1.03) at half.
      final k = keyframes(_phase(seconds, 3.6), const [(0, 0), (.5, 1), (1, 0)]);
      return CoreMotion(scaleX: 1 + .02 * k, scaleY: 1 + .03 * k);
    case MascotState.work:
      // m-sway 1.6 s: -2.5 degrees at 25%, +2.5 at 75%.
      final d = keyframes(_phase(seconds, 1.6), const [(0, 0), (.25, -2.5), (.75, 2.5), (1, 0)]);
      return CoreMotion(rotate: d * math.pi / 180);
    case MascotState.wait:
      // m-hop 3 s: still until 78%, up 6 at 86%, a squash at 93%.
      final p = _phase(seconds, 3);
      final dy = keyframes(p, const [(0, 0), (.78, 0), (.86, -6), (.93, 1), (1, 0)]);
      final sq = keyframes(p, const [(0, 0), (.86, 0), (.93, 1), (1, 0)]);
      return CoreMotion(dy: dy, scaleX: 1 + .02 * sq, scaleY: 1 - .02 * sq);
    case MascotState.think:
    case MascotState.error:
      return CoreMotion.still;
  }
}

/// The tool while working (m-tool 0.8 s, alternate): down to -16 degrees, in radians.
double toolAngle(double seconds) {
  final p = _phase(seconds, 1.6);
  final k = keyframes(p, const [(0, 0), (.5, 1), (1, 0)]);
  return -16 * k * math.pi / 180;
}

/// The headset while working (m-pulse 1.2 s): opacity .75 at half.
double headsetOpacity(double seconds) =>
    1 - .25 * keyframes(_phase(seconds, 1.2), const [(0, 0), (.5, 1), (1, 0)]);

/// Thinking dots' cycle (1.8 s) and the waiting ring's (1.6 s), as 0..1.
double thinkPhase(double seconds) => _phase(seconds, 1.8);
double ringPhase(double seconds) => _phase(seconds, 1.6);
