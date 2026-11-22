// 3.12: Settings › Rules' routes, the same the page calls (`rules`, `createRule`, `enableRule`,
// `undoRule`, `tryRule`, `ruleHistory`, `addRuleTemplate`, `resumeRules`, `magicRule…` in
// packages/web/src/api.ts). A rule travels as the page's JSON (`RuleDraft` in
// packages/protocol/src/person-rules.ts): when, if, then, examples.
import '../../api/client.dart';

String _id(String id) => Uri.encodeComponent(id);

/// The events a rule listens to, in the page's order.
const ruleEvents = ['usage', 'budget', 'tool', 'file', 'agent_done', 'schedule', 'webhook'];

/// Which facts each event has (`RULE_FIELDS_BY_EVENT`).
const ruleFieldsByEvent = <String, List<String>>{
  'usage': ['marginPct', 'usedPct', 'window', 'provider'],
  'budget': ['budgetPct', 'budget'],
  'tool': ['tool', 'command', 'path', 'project', 'agent'],
  'file': ['path', 'tool', 'project', 'agent'],
  'agent_done': ['agent', 'project', 'stopReason'],
  'schedule': [],
  'webhook': ['body'],
};

const ruleNumericFields = {'marginPct', 'usedPct', 'budgetPct'};
const ruleNumberOps = ['lte', 'lt', 'gte', 'gt', 'eq', 'neq'];
const ruleTextOps = ['eq', 'neq', 'matches', 'contains'];
const ruleActions = ['notify', 'ask', 'block', 'stop', 'tools_off', 'automation', 'command'];

/// Only where something is about to run can a rule ask or block.
bool ruleCanAsk(String event) => event == 'tool' || event == 'file';

Map<String, dynamic> _map(Object? o) =>
    o is Map<String, dynamic> ? o : (o is Map ? o.cast<String, dynamic>() : <String, dynamic>{});
List<Map<String, dynamic>> _maps(Object? o) => [
  for (final x in (o is List ? o : const [])) _map(x),
];
String _s(Object? o) => o is String ? o : '';

/// A rule as the server keeps it (`PersonRule`); [draft] is what the editor changes and sends.
class PersonRuleView {
  PersonRuleView(this.json);

  final Map<String, dynamic> json;

  String get id => _s(json['id']);
  String get name => _s(json['name']);
  String get description => _s(json['description']);
  bool get enabled => json['enabled'] == true;
  String get origin => _s(json['origin']);
  int get version => (json['version'] as num?)?.toInt() ?? 0;
  String? get lastFiredAt => json['lastFiredAt'] is String ? json['lastFiredAt'] as String : null;
  Map<String, dynamic> get when => _map(json['when']);
  String get event => _s(when['event']);
  List<Map<String, dynamic>> get conditions => _maps(json['if']);
  List<Map<String, dynamic>> get actions => _maps(json['actions']);

  /// The fields the editor sends back (`RuleDraft`).
  Map<String, dynamic> get draft => {
    'name': name,
    'description': description,
    'when': when,
    'if': conditions,
    'actions': actions,
    'examples': _map(json['examples']),
  };
}

/// A stop a rule put in place (`RuleHold`).
class RuleHoldView {
  RuleHoldView(this.json);

  final Map<String, dynamic> json;
  String get ruleId => _s(json['ruleId']);
  String get ruleName => _s(json['ruleName']);
  String get reason => _s(json['reason']);
  String get at => _s(json['at']);
}

/// A time a rule acted (`RuleFire`).
class RuleFireView {
  RuleFireView(this.json);

  final Map<String, dynamic> json;
  String get id => _s(json['id']);
  String get ruleName => _s(json['ruleName']);
  String get at => _s(json['at']);
  List<String> get results => [
    for (final r in (json['results'] is List ? json['results'] as List : const []))
      if (r is String) r,
  ];
}

/// One version of a rule's history (`RuleVersion`).
class RuleVersionView {
  RuleVersionView(this.json);

  final Map<String, dynamic> json;
  int get version => (json['version'] as num?)?.toInt() ?? 0;
  String get change => _s(json['change']);
  String get by => _s(json['by']);
  String get at => _s(json['at']);
  PersonRuleView? get rule => json['rule'] is Map ? PersonRuleView(_map(json['rule'])) : null;
}

/// The examples' outcome (`RuleTrial`).
class RuleTrialView {
  RuleTrialView(this.json);

  final Map<String, dynamic> json;
  bool get ok => json['ok'] == true;
  bool? get fire => json['fire'] is bool ? json['fire'] as bool : null;
  bool? get pass => json['pass'] is bool ? json['pass'] as bool : null;
  List<String> get problems => [
    for (final p in (json['problems'] is List ? json['problems'] as List : const []))
      if (p is String) p,
  ];
}

/// A magic rule (`MagicRule`): God's conversation and its proposal.
class MagicRuleView {
  MagicRuleView(this.json);

