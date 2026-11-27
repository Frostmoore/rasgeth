// p3.12.6: the «Improvements» of a local model's card, as the page's (LocalModels.tsx,
// `ImprovementCard`): Prefetch, Big Chunks, Speculative Decoding and No Repack, each with its
// switch, its help, a lock and the reason when the computer or the model cannot use it, the gold
// star where we tried it ourselves, what the person measured here, and the button to measure it
// (a long job, asked first). The words are the page's, through tool/area_words.mjs.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../api/models_api.dart';
import '../automations/automation_kit.dart' show AutoChips;
import '../knowledge_kit.dart';
import '../rules_kit.dart';

/// The gain of a speed in a sign and a percent: «+11%», «-4%» (the page's `gainText`).
String gainText(double before, double after) {
  if (!(before > 0)) return '';
  final pct = ((after / before - 1) * 100).round();
  return '${pct > 0 ? '+' : ''}$pct%';
}

/// A speed with [d] decimals, in the person's number format (the page's `num`).
String speedNum(double n, int d, String lang) {
  final t = n.toStringAsFixed(d);
  return lang == 'it' ? t.replaceFirst('.', ',') : t;
}

/// Why an improvement is off, in words (the page's `whyText`).
String improvementWhy(AppLocalizations l, Improvement i) => switch (i.reason) {
  'needNvidia' => l.moLmImprWhy_needNvidia(i.gpu ?? l.moLmImprIntegratedOnly),
  'needGpu' => l.moLmImprWhy_needGpu,
  'needMoe' => l.moLmImprWhy_needMoe,
  'needDeepField' => l.moLmImprWhy_needDeepField,
  'missingEngine' => l.moLmImprWhy_missingEngine,
  _ => '',
};

/// What we measured ourselves, in a sentence (the page's `testedText`).
String improvementTested(AppLocalizations l, TestedResult r, String lang) {
  String n(double v) => speedNum(v, 2, lang);
  return [
    if (r.mode == 'mtp') l.moLmImprTestedMtp,
    if (r.write != null)
      l.moLmImprTestedWrite(
        n(r.write!.after),
        n(r.write!.before),
        gainText(r.write!.before, r.write!.after),
      ),
    if (r.read != null)
      l.moLmImprTestedRead(
        n(r.read!.after),
        n(r.read!.before),
        gainText(r.read!.before, r.read!.after),
      ),
    '${r.hardware}.',
  ].join(' ');
}

String improvementName(AppLocalizations l, String id) => switch (id) {
  'recommended' => l.moLmRecTitle,
  'prefetch' => l.moLmImpr_prefetch,
  'bigChunks' => l.moLmImpr_bigChunks,
  'speculative' => l.moLmImpr_speculative,
  _ => l.moLmImpr_noRepack,
};

String _sub(AppLocalizations l, String id) => switch (id) {
  'recommended' => l.moLmRecSub,
  'prefetch' => l.moLmImprSub_prefetch,
  'bigChunks' => l.moLmImprSub_bigChunks,
  'speculative' => l.moLmImprSub_speculative,
  _ => l.moLmImprSub_noRepack,
};

/// The context bar's steps (3.12.10, the page's `CTX_STEPS`): round sizes up to the longest the model knows.
const ctxSteps = [4096, 8192, 16384, 32768, 65536, 131072, 262144, 524288, 1048576];

/// 32768 -> «32k», 1048576 -> «1M» (the page's `ctxText`).
String ctxText(int n) => n >= 1048576 ? '${(n / 1048576).round()}M' : '${(n / 1024).round()}k';

/// How much context the engine books (3.12.10, the page's `ContextBar`): the bar in round steps, a gold line where
/// the model, its context and the engine's scratch stop fitting in the card, and what each side means.
class ContextBar extends StatelessWidget {
  const ContextBar({super.key, required this.info, required this.value, required this.onChanged});

