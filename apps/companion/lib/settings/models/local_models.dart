// G42.15: the model on this computer, native, as the page's (LocalModels.tsx): what this computer
// can run in a sentence, the engine, the suggested models in two groups (those that run well here
// and the slower ones) with their estimated speed, size and state; a model's window with what it
// is good at, its speed, the download with the real bar (pause, go on, discard), start, on or off,
// «Use it for the agents», delete, and the speed test; the other files and «Downloaded models».
// The download and the engine are server jobs, followed every second while they run.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/new_agent_screen.dart' show RgSwitch;
import '../../theme/colors.dart';
import '../../ui/chat/file_download.dart' show byteWords;
import '../../ui/dialogs.dart';
import '../../ui/icons.dart';
import '../api/models_api.dart';
import '../automations/automation_kit.dart' show AutoChips;
import '../knowledge_kit.dart';
import '../rules_kit.dart';
import 'local_speed.dart';
import '../../ui/systems.dart';

String _gb(double n) => '${n.toStringAsFixed(1)} GB';

/// What this computer can run, in a sentence (the page's `hardwareText`).
String hardwareWords(AppLocalizations l, ModelsSetup s) {
  final gpus = s.gpus;
  final card = gpus.where((g) => g['integrated'] != true).firstOrNull ?? gpus.firstOrNull;
  final max = s.maxModelGb.toStringAsFixed(s.maxModelGb % 1 == 0 ? 0 : 1);
  if (s.kind == 'gpu' && card != null) {
    final vram = s.vramGb.toStringAsFixed(s.vramGb % 1 == 0 ? 0 : 1);
    return l.moLmHwGpu(max, '${card['name'] ?? ''}', vram);
  }
  if (s.kind == 'gpu-unknown') return l.moLmHwGpuUnknown;
  if (s.kind == 'igpu') return l.moLmHwIgpu(max);
  if (gpus.any((g) => g['integrated'] != true)) return l.moLmHwUnreachable(max);
  return l.moLmHwCpu(max);
}

String _engineWords(AppLocalizations l, String v, ModelsSetup s) => switch (v) {
  'windows' => s.os == 'darwin' ? l.moLmEngine_mac : l.moLmEngine_windows,
  'cuda' => l.moLmEngine_cuda,
  'vulkan' => l.moLmEngine_vulkan,
  _ => l.moLmEngine_cpu,
};

LmJob? _latest(List<LmJob> jobs, String kind, String model) =>
    jobs.where((j) => j.kind == kind && j.vars['model'] == model).lastOrNull;

LocalSpeed _speed(ModelsSetup s, LocalChoice m, double sizeGb) => estimatedSpeed(
  totalB: m.totalB,
  activeB: m.activeB,
  fileGb: sizeGb,
  kind: s.kind,
  vramGb: s.vramGb,
  ramGb: s.ramGb,
);

/// Usable here: fits in the card and the whole RAM and writes at least 10 a second (or measured).
bool _works(ModelsSetup s, LocalChoice m) {
  final f = m.file;
  if (f == null) return false;
  final measured = s.measuredTps(targetName(f.file));
  if (measured != null) return measured >= usableTps;
  final sp = _speed(s, m, f.sizeGb);
  return sp.range == null && sp.tokensPerSec >= usableTps;
}

/// The one to suggest: among those that fit at a good quality and are not too slow here, the
/// cleverest (tools and code as tie-breakers); none of them: the largest that fits.
String? _recommended(ModelsSetup s, List<LocalChoice> models) {
  final fitting = models.where((m) => m.file != null && !m.beyondMemory).toList();
  int score(LocalChoice m) =>
      (m.scores['smart'] ?? 0) * 10 + (m.scores['tools'] ?? 0) * 2 + (m.scores['code'] ?? 0);
  final usable =
      fitting
          .where((m) => m.file!.quality != 'reduced' && _speed(s, m, m.file!.sizeGb).stars >= 2)
          .toList()
        ..sort((a, b) => score(b) - score(a));
  return (usable.firstOrNull ?? fitting.lastOrNull)?.id;
}

String _speedWords(
  AppLocalizations l,
  ModelsSetup s,
  LocalChoice m,
  double sizeGb, [
  String? unit,
]) {
  final measured = s.measuredTps(targetName(m.file?.file ?? ''));
  if (measured != null) return '${measured.round()} ${l.moLmSpeedMeasured}';
  final sp = _speed(s, m, sizeGb);
  final r = sp.range;
  final n = r != null && r.$1 != r.$2 ? '${r.$1}–${r.$2}' : '${sp.tokensPerSec}';
  return '$n ${unit ?? l.moLmTokensUnit}';
}

