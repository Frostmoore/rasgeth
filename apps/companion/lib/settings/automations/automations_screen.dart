// G42.9: Settings › Automations, native, as the page's Automations.tsx (G24.8, drawn as the wizard
// on 2026-11-06): big squares to make one (an automation, a reminder, or a magic one built with
// God, G33.3), the magic ones still being built, the automations as squares lit when switched
// on, each opening a window (a sheet from below on a phone) with its switch, its webhook and the
// secret shown only once, its runs, and the buttons to run it now, change it or delete it. Making
// and changing happen in the editor (automation_editor.dart). The mailboxes they read sit under
// «Sources», added and changed there as on the page (G42.13, channels/mailboxes.dart). The list
// is read again whenever the server says an automation changed (`automations.changed`).
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/conversation.dart' show Project;
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/conversation_screen.dart';
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../../ui/markdown.dart';
import '../api/automations_api.dart';
import '../channels/mailboxes.dart';
import '../rules_kit.dart';
import 'automation_draft.dart';
import 'automation_editor.dart';
import 'automation_kit.dart';
import 'automation_types.dart';
import 'magic_automation.dart';
import 'time_zone.dart';

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openAutomationsSettings(BuildContext context) =>
    openRulesPage(context, (panel) => AutomationsScreen(panel: panel));

const _statuses = ['running', 'ok', 'failed', 'timeout', 'skipped'];
const _triggers = ['cron', 'webhook', 'manual', 'missed'];
const _moreTriggers = ['email', 'message', 'files', 'after', 'task', 'startup', 'retry'];

String _nth(String list, int i, String or) {
  final p = list.split(',');
  return i >= 0 && i < p.length ? p[i] : or;
}

/// A run's state in words (the page's `statusLabel`).
String runStatusLabel(AppLocalizations l, String s) =>
    s == 'queued' ? l.auAxRunQueued : _nth(l.auRunStatus, _statuses.indexOf(s), s);

/// Why a run started, in words (the page's `triggerLabel`).
String runTriggerLabel(AppLocalizations l, String s) => _triggers.contains(s)
    ? _nth(l.auRunTriggers, _triggers.indexOf(s), s)
    : _nth(l.auAxRunTriggers, _moreTriggers.indexOf(s), s);

/// Whether a run's message reached the person, in words.
String deliveryText(AppLocalizations l, RunDelivery d) {
  if (d.status == 'delivered') {
    final to = d.to.where((x) => x != 'chats').join(', ');
    return to.isNotEmpty ? l.auDeliveryDeliveredTo(to) : l.auDeliveryDelivered;
  }
  if (d.status == 'no-chat') return l.auDeliveryNoChat;
  return l.auDeliveryFailed(d.reason ?? '');
}

/// When an automation runs, in words (a date for reminders), as the page's `recipeWhen`.
String recipeWhen(AppLocalizations l, Automation a, List<WhoOption> who, List<Project> projects) {
  final on = a.on;
  if (on['at'] is String) return l.auWhenAt(dateTimeWords(l, on['at'] as String));
  if (a.error != null) return whenWords(l, fromOn(on, a.project));
  return sentence(l, fromRecipe(a.recipe, who, projects), who).firstOrNull ?? '';
}

/// The drawn icon of an automation, by what starts it.
RgIcons automationIcon(Automation a) {
  final on = a.on;
  if (on['at'] != null) return RgIcons.bell;
  if (on['email'] != null) return RgIcons.send;
  if (on['message'] != null) return RgIcons.chat;
  if (on['files'] != null) return RgIcons.folder;
  if (on['after'] != null) return RgIcons.layers;
  if (on['task'] != null) return RgIcons.play;
  if (on['startup'] == true && on['cron'] == null) return RgIcons.zap;
  if (on['events'] != null && on['cron'] == null) return RgIcons.git;
  if (on['webhook'] == true && on['cron'] == null) return RgIcons.globe;
  return RgIcons.clock;
}

/// The agent a recipe talks to, as the server resolves it (for opening its conversations).
Agent? agentOfRecipe(Automation a, List<Agent> agents) {
  final want = a.agent.toLowerCase();
  final pool = agents.where((x) => a.project == null || x.projectId == a.project);
  if (want == 'god' || want == 'orchestrator') {
    return pool.where((x) => x.kind.name == want).firstOrNull;
  }
  return pool.where((x) => x.id == a.agent || x.name.toLowerCase() == want).firstOrNull;
}

