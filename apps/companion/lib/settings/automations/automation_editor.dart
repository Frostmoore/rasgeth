// G42.9: the automation editor without limits, native, as the page's AutomationEditor.tsx (G33.3,
// the person: "mi deve dare ogni tipo di possibilità immaginabile, rimanendo con uno stile moderno
// e gradevole"). Five parts, in the order a person thinks: When (one or more things that start
// it), Only if (conditions, all together), What it does (an agent and its instructions, or a
// plain reminder; a yes first, a spending limit), Where it tells you, and Advanced (failures,
// overlaps, model, and the YAML in a coloured field). A sentence in words follows every change,
// and the next times come from the server (`POST /api/automations/preview`), which reads the
// recipe as it will run. The same editor makes a new automation, changes one, makes an
// assistant's routine (its agent chosen beforehand) and changes a magic automation's proposal
// before approving it. A recipe chooses an agent, never its tools.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api/client.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../api/automations_api.dart';
import '../rules_kit.dart';
import 'automation_draft.dart';
import 'automation_kit.dart';
import 'automation_types.dart';
import 'time_zone.dart';

/// Opens the editor in a window (a whole screen on a phone); what was saved, or null.
Future<AutomationSaved?> openAutomationEditor(
  BuildContext context, {
  required String title,
  Automation? current,
  Map<String, dynamic>? seed,
  String? who,
  Future<AutomationSaved> Function(String yaml)? submit,
  String? submitLabel,
}) => openAutoWindow<AutomationSaved>(
  context,
  title: title,
  wide: true,
  full: true,
  key: const Key('au-editor-window'),
  child: (ctx, close) => AutomationEditor(
    current: current,
    seed: seed,
    who: who,
    submit: submit,
    submitLabel: submitLabel,
    onSaved: close,
    onCancel: () => close(),
  ),
);

class AutomationEditor extends StatefulWidget {
  const AutomationEditor({
    super.key,
    this.current,
    this.seed,
    this.who,
    this.submit,
    this.submitLabel,
    required this.onSaved,
    required this.onCancel,
  });

  final Automation? current;

  /// A recipe to start from (a magic automation's proposal).
  final Map<String, dynamic>? seed;

  /// Who does it, chosen beforehand (an assistant's own routine: `p:<id>`).
  final String? who;

  /// Instead of saving: what the button does with the YAML (approve a proposal).
  final Future<AutomationSaved> Function(String yaml)? submit;
  final String? submitLabel;
  final void Function([AutomationSaved?]) onSaved;
  final VoidCallback onCancel;

  @override
  State<AutomationEditor> createState() => _AutomationEditorState();
}

class _AutomationEditorState extends State<AutomationEditor> {
  late Draft _d;
  String _tpl = 'blank';
  late String _name;
  String? _yaml;
  List<Automation> _others = const [];
  List<MailboxInfo> _boxes = const [];
  AutomationPreview? _preview;
  String? _previewed;
  Timer? _timer;
  String? _error;
  bool _busy = false;
  bool _advanced = false;
  String? _zone;
  late final _yamlCtl = YamlController();

