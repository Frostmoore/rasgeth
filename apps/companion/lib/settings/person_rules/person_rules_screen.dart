// 3.12: Settings › Rules, native, as the page's Rules.tsx («Regole della persona»): the person's
// own rules that Rasgeth enforces by itself (when, if, then). The stops in place on top with
// «Resume»; the rules with their switch (on only when the two examples pass), their words, the
// history with «Undo the last change», remove; the editor (when, if, then, the two examples and
// «Try»); the ready-made weekly margin (added switched off); the magic rule, built with God in a
// conversation with the proposal beside it (approve, change, refuse); what the rules did.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/conversation_screen.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../automations/automation_kit.dart';
import '../automations/magic_automation.dart' show MagicSteps, magicStateLabel;
import '../rules_kit.dart';
import 'person_rules_api.dart';

Future<void> openPersonRulesSettings(BuildContext context) =>
    openRulesPage(context, (panel) => PersonRulesScreen(panel: panel));

// ---------- Words ----------

String ruleEventWord(AppLocalizations l, String e) => switch (e) {
  'usage' => l.prEvUsage,
  'budget' => l.prEvBudget,
  'tool' => l.prEvTool,
  'file' => l.prEvFile,
  'agent_done' => l.prEvAgentDone,
  'schedule' => l.prEvSchedule,
  _ => e,
};

String ruleFieldWord(AppLocalizations l, String f) => switch (f) {
  'marginPct' => l.prFieldMargin,
  'usedPct' => l.prFieldUsed,
  'window' => l.prFieldWindow,
  'provider' => l.prFieldProvider,
  'budgetPct' => l.prFieldBudgetPct,
  'budget' => l.prFieldBudget,
  'tool' => l.prFieldTool,
  'command' => l.prFieldCommand,
  'path' => l.prFieldPath,
  'project' => l.prFieldProject,
  'agent' => l.prFieldAgent,
  'stopReason' => l.prFieldStop,
  _ => f,
};

String ruleOpWord(AppLocalizations l, String o) => switch (o) {
  'lt' => l.prOpLt,
  'lte' => l.prOpLte,
  'gt' => l.prOpGt,
  'gte' => l.prOpGte,
  'eq' => l.prOpEq,
  'neq' => l.prOpNeq,
  'matches' => l.prOpMatches,
  'contains' => l.prOpContains,
  _ => o,
};

String ruleActionWord(AppLocalizations l, String a) => switch (a) {
  'notify' => l.prActNotify,
  'ask' => l.prActAsk,
  'block' => l.prActBlock,
  'stop' => l.prActStop,
  'tools_off' => l.prActToolsOff,
  'automation' => l.prActAutomation,
  'command' => l.prActCommand,
  _ => a,
};

String _text(Map<String, dynamic> a, String k) => a[k] is String ? a[k] as String : '';
List<String> _strings(Object? o) => [for (final x in (o is List ? o : const [])) '$x'];

String _actSentence(AppLocalizations l, Map<String, dynamic> a) => switch (a['do']) {
  'notify' => _text(a, 'text').isEmpty ? l.prSayNotify : l.prSayNotifyText(_text(a, 'text')),
  'ask' => l.prSayAsk,
  'block' => l.prSayBlock,
  'stop' => a['resume'] == 'auto' ? l.prSayStopAuto : l.prSayStop,
  'tools_off' => l.prSayToolsOff([..._strings(a['kits']), ..._strings(a['tools'])].join(', ')),
  'automation' => l.prSayAutomation(_text(a, 'automation')),
  'command' => l.prSayCommand(_text(a, 'command')),
  _ => '${a['do']}',
};

