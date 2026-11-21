// G42.17: Settings › Platform, the page's Platform.tsx, native: every change to the settings (by
// the person or by God) in sentences, newest first, undoable while its `before` is kept; God's
// code changes apart, with their stage, «Discard» and «Promote» (asked first, and only when a
// supervisor runs the server); the raw data under «Technical details»; how the server runs and its
// releases. The sentences are the page's `describeChange` (changes.ts), checked with its vectors.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../app_state.dart';
import '../l10n/rule_words.g.dart';
import '../l10n/tool_words.g.dart';
import '../setup/wizard/wizard_screen.dart' show wzWord;
import '../setup/wizard/wizard_words.g.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'extensions/ext_catalog.dart' show mcpCatalog;
import 'rules_kit.dart';

Future<void> openPlatformSettings(BuildContext context) =>
    openRulesPage(context, (panel) => PlatformScreen(panel: panel));

class PlatformChange {
  PlatformChange(Map<String, dynamic> j)
    : id = '${j['id'] ?? ''}',
      kind = '${j['kind'] ?? 'config'}',
      change = '${j['change'] ?? ''}',
      stage = '${j['stage'] ?? ''}',
      target = j['target'] as String?,
      before = j['before'],
      after = j['after'],
      detail = j['detail'] as String?,
      by = '${j['by'] ?? ''}',
      createdAt = '${j['createdAt'] ?? ''}',
      updatedAt = '${j['updatedAt'] ?? ''}',
      hasBefore = j.containsKey('before');

  final String id;
  final String kind;
  final String change;
  final String stage;
  final String? target;
  final Object? before;
  final Object? after;
  final String? detail;
  final String by;
  final String createdAt;
  final String updatedAt;
  final bool hasBefore;
}

extension PlatformApi on RedGiantClient {
  Future<Map<String, dynamic>> platformInfo() async => objectOf(await getJson('/api/platform'));
  Future<List<PlatformChange>> platformChanges() async => [
    for (final c in arrayOf(await getJson('/api/platform/changes'))) PlatformChange(c),
  ];
  Future<void> undoChange(String id) =>
      callJson('POST', '/api/platform/changes/${Uri.encodeComponent(id)}/undo', const {});
  Future<void> discardChange(String id) =>
      callJson('POST', '/api/platform/changes/${Uri.encodeComponent(id)}/discard', const {});
  Future<void> promoteChange(String id) =>
      callJson('POST', '/api/platform/changes/${Uri.encodeComponent(id)}/promote', const {});
}

// ---- the sentences (changes.ts) ----

typedef ChangeNames = ({String Function(String) agent, String Function(String) project});

String _t(String lang, String key, [Map<String, String> v = const {}]) {
  var s = wizardWords[lang]?[key] ?? wizardWords['en']![key] ?? key;
  v.forEach((k, x) => s = s.replaceAll('{$k}', x));
  return s;
}

String? _opt(String lang, String key) => wizardWords[lang]?[key] ?? toolWords[lang]?[key];

String _fixed(double v, int digits) => v.toStringAsFixed(digits);

/// The page's `usd` and `kTokens` (format.ts).
String usdText(num v) =>
    v == 0 ? r'$0' : (v < 0.01 ? '\$${_fixed(v.toDouble(), 4)}' : '\$${_fixed(v.toDouble(), 2)}');
String kTokensText(num n) => n >= 1000000
    ? '${_fixed(n / 1000000, 1)}M'
    : n >= 10000
    ? '${(n / 1000 + 0.5).floor()}k'
    : n >= 1000
    ? '${_fixed(n / 1000, 1)}k'
    : '$n';

Map<dynamic, dynamic> _map(Object? o) => o is Map<dynamic, dynamic> ? o : const {};
List<String> _strs(Object? o) => [for (final x in o is List ? o : const []) '$x'];

