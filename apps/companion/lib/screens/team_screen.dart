// Team (proposal A's home): the RedGiant's name and state, the «For you» and «In progress» pills,
// and the grid of first-level agents with their living mascots (the page's `agentMascotState`,
// kept up to date by the live connection). A tap opens the agent's conversation; a long press
// shows what it is doing, with «Stop», «Open the task» and the favourite (G40.9). Favourites come
// first and have their own filter, as each project does.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/live.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import '../ui/words.dart';
import 'conversation_screen.dart';
import 'first_start_screen.dart';

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
            if (everyone && (app.projects.isNotEmpty || app.favourites.isNotEmpty))
              const _Filters(),
            Expanded(
              child: !everyone && app.servers.isEmpty && !app.connecting
                  ? const _FirstSteps()
                  : team.isEmpty
                  ? EmptyState(
                      icon: app.teamFilter == TeamFilter.favourites ? RgIcons.star : RgIcons.users,
                      text: !everyone
                          ? (hello == null ? l.connectFromYou : l.teamEmpty)
                          : app.teamFilter == TeamFilter.favourites
                          ? l.teamNoFavourites
                          : l.teamNoneInProject,
                    )
                  : GridView.builder(
                      key: const Key('team-grid'),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 220,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: .95,
                      ),
                      itemCount: team.length,
                      itemBuilder: (context, i) => AgentCard(
                        agent: team[i],
                        state: app.live.mascotStateOf(team[i].id),
                        favourite: app.isFavourite(team[i].id),
                        onTap: () => openAgentConversation(context, team[i]),
                        onLongPress: () => showAgentSheet(context, team[i]),
                      ),
                    ),
            ),
          ],
        );
      },
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
          child: Padding(
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
                              running.isNotEmpty
                                  ? (running.first.title?.isNotEmpty == true
                                        ? running.first.title!
                                        : stateWord(l, state))
                                  : state == MascotState.wait
                                  ? l.agentWaitsYou
                                  : l.agentIdleNow,
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

/// The colour of a state's dot.
Color stateColor(RgColors c, MascotState s) => switch (s) {
  MascotState.wait => c.accent,
  MascotState.error => c.err,
  MascotState.think => c.warn,
  MascotState.work => c.ok,
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
