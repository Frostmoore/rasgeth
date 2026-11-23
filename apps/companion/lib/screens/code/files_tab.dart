// Files (G40.11): one folder per screen with the crumbs on top, the search, and a file's view
// with highlighting, a small edit (saved only if nobody changed the file since), «Ask…» an agent,
// its diff and its path. The page's Explorer routes (`/api/files/*`), same rules: an archived
// project's files are read only. On a tablet held sideways the tree and the file side by side.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../conversation_screen.dart';
import 'project_screen.dart';

String sizeWords(int bytes, String locale) {
  final f = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1);
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${f.format(bytes / 1024)} kB';
  return '${f.format(bytes / 1024 / 1024)} MB';
}

class FilesTab extends StatefulWidget {
  const FilesTab({super.key, required this.ctx});

  final ProjectCtx ctx;

  @override
  State<FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<FilesTab> with AutomaticKeepAliveClientMixin {
  /// The folders open, from the project's root ('.').
  final _path = <String>[];
  List<FileEntry>? _entries;
  Object? _error;
  final _query = TextEditingController();
  List<SearchHit>? _hits;
  Timer? _debounce;
  String? _open;

  @override
  bool get wantKeepAlive => true;

  String get _dir => _path.isEmpty ? '.' : _path.last;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _entries = null);
    try {
      final e = await widget.ctx.client.listFiles(widget.ctx.scope, _dir);
      if (mounted)
        setState(() {
          _entries = e;
          _error = null;
        });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _search(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _hits = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final h = await widget.ctx.client.searchFiles(widget.ctx.scope, q.trim());
        if (mounted && _query.text == q) setState(() => _hits = h);
      } on ApiException catch (e) {
        if (mounted) showApiError(context, e);
      }
    });
  }

  void _openFile(String path) {
    if (widget.ctx.wide) {
      setState(() => _open = path);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(path.split('/').last)),
          body: FileView(ctx: widget.ctx, path: path),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final changed = {
      for (final ch in widget.ctx.git?.changes ?? const <GitChange>[]) ch.path: ch.status,
    };
    final crumbs = [
      (widget.ctx.project.name, -1),
      for (final (i, p) in _path.indexed) (p.split('/').last, i),
    ];
    final tree = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            key: const Key('files-search'),
            controller: _query,
            onChanged: _search,
            decoration: InputDecoration(
              isDense: true,
              hintText: l.codeSearchHint,
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10),
                child: RgIcon(RgIcons.search, size: 18, color: c.dim),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 38),
            ),
          ),
        ),
        if (_hits == null)
          SingleChildScrollView(
            key: const Key('files-crumbs'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                for (final (i, (name, at)) in crumbs.indexed) ...[
                  if (i > 0) RgIcon(RgIcons.chevronRight, size: 14, color: c.dim),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 32),
                    ),
                    onPressed: i == crumbs.length - 1
                        ? null
                        : () {
                            _path.removeRange(at + 1, _path.length);
                            _load();
                          },
                    child: Text(
                      name,
                      style: TextStyle(
                        fontWeight: i == crumbs.length - 1 ? FontWeight.w800 : FontWeight.w600,
                        color: i == crumbs.length - 1 ? c.text : c.accent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        Expanded(child: _hits != null ? _hitList(l, c) : _list(l, c, changed)),
      ],
    );
    if (!widget.ctx.wide) return tree;
    return Row(
      children: [
        SizedBox(width: 360, child: tree),
        VerticalDivider(width: 1, color: c.line),
        Expanded(
          child: _open == null
              ? EmptyState(icon: RgIcons.file, text: l.codePickFile)
              : FileView(key: ValueKey(_open), ctx: widget.ctx, path: _open!),
        ),
      ],
    );
  }

  Widget _hitList(AppLocalizations l, RgColors c) {
    final hits = _hits!;
    if (hits.isEmpty) return EmptyState(icon: RgIcons.search, text: l.codeNoHits);
    return ListView(
      key: const Key('files-hits'),
      children: [
        for (final h in hits)
          ListTile(
            dense: true,
            leading: RgIcon(RgIcons.file, size: 18, color: c.dim),
            title: Text(
              h.line == null ? h.path : '${h.path}:${h.line}',
              style: const TextStyle(fontFamily: monoFamily, fontFamilyFallback: monoFallback),
            ),
            subtitle: h.text == null
                ? null
                : Text(
                    h.text!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: monoFamily,
                      fontFamilyFallback: monoFallback,
                    ),
                  ),
            onTap: () => _openFile(h.path),
          ),
      ],
    );
  }

  Widget _list(AppLocalizations l, RgColors c, Map<String, String> changed) {
    final entries = _entries;
    if (entries == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    }
    if (entries.isEmpty) return EmptyState(icon: RgIcons.folder, text: l.codeEmptyFolder);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        key: const Key('files-list'),
        children: [
          for (final e in entries)
            ListTile(
              key: Key('file-${e.path}'),
              leading: RgIcon(
                e.dir ? RgIcons.folder : RgIcons.file,
                size: 20,
                color: e.dir ? c.accent : c.dim,
              ),
              title: Row(
                children: [
                  Flexible(
                    child: Text(
                      e.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!e.dir && changed[e.path] != null) ...[
                    const SizedBox(width: 6),
                    _Mark(changed[e.path]!),
                  ],
                ],
              ),
              trailing: e.dir
                  ? RgIcon(RgIcons.chevronRight, size: 18, color: c.dim)
                  : Text(
                      sizeWords(e.size, l.localeName),
                      style: TextStyle(color: c.dim, fontSize: 12.5),
                    ),
              onTap: () {
                if (e.dir) {
                  _path.add(e.path);
                  _load();
                } else {
                  _openFile(e.path);
                }
              },
            ),
        ],
      ),
    );
  }
}

