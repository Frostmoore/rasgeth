// G42.17: the setup wizard's rules as the page's packages/web/src/wizard.ts (checked with its
// vectors, tool/wizard_vectors.mjs): which steps there are for a mode, a role, the local offer and
// a password chosen before; which may be left for later; the step after one; the ready choices of
// the approvals and which one a set is; the ways of thinking in use.
import 'wizard_presets.g.dart';

export 'wizard_presets.g.dart';

/// The wizard's steps, the page's `StepKey`.
const allSteps = [
  'wzWelcome',
  'wzRole',
  'wzAccount',
  'wzMachine',
  'wzMode',
  'wzBrain',
  'wzLocal',
  'wzNames',
  'wzAssign',
  'wzImport',
  'wzTelegram',
  'wzStorage',
  'wzCode',
  'wzRemote',
  'wzSafety',
  'wzDone',
];

/// The step only the advanced installation has.
const advancedSteps = ['wzCode'];

List<String> stepsFor(String? mode, {String? role, bool? local, bool password = false}) {
  if (password) {
    return stepsFor(mode, role: role, local: local).where((k) => k != 'wzAccount').toList();
  }
  // A node gets its agents, models and chats from the main one (pairing).
  if (role == 'node') return ['wzWelcome', 'wzRole', 'wzAccount', 'wzMachine', 'wzDone'];
  return [
    'wzWelcome',
    'wzRole',
    'wzAccount',
    'wzMachine',
    'wzMode',
    'wzBrain',
    if (local != false) 'wzLocal',
    'wzNames',
    'wzAssign',
    'wzImport',
    'wzTelegram',
    'wzStorage',
    if (mode == 'advanced') ...advancedSteps,
    'wzRemote',
    'wzSafety',
    'wzDone',
  ];
}

const _skippable = [
  'wzBrain',
  'wzLocal',
  'wzImport',
  'wzTelegram',
  'wzStorage',
  'wzCode',
  'wzRemote',
];

/// The password step is skipped only by who can sign in otherwise.
bool skippable(String k, {bool mustSetPassword = false}) =>
    _skippable.contains(k) || (k == 'wzAccount' && !mustSetPassword);

String stepAfter(List<String> list, String from) {
  final i = list.indexOf(from);
  final at = (i + 1).clamp(0, list.length - 1);
  return list.isEmpty ? 'wzDone' : list[at];
}

String? presetOf(List<String> humanOnly) {
  for (final e in presets.entries) {
    if (e.value.length == humanOnly.length && e.value.every(humanOnly.contains)) return e.key;
  }
  return null;
}

/// The ways of thinking connected now: claude, chatgpt, keys, local, server.
List<String> waysInUse(Map<String, dynamic> s) {
  final config = (s['config'] as Map?) ?? const {};
  final subs = (config['subscriptions'] as Map?) ?? const {};
  final keys = (((s['secretsSet'] as Map?) ?? const {})['keys'] as List?) ?? const [];
  final locked = (s['locked'] as Map?) ?? const {};
  return [
    if (subs['claude'] == true) 'claude',
    if (subs['chatgpt'] == true) 'chatgpt',
    if (keys.isNotEmpty || locked['anthropic'] == true) 'keys',
    if (config['engine'] != null) 'local',
    if (config['server'] != null || locked['server'] == true) 'server',
  ];
}

/// Paid per use: a provider's key (subscriptions and local models cost nothing more).
bool paysPerUse(Map<String, dynamic> s) {
  final keys = (((s['secretsSet'] as Map?) ?? const {})['keys'] as List?) ?? const [];
  return keys.isNotEmpty || ((s['locked'] as Map?) ?? const {})['anthropic'] == true;
}

/// The page's `passwordProblem`: the word key of what is wrong, or null.
String? passwordProblem(String value, String again, {required bool needed}) {
  if (value.isEmpty && again.isEmpty) return needed ? 'fbPasswordNeeded' : null;
  if (value.length < 10 || RegExp(r'^(.)\1+$').hasMatch(value)) return 'fbPasswordWeak';
  if (value != again) return 'fbPasswordDiffer';
  return null;
}
