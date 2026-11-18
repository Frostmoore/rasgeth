// How many agents a project may have besides its orchestrator (2026-11-18, the person: «un'opzione
// sia nella web app che nelle app companion per poter limitare i sotto-agenti di ciascun progetto.
// Default 3, e posso arrivare a 0»). The page's `AgentLimitControl` (ProjectAgentLimit.tsx): a
// slider in steps, 0 to 10, saved when the finger lets go (one change in the history, undoable);
// the line under it says how many count now and, over the limit, that nobody is removed. In the
// project's menu (its window) and in the project's view.
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/conversation.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'dialogs.dart';
import 'icons.dart';

/// «2 agents», «1 agent», «none».
String agentsWord(AppLocalizations l, int n) =>
    n == 0 ? l.palNone : (n == 1 ? l.palOne : l.palN('$n'));

/// The server's refusal in the person's words: `agent_limit` (2026-11-18), else its message.
String apiErrorText(AppLocalizations l, ApiException e) => e.code == 'agent_limit'
    ? l.errAgentLimit(e.vars['project'] ?? '', e.vars['max'] ?? '', e.vars['count'] ?? '')
    : e.message;

/// The slider for [project], with the line under it.
class AgentLimitTile extends StatefulWidget {
  const AgentLimitTile({super.key, required this.project});

  final Project project;

  @override
  State<AgentLimitTile> createState() => _AgentLimitTileState();
}

class _AgentLimitTileState extends State<AgentLimitTile> {
  late int _value = widget.project.maxAgents;
  bool _saved = false;
  String? _error;

  @override
  void didUpdateWidget(AgentLimitTile old) {
    super.didUpdateWidget(old);
    // The server's value when it changes elsewhere (the page, an undo).
    if (old.project.maxAgents != widget.project.maxAgents) _value = widget.project.maxAgents;
  }

  Future<void> _save(int n) async {
    if (n == widget.project.maxAgents) return;
    final err = await AppScope.read(context).setProjectMaxAgents(widget.project.id, n);
    if (!mounted) return;
    setState(() {
      _saved = err == null;
      _error = err;
      if (err != null) _value = widget.project.maxAgents;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = widget.project;
    final count = p.agents ?? 0;
    final words = _value == 0 ? l.palZero : '$_value';
    return Padding(
      key: Key('agent-limit-${p.id}'),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RgIcon(RgIcons.users, size: 16, color: c.dim),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.palTitle,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: c.accentSoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$_value',
                  key: Key('agent-limit-value-${p.id}'),
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Slider(
            key: Key('agent-limit-slider-${p.id}'),
            value: _value.clamp(0, Project.projectAgentsMax).toDouble(),
            max: Project.projectAgentsMax.toDouble(),
            divisions: Project.projectAgentsMax,
            activeColor: c.accent,
            inactiveColor: c.line,
            label: words,
            semanticFormatterCallback: (v) => v.round() == 0 ? l.palZero : '${v.round()}',
            onChanged: (v) => setState(() {
              _value = v.round();
              _saved = false;
              _error = null;
            }),
            onChangeEnd: (v) => _save(v.round()),
          ),
          // The ends, as the page's slider: 0 in words, 10.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(l.palZero, style: TextStyle(color: c.dim, fontSize: 12)),
                ),
                Text('${Project.projectAgentsMax}', style: TextStyle(color: c.dim, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${l.palHelp} ${l.palNow(agentsWord(l, count))}',
            style: TextStyle(color: c.dim, fontSize: 12.5),
          ),
          if (count > _value)
            Container(
              key: Key('agent-limit-over-${p.id}'),
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.warn.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.warn.withValues(alpha: .5)),
              ),
              child: Text(
                l.palOver(agentsWord(l, count), '$_value'),
                style: TextStyle(color: c.warnText, fontSize: 13),
              ),
            ),
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l.palSaved,
                key: Key('agent-limit-saved-${p.id}'),
                style: TextStyle(color: c.dim, fontSize: 12.5),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_error!, style: TextStyle(color: c.err, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

/// The project menu's «Agents at most»: the same slider in our window.
Future<void> askProjectAgentLimit(BuildContext context, Project p) => showRgWindow<void>(
  context: context,
  builder: (context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('agent-limit-window'),
      title: Text(p.name),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      content: SizedBox(
        width: 460,
        // The project as the app reads it now: the count and the value after a save.
        child: Builder(
          builder: (context) {
            final app = AppScope.of(context);
            final now = app.projects.where((x) => x.id == p.id).firstOrNull ?? p;
            return AgentLimitTile(project: now);
          },
        ),
      ),
      actions: [
        TextButton(
          key: const Key('agent-limit-close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.close),
        ),
      ],
    );
  },
);