/// The rule in three lines, as the page's `ruleLines`: when, if, then.
List<String> ruleLines(AppLocalizations l, Map<String, dynamic> rule) {
  final when = rule['when'] is Map ? (rule['when'] as Map).cast<String, dynamic>() : const {};
  final event = '${when['event'] ?? ''}';
  final conds = [
    for (final c in (rule['if'] is List ? rule['if'] as List : const []))
      if (c is Map) c.cast<String, dynamic>(),
  ];
  final acts = [
    for (final a in (rule['actions'] is List ? rule['actions'] as List : const []))
      if (a is Map) a.cast<String, dynamic>(),
  ];
  return [
    event == 'schedule'
        ? l.prSayWhenTime('${when['cron'] ?? ''}')
        : l.prSayWhen(ruleEventWord(l, event)),
    if (conds.isNotEmpty)
      l.prSayIf(
        conds
            .map(
              (c) =>
                  '${ruleFieldWord(l, '${c['field']}')} ${ruleOpWord(l, '${c['op']}')} ${c['value']}',
            )
            .join(l.prAnd),
      ),
    l.prSayThen(acts.map((a) => _actSentence(l, a)).join(', ')),
  ];
}

String _when(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day}/${d.month} ${two(d.hour)}:${two(d.minute)}';
}

// ---------- The page ----------

class PersonRulesScreen extends StatefulWidget {
  const PersonRulesScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<PersonRulesScreen> createState() => _PersonRulesScreenState();
}

