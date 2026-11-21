// Settings › Safety (G42.4, native; the page's `Safety.tsx`, G24.4): four decisions, each a card
// with its question and a drawn choice: the guardian; who says yes to risky actions (three ready
// choices, a switch per danger in a window: the policy's `humanOnly`); a spending limit only when
// something is paid per use; the skills the agents write. Then how long conversations are kept.
// A danger off by default (`offByDefault`, remove-agent since 3.10) has its switch on the danger
// itself (`enabledDanger`): on, only the person approves it; off, nobody is asked.
// Saved together with «Save» (`PUT /api/setup/safety`), as the wizard's step saves on «Next».
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/rule_words.g.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import 'api/rules_api.dart';
import 'rules_kit.dart';

Future<void> openSafetySettings(BuildContext context) =>
    openRulesPage(context, (panel) => SafetyScreen(panel: panel));

/// The ready choices of who approves (`PRESETS` in packages/web/src/wizard.ts).
const safetyPresets = <String, List<String>>{
  'careful': dangerIds,
  'balanced': [
    'git-push',
    'git-history',
    'privilege',
    'disk',
    'deploy',
    'database-drop',
    'secrets-files',
    'platform',
  ],
  'free': ['platform', 'secrets-files'],
};

/// The ready choice a set of human-only dangers is, if it is one (`presetOf`).
String? presetOf(List<String> humanOnly) {
  for (final e in safetyPresets.entries) {
    if (e.value.length == humanOnly.length && e.value.every(humanOnly.contains)) return e.key;
  }
  return null;
}