/// What a change did, in one or more sentences, as the page's `describeChange`.
List<String> describeChange(PlatformChange c, ChangeNames n, String lang) {
  String t(String k, [Map<String, String> v = const {}]) => _t(lang, k, v);
  if (c.kind == 'code')
    return [
      t('chgCode', {'what': c.change}),
    ];
  final target = c.target ?? '';
  final parts = target.split(':');
  final type = parts.first;
  final id = parts.skip(1).join(':');
  String limitText(Map<dynamic, dynamic> l) => l['usd'] is num
      ? usdText(l['usd'] as num)
      : l['tokens'] is num
      ? '${kTokensText(l['tokens'] as num)} token'
      : t('chgNoLimit');
  double limitSize(Map<dynamic, dynamic> l) =>
      ((l['usd'] ?? l['tokens']) as num?)?.toDouble() ?? double.infinity;
  String dangers(List<String> ids) =>
      ids.map((x) => ruleWords[lang]?.dangers[x]?.name ?? x).join(', ');
  String tools(List<String> ids) => ids.map((x) => _opt(lang, 'tool_$x') ?? x).join(', ');
  if (type == 'budget') {
    final scope = parts.length > 1 ? parts[1] : '';
    final who = parts.skip(2).join(':');
    final b = _map(c.before);
    final a = _map(c.after);
    final what = scope == 'global'
        ? t('chgBudgetTotal')
        : t('chgBudgetOf', {'name': scope == 'project' ? n.project(who) : n.agent(who)});
    final v = {'what': what, 'before': limitText(b), 'after': limitText(a)};
    final bs = limitSize(b);
    final as = limitSize(a);
    if (as == double.infinity && bs != as) return [t('chgBudgetRemoved', v)];
    if (bs == double.infinity && as != bs) return [t('chgBudgetSet', v)];
    return [t(as > bs ? 'chgBudgetUp' : (as < bs ? 'chgBudgetDown' : 'chgBudgetSame'), v)];
  }
  if (type == 'agent') {
    final name = n.agent(id);
    final b = _map(c.before);
    final a = _map(c.after);
    String model(Object? m) => m is Map<dynamic, dynamic>
        ? '${m['provider']}/${m['model']}${m['effort'] != null ? ' (${m['effort']})' : ''}'
        : t('chgInherited');
    String mode(Object? m) => m == null ? t('chgInherited') : (_opt(lang, 'agentMode_$m') ?? '$m');
    final out = <String>[];
    if (a.containsKey('model') && jsonEncode(b['model']) != jsonEncode(a['model'])) {
      out.add(
        t('chgAgentModel', {'name': name, 'before': model(b['model']), 'after': model(a['model'])}),
      );
    }
    if (a.containsKey('mode') && b['mode'] != a['mode']) {
      out.add(
        t('chgAgentMode', {'name': name, 'before': mode(b['mode']), 'after': mode(a['mode'])}),
      );
    }
    if (a.containsKey('systemPrompt') && b['systemPrompt'] != a['systemPrompt']) {
      final p = a['systemPrompt'];
      out.add(
        t(p is String && p.isNotEmpty ? 'chgAgentPrompt' : 'chgAgentPromptReset', {'name': name}),
      );
    }
    return out.isNotEmpty
        ? out
        : [
            t('chgAgentSame', {'name': name}),
          ];
  }
  if (type == 'policy') {
    final b = _map(c.before);
    final a = _map(c.after);
    List<String> diff(Object? x, Object? y) =>
        _strs(x).where((v) => !_strs(y).contains(v)).toList();
    final out = <String>[];
    final added = diff(a['humanOnly'], b['humanOnly']);
    final removed = diff(b['humanOnly'], a['humanOnly']);
    final off = diff(a['disabledDanger'], b['disabledDanger']);
    final on = diff(b['disabledDanger'], a['disabledDanger']);
    if (added.isNotEmpty) out.add(t('chgHumanOnly', {'list': dangers(added)}));
    if (removed.isNotEmpty) out.add(t('chgNotHumanOnly', {'list': dangers(removed)}));
    if (off.isNotEmpty) out.add(t('chgDangerOff', {'list': dangers(off)}));
    if (on.isNotEmpty) out.add(t('chgDangerOn', {'list': dangers(on)}));
    String key(Map<dynamic, dynamic> r) => '${r['tool']}|${r['match'] ?? ''}|${r['decision']}';
    List<Map<dynamic, dynamic>> rules(Map<dynamic, dynamic> p) => [
      for (final r in (p['rules'] as List? ?? const []))
        if (r is Map<dynamic, dynamic>) r,
    ];
    final had = rules(b).map(key).toSet();
    final has = rules(a).map(key).toSet();
    String rule(Map<dynamic, dynamic> r) => t('chgRule_${r['decision']}', {
      'tool': '${r['tool']}',
      'match': r['match'] != null && '${r['match']}'.isNotEmpty ? ' (${r['match']})' : '',
    });
    for (final r in rules(a)) {
      if (!had.contains(key(r))) out.add(t('chgRuleAdded', {'rule': rule(r)}));
    }
    for (final r in rules(b)) {
      if (!has.contains(key(r))) out.add(t('chgRuleRemoved', {'rule': rule(r)}));
    }
    return out.isNotEmpty ? out : [t('chgPolicySame')];
  }
  if (type == 'automation') {
    String nameOf(Object? x) {
      final m = RegExp(
        r'''^name:\s*["']?([^"'\n]+)''',
        multiLine: true,
      ).firstMatch('${_map(x)['yaml'] ?? ''}');
      return m?.group(1) ?? '';
    }

    final name = nameOf(c.after).isNotEmpty ? nameOf(c.after) : nameOf(c.before);
    if (c.before == null)
      return [
        t('chgAutoCreated', {'name': name}),
      ];
    if (c.after == null)
      return [
        t('chgAutoDeleted', {'name': name}),
      ];
    if (_map(c.before)['yaml'] != _map(c.after)['yaml'])
      return [
        t('chgAutoEdited', {'name': name}),
      ];
    return [
      t(_map(c.after)['enabled'] == true ? 'chgAutoOn' : 'chgAutoOff', {'name': name}),
    ];
  }
  if (type == 'mcp') {
    final name = mcpCatalog.where((e) => e.id == id).firstOrNull?.name ?? id;
    String where(Object? m) {
      final p = _map(m)['projectId'];
      return p is String ? t('extOnlyProject', {'name': n.project(p)}) : t('extEverywhere');
    }

    if (c.before == null && c.after != null)
      return [
        t('chgMcpAdded', {'name': name, 'where': where(c.after)}),
      ];
    if (c.before != null && c.after == null)
      return [
        t('chgMcpRemoved', {'name': name}),
      ];
    return [
      t('chgMcpChanged', {'name': name, 'where': where(c.after)}),
    ];
  }
  if (type == 'tools') {
    final b = _map(c.before);
    final a = _map(c.after);
    List<String> kitLines(Map<dynamic, dynamic> kb, Map<dynamic, dynamic> ka, [String? who]) {
      final ids = {...kb.keys, ...ka.keys}.map((x) => '$x').where((x) => kb[x] != ka[x]).toList();
      return [
        for (final k in ids)
          () {
            final kit = _opt(lang, 'kit_$k') ?? k;
            final v = ka[k];
            final state = v == 'on'
                ? t('kitOn')
                : v == 'off'
                ? t('kitOff')
                : v == 'auto'
                ? t('kitAuto')
                : t('chgKitDefault');
            return who != null
                ? t('chgKitAgent', {'name': who, 'kit': kit, 'state': state})
                : t('chgKit', {'kit': kit, 'state': state});
          }(),
      ];
    }

    final out = <String>[];
    if (id.isEmpty) {
      out.addAll(kitLines(_map(b['kits']), _map(a['kits'])));
      final bo = _strs(b['off']);
      final ao = _strs(a['off']);
      final off = ao.where((x) => !bo.contains(x)).toList();
      final on = bo.where((x) => !ao.contains(x)).toList();
      if (off.isNotEmpty) out.add(t('chgToolsOff', {'list': tools(off)}));
      if (on.isNotEmpty) out.add(t('chgToolsOn', {'list': tools(on)}));
      return out.isNotEmpty ? out : [t('chgToolsSame')];
    }
    final name = n.agent(id);
    out.addAll(kitLines(_map(_map(b['agentKits'])[id]), _map(_map(a['agentKits'])[id]), name));
    final bb = _map(_map(b['agents'])[id]);
    final aa = _map(_map(a['agents'])[id]);
    final ids = {...bb.keys, ...aa.keys}.map((x) => '$x').where((x) => bb[x] != aa[x]).toList();
    List<String> of(String? v) => ids.where((x) => aa[x] == v).toList();
    if (of('on').isNotEmpty) out.add(t('chgToolsAgentOn', {'name': name, 'list': tools(of('on'))}));
    if (of('off').isNotEmpty)
      out.add(t('chgToolsAgentOff', {'name': name, 'list': tools(of('off'))}));
    if (of(null).isNotEmpty)
      out.add(t('chgToolsAgentDefault', {'name': name, 'list': tools(of(null))}));
    return out.isNotEmpty ? out : [t('chgToolsSame')];
  }
  if (type == 'project-agents') {
    final before = _map(c.before)['maxAgents'];
    final after = _map(c.after)['maxAgents'];
    if (after != null) {
      return [
        t('chgProjectAgents', {
          'project': n.project(id),
          'from': before == null ? '—' : '$before',
          'to': '$after',
        }),
      ];
    }
  }
  return [c.change];
}

