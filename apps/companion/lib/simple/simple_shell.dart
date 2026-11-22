// The simple interface (3.12, design «B · Assistente», the page's components/Simple.tsx): for
// everyday people who do not know what an agent is. «Oggi» (a greeting, one big box for God, the
// topics in progress with their state), a topic read as a clean document with its decisions in an
// evident box, a few settings in groups with «Vista completa» at the bottom, the archive with its
// search. Telephone and computer: one column, wider cards on a wide window.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/conversation.dart';
import '../api/live_model.dart';
import '../api/topics.dart';
import '../app_state.dart';
import '../brand.dart';
import '../l10n/app_localizations.dart';
import '../screens/inbox_screen.dart' show CriticalRequestScreen;
import '../screens/notifications_screen.dart';
import '../settings/channels/telegram_screen.dart';
import '../theme/colors.dart';
import '../ui/accent_picker.dart';
import '../ui/chat/question_card.dart';
import '../ui/chat/request_cards.dart' show armDelay;
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import '../ui/model_sheet.dart' show ChoiceRow;
import '../ui/product_cards.dart';
import '../ui/rg_menu.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import 'simple_model.dart';

/// The widest the screens grow (the board's `.wrap`): wider windows keep it in the middle.
const double kSimpleWidth = 760;

/// The simple interface's home: «Oggi».
class SimpleShell extends StatelessWidget {
  const SimpleShell({super.key});

  @override
  Widget build(BuildContext context) => const TodayScreen();
}

/// The screens' background: a light wash of the accent (the board's gradient), the theme's bg in
/// the dark.
BoxDecoration _wash(BuildContext context) {
  final c = RgColors.of(context);
  final dark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    gradient: dark
        ? null
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(c.bg, c.accent, 0.04)!, c.panel],
          ),
    color: dark ? c.bg : null,
  );
}

List<BoxShadow> _shadow(BuildContext context, {bool big = false}) {
  if (Theme.of(context).brightness == Brightness.dark) return const [];
  final c = RgColors.of(context);
  return [
    BoxShadow(
      color: c.text.withValues(alpha: big ? 0.10 : 0.07),
      blurRadius: big ? 18 : 10,
      offset: Offset(0, big ? 4 : 2),
    ),
  ];
}

Border? _ring(BuildContext context) => Theme.of(context).brightness == Brightness.dark
    ? Border.all(color: RgColors.of(context).line)
    : null;

/// A centred column, as wide as the board's.
class _Column extends StatelessWidget {
  const _Column({required this.child, this.width = kSimpleWidth});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

/// The big box: one place to write to God.
class AskBox extends StatefulWidget {
  const AskBox({super.key, required this.hint, required this.onSend, this.big = false});

  final String hint;
  final Future<bool> Function(String text) onSend;
  final bool big;

