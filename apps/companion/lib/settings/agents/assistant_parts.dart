// G42.4: what only a personal assistant has (the page's AssistantPage, Assistants.tsx): the
// services it may use (MCP servers added for everyone, each with its state), its routines (work
// it does by itself at a set time: on or off, and a new one), and the skills it uses. Its job,
// instructions, projects, notes and summaries are in the agent's other groups, as for any agent.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/conversation.dart' show Project;
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/icons.dart';
import '../../ui/settings_kit.dart';
import '../automations/automation_draft.dart' show WhoOption, whoOptions;
import '../automations/automation_editor.dart';
import '../automations/automation_types.dart';
import '../automations/automations_screen.dart' show openAutomation, recipeWhen;
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

/// A routine's schedule in words, as the page's `recipeWhen` (Automations.tsx), without the
/// sentence's full stop (it is followed by «on» or «off» in the row).
String routineWhen(AppLocalizations l, Routine r, List<WhoOption> who, List<Project> projects) {
  final w = recipeWhen(l, Automation.fromJson(r.raw), who, projects);
  return w.endsWith('.') ? w.substring(0, w.length - 1) : w;
}

class AssistantGroup extends StatefulWidget {
  const AssistantGroup({super.key, required this.agent, this.readOnly = false});

  final Agent agent;
  final bool readOnly;

  @override
  State<AssistantGroup> createState() => _AssistantGroupState();
}

class _AssistantGroupState extends State<AssistantGroup> {
  List<Routine>? _routines;
  List<SkillEntry>? _skills;
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
      soft(c.routinesOf(widget.agent)),
      soft(c.platformSkills()),
    ]);
    if (!mounted) return;
    setState(() {
      _routines = r[0] as List<Routine>? ?? const [];
      _skills = r[1] as List<SkillEntry>? ?? const [];
    });
  }

  void _say(String t, {bool bad = false}) => setState(() {
    _said = t;
    _bad = bad;
  });

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
    final l = AppLocalizations.of(context);
    // The same editor as Settings › Automations, with this assistant already chosen (G42.9).
    final made = await openAutomationEditor(
      context,
      title: l.auAsstNewRoutine,
      who: 'p:${widget.agent.id}',
    );
    if (made != null) await _reloadRoutines();
  }

  Future<void> _reloadRoutines() async {
    final list = await _c?.routinesOf(widget.agent);
    if (mounted && list != null) setState(() => _routines = list);
  }

  /// A routine's window: its switch, its runs, «Run now», change it, delete it.
  Future<void> _openRoutine(Routine r) async {
    await openAutomation(
      context,
      Automation.fromJson(r.raw),
      onChanged: () => unawaited(_reloadRoutines()),
    );
    await _reloadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final ro = widget.readOnly;
    final app = AppScope.of(context);
    final who = whoOptions(l, app.agents);
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
                                  routineWhen(l, r, who, app.projects),
                                  r.enabled ? l.g4AgOn : l.g4AgOff,
                                ].where((x) => x.isNotEmpty).join(' · '),
                                style: TextStyle(fontSize: 12.5, color: c.dim),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: Key('as-routine-open-${r.id}'),
                          tooltip: l.auOwnRoutineOpen,
                          onPressed: ro ? null : () => _openRoutine(r),
                          icon: RgIcon(RgIcons.pencil, size: 17, color: c.dim),
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