class LocalModelsSection extends StatefulWidget {
  const LocalModelsSection({super.key, required this.s, this.poll = true, required this.onChange});

  final ModelsSetup s;
  final bool poll;
  final Future<void> Function() onChange;

  @override
  State<LocalModelsSection> createState() => _LocalModelsSectionState();
}

class _LocalModelsSectionState extends State<LocalModelsSection> {
  late String _variant = widget.s.variant;
  List<LocalChoice>? _models;
  List<LocalFile> _files = const [];
  List<LmJob> _jobs = const [];
  String? _error;
  Timer? _timer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final r = await c.localModels(_variant);
      List<LmJob> jobs;
      try {
        jobs = await c.lmJobs();
      } on Object {
        jobs = const [];
      }
      if (!mounted) return;
      setState(() {
        _models = r.models;
        _files = r.files;
        _jobs = jobs;
        _error = null;
      });
      _follow();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  /// While something runs, its progress is read every second; when it ends, everything again.
  void _follow() {
    final running = _jobs.any((j) => j.state == 'running');
    if (!running || !widget.poll) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      final c = AppScope.read(context).client;
      if (c == null) return;
      try {
        final next = await c.lmJobs();
        if (!mounted) return;
        setState(() => _jobs = next);
        if (!next.any((j) => j.state == 'running')) {
          _timer?.cancel();
          _timer = null;
          await _load();
          await widget.onChange();
        }
      } on Object {
        // Read again in a second.
      }
    });
  }

  Future<void> _changed() async {
    await _load();
    await widget.onChange();
  }

  String _tag(AppLocalizations l, LocalChoice m, String? best) {
    final f = m.file;
    if (f == null) return m.unavailable ? l.moLmUnavailable : l.moLmCardTooBig;
    final name = targetName(f.file);
    final active = widget.s.activeModel;
    if (active == name) return widget.s.engineOff ? l.moLmOff : l.moLmInUse;
    final dl = _latest(_jobs, 'model_download', name);
    if (dl?.state == 'running') {
      final p = dl!.steps.firstOrNull;
      return p?.total != null && p!.total! > 0
          ? l.moLmCardDownloading('${((p.done ?? 0) / p.total! * 100).round()}')
          : l.moLmStarting;
    }
    final local = _files.where((x) => x.file == name).firstOrNull;
    if (local?.partial ?? false) return l.moLmCardPaused;
    if (local != null) return l.moLmCardReady;
    return m.id == best ? l.moLmRecommended : l.moLmCardGet(_gb(f.sizeGb));
  }

  Future<void> _openModel(LocalChoice m) => kbWindow<void>(
    context,
    key: Key('lm-window-${m.id}'),
    title: m.name,
    wide: true,
    body: (ctx, close) => _ModelPanel(
      m: m,
      s: widget.s,
      variant: _variant,
      files: () => _files,
      jobs: () => _jobs,
      poll: widget.poll,
      onChange: _changed,
    ),
  );

  Future<void> _openDownloaded() {
    final names = {
      for (final m in _models ?? const <LocalChoice>[])
        if (m.file != null) targetName(m.file!.file): m.name,
    };
    return kbWindow<void>(
      context,
      key: const Key('lm-downloaded-window'),
      title: AppLocalizations.of(context).moLmDownloadedTitle,
      wide: true,
      body: (ctx, close) => _Downloaded(
        files: _files,
        names: names,
        jobs: _jobs,
        active: widget.s.activeModel,
        variant: _variant,
        onChange: () async {
          await _changed();
          close();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final s = widget.s;
    final lang = Localizations.localeOf(context).languageCode;
    final models = _models;
    final best = models == null ? null : _recommended(s, models);
    final fit = [
      for (final m in models ?? const <LocalChoice>[])
        if (_works(s, m)) m,
    ];
    final slow = [
      for (final m in models ?? const <LocalChoice>[])
        if (!_works(s, m)) m,
    ];
    final known = {
      for (final m in models ?? const <LocalChoice>[])
        if (m.file != null) targetName(m.file!.file),
    };
    final others = [
      for (final f in _files)
        if (!known.contains(f.file) && !f.partial) f,
    ];
    final variants = s.windowsEngine ? const ['windows'] : const ['cpu', 'cuda', 'vulkan'];
    final shown = _slow ? slow : fit;
    Widget card(LocalChoice m) {
      final f = m.file;
      final inUse = f != null && s.activeModel == targetName(f.file);
      return KbTile(
        key: Key('lm-card-${m.id}'),
        icon: RgIcons.cpu,
        title: m.name,
        badge: _tag(l, m, best),
        text: [
          m.activeB < m.totalB ? l.moWzMoe(_num(m.totalB)) : l.moWzDense(_num(m.totalB)),
          if (f != null) '${_speedWords(l, s, m, f.sizeGb)} · ${_gb(f.sizeGb)}',
        ].join('\n'),
        on: inUse,
        onTap: () => _openModel(m),
      );
    }

    return Column(
      key: const Key('lm-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbBox(
          key: const Key('lm-machine'),
          children: [
            Row(
              children: [
                RgIcon(RgIcons.monitor, size: 20, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hardwareWords(l, s),
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600, height: 1.35),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text(
                l.moLmEngine,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
              ),
            ),
            AutoChips<String>(
              options: [
                for (final v in variants)
                  (
                    v,
                    '${_engineWords(l, v, s)}${v == (s.suggestion['engine'] ?? '') ? ' (${l.moLmRecommended})' : ''}',
                  ),
              ],
              value: [_variant],
              keyOf: (v) => 'lm-engine-$v',
              onChanged: s.lockedOf('engine')
                  ? null
                  : (v) {
                      if (v.isEmpty || v.first == _variant) return;
                      setState(() {
                        _variant = v.first;
                        _models = null;
                      });
                      unawaited(_load());
                    },
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.moLmEngineHelp, style: TextStyle(color: c.dim, fontSize: 12.5)),
            ),
            SysExplain(RgSystem.deepField, sysWord(context, 'wzStreamInfo1')),
            SysExplain(RgSystem.persistar, l.moSysPersistarLine),
          ],
        ),
        if (s.lockedOf('engine')) KbLine(l.moWzLocked, dim: true),
        if (_error != null) KbLine(_error!, error: true),
        RulesSub(title: l.moWzPickModel),
        KbLine(l.moLmScoresHint, dim: true),
        if (models == null)
          KbLine(l.moLmLoading, dim: true)
        else ...[
          AutoChips<bool>(
            options: [
              (false, '${l.moWzFitTab} · ${fit.length}'),
              (true, '${l.moWzSlowTab} · ${slow.length}'),
            ],
            value: [_slow],
            keyOf: (v) => v ? 'lm-tab-slow' : 'lm-tab-fit',
            onChanged: (v) => setState(() => _slow = v.firstOrNull ?? false),
          ),
          const SizedBox(height: 10),
          if (!_slow && fit.isEmpty) KbLine(l.moWzFitNone, dim: true),
          KbTiles(minWidth: 200, children: [for (final m in shown) card(m)]),
        ],
        RulesSub(title: l.moWzMoreModels),
        KbTiles(
          minWidth: 200,
          children: [
            for (final f in others)
              KbTile(
                key: Key('lm-file-${f.file}'),
                icon: RgIcons.file,
                title: f.file,
                badge: s.activeModel == f.file ? l.moLmInUse : l.moLmOther,
                text: byteWords(f.bytes, lang),
                on: s.activeModel == f.file,
                onTap: () => kbWindow<void>(
                  context,
                  key: Key('lm-file-window-${f.file}'),
                  title: f.file,
                  wide: true,
                  body: (ctx, close) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      KbLine(l.moLmOtherHelp(byteWords(f.bytes, lang)), dim: true),
                      _FileActions(
                        repo: null,
                        file: f.file,
                        sizeGb: null,
                        s: s,
                        variant: _variant,
                        files: () => _files,
                        jobs: () => _jobs,
                        onChange: _changed,
                      ),
                    ],
                  ),
                ),
              ),
            KbTile(
              key: const Key('lm-downloaded'),
              icon: RgIcons.trash,
              title: l.moLmDownloadedTitle,
              text: l.moLmDownloadedNote(
                '${_files.length}',
                byteWords(_files.fold(0, (n, f) => n + f.bytes), lang),
              ),
              on: false,
              onTap: _openDownloaded,
            ),
          ],
        ),
      ],
    );
  }
}