  @override
  State<AskBox> createState() => _AskBoxState();
}

class _AskBoxState extends State<AskBox> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final words = _text.text.trim();
    if (words.isEmpty || _busy) return;
    setState(() => _busy = true);
    final ok = await widget.onSend(words);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      margin: EdgeInsets.fromLTRB(16, 6, 16, widget.big ? 14 : 12),
      padding: EdgeInsets.fromLTRB(
        18,
        widget.big ? 10 : 6,
        widget.big ? 10 : 6,
        widget.big ? 10 : 6,
      ),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadow(context, big: true),
        border: _ring(context),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: Key(widget.big ? 'simple-ask' : 'simple-reply'),
              controller: _text,
              minLines: widget.big ? 2 : 1,
              maxLines: 6,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => unawaited(_send()),
              style: TextStyle(fontSize: 16.5, color: c.text, height: 1.4),
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: l.smpSend,
            child: Material(
              color: c.accent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                key: Key(widget.big ? 'simple-ask-send' : 'simple-reply-send'),
                borderRadius: BorderRadius.circular(12),
                onTap: _busy ? null : () => unawaited(_send()),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(child: RgIcon(RgIcons.send, size: 18, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A topic's state in words.
String stateWord(AppLocalizations l, TopicState s) => switch (s) {
  TopicState.waiting => l.smpWaiting,
  TopicState.working => l.smpWorking,
  TopicState.ready => l.smpReady,
};

String _greeting(AppLocalizations l, String name) {
  final key = greetingKey(DateTime.now().hour);
  if (name.isEmpty) {
    return switch (key) {
      'smpMorning' => l.smpMorning,
      'smpAfternoon' => l.smpAfternoon,
      _ => l.smpEvening,
    };
  }
  return switch (key) {
    'smpMorning' => l.smpMorningName(name),
    'smpAfternoon' => l.smpAfternoonName(name),
    _ => l.smpEveningName(name),
  };
}

Future<void> openTopic(BuildContext context, String id, String title) {
  AppScope.read(context).simple.opened(id);
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TopicScreen(id: id, title: title),
    ),
  );
}

/// Requests and questions of no topic (an automation's): «Oggi» shows a line for them.
({List<PermissionRequest> approvals, List<QuestionRequest> questions}) waitingElsewhere(
  LiveModel live,
  List<TopicView> topics,
) {
  final known = {for (final t in topics) t.id};
  bool mine(TopicRef? t, String? sid) =>
      (t != null && known.contains(t.id)) || (sid != null && known.contains(sid));
  return (
    approvals: [
      for (final r in live.approvals)
        if (!mine(r.topic, r.sessionId)) r,
    ],
    questions: [
      for (final q in live.questions)
        if (!mine(q.topic, q.sessionId)) q,
    ],
  );
}

/// «Oggi»: the greeting, the big box, the topics in progress.
class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(AppScope.read(context).simple.refresh());
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      key: const Key('simple-today'),
      body: DecoratedBox(
        decoration: _wash(context),
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge([app.simple, app.live]),
            builder: (context, _) {
              final s = app.simple;
              final other = waitingElsewhere(app.live, s.topics);
              final others = other.approvals.length + other.questions.length;
              return SingleChildScrollView(
                child: _Column(
                  width: 980,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
                        child: Row(
                          children: [
                            Text(
                              kProductName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: c.dim,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              key: const Key('simple-settings'),
                              tooltip: l.smpSettings,
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SimpleSettingsScreen(),
                                ),
                              ),
                              icon: RgIcon(RgIcons.settings, size: 21, color: c.text),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(l, app.personName.trim()),
                              key: const Key('simple-greeting'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: c.text,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(l.smpHeroLead, style: TextStyle(fontSize: 15.5, color: c.dim)),
                          ],
                        ),
                      ),
                      AskBox(
                        big: true,
                        hint: l.smpAskHint,
                        onSend: (text) async {
                          final r = await s.ask(text);
                          if (r == null || !context.mounted) return false;
                          unawaited(openTopic(context, r.sessionId, r.routed.title));
                          return true;
                        },
                      ),
                      if (s.error != null) _ErrorLine(s.error!),
                      if (others > 0)
                        _WaitingLine(
                          text: others == 1 ? l.smpOtherOne : l.smpOtherMany('$others'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const SimpleRequestsScreen()),
                          ),
                        ),
                      // The ready-made assistants (3.12, still to be defined): none, nothing shown.
                      if (s.assistants.isNotEmpty) _Assistants(list: s.assistants),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          l.smpInProgress,
                          style: TextStyle(
                            fontSize: 13,
                            color: c.dim,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      if (s.topics.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                          child: Text(
                            s.loaded ? l.smpNoTopics : l.smpLoading,
                            style: TextStyle(color: c.dim, fontSize: 15, height: 1.45),
                          ),
                        )
                      else
                        _Cards(topics: s.topics),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 20, 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            key: const Key('simple-archive'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const SimpleArchiveScreen()),
                            ),
                            icon: RgIcon(RgIcons.archive, size: 16, color: c.accent2),
                            label: Text(
                              l.smpArchive('${s.archivedCount}'),
                              style: TextStyle(color: c.accent2, fontSize: 14.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(text, style: TextStyle(color: c.err, fontSize: 14)),
    );
  }
}

class _WaitingLine extends StatelessWidget {
  const _WaitingLine({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: const Key('simple-waiting'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border(left: BorderSide(color: c.accent, width: 4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(text, style: TextStyle(fontSize: 15, color: c.text)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Assistants extends StatelessWidget {
  const _Assistants({required this.list});

  final List<SimpleAssistant> list;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final s = AppScope.read(context).simple;
    return SizedBox(
      height: 76,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final a in list)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Material(
                color: c.panel,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => unawaited(s.ask(a.ask)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(a.line, style: TextStyle(fontSize: 13, color: c.dim)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The topics' cards: two in a row on a phone, up to four on a computer.
class _Cards extends StatelessWidget {
  const _Cards({required this.topics});

  final List<TopicView> topics;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth - 32;
      final cols = width < 520 ? 2 : (width / 210).floor().clamp(2, 4);
      const gap = 10.0;
      final w = (width - gap * (cols - 1)) / cols;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in topics)
              SizedBox(
                width: w,
                child: TopicCard(topic: t),
              ),
          ],
        ),
      );
    },
  );
}

/// One topic's card: its title, a line about it, its state in words.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.topic});

  final TopicView topic;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final t = topic;
    final waiting = t.state == TopicState.waiting;
    return Material(
      color: c.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: Key('topic-${t.id}'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => unawaited(openTopic(context, t.id, t.title)),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: _shadow(context),
            border: _ring(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (t.pinned) ...[
                    RgIcon(RgIcons.pin, size: 13, color: c.dim),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      t.title,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: c.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                t.summary ?? l.smpJustStarted,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, color: c.dim, height: 1.35),
              ),
              if (t.from != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l.smpFrom(t.from!),
                    style: TextStyle(fontSize: 12.5, color: c.dim, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 10),
              Container(
                key: Key('topic-state-${t.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: waiting ? c.accent : Color.lerp(c.panel2, c.accent, 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        stateWord(l, t.state),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: waiting ? Colors.white : Color.lerp(c.text, c.accent, 0.22),
                        ),
                      ),
                    ),
                    if (t.unread > 0) ...[
                      const SizedBox(width: 6),
                      Semantics(
                        label: l.smpUnread,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: waiting ? Colors.white : c.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The top of a screen: back, a title, what else it offers.
class _Top extends StatelessWidget {
  const _Top({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 6, 6),
      child: Row(
        children: [
          IconButton(
            key: const Key('simple-back'),
            tooltip: l.smpBack,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: RgIcon(RgIcons.chevronLeft, size: 24, color: c.accent2),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A topic, read as a document; its decisions in a box; «Rispondi…» at the bottom.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.id, required this.title});

  final String id;
  final String title;

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  late final AppController _app = AppScope.read(context);
  late final SessionView _view = _app.follow(widget.id);
  final _scroll = ScrollController();

  @override
  void dispose() {
    _app.unfollow(widget.id);
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _move(int seq) async {
    final r = await showMoveSheet(context, from: widget.id, seq: seq);
    if (r == null || !mounted) return;
    unawaited(
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TopicScreen(id: r.sessionId, title: r.routed.title),
        ),
      ),
    );
  }

  Future<void> _menu(BuildContext context, TopicView? t, String title) async {
    final l = AppLocalizations.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final at = box == null ? Offset.zero : box.localToGlobal(box.size.topRight(Offset.zero));
    final what = await showRgMenu<String>(context, at, [
      RgMenuEntry('rename', RgIcons.pencil, l.smpRename, key: const Key('topic-rename')),
      RgMenuEntry(
        'pin',
        RgIcons.pin,
        t?.pinned == true ? l.smpUnpin : l.smpPin,
        key: const Key('topic-pin'),
      ),
      RgMenuEntry('archive', RgIcons.archive, l.smpArchiveThis, key: const Key('topic-archive')),
    ]);
    if (!context.mounted) return;
    final s = _app.simple;
    switch (what) {
      case 'rename':
        final name = await askText(context, title: l.smpRename, initial: title, yes: l.smpRename);
        if (name != null && name.trim().isNotEmpty) await s.rename(widget.id, name.trim());
      case 'pin':
        await s.pin(widget.id, !(t?.pinned ?? false));
      case 'archive':
        if (await s.archive(widget.id) && context.mounted) Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      key: const Key('simple-topic'),
      body: DecoratedBox(
        decoration: _wash(context),
        child: SafeArea(
          child: _Column(
            child: ListenableBuilder(
              listenable: Listenable.merge([_view, _app.live, _app.simple]),
              builder: (context, _) {
                final t = _app.simple.topic(widget.id);
                final title = t?.title ?? widget.title;
                final items = documentItems(_view.items);
                final approvals = [
                  for (final r in _app.live.approvals)
                    if (r.topic?.id == widget.id || r.sessionId == widget.id) r,
                ];
                final asked = {
                  for (final i in items)
                    if (i is QuestionItem) i.requestId,
                };
                final questions = [
                  for (final q in _app.live.questions)
                    if ((q.topic?.id == widget.id || q.sessionId == widget.id) &&
                        !asked.contains(q.requestId))
                      q,
                ];
                final open = {for (final q in _app.live.questions) q.requestId};
                return Column(
                  children: [
                    _Top(
                      title: title,
                      trailing: Builder(
                        builder: (ctx) => IconButton(
                          key: const Key('topic-more'),
                          tooltip: l.smpMore,
                          onPressed: () => unawaited(_menu(ctx, t, title)),
                          icon: RgIcon(RgIcons.more, size: 20, color: c.text),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        key: const Key('topic-doc'),
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                        children: [
                          if (items.isEmpty && _view.liveText.isEmpty)
                            Text(
                              _view.synced ? l.smpEmptyTopic : l.smpLoading,
                              style: TextStyle(color: c.dim, fontSize: 15),
                            ),
                          for (final i in items)
                            _DocItem(
                              key: Key('doc-${i.key}'),
                              item: i,
                              topicId: widget.id,
                              open: open,
                              onMove: _move,
                            ),
                          if (_view.liveText.isNotEmpty)
                            SafeMarkdown(_view.liveText, reading: true, cursor: true),
                          if (_view.running && _view.liveText.isEmpty) _Working(l.smpWorkingNow),
                          for (final r in approvals)
                            Decision(key: Key('decide-${r.requestId}'), request: r),
                          for (final q in questions) _QuestionBox(q: q),
                        ],
                      ),
                    ),
                    AskBox(
                      hint: l.smpReplyHint,
                      onSend: (text) async {
                        final r = await _app.simple.ask(text, topicId: widget.id);
                        _toEnd();
                        return r != null;
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.only(right: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.4 + i * 0.25),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: c.dim, fontSize: 15.5)),
        ],
      ),
    );
  }
}

/// One piece of the document.
class _DocItem extends StatelessWidget {
  const _DocItem({
    super.key,
    required this.item,
    required this.topicId,
    required this.open,
    required this.onMove,
  });

  final ChatItem item;
  final String topicId;
  final Set<String> open;
  final void Function(int seq) onMove;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final simple = AppScope.read(context).simple;
    switch (item) {
      case UserItem(:final text, :final seq, :final movedFrom):
        final cut = text.indexOf('\n\n<attachment name="');
        final words = cut < 0 ? text : text.substring(0, cut);
        return Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (movedFrom != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l.smpMovedHere, style: TextStyle(fontSize: 13, color: c.dim)),
                ),
              GestureDetector(
                onLongPress: seq == null ? null : () => onMove(seq),
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color.lerp(c.panel2, c.accent, 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    words,
                    style: TextStyle(fontSize: 16.5, height: 1.5, color: c.text),
                  ),
                ),
              ),
            ],
          ),
        );
      case RoutedItem(:final uncertain, :final userSeq):
        final title = simple.titleOf(topicId) ?? '';
        final line = Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            // Unsure: said short, the topic is the one on screen; sure: «in: Titolo».
            Text(
              uncertain ? l.smpRoutedUnsure : l.smpRoutedIn,
              style: TextStyle(fontSize: 13.5, color: uncertain ? c.text : c.dim),
            ),
            if (!uncertain)
              Text(
                title,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: c.text),
              ),
            if (userSeq != null) ...[
              Text('·', style: TextStyle(color: c.dim)),
              InkWell(
                key: Key('routed-move-$userSeq'),
                onTap: () => onMove(userSeq),
                child: Text(l.smpMove, style: TextStyle(fontSize: 13.5, color: c.accent2)),
              ),
            ],
          ],
        );
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            key: uncertain ? const Key('routed-unsure') : null,
            margin: const EdgeInsets.only(bottom: 4),
            padding: uncertain
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : EdgeInsets.zero,
            decoration: uncertain
                ? BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(12))
                : null,
            child: line,
          ),
        );
      case MovedItem(:final toSessionId):
        final to = simple.titleOf(toSessionId);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: TextButton(
              onPressed: () => unawaited(openTopic(context, toSessionId, to ?? '')),
              child: Text(
                to == null ? l.smpMovedElsewhere : l.smpMovedTo(to),
                style: TextStyle(color: c.dim, fontSize: 13.5),
              ),
            ),
          ),
        );
      case AssistantItem(:final text):
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SafeMarkdown(text, reading: true),
        );
      case final QuestionItem q:
        final waiting = !q.answered && open.contains(q.requestId);
        if (waiting) {
          return SimpleQuestion(
            key: Key('ask-${q.requestId}'),
            requestId: q.requestId,
            questions: q.questions,
            plan: q.plan,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 14),
          child: ChatQuestionCard.of(q, open: false),
        );
      case ProductsItem(:final products, :final title):
        return ProductCarousel(products: products, title: title);
      case FileItem(:final name):
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              RgIcon(RgIcons.file, size: 16, color: c.dim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, style: TextStyle(color: c.text)),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// A request in plain words, in an evident box: what would happen, «Sì» or «No». A truly
/// dangerous one says it can't be undone, in red; its yes opens the full screen, as everywhere.
class Decision extends StatefulWidget {
  const Decision({super.key, required this.request});

  final PermissionRequest request;

  @override
  State<Decision> createState() => _DecisionState();
}

class _DecisionState extends State<Decision> {
  bool _armed = false;
  Timer? _arm;

  @override
  void initState() {
    super.initState();
    _arm = Timer(armDelay, () {
      if (mounted) setState(() => _armed = true);
    });
  }

  @override
  void dispose() {
    _arm?.cancel();
    super.dispose();
  }

  Future<void> _answer(bool allow) async {
    if (!_armed) return;
    final app = AppScope.read(context);
    final r = widget.request;
    if (allow && r.isCritical) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => CriticalRequestScreen(request: r)));
      return;
    }
    await app.resolvePermission(r, allow: allow);
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final r = widget.request;
    final words = r.wordsIn(Localizations.localeOf(context).languageCode);
    final critical = r.isCritical;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: critical ? c.criticalSoft : c.panel,
        border: Border.all(color: critical ? c.critical : c.accent, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            critical ? l.smpAskCritical : l.smpAskAllow,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16.5,
              color: critical ? c.criticalText : c.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(words?.what ?? '', style: TextStyle(fontSize: 16, height: 1.5, color: c.text)),
          if (critical)
            for (final x in words?.critical ?? const <String>[])
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 6),
                child: Text('–  $x', style: TextStyle(fontSize: 15, color: c.text)),
              ),
          const SizedBox(height: 10),
          Opacity(
            opacity: _armed ? 1 : 0.6,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: Key('decide-yes-${r.requestId}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: critical ? c.critical : c.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => unawaited(_answer(true)),
                  child: Text(l.smpYes),
                ),
                FilledButton(
                  key: Key('decide-no-${r.requestId}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color.lerp(c.panel2, c.accent, 0.09),
                    foregroundColor: c.text,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => unawaited(_answer(false)),
                  child: Text(l.smpNo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBox extends StatelessWidget {
  const _QuestionBox({required this.q});

  final QuestionRequest q;

  @override
  Widget build(BuildContext context) => SimpleQuestion(
    key: Key('ask-${q.requestId}'),
    requestId: q.requestId,
    questions: q.questions,
    plan: q.plan,
    topic: q.topic?.title,
  );
}

/// A question waiting for the person, in the evident box. One plain choice (the board's «Vuoi
/// che lo prenoti?») is its buttons, the first one filled, with «Altro…» for words of one's own;
/// anything else (several questions, several choices, a plan) is the usual card.
class SimpleQuestion extends StatefulWidget {
  const SimpleQuestion({
    super.key,
    required this.requestId,
    required this.questions,
    this.plan,
    this.topic,
  });

  final String requestId;
  final List<Question> questions;
  final String? plan;

  /// «per: Titolo», outside the topic.
  final String? topic;

  @override
  State<SimpleQuestion> createState() => _SimpleQuestionState();
}

class _SimpleQuestionState extends State<SimpleQuestion> {
  bool _armed = false;
  bool _sent = false;
  Timer? _arm;
  TextEditingController? _other;

  @override
  void initState() {
    super.initState();
    _arm = Timer(armDelay, () {
      if (mounted) setState(() => _armed = true);
    });
  }

  @override
  void dispose() {
    _arm?.cancel();
    _other?.dispose();
    super.dispose();
  }

  void _answer(String text) {
    if (!_armed || _sent || text.trim().isEmpty) return;
    final ok = AppScope.read(context).answerQuestionId(widget.requestId, [
      [text.trim()],
    ]);
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final one = widget.questions.length == 1 && widget.plan == null ? widget.questions.first : null;
    ButtonStyle style(bool main) => FilledButton.styleFrom(
      backgroundColor: main ? c.accent : Color.lerp(c.panel2, c.accent, 0.09),
      foregroundColor: main ? Colors.white : c.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(color: c.accent, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.topic != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l.smpFor(widget.topic!), style: TextStyle(fontSize: 13, color: c.dim)),
            ),
          if (one == null || one.multiSelect)
            ChatQuestionCard(
              requestId: widget.requestId,
              questions: widget.questions,
              plan: widget.plan,
              open: true,
            )
          else ...[
            Text(
              one.question,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.5, color: c.text),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: _armed && !_sent ? 1 : 0.6,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < one.options.length; i++)
                    FilledButton(
                      key: Key('ask-${widget.requestId}-$i'),
                      style: style(i == 0),
                      onPressed: () => _answer(one.options[i].label),
                      child: Text(one.options[i].label),
                    ),
                  if (_other == null)
                    FilledButton(
                      key: Key('ask-${widget.requestId}-other'),
                      style: style(false),
                      onPressed: () => setState(() => _other = TextEditingController()),
                      child: Text(l.smpOther),
                    ),
                ],
              ),
            ),
            if (_other != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _other,
                        decoration: InputDecoration(hintText: l.smpOtherHint, isDense: true),
                        onSubmitted: _answer,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: style(true),
                      onPressed: () => _answer(_other!.text),
                      child: Text(l.smpSend),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// «Sposta»: the exchange goes to another topic, an archived one (found with its search) or a new
/// one. Where it went, or null.
Future<TopicSent?> showMoveSheet(BuildContext context, {required String from, required int seq}) =>
    showModalBottomSheet<TopicSent>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MoveSheet(from: from, seq: seq),
    );

class _MoveSheet extends StatefulWidget {
  const _MoveSheet({required this.from, required this.seq});

  final String from;
  final int seq;

  @override
  State<_MoveSheet> createState() => _MoveSheetState();
}

class _MoveSheetState extends State<_MoveSheet> {
  late final SimpleModel _s = AppScope.read(context).simple;
  String _q = '';
  Timer? _search;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_s.searchArchive(''));
  }

  @override
  void dispose() {
    _search?.cancel();
    super.dispose();
  }

  Future<void> _go(String to, {String? title}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await _s.move(widget.from, widget.seq, to, title: title);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) Navigator.of(context).pop(r);
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: _s,
      builder: (context, _) {
        final words = _q.trim().toLowerCase();
        bool match(TopicView t) =>
            words.isEmpty || '${t.title} ${t.summary ?? ''}'.toLowerCase().contains(words);
        final active = [
          for (final t in _s.topics)
            if (t.id != widget.from && match(t)) t,
        ];
        final archived = [
          for (final t in _s.archived)
            if (t.id != widget.from) t,
        ];
        Widget row(TopicView t) => ListTile(
          key: Key('move-to-${t.id}'),
          title: Text(
            t.title,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
          ),
          subtitle: t.summary == null ? null : Text(t.summary!, style: TextStyle(color: c.dim)),
          onTap: _busy ? null : () => unawaited(_go(t.id)),
        );
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
            child: ListView(
              key: const Key('move-sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Text(
                    l.smpMoveTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text(l.smpMoveLead, style: TextStyle(color: c.dim, fontSize: 14.5)),
                ),
                ListTile(
                  key: const Key('move-new'),
                  leading: RgIcon(RgIcons.plus, size: 18, color: c.accent2),
                  title: Text(
                    l.smpNewTopic,
                    style: TextStyle(color: c.accent2, fontWeight: FontWeight.w600),
                  ),
                  onTap: _busy
                      ? null
                      : () async {
                          final title = await askText(
                            context,
                            title: l.smpNewTopic,
                            hint: l.smpNewTopicName,
                            yes: l.smpMove,
                          );
                          if (title != null) await _go('new', title: title);
                        },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: TextField(
                    key: const Key('move-search'),
                    decoration: InputDecoration(
                      hintText: l.smpSearchHint,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: RgIcon(RgIcons.search, size: 16, color: c.dim),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _q = v);
                      _search?.cancel();
                      _search = Timer(
                        const Duration(milliseconds: 250),
                        () => unawaited(_s.searchArchive(v)),
                      );
                    },
                  ),
                ),
                for (final t in active) row(t),
                if (archived.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      l.smpInArchive,
                      style: TextStyle(fontSize: 13, color: c.dim, fontWeight: FontWeight.w600),
                    ),
                  ),
                for (final t in archived) row(t),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A group of rows (the board's `.grp`).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow(context),
        border: _ring(context),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: c.line.withValues(alpha: 0.7)),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A row: its words on the left, its control or value on the right; the whole row is the tap.
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.title,
    this.help,
    this.trailing,
    this.onTap,
    this.wide = false,
  });

  final String title;
  final String? help;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The control goes under the words (a row of choices on a phone).
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 15.5, color: c.text)),
        if (help != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(help!, style: TextStyle(fontSize: 13, color: c.dim, height: 1.35)),
          ),
      ],
    );
    final body = wide
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [words, const SizedBox(height: 8), ?trailing],
          )
        : Row(
            children: [
              Expanded(child: words),
              const SizedBox(width: 14),
              ?trailing,
            ],
          );
    final row = Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: body);
    return onTap == null
        ? row
        : MergeSemantics(
            child: InkWell(onTap: onTap, child: row),
          );
  }
}

