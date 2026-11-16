// «Projects» in the control room (G40.17). One tile per project with the mascots of its agents and
// its latest actions; with the advanced interface (board C, advanced 1) also the branch and the
// commits to send, the changes, the verifier of its open task and the last commit, the open
// tasks under the wall and, on the right, the stream of events of every project, frozen while
// the pointer is over it.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/conversation.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../mascot/mascot_view.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../../ui/words.dart';
import '../desk_controller.dart';
import '../new_project.dart';
import '../palette.dart' show requestLine;
import '../wall.dart';
import '../wall_feed.dart';

/// «12 min», «3 h», «ieri», «4 g»: how long ago, short.
String ageOf(AppLocalizations l, String iso, {DateTime? now}) {
  final t = DateTime.tryParse(iso);
  if (t == null) return '';
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return l.deskAgeNow;
  if (d.inMinutes < 60) return l.deskAgeMinutes(d.inMinutes);
  if (d.inHours < 24) return l.deskAgeHours(d.inHours);
  if (d.inDays == 1) return l.deskAgeYesterday;
  return l.deskAgeDays(d.inDays);
}

/// The agents of a project (first level).
List<Agent> projectAgents(AppController app, String projectId) =>
    app.agents.where((a) => a.projectId == projectId && a.kind != AgentKind.subagent).toList();

enum ProjectFilter { all, changes, waiting }

class ProjectsWall extends StatefulWidget {
  const ProjectsWall({super.key, required this.feed});

  final WallFeed feed;

  @override
  State<ProjectsWall> createState() => _ProjectsWallState();
}

class _ProjectsWallState extends State<ProjectsWall> {
  ProjectFilter _filter = ProjectFilter.all;
  bool _list = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final feed = widget.feed;
    return ListenableBuilder(
      listenable: Listenable.merge([app.live, feed]),
      builder: (context, _) {
        final all = app.projects.where((p) => !p.archived).toList();
        bool waits(Project p) =>
            app.live.requests.any((r) => projectAgents(app, p.id).any((a) => a.id == r.agentId));
        bool changed(Project p) => feed.status[p.id]?.git?.clean == false;
        final shown = all.where((p) {
          return switch (_filter) {
            ProjectFilter.all => true,
            ProjectFilter.changes => changed(p),
            ProjectFilter.waiting => waits(p),
          };
        }).toList();
        final tasks = [
          for (final p in all)
            for (final t in feed.status[p.id]?.open ?? const <TaskRow>[]) (p, t),
        ];
        final wall = CustomScrollView(
          key: const Key('desk-projects'),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(child: HeroRow()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilterPill(
                            key: const Key('projects-filter-all'),
                            label: '${l.deskAllProjects} · ${all.length}',
                            on: _filter == ProjectFilter.all,
                            onTap: () => setState(() => _filter = ProjectFilter.all),
                          ),
                          if (app.advanced)
                            FilterPill(
                              key: const Key('projects-filter-changes'),
                              label: '${l.deskWithChanges} · ${all.where(changed).length}',
                              on: _filter == ProjectFilter.changes,
                              onTap: () => setState(() => _filter = ProjectFilter.changes),
                            ),
                          FilterPill(
                            key: const Key('projects-filter-waiting'),
                            label: '${l.deskFilterWaiting} · ${all.where(waits).length}',
                            hot: all.any(waits),
                            on: _filter == ProjectFilter.waiting,
                            onTap: () => setState(() => _filter = ProjectFilter.waiting),
                          ),
                        ],
                      ),
                    ),
                    Segmented(
                      key: const Key('projects-layout'),
                      options: [l.deskTiles, l.deskList],
                      icons: const [RgIcons.square, RgIcons.list],
                      selected: _list ? 1 : 0,
                      onSelect: (i) => setState(() => _list = i == 1),
                    ),
                  ],
                ),
              ),
            ),
            if (shown.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
                  child: Column(
                    children: [
                      EmptyState(icon: RgIcons.folder, text: l.deskNoProjects),
                      const SizedBox(width: 360, height: 178, child: NewProjectTile()),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: _list ? 4000 : 380,
                    mainAxisExtent: app.advanced ? 262 : 178,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  // «New project» is the last tile, right after the last project.
                  itemCount: shown.length + 1,
                  itemBuilder: (context, i) => i == shown.length
                      ? const NewProjectTile()
                      : ProjectTile(project: shown[i], feed: feed),
                ),
              ),
            if (app.advanced && tasks.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                sliver: SliverToBoxAdapter(child: _OpenTasks(tasks: tasks)),
              )
            else
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
        if (!app.advanced) return wall;
        return LayoutBuilder(
          builder: (context, box) => box.maxWidth < 980
              ? wall
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: wall),
                    Container(
                      width: 340,
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: c.line)),
                      ),
                      child: EventStream(feed: feed),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// «New project» as a tile of the wall: the last one after the projects, or under «no projects».