String _num(double n) => n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(1);

/// Five drawn steps: how a model does at one thing.
class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      label: '$label $value/5',
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: c.dim, fontSize: 13)),
          ),
          for (var i = 0; i < 5; i++)
            Container(
              width: 18,
              height: 7,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: i < value ? c.accent : c.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      ),
    );
  }
}

/// Everything about one suggested model: what it is good at, its speed, its file.
class _ModelPanel extends StatelessWidget {
  const _ModelPanel({
    required this.m,
    required this.s,
    required this.variant,
    required this.files,
    required this.jobs,
    required this.poll,
    required this.onChange,
  });

  final LocalChoice m;
  final ModelsSetup s;
  final String variant;
  final List<LocalFile> Function() files;
  final List<LmJob> Function() jobs;
  final bool poll;
  final Future<void> Function() onChange;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final f = m.file;
    String score(String k) => switch (k) {
      'smart' => l.moLmScore_smart,
      'code' => l.moLmScore_code,
      'tools' => l.moLmScore_tools,
      _ => l.moLmScore_languages,
    };
    return Column(
      key: Key('lm-panel-${m.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (f != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _speedWords(l, s, m, f.sizeGb, l.moLmSpeedEstimate),
              key: const Key('lm-speed'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.text),
            ),
          ),
        for (final k in const ['smart', 'code', 'tools', 'languages'])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: _Meter(label: score(k), value: m.scores[k] ?? 0),
          ),
        const SizedBox(height: 8),
        if (f == null)
          KbLine(
            m.unavailable
                ? l.moLmUnavailable
                : l.moLmTooBig(_gb(s.maxModelGb), m.smallestGb == null ? '?' : _gb(m.smallestGb!)),
          )
        else ...[
          KbLine(
            '${f.quant ?? 'GGUF'} · ${_gb(f.sizeGb)} · ${switch (f.quality) {
              'high' => l.moLmQuality_high,
              'reduced' => l.moLmQuality_reduced,
              _ => l.moLmQuality_good,
            }}',
            dim: true,
          ),
          if (f.sizeGb > s.ramGb + (s.kind == 'gpu' ? s.vramGb : 0)) KbLine(l.moLmBeyondMemory),
          _FileActions(
            repo: m.repo,
            file: f.file,
            sizeGb: f.sizeGb,
            s: s,
            variant: variant,
            files: files,
            jobs: jobs,
            poll: poll,
            onChange: onChange,
          ),
        ],
      ],
    );
  }
}

