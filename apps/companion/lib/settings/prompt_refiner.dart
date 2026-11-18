// The instructions' refiner (G42.4, native), as the page's PromptRefiner.tsx: under an editor,
// choose the model that writes (remembered; none: God's), say what to change or leave it empty, see
// the estimate, then the before and after with the differences lit (word_diff.dart, the page's
// word-diff.ts), what changed, and «Use this version» (it fills the editor: the person saves as
// always), «Try again», «Cancel». Nothing is ever saved from here. Also the page's ToolProposal
// (God's choice of a new agent's tools) and DraftInstructions (the creation's last step: God
// writes the instructions from the built-in ones and chooses the tools).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/settings_types.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../l10n/tool_words.g.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/model_sheet.dart';
import 'api/general_api.dart';
import 'word_diff.dart';

const _writerKey = 'refiner.model';

/// Tokens as people say them («circa 320»), as the page's `aboutTokens`.
String aboutTokens(AppLocalizations l, int n) {
  final v = n < 20 ? n : (n / 10).round() * 10;
  final sep = l.localeName.startsWith('it') ? '.' : ',';
  final s = '$v';
  final out = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(sep);
    out.write(s[i]);
  }
  return out.toString();
}

/// «about 3,200 tokens, less than a cent», as the page's `costWords`.
String refineCostWords(AppLocalizations l, int tokens, double? usd) {
  final cost = usd == null
      ? l.refineFree
      : usd < .01
      ? l.refineCostTiny
      : l.refineCost('\$${usd.toStringAsFixed(2)}');
  return l.refineCostLine(aboutTokens(l, tokens), cost);
}

String refineErrorWords(AppLocalizations l, ApiException e) => switch (e.code) {
  'removed_parts' => l.refineErr_removed_parts,
  'budget' => l.refineErr_budget,
  'no_model' => l.refineErr_no_model,
  'no_answer' => l.refineErr_no_answer,
  _ => e.message,
};

/// A tool's name as the page says it.
String toolNameOf(AppLocalizations l, String id) =>
    toolWords[l.localeName.startsWith('it') ? 'it' : 'en']?['tool_$id'] ?? id;

String godNameOf(AppController app) =>
    app.agents.where((a) => a.kind == AgentKind.god).firstOrNull?.name ?? 'God';

/// The model chosen last time to write instructions (null: God's), kept on this device.
Future<AgentModel?> readWriterModel(AppController app) async {
  final raw = await app.prefs.get(_writerKey);
  if (raw == null) return null;
  try {
    return AgentModel.fromJson(jsonDecode(raw));
  } on FormatException {
    return null;
  }
}

Future<void> saveWriterModel(AppController app, AgentModel? m) =>
    app.prefs.set(_writerKey, m == null ? null : jsonEncode(m.toJson()));

/// The writer's row: «The model that writes», its name, a tap to change it.
class _WriterRow extends StatelessWidget {
  const _WriterRow({required this.models, required this.model, required this.onPick});

  final List<ModelChoice>? models;
  final AgentModel? model;
  final ValueChanged<AgentModel?> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.read(context);
    final god = l.g4GenRefineGodModel(godNameOf(app));
    final list = models;
    return Material(
      color: c.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.line),
      ),
      child: InkWell(
        key: const Key('refine-writer'),
        borderRadius: BorderRadius.circular(12),
        onTap: list == null || list.isEmpty
            ? null
            : () async {
                final p = await showModelPicker(
                  context,
                  title: l.g4GenRefineModel,
                  models: list,
                  current: model,
                  inheritLabel: god,
                );
                if (p != null) onPick(p.model);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              RgIcon(RgIcons.cpu, size: 18, color: c.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.g4GenRefineModel, style: TextStyle(color: c.dim, fontSize: 12)),
                    Text(
                      list == null
                          ? l.loading
                          : model == null
                          ? god
                          : modelWords(l, list, model!),
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              RgIcon(RgIcons.chevronDown, size: 18, color: c.dim),
            ],
          ),
        ),
      ),
    );
  }
}

