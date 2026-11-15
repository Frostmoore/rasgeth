// Chat (decision D9, variant 3): the everyday conversations with Chat (the `assistant` agent the
// server makes the first time, `GET /api/chat/agent`), day by day. The field over the bar opens
// a new one at once, with its text as the first message, which also names it (G40.9) unless the
// server has a title for it already.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/icons.dart';
import 'conversation_screen.dart';

/// Conversations grouped by their local day, the latest day first.
List<({DateTime day, List<SessionRow> rows})> byDay(List<SessionRow> rows) {
  final groups = <DateTime, List<SessionRow>>{};
  for (final r in rows) {
    final t = DateTime.tryParse(r.when)?.toLocal();
    if (t == null) continue;
    (groups[DateTime(t.year, t.month, t.day)] ??= []).add(r);
  }
  final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final d in days) (day: d, rows: groups[d]!..sort((a, b) => b.when.compareTo(a.when))),
  ];
}

String dayLabel(AppLocalizations l, DateTime day, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  if (day == today) return l.today;
  if (day == today.subtract(const Duration(days: 1))) return l.yesterday;
  return DateFormat.yMMMMEEEEd(l.localeName).format(day);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (app.connected && app.chatAgentId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => app.ensureChatAgent());
    }
    if (app.chatDraft != null && !_opening) {
      _opening = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openNew(app.takeChatDraft()));
    }
  }

  Future<void> _openNew(String? first) async {
    final app = AppScope.read(context);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    if (!app.connected) {
      setState(() => _opening = false);
      messenger.showSnackBar(SnackBar(content: Text(l.connectFromYou)));
      return;
    }
    setState(() => _opening = true);
    final id = await app.newChatSession();
    if (mounted) setState(() => _opening = false);
    if (id == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.openFailed)));
      return;
    }
    final agent = app.agents.where((a) => a.id == app.chatAgentId).firstOrNull;
    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: id, agent: agent, firstMessage: first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        final chatId = app.chatAgentId;
        final rows = chatId == null
            ? const <SessionRow>[]
            : app.live.sessions.where((s) => s.agentId == chatId && !s.archived).toList();
        final days = byDay(rows);
        final agent = app.agents.where((a) => a.id == chatId).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: l.tabChat,
              trailing: app.connected
                  ? TextButton.icon(
                      key: const Key('chat-new'),
                      onPressed: _opening ? null : () => _openNew(null),
                      icon: RgIcon(RgIcons.plus, size: 18, color: c.accent),
                      label: Text(l.chatNew),
                    )
                  : null,
            ),
            Expanded(
              child: days.isEmpty
                  ? EmptyState(icon: RgIcons.chat, text: _opening ? l.loading : l.chatEmpty)
                  : ListView(
                      key: const Key('chat-days'),
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        for (final d in days) ...[
                          Semantics(
                            header: true,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                              child: Text(
                                dayLabel(l, d.day),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.dim,
                                ),
                              ),
                            ),
                          ),
                          for (final r in d.rows)
                            ListTile(
                              key: Key('chat-${r.id}'),
                              leading: RgIcon(
                                r.running ? RgIcons.spinner : RgIcons.chat,
                                color: r.running ? c.ok : c.dim,
                              ),
                              title: Text(
                                r.task ?? (r.title?.isNotEmpty == true ? r.title! : l.untitled),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                DateFormat.Hm(l.localeName)
                                    .format(DateTime.tryParse(r.when)?.toLocal() ?? d.day),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ConversationScreen(sessionId: r.id, agent: agent),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
