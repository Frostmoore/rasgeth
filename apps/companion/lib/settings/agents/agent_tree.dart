// G42.4: the agents' tree as the page's Settings › Agents draws it (Hierarchy.tsx, TreeView), on
// a phone too and beyond the first level: God on top, Demi-God and the personal agents in one
// group, each project in its own frame with its lead's team (agents, their helpers, the agents of
// other places assigned to it, dashed) and its inspector. Every level opens and closes; a tap
// opens the agent's settings; «Agent under it» under each project lead; «Also the stopped ones»
// and the project filter as on the page. The rules are one pure function, [agentForest].
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../mascot/mascot_view.dart';
import '../../screens/agent_settings_screen.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch, openNewAgent;
import '../../screens/removed_agents_screen.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../../ui/words.dart';
import 'add_agent_under.dart';

/// Who may hang under whom (the page's `CHILDREN`).
const agentChildren = <AgentKind, List<AgentKind>>{
  AgentKind.god: [
    AgentKind.demigod,
    AgentKind.orchestrator,
    AgentKind.inspector,
    AgentKind.assistant,
  ],
  AgentKind.demigod: [],
  AgentKind.orchestrator: [AgentKind.agent],
  AgentKind.agent: [AgentKind.subagent],
  AgentKind.subagent: [],
  AgentKind.inspector: [],
  AgentKind.assistant: [],
};

/// The kinds a person may add under [a] (never a helper: agents make those themselves).
List<AgentKind> addableUnder(Agent a) =>
    (agentChildren[a.kind] ?? const []).where((k) => k != AgentKind.subagent).toList();

/// «Agent under it»: an active agent that may have children the person makes.
bool canAddUnder(Agent a) => a.active && addableUnder(a).isNotEmpty;

bool _lead(Agent a) => a.kind == AgentKind.orchestrator || a.kind == AgentKind.inspector;

/// One agent in the tree, with those under it.
class AgentNode {
  const AgentNode(this.agent, {this.children = const [], this.assigned = false, this.plus = false});

  final Agent agent;
  final List<AgentNode> children;

  /// An agent of another place assigned to this project (drawn dashed, «assigned»).
  final bool assigned;

  /// The «Agent under it» button goes under it (an active project lead).
  final bool plus;

  /// Every agent of this branch, depth first (for tests and the counts).
  Iterable<(AgentNode, int)> walk([int depth = 0]) sync* {
    yield (this, depth);
    for (final k in children) {
      yield* k.walk(depth + 1);
    }
  }
}

/// A project's frame: its lead's team and its inspector.
class ProjectFrame {
  const ProjectFrame(this.projectId, this.leads);

  final String projectId;
  final List<AgentNode> leads;
}

/// The whole tree: the roots (God), the group under it and one frame per project.
class AgentForest {
  const AgentForest({this.roots = const [], this.nearOf = const {}, this.frames = const []});

  final List<Agent> roots;

  /// Under each root, Demi-God and the personal agents in one column.
  final Map<String, List<Agent>> nearOf;

  /// The projects' frames: under God only.
  final List<ProjectFrame> frames;

  /// God's group (the first root's when there is no God).
  List<Agent> get near =>
      nearOf[(roots.where((r) => r.kind == AgentKind.god).firstOrNull ?? roots.firstOrNull)?.id] ??
      const [];

  bool get isEmpty => roots.isEmpty && frames.every((f) => f.leads.isEmpty);
}

AgentNode _subtree(Agent a, List<Agent> list) {
  final kids = [
    for (final k in list)
      if (k.parentId == a.id && !_lead(k)) _subtree(k, list),
  ];
  final assigned = a.kind == AgentKind.orchestrator && a.projectId != null
      ? [
          for (final k in list)
            if (k.projectId != a.projectId && k.projects.contains(a.projectId))
              AgentNode(k, assigned: true),
        ]
      : const <AgentNode>[];
  return AgentNode(
    a,
    children: [...kids, ...assigned],
    plus: a.kind == AgentKind.orchestrator && a.active,
  );
}

ProjectFrame _frame(String projectId, List<Agent> list) => ProjectFrame(projectId, [
  for (final a in list)
    if (a.projectId == projectId && _lead(a)) _subtree(a, list),
]);

/// The page's TreeView as data: the agents shown ([showStopped] adds the stopped ones), with a
/// [projectId] only that project's (its own and those assigned to it), from its lead down.
AgentForest agentForest(List<Agent> all, {String? projectId, bool showStopped = false}) {
  final shown = [
    for (final a in all)
      if (showStopped || a.active) a,
  ];
  final list = projectId == null
      ? shown
      : [
          for (final a in shown)
            if (a.projectId == projectId || a.projects.contains(projectId)) a,
        ];
  if (projectId != null) return AgentForest(frames: [_frame(projectId, list)]);
  final roots = [
    for (final a in list)
      if (a.parentId == null) a,
  ];
  final god = roots.where((r) => r.kind == AgentKind.god).firstOrNull;
  final nearOf = {
    for (final r in roots)
      r.id: [
        for (final a in list)
          if (a.parentId == r.id && !_lead(a)) a,
      ],
  };
  final ids = <String>{
    for (final a in list)
      if (_lead(a) && a.projectId != null) a.projectId!,
  }.toList();
  return AgentForest(
    roots: roots,
    nearOf: nearOf,
    frames: god == null ? const [] : [for (final p in ids) _frame(p, list)],
  );
}

