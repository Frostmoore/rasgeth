// G42.17: Settings › External agents, the page's ExternalAgents.tsx, native: the coding agents the
// person already uses (Claude Code, Codex, Gemini CLI…, the server's ready-made commands) as agents
// of a project; add one from a ready command or another program, «Try» it (the server starts it
// in an empty folder of its own and asks who it is), edit its command, arguments and variables,
// remove it after a yes. Variables never hold a secret: the server refuses one and says why.
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/client.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../setup/wizard/wizard_screen.dart' show wzWord;
import '../theme/colors.dart';
import '../ui/dialogs.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'rules_kit.dart';

Future<void> openAcpSettings(BuildContext context) =>
    openRulesPage(context, (panel) => AcpScreen(panel: panel));

class AcpPreset {
  const AcpPreset(this.id, this.name, this.command, this.args);
  final String id;
  final String name;
  final String command;
  final List<String> args;
}

class AcpWorker {
  AcpWorker(Map<String, dynamic> j)
    : agentId = '${j['agentId'] ?? ''}',
      name = '${j['name'] ?? ''}',
      projectId = j['projectId'] as String?,
      stopped = j['status'] == 'stopped',
      command = '${j['command'] ?? ''}',
      args = [for (final a in (j['args'] as List? ?? const [])) '$a'],
      env = {for (final e in ((j['env'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'};

  final String agentId;
  final String name;
  final String? projectId;
  final bool stopped;
  final String command;
  final List<String> args;
  final Map<String, String> env;
}

extension AcpApi on RedGiantClient {
  Future<({List<AcpWorker> workers, List<AcpPreset> presets})> acpWorkers() async {
    final j = objectOf(await getJson('/api/acp/workers'));
    return (
      workers: [for (final w in arrayOf(j['workers'])) AcpWorker(w)],
      presets: [
        for (final p in arrayOf(j['presets']))
          AcpPreset('${p['id']}', '${p['name']}', '${p['command']}', [
            for (final a in (p['args'] as List? ?? const [])) '$a',
          ]),
      ],
    );
  }

  Future<void> createAcpWorker(Map<String, Object?> w) => callJson('POST', '/api/acp/workers', w);
  Future<void> updateAcpWorker(String id, Map<String, Object?> c) =>
      callJson('PUT', '/api/acp/workers/${Uri.encodeComponent(id)}', c);
  Future<void> removeAcpWorker(String id) =>
      callJson('DELETE', '/api/acp/workers/${Uri.encodeComponent(id)}');
  Future<Map<String, dynamic>> tryAcpWorker(Map<String, Object?> c) async =>
      objectOf(await callJson('POST', '/api/acp/try', c));
}

class AcpScreen extends StatefulWidget {
  const AcpScreen({super.key, required this.panel});

  final bool panel;

  @override
  State<AcpScreen> createState() => _AcpScreenState();
}

class _AcpScreenState extends State<AcpScreen> {
  late final AppController app = AppScope.read(context);
  List<AcpWorker>? _workers;
  List<AcpPreset> _presets = const [];
  String? _error;

  String w(String k, [Map<String, String> v = const {}]) => wzWord(context, k, v);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final r = await app.client!.acpWorkers();
      if (mounted) {
        setState(() {
          _workers = r.workers;
          _presets = r.presets;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _edit([AcpWorker? worker]) async {
    final changed = await showRgWindow<bool>(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _AcpEditor(worker: worker, presets: _presets),
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _remove(AcpWorker x) async {
    final ok = await askConfirm(
      context,
      title: w('acpRemoveQ', {'name': x.name}),
      body: w('acpRemoveText'),
      yes: AppLocalizations.of(context).g7AcpRemove,
      danger: true,
    );
    if (!ok) return;
    try {
      await app.client!.removeAcpWorker(x.agentId);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final projects = app.projects;
    final list = _workers;
    return RulesPage(
      pageKey: const Key('acp-page'),
      panel: widget.panel,
      title: w('acpSection'),
      question: w('acpPageQ'),
      lead: w('acpPageLead'),
      children: [
        if (_error != null) NoticeBanner(key: const Key('acp-error'), text: _error!, error: true),
        RulesSub(title: w('acpWorkersTitle'), lead: w('acpWorkersLead')),
        if (list == null)
          const RulesLoading()
        else
          SettingsCard(
            key: const Key('acp-list'),
            children: [
              if (list.isEmpty) NoteLine(icon: RgIcons.terminal, text: w('acpNone')),
              for (final x in list)
                ListTile(
                  key: Key('acp-${x.agentId}'),
                  leading: RgIcon(RgIcons.terminal, color: x.stopped ? c.dim : c.accent),
                  title: Text(x.name),
                  subtitle: Text(
                    [
                      [x.command, ...x.args].join(' '),
                      if (x.projectId != null)
                        w('acpInProject', {
                          'project':
                              projects.where((p) => p.id == x.projectId).firstOrNull?.name ??
                              x.projectId!,
                        }),
                      if (x.stopped) w('acpStopped'),
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: Key('acp-edit-${x.agentId}'),
                        tooltip: w('acpEdit'),
                        onPressed: () => unawaited(_edit(x)),
                        icon: RgIcon(RgIcons.edit, size: 18, color: c.dim),
                      ),
                      IconButton(
                        key: Key('acp-remove-${x.agentId}'),
                        tooltip: AppLocalizations.of(context).g7AcpRemove,
                        onPressed: () => unawaited(_remove(x)),
                        icon: RgIcon(RgIcons.trash, size: 18, color: c.err),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: projects.isEmpty
              ? Text(w('acpNeedProject'), style: TextStyle(color: c.dim))
              : Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    key: const Key('acp-add'),
                    onPressed: () => unawaited(_edit()),
                    icon: const RgIcon(RgIcons.plus, size: 18, color: Colors.white),
                    label: Text(w('acpAdd')),
                  ),
                ),
        ),
        RulesSub(title: w('acpHowTitle')),
        SettingsCard(
          children: [
            for (final n in [1, 2, 3])
              NoteLine(icon: RgIcons.check, text: '${w('acpStep${n}Title')}: ${w('acpStep$n')}'),
          ],
        ),
      ],
    );
  }
}

class _AcpEditor extends StatefulWidget {
  const _AcpEditor({this.worker, required this.presets});

  final AcpWorker? worker;
  final List<AcpPreset> presets;

  @override
  State<_AcpEditor> createState() => _AcpEditorState();
}

class _AcpEditorState extends State<_AcpEditor> {
  late final AppController app = AppScope.read(context);
  late final _name = TextEditingController(text: widget.worker?.name ?? '');
  late final _command = TextEditingController(text: widget.worker?.command ?? '');
  late final _args = TextEditingController(text: widget.worker?.args.join('\n') ?? '');
  late final _env = TextEditingController(
    text: [for (final e in (widget.worker?.env ?? const {}).entries) '${e.key}=${e.value}']
        .join('\n'),
  );
  String? _preset;
  String? _project;
  String? _said;
  bool _ok = false;
  bool _busy = false;

  String w(String k, [Map<String, String> v = const {}]) => wzWord(context, k, v);

  @override
  void initState() {
    super.initState();
    _project = app.projects.firstOrNull?.id;
  }

  @override
  void dispose() {
    for (final t in [_name, _command, _args, _env]) {
      t.dispose();
    }
    super.dispose();
  }

  Map<String, Object?> get _config => {
    'command': _command.text.trim(),
    'args': [
      for (final a in _args.text.split('\n'))
        if (a.trim().isNotEmpty) a.trim(),
    ],
    'env': {
      for (final line in _env.text.split('\n'))
        if (line.contains('='))
          line.substring(0, line.indexOf('=')).trim(): line.substring(line.indexOf('=') + 1),
    },
  };

  void _pick(AcpPreset? p) => setState(() {
    _preset = p?.id ?? 'other';
    if (p != null) {
      _command.text = p.command;
      _args.text = p.args.join('\n');
      if (_name.text.trim().isEmpty) _name.text = p.name;
    }
  });

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _said = null;
    });
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _said = e.message;
          _ok = false;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final editing = widget.worker != null;
    return Material(
      color: c.bg,
      child: ListView(
        key: const Key('acp-editor'),
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            w(editing ? 'acpEditTitle' : 'acpAddTitle'),
            style: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (!editing) ...[
            Text(w('acpWhich'), style: TextStyle(color: c.dim)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.presets)
                  ChoiceChip(
                    key: Key('acp-preset-${p.id}'),
                    label: Text(p.name),
                    selected: _preset == p.id,
                    showCheckmark: false,
                    onSelected: (_) => _pick(p),
                  ),
                ChoiceChip(
                  key: const Key('acp-preset-other'),
                  label: Text(w('acpOther')),
                  selected: _preset == 'other',
                  showCheckmark: false,
                  onSelected: (_) => _pick(null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('acp-name'),
              controller: _name,
              decoration: InputDecoration(labelText: w('acpName')),
            ),
            const SizedBox(height: 8),
            Text(w('acpProject'), style: TextStyle(color: c.dim)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in app.projects)
                  ChoiceChip(
                    key: Key('acp-project-${p.id}'),
                    label: Text(p.name),
                    selected: _project == p.id,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _project = p.id),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('acp-command'),
            controller: _command,
            decoration: InputDecoration(
              labelText: w('acpCommand'),
              helperText: w('acpCommandHelp'),
              helperMaxLines: 4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('acp-args'),
            controller: _args,
            minLines: 1,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: w('acpArgs'),
              helperText: w('acpArgsHelp'),
              helperMaxLines: 4,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('acp-env'),
            controller: _env,
            minLines: 1,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: w('acpEnv'),
              helperText: w('acpEnvHelp'),
              helperMaxLines: 4,
            ),
          ),
          if (_said != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _said!,
                key: const Key('acp-said'),
                style: TextStyle(color: _ok ? c.ok : c.err),
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('acp-try'),
                onPressed: _busy || _command.text.trim().isEmpty
                    ? null
                    : () => unawaited(
                        _run(() async {
                          final r = await app.client!.tryAcpWorker(_config);
                          final signIn = [for (final s in (r['signIn'] as List? ?? const [])) '$s'];
                          if (!mounted) return;
                          setState(() {
                            _ok = true;
                            _said = [
                              w('acpTried', {
                                'name':
                                    '${r['name']}${r['version'] != null ? ' ${r['version']}' : ''}',
                              }),
                              if (signIn.isNotEmpty) w('acpSignIn', {'how': signIn.join(', ')}),
                            ].join(' ');
                          });
                        }),
                      ),
                child: Text(_busy ? w('acpTrying') : w('acpTry')),
              ),
              FilledButton(
                key: const Key('acp-save'),
                onPressed:
                    _busy ||
                        _command.text.trim().isEmpty ||
                        (!editing && (_project == null || _name.text.trim().isEmpty))
                    ? null
                    : () => unawaited(
                        _run(() async {
                          if (editing) {
                            await app.client!.updateAcpWorker(widget.worker!.agentId, _config);
                          } else {
                            await app.client!.createAcpWorker({
                              'name': _name.text.trim(),
                              'projectId': _project,
                              ..._config,
                            });
                          }
                          if (mounted) Navigator.of(this.context).pop(true);
                        }),
                      ),
                child: Text(l.save),
              ),
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
            ],
          ),
        ],
      ),
    );
  }
}
