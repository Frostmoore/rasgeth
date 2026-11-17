// A project's board (G42.3), as the page's Board.tsx: the threads the agents and the person write
// in (task, result, question, decision, blocker, note), their state (open, resolved, blocked),
// a search, a new thread and the replies. Wide: the list on the left (340 px) and the thread on
// the right; on a phone the list, and the thread over it. It reads again on `board.changed`.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/client.dart';
import '../api/groups.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';
import '../ui/markdown.dart';
import '../ui/rg_menu.dart';

/// `toLocaleString()`: the date and time in the person's language.
String localWhen(String iso, String locale) {
  final d = DateTime.tryParse(iso)?.toLocal();
  return d == null ? iso : DateFormat.yMd(locale).add_Hms().format(d);
}

String boardKindLabel(AppLocalizations l, String kind) {
  final labels = l.cvPostKindLabels.split(',');
  final i = boardKinds.indexOf(kind);
  return i >= 0 && i < labels.length ? labels[i] : kind;
}

String boardStatusLabel(AppLocalizations l, String status) => switch (status) {
  'resolved' => l.cvStatusResolved,
  'blocked' => l.cvStatusBlocked,
  _ => l.cvStatusOpen,
};

/// The colour of a kind or a state (the page's `.kind-badge`, `.status-chip`).
Color boardColor(RgColors c, String k) => switch (k) {
  'decision' => c.warnText,
  'blocker' || 'blocked' => c.err,
  'result' || 'resolved' => c.ok,
  'question' => const Color(0xFF7CC6FF),
  _ => c.dim,
};

