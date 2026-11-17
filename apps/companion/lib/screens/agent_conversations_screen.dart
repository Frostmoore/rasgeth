// An agent's conversations (3.8.8, the user: «a click on God's card must show its conversations,
// as it happens for Chat, and the same for every other agent»): the page's bar (Sidebar.tsx
// `Sessions`) as a list. Pinned first, then the latest; the folders; «Archived (n)» and back;
// «New conversation» on top. On a computer it fills the control room's panel, on a phone the
// whole screen. Every row has the conversation's menu (right click, long press).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/conversation.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../desktop/desk_controller.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/agent_menu.dart';
import '../ui/common.dart';
import '../ui/conversation_menu.dart';
import '../ui/icons.dart';
import '../ui/words.dart';
import 'conversation_screen.dart';
import 'team_screen.dart';

/// [a]'s conversations: the panel on a computer, the whole screen on a phone.
Future<void> openAgentConversations(BuildContext context, Agent a) async {
  final desk = DeskScope.maybeRead(context);
  if (desk != null) {
    desk.showAgent(a);
    return;
  }
  await Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => AgentConversationsScreen(agent: a)));
}

/// The rows of a list: pinned first, then the latest (the page's order).
List<SessionRow> sessionOrder(Iterable<SessionRow> rows) =>
    rows.toList()
      ..sort((a, b) => a.pinned != b.pinned ? (a.pinned ? -1 : 1) : b.when.compareTo(a.when));

/// When a row was last used: the hour today, else the day and the hour.
String rowWhen(AppLocalizations l, SessionRow r, {DateTime? now}) {
  final t = DateTime.tryParse(r.when)?.toLocal();
  if (t == null) return '';
  final n = now ?? DateTime.now();
  if (t.year == n.year && t.month == n.month && t.day == n.day) {
    return DateFormat.Hm(l.localeName).format(t);
  }
  return DateFormat.MMMd(l.localeName).add_Hm().format(t);
}

/// One conversation in a list: its state, title, when, and the menu.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.row, this.who, this.tileKey, this.onTap});

  final SessionRow row;

  /// The agent's name, where the list mixes several (a project's team).
  final Agent? who;
  final Key? tileKey;

  /// Instead of opening it (the Chat keeps its own way).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = row;
    final panel = DeskScope.maybeOf(context)?.panel;
    final open = panel is PanelConversation && panel.sessionId == r.id;
    final origin = r.forkedFrom == null
        ? null
        : app.live.sessions.where((s) => s.id == r.forkedFrom).firstOrNull;
    final sub = [
      rowWhen(l, r),
      if (who != null) who!.name,
      if (origin != null) l.cmForkOf(origin.title ?? l.untitled),
    ].join(' · ');
    return ConversationPress(
      row: r,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        child: Material(
          color: open ? c.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            key: tileKey ?? Key('conv-${r.id}'),
            borderRadius: BorderRadius.circular(10),
            onTap: onTap ?? () => openSessionRow(context, r),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: r.running ? c.ok.withValues(alpha: .14) : c.panel2,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    alignment: Alignment.center,
                    // 3.8.9: a conversation at work turns (RgSpinner), as everywhere.
                    child: r.running
                        ? RgSpinner(size: 16, color: c.ok)
                        : who != null
                        ? MascotView(agentId: who!.id, spec: who!.mascot, size: 24)
                        : RgIcon(
                            r.task != null
                                ? RgIcons.checkSquare
                                : r.archived
                                ? RgIcons.archive
                                : RgIcons.chat,
                            size: 16,
                            color: c.dim,
                          ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sessionTitle(l, r),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: open ? FontWeight.w700 : FontWeight.w600,
                            color: c.text,
                          ),
                        ),
                        if (sub.isNotEmpty)
                          Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: c.dim),
                          ),
                      ],
                    ),
                  ),
                  if (r.running)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        l.stateWork,
                        style: TextStyle(fontSize: 12, color: c.ok, fontWeight: FontWeight.w600),
                      ),
                    ),
                  if (r.pinned)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: RgIcon(
                        RgIcons.pin,
                        key: Key('conv-pinned-${r.id}'),
                        size: 14,
                        color: c.accent,
                        filled: true,
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
}

/// A small heading inside a list (a folder, «Pinned», the team's).
class ListHeading extends StatelessWidget {
  const ListHeading(this.text, {super.key, this.icon});

  final String text;
  final RgIcons? icon;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
        child: Row(
          children: [
            if (icon != null) ...[RgIcon(icon!, size: 13, color: c.dim), const SizedBox(width: 6)],
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
          ],
        ),
      ),
    );
  }
}

/// «Archived (n)» and «Back to the conversations» under a list.
class ArchivedToggle extends StatelessWidget {
  const ArchivedToggle({super.key, required this.count, required this.on, required this.onTap});

