// Every setting of one agent (G38.7, the person: «tutte quelle che odio modificare dalla pagina
// agenti delle impostazioni»), the page's Settings › Agents window grouped as its tabs: general
// (mascot, name, job, projects, stop), model and way (model, mode, instructions), memory (its
// notes, its project's, summaries), spending, tools, knowledge. A panel on a computer, a whole
// screen on a phone. Everything goes through the page's own routes and the server's rules; God
// and the Chat keep theirs (God's face is drawn by hand and God never stops; the Chat has its own
// model and instructions and never stops; essential tools never switch off; an open
// conversation's model is changed only by the person, from its composer).
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/budgets.dart';
import '../api/client.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/tool_words.g.dart';
import '../mascot/mascot_view.dart';
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/remove_agent.dart';
import '../ui/settings_kit.dart';
import 'instructions_screen.dart';
import 'new_agent_screen.dart' show RgSwitch;
import 'team_screen.dart' show AgentModelRow;

/// Opens [a]'s settings: a panel over the window on a computer, a whole screen on a phone.
Future<void> openAgentSettings(BuildContext context, Agent a) {
  final size = MediaQuery.sizeOf(context);
  if (size.width >= 760) {
    return showRgWindow<void>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(28),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 780, maxHeight: size.height * .9),
          child: AgentSettingsScreen(agentId: a.id, agent: a, panel: true),
        ),
      ),
    );
  }
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AgentSettingsScreen(agentId: a.id, agent: a),
    ),
  );
}

enum AgentGroup { general, work, memory, limits, tools, knowledge }

/// The groups [a] has (as the page's tabs: Demi-God keeps no memory nor knowledge).
List<AgentGroup> groupsOf(Agent a) => a.kind == AgentKind.demigod
    ? const [AgentGroup.general, AgentGroup.work, AgentGroup.limits, AgentGroup.tools]
    : AgentGroup.values;

class AgentSettingsScreen extends StatefulWidget {
  const AgentSettingsScreen({
    super.key,
    required this.agentId,
    required this.agent,
    this.panel = false,
    this.initial = AgentGroup.general,
  });

  final String agentId;

  /// As it was when opened (the team's own record follows it once saved).
  final Agent agent;
  final bool panel;
  final AgentGroup initial;

  @override
  State<AgentSettingsScreen> createState() => _AgentSettingsScreenState();
}