/// A file's git mark (M, A, ?…).
class _Mark extends StatelessWidget {
  const _Mark(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final color = status == '?' || status == 'A'
        ? c.ok
        : status == 'D'
        ? c.err
        : c.warnText;
    return Text(
      status == '?' ? 'U' : status,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5),
    );
  }
}

/// One file: highlighted, with its actions; a small edit in place.
class FileView extends StatefulWidget {
  const FileView({super.key, required this.ctx, required this.path});

  final ProjectCtx ctx;
  final String path;

  @override
  State<FileView> createState() => _FileViewState();
}

class _FileViewState extends State<FileView> {
  FileText? _file;
  Object? _error;
  TextEditingController? _edit;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _edit?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final f = await widget.ctx.client.fileText(widget.ctx.scope, widget.path);
      if (mounted)
        setState(() {
          _file = f;
          _error = null;
        });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _save() async {
    final f = _file;
    final e = _edit;
    if (f == null || e == null) return;
    setState(() => _saving = true);
    final l = AppLocalizations.of(context);
    try {
      final at = await widget.ctx.client.saveText(
        widget.ctx.scope,
        widget.path,
        e.text,
        expected: f.modifiedAt,
      );
      if (!mounted) return;
      setState(() {
        _file = FileText(path: f.path, size: e.text.length, modifiedAt: at, text: e.text);
        _edit = null;
      });
      e.dispose();
      unawaited(widget.ctx.reloadGit());
      say(context, l.codeSaved);
    } on ApiException catch (err) {
      if (mounted) showApiError(context, err);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _ask() async {
    final l = AppLocalizations.of(context);
    final agents = widget.ctx.agents.isEmpty ? [?widget.ctx.app.god] : widget.ctx.agents;
    final a = await pickFrom(
      context,
      title: l.codeAskWho,
      options: [for (final a in agents) (a, a.name, a.role)],
    );
    if (a == null || !mounted) return;
    final nav = Navigator.of(context);
    final sid = await widget.ctx.app.openAgent(a);
    if (sid == null) return;
    await nav.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ConversationScreen(sessionId: sid, agent: a, draft: l.codeAskDraft(widget.path)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final f = _file;
    if (f == null) {
      return _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    }
    final when = DateTime.tryParse(f.modifiedAt)?.toLocal();
    final edit = _edit;
    final why = f.text != null && edit == null && widget.ctx.readOnly ? l.codeArchived : null;
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (edit == null && f.text != null && !widget.ctx.readOnly && f.size < 512 * 1024)
          PickChip(
            key: const Key('file-edit'),
            icon: RgIcons.edit,
            label: l.codeSmallEdit,
            onTap: () => setState(() => _edit = TextEditingController(text: f.text)),
          ),
        if (edit != null) ...[
          PickChip(
            key: const Key('file-save'),
            icon: RgIcons.check,
            selected: true,
            label: _saving ? l.codeSaving : l.codeSave,
            onTap: _saving ? () {} : _save,
          ),
          PickChip(
            key: const Key('file-cancel'),
            label: l.cancel,
            onTap: () => setState(() {
              _edit = null;
              edit.dispose();
            }),
          ),
        ],
        if (edit == null) ...[
          PickChip(key: const Key('file-ask'), icon: RgIcons.chat, label: l.codeAsk, onTap: _ask),
          PickChip(
            key: const Key('file-diff'),
            icon: RgIcons.diff,
            label: l.codeSeeDiff,
            onTap: () {
              if (!widget.ctx.wide) Navigator.of(context).maybePop();
              widget.ctx.openDiff(const DiffSource.working(), file: widget.path);
            },
          ),
          PickChip(
            key: const Key('file-copy-path'),
            icon: RgIcons.copy,
            label: l.codeCopyPath,
            onTap: () {
              unawaited(Clipboard.setData(ClipboardData(text: widget.path)));
              say(context, l.codePathCopied);
            },
          ),
        ],
      ],
    );
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 13,
      height: 1.45,
      color: c.text,
    );
    Widget body;
    if (f.text == null) {
      body = EmptyState(icon: RgIcons.file, text: l.codeNotText);
    } else if (edit != null) {
      body = Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          key: const Key('file-editor'),
          controller: edit,
          maxLines: null,
          expands: true,
          style: mono,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      );
    } else {
      final ext = extOf(widget.path);
      final lines = f.text!.split('\n');
      final width = '${lines.length}'.length;
      body = SingleChildScrollView(
        key: const Key('file-view'),
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText.rich(
            TextSpan(
              style: mono,
              children: [
                for (final (i, line) in lines.indexed) ...[
                  TextSpan(
                    text: '${'${i + 1}'.padLeft(width)}  ',
                    style: TextStyle(color: c.dim),
                  ),
                  ...highlightLine(line, ext, c),
                  if (i < lines.length - 1) const TextSpan(text: '\n'),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Text(
            widget.path,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: c.text,
              fontFamily: monoFamily,
              fontFamilyFallback: monoFallback,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
          child: Text(
            '${sizeWords(f.size, l.localeName)}${when == null ? '' : ' · ${l.codeModifiedAt(DateFormat.MMMd(l.localeName).add_Hm().format(when))}'}',
            style: TextStyle(color: c.dim, fontSize: 12.5),
          ),
        ),
        if (why != null)
          Padding(
            key: const Key('file-readonly'),
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Text(why, style: TextStyle(color: c.dim, fontSize: 12.5)),
          ),
        Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 8), child: actions),
        Divider(height: 1, color: c.line),
        Expanded(
          child: ColoredBox(color: c.panel, child: body),
        ),
      ],
    );
  }
}
