// The old everyday chats and a project's inspector (G42.3), as the page's DailyChat.tsx: the
// exchanges of one chat (the person's message, the answer with its reasoning folded, the searches
// and pages it used as chips, the answer in Markdown), a field to go on, and in the header the
// Chat's model (`/api/chat/settings`: it counts from the next message), «Go on as a group» (a group
// chat with this one as context) and «Delete» for good. The inspector has its conversations to
// choose from and «New chat». The answer comes as server-sent events, read once it is over.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/groups.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/chat/simple_composer.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import '../ui/model_sheet.dart';
import '../ui/rg_menu.dart';
import 'project_board_screen.dart' show localWhen;
import 'conversation_screen.dart' show MaxWidthCenter;
import 'room_screen.dart';

Future<void> openDailyChat(
  BuildContext context, {
  ChatSummary? chat,
  String? projectId,
  String? projectName,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => DailyChatScreen(chat: chat, projectId: projectId, projectName: projectName),
  ),
);

class DailyChatScreen extends StatefulWidget {
  const DailyChatScreen({super.key, this.chat, this.projectId, this.projectName});

  /// The chat opened (null: a new one, made with the first message).
  final ChatSummary? chat;

  /// A project's inspector instead of the everyday Chat.
  final String? projectId;
  final String? projectName;

  @override
  State<DailyChatScreen> createState() => _DailyChatScreenState();
}

class _DailyChatScreenState extends State<DailyChatScreen> {
  late final AppController app = AppScope.read(context);
  late ChatSummary? _chat = widget.chat;
  List<ChatEntry> _entries = const [];
  List<ChatSummary> _list = const [];
  String? _pending;
  bool _sending = false;
  String? _note;