  /// From the server; null until it answers.
  final ({int trained, int? inCard})? info;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final trained = info?.trained ?? 65536;
    final steps = ctxSteps.where((n) => n <= trained).toList();
    if (steps.isEmpty) steps.add(trained);
    final found = steps.indexWhere((n) => n >= value);
    final index = found == -1 ? steps.length - 1 : found;
    final inCard = info?.inCard;
    final mark = inCard != null && inCard > 0 ? steps.lastIndexWhere((n) => n <= inCard) : -1;
    final help = info == null
        ? null
        : inCard == null
        ? l.moLmCtxNoCard
        : inCard == 0
        ? l.moLmCtxTooBig
        : steps[index] <= inCard
        ? l.moLmCtxFits
        : l.moLmCtxBeyond(ctxText(inCard));
    final last = (steps.length - 1).clamp(1, 99);
    return Padding(
      key: const Key('context-bar'),
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.moLmCtxTitle,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text, fontSize: 14),
                ),
              ),
              Text(
                ctxText(steps[index]),
                key: const Key('context-bar-value'),
                style: TextStyle(fontWeight: FontWeight.w800, color: c.accent),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, box) {
              // Flutter's slider draws its track inside the overlay's radius at each end.
              const inset = 24.0;
              final track = box.maxWidth - inset * 2;
              return Stack(
                children: [
                  Slider(
                    key: const Key('context-bar-slider'),
                    value: index.toDouble(),
                    min: 0,
                    max: last.toDouble(),
                    divisions: last,
                    label: ctxText(steps[index]),
                    onChanged: (v) => onChanged(steps[v.round()]),
                  ),
                  if (mark >= 0)
                    Positioned(
                      key: const Key('context-bar-mark'),
                      left: inset + track * (mark / last) - 2,
                      top: 10,
                      bottom: 10,
                      child: Semantics(
                        label: l.moLmCtxMark(ctxText(steps[mark])),
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: c.gold,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          if (help != null)
            Text(help, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
        ],
      ),
    );
  }
}

/// One improvement: name and what it does, its switch (none for the one made of choices), the
/// help, the lock with its reason, the gold star, what was measured here and the button to measure.
class ImprovementCard extends StatelessWidget {
  const ImprovementCard({
    super.key,
    required this.id,
    required this.available,
    this.why,
    this.on,
    this.onChanged,
    required this.help,
    this.tested,
    this.measured,
    this.onMeasure,
    this.child,
  });

  final String id;
  final bool available;
  final String? why;

  /// The switch; null for the card made of choices (speculative decoding).
  final bool? on;
  final ValueChanged<bool>? onChanged;
  final String help;
  final String? tested;
  final String? measured;
  final VoidCallback? onMeasure;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final gold = tested != null;
    final name = improvementName(l, id);
    return Opacity(
      opacity: available ? 1 : .6,
      child: Container(
        key: Key('impr-$id'),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: gold ? c.goldSoft : (available ? c.panel : c.panel2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: gold ? c.gold : c.line, width: gold ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 15),
                      ),
                      Text(_sub(l, id), style: TextStyle(color: c.dim, fontSize: 13)),
                    ],
                  ),
                ),
                if (on != null)
                  Semantics(
                    label: name,
                    toggled: available && on!,
                    button: true,
                    child: InkWell(
                      key: Key('impr-switch-$id'),
                      borderRadius: BorderRadius.circular(99),
                      onTap: available ? () => onChanged?.call(!on!) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: RgSwitch(on: available && on!),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(help, style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35)),
            ),
            if (!available && why != null && why!.isNotEmpty)
              Padding(
                key: Key('impr-lock-$id'),
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RgIcon(RgIcons.lock, size: 14, color: c.dim),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(why!, style: TextStyle(color: c.dim, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            if (tested != null)
              Padding(
                key: Key('impr-tested-$id'),
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: RgIcon(RgIcons.star, size: 14, color: c.gold, filled: true),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: l.moLmImprTested,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: ' $tested'),
                          ],
                        ),
                        style: TextStyle(color: c.text, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (available && child != null) child!,
            if (measured != null)
              Padding(
                key: Key('impr-measured-$id'),
                padding: const EdgeInsets.only(top: 6),
                child: Text(measured!, style: TextStyle(color: c.dim, fontSize: 12.5)),
              ),
            if (available && onMeasure != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    key: Key('impr-measure-$id'),
                    onPressed: onMeasure,
                    child: Text(l.moLmImprMeasure),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _stepWords(AppLocalizations l, String id) => switch (id) {
  'without' => l.moJob_step_without,
  'with' => l.moJob_step_with,
  'restore' => l.moJob_step_restore,
  _ => id,
};

/// The measurement of one improvement running: its steps and the two ways' speeds.
class ImprovementRun extends StatefulWidget {
  const ImprovementRun({super.key, required this.job, required this.poll});

  final LmJob job;
  final bool poll;

  @override
  State<ImprovementRun> createState() => _ImprovementRunState();
}

class _ImprovementRunState extends State<ImprovementRun> {
  late LmJob _job = widget.job;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.poll && _job.state == 'running') {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final c = AppScope.read(context).client;
        if (c == null) return;
        try {
          final next = await c.lmJob(_job.id);
          if (!mounted) return;
          setState(() => _job = next);
          if (next.state != 'running') _timer?.cancel();
        } on Object {
          // Again in a second.
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final j = _job;
    var trials = <Map<String, dynamic>>[];
    try {
      final list = jsonDecode(j.vars['trials'] ?? '[]');
      trials = [
        for (final t in list is List ? list : const [])
          if (t is Map) t.cast<String, dynamic>(),
      ]..sort((a, b) => a['mode'] == 'without' ? -1 : (b['mode'] == 'without' ? 1 : 0));
    } on Object {
      trials = [];
    }
    String tps(Object? v, int d) => v is num ? speedNum(v.toDouble(), d, lang) : '–';
    Widget cell(String t, {bool head = false}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          t,
          style: TextStyle(
            color: head ? c.dim : c.text,
            fontWeight: head ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
    return Column(
      key: const Key('impr-run'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.moJob_improvement_test(j.vars['model'] ?? ''),
          style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
        ),
        for (final st in j.steps)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: switch (st.state) {
                    'running' => RgSpinner(size: 13, color: c.accent),
                    'done' => RgIcon(RgIcons.check, size: 13, color: c.ok),
                    'failed' => RgIcon(RgIcons.x, size: 13, color: c.err),
                    _ => const SizedBox.shrink(),
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _stepWords(l, st.id),
                    style: TextStyle(color: st.state == 'waiting' ? c.dim : c.text),
                  ),
                ),
              ],
            ),
          ),
        if (trials.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              cell(l.moLmImprTestWay, head: true),
              cell(l.moLmImprTestRead, head: true),
              cell(l.moLmImprTestWrite, head: true),
            ],
          ),
          for (final t in trials)
            Row(
              key: Key('impr-trial-${t['mode']}'),
              children: [
                cell(t['mode'] == 'with' ? l.moLmImprWith : l.moLmImprWithout),
                cell(tps(t['readTps'], 1)),
                cell(tps(t['writeTps'], 1)),
              ],
            ),
        ],
        if (j.state == 'done') KbLine(l.moLmImprTestDone, dim: true),
        if (j.state == 'failed') KbLine(j.errorMessage ?? '', error: true),
      ],
    );
  }
}

