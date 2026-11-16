// A project open on a computer (G40.17, board C advanced 2): on the left the task's changes and
// the files' tree; in the middle the open documents as tabs (the diff, side by side or inline,
// with keep, discard and comment on every block; a file with its small edit); on the right the
// conversation of the agent who reads the comments. The diff and the file are the phone's
// (G40.11), reused.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../l10n/app_localizations.dart';
import '../../screens/code/diff_tab.dart';
import '../../screens/code/files_tab.dart';
import '../../screens/conversation_screen.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../desk_controller.dart';
import '../desk_menu.dart';
import '../palette.dart';
import 'common.dart';
import '../side_panel.dart' show PanelSurface;
import 'projects_wall.dart' show BranchPill;

/// An open document: a diff (with the file to start from) or a file.
class CodeDoc {
  const CodeDoc.diff(DiffSource this.source, {this.file}) : path = null;
  const CodeDoc.file(String this.path) : source = null, file = null;

  final DiffSource? source;
  final String? file;
  final String? path;

  bool get isDiff => source != null;

  String get id => isDiff ? 'diff:${source!.query}' : 'file:$path';

  @override
  bool operator ==(Object other) => other is CodeDoc && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class CodeView extends StatefulWidget {
  const CodeView({super.key});

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  String? _for;
  GitState? _git;
  final _docs = <CodeDoc>[];
  int _open = 0;
  bool _sideBySide = true;
  Agent? _reader;
  final _tree = <String, List<FileEntry>>{};
  final _expanded = <String>{'.'};

  late final DeskController _desk = DeskScope.read(context);

  @override
  void initState() {
    super.initState();
    _desk.addListener(_pending);
  }

  @override
  void dispose() {
    _desk.removeListener(_pending);
    super.dispose();
  }

  /// A file or a diff asked from elsewhere (the palette, Git).
  void _pending() {
    if (!mounted) return;
    final f = _desk.takeFile();
    if (f != null) _show(CodeDoc.file(f.path));
    final d = _desk.takeDiff();
    if (d != null) _show(CodeDoc.diff(d.source));
  }

  void _show(CodeDoc d) {
    setState(() {
      final i = _docs.indexOf(d);
      if (i >= 0) {
        _docs[i] = d;
        _open = i;
      } else {
        _docs.add(d);
        _open = _docs.length - 1;
      }
    });
  }

  void _close(int i) {
    setState(() {
      _docs.removeAt(i);
      if (_open >= _docs.length) _open = _docs.isEmpty ? 0 : _docs.length - 1;
    });
  }

  Future<void> _start(String pid) async {
    _git = null;
    _docs
      ..clear()
      ..add(const CodeDoc.diff(DiffSource.working()));
    _open = 0;
    _tree.clear();
    _expanded
      ..clear()
      ..add('.');
    await Future.wait([_reloadGit(pid), _list(pid, '.')]);
    _pending();
  }

  Future<void> _reloadGit([String? pid]) async {
    final id = pid ?? _for;
    final c = AppScope.read(context).client;
    if (id == null || c == null) return;
    try {
      final g = await c.gitState(id);
      if (mounted && id == _for) setState(() => _git = g);
    } on ApiException {
      // Without the branch.
    }
  }

  Future<void> _list(String pid, String path) async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final entries = await c.listFiles('project:$pid', path);
      if (mounted && pid == _for) setState(() => _tree[path] = entries);
    } on ApiException {
      // The folder stays closed.
    }
  }

  void _toggle(FileEntry e) {
    final pid = _for;
    if (pid == null) return;
    if (!e.dir) {
      _show(CodeDoc.file(e.path));
      return;
    }
    setState(() => _expanded.contains(e.path) ? _expanded.remove(e.path) : _expanded.add(e.path));
    if (!_tree.containsKey(e.path)) unawaited(_list(pid, e.path));
  }

  List<Widget> _treeRows(RgColors c, String path, int depth) => [
    for (final e in _tree[path] ?? const <FileEntry>[]) ...[
      InkWell(
        key: Key('tree-${e.path}'),
        onTap: () => _toggle(e),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.0 + depth * 14, 4, 8, 4),
          child: Row(
            children: [
              if (e.dir)
                RgIcon(
                  _expanded.contains(e.path) ? RgIcons.chevronDown : RgIcons.chevronRight,
                  size: 13,
                  color: c.dim,
                )
              else
                const SizedBox(width: 13),
              const SizedBox(width: 4),
              RgIcon(e.dir ? RgIcons.folder : RgIcons.file, size: 14, color: c.dim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: c.text),
                ),
              ),
              if (_git?.changes.where((x) => x.path == e.path).firstOrNull case final ch?)
                Text(
                  ch.status == '?' ? 'A' : ch.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(c, ch.status),
                    fontFamily: monoFamily,
                    fontFamilyFallback: monoFallback,
                  ),
                ),
            ],
          ),
        ),
      ),
      if (e.dir && _expanded.contains(e.path)) ..._treeRows(c, e.path, depth + 1),
    ],
  ];

  Color _statusColor(RgColors c, String s) => switch (s) {
    'A' || '?' => c.ok,
    'D' => c.err,
    _ => c.warnText,
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final desk = DeskScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = deskProject(app, desk);
    if (p == null) return const NoProject();
    if (_for != p.id) {
      _for = p.id;
      _reader = null;
      unawaited(_start(p.id));
    }
    final mac = isMacLike(app);
    final ctx = deskCtx(
      app,
      p,
      git: _git,
      reloadGit: _reloadGit,
      openDiff: (s, {file}) => _show(CodeDoc.diff(s, file: file)),
    );
    final changes = _git?.changes ?? const <GitChange>[];
    final left = ListView(
      key: const Key('code-left'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              const Expanded(child: ProjectPicker()),
              if (_git != null) BranchPill(git: _git!),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
          child: InkWell(
            key: const Key('code-goto-file'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => showPalette(context, desk: desk, commands: const [], initial: '# '),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.line),
              ),
              child: Row(
                children: [
                  RgIcon(RgIcons.search, size: 14, color: c.dim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.deskGoToFile, style: TextStyle(fontSize: 13, color: c.dim)),
                  ),
                  KeyCap(shortcutLabel(cmdKey(LogicalKeyboardKey.keyP, mac: mac), l, mac: mac)),
                ],
              ),
            ),
          ),
        ),
        SideHead(l.deskTaskChanges, count: changes.length),
        if (changes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(l.codeClean, style: TextStyle(fontSize: 12.5, color: c.dim)),
          ),
        for (final ch in changes)
          InkWell(
            key: Key('change-${ch.path}'),
            onTap: () => _show(CodeDoc.diff(const DiffSource.working(), file: ch.path)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: Row(
                children: [
                  RgIcon(RgIcons.file, size: 14, color: c.dim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ch.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.text),
                    ),
                  ),
                  Text(
                    ch.status == '?' ? 'A' : ch.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(c, ch.status),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SideHead(l.deskFiles),
        ..._treeRows(c, '.', 0),
      ],
    );
    final doc = _docs.isEmpty ? null : _docs[_open.clamp(0, _docs.length - 1)];
    final tabs = Container(
      height: 38,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (i, d) in _docs.indexed)
                  _DocTab(
                    key: Key('doc-tab-$i'),
                    label: d.isDiff
                        ? '${d.file ?? l.codeTabDiff}${d.file != null ? ' · ${l.deskDiffWord}' : ''}'
                        : d.path!.split('/').last,
                    icon: d.isDiff ? RgIcons.diff : RgIcons.file,
                    on: i == _open,
                    onTap: () => setState(() => _open = i),
                    onClose: () => _close(i),
                  ),
              ],
            ),
          ),
          if (doc?.isDiff ?? false)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Toggle(
                options: [l.deskSideBySide, l.deskInline],
                selected: _sideBySide ? 0 : 1,
                onSelect: (i) => setState(() => _sideBySide = i == 0),
              ),
            ),
        ],
      ),
    );
    final center = doc == null
        ? EmptyState(icon: RgIcons.code, text: l.codePickFile)
        : doc.isDiff
        ? DiffTab(
            key: ValueKey('${p.id}:${doc.id}:${doc.file}'),
            ctx: ctx,
            source: doc.source!,
            startFile: doc.file,
            sideBySide: _sideBySide,
            onReader: (a) {
              if (mounted && a?.id != _reader?.id) setState(() => _reader = a);
            },
          )
        : FileView(key: ValueKey('${p.id}:${doc.path}'), ctx: ctx, path: doc.path!);
    final reader = _reader ?? ctx.lead;
    final sid = ctx.latestSessionOf(reader?.id);
    final right = reader == null || sid == null
        ? EmptyState(icon: RgIcons.chat, text: l.codeNoChat)
        : Navigator(
            key: ValueKey('code-chat:$sid'),
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (_, _, _) => PanelSurface(
                child: ConversationScreen(
                  key: ValueKey(sid),
                  sessionId: sid,
                  agent: reader,
                  embedded: true,
                  headerActions: [
                    IconButton(
                      tooltip: l.deskOpenInPanel,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => desk.show(PanelConversation(sid, agent: reader)),
                      icon: RgIcon(RgIcons.external, size: 17, color: c.dim),
                    ),
                  ],
                ),
              ),
            ),
          );
    final wide = MediaQuery.sizeOf(context).width >= 1240 && desk.panel == null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 250,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: c.line)),
          ),
          child: left,
        ),
        Expanded(
          child: Column(
            children: [
              tabs,
              Expanded(child: center),
            ],
          ),
        ),
        if (wide)
          Container(
            width: 360,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: c.line)),
            ),
            child: right,
          ),
      ],
    );
  }
}

class _DocTab extends StatelessWidget {
  const _DocTab({
    super.key,
    required this.label,
    required this.icon,
    required this.on,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final RgIcons icon;
  final bool on;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 2),
          decoration: BoxDecoration(
            color: on ? c.bg : null,
            border: Border(
              bottom: BorderSide(color: on ? c.accent : Colors.transparent, width: 2),
              right: BorderSide(color: c.line),
            ),
          ),
          child: Row(
            children: [
              RgIcon(icon, size: 14, color: on ? c.text : c.dim),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, color: on ? c.text : c.dim)),
              IconButton(
                tooltip: l.deskClose,
                visualDensity: VisualDensity.compact,
                onPressed: onClose,
                icon: RgIcon(RgIcons.x, size: 13, color: c.dim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.options, required this.selected, required this.onSelect});

  final List<String> options;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.panel2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: c.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, o) in options.indexed)
            Semantics(
              button: true,
              selected: i == selected,
              child: InkWell(
                key: Key('diff-mode-$i'),
                onTap: () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: i == selected ? c.bg : null,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    o,
                    style: TextStyle(fontSize: 12, color: i == selected ? c.text : c.dim),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
