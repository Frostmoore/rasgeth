// 3.8.7: what the model is doing right now, as the page's card (packages/web/src/components/
// TurnProgress.tsx): reading the context (prefill) with how much is done, how fast and how much
// came from the cache, or writing, reasoning or the answer, with its speed. Local engines report
// the reading as it goes (`prefill`); for the others the wait is timed until the first token.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/live_model.dart';
import '../api/metrics.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';

/// Characters a token is worth, roughly: the live speed is an estimate until the end.
const _charsPerToken = 4;

/// `secs` of the page: 1.2 s under ten seconds, 12 s above.
String tpSecs(int ms) => '${(ms / 1000).toStringAsFixed(ms < 10000 ? 1 : 0)} s';

String _pct(double n) => '${jsRound(n * 100)}%';

class TurnProgress extends StatefulWidget {
  const TurnProgress({super.key, required this.call, this.now = DateTime.now, this.still = false});

  final ModelCall call;

  /// The clock (tests give a fake one).
  final DateTime Function() now;

  /// «Reduce motion»: the busy bar stands still.
  final bool still;

  @override
  State<TurnProgress> createState() => _TurnProgressState();
}

class _TurnProgressState extends State<TurnProgress> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Times move by themselves: the card is redrawn a few times a second.
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final call = widget.call;
    final now = widget.now();
    final p = call.prefill;
    final dim = TextStyle(color: c.dim, fontSize: 12);
    final first = call.firstToken;

    late final String title;
    late final int clockMs;
    double? done;
    final stats = <Widget>[];
    if (first == null) {
      final known = p != null && p.total > 0;
      title = l.tpReading;
      clockMs = now.difference(call.since).inMilliseconds;
      if (known) {
        final fresh = (p.processed - p.cached).clamp(0, 1 << 62);
        final rate = p.ms > 0 ? fresh / (p.ms / 1000) : null;
        done = p.processed / p.total;
        stats.add(Text(l.tpTokens(kTokens(p.processed), kTokens(p.total)), style: dim));
        if (rate != null && rate > 0) stats.add(Text(l.tpRate('${jsRound(rate)}'), style: dim));
        stats.add(
          Text(
            l.tpCache(_pct(p.cached / p.total)),
            style: p.cached / p.total >= 0.5 ? dim.copyWith(color: c.ok) : dim,
          ),
        );
      } else {
        stats.add(Text(l.tpWaitingFirst, style: dim));
      }
    } else {
      final elapsed = now.difference(first).inMilliseconds.clamp(1, 1 << 62);
      final tokens = call.chars / _charsPerToken;
      final rate = tokens / (elapsed / 1000);
      final firstAfter = tpSecs(first.difference(call.since).inMilliseconds);
      title = call.writing == 'thinking' ? l.tpThinking : l.tpWriting;
      clockMs = elapsed;
      stats.add(Text(l.tpWritten(kTokens(jsRound(tokens))), style: dim));
      if (elapsed > 800) stats.add(Text(l.tpGenRate('${jsRound(rate)}'), style: dim));
      if (p != null && p.total > 0) {
        stats.add(
          Text(l.tpReadIn(kTokens(p.total), firstAfter, _pct(p.cached / p.total)), style: dim),
        );
      }
      if (p == null) stats.add(Text(l.tpFirstAfter(firstAfter), style: dim));
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Container(
            key: const Key('turn-progress'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        key: const Key('turn-progress-title'),
                        style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(tpSecs(clockMs), style: TextStyle(color: c.dim, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                _Bar(done: done, still: widget.still),
                const SizedBox(height: 6),
                Wrap(spacing: 12, runSpacing: 4, children: stats),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The page's `ui-bar`: filled to [done], or a slice that slides while the end is unknown.
class _Bar extends StatefulWidget {
  const _Bar({required this.done, required this.still});

  final double? done;
  final bool still;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  bool get _busy => widget.done == null;

  void _sync() {
    if (_busy && !widget.still) {
      if (!_c.isAnimating) _c.repeat();
    } else if (_c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Bar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        key: const Key('turn-progress-bar'),
        height: 8,
        color: c.panel2,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            if (!_busy) {
              return Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  width: w * widget.done!.clamp(0.0, 1.0),
                  color: c.accent,
                ),
              );
            }
            return AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                // 30% of the width, from -100% to +340% of itself (the page's `ui-busy`).
                final t = widget.still ? 0.35 : Curves.easeInOut.transform(_c.value);
                final slice = w * 0.3;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: slice * (-1 + 4.4 * t),
                      top: 0,
                      bottom: 0,
                      width: slice,
                      child: ColoredBox(color: c.accent),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The agent works and nothing else on screen shows it (3.12.8, the page's `QuietWork`): the time since its last step
/// and, when a tool without a card of its own is under way, which one.
class QuietWork extends StatefulWidget {
  const QuietWork({
    super.key,
    required this.since,
    this.tool,
    this.now = DateTime.now,
    this.still = false,
  });

  final DateTime since;
  final String? tool;
  final DateTime Function() now;
  final bool still;

  @override
  State<QuietWork> createState() => _QuietWorkState();
}

class _QuietWorkState extends State<QuietWork> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final ms = widget.now().difference(widget.since).inMilliseconds.clamp(0, 1 << 62);
    final tool = widget.tool;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Semantics(
          liveRegion: true,
          container: true,
          child: Container(
            key: const Key('quiet-work'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border.all(color: c.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tool == null ? l.qwWorking : l.qwTool(tool),
                        style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(tpSecs(ms), style: TextStyle(color: c.dim, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                _Bar(done: null, still: widget.still),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