  final Map<String, dynamic> json;
  String get id => _s(json['id']);
  String get title => _s(json['title']);
  String get status => _s(json['status']);
  String get sessionId => _s(json['sessionId']);
  String get agentId => _s(json['agentId']);
  Map<String, dynamic>? get proposal => json['proposal'] is Map ? _map(json['proposal']) : null;
  Map<String, dynamic>? get rule => proposal == null ? null : _map(proposal!['rule']);
  String get summary => _s(proposal?['summary']);
  List<String> get missing => [
    for (final m in (proposal?['missing'] is List ? proposal!['missing'] as List : const []))
      if (m is String) m,
  ];
  RuleTrialView? get trial =>
      proposal?['trial'] is Map ? RuleTrialView(_map(proposal!['trial'])) : null;
}

/// What `GET /api/rules` answers.
typedef RulesLoaded = ({
  List<PersonRuleView> rules,
  List<RuleHoldView> holds,
  List<RuleFireView> fires,
});

extension PersonRulesApi on RedGiantClient {
  /// `GET /api/rules`.
  Future<RulesLoaded> personRules() async {
    final j = objectOf(await getJson('/api/rules'));
    return (
      rules: [for (final r in _maps(j['rules'])) PersonRuleView(r)],
      holds: [for (final h in _maps(j['holds'])) RuleHoldView(h)],
      fires: [for (final f in _maps(j['fires'])) RuleFireView(f)],
    );
  }

  /// `POST /api/rules`.
  Future<PersonRuleView> createPersonRule(Map<String, dynamic> rule, {bool enable = false}) async =>
      PersonRuleView(
        objectOf(await callJson('POST', '/api/rules', {'rule': rule, 'enable': enable})),
      );

  /// `PUT /api/rules/:id`.
  Future<PersonRuleView> updatePersonRule(String id, Map<String, dynamic> rule) async =>
      PersonRuleView(objectOf(await callJson('PUT', '/api/rules/${_id(id)}', {'rule': rule})));

  /// `POST /api/rules/:id/enabled`.
  Future<PersonRuleView> enablePersonRule(String id, bool enabled) async => PersonRuleView(
    objectOf(await callJson('POST', '/api/rules/${_id(id)}/enabled', {'enabled': enabled})),
  );

  /// `DELETE /api/rules/:id`.
  Future<void> removePersonRule(String id) => callJson('DELETE', '/api/rules/${_id(id)}');

  /// `POST /api/rules/:id/secret`: a webhook rule's new secret, shown only now.
  Future<String> rotatePersonRuleSecret(String id) async {
    final j = objectOf(await callJson('POST', '/api/rules/${_id(id)}/secret', {}));
    return j['webhookSecret'] is String ? j['webhookSecret'] as String : '';
  }

  /// `POST /api/rules/:id/undo`: the version before the last change comes back.
  Future<void> undoPersonRule(String id) => callJson('POST', '/api/rules/${_id(id)}/undo', {});

  /// `POST /api/rules/try`: the two examples, run now.
  Future<RuleTrialView> tryPersonRule(Map<String, dynamic> rule) async =>
      RuleTrialView(objectOf(await callJson('POST', '/api/rules/try', {'rule': rule})));

  /// `GET /api/rules/history?id=`.
  Future<List<RuleVersionView>> personRuleHistory(String id) async => [
    for (final v in arrayOf(await getJson('/api/rules/history', {'id': id}))) RuleVersionView(v),
  ];

  /// `POST /api/rules/template`: a ready-made set, added switched off.
  Future<void> addPersonRuleTemplate(String template) =>
      callJson('POST', '/api/rules/template', {'template': template, 'enable': false});

  /// `POST /api/rules/resume`: one rule's stop, or all of them.
  Future<void> resumePersonRules([String? ruleId]) =>
      callJson('POST', '/api/rules/resume', {'ruleId': ?ruleId});

  /// `GET /api/magic-rules`.
  Future<List<MagicRuleView>> magicRules() async => [
    for (final m in arrayOf(await getJson('/api/magic-rules'))) MagicRuleView(m),
  ];

  /// `GET /api/magic-rules/:id`.
  Future<MagicRuleView> magicRule(String id) async =>
      MagicRuleView(objectOf(await getJson('/api/magic-rules/${_id(id)}')));

  /// `POST /api/magic-rules`: a conversation with God starts.
  Future<MagicRuleView> startMagicRule(String request) async =>
      MagicRuleView(objectOf(await callJson('POST', '/api/magic-rules', {'request': request})));

  /// `POST /api/magic-rules/:id/approve`, with the person's change or as God wrote it.
  Future<void> approveMagicRule(String id, [Map<String, dynamic>? rule]) =>
      callJson('POST', '/api/magic-rules/${_id(id)}/approve', {'rule': ?rule});

  /// `POST /api/magic-rules/:id/reject`, with what is wrong.
  Future<void> rejectMagicRule(String id, [String? reason]) =>
      callJson('POST', '/api/magic-rules/${_id(id)}/reject', {'reason': ?reason});
}
