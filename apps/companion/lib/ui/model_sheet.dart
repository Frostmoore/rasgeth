// The model of an agent, of the Chat or of one conversation (3.8.1): the models under a heading
// per provider and way (Anthropic's subscription, Anthropic's API key…) with a line on what the
// way means, the newest first and a search when the list is long (G42.15, the person's request of
// 2026-11-20), the effort when the model takes one, and «the same as above» (the agent's, the
// parent's or the default). The sheet only chooses: the caller saves with the page's own API.
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
  // By provider and way, the newest first (2026-11-20, the person): every way is its own row.
  late final List<ModelGroup> _groups = modelGroups(widget.models);
  late String? _chosen = widget.models.any((m) => m.key == widget.current?.key)
      ? widget.current!.key
      : null;
  late String _effort = widget.current?.effort ?? 'medium';
  String _query = '';

  ModelChoice? get _choice => widget.models.where((m) => m.key == _chosen).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final choice = _choice;
    final cur = widget.current;
    final searchable = widget.models.length > 8;
    final shown = [
      for (final g in _groups)
        (
          g,
          groupTitle(g, lang),
          [
            for (final m in g.choices)
              if (modelMatches(m, groupTitle(g, lang), _query)) m,
          ],
        ),
    ].where((e) => e.$3.isNotEmpty).toList();
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
            if (searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  key: const Key('model-search'),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l.moModelSearch,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(10),
                      child: RgIcon(RgIcons.search, size: 16, color: c.dim),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (widget.inheritLabel != null && _query.trim().isEmpty)
                    _Row(
                      key: const Key('model-inherit'),
                      title: widget.inheritLabel!,
                      on: cur == null && _chosen == null,
                      onTap: () => Navigator.pop(context, const ModelPick(null)),
                    ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        l.moUiDropNone,
                        key: const Key('model-none'),
                        style: TextStyle(color: c.dim),
                      ),
                    ),
                  for (final (g, title, models) in shown) ...[
                    _GroupHead(
                      key: Key('model-group-${g.id}'),
                      title: title,
                      hint: wayHint(
                        l,
                        ModelWay(
                          modelRoute(g.provider, models.first.model, models.first.name),
                          models.first,
                        ),
                      ),
                    ),
                    for (final m in models)
                      _Row(
                        key: Key('model-${m.key}'),
                        title: m.name ?? modelName(m.model),
                        subtitle: switch (m.status) {
                          'new' => l.moModelNew,
                          'unconfirmed' => l.moModelUnconfirmed,
                          _ => null,
                        },
                        on: _chosen == m.key,
                        onTap: () => setState(() => _chosen = m.key),
                      ),
                  ],
                ],
              ),
            ),
            if (choice != null)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    if (choice.effort) ...[
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
                            provider: choice.provider,
                            model: choice.model,
                            effort: choice.effort ? _effort : null,
                          ),
                        ),
                      ),
                      child: Text(l.modelUse(choice.name ?? modelName(choice.model))),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A group's heading (provider and way) and what that way means, in one line.
class _GroupHead extends StatelessWidget {
  const _GroupHead({super.key, required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 12, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: c.dim,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: .5,
              ),
            ),
            Text(hint, style: TextStyle(color: c.dim, fontSize: 12)),
          ],
        ),
      ),
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