/// The writer model and the models it may be among: known models only (a model gone means God's).
mixin _Writer<T extends StatefulWidget> on State<T> {
  List<ModelChoice>? models;
  AgentModel? _writer;

  AgentModel? get writer {
    final w = _writer;
    if (w == null || models == null) return null;
    return models!.any((m) => m.provider == w.provider && m.model == w.model) ? w : null;
  }

  Future<void> loadWriter() async {
    final app = AppScope.read(context);
    final w = await readWriterModel(app);
    List<ModelChoice>? list;
    try {
      list = await app.client?.models();
    } on ApiException {
      list = const [];
    }
    if (!mounted) return;
    setState(() {
      _writer = w;
      models = list ?? const [];
    });
  }

  void pickWriter(AgentModel? m) {
    setState(() => _writer = m);
    unawaited(saveWriterModel(AppScope.read(context), m));
  }
}

/// «Improve the instructions» under an editor. [text] is what the editor holds now; [onUse] puts
/// the new version in it. [rewrite]: God rewrites them for the agent's new job (goal `draft`).
class PromptRefiner extends StatefulWidget {
  const PromptRefiner({
    super.key,
    required this.target,
    required this.text,
    required this.onUse,
    this.rewrite = false,
    this.startOpen = false,
    this.onClose,
  });

  final RefineFor target;
  final String text;
  final ValueChanged<String> onUse;
  final bool rewrite;
  final bool startOpen;
  final VoidCallback? onClose;

  @override
  State<PromptRefiner> createState() => _PromptRefinerState();
}

enum _Phase { ask, working, result }

class _PromptRefinerState extends State<PromptRefiner> with _Writer {
  late bool _open = widget.startOpen;
  final _wish = TextEditingController();
  _Phase _phase = _Phase.ask;
  RefineAnswer? _result;
  String _before = '';
  String? _error;
  bool _used = false;

  /// The estimate: null while asked, false when there is none.
  Object? _estimate;
  Timer? _timer;
  int _run = 0;

  String get _lang => Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';
  String get _goal => widget.rewrite ? 'draft' : 'refine';

  @override
  void initState() {
    super.initState();
    _wish.addListener(_guessSoon);
    if (_open) WidgetsBinding.instance.addPostFrameCallback((_) => _opened());
  }

  @override
  void didUpdateWidget(PromptRefiner old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _guessSoon();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wish.dispose();
    super.dispose();
  }

  Future<void> _opened() async {
    await loadWriter();
    // The first estimate at once; later ones a moment after typing stops.
    await _guess();
  }

