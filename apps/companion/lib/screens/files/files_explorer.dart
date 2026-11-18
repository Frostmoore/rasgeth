// The conversation's files (G42.5, the page's `Explorer.tsx`): the tree of the conversation's
// place (its project, the personal agents' desk, or God's platform, as `currentScope`), with the
// page's actions and routes: new file and folder, upload (a taken name asks: keep both, replace,
// skip; a `.rgartifact` is imported), hidden files, refresh, terminal, rename, download, delete
// (to `.trash`, for good inside it), copy the path, ask the agent, open in the Canvas. An
// archived project's files are read only (the server refuses changes too: 423). On a computer
// files dropped from the system go into the folder under the pointer, and a file dragged from the
// tree onto the conversation is attached to the message.
import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/conversation.dart';
import '../../api/types.dart';
import '../../app_state.dart';
import '../../desktop/drops.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/dialogs.dart';
import '../../ui/file_icons.dart';
import '../../ui/highlight.dart' show monoFallback, monoFamily;
import '../../ui/icons.dart';
import '../code/files_tab.dart' show sizeWords;
import '../../terminal/terminal_screen.dart';
import '../code/project_screen.dart' show say, showApiError;

/// Where a conversation's files are: the page's `currentScope` for an agent's tab.
class ExplorerPlace {
  const ExplorerPlace({required this.scope, this.project, this.readOnly = false, this.focus});

  /// `project:<id>`, `assistants` or `platform` (the routes' scope).
  final String scope;

  /// The project, when the place is one (its name is the panel's title).
  final Project? project;

  /// An archived project's files: shown, never changed.
  final bool readOnly;

  /// A subproject's folder (G24.13): shown open, with the ones above it, as the page's `reveal`.
  final String? focus;

  bool get assistants => scope == 'assistants';

  @override
  bool operator ==(Object other) =>
      other is ExplorerPlace &&
      other.scope == scope &&
      other.readOnly == readOnly &&
      other.focus == focus;

  @override
  int get hashCode => Object.hash(scope, readOnly, focus);
}

/// The folders to open for [focus]: each one above it, then itself (`a`, `a/b`).
List<String> foldersToReveal(String? focus) {
  final f = focus?.replaceAll(RegExp(r'^/+|/+$'), '') ?? '';
  if (f.isEmpty) return const [];
  final parts = f.split('/');
  return [for (var i = 1; i <= parts.length; i++) parts.take(i).join('/')];
}

/// The place of [agent]'s conversation: the personal agents' shared desk, its project (archived:
/// read only), or God's platform.
ExplorerPlace explorerPlaceOf({
  Agent? agent,
  String? sessionProjectId,
  List<Project> projects = const [],
  List<Project> archived = const [],
  List<Subproject> subprojects = const [],
}) {
  if (agent?.kind == AgentKind.assistant) return const ExplorerPlace(scope: 'assistants');
  final id = agent?.projectId ?? sessionProjectId;
  if (id == null) return const ExplorerPlace(scope: 'platform');
  final open = projects.where((p) => p.id == id).firstOrNull;
  final old = archived.where((p) => p.id == id).firstOrNull;
  final p = open ?? old;
  // A subproject's agent: the files open on its folder (G24.13, the page's `currentScope`).
  final sub = agent?.subprojectId == null
      ? null
      : subprojects.where((x) => x.id == agent!.subprojectId).firstOrNull;
  return ExplorerPlace(
    scope: 'project:$id',
    project: p,
    readOnly: (p?.archived ?? false) || (open == null && old != null),
    focus: sub?.dir,
  );
}

/// The place of a conversation in the app.
ExplorerPlace explorerPlaceFor(AppController app, String sessionId, Agent? agent) {
  final row = app.live.sessions.where((s) => s.id == sessionId).firstOrNull;
  return explorerPlaceOf(
    agent: agent,
    sessionProjectId: row?.projectId,
    projects: app.projects,
    archived: app.archivedProjects,
    subprojects: app.subprojects,
  );
}

/// A file dragged from the tree (onto the conversation: attached to the message).
class ExplorerFileDrag {
  const ExplorerFileDrag({
    required this.scope,
    required this.path,
    required this.name,
    required this.size,
  });

  final String scope;
  final String path;
  final String name;
  final int size;
}

typedef ExplorerSaver = Future<bool> Function(String name, Uint8List bytes);
typedef ExplorerPicker = Future<List<(String, Uint8List)>> Function();

Future<bool> _saveWithPicker(String name, Uint8List bytes) async =>
    await FilePicker.saveFile(fileName: name, bytes: bytes) != null;