  bool _made = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_made) return;
    _made = true;
    final app = AppScope.read(context);
    final l = AppLocalizations.of(context);
    final who = whoOptions(l, app.agents);
    final start = widget.seed ?? widget.current?.recipe;
    if (start != null) {
      _d = fromRecipe(start, who, app.projects);
    } else {
      _tpl = 'morning';
      _d = blankDraft(app.projects)
        ..title = templateTitle(l, 'morning')
        ..time = templateWhen['morning']!
        ..instructions = templateText(l, 'morning')
        ..whoKey = widget.who ?? 'god';
    }
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    _name =
        widget.current?.name ??
        (widget.seed?['name'] as String?) ??
        '${slug(_d.title)}-${stamp.substring(stamp.length - 4)}';
    unawaited(_loadAround());
  }

  Future<void> _loadAround() async {
    final c = AppScope.read(context).client;
    final zone = await deviceTimeZone();
    if (mounted) setState(() => _zone = zone);
    if (c == null) return;
    try {
      final all = await c.automations();
      if (mounted) setState(() => _others = all.where((a) => a.id != widget.current?.id).toList());
    } on ApiException {
      // The list of the others is only for «after» and «if it fails».
    }
    try {
      final boxes = await c.mailboxes();
      if (mounted) setState(() => _boxes = boxes);
    } on ApiException {
      // No mailboxes to choose: «all of them».
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _yamlCtl.dispose();
    super.dispose();
  }

  void _up(void Function(Draft d) f) => setState(() => f(_d));

  void _pickTemplate(AppLocalizations l, String x) => setState(() {
    _tpl = x;
    if (x == 'blank') {
      _d
        ..title = ''
        ..instructions = ''
        ..starts = ['time']
        ..time = const When('daily', time: '09:00');
      return;
    }
    _d
      ..title = templateTitle(l, x)
      ..instructions = templateText(l, x)
      ..starts = ['time']
      ..time = templateWhen[x]!;
  });

  /// The server's reading a moment after each change.
  void _schedulePreview(String text) {
    if (text == _previewed) return;
    _previewed = text;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 450), () async {
      final c = AppScope.read(context).client;
      if (c == null) return;
      try {
        final p = await c.previewAutomation(text);
        if (mounted && _previewed == text) setState(() => _preview = p);
      } on ApiException {
        if (mounted) setState(() => _preview = null);
      }
    });
  }

  Future<void> _save(String text) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final current = widget.current;
      final res = widget.submit != null
          ? await widget.submit!(text)
          : current != null
          ? await c.updateAutomation(current.id, text)
          : await c.createAutomation(text);
      // A routine on repository events: its webhook goes on Gitea or GitHub now, with the
      // secret that is shown only this once (G24.14c).
      if (_d.has('repo') && res.webhookSecret != null) {
        await c.repoHook(res.automation.id, res.webhookSecret!, _d.repoProject);
      }
      widget.onSaved(res);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).errGeneric(e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final who = whoOptions(l, app.agents);
    final d = _d;
    final generated = toYaml(d, _name, who, zone: _zone);
    final text = _yaml ?? generated;
    if (_yaml == null && _yamlCtl.text != generated) _yamlCtl.text = generated;
    _schedulePreview(text);
    final others = {for (final a in _others) a.name: a.description};
    final said = sentence(l, d, who, others);
    final ready =
        _yaml != null ||
        (d.title.trim().isNotEmpty &&
            d.starts.isNotEmpty &&
            (d.does == 'agent' ? d.instructions.trim().isNotEmpty : d.reminder.trim().isNotEmpty));
    final projects = [for (final p in app.projects) (p.id, p.name)];
    final otherOptions = [for (final a in _others) (a.name, a.title)];
    final p = _preview;

    return Column(
      key: const Key('au-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.current == null && widget.seed == null) ...[
          AutoLb(l.auAutoStart),
          AutoGrid(
            min: 200,
            children: [
              for (final x in [...templates, 'blank'])
                _TemplateButton(
                  key: Key('au-tpl-$x'),
                  title: templateTitle(l, x),
                  text: templateDesc(l, x),
                  on: _tpl == x,
                  onTap: () => _pickTemplate(l, x),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        AutoField(
          label: l.auAutoTitle,
          help: l.auAutoTitleHelp,
          value: d.title,
          fieldKey: const Key('au-title'),
          onChanged: (v) => _up((d) => d.title = v),
        ),
        SaysBox(lines: said),

        // ---- 1. When ----
        AutoPart(
          n: 1,
          icon: RgIcons.clock,
          title: l.auAxWhen,
          help: l.auAxWhenHelp,
          children: [
            AutoChips<String>(
              multiple: true,
              options: [for (final s in starts) (s, startLabel(l, s))],
              value: d.starts,
              keyOf: (s) => 'au-start-$s',
              onChanged: (v) => _up((d) => d.starts = v),
            ),
            if (d.has('time'))
              AutoDetail(
                icon: RgIcons.clock,
                title: l.auAxStart_time,
                children: [_TimeDetail(when: d.time, onChanged: (w) => _up((d) => d.time = w))],
              ),
            if (d.has('email'))
              AutoDetail(
                icon: RgIcons.send,
                title: l.auWhenKind_email,
                children: [
                  AutoRow(
                    children: [
                      AutoField(
                        label: l.auEmailFrom,
                        hint: l.auEmailFromPlaceholder,
                        value: d.emailFrom,
                        fieldKey: const Key('au-email-from'),
                        onChanged: (v) => _up((d) => d.emailFrom = v),
                      ),
                      AutoField(
                        label: l.auEmailSubject,
                        hint: l.auEmailSubjectPlaceholder,
                        value: d.emailSubject,
                        onChanged: (v) => _up((d) => d.emailSubject = v),
                      ),
                      AutoField(
                        label: l.auAxEmailText,
                        hint: l.auAxEmailTextPlaceholder,
                        value: d.emailText,
                        onChanged: (v) => _up((d) => d.emailText = v),
                      ),
                    ],
                  ),
                  if (_boxes.length > 1) ...[
                    AutoLb(l.auAxEmailWhich),
                    RgChoice<String>(
                      options: [
                        ('all', l.auAxEmailAll),
                        ('categories', l.auAxEmailByCategory),
                        ('boxes', l.auAxEmailByBox),
                      ],
                      value: d.emailScope,
                      keyOf: (v) => 'au-email-scope-$v',
                      onChanged: (v) => _up((d) => d.emailScope = v),
                    ),
                    const SizedBox(height: 8),
                    if (d.emailScope == 'categories')
                      AutoChips<String>(
                        multiple: true,
                        options: [
                          for (final cat in {for (final b in _boxes) b.category})
                            (cat, categoryLabel(l, cat)),
                        ],
                        value: d.emailCategories,
                        keyOf: (v) => 'au-email-cat-$v',
                        onChanged: (v) => _up((d) => d.emailCategories = v),
                      ),
                    if (d.emailScope == 'boxes')
                      AutoChips<String>(
                        multiple: true,
                        options: [for (final b in _boxes) (b.id, b.name)],
                        value: d.emailBoxes,
                        keyOf: (v) => 'au-email-box-$v',
                        onChanged: (v) => _up((d) => d.emailBoxes = v),
                      ),
                  ],
                  _MailboxLine(boxes: _boxes),
                  AutoHelp(l.auWhenEmailHelp),
                ],
              ),
            if (d.has('message'))
              AutoDetail(
                icon: RgIcons.chat,
                title: l.auAxStart_message,
                children: [
                  AutoLb(l.auAxMessageWhere),
                  AutoChips<String>(
                    multiple: true,
                    options: [for (final p in platforms) (p, platformNames[p] ?? p)],
                    value: d.messagePlatforms,
                    keyOf: (v) => 'au-msg-$v',
                    onChanged: (v) => _up((d) => d.messagePlatforms = v),
                  ),
                  const SizedBox(height: 12),
                  AutoRow(
                    children: [
                      AutoField(
                        label: l.auAxMessageFrom,
                        help: l.auAxMessageFromHelp,
                        value: d.messageFrom,
                        onChanged: (v) => _up((d) => d.messageFrom = v),
                      ),
                      AutoField(
                        label: l.auAxMessageWords,
                        help: l.auAxWordsHelp,
                        hint: l.auAxMessageWordsPlaceholder,
                        value: d.messageWords,
                        onChanged: (v) => _up((d) => d.messageWords = v),
                      ),
                      AutoField(
                        label: l.auAxMessageChat,
                        help: l.auAxMessageChatHelp,
                        value: d.messageChat,
                        onChanged: (v) => _up((d) => d.messageChat = v),
                      ),
                    ],
                  ),
                  SwitchLine(
                    title: l.auAxMessageHandle,
                    help: l.auAxMessageHandleHelp,
                    on: d.messageHandle,
                    onChanged: (v) => _up((d) => d.messageHandle = v),
                  ),
                ],
              ),
            if (d.has('files'))
              AutoDetail(
                icon: RgIcons.folder,
                title: l.auAxStart_files,
                children: [
                  AutoRow(
                    children: [
                      PickBox<String>(
                        label: l.auProjects,
                        options: projects,
                        value: d.filesProject,
                        keyOf: (v) => 'au-pick-$v',
                        onChanged: projects.isEmpty ? null : (v) => _up((d) => d.filesProject = v),
                      ),
                      AutoField(
                        label: l.auAxFilesPath,
                        help: l.auAxFilesPathHelp,
                        value: d.filesPath,
                        onChanged: (v) => _up((d) => d.filesPath = v),
                      ),
                      AutoField(
                        label: l.auAxFilesPattern,
                        help: l.auAxFilesPatternHelp,
                        hint: '*.pdf',
                        value: d.filesPattern,
                        onChanged: (v) => _up((d) => d.filesPattern = v),
                      ),
                    ],
                  ),
                  AutoChips<String>(
                    multiple: true,
                    options: [
                      ('added', l.auAxFiles_added),
                      ('changed', l.auAxFiles_changed),
                      ('removed', l.auAxFiles_removed),
                    ],
                    value: d.filesChanges,
                    keyOf: (v) => 'au-files-$v',
                    onChanged: (v) => _up((d) => d.filesChanges = v),
                  ),
                  if (projects.isEmpty) AutoHelp(l.auAxFilesProjectHelp),
                ],
              ),
            if (d.has('repo'))
              AutoDetail(
                icon: RgIcons.git,
                title: l.auWhenKind_repo,
                children: [
                  PickBox<String>(
                    label: l.auProjects,
                    options: projects,
                    value: d.repoProject,
                    keyOf: (v) => 'au-pick-$v',
                    onChanged: projects.isEmpty ? null : (v) => _up((d) => d.repoProject = v),
                  ),
                  AutoChips<String>(
                    multiple: true,
                    options: [for (final e in repoEvents) (e, _repoEvent(l, e))],
                    value: d.repoEvents,
                    keyOf: (v) => 'au-repo-$v',
                    onChanged: (v) => _up((d) => d.repoEvents = v),
                  ),
                  AutoHelp(l.auWhenRepoHelp),
                ],
              ),
            if (d.has('after'))
              AutoDetail(
                icon: RgIcons.layers,
                title: l.auAxStart_after,
                children: [
                  PickBox<String>(
                    label: l.auAxAfterWhich,
                    options: [('', l.auAxPick), ...otherOptions],
                    value: d.afterAutomation,
                    boxKey: const Key('au-after-which'),
                    keyOf: (v) => 'au-pick-after-$v',
                    onChanged: (v) => _up((d) => d.afterAutomation = v),
                  ),
                  AutoChips<String>(
                    multiple: true,
                    options: [
                      ('ok', l.auAxAfter_ok),
                      ('failed', l.auAxAfter_failed),
                      ('timeout', l.auAxAfter_timeout),
                    ],
                    value: d.afterStatus,
                    keyOf: (v) => 'au-after-$v',
                    onChanged: (v) => _up((d) => d.afterStatus = v),
                  ),
                ],
              ),
            if (d.has('task'))
              AutoDetail(
                icon: RgIcons.play,
                title: l.auAxStart_task,
                children: [
                  PickBox<String>(
                    label: l.auProjects,
                    options: [('', l.auAxAnyProject), ...projects],
                    value: d.taskProject,
                    keyOf: (v) => 'au-pick-task-$v',
                    onChanged: (v) => _up((d) => d.taskProject = v),
                  ),
                  AutoChips<String>(
                    multiple: true,
                    options: [
                      ('verified', l.auAxTask_verified),
                      ('not_testable', l.auAxTask_not_testable),
                      ('abandoned', l.auAxTask_abandoned),
                    ],
                    value: d.taskOutcome,
                    keyOf: (v) => 'au-task-$v',
                    onChanged: (v) => _up((d) => d.taskOutcome = v),
                  ),
                ],
              ),
            if (d.has('webhook')) AutoHelp(l.auWhenWebhookHelp),
            if (d.has('startup')) AutoHelp(l.auAxStartupHelp),
            if (p != null &&
                p.error == null &&
                p.next.isEmpty &&
                d.has('time') &&
                d.time.kind != 'once')
              _NextBox(bad: true, children: [Text(l.auAxNextNone)]),
            if (p != null && (p.next.isNotEmpty || p.error != null))
              _NextBox(
                bad: p.error != null,
                children: p.error != null
                    ? [Text('${l.auAxServerSays} ${p.error}', key: const Key('au-server-says'))]
                    : [
                        Text(
                          l.auAxNextTimes,
                          style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                        ),
                        const SizedBox(height: 6),
                        for (final (i, n) in p.next.indexed)
                          Padding(
                            key: Key('au-next-$i'),
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              '${i + 1}.  ${_nextWords(l, n)}',
                              style: TextStyle(
                                color: c.text,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                      ],
              ),
          ],
        ),

        // ---- 2. Only if ----
        AutoPart(
          n: 2,
          icon: RgIcons.sliders,
          title: l.auAxOnly,
          help: l.auAxOnlyHelp,
          children: [
            AutoCond(
              key: const Key('au-cond-hours'),
              title: l.auAxCondHours,
              on: d.onlyHours,
              onChanged: (v) => _up((d) => d.onlyHours = v),
              children: [
                AutoRow(
                  min: 140,
                  children: [
                    TimeBox(
                      label: l.auAxFrom,
                      value: d.onlyFrom,
                      onChanged: (v) => _up((d) => d.onlyFrom = v),
                    ),
                    TimeBox(
                      label: l.auAxTo,
                      value: d.onlyTo,
                      onChanged: (v) => _up((d) => d.onlyTo = v),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('au-work-hours'),
                      onPressed: () => _up(
                        (d) => d
                          ..onlyFrom = '09:00'
                          ..onlyTo = '18:00'
                          ..onlyDays = [1, 2, 3, 4, 5],
                      ),
                      child: Text(l.auAxWorkHours),
                    ),
                    OutlinedButton(
                      onPressed: () => _up(
                        (d) => d
                          ..onlyFrom = '22:00'
                          ..onlyTo = '07:00',
                      ),
                      child: Text(l.auAxNightHours),
                    ),
                  ],
                ),
              ],
            ),
            AutoCond(
              key: const Key('au-cond-days'),
              title: l.auAxCondDays,
              on: d.onlyDays != null,
              onChanged: (v) => _up((d) => d.onlyDays = v ? [1, 2, 3, 4, 5] : null),
              children: [
                AutoChips<int>(
                  multiple: true,
                  options: [for (final x in weekDays) (x, dayName(l, x))],
                  value: d.onlyDays ?? const [],
                  keyOf: (v) => 'au-only-day-$v',
                  onChanged: (v) => _up((d) => d.onlyDays = v),
                ),
              ],
            ),
            AutoCond(
              title: l.auAxCondDates,
              on: d.onlyDates,
              onChanged: (v) => _up((d) => d.onlyDates = v),
              children: [
                AutoRow(
                  min: 140,
                  children: [
                    DateBox(
                      label: l.auAxFromDay,
                      value: d.onlyDateFrom,
                      empty: '…',
                      onChanged: (v) => _up((d) => d.onlyDateFrom = v),
                    ),
                    DateBox(
                      label: l.auAxToDay,
                      value: d.onlyDateTo,
                      empty: '…',
                      onChanged: (v) => _up((d) => d.onlyDateTo = v),
                    ),
                  ],
                ),
              ],
            ),
            AutoCond(
              title: l.auAxCondFrom,
              help: l.auAxCondFromHelp,
              on: d.onlySenders.isNotEmpty,
              onChanged: (v) => _up((d) => d.onlySenders = v ? ' ' : ''),
              children: [
                AutoField(
                  label: l.auAxSenders,
                  help: l.auAxWordsHelp,
                  hint: l.auAxSendersPlaceholder,
                  value: d.onlySenders.trim(),
                  onChanged: (v) => _up((d) => d.onlySenders = v.isEmpty ? ' ' : v),
                ),
              ],
            ),
            AutoCond(
              key: const Key('au-cond-words'),
              title: l.auAxCondWords,
              on: d.onlyWords.isNotEmpty,
              onChanged: (v) => _up((d) => d.onlyWords = v ? ' ' : ''),
              children: [
                AutoField(
                  label: l.auAxWords,
                  help: l.auAxWordsHelp,
                  hint: l.auAxWordsPlaceholder,
                  value: d.onlyWords.trim(),
                  fieldKey: const Key('au-only-words'),
                  onChanged: (v) => _up((d) => d.onlyWords = v.isEmpty ? ' ' : v),
                ),
                RgChoice<String>(
                  options: [('any', l.auAxMatchAny), ('all', l.auAxMatchAll)],
                  value: d.onlyMatch,
                  keyOf: (v) => 'au-match-$v',
                  onChanged: (v) => _up((d) => d.onlyMatch = v),
                ),
              ],
            ),
            AutoCond(
              title: l.auAxCondWithout,
              on: d.onlyWithout.isNotEmpty,
              onChanged: (v) => _up((d) => d.onlyWithout = v ? ' ' : ''),
              children: [
                AutoField(
                  label: l.auAxWithout,
                  help: l.auAxWordsHelp,
                  hint: l.auAxWithoutPlaceholder,
                  value: d.onlyWithout.trim(),
                  onChanged: (v) => _up((d) => d.onlyWithout = v.isEmpty ? ' ' : v),
                ),
              ],
            ),
            AutoCond(
              title: l.auAxCondMax,
              on: d.onlyMaxPerDay > 0,
              onChanged: (v) => _up((d) => d.onlyMaxPerDay = v ? 3 : 0),
              children: [
                AutoField(
                  label: l.auAxMaxPerDay,
                  number: true,
                  value: '${d.onlyMaxPerDay}',
                  onChanged: (v) => _up((d) => d.onlyMaxPerDay = _atLeast(v, 1)),
                ),
              ],
            ),
            AutoCond(
              title: l.auAxCondCooldown,
              on: d.onlyCooldown > 0,
              onChanged: (v) => _up((d) => d.onlyCooldown = v ? 30 : 0),
              children: [
                AutoField(
                  label: l.auAxCooldown,
                  number: true,
                  value: '${d.onlyCooldown}',
                  onChanged: (v) => _up((d) => d.onlyCooldown = _atLeast(v, 1)),
                ),
              ],
            ),
          ],
        ),

        // ---- 3. What it does ----
        AutoPart(
          n: 3,
          icon: RgIcons.zap,
          title: l.auAxDoes,
          help: l.auAxDoesHelp,
          children: [
            RgChoice<String>(
              options: [('agent', l.auAxDoesAgent), ('reminder', l.auAxDoesReminder)],
              value: d.does,
              keyOf: (v) => 'au-does-$v',
              onChanged: (v) => _up((d) => d.does = v),
            ),
            const SizedBox(height: 12),
            if (d.does == 'agent') ...[
              PickBox<String>(
                label: l.auAutoWho,
                help: l.auAutoWhoHelp,
                options: [
                  for (final x in who) (x.key, x.label),
                  if (!who.any((x) => x.key == d.whoKey)) (d.whoKey, d.whoKey),
                ],
                value: d.whoKey,
                boxKey: const Key('au-who'),
                keyOf: (v) => 'au-who-$v',
                onChanged: (v) => _up((d) => d.whoKey = v),
              ),
              AutoField(
                label: l.auAutoWhat,
                help: l.auAutoWhatHelp,
                value: d.instructions,
                lines: 5,
                fieldKey: const Key('au-instructions'),
                onChanged: (v) => _up((d) => d.instructions = v),
              ),
              AutoLb(l.auAxSession),
              RgChoice<String>(
                options: [('new', l.auAxSessionNew), ('continue', l.auAxSessionContinue)],
                value: d.session,
                keyOf: (v) => 'au-session-$v',
                onChanged: (v) => _up((d) => d.session = v),
              ),
              const SizedBox(height: 12),
            ] else
              AutoField(
                label: l.auReminderWhat,
                value: d.reminder,
                lines: 3,
                fieldKey: const Key('au-reminder-body'),
                onChanged: (v) => _up((d) => d.reminder = v),
              ),
            AutoCond(
              key: const Key('au-approve'),
              title: l.auAxApprove,
              help: l.auAxApproveHelp,
              on: d.approve,
              onChanged: (v) => _up((d) => d.approve = v),
            ),
            if (d.does == 'agent')
              AutoCond(
                key: const Key('au-budget'),
                title: l.auAxBudget,
                help: l.auAxBudgetHelp,
                on: d.budget > 0,
                onChanged: (v) => _up((d) => d.budget = v ? .5 : 0),
                children: [
                  AutoField(
                    label: l.auAxBudgetUsd,
                    number: true,
                    decimal: true,
                    prefix: r'$ ',
                    value: _plain(d.budget),
                    fieldKey: const Key('au-budget-usd'),
                    onChanged: (v) => _up((d) {
                      final n = double.tryParse(v.replaceAll(',', '.')) ?? .01;
                      d.budget = n < .01 ? .01 : n;
                    }),
                  ),
                ],
              ),
          ],
        ),

        // ---- 4. Where it tells you ----
        AutoPart(
          n: 4,
          icon: RgIcons.bell,
          title: l.auAxTell,
          help: l.auAxTellHelp,
          children: [
            RgChoice<String>(
              options: [
                ('always', l.auAxTellAlways),
                ('failure', l.auAxTellFailure),
                ('never', l.auAxTellNever),
              ],
              value: d.notifyWhen,
              keyOf: (v) => 'au-tell-$v',
              onChanged: (v) => _up((d) => d.notifyWhen = v),
            ),
            if (d.notifyWhen != 'never') ...[
              AutoLb(l.auAxTellWhere),
              AutoChips<String>(
                multiple: true,
                options: [
                  for (final p in platforms) (p, platformNames[p] ?? p),
                  ('web', l.auAxToWeb),
                  ('email', l.auAxToEmail),
                ],
                value: d.notifyTo,
                keyOf: (v) => 'au-to-$v',
                onChanged: (v) => _up((d) => d.notifyTo = v),
              ),
              AutoHelp(
                d.notifyTo.isEmpty
                    ? l.auAxTellAllHelp
                    : d.has('message') && !d.notifyTo.any(platforms.contains)
                    ? l.auAxTellReplyHelp
                    : l.auAxTellSomeHelp,
              ),
              if (d.notifyTo.contains('email'))
                AutoRow(
                  children: [
                    AutoField(
                      label: l.auAxTellEmailTo,
                      help: l.auAxTellEmailToHelp,
                      value: d.notifyEmail,
                      onChanged: (v) => _up((d) => d.notifyEmail = v),
                    ),
                    if (_boxes.isNotEmpty)
                      PickBox<String>(
                        label: l.auAxTellEmailFrom,
                        options: [('', l.auAxFirstBox), for (final b in _boxes) (b.id, b.name)],
                        value: d.notifyBox,
                        keyOf: (v) => 'au-pick-box-$v',
                        onChanged: (v) => _up((d) => d.notifyBox = v),
                      ),
                  ],
                ),
            ],
          ],
        ),

        // ---- Advanced ----
        const SizedBox(height: 14),
        _AdvancedHead(
          label: l.auAxAdvanced,
          open: _advanced,
          onTap: () => setState(() => _advanced = !_advanced),
        ),
        if (_advanced)
          Container(
            key: const Key('au-advanced'),
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: c.panel,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SmallHead(icon: RgIcons.shield, text: l.auAxIfFails),
                AutoRow(
                  min: 160,
                  children: [
                    AutoField(
                      label: l.auAxRetries,
                      number: true,
                      value: '${d.retries}',
                      fieldKey: const Key('au-retries'),
                      onChanged: (v) => _up((d) => d.retries = _atLeast(v, 0).clamp(0, 5)),
                    ),
                    if (d.retries > 0)
                      AutoField(
                        label: l.auAxRetryMinutes,
                        number: true,
                        value: '${d.retryMinutes}',
                        onChanged: (v) => _up((d) => d.retryMinutes = _atLeast(v, 1)),
                      ),
                    PickBox<String>(
                      label: l.auAxFallback,
                      options: [('', l.auAxNone), ...otherOptions],
                      value: d.fallback,
                      keyOf: (v) => 'au-pick-fallback-$v',
                      onChanged: (v) => _up((d) => d.fallback = v),
                    ),
                  ],
                ),
                AutoLb(l.auAxOverlap),
                RgChoice<String>(
                  options: [('skip', l.auAxOverlapSkip), ('queue', l.auAxOverlapQueue)],
                  value: d.overlap,
                  keyOf: (v) => 'au-overlap-$v',
                  onChanged: (v) => _up((d) => d.overlap = v),
                ),
                if (d.has('time') && d.time.kind != 'once') ...[
                  AutoLb(l.auAxMissed),
                  RgChoice<String>(
                    options: [('skip', l.auAxMissedSkip), ('run', l.auAxMissedRun)],
                    value: d.missed,
                    keyOf: (v) => 'au-missed-$v',
                    onChanged: (v) => _up((d) => d.missed = v),
                  ),
                ],
                const SizedBox(height: 12),
                AutoRow(
                  min: 160,
                  children: [
                    AutoField(
                      label: l.auAxTimeout,
                      number: true,
                      value: '${d.timeout}',
                      onChanged: (v) => _up((d) => d.timeout = _atLeast(v, 1).clamp(1, 1440)),
                    ),
                    if (d.does == 'agent') ...[
                      AutoField(
                        label: l.auAxModel,
                        help: l.auAxModelHelp,
                        hint: 'provider/model',
                        mono: true,
                        value: d.model,
                        onChanged: (v) => _up((d) => d.model = v),
                      ),
                      PickBox<String>(
                        label: l.auAxEffort,
                        options: [
                          ('', l.auAxAgentOwn),
                          for (final x in ['low', 'medium', 'high', 'xhigh', 'max']) (x, x),
                        ],
                        value: d.effort,
                        keyOf: (v) => 'au-pick-effort-$v',
                        onChanged: (v) => _up((d) => d.effort = v),
                      ),
                    ],
                  ],
                ),
                _SmallHead(icon: RgIcons.globe, text: l.auAutoYaml),
                AutoHelp(l.auAutoYamlHint),
                const SizedBox(height: 6),
                YamlField(controller: _yamlCtl, onChanged: (v) => setState(() => _yaml = v)),
                if (_yaml != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('au-yaml-back'),
                      onPressed: () => setState(() => _yaml = null),
                      child: Text(l.auAxYamlBack),
                    ),
                  ),
              ],
            ),
          ),
        if (_error != null) AutoNotice(_error!, error: true, key: const Key('au-error')),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              key: const Key('au-cancel'),
              onPressed: widget.onCancel,
              child: Text(l.auCancel),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('au-save'),
              onPressed: _busy || !ready ? null : () => _save(text),
              child: Text(widget.submitLabel ?? (widget.current != null ? l.auSave : l.auCreate)),
            ),
          ],
        ),
      ],
    );
  }
}