/// Opens a run's (or a magic automation's) conversation over everything.
Future<void> openRunConversation(BuildContext context, String sessionId, Agent? agent) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(sessionId: sessionId, agent: agent),
      ),
    );

String _why(AppLocalizations l, Object e) => l.errGeneric(e is ApiException ? e.message : '$e');

/// One automation's window, then (when asked) its editor and its window again with what was
/// saved; [onChanged] after every change. Settings › Automations and an assistant's routines.
Future<void> openAutomation(
  BuildContext context,
  Automation a, {
  String? secret,
  required VoidCallback onChanged,
}) async {
  var current = a;
  String? shown = secret;
  while (true) {
    if (!context.mounted) return;
    final next = await openAutoWindow<ViewNext>(
      context,
      title: current.title,
      wide: true,
      key: const Key('au-view'),
      child: (ctx, close) =>
          AutomationView(automation: current, secret: shown, onClose: close, onChanged: onChanged),
    );
    if (next != ViewNext.edit || !context.mounted) return;
    final s = await openAutomationEditor(context, current: current, title: current.title);
    if (s != null) {
      onChanged();
      current = s.automation;
      shown = s.webhookSecret;
    } else {
      shown = null;
    }
  }
}

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key, this.panel = false});

  final bool panel;

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  List<Automation>? _list;
  List<MagicAutomation> _magic = const [];
  String? _error;
  late final ValueNotifier<int> _changed = AppScope.read(context).live.automationsChanged;

  @override
  void initState() {
    super.initState();
    _changed.addListener(_load);
    unawaited(_load());
  }

  @override
  void dispose() {
    _changed.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final list = await c.automations();
      List<MagicAutomation> magic;
      try {
        magic = await c.magicAutomations();
      } on ApiException {
        magic = const [];
      }
      if (!mounted) return;
      setState(() {
        _list = list;
        _magic = magic;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _why(AppLocalizations.of(context), e));
    }
  }

  String _stateOf(AppLocalizations l, Automation a) => [
    a.enabled ? l.auEnabled : l.auDisabled,
    if (a.lastRun != null) runStatusLabel(l, a.lastRun!.status),
    if (a.nextRunAt != null) '${l.auNextRun} ${dateTimeWords(l, a.nextRunAt!)}',
  ].join(' · ');

  /// After a save: the list again, then the automation's window (with the secret shown once).
  Future<void> _saved(AutomationSaved s) async {
    await _load();
    if (!mounted) return;
    final a = _list?.where((x) => x.id == s.automation.id).firstOrNull ?? s.automation;
    await _openView(a, secret: s.webhookSecret);
  }

  Future<void> _openView(Automation a, {String? secret}) async {
    await openAutomation(context, a, secret: secret, onChanged: () => unawaited(_load()));
    if (mounted) await _load();
  }

  Future<void> _new() async {
    final s = await openAutomationEditor(
      context,
      title: AppLocalizations.of(context).auNewAutomation,
    );
    if (s != null) await _saved(s);
  }

  Future<void> _reminder() async {
    final l = AppLocalizations.of(context);
    final s = await openAutoWindow<AutomationSaved>(
      context,
      title: l.auNewReminder,
      key: const Key('au-reminder'),
      child: (ctx, close) => ReminderForm(onSaved: close, onCancel: close),
    );
    if (s != null) await _saved(s);
  }

  Future<void> _startMagic() async {
    final m = await openMagicStart(context);
    if (m == null || !mounted) return;
    setState(() => _magic = [m, ..._magic.where((x) => x.id != m.id)]);
    await _openMagic(m);
  }

  Future<void> _openMagic(MagicAutomation m) async {
    final s = await openMagicChat(context, m, onChange: () => unawaited(_load()));
    if (s != null) {
      await _saved(s);
    } else {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final who = whoOptions(l, app.agents);
    final list = _list;
    final building = _magic.where((m) => m.status == 'building' || m.status == 'ready').toList();
    return RulesPage(
      pageKey: const Key('automations-settings'),
      title: l.auAutomations,
      panel: widget.panel,
      question: l.auAwQ,
      lead: l.auAwLead,
      children: [
        _MagicCta(onTap: _startMagic),
        AutoGrid(
          children: [
            AutoTile(
              key: const Key('au-new'),
              icon: RgIcons.plus,
              title: l.auNewAutomation,
              text: l.auAwNewText,
              onTap: _new,
            ),
            AutoTile(
              key: const Key('au-new-reminder'),
              icon: RgIcons.clock,
              title: l.auNewReminder,
              text: l.auAwReminderText,
              onTap: _reminder,
            ),
          ],
        ),
        if (building.isNotEmpty) ...[
          RulesSub(title: l.auAxMagicListTitle, lead: l.auAxMagicListLead, icon: RgIcons.spark),
          AutoGrid(
            children: [
              for (final m in building)
                AutoTile(
                  key: Key('au-magic-${m.id}'),
                  icon: RgIcons.spark,
                  gold: true,
                  on: m.status == 'ready',
                  title: '${l.auAxMagic}: ${m.title}',
                  badge: m.status == 'ready' ? l.auAxMagicReadyBadge : null,
                  text: m.request,
                  state: magicStateLabel(l, m.status),
                  onTap: () => _openMagic(m),
                ),
            ],
          ),
        ],
        RulesSub(
          title: l.auAwListTitle,
          lead: list != null && list.isNotEmpty ? l.auAwListLead : null,
        ),
        if (_error != null) RulesLoading(error: _error),
        if (list == null && _error == null) const RulesLoading(),
        if (list != null && list.isEmpty)
          Text(
            l.auNoAutomations,
            key: const Key('au-empty'),
            style: TextStyle(color: c.dim, fontSize: 14),
          ),
        if (list != null && list.isNotEmpty)
          AutoGrid(
            children: [
              for (final a in list)
                AutoTile(
                  key: Key('au-row-${a.id}'),
                  icon: automationIcon(a),
                  on: a.enabled,
                  title: a.title,
                  badge: a.error != null ? l.auRecipeBroken : null,
                  text: recipeWhen(l, a, who, app.projects),
                  state: _stateOf(l, a),
                  onTap: () => _openView(a),
                ),
            ],
          ),
        RulesSub(title: l.auAwSourcesTitle, lead: l.auAwSourcesLead, icon: RgIcons.mail),
        // G42.13: the mailboxes, added and changed here as on the page.
        MailboxesSection(onChange: _load),
      ],
    );
  }
}

