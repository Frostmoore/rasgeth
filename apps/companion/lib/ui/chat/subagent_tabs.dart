// A conversation with its sub-agents (G42.3), as the page's Chat.tsx (p3.3.1, as Officina shows
// them): when it started any, a row of tabs on top, «Agente principale» and one per sub-agent; a
// sub-agent with sub-agents of its own opens another row under it, and so on. Each tab: its task,
// a dot for its state, a ring when something new came, the shield when it waits for the person's
// yes, «x» once it stopped (`subagent.close`). A sub-agent's tab shows its conversation with the
// chat's own pieces and, instead of the composer, a bar with its time, tools, tokens and «Ferma»
// (nobody writes to it: it takes orders from the agent that started it).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/conversation.dart';
import '../../api/live_model.dart';
import '../../api/metrics.dart' show duration, kTokens;
import '../../api/parallel.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../mascot/mascot_view.dart';
import '../../screens/conversation_screen.dart' show ChatActions, ChatItemView, MaxWidthCenter;
import '../../theme/colors.dart';
import '../icons.dart';
import '../turn_progress.dart';
import 'command_strip.dart';
import 'request_cards.dart';

/// One level of tabs: the conversation whose tabs it shows, and the tab chosen in it.
class SubLevel {
  SubLevel({required this.session, required this.agentId, required this.tabs});

  final String session;
  final String agentId;
  final List<SubTab> tabs;
  SubTab? chosen;
}

/// The levels shown for [rootSessionId] along [path] (the page's `Chat`): a chosen sub-agent with
/// sub-agents of its own adds the next row under it. [eventsOf] gives a conversation's events.
List<SubLevel> subLevels(
  String rootSessionId,
  String rootAgentId,
  List<String> path,
  List<RgEvent> Function(String sessionId) eventsOf,
) {
  final levels = [
    SubLevel(
      session: rootSessionId,
      agentId: rootAgentId,
      tabs: subagentTabs(eventsOf(rootSessionId)),
    ),
  ];
  for (final id in path) {
    final level = levels.last;
    final tab = level.tabs.where((x) => x.childSessionId == id && !x.closed).firstOrNull;
    if (tab == null) break;
    level.chosen = tab;
    final below = subagentTabs(eventsOf(tab.childSessionId));
    if (!below.any((x) => !x.closed)) break;
    levels.add(SubLevel(session: tab.childSessionId, agentId: tab.childAgentId, tabs: below));
  }
  return levels;
}

/// A request belongs to the sub-agent's conversation (its agent's only when it names none).
List<PermissionRequest> asksIn(AppController app, SubTab tab) => [
  for (final r in app.live.approvals)
    if (r.sessionId != null ? r.sessionId == tab.childSessionId : r.agentId == tab.childAgentId) r,
];

String _status(AppController app, SubTab tab, String parent) => subStatus(
  tab,
  childRunning: app.live.views[tab.childSessionId]?.running ?? false,
  parentRunning: app.live.views[parent]?.running ?? false,
);

String subStatusWords(AppLocalizations l, String status) => switch (status) {
  'running' => l.cvSubStatusRunning,
  'done' => l.cvSubStatusDone,
  'failed' => l.cvSubStatusFailed,
  _ => l.cvSubStatusStopped,
};

/// The conversation's sub-agents around [main]: the rows of tabs on top, then the chosen tab's
/// view or [main] itself. Without sub-agents, just [main].
class SubagentHost extends StatefulWidget {
  const SubagentHost({
    super.key,
    required this.sessionId,
    required this.agentId,
    required this.main,
  });

  final String sessionId;
  final String agentId;
  final Widget main;

  @override
  State<SubagentHost> createState() => _SubagentHostState();
}

class _SubagentHostState extends State<SubagentHost> {
  late final AppController app = AppScope.read(context);

  /// The sub-agents' conversations followed for their tabs (state, «new», their own tabs).
  final Set<String> _followed = {};

