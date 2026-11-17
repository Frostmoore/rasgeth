// For you (G40.7, G40.9): what waits for the person, as a stack of cards. The app is one of the
// channels that get every request at once (G36.17): the first answer closes the other copies and
// says where it was given. Ordinary requests: Yes or No on the card, or a swipe (right yes, left
// no). Truly dangerous ones (G36.17b) come first and never swipe: never the quick yes, they open a
// full screen of their own, where the yes asks once more. Questions: their options, sent with
// `question.answer`. «Later» puts the top card at the bottom of the stack.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/common.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';

/// What a permission asks to do, in one line (the command, the path, else the input).
String requestSummary(PermissionRequest r) {
  final i = r.input;
  if (i is Map<String, dynamic>) {
    for (final k in ['command', 'path', 'url', 'to', 'name']) {
      final v = i[k];
      if (v is String && v.isNotEmpty) return v;
    }
  }
  final s = jsonEncode(i);
  return s.length > 240 ? '${s.substring(0, 240)}…' : s;
}

/// The stack's order: truly dangerous requests first, then the oldest first; the ones put off
/// with «Later» ([later], oldest put off first) at the bottom.
List<PersonRequest> stackOrder(List<PersonRequest> all, List<String> later) {
  bool critical(PersonRequest r) => r is PermissionRequest && r.isCritical;
  final now = all.where((r) => !later.contains(r.requestId)).toList()
    ..sort((a, b) {
      final c = (critical(b) ? 1 : 0) - (critical(a) ? 1 : 0);
      return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
    });
  final put = [for (final id in later) ...all.where((r) => r.requestId == id)];
  return [...now, ...put];
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final List<String> _later = [];

  /// Answered here by a swipe: off the stack at once, before the server's confirmation.
  final Set<String> _answered = {};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        final all = app.live.requests;
        _later.removeWhere((id) => !all.any((r) => r.requestId == id));
        _answered.removeWhere((id) => !all.any((r) => r.requestId == id));
        final list = stackOrder(
          all.where((r) => !_answered.contains(r.requestId)).toList(),
          _later,
        );
        final top = list.firstOrNull;
        final critical = top is PermissionRequest && top.isCritical;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: l.tabInbox,
              trailing: list.length < 2
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.inboxPosition('1', '${list.length}'),
                          key: const Key('inbox-position'),
                          style: TextStyle(color: c.dim, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          key: const Key('inbox-later'),
                          onPressed: () => setState(() => _later.add(top!.requestId)),
                          child: Text(l.inboxNext),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: top == null
                  ? EmptyState(icon: RgIcons.bell, text: l.inboxEmpty)
                  // One card at a time, never wider than a phone's on a computer (the room's
                  // side panel is narrower than the window: its own width counts).
                  : LayoutBuilder(
                      builder: (context, box) => ListView(
                        key: const Key('inbox-stack'),
                        padding: EdgeInsets.fromLTRB(
                          16 + ((box.maxWidth - 32 - 640) / 2).clamp(0, 9999),
                          4,
                          16 + ((box.maxWidth - 32 - 640) / 2).clamp(0, 9999),
                          24,
                        ),
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // The cards behind, peeking under the top one.
                              for (var i = (list.length - 1).clamp(0, 2); i >= 1; i--)
                                Positioned(
                                  left: 10.0 * i,
                                  right: 10.0 * i,
                                  top: 12.0 * i,
                                  bottom: -12.0 * i,
                                  child: _Behind(depth: i, request: list[i]),
                                ),
                              SwipeCard(
                                key: ValueKey(top.requestId),
                                request: top,
                                onAnswered: () => setState(() => _answered.add(top.requestId)),
                                child: switch (top) {
                                  final PermissionRequest p => PermissionCard(request: p),
                                  final QuestionRequest q => QuestionCard(request: q),
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          if (top is PermissionRequest)
                            Text(
                              critical ? l.inboxCriticalHint : l.inboxSwipeHint,
                              key: const Key('inbox-hint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: critical ? c.criticalText : c.dim,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// A card waiting under the top one: its edge only (the agent's name for screen readers).
class _Behind extends StatelessWidget {
  const _Behind({required this.depth, required this.request});

  final int depth;
  final PersonRequest request;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final critical = request is PermissionRequest && (request as PermissionRequest).isCritical;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(critical ? c.criticalSoft : c.panel, c.bg, .25 * depth),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: critical ? c.critical : c.line),
        ),
      ),
    );
  }
}

/// The top card: an ordinary permission follows the finger and answers past a threshold (right
/// yes, left no); a critical one or a question does not move (a tap on a critical one opens its
/// screen). With «Reduce motion» the card does not fly away, it just goes.
class SwipeCard extends StatefulWidget {
  const SwipeCard({super.key, required this.request, required this.child, this.onAnswered});

  final PersonRequest request;
  final Widget child;

  /// The answer went out: the stack moves on.
  final VoidCallback? onAnswered;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() => _dx = _anim?.value ?? _dx));
  Animation<double>? _anim;
  double _dx = 0;
  bool _busy = false;

  static const _threshold = 110.0;

  bool get _swipes {
    final r = widget.request;
    return r is PermissionRequest && !r.isCritical;
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  bool get _reduced =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ||
      AppScope.read(context).reduceMotion;

  Future<void> _to(double x) async {
    if (_reduced) {
      setState(() => _dx = x);
      return;
    }
    _anim = Tween(begin: _dx, end: x).animate(CurvedAnimation(parent: _fly, curve: Curves.easeOut));
    await _fly.forward(from: 0);
  }

  Future<void> _end(double velocity) async {
    final allow = _dx > _threshold || velocity > 900;
    final deny = _dx < -_threshold || velocity < -900;
    if (!allow && !deny) return _to(0);
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final r = widget.request as PermissionRequest;
    final width = MediaQuery.sizeOf(context).width;
    setState(() => _busy = true);
    await _to(allow ? width : -width);
    final ok = await app.resolvePermission(r, allow: allow);
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(l.notLive)));
      await _to(0);
      return;
    }
    widget.onAnswered?.call();
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(allow ? l.inboxSaidYes(r.agentName) : l.inboxSaidNo(r.agentName)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final r = widget.request;
    final k = (_dx.abs() / _threshold).clamp(0.0, 1.0);
    Widget card = widget.child;
    if (r is PermissionRequest && r.isCritical) {
      // No swipe: a tap opens the full screen.
      card = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => CriticalRequestScreen(request: r),
          ),
        ),
        child: card,
      );
    }
    if (!_swipes) return card;
    return GestureDetector(
      key: Key('swipe-${r.requestId}'),
      onHorizontalDragUpdate: _busy ? null : (d) => setState(() => _dx += d.delta.dx),
      onHorizontalDragEnd: _busy ? null : (d) => _end(d.primaryVelocity ?? 0),
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..translateByDouble(_dx, 0, 0, 1)
          ..rotateZ(_dx / 1600),
        child: Stack(
          children: [
            card,
            if (_dx.abs() > 4)
              // In the card's free corners: yes bottom left, no top right.
              Positioned(
                top: _dx < 0 ? 12 : null,
                bottom: _dx > 0 ? 14 : null,
                left: _dx > 0 ? 14 : null,
                right: _dx < 0 ? 14 : null,
                child: Opacity(
                  opacity: k,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: (_dx > 0 ? c.ok : c.err).withValues(alpha: .14),
                      border: Border.all(color: _dx > 0 ? c.ok : c.err, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _dx > 0 ? l.yes : l.no,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: _dx > 0 ? c.ok : c.err,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  const PermissionCard({super.key, required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = request;
    final critical = r.isCritical;
    final lang = Localizations.localeOf(context).languageCode;
    return Container(
      key: Key('request-${r.requestId}'),
      decoration: BoxDecoration(
        color: critical ? c.criticalSoft : c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: critical ? c.critical : c.line, width: critical ? 2 : 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RgIcon(
                critical ? RgIcons.alert : RgIcons.shield,
                size: 18,
                color: critical ? c.critical : c.dim,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  critical ? l.requestCritical(r.agentName) : l.requestFrom(r.agentName),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: critical ? c.criticalText : c.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // What it asks, in plain words first (p3.8.9); the command stays below, small.
          Text(
            requestLineFor(r, lang),
            key: Key('inbox-what-${r.requestId}'),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, height: 1.3, color: c.text),
          ),
          const SizedBox(height: 4),
          Text(
            '${r.tool}: ${requestSummary(r)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, color: c.dim),
          ),
          for (final reason in (r.wordsIn(lang)?.reasons ?? r.reasons).take(3))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(reason, style: TextStyle(fontSize: 13, color: c.dim)),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                key: Key('deny-${r.requestId}'),
                onPressed: () => app.resolvePermission(r, allow: false),
                child: Text(l.no),
              ),
              const SizedBox(width: 10),
              if (critical)
                FilledButton(
                  key: Key('open-${r.requestId}'),
                  style: FilledButton.styleFrom(backgroundColor: c.critical),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      fullscreenDialog: true,
                      builder: (_) => CriticalRequestScreen(request: r),
                    ),
                  ),
                  child: Text(l.requestLook),
                )
              else
                FilledButton(
                  key: Key('allow-${r.requestId}'),
                  onPressed: () => app.resolvePermission(r, allow: true),
                  child: Text(l.yes),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A request in one line the person reads (p3.8.9): the server's words in [lang] (G42.1,
/// `withRequestWords`: «Writes the script x.sh and runs it…»), else the command or the path.
String requestLineFor(PermissionRequest r, String lang) =>
    r.wordsIn(lang)?.what ?? requestSummary(r);

/// How a request was closed elsewhere, in a sentence (p3.8.9): «You already answered from the page
/// or another window: allowed», «… from Telegram: denied», «Nobody answered in time: denied».
String closedLine(AppLocalizations l, ({String decision, String? via}) d) {
  final answer = d.decision == 'allow' ? l.requestAnswerAllowed : l.requestAnswerDenied;
  final via = d.via;
  if (via == null || via.isEmpty || via == 'classifier') return l.requestDoneElsewhere(answer);
  if (via == 'web' || via.startsWith('app')) return l.requestDoneHere(answer);
  if (via == 'timeout') return l.requestDoneTimeout(answer);
  return l.requestDoneChat('${via[0].toUpperCase()}${via.substring(1)}', answer);
}

/// A truly dangerous request, full screen: what it does in a line, then No (first) or a yes asked
/// twice. There is always a way out (p3.8.9, after a screen left with no exit once answered from
/// the page): the close button at the top, Esc on a computer, back on a phone. Answered elsewhere
/// (the page, a chat, another window), it says so with the answer and closes by itself after
/// [autoClose], or with «Close».
class CriticalRequestScreen extends StatefulWidget {
  const CriticalRequestScreen({
    super.key,
    required this.request,
    this.autoClose = const Duration(seconds: 5),
  });

  final PermissionRequest request;
  final Duration autoClose;

  @override
  State<CriticalRequestScreen> createState() => _CriticalRequestScreenState();
}

class _CriticalRequestScreenState extends State<CriticalRequestScreen> {
  Timer? _timer;

  /// Answered from this screen: it closes after the answer, without «already answered».
  bool _answering = false;
  bool _gone = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    if (_gone || !mounted) return;
    _gone = true;
    _timer?.cancel();
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = widget.request;
    final lang = Localizations.localeOf(context).languageCode;
    final w = r.wordsIn(lang);
    TextStyle strong(Color color) => TextStyle(fontWeight: FontWeight.w700, color: color);
    return Scaffold(
      backgroundColor: c.criticalSoft,
      body: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
        child: Focus(
          autofocus: true,
          child: SafeArea(
            child: ListenableBuilder(
              listenable: app.live,
              builder: (context, _) {
                final open = app.live.approvals.any((a) => a.requestId == r.requestId);
                final done = app.live.closedRequests[r.requestId];
                if (!open && !_answering && _timer == null) {
                  _timer = Timer(widget.autoClose, _close);
                }
                return ListView(
                  key: const Key('critical-screen'),
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 20),
                  children: [
                    Row(
                      children: [
                        RgIcon(RgIcons.alert, size: 30, color: c.critical),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              l.criticalTitle,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: c.criticalText,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('critical-close'),
                          tooltip: l.requestCloseHint,
                          onPressed: _close,
                          icon: RgIcon(RgIcons.x, size: 22, color: c.text),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            l.criticalBody(r.agentName),
                            style: TextStyle(fontSize: 15.5, color: c.text),
                          ),
                          const SizedBox(height: 14),
                          // What it does, in plain words, before anything technical.
                          Text(
                            requestLineFor(r, lang),
                            key: const Key('critical-what'),
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.35,
                              fontWeight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (w != null && w.critical.isNotEmpty)
                            for (final x in w.critical)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(x, style: strong(c.criticalText)),
                              )
                          else
                            for (final d in r.critical)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${criticalLabel(l, d.id)}'
                                  '${d.target == null ? '' : ': ${d.target}'}',
                                  style: strong(c.criticalText),
                                ),
                              ),
                          for (final reason in w?.reasons ?? const <String>[])
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(reason, style: TextStyle(color: c.dim)),
                            ),
                          const SizedBox(height: 18),
                          if (!open)
                            Container(
                              key: const Key('critical-done'),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: c.panel,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: c.line),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    done == null
                                        ? l.requestClosed(app.live.lastClosedVia ?? '-')
                                        : closedLine(l, done),
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.requestDoneClosing,
                                    style: TextStyle(color: c.dim, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    key: const Key('critical-done-close'),
                                    onPressed: _close,
                                    child: Text(l.close),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            FilledButton(
                              key: const Key('critical-no'),
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              onPressed: () async {
                                setState(() => _answering = true);
                                await app.resolvePermission(r, allow: false);
                                _close();
                              },
                              child: Text(l.criticalNo),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              key: const Key('critical-yes'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                foregroundColor: c.critical,
                                side: BorderSide(color: c.critical),
                              ),
                              onPressed: () async {
                                final sure = await askConfirm(
                                  context,
                                  title: l.criticalConfirmTitle,
                                  body: l.criticalConfirmBody,
                                  yes: l.criticalYes,
                                  danger: true,
                                );
                                if (!sure || !mounted) return;
                                setState(() => _answering = true);
                                await app.resolvePermission(r, allow: true, fromFullScreen: true);
                                _close();
                              },
                              child: Text(l.criticalYes),
                            ),
                          ],
                          const SizedBox(height: 22),
                          // The technical details, small, at the bottom.
                          Text(
                            l.requestTechDetails,
                            style: TextStyle(color: c.dim, fontSize: 12.5),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(maxHeight: 260),
                            decoration: BoxDecoration(
                              color: c.panel,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: c.line),
                            ),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                '${r.tool}\n'
                                '${const JsonEncoder.withIndent('  ').convert(r.input)}',
                                key: const Key('critical-input'),
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: c.dim,
                                ),
                              ),
                            ),
                          ),
                          for (final reason in r.reasons)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(reason, style: TextStyle(color: c.dim, fontSize: 12)),
                            ),
                        ],
                      ),
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

/// The danger's kind in words (`CRITICAL_IDS`).
String criticalLabel(AppLocalizations l, String id) => switch (id) {
  'critical-system' => l.criticalSystem,
  'critical-delete' => l.criticalDelete,
  'critical-secret' => l.criticalSecret,
  'critical-payment' => l.criticalPayment,
  'critical-protections' => l.criticalProtections,
  _ => id,
};

class QuestionCard extends StatefulWidget {
  const QuestionCard({super.key, required this.request});

  final QuestionRequest request;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  late final List<Set<String>> _chosen = [for (final _ in widget.request.questions) <String>{}];
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final q = widget.request;
    final ready = _chosen.every((s) => s.isNotEmpty);
    return Container(
      key: Key('question-${q.requestId}'),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accentDim),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RgIcon(RgIcons.help, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.questionFrom(q.agentName),
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
              ),
            ],
          ),
          if (q.plan != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                q.plan!,
                maxLines: 8,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.dim, fontSize: 13.5),
              ),
            ),
          for (final (i, qq) in q.questions.indexed) ...[
            const SizedBox(height: 8),
            Text(qq.question, style: TextStyle(color: c.text, fontSize: 15)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final o in qq.options)
                  ChoiceChip(
                    key: Key('option-${q.requestId}-$i-${o.label}'),
                    showCheckmark: false,
                    label: Text(o.label),
                    tooltip: o.description,
                    selected: _chosen[i].contains(o.label),
                    onSelected: (on) => setState(() {
                      if (!qq.multiSelect) _chosen[i].clear();
                      on ? _chosen[i].add(o.label) : _chosen[i].remove(o.label);
                    }),
                  ),
              ],
            ),
          ],
          if (_failed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l.notLive, style: TextStyle(color: c.err, fontSize: 13)),
            ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: Key('answer-${q.requestId}'),
              onPressed: ready
                  ? () => setState(
                      () => _failed = !app.answerQuestion(q, [for (final s in _chosen) s.toList()]),
                    )
                  : null,
              child: Text(l.answer),
            ),
          ),
        ],
      ),
    );
  }
}
