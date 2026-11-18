// G42.10: Settings › Knowledge, native, as the page's `Knowledge.tsx` (G36.5-G36.6): what is
// ready and how long the rest takes (a real bar), why the search goes by words only and the one
// button that turns the meaning on, the collections with their sources (a folder, a file, a web
// page, a project, a mailbox, the conversations: chosen among RedGiant's folders, sent from this
// device, or written), what could not be read, who each collection is for, «try a search» as the
// agents do it, the model that reads by meaning and the one that reorders (downloaded with their
// bar), the processor's threads, the OCR, the disk, the backup of the vectors, «Rebuild» and
// «Pause». The same routes as the page (`knowledge*` in api.ts); nothing is downloaded without a
// press of the person.
import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../api/types.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/chat/file_download.dart' show byteWords;
import '../ui/icons.dart';
import 'api/knowledge_api.dart';
import 'knowledge_cite.dart';
import 'knowledge_kit.dart';
import 'rules_kit.dart';

/// Files from this device: their names and bytes (the system's chooser; a test gives its own).
typedef KbPickFiles = Future<List<(String, List<int>)>> Function();

Future<List<(String, List<int>)>> _systemPick() async => [
  for (final f in await FilePicker.pickFiles()) (f.name, await f.readAsBytes()),
];

/// Opens the page: a panel over the window on a computer, a whole screen on a phone.
Future<void> openKnowledgeSettings(BuildContext context) =>
    openRulesPage(context, (panel) => KnowledgeScreen(panel: panel));

/// Where a collection's uploads go: God's folder, one folder per collection (the page's).
String kbUploadFolder(KbCollection c) => 'knowledge/${c.id}';

