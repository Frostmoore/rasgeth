// Projects (G40.11; G42.5: in the bar for everyone, as the page's projects): every project with
// its lead and what it is doing, its subprojects and, with the advanced interface, its git state
// (branch, changes, commits ahead and behind); a tap opens the project. «New project» is the
// page's own (the name, then its orchestrator), and Settings › Projects and › Code are one tap
// away (archive, restore, initialise git; where the code lives).
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/code.dart';
import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import '../ui/project_menu.dart';
import '../ui/words.dart';
import '../desktop/new_project.dart';
import '../settings/projects_settings.dart';
import 'code/git_tab.dart' show AheadBehind;

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Project>? _projects;
  final _git = <String, GitState>{};
  final _open = <String, int>{};
  bool _failed = false;

  int? _version;

  // Its own copy of the projects (with git and tasks): read again whenever the app read the
  // projects again (p3.8.9: one made, archived or merged elsewhere), the first time included.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    // The advanced interface switched on: the git state too.
    final v = app.projectsVersion * 2 + (app.advanced ? 1 : 0);
    if (v == _version) return;
    _version = v;
    unawaited(_load());
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    final c = app.client;
    if (c == null) {
      // No RedGiant yet: nothing to wait for.
      // (Called from didChangeDependencies: the build that follows shows it.)
      _projects ??= const [];
      return;
    }
    final advanced = app.advanced;
    try {
      final list = await c.projects();
      if (!mounted) return;
      setState(() {
        _projects = list;
        _failed = false;
      });
      await Future.wait([
        for (final p in list)
          () async {
            try {
              final g = advanced ? await c.gitState(p.id) : null;
              final t = await c.tasks(p.id);
              if (!mounted) return;
              setState(() {
                if (g != null) _git[p.id] = g;
                _open[p.id] = t.where((x) => !x.done).length;
              });
            } on ApiException {
              // That project's card stays without its state.
            }
          }(),
      ]);
    } on ApiException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    // The app's own lists once loaded: an archive or a restore from the menu shows at once.
    final list = _projects == null
        ? null
        : app.projects.isEmpty && app.archivedProjects.isEmpty
        ? _projects
        : [...app.projects, ...app.archivedProjects];
    return Column(
      children: [
        ScreenHeader(
          title: l.tabProjects,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: const Key('projects-settings'),
                tooltip: l.psTitle,
                onPressed: () => unawaited(openProjectsSettings(context)),
                icon: RgIcon(RgIcons.settings, size: 20, color: RgColors.of(context).dim),
              ),
              const SizedBox(width: 4),
              FilledButton.icon(
                key: const Key('projects-new'),
                onPressed: () async {
                  final made = await openNewProject(context);
                  if (made != null) await _load();
                },
                icon: const RgIcon(RgIcons.plus, size: 16, color: Colors.white),
                label: Text(l.psNewProject),
              ),
            ],
          ),
        ),
        Expanded(
          child: list == null
              ? (_failed
                    ? EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed)
                    : const Center(child: CircularProgressIndicator()))
              : list.isEmpty
              ? EmptyState(icon: RgIcons.folder, text: l.codeNoProjects)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    key: const Key('projects-list'),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final p in list)
                        _ProjectCard(project: p, git: _git[p.id], open: _open[p.id]),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, this.git, this.open});

  final Project project;
  final GitState? git;
  final int? open;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lead = app.agents
        .where(
          (a) =>
              a.projectId == project.id &&
              a.kind == AgentKind.orchestrator &&
              a.subprojectId == null,
        )
        .firstOrNull;
    final subs = app.subprojectsOf(project.id);
    final state = lead == null ? null : app.live.mascotStateOf(lead.id);
    final g = git;
    final who = [
      if (lead != null) lead.name,
      if (project.archived)
        l.codeArchivedShort
      else if (state == MascotState.error)
        stateWord(l, state!)
      else if (open != null)
        open == 0 ? l.codeNoOpenTasks : l.codeOpenTasks(open!),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          key: Key('project-${project.id}'),
          borderRadius: BorderRadius.circular(16),
          // 3.8.8: the project's conversations (and, archived, its tasks); its tasks and files from
          // the menu (long press), with «Archive» and «Restore».
          onTap: () => openProject(context, project),
          onLongPress: () => showProjectMenu(context, project),
          onSecondaryTapUp: (d) => showProjectMenu(context, project, at: d.globalPosition),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.text),
                      ),
                    ),
                    if (project.archived) RgIcon(RgIcons.lock, size: 16, color: c.dim),
                  ],
                ),
                if (who.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      who,
                      style: TextStyle(
                        color: state == MascotState.error ? c.err : c.dim,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (subs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      key: Key('project-subs-${project.id}'),
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final x in subs)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: c.accentSoft,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                RgIcon(RgIcons.box, size: 12, color: c.accent),
                                const SizedBox(width: 4),
                                Text(
                                  x.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: c.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                if (project.git == false && !project.archived)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l.pmNoGit,
                      key: Key('project-nogit-${project.id}'),
                      style: TextStyle(color: c.warnText, fontSize: 12.5),
                    ),
                  ),
                if (app.advanced) const SizedBox(height: 8),
                if (!app.advanced)
                  const SizedBox.shrink()
                else if (g == null)
                  const SizedBox(height: 18)
                else if (!g.repo)
                  Text(l.codeNoRepo, style: TextStyle(color: c.dim, fontSize: 12.5))
                else
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.panel2,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RgIcon(RgIcons.gitBranch, size: 13, color: c.dim),
                            const SizedBox(width: 4),
                            Text(
                              g.branch ?? l.codeDetached,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: c.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          g.clean ? l.codeClean : l.codeChanges(g.changes.length),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: g.clean ? c.dim : c.warnText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      AheadBehind(ahead: g.ahead, behind: g.behind),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