/// What can be done with one model file: download, pause, go on, start, use, delete, measure.
class _FileActions extends StatefulWidget {
  const _FileActions({
    required this.repo,
    required this.file,
    required this.sizeGb,
    required this.s,
    required this.variant,
    required this.files,
    required this.jobs,
    this.poll = true,
    required this.onChange,
  });

  final String? repo;
  final String file;
  final double? sizeGb;
  final ModelsSetup s;
  final String variant;
  final List<LocalFile> Function() files;
  final List<LmJob> Function() jobs;
  final bool poll;
  final Future<void> Function() onChange;

  @override
  State<_FileActions> createState() => _FileActionsState();
}

class _FileActionsState extends State<_FileActions> {
  String? _error;
  bool _used = false;
  Timer? _timer;
  List<LmJob>? _ownJobs;
  List<LocalFile>? _ownFiles;
  late bool _off = widget.s.engineOff;
  late String? _active = widget.s.activeModel;

  String get _name => targetName(widget.file);
  List<LmJob> get _jobs => _ownJobs ?? widget.jobs();
  List<LocalFile> get _files => _ownFiles ?? widget.files();

  @override
  void initState() {
    super.initState();
    // What the list knew, then the server's state of now.
    _follow();
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// The window follows its own jobs (the list under it follows them too).
  void _follow() {
    final running = _jobs.any((j) => j.vars['model'] == _name && j.state == 'running');
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
      final jobs = await c.lmJobs();
      final r = await c.localModels(widget.variant);
      final s = await c.modelsSetup();
      if (!mounted) return;
      setState(() {
        _ownJobs = jobs;
        _ownFiles = r.files;
        _active = s.activeModel;
        _off = s.engineOff;
      });
      _follow();
    } on Object {
      // Again in a second.
    }
  }

