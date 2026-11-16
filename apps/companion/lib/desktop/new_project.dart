// «New project» in the control room, the page's own flow (`Sidebar.tsx` `create`): the name in our
// dialog, `POST /api/projects`, then its orchestrator under God (`POST /api/agents`, named as the
// project) and the lists read again. A project without its git repository says so, never silently.
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../ui/dialogs.dart';

/// What the person reads once a project is made: the git notice when the folder has no
/// repository, else that it is there with its orchestrator.
String madeNotice(AppLocalizations l, Project p) {
  if (p.git != false) return l.deskProjectMade(p.name);
  final why = p.gitError ?? '';
  return l.deskProjectNoGit(p.name, why.contains('not installed') ? l.deskGitMissing : why);
}

/// Asks the name and makes the project with its orchestrator; null when the person gave up or it
/// failed (a snack bar says why).
Future<Project?> openNewProject(BuildContext context) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final name = (await askText(
    context,
    title: l.deskNewProject,
    hint: l.deskProjectName,
    yes: l.deskProjectCreate,
    fieldKey: const Key('new-project-name'),
  ))?.trim();
  final c = app.client;
  if (name == null || name.isEmpty || c == null) return null;
  final Project project;
  try {
    project = await c.createProject(name);
  } on ApiException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l.deskProjectFailed(e.message))));
    return null;
  }
  // Every project gets its orchestrator under God, as on the page.
  String? orchestratorFailed;
  if (app.god case final god?) {
    try {
      await c.createAgent(
        kind: 'orchestrator',
        parentId: god.id,
        projectId: project.id,
        name: project.name,
      );
    } on ApiException catch (e) {
      orchestratorFailed = e.message;
    }
  }
  await app.refresh();
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        orchestratorFailed != null ? l.newAgentFailed(orchestratorFailed) : madeNotice(l, project),
      ),
    ),
  );
  return project;
}