Future<void> openBoard(BuildContext context, {String? projectId, required String title}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BoardScreen(projectId: projectId, title: title),
      ),
    );

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, this.projectId, required this.title});

  final String? projectId;
  final String title;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final AppController app = AppScope.read(context);
  List<BoardThread> _threads = const [];
  String? _open;
  ({BoardThread thread, List<BoardPost> posts})? _detail;
  List<BoardPost>? _results;
  final _query = TextEditingController();
  bool _loaded = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    app.live.boardChanged.addListener(_reload);
    unawaited(_reload());
  }

  @override
  void dispose() {
    app.live.boardChanged.removeListener(_reload);
    _query.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final c = app.client;
    if (c == null) return;
    try {
      final list = await c.boardThreads(projectId: widget.projectId);
      final open = _open;
      final detail = open == null ? null : await c.boardThread(open);
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _threads = list;
        if (open == _open) _detail = detail;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loaded = true;
          _note = e.message;
        });
      }
    }
  }

  Future<void> _openThread(String id) async {
    setState(() {
      _open = id;
      _results = null;
    });
    try {
      final d = await app.client?.boardThread(id);
      if (mounted && _open == id) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return setState(() => _results = null);
    try {
      final r = await app.client?.boardSearch(q);
      if (mounted && r != null) {
        setState(
          () => _results = [
            for (final p in r)
              if (_threads.any((t) => t.id == p.threadId) || widget.projectId == null) p,
          ],
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  Future<bool> _post({String? title, required String kind, required String body}) async {
    final c = app.client;
    if (c == null) return false;
    try {
      final id = await c.boardPost(
        threadId: title == null ? _open : null,
        projectId: widget.projectId,
        title: title,
        kind: kind,
        body: body,
      );
      await _reload();
      if (title != null && id.isNotEmpty && mounted) {
        if (MediaQuery.sizeOf(context).width >= 820) {
          await _openThread(id);
        } else {
          unawaited(
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => BoardThreadScreen(threadId: id))),
          );
        }
      }
      return true;
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
      return false;
    }
  }

  Future<void> _status(String status) async {
    final open = _open;
    if (open == null) return;
    try {
      await app.client?.setBoardStatus(open, status);
      await _reload();
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 820;
    final list = _List(
      threads: _threads,
      results: _results,
      open: _open,
      loaded: _loaded,
      query: _query,
      onSearch: _search,
      onOpen: (id) {
        if (wide) {
          unawaited(_openThread(id));
        } else {
          setState(() => _results = null);
          unawaited(
            Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => BoardThreadScreen(threadId: id))),
          );
        }
      },
      onNew: (title, kind, body) => _post(title: title, kind: kind, body: body),
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('board-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            RgIcon(RgIcons.board, size: 18, color: c.dim),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(_note!, style: TextStyle(color: c.err, fontSize: 13)),
            ),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 340,
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: c.line)),
                        ),
                        child: list,
                      ),
                      Expanded(child: _threadView()),
                    ],
                  )
                : list,
          ),
        ],
      ),
    );
  }

  Widget _threadView() {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final d = _detail;
    if (d == null || d.thread.id != _open) {
      return Center(
        child: Text(
          _open == null ? l.cvBoard : l.loading,
          style: TextStyle(
            color: c.dim.withValues(alpha: .7),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return _ThreadView(
      detail: d,
      onStatus: _status,
      onReply: (kind, body) => _post(kind: kind, body: body),
    );
  }
}

/// On a phone: the thread over the list, read again on `board.changed`.
class BoardThreadScreen extends StatefulWidget {
  const BoardThreadScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<BoardThreadScreen> createState() => _BoardThreadScreenState();
}

class _BoardThreadScreenState extends State<BoardThreadScreen> {
  late final AppController app = AppScope.read(context);
  ({BoardThread thread, List<BoardPost> posts})? _detail;
  String? _note;

  @override
  void initState() {
    super.initState();
    app.live.boardChanged.addListener(_load);
    unawaited(_load());
  }

  @override
  void dispose() {
    app.live.boardChanged.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await app.client?.boardThread(widget.threadId);
      if (mounted) setState(() => _detail = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _note = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('board-thread-back'),
          tooltip: l.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: RgIcon(RgIcons.arrowLeft, color: c.text),
        ),
        // The thread's title is right under it, with its state: the bar says where it is.
        title: Text(l.cvBoard, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          if (_note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(_note!, style: TextStyle(color: c.err, fontSize: 13)),
            ),
          Expanded(
            child: d == null
                ? Center(
                    child: Text(l.loading, style: TextStyle(color: c.dim)),
                  )
                : _ThreadView(
                    detail: d,
                    onStatus: (st) async {
                      try {
                        await app.client?.setBoardStatus(widget.threadId, st);
                        await _load();
                      } on ApiException catch (e) {
                        if (mounted) setState(() => _note = e.message);
                      }
                    },
                    onReply: (kind, body) async {
                      try {
                        await app.client?.boardPost(
                          threadId: widget.threadId,
                          kind: kind,
                          body: body,
                        );
                        await _load();
                        return true;
                      } on ApiException catch (e) {
                        if (mounted) setState(() => _note = e.message);
                        return false;
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.threads,
    required this.results,
    required this.open,
    required this.loaded,
    required this.query,
    required this.onSearch,
    required this.onOpen,
    required this.onNew,
  });

  final List<BoardThread> threads;
  final List<BoardPost>? results;
  final String? open;
  final bool loaded;
  final TextEditingController query;
  final VoidCallback onSearch;
  final ValueChanged<String> onOpen;
  final Future<bool> Function(String title, String kind, String body) onNew;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    String author(String id) =>
        id == 'human' ? l.cvYou : (app.agents.where((a) => a.id == id).firstOrNull?.name ?? id);
    final r = results;
    // The list, and the new thread's composer at the bottom (the page's `board-list`).
    return Column(
      children: [
        Expanded(
          child: ListView(
            key: const Key('board-list'),
            padding: const EdgeInsets.all(12),
            children: [
              TextField(
                key: const Key('board-search'),
                controller: query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: l.cvSearch,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: RgIcon(RgIcons.search, size: 16, color: c.dim),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (r != null)
                if (r.isEmpty)
                  _Empty(l.cvNoResults)
                else
                  for (final p in r)
                    _Item(
                      key: Key('board-result-${p.id}'),
                      selected: false,
                      onTap: () => onOpen(p.threadId),
                      children: [
                        Text(
                          p.title ?? '',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          p.body.length > 120 ? p.body.substring(0, 120) : p.body,
                          style: TextStyle(color: c.dim, fontSize: 12.5),
                        ),
                      ],
                    )
              else if (!loaded)
                _Empty(l.loading)
              else if (threads.isEmpty)
                _Empty(l.cvEmptyBoard)
              else
                for (final th in threads)
                  _Item(
                    key: Key('board-thread-${th.id}'),
                    selected: open == th.id,
                    onTap: () => onOpen(th.id),
                    children: [
                      BoardChip(
                        text: boardStatusLabel(l, th.status),
                        color: boardColor(c, th.status),
                      ),
                      Text(
                        th.title,
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${th.posts} · ${author(th.createdBy)} · ${localWhen(th.updatedAt, locale)}',
                        style: TextStyle(color: c.dim, fontSize: 12.5),
                      ),
                    ],
                  ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: BoardComposer(withTitle: true, onSend: (t, k, b) => onNew(t, k, b)),
        ),
      ],
    );
  }
}

TextStyle _strong(RgColors c) =>
    TextStyle(color: c.text, fontWeight: FontWeight.w700, fontSize: 14);

class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
      child: Text(text, style: TextStyle(color: RgColors.of(context).dim)),
    ),
  );
}

class _Item extends StatelessWidget {
  const _Item({super.key, required this.selected, required this.onTap, required this.children});

  final bool selected;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: c.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: selected ? c.accent : c.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 3,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// A small pill (the page's `.kind-badge`, `.status-chip`).
class BoardChip extends StatelessWidget {
  const BoardChip({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: RgColors.of(context).line),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 11)),
  );
}

class _ThreadView extends StatelessWidget {
  const _ThreadView({required this.detail, required this.onStatus, required this.onReply});

  final ({BoardThread thread, List<BoardPost> posts}) detail;
  final ValueChanged<String> onStatus;
  final Future<bool> Function(String kind, String body) onReply;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final th = detail.thread;
    String nameOf(String id) => app.agents.where((a) => a.id == id).firstOrNull?.name ?? '';
    String author(String id) => id == 'human' ? l.cvYou : (nameOf(id).isEmpty ? id : nameOf(id));
    Color border(String kind) => switch (kind) {
      'decision' => Color.lerp(c.line, c.warn, .55)!,
      'blocker' => Color.lerp(c.line, c.err, .55)!,
      'result' => Color.lerp(c.line, c.ok, .55)!,
      _ => c.line,
    };
    return Column(
      key: Key('board-thread-view-${th.id}'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            children: [
              // The title and its state, the buttons on the right (they go under it when narrow).
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        th.title,
                        style: TextStyle(color: c.text, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      BoardChip(
                        text: boardStatusLabel(l, th.status),
                        color: boardColor(c, th.status),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (th.status != 'resolved')
                        OutlinedButton(
                          key: const Key('board-resolve'),
                          onPressed: () => onStatus('resolved'),
                          child: Text(l.cvResolve),
                        ),
                      if (th.status == 'open')
                        OutlinedButton(
                          key: const Key('board-block'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.err,
                            side: BorderSide(color: c.err.withValues(alpha: .6)),
                          ),
                          onPressed: () => onStatus('blocked'),
                          child: Text(l.cvBlock),
                        ),
                      if (th.status != 'open')
                        OutlinedButton(
                          key: const Key('board-reopen'),
                          onPressed: () => onStatus('open'),
                          child: Text(l.cvReopen),
                        ),
                    ],
                  ),
                ],
              ),
              if (th.summary != null && th.summary!.isNotEmpty)
                Container(
                  key: const Key('board-summary'),
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.panel,
                    border: Border(left: BorderSide(color: c.accent2, width: 2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.cvSummary,
                        style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(th.summary!, style: TextStyle(color: c.dim)),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              for (final p in detail.posts)
                Container(
                  key: Key('board-post-${p.id}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  decoration: BoxDecoration(
                    color: c.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: border(p.kind)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          BoardChip(text: boardKindLabel(l, p.kind), color: boardColor(c, p.kind)),
                          Text(
                            author(p.author),
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            localWhen(p.createdAt, locale),
                            style: TextStyle(color: c.dim, fontSize: 12.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SafeMarkdown(boardMentions(p.body, nameOf)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: BoardComposer(withTitle: false, onSend: (_, k, b) => onReply(k, b)),
        ),
      ],
    );
  }
}

/// The page's `board-composer`: the title (for a new thread), the text, the kind and the button.
class BoardComposer extends StatefulWidget {
  const BoardComposer({super.key, required this.withTitle, required this.onSend});

  final bool withTitle;
  final Future<bool> Function(String title, String kind, String body) onSend;

  @override
  State<BoardComposer> createState() => _BoardComposerState();
}

class _BoardComposerState extends State<BoardComposer> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _kind = 'note';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_body.text.trim().isEmpty || (widget.withTitle && _title.text.trim().isEmpty)) return;
    setState(() => _busy = true);
    final ok = await widget.onSend(_title.text.trim(), _kind, _body.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _title.clear();
      _body.clear();
    }
  }

  Future<void> _pickKind(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final at = box?.localToGlobal(box.size.bottomLeft(Offset.zero));
    final entries = [
      for (final k in boardKinds)
        RgMenuEntry(
          k,
          k == _kind ? RgIcons.check : RgIcons.tag,
          boardKindLabel(l, k),
          key: Key('board-kind-$k'),
          color: k == 'note' ? null : boardColor(c, k),
        ),
    ];
    final pick = MediaQuery.sizeOf(context).width >= 700 && at != null
        ? await showRgMenu<String>(context, at, entries)
        : await showRgSheet<String>(
            context,
            head: RgSheetHead(
              leading: RgIcon(RgIcons.tag, size: 22, color: c.dim),
              title: widget.withTitle ? l.cvNewThread : l.cvReply,
            ),
            entries: entries,
          );
    if (pick != null && mounted) setState(() => _kind = pick);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final pre = widget.withTitle ? 'board-new' : 'board-reply';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        if (widget.withTitle)
          TextField(
            key: Key('$pre-title'),
            controller: _title,
            decoration: InputDecoration(isDense: true, hintText: l.cvTitle),
          ),
        TextField(
          key: Key('$pre-body'),
          controller: _body,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(isDense: true),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 8,
          runSpacing: 6,
          children: [
            Builder(
              builder: (context) => OutlinedButton.icon(
                key: Key('$pre-kind'),
                onPressed: () => _pickKind(context),
                icon: RgIcon(RgIcons.chevronDown, size: 14, color: c.dim),
                label: Text(
                  boardKindLabel(l, _kind),
                  style: TextStyle(color: boardColor(c, _kind)),
                ),
              ),
            ),
            FilledButton(
              key: Key('$pre-send'),
              onPressed: _busy ? null : _send,
              child: Text(widget.withTitle ? l.cvNewThread : l.cvReply),
            ),
          ],
        ),
      ],
    );
  }
}
