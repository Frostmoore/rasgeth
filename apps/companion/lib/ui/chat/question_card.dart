// A question (`ask_user`) or a plan (`propose_plan`) in the conversation (G42.1), as the page's
// `QuestionCard.tsx`: while it waits, the person picks options (one, or many for a multiple
// choice) or writes another answer («Altro»), or approves the plan or asks to revise it with
// words; `question.answer` over the socket. Afterwards it stays in the chat with what was
// answered. Choices are our drawn marks, never native radios or checkboxes.
import 'package:flutter/material.dart';

import '../../api/conversation.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';
import '../markdown.dart';
import 'request_cards.dart' show ActButton, ActKind, MaxWidthLeft;

/// `PLAN_APPROVE`, `PLAN_REVISE` (packages/protocol/src/questions.ts): the answers sent.
const planApprove = 'Approve';
const planRevise = 'Keep planning';

String planLabel(AppLocalizations l, String label) => label == planApprove
    ? l.cvPlanApprove
    : label == planRevise
    ? l.cvPlanRevise
    : label;

class ChatQuestionCard extends StatefulWidget {
  const ChatQuestionCard({
    super.key,
    required this.requestId,
    required this.questions,
    this.plan,
    this.answered = false,
    this.answers,
    required this.open,
  });

  /// From an item of the conversation.
  factory ChatQuestionCard.of(QuestionItem item, {required bool open, Key? key}) =>
      ChatQuestionCard(
        key: key,
        requestId: item.requestId,
        questions: item.questions,
        plan: item.plan,
        answered: item.answered,
        answers: item.answers,
        open: open,
      );

  final String requestId;
  final List<Question> questions;
  final String? plan;
  final bool answered;
  final List<List<String>>? answers;

  /// Still waiting for the person (the server lists it).
  final bool open;

  @override
  State<ChatQuestionCard> createState() => _ChatQuestionCardState();
}

class _ChatQuestionCardState extends State<ChatQuestionCard> {
  late final List<List<String>> _picked = [for (final _ in widget.questions) <String>[]];
  late final List<TextEditingController> _other = [
    for (final _ in widget.questions.isEmpty ? [null] : widget.questions) TextEditingController(),
  ];
  bool _sent = false;
  bool _failed = false;
  bool _planOpen = false;

  @override
  void dispose() {
    for (final c in _other) {
      c.dispose();
    }
    super.dispose();
  }

  void _send(List<List<String>> answers) {
    final ok = AppScope.read(context).answerQuestionId(widget.requestId, answers);
    setState(() {
      _sent = ok;
      _failed = !ok;
    });
  }