/// Few settings, in groups; «Vista completa» at the bottom.
class SimpleSettingsScreen extends StatefulWidget {
  const SimpleSettingsScreen({super.key});

  @override
  State<SimpleSettingsScreen> createState() => _SimpleSettingsScreenState();
}

class _SimpleSettingsScreenState extends State<SimpleSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return Scaffold(
      key: const Key('simple-settings-screen'),
      body: DecoratedBox(
        decoration: _wash(context),
        child: SafeArea(
          child: _Column(
            child: Column(
              children: [
                _Top(title: l.smpSettings),
                Expanded(
                  child: ListenableBuilder(
                    listenable: app.handsFree,
                    builder: (context, _) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        _Group(
                          children: [
                            if (app.desktop)
                              _Row(
                                key: const Key('simple-notify'),
                                title: l.smpNotify,
                                trailing: RgSwitch(on: app.desktopNotify),
                                onTap: () => app.setDesktopNotify(!app.desktopNotify),
                              )
                            else
                              _Row(
                                key: const Key('simple-notify'),
                                title: l.smpNotify,
                                trailing: RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const NotificationsScreen(),
                                  ),
                                ),
                              ),
                            _Row(
                              key: const Key('simple-voice'),
                              title: l.smpVoice,
                              help: l.smpVoiceHelp,
                              trailing: RgSwitch(on: app.handsFree.settings.enabled),
                              onTap: () => unawaited(
                                app.handsFree.update(
                                  app.handsFree.settings.copyWith(
                                    enabled: !app.handsFree.settings.enabled,
                                  ),
                                ),
                              ),
                            ),
                            _Row(
                              title: l.smpSpend,
                              help: l.smpSpendHelp,
                              trailing: Text(l.smpAlways, style: TextStyle(color: c.dim)),
                            ),
                          ],
                        ),
                        _Group(
                          children: [
                            _Row(
                              key: const Key('simple-name'),
                              title: l.smpYourName,
                              trailing: Text(
                                app.personName.isEmpty ? l.smpNoName : app.personName,
                                style: TextStyle(color: c.dim),
                              ),
                              onTap: () async {
                                final v = await askText(
                                  context,
                                  title: l.smpYourName,
                                  initial: app.personName,
                                  hint: l.smpYourNameLabel,
                                  yes: l.smpYourName,
                                  fieldKey: const Key('simple-name-field'),
                                );
                                if (v != null) await app.setPersonName(v);
                              },
                            ),
                            _Row(
                              key: const Key('simple-telegram'),
                              title: 'Telegram',
                              trailing: Text(
                                l.smpLink,
                                style: TextStyle(color: c.accent2, fontWeight: FontWeight.w600),
                              ),
                              onTap: () => unawaited(openTelegramSettings(context)),
                            ),
                          ],
                        ),
                        _Group(
                          children: [
                            _Row(
                              title: l.smpTheme,
                              wide: narrow,
                              trailing: ChoiceRow(
                                keyPrefix: 'simple-theme',
                                values: const ['system', 'light', 'dark'],
                                selected: app.themeMode.name,
                                label: (v) => switch (v) {
                                  'light' => l.themeLight,
                                  'dark' => l.themeDark,
                                  _ => l.themeSystem,
                                },
                                onChanged: (v) => app.setThemeMode(ThemeMode.values.byName(v)),
                              ),
                            ),
                            _Row(
                              title: l.smpColour,
                              wide: narrow,
                              trailing: AccentPicker(key: const Key('simple-accent'), app: app),
                            ),
                            _Row(
                              title: l.smpLanguage,
                              trailing: ChoiceRow(
                                keyPrefix: 'simple-lang',
                                values: const ['it', 'en'],
                                selected: Localizations.localeOf(context).languageCode,
                                label: (v) => v == 'it' ? 'Italiano' : 'English',
                                onChanged: (v) => app.setLocale(Locale(v)),
                              ),
                            ),
                          ],
                        ),
                        _Group(
                          children: [
                            _Row(
                              key: const Key('simple-full-view'),
                              title: l.smpFullView,
                              help: l.smpFullViewHelp,
                              trailing: const RgSwitch(on: false),
                              onTap: () {
                                Navigator.of(context).popUntil((r) => r.isFirst);
                                app.setUi('full');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The archive: topics that rested, found with words; one tap takes one back.
class SimpleArchiveScreen extends StatefulWidget {
  const SimpleArchiveScreen({super.key});

  @override
  State<SimpleArchiveScreen> createState() => _SimpleArchiveScreenState();
}

class _SimpleArchiveScreenState extends State<SimpleArchiveScreen> {
  late final SimpleModel _s = AppScope.read(context).simple;
  String _q = '';
  Timer? _search;

  @override
  void initState() {
    super.initState();
    unawaited(_s.searchArchive(''));
  }

  @override
  void dispose() {
    _search?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      key: const Key('simple-archive-screen'),
      body: DecoratedBox(
        decoration: _wash(context),
        child: SafeArea(
          child: _Column(
            child: Column(
              children: [
                _Top(title: l.smpArchiveTitle),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _s,
                    builder: (context, _) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                          child: Text(
                            l.smpArchiveLead,
                            style: TextStyle(color: c.dim, fontSize: 15, height: 1.45),
                          ),
                        ),
                        TextField(
                          key: const Key('archive-search'),
                          decoration: InputDecoration(
                            hintText: l.smpSearchHint,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12),
                              child: RgIcon(RgIcons.search, size: 16, color: c.dim),
                            ),
                          ),
                          onChanged: (v) {
                            setState(() => _q = v);
                            _search?.cancel();
                            _search = Timer(
                              const Duration(milliseconds: 250),
                              () => unawaited(_s.searchArchive(v)),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        if (_s.archived.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              _q.trim().isEmpty ? l.smpArchiveEmpty : l.smpNothingFound,
                              style: TextStyle(color: c.dim, fontSize: 15),
                            ),
                          )
                        else
                          _Group(
                            children: [
                              for (final t in _s.archived)
                                _Row(
                                  key: Key('archived-${t.id}'),
                                  title: t.title,
                                  help: t.summary,
                                  trailing: Text(
                                    _day(t.lastAt, lang),
                                    style: TextStyle(color: c.dim, fontSize: 13.5),
                                  ),
                                  onTap: () async {
                                    if (await _s.restore(t.id) && context.mounted) {
                                      unawaited(
                                        Navigator.of(context).pushReplacement(
                                          MaterialPageRoute<void>(
                                            builder: (_) => TopicScreen(id: t.id, title: t.title),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _day(String? iso, String lang) {
  final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  const it = [
    'gennaio',
    'febbraio',
    'marzo',
    'aprile',
    'maggio',
    'giugno',
    'luglio',
    'agosto',
    'settembre',
    'ottobre',
    'novembre',
    'dicembre',
  ];
  const en = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return lang == 'it' ? '${d.day} ${it[d.month - 1]}' : '${en[d.month - 1]} ${d.day}';
}

/// What waits for the person outside the topics (an automation's request).
class SimpleRequestsScreen extends StatelessWidget {
  const SimpleRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: _wash(context),
        child: SafeArea(
          child: _Column(
            child: Column(
              children: [
                _Top(title: l.smpRequestsTitle),
                Expanded(
                  child: ListenableBuilder(
                    listenable: Listenable.merge([app.live, app.simple]),
                    builder: (context, _) {
                      final w = waitingElsewhere(app.live, app.simple.topics);
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        children: [
                          if (w.approvals.isEmpty && w.questions.isEmpty)
                            Text(l.smpNothingWaits, style: TextStyle(color: c.dim, fontSize: 15)),
                          for (final r in w.approvals)
                            Decision(key: Key('decide-${r.requestId}'), request: r),
                          for (final q in w.questions) _QuestionBox(q: q),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
