// Tool groups (3.9.4, the page's `ToolKits.tsx`; decision «Strumenti spenti di serie, accesi a
// gruppi quando servono»): each kit with what it holds, what it weighs when on and its state: off by
// default (the agent switches it on itself when the work needs it), always on, or off by the person
// (the agent has to ask). For every agent, or for one agent (its own choice, or as for everyone).
import 'dart:async';

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/tool_words.g.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import 'api/rules_api.dart';
import 'rules_kit.dart';
import 'tools_screen.dart' show aboutTokens;

String _w(AppLocalizations l, String key, [String fallback = '']) =>
    toolWords[l.localeName.startsWith('it') ? 'it' : 'en']?[key] ?? fallback;

/// A kit's name and what it holds, in the page's words.
String kitName(AppLocalizations l, String id) => _w(l, 'kit_$id', id);
String kitDoes(AppLocalizations l, String id) => _w(l, 'kitDo_$id');

String kitStateWord(AppLocalizations l, String s) => switch (s) {
  'on' => l.tkOn,
  'off' => l.tkOff,
  _ => l.tkAuto,
};

/// The kits of a tools view: each choice is sent at once, then the view is read again.
class ToolKitsSection extends StatefulWidget {
  const ToolKitsSection({
    super.key,
    required this.view,
    required this.onView,
    required this.onError,
    required this.reload,
    this.agentName,
  });

  final ToolsView view;
  final ValueChanged<ToolsView> onView;
  final ValueChanged<String> onError;
  final Future<void> Function() reload;
  final String? agentName;

  @override
  State<ToolKitsSection> createState() => _ToolKitsSectionState();
}

class _ToolKitsSectionState extends State<ToolKitsSection> {
  bool _busy = false;

  Future<void> _pick(KitView k, String pick) async {
    final c = AppScope.read(context).client;
    final v = widget.view;
    if (c == null || _busy) return;
    // For every agent, choosing the default clears the choice.
    final send = v.agentId == null && pick == k.byDefault ? 'default' : pick;
    widget.onView(v.withKit(k.id, send == 'default' ? null : send));
    setState(() => _busy = true);
    try {
      if (v.agentId != null) {
        await c.setAgentKits(v.agentId!, {k.id: send});
      } else {
        await c.setKits({k.id: send});
      }
    } on Exception catch (e) {
      widget.onError(rulesWhy(e));
    } finally {
      if (mounted) setState(() => _busy = false);
      await widget.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final v = widget.view;
    if (v.kits.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('tl-kits'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(
          title: l.tkTitle,
          lead: widget.agentName != null ? l.tkAgentLead(widget.agentName!) : l.tkLead,
          icon: RgIcons.layers,
        ),
        if (v.essential != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                RgIcon(RgIcons.lock, size: 14, color: c.dim),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.tkEssential(aboutTokens(l, v.essential!)),
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        for (final k in v.kits)
          _KitCard(k: k, forAgent: v.agentId != null, busy: _busy, onPick: (p) => _pick(k, p)),
      ],
    );
  }
}

class _KitCard extends StatelessWidget {
  const _KitCard({
    required this.k,
    required this.forAgent,
    required this.busy,
    required this.onPick,
  });

  final KitView k;
  final bool forAgent;
  final bool busy;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final on = k.state == 'on';
    final stateColor = switch (k.state) {
      'on' => c.accent,
      'off' => c.warnText,
      _ => c.dim,
    };
    String mark(String id, String text) =>
        !forAgent && id == k.byDefault ? '$text (${l.tkIsDefault})' : text;
    final options = <(String, String)>[
      if (forAgent) ('default', l.tkAsAll(kitStateWord(l, k.global ?? k.byDefault))),
      ('auto', mark('auto', l.tkAuto)),
      ('on', mark('on', l.tkOn)),
      ('off', mark('off', l.tkOff)),
    ];
    final names = [for (final e in k.entries) _w(l, 'tool_$e', e)].join(', ');
    return Padding(
      key: Key('tl-kit-${k.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: on ? c.accentSoft : c.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? c.accent : c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  kitName(l, k.id),
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14.5),
                ),
                Container(
                  key: Key('tl-kit-${k.id}-state'),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: stateColor),
                  ),
                  child: Text(
                    kitStateWord(l, k.state),
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (kitDoes(l, k.id).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  kitDoes(l, k.id),
                  style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                [
                  l.tkWeight(aboutTokens(l, k.tokens)),
                  if (k.byDefault == 'on' && k.id != 'core') l.tkRole,
                ].join(' · '),
                style: TextStyle(color: c.dim, fontSize: 11.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(l.tkTools(names), style: TextStyle(color: c.dim, fontSize: 11.5)),
            ),
            const SizedBox(height: 10),
            Opacity(
              opacity: busy ? .7 : 1,
              child: RgChoice<String>(
                options: options,
                value: forAgent ? (k.own ?? 'default') : k.state,
                keyOf: (v) => 'tl-kit-${k.id}-$v',
                onChanged: busy ? null : onPick,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An agent's kits in its window (the page's `AgentTools` heading): read on its own.
class AgentKits extends StatefulWidget {
  const AgentKits({super.key, required this.agentId, required this.agentName});

  final String agentId;
  final String agentName;

  @override
  State<AgentKits> createState() => _AgentKitsState();
}

class _AgentKitsState extends State<AgentKits> {
  ToolsView? _view;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final v = await c.toolsView(agentId: widget.agentId);
      if (mounted) setState(() => _view = v);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = _view;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) RulesLoading(error: l.g4TlError(_error!)),
          if (v != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${l.tkStartTotal(aboutTokens(l, v.total))} · ${l.tkRest(aboutTokens(l, v.saved))}',
                key: const Key('as-kits-total'),
                style: TextStyle(color: RgColors.of(context).dim, fontSize: 12.5),
              ),
            ),
            ToolKitsSection(
              view: v,
              onView: (n) => setState(() => _view = n),
              onError: (e) => setState(() => _error = e),
              reload: _load,
              agentName: widget.agentName,
            ),
          ],
        ],
      ),
    );
  }
}