Future<List<(String, Uint8List)>> _pickWithPicker() async {
  final out = <(String, Uint8List)>[];
  for (final f in await FilePicker.pickFiles()) {
    out.add((f.name, await f.readAsBytes()));
  }
  return out;
}

const _hiddenPref = 'explorerHidden';

enum _RowAct { open, ask, copyPath, rename, download, delete }

/// The files panel (computer) or screen (phone).
class FilesExplorer extends StatefulWidget {
  const FilesExplorer({
    super.key,
    required this.place,
    required this.onOpen,
    this.onAsk,
    this.onClose,
    this.onFull,
    this.full = false,
    this.computer = false,
    this.saveFile,
    this.pickFiles,
    this.onTerminal,
  });

  final ExplorerPlace place;

  /// «Terminal» (G42.5): on a computer the conversation's right column opens one in a tab; null:
  /// the whole screen (a phone).
  final void Function(String scope, String title)? onTerminal;

  /// A file opens in the Canvas (the same tab an agent showing it would open).
  final void Function(String path, String name) onOpen;

  /// «Ask the agent»: the file goes into the conversation's composer.
  final void Function(String path)? onAsk;

  /// The panel's ×, or the phone's «back».
  final VoidCallback? onClose;

  /// «Full window» and back (null: no such button).
  final VoidCallback? onFull;
  final bool full;

  /// A computer: hover actions, right click, drops from the system, drag to the conversation.
  final bool computer;

  /// Tests give their own.
  final ExplorerSaver? saveFile;
  final ExplorerPicker? pickFiles;

  @override
  State<FilesExplorer> createState() => _FilesExplorerState();
}

class _FilesExplorerState extends State<FilesExplorer> {
  late AppController app;

  /// Each folder's entries once read ('.' is the root); null while it loads.
  final _kids = <String, List<FileEntry>?>{};
  final _failed = <String>{};
  final _open = <String>{};
  FileEntry? _selected;
  bool _hidden = false;
  int _busy = 0;

  /// A name already taken: the person picks keep both, replace or skip.
  ({String name, Completer<String?> answer})? _taken;

  final _query = TextEditingController();
  List<SearchHit>? _hits;
  Timer? _debounce;

  /// Files from the system hovering: the folder they would go into ('' the root).
  String? _dropDir;
  final _dropKey = GlobalKey(debugLabel: 'files-drop');
  final _rowKeys = <String, GlobalKey>{};

  RedGiantClient get _client => app.client!;
  String get _scope => widget.place.scope;
  bool get _readOnly => widget.place.readOnly;

  @override
  void initState() {
    super.initState();
    app = AppScope.read(context);
    DropClaims.add(_dropKey);
    unawaited(_loadHidden());
    unawaited(_load('.'));
    _reveal();
  }

  /// A subproject's folder shown open, with the ones above it (the page's `reveal`).
  void _reveal() {
    final dirs = foldersToReveal(widget.place.focus);
    if (dirs.isEmpty) return;
    _open.addAll(dirs);
    for (final d in dirs) {
      unawaited(_load(d));
    }
  }

  @override
  void didUpdateWidget(FilesExplorer old) {
    super.didUpdateWidget(old);
    if (old.place.scope != widget.place.scope) {
      _kids.clear();
      _open.clear();
      _selected = null;
      _hits = null;
      _query.clear();
      unawaited(_load('.'));
      _reveal();
    } else if (old.place.focus != widget.place.focus) {
      _reveal();
    }
  }

  @override
  void dispose() {
    DropClaims.remove(_dropKey);
    _debounce?.cancel();
    _query.dispose();
    _taken?.answer.complete(null);
    super.dispose();
  }

  Future<void> _loadHidden() async {
    final v = await app.prefs.get(_hiddenPref) == '1';
    if (mounted && v != _hidden) setState(() => _hidden = v);
  }

  Future<void> _load(String dir) async {
    try {
      final e = await _client.listFiles(_scope, dir);
      if (!mounted) return;
      setState(() {
        _kids[dir] = e;
        _failed.remove(dir);
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _failed.add(dir);
        // A folder gone (renamed, deleted elsewhere) closes.
        if (dir != '.') _open.remove(dir);
      });
    }
  }

  /// The root and every open folder again (after a change, or «Refresh»).
  Future<void> _reload() async {
    await Future.wait([_load('.'), for (final d in _open.toList()) _load(d)]);
  }

