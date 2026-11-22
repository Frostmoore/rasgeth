// The agents' strip at the bottom of «Oggi» (3.12.1, the page's components/SimpleStrip.tsx,
// tavole-mascotte-chat/striscia-fitta.html): the mascots of every agent, overlapping by almost
// half. The mouse over it, or a finger sliding along it, enlarges the one under it (its neighbours
// a little); it makes a small movement and a balloon with its name and live state appears above;
// tapping the balloon opens its conversation.
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

class SimpleStrip extends StatefulWidget {
  const SimpleStrip({super.key});

  @override
  State<SimpleStrip> createState() => _SimpleStripState();
}

class _SimpleStripState extends State<SimpleStrip> {
  String? _on;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = stripAgents(app.agents, app.chatAgentId);
    if (list.isEmpty) return const SizedBox.shrink();
    final phone = MediaQuery.sizeOf(context).width <= 640;
    final size = phone ? 64.0 : 84.0;
    // Overlapping by almost half.
    final step = size * 0.55;
    final at = list.indexWhere((a) => a.id == _on);
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Container(
      key: const Key('simple-strip'),
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, c.text.withValues(alpha: 0.05)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              l.smpYourAgents,
              style: TextStyle(
                fontSize: 13,
                color: c.dim,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, box) {
              final width = step * (list.length - 1) + size;
              final left0 = math.max(0.0, (box.maxWidth - width) / 2);
              final centres = [for (var i = 0; i < list.length; i++) left0 + i * step + size / 2];
              void under(double x) {
                final i = nearestIndex(centres, x);
                if (i >= 0 && list[i].id != _on) setState(() => _on = list[i].id);
              }

              // The picked one on top, its neighbours under it, the rest in order.
              final order = [for (var i = 0; i < list.length; i++) i]
                ..sort((a, b) {
                  int rank(int i) => i == at ? 2 : (at >= 0 && (i - at).abs() == 1 ? 1 : 0);
                  final r = rank(a).compareTo(rank(b));
                  return r != 0 ? r : b.compareTo(a);
                });
              return MouseRegion(
                onHover: (e) => under(e.localPosition.dx),
                onExit: (_) => setState(() => _on = null),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) => under(d.localPosition.dx),
                  onPanUpdate: (d) => under(d.localPosition.dx),
                  child: SizedBox(
                    height: size * 1.75 + 64,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (final i in order)
                          Positioned(
                            left: centres[i] - size / 2,
                            bottom: 0,
                            child: _Mini(
                              key: Key('strip-${list[i].id}'),
                              agent: list[i],
                              size: size,
                              scale: i == at ? 1.75 : (at >= 0 && (i - at).abs() == 1 ? 1.22 : 1.0),
                              on: i == at,
                              reduced: reduced,
                              onFocus: () => setState(() => _on = list[i].id),
                            ),
                          ),
                        if (at >= 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            child: Align(
                              alignment: Alignment(
                                box.maxWidth <= 0 ? 0 : (centres[at] / box.maxWidth) * 2 - 1,
                                -1,
                              ),
                              child: _Balloon(
                                agent: list[at],
                                state: words.stateWord(l, app.live.mascotStateOf(list[at].id)),
                                onTap: () =>
                                    unawaited(openAgentConversation(context, app, list[at])),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final state = app.live.mascotStateOf(agent.id);
    final d = reduced ? Duration.zero : const Duration(milliseconds: 220);
    return Semantics(
      button: true,
      selected: on,
      label: l.smpAgentIs(agent.name, words.stateWord(l, state)),
      child: Focus(
        onFocusChange: (f) {
          if (f) onFocus();
        },
        child: GestureDetector(
          onTap: onFocus,
          child: AnimatedScale(
            scale: scale,
            duration: d,
            curve: Curves.easeOutBack,
            alignment: Alignment.bottomCenter,
            // The small movement of the one picked: a little sway, once.
            child: TweenAnimationBuilder<double>(
              key: ValueKey(on),
              tween: Tween(begin: 0, end: 1),
              duration: on && !reduced ? const Duration(milliseconds: 700) : Duration.zero,
              builder: (context, v, child) => Transform.rotate(
                angle: on ? math.sin(v * 2 * math.pi) * 0.17 * (1 - v) : 0,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
              child: ExcludeSemantics(
                child: MascotView(agentId: agent.id, spec: agent.mascot, state: state, size: size),
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