/// Files from the device into a collection, as the page's `uploadToCollection`: written into its
/// upload folder, then that folder is one of its sources (added once, read again after).
Future<int> kbUploadToCollection(
  RedGiantClient c,
  KbCollection col,
  List<(String, List<int>)> files, {
  void Function(int done, int total)? progress,
}) async {
  final dir = kbUploadFolder(col);
  var done = 0;
  for (final (name, bytes) in files) {
    final safe = name.split(RegExp(r'[\\/]')).where((x) => x.isNotEmpty && x != '.' && x != '..');
    if (safe.isEmpty) continue;
    await c.writeReplacing('platform', '$dir/${safe.join('/')}', base64.encode(bytes));
    done++;
    progress?.call(done, files.length);
  }
  final sources = await c.knowledgeSources(col.id);
  final kept = sources
      .where((s) => s.kind == 'workspace' && s.spec['scope'] == 'platform' && s.spec['path'] == dir)
      .firstOrNull;
  if (kept != null) {
    await c.rescanKnowledge(col.id, kept.id);
  } else {
    await c.addKnowledgeSource(col.id, {'kind': 'workspace', 'scope': 'platform', 'path': dir});
  }
  return done;
}

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key, this.panel = false, this.pickFiles, this.poll = true});

  final bool panel;
  final KbPickFiles? pickFiles;

  /// Follows the work every few seconds (as the page); tests turn it off.
  final bool poll;

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen> {
  KbStatus? _st;
  List<KbCollection> _cols = const [];
  KbModels? _models;
  KbDisk? _disk;
  List<KbJob> _jobs = const [];
  String? _error;
  Timer? _timer;
  Timer? _jobTimer;

  RedGiantClient? get _c => AppScope.read(context).client;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_loadModels());
    unawaited(_loadDisk());
    unawaited(_tickJobs());
    if (widget.poll) _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _jobTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final c = _c;
    if (c == null) return;
    try {
      final st = await c.knowledgeStatus();
      final cols = await c.knowledgeCollections();
      if (!mounted) return;
      setState(() {
        _st = st;
        _cols = cols;
        _error = null;
      });
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(AppLocalizations.of(context), e));
    }
  }

  Future<void> _loadModels() async {
    try {
      final m = await _c?.knowledgeModels();
      if (mounted && m != null) setState(() => _models = m);
    } on Exception {
      // The models' part stays hidden, as on the page.
    }
  }

  Future<void> _loadDisk() async {
    try {
      final d = await _c?.knowledgeDisk();
      if (mounted && d != null) setState(() => _disk = d);
    } on Exception {
      // «Loading…» stays.
    }
  }

  /// The downloads, every second while one runs, every four otherwise (the page's).
  Future<void> _tickJobs() async {
    List<KbJob> jobs;
    try {
      jobs = await _c?.knowledgeJobs() ?? const [];
    } on Exception {
      jobs = const [];
    }
    if (!mounted) return;
    setState(() => _jobs = jobs);
    if (widget.poll) {
      _jobTimer = Timer(
        Duration(seconds: jobs.any((j) => j.running) ? 1 : 4),
        () => unawaited(_tickJobs()),
      );
    }
  }

  /// Does [f], then reads the page again; an error is said in words.
  Future<bool> _run(Future<void> Function(RedGiantClient c) f) async {
    final c = _c;
    if (c == null) return false;
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await f(c);
      await _load();
      unawaited(_loadModels());
      unawaited(_tickJobs());
      return true;
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
      return false;
    }
  }

  Future<void> _openCollection(KbCollection col) async {
    await kbWindow<void>(
      context,
      key: const Key('kb-collection-window'),
      wide: true,
      title: col.name,
      sub:
          '${kbScopeWords(AppLocalizations.of(context), AppScope.read(context), col.scope)} · '
          '${AppLocalizations.of(context).knKbColLine(kbNum(AppLocalizations.of(context), col.documents), kbNum(AppLocalizations.of(context), col.chunks))}',
      body: (ctx, close) => _CollectionBody(
        col: col,
        pickFiles: widget.pickFiles ?? _systemPick,
        poll: widget.poll,
        onChanged: _load,
        onClose: close,
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _newCollection() async {
    final made = await kbWindow<KbCollection>(
      context,
      key: const Key('kb-new-window'),
      title: AppLocalizations.of(context).knKbNewCollection,
      body: (ctx, close) => _NewCollection(onDone: close),
    );
    if (!mounted) return;
    await _load();
    if (made != null && mounted) await _openCollection(made);
  }

  Future<void> _rebuild() async {
    final l = AppLocalizations.of(context);
    final yes = await kbWindow<bool>(
      context,
      key: const Key('kb-rebuild-window'),
      title: l.knKbRebuildQ,
      body: (ctx, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KbLine(l.knKbRebuildText),
          KbActs(
            children: [
              OutlinedButton(onPressed: () => close(false), child: Text(l.cancel)),
              FilledButton(
                key: const Key('kb-rebuild-yes'),
                onPressed: () => close(true),
                child: Text(l.knKbRebuild),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) await _run((c) => c.rebuildKnowledge());
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final st = _st;
    final models = _models;
    return RulesPage(
      pageKey: const Key('knowledge-settings'),
      title: l.knKbSection,
      panel: widget.panel,
      question: l.knKbQ,
      lead: st == null ? null : l.knKbLead,
      children: [
        if (st == null) RulesLoading(error: _error),
        if (st != null) ...[
          if (_error != null) KbLine(_error!, error: true, key: const Key('kb-error')),
          _StatusPart(st: st, jobs: _jobs, onPause: (p) => _run((c) => c.pauseKnowledge(p))),
          _MeaningNote(st: st, models: models, jobs: _jobs, run: _run),
          RulesSub(title: l.knKbColsTitle, lead: l.knKbColsLead),
          KbTiles(
            minWidth: 200,
            children: [
              for (final col in _cols)
                _CollectionCard(
                  key: Key('kb-col-${col.id}'),
                  col: col,
                  onTap: () => _openCollection(col),
                ),
              Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: c.line, width: 1.5),
                ),
                child: InkWell(
                  key: const Key('kb-new'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: _newCollection,
                  child: SizedBox(
                    height: 96,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RgIcon(RgIcons.plus, size: 22, color: c.accent),
                          const SizedBox(height: 6),
                          Text(
                            l.knKbNewCollection,
                            style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_cols.isEmpty) KbLine(l.knKbNoCols, dim: true),
          _TryIt(has: _cols.isNotEmpty),
          if (models != null) _ModelPart(st: st, models: models, jobs: _jobs, run: _run),
          if (models != null) _OcrPart(st: st, models: models, jobs: _jobs, run: _run),
          RulesSub(title: l.knKbDiskTitle, lead: l.knKbDiskLead),
          KbBox(
            children: [
              if (_disk == null)
                KbLine(l.knKbLoading, dim: true)
              else
                _Facts(
                  rows: [
                    (l.knKbDiskTexts, _disk!.texts, false),
                    (l.knKbDiskVectors, _disk!.vectors, false),
                    (l.knKbDiskModels, _disk!.models, false),
                    (l.knKbDiskOcr, _disk!.ocr, false),
                    (
                      l.knKbDiskTotal,
                      _disk!.texts + _disk!.vectors + _disk!.models + _disk!.ocr,
                      true,
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              KbSwitchRow(
                key: const Key('kb-backup-vectors'),
                title: l.knKbBackupVectors,
                help: l.knKbBackupVectorsHelp,
                on: st.backupVectors,
                onChanged: (on) => _run((c) => c.setKnowledgeSettings({'backupVectors': on})),
              ),
              RuleRow(
                title: l.knKbRebuild,
                help: l.knKbRebuildHelp,
                child: OutlinedButton.icon(
                  key: const Key('kb-rebuild'),
                  onPressed: _rebuild,
                  icon: RgIcon(RgIcons.refresh, size: 16, color: c.text),
                  label: Text(l.knKbRebuild),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Sizes as the page's `Facts`: a word and its amount, the last one bold.
class _Facts extends StatelessWidget {
  const _Facts({required this.rows});

  final List<(String, int, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Column(
      children: [
        for (final (name, n, bold) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(name, style: TextStyle(color: bold ? c.text : c.dim)),
                ),
                Text(
                  byteWords(n, lang),
                  style: TextStyle(
                    color: c.text,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// What is ready, what is left and how long it takes.
class _StatusPart extends StatefulWidget {
  const _StatusPart({required this.st, required this.jobs, required this.onPause});

  final KbStatus st;
  final List<KbJob> jobs;
  final ValueChanged<bool> onPause;

  @override
  State<_StatusPart> createState() => _StatusPartState();
}

class _StatusPartState extends State<_StatusPart> {
  bool _details = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final st = widget.st;
    final building = st.indexes.where((i) => i.state == 'building').firstOrNull;
    final active = st.indexes.where((i) => i.active).firstOrNull;
    final filling = building ?? active;
    final busy = st.queueDocuments > 0 || (filling != null && filling.embedded < filling.total);
    final headline = !st.vectorOk
        ? l.knKbStateNoVector
        : st.embedding == null
        ? l.knKbStateNoModel
        : st.chunks == 0
        ? l.knKbStateEmpty
        : busy && st.paused
        ? l.knKbStatePaused
        : busy
        ? l.knKbStateWorking
        : l.knKbStateReady(kbNum(l, st.chunks));
    final downloads = widget.jobs.where((j) => j.kind != 'download_ocr');
    return KbBox(
      key: const Key('kb-status'),
      tone: busy ? c.accent : null,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: RgIcon(RgIcons.database, size: 24, color: c.accent)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    key: const Key('kb-headline'),
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c.text),
                  ),
                  Text(
                    l.knKbStatusLine(kbNum(l, st.collections), kbNum(l, st.chunks)),
                    style: TextStyle(color: c.dim, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (filling != null && filling.total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: KbBar(
              done: filling.embedded,
              total: filling.total,
              rate: st.perMinute == null ? null : st.perMinute! / 60,
              secondsLeft: st.etaSeconds,
            ),
          ),
        if (building != null && active != null) KbLine(l.knKbNewIndex(building.model), dim: true),
        if (st.queueDocuments > 0) KbLine(l.knKbDocsWaiting(kbNum(l, st.queueDocuments))),
        if (st.queueChunks > 0 && st.etaSeconds == null && busy) KbLine(l.knKbEtaSoon, dim: true),
        if (st.queueError != null) KbLine(l.knKbQueueError(st.queueError!), error: true),
        if (!st.vectorOk) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('kb-vector-details'),
              onPressed: () => setState(() => _details = !_details),
              icon: RgIcon(
                _details ? RgIcons.chevronDown : RgIcons.chevronRight,
                size: 14,
                color: c.dim,
              ),
              label: Text(l.knUiDetails),
            ),
          ),
          if (_details)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: c.panel2, borderRadius: BorderRadius.circular(8)),
              child: SelectableText(
                st.vectorReason ?? '',
                style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: c.text),
              ),
            ),
        ],
        for (final j in downloads) KbJobView(job: j),
        if (st.embedding != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: KbSwitchRow(
              key: const Key('kb-pause'),
              title: l.knKbPause,
              help: l.knKbPauseHelp,
              on: st.paused,
              onChanged: widget.onPause,
            ),
          ),
      ],
    );
  }
}

/// When the search goes by words only: why, in plain words, and the one action that turns it on.
class _MeaningNote extends StatelessWidget {
  const _MeaningNote({
    required this.st,
    required this.models,
    required this.jobs,
    required this.run,
  });

  final KbStatus st;
  final KbModels? models;
  final List<KbJob> jobs;
  final Future<bool> Function(Future<void> Function(RedGiantClient c) f) run;

  Future<void> _turnOn(BuildContext context, KbLocalModel best) async {
    final l = AppLocalizations.of(context);
    final yes = await kbWindow<bool>(
      context,
      key: const Key('kb-meaning-window'),
      title: l.knKbMeaningTurnOn,
      body: (ctx, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KbLine(l.knKbMeaningWhy),
          KbLine(l.knKbMeaningBest(best.name, kbNum(l, best.sizeMb))),
          KbActs(
            children: [
              OutlinedButton(onPressed: () => close(false), child: Text(l.knKbMeaningOther)),
              FilledButton(
                key: const Key('kb-meaning-yes'),
                onPressed: () => close(true),
                child: Text(
                  best.here
                      ? l.knKbMeaningUse(best.name)
                      : l.knKbMeaningDownload(best.name, kbNum(l, best.sizeMb)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) {
      await run(
        (c) => c.setKnowledgeSettings({
          'embedding': {'provider': 'local', 'model': best.id},
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (st.meaningOn) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final local = models?.local ?? const <KbLocalModel>[];
    final best = local.where((m) => m.recommended).firstOrNull ?? local.firstOrNull;
    final off = st.meaningOff ?? 'failed';
    final downloading = jobs.any((j) => j.running && j.kind != 'download_ocr');
    final chosen = local.where((m) => m.id == st.embeddingModel).firstOrNull;
    return KbBox(
      key: const Key('kb-meaning'),
      tone: off == 'failed' ? c.err : c.warn,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RgIcon(RgIcons.search, size: 22, color: c.warnText),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.knKbMeaningOffTitle,
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                  ),
                  KbLine(switch (off) {
                    'no_model' => l.knKbMeaningOff_no_model,
                    'downloading' => l.knKbMeaningOff_downloading,
                    'no_vector' => l.knKbMeaningOff_no_vector,
                    _ => l.knKbMeaningOff_failed,
                  }),
                  if (off == 'failed' && st.meaningDetail != null)
                    Text(
                      st.meaningDetail!,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: c.dim),
                    ),
                ],
              ),
            ),
          ],
        ),
        KbActs(
          children: [
            if ((off == 'failed' || off == 'no_model'))
              OutlinedButton(
                key: const Key('kb-meaning-other'),
                onPressed: () => Scrollable.ensureVisible(
                  _modelKey.currentContext ?? context,
                  duration: const Duration(milliseconds: 300),
                ),
                child: Text(l.knKbMeaningOther),
              ),
            if (off == 'no_model' && best != null)
              FilledButton(
                key: const Key('kb-meaning-on'),
                onPressed: () => _turnOn(context, best),
                child: Text(l.knKbMeaningTurnOn),
              ),
            if (off == 'downloading' &&
                !downloading &&
                st.embeddingProvider == 'local' &&
                chosen != null)
              FilledButton(
                key: const Key('kb-meaning-download'),
                onPressed: () => run(
                  (c) => c.downloadKnowledgeModel(
                    'embed',
                    chosen.id,
                    gpu: st.embedding?['gpu'] == true,
                  ),
                ),
                child: Text(l.knKbMeaningDownload(chosen.name, kbNum(l, chosen.sizeMb))),
              ),
          ],
        ),
      ],
    );
  }
}

/// Where «Choose another model» scrolls to.
final _modelKey = GlobalKey(debugLabel: 'kb-model');

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({super.key, required this.col, required this.onTap});

  final KbCollection col;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    return Semantics(
      button: true,
      label: l.knKbOpenCollection(col.name),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RgIcon(RgIcons.layers, size: 18, color: c.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        col.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.text, fontSize: 15),
                      ),
                    ),
                    RgIcon(RgIcons.chevronRight, size: 16, color: c.dim),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.panel2,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.line),
                  ),
                  child: Text(
                    kbScopeWords(l, app, col.scope),
                    style: TextStyle(color: c.dim, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.knKbColLine(kbNum(l, col.documents), kbNum(l, col.chunks)),
                  style: TextStyle(color: c.text, fontSize: 13),
                ),
                if (col.description != null && col.description!.isNotEmpty)
                  Text(
                    col.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.dim, fontSize: 12.5),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Drawn chips, one or several chosen (the page's `Chips`). Never a native checkbox.
class KbChips extends StatelessWidget {
  const KbChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.multiple = false,
    required this.keyPrefix,
  });

  final List<(String, String)> options;
  final List<String> value;
  final ValueChanged<List<String>> onChanged;
  final bool multiple;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (id, label) in options)
          Builder(
            builder: (context) {
              final on = value.contains(id);
              return Semantics(
                button: true,
                selected: on,
                child: Material(
                  color: on ? c.accentSoft : c.panel2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(color: on ? c.accent : c.line, width: on ? 1.5 : 1),
                  ),
                  child: InkWell(
                    key: Key('$keyPrefix-$id'),
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onChanged(
                      multiple ? (on ? [...value.where((x) => x != id)] : [...value, id]) : [id],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (multiple && on) ...[
                            RgIcon(RgIcons.check, size: 13, color: c.accent),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: on ? c.text : c.dim,
                              fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A small heading inside a window (the page's `wz-lb` and `kb-h3`).
class _Label extends StatelessWidget {
  const _Label(this.text, {this.big = false});

  final String text;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: EdgeInsets.only(top: big ? 16 : 10, bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: big ? c.text : c.dim,
          fontSize: big ? 15 : 13,
        ),
      ),
    );
  }
}

InputDecoration _field({String? hint, String? help}) => InputDecoration(
  hintText: hint,
  helperText: help,
  helperMaxLines: 3,
  isDense: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
);

/// For whom: everyone, one agent, one project.
class _ScopePick extends StatelessWidget {
  const _ScopePick({required this.scope, required this.onChanged});

  final KbScope scope;
  final ValueChanged<KbScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final working = [
      for (final a in app.agents)
        if (a.kind != AgentKind.demigod && a.kind != AgentKind.inspector) a,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RgChoice<String>(
          vertical: true,
          options: [
            ('all', l.knKbScopeAll),
            ('agent', l.knKbScopeAgent),
            ('project', l.knKbScopeProject),
          ],
          value: scope.kind,
          keyOf: (k) => 'kb-scope-$k',
          onChanged: (k) => onChanged(switch (k) {
            'agent' => KbScope.agent(working.firstOrNull?.id ?? ''),
            'project' => KbScope.project(app.projects.firstOrNull?.id ?? ''),
            _ => const KbScope.all(),
          }),
        ),
        if (scope.kind == 'agent')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: KbChips(
              keyPrefix: 'kb-scope-agent',
              options: [for (final a in working) (a.id, a.name)],
              value: [?scope.id],
              onChanged: (ids) => ids.isEmpty ? null : onChanged(KbScope.agent(ids.last)),
            ),
          ),
        if (scope.kind == 'project')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: app.projects.isEmpty
                ? KbLine(l.knKbNoProjects, dim: true)
                : KbChips(
                    keyPrefix: 'kb-scope-project',
                    options: [for (final p in app.projects) (p.id, p.name)],
                    value: [?scope.id],
                    onChanged: (ids) => ids.isEmpty ? null : onChanged(KbScope.project(ids.last)),
                  ),
          ),
      ],
    );
  }
}

class _NewCollection extends StatefulWidget {
  const _NewCollection({required this.onDone});

  final void Function([KbCollection?]) onDone;

  @override
  State<_NewCollection> createState() => _NewCollectionState();
}

class _NewCollectionState extends State<_NewCollection> {
  final _name = TextEditingController();
  KbScope _scope = const KbScope.all();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _make() async {
    final l = AppLocalizations.of(context);
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      widget.onDone(await c.createKnowledgeCollection(_name.text.trim(), _scope));
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(l.knKbColName),
        TextField(
          key: const Key('kb-new-name'),
          controller: _name,
          maxLength: 120,
          onChanged: (_) => setState(() {}),
          decoration: _field(hint: l.knKbColNameExample, help: l.knKbColNameHelp),
        ),
        _Label(l.knKbForWhom),
        _ScopePick(scope: _scope, onChanged: (s) => setState(() => _scope = s)),
        if (_error != null) KbLine(_error!, error: true),
        KbActs(
          children: [
            OutlinedButton(onPressed: widget.onDone, child: Text(l.cancel)),
            FilledButton(
              key: const Key('kb-new-make'),
              onPressed: _name.text.trim().isEmpty ? null : _make,
              child: Text(l.knKbMake),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a source reads, in words, with its icon (the page's `sourceWords`).
(RgIcons, String) kbSourceWords(AppLocalizations l, AppController app, Map<String, dynamic> s) {
  String name(String id) => app.agents.where((a) => a.id == id).firstOrNull?.name ?? id;
  final days = '${s['days'] ?? 365}';
  switch (s['kind']) {
    case 'folder':
      return (RgIcons.folder, '${s['path'] ?? ''}');
    case 'workspace':
      final scope = '${s['scope'] ?? ''}';
      final id = scope.startsWith('project:') ? scope.substring(8) : scope;
      final place = scope == 'platform'
          ? l.knKbPlacePlatform
          : scope == 'assistants'
          ? l.knKbPlaceAssistants
          : app.projects.where((p) => p.id == id).firstOrNull?.name ?? id;
      final path = '${s['path'] ?? '.'}';
      return (
        RgIcons.box,
        l.knKbSrcProjectOf(place) + (path.isNotEmpty && path != '.' ? ' · $path' : ''),
      );
    case 'file':
      return (RgIcons.file, '${s['path'] ?? ''}');
    case 'url':
      return (RgIcons.globe, '${s['url'] ?? ''}');
    case 'mail':
      return (RgIcons.mail, l.knKbSrcMailOf(days));
    default:
      final agents = [for (final a in (s['agents'] as List? ?? const [])) '$a'];
      return (
        RgIcons.chat,
        agents.isEmpty
            ? l.knKbSrcChatsAll(days)
            : l.knKbSrcChatsOf(days, agents.map(name).join(', ')),
      );
  }
}

String _stateWords(AppLocalizations l, String s) => switch (s) {
  'scanning' => l.knKbSrcState_scanning,
  'ready' => l.knKbSrcState_ready,
  'failed' => l.knKbSrcState_failed,
  _ => l.knKbSrcState_waiting,
};

String _reasonWords(AppLocalizations l, KbDocument d) {
  if (d.state == 'failed') return l.knKbWhyFailed(d.reason ?? '');
  return switch (d.reason) {
    'needs_ocr' => l.knKbWhy_needs_ocr,
    'needs_libreoffice' => l.knKbWhy_needs_libreoffice,
    'binary' => l.knKbWhy_binary,
    'too_big' => l.knKbWhy_too_big,
    'empty' => l.knKbWhy_empty,
    'unsupported' => l.knKbWhy_unsupported,
    'encrypted' => l.knKbWhy_encrypted,
    _ => d.reason ?? '',
  };
}

/// One collection: its sources, what could not be read, who it is for, and removing it.
class _CollectionBody extends StatefulWidget {
  const _CollectionBody({
    required this.col,
    required this.pickFiles,
    required this.poll,
    required this.onChanged,
    required this.onClose,
  });

  final KbCollection col;
  final KbPickFiles pickFiles;
  final bool poll;
  final Future<void> Function() onChanged;
  final void Function([void]) onClose;

  @override
  State<_CollectionBody> createState() => _CollectionBodyState();
}

class _CollectionBodyState extends State<_CollectionBody> {
  List<KbSource>? _sources;
  List<KbDocument> _left = const [];
  late KbScope _scope = widget.col.scope;
  String? _error;
  bool _removing = false;
  ({int done, int total})? _sent;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    if (widget.poll) _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final s = await c.knowledgeSources(widget.col.id);
      final skipped = await c.knowledgeDocuments(widget.col.id, 'skipped');
      final failed = await c.knowledgeDocuments(widget.col.id, 'failed');
      if (mounted) {
        setState(() {
          _sources = s;
          _left = [...failed, ...skipped];
        });
      }
    } on Exception catch (e) {
      if (mounted && _sources == null) {
        setState(() => _error = kbWhy(AppLocalizations.of(context), e));
      }
    }
  }

  Future<void> _act(Future<void> Function(RedGiantClient c) f) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    setState(() => _error = null);
    try {
      await f(c);
      await _load();
      await widget.onChanged();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
    }
  }

  Future<void> _upload() async {
    final files = await widget.pickFiles();
    if (files.isEmpty || !mounted) return;
    setState(() => _sent = (done: 0, total: files.length));
    await _act(
      (c) => kbUploadToCollection(
        c,
        widget.col,
        files,
        progress: (d, t) => mounted ? setState(() => _sent = (done: d, total: t)) : null,
      ),
    );
    if (mounted) setState(() => _sent = null);
  }

  Future<void> _addSource() async {
    final added = await kbWindow<bool>(
      context,
      key: const Key('kb-add-window'),
      wide: true,
      title: AppLocalizations.of(context).knKbAddSourceTo(widget.col.name),
      body: (ctx, close) => _AddSource(col: widget.col, pickFiles: widget.pickFiles, onDone: close),
    );
    if (added == true && mounted) {
      await _load();
      await widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    if (_removing) {
      return Column(
        key: const Key('kb-remove-ask'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Label(l.knKbRemoveQ(widget.col.name), big: true),
          KbLine(l.knKbRemoveText),
          if (_error != null) KbLine(_error!, error: true),
          KbActs(
            children: [
              OutlinedButton(
                onPressed: () => setState(() => _removing = false),
                child: Text(l.cancel),
              ),
              FilledButton(
                key: const Key('kb-remove-yes'),
                style: FilledButton.styleFrom(backgroundColor: c.critical),
                onPressed: () async {
                  final client = AppScope.read(context).client;
                  try {
                    await client?.removeKnowledgeCollection(widget.col.id);
                    widget.onClose();
                  } on Exception catch (e) {
                    if (mounted) setState(() => _error = kbWhy(l, e));
                  }
                },
                child: Text(l.knKbRemove),
              ),
            ],
          ),
        ],
      );
    }
    final sources = _sources;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) KbLine(_error!, error: true, key: const Key('kb-col-error')),
        _Label(l.knKbSources, big: true),
        if (sources == null) KbLine(l.knKbLoading, dim: true),
        if (sources != null && sources.isEmpty) KbLine(l.knKbNoSources, dim: true),
        for (final s in sources ?? const <KbSource>[])
          Builder(
            builder: (context) {
              final (icon, what) = kbSourceWords(l, app, s.spec);
              final tone = switch (s.state) {
                'failed' => c.err,
                'scanning' => c.accent,
                'ready' => c.ok,
                _ => c.dim,
              };
              return Container(
                key: Key('kb-source-${s.id}'),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(
                  color: c.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.line),
                ),
                child: Row(
                  children: [
                    RgIcon(icon, size: 20, color: c.dim),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            what,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: _stateWords(l, s.state),
                                  style: TextStyle(color: tone, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text:
                                      ' · ${l.knKbSrcDocs(kbNum(l, s.documents))}'
                                      '${s.error != null ? ' · ${s.error}' : ''}',
                                ),
                              ],
                            ),
                            style: TextStyle(color: c.dim, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('kb-rescan-${s.id}'),
                      tooltip: l.knKbRescan,
                      onPressed: () => _act((cl) => cl.rescanKnowledge(widget.col.id, s.id)),
                      icon: RgIcon(RgIcons.refresh, size: 16, color: c.dim),
                    ),
                    IconButton(
                      key: Key('kb-remove-source-${s.id}'),
                      tooltip: l.knKbRemoveSource,
                      onPressed: () => _act((cl) => cl.removeKnowledgeSource(widget.col.id, s.id)),
                      icon: RgIcon(RgIcons.trash, size: 16, color: c.dim),
                    ),
                  ],
                ),
              );
            },
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('kb-add-source'),
              onPressed: _addSource,
              icon: RgIcon(RgIcons.plus, size: 16, color: c.text),
              label: Text(l.knKbAddSource),
            ),
            OutlinedButton.icon(
              key: const Key('kb-upload'),
              onPressed: _sent != null ? null : _upload,
              icon: RgIcon(RgIcons.upload, size: 16, color: c.text),
              label: Text(l.knKbUploadFiles),
            ),
          ],
        ),
        if (_sent != null) ...[
          KbLine(l.knKbUploading, dim: true),
          KbBar(done: _sent!.done, total: _sent!.total),
        ],
        if (_left.isNotEmpty) ...[
          _Label(l.knKbLeftOut('${_left.length}'), big: true),
          for (final d in _left)
            Padding(
              key: Key('kb-left-${d.id}'),
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.path,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: c.text),
                  ),
                  Text(_reasonWords(l, d), style: TextStyle(color: c.dim, fontSize: 12.5)),
                ],
              ),
            ),
        ],
        _Label(l.knKbForWhom, big: true),
        _ScopePick(scope: _scope, onChanged: (s) => setState(() => _scope = s)),
        if (_scope != widget.col.scope)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                key: const Key('kb-save-scope'),
                onPressed: () =>
                    _act((cl) => cl.updateKnowledgeCollection(widget.col.id, scope: _scope)),
                child: Text(l.knKbSaveScope),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Divider(color: c.line),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              key: const Key('kb-remove'),
              onPressed: () => setState(() => _removing = true),
              icon: RgIcon(RgIcons.trash, size: 16, color: c.err),
              label: Text(l.knKbRemove, style: TextStyle(color: c.err)),
            ),
            FilledButton(
              key: const Key('kb-collection-done'),
              onPressed: widget.onClose,
              child: Text(l.knWzDoneBtn),
            ),
          ],
        ),
      ],
    );
  }
}

/// Adding a source: what kind, then where (and, for mail and conversations, the person's yes).
class _AddSource extends StatefulWidget {
  const _AddSource({required this.col, required this.pickFiles, required this.onDone});

  final KbCollection col;
  final KbPickFiles pickFiles;
  final void Function([bool?]) onDone;

  @override
  State<_AddSource> createState() => _AddSourceState();
}

class _AddSourceState extends State<_AddSource> {
  String _kind = 'folder';
  final _path = TextEditingController();
  final _url = TextEditingController();
  String? _project;
  String? _mailbox;
  List<({String id, String name})>? _boxes;
  List<String> _chatAgents = const [];
  double _days = 365;
  bool _consent = false;
  String? _error;
  bool _busy = false;
  ({String scope, String path, bool dir})? _picked;
  ({int done, int total})? _sent;

  @override
  void initState() {
    super.initState();
    _project = AppScope.read(context).projects.firstOrNull?.id;
    unawaited(() async {
      try {
        final b = await AppScope.read(context).client?.knowledgeMailboxes() ?? const [];
        if (mounted) {
          setState(() {
            _boxes = b;
            _mailbox = b.firstOrNull?.id;
          });
        }
      } on Exception {
        if (mounted) setState(() => _boxes = const []);
      }
    }());
  }

  @override
  void dispose() {
    _path.dispose();
    _url.dispose();
    super.dispose();
  }

  Map<String, Object?>? _spec() {
    final p = _picked;
    if ((_kind == 'folder' || _kind == 'file') && p != null) {
      return p.dir
          ? {'kind': 'workspace', 'scope': p.scope, 'path': p.path}
          : {'kind': 'file', 'scope': p.scope, 'path': p.path};
    }
    final path = _path.text.trim();
    final url = _url.text.trim();
    return switch (_kind) {
      'folder' || 'file' => path.isEmpty ? null : {'kind': _kind, 'path': path},
      'url' => url.isEmpty ? null : {'kind': 'url', 'url': url},
      'workspace' => _project == null ? null : {'kind': 'workspace', 'scope': 'project:$_project'},
      'mail' =>
        _mailbox != null && _consent
            ? {'kind': 'mail', 'mailbox': _mailbox, 'days': _days.round(), 'consent': true}
            : null,
      _ =>
        _consent
            ? {'kind': 'chats', 'agents': _chatAgents, 'days': _days.round(), 'consent': true}
            : null,
    };
  }

  Future<void> _add() async {
    final s = _spec();
    final c = AppScope.read(context).client;
    if (s == null || c == null) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await c.addKnowledgeSource(widget.col.id, s);
      widget.onDone(true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    final files = await widget.pickFiles();
    if (files.isEmpty || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _sent = (done: 0, total: files.length);
    });
    try {
      await kbUploadToCollection(
        c,
        widget.col,
        files,
        progress: (d, t) => mounted ? setState(() => _sent = (done: d, total: t)) : null,
      );
      widget.onDone(true);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _sent = null;
        });
      }
    }
  }

  Future<void> _pick() async {
    final p = await kbWindow<({String scope, String path, bool dir})>(
      context,
      key: const Key('kb-picker'),
      wide: true,
      title: _kind == 'folder'
          ? AppLocalizations.of(context).knKbPickFolder
          : AppLocalizations.of(context).knKbPickFile,
      body: (ctx, close) => KbPlacePicker(wantDir: _kind == 'folder', onPick: close),
    );
    if (p != null && mounted) setState(() => _picked = p);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    Widget tile(String k, RgIcons icon, String title, String text) => KbTile(
      key: Key('kb-kind-$k'),
      icon: icon,
      title: title,
      text: text,
      on: _kind == k,
      onTap: () => setState(() {
        _kind = k;
        _consent = false;
        _error = null;
        _picked = null;
      }),
    );
    final people = [
      for (final a in app.agents)
        if (a.kind != AgentKind.inspector) a,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbTiles(
          minWidth: 150,
          children: [
            tile('folder', RgIcons.folder, l.knKbKind_folder, l.knKbKindText_folder),
            tile('file', RgIcons.file, l.knKbKind_file, l.knKbKindText_file),
            tile('url', RgIcons.globe, l.knKbKind_url, l.knKbKindText_url),
            tile('workspace', RgIcons.box, l.knKbKind_workspace, l.knKbKindText_workspace),
            tile('mail', RgIcons.mail, l.knKbKind_mail, l.knKbKindText_mail),
            tile('chats', RgIcons.chat, l.knKbKind_chats, l.knKbKindText_chats),
          ],
        ),
        const SizedBox(height: 12),
        if (_kind == 'folder' || _kind == 'file') ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: const Key('kb-pick'),
                onPressed: _busy ? null : _pick,
                icon: RgIcon(RgIcons.folder, size: 16, color: c.text),
                label: Text(_kind == 'folder' ? l.knKbPickFolder : l.knKbPickFile),
              ),
              OutlinedButton.icon(
                key: const Key('kb-send-files'),
                onPressed: _busy ? null : _send,
                icon: RgIcon(RgIcons.upload, size: 16, color: c.text),
                label: Text(l.knKbUploadFiles),
              ),
            ],
          ),
          KbLine(l.knKbUploadSay, dim: true),
          if (_sent != null) KbBar(done: _sent!.done, total: _sent!.total),
          if (_picked != null)
            Container(
              key: const Key('kb-picked'),
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(
                color: c.accentSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.accent.withValues(alpha: .5)),
              ),
              child: Row(
                children: [
                  RgIcon(_picked!.dir ? RgIcons.folder : RgIcons.file, size: 18, color: c.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      kbPickedWords(l, app, _picked!.scope, _picked!.path),
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _picked = null),
                    child: Text(l.knKbPickOther),
                  ),
                ],
              ),
            )
          else ...[
            _Label(_kind == 'folder' ? l.knKbFolderPath : l.knKbFilePath),
            TextField(
              key: const Key('kb-path'),
              controller: _path,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: _field(
                hint: _kind == 'folder' ? l.knKbFolderExample : l.knKbFileExample,
                help: _kind == 'folder' ? l.knKbFolderHelp : l.knKbFileHelp,
              ),
            ),
          ],
        ],
        if (_kind == 'url') ...[
          _Label(l.knKbUrl),
          TextField(
            key: const Key('kb-url'),
            controller: _url,
            keyboardType: TextInputType.url,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: _field(hint: 'https://', help: l.knKbUrlHelp),
          ),
        ],
        if (_kind == 'workspace')
          if (app.projects.isEmpty)
            KbLine(l.knKbNoProjects, dim: true)
          else ...[
            _Label(l.knKbWhichProject),
            KbChips(
              keyPrefix: 'kb-project',
              options: [for (final p in app.projects) (p.id, p.name)],
              value: [?_project],
              onChanged: (ids) => setState(() => _project = ids.lastOrNull ?? _project),
            ),
          ],
        if (_kind == 'mail')
          if (_boxes != null && _boxes!.isEmpty)
            KbLine(l.knKbNoMailboxes, dim: true)
          else ...[
            _Label(l.knKbWhichMailbox),
            KbChips(
              keyPrefix: 'kb-mailbox',
              options: [
                for (final b in _boxes ?? const <({String id, String name})>[]) (b.id, b.name),
              ],
              value: [?_mailbox],
              onChanged: (ids) => setState(() => _mailbox = ids.lastOrNull ?? _mailbox),
            ),
          ],
        if (_kind == 'chats') ...[
          _Label(l.knKbWhichChats),
          KbChips(
            keyPrefix: 'kb-chat-agent',
            multiple: true,
            options: [for (final a in people) (a.id, a.name)],
            value: _chatAgents,
            onChanged: (ids) => setState(() => _chatAgents = ids),
          ),
          if (_chatAgents.isEmpty) KbLine(l.knKbAllChats, dim: true),
        ],
        if (_kind == 'mail' || _kind == 'chats') ...[
          _Label('${l.knKbHowFarBack}: ${l.knKbDays(kbNum(l, _days.round()))}'),
          Slider(
            key: const Key('kb-days'),
            value: _days,
            min: 30,
            max: 1830,
            divisions: 60,
            label: l.knKbDays(kbNum(l, _days.round())),
            onChanged: (v) => setState(() => _days = v),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            decoration: BoxDecoration(
              color: c.warn.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.warn.withValues(alpha: .35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KbLine(_kind == 'mail' ? l.knKbConsentMail : l.knKbConsentChats),
                KbSwitchRow(
                  key: const Key('kb-consent'),
                  title: _kind == 'mail' ? l.knKbConsentMailYes : l.knKbConsentChatsYes,
                  on: _consent,
                  onChanged: (v) => setState(() => _consent = v),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) KbLine(_error!, error: true, key: const Key('kb-add-error')),
        KbActs(
          children: [
            OutlinedButton(onPressed: () => widget.onDone(false), child: Text(l.cancel)),
            FilledButton(
              key: const Key('kb-add'),
              onPressed: _spec() == null || _busy ? null : _add,
              child: Text(l.knKbAdd),
            ),
          ],
        ),
      ],
    );
  }
}

/// What a picked place is called: the project's name, then the path inside it.
String kbPickedWords(AppLocalizations l, AppController app, String scope, String path) {
  final place = scope == 'platform'
      ? l.knKbPlacePlatform
      : scope == 'assistants'
      ? l.knKbPlaceAssistants
      : app.projects.where((p) => 'project:${p.id}' == scope).firstOrNull?.name ?? scope;
  return path.isNotEmpty && path != '.' ? '$place · $path' : place;
}

/// RedGiant's folders, one level at a time (the page's `PlacePicker`): a folder or a file.
class KbPlacePicker extends StatefulWidget {
  const KbPlacePicker({super.key, required this.wantDir, required this.onPick});

  final bool wantDir;
  final void Function([({String scope, String path, bool dir})?]) onPick;

  @override
  State<KbPlacePicker> createState() => _KbPlacePickerState();
}

class _KbPlacePickerState extends State<KbPlacePicker> {
  String? _scope;
  String _path = '.';
  List<({String name, String path, bool dir})>? _entries;
  String? _error;

  Future<void> _open(String scope, String path) async {
    setState(() {
      _scope = scope;
      _path = path;
      _entries = null;
      _error = null;
    });
    try {
      final list = await AppScope.read(context).client?.listFiles(scope, path) ?? const [];
      final out = [
        for (final e in list)
          if (!e.name.startsWith('.')) (name: e.name, path: e.path, dir: e.dir),
      ]..sort((a, b) => a.dir == b.dir ? a.name.compareTo(b.name) : (a.dir ? -1 : 1));
      if (mounted) setState(() => _entries = out);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : '$e');
    }
  }

  void _up() {
    if (_path == '.') {
      setState(() => _scope = null);
    } else {
      unawaited(
        _open(_scope!, _path.contains('/') ? _path.substring(0, _path.lastIndexOf('/')) : '.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final app = AppScope.of(context);
    final places = [
      for (final p in app.projects) ('project:${p.id}', p.name, RgIcons.box),
      ('platform', l.knKbPlacePlatform, RgIcons.folder),
      ('assistants', l.knKbPlaceAssistants, RgIcons.folder),
    ];
    Widget row(Key key, RgIcons icon, String name, VoidCallback? onTap) => InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          children: [
            RgIcon(icon, size: 20, color: onTap == null ? c.line : c.dim),
            const SizedBox(width: 10),
            Expanded(
              child: Text(name, style: TextStyle(color: onTap == null ? c.dim : c.text)),
            ),
          ],
        ),
      ),
    );
    final scope = _scope;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(scope == null ? l.knKbPickWhere : kbPickedWords(l, app, scope, _path), dim: true),
        if (_error != null) KbLine(_error!, error: true),
        if (scope == null)
          for (final (s, name, icon) in places)
            row(Key('kb-place-$s'), icon, name, () => _open(s, '.'))
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('kb-pick-up'),
              onPressed: _up,
              icon: RgIcon(RgIcons.arrowLeft, size: 14, color: c.accent),
              label: Text(_path == '.' ? l.knKbPickPlaces : l.knKbPickUp),
            ),
          ),
          if (_entries == null && _error == null) KbLine(l.knKbLoading, dim: true),
          if (_entries?.isEmpty ?? false)
            KbLine(
              l.knKbPickEmpty(places.where((p) => p.$1 == scope).firstOrNull?.$2 ?? ''),
              dim: true,
            ),
          for (final e in _entries ?? const <({String name, String path, bool dir})>[])
            e.dir
                ? row(
                    Key('kb-pick-dir-${e.path}'),
                    RgIcons.folder,
                    e.name,
                    () => _open(scope, e.path),
                  )
                : row(
                    Key('kb-pick-file-${e.path}'),
                    RgIcons.file,
                    e.name,
                    widget.wantDir
                        ? null
                        : () => widget.onPick((scope: scope, path: e.path, dir: false)),
                  ),
        ],
        KbActs(
          children: [
            OutlinedButton(onPressed: widget.onPick, child: Text(l.cancel)),
            if (widget.wantDir && scope != null)
              FilledButton(
                key: const Key('kb-pick-this'),
                onPressed: () => widget.onPick((scope: scope, path: _path, dir: true)),
                child: Text(l.knKbPickThis),
              ),
          ],
        ),
      ],
    );
  }
}