/// The section of a model's card: the warning and the four cards. The choices live in the card
/// (the parent), as the activation sends them.
class ImprovementsSection extends StatefulWidget {
  const ImprovementsSection({
    super.key,
    required this.m,
    required this.s,
    required this.variant,
    required this.stream,
    required this.name,
    required this.choices,
    required this.onChoices,
    required this.files,
    required this.jobs,
    required this.bump,
    required this.speedTest,
    required this.poll,
    required this.onChange,
  });

  final LocalChoice m;
  final ModelsSetup s;
  final String variant;

  /// Deep Field is on for the engine.
  final bool stream;

  /// The model file's name in the folder (as the server names it).
  final String name;
  final EngineChoices choices;
  final ValueChanged<EngineChoices> onChoices;
  final List<LocalFile> Function() files;
  final List<LmJob> Function() jobs;

  /// Ticks when something of the card changed (a download started or ended).
  final Listenable bump;

  /// The speed test's button (it lives in the speculative card).
  final Widget Function(bool downloaded, String? draftName, bool mtp) speedTest;
  final bool poll;
  final Future<void> Function() onChange;

  @override
  State<ImprovementsSection> createState() => _ImprovementsSectionState();
}

class _ImprovementsSectionState extends State<ImprovementsSection> {
  /// The context bar's numbers from the server (3.12.10): null until it answers.
  ({int trained, int? inCard})? _ctxInfo;
  String? _ctxFor;
  List<LocalFile>? _files;
  List<LmJob>? _jobs;
  String? _error;
  Timer? _timer;

  List<LocalFile> get files => _files ?? widget.files();
  List<LmJob> get jobs => _jobs ?? widget.jobs();
  String? get _draftName =>
      widget.m.draftFile == null ? null : targetName(widget.m.draftFile!.file);
  bool get _downloaded => files.any((f) => f.file == widget.name && !f.partial);