  List<List<String>> get _collected => [
    for (final (i, p) in _picked.indexed)
      [...p, if (_other[i].text.trim().isNotEmpty) _other[i].text.trim()],
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final w = widget;
    if (!w.open || w.answered) return _done(l, c);
    final plan = w.plan;
    final children = <Widget>[];
    if (plan != null) {
      final feedback = _other[0].text.trim();
      children.addAll([
        Row(
          children: [
            RgIcon(RgIcons.info, size: 17, color: c.accent),
            const SizedBox(width: 8),
            Text(
              l.cvProposedPlan,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SafeMarkdown(plan),
        TextField(
          key: Key('plan-feedback-${w.requestId}'),
          controller: _other[0],
          enabled: !_sent,
          minLines: 2,
          maxLines: 6,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(hintText: l.cvPlanFeedback, isDense: true),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActButton(
              key: Key('plan-approve-${w.requestId}'),
              label: l.cvPlanApprove,
              kind: ActKind.yes,
              onTap: _sent
                  ? null
                  : () => _send([
                      [planApprove],
                    ]),
            ),
            ActButton(
              key: Key('plan-revise-${w.requestId}'),
              label: feedback.isNotEmpty ? l.cvSendFeedback : l.cvPlanRevise,
              kind: ActKind.always,
              onTap: _sent
                  ? null
                  : () => _send([
                      [feedback.isNotEmpty ? feedback : planRevise],
                    ]),
            ),
          ],
        ),
      ]);
    } else {
      for (final (i, q) in w.questions.indexed) {
        children.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (q.header != null && q.header!.isNotEmpty) _Chip(q.header!),
                  Text(
                    q.question,
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                  ),
                  if (q.multiSelect)
                    Text('(${l.cvManyAnswers})', style: TextStyle(color: c.dim, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              for (final o in q.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _Option(
                    key: Key('chat-option-${w.requestId}-$i-${o.label}'),
                    label: o.label,
                    description: o.description,
                    many: q.multiSelect,
                    on: _picked[i].contains(o.label),
                    onTap: _sent
                        ? null
                        : () => setState(() {
                            final p = _picked[i];
                            if (q.multiSelect) {
                              p.contains(o.label) ? p.remove(o.label) : p.add(o.label);
                            } else {
                              p
                                ..clear()
                                ..add(o.label);
                            }
                          }),
                  ),
                ),
              TextField(
                key: Key('chat-other-${w.requestId}-$i'),
                controller: _other[i],
                enabled: !_sent,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(hintText: l.cvOtherAnswer, isDense: true),
              ),
            ],
          ),
        );
      }
      final complete = _collected.every((a) => a.isNotEmpty);
      children.add(
        Wrap(
          children: [
            ActButton(
              key: Key('chat-answer-${w.requestId}'),
              label: l.cvAnswer,
              kind: ActKind.yes,
              onTap: !complete || _sent ? null : () => _send(_collected),
            ),
          ],
        ),
      );
    }
    if (_failed) children.add(Text(l.notLive, style: TextStyle(color: c.err, fontSize: 13)));
    return MaxWidthLeft(
      child: Container(
        key: Key('chat-question-${w.requestId}'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.accentSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, ch) in children.indexed) ...[if (i > 0) const SizedBox(height: 12), ch],
          ],
        ),
      ),
    );
  }

  /// Answered (or not any more open): what was said, the plan folded.
  Widget _done(AppLocalizations l, RgColors c) {
    final w = widget;
    final plan = w.plan;
    return MaxWidthLeft(
      child: Container(
        key: Key('chat-question-done-${w.requestId}'),
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan != null) ...[
              InkWell(
                onTap: () => setState(() => _planOpen = !_planOpen),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RgIcon(
                      _planOpen ? RgIcons.chevronDown : RgIcons.chevronRight,
                      size: 14,
                      color: c.dim,
                    ),
                    const SizedBox(width: 4),
                    Text(l.cvProposedPlan, style: TextStyle(color: c.dim, fontSize: 13)),
                  ],
                ),
              ),
              if (_planOpen) SafeMarkdown(plan),
              const SizedBox(height: 4),
            ],
            for (final (i, q) in w.questions.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 8,
                  children: [
                    Text(
                      plan != null ? l.cvProposedPlan : q.question,
                      style: TextStyle(color: c.dim, fontSize: 13),
                    ),
                    Text(
                      !w.answered
                          ? l.cvWaitingAnswer
                          : w.answers == null
                          ? l.cvNotAnswered
                          : (i < w.answers!.length ? w.answers![i] : const <String>[])
                                .map((a) => planLabel(l, a))
                                .join('; '),
                      style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.line),
      ),
      child: Text(text, style: TextStyle(color: c.dim, fontSize: 12)),
    );
  }
}

/// An option (`.option`): a round mark for one answer, a square one for many, filled with the
/// accent when chosen (never ticked).
class _Option extends StatelessWidget {
  const _Option({
    super.key,
    required this.label,
    required this.many,
    required this.on,
    required this.onTap,
    this.description,
  });

  final String label;
  final String? description;
  final bool many;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accentDim : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: on ? c.accent : c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: many ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: many ? BorderRadius.circular(4) : null,
                    color: c.panel,
                    border: Border.all(color: on ? c.accent : c.dim),
                  ),
                  child: on
                      ? Container(
                          margin: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: many ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: many ? BorderRadius.circular(2) : null,
                            color: c.accent,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: c.text, fontSize: 14.5)),
                      if (description != null && description!.isNotEmpty)
                        Text(description!, style: TextStyle(color: c.dim, fontSize: 13)),
                    ],
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