/// Opens the tree: a whole screen, on a phone as on a computer (the page's own page).
Future<void> openAgentTree(BuildContext context, {String? projectId}) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => AgentTreeScreen(projectId: projectId)));

class AgentTreeScreen extends StatefulWidget {
  const AgentTreeScreen({super.key, this.projectId});

  /// Only this project's agents (its page), without the filter.
  final String? projectId;

  @override
  State<AgentTreeScreen> createState() => _AgentTreeScreenState();
}

class _AgentTreeScreenState extends State<AgentTreeScreen> {
  String? _filter;
  bool _stopped = false;

  /// The branches closed by the person (everything is open at first, as on the page).
  final _closed = <String>{};

  void _toggle(String id) =>
      setState(() => _closed.contains(id) ? _closed.remove(id) : _closed.add(id));

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final scope = widget.projectId ?? _filter;
    return ListenableBuilder(
      listenable: Listenable.merge([app, app.live]),
      builder: (context, _) {
        final forest = agentForest(app.agents, projectId: scope, showStopped: _stopped);
        final hasGod = app.agents.any((a) => a.parentId == null);
        final projectName = widget.projectId == null
            ? null
            : app.projects.where((p) => p.id == widget.projectId).firstOrNull?.name ??
                  widget.projectId;
        return SettingsScaffold(
          title: projectName == null ? l.g4AgTreeTitle : l.g4AgTreeOf(projectName),
          backKey: const Key('tree-back'),
          backLabel: l.back,
          listKey: const Key('agent-tree'),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                widget.projectId == null ? l.g4AgTreeLead : l.g4AgTreeProjectLead,
                style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.4),
              ),
            ),
            if (widget.projectId == null && app.projects.isNotEmpty)
              SizedBox(
                height: 46,
                child: ListView(
                  key: const Key('tree-filters'),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  children: [
                    _Chip(
                      key: const Key('tree-filter-all'),
                      label: l.g4AgAllProjects,
                      on: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final p in app.projects)
                      _Chip(
                        key: Key('tree-filter-${p.id}'),
                        label: p.name,
                        icon: RgIcons.folder,
                        on: _filter == p.id,
                        onTap: () => setState(() => _filter = p.id),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      key: const Key('tree-stopped'),
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _stopped = !_stopped),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            RgSwitch(on: _stopped),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                l.g4AgShowStopped,
                                style: TextStyle(color: c.text, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasGod && widget.projectId == null)
                    FilledButton.icon(
                      key: const Key('tree-new'),
                      onPressed: () => openNewAgent(context),
                      icon: const RgIcon(RgIcons.plus, size: 16, color: Colors.white),
                      label: Text(l.teamNewAgent),
                    ),
                ],
              ),
            ),
            if (forest.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  scope != null ? l.g4AgNoLead : l.teamNoAgents,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.dim),
                ),
              ),
            for (final root in forest.roots)
              if ((forest.nearOf[root.id] ?? const <Agent>[]) case final near) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _NodeRow(
                    agent: root,
                    depth: 0,
                    open: !_closed.contains(root.id),
                    hasKids:
                        near.isNotEmpty || (root.kind == AgentKind.god && forest.frames.isNotEmpty),
                    onToggle:
                        near.isNotEmpty || (root.kind == AgentKind.god && forest.frames.isNotEmpty)
                        ? () => _toggle(root.id)
                        : null,
                  ),
                ),
                if (!_closed.contains(root.id)) ...[
                  if (near.isNotEmpty)
                    _Frame(
                      key: Key(root.kind == AgentKind.god ? 'tree-near' : 'tree-near-${root.id}'),
                      title: l.g4AgNear,
                      children: [for (final a in near) _NodeRow(agent: a, depth: 0)],
                    ),
                  if (root.kind == AgentKind.god)
                    for (final f in forest.frames)
                      _Frame(
                        key: Key('tree-project-${f.projectId}'),
                        title:
                            app.projects.where((p) => p.id == f.projectId).firstOrNull?.name ??
                            app.archivedProjects
                                .where((p) => p.id == f.projectId)
                                .firstOrNull
                                ?.name ??
                            f.projectId,
                        archived: app.archivedProjects.any((p) => p.id == f.projectId),
                        children: [
                          if (f.leads.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(l.g4AgNoLead, style: TextStyle(color: c.dim)),
                            ),
                          for (final n in f.leads)
                            _Branch(node: n, depth: 0, closed: _closed, toggle: _toggle),
                        ],
                      ),
                ],
              ],
            if (forest.roots.isEmpty)
              for (final f in forest.frames)
                for (final n in f.leads)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _Branch(node: n, depth: 0, closed: _closed, toggle: _toggle),
                  ),
            const SizedBox(height: 12),
            SettingsCard(
              children: [
                ListTile(
                  key: const Key('tree-removed'),
                  leading: RgIcon(RgIcons.archive, size: 18, color: c.dim),
                  title: Text(
                    l.raListTitle,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(l.raListRow, style: TextStyle(color: c.dim)),
                  trailing: RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
                  onTap: () => openRemovedAgents(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// One branch: its agent, then (open) those under it behind a line, and «Agent under it».
class _Branch extends StatelessWidget {
  const _Branch({
    required this.node,
    required this.depth,
    required this.closed,
    required this.toggle,
  });

  final AgentNode node;
  final int depth;
  final Set<String> closed;
  final ValueChanged<String> toggle;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final a = node.agent;
    final id = node.assigned ? 'as-${a.id}' : a.id;
    final open = !closed.contains(id);
    final hasKids = node.children.isNotEmpty || node.plus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NodeRow(
          agent: a,
          depth: depth,
          assigned: node.assigned,
          open: open,
          hasKids: hasKids,
          onToggle: hasKids ? () => toggle(id) : null,
        ),
        if (open && hasKids)
          Container(
            margin: const EdgeInsets.only(left: 22),
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.line, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final k in node.children)
                  _Branch(node: k, depth: depth + 1, closed: closed, toggle: toggle),
                if (node.plus)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 6),
                      child: TextButton.icon(
                        key: Key('tree-add-${a.id}'),
                        onPressed: () => openAddUnder(context, a),
                        icon: RgIcon(RgIcons.plus, size: 15, color: c.accent),
                        label: Text(l.g4AgAddShort, style: TextStyle(color: c.accent)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One agent: its living mascot, name, job (or kind, or «assigned») and state; a tap opens its
/// settings, the chevron opens or closes what is under it.
class _NodeRow extends StatelessWidget {
  const _NodeRow({
    required this.agent,
    required this.depth,
    this.assigned = false,
    this.open = true,
    this.hasKids = false,
    this.onToggle,
  });

  final Agent agent;
  final int depth;
  final bool assigned;
  final bool open;
  final bool hasKids;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final state = app.live.mascotStateOf(a.id);
    final busy = state == MascotState.work || state == MascotState.think;
    final sub = assigned
        ? l.g4AgAssigned
        : (a.role != null && a.role!.trim().isNotEmpty ? a.role!.trim() : kindWords(l, app, a));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: assigned ? Colors.transparent : (a.active ? c.panel : c.panel2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: busy ? c.accent.withValues(alpha: .55) : c.line,
            width: assigned ? 1.2 : 1,
            style: BorderStyle.solid,
          ),
        ),
        child: InkWell(
          key: Key(assigned ? 'tree-assigned-${a.id}' : 'tree-node-${a.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: () => unawaited(openAgentSettings(context, a)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
            child: Row(
              children: [
                Opacity(
                  opacity: a.active ? 1 : .55,
                  child: MascotView(
                    agentId: a.id,
                    spec: a.mascot,
                    state: state,
                    size: 36,
                    label: a.name,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: a.active ? c.text : c.dim,
                              ),
                            ),
                          ),
                          if (!a.active) ...[const SizedBox(width: 6), _Tag(text: l.asStopped)],
                          if (assigned) ...[
                            const SizedBox(width: 6),
                            _Tag(text: l.g4AgAssigned, accent: true),
                          ],
                        ],
                      ),
                      Text(
                        assigned ? kindWords(l, app, a) : sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.dim, fontSize: 12.5),
                      ),
                      if (busy || state == MascotState.wait)
                        Text(
                          stateWord(l, state),
                          style: TextStyle(
                            color: state == MascotState.wait ? c.warn : c.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (onToggle != null)
                  IconButton(
                    key: Key('tree-toggle-${assigned ? 'as-' : ''}${a.id}'),
                    tooltip: open ? l.g4AgClose : l.g4AgOpen,
                    onPressed: onToggle,
                    icon: AnimatedRotation(
                      turns: open ? 0 : -.25,
                      duration: const Duration(milliseconds: 160),
                      child: RgIcon(RgIcons.chevronDown, size: 18, color: c.dim),
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: accent ? c.accentSoft : c.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent ? c.accent.withValues(alpha: .5) : c.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: accent ? c.accent : c.dim,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A group in a frame of its own (a project, or Demi-God and the personal agents).
class _Frame extends StatelessWidget {
  const _Frame({super.key, required this.title, required this.children, this.archived = false});

  final String title;
  final List<Widget> children;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Row(
              children: [
                RgIcon(archived ? RgIcons.archive : RgIcons.folder, size: 14, color: c.dim),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: .3,
                      color: c.dim,
                    ),
                  ),
                ),
                if (archived) ...[const SizedBox(width: 6), _Tag(text: l.g4AgArchived)],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.label, required this.on, required this.onTap, this.icon});

  final String label;
  final bool on;
  final VoidCallback onTap;
  final RgIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? c.accentSoft : c.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: on ? c.accent : c.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    RgIcon(icon!, size: 14, color: on ? c.accent : c.dim),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: c.text,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
