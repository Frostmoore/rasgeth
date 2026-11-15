// Team (proposal A's home): the RedGiant's name and state, the «For you» and «In progress» pills,
// and the grid of first-level agents with their living mascots. Long press, favourites and the
// project filter come with G40.9; the live states with the WebSocket (G40.7).
import 'package:flutter/material.dart';

import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import '../ui/words.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenHeader(
          title: hello?.machine ?? l.noServer,
          subtitle: Row(
            children: [
              Dot(app.connected ? c.ok : c.dim),
              const SizedBox(width: 5),
              Text(
                hello == null
                    ? l.connectFromYou
                    : app.connected
                    ? l.statusConnected
                    : l.statusUnreachable,
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
                  count: 0,
                  hot: true,
                  onTap: () => app.setTab(AppTab.inbox),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Pill(
                  icon: RgIcons.spinner,
                  label: l.pillRunning,
                  count: 0,
                  onTap: () => app.setTab(AppTab.activity),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: team.isEmpty
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
                  itemBuilder: (context, i) => AgentCard(agent: team[i]),
                ),
        ),
      ],
    );
  }
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
  const AgentCard({super.key, required this.agent, this.state = MascotState.idle});

  final Agent agent;
  final MascotState state;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final word = stateWord(l, state);
    final waiting = state == MascotState.wait;
    return Container(
      key: Key('agent-${agent.id}'),
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
              Text(word, style: TextStyle(fontSize: 12.5, color: c.dim)),
            ],
          ),
        ],
      ),
    );
  }
}
