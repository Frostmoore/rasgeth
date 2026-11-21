// Settings › Requests to you (G42.4, native; the page's `RequestsPage.tsx`, G36.17): whether the
// agents' requests reach the person everywhere or nowhere («Don't ask me anything»: the classifier
// decides), how long they wait, the truly dangerous requests that always reach the person (in
// the protocol's words, `criticalWords`), the classifier's model, and every decision taken without
// the person with its reason. Saved as configuration (`PUT /api/settings/requests`), undoable.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/model_routes.dart' show modelName;
import '../api/settings_types.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/rule_words.g.dart';
import '../screens/conversation_screen.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import 'api/rules_api.dart';
import 'rules_kit.dart';
import '../ui/systems.dart';

Future<void> openRequestsSettings(BuildContext context) =>
    openRulesPage(context, (panel) => RequestsScreen(panel: panel));

const _minute = 60000;

/// The ready times (null: no limit), as the page's `TIMES`.
const requestTimes = <int?>[5 * _minute, 15 * _minute, 60 * _minute, 24 * 60 * _minute, null];

const _criticalIcons = <String, RgIcons>{
  'critical-system': RgIcons.monitor,
  'critical-delete': RgIcons.trash,
  'critical-secret': RgIcons.lock,
  'critical-payment': RgIcons.bag,
  'critical-protections': RgIcons.shield,
};

