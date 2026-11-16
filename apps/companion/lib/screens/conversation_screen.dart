// One conversation (G40.7): its history, the answer streaming in, the reasoning folded, the
// tools' calls, the files and canvases the agent showed, and the composer with attachments as
// the page's (photos, text files, the rest saved in the workspace), «press and talk» and the
// answers read aloud (G40.10). The same messages as the page: `session.follow` (history in one
// go), `session.send`, `session.interrupt`.
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/attachments.dart';
import '../api/client.dart';
import '../api/conversation.dart';
import '../api/live_model.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import '../ui/words.dart';
import 'canvas_screen.dart';
import 'conversation_more.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.sessionId, this.agent, this.firstMessage});

  final String sessionId;
  final Agent? agent;

  /// Sent as soon as the conversation opens (the Chat's field over the bar).
  final String? firstMessage;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final AppController app;
  late final SessionView view;
  final _text = TextEditingController();
  final _attached = <Attached>[];
  bool _sending = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
    view = app.follow(widget.sessionId);
    final first = widget.firstMessage;
    if (first != null && first.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(text: first));
    }
  }

  @override
  void dispose() {
    app.unfollow(widget.sessionId);
    // A voice failure belongs to this conversation (told after the tree is unlocked).
    final v = app.voice;
    scheduleMicrotask(() {
      v.clearProblem();
      unawaited(v.stopSpeaking());
    });
    _text.dispose();
    super.dispose();
  }

  Agent? get _agent =>
      widget.agent ??
      app.agents
          .where(
            (a) =>
                a.id ==
                app.live.sessions.where((s) => s.id == widget.sessionId).firstOrNull?.agentId,
          )
          .firstOrNull;

  Future<void> _send({String? text}) async {
    final l = AppLocalizations.of(context);
    final t = (text ?? _text.text).trim();
    if (t.isEmpty && _attached.isEmpty) return;
    setState(() => _sending = true);
    final c = app.client;
    var ok = false;
    try {
      final packed = await packMessage(
        t.isEmpty ? l.attachmentOnly : t,
        List.of(_attached),
        upload: c == null
            ? null
            : (path, bytes) => c.writeFile(attachmentScope(_agent), path, bytes),
        notSent: l.attachmentNotSent,
      );
      ok = await app.send(widget.sessionId, packed.text, images: packed.images);
    } on ApiException {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        if (text == null) _text.clear();
        _attached.clear();
        _note = null;
      } else {
        _note = l.sendFailed;
      }
    });
  }

  Future<void> _attach() async {
    final l = AppLocalizations.of(context);
    final files = await FilePicker.pickFiles();
    for (final f in files) {
      if (_attached.length >= kMaxAttached) break;
      final a = classify(f.name, await f.readAsBytes());
      if (a == null) {
        setState(() => _note = l.attachmentTooBig(f.name));
        continue;
      }
      setState(() => _attached.add(a));
    }
  }

  // ---- press and talk (G40.10) ----

  String get _lang => app.locale?.languageCode ?? Localizations.localeOf(context).languageCode;

  Future<void> _talkStart() async {
    final l = AppLocalizations.of(context);
    setState(() => _note = null);
    await app.voice.startRecording(l);
  }

  Future<void> _talkEnd() async {
    final l = AppLocalizations.of(context);
    final text = await app.voice.stopAndTranscribe(l, _lang);
    if (!mounted || text == null) return;
    final now = _text.text.trimRight();
    _text.text = now.isEmpty ? text : '$now $text';
    _text.selection = TextSelection.collapsed(offset: _text.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final agent =
        widget.agent ??
        app.agents
            .where(
              (a) =>
                  a.id ==
                  app.live.sessions.where((s) => s.id == widget.sessionId).firstOrNull?.agentId,
            )
            .firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ListenableBuilder(
              listenable: Listenable.merge([app.live, view]),
              builder: (context, _) {
                final state = agent == null ? MascotState.idle : app.live.mascotStateOf(agent.id);
                return _Header(
                  agent: agent,
                  state: state,
                  running: view.running,
                  onStop: () => app.interrupt(widget.sessionId),
                );
              },
            ),
            if (!app.isLive)
              Container(
                width: double.infinity,
                color: c.panel2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(l.notLive, style: TextStyle(color: c.dim, fontSize: 13)),
              ),
            Expanded(
              child: ListenableBuilder(
                listenable: view,
                builder: (context, _) {
                  final items = view.items;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        view.synced || !app.isLive ? l.conversationEmpty : l.loading,
                        style: TextStyle(color: c.dim),
                      ),
                    );
                  }
                  return ListView.builder(
                    key: const Key('conversation-items'),
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    itemCount: items.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ChatItemView(item: items[items.length - 1 - i]),
                    ),
                  );
                },
              ),
            ),
            if (_note != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(_note!, style: TextStyle(color: c.err, fontSize: 13)),
              ),
            ListenableBuilder(
              listenable: app.voice,
              builder: (context, _) {
                final v = app.voice;
                final text = v.recording
                    ? l.voiceListening
                    : v.transcribing
                    ? l.voiceWriting
                    : v.problem;
                if (text == null) return const SizedBox.shrink();
                return Padding(
                  key: const Key('voice-line'),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      RgIcon(
                        v.recording
                            ? RgIcons.mic
                            : (v.transcribing ? RgIcons.spinner : RgIcons.alert),
                        size: 15,
                        color: v.recording
                            ? c.err
                            : (v.problem != null && !v.transcribing ? c.err : c.dim),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            color: v.problem != null && !v.recording && !v.transcribing
                                ? c.err
                                : c.dim,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_attached.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final (i, a) in _attached.indexed)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InputChip(
                          avatar: RgIcon(
                            a is AttachedImage ? RgIcons.image : RgIcons.file,
                            size: 16,
                            color: c.dim,
                          ),
                          label: Text(a.name, overflow: TextOverflow.ellipsis),
                          deleteButtonTooltipMessage: l.attachmentRemove,
                          deleteIcon: RgIcon(RgIcons.x, size: 14, color: c.dim),
                          onDeleted: () => setState(() => _attached.removeAt(i)),
                        ),
                      ),
                  ],
                ),
              ),
            ListenableBuilder(
              listenable: Listenable.merge([app, app.live]),
              builder: (context, _) => _Composer(
                controller: _text,
                sending: _sending,
                onAttach: _attach,
                onSend: _send,
                onTalkStart: _talkStart,
                onTalkEnd: _talkEnd,
                onTalkCancel: () => unawaited(app.voice.cancelRecording()),
                onTalkTap: () =>
                    setState(() => _note = AppLocalizations.of(context).voiceHoldToTalk),
                changed: moreChanged(app, widget.sessionId, agent),
                onMore: () =>
                    showMoreSheet(context, sessionId: widget.sessionId, agent: agent, view: view),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.agent,
    required this.state,
    required this.running,
    required this.onStop,
  });

  final Agent? agent;
  final MascotState state;
  final bool running;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final word = stateWord(l, state);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
      child: Row(
        children: [
          IconButton(
            key: const Key('conversation-back'),
            tooltip: l.back,
            onPressed: () => Navigator.maybePop(context),
            icon: RgIcon(RgIcons.arrowLeft, color: c.text),
          ),
          if (a != null)
            MascotView(
              agentId: a.id,
              spec: a.mascot,
              state: state,
              size: 36,
              label: l.mascotLabel(a.name, word),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a?.name ?? l.tabChat,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5, color: c.text),
                ),
                Text(word, style: TextStyle(fontSize: 12.5, color: c.dim)),
              ],
            ),
          ),
          if (running)
            TextButton.icon(
              key: const Key('conversation-stop'),
              onPressed: onStop,
              icon: RgIcon(RgIcons.stop, size: 16, color: c.err),
              label: Text(l.stop, style: TextStyle(color: c.err)),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onAttach,
    required this.onSend,
    required this.onMore,
    required this.onTalkStart,
    required this.onTalkEnd,
    required this.onTalkCancel,
    required this.onTalkTap,
    this.changed = false,
  });

  /// «Press and talk»: held down it records, let go it writes down (G40.10).
  final VoidCallback onTalkStart;
  final VoidCallback onTalkEnd;
  final VoidCallback onTalkCancel;

  /// A short tap: how to use it.
  final VoidCallback onTalkTap;

  /// The «…»: mode, model, meanwhile, summarise, add an agent.
  final VoidCallback onMore;

  /// Something is not as it starts: a mark on the «…».
  final bool changed;

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('composer-attach'),
            tooltip: l.attach,
            onPressed: onAttach,
            icon: RgIcon(RgIcons.paperclip, size: 20, color: c.dim),
          ),
          Expanded(
            child: TextField(
              key: const Key('composer-text'),
              controller: controller,
              minLines: 1,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(hintText: l.composerAgentHint, isDense: true),
            ),
          ),
          const SizedBox(width: 2),
          _TalkButton(
            onStart: onTalkStart,
            onEnd: onTalkEnd,
            onCancel: onTalkCancel,
            onTap: onTalkTap,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                key: const Key('composer-more'),
                tooltip: changed ? l.moreChanged : l.more,
                onPressed: onMore,
                icon: RgIcon(RgIcons.more, size: 22, color: c.dim, filled: true),
              ),
              if (changed)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    key: const Key('composer-more-mark'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          Semantics(
            button: true,
            label: l.composerSend,
            child: Material(
              color: sending ? c.dim : c.accent,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('composer-send'),
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(child: RgIcon(RgIcons.send, size: 19, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One item of a conversation.
class ChatItemView extends StatelessWidget {
  const ChatItemView({super.key, required this.item});

  final ChatItem item;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final split = switch (item) {
      UserItem(:final text) => splitAttachments(text),
      _ => (text: '', files: const <({String name, String? path})>[]),
    };
    return switch (item) {
      UserItem(:final images, :final from) => Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: c.user, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (from != null)
                Text(l.fromSomeone(from), style: TextStyle(color: c.dim, fontSize: 12)),
              if (split.text.trim().isNotEmpty)
                SelectableText(split.text, style: TextStyle(color: c.text, fontSize: 15)),
              for (final f in split.files)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RgIcon(RgIcons.file, size: 14, color: c.dim),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          f.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.dim, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              if (images > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RgIcon(RgIcons.image, size: 14, color: c.dim),
                      const SizedBox(width: 4),
                      Text(l.imagesCount(images), style: TextStyle(color: c.dim, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      AssistantItem() => AssistantView(item: item as AssistantItem),
      ToolItem() => ToolView(item: item as ToolItem),
      NoticeItem(:final level, :final text) => Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: switch (level) {
              NoticeLevel.error => c.err,
              NoticeLevel.warn => c.warnText,
              NoticeLevel.ok => c.ok,
              NoticeLevel.info => c.dim,
            },
          ),
        ),
      ),
      CanvasItem(:final title, :final scope, :final path, :final isFile) => _FileCard(
        title: title.isEmpty ? (path ?? '') : title,
        subtitle: path ?? '',
        onOpen: isFile && scope != null && path != null
            ? () => openCanvas(context, scope: scope, path: path, title: title)
            : null,
      ),
      FileItem(:final scope, :final path, :final name, :final caption) => _FileCard(
        title: name,
        subtitle: caption ?? path,
        onOpen: () => openCanvas(context, scope: scope, path: path, title: name),
      ),
    };
  }
}

/// The agent's answer: the reasoning folded above it, the text as safe Markdown.
class AssistantView extends StatefulWidget {
  const AssistantView({super.key, required this.item});

  final AssistantItem item;

  @override
  State<AssistantView> createState() => _AssistantViewState();
}

class _AssistantViewState extends State<AssistantView> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final it = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (it.thinking.isNotEmpty)
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              key: const Key('thinking-toggle'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RgIcon(
                      _open ? RgIcons.chevronDown : RgIcons.chevronRight,
                      size: 16,
                      color: c.dim,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      it.live && it.text.isEmpty ? l.reasoningNow : l.reasoning,
                      style: TextStyle(color: c.dim, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (_open && it.thinking.isNotEmpty)
          Container(
            key: const Key('thinking-text'),
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.line, width: 2)),
            ),
            child: SelectableText(it.thinking, style: TextStyle(color: c.dim, fontSize: 13.5)),
          ),
        if (it.text.isNotEmpty) SafeMarkdown(it.text),
        if (it.live && it.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l.writing, style: TextStyle(color: c.dim, fontSize: 12)),
          ),
        if (!it.live && it.text.trim().isNotEmpty) _ReadAloud(id: 'a-${it.ts}', text: it.text),
      ],
    );
  }
}

