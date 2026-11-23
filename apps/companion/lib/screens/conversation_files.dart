// The conversation's files (G42.5), as the page's folder button in the top bar and its Explorer on
// the right (layout Officina). On a computer a panel beside the conversation, resizable, kept
// open or closed (and full window or not) between openings; narrower than [_sideFrom] it covers
// the conversation until closed. On a phone a screen of its own. A file dragged from the panel
// onto the conversation is attached to the message.
//
// The right column (3.8.11): the files and the Canvas (G42.2) share one column on the right of
// the conversation, never two side by side (the window is narrower than the page's).
// - One open: the column shows it, as before, with no tabs.
// - Both open: two drawn tabs, Files and Canvas, on top of the column; the one in front is lit.
//   Each keeps its own width (the files' is kept between openings, the Canvas's while the
//   conversation is open) and its state (the tree's folders, the page in the web view).
// - The folder button brings the files in front (opening them), or closes them when they are
//   already in front. What an agent shows, a «… in the Canvas» line and a file opened from the
//   files bring the Canvas in front: the file opens in a Canvas tab, the tree one tap away.
// - Closing one leaves the other in front. The files full window cover the conversation and
//   the Canvas until made small again.
// - Narrow (below each one's width), as before: the files cover the conversation, the Canvas
//   opens as a screen of its own.
// - Terminals (G42.5): the files' «Terminal» opens one in a tab of the same column (the page's
//   terminal tab in its area on the right), as many as asked, each closed by its ×; they share
//   the files' width and live while the conversation is open. Narrow, a terminal is a screen.
part of 'conversation_screen.dart';

/// What the right column shows in front when more than one thing is open.
enum _SideTab { files, canvas, terminal }

/// A terminal in the right column: its place's scope and the page's title.
class _SideTerm {
  _SideTerm(this.id, this.scope, this.title);

  final String id;
  final String scope;
  final String title;
  final key = GlobalKey<RgTerminalState>();
}

