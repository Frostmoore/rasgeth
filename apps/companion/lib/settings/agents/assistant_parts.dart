// G42.4: what only a personal assistant has (the page's AssistantPage, Assistants.tsx): the
// services it may use (MCP servers added for everyone, each with its state), its routines (work
// it does by itself at a set time: on or off, and a new one), and the skills it uses. Its job,
// instructions, projects, notes and summaries are in the agent's other groups, as for any agent.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../api/agents_api.dart';
import 'service_names.g.dart';

/// A service's state in words (the page's `extWorks`, `extNeedsLogin`…).
String serviceState(AppLocalizations l, ServiceEntry s) => switch (s.state) {
  null => l.g4AgSvcChecking,
  'connected' => l.g4AgSvcWorks(s.tools),
  'login' => l.g4AgSvcLogin,
  _ => l.g4AgSvcBroken,
};

/// A service's name as the page's catalog says it (MCP_CATALOG); others as they are.
String serviceName(String id) => serviceNames[id] ?? id;

/// The kinds of schedule a routine made here may have (the page's editor has them all).
enum RoutineEvery { daily, weekdays, weekly, hourly }

/// The cron of a schedule (the page's `toCron`): «09:00» every day, on weekdays, on Mondays, or
/// every hour on the hour.
String routineCron(RoutineEvery e, String time) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time.trim());
  final h = m == null ? 9 : int.parse(m.group(1)!).clamp(0, 23);
  final min = m == null ? 0 : int.parse(m.group(2)!).clamp(0, 59);
  return switch (e) {
    RoutineEvery.daily => '$min $h * * *',
    RoutineEvery.weekdays => '$min $h * * 1-5',
    RoutineEvery.weekly => '$min $h * * 1',
    RoutineEvery.hourly => '0 * * * *',
  };
}