  /// The estimate is asked again a moment after typing stops, as the page's `useEstimate`.
  void _guessSoon() {
    if (!_open || _phase != _Phase.ask) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 350), _guess);
  }

  Future<void> _guess() async {
    final c = AppScope.read(context).client;
    if (c == null || !mounted) return;
    final l = AppLocalizations.of(context);
    try {
      final g = await c.refineGuess(
        widget.target,
        goal: _goal,
        text: widget.text,
        request: _wish.text,
        lang: _lang,
        model: writer,
      );
      if (mounted) {
        setState(() => _estimate = l.refineEstimate(refineCostWords(l, g.tokens, g.usd)));
      }
    } on ApiException {
      if (mounted) setState(() => _estimate = false);
    }
  }

  void _close() {
    _run++;
    setState(() {
      _open = false;
      _phase = _Phase.ask;
      _result = null;
      _error = null;
    });
    widget.onClose?.call();
  }

  Future<void> _go() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    final mine = ++_run;
    setState(() {
      _error = null;
      _used = false;
      _before = widget.text;
      _phase = _Phase.working;
    });
    try {
      final r = await c.refineText(
        widget.target,
        goal: _goal,
        text: widget.text,
        request: _wish.text,
        lang: _lang,
        model: writer,
      );
      if (mine != _run || !mounted) return;
      setState(() {
        _result = r;
        _phase = _Phase.result;
      });
    } on ApiException catch (e) {
      if (mine != _run || !mounted) return;
      setState(() {
        _error = refineErrorWords(l, e);
        _phase = _Phase.ask;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.read(context);
    if (!_open) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (_used)
            Text(
              l.refineUsed,
              key: const Key('refine-used'),
              style: TextStyle(color: c.ok),
            ),
          OutlinedButton.icon(
            key: const Key('refine-open'),
            onPressed: () {
              setState(() {
                _open = true;
                _estimate = null;
              });
              unawaited(_opened());
            },
            icon: RgIcon(RgIcons.zap, size: 16, color: c.accent),
            label: Text(widget.rewrite ? l.g4GenRewriteYes : l.refineOpen),
          ),
        ],
      );
    }
    final r = _result;
    return Container(
      key: const Key('refine-box'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accentDim),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            children: [
              RgIcon(RgIcons.zap, size: 18, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.rewrite ? l.g4GenRewriteTitle : l.refineOpen,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 15),
                ),
              ),
            ],
          ),
          if (_phase == _Phase.ask) ...[
            Text(
              widget.rewrite ? l.g4GenRewriteLead(godNameOf(app)) : l.refineLead,
              style: TextStyle(color: c.dim, fontSize: 13),
            ),
            _WriterRow(
              models: models,
              model: writer,
              onPick: (m) {
                pickWriter(m);
                _guessSoon();
              },
            ),
            TextField(
              key: const Key('refine-wish'),
              controller: _wish,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l.refineWish,
                hintText: l.refineWishPlaceholder,
                hintMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
            ),
            Text(
              _estimate is String
                  ? _estimate! as String
                  : _estimate == false
                  ? l.refineNoEstimate
                  : l.loading,
              key: const Key('refine-estimate'),
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
            if (_error != null)
              Text(
                _error!,
                key: const Key('refine-error'),
                style: TextStyle(color: c.err),
              ),
            _Acts(
              children: [
                TextButton(
                  key: const Key('refine-cancel'),
                  onPressed: _close,
                  child: Text(l.cancel),
                ),
                FilledButton.icon(
                  key: const Key('refine-go'),
                  onPressed: !widget.rewrite && widget.text.trim().isEmpty ? null : _go,
                  icon: const RgIcon(RgIcons.zap, size: 15, color: Colors.white),
                  label: Text(widget.rewrite ? l.g4GenRewriteGo : l.refineGo),
                ),
              ],
            ),
          ],
          if (_phase == _Phase.working) ...[
            Row(
              key: const Key('refine-working'),
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(l.refineWorking, style: TextStyle(color: c.text)),
                ),
              ],
            ),
            _Acts(
              children: [TextButton(onPressed: _close, child: Text(l.cancel))],
            ),
          ],
          if (_phase == _Phase.result && r != null) ...[
            WordDiffView(before: _before, after: r.text),
            RefineChanges(text: r.changes),
            Text(
              l.refineSpent(refineCostWords(l, r.tokens, r.usd)),
              style: TextStyle(color: c.dim, fontSize: 12.5),
            ),
            _Acts(
              children: [
                TextButton(onPressed: _close, child: Text(l.cancel)),
                OutlinedButton.icon(
                  key: const Key('refine-retry'),
                  onPressed: _go,
                  icon: RgIcon(RgIcons.refresh, size: 15, color: c.text),
                  label: Text(l.refineRetry),
                ),
                FilledButton(
                  key: const Key('refine-use'),
                  onPressed: () {
                    widget.onUse(r.text);
                    _close();
                    setState(() => _used = true);
                  },
                  child: Text(l.refineUse),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Acts extends StatelessWidget {
  const _Acts({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

/// Before and after, side by side (stacked on a phone): what goes in red, what comes in green.
class WordDiffView extends StatelessWidget {
  const WordDiffView({super.key, required this.before, required this.after});

  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final parts = wordDiff(before, after);
    final n = diffCounts(parts);
    if (n.add == 0 && n.del == 0) {
      return Text(
        l.refineSame,
        key: const Key('refine-same'),
        style: TextStyle(color: c.dim),
      );
    }
    final base = TextStyle(color: c.text, fontSize: 13.5, height: 1.45);
    Widget column(String title, DiffKind hide, Key key) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(
          title,
          style: TextStyle(color: c.dim, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.line),
          ),
          child: SingleChildScrollView(
            child: SelectableText.rich(
              key: key,
              TextSpan(
                style: base,
                children: [
                  for (final p in parts)
                    if (p.kind != hide)
                      TextSpan(
                        text: p.text,
                        style: switch (p.kind) {
                          DiffKind.del => TextStyle(
                            color: c.err,
                            backgroundColor: c.err.withValues(alpha: .12),
                            decoration: TextDecoration.lineThrough,
                          ),
                          DiffKind.add => TextStyle(
                            color: c.ok,
                            backgroundColor: c.ok.withValues(alpha: .14),
                          ),
                          DiffKind.same => null,
                        },
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    final left = column(l.g4GenRefineBefore, DiffKind.add, const Key('refine-before'));
    final right = column(l.g4GenRefineAfter, DiffKind.del, const Key('refine-after'));
    Widget chip(String text, Color col) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: col.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
    return Column(
      key: const Key('refine-diff'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            chip(l.g4GenRefineLegendDel, c.err),
            chip(l.g4GenRefineLegendAdd, c.ok),
            Text(
              l.g4GenRefineCount('${n.del}', '${n.add}'),
              key: const Key('refine-count'),
              style: TextStyle(color: c.dim, fontSize: 12),
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, box) => box.maxWidth >= 560
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(child: left),
                    Expanded(child: right),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [left, right],
                ),
        ),
      ],
    );
  }
}

/// What the model says it changed, line by line.
class RefineChanges extends StatelessWidget {
  const RefineChanges({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lines = [
      for (final s in text.split('\n'))
        if (s.replaceFirst(RegExp(r'^\s*[-*]\s*'), '').trim() case final t when t.isNotEmpty) t,
    ];
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      key: const Key('refine-changes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(
          l.refineChanges,
          style: TextStyle(color: c.dim, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        for (final t in lines)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                ),
              ),
              Expanded(
                child: Text(t, style: TextStyle(color: c.text, fontSize: 13.5)),
              ),
            ],
          ),
      ],
    );
  }
}

/// God's choice of a new agent's tools: each on or off with why, and what it saves.
class ToolProposal extends StatelessWidget {
  const ToolProposal({super.key, required this.tools, required this.onChange});

  final List<ToolPick> tools;
  final ValueChanged<List<ToolPick>> onChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final off = tools.where((t) => !t.on).toList();
    final saved = off.fold(0, (n, t) => n + t.tokens);
    final sorted = [...tools]..sort((a, b) => (a.on ? 1 : 0) - (b.on ? 1 : 0));
    return Column(
      key: const Key('tool-proposal'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          l.g4GenDraftToolsTitle,
          style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
        ),
        Text(
          off.isNotEmpty
              ? l.g4GenDraftToolsSaved('${off.length}', aboutTokens(l, saved))
              : l.g4GenDraftToolsAllOn,
          style: TextStyle(color: c.dim, fontSize: 12.5),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.line),
          ),
          child: Column(
            children: [
              for (final (i, t) in sorted.indexed)
                InkWell(
                  key: Key('tool-pick-${t.id}'),
                  onTap: () =>
                      onChange([for (final x in tools) x.id == t.id ? x.withOn(!x.on) : x]),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: i == 0 ? null : Border(top: BorderSide(color: c.line)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                toolNameOf(l, t.id),
                                style: TextStyle(
                                  color: t.on ? c.text : c.dim,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                [
                                  if (t.why.isNotEmpty)
                                    t.why
                                  else if (t.on)
                                    l.g4GenDraftToolOnDefault,
                                  l.g4GenDraftToolTokens(aboutTokens(l, t.tokens)),
                                ].join(' · '),
                                style: TextStyle(color: c.dim, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        RgSwitch(on: t.on),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (off.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('tool-proposal-all'),
              onPressed: () => onChange([for (final t in tools) t.withOn(true)]),
              child: Text(l.g4GenDraftToolsLikeOthers),
            ),
          ),
      ],
    );
  }
}

/// What the creation's last step hands back: the instructions and the tools to switch off.
typedef DraftOutcome = ({String text, List<ToolPick>? tools});

/// The creation's last step, as the page's DraftInstructions: God writes the instructions from
/// the built-in ones and chooses the tools as soon as the step opens. Editable; «Write them again»,
/// «Use the built-in ones». On a failure the built-in ones ([fallback] of them), and it says so.
class DraftInstructions extends StatefulWidget {
  const DraftInstructions({
    super.key,
    required this.draft,
    required this.fallback,
    required this.onChange,
  });

  /// The protocol's `draft` (kind, name, role, projectId, mode, model…).
  final Map<String, Object?> draft;
  final String Function(String base) fallback;
  final ValueChanged<DraftOutcome> onChange;

  @override
  State<DraftInstructions> createState() => _DraftInstructionsState();
}

enum _Draft { working, done, failed, builtIn }

class _DraftInstructionsState extends State<DraftInstructions> with _Writer {
  final _text = TextEditingController();
  _Draft _state = _Draft.working;
  String _base = '';
  String _changes = '';
  String _spent = '';
  String _why = '';
  List<ToolPick>? _tools;
  int _run = 0;

  String get _lang => Localizations.localeOf(context).languageCode == 'en' ? 'en' : 'it';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await loadWriter();
      await _write();
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _emit() => widget.onChange((text: _text.text, tools: _tools));

  Future<void> _write() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    final mine = ++_run;
    setState(() => _state = _Draft.working);
    final target = RefineDraft(widget.draft);
    var start = _base;
    try {
      if (start.isEmpty) {
        final g = await c.refineGuess(target, goal: 'draft', lang: _lang, model: writer);
        start = widget.fallback(g.base);
        _base = start;
      }
      final r = await c.refineText(target, goal: 'draft', lang: _lang, model: writer);
      if (mine != _run || !mounted) return;
      setState(() {
        _text.text = r.text;
        _changes = r.changes;
        _tools = r.tools;
        _spent = refineCostWords(l, r.tokens, r.usd);
        _state = _Draft.done;
      });
    } on ApiException catch (e) {
      if (mine != _run || !mounted) return;
      setState(() {
        _why = refineErrorWords(l, e);
        _text.text = start;
        _tools = null;
        _state = _Draft.failed;
      });
    }
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final god = godNameOf(AppScope.read(context));
    final tools = _tools;
    return Column(
      key: const Key('draft-instructions'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Text(l.g4GenDraftLead(god), style: TextStyle(color: c.dim, fontSize: 13)),
        _WriterRow(models: models, model: writer, onPick: pickWriter),
        if (_state == _Draft.working)
          Row(
            key: const Key('draft-working'),
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(l.g4GenDraftWorking(god))),
            ],
          )
        else ...[
          if (_state == _Draft.failed)
            Text(
              l.g4GenDraftFailed(god, _why),
              key: const Key('draft-failed'),
              style: TextStyle(color: c.warnText),
            ),
          if (_state == _Draft.builtIn)
            Text(l.g4GenDraftDefaultUsed, style: TextStyle(color: c.dim)),
          TextField(
            key: const Key('draft-text'),
            controller: _text,
            minLines: 8,
            maxLines: 16,
            onChanged: (_) => _emit(),
            style: const TextStyle(fontSize: 13.5, height: 1.4),
            decoration: InputDecoration(
              labelText: l.g4GenAgentInstructions,
              border: const OutlineInputBorder(),
            ),
          ),
          if (_state == _Draft.done) RefineChanges(text: _changes),
          if (_state == _Draft.done && _spent.isNotEmpty)
            Text(l.refineSpent(_spent), style: TextStyle(color: c.dim, fontSize: 12.5)),
          if (tools != null && tools.isNotEmpty)
            ToolProposal(
              tools: tools,
              onChange: (next) {
                setState(() => _tools = next);
                _emit();
              },
            ),
          _Acts(
            children: [
              if (_state != _Draft.builtIn && _base.isNotEmpty)
                TextButton(
                  key: const Key('draft-default'),
                  onPressed: () {
                    _run++;
                    setState(() {
                      _text.text = _base;
                      _tools = null;
                      _state = _Draft.builtIn;
                    });
                    _emit();
                  },
                  child: Text(l.g4GenDraftUseDefault),
                ),
              OutlinedButton.icon(
                key: const Key('draft-again'),
                onPressed: _write,
                icon: RgIcon(RgIcons.refresh, size: 15, color: c.text),
                label: Text(l.g4GenDraftRegenerate),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