String _lang(AppLocalizations l) => l.localeName.startsWith('it') ? 'it' : 'en';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  Map<String, dynamic>? _loaded;
  Map<String, dynamic>? _s;
  List<UnattendedDecision> _all = const [];
  List<ModelChoice>? _models;
  String? _change;
  bool _undone = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final r = await c.requestSettings();
      final a = await c.unattended();
      if (!mounted) return;
      setState(() {
        _loaded = r;
        _s = {...(r['settings'] as Map<String, dynamic>? ?? const {})};
        _all = a;
        _error = null;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    try {
      final m = await c.models();
      if (mounted) setState(() => _models = m);
    } on Exception {
      // Without the models, the classifier's model keeps its words and cannot be changed.
    }
  }

  void _set(Map<String, dynamic> next) => setState(() {
    _s = next;
    _change = null;
    _undone = false;
  });

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    final s = _s;
    if (c == null || s == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await c.setRequestSettings(s);
      if (mounted) {
        setState(() {
          _change = id ?? '';
          _undone = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _undo() async {
    final c = AppScope.read(context).client;
    final id = _change;
    if (c == null || id == null || id.isEmpty) return;
    try {
      await c.undoChange(id);
      if (mounted) setState(() => _undone = true);
      await _load();
      if (mounted) setState(() => _undone = true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _pickClassifier(String lightModel) async {
    final l = AppLocalizations.of(context);
    final models = _models;
    final s = _s;
    if (models == null || models.isEmpty || s == null) return;
    final pick = await showModelPicker(
      context,
      title: l.g4RqClassifierModel,
      models: models,
      current: AgentModel.fromJson(s['classifierModel']),
      inheritLabel: l.g4RqClassifierDefault(lightModel),
    );
    if (pick == null || !mounted) return;
    final next = {...s}..remove('classifierModel');
    final m = pick.model;
    if (m != null) {
      next['classifierModel'] = {
        'provider': m.provider,
        'model': m.model,
        if (m.effort != null) 'effort': m.effort,
      };
    }
    _set(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _s;
    final loaded = _loaded;
    if (s == null || loaded == null) {
      return RulesPage(
        pageKey: const Key('requests-settings'),
        system: RgSystem.eventHorizon,
        title: l.g4RqSection,
        question: l.g4RqPageQ,
        lead: l.g4RqPageLead,
        panel: widget.panel,
        children: [RulesLoading(error: _error)],
      );
    }
    final ask = s['mode'] != 'classifier';
    final timeout = (s['timeoutMs'] as num?)?.toInt();
    final after = s['afterTimeout'] == 'classifier' ? 'classifier' : 'no';
    final usesClassifier = !ask || (timeout != null && after == 'classifier');
    final dm = loaded['defaultModel'];
    final lightModel = dm is Map && dm['model'] is String
        ? modelName(dm['model'] as String)
        : l.g4RqNoModel;
    final own = AgentModel.fromJson(s['classifierModel']);
    final critical = [
      for (final id in (loaded['critical'] is List ? loaded['critical'] as List : criticalIds))
        '$id',
    ];
    final times = [...requestTimes, if (!requestTimes.contains(timeout)) timeout];
    return RulesPage(
      pageKey: const Key('requests-settings'),
      system: RgSystem.eventHorizon,
      title: l.g4RqSection,
      question: l.g4RqPageQ,
      lead: l.g4RqPageLead,
      panel: widget.panel,
      children: [
        RuleCard(
          key: const Key('rq-mode'),
          icon: RgIcons.bell,
          title: l.g4RqModeTitle,
          question: l.g4RqModeQ,
          children: [
            RgChoice<String>(
              vertical: true,
              options: [('ask', l.g4RqModeAsk), ('classifier', l.g4RqModeClassifier)],
              value: ask ? 'ask' : 'classifier',
              keyOf: (v) => 'rq-mode-$v',
              onChanged: (v) => _set({...s, 'mode': v}),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.criticalSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: RgIcon(RgIcons.lock, size: 16, color: c.criticalText),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.g4RqAlwaysYou,
                      style: TextStyle(color: c.criticalText, fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            RuleSay(ask ? l.g4RqModeAskText : l.g4RqModeClassifierText),
            if (!ask) ...[const SizedBox(height: 10), RuleWarn(l.g4RqModeClassifierWarn)],
          ],
        ),
        RuleCard(
          key: const Key('rq-time'),
          icon: RgIcons.clock,
          title: l.g4RqTimeTitle,
          question: ask ? l.g4RqTimeQ : l.g4RqTimeQSpecial,
          children: [
            RgChoice<int?>(
              options: [for (final v in times) (v, v == null ? l.g4CmNoLimit : spanWords(l, v))],
              value: timeout,
              keyOf: (v) => 'rq-time-${v ?? 'none'}',
              onChanged: (v) => _set({...s, 'timeoutMs': v}),
            ),
            if (timeout == null)
              RuleSay(ask ? l.g4RqTimeNone : l.g4RqTimeNoneSpecial)
            else if (!ask)
              RuleSay(l.g4RqAfterSpecialText(spanWords(l, timeout)))
            else ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Text(
                  l.g4RqAfterQ(spanWords(l, timeout)),
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14),
                ),
              ),
              RgChoice<String>(
                vertical: true,
                options: [('no', l.g4RqAfterNo), ('classifier', l.g4RqAfterClassifier)],
                value: after,
                keyOf: (v) => 'rq-after-$v',
                onChanged: (v) => _set({...s, 'afterTimeout': v}),
              ),
              RuleSay(after == 'no' ? l.g4RqAfterNoText : l.g4RqAfterClassifierText),
            ],
          ],
        ),
        RuleCard(
          key: const Key('rq-special'),
          icon: RgIcons.alert,
          tone: c.critical,
          title: l.g4RqSpecialTitle,
          question: l.g4RqSpecialQ,
          children: [
            Text(l.g4RqSpecialText, style: TextStyle(color: c.dim, fontSize: 13, height: 1.4)),
            const SizedBox(height: 6),
            for (final id in critical) _Critical(id: id),
            RuleSay(l.g4RqSpecialNot),
          ],
        ),
        if (usesClassifier)
          RuleCard(
            key: const Key('rq-classifier'),
            icon: RgIcons.shield,
            title: l.g4RqClassifierTitle,
            question: l.g4RqClassifierQ,
            children: [
              Material(
                color: c.panel2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: c.line),
                ),
                child: ListTile(
                  key: const Key('rq-classifier-model'),
                  leading: RgIcon(RgIcons.cpu, color: c.accent),
                  title: Text(l.g4RqClassifierModel),
                  subtitle: Text(
                    own == null
                        ? l.g4RqClassifierDefault(lightModel)
                        : (_models == null ? modelName(own.model) : modelWords(l, _models!, own)),
                  ),
                  trailing: (_models?.isNotEmpty ?? false)
                      ? RgIcon(RgIcons.chevronRight, color: c.dim)
                      : null,
                  onTap: (_models?.isNotEmpty ?? false) ? () => _pickClassifier(lightModel) : null,
                ),
              ),
              RuleSay(l.g4RqClassifierHow),
            ],
          ),
        RuleSaveRow(
          onSave: _save,
          saving: _saving,
          saved: _change == null ? null : l.g4RqSaved,
          undone: _undone,
          onUndo: (_change?.isNotEmpty ?? false) ? _undo : null,
          error: _error,
        ),
        RulesSub(title: l.g4RqDoneTitle, lead: l.g4RqDoneLead, icon: RgIcons.list),
        if (_all.isEmpty)
          Padding(
            key: const Key('rq-done-empty'),
            padding: const EdgeInsets.all(16),
            child: Text(l.g4RqDoneEmpty, style: TextStyle(color: c.dim)),
          )
        else
          for (final d in _all.take(50)) _Decision(d: d),
      ],
    );
  }
}

class _Critical extends StatelessWidget {
  const _Critical({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final w = ruleWords[_lang(l)]!.critical[id];
    if (w == null) return const SizedBox.shrink();
    return Padding(
      key: Key('rq-critical-$id'),
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.criticalSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: RgIcon(_criticalIcons[id] ?? RgIcons.alert, size: 16, color: c.criticalText),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.name,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(w.hint, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
                const SizedBox(height: 4),
                Text(
                  '${l.g4RqCriticalExamples} ${w.examples.join('; ')}.',
                  style: TextStyle(
                    color: c.dim,
                    fontSize: 12,
                    height: 1.35,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Decision extends StatelessWidget {
  const _Decision({required this.d});

  final UnattendedDecision d;

  static String _when(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.day}/${two(t.month)} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final decision = switch (d.decision) {
      'allow' => l.g4RqDecisionAllow,
      'answered' => l.g4RqDecisionAnswered,
      'blocked' => l.g4RqDecisionBlocked,
      _ => l.g4RqDecisionDeny,
    };
    final tone = switch (d.decision) {
      'allow' || 'answered' => c.ok,
      'blocked' => c.critical,
      _ => c.err,
    };
    final kind = switch (d.kind) {
      'question' => l.g4RqKindQuestion,
      'plan' => l.g4RqKindPlan,
      'tool' => l.g4RqKindTool,
      'credential' => l.g4RqKindCredential,
      'automation' => l.g4RqKindAutomation,
      _ => l.g4RqKindApproval,
    };
    final by = d.by == 'classifier'
        ? (d.model != null
              ? l.g4RqByModel(modelName(d.model!.split('/').skip(1).join('/')))
              : l.g4RqByClassifier)
        : l.g4RqByTimeout;
    final words = ruleWords[_lang(l)]!.dangers;
    return Container(
      key: Key('rq-decision-${d.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: d.decision == 'blocked' ? c.critical : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  decision,
                  style: TextStyle(color: tone, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Text(
                d.agentName,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
              ),
              Text(kind, style: TextStyle(color: c.dim, fontSize: 12.5)),
              Text(_when(d.createdAt), style: TextStyle(color: c.dim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Text(d.what, style: TextStyle(color: c.text, fontSize: 14)),
          if (d.danger.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                d.danger.map((x) => words[x]?.name ?? x).join(' · '),
                style: TextStyle(color: c.warnText, fontSize: 12.5),
              ),
            ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$by ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: d.reason),
              ],
            ),
            style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
          ),
          if (d.sessionId != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: Key('rq-open-${d.id}'),
                onPressed: () {
                  final app = AppScope.read(context);
                  final agent = app.agents.where((a) => a.id == d.agentId).firstOrNull;
                  unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ConversationScreen(sessionId: d.sessionId!, agent: agent),
                      ),
                    ),
                  );
                },
                child: Text(l.g4RqOpenChat),
              ),
            ),
        ],
      ),
    );
  }
}