  Future<void> _act(Future<void> Function() f) async {
    setState(() => _error = null);
    try {
      await f();
      await _refresh();
      await widget.onChange();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  String _jobError(AppLocalizations l, LmJob j) => switch (j.errorCode) {
    'out_of_memory' => l.moJob_error_out_of_memory,
    'model_missing' => l.moJob_error_model_missing,
    'no_gpu' => l.moJob_error_no_gpu,
    'bad_file' => l.moJob_error_bad_file,
    'load_timeout' => l.moJob_error_load_timeout,
    'engine_stopped' => l.moJob_error_engine_stopped,
    'checksum' => l.moJob_error_checksum,
    'incomplete' => l.moJob_error_incomplete,
    _ => j.errorMessage ?? '',
  };

  String _step(AppLocalizations l, String id) => switch (id) {
    'image' => l.moJob_step_image,
    'start' => l.moJob_step_start,
    'load' => l.moJob_step_load,
    'try' => l.moJob_step_try,
    'tune' => l.moJob_step_tune,
    'model_download' => l.moJob_step_model_download,
    'none' => l.moJob_step_none,
    'draft' => l.moJob_step_draft,
    'ngram' => l.moJob_step_ngram,
    'preload' => l.moJob_step_preload,
    _ => id,
  };

  Widget _jobSteps(AppLocalizations l, RgColors c, LmJob j) => Column(
    key: Key('lm-job-${j.id}'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final st in j.steps)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
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
                  Text(
                    _step(l, st.id),
                    style: TextStyle(color: st.state == 'waiting' ? c.dim : c.text),
                  ),
                ],
              ),
              if (st.state == 'running' && st.done != null)
                KbBar(
                  done: st.done!,
                  total: st.total,
                  rate: st.rate,
                  secondsLeft: st.secondsLeft,
                  bytes: true,
                ),
            ],
          ),
        ),
      if (j.state == 'failed') KbLine(_jobError(l, j), error: true),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final client = AppScope.of(context).client;
    final dl = _latest(_jobs, 'model_download', _name);
    final eng = _latest(_jobs, 'engine', _name);
    final local = _files.where((f) => f.file == _name).firstOrNull;
    final active = _active == _name;
    final repo = widget.repo;
    final children = <Widget>[];
    Future<void> download() =>
        _act(() async => client!.downloadModel(repo!, widget.file, widget.variant));
    if (dl?.state == 'running') {
      final p = dl!.steps.firstOrNull;
      children.addAll([
        if (p?.done != null)
          KbBar(
            done: p!.done!,
            total: p.total,
            rate: p.rate,
            secondsLeft: p.secondsLeft,
            bytes: true,
          )
        else
          KbLine(l.moLmStarting, dim: true),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: const Key('lm-pause'),
            onPressed: () => _act(() => client!.cancelLmJob(dl.id)),
            child: Text(l.moLmPause),
          ),
        ),
      ]);
    } else if (local?.partial ?? false) {
      children.addAll([
        KbLine(
          widget.sizeGb != null
              ? l.moLmPaused(byteWords(local!.bytes, lang), _gb(widget.sizeGb!))
              : l.moLmPausedAt(byteWords(local!.bytes, lang)),
          dim: true,
        ),
        Wrap(
          spacing: 10,
          children: [
            if (repo != null)
              FilledButton(
                key: const Key('lm-resume'),
                onPressed: download,
                child: Text(l.moLmResume),
              ),
            TextButton(
              key: const Key('lm-discard'),
              onPressed: () => _act(() => client!.removeModel(_name, widget.variant)),
              child: Text(l.moLmDiscard),
            ),
          ],
        ),
      ]);
    } else if (local != null) {
      if (eng != null && (eng.state == 'running' || eng.state == 'failed')) {
        children.add(
          KbBox(
            children: [
              Text(
                l.moJob_engine(eng.vars['model'] ?? _name),
                style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
              ),
              _jobSteps(l, c, eng),
              if (eng.steps.any((x) => x.id == 'try' && x.state == 'running'))
                KbLine(l.moLmWarmHelp, dim: true),
            ],
          ),
        );
      }
      children.add(
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (active && eng?.state != 'running') ...[
              // On or off without deleting it: off frees its memory and it does not load at start.
              Semantics(
                toggled: !_off,
                button: true,
                child: InkWell(
                  key: const Key('lm-power'),
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => _act(() => client!.setEnginePower(_off)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RgSwitch(on: !_off),
                        const SizedBox(width: 8),
                        Text(_off ? l.moLmOff : l.moLmOn, style: TextStyle(color: c.text)),
                      ],
                    ),
                  ),
                ),
              ),
              FilledButton(
                key: const Key('lm-use'),
                onPressed: _used
                    ? null
                    : () => _act(() async {
                        await client!.setupModels({
                          'defaultModel': {'provider': 'local', 'model': _name},
                        });
                        setState(() => _used = true);
                      }),
                child: Text(l.moLmUseForAgents),
              ),
            ] else if (eng?.state != 'running')
              FilledButton.icon(
                key: const Key('lm-start'),
                onPressed: () =>
                    _act(() => client!.setupEngine({'variant': widget.variant, 'model': _name})),
                icon: const RgIcon(RgIcons.play, size: 15, color: Colors.white),
                label: Text(l.moLmStart),
              ),
            if (eng?.state != 'running') ...[
              OutlinedButton(
                key: const Key('lm-speed-test'),
                onPressed: () => kbWindow<void>(
                  context,
                  key: const Key('lm-speed-window'),
                  title: l.moLmSpeedTestTitle,
                  wide: true,
                  body: (ctx, close) => _SpeedTest(
                    variant: widget.variant,
                    model: _name,
                    poll: widget.poll,
                    onClose: close,
                  ),
                ),
                child: Text(l.moLmSpeedTest),
              ),
              TextButton.icon(
                key: const Key('lm-delete'),
                onPressed: () async {
                  if (active &&
                      !await askConfirm(
                        context,
                        title: l.moLmDelete,
                        body: l.moLmDeleteActiveConfirm,
                        yes: l.moLmDelete,
                        danger: true,
                      )) {
                    return;
                  }
                  await _act(() async {
                    if (active) await client!.setupEngine(null);
                    await client!.removeModel(_name, widget.variant);
                  });
                },
                icon: RgIcon(RgIcons.trash, size: 14, color: c.err),
                label: Text(l.moLmDelete, style: TextStyle(color: c.err)),
              ),
            ],
          ],
        ),
      );
      if (_used) children.add(KbLine(l.moLmUsedForAgents));
    } else {
      children.addAll([
        if (dl?.state == 'failed') KbLine(_jobError(l, dl!), error: true),
        if (repo != null)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              key: const Key('lm-download'),
              onPressed: download,
              icon: const RgIcon(RgIcons.download, size: 15, color: Colors.white),
              label: Text(l.moLmDownload(widget.sizeGb != null ? _gb(widget.sizeGb!) : '')),
            ),
          ),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...children, if (_error != null) KbLine(_error!, error: true)],
    );
  }
}