class NewProjectTile extends StatelessWidget {
  const NewProjectTile({super.key});

  @override
  Widget build(BuildContext context) => NewTile(
    key: const Key('desk-new-project'),
    icon: RgIcons.plus,
    label: AppLocalizations.of(context).deskNewProject,
    onTap: () => openNewProject(context),
  );
}

class ProjectTile extends StatelessWidget {
  const ProjectTile({super.key, required this.project, required this.feed});

  final Project project;
  final WallFeed feed;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = project;
    final agents = projectAgents(app, p.id);
    final states = {for (final a in agents) a.id: app.live.mascotStateOf(a.id)};
    final working = agents
        .where((a) => states[a.id] == MascotState.work || states[a.id] == MascotState.think)
        .toList();
    final asks = app.live.requests.where((r) => agents.any((a) => a.id == r.agentId)).toList();
    final critical = asks.any((r) => r is PermissionRequest && r.isCritical);
    final s = feed.status[p.id];
    final git = s?.git;
    final lines = feed.projectLines(p.id);
    final lead =
        agents.where((a) => a.kind == AgentKind.orchestrator).firstOrNull ??
        working.firstOrNull ??
        agents.firstOrNull;
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 11.5,
      height: 1.45,
      color: c.dim,
    );
    final label = TextStyle(fontSize: 11, letterSpacing: .4, color: c.dim);
    Widget row(String name, Widget value) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(width: 82, child: Text(name.toUpperCase(), style: label)),
          Expanded(child: value),
        ],
      ),
    );
    final task = s?.open.where((t) => t.verifier != null).firstOrNull ?? s?.open.firstOrNull;
    final who = working.isNotEmpty
        ? l.deskProjectWorking(
            working.first.name,
            stateWord(l, states[working.first.id]!),
            working.length,
          )
        : agents.isEmpty
        ? l.deskNoAgents
        : l.deskAgentsCount(agents.length);
    return Semantics(
      button: true,
      label: p.name,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('project-tile-${p.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            desk.setProject(p.id);
            if (app.advanced) {
              desk.setView(DeskView.code);
            } else if (lead != null) {
              unawaited(desk.openAgent(lead));
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: critical || asks.isNotEmpty ? c.accent : c.line,
                width: critical ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RgIcon(RgIcons.folder, size: 16, color: c.text),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: c.text),
                      ),
                    ),
                    if (app.advanced && git != null) BranchPill(git: git),
                    if (asks.isNotEmpty && !app.advanced)
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                        child: Text(
                          '${asks.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final a in agents.take(6))
                      Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: MascotView(
                          agentId: a.id,
                          spec: a.mascot,
                          state: states[a.id]!,
                          size: 30,
                          label: l.mascotLabel(a.name, stateWord(l, states[a.id]!)),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        who,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.dim),
                      ),
                    ),
                  ],
                ),
                if (app.advanced) ...[
                  if (git?.repo == false)
                    row(
                      l.deskFiles,
                      Text(l.deskNoGit, style: TextStyle(fontSize: 12.5, color: c.text)),
                    )
                  else
                    row(
                      l.deskChanges,
                      s == null
                          ? Text('…', style: TextStyle(color: c.dim))
                          : s.files == 0
                          ? Text(l.deskNoChanges, style: TextStyle(fontSize: 12.5, color: c.text))
                          : Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '+${s.added} ',
                                    style: TextStyle(color: c.ok, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(
                                    text: '−${s.removed}',
                                    style: TextStyle(color: c.err, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: ' · ${l.deskFilesCount(s.files)}'),
                                ],
                              ),
                              style: TextStyle(fontSize: 12.5, color: c.text),
                            ),
                    ),
                  row(
                    l.deskVerifier,
                    task == null
                        ? Text(l.deskNoTask, style: TextStyle(fontSize: 12.5, color: c.dim))
                        : Row(
                            children: [
                              RgIcon(
                                task.verified == true
                                    ? RgIcons.check
                                    : task.verifier == null
                                    ? RgIcons.spinner
                                    : RgIcons.x,
                                size: 13,
                                color: task.verified == true
                                    ? c.ok
                                    : task.verifier == null
                                    ? c.warn
                                    : c.err,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '«${task.title}»: ${task.verifier == null
                                      ? l.deskTaskRunning
                                      : task.verified == true
                                      ? l.deskTaskPassed
                                      : l.deskTaskFailed}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12.5, color: c.text),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
                const SizedBox(height: 6),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: c.line, width: 2)),
                    ),
                    child: ClipRect(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final e in lines)
                            Text(
                              '${e.agentName ?? ''}: ${actionText(e, max: 60)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mono.copyWith(color: e.error ? c.err : c.text),
                            ),
                          if (lines.isEmpty) Text(l.deskNoActions, style: mono),
                        ],
                      ),
                    ),
                  ),
                ),
                if (asks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Row(
                      children: [
                        RgIcon(critical ? RgIcons.shield : RgIcons.bell, size: 13, color: c.accent),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            l.deskAgentAsks(asks.first.agentName, requestLine(asks.first)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: c.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (app.advanced && s?.last != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${s!.last!.short} ',
                            style: TextStyle(color: c.warnText, fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: '${s.last!.subject} · ${ageOf(l, s.last!.date)}'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// «⑂ p2.4.0 ↑3» drawn: the branch and the commits to send.
class BranchPill extends StatelessWidget {
  const BranchPill({super.key, required this.git});

  final GitState git;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      color: c.dim,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.line),
      ),
      child: !git.repo
          ? Text(l.deskNoGitShort, style: mono)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(RgIcons.gitBranch, size: 11, color: c.dim),
                const SizedBox(width: 4),
                Text(git.branch ?? l.codeDetached, style: mono),
                if (git.ahead > 0) ...[
                  const SizedBox(width: 5),
                  RgIcon(RgIcons.arrowUp, size: 11, color: c.accent),
                  Text('${git.ahead}', style: mono.copyWith(color: c.accent)),
                ],
              ],
            ),
    );
  }
}