/// The magic button (G33.3): a look of its own, God builds the automation with you.
class _MagicCta extends StatelessWidget {
  const _MagicCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = godColor(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: godLine(context)),
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.6,
              colors: [Color.alphaBlend(god.withValues(alpha: .22), c.panel), c.panel],
              stops: const [0, .6],
            ),
          ),
          child: InkWell(
            key: const Key('au-magic'),
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  const GodOrb(size: 56),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.auAxMagic,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.auAxMagicTile,
                          style: TextStyle(color: c.dim, fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the automation's window asks the list to do when it closes.
enum ViewNext { edit, deleted }

/// One automation's window: its switch, its webhook, its runs; run it, change it or delete it.
class AutomationView extends StatefulWidget {
  const AutomationView({
    super.key,
    required this.automation,
    this.secret,
    required this.onClose,
    required this.onChanged,
  });

  final Automation automation;

  /// The webhook's secret just made (shown only this once).
  final String? secret;
  final void Function([ViewNext?]) onClose;
  final VoidCallback onChanged;

  @override
  State<AutomationView> createState() => _AutomationViewState();
}

class _AutomationViewState extends State<AutomationView> {
  late Automation _a = widget.automation;
  late String? _secret = widget.secret;
  List<AutomationRun>? _runs;
  bool _started = false;
  bool _busy = false;
  String? _error;
  late final ValueNotifier<int> _changed = AppScope.read(context).live.automationsChanged;

  @override
  void initState() {
    super.initState();
    _changed.addListener(_reload);
    unawaited(_reload());
  }

  @override
  void dispose() {
    _changed.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final runs = await c.automationRuns(_a.id);
      final all = await c.automations();
      if (!mounted) return;
      setState(() {
        _runs = runs;
        _a = all.where((x) => x.id == _a.id).firstOrNull ?? _a;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _why(AppLocalizations.of(context), e));
    }
  }

  Future<void> _act(Future<void> Function(RedGiantClient c) f) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f(c);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = _why(AppLocalizations.of(context), e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final yes = await askConfirm(
      context,
      title: l.auDelete,
      body: l.auDeleteAutomationConfirm,
      yes: l.auDelete,
      danger: true,
    );
    if (!yes || !mounted) return;
    await _act((c) async {
      await c.deleteAutomation(_a.id);
      widget.onChanged();
      widget.onClose(ViewNext.deleted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final a = _a;
    final who = whoOptions(l, app.agents);
    final client = app.client;
    final hookUrl = client == null
        ? '/api/automations/${a.id}/hook'
        : client.base.resolve('/api/automations/${a.id}/hook').toString();
    final facts = <(String, String)>[
      if (a.nextRunAt != null) (l.auNextRun, dateTimeWords(l, a.nextRunAt!)),
      if (a.lastRun != null) (l.auAwLastRun, runStatusLabel(l, a.lastRun!.status)),
    ];
    return Column(
      key: Key('au-view-${a.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: a.enabled ? c.accentSoft.withValues(alpha: .5) : c.panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: a.enabled ? c.accent.withValues(alpha: .6) : c.line),
          ),
          child: SwitchLine(
            key: const Key('au-switch'),
            title: l.auAutoOn,
            help: a.enabled ? recipeWhen(l, a, who, app.projects) : l.auAutoOff,
            on: a.enabled,
            onChanged: _busy
                ? null
                : (on) => _act((c) async {
                    final b = await c.enableAutomation(a.id, on);
                    if (mounted) setState(() => _a = b);
                    widget.onChanged();
                  }),
          ),
        ),
        if (a.error != null) AutoNotice('${l.auRecipeBroken}: ${a.error}', error: true),
        if (facts.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final (k, v) in facts)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: c.panel,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(k, style: TextStyle(color: c.dim, fontSize: 12)),
                        Text(
                          v,
                          style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        if (a.reminder != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(14)),
            child: Text(a.reminder!, style: TextStyle(color: c.text, fontSize: 15, height: 1.45)),
          ),
        if (a.on['webhook'] == true)
          Container(
            key: const Key('au-hook'),
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.auWebhookUrl,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 13.5),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  'POST $hookUrl',
                  style: TextStyle(fontFamily: 'monospace', color: c.text, fontSize: 13),
                ),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    CopyButton(text: hookUrl, buttonKey: const Key('au-hook-copy')),
                    TextButton.icon(
                      key: const Key('au-secret'),
                      onPressed: _busy
                          ? null
                          : () => _act((c) async {
                              final s = await c.rotateAutomationSecret(a.id);
                              if (mounted) setState(() => _secret = s);
                            }),
                      icon: RgIcon(RgIcons.refresh, size: 16, color: c.accent),
                      label: Text(l.auNewSecret),
                    ),
                  ],
                ),
                if (_secret != null)
                  AutoNotice(
                    l.auWebhookSecretOnce,
                    key: const Key('au-secret-once'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SelectableText(
                        _secret!,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: c.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_started) AutoNotice(l.auAwStarted, key: const Key('au-started')),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('au-error')),
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            l.auRuns,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.text),
          ),
        ),
        if (_runs == null)
          Text(l.loading, style: TextStyle(color: c.dim))
        else if (_runs!.isEmpty)
          Text(
            l.auNoRuns,
            key: const Key('au-no-runs'),
            style: TextStyle(color: c.dim),
          )
        else
          for (final r in _runs!) _RunCard(run: r, automation: a),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton(
              key: const Key('au-delete'),
              style: TextButton.styleFrom(foregroundColor: c.err),
              onPressed: _busy ? null : _delete,
              child: Text(l.auDelete),
            ),
            if (a.reminder == null)
              OutlinedButton.icon(
                key: const Key('au-edit'),
                onPressed: _busy ? null : () => widget.onClose(ViewNext.edit),
                icon: RgIcon(RgIcons.pencil, size: 16, color: c.text),
                label: Text(l.auAwChange),
              ),
            FilledButton.icon(
              key: const Key('au-run'),
              onPressed: _busy
                  ? null
                  : () => _act((c) async {
                      await c.runAutomation(a.id);
                      if (mounted) setState(() => _started = true);
                      unawaited(_reload());
                    }),
              icon: const RgIcon(RgIcons.play, size: 16, color: Colors.white),
              label: Text(l.auRunNow),
            ),
          ],
        ),
      ],
    );
  }
}