/// What speculative decoding gains here: a job; the engine is put back after.
class _SpeedTest extends StatefulWidget {
  const _SpeedTest({
    required this.variant,
    required this.model,
    required this.poll,
    required this.onClose,
  });

  final String variant;
  final String model;
  final bool poll;
  final void Function([void]) onClose;

  @override
  State<_SpeedTest> createState() => _SpeedTestState();
}

class _SpeedTestState extends State<_SpeedTest> {
  LmJob? _job;
  String? _error;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted) return;
    final c = AppScope.read(context).client;
    if (c == null) return;
    setState(() => _error = null);
    try {
      final j = await c.speedTest(
        {'variant': widget.variant, 'model': widget.model},
        const ['none', 'ngram'],
      );
      setState(() => _job = j);
      if (widget.poll) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
          try {
            final next = await c.lmJob(j.id);
            if (!mounted) return;
            setState(() => _job = next);
            if (next.state != 'running') _timer?.cancel();
          } on Object {
            // Again in a second.
          }
        });
      }
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final j = _job;
    var trials = const <Map<String, dynamic>>[];
    final raw = j?.vars['trials'];
    if (raw != null) {
      try {
        final list = jsonDecode(raw);
        trials = [
          for (final t in list is List ? list : const [])
            if (t is Map) t.cast<String, dynamic>(),
        ];
      } on Object {
        trials = const [];
      }
    }
    String mode(String m) => switch (m) {
      'draft' => l.moLmSpeedMode_draft,
      'ngram' => l.moLmSpeedMode_ngram,
      _ => l.moLmSpeedMode_none,
    };
    return Column(
      key: const Key('lm-speed-test-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (j == null) ...[
          KbLine(l.moLmSpeedTestIntro),
          KbBox(
            tone: c.warn,
            children: [Text(l.moLmSpeedTestCost, style: TextStyle(color: c.text))],
          ),
          KbActs(
            children: [
              TextButton(onPressed: widget.onClose, child: Text(l.cancel)),
              FilledButton(
                key: const Key('lm-speed-start'),
                onPressed: _start,
                child: Text(l.moLmSpeedTestStart),
              ),
            ],
          ),
        ] else ...[
          Text(
            l.moJob_speed_test(j.vars['model'] ?? widget.model),
            style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
          ),
          for (final t in trials)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode('${t['mode']}'),
                    style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    t['proseTps'] is num
                        ? '${l.moLmSpeedTestProse} ${t['proseTps']} · ${l.moLmSpeedTestCode} ${t['codeTps'] ?? '–'}'
                        : (t['state'] == 'running'
                              ? l.moLmTuneRunning
                              : (t['state'] == 'failed' ? l.moLmTuneFailed : '–')),
                    style: TextStyle(color: c.dim),
                  ),
                ],
              ),
            ),
          if (j.state == 'done') KbLine(l.moLmSpeedTestDone, dim: true),
          if (j.state == 'failed') KbLine(j.errorMessage ?? '', error: true),
        ],
        if (_error != null) KbLine(_error!, error: true),
      ],
    );
  }
}

