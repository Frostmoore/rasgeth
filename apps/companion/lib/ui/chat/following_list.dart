// Following a reply as it streams (3.10.4), the page's `follow.ts`. The person: with cloud models
// the text comes faster than one reads, and a finger put down to stay at a point was pulled to the
// bottom anyway. So the conversation follows the newest text only while the view is at the bottom
// (within [kFollowNear] px); a touch, a drag, a wheel or a key that moves it stops that, and the
// view stays exactly where it is. «Nuovo testo» shows while text came below; it, scrolling back to
// the bottom by hand (the finger lifted), or a message sent ([FollowController.resume]) follows
// again.
//
// How the view stays: the list is reversed (it opens at the bottom, the history built upwards
// lazily, as before 3.10.4); what came after the history first shown is one block at the bottom.
// While not following, the block's growth is given back to the scroll offset during layout
// (`scrollOffsetCorrection`), so new text below moves nothing above, even under a dragging finger.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/colors.dart';
import '../icons.dart';

const double kFollowNear = 4;

/// The state of following, for a screen's own actions (a message sent: [resume]).
class FollowController extends ChangeNotifier {
  bool _follow = true;
  bool _unseen = false;
  bool _holding = false;

  /// Our own move to the bottom is under way: its scrolls are not the person's.
  bool _ours = false;
  ScrollController? _scroll;

  bool get following => _follow;

  /// Text came below while not following.
  bool get unseen => _unseen;

  /// The view keeps its place: not following, or a finger on it.
  bool get _keep => !_follow || _holding;

  /// Back to the bottom, following again.
  void resume() {
    _holding = false;
    _set(follow: true, unseen: false);
    toEnd();
  }

  /// Stop following (a jump to a passage higher up).
  void stop() => _set(follow: false);

  /// To the bottom (offset 0 of the reversed list).
  void toEnd() {
    final s = _scroll;
    if (s == null || !s.hasClients || s.position.pixels == 0) return;
    _ours = true;
    try {
      s.jumpTo(0);
    } finally {
      _ours = false;
    }
  }

  /// To the bottom, quickly (the button).
  Future<void> glide() async {
    final s = _scroll;
    if (s == null || !s.hasClients) return;
    _ours = true;
    try {
      await s.animateTo(0, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    } finally {
      _ours = false;
    }
    toEnd();
  }

  void _set({bool? follow, bool? unseen}) {
    final f = follow ?? _follow, u = unseen ?? _unseen;
    if (f == _follow && u == _unseen) return;
    _follow = f;
    _unseen = u;
    notifyListeners();
  }
}

class FollowingList extends StatefulWidget {
  const FollowingList({
    super.key,
    required this.listKey,
    required this.controller,
    required this.follow,
    required this.count,
    required this.history,
    required this.settled,
    required this.itemBuilder,
    this.padding = EdgeInsets.zero,
  });

  /// The scrollable's key (tests drag it).
  final Key listKey;
  final ScrollController controller;
  final FollowController follow;

  /// The items, oldest first.
  final int count;

  /// How many of the first items are the stored history (the rest: what is being written, the
  /// cards and requests after it).
  final int history;

  /// The history has arrived: what it holds now stays above the block (from its first item: a
  /// new conversation's first message joins it too).
  final bool settled;

  /// The item at [at], oldest first.
  final Widget Function(BuildContext context, int at) itemBuilder;
  final EdgeInsets padding;

  @override
  State<FollowingList> createState() => _FollowingListState();
}

class _FollowingListState extends State<FollowingList> {
  int? _split;

  FollowController get f => widget.follow;

  @override
  void initState() {
    super.initState();
    f._scroll = widget.controller;
    f.addListener(_changed);
  }

  @override
  void didUpdateWidget(FollowingList old) {
    super.didUpdateWidget(old);
    f._scroll = widget.controller;
    if (old.follow != widget.follow) {
      old.follow.removeListener(_changed);
      widget.follow.addListener(_changed);
    }
  }

  @override
  void dispose() {
    f.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool _atEnd(ScrollMetrics m) => m.pixels - m.minScrollExtent <= kFollowNear;

  bool _onNote(ScrollNotification n) {
    if (n.depth != 0) return false;
    final m = n.metrics;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      f._set(follow: false);
    } else if (n is ScrollUpdateNotification) {
      // Any move that is not ours and leaves the bottom (a drag, a key, a passage brought into
      // view) stops following; back at the bottom without a finger on it, following again.
      if (f._follow && !f._ours && !_atEnd(m)) {
        f._set(follow: false);
      } else if (!f._follow && !f._holding && _atEnd(m)) {
        f._set(follow: true, unseen: false);
      }
    } else if (n is ScrollEndNotification) {
      if (!f._follow && !f._holding && _atEnd(m)) f._set(follow: true, unseen: false);
    }
    return false;
  }

