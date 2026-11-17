// The control room's wall (G40.17, board C, «Squadra»): at the top God, the Chat and «For you»,
// each with its own field or count; under them the filters and the wall of tiles, one per agent,
// grouped by project (or by state), with the living mascots, what each one is doing and its
// latest actions scrolling by. A click opens the conversation in the side panel; a right click
// (or a long press) the agent's sheet. A truly dangerous request takes the top of the room.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../screens/inbox_screen.dart';
import '../screens/new_agent_screen.dart';
import '../screens/team_screen.dart';
import '../theme/colors.dart';
import '../ui/agent_menu.dart';
import '../ui/common.dart';
import '../ui/highlight.dart';
import '../ui/icons.dart';
import '../ui/project_menu.dart';
import '../ui/send_keys.dart';
import '../ui/words.dart';
import 'desk_controller.dart';
import 'desk_menu.dart';
import 'palette.dart' show requestLine;
import 'wall_feed.dart';

/// Which filter an agent's state falls in.
WallFilter filterOf(MascotState s) => switch (s) {
  MascotState.work || MascotState.think => WallFilter.working,
  MascotState.wait => WallFilter.waiting,
  MascotState.error => WallFilter.blocked,
  _ => WallFilter.all,
};

/// The wall's agents: the first level without God, the Chat and Demi-God (as Team).
List<Agent> wallAgents(AppController app) =>
    app.agents
        .where(
          (a) =>
              a.kind != AgentKind.subagent &&
              a.kind != AgentKind.inspector &&
              a.kind != AgentKind.god &&
              a.kind != AgentKind.demigod &&
              a.id != app.chatAgentId,
        )
        .toList()
      ..sort((a, b) {
        final f = (app.isFavourite(b.id) ? 1 : 0) - (app.isFavourite(a.id) ? 1 : 0);
        return f != 0 ? f : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

/// The wall's sections: by project (in the projects' order, the agents without one last) or by
/// state (waiting first, then working, blocked, still). Empty sections are left out.
List<({String title, List<Agent> agents, Project? project})> wallSections(
  AppController app,
  AppLocalizations l, {
  required bool byProject,
  required WallFilter filter,
}) {
  final agents = wallAgents(app)
      .where((a) => filter == WallFilter.all || filterOf(app.live.mascotStateOf(a.id)) == filter)
      .toList();
  if (byProject) {
    final out = <({String title, List<Agent> agents, Project? project})>[];
    for (final p in app.projects) {
      final list = agents.where((a) => a.projectId == p.id).toList();
      if (list.isNotEmpty) out.add((title: p.name, agents: list, project: p));
    }
    final known = app.projects.map((p) => p.id).toSet();
    final rest = agents.where((a) => a.projectId == null || !known.contains(a.projectId)).toList();
    if (rest.isNotEmpty) out.add((title: l.deskNoProject, agents: rest, project: null));
    return out;
  }
  final order = [
    (WallFilter.waiting, l.deskFilterWaiting),
    (WallFilter.working, l.deskFilterWorking),
    (WallFilter.blocked, l.deskFilterBlocked),
    (WallFilter.all, l.deskStill),
  ];
  return [
    for (final (f, title) in order)
      if (agents.where((a) => filterOf(app.live.mascotStateOf(a.id)) == f).toList() case final list
          when list.isNotEmpty)
        (title: title, agents: list, project: null),
  ];
}

/// The squad's wall, with God, the Chat and «For you» over it.
class TeamWall extends StatelessWidget {
  const TeamWall({super.key, required this.feed});

  final WallFeed feed;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app.live, feed]),
      builder: (context, _) {
        final sections = wallSections(app, l, byProject: desk.byProject, filter: desk.wallFilter);
        final everyone = wallAgents(app);
        int count(WallFilter f) =>
            everyone.where((a) => filterOf(app.live.mascotStateOf(a.id)) == f).length;
        final critical = app.live.approvals.where((r) => r.isCritical).toList();
        return CustomScrollView(
          key: const Key('desk-wall'),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              sliver: SliverToBoxAdapter(child: HeroRow()),
            ),
            for (final r in critical)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverToBoxAdapter(child: CriticalBanner(request: r)),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilterPill(
                            key: const Key('wall-filter-all'),
                            label: '${l.deskFilterAll} · ${everyone.length}',
                            on: desk.wallFilter == WallFilter.all,
                            onTap: () => desk.setFilter(WallFilter.all),
                          ),
                          FilterPill(
                            key: const Key('wall-filter-working'),
                            label: '${l.deskFilterWorking} · ${count(WallFilter.working)}',
                            on: desk.wallFilter == WallFilter.working,
                            onTap: () => desk.setFilter(WallFilter.working),
                          ),
                          FilterPill(
                            key: const Key('wall-filter-waiting'),
                            label: '${l.deskFilterWaiting} · ${count(WallFilter.waiting)}',
                            hot: count(WallFilter.waiting) > 0,
                            on: desk.wallFilter == WallFilter.waiting,
                            onTap: () => desk.setFilter(WallFilter.waiting),
                          ),
                          FilterPill(
                            key: const Key('wall-filter-blocked'),
                            label: '${l.deskFilterBlocked} · ${count(WallFilter.blocked)}',
                            on: desk.wallFilter == WallFilter.blocked,
                            onTap: () => desk.setFilter(WallFilter.blocked),
                          ),
                        ],
                      ),
                    ),
                    Segmented(
                      key: const Key('wall-group'),
                      options: [l.deskByProject, l.deskByState],
                      selected: desk.byProject ? 0 : 1,
                      onSelect: (i) => desk.setByProject(i == 0),
                    ),
                  ],
                ),
              ),
            ),
            if (sections.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 28, 40, 20),
                  child: Column(
                    children: [
                      EmptyState(
                        icon: RgIcons.users,
                        text: everyone.isEmpty ? l.teamNoAgents : l.deskNoneHere,
                      ),
                      const SizedBox(width: 330, height: 168, child: NewAgentTile()),
                    ],
                  ),
                ),
              ),
            for (final (si, s) in sections.indexed) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 14, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _SectionTitle(title: s.title, project: s.project),
                      const SizedBox(width: 10),
                      Expanded(child: Divider(color: c.line, height: 1)),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 340,
                    mainAxisExtent: 168,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  // «New agent» is the last tile, right after the last agent.
                  itemCount: s.agents.length + (si == sections.length - 1 ? 1 : 0),
                  itemBuilder: (context, i) => i == s.agents.length
                      ? const NewAgentTile()
                      : AgentTile(agent: s.agents[i], feed: feed),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        );
      },
    );
  }
}

