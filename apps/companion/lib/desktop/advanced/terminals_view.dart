// Terminals on computers (G40.17, board C advanced 3): the agents' terminals (read only: what
// they ran and what it printed, read again as they work) and the person's own shells in the
// project's container, side by side in a grid or one at a time as tabs, each with its agent's
// mascot over it. The cells are the phone's (G40.11) without the row of extra keys.
import 'package:flutter/material.dart';

import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../mascot/mascot_view.dart';
import '../../screens/code/terminal_tab.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/icons.dart';
import '../../ui/words.dart';
import '../desk_controller.dart';
import '../wall.dart' show Segmented;
import 'common.dart';

/// One terminal in the grid: an agent's (read only) or one of the person's.
class TermCell {
  TermCell.agent(this.agentId, this.projectId) : command = null, own = false;
  TermCell.own(this.projectId, {this.command}) : agentId = null, own = true;

  final String? agentId;
  final String projectId;
  final bool own;
  final String? command;

  late final String key = own
      ? 'own:$projectId:${identityHashCode(this)}'
      : 'agent:$agentId';
}

/// The terminals shown first: the agents at work, then the project's, at most [max].
List<TermCell> firstCells(AppController app, String? projectId, {int max = 4}) {
  final withProject = app.agents
      .where((a) => a.projectId != null && a.kind != AgentKind.subagent)
      .toList();
  bool working(Agent a) {
    final s = app.live.mascotStateOf(a.id);
    return s == MascotState.work || s == MascotState.think || s == MascotState.error;
  }

  final ordered = [
    ...withProject.where(working),
    ...withProject.where((a) => !working(a) && a.projectId == projectId),
  ];
  return [for (final a in ordered.take(max)) TermCell.agent(a.id, a.projectId!)];
}

class TerminalsView extends StatefulWidget {
  const TerminalsView({super.key});

  @override
  State<TerminalsView> createState() => _TerminalsViewState();
}

class _TerminalsViewState extends State<TerminalsView> {
  List<TermCell>? _cells;
  bool _tabs = false;
  int _tab = 0;
  late final DeskController _desk = DeskScope.read(context);

  @override
  void initState() {
    super.initState();
    _desk.addListener(_pending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _pending());
  }

  @override
  void dispose() {
    _desk.removeListener(_pending);
    super.dispose();
  }

  void _pending() {
    if (!mounted) return;
    final cmd = _desk.takeCommand();
    if (cmd == null) return;
    _add(TermCell.own(cmd.projectId, command: cmd.command));
  }

  void _add(TermCell cell) {
    setState(() {
      final cells = _cells ??= [];
      if (!cell.own && cells.any((x) => x.key == cell.key)) return;
      cells.add(cell);
      _tab = cells.length - 1;
    });
  }

  void _remove(TermCell cell) => setState(() {
    _cells?.remove(cell);
    _tab = _tab.clamp(0, ((_cells?.length ?? 1) - 1).clamp(0, 1 << 20));
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final cells = _cells ??= firstCells(app, desk.projectOr());
    final agents = app.agents
        .where((a) => a.projectId != null && a.kind != AgentKind.subagent)
        .toList();
    final own = cells.where((x) => x.own).toList();
    final pid = desk.projectOr();
    final left = ListView(
      children: [
        SideHead(l.deskAgentsTerminals, count: agents.length),
        for (final a in agents)
          _AgentRow(
            agent: a,
            shown: cells.any((x) => x.agentId == a.id),
            onTap: () {
              final cell = cells.where((x) => x.agentId == a.id).firstOrNull;
              if (cell != null) {
                _remove(cell);
              } else {
                _add(TermCell.agent(a.id, a.projectId!));
              }
            },
          ),
        SideHead(l.deskYourTerminals, count: own.length),
        for (final x in own)
          ListTile(
            dense: true,
            leading: RgIcon(RgIcons.terminal, size: 16, color: c.accent),
            title: Text(app.projects.where((p) => p.id == x.projectId).firstOrNull?.name ?? ''),
            subtitle: Text(l.deskInContainer),
          ),
        if (pid != null)
          TextButton.icon(
            key: const Key('term-new'),
            onPressed: () => _add(TermCell.own(pid)),
            icon: RgIcon(RgIcons.plus, size: 15, color: c.accent),
            label: Text(l.deskNewTerminal),
          ),
      ],
    );
    final toolbar = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Segmented(
            key: const Key('term-layout'),
            options: [l.deskGrid, l.deskTabs],
            icons: const [RgIcons.square, RgIcons.list],
            selected: _tabs ? 1 : 0,
            onSelect: (i) => setState(() => _tabs = i == 1),
          ),
          const SizedBox(width: 12),
          Text(l.deskTerminalsShown(cells.length), style: TextStyle(color: c.dim, fontSize: 12.5)),
          const Spacer(),
          const ProjectPicker(),
        ],
      ),
    );
    Widget area;
    if (cells.isEmpty) {
      area = EmptyState(icon: RgIcons.terminal, text: l.deskNoTerminals);
    } else if (_tabs) {
      final i = _tab.clamp(0, cells.length - 1);
      area = Column(
        children: [
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (j, x) in cells.indexed)
                  InkWell(
                    onTap: () => setState(() => _tab = j),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: j == i ? c.accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        _title(app, l, x),
                        style: TextStyle(fontSize: 13, color: j == i ? c.text : c.dim),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _Cell(key: ValueKey(cells[i].key), cell: cells[i], onClose: () => _remove(cells[i])),
            ),
          ),
        ],
      );
    } else {
      area = LayoutBuilder(
        builder: (context, box) {
          final cols = cells.length == 1 ? 1 : (box.maxWidth >= 1100 && cells.length > 4 ? 3 : 2);
          final rows = (cells.length / cols).ceil();
          final h = ((box.maxHeight - 8) / rows).clamp(220.0, 2000.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final x in cells)
                  SizedBox(
                    width: (box.maxWidth - 16 - (cols - 1) * 8) / cols,
                    height: h - 8,
                    child: _Cell(key: ValueKey(x.key), cell: x, onClose: () => _remove(x)),
                  ),
              ],
            ),
          );
        },
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 240,
          decoration: BoxDecoration(border: Border(right: BorderSide(color: c.line))),
          child: left,
        ),
        Expanded(
          child: Column(
            children: [
              toolbar,
              Divider(height: 1, color: c.line),
              Expanded(child: area),
            ],
          ),
        ),
      ],
    );
  }
}

