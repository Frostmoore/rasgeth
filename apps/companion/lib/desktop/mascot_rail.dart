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

/// Wide enough for a mascot, the tree's indents and a name (3.8.8: agents under their lead).
const kRailWidth = 200.0;

/// One agent of the bar's tree and the ones under it (by `parentId`).
class RailNode {
  RailNode(this.agent, [List<RailNode>? children]) : children = children ?? [];

  final Agent agent;
  final List<RailNode> children;

  /// This agent and every one under it.
  Iterable<Agent> get all sync* {
    yield agent;
    for (final c in children) {
      yield* c.all;
    }
  }
}

/// A project's group (its lead on top, the others under it) or the agents without a project.
class RailGroup {
  RailGroup({required this.id, required this.title, required this.nodes, this.projectId});

  /// What the open/closed state is kept by: the project's id, or '-' for no project.
  final String id;
  final String title;
  final String? projectId;

  /// With a lead: one node (the lead, the rest under it); else the agents at the top level.
  final List<RailNode> nodes;
}

/// The bar's tree (3.8.8, the user: «the agents of a project under their orchestrator,
/// collapsible»): per project its orchestrator with the project's agents under it and their
/// subagents under them (`parentId`), the agents without a project last. God, Demi-God, the Chat
/// and the inspectors are not in it (God and the Chat are on top of the bar). Pure, tested.
List<RailGroup> railTree(AppController app, {required String noProject}) {
  final pool = app.agents
      .where(
        (a) =>
            a.kind != AgentKind.god &&
            a.kind != AgentKind.demigod &&
            a.kind != AgentKind.inspector &&
            a.id != app.chatAgentId &&
            (a.kind != AgentKind.subagent || a.active),
      )
      .toList();
  int order(Agent a, Agent b) {
    final f = (app.isFavourite(b.id) ? 1 : 0) - (app.isFavourite(a.id) ? 1 : 0);
    return f != 0 ? f : a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  List<RailNode> nest(List<Agent> members, String? under) {
    final ids = {for (final m in members) m.id};
    final here =
        members
            .where((m) => under == null ? !ids.contains(m.parentId) : m.parentId == under)
            .toList()
          ..sort(order);
    return [
      for (final a in here) RailNode(a, nest(members.where((m) => m.id != a.id).toList(), a.id)),
    ];
  }

  final known = {for (final p in app.projects) p.id};
  final out = <RailGroup>[];
  for (final p in app.projects) {
    final members = pool.where((a) => a.projectId == p.id).toList();
    if (members.isEmpty) continue;
    final lead = members.where((a) => a.kind == AgentKind.orchestrator).firstOrNull;
    final List<RailNode> nodes;
    if (lead == null) {
      nodes = nest(members, null);
    } else {
      final rest = members.where((a) => a.id != lead.id).toList();
      final ids = {for (final m in rest) m.id};
      // Under the lead: its own children and whoever has no parent inside the project.
      final top = rest.where((a) => a.parentId == lead.id || !ids.contains(a.parentId)).toList()
        ..sort(order);
      nodes = [
        RailNode(lead, [
          for (final a in top) RailNode(a, nest(rest.where((m) => m.id != a.id).toList(), a.id)),
        ]),
      ];
    }
    out.add(RailGroup(id: p.id, title: p.name, nodes: nodes, projectId: p.id));
  }
  final loose = pool.where((a) => a.projectId == null || !known.contains(a.projectId)).toList();
  if (loose.isNotEmpty) out.add(RailGroup(id: '-', title: noProject, nodes: nest(loose, null)));
  return out;
}

class MascotRail extends StatefulWidget {
  const MascotRail({super.key});

  /// Where the closed groups are kept (their ids, comma separated).
  static const closedPref = 'deskRailClosed';

  @override
  State<MascotRail> createState() => _MascotRailState();
}

class _MascotRailState extends State<MascotRail> {
  /// The nodes closed (agent ids): a lead or any agent with others under it.
  Set<String> _closed = {};

  @override
  void initState() {
    super.initState();
    AppScope.read(context).prefs.get(MascotRail.closedPref).then((v) {
      if (!mounted || v == null || v.isEmpty) return;
      setState(() => _closed = v.split(',').toSet());
    });
  }

  void _toggle(String id) {
    setState(() => _closed = {..._closed}..toggle(id));
    final v = (_closed.toList()..sort()).join(',');
    AppScope.read(context).prefs.set(MascotRail.closedPref, v.isEmpty ? null : v);
  }

  List<Widget> _rows(RailNode n, int depth) {
    final open = !_closed.contains(n.agent.id);
    return [
      _RailAgent(
        agent: n.agent,
        depth: depth,
        hidden: n.children.isEmpty || open ? const [] : n.all.skip(1).toList(),
        open: n.children.isEmpty ? null : open,
        onToggle: n.children.isEmpty ? null : () => _toggle(n.agent.id),
      ),
      if (open && n.children.isNotEmpty)
        _Guide(depth: depth, children: [for (final c in n.children) ..._rows(c, depth + 1)]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mac = isMacLike(app);
    final god = app.god;
    final chat = app.chatAgent;
    final groups = railTree(app, noProject: l.deskNoProject);
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
                padding: const EdgeInsets.only(bottom: 6, top: 4),
                children: [
                  if (god != null) _RailAgent(agent: god),
                  if (chat != null) _RailAgent(agent: chat),
                  for (final g in groups) ...[
                    Padding(
                      key: Key('rail-group-${g.id}'),
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 3),
                      child: Text(
                        g.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w700,
                          color: c.dim,
                        ),
                      ),
                    ),
                    for (final n in g.nodes) ..._rows(n, 0),
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

extension on Set<String> {
  void toggle(String id) => contains(id) ? remove(id) : add(id);
}

/// The children of an open node: indented, with a thin guide line on their left.
class _Guide extends StatelessWidget {
  const _Guide({required this.depth, required this.children});

  final int depth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Stack(
      children: [
        Positioned(
          // Under the parent's arrow.
          left: 21.0 + depth * _indent,
          top: 0,
          bottom: 8,
          child: Container(width: 1, color: c.line),
        ),
        Column(children: children),
      ],
    );
  }
}

const _indent = 14.0;

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
  const _RailAgent({
    required this.agent,
    this.depth = 0,
    this.open,
    this.onToggle,
    this.hidden = const [],
  });

  final Agent agent;
  final int depth;

  /// null: nothing under it; else whether its group is open (the arrow).
  final bool? open;
  final VoidCallback? onToggle;

  /// The agents its closed group hides: their work and their requests show on it.
  final List<Agent> hidden;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final state = app.live.mascotStateOf(a.id);
    final here = desk.panelAgentId == a.id;
    int asksOf(String id) => app.live.requests.where((r) => r.agentId == id).length;
    final asks = asksOf(a.id) + hidden.fold<int>(0, (n, x) => n + asksOf(x.id));
    // A closed group says whether someone under it works or waits for the person.
    final under = [for (final x in hidden) app.live.mascotStateOf(x.id)];
    final underWaits = under.contains(MascotState.wait) || hidden.any((x) => asksOf(x.id) > 0);
    final underWorks = under.any((s) => s == MascotState.work || s == MascotState.think);
    final tip = [a.name, stateWord(l, state), if (asks > 0) l.deskRailWaiting(asks)].join(' · ');
    return Tooltip(
      message: tip,
      waitDuration: const Duration(milliseconds: 500),
      child: Semantics(
        button: true,
        selected: here,
        expanded: open,
        label: tip,
        excludeSemantics: true,
        child: InkWell(
          key: Key('rail-${a.id}'),
          borderRadius: BorderRadius.circular(9),
          onSecondaryTapUp: (d) => showAgentMenu(context, a, d.globalPosition),
          onLongPress: () => showAgentSheet(context, a),
          onTap: () async {
            if (here) return;
            if (!await desk.openAgent(a) && context.mounted) {
              ScaffoldMessenger.maybeOf(context)
                  ?.showSnackBar(SnackBar(content: Text(l.statusUnreachable)));
            }
          },
          child: Container(
            height: 42,
            margin: EdgeInsets.fromLTRB(6 + depth * _indent, 1, 6, 1),
            padding: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: here ? c.accentSoft : null,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: here ? c.accent : Colors.transparent, width: 1.2),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: open == null
                      ? null
                      : InkWell(
                          key: Key('rail-fold-${a.id}'),
                          borderRadius: BorderRadius.circular(5),
                          onTap: onToggle,
                          child: SizedBox(
                            height: 28,
                            child: Center(
                              child: RgIcon(
                                open! ? RgIcons.chevronDown : RgIcons.chevronRight,
                                size: 13,
                                color: c.dim,
                              ),
                            ),
                          ),
                        ),
                ),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      MascotView(agentId: a.id, spec: a.mascot, state: state, size: 32),
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          key: Key('rail-dot-${a.id}'),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: stateColor(c, state),
                            shape: BoxShape.circle,
                            border: Border.all(color: here ? c.accentSoft : c.panel, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: here ? FontWeight.w700 : FontWeight.w500,
                      color: here ? c.text : c.dim,
                    ),
                  ),
                ),
                if (open == false && (underWorks || underWaits))
                  Container(
                    key: Key('rail-under-${a.id}'),
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: underWaits ? c.accent : c.ok,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (asks > 0)
                  Container(
                    key: Key('rail-asks-${a.id}'),
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(9),
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