  /// Where new things go: the folder selected, or the selected file's folder ('' the root).
  String get _base {
    final s = _selected;
    if (s == null) return '';
    if (s.dir) return s.path;
    final i = s.path.lastIndexOf('/');
    return i < 0 ? '' : s.path.substring(0, i);
  }

  String _join(String name) => _base.isEmpty ? name : '$_base/$name';

  /// A change: done, then the tree again; a refusal said in words.
  Future<bool> _act(Future<void> Function() f) async {
    try {
      await f();
      await _reload();
      return true;
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
      return false;
    }
  }

  void _toggle(FileEntry e) {
    setState(() {
      _selected = e;
      if (!_open.remove(e.path)) {
        _open.add(e.path);
        if (_kids[e.path] == null) unawaited(_load(e.path));
      }
    });
  }

  void _openFile(String path, String name) => widget.onOpen(path, name);

  void _tap(FileEntry e) {
    if (e.dir) {
      _toggle(e);
    } else {
      setState(() => _selected = e);
      _openFile(e.path, e.name);
    }
  }

  // ---- the header's actions ----

  Future<void> _newFile() async {
    final l = AppLocalizations.of(context);
    final n = await askText(
      context,
      title: l.fxNewFile,
      initial: _join(''),
      yes: l.fxMake,
      hint: l.fxPathHint,
      fieldKey: const Key('files-new-name'),
    );
    if (n == null || n.trim().isEmpty || n.endsWith('/')) return;
    await _act(() => _client.saveText(_scope, n.trim(), ''));
  }

  Future<void> _newFolder() async {
    final l = AppLocalizations.of(context);
    final n = await askText(
      context,
      title: l.fxNewFolder,
      initial: _join(''),
      yes: l.fxMake,
      hint: l.fxPathHint,
      fieldKey: const Key('files-new-name'),
    );
    final path = n?.trim().replaceFirst(RegExp(r'/+$'), '');
    if (path == null || path.isEmpty) return;
    if (await _act(() => _client.fileOp('mkdir', _scope, path))) {
      // The new folder shows open, ready for what goes in it.
      final up = path.split('/');
      for (var i = 1; i < up.length; i++) {
        _open.add(up.take(i).join('/'));
      }
      await _reload();
    }
  }

  Future<void> _pickAndUpload() async {
    final files = await (widget.pickFiles ?? _pickWithPicker)();
    if (files.isEmpty || !mounted) return;
    await _upload(_base, files);
  }

  /// The person's choice for a taken name: `keep-both`, `replace`, or null (skip).
  Future<String?> _askTaken(String name) {
    final c = Completer<String?>();
    setState(() => _taken = (name: name, answer: c));
    return c.future.whenComplete(() {
      if (mounted) setState(() => _taken = null);
    });
  }

