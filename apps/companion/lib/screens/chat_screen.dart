// Chat (decision D9, variant 3): the everyday conversations with Chat (the `assistant` agent the
// server makes the first time, `GET /api/chat/agent`), day by day. The field over the bar opens
// a new one at once, with its text as the first message, which also names it (G40.9) unless the
// server has a title for it already. «Salvati» (G40.14) opens from its header.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../api/groups.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/conversation_menu.dart';
import '../ui/icons.dart';
import 'agent_conversations_screen.dart';
import '../desktop/desk_controller.dart';
import 'conversation_screen.dart';
import 'board_screen.dart' show localWhen;
import 'daily_chat_screen.dart';
import 'instructions_screen.dart';
import 'room_screen.dart';
import 'saved_screen.dart';
import '../ui/model_sheet.dart';

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

  /// «Archived (n)» shown instead of the days (3.8.8, as the page's Chats).
  bool _archived = false;

  /// The group chats (G42.3: «Groups» under the chats, as the page's Chats) and the old
  /// everyday chats («Earlier chats», and the ones in a folder).
  List<Room> _rooms = const [];
  List<ChatSummary> _old = const [];
  AppController? _app;

  @override
  void initState() {
    super.initState();
    _app = AppScope.read(context);
    _app!.live.roomsChanged.addListener(_reloadGroups);
    _app!.addListener(_connectedChanged);
    unawaited(_reloadGroups());
  }

  bool _wasConnected = false;

  void _connectedChanged() {
    final now = _app?.connected ?? false;
    if (now && !_wasConnected) unawaited(_reloadGroups());
    _wasConnected = now;
  }

  @override
  void dispose() {
    _app?.live.roomsChanged.removeListener(_reloadGroups);
    _app?.removeListener(_connectedChanged);
    super.dispose();
  }

  Future<void> _reloadGroups() async {
    final c = _app?.client;
    if (c == null) return;
    try {
      final rooms = await c.rooms();
      final old = await c.chats().catchError((_) => const <ChatSummary>[]);
      if (mounted) {
        setState(() {
          _rooms = rooms;
          _old = old;
        });
      }
    } on ApiException {
      // Read again on the next change.
    }
  }

  Future<void> _newGroup() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    try {
      final room = await _app!.client!.createRoom(title: l.cvGroupNew);
      unawaited(_reloadGroups());
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => RoomScreen(roomId: room.id))));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _chatModel() async {
    final l = AppLocalizations.of(context);
    final app = _app!;
    final c = app.client;
    if (c == null) return;
    final models = await app.modelChoices(again: true);
    final current = await c.chatModel().catchError((_) => null);
    if (!mounted || models.isEmpty) return;
    final pick = await showModelPicker(
      context,
      title: l.cvDailyChat,
      models: models,
      current: current,
      inheritLabel: l.cvAgentModelDefault,
    );
    if (pick == null) return;
    try {
      await c.setChatModel(pick.model);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

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
    // In the control room the conversation takes the panel, with its own header (full window, detach,
    // close), instead of being pushed over the list without them (3.8.4).
    final desk = mounted ? DeskScope.maybeRead(context) : null;
    if (desk != null) {
      desk.show(PanelConversation(id, agent: agent, firstMessage: first));
      return;
    }
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
        final all = chatId == null
            ? const <SessionRow>[]
            : app.live.sessions.where((s) => s.agentId == chatId).toList();
        final archivedCount = all.where((s) => s.archived).length;
        final rows = all.where((s) => s.archived == _archived).toList();
        final days = byDay(_archived ? rows : rows.where((r) => r.folder == null).toList());
        final folders = _archived
            ? const <String>[]
            : ({for (final r in rows) ?r.folder, for (final o in _old) ?o.folder}.toList()..sort());
        final earlier = _archived
            ? const <ChatSummary>[]
            : _old.where((o) => o.folder == null).toList();
        final extra = <Widget>[
          for (final f in folders) ...[
            ListHeading(f, icon: RgIcons.folder),
            for (final r in rows.where((r) => r.folder == f))
              SessionTile(
                row: r,
                tileKey: Key('chat-${r.id}'),
                onTap: () => openSessionRow(
                  context,
                  r,
                  agent: app.agents.where((a) => a.id == chatId).firstOrNull,
                ),
              ),
            for (final o in _old.where((o) => o.folder == f))
              _OldChatTile(chat: o, onChanged: _reloadGroups, others: _old),
          ],
          if (earlier.isNotEmpty) ...[
            ListHeading(l.cvChatsBefore, icon: RgIcons.chat),
            for (final o in earlier) _OldChatTile(chat: o, onChanged: _reloadGroups, others: _old),
          ],
        ];
        final groups = _archived
            ? const <Widget>[]
            : <Widget>[
                ListHeading(l.cvGroups, icon: RgIcons.users),
                if (_rooms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
                    child: Text(l.cvGroupsEmpty, style: TextStyle(color: c.dim, fontSize: 13)),
                  ),
                for (final r in _rooms) _RoomTile(room: r),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const Key('chat-new-group'),
                      onPressed: app.connected ? _newGroup : null,
                      icon: RgIcon(RgIcons.plus, size: 16, color: c.accent),
                      label: Text(l.cvGroupNew),
                    ),
                  ),
                ),
              ];
        final toggle = ArchivedToggle(
          count: archivedCount,
          on: _archived,
          onTap: () => setState(() => _archived = !_archived),
        );
        final agent = app.agents.where((a) => a.id == chatId).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: l.tabChat,
              trailing: app.connected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (agent != null)
                          IconButton(
                            key: const Key('chat-instructions'),
                            tooltip: l.cvChatInstructions,
                            onPressed: () => openInstructions(context, agent),
                            icon: RgIcon(RgIcons.edit, size: 20, color: c.text),
                          ),
                        IconButton(
                          key: const Key('chat-model'),
                          tooltip: l.cvAgentModelDefault,
                          onPressed: _chatModel,
                          icon: RgIcon(RgIcons.cpu, size: 20, color: c.text),
                        ),
                        // G40.14: the passages kept from the conversations.
                        IconButton(
                          key: const Key('chat-saved'),
                          tooltip: l.savedTitle,
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const SavedScreen())),
                          icon: RgIcon(RgIcons.bookmark, size: 20, color: c.text),
                        ),
                        TextButton.icon(
                          key: const Key('chat-new'),
                          onPressed: _opening ? null : () => _openNew(null),
                          icon: RgIcon(RgIcons.plus, size: 18, color: c.accent),
                          // Room for «Salvati» beside it on a narrow phone.
                          label: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(l.chatNew, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: days.isEmpty && extra.isEmpty && (_archived || _rooms.isEmpty)
                  ? Column(
                      children: [
                        Expanded(
                          child: EmptyState(
                            icon: _archived ? RgIcons.archive : RgIcons.chat,
                            text: _opening
                                ? l.loading
                                : _archived
                                ? l.cmEmptyArchived
                                : l.chatEmpty,
                          ),
                        ),
                        toggle,
                      ],
                    )
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
                            SessionTile(
                              row: r,
                              tileKey: Key('chat-${r.id}'),
                              onTap: () => openSessionRow(context, r, agent: agent),
                            ),
                        ],
                        ...extra,
                        toggle,
                        ...groups,
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A chat of the old everyday Chat: opens in its own screen; the menu moves it to a folder.
class _OldChatTile extends StatelessWidget {
  const _OldChatTile({required this.chat, required this.onChanged, this.others = const []});

  final ChatSummary chat;

  /// The other old chats (their folders are offered too).
  final List<ChatSummary> others;
  final Future<void> Function() onChanged;

  Future<void> _folder(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final folders = {
      for (final s in app.live.sessions)
        if (s.agentId == app.chatAgentId && s.folder != null) s.folder!,
      for (final o in others) ?o.folder,
    }.toList()..sort();
    final name = await askFolder(
      context,
      folders: folders,
      current: chat.folder,
      subtitle: chat.title,
    );
    if (name == null) return;
    try {
      await app.client?.setChatFolder(chat.id, name.isEmpty ? null : name);
      await onChanged();
    } on ApiException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.cmFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    return ListTile(
      key: Key('old-chat-${chat.id}'),
      leading: RgIcon(RgIcons.chat, size: 18, color: c.dim),
      title: Text(
        chat.title.isEmpty ? l.cvNewChat : chat.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(localWhen(chat.updatedAt, locale)),
      trailing: IconButton(
        key: Key('old-chat-folder-${chat.id}'),
        tooltip: l.cvFolderMove,
        onPressed: () => _folder(context),
        icon: RgIcon(RgIcons.folder, size: 16, color: c.dim),
      ),
      onTap: () => openDailyChat(context, chat: chat).whenComplete(onChanged),
    );
  }
}

/// A group chat in the list: its title, its members' faces, a dot while someone answers.
class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    final names = [
      for (final m in room.members) ?app.agents.where((a) => a.id == m.agentId).firstOrNull?.name,
    ];
    return ListTile(
      key: Key('room-tile-${room.id}'),
      leading: RgIcon(RgIcons.users, size: 18, color: c.dim),
      title: Text(room.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: names.isEmpty
          ? null
          : Text(names.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: room.answering.isEmpty
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.ok, shape: BoxShape.circle),
            ),
      onTap: () => openRoom(context, room.id),
    );
  }
}
