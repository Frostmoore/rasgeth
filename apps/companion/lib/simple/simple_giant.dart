// «Oggi»'s stage (3.12.1, the page's components/SimpleStage.tsx, tavole-mascotte-chat/luna.html):
// God's mascot, giant, at the centre above the greeting. Its mood follows what really happens
// (`giantMood`) and, still, it makes a small gesture now and then, never the same twice in a row.
// With reduced motion (the system's or the app's) it stays still.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/topics.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_source.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import 'simple_model.dart';

/// God's mood on «Oggi», from the app's real facts (the page's `godMood`).
GiantMood godMood(AppController app) {
  final god = app.god;
  final live = god == null ? MascotState.idle : app.live.mascotStateOf(god.id);
  final s = app.simple;
  return giantMood(
    typing: s.typing,
    routing: s.routing || live == MascotState.think,
    working: live == MascotState.work || s.topics.any((x) => x.state == TopicState.working),
    waiting:
        live == MascotState.wait ||
        app.live.forYou > 0 ||
        s.topics.any((x) => x.state == TopicState.waiting),
    happy: s.cheer,
    error: s.error != null || s.trouble != null || live == MascotState.error,
  );
}

/// Each mood in words, for screen readers.
String moodWord(AppLocalizations l, GiantMood m) => switch (m) {
  GiantMood.rest => l.smpMoodRest,
  GiantMood.listen => l.smpMoodListen,
  GiantMood.think => l.smpMoodThink,
  GiantMood.work => l.smpMoodWork,
  GiantMood.wait => l.smpMoodWait,
  GiantMood.happy => l.smpMoodHappy,
  GiantMood.worried => l.smpMoodWorried,
};

/// God's gestures: its eyes are one drawing, so no wink.
const godGestures = [
  IdleGesture.lookL,
  IdleGesture.lookR,
  IdleGesture.hop,
  IdleGesture.wiggle,
  IdleGesture.nod,
];

/// A giant mascot: its drawing in the mood's state, the mood's movement and, still, its gestures.
class GiantMascot extends StatefulWidget {
  const GiantMascot({
    super.key,
    required this.agent,
    required this.mood,
    this.name,
    this.gestures = godGestures,
    this.size = 220,
    this.still = false,
    this.rand,
  });

  final Agent? agent;

  /// Its name for screen readers, when not the agent's (Satellite).
  final String? name;

  /// Behind on the orbit: no gestures.
  final bool still;
  final GiantMood mood;
  final List<IdleGesture> gestures;
  final double size;

  /// The draw for gestures and their waits (tests give a fixed one).
  final double Function()? rand;

  @override
  State<GiantMascot> createState() => GiantMascotState();
}