/// Every file of the models folder, biggest first, each with Delete.
class _Downloaded extends StatefulWidget {
  const _Downloaded({
    required this.files,
    required this.names,
    required this.jobs,
    required this.active,
    required this.variant,
    required this.onChange,
  });

  final List<LocalFile> files;
  final Map<String, String> names;
  final List<LmJob> jobs;
  final String? active;
  final String variant;
  final Future<void> Function() onChange;

  @override
  State<_Downloaded> createState() => _DownloadedState();
}

class _DownloadedState extends State<_Downloaded> {
  String? _error;
  String? _busy;

  Future<void> _remove(LocalFile f) async {
    final l = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final name = widget.names[f.file] ?? f.file;
    final inUse = widget.active == f.file;
    final ok = await askConfirm(
      context,
      title: l.moLmDelete,
      body: inUse
          ? l.moLmDownloadedConfirmActive(name, byteWords(f.bytes, lang))
          : l.moLmDownloadedConfirm(name, byteWords(f.bytes, lang)),
      yes: l.moLmDelete,
      danger: true,
    );
    if (!ok || !mounted) return;
    if (!mounted) return;
    final c = AppScope.read(context).client;
    setState(() {
      _busy = f.file;
      _error = null;
    });
    try {
      // The model in use goes too: the engine stops first.
      if (inUse) await c?.setupEngine(null);
      await c?.removeModel(f.file, widget.variant);
      await widget.onChange();
    } on Object catch (e) {
      if (mounted) setState(() => _error = rulesWhy(e));
    }
    if (mounted) setState(() => _busy = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    if (widget.files.isEmpty) return KbLine(l.moLmDownloadedEmpty, dim: true);
    final sorted = [...widget.files]..sort((a, b) => b.bytes - a.bytes);
    return Column(
      key: const Key('lm-downloaded-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KbLine(
          l.moLmDownloadedHelp(byteWords(widget.files.fold(0, (n, f) => n + f.bytes), lang)),
          dim: true,
        ),
        if (_error != null) KbLine(_error!, error: true),
        for (final f in sorted)
          Container(
            key: Key('lm-downloaded-${f.file}'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.line)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.names[f.file] ?? f.file,
                        style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                      ),
                      Text(
                        [
                          if (widget.names.containsKey(f.file)) f.file,
                          byteWords(f.bytes, lang),
                          if (widget.active == f.file) l.moLmInUse,
                          if (_latest(widget.jobs, 'model_download', f.file)?.state == 'running')
                            l.moLmDownloadedBusy
                          else if (f.partial)
                            l.moLmDownloadedPartial,
                        ].join(' · '),
                        style: TextStyle(color: c.dim, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                if (_latest(widget.jobs, 'model_download', f.file)?.state != 'running')
                  TextButton(
                    key: Key('lm-downloaded-delete-${f.file}'),
                    onPressed: _busy == f.file ? null : () => _remove(f),
                    child: Text(l.moLmDelete, style: TextStyle(color: c.err)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
