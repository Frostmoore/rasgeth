// A board of variants in the app (G42.2), as the page's `Variants.tsx`: the title, when it was
// published and what it is for, the width of the previews (computer, tablet, phone), then each
// variant with its number and note, its preview, «I choose this», «Full screen», a comment and
// what was said about it, and a comment on the whole board. Everything is native but the variants
// themselves, which are HTML: each one is the page inside a web view of its own
// (`embed=board&variant=n&screen=…`), drawn at the real screen's width and scaled to its frame.
// What the person says goes to the agent as a message (`POST /api/sessions/:id/variants`).
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/board.dart';
import '../app_state.dart';
import '../embed/embed_link.dart';
import '../embed/embed_screen.dart';
import '../embed/embed_view.dart';
import '../l10n/app_localizations.dart';
import '../theme/colors.dart';
import '../ui/icons.dart';

/// Opens the board [proposalId] of the conversation [sessionId].
Future<void> openBoard(
  BuildContext context, {
  required String sessionId,
  required String proposalId,
  String? title,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => BoardScreen(sessionId: sessionId, proposalId: proposalId, title: title),
  ),
);

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.sessionId, required this.proposalId, this.title});

  final String sessionId;
  final String proposalId;
  final String? title;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

typedef _Status = ({bool? ok, String text});

class _BoardScreenState extends State<BoardScreen> {
  Board? _board;
  bool _missing = false;
  String? _error;
  EmbedContext? _embed;
  String _screen = 'computer';
  final _notes = <String, TextEditingController>{};
  final _status = <String, _Status>{};
  bool _started = false;

  static String _key(int? n) => n == null ? 'all' : '$n';