class _PersonRulesScreenState extends State<PersonRulesScreen> {
  RulesLoaded? _data;
  List<MagicRuleView> _magic = const [];
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    // A stop or a fire happens without the page: read again now and then.
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(_load()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final d = await c.personRules();
      final m = await c.magicRules().catchError((_) => <MagicRuleView>[]);
      if (!mounted) return;
      setState(() {
        _data = d;
        _magic = m;
        _error = null;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _act(Future<void> Function(RedGiantClient c) f) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await f(c);
      if (mounted) setState(() => _error = null);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    await _load();
  }

  Future<void> _edit([PersonRuleView? r]) async {
    final l = AppLocalizations.of(context);
    final done = await openRuleEditor(
      context,
      title: r?.name ?? l.prNew,
      seed: r?.draft,
      submit: (c, rule, enable) async {
        if (r == null) {
          await c.createPersonRule(rule, enable: enable);
          return;
        }
        final saved = await c.updatePersonRule(r.id, rule);
        if (enable && !saved.enabled) await c.enablePersonRule(r.id, true);
      },
    );
    if (done == true) await _load();
  }

  Future<void> _startMagic() async {
    final l = AppLocalizations.of(context);
    final text = await askText(
      context,
      title: l.prMagicAsk,
      yes: l.prMagicGo,
      hint: l.prMagicPh,
      fieldKey: const Key('pr-magic-text'),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final m = await c.startMagicRule(text.trim());
      if (!mounted) return;
      await _openMagic(m);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _openMagic(MagicRuleView m) async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: '${l.prMagic}: ${m.title}',
      sub: magicStateLabel(l, m.status),
      icon: const GodOrb(size: 32),
      wide: true,
      full: true,
      scroll: false,
      key: const Key('pr-magic-chat'),
      child: (ctx, close) => _MagicRuleChat(magic: m, onDone: close),
    );
    await _load();
  }

  Future<void> _history(PersonRuleView r) async {
    final l = AppLocalizations.of(context);
    await openAutoWindow<void>(
      context,
      title: l.prHistoryOf(r.name),
      key: const Key('pr-history'),
      child: (ctx, close) => _History(rule: r),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final d = _data;
    final rules = d?.rules ?? const <PersonRuleView>[];
    final hasMargin = rules.any((r) => r.origin == 'template');
    return RulesPage(
      pageKey: const Key('pr-page'),
      title: l.prSection,
      question: l.prQ,
      lead: l.prLead,
      panel: widget.panel,
      children: [
        for (final h in d?.holds ?? const <RuleHoldView>[])
          Container(
            key: Key('pr-hold-${h.ruleId}'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.err.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.err.withValues(alpha: .45)),
            ),
            child: Row(
              children: [
                RgIcon(RgIcons.stop, size: 22, color: c.err),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.prHoldTitle(h.ruleName),
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                      ),
                      Text(
                        '${h.reason} · ${l.prHoldSince(_when(l, h.at))}',
                        style: TextStyle(color: c.dim, fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: Key('pr-resume-${h.ruleId}'),
                  onPressed: () => _act((c) => c.resumePersonRules(h.ruleId)),
                  child: Text(l.prResumeNow),
                ),
              ],
            ),
          ),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('pr-error')),
        if (d == null && _error == null) const RulesLoading(),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const Key('pr-magic'),
              onPressed: _startMagic,
              icon: const RgIcon(RgIcons.spark, size: 18, color: Colors.white),
              label: Text(l.prMagic),
            ),
            OutlinedButton.icon(
              key: const Key('pr-new'),
              onPressed: _edit,
              icon: RgIcon(RgIcons.plus, size: 18, color: c.text),
              label: Text(l.prNew),
            ),
          ],
        ),
        for (final m in _magic.where((m) => m.status != 'done'))
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ListTile(
              key: Key('pr-magic-${m.id}'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.line),
              ),
              leading: RgIcon(RgIcons.spark, size: 18, color: c.accent),
              title: Text(m.title),
              subtitle: Text(magicStateLabel(l, m.status)),
              onTap: () => _openMagic(m),
            ),
          ),
        RulesSub(
          title: l.prListTitle,
          lead: rules.isEmpty ? l.prNone : l.prListLead,
          icon: RgIcons.zap,
        ),
        for (final r in rules)
          _RuleTile(
            rule: r,
            onSwitch: (on) => _act((c) => c.enablePersonRule(r.id, on)),
            onEdit: () => _edit(r),
            onHistory: () => _history(r),
            onRemove: () async {
              final yes = await askConfirm(
                context,
                title: l.prRemoveQ(r.name),
                body: l.prRemoveLead,
                yes: l.prRemove,
                danger: true,
              );
              if (yes) await _act((c) => c.removePersonRule(r.id));
            },
          ),
        if (d != null && !hasMargin)
          RuleCard(
            key: const Key('pr-template-card'),
            icon: RgIcons.bell,
            title: l.prTplMargin,
            question: l.prTplMarginQ,
            children: [
              Text(l.prTplMarginLead, style: TextStyle(color: c.dim, height: 1.4)),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  key: const Key('pr-template'),
                  onPressed: () => _act((c) => c.addPersonRuleTemplate('weekly-margin')),
                  child: Text(l.prTplAdd),
                ),
              ),
            ],
          ),
        if ((d?.fires ?? const []).isNotEmpty) ...[
          RulesSub(title: l.prFiresTitle, lead: l.prFiresLead, icon: RgIcons.activity),
          for (final f in d!.fires)
            Padding(
              key: Key('pr-fire-${f.id}'),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Text(
                '${_when(l, f.at)} · ${f.ruleName} · ${f.results.join(' · ')}',
                style: TextStyle(color: c.dim, fontSize: 13),
              ),
            ),
        ],
      ],
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({
    required this.rule,
    required this.onSwitch,
    required this.onEdit,
    required this.onHistory,
    required this.onRemove,
  });

  final PersonRuleView rule;
  final ValueChanged<bool> onSwitch;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = rule;
    final by = r.origin == 'god'
        ? l.prByGod
        : r.origin == 'template'
        ? l.prByTemplate
        : l.prByYou;
    return Container(
      key: Key('pr-rule-${r.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      decoration: BoxDecoration(
        color: r.enabled ? c.accentSoft.withValues(alpha: .5) : c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.enabled ? c.accent.withValues(alpha: .6) : c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchLine(
            key: Key('pr-switch-${r.id}'),
            title: r.name,
            help: [
              by,
              if (r.lastFiredAt != null) l.prLastFired(_when(l, r.lastFiredAt!)),
            ].join(' · '),
            on: r.enabled,
            onChanged: onSwitch,
          ),
          if (r.description.isNotEmpty)
            Text(r.description, style: TextStyle(color: c.text, height: 1.4)),
          for (final line in ruleLines(l, r.json))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(line, style: TextStyle(color: c.dim, fontSize: 13.5, height: 1.35)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              TextButton(key: Key('pr-edit-${r.id}'), onPressed: onEdit, child: Text(l.prEdit)),
              TextButton(
                key: Key('pr-history-${r.id}'),
                onPressed: onHistory,
                child: Text(l.prHistory),
              ),
              TextButton(
                key: Key('pr-remove-${r.id}'),
                onPressed: onRemove,
                child: Text(l.prRemove, style: TextStyle(color: c.err)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- History ----------

class _History extends StatefulWidget {
  const _History({required this.rule});

  final PersonRuleView rule;

  @override
  State<_History> createState() => _HistoryState();
}

class _HistoryState extends State<_History> {
  List<RuleVersionView>? _list;
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
      final h = await c.personRuleHistory(widget.rule.id);
      if (mounted) setState(() => _list = h);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  String _change(AppLocalizations l, String ch) => switch (ch) {
    'created' => l.prChCreated,
    'changed' => l.prChChanged,
    'enabled' => l.prChEnabled,
    'disabled' => l.prChDisabled,
    'removed' => l.prChRemoved,
    'undone' => l.prChUndone,
    _ => ch,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final v in _list ?? const <RuleVersionView>[])
          Padding(
            key: Key('pr-version-${v.version}'),
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_when(l, v.at)} · ${_change(l, v.change)}',
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                Text(
                  l.prHistoryBy(v.by == 'person' ? l.prByYou : v.by, '${v.version}'),
                  style: TextStyle(color: c.dim, fontSize: 12.5),
                ),
                if (v.rule != null)
                  Text(
                    ruleLines(l, v.rule!.json).join(' · '),
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
              ],
            ),
          ),
        if (_error != null) AutoNotice(_error!, error: true),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            key: const Key('pr-undo'),
            onPressed: (_list ?? const []).isEmpty
                ? null
                : () async {
                    final cl = AppScope.read(context).client;
                    if (cl == null) return;
                    try {
                      await cl.undoPersonRule(widget.rule.id);
                    } on Exception catch (e) {
                      if (mounted) setState(() => _error = rulesWhy(e));
                    }
                    await _load();
                  },
            icon: RgIcon(RgIcons.restore, size: 16, color: c.text),
            label: Text(l.prUndo),
          ),
        ),
      ],
    );
  }
}

