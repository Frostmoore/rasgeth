// Agents at work together (3.8.10), as the app draws it: the «queued (2nd of 3)» pill, the banner of
// a conversation waiting for a place («Passa avanti», «Vedi la coda»), the queue's list with its
// rows and the window that shows it. The page draws the same from the same `turns.queue`.
import 'package:flutter/material.dart';

import '../api/turn_queue.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../mascot/mascot_view.dart';
import '../screens/at_work_screen.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'icons.dart';

/// «2°» in Italian, «2nd» in English.
String nthWord(AppLocalizations l, int n) {
  if (l.localeName.startsWith('it')) return '$n°';
  final teen = n % 100 >= 11 && n % 100 <= 13;
  final suffix = teen
      ? 'th'
      : switch (n % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$n$suffix';
}

/// «in coda (2° di 3)».
String queuedWords(AppLocalizations l, LinePlace p) => l.queuedNth(nthWord(l, p.place), p.of);

/// The colour of waiting: warm, distinct from the accent of working.
Color queueColor(RgColors c) => c.warn;

/// A small pill: the clock and «in coda (2° di 3)».
class QueuePill extends StatelessWidget {
  const QueuePill({super.key, required this.place, this.dense = false});

  final LinePlace place;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final col = queueColor(c);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 8, vertical: dense ? 1 : 3),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: col.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(RgIcons.clock, size: dense ? 11 : 13, color: c.warnText),
          const SizedBox(width: 4),
          Text(
            queuedWords(l, place),
            style: TextStyle(
              fontSize: dense ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: c.warnText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Over a conversation that waits for a place: what it waits for and what the person can do.
class QueueBanner extends StatelessWidget {
  const QueueBanner({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final place = app.live.turns.placeOf(sessionId);
    if (place == null) return const SizedBox.shrink();
    final col = queueColor(c);
    return Container(
      key: const Key('queue-banner'),
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.withValues(alpha: .40)),
      ),
      // Wide: one line, the buttons at its end; narrow: the buttons under the words.
      child: LayoutBuilder(
        builder: (context, box) {
          final words = Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: col.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: RgIcon(RgIcons.clock, size: 16, color: c.warnText),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l.queuedBanner(nthWord(l, place.place), place.of),
                  style: TextStyle(color: c.text, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
          final buttons = Wrap(
            spacing: 4,
            children: [
              if (place.place > 1)
                TextButton.icon(
                  key: const Key('queue-banner-first'),
                  onPressed: () => _moveFirst(context, sessionId),
                  icon: RgIcon(RgIcons.arrowUp, size: 15, color: c.accent),
                  label: Text(l.queueMoveFirst),
                ),
              TextButton(
                key: const Key('queue-banner-see'),
                onPressed: () => showTurnQueue(context),
                child: Text(l.queueSee),
              ),
            ],
          );
          if (box.maxWidth >= 640) {
            return Row(
              children: [
                Expanded(child: words),
                const SizedBox(width: 8),
                buttons,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              words,
              Align(alignment: Alignment.centerRight, child: buttons),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _moveFirst(BuildContext context, String sessionId) async {
  final app = AppScope.read(context);
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!await app.moveFirst(sessionId)) {
    messenger?.showSnackBar(SnackBar(content: Text(l.queueMoveFailed)));
  }
}

/// The queue in a window over the screen.
Future<void> showTurnQueue(BuildContext context) {
  final l = AppLocalizations.of(context);
  final size = MediaQuery.sizeOf(context);
  return showRgWindow<void>(
    context: context,
    builder: (ctx) {
      final c = RgColors.of(ctx);
      return Dialog(
        key: const Key('queue-window'),
        insetPadding: const EdgeInsets.all(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 560, maxHeight: size.height * .8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                child: Row(
                  children: [
                    RgIcon(RgIcons.users, size: 20, color: c.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.queueTitle,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
                      ),
                    ),
                    IconButton(
                      key: const Key('queue-close'),
                      tooltip: l.back,
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: RgIcon(RgIcons.x, color: c.dim),
                    ),
                  ],
                ),
              ),
              const Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 8),
                  child: TurnQueueList(),
                ),
              ),
              Divider(height: 1, color: c.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('queue-settings'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      openAtWork(context);
                    },
                    icon: RgIcon(RgIcons.settings, size: 15, color: c.accent),
                    label: Text(l.queueOpenSettings),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The places taken and the line, one row per waiting conversation.
class TurnQueueList extends StatelessWidget {
  const TurnQueueList({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final q = app.live.turns;
    final limit = q.limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                limit == null ? l.atWorkPlacesNoLimit(q.working) : l.atWorkPlaces(q.working, limit),
                key: const Key('queue-places'),
                style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              if (limit != null) ...[
                const SizedBox(height: 8),
                _Places(working: q.working, limit: limit),
              ],
            ],
          ),
        ),
        if (q.queued.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              l.queueEmpty,
              key: const Key('queue-empty'),
              style: TextStyle(color: c.dim, fontSize: 13.5),
            ),
          )
        else
          for (final (i, t) in q.queued.indexed) _QueueRow(turn: t, index: i),
      ],
    );
  }
}

/// The places as a row of segments: taken ones lit, free ones outlined.
class _Places extends StatelessWidget {
  const _Places({required this.working, required this.limit});

  final int working;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Row(
      children: [
        for (var i = 0; i < limit; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i == limit - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i < working ? c.accent : c.line.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.turn, required this.index});

  final QueuedTurn turn;
  final int index;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final agent = app.agents.where((a) => a.id == turn.agentId).firstOrNull;
    final row = app.live.sessions.where((s) => s.id == turn.sessionId).firstOrNull;
    final minutes = turn.since == null
        ? 0
        : app.live.now().difference(turn.since!).inMinutes.clamp(0, 100000);
    final facts = [
      l.queueWaited(minutes),
      if (turn.first) l.queueMoved else if (turn.child) l.queueChild,
    ];
    final next = index == 0;
    return Container(
      key: Key('queue-row-${turn.sessionId}'),
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: next ? queueColor(c).withValues(alpha: .08) : c.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: next ? queueColor(c).withValues(alpha: .40) : c.line),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              nthWord(l, index + 1),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.dim, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 6),
          MascotView(agentId: turn.agentId, spec: agent?.mascot, state: MascotState.idle, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        agent?.name ?? turn.agentId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    if (next) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: queueColor(c).withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          l.queueNext,
                          style: TextStyle(
                            color: c.warnText,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (row?.title?.isNotEmpty ?? false)
                  Text(
                    row!.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontSize: 12.5),
                  ),
                Text(facts.join(' · '), style: TextStyle(color: c.dim, fontSize: 12)),
              ],
            ),
          ),
          if (!next)
            IconButton(
              key: Key('queue-first-${turn.sessionId}'),
              tooltip: l.queueMoveFirst,
              onPressed: () => _moveFirst(context, turn.sessionId),
              icon: RgIcon(RgIcons.arrowUp, size: 18, color: c.accent),
            ),
          IconButton(
            key: Key('queue-stop-${turn.sessionId}'),
            tooltip: l.queueStop,
            onPressed: () => app.interrupt(turn.sessionId),
            icon: RgIcon(RgIcons.x, size: 18, color: c.dim),
          ),
        ],
      ),
    );
  }
}
