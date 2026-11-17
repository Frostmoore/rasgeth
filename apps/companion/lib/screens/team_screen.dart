// Team (proposal A's home): the RedGiant's name and state, the «For you» and «In progress» pills,
// and the grid of first-level agents with their living mascots (the page's `agentMascotState`,
// kept up to date by the live connection). A tap opens the agent's conversation; a long press
// shows what it is doing, with «Stop», «Open the task» and the favourite (G40.9). Favourites come
// first and have their own filter, as each project does.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/conversation.dart';
import '../api/live.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/agent_menu.dart';
import '../ui/common.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import '../ui/remove_agent.dart';
import '../ui/words.dart';
import 'agent_settings_screen.dart';
import 'code/project_screen.dart';
import 'conversation_screen.dart';
import 'first_start_screen.dart';
import 'instructions_screen.dart';
import 'new_agent_screen.dart';
import 'removed_agents_screen.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final hello = app.hello;
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        // First level: God and the agents right under it (not subagents nor inspectors).
        final everyone = app.agents.any(
          (a) => a.kind != AgentKind.subagent && a.kind != AgentKind.inspector,
        );
        final team = app.teamShown();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: hello == null ? l.noServer : app.displayName,
              subtitle: Row(
                children: [
                  Dot(
                    app.connected
                        ? (app.isLive && app.liveStatus != LiveStatus.open ? c.warn : c.ok)
                        : c.dim,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      hello == null
                          ? (app.connecting ? l.connecting : l.connectFromYou)
                          : !app.connected
                          ? l.statusUnreachable
                          : app.isLive && app.liveStatus != LiveStatus.open
                          ? l.statusReconnecting
                          : l.statusConnected,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _Pill(
                      icon: RgIcons.bell,
                      label: l.pillInbox,
                      count: app.live.forYou,
                      hot: true,
                      onTap: () => app.setTab(AppTab.inbox),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Pill(
                      icon: RgIcons.spinner,
                      label: l.pillRunning,
                      count: app.live.inProgress,
                      onTap: () => app.setTab(AppTab.activity),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !everyone && app.servers.isEmpty && !app.connecting
                  ? const _FirstSteps()
                  : !everyone
                  ? EmptyState(
                      icon: RgIcons.users,
                      text: hello == null ? l.connectFromYou : l.teamEmpty,
                    )
                  : CustomScrollView(
                      key: const Key('team-scroll'),
                      slivers: [
                        if (app.god case final god?)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                              child: AgentPress(
                                agent: god,
                                longPress: false,
                                child: GodCard(
                                  agent: god,
                                  state: app.live.mascotStateOf(god.id),
                                  doing: doingOf(l, app, god, app.live.mascotStateOf(god.id)),
                                  onTap: () => openAgentConversation(context, god),
                                  onLongPress: () => showAgentSheet(context, god),
                                ),
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                            child: AgentPress(
                              agent: app.chatAgent,
                              longPress: false,
                              child: ChatCard(
                                agent: app.chatAgent,
                                state: app.chatAgent == null
                                    ? MascotState.idle
                                    : app.live.mascotStateOf(app.chatAgent!.id),
                                latest: app.chatAgent == null
                                    ? null
                                    : app.latestOf(app.chatAgent!.id),
                                onTap: () => app.setTab(AppTab.chat),
                                onLongPress: app.chatAgent == null
                                    ? null
                                    : () => showAgentSheet(context, app.chatAgent!),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    header: true,
                                    child: Text(
                                      l.teamAgents,
                                      key: const Key('team-agents-header'),
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: c.text,
                                      ),
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  key: const Key('team-new-agent'),
                                  onPressed: () => openNewAgent(context),
                                  icon: RgIcon(RgIcons.plus, size: 18, color: c.accent),
                                  label: Text(
                                    l.teamNewAgent,
                                    style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (app.projects.isNotEmpty || app.favourites.isNotEmpty)
                          const SliverToBoxAdapter(child: _Filters()),
                        if (team.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: EmptyState(
                                icon: app.teamFilter == TeamFilter.favourites
                                    ? RgIcons.star
                                    : RgIcons.users,
                                text: app.teamFilter == TeamFilter.favourites
                                    ? l.teamNoFavourites
                                    : app.teamFilter == TeamFilter.all
                                    ? l.teamNoAgents
                                    : l.teamNoneInProject,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverGrid.builder(
                              key: const Key('team-grid'),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 220,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: .95,
                              ),
                              itemCount: team.length,
                              itemBuilder: (context, i) => AgentPress(
                                agent: team[i],
                                longPress: false,
                                child: AgentCard(
                                  agent: team[i],
                                  state: app.live.mascotStateOf(team[i].id),
                                  favourite: app.isFavourite(team[i].id),
                                  onTap: () => openAgentConversation(context, team[i]),
                                  onLongPress: () => showAgentSheet(context, team[i]),
                                ),
                              ),
                            ),
                          ),
                        // 3.8.9: the agents taken out of the team, to read and bring back.
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            child: ListTile(
                              key: const Key('team-removed'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: c.line),
                              ),
                              tileColor: c.panel,
                              leading: RgIcon(RgIcons.archive, size: 18, color: c.dim),
                              title: Text(
                                l.raListTitle,
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                              ),
                              subtitle: Text(l.raListRow, style: TextStyle(color: c.dim)),
                              trailing: RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
                              onTap: () => openRemovedAgents(context),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// What [a] is doing now, in words: its running conversation's title, waiting for the person,
/// just answered, or still.
String doingOf(AppLocalizations l, AppController app, Agent a, MascotState state) {
  final running = app.runningOf(a.id);
  if (running.isNotEmpty) {
    final t = running.first.title;
    return t != null && t.isNotEmpty ? t : stateWord(l, state);
  }
  return switch (state) {
    MascotState.wait => l.agentWaitsYou,
    MascotState.active => l.agentJustAnswered,
    MascotState.error => l.agentBlockedNow,
    _ => l.agentIdleNow,
  };
}

/// God's big card at the top of Team: its mascot, its state and what it is doing.
class GodCard extends StatelessWidget {
  const GodCard({
    super.key,
    required this.agent,
    required this.state,
    required this.doing,
    this.onTap,
    this.onLongPress,
  });

  final Agent agent;
  final MascotState state;
  final String doing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final word = stateWord(l, state);
    final waiting = state == MascotState.wait;
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('team-god'),
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: waiting ? c.accentDim : c.line),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accentSoft, c.panel],
                stops: const [0, .8],
              ),
            ),
            child: Row(
              children: [
                MascotView(
                  agentId: agent.id,
                  spec: agent.mascot,
                  state: state,
                  size: (MediaQuery.sizeOf(context).width * .28).clamp(84.0, 120.0),
                  label: l.mascotLabel(agent.name, word),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.text),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Dot(stateColor(c, state)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              word,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.5, color: c.dim),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        doing,
                        key: const Key('team-god-doing'),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.5, color: c.text, height: 1.3),
                      ),
                    ],
                  ),
                ),
                RgIcon(RgIcons.chevronRight, size: 20, color: c.dim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Chat's wide card under God's: a tap opens the Chat.
class ChatCard extends StatelessWidget {
  const ChatCard({
    super.key,
    this.agent,
    this.state = MascotState.idle,
    this.latest,
    this.onTap,
    this.onLongPress,
  });

  final Agent? agent;
  final MascotState state;
  final SessionRow? latest;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final a = agent;
    final word = stateWord(l, state);
    final title = latest?.title;
    return Semantics(
      button: true,
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          key: const Key('team-chat'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              children: [
                if (a != null)
                  MascotView(
                    agentId: a.id,
                    spec: a.mascot,
                    state: state,
                    size: 60,
                    label: l.mascotLabel(a.name, word),
                  )
                else
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(child: RgIcon(RgIcons.chat, size: 28, color: c.dim)),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            a?.name ?? l.tabChat,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                          if (a != null) ...[
                            const SizedBox(width: 8),
                            Dot(stateColor(c, state)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                word,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12.5, color: c.dim),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title != null && title.isNotEmpty ? title : l.teamChatLead,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, color: c.dim),
                      ),
                    ],
                  ),
                ),
                RgIcon(RgIcons.chevronRight, size: 20, color: c.dim),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// All, Favourites, then each project: one choice, kept per RedGiant.
class _Filters extends StatelessWidget {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    Widget chip(String value, String label, {RgIcons? icon, required Key key}) {
      final on = app.teamFilter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          selected: on,
          button: true,
          child: Material(
            color: on ? c.accentSoft : c.panel,
            shape: StadiumBorder(side: BorderSide(color: on ? c.accentDim : c.line)),
            child: InkWell(
              key: key,
              customBorder: const StadiumBorder(),
              onTap: () => app.setTeamFilter(value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      RgIcon(
                        icon,
                        size: 15,
                        color: on ? c.accent : c.dim,
                        filled: on && icon == RgIcons.star,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                        color: on ? c.text : c.dim,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 46,
      child: ListView(
        key: const Key('team-filters'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 10),
        children: [
          chip(TeamFilter.all, l.teamAll, key: const Key('team-filter-all')),
          chip(
            TeamFilter.favourites,
            l.teamFavourites,
            icon: RgIcons.star,
            key: const Key('team-filter-favourites'),
          ),
          for (final p in app.projects)
            chip(p.id, p.name, icon: RgIcons.folder, key: Key('team-filter-${p.id}')),
        ],
      ),
    );
  }
}

/// The long press: what [a] is doing now, and its quick actions.
Future<void> showAgentSheet(BuildContext context, Agent a) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => AgentSheet(agent: a, parent: context),
);

class AgentSheet extends StatelessWidget {
  const AgentSheet({super.key, required this.agent, required this.parent});

  final Agent agent;

  /// The page under the sheet (it opens the conversations once the sheet is closed).
  final BuildContext parent;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        final a = agent;
        final state = app.live.mascotStateOf(a.id);
        final running = app.runningOf(a.id);
        final rows = app.live.sessions.where((s) => s.agentId == a.id && !s.archived).toList()
          ..sort((x, y) => y.when.compareTo(x.when));
        final latest = rows.firstOrNull;
        final task = [...running, ...rows].where((s) => s.task != null).firstOrNull;
        final fav = app.isFavourite(a.id);
        final when = latest == null ? null : DateTime.tryParse(latest.when)?.toLocal();
        void close() => Navigator.of(context).pop();
        return SafeArea(
          child: SingleChildScrollView(
            key: Key('agent-sheet-${a.id}'),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    MascotView(
                      agentId: a.id,
                      spec: a.mascot,
                      state: state,
                      size: 72,
                      label: l.mascotLabel(a.name, stateWord(l, state)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                          if (a.role?.isNotEmpty == true)
                            Text(
                              a.role!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.dim, fontSize: 13.5),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('agent-favourite'),
                      tooltip: fav ? l.favouriteRemove : l.favouriteAdd,
                      onPressed: () => app.toggleFavourite(a.id),
                      icon: RgIcon(RgIcons.star, color: fav ? c.accent : c.dim, filled: fav),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  l.agentDoing,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.dim),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.panel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Dot(stateColor(c, state)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              doingOf(l, app, a, state),
                              style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
                            ),
                          ),
                        ],
                      ),
                      if (task != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l.agentTask(task.task!),
                            style: TextStyle(color: c.text, fontSize: 13.5),
                          ),
                        ),
                      if (when != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            l.agentLastAt(DateFormat.MMMd(l.localeName).add_Hm().format(when)),
                            style: TextStyle(color: c.dim, fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                AgentModelRow(agent: a, parent: parent),
                const SizedBox(height: 8),
                _SheetRow(
                  key: const Key('agent-instructions'),
                  icon: RgIcons.edit,
                  title: app.isChat(a) ? l.chatInstructions : l.agentInstructions,
                  subtitle: l.agentInstructionsRow,
                  onTap: () {
                    close();
                    openInstructions(parent, a);
                  },
                ),
                const SizedBox(height: 8),
                AgentSettingsRow(
                  onTap: () {
                    close();
                    openAgentSettings(parent, a);
                  },
                ),
                // G40.11: the agent's files, diff and terminal (the advanced interface).
                if (app.advanced && a.projectId != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final (tab, icon, label, k) in [
                        (ProjectTab.files, RgIcons.folder, l.codeTabFiles, 'files'),
                        (ProjectTab.diff, RgIcons.diff, l.codeTabDiff, 'diff'),
                        (ProjectTab.terminal, RgIcons.terminal, l.codeTabTerminal, 'terminal'),
                      ])
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: tab == ProjectTab.terminal ? 0 : 8),
                            child: OutlinedButton.icon(
                              key: Key('agent-code-$k'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                              ),
                              onPressed: () {
                                close();
                                final project =
                                    app.projects.where((p) => p.id == a.projectId).firstOrNull ??
                                    Project(id: a.projectId!, name: a.projectId!);
                                Navigator.of(parent).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProjectScreen(
                                      project: project,
                                      initial: tab,
                                      agentId: a.id,
                                    ),
                                  ),
                                );
                              },
                              icon: RgIcon(icon, size: 16, color: c.text),
                              label: Text(label, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                if (running.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FilledButton.icon(
                      key: const Key('agent-stop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.err,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(parent);
                        final ok = await app.stopAgent(a.id);
                        messenger.showSnackBar(
                          SnackBar(content: Text(ok ? l.agentStopped(a.name) : l.agentStopFailed)),
                        );
                      },
                      icon: const RgIcon(RgIcons.stop, size: 18, color: Colors.white),
                      label: Text(l.agentStop),
                    ),
                  ),
                if (task != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      key: const Key('agent-open-task'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () {
                        close();
                        Navigator.of(parent).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ConversationScreen(sessionId: task.id, agent: a),
                          ),
                        );
                      },
                      icon: RgIcon(RgIcons.checkSquare, size: 18, color: c.text),
                      label: Text(l.agentOpenTask),
                    ),
                  ),
                if (a.kind != AgentKind.god && a.active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      key: const Key('agent-mascot-change'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(parent);
                        final yes = await askConfirm(
                          context,
                          title: l.mascotChange,
                          body: l.mascotChangeAsk(a.name),
                          yes: l.mascotChangeYes,
                        );
                        if (!yes) return;
                        final updated = await app.changeMascot(a);
                        if (updated != null) {
                          messenger.showSnackBar(SnackBar(content: Text(l.mascotChanged(a.name))));
                        }
                      },
                      icon: RgIcon(RgIcons.refresh, size: 18, color: c.text),
                      label: Text(l.mascotChange),
                    ),
                  ),
                // 3.8.9: out of the team; its history stays and «Removed agents» restores it.
                if (canRemoveAgent(app, a))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      key: const Key('agent-remove'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        foregroundColor: c.err,
                        side: BorderSide(color: c.err.withValues(alpha: .5)),
                      ),
                      onPressed: () async {
                        if (await confirmRemoveAgent(context, a) && context.mounted) close();
                      },
                      icon: RgIcon(RgIcons.trash, size: 18, color: c.err),
                      label: Text(l.raMenu),
                    ),
                  ),
                OutlinedButton.icon(
                  key: const Key('agent-open'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () {
                    close();
                    openAgentConversation(parent, a);
                  },
                  icon: RgIcon(RgIcons.chat, size: 18, color: c.text),
                  label: Text(l.agentOpenChat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The sheet's «Model»: [agent]'s model now with its way, and a tap to change it (the families
/// with Subscription / API key, G40.9b), saved with the page's own API.
class AgentModelRow extends StatefulWidget {
  const AgentModelRow({super.key, required this.agent, required this.parent});

  final Agent agent;
  final BuildContext parent;

  @override
  State<AgentModelRow> createState() => _AgentModelRowState();
}

class _AgentModelRowState extends State<AgentModelRow> {
  AgentModel? _own;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) unawaited(_load());
  }

  Future<void> _load() async {
    _loaded = true;
    final app = AppScope.read(context);
    final own = await app.ownModelOf(widget.agent);
    await app.modelChoices();
    if (mounted) setState(() => _own = own);
  }

  String _inheritLabel(AppLocalizations l, AppController app) {
    final a = widget.agent;
    if (a.kind == AgentKind.god || app.isChat(a)) return l.agentModelDefault;
    final up = app.inheritedModelOf(a);
    return up == null
        ? l.agentModelInherit
        : l.modelInheritOf(l.agentModelInherit, modelWords(l, app.knownModels, up));
  }

  Future<void> _pick() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(widget.parent);
    final models = await app.modelChoices(again: true);
    if (!mounted) return;
    if (models.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.noModels)));
      return;
    }
    final pick = await showModelPicker(
      context,
      title: l.agentModelTitle(widget.agent.name),
      models: models,
      current: _own,
      inheritLabel: _inheritLabel(l, app),
    );
    if (pick == null || !mounted) return;
    final ok = await app.setAgentModel(widget.agent, pick.model);
    if (!mounted) return;
    if (ok) setState(() => _own = pick.model);
    messenger.showSnackBar(SnackBar(content: Text(ok ? l.agentModelSaved : l.agentModelFailed)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final own = _own;
    final words = own == null ? _inheritLabel(l, app) : modelWords(l, app.knownModels, own);
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        key: const Key('agent-model'),
        borderRadius: BorderRadius.circular(14),
        onTap: _loaded ? _pick : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              RgIcon(RgIcons.zap, size: 18, color: c.dim),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.agentModel,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                    ),
                    Text(
                      words,
                      key: const Key('agent-model-now'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.dim, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final RgIcons icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              RgIcon(icon, size: 18, color: c.dim),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                    ),
                    Text(subtitle, style: TextStyle(color: c.dim, fontSize: 12.5)),
                  ],
                ),
              ),
              RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// The colour of a state's dot.
Color stateColor(RgColors c, MascotState s) => switch (s) {
  MascotState.wait => c.accent,
  MascotState.error => c.err,
  MascotState.think => c.warn,
  MascotState.work => c.ok,
  MascotState.active => c.ok,
  MascotState.idle => c.dim,
};

/// No RedGiant yet: set a new one up from here (G40.8), or connect one that runs already.
class _FirstSteps extends StatelessWidget {
  const _FirstSteps();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RgIcon(RgIcons.server, size: 44, color: c.dim),
              const SizedBox(height: 12),
              Text(
                l.firstStepsTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c.text),
              ),
              const SizedBox(height: 6),
              Text(
                l.firstStepsLead,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.dim),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('team-setup-new'),
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const FirstStartScreen())),
                icon: const RgIcon(RgIcons.wifi, size: 18, color: Colors.white),
                label: Text(l.setupNew),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('team-connect'),
                onPressed: () => app.setTab(AppTab.you),
                child: Text(l.connectExisting),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens [a]'s conversation (God's shared one, or the latest).
