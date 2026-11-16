// A project in the advanced interface (G40.11): its tabs side by side, swiped left and right
// (Tasks, Files, Diff, Terminal, Log, Git), with the branch and the changes under its name. On a
// tablet held sideways two panels: tree and file, diff and chat.
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/conversation.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import 'diff_tab.dart';
import 'files_tab.dart';
import 'git_tab.dart';
import 'log_tab.dart';
import 'tasks_tab.dart';
import 'terminal_tab.dart';

enum ProjectTab { tasks, files, diff, terminal, log, git }

/// What every tab of a project shares: the project, its agents, the way to another tab.
class ProjectCtx {
  const ProjectCtx({
    required this.project,
    required this.app,
    required this.openDiff,
    required this.openTab,
    required this.wide,
    required this.reloadGit,
    this.git,
  });

  final Project project;
  final AppController app;
  final void Function(DiffSource source, {String? file}) openDiff;
  final void Function(ProjectTab tab) openTab;

  /// A tablet held sideways: two panels.
  final bool wide;
  final GitState? git;
  final Future<void> Function() reloadGit;

  RedGiantClient get client => app.client!;
  String get scope => 'project:${project.id}';
  bool get readOnly => project.archived;

  List<Agent> get agents => [
    for (final a in app.agents)
      if (a.projectId == project.id && a.kind != AgentKind.subagent) a,
  ];

  /// Who reads a comment when the diff names nobody: the project's orchestrator, or God.
  Agent? get lead =>
      agents.where((a) => a.kind == AgentKind.orchestrator).firstOrNull ??
      agents.firstOrNull ??
      app.god;

  Agent? agentById(String? id) => app.agents.where((a) => a.id == id).firstOrNull;

  /// The latest conversation of [agentId] (the chat next to its diff, its commands).
  String? latestSessionOf(String? agentId) {
    final rows = app.live.sessions.where((s) => s.agentId == agentId && !s.archived).toList()
      ..sort((x, y) => y.when.compareTo(x.when));
    return rows.firstOrNull?.id;
  }
}

/// A short note at the bottom, in place of the one showing (never a queue of old ones).
void say(BuildContext context, String text) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(text)));

/// The error of a request, in the person's words.
void showApiError(BuildContext context, Object e) {
  final l = AppLocalizations.of(context);
  final text = switch (e) {
    ApiException(status: 423) => l.codeArchived,
    ApiException(status: 409) => l.codeChangedMeanwhile,
    ApiException(unreachable: true) => l.codeUnreachable,
    ApiException(:final message) => message,
    _ => '$e',
  };
  say(context, text);
}

String tabLabel(AppLocalizations l, ProjectTab t) => switch (t) {
  ProjectTab.tasks => l.codeTabTasks,
  ProjectTab.files => l.codeTabFiles,
  ProjectTab.diff => l.codeTabDiff,
  ProjectTab.terminal => l.codeTabTerminal,
  ProjectTab.log => l.codeTabLog,
  ProjectTab.git => l.codeTabGit,
};

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({
    super.key,
    required this.project,
    this.initial = ProjectTab.tasks,
    this.agentId,
  });

  final Project project;
  final ProjectTab initial;

  /// Opened from an agent's sheet: its diff and its terminal.
  final String? agentId;

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late final PageController _pages = PageController(initialPage: widget.initial.index);
  late ProjectTab _tab = widget.initial;
  late DiffSource _diff = widget.agentId == null
      ? const DiffSource.working()
      : DiffSource.agent(widget.agentId!);
  String? _diffFile;
  GitState? _git;
  final _tabKeys = {for (final t in ProjectTab.values) t: GlobalKey()};

  @override
  void initState() {
    super.initState();
    _reloadGit();
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _reloadGit() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final g = await c.gitState(widget.project.id);
      if (mounted) setState(() => _git = g);
    } on ApiException {
      // The header stays without the branch.
    }
  }

  void _open(ProjectTab t) {
    setState(() => _tab = t);
    _pages.animateToPage(
      t.index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
    final ctx = _tabKeys[t]?.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final ctx = ProjectCtx(
      project: widget.project,
      app: app,
      wide: size.width >= 900 && size.width > size.height,
      git: _git,
      reloadGit: _reloadGit,
      openTab: _open,
      openDiff: (s, {file}) {
        setState(() {
          _diff = s;
          _diffFile = file;
        });
        _open(ProjectTab.diff);
      },
    );
    final g = _git;
    final sub = g == null
        ? null
        : !g.repo
        ? l.codeNoRepo
        : '${g.branch ?? l.codeDetached} · ${g.clean ? l.codeClean : l.codeChanges(g.changes.length)}';
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.project.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            if (sub != null)
              Row(
                children: [
                  RgIcon(RgIcons.gitBranch, size: 13, color: c.dim),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      sub,
                      key: const Key('project-git-line'),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.dim),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.project.archived)
            Container(
              width: double.infinity,
              color: c.panel2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  RgIcon(RgIcons.lock, size: 16, color: c.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.codeArchived, style: TextStyle(color: c.dim)),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            key: const Key('project-tabs'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: Row(
              children: [
                for (final t in ProjectTab.values)
                  Padding(
                    key: _tabKeys[t],
                    padding: const EdgeInsets.only(right: 6),
                    child: _TabChip(
                      key: Key('ptab-${t.name}'),
                      label: tabLabel(l, t),
                      selected: _tab == t,
                      onTap: () => _open(t),
                    ),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _tab = ProjectTab.values[i]),
              children: [
                TasksTab(ctx: ctx),
                FilesTab(ctx: ctx),
                DiffTab(
                  key: ValueKey((_diff, _diffFile)),
                  ctx: ctx,
                  source: _diff,
                  startFile: _diffFile,
                ),
                TerminalTab(ctx: ctx, startAgent: widget.agentId),
                LogTab(ctx: ctx, startAgent: widget.agentId),
                GitTab(ctx: ctx),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? c.accentSoft : c.panel2,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.accentDim : Colors.transparent)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: selected ? c.accent : c.dim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chip that filters or chooses (Log, Diff, Terminal): our own, drawn.
class PickChip extends StatelessWidget {
  const PickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final RgIcons? icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final fg = selected ? (danger ? c.err : c.accent) : c.text;
    return Material(
      color: selected ? (danger ? c.criticalSoft : c.accentSoft) : c.panel,
      shape: StadiumBorder(side: BorderSide(color: selected ? fg.withValues(alpha: .5) : c.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[RgIcon(icon!, size: 14, color: fg), const SizedBox(width: 5)],
              Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A list of choices in our sheet (never a system menu).
Future<T?> pickFrom<T>(
  BuildContext context, {
  required String title,
  required List<(T, String, String?)> options,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (context) {
    final c = RgColors.of(context);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .7),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            for (final (value, label, sub) in options)
              ListTile(
                key: Key('pick-$label'),
                title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: sub == null
                    ? null
                    : Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.dim),
                      ),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
  },
);

/// The time of an ISO date, local, as 9:31:02.
String clockOf(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.hour}:${two(d.minute)}:${two(d.second)}';
}
