// Diff (G40.11): a task's, an agent's, a commit's or the uncommitted changes, always unified
// (never side by side on a phone), one file per screen swiped left and right; for every hunk
// «keep» (staged), «discard» (kept in the trash first, after the person's yes) or «comment to the
// agent». On a tablet held sideways the agent's chat next to it.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/client.dart';
import '../../api/code.dart';
import '../../api/types.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../../ui/common.dart';
import '../../ui/dialogs.dart';
import '../../ui/highlight.dart';
import '../../ui/icons.dart';
import '../conversation_screen.dart';
import 'project_screen.dart';

class DiffTab extends StatefulWidget {
  const DiffTab({
    super.key,
    required this.ctx,
    required this.source,
    this.startFile,
    this.sideBySide = false,
    this.onReader,
  });

  final ProjectCtx ctx;

  /// Computers (G40.17): before and after in two columns.
  final bool sideBySide;

  /// Tells who reads the comments (the computers' code view shows that agent's conversation).
  final ValueChanged<Agent?>? onReader;
  final DiffSource source;
  final String? startFile;

  @override
  State<DiffTab> createState() => _DiffTabState();
}

class _DiffTabState extends State<DiffTab> with AutomaticKeepAliveClientMixin {
  DiffView? _diff;
  Object? _error;
  late DiffSource _source = widget.source;
  PageController? _pages;
  int _page = 0;

