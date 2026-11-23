// The agents' strip at the bottom of «Oggi» (3.12.1, the page's components/SimpleStrip.tsx,
// tavole-mascotte-chat/striscia-fitta.html): the mascots of every agent, overlapping by almost
// half. The mouse over it, or a finger sliding along it, enlarges the one under it (its neighbours
// a little); it makes a small movement and a balloon with its name and live state appears above;
// tapping the balloon opens its conversation. 3.12.2: the strip floats at the bottom of the
// screen (outside what scrolls), the one balloon slides to the newly picked one and fades, and a
// tap outside the strip and its balloon picks nobody.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/conversation.dart' show SessionRow;
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/words.dart' as words;
import 'simple_shell.dart' show openChat;

/// The agents in the strip: every working agent with a face of its own, but God and the Chat
/// (already on the orbit above), in the order they came (the page's `stripAgents`).
List<Agent> stripAgents(List<Agent> list, String? chatId) => [
  for (final a in list)
    if (a.status == 'active' &&
        a.kind != AgentKind.god &&
        a.kind != AgentKind.subagent &&
        a.id != chatId)
      a,
];

/// The index nearest to [x] among [centres]; -1 with none (the page's `nearestIndex`).
int nearestIndex(List<double> centres, double x) {
  var best = -1;
  var d = double.infinity;
  for (var i = 0; i < centres.length; i++) {
    if ((centres[i] - x).abs() < d) {
      d = (centres[i] - x).abs();
      best = i;
    }
  }
  return best;
}

/// Opens an agent's latest conversation (a new one when it has none).
Future<void> openAgentConversation(BuildContext context, AppController app, Agent a) async {
  final rows = app.live.sessions.where((r) => r.agentId == a.id && !r.archived).toList()
    ..sort((x, y) => (y.lastAt ?? y.createdAt).compareTo(x.lastAt ?? x.createdAt));
  final SessionRow? latest = rows.firstOrNull;
  if (latest != null) return openChat(context, latest.id, latest.title ?? a.name);
  final c = app.client;
  if (c == null) return;
  final sid = await c.newSession(a.id);
  if (!context.mounted) return;
  return openChat(context, sid, a.name);
}

/// The mascot's size in the strip (the page: 84, on a phone 64).
double stripMascotSize(BuildContext context) =>
    MediaQuery.sizeOf(context).width <= 640 ? 64.0 : 84.0;

/// The strip's real height (3.12.3): one mascot plus its title, nothing reserved for the balloon.
/// The content above pads itself with exactly this; the balloon opens over it.
double stripBandHeight(BuildContext context) => stripMascotSize(context) + _titleZone + _bottomPad;

const double _titleZone = 26;
const double _bottomPad = 10;
const Duration _moveTime = Duration(milliseconds: 250);

/// What the strip needs in height with the picked one enlarged and its balloon open: more than
/// [stripBandHeight], the rest is drawn over the content (it takes no touch where nothing is).
double _overlayHeight(double size) => _bottomPad + size * 1.75 + 62;

class SimpleStrip extends StatefulWidget {
  const SimpleStrip({super.key});

  /// True when there is at least one agent to show (otherwise the strip takes no room).
  static bool shows(AppController app) => stripAgents(app.agents, app.chatAgentId).isNotEmpty;

  @override
  State<SimpleStrip> createState() => _SimpleStripState();
}

class _SimpleStripState extends State<SimpleStrip> {
  String? _on;

  /// The balloon's agent: the last one picked, kept while the balloon fades out.
  String? _shown;

