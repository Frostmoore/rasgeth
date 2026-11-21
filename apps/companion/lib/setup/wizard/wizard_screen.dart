// G42.17: the setup wizard, native, as the page's Setup.tsx: one question per screen, a thin line
// of progress at the top and a counter that opens every step; big «Next», «Back» and «Skip» at
// the bottom. Each step is saved when it is left and the wizard can be run again from Settings
// («Redo the setup»); the app's own first start (the temporary network, the access, the
// languages, a way of thinking, the names) goes on here for the rest. The steps the app already
// has as native settings (models, local models, Telegram, backups, code, access from outside,
// safety) open those screens from their step; the others are drawn here. The rules are the page's
// (wizard_logic.dart, its vectors) and so are the words (wizard_words.g.dart).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../settings/api/rules_api.dart';
import '../../settings/api/system_api.dart';
import '../../settings/channels/telegram_screen.dart' show openTelegramSettings;
import '../../settings/code_settings.dart' show openCodeSettings;
import '../../settings/import_screen.dart' show openImportSettings;
import '../../settings/models/models_screen.dart' show openModelsSettings;
import '../../settings/safety_screen.dart' show openSafetySettings;
import '../../settings/system/backup_screen.dart' show openBackupSettings;
import '../../settings/system/remote_screen.dart' show openRemoteSettings;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import 'wizard_logic.dart';
import 'wizard_words.g.dart';

/// A word of the page's wizard, in the interface's language, with its {names} filled.
String wzWord(BuildContext context, String key, [Map<String, String> vars = const {}]) {
  final lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';
  var s = wizardWords[lang]![key] ?? wizardWords['en']![key] ?? key;
  vars.forEach((k, v) => s = s.replaceAll('{$k}', v));
  return s;
}

/// «Redo the setup» from Settings, or the rest of the first start ([start]: the step to open).
Future<void> openSetupWizard(BuildContext context, {String? start}) => Navigator.of(context).push(
  MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => SetupWizardScreen(start: start)),
);

extension WizardApi on RedGiantClient {
  /// `PUT /api/setup/mode`.
  Future<void> setupMode(String mode) => callJson('PUT', '/api/setup/mode', {'mode': mode});
}

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key, this.start});

  final String? start;

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