class ToolView extends StatefulWidget {
  const ToolView({super.key, required this.item});

  final ToolItem item;

  @override
  State<ToolView> createState() => _ToolViewState();
}

class _ToolViewState extends State<ToolView> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final it = widget.item;
    final out = it.output ?? '';
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  RgIcon(RgIcons.tool, size: 15, color: c.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      it.tool,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.text),
                    ),
                  ),
                  Text(
                    it.ok == null ? l.toolRunning : (it.ok! ? l.toolOk : l.toolFailed),
                    style: TextStyle(
                      fontSize: 12,
                      color: it.ok == null ? c.dim : (it.ok! ? c.ok : c.err),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: SelectableText(
                '${const JsonEncoder.withIndent('  ').convert(it.input)}\n\n${out.length > 4000 ? '${out.substring(0, 4000)}…' : out}',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.dim),
              ),
            ),
        ],
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.title, required this.subtitle, required this.onOpen});

  final String title;
  final String subtitle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Material(
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.line),
      ),
      child: ListTile(
        dense: true,
        leading: RgIcon(RgIcons.file, color: c.dim),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: onOpen == null ? null : Text(l.open, style: TextStyle(color: c.accent)),
        onTap: onOpen,
      ),
    );
  }
}

/// «Press and talk»: the microphone, held down while speaking.
class _TalkButton extends StatelessWidget {
  const _TalkButton({
    required this.onStart,
    required this.onEnd,
    required this.onCancel,
    required this.onTap,
  });

