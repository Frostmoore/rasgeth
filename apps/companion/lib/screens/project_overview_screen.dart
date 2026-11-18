// A project (3.8.8): what the page shows for it. In use, its lead's conversations (pinned, the
// latest, folders, «Archived (n)», «New conversation») and the team's conversations (the page's
// `Sessions` and `TeamSessions`); archived (ProjectArchive.tsx `ArchivedProjectView`), read only:
// the badge, «Restore», every conversation and the tasks. In the control room's panel on a
// computer, the whole screen on a phone; the head has the project's menu.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import '../ui/project_agents.dart';
import '../ui/project_menu.dart';
import 'activity_screen.dart' show outcomeWord;
import 'agent_conversations_screen.dart';

/// The project's head: its name, its lead or the archived badge, its menu.
class ProjectHead extends StatelessWidget {
  const ProjectHead({super.key, required this.project, this.trailing = const []});

  final Project project;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = project;
    final day = DateTime.tryParse(p.archivedAt ?? '')?.toLocal();
    return ProjectPress(
      project: p,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.archived ? c.panel2 : c.accentSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: RgIcon(
              p.archived ? RgIcons.archive : RgIcons.folder,
              size: 19,
              color: p.archived ? c.dim : c.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.text),
                ),
                if (p.archived)
                  Text(
                    day == null
                        ? l.pmBadge
                        : '${l.pmBadge} · ${l.pmArchivedOn(DateFormat.yMMMd(l.localeName).format(day))}',
                    key: const Key('proj-badge'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.dim),
                  )
                else if (p.git == false)
                  Text(l.pmNoGit, style: TextStyle(fontSize: 12.5, color: c.warnText)),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// The body: the lead's list with the team's under it, or the archived project's view.
class ProjectOverview extends StatefulWidget {
  const ProjectOverview({super.key, required this.projectId});

  final String projectId;

  @override
  State<ProjectOverview> createState() => _ProjectOverviewState();
}

class _ProjectOverviewState extends State<ProjectOverview> {
  Future<List<TaskRow>>? _tasks;
  bool? _wasArchived;

