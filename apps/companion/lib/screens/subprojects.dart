// A project's subprojects (G24.13, G42.5), as the page's `Subprojects` under a project in its bar
// (Sidebar.tsx): each one with its folder and its agents' conversations, opened and closed; its
// files open on its folder (the page's `currentScope` with `focus`). «New subproject» is the
// page's form in our window: a new one (a name, an optional folder) or an existing project
// brought in with its history (asked first, the page's words), and its own sandbox image. The
// same routes: `POST /api/projects/:id/subprojects`, `POST /api/projects/:id/adopt`,
// `PATCH /api/projects/:id/subprojects/:sub`.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'agent_conversations_screen.dart';
import 'canvas_screen.dart' show openCanvas;
import 'files/files_explorer.dart';

/// The subprojects of [project], under its conversations.
class SubprojectsSection extends StatefulWidget {
  const SubprojectsSection({super.key, required this.project});

  final Project project;

  @override
  State<SubprojectsSection> createState() => _SubprojectsSectionState();
}

class _SubprojectsSectionState extends State<SubprojectsSection> {
  final _open = <String>{};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = widget.project;
    final list = app.subprojectsOf(p.id);
    return Column(
      key: Key('subprojects-${p.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListHeading(l.spTitle, icon: RgIcons.box),
        for (final s in list) ...[
          _SubRow(
            sub: s,
            open: _open.contains(s.id),
            onTap: () =>
                setState(() => _open.contains(s.id) ? _open.remove(s.id) : _open.add(s.id)),
          ),
          if (_open.contains(s.id)) _SubTeam(project: p, sub: s),
        ],
        if (!p.archived)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('sub-new-${p.id}'),
                onPressed: () => unawaited(openNewSubproject(context, p)),
                icon: RgIcon(RgIcons.plus, size: 15, color: c.accent),
                label: Text(l.spNew),
              ),
            ),
          ),
      ],
    );
  }
}

class _SubRow extends StatelessWidget {
  const _SubRow({required this.sub, required this.open, required this.onTap});