/// The search as the agents do it, to see what they would find.
class _TryIt extends StatefulWidget {
  const _TryIt({required this.has});

  final bool has;

  @override
  State<_TryIt> createState() => _TryItState();
}

class _TryItState extends State<_TryIt> {
  final _q = TextEditingController();
  KbSearchResult? _r;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _q.text.trim();
    final c = AppScope.read(context).client;
    if (q.isEmpty || c == null) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await c.knowledgeSearch(q);
      if (mounted) setState(() => _r = r);
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final r = _r;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(title: l.knKbTryTitle, lead: l.knKbTryLead),
        KbBox(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('kb-try-field'),
                    controller: _q,
                    enabled: widget.has,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    onChanged: (_) => setState(() {}),
                    decoration: _field(hint: l.knKbTryExample),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('kb-try'),
                  onPressed: !widget.has || _busy || _q.text.trim().isEmpty ? null : _search,
                  icon: const RgIcon(RgIcons.search, size: 16, color: Colors.white),
                  label: Text(l.knKbTrySearch),
                ),
              ],
            ),
            if (_error != null) KbLine(_error!, error: true),
            if (r != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  r.wordsOnly != null
                      ? l.knKbTryWordsOnly
                      : l.knKbTryHow('${r.ms}', '${r.hits.length}'),
                  key: const Key('kb-try-how'),
                  style: TextStyle(color: c.dim, fontSize: 12.5),
                ),
              ),
              if (r.hits.isEmpty) KbLine(l.knKbTryNothing),
              for (final (i, h) in r.hits.indexed) _Hit(key: Key('kb-hit-$i'), h: h),
            ],
          ],
        ),
      ],
    );
  }
}