mixin _ConversationFiles on State<ConversationScreen> {
  /// The conversation's own state (the composer, its attachments).
  _ConversationScreenState get _s => this as _ConversationScreenState;

  static const _sideFrom = 720.0;
  static const _minWidth = 240.0;

  bool _filesOpen = false;
  bool _filesFull = false;
  double _filesWidth = 320;

  /// Too narrow for a panel: the files cover the conversation until closed (not kept).
  bool _filesCover = false;
  bool _filesWide = true;

  /// In front of the right column when both are open (3.8.11).
  _SideTab _sideFront = _SideTab.files;

  /// The terminals open in the column (G42.5), and the one shown when a terminal is in front.
  final _terms = <_SideTerm>[];
  String? _termFront;
  int _termSeq = 0;

  /// The files' «Terminal» on a wide computer window: a new tab in front.
  void _openTermHere(String scope, String title) {
    final t = _SideTerm('term-${++_termSeq}', scope, title);
    setState(() {
      _terms.add(t);
      _termFront = t.id;
      _sideFront = _SideTab.terminal;
    });
  }

  void _closeTerm(String id) {
    setState(() {
      final i = _terms.indexWhere((t) => t.id == id);
      if (i < 0) return;
      _terms.removeAt(i);
      if (_termFront == id) {
        _termFront = _terms.isEmpty ? null : _terms[(i - 1).clamp(0, _terms.length - 1)].id;
      }
      if (_terms.isEmpty && _sideFront == _SideTab.terminal) _sideFront = _SideTab.files;
    });
  }

  /// The Canvas is beside the conversation now (its panel, not a screen of its own).
  bool get _canvasSide => _s._canvasBeside && _s._canvas.open && _s._canvas.current != null;
  Timer? _widthSave;
  final _filesKey = GlobalKey(debugLabel: 'conversation-files');

  bool get _computer => DeskScope.maybeRead(context) != null;

  @override
  void initState() {
    super.initState();
    unawaited(_loadFiles(AppScope.read(context).prefs));
  }

  @override
  void dispose() {
    _widthSave?.cancel();
    super.dispose();
  }

  Future<void> _loadFiles(AppPrefs p) async {
    final open = await p.get('explorerOpen') == '1';
    final full = await p.get('explorerFull') == '1';
    final w = double.tryParse(await p.get('explorerWidth') ?? '');
    if (!mounted) return;
    setState(() {
      _filesOpen = open;
      _filesFull = full;
      if (w != null) _filesWidth = w;
    });
  }

  void _setFilesOpen(bool v) {
    setState(() => _filesOpen = v);
    unawaited(_s.app.prefs.set('explorerOpen', v ? '1' : null));
  }

  void _setFilesFull(bool v) {
    setState(() => _filesFull = v);
    unawaited(_s.app.prefs.set('explorerFull', v ? '1' : null));
  }

  void _setFilesWidth(double w) {
    setState(() => _filesWidth = w);
    _widthSave?.cancel();
    _widthSave = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_s.app.prefs.set('explorerWidth', w.round().toString())),
    );
  }

  /// A file opened from the files' screen (a phone): a tab of this conversation's Canvas.
  void _openFile(BuildContext context, String scope, String path, String name) =>
      _s._showCanvas(name, {'kind': 'file', 'scope': scope, 'path': path}, force: true);

  /// A file opened from the panel on a computer: in the Canvas beside the conversation (the
  /// column brings it in front), or the Canvas screen where it is narrow.
  void _openFileHere(String scope, String path, String name) =>
      _s._showCanvas(name, {'kind': 'file', 'scope': scope, 'path': path}, force: true);

  /// The header's folder button.
  Widget _filesButton(BuildContext context, Agent? agent) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final on =
        _computer &&
        (_filesWide
            ? _filesOpen && (_sideFront == _SideTab.files || (!_canvasSide && _terms.isEmpty))
            : _filesCover);
    return IconButton(
      key: const Key('conversation-files'),
      tooltip: l.fxOpenFiles,
      isSelected: on,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 40),
      style: on ? IconButton.styleFrom(backgroundColor: c.accentSoft) : null,
      onPressed: () => _toggleFiles(agent),
      icon: RgIcon(RgIcons.folder, size: 20, color: on ? c.accent : c.dim),
    );
  }

  void _toggleFiles(Agent? agent) {
    if (!_computer) {
      final place = explorerPlaceFor(_s.app, widget.sessionId, agent);
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FilesScreen(
              place: place,
              onOpen: (ctx, path, name) => _openFile(ctx, place.scope, path, name),
              onAsk: _s._readOnly ? null : _askAbout,
            ),
          ),
        ),
      );
      return;
    }
    if (_filesWide) {
      // Behind the Canvas: in front first; in front (or alone): open or closed.
      final behind =
          (_canvasSide && _sideFront == _SideTab.canvas) ||
          (_terms.isNotEmpty && _sideFront == _SideTab.terminal);
      if (_filesOpen && behind && !_filesFull) {
        setState(() => _sideFront = _SideTab.files);
        return;
      }
      if (!_filesOpen) _sideFront = _SideTab.files;
      _setFilesOpen(!_filesOpen);
    } else {
      setState(() => _filesCover = !_filesCover);
    }
  }

  /// «Ask the agent»: the file's line goes into the composer, for the person to finish.
  void _askAbout(String path) {
    final draft = AppLocalizations.of(context).codeAskDraft(path);
    final now = _s._text.text;
    final text = now.trim().isEmpty
        ? draft
        : '$now${now.endsWith(' ') || now.endsWith('\n') ? '' : ' '}$draft';
    _s._before = text;
    _s._text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// A file dragged from the panel. In the agent's own workspace a big file is named by its path
  /// (nothing written again); a photo or a text comes with its content, as «Attach» does.
  Future<void> _attachFromFiles(ExplorerFileDrag f) async {
    final l = AppLocalizations.of(context);
    final client = _s.app.client;
    if (client == null || _s._readOnly) return;
    if (_s._attached.length >= kMaxAttached) {
      setState(() => _s._note = l.cvTooMany('$kMaxAttached'));
      return;
    }
    final same = f.scope == attachmentScope(_s._agent);
    final content =
        (imageTypeOf(f.name) != null && f.size <= kMaxFileBytes) ||
        (isTextName(f.name) && f.size <= kMaxTextChars);
    if (same && !content) {
      setState(() => _s._attached.add(AttachedPath(f.name, f.path, f.size)));
      return;
    }
    if (f.size > kMaxFileBytes) {
      setState(() => _s._note = l.attachmentTooBig(f.name));
      return;
    }
    try {
      final bytes = await client.fileRaw(f.scope, f.path);
      if (mounted) await _s._add(f.name, bytes);
    } on ApiException {
      if (mounted) setState(() => _s._note = l.fxAttachFailed(f.name));
    }
  }

  /// The right column's tabs, shown when more than one thing is open in it.
  Widget _sideTabs(BuildContext context, {required bool files, required bool canvas}) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    Widget tab(_SideTab t, String label, RgIcons icon, {_SideTerm? term}) {
      final on = _sideFront == t && (term == null || _termFront == term.id);
      final keyName = term?.id ?? t.name;
      return Semantics(
        button: true,
        selected: on,
        child: Material(
          color: on ? c.bg : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: on ? c.line : Colors.transparent),
          ),
          child: InkWell(
            key: Key('side-tab-$keyName'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              _sideFront = t;
              if (term != null) _termFront = term.id;
            }),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 6, term == null ? 12 : 4, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RgIcon(icon, size: 15, color: on ? c.accent : c.dim),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: on ? c.text : c.dim,
                        fontSize: 13,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (term != null)
                    InkResponse(
                      key: Key('side-tab-close-${term.id}'),
                      radius: 14,
                      onTap: () => _closeTerm(term.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Semantics(
                          button: true,
                          label: l.deskClose,
                          child: RgIcon(RgIcons.x, size: 13, color: c.dim),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: l.sideTabsLabel,
      container: true,
      child: Container(
        key: const Key('side-tabs'),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: c.panel2,
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (files) ...[
                tab(_SideTab.files, l.sideTabFiles, RgIcons.folder),
                const SizedBox(width: 4),
              ],
              if (canvas) ...[
                tab(_SideTab.canvas, l.sideTabCanvas, RgIcons.canvas),
                const SizedBox(width: 4),
              ],
              for (final t in _terms) ...[
                tab(_SideTab.terminal, t.title, RgIcons.terminal, term: t),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CanvasHost(
    // What opens a file from inside the conversation (a card, an attachment, a widget) opens a
    // tab of its Canvas (G42.6).
    show: (title, target) => _s._showCanvas(title, target, force: true),
    child: _layout(context),
  );

  /// The conversation at least [min] wide, clipped (a maximized Canvas covers it, G42.6): it
  /// stays in the tree, its state kept.
  Widget _atLeast(double min, bool hidden, Widget child) => ClipRect(
    child: LayoutBuilder(
      builder: (context, b) => OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: math.max(b.maxWidth, min),
        maxWidth: math.max(b.maxWidth, min),
        child: Offstage(offstage: hidden, child: child),
      ),
    ),
  );

  Widget _layout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _s._canvasBeside = box.maxWidth >= canvasBesideFrom(Theme.of(context).platform);
        final chat = _s._chat(context);
        final canvasSide = _canvasSide;
        final over = canvasSide && (_s._canvas.max || _s._canvas.full);
        if (!_computer) {
          // A tablet: the Canvas alone on the right (the files are a screen of their own).
          if (!canvasSide) return chat;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _atLeast(360, over, chat)),
              Material(
                color: RgColors.of(context).bg,
                child: SafeArea(
                  left: false,
                  child: CanvasPanel(
                    model: _s._canvas,
                    maxWidth: box.maxWidth,
                    sessionId: widget.sessionId,
                    onAskAgent: _s._readOnly ? null : _s._askFromCanvas,
                  ),
                ),
              ),
            ],
          );
        }
        final agent = _s._agent;
        final l = AppLocalizations.of(context);
        final c = RgColors.of(context);
        _filesWide = box.maxWidth >= _sideFrom;
        final wide = _filesWide;
        final cover = wide ? _filesOpen && _filesFull : _filesCover;
        final side = wide && _filesOpen && !_filesFull;
        final terms = wide && _terms.isNotEmpty;
        // One column on the right: more than one open, the tab in front shows (the others kept,
        // hidden).
        final count = (side ? 1 : 0) + (canvasSide ? 1 : 0) + (terms ? _terms.length : 0);
        final both = count > 1;
        bool shown(_SideTab t) => switch (t) {
          _SideTab.files => side,
          _SideTab.canvas => canvasSide,
          _SideTab.terminal => terms,
        };
        final front = shown(_sideFront)
            ? _sideFront
            : side
            ? _SideTab.files
            : terms
            ? _SideTab.terminal
            : _SideTab.canvas;
        final termFront = _terms.any((t) => t.id == _termFront)
            ? _termFront
            : _terms.firstOrNull?.id;
        final column = side || terms;
        final most = math.max(_minWidth, box.maxWidth * .6);
        final width = _filesWidth.clamp(_minWidth, most).toDouble();
        final place = explorerPlaceFor(_s.app, widget.sessionId, agent);
        final Widget? panel = cover || side
            ? FilesExplorer(
                key: _filesKey,
                place: place,
                computer: true,
                onOpen: (path, name) => _openFileHere(place.scope, path, name),
                onAsk: _s._readOnly ? null : _askAbout,
                onClose: () => wide ? _setFilesOpen(false) : setState(() => _filesCover = false),
                onFull: wide ? () => _setFilesFull(!_filesFull) : null,
                full: cover,
                onTerminal: wide ? _openTermHere : null,
              )
            : null;
        final client = _s.app.client;
        final tabs = both ? _sideTabs(context, files: side, canvas: canvasSide) : null;
        final target = DragTarget<ExplorerFileDrag>(
          onWillAcceptWithDetails: (_) => !_s._readOnly,
          onAcceptWithDetails: (d) => unawaited(_attachFromFiles(d.data)),
          builder: (context, over, _) => Stack(
            fit: StackFit.expand,
            children: [
              chat,
              if (over.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      key: const Key('conversation-file-drop'),
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: c.accentSoft.withValues(alpha: .85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.accent, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RgIcon(RgIcons.paperclip, size: 20, color: c.accent),
                          const SizedBox(width: 8),
                          Text(
                            l.deskDropHere,
                            style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: cover,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _atLeast(360, over, target)),
                  if (column)
                    Offstage(
                      offstage: front == _SideTab.canvas || over,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DecoratedBox(
                            key: const Key('files-resizer'),
                            decoration: BoxDecoration(
                              color: c.panel,
                              border: Border(left: BorderSide(color: c.line)),
                            ),
                            child: Semantics(
                              label: l.fxResize,
                              child: PanelResizer(
                                onDrag: (dx) =>
                                    _setFilesWidth((width - dx).clamp(_minWidth, most).toDouble()),
                                onKey: (d) => _setFilesWidth(
                                  (width + d * 24).clamp(_minWidth, most).toDouble(),
                                ),
                                onReset: () => _setFilesWidth(320),
                              ),
                            ),
                          ),
                          SizedBox(
                            key: const Key('conversation-files-side'),
                            width: width,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ?tabs,
                                Expanded(
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      if (side && panel != null)
                                        Offstage(offstage: front != _SideTab.files, child: panel),
                                      if (terms && client != null)
                                        for (final t in _terms)
                                          Offstage(
                                            key: ValueKey(t.id),
                                            offstage:
                                                front != _SideTab.terminal || termFront != t.id,
                                            child: RgTerminal(
                                              key: t.key,
                                              client: client,
                                              scope: t.scope,
                                              font: 12.5,
                                            ),
                                          ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (canvasSide)
                    Offstage(
                      offstage: front != _SideTab.canvas,
                      child: Material(
                        color: c.bg,
                        child: CanvasPanel(
                          model: _s._canvas,
                          maxWidth: box.maxWidth,
                          sessionId: widget.sessionId,
                          top: over ? null : tabs,
                          visible: front == _SideTab.canvas,
                          onAskAgent: _s._readOnly ? null : _s._askFromCanvas,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (cover && panel != null)
              Positioned.fill(
                child: KeyedSubtree(key: const Key('conversation-files-cover'), child: panel),
              ),
          ],
        );
      },
    );
  }
}