  /// The block grew while the view kept its place: there is new text below.
  void _grew() {
    if (!mounted) return;
    final s = widget.controller;
    if (s.hasClients && !_atEnd(s.position)) f._set(unseen: true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = RgColors.of(context);
    final count = widget.count;
    // Once the history is there, its length is where the block starts; a shorter history (a
    // message erased) moves it back.
    final history = math.min(widget.history, count);
    if (widget.settled && history > 0) _split ??= history;
    if (_split != null && _split! > history) _split = history;
    final split = _split ?? history;
    final p = widget.padding;
    final list = CustomScrollView(
      key: widget.listKey,
      controller: widget.controller,
      reverse: true,
      slivers: [
        // At the bottom: everything after the history first shown, laid out whole (a few
        // messages), so its height is exact and its growth can be given back.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(p.left, 0, p.right, p.bottom),
          sliver: _KeepPlace(
            keep: f._keep,
            onGrew: _grew,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (var at = split; at < count; at++) widget.itemBuilder(context, at)],
              ),
            ),
          ),
        ),
        // Above: the history, newest first, built as it comes into view.
        SliverPadding(
          padding: EdgeInsets.fromLTRB(p.left, p.top, p.right, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => widget.itemBuilder(context, split - 1 - i),
              childCount: split,
            ),
          ),
        ),
      ],
    );
    return Stack(
      children: [
        Listener(
          // A finger (or a button) down on the conversation: it stays where it is.
          onPointerDown: (_) => setState(() => f._holding = true),
          onPointerUp: (_) => _lifted(),
          onPointerCancel: (_) => _lifted(),
          onPointerSignal: (e) {
            if (e is PointerScrollEvent && e.scrollDelta.dy < 0) f._set(follow: false);
          },
          child: NotificationListener<ScrollNotification>(onNotification: _onNote, child: list),
        ),
        if (!f._follow)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Tooltip(
                message: l.cvToBottom,
                child: Material(
                  color: f._unseen ? c.accent : c.panel2,
                  shape: StadiumBorder(side: BorderSide(color: f._unseen ? c.accent : c.line)),
                  elevation: 4,
                  shadowColor: Colors.black54,
                  child: InkWell(
                    key: const Key('to-bottom'),
                    customBorder: const StadiumBorder(),
                    onTap: () {
                      f._holding = false;
                      f._set(follow: true, unseen: false);
                      f.glide().ignore();
                    },
                    child: SizedBox(
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: f._unseen ? 14 : 11),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RgIcon(
                              RgIcons.arrowDown,
                              size: 18,
                              color: f._unseen ? Colors.white : c.text,
                            ),
                            if (f._unseen) ...[
                              const SizedBox(width: 6),
                              Text(
                                l.newText,
                                key: const Key('new-text'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _lifted() {
    if (!f._holding) return;
    setState(() => f._holding = false);
    final s = widget.controller;
    if (!s.hasClients) return;
    if (_atEnd(s.position)) {
      f._set(follow: true, unseen: false);
    } else if (f._follow) {
      // Text came below while the finger held the view: it stays there.
      f._set(follow: false, unseen: true);
    }
  }
}

/// The block at the bottom: while [keep], a change of its height moves the scroll offset by as
/// much, during layout, so what is above stays where it is on screen.
class _KeepPlace extends SingleChildRenderObjectWidget {
  const _KeepPlace({required this.keep, required this.onGrew, required Widget sliver})
    : super(child: sliver);

  final bool keep;
  final VoidCallback onGrew;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderKeepPlace(keep: keep, onGrew: onGrew);

  @override
  void updateRenderObject(BuildContext context, _RenderKeepPlace r) => r
    ..keep = keep
    ..onGrew = onGrew;
}

class _RenderKeepPlace extends RenderProxySliver {
  _RenderKeepPlace({required this.keep, required this.onGrew});

  bool keep;
  VoidCallback onGrew;
  double? _extent;

  @override
  void performLayout() {
    child!.layout(constraints, parentUsesSize: true);
    final g = child!.geometry!;
    final last = _extent;
    _extent = g.scrollExtent;
    final grown = last == null ? 0.0 : g.scrollExtent - last;
    if (keep && grown.abs() > 0.01 && g.scrollOffsetCorrection == null) {
      geometry = SliverGeometry(scrollOffsetCorrection: grown);
      if (grown > 0) WidgetsBinding.instance.addPostFrameCallback((_) => onGrew());
      return;
    }
    geometry = g;
  }
}