/// One run: how it went, why it started, when and how long, whether its message arrived, what it
/// said, and its conversation.
class _RunCard extends StatelessWidget {
  const _RunCard({required this.run, required this.automation});

  final AutomationRun run;
  final Automation automation;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = run;
    final bad = !['ok', 'running', 'skipped', 'queued'].contains(r.status);
    final tone = r.status == 'ok' ? c.ok : (bad ? c.err : c.dim);
    final start = DateTime.tryParse(r.startedAt);
    final end = r.finishedAt == null ? null : DateTime.tryParse(r.finishedAt!);
    final secs = start != null && end != null
        ? (end.difference(start).inMilliseconds / 1000).round().clamp(1, 1 << 30)
        : null;
    return Container(
      key: Key('au-run-${r.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: r.status == 'ok' ? c.line : tone.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                runStatusLabel(l, r.status),
                style: TextStyle(color: tone, fontWeight: FontWeight.w800),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: c.panel2,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  runTriggerLabel(l, r.trigger),
                  style: TextStyle(color: c.dim, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${dateTimeWords(l, r.startedAt)}${secs != null ? ' · $secs s' : ''}',
                style: TextStyle(color: c.dim, fontSize: 12.5),
              ),
            ],
          ),
          if (r.delivery != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                deliveryText(l, r.delivery!),
                style: TextStyle(
                  color: r.delivery!.status == 'delivered' ? c.dim : c.err,
                  fontSize: 12.5,
                ),
              ),
            ),
          if (r.summary.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 6), child: SafeMarkdown(r.summary)),
          if (r.sessionId != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: Key('au-run-open-${r.id}'),
                onPressed: () => openRunConversation(
                  context,
                  r.sessionId!,
                  agentOfRecipe(automation, AppScope.read(context).agents),
                ),
                child: Text(l.auOpenSession),
              ),
            ),
        ],
      ),
    );
  }
}

