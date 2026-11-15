// Team (proposal A's home): the RedGiant's name and state, the «For you» and «In progress» pills,
// and the grid of first-level agents with their living mascots (the page's `agentMascotState`,
// kept up to date by the live connection). A tap opens the agent's conversation. Long press,
// favourites and the project filter come with G40.9.
import 'package:flutter/material.dart';

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
    // First level: God and the agents right under it (not subagents nor inspectors).
    final team = app.agents
        .where((a) => a.kind != AgentKind.subagent && a.kind != AgentKind.inspector)
        .toList();
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) => Column(
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
            child: team.isEmpty && app.servers.isEmpty && !app.connecting
                ? const _FirstSteps()
                : team.isEmpty
                ? EmptyState(
                    icon: RgIcons.users,
                    text: hello == null ? l.connectFromYou : l.teamEmpty,
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
                      onTap: () => openAgentConversation(context, team[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

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
  const AgentCard({super.key, required this.agent, this.state = MascotState.idle, this.onTap});

  final Agent agent;
  final MascotState state;
  final VoidCallback? onTap;

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
          MascotView(
            agentId: agent.id,
            spec: agent.mascot,
            state: state,
            size: 64,
            label: l.mascotLabel(agent.name, word),
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
              Dot(switch (state) {
                MascotState.wait => c.accent,
                MascotState.error => c.err,
                MascotState.think => c.warn,
                MascotState.work => c.ok,
                MascotState.idle => c.dim,
              }),
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: Key('agent-${agent.id}'),
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: card,
        ),
      ),
    );
  }
}