// ---------- The editor ----------

typedef RuleSubmit = Future<void> Function(
  RedGiantClient c,
  Map<String, dynamic> rule,
  bool enable,
);

/// Opens the rule's editor; true when it was saved.
Future<bool?> openRuleEditor(
  BuildContext context, {
  required String title,
  Map<String, dynamic>? seed,
  required RuleSubmit submit,
  String? submitLabel,
}) => openAutoWindow<bool>(
  context,
  title: title,
  wide: true,
  key: const Key('pr-editor'),
  child: (ctx, close) =>
      RuleEditor(seed: seed, submit: submit, submitLabel: submitLabel, onDone: () => close(true)),
);

Map<String, dynamic> _freshAction(String kind) => switch (kind) {
  'stop' => {'do': 'stop', 'text': '', 'scope': 'all', 'resume': 'person'},
  'tools_off' => {'do': 'tools_off', 'kits': <String>[], 'tools': <String>[]},
  'automation' => {'do': 'automation', 'automation': ''},
  'command' => {'do': 'command', 'command': ''},
  _ => {'do': kind, 'text': ''},
};

/// The draft as the server reads it, as the page's `toInput`: numbers as numbers, the examples
/// only on the fields the conditions use.
Map<String, dynamic> ruleInput(Map<String, dynamic> d) {
  final conds = [
    for (final c in (d['if'] as List? ?? const []))
      {
        ...(c as Map).cast<String, dynamic>(),
        'value': ruleNumericFields.contains(c['field'])
            ? (num.tryParse('${c['value']}') ?? 0)
            : '${c['value']}',
      },
  ];
  final used = {for (final c in conds) '${c['field']}'};
  final ex = (d['examples'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, Object> pick(Object? s) {
    final m = (s as Map?)?.cast<String, dynamic>() ?? const {};
    return {
      for (final f in used)
        if (m[f] != null && '${m[f]}'.isNotEmpty)
          f: ruleNumericFields.contains(f) ? (num.tryParse('${m[f]}') ?? 0) : '${m[f]}',
    };
  }

  final when = (d['when'] as Map).cast<String, dynamic>();
  return {
    'name': '${d['name'] ?? ''}'.trim(),
    'description': '${d['description'] ?? ''}',
    'when': when['event'] == 'schedule'
        ? {
            'event': 'schedule',
            'cron': '${when['cron'] ?? ''}',
            if ('${when['timezone'] ?? ''}'.isNotEmpty) 'timezone': when['timezone'],
          }
        : {'event': when['event']},
    'if': conds,
    'actions': d['actions'],
    'examples': used.isEmpty
        ? <String, Object>{}
        : {'fire': pick(ex['fire']), 'pass': pick(ex['pass'])},
  };
}

class RuleEditor extends StatefulWidget {
  const RuleEditor({
    super.key,
    this.seed,
    required this.submit,
    required this.onDone,
    this.submitLabel,
  });

  final Map<String, dynamic>? seed;
  final RuleSubmit submit;
  final VoidCallback onDone;
  final String? submitLabel;

  @override
  State<RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<RuleEditor> {
  late final Map<String, dynamic> _d = _start();
  RuleTrialView? _trial;
  String? _error;
  bool _busy = false;

  Map<String, dynamic> _start() {
    final s = widget.seed;
    if (s == null) {
      return {
        'name': '',
        'description': '',
        'when': {'event': 'tool'},
        'if': <Map<String, dynamic>>[],
        'actions': [_freshAction('notify')],
        'examples': {'fire': <String, dynamic>{}, 'pass': <String, dynamic>{}},
      };
    }
    final ex = (s['examples'] as Map?)?.cast<String, dynamic>() ?? const {};
    return {
      'name': s['name'] ?? '',
      'description': s['description'] ?? '',
      'when': {
        ...((s['when'] as Map?)?.cast<String, dynamic>() ?? {'event': 'tool'}),
      },
      'if': [
        for (final c in (s['if'] as List? ?? const [])) {...(c as Map).cast<String, dynamic>()},
      ],
      'actions': [
        for (final a in (s['actions'] as List? ?? const []))
          {...(a as Map).cast<String, dynamic>()},
      ],
      'examples': {
        'fire': {...((ex['fire'] as Map?)?.cast<String, dynamic>() ?? {})},
        'pass': {...((ex['pass'] as Map?)?.cast<String, dynamic>() ?? {})},
      },
    };
  }

  String get _event => '${(_d['when'] as Map)['event']}';
  List<Map<String, dynamic>> get _conds => (_d['if'] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get _acts => (_d['actions'] as List).cast<Map<String, dynamic>>();

  void _set(void Function() f) => setState(() {
    f();
    _trial = null;
  });

  Future<void> _try() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final t = await c.tryPersonRule(ruleInput(_d));
      if (mounted) setState(() => _trial = t);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  Future<void> _save(bool enable) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.submit(c, ruleInput(_d), enable);
      widget.onDone();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final fields = ruleFieldsByEvent[_event] ?? const <String>[];
    final kinds = [
      for (final k in ruleActions)
        if (ruleCanAsk(_event) || (k != 'ask' && k != 'block')) k,
    ];
    final used = {for (final x in _conds) '${x['field']}'};
    Widget part(String tag, String q) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$tag ',
              style: TextStyle(color: c.accent, fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: q,
              style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutoField(
          fieldKey: const Key('pr-name'),
          label: l.prName,
          hint: l.prNamePh,
          value: '${_d['name']}',
          onChanged: (v) => _set(() => _d['name'] = v),
        ),
        AutoField(
          fieldKey: const Key('pr-words'),
          label: l.prWords,
          value: '${_d['description']}',
          lines: 2,
          onChanged: (v) => _set(() => _d['description'] = v),
        ),
        part(l.prWhen, l.prWhenQ),
        RgChoice<String>(
          vertical: true,
          options: [for (final e in ruleEvents) (e, ruleEventWord(l, e))],
          value: _event,
          keyOf: (e) => 'pr-ev-$e',
          onChanged: (e) => _set(() {
            _d['when'] = {'event': e, if (e == 'schedule') 'cron': '0 9 * * 1-5'};
            _d['if'] = [
              for (final x in _conds)
                if ((ruleFieldsByEvent[e] ?? const []).contains(x['field'])) x,
            ];
            _d['actions'] = [
              for (final a in _acts)
                if (ruleCanAsk(e) || (a['do'] != 'ask' && a['do'] != 'block')) a,
            ];
            if (_acts.isEmpty) _d['actions'] = [_freshAction('notify')];
          }),
        ),
        if (_event == 'schedule') ...[
          const SizedBox(height: 10),
          AutoField(
            fieldKey: const Key('pr-cron'),
            label: l.prCron,
            help: l.prCronHelp,
            mono: true,
            value: '${(_d['when'] as Map)['cron'] ?? ''}',
            onChanged: (v) => _set(() => (_d['when'] as Map)['cron'] = v),
          ),
        ],
        part(l.prIf, l.prIfQ),
        if (_conds.isEmpty) Text(l.prIfNone, style: TextStyle(color: c.dim)),
        for (var i = 0; i < _conds.length; i++)
          Container(
            key: Key('pr-cond-$i'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                RgChoice<String>(
                  options: [for (final f in fields) (f, ruleFieldWord(l, f))],
                  value: '${_conds[i]['field']}',
                  keyOf: (f) => 'pr-cf-$i-$f',
                  onChanged: (f) => _set(() {
                    final n = ruleNumericFields.contains(f);
                    _conds[i] = {'field': f, 'op': n ? 'lte' : 'matches', 'value': n ? 5 : ''};
                  }),
                ),
                RgChoice<String>(
                  options: [
                    for (final o
                        in ruleNumericFields.contains(_conds[i]['field'])
                            ? ruleNumberOps
                            : ruleTextOps)
                      (o, ruleOpWord(l, o)),
                  ],
                  value: '${_conds[i]['op']}',
                  keyOf: (o) => 'pr-co-$i-$o',
                  onChanged: (o) => _set(() => _conds[i]['op'] = o),
                ),
                Row(
                  children: [
                    Expanded(
                      child: AutoField(
                        fieldKey: Key('pr-cv-$i'),
                        label: l.prValue,
                        value: '${_conds[i]['value']}',
                        decimal: ruleNumericFields.contains(_conds[i]['field']),
                        onChanged: (v) => _set(() => _conds[i]['value'] = v),
                      ),
                    ),
                    IconButton(
                      key: Key('pr-cx-$i'),
                      tooltip: l.prRemoveCond,
                      onPressed: () => _set(() => _conds.removeAt(i)),
                      icon: RgIcon(RgIcons.x, size: 18, color: c.dim),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (fields.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('pr-add-cond'),
              onPressed: () => _set(() {
                final f = fields.first;
                final n = ruleNumericFields.contains(f);
                _conds.add({'field': f, 'op': n ? 'lte' : 'matches', 'value': n ? 5 : ''});
              }),
              icon: RgIcon(RgIcons.plus, size: 16, color: c.accent),
              label: Text(l.prAddCond),
            ),
          ),
        part(l.prThen, l.prThenQ),
        for (var i = 0; i < _acts.length; i++)
          Container(
            key: Key('pr-act-$i'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                RgChoice<String>(
                  options: [for (final k in kinds) (k, ruleActionWord(l, k))],
                  value: '${_acts[i]['do']}',
                  keyOf: (k) => 'pr-ak-$i-$k',
                  onChanged: (k) => _set(() => _acts[i] = _freshAction(k)),
                ),
                if (const ['notify', 'ask', 'block', 'stop'].contains(_acts[i]['do']))
                  AutoField(
                    fieldKey: Key('pr-at-$i'),
                    label: _acts[i]['do'] == 'notify' ? l.prNotifyPh : l.prReasonPh,
                    value: _text(_acts[i], 'text'),
                    onChanged: (v) => _set(() => _acts[i]['text'] = v),
                  ),
                if (_acts[i]['do'] == 'stop') ...[
                  RgChoice<String>(
                    options: [
                      ('all', l.prScopeAll),
                      ('project', l.prScopeProject),
                      ('agent', l.prScopeAgent),
                    ],
                    value: '${_acts[i]['scope']}',
                    keyOf: (s) => 'pr-as-$i-$s',
                    onChanged: (s) => _set(() => _acts[i]['scope'] = s),
                  ),
                  RgChoice<String>(
                    options: [('person', l.prResumePerson), ('auto', l.prResumeAuto)],
                    value: '${_acts[i]['resume']}',
                    keyOf: (s) => 'pr-ar-$i-$s',
                    onChanged: (s) => _set(() => _acts[i]['resume'] = s),
                  ),
                ],
                if (_acts[i]['do'] == 'tools_off')
                  AutoField(
                    fieldKey: Key('pr-atools-$i'),
                    label: l.prToolsOff,
                    hint: 'web_search, kit:browser',
                    mono: true,
                    value: [
                      for (final k in _strings(_acts[i]['kits'])) 'kit:$k',
                      ..._strings(_acts[i]['tools']),
                    ].join(', '),
                    onChanged: (v) => _set(() {
                      final w = [
                        for (final x in v.split(','))
                          if (x.trim().isNotEmpty) x.trim(),
                      ];
                      _acts[i]['kits'] = [
                        for (final x in w)
                          if (x.startsWith('kit:')) x.substring(4),
                      ];
                      _acts[i]['tools'] = [
                        for (final x in w)
                          if (!x.startsWith('kit:')) x,
                      ];
                    }),
                  ),
                if (_acts[i]['do'] == 'automation')
                  AutoField(
                    fieldKey: Key('pr-aauto-$i'),
                    label: l.prAutomation,
                    value: _text(_acts[i], 'automation'),
                    onChanged: (v) => _set(() => _acts[i]['automation'] = v),
                  ),
                if (_acts[i]['do'] == 'command') ...[
                  AutoField(
                    fieldKey: Key('pr-acmd-$i'),
                    label: l.prCommand,
                    mono: true,
                    value: _text(_acts[i], 'command'),
                    onChanged: (v) => _set(() => _acts[i]['command'] = v),
                  ),
                  AutoField(
                    fieldKey: Key('pr-aproj-$i'),
                    label: l.prProjectPh,
                    value: _text(_acts[i], 'project'),
                    onChanged: (v) => _set(() {
                      if (v.trim().isEmpty) {
                        _acts[i].remove('project');
                      } else {
                        _acts[i]['project'] = v;
                      }
                    }),
                  ),
                  Text(l.prCommandSafe, style: TextStyle(color: c.dim, fontSize: 12.5)),
                ],
                if (_acts.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: Key('pr-ax-$i'),
                      onPressed: () => _set(() => _acts.removeAt(i)),
                      child: Text(l.prRemoveAct),
                    ),
                  ),
              ],
            ),
          ),
        if (_acts.length < 10)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('pr-add-act'),
              onPressed: () => _set(() => _acts.add(_freshAction('notify'))),
              icon: RgIcon(RgIcons.plus, size: 16, color: c.accent),
              label: Text(l.prAddAct),
            ),
          ),
        if (used.isNotEmpty) ...[
          part(l.prExamples, l.prExamplesQ),
          for (final kind in const ['fire', 'pass'])
            Container(
              key: Key('pr-ex-$kind'),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    kind == 'fire' ? l.prExFire : l.prExPass,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                  const SizedBox(height: 6),
                  for (final f in used)
                    AutoField(
                      fieldKey: Key('pr-x$kind-$f'),
                      label: ruleFieldWord(l, f),
                      value: '${((_d['examples'] as Map)[kind] as Map)[f] ?? ''}',
                      onChanged: (v) => _set(() => ((_d['examples'] as Map)[kind] as Map)[f] = v),
                    ),
                  if (_trial != null && (kind == 'fire' ? _trial!.fire : _trial!.pass) != null)
                    Text(
                      (kind == 'fire' ? _trial!.fire! : _trial!.pass!) ? l.prExOk : l.prExBad,
                      key: Key('pr-verdict-$kind'),
                      style: TextStyle(
                        color: (kind == 'fire' ? _trial!.fire! : _trial!.pass!) ? c.ok : c.err,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
        ],
        if (_trial != null)
          AutoNotice(
            _trial!.ok ? l.prTrialOk : _trial!.problems.join(' · '),
            error: !_trial!.ok,
            key: const Key('pr-trial'),
          ),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('pr-ed-error')),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(key: const Key('pr-try'), onPressed: _try, child: Text(l.prTry)),
            OutlinedButton(
              key: const Key('pr-save-off'),
              onPressed: _busy || '${_d['name']}'.trim().isEmpty ? null : () => _save(false),
              child: Text(l.prSaveOff),
            ),
            FilledButton(
              key: const Key('pr-save-on'),
              onPressed: _busy || '${_d['name']}'.trim().isEmpty ? null : () => _save(true),
              child: Text(widget.submitLabel ?? l.prSaveOn),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------- The magic rule ----------

class _MagicRuleChat extends StatefulWidget {
  const _MagicRuleChat({required this.magic, required this.onDone});

  final MagicRuleView magic;
  final void Function([void]) onDone;

  @override
  State<_MagicRuleChat> createState() => _MagicRuleChatState();
}

class _MagicRuleChatState extends State<_MagicRuleChat> {
  late MagicRuleView _m = widget.magic;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    // God works in the conversation; the proposal is read again until it comes.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_m.status == 'building') unawaited(_reload());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final m = await c.magicRule(_m.id);
      if (mounted) setState(() => _m = m);
    } on ApiException {
      // Read again at the next tick.
    }
  }

  Future<void> _do(Future<void> Function(RedGiantClient c) f, {bool close = false}) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await f(c);
      if (close) {
        widget.onDone();
        return;
      }
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final agent = app.agents.where((a) => a.id == _m.agentId).firstOrNull;
    final rule = _m.rule;
    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MagicSteps(status: _m.status, labels: [l.prMagicStep1, l.prMagicStep2, l.prMagicStep3]),
        if (_m.status == 'ready' && rule != null)
          Container(
            key: const Key('pr-mg-proposal'),
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.accent.withValues(alpha: .5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.prMagicProposal,
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rule['name'] ?? ''}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
                ),
                if (_m.summary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(_m.summary, style: TextStyle(color: c.text, height: 1.4)),
                  ),
                const SizedBox(height: 6),
                for (final line in ruleLines(l, rule))
                  Text(line, style: TextStyle(color: c.dim, height: 1.4)),
                if (_m.missing.isNotEmpty) RuleWarn('${l.prMagicMissing} ${_m.missing.join(', ')}'),
                if (_m.trial != null)
                  AutoNotice(
                    _m.trial!.ok
                        ? l.prTrialOk
                        : '${l.prMagicNotTested} ${_m.trial!.problems.join(' · ')}',
                    error: !_m.trial!.ok,
                  ),
                if (_error != null) AutoNotice(_error!, error: true),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      key: const Key('pr-mg-refuse'),
                      onPressed: () async {
                        final why = await askText(
                          context,
                          title: l.prMagicRefuse,
                          yes: l.prMagicSendNo,
                          hint: l.prMagicWhy,
                          fieldKey: const Key('pr-mg-why'),
                        );
                        if (why == null) return;
                        await _do(
                          (c) => c.rejectMagicRule(_m.id, why.trim().isEmpty ? null : why.trim()),
                        );
                      },
                      child: Text(l.prMagicRefuse),
                    ),
                    OutlinedButton(
                      key: const Key('pr-mg-change'),
                      onPressed: () async {
                        final done = await openRuleEditor(
                          context,
                          title: '${rule['name'] ?? ''}',
                          seed: rule,
                          submitLabel: l.prMagicApprove,
                          submit: (c, r, _) => c.approveMagicRule(_m.id, r),
                        );
                        if (done == true) widget.onDone();
                      },
                      child: Text(l.prMagicChange),
                    ),
                    FilledButton(
                      key: const Key('pr-mg-approve'),
                      onPressed: () => _do((c) => c.approveMagicRule(_m.id), close: true),
                      child: Text(l.prMagicApprove),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (_m.status == 'done') AutoNotice(l.prMagicDone),
        if (_m.status == 'building')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(l.prMagicBuilding, style: TextStyle(color: c.dim, height: 1.4)),
          ),
      ],
    );
    final chat = ConversationScreen(
      key: Key('pr-magic-conv-${_m.sessionId}'),
      sessionId: _m.sessionId,
      agent: agent,
      embedded: true,
    );
    if (isWide(context)) {
      return SizedBox(
        height: MediaQuery.sizeOf(context).height * .8,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 340,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: c.line)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 20),
                  child: side,
                ),
              ),
            ),
            Expanded(child: chat),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .42),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: side,
          ),
        ),
        Divider(height: 1, color: c.line),
        Expanded(child: chat),
      ],
    );
  }
}