/// What a step says when «Next» is pressed: false keeps the person there.
typedef _Save = Future<bool> Function();

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  late final AppController app = AppScope.read(context);
  Map<String, dynamic>? _s;
  bool _hadPassword = false;
  String _key = 'wzWelcome';
  bool _busy = false;
  String? _error;
  _Save? _save;

  RedGiantClient? get _c => app.client;

  /// Signed in with a setup code and no password yet: the password step stays (the page's rule).
  bool get _must => app.viaSetupCode && !_hadPassword;

  @override
  void initState() {
    super.initState();
    if (widget.start != null) _key = widget.start!;
    unawaited(_load(first: true));
  }

  Future<void> _load({bool first = false}) async {
    final c = _c;
    if (c == null) return;
    try {
      final s = await c.setupState();
      // A password chosen before the wizard: its step is not asked again (read once).
      if (first) _hadPassword = (await c.loginMethods()).password;
      if (mounted) setState(() => _s = s);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  List<String> get _steps {
    final s = _s ?? const {};
    final config = (s['config'] as Map?) ?? const {};
    final offer = s['offer'] as Map?;
    return stepsFor(
      config['mode'] as String?,
      role: config['role'] as String?,
      local: offer == null ? null : offer['local'] == true,
      password: _hadPassword,
    );
  }

  Future<void> _move(String to, {required bool save}) async {
    if (_busy) return;
    if (save && _save != null) {
      setState(() {
        _busy = true;
        _error = null;
      });
      bool ok;
      try {
        ok = await _save!();
      } on ApiException catch (e) {
        ok = false;
        if (mounted) setState(() => _error = e.message);
      }
      if (!mounted) return;
      setState(() => _busy = false);
      if (!ok) return;
    }
    // The settings come back first: choosing «Advanced» adds a step after this one.
    await _load();
    if (!mounted) return;
    final list = _steps;
    setState(() {
      _save = null;
      _error = null;
      _key = to == 'next' ? stepAfter(list, _key) : to;
    });
  }

  Future<void> _finish() async {
    final c = _c;
    if (c == null || _busy) return;
    setState(() => _busy = true);
    try {
      await c.setupComplete();
      if (mounted) Navigator.of(context).pop();
      unawaited(app.refresh());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _jump() async {
    final steps = _steps;
    final at = steps.indexOf(_key);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final c = RgColors.of(ctx);
        return SafeArea(
          child: ListView(
            key: const Key('wz-jump'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                wzWord(ctx, 'wzAllSteps'),
                style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(wzWord(ctx, 'wzAllStepsLead'), style: TextStyle(color: c.dim)),
              ),
              for (final (i, k) in steps.indexed)
                ListTile(
                  key: Key('wz-jump-$k'),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: i == at ? c.accent : (i < at ? c.accentSoft : c.panel2),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: i == at ? Colors.white : c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(_stepName(ctx, k)),
                  trailing: Text(
                    i == at ? wzWord(ctx, 'wzHere') : (i < at ? wzWord(ctx, 'wzSeen') : ''),
                    style: TextStyle(color: c.dim, fontSize: 12),
                  ),
                  onTap: () => Navigator.of(ctx).pop(k),
                ),
            ],
          ),
        );
      },
    );
    if (picked != null) await _move(picked, save: true);
  }

  String _stepName(BuildContext context, String k) => wzWord(context, k);

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final s = _s;
    final steps = _steps;
    final at = steps.indexOf(_key).clamp(0, steps.length - 1);
    final phone = MediaQuery.sizeOf(context).width < 700;
    final label = at == 0
        ? wzWord(context, 'wzStart')
        : _key == 'wzDone'
        ? wzWord(context, 'wzFinish')
        : wzWord(context, 'wzNext');
    return Scaffold(
      key: const Key('wz'),
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              key: const Key('wz-progress'),
              value: (at + 1) / steps.length,
              minHeight: 3,
              backgroundColor: c.line,
              color: c.accent,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('wz-close'),
                    tooltip: l.close,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: RgIcon(RgIcons.x, color: c.text),
                  ),
                  const Spacer(),
                  InkWell(
                    key: const Key('wz-counter'),
                    borderRadius: BorderRadius.circular(20),
                    onTap: s == null ? null : () => unawaited(_jump()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.line),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          Text(
                            wzWord(context, 'wzNofN', {'n': '${at + 1}', 'of': '${steps.length}'}),
                            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                          ),
                          if (!phone)
                            Text(_stepName(context, _key), style: TextStyle(color: c.dim)),
                          RgIcon(
                            phone ? RgIcons.list : RgIcons.chevronDown,
                            size: 16,
                            color: c.dim,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: s == null
                  ? Center(child: RgSpinner(color: c.dim))
                  : Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: ListView(
                          key: Key('wz-step-$_key'),
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                          children: [_step(context, s)],
                        ),
                      ),
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _error!,
                  key: const Key('wz-error'),
                  style: TextStyle(color: c.err),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  // On a phone «Back» is its arrow only, as the page's bar.
                  if (at > 0 && phone)
                    IconButton(
                      key: const Key('wz-back'),
                      tooltip: wzWord(context, 'wzBack'),
                      onPressed: _busy ? null : () => unawaited(_move(steps[at - 1], save: false)),
                      icon: RgIcon(RgIcons.chevronLeft, size: 22, color: c.text),
                    )
                  else if (at > 0)
                    TextButton.icon(
                      key: const Key('wz-back'),
                      onPressed: _busy ? null : () => unawaited(_move(steps[at - 1], save: false)),
                      icon: RgIcon(RgIcons.chevronLeft, size: 18, color: c.text),
                      label: Text(wzWord(context, 'wzBack'), style: TextStyle(color: c.text)),
                    ),
                  const Spacer(),
                  if (skippable(_key, mustSetPassword: _must) && _key != 'wzDone')
                    TextButton(
                      key: const Key('wz-skip'),
                      onPressed: _busy ? null : () => unawaited(_move('next', save: false)),
                      child: Text(wzWord(context, 'wzSkip'), style: TextStyle(color: c.dim)),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    flex: 4,
                    child: FilledButton.icon(
                      key: const Key('wz-next'),
                      onPressed: _busy || s == null
                          ? null
                          : () =>
                                unawaited(_key == 'wzDone' ? _finish() : _move('next', save: true)),
                      icon: const RgIcon(RgIcons.arrowRight, size: 18, color: Colors.white),
                      label: Text(
                        _busy ? wzWord(context, 'wzSaving') : label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- the steps ----

  Widget _step(BuildContext context, Map<String, dynamic> s) {
    final l = AppLocalizations.of(context);
    String w(String k, [Map<String, String> v = const {}]) => wzWord(context, k, v);
    final config = (s['config'] as Map?) ?? const {};
    switch (_key) {
      case 'wzWelcome':
        return _WelcomeStep(register: (f) => _save = f);
      case 'wzRole':
        return _PickStep(
          title: w('fbRoleQ'),
          lead: w('fbRoleLead'),
          value: (config['role'] as String?) ?? 'full',
          options: [
            ('full', l.g7WzRoleFull, l.g7WzRoleFullText),
            ('node', l.g7WzRoleNode, l.g7WzRoleNodeText),
          ],
          register: (f) => _save = f,
          save: (v) async {
            if (v != (config['role'] ?? 'full')) await _c!.setupRole(v, confirm: true);
            return true;
          },
        );
      case 'wzAccount':
        return _AccountStep(register: (f) => _save = f, must: _must);
      case 'wzMachine':
        return _MachineStep(s: s);
      case 'wzMode':
        return _PickStep(
          title: w('wzModeQ'),
          lead: w('wzModeLead'),
          value: (config['mode'] as String?) ?? 'standard',
          options: [
            ('standard', w('modeStandard'), w('wzModeStdText')),
            ('advanced', w('modeAdvanced'), w('wzModeAdvText')),
          ],
          register: (f) => _save = f,
          save: (v) async {
            if (v != (config['mode'] ?? 'standard')) await _c!.setupMode(v);
            return true;
          },
        );
      case 'wzBrain':
        final ways = waysInUse(s);
        return _OpenStep(
          title: w('wzBrainQ'),
          lead: w('wzBrainLead'),
          facts: [
            ways.isEmpty ? l.g7WzNoWay : l.g7WzWays(ways.map((x) => _wayName(l, x)).join(', ')),
          ],
          action: l.g7WzOpenModels,
          open: () => openModelsSettings(context),
          after: _load,
        );
      case 'wzLocal':
        final engine = config['engine'] as Map?;
        return _OpenStep(
          title: w('wzLocalQ'),
          lead: w('wzLocalLead'),
          facts: [engine == null ? l.g7WzNoLocal : l.g7WzLocal('${engine['model'] ?? ''}')],
          action: l.g7WzOpenLocal,
          open: () => openModelsSettings(context),
          after: _load,
        );
      case 'wzNames':
        final names = (s['names'] as Map?) ?? const {};
        return _NamesStep(
          god: '${names['god'] ?? 'God'}',
          demigod: '${names['demigod'] ?? 'Demi-God'}',
          register: (f) => _save = f,
        );
      case 'wzAssign':
        return _OpenStep(
          title: w('wzAssign'),
          lead: l.g7WzAssignLead,
          facts: const [],
          action: l.g7WzOpenAssign,
          open: () => openModelsSettings(context),
          after: _load,
        );
      case 'wzImport':
        return _OpenStep(
          title: w('impQ'),
          lead: w('impLead'),
          facts: const [],
          action: l.g7ImpOpen,
          open: () => openImportSettings(context),
          after: _load,
        );
      case 'wzTelegram':
        return _OpenStep(
          title: w('wzTelegram'),
          lead: l.g7WzTelegramLead,
          facts: const [],
          action: l.g7WzOpenTelegram,
          open: () => openTelegramSettings(context),
          after: _load,
        );
      case 'wzStorage':
        return _OpenStep(
          title: w('fbStorageQ'),
          lead: w('fbStorageLead'),
          facts: const [],
          action: l.g7WzOpenBackups,
          open: () => openBackupSettings(context),
          after: _load,
        );
      case 'wzCode':
        return _OpenStep(
          title: w('wzCodeQ'),
          lead: w('wzCodeLead'),
          facts: const [],
          action: l.g7WzOpenCode,
          open: () => openCodeSettings(context),
          after: _load,
        );
      case 'wzRemote':
        return _OpenStep(
          title: w('wzRemoteQ'),
          lead: w('fbRemoteLead'),
          facts: const [],
          action: l.g7WzOpenRemote,
          open: () => openRemoteSettings(context),
          after: _load,
        );
      case 'wzSafety':
        final policy = (s['policy'] as Map?) ?? const {};
        final human = [for (final x in (policy['humanOnly'] as List? ?? const [])) '$x'];
        return _PickStep(
          title: w('wzSafety'),
          lead: w('wzSafetyLead'),
          value: presetOf(human) ?? '',
          options: [
            for (final p in presets.keys)
              (p, w('wzPreset_$p'), l.g7WzPresetText('${presets[p]!.length}')),
          ],
          register: (f) => _save = f,
          save: (v) async {
            if (v.isNotEmpty && v != presetOf(human)) {
              await _c!.setSafety({'humanOnly': presets[v]});
            }
            return true;
          },
          extra: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: OutlinedButton.icon(
              key: const Key('wz-safety-more'),
              onPressed: () async {
                await openSafetySettings(context);
                await _load();
              },
              icon: RgIcon(RgIcons.shield, size: 16, color: RgColors.of(context).text),
              label: Text(l.g7WzSafetyMore),
            ),
          ),
        );
      default:
        return _DoneStep(s: s, go: (k) => unawaited(_move(k, save: false)));
    }
  }

  static String _wayName(AppLocalizations l, String way) => switch (way) {
    'claude' => 'Claude',
    'chatgpt' => 'ChatGPT',
    'keys' => l.g7WzWayKeys,
    'local' => l.g7WzWayLocal,
    _ => l.g7WzWayServer,
  };
}

/// A step's big question and its lead.
class _Head extends StatelessWidget {
  const _Head(this.q, this.lead);

  final String q;
  final String lead;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            q,
            key: const Key('wz-q'),
            style: TextStyle(color: c.text, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
          ),
          Text(lead, style: TextStyle(color: c.dim, fontSize: 15, height: 1.4)),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatefulWidget {
  const _WelcomeStep({required this.register});

  final void Function(_Save) register;

  @override
  State<_WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<_WelcomeStep> {
  late final AppController app = AppScope.read(context);
  late String _lang = Localizations.localeOf(context).languageCode == 'it' ? 'it' : 'en';

  @override
  Widget build(BuildContext context) {
    widget.register(() async {
      await app.client!.setupLanguages(language: _lang);
      return true;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(wzWord(context, 'wzHello'), wzWord(context, 'wzHelloLead')),
        SettingsCard(
          children: [
            for (final (code, word) in [('it', 'wzLangIt'), ('en', 'wzLangEn')])
              PickRow(
                key: Key('wz-lang-$code'),
                title: wzWord(context, word),
                selected: _lang == code,
                onTap: () {
                  setState(() => _lang = code);
                  app.setLocale(Locale(code));
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _PickStep extends StatefulWidget {
  const _PickStep({
    required this.title,
    required this.lead,
    required this.value,
    required this.options,
    required this.register,
    required this.save,
    this.extra,
  });

  final String title;
  final String lead;
  final String value;
  final List<(String, String, String)> options;
  final void Function(_Save) register;
  final Future<bool> Function(String) save;
  final Widget? extra;

  @override
  State<_PickStep> createState() => _PickStepState();
}

class _PickStepState extends State<_PickStep> {
  late String _v = widget.value;

  @override
  Widget build(BuildContext context) {
    widget.register(() => widget.save(_v));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(widget.title, widget.lead),
        SettingsCard(
          children: [
            for (final (id, title, text) in widget.options)
              PickRow(
                key: Key('wz-pick-$id'),
                title: title,
                subtitle: text,
                selected: _v == id,
                onTap: () => setState(() => _v = id),
              ),
          ],
        ),
        ?widget.extra,
      ],
    );
  }
}

class _AccountStep extends StatefulWidget {
  const _AccountStep({required this.register, this.must = false});

  final void Function(_Save) register;
  final bool must;

  @override
  State<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<_AccountStep> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _problem;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final app = AppScope.read(context);
    widget.register(() async {
      final p = passwordProblem(_a.text, _b.text, needed: widget.must);
      if (p != null) {
        setState(() => _problem = wzWord(context, p));
        return false;
      }
      if (_a.text.isEmpty) return true;
      await app.client!.setPassword(_a.text);
      return true;
    });
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _Head(wzWord(context, 'fbAccountQ'), wzWord(context, 'fbAccountLead')),
        TextField(
          key: const Key('wz-password'),
          controller: _a,
          obscureText: true,
          decoration: InputDecoration(labelText: l.g7WzPassword),
          onChanged: (_) => setState(() => _problem = null),
        ),
        TextField(
          key: const Key('wz-password-again'),
          controller: _b,
          obscureText: true,
          decoration: InputDecoration(labelText: l.g7WzPasswordAgain),
          onChanged: (_) => setState(() => _problem = null),
        ),
        if (_problem != null)
          Text(
            _problem!,
            key: const Key('wz-password-problem'),
            style: TextStyle(color: c.err),
          ),
      ],
    );
  }
}

class _MachineStep extends StatelessWidget {
  const _MachineStep({required this.s});

  final Map<String, dynamic> s;

  @override
  Widget build(BuildContext context) {
    final hw = (s['hardware'] as Map?) ?? const {};
    final gpus = [
      for (final g in (hw['gpus'] as List? ?? const []))
        if (g is Map) '${g['name'] ?? g['model'] ?? ''}'.trim(),
    ].where((x) => x.isNotEmpty).toList();
    String w(String k) => wzWord(context, k);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(w('fbMachineQ'), w('fbMachineLead')),
        SettingsCard(
          key: const Key('wz-machine'),
          children: [
            if (hw['cpu'] != null)
              NoteLine(
                icon: RgIcons.cpu,
                strong: true,
                text:
                    '${w('wzCpu')}: ${hw['cpu']}${hw['cores'] != null ? ' · ${hw['cores']}' : ''}',
              ),
            if (hw['ramGb'] != null)
              NoteLine(icon: RgIcons.database, text: '${w('wzMemory')}: ${hw['ramGb']} GB'),
            NoteLine(
              icon: RgIcons.monitor,
              text: gpus.isEmpty ? w('wzNoGpu') : '${w('wzGpu')}: ${gpus.join(', ')}',
            ),
            if (hw['diskFreeGb'] != null)
              NoteLine(
                icon: RgIcons.box,
                text: AppLocalizations.of(context).g7WzDiskFree('${hw['diskFreeGb']}'),
              ),
          ],
        ),
      ],
    );
  }
}

class _OpenStep extends StatelessWidget {
  const _OpenStep({
    required this.title,
    required this.lead,
    required this.facts,
    required this.action,
    required this.open,
    required this.after,
  });

  final String title;
  final String lead;
  final List<String> facts;
  final String action;
  final Future<void> Function() open;
  final Future<void> Function() after;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _Head(title, lead),
        if (facts.isNotEmpty)
          SettingsCard(
            children: [for (final f in facts) NoteLine(icon: RgIcons.check, strong: true, text: f)],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            key: const Key('wz-open'),
            onPressed: () async {
              await open();
              await after();
            },
            icon: RgIcon(RgIcons.chevronRight, size: 18, color: c.text),
            label: Text(action),
          ),
        ),
      ],
    );
  }
}

class _NamesStep extends StatefulWidget {
  const _NamesStep({required this.god, required this.demigod, required this.register});

  final String god;
  final String demigod;
  final void Function(_Save) register;

  @override
  State<_NamesStep> createState() => _NamesStepState();
}

class _NamesStepState extends State<_NamesStep> {
  late final _god = TextEditingController(text: widget.god);
  late final _demi = TextEditingController(text: widget.demigod);

  @override
  void dispose() {
    _god.dispose();
    _demi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.read(context);
    widget.register(() async {
      await app.client!.setupNames(
        god: _god.text.trim().isEmpty ? 'God' : _god.text.trim(),
        demigod: _demi.text.trim().isEmpty ? 'Demi-God' : _demi.text.trim(),
      );
      return true;
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _Head(wzWord(context, 'wzNamesQ'), wzWord(context, 'wzNamesLead')),
        TextField(
          key: const Key('wz-god'),
          controller: _god,
          maxLength: 40,
          decoration: InputDecoration(labelText: wzWord(context, 'wzGodRole')),
        ),
        TextField(
          key: const Key('wz-demigod'),
          controller: _demi,
          maxLength: 40,
          decoration: InputDecoration(labelText: wzWord(context, 'wzDemiRole')),
        ),
      ],
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.s, required this.go});

  final Map<String, dynamic> s;
  final void Function(String) go;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final names = (s['names'] as Map?) ?? const {};
    final policy = (s['policy'] as Map?) ?? const {};
    final human = [for (final x in (policy['humanOnly'] as List? ?? const [])) '$x'];
    final preset = presetOf(human);
    final ways = waysInUse(s);
    final rows = <(String, RgIcons, String, String)>[
      (
        'wzBrain',
        RgIcons.spark,
        wzWord(context, 'wzBrain'),
        ways.isEmpty
            ? l.g7WzNoWay
            : l.g7WzWays(ways.map((x) => _SetupWizardScreenState._wayName(l, x)).join(', ')),
      ),
      (
        'wzNames',
        RgIcons.users,
        wzWord(context, 'wzNames'),
        '${names['god'] ?? 'God'} · ${names['demigod'] ?? 'Demi-God'}',
      ),
      (
        'wzSafety',
        RgIcons.shield,
        wzWord(context, 'wzSafety'),
        preset == null ? l.g7WzCustom : wzWord(context, 'wzPreset_$preset'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Center(child: RgIcon(RgIcons.check, size: 56, color: c.ok)),
        _Head(wzWord(context, 'wzDoneQ'), wzWord(context, 'wzDoneLead')),
        SettingsCard(
          key: const Key('wz-recap'),
          children: [
            for (final (step, icon, label, value) in rows)
              ListTile(
                key: Key('wz-recap-$step'),
                leading: RgIcon(icon, color: c.accent),
                title: Text(label),
                subtitle: Text(value),
                trailing: Text(wzWord(context, 'wzChange'), style: TextStyle(color: c.accent)),
                onTap: () => go(step),
              ),
          ],
        ),
        Text(wzWord(context, 'wzRunAgainSettings'), style: TextStyle(color: c.dim, fontSize: 13)),
      ],
    );
  }
}