  TextEditingController _note(int? n) => _notes.putIfAbsent(_key(n), TextEditingController.new);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(_load());
    unawaited(
      embedContextOf(context).then((e) {
        if (mounted) setState(() => _embed = e);
      }),
    );
  }

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final c = AppScope.read(context).client;
    if (c == null) return;
    try {
      final events = await c.sessionEvents(widget.sessionId);
      if (!mounted) return;
      final b = boardOf(events, widget.proposalId);
      setState(() {
        _board = b;
        _missing = b == null;
        _error = null;
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _send(int? variant, {required bool choice}) async {
    final l = AppLocalizations.of(context);
    final k = _key(variant);
    final comment = _note(variant).text.trim();
    if (!choice && comment.isEmpty) {
      setState(() => _status[k] = (ok: false, text: l.cvBoardWriteComment));
      return;
    }
    setState(() => _status[k] = (ok: null, text: l.cvBoardSending));
    final c = AppScope.read(context).client;
    try {
      if (c == null) throw StateError('Not connected');
      await c.answerVariants(
        widget.sessionId,
        proposalId: widget.proposalId,
        variant: variant,
        choice: choice,
        comment: comment,
      );
      if (!mounted) return;
      _note(variant).clear();
      setState(() => _status[k] = (ok: true, text: l.cvBoardSent));
      await _load();
    } on Object catch (e) {
      if (mounted) setState(() => _status[k] = (ok: false, text: '$e'));
    }
  }

  Uri? _variantUrl(int n, String screen) {
    final e = _embed;
    if (e == null) return null;
    return embedUrl(
      e.base,
      EmbedParams(
        token: e.token,
        embed: EmbedKind.board,
        bridge: _nonces.putIfAbsent('$n/$screen', newEmbedNonce),
        theme: e.theme,
        lang: e.lang,
        board: '${widget.sessionId}.${widget.proposalId}',
        variant: n,
        screen: screen,
      ),
    );
  }

  final _nonces = <String, String>{};

  String _when(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final l = AppLocalizations.of(context);
    return DateFormat.MMMd(l.localeName).add_Hm().format(d);
  }

  Future<void> _full(int n) async {
    final b = _board;
    final url = _variantUrl(n, _screen);
    if (b == null || url == null) return;
    final chose = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _VariantFull(
          number: n,
          title: b.variants[n - 1].title,
          url: url,
          nonce: _nonces['$n/$_screen']!,
          leaf: _embed?.leaf,
        ),
      ),
    );
    if (chose == true && mounted) await _send(n, choice: true);
  }

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final b = _board;
    final n = b?.variants.length ?? 0;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Bar(
              title: b?.title ?? widget.title ?? l.cvBoardTab,
              meta: b == null
                  ? null
                  : '${n == 1 ? l.cvBoardOneVariant : l.cvBoardVariants('$n')} · ${_when(b.at)}',
            ),
            Expanded(
              child: _error != null
                  ? _Centered(icon: RgIcons.alert, text: l.errGeneric(_error!), color: c.err)
                  : _missing
                  ? _Centered(icon: RgIcons.canvas, text: l.cvBoardNotFound, color: c.dim)
                  : b == null
                  ? Center(
                      child: Text(l.loading, style: TextStyle(color: c.dim)),
                    )
                  : LayoutBuilder(builder: (context, box) => _body(context, b, box.maxWidth)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Board b, double width) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    const gap = 18.0;
    final pad = width < 600 ? 14.0 : 20.0;
    final inner = (width > 1600 ? 1600.0 : width) - pad * 2;
    // As the page's grid: as many columns of the screen's width as fit, sharing what is left.
    final col = boardColumns[_screen]!;
    final cols = inner < col
        ? 1
        : ((inner + gap) / (col + gap)).floor().clamp(1, b.variants.length);
    final cardWidth = (inner - gap * (cols - 1)) / cols;
    return ListView(
      key: const Key('board-list'),
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      b.description!,
                      style: TextStyle(color: c.text, fontSize: 15, height: 1.5),
                    ),
                  ),
                Semantics(
                  label: l.cvBoardScreens,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in boardScreens.keys)
                        _Pill(
                          key: Key('board-screen-$s'),
                          label: switch (s) {
                            'tablet' => l.cvBoardScreenTablet,
                            'phone' => l.cvBoardScreenPhone,
                            _ => l.cvBoardScreenComputer,
                          },
                          on: _screen == s,
                          onTap: () => setState(() => _screen = s),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (i, v) in b.variants.indexed)
                      SizedBox(width: cardWidth, child: _variant(context, b, i + 1, v)),
                  ],
                ),
                const SizedBox(height: gap),
                _whole(context, b),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _variant(BuildContext context, Board b, int no, BoardVariant v) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    final chosen = b.chosen == no;
    final url = _variantUrl(no, _screen);
    return Container(
      key: Key('board-variant-$no'),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chosen ? c.ok : c.line, width: chosen ? 2 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('$no', style: TextStyle(color: c.dim, fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    v.title,
                    style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                if (chosen)
                  Container(
                    key: Key('board-chosen-$no'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.ok,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l.cvBoardChosen,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (v.note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(v.note!, style: TextStyle(color: c.dim, fontSize: 13)),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(horizontal: BorderSide(color: c.line)),
            ),
            child: AspectRatio(
              aspectRatio: boardAspect(_screen),
              child: url == null
                  ? const SizedBox.expand()
                  : EmbedView(
                      key: ValueKey('board-frame-$no-$_screen'),
                      url: url,
                      nonce: _nonces['$no/$_screen'],
                      leaf: _embed?.leaf,
                      handleBack: false,
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      key: Key('board-choose-$no'),
                      onPressed: () => _send(no, choice: true),
                      icon: const RgIcon(RgIcons.check, size: 15, color: Colors.white),
                      label: Text(chosen ? l.cvBoardChosen : l.cvBoardChoose),
                    ),
                    OutlinedButton.icon(
                      key: Key('board-full-$no'),
                      onPressed: url == null ? null : () => _full(no),
                      icon: RgIcon(RgIcons.maximize, size: 15, color: c.text),
                      label: Text(l.cvBoardFull),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _comment(context, no, l.cvBoardCommentHere, l.cvBoardSendComment),
                _history(context, b.answersOn(no)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whole(BuildContext context, Board b) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      key: const Key('board-whole'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.cvBoardWhole,
            style: TextStyle(color: c.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _comment(context, null, l.cvBoardWholeHint, l.cvBoardSendToAgent),
          _history(context, b.answersOn(null)),
        ],
      ),
    );
  }

  Widget _comment(BuildContext context, int? no, String hint, String send) {
    final c = RgColors.of(context);
    final st = _status[_key(no)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: Key('board-comment-${_key(no)}'),
          controller: _note(no),
          minLines: 2,
          maxLines: 6,
          style: TextStyle(color: c.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.dim, fontSize: 13),
            isDense: true,
            filled: true,
            fillColor: c.bg,
            contentPadding: const EdgeInsets.all(10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.line),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            key: Key('board-send-${_key(no)}'),
            onPressed: () => _send(no, choice: false),
            icon: RgIcon(RgIcons.send, size: 14, color: c.text),
            label: Text(send),
          ),
        ),
        if (st != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              st.text,
              key: Key('board-status-${_key(no)}'),
              style: TextStyle(
                fontSize: 12,
                color: st.ok == true
                    ? c.ok
                    : st.ok == false
                    ? c.accent
                    : c.dim,
              ),
            ),
          ),
      ],
    );
  }

  Widget _history(BuildContext context, List<BoardAnswer> answers) {
    if (answers.isEmpty) return const SizedBox.shrink();
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final a in answers)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${_when(a.ts)} · ${a.choice ? l.cvBoardChoiceWord : l.cvBoardCommentWord}'
                '${a.comment != null ? ': ${a.comment}' : ''}',
                style: TextStyle(color: c.dim, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// The screen's bar: back, the board's title and what it holds.
class _Bar extends StatelessWidget {
  const _Bar({required this.title, this.meta, this.actions = const []});

  final String title;
  final String? meta;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('board-back'),
            tooltip: l.back,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: RgIcon(RgIcons.arrowLeft, color: c.text),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  key: const Key('board-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                ),
                if (meta != null)
                  Text(
                    meta!,
                    key: const Key('board-meta'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.dim, fontSize: 12),
                  ),
              ],
            ),
          ),
          ...actions,
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// One of the screen widths, as the page's round buttons (on: the accent).
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    return Semantics(
      selected: on,
      button: true,
      child: Material(
        color: on ? c.accent : c.panel,
        shape: StadiumBorder(side: BorderSide(color: on ? c.accent : c.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: TextStyle(
                color: on ? Colors.white : c.text,
                fontSize: 13,
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.icon, required this.text, required this.color});

  final RgIcons icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RgIcon(icon, size: 22, color: color),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: RgColors.of(context).text),
          ),
        ],
      ),
    ),
  );
}

/// One variant on the whole screen (the page's «Full screen»): its number and title, «I choose
/// this» (back to the board, which sends it) and «Close».
class _VariantFull extends StatelessWidget {
  const _VariantFull({
    required this.number,
    required this.title,
    required this.url,
    required this.nonce,
    this.leaf,
  });

  final int number;
  final String title;
  final Uri url;
  final String nonce;
  final Uint8List? leaf;

  @override
  Widget build(BuildContext context) {
    final c = RgColors.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.panel2,
      body: SafeArea(
        child: Column(
          children: [
            _Bar(
              title: '$number. $title',
              actions: [
                FilledButton.icon(
                  key: const Key('board-full-choose'),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const RgIcon(RgIcons.check, size: 15, color: Colors.white),
                  label: Text(l.cvBoardChoose),
                ),
                IconButton(
                  key: const Key('board-full-close'),
                  tooltip: l.cvClose,
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: RgIcon(RgIcons.x, size: 18, color: c.text),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: EmbedView(url: url, nonce: nonce, leaf: leaf, handleBack: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