  /// Uploads one by one into [dir]; a taken name asks before anything is overwritten.
  Future<void> _upload(String dir, List<(String, Uint8List)> files) async {
    if (_readOnly) return;
    final l = AppLocalizations.of(context);
    setState(() => _busy++);
    var done = 0;
    try {
      for (final (name, bytes) in files) {
        // An artifact from another RedGiant (3.5.9): checked on the server, written into this
        // place's artefatti/ with no permissions, opened on its source; never run here.
        if (name.toLowerCase().endsWith('.rgartifact')) {
          try {
            final r = await _client.importArtifact(_scope, bytes);
            done++;
            if (r.path.isNotEmpty) _openFile(r.path, r.path.split('/').last);
          } on ApiException catch (e) {
            if (mounted) showApiError(context, e);
          }
          continue;
        }
        final path = dir.isEmpty || dir == '.' ? name : '$dir/$name';
        try {
          await _client.uploadFile(_scope, path, bytes, ifExists: 'fail');
          done++;
        } on ApiException catch (e) {
          if (e.status != 409) {
            if (mounted) showApiError(context, e);
            continue;
          }
          final choice = await _askTaken(path);
          if (choice == null) continue;
          try {
            await _client.uploadFile(_scope, path, bytes, ifExists: choice);
            done++;
          } on ApiException catch (e) {
            if (mounted) showApiError(context, e);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _busy--);
    }
    if (dir.isNotEmpty && dir != '.') _open.add(dir);
    await _reload();
    if (mounted && done > 0) say(context, l.fxUploaded(done));
  }

  Future<void> _setHidden(bool v) async {
    setState(() => _hidden = v);
    await app.prefs.set(_hiddenPref, v ? '1' : null);
  }

  /// The page's terminal button: a shell in this place (project, personal agents' desk or
  /// platform), titled «Terminal · the place»; never in an archived project.
  void _terminal() {
    final l = AppLocalizations.of(context);
    final p = widget.place;
    final title = terminalTitle(
      l,
      p.project?.name ?? (p.assistants ? l.fxAssistants : l.fxPlatform),
    );
    final beside = widget.onTerminal;
    if (beside != null) {
      beside(p.scope, title);
      return;
    }
    unawaited(openTerminalScreen(context, scope: p.scope, title: title));
  }

  // ---- a row's actions ----

  Future<void> _rename(FileEntry e) async {
    final l = AppLocalizations.of(context);
    final to = await askText(
      context,
      title: l.fxRename,
      initial: e.path,
      yes: l.fxRename,
      hint: l.fxPathHint,
      fieldKey: const Key('files-rename-to'),
    );
    final t = to?.trim();
    if (t == null || t.isEmpty || t == e.path) return;
    if (await _act(() => _client.fileOp('rename', _scope, e.path, to: t))) {
      if (_selected?.path == e.path) setState(() => _selected = null);
    }
  }

  Future<void> _download(FileEntry e) async {
    final l = AppLocalizations.of(context);
    try {
      final bytes = await _client.fileRaw(_scope, e.path);
      final saved = await (widget.saveFile ?? _saveWithPicker)(e.name, bytes);
      if (saved && mounted) say(context, l.fxDownloaded(e.name));
    } on ApiException catch (err) {
      if (mounted) showApiError(context, err);
    }
  }

  Future<void> _delete(FileEntry e) async {
    final l = AppLocalizations.of(context);
    final forGood = e.path == '.trash' || e.path.startsWith('.trash/');
    final yes = await askConfirm(
      context,
      title: l.fxDelete,
      body: forGood ? l.fxConfirmDeleteForGood(e.path) : l.fxConfirmDelete(e.path),
      yes: l.fxDelete,
      danger: true,
    );
    if (!yes || !mounted) return;
    if (await _act(() => _client.fileOp('delete', _scope, e.path))) {
      if (_selected?.path == e.path) setState(() => _selected = null);
      _open.removeWhere((p) => p == e.path || p.startsWith('${e.path}/'));
    }
  }

  Future<void> _run(FileEntry e, _RowAct a) async {
    final l = AppLocalizations.of(context);
    switch (a) {
      case _RowAct.open:
        _tap(e);
      case _RowAct.ask:
        widget.onAsk?.call(e.path);
      case _RowAct.copyPath:
        await Clipboard.setData(ClipboardData(text: e.path));
        if (mounted) say(context, l.codePathCopied);
      case _RowAct.rename:
        await _rename(e);
      case _RowAct.download:
        await _download(e);
      case _RowAct.delete:
        await _delete(e);
    }
  }

  List<(_RowAct, Widget, String, bool)> _actsOf(FileEntry e, AppLocalizations l, RgColors c) => [
    if (!e.dir) (_RowAct.open, RgIcon(RgIcons.canvas, size: 17, color: c.dim), l.fxOpen, false),
    if (widget.onAsk != null && !_readOnly)
      (_RowAct.ask, RgIcon(RgIcons.chat, size: 17, color: c.dim), l.fxAsk, false),
    (_RowAct.copyPath, RgIcon(RgIcons.copy, size: 17, color: c.dim), l.codeCopyPath, false),
    if (!_readOnly)
      (_RowAct.rename, FileGlyphIcon(FileGlyph.pencil, size: 16, color: c.dim), l.fxRename, false),
    if (!e.dir)
      (_RowAct.download, RgIcon(RgIcons.download, size: 17, color: c.dim), l.fxDownload, false),
    if (!_readOnly)
      (_RowAct.delete, RgIcon(RgIcons.trash, size: 17, color: c.err), l.fxDelete, true),
  ];

  /// The computer's menu, at [at] (global coordinates).
  Future<void> _menu(FileEntry e, Offset at) async {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    setState(() => _selected = e);
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final local = overlay.globalToLocal(at);
    final pick = await showMenu<_RowAct>(
      context: context,
      position: RelativeRect.fromRect(local & const Size(1, 1), Offset.zero & overlay.size),
      color: c.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.line),
      ),
      items: [
        for (final (a, icon, text, danger) in _actsOf(e, l, c)) ...[
          if (a == _RowAct.delete) const PopupMenuDivider(height: 8),
          PopupMenuItem(
            key: Key('files-menu-${a.name}'),
            value: a,
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: danger ? c.err : c.text, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
    if (pick != null && mounted) await _run(e, pick);
  }

  /// The phone's sheet of a row.
  Future<void> _sheet(FileEntry e) async {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    setState(() => _selected = e);
    final pick = await showModalBottomSheet<_RowAct>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  if (e.dir) const FolderIcon(size: 20) else FileIcon(name: e.name, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                    ),
                  ),
                ],
              ),
            ),
            for (final (a, icon, text, danger) in _actsOf(e, l, c))
              ListTile(
                key: Key('files-menu-${a.name}'),
                leading: icon,
                title: Text(text, style: TextStyle(color: danger ? c.err : c.text)),
                onTap: () => Navigator.pop(context, a),
              ),
          ],
        ),
      ),
    );
    if (pick != null && mounted) await _run(e, pick);
  }

  // ---- search ----

  void _search(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _hits = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final h = await _client.searchFiles(_scope, q.trim());
        if (mounted && _query.text == q) setState(() => _hits = h);
      } on ApiException catch (e) {
        if (mounted) showApiError(context, e);
      }
    });
  }

  // ---- files from the system (computer) ----

  /// The open folder under [global], or the root.
  String _folderAt(Offset global) {
    String? best;
    for (final MapEntry(key: path, value: k) in _rowKeys.entries) {
      final box = k.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      if (!(Offset.zero & box.size).contains(box.globalToLocal(global))) continue;
      final entry = _entryAt(path);
      if (entry == null) continue;
      best = entry.dir
          ? entry.path
          : (entry.path.contains('/') ? entry.path.substring(0, entry.path.lastIndexOf('/')) : '');
    }
    return best ?? '';
  }

  FileEntry? _entryAt(String path) {
    for (final list in _kids.values) {
      for (final e in list ?? const <FileEntry>[]) {
        if (e.path == path) return e;
      }
    }
    return null;
  }

  Future<void> _dropped(DropDoneDetails d) async {
    final dir = _folderAt(d.globalPosition);
    setState(() => _dropDir = null);
    if (_readOnly) return;
    final files = <(String, Uint8List)>[];
    for (final f in d.files) {
      if (f is DropItemDirectory) continue;
      try {
        files.add((f.name, await f.readAsBytes()));
      } on Object {
        // A file the system does not let us read: left out.
      }
    }
    if (files.isNotEmpty && mounted) await _upload(dir, files);
  }

  // ---- drawing ----

  /// The rows shown: each folder's entries, the open ones' inside (depth first).
  List<(FileEntry?, int, String)> _rows() {
    final out = <(FileEntry?, int, String)>[];
    void walk(String dir, int depth) {
      final list = _kids[dir];
      if (list == null) {
        out.add((null, depth, dir));
        return;
      }
      for (final e in list) {
        if (!_hidden && e.name.startsWith('.')) continue;
        out.add((e, depth, dir));
        if (e.dir && _open.contains(e.path)) walk(e.path, depth + 1);
      }
    }

    walk('.', 0);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final p = widget.place;
    final title = p.project?.name ?? (p.assistants ? l.fxAssistants : l.fxPlatform);
    final side = widget.computer ? 32.0 : 40.0;
    Widget button(Key key, Widget icon, String tip, VoidCallback onTap, {bool on = false}) =>
        IconButton(
          key: key,
          tooltip: tip,
          isSelected: on,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: side, height: side),
          style: IconButton.styleFrom(
            backgroundColor: on ? c.accentSoft : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onTap,
          icon: icon,
        );
    final iconSize = widget.computer ? 17.0 : 20.0;
    // The title row: the place and the panel's own buttons; under it the page's tools.
    final titleRow = Row(
      children: [
        if (!widget.computer)
          IconButton(
            key: const Key('files-back'),
            tooltip: l.back,
            onPressed: widget.onClose,
            icon: RgIcon(RgIcons.arrowLeft, color: c.text),
          )
        else ...[
          const SizedBox(width: 4),
          const FolderIcon(size: 18),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                key: const Key('files-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: widget.computer ? 14.5 : 16.5,
                  color: c.text,
                ),
              ),
              if (!widget.computer)
                Text(l.fxSubtitle, style: TextStyle(fontSize: 12.5, color: c.dim)),
            ],
          ),
        ),
        if (widget.onFull != null)
          button(
            Key(widget.full ? 'files-unfull' : 'files-full'),
            RgIcon(widget.full ? RgIcons.minimize : RgIcons.maximize, size: 16, color: c.dim),
            widget.full ? l.fxFullOff : l.fxFull,
            widget.onFull!,
          ),
        if (widget.computer && widget.onClose != null)
          button(
            const Key('files-close'),
            RgIcon(RgIcons.x, size: iconSize, color: c.dim),
            l.fxClose,
            widget.onClose!,
          ),
      ],
    );
    final tools = Row(
      children: [
        if (!_readOnly) ...[
          button(
            const Key('files-new-file'),
            FileGlyphIcon(FileGlyph.filePlus, size: iconSize, color: c.dim),
            l.fxNewFile,
            _newFile,
          ),
          button(
            const Key('files-new-folder'),
            FileGlyphIcon(FileGlyph.folderPlus, size: iconSize, color: c.dim),
            l.fxNewFolder,
            _newFolder,
          ),
          button(
            const Key('files-upload'),
            RgIcon(RgIcons.upload, size: iconSize, color: c.dim),
            l.fxUpload,
            _pickAndUpload,
          ),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: c.line,
          ),
        ],
        button(
          const Key('files-hidden'),
          FileGlyphIcon(FileGlyph.eye, size: iconSize, color: _hidden ? c.accent : c.dim),
          _hidden ? l.fxHideHidden : l.fxShowHidden,
          () => unawaited(_setHidden(!_hidden)),
          on: _hidden,
        ),
        button(
          const Key('files-refresh'),
          RgIcon(RgIcons.refresh, size: iconSize - 1, color: c.dim),
          l.fxRefresh,
          () => unawaited(_reload()),
        ),
        if (!_readOnly)
          button(
            const Key('files-terminal'),
            RgIcon(RgIcons.terminal, size: iconSize, color: c.dim),
            l.fxTerminal,
            _terminal,
          ),
      ],
    );
    final head = Container(
      padding: EdgeInsets.fromLTRB(widget.computer ? 8 : 4, 6, 6, 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: widget.computer ? 34 : 48, child: titleRow),
          Padding(
            padding: EdgeInsets.only(left: widget.computer ? 0 : 8, top: 2),
            child: tools,
          ),
        ],
      ),
    );
    final where = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        key: const Key('files-search'),
        controller: _query,
        onChanged: _search,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          hintText: l.fxSearchHint,
          filled: true,
          fillColor: c.bg,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(9),
            child: RgIcon(RgIcons.search, size: 16, color: c.dim),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _query.text.isEmpty
              ? null
              : IconButton(
                  tooltip: l.fxClearSearch,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _query.clear();
                    _search('');
                  },
                  icon: RgIcon(RgIcons.x, size: 14, color: c.dim),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: c.line),
          ),
        ),
      ),
    );
    final folderLine = Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: Text.rich(
        key: const Key('files-where'),
        TextSpan(
          style: TextStyle(fontSize: 12, color: c.dim),
          children: [
            TextSpan(text: '${l.fxFolder}: '),
            TextSpan(
              text: '/$_base',
              style: TextStyle(
                fontFamily: monoFamily,
                fontFamilyFallback: monoFallback,
                color: c.text,
              ),
            ),
          ],
        ),
      ),
    );
    final taken = _taken;
    final tree = _hits != null ? _hitList(l, c) : _tree(l, c);
    return ColoredBox(
      color: c.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          if (_busy > 0)
            LinearProgressIndicator(minHeight: 2, color: c.accent, backgroundColor: c.panel)
          else
            const SizedBox(height: 2),
          where,
          if (_hits == null) folderLine,
          // An archived project (2026-11-09): its files are shown, never changed.
          if (_readOnly)
            Container(
              key: const Key('files-read-only'),
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Color.alphaBlend(c.warn.withValues(alpha: .12), c.panel),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  RgIcon(RgIcons.archive, size: 14, color: c.warnText),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l.fxReadOnly, style: TextStyle(color: c.warnText, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          if (taken != null) _TakenBar(name: taken.name, answer: taken.answer),
          Divider(height: 1, color: c.line),
          Expanded(
            child: widget.computer && !_readOnly
                ? DropTarget(
                    key: _dropKey,
                    onDragEntered: (d) => setState(() => _dropDir = _folderAt(d.globalPosition)),
                    onDragUpdated: (d) {
                      final dir = _folderAt(d.globalPosition);
                      if (dir != _dropDir) setState(() => _dropDir = dir);
                    },
                    onDragExited: (_) => setState(() => _dropDir = null),
                    onDragDone: (d) => unawaited(_dropped(d)),
                    child: tree,
                  )
                : KeyedSubtree(key: _dropKey, child: tree),
          ),
        ],
      ),
    );
  }

  Widget _hitList(AppLocalizations l, RgColors c) {
    final hits = _hits!;
    if (hits.isEmpty) return EmptyState(icon: RgIcons.search, text: l.codeNoHits);
    return ListView(
      key: const Key('files-hits'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        for (final h in hits)
          InkWell(
            key: Key('files-hit-${h.path}'),
            onTap: () => _openFile(h.path, h.path.split('/').last),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: FileIcon(name: h.path, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h.line == null ? h.path : '${h.path}:${h.line}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: c.text,
                          ),
                        ),
                        if (h.text != null)
                          Text(
                            h.text!.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: monoFamily,
                              fontFamilyFallback: monoFallback,
                              fontSize: 12,
                              color: c.dim,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tree(AppLocalizations l, RgColors c) {
    if (_kids['.'] == null) {
      return _failed.contains('.')
          ? EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed)
          : const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }
    final rows = _rows();
    final dropping = _dropDir != null;
    if (rows.isEmpty) {
      return Stack(
        children: [
          EmptyState(icon: RgIcons.folder, text: l.fxEmpty),
          if (dropping) _DropHint(text: l.fxDropHere),
        ],
      );
    }
    final list = RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        key: const Key('files-tree'),
        padding: const EdgeInsets.only(top: 4, bottom: 16),
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final (e, depth, dir) = rows[i];
          if (e == null) {
            return Padding(
              padding: EdgeInsets.fromLTRB(depth * 16.0 + 34, 6, 8, 6),
              child: _failed.contains(dir)
                  ? Text(l.codeLoadFailed, style: TextStyle(color: c.dim, fontSize: 12.5))
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: c.dim),
                      ),
                    ),
            );
          }
          final k = _rowKeys.putIfAbsent(e.path, GlobalKey.new);
          return _Row(
            key: k,
            entry: e,
            depth: depth,
            open: _open.contains(e.path),
            selected: _selected?.path == e.path,
            dropHere: dropping && e.dir && _dropDir == e.path,
            computer: widget.computer,
            readOnly: _readOnly,
            size: e.dir ? null : sizeWords(e.size, l.localeName),
            scope: _scope,
            onTap: () => _tap(e),
            onMenu: (at) => unawaited(_menu(e, at)),
            onSheet: () => unawaited(_sheet(e)),
            onRename: () => unawaited(_rename(e)),
            onDownload: () => unawaited(_download(e)),
            onDelete: () => unawaited(_delete(e)),
          );
        },
      ),
    );
    return Stack(
      children: [
        Positioned.fill(child: list),
        if (dropping && _dropDir == '')
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: c.accent, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        if (dropping) _DropHint(text: l.fxDropHere),
      ],
    );
  }
}