int _atLeast(String v, int min) {
  final n = int.tryParse(v) ?? 0;
  return n < min ? min : n;
}

String _plain(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

String _repoEvent(AppLocalizations l, String e) => switch (e) {
  'push' => l.auRepoEvent_push,
  'pull_request' => l.auRepoEvent_pull_request,
  'issues' => l.auRepoEvent_issues,
  'issue_comment' => l.auRepoEvent_issue_comment,
  _ => l.auRepoEvent_release,
};

/// A next time as the page writes it: the weekday, the day and month, the time.
String _nextWords(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final t = d.toLocal();
  return '${DateFormat('EEE d MMM', l.localeName).format(t)}, '
      '${DateFormat.Hm(l.localeName).format(t)}';
}

/// The schedule: how often, then only what that needs (the page's `TimeDetail`).
class _TimeDetail extends StatelessWidget {
  const _TimeDetail({required this.when, required this.onChanged});

  final When when;
  final ValueChanged<When> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final w = when;
    String label(String k) => switch (k) {
      'daily' => l.auWhenKind_daily,
      'weekdays' => l.auWhenKind_weekdays,
      'weekly' => l.auWhenKind_weekly,
      'monthly' => l.auWhenKind_monthly,
      'hours' => l.auWhenKind_hours,
      'minutes' => l.auAxKind_minutes,
      'once' => l.auAxKind_once,
      _ => l.auAxKind_custom,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutoChips<String>(
          options: [
            for (final k in [...schedules, 'custom']) (k, label(k)),
          ],
          value: [w.kind],
          keyOf: (k) => 'au-when-$k',
          onChanged: (v) => onChanged(scheduleOf(v.first, w)),
        ),
        const SizedBox(height: 12),
        AutoRow(
          min: 150,
          children: [
            if (w.hasTime)
              TimeBox(
                label: l.auWhenAtTime,
                value: w.time,
                boxKey: const Key('au-when-time'),
                onChanged: (v) => onChanged(w.copy(time: v)),
              ),
            if (w.kind == 'monthly')
              AutoField(
                label: l.auWhenDayOfMonth,
                number: true,
                value: '${w.day}',
                onChanged: (v) => onChanged(w.copy(day: _atLeast(v, 1).clamp(1, 28))),
              ),
            if (w.kind == 'hours')
              AutoField(
                label: l.auWhenEveryHours,
                number: true,
                value: '${w.every}',
                fieldKey: const Key('au-every-hours'),
                onChanged: (v) => onChanged(w.copy(every: _atLeast(v, 1).clamp(1, 23))),
              ),
            if (w.kind == 'minutes')
              AutoField(
                label: l.auAxEveryMinutes,
                number: true,
                value: '${w.every}',
                onChanged: (v) => onChanged(w.copy(every: _atLeast(v, 1).clamp(1, 59))),
              ),
            if (w.kind == 'once') ...[
              DateBox(
                label: l.auAxOnceAt,
                value: w.at.length >= 10 ? w.at.substring(0, 10) : '',
                boxKey: const Key('au-once-day'),
                onChanged: (v) {
                  if (v.isEmpty) return;
                  final time = w.at.length >= 16 ? w.at.substring(11, 16) : '09:00';
                  onChanged(w.copy(at: '${v}T$time'));
                },
              ),
              TimeBox(
                label: l.auWhenAtTime,
                value: w.at.length >= 16 ? w.at.substring(11, 16) : '09:00',
                onChanged: (v) {
                  final day = w.at.length >= 10 ? w.at.substring(0, 10) : '';
                  if (day.isNotEmpty) onChanged(w.copy(at: '${day}T$v'));
                },
              ),
            ],
            if (w.kind == 'custom')
              AutoField(
                label: l.auAxCron,
                help: l.auAxCronHelp,
                mono: true,
                value: w.cron,
                fieldKey: const Key('au-cron'),
                onChanged: (v) => onChanged(w.copy(cron: v)),
              ),
          ],
        ),
        if (w.kind == 'weekly')
          AutoChips<int>(
            multiple: true,
            options: [for (final x in weekDays) (x, dayName(l, x))],
            value: w.days,
            keyOf: (v) => 'au-day-$v',
            onChanged: (v) => onChanged(w.copy(days: v)),
          ),
      ],
    );
  }
}