  bool get _inspector => widget.projectId != null;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final c = app.client;
    if (c == null) return;
    try {
      if (_inspector) {
        final list = await c.chats(projectId: widget.projectId);
        if (!mounted) return;
        setState(() {
          _list = list;
          _chat ??= list.firstOrNull;
        });
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<void> _load() async {
    final id = _chat?.id;
    if (id == null) {
      if (mounted) setState(() => _entries = const []);
      return;
    }
    try {
      final e = await app.client?.chatEntries(id);
      if (mounted && e != null && _chat?.id == id) setState(() => _entries = e);
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<bool> _send(String text) async {
    final c = app.client;
    if (c == null) return false;
    setState(() {
      _sending = true;
      _pending = text;
      _note = null;
    });
    try {
      final chat = _chat ??= await c.newChat(projectId: widget.projectId);
      final err = await c.sendChat(chat.id, text);
      await _load();
      if (mounted) setState(() => _note = err);
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _pending = null;
        });
      }
    }
  }

  Future<void> _model() async {
    final l = AppLocalizations.of(context);
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
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<void> _toGroup() async {
    final l = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    final who = await pickJoinable(context, app, inChat: const {}, title: l.cvChatToGroup);
    if (who == null) return;
    final context0 = [
      for (final e in _entries)
        if (e.shown && e.text.trim().isNotEmpty)
          '${e.role == 'user' ? 'User' : 'Assistant'}: ${e.text.trim()}',
    ].join('\n\n');
    try {
      final room = await app.client!.createRoom(
        members: [who],
        context: context0.length > 60000 ? context0.substring(context0.length - 60000) : context0,
      );
      unawaited(nav.push(MaterialPageRoute<void>(builder: (_) => RoomScreen(roomId: room.id))));
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final id = _chat?.id;
    if (id == null) return;
    final nav = Navigator.of(context);
    if (!await askConfirm(
      context,
      title: l.cvDelete,
      body: l.cvDeleteChatConfirm,
      yes: l.cvDelete,
      danger: true,
    )) {
      return;
    }
    try {
      await app.client?.deleteChat(id);
      if (_inspector) {
        setState(() => _chat = null);
        await _start();
      } else {
        nav.pop();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<void> _pickConversation() async {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final pick = await showRgSheet<String>(
      context,
      key: const Key('inspector-chats'),
      head: RgSheetHead(
        leading: RgIcon(RgIcons.list, size: 22, color: c.dim),
        title: l.cvConversations,
      ),
      entries: [
        RgMenuEntry('', RgIcons.plus, l.cvNewChat, key: const Key('inspector-new')),
        if (_list.isNotEmpty) null,
        for (final x in _list)
          RgMenuEntry(
            x.id,
            x.id == _chat?.id ? RgIcons.check : RgIcons.chat,
            '${x.title} · ${localWhen(x.createdAt, locale)}',
            key: Key('inspector-chat-${x.id}'),
          ),
      ],
    );
    if (pick == null || !mounted) return;
    setState(() {
      _chat = pick.isEmpty ? null : _list.where((x) => x.id == pick).firstOrNull;
      _entries = const [];
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final title = _inspector
        ? '${l.cvInspector} · ${widget.projectName ?? ''}'
        : (_chat?.title.isNotEmpty ?? false)
        ? _chat!.title
        : l.cvNewChat;
    final shown = [
      for (final e in _entries)
        if (e.shown) e,
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('daily-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            RgIcon(_inspector ? RgIcons.search : RgIcons.chat, size: 18, color: c.dim),
            const SizedBox(width: 8),
            Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          if (_inspector)
            IconButton(
              key: const Key('daily-conversations'),
              tooltip: l.cvConversations,
              onPressed: _pickConversation,
              icon: RgIcon(RgIcons.list, size: 20, color: c.text),
            )
          else
            IconButton(
              key: const Key('daily-model'),
              tooltip: l.cvAgentModelDefault,
              onPressed: _model,
              icon: RgIcon(RgIcons.cpu, size: 20, color: c.text),
            ),
          if (_entries.isNotEmpty)
            IconButton(
              key: const Key('daily-group'),
              tooltip: l.cvChatToGroup,
              onPressed: _toGroup,
              icon: RgIcon(RgIcons.users, size: 20, color: c.text),
            ),
          if (_chat != null)
            IconButton(
              key: const Key('daily-delete'),
              tooltip: l.cvDelete,
              onPressed: _delete,
              icon: RgIcon(RgIcons.trash, size: 20, color: c.text),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('daily-entries'),
              reverse: true,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              children: [
                if (_pending != null) ...[
                  MaxWidthCenter(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(l.cvThinking, style: TextStyle(color: c.dim, fontSize: 13.5)),
                      ),
                    ),
                  ),
                  MaxWidthCenter(child: _UserLine(text: _pending!)),
                ],
                for (final e in shown.reversed)
                  MaxWidthCenter(
                    child: e.role == 'user' ? _UserLine(text: e.text) : _Answer(entry: e),
                  ),
                if (shown.isEmpty && _pending == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                    child: Column(
                      children: [
                        RgIcon(_inspector ? RgIcons.search : RgIcons.chat, size: 40, color: c.dim),
                        const SizedBox(height: 12),
                        Text(
                          _inspector ? l.cvInspectorHint : l.cvChatHint,
                          key: const Key('daily-hint'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: c.dim, fontSize: 14.5),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_note != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(_note!, style: TextStyle(color: c.err, fontSize: 13)),
            ),
          SafeArea(
            top: false,
            child: MaxWidthCenter(
              child: SimpleComposer(
                fieldKey: const Key('daily-text'),
                sendKey: const Key('daily-send'),
                hint: l.cvChatPlaceholder,
                sending: _sending,
                onSend: _send,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserLine extends StatelessWidget {
  const _UserLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 640),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.user,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.accent),
        ),
        child: SelectableText(text, style: TextStyle(color: c.text, fontSize: 15)),
      ),
    );
  }
}

class _Answer extends StatefulWidget {
  const _Answer({required this.entry});

  final ChatEntry entry;

  @override
  State<_Answer> createState() => _AnswerState();
}

class _AnswerState extends State<_Answer> {
  bool _thinking = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final e = widget.entry;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: Key('daily-answer-${e.id}'),
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(maxWidth: 860),
        padding: const EdgeInsets.symmetric(vertical: 4),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            if (e.thinking.isNotEmpty) ...[
              InkWell(
                onTap: () => setState(() => _thinking = !_thinking),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RgIcon(
                      _thinking ? RgIcons.chevronDown : RgIcons.chevronRight,
                      size: 13,
                      color: c.dim,
                    ),
                    const SizedBox(width: 4),
                    Text(l.cvThinking, style: TextStyle(color: c.dim, fontSize: 13)),
                  ],
                ),
              ),
              if (_thinking) Text(e.thinking, style: TextStyle(color: c.dim, fontSize: 13)),
            ],
            if (e.tools.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in e.tools)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.panel2,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RgIcon(
                            t.name == 'web_search' ? RgIcons.search : RgIcons.file,
                            size: 12,
                            color: c.dim,
                          ),
                          const SizedBox(width: 5),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Text(
                              t.what.isEmpty ? t.name : t.what,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.dim, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (e.text.isNotEmpty) SafeMarkdown(e.text, reading: true),
          ],
        ),
      ),
    );
  }
}
