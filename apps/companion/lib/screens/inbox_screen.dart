// For you (G40.7; the stack of cards and swiping come with G40.9): what waits for the person.
// The app is one of the channels that get every request at once (G36.17): the first answer
// closes the other copies and says where it was given. Ordinary requests: Yes or No on the card.
// Truly dangerous ones (G36.17b): never the quick yes; they open a full screen of their own,
// where the yes asks once more. Questions: their options, sent with `question.answer`.
import 'dart:convert';

import 'package:flutter/material.dart';

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

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: app.live,
      builder: (context, _) {
        final list = app.live.requests;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(title: l.tabInbox),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: RgIcons.bell, text: l.inboxEmpty)
                  : ListView.separated(
                      key: const Key('inbox-list'),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => switch (list[i]) {
                        final PermissionRequest p => PermissionCard(request: p),
                        final QuestionRequest q => QuestionCard(request: q),
                      },
                    ),
            ),
          ],
        );
      },
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
          Text(
            r.tool,
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.dim),
          ),
          const SizedBox(height: 2),
          Text(
            requestSummary(r),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.text),
          ),
          for (final reason in r.reasons.take(3))
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

/// A truly dangerous request, full screen: what it does, then No (first) or a yes asked twice.
class CriticalRequestScreen extends StatelessWidget {
  const CriticalRequestScreen({super.key, required this.request});

  final PermissionRequest request;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = request;
    return Scaffold(
      backgroundColor: c.criticalSoft,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: app.live,
          builder: (context, _) {
            final open = app.live.approvals.any((a) => a.requestId == r.requestId);
            return ListView(
              key: const Key('critical-screen'),
              padding: const EdgeInsets.all(20),
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
                  ],
                ),
                const SizedBox(height: 12),
                Text(l.criticalBody(r.agentName), style: TextStyle(fontSize: 15.5, color: c.text)),
                const SizedBox(height: 14),
                for (final d in r.critical)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${criticalLabel(l, d.id)}${d.target == null ? '' : ': ${d.target}'}',
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.criticalText),
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.panel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.critical),
                  ),
                  child: SelectableText(
                    '${r.tool}\n${const JsonEncoder.withIndent('  ').convert(r.input)}',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.text),
                  ),
                ),
                for (final reason in r.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(reason, style: TextStyle(color: c.dim)),
                  ),
                const SizedBox(height: 24),
                if (!open)
                  Text(
                    l.requestClosed(app.live.lastClosedVia ?? '-'),
                    style: TextStyle(color: c.dim, fontSize: 15),
                  )
                else ...[
                  FilledButton(
                    key: const Key('critical-no'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    onPressed: () async {
                      await app.resolvePermission(r, allow: false);
                      if (context.mounted) Navigator.maybePop(context);
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
                      if (!sure) return;
                      await app.resolvePermission(r, allow: true, fromFullScreen: true);
                      if (context.mounted) Navigator.maybePop(context);
                    },
                    child: Text(l.criticalYes),
                  ),
                ],
              ],
            );
          },
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
