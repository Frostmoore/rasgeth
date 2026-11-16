// What the advanced views share on computers (G40.17): the project they look at (chosen at the
// top of each, the same for all), a `ProjectCtx` for the phone's tabs reused as they are, and the
// commit and the push, which the menus can start from anywhere.
import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/conversation.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/code/project_screen.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../desk_controller.dart';

/// The project an advanced view shows, or null when there is none.
Project? deskProject(AppController app, DeskController desk) {
  final id = desk.projectOr();
  return app.projects.where((p) => p.id == id).firstOrNull;
}

/// The phone's tabs' context, for a project on a computer.
ProjectCtx deskCtx(
  AppController app,
  Project p, {
  GitState? git,
  Future<void> Function()? reloadGit,
  void Function(DiffSource source, {String? file})? openDiff,
  void Function(ProjectTab tab)? openTab,
}) => ProjectCtx(
  project: p,
  app: app,
  wide: false,
  git: git,
  reloadGit: reloadGit ?? () async {},
  openDiff: openDiff ?? (_, {file}) {},
  openTab: openTab ?? (_) {},
);

/// «Make a commit…»: the message asked in our dialog, then everything in the working tree.
Future<void> commitInProject(BuildContext context, AppController app, String projectId) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final m = await askText(context, title: l.deskGitCommitTitle, yes: l.codeCommit);
  if (m == null || m.trim().isEmpty) return;
  try {
    final h = await app.client!.gitCommit(projectId, m.trim());
    messenger?.showSnackBar(SnackBar(content: Text(l.codeCommitted(h))));
  } on ApiException catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(e.code == 'nothing' ? l.codeNothingToCommit : e.message)),
    );
  }
}

/// «Send…»: the push is a request to the person, answered from «For you» like an agent's.
Future<void> pushProject(BuildContext context, AppController app, String projectId) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await app.client!.gitPush(projectId);
    messenger?.showSnackBar(SnackBar(content: Text(l.deskPushAsked)));
  } on ApiException catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(e.code == 'no_remote' ? l.codeNoRemote : e.message)),
    );
  }
}

/// The project's name with a menu of the others (the advanced views' top left).
class ProjectPicker extends StatelessWidget {
  const ProjectPicker({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final p = deskProject(app, desk);
    final projects = app.projects.where((x) => !x.archived).toList();
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(c.panel),
        side: WidgetStatePropertyAll(BorderSide(color: c.line)),
      ),
      menuChildren: [
        for (final x in projects)
          MenuItemButton(
            key: Key('pick-project-${x.id}'),
            leadingIcon: RgIcon(RgIcons.folder, size: 15, color: c.dim),
            onPressed: () => desk.setProject(x.id),
            child: Text(x.name),
          ),
      ],
      builder: (context, ctl, _) => InkWell(
        key: const Key('desk-project-picker'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => ctl.isOpen ? ctl.close() : ctl.open(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RgIcon(RgIcons.folder, size: 17, color: c.text),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  p?.name ?? l.deskNoProjects,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.text),
                ),
              ),
              const SizedBox(width: 4),
              RgIcon(RgIcons.chevronDown, size: 15, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section's title in the advanced views' side columns.
class SideHead extends StatelessWidget {
  const SideHead(this.text, {super.key, this.count});

  final String text;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
                fontSize: 11.5,
                letterSpacing: .6,
                fontWeight: FontWeight.w700,
                color: c.dim,
              ),
            ),
          ),
          if (count != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: c.panel2,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('$count', style: TextStyle(fontSize: 11, color: c.dim)),
            ),
        ],
      ),
    );
  }
}

/// No project yet: the advanced views say so.
class NoProject extends StatelessWidget {
  const NoProject({super.key});

  @override
  Widget build(BuildContext context) =>
      EmptyState(icon: RgIcons.folder, text: AppLocalizations.of(context).deskNoProjects);
}
