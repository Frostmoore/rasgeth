// Settings › Projects (G42.5), the page's `ProjectsPage` (ProjectArchive.tsx): the projects in
// use with their folder, the «No git repository» pill with «Initialise git», «Archive» (the same
// window as the project's menu: who works, the automations that pause); then the archived ones,
// read only, with «Restore». At the bottom, where the code lives (Settings › Code). The same
// routes as the page.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/highlight.dart' show monoFallback, monoFamily;
import '../ui/icons.dart';
import '../ui/project_menu.dart';
import '../ui/settings_kit.dart';
import 'code_settings.dart';

Future<void> openProjectsSettings(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ProjectsSettingsScreen()));

class ProjectsSettingsScreen extends StatefulWidget {
  const ProjectsSettingsScreen({super.key});

  @override
  State<ProjectsSettingsScreen> createState() => _ProjectsSettingsScreenState();
}

class _ProjectsSettingsScreenState extends State<ProjectsSettingsScreen> {
  String? _busy;
  String? _done;
  bool _failed = false;

  Future<void> _initGit(String id, String name) async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = id;
      _done = null;
    });
    final ok = await app.initProjectGit(id);
    if (!mounted) return;
    setState(() {
      _busy = null;
      _failed = !ok;
      _done = ok ? l.pmInitGitDone(name) : l.cmFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 12,
      color: c.dim,
    );
    Widget pill(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.warnText.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.warnText.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(RgIcons.gitBranch, size: 12, color: c.warnText),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: c.warnText, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return SettingsScaffold(
      title: l.psTitle,
      backKey: const Key('ps-back'),
      backLabel: l.back,
      listKey: const Key('ps-list'),
      children: [
        NoteLine(icon: RgIcons.info, text: l.psLead),
        if (_done != null) NoticeBanner(key: const Key('ps-notice'), text: _done!, error: _failed),
        SectionHead(l.psInUse),
        SettingsCard(
          children: [
            if (app.projects.isEmpty) NoteLine(icon: RgIcons.box, text: l.psNone),
            for (final (i, p) in app.projects.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              Padding(
                key: Key('ps-project-${p.id}'),
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        RgIcon(RgIcons.box, size: 17, color: c.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: c.text,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((p.path ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3, left: 25),
                        child: SelectableText(p.path!, style: mono),
                      ),
                    if (p.git == false)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 25),
                        child: pill(l.pmNoGit),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 17),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (p.git == false)
                            OutlinedButton.icon(
                              key: Key('ps-git-${p.id}'),
                              onPressed: _busy == p.id ? null : () => _initGit(p.id, p.name),
                              icon: RgIcon(RgIcons.gitBranch, size: 16, color: c.accent),
                              label: Text(l.pmInitGit),
                            ),
                          OutlinedButton.icon(
                            key: Key('ps-archive-${p.id}'),
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.maybeOf(context);
                              if (await askArchiveProject(context, p)) {
                                messenger?.showSnackBar(
                                  SnackBar(content: Text(l.pmArchived(p.name))),
                                );
                              }
                            },
                            icon: RgIcon(RgIcons.archive, size: 16, color: c.dim),
                            label: Text(l.pmArchive),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        SectionHead(l.psArchived),
        NoteLine(icon: RgIcons.lock, text: l.psArchivedLead),
        SettingsCard(
          children: [
            if (app.archivedProjects.isEmpty)
              NoteLine(icon: RgIcons.archive, text: l.psNoneArchived),
            for (final (i, p) in app.archivedProjects.indexed) ...[
              if (i > 0) Divider(height: 1, color: c.line),
              ListTile(
                key: Key('ps-archived-${p.id}'),
                leading: RgIcon(RgIcons.archive, color: c.dim),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: () {
                  final day = DateTime.tryParse(p.archivedAt ?? '')?.toLocal();
                  return day == null
                      ? null
                      : Text(l.pmArchivedOn(DateFormat.yMMMd(l.localeName).format(day)));
                }(),
                trailing: TextButton.icon(
                  key: Key('ps-restore-${p.id}'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    final ok = await app.restoreProject(p.id);
                    messenger?.showSnackBar(
                      SnackBar(content: Text(ok ? l.pmRestored(p.name) : l.cmFailed)),
                    );
                  },
                  icon: RgIcon(RgIcons.restore, size: 16, color: c.accent),
                  label: Text(l.pmRestore),
                ),
              ),
            ],
          ],
        ),
        SectionHead(l.csEyebrow),
        SettingsCard(
          children: [
            ListTile(
              key: const Key('ps-code'),
              leading: RgIcon(RgIcons.gitBranch, color: c.accent),
              title: Text(l.csTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(l.csRowHint),
              trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
              onTap: () => unawaited(openCodeSettings(context)),
            ),
          ],
        ),
      ],
    );
  }
}
