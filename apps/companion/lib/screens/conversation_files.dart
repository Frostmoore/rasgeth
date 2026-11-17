// The conversation's files (G42.5), as the page's folder button in the top bar and its Explorer on
// the right (layout Officina). On a computer a panel beside the conversation, resizable, kept
// open or closed (and full window or not) between openings; narrower than [_sideFrom] it covers
// the conversation until closed. On a phone a screen of its own. A file dragged from the panel
// onto the conversation is attached to the message.
part of 'conversation_screen.dart';

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
  bool _wide = true;
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

  void _openFile(BuildContext context, String scope, String path, String name) => unawaited(
    openCanvas(context, scope: scope, path: path, title: name, sessionId: widget.sessionId),
  );

  /// The header's folder button.
  Widget _filesButton(BuildContext context, Agent? agent) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final on = _computer && (_wide ? _filesOpen : _filesCover);
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
    if (_wide) {
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

  @override
  Widget build(BuildContext context) {
    final chat = _s._chat(context);
    if (!_computer) return chat;
    final agent = _s._agent;
    return LayoutBuilder(
      builder: (context, box) {
        final l = AppLocalizations.of(context);
        final c = RgColors.of(context);
        _wide = box.maxWidth >= _sideFrom;
        final wide = _wide;
        final cover = wide ? _filesOpen && _filesFull : _filesCover;
        final side = wide && _filesOpen && !_filesFull;
        final most = math.max(_minWidth, box.maxWidth * .6);
        final width = _filesWidth.clamp(_minWidth, most).toDouble();
        final place = explorerPlaceFor(_s.app, widget.sessionId, agent);
        final Widget? panel = cover || side
            ? FilesExplorer(
                key: _filesKey,
                place: place,
                computer: true,
                onOpen: (path, name) => _openFile(context, place.scope, path, name),
                onAsk: _s._readOnly ? null : _askAbout,
                onClose: () => wide ? _setFilesOpen(false) : setState(() => _filesCover = false),
                onFull: wide ? () => _setFilesFull(!_filesFull) : null,
                full: cover,
              )
            : null;
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
                  Expanded(child: target),
                  if (side && panel != null) ...[
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
                          onKey: (d) =>
                              _setFilesWidth((width + d * 24).clamp(_minWidth, most).toDouble()),
                        ),
                      ),
                    ),
                    SizedBox(key: const Key('conversation-files-side'), width: width, child: panel),
                  ],
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