  @override
  void initState() {
    super.initState();
    widget.bump.addListener(_refresh);
    unawaited(_refresh());
    unawaited(_context());
  }

  @override
  void didUpdateWidget(ImprovementsSection old) {
    super.didUpdateWidget(old);
    if (old.name != widget.name || old.choices.recommended != widget.choices.recommended) {
      unawaited(_context());
    }
  }

  /// How much context the model knows and how much stays in the card (3.12.10, the page's `contextInfo`).
  Future<void> _context() async {
    final c = AppScope.read(context).client;
    final file = widget.m.file?.file;
    if (c == null || file == null) return;
    final key = '$file ${widget.choices.recommended}';
    _ctxFor = key;
    try {
      final r = await c.contextInfo(
        widget.variant,
        widget.m.repo,
        file,
        recommended: widget.choices.recommended,
      );
      if (mounted && _ctxFor == key) setState(() => _ctxInfo = r);
    } on Object {
      // The bar without its mark.
    }
  }

  @override
  void dispose() {
    widget.bump.removeListener(_refresh);
    _timer?.cancel();
    super.dispose();
  }

  void _follow() {
    final running = jobs.any(
      (j) => j.kind == 'model_download' && j.state == 'running' && j.vars['model'] == _draftName,
    );
    if (!running || !widget.poll) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final js = await c.lmJobs();
      final r = await c.localModels(widget.variant, stream: widget.stream);
      if (!mounted) return;
      setState(() {
        _jobs = js;
        _files = r.files;
      });
      _follow();
    } on Object {
      // Again at the next change.
    }
  }

  Future<void> _measure(String id) async {
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    final yes = await askConfirm(
      context,
      title: l.moLmImprAskTitle(widget.m.name),
      body: l.moLmImprAskText,
      yes: l.moLmImprAskYes,
    );
    if (!yes || !mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final draft = _draftReady ? _draftName : null;
      final job = await c.improvementTest(
        widget.choices.body(widget.variant, widget.name, stream: widget.stream, draftModel: draft),
        id,
      );
      if (!mounted) return;
      await kbWindow<void>(
        context,
        key: const Key('impr-run-window'),
        title: l.moLmImprTestTitle(widget.m.name),
        wide: true,
        body: (ctx, close) => ImprovementRun(job: job, poll: widget.poll),
      );
      await widget.onChange();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  bool get _draftReady => files.any((f) => f.file == _draftName && !f.partial);

  Widget _speculation(AppLocalizations l, RgColors c) {
    final m = widget.m;
    final draft = m.draftFile;
    final local = files.where((f) => f.file == _draftName).firstOrNull;
    final dl = _draftName == null
        ? null
        : jobs.where((j) => j.kind == 'model_download' && j.vars['model'] == _draftName).lastOrNull;
    final p = dl?.state == 'running' ? dl!.steps.firstOrNull : null;
    final mode = widget.choices.speculative;
    final mtp = m.improvement('speculative')?.mtp ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: AutoChips<String>(
            options: [
              ('none', l.moLmSpecNone),
              if (draft != null) ('draft', l.moLmSpecDraft),
              ('ngram', l.moLmSpecNgram),
              if (mtp) ('mtp', l.moLmSpecMtp),
            ],
            value: [mode],
            keyOf: (v) => 'impr-spec-$v',
            onChanged: (v) => widget.onChoices(widget.choices.copy(speculative: v.first)),
          ),
        ),
        if (mode == 'draft' && draft != null) ...[
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.moLmSpecDraftHelp(_draftName ?? '', _gbText(draft.sizeGb)),
              style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
            ),
          ),
          if (local != null && !local.partial)
            KbLine(l.moLmSpecDraftReady, dim: true)
          else if (p?.done != null)
            KbBar(
              done: p!.done!,
              total: p.total,
              rate: p.rate,
              secondsLeft: p.secondsLeft,
              bytes: true,
            )
          else if (m.draftRepo != null)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('impr-draft-get'),
                onPressed: () async {
                  final client = AppScope.read(context).client;
                  try {
                    await client?.downloadModel(m.draftRepo!, draft.file, widget.variant);
                    await _refresh();
                  } on Object catch (e) {
                    if (mounted) setState(() => _error = rulesWhy(e));
                  }
                },
                icon: RgIcon(RgIcons.download, size: 14, color: c.text),
                label: Text(l.moLmSpecDraftGet(_gbText(draft.sizeGb))),
              ),
            ),
        ],
        if (mode == 'ngram')
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.moLmSpecNgramHelp,
              style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
            ),
          ),
        if (mode == 'mtp' && mtp)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.moLmSpecMtpHelp,
              style: TextStyle(color: c.dim, fontSize: 12.5, height: 1.35),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: widget.speedTest(_downloaded, _draftReady ? _draftName : null, mtp),
          ),
        ),
      ],
    );
  }

  String _gbText(double n) => '${n.toStringAsFixed(1)} GB';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final m = widget.m;
    final ch = widget.choices;
    final tests = widget.s.improvementTests;
    // An older server says nothing: only the two that never depend on the computer stay on offer.
    bool can(String id) =>
        m.improvement(id)?.available ?? (id == 'speculative' || id == 'noRepack');
    String? why(String id) {
      final i = m.improvement(id);
      return i != null && !i.available ? improvementWhy(l, i) : null;
    }

    String? tested(String id) {
      final r = m.tested.where((x) => x.improvement == id).firstOrNull;
      return r == null ? null : improvementTested(l, r, lang);
    }

    String? measured(String id) {
      final t = tests.where((x) => x.model == widget.name && x.improvement == id).firstOrNull;
      if (t == null) return null;
      String n(double v, int d) => speedNum(v, d, lang);
      return l.moLmImprMeasured(
        n(t.read.after, 1),
        n(t.read.before, 1),
        n(t.write.after, 2),
        n(t.write.before, 2),
      );
    }

    Widget card(String id, bool on, String help, EngineChoices Function(bool) set) =>
        ImprovementCard(
          id: id,
          available: can(id),
          why: why(id),
          on: on,
          onChanged: (v) => widget.onChoices(set(v)),
          help: help,
          tested: tested(id),
          measured: measured(id),
          onMeasure: _downloaded ? () => _measure(id) : null,
        );
    return Column(
      key: const Key('impr-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // How much context the engine books (3.12.10); with Deep Field its plan decides.
        if (!widget.stream)
          ContextBar(
            info: _ctxInfo,
            value: ch.ctx ?? 65536,
            onChanged: (v) => widget.onChoices(ch.copy(ctx: v)),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          child: Text(
            l.moLmImprTitle,
            style: TextStyle(fontWeight: FontWeight.w700, color: c.dim, fontSize: 13),
          ),
        ),
        KbBox(
          tone: c.warn,
          children: [Text(l.moLmImprWarn, style: TextStyle(color: c.text))],
        ),
        // Our engine for this model (3.12.10): gold, off until the person switches it on.
        if (m.recommended case final rec?)
          ImprovementCard(
            id: 'recommended',
            available: true,
            on: ch.recommended == m.id,
            onChanged: (v) => widget.onChoices(
              v ? ch.copy(recommended: m.id, ctx: rec.ctx) : ch.copy(noRecommended: true),
            ),
            help: [
              if (rec.ubatch != null) l.moLmRecPass('${rec.ubatch}'),
              if (rec.ctx != null) l.moLmRecCtx(ctxText(rec.ctx!)),
            ].join(' '),
            tested: improvementTested(
              l,
              TestedResult({
                'improvement': 'speculative',
                'hardware': rec.hardware,
                'write': {'before': rec.write.before, 'after': rec.write.after},
              }),
              lang,
            ),
          ),
        card(
          'prefetch',
          can('prefetch') && ch.prefetch,
          widget.variant == 'cuda'
              ? l.moLmMoePrefetchHelpDocker('2.5 GB')
              : l.moLmMoePrefetchHelp('700 MB'),
          (v) => ch.copy(prefetch: v),
        ),
        card(
          'bigChunks',
          can('bigChunks') && ch.bigChunks,
          l.moLmBigChunksHelp,
          (v) => ch.copy(bigChunks: v),
        ),
        ImprovementCard(
          id: 'speculative',
          available: can('speculative'),
          help: l.moLmSpecHelp,
          tested: tested('speculative'),
          child: _speculation(l, c),
        ),
        card('noRepack', ch.noRepack, l.moLmImprHelp_noRepack, (v) => ch.copy(noRepack: v)),
        if (_error != null) KbLine(_error!, error: true),
      ],
    );
  }
}
