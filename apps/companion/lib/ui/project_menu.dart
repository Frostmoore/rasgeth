// A project's menu (3.8.8): right click on a computer, long press on a phone, wherever a project
// shows. The page's project row (Sidebar.tsx: the name opens it, «Agents of…», «Archive the
// project»), its archived list («Restore») and Settings › Projects («Initialise git»), with the
// same routes and the same window before archiving (ProjectArchive.tsx `ArchiveProjectDialog`:
// who is working, the automations that pause, what happens; never a system prompt).
import 'package:flutter/material.dart';

import '../api/conversation.dart';
import '../app_state.dart';
import '../desktop/desk_controller.dart';
import '../l10n/app_localizations.dart';
import '../screens/code/project_screen.dart';
import '../screens/project_overview_screen.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'icons.dart';
import 'project_agents.dart';
import 'rg_menu.dart';

/// Right click or long press on a project.
class ProjectPress extends StatelessWidget {
  const ProjectPress({
    super.key,
    required this.project,
    required this.child,
    this.longPress = true,
  });

  final Project project;
  final Widget child;
  final bool longPress;

  @override
  Widget build(BuildContext context) => RgPress(
    longPress: longPress,
    onMenu: (at) => showProjectMenu(context, project, at: at),
    child: child,
  );
}

enum _P { open, code, tasks, agents, limit, git, archive, restore }

/// [p]'s menu: at [at] on a computer, the sheet without it.
Future<void> showProjectMenu(BuildContext context, Project p, {Offset? at}) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final c = RgColors.of(context);
  final desk = DeskScope.maybeRead(context);
  final entries = <RgMenuEntry<_P>?>[
    RgMenuEntry(_P.open, RgIcons.chat, l.pmOpen, key: const Key('proj-menu-open')),
    if (desk != null && app.advanced && !p.archived)
      RgMenuEntry(_P.code, RgIcons.code, l.pmCode, key: const Key('proj-menu-code')),
    if (desk == null)
      RgMenuEntry(_P.tasks, RgIcons.board, l.pmTasks, key: const Key('proj-menu-tasks')),
    if (!p.archived)
      RgMenuEntry(_P.agents, RgIcons.users, l.pmAgents(p.name), key: const Key('proj-menu-agents')),
    // How many agents it may have besides its orchestrator (2026-11-18).
    if (!p.archived)
      RgMenuEntry(
        _P.limit,
        RgIcons.users,
        l.pmAgentLimit(p.maxAgents == 0 ? l.palZero : '${p.maxAgents}'),
        key: const Key('proj-menu-limit'),
      ),
    if (p.git == false && !p.archived)
      RgMenuEntry(_P.git, RgIcons.gitBranch, l.pmInitGit, key: const Key('proj-menu-git')),
    null,
    if (p.archived)
      RgMenuEntry(_P.restore, RgIcons.restore, l.pmRestore, key: const Key('proj-menu-restore'))
    else
      RgMenuEntry(_P.archive, RgIcons.archive, l.pmArchive, key: const Key('proj-menu-archive')),
  ];
  final pick = at != null
      ? await showRgMenu(context, at, entries)
      : await showRgSheet(
          context,
          key: Key('proj-sheet-${p.id}'),
          head: RgSheetHead(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: RgIcon(p.archived ? RgIcons.archive : RgIcons.folder, size: 20, color: c.dim),
            ),
            title: p.name,
            subtitle: p.archived ? l.pmBadge : null,
          ),
          entries: entries,
        );
  if (pick == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  void say(String text) => messenger?.showSnackBar(SnackBar(content: Text(text)));
  switch (pick) {
    case _P.open:
      await openProject(context, p);
    case _P.code:
      // The code view wants the room: the project's panel gives way to it.
      if (desk!.panel is PanelProject) desk.closePanel();
      desk
        ..setProject(p.id)
        ..setView(DeskView.code);
    case _P.tasks:
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => ProjectScreen(project: p)));
    case _P.agents:
      app.setTeamFilter(p.id);
      if (desk != null) {
        desk
          ..setByProject(true)
          ..setView(DeskView.team);
      } else {
        app.setTab(AppTab.team);
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    case _P.limit:
      await askProjectAgentLimit(context, p);
    case _P.git:
      say(await app.initProjectGit(p.id) ? l.pmInitGitDone(p.name) : l.cmFailed);
    case _P.archive:
      if (await askArchiveProject(context, p)) say(l.pmArchived(p.name));
    case _P.restore:
      say(await app.restoreProject(p.id) ? l.pmRestored(p.name) : l.cmFailed);
  }
}

