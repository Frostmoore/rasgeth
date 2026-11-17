// The conversations «full window» (3.8.3): the open conversation covers the room under the menus
// and the agents' mascots stand in a bar on its left, to go from one conversation to another
// with one click. At the top the way back to the room, then God and the Chat, then the agents
// grouped as the wall groups them (by project or by state), «New agent» at the bottom. Each
// mascot is alive, with its state's dot, its requests waiting and its name; the open one is lit.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../screens/new_agent_screen.dart';
import '../screens/team_screen.dart' show showAgentSheet, stateColor;
import '../theme/colors.dart';
import '../ui/agent_menu.dart';
import '../ui/icons.dart';
import '../ui/words.dart';
import 'desk_controller.dart';
import 'desk_menu.dart';
import 'wall.dart' show wallSections;

const kRailWidth = 92.0;

class MascotRail extends StatelessWidget {
  const MascotRail({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mac = isMacLike(app);
    final god = app.god;
    final chat = app.chatAgent;
    final sections = wallSections(app, l, byProject: desk.byProject, filter: WallFilter.all);
    return Semantics(
      container: true,
      label: l.deskRailLabel,
      child: Container(
        key: const Key('desk-rail'),
        width: kRailWidth,
        decoration: BoxDecoration(
          color: c.panel,
          border: Border(right: BorderSide(color: c.line)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _RailButton(
              key: const Key('rail-room'),
              icon: RgIcons.home,
              label: l.deskBackToRoom,
              onTap: desk.backToRoom,
            ),
            _Line(c),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 6),
                children: [
                  if (god != null) _RailAgent(agent: god),
                  if (chat != null) _RailAgent(agent: chat),
                  for (final s in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 2),
                      child: Text(
                        s.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w700,
                          color: c.dim,
                        ),
                      ),
                    ),
                    for (final a in s.agents) _RailAgent(agent: a),
                  ],
                ],
              ),
            ),
            _Line(c),
            _RailButton(
              key: const Key('rail-new-agent'),
              icon: RgIcons.plus,
              label:
                  '${l.teamNewAgent} (${shortcutLabel(cmdKey(LogicalKeyboardKey.keyN, mac: mac), l, mac: mac)})',
              onTap: () => openNewAgent(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.c);

  final RgColors c;

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: c.line);
}

/// A round drawn button of the bar (back to the room, new agent).
class _RailButton extends StatelessWidget {
  const _RailButton({super.key, required this.icon, required this.label, required this.onTap});

  final RgIcons icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: label,
        preferBelow: false,
        child: Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: Material(
            color: c.panel2,
            shape: CircleBorder(side: BorderSide(color: c.line)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Center(child: RgIcon(icon, size: 19, color: c.text)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RailAgent extends StatelessWidget {
  const _RailAgent({required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final state = app.live.mascotStateOf(a.id);
    final open = desk.panelAgentId == a.id;
    final asks = app.live.requests.where((r) => r.agentId == a.id).length;
    final tip = [a.name, stateWord(l, state), if (asks > 0) l.deskRailWaiting(asks)].join(' · ');
    return Tooltip(
      message: tip,
      waitDuration: const Duration(milliseconds: 350),
      child: Semantics(
        button: true,
        selected: open,
        label: tip,
        excludeSemantics: true,
        child: InkWell(
          key: Key('rail-${a.id}'),
          onSecondaryTapUp: (d) => showAgentMenu(context, a, d.globalPosition),
          onLongPress: () => showAgentSheet(context, a),
          onTap: () async {
            if (open) return;
            if (!await desk.openAgent(a) && context.mounted) {
              ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(SnackBar(content: Text(l.statusUnreachable)));
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 5),
            decoration: BoxDecoration(
              color: open ? c.accentSoft : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: open ? c.accent : Colors.transparent, width: 1.5),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 46,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 2,
                        top: 0,
                        child: MascotView(agentId: a.id, spec: a.mascot, state: state, size: 44),
                      ),
                      // The state: working, waiting for you, still.
                      Positioned(
                        right: 2,
                        bottom: 0,
                        child: Container(
                          key: Key('rail-dot-${a.id}'),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: stateColor(c, state),
                            shape: BoxShape.circle,
                            border: Border.all(color: open ? c.accentSoft : c.panel, width: 2),
                          ),
                        ),
                      ),
                      if (asks > 0)
                        Positioned(
                          right: -4,
                          top: -3,
                          child: Container(
                            key: Key('rail-asks-${a.id}'),
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: c.panel, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$asks',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  a.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.15,
                    fontWeight: open ? FontWeight.w700 : FontWeight.w500,
                    color: open ? c.text : c.dim,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Escape leaves the full window, unless something is being written in the focused field.
bool writingNow() {
  final ctx = FocusManager.instance.primaryFocus?.context;
  if (ctx == null) return false;
  final edit = ctx.findAncestorStateOfType<EditableTextState>();
  return edit != null && edit.textEditingValue.text.trim().isNotEmpty;
}