  Project? _project(AppController app) =>
      app.projects.where((p) => p.id == widget.projectId).firstOrNull ??
      app.archivedProjects.where((p) => p.id == widget.projectId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = _project(app);
    if (p == null) return EmptyState(icon: RgIcons.folder, text: l.codeNoProjects);
    if (p.archived != _wasArchived) {
      _wasArchived = p.archived;
      _tasks = p.archived ? app.client?.tasks(p.id).catchError((_) => <TaskRow>[]) : null;
    }
    final team = app.agents.where((a) => a.projectId == p.id).toList();
    final lead = team.where((a) => a.kind == AgentKind.orchestrator).firstOrNull;
    final ids = {for (final a in team) a.id};
    Agent? agentOf(String id) => app.agents.where((a) => a.id == id).firstOrNull;
    final restore = p.archived
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              key: const Key('proj-archived-note'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.panel2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  RgIcon(RgIcons.lock, size: 17, color: c.dim),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l.pmViewLead, style: TextStyle(color: c.text, fontSize: 13.5)),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    key: const Key('proj-restore'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final ok = await app.restoreProject(p.id);
                      messenger?.showSnackBar(
                        SnackBar(content: Text(ok ? l.pmRestored(p.name) : l.cmFailed)),
                      );
                    },
                    icon: const RgIcon(RgIcons.restore, size: 16, color: Colors.white),
                    label: Text(l.pmRestore),
                  ),
                ],
              ),
            ),
          )
        : null;
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        if (p.archived) {
          final rows =
              app.live.sessions
                  .where((r) => r.projectId == p.id || ids.contains(r.agentId))
                  .toList()
                ..sort((a, b) => b.when.compareTo(a.when));
          return ListView(
            key: Key('proj-overview-${p.id}'),
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              ?restore,
              ListHeading(l.pmConversations, icon: RgIcons.chat),
              if (rows.isEmpty) _Dim(l.pmNoConversations),
              for (final r in rows) SessionTile(row: r, who: agentOf(r.agentId)),
              ListHeading(l.pmTasksTitle, icon: RgIcons.board),
              FutureBuilder<List<TaskRow>>(
                future: _tasks,
                builder: (context, snap) {
                  final tasks = snap.data;
                  if (tasks == null) return _Dim(l.loading);
                  if (tasks.isEmpty) return _Dim(l.pmNoTasks);
                  return Column(
                    children: [
                      for (final t in tasks)
                        ListTile(
                          key: Key('proj-task-${t.id}'),
                          dense: true,
                          leading: RgIcon(RgIcons.list, size: 16, color: c.dim),
                          title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(t.agentName),
                          trailing: Text(
                            outcomeWord(l, t.outcome, false),
                            style: TextStyle(fontSize: 12, color: c.dim),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        }
        final teamRows =
            app.live.sessions
                .where(
                  (r) =>
                      r.projectId == p.id &&
                      r.agentId != lead?.id &&
                      !r.archived &&
                      app.agents.any((a) => a.id == r.agentId),
                )
                .toList()
              ..sort(
                (a, b) => (a.task != null) != (b.task != null)
                    ? (a.task != null ? -1 : 1)
                    : a.running != b.running
                    ? (a.running ? -1 : 1)
                    : b.when.compareTo(a.when),
              );
        final teamPart = [
          // How many agents it may have besides its lead (2026-11-18), where its team is.
          AgentLimitTile(project: p),
          if (teamRows.isNotEmpty) ...[
            ListHeading(l.pmTeam, icon: RgIcons.users),
            for (final r in teamRows) SessionTile(row: r, who: agentOf(r.agentId)),
          ],
        ];
        if (lead == null) {
          return ListView(
            key: Key('proj-overview-${p.id}'),
            children: [_Dim(l.pmNoLead), ...teamPart],
          );
        }
        return AgentConversations(
          key: Key('proj-overview-${p.id}'),
          agent: lead,
          header: [ListHeading(lead.name, icon: RgIcons.chat)],
          footer: teamPart,
        );
      },
    );
  }
}

class _Dim extends StatelessWidget {
  const _Dim(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
    child: Text(text, style: TextStyle(color: RgColors.of(context).dim)),
  );
}

/// The phone's whole screen of a project.
class ProjectOverviewScreen extends StatelessWidget {
  const ProjectOverviewScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    final p =
        app.projects.where((x) => x.id == projectId).firstOrNull ??
        app.archivedProjects.where((x) => x.id == projectId).firstOrNull;
    return Scaffold(
      key: Key('proj-screen-$projectId'),
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          key: const Key('proj-back'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: p == null ? null : ProjectHead(project: p),
        actions: [
          if (p != null)
            IconButton(
              key: const Key('proj-more'),
              tooltip: p.name,
              onPressed: () => showProjectMenu(context, p),
              icon: RgIcon(RgIcons.more, color: c.text),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ProjectOverview(projectId: projectId),
    );
  }
}

/// The panel's head on a computer (a project there).
class ProjectPanelHead extends StatelessWidget {
  const ProjectPanelHead({super.key, required this.projectId, required this.close});

  final String projectId;
  final Widget close;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    final p =
        app.projects.where((x) => x.id == projectId).firstOrNull ??
        app.archivedProjects.where((x) => x.id == projectId).firstOrNull;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: p == null
                ? const SizedBox.shrink()
                : ProjectHead(
                    project: p,
                    trailing: [
                      Builder(
                        builder: (ctx) => IconButton(
                          key: const Key('proj-more'),
                          tooltip: p.name,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            final box = ctx.findRenderObject()! as RenderBox;
                            showProjectMenu(
                              ctx,
                              p,
                              at: box.localToGlobal(box.size.bottomLeft(Offset.zero)),
                            );
                          },
                          icon: RgIcon(RgIcons.more, size: 17, color: c.dim),
                        ),
                      ),
                    ],
                  ),
          ),
          close,
        ],
      ),
    );
  }
}