class GiantMascotState extends State<GiantMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  final _random = math.Random();
  Timer? _timer;
  IdleGesture? _last;

  /// Whether the mood's movement runs (never with reduced motion).
  bool get moving => _motion.isAnimating;

  /// The gesture being made, or null.
  IdleGesture? gesture;
  DateTime _gestureAt = DateTime.now();

  double _rand() => widget.rand?.call() ?? _random.nextDouble();

  bool get _reduced =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      (MascotScope.maybeOf(context)?.reduceMotion ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(GiantMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood || oldWidget.still != widget.still) _sync();
  }

  void _sync() {
    if (_reduced) {
      _motion.stop();
      _stopGestures();
      return;
    }
    if (!_motion.isAnimating) unawaited(_motion.repeat());
    if (widget.mood == GiantMood.rest && !widget.still) {
      if (_timer == null) _nextGesture();
    } else {
      _stopGestures();
    }
  }

  void _stopGestures() {
    _timer?.cancel();
    _timer = null;
    if (gesture != null && mounted) setState(() => gesture = null);
  }

  void _nextGesture() {
    _timer = Timer(gestureDelay(_rand), () {
      if (!mounted) return;
      final g = nextGesture(_last, widget.gestures, _rand);
      _last = g;
      setState(() {
        gesture = g;
        _gestureAt = DateTime.now();
      });
      _timer = Timer(gestureLength(g), () {
        if (!mounted) return;
        setState(() => gesture = null);
        _nextGesture();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _motion.dispose();
    super.dispose();
  }

  /// The mood's and the gesture's movement at [t] (0-1 of the loop).
  Matrix4 _pose(double t) {
    final w = 2 * math.pi * t;
    var dx = 0.0, dy = 0.0, rot = 0.0, sx = 1.0, sy = 1.0;
    switch (widget.mood) {
      case GiantMood.listen:
        rot = -0.07 * (0.5 - 0.5 * math.cos(w));
        dy = 3 * (0.5 - 0.5 * math.cos(w));
      case GiantMood.think:
        rot = 0.05 * math.sin(w);
      case GiantMood.work:
        dy = -4 * (math.sin(2 * w).abs());
      case GiantMood.wait:
        dy = 4 * math.sin(w);
        rot = 0.03 * math.sin(w);
      case GiantMood.happy:
        final h = math.sin(math.pi * ((t * 2) % 1));
        dy = -22 * h;
        sx = 1 + 0.04 * h;
        sy = 1 - 0.04 * h;
      case GiantMood.worried:
        final p = (t * 1) % 1;
        dx = p < 0.2 ? 3 * math.sin(p * 10 * 2 * math.pi) : 0;
      case GiantMood.rest:
        dy = -7 * (0.5 - 0.5 * math.cos(w));
    }
    final g = gesture;
    if (g != null) {
      final total = gestureLength(g).inMilliseconds;
      final p = (DateTime.now().difference(_gestureAt).inMilliseconds / total).clamp(0.0, 1.0);
      final bump = math.sin(math.pi * p);
      switch (g) {
        case IdleGesture.lookL:
          dx -= 8 * bump;
          rot -= 0.06 * bump;
        case IdleGesture.lookR:
          dx += 8 * bump;
          rot += 0.06 * bump;
        case IdleGesture.hop:
          dy -= 16 * bump;
          sx *= 1 + 0.04 * bump;
          sy *= 1 - 0.04 * bump;
        case IdleGesture.wiggle:
          rot += 0.14 * math.sin(2 * math.pi * p);
        case IdleGesture.nod:
          rot += 0.07 * bump;
          dy += 4 * bump;
        case IdleGesture.wink:
          sy *= 1 - 0.03 * bump;
      }
    }
    final size = widget.size;
    return Matrix4.identity()
      ..translateByDouble(dx + size / 2, dy + size * 0.88, 0, 1)
      ..rotateZ(rot)
      ..scaleByDouble(sx, sy, 1, 1)
      ..translateByDouble(-size / 2, -size * 0.88, 0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = widget.agent;
    final drawing = MascotView(
      agentId: a?.id,
      spec: a?.mascot,
      // Behind on the orbit it shows no sign of its state (it would land on the one in front).
      state: widget.still ? MascotState.active : giantState(widget.mood),
      size: widget.size,
      signs: false,
      label: l.smpMascotOf(widget.name ?? a?.name ?? 'God', moodWord(l, widget.mood)),
    );
    return SizedBox(
      key: Key('simple-giant-${widget.mood.name}'),
      width: widget.size,
      height: widget.size,
      child: _reduced
          ? drawing
          : AnimatedBuilder(
              animation: _motion,
              builder: (context, child) => Transform(transform: _pose(_motion.value), child: child),
              child: drawing,
            ),
    );
  }
}

/// Satellite's mood: the Chat's live state, and the person writing to it.
GiantMood satelliteMood(AppController app) {
  final id = app.chatAgentId;
  final live = id == null ? MascotState.idle : app.live.mascotStateOf(id);
  final s = app.simple;
  return giantMood(
    typing: s.typing && s.front == StageFront.chat,
    routing: s.chatSending || live == MascotState.think,
    working: live == MascotState.work,
    waiting: live == MascotState.wait,
    error: live == MascotState.error,
  );
}

/// «Oggi»'s stage: God, giant, and Satellite behind him on the same orbit. A swipe, a tap on the
/// one behind or on the names bring the other in front; with reduced motion at once.
class SimpleStage extends StatefulWidget {
  const SimpleStage({super.key});

  @override
  State<SimpleStage> createState() => _SimpleStageState();
}

class _SimpleStageState extends State<SimpleStage> with SingleTickerProviderStateMixin {
  late final AppController _app = AppScope.read(context);
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addListener(() => setState(() {}));
  Map<StageFront, double> _from = const {};
  Map<StageFront, double> _to = const {};

  @override
  void initState() {
    super.initState();
    final f = _app.simple.front;
    _to = {
      StageFront.god: f == StageFront.god ? 0 : orbitBack,
      StageFront.chat: f == StageFront.chat ? 0 : orbitBack,
    };
    _from = _to;
    // Satellite is the Chat's face: the Chat agent is made on first use (as its screen does).
    if (_app.chatAgentId == null) unawaited(_app.ensureChatAgent());
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  double _theta(StageFront who) {
    final e = Curves.easeInOutCubic.transform(_turn.value);
    final a = _from[who] ?? 0, b = _to[who] ?? 0;
    return a + (b - a) * e;
  }

  void _rotate(int dir) {
    final s = _app.simple;
    final now = s.front;
    final back = now == StageFront.god ? StageFront.chat : StageFront.god;
    final from = {for (final k in StageFront.values) k: _theta(k)};
    s.bringFront(back);
    final reduced =
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
        (MascotScope.maybeOf(context)?.reduceMotion ?? false);
    final end = {now: dir * orbitBack, back: 0.0};
    if (reduced) {
      setState(() {
        _from = end;
        _to = end;
      });
      return;
    }
    // The one coming in front goes all the way round to 0, on the side of the swipe.
    var b = from[back]!;
    if (dir > 0 && b < 0) b += 2 * math.pi;
    if (dir < 0 && b > 0) b -= 2 * math.pi;
    _from = {now: from[now]!, back: b};
    _to = {now: dir * orbitBack, back: dir > 0 ? 2 * math.pi : -2 * math.pi};
    unawaited(
      _turn.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          _from = end;
          _to = end;
          _turn.value = 0;
        });
      }),
    );
  }

  void bring(StageFront who) {
    if (_app.simple.front == who) return;
    _rotate(_theta(who) > 0 ? -1 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final size = width > 640 ? 260.0 : 210.0;
    final radius = math.max(110.0, math.min(240.0, width * 0.36));
    return ListenableBuilder(
      listenable: Listenable.merge([app.simple, app.live]),
      builder: (context, _) {
        final front = app.simple.front;
        Widget orbiter(StageFront who) {
          final p = orbitPlace(_theta(who), radius);
          final isFront = front == who;
          final mascot = who == StageFront.god
              ? GiantMascot(agent: app.god, mood: godMood(app), size: size, still: !isFront)
              : GiantMascot(
                  agent: app.chatAgent,
                  name: l.smpSatellite,
                  mood: satelliteMood(app),
                  gestures: IdleGesture.values,
                  size: size,
                  still: !isFront,
                );
          return Positioned(
            key: Key('simple-orbiter-${who.name}'),
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.translate(
                offset: Offset(p.x, p.y),
                child: Transform.scale(
                  scale: p.scale,
                  child: GestureDetector(
                    onTap: isFront ? null : () => bring(who),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(_dim(p.light)),
                      child: mascot,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final order = [...StageFront.values]
          ..sort(
            (a, b) => orbitPlace(_theta(a), radius).z.compareTo(orbitPlace(_theta(b), radius).z),
          );
        return Column(
          children: [
            GestureDetector(
              key: const Key('simple-stage'),
              behavior: HitTestBehavior.opaque,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v.abs() > 100) _rotate(v > 0 ? 1 : -1);
              },
              child: SizedBox(
                height: size + 30,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: size * 0.75,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: CustomPaint(
                          size: Size(math.min(560, width * 0.92), size * 0.33),
                          painter: _OrbitPainter(c.dim.withValues(alpha: 0.35)),
                        ),
                      ),
                    ),
                    for (final who in order) orbiter(who),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Name(
                  key: const Key('simple-front-god'),
                  text: app.god?.name ?? 'God',
                  on: front == StageFront.god,
                  color: c.accent,
                  onTap: () => bring(StageFront.god),
                ),
                const SizedBox(width: 10),
                _Name(
                  key: const Key('simple-front-chat'),
                  text: l.smpSatelliteChat,
                  on: front == StageFront.chat,
                  color: satelliteLilac,
                  onTap: () => bring(StageFront.chat),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Satellite's lilac (the page's `--smp-chat`).
const satelliteLilac = Color(0xFF8F7CF0);

/// Dimmer behind (the page's `brightness`).
List<double> _dim(double k) => [
  k, 0, 0, 0, 0, //
  0, k, 0, 0, 0, //
  0, 0, k, 0, 0, //
  0, 0, 0, 1, 0, //
];

class _Name extends StatelessWidget {
  const _Name({
    super.key,
    required this.text,
    required this.on,
    required this.color,
    required this.onTap,
  });

  final String text;
  final bool on;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: on ? color : c.line, width: 1.5),
          ),
          child: Text(text, style: TextStyle(fontSize: 13, color: on ? c.text : c.dim)),
        ),
      ),
    );
  }
}

/// The orbit: a dashed ellipse under the giant.
class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & size;
    const dashes = 64;
    for (var i = 0; i < dashes; i += 2) {
      canvas.drawArc(rect, i * 2 * math.pi / dashes, 2 * math.pi / dashes, false, p);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.color != color;
}
