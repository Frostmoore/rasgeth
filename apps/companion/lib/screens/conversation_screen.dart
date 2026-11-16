// One conversation (G40.7): its history, the answer streaming in, the reasoning folded, the
// tools' calls, the files and canvases the agent showed, and the composer with attachments as
// the page's (photos, text files, the rest saved in the workspace), «press and talk» and the
// answers read aloud (G40.10). The same messages as the page: `session.follow` (history in one
// go), `session.send`, `session.interrupt`. An answer is selectable with our menu: «Rispondi a
// questo» puts the passage above the composer (G36.22), «Salva» keeps it (G40.14); a message's
// menu saves it whole. Product cards (G40.16) show as a carousel. Opened from «Salvati», the
// conversation goes to the message and lights the passage up.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/attachments.dart';
import '../api/client.dart';
import '../api/conversation.dart';
import '../api/live_model.dart';
import '../api/saved.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import '../ui/passage_selection.dart';
import '../ui/product_cards.dart';
import '../ui/words.dart';
import 'canvas_screen.dart';
import 'conversation_more.dart';
import 'saved_screen.dart';

/// A message to go to when the conversation opens (a saved passage, a quote), lit up a moment.
class PassageJump {
  const PassageJump({required this.seq, required this.text, this.start, this.end});

  final int seq;
  final String text;
  final int? start;
  final int? end;
}

/// What the person can do with the items: reply to a passage, save one, go to a quoted one.
class ChatActions {
  const ChatActions({this.reply, this.save, this.jump, this.lit, this.flashSeq});

  final void Function(AssistantItem item, PickedPassage passage)? reply;

  /// A passage, or the whole message with null.
  final void Function(AssistantItem item, PickedPassage? passage)? save;
  final void Function(Quote quote)? jump;