const _retention = ['forever', '365', '90', '30'];
const _budgets = ['20', '50', '100', ''];

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  Map<String, dynamic>? _state;
  List<String> _humanOnly = const [];
  List<String> _dangers = const [];
  List<String> _enabledDanger = const [];
  Set<String> _offByDefault = const {};
  String _guardian = 'ask';
  String _skills = 'ask';
  String _budget = '';
  String _retentionChoice = 'forever';
  String _base = 'balanced';
  bool _paid = false;
  String? _god;
  bool _saving = false;
  bool _saved = false;
  String? _error;
  final _other = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.setupState();
      if (!mounted) return;
      Map<String, dynamic> m(Object? o) => o is Map<String, dynamic> ? o : const {};
      final policy = m(s['policy']);
      final config = m(s['config']);
      final secrets = m(s['secretsSet']);
      final locked = m(s['locked']);
      final humanOnly = [for (final x in (policy['humanOnly'] as List? ?? const [])) '$x'];
      final dangers = [
        for (final d in (policy['dangers'] as List? ?? const []))
          if (d is Map && d['id'] is String) d['id'] as String,
      ];
      final offByDefault = {
        for (final d in (policy['dangers'] as List? ?? const []))
          if (d is Map && d['id'] is String && d['offByDefault'] == true) d['id'] as String,
      };
      final enabledDanger = [for (final x in (policy['enabledDanger'] as List? ?? const [])) '$x'];
      final budget = (s['budgetUsd'] as num?);
      final ret = (config['retentionDays'] as num?)?.toInt();
      setState(() {
        _state = s;
        _humanOnly = humanOnly;
        _dangers = dangers.isEmpty ? dangerIds : dangers;
        _offByDefault = offByDefault;
        _enabledDanger = enabledDanger;
        _guardian = policy['guardian'] == 'auto' ? 'auto' : 'ask';
        _skills = policy['skills'] == 'auto' ? 'auto' : 'ask';
        _budget = budget == null ? '' : _num(budget);
        _other.text = _budgets.contains(_budget) ? '' : _budget;
        _retentionChoice = ret == null ? 'forever' : '$ret';
        _base = presetOf(humanOnly) ?? 'balanced';
        _paid =
            (secrets['keys'] is List && (secrets['keys'] as List).isNotEmpty) ||
            locked['anthropic'] == true;
        _god = m(s['names'])['god'] as String?;
        _error = null;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  static String _num(num n) => n == n.roundToDouble() ? '${n.toInt()}' : '$n';

  double? get _limit => double.tryParse(_budget.replaceAll(',', '.'));

  void _changed(VoidCallback f) => setState(() {
    f();
    _saved = false;
  });

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final limit = _limit;
    try {
      await c.setSafety({
        'guardian': _guardian,
        'skills': _skills,
        'humanOnly': _humanOnly,
        'enabledDanger': _enabledDanger,
        // Only where something is paid per use, as the page: there is no limit to set otherwise.
        if (_paid) 'budgetUsd': _budget.trim().isNotEmpty && (limit ?? 0) > 0 ? limit : null,
        'retentionDays': _retentionChoice == 'forever' ? null : int.parse(_retentionChoice),
      });
      if (mounted) setState(() => _saved = true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pick(String preset) => _changed(() {
    _base = preset;
    _humanOnly = [...safetyPresets[preset]!];
  });

  String _presetWord(AppLocalizations l, String p) => switch (p) {
    'careful' => l.g4SfCareful,
    'free' => l.g4SfFree,
    _ => l.g4SfBalanced,
  };

  String _keepWord(AppLocalizations l, String r) => switch (r) {
    '365' => l.g4SfKeep365,
    '90' => l.g4SfKeep90,
    '30' => l.g4SfKeep30,
    _ => l.g4SfKeepForever,
  };

  Future<void> _custom() async {
    await showRgWindow<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          final l = AppLocalizations.of(context);
          final c = RgColors.of(context);
          final words = ruleWords[l.localeName.startsWith('it') ? 'it' : 'en']!.dangers;
          return Dialog(
            key: const Key('sf-custom'),
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 560,
                maxHeight: MediaQuery.sizeOf(context).height * .86,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                    child: Text(
                      l.g4SfCustomTitle,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      l.g4SfCustomLead(_god ?? 'God'),
                      style: TextStyle(color: c.dim, fontSize: 13, height: 1.4),
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final id in _dangers)
                          InkWell(
                            key: Key('sf-danger-$id'),
                            onTap: () {
                              _changed(() {
                                if (_offByDefault.contains(id)) {
                                  _enabledDanger = _enabledDanger.contains(id)
                                      ? _enabledDanger.where((x) => x != id).toList()
                                      : [..._enabledDanger, id];
                                } else {
                                  _humanOnly = _humanOnly.contains(id)
                                      ? _humanOnly.where((x) => x != id).toList()
                                      : [..._humanOnly, id];
                                }
                              });
                              setLocal(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          words[id]?.name ?? id,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: c.text,
                                          ),
                                        ),
                                        if ((words[id]?.hint ?? '').isNotEmpty)
                                          Text(
                                            words[id]!.hint,
                                            style: TextStyle(color: c.dim, fontSize: 12.5),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Semantics(
                                    label: l.g4SfCustomOn,
                                    child: RgSwitch(
                                      on: _offByDefault.contains(id)
                                          ? _enabledDanger.contains(id)
                                          : _humanOnly.contains(id),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton(
                          key: const Key('sf-custom-back'),
                          onPressed: () {
                            _pick(_base);
                            setLocal(() {});
                          },
                          child: Text(l.g4SfBackTo(_presetWord(l, _base))),
                        ),
                        FilledButton(
                          key: const Key('sf-custom-done'),
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l.g4SfDoneBtn),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    if (_state == null) {
      return RulesPage(
        pageKey: const Key('safety-settings'),
        title: l.g4SfTitle,
        question: l.g4SfTitle,
        lead: l.g4SfLead,
        panel: widget.panel,
        children: [RulesLoading(error: _error)],
      );
    }
    final preset = presetOf(_humanOnly);
    final limit = _limit;
    return RulesPage(
      pageKey: const Key('safety-settings'),
      title: l.g4SfTitle,
      question: l.g4SfTitle,
      lead: l.g4SfLead,
      panel: widget.panel,
      children: [
        RuleCard(
          key: const Key('sf-guardian'),
          icon: RgIcons.shield,
          title: l.g4SfGuardianTitle,
          question: l.g4SfGuardQ,
          children: [
            RgChoice<String>(
              options: [('ask', l.g4SfGuardAsk), ('auto', l.g4SfGuardAuto)],
              value: _guardian,
              keyOf: (v) => 'sf-guardian-$v',
              onChanged: (v) => _changed(() => _guardian = v),
            ),
            RuleSay(_guardian == 'ask' ? l.g4SfGuardianAskText : l.g4SfGuardianAutoText),
          ],
        ),
        RuleCard(
          key: const Key('sf-approvals'),
          icon: RgIcons.checkSquare,
          title: l.g4SfApprTitle,
          question: l.g4SfApprQ,
          children: [
            RgChoice<String>(
              options: [
                for (final p in const ['careful', 'balanced', 'free']) (p, _presetWord(l, p)),
              ],
              value: preset,
              keyOf: (v) => 'sf-preset-$v',
              onChanged: _pick,
            ),
            RuleSay(switch (preset) {
              'careful' => l.g4SfCarefulText,
              'balanced' => l.g4SfBalancedText,
              'free' => l.g4SfFreeText,
              _ => l.g4SfApprCustom(_humanOnly.length, '${_dangers.length}'),
            }),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('sf-personalize'),
                onPressed: _custom,
                icon: RgIcon(RgIcons.settings, size: 16, color: c.accent),
                label: Text(l.g4SfPersonalize),
              ),
            ),
          ],
        ),
        RuleCard(
          key: const Key('sf-budget'),
          icon: RgIcons.bag,
          title: l.g4SfBudgetTitle,
          question: _paid ? l.g4SfBudgetQ : l.g4SfBudgetQFree,
          children: _paid
              ? [
                  RgChoice<String>(
                    options: [for (final v in _budgets) (v, v.isEmpty ? l.g4SfNoLimit : '\$$v')],
                    value: _budgets.contains(_budget) ? _budget : null,
                    keyOf: (v) => 'sf-budget-${v.isEmpty ? 'none' : v}',
                    onChanged: (v) => _changed(() {
                      _budget = v;
                      _other.text = '';
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      key: const Key('sf-budget-other'),
                      controller: _other,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: l.g4SfBudgetOther,
                        prefixText: '\$ ',
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          _changed(() => _budget = v.replaceAll(RegExp(r'[^\d.,]'), '')),
                    ),
                  ),
                  RuleSay(
                    _budget.trim().isNotEmpty && (limit ?? 0) > 0
                        ? l.g4SfBudgetSay(_num(limit!))
                        : l.g4SfBudgetNone,
                  ),
                ]
              : [
                  Text(
                    l.g4SfNothingPaid,
                    key: const Key('sf-nothing-paid'),
                    style: TextStyle(color: c.dim, fontSize: 13, height: 1.4),
                  ),
                ],
        ),
        RuleCard(
          key: const Key('sf-skills'),
          icon: RgIcons.star,
          title: l.g4SfSkillsTitle,
          question: l.g4SfSkillsQ,
          children: [
            RgChoice<String>(
              vertical: true,
              options: [('ask', l.g4SfSkillsAsk), ('auto', l.g4SfSkillsAuto)],
              value: _skills,
              keyOf: (v) => 'sf-skills-$v',
              onChanged: (v) => _changed(() => _skills = v),
            ),
            RuleSay(
              '${_skills == 'ask' ? l.g4SfSkillsAskText : l.g4SfSkillsAutoText} ${l.g4SfSkillsTools}',
            ),
          ],
        ),
        RuleCard(
          key: const Key('sf-retention'),
          icon: RgIcons.clock,
          title: l.g4SfKeepFor,
          children: [
            RgChoice<String>(
              options: [for (final r in _retention) (r, _keepWord(l, r))],
              value: _retentionChoice,
              keyOf: (v) => 'sf-keep-$v',
              onChanged: (v) => _changed(() => _retentionChoice = v),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: RgIcon(RgIcons.shield, size: 15, color: c.dim),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.g4SfWhereAgents,
                    style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                  ),
                ),
              ],
            ),
          ],
        ),
        RuleSaveRow(
          onSave: _save,
          saving: _saving,
          saved: _saved ? l.g4SfSaved : null,
          error: _error,
        ),
      ],
    );
  }
}