String _title(AppController app, AppLocalizations l, TermCell x) => x.own
    ? l.deskYourTerminal
    : app.agents.where((a) => a.id == x.agentId).firstOrNull?.name ?? '';

class _AgentRow extends StatelessWidget {
  const _AgentRow({required this.agent, required this.shown, required this.onTap});

  final Agent agent;
  final bool shown;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final state = app.live.mascotStateOf(agent.id);
    final project = app.projects.where((p) => p.id == agent.projectId).firstOrNull?.name ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: shown ? c.panel2 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: Key('term-agent-row-${agent.id}'),
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                MascotView(
                  agentId: agent.id,
                  spec: agent.mascot,
                  state: state,
                  size: 28,
                  label: l.mascotLabel(agent.name, stateWord(l, state)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agent.name, style: TextStyle(fontSize: 13, color: c.text)),
                      Text(
                        project,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: c.dim),
                      ),
                    ],
                  ),
                ),
                RgIcon(RgIcons.lock, size: 14, color: c.dim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({super.key, required this.cell, required this.onClose});

  final TermCell cell;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = app.projects.where((x) => x.id == cell.projectId).firstOrNull;
    final a = app.agents.where((x) => x.id == cell.agentId).firstOrNull;
    if (p == null) return const NoProject();
    final ctx = deskCtx(app, p);
    final state = a == null ? MascotState.idle : app.live.mascotStateOf(a.id);
    return Container(
      key: Key('term-cell-${cell.own ? 'own-${cell.projectId}' : cell.agentId}'),
      decoration: BoxDecoration(
        color: const Color(0xFF120F10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cell.own ? c.accentDim : c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: c.panel,
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
            child: Row(
              children: [
                if (a != null)
                  MascotView(
                    agentId: a.id,
                    spec: a.mascot,
                    state: state,
                    size: 30,
                    label: l.mascotLabel(a.name, stateWord(l, state)),
                  )
                else
                  RgIcon(RgIcons.terminal, size: 20, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a?.name ?? l.deskYourTerminal,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text),
                      ),
                      Text(
                        a == null ? '${p.name} · ${l.deskInContainer}' : '${stateWord(l, state)} · ${p.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: c.dim),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: a == null ? c.accentDim : c.line),
                    color: a == null ? c.accentSoft : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a != null) ...[
                        RgIcon(RgIcons.lock, size: 11, color: c.dim),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        a == null ? l.deskYouWrite : l.deskReadOnly,
                        style: TextStyle(fontSize: 11.5, color: a == null ? c.accent : c.dim),
                      ),
                    ],
                  ),
                ),
                if (a != null)
                  IconButton(
                    tooltip: l.deskAskInConversation,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => desk.openAgent(a),
                    icon: RgIcon(RgIcons.chat, size: 16, color: c.dim),
                  ),
                IconButton(
                  key: Key('term-close-${cell.key}'),
                  tooltip: l.deskClose,
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: RgIcon(RgIcons.x, size: 15, color: c.dim),
                ),
              ],
            ),
          ),
          Expanded(
            child: a != null
                ? AgentCommands(
                    ctx: ctx,
                    agentId: a.id,
                    font: 12.5,
                    compact: true,
                    every: const Duration(seconds: 8),
                  )
                : OwnShell(
                    ctx: ctx,
                    font: 12.5,
                    compact: true,
                    autoOpen: true,
                    command: cell.command,
                  ),
          ),
          Container(
            color: c.panel,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                RgIcon(a == null ? RgIcons.shield : RgIcons.alert, size: 12, color: c.dim),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    a == null ? l.deskNoKeysHere : l.deskTermAskHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: c.dim),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
