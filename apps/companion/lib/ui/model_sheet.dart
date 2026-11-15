// The model of an agent, of the Chat or of one conversation (3.8.1): the families with the drawn
// choice of the way (Subscription / API key, G40.9b) and a line on what it means, the effort when
// the model takes one, and «the same as above» (the agent's, the parent's or the default). The
// sheet only chooses: the caller saves with the page's own API.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/model_routes.dart';
import '../api/settings_types.dart';
import '../api/types.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import 'icons.dart';
import 'words.dart';

/// What the sheet gave back: a model, or none (follow the one above).
class ModelPick {
  const ModelPick(this.model);
  final AgentModel? model;
}

/// A model in words: «Sonnet 5 · Abbonamento · Medio».
String modelWords(AppLocalizations l, List<ModelChoice> choices, AgentModel m) {
  final at = familyOf(modelFamilies(choices), m.key);
  final name = at == null ? modelName(m.model) : at.$1.label;
  final way = at == null ? null : wayWord(l, at.$1.ways[at.$2]);
  return [name, ?way, if (m.effort != null) effortWord(l, m.effort!)].join(' · ');
}

String effortWord(AppLocalizations l, String e) => switch (e) {
  'low' => l.effortLow,
  'high' => l.effortHigh,
  'max' => l.effortMax,
  _ => l.effortMedium,
};

Future<ModelPick?> showModelPicker(
  BuildContext context, {
  required String title,
  required List<ModelChoice> models,
  AgentModel? current,
  String? inheritLabel,
}) => showModalBottomSheet<ModelPick>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) =>
      AgentModelSheet(title: title, models: models, current: current, inheritLabel: inheritLabel),
);

class AgentModelSheet extends StatefulWidget {
  const AgentModelSheet({
    super.key,
    required this.title,
    required this.models,
    this.current,
    this.inheritLabel,
  });

  final String title;
  final List<ModelChoice> models;

  /// Its own model now (null: it follows the one above).
  final AgentModel? current;

  /// «The same as the one above it» / «The default model»; null: no such choice.
  final String? inheritLabel;

  @override
  State<AgentModelSheet> createState() => _AgentModelSheetState();
}

class _AgentModelSheetState extends State<AgentModelSheet> {
  late final List<ModelFamily> _families = modelFamilies(widget.models);
  late String? _family = familyOf(_families, widget.current?.key ?? '')?.$1.id;
  late final Map<String, int> _way = {
    for (final f in _families)
      f.id: math.max(0, f.ways.indexWhere((w) => w.choice.key == widget.current?.key)),
  };
  late String _effort = widget.current?.effort ?? 'medium';

  ModelFamily? get _chosen => _families.where((f) => f.id == _family).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final chosen = _chosen;
    final way = chosen == null ? null : chosen.ways[_way[chosen.id] ?? 0];
    final cur = widget.current;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                widget.title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l.modelNow(
                  cur == null
                      ? (widget.inheritLabel ?? l.agentModelDefault)
                      : modelWords(l, widget.models, cur),
                ),
                key: const Key('model-now'),
                style: TextStyle(color: c.dim, fontSize: 13.5),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (widget.inheritLabel != null)
                    _Row(
                      key: const Key('model-inherit'),
                      title: widget.inheritLabel!,
                      on: cur == null && _family == null,
                      onTap: () => Navigator.pop(context, const ModelPick(null)),
                    ),
                  for (final f in _families) _familyRow(l, c, f),
                ],
              ),
            ),
            if (chosen != null && way != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    if (way.choice.effort) ...[
                      Text(
                        l.effortTitle,
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.dim, fontSize: 13),
                      ),
                      ChoiceRow(
                        keyPrefix: 'effort',
                        values: efforts,
                        selected: _effort,
                        label: (e) => effortWord(l, e),
                        onChanged: (e) => setState(() => _effort = e),
                      ),
                    ],
                    FilledButton(
                      key: const Key('model-use'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                      onPressed: () => Navigator.pop(
                        context,
                        ModelPick(
                          AgentModel(
                            provider: way.choice.provider,
                            model: way.choice.model,
                            effort: way.choice.effort ? _effort : null,
                          ),
                        ),
                      ),
                      child: Text(l.modelUse(chosen.label)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _familyRow(AppLocalizations l, RgColors c, ModelFamily f) {
    final i = _way[f.id] ?? 0;
    final way = f.ways[i];
    final on = _family == f.id;
    final many = f.ways.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(
          key: Key('model-${f.id}'),
          title: f.label,
          subtitle: many
              ? f.ways.map((w) => wayWord(l, w)).join(' ${l.modelWayOr} ')
              : wayWord(l, way),
          on: on,
          onTap: () => setState(() => _family = f.id),
        ),
        if (on && many)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                ChoiceRow(
                  keyPrefix: 'way',
                  values: [for (final w in f.ways) w.choice.key],
                  selected: way.choice.key,
                  label: (k) => wayWord(l, f.ways.firstWhere((w) => w.choice.key == k)),
                  onChanged: (k) =>
                      setState(() => _way[f.id] = f.ways.indexWhere((w) => w.choice.key == k)),
                ),
                Text(wayHint(l, way), style: TextStyle(color: c.dim, fontSize: 12.5)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.title,
    this.subtitle,
    required this.on,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: on ? c.accentSoft : c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: on ? c.accentDim : c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: TextStyle(color: c.dim, fontSize: 12.5)),
                    ],
                  ),
                ),
                if (on) RgIcon(RgIcons.check, size: 18, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A drawn choice among a few values (pills in a wrap): never a native radio button.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.enabled = true,
  });

  final String keyPrefix;
  final List<String> values;
  final String? selected;
  final String Function(String) label;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          Semantics(
            selected: v == selected,
            button: true,
            enabled: enabled,
            child: Material(
              color: v == selected ? c.accentSoft : c.panel,
              shape: StadiumBorder(side: BorderSide(color: v == selected ? c.accent : c.line)),
              child: InkWell(
                key: Key('$keyPrefix-$v'),
                customBorder: const StadiumBorder(),
                onTap: enabled ? () => onChanged(v) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Text(
                    label(v),
                    style: TextStyle(
                      fontWeight: v == selected ? FontWeight.w700 : FontWeight.w500,
                      color: enabled ? (v == selected ? c.text : c.dim) : c.line,
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
