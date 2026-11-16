// «Share to RedGiant» (G40.10): what another app shared (text, a link, photos, files) goes to the
// Chat (a new conversation) or to an agent (its usual one), with a note, as the composer sends
// it: photos as images, small text files inside the message, the rest saved in the agent's
// workspace (`packMessage`).
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../api/attachments.dart';
import '../api/client.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../share/share_intake.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'conversation_screen.dart';

/// Where it goes: the Chat, or one agent.
const kShareToChat = '';

/// The message the shared things make, with the person's [note] first.
String sharedText(String note, List<SharedItem> items) {
  final parts = [
    if (note.trim().isNotEmpty) note.trim(),
    for (final i in items)
      if (!i.isFile && (i.text ?? '').trim().isNotEmpty) i.text!.trim(),
  ];
  return parts.join('\n\n');
}

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.items, this.readFile});

  final List<SharedItem> items;

  /// Reads a shared file (tests give their own).
  final Future<List<int>> Function(String path)? readFile;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  late final AppController app;
  final _note = TextEditingController();
  String _to = kShareToChat;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<List<int>> _read(String path) => widget.readFile?.call(path) ?? File(path).readAsBytes();

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final c = app.client;
    if (c == null) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final agent = _to == kShareToChat
          ? app.chatAgent
          : app.agents.where((a) => a.id == _to).firstOrNull;
      final attached = <Attached>[];
      for (final i in widget.items.where((i) => i.isFile && i.path != null)) {
        final bytes = await _read(i.path!);
        final a = classify(i.name, Uint8List.fromList(bytes), mimeType: i.mimeType);
        if (a == null) {
          setState(() => _error = l.attachmentTooBig(i.name));
          return;
        }
        attached.add(a);
      }
      final text = sharedText(_note.text, widget.items);
      final packed = await packMessage(
        text.isEmpty ? l.attachmentOnly : text,
        attached.take(kMaxAttached).toList(),
        upload: (path, bytes) => c.writeFile(attachmentScope(agent), path, bytes),
        notSent: l.attachmentNotSent,
      );
      final sid = _to == kShareToChat
          ? await app.newChatSession()
          : (agent == null ? null : await app.openAgent(agent));
      if (sid == null) {
        setState(() => _error = l.sendFailed);
        return;
      }
      final ok = await app.send(sid, packed.text, images: packed.images);
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = l.sendFailed);
        return;
      }
      app.shareHandled();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(sessionId: sid, agent: agent),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = l.errGeneric(e.message));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final targets = [
      for (final a in app.agents)
        if (a.active && a.id != app.chatAgentId) a,
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('share-cancel'),
          tooltip: l.cancel,
          onPressed: () {
            app.shareHandled();
            Navigator.of(context).pop();
          },
          icon: RgIcon(RgIcons.x, color: c.text),
        ),
        title: Text(l.shareTitle),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('share-list'),
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    if (_error != null) NoticeBanner(text: _error!, error: true),
                    SectionHead(l.shareWhat),
                    SettingsCard(
                      key: const Key('share-items'),
                      children: [for (final i in widget.items) _ItemLine(item: i)],
                    ),
                    SectionHead(l.shareTo),
                    SettingsCard(
                      key: const Key('share-targets'),
                      children: [
                        PickRow(
                          key: const Key('share-to-chat'),
                          leading: RgIcon(RgIcons.chat, color: c.accent),
                          title: l.tabChat,
                          subtitle: l.shareToChatHint,
                          selected: _to == kShareToChat,
                          onTap: () => setState(() => _to = kShareToChat),
                        ),
                        for (final a in targets)
                          PickRow(
                            key: Key('share-to-${a.id}'),
                            leading: MascotView(
                              agentId: a.id,
                              spec: a.mascot,
                              state: MascotState.idle,
                              size: 30,
                              label: a.name,
                            ),
                            title: a.name,
                            subtitle: a.role,
                            selected: _to == a.id,
                            onTap: () => setState(() => _to = a.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: c.bg,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('share-note'),
                          controller: _note,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(hintText: l.shareNoteHint, isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        key: const Key('share-send'),
                        onPressed: _sending || app.client == null ? null : _send,
                        icon: const RgIcon(RgIcons.send, size: 17, color: Colors.white),
                        label: Text(l.composerSend),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item});

  final SharedItem item;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final icon = switch (item.kind) {
      SharedKind.text => RgIcons.edit,
      SharedKind.url => RgIcons.link,
      SharedKind.image => RgIcons.image,
      SharedKind.file => RgIcons.file,
    };
    final text = item.isFile ? item.name : (item.text ?? '').trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RgIcon(icon, size: 18, color: c.dim),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c.text, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