  /// The passage lit up now, and the message flashing (the passage was not found in it).
  final PassageJump? lit;
  final int? flashSeq;
}

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.sessionId,
    this.agent,
    this.firstMessage,
    this.draft,
    this.jump,
    this.embedded = false,
  });

  final String sessionId;
  final Agent? agent;

  /// Where to go once the history is in (from «Salvati»).
  final PassageJump? jump;

  /// Shown inside another screen (the tablet's diff): no way «back» of its own.
  final bool embedded;

  /// Sent as soon as the conversation opens (the Chat's field over the bar).
  final String? firstMessage;

  /// Written in the field, for the person to finish (the advanced interface's «Ask…»).
  final String? draft;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final AppController app;
  late final SessionView view;
  final _text = TextEditingController();
  final _attached = <Attached>[];
  final _quotes = <Quote>[];
  final _scroll = ScrollController();
  final _keys = <int, GlobalKey>{};
  PassageJump? _pending;
  PassageJump? _lit;
  int? _flash;
  Timer? _litTimer;
  bool _sending = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
    view = app.follow(widget.sessionId);
    _pending = widget.jump;
    if (_pending != null) {
      view.addListener(_tryJump);
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryJump());
    }
    if (widget.draft != null) _text.text = widget.draft!;
    final first = widget.firstMessage;
    if (first != null && first.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(text: first));
    }
  }

  @override
  void dispose() {
    view.removeListener(_tryJump);
    _litTimer?.cancel();
    _scroll.dispose();
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

  // ---- passages: reply, save, go to (G36.22, G40.14) ----

  void _tryJump() {
    final j = _pending;
    if (j == null || !mounted) return;
    final there = view.items.any((i) => i is AssistantItem && i.seq == j.seq);
    if (!there) {
      if (view.synced && view.events.isNotEmpty) {
        _pending = null;
        view.removeListener(_tryJump);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).savedNotThere)));
      }
      return;
    }
    _pending = null;
    view.removeListener(_tryJump);
    _goTo(j);
  }

  /// Scrolls to the message and lights the passage up (the whole message when it is not found).
  void _goTo(PassageJump j) {
    final item = view.items.whereType<AssistantItem>().where((i) => i.seq == j.seq).firstOrNull;
    if (item == null) return;
    final found = markPassage(item.text, j.text, start: j.start, end: j.end) != null;
    _litTimer?.cancel();
    setState(() {
      _lit = found ? j : null;
      _flash = found ? null : j.seq;
    });
    _litTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _lit = null;
          _flash = null;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_scrollTo(j.seq)));
  }

  Future<void> _scrollTo(int seq) async {
    for (var i = 0; i < 80 && mounted; i++) {
      final ctx = _keys[seq]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: .3,
          duration: const Duration(milliseconds: 300),
        );
        return;
      }
      if (_scroll.hasClients) {
        final p = _scroll.position;
        if (p.pixels >= p.maxScrollExtent) return;
        _scroll.jumpTo(math.min(p.pixels + p.viewportDimension * .7, p.maxScrollExtent));
      }
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  void _reply(AssistantItem item, PickedPassage p) {
    final l = AppLocalizations.of(context);
    if (_quotes.length >= maxQuotes) {
      setState(() => _note = l.quoteTooMany(maxQuotes));
      return;
    }
    final squash = p.text.replaceAll(RegExp(r'\s+'), ' ');
    if (_quotes.any((q) => q.seq == item.seq && q.text.replaceAll(RegExp(r'\s+'), ' ') == squash)) {
      return;
    }
    final text = p.text.length > 4000 ? '${p.text.substring(0, 3999)}…' : p.text;
    setState(() {
      _quotes.add(
        Quote(
          text: text,
          seq: item.seq,
          at: item.ts.isEmpty ? null : item.ts,
          start: p.start,
          end: p.end,
        ),
      );
    });
  }

  void _save(AssistantItem item, PickedPassage? p) {
    final seq = item.seq;
    if (seq == null) return;
    unawaited(
      showSaveSheet(
        context,
        sessionId: widget.sessionId,
        seq: seq,
        preview: p?.text ?? item.text,
        text: p?.text,
        start: p?.start,
        end: p?.end,
      ),
    );
  }

  void _jumpQuote(Quote q) {
    final seq = q.seq;
    if (seq == null) return;
    _goTo(PassageJump(seq: seq, text: q.text, start: q.start, end: q.end));
  }

  Future<void> _send({String? text}) async {
    final l = AppLocalizations.of(context);
    final t = (text ?? _text.text).trim();
    if (t.isEmpty && _attached.isEmpty && _quotes.isEmpty) return;
    setState(() => _sending = true);
    final c = app.client;
    var ok = false;
    final quotes = List.of(_quotes);
    try {
      final packed = await packMessage(
        t.isEmpty && _attached.isNotEmpty ? l.attachmentOnly : t,
        List.of(_attached),
        upload: c == null
            ? null
            : (path, bytes) => c.writeFile(attachmentScope(_agent), path, bytes),
        notSent: l.attachmentNotSent,
      );
      ok = await app.send(widget.sessionId, packed.text, images: packed.images, quotes: quotes);
    } on ApiException {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        if (text == null) _text.clear();
        _attached.clear();
        _quotes.clear();
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
                  embedded: widget.embedded,
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
                  final actions = ChatActions(
                    reply: _reply,
                    save: _save,
                    jump: _jumpQuote,
                    lit: _lit,
                    flashSeq: _flash,
                  );
                  return ListView.builder(
                    key: const Key('conversation-items'),
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[items.length - 1 - i];
                      final seq = item is AssistantItem ? item.seq : null;
                      return Padding(
                        key: seq == null ? null : _keys.putIfAbsent(seq, GlobalKey.new),
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ChatItemView(item: item, actions: actions),
                      );
                    },
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
            if (_quotes.isNotEmpty)
              _QuoteDrafts(
                quotes: _quotes,
                onRemove: (q) => setState(() => _quotes.remove(q)),
                onJump: _jumpQuote,
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
    required this.embedded,
    required this.agent,
    required this.state,
    required this.running,
    required this.onStop,
  });

  final bool embedded;
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
      padding: EdgeInsets.fromLTRB(embedded ? 12 : 4, 6, 10, 6),
      child: Row(
        children: [
          // Beside the diff the conversation is a panel: «back» would close the project.
          if (!embedded)
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
  const ChatItemView({super.key, required this.item, this.actions = const ChatActions()});

  final ChatItem item;
  final ChatActions actions;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final split = switch (item) {
      UserItem(:final text) => splitAttachments(text),
      _ => (text: '', files: const <({String name, String? path})>[]),
    };
    return switch (item) {
      UserItem(:final images, :final from, :final quotes) => Align(
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
              for (final q in quotes)
                _QuoteBlock(quote: q, onJump: actions.jump == null ? null : () => actions.jump!(q)),
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
      AssistantItem() => AssistantView(item: item as AssistantItem, actions: actions),
      ProductsItem(:final products, :final title) => ProductCarousel(
        key: Key('products-${(item as ProductsItem).seq}'),
        products: products,
        title: title,
      ),
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
  const AssistantView({super.key, required this.item, this.actions = const ChatActions()});

  final AssistantItem item;
  final ChatActions actions;

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
        if (it.text.isNotEmpty) _body(c),
        if (it.live && it.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(l.writing, style: TextStyle(color: c.dim, fontSize: 12)),
          ),
        if (!it.live && it.text.trim().isNotEmpty)
          Row(
            children: [
              _ReadAloud(id: 'a-${it.ts}', text: it.text),
              if (it.seq != null) _MessageMenu(item: it, actions: widget.actions),
            ],
          ),
      ],
    );
  }

  Widget _body(RgColors c) {
    final it = widget.item;
    final a = widget.actions;
    if (it.live || it.seq == null) return SafeMarkdown(it.text);
    final lit = a.lit;
    final marked = lit != null && lit.seq == it.seq
        ? markPassage(it.text, lit.text, start: lit.start, end: lit.end)
        : null;
    final flash = a.flashSeq == it.seq;
    return AnimatedContainer(
      key: Key('answer-${it.seq}'),
      duration: const Duration(milliseconds: 300),
      padding: flash ? const EdgeInsets.symmetric(horizontal: 6) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: flash ? c.accentSoft : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableAnswer(
        data: marked ?? it.text,
        onReply: a.reply == null ? null : (p) => a.reply!(it, p),
        onSave: a.save == null ? null : (p) => a.save!(it, p),
      ),
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

/// A message's menu: copy it, save it whole (G40.14).
class _MessageMenu extends StatelessWidget {
  const _MessageMenu({required this.item, required this.actions});

  final AssistantItem item;
  final ChatActions actions;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return IconButton(
      key: Key('message-menu-${item.seq}'),
      tooltip: l.messageMenu,
      visualDensity: VisualDensity.compact,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final what = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  key: const Key('message-copy'),
                  leading: RgIcon(RgIcons.copy, color: c.text),
                  title: Text(l.copy),
                  onTap: () => Navigator.pop(context, 'copy'),
                ),
                if (actions.save != null)
                  ListTile(
                    key: const Key('message-save'),
                    leading: RgIcon(RgIcons.bookmark, color: c.text),
                    title: Text(l.savedSave),
                    subtitle: Text(l.messageSaveHint),
                    onTap: () => Navigator.pop(context, 'save'),
                  ),
              ],
            ),
          ),
        );
        if (what == 'copy') {
          await Clipboard.setData(ClipboardData(text: item.text));
          messenger.showSnackBar(SnackBar(content: Text(l.messageCopied)));
        } else if (what == 'save') {
          actions.save!(item, null);
        }
      },
      icon: RgIcon(RgIcons.more, size: 18, color: c.dim, filled: true),
    );
  }
}