String _q(String s) => _json(s);
String _json(String s) {
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

/// A routine's recipe as YAML, as the page's editor writes it (strings quoted as JSON).
String routineYaml({
  required Agent agent,
  required String title,
  required String instructions,
  required String cron,
  required String stamp,
}) {
  final slug = agent.name
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final name = 'routine-${slug.isEmpty ? 'agent' : slug}-$stamp';
  return [
    'name: ${_q(name)}',
    'description: ${_q(title)}',
    'on:',
    '  cron: ${_q(cron)}',
    'agent: ${_q(agent.id)}',
    'instructions: ${_q(instructions)}',
    '',
  ].join('\n');
}

/// The cron of a routine in words, for the four schedules made here; others as they are.
String routineWhen(AppLocalizations l, Routine r) {
  final c = r.cron;
  if (r.at != null) return l.g4AgRoutineOnce(r.at!.replaceFirst('T', ' '));
  if (c == null) return '';
  if (c == '0 * * * *') return l.g4AgEvery_hourly;
  final m = RegExp(r'^(\d+) (\d+) \* \* (\*|1-5|1)$').firstMatch(c);
  if (m == null) return c;
  final t = '${m.group(2)!.padLeft(2, '0')}:${m.group(1)!.padLeft(2, '0')}';
  return switch (m.group(3)) {
    '*' => l.g4AgWhenDaily(t),
    '1-5' => l.g4AgWhenWeekdays(t),
    _ => l.g4AgWhenWeekly(t),
  };
}

class AssistantGroup extends StatefulWidget {
  const AssistantGroup({super.key, required this.agent, this.readOnly = false});

  final Agent agent;
  final bool readOnly;

  @override
  State<AssistantGroup> createState() => _AssistantGroupState();
}

class _AssistantGroupState extends State<AssistantGroup> {
  List<ServiceEntry>? _services;
  List<Routine>? _routines;
  List<SkillEntry>? _skills;
  late final Set<String> _on = {...widget.agent.connections};
  String? _said;
  bool _bad = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  RedGiantClient? get _c => AppScope.read(context).client;

  Future<void> _load() async {
    final c = _c;
    if (c == null) return;
    Future<T?> soft<T>(Future<T> f) async {
      try {
        return await f;
      } on ApiException {
        return null;
      }
    }

    final r = await Future.wait<Object?>([
      soft(c.assistantServices()),
      soft(c.routinesOf(widget.agent)),
      soft(c.platformSkills()),
    ]);
    if (!mounted) return;
    setState(() {
      _services = r[0] as List<ServiceEntry>? ?? const [];
      _routines = r[1] as List<Routine>? ?? const [];
      _skills = r[2] as List<SkillEntry>? ?? const [];
    });
  }

  void _say(String t, {bool bad = false}) => setState(() {
    _said = t;
    _bad = bad;
  });

  bool get _changed {
    final was = {...widget.agent.connections};
    return was.length != _on.length || !was.containsAll(_on);
  }

  Future<void> _saveServices() async {
    final l = AppLocalizations.of(context);
    final why = await AppScope.read(context)
        .saveAgent(widget.agent, {'connections': (_on.toList()..sort())});
    if (!mounted) return;
    why == null ? _say(l.g4AgSavedNewChats) : _say(l.asRefused(why), bad: true);
  }

  bool _skillOn(String name) => widget.agent.skills == null || widget.agent.skills!.contains(name);

  Future<void> _skill(String name, bool want) async {
    final l = AppLocalizations.of(context);
    final all = [for (final s in _skills ?? const <SkillEntry>[]) s.name];
    final current = all.where(_skillOn).toList();
    final next = want ? {...current, name}.toList() : current.where((n) => n != name).toList();
    final why = await AppScope.read(context)
        .saveAgent(widget.agent, {'skills': next.length == all.length ? null : next});
    if (!mounted) return;
    why == null ? _say(l.g4AgSavedNewChats) : _say(l.asRefused(why), bad: true);
  }

  Future<void> _routineOn(Routine r, bool on) async {
    final l = AppLocalizations.of(context);
    try {
      await _c!.setRoutineOn(r.id, on);
      final list = await _c!.routinesOf(widget.agent);
      if (mounted) setState(() => _routines = list);
    } on ApiException catch (e) {
      _say(l.asRefused(e.message), bad: true);
    }
  }

  Future<void> _newRoutine() async {
    final made = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RoutineSheet(agent: widget.agent),
    );
    if (made == true) {
      final list = await _c?.routinesOf(widget.agent);
      if (mounted && list != null) setState(() => _routines = list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final ro = widget.readOnly;
    Widget wait() => const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
    return Column(
      key: const Key('as-assistant'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_said != null)
          NoticeBanner(key: const Key('as-assistant-note'), text: _said!, error: _bad),
        SectionHead(l.g4AgServices),
        _help(context, l.g4AgServicesHelp),
        SettingsCard(
          children: [
            if (_services == null)
              wait()
            else if (_services!.isEmpty)
              NoteLine(icon: RgIcons.layers, text: l.g4AgNoServices)
            else
              for (final s in _services!)
                InkWell(
                  key: Key('as-service-${s.name}'),
                  onTap: ro
                      ? null
                      : () => setState(
                          () => _on.contains(s.name) ? _on.remove(s.name) : _on.add(s.name),
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                serviceName(s.name),
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                              ),
                              Text(
                                serviceState(l, s),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: s.state == 'connected'
                                      ? c.ok
                                      : s.state == null
                                      ? c.dim
                                      : c.warn,
                                ),
                              ),
                            ],
                          ),
                        ),
                        RgSwitch(on: _on.contains(s.name)),
                      ],
                    ),
                  ),
                ),
            NoteLine(icon: RgIcons.info, text: l.g4AgAddServiceHint),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const Key('as-save-services'),
              onPressed: !ro && _changed ? _saveServices : null,
              child: Text(l.save),
            ),
          ),
        ),
        SectionHead(l.g4AgRoutines),
        _help(context, l.g4AgRoutinesHelp),
        SettingsCard(
          children: [
            if (_routines == null)
              wait()
            else if (_routines!.isEmpty)
              NoteLine(icon: RgIcons.clock, text: l.g4AgNoRoutines)
            else
              for (final r in _routines!)
                InkWell(
                  key: Key('as-routine-${r.id}'),
                  onTap: ro ? null : () => _routineOn(r, !r.enabled),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        RgIcon(RgIcons.clock, size: 18, color: r.enabled ? c.accent : c.dim),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.title,
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                              ),
                              Text(
                                [
                                  routineWhen(l, r),
                                  r.enabled ? l.g4AgOn : l.g4AgOff,
                                ].where((x) => x.isNotEmpty).join(' · '),
                                style: TextStyle(fontSize: 12.5, color: c.dim),
                              ),
                            ],
                          ),
                        ),
                        RgSwitch(on: r.enabled),
                      ],
                    ),
                  ),
                ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              key: const Key('as-new-routine'),
              onPressed: ro ? null : _newRoutine,
              icon: RgIcon(RgIcons.plus, size: 16, color: ro ? c.dim : c.text),
              label: Text(l.g4AgNewRoutine),
            ),
          ),
        ),
        if (_skills != null && _skills!.isNotEmpty) ...[
          SectionHead(l.g4AgSkills),
          _help(context, l.g4AgSkillsHelp),
          SettingsCard(
            children: [
              for (final s in _skills!)
                InkWell(
                  key: Key('as-skill-${s.name}'),
                  onTap: ro ? null : () => _skill(s.name, !_skillOn(s.name)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.name,
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                              ),
                              if (s.description.isNotEmpty)
                                Text(s.description, style: TextStyle(fontSize: 12.5, color: c.dim)),
                            ],
                          ),
                        ),
                        RgSwitch(on: _skillOn(s.name)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

Widget _help(BuildContext context, String text) {
  final c = RgColors.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(text, style: TextStyle(color: c.dim, fontSize: 13, height: 1.35)),
  );
}

/// «New routine»: what it does, how often, at what time; then `POST /api/automations`.
class RoutineSheet extends StatefulWidget {
  const RoutineSheet({super.key, required this.agent});

  final Agent agent;

  @override
  State<RoutineSheet> createState() => _RoutineSheetState();
}

class _RoutineSheetState extends State<RoutineSheet> {
  final _title = TextEditingController();
  final _what = TextEditingController();
  final _time = TextEditingController(text: '09:00');
  RoutineEvery _every = RoutineEvery.daily;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final t in [_title, _what, _time]) {
      t.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final t in [_title, _what, _time]) {
      t.dispose();
    }
    super.dispose();
  }

  bool get _timeOk => RegExp(r'^([01]?\d|2[0-3]):[0-5]\d$').hasMatch(_time.text.trim());

  bool get _ok =>
      _what.text.trim().isNotEmpty && (_every == RoutineEvery.hourly || _timeOk) && !_busy;

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final what = _what.text.trim();
    final title = _title.text.trim().isEmpty
        ? (what.split('\n').first.length > 80
              ? what.split('\n').first.substring(0, 80)
              : what.split('\n').first)
        : _title.text.trim();
    try {
      await c.createRoutine(
        routineYaml(
          agent: widget.agent,
          title: title,
          instructions: what,
          cron: routineCron(_every, _time.text),
          stamp: DateTime.now().millisecondsSinceEpoch.toRadixString(36).substring(4),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = l.asRefused(e.message);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
            maxWidth: 640,
          ),
          child: ListView(
            key: const Key('routine-sheet'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  l.g4AgNewRoutineOf(widget.agent.name),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                ),
              ),
              if (_error != null)
                NoticeBanner(key: const Key('routine-error'), text: _error!, error: true),
              SectionHead(l.g4AgRoutineWhat),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const Key('routine-what'),
                  controller: _what,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(hintText: l.g4AgRoutineWhatHint),
                ),
              ),
              SectionHead(l.g4AgRoutineTitle),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  key: const Key('routine-title'),
                  controller: _title,
                  maxLength: 80,
                ),
              ),
              SectionHead(l.g4AgRoutineWhen),
              SettingsCard(
                children: [
                  for (final (e, t) in [
                    (RoutineEvery.daily, l.g4AgEvery_daily),
                    (RoutineEvery.weekdays, l.g4AgEvery_weekdays),
                    (RoutineEvery.weekly, l.g4AgEvery_weekly),
                    (RoutineEvery.hourly, l.g4AgEvery_hourly),
                  ])
                    PickRow(
                      key: Key('routine-every-${e.name}'),
                      title: t,
                      selected: _every == e,
                      onTap: () => setState(() => _every = e),
                    ),
                ],
              ),
              if (_every != RoutineEvery.hourly)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    key: const Key('routine-time'),
                    controller: _time,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      labelText: l.g4AgRoutineTime,
                      errorText: _timeOk ? null : l.g4AgRoutineTimeBad,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('routine-cancel'),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      key: const Key('routine-save'),
                      onPressed: _ok ? _save : null,
                      child: Text(l.g4AgRoutineSave),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