  final int count;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (count == 0 && !on) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('conv-archived-toggle'),
          onPressed: onTap,
          icon: RgIcon(on ? RgIcons.arrowLeft : RgIcons.archive, size: 15, color: c.dim),
          label: Text(
            on ? l.cmBack : l.cmArchivedN(count),
            style: TextStyle(color: c.dim, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// The list of [agent]'s conversations, with «New conversation» and «Archived (n)».
class AgentConversations extends StatefulWidget {
  const AgentConversations({
    super.key,
    required this.agent,
    this.readOnly = false,
    this.header = const [],
    this.footer = const [],
  });

  final Agent agent;

  /// Above the list and under it (a project's head, its team's conversations).
  final List<Widget> header;
  final List<Widget> footer;

  /// An archived project's agent: no new conversation.
  final bool readOnly;

  @override
  State<AgentConversations> createState() => _AgentConversationsState();
}

class _AgentConversationsState extends State<AgentConversations> {
  bool _archived = false;
  bool _opening = false;

  Future<void> _new() async {
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final desk = DeskScope.maybeRead(context);
    final nav = Navigator.of(context);
    setState(() => _opening = true);
    final id = await app.openAgent(widget.agent, fresh: true);
    if (mounted) setState(() => _opening = false);
    if (id == null) {
      messenger?.showSnackBar(SnackBar(content: Text(l.openFailed)));
      return;
    }
    if (desk != null) {
      desk.show(PanelConversation(id, agent: widget.agent));
      return;
    }
    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: id, agent: widget.agent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        final a = widget.agent;
        final mine = app.live.sessions.where((s) => s.agentId == a.id).toList();
        final archivedCount = mine.where((s) => s.archived).length;
        final shown = sessionOrder(mine.where((s) => s.archived == _archived));
        final loose = shown.where((s) => s.folder == null).toList();
        final folders = {for (final s in shown) ?s.folder}.toList()..sort();
        final pinned = loose.where((s) => s.pinned).toList();
        final rest = loose.where((s) => !s.pinned).toList();
        return ListView(
          key: Key('agent-convs-${a.id}'),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            ...widget.header,
            if (!widget.readOnly && !_archived)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: FilledButton.icon(
                  key: const Key('agent-conv-new'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                  ),
                  onPressed: _opening ? null : _new,
                  icon: const RgIcon(RgIcons.plus, size: 17, color: Colors.white),
                  label: Text(l.cmNew),
                ),
              ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  icon: _archived ? RgIcons.archive : RgIcons.chat,
                  text: _archived ? l.cmEmptyArchived : l.cmEmpty,
                ),
              ),
            if (pinned.isNotEmpty) ...[
              ListHeading(l.cmPinned, icon: RgIcons.pin),
              for (final r in pinned) SessionTile(row: r),
            ],
            for (final f in folders) ...[
              ListHeading(f, icon: RgIcons.folder),
              for (final r in shown.where((s) => s.folder == f)) SessionTile(row: r),
            ],
            if (rest.isNotEmpty && (pinned.isNotEmpty || folders.isNotEmpty))
              ListHeading(l.pmConversations, icon: RgIcons.chat),
            for (final r in rest) SessionTile(row: r),
            ArchivedToggle(
              count: archivedCount,
              on: _archived,
              onTap: () => setState(() => _archived = !_archived),
            ),
            ...widget.footer,
          ],
        );
      },
    );
  }
}

/// The agent's head over its list: mascot, name, what it does, and its menu.
class AgentListHead extends StatelessWidget {
  const AgentListHead({super.key, required this.agent, this.trailing = const []});

  final Agent agent;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final state = app.live.mascotStateOf(a.id);
    return AgentPress(
      agent: a,
      child: Row(
        children: [
          MascotView(
            agentId: a.id,
            spec: a.mascot,
            state: state,
            size: 40,
            label: l.mascotLabel(a.name, stateWord(l, state)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.text),
                ),
                Row(
                  children: [
                    Dot(stateColor(c, state)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        doingOf(l, app, a, state),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.dim),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// The phone's whole screen of an agent's conversations.
class AgentConversationsScreen extends StatelessWidget {
  const AgentConversationsScreen({super.key, required this.agent});

  final Agent agent;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = app.agents.where((x) => x.id == agent.id).firstOrNull ?? agent;
    return Scaffold(
      key: Key('agent-convs-screen-${a.id}'),
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        leading: IconButton(
          key: const Key('agent-convs-back'),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        title: AgentListHead(agent: a),
        actions: [
          IconButton(
            key: const Key('agent-convs-more'),
            tooltip: l.cmConversationsOf(a.name),
            onPressed: () => showAgentSheet(context, a),
            icon: RgIcon(RgIcons.more, color: c.text),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AgentConversations(agent: a, readOnly: app.isAgentReadOnly(a)),
    );
  }
}
