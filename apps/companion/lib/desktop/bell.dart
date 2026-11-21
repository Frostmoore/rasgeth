// The bell in the control room's bar (3.8.8, the user: «the "For you" card is no use to me: the
// notifications in the bar at the top are better»). As the page's bell (App.tsx, Bell.tsx): in the
// bar, right after the search, with the count of what waits for the person; a truly dangerous
// request makes the badge solid red and the bell nod (never with «reduce motion»). A click opens
// a drop-down under it: the permissions with the page's quick answers (a truly dangerous one only
// from its own screen), the questions, the conversations at work, «See all» (the list in the
// panel). Esc or a click outside closes it.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../screens/inbox_screen.dart';
import '../settings/extensions/extensions_screen.dart' show openExtensionsSettings;
import '../settings/extensions/proposals_block.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import 'desk_controller.dart';

/// The bell's count: what waits for the person (the page's `waiting`, the automations' notices
/// included, G42.9).
int bellCount(AppController app) => app.live.waiting;

/// Whether a truly dangerous request waits (G36.17b).
bool bellCritical(AppController app) => app.live.approvals.any((r) => r.isCritical);

/// The bell with its badge. [onTap] opens the drop-down.
class DeskBell extends StatefulWidget {
  const DeskBell({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<DeskBell> createState() => _DeskBellState();
}

class _DeskBellState extends State<DeskBell> with SingleTickerProviderStateMixin {
  late final _nod = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void dispose() {
    _nod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final n = bellCount(app);
    final critical = bellCritical(app);
    final still = app.reduceMotion || MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (critical && !still) {
      if (!_nod.isAnimating) _nod.repeat();
    } else if (_nod.isAnimating) {
      _nod
        ..stop()
        ..value = 0;
    }
    final bell = RgIcon(RgIcons.bell, size: 18, color: n > 0 ? c.text : c.dim);
    return Tooltip(
      message: l.bellTooltip,
      child: Semantics(
        button: true,
        label: '${l.bellTooltip}: ${l.deskForYouCount(n)}',
        excludeSemantics: true,
        child: InkWell(
          key: const Key('desk-bell'),
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onTap,
          child: SizedBox(
            width: 36,
            height: 32,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // A short nod twice, then a pause: the bell hangs from its top.
                AnimatedBuilder(
                  animation: _nod,
                  builder: (_, child) {
                    final t = _nod.value;
                    final a = t < .4 ? math.sin(t / .4 * math.pi * 4) * (1 - t / .4) * .28 : 0.0;
                    return Transform.rotate(angle: a, alignment: Alignment.topCenter, child: child);
                  },
                  child: bell,
                ),
                if (n > 0)
                  Positioned(
                    right: 0,
                    top: 2,
                    child: Container(
                      key: Key(critical ? 'desk-bell-badge-critical' : 'desk-bell-badge'),
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: critical ? c.critical : c.accent,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: c.panel, width: 1.5),
                        boxShadow: critical
                            ? [BoxShadow(color: c.critical.withValues(alpha: .45), blurRadius: 6)]
                            : null,
                      ),
                      child: Text(
                        n > 99 ? '99+' : '$n',
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
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

/// Opens the drop-down under [anchor] (the bell's key). Esc or a click outside closes it.
Future<void> showBellPopover(
  BuildContext context, {
  required DeskController desk,
  required GlobalKey anchor,
}) {
  final box = anchor.currentContext?.findRenderObject() as RenderBox?;
  final size = MediaQuery.sizeOf(context);
  final rect = box == null || !box.attached
      ? Rect.fromLTWH(size.width - 60, 6, 36, 32)
      : box.localToGlobal(Offset.zero) & box.size;
  return showRgOverlay<void>(
    context: context,
    barrierLabel: AppLocalizations.of(context).bellTitle,
    barrierColor: Colors.black.withValues(alpha: .06),
    transitionDuration: const Duration(milliseconds: 110),
    pageBuilder: (ctx, _, _) => DeskScope(
      desk: desk,
      child: _Placed(anchor: rect),
    ),
  );
}

class _Placed extends StatelessWidget {
  const _Placed({required this.anchor});

  final Rect anchor;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    const width = 400.0;
    final right = (size.width - anchor.right).clamp(8.0, size.width - width - 8);
    return Stack(
      children: [
        Positioned(
          top: anchor.bottom + 6,
          right: right,
          width: math.min(width, size.width - 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: math.max(240, size.height - anchor.bottom - 40)),
            child: const BellPanel(),
          ),
        ),
      ],
    );
  }
}

/// What the drop-down shows.
class BellPanel extends StatelessWidget {
  const BellPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.read(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    void close() => Navigator.of(context).maybePop();
    return Material(
      key: const Key('bell-panel'),
      color: c.panel,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: .25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListenableBuilder(
        listenable: app.live,
        builder: (context, _) {
          final asks = [...app.live.approvals]
            ..sort(
              (a, b) => a.isCritical != b.isCritical
                  ? (a.isCritical ? -1 : 1)
                  : a.createdAt.compareTo(b.createdAt),
            );
          final questions = app.live.questions;
          final running = app.live.sessions.where((s) => s.running && !s.archived).toList()
            ..sort((a, b) => b.when.compareTo(a.when));
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 6, 8),
                child: Row(
                  children: [
                    RgIcon(RgIcons.bell, size: 17, color: c.text),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.bellTitle,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: c.text),
                      ),
                    ),
                    IconButton(
                      key: const Key('bell-close'),
                      tooltip: l.deskClose,
                      visualDensity: VisualDensity.compact,
                      onPressed: close,
                      icon: RgIcon(RgIcons.x, size: 16, color: c.dim),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.line),
              Flexible(
                child: ListView(
                  key: const Key('bell-list'),
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  children: [
                    if (app.live.notices.isNotEmpty) ...[
                      _Head('${l.auAutomationNotices} (${app.live.notices.length})'),
                      for (final n in app.live.notices)
                        _NoticeLine(
                          key: Key('bell-notice-${n.runId}'),
                          name: n.name,
                          text: n.text,
                          bad: n.status != 'ok',
                          onTap: n.sessionId == null
                              ? null
                              : () {
                                  close();
                                  desk.show(PanelConversation(n.sessionId!));
                                },
                          onDismiss: () => app.live.dismissNotice(n.runId),
                        ),
                    ],
                    // G42.11: the agents' proposals, as the page's bell.
                    ProposalsBlock(
                      onOpen: () {
                        final nav = Navigator.of(context, rootNavigator: true);
                        close();
                        unawaited(openExtensionsSettings(nav.context));
                      },
                    ),
                    _Head(l.bellPermissions(asks.length)),
                    if (asks.isEmpty) _Dim(l.bellNoApprovals),
                    for (final r in asks) _AskRow(request: r, close: close),
                    _Head(l.bellQuestions(questions.length)),
                    if (questions.isEmpty) _Dim(l.bellNoQuestions),
                    for (final q in questions)
                      _Line(
                        key: Key('bell-question-${q.requestId}'),
                        agentId: q.agentId,
                        who: q.agentName,
                        text: q.questions.firstOrNull?.question ?? '',
                        action: l.bellAnswer,
                        onAction: () {
                          close();
                          desk.show(PanelConversation(q.sessionId));
                        },
                      ),
                    _Head(l.bellWorking(running.length)),
                    if (running.isEmpty) _Dim(l.bellNothingRunning),
                    for (final s in running.take(8))
                      _Line(
                        key: Key('bell-running-${s.id}'),
                        agentId: s.agentId,
                        who: app.agents.where((a) => a.id == s.agentId).firstOrNull?.name ?? '',
                        text: s.task ?? s.title ?? l.untitled,
                        running: true,
                        onTap: () {
                          close();
                          desk.show(PanelConversation(s.id));
                        },
                      ),
                  ],
                ),
              ),
              Divider(height: 1, color: c.line),
              TextButton(
                key: const Key('bell-see-all'),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  shape: const RoundedRectangleBorder(),
                ),
                onPressed: () {
                  close();
                  desk.show(const PanelPage(PanelScreen.inbox));
                },
                child: Text(l.bellSeeAll, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        letterSpacing: .6,
        fontWeight: FontWeight.w700,
        color: RgColors.of(context).dim,
      ),
    ),
  );
}

class _Dim extends StatelessWidget {
  const _Dim(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 2, 6, 4),
    child: Text(text, style: TextStyle(fontSize: 13, color: RgColors.of(context).dim)),
  );
}

class _Face extends StatelessWidget {
  const _Face({required this.agentId});

  final String agentId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final a = app.agents.where((x) => x.id == agentId).firstOrNull;
    if (a == null) return RgIcon(RgIcons.user, size: 22, color: RgColors.of(context).dim);
    return MascotView(agentId: a.id, spec: a.mascot, state: app.live.mascotStateOf(a.id), size: 28);
  }
}

const _pad = EdgeInsets.symmetric(horizontal: 12);
const _min = Size(0, 32);

/// A permission request: who, what in words, and the page's quick answers.
class _AskRow extends StatelessWidget {
  const _AskRow({required this.request, required this.close});

  final PermissionRequest request;
  final VoidCallback close;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.read(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = request;
    final critical = r.isCritical;
    final what = r.wordsIn(l.localeName)?.what ?? '${r.tool}: ${requestSummary(r)}';
    final nav = Navigator.of(context, rootNavigator: true);
    return Container(
      key: Key('bell-request-${r.requestId}'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: critical ? c.criticalSoft : c.bg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: critical ? c.critical : c.line, width: critical ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Face(agentId: r.agentId),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      critical ? l.requestCritical(r.agentName) : r.agentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: critical ? c.criticalText : c.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      what,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.text, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: [
              if (r.sessionId != null)
                TextButton(
                  key: Key('bell-open-${r.requestId}'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: _pad,
                    minimumSize: _min,
                  ),
                  onPressed: () {
                    close();
                    desk.show(PanelConversation(r.sessionId!));
                  },
                  child: Text(l.open),
                ),
              OutlinedButton(
                key: Key('bell-deny-${r.requestId}'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: _pad,
                  minimumSize: _min,
                ),
                onPressed: () => app.resolvePermission(r, allow: false),
                child: Text(l.bellDeny),
              ),
              if (critical)
                FilledButton(
                  key: Key('bell-look-${r.requestId}'),
                  style: FilledButton.styleFrom(
                    backgroundColor: c.critical,
                    visualDensity: VisualDensity.compact,
                    padding: _pad,
                    minimumSize: _min,
                  ),
                  onPressed: () {
                    close();
                    nav.push(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) => CriticalRequestScreen(request: r),
                      ),
                    );
                  },
                  child: Text(l.bellLook),
                )
              else
                FilledButton(
                  key: Key('bell-allow-${r.requestId}'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: _pad,
                    minimumSize: _min,
                  ),
                  onPressed: () => app.resolvePermission(r, allow: true),
                  child: Text(l.bellAllow),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A question or a conversation at work: who, a line, and what to do.
class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.agentId,
    required this.who,
    required this.text,
    this.action,
    this.onAction,
    this.onTap,
    this.running = false,
  });

  final String agentId;
  final String who;
  final String text;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback? onTap;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap ?? onAction,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            _Face(agentId: agentId),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.text),
                  ),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.dim),
                  ),
                ],
              ),
            ),
            if (running)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(color: c.ok, shape: BoxShape.circle),
              ),
            if (action != null)
              TextButton(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: onAction,
                child: Text(action!),
              ),
          ],
        ),
      ),
    );
  }
}

/// An automation's message (G42.9): its name, the message, «Dismiss».
class _NoticeLine extends StatelessWidget {
  const _NoticeLine({
    super.key,
    required this.name,
    required this.text,
    required this.bad,
    required this.onTap,
    required this.onDismiss,
  });

  final String name;
  final String text;
  final bool bad;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 0, 6),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: (bad ? c.err : c.accent).withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Center(child: RgIcon(RgIcons.clock, size: 15, color: bad ? c.err : c.accent)),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c.text),
                  ),
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: c.dim),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l.auDismiss,
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
              icon: RgIcon(RgIcons.x, size: 14, color: c.dim),
            ),
          ],
        ),
      ),
    );
  }
}