class _Hit extends StatelessWidget {
  const _Hit({super.key, required this.h});

  final KbHit h;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final cit = h.citation;
    final place = kbPlaceWords(l, cit);
    final text = h.text.length > 320 ? '${h.text.substring(0, 318)}…' : h.text;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: c.panel2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => openKbCitation(context, cit.chunkId),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cit.title,
                        style: TextStyle(fontWeight: FontWeight.w800, color: c.text),
                      ),
                    ),
                    if (place.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          place,
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                if (cit.heading != null)
                  Text(cit.heading!, style: TextStyle(color: c.dim, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(text, style: TextStyle(color: c.text, fontSize: 13.5, height: 1.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _cloudProviders = ['openai', 'voyage', 'cohere', 'gemini', 'mistral', 'jina', 'compatible'];

/// The cloud APIs' addresses (protocol `EMBEDDING_API_URLS`).
const _cloudUrls = {
  'openai': 'https://api.openai.com/v1',
  'voyage': 'https://api.voyageai.com/v1',
  'cohere': 'https://api.cohere.com/v2',
  'gemini': 'https://generativelanguage.googleapis.com/v1beta',
  'mistral': 'https://api.mistral.ai/v1',
  'jina': 'https://api.jina.ai/v1',
};

String _provWords(AppLocalizations l, String p) => switch (p) {
  'openai' => l.knKbProv_openai,
  'voyage' => l.knKbProv_voyage,
  'cohere' => l.knKbProv_cohere,
  'gemini' => l.knKbProv_gemini,
  'mistral' => l.knKbProv_mistral,
  'jina' => l.knKbProv_jina,
  _ => l.knKbProv_compatible,
};

/// The model that reads by meaning, and the one that puts the best first.
class _ModelPart extends StatefulWidget {
  const _ModelPart({required this.st, required this.models, required this.jobs, required this.run});

  final KbStatus st;
  final KbModels models;
  final List<KbJob> jobs;
  final Future<bool> Function(Future<void> Function(RedGiantClient c) f) run;

  @override
  State<_ModelPart> createState() => _ModelPartState();
}

class _ModelPartState extends State<_ModelPart> {
  bool _threads = false;
  double? _threadsValue;

  bool _downloading(String name) => widget.jobs.any((j) => j.running && j.vars['model'] == name);

  Future<void> _cloud() async {
    final e = widget.st.embedding;
    await kbWindow<void>(
      context,
      key: const Key('kb-cloud-window'),
      wide: true,
      title: AppLocalizations.of(context).knKbCloudTitle,
      body: (ctx, close) => _CloudBody(
        models: widget.models,
        now: e != null && e['provider'] != 'local' ? e : null,
        run: widget.run,
        onDone: close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final st = widget.st;
    final e = st.embedding;
    final r = st.rerank;
    String state(KbLocalModel m) => _downloading(m.name)
        ? l.knKbDownloading
        : m.here
        ? l.knKbHere
        : l.knKbToDownload(kbNum(l, m.sizeMb));
    final threads = _threadsValue ?? st.threads.toDouble();
    return Column(
      key: _modelKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(title: l.knKbModelTitle, lead: l.knKbModelLead),
        KbTiles(
          children: [
            for (final m in widget.models.local)
              KbTile(
                key: Key('kb-model-${m.id}'),
                icon: RgIcons.cpu,
                title: m.name,
                badge: m.recommended ? l.knKbRecommended : null,
                text: l.knKbLocalText(kbNum(l, m.defaultDims), kbNum(l, m.sizeMb)),
                state: state(m),
                on: e?['provider'] == 'local' && e?['model'] == m.id,
                onTap: () => widget.run(
                  (c) => c.setKnowledgeSettings({
                    'embedding': {'provider': 'local', 'model': m.id},
                  }),
                ),
              ),
            KbTile(
              key: const Key('kb-model-cloud'),
              icon: RgIcons.cloud,
              title: l.knKbCloudTitle,
              text: e != null && e['provider'] != 'local'
                  ? '${e['provider']} · ${e['model']}'
                  : l.knKbCloudText,
              on: e != null && e['provider'] != 'local',
              onTap: _cloud,
            ),
          ],
        ),
        RulesSub(title: l.knKbRerankTitle, lead: l.knKbRerankLead),
        KbTiles(
          children: [
            KbTile(
              key: const Key('kb-rerank-none'),
              icon: RgIcons.search,
              title: l.knKbRerankNone,
              text: l.knKbRerankNoneText,
              on: r == null,
              onTap: () => widget.run((c) => c.setKnowledgeSettings({'rerank': null})),
            ),
            for (final m in widget.models.localRerank)
              KbTile(
                key: Key('kb-rerank-${m.id}'),
                icon: RgIcons.cpu,
                title: m.name,
                badge: m.recommended ? l.knKbRecommended : null,
                text: l.knKbRerankText(kbNum(l, m.sizeMb)),
                state: state(m),
                on: r?['provider'] == 'local' && r?['model'] == m.id,
                onTap: () => widget.run((c) async {
                  await c.setKnowledgeSettings({
                    'rerank': {'provider': 'local', 'model': m.id},
                  });
                  if (!m.here) await c.downloadKnowledgeModel('rerank', m.id);
                }),
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('kb-threads-open'),
            onPressed: () => setState(() => _threads = !_threads),
            icon: RgIcon(
              _threads ? RgIcons.chevronDown : RgIcons.chevronRight,
              size: 14,
              color: c.dim,
            ),
            label: Text(l.knKbThreadsTitle),
          ),
        ),
        if (_threads)
          KbBox(
            children: [
              Text(
                '${l.knKbThreads}: ${threads == 0 ? l.knKbThreadsAuto : '${threads.round()}'}',
                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
              ),
              Slider(
                key: const Key('kb-threads'),
                value: threads,
                min: 0,
                max: 8,
                divisions: 8,
                onChanged: (v) => setState(() => _threadsValue = v),
                onChangeEnd: (v) =>
                    widget.run((c) => c.setKnowledgeSettings({'threads': v.round()})),
              ),
              KbLine(l.knKbThreadsHelp, dim: true),
            ],
          ),
      ],
    );
  }
}

/// A cloud API for the embeddings: provider, model, and the keychain entry with its key.
class _CloudBody extends StatefulWidget {
  const _CloudBody({required this.models, this.now, required this.run, required this.onDone});

  final KbModels models;
  final Map<String, dynamic>? now;
  final Future<bool> Function(Future<void> Function(RedGiantClient c) f) run;
  final void Function([void]) onDone;

  @override
  State<_CloudBody> createState() => _CloudBodyState();
}

class _CloudBodyState extends State<_CloudBody> {
  late String _provider = '${widget.now?['provider'] ?? 'openai'}';
  late final _model = TextEditingController(
    text: '${widget.now?['model'] ?? _suggestions(_provider).firstOrNull ?? ''}',
  );
  late final _baseUrl = TextEditingController(text: '${widget.now?['baseUrl'] ?? ''}');
  late final _credential = TextEditingController(text: '${widget.now?['credential'] ?? ''}');
  bool _busy = false;
  String? _error;

  List<String> _suggestions(String p) => [
    for (final m in widget.models.cloud)
      if (m.provider == p) m.model,
  ];

  @override
  void dispose() {
    _model.dispose();
    _baseUrl.dispose();
    _credential.dispose();
    super.dispose();
  }

  Future<void> _use() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // The server tries the API once first: a wrong key is said here, now.
      await c.setKnowledgeSettings({
        'embedding': {
          'provider': _provider,
          'model': _model.text.trim(),
          if (_provider == 'compatible' && _baseUrl.text.trim().isNotEmpty)
            'baseUrl': _baseUrl.text.trim(),
          if (_credential.text.trim().isNotEmpty) 'credential': _credential.text.trim(),
        },
      });
      await widget.run((_) async {});
      widget.onDone();
    } on Exception catch (e) {
      if (mounted) setState(() => _error = kbWhy(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final suggestions = _suggestions(_provider);
    final ok =
        _model.text.trim().isNotEmpty &&
        (_provider != 'compatible' || _baseUrl.text.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(l.knKbCloudLead),
        _Label(l.knKbCloudWho),
        KbChips(
          keyPrefix: 'kb-cloud',
          options: [for (final p in _cloudProviders) (p, _provWords(l, p))],
          value: [_provider],
          onChanged: (ids) => setState(() {
            _provider = ids.last;
            _model.text = _suggestions(_provider).firstOrNull ?? '';
          }),
        ),
        if (suggestions.isNotEmpty) ...[
          _Label(l.knKbCloudModel),
          KbChips(
            keyPrefix: 'kb-cloud-model',
            options: [for (final m in suggestions) (m, m)],
            value: [_model.text],
            onChanged: (ids) => setState(() => _model.text = ids.last),
          ),
        ],
        _Label(l.knKbCloudModelName),
        TextField(
          key: const Key('kb-cloud-model-name'),
          controller: _model,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: _field(),
        ),
        if (_provider == 'compatible') ...[
          _Label(l.knKbCloudUrl),
          TextField(
            key: const Key('kb-cloud-url'),
            controller: _baseUrl,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: _field(hint: 'https://example.com/v1', help: l.knKbCloudUrlHelp),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _cloudUrls[_provider] ?? '',
              style: TextStyle(color: c.dim, fontFamily: 'monospace', fontSize: 12.5),
            ),
          ),
        _Label(l.knKbCloudKey),
        TextField(
          key: const Key('kb-cloud-key'),
          controller: _credential,
          style: const TextStyle(fontFamily: 'monospace'),
          decoration: _field(hint: l.knKbCloudKeyExample, help: l.knKbCloudKeyHelp),
        ),
        if (_error != null) KbLine(_error!, error: true, key: const Key('kb-cloud-error')),
        KbActs(
          children: [
            OutlinedButton(onPressed: widget.onDone, child: Text(l.cancel)),
            FilledButton(
              key: const Key('kb-cloud-use'),
              onPressed: !ok || _busy ? null : _use,
              child: Text(_busy ? l.knKbCloudTrying : l.knKbCloudUse),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reading the text in pictures and scanned PDFs, on this computer.
class _OcrPart extends StatelessWidget {
  const _OcrPart({required this.st, required this.models, required this.jobs, required this.run});

  final KbStatus st;
  final KbModels models;
  final List<KbJob> jobs;
  final Future<bool> Function(Future<void> Function(RedGiantClient c) f) run;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final langs = st.ocrLanguages;
    final missing = models.ocr.where((x) => langs.contains(x.id) && !x.here);
    final ocrJobs = jobs.where((j) => j.kind == 'download_ocr').toList();
    final size = ((3808 + missing.fold(0, (n, x) => n + x.sizeKb)) / 1024).round().clamp(
      1,
      1 << 30,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RulesSub(title: l.knKbOcrTitle, lead: l.knKbOcrLead),
        KbBox(
          children: [
            KbSwitchRow(
              key: const Key('kb-ocr-on'),
              title: l.knKbOcrOn,
              help: l.knKbOcrOnHelp,
              on: st.ocrOn,
              onChanged: (on) => run(
                (c) => c.setKnowledgeSettings({
                  'ocr': {'on': on, 'languages': langs},
                }),
              ),
            ),
            _Label(l.knKbOcrLanguages),
            KbChips(
              keyPrefix: 'kb-ocr-lang',
              multiple: true,
              options: [for (final x in models.ocr) (x.id, x.name)],
              value: langs,
              onChanged: (next) => next.isEmpty || next.length > 6
                  ? null
                  : run(
                      (c) => c.setKnowledgeSettings({
                        'ocr': {'on': st.ocrOn, 'languages': next},
                      }),
                    ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RgIcon(RgIcons.image, size: 16, color: c.dim),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      st.ocrReady ? l.knKbOcrReady : l.knKbOcrToDownload(kbNum(l, size)),
                      if (st.ocrWaiting > 0) l.knKbOcrWaiting(kbNum(l, st.ocrWaiting)),
                    ].join(' '),
                    key: const Key('kb-ocr-state'),
                    style: TextStyle(color: c.text, fontSize: 13.5),
                  ),
                ),
              ],
            ),
            if (!st.ocrReady && !ocrJobs.any((j) => j.running))
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('kb-ocr-download'),
                    onPressed: () => run((c) => c.downloadOcr(langs)),
                    icon: RgIcon(RgIcons.download, size: 16, color: c.text),
                    label: Text(l.knKbOcrDownload),
                  ),
                ),
              ),
            for (final j in ocrJobs) KbJobView(job: j),
          ],
        ),
      ],
    );
  }
}