/// «Files to upload here», at the top while files from the system hover.
class _DropHint extends StatelessWidget {
  const _DropHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Positioned(
      left: 8,
      right: 8,
      top: 6,
      child: IgnorePointer(
        child: Container(
          key: const Key('files-drop-hint'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.accent),
          ),
          child: Row(
            children: [
              RgIcon(RgIcons.upload, size: 15, color: c.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A name already taken: keep both, replace, skip.
class _TakenBar extends StatelessWidget {
  const _TakenBar({required this.name, required this.answer});

  final String name;
  final Completer<String?> answer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    void pick(String? v) {
      if (!answer.isCompleted) answer.complete(v);
    }

    return Container(
      key: const Key('files-taken'),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.fxExists(name), style: TextStyle(color: c.text, fontSize: 13.5)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton(
                key: const Key('files-keep-both'),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () => pick('keep-both'),
                child: Text(l.fxKeepBoth),
              ),
              OutlinedButton(
                key: const Key('files-replace'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: c.err,
                  side: BorderSide(color: c.err.withValues(alpha: .6)),
                ),
                onPressed: () => pick('replace'),
                child: Text(l.fxReplace),
              ),
              TextButton(
                key: const Key('files-skip'),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                onPressed: () => pick(null),
                child: Text(l.cancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One row of the tree: chevron, drawn icon, name, size; on a computer the page's actions on
/// hover and the menu on a right click, on a phone «…» and a long press.
class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.entry,
    required this.depth,
    required this.open,
    required this.selected,
    required this.dropHere,
    required this.computer,
    required this.readOnly,
    required this.size,
    required this.scope,
    required this.onTap,
    required this.onMenu,
    required this.onSheet,
    required this.onRename,
    required this.onDownload,
    required this.onDelete,
  });

  final FileEntry entry;
  final int depth;
  final bool open;
  final bool selected;
  final bool dropHere;
  final bool computer;
  final bool readOnly;
  final String? size;
  final String scope;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMenu;
  final VoidCallback onSheet;
  final VoidCallback onRename;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final e = widget.entry;
    final computer = widget.computer;
    final height = computer ? 30.0 : 44.0;
    Widget small(Key key, Widget icon, String tip, VoidCallback onTap) => SizedBox(
      width: 26,
      height: 26,
      child: IconButton(
        key: key,
        tooltip: tip,
        padding: EdgeInsets.zero,
        iconSize: 14,
        onPressed: onTap,
        icon: icon,
      ),
    );
    final trailing = <Widget>[
      if (computer && _hover) ...[
        if (!widget.readOnly)
          small(
            Key('files-rename-${e.path}'),
            FileGlyphIcon(FileGlyph.pencil, size: 13, color: c.dim),
            l.fxRename,
            widget.onRename,
          ),
        if (!e.dir)
          small(
            Key('files-download-${e.path}'),
            RgIcon(RgIcons.download, size: 14, color: c.dim),
            l.fxDownload,
            widget.onDownload,
          ),
        if (!widget.readOnly)
          small(
            Key('files-delete-${e.path}'),
            RgIcon(RgIcons.trash, size: 14, color: c.dim),
            l.fxDelete,
            widget.onDelete,
          ),
      ] else if (widget.size != null)
        Text(
          widget.size!,
          style: TextStyle(color: c.dim, fontSize: computer ? 11.5 : 12.5),
        ),
      if (!computer)
        IconButton(
          key: Key('files-more-${e.path}'),
          tooltip: l.fxMore,
          visualDensity: VisualDensity.compact,
          onPressed: widget.onSheet,
          icon: RgIcon(RgIcons.more, size: 18, color: c.dim, filled: true),
        ),
    ];
    final bg = widget.dropHere
        ? c.accentSoft
        : widget.selected
        ? Color.alphaBlend(c.accent.withValues(alpha: .14), c.panel)
        : _hover
        ? c.panel2
        : Colors.transparent;
    Widget row = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: Key('files-row-${e.path}'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onSecondaryTapUp: computer ? (d) => widget.onMenu(d.globalPosition) : null,
        onLongPress: computer ? null : widget.onSheet,
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: EdgeInsets.only(left: widget.depth * 16.0 + 6, right: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(7),
            border: widget.dropHere ? Border.all(color: c.accent, width: 1.5) : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: e.dir
                    ? AnimatedRotation(
                        turns: widget.open ? .25 : 0,
                        duration: const Duration(milliseconds: 120),
                        child: RgIcon(RgIcons.chevronRight, size: 13, color: c.dim),
                      )
                    : null,
              ),
              const SizedBox(width: 4),
              if (e.dir)
                FolderIcon(open: widget.open, size: computer ? 16 : 19)
              else
                FileIcon(name: e.name, size: computer ? 15 : 18),
              SizedBox(width: computer ? 8 : 12),
              Expanded(
                child: Text(
                  e.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: computer ? 13.5 : 15,
                    fontWeight: e.dir ? FontWeight.w600 : FontWeight.w500,
                    color: e.name.startsWith('.') ? c.dim : c.text,
                  ),
                ),
              ),
              ...trailing,
            ],
          ),
        ),
      ),
    );
    if (computer && !e.dir) {
      row = Draggable<ExplorerFileDrag>(
        data: ExplorerFileDrag(scope: widget.scope, path: e.path, name: e.name, size: e.size),
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: _DragChip(name: e.name),
        child: row,
      );
    }
    return row;
  }
}

/// What follows the pointer while a file is dragged onto the conversation.
class _DragChip extends StatelessWidget {
  const _DragChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Material(
      color: Colors.transparent,
      child: Transform.translate(
        offset: const Offset(10, 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: c.accent),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FileIcon(name: name, size: 15),
              const SizedBox(width: 8),
              Text(
                name,
                style: TextStyle(color: c.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The phone's files screen: the explorer at full screen, its own «back».
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key, required this.place, required this.onOpen, this.onAsk});

  final ExplorerPlace place;
  final void Function(BuildContext context, String path, String name) onOpen;
  final void Function(String path)? onAsk;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Builder(
        builder: (context) => FilesExplorer(
          place: place,
          onOpen: (path, name) => onOpen(context, path, name),
          onAsk: onAsk == null
              ? null
              : (path) {
                  Navigator.of(context).maybePop();
                  onAsk!(path);
                },
          onClose: () => Navigator.of(context).maybePop(),
        ),
      ),
    ),
  );
}