class _TemplateButton extends StatelessWidget {
  const _TemplateButton({
    super.key,
    required this.title,
    required this.text,
    required this.on,
    required this.onTap,
  });

  final String title;
  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? c.accent : c.line, width: on ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextBox extends StatelessWidget {
  const _NextBox({required this.bad, required this.children});

  final bool bad;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final col = bad ? c.warn : c.accent;
    return Container(
      key: const Key('au-next'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withValues(alpha: .4)),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: bad ? c.warnText : c.text, fontSize: 13.5, height: 1.4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _AdvancedHead extends StatelessWidget {
  const _AdvancedHead({required this.label, required this.open, required this.onTap});

  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('au-advanced-toggle'),
        onPressed: onTap,
        icon: AnimatedRotation(
          turns: open ? .5 : 0,
          duration: const Duration(milliseconds: 160),
          child: RgIcon(RgIcons.chevronDown, size: 18, color: c.accent),
        ),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SmallHead extends StatelessWidget {
  const _SmallHead({required this.icon, required this.text});

  final RgIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          RgIcon(icon, size: 16, color: c.accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
          ),
        ],
      ),
    );
  }
}

/// The mailboxes an email automation reads (the page's `MailboxNeed`).
class _MailboxLine extends StatelessWidget {
  const _MailboxLine({required this.boxes});