String codeStageText(String stage, String lang) => _t(lang, 'chgStage_$stage');

class PlatformScreen extends StatefulWidget {
  const PlatformScreen({super.key, required this.panel});

  final bool panel;

  @override
  State<PlatformScreen> createState() => _PlatformScreenState();
}

class _PlatformScreenState extends State<PlatformScreen> {
  late final AppController app = AppScope.read(context);
  List<PlatformChange>? _changes;
  Map<String, dynamic>? _info;
  String? _error;
  final _open = <String>{};

  String get _lang => Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
  String w(String k, [Map<String, String> v = const {}]) => wzWord(context, k, v);

  ChangeNames get _names => (
    agent: (id) => app.agents.where((a) => a.id == id).firstOrNull?.name ?? id,
    project: (id) => app.projects.where((p) => p.id == id).firstOrNull?.name ?? id,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    app.live.platformChanged.addListener(_pushed);
  }

  void _pushed() => unawaited(_load());

  @override
  void dispose() {
    app.live.platformChanged.removeListener(_pushed);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final c = app.client!;
      final r = await Future.wait<Object>([c.platformChanges(), c.platformInfo()]);
      if (mounted) {
        setState(() {
          _changes = r[0] as List<PlatformChange>;
          _info = r[1] as Map<String, dynamic>;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _act(Future<void> Function() f) async {
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    await _load();
  }

  String _who(String id) => id == 'human'
      ? w('you')
      : id == 'supervisor'
      ? w('supervisorName')
      : _names.agent(id);

  String _when(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  Widget _tech(RgColors c, String id, List<Widget> body) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton(
        key: Key('pl-tech-$id'),
        onPressed: () => setState(() => _open.contains(id) ? _open.remove(id) : _open.add(id)),
        child: Text(w('historyTechnical')),
      ),
      if (_open.contains(id))
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 6, children: body),
        ),
    ],
  );

  Widget _mono(RgColors c, String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: c.code, borderRadius: BorderRadius.circular(8)),
    child: SelectableText(
      text,
      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.text),
    ),
  );

  String _json(Object? v) => v == null ? '—' : const JsonEncoder.withIndent('  ').convert(v);

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final list = _changes;
    final info = _info;
    final code = list?.where((x) => x.kind == 'code').toList() ?? const [];
    final config = list?.where((x) => x.kind == 'config').toList() ?? const [];
    final supervised = info?['supervised'] == true;
    return RulesPage(
      pageKey: const Key('pl-page'),
      panel: widget.panel,
      title: w('platformView'),
      question: w('sbPlatformQ'),
      lead: w('historyIntro'),
      children: [
        if (_error != null) NoticeBanner(key: const Key('pl-error'), text: _error!, error: true),
        if (list == null) const RulesLoading(),
        if (code.isNotEmpty) ...[
          RulesSub(title: w('historyCode'), lead: w('historyCodeHelp')),
          for (final x in code)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SettingsCard(
                key: Key('pl-code-${x.id}'),
                children: [
                  ListTile(
                    leading: RgIcon(RgIcons.git, color: c.accent),
                    title: Text(describeChange(x, _names, _lang).first),
                    subtitle: Text(
                      '${codeStageText(x.stage, _lang)}\n${_who(x.by)} · ${_when(x.updatedAt)}',
                    ),
                    isThreeLine: true,
                  ),
                  if (['proposed', 'tested', 'failed', 'rolled_back'].contains(x.stage))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            key: Key('pl-discard-${x.id}'),
                            onPressed: () => unawaited(_act(() => app.client!.discardChange(x.id))),
                            child: Text(w('discard')),
                          ),
                          if (x.stage == 'tested' && supervised)
                            FilledButton(
                              key: Key('pl-promote-${x.id}'),
                              onPressed: () async {
                                final ok = await askConfirm(
                                  context,
                                  title: w('historyPromote'),
                                  body:
                                      '${describeChange(x, _names, _lang).first}\n\n${w('historyPromoteConfirm')}',
                                  yes: w('historyPromote'),
                                );
                                if (ok) await _act(() => app.client!.promoteChange(x.id));
                              },
                              child: Text(w('historyPromote')),
                            ),
                        ],
                      ),
                    ),
                  if (x.stage == 'tested' && !supervised)
                    NoteLine(icon: RgIcons.info, text: w('techNotSupervised')),
                  if (x.detail != null) _tech(c, x.id, [_mono(c, x.detail!)]),
                ],
              ),
            ),
        ],
        RulesSub(title: w('historySettings')),
        if (list != null && config.isEmpty) NoteLine(icon: RgIcons.info, text: w('noChanges')),
        for (final x in config)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SettingsCard(
              key: Key('pl-change-${x.id}'),
              children: [
                ListTile(
                  leading: RgIcon(RgIcons.settings, color: x.stage == 'undone' ? c.dim : c.accent),
                  title: Text(
                    describeChange(x, _names, _lang).join('\n'),
                    style: TextStyle(
                      color: x.stage == 'undone' ? c.dim : c.text,
                      decoration: x.stage == 'undone' ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    [
                      _who(x.by),
                      _when(x.createdAt),
                      if (x.stage == 'undone') w('historyUndone'),
                    ].join(' · '),
                  ),
                  trailing: x.stage == 'promoted' && x.hasBefore
                      ? TextButton(
                          key: Key('pl-undo-${x.id}'),
                          onPressed: () => unawaited(_act(() => app.client!.undoChange(x.id))),
                          child: Text(w('undo')),
                        )
                      : null,
                ),
                _tech(c, x.id, [
                  Text(w('before'), style: TextStyle(color: c.dim)),
                  _mono(c, _json(x.before)),
                  Text(w('after'), style: TextStyle(color: c.dim)),
                  _mono(c, _json(x.after)),
                  if (x.detail != null) _mono(c, x.detail!),
                ]),
              ],
            ),
          ),
        if (info != null)
          SettingsCard(
            key: const Key('pl-info'),
            children: [
              _tech(c, 'info', [
                Text(
                  w('techWhereTitle'),
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                ),
                Text(
                  wizardWords[_lang]?['techWhere_${info['sandbox']}'] ?? '${info['sandbox']}',
                  style: TextStyle(color: c.dim),
                ),
                if (info['metal'] == true)
                  Text(w('techMetal'), style: TextStyle(color: c.warnText)),
                Text(
                  w('techCodeTitle'),
                  style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                ),
                Text(
                  supervised
                      ? [
                          w('techSupervised'),
                          if (info['lastGood'] is String)
                            w('techLastGood', {
                              'commit': (info['lastGood'] as String).padRight(8).substring(0, 8),
                            }),
                        ].join(' ')
                      : '${w('techNotSupervised')} ${w('techNotSupervisedMeans')}',
                  style: TextStyle(color: c.dim),
                ),
                for (final r
                    in (info['releases'] as List? ?? const []).whereType<Map<dynamic, dynamic>>())
                  Text(
                    '${codeStageText('${r['result']}', _lang)} · ${'${r['commit']}'.padRight(8).substring(0, 8)} · ${_when('${r['at']}')}',
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
                if ((info['releases'] as List? ?? const []).isNotEmpty)
                  Text(w('releases'), style: TextStyle(color: c.dim, fontSize: 12)),
              ]),
            ],
          ),
      ],
    );
  }
}