  void _pick(String? id) {
    if (id == _on) return;
    setState(() {
      _on = id;
      if (id != null) _shown = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = stripAgents(app.agents, app.chatAgentId);
    if (list.isEmpty) return const SizedBox.shrink();
    final size = stripMascotSize(context);
    // Overlapping by almost half.
    final step = size * 0.55;
    final band = stripBandHeight(context);
    final at = list.indexWhere((a) => a.id == _on);
    final shownAt = list.indexWhere((a) => a.id == (_on ?? _shown));
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final slide = reduced ? Duration.zero : _moveTime;
    return TapRegion(
      onTapOutside: (_) => _pick(null),
      child: SizedBox(
        height: _overlayHeight(size),
        child: LayoutBuilder(
          builder: (context, box) {
            final width = step * (list.length - 1) + size;
            final left0 = math.max(0.0, (box.maxWidth - width) / 2);
            final centres = [for (var i = 0; i < list.length; i++) left0 + i * step + size / 2];
            void under(double x) {
              final i = nearestIndex(centres, x);
              if (i >= 0) _pick(list[i].id);
            }

            // The picked one on top, its neighbours under it, the rest in order.
            final order = [for (var i = 0; i < list.length; i++) i]
              ..sort((a, b) {
                int rank(int i) => i == at ? 2 : (at >= 0 && (i - at).abs() == 1 ? 1 : 0);
                final r = rank(a).compareTo(rank(b));
                return r != 0 ? r : b.compareTo(a);
              });
            return MouseRegion(
              opaque: false,
              onHover: (e) => under(e.localPosition.dx),
              onExit: (_) => _pick(null),
              // Deferring to the children: the empty part above the band (where the balloon
              // opens) lets the touches through to the content behind.
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onPanDown: (d) => under(d.localPosition.dx),
                onPanUpdate: (d) => under(d.localPosition.dx),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: band,
                      child: Container(
                        key: const Key('simple-strip'),
                        decoration: BoxDecoration(
                          color: c.bg,
                          border: Border(top: BorderSide(color: c.line)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, c.text.withValues(alpha: 0.05)],
                          ),
                        ),
                        padding: const EdgeInsets.only(left: 20, top: 8),
                        alignment: Alignment.topLeft,
                        child: Text(
                          l.smpYourAgents,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            color: c.dim,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    for (final i in order)
                      // Keyed: when the order changes the same widget moves (and goes on
                      // animating); without the key every pick would rebuild it, with no motion.
                      Positioned(
                        key: ValueKey('strip-pos-${list[i].id}'),
                        left: centres[i] - size / 2,
                        bottom: _bottomPad,
                        child: _Mini(
                          key: Key('strip-${list[i].id}'),
                          agent: list[i],
                          size: size,
                          scale: i == at ? 1.75 : (at >= 0 && (i - at).abs() == 1 ? 1.22 : 1.0),
                          on: i == at,
                          reduced: reduced,
                          onFocus: () => _pick(list[i].id),
                        ),
                      ),
                    if (shownAt >= 0)
                      // The balloon's centre slides to the picked one's (its own width, which
                      // follows the name, never moves the centre), kept inside the screen.
                      TweenAnimationBuilder<double>(
                        key: const Key('strip-balloon-slide'),
                        tween: Tween(
                          end: centres[shownAt].clamp(
                            math.min(70.0, box.maxWidth / 2),
                            math.max(box.maxWidth - 70.0, box.maxWidth / 2),
                          ),
                        ),
                        duration: slide,
                        curve: Curves.ease,
                        builder: (context, x, child) => Positioned(
                          left: x,
                          top: 0,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0),
                            child: child,
                          ),
                        ),
                        child: IgnorePointer(
                          ignoring: at < 0,
                          child: AnimatedOpacity(
                            key: const Key('strip-balloon-fade'),
                            duration: slide,
                            opacity: at >= 0 ? 1 : 0,
                            onEnd: () {
                              if (_on == null && _shown != null && mounted) {
                                setState(() => _shown = null);
                              }
                            },
                            child: _Balloon(
                              agent: list[shownAt],
                              state: words.stateWord(l, app.live.mascotStateOf(list[shownAt].id)),
                              onTap: () =>
                                  unawaited(openAgentConversation(context, app, list[shownAt])),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Mini extends StatefulWidget {
  const _Mini({
    super.key,
    required this.agent,
    required this.size,
    required this.scale,
    required this.on,
    required this.reduced,
    required this.onFocus,
  });

  final Agent agent;
  final double size;
  final double scale;
  final bool on;
  final bool reduced;
  final VoidCallback onFocus;

  @override
  State<_Mini> createState() => _MiniState();
}

class _MiniState extends State<_Mini> with SingleTickerProviderStateMixin {
  // The small movement of the one picked: a little sway, once. The mascot itself is never
  // rebuilt from scratch (no key on it), so the scale change below runs as an animation.
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void didUpdateWidget(_Mini old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on && !widget.reduced) _sway.forward(from: 0);
    if (!widget.on && old.on) _sway.value = 1;
  }

  @override
  void dispose() {
    _sway.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final state = app.live.mascotStateOf(widget.agent.id);
    final d = widget.reduced ? Duration.zero : _moveTime;
    return Semantics(
      button: true,
      selected: widget.on,
      label: l.smpAgentIs(widget.agent.name, words.stateWord(l, state)),
      child: Focus(
        onFocusChange: (f) {
          if (f) widget.onFocus();
        },
        child: GestureDetector(
          onTap: widget.onFocus,
          child: AnimatedScale(
            scale: widget.scale,
            duration: d,
            curve: Curves.ease,
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: _sway,
              builder: (context, child) {
                final v = _sway.value;
                return Transform.rotate(
                  angle: widget.on && _sway.isAnimating
                      ? math.sin(v * 2 * math.pi) * 0.17 * (1 - v)
                      : 0,
                  alignment: Alignment.bottomCenter,
                  child: child,
                );
              },
              child: ExcludeSemantics(
                child: MascotView(
                  agentId: widget.agent.id,
                  spec: widget.agent.mascot,
                  state: state,
                  size: widget.size,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Balloon extends StatelessWidget {
  const _Balloon({required this.agent, required this.state, required this.onTap});

  final Agent agent;
  final String state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const Key('strip-balloon'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.accent, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 18)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(l.smpOpenChat, style: TextStyle(color: c.accent, fontSize: 12)),
                ],
              ),
              Text(state, style: TextStyle(color: c.dim, fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}