  final Subproject sub;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final team = app.agents.where((a) => a.subprojectId == sub.id && a.active).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: Key('sub-${sub.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Semantics(
            expanded: open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: open ? .25 : 0,
                    duration: const Duration(milliseconds: 140),
                    child: RgIcon(RgIcons.chevronRight, size: 15, color: c.dim),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    child: RgIcon(RgIcons.box, size: 16, color: c.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                        ),
                        Text(
                          ['${sub.dir}/', team == 0 ? l.spNoTeam : l.spTeam(team)].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: c.dim),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: Key('sub-files-${sub.id}'),
                    tooltip: l.spFiles,
                    onPressed: () => openSubprojectFiles(context, sub),
                    icon: RgIcon(RgIcons.folder, size: 18, color: c.dim),
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

/// A subproject's agents with their conversations (the page's `sub-agent` rows).
class _SubTeam extends StatelessWidget {
  const _SubTeam({required this.project, required this.sub});

  final Project project;
  final Subproject sub;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final team = app.agents.where((a) => a.subprojectId == sub.id && a.active).toList();
    if (team.isEmpty) {
      return Padding(
        key: Key('sub-team-${sub.id}'),
        padding: const EdgeInsets.fromLTRB(58, 0, 18, 8),
        child: Text(l.spNoAgents, style: TextStyle(color: c.dim, fontSize: 13)),
      );
    }
    return ListenableBuilder(
      key: Key('sub-team-${sub.id}'),
      listenable: app.live,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final a in team) ...[
              for (final r
                  in (app.live.sessions.where((r) => r.agentId == a.id && !r.archived).toList()
                        ..sort((x, y) => y.when.compareTo(x.when)))
                      .take(5))
                SessionTile(row: r, who: a),
              if (!app.live.sessions.any((r) => r.agentId == a.id && !r.archived))
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
                  child: Text(
                    '${a.name} · ${l.pmNoConversations}',
                    style: TextStyle(color: c.dim, fontSize: 13),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The project's files, open on [sub]'s folder: a panel-sized screen everywhere (the page opens
/// its explorer there from the subproject's agents).
Future<void> openSubprojectFiles(BuildContext context, Subproject sub) {
  final app = AppScope.read(context);
  final p =
      app.projects.where((x) => x.id == sub.projectId).firstOrNull ??
      app.archivedProjects.where((x) => x.id == sub.projectId).firstOrNull;
  final place = ExplorerPlace(
    scope: 'project:${sub.projectId}',
    project: p,
    readOnly: p?.archived ?? false,
    focus: sub.dir,
  );
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => FilesScreen(
        place: place,
        onOpen: (ctx, path, name) =>
            unawaited(openCanvas(ctx, scope: place.scope, path: path, title: name)),
      ),
    ),
  );
}

/// «New subproject»: the page's form in our window; true once made (the lists read again).
Future<bool> openNewSubproject(BuildContext context, Project project) async {
  final made = await showRgWindow<bool>(
    context: context,
    builder: (_) => _NewSubproject(project: project),
  );
  return made ?? false;
}

class _NewSubproject extends StatefulWidget {
  const _NewSubproject({required this.project});

  final Project project;

  @override
  State<_NewSubproject> createState() => _NewSubprojectState();
}

class _NewSubprojectState extends State<_NewSubproject> {
  final _name = TextEditingController();
  final _dir = TextEditingController();
  final _image = TextEditingController();

  /// An existing project to bring in; null: a new subproject.
  String? _from;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _dir.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final c = app.client;
    if (c == null) return;
    final from = _from;
    if (from != null &&
        !await askConfirm(
          context,
          title: l.spBringInTitle,
          body: l.spAdoptConfirm,
          yes: l.spBringIn,
        )) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final dir = _dir.text.trim();
      final made = from != null
          ? await c.adoptProject(widget.project.id, from, dir: dir)
          : await c.createSubproject(widget.project.id, _name.text.trim(), dir: dir);
      final image = _image.text.trim();
      if (image.isNotEmpty) await c.setSubprojectImage(widget.project.id, made.id, image);
      await app.refresh();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final others = app.projects.where((p) => p.id != widget.project.id).toList();
    final ok = !_busy && (_from != null || _name.text.trim().isNotEmpty);
    Widget field(TextEditingController t, String label, String? help, Key key) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        key: key,
        controller: t,
        enabled: !_busy,
        autocorrect: false,
        decoration: InputDecoration(labelText: label, helperText: help, helperMaxLines: 3),
      ),
    );
    return AlertDialog(
      key: const Key('sub-window'),
      title: Text(l.spNewTitle(widget.project.name)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (others.isNotEmpty) ...[
                Text(l.spFrom, style: TextStyle(color: c.dim, fontSize: 13)),
                const SizedBox(height: 4),
                Material(
                  color: c.panel2,
                  clipBehavior: Clip.antiAlias,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      PickRow(
                        key: const Key('sub-from-new'),
                        title: l.spNewOne,
                        leading: RgIcon(RgIcons.plus, size: 18, color: c.accent),
                        selected: _from == null,
                        onTap: _busy ? null : () => setState(() => _from = null),
                      ),
                      for (final p in others)
                        PickRow(
                          key: Key('sub-from-${p.id}'),
                          title: l.spBringInName(p.name),
                          leading: RgIcon(RgIcons.box, size: 18, color: c.dim),
                          selected: _from == p.id,
                          onTap: _busy ? null : () => setState(() => _from = p.id),
                        ),
                    ],
                  ),
                ),
              ],
              if (_from == null) field(_name, l.spName, null, const Key('sub-name')),
              field(_dir, l.spDir, l.spDirHelp, const Key('sub-dir')),
              field(_image, l.spImage, l.spImageHelp, const Key('sub-image')),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    key: const Key('sub-error'),
                    style: TextStyle(color: c.err),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const Key('sub-cancel'),
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('sub-create'),
          onPressed: ok ? _create : null,
          child: _busy
              ? const RgSpinner(size: 16, color: Colors.white)
              : Text(_from == null ? l.spCreate : l.spBringIn),
        ),
      ],
    );
  }
}