class _AgentSettingsScreenState extends State<AgentSettingsScreen> {
  late AgentGroup _group = widget.initial;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final a = app.agents.where((x) => x.id == widget.agentId).firstOrNull ?? widget.agent;
        final groups = groupsOf(a);
        final group = groups.contains(_group) ? _group : AgentGroup.general;
        final head = _Head(agent: a, panel: widget.panel);
        final tabs = _Tabs(
          groups: groups,
          selected: group,
          onSelect: (g) => setState(() => _group = g),
        );
        final body = KeyedSubtree(
          key: ValueKey('${a.id}-${group.name}'),
          child: switch (group) {
            AgentGroup.general => _General(agent: a),
            AgentGroup.work => _Work(agent: a),
            AgentGroup.memory => _Memory(agent: a),
            AgentGroup.limits => _Limits(agent: a),
            AgentGroup.tools => _Tools(agent: a),
            AgentGroup.knowledge => _Knowledge(agent: a),
          },
        );
        final list = ListView(
          key: const Key('agent-settings-list'),
          padding: const EdgeInsets.only(bottom: 28),
          children: [body],
        );
        if (widget.panel) {
          return Material(
            key: const Key('agent-settings-panel'),
            color: c.bg,
            child: Column(
              children: [
                head,
                tabs,
                Divider(height: 1, color: c.line),
                Expanded(child: list),
              ],
            ),
          );
        }
        return Scaffold(
          key: const Key('agent-settings-screen'),
          appBar: AppBar(
            leading: IconButton(
              key: const Key('agent-settings-back'),
              tooltip: l.back,
              onPressed: () => Navigator.of(context).pop(),
              icon: RgIcon(RgIcons.arrowLeft, color: c.text),
            ),
            title: Text(l.asTitle(a.name)),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  head,
                  tabs,
                  Divider(height: 1, color: c.line),
                  Expanded(child: list),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String kindWords(AppLocalizations l, AppController app, Agent a) {
  if (app.isChat(a)) return l.asKindChat;
  return switch (a.kind) {
    AgentKind.god => l.asKind_god,
    AgentKind.demigod => l.asKind_demigod,
    AgentKind.orchestrator => l.asKind_orchestrator,
    AgentKind.agent => l.asKind_agent,
    AgentKind.subagent => l.asKind_subagent,
    AgentKind.inspector => l.asKind_inspector,
    AgentKind.assistant => l.asKind_assistant,
  };
}

class _Head extends StatelessWidget {
  const _Head({required this.agent, required this.panel});

  final Agent agent;
  final bool panel;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = agent;
    final project = a.projectId == null
        ? null
        : app.projects.where((p) => p.id == a.projectId).firstOrNull?.name ?? a.projectId;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, panel ? 16 : 10, panel ? 8 : 16, 8),
      child: Row(
        children: [
          MascotView(
            agentId: a.id,
            spec: a.mascot,
            state: app.live.mascotStateOf(a.id),
            size: 52,
            label: a.name,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (panel)
                  Text(
                    l.asTitle(a.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
                  ),
                Text(
                  [kindWords(l, app, a), ?project].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.dim, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!a.active)
            Container(
              key: const Key('agent-settings-stopped'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: c.panel2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.line),
              ),
              child: Text(l.asStopped, style: TextStyle(color: c.dim, fontSize: 12)),
            ),
          if (panel)
            IconButton(
              key: const Key('agent-settings-close'),
              tooltip: l.asClose,
              onPressed: () => Navigator.of(context).pop(),
              icon: RgIcon(RgIcons.x, color: c.dim),
            ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.groups, required this.selected, required this.onSelect});

  final List<AgentGroup> groups;
  final AgentGroup selected;
  final ValueChanged<AgentGroup> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    (RgIcons, String) of(AgentGroup g) => switch (g) {
      AgentGroup.general => (RgIcons.user, l.asGroupGeneral),
      AgentGroup.work => (RgIcons.zap, l.asGroupWork),
      AgentGroup.memory => (RgIcons.bookmark, l.asGroupMemory),
      AgentGroup.limits => (RgIcons.activity, l.asGroupLimits),
      AgentGroup.tools => (RgIcons.tool, l.asGroupTools),
      AgentGroup.knowledge => (RgIcons.search, l.asGroupKnowledge),
    };
    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Row(
          children: [
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Semantics(
                  button: true,
                  selected: g == selected,
                  child: Material(
                    color: g == selected ? c.accentSoft : c.panel,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: g == selected ? c.accent : c.line),
                    ),
                    child: InkWell(
                      key: Key('agent-group-${g.name}'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onSelect(g),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RgIcon(of(g).$1, size: 15, color: g == selected ? c.accent : c.dim),
                            const SizedBox(width: 6),
                            Text(
                              of(g).$2,
                              style: TextStyle(
                                fontSize: 13,
                                color: c.text,
                                fontWeight: g == selected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---- Pieces ----

/// How the last save went: «Saved», or the server's own words.
class _Outcome {
  String? text;
  bool bad = false;

  void ok(String t) {
    text = t;
    bad = false;
  }

  void fail(String t) {
    text = t;
    bad = true;
  }
}

Widget _banner(_Outcome o, {Key? key}) => o.text == null
    ? const SizedBox.shrink()
    : NoticeBanner(key: key ?? const Key('agent-settings-note'), text: o.text!, error: o.bad);

Widget _help(BuildContext context, String text) {
  final c = RgColors.of(context);
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Text(text, style: TextStyle(color: c.dim, fontSize: 13, height: 1.35)),
  );
}

InputDecoration _field(RgColors c, {String? hint}) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: c.panel,
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c.line),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c.line),
  ),
);

class _SaveRow extends StatelessWidget {
  const _SaveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: children),
  );
}

/// One choice among a few, drawn (never a native radio button): a row of chips.
class _Choice<T> extends StatelessWidget {
  const _Choice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    required this.keyOf,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final String Function(T) keyOf;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (v, label) in options)
          Semantics(
            button: true,
            selected: v == value,
            child: Material(
              color: v == value ? c.accentSoft : c.panel2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: v == value ? c.accent : c.line),
              ),
              child: InkWell(
                key: Key(keyOf(v)),
                borderRadius: BorderRadius.circular(8),
                onTap: onChanged == null || v == value ? null : () => onChanged!(v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: v == value ? c.text : c.dim,
                      fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _why(Object e) => e is ApiException ? e.message : '$e';

// ---- General: mascot, name, job, projects, stop ----

class _General extends StatefulWidget {
  const _General({required this.agent});

  final Agent agent;

  @override
  State<_General> createState() => _GeneralState();
}

class _GeneralState extends State<_General> {
  late final _name = TextEditingController(text: widget.agent.name);
  late final _role = TextEditingController(text: widget.agent.role ?? '');
  final _out = _Outcome();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _role.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim() != widget.agent.name || _role.text.trim() != (widget.agent.role ?? '');

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final a = widget.agent;
    final name = _name.text.trim();
    final role = _role.text.trim();
    if (name.isEmpty) {
      setState(() => _out.fail(l.asNoName));
      return;
    }
    setState(() => _busy = true);
    final why = await app.saveAgent(a, {
      if (name != a.name) 'name': name,
      if (role.isNotEmpty && role != (a.role ?? '')) 'role': role,
    });
    if (!mounted) return;
    setState(() {
      _busy = false;
      why == null ? _out.ok(l.asSaved) : _out.fail(l.asRefused(why));
    });
  }

  Future<void> _assign(String projectId, bool on) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final next = {...widget.agent.projects};
    on ? next.add(projectId) : next.remove(projectId);
    final why = await app.saveAgent(widget.agent, {'projects': next.toList()});
    if (!mounted) return;
    setState(() => why == null ? _out.ok(l.asSavedNew) : _out.fail(l.asRefused(why)));
  }

  Future<void> _mascot() async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final a = widget.agent;
    final yes = await askConfirm(
      context,
      title: l.mascotChange,
      body: l.mascotChangeAsk(a.name),
      yes: l.mascotChangeYes,
    );
    if (!yes) return;
    final updated = await app.changeMascot(a);
    if (!mounted) return;
    setState(
      () => updated != null
          ? _out.ok(l.mascotChanged(a.name))
          : _out.fail(l.asRefused(l.statusUnreachable)),
    );
  }

  Future<void> _stop() async {
    final l = AppLocalizations.of(context);
    final app = AppScope.read(context);
    final a = widget.agent;
    final yes = await askConfirm(
      context,
      title: l.agentStop,
      body: l.asStopAsk(a.name),
      yes: l.asStopYes(a.name),
      danger: true,
    );
    if (!yes) return;
    final why = await app.stopAgentForGood(a);
    if (!mounted) return;
    setState(() => why == null ? _out.ok(l.asStoppedNow(a.name)) : _out.fail(l.asRefused(why)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = widget.agent;
    final god = a.kind == AgentKind.god;
    final chat = app.isChat(a);
    final assignable = a.kind == AgentKind.agent || a.kind == AgentKind.assistant;
    final others = app.projects.where((p) => p.id != a.projectId).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner(_out),
        SectionHead(l.asMascot),
        SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  MascotView(agentId: a.id, spec: a.mascot, size: 84, label: a.name),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          god ? l.asMascotGod : l.asMascotHelp,
                          style: TextStyle(color: c.dim, fontSize: 13, height: 1.35),
                        ),
                        if (!god && a.active) ...[
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            key: const Key('as-mascot'),
                            onPressed: _mascot,
                            icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
                            label: Text(l.mascotChange),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SectionHead(l.asName),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('as-name'),
            controller: _name,
            maxLength: 60,
            decoration: _field(c).copyWith(counterText: ''),
          ),
        ),
        SectionHead(l.asRole),
        _help(context, l.asRoleHelp),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            key: const Key('as-role'),
            controller: _role,
            minLines: 2,
            maxLines: 5,
            decoration: _field(c),
          ),
        ),
        _SaveRow(
          children: [
            FilledButton(
              key: const Key('as-save-general'),
              onPressed: _changed && !_busy ? _save : null,
              child: Text(l.save),
            ),
          ],
        ),
        if (assignable && others.isNotEmpty) ...[
          SectionHead(l.asProjects),
          _help(context, l.asProjectsHelp(a.name)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in others)
                  _ProjectChip(
                    key: Key('as-project-${p.id}'),
                    label: p.name,
                    on: a.projects.contains(p.id),
                    onTap: () => _assign(p.id, !a.projects.contains(p.id)),
                  ),
              ],
            ),
          ),
        ],
        if (!god && !chat && a.active) ...[
          SectionHead(l.asDanger),
          _help(context, l.asStopHelp),
          _SaveRow(
            children: [
              OutlinedButton.icon(
                key: const Key('as-stop'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.err,
                  side: BorderSide(color: c.err.withValues(alpha: .5)),
                ),
                onPressed: _stop,
                icon: RgIcon(RgIcons.stop, size: 16, color: c.err),
                label: Text(l.asStopYes(a.name)),
              ),
            ],
          ),
        ],
        // 3.8.9: out of the team with those below it (stopped or not); «Removed agents» restores.
        if (canRemoveAgent(app, a)) ...[
          if (!a.active) SectionHead(l.asDanger),
          _help(context, l.raHelp),
          _SaveRow(
            children: [
              OutlinedButton.icon(
                key: const Key('as-remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.err,
                  side: BorderSide(color: c.err.withValues(alpha: .5)),
                ),
                onPressed: () async {
                  if (await confirmRemoveAgent(context, a) && context.mounted) {
                    Navigator.of(context).maybePop();
                  }
                },
                icon: RgIcon(RgIcons.trash, size: 16, color: c.err),
                label: Text(l.raYes(a.name)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProjectChip extends StatelessWidget {
  const _ProjectChip({super.key, required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      toggled: on,
      button: true,
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: on ? c.accent : c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RgIcon(RgIcons.folder, size: 14, color: on ? c.accent : c.dim),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: c.text,
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Model and way: model, mode, instructions ----

class _Work extends StatefulWidget {
  const _Work({required this.agent});

  final Agent agent;

  @override
  State<_Work> createState() => _WorkState();
}

class _WorkState extends State<_Work> {
  final _out = _Outcome();

  Future<void> _mode(String m) async {
    final l = AppLocalizations.of(context);
    final why = await AppScope.read(context).saveAgent(widget.agent, {'mode': m});
    if (!mounted) return;
    setState(() => why == null ? _out.ok(l.asSaved) : _out.fail(l.asRefused(why)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = widget.agent;
    final mode = a.mode ?? 'auto';
    final help = app.isChat(a)
        ? l.asModelChatHelp
        : a.kind == AgentKind.god
        ? l.asModelGodHelp
        : l.asModelHelp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner(_out),
        SectionHead(l.agentModel),
        _help(context, help),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AgentModelRow(key: ValueKey('model-${a.id}'), agent: a, parent: context),
        ),
        SectionHead(l.asMode),
        _help(context, l.asModeHelp),
        SettingsCard(
          children: [
            for (final (m, title, text) in [
              ('auto', l.asMode_auto, l.asModeExplain_auto),
              ('manual', l.asMode_manual, l.asModeExplain_manual),
              ('plan', l.asMode_plan, l.asModeExplain_plan),
              ('readonly', l.asMode_readonly, l.asModeExplain_readonly),
            ])
              PickRow(
                key: Key('as-mode-$m'),
                title: title,
                subtitle: text,
                selected: mode == m,
                onTap: mode == m ? null : () => _mode(m),
              ),
          ],
        ),
        SectionHead(app.isChat(a) ? l.chatInstructions : l.agentInstructions),
        _help(context, l.asInstructionsHelp),
        SettingsCard(
          children: [
            ListTile(
              key: const Key('as-instructions'),
              leading: RgIcon(RgIcons.edit, size: 18, color: c.dim),
              title: Text(l.agentInstructionsRow, style: TextStyle(color: c.text)),
              trailing: RgIcon(RgIcons.chevronRight, size: 18, color: c.dim),
              onTap: () => openInstructions(context, a),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Memory: its notes, its project's, the summaries ----

class _Memory extends StatefulWidget {
  const _Memory({required this.agent});

  final Agent agent;

  @override
  State<_Memory> createState() => _MemoryState();
}

class _MemoryState extends State<_Memory> {
  final _out = _Outcome();
  ({double at, double keep})? _defaults;
  late int _at = ((widget.agent.compactAt ?? .8) * 100).round();
  late int _keep = ((widget.agent.compactKeep ?? .25) * 100).round();
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final d = await c.compactionDefaults(widget.agent.id);
      if (!mounted) return;
      setState(() {
        _defaults = d;
        if (!_touched && widget.agent.compactAt == null) _at = (d.at * 100).round();
        if (!_touched && widget.agent.compactKeep == null) _keep = (d.keep * 100).round();
      });
    } on ApiException {
      // The sliders keep the page's defaults.
    }
  }

  Future<void> _save({bool reset = false}) async {
    final l = AppLocalizations.of(context);
    final why = await AppScope.read(context).saveAgent(widget.agent, {
      'compaction': reset ? <String, Object?>{} : {'at': _at / 100, 'keep': _keep / 100},
    });
    if (!mounted) return;
    setState(() {
      if (why == null) {
        _out.ok(l.asSavedNew);
        if (reset) {
          _at = ((_defaults?.at ?? .8) * 100).round();
          _keep = ((_defaults?.keep ?? .25) * 100).round();
          _touched = false;
        }
      } else {
        _out.fail(l.asRefused(why));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final a = widget.agent;
    final remembers = a.kind != AgentKind.demigod && a.kind != AgentKind.inspector;
    final project = a.projectId == null
        ? null
        : app.projects.where((p) => p.id == a.projectId).firstOrNull?.name ?? a.projectId!;
    final d = _defaults;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner(_out),
        if (remembers)
          _Notes(
            key: const Key('as-notes-self'),
            agent: a,
            scope: 'self',
            title: l.asMemOwn(a.name),
            help: l.asMemOwnHelp(a.name),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(l.asMemNone, style: TextStyle(color: c.dim)),
          ),
        if (project != null)
          _Notes(
            key: const Key('as-notes-project'),
            agent: a,
            scope: 'project',
            projectId: a.projectId,
            title: l.asMemProject(project),
            help: l.asMemProjectHelp,
          ),
        SectionHead(l.asCompact),
        _help(context, l.asCompactHelp),
        SettingsCard(
          children: [
            _SliderRow(
              key: const Key('as-compact-at'),
              title: l.asCompactAt,
              value: _at,
              min: 50,
              max: 95,
              words: (n) => l.asCompactAtValue('$n'),
              onChanged: (v) => setState(() {
                _touched = true;
                _at = v;
              }),
            ),
            Divider(height: 1, color: c.line),
            _SliderRow(
              key: const Key('as-compact-keep'),
              title: l.asCompactKeep,
              value: _keep,
              min: 0,
              max: 50,
              words: (n) => n == 0 ? l.asCompactKeepNone : l.asCompactKeepValue('$n'),
              onChanged: (v) => setState(() {
                _touched = true;
                _keep = v;
              }),
            ),
          ],
        ),
        if (d != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l.asCompactDefaultIs('${(d.at * 100).round()}', '${(d.keep * 100).round()}'),
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
          ),
        _SaveRow(
          children: [
            OutlinedButton(
              key: const Key('as-compact-reset'),
              onPressed: () => _save(reset: true),
              child: Text(l.asCompactDefaults),
            ),
            FilledButton(key: const Key('as-save-compact'), onPressed: _save, child: Text(l.save)),
          ],
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.words,
    required this.onChanged,
  });

  final String title;
  final int value;
  final int min;
  final int max;
  final String Function(int) words;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    // Five by five, as the page's sliders; a server value between two notches stays as it is.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
                ),
              ),
              Text(
                words(value),
                style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ 5,
            activeColor: c.accent,
            inactiveColor: c.line,
            label: words(value),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _Notes extends StatefulWidget {
  const _Notes({
    super.key,
    required this.agent,
    required this.scope,
    required this.title,
    required this.help,
    this.projectId,
  });

  final Agent agent;
  final String scope;
  final String? projectId;
  final String title;
  final String help;

  @override
  State<_Notes> createState() => _NotesState();
}

class _NotesState extends State<_Notes> {
  final _text = TextEditingController();
  final _out = _Outcome();
  String? _kept;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    unawaited(_load());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    var text = '';
    try {
      text = await c?.notes(widget.scope, widget.agent.id, projectId: widget.projectId) ?? '';
    } on ApiException {
      // As the page: no notes yet reads as empty.
    }
    if (!mounted) return;
    setState(() {
      _kept = text;
      _text.text = text;
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      await c.setNotes(widget.scope, widget.agent.id, _text.text, projectId: widget.projectId);
      if (!mounted) return;
      setState(() {
        _kept = _text.text;
        _out.ok(l.asSaved);
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(l.asRefused(_why(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHead(widget.title),
        _help(context, widget.help),
        if (_kept == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: Key('as-notes-${widget.scope}-text'),
              controller: _text,
              minLines: 3,
              maxLines: 10,
              decoration: _field(c),
            ),
          ),
        _banner(_out, key: Key('as-notes-${widget.scope}-note')),
        _SaveRow(
          children: [
            FilledButton(
              key: Key('as-save-notes-${widget.scope}'),
              onPressed: _kept != null && _text.text != _kept ? _save : null,
              child: Text(l.save),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Spending: what it spent, its limit ----

class _Limits extends StatefulWidget {
  const _Limits({required this.agent});

  final Agent agent;

  @override
  State<_Limits> createState() => _LimitsState();
}

class _LimitsState extends State<_Limits> {
  final _usd = TextEditingController();
  final _out = _Outcome();
  Budget? _row;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _usd.addListener(() => setState(() {}));
    unawaited(_load());
  }

  @override
  void dispose() {
    _usd.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    try {
      final rows = await c?.budgets() ?? const <Budget>[];
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _row = rows.where((b) => b.scope == 'agent' && b.id == widget.agent.id).firstOrNull;
        final u = _row?.limitUsd;
        _usd.text = u == null ? '' : _money(u);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _out.fail(AppLocalizations.of(context).asLoadFailed(_why(e)));
        });
      }
    }
  }

  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  double? get _amount => double.tryParse(_usd.text.trim().replaceAll(',', '.'));

  Future<void> _save({bool remove = false}) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null) return;
    final n = _amount;
    if (!remove && (n == null || !(n > 0))) {
      setState(() => _out.fail(l.asLimitBad));
      return;
    }
    try {
      await c.setBudget('agent', widget.agent.id, usd: remove ? null : n);
      if (!mounted) return;
      _out.ok(l.asSaved);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(l.asRefused(_why(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final row = _row;
    final hasLimit = row?.limitUsd != null || row?.limitTokens != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner(_out),
        SectionHead(l.asSpent),
        _help(context, l.asLimitsHelp),
        if (!_loaded)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '\$${(row?.usedUsd ?? 0).toStringAsFixed(2)}',
              key: const Key('as-spent'),
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.text),
            ),
          ),
          SectionHead(l.asLimit),
          if (row?.limitUsd == null && row?.limitTokens != null)
            _help(context, l.asLimitTokens('${row!.limitTokens!.round()}')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('as-limit'),
              controller: _usd,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _field(c, hint: l.asNoLimit).copyWith(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 6),
                  child: Text(
                    '\$',
                    style: TextStyle(color: c.dim, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
          ),
          _SaveRow(
            children: [
              if (hasLimit)
                OutlinedButton(
                  key: const Key('as-limit-remove'),
                  onPressed: () => _save(remove: true),
                  child: Text(l.asRemoveLimit),
                ),
              FilledButton(
                key: const Key('as-save-limit'),
                onPressed: _usd.text.trim().isEmpty ? null : _save,
                child: Text(l.save),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ---- Tools: each as for every agent, always on, or off; the edits in open files ----

class _Tools extends StatefulWidget {
  const _Tools({required this.agent});

  final Agent agent;

  @override
  State<_Tools> createState() => _ToolsState();
}

class _ToolsState extends State<_Tools> {
  final _out = _Outcome();
  List<ToolEntry>? _tools;
  Map<String, dynamic>? _editor;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final tools = await c.agentTools(widget.agent.id);
      Map<String, dynamic>? editor;
      try {
        editor = await c.editorSettings();
      } on ApiException {
        editor = null;
      }
      if (mounted) {
        setState(() {
          _tools = tools;
          _editor = editor;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(AppLocalizations.of(context).asLoadFailed(_why(e))));
    }
  }

  Future<void> _choose(ToolEntry t, String pick) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null || t.essential) return;
    try {
      await c.setAgentTools(widget.agent.id, {t.id: pick});
      if (mounted) setState(() => _out.ok(l.asSavedNew));
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(l.asRefused(_why(e))));
    }
    await _load();
  }

  Future<void> _editRule(String mode) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    final s = _editor;
    if (c == null || s == null) return;
    final agents = {...((s['agents'] as Map?) ?? const {})}.cast<String, Object?>();
    mode == 'now' ? agents.remove(widget.agent.id) : agents[widget.agent.id] = mode;
    final next = {...s, 'agents': agents};
    try {
      await c.setEditorSettings(next);
      if (mounted) {
        setState(() {
          _editor = next;
          _out.ok(l.asSaved);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(l.asRefused(_why(e))));
    }
  }

  String _word(AppLocalizations l, String key, String fallback) =>
      toolWords[l.localeName.startsWith('it') ? 'it' : 'en']?[key] ?? fallback;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final tools = _tools;
    final editor = _editor;
    final total = tools?.where((t) => t.on).fold<int>(0, (n, t) => n + t.tokens) ?? 0;
    final groups = <String, List<ToolEntry>>{};
    for (final t in tools ?? const <ToolEntry>[]) {
      (groups[t.group] ??= []).add(t);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner(_out),
        if (editor != null) ...[
          SectionHead(l.asEditRule),
          _help(context, l.asEditRuleHelp),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _Choice<String>(
              options: [('now', l.asEditNow), ('propose', l.asEditPropose)],
              value: ((editor['agents'] as Map?)?[widget.agent.id] as String?) ?? 'now',
              keyOf: (v) => 'as-edit-$v',
              onChanged: _editRule,
            ),
          ),
        ],
        SectionHead(l.asGroupTools),
        _help(context, l.asToolsHelp),
        if (tools == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else ...[
          if (total > 0)
            _help(context, l.asToolsTotal(widget.agent.name, '${(total / 100).round() * 100}')),
          NoteLine(icon: RgIcons.help, text: l.asToolsNewOnly),
          for (final g in groups.entries) ...[
            SectionHead(_word(l, 'toolGrp_${g.key}', g.key)),
            SettingsCard(
              children: [
                for (final (i, t) in g.value.indexed) ...[
                  if (i > 0) Divider(height: 1, color: c.line),
                  Padding(
                    key: Key('as-tool-${t.id}'),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _word(l, 'tool_${t.id}', t.id),
                                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                              ),
                            ),
                            RgSwitch(on: t.on),
                          ],
                        ),
                        if (_word(l, 'toolDo_${t.id}', '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _word(l, 'toolDo_${t.id}', ''),
                              style: TextStyle(color: c.dim, fontSize: 12.5),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (t.essential)
                          Row(
                            key: Key('as-tool-${t.id}-locked'),
                            children: [
                              RgIcon(RgIcons.lock, size: 14, color: c.dim),
                              const SizedBox(width: 6),
                              Text(l.asToolLocked, style: TextStyle(color: c.dim, fontSize: 12.5)),
                            ],
                          )
                        else
                          _Choice<String>(
                            options: [
                              ('default', t.globalOn ? l.asToolDefaultOn : l.asToolDefaultOff),
                              ('on', l.asToolAlways),
                              ('off', l.asToolOff),
                            ],
                            value: t.own ?? 'default',
                            keyOf: (v) => 'as-tool-${t.id}-$v',
                            onChanged: (v) => _choose(t, v),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ],
    );
  }
}

// ---- Knowledge: the collections it reads ----

class _Knowledge extends StatefulWidget {
  const _Knowledge({required this.agent});

  final Agent agent;

  @override
  State<_Knowledge> createState() => _KnowledgeState();
}

class _KnowledgeState extends State<_Knowledge> {
  final _out = _Outcome();
  List<AgentCollection>? _list;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final list = await c.agentKnowledge(widget.agent.id);
      if (mounted) setState(() => _list = list);
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(AppLocalizations.of(context).asLoadFailed(_why(e))));
    }
  }

  Future<void> _choose(AgentCollection col, String pick) async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final list = await c.setAgentKnowledge(
        widget.agent.id,
        col.id,
        pick == 'default' ? null : pick,
      );
      if (mounted) {
        setState(() {
          _list = list;
          _out.ok(l.asSavedNew);
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _out.fail(l.asRefused(_why(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final list = _list;
    String scope(String s) => switch (s) {
      'agent' => l.asKbScope_agent,
      'project' => l.asKbScope_project,
      _ => l.asKbScope_global,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _banner(_out),
        SectionHead(l.asGroupKnowledge),
        _help(context, l.asKbHelp(widget.agent.name)),
        if (list == null && _out.text == null)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (list != null && list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(l.asKbNone, style: TextStyle(color: c.dim)),
          )
        else if (list != null)
          SettingsCard(
            children: [
              for (final (i, col) in list.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.line),
                Padding(
                  key: Key('as-kb-${col.id}'),
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              col.name,
                              style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                            ),
                          ),
                          RgSwitch(on: col.on),
                        ],
                      ),
                      Text(scope(col.scope), style: TextStyle(color: c.dim, fontSize: 12.5)),
                      const SizedBox(height: 8),
                      _Choice<String>(
                        options: [
                          ('default', l.asKbByScope(col.byScope ? l.asKbOn : l.asKbOff)),
                          ('on', l.asKbOn),
                          ('off', l.asKbOff),
                        ],
                        value: col.own ?? 'default',
                        keyOf: (v) => 'as-kb-${col.id}-$v',
                        onChanged: (v) => _choose(col, v),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}