/// A section's title; a project's opens it (a click) and has its menu (right click, 3.8.8).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.project});

  final String title;
  final Project? project;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final text = Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: .7,
          fontWeight: FontWeight.w700,
          color: c.dim,
        ),
      ),
    );
    final p = project;
    if (p == null) return text;
    return ProjectPress(
      project: p,
      child: InkWell(
        key: Key('section-project-${p.id}'),
        borderRadius: BorderRadius.circular(6),
        onTap: () => DeskScope.read(context).showProject(p.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RgIcon(RgIcons.folder, size: 13, color: c.dim),
              const SizedBox(width: 6),
              text,
              const SizedBox(width: 2),
              RgIcon(RgIcons.chevronRight, size: 13, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// God and the Chat, side by side at the top of the wall.
class HeroRow extends StatelessWidget {
  const HeroRow({super.key});

  /// The cards' height: God's name, what it does and its field.
  static const height = 146.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // A narrow room (a small window with the panel open): God on its own line.
        // 3.8.8: «For you» left the wall for the bell in the bar at the top; God and the Chat
        // share the row. A narrow room (a small window with the panel open): one over the other.
        if (box.maxWidth < 700) {
          return const Column(
            children: [
              SizedBox(height: height, child: GodHero()),
              SizedBox(height: 10),
              SizedBox(height: height, child: ChatHero()),
            ],
          );
        }
        return const SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 11, child: GodHero()),
              SizedBox(width: 12),
              Expanded(flex: 9, child: ChatHero()),
            ],
          ),
        );
      },
    );
  }
}

