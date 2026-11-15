// The mascots' motion: the library's table (`MASCOT_MOTION` in `@redgiant/mascot`, embedded in
// motion_table.g.dart), the same one the page's CSS is made from, played on the drawing's layers.
// Only transforms (translate, rotate, scale around each group's turning point) and opacity move.
// Every mascot has its own rhythm: the sixteen `--k` numbers on the SVG's root pick each track's
// period and phase, exactly as the page's `calc()` does.
import 'dart:convert';

import 'package:flutter/animation.dart';

import '../api/types.dart';
import 'motion_table.g.dart';
import 'rhythm.dart';

/// One keyframe: when (0..1) and the value (x and y; rotate and opacity use x).
typedef MotionFrame = ({double at, double x, double y});

enum MotionProp { translate, rotate, scale, opacity }

class MotionTrack {
  MotionTrack._({
    required this.el,
    required this.prop,
    required this.durMin,
    required this.durMax,
    required this.dk,
    required this.pk,
    required this.phase,
    required this.curve,
    required this.frames,
    this.rareEv,
    this.gapMin = 0,
    this.gapMax = 0,
  });

  factory MotionTrack.fromJson(Map<String, dynamic> j) {
    final dur = j['dur'];
    final (lo, hi) = dur is List
        ? ((dur[0] as num).toDouble(), (dur[1] as num).toDouble())
        : ((dur as num).toDouble(), dur.toDouble());
    final rare = j['rare'] as Map<String, dynamic>?;
    final gap = rare?['gap'] as List<dynamic>?;
    return MotionTrack._(
      rareEv: rare?['ev'] as String?,
      gapMin: (gap?[0] as num?)?.toDouble() ?? 0,
      gapMax: (gap?[1] as num?)?.toDouble() ?? 0,
      el: j['el'] as String,
      prop: MotionProp.values.byName(j['prop'] as String),
      durMin: lo,
      durMax: hi,
      dk: (j['dk'] as num?)?.toInt(),
      pk: (j['pk'] as num?)?.toInt(),
      phase: (j['phase'] as num?)?.toDouble() ?? 0,
      curve: _curves[j['ease'] as String? ?? 'ease-in-out'] ?? Curves.easeInOut,
      frames: [
        for (final f in (j['frames'] as List).cast<List<dynamic>>())
          switch (f[1]) {
            final List<dynamic> v => (
              at: (f[0] as num).toDouble(),
              x: (v[0] as num).toDouble(),
              y: (v[1] as num).toDouble(),
            ),
            final num v => (at: (f[0] as num).toDouble(), x: v.toDouble(), y: v.toDouble()),
            _ => throw FormatException('bad frame $f'),
          },
      ],
    );
  }

  /// The CSS timing functions, the same cubic curves.
  static const _curves = {
    'ease-in-out': Curves.easeInOut,
    'linear': Curves.linear,
    'ease-out': Curves.easeOut,
    'ease-in': Curves.easeIn,
  };

  final String el;
  final MotionProp prop;
  final double durMin;
  final double durMax;
  final int? dk;
  final int? pk;
  final double phase;
  final Curve curve;
  final List<MotionFrame> frames;

  /// A rare event (its name; null for the tracks that loop): it lasts [durMin] and comes back
  /// after [gapMin]..[gapMax] seconds, a different gap every time and per mascot.
  final String? rareEv;
  final double gapMin;
  final double gapMax;

  bool get isRare => rareEv != null;

  /// When this rare event starts between [from] and [to] (the library's `rareStarts`).
  List<double> starts(List<double> k, double from, double to) =>
      isRare ? rareStarts(rareEv!, gapMin, gapMax, pk, k, from, to) : const [];

  /// Where the rare event is at [seconds] (0..1), or null while it rests.
  double? rareProgress(double seconds, List<double> k) {
    for (final s in starts(k, seconds - durMin, seconds + 1e-9)) {
      if (seconds >= s && seconds < s + durMin) return (seconds - s) / durMin;
    }
    return null;
  }

  double duration(List<double> k) => durMin + (durMax - durMin) * _k(k, dk);

  /// Where the cycle is at [seconds] (0..1), as CSS with the delay `-dur * (k[pk] + phase)`.
  double progress(double seconds, List<double> k) {
    final p = seconds / duration(k) + _k(k, pk) + phase;
    return p - p.floorToDouble();
  }

  /// The value at [seconds]: the frames around the cycle's position, eased between them.
  ({double x, double y}) valueAt(double seconds, List<double> k) {
    if (isRare) {
      final p = rareProgress(seconds, k);
      if (p == null) return (x: frames.first.x, y: frames.first.y);
      return valueAtProgress(p);
    }
    return valueAtProgress(progress(seconds, k));
  }

  ({double x, double y}) valueAtProgress(double p) {
    for (var i = 1; i < frames.length; i++) {
      final a = frames[i - 1];
      final b = frames[i];
      if (p <= b.at) {
        final t = b.at == a.at ? 1.0 : ((p - a.at) / (b.at - a.at)).clamp(0.0, 1.0);
        final e = curve.transform(t);
        return (x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e);
      }
    }
    final last = frames.last;
    return (x: last.x, y: last.y);
  }

  static double _k(List<double> k, int? i) => i == null || i >= k.length ? 0 : k[i];
}

/// How one group stands at a moment: the page's `translate`, `rotate`, `scale` and `opacity`.
class MotionPose {
  const MotionPose({
    this.dx = 0,
    this.dy = 0,
    this.rotate = 0,
    this.sx = 1,
    this.sy = 1,
    this.opacity,
  });

  /// Box units (100 = the mascot's height).
  final double dx;
  final double dy;

  /// Degrees.
  final double rotate;
  final double sx;
  final double sy;

  /// Null: the drawing's own (the group's `opacity` attribute).
  final double? opacity;

  static const rest = MotionPose();

  bool get movesNothing => dx == 0 && dy == 0 && rotate == 0 && sx == 1 && sy == 1;
}

class MotionTable {
  MotionTable._(this.elements, this.states, this.tiny);

  factory MotionTable.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    List<MotionTrack> list(Object? l) => [
      for (final t in (l as List).cast<Map<String, dynamic>>()) MotionTrack.fromJson(t),
    ];
    final states = j['states'] as Map<String, dynamic>;
    return MotionTable._((j['elements'] as List).cast<String>().toSet(), {
      for (final s in MascotState.values) s: list(states[s.name]),
    }, list(j['tiny']));
  }

  static final MotionTable instance = MotionTable.parse(mascotMotionJson);

  /// Every group that moves (the app cuts these out as layers).
  final Set<String> elements;
  final Map<MascotState, List<MotionTrack>> states;
  final List<MotionTrack> tiny;

  /// Every moving group's pose at [seconds], for a mascot of rhythm [k].
  Map<String, MotionPose> poses(
    MascotState state,
    double seconds,
    List<double> k, {
    bool tiny = false,
  }) {
    final acc = <String, Map<MotionProp, ({double x, double y})>>{};
    for (final t in tiny ? this.tiny : states[state]!) {
      (acc[t.el] ??= {})[t.prop] = t.valueAt(seconds, k);
    }
    return {
      for (final MapEntry(key: el, value: v) in acc.entries)
        el: MotionPose(
          dx: v[MotionProp.translate]?.x ?? 0,
          dy: v[MotionProp.translate]?.y ?? 0,
          rotate: v[MotionProp.rotate]?.x ?? 0,
          sx: v[MotionProp.scale]?.x ?? 1,
          sy: v[MotionProp.scale]?.y ?? 1,
          opacity: v[MotionProp.opacity]?.x,
        ),
    };
  }
}