/// A project: in the control room's panel, else the whole screen.
Future<void> openProject(BuildContext context, Project p) async {
  final desk = DeskScope.maybeRead(context);
  if (desk != null) {
    desk.showProject(p.id);
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => ProjectOverviewScreen(projectId: p.id)));
}

/// «Archive»: first who is working and which automations will pause, then the person's yes in our
/// window. True when it was archived.
Future<bool> askArchiveProject(BuildContext context, Project p) async {
  final yes = await showRgWindow<bool>(
    context: context,
    builder: (_) => _ArchiveWindow(project: p),
  );
  return yes ?? false;
}

class _ArchiveWindow extends StatefulWidget {
  const _ArchiveWindow({required this.project});

  final Project project;

  @override
  State<_ArchiveWindow> createState() => _ArchiveWindowState();
}

class _ArchiveWindowState extends State<_ArchiveWindow> {
  ProjectWork? _work;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    AppScope.read(context).projectWork(widget.project.id).then((w) {
      if (!mounted) return;
      setState(() {
        _work = w;
        if (w == null) _error = AppLocalizations.of(context).cmFailed;
      });
    });
  }

  Future<void> _archive() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await AppScope.read(context).archiveProject(widget.project.id);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final w = _work;
    final n = w?.working.length ?? 0;
    final autos = w?.automations ?? const <String>[];
    Widget fact(String t) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RgIcon(RgIcons.check, size: 14, color: c.dim),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(t, style: TextStyle(color: c.text, fontSize: 13.5)),
          ),
        ],
      ),
    );
    return AlertDialog(
      key: const Key('proj-archive-window'),
      icon: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(13)),
          alignment: Alignment.center,
          child: RgIcon(RgIcons.archive, size: 22, color: c.accent),
        ),
      ),
      title: Text(l.pmAskTitle(widget.project.name)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.pmAskLead, style: TextStyle(color: c.dim, fontSize: 14)),
              const SizedBox(height: 12),
              if (w == null && _error == null) Text(l.loading, style: TextStyle(color: c.dim)),
              if (w != null)
                n > 0
                    ? Container(
                        key: const Key('proj-archive-working'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.warn.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.warn.withValues(alpha: .5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.pmWorking(n),
                              style: TextStyle(fontWeight: FontWeight.w700, color: c.warnText),
                            ),
                            for (final x in w.working)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  [x.agentName, ?x.title].join(' · '),
                                  style: TextStyle(color: c.text, fontSize: 13.5),
                                ),
                              ),
                          ],
                        ),
                      )
                    : Text(l.pmNobody, style: TextStyle(color: c.text)),
              if (autos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    l.pmAutos(autos.length, autos.join(', ')),
                    style: TextStyle(color: c.text, fontSize: 13.5),
                  ),
                ),
              const SizedBox(height: 8),
              fact(l.pmFactTasks),
              fact(l.pmFactSandbox),
              fact(l.pmFactNobody),
              fact(l.pmFactRestore),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: TextStyle(color: c.err)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('dialog-no'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('proj-archive-yes'),
          onPressed: _busy || w == null ? null : _archive,
          child: Text(n > 0 ? l.pmStopAndArchive : l.pmArchiveYes),
        ),
      ],
    );
  }
}