  /// Hunks kept or discarded here, by file and header.
  final _done = <String, String>{};
  String? _commenting;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pages?.dispose();
    _comment.dispose();
    super.dispose();
  }

  Future<void> _load({bool keepPage = false}) async {
    try {
      final d = await widget.ctx.client.gitDiff(widget.ctx.project.id, _source);
      if (!mounted) return;
      var start = keepPage ? _page : 0;
      final want = widget.startFile;
      if (!keepPage && want != null) {
        final i = d.files.indexWhere((f) => f.path == want);
        if (i >= 0) start = i;
      }
      if (start >= d.files.length) start = d.files.isEmpty ? 0 : d.files.length - 1;
      _pages?.dispose();
      setState(() {
        _diff = d;
        _error = null;
        _page = start;
        _pages = PageController(initialPage: start);
      });
      widget.onReader?.call(_reader);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  String _label(AppLocalizations l) {
    final s = _source;
    if (s.working) return l.codeDiffWorking;
    if (s.task != null) return l.codeDiffTask(s.label ?? _diff?.title ?? s.task!);
    if (s.commit != null) return l.codeDiffCommit(s.commit!, s.label ?? _diff?.title ?? '');
    return l.codeDiffAgent(widget.ctx.agentById(s.agent)?.name ?? s.agent!);
  }

  Future<void> _choose() async {
    final l = AppLocalizations.of(context);
    final ctx = widget.ctx;
    List<(DiffSource, String, String?)> options = [
      (const DiffSource.working(), l.codeDiffWorking, null),
    ];
    try {
      final tasks = await ctx.client.tasks(ctx.project.id);
      final commits = await ctx.client.gitLog(ctx.project.id, limit: 20);
      options = [
        ...options,
        for (final a in ctx.agents) (DiffSource.agent(a.id), l.codeDiffAgent(a.name), a.role),
        for (final t in tasks.take(20))
          (DiffSource.task(t.id, label: t.title), l.codeDiffTask(t.title), t.agentName),
        for (final c in commits)
          (
            DiffSource.commit(c.short, label: c.subject),
            l.codeDiffCommit(c.short, c.subject),
            c.author,
          ),
      ];
    } on ApiException {
      // The uncommitted changes at least.
    }
    if (!mounted) return;
    final s = await pickFrom(context, title: l.codeDiffWhich, options: options);
    if (s == null || s == _source) return;
    setState(() {
      _source = s;
      _diff = null;
      _done.clear();
    });
    await _load();
  }

  /// The agent a comment goes to: the diff's, or the project's lead.
  Agent? get _reader => widget.ctx.agentById(_diff?.agentId ?? _source.agent) ?? widget.ctx.lead;

  Future<void> _act(DiffFile f, DiffHunk h, {required bool keep}) async {
    final l = AppLocalizations.of(context);
    final key = '${f.path}\n${h.header}';
    final commit = _source.commit != null;
    // A commit's hunk is kept as it is: nothing to do on the server.
    if (keep && commit) {
      setState(() => _done[key] = 'keep');
      return;
    }
    if (!keep) {
      final yes = await askConfirm(
        context,
        title: l.codeDiscardTitle,
        body: commit ? l.codeDiscardCommitBody(f.path) : l.codeDiscardBody(f.path),
        yes: l.codeDiscard,
        danger: true,
      );
      if (!yes || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await widget.ctx.client.gitHunk(
        widget.ctx.project.id,
        patch: hunkPatch(f, h),
        keep: keep,
        agent: _source.agent ?? (_source.task != null ? _diff?.agentId : null),
      );
      if (!mounted) return;
      setState(() => _done[key] = keep ? 'keep' : 'discard');
      say(context, keep ? l.codeKept : l.codeDiscarded);
      unawaited(widget.ctx.reloadGit());
      if (!keep && !commit) await _load(keepPage: true);
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send(DiffFile f, DiffHunk h) async {
    final l = AppLocalizations.of(context);
    final text = _comment.text.trim();
    final a = _reader;
    if (text.isEmpty || a == null) return;
    setState(() => _busy = true);
    final sid = await widget.ctx.app.openAgent(a);
    final ok =
        sid != null &&
        await widget.ctx.app.send(
          sid,
          '${l.codeCommentIntro(f.path, h.header)}\n\n```diff\n${h.raw.toString().trimRight()}\n```\n\n$text',
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) {
        _commenting = null;
        _comment.clear();
      }
    });
    say(context, ok ? l.codeCommentSent(a.name) : l.codeCommentFailed);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final d = _diff;
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.line),
        ),
        child: InkWell(
          key: const Key('diff-source'),
          borderRadius: BorderRadius.circular(12),
          onTap: _choose,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                RgIcon(RgIcons.diff, size: 17, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _label(l),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                  ),
                ),
                RgIcon(RgIcons.chevronDown, size: 17, color: c.dim),
              ],
            ),
          ),
        ),
      ),
    );
    Widget body;
    if (d == null) {
      body = _error == null
          ? const Center(child: CircularProgressIndicator())
          : EmptyState(icon: RgIcons.alert, text: l.codeLoadFailed);
    } else if (d.files.isEmpty) {
      body = EmptyState(icon: RgIcons.check, text: l.codeDiffEmpty);
    } else {
      final f = d.files[_page.clamp(0, d.files.length - 1)];
      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    f.path,
                    key: const Key('diff-file'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: monoFamily,
                      fontFamilyFallback: monoFallback,
                      fontWeight: FontWeight.w700,
                      color: c.text,
                    ),
                  ),
                ),
                Text(
                  '+${f.added} ',
                  style: TextStyle(color: c.ok, fontWeight: FontWeight.w700),
                ),
                Text(
                  '-${f.removed}',
                  style: TextStyle(color: c.err, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text(
                  l.codeFileOf(_page + 1, d.files.length),
                  key: const Key('diff-count'),
                  style: TextStyle(color: c.dim, fontSize: 12.5),
                ),
                IconButton(
                  tooltip: l.codePrevFile,
                  onPressed: _page == 0
                      ? null
                      : () => _pages?.previousPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                  icon: RgIcon(RgIcons.arrowLeft, size: 18, color: _page == 0 ? c.line : c.text),
                ),
                IconButton(
                  key: const Key('diff-next'),
                  tooltip: l.codeNextFile,
                  onPressed: _page >= d.files.length - 1
                      ? null
                      : () => _pages?.nextPage(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                        ),
                  icon: RgIcon(
                    RgIcons.arrowRight,
                    size: 18,
                    color: _page >= d.files.length - 1 ? c.line : c.text,
                  ),
                ),
              ],
            ),
          ),
          if (d.truncated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(l.codeDiffTruncated, style: TextStyle(color: c.warnText, fontSize: 12.5)),
            ),
          Expanded(
            child: PageView.builder(
              key: const Key('diff-pages'),
              controller: _pages,
              itemCount: d.files.length,
              onPageChanged: (i) => setState(() {
                _page = i;
                _commenting = null;
              }),
              itemBuilder: (context, i) => _fileView(l, c, d.files[i]),
            ),
          ),
        ],
      );
    }
    final column = Column(
      children: [
        header,
        Expanded(child: body),
      ],
    );
    if (!widget.ctx.wide) return column;
    final sid = widget.ctx.latestSessionOf(_reader?.id);
    return Row(
      children: [
        Expanded(flex: 3, child: column),
        VerticalDivider(width: 1, color: c.line),
        Expanded(
          flex: 2,
          child: sid == null
              ? EmptyState(icon: RgIcons.chat, text: l.codeNoChat)
              : ConversationScreen(
                  key: ValueKey(sid),
                  sessionId: sid,
                  agent: _reader,
                  embedded: true,
                ),
        ),
      ],
    );
  }

  Widget _fileView(AppLocalizations l, RgColors c, DiffFile f) {
    final ext = extOf(f.path);
    final mono = TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: monoFallback,
      fontSize: 12.5,
      height: 1.4,
      color: c.text,
    );
    if (f.binary || f.hunks.isEmpty) {
      return EmptyState(icon: RgIcons.file, text: f.binary ? l.codeDiffBinary : l.codeDiffNoHunks);
    }
    final readOnly = widget.ctx.readOnly;
    if (widget.sideBySide) return _sideBySide(l, c, f, mono, ext, readOnly);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        for (final h in f.hunks) ...[
          Container(
            color: c.panel2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(h.header, style: mono.copyWith(color: c.dim)),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in h.lines)
                  Container(
                    color: switch (line.kind) {
                      DiffLineKind.added => c.ok.withValues(alpha: .14),
                      DiffLineKind.removed => c.err.withValues(alpha: .14),
                      _ => null,
                    },
                    padding: const EdgeInsets.only(right: 16),
                    child: Text.rich(
                      TextSpan(
                        style: mono,
                        children: [
                          TextSpan(
                            text: ' ${'${line.newNo ?? line.oldNo ?? ''}'.padLeft(4)} ',
                            style: TextStyle(color: c.dim),
                          ),
                          TextSpan(
                            text: switch (line.kind) {
                              DiffLineKind.added => '+ ',
                              DiffLineKind.removed => '- ',
                              _ => '  ',
                            },
                            style: TextStyle(
                              color: line.kind == DiffLineKind.added
                                  ? c.ok
                                  : line.kind == DiffLineKind.removed
                                  ? c.err
                                  : c.dim,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (line.kind == DiffLineKind.note)
                            TextSpan(
                              text: line.text,
                              style: TextStyle(color: c.dim),
                            )
                          else
                            ...highlightLine(line.text, ext, c),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _hunkActions(l, c, f, h, readOnly),
        ],
      ],
    );
  }

  /// Before (left) and after (right), line by line.
  Widget _sideBySide(
    AppLocalizations l,
    RgColors c,
    DiffFile f,
    TextStyle mono,
    String? ext,
    bool readOnly,
  ) {
    Widget cell(DiffLine? line, {required bool left}) {
      final kind = line?.kind;
      final no = line == null ? null : (left ? line.oldNo : line.newNo);
      final bg = switch (kind) {
        DiffLineKind.added when !left => c.ok.withValues(alpha: .14),
        DiffLineKind.removed when left => c.err.withValues(alpha: .14),
        null => c.panel2.withValues(alpha: .5),
        _ => null,
      };
      return Container(
        color: bg,
        padding: const EdgeInsets.only(right: 12),
        child: Text.rich(
          TextSpan(
            style: mono,
            children: [
              TextSpan(text: ' ${'${no ?? ''}'.padLeft(4)}  ', style: TextStyle(color: c.dim)),
              if (line == null)
                const TextSpan(text: '')
              else if (kind == DiffLineKind.note)
                TextSpan(text: line.text, style: TextStyle(color: c.dim))
              else
                ...highlightLine(line.text, ext, c),
            ],
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
        ),
      );
    }

    return ListView(
      key: const Key('diff-side-by-side'),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
      children: [
        for (final h in f.hunks) ...[
          Container(
            color: c.panel2,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(h.header, style: mono.copyWith(color: c.dim)),
          ),
          for (final (a, b) in sideBySideRows(h))
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cell(a, left: true)),
                  VerticalDivider(width: 1, color: c.line),
                  Expanded(child: cell(b == a ? a : b, left: false)),
                ],
              ),
            ),
          _hunkActions(l, c, f, h, readOnly),
        ],
      ],
    );
  }

  Widget _hunkActions(AppLocalizations l, RgColors c, DiffFile f, DiffHunk h, bool readOnly) {
    final key = '${f.path}\n${h.header}';
    final done = _done[key];
    final commenting = _commenting == key;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (done != null)
                PickChip(
                  icon: done == 'keep' ? RgIcons.check : RgIcons.x,
                  selected: true,
                  danger: done != 'keep',
                  label: done == 'keep' ? l.codeKept : l.codeDiscarded,
                  onTap: () {},
                )
              else if (!readOnly) ...[
                PickChip(
                  key: Key('hunk-keep-${h.header}'),
                  icon: RgIcons.check,
                  label: l.codeKeep,
                  onTap: _busy ? () {} : () => _act(f, h, keep: true),
                ),
                PickChip(
                  key: Key('hunk-discard-${h.header}'),
                  icon: RgIcons.x,
                  label: l.codeDiscard,
                  onTap: _busy ? () {} : () => _act(f, h, keep: false),
                ),
              ],
              if (!readOnly && _reader != null)
                PickChip(
                  key: Key('hunk-comment-${h.header}'),
                  icon: RgIcons.chat,
                  selected: commenting,
                  label: l.codeComment,
                  onTap: () => setState(() => _commenting = commenting ? null : key),
                ),
            ],
          ),
          if (commenting)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('hunk-comment-text'),
                      controller: _comment,
                      autofocus: true,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l.codeCommentHint(_reader?.name ?? ''),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('hunk-comment-send'),
                    onPressed: _busy ? null : () => _send(f, h),
                    child: Text(l.composerSend),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
