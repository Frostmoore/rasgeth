// A group chat (G42.3), as the page's Room.tsx: several agents in one chat. On top the members
// (mascot, name, «answers first» for the first, what its answers cost and how full its context
// is, «x» to take one out) and «Add an agent» (the person's own agents, then every project's lead,
// agents and inspector). The messages: the person's, each agent's with its face and name, the
// joins and leaves in small centred notes. The first member answers, or whoever is called with
// @name (the composer suggests the members after «@»). It reads the room again on `room.changed`.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../api/groups.dart';
import '../api/metrics.dart' show usd;
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/chat/simple_composer.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import '../ui/rg_menu.dart';
import 'conversation_screen.dart' show MaxWidthCenter;

/// At most six agents in a group (the server's `MAX_MEMBERS`).
const maxRoomMembers = 6;

Future<void> openRoom(BuildContext context, String roomId) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => RoomScreen(roomId: roomId)));

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  late final AppController app = AppScope.read(context);
  Room? _room;
  List<RoomLine> _lines = const [];
  bool _gone = false;
  bool _loaded = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    app.live.roomsChanged.addListener(_changed);
    unawaited(_load());
  }

  @override
  void dispose() {
    app.live.roomsChanged.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final id = app.live.lastRoom;
    if (id == null || id == widget.roomId) unawaited(_load());
  }

  Future<void> _load() async {
    final c = app.client;
    if (c == null) return;
    try {
      final rooms = await c.rooms();
      final room = rooms.where((r) => r.id == widget.roomId).firstOrNull;
      final events = room == null ? const <RgEvent>[] : await c.roomEvents(widget.roomId);
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _room = room;
        _gone = room == null;
        _lines = [for (final e in events) ?RoomLine.fromEvent(e)];
      });
    } on ApiException {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<bool> _send(String text) async {
    final c = app.client;
    if (c == null) return false;
    try {
      await c.postRoom(widget.roomId, text);
      if (mounted) setState(() => _note = null);
      unawaited(_load());
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
      return false;
    }
  }

  Future<void> _remove(String agentId) async {
    try {
      await app.client?.removeRoomMember(widget.roomId, agentId);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final room = _room;
    if (room == null) return;
    final pick = await pickJoinable(
      context,
      app,
      inChat: {for (final m in room.members) m.agentId},
      title: l.cvRoomPick,
    );
    if (pick == null || !mounted) return;
    try {
      await app.client?.addRoomMember(widget.roomId, pick);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final room = _room;
    String nameOf(String id) => app.agents.where((a) => a.id == id).firstOrNull?.name ?? '';
    final answering = room == null
        ? const <String>[]
        : [for (final id in room.answering) nameOf(id)];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('room-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            RgIcon(RgIcons.users, size: 18, color: c.dim),
            const SizedBox(width: 8),
            Expanded(child: Text(room?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: !_loaded
          ? Center(
              child: Text(l.loading, style: TextStyle(color: c.dim)),
            )
          : _gone
          ? Center(
              child: Text(
                l.cvRoomGone,
                key: const Key('room-gone'),
                style: TextStyle(color: c.dim),
              ),
            )
          : Column(
              children: [
                _Members(room: room!, onRemove: _remove, onAdd: _add),
                Expanded(
                  child: ListView(
                    key: const Key('room-lines'),
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    children: [
                      if (answering.isNotEmpty)
                        MaxWidthCenter(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              decoration: BoxDecoration(
                                color: c.panel,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.line),
                              ),
                              child: Text(
                                l.cvRoomAnswering(answering.join(', ')),
                                key: const Key('room-answering'),
                                style: TextStyle(color: c.dim, fontSize: 13.5),
                              ),
                            ),
                          ),
                        ),
                      for (final line in _lines.reversed)
                        MaxWidthCenter(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _Line(line: line),
                          ),
                        ),
                      if (_lines.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                          child: Text(
                            l.cvRoomEmpty,
                            key: const Key('room-empty'),
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.dim, fontSize: 14),
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
                      fieldKey: const Key('room-text'),
                      sendKey: const Key('room-send'),
                      hint: l.cvRoomWrite,
                      mentions: mentionNames(room, app.agents),
                      onSend: _send,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// «Add an agent»: the agents a group can take, under their groups (the page's select with its
/// optgroups), in our sheet. The id picked (or `inspector:<projectId>`), or null.
Future<String?> pickJoinable(
  BuildContext context,
  AppController app, {
  required Set<String> inChat,
  required String title,
}) {
  final l = AppLocalizations.of(context);
  final c = RgColors.of(context);
  final options = joinable(
    app.agents,
    app.projects,
    inChat: inChat,
    lead: l.cvRoomLead,
    inspector: l.cvRoomInspector,
  );
  final entries = <RgMenuEntry<String>?>[];
  String? group = '';
  for (final o in options) {
    if (o.project != group) {
      if (entries.isNotEmpty) entries.add(null);
      group = o.project;
    }
    entries.add(
      RgMenuEntry(
        o.id,
        o.project == null ? RgIcons.user : (o.agentId == null ? RgIcons.search : RgIcons.users),
        o.project == null ? o.name : '${o.name} · ${o.project}',
        key: Key('room-pick-${o.id}'),
      ),
    );
  }
  return showRgSheet<String>(
    context,
    key: const Key('room-pick'),
    head: RgSheetHead(
      leading: RgIcon(RgIcons.userPlus, size: 22, color: c.dim),
      title: l.cvRoomAdd,
      subtitle: title,
    ),
    entries: entries,
  );
}

class _Members extends StatelessWidget {
  const _Members({required this.room, required this.onRemove, required this.onAdd});

  final Room room;
  final void Function(String agentId) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('room-head'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, m) in room.members.indexed)
            Builder(
              builder: (context) {
                final a = app.agents.where((x) => x.id == m.agentId).firstOrNull;
                final usage = [
                  if (m.costUsd != null) usd(m.costUsd!),
                  if (m.context != null) '${(m.context! * 100).round()}%',
                ].join(' · ');
                return Tooltip(
                  message: usage.isEmpty ? '' : l.cvRoomUsageHint,
                  child: Container(
                    key: Key('room-member-${m.agentId}'),
                    padding: const EdgeInsets.fromLTRB(4, 3, 4, 3),
                    decoration: BoxDecoration(
                      color: c.panel2,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (a != null)
                          MascotView(agentId: a.id, state: app.live.mascotStateOf(a.id), size: 20)
                        else
                          RgIcon(RgIcons.user, size: 14, color: c.dim),
                        const SizedBox(width: 6),
                        Text(a?.name ?? m.agentId, style: TextStyle(color: c.text, fontSize: 13)),
                        if (i == 0)
                          Text(' · ${l.cvRoomFirst}', style: TextStyle(color: c.dim, fontSize: 12)),
                        if (usage.isNotEmpty)
                          Text(' · $usage', style: TextStyle(color: c.dim, fontSize: 12)),
                        if (room.members.length > 1)
                          Tooltip(
                            message: l.cvRoomRemove(a?.name ?? ''),
                            child: InkWell(
                              key: Key('room-remove-${m.agentId}'),
                              customBorder: const CircleBorder(),
                              onTap: () => onRemove(m.agentId),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: RgIcon(RgIcons.x, size: 11, color: c.dim),
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 4),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (room.members.length < maxRoomMembers)
            TextButton.icon(
              key: const Key('room-add'),
              onPressed: onAdd,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              icon: RgIcon(RgIcons.plus, size: 14, color: c.accent),
              label: Text(l.cvRoomAdd, style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line});

  final RoomLine line;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (line.note) {
      final text = line.change == 'added'
          ? l.cvRoomJoined(line.name)
          : line.change == 'removed'
          ? l.cvRoomLeft(line.name)
          : line.text;
      return Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.dim, fontSize: 12),
        ),
      );
    }
    if (line.human) {
      return Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.user,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.accent),
            ),
            child: SelectableText(line.text, style: TextStyle(color: c.text, fontSize: 15)),
          ),
        ),
      );
    }
    final a = app.agents.where((x) => x.id == line.from).firstOrNull;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: Key('room-msg-${line.seq}'),
        constraints: const BoxConstraints(maxWidth: 860),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (a != null) ...[
                  MascotView(agentId: a.id, state: app.live.mascotStateOf(a.id), size: 20),
                  const SizedBox(width: 6),
                ],
                Text(
                  line.name.isNotEmpty ? line.name : (a?.name ?? ''),
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SafeMarkdown(line.text),
          ],
        ),
      ),
    );
  }
}