/// A quoted passage in a sent message: a tap goes to it.
class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.quote, this.onJump});

  final Quote quote;
  final VoidCallback? onJump;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: onJump != null && quote.seq != null,
        hint: l.quoteJump,
        child: InkWell(
          key: Key('quote-ref-${quote.seq}'),
          onTap: quote.seq == null ? null : onJump,
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 4, 6, 4),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.accentDim, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.dim, fontSize: 13.5, fontStyle: FontStyle.italic),
                ),
                if (quote.reply != null && quote.reply!.trim().isNotEmpty)
                  Text(quote.reply!.trim(), style: TextStyle(color: c.text, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The passages being answered, above the composer (G36.22): each can go.
class _QuoteDrafts extends StatelessWidget {
  const _QuoteDrafts({required this.quotes, required this.onRemove, required this.onJump});

  final List<Quote> quotes;
  final ValueChanged<Quote> onRemove;
  final ValueChanged<Quote> onJump;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('quote-drafts'),
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: c.panel2,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        children: [
          Row(
            children: [
              RgIcon(RgIcons.reply, size: 14, color: c.dim),
              const SizedBox(width: 6),
              Text(l.quoteReplyingTo, style: TextStyle(color: c.dim, fontSize: 12.5)),
            ],
          ),
          for (final (i, q) in quotes.indexed)
            Row(
              key: Key('quote-draft-$i'),
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => onJump(q),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.fromLTRB(9, 3, 4, 3),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: c.accent, width: 3)),
                      ),
                      child: Text(
                        q.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.text, fontSize: 13.5),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  key: Key('quote-remove-$i'),
                  tooltip: l.quoteRemove,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onRemove(q),
                  icon: RgIcon(RgIcons.x, size: 15, color: c.dim),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
