// Settings › Commands (G42.4, native; the page's `CommandLimits.tsx`, G36.16, and its
// `AtWorkCard`, 3.8.10): one page for the person's limits. On top «Agents at work together, at
// most» (`maxAtWork`, saved at once, undoable) with the line as it is now; then the background
// commands (how many at once, how long, how big their log), the ordinary commands' longest wait
// and the steps of one turn, each a row of drawn chips with «No limit» and its plain warning
// (never a block), saved together with «Save» (`PUT /api/settings/commands`, the whole settings
// again), undoable, with «Back to the defaults».
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/turn_queue_view.dart';
import 'api/rules_api.dart';
import 'rules_kit.dart';

Future<void> openCommandsSettings(BuildContext context) =>
    openRulesPage(context, (panel) => CommandsScreen(panel: panel));

/// The ready choices of agents at work together (null: no limit).
const atWorkChoices = <int?>[null, 1, 2, 3, 4, 6, 8, 12, 20];

/// The limit in words, for the row that opens this page.
String atWorkSummary(AppLocalizations l, int? limit) =>
    limit == null ? l.atWorkNoLimit : l.atWorkSummary(limit);

const _minute = 60000;
const _hour = 60 * _minute;
const _mb = 1024 * 1024;

/// The ready values, and the saved one too when it is not among them (the page's `options`).
List<int?> _with(List<int?> ready, int? now) => ready.contains(now) ? ready : [...ready, now];