BoxDecoration heroBox(RgColors c, {bool lit = false}) => BoxDecoration(
  color: c.panel,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: lit ? c.accentDim : c.line),
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lit ? c.accentSoft : c.panel2, c.panel],
  ),
);

/// A field at the top: God's or the Chat's. Enter sends; the conversation opens in the panel.
class HeroField extends StatefulWidget {
  const HeroField({
    super.key,
    required this.hint,
    required this.onSend,
    this.focus,
    this.shortcut,
    this.dense = false,
  });

  final String hint;
  final Future<bool> Function(String text) onSend;
  final FocusNode? focus;
  final String? shortcut;
  final bool dense;

  @override
  State<HeroField> createState() => _HeroFieldState();
}

class _HeroFieldState extends State<HeroField> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _busy) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l = AppLocalizations.of(context);
    setState(() => _busy = true);
    final ok = await widget.onSend(t);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _text.clear();
    } else {
      messenger?.showSnackBar(SnackBar(content: Text(l.openFailed)));
    }
  }

  bool _narrow = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        _narrow = box.maxWidth < 260;
        return _field(c);
      },
    );
  }

  Widget _field(RgColors c) {
    return Container(
      height: widget.dense ? 34 : 40,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: SendKeys(
              onSend: _busy ? null : () => unawaited(_send()),
              child: TextField(
                controller: _text,
                focusNode: widget.focus,
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
                style: TextStyle(fontSize: 13.5, color: c.text),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: c.dim, fontSize: 13.5),
                ),
              ),
            ),
          ),
          if (widget.shortcut != null && !_narrow)
            Padding(padding: const EdgeInsets.only(left: 6), child: KeyCap(widget.shortcut!)),
          if (!widget.dense)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Semantics(
                button: true,
                label: AppLocalizations.of(context).composerSend,
                child: Material(
                  color: c.accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _busy ? null : _send,
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(child: RgIcon(RgIcons.send, size: 15, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class GodHero extends StatelessWidget {
  const GodHero({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = app.god;
    final state = god == null ? MascotState.idle : app.live.mascotStateOf(god.id);
    final mac = isMacLike(app);
    final open = god != null && desk.panelAgentId == god.id;
    // 3.8.8: the whole card answers, as the Chat's: a click shows God's conversations in the
    // panel, a right click (or a long press) its menu with God's rules.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('desk-god'),
        borderRadius: BorderRadius.circular(14),
        onTap: god == null ? null : () => desk.showAgent(god),
        onSecondaryTapUp: god == null ? null : (d) => showAgentMenu(context, god, d.globalPosition),
        onLongPress: god == null ? null : () => showAgentSheet(context, god),
        child: Ink(
          decoration: heroBox(c, lit: true).copyWith(
            border: Border.all(color: open ? c.accent : c.accentDim, width: open ? 1.5 : 1),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              if (god == null)
                const SizedBox(width: 84, height: 84)
              else
                MascotView(
                  agentId: god.id,
                  spec: god.mascot,
                  state: state,
                  size: 84,
                  label: l.mascotLabel(god.name, stateWord(l, state)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            god?.name ?? 'God',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                        ),
                        if (god != null) Flexible(child: HeroCount(agentId: god.id)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Dot(stateColor(c, state)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            god == null ? l.statusUnreachable : doingOf(l, app, god, state),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: c.dim),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    HeroField(
                      key: const Key('desk-god-field'),
                      hint: l.deskGodHint,
                      focus: desk.godFocus,
                      shortcut: shortcutLabel(
                        cmdKey(LogicalKeyboardKey.keyG, mac: mac),
                        l,
                        mac: mac,
                      ),
                      onSend: (t) async =>
                          god != null && await desk.openAgent(god, firstMessage: t),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// How many conversations an agent has (not archived), and that a click shows them.
class HeroCount extends StatelessWidget {
  const HeroCount({super.key, required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final n = app.live.sessions.where((s) => s.agentId == agentId && !s.archived).length;
    // Nothing yet: nothing to say (the card's click shows the empty list anyway).
    if (n == 0) return const SizedBox.shrink();
    return Container(
      key: Key('hero-count-$agentId'),
      padding: const EdgeInsets.fromLTRB(8, 3, 4, 3),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(RgIcons.chat, size: 12, color: c.dim),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              l.pmConversationsCount(n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: c.dim, fontWeight: FontWeight.w600),
            ),
          ),
          RgIcon(RgIcons.chevronRight, size: 13, color: c.dim),
        ],
      ),
    );
  }
}

class ChatHero extends StatelessWidget {
  const ChatHero({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final chat = app.chatAgent;
    final state = chat == null ? MascotState.idle : app.live.mascotStateOf(chat.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('desk-chat'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => desk.show(const PanelPage(PanelScreen.chat)),
        onSecondaryTapUp: chat == null
            ? null
            : (d) => showAgentMenu(context, chat, d.globalPosition),
        onLongPress: chat == null ? null : () => showAgentSheet(context, chat),
        child: Ink(
          decoration: heroBox(c),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            children: [
              if (chat != null)
                MascotView(
                  agentId: chat.id,
                  spec: chat.mascot,
                  state: state,
                  size: 58,
                  label: l.mascotLabel(chat.name, stateWord(l, state)),
                )
              else
                RgIcon(RgIcons.chat, size: 40, color: c.dim),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.tabChat,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                        ),
                        if (chat != null) Flexible(child: HeroCount(agentId: chat.id)),
                      ],
                    ),
                    Text(
                      l.deskChatSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: c.dim),
                    ),
                    const SizedBox(height: 8),
                    HeroField(
                      key: const Key('desk-chat-field'),
                      hint: l.deskChatHint,
                      focus: desk.chatFocus,
                      onSend: desk.startChat,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A truly dangerous request at the top of the room (it is never answered from here: «Open»
/// leads to its full screen, as everywhere).
class CriticalBanner extends StatelessWidget {
  const CriticalBanner({super.key, required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    void open() => Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CriticalRequestScreen(request: request),
      ),
    );
    return Material(
      key: Key('desk-critical-${request.requestId}'),
      color: c.critical,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Row(
            children: [
              RgIcon(RgIcons.shield, size: 22, color: c.criticalInk),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.deskCriticalTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: .6,
                        fontWeight: FontWeight.w800,
                        color: c.criticalInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.agentName}: ${requestLine(request, l.localeName)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: c.criticalInk,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: Key('desk-critical-open-${request.requestId}'),
                style: FilledButton.styleFrom(
                  backgroundColor: c.criticalInk,
                  foregroundColor: c.critical,
                ),
                onPressed: open,
                child: Text(l.deskOpenDetail),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One agent on the wall.
class AgentTile extends StatelessWidget {
  const AgentTile({super.key, required this.agent, required this.feed});

  final Agent agent;
  final WallFeed feed;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final state = app.live.mascotStateOf(a.id);
    final waiting = state == MascotState.wait;
    final open = desk.panelAgentId == a.id;
    final project = app.projects.where((p) => p.id == a.projectId).firstOrNull?.name;
    final asks = app.live.requests.where((r) => r.agentId == a.id).toList();
    final running = state == MascotState.work || state == MascotState.think;
    final lines = feed.linesOf(a.id);
    final subs = app.agents
        .where((x) => x.parentId == a.id && x.kind == AgentKind.subagent)
        .toList();
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 11.5,
      height: 1.45,
      color: c.dim,
    );
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: open ? c.accent : (waiting ? c.accentDim : c.line),
          width: open ? 2 : 1,
        ),
        gradient: waiting
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.accentSoft, c.panel],
                stops: const [0, .75],
              )
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MascotView(
                agentId: a.id,
                spec: a.mascot,
                state: state,
                size: 42,
                label: l.mascotLabel(a.name, stateWord(l, state)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: c.text),
                    ),
                    Row(
                      children: [
                        Dot(stateColor(c, state)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            [stateWord(l, state), ?project].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: c.dim),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (app.isFavourite(a.id))
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: RgIcon(RgIcons.star, size: 14, color: c.accent, filled: true),
                ),
              if (asks.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 6),
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
          Text(
            doingOf(l, app, a, state),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: c.text),
          ),
          const SizedBox(height: 5),
          if (running)
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 3,
                value: app.reduceMotion ? .6 : null,
                color: c.accent,
                backgroundColor: c.line,
              ),
            )
          else
            Container(height: 1, color: c.line),
          const SizedBox(height: 5),
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: c.line, width: 2)),
              ),
              child: ClipRect(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final e in lines)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: Text(
                          actionText(e),
                          key: ValueKey(e.seq),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mono.copyWith(color: e.error ? c.err : null),
                        ),
                      ),
                    if (asks.isNotEmpty)
                      Text(
                        l.deskAsks(requestLine(asks.first, l.localeName)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono.copyWith(color: c.accent, fontWeight: FontWeight.w600),
                      ),
                    if (lines.isEmpty && asks.isEmpty)
                      Text(
                        l.deskNoActions,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (subs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  for (final s in subs.take(4))
                    MascotView(
                      agentId: s.id,
                      spec: s.mascot,
                      state: app.live.mascotStateOf(s.id),
                      size: 18,
                      label: l.mascotLabel(s.name, stateWord(l, app.live.mascotStateOf(s.id))),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    l.deskSubagents(subs.length),
                    style: TextStyle(fontSize: 11.5, color: c.dim),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
    return Semantics(
      button: true,
      selected: open,
      label: '${a.name}, ${stateWord(l, state)}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('tile-${a.id}'),
          borderRadius: BorderRadius.circular(12),
          // 3.8.8: the agent's conversations in the panel (as the page's bar), not straight its
          // latest one; the menu's «Open the conversation» still goes there at once.
          onTap: () => desk.showAgent(a),
          onSecondaryTapUp: (d) => showAgentMenu(context, a, d.globalPosition),
          onLongPress: () => showAgentSheet(context, a),
          child: tile,
        ),
      ),
    );
  }
}

/// «New agent» as a tile of the wall: the last one after the agents, or under «no agents».
class NewAgentTile extends StatelessWidget {
  const NewAgentTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mac = isMacLike(AppScope.of(context));
    return NewTile(
      key: const Key('desk-new-agent'),
      icon: RgIcons.plus,
      label: l.teamNewAgent,
      shortcut: shortcutLabel(cmdKey(LogicalKeyboardKey.keyN, mac: mac), l, mac: mac),
      onTap: () => openNewAgent(context),
    );
  }
}

/// A tile that makes something new (an agent, a project): as big as its neighbours, with a
/// drawn icon in the place of the mascot, the words and, when there is one, the shortcut.
class NewTile extends StatefulWidget {
  const NewTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.shortcut,
  });

  final RgIcons icon;
  final String label;
  final String? shortcut;
  final VoidCallback onTap;

  @override
  State<NewTile> createState() => _NewTileState();
}

class _NewTileState extends State<NewTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final shortcut = widget.shortcut;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: _hover ? c.panel : c.panel.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hover ? c.accentDim : c.line),
              ),
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _hover ? c.accentSoft : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _hover ? c.accent : c.line, width: 1.5),
                      ),
                      child: RgIcon(widget.icon, size: 20, color: _hover ? c.accent : c.dim),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: _hover ? c.text : c.dim,
                      ),
                    ),
                    if (shortcut != null) ...[const SizedBox(height: 8), KeyCap(shortcut)],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chip of the wall's filters.
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.on,
    required this.onTap,
    this.hot = false,
  });

  final String label;
  final bool on;
  final bool hot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final fg = on ? c.bg : (hot ? c.accent : c.dim);
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? c.text : (hot ? c.accentSoft : c.panel2),
        shape: StadiumBorder(side: BorderSide(color: hot && !on ? c.accentDim : c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two or more choices side by side (our own, drawn).
class Segmented extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
    this.icons,
  });

  final List<String> options;
  final List<RgIcons>? icons;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, o) in options.indexed)
            Semantics(
              button: true,
              selected: i == selected,
              child: Material(
                color: i == selected ? c.panel : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                child: InkWell(
                  key: Key('seg-$o'),
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icons != null) ...[
                          RgIcon(icons![i], size: 14, color: i == selected ? c.text : c.dim),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          o,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                            color: i == selected ? c.text : c.dim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The compact top strip of the other views: God's and the Chat's fields, «For you».
class HeroStrip extends StatelessWidget {
  const HeroStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = app.god;
    final chat = app.chatAgent;
    final mac = isMacLike(app);
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 820;
        return Container(
          key: const Key('desk-strip'),
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
          decoration: BoxDecoration(
            color: c.panel,
            border: Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              if (god != null)
                AgentPress(
                  key: const Key('strip-god'),
                  agent: god,
                  onTap: () => desk.showAgent(god),
                  child: MascotView(
                    agentId: god.id,
                    spec: god.mascot,
                    state: app.live.mascotStateOf(god.id),
                    size: 30,
                    label: l.mascotLabel(god.name, stateWord(l, app.live.mascotStateOf(god.id))),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: HeroField(
                  key: const Key('desk-god-field'),
                  dense: true,
                  hint: l.deskGodHint,
                  focus: desk.godFocus,
                  shortcut: shortcutLabel(cmdKey(LogicalKeyboardKey.keyG, mac: mac), l, mac: mac),
                  onSend: (t) async => god != null && await desk.openAgent(god, firstMessage: t),
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: 14),
                if (chat != null)
                  AgentPress(
                    key: const Key('strip-chat'),
                    agent: chat,
                    onTap: () => desk.show(const PanelPage(PanelScreen.chat)),
                    child: MascotView(
                      agentId: chat.id,
                      spec: chat.mascot,
                      state: app.live.mascotStateOf(chat.id),
                      size: 26,
                      label: l.mascotLabel(
                        chat.name,
                        stateWord(l, app.live.mascotStateOf(chat.id)),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: HeroField(
                    key: const Key('desk-chat-field'),
                    dense: true,
                    hint: l.deskChatHint,
                    focus: desk.chatFocus,
                    onSend: desk.startChat,
                  ),
                ),
                const Spacer(flex: 1),
                if (app.advanced)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: AdvancedPill(onTap: () => app.setAdvanced(false)),
                  ),
              ] else
                const SizedBox(width: 10),
            ],
          ),
        );
      },
    );
  }
}

/// «Advanced»: shown while the advanced interface is on (a click turns it off).
class AdvancedPill extends StatelessWidget {
  const AdvancedPill({super.key, required this.onTap, this.on = true});

  final VoidCallback onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final fg = on ? c.accent : c.dim;
    return Semantics(
      button: true,
      toggled: on,
      label: l.advancedTitle,
      child: Material(
        color: on ? c.accentSoft : Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: on ? c.accentDim : c.line)),
        child: InkWell(
          key: const Key('desk-advanced-pill'),
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(RgIcons.code, size: 13, color: fg),
                const SizedBox(width: 5),
                Text(l.deskAdvancedShort, style: TextStyle(fontSize: 12, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The time of an event, as 15:42:08.
String clockShort(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
}