/// A reminder: what, which day, what time; sent as written, no agent (the page's ReminderForm).
class ReminderForm extends StatefulWidget {
  const ReminderForm({super.key, required this.onSaved, required this.onCancel, this.now});

  final void Function([AutomationSaved?]) onSaved;
  final void Function([AutomationSaved?]) onCancel;

  /// For tests: today.
  final DateTime? now;

  @override
  State<ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<ReminderForm> {
  String _text = '';
  late String _day = () {
    final t = (widget.now ?? DateTime.now()).add(const Duration(days: 1));
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }();
  String _time = '09:00';
  String? _error;
  bool _busy = false;

  static String _q(String s) => _jsonString(s);

  Future<void> _save() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final text = _text.trim();
    final first = text.split('\n').first;
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final zone = await deviceTimeZone();
    final yaml = [
      'name: reminder-$_day-${_time.replaceAll(':', '')}-${stamp.substring(stamp.length - 3)}',
      'description: ${_q(first.length > 80 ? first.substring(0, 80) : first)}',
      'on:',
      '  at: ${_q('${_day}T$_time')}',
      '  timezone: ${zone ?? 'UTC'}',
      'reminder: ${_q(text)}',
      '',
    ].join('\n');
    try {
      final s = await c.createAutomation(yaml);
      widget.onSaved(s);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _why(AppLocalizations.of(context), e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(l.auReminderPurpose, style: TextStyle(color: c.dim, height: 1.4)),
        ),
        AutoField(
          label: l.auReminderWhat,
          value: _text,
          lines: 3,
          fieldKey: const Key('au-reminder-text'),
          onChanged: (v) => setState(() => _text = v),
        ),
        AutoRow(
          min: 150,
          children: [
            DateBox(
              label: l.auReminderDay,
              value: _day,
              boxKey: const Key('au-reminder-day'),
              onChanged: (v) => setState(() => _day = v.isEmpty ? _day : v),
            ),
            TimeBox(
              label: l.auWhenAtTime,
              value: _time,
              boxKey: const Key('au-reminder-time'),
              onChanged: (v) => setState(() => _time = v),
            ),
          ],
        ),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('au-error')),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(onPressed: () => widget.onCancel(), child: Text(l.auCancel)),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('au-reminder-save'),
              onPressed: _busy || _text.trim().isEmpty ? null : _save,
              child: Text(l.auReminderSave),
            ),
          ],
        ),
      ],
    );
  }
}

String _jsonString(String s) {
  final b = StringBuffer('"');
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    b.write(switch (ch) {
      '"' => r'\"',
      r'\' => r'\\',
      '\n' => r'\n',
      '\r' => r'\r',
      '\t' => r'\t',
      _ => r < 0x20 ? '\\u${r.toRadixString(16).padLeft(4, '0')}' : ch,
    });
  }
  b.write('"');
  return b.toString();
}