class CommandsScreen extends StatefulWidget {
  const CommandsScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  /// What the server has now, and what the person is changing.
  Map<String, dynamic>? _server;
  Map<String, dynamic>? _s;
  Map<String, dynamic>? _defaults;
  int _serverTurns = 200;
  String? _change;
  bool _undone = false;
  bool _saving = false;
  String? _error;
  String? _atWorkChange;
  bool _atWorkUndone = false;
  String? _atWorkError;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final app = AppScope.read(context);
    final c = app.client;
    if (c == null) return;
    unawaited(app.refreshTurns());
    try {
      final r = await c.commandLimits();
      if (!mounted) return;
      final s = {...(r['settings'] as Map<String, dynamic>? ?? const {})};
      setState(() {
        _server = s;
        _s = {...s};
        _defaults = r['defaults'] is Map<String, dynamic>
            ? r['defaults'] as Map<String, dynamic>
            : null;
        _serverTurns = (r['serverMaxTurns'] as num?)?.toInt() ?? 200;
        _error = null;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  int? _int(String k) => (_s?[k] as num?)?.toInt();

  void _set(String k, Object? v) => setState(() {
    _s = {...?_s, k: v};
    _change = null;
    _undone = false;
  });

  Future<void> _save(Map<String, dynamic> v) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    // The agents at work keep what is saved: this button saves the other limits.
    final next = {...v, 'maxAtWork': _server?['maxAtWork']};
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await c.saveCommandLimits(next);
      if (mounted) {
        setState(() {
          _server = {...next};
          _s = {...next};
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
      await _load();
      if (mounted) setState(() => _undone = true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  /// Agents at work together: saved at once, with the limits as they are on the server.
  Future<void> _pickAtWork(int? v) async {
    final c = AppScope.read(context).client;
    final server = _server;
    if (c == null || server == null || v == (server['maxAtWork'] as num?)?.toInt()) return;
    final next = {...server, 'maxAtWork': v};
    setState(() {
      _server = next;
      _s = {...?_s, 'maxAtWork': v};
      _atWorkChange = null;
      _atWorkUndone = false;
      _atWorkError = null;
    });
    try {
      final id = await c.saveCommandLimits(next);
      if (mounted) setState(() => _atWorkChange = id ?? '');
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _server = server;
          _s = {...?_s, 'maxAtWork': server['maxAtWork']};
          _atWorkError = AppLocalizations.of(context).errGeneric(rulesWhy(e));
        });
      }
    }
  }

  Future<void> _undoAtWork() async {
    final c = AppScope.read(context).client;
    final id = _atWorkChange;
    if (c == null || id == null || id.isEmpty) return;
    try {
      await c.undoChange(id);
      await _load();
      if (mounted) setState(() => _atWorkUndone = true);
    } on Exception catch (e) {
      if (mounted) setState(() => _atWorkError = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = _s;
    if (s == null) {
      return RulesPage(
        pageKey: const Key('commands-settings'),
        title: l.g4CmSection,
        question: l.g4CmPageQ,
        lead: l.g4CmPageLead,
        panel: widget.panel,
        children: [RulesLoading(error: _error)],
      );
    }
    String mb(int v) => v >= 1024 * _mb ? '1 GB' : '${(v / _mb).round()} MB';
    final atWork = (_server?['maxAtWork'] as num?)?.toInt();
    final perSession = _int('maxPerSession');
    final maxMs = _int('maxMs');
    final log = _int('maxLogBytes');
    final bash = _int('bashMaxMs') ?? 10 * _minute;
    final turnsSet = s.containsKey('maxTurns');
    final turns = _int('maxTurns');
    return RulesPage(
      pageKey: const Key('commands-settings'),
      title: l.g4CmSection,
      question: l.g4CmPageQ,
      lead: l.g4CmPageLead,
      panel: widget.panel,
      children: [
        // ---- agents at work together (3.8.10) ----
        RuleCard(
          key: const Key('at-work'),
          icon: RgIcons.users,
          title: l.atWorkAtMost,
          question: l.atWorkHelp,
          children: [
            RgChoice<int?>(
              options: [
                for (final v in _with(atWorkChoices, atWork))
                  (v, v == null ? l.atWorkNoLimit : '$v'),
              ],
              value: atWork,
              keyOf: (v) => 'at-work-${v ?? 'none'}',
              onChanged: _pickAtWork,
            ),
            RuleSay(atWork == null ? l.atWorkNoLimitHint : atWorkSummary(l, atWork)),
            if (_atWorkError != null) ...[const SizedBox(height: 8), RuleWarn(_atWorkError!)],
            if (_atWorkUndone)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.g4CmUndone, style: TextStyle(color: c.ok, fontSize: 13)),
              )
            else if (_atWorkChange != null)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.atWorkSaved, style: TextStyle(color: c.ok, fontSize: 13)),
                  if (_atWorkChange!.isNotEmpty)
                    TextButton(
                      key: const Key('at-work-undo'),
                      onPressed: _undoAtWork,
                      child: Text(l.g4CmUndo),
                    ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Text(
                l.atWorkNow,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14),
              ),
            ),
            const TurnQueueList(),
          ],
        ),
        // ---- background commands ----
        RulesSub(title: l.g4CmBgTitle, lead: l.g4CmBgLead, icon: RgIcons.terminal),
        RuleCard(
          key: const Key('cm-bg'),
          icon: RgIcons.activity,
          title: l.g4CmBgTitle,
          children: [
            RuleRow(
              title: l.g4CmAtOnce,
              help: l.g4CmAtOnceHelp,
              child: RgChoice<int?>(
                options: [
                  for (final v in _with([2, 4, 8, 16, null], perSession))
                    (v, v == null ? l.g4CmNoLimit : '$v'),
                ],
                value: perSession,
                keyOf: (v) => 'cm-at-once-${v ?? 'none'}',
                onChanged: (v) => _set('maxPerSession', v),
              ),
            ),
            if (perSession == null) RuleWarn(l.g4CmAtOnceWarn),
            RuleRow(
              title: l.g4CmLong,
              help: l.g4CmLongHelp,
              child: RgChoice<int?>(
                options: [
                  for (final v in _with([
                    10 * _minute,
                    _hour,
                    6 * _hour,
                    24 * _hour,
                    7 * 24 * _hour,
                    null,
                  ], maxMs))
                    (v, v == null ? l.g4CmNoLimit : spanWords(l, v)),
                ],
                value: maxMs,
                keyOf: (v) => 'cm-long-${v ?? 'none'}',
                onChanged: (v) => _set('maxMs', v),
              ),
            ),
            if (maxMs == null) RuleWarn(l.g4CmLongWarn),
            RuleRow(
              title: l.g4CmLog,
              help: l.g4CmLogHelp,
              child: RgChoice<int?>(
                options: [
                  for (final v in _with([_mb, 8 * _mb, 64 * _mb, 512 * _mb, null], log))
                    (v, v == null ? l.g4CmNoLimit : mb(v)),
                ],
                value: log,
                keyOf: (v) => 'cm-log-${v ?? 'none'}',
                onChanged: (v) => _set('maxLogBytes', v),
              ),
            ),
            if (log == null) RuleWarn(l.g4CmLogWarn),
          ],
        ),
        // ---- ordinary commands ----
        RulesSub(title: l.g4CmBashTitle, lead: l.g4CmBashLead, icon: RgIcons.clock),
        RuleCard(
          key: const Key('cm-bash'),
          icon: RgIcons.terminal,
          title: l.g4CmBash,
          question: l.g4CmBashHelp,
          children: [
            RgChoice<int>(
              options: [
                for (final v in _with([
                  2 * _minute,
                  10 * _minute,
                  30 * _minute,
                  _hour,
                  2 * _hour,
                ], bash))
                  (v!, spanWords(l, v)),
              ],
              value: bash,
              keyOf: (v) => 'cm-bash-$v',
              onChanged: (v) => _set('bashMaxMs', v),
            ),
          ],
        ),
        // ---- steps in one turn ----
        RulesSub(title: l.g4CmStepsTitle, lead: l.g4CmStepsLead, icon: RgIcons.layers),
        RuleCard(
          key: const Key('cm-steps'),
          icon: RgIcons.refresh,
          title: l.g4CmSteps,
          question: l.g4CmStepsHelp('$_serverTurns'),
          children: [
            RgChoice<String>(
              options: [
                ('default', l.g4CmStepsDefault),
                for (final v in _with([25, 100, 200, 500, null], turnsSet ? turns : 25))
                  (v == null ? 'none' : '$v', v == null ? l.g4CmNoLimit : '$v'),
              ],
              value: !turnsSet ? 'default' : (turns == null ? 'none' : '$turns'),
              keyOf: (v) => 'cm-steps-$v',
              onChanged: (v) => setState(() {
                final next = {...s}..remove('maxTurns');
                if (v != 'default') next['maxTurns'] = v == 'none' ? null : int.parse(v);
                _s = next;
                _change = null;
                _undone = false;
              }),
            ),
            if (turnsSet && turns == null) ...[
              const SizedBox(height: 10),
              RuleWarn(l.g4CmStepsWarn),
            ],
          ],
        ),
        RuleSaveRow(
          onSave: () => _save(s),
          saving: _saving,
          saved: _change == null ? null : l.g4CmSaved,
          undone: _undone,
          onUndo: (_change?.isNotEmpty ?? false) ? _undo : null,
          error: _error,
          extra: _defaults == null
              ? null
              : OutlinedButton(
                  key: const Key('cm-defaults'),
                  onPressed: _saving ? null : () => _save({..._defaults!}),
                  child: Text(l.g4CmDefaults),
                ),
        ),
      ],
    );
  }
}