Future<void> openAgentConversation(BuildContext context, Agent a, {bool fresh = false}) async {
  final app = AppScope.read(context);
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  final id = await app.openAgent(a, fresh: fresh);
  if (id == null) {
    messenger.showSnackBar(SnackBar(content: Text(l.openFailed)));
    return;
  }
  await nav.push(
    MaterialPageRoute<void>(
      builder: (_) => ConversationScreen(sessionId: id, agent: a),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.count,
    required this.onTap,
    this.hot = false,
  });

  final RgIcons icon;
  final String label;
  final int count;
  final bool hot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final lit = hot && count > 0;
    return Material(
      color: lit ? c.accentSoft : c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: lit ? c.accentDim : c.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              RgIcon(icon, size: 18, color: c.text),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: c.text),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: lit ? c.accent : c.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AgentCard extends StatelessWidget {
  const AgentCard({
    super.key,
    required this.agent,
    this.state = MascotState.idle,
    this.favourite = false,
    this.onTap,
    this.onLongPress,
  });

  final Agent agent;
  final MascotState state;
  final bool favourite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final word = stateWord(l, state);
    final waiting = state == MascotState.wait;
    final card = Container(
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: waiting ? c.accentDim : c.line),
        gradient: waiting
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [c.accentSoft, c.panel],
                stops: const [0, .7],
              )
            : null,
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // As big as the card allows: the mascots are the point of this screen.
          LayoutBuilder(
            builder: (context, box) => MascotView(
              agentId: agent.id,
              spec: agent.mascot,
              state: state,
              size: box.maxWidth.isFinite ? (box.maxWidth * .5).clamp(56.0, 104.0) : 64,
              label: l.mascotLabel(agent.name, word),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            agent.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: c.text),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Dot(stateColor(c, state)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: c.dim),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      value: favourite ? l.favouriteMark : null,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('agent-${agent.id}'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          onLongPress: onLongPress,
          child: favourite
              ? Stack(
                  children: [
                    card,
                    Positioned(
                      top: 10,
                      right: 10,
                      child: RgIcon(RgIcons.star, size: 16, color: c.accent, filled: true),
                    ),
                  ],
                )
              : card,
        ),
      ),
    );
  }
}
