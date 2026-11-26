// G42.17: «Coming from another agent?», the page's ImportFrom.tsx, native: look on this computer
// (the home folder, the projects, a folder of one's own), or a folder or an export's files from
// this device (ChatGPT's or Claude's zip); then everything found, by kind, each with its switch,
// what it already is here, its notes and what is left behind; «Import» starts the server's job, its
// result says what went, with «Undo» and the memories offer; the imports done stay in a history
// that can be taken back. The words are the page's (`imp…`, wizard_words.g.dart).
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../screens/new_agent_screen.dart' show RgSwitch;
import '../setup/wizard/wizard_screen.dart' show wzWord;
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/settings_kit.dart';
import 'automations/automation_kit.dart' show AutoChips;
import 'rules_kit.dart';

/// Files from this device: names and bytes (the system's chooser; a test gives its own).
typedef ImportPick = Future<List<(String, List<int>)>> Function();

Future<List<(String, List<int>)>> _systemPick() async => [
  for (final f in await FilePicker.pickFiles()) (f.name, await f.readAsBytes()),
];

Future<void> openImportSettings(BuildContext context, {ImportPick? pick}) =>
    openRulesPage(context, (panel) => ImportScreen(panel: panel, pick: pick));

const importSources = <String, String>{
  'claude-code': 'Claude Code',
  'codex': 'Codex',
  'cursor': 'Cursor',
  'gemini': 'Gemini',
  'opencode': 'opencode',
  'hermes': 'Hermes',
  'chatgpt': 'ChatGPT',
  'claude': 'Claude',
};
const importKinds = ['project', 'instructions', 'skill', 'mcp', 'memory', 'conversation'];

extension ImportApi on RedGiantClient {
  Future<Map<String, dynamic>> importScan({
    bool home = true,
    bool projects = true,
    bool claudeProjects = true,
    String? folder,
  }) async => objectOf(
    await callJson('POST', '/api/import/scan', {
      'home': home,
      'projects': projects,
      'claudeProjects': claudeProjects,
      if (folder != null && folder.trim().isNotEmpty) 'folder': folder.trim(),
    }),
  );
  Future<String> importUpload() async =>
      '${objectOf(await callJson('POST', '/api/import/upload', const {}))['id']}';
  Future<void> importFile(String id, String path, List<int> bytes) =>
      putBytes('/api/import/upload/${Uri.encodeComponent(id)}', bytes, query: {'path': path});
  Future<Map<String, dynamic>> importPreview(String id) async => objectOf(
    await callJson('POST', '/api/import/upload/${Uri.encodeComponent(id)}/preview', const {}),
  );
  Future<String> importApply(String id, List<Map<String, Object?>> choices) async =>
      '${objectOf(await callJson('POST', '/api/import/apply', {'id': id, 'choices': choices}))['id']}';
  Future<Map<String, dynamic>> importJob(String id) async =>
      objectOf(await getJson('/api/jobs/${Uri.encodeComponent(id)}'));
  Future<List<Map<String, dynamic>>> importHistory() async =>
      arrayOf(await getJson('/api/import/history'));
  Future<Map<String, dynamic>> importUndo(String id) async =>
      objectOf(await callJson('POST', '/api/import/${Uri.encodeComponent(id)}/undo', const {}));
  Future<Map<String, dynamic>> importMemories(String id) async =>
      objectOf(await callJson('POST', '/api/import/${Uri.encodeComponent(id)}/memories', const {}));
}

class ImportScreen extends StatefulWidget {
  const ImportScreen({
    super.key,
    required this.panel,
    this.pick,
    this.poll = const Duration(seconds: 1),
  });

  final bool panel;
  final ImportPick? pick;
  final Duration poll;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late final AppController app = AppScope.read(context);
  List<Map<String, dynamic>>? _history;
  Map<String, dynamic>? _preview;
  final _on = <String, bool>{};
  Map<String, dynamic>? _done;
  String? _working;
  String? _error;
  bool _home = true;
  bool _projects = true;
  bool _claude = true;