  final List<MailboxInfo> boxes;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final ok = boxes.isNotEmpty;
    final text = boxes.length > 1
        ? l.auAxMailboxesWatching('${boxes.length}', boxes.map((b) => b.name).join(', '))
        : ok
        ? l.auEmailWatching(boxes.first.user, boxes.first.host)
        : l.auEmailNeedFirst;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (ok ? c.ok : c.warn).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (ok ? c.ok : c.warn).withValues(alpha: .35)),
      ),
      child: Row(
        children: [
          RgIcon(RgIcons.send, size: 17, color: ok ? c.ok : c.warnText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok ? text : '$text ${l.auOwnMailboxesElsewhere}',
              style: TextStyle(color: c.text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// The YAML coloured as code: keys, strings, numbers and words like true, comments.
class YamlController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final c = RgColors.of(context);
    final base = style ?? const TextStyle();
    final spans = <TextSpan>[];
    final line = RegExp(r'^(\s*)([A-Za-z0-9_-]+)(:)(.*)$');
    final lines = text.split('\n');
    for (final (i, raw) in lines.indexed) {
      final m = line.firstMatch(raw);
      if (raw.trimLeft().startsWith('#')) {
        spans.add(
          TextSpan(
            text: raw,
            style: base.copyWith(color: c.dim),
          ),
        );
      } else if (m != null) {
        spans
          ..add(TextSpan(text: m.group(1)))
          ..add(
            TextSpan(
              text: m.group(2),
              style: base.copyWith(color: c.accent, fontWeight: FontWeight.w700),
            ),
          )
          ..add(
            TextSpan(
              text: m.group(3),
              style: base.copyWith(color: c.dim),
            ),
          )
          ..add(_value(m.group(4)!, base, c));
      } else {
        spans.add(TextSpan(text: raw));
      }
      if (i < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return TextSpan(style: base, children: spans);
  }

  TextSpan _value(String v, TextStyle base, RgColors c) {
    final t = v.trim();
    if (t.isEmpty) return TextSpan(text: v);
    final Color col;
    if (t.startsWith('"') || t.startsWith("'")) {
      col = c.ok;
    } else if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(t) || ['true', 'false', 'null'].contains(t)) {
      col = c.warnText;
    } else if (t.startsWith('[') || t.startsWith('{')) {
      col = c.text;
    } else {
      col = c.text;
    }
    return TextSpan(
      text: v,
      style: base.copyWith(color: col),
    );
  }
}

/// The YAML in a native field, coloured, in the code font (the page's `aw-yaml`).
class YamlField extends StatelessWidget {
  const YamlField({super.key, required this.controller, required this.onChanged});

  final YamlController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Semantics(
      label: l.auOwnYamlLabel,
      textField: true,
      child: TextField(
        key: const Key('au-yaml'),
        controller: controller,
        minLines: 10,
        maxLines: 24,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.multiline,
        style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: c.text, height: 1.45),
        decoration: autoInput(context).copyWith(fillColor: c.code),
        onChanged: onChanged,
      ),
    );
  }
}