  final VoidCallback onStart;
  final VoidCallback onEnd;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = AppScope.of(context).voice;
    return ListenableBuilder(
      listenable: v,
      builder: (context, _) => Semantics(
        button: true,
        label: l.voiceHoldToTalk,
        child: Tooltip(
          message: l.voiceHoldToTalk,
          child: GestureDetector(
            key: const Key('composer-talk'),
            onTap: onTap,
            onLongPressStart: (_) => onStart(),
            onLongPressEnd: (_) => onEnd(),
            onLongPressCancel: onCancel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: v.recording ? c.err.withValues(alpha: .14) : Colors.transparent,
              ),
              child: Center(
                child: RgIcon(
                  v.transcribing ? RgIcons.spinner : RgIcons.mic,
                  size: 20,
                  color: v.recording ? c.err : c.dim,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reads an answer aloud with the voice chosen for RedGiant (Tu › Voce); again to stop.
class _ReadAloud extends StatelessWidget {
  const _ReadAloud({required this.id, required this.text});

  final String id;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = AppScope.maybeRead(context)?.voice;
    if (v == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: v,
      builder: (context, _) {
        final on = v.speaking == id;
        return Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: Key('read-aloud-$id'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => unawaited(v.speak(id, text, l)),
            icon: RgIcon(on ? RgIcons.stop : RgIcons.volume, size: 15, color: c.dim),
            label: Text(
              on ? l.voiceStop : l.voiceReadAloud,
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
          ),
        );
      },
    );
  }
}