  /// A project's way in (alpha 4.0): adopt, copy or clone, and whether its notes go to the Knowledge.
  final _mode = <String, String>{};
  final _knowledge = <String, bool>{};
  final _folder = TextEditingController();
  bool _scanning = false;

  RedGiantClient get _c => app.client!;
  String w(String k, [Map<String, String> v = const {}]) => wzWord(context, k, v);

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  @override
  void dispose() {
    _folder.dispose();
    super.dispose();
  }

  Future<void> _try(Future<void> Function() f) async {
    setState(() => _error = null);
    try {
      await f();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _loadHistory() => _try(() async {
    final h = await _c.importHistory();
    if (mounted) setState(() => _history = h);
  });

  void _show(Map<String, dynamic> p) {
    _on.clear();
    for (final i in (p['items'] as List? ?? const []).whereType<Map<dynamic, dynamic>>()) {
      _on['${i['id']}'] = i['on'] == true;
    }
    setState(() {
      _preview = p;
      _done = null;
      _scanning = false;
    });
  }

  Future<void> _scan() => _try(() async {
    setState(() => _working = w('impLooking'));
    try {
      _show(
        await _c.importScan(
          home: _home,
          projects: _projects,
          claudeProjects: _claude,
          folder: _folder.text,
        ),
      );
    } finally {
      if (mounted) setState(() => _working = null);
    }
  });

  Future<void> _upload() => _try(() async {
    final files = await (widget.pick ?? _systemPick)();
    if (files.isEmpty || !mounted) return;
    setState(() => _working = w('impUploading'));
    try {
      final id = await _c.importUpload();
      for (final (name, bytes) in files) {
        await _c.importFile(id, name, bytes);
      }
      _show(await _c.importPreview(id));
    } finally {
      if (mounted) setState(() => _working = null);
    }
  });

  Future<void> _apply() => _try(() async {
    final p = _preview!;
    final choices = [
      for (final i in (p['items'] as List).whereType<Map<dynamic, dynamic>>())
        if (_on['${i['id']}'] == true)
          {
            'id': '${i['id']}',
            'on': true,
            if (i['kind'] == 'project') ...{
              'mode': _mode['${i['id']}'] ?? _modes(i).firstOrNull,
              'knowledge': _knowledge['${i['id']}'] ?? true,
            },
          },
    ];
    setState(() => _working = w('impDo', {'n': '${choices.length}'}));
    try {
      final job = await _c.importApply('${p['id']}', choices);
      for (;;) {
        final j = await _c.importJob(job);
        if (j['state'] == 'done') {
          if (mounted)
            setState(
              () => _done =
                  (j['result'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? const {},
            );
          break;
        }
        if (j['state'] == 'failed' || j['state'] == 'cancelled') {
          final e = j['error'];
          throw ApiException(0, e is Map<dynamic, dynamic> ? '${e['message']}' : '${j['state']}');
        }
        await Future<void>.delayed(widget.poll);
        if (!mounted) return;
      }
      if (mounted) setState(() => _preview = null);
      await _loadHistory();
    } finally {
      if (mounted) setState(() => _working = null);
    }
  });

  Future<void> _undo(String id) => _try(() async {
    final r = await _c.importUndo(id);
    if (mounted && _done?['id'] == id) setState(() => _done = r);
    await _loadHistory();
  });

  Future<void> _memories(String id) => _try(() async => _show(await _c.importMemories(id)));

  String _when(String iso) {
    final t = DateTime.tryParse(iso)?.toLocal();
    if (t == null) return iso;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return RulesPage(
      pageKey: const Key('imp-page'),
      panel: widget.panel,
      title: w('impEyebrow'),
      question: w('impQ'),
      lead: w('impLead'),
      children: [
        if (_error != null) NoticeBanner(key: const Key('imp-error'), text: _error!, error: true),
        if (_working != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  _working!,
                  key: const Key('imp-working'),
                  style: TextStyle(color: c.dim),
                ),
                const LinearProgressIndicator(minHeight: 3),
              ],
            ),
          ),
        if (_done != null) _doneCard(c, l),
        if (_preview != null)
          ..._previewParts(c, l)
        else ...[
          if (_scanning) _scanCard(c) else _ways(c),
          SettingsCard(
            children: [
              NoteLine(icon: RgIcons.info, strong: true, text: w('impHowExport')),
              NoteLine(icon: RgIcons.chat, text: w('impHowChatgpt')),
              NoteLine(icon: RgIcons.chat, text: w('impHowClaude')),
            ],
          ),
        ],
        if ((_history ?? const []).isNotEmpty) ...[
          RulesSub(title: w('impHistory'), lead: w('impHistoryLead')),
          SettingsCard(
            key: const Key('imp-history'),
            children: [
              for (final h in _history!)
                ListTile(
                  key: Key('imp-history-${h['id']}'),
                  title: Text(
                    [
                      for (final s in (h['sources'] as List? ?? const []))
                        importSources['$s'] ?? '$s',
                    ].join(', '),
                  ),
                  subtitle: Text(
                    [
                      _when('${h['createdAt']}'),
                      w('impHistoryItems', {
                        'n':
                            '${(h['done'] as List? ?? const []).whereType<Map<dynamic, dynamic>>().where((d) => d['ok'] == true).length}',
                      }),
                      if (h['undoneAt'] != null) w('impUndoneShort'),
                    ].join(' · '),
                  ),
                  trailing: h['undoneAt'] != null
                      ? null
                      : TextButton(
                          key: Key('imp-undo-${h['id']}'),
                          onPressed: () => unawaited(_undo('${h['id']}')),
                          child: Text(w('impUndo')),
                        ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _ways(RgColors c) => SettingsCard(
    key: const Key('imp-ways'),
    children: [
      for (final (k, icon, title, text, act) in [
        (
          'scan',
          RgIcons.search,
          w('impWayScan'),
          w('impWayScanText'),
          () => setState(() => _scanning = true),
        ),
        (
          'folder',
          RgIcons.folder,
          w('impWayFolder'),
          w('impWayFolderText'),
          () => unawaited(_upload()),
        ),
        (
          'export',
          RgIcons.upload,
          w('impWayExport'),
          w('impWayExportText'),
          () => unawaited(_upload()),
        ),
      ])
        ListTile(
          key: Key('imp-way-$k'),
          leading: RgIcon(icon, color: c.accent),
          title: Text(title),
          subtitle: Text(text),
          trailing: RgIcon(RgIcons.chevronRight, color: c.dim),
          onTap: _working == null ? act : null,
        ),
    ],
  );

  Widget _scanCard(RgColors c) => SettingsCard(
    key: const Key('imp-scan'),
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(w('impScanLead'), style: TextStyle(color: c.dim)),
      ),
      _switch('imp-scan-home', w('impScanHome'), w('impScanHomeHelp'), _home, (v) => _home = v),
      _switch(
        'imp-scan-claude',
        w('impScanClaude'),
        w('impScanClaudeHelp'),
        _claude,
        (v) => _claude = v,
      ),
      _switch(
        'imp-scan-projects',
        w('impScanProjects'),
        w('impScanProjectsHelp'),
        _projects,
        (v) => _projects = v,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: TextField(
          key: const Key('imp-scan-folder'),
          controller: _folder,
          decoration: InputDecoration(
            labelText: w('impScanFolder'),
            helperText: w('impScanFolderHelp'),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(w('impScanPromise'), style: TextStyle(color: c.dim, fontSize: 12.5)),
            Row(
              spacing: 8,
              children: [
                FilledButton(
                  key: const Key('imp-scan-go'),
                  onPressed:
                      _working != null ||
                          (!_home && !_projects && !_claude && _folder.text.trim().isEmpty)
                      ? null
                      : () => unawaited(_scan()),
                  child: Text(w('impScanGo')),
                ),
                TextButton(
                  onPressed: () => setState(() => _scanning = false),
                  child: Text(AppLocalizations.of(context).back),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  Widget _switch(String key, String title, String help, bool on, void Function(bool) set) =>
      InkWell(
        key: Key(key),
        onTap: () => setState(() => set(!on)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: RgColors.of(context).text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(help, style: TextStyle(color: RgColors.of(context).dim, fontSize: 12.5)),
                  ],
                ),
              ),
              RgSwitch(on: on),
            ],
          ),
        ),
      );

  List<String> _modes(Map<dynamic, dynamic> i) => [
    for (final m in ((i['project'] as Map<dynamic, dynamic>?)?['modes'] as List? ?? const [])) '$m',
  ];

  /// A whole project (alpha 4.0): what it would bring and, when chosen, how it comes (as the page's).
  List<Widget> _projectParts(Map<dynamic, dynamic> i, Map<dynamic, dynamic> pr, RgColors c) {
    final id = '${i['id']}';
    final dim = TextStyle(color: c.dim, fontSize: 12);
    final remote = pr['remote'];
    final secrets = (pr['secrets'] as List? ?? const []).map((x) => '$x').toList();
    final machine = (pr['machine'] as List? ?? const [])
        .whereType<Map<dynamic, dynamic>>()
        .toList();
    final modes = _modes(i);
    final mode = _mode[id] ?? modes.firstOrNull;
    final instructions = (pr['instructions'] as List? ?? const []).map((x) => '$x').toList();
    return [
      Text(
        remote != null
            ? '${w('impProjRemote')}: $remote'
            : pr['git'] == true
            ? w('impProjGitLocal')
            : w('impProjNoGit'),
        style: dim,
      ),
      Text(
        w('impProjFacts', {
          'instructions': instructions.isEmpty
              ? w('impProjNoInstructions')
              : instructions.join(', '),
          'notes': '${pr['notes'] ?? 0}',
          'memory': '${pr['memory'] ?? 0}',
          'conversations': '${pr['conversations'] ?? 0}',
          'size': '${((pr['bytes'] as num? ?? 0) / 1e6).round().clamp(1, 1 << 30)} MB',
        }),
        style: dim,
      ),
      if (secrets.isNotEmpty)
        Text(w('impProjSecrets', {'files': secrets.take(6).join(', ')}), style: dim),
      if (machine.isNotEmpty) Text(w('impProjMachine', {'n': '${machine.length}'}), style: dim),
      if ((_on[id] ?? false) && modes.isNotEmpty) ...[
        AutoChips<String>(
          key: Key('imp-mode-$id'),
          options: [for (final m in modes) (m, w('impProjMode_$m'))],
          value: [?mode],
          keyOf: (m) => 'imp-mode-$id-$m',
          onChanged: (v) {
            if (v.isNotEmpty) setState(() => _mode[id] = v.first);
          },
        ),
        if (mode != null) Text(w('impProjModeHelp_$mode'), style: dim),
        if ((pr['notes'] as num? ?? 0) > 0 || (pr['memory'] as num? ?? 0) > 0)
          InkWell(
            key: Key('imp-knowledge-$id'),
            onTap: () => setState(() => _knowledge[id] = !(_knowledge[id] ?? true)),
            child: Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(w('impProjKnowledge'), style: TextStyle(color: c.text)),
                ),
                RgSwitch(on: _knowledge[id] ?? true),
              ],
            ),
          ),
      ],
    ];
  }

  String _note(Map<dynamic, dynamic> n) {
    final key = 'impNote_${n['code']}';
    final said = w(key, {'arg': '${n['arg'] ?? ''}'});
    return said == key ? '${n['code']}' : said;
  }

  List<Widget> _previewParts(RgColors c, AppLocalizations l) {
    final p = _preview!;
    final items = (p['items'] as List? ?? const []).whereType<Map<dynamic, dynamic>>().toList();
    final chosen = items.where((i) => _on['${i['id']}'] == true).length;
    final left = (p['left'] as List? ?? const []).whereType<Map<dynamic, dynamic>>().toList();
    return [
      RulesSub(
        title: w('impFoundTitle'),
        lead: w('impFoundSub', {'n': '${items.length}', 'files': '${p['read'] ?? 0}'}),
      ),
      if (items.isEmpty) NoteLine(icon: RgIcons.info, text: w('impNothing')),
      for (final k in importKinds)
        if (items.any((i) => i['kind'] == k)) ...[
          SectionHead(w('impKind_$k')),
          SettingsCard(
            key: Key('imp-kind-$k'),
            children: [
              for (final i in items.where((i) => i['kind'] == k))
                InkWell(
                  key: Key('imp-item-${i['id']}'),
                  onTap: () => setState(() => _on['${i['id']}'] = !(_on['${i['id']}'] ?? false)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      spacing: 12,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                '${i['name']}',
                                style: TextStyle(color: c.text, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                [
                                  importSources['${i['source']}'] ?? '${i['source']}',
                                  '${i['from']}',
                                  if (i['exists'] == 'same') w('impSame'),
                                  if (i['exists'] == 'taken') w('impTaken'),
                                ].join(' · '),
                                style: TextStyle(color: c.dim, fontSize: 12),
                              ),
                              if ('${i['preview'] ?? ''}'.isNotEmpty)
                                Text(
                                  '${i['preview']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: c.dim, fontSize: 12.5),
                                ),
                              for (final n
                                  in (i['notes'] as List? ?? const [])
                                      .whereType<Map<dynamic, dynamic>>())
                                Text(_note(n), style: TextStyle(color: c.warnText, fontSize: 12)),
                              if (i['project'] case final Map<dynamic, dynamic> pr)
                                ..._projectParts(i, pr, c),
                            ],
                          ),
                        ),
                        RgSwitch(on: _on['${i['id']}'] ?? false),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      if (left.isNotEmpty) ...[
        RulesSub(title: w('impLeftTitle'), lead: w('impLeftLead')),
        SettingsCard(
          children: [
            for (final x in left) NoteLine(icon: RgIcons.minus, text: '${x['from']}: ${x['what']}'),
          ],
        ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const Key('imp-do'),
              onPressed: _working != null || chosen == 0 ? null : () => unawaited(_apply()),
              child: Text(w('impDo', {'n': '$chosen'})),
            ),
            TextButton(
              key: const Key('imp-cancel'),
              onPressed: () => setState(() => _preview = null),
              child: Text(l.cancel),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _doneCard(RgColors c, AppLocalizations l) {
    final r = _done!;
    final done = (r['done'] as List? ?? const []).whereType<Map<dynamic, dynamic>>().toList();
    final ok = done.where((d) => d['ok'] == true).toList();
    final bad = done.where((d) => d['ok'] != true).toList();
    final convs = ok.where((d) => d['kind'] == 'conversation').length;
    final undone = r['undoneAt'] != null;
    return SettingsCard(
      key: const Key('imp-done'),
      children: [
        NoteLine(
          icon: RgIcons.check,
          color: c.ok,
          strong: true,
          text: undone
              ? w('impUndone')
              : w('impDoneLead', {'ok': '${ok.length}', 'n': '${done.length}'}),
        ),
        if (!undone)
          for (final k in importKinds)
            if (ok.any((d) => d['kind'] == k))
              NoteLine(
                icon: RgIcons.check,
                text: '${w('impKind_$k')}: ${ok.where((d) => d['kind'] == k).length}',
              ),
        for (final d in bad)
          NoteLine(icon: RgIcons.alert, color: c.err, text: '${d['name']}: ${d['error'] ?? ''}'),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (!undone)
                OutlinedButton(
                  key: const Key('imp-done-undo'),
                  onPressed: () => unawaited(_undo('${r['id']}')),
                  child: Text(w('impUndo')),
                ),
              if (!undone && convs > 0)
                OutlinedButton(
                  key: const Key('imp-memories'),
                  onPressed: () => unawaited(_memories('${r['id']}')),
                  child: Text(w('impMemOfferBtn')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