class _OpenTasks extends StatelessWidget {
  const _OpenTasks({required this.tasks});

  final List<(Project, TaskRow)> tasks;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 12,
      color: c.text,
    );
    return Container(
      key: const Key('desk-open-tasks'),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                RgIcon(RgIcons.check, size: 14, color: c.dim),
                const SizedBox(width: 6),
                Text(
                  '${l.deskOpenTasks.toUpperCase()} · ${tasks.length}',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: .6,
                    fontWeight: FontWeight.w700,
                    color: c.dim,
                  ),
                ),
                const Spacer(),
                Text(l.deskTasksRule, style: TextStyle(fontSize: 12, color: c.dim)),
              ],
            ),
          ),
          for (final (p, t) in tasks)
            InkWell(
              onTap: () {
                final a = app.agents.where((x) => x.id == t.agentId).firstOrNull;
                if (t.sessionId != null) {
                  desk.show(PanelConversation(t.sessionId!, agent: a));
                } else if (a != null) {
                  unawaited(desk.openAgent(a));
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(t.agentName, style: TextStyle(color: c.text)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(p.name, style: TextStyle(color: c.dim)),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        t.verifier ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        t.verifier == null
                            ? l.deskTaskRunning
                            : t.verified == true
                            ? l.deskTaskPassed
                            : l.deskTaskFailed,
                        style: TextStyle(
                          color: t.verifier == null ? c.dim : (t.verified == true ? c.ok : c.err),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// «The stream of events»: every project's actions as they come, frozen under the pointer.
class EventStream extends StatefulWidget {
  const EventStream({super.key, required this.feed});

  final WallFeed feed;

  @override
  State<EventStream> createState() => _EventStreamState();
}

class _EventStreamState extends State<EventStream> {
  List<ProjectEvent>? _frozen;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final events = _frozen ?? widget.feed.recent();
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 11.5,
      color: c.dim,
    );
    return Column(
      key: const Key('desk-event-stream'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
          child: Row(
            children: [
              RgIcon(RgIcons.zap, size: 16, color: c.text),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l.deskEventStream,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: c.text),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  l.deskAllProjectsLower,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: c.dim),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(99)),
                child: Row(
                  children: [
                    Dot(_frozen == null ? c.ok : c.warn),
                    const SizedBox(width: 5),
                    Text(
                      _frozen == null ? l.deskLive : l.deskFrozen,
                      style: TextStyle(fontSize: 11.5, color: c.dim),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: c.line),
        Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _frozen = widget.feed.recent()),
            onExit: (_) => setState(() => _frozen = null),
            child: events.isEmpty
                ? EmptyState(icon: RgIcons.activity, text: l.codeLogEmpty)
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
                    itemBuilder: (context, i) {
                      final e = events[i];
                      final a = app.agents.where((x) => x.id == e.agentId).firstOrNull;
                      return InkWell(
                        onTap: () {
                          final pid = widget.feed.projectOf(e);
                          desk.searchLog('', projectId: pid);
                        },
                        child: Container(
                          color: e.error ? c.criticalSoft : null,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (a != null)
                                    MascotView(
                                      agentId: a.id,
                                      spec: a.mascot,
                                      state: app.live.mascotStateOf(a.id),
                                      size: 20,
                                      label: a.name,
                                    ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      e.agentName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, color: c.text),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  EventType(type: e.type, error: e.error),
                                  const Spacer(),
                                  Text(clockShort(e.ts), style: mono),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                actionText(e, max: 90),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: mono.copyWith(color: c.text),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        Divider(height: 1, color: c.line),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
          child: Text(l.deskStreamHint, style: TextStyle(fontSize: 11.5, color: c.dim)),
        ),
      ],
    );
  }
}

/// An event's type as a small coloured label (`tool.call`, `approval.requested`…).
class EventType extends StatelessWidget {
  const EventType({super.key, required this.type, this.error = false});

  final String type;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final color = error || type.contains('error') || type.contains('critical')
        ? c.err
        : type.startsWith('approval.') || type.startsWith('permission.')
        ? c.accent
        : type.startsWith('task.')
        ? c.ok
        : c.dim;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .13),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontFamily: monoFamily,
          fontFamilyFallback: monoFallback,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// The status bar's project: its branch and the commits to send (advanced).
class ProjectStatusItem extends StatefulWidget {
  const ProjectStatusItem({super.key, required this.desk});

  final DeskController desk;

  @override
  State<ProjectStatusItem> createState() => _ProjectStatusItemState();
}

class _ProjectStatusItemState extends State<ProjectStatusItem> {
  GitState? _git;
  String? _for;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load(force: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool force = false}) async {
    final pid = widget.desk.projectOr();
    if (pid == null || (!force && pid == _for)) return;
    _for = pid;
    try {
      final g = await widget.desk.app.client?.gitState(pid);
      if (mounted) setState(() => _git = g);
    } on ApiException {
      // Shown without it.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    unawaited(_load());
    final g = _git;
    if (g == null || !g.repo) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(RgIcons.gitBranch, size: 13, color: c.dim),
          const SizedBox(width: 5),
          Text(
            '${g.branch ?? l.codeDetached} · ${l.deskToSend(g.ahead)}',
            key: const Key('status-branch'),
            style: TextStyle(fontSize: 12, color: c.dim),
          ),
        ],
      ),
    );
  }
}