  @override
  void dispose() {
    for (final id in _followed) {
      app.unfollow(id);
    }
    super.dispose();
  }

  /// Follows the conversations behind the visible tabs (the page's `useFollowAll`).
  void _followAll(Iterable<String> ids) {
    final want = ids.toSet();
    for (final id in want.difference(_followed)) {
      app.follow(id);
    }
    for (final id in _followed.difference(want)) {
      app.unfollow(id);
    }
    _followed
      ..clear()
      ..addAll(want);
  }

  List<RgEvent> _events(String id) => app.live.views[id]?.events ?? const [];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([app, app.live, ...app.live.views.values]),
      builder: (context, _) {
        final root = widget.sessionId;
        final path = app.subPath[root] ?? const [];
        final levels = subLevels(root, widget.agentId, path, _events);
        final visible = [
          for (final l in levels)
            for (final x in l.tabs)
              if (!x.closed) x.childSessionId,
        ];
        // After the frame: following changes the views listened to here.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _followAll(visible);
        });
        if (path.isEmpty && visible.isEmpty) return widget.main;
        final chosen = levels.where((l) => l.chosen != null).toList();
        final open = chosen.lastOrNull;
        return Column(
          children: [
            _SubRows(root: root, rootAgent: widget.agentId, levels: levels, path: path),
            Expanded(
              child: open?.chosen == null
                  ? widget.main
                  : SubagentView(
                      key: ValueKey(open!.chosen!.childSessionId),
                      tab: open.chosen!,
                      parentSession: open.session,
                      parentAgent: open.agentId,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SubRows extends StatelessWidget {
  const _SubRows({
    required this.root,
    required this.rootAgent,
    required this.levels,
    required this.path,
  });

  final String root;
  final String rootAgent;
  final List<SubLevel> levels;
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    String nameOf(String id) => app.agents.where((a) => a.id == id).firstOrNull?.name ?? '';
    final askers = [
      for (final (i, lv) in levels.indexed)
        for (final x in lv.tabs)
          if (!x.closed &&
              (i >= path.length || x.childSessionId != path[i]) &&
              asksIn(app, x).isNotEmpty)
            (tab: x, level: i),
    ];
    return Container(
      key: const Key('sub-rows'),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, lv) in levels.indexed)
            _row(context, i, lv, i == 0 ? l.cvSubMain : nameOf(lv.agentId)),
          if (path.isNotEmpty)
            Container(
              key: const Key('sub-crumbs'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                runSpacing: 2,
                children: [
                  _Crumb(
                    text: nameOf(rootAgent).isEmpty ? l.cvSubMain : nameOf(rootAgent),
                    onTap: () => app.openSubPath(root, const []),
                  ),
                  for (final (i, lv) in levels.where((x) => x.chosen != null).indexed) ...[
                    RgIcon(RgIcons.chevronRight, size: 12, color: c.dim),
                    _Crumb(
                      text: lv.chosen!.title,
                      onTap: () => app.openSubPath(root, path.sublist(0, i + 1)),
                    ),
                  ],
                ],
              ),
            ),
          for (final a in askers)
            Container(
              key: Key('sub-asks-${a.tab.childSessionId}'),
              margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: c.warn.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.warn.withValues(alpha: .45)),
              ),
              child: Row(
                children: [
                  RgIcon(RgIcons.shield, size: 13, color: c.warnText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.cvSubAsks(a.tab.title),
                      style: TextStyle(color: c.text, fontSize: 13),
                    ),
                  ),
                  _Crumb(
                    text: l.cvSubOpenTab,
                    onTap: () =>
                        app.openSubPath(root, [...path.take(a.level), a.tab.childSessionId]),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, int i, SubLevel lv, String mainName) {
    final app = AppScope.of(context);
    final c = RgColors.of(context);
    final row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(10, i == 0 ? 6 : 4, 10, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _TabShape(
            key: Key('sub-main-$i'),
            on: lv.chosen == null,
            onTap: () => app.openSubPath(root, path.take(i).toList()),
            child: Text(mainName, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          for (final x in lv.tabs.where((x) => !x.closed)) ...[
            const SizedBox(width: 4),
            _SubTabButton(
              tab: x,
              parent: lv.session,
              on: lv.chosen?.childSessionId == x.childSessionId,
              select: () => app.openSubPath(root, [...path.take(i), x.childSessionId]),
              closed: () {
                if (lv.chosen?.childSessionId == x.childSessionId) {
                  app.openSubPath(root, path.take(i).toList());
                }
              },
            ),
          ],
        ],
      ),
    );
    if (i == 0) return row;
    // The rows below: a dashed line over a slightly darker band (the page's `.sub-row + .sub-row`).
    return CustomPaint(
      painter: DashedTopLine(c.line),
      child: ColoredBox(color: Color.lerp(c.panel, c.panel2, .5)!, child: row),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(text, style: TextStyle(color: c.accent, fontSize: 12.5)),
      ),
    );
  }
}

/// The shape of a tab (the page's `.sub-tab`): rounded on top, open at the bottom; the chosen one
/// takes the panel's colour and a line of accent on top.
class _TabShape extends StatelessWidget {
  const _TabShape({super.key, required this.on, required this.child, this.onTap, this.trailing});

  final bool on;
  final Widget child;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 700;
    const radius = BorderRadius.vertical(top: Radius.circular(8));
    return Semantics(
      selected: on,
      button: true,
      child: CustomPaint(
        foregroundPainter: _TabEdge(line: c.line, accent: on ? c.accent : null),
        child: Container(
          constraints: BoxConstraints(maxWidth: narrow ? 180 : 240),
          decoration: BoxDecoration(color: on ? c.panel : c.panel2, borderRadius: radius),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, on ? 6 : 7, trailing == null ? 10 : 4, 6),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(fontSize: 13, color: on ? c.text : c.dim),
                      child: child,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// The tab's edge (the page's `.sub-tab`): left, top and right in the line's colour, rounded on
/// top, open at the bottom; the chosen one with a line of accent inside its top.
class _TabEdge extends CustomPainter {
  _TabEdge({required this.line, this.accent});

  final Color line;
  final Color? accent;

  @override
  void paint(Canvas canvas, Size size) {
    const r = 8.0;
    final p = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(.5, size.height)
      ..lineTo(.5, r)
      ..arcToPoint(const Offset(r, .5), radius: const Radius.circular(r - .5))
      ..lineTo(size.width - r, .5)
      ..arcToPoint(Offset(size.width - .5, r), radius: const Radius.circular(r - .5))
      ..lineTo(size.width - .5, size.height);
    canvas.drawPath(path, p);
    if (accent != null) {
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: const Radius.circular(r),
          topRight: const Radius.circular(r),
        ),
      );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 2), Paint()..color = accent!);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TabEdge old) => old.line != line || old.accent != accent;
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.tab,
    required this.parent,
    required this.on,
    required this.select,
    required this.closed,
  });

  final SubTab tab;
  final String parent;
  final bool on;
  final VoidCallback select;
  final VoidCallback closed;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final status = _status(app, tab, parent);
    final child = app.live.views[tab.childSessionId];
    final lastSeq = child == null || child.events.isEmpty ? 0 : child.events.last.seq;
    final fresh = !on && lastSeq > (app.subSeen[tab.childSessionId] ?? tab.fromSeq);
    final waiting = asksIn(app, tab).isNotEmpty;
    final agent = app.agents.where((a) => a.id == tab.childAgentId).firstOrNull;
    final from = agent?.name ?? '';
    return Tooltip(
      message: '${tab.title}${from.isNotEmpty ? ' ($from)' : ''} · ${subStatusWords(l, status)}',
      child: _TabShape(
        key: Key('sub-tab-${tab.childSessionId}'),
        on: on,
        onTap: select,
        trailing: status == 'running'
            ? null
            : Tooltip(
                message: l.cvSubClose,
                child: InkWell(
                  key: Key('sub-close-${tab.childSessionId}'),
                  onTap: () {
                    app.closeSubagent(parent, tab.childSessionId);
                    closed();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 7, 6),
                    child: RgIcon(RgIcons.x, size: 11, color: c.dim),
                  ),
                ),
              ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(label: subStatusWords(l, status), child: StateDot(status)),
            const SizedBox(width: 6),
            if (agent != null) ...[
              MascotView(agentId: agent.id, state: app.live.mascotStateOf(agent.id), size: 16),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(tab.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (fresh) ...[
              const SizedBox(width: 6),
              Semantics(
                label: l.cvSubFresh,
                child: Container(
                  key: Key('sub-fresh-${tab.childSessionId}'),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.text.withValues(alpha: .75), width: 2),
                  ),
                ),
              ),
            ],
            if (waiting) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: l.cvSubWaits,
                child: RgIcon(
                  RgIcons.shield,
                  key: Key('sub-waits-${tab.childSessionId}'),
                  size: 12,
                  color: c.warn,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A sub-agent's tab: the task it was given, its conversation, and the bar with «Ferma».
class SubagentView extends StatefulWidget {
  const SubagentView({
    super.key,
    required this.tab,
    required this.parentSession,
    required this.parentAgent,
  });

  final SubTab tab;
  final String parentSession;
  final String parentAgent;

  @override
  State<SubagentView> createState() => _SubagentViewState();
}

class _SubagentViewState extends State<SubagentView> {
  late final AppController app = AppScope.read(context);
  late final SessionView view;
  Timer? _tick;
  bool _taskOpen = true;

  @override
  void initState() {
    super.initState();
    view = app.follow(widget.tab.childSessionId);
    _taskOpen = widget.tab.task.length < 600;
  }

  @override
  void dispose() {
    _tick?.cancel();
    app.unfollow(widget.tab.childSessionId);
    super.dispose();
  }

  void _ticking(bool on) {
    if (on && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!on) {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _openSession(String sessionId, String? agentId) {
    // A link to a sub-agent's conversation inside this one: its tab, one level deeper.
    final root = _rootOf();
    final path = app.subPath[root] ?? const [];
    app.openSubPath(root, [...path, sessionId]);
  }

  String _rootOf() {
    for (final e in app.subPath.entries) {
      if (e.value.contains(widget.tab.childSessionId)) return e.key;
    }
    return widget.parentSession;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([view, app.live]),
      builder: (context, _) {
        final tab = widget.tab;
        final mine = view.events.where((e) => e.seq > tab.fromSeq).toList();
        final items = buildItems(
          mine,
          liveText: view.liveText,
          liveThinking: view.liveThinking,
          sessionId: tab.childSessionId,
        ).where((i) => i is! AssistantItem || showsSomething(i)).toList();
        final status = _status(app, tab, widget.parentSession);
        _ticking(status == 'running');
        final lastSeq = view.events.isEmpty ? 0 : view.events.last.seq;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => app.markSubSeen(tab.childSessionId, lastSeq),
        );
        final tools = items.whereType<ToolItem>().length;
        var tokens = 0;
        for (final e in mine) {
          final m = e.payload?['metrics'];
          if (e.type == 'message.assistant' && m is Map) {
            tokens +=
                ((m['inputTokens'] as num?) ?? 0).toInt() +
                ((m['outputTokens'] as num?) ?? 0).toInt();
          }
        }
        final start = DateTime.tryParse(tab.startedAt);
        final end = tab.endedAt != null
            ? DateTime.tryParse(tab.endedAt!)
            : status == 'running'
            ? app.live.now()
            : null;
        final ms = start == null || end == null ? null : end.difference(start).inMilliseconds;
        final waiting = asksIn(app, tab);
        final from = app.agents.where((a) => a.id == widget.parentAgent).firstOrNull?.name ?? '';
        final actions = ChatActions(
          sessionId: tab.childSessionId,
          agent: app.agents.where((a) => a.id == tab.childAgentId).firstOrNull,
          openSession: _openSession,
          readOnly: true,
        );
        final call = view.call;
        final body = <Widget>[
          _TaskCard(
            title: tab.title,
            task: tab.task,
            from: from,
            open: _taskOpen,
            onToggle: () => setState(() => _taskOpen = !_taskOpen),
          ),
          for (final item in items) ChatItemView(item: item, actions: actions),
          if (status == 'running' && call != null)
            TurnProgress(call: call, now: app.live.now, still: app.reduceMotion),
          if (tab.summary != null && status != 'running')
            _Notice(
              key: const Key('sub-ended'),
              icon: RgIcons.info,
              color: status == 'done' ? c.ok : c.err,
              text: switch (status) {
                'done' => l.cvSubEndedDone,
                'failed' => l.cvSubEndedFailed,
                _ => l.cvSubEndedStopped,
              },
            ),
          if (tab.ended == null && status == 'stopped')
            _Notice(
              key: const Key('sub-interrupted'),
              icon: RgIcons.alert,
              color: c.warn,
              text: l.cvSubInterrupted,
            ),
          for (final r in waiting)
            ChatRequestCard(key: Key('sub-request-${r.requestId}'), request: r),
        ];
        return Column(
          children: [
            CommandStrip(sessionId: tab.childSessionId, view: view),
            Expanded(
              child: ListView.builder(
                key: Key('sub-view-${tab.childSessionId}'),
                reverse: true,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                itemCount: body.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: MaxWidthCenter(child: body[body.length - 1 - i]),
                ),
              ),
            ),
            _SubBar(
              status: status,
              ms: ms,
              tools: tools,
              tokens: tokens,
              onStop: () =>
                  app.socket?.send({'type': 'session.interrupt', 'sessionId': tab.childSessionId}),
            ),
          ],
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.title,
    required this.task,
    required this.from,
    required this.open,
    required this.onToggle,
  });

  final String title;
  final String task;
  final String from;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Container(
      key: const Key('sub-task'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                RgIcon(open ? RgIcons.chevronDown : RgIcons.chevronRight, size: 13, color: c.dim),
                Text(
                  from.isNotEmpty ? l.cvSubTaskFrom(from) : l.cvSubTask,
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(title, style: TextStyle(color: c.dim, fontSize: 13.5)),
              ],
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .4),
                child: SingleChildScrollView(
                  child: SelectableText(task, style: TextStyle(color: c.text, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.icon, required this.color, required this.text});

  final RgIcons icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: .40)),
      ),
      child: Row(
        children: [
          RgIcon(icon, size: 13, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: c.text, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Instead of the composer (the page's `.sub-bar`).
class _SubBar extends StatelessWidget {
  const _SubBar({
    required this.status,
    required this.ms,
    required this.tools,
    required this.tokens,
    required this.onStop,
  });

  final String status;
  final int? ms;
  final int tools;
  final int tokens;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final dim = TextStyle(color: c.dim, fontSize: 13);
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return Container(
      key: const Key('sub-bar'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.panel2,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StateDot(status),
                      const SizedBox(width: 6),
                      Text(
                        subStatusWords(l, status),
                        style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Text(l.cvSubTime(duration(ms)), style: dim),
                  Text(l.cvSubTools('$tools'), style: dim),
                  Text(l.cvSubTokens(kTokens(tokens)), style: dim),
                  if (!narrow) Text(l.cvSubNoWrite, style: dim),
                ],
              ),
            ),
            if (status == 'running')
              OutlinedButton.icon(
                key: const Key('sub-stop'),
                onPressed: onStop,
                icon: RgIcon(RgIcons.stop, size: 13, color: c.text),
                label: Text(l.cvSubStop),
              ),
          ],
        ),
      ),
    );
  }
}
